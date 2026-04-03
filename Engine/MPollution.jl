#
# MPollution.jl
#

module MPollution

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime,Last,DT
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
  ECCs::Vector{Int} = collect(Select(ECC))  
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Level::SetArray = ReadDisk(db,"MainDB/LevelKey")
  Levels::Vector{Int} = collect(Select(Level))
  LU::SetArray = ReadDisk(db,"MainDB/LUDS")
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  PollX::SetArray = ReadDisk(db,"MainDB/PollKey")
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  
  Yr2000 = 2000-ITime+1  
  Yr2012 = 2012-ITime+1
  Yr2013 = 2013-ITime+1
  Yr2016 = 2016-ITime+1
  Yr2020 = 2020-ITime+1

  AGFr::VariableArray{3} = ReadDisk(db,"SInput/AGFr",year) #[ECC,Poll,Area,Year]  Government Subsidy ($/$)
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year) #[Area,Market,Year]  Areas included in Market
  BCarbonSw::Float32 = ReadDisk(db,"SInput/BCarbonSw",year) #[Year]  Black Carbon coefficient switch (1=POCX set relative to PM25)
  BCMult::VariableArray{3} = ReadDisk(db,"SInput/BCMult",year) #[Fuel,ECC,Area,Year]  Fuel Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  BCMultProcess::VariableArray{2} = ReadDisk(db,"SInput/BCMultProcess",year) #[ECC,Area,Year]  Process Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  CapTrade::VariableArray{1} = ReadDisk(db,"SInput/CapTrade",year) #[Market,Year]  Emission Cap and Trading Switch (1=Trade, Cap Only=2)
  Driver::VariableArray{2} = ReadDisk(db,"MOutput/Driver",year) #[ECC,Area,Year]  Economic Driver (Various Units)
  ECCMarket::VariableArray{2} = ReadDisk(db,"SInput/ECCMarket",year) #[ECC,Market,Year]  Economic Categories included in Market
  eCO2Price::VariableArray{1} = ReadDisk(db,"SOutput/eCO2Price",year) #[Area,Year]  Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  eCO2PriceExo::VariableArray{1} = ReadDisk(db,"SInput/eCO2PriceExo",year) #[Area,Year]  Carbon Tax plus Permit Cost (Real $/eCO2 Tonnes)
  ECoverage::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) #[ECC,Poll,PCov,Area,Year]  Emissions Permit Coverage (Tonnes/Tonnes)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Related Pollution (Tonnes/Yr)
  EnPOCX::VariableArray{4} = ReadDisk(db,"MEInput/EnPOCX",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Pollution Coefficient (Tonnes/$B-output)
  EORCredits::VariableArray{3} = ReadDisk(db,"SOutput/EORCredits",year) #[ECC,Poll,Area,Year]  Emissions Credits for using CO2 for EOR (Tonnes/Yr)
  EORCreditMultiplier::VariableArray{2} = ReadDisk(db,"MEInput/EORCreditMultiplier",year) #[ECC,Area,Year]  EOR Credit Multiplier (Tonnes/Tonnes)
  EORFraction::VariableArray{2} = ReadDisk(db,"MEInput/EORFraction",year) #[ECC,Area,Year]  Fraction of Sequestered CO2 used for EOR (Tonnes/Tonnes)
  EORLimit::VariableArray{1} = ReadDisk(db,"MEInput/EORLimit",year) #[Area,Year]  Maximum Amonut of Sequestered CO2 which can be used for EOR (Tonnes)
  EORRate::VariableArray{1} = ReadDisk(db,"MEInput/EORRate",year) #[Area,Year]  EOR Production per unit of Sequestered CO2 (TBtu/Tonne)
  EUPolSq::VariableArray{2} = ReadDisk(db,"SOutput/EUPolSq",year) #[Poll,Area,Year]  Electric Utility Pollution Sequestered (Tonnes/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel]
  FlC2H6PerCH4::VariableArray{2} = ReadDisk(db,"MEInput/FlC2H6PerCH4",year) #[ECC,Area,Year]  Flaring C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  FlCC::VariableArray{2} = ReadDisk(db,"MEInput/FlCC",year) #[ECC,Area,Year]  Flaring Reduction Capital Cost ($/Tonne CH4)
  FlCH4Captured::VariableArray{2} = ReadDisk(db,"MEOutput/FlCH4Captured",year) #[ECC,Area,Year]  CH4 Captured from Flaring Reductions (Tonnes/Yr)
  FlCH4CapturedFraction::VariableArray{2} = ReadDisk(db,"MEInput/FlCH4CapturedFraction",year) #[ECC,Area,Year]  CH4 Captured from CO2 Flaring Reductions (Tonnes CH4/Tonne CO2)
  FlCosts::VariableArray{2} = ReadDisk(db,"SOutput/FlCosts",year) #[ECC,Area,Year]  Flaring Reduction Costs ($/mmBtu)
  FlGAProd::VariableArray{2} = ReadDisk(db,"SOutput/FlGAProd",year) #[ECC,Area,Year]  Natural Gas Produced from Flaring Reductions (TBtu/Yr)
  FlGProd::VariableArray{1} = ReadDisk(db,"SOutput/FlGProd",year) #[Nation,Year]  Natural Gas Produced from Flaring Reductions (TBtu/Yr)
  FlInv::VariableArray{2} = ReadDisk(db,"SOutput/FlInv",year) #[ECC,Area,Year]  Flaring Reduction Investments (M$/Yr)
  FlPExp::VariableArray{2} = ReadDisk(db,"SOutput/FlPExp",year) #[ECC,Area,Year]  Flaring Reduction Private Expenses (M$/Yr)
  FlPOCX::VariableArray{3} = ReadDisk(db,"MEInput/FlPOCX",year) #[ECC,Poll,Area,Year]  Flaring Emissions Coefficient (Tonnes/Driver)
  FlPOCXMult::VariableArray{3} = ReadDisk(db,"MEInput/FlPOCXMult",year) #[ECC,Poll,Area,Year]  Flaring Pollution Coefficient Multiplier (Tonnes/Driver)
  FlPol::VariableArray{3} = ReadDisk(db,"SOutput/FlPol",year) #[ECC,Poll,Area,Year]  Flaring Emissions (Tonnes/Yr)
  FlPolSwitch::VariableArray{3} = ReadDisk(db,"SInput/FlPolSwitch",year) #[ECC,Poll,Area,Year]  Flaring Pollution Switch (0 = Exogenous)
  FlReduce::VariableArray{3} = ReadDisk(db,"SOutput/FlReduce",year) #[ECC,Poll,Area,Year]  Flaring Reductions (Tonnes/Yr)
  FlRP::VariableArray{3} = ReadDisk(db,"MEInput/FlRP",year) #[ECC,Poll,Area,Year]  Fraction of Flaring Reduced (Tonnes/Tonnes)
  FPCFSObligated::VariableArray{2} = ReadDisk(db,"SOutput/FPCFSObligated",year) #[ECC,Area,Year]  CFS Price for Obligated Sectors ($/Tonnes)
  FuA0::VariableArray{2} = ReadDisk(db,"MEInput/FuA0") #[ECC,Area]  A Term in Other Fugitives Reduction Curve (??)
  FuB0::VariableArray{2} = ReadDisk(db,"MEInput/FuB0") #[ECC,Area]  B Term in Other Fugitives Reduction Curve (??)
  FuC0::VariableArray{2} = ReadDisk(db,"MEInput/FuC0",year) #[ECC,Area,Year]  C Term in Other Fugitives Reduction Curve (??)
  FuC2H6PerCH4::VariableArray{2} = ReadDisk(db,"MEInput/FuC2H6PerCH4",year) #[ECC,Area,Year]  Other Fugitives C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  FuCap::VariableArray{2} = ReadDisk(db,"MEOutput/FuCap",year) #[ECC,Area,Year]  Other Fugitives Reduction Capacity (Tonnes/Yr)
  FuCapPrior::VariableArray{2} = ReadDisk(db,"MEOutput/FuCap",prior) #[ECC,Area,Prior]  Other Fugitives Reduction Capacity in Previous Year (Tonnes/Yr)
  FuCC::VariableArray{2} = ReadDisk(db,"MEOutput/FuCC",year) #[ECC,Area,Year]  Other Fugitives Reduction Capital Cost ($/Tonne)
  FuCCReplace::VariableArray{2} = ReadDisk(db,"MEInput/FuCCReplace",year) #[ECC,Area,Year]  Other Fugitives Reduction Replacement Capital Cost ($/Tonne CH4)
  FuCCA0::VariableArray{2} = ReadDisk(db,"MEInput/FuCCA0") #[ECC,Area]  A Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCB0::VariableArray{2} = ReadDisk(db,"MEInput/FuCCB0") #[ECC,Area]  B Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCC0::VariableArray{2} = ReadDisk(db,"MEInput/FuCCC0",year) #[ECC,Area,Year]  C Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCEm::VariableArray{2} = ReadDisk(db,"MEOutput/FuCCEm",year) #[ECC,Area,Year]  Other Fugitives Reduction Embedded Capital Cost ($/Tonne)
  FuCCEmPrior::VariableArray{2} = ReadDisk(db,"MEOutput/FuCCEm",prior) #[ECC,Area,Prior]  Other Fugitives Reduction Embedded Capital Cost in Previous Year  ($/Tonne)
  FuCH4Captured::VariableArray{2} = ReadDisk(db,"MEOutput/FuCH4Captured",year) #[ECC,Area,Year]  CH4 Captured from Other Fugitives Reductions (Tonnes/Yr)
  FuCH4CapturedFraction::VariableArray{2} = ReadDisk(db,"MEInput/FuCH4CapturedFraction",year) #[ECC,Area,Year]  Fraction of CH4 Captured from Other Fugitives Reductions (Tonnes/Tonnes)
  FuCH4Flared::VariableArray{2} = ReadDisk(db,"MEOutput/FuCH4Flared",year) #[ECC,Area,Year]  CH4 Flared from Other Fugitives Reductions (Tonnes/Yr)
  FuCH4FlaredPOCF::VariableArray{3} = ReadDisk(db,"MEInput/FuCH4FlaredPOCF",year) #[ECC,Poll,Area,Year]  Pollution Coefficient for Flared CH4 (Tonnes/Tonnes)
  FuCH4FlPol::VariableArray{3} = ReadDisk(db,"MEOutput/FuCH4FlPol",year) #[ECC,Poll,Area,Year]  Emissions from Flaring CH4 (Tonnes/Yr)
  FuCosts::VariableArray{2} = ReadDisk(db,"SOutput/FuCosts",year) #[ECC,Area,Year]  Other Fugitives Reduction Costs ($/mmBtu)
  FuCR::VariableArray{2} = ReadDisk(db,"MEOutput/FuCR",year) #[ECC,Area,Year]  Other Fugitives Reduction Capacity Completion Rate (Tonnes/Yr/Yr)
  FuGAProd::VariableArray{2} = ReadDisk(db,"SOutput/FuGAProd",year) #[ECC,Area,Year]  Natural Gas Produced from Other Fugitives Reductions (TBtu/Yr)
  FuGExp::VariableArray{2} = ReadDisk(db,"MEOutput/FuGExp",year) #[ECC,Area,Year]  Other Fugitives Reduction Government Expenses (M$/Yr)
  FuGFr::VariableArray{2} = ReadDisk(db,"MEInput/FuGFr",year) #[ECC,Area,Year]  Other Fugitives Reduction Grant Fraction ($/$)
  FuGProd::VariableArray{1} = ReadDisk(db,"SOutput/FuGProd",year) #[Nation,Year]  Natural Gas Produced from Other Fugitives Reductions (TBtu/Yr)
  FuInv::VariableArray{2} = ReadDisk(db,"SOutput/FuInv",year) #[ECC,Area,Year]  Other Fugitives Reduction Investments (M$/Yr)
  FuOCF::VariableArray{2} = ReadDisk(db,"MEInput/FuOCF",year) #[ECC,Area,Year]  Other Fugitives Reduction Operating Cost Factor ($/$)
  FuOMExp::VariableArray{2} = ReadDisk(db,"SOutput/FuOMExp",year) #[ECC,Area,Year]  Other Fugitives Reduction O&M Expenses (M$/Yr)
  FuPExp::VariableArray{2} = ReadDisk(db,"SOutput/FuPExp",year) #[ECC,Area,Year]  Other Fugitives Reduction Private Expenses (M$/Yr)
  FuPL::VariableArray{2} = ReadDisk(db,"MEInput/FuPL",year) #[ECC,Area,Year]  Other Fugitives Reduction Physical Lifetime (Years)
  FuPOCF::VariableArray{3} = ReadDisk(db,"MEInput/FuPOCF",year) #[ECC,Poll,Area,Year]  Other Fugitives Emission Factor (Tonnes/Tonne CH4)
  FuPOCX::VariableArray{3} = ReadDisk(db,"MEInput/FuPOCX",year) #[ECC,Poll,Area,Year]  Other Fugitives Emissions Coefficient (Tonnes/Driver)
  FuPOCXMult::VariableArray{3} = ReadDisk(db,"MEInput/FuPOCXMult",year) #[ECC,Poll,Area,Year]  Other Fugitives Pollution Coefficient Multiplier (Tonnes/Driver)
  FuPol::VariableArray{3} = ReadDisk(db,"SOutput/FuPol",year) #[ECC,Poll,Area,Year]  Other Fugitives Emissions (Tonnes/Yr)
  FuPolSwitch::VariableArray{3} = ReadDisk(db,"SInput/FuPolSwitch",year) #[ECC,Poll,Area,Year]  Other Fugitives Pollution Switch (0 = Exogenous)
  FuPrice::VariableArray{2} = ReadDisk(db,"MEOutput/FuPrice",year) #[ECC,Area,Year]  Price for Other Fugitives Reduction Curve ($/Tonne)
  FuPriceSw::Float32 = ReadDisk(db,"MEInput/FuPriceSw",year) #[Year]  Other Fugitives Reduction Curve Price Switch (1=Endogenous, 0 = Exogenous)
  FuReduce::VariableArray{3} = ReadDisk(db,"SOutput/FuReduce",year) #[ECC,Poll,Area,Year]  Other Fugitives Reductions (Tonnes/Yr)
  FuReducePrior::VariableArray{3} = ReadDisk(db,"SOutput/FuReduce",prior) #[ECC,Poll,Area,Prior]  Other Fugitives Reductions in Previous Year (Tonnes/Yr)
  FuRP::VariableArray{3} = ReadDisk(db,"MEOutput/FuRP",year) #[ECC,Poll,Area,Year]  Fraction of Other Fugitives Reduced (Tonnes/Tonnes)
  GRExp::VariableArray{3} = ReadDisk(db,"SOutput/GRExp",year) #[ECC,Poll,Area,Year]  Reduction Government Expenses (M$/Yr)
  GrossPol::VariableArray{3} = ReadDisk(db,"SOutput/GrossPol",year) #[ECC,Poll,Area,Year]  Gross Pollution - before any policies (Tonnes/Yr)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationYr::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") #[Area,Year]  Inflation Index ($/$)
  Inf00::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr2000) #[Area,Year]  Inflation Index for 2000 ($/$)
  InSm::VariableArray{1} = ReadDisk(db,"MOutput/InSm",year) #[Area,Year]  Smoothed Inflation Rate (1/Yr)
  LandArea::VariableArray{1} = ReadDisk(db,"MEInput/LandArea") #[Area]  Land Area (Acres)
  LUFr::VariableArray{2} = ReadDisk(db,"MEOutput/LUFr",year) #[LU,Area,Year]  Land Use Area Fraction (Acre/Acre)
  LUArea::VariableArray{2} = ReadDisk(db,"MEOutput/LUArea",year) #[LU,Area,Year]  Land Use Area (Acres)
  LUPolLU::VariableArray{3} = ReadDisk(db,"MEOutput/LUPolLU",year) #[LU,Poll,Area,Year]  Land Use Pollution (Tonnes)
  LUPOCX::VariableArray{3} = ReadDisk(db,"MEInput/LUPOCX",year) #[LU,Poll,Area,Year]  Land Use Area Pollution Coefficient (Tonnes/Acre)
  MEA0::VariableArray{3} = ReadDisk(db,"MEInput/MEA0",year) #[ECC,Poll,Area,Year]  A Term in eCO2 Reduction Curve (CDN 1999$)
  MEB0::VariableArray{3} = ReadDisk(db,"MEInput/MEB0",year) #[ECC,Poll,Area,Year]  B Term in eCO2 Reduction Curve (CDN 1999$)
  MEC0::VariableArray{3} = ReadDisk(db,"MEInput/MEC0",year) #[ECC,Poll,Area,Year]  C Term in eCO2 Reduction Curve (CDN 1999$)
  MECC::VariableArray{2} = ReadDisk(db,"MEOutput/MECC",year) #[ECC,Area,Year]  Non Energy eCO2 Reduction Capital Cost ($/Tonne)
  MECCR::VariableArray{2} = ReadDisk(db,"MEOutput/MECCR",year) #[ECC,Area,Year]  Non Energy eCO2 Reduction Capital Charge Rate ($/$)
  MECM::VariableArray{2} = ReadDisk(db,"MEInput/MECM") #[Poll,PollX]  Cross-over Reduction Multiplier (Tonnes/Tonnes)
  MEDriver::VariableArray{2} = ReadDisk(db,"MOutput/MEDriver",year) #[ECC,Area,Year]  Driver for Process Emissions (Various Millions/Yr)
  MEIRP::VariableArray{3} = ReadDisk(db,"MEOutput/MEIRP",year) #[ECC,Poll,Area,Year]  Indicated Pollutant Reduction (Tonnes/Tonnes)
  MEIVTC::VariableArray{2} = ReadDisk(db,"MEInput/MEIVTC",year) #[ECC,Area,Year]  Non Energy eCO2 Reduction Investment Tax Credit ($/$)
  MEPCstN::VariableArray{3} = ReadDisk(db,"MEInput/MEPCstN") #[ECC,Poll,Area]  Pollution Reduction Cost Normal ($/Tonne)
  MEPL::VariableArray{2} = ReadDisk(db,"MEInput/MEPL",year) #[ECC,Area,Year]  Non Energy eCO2 Reduction Physical Lifetime (Years)
  MEPOCA::VariableArray{3} = ReadDisk(db,"MEOutput/MEPOCA",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution Coefficient (Tonnes/$B-output)
  MEPOCX::VariableArray{3} = ReadDisk(db,"MEInput/MEPOCX",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution Coefficient (Tonnes/$B-output)
  MEPOCM::VariableArray{3} = ReadDisk(db,"MEOutput/MEPOCM",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution Coefficient Multiplier (Tonnes/Tonnes)
  MEPOCS::VariableArray{3} = ReadDisk(db,"MEInput/MEPOCS",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution Standard (Tonnes/$B-output)
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year) #[ECC,Poll,Area,Year]  Process Pollution (Tonnes/Yr)
  MEPolSwitch::VariableArray{3} = ReadDisk(db,"SInput/MEPolSwitch",year) #[ECC,Poll,Area,Year]  Process Pollution Switch (0 = Exogenous)
  MEPrice::VariableArray{3} = ReadDisk(db,"MEOutput/MEPrice",year) #[ECC,Poll,Area,Year]  Process Emission Reduction Price ($/eCO2 Tonne)
  MEPriceSw::Float32 = ReadDisk(db,"MEInput/MEPriceSw",year) #[Year]  Process Emission Reduction Curve Price Switch (1=Endogenous, 0 = Exogenous)
  MEPVF::VariableArray{3} = ReadDisk(db,"MEInput/MEPVF") #[ECC,Poll,Area]  Pollution Reduction Variance Factor (($/Tonne)/($/Tonne))
  MERCA0::VariableArray{3} = ReadDisk(db,"MEInput/MERCA0",year) #[ECC,Poll,Area,Year]  A Term in Emission Reduction Curve (US$2000)
  MERCap::VariableArray{3} = ReadDisk(db,"MEOutput/MERCap",year) #[ECC,Poll,Area,Year]  Reduction Capital (Tonnes/Yr)
  MERCapPrior::VariableArray{3} = ReadDisk(db,"MEOutput/MERCap",prior) #[ECC,Poll,Area,Year]  Reduction Capital (Tonnes/Yr)
  MERCB0::VariableArray{3} = ReadDisk(db,"MEInput/MERCB0",year) #[ECC,Poll,Area,Year]  B Term in Emission Reduction Curve (US$2000)
  MERCC::VariableArray{3} = ReadDisk(db,"MEOutput/MERCC",year) #[ECC,Poll,Area,Year]  Reduction Capital Cost ($/Tonne)
  MERCC0::VariableArray{3} = ReadDisk(db,"MEInput/MERCC0",year) #[ECC,Poll,Area,Year]  C Term in Emission Reduction Curve (US$2000)
  MERCCEm::VariableArray{3} = ReadDisk(db,"MEOutput/MERCCEm",year) #[ECC,Poll,Area,Year]  Embedied Reduction Capital Cost ($)
  MERCCEmPrior::VariableArray{3} = ReadDisk(db,"MEOutput/MERCCEm",prior) #[ECC,Poll,Area,Year]  Embedied Reduction Capital Cost ($)
  MERCD::VariableArray{2} = ReadDisk(db,"MEInput/MERCD") #[ECC,Poll]  Reduction Capital Construction Delay (Years)
  MERCI::VariableArray{3} = ReadDisk(db,"MEOutput/MERCI",year) #[ECC,Poll,Area,Year]  Reduction Capital Initiation (Tonnes/Yr/Yr)
  MERCPL::VariableArray{2} = ReadDisk(db,"MEInput/MERCPL") #[ECC,Poll]  Reduction Capital Pysical Life (Years)
  MERCR::VariableArray{3} = ReadDisk(db,"MEOutput/MERCR",year) #[ECC,Poll,Area,Year]  Reduction Capital Completion Rate (Tonnes/Yr/Yr)
  MERCRPrior::VariableArray{3} = ReadDisk(db,"MEOutput/MERCR",prior) #[ECC,Poll,Area,Year]  Reduction Capital Completion Rate (Tonnes/Yr/Yr)
  MERCstM::VariableArray{2} = ReadDisk(db,"MEInput/MERCstM",year) #[ECC,Poll,Year]  Reduction Cost Technology multiplier ($/$)
  MERCSw::VariableArray{3} = ReadDisk(db,"MEInput/MERCSw",year) #[ECC,Poll,Area,Year]  Emission Reduction Curve Switch (1=Old, 2=New, 0 = None)
  MEReduce::VariableArray{3} = ReadDisk(db,"SOutput/MEReduce",year) #[ECC,Poll,Area,Year]  Reductions from Economic Activity Emissions (Tonnes/Yr)
  MERICap::VariableArray{3} = ReadDisk(db,"MEOutput/MERICap",year) #[ECC,Poll,Area,Year]  Indicated Reduction Capital (Tonnes/Yr)
  MERM::VariableArray{3} = ReadDisk(db,"MEOutput/MERM",year) #[ECC,Poll,Area,Year]  Reduction Multiplier (Tonnes/Tonnes)
  MEROCF::VariableArray{2} = ReadDisk(db,"MEInput/MEROCF") #[ECC,Poll]  Polution Reducution O&M ($/Tonne/($/Tonne))
  MEROIN::VariableArray{2} = ReadDisk(db,"MEInput/MEROIN",year) #[ECC,Area,Year]  Non Energy eCO2 Reduction Return on Investment ($/$)
  MERP::VariableArray{3} = ReadDisk(db,"MEOutput/MERP",year) #[ECC,Poll,Area,Year]  Pollutant Reduction (Tonnes/Tonnes)
  MERPPrior::VariableArray{3} = ReadDisk(db,"MEOutput/MERP",prior) #[ECC,Poll,Area,Prior]  Pollutant Reduction in Previous Year (Tonnes/Tonnes)
  # 23.08.15, LJD: MERPXP is Unused
  # MERPXP::VariableArray{4} = ReadDisk(db,"MEOutput/MERPXP",year) #[ECC,Poll,PollX,Area,Year]  Pollutant Reduction with Cross Impacts (Tonnes/Tonnes)
  METL::VariableArray{2} = ReadDisk(db,"MEInput/METL",year) #[ECC,Area,Year]  Non Energy eCO2 Reduction Tax Lifetime (Years)
  METxRt::VariableArray{2} = ReadDisk(db,"MEInput/METxRt",year) #[ECC,Area,Year]  Non Energy eCO2 Reduction Tax Rate ($/$)
  MEVR::VariableArray{3} = ReadDisk(db,"MEOutput/MEVR",year) #[ECC,Poll,Area,Year]  Voluntary Reduction Policy (Tonnes/Tonnes)
  MEVRPrior::VariableArray{3} = ReadDisk(db,"MEOutput/MEVR",prior) #[ECC,Poll,Area,Year]  Voluntary Reduction Policy (Tonnes/Tonnes)
  MEVRP::VariableArray{3} = ReadDisk(db,"MEInput/MEVRP",year) #[ECC,Poll,Area,Year]  Voluntary Reduction Policy (Tonnes/Tonnes)
  MEVRRT::VariableArray{1} = ReadDisk(db,"MEInput/MEVRRT") #[ECC]  Voluntary Reduction response time (Years)
  MWDecayTime::VariableArray{1} = ReadDisk(db,"MEInput/MWDecayTime") #[Area]  Municipal Waste Decay Time (Years)
  MWEPol::VariableArray{2} = ReadDisk(db,"MEOutput/MWEPol",year) #[Poll,Area,Year]  Embodied Solid Waste Pollution (Tonnes/Yr)
  MWPolAdd::VariableArray{2} = ReadDisk(db,"MEOutput/MWPolAdd",year) #[Poll,Area,Year]  Solid Waste Pollution Additions (Tonnes/Yr)
  OAPrEOR::VariableArray{2} = ReadDisk(db,"SOutput/OAPrEOR",year) #[Process,Area,Year]  Oil Production from EOR (TBtu/Yr)
  ORMEPOCA::VariableArray{3} = ReadDisk(db,"MEOutput/ORMEPOCA",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution Coefficient (Tonnes/$B-output)
  ORMEPOCX::VariableArray{3} = ReadDisk(db,"MEInput/ORMEPOCX",year) #[ECC,Poll,Area,Year]  Non-Energy Off Road Pollution Coefficient (Tonnes/Economic Driver)
  ORMEPol::VariableArray{3} = ReadDisk(db,"SOutput/ORMEPol",year) #[ECC,Poll,Area,Year]  Process Off Road Pollution (Tonnes/Year)
  PAdCost::VariableArray{3} = ReadDisk(db,"SInput/PAdCost",year) #[ECC,Poll,Area,Year]  Policy Administrative Cost (Exogenous)
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost (Real $/Tonnes)
  PCostExo::VariableArray{3} = ReadDisk(db,"SInput/PCostExo",year) #[ECC,Poll,Area,Year]  Exogenous Permit Cost (Real $/Tonnes)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (eCO2 Tonnes/Tonne)
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) #[Poll,Market,Year]  Pollutants included in Market
  PRExp::VariableArray{3} = ReadDisk(db,"SOutput/PRExp",year) #[ECC,Poll,Area,Year]  Reduction Private Expenses (M$/Yr)
  RPolicy::VariableArray{3} = ReadDisk(db,"SOutput/RPolicy",year) #[ECC,Poll,Area,Year]  Provincial Reduction from Limit (Tonnes/Tonnes)
  SqA0::VariableArray{2} = ReadDisk(db,"MEInput/SqA0",year) #[ECC,Area,Year]  A Term in eCO2 Sequestering Curve (units assume 2016 CN$)
  SqB0::VariableArray{2} = ReadDisk(db,"MEInput/SqB0",year) #[ECC,Area,Year]  B Term in eCO2 Sequestering Curve (Dimensionless)
  SqBL::VariableArray{1} = ReadDisk(db,"MEInput/SqBL",year) #[Area,Year]  Sequestering Book Lifetime (Years)
  SqC0::VariableArray{2} = ReadDisk(db,"MEInput/SqC0",year) #[ECC,Area,Year]  C Term in eCO2 Sequestering Curve (Tonnes/Tonnes)
  SqCap::VariableArray{2} = ReadDisk(db,"MEOutput/SqCap",year) #[ECC,Area,Year]  Sequestering eCO2 Reduction Capacity (Tonnes/Yr)
  SqCapPrior::VariableArray{2} = ReadDisk(db,"MEOutput/SqCap",prior) #[ECC,Area,Prior]  Sequestering eCO2 Reduction Capacity in Previous Year (Tonnes/Yr)
  SqCapCI::VariableArray{2} = ReadDisk(db,"MEOutput/SqCapCI",year) #[ECC,Area,Year]  Sequestering Capacity Construction Initiation (Tonnes/Yr/Yr)
  SqCapCR::VariableArray{2} = ReadDisk(db,"MEOutput/SqCapCR",year) #[ECC,Area,Year]  Sequestering Capacity Completion Rate (Tonnes/Yr/Yr)
  SqCapRR::VariableArray{2} = ReadDisk(db,"MEOutput/SqCapRR",year) #[ECC,Area,Year]  Sequestering Capacity Retirement Rate (Tonnes/Yr/Yr)
  SqCC::VariableArray{2} = ReadDisk(db,"MEOutput/SqCC",year) #[ECC,Area,Year]  Sequestering eCO2 Reduction Capital Cost ($/Tonne)
  SqCCA0::VariableArray{2} = ReadDisk(db,"MEInput/SqCCA0",year) #[ECC,Area,Year]  A Term in eCO2 Sequestering Capital Cost Curve (2012 CN$)
  SqCCB0::VariableArray{2} = ReadDisk(db,"MEInput/SqCCB0",year) #[ECC,Area,Year]  B Term in eCO2 Sequestering Capital Cost Curve (2012 CN$)
  SqCCC0::VariableArray{2} = ReadDisk(db,"MEInput/SqCCC0",year) #[ECC,Area,Year]  C Term in eCO2 Sequestering Capital Cost Curve (2012 CN$)
  SqCCEm::VariableArray{2} = ReadDisk(db,"MEOutput/SqCCEm",year) #[ECC,Area,Year]  Sequestering eCO2 Reduction Embedded Capital Cost ($/Tonne)
  SqCCEmPrior::VariableArray{2} = ReadDisk(db,"MEOutput/SqCCEm",prior) #[ECC,Area,Year]  Sequestering eCO2 Reduction Embedded Capital Cost ($/Tonne)
  SqCCLevelized::VariableArray{2} = ReadDisk(db,"MEOutput/SqCCLevelized",year) #[ECC,Area,Year]  Sequestering Levelized Capital Cost for Capital Cost Curve (2016 CN$/tonne CO2e)
  SqCCR::VariableArray{1} = ReadDisk(db,"MEOutput/SqCCR",year) #[Area,Year]  Sequestering eCO2 Reduction Capital Charge Rate ($/$)
  SqCCRMult::VariableArray{1} = ReadDisk(db,"MEOutput/SqCCRMult",year) #[Area,Year]  Sequestering eCO2 Reduction Capital Charge Rate Multiplier ($/$)
  SqCCSw::VariableArray{2} = ReadDisk(db,"MEInput/SqCCSw",year) #[ECC,Area,Year]  Sequestering Capital Cost Switch (1=CC Curve)
  SqCCThreshold::VariableArray{2} = ReadDisk(db,"MEInput/SqCCThreshold",year) #[ECC,Area,Year]  Levelized Cost Threshold for Sequestering Curve (2016 CN$/Tonne)
  SqCD::VariableArray{2} = ReadDisk(db,"MEInput/SqCD",year) #[ECC,Area,Year]  Sequestering Construction Delay (Years)
  SqCDOrder::VariableArray{1} = ReadDisk(db,"MEInput/SqCDOrder",year) #[ECC,Year]  Number of Levels in the Sequestering Construction Delay (Number)
  SqCDInput::VariableArray{3} = ReadDisk(db,"MEOutput/SqCDInput",year) #[Level,ECC,Area,Year]  Input to Sequestering Delay Level (Tonnes/Yr/Yr)
  SqCDLevel::VariableArray{3} = ReadDisk(db,"MEOutput/SqCDLevel",year) #[Level,ECC,Area,Year]  Sequestering Delay Level (Tonnes/Yr)
  SqCDLevelPrior::VariableArray{3} = ReadDisk(db,"MEOutput/SqCDLevel",prior) #[Level,ECC,Area,Year]  Sequestering Delay Level (Tonnes/Yr)
  SqCDOutput::VariableArray{3} = ReadDisk(db,"MEOutput/SqCDOutput",year) #[Level,ECC,Area,Year]  Output from Sequestering Delay Level (Tonnes/Yr/Yr)
  SqFuelCost::VariableArray{2} = ReadDisk(db,"SOutput/SqFuelCost",year) #[ECC,Area,Year]  Sequestering Fuel Costs ($/Tonnes)
  SqGExp::VariableArray{2} = ReadDisk(db,"MEOutput/SqGExp",year) #[ECC,Area,Year]  Sequestering Government Expenses (M$/Yr)
  SqGFr::VariableArray{1} = ReadDisk(db,"MEInput/SqGFr",year) #[Area,Year]  Sequestering CO2 Reduction Grant Fraction ($/$)
  SqInv::VariableArray{2} = ReadDisk(db,"SOutput/SqInv",year) #[ECC,Area,Year]  Sequestering Investments (M$/Yr)
  SqIVTC::VariableArray{1} = ReadDisk(db,"MEInput/SqIVTC",year) #[Area,Year]  Sequestering CO2 Reduction Investment Tax Credit ($/$)
  SqIPol::VariableArray{3} = ReadDisk(db,"MEOutput/SqIPol",year) #[ECC,Poll,Area,Year]  CCS Indicated for Construction (Tonnes/Yr)
  SqIPolCC::VariableArray{3} = ReadDisk(db,"MEOutput/SqIPolCC",year) #[ECC,Poll,Area,Year]  CCS Indicated from Cost Curves (Tonnes/Yr)
  SqOCF::VariableArray{2} = ReadDisk(db,"SInput/SqOCF",year) #[ECC,Area,Year]  Sequestering eCO2 Reduction Operating Cost Factor ($/$)
  SqOMExp::VariableArray{2} = ReadDisk(db,"SOutput/SqOMExp",year) #[ECC,Area,Year]  Sequestering O&M Expenses (M$/Yr)
  
  SqPenaltyFracPrior::VariableArray{3} = ReadDisk(db,"MEInput/SqPenaltyFrac",prior) #[ECC,Poll,Area,Year] Sequestering Emission Penalty (Tonne/Tonne)
  
  SqPExp::VariableArray{2} = ReadDisk(db,"SOutput/SqPExp",year) #[ECC,Area,Year]  Sequestering Private Expenses (M$/Yr)
  SqPGMult::VariableArray{3} = ReadDisk(db,"SInput/SqPGMult",year) #[ECC,Poll,Area,Year]  Sequestering Gratis Permit Multiplier (Tonnes/Tonnes)
  SqPL::VariableArray{1} = ReadDisk(db,"MEInput/SqPL",year) #[Area,Year]  Sequestering eCO2 Reduction Physical Lifetime (Years)
  SqPOCF::VariableArray{3} = ReadDisk(db,"MEInput/SqPOCF",year) #[ECC,Poll,Area,Year]  Sequestering Emission Factor (Tonnes/Tonne CO2)
  SqPol::VariableArray{3} = ReadDisk(db,"SOutput/SqPol",year) #[ECC,Poll,Area,Year]  Sequestering Gross Emissions (Tonnes/Yr)
  SqPolCC::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCC",year) #[ECC,Poll,Area,Year]  Sequestering Cost Curve Gross Emissions (Tonnes/Yr)
  SqPolCCNet::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCNet",year) #[ECC,Poll,Area,Year]  Sequestering Cost Curve Net Emissions (Tonnes/Yr)
  SqPolCCNetPrior::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCNet",prior) #[ECC,Poll,Area,Prior]  Sequestering Non-Cogeneration Emissions in Previous Year (Tonnes/Yr)
  SqPolCCPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCPenalty",year) #[ECC,Poll,Area,Year]  Sequestering Emissions Penalty (Tonnes/Yr)
  SqPolCg::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCg",year) #[ECC,Poll,Area,Year]  Sequestering Cogeneration Gross Emissions (Tonnes/Yr)
  SqPolCgPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCgPenalty",year) #[ECC,Poll,Area,Year]  Sequestering Cogeneration Emissions Penalty (Tonnes/Yr)
  SqPolNet::VariableArray{3} = ReadDisk(db,"SOutput/SqPolNet",year) #[ECC,Poll,Area,Year]  Net Sequestering Emissions (Tonnes/Yr)
  SqPolPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolPenalty",year) #[ECC,Poll,Area,Year]  Sequestering Emissions Penalty (Tonnes/Yr)
  
  SqPotential::VariableArray{3} = ReadDisk(db,"SOutput/SqPotential",year) #[ECC,Poll,Area,Prior]  Potential Sequestering Emissions (Tonnes/Yr)
  SqPotentialPrior::VariableArray{3} = ReadDisk(db,"SOutput/SqPotential",prior) #[ECC,Poll,Area,Prior]  Potential Sequestering Emissions (Tonnes/Yr)
  
  SqPrice::VariableArray{2} = ReadDisk(db,"MEOutput/SqPrice",year) #[ECC,Area,Year]  Sequestering Price for Cost Curve (2016 CN$/tonne CO2e)
  SqReduction::VariableArray{3} = ReadDisk(db,"MEOutput/SqReduction",year) #[ECC,Poll,Area,Year]  Sequestering Fraction Captured Marginal(tonne/tonne)
  SqReductionEm::VariableArray{3} = ReadDisk(db,"MEOutput/SqReductionEm",year) #[ECC,Poll,Area,Year]  Sequestering Fraction Captured Embedded (tonne/tonne)
  SqReductionEmPrior::VariableArray{3} = ReadDisk(db,"MEOutput/SqReductionEm",prior) #[ECC,Poll,Area,Prior]  Sequestering Fraction Captured Embedded in Previous Year (tonne/tonne)
  SqROIN::VariableArray{1} = ReadDisk(db,"MEInput/SqROIN",year) #[Area,Year]  Sequestering eCO2 Reduction Return on Investment ($/$)
  SqTL::VariableArray{1} = ReadDisk(db,"MEInput/SqTL",year) #[Area,Year]  Sequestering eCO2 Reduction Tax Lifetime (Years)
  SqTM::VariableArray{2} = ReadDisk(db,"MEInput/SqTM",year) #[ECC,Area,Year]  Sequestering Technology Multiplier ($/$)
  SqTransStorageCost::VariableArray{1} = ReadDisk(db,"MEInput/SqTransStorageCost",year) #[Area,Year]  Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e)
  
  SqTSCapitalFraction::VariableArray{1} = ReadDisk(db,"MEInput/SqTSCapitalFraction",year) #[Area,Year]  Captial Fraction of Sequestering Transportation and Storage Costs ($/$)

  SqTSCost::VariableArray{1} = ReadDisk(db,"MEOutput/SqTSCost",year) #[Area,Year]  Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e) 
  
  SqTxRt::VariableArray{1} = ReadDisk(db,"MEInput/SqTxRt",year) #[Area,Year]  Sequestering eCO2 Reduction Tax Rate ($/$)
  VnA0::VariableArray{2} = ReadDisk(db,"MEInput/VnA0") #[ECC,Area]  A Term in Venting Reduction Curve (??)
  VnB0::VariableArray{2} = ReadDisk(db,"MEInput/VnB0") #[ECC,Area]  B Term in Venting Reduction Curve (??)
  VnC0::VariableArray{2} = ReadDisk(db,"MEInput/VnC0",year) #[ECC,Area,Year]  C Term in Venting Reduction Curve (??)
  VnC2H6PerCH4::VariableArray{2} = ReadDisk(db,"MEInput/VnC2H6PerCH4",year) #[ECC,Area,Year]  Venting Reduction C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  VnCap::VariableArray{2} = ReadDisk(db,"MEOutput/VnCap",year) #[ECC,Area,Year]  Venting Reduction Capacity (Tonnes/Yr)
  VnCapPrior::VariableArray{2} = ReadDisk(db,"MEOutput/VnCap",prior) #[ECC,Area,Prior]  Venting Reduction Capacity in Previous Year (Tonnes/Yr)
  VnCC::VariableArray{2} = ReadDisk(db,"MEOutput/VnCC",year) #[ECC,Area,Year]  Venting Reduction Capital Cost ($/Tonne)
  VnCCA0::VariableArray{2} = ReadDisk(db,"MEInput/VnCCA0") #[ECC,Area]  A Term in Venting Reduction Capital Cost Curve ($/$)
  VnCCB0::VariableArray{2} = ReadDisk(db,"MEInput/VnCCB0") #[ECC,Area]  B Term in Venting Reduction Capital Cost Curve ($/$)
  VnCCC0::VariableArray{2} = ReadDisk(db,"MEInput/VnCCC0",year) #[ECC,Area,Year]  C Term in Venting Reduction Capital Cost Curve ($/$)
  VnCCEm::VariableArray{2} = ReadDisk(db,"MEOutput/VnCCEm",year) #[ECC,Area,Year]  Venting Reduction Embedded Capital Cost ($/Tonne)
  VnCCEmPrior::VariableArray{2} = ReadDisk(db,"MEOutput/VnCCEm",prior) #[ECC,Area,Prior]  Venting Reduction Embedded Capital Cost in Previous Year  ($/Tonne)
  VnCH4Captured::VariableArray{2} = ReadDisk(db,"MEOutput/VnCH4Captured",year) #[ECC,Area,Year]  CH4 Captured from Venting Reductions (Tonnes/Yr)
  VnCH4CapturedFraction::VariableArray{2} = ReadDisk(db,"MEInput/VnCH4CapturedFraction",year) #[ECC,Area,Year]  Fraction of Captured from Venting Reductions (Tonnes/Tonnes)
  VnCH4Flared::VariableArray{2} = ReadDisk(db,"MEOutput/VnCH4Flared",year) #[ECC,Area,Year]  CH4 Flared from Venting Reductions (Tonnes/Yr)
  VnCH4FlaredPOCF::VariableArray{3} = ReadDisk(db,"MEInput/VnCH4FlaredPOCF",year) #[ECC,Poll,Area,Year]  Pollution Coefficient for Flared CH4 (Tonnes/Tonnes)
  VnCH4FlPol::VariableArray{3} = ReadDisk(db,"MEOutput/VnCH4FlPol",year) #[ECC,Poll,Area,Year]  Emissions from Flaring CH4 (Tonnes/Yr)
  VnCosts::VariableArray{2} = ReadDisk(db,"SOutput/VnCosts",year) #[ECC,Area,Year]  Venting Reduction Costs ($/mmBtu)
  VnCR::VariableArray{2} = ReadDisk(db,"MEOutput/VnCR",year) #[ECC,Area,Year]  Venting Reduction Capacity Completion Rate (Tonnes/Yr/Yr)
  VnGAProd::VariableArray{2} = ReadDisk(db,"SOutput/VnGAProd",year) #[ECC,Area,Year]  Natural Gas Produced from Venting Reductions (TBtu/Yr)
  VnGExp::VariableArray{2} = ReadDisk(db,"MEOutput/VnGExp",year) #[ECC,Area,Year]  Venting Reduction Government Expenses (M$/Yr)
  VnGFr::VariableArray{2} = ReadDisk(db,"MEInput/VnGFr",year) #[ECC,Area,Year]  Venting Reduction Grant Fraction ($/$)
  VnGProd::VariableArray{1} = ReadDisk(db,"SOutput/VnGProd",year) #[Nation,Year]  Natural Gas Produced from Venting Reductions (TBtu/Yr)
  VnInv::VariableArray{2} = ReadDisk(db,"SOutput/VnInv",year) #[ECC,Area,Year]  Venting Reduction Investments (M$/Yr)
  VnOCF::VariableArray{2} = ReadDisk(db,"MEInput/VnOCF",year) #[ECC,Area,Year]  Venting Reduction Operating Cost Factor ($/$)
  VnOMExp::VariableArray{2} = ReadDisk(db,"SOutput/VnOMExp",year) #[ECC,Area,Year]  Venting Reduction O&M Expenses (M$/Yr)
  VnPExp::VariableArray{2} = ReadDisk(db,"SOutput/VnPExp",year) #[ECC,Area,Year]  Venting Reduction Private Expenses (M$/Yr)
  VnPL::VariableArray{2} = ReadDisk(db,"MEInput/VnPL",year) #[ECC,Area,Year]  Venting Reduction Physical Lifetime (Years)
  VnPOCF::VariableArray{3} = ReadDisk(db,"MEInput/VnPOCF",year) #[ECC,Poll,Area,Year]  Venting Other Pollutant Emission Factor (Tonnes/Tonne CH4)
  VnPOCX::VariableArray{3} = ReadDisk(db,"MEInput/VnPOCX",year) #[ECC,Poll,Area,Year]  Venting Emissions Coefficient (Tonnes/Driver)
  VnPOCXMult::VariableArray{3} = ReadDisk(db,"MEInput/VnPOCXMult",year) #[ECC,Poll,Area,Year]  Venting Pollution Coefficient Multiplier (Tonnes/Driver)
  VnPol::VariableArray{3} = ReadDisk(db,"SOutput/VnPol",year) #[ECC,Poll,Area,Year]  Venting Emissions (Tonnes/Yr)
  VnPolSwitch::VariableArray{3} = ReadDisk(db,"SInput/VnPolSwitch",year) #[ECC,Poll,Area,Year]  Venting Pollution Switch (0 = Exogenous)
  VnPrice::VariableArray{2} = ReadDisk(db,"MEOutput/VnPrice",year) #[ECC,Area,Year]  Price for Venting Reduction Curve ($/Tonne)
  VnPriceSw::Float32 = ReadDisk(db,"MEInput/VnPriceSw",year) #[Year]  Venting Reduction Curve Price Switch (1=Endogenous, 0 = Exogenous)
  VnReduce::VariableArray{3} = ReadDisk(db,"SOutput/VnReduce",year) #[ECC,Poll,Area,Year]  Venting Reductions (Tonnes/Yr)
  VnRP::VariableArray{3} = ReadDisk(db,"MEOutput/VnRP",year) #[ECC,Poll,Area,Year]  Fraction of Venting Reduced (Tonnes/Tonnes)
  xFlPol::VariableArray{3} = ReadDisk(db,"SInput/xFlPol",year) #[ECC,Poll,Area,Year]  Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{3} = ReadDisk(db,"SInput/xFuPol",year) #[ECC,Poll,Area,Year]  Other Fugitives Emissions (Tonnes/Yr)
  xFuPrice::VariableArray{2} = ReadDisk(db,"MEInput/xFuPrice",year) #[ECC,Area,Year]  Exogenous Price for Other Fugitives Reduction Curve ($/Tonne)
  xLUFr::VariableArray{2} = ReadDisk(db,"MEInput/xLUFr",year) #[LU,Area,Year]  Exogenous Land Use Area Fraction (Acre/Acre)
  xMEPol::VariableArray{3} = ReadDisk(db,"SInput/xMEPol",year) #[ECC,Poll,Area,Year]  Process Pollution (Tonnes/Yr)
  xMEPrice::VariableArray{3} = ReadDisk(db,"MEInput/xMEPrice",year) #[ECC,Poll,Area,Year]  Exogenous Price for Process Emission Reduction Curve ($/eCO2 Tonne)
  xMERM::VariableArray{3} = ReadDisk(db,"MEInput/xMERM",year) #[ECC,Poll,Area,Year]  Exogenous Average Pollution Coefficient Reduction Multiplier (Tonnes/Tonnes)
  xPRExp::VariableArray{3} = ReadDisk(db,"SInput/xPRExp",year) #[ECC,Poll,Area,Year]  Exogenous Reduction Private Expenses (M$/Yr)

  xSqPol::VariableArray{3} = ReadDisk(db,"MEInput/xSqPol",year) #[ECC,Poll,Area,Year]  Exogenous Sequestering Gross Emissions (Tonnes/Yr)
    
  xSqPolCCNet::VariableArray{3} = ReadDisk(db,"MEInput/xSqPolCCNet",year) #[ECC,Poll,Area,Year]  Exogenous Sequestering Net Emissions (Tonnes/Yr)
  xSqPrice::VariableArray{2} = ReadDisk(db,"MEInput/xSqPrice",year) #[ECC,Area,Year]  Exogenous Sequestering Cost Curve Price (Real CN$/tonne CO2e)

  xSqPriceAdd::VariableArray{2} = ReadDisk(db,"MEInput/xSqPriceAdd",year) #[ECC,Area,Year]  Exogenous Adder to Sequestering Cost Curve Price (Real CN$/tonne CO2e)

  xVnPol::VariableArray{3} = ReadDisk(db,"SInput/xVnPol",year) #[ECC,Poll,Area,Year]  Venting Emissions (Tonnes/Yr)
  xVnPrice::VariableArray{2} = ReadDisk(db,"MEInput/xVnPrice",year) #[ECC,Area,Year]  Exogenous Price for Venting Reduction Curve ($/Tonne)

  #
  # Scratch Variables
  #
  EORCO2::VariableArray{1} = zeros(Float32,length(Area))
  FlReduceEndogenous::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  FlReduceRegulations::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  FlReduceExogenous::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  FuReduceEndogenous::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  FuReduceRegulations::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  FuReduceExogenous::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  MERPStd::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  RPFull::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  SqCapEff::VariableArray{2} = zeros(Float32,length(ECC),length(Area))
  SqCCLevelForCC::VariableArray{2} = zeros(Float32,length(ECC),length(Area))
  SqCCR0::VariableArray{1} = zeros(Float32,length(Area))
  VnReduceEndogenous::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  VnReduceRegulations::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  VnReduceExogenous::VariableArray{3} = zeros(Float32,length(ECC),length(Poll),length(Area))
  
  KJBtu = 1.054615
  TBtuGasPerTonneCH4=55.577*KJBtu/1e6
end

# TODOJulia - dimension Inflation by year and remove all the InflationYr variables - Jeff Amlin 1/15/25

function CCSInitiation(data::Data)
  (; db,CTime,year,Yr2012,Yr2016) = data
  (; Area,Areas,ECC,ECCs,Level,Levels, PCov,Poll,Polls) = data #sets
  (; ECoverage,FPCFSObligated,Inflation,InflationYr,InSm,PCost,PCostExo) = data  
  (; SqBL,SqA0,SqB0,SqC0,SqCap,SqCapCR,SqCapCI,SqCapEff,SqCapPrior,SqCapRR,SqCC,SqCCA0,SqCCB0,SqCCC0,SqCCLevelized) = data
  (; SqCCR,SqCCR0,SqCCRMult,SqCCSw,SqCCThreshold,SqCD,SqCDInput,SqCDLevel,SqCDLevelPrior,SqCDOrder,SqCDOutput,SqFuelCost) = data
  (; SqIPol,SqIVTC,SqOCF,SqIPolCC,SqPenaltyFracPrior,SqPGMult,SqPL) = data
  (; SqPolCCNet,SqPolCCNetPrior,SqPotential,SqPotentialPrior,SqPrice,SqReduction,SqReductionEm) = data
  (; SqReductionEmPrior,SqROIN,SqTL,SqTM,SqTransStorageCost,SqTSCapitalFraction,SqTSCost,SqTxRt,xSqPol,xSqPolCCNet,xSqPrice) = data
  (; SqCCLevelForCC,xSqPriceAdd) = data
  # @info "  MPollution.jl - CCSInitiation"

  @. xSqPolCCNet = xSqPol/(1+SqPenaltyFracPrior)
  WriteDisk(db,"MEInput/xSqPolCCNet",year,xSqPolCCNet)

  #
  # Sequestering is driven by CO2 prices
  #
  CO2 = Select(Poll,"CO2")

  #
  #  Sequestering Capital Charge Rate with and without ITC
  #
  for area in Areas
    @finite_math SqCCR0[area] = (1 - 0/(1+SqROIN[area]+InSm[area])-SqTxRt[area]*(2/SqTL[area])/
                                (SqROIN[area]+InSm[area]+2/SqTL[area]))*SqROIN[area]/
                                (1-(1/(1+SqROIN[area]))^SqBL[area])/(1-SqTxRt[area])

    @finite_math SqCCR[area] = (1-SqIVTC[area]/(1+SqROIN[area]+InSm[area])-SqTxRt[area]*(2/SqTL[area])/
                             (SqROIN[area]+InSm[area]+2/SqTL[area]))*SqROIN[area]/
                             (1-(1/(1+SqROIN[area]))^SqBL[area])/(1-SqTxRt[area])
    @finite_math SqCCRMult[area] = SqCCR[area]/SqCCR0[area]
  end

  WriteDisk(db,"MEOutput/SqCCR",year,SqCCR)
  WriteDisk(db,"MEOutput/SqCCRMult",year,SqCCRMult)
  
  #
  # Apply ITC to CCS Transportation and Storage Costs
  #
  @. SqTSCost = SqTransStorageCost*(SqTSCapitalFraction*SqCCRMult+(1-SqTSCapitalFraction))
  WriteDisk(db,"MEOutput/SqTSCost",year,SqTSCost)  

  for area in Areas, ecc in ECCs
    pcov = Select(PCov,"Energy")
    
    #
    # Sequestering "Price" (Cost Curve is in 2016 CN$)
    #
    @finite_math SqPrice[ecc,area] =
      (max(PCost[ecc,CO2,area]*SqPGMult[ecc,CO2,area]*ECoverage[ecc,CO2,pcov,area]+
           PCostExo[ecc,CO2,area]+FPCFSObligated[ecc,area]/Inflation[area],
           xSqPrice[ecc,area])+xSqPriceAdd[ecc,area])*InflationYr[area,Yr2016]
          
    @finite_math SqCCLevelized[ecc,area] = (SqPrice[ecc,area]-SqTSCost[area]-
      SqFuelCost[ecc,area]/Inflation[area]*InflationYr[area,Yr2016])/SqCCRMult[area]

    if (SqCCLevelized[ecc,area] > SqCCThreshold[ecc,area]) && (SqC0[ecc,area] > 0)
      
      #
      # Sequestering Reduction Indicated from Cost Curve
      #
      @finite_math SqReduction[ecc,CO2,area] = min((SqC0[ecc,area]/(1+SqA0[ecc,area]*
      (SqCCLevelized[ecc,area]/SqTM[ecc,area])^SqB0[ecc,area])),SqC0[ecc,area]*0.999)
      
      @finite_math SqCCLevelForCC[ecc,area] =
                   ((SqC0[ecc,area]/SqReduction[ecc,CO2,area]-1)/
                   SqA0[ecc,area])^(1/SqB0[ecc,area])/SqTM[ecc,area]
      
      SqIPolCC[ecc,CO2,area] = 0-SqReduction[ecc,CO2,area]*SqPotentialPrior[ecc,CO2,area]
      
      #
      # Sequestering Capital Costs
      #
      if SqCCSw[ecc,area] == 1
        @finite_math SqCC[ecc,area] = SqCCC0[ecc,area]/(1+SqCCA0[ecc,area]*
                    (SqCCLevelized[ecc,area]/SqTM[ecc,area])^SqCCB0[ecc,area])
     
        @finite_math SqCC[ecc,area] =
                     SqCC[ecc,area]/InflationYr[area,Yr2012]*Inflation[area]

      elseif SqCCSw[ecc,area] == 2
        @finite_math SqCC[ecc,area] = (PCost[ecc,CO2,area]+PCostExo[ecc,CO2,area]+
                     FPCFSObligated[ecc,area]/Inflation[area])/
                    (SqCCR[area]+SqOCF[ecc,area])*Inflation[area]
         
      elseif SqCCSw[ecc,area] == 3
        @finite_math SqCC[ecc,area] = SqCCLevelForCC[ecc,area]/InflationYr[area,Yr2016]/
                    (SqCCR[area]+SqOCF[ecc,area])*Inflation[area]
      end
    else
      SqReduction[ecc,CO2,area] = 0
      SqIPolCC[ecc,CO2,area] = 0
      SqCC[ecc,area] = 0
    end
    SqReductionEm[ecc,CO2,area] = max(SqReductionEmPrior[ecc,CO2,area],
                                      SqReduction[ecc,CO2,area])
  end

  WriteDisk(db,"MEOutput/SqCC",year,SqCC)
  WriteDisk(db,"MEOutput/SqCCLevelized",year,SqCCLevelized)
  WriteDisk(db,"MEOutput/SqIPolCC",year,SqIPolCC)
  WriteDisk(db,"MEOutput/SqPrice",year,SqPrice)
  WriteDisk(db,"MEOutput/SqReduction",year,SqReduction)
  WriteDisk(db,"MEOutput/SqReductionEm",year,SqReductionEm)
  
  #
  # All the values in the equation are negative; therefore,
  # CCS Indicated (SqIPol) is CCS indicated by CCS curve (SqIPolCC),
  # but not less than previous year value (SqPolCCNetPrior) less
  # retirements (SqPolCCNetPrior/SqPL) or less than the amount
  # developed exogenously (by government) (xSqPolCCNet).
  #

  for area in Areas, ecc in ECCs
    @finite_math SqIPol[ecc,CO2,area] = min(SqIPolCC[ecc,CO2,area],
      (SqPolCCNetPrior[ecc,CO2,area]-
       SqPolCCNetPrior[ecc,CO2,area]/SqPL[area])*SqPL[area]/SqPL[area],
      xSqPolCCNet[ecc,CO2,area])
  end
  WriteDisk(db,"MEOutput/SqIPol",year,SqIPol)

  #
  # Sequestering Capacity Retired
  #
  for area in Areas, ecc in ECCs
    @finite_math SqCapRR[ecc,area] = SqCapPrior[ecc,area]/SqPL[area]
  end
  WriteDisk(db,"MEOutput/SqCapRR",year,SqCapRR)

  #
  # Sequestering Effective Capacity
  #
  for area in Areas, ecc in ECCs
    SqCapEff[ecc,area] = SqCapPrior[ecc,area]-SqCapRR[ecc,area]+
                         sum(SqCDLevelPrior[level,ecc,area] for level in Levels)

    #
    # Sequestering Capacity Construction Initiated
    #
    SqCapCI[ecc,area] = max(0-SqIPol[ecc,CO2,area]-SqCapEff[ecc,area],0.0)
  end
  WriteDisk(db,"MEOutput/SqCapCI",year,SqCapCI)

  #
  # CCS Construction Delay
  #
  for area in Areas, ecc in ECCs
    if SqCD[ecc,area] > 0.0
      for level in Levels
        @finite_math SqCDOutput[level,ecc,area] = SqCDLevelPrior[level,ecc,area]/
                                                 (SqCD[ecc,area]/SqCDOrder[ecc])
      end

      sqcdorder::Integer = floor(SqCDOrder[ecc])
      for level in 2:sqcdorder
        SqCDInput[level,ecc,area] = SqCDOutput[level-1,ecc,area]
      end

      SqCDInput[1,ecc,area] = SqCapCI[ecc,area]

      for level in Levels
        SqCDLevel[level,ecc,area] = SqCDLevelPrior[level,ecc,area]+
                                    (SqCDInput[level,ecc,area]-SqCDOutput[level,ecc,area])
      end

      SqCapCR[ecc,area] = max(SqCDOutput[sqcdorder,ecc,area], 0.0)
      
    else
      SqCapCR[ecc,area] = SqCapCI[ecc,area]+
                          sum(SqCDLevelPrior[level,ecc,area] for level in Levels)      
    end
  end

  WriteDisk(db,"MEOutput/SqCDInput",year,SqCDInput)
  WriteDisk(db,"MEOutput/SqCDLevel",year,SqCDLevel)
  WriteDisk(db,"MEOutput/SqCDOutput",year,SqCDOutput)
  WriteDisk(db,"MEOutput/SqCapCR",year,SqCapCR)

  #
  # Sequestering Capacity
  #
  for area in Areas, ecc in ECCs
    SqCap[ecc,area] = SqCapPrior[ecc,area]+DT*(SqCapCR[ecc,area]-SqCapRR[ecc,area])
  end

  WriteDisk(db,"MEOutput/SqCap",year,SqCap)

  #
  ########################
  #
  #  Sequestering from Cost Curves
  #
  ecc1 = Select(ECC,!=("UtilityGen"))
  ecc2 = Select(ECC,!=("H2Production"))
  ecc3 = Select(ECC,!=("BiofuelProduction"))
  ecc4 = Select(ECC,!=("DirectAirCapture"))
  eccs = intersect(ecc1,ecc2,ecc3,ecc4)

  for area in Areas, ecc in eccs
    if CTime <= HisTime
      SqPolCCNet[ecc,CO2,area] = xSqPolCCNet[ecc,CO2,area]
    else
                        
      SqPolCCNet[ecc,CO2,area] = 0-max(min(SqCap[ecc,area],
        SqReductionEm[ecc,CO2,area]*SqPotentialPrior[ecc,CO2,area]),
        0-xSqPolCCNet[ecc,CO2,area])    
                                     
    end
  end

  WriteDisk(db,"SOutput/SqPolCCNet",year,SqPolCCNet)
end # function CCSInitiation

function CCSReductions(data::Data,areas,nation)
  (; db,year,CTime) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls,Process) = data #sets
  (; EORCO2,EORCreditMultiplier,EORCredits,EORFraction,EORLimit,EORRate) = data
  (; OAPrEOR,SqCap,SqCapCR,SqCapPrior,SqCC,SqCCEm,SqCCEmPrior,SqGExp) = data
  (; SqGFr,SqInv,SqOCF,SqOMExp,SqPenaltyFracPrior,SqPExp,SqPL,SqPOCF,SqPol,SqPolCC) = data
  (; SqPolCCNet,SqPolCCPenalty,SqPolCg,SqPolCgPenalty,SqPolNet,SqPolPenalty) = data
  (; SqPotential,SqReductionEm,xSqPol,xSqPolCCNet) = data

  # @info "  MPollution.jl - CCSReductions"

  @. xSqPolCCNet = xSqPol/(1+SqPenaltyFracPrior)
  WriteDisk(db,"MEInput/xSqPolCCNet",year,xSqPolCCNet)

  #
  # Sequestering from Cost Curves
  #
  ecc1 = Select(ECC,!=("UtilityGen"))
  ecc2 = Select(ECC,!=("H2Production"))
  ecc3 = Select(ECC,!=("BiofuelProduction"))
  ecc4 = Select(ECC,!=("DirectAirCapture"))
  eccs = intersect(ecc1,ecc2,ecc3,ecc4)

  if CTime <= HisTime
    for area in areas, poll in Polls, ecc in eccs 
      SqPolCCNet[ecc,poll,area] = xSqPolCCNet[ecc,poll,area]
    end
    
  else
    for area in areas, poll in Polls, ecc in eccs                         
      SqPolCCNet[ecc,poll,area] = 0-max(min(SqCap[ecc,area],
        SqReductionEm[ecc,poll,area]*SqPotential[ecc,poll,area]),
        0-xSqPolCCNet[ecc,poll,area])                                    
    end
    
  end

  WriteDisk(db,"SOutput/SqPolCCNet",year,SqPolCCNet)

  #
  # Non-Cogeneration Sequestering
  #
  ecc1 = Select(ECC,!=("UtilityGen"))
  ecc2 = Select(ECC,!=("H2Production"))
  ecc3 = Select(ECC,!=("BiofuelProduction"))
  ecc4 = Select(ECC,!=("DirectAirCapture"))
  eccs = intersect(ecc1,ecc2,ecc3,ecc4)
  for area in areas, poll in Polls, ecc in eccs
    SqPolCC[ecc,poll,area] = SqPolCCNet[ecc,poll,area]+SqPolCCPenalty[ecc,poll,area]
  end

  WriteDisk(db,"SOutput/SqPolCC",year,SqPolCC)

  #
  # Sequestering
  #
  for area in areas, poll in Polls, ecc in ECCs
    SqPolNet[ecc,poll,area] = SqPolCCNet[ecc,poll,area]+SqPolCg[ecc,poll,area]-
                            SqPolCgPenalty[ecc,poll,area]
    SqPolPenalty[ecc,poll,area] = SqPolCCPenalty[ecc,poll,area]+
                                SqPolCgPenalty[ecc,poll,area]
    SqPol[ecc,poll,area] = SqPolNet[ecc,poll,area]+SqPolPenalty[ecc,poll,area]
  end
  
  #
  # Sequestering of other Pollutants
  #
  CO2 =  Select(Poll,"CO2")
  polls = Select(Poll,!=("CO2"))
  for area in areas, poll in polls, ecc in ECCs
    SqPolNet[ecc,poll,area] = SqPolNet[ecc,CO2,area]*SqPOCF[ecc,poll,area]
    SqPolPenalty[ecc,poll,area] = SqPolPenalty[ecc,CO2,area]*SqPOCF[ecc,poll,area]
    SqPol[ecc,poll,area] = SqPol[ecc,CO2,area]*SqPOCF[ecc,poll,area]
  end

  WriteDisk(db,"SOutput/SqPol",year,SqPol)
  WriteDisk(db,"SOutput/SqPolNet",year,SqPolNet)
  WriteDisk(db,"SOutput/SqPolPenalty",year,SqPolPenalty)

  #
  ##########################
  #
  #  Captured CO2 for EOR in Light Oil Mining
  #
  for area in areas
    EORCO2[area] = sum(-SqPol[ecc,CO2,area]*EORFraction[ecc,area] for ecc in ECCs)
  end

  ecc = Select(ECC,"LightOilMining")
  process = Select(Process,"LightOilMining")
  for area in areas
    OAPrEOR[process,area] = min(EORCO2[area],EORLimit[area])*EORRate[area]
    EORCredits[ecc,CO2,area] = EORCO2[area]*EORCreditMultiplier[ecc,area]
  end

  WriteDisk(db,"SOutput/EORCredits",year,EORCredits)
  WriteDisk(db,"SOutput/OAPrEOR",year,OAPrEOR)

  #
  ##########################
  #
  # Sequestering O&M Costs (SqOMExp) are normally a function of
  # Embedded Capital Costs (SqCCEm); however, since the retirement
  # rate is set to zero (by setting SqPL=0), the Embedded Capital
  # Cost is reduced due to inflation casusing O&M Costs to be
  # reduced.  To remedy use the Capital Cost (SqCC) when the
  # retirement rate is zero.  Jeff Amlin 1/15/14
  #
  for area in areas, ecc in ECCs
    @finite_math SqCCEm[ecc,area] = (SqCCEmPrior[ecc,area]*SqCapPrior[ecc,area]+
                 SqCC[ecc,area]*SqCapCR[ecc,area])/SqCap[ecc,area]
  end

  WriteDisk(db,"MEOutput/SqCCEm",year,SqCCEm)


  for area in areas, ecc in ECCs
    if SqPL[area] != 0
      SqOMExp[ecc,area] = SqCap[ecc,area]*SqCCEm[ecc,area]*SqOCF[ecc,area]/1e6
    else
      SqOMExp[ecc,area] = SqCap[ecc,area]*SqCC[ecc,area]*SqOCF[ecc,area]/1e6
    end
  end
  WriteDisk(db,"SOutput/SqOMExp",year,SqOMExp)

  #
  # Sequestering Investments
  #
  for area in areas, ecc in ECCs
    SqInv[ecc,area] = SqCapCR[ecc,area]*SqCC[ecc,area]/1e6
  end
  WriteDisk(db,"SOutput/SqInv",year,SqInv)

  #
  #  Sequestering Private Expenditures
  #
  for area in areas, ecc in ECCs
    SqPExp[ecc,area] = SqInv[ecc,area]*(1-SqGFr[area])+SqOMExp[ecc,area]
  end
  WriteDisk(db,"SOutput/SqPExp",year,SqPExp)

  #
  #  Sequestering Government Expenditures
  #
  for area in areas, ecc in ECCs
    SqGExp[ecc,area] = SqInv[ecc,area]*SqGFr[area]
  end
  WriteDisk(db,"MEOutput/SqGExp",year,SqGExp)


end

function ProcessReductionPrice(data::Data,areas,nation)
  (; db,year,Yr2013) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls,PCov) = data #sets
  (; MEPrice,PCost,PolConv,ECoverage,PCostExo,Inflation,InflationYr,FPCFSObligated,MEPriceSw,eCO2PriceExo,eCO2Price,xMEPrice) = data

  # @info "  MPollution.jl - Reductions - ProcessReductionPrice"

  if MEPriceSw == 1
    pcov = Select(PCov,"Process")
    for area in areas, poll in Polls, ecc in ECCs
      @finite_math MEPrice[ecc,poll,area] = (PCost[ecc,poll,area]*PolConv[poll]*ECoverage[ecc,poll,pcov,area]+
                              PCostExo[ecc,poll,area])*InflationYr[area,Yr2013]+
                              FPCFSObligated[ecc,area]/Inflation[area]*InflationYr[area,Yr2013]
    end
  elseif MEPriceSw == 2
    for area in areas, poll in Polls, ecc in ECCs
      @finite_math MEPrice[ecc,poll,area] = (eCO2Price[area]/Inflation[area]+
                              eCO2PriceExo[area])*InflationYr[area,Yr2013]
    end
  elseif MEPriceSw == 3
    for area in areas, poll in Polls, ecc in ECCs
      MEPrice[ecc,poll,area] = xMEPrice[ecc,poll,area]*InflationYr[area,Yr2013]
    end
  end

  WriteDisk(db,"MEOutput/MEPrice",year,MEPrice)

end

function ProcessEmissionReductions(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; MEPrice,MERP,MEC0,MEA0,MEPrice,MEB0,MEReduce,MEPOCX,MEDriver) = data

  # @info "  MPollution.jl - Reductions - ProcessEmissionReductions"

  for area in areas, poll in Polls, ecc in ECCs
    @finite_math MERP[ecc,poll,area] = MEC0[ecc,poll,area]/(1+MEA0[ecc,poll,area]*
    MEPrice[ecc,poll,area]^MEB0[ecc,poll,area])*MEPrice[ecc,poll,area]/MEPrice[ecc,poll,area]
    
    MEReduce[ecc,poll,area] = max(MEPOCX[ecc,poll,area]*MEDriver[ecc,area]*MERP[ecc,poll,area],
                                MEReduce[ecc,poll,area])
  end

  WriteDisk(db,"MEOutput/MERP",year,MERP)
  WriteDisk(db,"SOutput/MEReduce",year,MEReduce)

end

function VentingReductionPrice(data::Data,areas,nation)
  (; db,year,Yr2020) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls,PCov) = data #sets
  (; ANMap,VnPrice,PCost,PolConv,ECoverage,PCostExo,Inflation,InflationYr) = data
  (; FPCFSObligated,VnPriceSw,eCO2PriceExo,eCO2Price,xVnPrice) = data

  # @info "  MPollution.jl - Reductions - VentingReductionPrice"

  if VnPriceSw == 1
    for area in areas, ecc in ECCs
      pcov = Select(PCov,"Venting")
      CH4 = Select(Poll,"CH4")
      @finite_math VnPrice[ecc,area] = (PCost[ecc,CH4,area]*PolConv[CH4]*ECoverage[ecc,CH4,pcov,area]+
                        PCostExo[ecc,CH4,area])+
                        FPCFSObligated[ecc,area]/Inflation[area]*InflationYr[area,Yr2020]
    end
  elseif VnPriceSw == 2
    for area in areas, ecc in ECCs
      @finite_math VnPrice[ecc,area] = (eCO2Price[area]/Inflation[area]+eCO2PriceExo[area])*InflationYr[area,Yr2020]
    end
  else
    for area in areas, ecc in ECCs
      VnPrice[ecc,area] = xVnPrice[ecc,area]*InflationYr[area,Yr2020]
    end
  end

  WriteDisk(db,"MEOutput/VnPrice",year,VnPrice)

