#
# SpOGProd.jl
#

module SpOGProd

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,HisTime,Last,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelOG::SetArray = ReadDisk(db,"MainDB/FuelOGKey")
  FuelOGs::Vector{Int} = collect(Select(FuelOG))
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  PI::SetArray = ReadDisk(db,"SInput/PIKey")
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  ProcOG::SetArray = ReadDisk(db,"MainDB/ProcOGKey")
  ProcOGs::Vector{Int} = collect(Select(ProcOG))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  OGRefName::String = ReadDisk(db,"MainDB/OGRefName") #  Oil/Gas Reference Case Name
  OGRefNameDB::String = ReadDisk(db,"MainDB/OGRefNameDB") #  Oil/Gas Reference Case Name

  LastExo::Int = 2040-ITime+1

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  ByFrac::VariableArray{1} = ReadDisk(db,"SpInput/ByFrac",year) #[OGUnit,Year]  Byproducts Fraction (Btu/Btu)
  ByPrice::VariableArray{1} = ReadDisk(db,"SpOutput/ByPrice",year) #[OGUnit,Year]  Byproducts Price ($/mmBtu)
  ByRev::VariableArray{1} = ReadDisk(db,"SpOutput/ByRev",year) #[OGUnit,Year]  Byproducts Revenue ($/mmBtu)
  CCMDem::VariableArray{1} = ReadDisk(db,"SpOutput/CCMDem",year) #[OGUnit,Year]  Capital Cost Multiplier from Demand Module ($/$)
  CCMDemSw::VariableArray{1} = ReadDisk(db,"SpInput/CCMDemSw",year) #[OGUnit,Year]  Switch to Activate the Capital Cost Multiplier (1 = on)
  DemCCMult::VariableArray{2} = ReadDisk(db,"SOutput/DemCCMult",year) #[ECC,Area,Year]  Demand Capital Cost Multiplier ($/$)
  DemCCMultPrior::VariableArray{2} = ReadDisk(db,"SOutput/DemCCMult",prior) #[ECC,Area,Year]  Demand Capital Cost Multiplier ($/$)
  DemRq::VariableArray{3} = ReadDisk(db,"SOutput/DemRq",year) #[Fuel,ECC,Area,Year]  Marginal Energy Demand (TBtu/Driver)
  DemRqPrior::VariableArray{3} = ReadDisk(db,"SOutput/DemRq",prior) #[Fuel,ECC,Area,Year]  Marginal Energy Demand (TBtu/Driver)
  Dev::VariableArray{1} = ReadDisk(db,"SpOutput/Dev",year) #[OGUnit,Year]  Development of Resources (TBtu/Yr)
  DevCap::VariableArray{1} = ReadDisk(db,"SpOutput/DevCap",year) #[OGUnit,Year]  Development Capital Costs ($/mmBtu)
  DevDep::VariableArray{1} = ReadDisk(db,"SpOutput/DevDep",year) #[OGUnit,Year]  Development Depreciation ($/mmBtu)
  DevDM::VariableArray{1} = ReadDisk(db,"SpOutput/DevDM",year) #[OGUnit,Year]  Development Cost Delpletion Multiplier ($/$)
  DevDMB0::VariableArray{1} = ReadDisk(db,"SpInput/DevDMB0",year) #[OGUnit,Year]  Development Costs Depletion Multiplier Coefficient ($/$)
  DevDMRef::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/DevDM",year) #[OGUnit,Year]  Development Cost Delpletion Multiplier in Reference Case ($/$)
  DevExp::VariableArray{1} = ReadDisk(db,"SpOutput/DevExp",year) #[OGUnit,Year]  Development Expenses ($/mmBtu)
  DevIM::VariableArray{1} = ReadDisk(db,"SpOutput/DevIM",year) #[OGUnit,Year]  Development Cost Infrastructure Multiplier ($/$)
  DevITax::VariableArray{1} = ReadDisk(db,"SpOutput/DevITax",year) #[OGUnit,Year]  Development Income Taxes ($/mmBtu)
  DevLCM::VariableArray{1} = ReadDisk(db,"SpOutput/DevLCM",year) #[OGUnit,Year]  Development Cost Learning Curve Multiplier ($/$)
  DevLCMB0::VariableArray{1} = ReadDisk(db,"SpInput/DevLCMB0",year) #[OGUnit,Year]  Development Costs Learning Curve Multiplier Coefficient ($/$)
  DevMaxM::VariableArray{1} = ReadDisk(db,"SpInput/DevMaxM",year) #[OGUnit,Year]  Development Rate Maximum Multiplier from ROI (Btu/Btu)
  DevMinM::VariableArray{1} = ReadDisk(db,"SpInput/DevMinM",year) #[OGUnit,Year]  Development Rate Minimum Multiplier from ROI (Btu/Btu)
  DevNtInc::VariableArray{1} = ReadDisk(db,"SpOutput/DevNtInc",year) #[OGUnit,Year]  Development Net Income ($/mmBtu)
  DevOG::VariableArray{2} = ReadDisk(db,"SpOutput/DevOG",year) #[ProcOG,Area,Year]  Development of Resources (TBtu/Yr)
  DevRaOG::VariableArray{2} = ReadDisk(db,"SpOutput/DevRaOG",year) #[ProcOG,Area,Year]  Development Rate (TBtu/TBtu)
  DevRate::VariableArray{1} = ReadDisk(db,"SpOutput/DevRate",year) #[OGUnit,Year]  Development Rate (Btu/Btu)
  DevRateM::VariableArray{1} = ReadDisk(db,"SpOutput/DevRateM",year) #[OGUnit,Year]  Development Rate Multiplier (Btu/Btu)
  DevRateMRef::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/DevRateM",year) #[OGUnit,Year]  Development Rate Multiplier (Btu/Btu)
  DevROI::VariableArray{1} = ReadDisk(db,"SpOutput/DevROI",year) #[OGUnit,Year]  Development Return on Investment ($/$)
  DevROIRef::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/DevROI",year) #[OGUnit,Year]  Reference Case Development Return on Investment ($/$)
  DevROIRefLastExo::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/DevROI",LastExo) #[OGUnit,LastExo]  Development Return on Investment in Last Year of Exogenous Forecast ($/$)
  DevSw::VariableArray{1} = ReadDisk(db,"SpInput/DevSw",year) #[OGUnit,Year]  Development Switch
  DevVar::VariableArray{1} = ReadDisk(db,"SpInput/DevVar",year) #[OGUnit,Year]  Development Rate Variance (Btu/Btu)
  DevVF::VariableArray{1} = ReadDisk(db,"SpInput/DevVF",year) #[OGUnit,Year]  Development Rate Variance Factor for ROI (Btu/Btu)
  DilCosts::VariableArray{1} = ReadDisk(db,"SpOutput/DilCosts",year) #[OGUnit,Year]  Diluent Costs ($/mmBtu)
  DilFrac::VariableArray{1} = ReadDisk(db,"SpInput/DilFrac",year) #[OGUnit,Year]  Diluent Fraction (Btu/Btu)
  DilPrice::VariableArray{1} = ReadDisk(db,"SpOutput/DilPrice",year) #[OGUnit,Year]  Diluent Price ($/mmBtu)
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  ExchangeRateNation::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateNation",year) #[Nation,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  FkCosts::VariableArray{1} = ReadDisk(db,"SpOutput/FkCosts",year) #[OGUnit,Year]  Feedstock Costs ($/mmBtu)
  FkFrac::VariableArray{1} = ReadDisk(db,"SpInput/FkFrac",year) #[OGUnit,Year]  Feedstock Fraction (Btu/Btu)
  FkPrice::VariableArray{1} = ReadDisk(db,"SpOutput/FkPrice",year) #[OGUnit,Year]  Feedstock Price ($/mmBtu)
  FlCosts::VariableArray{2} = ReadDisk(db,"SOutput/FlCosts",year) #[ECC,Area,Year]  Flaring Reduction Costs ($/TBtu)
  FPECC::VariableArray{3} = ReadDisk(db,"SOutput/FPECC",year) #[Fuel,ECC,Area,Year]  Fuel Prices excluding Emission Costs ($/mmBtu)
  FPECCCFSNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSNet",year) #[Fuel,ECC,Area,Year]  Incremental CFS Price ($/mmBtu)
  FPECCCPNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCPNet",year) #[Fuel,ECC,Area,Year]  Net Carbon Price after OBA ($/mmBtu)
  FPECCOGEC::VariableArray{3} = ReadDisk(db,"SOutput/FPECCOGEC",year) #[Fuel,ECC,Area,Year]  Incremental OGEC Price ($/mmBtu)
  FuCosts::VariableArray{2} = ReadDisk(db,"SOutput/FuCosts",year) #[ECC,Area,Year]  Other Fugitives Reduction Costs ($/mmBtu)
  GasProcessingSwitch::VariableArray{1} = ReadDisk(db,"SpInput/GasProcessingSwitch",year) #[Area,Year]  Gas Processing Switch (1=Endogenous, 0 = Exogenous)
  GasProcessingFraction::VariableArray{2} = ReadDisk(db,"SpInput/GasProcessingFraction",year) #[Process,Area,Year]  Gas Processing Fraction (Btu/Btu)
  GasProductionMap::VariableArray{1} = ReadDisk(db,"SpInput/GasProductionMap") #[Process]  Gas Production Map (1=include)
  GAProd::VariableArray{2} = ReadDisk(db,"SOutput/GAProd",year) #[Process,Area,Year]  Primary Natural Gas Production (TBtu/Yr)
  G2NProd::VariableArray{1} = ReadDisk(db,"SpOutput/G2NProd",year) #[GNode,Year]  Natural Gas Production (TBtu/Yr)
  GProd::VariableArray{2} = ReadDisk(db,"SOutput/GProd",year) #[Process,Nation,Year]  Primary Natural Gas Production (TBtu/Yr)
  GRRMax::VariableArray{1} = ReadDisk(db,"SpInput/GRRMax",year) #[OGUnit,Year]  Maximum Gross Revenue Royalty Rate ($/$)
  GRRMin::VariableArray{1} = ReadDisk(db,"SpInput/GRRMin",year) #[OGUnit,Year]  Minimum Gross Revenue Royalty Rate ($/$)
  GRRPr::VariableArray{1} = ReadDisk(db,"SpInput/GRRPr",year) #[OGUnit,Year]  Gross Revenue Royalty Rate Slope to Price ($/$)
  GRRPr0::VariableArray{1} = ReadDisk(db,"SpInput/GRRPr0",year) #[OGUnit,Year]  Gross Revenue Royalty Rate Intercept ($/$)
  GRRRate::VariableArray{1} = ReadDisk(db,"SpOutput/GRRRate",year) #[OGUnit,Year]  Gross Revenue Royalty Rate ($/$)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationOGUnit::VariableArray{1} = ReadDisk(db,"MOutput/InflationOGUnit",year) #[OGUnit,Year]  Inflation Index ($/$)
  InflationNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) #[Nation,Year]  Inflation Index ($/$)
  LNGPM::Float32 = ReadDisk(db,"SpInput/LNGPM",year) #[Year]  LNG Price relative to Brent ($/$)
  LNGProdMin::VariableArray{1} = ReadDisk(db,"SOutput/LNGProdMin",year) #[Nation,Year]  LNG Production (TBtu/Yr)
  MeanEUR::VariableArray{1} = ReadDisk(db,"SpInput/MeanEUR",year) #[OGUnit,Year]  Mean Expected Ultimate Recovery (TBtu/Well)
  NetRev::VariableArray{1} = ReadDisk(db,"SpOutput/NetRev",year) #[OGUnit,Year]  Net Revenues for Royalty Calcuatlion ($/mmBtu)
  NewWells::VariableArray{1} = ReadDisk(db,"SpOutput/NewWells",year) #[OGUnit,Year]  Number of New Wells
  NGLiquidsFraction::VariableArray{2} = ReadDisk(db,"SpInput/NGLiquidsFraction",year) #[Process,Area,Year]  NG Liquids Production as a Fraction of NG Production (Btu/Btu)
  NRRMax::VariableArray{1} = ReadDisk(db,"SpInput/NRRMax",year) #[OGUnit,Year]  Maximum Net Revenue Royalty Rate ($/$)
  NRRMin::VariableArray{1} = ReadDisk(db,"SpInput/NRRMin",year) #[OGUnit,Year]  Minimum Net Revenue Royalty Rate ($/$)
  NRRPr::VariableArray{1} = ReadDisk(db,"SpInput/NRRPr",year) #[OGUnit,Year]  Net Revenue Royalty Rate Slope to Price ($/$)
  NRRPr0::VariableArray{1} = ReadDisk(db,"SpInput/NRRPr0",year) #[OGUnit,Year]  Net Revenue Royalty Rate Intercept ($/$)
  NRRRate::VariableArray{1} = ReadDisk(db,"SpOutput/NRRRate",year) #[OGUnit,Year]  Net Revenue Royalty Rate ($/$)
  OAProd::VariableArray{2} = ReadDisk(db,"SOutput/OAProd",year) #[Process,Area,Year]  Primary Oil Production (TBtu/Yr)
  OProd::VariableArray{2} = ReadDisk(db,"SOutput/OProd",year) #[Process,Nation,Year]  Primary Oil Production (TBtu/Yr)
  OGAbCFr::VariableArray{1} = ReadDisk(db,"SpInput/OGAbCFr",year) #[OGUnit,Year]  Abandonment Costs Fraction ($/$)
  OGAbCosts::VariableArray{1} = ReadDisk(db,"SpOutput/OGAbCosts",year) #[OGUnit,Year]  Abandonment Costs ($/mmBtu)
  OGArea::Vector{String} = ReadDisk(db,"SpInput/OGArea") #[OGUnit]  OG Unit Area
  OGCapCosts::VariableArray{1} = ReadDisk(db,"SpOutput/OGCapCosts",year) #[OGUnit,Year]  Capital Costs ($/mmBtu)
  OGCounter::Float32 = ReadDisk(db,"SpInput/OGCounter",year) #[Year]  Number of OG Units for this Year (Number)
  OGDep::VariableArray{1} = ReadDisk(db,"SpOutput/OGDep",year) #[OGUnit,Year]  Depreciation ($/mmBtu)
  DevDpRate::VariableArray{1} = ReadDisk(db,"SpInput/DevDpRate",year) #[OGUnit,Year]  Development Depreciation Rate ($/$)
  SusDpRate::VariableArray{1} = ReadDisk(db,"SpInput/SusDpRate",year) #[OGUnit,Year]  Sustaining Depreciation Rate ($/$)
  OAPrEORPrior::VariableArray{2} = ReadDisk(db,"SOutput/OAPrEOR",prior) #[Process,Area,Prior]  Oil Production from EOR (TBtu/Yr)
  OGCode::Vector{String} = ReadDisk(db,"MainDB/OGCode") #[OGUnit]  OG Unit Code
  OGECC::Vector{String} = ReadDisk(db,"SpInput/OGECC") #[OGUnit]  OG Unit ECC
  OGENPN::VariableArray{2} = ReadDisk(db,"SpOutput/OGENPN",year) #[FuelOG,Nation,Year]  Wholesale Price used to compute Product Price ($/mmBtu)
  OGFCosts::VariableArray{1} = ReadDisk(db,"SpOutput/OGFCosts",year) #[OGUnit,Year]  Fuel Costs ($/mmBtu)
  OGFMap::VariableArray{2} = ReadDisk(db,"SpInput/OGFMap") #[FuelOG,Fuel]  Map between FuelOG and Fuel
  OGFP::VariableArray{1} = ReadDisk(db,"SpOutput/OGFP",year) #[OGUnit,Year]  Product Price ($/mmBtu)
  OGFPAdd::VariableArray{1} = ReadDisk(db,"SpInput/OGFPAdd",year) #[OGUnit,Year]  Price Adder for Supply Cost Search ($/mmBtu)
  OGFPDChg::VariableArray{1} = ReadDisk(db,"SpInput/OGFPDChg",year) #[OGUnit,Year]  Product Price Delivery Charge ($/mmBtu)
  OGFPMax::VariableArray{1} = ReadDisk(db,"SpInput/OGFPMax",year) #[OGUnit,Year]  Maximum Price for Supply Cost Search ($/mmBtu)
  OGFPMin::VariableArray{1} = ReadDisk(db,"SpInput/OGFPMin",year) #[OGUnit,Year]  Inital Price for Supply Cost Search ($/mmBtu)
  OGFPrice::VariableArray{2} = ReadDisk(db,"SpOutput/OGFPrice",year) #[OGUnit,Fuel,Year]  Price for Fuel Purchased ($/mmBtu)
  OGFuel::Vector{String} = ReadDisk(db,"SpInput/OGFuel") #[OGUnit]  Fuel Type
  OGFUse::VariableArray{2} = ReadDisk(db,"SpOutput/OGFUse",year) #[OGUnit,Fuel,Year]  Fuel Usage (Btu/Btu)
  OGITxRate::VariableArray{1} = ReadDisk(db,"SpInput/OGITxRate",year) #[OGUnit,Year]  Income Tax Rate ($/$)
  OGName::Vector{String} = ReadDisk(db,"SpInput/OGNode") #[OGUnit]  OG Unit Name
  OGNation::Vector{String} = ReadDisk(db,"SpInput/OGNation") #[OGUnit]  OG Unit Nation
  OGNode::Vector{String} = ReadDisk(db,"SpInput/OGNode") #[OGUnit]  OG Unit Gas Transmission Node
  OGOGSw::Vector{String} = ReadDisk(db,"SpInput/OGOGSw") #[OGUnit]  OG Unit Oil or Gas Switch
  OGOMCosts::VariableArray{1} = ReadDisk(db,"SpOutput/OGOMCosts",year) #[OGUnit,Year]  O&M Costs ($/mmBtu)
  OGOpCosts::VariableArray{1} = ReadDisk(db,"SpOutput/OGOpCosts",year) #[OGUnit,Year]  Operatng Costs ($/mmBtu)
  OGPolCosts::VariableArray{1} = ReadDisk(db,"SpOutput/OGPolCosts",year) #[OGUnit,Year]  Pollution Costs ($/mmBtu)
  OGPolPrice::VariableArray{2} = ReadDisk(db,"SpOutput/OGPolPrice",year) #[OGUnit,Fuel,Year]  Pollution Cost for Fuel Purchased ($/mmBtu)
  OGPrSw::VariableArray{1} = ReadDisk(db,"SpInput/OGPrSw",year) #[OGUnit,Year]  OG Price Switch
  OGProcess::Vector{String} = ReadDisk(db,"SpInput/OGProcess") #[OGUnit]  OG Unit Production Process
  OGRev::VariableArray{1} = ReadDisk(db,"SpOutput/OGRev",year) #[OGUnit,Year]  Revenues ($/mmBtu)
  OGROIN::VariableArray{1} = ReadDisk(db,"SpInput/OGROIN",year) #[OGUnit,Year]  Return on Investment Normal ($/Yr/$)
  OpDM::VariableArray{1} = ReadDisk(db,"SpOutput/OpDM",year) #[OGUnit,Year]  Operating Cost Delpletion Multiplier ($/$)
  OpDMB0::VariableArray{1} = ReadDisk(db,"SpInput/OpDMB0",year) #[OGUnit,Year]  Operating Costs Depletion Multiplier Coefficient ($/$)
  OpDMRef::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/OpDM",year) #[OGUnit,Year]  Operating Cost Delpletion Multiplier in Reference Case ($/$)
  OpExp::VariableArray{1} = ReadDisk(db,"SpOutput/OpExp",year) #[OGUnit,Year]  Operating Expenses ($/mmBtu)
  OpLCM::VariableArray{1} = ReadDisk(db,"SpOutput/OpLCM",year) #[OGUnit,Year]  Operating Costs Learning Curve Multiplier ($/$)
  OpLCMB0::VariableArray{1} = ReadDisk(db,"SpInput/OpLCMB0",year) #[OGUnit,Year]  Operating Costs Learning Curve Multiplier Coefficient ($/$)
  OpWrkCap::VariableArray{1} = ReadDisk(db,"SpOutput/OpWrkCap",year) #[OGUnit,Year]  Operating Working Capital ($/mmBtu)
  OWCDays::VariableArray{1} = ReadDisk(db,"SpInput/OWCDays",year) #[OGUnit,Year]  Operating Working Capital Days Payment (Days)
  Pd::VariableArray{1} = ReadDisk(db,"SpOutput/Pd",year) #[OGUnit,Year]  Production (TBtu/Yr)
  PdC0OG::VariableArray{1} = ReadDisk(db,"SpInput/PdC0OG",year) #[OGUnit,Year]  Learning Curve Initial Cumulative Production (TBtu)
  PdCum::VariableArray{1} = ReadDisk(db,"SpOutput/PdCum",year) #[OGUnit,Year]  Cumulative Production (TBtu)
  PdCumPrior::VariableArray{1} = ReadDisk(db,"SpOutput/PdCum",prior) #[OGUnit,Year]  Cumulative Production (TBtu)
  PdCumOG::VariableArray{2} = ReadDisk(db,"SpOutput/PdCumOG",year) #[ProcOG,Area,Year]  Cumulative Production (TBtu)
  PdCumOGPrior::VariableArray{2} = ReadDisk(db,"SpOutput/PdCumOG",prior) #[ProcOG,Area,Year]  Cumulative Production (TBtu)
  PdExp::VariableArray{1} = ReadDisk(db,"SpOutput/PdExp",year) #[OGUnit,Year]  Production Expenses ($/mmBtu)
  PdITax::VariableArray{1} = ReadDisk(db,"SpOutput/PdITax",year) #[OGUnit,Year]  Production Income Taxes ($/mmBtu)
  PdMax::VariableArray{1} = ReadDisk(db,"SpInput/PdMax",year) #[OGUnit,Year]  Maximum Production Rate (Btu/Btu)
  PdMaxM::VariableArray{1} = ReadDisk(db,"SpInput/PdMaxM",year) #[OGUnit,Year]  Production Rate Maximum Multiplier from ROI (Btu/Btu)
  PdMinM::VariableArray{1} = ReadDisk(db,"SpInput/PdMinM",year) #[OGUnit,Year]  Production Rate Minimum Multiplier from ROI (Btu/Btu)
  PdNtInc::VariableArray{1} = ReadDisk(db,"SpOutput/PdNtInc",year) #[OGUnit,Year]  Production Net Income ($/mmBtu)
  PdOG::VariableArray{2} = ReadDisk(db,"SpOutput/PdOG",year) #[ProcOG,Area,Year]  Production (TBtu/Yr)
  PdOGPrior::VariableArray{2} = ReadDisk(db,"SpOutput/PdOG",prior) #[ProcOG,Area,Year]  Production (TBtu/Yr)
  PdPotential::VariableArray{2} = ReadDisk(db,"SpOutput/PdPotential",year) #[ProcOG,Area,Year]  Production Potential (TBtu)
  PdRaOG::VariableArray{2} = ReadDisk(db,"SpOutput/PdRaOG",year) #[ProcOG,Area,Year]  Production Rate (TBtu/TBtu)
  PdRate::VariableArray{1} = ReadDisk(db,"SpOutput/PdRate",year) #[OGUnit,Year]  Production Rate (Btu/Btu)
  PdRateM::VariableArray{1} = ReadDisk(db,"SpOutput/PdRateM",year) #[OGUnit,Year]  Production Rate Multiplier (Btu/Btu)
  PdRateMRef::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/PdRateM",year) #[OGUnit,Year]  Production Rate Multiplier (Btu/Btu)
  PdROI::VariableArray{1} = ReadDisk(db,"SpOutput/PdROI",year) #[OGUnit,Year]  Production Return on Investment ($/$)
  PdROIRef::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/PdROI",year) #[OGUnit,Year]  Reference Case Production Return on Investment ($/$)
  PdROIRefLastExo::VariableArray{1} = ReadDisk(OGRefNameDB,"SpOutput/PdROI",LastExo) #[OGUnit,LastExo]  Production Return on Investment in Last Year of Exogenous Forecast ($/$)
  PdSw::VariableArray{1} = ReadDisk(db,"SpInput/PdSw",year) #[OGUnit,Year]  Production Switch
  PdVar::VariableArray{1} = ReadDisk(db,"SpInput/PdVar",year) #[OGUnit,Year]  Production Rate Variance (Btu/Btu)
  PdVF::VariableArray{1} = ReadDisk(db,"SpInput/PdVF",year) #[OGUnit,Year]  Production Rate Variance Factor for ROI (Btu/Btu)
  ROITarget::VariableArray{1} = ReadDisk(db,"SpInput/ROITarget",year) #[OGUnit,Year]  ROI Target for Supply Cost Search ($/$)
  RsD0OG::VariableArray{1} = ReadDisk(db,"SpOutput/RsD0OG",year) #[OGUnit,Year]  Learning Curve Initial Developed Resources (TBtu)
  RsDev::VariableArray{1} = ReadDisk(db,"SpOutput/RsDev",year) #[OGUnit,Year]  Developed Resources (TBtu)
  RsDevPrior::VariableArray{1} = ReadDisk(db,"SpOutput/RsDev",prior) #[OGUnit,Year]  Developed Resources (TBtu)
  RsDevZero::VariableArray{1} = ReadDisk(db,"SpOutput/RsDev",Zero) #[OGUnit,Year]  Developed Resources (TBtu)
  RsDevOG::VariableArray{2} = ReadDisk(db,"SpOutput/RsDevOG",year) #[ProcOG,Area,Year]  Developed Resources (TBtu)
  RsDevOGPrior::VariableArray{2} = ReadDisk(db,"SpOutput/RsDevOG",prior) #[ProcOG,Area,Year]  Developed Resources (TBtu)
  RsUnpOG::VariableArray{2} = ReadDisk(db,"SpOutput/RsUnpOG",year) #[ProcOG,Area,Year]  Undeveloped Resources (TBtu)
  RsUnpOGPrior::VariableArray{2} = ReadDisk(db,"SpOutput/RsUnpOG",prior) #[ProcOG,Area,Year]  Undeveloped Resources (TBtu)
  RsUndev::VariableArray{1} = ReadDisk(db,"SpOutput/RsUndev",year) #[OGUnit,Year]  Undeveloped Resources (TBtu)
  RsUndevPrior::VariableArray{1} = ReadDisk(db,"SpOutput/RsUndev",prior) #[OGUnit,Year]  Undeveloped Resources (TBtu)
  RsUndevZero::VariableArray{1} = ReadDisk(db,"SpOutput/RsUndev",Zero) #[OGUnit,Year]  Undeveloped Resources (TBtu)
  RyFP::VariableArray{1} = ReadDisk(db,"SpOutput/RyFP",year) #[OGUnit,Year]  Fuel Price used to compute Royalties ($/mmBtu)
  RyLev::VariableArray{1} = ReadDisk(db,"SpOutput/RyLev",year) #[OGUnit,Year]  Levelized Royalty Payments ($/mmBtu))
  RyLevFactor::VariableArray{1} = ReadDisk(db,"SpInput/RyLevFactor",year) #[OGUnit,Year]  Royalty Levelization Factor ($/$)
  SCFP::VariableArray{1} = ReadDisk(db,"SpOutput/SCFP",year) #[OGUnit,Year]  Supply Cost ($/mmBtu)
  SCITax::VariableArray{1} = ReadDisk(db,"SpOutput/SCITax",year) #[OGUnit,Year]  Supply Cost Income Tax ($/mmBtu)
  SCNtInc::VariableArray{1} = ReadDisk(db,"SpOutput/SCNtInc",year) #[OGUnit,Year]  Supply Cost Net Income ($/mmBtu)
  SCRyFP::VariableArray{1} = ReadDisk(db,"SpOutput/SCRyFP",year) #[OGUnit,Year]  Fuel Price used to compute Supply Cost Royalties ($/mmBtu)
  SCRyLev::VariableArray{1} = ReadDisk(db,"SpOutput/SCRyLev",year) #[OGUnit,Year]  Supply Cost Royalties ($/mmBtu)
  SusCap::VariableArray{1} = ReadDisk(db,"SpOutput/SusCap",year) #[OGUnit,Year]  Sustaining Capital Costs ($/mmBtu)
  SusDep::VariableArray{1} = ReadDisk(db,"SpOutput/SusDep",year) #[OGUnit,Year]  Sustaining Depreciation ($/mmBtu)
  VnCosts::VariableArray{2} = ReadDisk(db,"SOutput/VnCosts",year) #[ECC,Area,Year]  Venting Reduction Costs ($/mmBtu)
  xDev::VariableArray{1} = ReadDisk(db,"SpInput/xDev",year) #[OGUnit,Year]  Historical Development of Resources (TBtu/Yr)
  xDevCap::VariableArray{1} = ReadDisk(db,"SpInput/xDevCap",year) #[OGUnit,Year]  Exogenous Development Capital Costs ($/mmBtu)
  xDevRate::VariableArray{1} = ReadDisk(db,"SpInput/xDevRate",year) #[OGUnit,Year]  Exogenous Development Rate (Btu/Btu)
  xDevRateLastExo::VariableArray{1} = ReadDisk(db,"SpInput/xDevRate",LastExo) #[OGUnit,LastExo]  Exogenous Development Rate in Last Year of Exogenous Forecast (Btu/Btu)
  xGAProd::VariableArray{2} = ReadDisk(db,"SInput/xGAProd",year) #[Process,Area,Year]  Natural Gas Production (TBtu/Yr)
  xOAProd::VariableArray{2} = ReadDisk(db,"SInput/xOAProd",year) #[Process,Area,Year]  Oil Production (TBtu/Yr)
  xOGFP::VariableArray{1} = ReadDisk(db,"SpInput/xOGFP",year) #[OGUnit,Year]  Historical OG Price ($/mmBtu)
  xOGOMCosts::VariableArray{1} = ReadDisk(db,"SpInput/xOGOMCosts",year) #[OGUnit,Year]  O&M Costs ($/mmBtu)
  xPd::VariableArray{1} = ReadDisk(db,"SpInput/xPd",year) #[OGUnit,Year]  Historical Production (TBtu/Yr)
  xPdRate::VariableArray{1} = ReadDisk(db,"SpInput/xPdRate",year) #[OGUnit,Year]  Historical Production Rate (Btu/Btu)
  xPdRateLastExo::VariableArray{1} = ReadDisk(db,"SpInput/xPdRate",LastExo) #[OGUnit,LastExo]  Exogenous Production Rate in Last Year of Exogenous Forecast (Btu/Btu)
  xProcSw::VariableArray{1} = ReadDisk(db,"SInput/xProcSw",year) #[PI,Year] "Procedure on/off Switch"
  xRsDev::VariableArray{1} = ReadDisk(db,"SpInput/xRsDev",year) #[OGUnit,Year]  Historical Developed Resources (TBtu)
  xRsDevZero::VariableArray{1} = ReadDisk(db,"SpInput/xRsDev",Zero) #[OGUnit,Year]  Historical Developed Resources (TBtu)
  xRsUndev::VariableArray{1} = ReadDisk(db,"SpInput/xRsUndev",year) #[OGUnit,Year]  Historical Undeveloped Resources (TBtu)
  xRsUndevZero::VariableArray{1} = ReadDisk(db,"SpInput/xRsUndev",Zero) #[OGUnit,Year]  Historical Undeveloped Resources (TBtu)
  xRvUndev::VariableArray{1} = ReadDisk(db,"SpInput/xRvUndev",year) #[OGUnit,Year]  Revisions to Undeveloped Resources (TBtu)
  xSusCap::VariableArray{1} = ReadDisk(db,"SpInput/xSusCap",year) #[OGUnit,Year]  Exogenous Sustaining Capital Costs ($/mmBtu)

  #
  # Scratch Variables
  #
  PdTotal::VariableArray{2} = zeros(Float32,length(Process),length(Area))
  ProcSw::VariableArray = zeros(Float32,length(PI))
