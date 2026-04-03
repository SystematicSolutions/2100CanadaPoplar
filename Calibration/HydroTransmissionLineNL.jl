#
# HydroTransmissionLineNL.jl
#
using EnergyModel

module HydroTransmissionLineNL

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
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xRnImports::VariableArray{2} = ReadDisk(db,"EGInput/xRnImports") # [Area,Year] Exogenous Renewable Generation Imports (GWh/Yr)
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xCapacity::VariableArray{6} = ReadDisk(db,"EInput/xCapacity") # [Area,GenCo,Plant,TimeP,Month,Year] Capacity for Exogenous Contracts (MW)
  xCapSw::VariableArray{4} = ReadDisk(db,"EInput/xCapSw") # [Area,GenCo,Plant,Year] Switch for Exogenous Contract (1=Contract)
  xEnergy::VariableArray{4} = ReadDisk(db,"EInput/xEnergy") # [Area,GenCo,Plant,Year] Energy Limit on Exogenous Contracts (Gwh/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xUCCost::VariableArray{4} = ReadDisk(db,"EInput/xUCCost") # [Area,GenCo,Plant,Year] Capacity Cost for Exogenous Contracts ($/KW)
  xUECost::VariableArray{4} = ReadDisk(db,"EInput/xUECost") # [Area,GenCo,Plant,Year] Energy Cost for Exogenous Contracts ($/MWh)

  #
  # Scratch Variables
  #
  CntCap::VariableArray{1} = zeros(length(Year)) # [Year] Contract Capacity (MW)

  
end

function TransmissionData(db)
  data = EControl(; db)
  (;Area,GenCo,Months) = data
  (;Plant) = data
  (;TimePs) = data
  (;CntCap,xRnImports,xCapacity,xCapSw,xEnergy,xInflation,xUCCost,xUECost) = data

  #
  ########################
  #
  # Renewable Imports
  #
  # For Nova Scotia power from NL is assumed to be renewable imports
  #
  # Modified 2020 (from 900 to 600) to reflect Maritime Link expected for 
  # July 2020. JSLandry; Mar 22, 2020. 
  #
  # Postponed Maritime Link to July 2021, so MW values are all postponed by 
  # one year. JSLandry; Jul 6, 2020.
  #
  area=Select(Area,"NS")
  xRnImports[area,Yr(2021)]=600.0
  xRnImports[area,Yr(2022)]=1200.0
  xRnImports[area,Yr(2023)]=1200.0
  years=collect(Yr(2024):Final)
  for year in years
    xRnImports[area,year]=xRnImports[area,Yr(2023)]
  end
  WriteDisk(db,"EGInput/xRnImports",xRnImports)

  #
  ########################
  #
  # NS Power Costs
  #
  # Establish an exogenous contract with exogenous prices
  #
  area=Select(Area,"NS")
  genco=Select(GenCo,"NL")
  plant=Select(Plant,"BaseHydro")

  #
  # Contract Capacity (MW)
  #
  # Postponed Maritime Link to July 2021, so MW values are all postponed by 
  # one year (value for 2021 modified so it is now equal to half of the values 
  # for 2022 and 2023). JSLandry; Jul 6, 2020.
  #
  CntCap[Yr(2021)]=101.0
  CntCap[Yr(2022)]=202.0
  CntCap[Yr(2023)]=202.0  
  years=collect(Yr(2024):Final)
  for year in years
    CntCap[year] = CntCap[Yr(2023)]
  end  
  years=collect(Yr(2021):Final)  
  for year in years, month in Months, timep in TimePs
    xCapacity[area,genco,plant,timep,month,year] = CntCap[year]
  end
  
  #
  # Contract Energy
  #
  for year in years
    xEnergy[area,genco,plant,year]=xRnImports[area,year]
  end

  #
  # Contract Costs are exogenous (xCapSw=1)
  #
  for year in years
    xCapSw[area,genco,plant,year] = 1
    xUCCost[area,genco,plant,year] = 553.03/xInflation[area,year]
    xUECost[area,genco,plant,year] = 0.0
  end

  WriteDisk(db,"EInput/xCapacity",xCapacity)
  WriteDisk(db,"EInput/xCapSw",xCapSw)
  WriteDisk(db,"EInput/xEnergy",xEnergy)
  WriteDisk(db,"EInput/xUCCost",xUCCost)
  WriteDisk(db,"EInput/xUECost",xUECost)
  
end

function Control(db)
  @info "HydroTransmissionLineNL.jl - Control"
  TransmissionData(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
