#
# EPollution.jl
#

module EPollution

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
  
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Pointer to Base case database

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  PollX::SetArray = ReadDisk(db,"MainDB/PollKey")
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Yrv::VariableArray{1} = ReadDisk(db,"MainDB/Yrv")

  AGFr::VariableArray{3} = ReadDisk(db,"SInput/AGFr",year) #[ECC,Poll,Area,Year]  Government Subsidy ($/$)
  AGPV::VariableArray{2} = ReadDisk(db,"EOutput/AGPV",year) #[Plant,GenCo,Year]  Average Gratis Permit Value (US$/Yr)
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year) #[Area,Market,Year]  Areas included in Market
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  BCarbonSw::Float32 = ReadDisk(db,"SInput/BCarbonSw",year) #[Year]  Black Carbon coefficient switch (1=POCX set relative to PM25)
  BCMult::VariableArray{3} = ReadDisk(db,"SInput/BCMult",year) #[Fuel,ECC,Area,Year]  Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  BCMultProcess::VariableArray{2} = ReadDisk(db,"SInput/BCMultProcess",year) #[ECC,Area,Year]  Process Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes)
  CapTrade::VariableArray{1} = ReadDisk(db,"SInput/CapTrade",year) #[Market,Year]  Emission Cap and Trading Switch (1=Trade, Cap Only=2)
  CFStd::VariableArray{4} = ReadDisk(db,"EGInput/CFStd",year) #[FuelEP,Plant,Poll,Area,Year]  Clean Fuel Standard (kg/MWh)
  CgFPol::VariableArray{4} = ReadDisk(db,"SOutput/CgFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Pollution in Cogeneration Units (Tonnes/Yr)
  CgFPolGross::VariableArray{4} = ReadDisk(db,"SOutput/CgFPolGross",year) #[FuelEP,ECC,Poll,Area,Year]  Cogeneration Units Gross Pollution  (Tonnes/Yr)
  CgPCost::VariableArray{3} = ReadDisk(db,"SOutput/CgPCost",year) #[FuelEP,ECC,Area,Year]  Cogen Permit Cost ($/mmBtu)
  CgPExp::VariableArray{2} = ReadDisk(db,"SOutput/CgPExp",year) #[ECC,Area,Year]  Cogeneration Emission Charges (M$/Yr)
  CgPGratis::VariableArray{3} = ReadDisk(db,"SOutput/CgPGratis",year) #[ECC,Poll,Area,Year]  Cogeneration Gratis Permits (Tonnes/Yr)
  CgPoCst::VariableArray{3} = ReadDisk(db,"SOutput/CgPoCst",year) #[FuelEP,ECC,Area,Year]  Cogeneration Emission Charges (M$/Yr)
  CgPolSq::VariableArray{3} = ReadDisk(db,"SOutput/CgPolSq",year) #[ECC,Poll,Area,Year]  Cogeneration Pollution Sequestered (Tonnes/Yr)
  CgPolSqPenalty::VariableArray{3} = ReadDisk(db,"SOutput/CgPolSqPenalty",year) #[ECC,Poll,Area,Year]  Cogeneration Pollution Sequestered (Tonnes/Yr)
  ECCMarket::VariableArray{2} = ReadDisk(db,"SInput/ECCMarket",year) #[ECC,Market,Year]  Economic Categories included in Market
  ECoverage::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) #[ECC,Poll,PCov,Area,Year]  Emissions Coverage (1=Covered)
  EGCum::VariableArray{2} = zeros(Float32,length(Plant),length(GenCo)) # Accumulated Electricity Generated (GWh/Yr)
  EGPA::VariableArray{2} = ReadDisk(db,"EGOutput/EGPA",year) #[Plant,Area,Year]  Electricity Generated (GWh/Yr)
  EGPAPrior::VariableArray{2} = ReadDisk(db,"EGOutput/EGPA",prior) #[Plant,Area,Year]  Electricity Generated (GWh/Yr)
  EGSpImports::VariableArray{1} = ReadDisk(db,"EGOutput/EGSpImports",year) #[Area,Year]  Imports from Specified Units (GWh)
  EICoverage::VariableArray{3} = ReadDisk(db,"EGInput/EICoverage",year) #[FuelEP,Poll,Area,Year]  Fuels and Polutants included in Emission Intensity (1 = Included)
  ETAPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAPr",year) #[Market,Year]  Cost of Emission Trading Allowances (US$/Tonne)
  ETAvPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAvPr",year) #[Market,Year]  Average Cost of Emission Trading Allowances (US$/Tonne)
  EUCCR::VariableArray{1} = ReadDisk(db,"EGInput/EUCCR",year) #[Area,Year]  Polution Reducution Capital Charge Rate ($/$)
  EUCM::VariableArray{4} = ReadDisk(db,"EGInput/EUCM") #[FuelEP,Plant,Poll,PollX]  Cross-over Reduction Multiplier (Tonnes/Tonnes)
  EUDPF::VariableArray{3} = ReadDisk(db,"EGOutput/EUDPF",year) #[FuelEP,Plant,Area,Year]  Electric Utility Fuel Demands (TBtu/Yr)
  EUEuPol::VariableArray{4} = ReadDisk(db,"EGOutput/EUEuPol",year) #[FuelEP,Plant,Poll,Area,Year]  Electric Utility Pollution (Tonnes/Yr)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Pollution with Cogeneration (Tonnes/Yr)
  EUIRP::VariableArray{4} = ReadDisk(db,"EGOutput/EUIRP",year) #[FuelEP,Plant,Poll,Area,Year]  Indicated Pollutant Reduction (Tonnes/Tonnes)
  EUMEPol::VariableArray{3} = ReadDisk(db,"EGOutput/EUMEPol",year) #[Plant,Poll,Area,Year]  Electric Utility Process Pollution (Tonnes/Yr)
  EUPCostN::VariableArray{4} = ReadDisk(db,"EGInput/EUPCostN") #[FuelEP,Plant,Poll,Area]  Pollution Reduction Cost Normal ($/Tonne)
  EUPExp::VariableArray{1} = ReadDisk(db,"SOutput/EUPExp",year) #[Area,Year]  Electric Utility Emission Charges (M$/Yr)
  EUPOCX::VariableArray{4} = ReadDisk(db,"EGOutput/EUPOCX",year) #[FuelEP,Plant,Poll,Area,Year]  Electric Utility Pollution Coefficient (Tonnes/TBtu)
  EUPVF::VariableArray{4} = ReadDisk(db,"EGInput/EUPVF") #[FuelEP,Plant,Poll,Area]  Pollution Reduction Variance Factor (($/Tonne)/($/Tonne))
  EURCap::VariableArray{4} = ReadDisk(db,"EGOutput/EURCap",year) # [FuelEP,Plant,Poll,Area,Year]  Reduction Capacity (Tonnes/Yr)
  EURCapPrior::VariableArray{4} = ReadDisk(db,"EGOutput/EURCap",prior) # [FuelEP,Plant,Poll,Area,Year]  Reduction Capacity (Tonnes/Yr)
  EURCC::VariableArray{4} = ReadDisk(db,"EGOutput/EURCC",year) # [FuelEP,Plant,Poll,Area,Year]  Reduction Capital Cost ($/Tonne)
  EURCCEm::VariableArray{4} = ReadDisk(db,"EGOutput/EURCCEm",year) # [FuelEP,Plant,Poll,Area,Year]  Embedded Reduction Capital Cost ($)
  EURCCEmPrior::VariableArray{4} = ReadDisk(db,"EGOutput/EURCCEm",prior) # [FuelEP,Plant,Poll,Area,Year]  Embedded Reduction Capital Cost ($)
  EURCD::VariableArray{1} = ReadDisk(db,"EGInput/EURCD") #[Poll]  Reduction Capital Construction Delay (Years)
  EURCI::VariableArray{4} = ReadDisk(db,"EGOutput/EURCI",year) # [FuelEP,Plant,Poll,Area,Year]  Reduction Capacity Initiation (Tonnes/Yr/Yr)
  EURCPL::VariableArray{1} = ReadDisk(db,"EGInput/EURCPL") #[Poll]  Reduction Capital Physical Life (Years)
  EURCR::VariableArray{4} = ReadDisk(db,"EGOutput/EURCR",year) # e[FuelEP,Plant,Poll,Area,Year]  Reduction Capital Completion Rate (Tonnes/Yr/Yr)
  EURCRPrior::VariableArray{4} = ReadDisk(db,"EGOutput/EURCR",prior) # [FuelEP,Plant,Poll,Area,Year]  Reduction Capital Completion Rate (Tonnes/Yr/Yr)
  EURCstM::VariableArray{3} = ReadDisk(db,"EGInput/EURCstM",year) #[FuelEP,Plant,Poll,Year]  Reduction Cost Technology Multiplier ($/$)
  EURICap::VariableArray{4} = ReadDisk(db,"EGOutput/EURICap",year) # [FuelEP,Plant,Poll,Area,Year]   Indicated Reduction Capital (Tonnes/Yr)
  EURM::VariableArray{4} = ReadDisk(db,"EGOutput/EURM",year) # [FuelEP,Plant,Poll,Area,Year]  Reduction Multiplier by Area (Tonnes/Tonnes)
  EUROCF::VariableArray{4} = ReadDisk(db,"EGInput/EUROCF") #[FuelEP,Plant,Poll,Area]  Polution Reducution O&M Cost Factor ($/$)
  EURP::VariableArray{4} = ReadDisk(db,"EGOutput/EURP",year) # [FuelEP,Plant,Poll,Area,Year]  Pollutant Reduction (Tonnes/Tonnes)
  EURPCSw::VariableArray{3} = ReadDisk(db,"EGInput/EURPCSw",year) #[Plant,Poll,Area,Year]  Pollution Reduction Curve Switch (1=2009, 2=2004)
  EURPPrior::VariableArray{4} = ReadDisk(db,"EGOutput/EURP",prior) #[FuelEP,Plant,Poll,Area,Year]  Pollutant Reduction (Tonnes/Tonnes)
  EUVR::VariableArray{4} = ReadDisk(db,"EGOutput/EUVR",year) # [FuelEP,Plant,Poll,Area,Year]  Voluntary Reduction Policy (Tonnes/Tonnes)
  EUVRP::VariableArray{4} = ReadDisk(db,"EGInput/EUVRP",year) #[FuelEP,Plant,Poll,Area,Year]  Voluntary Reduction Policy (Tonnes/Tonnes)
  EUVRPrior::VariableArray{4} = ReadDisk(db,"EGOutput/EUVR",prior) #[FuelEP,Plant,Poll,Area,Year]  Voluntary Reduction Policy (Tonnes/Tonnes)
  EUVRRT::VariableArray{2} = ReadDisk(db,"EGInput/EUVRRT") #[FuelEP,Plant]  Voluntary Reduction response time (Years)
  ExchangeRate::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",year) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateUnit::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateUnit",year) #[Unit,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExYear::VariableArray{1} = ReadDisk(db,"SInput/ExYear") #[Market]  Year to Define Existing Plants (Year)
  FacSw::VariableArray{1} = ReadDisk(db,"SInput/FacSw") #[Market]  Facility Level Intensity Target Switch (1=Facility Target)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FlFrNew::VariableArray{3} = ReadDisk(db,"EGInput/FlFrNew",year) #[FuelEP,Plant,Area,Year]  Fuel Fraction for New Plants
  GPEUSw::VariableArray{1} = ReadDisk(db,"SInput/GPEUSw") #[Market]  Gratis Permit Allocation Switch for Electric Utilities
  GPFrac::VariableArray{4} = ReadDisk(db,"SOutput/GPFrac",year) #[ECC,Poll,PCov,Area,Year]  Emissions Gratis Permit Fraction (Tonnes/Tonnes)
  GPNew::VariableArray{4} = ReadDisk(db,"EGOutput/GPNew",year) #[FuelEP,Plant,Poll,Area,Year]  Gratis Permits for New Plants (kg/MWh)
  GPVCum::VariableArray{2} = zeros(Float32,length(Plant),length(GenCo)) # Accumulated Gratis Permit Value (US$M/Yr)
  GracePd::VariableArray{1} = ReadDisk(db,"SInput/GracePd") #[Market]  Grace Period for New Facilites (Years)
  GRExp::VariableArray{3} = ReadDisk(db,"SOutput/GRExp",year) #[ECC,Poll,Area,Year]  Reduction Government Expenses (M$/Yr)
  GrImpAdj::VariableArray{1} = ReadDisk(db,"EGOutput/GrImpAdj",year) #[Area,Year]  Gross Imports Adjustment (GWh/GWh)
  GrImpMult::VariableArray{2} = ReadDisk(db,"EGInput/GrImpMult",year) #[NodeX,Area,Year]  Gross Imports Multiplier (GWh/GWh)
  GrImports::VariableArray{2} = ReadDisk(db,"EGOutput/GrImports",year) #[NodeX,Area,Year]  Gross Imports (GWh/Yr)
  GrImpTot::VariableArray{1} = ReadDisk(db,"EGOutput/GrImpTot",year) #[Area,Year]  Gross Imports (GWh/Yr)
  GrossPol::VariableArray{3} = ReadDisk(db,"SOutput/GrossPol",year) #[ECC,Poll,Area,Year]  Gross Pollution - before any policies (Tonnes/Yr)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HDLLoad::VariableArray{4} = ReadDisk(db,"EGOutput/HDLLoad",year) #[Node,NodeX,TimeP,Month,Year]  Loading on Transmission Lines (MW)
  HRtM::VariableArray{2} = ReadDisk(db,"EGInput/HRtM",year) #[Plant,Area,Year]  Marginal Heat Rate (Btu/KWh)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationUnit::VariableArray{1} = ReadDisk(db,"MOutput/InflationUnit",year) #[Unit,Year]  Inflation Index ($/$)
  LLPOCX::VariableArray{3} = ReadDisk(db,"EGInput/LLPOCX",year) #[Node,NodeX,Market,Year]  Transmission Emissions (kg/MWH)
  LLPoTxR::VariableArray{3} = ReadDisk(db,"EGOutput/LLPoTxR",year) #[Node,NodeX,Market,Year]  Pollution Costs for Transmission (US$/MWh)
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year) #[ECC,Poll,Area,Year]  Process Pollution (Tonnes/Yr)
  NdArFr::VariableArray{2} = ReadDisk(db,"EGInput/NdArFr",year) #[Node,Area,Year]  Fraction of the Node in each Area
  NetImports::VariableArray{1} = ReadDisk(db,"EGOutput/NetImports",year) #[Area,Year]  Net Imports to Area (GWh)
  OffNew::VariableArray{3} = ReadDisk(db,"EGInput/OffNew",year) #[Plant,Poll,Area,Year]  Offset Permits for New Plants (Tonnes/TBtu)
  OffRq::VariableArray{1} = ReadDisk(db,"SOutput/OffRq",year) #[Area,Year]  GHG Electric Utility Offsets Required (Tonnes/Yr)
  OffsetsElec::VariableArray{3} = ReadDisk(db,"SOutput/OffsetsElec",year) #[ECC,Poll,Area,Year]  Offsets from Electric Generation Units (Tonnes/Yr)
  OffSw::VariableArray{1} = ReadDisk(db,"EGInput/OffSw",year) #[Area,Year]  GHG Electric Utility Offsets Required Switch (1=Required)
  OffValue::VariableArray{3} = ReadDisk(db,"EGOutput/OffValue",year) #[Plant,Poll,Area,Year]  Value of Offsets ($/MWh)
  OtImports::VariableArray{1} = ReadDisk(db,"EGOutput/OtImports",year) #[Area,Year]  Other (Unspecified) Imports (GWh/Yr)
  OtISw::VariableArray{1} = ReadDisk(db,"EGInput/OtISw",year) #[Area,Year]  Other (Unspecified) Imports Switch
  PAdCost::VariableArray{3} = ReadDisk(db,"SInput/PAdCost",year) #[ECC,Poll,Area,Year]  Policy Administrative Cost (Exogenous)
  PAucSw::VariableArray{1} = ReadDisk(db,"SInput/PAucSw") #[Market]  Switch to Auction Permits (1=Auction)
  PCost::VariableArray{4} = ReadDisk(db,"EGOutput/PCost",year) #[FuelEP,Plant,Poll,Area,Year]  Permit Cost ($/Tonne)
  PCostECC::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost (Real $/Tonnes)
  PCostECCExo::VariableArray{3} = ReadDisk(db,"SInput/PCostExo",year) #[ECC,Poll,Area,Year]  Exogenous Permit Cost (Real $/Tonnes)
  PCostExo::VariableArray{4} = zeros(Float32,length(FuelEP),length(Plant),length(Poll),length(Area)) #[FuelEP,Plant,Poll,Area]  Permit Cost ($/Tonne)
  PCostM::VariableArray{4} = ReadDisk(db,"EGInput/PCostM",year) #[FuelEP,Plant,Poll,Area,Year]  Permit Cost Multiplier ($/Tonne/$/Tonne)
  PCostOut::VariableArray{4} = ReadDisk(db,"EGOutput/PCostOut",year) #[FuelEP,Plant,Poll,Area,Year]  Permit Cost ($/Tonne)
  PCovMarket::VariableArray{2} = ReadDisk(db,"SInput/PCovMarket",year) #[PCov,Market,Year]  Types of Pollution included in Market
  PGratEx::VariableArray{4} = ReadDisk(db,"SOutput/PGratEx",year) #[ECC,Poll,PCov,Area,Year]  Gratis Permits for Existing Capacity (Tonnes/Yr)
  PGratis::VariableArray{4} = ReadDisk(db,"SOutput/PGratis",year) #[ECC,Poll,PCov,Area,Year]  Gratis Permits (Tonnes/Yr)
  PGratisOBPS::VariableArray{4} = ReadDisk(db,"SOutput/PGratisOBPS",year) #[ECC,Poll,PCov,Area,Year]  Gratis Permits for Output Based Pricing System (Tonnes/Yr)
  PGratNew::VariableArray{4} = ReadDisk(db,"SOutput/PGratNew",year) #[ECC,Poll,PCov,Area,Year]  Gratis Permits for Existing Capacity (Tonnes/Yr)
  POCX::VariableArray{4} = ReadDisk(db,"EGInput/POCX",year) #[FuelEP,Plant,Poll,Area,Year]  Marginal Pollution Coefficients (Tonnes/TBtu)
  POCXOthImports::VariableArray{3} = ReadDisk(db,"EGInput/POCXOthImports",year) #[Poll,NodeX,Area,Year]  Imported Emissions Coefficients (Tonnes/GWh)
  POCXRnImports::VariableArray{2} = ReadDisk(db,"EGInput/POCXRnImports",year) #[Poll,Area,Year]  Renewable Imports Emissions Coefficient (Tonnes/GWh)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (Tonne eCO2/Tonne)
  PolCov::VariableArray{4} = ReadDisk(db,"SOutput/PolCov",year) #[ECC,Poll,PCov,Area,Year]  Covered Pollution (Tonnes/Yr)
  PolImports::VariableArray{2} = ReadDisk(db,"SOutput/PolImports",year) #[Poll,Area,Year]  Emissions from Imported Electricity (Tonnes)
  PollLimitGHGFlag::VariableArray{1} = ReadDisk(db,"EGInput/PollLimitGHGFlag",year) #[Area,Year]  Pollution Limit GHG Flag (1=GHG Limit)
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) #[Poll,Market,Year]  Pollutants included in Market
  PolOthImports::VariableArray{2} = ReadDisk(db,"EGOutput/PolOthImports",year) #[Poll,Area,Year]  Emissions from Non-Specified Imports (Tonnes)
  PolRnImports::VariableArray{2} = ReadDisk(db,"EGOutput/PolRnImports",year) #[Poll,Area,Year]  Emissions from Renewable Imports (Tonnes)
  PolSpImport::VariableArray{2} = ReadDisk(db,"EGOutput/PolSpImport",year) #[Poll,Area,Year]  Emissions from Imports from Specified Units (Tonnes)
  PoTRNew::VariableArray{2} = ReadDisk(db,"EGOutput/PoTRNew",year) #[Plant,Area,Year]  Emission Cost for New Plants ($/MWh)
  PoTxRNew::VariableArray{4} = ReadDisk(db,"EGOutput/PoTxRNew",year) #[FuelEP,Plant,Poll,Area,Year]  New Plant Emission Cost ($/MWh)
  PoTxRNewGross::VariableArray{4} = ReadDisk(db,"EGOutput/PoTxRNewGross",year) #[FuelEP,Plant,Poll,Area,Year]  New Plant Gross Emission Cost ($/MWh)
  PoTxRNewSq::VariableArray{4} = ReadDisk(db,"EGOutput/PoTxRNewSq",year) #[FuelEP,Plant,Poll,Area,Year]  New Plant Emission Cost Reduction for CCS ($/MWh)
  PRExp::VariableArray{3} = ReadDisk(db,"SOutput/PRExp",year) #[ECC,Poll,Area,Year]  Reduction Private Expenses (M$/Yr)
  PSoECC::VariableArray{2} = ReadDisk(db,"SOutput/PSoECC",year) #[ECC,Area,Year]  Power Sold to Grid (GWh)
  RnGen::VariableArray{1} = ReadDisk(db,"EGOutput/RnGen",year) #[Area,Year]  Renewable Current Level of Generation (GWh/Yr)
  RnGoal::VariableArray{1} = ReadDisk(db,"EGOutput/RnGoal",year) #[Area,Year]  Renewable Generation Goal (GWh/Yr)
  RnImports::VariableArray{1} = ReadDisk(db,"EGOutput/RnImports",year) #[Area,Year]  Renewable Generation Imports (GWh/Yr)
  RnOption::VariableArray{1} = ReadDisk(db,"EGInput/RnOption",year) #[Area,Year]  Renewable Expansion Option (1=Local RPS, 2=Regional RPS, 3=FIT)
  RPolicy::VariableArray{3} = ReadDisk(db,"SOutput/RPolicy",year) #[ECC,Poll,Area,Year]  Pollution Reduction from Limit (Tonnes/Tonnes)
  RREx::VariableArray{4} = ReadDisk(db,"SOutput/RREx",year) #[ECC,Poll,PCov,Area,Year]  Require Reductions in Existing Facilities (Tonnes/Yr)
  RRNew::VariableArray{4} = ReadDisk(db,"SOutput/RRNew",year) #[ECC,Poll,PCov,Area,Year]  Require Reductions in New Facilities (Tonnes/Yr)
  SaEC::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",year) #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)
  SqFr::VariableArray{3} = ReadDisk(db,"EGInput/SqFr",year) #[Plant,Poll,Area,Year]  Sequestered Pollution Fraction (Tonne/Tonne)
  SqPolCC::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCC",year) #[ECC,Poll,Area,Year]  Sequestering Non-Cogeneration Gross Emissions (Tonnes/Yr)
  SqPolCCNet::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCNet",year) #[ECC,Poll,Area,Year]  Sequestering Non-Cogeneration Net Emissions (Tonnes/Yr)
  SqPolCCPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCPenalty",year) #[ECC,Poll,Area,Year]  Sequestering Non-Cogeneration Emissions Penalty (Tonnes/Yr)
  TargNew::VariableArray{1} = ReadDisk(db,"SInput/TargNew",year) #[Market,Year]  Emission Reduction Target for New Capacity (Tonnes/Tonnes)
  TDEF::VariableArray{2} = ReadDisk(db,"SInput/TDEF",year) #[Fuel,Area,Year]  T&D Efficiency (Btu/Btu)
  TFPol::VariableArray{4} = ReadDisk(db,"SOutput/TFPol",year) #[ES,FuelEP,Poll,Area,Year]  Energy Sector Pollution (Tonnes/Yr)
  TSPol::VariableArray{3} = ReadDisk(db,"SOutput/TSPol",year) #[ES,Poll,Area,Year]  Energy Sector Pollution (Tonnes/Yr)
  UnArea::Vector{String} = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
  UnCode::Vector{String} = ReadDisk(db,"EGInput/UnCode") #[Unit]  Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::Float32 = ReadDisk(db,"EGInput/UnCounter",year) #[Year]  Number of Units
  UnCounterPrior::Float32 = ReadDisk(db,"EGInput/UnCounter",prior) #[Year]  Number of Units
  UnCoverage::VariableArray{2} = ReadDisk(db,"EGInput/UnCoverage",year) #[Unit,Poll,Year]  Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UnDmd",year) #[Unit,FuelEP,Year]  Energy Demands (TBtu)
  UnDmdPrior::VariableArray{2} = ReadDisk(db,"EGOutput/UnDmd",prior) #[Unit,FuelEP,Year]  Energy Demands (TBtu)
 
  UnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGA",year) #[Unit,Year]  Generation (GWh)
  UnEGABase::VariableArray{1} = ReadDisk(BCNameDB,"EGOutput/UnEGA",year) #[Unit,Year]  Generation (GWh)
  UnEGAPrior::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGA",prior) #[Unit,Year]  Generation (GWh)
 
  UnEI::VariableArray{1} = ReadDisk(db,"EGOutput/UnEI",year) #[Unit,Year]  Emission Intensity (Tonnes/GWh)
  UnEmit::VariableArray{1} = ReadDisk(db,"EGInput/UnEmit") #[Unit]  Does this Unit Emit Pollution? (1=Yes)
  UnFlFr::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFr",year) #[Unit,FuelEP,Year]  Fuel Fraction (Btu/Btu)
  UnFrImports::VariableArray{2} = ReadDisk(db,"EGInput/UnFrImports",year) #[Unit,Area,Year]  Fraction of Unit Imported to Area (GWH/GWH)
  UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Gross Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
  UnGP::VariableArray{3} = ReadDisk(db,"EGOutput/UnGP",year) #[Unit,FuelEP,Poll,Year]  Unit Intensity Target or Gratis Permits (kg/MWh)
  UnHRt::VariableArray{1} = ReadDisk(db,"EGInput/UnHRt",year) #[Unit,Year]  Heat Rate (Btu/KWh)
  UnLife::VariableArray{1} = ReadDisk(db,"EGOutput/UnLife",year) #[Unit,Year]  Number of Years for Unit to Operate (Years)
  UnMECX::VariableArray{2} = ReadDisk(db,"EGInput/UnMECX",year) #[Unit,Poll,Year]  Process Pollution Coefficient (Tonnes/GWh)
  UnMEPol::VariableArray{2} = ReadDisk(db,"EGOutput/UnMEPol",year) #[Unit,Poll,Year]  Process Pollution (Tonnes)
  UnNeedsCredits::VariableArray{2} = ReadDisk(db,"EGOutput/UnNeedsCredits",year) #[Unit,Poll,Year]  Switch If Unit Still Needs Credits (1=Needs Credits)
  UnNode::Vector{String} = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
  UnOffsets::VariableArray{2} = ReadDisk(db,"EGInput/UnOffsets",year) #[Unit,Poll,Year]  Offsets (Tonnes/GWh)
  UnOffValue::VariableArray{2} = ReadDisk(db,"EGOutput/UnOffValue",year) #[Unit,Poll,Year]  Offset Value ($/MWh)
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  UnOUREG::VariableArray{1} = ReadDisk(db,"EGInput/UnOUREG",year) #[Unit,Year]  Own Use Rate for Generation (GWh/GWh)
  UnPExp::VariableArray{1} = ReadDisk(db,"EGOutput/UnPExp",year) #[Unit,Year]  Unit Emission Charges (M$/Yr)
  UnPGratis::VariableArray{2} = ReadDisk(db,"EGOutput/UnPGratis",year) #[Unit,Poll,Year]  Gratis Permits (Tonnes/Yr)
  UnPGValue::VariableArray{2} = ReadDisk(db,"EGOutput/UnPGValue",year) #[Unit,Poll,Year]  Gratis Permit Value (US$M/Yr)
  UnPlant::Vector{String} = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
  UnPOCA::VariableArray{3} = ReadDisk(db,"EGOutput/UnPOCA",year) #[Unit,FuelEP,Poll,Year]  Pollution Coefficient (Tonnes/TBtu)
  UnPOCAPrior::VariableArray{3} = ReadDisk(db,"EGOutput/UnPOCA",prior) #[Unit,FuelEP,Poll,Prior]  Pollution Coefficient in Previous Year (Tonnes/TBtu)
  UnPOCGWh::VariableArray{2} = ReadDisk(db,"EGOutput/UnPOCGWh",year) #[Unit,Poll,Year]  Pollution Coefficient (Tonnes/GWh)
  UnPOCX::VariableArray{3} = ReadDisk(db,"EGInput/UnPOCX",year) #[Unit,FuelEP,Poll,Year]  Pollution Coefficient (Tonnes/TBtu)
  UnPol::VariableArray{3} = ReadDisk(db,"EGOutput/UnPol",year) #[Unit,FuelEP,Poll,Year]  Pollution (Tonnes)
  UnPolGross::VariableArray{3} = ReadDisk(db,"EGOutput/UnPolGross",year) # [Unit,FuelEP,Poll,Year]  Gross Pollution (Tonnes)
  UnPolSq::VariableArray{3} = ReadDisk(db,"EGOutput/UnPolSq",year) # [Unit,FuelEP,Poll,Year]  Gross Sequestered Pollution (Tonnes/Yr)
  UnPolSqPenalty::VariableArray{3} = ReadDisk(db,"EGOutput/UnPolSqPenalty",year) # [Unit,FuelEP,Poll,Year]  Sequestered Pollution Penalty (Tonnes/Yr)
  UnPoTAv::VariableArray{3} = ReadDisk(db,"EGOutput/UnPoTAv",year) #[Unit,FuelEP,Poll,Year]  Average Pollution Tax Rate ($/MWh)
  UnPoTR::VariableArray{1} = ReadDisk(db,"EGOutput/UnPoTR",year) #[Unit,Year]  Pollution Tax Rate ($/MWh)
  UnPoTxR::VariableArray{3} = ReadDisk(db,"EGOutput/UnPoTxR",year) #[Unit,FuelEP,Poll,Year]  Marginal Pollution Tax Rate ($/MWh)
  UnPRCost::VariableArray{1} = ReadDisk(db,"EGOutput/UnPRCost",year) #[Unit,Year]  Levelized Cost of Unit with Pollution Reduction Equipment ($/MWh)
  UnPRSw::VariableArray{2} = ReadDisk(db,"EGInput/UnPRSw",year) #[Unit,Poll,Year]  Pollution Reduction Switch (Number)
  UnRCap::VariableArray{3} = ReadDisk(db,"EGOutput/UnRCap",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Capacity (Tonnes/Yr)
  UnRCapPrior::VariableArray{3} = ReadDisk(db,"EGOutput/UnRCap",prior) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Capacity (Tonnes/Yr)
  UnRCC::VariableArray{3} = ReadDisk(db,"EGOutput/UnRCC",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Capital Cost ($/(Tonnes/Yr))
  UnRCCEm::VariableArray{2} = ReadDisk(db,"EGOutput/UnRCCEm",year) #[Unit,Poll,Year]  Embedded Pollution Reduction Capital Cost (M$)
  UnRCCEmPrior::VariableArray{2} = ReadDisk(db,"EGOutput/UnRCCEm",prior) #[Unit,Poll,Year]  Embedded Pollution Reduction Capital Cost (M$)
  UnRCGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnRCGA",year) #[Unit,Year]  Emission Reduction Capital Costs (M$/Yr)
  UnRCI::VariableArray{3} = ReadDisk(db,"EGOutput/UnRCI") #[Unit,FuelEP,Poll]  Pollution Reduction Capacity Initiated (Tonnes/Yr/Yr)
  UnRCOM::VariableArray{1} = ReadDisk(db,"EGOutput/UnRCOM",year) #[Unit,Year]  Emission Reduction O&M Costs (M$/Yr)
  UnRCR::VariableArray{3} = ReadDisk(db,"EGOutput/UnRCR",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Completion Rate (Tonnes/Yr/Yr)
  UnRCRPrior::VariableArray{3} = ReadDisk(db,"EGOutput/UnRCR",prior) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Completion Rate (Tonnes/Yr/Yr)
  UnRetire::VariableArray{1} = ReadDisk(db,"EGInput/UnRetire",year) #[Unit,Year]  Retirement Date (Year)
  UnRICap::VariableArray{3} = ReadDisk(db,"EGOutput/UnRICap") #[Unit,FuelEP,Poll]  Pollution Indicated Reduction Capacity (Tonnes/Yr)
  UnRM::VariableArray{3} = ReadDisk(db,"EGOutput/UnRM",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Multiplier (Tonnes/Tonnes)
  UnROCF::VariableArray{2} = ReadDisk(db,"EGInput/UnROCF",year) #[Unit,Poll,Year]  Pollution Reduction O&M Cost Factor ($/Yr/$)
  UnRP::VariableArray{3} = ReadDisk(db,"EGOutput/UnRP",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction (Tonnes/Tonnes)
  UnRR::VariableArray{2} = zeros(Float32,length(Unit),length(Poll)) #[Unit,Poll] Pollution Reduction Required (Tonnes)
  UnSector::Vector{String} = ReadDisk(db,"EGInput/UnSector") #[Unit]  Unit Type (Utility or Industry)
  UnSqFr::VariableArray{2} = ReadDisk(db,"EGInput/UnSqFr",year) #[Unit,Poll,Year]  Sequestered Pollution Fraction (Tonnes/Tonnes)
  UnZeroFr::VariableArray{3} = ReadDisk(db,"EGInput/UnZeroFr",year) #[Unit,FuelEP,Poll,Year]  Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
 
  UUnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGA",year) #[Unit,Year]  Endogenous Generation (GWh)
  UUnEGABase::VariableArray{1} = ReadDisk(BCNameDB,"EGOutput/UUnEGA",year) #[Unit,Year]  Endogenous Generation (GWh)
  UUnEGAve::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGAve",year) #[Unit,Year]  Average Endogenous Generation (GWh)
  UUnEGAveBase::VariableArray{1} = ReadDisk(BCNameDB,"EGOutput/UUnEGAve",year) #[Unit,Year]  Average Endogenous Generation (GWh)

  xEURM::VariableArray{4} = ReadDisk(db,"EGInput/xEURM",year) #[FuelEP,Plant,Poll,Area,Year]  Exogenous Reduction Multiplier by Area (Tonnes/Tonnes)
  xGPNew::VariableArray{4} = ReadDisk(db,"EGInput/xGPNew",year) #[FuelEP,Plant,Poll,Area,Year]  Gratis Permits for New Plants (kg/MWh)
  xPGratis::VariableArray{4} = ReadDisk(db,"SInput/xPGratis",year) #[ecc,poll,pcov,area],Year]  Exogenous Gratis Permits (Tonnes/Yr)
  xPolOthImports::VariableArray{2} = ReadDisk(db,"EGInput/xPolOthImports",year) #[Poll,Area,Year]  Exogenous Imported Emissions (Tonnes)
  xRnImports::VariableArray{1} = ReadDisk(db,"EGInput/xRnImports",year) #[Area,Year]  Exogenous Renewable Generation Imports (GWh/Yr)
  xUnGP::VariableArray{3} = ReadDisk(db,"EGInput/xUnGP",year) #[Unit,FuelEP,Poll,Year]  Unit Intensity Target or Gratis Permits (kg/MWh)
  xUnRCC::VariableArray{3} = ReadDisk(db,"EGInput/xUnRCC",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Capital Cost ($/(Tonnes/Yr))
  xUnRP::VariableArray{3} = ReadDisk(db,"EGInput/xUnRP",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction (Tonnes/Tonnes)
  ZeroFr::VariableArray{3} = ReadDisk(db,"SInput/ZeroFr",year) #[FuelEP,Poll,Area,Year]  Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
  
  #
  # Scratch
  #
  UnEGAPermits::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit] Generation for Permit Calculations (GWh/Yr)
  UnPOCNet::VariableArray{3} = zeros(Float32,length(Unit),length(FuelEP),length(Poll)) # [Unit,FuelEP,Poll] Pollution Coefficient Net of CCS (Tonnes/TBtu)
  UUnEGAPermits::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit]   Endogenous Generation for Permit Calculations (GWh/Yr)
  UUnEGAvePermits::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit]  Average Endogenous Generation for Permit Calculations (GWh/Yr)

end

function GetUnitSets(data,unit)
  (;Area,ECC,GenCo,Node,Plant) = data
  (;UnArea,UnGenCo,UnNode,UnPlant,UnSector) = data

  if (UnArea[unit] != "Null")  &&
     (UnGenCo[unit] != "Null") && 
     (UnNode[unit] != "Null")  &&
     (UnPlant[unit] != "Null") &&
     (UnSector[unit] != "Null") 
     
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])    
    genco = Select(GenCo,UnGenCo[unit])
    node = Select(Node,UnNode[unit])
    plant = Select(Plant,UnPlant[unit])
    
    UnitIsValid=true
    
  else
    area = Int(1)
    ecc = Int(1)
    genco = Int(1)
    node = Int(1)
    plant = Int(1)
    UnitIsValid = false
  end

  return area,ecc,genco,node,plant,UnitIsValid
end

function ResetUnitSets(data::Data)
  # 
  #  This procedure restores the sets to all values
  # 
  # Select ECC*, GenCo*, Plant*, Node*, Area*
end

function GetUtilityUnits(data::Data,test)
  (; CTime) = data
  (; UnCogen,UnCounter,UnCounterPrior,UnOnLine,UnRetire) = data

  if test == "UsePrior"
    units = 1:Int(UnCounterPrior)
  else
    units = 1:Int(UnCounter)
  end

  unitsol = Select(UnOnLine,<=(CTime))
  unitsret = Select(UnRetire,>(CTime))
  unitscg0 = Select(UnCogen, ==(0.0))

  UtilityUnits = intersect(units,unitsol,unitsret,unitscg0)

  return UtilityUnits

end

function GetCogenUnits(data::Data,test)
  (; CTime) = data
  (; UnCogen,UnCounter,UnCounterPrior,UnOnLine,UnRetire) = data

  if test == "UsePrior"
    units = 1:Int(UnCounterPrior)
  else
    units = 1:Int(UnCounter)
  end

  unitsol = Select(UnOnLine,<=(CTime))
  unitsret = Select(UnRetire,>(CTime))
  unitscg0 = Select(UnCogen,>(0.0))

  CogenUnits = intersect(units,unitsol,unitsret,unitscg0)

  return CogenUnits

end

function CheckGeneration(data::Data)

  #
  # 23.10.02, LJD: Procedure unused in Promula
  #

  # Define Procedure CheckGeneration
  # 
  # GenerationIsEndogenous = "True"
  # GenerationIsByPlantType = "False"
  # 
  # End Procedure CheckGeneration

end

function GetMarketParameters(data::Data,market)
  (; Areas,ECC,Poll,Poll,Polls) = data
  (; AreaMarket,CapTrade,ECCMarket,PollMarket) = data

  #
  # This procedure gets the parameters for this market including whether the
  # market is active for electric generation (ECCMarket) for this year (CapTrade).
  #

  ecc = Select(ECC,"UtilityGen")

  areas = findall(AreaMarket[:,market] .== 1)
  polls = findall(PollMarket[:,market] .== 1)

  # areas = Select(Area,"AB")
  # polls = Select(Poll, ["CO2","CH4","N2O","SF6","PFC","HFC"])
  ActiveMarket = "False"

  for poll in polls, area in areas
    if (AreaMarket[area,market] == 1) && (ECCMarket[ecc,market] == 1) &&
      (PollMarket[poll,market] == 1) && (CapTrade[market] != 0) && (CapTrade[market] != 6)
      ActiveMarket = "True"
    else
      ActiveMarket = "False"
    end
  end

  return areas,polls,ActiveMarket

end

function InitializePollution(data::Data)
  (; db,year) = data
  (; UnGP,UnLife,UnMEPol,UnNeedsCredits,UnOffValue,UnPGValue) = data
  (; UnPOCA,UnPOCGWh,UnPol,UnPolGross,UnPolSq,UnPolSqPenalty,UnPoTAv,UnPoTR) = data
  (; UnPoTxR,UnPRCost,UnRCap,UnRCC,UnRCCEm) = data
  (; UnRCGA,UnRCI,UnRCOM,UnRCR,UnRICap,UnRM) = data


  @. UnGP = 0
  @. UnLife = 0
  @. UnMEPol = 0
  @. UnNeedsCredits = 0
  @. UnOffValue = 0
  @. UnPGValue = 0
  @. UnPOCA = 0
  @. UnPOCGWh = 0
  @. UnPol = 0
  @. UnPolGross = 0
  @. UnPolSq = 0
  @. UnPolSqPenalty = 0
  @. UnPoTAv = 0
  @. UnPoTR = 0
  @. UnPoTxR = 0
  @. UnPRCost = 0
  @. UnRCap = 0
  @. UnRCC = 0
  @. UnRCCEm = 0
  @. UnRCGA = 0
  @. UnRCI = 0
  @. UnRCOM = 0
  @. UnRCR = 0
  @. UnRICap = 0
  @. UnRM = 1

  WriteDisk(db,"EGOutput/UnGP",year,UnGP)
  WriteDisk(db,"EGOutput/UnLife",year,UnLife)
  WriteDisk(db,"EGOutput/UnMEPol",year,UnMEPol)
  WriteDisk(db,"EGOutput/UnNeedsCredits",year,UnNeedsCredits)
  WriteDisk(db,"EGOutput/UnOffValue",year,UnOffValue)
  WriteDisk(db,"EGOutput/UnPGValue",year,UnPGValue)
  WriteDisk(db,"EGOutput/UnPOCA",year,UnPOCA)
  WriteDisk(db,"EGOutput/UnPOCGWh",year,UnPOCGWh)
  WriteDisk(db,"EGOutput/UnPol",year,UnPol)
  WriteDisk(db,"EGOutput/UnPolGross",year,UnPolGross)
  WriteDisk(db,"EGOutput/UnPolSq",year,UnPolSq)
  WriteDisk(db,"EGOutput/UnPolSqPenalty",year,UnPolSqPenalty)
  WriteDisk(db,"EGOutput/UnPoTAv",year,UnPoTAv)
  WriteDisk(db,"EGOutput/UnPoTR",year,UnPoTR)
  WriteDisk(db,"EGOutput/UnPoTxR",year,UnPoTxR)
  WriteDisk(db,"EGOutput/UnPRCost",year,UnPRCost)
  WriteDisk(db,"EGOutput/UnRCap",year,UnRCap)
  WriteDisk(db,"EGOutput/UnRCC",year,UnRCC)
  WriteDisk(db,"EGOutput/UnRCCEm",year,UnRCCEm)
  WriteDisk(db,"EGOutput/UnRCGA",year,UnRCGA)
  WriteDisk(db,"EGOutput/UnRCI",UnRCI)
  WriteDisk(db,"EGOutput/UnRCOM",year,UnRCOM)
  WriteDisk(db,"EGOutput/UnRCR",year,UnRCR)
  WriteDisk(db,"EGOutput/UnRICap",UnRICap)
  WriteDisk(db,"EGOutput/UnRM",year,UnRM)

end

function GetPCost(data::Data)
  (; db,year) = data
  (; Areas,ECC,FuelEPs,Plants,Polls) = data
  (; PCost,PCostECC,PCostECCExo,PCostExo,PCostOut) = data

  #
  # This procedure extracts the pollution costs (PCost, PCostECC)
  # for electric utility generation.
  #
  ecc = Select(ECC,"UtilityGen")

  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    PCost[fuelep,plant,poll,area] = PCostECC[ecc,poll,area]
    PCostOut[fuelep,plant,poll,area] = PCost[fuelep,plant,poll,area]
    PCostExo[fuelep,plant,poll,area] = PCostECCExo[ecc,poll,area]
  end

  WriteDisk(db,"EGOutput/PCost",year,PCost)
  WriteDisk(db,"EGOutput/PCostOut",year,PCostOut)

end

function InitializeEmissionsCoverage(data::Data)
  (; Areas,ECC,ECCs,PCov,Polls) = data
  (; PolCov) = data

  pcov = Select(PCov,"Cogeneration")
  for area in Areas, poll in Polls, ecc in ECCs
    PolCov[ecc,poll,pcov,area] = 0
  end

  ecc = Select(ECC,"UtilityGen")
  pcov = Select(PCov,"Energy")
  for area in Areas, poll in Polls
    PolCov[ecc,poll,pcov,area] = 0
  end

end

function CoveredEmissions(data,unit,ecc,polls,pcov,area,market)
  (; FuelEPs) = data
  (; PolConv,PolCov,UnPol) = data
 
  for poll in polls
    PolCov[ecc,poll,pcov,area] = PolCov[ecc,poll,pcov,area]+
      sum(UnPol[unit,fuelep,poll] for fuelep in FuelEPs)*PolConv[poll]
  end 

end

function AddElectricImportEmissions(data::Data)
  (; Areas,ECC,PCov,Polls) = data
  (; ECoverage,PolConv,PolCov,PolImports) = data

  ecc = Select(ECC,"UtilityGen")
  pcov = Select(PCov,"Energy")

  for area in Areas, poll in Polls
    PolCov[ecc,poll,pcov,area] = PolCov[ecc,poll,pcov,area]+
      PolImports[poll,area]*PolConv[poll]*ECoverage[ecc,poll,pcov,area]
  end

end

function InitializeUnPRAccounting(data::Data,ecc)
  (; Polls,Areas) = data
  (; GRExp,PRExp) = data
  
  #
  # Initialize expenses before accumulating across Units
  #
  for poll in Polls, area in Areas
    PRExp[ecc,poll,area] = 0
    GRExp[ecc,poll,area] = 0
  end

end

function UnitEmbeddedReductionCapitalCosts(data::Data,unit)
  (; FuelEPs,Polls) = data
  (; UnRCC,UnRCCEm,UnRCCEmPrior,UnRCR) = data

  for poll in Polls
    UnRCCEm[unit,poll] = UnRCCEmPrior[unit,poll]+
      sum(UnRCC[unit,fuelep,poll]*UnRCR[unit,fuelep,poll] for fuelep in FuelEPs)
  end

end

function UnitEmissionReductionCapitalCosts(data::Data,unit,ecc,area)
  (; FuelEPs,Poll,Polls) = data
  (; AGFr,UnRCC,UnRCGA,UnRCR) = data
  InnerSum::VariableArray{1} = zeros(Float32,length(Poll))
  
  for poll in Polls
    InnerSum[poll] = sum(UnRCR[unit,fuelep,poll]*
                         UnRCC[unit,fuelep,poll] for fuelep in FuelEPs)
  end

  UnRCGA[unit] = sum(InnerSum[poll]*(1-AGFr[ecc,poll,area]) for poll in Polls)/1e6

end

function UnitEmissionReductionOMCosts(data::Data,unit)
  (; Polls) = data
  (; UnRCCEm,UnRCOM,UnROCF) = data

  UnRCOM[unit] = sum(UnRCCEm[unit,poll]*UnROCF[unit,poll] for poll in Polls)/1e6

end

function UnitPrivateExpensesForPollutionReductions(data::Data,unit,ecc,area)
  (; FuelEPs,Polls) = data
  (; AGFr,PRExp,UnRCC,UnRCCEm,UnRCR,UnROCF) = data

  for poll in Polls
    PRExp[ecc,poll,area] = PRExp[ecc,poll,area]+(sum(UnRCR[unit,fuelep,poll]*
      UnRCC[unit,fuelep,poll] for fuelep in FuelEPs)*(1-AGFr[ecc,poll,area])+
      UnRCCEm[unit,poll]*UnROCF[unit,poll])/1e6
  end

end

function UnitGovernmentExpensesForPollutionReductions(data::Data,unit,ecc,area)
  (; FuelEPs,Polls) = data
  (; AGFr,GRExp,PAdCost,UnRCC,UnRCR) = data

  for poll in Polls
    GRExp[ecc,poll,area] = GRExp[ecc,poll,area]+
                        (sum(UnRCR[unit,fuelep,poll]*
                        UnRCC[unit,fuelep,poll] for fuelep in FuelEPs))*
                        AGFr[ecc,poll,area]/1e6+
                        PAdCost[ecc,poll,area]
  end

end

function PutUnPRAccounting(data::Data)
  (; db,year) = data
  (; GRExp,PRExp,UnRCCEm,UnRCGA,UnRCOM) = data

  WriteDisk(db,"SOutput/GRExp",year,GRExp)
  WriteDisk(db,"SOutput/PRExp",year,PRExp)
  WriteDisk(db,"EGOutput/UnRCCEm",year,UnRCCEm)
  WriteDisk(db,"EGOutput/UnRCGA",year,UnRCGA)
  WriteDisk(db,"EGOutput/UnRCOM",year,UnRCOM)
end

function InitializeGratisPermits(data::Data,ecc,pcov)
  (; ECC,ECCs,PCov,Polls,Areas,Units) = data
  (; PGratis,PGratEx,PGratisOBPS,PGratNew,RREx,RRNew,UnPGValue,CgPGratis) = data

  for poll in Polls, area in Areas
    PGratEx[ecc,poll,pcov,area] = 0
    PGratNew[ecc,poll,pcov,area] = 0
    PGratis[ecc,poll,pcov,area] = 0
    PGratisOBPS[ecc,poll,pcov,area] = 0
    RREx[ecc,poll,pcov,area] = 0
    RRNew[ecc,poll,pcov,area] = 0
  end

  for unit in Units, poll in Polls
    UnPGValue[unit,poll] = 0
  end
  # Note all ECCs are modified here per Spruce Promula code
  for ecc in ECCs, poll in Polls, area in Areas
    CgPGratis[ecc,poll,area] = 0
  end

end

#function ReadBaseValuesForPermits(data::Data,market,unit)
#  (; BaseSw,FacSw,UnEGA,UnEGABase,UnEGAPermits) = data
#  (; UUnEGA,UUnEGABase,UUnEGAPermits) = data
#  (; UUnEGAve,UUnEGAveBase,UUnEGAvePermits) = data  
#  
#  #
#  # If this is not a facility level cap (FacSw=0), then read in the
#  # base case values to determine the permits
#  #
#  if (FacSw[market] == 0) && (BaseSw == 0)
#    UnEGAPermits[unit] = UnEGABase[unit]
#    UUnEGAPermits[unit] = UUnEGABase[unit]
#    UUnEGAvePermits[unit] = UUnEGAveBase[unit]
#  else
#    UnEGAPermits[unit] = UnEGA[unit]
#    UUnEGAPermits[unit] = UUnEGA[unit]
#    UUnEGAvePermits[unit] = UUnEGAve[unit]    
#  end
#
#end

function PermitsForFuelBurningPlants(data::Data,market,unit,polls)
  (; FuelEPs) = data
  (; PolConv,UnEGA,UnFlFr,UnGP,UnHRt,UnPOCA,UnRR) = data

  #
  # Gratis Permits and Required Reductions for Fuel Burning Plants
  # If unit burns fuel, then gratis permits may vary by fuel.
  #
  Sum1 = sum(UnFlFr[unit,fuelep] for fuelep in FuelEPs)
  if Sum1 > 0.0
    for poll in polls
      UnRR[unit,poll] = sum(UnFlFr[unit,fuelep]*
                      (UnPOCA[unit,fuelep,poll]*UnHRt[unit]*PolConv[poll]/1e6-
                       UnGP[unit,fuelep,poll]) for fuelep in FuelEPs)*UnEGA[unit]
    end
    
  #
  # For units which do not burn fuel the gratis permits are stored
  # in all fuels so use FuelEP(1) - Jeff Amlin 11/14/24
  #
  else
    for poll in polls
      fuelep = 1
      UnRR[unit,poll] = 0-sum(UnGP[unit,fuelep,poll]*UnEGA[unit])
    end
  end

end

function PermitsForFacilityIntensityTargets(data::Data,market,unit,polls)
  (; ETAvPr,FacSw,PAucSw,UnPGratis,UnPGValue) = data

  #
  # If this is a facility intensity target (FacSw=1), then the value
  # of permits have already been accounted for.  If the permits are
  # auctioned (PAucSw=1), then the must be purchased and the retail
  # customers get no rebate.
  #
  # Assume facility level intensity target - Jeff Amlin 3/17/25
  #
  FacSw[market] = 1
  if (FacSw[market] == 0) && (PAucSw[market] == 0)
    for poll in polls
      UnPGValue[unit,poll] = UnPGratis[unit,poll]*ETAvPr[market]/1e6
    end
  end

end

function PermitsForExistingPlants(data::Data,market,unit,ecc,polls,pcov,area)
  (; ECC,PCov) = data
  (; ExYear,RREx,PGratEx,UnPGratis,UnRR,UnOnLine) = data

  if UnOnLine[unit] <= ExYear[market]
    for poll in polls
      PGratEx[ecc,poll,pcov,area] = PGratEx[ecc,poll,pcov,area]+UnPGratis[unit,poll]
      RREx[ecc,poll,pcov,area] = RREx[ecc,poll,pcov,area]+UnRR[unit,poll]
    end
  end

end

function PermitsForNewPlants(data::Data,market,unit,ecc,polls,pcov,area)
  (; year) = data
  (; ECC,PCov,Yrv) = data
  (; RRNew,PGratNew,UnPGratis,UnRR,UnOnLine) = data

  if UnOnLine[unit] <= Yrv[year]
    for poll in polls
      PGratNew[ecc,poll,pcov,area] = PGratNew[ecc,poll,pcov,area]+UnPGratis[unit,poll]
      RRNew[ecc,poll,pcov,area] = RRNew[ecc,poll,pcov,area]+UnRR[unit,poll]
    end
  end

end

function PermitsWhichAreOutputBased(data::Data,market,unit,ecc,polls,pcov,area)
  (; CTime) = data
  (; Area,ECC,FuelEP,FuelEPs,PCov,Poll) = data
  (; UnArea,UnCode,UnCogen) = data
  (; ECCMarket,CapTrade,PGratisOBPS,UnFlFr,UnGP,UnOffsets,UnEGA,UnPGratis) = data
 
 @debug "EPollutiuon.jl - SavePermitsOrUseExogenous"
 
 
  if (ECCMarket[ecc,market] == 1) && (CapTrade[market] == 5)
    
    for poll in polls
      UnPGratis[unit,poll] = (sum(UnFlFr[unit,fuelep]*
        UnGP[unit,fuelep,poll] for fuelep in FuelEPs)+ 
        UnOffsets[unit,poll])*UnEGA[unit]    
    end
    
    for poll in polls
      PGratisOBPS[ecc,poll,pcov,area] = PGratisOBPS[ecc,poll,pcov,area]+ 
        UnPGratis[unit,poll] 
    end    
  end
  
  #if market == 142 
  #  poll = Select(Poll,"CO2")
  #  @info " $(PGratisOBPS[ecc,poll,pcov,area]/1e6)  $(UnCode[unit])   $(UnPGratis[unit,poll])"
  #  #@info "  $(UnArea[unit]) $(ECC[ecc]) $(UnCogen[unit])"
  #  #@info "  $(Area[area]) $(ECC[ecc]) $(PCov[pcov]) "
  #end
  

end

function PermitsForCogenUnits(data::Data)
  (; Areas,Polls,FuelEPs) = data
  (; CgPGratis,UnEGAPrior,UnFlFr,UnGP,UnPGratis) = data

  WhichUnCounter = "UsePrior"
  units = GetCogenUnits(data,WhichUnCounter)

  for unit in units
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid  
    
      for poll in Polls
        UnPGratis[unit,poll] = sum(UnFlFr[unit,fuelep]*
          UnGP[unit,fuelep,poll] for fuelep in FuelEPs)*UnEGAPrior[unit]
      end
      
      for poll in Polls
        CgPGratis[ecc,poll,area] = CgPGratis[ecc,poll,area]+UnPGratis[unit,poll]
      end
    end
  end
end

function SavePermitsOrUseExogenous(data::Data,market,ecc,polls,pcov,areas)
  (; CTime) = data
  (; Area,ECC,PCov,Poll) = data
  (; GPEUSw,PGratEx,PGratis,PGratNew,xPGratis,PGratisOBPS) = data

  @debug "EPollutiuon.jl - SavePermitsOrUseExogenous"

  if (GPEUSw[market] == 1) || (GPEUSw[market] == 2)
    for area in areas, poll in polls
      PGratis[ecc,poll,pcov,area] = PGratEx[ecc,poll,pcov,area]+PGratNew[ecc,poll,pcov,area]
    end
  elseif GPEUSw[market] == 4
    for area in areas, poll in polls
      PGratis[ecc,poll,pcov,area] = PGratisOBPS[ecc,poll,pcov,area] 
    end
    PermitsForCogenUnits(data)
  #
  # Gratis Permits are exogenous
  #
  else
    for area in areas, poll in polls
      PGratis[ecc,poll,pcov,area] = xPGratis[ecc,poll,pcov,area]
    end
  end

end

function PutGratisPermits(data::Data)
  (; db,year,CTime) = data
  (; Area,ECC,Poll) = data  
  (; CgPGratis,PGratis,PGratisOBPS,PGratEx,PGratNew,RREx,RRNew,UnPGValue,UnPGratis) = data

  WriteDisk(db,"SOutput/CgPGratis",year,CgPGratis)
  WriteDisk(db,"SOutput/PGratis",year,PGratis)
  WriteDisk(db,"SOutput/PGratisOBPS",year,PGratisOBPS)
  WriteDisk(db,"SOutput/PGratEx",year,PGratEx)
  WriteDisk(db,"SOutput/PGratNew",year,PGratNew)
  WriteDisk(db,"SOutput/RREx",year,RREx)
  WriteDisk(db,"SOutput/RRNew",year,RRNew)
  WriteDisk(db,"EGOutput/UnPGratis",year,UnPGratis)
  WriteDisk(db,"EGOutput/UnPGValue",year,UnPGValue)
  
end

function InitializeAccumulationVariables(data::Data)
  (; GPVCum,EGCum) = data

  @. GPVCum = 0
  @. EGCum = 0

end

function AccumulatePermitsValue(data::Data,unit,genco,plant)
  (; Polls) = data
  (; GPVCum,UnGC,UnPGValue) = data

  @finite_math GPVCum[plant,genco] = GPVCum[plant,genco]+
    sum(UnPGValue[unit,poll] for poll in Polls)*UnGC[unit]/UnGC[unit]
end

function AccumulatePermitsGeneration(data::Data,unit,genco,plant)
  (; EGCum,UnGC,UUnEGA,UUnEGAve) = data
 
  #
  # Note - the "Permit" values are from the last active market - Jeff Amlin 1/28/25
  #
  if UnGC[unit] > 0.0
    EGCum[plant,genco] = EGCum[plant,genco]+
      max(UUnEGA[unit],UUnEGAve[unit],0.000001)*UnGC[unit]/UnGC[unit] 
  end
end

function AveragePermitValue(data::Data)
  (; db,year) = data
  (; GenCos,Plants) = data
  (; AGPV,EGCum,GPVCum) = data

  #
  # Average Gratis Permit Value (AGPV) is the weighted average of
  # Unit Gratis Permit Value (UnPGValue)
  #
  for genco in GenCos, plant in Plants
    @finite_math AGPV[plant,genco] = GPVCum[plant,genco]/EGCum[plant,genco]*1000
  end

  WriteDisk(db,"EOutput/AGPV",year,AGPV)

end

function GratisPermitsByPlantType(data::Data)

  InitializeAccumulationVariables(data)

  WhichUnCounter = "UseCurrent"
  units = GetUtilityUnits(data,WhichUnCounter)

  for unit in units
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid  
      AccumulatePermitsValue(data,unit,genco,plant)
      AccumulatePermitsGeneration(data,unit,genco,plant)
    end
  end

  AveragePermitValue(data)

end

function InitializeUnPRCapacity(data::Data)

  #
  # 23.10.02, LJD: moving functions outside procedure due to Julia differences.
  #

  # Select ECC(UtilityGen)
  # Select Year(Prior)
  # Read Disk(UnRCap,UnRCR)
  # Select Year(Current)

end

function UnitIndicatedReductionCapacity(data::Data)
  (; FuelEPs,Polls,Units) = data
  (; UnPol,UnRICap,UnRM,UnRP) = data

  #
  # Indicated Reduction Capacity (UnRICap) is emissions divided by the reduction
  # multiplier (to give back total embodied emissions) times the pollution
  # reduction (UnRP) which tells how many Tonnes of pollution can be reduced.
  #
  for poll in Polls, fuelep in FuelEPs, unit in Units
    @finite_math UnRICap[unit,fuelep,poll] = UnPol[unit,fuelep,poll]/
      UnRM[unit,fuelep,poll]*UnRP[unit,fuelep,poll]
  end

end

function UnitCapacityInitiationRate(data::Data)
  (; FuelEPs,Polls,Units) = data
  (; UnRCI,UnRICap,UnRCapPrior,EURCD,EURCPL,UnRCRPrior) = data

  #
  # Reduction Capacity Initiation Rate
  #
  for poll in Polls, fuelep in FuelEPs, unit in Units
    @finite_math UnRCI[unit,fuelep,poll] = max(0,UnRICap[unit,fuelep,poll]-
      UnRCapPrior[unit,fuelep,poll]-UnRCRPrior[unit,fuelep,poll]*EURCD[poll]+
      UnRCapPrior[unit,fuelep,poll]/EURCPL[poll])/EURCD[poll]
  end

end

function UnitReductionCapacity(data::Data)
  (; FuelEPs,Polls,Units) = data
  (; UnRCap,UnRCapPrior,UnRCRPrior,EURCPL) = data

  for poll in Polls, fuelep in FuelEPs, unit in Units
    @finite_math UnRCap[unit,fuelep,poll] = UnRCapPrior[unit,fuelep,poll]+DT*
      (UnRCRPrior[unit,fuelep,poll]-UnRCapPrior[unit,fuelep,poll]/EURCPL[poll])
  end

end

function UnitReductionCapacityCompletionRate(data::Data)
  (; FuelEPs,Polls,Units) = data
  (; UnRCI,UnRCR,UnRCRPrior,EURCD) = data

  for poll in Polls, fuelep in FuelEPs, unit in Units
    @finite_math UnRCR[unit,fuelep,poll] = UnRCRPrior[unit,fuelep,poll]+DT*
      (UnRCI[unit,fuelep,poll]-UnRCRPrior[unit,fuelep,poll])/EURCD[poll]
  end

end

function PutUnPRCapacity(data::Data)
  (; db,year) = data
  (; UnRCap,UnRCI,UnRCR,UnRICap) = data

  WriteDisk(db,"EGOutput/UnRCap",year,UnRCap)
  WriteDisk(db,"EGOutput/UnRCI",UnRCI)
  WriteDisk(db,"EGOutput/UnRCR",year,UnRCR)
  WriteDisk(db,"EGOutput/UnRICap",UnRICap)

end

function IndicatedReductionCapacity(data::Data)
  (; Areas,ES,FuelEPs,Plants,Polls) = data
  (; EURICap,EURM,EURP,TFPol) = data

  es = Select(ES,"Electric")

  #
  # Indicated Reduction Capacity (EURICap) is emissions divided by the reduction
  # multiplier (to give back total embodied emissions) times the pollution
  # reduction (EURP) which tells how many Tonnes of pollution can be reduced.
  #
  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    @finite_math EURICap[fuelep,plant,poll,area] = TFPol[es,fuelep,poll,area]/
      EURM[fuelep,plant,poll,area]*EURP[fuelep,plant,poll,area]
  end

end

function ReductionCapacityInitiationRate(data::Data)
  (; Areas,FuelEPs,Plants,Polls) = data
  (; EURCapPrior,EURCI,EURCD,EURCPL,EURCRPrior,EURICap) = data

  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    @finite_math EURCI[fuelep,plant,poll,area] = 
      max(0,EURICap[fuelep,plant,poll,area]-EURCapPrior[fuelep,plant,poll,area]-
      EURCRPrior[fuelep,plant,poll,area]*EURCD[poll]+
      EURCapPrior[fuelep,plant,poll,area]/EURCPL[poll])/EURCD[poll]
  end

end

function EmbeddedReductionCapitalCosts(data::Data)
  (; Areas,FuelEPs,Plants,Polls) = data
  (; EURCC,EURCCEm,EURCCEmPrior,EURCRPrior) = data

  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    EURCCEm[fuelep,plant,poll,area] = EURCCEmPrior[fuelep,plant,poll,area]+
      DT*EURCC[fuelep,plant,poll,area]*EURCRPrior[fuelep,plant,poll,area]
  end

end

function ReductionCapacity(data::Data)
  (; Areas,FuelEPs,Plants,Polls) = data
  (; EURCap,EURCapPrior,EURCPL,EURCRPrior) = data

  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    @finite_math EURCap[fuelep,plant,poll,area] = EURCapPrior[fuelep,plant,poll,area]+
      DT*(EURCRPrior[fuelep,plant,poll,area]-EURCapPrior[fuelep,plant,poll,area]/EURCPL[poll])
  end

end

function ReductionCapacityCompletionRate(data::Data)
  (; Areas,FuelEPs,Plants,Polls) = data
  (; EURCD,EURCI,EURCR,EURCRPrior) = data

  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    @finite_math EURCR[fuelep,plant,poll,area] = EURCRPrior[fuelep,plant,poll,area]+
      DT*(EURCI[fuelep,plant,poll,area]-EURCRPrior[fuelep,plant,poll,area])/EURCD[poll]
  end

end

function PrivateExpensesForPollutionReductions(data::Data)
  (; Areas,ECC,FuelEPs,Plants,Polls) = data
  (; AGFr,EURCC,EURCCEm,EURCR,EUROCF,PRExp) = data

  ecc = Select(ECC,"UtilityGen")

  for area in Areas, poll in Polls
    PRExp[ecc,poll,area] = sum(EURCR[fuelep,plant,poll,area]*
      EURCC[fuelep,plant,poll,area]*(1-AGFr[ecc,poll,area])+
      EURCCEm[fuelep,plant,poll,area]*
      EUROCF[fuelep,plant,poll,area] for plant in Plants, fuelep in FuelEPs)/1e6
  end

end

function GovernmentExpensesForPollutionReductions(data::Data)
  (; Areas,ECC,FuelEPs,Plants,Polls) = data
  (; AGFr,EURCC,EURCR,GRExp,PAdCost) = data

  ecc = Select(ECC,"UtilityGen")

  for area in Areas, poll in Polls
    GRExp[ecc,poll,area] = sum(EURCR[fuelep,plant,poll,area]*
      EURCC[fuelep,plant,poll,area]*AGFr[ecc,poll,area] for plant in Plants, 
      fuelep in FuelEPs)/1e6+PAdCost[ecc,poll,area]
  end

end

function PutPollutionReductionAccounting(data::Data)
  (; db,year) = data
  (; GRExp,PRExp,EURCap,EURCCEm,EURCI,EURCR,EURCap) = data

  WriteDisk(db,"SOutput/GRExp",year,GRExp)
  WriteDisk(db,"SOutput/PRExp",year,PRExp)
  WriteDisk(db,"EGOutput/EURCap",year,EURCap)
  WriteDisk(db,"EGOutput/EURCCEm",year,EURCCEm)
  WriteDisk(db,"EGOutput/EURCI",year,EURCI)
  WriteDisk(db,"EGOutput/EURCR",year,EURCR)
  WriteDisk(db,"EGOutput/EURCap",year,EURCap)

end

function GetUnitsForRqOffsets(data::Data)
  (; UnEmit,UnCogen) = data

  unit_e = Select(UnEmit, >(0.0))
  unit_cg = Select(UnCogen, ==(0.0))
  UnitsForRqOffsets = intersect(unit_e,unit_cg)

  return UnitsForRqOffsets
end

function CheckForOffset(data::Data,unit)
  (; year) = data
  (; Yrv) = data
  (; OffSw,UnOnLine) = data

  area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
  if UnitIsValid  
    UnitNeedsOffset = "False"
    if ((UnOnLine[area] > 2012) || (Yrv[year] >= 2015)) && (OffSw[area] == 1)
      UnitNeedsOffset = "True"
    end
  end

  return UnitNeedsOffset
end

function GenerationFromOutOfStateUnits(data::Data,area)
  (; Area) = data
  (; EGSpImports,UnArea,UnCounter,UnEGA,UnFrImports) = data

  units1 = 1:Int(UnCounter)
  units2 = Select(UnArea,!=(Area[area]))
  units = intersect(units1,units2)
  
  EGSpImports[area] = sum(UnEGA[unit]*UnFrImports[unit,area] for unit in units)

end

function EmissionsFromOutOfStateUnits(data::Data,area)
  (; Area,FuelEPs,Polls) = data
  (; PolSpImport,UnArea,UnCounter,UnPol,UnFrImports) = data

  units1 = 1:Int(UnCounter)
  units2 = Select(UnArea,!=(Area[area]))
  units = intersect(units1,units2)

  for poll in Polls
    PolSpImport[poll,area] = sum(UnPol[unit,fuelep,poll]*
      UnFrImports[unit,area] for fuelep in FuelEPs, unit in units)
  end

end

function AddNonCoalEmissionsFromOutOfStateUnits(data::Data,area)
  (; Area,Polls) = data
  (; OtISw,POCXOthImports,PolSpImport,UnArea,UnCounter,UnEGA,UnPlant,UnFrImports) = data

  if OtISw[area] == 2

    units1 = 1:Int(UnCounter)
    units2 = Select(UnArea,!=(Area[area]))
    units3 = Select(UnPlant,!=("Coal"))
    units = intersect(units1,units2,units3)

    nodex = 1 # POCXOthImports for all NodeX should be the same, this uses example value.

    for poll in Polls
      PolSpImport[poll,area] = PolSpImport[poll,area]+
        sum(UnEGA[unit]*UnFrImports[unit,area] for unit in units)*
          POCXOthImports[poll,nodex,area]
    end
  end

# Do If OtISw eq 2
#   Select Unit*
#   Select Unit If UnArea ne AreaKey
#   Select Unit If UnPlant ne "Coal"
#   PolSpImport(Poll,Area) = PolSpImport(Poll,Area)+
#     sum(Unit)(UnEGA(Unit)*UnFrImports(Unit,Area))*POCXOthImports(Poll,NX,Area)
#   Select Unit*
# End Do If



end

function RenewablePowerImports(data::Data,area)
  (; RnImports,RnGen,RnGoal,RnOption,xRnImports) = data

  if RnOption[area] == 0
    RnImports[area] = xRnImports[area]
  else
    RnImports[area] = max(RnGoal[area]-RnGen[area],0)
  end
end

function SumNetImports(data::Data,area)
  (; ECCs,Fuel,Plants) = data
  (; EGPA,NetImports,PSoECC,SaEC,TDEF) = data

  electric = Select(Fuel,"Electric")

  @finite_math NetImports[area] = sum(SaEC[ecc,area]/TDEF[electric,area] for ecc in ECCs)-
                                  sum(EGPA[plant,area] for plant in Plants)-
                                  sum(PSoECC[ecc,area] for ecc in ECCs)
end

function OtherImports(data::Data,area)
  (; EGSpImports,NetImports,OtImports,RnImports) = data

  OtImports[area] = NetImports[area]-EGSpImports[area]-RnImports[area]
end

function GrossImports(data::Data,area)
  (; Months,Nodes,NodeXs,TimePs) = data
  (; EGSpImports,GrImpAdj,GrImpMult,GrImports) = data
  (; GrImpTot,HDHours,HDLLoad,NdArFr,RnImports) = data

  for nodex in NodeXs
    GrImports[nodex,area] = sum(HDLLoad[node,nodex,timep,month]*
      HDHours[timep,month]*NdArFr[node,area] for month in Months, 
      timep in TimePs, node in Nodes)/1000
  end
  GrImpTot[area] = sum(GrImports[nodex,area] for nodex in NodeXs)

  @finite_math GrImpAdj[area] = max(GrImpTot[area]-EGSpImports[area]-RnImports[area],0)/GrImpTot[area]

  for nodex in NodeXs
    GrImports[nodex,area] = GrImports[nodex,area]*GrImpAdj[area]*GrImpMult[nodex,area]
  end
  
  GrImpTot[area] = sum(GrImports[nodex,area] for nodex in NodeXs)
end

function OtherImportsEmissions(data::Data,area)
  (; NodeXs,Polls) = data
  (; GrImports,OtImports,OtISw,PolOthImports,POCXOthImports,xPolOthImports) = data

  #
  # If Other Import Switch (OtISw) is 1.0, then Other Import Emissions
  # (PolOthImports) are computed from Other Imports (OtImports)
  #
  if (OtISw[area] == 1) || (OtISw[area] == 2)

    nodex = 1 # Uses POCXOthImports from a non-specific node.
    for poll in Polls
      PolOthImports[poll,area] = OtImports[area]*POCXOthImports[poll,nodex,area]+
                                 xPolOthImports[poll,area]
    end

  #
  # Else Other Import Emissions (PolOthImports) are computed from Gross
  # Non-specified Electric Imports (GrImports).
  #
  else
    for poll in Polls
      PolOthImports[poll,area] = sum(GrImports[nodex,area]*POCXOthImports[poll,nodex,area] for nodex in NodeXs)+
                                 xPolOthImports[poll,area]
    end
  end

end

function RenewableImportsEmissions(data::Data,area)
  (; Polls) = data
  (; PolRnImports,RnImports,POCXRnImports) = data

  #
  # Renewable Imports (RnImports) are assigned emissions (PolRnImports)
  # based on the Renewable Emission Coefficient (POCXRnImports)
  #
  for poll in Polls
    PolRnImports[poll,area] = RnImports[area]*POCXRnImports[poll,area]
  end

end

function ImportsEmissions(data::Data,area)
  (; Polls) = data
  (; PolImports,PolOthImports,PolRnImports,PolSpImport) = data

  for poll in Polls
    PolImports[poll,area] = PolSpImport[poll,area]+PolOthImports[poll,area]+PolRnImports[poll,area]
  end

end

function PutImports(data::Data)
  (; db,year) = data
  (; EGSpImports,GrImpAdj,GrImports,GrImpTot,OtImports) = data
  (; NetImports,PolImports,PolOthImports,PolRnImports) = data
  (; PolSpImport,RnImports) = data


  WriteDisk(db,"EGOutput/EGSpImports",year,EGSpImports)
  WriteDisk(db,"EGOutput/GrImpAdj",year,GrImpAdj)
  WriteDisk(db,"EGOutput/GrImports",year,GrImports)
  WriteDisk(db,"EGOutput/GrImpTot",year,GrImpTot)
  WriteDisk(db,"EGOutput/OtImports",year,OtImports)
  WriteDisk(db,"EGOutput/NetImports",year,NetImports)
  WriteDisk(db,"SOutput/PolImports",year,PolImports)
  WriteDisk(db,"EGOutput/PolOthImports",year,PolOthImports)
  WriteDisk(db,"EGOutput/PolRnImports",year,PolRnImports)
  WriteDisk(db,"EGOutput/PolSpImport",year,PolSpImport)
  WriteDisk(db,"EGOutput/RnImports",year,RnImports)
end

function InitializeElectricGenerationEmissions(data::Data)
  (; Areas,ECC,FuelEPs,Polls) = data
  (; EuFPol,EUEuPol,EUMEPol,SqPolCC,SqPolCCPenalty) = data
  (; CgFPolGross,CgFPol,CgPolSq,CgPolSqPenalty) = data

  ecc = Select(ECC,"UtilityGen")

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EuFPol[fuelep,ecc,poll,area] = 0
  end

  @. EUEuPol = 0
  @. EUMEPol = 0

  for area in Areas, poll in Polls
    SqPolCC[ecc,poll,area] = 0
  end

  for area in Areas, poll in Polls
    SqPolCCPenalty[ecc,poll,area] = 0
  end

  #
  # Select ECC*
  #

  #
  # LJD: Unit selections moved out of InitializeElectricGenerationEmissions
  #

  #
  # Select Unit(1-UnCounter)
  # Select Unit If ((UnOnLine le CTime) and (UnRetire gt CTime))
  #
end

function UnitPollution(data::Data,unit,area,ecc,genco,node,plant)
  (; CTime,FuelEP,FuelEPs,Poll,Polls) = data
  (; UnCogen,UnDmd,UnEGA,UnMECX,UnMEPol,UnOUREG) = data
  (; UnPOCA,UnPol,UnPolGross,UnPolSq) = data
  (; UnPolSqPenalty,UnSqFr,UnZeroFr) = data
  
  if UnCogen[unit] == 0
    for poll in Polls, fuelep in FuelEPs
      UnPolGross[unit,fuelep,poll] = UnDmd[unit,fuelep]*UnPOCA[unit,fuelep,poll]
      UnPolSq[unit,fuelep,poll] = UnPolGross[unit,fuelep,poll]*UnSqFr[unit,poll]
      UnPolSqPenalty[unit,fuelep,poll] = UnPolSq[unit,fuelep,poll]*UnOUREG[unit]
      UnPol[unit,fuelep,poll] = UnPolGross[unit,fuelep,poll]*
        (1-UnZeroFr[unit,fuelep,poll])-UnPolSq[unit,fuelep,poll] 
    end
    for poll in Polls
      UnMEPol[unit,poll] = max(UnEGA[unit]*UnMECX[unit,poll],0)
    end
  end

end

function UnitEmissionIntensity(data::Data,unit,area,ecc,genco,node,plant)
  (; FuelEPs,Poll) = data
  (; EICoverage,PolConv,UnEI,UnEGA,UnPol) = data

  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  
  @finite_math UnEI[unit] = 
    sum(UnPol[unit,fuelep,poll]*EICoverage[fuelep,poll,area]*PolConv[poll]
        for poll in polls, fuelep in FuelEPs)/UnEGA[unit]

end

function ElectricUtilityUnitPollution(data::Data,unit,area,ecc,genco,node,plant)
  (; CTime,FuelEP,FuelEPs,Poll,Polls) = data
  (; EuFPol,EUMEPol,EUEuPol,SqPolCC,SqPolCCPenalty) = data
  (; UnCogen,UnMEPol,UnPol,UnPolGross,UnPolSq) = data
  (; UnPolSqPenalty,UnSector,UnZeroFr) = data

  if UnCogen[unit] == 0
    for poll in Polls
      for fuelep in FuelEPs
        EUEuPol[fuelep,plant,poll,area] = EUEuPol[fuelep,plant,poll,area]+
          UnPol[unit,fuelep,poll]    
      end
      
      EUMEPol[plant,poll,area] = EUMEPol[plant,poll,area]+UnMEPol[unit,poll]
      for fuelep in FuelEPs
        EuFPol[fuelep,ecc,poll,area] = EuFPol[fuelep,ecc,poll,area]+
          UnPolGross[unit,fuelep,poll]*(1-UnZeroFr[unit,fuelep,poll])
      end
    end

    if UnSector[unit] == "UtilityGen"
      for poll in Polls
        SqPolCC[ecc,poll,area] = SqPolCC[ecc,poll,area]-
                    sum(UnPolSq[unit,fuelep,poll] for fuelep in FuelEPs)
        SqPolCCPenalty[ecc,poll,area] = SqPolCCPenalty[ecc,poll,area]-
                    sum(UnPolSqPenalty[unit,fuelep,poll] for fuelep in FuelEPs)
      end
    end
  end

end

function PutUnitEmissions(data::Data)
  (; db,year) = data
  (; CgFPolGross,CgFPol,CgPolSq,CgPolSqPenalty,UnEI) = data
  (; UnMEPol,UnPol,UnPolGross,UnPolSq,UnPolSqPenalty) = data

  WriteDisk(db,"EGOutput/UnEI",year,UnEI)
  WriteDisk(db,"EGOutput/UnMEPol",year,UnMEPol)
  WriteDisk(db,"EGOutput/UnPol",year,UnPol)
  WriteDisk(db,"EGOutput/UnPolGross",year,UnPolGross)
  WriteDisk(db,"EGOutput/UnPolSq",year,UnPolSq)
  WriteDisk(db,"EGOutput/UnPolSqPenalty",year,UnPolSqPenalty)
end

function ElectricUtilityFuelRelatedPollution(data::Data)
  (; Areas,ES,FuelEPs,Plants,Polls) = data
  (; EUEuPol,TFPol) = data

  es = Select(ES,"Electric")

  for area in Areas, poll in Polls,fuelep in FuelEPs
    TFPol[es,fuelep,poll,area] = sum(EUEuPol[fuelep,plant,poll,area] for plant in Plants)
  end

end

function ProcessEndogenous(data::Data)
  (; Areas,ECC,Plants,Polls) = data
  (; EUMEPol,MEPol) = data

  ecc = Select(ECC,"UtilityGen")

  for area in Areas, poll in Polls
    MEPol[ecc,poll,area] = sum(EUMEPol[plant,poll,area] for plant in Plants)
  end

end

function FindReductions(data::Data,market,areas,polls)
  (; db,year) = data
  (; Area,ECC,FuelEP,FuelEPs,Plant,Plants,Poll,PCov) = data
  (; ANMap,CapTrade,ECoverage,EUCCR,EUIRP,EUPCostN) = data
  (; EUPVF,EURCC,EURCD,EURCPL,EURCstM,EUROCF,EURP) = data
  (; EURPCSw,EURPPrior,Inflation,PCost,PCostExo) = data
  (; PCostM,PCostOut,RPolicy,xEURM) = data

  RPFull::VariableArray{4} = zeros(Float32,length(FuelEP),length(Plant),length(Poll),length(Area)) #[FuelEP,Plant,Poll,Area] Full Pollutant Reduction (Tonnes/Tonnes)

  ecc = Select(ECC,"UtilityGen")
  pcov = Select(PCov,"Energy")

  #
  # Do if policy is a cap with trading (CapTrade = 1)
  #
  if (CapTrade[market] == 1) || (CapTrade[market] == 3)
    #
    # Capital cost of reduction technology based on the permit cost (PCost)
    #
    for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
      @finite_math EURCC[fuelep,plant,poll,area] = (PCost[fuelep,plant,poll,area]*
        ECoverage[ecc,poll,pcov,area]+PCostExo[fuelep,plant,poll,area])/
        (EUCCR[area]+EUROCF[fuelep,plant,poll,area])*Inflation[area]
    end
    for area in areas
      nations = findall(ANMap[area,:] .== 1)
      for nation in nations
        if ANMap[area,nation] == 1
          for poll in polls, plant in Plants
            #
            # For the Reduction Curves from 2009 (RPCSw=1), the Indicated
            # Reductions (IRP) is a function of the capital costs (RCC)
            # and the Reduction Cost Curve (PCostN, PVF)
            #
            if (EURPCSw[plant,poll,area] == 1)
              for fuelep in FuelEPs
                @finite_math EUIRP[fuelep,plant,poll,area] = log(EURCC[fuelep,plant,poll,area]/
                  Inflation[area]/(EUPCostN[fuelep,plant,poll,area]/PCostM[fuelep,plant,poll,area]/
                  EURCstM[fuelep,plant,poll]))/EUPVF[fuelep,plant,poll,area]*ECoverage[ecc,poll,pcov],area
              end

            #
            # For the Reduction Curves from 2004 (RPCSw=2), the indicated
            # reductions (IRP) are a function of the permit cost (PCost)
            # and the pollution reduction curve parameters (PCostN, PVF)
            # adjusted by the reductions cost multiplier (RCostM) for the
            # covered emissions (PCCov)
            #
            elseif (EURPCSw[plant,poll,area] == 2) 
              for fuelep in FuelEPs
                if ((PCost[fuelep,plant,poll,area] != 0) || 
                    (PCostExo[fuelep,plant,poll,area] != 0)) &&
                  (EUPCostN[fuelep,plant,poll,area] != 0) && 
                  (EUPVF[fuelep,plant,poll,area] != 0)

                  @finite_math EUIRP[fuelep,plant,poll,area] = 1/(1+((max((PCost[fuelep,plant,poll,area]*
                    ECoverage[ecc,poll,pcov,area]+PCostExo[fuelep,plant,poll,area])*
                    PCostM[fuelep,plant,poll,area],0.01)*EURCstM[fuelep,plant,poll])/
                    EUPCostN[fuelep,plant,poll,area])^EUPVF[fuelep,plant,poll,area])
                end
              end
            end
          end
        end
      end
    end

    WriteDisk(db,"EGOutput/EUIRP",year,EUIRP)

    #
    # Indicated reductions (EUIRP) become actual reductions (EURP)
    # after a construction delay (EURCD)
    #
    for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
      @finite_math EURP[fuelep,plant,poll,area] = EURPPrior[fuelep,plant,poll,area]+
        (EUIRP[fuelep,plant,poll,area]-EURPPrior[fuelep,plant,poll,area])/EURCD[poll]
    end
    #
    # Actural Reductions (EURP) are
    # increased by changes in Indicated Reductions (EUIRP) and the construction time(EURCD)
    # and reduced by the physical lifetime (EURCPL).
    #
    for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
      @finite_math EURP[fuelep,plant,poll,area] = EURPPrior[fuelep,plant,poll,area]+
        (max(EURPPrior[fuelep,plant,poll,area],EUIRP[fuelep,plant,poll,area])-EURPPrior[fuelep,plant,poll,area])/EURCD[poll]-
        EURPPrior[fuelep,plant,poll,area]/EURCPL[poll]
    end
    #
    # Pollution Costs (PCostOut) is pollution cost input (PCost)
    #
    for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
      PCostOut[fuelep,plant,poll,area] = PCost[fuelep,plant,poll,area]
    end

  #
  # If system has emissions Cap, but no emissions Trading (CapTrade = 2),
  # then input is the actual reduction (RPolicy)
  #
  elseif (CapTrade[market] == 2) || (CapTrade[market] == 4)
    #
    # Pollution Reduction (EURP) is the reduction policy (RPolicy)
    # times the coverage of the regulations (ECoverage).
    #
    for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
      EURP[fuelep,plant,poll,area] = RPolicy[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]
      RPFull[fuelep,plant,poll,area] = 1-(1-EURP[fuelep,plant,poll,area])*xEURM[fuelep,plant,poll,area]
    end

    for area in areas, poll in polls, plant in Plants
      #
      # For the Reduction Curves from 2009 (RPCSw=1),
      #
      if EURPCSw[plant,poll,area] == 1
        for fuelep in FuelEPs
          @finite_math EURCC[fuelep,plant,poll,area] = (EUPCostN[fuelep,plant,poll,area]/EURCstM[fuelep,plant,poll])*exp(EUPVF[fuelep,plant,poll,area]*RPFull[fuelep,plant,poll,area])*Inflation[area]
        end

      #
      # For the Reduction Curves from 2004 (RPCSw=2), the capital cost of
      # the reduction technology (EURCC) is based on the reduction (EURP)
      # and the reduction curve parameters (EUPCostN, EUPVF) adjusted by
      # the reductions cost multiplier (EURCstM).
      #
      elseif EURPCSw[plant,poll,area] == 2
        for fuelep in FuelEPs
          @finite_math EURCC[fuelep,plant,poll,area] = (1/RPFull[fuelep,plant,poll,area]-1)^(1/EUPVF[fuelep,plant,poll,area])*EUPCostN[fuelep,plant,poll,area]/EURCstM[fuelep,plant,poll]/(EUCCR[area]+EUROCF[fuelep,plant,poll,area])*Inflation[area]
        end
      end

    end

    #
    # Permit Cost as Output (PCostOut)
    #
    for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
      @finite_math PCostOut[fuelep,plant,poll,area] = EURCC[fuelep,plant,poll,area]*(EUCCR[area]+EUROCF[fuelep,plant,poll,area])/Inflation[area]
    end

  #
  # Else CapTrade equals 5 for the GHG markets
  #
  elseif (CapTrade[market] == 5)
    for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
      #
      # There are currently no reduction curves for GHG so just apply
      # permit cost (PCost) to covered sectors (ECoverage) less the
      # impact of gratis permits.
      #
      EURP[fuelep,plant,poll,area] = 0
      EURCC[fuelep,plant,poll,area] = 0

      #
      # Pollution Costs as Output (PCostOut)
      PCostOut[fuelep,plant,poll,area] = PCost[fuelep,plant,poll,area]*
                                       ECoverage[ecc,poll,pcov,area]
      #
      # PCostOut=PCost*ECoverage*(1-GPFrac) # Commented out in Promula
      #    
    end

  end

end

function FindCrossMultiplier(data::Data)
  (; Areas,FuelEPs,Plants,Polls) = data
  (; EURM,EURP,EUVR,xEURM) = data

  #
  # Reduction in come Pollutants cause reductions in other Pollutants.
  # This relationship is specified in the cross multiplier (EUCM).
  #
  # ? EURPXP(FuelEP,P,xP,Area)=EUCM(FuelEP,P,xP)*EURP(FuelEP,P,Area)
  #
  # Find net reduction multiplier (EURM) including the cross impacts (EURPXP)
  # and the volunatry reductions (EUVR).
  #
  # ? EURM(FuelEP,P,Area)=PRODUCT(xP)(1-EURPXP(FuelEP,P,xP,Area))*
  # ?                               (1-EUVR(FuelEP,P,Area))
  #
  #  ?? Temporarily leave out cross impacts
  #
  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    EURM[fuelep,plant,poll,area] = (1-EURP[fuelep,plant,poll,area])*(1-EUVR[fuelep,plant,poll,area])*xEURM[fuelep,plant,poll,area]
  end

end

function PutPRReductions(data::Data)
  (; db,year) = data
  (; EURCC,EURM,EURP,EUVR,PCostOut) = data

  WriteDisk(db,"EGOutput/EURCC",year,EURCC)
  WriteDisk(db,"EGOutput/EURM",year,EURM)
  WriteDisk(db,"EGOutput/EURP",year,EURP)
  WriteDisk(db,"EGOutput/EUVR",year,EUVR)
  WriteDisk(db,"EGOutput/PCostOut",year,PCostOut)
end

function PRReductions(data::Data)
  (; db,year) = data
  (; Areas,ECC,FuelEPs,Markets,PCov,Plants,Polls) = data
  (; EUVR,EUVRPrior,EUVRP,EUVRRT) = data

  #@info "  EPollution.jl - PRReductions"

  #
  # This procedure computes the emission reductions (EURM)
  # for each generic plant type.
  #
  # Reduction Policy
  #
  ecc = Select(ECC,"UtilityGen")
  pcov = Select(PCov,"Energy")
  #
  # Voluntary reductions are based on exogenous goal and time lag.
  #
  for area in Areas, poll in Polls, plant in Plants, fuelep in FuelEPs
    @finite_math EUVR[fuelep,plant,poll,area] = EUVRPrior[fuelep,plant,poll,area]+
      DT*(EUVRP[fuelep,plant,poll,area]-EUVRPrior[fuelep,plant,poll,area])/EUVRRT[fuelep,plant]
  end
  #
  # If system has an emission Cap and emissions Trading (CapTrade = 1 or 3),
  # then the input is the permit cost (PCost).
  #
  for market in Markets
    areas,polls,ActiveMarket = GetMarketParameters(data,market)

    if ActiveMarket == "True"
      FindReductions(data,market,areas,polls)
    end

  end

  FindCrossMultiplier(data)

  PutPRReductions(data)
end

function UnCurve(data::Data,unit,poll,plant,area)
  (; FuelEPs) = data
  (; EURCC,EURP,UnRCC,UnRP) = data

  #@info "  EPollution.jl - UnCurve"

  #
  # This procedure transfers the plant type reduction (EURP) and
  # emission control capital cost (EURCC) the each of the individual
  # units (UnRP, UnRCC) based on the plant type and area.
  #
  # Pollution Reduction Multiplier
  #
  for fuelep in FuelEPs
    UnRP[unit,fuelep,poll] = EURP[fuelep,plant,poll,area]
  end

  #
  # Pollution Reduction Capital Cost
  #
  for fuelep in FuelEPs
    UnRCC[unit,fuelep,poll] = EURCC[fuelep,plant,poll,area]
  end

end

function UnReduce(data::Data,unit,poll,plant,area)
  (; FuelEPs) = data
  (; EUCCR,EUPCostN,EUPVF,EURCstM,EUROCF,EURP,EURPCSw,InflationUnit,UnRCC,UnRP,xUnRCC,xUnRP) = data

  #@info "  EPollution.jl - UnReduce"
  #
  # In this procedure the emission reduction for each unit is
  # exogenous (xUnRP) while the emission control capital cost
  # curve (EUPCostN, EUPVF) is defined by plant type.
  #
  # Pollution Reduction Multiplier
  #
  for fuelep in FuelEPs
    UnRP[unit,fuelep,poll] = max(EURP[fuelep,plant,poll,area],xUnRP[unit,fuelep,poll])
  end

  #
  # Pollution Reduction Capital Cost
  #
  # For the Reduction Curves from 2009 (RPCSw=1),
  #
  if (EURPCSw[plant,poll,area] == 1) && (UnRP[plant,poll,area] < 0.00)
    for fuelep in FuelEPs
      @finite_math UnRCC[unit,fuelep,poll] = (EUPCostN[fuelep,plant,poll,area]/EURCstM[fuelep,plant,poll])*exp(EUPVF[fuelep,plant,poll,area]*UnRP[unit,fuelep,poll])*InflationUnit[unit]
    end

    #
    # For the Reduction Curves from 2004 (RPCSw=2), the capital cost of
    # the reduction technology (EURCC) is based on the reduction (EURP)
    # and the reduction curve parameters (EUPCostN, EUPVF) adjusted by
    # the reductions cost multiplier (EURCstM).
    #
  elseif (EURPCSw == 2) && (UnRP[plant,poll,area] > 0.00)
    for fuelep in FuelEPs
      @finite_math UnRCC[unit,fuelep,poll] = (1/UnRP[unit,fuelep,poll]-1)^(1/EUPVF[fuelep,plant,poll,area])*EUPCostN[fuelep,plant,poll,area]/EURCstM[fuelep,plant,poll]/(EUCCR[area]+EUROCF[fuelep,plant,poll,area])*InflationUnit[unit]
    end

    #
    # No reduction is required (UnRP=0.00)
    #
  else
    for fuelep in FuelEPs
      UnRCC[unit,fuelep,poll] = 0.00
    end
  end

  #
  # Exogenous Capital Costs (we need to add more switches-JSA 9/11/12)
  #
  # 23.09.28, LJD: #TODOJulia ">=0" rather than ">0" makes me somewhat nervous, 
  # since 0 is a default value for most variables, and this could easily wipe things out. 
  #
  for fuelep in FuelEPs
    if xUnRCC[unit,fuelep,poll] >= 0.0
      UnRCC[unit,fuelep,poll] = xUnRCC[unit,fuelep,poll]*InflationUnit[unit]
    end
  end

end

function UnPReductions(data::Data)
  (; db,year) = data
  (; FuelEPs,Polls) = data
  (; EUVR,UnCounterPrior,UnEmit,UnRCC,UnRM,UnRP,UnPRSw) = data

  #@info "  EPollution.jl - UnPReductions"

  for unit in 1:Int(UnCounterPrior)
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid 
      if UnEmit[unit] > 0
        for poll in Polls
          if UnPRSw[unit,poll] == 1
            UnCurve(data,unit,poll,plant,area)
          elseif  UnPRSw[unit,poll] == 2
            UnReduce(data,unit,poll,plant,area)
          end
        end
      end
      
      for poll in Polls, fuelep in FuelEPs
        UnRM[unit,fuelep,poll] = (1-UnRP[unit,fuelep,poll])*
                                 (1-EUVR[fuelep,plant,poll,area]) 
      end
    end
  end


  WriteDisk(db,"EGOutput/UnRCC",year,UnRCC)
  WriteDisk(db,"EGOutput/UnRM",year,UnRM)
  WriteDisk(db,"EGOutput/UnRP",year,UnRP)

end

function PolCoefficients(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuels,FuelEPs,Plants,Poll,Polls,Unit) = data
  (; BCarbonSw,BCMult,BCMultProcess,FFPMap,POCX) = data
  (; PolConv,UnDmdPrior,PollLimitGHGFlag) = data
  (; UnCounterPrior,UnEGAPrior,UnFlFr,UnHRt,UnMECX,UnPOCA,UnPOCGWh) = data
  (; UnPOCX,UnRM,UnSqFr,UnZeroFr,UnPOCNet) = data
  TempUP1::VariableArray{2} = zeros(Float32,length(Unit),length(Poll))
  TempUP2::VariableArray{2} = zeros(Float32,length(Unit),length(Poll))

  #@info "  EPollution.jl - PolCoefficients"

  bc = Select(Poll,"BC")
  pm25 = Select(Poll,"PM25")
  units = 1:Int(UnCounterPrior)

  #
  # Pollution Coefficient (UnPOCA) is the normal coefficient (UnPOCX)
  # times the Pollution Reduction Multiplier (UnRM).
  #
  for poll in Polls, fuelep in FuelEPs, unit in units
    UnPOCA[unit,fuelep,poll] = UnPOCX[unit,fuelep,poll]*UnRM[unit,fuelep,poll]
  end

  #
  # Black Carbon (BC) is a function of PM 2.5 (PM25).
  #
  if BCarbonSw == 1
    ecc = Select(ECC,"UtilityGen")
    for fuel in Fuels, fuelep in FuelEPs
      if FFPMap[fuelep,fuel] == 1.0
        for area in Areas, plant in Plants
          POCX[fuelep,plant,bc,area] = POCX[fuelep,plant,pm25,area]*BCMult[fuel,ecc,area]
        end
      end
    end

    for unit in units
      area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
      if UnitIsValid 
        ecc = Select(ECC,"UtilityGen")
        for fuel in Fuels, fuelep in FuelEPs
          if FFPMap[fuelep,fuel] == 1.0
            UnPOCX[unit,fuelep,bc] = UnPOCX[unit,fuelep,pm25]*BCMult[fuel,ecc,area]
            UnPOCA[unit,fuelep,bc] = UnPOCA[unit,fuelep,pm25]*BCMult[fuel,ecc,area]
          end
        end
        UnMECX[unit,bc] = UnMECX[unit,pm25]*BCMultProcess[ecc,area]
      end
    end

    WriteDisk(db,"EGInput/POCX",year,POCX)
    WriteDisk(db,"EGInput/UnMECX",year,UnMECX)
    WriteDisk(db,"EGInput/UnPOCX",year,UnPOCX)

  end

  WriteDisk(db,"EGOutput/UnPOCA",year,UnPOCA)

  #
  # Estimate Emission Coefficient per MWh
  #
  for poll in Polls, unit in units
    for fuelep in FuelEPs
      UnPOCNet[unit,fuelep,poll] = UnPOCA[unit,fuelep,poll]*(1-UnSqFr[unit,poll])*(1-UnZeroFr[unit,fuelep,poll])
    end
    @finite_math TempUP1[unit,poll] = sum(UnDmdPrior[unit,fuelep]*UnPOCNet[unit,fuelep,poll] for fuelep in FuelEPs)/UnEGAPrior[unit]
    TempUP2[unit,poll] = sum(UnHRt[unit]*UnFlFr[unit,fuelep]*UnPOCNet[unit,fuelep,poll]/1e6 for fuelep in FuelEPs)
    UnPOCGWh[unit,poll] = max(TempUP1[unit,poll],TempUP2[unit,poll])
  end

  #
  # For GHG Emission Limits store all GHG emissions in CO2
  #
  CO2 = Select(Poll,"CO2")
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  for unit in units
    UnPOCGWh[unit,CO2] = sum(UnPOCGWh[unit,poll]*PolConv[poll] for poll in polls)
  end 
  polls = Select(Poll,["CH4","N2O","SF6","PFC","HFC"])      
  for poll in polls, unit in units
    UnPOCGWh[unit,poll] = 0
  end

  WriteDisk(db,"EGOutput/UnPOCGWh",year,UnPOCGWh)

end

function NewPlantEmissionTargets(data::Data,market)
  (; db,year) = data
  (; FuelEPs,Plants) = data
  (; GPNew,xGPNew) = data

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # New plant "effective" emission targets (GPNew) are equal to
  # intensity targets for new plants (xGPNew).  This is an "effective"
  # number because the emissions target may vary through time, but we
  # need a single value when deciding whether or not to build a
  # particular this type of plant.
  #
  for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
    GPNew[fuelep,plant,poll,area] = xGPNew[fuelep,plant,poll,area]
  end

  WriteDisk(db,"EGOutput/GPNew",year,GPNew)

end

function NewPlantEmissionCharges(data::Data,market)
  (; db,year) = data
  (; FuelEPs,Plants) = data
  (; ETAPr,ExchangeRate,GPNew,HRtM,OffNew) = data
  (; OffValue,POCX,PolConv,PoTxRNew,PoTxRNewGross) = data
  (; PoTxRNewSq,SqFr,ZeroFr) = data

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # New plant emissions cost (PoTxRNew) are the cost of permits (ETAPr)
  # times the emissions intensity (POCX) less the level of gratis
  # permits (GPNew).
  #
  for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs
    PoTxRNewGross[fuelep,plant,poll,area] = ETAPr[market]*(POCX[fuelep,plant,poll,area]*HRtM[plant,area]*PolConv[poll]-GPNew[fuelep,plant,poll,area]*1e6)*ExchangeRate[area]/1e9
    PoTxRNewSq[fuelep,plant,poll,area] = PoTxRNewGross[fuelep,plant,poll,area]*SqFr[plant,poll,area]
    PoTxRNew[fuelep,plant,poll,area] = PoTxRNewGross[fuelep,plant,poll,area]*(1-ZeroFr[fuelep,poll,area])-PoTxRNewSq[fuelep,plant,poll,area]
  end

  for area in areas, poll in polls, plant in Plants
    OffValue[plant,poll,area] = ETAPr[market]*OffNew[plant,poll,area]*ExchangeRate[area]/1000
  end

  WriteDisk(db,"EGOutput/OffValue",year,OffValue)
  WriteDisk(db,"EGOutput/PoTxRNew",year,PoTxRNew)
  WriteDisk(db,"EGOutput/PoTxRNewGross",year,PoTxRNewGross)
  WriteDisk(db,"EGOutput/PoTxRNewSq",year,PoTxRNewSq)
end

function TransmissionCosts(data::Data,market)
  (; db,year) = data
  (; Nodes,NodeXs) = data
  (; ETAPr,LLPOCX,LLPoTxR) = data

  #
  # Transmission Costs (LLPoTxR) are Transmission "Emissions" (LLPOCX) times
  # the Emission Cost (ETAPr).  Transmission "Emissions" (LLPOCX) is used to
  # for a boundary around a specific area to reduce leakage.
  #
  for nodex in NodeXs, node in Nodes
    LLPoTxR[node,nodex,market] = LLPOCX[node,nodex,market]*ETAPr[market]/1000
  end

  WriteDisk(db,"EGOutput/LLPoTxR",year,LLPoTxR)

end

function AllPollutantEmissionCharges(data::Data)
  (; db, year) = data
  (; FuelEPs,Polls,Units) = data
  (; UnEGAPrior, UnFlFr, UnOffValue, UnPoTR, UnPoTxR, UnPExp) = data
 
  for unit in Units
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid  

      #
      # Calculate total emission charge rate
      #
      UnPoTR[unit] = sum(UnPoTxR[unit,fuelep,poll]*UnFlFr[unit,fuelep]
                         for poll in Polls, fuelep in FuelEPs)-
                     sum(UnOffValue[unit,poll] for poll in Polls)
  
      #
      # Calculate emission charge in millions of dollars
      #
      UnPExp[unit] = UnPoTR[unit]*UnEGAPrior[unit]/1000
    end
  end
 
  WriteDisk(db,"EGOutput/UnPoTR",year,UnPoTR)
  WriteDisk(db,"EGOutput/UnPExp",year,UnPExp)
end

function NewUnitEmissionCharges(data::Data)
  (; db,year) = data
  (; Areas,FuelEPs,Plants,Polls) = data
  (; FlFrNew,OffValue,PoTRNew,PoTxRNew) = data

  for area in Areas, plant in Plants
    PoTRNew[plant,area] = sum(PoTxRNew[fuelep,plant,poll,area]*
      FlFrNew[fuelep,plant,area] for poll in Polls, fuelep in FuelEPs)-
      sum(OffValue[plant,poll,area] for poll in Polls)
  end

  WriteDisk(db,"EGOutput/PoTRNew",year,PoTRNew)

end

#
# New Unit Gratis Permits
#
function CheckIfUnitIsNewPlant(data::Data,market,unit)
  (; ExYear,CTime,UnOnLine) = data

  #
  # New plants are defined as ones coming on-line (UnOnLine) after the
  # "existing" year (ExYear) and before the current year (CTime).
  #
  UnitIsNewPlant = "False"
  if (UnOnLine[unit] > ExYear[market]) && (UnOnLine[unit] < CTime)
    UnitIsNewPlant = "True"
  end

  return UnitIsNewPlant

end

function CurrentAgeOfPlant(data::Data,unit)
  (; CTime,UnOnLine) = data

  UnAge = Int(CTime-UnOnLine[unit]+1)

  return UnAge
end

function NewPlantsGratisPermits(data::Data,market,unit,UnAge,area,ecc,genco,node,plant)
  (; FuelEPs,year) = data
  (; PolConv,TargNew,UnGP,UnHRt,UnPOCA) = data

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # If GPEUSw equals 2 - New plants are given gratis permits based on
  # their initial emissions (UnPOCA) times a reduction schedule (TargNew) based
  # on their age (UnAge)
  #

  for poll in polls, fuelep in FuelEPs
    UnGP[unit,fuelep,poll] = UnPOCA[unit,fuelep,poll]*PolConv[poll]*UnHRt[unit]/1e6*
                                (1-TargNew[market,year])
  end

end

function NewPlantsExogenousGratisPermits(data::Data,market,unit,area,ecc,genco,node,plant)
  (; FuelEPs) = data
  (; UnGP,xGPNew) = data

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # If GPEUSw equals 0 - New plants are given an exogenous amount of
  # gratis permts (xGPNew)
  #
  for poll in polls, fuelep in FuelEPs
    UnGP[unit,fuelep,poll] = xGPNew[fuelep,plant,poll,area]
  end

end

function CleanFuelStandard(data::Data,market,unit,UnAge,area,ecc,genco,node,plant)
  (; FuelEPs) = data
  (; CFStd,GracePd,UnGP,UnPOCA,PolConv,UnHRt) = data

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # New facilities must generally meet the Clean Fuel Standard based
  # on the age and plant type of the facility.
  #

  #
  # TODOJulia test if this use of UnAge as an Index for year is appropriate.
  #
  for poll in polls, fuelep in FuelEPs
    UnGP[unit,fuelep,poll] = CFStd[fuelep,plant,poll,area,UnAge]
  end

  #
  # However, if there is a grace period (GracePD), then the new
  # plants have no emissions intensity target during those years.
  # This code is used for the MultiClient study.
  #

  if UnAge <= GracePd[market]
    for poll in polls, fuelep in FuelEPs
      UnGP[unit,fuelep,poll] = UnPOCA[unit,fuelep,poll]*PolConv[poll]*UnHRt[unit]/1e6
    end
  end

end

function UnitGratisPermits(data::Data,market,unit,area,ecc,genco,node,plant)
  (; Poll,Polls,FuelEPs) = data
  (; GPEUSw,UnGP,xUnGP) = data
 
  UnitIsNewPlant = CheckIfUnitIsNewPlant(data, market, unit)
  
  if UnitIsNewPlant == "True"
    UnAge = CurrentAgeOfPlant(data,unit)
    if GPEUSw[market] == 1
      CleanFuelStandard(data,market,unit,UnAge,area,ecc,genco,node,plant)
    elseif GPEUSw[market] == 2
      NewPlantsGratisPermits(data,market,unit,UnAge,area,ecc,genco,node,plant) 
    else
      NewPlantsExogenousGratisPermits(data,market,unit,area,ecc,genco,node,plant)
    end
  else
    for poll in Polls, fuelep in FuelEPs
      UnGP[unit,fuelep,poll] = xUnGP[unit,fuelep,poll]
    end
  end
end

#
# Unit Emissions Charges
#

function UnitOffsetValue(data::Data,market,unit)
  (; ETAPr,ExchangeRateUnit,UnCoverage,UnOffsets,UnOffValue) = data

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # UnOffValue($/MWh)=ETAPr($/Tonne)*UnOffsets(Tonne/GWh)/1000(MWh/GWh)
  #
  for poll in polls
    UnOffValue[unit,poll] = ETAPr[market]*UnOffsets[unit,poll]/1000*ExchangeRateUnit[unit]*UnCoverage[unit,poll]
                            ExchangeRateUnit[unit]*UnCoverage[unit,poll]
  end

end

function AverageEmissionCharges(data::Data,market,unit)
  (; FuelEPs) = data
  (; ETAPr,ExchangeRateUnit,PolConv,UnCoverage,UnGP,UnHRt,UnPoTAv,UnPOCNet) = data

  #@info "  EPollution.jl - AverageEmissionCharges"

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # Average Emissions Cost (UnPoTAv) is is the cost of permits (ETAPr)
  # times the emissions intensity (UnPOCNet) adjusted by the level of
  # gratis permits (UnGP).
  #
  for poll in polls, fuelep in FuelEPs
    UnPoTAv[unit,fuelep,poll] = (ETAPr[market]*(UnPOCNet[unit,fuelep,poll]*UnHRt[unit]*PolConv[poll]-
      UnGP[unit,fuelep,poll]*1e6)*ExchangeRateUnit[unit]/1e9)*UnCoverage[unit,poll]
  end

end

function MarginalEmissionCharges(data::Data,market,unit)
  (; FuelEPs) = data
  (; ETAPr,ExchangeRateUnit,FacSw,PolConv,UnCoverage,UnHRt,UnPOCA,UnPoTAv,UnPoTxR,UnZeroFr) = data

  #@info "  EPollution.jl - MarginalEmissionCharges"

  areas,polls,ActiveMarket = GetMarketParameters(data,market)

  #
  # For intensity targets above the facility level, the Marginal
  # Emissions Cost (UnPoTxR) is the cost of permits (ETAPr)
  # times the emissions intensity (UnPOCA).
  #
  for poll in polls, fuelep in FuelEPs
    UnPoTxR[unit,fuelep,poll] = (ETAPr[market]*(UnPOCA[unit,fuelep,poll]*(1-UnZeroFr[unit,fuelep,poll])*UnHRt[unit]*PolConv[poll])*ExchangeRateUnit[unit]/1e9)*UnCoverage[unit,poll]
  end

  #
  # If there is a facility level intensity target (FacSw == 1),
  # then the Marginal Emissions Cost (UnPoTxR) is the Average
  # Emissions Costs (UnPoTAv).
  #
  # Assume facility level intensity target - Jeff Amlin 3/17/25
  #
  FacSw[market] = 1
  if FacSw[market] == 1
    for poll in polls, fuelep in FuelEPs
      UnPoTxR[unit,fuelep,poll] = UnPoTAv[unit,fuelep,poll]
    end
  end

end

function EmissionChargesForUtilityUnits(data::Data)
  (; db, year) = data
  (; EUPExp, UnPExp) = data
 
  @. EUPExp = 0
 
  WhichUnCounter = "UsePrior"
  units = GetUtilityUnits(data, WhichUnCounter)
 
  for unit in units
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid      
      EUPExp[area] = EUPExp[area]+UnPExp[unit]
    end
  end
 
  WriteDisk(db,"SOutput/EUPExp",year,EUPExp)
end

function EmissionChargesForCogenUnits(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,FuelEP,FuelEPs,Polls) = data
  (; CgPCost,CgPoCst,GPEUSw,UnDmd,UnEGAPrior,UnGP,UnPExp,UnFlFr,UnPoTxR) = data
  (; CgPExp) = data

  CgDmdECC::VariableArray{3} = zeros(Float32,length(FuelEP),length(ECC),length(Area)) #cratch Variable to Accumulate Cogen Demands (TBtu/Yr)
  @. CgPExp = 0  
  @. CgPoCst = 0  

  WhichUnCounter = "UsePrior"
  units = GetCogenUnits(data, WhichUnCounter)
 
  for unit in units
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid    
 
      CgPExp[ecc,area] = CgPExp[ecc,area] + UnPExp[unit]
 
      for fuelep in FuelEPs
        CgPoCst[fuelep,ecc,area] = CgPoCst[fuelep,ecc,area]+ 
          sum(UnPoTxR[unit,fuelep,poll]*UnEGAPrior[unit]*
              UnFlFr[unit,fuelep] for poll in Polls)/1000
        CgDmdECC[fuelep,ecc,area] = CgDmdECC[fuelep,ecc,area]+UnDmd[unit,fuelep]
      end
    end
  end
 
  for area in Areas, ecc in ECCs, fuelep in FuelEPs
    @finite_math CgPCost[fuelep,ecc,area] = 
      CgPoCst[fuelep,ecc,area]/CgDmdECC[fuelep,ecc,area]
  end
 
  WriteDisk(db,"SOutput/CgPExp",year,CgPExp)
  WriteDisk(db,"SOutput/CgPoCst",year,CgPoCst)
  WriteDisk(db,"SOutput/CgPCost",year,CgPCost)
end

function PutPollutionCost(data::Data)
  (; db, year) = data
  (; UnGP, UnOffValue, UnPoTR, UnPoTxR) = data
 
  WriteDisk(db,"EGOutput/UnGP",year,UnGP)
  WriteDisk(db,"EGOutput/UnOffValue",year,UnOffValue)
  WriteDisk(db,"EGOutput/UnPoTR",year,UnPoTR) 
  WriteDisk(db,"EGOutput/UnPoTxR",year,UnPoTxR)
end

function PollutionCost(data::Data)
  (; db,year) = data
  (; ECC,FuelEPs,Markets,PCov) = data
  (; AreaMarket,ECCMarket,UnCoverage,UnCounterPrior,UnGP,xUnGP,UnPoTAv) = data

  for market in Markets
    #
    # Select Energy Emissions (PCov(Energy)) for electric generation (ECC(UtilityGen))
    #
    ecc = Select(ECC,"UtilityGen")
    pcov = Select(PCov,"Energy")

    areas,polls,ActiveMarket = GetMarketParameters(data,market)

    if ActiveMarket == "True"
      #
      #   For each Unit which is in the Market Area
      #
      for unit in 1:Int(UnCounterPrior)
        area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
        if UnitIsValid       
          UnCover = maximum(UnCoverage[unit,poll] for poll in polls)
          if (AreaMarket[area,market] == 1) && (ECCMarket[ecc,market] == 1) && (UnCover > 0)
            UnitGratisPermits(data,market,unit,area,ecc,genco,node,plant)
            UnitOffsetValue(data,market,unit)
            AverageEmissionCharges(data,market,unit)
            MarginalEmissionCharges(data,market,unit)
          end
        end

      end

      NewPlantEmissionTargets(data,market)
      NewPlantEmissionCharges(data,market)
      TransmissionCosts(data,market)
      WriteDisk(db,"EGOutput/UnGP",year,UnGP)
      WriteDisk(db,"EGOutput/UnPoTAv",year,UnPoTAv)
    end
  end

  NewUnitEmissionCharges(data)
  AllPollutantEmissionCharges(data)
  EmissionChargesForUtilityUnits(data)
  EmissionChargesForCogenUnits(data)
  PutPollutionCost(data)

end

function EndogenousEmissions(data::Data)
  (; CTime) = data
  (; Areas,ECC,Polls) = data
  (; SqPolCC,SqPolCCNet,SqPolCCPenalty,UnCounter,UnOnLine,UnRetire) = data

  InitializeElectricGenerationEmissions(data)

  #
  # Unit selections moved out of InitializeElectricGenerationEmissions
  #
  for unit in 1:Int(UnCounter)
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid    
      if (UnOnLine[unit] <= CTime) && (UnRetire[unit] >= CTime)
      
        UnitPollution(data,unit,area,ecc,genco,node,plant)
        UnitEmissionIntensity(data,unit,area,ecc,genco,node,plant)
        ElectricUtilityUnitPollution(data,unit,area,ecc,genco,node,plant)
      
      end
    end
  end

  ecc = Select(ECC,"UtilityGen")

  for area in Areas, poll in Polls
    SqPolCCNet[ecc,poll,area] = SqPolCC[ecc,poll,area]-SqPolCCPenalty[ecc,poll,area]
  end

  PutUnitEmissions(data)
  ElectricUtilityFuelRelatedPollution(data)
  ProcessEndogenous(data)

end

function TotalElectricUtilityPollution(data::Data)
  (; Areas,ES,FuelEPs,Polls) = data
  (; TFPol,TSPol) = data

  es = Select(ES,"Electric")

  for area in Areas, poll in Polls
    TSPol[es,poll,area] = sum(TFPol[es,fuelep,poll,area] for fuelep in FuelEPs)
  end

end

function PollutionCoefficientByArea(data::Data)
  (; Areas,FuelEPs,Plants, Polls) = data
  (; EUDPF,EUPOCX,EUEuPol) = data

  for area in Areas, plant in Plants, poll in Polls, fuelep in FuelEPs
    @finite_math EUPOCX[fuelep,plant,poll,area] = EUEuPol[fuelep,plant,poll,area]/EUDPF[fuelep,plant,area]
  end

end

function GrossPollution(data::Data)
  (; Areas,ECC,FuelEPs,PCov,Plants,Polls) = data
  (; ECoverage,EUEuPol,EURM,GrossPol,MEPol) = data

  ecc = Select(ECC,"UtilityGen")
  energy = Select(PCov,"Energy")
  process = Select(PCov,"Process")

  for area in Areas, poll in Polls
    @finite_math GrossPol[ecc,poll,area] = sum(EUEuPol[fuelep,plant,poll,area]/
      EURM[fuelep,plant,poll,area] for plant in Plants, fuelep in FuelEPs)*ECoverage[ecc,poll,energy,area]+
      MEPol[ecc,poll,area]*ECoverage[ecc,poll,process,area]
  end

end

function PutElectricGenerationEmissions(data::Data)
  (; db,year) = data
  (; EuFPol,EUMEPol,EUPOCX,EUEuPol) = data
  (; GrossPol,MEPol,SqPolCC,SqPolCCNet) = data
  (; SqPolCCPenalty,TFPol,TSPol) = data

  WriteDisk(db,"SOutput/EuFPol",year,EuFPol)
  WriteDisk(db,"EGOutput/EUMEPol",year,EUMEPol)
  WriteDisk(db,"EGOutput/EUPOCX",year,EUPOCX)
  WriteDisk(db,"EGOutput/EUEuPol",year,EUEuPol)
  WriteDisk(db,"SOutput/GrossPol",year,GrossPol)
  WriteDisk(db,"SOutput/MEPol",year,MEPol)
  WriteDisk(db,"SOutput/SqPolCC",year,SqPolCC)
  WriteDisk(db,"SOutput/SqPolCCNet",year,SqPolCCNet)
  WriteDisk(db,"SOutput/SqPolCCPenalty",year,SqPolCCPenalty)
  WriteDisk(db,"SOutput/TFPol",year,TFPol)
  WriteDisk(db,"SOutput/TSPol",year,TSPol)
end

function ElectricGenerationEmissions(data::Data)

  #@info "  EPollution.jl - ElectricGenerationEmissions"

  EndogenousEmissions(data)
  TotalElectricUtilityPollution(data)
  PollutionCoefficientByArea(data)
  GrossPollution(data)
  PutElectricGenerationEmissions(data)
end

function Imports(data::Data)
  (; Areas) = data

  #@info "  EPollution.jl - Imports"

  for area in Areas
    GenerationFromOutOfStateUnits(data,area)
    EmissionsFromOutOfStateUnits(data,area)
    AddNonCoalEmissionsFromOutOfStateUnits(data,area)
    RenewablePowerImports(data,area)
    SumNetImports(data,area)
    OtherImports(data,area)
    GrossImports(data,area)
    OtherImportsEmissions(data,area)
    RenewableImportsEmissions(data,area)
    ImportsEmissions(data,area)
  end

  PutImports(data)

end

function RqOffsets(data::Data)
  (; db,year) = data
  (; FuelEPs,Poll) = data
  (; OffRq,PolConv,UnPol) = data

  UnitsForRqOffsets = GetUnitsForRqOffsets(data)
  ghg = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])

  for unit in UnitsForRqOffsets
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid 
      UnitNeedsOffset = CheckForOffset(data,unit)
      if UnitNeedsOffset == "True"
        OffRq[area] = OffRq[area]+ sum(UnPol[unit,fuelep,poll]*
                    PolConv[poll] for poll in ghg, fuelep in FuelEPs)
      end
    end
  end

  WriteDisk(db,"SOutput/OffRq",year,OffRq)