end

function OGSetSelect(data::Data,ogunit)
  (; Area,ECC,FuelOG,GNode,Nation,Process,ProcOG) = data #sets
  (; OGArea,OGECC,OGFuel,OGProcess,OGNode,OGNation,OGName) = data #sets

  OGUnitIsValid="True"

  areaindex = Select(Area,OGArea[ogunit])
  eccindex = Select(ECC,OGECC[ogunit])
  processindex = Select(Process,OGECC[ogunit])
  fuelogindex = Select(FuelOG,OGFuel[ogunit])
  procogindex = Select(ProcOG,OGProcess[ogunit])
  gnodeindex = Select(GNode,OGNode[ogunit])
  nationindex = Select(Nation,OGNation[ogunit])

  if OGArea[ogunit] != Area[areaindex]
    @info "OGArea is not valid inside SpOGProd.jl " OGName[ogunit],OGArea[ogunit]
    OGUnitIsValid = "False"
  elseif OGECC[ogunit] != ECC[eccindex]
    @info "OGECC is not valid inside SpOGProd.jl " OGName[ogunit],OGECC[ogunit]
    OGUnitIsValid = "False"
  elseif OGFuel[ogunit] != FuelOG[fuelogindex]
    @info "OGFuel is not valid inside SpOGProd.jl " OGName[ogunit],OGFuel[ogunit]
    OGUnitIsValid = "False"
  elseif OGNode[ogunit] != GNode[gnodeindex]
    @info "OGNode is not valid inside SpOGProd.jl " OGName[ogunit],OGNode[ogunit]
    OGUnitIsValid = "False"
  elseif OGNation[ogunit] != Nation[nationindex]
    @info "OGNation is not valid inside SpOGProd.jl " OGName[ogunit],OGNation[ogunit]
    OGUnitIsValid = "False"
  end

  return areaindex,eccindex,processindex,fuelogindex,procogindex,gnodeindex,nationindex,OGUnitIsValid