end

function VentingReduced(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; VnPOCX,VnRP,VnPOCXMult,MEDriver,xVnPol,VnPolSwitch,VnReduce,VnC0,VnB0,VnA0,VnPrice,VnPOCF) = data
  (; VnReduceEndogenous,VnReduceRegulations,VnReduceExogenous) = data

  # @info "  MPollution.jl - Reductions - VentingReduced"

  CH4 = Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    if VnPrice[ecc,area] != 0
      @finite_math VnRP[ecc,CH4,area] = VnC0[ecc,area]/(1+VnA0[ecc,area]*
                    VnPrice[ecc,area]^VnB0[ecc,area])
    else 
      VnRP[ecc,CH4,area] = 0
    end
  end

  for area in areas, ecc in ECCs
    VnReduceEndogenous[ecc,CH4,area] = VnPOCX[ecc,CH4,area]*VnRP[ecc,CH4,area]*MEDriver[ecc,area]
  end

  polls = Select(Poll,!=("CH4"))
  for area in areas, poll in polls, ecc in ECCs
    VnReduceEndogenous[ecc,poll,area] = VnReduceEndogenous[ecc,CH4,area]*VnPOCF[ecc,poll,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    VnReduceRegulations[ecc,poll,area] = VnPOCX[ecc,poll,area]*
      (1-VnPOCXMult[ecc,poll,area])*MEDriver[ecc,area]
    #
    VnReduceExogenous[ecc,poll,area] = VnPOCX[ecc,poll,area]*MEDriver[ecc,area]-xVnPol[ecc,poll,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    if VnPolSwitch[ecc,poll,area] == 2
      VnReduce[ecc,poll,area] = VnReduceRegulations[ecc,poll,area]
    elseif VnPolSwitch[ecc,poll,area] == 1
      VnReduce[ecc,poll,area] = VnReduceEndogenous[ecc,poll,area]
    elseif VnPolSwitch[ecc,poll,area] == 0
      VnReduce[ecc,poll,area] = VnReduceExogenous[ecc,poll,area]
    end
  end

  WriteDisk(db,"MEOutput/VnRP",year,VnRP)
  WriteDisk(db,"SOutput/VnReduce",year,VnReduce)

end

function VentingCH4Captured(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; VnCH4Captured,VnReduce,VnCH4CapturedFraction,TBtuGasPerTonneCH4,VnC2H6PerCH4,VnGAProd,VnGProd,ANMap) = data

  # @info "  MPollution.jl - Reductions - VentingCH4Captured"

  CH4 =  Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    VnCH4Captured[ecc,area] = VnReduce[ecc,CH4,area]*VnCH4CapturedFraction[ecc,area]
    #
    VnGAProd[ecc,area] = VnCH4Captured[ecc,area]*TBtuGasPerTonneCH4*(1+VnC2H6PerCH4[ecc,area])

  end

  for nation in nation
    VnGProd[nation] = sum(VnGAProd[ecc,area]*ANMap[area,nation] for area in areas, ecc in ECCs)
  end

  WriteDisk(db,"MEOutput/VnCH4Captured",year,VnCH4Captured)
  WriteDisk(db,"SOutput/VnGAProd",year,VnGAProd)
  WriteDisk(db,"SOutput/VnGProd",year,VnGProd)

end

function VentingEmissionsFromFlaringCH4(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; VnCH4Flared,VnCH4Captured,VnReduce,VnCH4FlPol,VnCH4Flared,VnCH4FlaredPOCF) = data

  # @info "  MPollution.jl - Reductions - VentingEmissionsFromFlaringCH4"

  CH4 = Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    VnCH4Flared[ecc,area] = VnReduce[ecc,CH4,area]-VnCH4Captured[ecc,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    VnCH4FlPol[ecc,poll,area] = VnCH4Flared[ecc,area]*VnCH4FlaredPOCF[ecc,poll,area]
  end

  WriteDisk(db,"MEOutput/VnCH4Flared",year,VnCH4Flared)
  WriteDisk(db,"MEOutput/VnCH4FlPol",year,VnCH4FlPol)

end

function VentingReductionCapacity(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; VnCR,VnCapPrior,VnReduce,VnPL,VnCap) = data

  # @info "  MPollution.jl - Reductions - VentingReductionCapacity"

  #
  # Venting Reductions Capacity Completion Rate is emissions
  # reduced (VnReduce) minus existing capacity (VnCap) plus
  # retirements (VnCap/VnPL).
  #

  CH4 =  Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    @finite_math VnCR[ecc,area] = max(VnReduce[ecc,CH4,area]-VnCapPrior[ecc,area]+VnCapPrior[ecc,area]/VnPL[ecc,area],0)
  end

  #
  #  Venting Reductions Capacity
  #
  for area in areas, ecc in ECCs
    @finite_math VnCap[ecc,area] = VnCapPrior[ecc,area]+DT*(VnCR[ecc,area]-VnCapPrior[ecc,area]/VnPL[ecc,area])
  end

  WriteDisk(db,"MEOutput/VnCR",year,VnCR)
  WriteDisk(db,"MEOutput/VnCap",year,VnCap)

end

function VentingReductionCosts(data::Data,areas,nation)
  (; db,year,Yr2020) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; VnCC,VnCCC0,VnCCA0,VnPrice,VnCCB0,Inflation,InflationYr,VnCCEm,VnCCEmPrior,VnCapPrior,VnCR,VnInv,VnOMExp,VnOCF,VnPExp,VnGFr,VnGExp,VnCosts,VnCap,MECCR,MEDriver) = data

  # @info "  MPollution.jl - Reductions - VentingReductionCapacity"

  for area in areas, ecc in ECCs
  #
  #  Capital Costs curve is in 2012 CN$
  #
    @finite_math VnCC[ecc,area] = VnCCC0[ecc,area]/(1+VnCCA0[ecc,area]*VnPrice[ecc,area]^VnCCB0[ecc,area])*VnPrice[ecc,area]/VnPrice[ecc,area]
    VnCC[ecc,area] = VnCC[ecc,area]/InflationYr[area,Yr2020]*Inflation[area]

    #
    # Venting Reductions Embedded Capital Costs
    #
    @finite_math VnCCEm[ecc,area] = (VnCCEmPrior[ecc,area]*VnCapPrior[ecc,area]+VnCC[ecc,area]*VnCR[ecc,area])/(VnCapPrior[ecc,area]+VnCR[ecc,area])

    #
    # Venting Reductions Private Expenses
    #
    VnInv[ecc,area] = VnCR[ecc,area]*VnCC[ecc,area]/1e6
    VnOMExp[ecc,area] = VnCap[ecc,area]*VnCCEm[ecc,area]*VnOCF[ecc,area]/1e6
    VnPExp[ecc,area] = VnInv[ecc,area]*(1-VnGFr[ecc,area])+VnOMExp[ecc,area]

    #
    # Venting Reductions Government Expenses
    #
    VnGExp[ecc,area] = VnCR[ecc,area]*VnCC[ecc,area]*VnGFr[ecc,area]/1e6

  end

  WriteDisk(db,"MEOutput/VnCC",year,VnCC)
  WriteDisk(db,"MEOutput/VnCCEm",year,VnCCEm)
  WriteDisk(db,"SOutput/VnInv",year,VnInv)
  WriteDisk(db,"SOutput/VnOMExp",year,VnOMExp)
  WriteDisk(db,"SOutput/VnPExp",year,VnPExp)
  WriteDisk(db,"MEOutput/VnGExp",year,VnGExp)

  #
  # Venting Reductions Costs
  #
  for area in areas, ecc in ECCs
    @finite_math VnCosts[ecc,area] = VnCap[ecc,area]*VnCCEm[ecc,area]*
      (MECCR[ecc,area]+VnOCF[ecc,area])/(MEDriver[ecc,area]*1000000)
  end

  WriteDisk(db,"SOutput/VnCosts",year,VnCosts)

end

function VentingReductions(data::Data,areas,nation)

  # @info "  MPollution.jl - Reductions - VentingReductions"

  VentingReductionPrice(data,areas,nation)
  VentingReduced(data,areas,nation)
  VentingCH4Captured(data,areas,nation)
  VentingEmissionsFromFlaringCH4(data,areas,nation)
  VentingReductionCapacity(data,areas,nation)
  VentingReductionCosts(data,areas,nation)

end

function VentingEmissions(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Polls) = data
  (; MEDriver,VnPOCX,VnPol,VnReduce) = data
  
  for area in Areas,poll in Polls,ecc in ECCs
    VnPol[ecc,poll,area] = VnPOCX[ecc,poll,area]*MEDriver[ecc,area]-VnReduce[ecc,poll,area]
  end
  
  WriteDisk(db,"SOutput/VnPol",year,VnPol)

end

function FugitivesReductionPrice(data::Data,areas,nation)
  (; db,year,Yr2020) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls,PCov) = data #sets
  (; FuPrice,PCost,PolConv,ECoverage,PCostExo,Inflation,InflationYr) = data
  (; FPCFSObligated,FuPriceSw,eCO2PriceExo,eCO2Price,xFuPrice) = data

  # @info "  MPollution.jl - Reductions - FugitivesReductionPrice"

  if FuPriceSw == 1
    for area in areas, ecc in ECCs
      pcov = Select(PCov,"Venting")
      CH4 = Select(Poll,"CH4")
      @finite_math FuPrice[ecc,area] = (PCost[ecc,CH4,area]*PolConv[CH4]*ECoverage[ecc,CH4,pcov,area]+
                        PCostExo[ecc,CH4,area])+
                        FPCFSObligated[ecc,area]/Inflation[area]*InflationYr[area,Yr2020]
    end
  elseif FuPriceSw == 2
    for area in areas, ecc in ECCs
      @finite_math FuPrice[ecc,area] = (eCO2Price[area]/Inflation[area]+eCO2PriceExo[area])*InflationYr[area,Yr2020]
    end
  else
    for area in areas, ecc in ECCs
      FuPrice[ecc,area] = xFuPrice[ecc,area]*InflationYr[area,Yr2020]
    end
  end

  WriteDisk(db,"MEOutput/FuPrice",year,FuPrice)

end

function FugitivesReduced(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FuPOCX,FuRP,FuPOCXMult,MEDriver,MERP,xFuPol,FuPolSwitch,FuReduce,FuC0,FuB0,FuA0,FuPrice,FuPOCF) = data
  (; FuReduceEndogenous,FuReduceRegulations,FuReduceExogenous) = data

  # @info "  MPollution.jl - Reductions - FugitivesReduced"

  CH4 = Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    @finite_math FuRP[ecc,CH4,area] = FuC0[ecc,area]/(1+FuA0[ecc,area]*FuPrice[ecc,area]^FuB0[ecc,area])*FuPrice[ecc,area]/FuPrice[ecc,area]
  end

  ecc = Select(ECC,"CoalMining")
  for area in areas, poll in Polls
    FuRP[ecc,poll,area] = MERP[ecc,poll,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    FuReduceEndogenous[ecc,poll,area] = FuPOCX[ecc,poll,area]*FuRP[ecc,poll,area]*MEDriver[ecc,area]
  end

  polls = Select(Poll,!=("CH4"))
  for area in areas, poll in polls, ecc in ECCs
    FuReduceEndogenous[ecc,poll,area] = FuReduceEndogenous[ecc,CH4,area]*FuPOCF[ecc,poll,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    FuReduceRegulations[ecc,poll,area] = FuPOCX[ecc,poll,area]*(1-FuPOCXMult[ecc,poll,area])*MEDriver[ecc,area]
    #
    FuReduceExogenous[ecc,poll,area] = FuPOCX[ecc,poll,area]*MEDriver[ecc,area]-xFuPol[ecc,poll,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    if FuPolSwitch[ecc,poll,area] == 2
      FuReduce[ecc,poll,area] = FuReduceRegulations[ecc,poll,area]
    elseif FuPolSwitch[ecc,poll,area] == 1
      FuReduce[ecc,poll,area] = FuReduceEndogenous[ecc,poll,area]
    elseif FuPolSwitch[ecc,poll,area] == 0
      FuReduce[ecc,poll,area] = FuReduceExogenous[ecc,poll,area]
    end
  end

  WriteDisk(db,"MEOutput/FuRP",year,FuRP)
  WriteDisk(db,"SOutput/FuReduce",year,FuReduce)

end

function FugitivesCH4Captured(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FuCH4Captured,FuReduce,FuCH4CapturedFraction,TBtuGasPerTonneCH4,FuC2H6PerCH4,FuGAProd,FuGProd,ANMap) = data

  # @info "  MPollution.jl - Reductions - FugitivesCH4Captured"

  CH4 = Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    FuCH4Captured[ecc,area] = FuReduce[ecc,CH4,area]*FuCH4CapturedFraction[ecc,area]
    #
    FuGAProd[ecc,area] = FuCH4Captured[ecc,area]*TBtuGasPerTonneCH4*(1+FuC2H6PerCH4[ecc,area])

  end

  for nation in nation
    FuGProd[nation] = sum(FuGAProd[ecc,area]*ANMap[area,nation] for area in areas, ecc in ECCs)
  end

  WriteDisk(db,"MEOutput/FuCH4Captured",year,FuCH4Captured)
  WriteDisk(db,"SOutput/FuGAProd",year,FuGAProd)
  WriteDisk(db,"SOutput/FuGProd",year,FuGProd)

end

function FugitivesEmissionsFromFlaringCH4(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FuCH4Flared,FuCH4Captured,FuReduce,FuCH4FlPol,FuCH4Flared,FuCH4FlaredPOCF) = data

  # @info "  MPollution.jl - Reductions - FugitivesEmissionsFromFlaringCH4"

  CH4 = Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    FuCH4Flared[ecc,area] = FuReduce[ecc,CH4,area]-FuCH4Captured[ecc,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    FuCH4FlPol[ecc,poll,area] = FuCH4Flared[ecc,area]*FuCH4FlaredPOCF[ecc,poll,area]
  end

  WriteDisk(db,"MEOutput/FuCH4Flared",year,FuCH4Flared)
  WriteDisk(db,"MEOutput/FuCH4FlPol",year,FuCH4FlPol)

end

function FugitivesReductionCapacity(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FuCR,FuCapPrior,FuReduce,FuPL,FuCap) = data

  # @info "  MPollution.jl - Reductions - FugitivesReductionCapacity"

  #
  # Fugitives Reduction Capacity Completion Rate is emissions
  # reduced (FuReduce) minus existing capacity (FuCap) plus
  # retirements (FuCap/FuPL).
  #

  CH4 = Select(Poll,"CH4")
  for area in areas, ecc in ECCs
    @finite_math FuCR[ecc,area] = max(FuReduce[ecc,CH4,area]-FuCapPrior[ecc,area]+FuCapPrior[ecc,area]/FuPL[ecc,area],0)
  end

  #
  #  Fugitives Reductions Capacity
  #
  for area in areas, ecc in ECCs
    @finite_math FuCap[ecc,area] = FuCapPrior[ecc,area]+DT*(FuCR[ecc,area]-FuCapPrior[ecc,area]/FuPL[ecc,area])
  end

  WriteDisk(db,"MEOutput/FuCR",year,FuCR)
  WriteDisk(db,"MEOutput/FuCap",year,FuCap)

end

function FugitivesReductionCosts(data::Data,areas,nation)
  (; db,year,Yr2020) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FuCC,FuCCC0,FuCCA0,FuPrice,FuCCB0,Inflation,InflationYr,FuCCEm,FuCCEmPrior,FuCapPrior,FuCR,FuInv,FuOMExp,FuOCF,FuPExp,FuGFr,FuGExp,FuCosts,FuCap,MECCR,MEDriver) = data

  # @info "  MPollution.jl - Reductions - FugitivesReductionCosts"

  for area in areas, ecc in ECCs
  #
  #  Capital Costs curve is in 2012 CN$
  #
    @finite_math FuCC[ecc,area] = FuCCC0[ecc,area]/(1+FuCCA0[ecc,area]*FuPrice[ecc,area]^FuCCB0[ecc,area])*FuPrice[ecc,area]/FuPrice[ecc,area]
    FuCC[ecc,area] = FuCC[ecc,area]/InflationYr[area,Yr2020]*Inflation[area]

    #
    # Fugitives Reductions Embedded Capital Costs
    #
    @finite_math FuCCEm[ecc,area] = (FuCCEmPrior[ecc,area]*FuCapPrior[ecc,area]+FuCC[ecc,area]*FuCR[ecc,area])/(FuCapPrior[ecc,area]+FuCR[ecc,area])

    #
    # Fugitives Reductions Private Expenses
    #
    FuInv[ecc,area] = FuCR[ecc,area]*FuCC[ecc,area]/1e6
    FuOMExp[ecc,area] = FuCap[ecc,area]*FuCCEm[ecc,area]*FuOCF[ecc,area]/1e6
    FuPExp[ecc,area] = FuInv[ecc,area]*(1-FuGFr[ecc,area])+FuOMExp[ecc,area]

    #
    # Fugitives Reductions Government Expenses
    #
    FuGExp[ecc,area] = FuCR[ecc,area]*FuCC[ecc,area]*FuGFr[ecc,area]/1e6

  end

  WriteDisk(db,"MEOutput/FuCC",year,FuCC)
  WriteDisk(db,"MEOutput/FuCCEm",year,FuCCEm)
  WriteDisk(db,"SOutput/FuInv",year,FuInv)
  WriteDisk(db,"SOutput/FuOMExp",year,FuOMExp)
  WriteDisk(db,"SOutput/FuPExp",year,FuPExp)
  WriteDisk(db,"MEOutput/FuGExp",year,FuGExp)

  #
  # Fugitives Reductions Costs
  #
  for area in areas, ecc in ECCs
    @finite_math FuCosts[ecc,area] = FuCap[ecc,area]*FuCCEm[ecc,area]*(MECCR[ecc,area]+FuOCF[ecc,area])/(MEDriver[ecc,area]*1000000)
  end

  WriteDisk(db,"SOutput/FuCosts",year,FuCosts)

end

function OtherFugitivesReductions(data::Data,areas,nation)

  # @info "  MPollution.jl - Reductions - OtherFugitivesReductions"

  FugitivesReductionPrice(data,areas,nation)
  FugitivesReduced(data,areas,nation)
  FugitivesCH4Captured(data,areas,nation)
  FugitivesEmissionsFromFlaringCH4(data,areas,nation)
  FugitivesReductionCapacity(data,areas,nation)
  FugitivesReductionCosts(data,areas,nation)

end

function FugitivesEmissions(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Polls) = data
  (; FuPOCX,FuPol,FuReduce,MEDriver) = data
  
  for area in Areas,poll in Polls,ecc in ECCs
    FuPol[ecc,poll,area] = FuPOCX[ecc,poll,area]*MEDriver[ecc,area]-FuReduce[ecc,poll,area]
  end
  
  WriteDisk(db,"SOutput/FuPol",year,FuPol)

end

function FlaringReduced(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FlPOCX,FlRP,FlPOCXMult,MEDriver,xFlPol,FlPolSwitch,FlReduce) = data
  (; FlReduceEndogenous,FlReduceRegulations,FlReduceExogenous) = data

  # @info "  MPollution.jl - Reductions - FlaringReduced"

  for area in areas, poll in Polls, ecc in ECCs
    # 23.08.21, LJD: The Promula code had a mysterious "*" at the end of this equation
    # FlReduceEndogenous=FlPOCX*FlRP*
    FlReduceEndogenous[ecc,poll,area] = FlPOCX[ecc,poll,area]*FlRP[ecc,poll,area]
    FlReduceRegulations[ecc,poll,area] = FlPOCX[ecc,poll,area]*(1-FlPOCXMult[ecc,poll,area])*MEDriver[ecc,area]
    FlReduceExogenous[ecc,poll,area] = FlPOCX[ecc,poll,area]*MEDriver[ecc,area]-xFlPol[ecc,poll,area]
  end

  for area in areas, poll in Polls, ecc in ECCs
    if FlPolSwitch[ecc,poll,area] == 2
      FlReduce[ecc,poll,area] = FlReduceRegulations[ecc,poll,area]
    elseif FlPolSwitch[ecc,poll,area] == 1
      FlReduce[ecc,poll,area] = FlReduceEndogenous[ecc,poll,area]
    elseif FlPolSwitch[ecc,poll,area] == 0
      FlReduce[ecc,poll,area] = FlReduceExogenous[ecc,poll,area]
    end
  end

  WriteDisk(db,"SOutput/FlReduce",year,FlReduce)

end

function FlaringCH4Captured(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FlCH4Captured,FlReduce,FlCH4CapturedFraction,TBtuGasPerTonneCH4,FlC2H6PerCH4,FlGProd,FlGAProd,ANMap) = data

  # @info "  MPollution.jl - Reductions - FlaringCH4Captured"

  CO2 = Select(Poll,"CO2")
  for area in areas, ecc in ECCs
    FlCH4Captured[ecc,area] = FlReduce[ecc,CO2,area]*FlCH4CapturedFraction[ecc,area]

    FlGAProd[ecc,area] = FlCH4Captured[ecc,area]*TBtuGasPerTonneCH4*(1+FlC2H6PerCH4[ecc,area])

  end

  for nation in nation
    FlGProd[nation] = sum(FlGAProd[ecc,area]*ANMap[area,nation] for area in areas, ecc in ECCs)
  end

  WriteDisk(db,"MEOutput/FlCH4Captured",year,FlCH4Captured)
  WriteDisk(db,"SOutput/FlGAProd",year,FlGAProd)
  WriteDisk(db,"SOutput/FlGProd",year,FlGProd)

end

function FlaringReductionCosts(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation,Poll,Polls) = data #sets
  (; FlInv,FlReduce,FlCC,Inflation,FlPExp,FlCosts,MEDriver) = data

  # @info "  MPollution.jl - Reductions - FlaringReductionCosts"

  #
  # Flaring Reductions Expenses
  #

  CO2 = Select(Poll,"CO2")
  for area in areas, ecc in ECCs
    FlInv[ecc,area] = FlReduce[ecc,CO2,area]*FlCC[ecc,area]*Inflation[area]/1e6
  end

  WriteDisk(db,"SOutput/FlInv",year,FlInv)

  for area in areas, ecc in ECCs
    FlPExp[ecc,area] = FlInv[ecc,area]
  end

  WriteDisk(db,"SOutput/FlPExp",year,FlPExp)


  for area in areas, ecc in ECCs
    @finite_math FlCosts[ecc,area] = FlInv[ecc,area]/(MEDriver[ecc,area]*1000000)
  end

  WriteDisk(db,"SOutput/FlCosts",year,FlCosts)

end

function FlaringReductions(data::Data,areas,nation)

  # @info "  MPollution.jl - Reductions - FlaringReductions"

  FlaringReduced(data,areas,nation)
  FlaringCH4Captured(data,areas,nation)
  FlaringReductionCosts(data,areas,nation)

end

function FlaringEmissions(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Polls) = data
  (; FlPOCX,FlPol,FlReduce,MEDriver) = data
  
  for area in Areas,poll in Polls,ecc in ECCs
    FlPol[ecc,poll,area] = FlPOCX[ecc,poll,area]*MEDriver[ecc,area]-FlReduce[ecc,poll,area]
  end
  
  WriteDisk(db,"SOutput/FlPol",year,FlPol)

end

function EmissionReductionCapitalChargeRate(data::Data,areas,nation)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Nation) = data #sets
  (; MECCR,MEIVTC,MEROIN,InSm,METxRt,METL,MEPL) = data

  # @info "  MPollution.jl - EmissionReductionCapitalChargeRate"

  for area in areas, ecc in ECCs
    @finite_math MECCR[ecc,area] = (1-MEIVTC[ecc,area]/(1+MEROIN[ecc,area]+InSm[area])-METxRt[ecc,area]*(2/METL[ecc,area])/
                    (MEROIN[ecc,area]+InSm[area]+2/METL[ecc,area]))*MEROIN[ecc,area]/
                    (1-(1/(1+MEROIN[ecc,area]))^MEPL[ecc,area])/(1-METxRt[ecc,area])
  end

  WriteDisk(db,"MEOutput/MECCR",year,MECCR)

end

function PRReductions(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Market,PCov,Poll,Polls) = data #sets
  (; AreaMarket,CapTrade,ECCMarket,ECoverage,Inf00,Inflation,MECCR) = data 
  (; MEIRP,MEPCstN,MEPOCS,MEPOCX,MEPVF,MERCA0,MERCB0) = data
  (; MERCC,MERCC0,MERCD,MERCPL,MERCstM,MERCSw,MERM) = data
  (; MEROCF,MERP,MERPPrior,MEVR,MEVRP,MEVRPrior,MEVRRT) = data
  (; PCost,PCostExo,PolConv,PollMarket,RPolicy,xMERM) = data
  (; MERPStd,RPFull) = data
 
  # @info "  MPollution.jl - Reductions - PRReductions"

  #
  # Reduction Policy (CAC only)
  #
  MERM .= 1.0
  CACPolls = Select(Poll,["SOX","COX","NOX","PMT","VOC","PM25","PM10","Hg","NH3","BC"])

  #
  # Voluntary reductions:based on exogenous goal and time lag.
  #
  for area in Areas, poll in CACPolls, ecc in ECCs
    @finite_math MEVR[ecc,poll,area] = MEVRPrior[ecc,poll,area]+DT*(MEVRP[ecc,poll,area]-MEVR[ecc,poll,area])/MEVRRT[ecc]
  end

  #
  # This section is all based on the process coverage (PCov=3)
  #
  pcov = Select(PCov,"Process")

  #
  # Reduction from Emissions Standard - the xmax and xmin functions are to
  # give MERPStd a correct value even when MEPOCX is negative (Solid Waste)
  # or if MEPOCS is extremely high (no contraint) which is the default value.
  # Jeff Amlin 12/03/09.
  #
  for area in Areas, poll in CACPolls, ecc in ECCs
    @finite_math MERPStd[ecc,poll,area] = min( max(1 - MEPOCS[ecc,poll,area]/max(MEPOCX[ecc,poll,area],abs(MEPOCX[ecc,poll,area]/1e6)),0),1)*MEPOCX[ecc,poll,area]/MEPOCX[ecc,poll,area]
  end

  #
  # Reductions (MERP) are set equal to reductions from the standard (MERPStd) in the
  # case where the emissions are not covered by a "market".  Jeff Amlin 11/27/09
  #
  for area in Areas, poll in CACPolls, ecc in ECCs
    MERP[ecc,poll,area] = MERPStd[ecc,poll,area]
  end

  #
  # If system has an emission Cap and emissions Trading (CapTrade = 1 or 3),
  # then the input is the permit cost (PCost).
  #
  for market in Select(Market)
    areas = findall(AreaMarket[:,market] .== 1)
    eccs = findall(ECCMarket[:,market] .== 1)
    CACPolls = Select(Poll,["SOX","COX","NOX","PMT","VOC","PM25","PM10","Hg","NH3","BC"])
    MarketPolls = findall(PollMarket[:,market] .== 1)
    polls = intersect(CACPolls,MarketPolls)
    
    #
    #    Do if policy is a cap with trading (CapTrade = 1)
    #
    if (CapTrade[market] == 1) || (CapTrade[market] == 3) || (CapTrade[market] == 5)
      #
      # Capital cost of reduction technology based on the permit cost (PCost)
      #
      for area in areas, poll in polls, ecc in eccs
        @finite_math MERCC[ecc,poll,area] = (PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]+
           PCostExo[ecc,poll,area])/(MECCR[ecc,area]+MEROCF[ecc,poll])*Inflation[area]
        #
        # The indicated reductions (MEIRP) are a function of the permit cost
        # (PCost) and the Pollution reduction curve parameters (MEPCstN, MEPVF)
        # adjusted by the reductions cost multiplier (MERCstM).
        #
        # CAC Reduction Curves from 2009
        #
        if MERCSw[ecc,poll,area] == 1
          if ((PCost[ecc,poll,area] != 0) || (PCostExo[ecc,poll,area] != 0)) && (MEPCstN[ecc,poll,area] != 0) && (MEPVF[ecc,poll,area] != 0)
            @finite_math MEIRP[ecc,poll,area] = log(MERCC[ecc,poll,area]/Inflation[area]/
              (MEPCstN[ecc,poll,area]/MERCstM[ecc,poll]))/MEPVF[ecc,poll,area]*
              ECoverage[ecc,poll,pcov,area]
          end
        #
        # GHG Reduction Curves
        #
        elseif MERCSw[ecc,poll,area] == 2
          if (PCost[ecc,poll,area] >= 0) || (PCostExo[ecc,poll,area] >= 0)
            @finite_math MEIRP[ecc,poll,area] = MERCC0[ecc,poll,area]/(1+MERCA0[ecc,poll,area]*
               max((PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]*PolConv[poll]+PCostExo[ecc,poll,area])/
               Inflation[area]*Inf00[area],0.01)^MERCB0[ecc,poll,area])
          end
        #
        # CAC Reduction Curves from 2006
        #
        elseif MERCSw[ecc,poll,area] == 3
          if ((PCost[ecc,poll,area] != 0) || (PCostExo[ecc,poll,area] != 0)) && (MEPCstN[ecc,poll,area] != 0) && (MEPVF[ecc,poll,area] != 0)
            @finite_math MEIRP[ecc,poll,area] = 1/(1+((max(PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]+PCostExo[ecc,poll,area],0.01)*
                                              MERCstM[ecc,poll])/MEPCstN[ecc,poll,area])^MEPVF[ecc,poll,area])
          end
        end #MERCSw

        #
        # Indicated reduction (MEIRP) must be at least equal to the reduction
        # from the emissions standard (MERPStd)
        #
        MEIRP[ecc,poll,area] = max(MEIRP[ecc,poll,area],MERPStd[ecc,poll,area])

        #
        # Actual Reductions (MERP) are increased by changes in Indicated
        # Reductions (MEIRP) and the construction time (MERCD)
        # and reduced by the physical lifetime (MERCPL).
        #
        @finite_math MERP[ecc,poll,area] = MERPPrior[ecc,poll,area]+max(MEIRP[ecc,poll,area]-MERPPrior[ecc,poll,area],0)/MERCD[ecc,poll]-MERPPrior[ecc,poll,area]/MERCPL[ecc,poll]

        #
        # Capital cost of reduction technology based on the permit cost (PCost)
        #
        @finite_math MERCC[ecc,poll,area] = (PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]+
          PCostExo[ecc,poll,area])/(MECCR[ecc,area]+MEROCF[ecc,poll])*Inflation[area]

      end #area, poll, ecc
    #
    # If system has emissions Cap, but no emissions Trading (CapTrade = 2),
    # then input is the actual reduction (RPolicy)
    #
    elseif (CapTrade[market] == 2) || (CapTrade[market] == 4)
      for area in areas, poll in polls, ecc in eccs
        #
        # Pollution Reduction (MERP) is the maximum of the reduction
        # policy (RPolicy) and the Pollution standard (1-MEPOCS/MEPOCX)
        # times the coverage of the regulations (ECoverage).
        #
        MERP[ecc,poll,area] = max(RPolicy[ecc,poll,area],MERPStd[ecc,poll,area])*ECoverage[ecc,poll,pcov,area]
        RPFull[ecc,poll,area] = 1-(1-MERP[ecc,poll,area])*xMERM[ecc,poll,area]

        #
        # The capital cost of the reduction technology (MERCC) based on the
        # reduction (MERP) and the Pollution reduction curve parameters
        # (MEPCstN, MEPVF) adjusted by by the reductions cost multiplier
        # (MERCstM).
        #
        # CAC Reduction Curves from 2009
        #
        if MERCSw[ecc,poll,area] == 1
          if (RPFull[ecc,poll,area] >= 0) && (MEPCstN[ecc,poll,area] != 0) && (MEPVF[ecc,poll,area] != 0)
            @finite_math MERCC[ecc,poll,area] = (MEPCstN[ecc,poll,area]/MERCstM[ecc,poll])*
              exp(MEPVF[ecc,poll,area]*RPFull[ecc,poll,area])*Inflation[area]
          end

        #
        # GHG Reduction Curves
        #
        elseif MERCSw[ecc,poll,area] == 2
          if (RPFull[ecc,poll,area] >= 0) && (MERCA0[ecc,poll,area] != 0) && (MERCB0[ecc,poll,area] != 0) && (MERCC0[ecc,poll,area] != 0)
            @finite_math MERCC[ecc,poll,area] = ((MERCC0[ecc,poll,area]/RPFull[ecc,poll,area]-1)/
              MERCA0[ecc,poll,area])^(1/MERCB0[ecc,poll,area])*(MECCR[ecc,area]+
              MEROCF[ecc,poll])*Inflation[area]
          end

        #
        # CAC Reduction Curves from 2006
        #
        elseif MERCSw[ecc,poll,area] == 3
          if (RPFull[ecc,poll,area] != 0) && (MEPCstN[ecc,poll,area] != 0) && (MEPVF[ecc,poll,area] != 0)
            @finite_math MERCC[ecc,poll,area] = (1/RPFull[ecc,poll,area]-1)^(1/MEPVF[ecc,poll,area])*
              MEPCstN[ecc,poll,area]/MERCstM[ecc,poll]/(MECCR[ecc,area]+MEROCF[ecc,poll])*Inflation[area]
          end

        elseif MERCSw[ecc,poll,area] == 4

          if (RPFull[ecc,poll,area] != 0) && (MEPCstN[ecc,poll,area] != 0) && (MEPVF[ecc,poll,area] != 0)
            @finite_math MERCC[ecc,poll,area] = exp((MEPCstN[ecc,poll,area]/MERCstM[ecc,poll])+
              (MEPVF[ecc,poll,area]*log(RPFull[ecc,poll,area])))*Inflation[area]
          end
        end #MERCSw
      end #area
    end #CapTrade
  end #market

  #
  # Reduction in come Pollutants cause reductions in other Pollutants.
  # This relationship is specified in the cross multiplier (CM).
  #
  # ? MERPXP(ECC,P,XP,Area)=MECM(P,XP)*MERP(ECC,P,Area)
  #
  # Find net reduction multiplier (MERM) including the cross impacts (MERPXP)
  # and the volunatry reductions (MEVR).
  #
  # ? MERM(ECC,P,Area)=PRODUCT(XP)(1-MERPXP(ECC,P,XP,Area))*
  # ?                             (1-MEVR(ECC,P,Area))
  #
  # ?? Temporarily leave out cross impacts (MERPXP, MERM omitted from Promula)
  #
  for area in Areas, poll in CACPolls, ecc in ECCs
    MERM[ecc,poll,area] = (1-MERP[ecc,poll,area])*(1-MEVR[ecc,poll,area])*xMERM[ecc,poll,area]
  end

  WriteDisk(db,"MEOutput/MEIRP",year,MEIRP)
  WriteDisk(db,"MEOutput/MERCC",year,MERCC)
  WriteDisk(db,"MEOutput/MERM",year,MERM)
  WriteDisk(db,"MEOutput/MERP",year,MERP)
  WriteDisk(db,"MEOutput/MEVR",year,MEVR)

