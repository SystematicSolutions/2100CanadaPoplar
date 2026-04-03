#
# HDF5_Functions.jl
#
# This file contains base functions for the E2020 model to interact with HDF5 databases

using HDF5, DataFrames

abstract type HDF5GroupDatabase end
dbOpenDict = Dict{String,Any}()

dbToReadWrite = HDF5GroupDatabase

function _h5_cache_cfg()
  mdc_nelmts  = parse(Int, get(ENV, "E2020_H5_MDC_SLOTS",     "0"))        # let lib choose if 0
  rdcc_nslots = parse(Int, get(ENV, "E2020_H5_RDCC_NSLOTS",   "1021"))      # prime number
  rdcc_mb     = parse(Float64, get(ENV, "E2020_H5_RDCC_MB",   "1024"))
  rdcc_bytes  = Int(rdcc_mb * 1024^2)
  rdcc_w0     = parse(Float64, get(ENV, "E2020_H5_RDCC_W0",   "0.1"))
  (mdc_nelmts, rdcc_nslots, rdcc_bytes, rdcc_w0)
end

function OpenDatabase(pathOfDB)
  global dbOpenDict
  mdc_nelmts, rdcc_nslots, rdcc_bytes, rdcc_w0 = _h5_cache_cfg()
 
  # Build a proper FileAccessProperties object and initialize it
  fapl = HDF5.FileAccessProperties()
  HDF5.init!(fapl)  # Explicitly initialize the property list
  HDF5.API.h5p_set_cache(
    fapl,
    Cint(mdc_nelmts),
    Csize_t(rdcc_nslots),
    Csize_t(rdcc_bytes),
    Cdouble(rdcc_w0),
  )
 
  # Open with the property list; HDF5.jl will close the property list
  if !haskey(dbOpenDict, pathOfDB)
    db = HDF5.h5open(pathOfDB, "cw"; fapl=fapl)
    dbOpenDict[pathOfDB] = db
  end
end
 
 function CloseDatabase()
   for k in keys(dbOpenDict)
     try
       close(dbOpenDict[k])
     finally
       empty!(dbOpenDict)
     end
   end
 end
struct HDF5DataSetNotFoundException <: Exception
  db::String
  name::String
end

function _get_database_variable_names(
  db,
  group::Union{String,Nothing} = nothing,
  fuzzyname::Union{String,Nothing} = nothing,
)
  # Access the database in read mode and retrieve the fuzzy matched variable names
  names = h5open(db, "r") do f
    candidates = String[] # Initialize an empty array to store candidate variable names

    # Iterate through groups and datasets in the database
    for g in f, dataset in g
      # Remove leading slashes and store the dataset name as a candidate
      candidate = lstrip(HDF5.name(dataset), '/')

      # If no group is specified, add all candidates
      if group === nothing
        push!(candidates, candidate)
      else
        # Remove leading slashes from the group name
        group = lstrip(group, '/')

        # If the candidate starts with the group name, add it to the list
        if startswith(candidate, group)
          push!(candidates, candidate)
        end
      end
    end

    if fuzzyname === nothing
      # If no fuzzyname is specified, return all candidates
      candidates
    elseif group === nothing
      # If only fuzzyname is specified, sort by fuzzyname
      reverse.(Utils.fuzzysort(reverse("/" * fuzzyname), reverse.(candidates)))
    else
      # If both group and fuzzyname are specified, sort by group and fuzzyname
      reverse.(Utils.fuzzysort(reverse(group * "/" * fuzzyname), reverse.(candidates)))
    end
  end
  names
end

function Base.showerror(io::IO, e::HDF5DataSetNotFoundException)
  name = e.name
  n_matches = 5
  printstyled("$(typeof(e)): "; color = :red, bold = true)
  println(io, "Unable to find $(name).")
  println(io, "Top $n_matches fuzzy matches are:")
  candidates = _get_database_variable_names(e.db)
  candidates = reverse.(Utils.fuzzysort(reverse(basename(name)), reverse.(candidates)))
  for c in first(candidates, n_matches)
    print(io, "  ReadDisk(\"")
    printstyled(io, lstrip(c, '/'); color = :red)
    println(io, "\")")
  end
