#
# SuPollutionMarket.jl
#

module SuPollutionMarket

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime,DT
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  Yr2000 = 2000-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Iter::SetArray = ReadDisk(db,"MainDB/IterKey")
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovs::Vector{Int} = collect(Select(PCov))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year) #[Area,Market,Year]  Areas included in Market
  CapTrade::VariableArray{1} = ReadDisk(db,"SInput/CapTrade",year) #[Market,Year]  Emission Cap and Trading Switch (1=Trade, Cap Only=2)
  CBSw::VariableArray{1} = ReadDisk(db,"SInput/CBSw",year) #[Market,Year]  Market Switch (0 = CT no Auction, 1=CT with Auction, 2=Tax)
  CgFPol::VariableArray{4} = ReadDisk(db,"SOutput/CgFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Cogeneration Related Pollution (Tonnes/Yr)
  DACPolNetPrior::VariableArray{1} = ReadDisk(db,"SpOutput/DACPolNet",prior) #[Area,Year]  Net GHG Emissions from DAC Production (eCO2 Tonnes/Yr)
  DACProductionPrior::VariableArray{1} = ReadDisk(db,"SOutput/DACProduction",prior) #[Area,Year]  DAC Production (eCO2 Tonnes/Yr)
  DoneM::VariableArray{1} = ReadDisk(db,"SOutput/DoneM") #[Market]  Market Done Switch (0 = Done)
  Driver::VariableArray{2} = ReadDisk(db,"MOutput/Driver",year) #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  DriverBaseline::VariableArray{2} = ReadDisk(db,"MInput/DriverBaseline",year) #[ECC,Area,Year]  Emissions Baseline Economic Driver (Various Units/Yr)
  EAProd::VariableArray{2} = ReadDisk(db,"SOutput/EAProd",year) #[Plant,Area,Year]  Electric Utility Production (GWh/Yr)
  ECCMarket::VariableArray{2} = ReadDisk(db,"SInput/ECCMarket",year) #[ECC,Market,Year]  Economic Categories included in Market
  eCO2Price::VariableArray{1} = ReadDisk(db,"SOutput/eCO2Price",year) #[Area,Year]  Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  eCO2PriceNext::VariableArray{1} = ReadDisk(db,"SOutput/eCO2Price",next) #[Area,Year]  Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  eCO2PriceExo::VariableArray{1} = ReadDisk(db,"SInput/eCO2PriceExo",year) #[Area,Year]  Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ECoverage::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) #[ECC,Poll,PCov,Area,Year]  Emissions Permit Coverage (Tonnes/Tonnes)
  EIBaseline::VariableArray{4} = ReadDisk(db,"SInput/EIBaseline",year) #[ECC,Poll,PCov,Area,Year]  Emission Intensity Baseline (Tonnes/Driver)
  ElecSw::VariableArray{2} = ReadDisk(db,"SInput/ElecSw",year) #[Poll,Area,Year]  Electricity Emission Allocation Switch
  Emissions::VariableArray{1} = ReadDisk(db,"SOutput/Emissions",year) #[Market,Year]  Actual Emissions (Tonnes)
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") #[Market]  First Year Market Limits are Enforced (Year)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Pollution including Cogeneration (Tonnes/Yr)
  EuPol::VariableArray{3} = ReadDisk(db,"SOutput/EuPol",year) #[ECC,Poll,Area,Year]  Enduse Energy Related Pollution (Tonnes/Yr)
  EORCredits::VariableArray{3} = ReadDisk(db,"SOutput/EORCredits",year) #[ECC,Poll,Area,Year]  Emissions Credits for using CO2 for EOR (Tonnes/Yr)
  Epsilon::Float32 = ReadDisk(db,"MainDB/Epsilon")[1] #[tv] A Very Small Number
  ETABank::VariableArray{1} = ReadDisk(db,"SOutput/ETABank",year) #[Market,Year]  Maximum Price when Permits are Banked (US$/Tonne)
  ETABY::VariableArray{1} = ReadDisk(db,"SInput/ETABY") #[Market]  Beginning Year for Emission Trading Allowances (Year)
  ETADA1P::VariableArray{1} = ReadDisk(db,"SInput/ETADA1P",year) #[Market,Year]  Price Break 1 for Releasing Allowance Reserve (Real US$/Tonne)
  ETADA2P::VariableArray{1} = ReadDisk(db,"SInput/ETADA2P",year) #[Market,Year]  Price Break 2 for Releasing Allowance Reserve (Real US$/Tonne)
  ETADA3P::VariableArray{1} = ReadDisk(db,"SInput/ETADA3P",year) #[Market,Year]  Price Break 3 for Releasing Allowance Reserve (Real US$/Tonne)
  ETADAP::VariableArray{1} = ReadDisk(db,"SInput/ETADAP",year) #[Market,Year]  Cost of Domestic Allowances from Government (Real US$/Tonne)
  ETAFAP::VariableArray{1} = ReadDisk(db,"SInput/ETAFAP",year) #[Market,Year]  Cost of Foreign Allowances (US$/Tonne)
  ETAIncr::VariableArray{1} = ReadDisk(db,"SInput/ETAIncr",year) #[Market,Year]  Increment in Allowance Price if Goal is not met ($/$)
  ETAMax::VariableArray{1} = ReadDisk(db,"SInput/ETAMax",year) #[Market,Year]  Maximum Price for Allowances (Real US$/Tonne)
  ETAMin::VariableArray{1} = ReadDisk(db,"SInput/ETAMin",year) #[Market,Year]  Minimum Price for Allowances (Real US$/Tonne)
  ETAPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAPr",year) #[Market,Year]  Cost of Emission Trading Allowances (US$/Tonne)
  ETAPrPrior::VariableArray{1} = ReadDisk(db,"SOutput/ETAPr",prior) #[Market,Prior]  Cost of Emission Trading Allowances (US$/Tonne)
  ETAPrNext::VariableArray{1} = ReadDisk(db,"SOutput/ETAPr",next) #[Market,Prior]  Cost of Emission Trading Allowances (US$/Tonne)
  ETARedeem::VariableArray{1} = ReadDisk(db,"SOutput/ETARedeem",year) #[Market,Year]  Minimum Price when Permits are Sold from Inventory (US$/Tonne)
  ETAvPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAvPr",year) #[Market,Year]  Average Cost of Emission Trading Allowances (US$/Tonne)
  ETAvPrNext::VariableArray{1} = ReadDisk(db,"SOutput/ETAvPr",next) #[Market,Year]  Average Cost of Emission Trading Allowances (US$/Tonne)
  ETR::VariableArray{2} = ReadDisk(db,"SOutput/ETR",year) #[Market,Iter,Year]  Permit Costs (US$/Tonne)
  ETRNext::VariableArray{2} = ReadDisk(db,"SOutput/ETR",next) #[Market,Iter,Next]  Permit Costs (US$/Tonne)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") #[Market]  Permit Cost Switch (1 = Iterate Credits,2=Iterate Emissions,0 = Exogenous)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (tBtu)
  ExchangeRate::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",year) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateNext::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",next) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateCN2000::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateNation",Yr2000) #[Nation,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  FBuy::VariableArray{1} = ReadDisk(db,"SOutput/FBuy",year) #[Market,Year]  Allowances Withdrawn or Bought  (Tonnes/Yr)
  FBuyFr::VariableArray{1} = ReadDisk(db,"SInput/FBuyFr",year) #[Market,Year]  Fraction of Allowances Withdrawn or Bought (Tonnes/Tonnes)
  FBuyFrArea::VariableArray{1} = ReadDisk(db,"SInput/FBuyFrArea",year) #[Area,Year]  Fraction of Allowances Withdrawn or Bought (Tonnes/Tonnes)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FInventory::VariableArray{1} = ReadDisk(db,"SOutput/FInventory",year) #[Market,Year]  Federal (Domestic) Permits Inventory (Tonnes)
  FInventoryPrior::VariableArray{1} = ReadDisk(db,"SOutput/FInventory",prior) #[Market,Prior]  Federal (Domestic) Permits Inventory (Tonnes)
  FInvRev::VariableArray{1} = ReadDisk(db,"SOutput/FInvRev",year) #[Market,Year]  Federal (Domestic) Permits Inventory (US$ Millions)
  FInvRevPrior::VariableArray{1} = ReadDisk(db,"SOutput/FInvRev",prior) #[Market,Prior]  Federal (Domestic) Permits Inventory (US$ Millions)
  FlPol::VariableArray{3} = ReadDisk(db,"SOutput/FlPol",year) #[ECC,Poll,Area,Year]  Fugitive Flaring Emissions (Tonnes/Yr)
  FPCredits::VariableArray{1} = ReadDisk(db,"SOutput/FPCredits",year) #[Market,Year]  Foreign Pollution Credits or Federal Shortfall (Tonnes/Yr)
  FSeFr1::VariableArray{1} = ReadDisk(db,"SInput/FSeFr1") #[Market]  Price 1 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  FSeFr2::VariableArray{1} = ReadDisk(db,"SInput/FSeFr2") #[Market]  Price 2 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  FSeFr3::VariableArray{1} = ReadDisk(db,"SInput/FSeFr3") #[Market]  Price 3 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  FSell::VariableArray{1} = ReadDisk(db,"SOutput/FSell",year) #[Market,Year]  Federal (Domestic) Permits Sold (Tonnes/Yr)
  FuPol::VariableArray{3} = ReadDisk(db,"SOutput/FuPol",year) #[ECC,Poll,Area,Year]  Other Fugitive Emissions (Tonnes/Yr)
  GoalPol::VariableArray{1} = ReadDisk(db,"SOutput/GoalPol",year) #[Market,Year]  Pollution Goal (Tonnes/Yr)
  GoalPolSw::VariableArray{1} = ReadDisk(db,"SInput/GoalPolSw") #[Market]  Pollution Goal Switch (1=Gratis Permits, 0 = Exogenous)
  GPNGSw::VariableArray{1} = ReadDisk(db,"SInput/GPNGSw",year) #[Market,Year]  Gratis Permit Allocation Switch for Gas Distribution
  GPOilSw::VariableArray{1} = ReadDisk(db,"SInput/GPOilSw",year) #[Market,Year]  Gratis Permit Allocation Switch for Gas Distribution
  GPol::VariableArray{2} = ReadDisk(db,"SOutput/GPol",year) #[Market,Iter,Year]  Market Emissions Goal (Tonnes/Yr)
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") #[Market]  Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0 = Exogenous)
  GrossPol::VariableArray{3} = ReadDisk(db,"SOutput/GrossPol",year) #[ECC,Poll,Area,Year]  Gross Pollution - before any policies (Tonnes/Yr)
  GrossPolPrior::VariableArray{3} = ReadDisk(db,"SOutput/GrossPol",prior) #[ECC,Poll,Area,Prior]  Gross Pollution - before any policies in Prior Year (Tonnes/Yr)
  GrossTot::VariableArray{1} = ReadDisk(db,"SOutput/GrossTot",year) #[Market,Year]  Gross Pollution (Tonnes/Yr)
  InflationUS::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) #Inflation Index ($/$)
  InflationUS2000::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",Yr2000) #[PointerUS,Year]  Inflation Index ($/$)
  InflationUSNext::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",next) #Inflation Index ($/$)
  IR::VariableArray{3} = ReadDisk(db,"SOutput/IR",year) #[ECC,PCov,Area,Year]  Internal Reductions (eCO2 Tonnes)
  ISaleSw::VariableArray{1} = ReadDisk(db,"SInput/ISaleSw",year) #[Market,Year]  Switch for Unlimited Sales (1 = International Permits, 2 = Domestic Permits)
  ISell::VariableArray{1} = ReadDisk(db,"SOutput/ISell",year) #[Market,Year]  International Permits Sold (Tonnes/Yr)
  MEReduce::VariableArray{3} = ReadDisk(db,"SOutput/MEReduce",year) #[ECC,Poll,Area,Year]  Reductions from Process Emssions (Tonnes/Yr)
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution (Tonnes/Yr)
  MktPol::VariableArray{1} = ReadDisk(db,"SOutput/MktPol",year) #[Market,Year]  Pollution Subject to Limits (Tonnes/Yr)
  MPol::VariableArray{2} = ReadDisk(db,"SOutput/MPol",year) #[Market,Iter,Year]  Market Covered Emissions (Tonnes/Yr)
  NcPol::VariableArray{3} = ReadDisk(db,"SOutput/NcPol",year) #[ECC,Poll,Area,Year]  Non Combustion Related Pollution (Tonnes/Yr)
  OBAFraction::VariableArray{2} = ReadDisk(db,"SInput/OBAFraction",year) #[ECC,Area,Year]  Output-Based Allocation Fraction (Tonne/Tonne)
  OffAlloc::VariableArray{3} = ReadDisk(db,"SOutput/OffAlloc",year) #[ECC,PCov,Area,Year]  Offsets allocated to Sectors (eCO2 Tonnes)
  OffA0::VariableArray{2} = ReadDisk(db,"SInput/OffA0",year) #[Market,Poll,Year]  A Term in Offset Reduction Curve (CN$2000)
  OffB0::VariableArray{2} = ReadDisk(db,"SInput/OffB0",year) #[Market,Poll,Year]  B Term in Offset Reduction Curve (CN$2000)
  OffC0::VariableArray{2} = ReadDisk(db,"SInput/OffC0",year) #[Market,Poll,Year]  C Term in Offset Reduction Curve (CN$2000)
  OffExcess::VariableArray{1} = ReadDisk(db,"SOutput/OffExcess",year) #[Area,Year]  Offsets in excess of Area needs (eCO2 Tonnes)
  OffGeneric::VariableArray{2} = ReadDisk(db,"SOutput/OffGeneric",year) #[Market,Poll,Year]  Generic Offsets (Tonnes/Yr)
  OffLimit::VariableArray{2} = ReadDisk(db,"SInput/OffLimit",year) #[Market,Poll,Year]  Offset Reduction Limit (Tonnes)
  OffMktFr::VariableArray{3} = ReadDisk(db,"SInput/OffMktFr",year) #[ECC,Area,Market,Year]  Fraction of Offsets allocated to each Market (Tonnes/Tonnes)
  OffRevenue::VariableArray{3} = ReadDisk(db,"SOutput/OffRevenue",year) #[ECC,Poll,Area,Year]  Offset Revenue including Sequestering (M$/Yr)
  Offsets::VariableArray{3} = ReadDisk(db,"SOutput/Offsets",year) #[ECC,Poll,Area,Year]  Offsets including Sequestering (Tonnes/Yr)
  OffsetsElec::VariableArray{3} = ReadDisk(db,"SOutput/OffsetsElec",year) #[ECC,Poll,Area,Year]  Offsets from Electric Utility Units (Tonnes/Yr)
  OffTotal::VariableArray{1} = ReadDisk(db,"SOutput/OffTotal",year) #[Market,Year]  Total Offsets (eCO2 Tonnes)
  OffYear::VariableArray{2} = ReadDisk(db,"SInput/OffYear") #[Market,Poll]  Constant Dollar Year for Offset Reduction Curve (Year)
  ORMEPol::VariableArray{3} = ReadDisk(db,"SOutput/ORMEPol",year) #[ECC,Poll,Area,Year]  Non-Energy Off Road Pollution (Tonnes/year)
  Over::VariableArray{2} = ReadDisk(db,"SOutput/Over",year) #[Market,Iter,Year]  Market Emissions Overage (Tonnes/Yr)
  OverBAB::VariableArray{1} = ReadDisk(db,"SOutput/OverBAB",year) #[Market,Year]  Overage Before Adjustment to Bank (Tonnes)
  OverLimit::VariableArray{1} = ReadDisk(db,"SInput/OverLimit",year) #[Market,Year]  Overage Limit as a Fraction (Tonnes/Tonnes)
  PAucRev::VariableArray{1} = ReadDisk(db,"SOutput/PAucRev",year) #[Market,Year]  Permits Auction Revenue (US$ Millions/Yr)
  PAuction::VariableArray{1} = ReadDisk(db,"SOutput/PAuction",year) #[Market,Year]  Permits Available for Auction (Tonnes/Yr)
  PBank::VariableArray{3} = ReadDisk(db,"SOutput/PBank",year) #[ECC,Poll,Area,Year]  Permits Banked (Tonnes/Yr)
  PBnkFr::VariableArray{3} = ReadDisk(db,"SInput/PBnkFr",year) #[ECC,Poll,Area,Year]  Fraction of Covered Emissions Banked (Tonnes/Tonnes)
  PBnkSw::VariableArray{1} = ReadDisk(db,"SInput/PBnkSw",year) #[Market,Year]  Banking Switch (1=Endo Prices, 2=Exog Prices)
  PBuy::VariableArray{3} = ReadDisk(db,"SOutput/PBuy",year) #[ECC,Poll,Area,Year]  Permits Bought (Tonnes/Yr)
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost (Real $/Tonnes)
  PCostNext::VariableArray{3} = ReadDisk(db,"SOutput/PCost",next) #[ECC,Poll,Area,Year]  Permit Cost (Real $/Tonnes)
  PCovMap::VariableArray{4} = ReadDisk(db,"SInput/PCovMap",year) #[FuelEP,ECC,PCov,Area,Year]  Pollution Coverage Map (1=Mapped)
  PExp::VariableArray{3} = ReadDisk(db,"SOutput/PExp",year) #[ECC,Poll,Area,Year]  Permits Expenditures (M$/Yr)
  PExpGross::VariableArray{3} = ReadDisk(db,"SOutput/PExpGross",year) #[ECC,Poll,Area,Year]  Permits Expenditures before Offset Revenue (M$/Yr)
  PGratis::VariableArray{4} = ReadDisk(db,"SOutput/PGratis",year) #[ECC,Poll,PCov,Area,Year]  Gratis Permits (Tonnes/Yr)
  PInvChange::VariableArray{1} = ReadDisk(db,"SOutput/PInvChange",year) #[Market,Year]  Change in Permit Inventory Before Banking Adjustment (Tonnes)
  PInventory::VariableArray{3} = ReadDisk(db,"SOutput/PInventory",year) #[ECC,Poll,Area,Year]  Permit Inventory (Tonnes)
  PInventoryPrior::VariableArray{3} = ReadDisk(db,"SOutput/PInventory",prior) #[ECC,Poll,Area,Prior]  Permit Inventory (Tonnes)
  PNeed::VariableArray{3} = ReadDisk(db,"SOutput/PNeed",year) #[ECC,Poll,Area,Year]  Permits Needed (Tonnes/Yr)
  POCAEU::VariableArray{2} = ReadDisk(db,"SOutput/POCAEU",year) #[Poll,Area,Year]  Average Electric Generation Emission Factor (Tonnes/TBtu)
  POCXEU::VariableArray{2} = ReadDisk(db,"SInput/POCXEU",year) #[Poll,Area,Year]  Exogenous Electric Generation Emission Factor (Tonnes/TBtu)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PolCov::VariableArray{4} = ReadDisk(db,"SOutput/PolCov",year) #[ECC,Poll,PCov,Area,Year]  Covered Pollution (Tonnes/Yr)
  PolCovRef::VariableArray{4} = ReadDisk(db,"SInput/BaPolCov",year) #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PolImports::VariableArray{2} = ReadDisk(db,"SOutput/PolImports",year) #[Poll,Area,Year]  Imported Electricity Emissions (Tonnes)
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) #[Poll,Market,Year]  Pollutants included in Market
  PolReduce::VariableArray{3} = ReadDisk(db,"SOutput/PolReduce",year) #[ECC,PCov,Area,Year]  Pollution Reduction Goal (eCO2 Tonnes)
  PolTot::VariableArray{4} = ReadDisk(db,"SOutput/PolTot",year) #[ECC,Poll,PCov,Area,Year]  Pollution (Tonnes/Yr)
  PRedeem::VariableArray{3} = ReadDisk(db,"SOutput/PRedeem",year) #[ECC,Poll,Area,Year]  Permits Redeemed from Inventory (Tonnes/Yr)
  PRedFr::VariableArray{3} = ReadDisk(db,"SInput/PRedFr",year) #[ECC,Poll,Area,Year]  Fraction of Permit Inventory Sold (Tonnes/Tonnes)
  PSell::VariableArray{3} = ReadDisk(db,"SOutput/PSell",year) #[ECC,Poll,Area,Year]  Permits Sold (Tonnes/Yr)
  RPolicy::VariableArray{3} = ReadDisk(db,"SOutput/RPolicy",year) #[ECC,Poll,Area,Year]  Pollution Reduction from Limit (Tonnes/Tonnes)
  SqPGMult::VariableArray{3} = ReadDisk(db,"SInput/SqPGMult",year) #[ECC,Poll,Area,Year]  Sequestering Gratis Permit Multiplier (Tonnes/Tonnes)
  SqPol::VariableArray{3} = ReadDisk(db,"SOutput/SqPol",year) #[ECC,Poll,Area,Year]  Sequestering Emissions (Tonnes/Yr)
  Target::VariableArray{1} = ReadDisk(db,"SOutput/Target",year) #[Market,Year]  Emissions Target (Tonnes)
  TBuy::VariableArray{1} = ReadDisk(db,"SOutput/TBuy",year) #[Market,Year]  Total Permit Bought (Tonnes/Yr)
  TGratis::VariableArray{1} = ReadDisk(db,"SOutput/TGratis",year) #[Market,Year]  Total Gratis Permits (Tonnes/Yr)
  TotPol::VariableArray{3} = ReadDisk(db,"SOutput/TotPol",year) #[ECC,Poll,Area,Year]  Pollution (Tonnes/Yr)
  TSell::VariableArray{1} = ReadDisk(db,"SOutput/TSell",year) #[Market,Year]  Total Permit Sold (Tonnes/Yr)
  VnPol::VariableArray{3} = ReadDisk(db,"SOutput/VnPol",year) #[ECC,Poll,Area,Year]  Fugitive Venting Emissions (Tonnes/Yr)
  xETAPr::VariableArray{1} = ReadDisk(db,"SInput/xETAPr",year) #[Market,Year]  Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xETAPrNext::VariableArray{1} = ReadDisk(db,"SInput/xETAPr",next) #[Market,Year]  Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xFSell::VariableArray{1} = ReadDisk(db,"SInput/xFSell",year) #[Market,Year]  Federal (Domestic) Permits Available (Tonnes/Yr)
  xGoalPol::VariableArray{1} = ReadDisk(db,"SInput/xGoalPol",year) #[Market,Year]  Pollution Goal (Tonnes/Yr)
  xISell::VariableArray{1} = ReadDisk(db,"SInput/xISell",year) #[Market,Year]  International Permits Available (Tonnes/Yr)
  xPAuction::VariableArray{1} = ReadDisk(db,"SInput/xPAuction",year) #[Market,Year]  Permits Available for Auction (Tonnes/Yr)
  xPGratis::VariableArray{4} = ReadDisk(db,"SInput/xPGratis",year) #[ECC,Poll,PCov,Area,Year]  Exogenous Gratis Permits (eCO2 Tonnes/Yr)
  xPolCap::VariableArray{4} = ReadDisk(db,"SInput/xPolCap",year) #[ECC,Poll,PCov,Area,Year]  Exogenous Emissions Cap (eCO2 Tonnes/Yr)
  xTGratis::VariableArray{1} = ReadDisk(db,"SInput/xTGratis",year) #[Market,Year]  Exogenous Gratis Permits (Tonnes/Yr)
  xXFSell::VariableArray{1} = ReadDisk(db,"SOutput/xXFSell",year) #[Market,Year]  Federal (Domestic) Permits Available (Tonnes/Yr)
  xXISell::VariableArray{1} = ReadDisk(db,"SOutput/xXISell",year) #[Market,Year]  International Permits Available (Tonnes/Yr)

  #
  # Scratch Variables
  #
  Change::VariableArray{1} = zeros(Float32,length(Market)) # Change in Emissions relative to Goal between Iterations (Tonnes)
  CrBuy::VariableArray{1} = zeros(Float32,length(Market)) # Emission Credits Bought (Tonnes)
  CrSell::VariableArray{1} = zeros(Float32,length(Market)) # Emission Credits Sold (Tonnes)
  ETAEff::VariableArray{1} = zeros(Float32,length(Market)) # Effective Permit Price (US$/Tonne)
  GoalMkt::VariableArray{1} = zeros(Float32,length(Market)) # Pollution Goal for Market (Tonnes/Yr)
  OffPr::VariableArray{1} = zeros(Float32,length(Market)) # Permit Price in Offset Curve Dollars (CN$2000/Tonne)
  OverMkt::VariableArray{1} = zeros(Float32,length(Market)) # Emissions Overage for Market (Tonnes/Yr)
  OverFrac::VariableArray{1} = zeros(Float32,length(Market)) # Market Emissions Overage Fraction (Tonnes/Tonnes)
  PolMkt::VariableArray{1} = zeros(Float32,length(Market)) # Pollution in Market (Tonnes/Yr)
  PBnkAdd::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area)) # Additional Allowances Bought and Banked (Tonnes)
  PBnkPolCov::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area)) # Banking Allocation Emissions Covered (Tonnes)
  PRedAdd::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area)) # Additional Allowances Redeemed and Sold (Tonnes)
  RetPol::VariableArray{2} = zeros(Float32,length(Poll),length(Area)) # Retail Fuel Customer Emissions (Tonnes)
  Temp_EPA::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