end

function Reductions(data::Data)
  (; db,year) = data
  (; Nation) = data #sets
  (; ANMap,MEPOCM) = data

  # @info "  MPollution.jl - Reductions"

  #
  # Initializations
  #
  MEPOCM .= 1.0
  WriteDisk(db,"MEOutput/MEPOCM",year,MEPOCM)

  #
  # Reductions are for Canada Only
  #

  for nation in Select(Nation,"CN")
    areas = findall(ANMap[:,nation] .== 1)
    EmissionReductionCapitalChargeRate(data,areas,nation)
    CCSReductions(data,areas,nation)
    ProcessReductionPrice(data,areas,nation)
    ProcessEmissionReductions(data,areas,nation)
    VentingReductions(data,areas,nation)
    OtherFugitivesReductions(data,areas,nation)
    FlaringReductions(data,areas,nation)
  end

  #
  #  Emission Reduction Curves
  #
  PRReductions(data)

end # function Reductions

function PolCoefficients(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Fuel,Fuels,FuelEP,FuelEPs,Poll,Polls) = data #sets
  (; MEPOCA,MEPOCX,MERM,MEPOCM,ORMEPOCA,ORMEPOCX,FuPOCX,FlPOCX,VnPOCX,EnPOCX,BCarbonSw,BCMultProcess,BCMult,FFPMap) = data

  for area in Areas, poll in Polls,ecc in ECCs
    MEPOCA[ecc,poll,area] = MEPOCX[ecc,poll,area]*MERM[ecc,poll,area]*MEPOCM[ecc,poll,area]
  end
  WriteDisk(db,"MEOutput/MEPOCA",year,MEPOCA)

  for area in Areas, poll in Polls,ecc in ECCs
    ORMEPOCA[ecc,poll,area] = ORMEPOCX[ecc,poll,area]
  end
  WriteDisk(db,"MEOutput/ORMEPOCA",year,ORMEPOCA)

  #
  # Black Carbon (BC) is a function of PM 2.5 (PM25).
  #
  if BCarbonSw == 1
    BC = Select(Poll,"BC")
    PM25 = Select(Poll,"PM25")
    for area in Areas,ecc in ECCs
      MEPOCX[ecc,BC,area] = MEPOCX[ecc,PM25,area]  *BCMultProcess[ecc,area]
      MEPOCA[ecc,BC,area] = MEPOCA[ecc,PM25,area]  *BCMultProcess[ecc,area]
      ORMEPOCX[ecc,BC,area] = ORMEPOCX[ecc,PM25,area]*BCMultProcess[ecc,area]
      ORMEPOCA[ecc,BC,area] = ORMEPOCA[ecc,PM25,area]*BCMultProcess[ecc,area]
      FuPOCX[ecc,BC,area] = FuPOCX[ecc,PM25,area]  *BCMultProcess[ecc,area]
      FlPOCX[ecc,BC,area] = FlPOCX[ecc,PM25,area]  *BCMultProcess[ecc,area]
      VnPOCX[ecc,BC,area] = VnPOCX[ecc,PM25,area]  *BCMultProcess[ecc,area]

      for fuel in Fuels, fuelep in FuelEPs
        EnPOCX[fuelep,ecc,BC,area] = EnPOCX[fuelep,ecc,PM25,area]*BCMult[fuelep,ecc,area]*FFPMap[fuelep,fuel]
      end
    end

    WriteDisk(db,"MEOutput/MEPOCA",year,MEPOCA)
    WriteDisk(db,"MEInput/MEPOCX",year,MEPOCX)
    WriteDisk(db,"MEOutput/ORMEPOCA",year,ORMEPOCA)
    WriteDisk(db,"MEInput/ORMEPOCX",year,ORMEPOCX)
    WriteDisk(db,"MEInput/FuPOCX",year,FuPOCX)
    WriteDisk(db,"MEInput/FlPOCX",year,FlPOCX)
    WriteDisk(db,"MEInput/VnPOCX",year,VnPOCX)
    WriteDisk(db,"MEInput/EnPOCX",year,EnPOCX)

  end