end

function OGRSetSets(data::Data)
  # Not used in Julia
end

function Initial(data::Data)
  (; db) = data
  (; RsDevZero,RsUndevZero,xRsDevZero,xRsUndevZero) = data

  # @info "  SpOGProd.jl - Initial - Oil and Gas Production Initialization"

  #
  # Initialize Developed and Undeveloped Resources
  #

  @. RsDevZero = xRsDevZero
  @. RsUndevZero = xRsUndevZero

  WriteDisk(db,"SpOutput/RsDev",Zero,RsDevZero)
  WriteDisk(db,"SpOutput/RsUndev",Zero,RsUndevZero)

end

function EcoMultipliers(data::Data)
  (; db,year) = data
  (; Fuel,Fuels) = data #sets
  (; CCMDem,CCMDemSw,DemCCMultPrior,DemRqPrior,DevDM) = data
  (; DevDMB0,DevIM,DevLCM,DevLCMB0,FPECC,FPECCCFSNet) = data
  (; FPECCCPNet,FPECCOGEC,OGCounter,OGFPrice,OGFUse,OGNation) = data
  (; OGPolPrice,OpDM,OpDMB0,OpLCM,OpLCMB0,PdC0OG,PdCumOGPrior) = data
  (; PdPotential,RsD0OG,RsDevOGPrior,RsUnpOGPrior) = data

  # @info "  SpOGProd.jl - EcoMultipliers - Oil and Gas Production Economic Multipliers"

  for ogunit in 1:Int(OGCounter)
    area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

    #
    # Depletion Multipliers
    #
    PdPotential[procog,area] = PdCumOGPrior[procog,area]+RsDevOGPrior[procog,area]+RsUnpOGPrior[procog,area]
    DevRemaining=PdPotential[procog,area]-(PdCumOGPrior[procog,area]+RsDevOGPrior[procog,area])
    @finite_math DevDM[ogunit] = max(DevRemaining/PdPotential[procog,area],0.0001)^DevDMB0[ogunit]
    PdRemaining=PdPotential[procog,area]-PdCumOGPrior[procog,area]
    @finite_math OpDM[ogunit] = max(PdRemaining/PdPotential[procog,area],0.0001)^OpDMB0[ogunit]

    #
    # Learning Curve Multipliers
    #
    @finite_math DevLCM = (max(PdCumOGPrior[procog,area]+RsDevOGPrior[procog,area],0.000001)/
            max(PdC0OG[ogunit]+RsD0OG[ogunit],0.000001))^DevLCMB0[ogunit]
    @finite_math OpLCM = (max(PdCumOGPrior[procog,area],0.000001)/max(PdC0OG[ogunit],0.000001))^OpLCMB0[ogunit]

    #
    # Multiplier from Infrastructure (DevIM) will eventually come
    # from the macroeonimc model, but for now it is just equal
    # to 1.0.  Jeff Amlin 8/24/12
    #
    DevIM[ogunit] = 1.0

    #
    # Marginal Fuel Usage (OGFUse) is the Marginal Energy
    # Requirement (DemRq) from the Demand Module
    #
    for fuel in Fuels
      OGFUse[ogunit,fuel] = DemRqPrior[fuel,ecc,area]
    end

    #
    # The Demand Mulitplier (DemM) is based on the changes in capital
    # costs from the Demand Module.
    #
    if (CCMDemSw[ogunit] == 1.0) && (OGNation[ogunit] == "CN")
      CCMDem[ogunit] = DemCCMultPrior[ecc,area]
    else
      CCMDem[ogunit] = 1.0
    end

    #
    # Fuel Price except for Raw Natural Gas which is assumed to have
    # a zero price for the Production module. Jeff Amlin 8/24/12
    #
    for fuel in Select(Fuel,"NaturalGasRaw")
      OGFPrice[ogunit,fuel] = 0.0
    end

    for fuel in Select(Fuel, !=("NaturalGasRaw"))
      OGFPrice[ogunit,fuel] = FPECC[fuel,ecc,area]
    end

    #
    # Emission Price (OGPolPrice) may have a value for Raw Natural Gas.
    # Jeff Amlin 8/24/12
    #
    for fuel in Fuels
      OGPolPrice[ogunit,fuel] = FPECCCPNet[fuel,ecc,area]+FPECCCFSNet[fuel,ecc,area]+
                                FPECCOGEC[fuel,ecc,area]
    end

  end

  # OGRSetSets

  WriteDisk(db,"SpOutput/CCMDem",year,CCMDem)
  WriteDisk(db,"SpOutput/DevDM",year,DevDM)
  WriteDisk(db,"SpOutput/DevLCM",year,DevLCM)
  WriteDisk(db,"SpOutput/DevIM",year,DevIM)
  WriteDisk(db,"SpOutput/OpDM",year,OpDM)
  WriteDisk(db,"SpOutput/OpLCM",year,OpLCM)
  WriteDisk(db,"SpOutput/OGFUse",year,OGFUse)
  WriteDisk(db,"SpOutput/OGFPrice",year,OGFPrice)
  WriteDisk(db,"SpOutput/OGPolPrice",year,OGPolPrice)
  WriteDisk(db,"SpOutput/PdPotential",year,PdPotential)