end

function GetMarketSets(data::Data,market)
  (; db,year,CTime) = data
  (; Areas,ECCs,Polls) = data
  (; AreaMarket,ECCMarket,PollMarket) = data
  
  areas = findall(AreaMarket[Areas,market] .== 1)
  eccs = findall(ECCMarket[ECCs,market] .== 1)
  polls = findall(PollMarket[Polls,market] .== 1)
  
  if !isempty(areas) && !isempty(eccs) && !isempty(polls)
    MarketValid = true
  else
    MarketValid = false
  end
  
  return areas,eccs,polls,MarketValid
  
end


function CoveredEmissions(data::Data)
  (; db,year) = data
  (; Areas,ECC,ECCs,Fuel,FuelEPs,Markets,PCov,PCovs,Plants,Poll,Polls) = data
  (; CgFPol,EAProd,ECCMarket,ECoverage,ElecSw,EuFPol) = data
  (; FlPol,FuPol,GPNGSw,GPOilSw,MEPol,NcPol,ORMEPol,PCovMap) = data
  (; POCAEU,PolConv,PolCov,PolTot,TotPol,VnPol) = data

  #@info "  SuPollutionMarket.jl - CoveredEmissions"

  #
  # Electricity Emission Factor (Average)
  #
  ecc = Select(ECC,"UtilityGen")
  for area in Areas, poll in Polls
    @finite_math POCAEU[poll,area] = 
      TotPol[ecc,poll,area]/sum(EAProd[plant,area]*3412/1e6 for plant in Plants)
  end

  WriteDisk(db,"SOutput/POCAEU",year,POCAEU)

  #
  # Pollution
  #
  pcovs = Select(PCov,["Energy","Oil","NaturalGas"])
  for area in Areas, pcov in pcovs, poll in Polls, ecc in ECCs
    PolTot[ecc,poll,pcov,area] = sum(EuFPol[fuelep,ecc,poll,area]*
                              PCovMap[fuelep,ecc,pcov,area] for fuelep in FuelEPs)
  end

  pcov = Select(PCov,"Cogeneration")
  for area in Areas, poll in Polls, ecc in ECCs
    PolTot[ecc,poll,pcov,area] = sum(CgFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end

  pcov = Select(PCov,"NonCombustion")
  for area in Areas, poll in Polls, ecc in ECCs
    PolTot[ecc,poll,pcov,area] = NcPol[ecc,poll,area]
  end

  pcov = Select(PCov,"Process")
  for area in Areas, poll in Polls, ecc in ECCs
    PolTot[ecc,poll,pcov,area] = MEPol[ecc,poll,area]+FuPol[ecc,poll,area]+ORMEPol[ecc,poll,area]
  end

  pcov = Select(PCov,"Venting")
  for area in Areas, poll in Polls, ecc in ECCs
    PolTot[ecc,poll,pcov,area] = VnPol[ecc,poll,area]
  end

  pcov = Select(PCov,"Flaring")
  for area in Areas, poll in Polls, ecc in ECCs
    PolTot[ecc,poll,pcov,area] = FlPol[ecc,poll,area]
  end

  #
  # Allocate Electric Generation Emissions
  #
  fuel = Select(Fuel,"Electric")
  ecc = Select(ECC,"UtilityGen")
  pcov = Select(PCov,"Energy")
  for area in Areas, poll in Polls
    
    #
    # If the Electricity Emission Allocation Switch (ElecSw) equals 1,
    # then allocate electricity emissions to sectors using the average
    # electricity emission factor (POCAEU).
    #
    if ElecSw[poll,area] == 1
      PolTot[ecc,poll,pcov,area] = PolTot[ecc,poll,pcov,area]+EuDemand[fuel,ecc,area]*POCAEU[poll,area]

    #
    # If the Electricity Emission Allocation Switch (ElecSw) equals 2,
    # then allocate electricity emissions to sectors using an exogneous
    # electricity emission factor (POCXEU).
    #
    elseif ElecSw[poll,area] == 2
      PolTot[ecc,poll,pcov,area] = PolTot[ecc,poll,pcov,area]+EuDemand[fuel,ecc,area]*POCXEU[poll,area]
    end
  end

  WriteDisk(db,"SOutput/PolTot",year,PolTot)

  #
  # Covered Pollution - Electric generation (UtilityGen) energy (Energy)
  # related covered emissions (PolCov) are calculated in EPollution.src,
  # but the other electric generation (UtilityGen) covered emissions (PolCov)
  # are calculated here.
  #
  ecc = Select(ECC,"UtilityGen")
  pcovs = Select(PCov,!=("Energy"))
  for area in Areas, pcov in pcovs, poll in Polls
    PolCov[ecc,poll,pcov,area] = PolTot[ecc,poll,pcov,area]*PolConv[poll]*ECoverage[ecc,poll,pcov,area]
  end

  #
  # Covered Pollution - the Electric Generation (UtilityGen) covered
  # emissions are calculated in EPollution.src.
  #
  eccs = Select(ECC,!=("UtilityGen"))
  for area in Areas, pcov in PCovs, poll in Polls, ecc in eccs
    PolCov[ecc,poll,pcov,area] = PolTot[ecc,poll,pcov,area]*PolConv[poll]*ECoverage[ecc,poll,pcov,area]
  end

  #
  # If Refiners and Importers must purchses GHG permits, then add RPP emissions
  # to the Petroleum Refiners total
  #
  for market in Markets 
    if GPOilSw[market] != 0   
      pcov = Select(PCov,"Oil")
      GHG = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
      petroleum = Select(ECC,"Petroleum")
      refineries  = Select(ECC,"OilRefineries")
      ECCPointers = union(petroleum,refineries)
      eccs = findall(ECCMarket[:,market] .== 1)
      for area in Areas, poll in GHG, eccpointer in ECCPointers
        PolCov[eccpointer,poll,pcov,area] = sum(PolTot[ecc,poll,pcov,area]*PolConv[poll] for ecc in eccs)
      end
    end

    #
    # If Natural Gas Distributors must purchses GHG permits, then add Natural Gas
    # emissions Natural Gas Distributors total.
    #
    if GPNGSw[market] != 0
      pcov = Select(PCov,"NaturalGas")
      GHG = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
      ECCPointer = Select(ECC,"NGDistribution")
      eccs = findall(ECCMarket[:,market] .== 1)
      for area in Areas, poll in GHG
        PolCov[ecc,poll,pcov,area] = sum(PolTot[ecc,poll,pcov,area]*PolConv[poll] for ecc in eccs)
      end
    end
  end

  WriteDisk(db,"SOutput/PolCov",year,PolCov)

end # CoveredEmissions

function GetGratisPermits(data::Data,market,areas,eccs,polls)
  (; db,year,CTime) = data
  (; Area,ECC,PCovs,Poll) = data
  (; Driver,EIBaseline,GratSw,OBAFraction,PGratis,PolConv,TGratis,xPGratis) = data

  #@info "  SuPollutionMarket.jl - GetGratisPermits"

  #
  # Electric Utility Gratis Permits are calculated in the electric sector
  #
  TGratis[market] = 0.0   
  for area in areas, pcov in PCovs, poll in polls, ecc in eccs
    if ECC[ecc] != "UtilityGen"
      if GratSw[market] == 2
        PGratis[ecc,poll,pcov,area] = EIBaseline[ecc,poll,pcov,area]*
                                      OBAFraction[ecc,area]*Driver[ecc,area]
        TGratis[market] = TGratis[market]+PGratis[ecc,poll,pcov,area] 
      elseif GratSw[market] == 0
        PGratis[ecc,poll,pcov,area] = xPGratis[ecc,poll,pcov,area]
        TGratis[market] = TGratis[market]+PGratis[ecc,poll,pcov,area] 
      else
        PGratis[ecc,poll,pcov,area] = 0.0
        TGratis[market] = TGratis[market]+PGratis[ecc,poll,pcov,area]         
      end
    end
  end
  

  WriteDisk(db,"SOutput/PGratis",year,PGratis)
  WriteDisk(db,"SOutput/TGratis",year,TGratis)

end

function GetGoalPol(data::Data,market)
  (; db,year) = data
  (; GoalPol,GoalPolSw,TGratis,xGoalPol) = data

  #@info "  SuPollutionMarket.jl - GetGoalPol"

  if GoalPolSw[market] == 1
    GoalPol[market] = TGratis[market]
  elseif GoalPolSw[market] == 0
    GoalPol[market] = xGoalPol[market]
  end

  WriteDisk(db,"SOutput/GoalPol",year,GoalPol)

end

function MarketOffsets(data::Data,market,areas,polls)
  (; db,year) = data
  (; ECC,ECCs,Nation,PCov,PCovs) = data
  (; DACProductionPrior,DACPolNetPrior) = data
  (; ECoverage,EORCredits,ETAPr,ExchangeRateCN2000,InflationUS,InflationUS2000) = data
  (; MEReduce,OffA0,OffB0,OffC0,OffGeneric,OffMktFr,OffPr,Offsets) = data
  (; OffsetsElec,OffTotal,PolConv,PolCov,SqPGMult,SqPol) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  #@info "  SuPollutionMarket.jl - MarketOffsets for Market $Market"

  #
  # Select all sectors since some have offsets even if they are
  # not in the market.
  #

  #
  # Market Variables in US$ while Generic Offset Curve is in CN$2000
  #
  @finite_math OffPr[market] = ETAPr[market]/
    InflationUS[US]*InflationUS2000[US]*ExchangeRateCN2000[CN]
  for poll in polls
    @finite_math OffGeneric[market,poll] = OffC0[market,poll]/
      (1+OffA0[market,poll]*OffPr[market]^OffB0[market,poll])
  end
  WriteDisk(db,"SOutput/OffGeneric",year,OffGeneric)

  #
  # Sequestering Credits (SqPol) are may be increased (SqPGMult) and
  # are adjusted for extra credit for EOR (or other uses of CO2).
  #
  for area in areas, poll in polls, ecc in ECCs
    SqPol[ecc,poll,area] = SqPol[ecc,poll,area]*SqPGMult[ecc,poll,area]-EORCredits[ecc,poll,area]

    #
    # Electric Utility sequestering must be less than current year emissions
    #
    if ECC[ecc] == "UtilityGen"
      
      #
      # Temp_EPA[ecc,poll,area] = sum(PolCov[ecc,poll,pcov,area]/
      #   PolConv[poll] for pcov in PCovs)
      #      
      SqPol[ecc,poll,area] = max(SqPol[ecc,poll,area],0-sum(PolCov[ecc,poll,pcov,area]/
        PolConv[poll] for pcov in PCovs))
    end
  end

  #
  # Offsets for each Sector
  #
  pcov = Select(PCov,"Process")
  for area in areas, poll in polls, ecc in ECCs
    Offsets[ecc,poll,area] = (MEReduce[ecc,poll,area]*(1-ECoverage[ecc,poll,pcov,area])-
    SqPol[ecc,poll,area]+OffsetsElec[ecc,poll,area])*PolConv[poll]
  end

  WriteDisk(db,"SOutput/Offsets",year,Offsets)

  #
  # Total Offsets
  #
  OffTotal[market] = 
    sum(Offsets[ecc,poll,area]*OffMktFr[ecc,area,market] for area in areas, poll in polls, ecc in ECCs)+
    sum(OffGeneric[market,poll]*PolConv[poll] for poll in polls)+
    sum(DACProductionPrior[area]-DACPolNetPrior[area] for area in areas)

  WriteDisk(db,"SOutput/OffTotal",year,OffTotal)

end # MarketOffsets

function BuySellPermits(data::Data,market,areas,eccs,polls)
  (; db,year,CTime) = data
  (; Area,ECC,Nation,PCovs,Poll) = data
  (; Enforce,ETABank,ETADA1P,ETADA2P,ETADA3P,ETADAP) = data
  (; ETAPr,ETARedeem,FBuy,FBuyFr,FBuyFrArea,FInventoryPrior) = data
  (; FInvRev,FInvRevPrior,FPCredits,FSeFr1,FSeFr2,FSeFr3,FSell,GoalPol) = data
  (; InflationUS,ISaleSw,MktPol,OffA0,OffB0,OffPr,OffTotal) = data
  (; PBank,PBnkFr,PBuy,PGratis,PInvChange,PInventory) = data
  (; PInventoryPrior,PNeed,PolConv,PolCov,PRedeem,PRedFr,PSell,TBuy) = data
  (; TSell,xFSell,xISell,xPAuction,xPolCap,xXFSell,xXISell) = data

  US = Select(Nation,"US")
  CO2 = Select(Poll,"CO2")

  #@info "  SuPollutionMarket.jl - BuySellPermits"

  #
  # Emissions Covered by this Market.  Convert GHG emissions to CO2
  # equivalent.  The conversion factor (PolConv) is equal 1.0 for
  # all non-GHG pollutants.
  #
  MktPol[market] = sum(PolCov[ecc,poll,pcov,area]
    for area in areas, pcov in PCovs, poll in polls, ecc in eccs)

  WriteDisk(db,"SOutput/MktPol",year,MktPol)

  #
  # The number of permits needed (PNeed) is the covered pollution (PolCov)
  # minus the gratis permits (PGratis)
  #
  for area in areas, poll in polls, ecc in eccs
    PNeed[ecc,poll,area] = sum(PolCov[ecc,poll,pcov,area]-
                               PGratis[ecc,poll,pcov,area] for pcov in PCovs)
  end

  WriteDisk(db,"SOutput/PNeed",year,PNeed)

  #
  # Bank permits (PBank) if price is less than ETABank based on
  # the fraction of permits banked (PBnkFr)
  #
  for area in areas, poll in polls, ecc in eccs
    PBank[ecc,poll,area] = sum(PolCov[ecc,poll,pcov,area] for pcov in PCovs)*PBnkFr[ecc,poll,area]*
                        min((ETAPr[market]/(ETABank[market]*InflationUS[US]/2))^(-5.0),1.0)
  end

  WriteDisk(db,"SOutput/PBank",year,PBank)

  #
  # Redeem permits from inventory (PRedeem) if price is greater than ETARedeem
  # based on the fraction of inventory redeemed (PRedFr).
  #
  for area in areas, poll in polls, ecc in eccs
    PRedeem[ecc,poll,area] = PInventoryPrior[ecc,poll,area]*PRedFr[ecc,poll,area]*
                           min(((ETARedeem[market]*InflationUS[US]*1.10)/ETAPr[market])^(-15.0),1.0)
  end

  WriteDisk(db,"SOutput/PRedeem",year,PRedeem)

  #
  # Change in Banked Allowance Inventory before Banking Adjustment
  #
  PInvChange[market] = sum(PBank[ecc,poll,area]-
                    PRedeem[ecc,poll,area] for area in areas, pcov in PCovs, poll in polls, ecc in eccs)

  WriteDisk(db,"SOutput/PInvChange",year,PInvChange)

  #
  # The number of permits bought (PBuy) is the number needed (PNeed)
  # plus the number added to inventory (PBank) minus the number removed
  # from inventory (PRedeem)
  #
  for area in areas, poll in polls, ecc in eccs
    PBuy[ecc,poll,area] =
      max(PNeed[ecc,poll,area]+PBank[ecc,poll,area]-PRedeem[ecc,poll,area],0)
  end

  WriteDisk(db,"SOutput/PBuy",year,PBuy)

  #
  # The number of permits sold (PSell) is the number redeemed from
  # inventory (PRedeem) less the number needed (PNeed) minus the number
  # added to the inventory (PBank).
  #
  for area in areas, poll in polls, ecc in eccs
    PSell[ecc,poll,area] =
      max(PRedeem[ecc,poll,area]-PNeed[ecc,poll,area]-PBank[ecc,poll,area],0)
  end

  WriteDisk(db,"SOutput/PSell",year,PSell)

  #
  # The federal govenment uses a fraction (FBuyFr) of the revenue
  # from selling permits (FInvRevPrior) to buy emissions permits (FBuy).
  #
  if (FInvRev[market] != -99) && (ISaleSw[market] != 5)
    FBuy[market] = max(FInvRevPrior[market]*FBuyFr[market]/ETAPr[market],0)*1e6

  #
  # For WCI style Cap and Trade (ISaleSw=5), the Domestic Permits
  # are called an Allowance Reserve which are removed (bought) at
  # certain fraction each year.
  #
  elseif ISaleSw[market] == 5
    FBuy[market] = sum(xPolCap[ecc,poll,pcov,area]*
                     FBuyFrArea[area] for area in areas, pcov in PCovs, poll in polls, ecc in eccs)+
                GoalPol[market]*FBuyFr[market]

  #
  # Else no Domestic Permits are purchased
  #
  else
    FBuy[market] = 0.0
  end

  WriteDisk(db,"SOutput/FBuy",year,FBuy)

  #
  # The WCI style Cap and Trade (ISaleSw=5) contains an Allowance
  # Reserve.  A fraction (FSeFr1, FSeFr2,FSeFr3) of the reserve
  # is released (sold) at certain price points (ETADA1P,
  # ETADA2P, ETADA3P).
  #

  if ISaleSw[market] == 5
    if (ETAPr[market]/InflationUS[US]) > ETADA3P[market]
      xXFSell[market] = (FInventoryPrior[market]+FBuy[market])*FSeFr3[market]
      ETADAP[market] = ETADA3P[market]

    elseif (ETAPr[market]/InflationUS[US]) > ETADA2P[market]
      xXFSell[market] = (FInventoryPrior[market]+FBuy[market])*FSeFr2[market]
      ETADAP[market] = ETADA2P[market]

    elseif (ETAPr[market]/InflationUS[US]) > ETADA1P[market]
      xXFSell[market] = (FInventoryPrior[market]+FBuy[market])*FSeFr1[market]
      ETADAP[market] = ETADA1P[market]

    else
      xXFSell[market] = 0
    end

    WriteDisk(db,"SInput/ETADAP",year,ETADAP)

  elseif ISaleSw[market] == 6
    if (ETAPr[market]/InflationUS[US]+0.10) >= ETADAP[market]
      xXFSell[market] = xFSell[market]
    else
      xXFSell[market] = 0
    end

  #
  # Else Domestic Permits Available (xXFSell) is exogenous (xFSell).
  #
  else
    xXFSell[market] = xFSell[market]
  end

  WriteDisk(db,"SOutput/xXFSell",year,xXFSell)

  #
  # Domestic Permits (FSell) are initialized to the maximium
  # (xXFSell), then reduced later if not needed.
  #
  FSell[market] = xXFSell[market]

  WriteDisk(db,"SOutput/FSell",year,FSell)

  #
  ###########################
  #
  # International Permits
  #
  if ISaleSw[market] == 5
    xXISell[market] = xISell[market]/(1+OffA0[market,CO2]*OffPr[market]^OffB0[market,CO2])
  elseif (ISaleSw[market] == 6) && ((ETAPr[market]/InflationUS[US]*1.01) < ETAFAP[market])
    xXISell[market] = 0.0
  else
    xXISell[market] = xISell[market]
  end

  WriteDisk(db,"SOutput/xXISell",year,xXISell)

  #
  # Offsets including Government and Foreign Permits
  #
  FPCredits[market] = FSell[market]-FBuy[market]+xXISell[market]+OffTotal[market]

  WriteDisk(db,"SOutput/FPCredits",year,FPCredits)

  #
  # Demand for permits (TBuy) is the sector purchases (PBuy) plus the
  # government purchases (FBuy).
  #
  TBuy[market] = sum(PBuy[ecc,poll,area] for area in areas, poll in polls, ecc in eccs)+FBuy[market]

  WriteDisk(db,"SOutput/TBuy",year,TBuy)

  #
  # Supply of permits (TSell) is amount auctioned (xPAuction), government
  # sales (FSell), international permits (xXISell), and Offsets (OffTotal).
  #
  TSell[market] = xPAuction[market]+
    sum(PSell[ecc,poll,area] for area in areas, poll in polls, ecc in eccs)+
    FSell[market]+xXISell[market]+OffTotal[market]

  WriteDisk(db,"SOutput/TSell",year,TSell)

  #
  # The number of permits in inventory (PInventory) is the number
  # in inventory in the previous year (PInventoryPrior) plus the number
  # banked (PBank) less the number sold from inventory (PRedeem).
  #
  if Enforce[market] <= CTime
    for area in areas, poll in polls, ecc in eccs
      PInventory[ecc,poll,area] = PInventoryPrior[ecc,poll,area]+DT*(PBank[ecc,poll,area]-PRedeem[ecc,poll,area])
    end
  end

end # BuySellPermits

function InitializeMarkets(data::Data)
  (; db,year,CTime) = data
  (; Markets,Nation,Poll) = data
  (; AreaMarket,CapTrade,DoneM,ECCMarket,eCO2Price,Enforce) = data
  (; ETABY,ETADAP,ETAPr,ETAvPr,ETR,ETRSw,ExchangeRate,FSell) = data
  (; InflationUS,ISell,PollMarket,xETAPr,xFSell,xISell) = data

  US = Select(Nation,"US")
  CO2 = Select(Poll,"CO2")

  #@info "  SuPollutionMarket.jl - InitializeMarkets"

  for market in Markets
    if CapTrade[market] != 0 && (ETABY[market] <= CTime)
      areas,eccs,polls,ValidMarket = GetMarketSets(data::Data,market)
      if ValidMarket

        #
        # Initalize Market to Iterate
        #
        DoneM[market] = 1

        #
        # Initialize prices (ETAPr, ETR) to exogenous price (xETAPr)
        # if exogenous price (xETAPr) is greater than zero else
        # prices (ETAPr, ETR) start with values from previous year.
        #
        if xETAPr[market] > 0
          ETAPr[market] = xETAPr[market]*InflationUS[US]
          ETR[market] = ETAPr[market]
        end
        ETAvPr[market] = ETAPr[market]

        #
        # Maximum CO2 Price in the Nation
        #
        if (PollMarket[CO2,market] == 1) && (Enforce[market] <= CTime)
          for area in areas
            eCO2Price[area] = max(eCO2Price[area],ETAPr[market]*ExchangeRate[area])
          end
        end
      end

      iter = 1
      if (ETR[market,iter] == 0.00) && ((ETRSw[market] == 1) || (ETRSw[market] == 2))
        @info "File: SuPollution Procedure: InitMarkets"
        @info " Market $market ETR = 0 during initialization in SuPollution"
      end

    #
    # Hard Cap
    #
    elseif CapTrade[market] == 2
      DoneM[market] = 1
    end # CapTrade & ETABY

    if (CapTrade[market] == 6) || (CapTrade[market] == 7)
      FSell[market] = xFSell[market]
      ISell[market] = xISell[market]
    end
  end

  WriteDisk(db,"SOutput/eCO2Price",year,eCO2Price)
  WriteDisk(db,"SInput/ETADAP",year,ETADAP)
  WriteDisk(db,"SOutput/ETAPr",year,ETAPr)
  WriteDisk(db,"SOutput/ETAvPr",year,ETAvPr)
  WriteDisk(db,"SOutput/ETR",year,ETR)
  WriteDisk(db,"SOutput/DoneM",DoneM)
  WriteDisk(db,"SOutput/FSell",year,FSell)
  WriteDisk(db,"SOutput/ISell",year,ISell)

end

function OneGoals(data::Data,market,CIt,NIt,PIt)
  (; db,year,CTime) = data
  (; CapTrade,Change,CrBuy,CrSell,Epsilon,ETRSw) = data
  (; FPCredits,FSell,GoalMkt,GoalPol,GPol) = data
  (; MktPol,MPol,Over,OverFrac,OverMkt,PolMkt,TBuy) = data
  (; TSell,xFSell) = data

  #@info "  SuPollutionMarket.jl - OneGoals for Market $market $CTime"
  
  #
  # Market goals for a single independent market
  #
  # MPol is Credits Needed to be Purchased or Total Emissions
  # GPol is Credits Available to be Sold or Emissions Goal
  #
  if (ETRSw[market] == 1) || (CapTrade[market] == 6) || (CapTrade[market] == 7)
    MPol[market,CIt] = TBuy[market]
    GPol[market,CIt] = TSell[market]
  else
    MPol[market,CIt] = MktPol[market]-FPCredits[market]
    GPol[market,CIt] = GoalPol[market]
  end

  #
  # Emissions Credits - bought and sold
  #
  CrBuy[market] = MPol[market,CIt]
  CrSell[market] = GPol[market,CIt]

  #if market == 141
  #  @info " OG 1 ETRSw   = $(ETRSw[market])  FPCredits = $(FPCredits[market]/1e6) $market"
  #  @info " OG 1 TBuy    = $(TBuy[market]/1e6)  TSell    = $(TSell[market]/1e6) $market"
  #  @info " OG 1 MktPol  = $(MktPol[market]/1e6)  GoalPol  = $(GoalPol[market]/1e6) $market"
  #  @info " OG 1 CrBuy   = $(CrBuy[market]/1e6)  CrSell    = $(CrSell[market]/1e6) $market"
  #end
  
  if CapTrade[market] == 6
    OverMkt[market] = CrBuy[market]-CrSell[market]
    Loc1=CrBuy[market]-CrSell[market]-FSell[market]
    if Loc1 < 0
      FSell[market] = 0
    else
      FSell[market] = OverMkt[market]
    end
    WriteDisk(db,"SOutput/FSell",year,FSell)
  end

  if CapTrade[market] == 7
    FSell[market] = xFSell[market]
    WriteDisk(db,"SOutput/FSell",year,FSell)
  end

  #
  # Overage (Over) is Purchases (CrBuy) minus Sales (CrSell)
  #
  Over[market,CIt] = CrBuy[market]-CrSell[market]
  OverMkt[market] = CrBuy[market]-CrSell[market]

  #
  # Emissions goal for combined market
  #
  GoalMkt[market] = max(GoalPol[market],Epsilon)

  if (CapTrade[market] == 6) || (CapTrade[market] == 7)
    GoalMkt[market] = max(CrBuy[market],Epsilon)
  end

  #
  # Emissions in market
  #
  PolMkt[market] = MktPol[market]-FPCredits[market]
  if (CapTrade[market] == 6) || (CapTrade[market] == 7)
    PolMkt[market] = max(CrSell[market],Epsilon)
  end

  #
  # Overage Fraction (OverFrac) is overage (OverMkt) divided by goal (GoalMkt)
  #
  OverFrac[market] = abs(OverMkt[market])/GoalMkt[market]

  #
  # Change between iterations
  #
  Change[market] = abs(Over[market,CIt]-Over[market,PIt])/GoalMkt[market]
  
  #if market == 141
  #  @info " OG 2 TBuy    = $(TBuy[market]/1e6)  TSell    = $(TSell[market]/1e6) $market"
  #  @info " OG 2 PolMkt  = $(PolMkt[market]/1e6)  GoalMkt  = $(GoalMkt[market]/1e6) $market"
  #  @info " OG 2 CrBuy   = $(CrBuy[market]/1e6)  CrSell   = $(CrSell[market]/1e6) $market"
  #  @info " OG 2 OverMkt = $(OverMkt[market]/1e6)  OverFrac = $(OverFrac[market]) $market"
  #  @info " OG 2 Epsilon = $Epsilon $market"
  #end
  
  WriteDisk(db,"SOutput/GPol",year,GPol)
  WriteDisk(db,"SOutput/MPol",year,MPol)
  WriteDisk(db,"SOutput/Over",year,Over)

end

function UnlimitedTechFund(data::Data,market,CIt,NIt,PIt)
  (; db,year) = data
  (; Nation) = data
  (; ETADAP,ETAPr,ETR,FSell,InflationUS,ISaleSw,OverMkt) = data

  US = Select(Nation,"US")

  #@info "  SuPollutionMarket.jl - UnlimitedTechFund for Market $market"

  #
  # Unlimited Tech Fund (ISalesw == 2)
  #
  if ISaleSw[market] == 2
    #
    # If the price (ETR) is greater than the TIF price (ETADAP),
    # then the price is equal to the TIF price (ETADAP) and the
    # TIF is unlimited.
    #
    if ETR[market,NIt] > (ETADAP[market]*InflationUS[US])
      ETR[market,NIt] = ETADAP[market]*InflationUS[US]
      WriteDisk(db,"SOutput/ETR",year,ETR)

      ETAPr[market] = ETADAP[market]*InflationUS[US]
      WriteDisk(db,"SOutput/ETAPr",year,ETAPr)

      FSell[market] = max(OverMkt[market],0)
      WriteDisk(db,"SOutput/FSell",year,FSell)

      DoneM[market] = 0

    #
    # Else the price (ETR) is less than the TIF price (ETADAP),
    # so the price does not change and the TIF is zero.
    #
    else
      FSell[market] = 0
      WriteDisk(db,"SOutput/FSell",year,FSell)
    end

  end

end

function LimitedTechFund(data::Data,market,CIt,NIt,PIt)
  (; db,year) = data
  (; Nation) = data
  (; CapTrade,ETADAP,ETR,FSell,InflationUS,ISaleSw,OverMkt,xFSell) = data

  US = Select(Nation,"US")

  #@info "  SuPollutionMarket.jl - LimitedTechFund for Market $market"

  if (ISaleSw[market] != 2) && (CapTrade[market] == 6)
    #
    # If the price (ETR) is greater than the TIF price (ETADAP),
    # then use all the available TIF (xFSell).
    #
    if ETR[market,NIt] > (ETADAP[market]*InflationUS[US])
      FSell[market] = min(max(OverMkt[market],0),xFSell[market])
    else
      FSell[market] = 0
    end

    WriteDisk(db,"SOutput/FSell",year,FSell)
  end

end

function IterCostOfPermits(data::Data,market,CIt,NIt,PIt)
  (; db,year,next,CTime) = data
  (; Iter,Nation) = data
  (; CrBuy,CrSell,DoneM,Epsilon,ETABY,ETADAP,ETAFAP,ETAIncr,ETAMax,ETAMin) = data
  (; ETAPr,ETAPrNext,ETR,ETRNext,FSell,GoalMkt,InflationUS,InflationUSNext) = data
  (; ISaleSw,OverFrac,OverLimit,OverMkt,PolMkt,xXISell,xETAPr,xETAPrNext) = data
  
  #@info "  SuPollutionMarket.jl - IterCostOfPermits for Market $market $CTime"

  US = Select(Nation,"US")

  # NIt = Next Iteration
  # CIt = Current Iteration
  # PIt = Previous Iteration

  # 
  # Select Year(Current)
  #
  if CTime >= ETABY[market]
  
  #@info " ICP 1 PolMkt = $(PolMkt[market]) GoalMkt = $(GoalMkt[market])"
  #@info " ICP 1 CrBuy  = $(CrBuy[market])  CrSell  = $(CrSell[market])"
  #@info " ICP 1 ETAPr  = $(ETAPr[market])  OverMkt = $(OverMkt[market]) OverFrac = $(OverFrac[market]) "
  #@info " ETR  1 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
  
    #
    # Check to see if we are "done"
    #
    if ((CIt > 1) && (CIt < (length(Iter) - 2)) &&
        (OverFrac[market] > OverLimit[market])) || (CIt <= 3)

      #
      # Adjust Prices
      #
      @finite_math ETR[market,NIt] = 
        ETR[market,CIt]*((CrBuy[market]/max(Epsilon,CrSell[market]))^ETAIncr[market])
      #@info " ETR  2 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
      #@info " CrBuy = $(CrBuy[market]) CrSell = $(CrSell[market])"
      #@info " ETAIncr = $(ETAIncr[market]) Epsilon = $Epsilon " 
        if isnan(ETR[market,NIt]) == true
          ETR[market,NIt] = ETAMax[market]*InflationUS[US]
        end
      #@info " ETR 2a = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) "         
      
      
      #
      # If Prices are Oscillating,then average last two prices
      #
      if (DoneM[market] != 2) &&
         (((ETR[market,NIt] < ETR[market,CIt]) && (ETR[market,CIt] > ETR[market,PIt])) ||
          ((ETR[market,NIt] > ETR[market,CIt]) && (ETR[market,CIt] < ETR[market,PIt])))
        ETR[market,NIt] = (ETR[market,CIt]+ETR[market,PIt])/2
        DoneM[market] = 2
        #@info " SuPollutionMarket.src Oscillation Adjustment"
        #@info " ETR  3 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
        

        # NOTE: Commented out in Promula
        # *
        # *    Else if we are close,then slow down adjustment
        # *
        # *    Else (OverFrac < 0.05)
        # *      ETR[market,NIt] = ETR[market,CIt]*((CrBuy/max(Epsilon,CrSell))^(ETAIncr[market]*0.5))
        # *      DoneM[market] = 1
        # *
        # *    Else if no oscillations,accelerate price changes
        # *
        # *    Else (CIt > 5) && (OverFrac > 0.20)
        # *      ETR[market,NIt] = ETR[market,CIt]*((CrBuy/max(Epsilon,CrSell))^(ETAIncr[market]*1.5))
        # *      DoneM[market] = 1
      
      else
        DoneM[market] = 1
      end
      
    #
    # Else we are Done
    #
    else
      ETR[market,NIt] = ETR[market,CIt]
      DoneM[market] = 1
      if (CIt >= (length(Iter) - 2)) || (OverFrac[market] <= OverLimit[market])
        DoneM[market] = 0
        @info " OverFrac <= OverLimit"
      end
      #@info " ETR  4 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
      
    end

    # if CapTrade[market] != 6 # Conditional commented out in Promula
    #
    # If the domestic price (ETADAP) is less than the international permit
    # price (ETAFAP),then domestic permits are used before international
    # permits.
    #
    if ETADAP[market] < ETAFAP[market]
  
      #
      # If the goal has been met (OverMkt <= 0.0) and the price is less
      # than the domestic permit price (ETR < ETADAP*InflationUS) and the goal
      # requires only the the use of domestic permits ((FSell[market]+OverMkt) > 0),
      # then the price must be equal to the domestic permit price (ETADAP)
      #
      if (OverMkt[market] <= 0) &&
         (ETR[market,NIt] < ETADAP[market]*InflationUS[US]) &&
         ((FSell[market]+OverMkt[market]) > 0)
        
        ETR[market,NIt] = ETADAP[market]*InflationUS[US]
        DoneM[market] = 0
        #@info " ETR  5 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
        
        
      #
      # Else if the goal has been met (OverMkt <= 0.0) and the price is less
      # than the international permit price (ETR < ETAFAP*InflationUS) and the
      # goal requires the use of domestic permits and international permits
      # ((FSell[market]+xXISell+OverMkt) > 0),then the price must be equal to
      # international permit price (ETAFAP).
      #
      elseif (xXISell[market] > 0) && (OverMkt[market] <= 0) &&
             (ETR[market,NIt] < ETAFAP[market]*InflationUS[US]) &&
             ((FSell[market]+xXISell[market]+OverMkt[market]) > 0)
        
        ETR[market,NIt] = ETAFAP[market]*InflationUS[US]
        DoneM[market] = 0
        #@info " ETR  6 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
        
      end
      
    #
    # Else if the international permit price (ETAFAP) is less than the domestic permit
    # price (ETADAP),then use international permits first.
    #
    else
   
      #
      # If the goal has been met (OverMkt <= 0.0) and the price is less than the
      # International permit price (ETR < ETAFAP*InflationUS) and the goal requires only the
      # use of international permits ((xXISell[market]+OverMkt) > 0),then the price must be
      # equal to the international permit price (ETAFAP)
      #
      if (OverMkt[market] <= 0) && (ETR[market,NIt] < ETAFAP[market]*InflationUS[US]) &&
         ((xXISell[market]+OverMkt[market]) > 0)
         
        ETR[market,NIt] = ETAFAP[market]*InflationUS[US]
        DoneM[market] = 0
        #@info " ETR  7 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
        
      #
      # Else if the goal has been met (OverMkt <= 0.0) and the price is less than the
      # domestic permit price (ETR < ETADAP*InflationUS) and the goal requires the use of
      # domestic permits and international permits ((FSell[market]+xXISell+OverMkt) > 0),
      # then the price must be equal to domestic permit price (ETADAP)
      #
      elseif (OverMkt[market] <= 0) && (ETR[market,NIt] < ETADAP[market]*InflationUS[US]) &&
             ((FSell[market]+xXISell[market]+OverMkt[market]) > 0)
        
        ETR[market,NIt] = ETADAP[market]*InflationUS[US]
        DoneM[market] = 0
        #@info " ETR  8 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
        
      end
    end
    
    # End Do If CapTrade

    #
    # If price (ETR) is less than minimum price (ETAMin) and
    # goal is met,then quit
    #
    if ETR[market,NIt] <= (ETAMin[market]*InflationUS[US])
      if (OverMkt[market]/GoalMkt[market]) <= OverLimit[market]
        @info " Price is less than minimum"
        DoneM[market] = 0
      end
      ETR[market,NIt] = ETAMin[market]*InflationUS[US]
      #@info " ETR  9 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
      
    
    #
    # If price (ETR) is greater than maximum price (ETAMax) and
    # goal is not met,then quit.
    #
    elseif ETR[market,NIt] >= (ETAMax[market]*InflationUS[US])
      if (OverMkt[market]/GoalMkt[market]) >= OverLimit[market]
        @info " Price is greater than maximum"
        DoneM[market] = 0
      end
      ETR[market,NIt] = ETAMax[market]*InflationUS[US]
      #@info " ETR 10 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
      
    end

    #
    # If overage is not changing,then stop.
    #
    if (CIt > 5) && (Change[market] < 0.001)
      @info " Overage not changing"
      DoneM[market] = 0
    end
    
    #
    # If we allow unlimited international trading (ISaleSw=1 or 3),then
    # the price (ETAPr) is equal to the international price (ETAFAP).
    #
    if (ISaleSw[market] == 1) || (ISaleSw[market] == 3)
      ETR[market,NIt] = ETAFAP[market]*InflationUS[US]
      DoneM[market] = 0
      #@info " ETR 11 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
      
    end
    #@info " ETR 12 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 

    UnlimitedTechFund(data,market,CIt,NIt,PIt)
    #@info " ETR 13 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
    
    LimitedTechFund(data,market,CIt,NIt,PIt)
    #@info " ETR 14 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 

    #
    # Minimum Number of Iterations
    #
    if CIt < 3
      DoneM[market] = 1
    end

    #
    # Assign values for this year
    #
    ETAPr[market] = ETR[market,NIt]
    
    #
    # Emission Prices (ETAPr) are for the Current year,but are also used
    # as the initial value for the Current year.  This is to reduce the
    # iterations needed when running TIM.
    #
    ETR[market,1] = ETR[market,NIt]
    #@info " ETR 15 = $(ETR[market,NIt]) $(ETR[market,CIt]) $(ETR[market,PIt]) " 
    
    WriteDisk(db,"SOutput/ETAPr",year,ETAPr)
    WriteDisk(db,"SOutput/ETR",year,ETR)

    #
    # Emission Prices (ETAPr) are for the Current year,but are also used
    # as the initial value for the Next year.
    #
    ETAPrNext[market] = ETR[market,NIt]
    ETRNext[market,1] = ETR[market,NIt]
    WriteDisk(db,"SOutput/ETAPr",next,ETAPrNext)
    WriteDisk(db,"SOutput/ETR",next,ETRNext)

  #
  # Else Market has not started
  #
  else
    ETAPr[market] = xETAPr[market]*InflationUS[US]
    WriteDisk(db,"SOutput/ETAPr",year,ETAPr)
  
    #
    ETAPrNext[market] = xETAPrNext[market]*InflationUSNext[US]
    WriteDisk(db,"SOutput/ETAPr",next,ETAPrNext)
  end

  #
  # Display
  #
  @info " Market = $market Iteration = $CIt DoneM = $(DoneM[market])"
  CrBuy[market] = CrBuy[market]/1000000
  CrSell[market] = CrSell[market]/1000000
  OverMkt[market] = OverMkt[market]/1000000
  GoalMkt[market] = GoalMkt[market]/1000000
  PolMkt[market] = PolMkt[market]/1000000
  @info " PolMkt = $(PolMkt[market]) GoalMkt = $(GoalMkt[market])"
  @info " CrBuy  = $(CrBuy[market])  CrSell  = $(CrSell[market])"
  @info " ETAPr  = $(ETAPr[market])  OverMkt = $(OverMkt[market]) OverFrac = $(OverFrac[market]) "

end # IterCostOfPermits

function ExogCostOfPermits(data::Data,market,CIt,NIt,PIt)
  (; db,year,next) = data
  (; Nation) = data
  (; CapTrade,ETAPr,ETAPrNext,ETAvPr,ETAvPrNext,ETR,ETRNext) = data
  (; InflationUS,InflationUSNext,xETAPr,xETAPrNext) = data

  US = Select(Nation,"US")

  #@info "  SuPollutionMarket.jl - ExogCostOfPermits for Market $market"

  ETAPr[market] = xETAPr[market]*InflationUS[US]
  ETR[market,CIt] = ETAPr[market]
  ETR[market,NIt] = ETAPr[market]
  ETAvPr[market] = ETAPr[market]

  WriteDisk(db,"SOutput/ETAPr",year,ETAPr)
  WriteDisk(db,"SOutput/ETAvPr",year,ETAvPr)
  WriteDisk(db,"SOutput/ETR",year,ETR)

  if CapTrade[market] > 0
    ETAPrNext[market] = xETAPrNext[market]*InflationUSNext[US]
  else
    ETAPrNext[market] = 0
  end
  ETRNext[market,CIt] = ETAPrNext[market]
  ETRNext[market,NIt] = ETAPrNext[market]
  ETAvPrNext[market] = ETAPrNext[market]

  WriteDisk(db,"SOutput/ETAPr",next,ETAPrNext)
  WriteDisk(db,"SOutput/ETAvPr",next,ETAvPrNext)
  WriteDisk(db,"SOutput/ETR",next,ETRNext)

end

function CostOfPermits(data::Data,market,CIt,NIt,PIt,areas,eccs,polls)
  (; ETRSw,DoneM) = data

  #@info "  SuPollutionMarket.jl - CostOfPermits for Market $market"

  #
  # Iteration Methods - iterate until price is found
  #
  if (ETRSw[market] == 1) || (ETRSw[market] == 2)
    OneGoals(data,market,CIt,NIt,PIt)
    IterCostOfPermits(data,market,CIt,NIt,PIt)

  #
  # Old Method - calculate price for next year
  #
  elseif ETRSw[market] == 3
    #@info "  SuPollutionMarket.jl - CostOfPermits ETRSw == 3; for Market $market"
    DoneM[market] = 0

  #
  # Exogenous Permit Cost
  #
  elseif ETRSw[market] == 0
    OneGoals(data,market,CIt,NIt,PIt)
    ExogCostOfPermits(data,market,CIt,NIt,PIt)
    UnlimitedTechFund(data,market,CIt,NIt,PIt)
    LimitedTechFund(data,market,CIt,NIt,PIt)
    DoneM[market] = 0
  end

end

function Off1Allocation(data::Data,market,areas,eccs,polls)
  (; db,year,CTime) = data
  (; Nation,PCovs) = data
  (; CapTrade,Emissions,ETADAP,ETAFAP,ETAPr,FBuy,FInventory) = data
  (; FInventoryPrior,FInvRev,FInvRevPrior,FSell,GoalPol) = data
  (; InflationUS,IR,ISaleSw,ISell,MktPol,OffTotal,OverBAB) = data
  (; PAuction,PBank,PBnkSw,PBuy,PInvChange,PInventory,PInventoryPrior) = data
  (; PolCov,PolCovRef,PRedeem,PSell,Target,xFSell,xISell) = data
  (; xPAuction,xXFSell,xXISell) = data
  (; PRedAdd,PBnkAdd,PBnkPolCov) = data

  US = Select(Nation,"US")

  #@info "  SuPollutionMarket.jl - Off1Allocation for Market $market"

  #
  # Allocate Offsets based on Prices
  #
  # Internal Reductions (IR)
  #
  for area in areas, pcov in PCovs, ecc in eccs
    IR[ecc,pcov,area] = sum(PolCovRef[ecc,poll,pcov,area]-
                      PolCov[ecc,poll,pcov,area] for poll in polls)
  end
  IRTotal = sum(IR[ecc,pcov,area] for area in areas, pcov in PCovs, ecc in eccs)

  #
  # Emissions Target
  #
  Target[market] = GoalPol[market]
  WriteDisk(db,"SOutput/Target",year,Target)

  #
  # Actual Emissions
  #
  Emissions[market] = MktPol[market]
  WriteDisk(db,"SOutput/Emissions",year,Emissions)

  #
  # Two Tier TIF (ISaleSw=6)
  #
  if ISaleSw[market] == 6
    if (ETAPr[market]/InflationUS[US]+0.10) >= ETADAP[market]
      FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXFSell[market]),0)
      if ((ETAPr[market]/InflationUS[US]*1.01) >= ETAFAP[market])
        ISell[market] = max(min(Emissions[market]+FBuy[market]-FSell[market]-OffTotal[market]+PInvChange[market]-Target[market],xXISell[market]),0)
      end
    else
      FSell[market] = 0.0
    end

  #
  # WCI - QC and CA market so any flows between the areas shows
  # up in Internation Allowance (ISell).  Negative numbers are
  # flows from QC to CA.
  #
  elseif ISaleSw[market] == 5
    ISell[market] = max(min(Emissions[market]+FBuy[market]-FSell[market]-OffTotal[market]+PInvChange[market]-
                    Target[market],xXISell[market]),0-xXISell[market])

  #
  # Domestic Permits after Offsets and International Permits
  #
  elseif ISaleSw[market] == 3
    FISell = max(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],0)
    ISell[market] = max(min(xXFSell[market]-IRTotal+FBuy[market]-OffTotal[market]+PInvChange[market],FISell,xXISell[market]),0)
    FSell[market] = max(FISell-ISell[market],0)

  #
  # Unlimited Domestic Permits (ISaleSw[market] == 2)
  #
  elseif ISaleSw[market] == 2
    if ETAFAP[market] > ETADAP[market]
      ISell[market] = 0
    else
      ISell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXISell[market]),0)
    end

    if CapTrade[market] == 6
      ISell[market] = xISell[market]
    end

    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+
      PInvChange[market]-ISell[market]-Target[market],xXFSell[market]),0)
      
   #if market == 141 
   #  @info " Off1Allo FSell      = $(FSell[market]/1e6) Market $market $CTime"
   #  @info " Off1Allo Emissions  = $(Emissions[market]/1e6) Market $market $CTime"     
   #  @info " Off1Allo Target     = $(Target[market]/1e6) Market $market $CTime"
   #  @info " Off1Allo xXFSell    = $(xXFSell[market]/1e6) Market $market $CTime"
   #  @info " Off1Allo FBuy       = $(FBuy[market]/1e6) Market $market $CTime"
   #  @info " Off1Allo OffTotal   = $(OffTotal[market]/1e6) Market $market $CTime"
   #  @info " Off1Allo PInvChange = $(PInvChange[market]/1e6) Market $market $CTime"
   #  @info " Off1Allo ISell      = $(ISell[market]/1e6) Market $market $CTime"
   #end
   
  #
  # Unlimited International Permits (ISaleSw[market] == 1)
  #
  elseif ISaleSw[market] == 1
    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXFSell[market]),0)
    ISell[market] = max(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-FSell[market]-Target[market],0)

  #
  # TODOJulia - review switches - Jeff Amlin 3/3/25 
  #
  # BC LCFS
  #
  elseif CapTrade[market] == 7
    FSell[market] = xFSell[market]
    ISell[market] = 0.0

  #
  # Domestic and International Permits Allocated based on Prices (ISaleSw[market] == 0)
  #
  elseif (ETAPr[market]/InflationUS[US] > ETAFAP[market]) && (ETAPr[market]/InflationUS[US] > ETADAP[market]) && (ETAFAP[market] >= ETADAP[market])
    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXFSell[market]),0)
    ISell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-FSell[market]-Target[market],xXISell[market]),0)

  elseif (ETAPr[market]/InflationUS[US] > ETAFAP[market]) && (ETAPr[market]/InflationUS[US] > ETADAP[market]) && (ETAFAP[market] < ETADAP[market])
    ISell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXISell[market]),0)
    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-ISell[market]-Target[market],xXFSell[market]),0)

  elseif (ETAPr[market]/InflationUS[US] <= ETAFAP[market]) && (ETAPr[market]/InflationUS[US] <= ETADAP[market]) && (ETAFAP[market] >= ETADAP[market])
    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXFSell[market]),0)
    ISell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-FSell[market]-Target[market],xXISell[market]),0)

  elseif (ETAPr[market]/InflationUS[US] <= ETAFAP[market]) && (ETAPr[market]/InflationUS[US] <= ETADAP[market]) && (ETAFAP[market] < ETADAP[market])
    ISell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXISell[market]),0)
    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-ISell[market]-Target[market],xXFSell[market]),0)

  elseif (ETAPr[market]/InflationUS[US] <= ETAFAP[market]) && (ETAPr[market]/InflationUS[US] > ETADAP[market])
    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXFSell[market]),0)
    ISell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-FSell[market]-Target[market],xXISell[market]),0)

  else
    ISell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-Target[market],xXISell[market]),0)
    FSell[market] = max(min(Emissions[market]+FBuy[market]-OffTotal[market]+PInvChange[market]-ISell[market]-Target[market],xXFSell[market]),0)
  end

  WriteDisk(db,"SOutput/FSell",year,FSell)
  WriteDisk(db,"SOutput/ISell",year,ISell)

  #
  # Permits Auctioned (will PAuction always equal xPAuction?)
  #
  PAuction[market] = xPAuction[market]

  WriteDisk(db,"SOutput/PAuction",year,PAuction)

  #
  # Update the TIF Inventory
  #
  FInventory[market] = FInventoryPrior[market]+FBuy[market]-FSell[market]

  if FInvRev[market] != -99
    FInvRev[market] = FInvRevPrior[market]+(FSell[market]*ETADAP[market]*InflationUS[US]-FBuy[market]*ETAPr[market])/1e6
  end

  #
  # Overage before adjustment to Banking
  #
  OverBAB[market] = Emissions[market]-OffTotal[market]+PInvChange[market]+FBuy[market]-FSell[market]-ISell[market]-Target[market]
  WriteDisk(db,"SOutput/OverBAB",year,OverBAB)

  #
  # Force Redemption of Banked Allowances to meet Goal (PBnkSw=1)
  #
  if (PBnkSw[market] == 1) && (OverBAB[market] > 0.00)
    
    #
    # Allowances in Bank
    #
    PInvTot = sum(PInventoryPrior[ecc,poll,area] for area in areas, poll in polls, ecc in eccs)

    #
    # Additional Allowances sold from Bank to meet Goal
    #
    for area in areas, poll in polls, ecc in eccs
      @finite_math PRedAdd[ecc,poll,area] = PInventoryPrior[ecc,poll,area]/PInvTot*min(OverBAB[market],PInvTot)
      PRedAdd[ecc,poll,area] = min(PRedAdd[ecc,poll,area],PInventoryPrior[ecc,poll,area]+PBank[ecc,poll,area]-PRedeem[ecc,poll,area])

      #
      # Adjust Allowances Redeemed and Sold
      #
      PRedeem[ecc,poll,area] = PRedeem[ecc,poll,area]+PRedAdd[ecc,poll,area]
      PSell[ecc,poll,area] = PSell[ecc,poll,area]+PRedAdd[ecc,poll,area]
    end

    WriteDisk(db,"SOutput/PRedeem",year,PRedeem)
    WriteDisk(db,"SOutput/PSell",year,PSell)

  end

  #
  # Force Buying and Banking of Allowances when Goal is
  # exceeded (PBnkSw=1 or PBnkSw=2)
  #
  if ((PBnkSw[market] == 1) || (PBnkSw[market] == 2)) && (OverBAB[market] < 0.00)
    
    #
    # Covered Emissions to allocate Banking
    #
    for area in areas, poll in polls, ecc in eccs
      PBnkPolCov[ecc,poll,area] = sum(PolCov[ecc,poll,pcov,area] for pcov in PCovs)
    end

    PBnkTot = sum(PBnkPolCov[ecc,poll,area] for area in areas, poll in polls, ecc in eccs)
    
    #
    # Additional Allowances Banked (PBnkAdd) is equal to Overage (OverBAB),
    # but must be allocated (PBnkPolCov/PBnkTot).
    #
    for area in areas, poll in polls, ecc in eccs
      PBnkAdd[ecc,poll,area] = PBnkPolCov[ecc,poll,area]/PBnkTot*(0-OverBAB[market])
    end

    #
    # Adjust Allowances Bought and Banked
    #
    for area in areas, poll in polls, ecc in eccs
      PBank[ecc,poll,area] = PBank[ecc,poll,area]+PBnkAdd[ecc,poll,area]
      PBuy[ecc,poll,area] = PBuy[ecc,poll,area]+PBnkAdd[ecc,poll,area]
    end

    WriteDisk(db,"SOutput/PBank",year,PBank)
    WriteDisk(db,"SOutput/PBuy",year,PBuy)

  end

  #
  # Update Bank Inventory
  #
  for area in areas, poll in polls, ecc in eccs
    PInventory[ecc,poll,area] = PInventoryPrior[ecc,poll,area]+DT*(PBank[ecc,poll,area]-PRedeem[ecc,poll,area])
  end