end

function PollutionReductionAccounting(data::Data)

  #@info "  EPollution.jl - PollutionReductionAccounting"

  IndicatedReductionCapacity(data)
  ReductionCapacityInitiationRate(data)
  EmbeddedReductionCapitalCosts(data)
  ReductionCapacity(data)
  ReductionCapacityCompletionRate(data)
  PrivateExpensesForPollutionReductions(data)
  GovernmentExpensesForPollutionReductions(data)

  PutPollutionReductionAccounting(data)
end

function UnPRCapacity(data::Data)

  #@info "  EPollution.jl - UnPRCapacity"

  #
  # This accounting is different since the plant curves are cumulative
  # curves while the unit information is marginal when a unit moves from
  # one technology to another.
  #
  # InitializeUnPRCapacity(data)
  #
  UnitIndicatedReductionCapacity(data)
  UnitCapacityInitiationRate(data)
  UnitReductionCapacity(data)
  UnitReductionCapacityCompletionRate(data)

  PutUnPRCapacity(data)
end

function UnPRAccounting(data::Data)
  (; db,year) = data
  (; ECC) = data
  
  #@info "  EPollution.jl - UnPRAccounting"

  ecc = Select(ECC, "UtilityGen")

  InitializeUnPRAccounting(data,ecc)

  WhichUnCounter = "UseCurrent"
  units = GetUtilityUnits(data, WhichUnCounter)

  for unit in units
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid  
  
      UnitEmbeddedReductionCapitalCosts(data,unit)
      UnitEmissionReductionCapitalCosts(data,unit,ecc,area)
      UnitEmissionReductionOMCosts(data,unit)
      UnitPrivateExpensesForPollutionReductions(data,unit,ecc,area)
      UnitGovernmentExpensesForPollutionReductions(data,unit,ecc,area)
      
    end
  end

  PutUnPRAccounting(data)
