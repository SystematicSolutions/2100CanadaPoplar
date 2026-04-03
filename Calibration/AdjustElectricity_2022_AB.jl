#
# AdjustElectricity_2022_AB.jl - Set Outage Rate and Energy Availability Factor
# for AB units.
#
using EnergyModel

module AdjustElectricity_2022_AB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  AvFactor::VariableArray{5} = ReadDisk(db,"EGInput/AvFactor") # [Plant,TimeP,Month,Area,Year] Availability Factor (MW/MW)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UnEGA") # [Unit,Year] Generation (GWh)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation (GWh)
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
end

function ECalibration(db)
  data = EControl(; db)
  (;TimePs,Area,Months,Plant,) = data
  (;AvFactor,UnArea,UnOR,UnPlant) = data
  (;UnMustRun) = data

  # 
  # Calibrate SK generation in 2022 with UnOR, updated RST 02Sept2023
  # 
  unit1 = findall(UnArea .== "SK")
  unit2 = findall(UnPlant .== "Coal")
  units = intersect(unit1,unit2)
  UnOR[units,TimePs,Months,Yr(2022)] = UnOR[units,TimePs,Months,Yr(2021)]

  # 
  # Calibrate AB/SK/NS generation in 2022 with UnMustRun, updated RST 02Sept2023
  # 
  unit1 = findall(UnArea .== "SK")
  unit2 = findall(UnArea .== "AB")
  unit3 = findall(UnArea .== "NS")
  unit4 = findall(UnPlant .== "Coal")
  units = intersect(union(unit1,unit2,unit3),unit4)
  @. UnMustRun[units] = 1

  # 
  # Calibrate generation in 2022 with AvFactor, updated RST 31Aug2023
  # 
  Coal = Select(Plant,"Coal")
  AB = Select(Area,"AB")
  @. AvFactor[Coal,TimePs,Months,AB,Yr(2022)] = 1.21

  # Select Plant(Coal), Area(SK), Year(2022)
  # AvFactor=6.48
  # Select Plant*, Area*, Year*

  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGInput/UnMustRun",UnMustRun)
  WriteDisk(db,"EGInput/AvFactor",AvFactor)
end

function CalibrationControl(db)
  @info "AdjustElectricity_2022_AB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
