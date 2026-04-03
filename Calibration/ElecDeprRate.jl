#
# ElecDeprRate.jl - Straight Line Depreciation
#
using EnergyModel

module ElecDeprRate

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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DPRSL::VariableArray{2} = ReadDisk(db,"EGInput/DPRSL") # [Area,Year] Straight Line Depreciation Rate (1/Yr)

  # Scratch Variables
end

function ECalibration(db)
  data = ECalib(; db)
  (;Areas,Years) = data
  (;DPRSL) = data
  
  @. DPRSL[Areas,Years] = 1.0/30.0
  WriteDisk(db,"EGInput/DPRSL",DPRSL)

end

function CalibrationControl(db)
  @info "ElecDeprRate.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
