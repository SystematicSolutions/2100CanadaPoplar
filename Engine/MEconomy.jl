#
# MEconomy.jl
#

module MEconomy


import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime,DT

import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  current::Int
  prior::Int
  next::Int
  CTime::Int


  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  CNAreas::Vector{Int} = collect(Select(CNArea))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodes::Vector{Int} = collect(Select(GNode))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))


  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  BfProduction::VariableArray{1} = ReadDisk(db,"SOutput/BfProduction",year) #[Area,Year]  Biofuel Production (TBtu/Yr)
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") #[Area,CNArea]  Map between Area and Canada Economic Areas (CNArea)
  DmdES::VariableArray{3} = ReadDisk(db,"SOutput/DmdES",prior) #[ES,Fuel,Area,Prior]  Natural Gas Demands (TBtu/Yr)
  Driver::VariableArray{2} = ReadDisk(db,"MOutput/Driver",year) #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  DriverPrior::VariableArray{2} = ReadDisk(db,"MOutput/Driver",prior) #[ECC,Area,Prior]  Economic Driver in Previous Year (Various Millions/Yr)
  DriverMultiplier::VariableArray{2} = ReadDisk(db,"MInput/DriverMultiplier",year) #[ECC,Area,Year]  Economic Driver (Driver/Driver)
  DriverMultiplierPrior::VariableArray{2} = ReadDisk(db,"MInput/DriverMultiplier",prior) #[ECC,Area,Prior]  Economic Driver (Driver/Driver)
  DrSwitch::VariableArray{2} = ReadDisk(db,"MInput/DrSwitch",year) #[ECC,Area,Year]  Economic Driver Switch
  DWFR::VariableArray{2} = ReadDisk(db,"MInput/DWFR",year) #[ECC,Area,Year]  Fraction of Population by Dwelling Type (People/People)
  EAProd::VariableArray{2} = ReadDisk(db,"SOutput/EAProd",prior) #[Plant,Area,Prior]  Electric Utility Production (GWh/Yr)
  ECCProMap::VariableArray{2} = ReadDisk(db,"SInput/ECCProMap") #[ECC,Process]  ECC to Process Map
  ECGR::VariableArray{2} = ReadDisk(db,"MCalDB/ECGR",year) #[ECC,Area,Year]  Economic Sector Growth Rate (1/Yr)
  ECUF::VariableArray{2} = ReadDisk(db,"MOutput/ECUF",year) #[ECC,Area,Year]  Capital Utilization Fraction
  ECUFC::VariableArray{2} = ReadDisk(db,"MCalDB/ECUFC",year) #[ECC,Area,Year]  Capital Utilization Fraction
  Emp::VariableArray{2} = ReadDisk(db,"MOutput/Emp",year) #[ECC,Area,Year]  Employment (Thousands)
  ExchangeRate::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRate") #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateGNode::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateGNode") #[GNode,Year]  Local Currency/US$ Exchange Rate (Local$/US$)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") #[Nation,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateNode::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNode") #[Node,Year]  Local Currency/US$ Exchange Rate (Local$/US$)
  ExchangeRateOGUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateOGUnit") #[OGUnit,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateRfUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateRfUnit") #[RfUnit,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateUnit") #[Unit,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  Floorspace::VariableArray{2} = ReadDisk(db,"MOutput/Floorspace",year) #[ECC,Area,Year]  Floor Space (Million Sq Ft)
  GDPDeflator::VariableArray{2} = ReadDisk(db,"MOutput/GDPDeflator") #[Nation,Year]  GDP Deflator (Index)
  GO::VariableArray{2} = ReadDisk(db,"MOutput/GO",year) #[ECC,Area,Year]  Gross Output (Real M$/Yr)
  GOMAT::VariableArray{2} = ReadDisk(db,"MInput/GOMAT",year) #[ECC,Area,Year]  Adjustment Time for Gross Output Multiplier (Years)
  GOMult::VariableArray{2} = ReadDisk(db,"SOutput/GOMult",prior) #[ECC,Area,Year]  Gross Output Multiplier ($/$)
  GOMSmooth::VariableArray{2} = ReadDisk(db,"SOutput/GOMSmooth",year) #[ECC,Area,Year]  Smooth of Gross Output Multiplier ($/$)
  GOMSmoothPrior::VariableArray{2} = ReadDisk(db,"SOutput/GOMSmooth",prior) #[ECC,Area,Year]  Prior Year Value of Smooth of Gross Output Multiplier ($/$)
  GOPrior::VariableArray{2} = ReadDisk(db,"MOutput/GO",prior) #[ECC,Area,Prior]  Gross Output (Real M$/Yr)
  GNodeAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeAreaMap") #[GNode,Area]  Natural Gas Node to Area Map
  GRP::VariableArray{1} = ReadDisk(db,"MOutput/GRP",year) #[Area,Year]  Gross Regional Product (M$/Yr)
  GRPAdj::VariableArray{1} = ReadDisk(db,"MInput/GRPAdj",year) #[Area,Year]  Gross Regional Product Adjustment (Fraction)
  GRPGR::VariableArray{1} = ReadDisk(db,"MOutput/GRPGR",year) #[Area,Year]  Gross Regional Product Growth Rate (1/Yr)
  GRPPrior::VariableArray{1} = ReadDisk(db,"MOutput/GRP",prior) #[Area,Prior]  Gross Regional Product (M$/Yr)
  HHS::VariableArray{2} = ReadDisk(db,"MOutput/HHS",year) #[ECC,Area,Year]  Households (Households)
  HHSFr::VariableArray{2} = ReadDisk(db,"MInput/HHSFr",year) #[ECC,Area,Year]  Household Fraction (Household/Household)
  HSize::VariableArray{2} = ReadDisk(db,"MOutput/HSize",year) #[ECC,Area,Year]  Household Size (People/Household)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") #[Area,Year]  Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") #[Nation,Year]  Inflation Index ($/$)
  InflationNode::VariableArray{2} = ReadDisk(db,"MOutput/InflationNode") #[Node,Year]  Inflation Index ($/$)
  InflationGNode::VariableArray{2} = ReadDisk(db,"MOutput/InflationGNode") #[GNode,Year]  Inflation Index ($/$)
  InflationOGUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationOGUnit") #[OGUnit,Year]  Inflation Index ($/$)
  InflationRfUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationRfUnit") #[RfUnit,Year]  Inflation Index ($/$)
  InflationUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationUnit") #[Unit,Year]  Inflation Index ($/$)
  InflationRate::VariableArray{1} = ReadDisk(db,"MOutput/InflationRate",year) #[Area,Year]  Inflation Rate (1/Yr)
  InflationRateNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationRateNation",year) #[Nation,Year]  Inflation Rate (1/Yr)
  InSm::VariableArray{1} = ReadDisk(db,"MOutput/InSm",year) #[Area,Year]  Smoothed Inflation Rate (1/Yr)
  InSmPrior::VariableArray{1} = ReadDisk(db,"MOutput/InSm",prior) #[Area,Year]  Smoothed Inflation Rate (1/Yr)
  INST::Float32 = ReadDisk(db,"MInput/INST") #  Inflation Rate Smooth Time (Years)
  LaborForce::VariableArray{1} = ReadDisk(db,"MInput/LaborForce",year) #[Nation,Year]  Total Labor Force,Age 15+ (000s)
  MacroSwitch::Vector{String} = ReadDisk(db,"MInput/MacroSwitch") #[Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  MapOther::VariableArray{2} = ReadDisk(db,"MInput/MapOther") #[ECC,Area]  Map for Economic Sectors to sum as Other (1 = Include)
  MEDriver::VariableArray{2} = ReadDisk(db,"MOutput/MEDriver",year) #[ECC,Area,Year]  Driver for Process Emissions (Various Millions/Yr)
  MPC::Float32 = ReadDisk(db,"MInput/MPC") # Production Capacity of a Mature Industry (M$/Yr)
  NGasFr::VariableArray{2} = ReadDisk(db,"MInput/NGasFr",year) #[ECC,Area,Year]  Fraction of National Natural Gas Driver allocated to each Area (Btu/Btu)
  GasDemand::VariableArray{1} = ReadDisk(db,"MOutput/GasDemand",year) #[Area,Year]  Gas Demands including NG,RNG,and H2 (TBtu/Yr)
  OGArea::Vector{String} = ReadDisk(db,"SpInput/OGArea") #[OGUnit]  Area
  PC::VariableArray{2} = ReadDisk(db,"MOutput/PC",year) #[ECC,Area,Year]  Production Capacity (M$/Yr)
  PCPrior::VariableArray{2} = ReadDisk(db,"MOutput/PC",prior) #[ECC,Area,Year]  Production Capacity (M$/Yr)
  PCA::VariableArray{3} = ReadDisk(db,"MOutput/PCA",year) #[Age,ECC,Area,Year]  Production Capacity Additions ($/YR/YR)
  PCLV::VariableArray{3} = ReadDisk(db,"MOutput/PCLV",year) #[Age,ECC,Area,Year]  Production Capacity ($/YR)
  PCLVPrior::VariableArray{3} = ReadDisk(db,"MOutput/PCLV",prior) #[Age,ECC,Area,Year]  Production Capacity ($/YR)
  PCMGR::VariableArray{1} = ReadDisk(db,"MInput/PCMGR") #[ECC]  Maximum Growth Rate of Production Capacity ($/YR)
  PCPL::VariableArray{2} = ReadDisk(db,"MInput/PCPL",year) #[ECC,Area,Year]  Physical Life of Production Capacity (YearS)
  PCR::VariableArray{3} = ReadDisk(db,"MOutput/PCR",year) #[Age,ECC,Area,Year]  Production Capacity Retirement ($/YR/YR)
  Pop::VariableArray{2} = ReadDisk(db,"MOutput/Pop",year) #[ECC,Area,Year]  Population (Millions)
  PopT::VariableArray{1} = ReadDisk(db,"MOutput/PopT",year) #[Area,Year]  Population (Millions)
  RealDispInc::VariableArray{1} = ReadDisk(db,"MInput/RealDispInc",year) #[Area,Year]  Real Disposable Income (Million Real CN$)
  RfArea::Vector{String} = ReadDisk(db,"SpInput/RfArea") #[RfUnit]  Refinery Area
  RPI::VariableArray{1} = ReadDisk(db,"MOutput/RPI",year) #[Area,Year]  Personal Income(Real M$/YR)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
  SegSw::VariableArray{1} = ReadDisk(db,"MainDB/SegSw") #[Seg] Segment Execution Switch
  StockAdjustment::VariableArray{2} = ReadDisk(db,"MInput/StockAdjustment",year) #[ECC,Area,Year]  Exogenous Capital Stock Adjustment ($/$)
  THHS::VariableArray{1} = ReadDisk(db,"MOutput/THHS",year) #[Area,Year]  Total Households (Households)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",prior) #[Fuel,ECC,Area,Prior]  Energy Demands (TBtu/Yr)
  UnArea::Vector{String} = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
  VehiclesPerPerson::VariableArray{1} = ReadDisk(db,"MInput/VehiclesPerPerson",year) #[Area,Year]  Average Vehicle Stock Per Person
  xCAProd::VariableArray{1} = ReadDisk(db,"SpInput/xCAProd",year) #[Area,Year]  Coal Production - Reference Case (TBtu/Yr)
  xDriver::VariableArray{2} = ReadDisk(db,"MInput/xDriver",year) #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  xDriverPrior::VariableArray{2} = ReadDisk(db,"MInput/xDriver",prior) #[ECC,Area,Prior]  Economic Driver in Previous Year (Various Units)
  xECUF::VariableArray{2} = ReadDisk(db,"MInput/xECUF",year) #[ECC,Area,Year]  Capital Utilization Fraction
  xEmp::VariableArray{2} = ReadDisk(db,"MInput/xEmp",year) #[ECC,Area,Year]  Employment (Thousands)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNode::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNode") # [Node,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xGAProd::VariableArray{2} = ReadDisk(db,"SInput/xGAProd",year) #[Process,Area,Year]  Natural Gas Production (TBtu/Yr)
  xGO::VariableArray{2} = ReadDisk(db,"MInput/xGO",year) #[ECC,Area,Year]  Gross Output (Real M$/Yr)
  xGOPrior::VariableArray{2} = ReadDisk(db,"MInput/xGO",prior) #[ECC,Area,Prior]  Gross Output (Real M$/Yr)
  xGProd::VariableArray{2} = ReadDisk(db,"SInput/xGProd",year) #[Process,Nation,Year]  Primary Gas Production (TBtu/Yr)
  xGRP::VariableArray{1} = ReadDisk(db,"MInput/xGRP",year) #[Area,Year]  Gross Regional Product (Real M$/Yr)
  xGRPPrior::VariableArray{1} = ReadDisk(db,"MInput/xGRP",prior) #[Area,Year]  Gross Regional Product (Real M$/Yr)
  xHHS::VariableArray{2} = ReadDisk(db,"MInput/xHHS",year) #[ECC,Area,Year]  Households (Households)
  xHSize::VariableArray{2} = ReadDisk(db,"MInput/xHSize",year) #[ECC,Area,Year]  Household Size (People/Household)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  xInflationNode::VariableArray{2} = ReadDisk(db,"MInput/xInflationNode") # [Node,Year] Inflation Index ($/$)
  xInflationRate::VariableArray{1} = ReadDisk(db,"MInput/xInflationRate",year) #[Area,Year]  Inflation Rate ($/$)
  xInflationRateNation::VariableArray{1} = ReadDisk(db,"MInput/xInflationRateNation",year) #[Nation,Year]  Inflation Rate ($/$)
  xOAProd::VariableArray{2} = ReadDisk(db,"SInput/xOAProd",year) #[Process,Area,Year]  Oil Production (TBtu/Yr)
  xPC::VariableArray{2} = ReadDisk(db,"MInput/xPC",year) #[ECC,Area,Year]  Production Capacity (M$/Yr)
  xPop::VariableArray{2} = ReadDisk(db,"MInput/xPop",year) #[ECC,Area,Year]  Population (Millions)
  xPopT::VariableArray{1} = ReadDisk(db,"MInput/xPopT",year) #[Area,Year]  Population (Millions)
  xRPI::VariableArray{1} = ReadDisk(db,"MInput/xRPI",year) #[Area,Year]  Total Personal Income (Real M$/Yr)
  xRPPAProd::VariableArray{1} = ReadDisk(db,"SInput/xRPPAProd",year) #[Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xSegSw::VariableArray{1} = ReadDisk(db,"MainDB/xSegSw") #[Seg] Segment Execution Switch
  xSuProd::VariableArray{1} = ReadDisk(db,"MInput/xSuProd",year) #[Area,Year]  Sugar Production (Thou. $)
  xTHHS::VariableArray{1} = ReadDisk(db,"MInput/xTHHS",year) #[Area,Year]  Total Households (Households)

  #
  # Scratch Variables
  #
  DrGR::VariableArray{2} = zeros(Float32,length(ECC),length(Area))
  ExchgTemp::VariableArray{3} = zeros(Float32,length(GNode),length(Area),length(Year))
  GOGR::VariableArray{2} = zeros(Float32,length(ECC),length(Area))
  GPGR::VariableArray{2} = zeros(Float32,length(ECC),length(Area))
  InflaTemp::VariableArray{3} = zeros(Float32,length(GNode),length(Area),length(Year))
  LUDriver::VariableArray{1} = zeros(Float32,length(Area))
  PCMin::VariableArray{2} = zeros(Float32,length(ECC),length(Area))