end

"""
    CreateDisk(db)

This creates a new database and initializes it with some metadata
"""
function CreateDisk(db)
  @info "CreateDisk - $db"
  # read-write, destroying any existing contents
  h5open(db, "w") do f
    f["metadata/created"] = string(Dates.now(Dates.UTC))
    f["metadata/hostname"] = gethostname()
    f["metadata/threads"] = Threads.nthreads()
  end
end

function throw_error_if_arr_contains_indefinite_values(arr, name)
  if eltype(arr) == String
    return false
  end
  # (any(isnan.(arr)) || any(isinf.(arr))) && error("$name contains at least one NaN or Inf. Something went wrong")
  return true
end


function CreateVariableInHDF5(db::String, name::String, sets::Tuple, doc::String, units::String)
  #@info "db $db"
  #@info "name $name"
  #@info "sets $sets"
  #@info "doc $doc"
  #@info "units $units"
  Dict(
    :db => db,
    :group => dirname(name),
    :name => basename(name),
    :ndims => length(sets),
    :dims => sets,
    :setdesc_locations => sets,
    :doc => doc,
    :units => units,
  )
end

"""
    ReadDisk(db::String, name::String, year::Int)
    ReadDisk(db::String, name::String)
    ReadDisk(::Type{DataFrame}, db::String, name::String; skip_zeros = false)
    ReadDisk(::Type{DataFrame}, db::String)

The `ReadDisk` functions provide a way to read data from an HDF5 file.

  - `ReadDisk(db, name, year)`: Reads a specific `year` slice from a 
     dataset named `name` in the HDF5 file specified by `db`. 
     Throws `HDF5DataSetNotFoundException` if the dataset is not found.
     
  - `ReadDisk(db, name)`: Reads the entire dataset named `name` from 
     the HDF5 file specified by `db`. Throws `HDF5DataSetNotFoundException`
     if the dataset is not found.
     
  - `ReadDisk(DataFrame, db, name; skip_zeros = false)`: Reads the dataset
     named `name` from the HDF5 file specified by `db` and returns a DataFrame.
     If `skip_zeros` is true, rows with zero values are omitted. Throws
     `HDF5DataSetNotFoundException` if the dataset is not found.
     
  - `ReadDisk(DataFrame, db)`: Reads a dataset from the HDF5 file specified
     by `db` and returns a DataFrame. The dataset is selected using an interactive menu.

# Examples

```julia
julia> name = "dataset_name"
db = "example.h5"

julia> data_all = ReadDisk(db, name)

julia> df_skip_zeros = ReadDisk(DataFrame, db, name; skip_zeros = true)
data_year = ReadDisk(db, name, 2020)

julia> df_selected = ReadDisk(DataFrame, db)

```
"""
function ReadDisk()
  nothing
end

function ReadDisk(db::String, dbAndVariableName::String, year::Int)
  if !haskey(dbOpenDict,db)
    OpenDatabase(db)
  end
  dbToReadWrite = dbOpenDict[db]
  if haskey(dbToReadWrite, dbAndVariableName)
    @assert last(attrs(dbToReadWrite[dbAndVariableName])["dims"]) == "Year" "Cannot use `ReadDisk($db, $dbAndVariableName, $year)` on array with dimensions $(attrs(dbToReadWrite[dbAndVariableName])["dims"])"
    ds = Any[(:) for _ in size(dataspace(dbToReadWrite[dbAndVariableName]))]
    ds[end] = year
    arr=dbToReadWrite[dbAndVariableName][ds...]
  else
    throw(HDF5DataSetNotFoundException(db, dbAndVariableName))
  end
  throw_error_if_arr_contains_indefinite_values(arr, dbAndVariableName)
  # @info "Loaded data for variable: $dbAndVariableName"
  arr
end

function ReadDisk(db::String, dbAndVariableName::String)
  # @info "Loading data for variable: $dbAndVariableName"
  if !haskey(dbOpenDict,db)
    OpenDatabase(db)
  end
  dbToReadWrite = dbOpenDict[db]
  if haskey(dbToReadWrite, dbAndVariableName)
    arr=read(dbToReadWrite[dbAndVariableName])
  else
    throw(HDF5DataSetNotFoundException(db, dbAndVariableName))
  end
  throw_error_if_arr_contains_indefinite_values(arr, dbAndVariableName)
  # @info "Loaded data for variable: $dbAndVariableName"  
  arr
