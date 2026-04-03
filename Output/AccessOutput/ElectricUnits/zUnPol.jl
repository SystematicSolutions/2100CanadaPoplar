#
# zUnPol.jl
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

Base.@kwdef struct zUnPolData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
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
  
  zUnPol::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)
  zUnPolRef::VariableArray{4} = ReadDisk(RefNameDB,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution (Tonnes)

  #
  # Scratch Variables for Unit selection between Reference and Policy
  #
  Conversion = zeros(Float32,length(Poll),length(Year)) # [Poll,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description

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
  data = zUnPolData(;db)
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

function zUnPol_AssignConversions(data)
  (; Poll,Polls,Years,Conversion,UnitsDS) = data
  
  Hg = Select(Poll,"Hg")
  
  for poll in Polls
    for year in Years
      Conversion[poll,year] = 0.001
    end
    UnitsDS[poll] = "Kilotonnes"
  end
  
  for year in Years
    Conversion[Hg,year] = 1000
  end
  UnitsDS[Hg] = "Kilograms"
  
end

function zUnPol_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  (; FuelEP,FuelEPDS,FuelEPs,Poll,PollDS,Polls,Year) = data
  (; Conversion,UnCode,UnCodeRef,UnitsDS) = data
  (; zUnPol,zUnPolRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
  
    for year in years, poll in Polls, fuelep in FuelEPs
    
      if UnitPolicy != 0
        ZZZ = zUnPol[UnitPolicy,fuelep,poll,year]*Conversion[poll,year]
        OutputUnCode = UnCode[UnitPolicy]
      end
      
      if UnitReference != 0
        CCC = zUnPolRef[UnitReference,fuelep,poll,year]*Conversion[poll,year]
        OutputUnCode = UnCodeRef[UnitReference]
      end  
      
      if (ZZZ != 0 || CCC != 0)
        println(iob,"zUnPol;",Year[year],";",PollDS[poll],";",FuelEPDS[fuelep],";",OutputUnCode,
        	";",UnitsDS[poll],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
      
    end
  end
end

function zUnPol_DtaRun(data,nation)
  (; Nation,Units,Year,Years,SceName) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,zUnPol,zUnPolRef,SceName) = data

  if BaseSw != 0
    @. zUnPolRef = zUnPol
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Pollutant;Fuel;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    if UnNation[CurrentUnit] == Nation[nation]
      UnitPolicy,UnitReference = FindUnitsToOutput(UnCode[CurrentUnit])
      zUnPol_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
    end
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zUnPol-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function zUnPol_DtaRun

function zUnPol_DtaControl(db)
  data = zUnPolData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "zUnPol_DtaControl"

  zUnPol_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    BuildUnitList(nation)
    if NationOutputMap[nation] == 1
      zUnPol_DtaRun(data,nation)
    end
  end
end
  
if abspath(PROGRAM_FILE) == @__FILE__
  zUnPol_DtaControl(DB)
end
