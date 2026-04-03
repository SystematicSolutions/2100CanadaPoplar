#
# DataReader.jl
#
#import Pkg;
#Pkg.add("HDF5")
#Pkg.add("DataFrames")
#Pkg.add("CSV")
#Pkg.add("Printf")
using CSV,DataFrames,DelimitedFiles,HDF5,Printf;

include("../Core/Core.jl") 
db=DatabaseName 
DataToRead="All"
startDirectory = pwd()

if length(ARGS) > 0
  startLength=length(startDirectory)
  rootLength=startLength-10
  modelRoot=SubString(startDirectory,1,rootLength)

  println("Model path " * ARGS[1])
  if length(ARGS) > 1
    DataToRead=ARGS[2]
    println("DataToRead " * ARGS[2])
  end
  
else
  # Use current working directory to determine model root
  current_dir = pwd()
  if occursin("InputData", current_dir)
    # If running from InputData directory, go up one level
    modelRoot = dirname(current_dir) * "\\"
  else
    modelRoot ="C:\\2020CanadaRedwood\\"
  end
  println("Using model root: " * modelRoot)
end
setsPath=ModelPath * "\\DataBase\\Sets\\"
#variableListPath =  modelRoot * "\\InputData\\VariableDatabaseInformation.txt"
#e2020VariableList = CSV.read(variableListPath, DataFrame; delim=';', copycols=true)

TomListPath=ModelPath * "\\2020TOM\\KOutput.csv"
TOMVariables::Vector{String}=[]
# OPTIMIZATION 1: Set Caching - Global cache for all set data
const SET_CACHE = Dict{String, Dict{String, Int}}()
const SET_SIZE_CACHE = Dict{String, Int}()
const SET_NAME_MAPPING = Dict{String, String}()  # Case-insensitive mapping from requested names to actual filenames
const cache_lock = ReentrantLock()

# OPTIMIZATION 2: Thread Count Heuristic
function determine_optimal_thread_count()
    available_cores = Threads.nthreads()
    physical_cores = max(1, div(available_cores, 2))  # Assume hyperthreading
    
    # Heuristic based on workload characteristics
    if available_cores <= 2
        return 1  # Single-threaded for very limited systems
    elseif available_cores <= 4
        return min(2, available_cores)  # Conservative for small systems
    elseif available_cores <= 8
        return min(4, available_cores - 1)  # Leave one core for OS
    else
        return min(8, available_cores - 2)  # Cap at 8 threads, leave 2 cores for OS
    end
end

function FillTOMList()
  open(TomListPath) do TomList
    for line in eachline(TomList)
      LineSplit = split(line, ",")
      VariableName = String(LineSplit[1])
      push!(TOMVariables,VariableName)
    end   
  end
end
# OPTIMIZATION 3: Preload all set data into cache
function PreloadSetData()
    println("Preloading set data for caching...")
    
    # Get all CSV files in the sets directory
    set_files = filter(f -> endswith(f, ".csv"), readdir(setsPath))
    
    lock(cache_lock) do
        # Build case-insensitive mapping from requested names to actual filenames
        for set_file in set_files
            set_name = replace(set_file, ".csv" => "")
            # Map both the original case and common variations to the actual filename
            SET_NAME_MAPPING[lowercase(set_name)] = set_name
            SET_NAME_MAPPING[set_name] = set_name
        end
        
        # Load data for each set
        for set_file in set_files
            set_path = joinpath(setsPath, set_file)
            set_name = replace(set_file, ".csv" => "")
            
            SET_CACHE[set_name] = Dict{String, Int}()
            
            # Match original GetSetSize logic exactly - count ALL lines
            line_counter = 0
            open(set_path) do setDescs
                for line in eachline(setDescs)
                    line_counter += 1
                    line_split = split(line, ",")
                    if length(line_split) > 0
                        name_in_file = String(line_split[1])
                        # Store both original case and lowercase for flexible lookup
                        SET_CACHE[set_name][lowercase(name_in_file)] = line_counter
                        SET_CACHE[set_name][name_in_file] = line_counter
                    end
                end
            end
            
            # Store the total count (matches original GetSetSize exactly)
            SET_SIZE_CACHE[set_name] = line_counter
        end
    end
    
    println("Cached $(length(SET_CACHE)) sets with $(sum(length(v) for v in values(SET_CACHE))) total entries")
    println("Built case-insensitive mapping for $(length(SET_NAME_MAPPING)) set name variations")