end

function ProcessEmissions(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Poll,Polls) = data #sets
  (; MEPol,MEPOCA,MEDriver,MEPolSwitch,xMEPol,ORMEPol,ORMEPOCA,MEReduce,MERP) = data

  #
  # Economic Activity Emissions - the Electric Utility and
  #  Transportation Emissions are computed inside the Sectors.
  #

  for ecc in ECCs
    if                                      (ECC[ecc] != "UtilityGen") &&
      (ECC[ecc] != "Passenger")          && (ECC[ecc] != "Freight") &&
      (ECC[ecc] != "AirPassenger")       && (ECC[ecc] != "AirFreight") &&
      (ECC[ecc] != "ForeignPassenger")   && (ECC[ecc] != "ForeignFreight") &&
      (ECC[ecc] != "ResidentialOffRoad") && (ECC[ecc] != "CommercialOffRoad")
      for area in Areas, poll in Polls
        MEPol[ecc,poll,area] = (MEPOCA[ecc,poll,area]*MEDriver[ecc,area]*MEPolSwitch[ecc,poll,area])+
          (xMEPol[ecc,poll,area]*(1-MEPolSwitch[ecc,poll,area]))
        #
        ORMEPol[ecc,poll,area] = ORMEPOCA[ecc,poll,area]*MEDriver[ecc,area]
      end
    #
    # Else Electric Utility or Transportation Sector
    #
    else
      for area in Areas, poll in Polls
        MEReduce[ecc,poll,area] = MEPol[ecc,poll,area]*MERP[ecc,poll,area]
      end
    end
  end
  #
  # Emission Reductions
  #
  for area in Areas, poll in Polls, ecc in ECCs
    MEPol[ecc,poll,area] = MEPol[ecc,poll,area]-MEReduce[ecc,poll,area]
  end

  WriteDisk(db,"SOutput/MEPol",year,MEPol)
  WriteDisk(db,"SOutput/ORMEPol",year,ORMEPol)
  WriteDisk(db,"SOutput/MEReduce",year,MEReduce)

  # Write Disk(ORMEPol,MEPol,MEReduce)

