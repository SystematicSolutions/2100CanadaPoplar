#
# qUnSqFr.jl
#

using EnergyModel

module qUnSqFr

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using ..EnergyModel: HDF5DataSetNotFoundException,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct qUnSqFrData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
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
  
  qUnSqFr::VariableArray{3} = ReadDisk(db,"EGInput/UnSqFr") # [Unit,Poll,Year] Sequestered Pollution Fraction (Tonnes/Tonnes)
  qUnSqFrRef::VariableArray{3} = ReadDisk(RefNameDB,"EGInput/UnSqFr") # [Unit,Poll,Year] Sequestered Pollution Fraction (Tonnes/Tonnes)
  
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


function FindUnitsToOutput(CurrentUnit,nation)
  db = DB
  data = qUnSqFrData(;db)
  (; Nation,Units) = data
  (; UnCode,UnCodeRef,UnNation,UnNationRef) = data

    PolicyUnit = 0
    for unit in Units
      if UnCode[unit] == UnCode[CurrentUnit] && UnNation[unit] == Nation[nation]
        PolicyUnit = CurrentUnit
      end
    end
 
    ReferenceUnit = 0
    for unit in Units
      if UnCodeRef[unit] == UnCode[CurrentUnit] && UnNationRef[unit] == Nation[nation]
        ReferenceUnit = unit
      end
    end

  return PolicyUnit,ReferenceUnit
  
end # function FindUnitsToOutput


function qUnSqFr_AssignConversions(data)
  (; Nation,Month,Poll,Polls,Years,Conversion,Unit,Units,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Tonne/Tonne"
  UnitsDS[CN] = "Tonne/Tonne"
  
end

function qUnSqFr_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  (; Month,Months,Poll,PollDS,Polls,Unit,Units,Year) = data
  (; Conversion,UnCode,UnitsDS,qUnSqFr,qUnSqFrRef) = data
  
  ZZZ = 0.0
  CCC = 0.0
        
  if UnitPolicy != 0 || UnitReference != 0
  
    for year in years, poll in Polls
    
      if UnitPolicy != 0
        ZZZ = qUnSqFr[UnitPolicy,poll,year]*Conversion[nation,year]
        OutputUnCode = UnCode[UnitPolicy]
      end
      
      if UnitReference != 0
          CCC = qUnSqFrRef[UnitReference,poll,year]*Conversion[nation,year]
        OutputUnCode = UnCode[UnitReference]
      end  
      
      if (ZZZ != 0 || CCC != 0)
          println(iob,"qUnSqFr;",UnitsDS[nation],";",PollDS[poll],";",OutputUnCode,";",Year[year],
                    ";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end

    end
  end
end

function qUnSqFr_DtaRun(data,nation,SceName)
  (; Nation,Units,Year,Years) = data
  (; BaseSw,Conversion,EndTime,UnCode,UnCodeRef,UnitsDS) = data
  (; UnNation,UnNationRef,qUnSqFr,qUnSqFrRef) = data

  if BaseSw != 0
    @. qUnSqFrRef = qUnSqFr
    @. UnCodeRef = UnCode
    @. UnNationRef = UnNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Poll;Unit;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  for CurrentUnit in Units
    UnitPolicy,UnitReference = FindUnitsToOutput(CurrentUnit,nation)
    qUnSqFr_WriteValues(data,iob,UnitPolicy,UnitReference,nation,years)
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "qUnSqFr-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end # function qUnSqFr_DtaRun

function qUnSqFr_DtaControl(db, SceName)
  data = qUnSqFrData(; db)
  (; Nation)= data
  (; NationOutputMap)= data
  
  @info "qUnSqFr_DtaControl"

  qUnSqFr_AssignConversions(data)
  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      qUnSqFr_DtaRun(data,nation,SceName)
    end
  end
end

#function Control(db,SceName)
#  @info "qUnSqFr.jl - Control"
#  qUnSqFr_DtaControl(db,SceName)
#end

#if abspath(PROGRAM_FILE) == @__FILE__
#  Control(DB)
#end

end