end

function VariableShouldBeRead(VariableName)
  if DataToRead=="All"
    return true
  end
  
  if DataToRead=="TOM"
    VarCount=length(TOMVariables)
    for rowIndex = 1:VarCount
      if TOMVariables[rowIndex]==VariableName
        println(VariableName * " Is TOM")
        return true
      end  
    end
    println(VariableName * " Is not TOM")
    return false
  end
  println(VariableName * " Error")
  return true
end

function GetDatabaseName(data)
  databaseName = data."HDF5 Database"[1]
  databaseName
end
function headerIsSet(header)
  #println(header)
   if header=="Variable" 
    return false
   end
   if header=="Units" 
    return false
   end
   if header=="Data" 
    return false
   end
   if header=="" 
    return false
   end
   
   return true
end
# OPTIMIZATION 4: Cached set index lookup with case-insensitive mapping
function GetSetIndexCached(setName, setFileName)
    set_key = replace(basename(setFileName), ".csv" => "")
    
    # Use case-insensitive mapping to find the actual filename
    actual_set_name = nothing
    lock(cache_lock) do
        if haskey(SET_NAME_MAPPING, set_key)
            actual_set_name = SET_NAME_MAPPING[set_key]
        elseif haskey(SET_NAME_MAPPING, lowercase(set_key))
            actual_set_name = SET_NAME_MAPPING[lowercase(set_key)]
        end
    end
    
    if actual_set_name === nothing
        println("Did not find mapping for set '$set_key'")
        return 1
    end
    
    # Get the index from cache
    index_result = lock(cache_lock) do
        if haskey(SET_CACHE, actual_set_name)
            cached_set = SET_CACHE[actual_set_name]
            # Try both original case and lowercase
            if haskey(cached_set, setName)
                return cached_set[setName]
            elseif haskey(cached_set, lowercase(setName))
                return cached_set[lowercase(setName)]
            else
                return nothing
            end
        else
            return nothing
        end
    end
    
    return index_result !== nothing ? index_result : 1  # Default fallback
end

# OPTIMIZATION 5: Cached set size lookup
function GetSetSizeCached(setName, setFileName)
    set_key = replace(basename(setFileName), ".csv" => "")
    
    # Use case-insensitive mapping to find the actual filename
    actual_set_name = nothing
    lock(cache_lock) do
        if haskey(SET_NAME_MAPPING, set_key)
            actual_set_name = SET_NAME_MAPPING[set_key]
        elseif haskey(SET_NAME_MAPPING, lowercase(set_key))
            actual_set_name = SET_NAME_MAPPING[lowercase(set_key)]
        end
    end
    
    if actual_set_name === nothing
        println("Did not find mapping for set size '$set_key'")
        return 1
    end
    
    # Get the size from cache
    size_result = lock(cache_lock) do
        if haskey(SET_SIZE_CACHE, actual_set_name)
            return SET_SIZE_CACHE[actual_set_name]
        else
            return nothing
        end
    end
    
    return size_result !== nothing ? size_result : 1  # Default fallback
end

