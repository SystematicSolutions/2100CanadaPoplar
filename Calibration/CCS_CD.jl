#
# CCS_CD.jl - GHG Carbon Sequestration - Jeff Amlin 10/3/21
#
using EnergyModel

module CCS_CD

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  SqCD::VariableArray{3} = ReadDisk(db,"MEInput/SqCD") # [ECC,Area,Year] Sequestering Construction Delay (Years)
  SqCDOrder::VariableArray{2} = ReadDisk(db,"MEInput/SqCDOrder") # [ECC,Year] Number of Levels in the Sequestering Construction Delay (Number)

  # Scratch Variables
end

function MCalibration(db)
  data = MControl(; db)
  (;SqCD,SqCDOrder) = data

  @. SqCD = 4

  WriteDisk(db,"MEInput/SqCD",SqCD)

  @. SqCDOrder = 4

  WriteDisk(db,"MEInput/SqCDOrder",SqCDOrder)

end

function CalibrationControl(db)
  @info "CCS_CD.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