end # Off1Allocation

function AveCostOfPermits(data::Data,market,areas,eccs,polls)
  (; db,year) = data
  (; Nation,Market) = data
  (; ETADAP,ETAFAP,ETAPr,ETAvPr,FBuy,FSell,InflationUS,ISell,PBuy) = data
  MBuy::VariableArray{1} = zeros(Float32,length(Market)) # Permits Purchased from Market (Tonnes/Yr)

  US = Select(Nation,"US")
  
  #@info "  SuPollutionMarket.jl - AveCostOfPermits"

  #
  # The average cost of permits (ETAvPr) are the market purchases (MBuy)
  # times the marginal price (ETAPr), the federal allowances (FSell)
  # times the domestic allowace price (ETADAP), plus the international
  # permits (ISell) times the international prices (ETAFAP).
  #
  MBuy[market] = sum(PBuy[ecc,poll,area] for area in areas, poll in polls, ecc in eccs)+
                 FBuy[market]-FSell[market]-ISell[market]
                 
  @finite_math ETAvPr[market] =
    (MBuy[market]*ETAPr[market]+
    FSell[market]*ETADAP[market]*InflationUS[US]+
    ISell[market]*ETAFAP[market]*InflationUS[US])/
    (MBuy[market]+FSell[market]+ISell[market])

  WriteDisk(db,"SOutput/ETAvPr",year,ETAvPr)