end

function EmissionsCoverage(data::Data)
  (; db,year,ECC) = data
  (; Markets,PCov,Poll) = data
  (; AreaMarket,CapTrade,ECCMarket,PCovMarket,PolCov,UnCogen,UnCounter,UnCoverage) = data

  #@info "  EPollution.jl - EmissionsCoverage"

  cogeneration = Select(PCov,"Cogeneration")
  energy = Select(PCov,"Energy")

  InitializeEmissionsCoverage(data)
  #
  # PCov is set in InitializeEmissionsCoverage
  #
  pcov = Select(PCov,"Energy")

  for market in Markets
    if CapTrade[market] != 0
      areas,polls,ActiveMarket = GetMarketParameters(data,market)
      if ActiveMarket == "True"
      
        units = collect(1:Int(UnCounter))
        for unit in units
          area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
          if UnitIsValid  
                
            UnCover = maximum(UnCoverage[unit,poll] for poll in polls)
            if (AreaMarket[area,market] == 1) && (ECCMarket[ecc,market] == 1) && (UnCover > 0)
        
              #
              # Utility Units
              #
              if UnCogen[unit] == 0
                if PCovMarket[energy,market] == 1
                  pcov = Select(PCov,"Energy")
                  CoveredEmissions(data,unit,ecc,polls,pcov,area,market)
                end

              #
              # Cogeneration Units - Given "Sector" cogeneration, all or no
              # cogeneration units must be covered so cogeneration is calculated
              # in SuPollution.src.  Jeff Amlin 9/14/17
              #
              #else UnCogen[unit] > 0
              #  if PCovMarket[cogeneration,market] == 1
              #    CoveredEmissions(data,unit,ecc,polls,pcov,area,market)
              #  end
              end
            end
          end
        end
      end
    end
  end

  AddElectricImportEmissions(data)

  WriteDisk(db,"SOutput/PolCov",year,PolCov)