end

function SolidWasteVeryOldWay(data::Data)
  # 
  #  Solid Waste GHG emissions are embedded (MEPol)
  # 
  # Do If ModSwitch eq "OldWay"
  #   Select Year(Prior)
  #   Read Disk(MWEPol)
  #   Select Year(Current)
  #   Select ECC(SolidWaste), Poll(CO2,CH4,N2O,SF6,PFC,HFC)
  #   MWPolAdd=MEPOCA*MEDriver
  #   MWEPol = MWEPol+DT*(MWPolAdd-MWEPol/MWDecayTime)
  #   MEPol = MWEPol/MWDecayTime
  #   Select ECC*, Poll*
  #   Write Disk(MWEPol,MWPolAdd)
  # End Do If
  # 
  # End Procedure SolidWasteVeryOldWay
  end

function LandUseEmissions(data::Data)
  # Define Procedure LandUseEmissions
  # 
  # Do If ModSwitch eq "Wisconsin"
  #   Select ECC(LandUse)
  # 
  #  Land Use sector for Wisconsin
  # 
  #   LUFr=XLUFr
  # 
  #  Area for each land use (LUArea) is the total land area (LandArea) times
  #  the land use fraction (LUFr).
  # 
  #   LUArea=LandArea*LUFr
  # 
  #  Pollution from each land use (LUPolLU) is the land use area (LUArea) times
  #  the land use pollution coefficient (LUPOCX)
  # 
  #   LUPolLU=LUArea*LUPOCX
  # 
  #  Land use pollution (MEPol) is the sum of emissions from each land use type (LUPolLU).
  # 
  #   MEPol(ECC,Poll,Area)=sum(LU)(LUPolLU(LU,Poll,Area))
  # 
  #   Select ECC*
  # 
  #   Write Disk(LUArea,LUFr,LUPolLU)
  # End Do If ModSwitch
  # 
  # End Define Procedure LandUseEmissions
