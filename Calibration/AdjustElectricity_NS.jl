#
# AdjustElectricity_NS.jl - Revise Outage Rate for NS units.
#
using EnergyModel

module AdjustElectricity_NS

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

  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
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

  HDVCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDVCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Variable Costs Bid ($/$)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type

  # Scratch Variables
end

function ECalibration(db)
  data = ECalib(; db)
  (;GenCo,Months,Node,Plant) = data
  (;TimePs,Years) = data
  (;HDVCFR,UnArea,UnCogen,UnMustRun,UnOR,UnPlant) = data
  
  # *
  # * NS OGCT Units
  # *
  unit1 = findall(UnArea .== "NS")
  unit2 = findall(UnPlant .== "OGCT")
  unit3 = findall(UnMustRun .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1,unit2, unit3, unit4)
  @. UnOR[units,Months,TimePs,Years] = 0.05
  
  
  # *
  # * NS OGCC Units
  # *
  unit1 = findall(UnArea .== "NS")
  unit2 = findall(UnPlant .== "OGCC")
  unit3 = findall(UnMustRun .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1,unit2, unit3, unit4)
  @. UnOR[units,Months,TimePs,Years] = 0.05
  
  # *
  # * NS Coal Units
  # *
  unit1 = findall(UnArea .== "NS")
  unit2 = findall(UnPlant .== "Coal")
  unit3 = findall(UnMustRun .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1,unit2, unit3, unit4)
  @. UnOR[units,Months,TimePs,Years] = 0.15
  
  
  WriteDisk(db,"EGInput/UnOR",UnOR)
  
  # *
  # * Calibrate generation in 2021 with HDVCFR - Jeff Amlin 9/17/22
  # *
  Coal = Select(Plant,"Coal")
  GenCo_NS = Select(GenCo,"NS")
  Node_NS = Select(Node, "NS")
  @. HDVCFR[Coal,GenCo_NS,Node_NS,TimePs,Months,Yr(2021)] = 0.330
  WriteDisk(db, "EGInput/HDVCFR",HDVCFR)

end

function CalibrationControl(db)
  @info "AdjustElectricity_NS.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