# OPTIMIZATION 6: Thread-safe string file processing
function ReadAndStoreStringTextFile(variableName,tableName,folderName,DbForVariable)
    nameOfFile = modelRoot * "\\InputData\\Process\\" * tableName * ".dat"
    if VariableShouldBeRead(tableName)
      println("Processing string file: $nameOfFile")
      if DbForVariable=="2020DB"
        DbForVariable="MainDB"
      end
      dbAndVariableName = "$DbForVariable/$variableName"
      
      # Build vector of string values. If this is a vUn* variable, index by Unit set.
      if startswith(tableName, "vUn")
        # Build a Unit-keyed array with exact length of EGInput.Unit set
        unit_set_path = joinpath(setsPath, "Unit.csv")
        # Load Unit set order into a vector
        unit_names = String[]
        open(unit_set_path) do f
          for line in eachline(f)
            line_split = split(line, ",")
            if !isempty(line_split)
              push!(unit_names, String(line_split[1]))
            end
          end
        end

        inputVariable = Vector{String}(undef, length(unit_names))
        # Pre-fill with empty strings to avoid special-case values
        fill!(inputVariable, "Null")

        # Populate by matching second column (Unit) to Unit set order
        open(nameOfFile) do textFileToRead
          for line in eachline(textFileToRead)
            if !startswith(line, "Variable")
              lineSplit = split(line, ";")
              if length(lineSplit) >= 4
                unit_id = String(lineSplit[2])
                data = String(lineSplit[4])
                # Find index using cached lookup for Unit set
                set_index = GetSetIndexCached(unit_id, unit_set_path)
                if 1 <= set_index <= length(inputVariable)
                  inputVariable[set_index] = data
                end
              end
            end
          end
        end

        return (dbAndVariableName, inputVariable)
      else
        # Non-Unit string variables: simple sequential vector of data column
        inputVariable::Vector{String} = []
        open(nameOfFile) do textFileToRead
          for line in eachline(textFileToRead)
            if !startswith(line, "Variable") 
              lineSplit = split(line, ";")
              if length(lineSplit) >= 4
                data = String(lineSplit[4])
                push!(inputVariable, data)
              end
            end
          end
        end

        return (dbAndVariableName, inputVariable)
      end
    end
    return nothing
end

# OPTIMIZATION 7: Optimized numeric file processing with caching
function ReadAndStoreNumericTextFile(tableName,folderName,dbAndVariableName)
  nameOfFile = modelRoot * "\\InputData\\" * folderName * "\\" * tableName * ".dat"
  println("Processing numeric file: $nameOfFile")
  
  if VariableShouldBeRead(tableName)
    input_matrix = readdlm("$nameOfFile", ';' ;header=true)
    headersForVariable=input_matrix[2]
    
    columnsInData=length(headersForVariable)
    setsToLoop::Vector{String}=[]
    for colIndex in 1:columnsInData
      header=string(headersForVariable[colIndex])
      if headerIsSet(header)
        pushfirst!(setsToLoop,header)
      end
    end
    
    totalSets=length(setsToLoop)
    dimsForVariable::Vector{Int}=[]
    
    # Use cached set sizes
    for setName in setsToLoop
      SetListPath=setsPath * setName * ".csv"
      sizeOfDim=GetSetSizeCached(setName,SetListPath)
      push!(dimsForVariable,sizeOfDim)
    end
    
    println("Dimensions: $dimsForVariable")
    inputVariable::VariableArray{totalSets} = zeros(Float32,Dims(dimsForVariable))
    
    open(nameOfFile) do textFileToRead
      for line in eachline(textFileToRead)
        if !startswith(line, "Variable") 
          lineSplit = split(line, ";")
          if length(lineSplit) >= totalSets + 3
            
            setDescInLine::Vector{String}=[]
            for colIndex in 2:(totalSets+1)
              setDesc=String(lineSplit[colIndex])
              pushfirst!(setDescInLine,setDesc)
            end
            
            # Data is the last entry, sets+ 1 for variable, one for units
            dataIndex=totalSets+1+2        
            data = parse(Float32,(String(lineSplit[dataIndex])))
            
            setIndexesForVariable::Vector{Int}=[]
            counter=1
            for setDS in setDescInLine
              setName=string(setsToLoop[counter])
              SetListPath=setsPath * setName * ".csv"
              setIndex=GetSetIndexCached(setDS,SetListPath)  # Use cached lookup
              push!(setIndexesForVariable,setIndex)
              counter+=1
            end
            
            inputVariable[setIndexesForVariable...]=data
          end
        end
      end
    end
    
    return (dbAndVariableName, inputVariable)
  end
  return nothing