end

function InitializeExchangeRateAndInflation(data::Data)
  (; db) = data
  (;Areas,Nation,Nations,Years) = data
  (;ExchangeRate,ExchangeRateNation,Inflation,InflationNation) = data
  (;xExchangeRate,xExchangeRateNation,xInflation,xInflationNation) = data

  @. ExchangeRate = xExchangeRate
  @. ExchangeRateNation = xExchangeRateNation
  @. Inflation = xInflation
  @. InflationNation = xInflationNation
  
  WriteDisk(db,"MOutput/ExchangeRate",ExchangeRate)
  WriteDisk(db,"MOutput/ExchangeRateNation",ExchangeRateNation)  
  WriteDisk(db,"MOutput/Inflation",Inflation)
  WriteDisk(db,"MOutput/InflationNation",InflationNation)

end


function NodeExchangeAndInflation(data::Data)
  (; db,year,current,next) = data
  (;Nation,Node,Nodes,Years) = data
  (;ExchangeRateNode,InflationNode) = data
  (;xExchangeRateNode,xExchangeRateNation,xInflationNation,xInflationNode) = data

  #
  # Initialize Node
  #
  
  #
  # US Nodes
  #
  US = Select(Nation,"US")  
  for node in Nodes, year in Years
    xExchangeRateNode[node,year]=xExchangeRateNation[US,year] 
    xInflationNode[node,year]=xInflationNation[US,year]
  end

  # 
  # Canada Nodes
  #
  CN = Select(Nation,"CN")
  nodes = Select(Node,["ON","QC","BC","AB","MB","SK","NB","NS","NL","LB","PE","YT","NT","NU"])
  for node in nodes, year in Years
    xExchangeRateNode[node,year]=xExchangeRateNation[CN,year] 
    xInflationNode[node,year]=xInflationNation[CN,year]
  end

  @. ExchangeRateNode = xExchangeRateNode
  @. InflationNode = xInflationNode

  WriteDisk(db, "MOutput/ExchangeRateNode", ExchangeRateNode)
  WriteDisk(db, "MOutput/InflationNode", InflationNode)
  WriteDisk(db, "MInput/xExchangeRateNode", xExchangeRateNode)
  WriteDisk(db, "MInput/xInflationNode", xInflationNode)

