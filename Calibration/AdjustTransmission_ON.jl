#
# AdjustTransmission_ON.jl
#
using EnergyModel

module AdjustTransmission_ON

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Nodes::Vector{Int} = collect(Select(Node))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  xLLVC::VariableArray{3} = ReadDisk(db,"EGInput/xLLVC") # [Node,NodeX,Year] Transmission rate (Real US$/MWh)
end

function ECalibration(db)
  data = EControl(; db)
  (;Nation,Node,NodeX) = data
  (;xInflationNation,xLLVC) = data

  #
  # Add transmission tariff to New York (NYPP) from Ontario (ON).
  # This will reduce exports from Ontario.  Jeff Amlin 03/21/19
  #
  US=Select(Nation,"US")
  node=Select(Node,"NYUP")
  nodex=Select(NodeX,"ON")
  # area=Select(Area,"ON")
  years=collect(Yr(2019):Final)

  for year in years
    xLLVC[node,nodex,year]=10/xInflationNation[US,Yr(2019)]
  end
  WriteDisk(db,"EGInput/xLLVC",xLLVC)
end

function CalibrationControl(db)
  @info "AdjustTransmission_ON.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
