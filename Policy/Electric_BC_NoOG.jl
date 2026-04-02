#
# Electric_BC_NoOG.jl
#
# Remove BC's ability to build OG plant types
# From call with BC October 4th, 2016, where they stated that
# No utility emitting generation will be built, and an expected
# 100% non-emitting grid starting next year.
#

using EnergyModel

module Electric_BC_NoOG

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  NdArFr::VariableArray{3} = ReadDisk(db,"EGInput/NdArFr") # [Node,Area,Year] Fraction of the Node in each Area (MW/MW)
  xGCPot::VariableArray{4} = ReadDisk(db,"EGInput/xGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area) = data
  (; Node) = data
  (; Plant,Years) = data
  (; xGCPot) = data

  BC = Select(Area,"BC")
  BC_Node = Select(Node,"BC")
  plants = Select(Plant,["OGCT","OGCC","OGSteam"])
  for year in Years, plant in plants
    xGCPot[plant,BC_Node,BC,year] = 0
  end
  
  WriteDisk(db,"EGInput/xGCPot",xGCPot)
end

function PolicyControl(db)
  @info "Electric_BC_NoOG.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