end

function WholesalePrices(data::Data)
  (; Fuel,Fuels,FuelOG,FuelOGs,Nations,OGUnits) = data #sets
  (; OGENPN,ENPN,InflationNation,OGFMap,LNGPM,OGCode,DilFrac) = data

  # @info "  SpOGProd.jl - WholesalePrices"

  #
  # Wholesale Price for each Product
  #
  for nation in Nations, fuelog in FuelOGs
    OGENPN[fuelog,nation] = sum(ENPN[fuel,nation]*OGFMap[fuelog,fuel] for fuel in Fuels)*InflationNation[nation]
  end

  #
  # LNG Prices are 90 percent of light crude oil prices according to data from Gavin emailed
  # of May 20, 2022 - PNV
  #

  LNGPM = .900

  lightcrude = Select(Fuel,"LightCrudeOil")
  lng = Select(FuelOG,"LNG")
  for nation in Nations
    OGENPN[lng,nation] = ENPN[lightcrude,nation]*InflationNation[nation]*LNGPM
  end

  #
  # Bitumen Prices - see "Sproule Bitumen price forecast .pdf"
  #
  bitumen = Select(FuelOG,"Bitumen")
  diluent = Select(FuelOG,"Diluent")
  heavyoil = Select(FuelOG,"HeavyOil")

  #
  # ogunit = Select(OGCode,"AB_OS_SAGD_0001")
  #
  for ogunit in OGUnits, nation in Nations
    if OGCode[ogunit] == "AB_OS_SAGD_0001"
      @finite_math OGENPN[bitumen,nation] = (OGENPN[heavyoil,nation]-OGENPN[diluent,nation]*DilFrac[ogunit])/(1-DilFrac[ogunit])
    end
  end