end

function ReadDisk(::Type{DataFrame}, db::String, name::String; skip_zeros = false)
  h5open(db, "r") do f
    !haskey(f, name) && throw(HDF5DataSetNotFoundException(db, name))
    dataset = f[name]
    attr = Dict(attrs(dataset))
    get(attr, "type", "") != "variable" && error("`ReadDisk(DataFrame, db, \"$name\")` not supported for sets")
    function g(name, dim)
      if dim == "Unit"
        out = read(f["EGInput/UnCode"])
      else
        out = read(f["$(dirname(name))/$dim"])
      end
      n = length(out)
      if first(out) == "" 
        out = 1:n
      end
      return out
    end
    dims = [Symbol(dim) => collect(g(name,dim)) for dim in attr["dims"]]
    units = attr["units"]
    arr = read(dataset)
    df = allcombinations(DataFrame, dims...)
    df[!, :Value] = reshape(arr, (prod(size(arr)),))
    if "Year" in names(df)
      df.Year = parse.(Int, df.Year)
    end
    metadata!(df, "variable", basename(name); style = :note)
    metadata!(df, "group", dirname(name); style = :note)
    metadata!(df, "name", name; style = :note)
    metadata!(df, "units", isempty(units) ? missing : units; style = :note)
    if skip_zeros
      subset!(df, :Value => ByRow(!isapprox(0.0)))
    end
    df
  end
end

function ReadDisk(::Type{DataFrame}, db::String)
  is_variable(ds) = get(Dict(attrs(ds)), "type", "") == "variable"
  get_doc(ds) = get(Dict(attrs(ds)), "doc", "")
  dataset_names = h5open(
    f -> [(; name = HDF5.name(ds), doc = get_doc(ds)) for g in f for ds in f[HDF5.name(g)] if is_variable(ds)],
    db,
  )
  ReadDisk(DataFrame, db, String(first(split(QM.fzfmenu(["$n - $d" for (n, d) in dataset_names]), " - "))))
end

function ReadSets(db, name)
  attrs = data_attrs(db, name)
  get(attrs, "type", "") == "variable" || error(
    "$name has to be a multi-dimensional array. Expected type `\"variable\"`, found `\"$(attrs["type"])\"` instead.",
  )
  dims = h5open(db) do f
    [Symbol(dim) => collect(read(f["$(dirname(name))/$dim"])) for dim in attrs["dims"]]
  end
  keys = first.(dims)
  values = last.(dims)
  (; zip(keys, values)...)
end

function ReadDiskAndSets(db::String, name::String)
  arr = ReadDisk(db, name)
  dims = ReadSets(db, name)
  (; zip([Symbol(basename(name))], [arr])..., dims...)
end

function try_delete_and_get_attributes(f, n)
  # println("try_delete_and_get_attributes")
  # println(f)
  # println(eltype(f))
  
  if haskey(f, n)
    attr = Dict{String,Any}(attrs(f[n]))
    delete_object(f, n)
    attr
  else
    Dict{String,Any}()
  end
end


function InputDataIsGood(fullNameWithDB, nameToCompare)
  fullNameWithDBsplit = String.(split(fullNameWithDB, '/'))
#  dbName = fullNameWithDBsplit[1]
  variableNameInDbStatement = fullNameWithDBsplit[2]
  #println(variableNameInDbStatement)
  #println(nameToCompare)
  if variableNameInDbStatement==nameToCompare
    return true
  else
    error("Name in DB statement $fullNameWithDB does not match variable name $nameToCompare")
    return false
  end
end