end

function NationInflationRateAndInflation(data::Data)
  (; db,year,current,prior,next) = data
  (; Nations) = data #sets
  (; GDPDeflator,InflationNation,InflationRateNation,xInflationRateNation) = data

  year = current
  for nation in Nations
    if current > 1 && GDPDeflator[nation,year] > 0.0 && GDPDeflator[nation,prior] > 0.0
      InflationRateNation[nation] = 
        (GDPDeflator[nation,year]-GDPDeflator[nation,prior])/GDPDeflator[nation,prior]
    else
      InflationRateNation[nation] = xInflationRateNation[nation]
    end
    
    InflationNation[nation,year] = InflationNation[nation,prior]+
                                   InflationNation[nation,prior]*InflationRateNation[nation]
    InflationNation[nation,next] = InflationNation[nation,year]+
                                   InflationNation[nation,year]*InflationRateNation[nation]
  end

  WriteDisk(db,"MOutput/InflationRateNation",year,InflationRateNation)
  WriteDisk(db,"MOutput/InflationNation",InflationNation)
end

function MapForCalibExchangeRateInflation(data::Data)
  (; db,year,current,next) = data
  (; Areas,Nations) = data #sets
  (; ANMap,ExchangeRate,ExchangeRateNation) = data
  (; Inflation,InflationNation,InflationRate,InflationRateNation) = data
 
  years = collect(current:next)
  for area in Areas, nation in Nations
    if ANMap[area,nation] == 1
      for year in years
        ExchangeRate[area,year] = ExchangeRateNation[nation,year]
      end
      for year in years      
        Inflation[area,year] = InflationNation[nation,year]
      end
      InflationRate[area] = InflationRateNation[nation]
    end
  end

  WriteDisk(db,"MOutput/ExchangeRate",ExchangeRate)
  WriteDisk(db,"MOutput/Inflation",Inflation)
  WriteDisk(db,"MOutput/InflationRate",year,InflationRate)
