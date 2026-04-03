#
# AdjustEmgPower.jl - Jeff Amlin 10/12/09
#
using EnergyModel

module AdjustEmgPower

import ...EnergyModel: ReadDisk,WriteDisk,Select, Zero
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

  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))

  xEMGVCost::VariableArray{2} = ReadDisk(db,"EGInput/xEMGVCost") # [Node,Year] Dispatch Price for Emergency Power ($/MWh)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") #[Nation,Year]  Inflation Index ($/$)

  # Scratch Variables
end

function ECalibration(db)
  data = ECalib(; db)
  (;Node,Nodes,Nation) = data
  (;xEMGVCost,xInflationNation) = data
  
  #
  # Default value is US$250/MWH - Jeff Amlin 9/02/2013
  #
  US = Select(Nation,"US")
  xInflationUS2010 = xInflationNation[US,Yr(2010)]
  
  @. xEMGVCost[Nodes,Yr(2011)] = 250/xInflationUS2010
  
  #
  # In Labrador value is US$300/MWH so that emergency power is not
  # exported from Labrador to Quebec - Jeff Amlin 9/02/2013
  #
  # Select Node(LB)
  
  LB = Select(Node, "LB")
  xEMGVCost[LB,Yr(2011)] = 300/xInflationUS2010
  
  #
  # In the Territories, there is unreported generation which
  # will show up as emergency power, but it does not need to
  # be as high price - Jeff Amlin 9/05/13
  #
  nodes = Select(Node, ["YT","NT","NU"])
  @. xEMGVCost[nodes,Yr(2011)] = 200/xInflationUS2010
  
  #
  # Below was originally Future-Final, but that only
  # made sense when LHY = 2011. I've changed it to be static
  # 2012-Final, since that US$250/MWH value is probably still
  # mostly valid for the year it was input.
  #
  years = collect(Yr(2012):Final)
  for year in years
    @. xEMGVCost[Nodes,year] = xEMGVCost[Nodes,year-1] * (1 + 0.01)
  end
  
  years = reverse(collect(Zero:Yr(2010)))
  for year in years
    @. xEMGVCost[Nodes,year] = xEMGVCost[Nodes,year+1] * (1 - 0.01)
  end 
  WriteDisk(db,"EGInput/xEMGVCost",xEMGVCost)

end

function CalibrationControl(db)
  @info "AdjustEmgPower.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
