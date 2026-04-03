#
# WCI_Market.jl - CA and QC GHG Cap and Trade Market
#
using EnergyModel

module WCI_Market

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  market = 200
  Current = Yr(2013)

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaKey::SetArray = ReadDisk(db, "MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Offset::SetArray = ReadDisk(db,"MainDB/OffsetKey")
  OffsetDS::SetArray = ReadDisk(db,"MainDB/OffsetDS")
  Offsets::Vector{Int} = collect(Select(Offset))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade, Cap Only=2)
  CBSw::VariableArray{2} = ReadDisk(db,"SInput/CBSw") # [Market,Year] Switch to send Government Revenues to Economic Model (1=Yes)
  CoverNew::VariableArray{4} = ReadDisk(db,"EGInput/CoverNew") # [Plant,Poll,Area,Year] Fraction of New Plants Covered in Emissions Market (1=100% Covered)
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db,"SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  ElecSw::VariableArray{3} = ReadDisk(db,"SInput/ElecSw") # [Poll,Area,Year] Electricity Emission Allocation Switch
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  ETABY::VariableArray{1} = ReadDisk(db,"SInput/ETABY") # [Market] Beginning Year for Emission Trading Allowances (Year)
  ETADA1P::VariableArray{2} = ReadDisk(db,"SInput/ETADA1P") # [Market,Year] Price Break 1 for Releasing Allowance Reserve ($/Tonne)
  ETADA2P::VariableArray{2} = ReadDisk(db,"SInput/ETADA2P") # [Market,Year] Price Break 2 for Releasing Allowance Reserve ($/Tonne)
  ETADA3P::VariableArray{2} = ReadDisk(db,"SInput/ETADA3P") # [Market,Year] Price Break 3 for Releasing Allowance Reserve ($/Tonne)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government ($/Tonne)
  ETAFAP::VariableArray{2} = ReadDisk(db,"SInput/ETAFAP") # [Market,Year] Cost of Foreign Allowances ($/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db,"SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  ETAMax::VariableArray{2} = ReadDisk(db,"SInput/ETAMax") # [Market,Year] Maximum Price for Allowances ($/Tonne)
  ETAMin::VariableArray{2} = ReadDisk(db,"SInput/ETAMin") # [Market,Year] Minimum Price for Allowances ($/Tonne)
  ETAPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate, 2=Old Method, 0=Exogenous)
  ExYear::VariableArray{1} = ReadDisk(db,"SInput/ExYear") # [Market] Year to Define Existing Plants (Year)
  FacSw::VariableArray{1} = ReadDisk(db,"SInput/FacSw") # [Market] Facility Level Intensity Target Switch (1=Facility Target)
  FBuyFr::VariableArray{2} = ReadDisk(db,"SInput/FBuyFr") # [Market,Year] Fraction of Allowances Withdrawn or Bought (Tonnes/Tonnes)
  FBuyFrArea::VariableArray{2} = ReadDisk(db,"SInput/FBuyFrArea") # [Area,Year] Fraction of Allowances Withdrawn or Bought (Tonnes/Tonnes)
  FInvRev::VariableArray{2} = ReadDisk(db,"SOutput/FInvRev") # [Market,Year] Federal (Domestic) Permits Inventory (M$)
  FSeFr1::VariableArray{1} = ReadDisk(db,"SInput/FSeFr1") # [Market] Price 1 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  FSeFr2::VariableArray{1} = ReadDisk(db,"SInput/FSeFr2") # [Market] Price 2 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  FSeFr3::VariableArray{1} = ReadDisk(db,"SInput/FSeFr3") # [Market] Price 3 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  GPEUSw::VariableArray{1} = ReadDisk(db,"SInput/GPEUSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous)
  GPGPrSw::VariableArray{2} = ReadDisk(db,"SInput/GPGPrSw") # [Market,Year] Gas Production Intensity based Gratis Permits (2=Intensity)
  GPNGSw::VariableArray{2} = ReadDisk(db,"SInput/GPNGSw") # [Market,Year] Gratis Permit Allocation Switch for Gas Distribution
  GPOilSw::VariableArray{2} = ReadDisk(db,"SInput/GPOilSw") # [Market,Year] Gratis Permit Allocation Switch for Gas Distribution
  GPOPrSw::VariableArray{2} = ReadDisk(db,"SInput/GPOPrSw") # [Market,Year] Oil Production Intensity based Gratis Permits (2=Intensity)
  GracePd::VariableArray{1} = ReadDisk(db,"SInput/GracePd") # [Market] Grace Period for New Facilites (Years)
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous)
  GRefSwitch::VariableArray{1} = ReadDisk(db,"EInput/GRefSwitch") # [Year] Gratis Permits Refunded in Retail Prices Switch (1=Yes)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits, 2=Domestic Permits)
  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # [Year] Maximum Number of Iterations (Number)
  OffA0::VariableArray{3} = ReadDisk(db,"SInput/OffA0") # [Market,Poll,Year] A Term in Offset Reduction Curve (CN$2000)
  OffB0::VariableArray{3} = ReadDisk(db,"SInput/OffB0") # [Market,Poll,Year] B Term in Offset Reduction Curve (CN$2000)
  OffC0::VariableArray{3} = ReadDisk(db,"SInput/OffC0") # [Market,Poll,Year] C Term in Offset Reduction Curve (CN$2000)
  OffMktFr::VariableArray{4} = ReadDisk(db,"SInput/OffMktFr") # [ECC,Area,Market,Year] Fraction of Offsets allocated to each Market (Tonne/Tonne)
  OffNew::VariableArray{4} = ReadDisk(db,"EGInput/OffNew") # [Plant,Poll,Area,Year] Offset Permits for New Plants (Tonnes/TBtu)
  OverLimit::VariableArray{2} = ReadDisk(db,"SInput/OverLimit") # [Market,Year] Overage Limit as a Fraction (Tonne/Tonne)
  PAucSw::VariableArray{1} = ReadDisk(db,"SInput/PAucSw") # [Market] Switch to Auction Permits (1=Auction)
  PBnkSw::VariableArray{2} = ReadDisk(db,"SInput/PBnkSw") # [Market,Year] Banking Switch (1=Endo Prices, 2=Exog Prices)
  PCovMap::VariableArray{5} = ReadDisk(db,"SInput/PCovMap") # [FuelEP,ECC,PCov,Area,Year] Pollution Coverage Map (1=Mapped)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PCost::VariableArray{4} = ReadDisk(db,"SOutput/PCost") # [ECC,Poll,Area,Year] Permit Cost (Real $/Tonnes)
  PIAT::VariableArray{2} = ReadDisk(db,"SInput/PIAT") # [ECC,Poll] Pollution Inventory Averaging Time (Years)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PolCovRef::VariableArray{5} = ReadDisk(db,"SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  xPolImports::VariableArray{3} = ReadDisk(db,"SInput/xPolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  xPolTot::VariableArray{5} = ReadDisk(db,"SInput/xPolTot") # [ECC,Poll,PCov,Area,Year] Historical Pollution (Tonnes/Yr)
  RePriceSwitch::VariableArray{3} = ReadDisk(db,"MEInput/RePriceSwitch") # [Offset,Area,Year] Reduction Emission Price Switch (1=Default)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCoverage::VariableArray{3} = ReadDisk(db,"EGInput/UnCoverage") # [Unit,Poll,Year] Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnEGARef::VariableArray{2} = ReadDisk(db,"EGOutput/UnEGA") # [Unit,Year] Generation in Reference Case (GWh) 
  UnF1::Array{String} = ReadDisk(db,"EGInput/UnF1") # [Unit] Fuel Source 1
  UnFacility::Array{String} = ReadDisk(db,"EGInput/UnFacility") # [Unit] Facility Name
  UnGCRef::VariableArray{2} = ReadDisk(db,"EGOutput/UnGC") # [Unit,Year] Generating Capacity in Reference Case (GWh) 
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOffsets::VariableArray{3} = ReadDisk(db,"EGInput/UnOffsets") # [Unit,Poll,Year] Offsets (Tonnes/GWh) 
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPolRef::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution in Reference Case (Tonnes) 
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xFSell::VariableArray{2} = ReadDisk(db,"SInput/xFSell") # [Market,Year] Exogenous Federal Permits Sold (Tonnes/Yr)
  xGoalPol::VariableArray{2} = ReadDisk(db,"SInput/xGoalPol") # [Market,Year] Pollution Goal (Tonnes eCO2/Yr)
  xGPNew::VariableArray{5} = ReadDisk(db,"EGInput/xGPNew") # [FuelEP,Plant,Poll,Area,Year] Gratis Permits for New Plants (kg/MWh)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] US Inflation Index ($/$)
  xISell::VariableArray{2} = ReadDisk(db,"SInput/xISell") # [Market,Year] Exogenous International Permits Sold (Tonnes/Yr)
  xPAuction::VariableArray{2} = ReadDisk(db,"SInput/xPAuction") # [Market,Year] Permits Available for Auction (Tonnes/Yr)
  xPGratis::VariableArray{5} = ReadDisk(db,"SInput/xPGratis") # [ECC,Poll,PCov,Area,Year] Exogenous Gratis Permits (Tonnes/Yr)
  xPolCap::VariableArray{5} = ReadDisk(db,"SInput/xPolCap") # [ECC,Poll,PCov,Area,Year] Exogenous Emissions Cap (Tonnes/Yr)
  xUnGP::VariableArray{4} = ReadDisk(db,"EGInput/xUnGP") # [Unit,FuelEP,Poll,Year] Unit Intensity Target or Gratis Permits (kg/MWh)

  #
  # Scratch Variables
  #
  AllowRates::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Allocated Allowance Rates for Narrow Scope (Tonne/Tonne)
  ECCoverage::VariableArray{4} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Year)) # [ECC,Poll,PCov,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  EThreshold::VariableArray{4} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Year)) # [ECC,Poll,PCov,Year] Sectoral Coverage Before Gratis Permits (1=Covered)
  # FacCounter    'Number of Facilities with Units Covered (Count)'
  # FacName::VariableArray{1} = zeros(Float32,length(Facility)) # [Facility] Electric Generation Facility Name
  # FacPolMax::VariableArray{1} = zeros(Float32,length(Facility)) # [Facility] Maximum GHG Emissions (eCO2 Tonnes/Yr)
  GoalECC::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Emission Reduction Goal (Tonne/Tonne)
  PGFrac::VariableArray{5} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Area),length(Year)) # [ECC,Poll,PCov,Area,Year] Gratis Permit Fraction (Tonnes/Tonnes)
  PolCap::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Emissions Cap (Tonnes eCO2/Yr)
  PolCovered::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Covered Emissions (Tonnes eCO2/Yr)
  PolTotMar::VariableArray{2} = zeros(Float32,length(Poll),length(PCov)) # [Poll,PCov] Marginal Emissions (Tonnes/Yr)
  Ratio::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ratio of Published versus Calculated Caps (Tonnes/Tonnes)
  UnGCOffset::VariableArray{2} = zeros(Float32,length(Unit),length(Year)) # [Unit,Year] Capacity Eligible for Offsets (MW)
  UnGCOnLine::VariableArray{2} = zeros(Float32,length(Unit),length(Year)) # [Unit,Year] Capacity Coming OnLine (MW)
  UnPGratis::VariableArray{3} = zeros(Float32,length(Unit),length(Poll),length(Year)) # [Unit,Poll,Year] Gratis Permits (Tonnes/Yr)
  UnPolMax::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit] Maximum GHG Emissions (eCO2 Tonnes/Yr)
  # YrBase   'Baseline Year Pointer for New Units (Year)'
  # YrCount  'Year Counter for New Units (Year)'
  # YrFuture 'Year after Phase In Period Pointer for New Units (Year)'
  # YrPhaseIn     'Phase In Year Pointer for New Units (Year)'