end

function ExpendPermit(data::Data,market,areas,eccs,polls)
  (; db,year,CTime) = data
  (; Area,ECC,Market,Nation,PCov,Poll) = data
  (; CBSw,Enforce,ETADAP,ETAEff,ETAFAP,ETAPr,ETAvPr,ExchangeRate) = data
  (; FInvRev,FSell,GPNGSw,GPOilSw,ISaleSw,InflationUS,ISell) = data
  (; PAucRev,PAuction,PBuy,PExp,PSell) = data
  (; RetPol) = data
  ExpInt::VariableArray{1} = zeros(Float32,length(Market)) # Expenditures for International Permits (US$ Millions)'
  ExpTot::VariableArray{1} = zeros(Float32,length(Market)) # Total Expenditures for Permits (US$ Millions)'

  ON = Select(Area,"ON")
  miscellaneous = Select(ECC,"Miscellaneous")
  US = Select(Nation,"US")
  CO2 = Select(Poll,"CO2")

  #@info "  SuPollutionMarket.jl - ExpendPermit for Market $market"
  #
  # Markets are often initiated in the model before the time when the
  # regulations are enforced.  This allows for early adapters.  The
  # first year the regulations are enforced (Enforce) is when the
  # participants begin buying and selling permits and inventory
  # the excess.
  #
  if Enforce[market] <= CTime
    
    #
    # If this is a cap and trade market (CBSw=0 or CBSw=1) then we
    # assume that the lower cost of offsets, international permits,
    # domestic permits, etc. are shared amoung all the market
    # participants and thus the effective price (ETAEff) they
    # all pay is equal to the average price (ETAvPr).
    #
    if (CBSw[market] == 0) || (CBSw[market] == 1)
      ETAEff[market] = ETAvPr[market]

    #
    # Else this is an emissions tax (CBSw=2 or CBSw=3) where the
    # govenenment pays for all the offsets, international permits,
    # domestic permits, etc. The effective price (ETAEff) for market
    # participants is the marginal price (ETAPr).
    #
    elseif (CBSw[market] == 2) || (CBSw[market] == 3)
      ETAEff[market] = ETAPr[market]
    end

    #
    # Permit Expenditure (PExp) are the permits purchased (PBuy) minus
    # permits sold times the effective permit price (ETAEff)
    #
    for area in areas, poll in polls, ecc in eccs
      PExp[ecc,poll,area] = PExp[ecc,poll,area]+
        (PBuy[ecc,poll,area]-PSell[ecc,poll,area])*ETAEff[market]*ExchangeRate[area]/1e6
    end

    #
    # If Petroleum industry must purchses GHG permits for RPP retail customers, then
    # the impact of the permits on the RPP retail customers is reflected in FPPolTaxF;
    # therefore for the Petroleum industry report permit expenditures (PExp) only
    # for the emissions generated by the Petroleum industry.
    #
    pcov = Select(PCov,"Oil")
    if GPOilSw[market] != 0
      for area in areas, poll in polls
        
        #
        # Emissions from retail customers
        #
        RetPol[poll,area] = sum(PolTot[ecc,poll,pcov,area]*PolConv[poll] for ecc in eccs)

        for ecc in ECCs
          if ((ECC[ecc] == "Petroleum") || (ECC[ecc] == "OilRefineries"))
            
            #
            # Remove cost of retail permits from producer permit expenditures
            #
            PExp[ecc,poll,area] = PExp[ecc,poll,area]-
              RetPol[poll,area]*ETAEff[market]*ExchangeRate[area]/1e6
          end
        end
      end
    end

    #
    # If Natural Gas Distributors must purchses GHG permits for retail Natural Gas
    # customers, then the impact of the permits on the retail Natural Gas customers
    # is reflected in FPPolTaxF; therefore for the Natural Gas Distributors report
    # permit expenditures (PExp) only for the emissions generated by the Natural
    # Gas Distributors.
    #
    pcov = Select(PCov,"NaturalGas")
    if GPNGSw[market] != 0
      for area in areas, poll in polls
        
        #
        # Emissions from retail customers
        #
        RetPol[poll,area] = sum(PolTot[ecc,poll,pcov,area]*PolConv[poll] for ecc in eccs)

        for ecc in ECCs
          if (ECC[ecc] == "NGDistribution")
            
            #
            # Remove cost of retail permits from producer permit expenditures
            #
            PExp[ecc,poll,area] = PExp[ecc,poll,area]-
              RetPol[poll,area]*ETAEff[market]*ExchangeRate[area]/1e6
          end
        end
      end
    end

    #
    # Government Revenues - If this is an emissions tax (CBSw=2), then
    # permit expenditures (PExp) net of the cost of international
    # permits (ISell*ETAFAP) are added to government revenues (government
    # revenues are stored in Miscellaneous).
    #
    if CBSw[market] == 2
      ExpTot[market] = sum(PExp[ecc,poll,area]/ExchangeRate[area] 
        for area in areas, poll in polls, ecc in eccs)
      
      ExpInt[market] = ISell[market]*ETAFAP[market]/1e6
      
      for area in areas, poll in polls
        PExp[miscellaneous,poll,area] = PExp[miscellaneous,poll,area]+
              sum(PExp[ecc,poll,area] for ecc in eccs)/
              ExpTot[market]*(ExpTot[market]-ExpInt[market])*ExchangeRate[area]
      end
    end

    #
    # Permit Auction Revenues - if there is an auction (CBSw=1), then
    # the permits auctioned (PAuction) times the permit price (ETAPr)
    # are added to government revenues "PExp(Miscellaneous,P,A)"
    #
    if CBSw[market] == 1
      PAucRev[market] = PAuction[market]*ETAPr[market]/1e6
      PExp[miscellaneous,CO2,ON] = PExp[miscellaneous,CO2,ON]+
                                PAucRev[market]*ExchangeRate[ON]

      WriteDisk(db,"SOutput/ETAvPr",year,ETAvPr)

    end

    #
    # If TIF Revenues are not used to buy permits (FInvRev == -99),
    # then add them to the government revuenues (PExp(Miscellaneous,P,A))
    # If ISaleSw equals 6, then the internation permit variable (ISell)
    # actually holds the second tier of the domestic permits.
    #
    if FInvRev[market] == -99
      PExp[miscellaneous,CO2,ON] = PExp[miscellaneous,CO2,ON]+
                  FSell[market]*ETADAP[market]*InflationUS[US]*ExchangeRate[ON]/1e6
      if ISaleSw[market] == 6
        PExp[miscellaneous,CO2,ON] = PExp[miscellaneous,CO2,ON]+
                  ISell[market]*ETAFAP[market]*InflationUS[US]*ExchangeRate[ON]/1e6
      end
    end

  end

