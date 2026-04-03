#
# HistoricalGeneration.jl
#
using EnergyModel

module HistoricalGeneration

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  xEGPA::VariableArray{3} = ReadDisk(db,"EGInput/xEGPA") # [Plant,Area,Year] Historical Electricity Generated (GWh/Yr)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation (GWh)

  # Scratch Variables
end

function GetUnitSets(data,unit)
  (; Area,Plant) = data
  (; UnArea,UnPlant) = data
  #
  # This procedure selects the sets for a particular unit
  #
  if (UnPlant[unit] != "Null") && (UnArea[unit] != "Null")
    plant = Select(Plant,UnPlant[unit])
    area = Select(Area,UnArea[unit])
    valid = true
  else
    plant=1
    area=1
    valid = false
  end
  return plant,area,valid
end

function UpdateHistorical(data)
  (;db) = data
  (;Units,Years,Yrv) = data
  (;UnCogen,UnOnLine,UnRetire,xEGPA,xUnEGA) = data

  @.xEGPA=0
  for unit in Units, year in Years
    if (UnOnLine[unit] <= Yrv[year]) && (UnRetire[unit,year] > Yrv[year]) && (UnCogen[unit] == 0)
      plant,area,valid = GetUnitSets(data,unit)
      if valid==true
        xEGPA[plant,area,year]=xEGPA[plant,area,year]+xUnEGA[unit,year]
      end
    end
  end

  WriteDisk(db,"EGInput/xEGPA",xEGPA)

end

function ECalibration(db)
  data = EControl(; db)

  UpdateHistorical(data)

end

function CalibrationControl(db)
  @info "HistoricalGeneration.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
