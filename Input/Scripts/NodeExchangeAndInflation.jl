#
# NodeExchangeAndInflation.jl - Assigns values to exchange rate and inflation variables
#
########################
#  - Assign values to new variables by Node (xExchangeRate, xExchangeRateNation, xInflationNation)
########################
#
using EnergyModel

module NodeExchangeAndInflation

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

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ExchangeRateNode::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNode") # [Node,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationNode::VariableArray{2} = ReadDisk(db,"MOutput/InflationNode") # [Node,Year] Inflation Index ($/$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [PointerCN,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNode::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNode") # [Node,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [PointerCN,Year] Inflation Index ($/$)
  xInflationNode::VariableArray{2} = ReadDisk(db,"MInput/xInflationNode") # [Node,Year] Inflation Index ($/$)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Nation,Node,Nodes,Years) = data
  (;ExchangeRateNode,InflationNode,xExchangeRateNode,xExchangeRateNation,xInflationNation,xInflationNode) = data

  US=Select(Nation,"US")
  CN=Select(Nation,"CN")

  #*
  #* Initialize Node
  #*
  #* US Nodes
  #*
  
  for node in Nodes, y in Years
    xExchangeRateNode[node,y]=xExchangeRateNation[US,y] 
    xInflationNode[node,y]=xInflationNation[US,y]
  end

  #* 
  #* Canada Nodes
  #*
  
  CNNodes=Select(Node,["ON","QC","BC","AB","MB","SK","NB","NS","NL","LB","PE","YT","NT","NU"])
  for node in CNNodes, y in Years
    xExchangeRateNode[node,y]=xExchangeRateNation[CN,y] 
    xInflationNode[node,y]=xInflationNation[CN,y]
  end

  @. ExchangeRateNode = xExchangeRateNode
  @. InflationNode = xInflationNode

  WriteDisk(db, "MOutput/ExchangeRateNode", ExchangeRateNode)
  WriteDisk(db, "MOutput/InflationNode", InflationNode)
  WriteDisk(db, "MInput/xExchangeRateNode", xExchangeRateNode)
  WriteDisk(db, "MInput/xInflationNode", xInflationNode)

end

function CalibrationControl(db)
  @info "NodeExchangeAndInflation.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
