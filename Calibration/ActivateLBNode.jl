#
using EnergyModel

module ActivateLBNode

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
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Nodes::Vector{Int} = collect(Select(Node))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  NodeSw::VariableArray{1} = ReadDisk(db,"EGInput/NodeSw") # [Node] Switch to indicate if Node is Active (1=Active)
  NodeXSw::VariableArray{1} = ReadDisk(db,"EGInput/NodeXSw") # [NodeX] Switch to indicate if NodeX is Active (1=Active)
  NdArFr::VariableArray{3} = ReadDisk(db,"EGInput/NdArFr") # [Node,Area,Year] Area Node Fraction

  # Scratch Variables
end

function ECalibration(db)
  data = ECalib(; db)
  (;Areas,Node) = data
  (;NodeSw,NodeXSw,NdArFr) = data
  
  # *
  # * Activate the Labrador and Nunavut Node
  # *
  NodeSw[3] = 1.0
  NodeXSw[3] = 1.0
  NodeSw[14] = 1.0
  NodeXSw[14] = 1.0
  
  WriteDisk(db,"EGInput/NodeSw",NodeSw)
  WriteDisk(db,"EGInput/NodeXSw",NodeXSw)
  
  
  # *
  # * For Newfoundland (NL) the Area Node Fraction for Labrador (LB)
  # * is the same as the Newfoundland Island (NL).
  # *
  NL = Select(Node, "NL")
  LB = Select(Node, "LB")
  
  years = collect(Future:Final)
  
  @. NdArFr[LB,Areas,years] = NdArFr[NL,Areas,years]
  
  WriteDisk(db,"EGInput/NdArFr",NdArFr)

end

function CalibrationControl(db)
  @info "ActivateLBNode.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