end

function MapExchangeRateInflation(data::Data)
  (; db,year,current,next) = data
  (; Area,Areas,GNodes,Nation,Nations,Node,Nodes,Year,Years) = data #sets
  (; ANMap,ExchangeRate,ExchangeRateGNode,ExchangeRateNation) = data
  (; ExchangeRateNode,ExchangeRateOGUnit,ExchangeRateRfUnit) = data
  (; ExchangeRateUnit,GNodeAreaMap,Inflation,InflationGNode) = data
  (; InflationNation,InflationNode,InflationOGUnit,InflationRate) = data
  (; InflationRateNation,InflationRfUnit,InflationUnit,OGArea) = data
  (; RfArea,UnArea) = data
  (; ExchgTemp,InflaTemp) = data
  ExchangeRateCN::VariableArray{1} = zeros(Float32,length(Year))
  ExchangeRateUS::VariableArray{1} = zeros(Float32,length(Year))

  InflationCN::VariableArray{1} = zeros(Float32,length(Year))
  InflationUS::VariableArray{1} = zeros(Float32,length(Year))

  PointerCN = Select(Nation,"CN")
  PointerUS = Select(Nation,"US")

  for y in Years

    InflationCN[y] = InflationNation[PointerCN,y]
    InflationUS[y] = InflationNation[PointerUS,y]
    ExchangeRateCN[y] = ExchangeRateNation[PointerCN,y]
    ExchangeRateUS[y] = ExchangeRateNation[PointerUS,y]
  end

  for y in [current,next]
    for area in Areas
      ExchangeRate[area,y] = sum(ExchangeRateNation[nation,y]*ANMap[area,nation] for nation in Nations)
      Inflation[area,y] = sum(InflationNation[nation,y]*ANMap[area,nation] for nation in Nations)
      InflationRate[area] = sum(InflationRateNation[nation]*ANMap[area,nation] for nation in Nations)
    end
    
  end
  
  WriteDisk(db,"MOutput/ExchangeRate",ExchangeRate)
  WriteDisk(db,"MOutput/Inflation",Inflation)
  WriteDisk(db,"MOutput/InflationRate",year,InflationRate)
  #

  for gnode in GNodes, y in [current,next]
    for area in Areas

      InflaTemp[gnode,area,y] = Inflation[area,y]   *GNodeAreaMap[gnode,area]
      ExchgTemp[gnode,area,y] = ExchangeRate[area,y]*GNodeAreaMap[gnode,area]
    end
    
    InflationGNode[gnode,y] = maximum(InflaTemp[gnode,:,y])
    ExchangeRateGNode[gnode,y] = maximum(ExchgTemp[gnode,:,y])
    WriteDisk(db,"MOutput/ExchangeRateGNode",ExchangeRateGNode)
    WriteDisk(db,"MOutput/InflationGNode",InflationGNode)
  end
  
  #
  # US Nodes (add Nation to Node Map)
  #
  for node in Nodes, y in [current,next]
    ExchangeRateNode[node,y] = ExchangeRateUS[y]
    InflationNode[node,y] = InflationUS[y]
  end
  
  #
  # Canada Nodes (add Nation to Node Map)
  #
  for node in Select(Node, (from = "MB", to = "NU")), y in [current,next]
    ExchangeRateNode[node,y] = ExchangeRateCN[y]
    InflationNode[node,y] = InflationCN[y]
  end
  
  WriteDisk(db,"MOutput/ExchangeRateNode",ExchangeRateNode)
  WriteDisk(db,"MOutput/InflationNode",InflationNode)
  #
  for area in Areas, y in [current,next]
    ogunits = findall(OGArea .== Area[area])
    for ogunit in ogunits
      InflationOGUnit[ogunit,y] = Inflation[area,y]
      ExchangeRateOGUnit[ogunit,y] = ExchangeRate[area,y]
    end
    
  end
  
  WriteDisk(db,"MOutput/ExchangeRateOGUnit",ExchangeRateOGUnit)
  WriteDisk(db,"MOutput/InflationOGUnit",InflationOGUnit)
  #
  for area in Areas, y in [current,next]
    rfunits = findall(RfArea .== Area[area])
    for rfunit in rfunits
      InflationRfUnit[rfunit,y] = Inflation[area,y]
      ExchangeRateRfUnit[rfunit,y] = ExchangeRate[area,y]
    end
    
  end
  
  WriteDisk(db,"MOutput/ExchangeRateRfUnit",ExchangeRateRfUnit)
  WriteDisk(db,"MOutput/InflationRfUnit",InflationRfUnit)
  #
  for area in Areas, y in [current,next]
    units = findall(UnArea .== Area[area])
    for unit in units
      InflationUnit[unit,y] = Inflation[area,y]
      ExchangeRateUnit[unit,y] = ExchangeRate[area,y]
    end
    
  end
  
  WriteDisk(db,"MOutput/ExchangeRateUnit",ExchangeRateUnit)
  WriteDisk(db,"MOutput/InflationUnit",InflationUnit)
  #