end

function OtherEnergyEmissions(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,FuelEP,FuelEPs,Poll,Polls) = data #sets
  (; EuFPol,EnPOCX,Driver) = data

  #
  # Solid Waste, Other Waste, Incineration, and Land Use Energy Emissions
  #   

  eccs = Select(ECC,["SolidWaste","Wastewater","Incineration","LandUse",
                     "RoadDust","OpenSources","ForestFires","Biogenics"])
  for area in Areas, poll in Polls, ecc in eccs, fuelep in FuelEPs
    EuFPol[fuelep,ecc,poll,area] = EnPOCX[fuelep,ecc,poll,area]*Driver[ecc,area]
  end

  WriteDisk(db,"SOutput/EuFPol",year,EuFPol)

end

function PRAccounting(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Poll,Polls) = data #sets
  (; MERCapPrior,MERCCEmPrior,MERCRPrior,MERICap,MEPol,MERM,MERP) = data 
  (; MERCI,MERCR,MERCD,MERCPL,MERCCEm,MERCap,PRExp,xPRExp,MERCC) = data 
  (; AGFr,MEROCF,GRExp,PAdCost) = data 

  #
  #  Pollution Reduction Accounting
  #
  for area in Areas, poll in Polls, ecc in ECCs
    #
    #  Pollution Reduction Accounting
    #
    # Indicated Reduction Capacity (RICap) is emissions (MEPol) divided by the reduction
    # multiplier (MERM) which gives back total embodied emissions times the Pollution
    # reduction (MERP) which tells how many Tonnes of Pollution can be reduced.
    #
    @finite_math MERICap[ecc,poll,area] = MEPol[ecc,poll,area]/MERM[ecc,poll,area]*MERP[ecc,poll,area]

    #
    # Reduction Capacity Initiation Rate
    #
    @finite_math MERCI[ecc,poll,area] = max(0,MERICap[ecc,poll,area]-MERCapPrior[ecc,poll,area]-
      MERCRPrior[ecc,poll,area]*MERCD[ecc,poll]+MERCapPrior[ecc,poll,area]/MERCPL[ecc,poll])/
      MERCD[ecc,poll]

    #
    # Embedded Reduction Capital Costs
    #
    MERCCEm[ecc,poll,area] = MERCCEmPrior[ecc,poll,area]+DT*MERCC[ecc,poll,area]*MERCRPrior[ecc,poll,area]

    #
    # Reduction Capacity
    #
    @finite_math MERCap[ecc,poll,area] = MERCapPrior[ecc,poll,area]+DT*(MERCRPrior[ecc,poll,area]-
                                       MERCapPrior[ecc,poll,area]/MERCPL[ecc,poll])

    #
    # Reduction Capacity Completion Rate (has to come last, given equations above)
    #
    @finite_math MERCR[ecc,poll,area] = MERCRPrior[ecc,poll,area]+DT*(MERCI[ecc,poll,area]-
                                      MERCRPrior[ecc,poll,area])/MERCD[ecc,poll]

    #
    # Private Expenses for Pollution Reductions
    #
    PRExp[ecc,poll,area] = PRExp[ecc,poll,area]+xPRExp[ecc,poll,area]+
                        (MERCR[ecc,poll,area]*MERCC[ecc,poll,area]*(1-AGFr[ecc,poll,area])+
                         MERCCEm[ecc,poll,area]*MEROCF[ecc,poll])/1e6

    #
    # Government Expenses for Pollution Reductions
    #
    GRExp[ecc,poll,area] = GRExp[ecc,poll,area]+MERCR[ecc,poll,area]*
                         MERCC[ecc,poll,area]*AGFr[ecc,poll,area]/1e6+PAdCost[ecc,poll,area]
  end

  WriteDisk(db,"SOutput/GRExp",year,GRExp)
  WriteDisk(db,"MEOutput/MERCap",year,MERCap)
  WriteDisk(db,"MEOutput/MERCCEm",year,MERCCEm)
  WriteDisk(db,"MEOutput/MERCI",year,MERCI)
  WriteDisk(db,"MEOutput/MERCR",year,MERCR)
  WriteDisk(db,"SOutput/PRExp",year,PRExp)

end

function CtrlPollution(data::Data)
  # @info "  MPollution.jl - CtrlPollution - Economic Activity (Non-Energy) Pollution"

PolCoefficients(data)
ProcessEmissions(data)
# SolidWasteVeryOldWay(data)
# LandUseEmissions(data)
VentingEmissions(data)
FlaringEmissions(data)
FugitivesEmissions(data)
OtherEnergyEmissions(data)
PRAccounting(data)

end # function CtrlPollution

function GrossProcessEmissions(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,PCov,Poll,Polls) = data #sets
  (; GrossPol,MEPol,MERM,ECoverage) = data

  # @info "  MPollution.jl - GrossProcessEmissions"

  #
  # Gross (before policy) Pollution covered by Pollution policy
  #
  for area in Areas, poll in Polls, ecc in ECCs
    pcov = Select(PCov,"Process")
    @finite_math GrossPol[ecc,poll,area] = GrossPol[ecc,poll,area]+
                                         MEPol[ecc,poll,area]/MERM[ecc,poll,area]*
                                         ECoverage[ecc,poll,pcov,area]
  end

  WriteDisk(db,"SOutput/GrossPol",year,GrossPol)

end # function GrossProcessEmissions

end # module MPollution