end

#
########################
#
function GetUnitSets(data,unit)
  (; Area,ECC,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant,UnSector) = data
    
  if UnPlant[unit] !== ""
    genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    UnitValid = true
  else
    genco = 1
    plant = 1
    node = 1
    area = 1
    ecc = 1
    UnitValid = false
  end
  return genco,plant,node,area,ecc,UnitValid
end

#
########################
#
function DefaultSets(data)
  (;market,Current) = data
  (;AreaMarket,ECCs,PCovMarket,PollMarket) = data
  areas = findall(AreaMarket[:,market,Final] .== 1)
  eccs = ECCs 
  pcovs = findall(PCovMarket[:,market,Final] .== 1) 
  polls = findall(PollMarket[:,market,Final] .== 1) 
  years = collect(Current:Final)
  return areas,eccs,pcovs,polls,years
end

#
########################
#
function GetScope(data,year)
  (;market) = data
  (;AreaMarket,ECCMarket,PCovMarket,PollMarket) = data
  areas = findall(AreaMarket[:,market,year] .== 1)
  eccs =  findall( ECCMarket[:,market,year] .== 1)    
  pcovs = findall(PCovMarket[:,market,year] .== 1) 
  polls = findall(PollMarket[:,market,year] .== 1) 
  return areas,eccs,pcovs,polls
