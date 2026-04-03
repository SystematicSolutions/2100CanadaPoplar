#
# OGUnitDetails.jl
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}


import ...EnergyModel: ITime

Base.@kwdef struct OGUnitDetailsData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}    = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCKey::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int}     = collect(Select(ECC))
  Fuel::SetArray   = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int}    = collect(Select(Fuel))
  FuelOG::SetArray = ReadDisk(db, "MainDB/FuelOGKey")
  FuelOGDS::SetArray = ReadDisk(db, "MainDB/FuelOGDS")
  FuelOGs::Vector{Int}    = collect(Select(FuelOG))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Process::SetArray = ReadDisk(db, "MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db, "MainDB/ProcessDS")
  Year::SetArray   = ReadDisk(db,"MainDB/YearKey")

  CDTime::Int = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)

  ByFrac::VariableArray{2} = ReadDisk(db, "SpInput/ByFrac") #[OGUnit,Year]  Byproducts Fraction (Btu/Btu)
  ByPrice::VariableArray{2} = ReadDisk(db, "SpOutput/ByPrice") #[OGUnit,Year]  Byproducts Price ($/mmBtu)
  ByRev::VariableArray{2} = ReadDisk(db, "SpOutput/ByRev") #[OGUnit,Year]  Byproducts Revenue ($/mmBtu)
  CCMDem::VariableArray{2} = ReadDisk(db, "SpOutput/CCMDem") #[OGUnit,Year]  Capital Cost Multiplier from Demand Module ($/$)
  CCMDemSw::VariableArray{2} = ReadDisk(db, "SpInput/CCMDemSw") #[OGUnit,Year]  Switch to Activate the Capital Cost Multiplier (1 = on)
  Dev::VariableArray{2} = ReadDisk(db, "SpOutput/Dev") #[OGUnit,Year]  Development of Resources (TBtu/Yr)
  DevCap::VariableArray{2} = ReadDisk(db, "SpOutput/DevCap") #[OGUnit,Year]  Development Capital Costs ($/mmBtu)
  DevDep::VariableArray{2} = ReadDisk(db, "SpOutput/DevDep") #[OGUnit,Year]  Development Depreciation ($/mmBtu)
  DevDM::VariableArray{2} = ReadDisk(db, "SpOutput/DevDM") #[OGUnit,Year]  Development Cost Delpletion Multiplier ($/$)
  DevDMB0::VariableArray{2} = ReadDisk(db, "SpInput/DevDMB0") #[OGUnit,Year]  Development Costs Depletion Multiplier Coefficient ($/$)
  DevDpRate::VariableArray{2} = ReadDisk(db, "SpInput/DevDpRate") #[OGUnit,Year]  Development Depreciation Rate ($/$)
  DevExp::VariableArray{2} = ReadDisk(db, "SpOutput/DevExp") #[OGUnit,Year]  Development Expenses ($/mmBtu)
  DevIM::VariableArray{2} = ReadDisk(db, "SpOutput/DevIM") #[OGUnit,Year]  Development Cost Infrastructure Multiplier ($/$)
  DevITax::VariableArray{2} = ReadDisk(db, "SpOutput/DevITax") #[OGUnit,Year]  Development Income Taxes ($/mmBtu)
  DevLCM::VariableArray{2} = ReadDisk(db, "SpOutput/DevLCM") #[OGUnit,Year]  Development Cost Learning Curve Multiplier ($/$)
  DevLCMB0::VariableArray{2} = ReadDisk(db, "SpInput/DevLCMB0") #[OGUnit,Year]  Development Costs Learning Curve Multiplier Coefficient ($/$)
  DevMaxM::VariableArray{2} = ReadDisk(db, "SpInput/DevMaxM") #[OGUnit,Year]  Development Rate Maximum Multiplier from ROI (Btu/Btu)
  DevMinM::VariableArray{2} = ReadDisk(db, "SpInput/DevMinM") #[OGUnit,Year]  Development Rate Minimum Multiplier from ROI (Btu/Btu)
  DevNtInc::VariableArray{2} = ReadDisk(db, "SpOutput/DevNtInc") #[OGUnit,Year]  Development Net Income ($/mmBtu)
  DevRate::VariableArray{2} = ReadDisk(db, "SpOutput/DevRate") #[OGUnit,Year]  Development Rate (Btu/Btu)
  DevRateM::VariableArray{2} = ReadDisk(db, "SpOutput/DevRateM") #[OGUnit,Year]  Development Rate Multiplier (Btu/Btu)
  DevRateMRef::VariableArray{2} = ReadDisk(db, "SpOutput/DevRateM") #[OGUnit,Year]  Development Rate Multiplier (Btu/Btu)
  DevROI::VariableArray{2} = ReadDisk(db, "SpOutput/DevROI") #[OGUnit,Year]  Development Return on Investment ($/$)
  DevSw::VariableArray{2} = ReadDisk(db, "SpInput/DevSw") #[OGUnit,Year]  Development Switch
  DevVar::VariableArray{2} = ReadDisk(db, "SpInput/DevVar") #[OGUnit,Year]  Development Rate Variance (Btu/Btu)
  DevVF::VariableArray{2} = ReadDisk(db, "SpInput/DevVF") #[OGUnit,Year]  Development Rate Variance Factor for ROI (Btu/Btu)
  DilCosts::VariableArray{2} = ReadDisk(db, "SpOutput/DilCosts") #[OGUnit,Year]  Diluent Costs ($/mmBtu)
  DilFrac::VariableArray{2} = ReadDisk(db, "SpInput/DilFrac") #[OGUnit,Year]  Diluent Fraction (Btu/Btu)
  DilPrice::VariableArray{2} = ReadDisk(db, "SpOutput/DilPrice") #[OGUnit,Year]  Diluent Price ($/mmBtu)
  eCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") #[Nation,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  FkCosts::VariableArray{2} = ReadDisk(db, "SpOutput/FkCosts") #[OGUnit,Year]  Feedstock Costs ($/mmBtu)
  FkFrac::VariableArray{2} = ReadDisk(db, "SpInput/FkFrac") #[OGUnit,Year]  Feedstock Fraction (Btu/Btu)
  FkPrice::VariableArray{2} = ReadDisk(db, "SpOutput/FkPrice") #[OGUnit,Year]  Feedstock Price ($/mmBtu)
  FlCosts::VariableArray{3} = ReadDisk(db, "SOutput/FlCosts") #[ECC,Area,Year]  Flaring Reduction Costs ($/TBtu)
  FuCosts::VariableArray{3} = ReadDisk(db, "SOutput/FuCosts") #[ECC,Area,Year]  Other Fugitives Reduction Costs ($/mmBtu)
  GRRMax::VariableArray{2} = ReadDisk(db, "SpInput/GRRMax") #[OGUnit,Year]  Maximum Gross Revenue Royalty Rate ($/$)
  GRRMin::VariableArray{2} = ReadDisk(db, "SpInput/GRRMin") #[OGUnit,Year]  Minimum Gross Revenue Royalty Rate ($/$)
  GRRPr::VariableArray{2} = ReadDisk(db, "SpInput/GRRPr") #[OGUnit,Year]  Gross Revenue Royalty Rate Slope to Price ($/$)
  GRRPr0::VariableArray{2} = ReadDisk(db, "SpInput/GRRPr0") #[OGUnit,Year]  Gross Revenue Royalty Rate Intercept ($/$)
  GRRRate::VariableArray{2} = ReadDisk(db, "SpOutput/GRRRate") #[OGUnit,Year]  Gross Revenue Royalty Rate ($/$)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationOGUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationOGUnit") #[OGUnit,Year]  Inflation Index ($/$)
  MeanEUR::VariableArray{2} = ReadDisk(db, "SpInput/MeanEUR") #[OGUnit,Year]  Mean Expected Ultimate Recovery (TBtu/Well)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  NetRev::VariableArray{2} = ReadDisk(db, "SpOutput/NetRev") #[OGUnit,Year]  Net Revenues for Royalty Calcuatlion ($/mmBtu)
  NewWells::VariableArray{2} = ReadDisk(db, "SpOutput/NewWells") #[OGUnit,Year]  Number of New Wells
  NRRMax::VariableArray{2} = ReadDisk(db, "SpInput/NRRMax") #[OGUnit,Year]  Maximum Net Revenue Royalty Rate ($/$)
  NRRMin::VariableArray{2} = ReadDisk(db, "SpInput/NRRMin") #[OGUnit,Year]  Minimum Net Revenue Royalty Rate ($/$)
  NRRPr::VariableArray{2} = ReadDisk(db, "SpInput/NRRPr") #[OGUnit,Year]  Net Revenue Royalty Rate Slope to Price ($/$)
  NRRPr0::VariableArray{2} = ReadDisk(db, "SpInput/NRRPr0") #[OGUnit,Year]  Net Revenue Royalty Rate Intercept ($/$)
  NRRRate::VariableArray{2} = ReadDisk(db, "SpOutput/NRRRate") #[OGUnit,Year]  Net Revenue Royalty Rate ($/$)
  OAPrEOR::VariableArray{3} = ReadDisk(db, "SOutput/OAPrEOR") # Oil Production from EOR (TBtu/Yr) [Process,Area]
  OAProd::VariableArray{3} = ReadDisk(db, "SOutput/OAProd") # [Process,Area,Year]  Primary Oil Production (TBtu/Yr)
  
  OffRevenue::VariableArray{4} = ReadDisk(db,"SOutput/OffRevenue") # [ECC,Poll,Area,Year]  Offset Revenue including Sequestering (M$/Yr)
  Offsets::VariableArray{4} = ReadDisk(db,"SOutput/Offsets") # [ECC,Poll,Area,Year]  Offsets including Sequestering (Tonnes/Yr)
  
  OGAbCFr::VariableArray{2} = ReadDisk(db, "SpInput/OGAbCFr") #[OGUnit,Year]  Abandonment Costs Fraction ($/$)
  OGAbCosts::VariableArray{2} = ReadDisk(db, "SpOutput/OGAbCosts") #[OGUnit,Year]  Abandonment Costs ($/mmBtu)
  OGArea::Vector{String} = ReadDisk(db, "SpInput/OGArea") #[OGUnit]  OG Unit Area
  OGCapCosts::VariableArray{2} = ReadDisk(db, "SpOutput/OGCapCosts") #[OGUnit,Year]  Capital Costs ($/mmBtu)
  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode") #[OGUnit]  OG Unit Code
  OGCounter::VariableArray{1} = ReadDisk(db, "SpInput/OGCounter") #[Year]  Number of OG Units for this Year (Number)
  OGDep::VariableArray{2} = ReadDisk(db, "SpOutput/OGDep") #[OGUnit,Year]  Depreciation ($/mmBtu)
  OGECC::Vector{String} = ReadDisk(db, "SpInput/OGECC") #[OGUnit]  OG Unit ECC
  OGENPN::VariableArray{3} = ReadDisk(db, "SpOutput/OGENPN") #[FuelOG,Nation,Year]  Wholesale Price used to compute Product Price ($/mmBtu)
  OGFCosts::VariableArray{2} = ReadDisk(db, "SpOutput/OGFCosts") #[OGUnit,Year]  Fuel Costs ($/mmBtu)
  OGFP::VariableArray{2} = ReadDisk(db, "SpOutput/OGFP") #[OGUnit,Year]  Product Price ($/mmBtu)
  OGFPAdd::VariableArray{2} = ReadDisk(db, "SpInput/OGFPAdd") #[OGUnit,Year]  Price Adder for Supply Cost Search ($/mmBtu)
  OGFPDChg::VariableArray{2} = ReadDisk(db, "SpInput/OGFPDChg") #[OGUnit,Year]  Product Price Delivery Charge ($/mmBtu)
  OGFPMax::VariableArray{2} = ReadDisk(db, "SpInput/OGFPMax") #[OGUnit,Year]  Maximum Price for Supply Cost Search ($/mmBtu)
  OGFPMin::VariableArray{2} = ReadDisk(db, "SpInput/OGFPMin") #[OGUnit,Year]  Inital Price for Supply Cost Search ($/mmBtu)
  OGFPrice::VariableArray{3} = ReadDisk(db, "SpOutput/OGFPrice") #[OGUnit,Fuel,Year]  Price for Fuel Purchased ($/mmBtu)
  OGFuel::Vector{String} = ReadDisk(db, "SpInput/OGFuel") #[OGUnit]  Fuel Type
  OGFUse::VariableArray{3} = ReadDisk(db, "SpOutput/OGFUse") #[OGUnit,Fuel,Year]  Fuel Usage (Btu/Btu)
  OGITxRate::VariableArray{2} = ReadDisk(db, "SpInput/OGITxRate") #[OGUnit,Year]  Income Tax Rate ($/$)
  OGName::Vector{String} = ReadDisk(db, "SpInput/OGNode") #[OGUnit]  OG Unit Name
  OGNation::Vector{String} = ReadDisk(db, "SpInput/OGNation") #[OGUnit]  OG Unit Nation
  OGNode::Vector{String} = ReadDisk(db, "SpInput/OGNode") #[OGUnit]  OG Unit Gas Transmission Node
  OGOGSw::Vector{String} = ReadDisk(db, "SpInput/OGOGSw") #[OGUnit]  OG Unit Oil or Gas Switch
  OGOMCosts::VariableArray{2} = ReadDisk(db, "SpOutput/OGOMCosts") #[OGUnit,Year]  O&M Costs ($/mmBtu)
  OGOpCosts::VariableArray{2} = ReadDisk(db, "SpOutput/OGOpCosts") #[OGUnit,Year]  Operatng Costs ($/mmBtu)
  OGPolCosts::VariableArray{2} = ReadDisk(db, "SpOutput/OGPolCosts") #[OGUnit,Year]  Pollution Costs ($/mmBtu)
  OGPolPrice::VariableArray{3} = ReadDisk(db, "SpOutput/OGPolPrice") #[OGUnit,Fuel,Year]  Pollution Cost for Fuel Purchased ($/mmBtu)
  OGPrSw::VariableArray{2} = ReadDisk(db, "SpInput/OGPrSw") #[OGUnit,Year]  OG Price Switch
  OGProcess::Vector{String} = ReadDisk(db, "SpInput/OGProcess") #[OGUnit]  OG Unit Production Process
  OGRev::VariableArray{2} = ReadDisk(db, "SpOutput/OGRev") #[OGUnit,Year]  Revenues ($/mmBtu)
  OGROIN::VariableArray{2} = ReadDisk(db, "SpInput/OGROIN") #[OGUnit,Year]  Return on Investment Normal ($/Yr/$)
  OpDM::VariableArray{2} = ReadDisk(db, "SpOutput/OpDM") #[OGUnit,Year]  Operating Cost Delpletion Multiplier ($/$)
  OpDMB0::VariableArray{2} = ReadDisk(db, "SpInput/OpDMB0") #[OGUnit,Year]  Operating Costs Depletion Multiplier Coefficient ($/$)
  OpExp::VariableArray{2} = ReadDisk(db, "SpOutput/OpExp") #[OGUnit,Year]  Operating Expenses ($/mmBtu)
  OpLCM::VariableArray{2} = ReadDisk(db, "SpOutput/OpLCM") #[OGUnit,Year]  Operating Costs Learning Curve Multiplier ($/$)
  OpLCMB0::VariableArray{2} = ReadDisk(db, "SpInput/OpLCMB0") #[OGUnit,Year]  Operating Costs Learning Curve Multiplier Coefficient ($/$)
  OpWrkCap::VariableArray{2} = ReadDisk(db, "SpOutput/OpWrkCap") #[OGUnit,Year]  Operating Working Capital ($/mmBtu)
  OWCDays::VariableArray{2} = ReadDisk(db, "SpInput/OWCDays") #[OGUnit,Year]  Operating Working Capital Days Payment (Days)
  PBuy::VariableArray{4} = ReadDisk(db, "SOutput/PBuy") # [ECC,Poll,Area,Year] Permits Bought (Tonnes/Year)
  
  Pd::VariableArray{2} = ReadDisk(db, "SpOutput/Pd") #[OGUnit,Year]  Production (TBtu/Yr)
  Pd3::VariableArray{2} = ReadDisk(db, "SpOutput/Pd3") #[OGUnit,Year]  Production (TBtu/Yr)
  Pd3Cum::VariableArray{2} = ReadDisk(db, "SpOutput/Pd3Cum") #[OGUnit,Year]  Cumulative Production after Pipeline Constraints (TBtu/Yr)
  PdC0OG::VariableArray{2} = ReadDisk(db, "SpInput/PdC0OG") #[OGUnit,Year]  Learning Curve Initial Cumulative Production (TBtu)
  PdCum::VariableArray{2} = ReadDisk(db, "SpOutput/PdCum") #[OGUnit,Year]  Cumulative Production (TBtu)
  PdExp::VariableArray{2} = ReadDisk(db, "SpOutput/PdExp") #[OGUnit,Year]  Production Expenses ($/mmBtu)
  PdITax::VariableArray{2} = ReadDisk(db, "SpOutput/PdITax") #[OGUnit,Year]  Production Income Taxes ($/mmBtu)
  PdMax::VariableArray{2} = ReadDisk(db, "SpInput/PdMax") #[OGUnit,Year]  Maximum Production Rate (Btu/Btu)
  PdMaxM::VariableArray{2} = ReadDisk(db, "SpInput/PdMaxM") #[OGUnit,Year]  Production Rate Maximum Multiplier from ROI (Btu/Btu)
  PdMinM::VariableArray{2} = ReadDisk(db, "SpInput/PdMinM") #[OGUnit,Year]  Production Rate Minimum Multiplier from ROI (Btu/Btu)
  PdNtInc::VariableArray{2} = ReadDisk(db, "SpOutput/PdNtInc") #[OGUnit,Year]  Production Net Income ($/mmBtu)
  PdRate::VariableArray{2} = ReadDisk(db, "SpOutput/PdRate") #[OGUnit,Year]  Production Rate (Btu/Btu)
  PdRateM::VariableArray{2} = ReadDisk(db, "SpOutput/PdRateM") #[OGUnit,Year]  Production Rate Multiplier (Btu/Btu)
  PdROI::VariableArray{2} = ReadDisk(db, "SpOutput/PdROI") #[OGUnit,Year]  Production Return on Investment ($/$)
  PdSw::VariableArray{2} = ReadDisk(db, "SpInput/PdSw") #[OGUnit,Year]  Production Switch
  PdVar::VariableArray{2} = ReadDisk(db, "SpInput/PdVar") #[OGUnit,Year]  Production Rate Variance (Btu/Btu)
  PdVF::VariableArray{2} = ReadDisk(db, "SpInput/PdVF") #[OGUnit,Year]  Production Rate Variance Factor for ROI (Btu/Btu)

  PExp::VariableArray{4} = ReadDisk(db,"SOutput/PExp") # [ECC,Poll,Area,Year] Permits Expenditures (M$/Yr)
  PExpExo::VariableArray{4} = ReadDisk(db, "SInput/PExpExo") # [ECC,Poll,Area,Year] Exogenous Permits Expenditures (M$/Year)  
  PGratis::VariableArray{5} = ReadDisk(db, "SOutput/PGratis") # [ECC,Poll,PCov,Area,Year] Gratis Permits (Tonnes/Year)
  PNeed::VariableArray{4} = ReadDisk(db, "SOutput/PNeed") # [ECC,Poll,Area,Year] Permits Needed (Tonnes/Year)
  PSell::VariableArray{4} = ReadDisk(db, "SOutput/PSell") # [ECC,Poll,Area,Year] Permits Sold (Tonnes/Year)

  ROITarget::VariableArray{2} = ReadDisk(db, "SpInput/ROITarget") #[OGUnit,Year]  ROI Target for Supply Cost Search ($/$)
  RsD0OG::VariableArray{2} = ReadDisk(db, "SpOutput/RsD0OG") #[OGUnit,Year]  Learning Curve Initial Developed Resources (TBtu)
  RsDev::VariableArray{2} = ReadDisk(db, "SpOutput/RsDev") #[OGUnit,Year]  Developed Resources (TBtu)
  RsUndev::VariableArray{2} = ReadDisk(db, "SpOutput/RsUndev") #[OGUnit,Year]  Undeveloped Resources (TBtu)
  RyFP::VariableArray{2} = ReadDisk(db, "SpOutput/RyFP") #[OGUnit,Year]  Fuel Price used to compute Royalties ($/mmBtu)
  RyLev::VariableArray{2} = ReadDisk(db, "SpOutput/RyLev") #[OGUnit,Year]  Levelized Royalty Payments ($/mmBtu))
  RyLevFactor::VariableArray{2} = ReadDisk(db, "SpInput/RyLevFactor") #[OGUnit,Year]  Royalty Levelization Factor ($/$)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  SCFP::VariableArray{2} = ReadDisk(db, "SpOutput/SCFP") #[OGUnit,Year]  Supply Cost ($/mmBtu)
  SCITax::VariableArray{2} = ReadDisk(db, "SpOutput/SCITax") #[OGUnit,Year]  Supply Cost Income Tax ($/mmBtu)
  SCNtInc::VariableArray{2} = ReadDisk(db, "SpOutput/SCNtInc") #[OGUnit,Year]  Supply Cost Net Income ($/mmBtu)
  SCRyFP::VariableArray{2} = ReadDisk(db, "SpOutput/SCRyFP") #[OGUnit,Year]  Fuel Price used to compute Supply Cost Royalties ($/mmBtu)
  SCRyLev::VariableArray{2} = ReadDisk(db, "SpOutput/SCRyLev") #[OGUnit,Year]  Supply Cost Royalties ($/mmBtu)
  SusCap::VariableArray{2} = ReadDisk(db, "SpOutput/SusCap") #[OGUnit,Year]  Sustaining Capital Costs ($/mmBtu)
  SusDep::VariableArray{2} = ReadDisk(db, "SpOutput/SusDep") #[OGUnit,Year]  Sustaining Depreciation ($/mmBtu)
  SusDpRate::VariableArray{2} = ReadDisk(db, "SpInput/SusDpRate") #[OGUnit,Year]  Sustaining Depreciation Rate ($/$)
  VnCosts::VariableArray{3} = ReadDisk(db, "SOutput/VnCosts") #[ECC,Area,Year]  Venting Reduction Costs ($/mmBtu)
  xDev::VariableArray{2} = ReadDisk(db, "SpInput/xDev") #[OGUnit,Year]  Historical Development of Resources (TBtu/Yr)
  xDevCap::VariableArray{2} = ReadDisk(db, "SpInput/xDevCap") #[OGUnit,Year]  Exogenous Development Capital Costs ($/mmBtu)
  xDevRate::VariableArray{2} = ReadDisk(db, "SpInput/xDevRate") #[OGUnit,Year]  Exogenous Development Rate (Btu/Btu)
  xOAProd::VariableArray{3} = ReadDisk(db, "SInput/xOAProd") #[Process,Area,Year]  Oil Production (TBtu/Yr)
  xOGFP::VariableArray{2} = ReadDisk(db, "SpInput/xOGFP") #[OGUnit,Year]  Historical OG Price ($/mmBtu)
  xOGOMCosts::VariableArray{2} = ReadDisk(db, "SpInput/xOGOMCosts") #[OGUnit,Year]  O&M Costs ($/mmBtu)
  xPd::VariableArray{2} = ReadDisk(db, "SpInput/xPd") #[OGUnit,Year]  Historical Production (TBtu/Yr)
  xPdCum::VariableArray{2} = ReadDisk(db, "SpInput/xPdCum") #[OGUnit,Year]  Historical Cumulative Production (TBtu/Yr)
  xPdRate::VariableArray{2} = ReadDisk(db, "SpInput/xPdRate") #[OGUnit,Year]  Historical Production Rate (Btu/Btu)
  xRsDev::VariableArray{2} = ReadDisk(db, "SpInput/xRsDev") #[OGUnit,Year]  Historical Developed Resources (TBtu)
  xRsUndev::VariableArray{2} = ReadDisk(db, "SpInput/xRsUndev") #[OGUnit,Year]  Historical Undeveloped Resources (TBtu)
  xRvUndev::VariableArray{2} = ReadDisk(db, "SpInput/xRvUndev") #[OGUnit,Year]  Revisions to Undeveloped Resources (TBtu)
  xSusCap::VariableArray{2} = ReadDisk(db, "SpInput/xSusCap") #[OGUnit,Year]  Exogenous Sustaining Capital Costs ($/mmBtu)