end

function GetGratisPermits(data::Data)
  (;ECC,Markets,PCov) = data
  (;AreaMarket,ECCMarket,UnCoverage) = data

  #@info "  EPollution.jl - GetGratisPermits"

  ecc = Select(ECC,"UtilityGen")
  pcov = Select(PCov,"Energy") 

  InitializeGratisPermits(data,ecc,pcov) 
  
  for market in Markets
    areas,polls,ActiveMarket = GetMarketParameters(data,market)      
    if ActiveMarket == "True"
      WhichUnCounter = "UsePrior"
      units = GetUtilityUnits(data,WhichUnCounter)
 
      for unit in units
        area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
        if UnitIsValid  
            
          UnCover = maximum(UnCoverage[unit,poll] for poll in polls)
          if (AreaMarket[area,market] == 1) && (ECCMarket[ecc,market] == 1) && (UnCover > 0) 
            
            PermitsForFuelBurningPlants(data,market,unit,polls)
            PermitsForFacilityIntensityTargets(data,market,unit,polls)
            PermitsForExistingPlants(data,market,unit,ecc,polls,pcov,area)
            PermitsForNewPlants(data,market,unit,ecc,polls,pcov,area)
            PermitsWhichAreOutputBased(data,market,unit,ecc,polls,pcov,area)
          
          end
        end
      end
    
      #
      # Get market areas which are lost in "for unit" loop - Jeff Amlin 1/28/25
      #
      areas,polls,ActiveMarket = GetMarketParameters(data,market)
      
      ecc = Select(ECC,"UtilityGen")
      SavePermitsOrUseExogenous(data,market,ecc,polls,pcov,areas)
      ecc = Select(ECC,"UtilityGen")

      
    end

  end

  PutGratisPermits(data)
  
  GratisPermitsByPlantType(data)