"""
    WriteDisk(db::String, name::String, value; force = false)
    WriteDisk(db::String, name::String, year::Int, value)
    WriteDisk(db::String, data::HDF5GroupDatabase)

The `WriteDisk` functions provide a way to write data to an HDF5 file.

  - `WriteDisk(db, name, value; force = false)`: Writes `value` to the dataset named `name` in the HDF5 file specified by `db`. If `force` is true, overwrites the existing dataset. Otherwise, preserves attributes of the existing dataset.
  - `WriteDisk(db, name, year, value)`: Writes `value` to a specific `year` slice of the dataset named `name` in the HDF5 file specified by `db`.
  - `WriteDisk(db, data::HDF5GroupDatabase)`: Writes the `data` object of type `HDF5GroupDatabase` to the HDF5 file specified by `db`. The `data` object should have fields corresponding to the dataset names and values.

# Examples

```julia
julia> name = "dataset_name"
db = "example.h5"

julia> WriteDisk(db, name, 2020, value)

```
"""
function WriteDisk end

function WriteDisk(db::String, dbAndVariableName::String, variableToWrite, variableName)
  throw_error_if_arr_contains_indefinite_values(variableToWrite, dbAndVariableName)
  if InputDataIsGood(dbAndVariableName,variableName)==true  
    if !haskey(dbOpenDict,db)
      OpenDatabase(db)
    end
    dbToReadWrite = dbOpenDict[db]
    if haskey(dbToReadWrite, dbAndVariableName)
      attr = try_delete_and_get_attributes(dbToReadWrite, dbAndVariableName)
      if eltype(variableToWrite) == String
        dbToReadWrite[dbAndVariableName] = variableToWrite
      else
        dbToReadWrite[dbAndVariableName, deflate = HDF5_Compression_Level] = variableToWrite
      end
      for (k, v) in attr
        attrs(dbToReadWrite[dbAndVariableName])[k] = v
      end
    else
      throw(HDF5DataSetNotFoundException(db, dbAndVariableName))
    end
    HDF5.flush(dbToReadWrite)
  end  
end

function WriteDisk(db::String, dbAndVariableName::String, variableToWrite; force = false)
  throw_error_if_arr_contains_indefinite_values(variableToWrite, dbAndVariableName)
  if !haskey(dbOpenDict,db)
    OpenDatabase(db)
  end
  dbToReadWrite = dbOpenDict[db]
  if haskey(dbToReadWrite, dbAndVariableName)
    attr = try_delete_and_get_attributes(dbToReadWrite, dbAndVariableName)
    if eltype(variableToWrite) == String
      dbToReadWrite[dbAndVariableName] = variableToWrite
    else
      dbToReadWrite[dbAndVariableName, deflate = HDF5_Compression_Level[]] = variableToWrite
    end
    for (k, v) in attr
      attrs(dbToReadWrite[dbAndVariableName])[k] = v
    end
  else
    throw(HDF5DataSetNotFoundException(db, dbAndVariableName))
  end
  HDF5.flush(dbToReadWrite)
end

#RobX 10/10/2025: can we delete this function? Not sure where it is ever used
function WriteDiskwithCheck(db::String, dbAndVariableName::String, variableToWrite; force = false)
  throw_error_if_arr_contains_indefinite_values(variableToWrite, dbAndVariableName)
  
  if dbOpen==false
  end

  if InputDataIsGood(dbAndVariableName,variableName)==true  
    h5open(db, "cw") do f
      !haskey(f, dbAndVariableName) && throw(HDF5DataSetNotFoundException(db, dbAndVariableName))
      attr = try_delete_and_get_attributes(f, dbAndVariableName)
      if eltype(variableToWrite) == String
        f[dbAndVariableName] = variableToWrite
      else
        f[dbAndVariableName, deflate = HDF5_Compression_Level] = variableToWrite
      end
      for (k, v) in attr
        attrs(f[dbAndVariableName])[k] = v
    #    println( attrs(f[dbAndVariableName])[k])
      end
    end
  end
end


function WriteDisk(db::String, name::String, year::Int, value)
  throw_error_if_arr_contains_indefinite_values(value, name)
  if !haskey(dbOpenDict,db)
    OpenDatabase(db)
  end
  dbToReadWrite = dbOpenDict[db]
  ds = Any[(:) for _ in size(dataspace(dbToReadWrite[name]))]
  ds[end] = year
  if eltype(value) == String
    dbToReadWrite[name][ds...] = value
  else
    dbToReadWrite[name][ds...] = value
  end
  HDF5.flush(dbToReadWrite)
