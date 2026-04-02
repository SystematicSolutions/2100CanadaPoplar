#
# Electric_NS_HydroPurchases.jl - Electric Generation GHG Performance
# Standards for NS coal which reduces coal generation instead
# of retiring - Jeff Amlin 8/7/2013
# Modified to push start date of Muskrat Falls back to 2020 - Hilary 17.02.24
#
# Modified in the context of the electrification project, to adjust
# values for to the Labrador-Island Transmission Link and the Maritime
# Link (should be kept for annual updates). JSLandry; Mar 22, 2020.
#
# Postponed Muskrat Falls, Labrador-Island Transmission Link, and Maritime Link
# from July 2020 to July 2021. JSLandry; Jul 7, 2020
#

using EnergyModel

module Electric_NS_HydroPurchases

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
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
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

  LLMax::VariableArray{5} = ReadDisk(db,"EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
  xCapacity::VariableArray{6} = ReadDisk(db,"EInput/xCapacity") # [Area,GenCo,Plant,TimeP,Month,Year] Capacity for Exogenous Contracts (MW)
  xEnergy::VariableArray{4} = ReadDisk(db,"EInput/xEnergy") # [Area,GenCo,Plant,Year] Energy Limit on Exogenous Contracts (Gwh/Yr)
  xRnImports::VariableArray{2} = ReadDisk(db,"EGInput/xRnImports") # [Area,Year] Renewable Generation Imports (GWh/Yr)
  # HDXLoad::VariableArray{5} = ReadDisk(db,"EGInput/*HDXLoad") # [Node,NodeX,TimeP,Month,Year] Exogenous Loading on Transmission Lines (MW)
 
  # Scratch Variables
  AddEnergy::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Energy Added to Provincial Contract (GWh)
  GCTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Cumulative Replacement Capacity (MW)
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,GenCo) = data
  (; Months) = data
  (; Node,NodeX) = data
  (; Plant,TimePs) = data
  (; AddEnergy,GCTotal,LLMax,xRnImports,xCapacity,xEnergy) = data

  #
  # In response to GHG EPS, Nova Scotia contracts to purchase more
  # output from Muskrat Falls.
  # New Capacity under Contract from Muskrat Falls is 100 MW
  #
  NS = Select(Area,"NS")
  NL_GenCo = Select(GenCo,"NL")
  BaseHydro = Select(Plant,"BaseHydro")
  years = collect(Yr(2025):Final)
  for year in years
    GCTotal[year] = 100
  end

  #
  # Increase Contract Energy
  # 
  @finite_math [AddEnergy[NS,year] = xEnergy[NS,NL_GenCo,BaseHydro,year] / xCapacity[NS,NL_GenCo,BaseHydro,timep,month,year] * GCTotal[year]
    for year in Yr(2025):Final,timep in TimePs,month in Months]
  xRnImports[NS,Yr(2025):Final] = xRnImports[NS,Yr(2025):Final] + 
    AddEnergy[NS,Yr(2025):Final]
  years = collect(Yr(2025):Final)
  for year in years
    xEnergy[NS,NL_GenCo,BaseHydro,year] = xEnergy[NS,NL_GenCo,BaseHydro,year] + 
      AddEnergy[NS,year]
  end

  #
  # Increase Contract Capacity (MW)
  #  
  years = collect(Yr(2025):Final)
  for year in years, month in Months, timep in TimePs
    xCapacity[NS,NL_GenCo,BaseHydro,timep,month,year] = 
      xCapacity[NS,NL_GenCo,BaseHydro,timep,month,year] + GCTotal[year]
  end
  
  WriteDisk(db,"EGInput/xRnImports",xRnImports)
  WriteDisk(db,"EInput/xCapacity",xCapacity)
  WriteDisk(db,"EInput/xEnergy",xEnergy)

  #
  # Reduce Contract (Forced) Flows to New Brunswick (NB) from Nova Scotia (NS)
  #
  # JSO Edit for NBEA,keep forced flow from NS to NB and NB to ISNE
  #
  # Select Node(NB),NodeX(NS)
  # Select Year(2025-Final)
  # HDXLoad=xmax(HDXLoad-GCTotal,0)
  # Select Year(2030-2035)
  # HDXLoad=0
  # Select Year*
  #
  # Reduce Contract (Forced) Flows to New England (ISNE) from New Brunswick (NB)
  #
  # Select Node(ISNE),NodeX(NB)
  # Select Year(2025-Final)
  # HDXLoad=xmax(HDXLoad-GCTotal,0)
  # Select Node*,NodeX*,Year*
  #
  # Write Disk(HDXLoad)
  #
  
  #
  # TD (June 2025): I remove all changes on LLMax since they are now made in vLLMax
  #

  # Transmission Capacity (LLMax) - during peak periods more power can pass through the lines
  #
  # Slightly modified to reflect that the total capacity of the Labrador-Island
  # Transmission Link is 900 MW (not 824 MW as previously used); half of the value
  # for 2020 since we assume that the link will be operational in July 2020
  # (https://www.thetelegram.com/news/local/another-delay-for-labrador-island-link-software-nalcor-390790/).
  # JSLandry; Mar 22, 2020.
  #
  # Postponed Labrador-Island Transmission Link to July 2021. JSLandry; Jul 7, 2020.
  #  
  # NL = Select(Node,"NL")
  # LB = Select(NodeX,"LB")
  # for month in Months, timep in TimePs
  #   LLMax[NL,LB,timep,month,Yr(2021)] = 450
  # end
  
  # TD 2025-05-06: updated starting year to 2023
  # Source: https://nlhydro.com/wp-content/uploads/2024/08/Hydro-Labrador-Island-Link.pdf

  # years = collect(Yr(2023):Final)
  # for year in years, month in Months, timep in TimePs
  #   LLMax[NL,LB,timep,month,year] = 900
  # end

  #
  # Transmission Capacity to Nova Scotia (NS) from NF Island (NL)
  # Allow flexibility to bring more power during peak periods
  #
  # Slightly modified to reflect that the total capacity of the Maritime Link
  # is 500 MW (not 488 MW as previously used); half of the value for 2020 since
  # the link is currently expected in June 2020, assuming July 2020 for delays
  # (https://www.cbc.ca/news/canada/nova-scotia/maritime-link-to-cost-nova-scotia-power-customers-144m-1.5375621).
  # Also removed the variation of LLMax by TimeP,because it did not seem consistent
  # with info found online (https://www.muskratfallsinquiry.ca/files/P-00453.pdf) and
  # did not fit with the comment above (the way it was coded, there was actually less
  # power during peak periods). JSLandry; Mar 22, 2020.
  #
  # Postponed Maritime Link to July 2021. JSLandry; Jul 7, 2020.
  #
  # Update Ref23 (TD,Aug 23): added 400 MW NS --> NL (based on consultation info)
  #  
  # NS = Select(Node,"NS")
  # NL = Select(NodeX,"NL")
  # 
  # years = collect(Yr(2021):Final)
  # for year in years, month in Months, timep in TimePs
  #   LLMax[NS,NL,timep,month,year] = 475
  # end
  
  
  #
  # NL = Select(Node,"NL")
  # NS = Select(NodeX,"NS")
  # years = collect(Yr(2023):Final)
  # for year in years, month in Months, timep in TimePs
  #   LLMax[NL,NS,timep,month,year] = 475
  # end

  #
  # Allow more power to flow from New Brunswick (NB) to New England (NEWE)
  # Removed this to reflect line constraints at present - H. Paulin 18.06.27
  #
  # Select Node(ISNE),NodeX(NB),Year(2025-Final)
  # LLMax=LLMax+1000
  # Select Node*,NodeX*,Year*
  #

  # WriteDisk(db,"EGInput/LLMax",LLMax)
end

function PolicyControl(db)
  @info "Electric_NS_HydroPurchases.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