end

function ElectricOffsets(data::Data)
  (; db,year) = data
  (; Polls,Unit) = data
  (; OffsetsElec,UnCounter,UnCoverage,UnEGA,UnOffsets) = data

  @. OffsetsElec=0

  for unit in 1:Int(UnCounter)
    area,ecc,genco,node,plant,UnitIsValid = GetUnitSets(data,unit)
    if UnitIsValid  
      for poll in Polls
        OffsetsElec[ecc,poll,area] = OffsetsElec[ecc,poll,area]+
          UnEGA[unit]*UnOffsets[unit,poll]*UnCoverage[unit,poll]
      end
    end
  end

  WriteDisk(db,"SOutput/OffsetsElec",year,OffsetsElec)
end

function Part1(data::Data)

  #@info "  EPollution.jl - Part1 Control Procedure $CTime"

  # Read Disk(UnCounter)

  GetPCost(data)
  PRReductions(data)
  UnPReductions(data)
  PolCoefficients(data)
  PollutionCost(data)
end

function Part2(data::Data)

  #@info "  EPollution.jl - Part2 Control Procedure"

  ElectricGenerationEmissions(data)
  Imports(data)
  RqOffsets(data)
  PollutionReductionAccounting(data)
  UnPRCapacity(data)  
  UnPRAccounting(data)
  EmissionsCoverage(data)
  GetGratisPermits(data)
  ElectricOffsets(data)
end

end # module EPollution
