#
# zUnStorage.jl
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

Base.@kwdef struct zUnStorageData
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
  
  zUnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") #[Unit]  Storage Switch (1=Storage Unit)
  zUnStorageRef::VariableArray{1} = ReadDisk(RefNameDB,"EGInput/UnStorage") #[Unit]  Storage Switch (1=Storage Unit)

  #
  # Scratch Variables for Unit selection between Reference and Policy
  #
  Conversion = zeros(Float32,length(Nation),length(Year)) # [Year] Units Conversion Factor
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
  data = zUnStorageData(;db)
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

function zUnStorage_AssignConversions(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Switch"
  UnitsDS[CN] = "Switch"
  
end

function zUnStorage_WriteValues(data,iob,UnitPolicy,UnitReference,nation)
  (; Nation,Year) = data
  (; Conversion,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,zUnStorage,zUnStorageRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
    
      if UnitPolicy != 0
        ZZZ = zUnStorage[UnitPolicy]*Conversion[nation]
        OutputUnCode = UnCode[UnitPolicy]
      end
      
      if UnitReference != 0
        CCC = zUnStorageRef[UnitReference]*Conversion[nation]
        OutputUnCode = UnCodeRef[UnitReference]
      end  
      
      if UnNation[UnitPolicy] == Nation[nation]
        println(iob,"zUnStorage;",OutputUnCode,";",UnitsDS[nation],
                    ";",@sprintf("%.0F",ZZZ),";",@sprintf("%.0F",CCC))
      end
      
  end
end

function zUnStorage_DtaRun(data,nation)
  (; Nation,Units,Year,Years,SceName) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,zUnStorage,zUnStorageRef) = data

  if BaseSw != 0
    @. zUnStorageRef = zUnStorage
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    if UnNation[CurrentUnit] == Nation[nation]
      UnitPolicy,UnitReference = FindUnitsToOutput(UnCode[CurrentUnit])
      zUnStorage_WriteValues(data,iob,UnitPolicy,UnitReference,nation)
    end
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zUnStorage-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function zUnStorage_DtaRun

function zUnStorage_DtaControl(db)
  data = zUnStorageData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "zUnStorage_DtaControl"

  zUnStorage_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    BuildUnitList(nation)
    if NationOutputMap[nation] == 1
      zUnStorage_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zUnStorage_DtaControl(DB)
end