end

function OGUnitDetails_DtaRun(data,ogunit)
  (; Area, AreaDS, Areas, Nation, ECC,ECCs, Fuel, FuelDS, Fuels, FuelOG, FuelOGDS, FuelOGs, Poll,Polls,Process, ProcessDS, Year) = data
  (; ByFrac,ByPrice,ByRev,CCMDem,CCMDemSw,Dev,DevCap,DevDep,DevDM,DevDMB0,DevDpRate,DevExp,DevIM,DevITax,DevLCM,
  DevLCMB0,DevMaxM,DevMinM,DevNtInc,DevRate,DevRateM,DevRateMRef,DevROI,DevSw,DevVar,DevVF,DilCosts,DilFrac,
  DilPrice,ENPN,FkCosts,FkFrac,FkPrice,FlCosts,FuCosts,GRRMax,GRRMin,GRRPr,GRRPr0,GRRRate,
  MeanEUR,MoneyUnitDS,NetRev,NewWells,NRRMax,NRRMin,NRRPr,NRRPr0,NRRRate,OAPrEOR,OAProd,OGAbCFr,
  OGAbCosts,OGArea,OGCapCosts,OGCode,OGDep,OGECC,OGENPN,OGFCosts,OGFP,OGFPAdd,OGFPDChg,OGFPMax,OGFPMin,
  OGFPrice,OGFuel,OGFUse,OGITxRate,OGName,OGNation,OGNode,OGOGSw,OGOMCosts,OGOpCosts,OGPolCosts,OGPolPrice,OGPrSw,
  OGProcess,OGRev,OGROIN,OpDM,OpDMB0,OpExp,OpLCM,OpLCMB0,OpWrkCap,OWCDays,Pd,Pd3,Pd3Cum,PdC0OG,PdCum,PdExp,PdITax,
  PdMax,PdMaxM,PdMinM,PdNtInc,PdRate,PdRateM,PdROI,PdSw,PdVar,PdVF,ROITarget,RsD0OG,RsDev,RsUndev,RyFP,RyLev,
  RyLevFactor,SceName,SCFP,SCITax,SCNtInc,SCRyFP,SCRyLev,SusCap,SusDep,SusDpRate,VnCosts,xDev,xDevCap,xDevRate,xOAProd,
  xOGFP,xOGOMCosts,xPd,xPdCum,xPdRate,xRsDev,xRsUndev,xRvUndev,xSusCap) = data
  (; InflationOGUnit, ExchangeRateNation, CDTime, CDYear) = data
  (; eCO2Price,Inflation,PBuy,PExp,PExpExo,PGratis,PNeed,PSell) = data
  (; OffRevenue,Offsets) = data
  
  #
  #  Select Units for Physical Variables
  #
  if OGOGSw[ogunit] == "Oil"
    DsLevel      = "MMB"
    DsFinancial  = "bbl"
    ConvLevel    = 5.8
    DsRate       = "PD"
    ConvRate     = 365
  else
    DsLevel      = "TBtu"
    DsFinancial  = "mmBtu"
    ConvLevel    = 1
    DsRate       = "/Yr"
    ConvRate     = 1
  end

  area = Select(Area, OGArea[ogunit])
  ecc = Select(ECC, OGECC[ogunit])
  process = Select(Process, OGECC[ogunit])
  fuelOG = Select(FuelOG, OGFuel[ogunit])
  nation = Select(Nation, OGNation[ogunit])

  CCC = Vector{String}(undef,length(Year))
  SSS = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))
  # year = Select(Year, (from = "1990", to = "2050"))
  years = collect(Yr(1990):Yr(2050))
  CDYear = max(CDYear,1)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the OG Production Units Check.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")
  println(iob, OGCode[ogunit],";", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  print(iob,"Cumulative Production (",DsLevel,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PDCum;Cumulative Production (",DsLevel,")")  
  for year in years
    ZZZ[year] = PdCum[ogunit,year]/ConvLevel
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  print(iob, "xPDCum;Historical Cumulative Production (",DsLevel,")")  
  for year in years
    ZZZ[year] = xPdCum[ogunit,year]/ConvLevel
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Production (",DsLevel,DsRate,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PD;Production (",DsLevel,DsRate,")")  
  for year in years
    ZZZ[year] = Pd[ogunit,year]/ConvLevel/ConvRate
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  print(iob, "xPD;Historical Production (",DsLevel,DsRate,")")  
  for year in years
    ZZZ[year] = xPd[ogunit,year]/ConvLevel/ConvRate
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  print(iob, "PdMax;Maximum Production Rate (",DsLevel,DsRate,")")  
  for year in years
    ZZZ[year] = PdMax[ogunit,year]/ConvLevel/ConvRate
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Production Rate(",DsLevel,"/",DsLevel,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = PdRate[ogunit,year]
  end
  print(iob, "PDRate;Production Rate (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xPdRate[ogunit,year]
  end
  print(iob, "xPDRate;Historical Production Rate (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Other Production Variables;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = PdSw[ogunit,year]
  end
  print(iob, "PdSw;Production Switch")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdVF[ogunit,year]
  end
  print(iob, "PdVF;Production Rate Variance Factor (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdRateM[ogunit,year]
  end
  print(iob, "PdRateM;Production Rate Multiplier (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdMaxM[ogunit,year]
  end
  print(iob, "PdMaxM;Production Rate Maximum Multiplier (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)  
  for year in years
    ZZZ[year] = PdMinM[ogunit,year]
  end
  print(iob, "PdMinM;Production Rate Minimum Multiplier (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdVar[ogunit,year]
  end
  print(iob, "PdVar;Production Rate Variance Constant (Btu/Btu)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Developed Resources (",DsLevel,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = RsDev[ogunit,year]/ConvLevel
  end
  print(iob, "RsDev;Developed Resources (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xRsDev[ogunit,year]/ConvLevel
  end
  print(iob, "xRsDev;Historical Developed Resources (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Development of Resources (",DsLevel,DsRate,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = Dev[ogunit,year]/ConvLevel/ConvRate
  end
  print(iob, "Dev;Development of Resources (",DsLevel,DsRate,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xDev[ogunit,year]/ConvLevel/ConvRate
  end
  print(iob, "xDev;Historical Development of Resources (",DsLevel,DsRate,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Undeveloped Resources (",DsLevel,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = RsUndev[ogunit,year]/ConvLevel
  end
  print(iob, "RsUndev;Undeveloped Resources (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xRsUndev[ogunit,year]/ConvLevel
  end
  print(iob, "xRsUndev;Historical Undeveloped Resources (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Revisions to Undeveloped Resources (",DsLevel,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = xRvUndev[ogunit,year]/ConvLevel
  end
  print(iob, "xRvUndev;Historical Revisions to Undeveloped Resources (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Development Rate(",DsLevel,"/",DsLevel,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = DevRate[ogunit,year]
  end
  print(iob, "DevRate;Development Rate (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xDevRate[ogunit,year]
  end
  print(iob, "xDevRate;Historical Development Rate (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Other Development Variables;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = DevSw[ogunit,year]
  end
  print(iob, "DevSw;Development Switch")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)  
  for year in years
    ZZZ[year] = DevVF[ogunit,year]
  end  
  print(iob, "DevVF;Development Rate Variance Factor (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevRateM[ogunit,year]
  end
  print(iob, "DevRateM;Development Rate Multiplier (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevMaxM[ogunit,year]
  end
  print(iob, "DevMaxM;Development Rate Maximum Multiplier (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevMinM[ogunit,year]
  end
  print(iob, "DevMinM;Development Rate Minimum Multiplier (",DsLevel,"/",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevVar[ogunit,year]
  end
  print(iob, "DevVar;Development Rate Variance Constant (Btu/Btu)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Levelized Costs
  #
  print(iob,"Levelized Costs (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = (OGRev[ogunit,year]-(OGRev[ogunit,year]-OGOpCosts[ogunit,year]-OpWrkCap[ogunit,year]-
      DevDep[ogunit,year]-SusDep[ogunit,year]-RyLev[ogunit,year])*
      (1-OGITxRate[ogunit,year]))/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "DevLvCst;Development Levelized Cost")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = (OGRev[ogunit,year]-(OGRev[ogunit,year]-OGOpCosts[ogunit,year]-OpWrkCap[ogunit,year]-
      SusDep[ogunit,year]-RyLev[ogunit,year])*
      (1-OGITxRate[ogunit,year]))/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "PdLvCst;Production Levelized Cost")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Revenue
  #
  print(iob,"Revenue (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGRev[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGRev;Revenues")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGFP[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGFP;OG Product Price")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = ByRev[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "ByRev;Byproducts Revenue")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xOGFP[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "xOGFP;Exogenous OG Product Price")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGFPAdd[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGFPAdd;Price Adder for Supply Cost Search")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGFPDChg[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGFPDChg;Product Price Delivery Charge")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGFPMax[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGFPMax;Maximum Price for Supply Cost Search")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGFPMin[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGFPMin;Inital Price for Supply Cost Search")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  #
  # Operating Expenses excluding
  #
  print(iob,"Operating Expenses Before Taxes and Depreciation (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)  
  for year in years
    ZZZ[year] = OpExp[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OpExp;Operating Expenses")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGOpCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGOpCosts;Operating Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)  
  for year in years
    ZZZ[year] = OpWrkCap[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OpWrkCap;Working Capital Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Operating Costs
  #
  print(iob,"Operating Costs (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGOpCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGOpCosts;Total")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGFCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGFCosts;Fuel Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGOMCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGOMCosts;Non-Fuel O&M Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  
  print(iob, "OGPolCosts;Pollution Costs ")
  for year in years
    ZZZ[year] = OGPolCosts[ogunit,year]/
      InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  
  for year in years
    ZZZ[year] = DilCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "DilCosts;Diluent Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = FkCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "FkCosts;Feedstock Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xOGOMCosts[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "xOGOMCosts;Exogenous O&M Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Operating Working Capital (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OpWrkCap[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OpWrkCap;Working Capital Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OWCDays[ogunit,year]
  end
  print(iob, "OWCDays;Operating Working Capital Days Payment (Days)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Abandonment Costs (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGAbCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGAbCosts;Abandonment Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGAbCFr[ogunit,year]
  end  
  print(iob, "OGAbCFr;Abandonment Costs Fraction (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Fuel Costs
  #
  print(iob,"Fuel Costs (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(OGFUse[ogunit,fuel,year].*OGFPrice[ogunit,fuel,year] for fuel in Fuels)./InflationOGUnit[ogunit,year].*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end  
  print(iob, "OGFCosts;Total")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  fuelPrimary = Select(Fuel,["Diesel","Electric","LPG","NaturalGas","NaturalGasRaw","PetroCoke","StillGas"])
  for fuel in fuelPrimary
    for year in years
      ZZZ[year] = OGFUse[ogunit,fuel,year]*OGFPrice[ogunit,fuel,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
    end
    print(iob, "OGFCosts;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
    for year in years
      SSS[year] = SSS[year] + ZZZ[year]
    end
  end
  for year in years
    ZZZ[year] = sum(OGFUse[ogunit,fuelOther,year].*OGFPrice[ogunit,fuelOther,year] for fuelOther in Fuels)./InflationOGUnit[ogunit,year].*InflationOGUnit[ogunit,CDYear]*ConvLevel-SSS[year]
  end  
  print(iob, "OGFCosts;Other")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Expenses
  #
  print(iob,"Expenses (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = DevExp[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end  
  print(iob, "DevExp;Development Expenses")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdExp[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end  
  print(iob, "PdExp;Production Expenses")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Depreciation
  #
  print(iob,"Depreciation (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGDep[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGDep;Depreciation")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevDep[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "DevDep;Development Depreciation")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = SusDep[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "SusDep;Sustaining Depreciation")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevDpRate[ogunit,year]
  end  
  print(iob, "DevDpRate;Development Depreciation Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = SusDpRate[ogunit,year]
  end  
  print(iob, "SusDpRate;Sustaining Depreciation Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Royalties and Income Taxes
  #
  print(iob,"Royalties and Taxes (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = RyLev[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "RyLev;Levelized Royalty Payments")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevITax[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "DevITax;Development Tax")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdITax[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "PdITax;Production Income Tax")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,"Detailed Royalty Information;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = RyLev[ogunit,year]/OGRev[ogunit,year]
  end
  print(iob, "RyEffRate;Effective Royalty Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = RyFP[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "RyFP;Price used to Compute Royalty Rates (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = GRRMax[ogunit,year]
  end  
  print(iob, "GRRMax;Maximum Gross Revenue Royalty Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = GRRMin[ogunit,year]
  end
  print(iob, "GRRMin;Minimum Gross Revenue Royalty Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = GRRPr[ogunit,year]
  end
  print(iob, "GRRPr;Gross Revenue Royalty Rate Slope to Price (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = GRRPr0[ogunit,year]
  end
  print(iob, "GRRPr0;Gross Revenue Royalty Rate Intercept (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = GRRRate[ogunit,year]
  end  
  print(iob, "GRRRate;Gross Revenue Royalty Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = NRRMax[ogunit,year]
  end  
  print(iob, "NRRMax;Maximum Net Revenue Royalty Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = NRRMin[ogunit,year]
  end
  print(iob, "NRRMin;Minimum Net Revenue Royalty Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = NRRPr[ogunit,year]
  end
  print(iob, "NRRPr;Net Revenue Royalty Rate Slope to Price (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = NRRPr0[ogunit,year]
  end
  print(iob, "NRRPr0;Net Revenue Royalty Rate Intercept (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = NRRRate[ogunit,year]
  end
  print(iob, "NRRRate;Net Revenue Royalty Rate (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end 
  println(iob)
  for year in years
    ZZZ[year] = NetRev[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end  
  print(iob, "NetRev;Net Revenues for Royalty Calculation (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = RyLevFactor[ogunit,year]
  end
  print(iob, "RyLevFactor;Royalty Levelization Factor (\$/\$)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Income Tax Rate
  #
  print(iob,"Income Tax Rate (\$/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGITxRate[ogunit,year]
  end
  print(iob, "OGITxRate;Statutory Income Tax Rate")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = (OGRev[ogunit,year]-OGOpCosts[ogunit,year]-OpWrkCap[ogunit,year]-SusDep[ogunit,year]-
      RyLev[ogunit,year])*OGITxRate[ogunit,year]/OGRev[ogunit,year]
  end
  print(iob, "TxEffRate;Effective Income Tax Rate")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Net Income
  #
  print(iob,"Net Income (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = DevNtInc[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "DevNtInc;Development Net Income")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdNtInc[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "PdNtInc;Production Net Income")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Capital Costs
  #
  print(iob,"Capital Costs (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGCapCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGCapCosts;Total")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevCap[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "DevCap;Development Capital Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = SusCap[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "SusCap;Sustaining Capital Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xDevCap[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "xDevCap;Exogenous Development Capital Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xSusCap[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end  
  print(iob, "xSusCap;Exogenous Sustaining Capital Costs")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # ROI
  #
  print(iob,"Return on Investment (\$/Yr/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = DevROI[ogunit,year]
  end
  print(iob, "DevROI;Development ROI")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdROI[ogunit,year]
  end
  print(iob, "PdROI;Production ROI")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = ROITarget[ogunit,year]
  end
  print(iob, "ROITarget;Development ROI Target for Supply Cost")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OGROIN[ogunit,year]
  end
  print(iob, "OGROIN;Return on Investment Normal")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Supply Cost
  #
  print(iob,"Supply Cost Information (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = SCFP[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "SCFP;Supply Cost Product Price")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = SCRyLev[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "SCRyLev;Supply Cost Levelized Royalty Payments")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = SCITax[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "SCITax;Supply Cost Income Tax")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = SCNtInc[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "SCNtInc;Supply Cost Net Income")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = SCRyFP[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "SCRyFP;Price used to Compute Supply Cost Royalty Rates")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  # Prices
  #
  print(iob,"Other Prices (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = ByPrice[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "ByPrice;Byproducts Price")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DilPrice[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "DilPrice;Diluent Price")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  
  print(iob, "OGPolPrice;Pollution Price")
  for year in years
    ZZZ[year] = 
      sum(OGFUse[ogunit,fuel,year]*OGPolPrice[ogunit,fuel,year] for fuel in Fuels)/
      sum(OGFUse[ogunit,fuel,year] for fuel in Fuels)/
      InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  
  println(iob)
  for year in years
    ZZZ[year] = FkPrice[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end  
  print(iob, "FkPrice;Feedstock Price")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,"Price of Fuel Consumed (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  fuelPrimary = Select(Fuel,["Diesel","Electric","LPG","NaturalGas","NaturalGasRaw","PetroCoke","StillGas"])
  for fuel in fuelPrimary
    for year in years
      ZZZ[year] = OGFPrice[ogunit,fuel,year]/InflationOGUnit[ogunit,year]*
        InflationOGUnit[ogunit,CDYear]
    end
    print(iob, "OGFPrice;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob,"Wholesale Price (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  if OGOGSw[ogunit] == "Oil"
    fuelSw = Select(Fuel,"LightCrudeOil")
  else
    fuelSw = Select(Fuel,"NaturalGas")
  end
  for year in years
    ZZZ[year] = ENPN[fuelSw,nation,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "ENPN;",FuelDS[fuelSw]," Wholesale Price")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,"Oil Gas Price (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuelOGAll in FuelOGs
    for year in years
      ZZZ[year] = OGENPN[fuelOGAll,nation,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
    end
    print(iob, "OGENPN;",FuelOGDS[fuelOGAll])
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob,"Oil Gas Price (",CDTime," US\$/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuelOGAll in FuelOGs
    for year in years
      ZZZ[year] = OGENPN[fuelOGAll,nation,year]/ExchangeRateNation[nation,year]/InflationOGUnit[ogunit,year]*
        InflationOGUnit[ogunit,CDYear]*ConvLevel
    end
    print(iob, "OGENPN;",FuelOGDS[fuelOGAll])
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Fuel Demand
  #
  print(iob,"Marginal Energy Demand (TBtu/Driver);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(OGFUse[ogunit,fuel,year] for fuel in Fuels)
  end
  print(iob, "OGFUse;Total")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    SSS[year] = 0
  end
  fuelPrimary = Select(Fuel,["Diesel","Electric","LPG","NaturalGas","NaturalGasRaw","PetroCoke","StillGas"])
  for fuel in fuelPrimary
    for year in years
      ZZZ[year] = OGFUse[ogunit,fuel,year]
    end
    print(iob, "OGFUse;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
    for year in years
      SSS[year] = SSS[year] + ZZZ[year]
    end
  end
  for year in years
    ZZZ[year] = sum(OGFUse[ogunit,fuel,year] for fuel in Fuels)-SSS[year]
  end
  print(iob, "OGFUse;Other")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Learning and Depletion Multipliers
  #
  print(iob,"Learning and Depletion Multipliers (\$/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = DevDM[ogunit,year]
  end
  print(iob, "DevDM;Development Depletion Multiplier")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevLCM[ogunit,year]
  end
  print(iob, "DevLCM;Development Learning Curve Multiplier")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevIM[ogunit,year]
  end
  print(iob, "DevIM;Development Infrastructure Multiplier")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevDMB0[ogunit,year]
  end
  print(iob, "DevDMB0;Development Costs Depletion Multiplier Coefficient")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DevLCMB0[ogunit,year]
  end
  print(iob, "DevLCMB0;Development Costs Learning Curve Multiplier Coefficient")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = RsD0OG[ogunit,year]
  end
  print(iob, "RsD0OG;Learning Curve Initial Developed Resources (MMB)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OpDM[ogunit,year]
  end
  print(iob, "OpDM;Operating Depletion Multiplier")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OpLCM[ogunit,year]
  end
  print(iob, "OpLCM;Operating Learning Curve Multiplier")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OpDMB0[ogunit,year]
  end
  print(iob, "OpDMB0;Operating Costs Depletion Multiplier Coefficient")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = OpLCMB0[ogunit,year]
  end
  print(iob, "OpLCMB0;Operating Costs Learning Curve Multiplier Coefficient")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdC0OG[ogunit,year]
  end
  print(iob, "PdC0OG;Learning Curve Initial Cumulative Production (MMB)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = CCMDem[ogunit,year]
  end
  print(iob, "CCMDem;Capital Cost Multiplier from Demand Module")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = CCMDemSw[ogunit,year]
  end
  print(iob, "CCMDemSw;Switch to Activate the Capital Cost Multiplier (1 = on)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end  
  println(iob)
  println(iob)

  print(iob,"Pollution Costs (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGPolCosts[ogunit,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "OGPolCosts;Total")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(OGFUse[ogunit,fuel,year].*OGPolPrice[ogunit,fuel,year] for fuel in Fuels)./InflationOGUnit[ogunit,year].*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end  
  print(iob, "OGFUse*OGPolPrice;Fuel Usage")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = VnCosts[ecc,area,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "VnCosts;Venting")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = FlCosts[ecc,area,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "FlCosts;Flaring")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = FuCosts[ecc,area,year]/InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]*ConvLevel
  end
  print(iob, "FuCosts;Other Fugitives")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Other Economics Variables
  #
  print(iob,"Other Economics Variables;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = ByFrac[ogunit,year]
  end  
  print(iob, "ByFrac;Byproducts Fraction (bbl/bbl)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = DilFrac[ogunit,year]
  end  
  print(iob, "DilFrac;Diluent Fraction (bbl/bbl)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = FkFrac[ogunit,year]
  end
  print(iob, "FkFrac;Feedstock Fraction (bbl/bbl)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Other Variables
  #
  print(iob,"Other Variables;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = NewWells[ogunit,year]
  end  
  print(iob, "NewWells;Number of New Wells")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = MeanEUR[ogunit,year]
  end  
  print(iob, "MeanEUR;Mean Expected Ultimate Recovery (TBtu/Well)")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,"Unit Characteristics;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"OGArea;Area")
  for year in years
    CCC[year] = OGArea[ogunit]
    print(iob,";",CCC[year])
  end
  println(iob)
  print(iob, "OGECC;Economic Sector")
  for year in years
    CCC[year] = OGECC[ogunit]
    print(iob, ";",CCC[year])
  end
  println(iob)
  print(iob, "OGFuel;Fuel Type")
  for year in years
    CCC[year] = OGFuel[ogunit]
    print(iob, ";",CCC[year])
  end
  println(iob)
  print(iob, "OGNation;Nation")
  for year in years
    CCC[year] = OGNation[ogunit]
    print(iob, ";",CCC[year])
  end
  println(iob)
  print(iob, "OGNode;Natural Gas Transmission Node")
  for year in years
    CCC[year] = OGNode[ogunit]
    print(iob,";",CCC[year])
  end
  println(iob)
  print(iob, "OGProcess;Production Process")
  for year in years
    CCC[year] = OGProcess[ogunit]
    print(iob, ";",CCC[year])
  end
  println(iob)
  print(iob, "OGOGSw;Oil or Gas Switch")
  for year in years
    CCC[year] = OGOGSw[ogunit]
    print(iob, ";",CCC[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = OGPrSw[ogunit,year]
  end
  print(iob, "OGPrSw;OG Price Switch")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end  
  println(iob)
  println(iob)

  #
  print(iob,"Cumulative Production (",DsLevel,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = PdCum[ogunit,year]/ConvLevel
  end
  print(iob, "PdCum;Cumulative Production (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = Pd3Cum[ogunit,year]/ConvLevel
  end
  print(iob, "Pd3Cum;Cumulative Production after Pipeline Constraints (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xPdCum[ogunit,year]/ConvLevel
  end
  print(iob, "xPdCum;Historical Cumulative Production (",DsLevel,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,"Production (",DsLevel,DsRate,");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = Pd[ogunit,year]/ConvLevel/ConvRate
  end
  print(iob, "Pd;Production (",DsLevel,DsRate,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = Pd3[ogunit,year]/ConvLevel/ConvRate
  end
  print(iob, "Pd3;Production after Pipeline Constraints (",DsLevel,DsRate,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = xPd[ogunit,year]/ConvLevel/ConvRate
  end
  print(iob, "xPd;Historical Production (",DsLevel,DsRate,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = PdMax[ogunit,year]/ConvLevel/ConvRate
  end
  print(iob, "PdMax;Maximum Production Rate (",DsLevel,DsRate,")")
  for year in years
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  if OGOGSw[ogunit] == "Oil"
    print(iob,"Oil Production ",Area[area]," ",ProcessDS[process],";")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = OAProd[process,area,year]/ConvLevel/ConvRate
    end
    print(iob, "OAProd;Endogenous (",DsLevel,DsRate,")")
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
    for year in years
      ZZZ[year] = OAPrEOR[process,area,year]/ConvLevel/ConvRate
    end
    print(iob, "OAPrEOR;EOR (",DsLevel,DsRate,")")
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
    for year in years
      ZZZ[year] = xOAProd[process,area,year]/ConvLevel/ConvRate
    end
    print(iob, "xOAProd;Exogenous (",DsLevel,DsRate,")")
    for year in years
      print(iob,";",@sprintf("%18.7f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  # PExp[ecc,poll,area] = PExp[ecc,poll,area]+
  # (PBuy[ecc,poll,area]-PSell[ecc,poll,area])*eCO2Price
  # PExp[ecc,poll,area] = PExpGross[ecc,poll,area]-OffRevenue[ecc,poll,area]
  #
  print(iob,"Emission Permits ",Area[area],";")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)  
  
  print(iob,"eCO2Price;eCO2 Price (",CDTime," ",MoneyUnitDS[area],"/tonne)")
  for year in years
    ZZZ[year] = eCO2Price[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  
  
  print(iob, "OGPolCosts;Pollution Costs (",CDTime," ",MoneyUnitDS[area],"/",DsFinancial,")")
  for year in years
    ZZZ[year] = OGPolCosts[ogunit,year]*ConvLevel/
      InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)  
  
  print(iob, "OGPolCosts;Pollution Costs (Millions ",CDTime," ",MoneyUnitDS[area],"/Yr)")
  for year in years
    ZZZ[year] = OGPolCosts[ogunit,year]*Pd[ogunit,year]/
      InflationOGUnit[ogunit,year]*InflationOGUnit[ogunit,CDYear]
    print(iob,";",@sprintf("%18.7f", ZZZ[year]))
  end
  println(iob)

  print(iob,"PExp;Emission Permit Expenses (Millions ",CDTime," ",MoneyUnitDS[area],"/Yr)")
  for year in years
    ZZZ[year] = sum((PExp[ecc,poll,area,year]+PExpExo[ecc,poll,area,year])/
      Inflation[area,year]*Inflation[area,CDYear] for poll in Polls)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"PBuy;Emission Permits Purchased (Millions ",CDTime," ",MoneyUnitDS[area],"/Yr)")
  for year in years
    ZZZ[year] = sum(PBuy[ecc,poll,area,year]/1e6 for poll in Polls)*
      eCO2Price[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)  
  
  print(iob,"PSell;Emission Permits Sold (Millions ",CDTime," ",MoneyUnitDS[area],"/Yr)")
  for year in years
    ZZZ[year] = sum(PSell[ecc,poll,area,year]/1e6 for poll in Polls)*
      eCO2Price[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob) 
  
  print(iob,"OffRevenue;Emission Offset Revenue (Millions ",CDTime," ",MoneyUnitDS[area],"/Yr)")
  for year in years
    ZZZ[year] = sum(OffRevenue[ecc,poll,area,year]/
      Inflation[area,year]*Inflation[area,CDYear] for poll in Polls)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)   

  print(iob,"PBuy;Emission Permits Purchased (MT/Yr)")
  for year in years
    ZZZ[year] = sum(PBuy[ecc,poll,area,year]/1e6 for poll in Polls)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"PSell;Emission Permits Sold (MT/Yr)")
  for year in years
    ZZZ[year] = sum(PSell[ecc,poll,area,year]/1e6 for poll in Polls)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)  

  print(iob,"Offsets;Emission Offsets (MT/Yr)")
  for year in years
    ZZZ[year] = sum(Offsets[ecc,poll,area,year]/1e6 for poll in Polls)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)   

  #
  # Create *.dta filename and write output values
  #
  OGCodeOut = OGCode[ogunit]
  filename = "OGUnitDetails-$OGCodeOut-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function OGUnitDetails_DtaControl(db)
  @info "OGUnitDetails_DtaControl"
  data = OGUnitDetailsData(; db)
  (; OGCounter) = data

  OGUnits = collect(1:Int(maximum(OGCounter)))
  for ogunit in OGUnits
    OGUnitDetails_DtaRun(data,ogunit)
  end
end


if abspath(PROGRAM_FILE) == @__FILE__
OGUnitDetails_DtaControl(DB)
end



