#
# Energy_Flows_VB.jl - Assign vFlow and vFlowNation to xFlow and xFlowNation
#
using EnergyModel

module Energy_Flows_VB

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaX::SetArray = ReadDisk(db,"MainDB/AreaXKey")
  AreaXDS::SetArray = ReadDisk(db,"MainDB/AreaXDS")
  AreaXs::Vector{Int} = collect(Select(AreaX))
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  NationX::SetArray = ReadDisk(db,"MainDB/NationXKey")
  NationXDS::SetArray = ReadDisk(db,"MainDB/NationXDS")
  NationXs::Vector{Int} = collect(Select(NationX))
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  vFlow::VariableArray{4} = ReadDisk(db,"VBInput/vFlow") # [Fuel,Area,AreaX,Year] Historical Energy Flow to Area from AreaX (TBtu/Yr)
  xFlow::VariableArray{4} = ReadDisk(db,"SpInput/xFlow") # [Fuel,Area,AreaX,Year] Historical Energy Flow to Area from AreaX (TBtu/Yr)
  vFlowNation::VariableArray{4} = ReadDisk(db,"VBInput/vFlowNation") # [Fuel,Nation,NationX,Year] Historical Energy Flow to Nation from NationX (TBtu/Yr)
  xFlowNation::VariableArray{4} = ReadDisk(db,"SpInput/xFlowNation") # [Fuel,Nation,NationX,Year] Historical Energy Flow to Nation from NationX (TBtu/Yr)
end

function SCalibration(db)
  data = SControl(; db)
  (;vFlow,vFlowNation,xFlow,xFlowNation) = data

  @. xFlow = vFlow
  @. xFlowNation = vFlowNation

  WriteDisk(db,"SpInput/xFlow",xFlow)
  WriteDisk(db,"SpInput/xFlowNation",xFlowNation)
  
end

function CalibrationControl(db)
  @info "Energy_Flows_VB.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