end # ExpendPermit

function HardCap(data::Data,market,CIt,NIt,PIt,areas,eccs,polls)
  (; db,year) = data
  (; DoneM,GoalPol,GrossPolPrior,GrossTot,PolConv,RPolicy) = data

  #@info "  SuPollutionMarket.jl - HardCap for Market $market"

  #
  # The policy reduction (RPolicy) is the pollution goal (GoalPol)
  # divided by the gross pollution (GrossPol).
  #
  GrossTot[market] = sum(GrossPolPrior[ecc,poll,area]*PolConv[poll] for area in areas, poll in polls, ecc in eccs)
  for area in areas, poll in polls, ecc in eccs
    if GrossTot[market] > 0.0
      RPolicy[ecc,poll,area] = 1-min(max(GoalPol[market]/GrossTot[market],0),1.0)
    else
      RPolicy[ecc,poll,area] = 0.0
    end
  end

  WriteDisk(db,"SOutput/RPolicy",year,RPolicy)
  WriteDisk(db,"SOutput/GrossTot",year,GrossTot)

  #
  # After two iterations, the hard cap should be close enough.
  #
  if CIt >= 2
    DoneM[market] = 0
    WriteDisk(db,"SOutput/DoneM",DoneM)
  end

end

function ImpactOnFuelPrices(data::Data)
  (; db,year,CTime) = data
  (; ECC,Markets,Nation,Poll) = data
  (; AreaMarket,CapTrade,ECCMarket,eCO2Price,Enforce) = data
  (; ETABY,ETAPr,ExchangeRate,InflationUS) = data
  (; PCost,PolConv,PollMarket) = data

  #@info "  SuPollutionMarket.jl - ImpactOnFuelPrices "

  US = Select(Nation,"US")
  CO2 = Select(Poll,"CO2")

  #
  # The trading allowances impact fuel prices for the next year.
  #
  # For each Market select the relevant Pollutant
  #
  @. PCost = 0.0
  @. eCO2Price = 0.0
  for market in Markets
    if (CapTrade[market] != 0) && (CapTrade[market] != 6) && (CapTrade[market] != 8)
      
      areas,eccs,polls,ValidMarket = GetMarketSets(data::Data,market)
      if ValidMarket

        #
        # Accumulate Permit Costs (PCost) converted from $/Tonnes eCO2 to $/Tonnes
        # The value of PolConv is 1.0 for non-GHG pollutants.
        #
        for ecc in eccs
          if ECC[ecc] != "UtilityGen"
            for area in areas, poll in polls
              @finite_math PCost[ecc,poll,area] = PCost[ecc,poll,area]+
                ETAPr[market]/PolConv[poll]/InflationUS[US]*ExchangeRate[area]
            end

          #
          # Electric Generation does not get early signal
          #
          elseif ETABY[market] <= CTime
            for area in areas, poll in polls
              @finite_math PCost[ecc,poll,area] = PCost[ecc,poll,area]+
                ETAPr[market]/PolConv[poll]/InflationUS[US]*ExchangeRate[area]
            end

          end # if "UtilityGen"
        end # eccs

        #
        # Maximum CO2 Price in the Nation
        #
        if (PollMarket[CO2,market] == 1) && (Enforce[market] <= CTime)
          for area in areas
            eCO2Price[area] = max(eCO2Price[area],ETAPr[market]*ExchangeRate[area])
          end
        end
      end # if AreaMarket, etc
    end # CapTrade
  end # Do Market

  WriteDisk(db,"SOutput/eCO2Price",year,eCO2Price)
  WriteDisk(db,"SOutput/PCost",year,PCost)

