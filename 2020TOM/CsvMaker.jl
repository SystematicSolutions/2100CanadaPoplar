#
# CsvMaker.jl
#
#import Pkg;
# Pkg.add("HDF5")
# Pkg.add("DataFrames")
# Pkg.add("CSV")
# Pkg.add("Printf")
begin
  try
    using CSV, DataFrames, DelimitedFiles, HDF5, Printf
  catch
    # Allow loading without external deps in test contexts
    using DelimitedFiles, Printf
  end
end
# Load core functionality (ReadDisk, ReadSetFromCSV, etc.)
include("../Core/Core.jl") 
db=DatabaseName
if length(ARGS) > 0
  startDirectory = pwd()
  ModelRoot=startDirectory
  TomRoot = ModelRoot * "\\"
  CsvFileName = TomRoot * ARGS[2]
  println("Model Root " * ModelRoot)
  println("Input Parameter " * ARGS[1])
  println("Input Parameter " * ARGS[2])
  
  if length(ARGS) > 2
    StartYear=parse(Int,ARGS[3])
    EndYear=parse(Int,ARGS[4])
    println("StartYear " * ARGS[3])
    println("EndYear " * ARGS[4])
  else
    StartYear=2022
    EndYear=2050
  end
else
  ModelRoot ="C:\\2020CanadaRedwoodTOM\\"
  TomRoot = ModelRoot *  "2020TOM\\" 
  CsvFileName = TomRoot * "Test.csv"
  StartYear=1985
  EndYear=2050
end

Base.@kwdef struct CsvMaker
  db::String
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOM")
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOM")
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM")
  IsActiveToFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToFuelTOM")
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
end

struct SetIndex
  labels_ds::Vector{String}
  labels_key::Vector{String}
end

mutable struct MapRow
  EnergyVariableName::String # Energy Model Variable Name
  ConcatSets::String # Energy Model Sets (ie ECCTOM&AreaTOM&Year)
  Units::String # Variable Units (ie 2017 $M/Yr)
  Direction::String # TOMtoE2020 or E2020toTOM
  TOMVariableName::String # TOM Model Variable Name
end

function ReadMapping(Mapping_path)
  Rows = MapRow[]
  open(Mapping_path, "r") do io
    first = true
    for line in eachline(io)
      if first
        first = false
        continue
      end
      Columns = split(line, ",")
      length(Columns) >= 5 || continue
      e2020 = String(Columns[1])
      sets_raw = String(Columns[2])
      units = String(Columns[3])
      direction = String(Columns[4])
      tom = String(Columns[5])
      push!(Rows, MapRow(e2020, sets_raw, units, direction, tom))
    end
  end
  return Rows
end

SetsPath=ModelPath * "\\Database\\Sets\\"
TomToE2020MapPath =  TomRoot * "KOutput.csv"   
Mapping = ReadMapping(TomToE2020MapPath)
SetCache = Dict{String,SetIndex}()

function WriteTomPeriodData(CsvFile)
  write(CsvFile,"V,L,")
  write(CsvFile,string(StartYear) * "01,")
  write(CsvFile,string(EndYear) * "01,")
  write(CsvFile,string(EndYear) * "01,")
  Periods = EndYear - StartYear + 1
  write(CsvFile,string(Periods) * "@01,")
end
function WriteAreaInfo(area,TomVarName,TomCsvFile)
  write(TomCsvFile,"KOutput,")
  write(TomCsvFile,"$area,") 
  write(TomCsvFile,"$TomVarName,")
  WriteTomPeriodData(TomCsvFile)
end
function LoadSet(Path)
  isfile(Path) || error("Set file not found: " * Path)
  DS = String[]
  Key = String[]
  open(Path, "r") do io
    for line in eachline(io)
      s = split(line, ",")
      if length(s) >= 2
        push!(DS, String(s[1]))
        push!(Key, String(s[2]))
      elseif length(s) == 1
        push!(DS, String(s[1]))
        push!(Key, "")
      end
    end
  end
  return SetIndex(DS, Key)
end
function Adjust3DimName(OriginalName, SetsToAdd)
  if occursin("_", OriginalName)
    i = findfirst(==('_'), OriginalName)
    Front = SubString(OriginalName, 1, i-1)
    Tail = SubString(OriginalName, i+1)
    FinalName =  String(Front) * SetsToAdd * "_" * String(Tail)
  else
    FinalName=OriginalName * SetsToAdd
  end
  return FinalName
end
function GetSet(name::AbstractString)
  if haskey(SetCache, name)
      return SetCache[name]
    end
    path = SetsPath * name * ".csv"
    si = LoadSet(path)
    SetCache[name] = si
    return si
  
