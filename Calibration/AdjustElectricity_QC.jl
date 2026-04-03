#
# AdjustElectricity_QC.jl - Revise Outage Rate for NS units.
#
using EnergyModel

module AdjustElectricity_QC

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type

  # Scratch Variables
end

function ECalibration(db)
  data = ECalib(; db)
  (;Months,TimePs,Years) = data
  (;UnArea,UnCogen,UnMustRun,UnOR,UnPlant) = data
  
  # *
  # * QC Outage Rates for OGCT Units
  # *
  
  unit1 = findall(UnArea .== "QC")
  unit2 = findall(UnPlant .== "OGCT")
  unit3 = findall(UnMustRun .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1,unit2, unit3, unit4)
  @. UnOR[units,Months,TimePs,Years] = 0.05
  
  # *
  # * QC Outage Rates for OGCC Units
  # *
  
  unit1 = findall(UnArea .== "QC")
  unit2 = findall(UnPlant .== "OGCC")
  unit3 = findall(UnMustRun .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1,unit2, unit3, unit4)
  @. UnOR[units,Months,TimePs,Years] = 0.05
  
  
  WriteDisk(db,"EGInput/UnOR",UnOR)

end

function CalibrationControl(db)
  @info "AdjustElectricity_QC.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