end

function ImpactOnFuelPricesNext(data::Data)
  (; db,next) = data
  (; ECC,Markets,Nation,Poll) = data
  (; AreaMarket,CapTrade,ECCMarket,eCO2PriceNext,Enforce) = data
  (; ETABY,ETAPr,ETAPrNext,ExchangeRateNext,InflationUSNext) = data
  (; PCostNext,PolConv,PollMarket) = data

  #@info "  SuPollutionMarket.jl - ImpactOnFuelPricesNext "

  US = Select(Nation,"US")
  CO2 = Select(Poll,"CO2")
  NextTime = next+ITime-1
  
  #
  # The trading allowances impact fuel prices for the next year.
  #
  # For each Market select the relevant Pollutant
  #
  @. PCostNext = 0.0
  @. eCO2PriceNext = 0.0
  for market in Markets
    if (CapTrade[market] != 0) && (CapTrade[market] != 6)
      areas,eccs,polls,ValidMarket = GetMarketSets(data::Data,market)
      if ValidMarket
      
        #
        # Accumulate Permit Costs (PCost) converted from $/Tonnes eCO2 to $/Tonnes
        # The value of PolConv is 1.0 for non-GHG pollutants.
        #
        for ecc in eccs
          if ECC[ecc] != "UtilityGen"
            for area in areas, poll in polls
              @finite_math PCostNext[ecc,poll,area] = PCostNext[ecc,poll,area]+
                ETAPrNext[market]/PolConv[poll]/InflationUSNext[US]*ExchangeRateNext[area]
            end

          #
          # Electric Generation does not get early signal
          #
          elseif ETABY[market] <= NextTime
            for area in areas, poll in polls
              @finite_math PCostNext[ecc,poll,area] = PCostNext[ecc,poll,area]+
                ETAPrNext[market]/PolConv[poll]/InflationUSNext[US]*ExchangeRateNext[area]
            end

          end # if "UtilityGen"
        end # eccs

        #
        # Maximum CO2 Price in the Nation
        #
        if (PollMarket[CO2,market] == 1) && (Enforce[market] <= NextTime)
          for area in areas
            eCO2PriceNext[area] = max(eCO2PriceNext[area],ETAPr[market]*ExchangeRateNext[area])
          end
        end
      end # if AreaMarket, etc
    end # CapTrade
  end # Do Market

  WriteDisk(db,"SOutput/eCO2Price",next,eCO2PriceNext)
  WriteDisk(db,"SOutput/PCost",next,PCostNext)