end


# function WriteDisk(db::String, name::String, year::Int, value)
#   throw_error_if_arr_contains_indefinite_values(value, name)
#   h5open(db, "cw") do f
#     # year = year - ITime + 1 We can comment this out once year becomes and index
#     ds = Any[(:) for _ in size(dataspace(f[name]))]
#     ds[end] = year
#     if eltype(value) == String
#       f[name][ds...] = value
#     else
#       f[name][ds...] = value
#     end
#   end
# end

function ReadSetLocationsFromCSV()
  # 
  # Read .csv from fixed location below, then use the two columns to creat
  # a dictionary for use in outputing dimension DS locations in HDF5 attributes.
  #
  # Code borrows from ReadSetsFromCSV(), can maybe be merged in future - Ian 01/12/26
  #
  SetsPath= ModelPath * "\\DataBase\\Sets\\"
  SetFileName::String = SetsPath * "SetDSLocations.csv"
  SetLocationDict = Dict{String,String}()
  open(SetFileName) do setDescs
    for line in eachline(setDescs)
      lineSplit = split(line, ",")
      SetName = String(lineSplit[1])
      NameInFile = String(lineSplit[2])
      SetLocationDict[SetName] = NameInFile
    end
  end
  return SetLocationDict
end

function FindDimsLoc(value,num_dims,setlocation_dict::Dict)

  #
  # Reads in the set names from database attributes and returns the equivalent
  # value from dictionary as a tuple in same order
  #
  sets = value[:dims]
  group = value[:group]
  count = 1:num_dims
  dim_loc = Vector{String}(undef,num_dims)
  for i in count
    key= string(sets[i])
    loc = get(setlocation_dict,key,"Missing")
    
    #
    # 'XInput' means that the variable is on the segment database, 
    # so we need to look up which segment the variable is in and replace
    # the character
    #
    if loc[1] == 'X'
      segment_location = String(group)
      loc = segment_location[1] * lstrip(loc,'X')
    end
    dim_loc[i] = loc
  end
  return dim_loc
end

function WriteDisk(db::String, data::HDF5GroupDatabase)
  prefix = last(split(string(typeof(data)), '.'))
  @info "Running WriteDisk($db, $prefix)"
###  prefix = lowercase(prefix) # remove this line if you want database prefix to not be lowercase
  h5open(db, "cw") do f
    #
    # Create dictionary to be used for dims_loc attribute
    #
    # TODOJulia: This should be probably be created elsewhere and dict imported
    # Located here to avoid getting called for every variable, but still
    # gets called for every statement in ModelDatabaseCreate.jl - Ian 01/12/26
    #
    setlocation_dict::Dict{String,String} = ReadSetLocationsFromCSV()
    
    for name in fieldnames(typeof(data))
      value = getfield(data, name)
      if value isa Vector
        n = "$prefix/$name"
        attr = try_delete_and_get_attributes(f, n)
        v = value
        if eltype(v) == String
          f[n] = v
        else
          f[n, deflate = HDF5_Compression_Level] = v
        end
        dataset = f[n]
        for (k, v) in attr
          attrs(dataset)[k] = v
        end
        attrs(dataset)["type"] = "set"
      elseif value isa AbstractDict
        @assert prefix == value[:group] "group in $value must be $prefix"
        n = "$(value[:group])/$(value[:name])"
        attr = try_delete_and_get_attributes(f, n)
        dims = collect(getfield(data, field) for field in value[:dims])
        # NOTE (Dheepak): The following does much faster dataset creation by preventing the need to preallocate
        #                 More tuning of compression level may be required.
        dataset = if length(dims) == 1
          arr = zeros(Float32, length.(dims)...)
          f[n] = arr
          dataset = f[n]
        else
          HDF5.create_dataset(
            f,
            n,
            datatype(Float32),
            dataspace(length.(dims)...);
            chunk = HDF5.heuristic_chunk(Float32, length.(dims)),
            deflate = HDF5_Compression_Level,
            alloc_time = :early,
            fill_time = :alloc,
          )
        end
        for (k, v) in attr
          attrs(dataset)[k] = v
        end
        set_locations = FindDimsLoc(value,length(dims),setlocation_dict)
        attrs(dataset)["type"] = "variable"
        attrs(dataset)["dims"] = collect(string.(value[:dims]))
        attrs(dataset)["setdesc_locations"] = set_locations[:]
        attrs(dataset)["ndims"] = length(dims)
        attrs(dataset)["doc"] = strip(value[:doc])
        attrs(dataset)["units"] = strip(value[:units])
      else
        n = "$prefix/$name"
        attr = try_delete_and_get_attributes(f, n)
        f[n] = value
        dataset = f[n]
        for (k, v) in attr
          attrs(dataset)[k] = v
        end
        attrs(dataset)["type"] = "scalar"
      end
    end
  end