end

function PdPrice(data::Data,ogunit)
  (; FuelOG) = data #sets
  (; OGENPN,OGFP,OGFPDChg,InflationOGUnit,OGPrSw,DilFrac,xOGFP,ByPrice) = data
  (; OGECC,FkPrice,RyFP) = data

  area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

  bitumen = Select(FuelOG,"Bitumen")
  diluent = Select(FuelOG,"Diluent")
  heavyoil = Select(FuelOG,"HeavyOil")
  naturalgas = Select(FuelOG,"NaturalGas")

  # @info "  SpOGProd.jl - PdPrice - Oil and Gas Production Prices"

  #
  # Prices are the representation Wholesale Price (OGENPN) which will
  # in general be either the World Oil Price or Wellhead Natural Gas
  # Prices plus a Delivery Charge (OGFPDChg)
  #
  if OGPrSw[ogunit] == 1
    OGFP[ogunit] = OGENPN[fuelog,nation]+OGFPDChg[ogunit]*InflationOGUnit[ogunit]

  #
  # Bitumen Prices - see Understanding Bitumen Pricing.docx
  # https://www.gljpc.com/blog/understanding-bitumen-pricing
  #
  elseif OGPrSw[ogunit] == 2
    OGFP[ogunit] = OGENPN[heavyoil,nation]*(1+DilFrac[ogunit])-OGENPN[diluent,nation]*DilFrac[ogunit]+
                OGFPDChg[ogunit]*InflationOGUnit[ogunit]

  #
  # Else Prices are exogneous
  #
  elseif OGPrSw[ogunit] == 0
    OGFP[ogunit] = xOGFP[ogunit]*InflationOGUnit[ogunit]
  end

  #
  # Byproduct Price
  #
  ByPrice[ogunit] = OGFP[ogunit]

  #
  # Feedstock Price is Bitumen Price for Upgraders and LNG Production
  #
  if OGECC[ogunit] == "OilSandsUpgraders"
    FkPrice[ogunit] = OGENPN[bitumen,nation]
  elseif OGECC[ogunit] == "LNGProduction"
    FkPrice[ogunit] = OGENPN[naturalgas,nation]
  end

  #
  # Fuel Price for Royalty calcuation
  #
  # Do If (OGOGSw eq "Oil") and (OGNation eq "CN")
  #   RyFP[ogunit] = OGENPN(LightOil,US)*ExchangeRateNation(CN,Y)
  # Else OGOGSw eq "Oil"
  #   RyFP[ogunit] = OGENPN(LightOil,US)
  # Else
  #   RyFP[ogunit] = OGENPN(NaturalGas,US)
  # End Do If
  #
  RyFP[ogunit] = OGENPN[fuelog,nation]

end

function Economics(data::Data,ogunit)
  (; Fuels,OGUnit) = data #sets
  (; ByFrac,ByPrice,ByRev,CCMDem,DevCap,DevDep,DevDM,DevDMRef) = data
  (; DevDpRate,DevExp,DevIM,DevITax,DevLCM,DevNtInc,DevROI) = data
  (; FkCosts,FkFrac,FkPrice,FlCosts,FuCosts,GRRMax,GRRMin) = data
  (; GRRPr,GRRPr0,GRRRate,InflationOGUnit,NetRev,NRRMax) = data
  (; NRRMin,NRRPr,NRRPr0,NRRRate,OGAbCFr,OGAbCosts,OGCapCosts) = data
  (; OGDep,OGFCosts,OGFP,OGFPrice,OGFUse,OGITxRate) = data
  (; OGOMCosts,OGOpCosts,OGPolCosts,OGPolPrice,OGRev,OpDM) = data
  (; OpDMRef,OpExp,OpLCM,OpWrkCap,OWCDays,PdExp,PdITax,PdNtInc) = data
  (; PdROI,RyFP,RyLev,RyLevFactor,SusCap,SusDep,SusDpRate) = data
  (; VnCosts,xDevCap,xOGOMCosts,xSusCap) = data

  OGFuCosts::VariableArray{1} = zeros(Float32,length(OGUnit))

  area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

  # @info "  SpOGProd.jl - Economics - Oil and Gas Production Marginal ROI"

  #
  # This procedure computes the marginal ROI (Return on
  # Investment) for each oil and gas play [ogunit].
  #
  # Byproduct Revenue (ByRev) is the Byproducts Price
  # Multiplier (ByPrice) times the Byproducts Production
  # Fraction (ByFrac) times the Product Price (OGFP)
  #
  ByRev[ogunit] = ByPrice[ogunit]*ByFrac[ogunit]

  #
  # Gross Revenue (OGRev) is equal to the Product Price (OGFP)
  # plus the Byproduct Revenue (ByRev)
  #
  OGRev[ogunit] = OGFP[ogunit]+ByRev[ogunit]

  #
  # Development Capital Costs
  #
  @finite_math DevCap[ogunit] = xDevCap[ogunit]*DevDM[ogunit]/DevDMRef[ogunit]*DevLCM[ogunit]*DevIM[ogunit]*CCMDem[ogunit]*InflationOGUnit[ogunit]

  #
  # Sustaining Capital Costs
  #
  @finite_math SusCap[ogunit] = xSusCap[ogunit]*OpDM[ogunit]/OpDMRef[ogunit]*OpLCM[ogunit]*CCMDem[ogunit]*InflationOGUnit[ogunit]

  #
  # Capital Costs
  #
  OGCapCosts[ogunit] = DevCap[ogunit]+SusCap[ogunit]

  #
  # Depreciation
  #
  DevDep[ogunit] = DevCap[ogunit]*DevDpRate[ogunit]
  SusDep[ogunit] = SusCap[ogunit]*SusDpRate[ogunit]
  OGDep[ogunit] = DevDep[ogunit]+SusDep[ogunit]

  #
  # Abandonment Costs
  #
  OGAbCosts[ogunit] = DevCap[ogunit]*OGAbCFr[ogunit]

  #
  # O&M Costs
  #
  @finite_math OGOMCosts[ogunit] = xOGOMCosts[ogunit]*OpDM[ogunit]/OpDMRef[ogunit]*OpLCM[ogunit]*InflationOGUnit[ogunit]

  #
  # Fuel Costs
  #
  OGFCosts[ogunit] = sum(OGFUse[ogunit,fuel]*OGFPrice[ogunit,fuel] for fuel in Fuels)

  #
  # Pollution Costs including Fugitive Reduction Costs
  #
  OGFuCosts[ogunit] = VnCosts[ecc,area]+FuCosts[ecc,area]+FlCosts[ecc,area]
  OGPolCosts[ogunit] = sum(OGFUse[ogunit,fuel]*OGPolPrice[ogunit,fuel] for fuel in Fuels)+
                       OGFuCosts[ogunit]

  #
  # Feedstock Costs
  #
  FkCosts[ogunit] = FkFrac[ogunit]*FkPrice[ogunit]

  #
  # Operating Costs
  #
  OGOpCosts[ogunit] = OGOMCosts[ogunit]+OGFCosts[ogunit]+OGPolCosts[ogunit]+FkCosts[ogunit]

  #
  # Operating Working Capital
  #
  OpWrkCap[ogunit] = OGFCosts[ogunit]*OWCDays[ogunit]/365

  #
  # Operating Expenses excluding Depreciation, Royalties, and Taxes
  #
  OpExp[ogunit] = OGOpCosts[ogunit]+OpWrkCap[ogunit]

  #
  # Revenue Royalty Rates
  #
  NRRRate[ogunit] = max(NRRMin[ogunit],min(NRRPr0[ogunit]+NRRPr[ogunit]*RyFP[ogunit],NRRMax[ogunit]))
  GRRRate[ogunit] = max(GRRMin[ogunit],min(GRRPr0[ogunit]+GRRPr[ogunit]*RyFP[ogunit],GRRMax[ogunit]))

  #
  # Net Revenues (NetRev) are Gross Revenues (OGrev) less
  # allowable expenses of operating costs and depreciation.
  #
  NetRev[ogunit] = OGRev[ogunit]-OGOpCosts[ogunit]-DevDep[ogunit]-SusDep[ogunit]

  #
  # Levelized Royalties (RyLev) are the larger of Net Revenues (NetRev)
  # times a the Net Revenue Royalty Rate (NRRRate) or Gross Revenues
  # (OGRev) times the Gross Revenue Royalty Rate (GRRRate) adjusted by
  # a levelization factor (RyLevFactor), if needed.
  #
  RyLev[ogunit] = max(NetRev[ogunit]*NRRRate[ogunit],OGRev[ogunit]*GRRRate[ogunit])*RyLevFactor[ogunit]

  #
  # Expenses excluding Income Taxes
  #
  DevExp[ogunit] = OGOpCosts[ogunit]+OpWrkCap[ogunit]+OGAbCosts[ogunit]+RyLev[ogunit]+SusDep[ogunit]+DevDep[ogunit]
  PdExp[ogunit] = OGOpCosts[ogunit]+OpWrkCap[ogunit]+OGAbCosts[ogunit]+RyLev[ogunit]+SusDep[ogunit]

  #
  # Income Taxes
  #
  DevITax[ogunit] = (OGRev[ogunit]-DevExp[ogunit])*OGITxRate[ogunit]
  PdITax[ogunit] =(OGRev[ogunit]-PdExp[ogunit] )*OGITxRate[ogunit]

  #
  # Net Income
  #
  DevNtInc[ogunit] = OGRev[ogunit]-DevExp[ogunit]-DevITax[ogunit]
  PdNtInc[ogunit] = OGRev[ogunit]-PdExp[ogunit] -PdITax[ogunit]

  #
  # Return on Investment ($/$)
  #
  @finite_math DevROI[ogunit] = DevNtInc[ogunit]/(SusCap[ogunit]+DevCap[ogunit])
  @finite_math PdROI[ogunit] = PdNtInc[ogunit] /(SusCap[ogunit])