end

function SmoothInflationRate(data::Data)
  (; db,year,CTime,current,prior,next) = data
  (; Areas) = data #sets
  (; InSm,InSmPrior,INST,InflationRate) = data


  for area in Areas
    @finite_math InSm[area] = InSmPrior[area]+DT*(InflationRate[area]-InSmPrior[area])/INST
  end

  WriteDisk(db,"MOutput/InSm",year,InSm)
end

function ApplyDriverSwitch(data::Data)
  (; db,year,CTime) = data
  (; Area,Areas,ECC,ECCs,ES,Fuel,Nations,Plants,Process,Processes) = data #sets
  (; ANMap,BfProduction,DrSwitch,EAProd,ECCProMap) = data
  (; Floorspace,GasDemand,MEDriver,MapOther,NGasFr) = data
  (; SecMap,TotDemand,VehiclesPerPerson,xCAProd) = data
  (; xDriver,xGAProd,xGO,xGProd,xGRP,xOAProd) = data
  (; xPopT,xRPI,xRPPAProd,xTHHS) = data
  NSGProd::VariableArray{1} = zeros(Float32,length(Process))
  xGOOther::VariableArray{1} = zeros(Float32,length(Area))

  #
  # Select Process*, Area*, Nation(CN)
  # Select Area If ANMap eq 1
  # Select Area If AreaKey ne "NL"
  # Select Process If ProcessKey ne "OilSandsUpgraders"
  #

  #
  OPipeDriver=sum(xOAProd[process,area] for area in Select(Area,["ON","QC",
    "BC","AB","MB","SK","NB","NS","PE","YT","NT","NU"]),
     process in Select(Process, !=("OilSandsUpgraders")))

  #
  # Gas Demands excluding Electric Utility Demands
  # Select the ECCs in residential (SecMap=1), commercial (SecMap=2),
  # industrial (SecMap=3), and transportation (SecMap=4) sectors.
  #
  # Select Fuel(Hydrogen,NaturalGas,RNG)
  #
  eccs = 1
  for es in Select(ES,(from = "Residential",to = "Transport"))
    eccs = union(eccs,findall(SecMap .== es))
  end
  
  for area in Areas
    fuels = Select(Fuel,["Hydrogen","NaturalGas","RNG"])
    GasDemand[area] = sum(TotDemand[fuel,ecc,area] for fuel in fuels, ecc in eccs)
  end

  WriteDisk(db,"MOutput/GasDemand",year,GasDemand)

  for area in Areas
    
    #
    # Gross Output from "Other" Sectors for DrSwitch=6
    #
    xGOOther[area] = sum(xGO[ecc,area]*MapOther[ecc,area] for ecc in ECCs)
  end

  #
  # Nova Scotia Natural Gas Production (Area 8 is Nova Scotia)
  #
  for process in Processes
    NSGProd[process] = sum(xGAProd[process,area] for area in Select(Area,"NS"))
  end

  for area in Areas,ecc in ECCs
    
    #
    # Floor Space as Driver (DrSwitch=1)
    #
    if DrSwitch[ecc,area] == 1
      xDriver[ecc,area] = Floorspace[ecc,area]
    
    #
    # GRP as Driver (DrSwitch=2)
    #
    elseif DrSwitch[ecc,area] == 2
      xDriver[ecc,area] = xGRP[area]
    
    #
    # Personal Income as Driver (DrSwitch=3)
    #
    elseif DrSwitch[ecc,area] == 3
      xDriver[ecc,area] = xRPI[area]
    
    #
    # Oil Pipeline Driver is National Oil Production (DrSwitch=4
    #
    elseif DrSwitch[ecc,area] == 4
      xDriver[ecc,area] = OPipeDriver
    
    #
    # National Natural Gas Production as Driver (DrSwitch=5)
    #
    elseif DrSwitch[ecc,area] == 5
      xDriver[ecc,area] = sum(xGProd[process,nation]*ECCProMap[ecc,process]*ANMap[area,nation] for process in Processes, nation in Nations)*NGasFr[ecc,area]
    
    #
    # Driver is Gross Output from "Other" Sectors (DrSwitch=6)
    #
    elseif DrSwitch[ecc,area] == 6
      xDriver[ecc,area] = xGOOther[area]
    
    #
    # Local Oil Production as Driver (DrSwitch=7)
    #
    elseif DrSwitch[ecc,area] == 7
      xDriver[ecc,area] = sum(xOAProd[process,area]*ECCProMap[ecc,process] for process in Processes)
    
    #
    # Local Natural Gas Production as Driver (DrSwitch=8)
    # 23.08.10, LJD: Why is DrSwitch 8 different from 25?
    #
    elseif DrSwitch[ecc,area] == 8
      xDriver[ecc,area] = sum(xGAProd[process,area]*ECCProMap[ecc,process] for process in Processes)
    
    #
    # Local Population as Driver (DrSwitch=9)
    #
    elseif DrSwitch[ecc,area] == 9
      xDriver[ecc,area] = xPopT[area]
    
    #
    # Driver is fixed as for Land Use (DrSwitch=10)
    #
    elseif DrSwitch[ecc,area] == 10
      xDriver[ecc,area] = 1.0
    
    #
    # Hotel Industry Gross Output as Driver (DrSwitch=11)
    #23.08.10, LJD: ECC["Hotel"] no longer exsits in model.
    #
    elseif DrSwitch[ecc,area] == 11
      xDriver[ecc,area] = xGO[select(ECC,"OtherCommercial"),area]
    
    #
    # Other Food/Agriculture Gross Output as Driver (DrSwitch=12)
    #23.08.10, LJD: ECC["OtherFood"] no longer exsits in model.
    #xDriver[ecc,area] = xGO[select(ECC["OtherFood"]),area]
    #
    elseif DrSwitch[ecc,area] == 12
     xDriver[ecc,area] = xGO[select(ECC,"OnFarmFuelUse"),area]
    
    #
    # Sugar Production as Driver (DrSwitch=13)
    # 23.08.10, LJD: does xSuProd even exist anymore?
    #
    elseif DrSwitch[ecc,area] == 13
      xDriver[ecc,area] = xSuProd[area]
    
    #
    # Military Employment as Driver (DrSwitch=14)
    # 23.08.10, LJD: There is no ECC["Military"] in current model code.
    #xDriver[ecc,area] = xEmp[area,Select(ECC["Military"])]
    #
    elseif DrSwitch[ecc,area] == 14
      xDriver[ecc,area] = xDriver[ecc,area]
    
    #
    # Land Area as Driver (DrSwitch=15)
    #
    elseif DrSwitch[ecc,area] == 15
      xDriver[ecc,area] = 1.0
    
    #
    # Total Households as Driver (DrSwitch=16)
    #
    elseif DrSwitch[ecc,area] == 16
      xDriver[ecc,area] = xTHHS[area]
    
    #
    # Electricity Production as Driver (DrSwitch=17)
    #
    elseif DrSwitch[ecc,area] == 17
      xDriver[ecc,area] = sum(EAProd[plant,area] for plant in Plants)
    
    #
    # RPP Production as Driver (DrSwitch=18)
    #
    elseif DrSwitch[ecc,area] == 18
      xDriver[ecc,area] = xRPPAProd[area]
    
    #
    # Freight Ton-Miles Traveled as Driver (DrSwitch=19)
    #
    elseif DrSwitch[ecc,area] == 19
      xDriver[ecc,area] = MEDriver[ecc,area]
    
    #
    # Farm Gross Output as Driver (DrSwitch=20)
    #
    elseif DrSwitch[ecc,area] == 20
      xDriver[ecc,area] = MEDriver[ecc,area]
   
    #
    # Gross Output as Driver (DrSwitch=21)
    #
    elseif DrSwitch[ecc,area] == 21
      xDriver[ecc,area] = xGO[ecc,area]
    
    #
    # Natural Gas Demands as Driver (DrSwitch=22)
    #
    elseif DrSwitch[ecc,area] == 22
      if CTime > HisTime
        xDriver[ecc,area] = GasDemand[area]
      else
        xDriver[ecc,area] = xDriver[ecc,area]
      end
    
    #
    # Liquid Natural Gas Production as Driver (DrSwitch=23)
    #
    elseif DrSwitch[ecc,area] == 23
      process = Select(Process,"LNGProduction")
      xDriver[ecc,area] = xGAProd[process,area]
    
    #
    # Electricity Production as Driver (DrSwitch=24)
    # 23.08.09, LJD: Described as "electricity production" but xCAProd 
    # is Coal Production. Comment seems wrong.
    #
    elseif DrSwitch[ecc,area] == 24
      xDriver[ecc,area] = xCAProd[area]
    
    #
    # Local Nova Scotia Natural Gas Production as Driver (DrSwitch=25)
    # 23.08.10, LJD: Why is DrSwitch 8 different from 25?
    #
     elseif DrSwitch[ecc,area] == 25
      xDriver[ecc,area] = sum(NSGProd[process]*ECCProMap[ecc,process] for process in Processes)
    
    #
    # Biofuel Production as Driver (DrSwitch=26)
    #
    elseif DrSwitch[ecc,area] == 26
      xDriver[ecc,area] = BfProduction[area]
    
    #
    # Number of vehicles as Driver (DrSwitch=27)
    #
    elseif DrSwitch[ecc,area] == 27
      xDriver[ecc,area] = xPopT[area]*VehiclesPerPerson[area]
    
    #
    # Driver is exogenous (DrSwitch=0)
    #
    elseif DrSwitch[ecc,area] == 0
      xDriver[ecc,area] = xDriver[ecc,area]
    end
    
  end
  
  #
  # Insure that the Drivers are greater than zero for all years.
  # This enables new industries to come into existence (from zero to
  # a postive number) in the forecast period.  J. Amlin 5/29/09
  #
  @. xDriver = max(xDriver,0.00001)

  WriteDisk(db,"MInput/xDriver",year,xDriver)

