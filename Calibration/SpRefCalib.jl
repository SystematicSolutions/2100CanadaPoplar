#
# SpRefCalib.jl
#
using EnergyModel

module SpRefCalib

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Crude::SetArray = ReadDisk(db,"MainDB/CrudeKey")
  CrudeDS::SetArray = ReadDisk(db,"MainDB/CrudeDS")
  Crudes::Vector{Int} = collect(Select(Crude))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  RfMaxCrude::VariableArray{3} = ReadDisk(db,"SpInput/RfMaxCrude") # [RfUnit,Crude,Year] Refinery Maximum Input Fraction of Crude Types (Btu/Btu)
  RfCalSw::VariableArray{2} = ReadDisk(db,"SpInput/RfCalSw") # [Nation,Year] Switch for Years to Calibration Production (1-Calibrate)

  # Scratch Variables
end

function SupplyCalibration(db)
  data = SControl(; db)
  (;Nation) = data
  (;RfCalSw) = data
  @. RfCalSw = 0
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  MX = Select(Nation,"MX")
  
  years = collect(Yr(1990):Yr(2012))
  
  @. RfCalSw[US,years] = 1
  @. RfCalSw[CN,years] = 1
  @. RfCalSw[MX,years] = 1
  WriteDisk(db,"SpInput/RfCalSw",RfCalSw)  

end

function CalibrationControl(db)
  @info "SpRefCalib.jl - CalibrationControl"

  SupplyCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