end

function CtrlEconomics(data::Data)
  (; db,year) = data
  (; ByPrice,ByRev,DevCap,DevDep,DevExp,DevITax,DevNtInc) = data
  (; DevROI,FkCosts,FkPrice,GRRRate,NetRev,NRRRate) = data
  (; OGAbCosts,OGCapCosts,OGCounter,OGDep,OGENPN,OGFCosts,OGFP) = data
  (; OGOMCosts,OGOpCosts,OGPolCosts,OGRev,OpExp,OpWrkCap) = data
  (; PdExp,PdITax,PdNtInc,PdROI,RyFP,RyLev,SusCap,SusDep) = data

  # @info "  SpOGProd.jl - CtrlEconomics"


  WholesalePrices(data::Data)
  for ogunit in 1:Int(OGCounter)
    
    #
    # OGSetSelect - 23.09.13, LJD: moving OGSetSelect within functions which 
    # are passed ogunit
    #
    PdPrice(data,ogunit)
    Economics(data,ogunit)
  end

  # OGRSetSets
  # Select OGUnit*

  WriteDisk(db,"SpOutput/ByPrice",year,ByPrice)
  WriteDisk(db,"SpOutput/OGENPN",year,OGENPN)
  WriteDisk(db,"SpOutput/OGFP",year,OGFP)
  WriteDisk(db,"SpOutput/RyFP",year,RyFP)
  WriteDisk(db,"SpOutput/ByRev",year,ByRev)
  WriteDisk(db,"SpOutput/DevCap",year,DevCap)
  WriteDisk(db,"SpOutput/DevDep",year,DevDep)
  WriteDisk(db,"SpOutput/DevExp",year,DevExp)
  WriteDisk(db,"SpOutput/DevITax",year,DevITax)
  WriteDisk(db,"SpOutput/DevNtInc",year,DevNtInc)
  WriteDisk(db,"SpOutput/DevROI",year,DevROI)
  WriteDisk(db,"SpOutput/FkCosts",year,FkCosts)
  WriteDisk(db,"SpOutput/FkPrice",year,FkPrice)
  WriteDisk(db,"SpOutput/GRRRate",year,GRRRate)
  WriteDisk(db,"SpOutput/NetRev",year,NetRev)
  WriteDisk(db,"SpOutput/NRRRate",year,NRRRate)
  WriteDisk(db,"SpOutput/OGAbCosts",year,OGAbCosts)
  WriteDisk(db,"SpOutput/OGCapCosts",year,OGCapCosts)
  WriteDisk(db,"SpOutput/OGDep",year,OGDep)
  WriteDisk(db,"SpOutput/OGFCosts",year,OGFCosts)
  WriteDisk(db,"SpOutput/OGOMCosts",year,OGOMCosts)
  WriteDisk(db,"SpOutput/OGOpCosts",year,OGOpCosts)
  WriteDisk(db,"SpOutput/OGPolCosts",year,OGPolCosts)
  WriteDisk(db,"SpOutput/OGRev",year,OGRev)
  WriteDisk(db,"SpOutput/OpExp",year,OpExp)
  WriteDisk(db,"SpOutput/OpWrkCap",year,OpWrkCap)
  WriteDisk(db,"SpOutput/PdExp",year,PdExp)
  WriteDisk(db,"SpOutput/PdITax",year,PdITax)
  WriteDisk(db,"SpOutput/PdNtInc",year,PdNtInc)
  WriteDisk(db,"SpOutput/PdROI",year,PdROI)
  WriteDisk(db,"SpOutput/RyLev",year,RyLev)
  WriteDisk(db,"SpOutput/SusCap",year,SusCap)
  WriteDisk(db,"SpOutput/SusDep",year,SusDep)

end

function FindPrice(data::Data)
  (; db,year) = data
  (; OGUnit) = data #sets
  (; DevITax,DevNtInc,DevROI,FkPrice,OGCounter,OGENPN,OGFP) = data
  (; OGFPAdd,OGFPMax,OGFPMin,ROITarget,RyFP,RyLev,SCFP,SCITax) = data
  (; SCNtInc,SCRyFP,SCRyLev) = data

  SCFkPrice::VariableArray{1} = zeros(Float32,length(OGUnit))


  # @info "  SpOGProd.jl - FindPrice - Find Price where ROI equals Target"

  @. SCFkPrice = FkPrice
  for ogunit in 1:Int(OGCounter)
    area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

    OGENPN[fuelog,nation] = OGFPMin[ogunit]

    while OGENPN[fuelog,nation] <= OGFPMax[ogunit]

      PdPrice(data,ogunit)
      FkPrice[ogunit] = SCFkPrice[ogunit]
      Economics(data,ogunit)

      #
      # Save the Supply Cost variables
      #
      SCFP[ogunit] = OGFP[ogunit]
      SCRyFP[ogunit] = RyFP[ogunit]
      SCRyLev[ogunit] = RyLev[ogunit]
      SCITax[ogunit] = DevITax[ogunit]
      SCNtInc[ogunit] = DevNtInc[ogunit]

      #
      # Once the development ROI (DevROI) exceeds the Target ROI (ROITarget),
      # end the loop by setting the price (OGFP) to the maximum price
      # (OGFPMax) plus an increment.
      #
      if DevROI[ogunit] >= ROITarget[ogunit]
        OGENPN[fuelog,nation] = OGFPMax[ogunit]+1e12
        #
        # Else increment the price (OGFP)
        #
      else
        OGENPN[fuelog,nation] = OGENPN[fuelog,nation]+OGFPAdd[ogunit]
      end # if ROI
    end # while OGENPN
  end  # Do OGUnit

  WriteDisk(db,"SpOutput/SCFP",year,SCFP)
  WriteDisk(db,"SpOutput/SCITax",year,SCITax)
  WriteDisk(db,"SpOutput/SCNtInc",year,SCNtInc)
  WriteDisk(db,"SpOutput/SCRyFP",year,SCRyFP)
  WriteDisk(db,"SpOutput/SCRyLev",year,SCRyLev)

end

function Exploration(data::Data)
  #
  # 23.09.12, LJD: Empty procedure in Promula
  #
end