end

function CapControl(data::Data,CIt,NIt,PIt)
  (; Markets) = data
  (; AreaMarket,CapTrade,ECCMarket,PollMarket) = data

  #@info "  SuPollutionMarket.jl - CapControl"

  #
  # Permits and Emissions Trading (Current Year)
  #
  for market in Markets
    if CapTrade[market] != 0
      areas,eccs,polls,ValidMarket = GetMarketSets(data::Data,market)
      if ValidMarket

        #
        # Emissions Goal
        #
        GetGoalPol(data,market)
          
        #
        # Policy is a Hard Cap (CapTrade = 2)
        #
        if CapTrade[market] == 2
          HardCap(data,market,CIt,NIt,PIt,areas,eccs,polls)
        end
      end
    end
  end

end

function Control(data::Data,CIt,NIt,PIt,DoneG)
  (; db,year) = data
  (; Markets) = data
  (; AreaMarket,CapTrade,DoneM,ECCMarket,ETAPr,FSell,PInventory,PollMarket,xFSell) = data

  #@debug "SuPollutionMarket.jl - Control"

  CoveredEmissions(data)
  
  #
  # Permits and Emissions Trading (Current Year)
  #
  for market in Markets
    if CapTrade[market] != 0
      areas,eccs,polls,ValidMarket = GetMarketSets(data::Data,market)
      if ValidMarket

        #
        # Number of gratis permits and the pollution goal
        #
        GetGratisPermits(data,market,areas,eccs,polls)
        GetGoalPol(data,market)
          
        #
        # Do if policy is a cap with trading (CapTrade = 1)
        # TODOSimplify - are we ready to remove CapTrade = 1 - Jeff Amlin 2/28/25
        #
        if (CapTrade[market] == 1) && ((DoneM[market] != 0) || (DoneG == 0)) 
          #@info "  SuPollutionMarket.jl - Control: CapTrade[market] == 1 not currently implemented. Market $market"

          # MarketOffsets(data,market,areas,polls)
          # BuySellPermits(data,market,areas,eccs,polls)
          # CostOfPermits(data,market,CIt,NIt,PIt,areas,eccs,polls)

        #
        # Else Policy is a Hard Cap (CapTrade = 2)
        #
        elseif (CapTrade[market] == 2) && ((DoneM[market] != 0) || (DoneG == 0))   
          HardCap(data,market,CIt,NIt,PIt,areas,eccs,polls)
            
        #
        # Else Policy is a Pollution Tax (CapTrade=3) with no trading
        # which means no pollution carry over or inventory
        # TODOSimplify - are we ready to remove CapTrade = 3 - Jeff Amlin 2/28/25
        #
        elseif (CapTrade[market] == 3) && ((DoneM[market] != 0) || (DoneG == 0)) 
          #@info "  SuPollutionMarket.jl - Control: CapTrade[market] == 3 not currently implemented."
          for area in areas, poll in polls, ecc in eccs
            PInventory[ecc,poll,area] = 0
          end
          # MarketOffsets(data,market,areas,polls)
          # BuySellPermits(data,market,areas,eccs,polls)
          # CostOfPermits(data,market,CIt,NIt,PIt,areas,eccs,polls)

        #
        # Else Policy are Hard Caps for individual sectors
        #
        elseif (CapTrade[market] == 4) && ((DoneM[market] != 0) || (DoneG == 0))
          #@info "  SuPollutionMarket.jl - Control: CapTrade[market] == 4 not currently implemented."

          DoneM[market] = 0

        #
        # Else GHG Market
        #
        elseif (CapTrade[market] == 5) && (DoneM[market] != 0)  # CapTrade[market] == 5 Seems Yes
          MarketOffsets(data,market,areas,polls)
          BuySellPermits(data,market,areas,eccs,polls)
          CostOfPermits(data,market,CIt,NIt,PIt,areas,eccs,polls)

        #
        # Else CFS Market
        #
        elseif ((CapTrade[market] == 6) || (CapTrade[market] == 7)) && (DoneM[market] != 0) # CapTrade[market] == 6 or 7 Seems Yes
          FSell[market] = xFSell[market]
          CostOfPermits(data,market,CIt,NIt,PIt,areas,eccs,polls)

        #
        # Else OGEC Market
        #
        elseif (CapTrade[market] == 8) && (DoneM[market] != 0)
          DoneM[market]=0
        end # if CapTrade
      end # if ValidMarket
    else # CapTrade == 0
      ETAPr[market] = 0
      WriteDisk(db,"SOutput/ETAPr",year,ETAPr)
    end
  end

  #
  # Apply Cost of Pollution Permits to Fuel Prices for this year and next year
  #
  ImpactOnFuelPrices(data)
  ImpactOnFuelPricesNext(data)

  #
  # Are all markets Done?
  #
  WriteDisk(db,"SOutput/DoneM",DoneM)

