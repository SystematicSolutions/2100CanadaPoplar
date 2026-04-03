#
# ImportEmissions_VB.jl
#
using EnergyModel

module ImportEmissions_VB

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  vRnImports::VariableArray{2} = ReadDisk(db,"VBInput/vRnImports") # [Area,Year] Exogenous Renewable Generation Imports (GWh/Yr)
  vPolImports::VariableArray{3} = ReadDisk(db,"VBInput/vPolImports") # [Poll,Area,Year] Reference Case Imported Electricity Emissions (Tonnes/Yr)
  xRnImports::VariableArray{2} = ReadDisk(db,"EGInput/xRnImports") # [Area,Year] Exogenous Renewable Generation Imports (GWh/Yr)
  xPolImports::VariableArray{3} = ReadDisk(db,"SInput/xPolImports") # [Poll,Area,Year] Reference Case Imported Electricity Emissions (Tonnes/Yr)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,AreaDS,Areas,Poll,PollDS,Polls,Year,YearDS,Years) = data
  (;vRnImports,vPolImports,xRnImports,xPolImports) = data

  @. xRnImports = vRnImports
  @. xPolImports = vPolImports

  WriteDisk(db,"EGInput/xRnImports",xRnImports)
  WriteDisk(db,"SInput/xPolImports",xPolImports)

end

function CalibrationControl(db)
  @info "ImportEmissions_VB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