end

function AdjMEconomy(data::Data)
  (; db,year,CTime) = data
  (; Areas,ECCs) = data #sets
  (; Driver,DriverMultiplier,DriverMultiplierPrior,DriverPrior) = data
  (; GO,GOMAT,GOMSmooth,GOMSmoothPrior,GOMult,GOPrior) = data
  (; GRP,GRPAdj,GRPPrior,xDriver) = data
  (; xDriverPrior,xGO,xGOPrior,xGRP,xGRPPrior) = data
  (; DrGR,GOGR,GPGR) = data

  if CTime > 2005
    for area in Areas, ecc in ECCs
      #
      # Smooth changes in energy production (GOMult, GOMSmooth)
      #
      @finite_math GOMSmooth[ecc,area] = GOMSmoothPrior[ecc,area]+
        (GOMult[ecc,area]-GOMSmoothPrior[ecc,area])/GOMAT[ecc,area]
      #
      # The growth rate of the economic driver (Driver) is adjusted to
      # reflect changes in the energy system (GOMSmooth) and to incorporate
      # the impact of the growth rate adjustment (GRPAdj) which is a policy
      # or uncertainty variable.
      #
      xDriver[ecc,area] = xDriver[ecc,area]*GOMSmooth[ecc,area]
      xDriverPrior[ecc,area] = xDriverPrior[ecc,area]*GOMSmoothPrior[ecc,area]
      if xDriverPrior[ecc,area] > 0.0
        DrGR[ecc,area] = (xDriver[ecc,area]-xDriverPrior[ecc,area])/
          xDriverPrior[ecc,area]
        Driver[ecc,area] = DriverPrior[ecc,area]/
          DriverMultiplierPrior[ecc,area]*(1+(DrGR[ecc,area]+GRPAdj[area]))
      else
        Driver[ecc,area] = xDriver[ecc,area]
      end
      #
      # The growth rate of gross output (GO) is adjusted to reflect changes
      # in the energy system (GOMSmooth) and to incorporate the impact of
      # the growth rate adjustment (GRPAdj) which is a policy or uncertainty
      # variable.
      #
      xGO[ecc,area] = xGO[ecc,area]*GOMSmooth[ecc,area]
      xGOPrior[ecc,area] = xGOPrior[ecc,area]*GOMSmoothPrior[ecc,area]
      if GOPrior[ecc,area] > 0.0
        GOGR[ecc,area] = (xGO[ecc,area]-xGOPrior[ecc,area])/xGOPrior[ecc,area]
        GO[ecc,area] = GOPrior[ecc,area]*(1+(GOGR[ecc,area]+GRPAdj[area]))      
      else
        GO[ecc,area] = xGO[ecc,area]
      end
      #
      # The Gross Regional Product (GRP) is adjusted to incorporate the
      # impact of the growth rate adjustment (GRPAdj) which is a policy
      # or uncertainty variable.
      #     
      if GRPPrior[area] > 0.0
        GPGR[area] = (xGRP[area]-xGRPPrior[area])/xGRPPrior[area]
        GRP[area] = GRPPrior[area]*(1+(GPGR[area]+GRPAdj[area]))      
      else
        GRP[area] = xGRP[area]
      end
    end
    WriteDisk(db,"SOutput/GOMSmooth",year,GOMSmooth)
  else
    for area in Areas, ecc in ECCs
      GO[ecc,area] = xGO[ecc,area]
      Driver[ecc,area] = xDriver[ecc,area]
      GRP[area] = xGRP[area]
    end
  end

  for area in Areas, ecc in ECCs
    Driver[ecc,area] = Driver[ecc,area]*DriverMultiplier[ecc,area]
  end

  WriteDisk(db,"MOutput/Driver",year,Driver)
  WriteDisk(db,"MOutput/GRP",year,GRP)
  WriteDisk(db,"MOutput/GO",year,GO)