end

#
########################
#
function GetBroadScope(data)
  (;Current) = data 
  year = Yr(2017)
  areas,eccs,pcovs,polls = GetScope(data,year) 
  years = collect(Current:Final)
  return areas,eccs,pcovs,polls,years
end

#
########################
#
function GetNarrowScope(data)
  (;Current) = data 
  year = Yr(2013)
  areas,eccs,pcovs,polls = GetScope(data,year) 
  years = collect(Current:Final)
  return areas,eccs,pcovs,polls,years
end

#
########################
#
function GetMarketScope(data)
  (;Current) = data
  year = Yr(2020)
  areas,eccs,pcovs,polls = GetScope(data,year) 
  years = collect(Current:Final)
  return areas,eccs,pcovs,polls,years
end

function SetUnitCoverage(data,uncode,uncoverage,polls,years)
  (; UnCode,UnCoverage) = data

  units = findall(UnCode[:] .== uncode)
  if !isempty(units)
    for year in years, poll in polls, unit in units    
      UnCoverage[unit,poll,year] = uncoverage
    end
  end
end
  
  

#
########################
#
function MarketWCI(db)
  data = EControl(; db)
  (;market,Current) = data  
  (;Area,AreaKey,Areas,ECC,ECCs) = data
  (;Nation,Offset,PCov,PCovs) = data
  (;Plants,Poll,Polls) = data
  (;Years,Yrv) = data
  (;AreaMarket,CapTrade,CBSw,CoverNew,Current,ECCMarket,ECoverage) = data
  (;ElecSw,Enforce,ETABY,ETADA1P,ETADA2P,ETADA3P,ETADAP,ETAFAP,ETAIncr,ETAMax) = data
  (;ETAMin,ETAPr,ETRSw,ExYear,FacSw,FBuyFr,FBuyFrArea,FInvRev,FSeFr1,FSeFr2) = data
  (;FSeFr3,GPEUSw,GPGPrSw,GPNGSw,GPOilSw,GPOPrSw,GracePd,GratSw,GRefSwitch) = data
  (;ISaleSw,MaxIter,OffA0,OffB0,OffC0,OffMktFr,OverLimit,PAucSw,PBnkSw) = data
  (;PCovMarket,PCost,PIAT,PolConv,PolCovRef,PollMarket,xPolImports,xPolTot,RePriceSwitch,UnArea) = data
  (;UnCoverage) = data
  (;xETAPr,xExchangeRate,xFSell,xGoalPol,xInflationNation,xISell) = data
  (;xPAuction,xPGratis,xPolCap) = data
  (;AllowRates) = data
  (;PolCap,PolCovered) = data


  #
  ########################
  #
  # Market Timing
  #
  # First year caps are enforced
  #
  Enforce[market] = Current+ITime-1
  Prior = Current-1
  WriteDisk(db,"SInput/Enforce",Enforce)
  years = collect(Current:Final)

  #
  ########################
  #
  # Areas Covered
  #
  for year in years, area in Areas
    AreaMarket[area,market,year] = 0
  end

  areas = Select(Area,["CA","QC"])
  for year in years, area in areas
    AreaMarket[area,market,year] = 1
  end
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)

  #
  ########################
  #
  # Emissions Covered
  #
  for year in years, poll in Polls
    PollMarket[poll,market,year] = 0
  end

  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  for year in years, poll in polls
    PollMarket[poll,market,year] = 1
  end
  WriteDisk(db,"SInput/PollMarket",PollMarket)

  #
  ########################
  #
  # Cover all types of emissions
  #
  for year in years, pcov in PCovs
    PCovMarket[pcov,market,year] = 0
  end

  pcovs = Select(PCov)
  for year in years, pcov in pcovs
    PCovMarket[pcov,market,year] = 1
  end
  WriteDisk(db,"SInput/PCovMarket",PCovMarket)

  #
  ########################
  #
  # Narrow Scope - starts in 2013 and continues to 2020
  #
  for year in years, ecc in ECCs
    ECCMarket[ecc,market,year] = 0
  end

  #
  # Narrow Scope
  #
  years = collect(Yr(2013):Final)
  eccs = Select(ECC,["NGDistribution","OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer","Petroleum","Rubber",
    "Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining",
    "UtilityGen","BiofuelProduction","Steam"])

  for year in years, ecc in eccs
    ECCMarket[ecc,market,year] = 1
  end
  areas,eccs,pcovs,polls,years = DefaultSets(data)

  #
  ########################
  #
  # Broad Scope
  #
  area = Select(Area,"CA")
  years = collect(Yr(2015):Final)
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential",
    "Wholesale","Retail","Warehouse","Information","Offices","Education",
    "Health","OtherCommercial",
    "StreetLighting","Construction","OnFarmFuelUse",
    "Passenger","Freight","ResidentialOffRoad","CommercialOffRoad"])              
  for year in years, ecc in eccs
    ECCMarket[ecc,market,year] = 1
  end

  #
  # Miscellaneous holds government revenues and is not covered
  #
  Miscellaneous = Select(ECC,"Miscellaneous")
  for year in years
    ECCMarket[Miscellaneous,market,year] = 0
  end
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)

  areas,eccs,pcovs,polls,years = DefaultSets(data) 
  
  #
  ########################
  #
  # GHG Market (CapTrade=5)
  #
  years = collect(Prior:Final)
  for year in years
    CapTrade[market,year] = 5
  end
  years = collect(Current:Final)
  WriteDisk(db,"SInput/CapTrade",CapTrade)

  #
  # The market for permits does not generate revenues for the
  # government (CBSw=0.0)
  #
  for year in years
    CBSw[market,year] = 0.0
  end
  WriteDisk(db,"SInput/CBSw",CBSw)

  #
  # Electricity Emissions are not allocated to each Sector (ElecSw=0)
  #
  for year in years, area in areas, poll in polls
    ElecSw[poll,area,year]=0
  end
  WriteDisk(db,"SInput/ElecSw",ElecSw)
  
  #
  # The market starts (ETABY) the same year when the market
  # is enforced (Enforce).
  # 
  ETABY[market] = Enforce[market]
  WriteDisk(db,"SInput/ETABY",ETABY)

  #
  # Price Breaks for Releasing Allowance Reserves
  #
  US = Select(Nation,"US")
  for year in years
    ETADA1P[market,year] = 40*(1+0.05)^(Yrv[year]-Enforce[market])/xInflationNation[US,Yr(2013)]
    ETADA2P[market,year] = 45*(1+0.05)^(Yrv[year]-Enforce[market])/xInflationNation[US,Yr(2013)]                         
    ETADA3P[market,year] = 50*(1+0.05)^(Yrv[year]-Enforce[market])/xInflationNation[US,Yr(2013)] 
  end

  WriteDisk(db,"SInput/ETADA1P",ETADA1P)
  WriteDisk(db,"SInput/ETADA2P",ETADA2P)
  WriteDisk(db,"SInput/ETADA3P",ETADA3P)

  # 
  # Price change increment
  # 
  for year in years
    ETAIncr[market,year] = 0.75
  end
  WriteDisk(db, "SInput/ETAIncr", ETAIncr)

  # 
  # Fix price. Do not iterate to find price (ETRSw=0).
  # 
  ETRSw[market] = 0
  WriteDisk(db, "SInput/ETRSw", ETRSw)
  
  #
  # The year used to define "existing" units is set to a high
  # values (ExYear=2200) to shut off this part of code.
  #
  ExYear[market] = 2200
  WriteDisk(db,"SInput/ExYear",ExYear)
  
  #
  # This is not a facility level intensity target
  #
  FacSw[market] = 0
  WriteDisk(db,"SInput/FacSw",FacSw)

  #
  # Fraction of Allowances removed from market for Allowance Reserve
  #
  for year in years
    FBuyFr[market,year] = 0.0
  end   
  
  for area in areas
    FBuyFrArea[area,Yr(2013)]=0.00  
    FBuyFrArea[area,Yr(2014)]=0.00
    FBuyFrArea[area,Yr(2015)]=0.00    
    FBuyFrArea[area,Yr(2016)]=0.00
    FBuyFrArea[area,Yr(2017)]=0.00
    FBuyFrArea[area,Yr(2018)]=0.00
    FBuyFrArea[area,Yr(2019)]=0.00    
    FBuyFrArea[area,Yr(2020)]=0.00
    years = collect(Yr(2021):Final)
    for year in years
      FBuyFrArea[area,year]=0.00
    end
  end
  
  WriteDisk(db,"SInput/FBuyFr",FBuyFr)
  WriteDisk(db,"SInput/FBuyFrArea",FBuyFrArea)  

  areas,eccs,pcovs,polls,years = DefaultSets(data)

  #
  # Technology Fund Revenues are added to Government 
  # Revenues (FInvRev=-99)
  #
  for year in Years
    FInvRev[market,year] = -99
  end
  WriteDisk(db, "SOutput/FInvRev", FInvRev)
  
  #
  # Fraction of Allowance Reserve Released at each Price Break
  #
  FSeFr1[market] = 0.333
  FSeFr2[market] = 0.666
  FSeFr3[market] = 1.000
  WriteDisk(db, "SInput/FSeFr1", FSeFr1)
  WriteDisk(db, "SInput/FSeFr2", FSeFr2)
  WriteDisk(db, "SInput/FSeFr3", FSeFr3)

  # 
  # Electric Utility Gratis Permits are exogenous (GPEUSw=3)
  # 
  GPEUSw[market] = 3
  WriteDisk(db, "SInput/GPEUSw", GPEUSw)

  #
  # Gas Production Gratis Permits are Intensity based (2=Intensity)
  #
  for year in years
    GPGPrSw[market,year] = 1
  end
  WriteDisk(db, "SInput/GPGPrSw", GPGPrSw)
  
  #
  # Natural Gas Distributors do not need to purchase allowances for 
  # the Natural Gas which they sell (GPNGSw=0)
  #
  for year in years
    GPNGSw[market,year] = 0
  end
  WriteDisk(db, "SInput/GPNGSw", GPNGSw)  
  
  #
  # Refineries do not need to purchase allowances for the RPP(Oil)
  # which they sell (GPOilSw=0)
  #
  for year in years
    GPOilSw[market,year] = 0
  end
  WriteDisk(db, "SInput/GPOilSw", GPOilSw)
  
  #
  # Oil Production Gratis Permits are not Intensity Based (1=Not Intensity)
  #
  for year in years
    GPOPrSw[market,year] = 1
  end
  WriteDisk(db, "SInput/GPOPrSw", GPOPrSw)
  
  #
  # Endogenous electric unit grace period is not used (GracePd=0)
  #
  GracePd[market] = 0
  WriteDisk(db, "SInput/GracePd", GracePd)
  
  #
  # Gratis Permits are exogenous (GratSw=0)
  #
  GratSw[market] = 0
  WriteDisk(db,"SInput/GratSw",GratSw)

  #
  # Allocated Allowances are used to reduce electricity prices
  #
  for year in years
    GRefSwitch[year] = 1
  end
  WriteDisk(db,"EInput/GRefSwitch",GRefSwitch)

  #
  # Maximum Number of Iterations
  #
  for year in years
    MaxIter[year] = max(MaxIter[year],1)
  end
  WriteDisk(db,"SInput/MaxIter",MaxIter)
  
  #
  # Offsets come from Residential, Commercial, and Animal Production
  #
  for year in years, area in areas, ecc in eccs
    OffMktFr[ecc,area,market,year] = 0.0
  end
  
  area = Select(Area,"QC")
  offset = Select(Offset,"AD")
  for year in years
    RePriceSwitch[offset,area,year] = 2
  end
  
  eccs = Select(ECC,["AnimalProduction","SolidWaste"])
  for year in years, ecc in eccs
    OffMktFr[ecc,area,market,year] = 1.0
  end

  WriteDisk(db,"SInput/OffMktFr",OffMktFr)
  WriteDisk(db,"MEInput/RePriceSwitch",RePriceSwitch)
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)

  #
  # Overage Limit (Fraction)
  #
  for year in years
    OverLimit[market,year] = 0.005
  end
  WriteDisk(db, "SInput/OverLimit", OverLimit)

  #
  # Gratis permits are not auctioned (PAucSw=0).
  #
  PAucSw[market] = 0
  WriteDisk(db, "SInput/PAucSw", PAucSw)

  #
  # Banking for Allowances
  #
  for year in years  
    PBnkSw[market,year] = 1
  end
  WriteDisk(db, "SInput/PBnkSw", PBnkSw)

  #
  # Permit Inventory Time
  #
  for ecc in eccs, poll in polls
    PIAT[ecc,poll] = 5
  end
  WriteDisk(db, "SInput/PIAT", PIAT)

  #
  #################################################
  #
  # Emission Coverage
  
  #
  # Zero out GHG Coverages
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 0
  end 
  
  #
  ########################
  #
  # California Narrow Scope
  #
  area = Select(Area,"CA")
  years = collect(Yr(2013):Final)
  eccs = Select(ECC,["OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer","Petroleum","Rubber",
    "Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining",
    "UtilityGen","BiofuelProduction","Steam"])           
                   
  #
  # Add HFC,SF6,PFC to covered emissions. Per Jeff. 09/27/23 R.Levesque
  #
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  pcovs = Select(PCov,["Energy","NaturalGas","NonCombustion","Process","Venting","Flaring"]) 
  
  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end 
  
  #
  # California electric imports not covered (0.25 of electric generation emissions)
  # 10/27/23 R.Levesque
  #
  eccs = Select(ECC,"UtilityGen")
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  pcovs = Select(PCov,["Energy","NaturalGas","NonCombustion","Process","Venting","Flaring"]) 
  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 0.25
  end 
  # TODo Promula - remove Select Poll*
  polls = Polls
  
  
  #
  # Small factories are not capped in the Narrow Scope
  #           
  eccs = Select(ECC,["OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer",
    "Rubber",
    "Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining",
    "BiofuelProduction"])   
    
   pcovs = Select(PCov,["Energy","NaturalGas","NonCombustion","Process","Venting","Flaring"])    


  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 0.825
  end 
  
  eccs = Select(ECC,"Cement")
  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 0.901
  end    
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # Broad Scope for California 
  #
  area = Select(Area,"CA")
  years = collect(Yr(2015):Final)          
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential",
    "Wholesale","Retail","Warehouse","Information","Offices","Education",
    "Health","OtherCommercial","NGDistribution",
    "StreetLighting","Construction","OnFarmFuelUse",
    "Passenger","Freight","ResidentialOffRoad","CommercialOffRoad"])  
    
  pcovs = Select(PCov,["Energy","Oil","NaturalGas"])
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])  

  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end 
  
  #
  # Natural Gas is covered for all industries
  #
  eccs = Select(ECC,["OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer","Petroleum","Rubber",
    "Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining",
    "BiofuelProduction"])  
  pcovs = Select(PCov,"NaturalGas")
  polls = Select(Poll,["CO2","CH4","N2O"])

  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end 
  
  #
  # Tractors are not covered in Agriculture (Fraction of Off-Road Demand = 0.28 in 2018)
  # 10/25/23 R.Levesque
  #
  pcovs = Select(PCov,["Energy","Oil"])
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  eccs = Select(ECC,"OnFarmFuelUse")

  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0-0.28
  end   

  #
  # Off-Road is covered for all other industries
  #
  eccs = Select(ECC,["OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer","Petroleum","Rubber",
    "Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining",
    "UtilityGen","BiofuelProduction","Steam"])                             
  pcovs = Select(PCov,"Oil")
  polls = Select(Poll,["CO2","CH4","N2O"])
  
  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end 
 
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # Narrow Scope for Quebec
  #
  area = Select(Area,"QC")
  years = collect(Yr(2013):Final)

  eccs = Select(ECC,["NGDistribution","OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer","Petroleum","Rubber",
    "Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining",
    "UtilityGen","BiofuelProduction","Steam"])   
              
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  pcovs = Select(PCov,["Energy","NaturalGas","NonCombustion","Process","Venting","Flaring"]) 
  
  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end 
  
  years = collect(Yr(2015):Final)
  pcovs = Select(PCov,"Oil")
  polls = Select(Poll,["CO2","CH4","N2O"])

  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end 
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # Broad Scope for Quebec
  #
  area = Select(Area,"QC")
  years = collect(Yr(2015):Final)
  
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential",
    "Wholesale","Retail","Warehouse","Information","Offices","Education",
    "Health","OtherCommercial",
    "StreetLighting","Construction","OnFarmFuelUse",
    "Passenger","Freight","ResidentialOffRoad","CommercialOffRoad"])               
  polls = Select(Poll,["CO2","CH4","N2O"])           
  pcovs = Select(PCov,["Energy","Oil","NaturalGas"])
             
  for year in years, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end 
  
  WriteDisk(db,"SInput/ECoverage",ECoverage)
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  #################################################
  #
  # Electric Generation Unit Coverage
  
  #
  # All existing units
  #
  unitsCA = findall(UnArea[:] .== "CA")
  unitsQC = findall(UnArea[:] .== "QC")
  units = union(unitsCA,unitsQC)
  for year in years, poll in polls, unit in units    
    UnCoverage[unit,poll,year] = 1.0
  end
  areas,eccs,pcovs,polls,years = DefaultSets(data)

  #
  # California "Specified" units - units outside California whose 
  # emissions are counted as part of the Californis emissions
  #
  # Four Corners Unit 4 and 5
  #
  SetUnitCoverage(data,"Mtn_2442_4",0.480,polls,years)
  SetUnitCoverage(data,"Mtn_2442_5",0.480,polls,years)

  #
  # Hoover Dam in Nevada
  #
  SetUnitCoverage(data,"Mtn_154_N1",0.550,polls,years)
  SetUnitCoverage(data,"Mtn_154_N2",0.550,polls,years)
  SetUnitCoverage(data,"Mtn_154_N3",0.550,polls,years)
  SetUnitCoverage(data,"Mtn_154_N4",0.550,polls,years)
  SetUnitCoverage(data,"Mtn_154_N5",0.550,polls,years)
  SetUnitCoverage(data,"Mtn_154_N6",0.550,polls,years)
  SetUnitCoverage(data,"Mtn_154_N7",0.550,polls,years)
  SetUnitCoverage(data,"Mtn_154_N8",0.550,polls,years)        

  #
  # Intermountain
  #
  SetUnitCoverage(data,"Mtn_6481_1",0.789,polls,years)
  SetUnitCoverage(data,"Mtn_6481_2",0.789,polls,years)
  
  #
  # Navajo
  #
  SetUnitCoverage(data,"Mtn_4941_NAV1",0.212,polls,years)
  SetUnitCoverage(data,"Mtn_4941_NAV2",0.212,polls,years)        
  SetUnitCoverage(data,"Mtn_4941_NAV3",0.212,polls,years)          

  #
  # Palo Verde
  #
  SetUnitCoverage(data,"Mtn_6008_1",0.274,polls,years)
  SetUnitCoverage(data,"Mtn_6008_2",0.274,polls,years)
  SetUnitCoverage(data,"Mtn_6008_3",0.274,polls,years)           

  #
  # Reid Gardner expires
  #
  SetUnitCoverage(data,"Mtn_2324_4",0.00,polls,years)   

  #
  # San Juan 3
  #
  SetUnitCoverage(data,"Mtn_2451_3",0.418,polls,years)

  #
  # San Juan 4
  #
  SetUnitCoverage(data,"Mtn_2451_4",0.388,polls,years)

  #
  # Yucca (Yuma AZ) 
  #
  SetUnitCoverage(data,"Mtn_120_ST1",0.100,polls,years)

  #
  # San Onofre Nuclear Units in California
  #
  SetUnitCoverage(data,"CA_360_2",0.388,polls,years)
  SetUnitCoverage(data,"CA_360_3",0.388,polls,years)

  WriteDisk(db,"EGInput/UnCoverage",UnCoverage)
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  #
  # All new units
  #
  for year in years, area in areas, poll in polls, plant in Plants
    CoverNew[plant,poll,area,year] = 1 
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)
  
  #
  ########################
  #
  UtilityGen = Select(ECC,"UtilityGen")
  Energy = Select(PCov,"Energy")
  for year in years, area in areas, poll in polls
    xPolTot[UtilityGen,poll,Energy,area,year] = 
      xPolTot[UtilityGen,poll,Energy,area,year]+xPolImports[poll,area,year]
  end
  
  #
  # Covered Emissions
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    PolCovRef[ecc,poll,pcov,area,year] = xPolTot[ecc,poll,pcov,area,year]*
      ECoverage[ecc,poll,pcov,area,year]*PolConv[poll]
  end
  WriteDisk(db,"SInput/BaPolCov",PolCovRef)
  
  #
  #################################################
  #
  # Allowance Budgets - Emission Caps
  #
  # International Carbon Action Partnership                                               
  # ETS Detailed Information                                                
  # Last Update: 30 March 2016                                              
  # First Compliance Period (2013-2014)  2013 162.8  2014 159.7         
  # Second Compliance Period (2015-2017) 2015 394.5  2016 382.4  2017 370.4.
  # Third Compliance Period (2018-2020)  2018 358.3  2019 346.3  2020 334.2.                                              
  # https//icapcarbonaction.com/en/?option=com_etsmap&task=export&format=pdf&layout=list&systems%5B%5D=44                                           
  #
  CA = Select(Area,"CA")
  QC = Select(Area,"QC")  
  years = collect(Yr(2013):Yr(2030))
  #                    2013  2014  2015  2016  2017  2018  2019  2020  2021  2022  2023  2024  2025  2026  2027  2028  2029  2030
  PolCap[CA,years] = [162.8 159.7 394.5 382.4 370.4 358.3 346.3 334.2 320.8 307.5 294.1 280.7 267.4 254.0 240.6 227.3 213.9 200.5]
  PolCap[QC,years] = [23.20 23.20 65.30 63.20 61.10 59.00 56.90 54.70 55.30 54.00 52.80 51.60 50.30 49.10 47.80 46.60 45.40 44.10]

  for year in years, area in areas
    PolCap[area,year] = PolCap[area,year]*1e6
  end 
  
  area = Select(Area,"CA")
  years = collect(Yr(2031):Final) 
  for year in years
    PolCap[area,year] = PolCap[area,year-1]-6.7*1e6
  end 
  area = Select(Area,"QC")
  years = collect(Yr(2031):Final) 
  for year in years
    PolCap[area,year] = PolCap[area,year-1]*0.972
  end 

  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  # Emission Caps - Broad Scope - the Broad Scope must be computed
  # first since the code is designed to overwrite the Broad Scope 
  # values with the Narrow Scope values for the Narrow Scope sectors.
  # Jeff Amlin 8/17/11
  #
  areas,eccs,pcovs,polls,years = GetBroadScope(data)
  for area in areas
  
  #
  # California - Broad Scope
  #
    if AreaKey[area] == "CA"
    
      for year in years
        PolCovered[area,year]=sum(PolCovRef[ecc,poll,pcov,area,year]
          for ecc in eccs, poll in polls, pcov in pcovs) 
      end
      
      year = Yr(2015)
      for pcov in pcovs, poll in polls, ecc in eccs
        @finite_math xPolCap[ecc,poll,pcov,area,year] = 
          xPolTot[ecc,poll,pcov,area,year]*PolConv[poll]*
          ECoverage[ecc,poll,pcov,area,year]*PolCap[area,year]/PolCovered[area,year]
      end
        
      years = collect(Yr(2016):Final)        
      for year in years, pcov in pcovs, poll in polls, ecc in eccs
        @finite_math xPolCap[ecc,poll,pcov,area,year] =
                     xPolCap[ecc,poll,pcov,area,year-1]*
                     PolCap[area,year]/PolCap[area,year-1]
      end          
      years = collect(Zero:Final)
  
  #
  # Quebec - Broad Scope
  #  
    elseif AreaKey[area] == "QC"
    
      for year in years
        PolCovered[area,year]=sum(PolCovRef[ecc,poll,pcov,area,year]
          for ecc in eccs, poll in polls, pcov in pcovs) 
      end
    
      year = Yr(2015)
      for pcov in pcovs, poll in polls, ecc in eccs
        @finite_math xPolCap[ecc,poll,pcov,area,year] = 
                     xPolTot[ecc,poll,pcov,area,year]*PolConv[poll]*
                   ECoverage[ecc,poll,pcov,area,year]*
                   PolCap[area,year]/PolCovered[area,year]
      end
        
      years = collect(Yr(2016):Final)        
      for year in years, pcov in pcovs, poll in polls, ecc in eccs
        @finite_math xPolCap[ecc,poll,pcov,area,year] = 
                     xPolCap[ecc,poll,pcov,area,year-1]*
                     PolCap[area,year]/PolCap[area,year-1]
      end

      years = collect(Zero:Final)
    end
  end
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  # Emission Caps - Narrow Scope - these calculations are after the Broad
  # Scope since we want them to overwrite the Broad Scope values for the
  # Narrow Scope sectors.  Jeff Amlin 8/17/11
  #
  areas,eccs,pcovs,polls,years = GetNarrowScope(data)
  
  for area in areas
  #
  # California - Narrow Scope
  #
    if AreaKey[area] == "CA"
    
      for year in years
        PolCovered[area,year]=sum(PolCovRef[ecc,poll,pcov,area,year]
          for ecc in eccs, poll in polls, pcov in pcovs) 
      end
      
      year = Yr(2013)
      for pcov in pcovs, poll in polls, ecc in eccs
        @finite_math xPolCap[ecc,poll,pcov,area,year] = 
                     xPolTot[ecc,poll,pcov,area,year]*PolConv[poll]*
                   ECoverage[ecc,poll,pcov,area,year]*
                   PolCap[area,year]/PolCovered[area,year]
      end
        
      years = collect(Yr(2014))        
      for year in years, pcov in pcovs, poll in polls, ecc in eccs
      @finite_math xPolCap[ecc,poll,pcov,area,year] = 
                   xPolCap[ecc,poll,pcov,area,year-1]*
                   PolCap[area,year]/PolCap[area,year-1]
      end          
      years = collect(Zero:Final)
    
  #
  # Quebec - Narrow Scope
  #
      elseif AreaKey[area] == "QC"
      
        for year in years
          PolCovered[area,year]=sum(PolCovRef[ecc,poll,pcov,area,year]
            for ecc in eccs, poll in polls, pcov in pcovs) 
        end
      
        year = Yr(2013)
        for pcov in pcovs, poll in polls, ecc in eccs
          @finite_math xPolCap[ecc,poll,pcov,area,year] = 
                       xPolTot[ecc,poll,pcov,area,year]*PolConv[poll]*
                     ECoverage[ecc,poll,pcov,area,year]*
                     PolCap[area,year]/PolCovered[area,year]
        end
          
        years = collect(Yr(2014))        
        for year in years, pcov in pcovs, poll in polls, ecc in eccs
          @finite_math xPolCap[ecc,poll,pcov,area,year] = 
                       xPolCap[ecc,poll,pcov,area,year-1]*
                       PolCap[area,year]/PolCap[area,year-1]
        end
        
      years = collect(Yr(2031):Final) 
 
    end
  end
  
  WriteDisk(db,"SInput/xPolCap",xPolCap)
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # Total Allowanced Budget - Emissions Goal
  #
  for year in years
    xGoalPol[market,year] = sum(xPolCap[ecc,poll,pcov,area,year]
      for area in areas, pcov in pcovs, poll in polls, ecc in eccs)
  end
  
  WriteDisk(db,"SInput/xGoalPol",xGoalPol)

  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # Allocated Allowances
  #
  # Narrow Scope Allocated Allowances Rate
  # Source: "Key Assumptions.xlsx" from 7/13/16 email from Maxime Charbonneau
  #
  CA = Select(Area,"CA")
  QC = Select(Area,"QC")  
  years = collect(Yr(2013):Yr(2030))
  #                        2013   2014   2015   2016   2017   2018   2019   2020   2021   2022   2023   2024   2025   2026   2027   2028   2029   2030
  AllowRates[CA,years] = [0.9817 0.9643 0.9460 0.9277 0.9103 0.8920 0.8737 0.8563 0.7706 0.6850 0.5994 0.5138 0.4281 0.3425 0.2569 0.1713 0.0856 0.0000]
  AllowRates[QC,years] = [0.8181 0.7526 0.7355 0.7400 0.7775 0.7542 0.8382 0.8345 0.9275 0.9396 0.9848 0.9848 0.9848 0.9848 0.9848 0.9848 0.9848 0.9848]
  area = Select(Area,"QC")  
  years=collect(Yr(2031):Final)
  for year in years
    AllowRates[area,year]=AllowRates[area,year-1]
  end  

  areas,eccs,pcovs,polls,years = DefaultSets(data)

  #
  # Broad Scope receives no allocated allowances
  #
  areas,eccs,pcovs,polls,years = GetBroadScope(data)
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs    
    xPGratis[ecc,poll,pcov,area,year] = xPolCap[ecc,poll,pcov,area,year]*0.0000
  end
  
  #
  # Narrow Scope 
  #
  areas,eccs,pcovs,polls,years = GetNarrowScope(data)
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    xPGratis[ecc,poll,pcov,area,year] = xPolCap[ecc,poll,pcov,area,year]*AllowRates[area,year]
  end
  
  WriteDisk(db,"SInput/xPGratis",xPGratis)
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # Auctioned Allowances
  #
  # Use Broad Scope to determine Auctioned Allowances
  #
  areas,eccs,pcovs,polls,years = GetBroadScope(data)
  
  for year in years
    xPAuction[market,year] = max(xGoalPol[market,year] - 
      sum(xPGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs,
                                                poll in polls, ecc in eccs), 0)
  end
  
  WriteDisk(db,"SInput/xPAuction",xPAuction)
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # California Generic Offsets 
  #
  # Offsets are set at Offset Limit of 8% and are
  # not sensitive to prices and stored in CO2.
  #
  # Offsets=OffC0/(1+OffA0*OffPr^OffB0)
  #
  # Remove offset price impact 
  #
  areas = Select(Area,"CA")
  CO2 = Select(Poll,"CO2")
  for year in years
    OffC0[market,CO2,year] = sum(xPolCap[ecc,poll,pcov,area,year]*0.08
               for area in areas, pcov in pcovs, poll in polls, ecc in eccs)
    OffA0[market,CO2,year] =  798568
    OffA0[market,CO2,year] =  0.0
    OffB0[market,CO2,year] = -4.4580
  end

  WriteDisk(db,"SInput/OffA0",OffA0)
  WriteDisk(db,"SInput/OffB0",OffB0)
  WriteDisk(db,"SInput/OffC0",OffC0)  
    
  areas,eccs,pcovs,polls,years = DefaultSets(data)
  
  #
  ########################
  #
  # TIF and International Permits
  #
  # WCI Type Market with Allowance Reserve (ISaleSw=5)
  #
  for year in years
    ISaleSw[market,year] = 5
  end

  WriteDisk(db,"SInput/ISaleSw",ISaleSw)
  
  #
  # Domestic (TIF) Permit Price
  #
  for year in years
    ETADAP[market,year] =  500
  end
  WriteDisk(db,"SInput/ETADAP",ETADAP)
  
  #
  # Minimum Price
  #
  for year in years
    ETAMin[market,year] = 0.0
  end
  WriteDisk(db,"SInput/ETAMin",ETAMin)

  #
  # Allowances sold from Reserve are endogenous so exogenous value is zero.
  #
  for year in years
    xFSell[market,year] = 0
  end  
  WriteDisk(db,"SInput/xFSell",xFSell)
  
  #
  # Maximum Price
  #
  for year in years
    ETAMax[market,year] = 200.00/xInflationNation[US,Yr(2010)]
  end
  WriteDisk(db,"SInput/ETAMax",ETAMax)
  
  #
  # International Allowances are not available
  #
  for year in years
    xISell[market,year] = 0.0
  end
  WriteDisk(db,"SInput/xISell",xISell)
  
  #
  # Price for Foreign Allowances ($/Tonne)
  #
  for year in years
    ETAFAP[market,year] = 1000/xInflationNation[US,Yr(2010)]
  end 
  WriteDisk(db,"SInput/ETAFAP",ETAFAP)
  
  #
  # Source: 2012-2021 August Auction Price, Current Auction Settlement Price
  # California Cap-And-Trade Program, Summary Of California-Quebec Joint
  # Auction Settlement Prices And Results, Last updated August 2021
  # https://ww2.arb.ca.gov/sites/default/files/2020-08/results_summary.pdf
  #
  # Source: "An Impact Analysis of AB398 on California's Cap-and-Trade Market" from 
  # California Carbon (sent by G. Obrekht on Sept 7 2017). Scenario 5.
  # http://californiacarbon.info/wp-content/uploads/2017/07/AB398-_Impact_Analysis.pdf
  #
  years = collect(Yr(2012):Yr(2030))
  #
  # Historical - https://ww2.arb.ca.gov/sites/default/files/2020-08/results_summary.pdf
  #
  xETAPr[market,Yr(2012)] = 10.09
  xETAPr[market,Yr(2013)] = 12.22
  xETAPr[market,Yr(2014)] = 11.50
  xETAPr[market,Yr(2015)] = 12.52
  xETAPr[market,Yr(2016)] = 12.73
  xETAPr[market,Yr(2017)] = 14.75
  xETAPr[market,Yr(2018)] = 15.05
  xETAPr[market,Yr(2019)] = 17.16
  xETAPr[market,Yr(2020)] = 16.68
  xETAPr[market,Yr(2021)] = 23.69 
  #
  # WCI - Randy 9/15/23
  #
  xETAPr[market,Yr(2022)] = 36.77  
  #
  # Interpolation - Jeff Amlin 9/15/23
  #
  xETAPr[market,Yr(2023)] = 38.10
  #
  # Forecast  http://californiacarbon.info/wp-content/uploads/2017/07/AB398-_Impact_Analysis.pdf
  #
  xETAPr[market,Yr(2024)] = 39.43
  xETAPr[market,Yr(2025)] = 59.89
  xETAPr[market,Yr(2026)] = 55.77
  xETAPr[market,Yr(2027)] = 53.49
  xETAPr[market,Yr(2028)] = 62.49
  xETAPr[market,Yr(2029)] = 68.11
  xETAPr[market,Yr(2030)] = 74.14
  
  for year in years
    xETAPr[market,year] = xETAPr[market,year]/xInflationNation[US,year]
  end
  
  years = collect(Yr(2031):Final)
  for year in years
    xETAPr[market,year] = xETAPr[market,Yr(2030)]
  end
  
  years = collect(Yr(2012):Final)
  for year in years
    xETAPr[market,year] = max(xETAPr[market,year],ETAMin[market,year])
  end

  for year in Years
    ETAPr[market,year] = xETAPr[market,year]*xInflationNation[US,year]
  end

  WriteDisk(db,"SOutput/ETAPr",ETAPr)
  WriteDisk(db,"SInput/xETAPr",xETAPr)

  areas,eccs,pcovs,polls,years = GetNarrowScope(data)
  for year in years, area in areas, poll in polls, ecc in eccs
    PCost[ecc,poll,area,year] = ETAPr[market,year]/PolConv[poll]/
      xInflationNation[US,year]*xExchangeRate[area,year]
  end
  
  
  areas,eccs,pcovs,polls,years = GetBroadScope(data)
  for year in years, area in areas, poll in polls, ecc in eccs
    PCost[ecc,poll,area,year] = ETAPr[market,year]/PolConv[poll]/
      xInflationNation[US,year]*xExchangeRate[area,year]
  end
  
  WriteDisk(db,"SOutput/PCost",PCost) 
  
  areas,eccs,pcovs,polls,years = DefaultSets(data)

end

function Control(db)
  @info "WCI_Market.jl - Control"

  MarketWCI(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
  