end # function Control

function FinalizeMarkets(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Markets,Polls) = data
  (; AreaMarket,CapTrade,ECCMarket,PollMarket) = data
  (; eCO2Price,ExchangeRate,FInventory,FInvRev,OffRevenue,Offsets,PExp,PExpGross,PInventory) = data

  #@info "SuPollutionMarket.jl - FinalizeMarkets"

  # Read Disk(FInventory,PInventory)
  @. PExp = 0.0
  @. OffRevenue = 0.0
  
  for market in Markets
    if CapTrade[market] != 0 && CapTrade[market] != 6 && CapTrade[market] != 8
      areas,eccs,polls,ValidMarket = GetMarketSets(data::Data,market)
      if ValidMarket    
        Off1Allocation(data,market,areas,eccs,polls)
        AveCostOfPermits(data,market,areas,eccs,polls)
        ExpendPermit(data,market,areas,eccs,polls)
      end
    end
  end

  #
  #  Offsets are in Tonnes eCO2, use eCO2Price for Offset Revenues - Jeff Amlin 5/7/25
  #
  for area in Areas, poll in Polls, ecc in ECCs
    PExpGross[ecc,poll,area] = PExp[ecc,poll,area]
    OffRevenue[ecc,poll,area] = Offsets[ecc,poll,area]*eCO2Price[area]*ExchangeRate[area]/1e6
    PExp[ecc,poll,area] = PExpGross[ecc,poll,area]-OffRevenue[ecc,poll,area]
  end

  WriteDisk(db,"SOutput/FInventory",year,FInventory)
  WriteDisk(db,"SOutput/OffRevenue",year,OffRevenue)
  WriteDisk(db,"SOutput/PExp",year,PExp)
  WriteDisk(db,"SOutput/PExpGross",year,PExpGross)
  WriteDisk(db,"SOutput/PInventory",year,PInventory)

  for market in Markets
    if FInvRev[market] != -99
      WriteDisk(db,"SOutput/FInvRev",year,FInvRev)
    end
  end

end

end # module SuPollutionMarket