end

# OPTIMIZATION 8: Batch database operations
function WriteDiskBatch(database_name, batch_data)
    println("Writing batch of $(length(batch_data)) variables to database...")
    
    for (db_var_name, var_data) in batch_data
        if var_data !== nothing
            WriteDisk(database_name, db_var_name, var_data)
        end
    end
    
    println("Batch write completed")
end

# OPTIMIZATION 9: Parallel processing with batching
function ReadInputDataOptimized()
  inputTablesForVariable = modelRoot * "\\InputData\\Process\\InputTablesForVariable.csv"
    inputVariableData::Vector{String}=[]
    
    open(inputTablesForVariable) do inputList
        for line in eachline(inputList)
            push!(inputVariableData,line)
        end
    end
    
    # Filter out header
    data_rows = filter(line -> !startswith(line, "VariableName"), inputVariableData)
    rowCount = length(data_rows)
    
    optimal_threads = determine_optimal_thread_count()
    println("Using $optimal_threads threads for processing $rowCount variables")
    
    # Prepare batches for database operations
    string_batch = Vector{Tuple{String, Vector{String}}}()
    numeric_batch = Vector{Tuple{String, Any}}()
    batch_locks = ReentrantLock()
    
    # Process with optimal threading
    batch_size = max(1, div(rowCount, optimal_threads * 2))  # Smaller batches for better load distribution
    batch_indices = collect(1:batch_size:rowCount)
    
    Threads.@threads for batch_start in batch_indices
        batch_end = min(batch_start + batch_size - 1, rowCount)
        
        local_string_batch = Vector{Tuple{String, Vector{String}}}()
        local_numeric_batch = Vector{Tuple{String, Any}}()
        
        for idx in batch_start:batch_end
            line = data_rows[idx]
            LineSplit = split(line, ",")
            
            if length(LineSplit) >= 4
                varName = String(LineSplit[1])
                tableName = String(LineSplit[2])
                folderName = String(LineSplit[3])
                VarIsString = String(LineSplit[4])
                DbForVariable = String(LineSplit[5])
                
                try
                    if VarIsString=="TRUE" 
                        result = ReadAndStoreStringTextFile(varName,tableName,folderName,DbForVariable)
                        if result !== nothing
                            push!(local_string_batch, result)
                        end
                    else
                        if DbForVariable=="2020DB"
                          DbForVariable="MainDB"
                        end
                        dbAndVariableName = "$DbForVariable/$varName"
                        result = ReadAndStoreNumericTextFile(tableName,folderName,dbAndVariableName)
                        if result !== nothing
                            push!(local_numeric_batch, result)
                        end
                    end
                catch e
                    println("Error processing $varName: $e")
                end
            end
        end
        
        # Merge local batches into global batches with lock
        lock(batch_locks) do
            append!(string_batch, local_string_batch)
            append!(numeric_batch, local_numeric_batch)
        end
    end
    
    # Batch write all results
    println("Writing $(length(string_batch)) string variables and $(length(numeric_batch)) numeric variables to database...")
    
    all_batch_data = vcat(string_batch, numeric_batch)
    WriteDiskBatch(DatabaseName, all_batch_data)
end

function InputDataControl()
    println("Starting optimized data reader...")
    println("Available threads: $(Threads.nthreads())")
    
    FillTOMList()
    PreloadSetData()  # Cache all set data first
    
    @time ReadInputDataOptimized()
end

InputDataControl()
  
         
println("Data read completed!")