function Development(data::Data)
  (; db,year) = data
  (; Dev,DevMaxM,DevMinM,DevRate,DevRateM,DevRateMRef,DevROI) = data
  (; DevROIRef,DevROIRefLastExo,DevSw,DevVar,DevVF,MeanEUR,NewWells) = data
  (; OGCounter,OGROIN,RsUndevPrior,xDev,xDevRate,xDevRateLastExo) = data

  # @info "  SpOGProd.jl - Development - Oil and Gas Development"

  for ogunit in 1:Int(OGCounter)
    area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

    #
    # Trap so Dev ROI is always positive
    #
    DevROI[ogunit] = max(DevROI[ogunit],0.000001)
    DevROIRef[ogunit] = max(DevROIRef[ogunit],0.000001)

    #
    # For Method 1 Development Rate (DevRate) is an input (xDevRate).
    #
    if DevSw[ogunit] == 1
      DevRate[ogunit] = xDevRate[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]
      DevRateM[ogunit] = 1

    #
    # For Method 2 Development Rate (DevRate) is adjusted by the
    # ROI of Development (DevROI) relative to the Reference Case (DevROIRef).
    #
    elseif DevSw[ogunit] == 2
      @finite_math DevRateM[ogunit] = max(min((1+DevVar[ogunit])/(DevVar[ogunit]+
        (DevROI[ogunit]/DevROIRef[ogunit])^DevVF[ogunit]),
        DevMaxM[ogunit]),DevMinM[ogunit])
      DevRate[ogunit] = xDevRate[ogunit]*DevRateM[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]

    #
    # For Method 3 Development Rate (DevRate) is adjusted by the
    # ROI of Development (DevROI) relative to the Normal ROI (OGROIN).
    #
    elseif DevSw[ogunit] == 3
      @finite_math DevRateM[ogunit] = max(min((1+DevVar[ogunit])/(DevVar[ogunit]+
        (DevROI[ogunit]/OGROIN[ogunit])^DevVF[ogunit]),
        DevMaxM[ogunit]),DevMinM[ogunit])
      DevRate[ogunit] = xDevRate[ogunit]*DevRateM[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]

    #
    # For Method 4 Development Rate (DevRate) is the Development Rate
    # in the last year of the exogenous forecast (xDevRateLastExo) adjusted
    # by the ROI of Development (DevROI) relative to the ROI in the last
    # year of the exogenous forecast (DevROIRefLastExo).
    #
    elseif DevSw[ogunit] == 4
      DevROIRefLastExo[ogunit] = max(DevROIRefLastExo[ogunit],0.000001)
      @finite_math DevRateM[ogunit] = max(min((1+DevVar[ogunit])/(DevVar[ogunit]+
        (DevROI[ogunit]/DevROIRefLastExo[ogunit])^DevVF[ogunit]),
        DevMaxM[ogunit]),DevMinM[ogunit])
      DevRate[ogunit] = xDevRateLastExo[ogunit]*DevRateM[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]

    #
    # For Method 5 Development Rate (DevRate) is non-symetric where the
    # Development Rate Multiplier (DevRateM) does not drop below the Reference case
    #
    elseif DevSw[ogunit] == 5
      @finite_math DevRateM[ogunit] = max(min((1+DevVar[ogunit])/(DevVar[ogunit]+
        (DevROI[ogunit]/DevROIRef[ogunit])^DevVF[ogunit]),
        DevMaxM[ogunit]),DevMinM[ogunit])
      DevRateM[ogunit] = max(DevRateM[ogunit],DevRateMRef[ogunit])
      DevRate[ogunit] = xDevRate[ogunit]*DevRateM[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]

    #
    # For Method 6 Development Rate (DevRate) is non-symetric where the
    # Development Rate Multiplier (DevRateM) does not drop below 50% of the Reference case
    #
    elseif DevSw[ogunit] == 6
      @finite_math DevRateM[ogunit] = max(min((1+DevVar[ogunit])/(DevVar[ogunit]+
        (DevROI[ogunit]/DevROIRef[ogunit])^DevVF[ogunit]),
        DevMaxM[ogunit]),DevMinM[ogunit])
      DevRateM[ogunit] = max(DevRateM[ogunit],DevRateMRef[ogunit]*0.50)
      DevRate[ogunit] = xDevRate[ogunit]*DevRateM[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]

    #
    # For Method 7 Development Rate (DevRate) is non-symetric where the
    # Development Rate Multiplier (DevRateM) does not drop below 87% of the Reference case
    #
    elseif DevSw[ogunit] == 7
      @finite_math DevRateM[ogunit] = max(min((1+DevVar[ogunit])/(DevVar[ogunit]+
        (DevROI[ogunit]/DevROIRef[ogunit])^DevVF[ogunit]),
        DevMaxM[ogunit]),DevMinM[ogunit])
      DevRateM[ogunit] = max(DevRateM[ogunit],DevRateMRef[ogunit]*0.87)
      DevRate[ogunit] = xDevRate[ogunit]*DevRateM[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]

    #
    # For Method 8 Development Rate (DevRate) is non-symetric where the
    # Development Rate Multiplier (DevRateM) does not drop below 87% of the Reference case
    #
    elseif DevSw[ogunit] == 8
      DevROIRefLastExo[ogunit] = max(DevROIRefLastExo[ogunit],0.000001)
      @finite_math DevRateM[ogunit] = max(min((1+DevVar[ogunit])/(DevVar[ogunit]+
        (DevROI[ogunit]/DevROIRefLastExo[ogunit])^DevVF[ogunit]),
        DevMaxM[ogunit]),DevMinM[ogunit])
      DevRateM[ogunit] = max(DevRateM[ogunit],DevRateMRef[ogunit]*0.87)
      DevRate[ogunit] = xDevRate[ogunit]*DevRateM[ogunit]
      Dev[ogunit] = RsUndevPrior[ogunit]*DevRate[ogunit]

    #
    # For Method 0 Development (Dev) is an input (xDev).
    #
    else
      Dev[ogunit] = xDev[ogunit]
      @finite_math DevRate[ogunit] = Dev[ogunit]/RsUndevPrior[ogunit]
      DevRateM[ogunit] = 1

    end

    #
    # In Case we need the number of Wells
    #
    @finite_math NewWells[ogunit] = Dev[ogunit]/MeanEUR[ogunit]
  end

  WriteDisk(db,"SpOutput/Dev",year,Dev)
  WriteDisk(db,"SpOutput/DevRate",year,DevRate)
  WriteDisk(db,"SpOutput/NewWells",year,NewWells)
  WriteDisk(db,"SpOutput/DevRateM",year,DevRateM)
end

function Production(data::Data)
  (; db,year) = data
  (; OGCounter,OGROIN,Pd,PdMax,PdMaxM,PdMinM,PdRate,PdRateM,PdRateMRef) = data
  (; PdROI,PdROIRef,PdROIRefLastExo,PdSw,PdVar,PdVF,RsDevPrior) = data
  (; xPd,xPdRate,xPdRateLastExo) = data

  # @info "  SpOGProd.jl - Production - Oil and Gas Production"

  for ogunit in 1:Int(OGCounter)
    area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

    #
    # Trap Production ROI to be positive
    #
    PdROI[ogunit] = max(PdROI[ogunit],0.000001)
    PdROIRef[ogunit] = max(PdROIRef[ogunit],0.000001)

    #
    # For Method 1 Production Rate (PdRate) is an input (xPdRate).
    #
    if PdSw[ogunit] == 1
      PdRate[ogunit] = xPdRate[ogunit]
      Pd[ogunit] = min(RsDevPrior[ogunit]*PdRate[ogunit],PdMax[ogunit])
      PdRateM[ogunit] = 1

    #
    # For Method 2 Production Rate (PdRate) is adjusted by the
    # ROI of Production (PdROI) relative to the Reference Case (PdROIRef).
    #
    elseif PdSw[ogunit] == 2
      @finite_math PdRateM[ogunit] = max(min((1+PdVar[ogunit])/(PdVar[ogunit]+
        (PdROI[ogunit]/PdROIRef[ogunit])^PdVF[ogunit]),
        PdMaxM[ogunit]),PdMinM[ogunit])
      PdRate[ogunit] = xPdRate[ogunit]*PdRateM[ogunit]
      Pd[ogunit] = min(RsDevPrior[ogunit]*PdRate[ogunit],PdMax[ogunit])

    #
    # For Method 3 Production Rate (PdRate) is adjusted by the
    # ROI of Production (PdROI) relative to the Normal ROI (OGROIN).
    #
    elseif PdSw[ogunit] == 3
      @finite_math PdRateM[ogunit] = max(min((1+PdVar[ogunit])/(PdVar[ogunit]+
        (PdROI[ogunit]/OGROIN[ogunit])^PdVF[ogunit]),
        PdMaxM[ogunit]),PdMinM[ogunit])
      PdRate[ogunit] = xPdRate[ogunit]*PdRateM[ogunit]
      Pd[ogunit] = min(RsDevPrior[ogunit]*PdRate[ogunit],PdMax[ogunit])

    #
    # For Method 4 Production Rate (PdRate) is Production Rate in the
    # last year of the exogenous forecast (xPdRateLastExo) adjusted by
    # the ROI of Production (PdROI) relative to the ROI in the last
    # year of the exogenous forecast (PdROIRefLastExo).
    #
    elseif PdSw[ogunit] == 4
      @finite_math PdRateM[ogunit] = max(min((1+PdVar[ogunit])/(PdVar[ogunit]+
        (PdROI[ogunit]/PdROIRefLastExo[ogunit])^PdVF[ogunit]),
        PdMaxM[ogunit]),PdMinM[ogunit])
      PdRate[ogunit] = xPdRateLastExo[ogunit]*PdRateM[ogunit]
      Pd[ogunit] = min(RsDevPrior[ogunit]*PdRate[ogunit],PdMax[ogunit])

    #
    # For Method 5 Production Rate (PdRate) is non-symetric where the
    # Production Rate Multiplier (PdRateM) does not drop below the Reference case
    #
    elseif PdSw[ogunit] == 5
      @finite_math PdRateM[ogunit] = max(min((1+PdVar[ogunit])/(PdVar[ogunit]+
        (PdROI[ogunit]/PdROIRef[ogunit])^PdVF[ogunit]),
        PdMaxM[ogunit]),PdMinM[ogunit])
      PdRateM[ogunit] = max(PdRateM[ogunit],PdRateMRef[ogunit])
      PdRate[ogunit] = xPdRate[ogunit]*PdRateM[ogunit]
      Pd[ogunit] = min(RsDevPrior[ogunit]*PdRate[ogunit],PdMax[ogunit])

    #
    # For Method 6 Development Rate (PdRate) is non-symetric where the
    # Production Rate Multiplier (PdRateM) does not drop below 90% of the Reference case
    #
    elseif PdSw[ogunit] == 6
      @finite_math PdRateM[ogunit] = max(min((1+PdVar[ogunit])/(PdVar[ogunit]+
        (PdROI[ogunit]/PdROIRef[ogunit])^PdVF[ogunit]),
        PdMaxM[ogunit]),PdMinM[ogunit])
      PdRateM[ogunit] = max(PdRateM[ogunit],PdRateMRef[ogunit]*0.90)
      PdRate[ogunit] = xPdRate[ogunit]*PdRateM[ogunit]
      Pd[ogunit] = min(RsDevPrior[ogunit]*PdRate[ogunit],PdMax[ogunit])

    #
    # For Method 0 Production (Pd) is an input (xPd)
    #
    elseif PdSw[ogunit] == 0
      Pd[ogunit] = xPd[ogunit]
      @finite_math PdRate[ogunit] = Pd[ogunit]/RsDevPrior[ogunit]
      PdRateM[ogunit] = 1

    end
  end

  WriteDisk(db,"SpOutput/Pd",year,Pd)
  WriteDisk(db,"SpOutput/PdRate",year,PdRate)
  WriteDisk(db,"SpOutput/PdRateM",year,PdRateM)

end

function EORProduction(data::Data)
  (; db,year) = data
  (; Area,Areas,Process) = data #sets
  (; DevSw,OAPrEORPrior,OGArea,OGECC,OGProcess,Pd,PdRate,PdTotal,RsDevPrior) = data

  # @info "  SpOGProd.jl - EORProduction - Enhanced Oil and Gas Production"

  #
  # EOR from sequestered CO2 in Canada
  #
  EORProcesses = Select(Process,["LightOilMining","FrontierOilMining"])
  for area in Areas, process in EORProcesses
    if (OAPrEORPrior[process,area] != 0)
      ogunits_p = findall(OGProcess[:] .== Process[process])
      ogunits_a = findall(OGArea[:] .== Area[area])
      ogunits = intersect(ogunits_p,ogunits_a)
      if !isempty(ogunits)
        PdTotal[process,area] = sum(Pd[ogunit] for ogunit in ogunits)
        for ogunit in ogunits
          if (OGECC[ogunit] == Process[process]) && (OGArea[ogunit] == Area[area])
            if DevSw[ogunit] != 0
              @finite_math Pd[ogunit] = Pd[ogunit]*(1+OAPrEORPrior[process,area]/PdTotal[process,area])
              @finite_math PdRate[ogunit] = Pd[ogunit]/RsDevPrior[ogunit]
            end
          end
        end
      end
    end
  end

  WriteDisk(db,"SpOutput/Pd",year,Pd)
  WriteDisk(db,"SpOutput/PdRate",year,PdRate)

