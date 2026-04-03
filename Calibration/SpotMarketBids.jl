#
# SpotMarketBids.jl
#
using EnergyModel

module SpotMarketBids

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
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  HDFCFR::VariableArray{4} = ReadDisk(db,"EGInput/HDFCFR") # [Plant,GenCo,TimeP,Year] Fraction of Fixed Costs in Block
  HDVCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDVCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Variable Costs Bid
  NdNMap::VariableArray{2} = ReadDisk(db,"EGInput/NdNMap") # [Node,Nation] Map between Node and Nation

end

function ECalibration(db)
  data = EControl(; db)
  (;GenCo,GenCos,Months,Nation,Node) = data
  (;Nodes,Plant,Plants,TimePs,Years) = data
  (;HDFCFR,HDVCFR,NdNMap) = data

  #
  # The default bid is variable costs (HDVCFr=1) except nuclear
  #
  @. HDVCFR=1.0
  Nuclear=Select(Plant,"Nuclear")
  for year in Years, month in Months, timep in TimePs, node in Nodes, genco in GenCos
    HDVCFR[Nuclear,genco,node,timep,month,year]=0.25
  end

  #
  # Lower Ontario Coal bids
  #
  Coal=Select(Plant,"Coal")
  ON=Select(GenCo,"ON")
  for year in Years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[Coal,ON,node,timep,month,year]=0.50
  end

  #
  # Bid Quebec nuclear low
  #
  QC=Select(GenCo,"QC")
  for year in Years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[Nuclear,QC,node,timep,month,year]=0.00
  end

  #
  # Adjust Alberta oil gas CT and CC bids to create
  # reasonable forecast of system prices
  #
  AB=Select(GenCo,"AB")
  OGCT=Select(Plant,"OGCT")
  for year in Years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[OGCT,AB,node,timep,month,year]=1.25
  end
  OGCC=Select(Plant,"OGCC")
  for year in Years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[OGCC,AB,node,timep,month,year]=1.25
  end
  OGSteam=Select(Plant,"OGSteam")
  years=collect(Yr(2020):Final)
  for year in years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[OGSteam,AB,node,timep,month,year]=1.25
  end
  #
  # Coal
  #
  for year in Years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[Coal,AB,node,timep,month,year]=0.75
  end
  years=collect(Yr(2029):Final)
  for year in years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[Coal,AB,node,timep,month,year]=1.00
  end

  #
  # Calibrate to AESO Pool Prices - Jeff Amlin 11/16/15
  #
  plants=Select(Plant,["OGCC","OGCT"])
  timeps=collect(1:5)
  for month in Months, timep in timeps, node in Nodes, plant in plants
    HDVCFR[plant,AB,node,timep,month,Yr(2010)]=2.1005*0.59
    HDVCFR[plant,AB,node,timep,month,Yr(2011)]=4.7146*0.89
    HDVCFR[plant,AB,node,timep,month,Yr(2012)]=3.2719*0.78
    HDVCFR[plant,AB,node,timep,month,Yr(2013)]=4.1612*0.87
    HDVCFR[plant,AB,node,timep,month,Yr(2014)]=1.1699*1.28
    HDVCFR[plant,AB,node,timep,month,Yr(2015)]=1.1686*0.84
    HDVCFR[plant,AB,node,timep,month,Yr(2016)]=1.0000
  end
  years=collect(Yr(2017):Final)
  for year in years, month in Months, timep in timeps, node in Nodes, plant in plants
    HDVCFR[plant,AB,node,timep,month,year]=1.0
  end

  #
  # Adjust New Brunswick bids
  #
  NB=Select(GenCo,"NB")
  SmallOGCC=Select(Plant,"SmallOGCC")
  for year in Years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[Coal,NB,node,timep,month,year]=0.25
    HDVCFR[OGSteam,NB,node,timep,month,year]=0.80
    HDVCFR[OGCC,NB,node,timep,month,year]=0.50
    # HDVCFR[SmallOGCC,NB,node,timep,month,year]=0.50
  end

  #
  # Bids for Nova Scotia
  # Restoring full bid always
  #
  NS=Select(GenCo,"NS")
  for year in Years, month in Months, timep in TimePs, node in Nodes, plant in Plants
    HDVCFR[plant,NS,node,timep,month,year]=1.00
  end
  for year in Years, month in Months, timep in TimePs, node in Nodes
    HDVCFR[OGSteam,NS,node,timep,month,year]=0.50
    HDVCFR[Coal,NS,node,timep,month,year]=0.50
    HDVCFR[OGCC,NS,node,timep,month,year]=0.50
    # HDVCFR[SmallOGCC,NS,node,timep,month,year]=0.50
  end

  #
  # Bid Newfoundland Generation
  #
  NL=Select(GenCo,"NL")
  for year in Years, month in Months, timep in TimePs, node in Nodes, plant in Plants
    HDVCFR[plant,NL,node,timep,month,year]=0.25
  end

  #
  # Bid Newfoundland (Labrador) Generation
  #
  LB=Select(Node,"LB")
  NL=Select(GenCo,"NL")
  for year in Years, month in Months, timep in TimePs, node in Nodes, plant in Plants
    HDVCFR[plant,NL,LB,timep,month,year]=1.20
  end

  #
  # Hydro is bid low to insure export to Quebec
  #
  plants=Select(Plant,["BaseHydro","PeakHydro"])
  for year in Years, month in Months, timep in TimePs, node in Nodes, plant in plants
    HDVCFR[plant,NL,node,timep,month,year]=0.50
  end

  WriteDisk(db,"EGInput/HDVCFR",HDVCFR)

  #
  # US Coal Units bid below variable costs to insure they run
  # Jeff Amlin 7/6/15
  #
  US=Select(Nation,"US")
  nodes_US=findall(NdNMap[:,US] .== 1)
  plants=Select(Plant,["Coal","CoalCCS"])
  for year in Years, month in Months, timep in TimePs, node in nodes_US, genco in GenCos,plant in plants
    HDVCFR[plant,genco,node,timep,month,year]=min(HDVCFR[plant,genco,node,timep,month,year],0.500)
  end

  #
  # US Biomass Units bid below variable costs to insure they run
  # Jeff Amlin 12/1/22
  #
  Biomass=Select(Plant,"Biomass")
  for year in Years, month in Months, timep in TimePs, node in nodes_US, genco in GenCos
    HDVCFR[Biomass,genco,node,timep,month,year] =
      min(HDVCFR[Biomass,genco,node,timep,month,year],0.05)
  end

  # #
  # # US OGCC Units bid below variable costs to increase generation
  # # Check prices relative to Canada?
  # # Jeff Amlin 12/1/22
  # #
  # OGCC=Select(Plant,"OGCC")
  # for year in Years, month in Months, timep in TimePs, node in nodes_US, genco in GenCos
  #   HDVCFR[OGCC,genco,node,timep,month,year] =
  #     min(HDVCFR[OGCC,genco,node,timep,month,year],0.90)
  # end

  #
  # Plants do not explicitly bid in their fixed costs
  #
  @. HDFCFR = 0.00

  WriteDisk(db,"EGInput/HDVCFR",HDVCFR)
  WriteDisk(db,"EGInput/HDFCFR",HDFCFR)

end

function CalibrationControl(db)
  @info "SpotMarketBids.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