end

"""
    ModifyDisk(func::Function, db::String, names...)

The `ModifyDisk` function allows modification of one or more datasets in an HDF5 file specified by `db` using a user-defined function `func`.

  - `func`: A function that takes the datasets' values as input, modifies them, and returns nothing.
  - `db`: The path to the HDF5 file.
  - `names...`: The names of the datasets to be modified.

The function reads the specified datasets, applies the user-defined function, and writes the modified values back to the HDF5 file.

# Examples

```julia
julia> names = ("dataset1", "dataset2")
db = "example.h5"

julia> function modify_datasets!(a, b)
         a .*= 2
         b .+= 1
       end

julia> ModifyDisk(modify_datasets!, db, names...)

julia> ModifyDisk(db, names...) do (a, b)
         a .*= 2
         b .+= 1
       end

```
"""
function ModifyDisk(func::Function, db::String, names...)
  @debug "Running ModifyDisk($db, $(join(names, " ")))"
  # Open hdf5 database
  h5open(db, "cw") do f
    # Check if name in in the database, if not throw an error
    for name in names
      !haskey(f, name) && throw(HDF5DataSetNotFoundException(db, name))
    end

    # Read all inputs from the database
    # `collect` is required here because we want to pass these values by reference
    values = collect(read(f[name]) for name in names)

    # Call user defined function with those inputs
    func(values...)

    for (name, value) in zip(names, values)
      throw_error_if_arr_contains_indefinite_values(value, name)
    end

    # Write all inputs after deleting them from the database
    for (n, v) in zip(names, values)
      attr = try_delete_and_get_attributes(f, n)
      if eltype(v) == String
        f[n] = v
      else
        f[n, deflate = HDF5_Compression_Level] = v
      end
      for (k, v) in attr
        attrs(f[n])[k] = v
      end
    end
  end
  nothing
end


"""
    ModifyDiskAndSets(func::Function, db::String, name::String)

Read, modify and write data in one function
"""
function ModifyDiskAndSets(func::Function, db::String, name::String)
  nt = ReadDiskAndSets(db, name)
  func(nt)
  WriteDisk(db, name, getfield(nt, Symbol(basename(name))))
end


"""
    data_attrs(db, name)

Returns a dictionary containing attributes and size of a dataset specified by `name` in an HDF5 file `db`.

# Arguments

  - `db::String`: A string representing the path to the HDF5 file.
  - `name::String`: A string representing the name of the dataset within the HDF5 file.

# Returns

  - `Dict`: A dictionary containing the dataset attributes as key-value pairs, as well as the size of the dataset with the key "size".

# Example

```julia
db = "path/to/hdf5/file.h5"
name = "dataset_name"
attributes = data_attrs(db, name)
```
"""
function data_attrs(db, name)
  h5open(db) do f
    d = Dict(attrs(f[name]))
    d["size"] = size(f[name])
    d
  end
end

"""
data_names(db)

Returns a vector of dataset names in an HDF5 file specified by db.

# Arguments

  - db::String: A string representing the path to the HDF5 file.

# Returns

  - Vector{String}: A vector of strings, where each string represents a dataset name in the HDF5 file.

# Example

```julia
db = "path/to/hdf5/file.h5"
dataset_names = data_names(db)
```
"""
data_names(db) = HDF5.h5open(f -> String[lstrip(HDF5.name(ds), '/') for g in f for ds in f[HDF5.name(g)]], db)