end

function UpdateResourcesLevels(data::Data)
  (; db,year) = data
  (; Dev,OGCounter,OGProcess,Pd,PdCum,PdCumPrior,RsDev,RsDevPrior,RsUndev,RsUndevPrior,xRvUndev) = data

  # @info "  SpOGProd.jl - UpdateResourcesLevels - Oil and Gas Production Resources"

  for ogunit in 1:Int(OGCounter)
    area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

    #
    # Undeveloped Resources (RsUndev) are Undeveloped Resources (RsUndev) in the
    # previous period plus Revisions to Undeveloped Resources (xRvUndev) minus
    # Development of Resources (Dev).
    #
    RsUndev[ogunit] = RsUndevPrior[ogunit]+xRvUndev[ogunit]-Dev[ogunit]

    #
    # Developed Resources (RsDev) are Developed Resources (RsDev)
    # in the previous year plus Development of Resources (Dev) less
    # Production (Pd).
    #
    if (OGProcess[ogunit] == "LNGProduction")
      RsDev[ogunit] = RsDevPrior[ogunit]+Dev[ogunit]
    else
      RsDev[ogunit] = RsDevPrior[ogunit]+Dev[ogunit]-Pd[ogunit]
    end

    #
    # Cumulative Production
    #
    PdCum[ogunit] = PdCumPrior[ogunit]+Pd[ogunit]

  end

  WriteDisk(db,"SpOutput/PdCum",year,PdCum)
  WriteDisk(db,"SpOutput/RsDev",year,RsDev)
  WriteDisk(db,"SpOutput/RsUndev",year,RsUndev)

end

function AggrgateUnits(data::Data)
  (; db,year) = data
  (; Areas,ProcOG,ProcOGs) = data #sets
  (; OAProd,GAProd,G2NProd,LNGProdMin,RsUnpOG,RsDevOG) = data
  (; DevOG,PdOG,PdCumOG,OGCounter,OGOGSw,Pd,OGProcess) = data
  (; OGCode,RsUndev,RsDev,Dev,PdCum,DevRaOG,PdRaOG) = data
  (; RsUnpOGPrior,RsDevOGPrior) = data

  # @info "  SpOGProd.jl - AggrgateUnits - Aggregate Production for Oil and Gas Units"

  @. OAProd = 0
  @. GAProd = 0
  @. G2NProd = 0
  @. LNGProdMin = 0
  @. RsUnpOG = 0
  @. RsDevOG = 0
  @. DevOG = 0
  @. PdOG = 0
  @. PdCumOG = 0

  for ogunit in 1:Int(OGCounter)
    area,ecc,process,fuelog,procog,gnode,nation,OGUnitIsValid = OGSetSelect(data,ogunit)

    if OGUnitIsValid == "True"
      #
      # If Oil Production
      #
      if OGOGSw[ogunit] == "Oil"
        OAProd[process,area] = OAProd[process,area]+Pd[ogunit]

      #
      # Else Natural Gas Production
      #
      else OGOGSw[ogunit] == "Gas"
        GAProd[process,area] = GAProd[process,area]+Pd[ogunit]
        G2NProd[gnode] = G2NProd[gnode]+Pd[ogunit]

        if (OGProcess[ogunit] == "LNGProduction") && (OGCode[ogunit] != "WSC_LNG_0001")
          LNGProdMin[nation] = LNGProdMin[nation]+Pd[ogunit]
        end
      end
      #
      # Totals by Product and Area
      #
      if OGProcess[ogunit] == ProcOG[procog]
        RsUnpOG[procog,area] = RsUnpOG[procog,area]+RsUndev[ogunit]
        RsDevOG[procog,area] = RsDevOG[procog,area]+RsDev[ogunit]
        DevOG[procog,area] = DevOG[procog,area]+Dev[ogunit]
        PdOG[procog,area] = PdOG[procog,area]+Pd[ogunit]
        PdCumOG[procog,area] = PdCumOG[procog,area]+PdCum[ogunit]
      end
    end
  end

  WriteDisk(db,"SOutput/GAProd",year,GAProd)
  WriteDisk(db,"SpOutput/G2NProd",year,G2NProd)
  WriteDisk(db,"SOutput/LNGProdMin",year,LNGProdMin)
  WriteDisk(db,"SOutput/OAProd",year,OAProd)
  WriteDisk(db,"SpOutput/RsUnpOG",year,RsUnpOG)
  WriteDisk(db,"SpOutput/RsDevOG",year,RsDevOG)
  WriteDisk(db,"SpOutput/DevOG",year,DevOG)
  WriteDisk(db,"SpOutput/PdOG",year,PdOG)
  WriteDisk(db,"SpOutput/PdCumOG",year,PdCumOG)

  #
  # Averages by Product and Area
  #
  for area in Areas, procog in ProcOGs
    @finite_math DevRaOG[procog,area] = DevOG[procog,area]/RsUnpOGPrior[procog,area]
    @finite_math PdRaOG[procog,area] = PdOG[procog,area]/RsDevOGPrior[procog,area]
  end

  WriteDisk(db,"SpOutput/DevRaOG",year,DevRaOG)
  WriteDisk(db,"SpOutput/PdRaOG",year,PdRaOG)

end

function AssociatedGas(data::Data)
  (; db,year) = data
  (; Area,Areas,Process,Processes) = data #sets
  (; GAProd,OAProd,xGAProd,xOAProd) = data
  LightOil::VariableArray{1} = zeros(Float32,length(Area))
  LightOilRef::VariableArray{1} = zeros(Float32,length(Area))

  # @info "  SpOGProd.jl - AssociatedGas"

  #
  # Associated Gas Production is from Light Oil - Jeff Amlin 05/20/21
  #
  for area in Areas
  
    processes = Select(Process,["LightOilMining","FrontierOilMining"])
    LightOil[area] = sum(OAProd[process,area] for process in processes)
    LightOilRef[area] = sum(xOAProd[process,area] for process in processes)
  
    for process in Processes
      if Process[process] == "AssociatedGasProduction"
        @finite_math GAProd[process,area] = xGAProd[process,area]*LightOil[area]/LightOilRef[area]
      end
    end
    
  end
  
  WriteDisk(db,"SOutput/GAProd",year,GAProd)  

end

function NGLiquids(data::Data)
  (; db,year) = data
  (; Area,Areas,Process,Processes) = data #sets
  (; OAProd,GAProd,NGLiquidsFraction) = data
  GasProduction::VariableArray{1} = zeros(Float32,length(Area))

  # @info "  SpOGProd.jl - NGLiquids"

  #
  # NG Liquids do not come from Associated Gas Production - Jeff Amlin 05/20/21
  #
  for area in Areas
  
    processes = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction"])
    GasProduction[area] = sum(GAProd[process,area] for process in processes)
    
    for process in Processes
      if (Process[process] == "PentanesPlus") || (Process[process] == "Condensates")
        OAProd[process,area] = GasProduction[area]*NGLiquidsFraction[process,area]
      end
    end
    
  end
  
  WriteDisk(db,"SOutput/OAProd",year,OAProd)

end

function GasProcessing(data::Data)
  (; db,year) = data
  (; Area,Areas,Process,Processes) = data #sets
  (; GAProd,GasProcessingFraction,GasProcessingSwitch,GasProductionMap) = data
  GasProduction::VariableArray{1} = zeros(Float32,length(Area))

  # @info "  SpOGProd.jl - GasProcessing - Sweet and Sour Gas Processing"

  for area in Areas
    GasProduction[area] = sum(GAProd[process,area]*GasProductionMap[process] for process in Processes)
    for process in Processes
      if (Process[process] == "SweetGasProcessing") || (Process[process] == "SourGasProcessing")
        GAProd[process,area] = GasProduction[area]*GasProcessingFraction[process,area]*GasProcessingSwitch[area]
        WriteDisk(db,"SOutput/GAProd",year,GAProd)
      end
    end
  end

end

function NationalTotals(data::Data)
  (; db,year) = data
  (; Areas,Nations,Processes) = data #sets
  (; ANMap,GAProd,GProd,OAProd,OProd) = data

  # @info "  SpOGProd.jl - NationalTotals"

  for nation in Nations, process in Processes
    GProd[process,nation] = sum(GAProd[process,area]*ANMap[area,nation] for area in Areas)
    OProd[process,nation] = sum(OAProd[process,area]*ANMap[area,nation] for area in Areas)
  end

  WriteDisk(db,"SOutput/GProd",year,GProd)
  WriteDisk(db,"SOutput/OProd",year,OProd)

end

function Control(data::Data)
  (; year) = data
  (; Endogenous,PI,ProcSw) = data #sets
  (; xProcSw) = data



  # @info "  SpOGProd.jl - Control - Oil and Gas Production Control"

  OGProd = Select(PI,"OGProd")
  ProcSw[OGProd] = xProcSw[OGProd]

  # if (ProcSw[OGProd] == Endogenous) && (ModSwitch != "NEB")
  if (ProcSw[OGProd] == Endogenous) 
    #
    # Initialize historical years
    #
    if year < Last
      Initial(data)
    end

    EcoMultipliers(data)
    CtrlEconomics(data)
    Development(data)
    Production(data)
    EORProduction(data)
    UpdateResourcesLevels(data)
    AggrgateUnits(data)
    AssociatedGas(data)
    NGLiquids(data)
    GasProcessing(data)
    NationalTotals(data)
    FindPrice(data)
    
  end

end # function Control

end # module SpOGProd
