#
# zUnOnLine.jl
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct zUnOnLineData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  RefUnit::SetArray = ReadDisk(RefNameDB,"MainDB/UnitKey")
  RefUnits::Vector{Int} = collect(Select(RefUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCodeRef::Array{String} = ReadDisk(RefNameDB,"EGInput/UnCode") # [Unit] Unit Code
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") #[Year]  Number of Units
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNationRef::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  zUnOnLine::VariableArray{1} = ReadDisk(db, "EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  zUnOnLineRef::VariableArray{1} = ReadDisk(RefNameDB, "EGInput/UnOnLine") #[Unit]  On-Line Date (Year)

  #
  # Scratch Variables for Unit selection between Reference and Policy
  #
  Conversion = zeros(Float32,length(Nation)) # [Nation] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  # CurrentUnit   'Pointer to the Unit being Processed (Number)'
  # OutputUnCode   'Code for the Unit being Output (Number)',  Type=String(20)
  # PolicyUnit    'Pointer to Policy Unit (Number)'
  # ReferenceUnit 'Pointer to Reference Unit (Number)'

end

PolicyUnits::Vector{String}=[]
ReferenceUnits::Vector{String}=[]
#
# Built Unit List for Matching
#
function BuildUnitList(nation)
  db = DB
  data = zUnOnLineData(;db)
  (; Nation,RefUnits,Units) = data
  (; UnCode,UnCodeRef,UnNation,UnNationRef) = data
  for unit in Units
    push!(PolicyUnits,UnCode[unit])
  end
  for unit in RefUnits
    push!(ReferenceUnits,UnCodeRef[unit])
  end
end # function FindUnitsToOutput


#
# Find matching Reference case Unit
#
function FindUnitsToOutput(CurrentCode)
  PolicyUnit = findfirst(==(CurrentCode),PolicyUnits)
  ReferenceUnit = findfirst(==(CurrentCode),ReferenceUnits)
  return PolicyUnit,ReferenceUnit
  
end # function FindUnitsToOutput

function zUnOnLine_AssignConversions(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  Conversion[US] = 1.0
  Conversion[CN] = 1.0

  UnitsDS[US] = "Year"
  UnitsDS[CN] = "Year"
  
end

function zUnOnLine_WriteValues(data,iob,UnitPolicy,UnitReference,nation)
  (; Year) = data
  (; Conversion,UnCode,UnCodeRef,UnitsDS) = data
  (; zUnOnLine,zUnOnLineRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
    
      if UnitPolicy != 0
        ZZZ = zUnOnLine[UnitPolicy]*Conversion[nation]
        OutputUnCode = UnCode[UnitPolicy]
      end
      
      if UnitReference != 0
        CCC = zUnOnLineRef[UnitReference]*Conversion[nation]
        OutputUnCode = UnCodeRef[UnitReference]
      end  
      
      if (ZZZ != 0 || CCC != 0)
        println(iob,"zUnOnLine;",OutputUnCode,";",UnitsDS[nation],
                    ";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
      
  end
end

function zUnOnLine_DtaRun(data,nation)
  (; Nation,Units,Year,Years) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,zUnOnLine,zUnOnLineRef,SceName) = data

  if BaseSw != 0
    @. zUnOnLineRef = zUnOnLine
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    if UnNation[CurrentUnit] == Nation[nation]
      UnitPolicy,UnitReference = FindUnitsToOutput(UnCode[CurrentUnit])
      zUnOnLine_WriteValues(data,iob,UnitPolicy,UnitReference,nation)
    end
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zUnOnLine-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function zUnOnLine_DtaRun

function zUnOnLine_DtaControl(db)
  data = zUnOnLineData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "zUnOnLine_DtaControl"

  zUnOnLine_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    BuildUnitList(nation)
    if NationOutputMap[nation] == 1
      zUnOnLine_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zUnOnLine_DtaControl(DB)
end