end

#
# 23.08.10, LJD Renamed from Procedure "MEconomy", since this was already 
#   used for the segment.
#
function MEconomyStatistics(data::Data)
  (; db,year) = data
  (; Age,Ages,Areas,ECC,ECCs,ES) = data #sets
  (; Driver,ECGR,ECUF,Emp,GRPGR,HHS,HSize) = data
  (; LUDriver,MEDriver,PC,PCA,PCLV,PCLVPrior,PCMin,PCPL) = data
  (; PCPrior,PCR,Pop,PopT,RPI,SecMap,StockAdjustment) = data
  (; THHS,xECUF,xEmp,xHHS,xPC,xPop,xPopT,xRPI) = data

  #
  # This procedure converts an exogenously specifed gross output (GO)
  # into production capacity (PC, PCLV) and investments (PCA).
  #
  
  #
  # Employment
  #
  for area in Areas, ecc in ECCs
    Emp[ecc,area] = xEmp[ecc,area]
  end

  for area in Areas, es in Select(ES,"Residential")
    eccs = findall(SecMap .== es)
  
    #
    # Population
    #
    PopT[area] = xPopT[area]
    for ecc in eccs
      Pop[ecc,area] = xPop[ecc,area]
    end
    
    #
    # Personal Income
    #
    RPI[area] = xRPI[area]
      
    #
    # Households
    #
    for ecc in eccs
      HHS[ecc,area] = xHHS[ecc,area]
    end
    THHS[area] = sum(HHS[ecc,area] for ecc in eccs)   
    
    #
    # Average Household Size
    #
    for ecc in eccs    
      @finite_math HSize[ecc,area] = Pop[ecc,area]/HHS[ecc,area]*1000000
    end

  end
  
  #
  # Convert from the economic driver (Driver), normally gross output (GO),
  # into the implied production capacity (xPC) using the exogenous
  # capacity utilization factor (xECUF).
  #
  for area in Areas, ecc in ECCs
    @finite_math xPC[ecc,area] = Driver[ecc,area]/xECUF[ecc,area]   
  end
  WriteDisk(db,"MInput/xPC",year,xPC)
  
  #
  # Production Capacity in Previous Year
  #
  for area in Areas, ecc in ECCs
    PCPrior[ecc,area] = sum(PCLVPrior[age,ecc,area] for age in Ages)
  end

  #
  # Production Capacity Retirements
  #
  for area in Areas, ecc in ECCs, age in Ages
    @finite_math PCR[age,ecc,area] = PCLVPrior[age,ecc,area]/(PCPL[ecc,area]/3)
  end

  #
  # Production Capacity
  #
  for area in Areas, ecc in ECCs
    PC[ecc,area] = xPC[ecc,area]
  end

  #
  # Constraint on PC Growth - PC cannot be less than the retirements
  #
  for area in Areas, ecc in ECCs
    PCMin[ecc,area] = PCPrior[ecc,area]*1.000001-PCR[Select(Age,"Old"),ecc,area]
    PC[ecc,area] = max(PC[ecc,area],PCMin[ecc,area])
  end

  #
  # GRP growth rate differential
  #
  for area in Areas, ecc in ECCs
    @finite_math ECGR[ecc,area] = (PC[ecc,area]-PCPrior[ecc,area])/PCPrior[ecc,area]-GRPGR[area]
  end

  #
  # New Production Capacity
  #
  New = Select(Age,"New")
  Old = Select(Age,"Old")
  for area in Areas, ecc in ECCs
    PCA[New,ecc,area] = (PCPrior[ecc,area]*(ECGR[ecc,area]+GRPGR[area]))+PCR[Old,ecc,area]
    
    #
    # New Production Capacity cannot be negative
    #
    if PCR[Old,ecc,area] < 0
      
      @finite_math ECGR[ecc,area] = -GRPGR[area]-PCR[Old,ecc,area]/PCPrior[ecc,area]
      
      PCA[New,ecc,area] = (PCPrior[ecc,area]*(ECGR[ecc,area]+GRPGR[area]))+PCR[Old,ecc,area]
    end
  end

  #
  # Age Capital Stock
  #
  for area in Areas, ecc in ECCs
    PCA[Select(Age,"Mid"),ecc,area] = PCR[Select(Age,"New"),ecc,area]
    PCA[Select(Age,"Old"),ecc,area] = PCR[Select(Age,"Mid"),ecc,area]
  end

  for area in Areas, ecc in ECCs, age in Ages
    PCLV[age,ecc,area] = PCLVPrior[age,ecc,area]+PCA[age,ecc,area] - PCR[age,ecc,area]
  end

  #
  # Exogenous Stock Adjustment
  # The Stock Adjustment (StockAdjustment) is used to represent non-systematic
  # adjustment to the capital stock including the addition of new
  # service territory or the impact of a hurricane.
  #
  for area in Areas, ecc in ECCs, age in Ages
    PCLV[age,ecc,area] = PCLV[age,ecc,area]*(1+StockAdjustment[ecc,area])
  end

  #
  # Production Capacity
  #
  for area in Areas, ecc in ECCs
    PC[ecc,area] = sum(PCLV[age,ecc,area] for age in Ages)
  end

  #
  # Compute capacity utilzation factor (ECUF) based on the difference
  # between the production capacity (PC) and the economic driver (Driver)
  # which is normally gross output (GO).
  #
  for area in Areas, ecc in ECCs
    @finite_math ECUF[ecc,area] = Driver[ecc,area]/PC[ecc,area]
  end

  WriteDisk(db,"MCalDB/ECGR",year,ECGR)
  WriteDisk(db,"MOutput/ECUF",year,ECUF)
  WriteDisk(db,"MOutput/Emp",year,Emp)
  WriteDisk(db,"MOutput/HHS",year,HHS)
  WriteDisk(db,"MOutput/HSize",year,HSize)
  WriteDisk(db,"MOutput/PC",year,PC)
  WriteDisk(db,"MOutput/PCA",year,PCA)
  WriteDisk(db,"MOutput/PCLV",year,PCLV)
  WriteDisk(db,"MOutput/PCR",year,PCR)
  WriteDisk(db,"MOutput/Pop",year,Pop)
  WriteDisk(db,"MOutput/PopT",year,PopT)
  WriteDisk(db,"MOutput/RPI",year,RPI)
  WriteDisk(db,"MOutput/THHS",year,THHS)

  #
  # Driver for Process Emissions (MEDriver) defaults to the Economic 
  #  Driver (Driver), but may be change in the other sectors 
  #  (transportation uses VMT).  Jeff Amlin 2/9/11
  #
  for area in Areas, ecc in ECCs
    MEDriver[ecc,area] = Driver[ecc,area]
  end
  
  #
  # Forestry uses Land Use as the process emissions driver
  #
  for area in Areas
    LUDriver[area] = MEDriver[Select(ECC,"LandUse"),area]
    MEDriver[Select(ECC,"Forestry"),area] = LUDriver[area]
  end
  WriteDisk(db,"MOutput/MEDriver",year,MEDriver)

end

function Control(data::Data)
  (; Nation) = data
  (; SegSw) = data

  #
  # Processing That Applies To All
  #
  # Do If (SegSw(MEconomy) eq Exogenous) or (SegSw(MEconomy) eq Endogenous)
  # @info "MEconomy.jl - Control - Apply data"
  #
  InitializeExchangeRateAndInflation(data)
  NodeExchangeAndInflation(data)
  NationInflationRateAndInflation(data)
  MapExchangeRateInflation(data)
  SmoothInflationRate(data)
  ApplyDriverSwitch(data)
  AdjMEconomy(data)
  MEconomyStatistics(data)
  
  #End Do If

end # function Control

end # module MEconomy