end
function WriteLineToCsv(combo,row,io,StartIndex,EndIndex,VariableToWrite)
  n = length(combo)
  AreaLabel = combo[n][1]
  SetLabels = n > 1 ? [combo[i][1] for i in 1:n-1] : String[]

  name_out = if length(SetLabels) == 0
    row.TOMVariableName
  elseif length(SetLabels) == 1
    Adjust3DimName(row.TOMVariableName, SetLabels[1])
  else
    row.TOMVariableName * SetLabels[1] * SetLabels[2]
  end

  WriteAreaInfo(AreaLabel, name_out, io)
  idxs = ntuple(i -> combo[i][2], n)
  @inbounds for y in StartIndex:EndIndex
    print(io, VariableToWrite[idxs..., y])
    write(io, ",")
  end
  write(io, "\n")
end

function GetSetIndexForVariable(VariableDimensions,SetToCheck)
  DimCount = length(VariableDimensions)
  if DimCount > 0
    for index in 1:DimCount
     
      if VariableDimensions[index]==SetToCheck
         return index
      end
    end
  else
    return 0
  end  
  return 0
end

function MakeCsvForTom(db)
  data = CsvMaker(; db)
  (; IsActiveToECCTOM,IsActiveToFuelTOM,ToTOMVariable) = data
  StartIndex = StartYear - 1985 + 1
  EndIndex   = EndYear   - 1985 + 1
  @assert EndIndex >= StartIndex "EndYear must be >= StartYear"
  @assert StartIndex >= 1 "StartYear ($(StartYear)) precedes 1985"

  TempCsvFile = CsvFileName * ".tmp"
  open(TempCsvFile, "w") do io
    for row in Mapping
      (row.Direction == "E2020toTOM" || row.Direction == "Both") || continue
      VariableToWrite = ReadDisk(db, "KOutput/" * row.EnergyVariableName)
      SetsSplit = split(row.ConcatSets, "&"; keepempty=true)
      SetCount = length(SetsSplit)
      AreaIndex = SetCount - 1
      AreaName = SetsSplit[AreaIndex]
      
      if SetCount > 1
        ExtraDims = SetsSplit[1:AreaIndex-1]
      else
       ExtraDims=[]
      end
      AreaSetPairs = GetSet(AreaName)
      ExtraDimsMap = Vector{Vector{Tuple{String,Int}}}(undef, length(ExtraDims))
      for (setIndex, setName) in pairs(ExtraDims)
        SetPairs = GetSet(setName * "label")
        lbls = SetPairs.labels_key
        KeyValuePairs = Vector{Tuple{String,Int}}(undef, length(lbls))
        @inbounds for (i, lbl) in enumerate(lbls)
          KeyValuePairs[i] = (lbl, i)
        end
        ExtraDimsMap[setIndex] = KeyValuePairs
      end
     
      AreaCombos = Vector{Tuple{String,Int}}(undef, length(AreaSetPairs.labels_ds))
      @inbounds for (i, lbl) in enumerate(AreaSetPairs.labels_ds)
        AreaCombos[i] = (lbl, i)
      end

      dims = (ExtraDimsMap..., AreaCombos)
                
      for combo in Iterators.product(dims...)
        VariableMapIndex = findfirst(item -> item == row.EnergyVariableName,ToTOMVariable)
        EccTOMIndex = GetSetIndexForVariable(ExtraDims,"ECCTOM")
        FuelTOMIndex = GetSetIndexForVariable(ExtraDims,"FuelTOM")
        
        # ECC no Fuel
        if EccTOMIndex > 0
          if FuelTOMIndex==0
            ECC = combo[EccTOMIndex][2] 
            if IsActiveToECCTOM[ECC,VariableMapIndex]==1.0
              WriteLineToCsv(combo,row,io,StartIndex,EndIndex,VariableToWrite)    
            end
          end
        end
        
        # Fuel no ECC
        
        if EccTOMIndex==0
          if FuelTOMIndex > 0
            Fuel = combo[FuelTOMIndex][2] 
            if IsActiveToFuelTOM[Fuel,VariableMapIndex]==1.0
              WriteLineToCsv(combo,row,io,StartIndex,EndIndex,VariableToWrite)    
            end
          end
        end
        
        # Fuel and ECC
        if EccTOMIndex > 0
          if FuelTOMIndex > 0
            Fuel = combo[FuelTOMIndex][2] 
            ECC = combo[EccTOMIndex][2] 
            if IsActiveToFuelTOM[Fuel,VariableMapIndex]==1.0
              if IsActiveToECCTOM[ECC,VariableMapIndex]==1.0  
                WriteLineToCsv(combo,row,io,StartIndex,EndIndex,VariableToWrite)    
              end
            end
          end
        end
        # no ECC no Fuel
        if EccTOMIndex==0
          if FuelTOMIndex==0
            WriteLineToCsv(combo,row,io,StartIndex,EndIndex,VariableToWrite)
          end
        end
      end
    end
  end

  # Replace atomically
  Base.mv(TempCsvFile, CsvFileName; force=true)
  nothing
end

function MakeTomCsv(db)
  @time MakeCsvForTom(db)
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
  MakeTomCsv(DB)
  println("TOM CSV Created!")
end
