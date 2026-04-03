#
# TDemand.jl
#

module TDemand

import ...EnergyModel: ReadDisk,WriteDisk,Select,Yr
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,DT
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const Input = "TInput"
const Outpt = "TOutput"
const CalDB = "TCalDB"
const SectorName::String = "Transportation"
const SectorKey::String = "Trans"
const ESKey::String = "Transport"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  SceName::String
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]
  YrDCC::Int = Int.(CurTime)
  Yr2010 = Yr(2010)
  Yr1997 = Yr(1997)

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/TechKey")
  CTechs::Vector{Int} = collect(Select(CTech))  
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseKey::SetArray = ReadDisk(db,"$Input/EnduseKey")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelKey::SetArray = ReadDisk(db,"MainDB/FuelKey")  
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPKey::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))  
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))  
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))  
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovs::Vector{Int} = collect(Select(PCov))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))  
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  PollX::SetArray = ReadDisk(db,"MainDB/PollXKey")
  PollXs::Vector{Int} = collect(Select(PollX))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  Sector::SetArray = ReadDisk(db,"MainDB/SectorKey")  
  Tech::SetArray   = ReadDisk(db,"$Input/TechKey")
  Techs::Vector{Int} = collect(Select(Tech))
  Vintage::SetArray = ReadDisk(db,"$Input/VintageKey")
  VintageKey::SetArray = ReadDisk(db,"$Input/VintageKey")  
  Vintages::Vector{Int} = collect(Select(Vintage))

  BCName::String = ReadDisk(db,"MainDB/BCName") #  Base Case Name
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  OGRefName::String = ReadDisk(db,"MainDB/OGRefName") #  Oil/Gas Reference Case Name
  OGRefNameDB::String = ReadDisk(db,"MainDB/OGRefNameDB") #  Oil/Gas Reference Case Name

  RefName::String = ReadDisk(db,"MainDB/RefName") #  Reference Case Name
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") #  Reference Case Name

  #
  # Model Variables
  #
  AB::VariableArray{4} = ReadDisk(db,"$Outpt/AB",year);   # Average Market Share ($/$) [Enduse,Tech,EC,Area]
  ABPrior::VariableArray{4} = ReadDisk(db,"$Outpt/AB",prior);   # Average Market Share ($/$) [Enduse,Tech,EC,Area]
  ADCC::VariableArray{4} = ReadDisk(db,"$Outpt/ADCC",year); # Average Device Capital Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  AGFr::VariableArray{3} = ReadDisk(db,"SInput/AGFr",year); # Government Subsidy ($/$) [ECC,Poll,Area]
  AMSF::VariableArray{4} = ReadDisk(db,"$Outpt/AMSF",year); # Capital Energy Requirement (Btu/Btu) [Enduse,Tech,EC,Area]
  AMSFPrior::VariableArray{4} = ReadDisk(db,"$Outpt/AMSF",prior); # Capital Energy Requirement (Btu/Btu) [Enduse,Tech,EC,Area]
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap"); # Map between Area and Nation [Area,Nation]
  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year); # Areas included in Market[Area,Market]
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  BAT::Float32 = ReadDisk(db,"$Input/BAT")[1] #[tv] Short Term Utilization Adjustment Time (YR)"
  BCarbonSw::Int = ReadDisk(db,"SInput/BCarbonSw",year); # Black Carbon coefficient switch (1=POCX set relative to PM25)
  BCMultTr::VariableArray{4} = ReadDisk(db,"$Input/BCMultTr",year); # Fuel Emission Multipler between Black Carbon and PM 2.5 (Tonnes/Tonnes) [Fuel,Tech,EC,Area]
  BE::Float32 = ReadDisk(db,"$Input/BE")[1] #[tv]  Budget Elasticity Factor ($/$)
  BM::VariableArray{4} = ReadDisk(db,"$Outpt/BM",year); # Budget Multiplier ($/$) [Enduse,Tech,EC,Area]
  BMM::VariableArray{4} = ReadDisk(db,"$Input/BMM",year); # Budget Exogenous Multiplier (Btu/Btu) [Enduse,Tech,EC,Area]
  CapTrade::VariableArray{1} = ReadDisk(db,"SInput/CapTrade",year); # Emission Cap and Trading Switch (1=Trade, Cap Only=2) [Market]
  CERSM::VariableArray{3} = ReadDisk(db,"$CalDB/CERSM",year); # Capital Energy Requirement (Btu/Btu) [Enduse,EC,Area]
  CFraction::VariableArray{4} = ReadDisk(db,"$Input/CFraction",year) # Fraction of Production Capacity open to Conversion ($/$) [Enduse,Tech,EC,Area]
  CgAT::VariableArray{3} = ReadDisk(db,"$Input/CgAT",year) # Cogeneration Implementation Time (Years) [Tech,EC,Area]
  CgBL::VariableArray{3} = ReadDisk(db,"$Input/CgBL") # Cogeneration Equipment Book Value Lifetime (Years) [Tech,EC,Area]
  CgCap::VariableArray{3} = ReadDisk(db,"SOutput/CgCap",year) # Cogeneration Capacity (MW) [Fuel,ECC,Area]
  CgCC::VariableArray{3} = ReadDisk(db,"$Input/CgCC",year) # Cogeneration Capital Cost ($/mmBtu/Yr) [Tech,EC,Area]
  CgCR::VariableArray{3} = ReadDisk(db,"$Outpt/CgCR",year) # Cogeneration Capacity Construction Rate (MW/Yr) [Tech,EC,Area]
  CgCUFP::VariableArray{3} = ReadDisk(db,"$Input/CgCUFP") # Cogeneration Capacity Utilization Factor used for Planning (Btu/Btu) [Tech,EC,Area]
  CgDC::VariableArray{2} = ReadDisk(db,"$Input/CgDC") # Cogeneration Delivery Charge ($/mmBtu) [Tech,Area]
  CgDem::VariableArray{3} = ReadDisk(db,"$Outpt/CgDem",year) # Cogeneration Demands (TBtu/Yr) [FuelEP,EC,Area]
  CgDemand::VariableArray{3} = ReadDisk(db,"SOutput/CgDemand",year) # Cogeneration Demands (TBtu/Yr) [Fuel,ECC,Area]
  CgDemandPrior::VariableArray{3} = ReadDisk(db,"SOutput/CgDemand",prior) # Cogeneration Demands (TBtu/Yr) [Fuel,ECC,Area]
  CgDM::VariableArray{2} = ReadDisk(db,"$Outpt/CgDM",year) # Depletion Multiplier ($/$) [Tech,Area]
  CgDmd::VariableArray{3} = ReadDisk(db,"$Outpt/CgDmd",year) # Cogeneration Energy Demand (TBtu/Yr) [Tech,EC,Area]
  CgDmSw::VariableArray{1} = ReadDisk(db,"$Input/CgDmSw") # Depletion Multiplier Switch for Selecting Technology [Tech]
  CgEC::VariableArray{2} = ReadDisk(db,"SOutput/CgEC",year) # Cogeneration by Economic Category (GWh/YR) [ECC,Area]
  CgECFP::VariableArray{3} = ReadDisk(db,"$Outpt/CgECFP",year) # Cogeneration Fuel Price ($/mmBtu) [Tech,EC,Area]
  CgECGrid::VariableArray{2} = ReadDisk(db,"SOutput/CgECGrid",year) # Cogeneration for Grid by Economic Category (GWh/YR) [ECC,Area]
  CgECNoGrid::VariableArray{2} = ReadDisk(db,"SOutput/CgECNoGrid",year) # Cogeneration not for Grid by Economic Category (GWh/YR) [ECC,Area]
  CgEG::VariableArray{3} = ReadDisk(db,"$Outpt/CgEG",year) # Cogeneration Generation (GWh/YR) [Tech,EC,Area]
  CgElectricFraction::VariableArray{3} = ReadDisk(db,"$Input/CgElectricFraction",year) # Cogeneration Electric Tech to Plant Fraction (MW/MW) [Plant,EC,Area]
  CgFPol::VariableArray{4} = ReadDisk(db,"SOutput/CgFPol",year) # Cogeneration Pollution (Tonnes/Yr) [FuelEP,ECC,Poll,Area]
  CgFPolGross::VariableArray{4} = ReadDisk(db,"SOutput/CgFPolGross",year) # Gross Cogeneration Emissions (Tonnes/Yr) [FuelEP,ECC,Poll,Area]
  CgFuelExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/CgFuelExpenditures",year) # Cogeneration Fuel Expenditures (M$) [ECC,Area]
  CgGC::VariableArray{3} = ReadDisk(db,"$Outpt/CgGC",year) # Cogeneration Generating Capacity (MW) [Tech,EC,Area]
  CgGCPrior::VariableArray{3} = ReadDisk(db,"$Outpt/CgGC",prior) # Cogeneration Generating Capacity (MW) [Tech,EC,Area]
  CgGCCI::VariableArray{4} = ReadDisk(db,"SOutput/CgGCCI",year) # Cogeneration Capacity Initiated (MW) [Plant,ECC,Node,Area]
  CgGen::VariableArray{3} = ReadDisk(db,"SOutput/CgGen",year) # Cogeneration Generation (GWh/Yr) [Fuel,ECC,Area]
  CgHRtM::VariableArray{3} = ReadDisk(db,"$Input/CgHRtM",year) # Marginal Cogeneration Heat Rate (Btu/KWh) [Tech,EC,Area]
  CgIGC::VariableArray{3} = ReadDisk(db,"$Outpt/CgIGC",year) # Indicated Cogeneration Capacity (MW) [Tech,EC,Area]
  CgIVTC::Float32 = ReadDisk(db,"$Input/CgIVTC",year) # Cogeneration Inv. Tax Credit ($/$) ]
  CgLoad::VariableArray{1} = ReadDisk(db,"$Input/CgLoad") # Flag to Exclude "Electric" Cogeneration (Hydro) from Electric Demands (0 = no,1=yes) [Tech]
  CgMCE::VariableArray{3} = ReadDisk(db,"$Outpt/CgMCE",year) # Cogen. Marginal Cost of Energy ($/mmBtu) [Tech,EC,Area]
  CgMCE0::VariableArray{3} = ReadDisk(db,"$Outpt/CgMCE",First) # Cogen. Marginal Cost of Energy ($/mmBtu) [Tech,EC,Area]
  CgMSF::VariableArray{3} = ReadDisk(db,"$Outpt/CgMSF",year) # Cogeneration Market Share (Btu/Btu) [Tech,EC,Area]
  CgMSM0::VariableArray{3} = ReadDisk(db,"$CalDB/CgMSM0",year) # Cogeneration Market Share Non-Price Factor (Btu/Btu) [Tech,EC,Area]
  CgMSMI::VariableArray{3} = ReadDisk(db,"$CalDB/CgMSMI") # Cogeneration Market Share Income Factor (Btu/$) [Tech,EC,Area]
  CgMSMM::VariableArray{3} = ReadDisk(db,"$Input/CgMSMM",year) # Cogeneration Market Share Non-Price Factor Multiplier (Btu/Btu) [Tech,EC,Area]
  CgNodeFraction::VariableArray{3} = ReadDisk(db,"$Input/CgNodeFraction",year) # Cogeneration EC and Area to Node Fraction (MW/MW) [EC,Node,Area]
  CgOF::VariableArray{3} = ReadDisk(db,"$Input/CgOF") # Cogeneration Operation Cost Fraction ($/Yr/$) [Tech,EC,Area]
  CgOMExp::VariableArray{2} = ReadDisk(db,"SOutput/CgOMExp",year) # Cogeneration O&M Expenditures (M$) [ECC,Area]
  CgOUREG::VariableArray{3} = ReadDisk(db,"$Input/CgOUREG",year) # Cogeneration Own Use Rate for Generation (GWh/GWh) [Tech,EC,Area]
  CgPCost::VariableArray{3} = ReadDisk(db,"SOutput/CgPCost",year) # Cogen Permit Cost ($/mmBtu) [FuelEP,ECC,Area]
  CgPCostExo::VariableArray{3} = ReadDisk(db,"SInput/CgPCostExo",year) # Exogenous Cogen Permit Cost (Real $/mmBtu) [FuelEP,ECC,Area]
  CgPCostExoPrior::VariableArray{3} = ReadDisk(db,"SInput/CgPCostExo",prior) # Exogenous Cogen Permit Cost (Real $/mmBtu) [FuelEP,ECC,Area]
  CgPCostPrior::VariableArray{3} = ReadDisk(db,"SOutput/CgPCost",prior) # Cogen Permit Cost ($/mmBtu) [FuelEP,ECC,Area]
  CgPCostTech::VariableArray{3} = ReadDisk(db,"$Outpt/CgPCostTech",year) # Cogeneration Permit Cost ($/mmBtu) [Tech,EC,Area]
  CgPL::VariableArray{3} = ReadDisk(db,"$Input/CgPL") # Cogeneration Equipment Lifetime (Years) [Tech,EC,Area]
  CgPlantFraction::VariableArray{2} = ReadDisk(db,"$Input/CgPlantFraction",year) # Cogeneration Tech to Plant Fraction (MW/MW) [Tech,Plant]
  CgPol::VariableArray{3} = ReadDisk(db,"SOutput/CgPol",year) # Cogeneration Related Pollution (Tonnes/Yr) [ECC,Poll,Area]
  CgPolEC::VariableArray{4} = ReadDisk(db,"$Outpt/CgPolEC",year) # Cogeneration Pollution (Tonnes/Yr) [FuelEP,EC,Poll,Area]
  CgPolSq::VariableArray{3} = ReadDisk(db,"SOutput/CgPolSq",year) # Cogeneration Gross Emissions Sequestered (Tonnes/Yr) [ECC,Poll,Area]
  CgPolSqPenalty::VariableArray{3} = ReadDisk(db,"SOutput/CgPolSqPenalty",year) # Cogeneration Sequestering Emissions Penalty (Tonnes/Yr) [ECC,Poll,Area]
  CgPot::VariableArray{3} = ReadDisk(db,"$Outpt/CgPot",year) # Cogeneration Potential (MW) [Tech,EC,Area]
  CgPotMult::VariableArray{3} = ReadDisk(db,"$Input/CgPotMult",year) # Cogeneration Potential Multiplier (Btu/Btu) [Tech,EC,Area]
  CgPotSw::VariableArray{3} = ReadDisk(db,"$Input/CgPotSw") # Cogeneration Potential Switch (0 = Steam,1=Electric) [Tech,EC,Area]
  CgR::VariableArray{3} = ReadDisk(db,"$Outpt/CgR",year) # Cogeneration Cap. Retirements (MW/Yr) [Tech,EC,Area]
  CgResI::VariableArray{2} = ReadDisk(db,"$Input/CgResI") # Resource Base (mmBtu) [Tech,Area]
  CgRisk::VariableArray{1} = ReadDisk(db,"$Input/CgRisk") # Cogeneration Excess Risk (DLESS) [Tech]
  CgSCM::VariableArray{1} = ReadDisk(db,"$Input/CgSCM") # Cogeneration Shared Cost Multiplier ($/$) [Tech]
  CgSqFr::VariableArray{4} = ReadDisk(db,"$Input/CgSqFr",year) # Cogeneration Sequestered Pollution Fraction (Tonne/Tonne) [FuelEP,EC,Poll,Area]
  CgSqPot::VariableArray{3} = ReadDisk(db,"SOutput/CgSqPot",year) # Cogeneration Sequestering Potential (Tonnes/Yr) [ECC,Poll,Area]
  CgTL::VariableArray{3} = ReadDisk(db,"$Input/CgTL") # Cogeneration Tax Life (YR) [Tech,EC,Area]
  CgUMS::VariableArray{3} = ReadDisk(db,"$Outpt/CgUMS",year) # Cogeneration Utilization Multiplier (Btu/Btu) [Tech,EC,Area]
  CgUMSPrior::VariableArray{3} = ReadDisk(db,"$Outpt/CgUMS",prior) # Cogeneration Utilization Multiplier (Btu/Btu) [Tech,EC,Area]
  CgVC::VariableArray{3} = ReadDisk(db,"$Outpt/CgVC",year) # Cogeneration Variable Costs ($/mmBtu) [Tech,EC,Area]
  CgVCSw::VariableArray{1} = ReadDisk(db,"$Input/CgVCSw") # Cogeneration Switch for Incorporating Fuel Costs in Variable Costs (1 = Include) [Tech]
  CgVF::VariableArray{3} = ReadDisk(db,"$CalDB/CgVF") # Cogeneration Variance Factor ($/$) [Tech,EC,Area]
  CHR::VariableArray{2} = ReadDisk(db,"$CalDB/CHR") # Cooling to Heating Ratio (Btu/Btu) [EC,Area]
  CHRM::VariableArray{2} = ReadDisk(db,"$Input/CHRM",year) # Cooling to Heating Ratio Multiplier [EC,Area]
  CM::VariableArray{3} = ReadDisk(db,"$Input/CM") # Cross-over Reduction Multiplier (Tonnes/Tonnes) [Tech,Poll,PollX]
  CMSF::VariableArray{5} = ReadDisk(db,"$Outpt/CMSF",year) # Device Conversion Market Share (Btu/Btu) [Enduse,Tech,CTech,EC,Area]
  CMSFSwitch::VariableArray{5} = ReadDisk(db,"$Input/CMSFSwitch",year) # Conversion Market Share Switch (1=Endogenous, 0=Exogenous) [Enduse,Tech,CTech,EC,Area]
  CMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/CMSM0",year) # Device Conversion Non-Price Factor (Btu/Btu) [Enduse,Tech,CTech,EC,Area]
  CMSMI::VariableArray{5} = ReadDisk(db,"$CalDB/CMSMI") # Conversion Market Share Multiplier ($/$) [Enduse,Tech,CTech,EC,Area]
  CnvrtEU::VariableArray{3} = ReadDisk(db,"$Input/CnvrtEU",year) # Conversion Switch [Enduse,EC,Area]
  CoverageCFS::VariableArray{3} = ReadDisk(db,"SInput/CoverageCFS",year) # Coverage fro CFS (1=Covered) [Fuel,ECC,Area]
  CROIN::VariableArray{4} = ReadDisk(db,"$Input/CROIN",year) # Conservation Return on Investment ($/Yr/$) [Enduse,Tech,EC,Area]
  CUF::VariableArray{4} = ReadDisk(db,"$CalDB/CUF",year) # Capacity Utilization Factor ($/Yr/$/Yr) [Enduse,Tech,EC,Area]
  CVF::VariableArray{5} = ReadDisk(db,"$CalDB/CVF",year) # Conversion Market Share Variance Factor (DLESS) [Enduse,Tech,CTech,EC,Area]
  DActV::VariableArray{5} = ReadDisk(db,"$Input/DActV") # Activity Rate of Equipment by Vintage (1/1) [Enduse,Tech,EC,Area,Vintage]
  DCC::VariableArray{4} = ReadDisk(db,"$Outpt/DCC",year) # Device Capital Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCRef::VariableArray{4} = ReadDisk(OGRefNameDB,"$Outpt/DCC",year) # Base Case Device Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  DCCA0::VariableArray{4} = ReadDisk(db,"$Input/DCCA0",year) # Device Capital Cost A0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DCCB0::VariableArray{4} = ReadDisk(db,"$Input/DCCB0",year) # Device Capital Cost B0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DCCC0::VariableArray{4} = ReadDisk(db,"$Input/DCCC0",year) # Device Capital Cost C0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DCCBefore::VariableArray{4} = ReadDisk(db,"$Outpt/DCCBefore",year) # Device Capital Cost Before Subsidy Policy ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCBeforeStd::VariableArray{4} = ReadDisk(db,"$Outpt/DCCBeforeStd",year) # Device Capital Cost Beore Standard ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCFullCost::VariableArray{4} = ReadDisk(db,"$Outpt/DCCFullCost",year) # Device Capital Cost Full Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCLimit::VariableArray{4} = ReadDisk(db,"$Input/DCCLimit",year) # Device Capital Cost Limit Multiplier ($/$) [Enduse,Tech,EC,Area]
  DCCN::VariableArray{4} = ReadDisk(db,"$Outpt/DCCN") # Normalized Device Capital Cost ($/mmBtu) [Enduse,Tech,EC,Area]
  DCCPolicy::VariableArray{4} = ReadDisk(db,"$Outpt/DCCPolicy",year) # Capital Cost of Policy Device ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCPoll::VariableArray{4} = ReadDisk(db,"$Outpt/DCCPoll",year) # Device Capital Cost from Pollution Price ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCPrice::VariableArray{4} = ReadDisk(db,"$Outpt/DCCPrice",year) # Device Capital Cost from Energy Price ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DCC",prior) # Device Capital Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCR::VariableArray{4} = ReadDisk(db,"$Outpt/DCCR",year) # Device Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  DCCRB::VariableArray{4} = ReadDisk(BCNameDB,"$Outpt/DCCR",year) # Base Case Device Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  DCCRPolicy::VariableArray{4} = ReadDisk(db,"$Outpt/DCCRPolicy",year) # Device Capital Charge Rate for Policy Device ($/Yr/$) [Enduse,Tech,EC,Area]
  DCCRPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DCCR",prior) # Device Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  DCCSubsidy::VariableArray{4} = ReadDisk(db,"$Input/DCCSubsidy",year) # Device Capital Cost Subsidy ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCDEM::VariableArray{4} = ReadDisk(db,"$Input/DCDEM",year) # Device Cost to Efficiency Multiplier for Efficiency Program ($/$/(Btu/Btu)) [Enduse,Tech,EC,Area]
  DCMM::VariableArray{4} = ReadDisk(db,"$Input/DCMM",year) # Capital Cost Maximum Multiplier  ($/$) [Enduse,Tech,EC,Area]
  DCMMM::VariableArray{4} = ReadDisk(db,"$Outpt/DCMMM",year) # Device Cost Efficiency Multiplier for Efficiency Program ($/$) [Enduse,Tech,EC,Area]
  DCTC::VariableArray{4} = ReadDisk(db,"$Outpt/DCTC",year) # Device Cap. Trade Off Coefficient (DLESS) [Enduse,Tech,EC,Area]
  DDay::VariableArray{2} = ReadDisk(db,"$Input/DDay",year) # Annual Degree Days (Degree Days) [Enduse,Area]
  DDayMonthly::VariableArray{3} = ReadDisk(db,"$Input/DDayMonthly",year) # Monthly Degree Days (Degree Days) [Enduse,Month,Area]
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # Normal Annual Degree Days (Degree Days) [Enduse,Area]
  DDCoefficient::VariableArray{3} = ReadDisk(db,"$Input/DDCoefficient",year) # Annual Energy Degree Day Coefficient (DD/DD) [Enduse,EC,Area]
  DDSat::VariableArray{2} = ReadDisk(db,"$Outpt/DDSat",year) # Degree Days for Saturation Equation (Degree Days) [Enduse,Area]
  DDSatFlag::VariableArray{2} = ReadDisk(db,"$Input/DDSatFlag") # Flag for Degree Days in Saturation Equation (1=include) [Enduse,Month]
  DDSmooth::VariableArray{2} = ReadDisk(db,"$Outpt/DDSmooth",year) # SmoothedDegree Days (Degree Days) [Enduse,Area]
  DDSmoothPrior::VariableArray{2} = ReadDisk(db,"$Outpt/DDSmooth",prior) # Smoothed Saturation Equation Degree Days in Previous Year (Degree Days) [Enduse,Area]
  DDSmoothingTime::VariableArray{2} = ReadDisk(db,"$Input/DDSmoothingTime",year) # Smoothing Time for Saturation Equation Degree Days (Years) [Enduse,Area]
  DEE::VariableArray{4} = ReadDisk(db,"$Outpt/DEE",year) # Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEA::VariableArray{4} = ReadDisk(db,"$Outpt/DEEA",year) # Average Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEA0::VariableArray{4} = ReadDisk(db,"$Input/DEEA0",year) # Device A0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEAM::VariableArray{4} = ReadDisk(db,"$Input/DEEAM",year) # Average Device Efficiency Multiplier (Fraction) [Enduse,Tech,EC,Area]
  DEEAPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DEEA",prior) # Average Device Efficiency in Prior Year (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEAV::VariableArray{5} = ReadDisk(db,"$Outpt/DEEAV",year) # Average Device Efficiency by Vintage (Btu/Btu) [Enduse,Tech,EC,Area,Vintage]
  DEEAVPrior::VariableArray{5} = ReadDisk(db,"$Outpt/DEEAV",prior) # Average Device Efficiency in Previous Year (Btu/Btu) [Enduse,Tech,EC,Area,Vintage]
  DEEB0::VariableArray{4} = ReadDisk(db,"$Input/DEEB0",year) # Device B0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEBeforeStd::VariableArray{4} = ReadDisk(db,"$Outpt/DEEBeforeStd",year) # Device Efficiency Before Standard (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEC0::VariableArray{4} = ReadDisk(db,"$Input/DEEC0",year) # Device C0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEFloorSw::VariableArray{2} = ReadDisk(db,"$Input/DEEFloorSw",year) # Switch to Activate Floor for Device Efficiency (1=Activate) [EC,Area]
  DEEPolicy::VariableArray{4} = ReadDisk(db,"$Outpt/DEEPolicy",year) # Policy Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEPolicyMSF::VariableArray{4} = ReadDisk(db,"$Outpt/DEEPolicyMSF",year) # Policy Participation Response (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEPoll::VariableArray{4} = ReadDisk(db,"$Outpt/DEEPoll",year) # Device Efficiency from Pollution Price (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEPrice::VariableArray{4} = ReadDisk(db,"$Outpt/DEEPrice",year) # Device Efficiency from Energy Price (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DEE",prior) # Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  DEERef::VariableArray{4} = ReadDisk(RefNameDB,"$Outpt/DEE",year) # Device Efficiency in Reference Case (Btu/Btu) [Enduse,Tech,EC,Area]
  DEESw::VariableArray{4} = ReadDisk(db,"$Input/DEESw",year) # Switch for Device Efficiency (Switch) [Enduse,Tech,EC,Area]
  DEEThermalMax::VariableArray{4} = ReadDisk(db,"$Input/DEEThermalMax") # Thermal Maximum Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # Maximum Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  DemCC::VariableArray{2} = ReadDisk(db,"SOutput/DemCC",year) # Demand Capital Cost ($/mmBtu) [ECC,Area]
  DemCCMult::VariableArray{2} = ReadDisk(db,"SOutput/DemCCMult",year) # Demand Capital Cost Multiplier ($/$) [ECC,Area]
  DEMM::VariableArray{4} = ReadDisk(db,"$CalDB/DEMM",year) # Maximum Device Efficiency Multiplier (Btu/Btu) [Enduse,Tech,EC,Area]
  DEMMM::VariableArray{4} = ReadDisk(db,"$Outpt/DEMMM",year) # Device Efficiency Multiplier for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DemRq::VariableArray{3} = ReadDisk(db,"SOutput/DemRq",year) # Marginal Energy Demand (TBtu/Driver) [Fuel,ECC,Area]
  DEPM::VariableArray{4} = ReadDisk(db,"$Input/DEPM",year) # Device Energy Price Multiplier ($/$) [Enduse,Tech,EC,Area]
  DER::VariableArray{4} = ReadDisk(db,"$Outpt/DER",year) # Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  DERA::VariableArray{4} = ReadDisk(db,"$Outpt/DERA",year) # Energy Requirement Addition (mmBtu/YR) [Enduse,Tech,EC,Area]
  DERAD::VariableArray{4} = ReadDisk(db,"$Outpt/DERAD",year) # Device Additions from Device Retirements (mmBtu/yr) [Enduse,Tech,EC,Area]
  DERAP::VariableArray{4} = ReadDisk(db,"$Outpt/DERAP",year) # Device Additions from Process Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERAPC::VariableArray{4} = ReadDisk(db,"$Outpt/DERAPC",year) # Device Additions from PCap Additions & Increases in Device Saturation (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERARC::VariableArray{4} = ReadDisk(db,"$Outpt/DERARC",year) # Device Additions from Conversions (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DER",prior) # Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  DERR::VariableArray{4} = ReadDisk(db,"$Outpt/DERR",year) # Device Energy Rqmt. Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERRD::VariableArray{4} = ReadDisk(db,"$Outpt/DERRD",year) # Device Retire. from Device Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERRDV::VariableArray{5} = ReadDisk(db,"$Outpt/DERRDV",year) # Device Retire from Device Retire. by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERReduction::VariableArray{4} = ReadDisk(db,"$Input/DERReduction",year) # Device Energy Reduction Fraction ((mmBtu/Yr)/(mmBtu/Yr)) [Enduse,Tech,EC,Area]
  DERRef::VariableArray{4} = ReadDisk(RefNameDB,"$Outpt/DER",year) # Reference Device Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  DERRP::VariableArray{4} = ReadDisk(db,"$Outpt/DERRP",year) # Device Retire. from Process Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERRPC::VariableArray{4} = ReadDisk(db,"$Outpt/DERRPC",year) # Device Retire. from Production Capacity Retirements and  Reductions in Device Saturation (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERRR::VariableArray{4} = ReadDisk(db,"$Outpt/DERRR",year) # Device Energy Retire. Retrofit ((mmBtu/Yr)/Yr) [Enduse,Tech,EC,Area]
  DERRRC::VariableArray{4} = ReadDisk(db,"$Outpt/DERRRC",year) # Device Retirements from Conversions (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  DERRRCV::VariableArray{5} = ReadDisk(db,"$Outpt/DERRRCV",year) # Device Retirements from Conversions by Vintage (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area,Vintage]
  DERRRExo::VariableArray{4} = ReadDisk(db,"$Outpt/DERRRExo",year) # Device Energy Exogenous Retrofits ((mmBtu/Yr)/Yr) [Enduse,Tech,EC,Area]
  DERRV::VariableArray{5} = ReadDisk(db,"$Outpt/DERRV",year) # Device Energy Requirement Retirements by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERV::VariableArray{5} = ReadDisk(db,"$Outpt/DERV",year) # Energy Requirement by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERVAllocation::VariableArray{5} = ReadDisk(db,"$Outpt/DERVAllocation",year) # Fraction of DER in each Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERVPrior::VariableArray{5} = ReadDisk(db,"$Outpt/DERV",prior) # Energy Requirement in Previous Year (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERVSum::VariableArray{4} = ReadDisk(db,"$Outpt/DERVSum",year) # Sum of Energy Requirement by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area]
  DERVSumPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DERVSum",prior) # Sum of Energy Requirement by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area]
  DEStd::VariableArray{4} = ReadDisk(db,"$Input/DEStd",year) # Device Efficiency Standards (Btu/Btu) [Enduse,Tech,EC,Area]
  DEStdP::VariableArray{4} = ReadDisk(db,"$Input/DEStdP",year) # Device Efficiency Standards Policy (Btu/Btu) [Enduse,Tech,EC,Area]
  DInv::VariableArray{2} = ReadDisk(db,"SOutput/DInv",year) # Device Investments (M$/Yr) [ECC,Area]
  DFPN::VariableArray{4} = ReadDisk(db,"$Outpt/DFPN") # Normalized Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  DFTC::VariableArray{4} = ReadDisk(db,"$Outpt/DFTC",year) # Device Fuel Trade Off Coefficient (DLESS) [Enduse,Tech,EC,Area]
  DGF::VariableArray{4} = ReadDisk(db,"$Input/DGF",year) # Domestic Grant Fraction ($/$) [Enduse,Tech,EC,Area]
  DInvTech::VariableArray{4} = ReadDisk(db,"$Outpt/DInvTech",year) # Device Investments (M$/Yr) [Enduse,Tech,EC,Area]
  DInvTechExo::VariableArray{4} = ReadDisk(db,"$Input/DInvTechExo",year) # Device Exogenous Investments (M$/Yr) [Enduse,Tech,EC,Area]
  DInvTechLast::VariableArray{4} = ReadDisk(db,"$Outpt/DInvTech",Last) # Device Investments (M$/Yr) [Enduse,Tech,EC,Area]
  DIVTC::VariableArray{2} = ReadDisk(db,"$Input/DIVTC",year) # Device Investment Tax Credit ($/$) [Tech,Area]
  Dmd::VariableArray{4} = ReadDisk(db,"$Outpt/Dmd",year) # Total Energy Demand (TBtu/Yr) [Enduse,Tech,EC,Area]
  DmdES::VariableArray{3} = ReadDisk(db,"SOutput/DmdES",year) # Energy Demand (TBtu/Yr) [ES,Fuel,Area]
  DmdFEPTech::VariableArray{4} = ReadDisk(db,"$Outpt/DmdFEPTech",year) # Energy Demands (TBtu/Yr) [FuelEP,Tech,EC,Area]
  DmdFEPTechPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DmdFEPTech",prior) # Energy Demands (TBtu/Yr) [FuelEP,Tech,EC,Area]
  DmdFuelTech::VariableArray{5} = ReadDisk(db,"$Outpt/DmdFuelTech",year) # Energy Demands (TBtu/Yr) [Enduse,Fuel,Tech,EC,Area]
  DmdFuelTechPrior::VariableArray{5} = ReadDisk(db,"$Outpt/DmdFuelTech",prior) # Energy Demands (TBtu/Yr) [Enduse,Fuel,Tech,EC,Area]
  DmdRq::VariableArray{4} = ReadDisk(db,"$Outpt/DmdRq",year) # Marginal Energy Demand (TBtu/Driver) [Enduse,Tech,EC,Area]
  DmdSw::VariableArray{3} = ReadDisk(db,"$Input/DmdSw",year) # Demand Switch (0 = Exogenous) [Tech,EC,Area]
  DmFrac::VariableArray{5} = ReadDisk(db,"$Outpt/DmFrac",year) # Demand Fuel/Tech Fraction Split (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DmFracPrior::VariableArray{5} = ReadDisk(db,"$Outpt/DmFrac",prior) # Demand Fuel/Tech Fraction Split (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DmFracMarginal::VariableArray{5} = ReadDisk(db,"$Outpt/DmFracMarginal",year) # Demand Fuel/Tech Fraction Marginal Market Share (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DmFracMSF::VariableArray{5} = ReadDisk(db,"$Outpt/DmFracMSF",year) # Demand Fuel/Tech Fraction Market Share (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DmFracMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/DmFracMSM0",year) # Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DmFracMax::VariableArray{5} = ReadDisk(db,"$Input/DmFracMax",year) # Demand Fuel/Tech Fraction Maximum (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DmFracMaxSC::VariableArray{2} = ReadDisk(db,"SOutput/DmFracMaxSC",year) # Maximum Blending for Low-Carbon Fuel (Btu/Btu) [Fuel,Nation]
  DmFracMin::VariableArray{5} = ReadDisk(db,"$Input/DmFracMin",year) # Demand Fuel/Tech Fraction Minimum (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DmFracTime::VariableArray{5} = ReadDisk(db,"$Input/DmFracTime",year) # Demand Fuel/Tech Adjustment Time (Years) [Enduse,Fuel,Tech,EC,Area]
  DmFracVF::VariableArray{5} = ReadDisk(db,"$Input/DmFracVF") # Demand Fuel/Tech Fraction Variance Factor (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DOCF::VariableArray{4} = ReadDisk(db,"$Input/DOCF",year) # Device Operating Cost Fraction ($/Yr/$) [Enduse,Tech,EC,Area]
  DOMExp::VariableArray{2} = ReadDisk(db,"SOutput/DOMExp",year) # Device O&M Expenditures (M$) [ECC,Area]
  DPIVTC::Float32 = ReadDisk(db,"$Input/DPIVTC",year) # Device Policy Investment Tax Credit ($/$) []
  DPL::VariableArray{4} = ReadDisk(db,"$Outpt/DPL",year) # Physical Life of Equipment (Years) [Enduse,Tech,EC,Area]
  DPLN::VariableArray{4} = ReadDisk(db,"$Outpt/DPL",First) # Physical Life of Equipment (Years) [Enduse,Tech,EC,Area]
  DPLV::VariableArray{5} = ReadDisk(db,"$Input/DPLV",year) # Scrappage Rate of Equipment by Vintage (1/1) [Enduse,Tech,EC,Area,Vintage]
  DPLVPrior::VariableArray{5} = ReadDisk(db,"$Input/DPLV",prior) # Scrappage Rate of Equipment by Vintage (1/1) [Enduse,Tech,EC,Area,Vintage]
  DRisk::VariableArray{2} = ReadDisk(db,"$Input/DRisk") # Device Excess Risk ($/$) [Enduse,Tech]
  Driver::VariableArray{2} = ReadDisk(db,"MOutput/Driver",year) # Economic Driver (Various Millions/Yr) [ECC,Area]
  DriverLast::VariableArray{2} = ReadDisk(db,"MOutput/Driver",Last) # Economic Driver (Various Millions/Yr) [ECC,Area]
  DriverRef::VariableArray{2} = ReadDisk(RefNameDB,"MOutput/Driver",year) # Reference Case Economic Driver (Various Millions/Yr) [ECC,Area]
  DRIVTC::VariableArray{2} = ReadDisk(db,"$Input/DRIVTC",year) # Device Retrofit Investment Tax Credit ($/$) [Tech,Area]
  DSMEU::VariableArray{4} = ReadDisk(db,"$Input/DSMEU",year) # Exogenous Enduse DSM Adjustment (GWh/Yr) [Enduse,Tech,EC,Area]
  DSMEUInv::VariableArray{4} = ReadDisk(db,"$Input/DSMEUInv",year) # Exogenous Enduse DSM Adjustment Investments (1985 M$/Yr) [Enduse,Tech,EC,Area]
  DSt::VariableArray{3} = ReadDisk(db,"$Outpt/DSt",year) # Device Saturation (Btu/Btu) [Enduse,EC,Area]
  DStPrior::VariableArray{3} = ReadDisk(db,"$Outpt/DSt",prior) # Device Saturation in Prior Year (Btu/Btu) [Enduse,EC,Area]
  DSt0::VariableArray{3} = ReadDisk(db,"$CalDB/DSt0",year) # Device Saturation Coefficient (Btu/Btu) [Enduse,EC,Area]
  DStA0::VariableArray{3} = ReadDisk(db,"$Input/DStA0",year) # Device Saturation Degree Day Coefficient (Btu/Btu/DD) [Enduse,EC,Area]
  DStAC::VariableArray{2} = ReadDisk(db,"SOutput/DStAC",year) # Device Saturation for AC (Btu/Btu) [Sector,Area]
  DStB0::VariableArray{3} = ReadDisk(db,"$Input/DStB0",year) # Device Saturation Area Adjustment (Btu/Btu) [Enduse,EC,Area]
  DStC0::VariableArray{3} = ReadDisk(db,"$Input/DStC0",year) # Device Saturation Constant Term (Btu/Btu) [Enduse,EC,Area]
  DStI::VariableArray{3} = ReadDisk(db,"$CalDB/DStI") # Device Saturation Income Utility ($/$) [Enduse,EC,Area]
  DStM::VariableArray{3} = ReadDisk(db,"$CalDB/DStM") # Maximum Device Saturation (Btu/Btu) [Enduse,EC,Area]
  DStMax::VariableArray{3} = ReadDisk(db,"$Input/DStMax") # Maximum Device Saturation (Btu/Btu) [Enduse,EC,Area]
  DStMin::VariableArray{3} = ReadDisk(db,"$Input/DStMin") # Minimum Device Saturation (Btu/Btu) [Enduse,EC,Area]
  DStP::VariableArray{3} = ReadDisk(db,"$CalDB/DStP") # Device Saturation Price Utility ($/$) [Enduse,EC,Area]
  DTL::VariableArray{4} = ReadDisk(db,"$Outpt/DTL",year) # Device Tax Life (Years) [Enduse,Tech,EC,Area]
  ECCMarket::VariableArray{2} = ReadDisk(db,"SInput/ECCMarket",year) # Economic Categories included in Market [ECC,Market]
  ECD::VariableArray{3} = ReadDisk(db,"$Outpt/ECD",year) # Fuel Demand (TBtu/Yr) [Tech,EC,Area]
  ECESMap::VariableArray{2} = ReadDisk(db,"$Input/ECESMap") # Map between EC and ES for Prices (Map) [EC,ES]
  ECFP::VariableArray{4} = ReadDisk(db,"$Outpt/ECFP",year) # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  ECFP0::VariableArray{4} = ReadDisk(db,"$Outpt/ECFP",First) # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  ECFPFuel::VariableArray{3} = ReadDisk(db,"$Outpt/ECFPFuel",year) # Fuel Price w/CFS Price ($/mmBtu) [Fuel,EC,Area]
  ECFPTech::VariableArray{4} = ReadDisk(db,"$Outpt/ECFPTech",year) # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  eCO2Price::VariableArray{1} = ReadDisk(db,"SOutput/eCO2Price",year) # Carbon Tax plus Permit Cost ($/eCO2 Tonnes) [Area]
  eCO2PriceExo::VariableArray{1} = ReadDisk(db,"SInput/eCO2PriceExo",year) # Carbon Tax plus Permit Cost ($/eCO2 Tonnes) [Area]
  ECovECC::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) # Emissions Coverage (1=Covered) [ECC,Poll,PCov,Area]
  ECoverage::VariableArray{4} = ReadDisk(db,"$Input/ECoverage",year) # Emissions Coverage (1=Covered) [EC,Poll,PCov,Area]
  ECovExo::VariableArray{4} = ReadDisk(db,"$Input/ECovExo",year) # Emissions Coverage for Exogenous Cap-and-Trade (1=Covered) [EC,Poll,PCov,Area]
  ECUF::VariableArray{2} = ReadDisk(db,"MOutput/ECUF",year) # Capital Utilization Fraction (Btu/Btu) [ECC,Area]
  EE::VariableArray{4} = ReadDisk(db,"$Outpt/EE",year) # Energy Efficiency (TBtu/Yr) [Enduse,Tech,EC,Area]
  EECoECC::VariableArray{3} = ReadDisk(db,"SOutput/EECoECC",year) # Energy Efficiency Costs ($M) [Fuel,ECC,Area]
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  EECosts::VariableArray{4} = ReadDisk(db,"$Outpt/EECosts",year) # Energy Efficiency Costs ($M) [Enduse,Tech,EC,Area]
  EEECC::VariableArray{3} = ReadDisk(db,"SOutput/EEECC",year) # Energy Efficiency (TBtu/Yr) [Fuel,ECC,Area]
  EEImpact::VariableArray{4} = ReadDisk(db,"$Input/EEImpact",year) # Energy Efficiency Impact (Btu/Btu) [Enduse,Tech,EC,Area]
  EESat::VariableArray{4} = ReadDisk(db,"$Input/EESat",year) # Energy Efficiency Saturation (Btu/Btu) [Enduse,Tech,EC,Area]
  EESw::Int = ReadDisk(db,"$Input/EESw",year); # Energy Efficiency Switch (Endogenous=1, Exogenous=0, Skip=-1)
  EEUCosts::VariableArray{4} = ReadDisk(db,"$Input/EEUCosts",year) # Energy Efficiency Unit Costs ($/mmBtu) [Enduse,Tech,EC,Area]
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) # Energy Related Pollution (Tonnes/Yr) [FuelEP,ECC,Poll,Area]
  EuPol::VariableArray{3} = ReadDisk(db,"SOutput/EuPol",year) # Enduse Energy Related Pollution (Tonnes/Yr) [ECC,Poll,Area]
  EORDInv::VariableArray{1} = ReadDisk(db,"$Input/EORDInv",year) # Device Investments for EOR (M$/TBtu) [Area]
  EORDmd::VariableArray{1} = ReadDisk(db,"$Input/EORDmd",year) # Demand for Motors for EOR (TBtu/TBtu) [Area]
  ESHRt::VariableArray{3} = ReadDisk(db,"$Input/ESHRt",year) # Excess Steam Heat Rate (Btu/KWh) [Tech,EC,Area]
  ETSwitch::VariableArray{2} = ReadDisk(db,"$Input/ETSwitch",year) # Emerging Technology Switch (1=Emerging Technology) [Tech,Area]
  EuDem::VariableArray{4} = ReadDisk(db,"$Outpt/EuDem",year) # Enduse Demands (TBtu/Yr) [Enduse,FuelEP,EC,Area]
  EuDemPrior::VariableArray{4} = ReadDisk(db,"$Outpt/EuDem",prior) # Enduse Demands (TBtu/Yr) [Enduse,FuelEP,EC,Area]
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) # Enduse Energy Demands (TBtu/Yr) [Fuel,ECC,Area]
  EUPC::VariableArray{5} = ReadDisk(db,"$Outpt/EUPC",year) # Production Capacity by Enduse (Driver/Yr) [Enduse,Tech,Age,EC,Area]
  EUPCPrior::VariableArray{5} = ReadDisk(db,"$Outpt/EUPC",prior) # Production Capacity by Enduse (Driver/Yr) [Enduse,Tech,Age,EC,Area]
  EUPCRef::VariableArray{5} = ReadDisk(OGRefNameDB,"$Outpt/EUPC",year) # Production Capacity by Enduse (Driver/Yr) [Enduse,Tech,Age,EC,Area]
  EUPCA::VariableArray{5} = ReadDisk(db,"$Outpt/EUPCA",year) # Production Capacity Additions ((M$/YR)/YR) [Enduse,Tech,Age,EC,Area]
  EUPCAC::VariableArray{5} = ReadDisk(db,"$Outpt/EUPCAC",year) # Production Capacity Additions from Device Conversions ((M$/YR)/YR) [Enduse,Tech,Age,EC,Area]
  EUPCAPC::VariableArray{5} = ReadDisk(db,"$Outpt/EUPCAPC",year) # Production Capacity Additions from New Production Capacity (M$/Yr/Yr) [Enduse,Tech,Age,EC,Area]
  EUPCR::VariableArray{5} = ReadDisk(db,"$Outpt/EUPCR",year) # Production Capacity Retirement ((M$/YR)/YR) [Enduse,Tech,Age,EC,Area]
  EUPCRC::VariableArray{5} = ReadDisk(db,"$Outpt/EUPCRC",year) # Production Capacity Retirements from Device Conversions ((M$/YR)/YR) [Enduse,Tech,Age,EC,Area]
  EUPCRPC::VariableArray{5} = ReadDisk(db,"$Outpt/EUPCRPC",year) # Production Capacity Retirements from Capacity Retirements (M$/Yr/Yr) [Enduse,Tech,Age,EC,Area]
  ExpCP::VariableArray{3} = ReadDisk(db,"$Outpt/ExpCP",year) # Emission Expenditures ($M/Yr) [Tech,EC,Area]
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  FDCC::VariableArray{4} = ReadDisk(db,"$Input/FDCC",) # Fixed Device Capital Cost ($/(MBTU/YR)) [Enduse,Tech,CTech,Area]
  FDCCU::VariableArray{4} = ReadDisk(db,"$Input/FDCCU",year) # Conversion Rebate [Enduse,Tech,CTech,Area]
  FEPCP::VariableArray{3} = ReadDisk(db,"$Outpt/FEPCP",year) # Carbon Price by FuelEP ($/mmBtu) [FuelEP,EC,Area]
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # Map between FuelEP and Fuel [FuelEP,Fuel]
  FPCFS::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFS",year) # CFS Price ($/mmBtu) [Fuel,EC,Area]
  FPCFSFuel::VariableArray{3} = ReadDisk(db,"SOutput/FPCFSFuel",year) # CFS Price ($/mmBtu) [Fuel,ES,Area]
  FPCFSLast::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFS",Last) # CFS Price ($/mmBtu) [Fuel,EC,Area]
  FPCFSNet::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFSNet",year) # CFS Price ($/mmBtu) [Fuel,EC,Area]
  FPCFSObligated::VariableArray{2} = ReadDisk(db,"SOutput/FPCFSObligated",year) # CFS Price for Obligated Sectors ($/Tonnes) [ECC,Area]
  FPCFSTech::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFSTech",year) # CFS Price ($/mmBtu) [Tech,EC,Area]
  FPCP::VariableArray{3} = ReadDisk(db,"$Outpt/FPCP",year) # Carbon Price before OBA ($/mmBtu) [Fuel,EC,Area]
  FPCPFrac::VariableArray{3} = ReadDisk(db,"$Input/FPCPFrac",year) # Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$) [Fuel,EC,Area]
  FPEC::VariableArray{3} = ReadDisk(db,"$Outpt/FPEC",year) # Fuel Prices excluding Emission Costs ($/mmBtu) [Fuel,EC,Area]
  FPECC::VariableArray{3} = ReadDisk(db,"SOutput/FPECC",year) # Fuel Prices excluding Emission Costs ($/mmBtu) [Fuel,ECC,Area]
  FPECCCFS::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFS",year) # Fuel Prices w/CFS Price ($/mmBtu) [Fuel,ECC,Area]
  FPECCCFSCP::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSCP",year) # Fuel Prices w/CFS and Carbon Price ($/mmBtu) [Fuel,ECC,Area]
  FPECCCFSCPNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSCPNet",year) # Fuel Prices w/CFS and Net Carbon Price ($/mmBtu) [Fuel,ECC,Area]
  FPECCCFSNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSNet",year) # Incremental CFS Price ($/mmBtu) [Fuel,ECC,Area]
  FPECCOGEC::VariableArray{3} = ReadDisk(db,"SOutput/FPECCOGEC",year) # Incremental OGEC Price ($/mmBtu)[Fuel,ECC,Area]
  FPECCCP::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCP",year) # Carbon Price before OBA ($/mmBtu) [Fuel,ECC,Area]
  FPECCCPNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCPNet",year) # Net Carbon Price after OBA ($/mmBtu) [Fuel,ECC,Area]
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) # Fuel Price ($/mmBtu) [Fuel,ES,Area]
  FPOGEC::VariableArray{3} = ReadDisk(db,"$Outpt/FPOGEC",year) # OGEC Price ($/mmBtu) [Fuel,EC,Area]
  FPTech::VariableArray{3} = ReadDisk(db,"$Outpt/FPTech",year) # Fuel Price excluding Emission Costs ($/mmBtu) [Tech,EC,Area]
  FsDem::VariableArray{4} = ReadDisk(db,"$Outpt/FsDem",year) # Feedstock Demands (TBtu/Yr) [Fuel,Tech,EC,Area]
  FsDemand::VariableArray{3} = ReadDisk(db,"SOutput/FsDemand",year) # Feedstock Demands (tBtu) [Fuel,ECC,Area]
  FsDmd::VariableArray{3} = ReadDisk(db,"$Outpt/FsDmd",year) # Feedstock Energy Demand (TBtu/Yr) [Tech,EC,Area]
  FsFrac::VariableArray{4} = ReadDisk(db,"$Outpt/FsFrac",year) # Feedstock Demands Fuel/Tech Split (Fraction) [Fuel,Tech,EC,Area]
  FsFracMarginal::VariableArray{4} = ReadDisk(db,"$Outpt/FsFracMarginal",year) # Feedstock Fuel/Tech Fraction Marginal Market Share (Btu/Btu) [Fuel,Tech,EC,Area]
  FsFracMSF::VariableArray{4} = ReadDisk(db,"$Outpt/FsFracMSF",year) # Feedstock Fuel/Tech Fraction Market Share (Btu/Btu) [Fuel,Tech,EC,Area]
  FsFracMSM0::VariableArray{4} = ReadDisk(db,"$CalDB/FsFracMSM0",year) # Feedstock Fuel/Tech Fraction Non-Price Factor (Btu/Btu) [Fuel,Tech,EC,Area]
  FsFracMax::VariableArray{4} = ReadDisk(db,"$Input/FsFracMax",year) # Feedstock Fuel/Tech Fraction Maximum (Btu/Btu) [Fuel,Tech,EC,Area]
  FsFracMin::VariableArray{4} = ReadDisk(db,"$Input/FsFracMin",year) # Feedstock Fuel/Tech Fraction Minimum (Btu/Btu) [Fuel,Tech,EC,Area]
  FsFracPrior::VariableArray{4} = ReadDisk(db,"$Outpt/FsFrac",prior) # Feedstock Fuel/Tech Fraction Split (Btu/Btu) [Fuel,Tech,EC,Area]
  FsFracTime::VariableArray{4} = ReadDisk(db,"$Input/FsFracTime",year) # Feedstock Fuel/Tech Adjustment Time (Years) [Fuel,Tech,EC,Area]
  FsFracVF::VariableArray{4} = ReadDisk(db,"$Input/FsFracVF",year) # Feedstock Fuel/Tech Fraction Variance Factor (Btu/Btu) [Fuel,Tech,EC,Area]
  FsFP::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",year) # Feedstock Fuel Price ($/mmBtu) [Fuel,ES,Area]
  FsFP0::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",First) # Feedstock Fuel Price ($/mmBtu) [Fuel,ES,Area]
  FsPEE::VariableArray{3} = ReadDisk(db,"$CalDB/FsPEE",year) # Feedstock Process Efficiency ($/mmBtu) [Tech,EC,Area]
  FsPOCA::VariableArray{5} = ReadDisk(db,"$Outpt/FsPOCA",year) # Feedstock Pollution Coefficients (Tonnes/TBtu) [Fuel,Tech,EC,Poll,Area]
  FsPOCS::VariableArray{5} = ReadDisk(db,"$Input/FsPOCS",year) # Feedstock Pollution Standards (Tonnes/TBtu) [Fuel,Tech,EC,Poll,Area]
  FsPOCX::VariableArray{5} = ReadDisk(db,"$Input/FsPOCX",year) # Feedstock Marginal Pollution Coefficients (Tonnes/TBtu) [Fuel,Tech,EC,Poll,Area]
  FsPol::VariableArray{5} = ReadDisk(db,"$Outpt/FsPol",year) # Feedstock Pollution (Tonnes/Yr) [Fuel,Tech,EC,Poll,Area]
  FuelExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/FuelExpenditures",year) # Fuel Expenditures (M$) [ECC,Area]
  FuelLimit::VariableArray{2} = ReadDisk(db,"SCalDB/FuelLimit",year) # Fuel Limit Multiplier (Btu/Btu) [Fuel,Area]
  FuelSCMap::VariableArray{2} = ReadDisk(db,"SInput/FuelSCMap",year) # Map for Fuels with a Supply Curve (1=Supply Curve) [Fuel,Nation]
  GO::VariableArray{2} = ReadDisk(db,"MOutput/GO",year) # Gross Output (M$/Yr) [ECC,Area]
  GPFrac::VariableArray{4} = ReadDisk(db,"$Outpt/GPFrac",year) # Emissions Gratis Permit Fraction (Tonnes/Tonnes) [EC,Poll,PCov,Area]
  GPFrECC::VariableArray{4} = ReadDisk(db,"SOutput/GPFrac",year) # Emissions Gratis Permit Fraction (Tonnes/Tonnes) [ECC,Poll,PCov,Area]
  GrElec::VariableArray{2} = ReadDisk(db,"SOutput/GrElec",year) # Gross Electric Usage (GWh) [ECC,Area]
  GRExp::VariableArray{3} = ReadDisk(db,"SOutput/GRExp",year) # Reduction Government Expenses (M$/Yr) [ECC,Poll,Area]
  GrossPol::VariableArray{3} = ReadDisk(db,"SOutput/GrossPol",year) # Gross Pollution - before any policies (Tonnes/Yr) [ECC,Poll,Area]
  H2PipelineMultiplier::VariableArray{1} = ReadDisk(db,"SOutput/H2PipelineMultiplier",prior) # Pipeline Efficiency Multiplier from H2 in Pipeline (Btu/Btu) [Area]
  IdrtCost::VariableArray{4} = ReadDisk(db,"$Input/IdrtCost",year) # Indirect Costs ($/mmBtu) [Enduse,Tech,EC,Area]
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) # Inflation Index ($/$) [Area]
  Inflation0::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",First) # Inflation Index ($/$) [Area]
  Inflation2010::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr2010) # Inflation Index for 2010 ($/$) [Area]
  Inflation1997::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr1997) # Inflation Index for 1997 ($/$) [Area]
  InflationRef::VariableArray{1} = ReadDisk(OGRefNameDB,"MOutput/Inflation",year) # Inflation Index ($/$) [Area]
  InSm::VariableArray{1} = ReadDisk(db,"MOutput/InSm",year) # Smoothed Inflation Rate ($/Yr/$) [Area]
  IPCost::VariableArray{4} = ReadDisk(db,"$Outpt/IPCost",year) # Indicated Permit Cost ($/Tonne) [Tech,EC,Poll,Area]
  IRP::VariableArray{4} = ReadDisk(db,"$Outpt/IRP",year) # Indicated Pollutant Reduction (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  MCFU::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",year) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  MCFUPolicy::VariableArray{4} = ReadDisk(db,"$Outpt/MCFUPolicy",year) # Marginal Cost of Fuel Use for Policy Device ($/mmBtu) [Enduse,Tech,EC,Area]
  MCFUPoll::VariableArray{4} = ReadDisk(db,"$Outpt/MCFUPoll",year) # Marginal Cost of Fuel Use from Pollution Price ($/mmBtu) [Enduse,Tech,EC,Area]
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year) # Process Pollution (Tonnes/Yr) [ECC,Poll,Area]
  MESqPot::VariableArray{3} = ReadDisk(db,"SOutput/MESqPot",year) # Process Sequestering Potential (Tonnes/Yr) [ECC,Poll,Area]
  MinPurF::VariableArray{2} = ReadDisk(db,"SInput/MinPurF",year) # Minimum Fraction of Electricity which is Purchased (GWh/GWh) [ECC,Area]
  MMSF::VariableArray{4} = ReadDisk(db,"$Outpt/MMSF",year) # Market Share Fraction by Device ($/$) [Enduse,Tech,EC,Area]
  MMSFB::VariableArray{4} = ReadDisk(BCNameDB,"$Outpt/MMSF",year) # Market Share Fraction from Base Case ($/$) [Enduse,Tech,EC,Area]
  MMSFExogenous::VariableArray{4} = ReadDisk(db,"$Input/MMSFExogenous",year) # Exogenous Market Share Fraction by Device ($/$) [Enduse,Tech,EC,Area]
  MMSM0::VariableArray{4} = ReadDisk(db,"$CalDB/MMSM0",year) # Non-Price Factors. ($/$) [Enduse,Tech,EC,Area]
  MMSMI::VariableArray{4} = ReadDisk(db,"$CalDB/MMSMI") # Market Share Mult. from Income ($/$) [Enduse,Tech,EC,Area]
  MMSFSwitch::VariableArray{4} = ReadDisk(db,"$Input/MMSFSwitch",year) # Market Share Switch (1=Endogenous, 0=Exogenous) [Enduse,Tech,EC,Area]
  MSLimit::VariableArray{4} = ReadDisk(db,"$Outpt/MSLimit",year) # [Enduse,Tech,EC,Area] Supply Limit on Market Share (Btu/Btu)
  MSMM::VariableArray{4} = ReadDisk(db,"$Input/MSMM",year) # Non-Price Market Share Factor Mult. [Enduse,Tech,EC,Area]
  MVDR::VariableArray{4} = ReadDisk(db,"$Outpt/MVDR",year) # Marginal Value of Device Retrofits ($/$) [Enduse,Tech,EC,Area]
  MVF::VariableArray{4} = ReadDisk(db,"$CalDB/MVF",year) # Market Share Variance Factor ($/$) [Enduse,Tech,EC,Area]
  MVPR::VariableArray{4} = ReadDisk(db,"$Outpt/MVPR",year) # Marginal Value of Process Retrofits ($/$) [Enduse,Tech,EC,Area]
  NcFPol::VariableArray{4} = ReadDisk(db,"SOutput/NcFPol",year) # Non Combustion Related Pollution (Tonnes/Yr) [Fuel,ECC,Poll,Area]
  NcPol::VariableArray{3} = ReadDisk(db,"SOutput/NcPol",year) # Non Combustion Related Pollution (Tonnes/Yr) [ECC,Poll,Area]
  OAPrEOR::VariableArray{2} = ReadDisk(db,"SOutput/OAPrEOR",year) # Oil Production from EOR (TBtu/Yr) [Process,Area]
  OAPrEORPrior::VariableArray{2} = ReadDisk(db,"SOutput/OAPrEOR",prior) # Oil Production from EOR in Previous Year (TBtu/Yr) [Process,Area]
  OBAFraction::VariableArray{2} = ReadDisk(db,"SInput/OBAFraction",year) # Output-Based Allocation Fraction (Tonne/Tonne) [ECC,Area]
  OMExp::VariableArray{2} = ReadDisk(db,"SOutput/OMExp",year) # O&M Expenditures (M$) [ECC,Area]
  OREnFPol::VariableArray{4} = ReadDisk(db,"SOutput/OREnFPol",year) # [FuelEP,ECC,Poll,Area] Off Road Actual Energy Related Pollution (Tonnes/Yr)
  PAdCost::VariableArray{3} = ReadDisk(db,"SInput/PAdCost",year) # Policy Administrative Cost (Exogenous) [ECC,Poll,Area]
  PC::VariableArray{2} = ReadDisk(db,"MOutput/PC",year) # Production Capacity (M$/Yr) [ECC,Area]
  PCPrior::VariableArray{2} = ReadDisk(db,"MOutput/PC",prior) # Production Capacity (M$/Yr) [ECC,Area]
  PC0::VariableArray{2} = ReadDisk(db,"MOutput/PC",First) # Production Capacity (M$/Yr) [ECC,Area]
  PCA::VariableArray{3} = ReadDisk(db,"MOutput/PCA",year) # Production Capacity Additions (M$/Yr/Yr) [Age,ECC,Area]
  PCC::VariableArray{4} = ReadDisk(db,"$Outpt/PCC",year) # Process Capital Cost ($/(Driver/Yr)) [Enduse,Tech,EC,Area]
  PCCRef::VariableArray{4} = ReadDisk(OGRefNameDB,"$Outpt/PCC",year) # Process Capital Cost ($/(Driver/Yr)) [Enduse,Tech,EC,Area]
  PCCA0::VariableArray{4} = ReadDisk(db,"$Input/PCCA0",year) # Process Capital Cost A0 Coeffcient for Efficiency Program ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PCCB0::VariableArray{4} = ReadDisk(db,"$Input/PCCB0",year) # Process Capital Cost B0 Coeffcient for Efficiency Program ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PCCC0::VariableArray{4} = ReadDisk(db,"$Input/PCCC0",year) # Process Capital Cost C0 Coeffcient for Efficiency Program ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PCCFC::VariableArray{4} = ReadDisk(db,"$Outpt/PCCFC",year) # Process Capital Cost Full Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  PCCMM::VariableArray{4} = ReadDisk(db,"$Input/PCCMM",year) # Process Cost Maximum Multiplier  ($/$) [Enduse,Tech,EC,Area]
  PCCN::VariableArray{4} = ReadDisk(db,"$Outpt/PCCN") # Normalized Process Capital Cost ($/mmBtu) [Enduse,Tech,EC,Area]
  PCCov::VariableArray{4} = ReadDisk(db,"$Outpt/PCCov",year) # Emissions Coverage by Tech or Fuel (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  PCCPoll::VariableArray{4} = ReadDisk(db,"$Outpt/PCCPoll",year) # Process Capital Cost from Pollution Price ($/($/Yr)) [Enduse,Tech,EC,Area]
  PCCPrice::VariableArray{4} = ReadDisk(db,"$Outpt/PCCPrice",year) # Process Capital Cost from Energy Price ($/($/Yr)) [Enduse,Tech,EC,Area]
  PCCR::VariableArray{4} = ReadDisk(db,"$Outpt/PCCR",year) # Process Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  PCCRB::VariableArray{4} = ReadDisk(BCNameDB,"$Outpt/PCCR",year) # Process Capital Charge Rate in Base Case ($/Yr/$) [Enduse,Tech,EC,Area]
  PCEU::VariableArray{4} = ReadDisk(db,"$Outpt/PCEU",year) # Production Capacity (Driver/Yr) [Enduse,Tech,EC,Area]
  PCEUPrior::VariableArray{4} = ReadDisk(db,"$Outpt/PCEU",prior) # Production Capacity (Driver/Yr) [Enduse,Tech,EC,Area]
  PCMMM::VariableArray{4} = ReadDisk(db,"$Outpt/PCMMM",year) # Process Cost Multiplier for Efficiency Program ($/$) [Enduse,Tech,EC,Area]
  PCost::VariableArray{4} = ReadDisk(db,"$Outpt/PCost",year) # Permit Cost ($/Tonne) [Tech,EC,Poll,Area]
  PCostECC::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) # Permit Cost ($/Tonne) [ECC,Poll,Area]
  PCostExo::VariableArray{4} = ReadDisk(db,"$Input/PCostExo",year) # Marginal Exogenous Permit Cost (Real $/Tonnes) [Tech,EC,Poll,Area]
  PCostM::VariableArray{4} = ReadDisk(db,"$Input/PCostM",year) # Permit Cost Multiplier ($/Tonne/$/Tonne) [Tech,EC,Poll,Area]
  PCostN::VariableArray{4} = ReadDisk(db,"$Input/PCostN") # Pollution Reduction Cost Normal ($/Tonne) [Tech,EC,Poll,Area]
  PCostPrior::VariableArray{4} = ReadDisk(db,"$Outpt/PCost",prior) # Permit Cost in Prior Year ($/Tonne) [FuelEP,EC,Poll,Area]
  PCostTech::VariableArray{3} = ReadDisk(db,"$Outpt/PCostTech",year) # Permit Cost ($/mmBtu) [Tech,EC,Area]
  PCovMap::VariableArray{4} = ReadDisk(db,"SInput/PCovMap",year) # Pollution Coverage Map (1=Mapped) [FuelEP,ECC,PCov,Area]
  PCPEM::VariableArray{4} = ReadDisk(db,"$Input/PCPEM",year) # Process Cost to Efficiency Multiplier for Efficiency Program ($/$/($/Btu/($/Btu))) [Enduse,Tech,EC,Area]
  PCPL::VariableArray{2} = ReadDisk(db,"MInput/PCPL",year) # Physical Life of Production Capacity (Years) [ECC,Area]
  PCTC::VariableArray{4} = ReadDisk(db,"$Outpt/PCTC",year) # Process Capital Trade Off Coefficient (DLESS) [Enduse,Tech,EC,Area]
  PE::VariableArray{2} = ReadDisk(db,"SOutput/PE",year) # Price of Electricity ($/mmBtu) [ECC,Area]
  PEE::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",year) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEERef::VariableArray{4} = ReadDisk(RefNameDB,"$Outpt/PEE",year) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEEA::VariableArray{4} = ReadDisk(db,"$Outpt/PEEA",year) # Average Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEEAPrior::VariableArray{4} = ReadDisk(db,"$Outpt/PEEA",prior) # Average Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEEA0::VariableArray{4} = ReadDisk(db,"$Input/PEEA0",year) # Process A0 Coeffcient for Efficiency Program ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PEEB0::VariableArray{4} = ReadDisk(db,"$Input/PEEB0",year) # Process B0 Coeffcient for Efficiency Program ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PEEBeforeStd::VariableArray{4} = ReadDisk(db,"$Outpt/PEEBeforeStd",year) # Process Efficiency Before Standard ($/Btu) [Enduse,Tech,EC,Area]
  PEEC0::VariableArray{4} = ReadDisk(db,"$Input/PEEC0",year) # Process C0 Coeffcient for Efficiency Program ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PEECurve::VariableArray{4} = ReadDisk(db,"$Outpt/PEECurve",year) #'Process Efficiency from Cost Curve ($/Btu) [Enduse,Tech,EC,Area]
  PEECurveM::VariableArray{4} = ReadDisk(db,"$Outpt/PEECurveM",year) # Process Efficiency from Cost Curve Multiplier(1/1) [Enduse,Tech,EC,Area,Year]
  PEEElas::VariableArray{4} = ReadDisk(db,"$Outpt/PEEElas",year) # Process Efficiency from Long Term Price Elasticity ($/Btu) [Enduse,Tech,EC,Area]
  PEEFloorSw::VariableArray{2} = ReadDisk(db,"$Input/PEEFloorSw",year) # Switch to Activate Floor for Process Efficiency (1=Activate) [EC,Area]
  PEElas::VariableArray{4} = ReadDisk(db,"$Input/PEElas",year) # Long Term Price Elasticity for Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEEPoll::VariableArray{4} = ReadDisk(db,"$Outpt/PEEPoll",year) # Process Efficiency from Pollution Price ($/Btu) [Enduse,Tech,EC,Area]
  PEEPrice::VariableArray{4} = ReadDisk(db,"$Outpt/PEEPrice",year) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEEPrior::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",prior) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEESw::VariableArray{4} = ReadDisk(db,"$Input/PEESw",year) # Switch for Process Efficiency (Switch) [Enduse,Tech,EC,Area]
  PEM::VariableArray{4} = ReadDisk(db,"$CalDB/PEM") # [Enduse,Tech,EC,Area] Maximum Process Efficiency ($/Btu) 
  PEMM::VariableArray{4} = ReadDisk(db,"$CalDB/PEMM",year) # Process Efficiency Max. Mult. ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PEMMM::VariableArray{4} = ReadDisk(db,"$Outpt/PEMMM",year) # Process Efficiency Multiplier for Efficiency Program ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  PEPL::VariableArray{4} = ReadDisk(db,"$Outpt/PEPL",year) # Physical Life of Process Requirements (Years) [Enduse,Tech,EC,Area]
  PEPLN::VariableArray{4} = ReadDisk(db,"$Outpt/PEPL",First) # Physical Life of Process Requirements (Years) [Enduse,Tech,EC,Area]
  PEPM::VariableArray{4} = ReadDisk(db,"$Input/PEPM",year) # Process Energy Price Mult. ($/$) [Enduse,Tech,EC,Area]
  PER::VariableArray{4} = ReadDisk(db,"$Outpt/PER",year) # Process Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  PERPrior::VariableArray{4} = ReadDisk(db,"$Outpt/PER",prior) # Process Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  PERA::VariableArray{4} = ReadDisk(db,"$Outpt/PERA",year) # Process Energy Rqmt. Addition (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERADSt::VariableArray{4} = ReadDisk(db,"$Outpt/PERADSt",year) # Process Additions from Increases in Saturation (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERAP::VariableArray{4} = ReadDisk(db,"$Outpt/PERAP",year) # Process Additions from Process Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERAPC::VariableArray{4} = ReadDisk(db,"$Outpt/PERAPC",year) # Process Additions from Production Capacity Additions (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERARC::VariableArray{4} = ReadDisk(db,"$Outpt/PERARC",year) # Process Additions from Device Conversions ((MBTU/YR)/YR) [Enduse,Tech,EC,Area]
  PERR::VariableArray{4} = ReadDisk(db,"$Outpt/PERR",year) # Process Energy Rqmt. Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERRDSt::VariableArray{4} = ReadDisk(db,"$Outpt/PERRDSt",year) # Process Retire. from Reductions in Saturation (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERReduction::VariableArray{4} = ReadDisk(db,"$Input/PERReduction",year) # Process Energy Exogenous Retrofits Percentage ((mmBtu/Yr)/(mmBtu/Yr)) [Enduse,Tech,EC,Area]
  PERRef::VariableArray{4} = ReadDisk(OGRefNameDB,"$Outpt/PER",year) # Reference Process Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  PERRP::VariableArray{4} = ReadDisk(db,"$Outpt/PERRP",year) # Process Retire. from Process Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERRPC::VariableArray{4} = ReadDisk(db,"$Outpt/PERRPC",year) # Process Retire. from Production Capacity Retire. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  PERRR::VariableArray{4} = ReadDisk(db,"$Outpt/PERRR",year) # Process Energy Retrofits ((mmBtu/Yr)/Yr) [Enduse,Tech,EC,Area]
  PERRRC::VariableArray{4} = ReadDisk(db,"$Outpt/PERRRC",year) # Process Retire. from Device Conversions ((MBTU/YR)/YR) [Enduse,Tech,EC,Area]
  PERRRExo::VariableArray{4} = ReadDisk(db,"$Outpt/PERRRExo",year) # Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr) [Enduse,Tech,EC,Area]
  PEStd::VariableArray{4} = ReadDisk(db,"$Input/PEStd",year) # Process Efficiency Standard ($/Btu) [Enduse,Tech,EC,Area]
  PEStdP::VariableArray{4} = ReadDisk(db,"$Input/PEStdP",year) # Process Efficiency Standard Policy ($/Btu) [Enduse,Tech,EC,Area]
  PETL::VariableArray{4} = ReadDisk(db,"$Outpt/PETL",year) # Tax Life of Process Requirements (Years) [Enduse,Tech,EC,Area]
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN") # Process Normalized Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  PFS::VariableArray{4} = ReadDisk(db,"$Outpt/PFS",year) # Process Fuel Savings ($/Yr) [Enduse,Tech,EC,Area]
  PFTC::VariableArray{4} = ReadDisk(db,"$Outpt/PFTC",year) # Process Fuel Trade Off Coefficient [Enduse,Tech,EC,Area]
  PInv::VariableArray{2} = ReadDisk(db,"SOutput/PInv",year) # Process Investments (M$/Yr) [ECC,Area]
  PInvDevice::VariableArray{4} = ReadDisk(db,"$Outpt/PInvDevice",year) # Process Investments by Technology (M$/Yr) [Enduse,Tech,EC,Area]
  PInvDriver::VariableArray{2} = ReadDisk(db,"SOutput/PInvDriver",year) # Process Investments from Driver (M$/Yr) [ECC,Area]
  PInvExo::VariableArray{4} = ReadDisk(db,"$Input/PInvExo",year) # Process Exogenous Investments (M$/Yr) [Enduse,Tech,EC,Area]
  PInvMinFrac::VariableArray{2} = ReadDisk(db,"$Input/PInvMinFrac",year) # Minimum Fraction for Process Investments ($/$) [EC,Area]
  PInvMinimum::VariableArray{2} = ReadDisk(db,"SOutput/PInvMinimum",year) # Process Investments Minimum Level (M$/Yr) [ECC,Area]
  PInvRef::VariableArray{2} = ReadDisk(RefNameDB,"SOutput/PInv",year) # Process Investments in Reference Case (M$/Yr) [ECC,Area]
  PInvTech::VariableArray{4} = ReadDisk(db,"$Outpt/PInvTech",year) # Process Investments by Technology (M$/Yr) [Enduse,Tech,EC,Area]
  PIVTC::VariableArray{1} = ReadDisk(db,"$Input/PIVTC") # Process Policy Investment Tax Credit ($/$) [Area]
  POCA::VariableArray{6} = ReadDisk(db,"$Outpt/POCA",year) # Average Pollution Coefficients (Tonnes/TBtu) [Enduse,FuelEP,Tech,EC,Poll,Area]
  POCAPrior::VariableArray{6} = ReadDisk(db,"$Outpt/POCA",prior) # Average Pollution Coefficients (Tonnes/TBtu) [Enduse,FuelEP,Tech,EC,Poll,Area]
  POCF::VariableArray{4} = ReadDisk(db,"$CalDB/POCF") # Process Operating Cost Fraction ($/Yr/$) [Enduse,Tech,EC,Area]
  POCS::VariableArray{6} = ReadDisk(db,"$Input/POCS",year) # Pollution Standards (Tonnes/TBtu) [Enduse,FuelEP,Tech,EC,Poll,Area]
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX",year) # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  POEM::VariableArray{6} = ReadDisk(db,"$Outpt/POEM",year) # Embodied Pollution (Tonnes/Yr) [Enduse,FuelEP,Tech,EC,Poll,Area]
  POEMPrior::VariableArray{6} = ReadDisk(db,"$Outpt/POEM",prior) # Embodied Pollution (Tonnes/Yr) [Enduse,FuelEP,Tech,EC,Poll,Area]
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) # Pollutants included in Market [Poll,Market]
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes) [Poll]
  PolMarginal::VariableArray{4} = ReadDisk(db,"$Outpt/PolMarginal",year) # Marginal Emissions (Tonnes/Yr) [Tech,EC,Poll,Area]
  PolSw::VariableArray{4} = ReadDisk(db,"$Input/PolSw",year) # Switch for Pollution Coefficients [Tech,EC,Poll,Area]
  Polute::VariableArray{6} = ReadDisk(db,"$CalDB/Polute",year) # Pollution (Tonnes/Yr) [Enduse,FuelEP,Tech,EC,Poll,Area]
  POMExp::VariableArray{2} = ReadDisk(db,"SOutput/POMExp",year) # Process O&M Expenditures (M$) [ECC,Area]
  Pop::VariableArray{2} = ReadDisk(db,"MOutput/Pop",year) # Population (Millions) [ECC,Area]
  Pop0::VariableArray{2} = ReadDisk(db,"MOutput/Pop",First) # Population (Millions) [ECC,Area]
  PRExp::VariableArray{3} = ReadDisk(db,"SOutput/PRExp",year) # Reduction Private Expenses (M$/Yr) [ECC,Poll,Area]
  PRExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/PRExpenditures",year) # Pollution Reduction Expenditures (M$/Yr) [ECC,Area]
  PrPCost::VariableArray{3} = ReadDisk(db,"$Outpt/PrPCost",year) # Pollution Cost ($/mmBtu) [Tech,EC,Area]
  PrPCostAT::VariableArray{2} = ReadDisk(db,"$Input/PrPCostAT") # Pollution Cost Adjustment Time (Years) [EC,Area]
  PrPCostMar::VariableArray{3} = ReadDisk(db,"$Outpt/PrPCostMar",year) # Marginal Pollution Cost ($/mmBtu) [Tech,EC,Area]
  PrPCostMarPrior::VariableArray{3} = ReadDisk(db,"$Outpt/PrPCostMar",prior) # Marginal Pollution Cost ($/mmBtu) [Tech,EC,Area]
  PrPCostPrior::VariableArray{3} = ReadDisk(db,"$Outpt/PrPCost",prior) # Pollution Cost ($/mmBtu) [Tech,EC,Area]
  PrPCostSw::Float32 = ReadDisk(db,"$Input/PrPCostSw",year) # Pollution Cost Switch ]
  PVF::VariableArray{4} = ReadDisk(db,"$Input/PVF") # Pollution Reduction Variance Factor (($/Tonne)/($/Tonne)) [Tech,EC,Poll,Area]
  RCap::VariableArray{4} = ReadDisk(db,"$Outpt/RCap",year) # Reduction Capital (Tonnes/Yr) [Tech,EC,Poll,Area]
  RCapPrior::VariableArray{4} = ReadDisk(db,"$Outpt/RCap",prior) # Reduction Capital (Tonnes/Yr) [Tech,EC,Poll,Area]
  RCC::VariableArray{4} = ReadDisk(db,"$Outpt/RCC",year) # Reduction Capital Cost ($/Tonne) [Tech,EC,Poll,Area]
  RCCEm::VariableArray{4} = ReadDisk(db,"$Outpt/RCCEm",year) # Embedied Reduction Capital Cost ($) [Tech,EC,Poll,Area]
  RCCEmPrior::VariableArray{4} = ReadDisk(db,"$Outpt/RCCEm",prior) # Embedied Reduction Capital Cost ($) [Tech,EC,Poll,Area]
  RCD::VariableArray{2} = ReadDisk(db,"$Input/RCD") # Reduction Capital Construction Delay (Years) [EC,Poll]
  RCI::VariableArray{4} = ReadDisk(db,"$Outpt/RCI",year) # Reduction Capital Initiation (Tonnes/Yr/Yr) [Tech,EC,Poll,Area]
  RCostM::VariableArray{2} = ReadDisk(db,"$Input/RCostM",year) # Reduction Cost Technology Multiplier ($/$) [Tech,Poll]
  RCPL::VariableArray{2} = ReadDisk(db,"$Input/RCPL") # Reduction Capital Pysical Life (Years) [EC,Poll]
  RCR::VariableArray{4} = ReadDisk(db,"$Outpt/RCR",year) # Reduction Capital Completion Rate (Tonnes/Yr/Yr) [Tech,EC,Poll,Area]
  RCRPrior::VariableArray{4} = ReadDisk(db,"$Outpt/RCR",prior) # Reduction Capital Completion Rate (Tonnes/Yr/Yr) [Tech,EC,Poll,Area]
  RCROIN::VariableArray{4} = ReadDisk(db,"$Input/RCROIN",year) # Retrofit Conservation Subsidy on Return on Investment ($/Yr/$) [Enduse,Tech,EC,Area]
  RDCC::VariableArray{4} = ReadDisk(db,"$Outpt/RDCC",year) # Retrofit Device Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  RDCCM::VariableArray{4} = ReadDisk(db,"$Input/RDCCM",year) # Retrofit Device Capital Cost Multiplier ($/$) [Enduse,Tech,EC,Area]
  RDCCR::VariableArray{4} = ReadDisk(db,"$Outpt/RDCCR",year) # Device Retrofit Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  RDCCRB::VariableArray{4} = ReadDisk(BCNameDB,"$Outpt/RDCCR",year) # Base Case Device Retrofit Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  RDCTC::VariableArray{4} = ReadDisk(db,"$Outpt/RDCTC",year) # Retrofit Device Cap. Trade Off Coefficient (DLESS) [Enduse,Tech,EC,Area]
  RDEE::VariableArray{4} = ReadDisk(db,"$Outpt/RDEE",year) # Retrofit Defice Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  RDEMM::VariableArray{4} = ReadDisk(db,"$Input/RDEMM",year) # Retrofit Maximum Device Efficiency Multiplier (Btu/Btu) [Enduse,Tech,EC,Area]
  RDEStd::VariableArray{4} = ReadDisk(db,"$Input/RDEStd",year) # Retrofit Device Efficiency Standards (Btu/Btu) [Enduse,Tech,EC,Area]
  RDFTC::VariableArray{4} = ReadDisk(db,"$Outpt/RDFTC",year) # Retrofit Device Fuel Trade Off Coefficient (DLESS) [Enduse,Tech,EC,Area]
  RDMSF::VariableArray{4} = ReadDisk(db,"$Outpt/RDMSF",year) # Device Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  RDMSM::VariableArray{4} = ReadDisk(db,"$CalDB/RDMSM",year) # Device Retrofit Market Share Multiplier (1/Yr) [Enduse,Tech,EC,Area]
  RDVF::VariableArray{2} = ReadDisk(db,"$Input/RDVF") # Device Retrofit Market Share Variance Factor (DLESS) [EC,Area]
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 
  RetroSw::VariableArray{3} = ReadDisk(db,"$Input/RetroSw",year) # Retrofit Selection (1=Device,2=Process,3=Both,4=Exogenous) [Enduse,EC,Area]
  RetroSwExo::Float32 = ReadDisk(db,"$Input/RetroSwExo",year) # Switch for Exogneous Retrofit Policy (=Method) ]
  RGF::VariableArray{4} = ReadDisk(db,"$Input/RGF",year) # Retrofit,year Rebate Fraction ($/$) [Enduse,Tech,EC,Area]
  RHCM::VariableArray{2} = ReadDisk(db,"$Input/RHCM",year) # Retrofit Hassle-Cost Multiplier ($/$) [EC,Area]
  RICap::VariableArray{4} = ReadDisk(db,"$Outpt/RICap",year) # Indicated Reduction Capital (Tonnes/Yr) [Tech,EC,Poll,Area]
  RInv::VariableArray{2} = ReadDisk(db,"SOutput/RInv",year) # Emission Reduction Investments (M$/Yr) [ECC,Area]
  RM::VariableArray{4} = ReadDisk(db,"$Outpt/RM",year) # Reduction Multiplier (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  RMPrior::VariableArray{4} = ReadDisk(db,"$Outpt/RM",prior) # Reduction Multiplier (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  ROCF::VariableArray{4} = ReadDisk(db,"$Input/ROCF") # Polution Reducution O&M ($/Tonne) [Tech,EC,Poll,Area]
  ROIN::VariableArray{2} = ReadDisk(db,"$Input/ROIN") # Return on Investment ($/Yr/$) [EC,Area]
  ROMExp::VariableArray{2} = ReadDisk(db,"SOutput/ROMExp",year) # Emission Reduction O&M Expenditures (M$) [ECC,Area]
  RP::VariableArray{4} = ReadDisk(db,"$Outpt/RP",year) # Pollutant Reduction (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  RPCC::VariableArray{4} = ReadDisk(db,"$Outpt/RPCC",year) # Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  RPCCM::VariableArray{4} = ReadDisk(db,"$Input/RPCCM",year) # Retrofit Process Capital Cost Multiplier ($/$) [Enduse,Tech,EC,Area]
  RPCCR::VariableArray{4} = ReadDisk(db,"$Outpt/RPCCR",year) # Process Retrofit Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  RPCCRB::VariableArray{4} = ReadDisk(BCNameDB,"$Outpt/RPCCR",year) # Base Case Process Retrofit Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  RPCSw::VariableArray{3} = ReadDisk(db,"$Input/RPCSw",year) # Pollution Reduction Curve Switch (1=2009,2=2004) [EC,Poll,Area]
  RPCTC::VariableArray{4} = ReadDisk(db,"$Outpt/RPCTC",year) # Retrofit Process Capital Trade Off Coefficient (DLESS) [Enduse,Tech,EC,Area]
  RPEE::VariableArray{4} = ReadDisk(db,"$Outpt/RPEE",year) # Retrofit Process Efficiency ($/BTU) [Enduse,Tech,EC,Area]
  RPEEFr::VariableArray{4} = ReadDisk(db,"$Input/RPEEFr",year) # Process Efficiency Fraction for Retrofits ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  RPEI::VariableArray{4} = ReadDisk(db,"$Outpt/RPEI",year) # Energy Impact of Pollution Reduction (Btu/Btu) [Enduse,Tech,EC,Area]
  RPEIX::VariableArray{4} = ReadDisk(db,"$Input/RPEIX",year) # Energy Impact of Pollution Reduction Coefficient (Btu/Btu/Tonne/Tonne) [Enduse,Tech,EC,Area]
  RPEMM::VariableArray{4} = ReadDisk(db,"$Input/RPEMM",year) # Process Efficiency Max. Mult. ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  RPEStd::VariableArray{4} = ReadDisk(db,"$Input/RPEStd",year) # Retrofit Process Efficiency Standard ($/Btu) [Enduse,Tech,EC,Area]
  RPFTC::VariableArray{4} = ReadDisk(db,"$Outpt/RPFTC",year) # Retrofit Process Fuel Trade Off Coefficient [Enduse,Tech,EC,Area]
  RPIVTC::VariableArray{1} = ReadDisk(db,"$Input/RPIVTC",year) # Process Retrofit Policy Investment Tax Credit ($/$) [Area]
  RPMSF::VariableArray{4} = ReadDisk(db,"$Outpt/RPMSF",year) # Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  RPMSLimit::VariableArray{2} = ReadDisk(db,"$Input/RPMSLimit",year) # Process Retrofit Market Share Limit (1/Yr) [EC,Area]
  RPMSM::VariableArray{4} = ReadDisk(db,"$CalDB/RPMSM",year) # Process Retrofit Market Share Multiplier (1/Yr) [Enduse,Tech,EC,Area]
  RPPrior::VariableArray{4} = ReadDisk(db,"$Outpt/RP",prior) # Pollutant Reduction (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  RPolECC::VariableArray{3} = ReadDisk(db,"SOutput/RPolicy",year) # Reduction Policy (Tonnes/Tonnes) [ECC,Poll,Area]
  RPolicy::VariableArray{3} = ReadDisk(db,"$Outpt/RPolicy",year) # Reduction Policy (Tonnes/Tonnes) [EC,Poll,Area]
  RPVF::VariableArray{2} = ReadDisk(db,"$Input/RPVF") # Process Retrofit Market Share Variance Factor (DLESS) [EC,Area]
  RRisk::VariableArray{3} = ReadDisk(db,"$Input/RRisk",year) # Retrofit Excess Risk ($/$) [Enduse,Tech,Area]
  SbMSM0::VariableArray{4} = ReadDisk(db,"$Input/SbMSM0",year) # Non-Price Factor for High Efficiency Device Market Share ($/$) [Enduse,Tech,EC,Area]
  SbVF::VariableArray{4} = ReadDisk(db,"$Input/SbVF",year) # Price Variance Factor for High Efficiency Device Market Share ($/$) [Enduse,Tech,EC,Area]
  SqDmd::VariableArray{3} = ReadDisk(db,"$Outpt/SqDmd",year) # Sequestering Energy Demand (TBtu/Yr) [Tech,EC,Area]
  SqDmdFuel::VariableArray{3} = ReadDisk(db,"$Outpt/SqDmdFuel",year) # Sequestering Fuel Demands (TBtu/Yr) [Fuel,EC,Area]
  SqEUTechMap::VariableArray{2} = ReadDisk(db,"$Input/SqEUTechMap") # Sequestering Enduse Map to Tech (1=include) [Enduse,Tech]
  SqFuelCost::VariableArray{2} = ReadDisk(db,"SOutput/SqFuelCost",year) # Sequestering Fuel Costs ($/Tonnes) [ECC,Area]
  SqPenaltyFrac::VariableArray{3} = ReadDisk(db,"MEInput/SqPenaltyFrac",year) # Sequestering Emission Penalty (Tonne/Tonne)[ECC,Poll,Area]
  SqPenaltyTech::VariableArray{4} = ReadDisk(db,"$Input/SqPenaltyTech",year) # Sequestering Energy Penalty (TBtu/Tonne) [Tech,EC,Poll,Area]
  SqPolCCNet::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCNet",year) # Sequestering Non-Cogeneration Emissions (Tonnes/Yr) [ECC,Poll,Area]
  SqPolCCPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCPenalty",year) # Sequestering Emissions Penalty (Tonnes/Yr) [ECC,Poll,Area]
  SqPolCg::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCg",year) # Sequestering Cogeneration Emissions (Tonnes/Yr) [ECC,Poll,Area]
  SqPolCgPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCgPenalty",year) # Sequestering Cogeneration Emissions Penalty (Tonnes/Yr) [ECC,Poll,Area]
  SqPotential::VariableArray{3} = ReadDisk(db,"SOutput/SqPotential",year) # Potential Sequestering Emissions (Tonnes/Yr) [ECC,Poll,Area]
  StHR::VariableArray{1} = ReadDisk(db,"SInput/StHR",year) # Steam Generation Heat Rate (Btu/Btu) [Area]
  StockAdjustment::VariableArray{4} = ReadDisk(db,"$Input/StockAdjustment",year) # Exogenous Capital Stock Adjustment ($/$) [Enduse,Tech,EC,Area]
  StPur::VariableArray{2} = ReadDisk(db,"SOutput/StPur",year) # Net Steam Purchases (tBtu/Yr) [ECC,Area]
  StSold::VariableArray{2} = ReadDisk(db,"SOutput/StSold",year) # Excess Steam Generated (tBtu/Yr) [ECC,Area]
  STX::VariableArray{1} = ReadDisk(db,"$Input/STX",year) # Sales Tax Rate on Energy Consumer ($/$) [Area]
  STXB::VariableArray{1} = ReadDisk(BCNameDB,"$Input/STX",year) # Sales Tax Rate on Energy Consumer in Base Case ($/$) [Area]
  TFPol::VariableArray{4} = ReadDisk(db,"SOutput/TFPol",year) # Energy Sector Pollution (Tonnes/Yr) [FuelEP,Poll,Area]
  ThermalLimit::VariableArray{1} = ReadDisk(db,"SOutput/ThermalLimit",year) # Process Policy Investment Tax Credit ($/$) [Area,Year]
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) # Energy Demands (TBtu/Yr) [Fuel,ECC,Area]
  TotFPol::VariableArray{4} = ReadDisk(db,"SOutput/TotFPol",year) # Pollution (Tonnes/Yr) [FuelEP,ECC,Poll,Area]
  TSLoad::VariableArray{3} = ReadDisk(db,"$Input/TSLoad") # Temperature Sensitive Fraction of Load (Btu/Btu) [Enduse,EC,Area]
  TSPol::VariableArray{3} = ReadDisk(db,"SOutput/TSPol",year) # Energy Sector Pollution (Tonnes/Yr) [Sector,Poll,Area]
  TxRt::VariableArray{2} = ReadDisk(db,"$Input/TxRt",year) # Tax Rate on Energy Consumer ($/$) [EC,Area]
  TrPCovMap::VariableArray{4} = ReadDisk(db,"$Input/TrPCovMap",year) # 'Transportation Technology Pollution Coverage Map (1=Mapped)'[Tech,EC,PCov,Area]
  UMS::VariableArray{4} = ReadDisk(db,"$Outpt/UMS",year) # Short Term Price Response (Btu/Btu) [Enduse,Tech,EC,Area]
  VR::VariableArray{4} = ReadDisk(db,"$Outpt/VR",year) # Voluntary Reduction Policy (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  VRP::VariableArray{4} = ReadDisk(db,"$Input/VRP",year) # Voluntary Reduction Policy (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  VRPrior::VariableArray{4} = ReadDisk(db,"$Outpt/VR",prior) # Voluntary Reduction Policy (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  VRRT::VariableArray{1} = ReadDisk(db,"$Input/VRRT") # Voluntary Reduction response time (Years) [EC]
  xCgDmd::VariableArray{3} = ReadDisk(db,"$Input/xCgDmd",year) # Exogenous Cogeneration (TBtu/Yr) [Tech,EC,Area]
  xCgIGC::VariableArray{3} = ReadDisk(db,"$Input/xCgIGC",year) # Exogenous Indicated Cogeneration Capacity (MW) [Tech,EC,Area]
  xCgMSF::VariableArray{3} = ReadDisk(db,"$CalDB/xCgMSF",year) # Exogenous Cogeneration Market Share (Btu/Btu) [Tech,EC,Area]
  xCMSF::VariableArray{5} = ReadDisk(db,"$Input/xCMSF",year) # Conversion Market Share by Device ($/$) [Enduse,Tech,CTech,EC,Area]
  xDCC::VariableArray{4} = ReadDisk(db,"$Input/xDCC",year) # Device Capital Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  xDCCPolicy::VariableArray{4} = ReadDisk(db,"$Input/xDCCPolicy",year) # Capital Cost of Policy Device ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  xDCCYr::VariableArray{4} = ReadDisk(db,"$Input/xDCC",YrDCC) # Device Capital Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  xDEE::VariableArray{4} = ReadDisk(db,"$Input/xDEE",year) # Historical Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  xDEEPolicy::VariableArray{4} = ReadDisk(db,"$Input/xDEEPolicy",year) # Policy Device Efficiency (Btu/Btu) [Enduse,Tech,EC,Area]
  xDEEPolicyMSF::VariableArray{4} = ReadDisk(db,"$Input/xDEEPolicyMSF",year) # Policy Participation Response (Btu/Btu) [Enduse,Tech,EC,Area]
  xDmd::VariableArray{4} = ReadDisk(db,"$Input/xDmd",year) # Process Heat Energy (TBtu/Yr) [Enduse,Tech,EC,Area]
  xDSt::VariableArray{3} = ReadDisk(db,"$Input/xDSt",year) # Device Saturation (Btu/Btu) [Enduse,EC,Area]
  xEE::VariableArray{4} = ReadDisk(db,"$Input/xEE",year) # Exogenous Energy Efficiency (TBtu) [Enduse,Tech,EC,Area]
  xFsDmd::VariableArray{3} = ReadDisk(db,"$Input/xFsDmd",year) # Feedstock Energy (TBtu/Yr) [Tech,EC,Area]
  xPCC::VariableArray{4} = ReadDisk(db,"$Input/xPCC",year) # Process Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  xPEE::VariableArray{4} = ReadDisk(db,"$Input/xPEE",year) # Historical Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  xRDMSF::VariableArray{4} = ReadDisk(db,"$Input/xRDMSF",year) # Exogenous Device Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  xRM::VariableArray{4} = ReadDisk(db,"$Input/xRM",year) # Exogenous Average Pollution Coefficient Reduction Multiplier (Tonnes/Tonnes) [Tech,EC,Poll,Area]
  xRPCC::VariableArray{4} = ReadDisk(db,"$Input/xRPCC",year) # Exogenous Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  xRPEE::VariableArray{4} = ReadDisk(db,"$Input/xRPEE",year) # Exogenous Retrofit Process Efficiency ($/BTU) [Enduse,Tech,EC,Area]
  xRPMSF::VariableArray{4} = ReadDisk(db,"$Input/xRPMSF",year) # Exogenous Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  ZeroFr::VariableArray{3} = ReadDisk(db,"SInput/ZeroFr",year) # Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes) [FuelEP,Poll,Area]
  SqEnMap::VariableArray{1} = ReadDisk(db,"$Input/SqEnMap") # Sequestering Enduse Map (1=include) [Enduse]
  EnSqPot::VariableArray{3} = ReadDisk(db,"SOutput/EnSqPot",year) # Enduse Sequestering Potential (Tonnes/Yr) [ECC,Poll,Area]
  FsSqPot::VariableArray{3} = ReadDisk(db,"SOutput/FsSqPot",year) # Feedstock Sequestering Potential (Tonnes/Yr) [ECC,Poll,Area]
  xProcSw::VariableArray{1} = ReadDisk(db,"$Input/xProcSw",year) #[PI,Year] "Procedure on/off Switch"
  FTMap::VariableArray{3} = ReadDisk(db,"$Input/FTMap") # [Fuel,EC,Tech]   # Fuel to Technology Mapping
  Epsilon::Float32 = ReadDisk(db,"MainDB/Epsilon")[1] #[tv] A Very Small Number
  ElecMap::VariableArray{1} = ReadDisk(db,"$Input/ElecMap") # [Tech]
  
  #
  # Scratch Variables
  #
  AgingFactor::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Vintage)) # Aging Factor (1/DPL)) [Enduse,Tech,EC,Area,Vintage]
  APCC::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # Average Process Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  CgCCR::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Cogeneration Capital Charge Rate ($/Yr/$) [EC,Area]
  CgEAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # Cogeneration Electricity Allocation Weight ($/mmBtu) [Tech,EC,Area]
  CgFP::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Electric Price ($/mmBtu) [EC,Area]
  CgFP0::VariableArray{2} = zeros(Float32,length(EC),length(Area))# Electric Price ($/mmBtu) [EC,Area]
  CgGCCINode::VariableArray{4} = zeros(Float32,length(Plant),length(EC),length(Node),length(Area)) # Cogeneration Capacity Initiated (MW) [Plant,EC,Node,Area]
  CgGCCIPlant::VariableArray{3} = zeros(Float32,length(Plant),length(EC),length(Area)) # Cogeneration Capacity Initiated (MW) [Plant,EC,Area]
  CgMAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # Cogeneration Market Allocation Weight ($/$) [Tech,EC,Area]
  CgPCost1::VariableArray{3} = zeros(Float32,length(FuelEP),length(ECC),length(Area)) # (FuelEP,ECC,Area)    'Cogen Permit Cost ($/mmBtu)'
  CgPCost2::VariableArray{3} = zeros(Float32,length(Fuel),length(ECC),length(Area)) # (Fuel,ECC,Area) 'Cogen Permit Cost ($/mmBtu)'
  CgPCost3::VariableArray{3} = zeros(Float32,length(Fuel),length(EC),length(Area)) #(Fuel,EC,Area)  'Cogen Permit Cost ($/mmBtu)'
  CgPot0::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area))  # (Tech,EC,Area)    'Cogeneration Potential (MW)'
  CgPot1::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area))  # (Tech,EC,Area)    'Cogeneration Potential (MW)'
  CgPotElec::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # (EC,Area) 'Cogeneration Potential Electricity Demands (MW)'
  CgRatio::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] 'Cogeneration Cost Ratio $/$'
  CMAW::VariableArray{4} = zeros(Float32,length(Tech),length(CTech),length(EC),length(Area)) # [Tech,CTech,EC,Area]
  CTMAW::VariableArray{3} = zeros(Float32,length(CTech),length(EC),length(Area))  # [CTech,EC,Area]
  DCCRBefore::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DCCRP::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)); # [FuelFP,EC,Area]
  DCMMMEndo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DCMMMExo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DCMMMRaw::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DEEBefore::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DemCCRef::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) #[ECC,Area] 'Demand Capital Cost ($/mmBtu)'
  DEMMMEndo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DEMMMExo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DEMMMRaw::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DemRqAB::VariableArray{2} = zeros(Float32,length(Fuel),length(ECC)) #[Fuel,ECC] Marginal Energy Demand for Alberta (TBtu/Driver)
  DERAdj::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DERAgedV::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Vintage)); # Energy Requirement Aged to Next Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERAV::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Vintage)); # Energy Requirement Addition (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERBefore::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); # DER Before Exogenous Retrofits (mmBtu/YR) [Enduse,Tech,EC,Area]
  DmFracMAW::VariableArray{5} = zeros(Float32,length(Enduse),length(Fuel),length(Tech),length(EC),length(Area))  # [Enduse,Fuel,Tech,EC,Area] Allocation Weights for Demand Fuel/Tech Fraction (DLess)
  DmFracTMAW::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DmFracTotal::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DOMC::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  DStHPsPrior::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] AC Saturation for Various Heat Pump Systems in Prior Year (Btu/Btu)
  ECMarket::VariableArray{2} = zeros(Float32,length(EC),length(Market)); # [EC,Market]
  EuDemF::VariableArray{4} = zeros(Float32,length(Enduse),length(Fuel),length(ECC),length(Area)) # Energy Demands (tBtu/Yr) [Enduse,Fuel,ECC,Area]
  EUPCAdj::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(Age),length(ECC),length(Area)) # (Enduse,Tech,Age,EC,Area)  'Production Capacity Adjustment (M$/Yr/Yr)'
  EUPCTemp::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(ECC),length(Area)) # [Enduse,Fuel,ECC,Area]
  FsFracMAW::VariableArray{4} = zeros(Float32,length(Fuel),length(Tech),length(EC),length(Area)) # (Fuel,Tech,EC,Area)    'Allocation Weights for Demand Fuel/Tech Fraction (DLess)'
  FsFracTMAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # (Tech,EC,Area)   'Total of Allocation Weights for Demand Fuel/Tech Fraction (DLess)'
  FsFracTotal::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # (Tech,EC,Area)  'Total of Demand Fuel/Tech Fractions (Btu/Btu)'
  FXCO::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # (Enduse,Tech,EC,Area)
  GrossEnFPol::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Poll),length(Area)) # [Tech,EC,Poll,Area] Energy Emissions before Reductions (Tonnes/Yr)
  LastVintage::Int = 0 # Last Vintage (Vintage Pointer)
  MAW::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # Marginal Allocation Weight ($/$) [Enduse,Tech,EC,Area]
  MAWBefore::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  MAWPolicy::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  MCFUBefore::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  MMSFAll::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area]
  MMSFHPs::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Marginal Market Share for AC Various Heat Pump Systems (Btu/Btu)
  MMSFOther::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area]
  NB::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area));
  PCCovTemp::VariableArray{5} = zeros(Float32,length(Tech),length(EC),length(Poll),length(PCov),length(Area));
  PCMMMEndo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  PCMMMExo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  PCMMMRaw::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  PEECurve10::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area));
  PEECurve11::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area));
  PEMMMEndo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  PEMMMExo::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  PEMMMRaw::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  PenultimateVintage::Int = 0 # Penultimate (Next to Last) Vintage (Vintage Pointer)
  PERAdj::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)); #[Enduse,Tech,EC,Area]
  POEMA::VariableArray{6} = zeros(Float32,length(Enduse),length(FuelEP),length(Tech),length(EC),length(Poll),length(Area)) # Pollution Additions (Tonnes/Yr) [enduse,fuelep,ec,poll,area]
  POEMR::VariableArray{6} = zeros(Float32,length(Enduse),length(FuelEP),length(Tech),length(EC),length(Poll),length(Area)) # Pollution Retirements (Tonnes/Yr) [enduse,fuelep,ec,poll,area]
  ProcSw::VariableArray{1} = zeros(Float32,length(PI)) #[PI,Year] "Procedure on/off Switch"
  RPFull::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Poll),length(Area)); # (FuelEP,EC,Poll,Area)
  SPC::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Total Production Capacity (M$/Yr) [EC,Area]
  SPC0::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Total Production Capacity (M$/Yr) [EC,Area]
  SPop::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Population (Millions) [EC,Area]
  SPop0::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Population (Millions) [EC,Area]
  SqDmdFuelEP::VariableArray{3} = zeros(Float32,length(FuelEP),length(EC),length(Area));
  SqPolCCPenaltyEC::VariableArray{3} = zeros(Float32,length(EC),length(Poll),length(Area)); # [ec,poll,area]
  TMAW::VariableArray{3} = zeros(Float32,length(Enduse),length(EC),length(Area)) # [Enduse,EC,Area]
  WCUF::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Capacity Utilization Factor Weighted by Output ($/$) [EC,Area]

end

function PRReductions(data::Data)
  (; db,year) = data
  (; Area,Areas,EC,ECs,ECC,Enduses,FuelEPs,Markets) = data
  (; PCovs,Polls,PollXs,Tech,Techs) = data
  (; ANMap,AreaMarket,CapTrade,CM,DCCRP,DCCRPrior) = data
  (; DmdFEPTechPrior,ECCMarket,ECMarket,ECovECC,ECoverage) = data
  (; GPFrac,GPFrECC,Inflation,IPCost,IRP,Markets,PCCov) = data
  (; PCCovTemp,PCost,PCostECC,PCostExo,PCostM,PCostN) = data
  (; PCostPrior,POCS,POCX,PollMarket,PVF,RCC) = data
  (; RCD,RCostM,RM,ROCF,RP,RPCSw,RPEI,RPEIX,RPFull) = data
  (; RPolECC,RPolicy,TrPCovMap,VR,VRP,VRPrior,VRRT,xRM) = data

  #@info " $ESKey Demand.jl, PRReductions, Pollution Reductions and Costs"

  #
  # Pollution Reduction Policy
  #
    
  #
  # Map input variables from ECC to EC
  #
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    
    for area in Areas,poll in Polls,pcov in PCovs
      ECoverage[ec,poll,pcov,area] = ECovECC[ecc,poll,pcov,area]
    end 
    
    for area in Areas,poll in Polls,tech in Techs
      for pcov in PCovs
        PCCovTemp[tech,ec,poll,pcov,area] = (ECoverage[ec,poll,pcov,area]*
          TrPCovMap[tech,ec,pcov,area])
      end
      PCCov[tech,ec,poll,area] = maximum(PCCovTemp[tech,ec,poll,:,area])
    end

    for area in Areas,poll in Polls,tech in Techs
      PCost[tech,ec,poll,area] = PCostECC[ecc,poll,area]*PCCov[tech,ec,poll,area]
    end
    
    for area in Areas,poll in Polls,pcov in PCovs   
      GPFrac[ec,poll,pcov,area] = GPFrECC[ecc,poll,pcov,area]
    end
    
    for area in Areas,poll in Polls 
      RPolicy[ec,poll,area] = RPolECC[ecc,poll,area]
    end
    
    for market in Markets
      ECMarket[ec,market] = ECCMarket[ecc,market]
    end
  end

  WriteDisk(db,"$Input/ECoverage",year,ECoverage)
  WriteDisk(db,"$Outpt/GPFrac",year,GPFrac)
  WriteDisk(db,"$Outpt/PCCov",year,PCCov)
  WriteDisk(db,"$Outpt/RPolicy",year,RPolicy)

  #
  # Map Device Capital Charge Rate from Tech to FuelEP
  # using the first enduse.
  #
  enduse = 1
  for tech in Select(Tech), area in Select(Area), ec in Select(EC)
    DCCRP[tech,ec,area] = DCCRPrior[enduse,tech,ec,area]
  end

  #
  # Voluntary reductions are based on exogenous goal and time lag.
  #
  for tech in Techs,ec in ECs,poll in Polls,area in Areas
    @finite_math VR[tech,ec,poll,area] = VRPrior[tech,ec,poll,area]+
      DT*(VRP[tech,ec,poll,area]-VRPrior[tech,ec,poll,area])/VRRT[ec]
  end

  #
  # If system has an emission Cap and emissions Trading (CapTrade = 1 or 3),
  # then the input is the permit cost (PCost).
  # permit cost (PCost),the capital charge rate (DCCRP) and the O&M costs (ROCF).
  #
  for market in Markets
    areas = findall(AreaMarket[:,market] .== 1)
    ecs = findall(ECMarket[:,market] .== 1)    
    polls = findall(PollMarket[:,market] .== 1)
    if (!isempty(areas)) && (!isempty(ecs)) && (!isempty(polls))
    
      #
      # Do if policy is a cap with trading (CapTrade = 1)
      #
      if (CapTrade[market] == 1) || (CapTrade[market] == 3)

        #    
        # The capital cost of the reduction technology (RCC) is based on the
        # permit cost (PCost), the capital charge rate (DCCRP) and the O&M costs (ROCF).
        #
        for tech in Techs,ec in ecs,poll in polls,area in areas
          @finite_math RCC[tech,ec,poll,area] = 
            (PCost[tech,ec,poll,area]*PCCov[tech,ec,poll,area]*Inflation[area]+
            PCostExo[tech,ec,poll,area]*Inflation[area])/
            (DCCRP[tech,ec,poll,area]+ROCF[tech,ec,poll,area])
        end

        for area in areas
          # nation = Select(ANMap[area,Nation], ==(1))
          nation = only(Select(ANMap[area, :], .==(1)))
          for ec in ecs, poll in polls, tech in Techs
          
            #
            #  For the Reduction Curves from 2009 (RPCSw=1),the Indicated
            #  Reductions (IRP) is a function of the capital costs (RCC)
            #  and the Reduction Cost Curve (PCostN,PVF)
            #
            if RPCSw[ec,poll,area] == 1
              @finite_math IRP[tech,ec,poll,area] = 
                ln(RCC[tech,ec,poll,area]/Inflation[area]/
                (PCostN[tech,ec,poll,area]/PCostM[tech,ec,poll,area]/
                RCostM[tech,ec,poll,area]))/
              PVF[tech,ec,poll,area]*PCCov[tech,ec,poll,area]
            
            #
            # For the Reduction Curves from 2004 (RPCSw=2), the indicated
            # reductions (IRP) are a function of the permit cost (PCost)
            # and the pollution reduction curve parameters (PCostN, PVF)
            # adjusted by the reductions cost multiplier (RCostM) for the
            # covered emissions (PCCov)
            #
            elseif (RPCSw[ec,poll,area] == 2) && 
                  (PCost[tech,ec,poll,area] != 0 || 
                    PCostExo[tech,ec,poll,area] != 0) &&
                   (PCostN[tech,ec,poll,area] != 0) &&
                   (PVF[tech,ec,poll,area] != 0)
              @. CostMax = max(((PCost+PCostExo)*PCostM),0.01)
              @finite_math IRP[tech,ec,poll,area] = 1/(1+((CostMax[tech,ec,poll,area]*
                RCostM[tech,poll])/PCostN[tech,ec,poll,area])^
                PVF[tech,ec,poll,area])*PCCov[tech,ec,poll,area]
            end
          end
        end
        
        #
        # Actual Reductions (RP) are increased by changes in Indicated Reductions (IRP)
        # after the construction time (RCD) and reduced by the physical lifetime (RCPL).
        #
        for tech in Techs, ec in ecs, poll in polls, area in areas
          @finite_math RP[tech,ec,poll,area] = RPPrior[tech,ec,poll,area]+
            (max(RPPrior[tech,ec,poll,area],IRP[tech,ec,poll,area])-
            RPPrior[tech,ec,poll,area])/RCD[ec,poll]-
            RPPrior[tech,ec,poll,area]/RCPL[ec,poll]
        end
        
      elseif (CapTrade[market] == 2) || (CapTrade[market] == 4)
      
        #
        # The Pollution Reduction (RP) is the maximum of the reduction
        # policy (RPolicy) and the pollution standard (POCS) times the
        # emissions coverage (ECoverage,PCCov).
        #
        for tech in Techs, ec in ecs, poll in polls, area in areas
          RP[tech,ec,poll,area] = max(RPolicy[ec,poll,area],
            (1-minimum(POCS[:,:,tech,ec,poll,area])/
            max(maximum(POCX[:,:,tech,ec,poll,area]),0.000001)))*
            PCCov[tech,ec,poll,area]
        end
        
        @. RPFull = 1-(1-RP)*xRM
        
        for area in areas
          #
          # nation = Select(ANMap[area,Nation], ==(1))
          #
          nation = only(Select(ANMap[area, :], .==(1)))          
          for ec in ecs,poll in polls

            #
            # For the Reduction Curves from 2009 (RPCSw=1),
            #
            if RPCSw[ec,poll,area] == 1
              for tech in Techs
                if RPFull[tech,ec,poll,area] > 0.0
                  @finite_math RCC[tech,ec,poll,area] = (PCostN[tech,ec,poll,area]/
                    RCostM[tech,ec,poll,area])*exp(PVF[tech,ec,poll,area]*
                    RPFull[tech,ec,poll,area] )*Inflation[area]
                else
                  RCC .= 0.0
                end
              end
              
            #
            # For the Reduction Curves from 2004 (RPCSw=2),the capital cost of the
            # reduction technology (RCC) based on the reduction (RP) and the pollution
            # reduction curve parameters (PCostN,PVF) adjusted by the reductions cost
            # multiplier (RCostM).
            # Constrain costs until we check the Lumber reduction curves
            #
            elseif RPCSw[ec,poll,area] == 2
            
              for tech in Techs
                @finite_math RCC[tech,ec,poll,area] = 
                  (1/RPFull[tech,ec,poll,area]-1)^(1/PVF[tech,ec,poll,area])*
                  PCostN[tech,ec,poll,area]/RCostM[tech,ec,poll,area]/
                  (DCCRP[tech,ec,poll,area]+ROCF[tech,ec,poll,area])*Inflation[area]
              end
              
              @. RCC = min(RCC,1e9)
            #
            # For the Reduction Curves from 2011 (RPCSw=3),
            #
            elseif RPCSw[ec,poll,area] == 3
              for tech in Select(Tech)
                if RPFull[tech,ec,poll,area] > 0
                  @finite_math RCC[tech,ec,poll,area] = 
                    (PCostN[tech,ec,poll,area]/RCostM[tech,ec,poll,area])*
                    exp(PVF[tech,ec,poll,area]*RPFull[tech,ec,poll,area])*Inflation[area]
                else
                  RCC[tech,ec,poll,area] = 0
                end
              end
              
              #
              # Constrain costs until we check the Lumber reduction curves
              #
              @. RCC = min(RCC,1e9)
              
            end
          end
        end
        
        #
        # Effective Permit Cost (IPCost)
        #
        for tech in Techs, ec in ecs, poll in polls, area in areas
          @finite_math IPCost[tech,ec,poll,area] = RCC[tech,ec,poll,area]*
            (DCCRP[tech,ec,area]+ROCF[tech,ec,poll,area])/Inflation[area]
        end       
        
        #
        # Smoothed Permit Cost (PCost)
        #
        for tech in Techs, ec in ecs, poll in polls, area in areas
          @finite_math PCost[tech,ec,poll,area] =
            PCostPrior[tech,ec,poll,area]+(IPCost[tech,ec,poll,area]-
            PCostPrior[tech,ec,poll,area])/RCD[ec,poll]
        end
      
      #
      # Else CapTrade equals 5 for the GHG markets
      # There are currently no reduction curves for GHG so just apply
      # permit cost (PCost) to covered sectors (PCCov/PCCov not zero).
      #
      elseif CapTrade[market] == 5
        for tech in Techs, ec in ecs, poll in polls, area in areas
          RP[tech,ec,poll,area] = 0.0
          RCC[tech,ec,poll,area] = 0.0
          if PCCov[tech,ec,poll,area] == 0
            PCost[tech,ec,poll,area] = 0
          end
        end
      end # if (CapTrade[market] == 1)
      
    end # (!isempty(areas))
  end # for market in Markets
  
  #
  # Reduction in some Pollutants cause reductions in other Pollutants.
  # This relationship is specified in the cross multiplier (CM).
  #
  
  #
  # Find net reduction multiplier (RM) including the cross impacts (RPXP)
  # and the volunatry reductions (VR).
  #
  @. RM = (1.0-RP)*(1.0-VR)*xRM

  #
  # Energy impact (RPEI) of emission reductions (RP) - Jeff Amlin 02/11/23
  #
  for ec in ECs,area in Areas,enduse in Enduses,tech in Techs
    @finite_math RPEI[enduse,tech,ec,area] = prod((1+
      RP[tech,ec,poll,area] *
      RPEIX[enduse,tech,ec,area]) for  poll in Polls)
  end

  WriteDisk(db,"$Outpt/IPCost",year,IPCost)
  WriteDisk(db,"$Outpt/IRP",year,IRP)
  WriteDisk(db,"$Outpt/PCost",year,PCost)
  WriteDisk(db,"$Outpt/RCC",year,RCC)
  WriteDisk(db,"$Outpt/RM",year,RM)
  WriteDisk(db,"$Outpt/RP",year,RP)
  WriteDisk(db,"$Outpt/RPEI",year,RPEI)
  WriteDisk(db,"$Outpt/VR",year,VR)

end

function TPrice(data::Data)
  (; db,year,CTime) = data
  (; Area,Areas,EC,ECs,ECC,Enduses,ES,ESes,Fuel,FuelKey,Fuels) = data
  (; FuelEPKey,FuelEPs,Poll,Polls,Techs) = data
  (; CoverageCFS,DmdFEPTechPrior,DmdFuelTechPrior) = data
  (; ECESMap,ECFP,ECFPFuel,ExpCP,FFPMap,FPCFS) = data
  (; FPCFSFuel,FPCFSLast,FPCFSNet,FPCFSObligated,FPCFSTech) = data
  (; FPCP,FPCPFrac,FPEC,FPECC,FPECCCFS,FPECCCFSCP,FPECCCFSCPNet) = data
  (; FPECCCFSNet,FPECCCP,FPECCCPNet,FPF,FPOGEC,FPECCOGEC,FPTech,Inflation) = data
  (; OBAFraction,PCost,PCostExo,PCostTech,PE,POCX,PolConv) = data
  (; PolMarginal,RM,ZeroFr) = data
  
  #@info " $ESKey Demand.jl, TPrice - Enduse Prices"

  #
  # Impact of Permit Costs on MCFU - map between FuelEP and Tech and
  # convert from $/Tonnes to $/mmBtu.
  #
  for tech in Techs,ec in ECs,poll in Polls,area in Areas
    @finite_math PolMarginal[tech,ec,poll,area] = 
      sum(POCX[enduse,fuelep,tech,ec,poll,area]*(1-ZeroFr[fuelep,poll,area])*
      RM[tech,ec,poll,area]*
      max(DmdFEPTechPrior[fuelep,tech,ec,area],1e-12)
      for enduse in Enduses, fuelep in FuelEPs)
  end
  WriteDisk(db,"$Outpt/PolMarginal",year,PolMarginal)

  for tech in Techs, ec in ECs, area in Areas
    @finite_math ExpCP[tech,ec,area] = sum(((PolMarginal[tech,ec,poll,area]*
      PCost[tech,ec,poll,area]+PCostExo[tech,ec,poll,area])*Inflation[area]/1e6)
      for poll in Polls)
  end
  WriteDisk(db,"$Outpt/ExpCP",year,ExpCP)
  
  for tech in Techs, ec in ECs, area in Areas
    @finite_math PCostTech[tech,ec,area] = 
      ExpCP[tech,ec,area]/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses, fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/PCostTech",year,PCostTech)
  
  for fuel in Fuels, ec in ECs, area in Areas
    @finite_math FPCP[fuel,ec,area] = sum(PCostTech[tech,ec,area]*
      DmdFuelTechPrior[enduse,fuel,tech,ec,area]*FPCPFrac[fuel,ec,area] for enduse in Enduses, tech in Techs)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area]*FPCPFrac[fuel,ec,area] for enduse in Enduses, tech in Techs)
  end
  WriteDisk(db,"$Outpt/FPCP",year,FPCP)

  #
  # FPCFS - CFR Prices
  #
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  es = Select(ES,ESKey)
  for area in Areas, ec in ECs, fuel in Fuels 
    ecc = Select(ECC,EC[ec])
    FPCFS[fuel,ec,area] = FPCFSFuel[fuel,es,area]*CoverageCFS[fuel,ecc,area]
    for fuelep in FuelEPs
      if FuelKey[fuel] == FuelEPKey[fuelep]   
        FPCFS[fuel,ec,area] = FPCFS[fuel,ec,area]+FPCFSObligated[ecc,area]*    
          sum(POCX[1,fuelep,tech,ec,poll,area]*(1-ZeroFr[fuelep,poll,area])*PolConv[poll]*
              max(DmdFEPTechPrior[fuelep,tech,ec,area],1e-12) for tech in Techs, poll in polls)/
          sum(max(DmdFEPTechPrior[fuelep,tech,ec,area],1e-12) for tech in Techs)/1e6
      end
    end
  end
  WriteDisk(db,"$Outpt/FPCFS",year,FPCFS)
  
  for area in Areas, ec in ECs, fuel in Fuels
    ecc = Select(ECC,EC[ec])
    FPOGEC[fuel,ec,area] = FPECCOGEC[fuel,ecc,area]
  end
  WriteDisk(db,"$Outpt/FPOGEC",year,FPOGEC)

  #
  # FPCFSNet - Net CFR Prices
  #
  @. FPCFSNet = FPCFS
  areas = Select(Area,"BC")
  for area in areas, ec in ECs, fuel in Fuels
    if CTime < HisTime
      FPCFSNet[fuel,ec,area] = 0.00
    else
      FPCFSNet[fuel,ec,area] = FPCFS[fuel,ec,area]-FPCFSLast[fuel,ec,area]
    end
  end
  WriteDisk(db,"$Outpt/FPCFSNet",year,FPCFSNet)
  
  #
  # FPCFSTech - CFR Prices by Tech
  #
  for tech in Techs,ec in ECs,area in Areas
    @finite_math FPCFSTech[tech,ec,area] = sum(FPCFSNet[fuel,ec,area]*
          DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,fuel in Fuels)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/FPCFSTech",year,FPCFSTech)

  #
  # Fuel Prices by Sector (EC)
  #
  for fuel in Fuels,ec in ECs,area in Areas
    FPEC[fuel,ec,area] = sum(FPF[fuel,es,area]*ECESMap[ec,es] for es in ESes)
  end

  ElectricFuels = Select(Fuel,["Electric","Geothermal","Solar"])
  for fuel in ElectricFuels,area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    FPEC[fuel,ec,area] = PE[ecc,area]/3412*1000
  end
  WriteDisk(db,"$Outpt/FPEC",year,FPEC)

  #
  # Fuel Prices by Tech
  #
  for ec in ECs,tech in Techs,area in Areas
    @finite_math FPTech[tech,ec,area] = 
      sum(FPEC[fuel,ec,area]*DmdFuelTechPrior[1,fuel,tech,ec,area] for fuel in Fuels)/
      sum(                   DmdFuelTechPrior[1,fuel,tech,ec,area] for fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/FPTech",year,FPTech)

  @. ECFPFuel = FPEC+FPCFSNet+FPCP+FPOGEC
  WriteDisk(db,"$Outpt/ECFPFuel",year,ECFPFuel)

  for ec in ECs,tech in Techs,area in Areas,enduse in Enduses
    @finite_math ECFP[enduse,tech,ec,area] = 
      sum((FPEC[fuel,ec,area]+FPCFSNet[fuel,ec,area]+FPOGEC[fuel,ec,area])*
          DmdFuelTechPrior[enduse,fuel,tech,ec,area] for fuel in Fuels)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for fuel in Fuels)+
      PCostTech[tech,ec,area]

    ECFP[enduse,tech,ec,area] = max(ECFP[enduse,tech,ec,area], FPTech[tech,ec,area]*0.50)
  end
  WriteDisk(db,"$Outpt/ECFP",year,ECFP)

  #
  # Price Variables by ECC
  #
  for fuel in Fuels,area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    FPECCCP[fuel,ecc,area] = FPCP[fuel,ec,area]
    FPECCCPNet[fuel,ecc,area] = FPECCCP[fuel,ecc,area]*(1-OBAFraction[ecc,area])
    FPECC[fuel,ecc,area] = FPEC[fuel,ec,area]
  end
  WriteDisk(db,"SOutput/FPECCCP",year,FPECCCP)
  WriteDisk(db,"SOutput/FPECCCPNet",year,FPECCCPNet)
  WriteDisk(db,"SOutput/FPECC",year,FPECC)


  for fuel in Fuels,area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    FPECCCFS[fuel,ecc,area] = FPECC[fuel,ecc,area]+FPCFSNet[fuel,ec,area]
    FPECCCFSNet[fuel,ecc,area] = FPECCCFS[fuel,ecc,area]-FPECC[fuel,ecc,area]
    FPECCCFSCP[fuel,ecc,area] = FPECC[fuel,ecc,area]+FPECCCFSNet[fuel,ecc,area]+FPECCCP[fuel,ecc,area]+FPECCOGEC[fuel,ecc,area]
    FPECCCFSCPNet[fuel,ecc,area] = FPECC[fuel,ecc,area]+FPECCCFSNet[fuel,ecc,area]+FPECCCPNet[fuel,ecc,area]+FPECCOGEC[fuel,ecc,area]
  end
  
  WriteDisk(db,"SOutput/FPECCCFS",year,FPECCCFS)
  WriteDisk(db,"SOutput/FPECCCFSNet",year,FPECCCFSNet)
  WriteDisk(db,"SOutput/FPECCCFSCP",year,FPECCCFSCP)
  WriteDisk(db,"SOutput/FPECCCFSCPNet",year,FPECCCFSCPNet)

end

function SmoothEmissionCosts(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs) = data
  (; PrPCostSw,PCostTech,FPCFSTech,eCO2Price,eCO2PriceExo,Inflation) = data
  (; PrPCostPrior,PrPCostAT,PrPCostMarPrior) = data
  (; PrPCostMar,PrPCost) = data

  #@debug "SmoothEmissionCosts Function Call"

  if PrPCostSw == 1.0
    @. PrPCostMar = PCostTech+FPCFSTech
  elseif PrPCostSw == 2.0
    for tech in Techs,ec in ECs,area in Areas
      PrPCostMar[tech,ec,area] = eCO2Price[area]+eCO2PriceExo[area]*Inflation[area]
    end
  else
    PrPCostMar = PrPCostPrior
  end

  for area in Areas,ec in ECs,tech in Techs
    if PrPCostMarPrior[tech,ec,area] == 0
      PrPCost[tech,ec,area] = PrPCostMar[tech,ec,area]
    else
      PrPCost[tech,ec,area] = PrPCostMar[tech,ec,area]*(1/PrPCostAT[ec,area])+PrPCostPrior[tech,ec,area]*(1-1/PrPCostAT[ec,area])
    end
  end

  WriteDisk(db,"$Outpt/PrPCostMar",year,PrPCostMar)
  WriteDisk(db,"$Outpt/PrPCost",year,PrPCost)

end

function AgeVintages(data::Data)
  (; db,year) = data
  (; Areas,ECs,Enduses,Techs,Vintage,Vintages) = data
  (; AgingFactor,DEEAV,DEEAVPrior,DERV,DERVAllocation,DERAgedV,DERVPrior,DERVSum,DPL) = data

  #
  # AgingFactor is a local variable for now defined as number of vintages over DPL
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, vintage in Vintages
    @finite_math AgingFactor[enduse,tech,ec,area,vintage] = min(Int(length(Vintage))/DPL[enduse,tech,ec,area], 1.0)
    DERAgedV[enduse,tech,ec,area,vintage] = DERVPrior[enduse,tech,ec,area,vintage]*AgingFactor[enduse,tech,ec,area,vintage]
  end
  
  FirstVintage = 1
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    DERV[enduse,tech,ec,area,FirstVintage] = DERVPrior[enduse,tech,ec,area,FirstVintage]-DERAgedV[enduse,tech,ec,area,FirstVintage]
  end

  LastVintage=Int(length(Vintage))
  PenultimateVintage = LastVintage-1
  vintages = collect(2:PenultimateVintage) 
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, vintage in vintages
    vintageprior = vintage-1
    DERV[enduse,tech,ec,area,vintage] = DERVPrior[enduse,tech,ec,area,vintage]-DERAgedV[enduse,tech,ec,area,vintage]+
                                        DERAgedV[enduse,tech,ec,area,vintageprior]
  end

  LastVintage = Int(length(Vintage))
  vintageprior = LastVintage-1
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    DERV[enduse,tech,ec,area,LastVintage] = DERVPrior[enduse,tech,ec,area,LastVintage]+DERAgedV[enduse,tech,ec,area,vintageprior]
  end

  #
  # Vintage Average Efficiency
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    @finite_math DEEAV[enduse,tech,ec,area,FirstVintage] = 
                 (DERVPrior[enduse,tech,ec,area,FirstVintage]*DEEAVPrior[enduse,tech,ec,area,FirstVintage]-
                 DERAgedV[enduse,tech,ec,area,FirstVintage]*DEEAVPrior[enduse,tech,ec,area,FirstVintage])/
                 DERV[enduse,tech,ec,area,FirstVintage]
     for vintage in vintages
       vintageprior = vintage-1
       @finite_math DEEAV[enduse,tech,ec,area,vintage] = 
                    (DERVPrior[enduse,tech,ec,area,vintage]*DEEAVPrior[enduse,tech,ec,area,vintage]-
                    DERAgedV[enduse,tech,ec,area,vintage]*DEEAVPrior[enduse,tech,ec,area,vintage] +
                    DERAgedV[enduse,tech,ec,area,vintageprior]*DEEAVPrior[enduse,tech,ec,area,vintageprior])/
                    DERV[enduse,tech,ec,area,vintage]
     end
    vintageprior = LastVintage-1
    @finite_math DEEAV[enduse,tech,ec,area,LastVintage] = 
                 (DERVPrior[enduse,tech,ec,area,LastVintage]*DEEAVPrior[enduse,tech,ec,area,LastVintage]-
                 DERAgedV[enduse,tech,ec,area,vintageprior]*DEEAVPrior[enduse,tech,ec,area,vintageprior])/
                 DERV[enduse,tech,ec,area,LastVintage]
  end
  WriteDisk(db,"$Outpt/DEEAV",year,DEEAV)
  WriteDisk(db,"$Outpt/DERV",year,DERV)

  #
  # Device Allocations for each Vintage (note Vintage(1) is empty)
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    DERVSum[enduse,tech,ec,area] = sum(DERV[enduse,tech,ec,area,vintage] for vintage in Vintages)
    for vintage in Vintages
      @finite_math DERVAllocation[enduse,tech,ec,area,vintage] = DERV[enduse,tech,ec,area,vintage] /
                                                                 DERVSum[enduse,tech,ec,area]
    end
  end

  WriteDisk(db,"$Outpt/DERVSum",year,DERVSum)
  WriteDisk(db,"$Outpt/DERVAllocation",year,DERVAllocation)

end

function CapacityUtilization(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC) = data
  (; PC,SPC,SPC0) = data
  (; PC0,Pop,Pop0,WCUF,SPop0,SPop,ECUF) = data

  #@debug "CapacityUtilization  Function Call"

  #
  # Map production capacity (PC),population (Pop),and capacity utilization
  # factor (ECUF) from the large economic category set (ECC) into production
  # capacity (SPC),population (SPop),and capacity utilization factor (WCUF)
  # with the single sector economic category set (EC).
  #
  for ec in ECs,area in Areas
    ecc = Select(ECC,EC[ec])
    SPC[ec,area] = PC[ecc,area]
    SPC0[ec,area] = PC0[ecc,area]
    SPop[ec,area] = max(Pop[ecc,area],0.000001)
    SPop0[ec,area] = max(Pop0[ecc,area],0.000001)
    WCUF[ec,area] = ECUF[ecc,area]
  end
end

function DMarginal(data::Data)
  (; db,OGRefName,SceName,year,Vintage) = data
  (; Areas,ECs,Techs,Enduses,Poll,PCov) = data
  (; BaseSw,CROIN,DCC,DCCA0,DCCB0,DCCBeforeStd,DCCC0,DCCFullCost,DCCLimit) = data
  (; DCCN,DCCPoll,DCCPrice,DCCR,DCCRB,DCCRef,DCDEM,DCMM,DCMMM) = data
  (; DCMMMEndo,DCMMMExo,DCMMMRaw,DCTC,DEE,DEEA0,DEEB0) = data
  (; DEEBeforeStd,DEEC0,DEEFloorSw,DEEPoll,DEEPrice,DEEPrior) = data
  (; DEERef,DEESw,DEEThermalMax,DEM,DEMM,DEMMM,DEMMMEndo) = data
  (; DEMMMExo,DEMMMRaw,DEPM,DEStd,DEStdP,DFPN,DFTC,DGF,DIVTC) = data
  (; DPIVTC,DPLN,DRisk,DTL,ECFP,ECoverage,ECovExo,FPCFSTech) = data
  (; Inflation,Inflation2010,InSm,PCostTech,PrPCost,ROIN,STX) = data
  (; STXB,TxRt,xDEE,xDCC,xDCCYr) = data

  #@debug "DMarginal  Function Call"


  if OGRefName == SceName
    @. DCCRef = DCC
    @. DEERef = DEE
  end
  
  #
  # Device Efficiency and Capital Costs
  #
  for tech in Techs,ec in ECs,area in Areas,enduse in Enduses
    @finite_math DCCR[enduse,tech,ec,area] = (1-(DIVTC[tech,area] +DPIVTC)/
      (1+ROIN[ec,area]-CROIN[enduse,tech,ec,area]+DRisk[enduse,tech] +InSm[area])-
      TxRt[ec,area] *(2/DTL[enduse,tech,ec,area])/(ROIN[ec,area]-CROIN[enduse,tech,ec,area]+DRisk[enduse,tech]+
      InSm[area]+2/DTL[enduse,tech,ec,area]))*(ROIN[ec,area]-CROIN[enduse,tech,ec,area]+DRisk[enduse,tech])/
      (1-(1/(1+ROIN[ec,area]-CROIN[enduse,tech,ec,area]+DRisk[enduse,tech]))^DPLN[enduse,tech,ec,area])/(1-TxRt[ec,area])
  end
  WriteDisk(db,"$Outpt/DCCR",year,DCCR)

  #
  # If this is the Base Case,then DCCRB equals DCCR.  If this is not the 
  # Base Case (BaseSw=0), then set DCCRB is equal to DCCR from the Base Case 
  # and is read from the Base Case database.
  #
  if BaseSw == 1
    @. DCCRB = DCCR
    @. STXB = STX
  end

  #
  # Device Energy Efficiency Curve for Pollution Costs (PrPCost)
  #
  CO2 = Select(Poll,"CO2")
  Energy = Select(PCov,"Energy")
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DEMMMRaw[enduse,tech,ec,area] = 1+DEEC0[enduse,tech,ec,area]/
      (1+DEEA0[enduse,tech,ec,area]*(PrPCost[tech,ec,area]/Inflation[area]*
      Inflation2010[area])^DEEB0[enduse,tech,ec,area])*
      (PrPCost[tech,ec,area]/PrPCost[tech,ec,area])
      
    @finite_math DEMMMEndo[enduse,tech,ec,area] = DEMMMRaw[enduse,tech,ec,area]*
     ECoverage[ec,CO2,Energy,area]+1.000*(1-ECoverage[ec,CO2,Energy,area])
    
    DEMMMExo[enduse,tech,ec,area] = DEMMMRaw[enduse,tech,ec,area]*
      ECovExo[ec,CO2,Energy,area]+1.000*(1-ECovExo[ec,CO2,Energy,area])
    
    DEMMM[enduse,tech,ec,area] = max(DEMMMEndo[enduse,tech,ec,area],DEMMMExo[enduse,tech,ec,area])

    @finite_math DCMMMRaw[enduse,tech,ec,area] = 1+DCCC0[enduse,tech,ec,area]/
      (1+DCCA0[enduse,tech,ec,area]*(PrPCost[tech,ec,area]/Inflation[area]*
      Inflation2010[area])^DCCB0[enduse,tech,ec,area])*
      (PrPCost[tech,ec,area]/PrPCost[tech,ec,area])+
      (DEMMM[enduse,tech,ec,area]-1)*DCDEM[enduse,tech,ec,area]

    @finite_math DCMMMEndo[enduse,tech,ec,area] = DCMMMRaw[enduse,tech,ec,area]*
      ECoverage[ec,CO2,Energy,area]+1.000*(1-ECoverage[ec,CO2,Energy,area])
      
    DCMMMExo[enduse,tech,ec,area] = DCMMMRaw[enduse,tech,ec,area]*
      ECovExo[ec,CO2,Energy,area]+1.000*(1-ECovExo[ec,CO2,Energy,area])
      
    DCMMM[enduse,tech,ec,area] = max(DCMMMEndo[enduse,tech,ec,area],DCMMMExo[enduse,tech,ec,area])

  end

  WriteDisk(db,"$Outpt/DEMMM",year,DEMMM)
  WriteDisk(db,"$Outpt/DCMMM",year,DCMMM)


  #
  # Marginal device efficiency (DEE) is determined by the relative energy
  # price (ECFP,DFPN) and the device efficiency curve parameters (DEM,DFTC).
  # Changes in the device capital charge rate (DCCRB,DCCR) use an assumed
  # Cobb-Douglas subsitution from Capital (not the same causality as "to"
  # capital from curves.)  The device efficiency multiplier (DEMM),the
  # domestic grant fraction (DGF) and the device price multiplier (DEPM)
  # are policy variables.
  #
  for enduse in Enduses,area in Areas,tech in Techs,ec in ECs
    @finite_math DEEPrice[enduse,tech,ec,area] = 
      DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]*
      (1/(1+(ECFP[enduse,tech,ec,area]/Inflation[area]*
       DEPM[enduse,tech,ec,area]/DFPN[enduse,tech,ec,area])^DFTC[enduse,tech,ec,area]*
      (1-DGF[enduse,tech,ec,area])*((1+STX[area])/(1+STXB[area]))*
      (DCCR[enduse,tech,ec,area]/DCCRB[enduse,tech,ec,area])))

    #
    # Patch instances where DFPN = 0 to match Promula outputs
    # Ian - 12/02/24
    #
    if DFPN[enduse,tech,ec,area] == 0
      if DEM[enduse,tech,ec,area] > 0 && DEMM[enduse,tech,ec,area] > 0
        DEEPrice[enduse,tech,ec,area] = DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]*0.98
      end
    end
  end
  
  @. DEEBeforeStd = DEEPrice
  
  for enduse in Enduses,area in Areas,tech in Techs,ec in ECs
    DEEPrice[enduse,tech,ec,area] = min(max(DEEPrice[enduse,tech,ec,area],
      DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area],
      (DEEPrior[enduse,tech,ec,area]*DEEFloorSw[area])),
      DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]*0.98)
  end
 
  #
  # Device Efficiency using Energy Efficiency Curve from Pollution Costs
  #
  for enduse in Enduses,area in Areas,tech in Techs,ec in ECs
    @finite_math DEEPoll[enduse,tech,ec,area] = 
      DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]*DEMMM[enduse,tech,ec,area]*
      (1/(1+((ECFP[enduse,tech,ec,area]-PCostTech[tech,ec,area]-FPCFSTech[tech,ec,area])/
      Inflation[area]*
      DEPM[enduse,tech,ec,area]/DFPN[enduse,tech,ec,area])^DFTC[enduse,tech,ec,area]*
      (1-DGF[enduse,tech,ec,area])*((1+STX[area])/(1+STXB[area]))*
      (DCCR[enduse,tech,ec,area]/DCCRB[enduse,tech,ec,area])))
  end

  for enduse in Enduses,area in Areas,tech in Techs,ec in ECs
    DEEPoll[enduse,tech,ec,area] = min(max(DEEPoll[enduse,tech,ec,area],
      DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area],
      (DEEPrior[enduse,tech,ec,area]*DEEFloorSw[area])),
      DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]*DEMMM[enduse,tech,ec,area]*0.98)
  end

  for enduse in Enduses,area in Areas,tech in Techs,ec in ECs
    if DEESw[enduse,tech,ec,area] == 1.0
      DEE[enduse,tech,ec,area] = DEEPrice[enduse,tech,ec,area]
    elseif DEESw[enduse,tech,ec,area] == 2.0
      DEE[enduse,tech,ec,area] = DEEPoll[enduse,tech,ec,area]
    elseif DEESw[enduse,tech,ec,area] == 3.0
      DEE[enduse,tech,ec,area] = max(DEEPrice[enduse,tech,ec,area],DEEPoll[enduse,tech,ec,area])
    elseif DEESw[enduse,tech,ec,area] == 6.0
      DEE[enduse,tech,ec,area] = DEERef[enduse,tech,ec,area]
      
    elseif DEESw[enduse,tech,ec,area] == 10
    
      @finite_math DEE[enduse,tech,ec,area] = DEMM[enduse,tech,ec,area]*
        (DEEC0[enduse,tech,ec,area]+DEEB0[enduse,tech,ec,area]*
        log(ECFP[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055)) 
        
      DEE[enduse,tech,ec,area] = min(max(DEE[enduse,tech,ec,area],
        DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area],
        (DEEPrior[enduse,tech,ec,area]*DEEFloorSw[area])),
        DCCB0[enduse,tech,ec,area])

    elseif DEESw[enduse,tech,ec,area] == 11
    
      ECFP[enduse,tech,ec,area] = max(ECFP[enduse,tech,ec,area],0.001)
      DEE[enduse,tech,ec,area] = DEMM[enduse,tech,ec,area]*
        (DEEC0[enduse,tech,ec,area]+DEEB0[enduse,tech,ec,area]/
        sqrt(ECFP[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055))
        
      DEE[enduse,tech,ec,area] = min(max(DEE[enduse,tech,ec,area],
        DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area],
        (DEEPrior[enduse,tech,ec,area]*DEEFloorSw[area])),
        DCCB0[enduse,tech,ec,area])
        
    elseif DEESw[enduse,tech,ec,area] == 12
      
      @finite_math DEE[enduse,tech,ec,area] = DEMM[enduse,tech,ec,area]*
        (DEEC0[enduse,tech,ec,area]+DEEB0[enduse,tech,ec,area]/
        (ECFP[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055)) 
        
      DEE[enduse,tech,ec,area] = min(max(DEE[enduse,tech,ec,area],
        DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area],
        (DEEPrior[enduse,tech,ec,area]*DEEFloorSw[area])),
        DCCB0[enduse,tech,ec,area])
    
    elseif DEESw[enduse,tech,ec,area] == 0.0
      DEE[enduse,tech,ec,area] = xDEE[enduse,tech,ec,area]
    end
    
    #
    # Check that DEE is below thermal maximum if constrained
    #
    DEE[enduse,tech,ec,area] = min(DEE[enduse,tech,ec,area],DEEThermalMax[enduse,tech,ec,area])

    #
    # Device Capital Cost (DCCPrice) from Efficiency/Capital Cost
    # Trade-off Curve (DCCN,DCMM,DCTC) and Energy Price (DEEPrice)
    #
    @finite_math DCCPrice[enduse,tech,ec,area] = 
      DCCN[enduse,tech,ec,area]*DCMM[enduse,tech,ec,area]*
      (DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]/DEEPrice[enduse,tech,ec,area]-1)^
      (1/min(DCTC[enduse,tech,ec,area],-0.01))*
      (1+STX[area])*(1-DGF[enduse,tech,ec,area])*Inflation[area]
    
    @. DCCBeforeStd = DCCPrice
      
    DCCPrice[enduse,tech,ec,area] = max(0,min(DCCPrice[enduse,tech,ec,area],
      xDCCYr[enduse,tech,ec,area]*DCCLimit[enduse,tech,ec,area]*
      DCMM[enduse,tech,ec,area]*Inflation[area]))

    #
    # Device Capital Costs (DCCPoll) using Energy Efficiency
    # Curve (DCMMM) from Pollution Costs (DEEPoll)
    #
    @finite_math DCCPoll[enduse,tech,ec,area] = 
      DCCN[enduse,tech,ec,area]*DCMM[enduse,tech,ec,area]*DCMMM[enduse,tech,ec,area]*
      (DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]*DEMMM[enduse,tech,ec,area]/
      DEEPoll[enduse,tech,ec,area]-1)^(1/min(DCTC[enduse,tech,ec,area],-0.01))*
      (1+STX[area])*(1-DGF[enduse,tech,ec,area])*Inflation[area]
      
    DCCPoll[enduse,tech,ec,area] = max(0,min(DCCPoll[enduse,tech,ec,area],
      xDCCYr[enduse,tech,ec,area]*DCCLimit[enduse,tech,ec,area]*
      DCMM[enduse,tech,ec,area]*DCMMM[enduse,tech,ec,area]*Inflation[area]))

    if DEESw[enduse,tech,ec,area] == 1.0
      DCC[enduse,tech,ec,area] = DCCPrice[enduse,tech,ec,area]
    elseif DEESw[enduse,tech,ec,area] == 2.0
      DCC[enduse,tech,ec,area] = DCCPoll[enduse,tech,ec,area]
    elseif DEESw[enduse,tech,ec,area] == 3.0
      if DEEPrice[enduse,tech,ec,area] >= DEEPoll[enduse,tech,ec,area]
        DCC[enduse,tech,ec,area] = DCCPrice[enduse,tech,ec,area]
      else
        DCC[enduse,tech,ec,area] = DCCPoll[enduse,tech,ec,area]
      end
    elseif DEESw[enduse,tech,ec,area] == 6.0
      DCC[enduse,tech,ec,area] = DCCRef[enduse,tech,ec,area]
    elseif DEESw[enduse,tech,ec,area] == 10
      @finite_math DCC[enduse,tech,ec,area] = (DCCC0[enduse,tech,ec,area]+
        exp((DEE[enduse,tech,ec,area]-DCCB0[enduse,tech,ec,area])/
        DCCA0[enduse,tech,ec,area]))/Inflation2010[area]*Inflation[area]
    elseif DEESw[enduse,tech,ec,area] == 11
      @finite_math DCC[enduse,tech,ec,area] = (DCCC0[enduse,tech,ec,area]+
        exp((DEE[enduse,tech,ec,area]-DCCB0[enduse,tech,ec,area])/
        DCCA0[enduse,tech,ec,area]))/Inflation2010[area]*Inflation[area]
    elseif DEESw[enduse,tech,ec,area] == 12
      @finite_math DCC[enduse,tech,ec,area] = (DCCC0[enduse,tech,ec,area]+
        exp((DEE[enduse,tech,ec,area]-DCCB0[enduse,tech,ec,area])/
        DCCA0[enduse,tech,ec,area]))/Inflation2010[area]*Inflation[area]
    elseif DEESw[enduse,tech,ec,area] == 0.0
      DCC[enduse,tech,ec,area] = xDCC[enduse,tech,ec,area]*Inflation[area]*(1+STX[area])
    end
    
    @finite_math DCCFullCost[enduse,tech,ec,area] = DCC[enduse,tech,ec,area]*
      ((1+STXB[area])/(1+STX[area]))/(1-DGF[enduse,tech,ec,area])
  end
  
  WriteDisk(db,"$Outpt/DCC",year,DCC)
  WriteDisk(db,"$Outpt/DCCFullCost",year,DCCFullCost)
  WriteDisk(db,"$Outpt/DCCPoll",year,DCCPoll)
  WriteDisk(db,"$Outpt/DCCPrice",year,DCCPrice)
  WriteDisk(db,"$Outpt/DCCBeforeStd",year,DCCBeforeStd)
  WriteDisk(db,"$Outpt/DEE",year,DEE)
  WriteDisk(db,"$Outpt/DEEBeforeStd",year,DEEBeforeStd)  
  WriteDisk(db,"$Outpt/DEEPoll",year,DEEPoll)
  WriteDisk(db,"$Outpt/DEEPrice",year,DEEPrice)

end

function DDSM(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs,Enduses) = data
  (; CROIN,DCC,DCCBefore,DCCFullCost,DCCPolicy,DCCR) = data
  (; DCCRBefore,DCCRPolicy,DCCSubsidy,DEE,DEEBefore) = data
  (; DEEPolicy,DEEPolicyMSF,DGF,DIVTC,DOCF,DPIVTC,DPLN) = data
  (; DRisk,DTL,ECFP,IdrtCost,Inflation,InSm,MAWBefore) = data
  (; MAWPolicy,MCFU,MCFUBefore,MCFUPolicy,ROIN,SbMSM0) = data
  (; SbVF,STX,STXB,TxRt,xDCCPolicy,xDEEPolicy,xDEEPolicyMSF) = data

  #@debug "DDSM Function Call"

  #
  # Subsidies for High Efficiency Devices
  #
  @. DCCBefore = DCC
  @. DEEBefore = DEE
  @. DCCRBefore = DCCR
  @. MCFUBefore = MCFU

  WriteDisk(db,"$Outpt/DCCBefore",year,DCCBefore)

  #
  # The efficiency and capital cost of the high efficiency device cannot be
  # lower than the "before" efficiency and capital cost.  Thus we will not
  # need to specify a high efficiency device for all technologies.
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    DEEPolicy[enduse,tech,ec,area] = max(xDEEPolicy[enduse,tech,ec,area],
      DEEBefore[enduse,tech,ec,area])
      
    DCCPolicy[enduse,tech,ec,area] = max(xDCCPolicy[enduse,tech,ec,area]*Inflation[area],
      DCCBefore[enduse,tech,ec,area])
  end

  WriteDisk(db,"$Outpt/DEEPolicy",year,DEEPolicy)
  WriteDisk(db,"$Outpt/DCCPolicy",year,DCCPolicy)

  #
  # The capital charge rate including incentives (DCCRPolicy) includes
  # policy investment tax credits (DPIVTC) and interest rate on
  # subsidized loans (CROIN).
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DCCRPolicy[enduse,tech,ec,area] = (1-(DIVTC[tech,area]+DPIVTC)/
      (1+ROIN[ec,area]-CROIN[enduse,tech,ec,area]+DRisk[enduse,tech]+InSm[area])-
      TxRt[ec,area]*(2/DTL[enduse,tech,ec,area])/
      (ROIN[ec,area]-CROIN[enduse,tech,ec,area]+DRisk[enduse,tech]+InSm[area]+
      2/DTL[enduse,tech,ec,area]))*
      (ROIN[ec,area]-CROIN[enduse,tech,ec,area]+DRisk[enduse,tech])/
      (1-(1/(1+ROIN[ec,area]-CROIN[enduse,tech,ec,area]+
      DRisk[enduse,tech]))^DPLN[enduse,tech,ec,area])/(1-TxRt[ec,area])
  end
  
  WriteDisk(db,"$Outpt/DCCRPolicy",year,DCCRPolicy)
  
  #
  # Marginal Fuel Cost
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math MCFUPolicy[enduse,tech,ec,area] = (DCCPolicy[enduse,tech,ec,area]-
      DCCSubsidy[enduse,tech,ec,area]*Inflation[area])*
      (DCCRPolicy[enduse,tech,ec,area]+DOCF[enduse,tech,ec,area])+ECFP[enduse,tech,ec,area]/
      DEEPolicy[enduse,tech,ec,area]+IdrtCost[enduse,tech,ec,area]*Inflation[area]
  end
  WriteDisk(db,"$Outpt/MCFUPolicy",year,MCFUPolicy)

  #
  # Market Share for High Efficiency Technology
  #
  @finite_math @. MAWBefore = exp(SbVF*log(MCFUBefore/MCFUBefore))
  @finite_math @. MAWPolicy = exp(SbMSM0+SbVF*log(MCFUPolicy/MCFUBefore))
  @finite_math @. DEEPolicyMSF = MAWPolicy/(MAWBefore+MAWPolicy)
 
  #
  # If High Efficiency Device Market Share is Exogenous
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    if xDEEPolicyMSF[enduse,tech,ec,area] >= 0.0
      DEEPolicyMSF = xDEEPolicyMSF
    end
  end
  WriteDisk(db,"$Outpt/DEEPolicyMSF",year,DEEPolicyMSF)

  #
  # Device Efficiency after combining policy devices with devices before policy
  #
  @. DEE = DEEBefore*(1-DEEPolicyMSF)+DEEPolicy*DEEPolicyMSF
  WriteDisk(db,"$Outpt/DEE",year,DEE)
  
  #
  # Device Efficiency after combining policy devices with devices before policy
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    DCC[enduse,tech,ec,area] = DCCBefore[enduse,tech,ec,area]*
    (1-DEEPolicyMSF[enduse,tech,ec,area])+
    (DCCPolicy[enduse,tech,ec,area]-DCCSubsidy[enduse,tech,ec,area]*Inflation[area])*
    DEEPolicyMSF[enduse,tech,ec,area]
  end
  WriteDisk(db,"$Outpt/DCC",year,DCC)
  
  #
  # Full Cost for Device Capital Cost after combining policy devices with
  # devices before policy.  This is sent to macroeconomic model.
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DCCFullCost[enduse,tech,ec,area] = (DCC[enduse,tech,ec,area]+
      DCCSubsidy[enduse,tech,ec,area]*Inflation[area]*
      DEEPolicyMSF[enduse,tech,ec,area])*((1+STXB[area])/(1+STX[area]))/
      (1-DGF[enduse,tech,ec,area])
  end
  WriteDisk(db,"$Outpt/DCCFullCost",year,DCCFullCost)
  
  #
  # The capital charge rate (DCCR) after combining policy devices with devices
  # before policy
  #
  @. DCCR = (DCCRBefore*(1-DEEPolicyMSF))+(DCCRPolicy*DEEPolicyMSF)
  WriteDisk(db,"$Outpt/DCCR",year,DCCR)

end

function MarginalCostOfFuelUsage(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs,Enduses) = data
  (; DOMC,DOCF,DCC,MCFU,DCCR,ECFP,DEE) = data
  (; DCCFullCost,IdrtCost,Inflation,Inflation) = data
  (; PCostTech,MCFUPoll,FPCFSTech) = data

  #@debug "MarginalCostOfFuelUsage Function Call"

  #
  # Device Operation and Maintenance Costs based on Full Cost
  #
  @. DOMC = DOCF*DCCFullCost
  
  #
  # Marginal Fuel Cost after combining policy devices with devices before policy
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math MCFU[enduse,tech,ec,area] = 
      DCCR[enduse,tech,ec,area]*DCC[enduse,tech,ec,area]+DOMC[enduse,tech,ec,area]+
      ECFP[enduse,tech,ec,area]/
      DEE[enduse,tech,ec,area]+
      IdrtCost[enduse,tech,ec,area]*Inflation[area]
    
    @finite_math MCFUPoll[enduse,tech,ec,area] = 
      DCCR[enduse,tech,ec,area]*DCC[enduse,tech,ec,area]+DOMC[enduse,tech,ec,area]+
      (ECFP[enduse,tech,ec,area]-PCostTech[tech,ec,area]-FPCFSTech[tech,ec,area])/
      DEE[enduse,tech,ec,area]+
      IdrtCost[enduse,tech,ec,area]*Inflation[area]
  end
  WriteDisk(db,"$Outpt/MCFU",year,MCFU)
  WriteDisk(db,"$Outpt/MCFUPoll",year,MCFUPoll)
  
end

function CMarginal(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs,Enduse,Enduses,Poll,PCov) = data
  (; BaseSw,CHR,CHRM,CROIN,ECoverage,ECovExo,Inflation) = data
  (; Inflation1997,Inflation2010,InSm,MCFU,MCFU0,MCFUPoll,OGRefName) = data
  (; PCC,PCCA0,PCCB0,PCCC0,PCCFC,PCCMM,PCCN,PCCPoll,PCCPrice) = data
  (; PCCR,PCCRB,PCCRef,PCMMM,PCMMMEndo,PCMMMExo,PCMMMRaw) = data
  (; PCPEM,PCTC,PEE,PEEA0,PEEB0,PEEBeforeStd,PEEC0,PEECurve) = data
  (; PEECurve10,PEECurve11,PEECurveM,PEEElas,PEEFloorSw,PEElas,PEEPoll) = data
  (; PEEPrice,PEEPrior,PEERef,PEESw,PEM,PEMM,PEMMM,PEMMMEndo,PEMMMExo) = data
  (; PEMMMRaw,PEPLN,PEPM,PERPrior,PEStd,PEStdP,PETL,PFPN) = data
  (; PFTC,PIVTC,PrPCost,ROIN,SceName,STX,STXB,TxRt,xPCC,xPEE) = data

  #@debug "CMarginal Function Call"
  
  if OGRefName == SceName
    @. PCCRef = PCC
    @. PEERef = PEE
  end
  
  #
  # Process Capital Charge Rate
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math PCCR[enduse,tech,ec,area] = (1-PIVTC[area]/(1+ROIN[ec,area]-
      CROIN[enduse,tech,ec,area]+InSm[area])-TxRt[ec,area]*
      (2/PETL[enduse,tech,ec,area])/(ROIN[ec,area]-CROIN[enduse,tech,ec,area]+
      InSm[area]+2/PETL[enduse,tech,ec,area]))*(ROIN[ec,area]-
      CROIN[enduse,tech,ec,area])/(1-(1/(1+ROIN[ec,area]-
      CROIN[enduse,tech,ec,area]))^PEPLN[enduse,tech,ec,area])/(1-TxRt[ec,area])
  end
  WriteDisk(db,"$Outpt/PCCR",year,PCCR)
  
  #
  # If this is the Base Case,then PCCRB equals PCCR.  If this is not the 
  # Base Case (BaseSw=0), then set PCCRB is equal to PCCR from the Base 
  # Case and is read from the Base Case database.
  #
  if BaseSw == 1
    @. PCCRB = PCCR
  end
  
  #
  # Process Energy Efficiency Curve for Pollution Costs (PrPCost)
  #
  CO2 = Select(Poll,"CO2")
  Energy = Select(PCov,"Energy")
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
  
    @finite_math PEMMMRaw[enduse,tech,ec,area] = 1+PEEC0[enduse,tech,ec,area]/
      (1+PEEA0[enduse,tech,ec,area]*(PrPCost[tech,ec,area]/
      Inflation[area]*Inflation2010[area])^PEEB0[enduse,tech,ec,area])*
      (PrPCost[tech,ec,area]/PrPCost[tech,ec,area])
    
    PEMMMEndo[enduse,tech,ec,area] = PEMMMRaw[enduse,tech,ec,area]*
      ECoverage[ec,CO2,Energy,area]+1.000*(1-ECoverage[ec,CO2,Energy,area])
    
    PEMMMExo[enduse,tech,ec,area] = PEMMMRaw[enduse,tech,ec,area]*
      ECovExo[ec,CO2,Energy,area]+1.000*(1-ECovExo[ec,CO2,Energy,area])
      
    PEMMM[enduse,tech,ec,area] = max(PEMMMEndo[enduse,tech,ec,area],PEMMMExo[enduse,tech,ec,area])

    @finite_math PCMMMRaw[enduse,tech,ec,area] = 1+PCCC0[enduse,tech,ec,area]/
      (1+PCCA0[enduse,tech,ec,area]*(PrPCost[tech,ec,area]/
      Inflation[area]*Inflation2010[area])^PCCB0[enduse,tech,ec,area])*
      (PrPCost[tech,ec,area]/PrPCost[tech,ec,area])+
      (PEMMM[enduse,tech,ec,area]-1)*PCPEM[enduse,tech,ec,area]
    
    PCMMMEndo[enduse,tech,ec,area] = PCMMMRaw[enduse,tech,ec,area]*ECoverage[ec,CO2,Energy,area]+
      1.000*(1-ECoverage[ec,CO2,Energy,area])
    
    PCMMMExo[enduse,tech,ec,area] = PCMMMRaw[enduse,tech,ec,area]*ECovExo[ec,CO2,Energy,area]+
      1.000*(1-ECovExo[ec,CO2,Energy,area])
    
    PCMMM[enduse,tech,ec,area] = max(PCMMMEndo[enduse,tech,ec,area],PCMMMExo[enduse,tech,ec,area])
  end

  WriteDisk(db,"$Outpt/PCMMM",year,PCMMM)
  WriteDisk(db,"$Outpt/PEMMM",year,PEMMM)


  #
  # Marginal device efficiency (PEE) is determined by the energy cost (MCFU),
  # the process efficiency curve and the process efficiency multiplier (PEMM).
  # Changes in capital charge rates (PCCRB/PCCR) assume Cobb-Douglas
  # subsitution from Capital (not the same causality as "to" capital from
  # curves.)
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas

    if PCCRB[enduse,tech,ec,area] > 0 &&
       MCFU[enduse,tech,ec,area]  > 0 &&
       PEPM[enduse,tech,ec,area]  > 0 &&
       PFPN[enduse,tech,ec,area]  > 0 &&
       PFTC[enduse,tech,ec,area] != 0
      PEEPrice[enduse,tech,ec,area] = 
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*
        (1/(1+(MCFU[enduse,tech,ec,area]/Inflation[area]*
        PEPM[enduse,tech,ec,area]/PFPN[enduse,tech,ec,area])^PFTC[enduse,tech,ec,area]*
        (PCCR[enduse,tech,ec,area]/PCCRB[enduse,tech,ec,area])))
    elseif PFTC[enduse,tech,ec,area] == 0 &&
          PFPN[enduse,tech,ec,area]  > 0  &&
          PCCRB[enduse,tech,ec,area] > 0
      PEEPrice[enduse,tech,ec,area] = 
        PEM[enduse,ec,area]*PEMM[enduse,tech,ec,area]*
        (1/(1+(PCCR[enduse,tech,ec,area]/PCCRB[enduse,tech,ec,area])))
    else
      PEEPrice[enduse,tech,ec,area] = 
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]
    end
    
    #
    # Process Efficiency using Energy Efficiency Curve from Pollution Costs
    #
    if PCCRB[enduse,tech,ec,area] > 0  &&
       MCFU[enduse,tech,ec,area]  > 0  &&
       PEPM[enduse,tech,ec,area]  > 0  &&
       PFPN[enduse,tech,ec,area]  > 0    
      PEEPoll[enduse,tech,ec,area] = PEM[enduse,tech,ec,area]*
        PEMM[enduse,tech,ec,area]*PEMMM[enduse,tech,ec,area]*
        (1/(1+(MCFUPoll[enduse,tech,ec,area]/Inflation[area]*
        PEPM[enduse,tech,ec,area]/PFPN[enduse,tech,ec,area])^
        PFTC[enduse,tech,ec,area]*(PCCR[enduse,tech,ec,area]/PCCRB[enduse,tech,ec,area])))
    else
      PEEPoll[enduse,tech,ec,area] = 
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*PEMMM[enduse,tech,ec,area]
    end
    
    #
    # Process Efficiency using Long Term Price Elasticity
    #
    @finite_math PEEElas[enduse,tech,ec,area] = PEM[enduse,tech,ec,area]*
      PEMM[enduse,tech,ec,area]*
      (1/(1+(MCFU[enduse,tech,ec,area]/Inflation[area]/MCFU0[enduse,tech,ec,area])^
      PEElas[enduse,tech,ec,area]))
      
  end

  #
  # Process Efficiency
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    if MCFU[enduse,tech,ec,area] >= 0
      @finite_math PEECurve10[enduse,tech,ec,area] = (PEEC0[enduse,tech,ec,area]+
        PEEB0[enduse,tech,ec,area]*
        log(MCFU[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055))*1.055/1e6
    else
      PEECurve10[enduse,tech,ec,area] = 0.00
    end
    @finite_math PEECurve10[enduse,tech,ec,area] = PEECurve10[enduse,tech,ec,area]/
      Inflation2010[area]*Inflation1997[area]*PEECurveM[enduse,tech,ec,area]

    @finite_math PEECurve11[enduse,tech,ec,area] = (PEEC0[enduse,tech,ec,area]+
      PEEB0[enduse,tech,ec,area]/
      ((MCFU[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055)^0.5))*1.055/1e6

    @finite_math PEECurve11[enduse,tech,ec,area] = PEECurve11[enduse,tech,ec,area]/
      Inflation2010[area]*Inflation1997[area]*PEECurveM[enduse,tech,ec,area]
  end

  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    if PEESw[enduse,tech,ec,area] == 1
      PEEBeforeStd[enduse,tech,ec,area] = PEEPrice[enduse,tech,ec,area]
      PEEPrice[enduse,tech,ec,area] = min(max(PEEPrice[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area]),
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*0.98)
      PEE[enduse,tech,ec,area] = PEEPrice[enduse,tech,ec,area]
      
    elseif PEESw[enduse,tech,ec,area] == 2
      PEEBeforeStd[enduse,tech,ec,area] = PEEPoll[enduse,tech,ec,area]
      PEEPoll[enduse,tech,ec,area] = min(max(PEEPoll[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area]),
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*0.98)
      PEE[enduse,tech,ec,area] = PEEPoll[enduse,tech,ec,area]
      
    elseif PEESw[enduse,tech,ec,area] == 3
      PEEBeforeStd[enduse,tech,ec,area] = max(PEEPrice[enduse,tech,ec,area],
        PEEPoll[enduse,tech,ec,area])
      PEEPrice[enduse,tech,ec,area] = min(max(PEEPrice[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area]),
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*0.98)
      PEEPoll[enduse,tech,ec,area] = min(max(PEEPoll[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area]),
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*PEMMM[enduse,tech,ec,area]*0.98)
      PEE[enduse,tech,ec,area] = max(PEEPrice[enduse,tech,ec,area],PEEPoll[enduse,tech,ec,area])
      
    elseif PEESw[enduse,tech,ec,area] == 4
      PEEBeforeStd[enduse,tech,ec,area] = PEEPrice[enduse,tech,ec,area]
      PEEPrice[enduse,tech,ec,area] = min(max(PEEPrice[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area]),
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*0.98)
      PEE[enduse,tech,ec,area] = PEEPrice[enduse,tech,ec,area]
      
    elseif PEESw[enduse,tech,ec,area] == 5
      PEEBeforeStd[enduse,tech,ec,area] = PEEElas[enduse,tech,ec,area]
      PEEPrice[enduse,tech,ec,area] = min(max(PEEElas[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area]),
        PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*0.98)
      PEE[enduse,tech,ec,area] = PEEElas[enduse,tech,ec,area]
      
    elseif PEESw[enduse,tech,ec,area] == 6
      PEE[enduse,tech,ec,area] = PEERef[enduse,tech,ec,area]
      
    elseif PEESw[enduse,tech,ec,area] == 10
      PEEBeforeStd[enduse,tech,ec,area] = PEECurve10[enduse,tech,ec,area]
      PEECurve[enduse,tech,ec,area] = max(PEECurve10[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area])
      PEE[enduse,tech,ec,area] = PEECurve[enduse,tech,ec,area]
     
    elseif PEESw[enduse,tech,ec,area] == 11
      PEEBeforeStd[enduse,tech,ec,area] = PEECurve11[enduse,tech,ec,area]
      PEECurve[enduse,tech,ec,area] = max(PEECurve11[enduse,tech,ec,area],
        PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area],
        PEEPrior[enduse,tech,ec,area]*PEEFloorSw[ec,area])
      PEE[enduse,tech,ec,area] = PEECurve[enduse,tech,ec,area]      
      
    elseif PEESw[enduse,tech,ec,area] == 0
      PEE[enduse,tech,ec,area] = xPEE[enduse,tech,ec,area]
    end

    #
    # The process capital cost (PCC) is computed based on the process
    # efficiency (PEE) in the efficiency/capital cost curve procedure.
    #
    @finite_math PCCPrice[enduse,tech,ec,area] = PCCN[enduse,tech,ec,area]*
      PCCMM[enduse,tech,ec,area]*Inflation[area]*
      (1+STX[area])*(PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]/
      PEEPrice[enduse,tech,ec,area]-1)^(1/PCTC[enduse,tech,ec,area])
    
    #
    # Process Capital Costs using Energy Efficiency Curve from Pollution Costs
    #
    @finite_math PCCPoll[enduse,tech,ec,area] = PCCN[enduse,tech,ec,area]*
      PCCMM[enduse,tech,ec,area]*PCMMM[enduse,tech,ec,area]*Inflation[area]*
      (1+STX[area])*
      (PEM[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]*PEMMM[enduse,tech,ec,area]/
      PEEPoll[enduse,tech,ec,area]-1)^(1/PCTC[enduse,tech,ec,area])
    
    #
    # Process Capital Cost depends on which Process Switch (PEESw)
    #
    if PEESw[enduse,tech,ec,area] == 1
      PCC[enduse,tech,ec,area] = PCCPrice[enduse,tech,ec,area]
    elseif PEESw[enduse,tech,ec,area] == 2
      PCC[enduse,tech,ec,area] = PCCPoll[enduse,tech,ec,area]
    elseif PEESw[enduse,tech,ec,area] == 3
      if PEEPrice[enduse,tech,ec,area] >= PEEPoll[enduse,tech,ec,area]
        PCC[enduse,tech,ec,area] = PCCPrice[enduse,tech,ec,area]
      else
        PCC[enduse,tech,ec,area] = PCCPoll[enduse,tech,ec,area]
      end
    elseif PEESw[enduse,tech,ec,area] == 4
      PCC[enduse,tech,ec,area] = PCCPrice[enduse,tech,ec,area]
    elseif PEESw[enduse,tech,ec,area] == 5
      PCC[enduse,tech,ec,area] = PCCPrice[enduse,tech,ec,area]
    elseif PEESw[enduse,tech,ec,area] == 6
      PCC[enduse,tech,ec,area] = PCCRef[enduse,tech,ec,area]
    elseif PEESw[enduse,tech,ec,area] == 0
      PCC[enduse,tech,ec,area] = xPCC[enduse,tech,ec,area]*Inflation[area]*(1+STX[area])
    end
  end

  #
  # The air conditioning process efficiency (PEE(AC)) is based on the
  # space heating process efficiency (PEE(Heat)),the heating-to-cooling
  # ratio (CHR),the heating-to-cooling ratio multiplier (CHRM),and the
  # process efficiency multiplier (PEMM).  If either space heating or air
  # do not exist as an enduse,then skip over the code.
  #
  if (SectorName == "Residential") || (SectorName == "Commercial")
    Heat = Select(Enduse,"Heat")
    AC = Select(Enduse,"AC")
    for tech in Techs,area in Areas,ec in ECs

      @finite_math PEE[AC,tech,ec,area] = 
        sum(PEE[Heat,AllTechs,ec,area]*
            PERPrior[Heat,AllTechs,ec,area] for AllTechs in Techs)/
        sum(PERPrior[Heat,AllTechs,ec,area] for AllTechs in Techs)/
        (CHR[ec,area]*CHRM[ec,area])*
        PEMM[AC,tech,ec,area]*PEMMM[AC,tech,ec,area]
   
      PCC[AC,tech,ec,area] = PCC[Heat,tech,ec,area]

    end
  end

  #
  # NRCan policy to make sure Informetrica sees full investment cost.
  #

  for tech in Techs,area in Areas,ec in ECs,enduse in Enduses
    @finite_math PCCFC[enduse,tech,ec,area] = PCC[enduse,tech,ec,area]*(1+STXB[area])/(1+STX[area])
  end

  WriteDisk(db,"$Outpt/PCC",year,PCC)
  WriteDisk(db,"$Outpt/PCCFC",year,PCCFC)
  WriteDisk(db,"$Outpt/PCCPoll",year,PCCPoll)
  WriteDisk(db,"$Outpt/PCCPrice",year,PCCPrice)
  WriteDisk(db,"$Outpt/PEE",year,PEE)
  WriteDisk(db,"$Outpt/PEEBeforeStd",year,PEEBeforeStd)
  WriteDisk(db,"$Outpt/PEEPoll",year,PEEPoll)
  WriteDisk(db,"$Outpt/PEEPrice",year,PEEPrice)
  
end

function CDSM(data::Data)
  #@debug "CDSM Function Call"
end

function IniRetrofits(data::Data)
  (; db,year) = data
  (; Area,Areas,EC,ECs,Enduse,Enduses,Tech,Techs) = data
  (; BaseSw,DCC,DCC,RDCCR,DIVTC,DRIVTC,ROIN,RCROIN,RRisk,InSm,TxRt) = data
  (; DTL,DPL,RDCCRB,PIVTC,PETL,PEPL,RPIVTC,RPCCRB,RPCCR) = data
  (; DERRR,MVDR,MVPR,PERRR,PFS,RDCC,RDEE,RDMSF,RPCC,RPEE,RPMSF) = data

  #@debug "IniRetrofits Function Call"

    #
    # Initialize Retrofits - this procedure is run even in the Base Case
    # to initialize values which will be used later in Retrofit policies.
    #
    # Retrofit Device Capital Charge Rates
    #
    # The incentive program capital charge rate (DCCSubsidy) is computed based
    # on the policy investment tax credits (DPIVTC) and the interest rate
    # on subsidized loans (CROIN).
    #
    for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
      @finite_math RDCCR[enduse,tech,ec,area] = (1-(DIVTC[tech,area]+DRIVTC[tech,area])/
        (1+ROIN[ec,area]-RCROIN[enduse,tech,ec,area]+RRisk[enduse,tech,area]+InSm[area])-TxRt[ec,area]*(2/DTL[enduse,tech,ec,area])/
        (ROIN[ec,area]-RCROIN[enduse,tech,ec,area]+RRisk[enduse,tech,area]+
        InSm[area]+2/DTL[enduse,tech,ec,area]))*(ROIN[ec,area]-RCROIN[enduse,tech,ec,area]+RRisk[enduse,tech,area])/
        (1-(1/(1+ROIN[ec,area]-RCROIN[enduse,tech,ec,area]+RRisk[enduse,tech,area]))^DPL[enduse,tech,ec,area])/(1-TxRt[ec,area])
    end

    if BaseSw == 1
      @. RDCCRB = RDCCR
    end
    #
    # Retrofit Process Captial Charge Rates
    # Same as PCCR except 50% of life left
    #
    for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
      @finite_math RPCCR[enduse,tech,ec,area] = (1-(PIVTC[area]+RPIVTC[area])/
        (1+ROIN[ec,area]-RCROIN[enduse,tech,ec,area]+InSm[area])-
        TxRt[ec,area]*(4/PETL[enduse,tech,ec,area])/
        (ROIN[ec,area]+0+InSm[area]+4/PETL[enduse,tech,ec,area]))*(ROIN[ec,area]-
        RCROIN[enduse,tech,ec,area])/
        (1-(1/(1+ROIN[ec,area]))^(PEPL[enduse,tech,ec,area]/2))/(1-TxRt[ec,area])
    end

    if BaseSw == 1
      @. RPCCRB = RPCCR
    end

    #
    # Initialize Retrofit outputs
    #


    DERRR = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    MVDR = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    MVPR = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    PERRR = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    PFS = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    RDCC = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    RDEE = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    RDMSF = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    RPCC = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    RPEE = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))
    RPMSF = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area))

    WriteDisk(db,"$Outpt/DERRR",year,DERRR)
    WriteDisk(db,"$Outpt/MVDR",year,MVDR)
    WriteDisk(db,"$Outpt/MVPR",year,MVPR)
    WriteDisk(db,"$Outpt/PERRR",year,PERRR)
    WriteDisk(db,"$Outpt/PFS",year,PFS)
    WriteDisk(db,"$Outpt/RDCC",year,RDCC)
    WriteDisk(db,"$Outpt/RDEE",year,RDEE)
    WriteDisk(db,"$Outpt/RDMSF",year,RDMSF)
    WriteDisk(db,"$Outpt/RPCC",year,RPCC)
    WriteDisk(db,"$Outpt/RPEE",year,RPEE)
    WriteDisk(db,"$Outpt/RPMSF",year,RPMSF)


end

function Retrofit(data::Data)
  (; db,year) = data
  (; Age,Ages,Areas,ECs,Enduse,Enduses,Techs) = data
  (; DCCN,DCMM,DCMMM,DEM,DEMM,DEMMM,DEEAPrior,DCTC,RRisk) = data
  (; EUPCPrior,EUPCRPC,Inflation,ADCC,RDCCRB) = data
  (; PEEAPrior,RetroSw,RDEE,RDMSF) = data
  (; DCCPrior,RDCC,MVDR,RDVF,RDMSM) = data
  (; PEM,RPEMM,PEMMM,PFPN,RPCCRB,RPCCR,RGF,MCFU,RPFTC) = data
  (; PEE,PEPM,RPEEFr,RPEE,PEEAPrior,RPEStd,RPCC,PCC,RPCCM) = data
  (; MVPR,ECFP,DEEAPrior,POCF,RHCM,RRisk,RPMSF,RPMSM,RPMSLimit) = data
  (; PERPrior,PERRPC,CHR,CHRM,RPEMM,RPCC,PFS,ECFP,PEEAPrior) = data
  (; xRPEE,xRPCC,xRPMSF,RDEStd,DCC,xRDMSF) = data
  (; DERRR,FXCO,MVDR,MVPR,PERRR,PFS,RDCC,RDEE,RDMSF,RPCC,RPEE,RPMSF) = data

  
  #@debug "Retrofit Function Call"

  #
  # Retrofit is efficiency not fuel decision. Process investment
  # will only last PEPL/2 years. Device has full life.  Process
  # retrofits cause reduction in device energy requirement for
  # stock.
  #
  # RetroSw = 1=Device,2=Process,3=Both,4=Exogenous
  #
  Old = Select(Age,"Old")
  for area in Areas, ec in ECs
    for enduse in Enduses
      if RetroSw[enduse,ec,area] == 1 || RetroSw[enduse,ec,area] == 3
        for tech in Techs
      
          #
          # Average Unit Cost of Device Stock
          #
          @finite_math ADCC[enduse,tech,ec,area] = DCCN[enduse,tech,ec,area]*DCMM[enduse,tech,ec,area]*
            DCMMM[enduse,tech,ec,area]*Inflation[area]*(DEM[enduse,tech,ec,area]*
            DEMM[enduse,tech,ec,area]*DEMMM[enduse,tech,ec,area]/
            DEEAPrior[enduse,tech,ec,area]-1)^(1/min(DCTC[enduse,tech,ec,area],-0.01))
      
          @finite_math RDEE[enduse,tech,ec,area] = DEM[enduse,tech,ec,area]*RDEMM[enduse,tech,ec,area]*
            DEMMM[enduse,tech,ec,area]*(1/(1+(ECFP[enduse,tech,ec,area]/Inflation[area]*
            DEPM[enduse,tech,ec,area]/DFPN[enduse,tech,ec,area])^RDFTC[enduse,tech,ec,area]*
            (1-RGF[enduse,tech,ec,area])*((1+STX[area])/(1+STXB[area]))*
            (RDCCR[enduse,tech,ec,area]/RDCCRB[enduse,tech,ec,area])))
      
          #
          # Retrofit Device Standard
          #
          RDEE[enduse,tech,ec,area] = max(DEE[enduse,tech,ec,area]*RDEMM[enduse,tech,ec,area],
            RDEStd[enduse,tech,ec,area])
        
          #
          # Retrofit Device Capital Costs
          #
          RDCC[enduse,tech,ec,area] = DCCPrior[enduse,tech,ec,area]*RDCCM[enduse,tech,ec,area]
      
          #
          # Marginal Value of Device Retrofits ($/$)
          #
          @finite_math MVDR[enduse,tech,ec,area] = (ECFP[enduse,tech,ec,area]*(1/DEEAPrior[enduse,tech,ec,area]-
            1/RDEE[enduse,tech,ec,area])-(RDCCR[enduse,tech,ec,area]+DOCF[enduse,tech,ec,area]+
            RHCM[ec,area])*RDCC[enduse,tech,ec,area])/RDCC[enduse,tech,ec,area]-
            RRisk[enduse,tech,area]
      
          @finite_math RDMSF[enduse,tech,ec,area] = max(0,MVDR[enduse,tech,ec,area])^(-RDVF[enduse,tech,ec,area])*
            RDMSM[enduse,tech,ec,area]/(max(0,MVDR[enduse,tech,ec,area])^(-RDVF[enduse,tech,ec,area])*
            RDMSM[enduse,tech,ec,area]+ROIN[ec,area]^(-RDVF[enduse,tech,ec,area]))
        
          #
          # Device Retrofit Market Share Fraction
          # Assume Cobb-Douglas subsitution from Capital (not the same causality
          # as "to" capital from curves.) Only make investment if 50% life left (1/2)
          #
          @finite_math RDMSF[enduse,tech,ec,area] = max(0,(1/(1+(DEEAPrior[enduse,tech,ec,area]/
            RDEE[enduse,tech,ec,area]))-0.5))/2*RDMSM[enduse,tech,ec,area]
      
          #
          # ***** Option **********

          @finite_math MVDR[enduse,tech,ec,area] = (ECFP[enduse,tech,ec,area]*
            (1/DEEAPrior[enduse,tech,ec,area]-1/RDEE[enduse,tech,ec,area]))/
            RDCC[enduse,tech,ec,area]-RRISK[enduse,tech,area]

          @finite_math RDMSF[enduse,tech,ec,area] = max(0,
            MVDR[enduse,tech,ec,area])^(-RDVF[enduse,tech,ec,area])*
            RDMSM[enduse,tech,ec,area]/(max(0,MVDR[enduse,tech,ec,area])^
            (-RDVF[enduse,tech,ec,area])*RDMSM[enduse,tech,ec,area]+(ROIN[ec,area]-
            RCROIN[enduse,tech,ec,area])^(-RDVF[enduse,tech,ec,area]))

          # *****
          #
        end # Tech
      end # if RetroSw

      #
      # Cost and Efficiency Decision
      #
      if RetroSw[enduse,ec,area] == 2 || RetroSw[enduse,ec,area] == 3  
        for tech in Techs       
          #
          #     Average Unit Cost of Process Stock
          #
          if (Enduse[enduse] == "Heat")      || (Enduse[enduse] == "Ground")  ||
             (Enduse[enduse] == "Air/Water") || (Enduse[enduse] == "Carriage")
            @finite_math APCC[enduse,tech,ec,area] = PCCN[enduse,tech,ec,area]*PCCMM[enduse,tech,ec,area]*
              PCMMM[enduse,tech,ec,area]*Inflation[area]*(PEM[enduse,tech,ec,area]*
              PEMM[enduse,tech,ec,area]*PEMMM[enduse,tech,ec,area]/
              PEEAPrior[enduse,tech,ec,area]-1)^(1/PCTC[enduse,tech,ec,area])
          end # if Enduse
    
          #
          # Retrofit Process Efficiency
          #
          @finite_math RPEE[enduse,tech,ec,area] = PEM[enduse,tech,ec,area]*RPEMM[enduse,tech,ec,area]*
            PEMMM[enduse,tech,ec,area]*(1/(1+(MCFU[enduse,tech,ec,area]/Inflation[area]*
            PEPM[enduse,tech,ec,area]/PFPN[enduse,tech,ec,area])^RPFTC[enduse,tech,ec,area]*
            (1-RGF[enduse,tech,ec,area])*(RPCCR[enduse,tech,ec,area]/RPCCRB[enduse,tech,ec,area])))

          #
          # Retrofit Process Standard. Assume can only go 50% of distance due to
          # structural contraints.
          #
          #     RPEE = xmax(((RPEE+PEEAPrior)/2),RPEStd)
          #     RPEE = RPEStd      
          #     RPEE = xmax(((PEE+PEEAPrior)/2*RPEMM),RPEStd)
          #
          @finite_math RPEE[enduse,tech,ec,area] = max((PEE[enduse,tech,ec,area]*
            RPEEFr[enduse,tech,ec,area]+PEEAPrior[enduse,tech,ec,area]*
            (1-RPEEFr[enduse,tech,ec,area]))*RPEMM[enduse,tech,ec,area],
            RPEStd[enduse,tech,ec,area])

          #
          # Retrofit Process Capital Costs
          #
          #  RPCC = (PCCN*PCCMM*PCMMM*Inflation*
          #       (PEM*RPEMM*PEMMM/RPEE-1)**(1/RPCTC)-APCC)*RPCCM
          #  RPCC = xmax(0,RPCC)
          #
          @. RPCC = PCC*RPCCM
  
          #
          # The energy savings is not based on MCFU because the fixed costs remain.
          # Process Investment Decision = $ Return/$ Invested
          #
          @finite_math MVPR[enduse,tech,ec,area] = (ECFP[enduse,tech,ec,area]/
            DEEAPrior[enduse,tech,ec,area]*(1/PEEAPrior[enduse,tech,ec,area]-1/
            RPEE[enduse,tech,ec,area])-(RPCCR[enduse,tech,ec,area]+
            POCF[enduse,tech,ec,area]+RHCM[ec,area])*RPCC[enduse,tech,ec,area])/
            RPCC[enduse,tech,ec,area]-RRisk[enduse,tech,area]

          #
          # Process Retrofit Market Share Fraction
          # Assume Cobb-Douglas subsitution from Capital (not the same causality
          # as "to" capital from curves.)
          # Only make investment if 50% life left (1/2)
          # Constrain the market share to be less than 95% - J. Amlin 11/11/04
          #
          @finite_math RPMSF[enduse,tech,ec,area] = min(max(0,(1/(1+(PEEAPrior[enduse,tech,ec,area]/
            RPEE[enduse,tech,ec,area]))-0.5))/2*RPMSM[enduse,tech,ec,area],RPMSLimit[ec,area])
          #
          #  RPMSF=xmax(0,MVPR)**(-RPVF)*RPMSM/ 
          #       (xmax(0,MVPR)**(-RPVF)*RPMSM+ROIN**(-RPVF))
        end # Tech
        # 
        #  The air conditioning process efficiency (PEE(AC)) is based on the
        #  space heating process efficiency (PEE(Heat)),the heating-to-cooling
        #  ratio (CHR),the heating-to-cooling ratio multiplier (CHRM),and the 
        #  process efficiency multiplier (PEMM).  If either space heating or air
        #   do not exist as an enduse,then skip over the code.
        #
        if (SectorName == "Residential") || (SectorName == "Commercial")
          Heat = Select(Enduse,"Heat")
          AC = Select(Enduse,"AC")
          if Enduse[enduse] == "AC"  
      
            @finite_math RPEE[AC,tech,ec,area] =
              sum(RPEE[Heat,tech,ec,area]*PERPrior[Heat,tech,ec,area] for tech in Techs)/
              sum(PERPrior[Heat,tech,ec,area] for tech in Techs)/
              CHR[ec,area]*CHRM[ec,area]*RPEMM[AC,tech,ec,area]
      
            RPCC[AC,tech,ec,area] = RPCC[Heat,tech,ec,area]
      
            @finite_math PFS[AC,tech,ec,area] = ECFP[AC,tech,ec,area]/
              DEEAPrior[AC,tech,ec,area]*
              (1/PEEAPrior[AC,tech,ec,area]-1/RPEE[AC,tech,ec,area])
          end # if Enduse
        end # if Sector
      end # Retrofit
    
      #
      # Exogenous retrofit efficiency and capital costs for all other enduses.
      #
      if RetroSw[enduse,ec,area] == 0
        # for tech in Techs
        @. RPEE = xRPEE
        @. RPCC = xRPCC
        @. RPMSF = xRPMSF
        @. RDEE = RDEStd
        @. RDCC = DCC
        @. RDMSF = xRDMSF
      end # Retrofit
    end # Enduse

    enduses = findall(RetroSw[:,ec,area] .>= 0)
    if isempty(enduses) 
      enduses = Select(Enduse)
    end
    for enduse in enduses
      if RetroSw[enduse,ec,area] .>= 0
        #
        # Capital stock remaining after retirements
        #
        for tech in Techs
          FXCO[enduse,tech,ec,area] = sum(EUPCPrior[enduse,tech,age,ec,area] for age in Ages)-
                                    EUPCRPC[enduse,tech,Old,ec,area]
        
          #
          # Reduction in Process Energy Requirements
          #
          @finite_math PERRR[enduse,tech,ec,area] = RPMSF[enduse,tech,ec,area]*
            FXCO[enduse,tech,ec,area]*(1/PEEAPrior[enduse,tech,ec,area]-
            1/RPEE[enduse,tech,ec,area])
          #
          # Reduction in device Energy Requirements
          #
          @finite_math DERRR[enduse,tech,ec,area] = RDMSF[enduse,tech,ec,area]*
            (PERPrior[enduse,tech,ec,area]-PERRPC[enduse,tech,ec,area])*
            (1/DEEAPrior[enduse,tech,ec,area]-1/RDEE[enduse,tech,ec,area])
        end # tech
      end # RetroSw
    end # enduse
  end # Area
  
  WriteDisk(db,"$Outpt/DERRR",year,DERRR)
  WriteDisk(db,"$Outpt/MVDR",year,MVDR)
  WriteDisk(db,"$Outpt/MVPR",year,MVPR)
  WriteDisk(db,"$Outpt/PERRR",year,PERRR)
  WriteDisk(db,"$Outpt/PFS",year,PFS)
  WriteDisk(db,"$Outpt/RDCC",year,RDCC)
  WriteDisk(db,"$Outpt/RDEE",year,RDEE)
  WriteDisk(db,"$Outpt/RDMSF",year,RDMSF)
  WriteDisk(db,"$Outpt/RPCC",year,RPCC)
  WriteDisk(db,"$Outpt/RPEE",year,RPEE)
  WriteDisk(db,"$Outpt/RPMSF",year,RPMSF)

end # function Retrofit


function CImpact(data::Data)
  #@debug "CImpact Function Call"
end

function MShare(data::Data)
  (; db,year) = data
  (; Areas,ECs,Enduses,Tech,Techs,PI) = data
  (; BaseSw,ETSwitch,MAW,MMSFB,MMSFSwitch,MMSM0,MSMM,MVF,MCFU) = data
  (; Inflation,Inflation0,PEE,MCFU0,PEE0,ThermalLimit,TMAW,MMSF,MMSFExogenous) = data
  (; MMSMI,MSLimit,SPC,SPop,SPC0,SPop0,ProcSw,Exogenous) = data

  #@debug " $ESKey Demand.src, MShare"

  #
  # Market Share Determination
  #

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    if Tech[tech] == "Storage"
      MSLimit[enduse,tech,ec,area] = ThermalLimit[area]
    else
      MSLimit[enduse,tech,ec,area] = 1.00
    end
  end
  WriteDisk(db,"$Outpt/MSLimit",year,MSLimit)

  for area in Areas,enduse in Enduses,ec in ECs,tech in Techs
    if MCFU[enduse,tech,ec,area]  > 0.0 && 
       MCFU0[enduse,tech,ec,area] > 0.0 &&
       PEE[enduse,tech,ec,area]   > 0.0 && 
       PEE0[enduse,tech,ec,area]  > 0.0 &&
       SPC[ec,area]               > 0.0 && 
       SPC0[ec,area]              > 0.0 && 
       SPop[ec,area]              > 0.0 && 
       SPop[ec,area]              > 0.0 && 
       MMSM0[enduse,tech,ec,area] > -150.0 
     
      MAW[enduse,tech,ec,area] = exp(MMSM0[enduse,tech,ec,area]+
        log(MSMM[enduse,tech,ec,area])+
        MMSMI[enduse,tech,ec,area]*(SPC[ec,area]/SPop[ec,area])/
                                    (SPC0[ec,area]/SPop0[ec,area])+
        MVF[enduse,tech,ec,area]*
        log((MCFU[enduse,tech,ec,area]/Inflation[area]/PEE[enduse,tech,ec,area])/
        (MCFU0[enduse,tech,ec,area]/Inflation0[area]/PEE0[enduse,tech,ec,area])))*
        MSLimit[enduse,tech,ec,area]
    else
      MAW[enduse,tech,ec,area] = 0.0
    end
  end
  
  for area in Areas,enduse in Enduses,ec in ECs,tech in Techs
    TMAW[enduse,ec,area] = sum(MAW[enduse,tech,ec,area] for tech in Techs)
    @finite_math MMSF[enduse,tech,ec,area] = MAW[enduse,tech,ec,area]/TMAW[enduse,ec,area]
  end

  #
  # If this is not the Base Case,then read the Market Share
  # from the Base Case
  #
  if BaseSw != 1

    #
    # Market expands for Emerging Technologies
    #
    for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
      MMSF[enduse,tech,ec,area] = MMSF[enduse,tech,ec,area]+
        max(MMSF[enduse,tech,ec,area]-MMSFB[enduse,tech,ec,area],0)*
        ETSwitch[tech,area] 
    end

    #
    # Normalize Market Share back to 1.0
    #
    for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
      TMAW[enduse,ec,area] = sum(MMSF[enduse,tech,ec,area] for tech in Techs)
    end
    for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
      @finite_math MMSF[enduse,tech,ec,area] = MMSF[enduse,tech,ec,area]/TMAW[enduse,ec,area]
    end
  end

  #
  # Exogenous Market Shares
  #
  pi = Select(PI,"MShare")
  if ProcSw[pi] == Exogenous
    for area in Areas, ec in ECs, enduse in Enduses
    
      MMSFExoTotal = 0.0
      techs = findall(MMSFSwitch[enduse,:,ec,area] .== 0)
      if !isempty(techs) 
        for tech in techs
          MMSF[enduse,tech,ec,area] = MMSFExogenous[enduse,tech,ec,area]
          MMSFExoTotal = sum(MMSF[enduse,tech,ec,area] for tech in techs)

          #
          # If the exogenous market shares are greater than 1.00,
          # then scale exogenous market shares back to 1.00.
          #
          if MMSFExoTotal > 1.0
            MMSF[enduse,tech,ec,area] = MMSF[enduse,tech,ec,area]/MMSFExoTotal
            MMSFExoTotal = 1.0
          end     
        end
      end

      techs = findall(MMSFSwitch[enduse,:,ec,area] .== 1)
      if !isempty(techs) 
        MMSFEndoTotal = sum(MMSF[enduse,tech,ec,area] for tech in techs)
        for tech in techs
          @finite_math MMSF[enduse,tech,ec,area] = MMSF[enduse,tech,ec,area]/
                                                   MMSFEndoTotal*(1-MMSFExoTotal)
        end
      end
    end
  end

  WriteDisk(db,"$Outpt/MMSF",year,MMSF)

end

function FuelSystem(data::Data)
  #@debug "FuelSystem Function Call"
end

function EnduseSaturation(data::Data)
  (; db,year,CTime) = data
  (; Areas,ECs,Tech,Techs,Enduse,Months,Sector) = data
  (; DSt,DStMin,xDSt,DDayMonthly,DDSatFlag,DDSat,DStHPsPrior) = data
  (; DDSmoothPrior,DDSmooth,DDSmoothingTime,AMSFPrior,DStAC) = data
  (; DStMax,DStC0,DStB0,DStA0,DStPrior,PCEUPrior) = data

  #@info "EnduseSaturation"

  @. DSt = xDSt

  if "AC" in Enduse
    AC = Select(Enduse,"AC")
    for area in Areas
      DDSat[AC,area] = sum(DDayMonthly[AC,month,area]*
        DDSatFlag[AC,month] for month in Months)
    end

    WriteDisk(db,"$Outpt/DDSat",year,DDSat)

    #
    # Smooth Degree Days
    #

    @. @finite_math DDSmooth = DDSmoothPrior+(DDSat-DDSmoothPrior)/DDSmoothingTime

    WriteDisk(db,"$Outpt/DDSmooth",year,DDSmooth)

    #
    # Heat Pump Systems Average Market Share for Space Heating
    #
    Heat = Select(Enduse,"Heat")
    techs = union(findall(Tech[:] .== "Geothermal"),
                  findall(Tech[:] .== "HeatPump"),
                  findall(Tech[:] .== "DualHPump"),
                  findall(Tech[:] .== "FuelCell"))
    if !isempty(techs) 
      for ec in ECs,area in Areas
        DStHPsPrior[ec,area] = sum(AMSFPrior[Heat,tech,ec,area] for tech in techs)
      end
    end

    #
    # Air Conditioning Saturation
    #
    if CTime > 2012
      for area in Areas, ec in ECs
        #
        # Sailor equation
        #
        @finite_math DSt[AC,ec,area] = DStC0[AC,ec,area]+DStB0[AC,ec,area]*
          exp(DStA0[AC,ec,area]*DDSmooth[AC,area])
        #
        # Constrain the saturation to be greater than the minumum saturation and
        # the saturation in the prior year and less than the maximum saturation
        #
        DSt[AC,ec,area] = min(max(DSt[AC,ec,area],DStPrior[AC,ec,area],DStMin[AC,ec,area]),
                              DStMax[AC,ec,area])
      end
    end

    #
    # Constrain AC DSt to the average market share of Heat Pump Systems from prior year
    #
    for area in Areas,ec in ECs
      DSt[AC,ec,area] = min(max(DSt[AC,ec,area],DStHPsPrior[ec,area]),DStMax[AC,ec,area])
    end

    sector = Select(Sector,SectorKey)
    for area in Areas
      SaturationWeighted = sum(DSt[AC,ec,area]*(sum(PCEUPrior[AC,tech,ec,area] for tech in Techs)) for ec in ECs)
      CapacityWeights = sum(PCEUPrior[AC,tech,ec,area] for tech in Techs,ec in ECs)
      @finite_math DStAC[sector,area] = SaturationWeighted/CapacityWeights
    end
  end
  WriteDisk(db,"$Outpt/DSt",year,DSt)
  WriteDisk(db,"SOutput/DStAC",year,DStAC)

end

function MarketShareAC(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,Tech,Techs,Enduse,Age,Ages,ECC) = data
  (; MMSF) = data
  (; EUPCPrior,PCA,MMSFHPs,MMSFOther,MMSFAll ) = data

  #@debug "MarketShareAC Function Call"

  #
  # Market share for Heat Pump Systems AC is equal to their
  # market share for Space Heating.
  #
  if "AC" in Enduse
    AC = Select(Enduse,"AC")
    Heat = Select(Enduse,"Heat")
    GeoHeatPump = Select(Tech,["Geothermal","HeatPump","DualHPump","FuelCell"])

    New = Select(Age,"New")
    for tech in GeoHeatPump,ec in ECs,area in Areas
      ecc = Select(ECC,EC[ec])
      @finite_math MMSF[AC,tech,ec,area] =
        sum((EUPCPrior[Heat,tech,age,ec,area]-EUPCPrior[AC,tech,age,ec,area]) for age in Ages)/
        PCA[New,ecc,area]*0.6
      MMSF[AC,tech,ec,area] = max(MMSF[AC,tech,ec,area],0.0)
    end
    for ec in ECs,area in Areas
      MMSFHPs[ec,area] = min(sum(MMSF[AC,tech,ec,area] for tech in GeoHeatPump),1.00)
    end    
    
    #   
    # Scale other market shares to 1.0 less market shares from Heat Pump Systems
    #    
    Other1 = Select(Tech,!=("Geothermal"))
    Other2 = Select(Tech,!=("HeatPump"))
    Other3 = Select(Tech,!=("DualHPump"))
    Other4 = Select(Tech,!=("FuelCell"))
    Other = intersect(Other1,Other2,Other3,Other4)     
    for ec in ECs,area in Areas
      MMSFOther[ec,area] = sum(MMSF[AC,tech,ec,area] for tech in Other)
    end
    for tech in Other,ec in ECs,area in Areas
      @finite_math MMSF[AC,tech,ec,area] = MMSF[AC,tech,ec,area]/
        MMSFOther[ec,area]*(1-MMSFHPs[ec,area])
    end

    #
    # Normalize marginal market share to equal 1.00
    #
    for ec in ECs,area in Areas
      MMSFAll[ec,area] = sum(MMSF[AC,tech,ec,area] for tech in Techs)
    end

    for tech in Techs,ec in ECs,area in Areas
      @finite_math MMSF[AC,tech,ec,area] = MMSF[AC,tech,ec,area]/MMSFAll[ec,area]
    end
  end

  WriteDisk(db,"$Outpt/MMSF",year,MMSF)
end

function MStock(data::Data)
  (; db,year) = data
  (; Age,Ages,Areas,EC,ECs,Techs,Enduses,ECC) = data
  (; EUPCRPC,EUPCPrior,PCPL,PCA,MMSF,EUPCAPC) = data
  (; EUPCRPC,PERAPC,PEE,PERRPC) = data
  (; DERRPC,DEEAPrior,DERAPC,PERAPC,DEE,PERRP) = data
  (; PEPL,PERAP,PEEAPrior,PEE,DERRP,DERAP,DSt) = data
  (; DStPrior,EUPCPrior,PERADSt,PERRDSt,DEEAPrior,PERPrior) = data
  (; PEPL) = data
  
  #@debug "MStock Function Call"

  # The production capacity "retirements" from each vintage (EUPCRPC) are equal
  # to the production capacity in each vintage (EUPC) divided by the time
  # spent in each vintage.  The time spent in each vintage is equal to the
  # production capacity lifetime (PCPL) divided by three since there are three
  # vintages (Age). The vintages are new, middle, and old.  The production
  # capacity is actually retired when it leaves the third (old) vintage category.
  #
  for area in Areas,ec in ECs,age in Ages,tech in Techs,enduse in Enduses
    ecc = Select(ECC,EC[ec])
    EUPCRPC[enduse,tech,age,ec,area] = EUPCPrior[enduse,tech,age,ec,area]/(PCPL[ecc,area]/3.0)
  end
  WriteDisk(db,"$Outpt/EUPCRPC",year,EUPCRPC)

  # The production capacity additions (EUPCAPC) for each technology for the newest
  # vintage (New) are equal to the production capacity additions (PCA) times the
  # marginal market share for each technology (MMSF).

  New = Select(Age,"New")
  for area in Areas,ec in ECs,tech in Techs,enduse in Enduses
    ecc = Select(ECC,EC[ec])
    EUPCAPC[enduse,tech,New,ec,area] = PCA[New,ecc,area]*MMSF[enduse,tech,ec,area]
  end

  # The production capacity additions (EUPCAPC) for the other vintages (Mid,Old)
  # are equal the production capacity retirements (EUPCRPC) for the next younger
  # vintage (A-1).

  ages = Select(Age,["Mid","Old"])
  for area in Areas,ec in ECs,age in ages,tech in Techs,enduse in Enduses
    EUPCAPC[enduse,tech,age,ec,area] = EUPCRPC[enduse,tech,age-1,ec,area]
  end

  # The process additions from changes in saturation (PERADST) are equal to the
  # production capacity (EUPC) less production capacity retirements (EUPCRPC)
  # times the increase in saturation divided by the average process efficiency
  # The increase in the device saturation is the difference between the device
  # saturation in the current period (DSt) and the device saturation in the
  # previous period (DSt) if the difference is greater than zero.

  Old = Select(Age,"Old")
  for area in Areas,ec in ECs,enduse in Enduses,tech in Techs
    @finite_math PERADSt[enduse,tech,ec,area] = 
      (sum(EUPCPrior[enduse,tech,age,ec,area] for age in Ages)-
       EUPCRPC[enduse,tech,Old,ec,area])*
      max(0,DSt[enduse,ec,area]-DStPrior[enduse,ec,area])/
      PEEAPrior[enduse,tech,ec,area]
  end
  WriteDisk(db,"$Outpt/PERADSt",year,PERADSt)

  # The process retirements from changes in saturation (PERRDST) are equal to
  # the production capacity (EUPC) less production capacity retirements (EUPCRPC)
  # times the reduction in saturation divided by the average process efficiency
  # (PEEAPrior). The reduction in the device saturation is the difference between the
  # device saturation in the previous period (DStPrior) and the device saturation in
  # the current period (DSt) if the difference is greater than zero.
  
  Old = Select(Age,"Old")
  for area in Areas,ec in ECs,enduse in Enduses,tech in Techs
    @finite_math PERRDSt[enduse,tech,ec,area] = 
      (sum(EUPCPrior[enduse,tech,age,ec,area] for age in Ages)-
       EUPCRPC[enduse,tech,Old,ec,area])*
      max(0,DStPrior[enduse,ec,area]-DSt[enduse,ec,area])/
      PEEAPrior[enduse,tech,ec,area]
  end
  WriteDisk(db,"$Outpt/PERRDSt",year,PERRDSt)

  #
  # The process additions from production capacity additions (PERAPC) are equal
  # to production capacity additions (EUPCAPC) to the newest vintage (New) times
  # the device saturation (DSt) divided by the marginal process efficiency (PEE).
  # 
  New = Select(Age,"New")
  for area in Areas,ec in ECs,enduse in Enduses,tech in Techs
    @finite_math PERAPC[enduse,tech,ec,area] = EUPCAPC[enduse,tech,New,ec,area]*
      DSt[enduse,ec,area]/PEE[enduse,tech,ec,area]
  end
  WriteDisk(db,"$Outpt/PERAPC",year,PERAPC)
  WriteDisk(db,"$Outpt/EUPCAPC",year,EUPCAPC)

  #
  # The process retirements from production capacity retirements (PERRPC) are
  # equal to the production capacity retirements (EUPCRPC) from the oldest
  # vintage (Old) times the device saturation in the previous period (DStPrior)
  # divided by the average process efficiency (PEEAPrior).
  #
  Old = Select(Age,"Old")
  for area in Areas,ec in ECs,enduse in Enduses,tech in Techs
    @finite_math PERRPC[enduse,tech,ec,area] = EUPCRPC[enduse,tech,Old,ec,area]*
      DStPrior[enduse,ec,area]/PEEAPrior[enduse,tech,ec,area]
  end
  WriteDisk(db,"$Outpt/PERRPC",year,PERRPC)

  #
  # The device retirements from production capacity and saturation additions
  # (DERRPC) are equal to the process retirements from production capacity
  # (PERRPC) plus the production capacity retirements from reductions in
  # saturation (PERRDST) divided by the average device efficiency (DEEAPrior).
  #
  @. @finite_math DERRPC = (PERRPC+PERRDSt)/DEEAPrior
  WriteDisk(db,"$Outpt/DERRPC",year,DERRPC)

  #
  # The device additions from production capacity and saturation additions
  # (DERAPC) are equal to the process additions from production capacity (PERAPC)
  # plus the production capacity additions from increases in saturation (PERADST)
  # divided by the marginal device efficiency (DEE).
  #
  @. @finite_math DERAPC = (PERAPC+PERADSt)/DEE
  WriteDisk(db,"$Outpt/DERAPC",year,DERAPC)

  # The process retirements due to process retirements (PERRP) are equal
  # to the process energy requirements (PER) less the process retirements
  # from retirement of production capacity (PERRPC) and reductions in the
  # device saturation (PERRDST) divided by the process lifetime (PEPL).
  #
  @. @finite_math PERRP = (PERPrior-PERRPC-PERRDSt)/PEPL
  WriteDisk(db,"$Outpt/PERRP",year,PERRP)

  # Process energy additions (PERAP) are replacements for the "retired" process
  # energy requirements (PERRP).  The process energy requirements (PERRP) are
  # retired based on the average process efficiency (PEEAPrior). The process additions
  # (PERAP) are added based on the marginal process efficiency (PEE).
  #
  @. @finite_math PERAP = PERRP*PEEAPrior/PEE
  WriteDisk(db,"$Outpt/PERAP",year,PERAP)

  # The device retirements from changes in the process energy (DERRP) are the
  # the reductions in device energy requirements (DER) from reductions in the
  # process energy requirements (PER).  The device retirements (DERRP) are
  # non-zero only when the process retirements (PERRP) are greater than the
  # process additions (PERAP).  The device retirements (DERRP) are removed based
  # on the average device efficiency (DEEAPrior).
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DERRP[enduse,tech,ec,area] = 
      max(0,(PERRP[enduse,tech,ec,area]-PERAP[enduse,tech,ec,area]))/
      DEEAPrior[enduse,tech,ec,area]
  end
  WriteDisk(db,"$Outpt/DERRP",year,DERRP)

  #
  # The device additions from changes in the process energy (DERAP) are the
  # additions to the device energy requirements (DER) from additions to the
  # process energy requirements (PER).  The device additions (DERRP) are non-zero
  # only when the process additions (PERAP) are greater than the process
  # retirements (PERRP). The device additions (DERAP) are added based on the
  # marginal device efficiency (DEE).
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DERAP[enduse,tech,ec,area] = max(0,(PERAP[enduse,tech,ec,area]-
      PERRP[enduse,tech,ec,area]))/DEE[enduse,tech,ec,area]
  end
  WriteDisk(db,"$Outpt/DERAP",year,DERAP)

end

function Conversion(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs,Enduses,CTechs) = data
  (; CMAW,CMSM0,CVF,MCFU,DCCR,FDCC,FDCCU,Inflation,MCFU0,Inflation0) = data
  (; CMSMI,SPC,SPop,SPC0,SPop0,CTMAW,xCMSF,CMSF,CMSFSwitch) = data
  (; CMSF,CnvrtEU,Exogenous,Endogenous) = data

  #@debug "Conversion Function Call"


  @. CMSF = 0.0

  #
  # "Conversion" means changing your fuel choice when your device is
  # replaced. Device conversion is a fuel choice decision. Process has only
  # conversion shift so neglect "choice" dynamics. Choice is on BTU
  # of Service so move PER with MCFU. Market share is "To Tech" "From CTech".
  # For simplicity allow rebates but not low-interest loans,
  # else algorithm would include CMCFU based a FDCCRU.
  #

  for area in Areas,enduse in Enduses,ec in ECs
    if (CnvrtEU[enduse,ec,area] == Endogenous) || (CnvrtEU[enduse,ec,area] == Exogenous)
      
      #
      # If the choice is made endogenously,then it is a function of the
      # cost of the new technology (MCFU) less the "hurdle" cost (FDCC).
      # The hurdle cost for space heating represents the cost of ducts.
      # These costs are "hurdle" costs in the sense that if change from
      # electric baseboard heat to a gas furnace you must add duct work
      # to the house.
      #
      for tech in Techs,ctech in CTechs
        if MCFU[enduse,tech,ec,area] >= 0 && MCFU0[enduse,tech,ec,area] >= 0
          @finite_math CMAW[tech,ctech,ec,area] = exp(CMSM0[enduse,tech,ctech,ec,area] +
            CVF[enduse,tech,ctech,ec,area] *
            log(((MCFU[enduse,tech,ec,area]-DCCR[enduse,tech,ec,area]*
            (FDCC[enduse,tech,ctech,area]+FDCCU[enduse,tech,ctech,area])*
            Inflation[area])/Inflation[area])/(MCFU0[enduse,tech,ec,area]/Inflation0[area]))+
            CMSMI[enduse,tech,ctech,ec,area]*
            (SPC[ec,area]/SPop[ec,area])/(SPC0[ec,area]/SPop0[ec,area]))
        else
          CMAW[tech,ctech,ec,area] = 0.0
        end
      end

      for ctech in CTechs
        CTMAW[ctech,ec,area] = sum(CMAW[tech,ctech,ec,area] for tech in Techs)
      end
      for tech in Techs,ctech in CTechs
        @finite_math CMSF[enduse,tech,ctech,ec,area] = CMAW[tech,ctech,ec,area]/CTMAW[ctech,ec,area]
      end
    end
    
    if CnvrtEU[enduse,ec,area] == Exogenous
      for ctech in CTechs
        techs = findall(CMSFSwitch[enduse,:,ctech,ec,area] .== 0)
        if !isempty(techs)
          for tech in techs
            CMSF[enduse,tech,ctech,ec,area] = xCMSF[enduse,tech,ctech,ec,area]
          end
          CMSFExoTotal = sum(CMSF[enduse,tech,ctech,ec,area] for tech in techs)
            
          techs = findall(CMSFSwitch[enduse,:,ctech,ec,area] .== 1)          
          if !isempty(techs)
            CMSFEndoTotal = sum(CMSF[enduse,tech,ctech,ec,area] for tech in techs)
            for tech in techs
              @finite_math CMSF[enduse,tech,ctech,ec,area] = 
                CMSF[enduse,tech,ctech,ec,area]/CMSFEndoTotal*(1-CMSFExoTotal)
            end
          end
        end
      end
    end
  end

  WriteDisk(db,"$Outpt/CMSF",year,CMSF)
end

function DeviceDynamics(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs,Enduses,CTechs,Vintages) = data
  (; DERRD,DERRDV,DERPrior,DERRPC,DERRP,DPL,CFraction ) = data
  (; DERAD,DEEAPrior,DEE) = data
  (; DERRRC,DERRRCV,CMSF,DERARC) = data
  (; DERVAllocation,DERVSum,DPLV) = data

  #@debug "DeviceDynamics Function Call"

  # This procedure simulates the dynamics of device wear-out (DERRD) and device
  # replacements (DERAD). When a device wears out,the device is replaced since
  # the process energy requirements still exist. The new device has the current
  # marginal device efficiency (DEE),while the old device is assumed to have a
  # device efficiency equal to the average device efficiency (DEEAPrior).  The new
  # device is normally the same technology or fuel type as the old device;
  # however,if the "conversion" switch has been turned on,then the new device
  # may select a different technology.
  # The device retirements or failures (DERRD) are equal to the device energy
  # requirements (DER) less production capacity retirements (DERRPC) and
  # process retirements (DERRP) divided by the average lifetime of the devices
  # (DPL).
  # DPL[enduse,tech,ec,area]
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas, vintage in Vintages
    @finite_math DERRDV[enduse,tech,ec,area,vintage] = (DERVSum[enduse,tech,ec,area]-
    DERRPC[enduse,tech,ec,area]-DERRP[enduse,tech,ec,area])*DERVAllocation[enduse,tech,ec,area,vintage]*
    DPLV[enduse,tech,ec,area,vintage]*(1.0-CFraction[enduse,tech,ec,area])
  end
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DERRD[enduse,tech,ec,area] = sum(DERRDV[enduse,tech,ec,area,vintage] for vintage in Vintages)   
  end
  WriteDisk(db,"$Outpt/DERRDV",year,DERRDV)
  WriteDisk(db,"$Outpt/DERRD",year,DERRD)

  #
  # Device retirements due to conversions (DERRRC) are equal to the device energy
  # requirements (DER) less production capacity retirements (DERRPC) and
  # process retirements (DERRP) divided by the average lifetime of the devices
  # (DPL) divided by the conversion fraction
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas, vintage in Vintages
    @finite_math DERRRCV[enduse,tech,ec,area,vintage] = (DERVSum[enduse,tech,ec,area]-
    DERRPC[enduse,tech,ec,area]-DERRP[enduse,tech,ec,area])*DERVAllocation[enduse,tech,ec,area,vintage]*
    DPLV[enduse,tech,ec,area,vintage]*CFraction[enduse,tech,ec,area]
  end
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DERRRC[enduse,tech,ec,area] = sum(DERRRCV[enduse,tech,ec,area,vintage] for vintage in Vintages)   
  end
  WriteDisk(db,"$Outpt/DERRRCV",year,DERRRCV)
  WriteDisk(db,"$Outpt/DERRRC",year,DERRRC)


  #
  # If there are no conversions,then the device additions from device wear-outs
  # (DERAD) are equal to the device retirements (DERRD) times the old (average)
  # device efficiency (DEEAPrior) divided by the new (marginal) device efficiency
  # (DEE).
  #
  @. @finite_math DERAD = DERRD*DEEAPrior/DEE
  WriteDisk(db,"$Outpt/DERAD",year,DERAD)

  # If the conversion switch is on,then the device additions from device
  # wear-out and conversions (DERARC) are equal to the device retirements from
  # conversions(DERRD) times the old (average) device efficiency (DEEAPrior)
  # times the fraction of the devices converted (CMSF) from one Technology (CTech)
  # to another Technology (Tech) divided by the new (marginal) device efficiency (DEE).

  for enduse in Enduses,ec in ECs,tech in Techs,area in Areas
    @finite_math DERARC[enduse,tech,ec,area] = sum(DERRRC[enduse,ctech,ec,area]*
      DEEAPrior[enduse,ctech,ec,area]*
      CMSF[enduse,tech,ctech,ec,area] for ctech in CTechs)/DEE[enduse,tech,ec,area]
  end

  WriteDisk(db,"$Outpt/DERARC",year,DERARC)


end

function RCPCDynamics(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs,Enduses,Ages,CTechs) = data
  (; PERRRC,PERARC,DERRRC,DEEAPrior,CMSF) = data
  (; EUPCRC,EUPCPrior,PEEAPrior,EUPCAC) = data

  #@debug "RCPCDynamics Function Call"

  #
  # Given the devices converted because of conversions,calculate the
  # impact on process energy requirements and production capacity.
  #

  @. PERRRC = 0.0
  @. PERARC = 0.0

  #
  # The process removals from conversions (PERRRC) are equal to the
  # device replacements from conversion (DERRRC) times the conversion market share (CMSF)
  # The terms are multiplied times the average device efficiency (DEEAPrior)
  # to convert from device to process energy requirements.
  #
  for ToTech in Techs,FromTech in CTechs,ec in ECs,area in Areas,enduse in Enduses
    if ToTech != FromTech
    
      PERRRC[enduse,FromTech,ec,area] = PERRRC[enduse,FromTech,ec,area]+
        DERRRC[enduse,FromTech,ec,area]*DEEAPrior[enduse,FromTech,ec,area]*
        CMSF[enduse,ToTech,FromTech,ec,area]

      #
      # The process additions from conversions (PERRARC) are calculated the
      # same as the process removals except for the index in the market share
      # variable (CMSF).  The process energy requirements are simply being
      # moved from one technology (CTech) to another (Tech).
      #
      PERARC[enduse,ToTech,ec,area] = PERARC[enduse,ToTech,ec,area]+
        DERRRC[enduse,FromTech,ec,area]*DEEAPrior[enduse,FromTech,ec,area]*
        CMSF[enduse,ToTech,FromTech,ec,area]

    end
  end

  #
  # The production capacity "retirements" due to conversions (EUPCRC) are the
  # process energy "retirements" due to conversions (PERRRC) times the average
  # process efficiency (PEEAPrior). These "retirements" are split between the vintages
  # based on the age distribution of the production capacity (EUPC).
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas,age in Ages
    @finite_math EUPCRC[enduse,tech,age,ec,area] = PERRRC[enduse,tech,ec,area]*
      PEEAPrior[enduse,tech,ec,area]*EUPCPrior[enduse,tech,age,ec,area]/
      (sum(EUPCPrior[enduse,tech,V,ec,area] for V in Ages))
  end

  # The production capacity "additions" due to conversions (EUPCAC) are equal to
  # the process energy "retirements" due to conversion (PERRRC) times the average
  # process efficiency (PEEAPrior) times the conversion shars (CNSF) which split based on
  # the age distribution of the production capacity (EUPC).

  @. EUPCAC = 0.0

  for ToTech in Techs,FromTech in CTechs,ec in ECs,area in Areas,enduse in Enduses,age in Ages
    @finite_math EUPCAC[enduse,ToTech,age,ec,area] = EUPCAC[enduse,ToTech,age,ec,area]+
      PERRRC[enduse,FromTech,ec,area]*PEEAPrior[enduse,FromTech,ec,area]*
      CMSF[enduse,ToTech,FromTech,ec,area]*
      EUPCPrior[enduse,FromTech,age,ec,area]/(sum(EUPCPrior[enduse,FromTech,V,ec,area] for V in Ages))
  end
  WriteDisk(db,"$Outpt/EUPCAC",year,EUPCAC)
  WriteDisk(db,"$Outpt/EUPCRC",year,EUPCRC)
  WriteDisk(db,"$Outpt/PERRRC",year,PERRRC)
  WriteDisk(db,"$Outpt/PERARC",year,PERARC)

end

function DRetrofit(data::Data)
  #@debug "DRetrofit Function Call"
end

function PRetrofit(data::Data)
  #@debug "PRetrofit"
end

function Utilize(data::Data)
  (; db,year) = data
  (; BM,BMM) = data

  #@debug "Utilize"


  # 
  # Do If ProcSw(Utilize) eq Endogenous
  # 
  #   APCC=CTABCE(PEEAPrior)*Inflation
  #   BCCR = (1-DIVTC/(1+ROIN-CROIN+DRisk+InSm)-TxRt*(2/BTL)/
  #       (ROIN-CROIN+DRisk+InSm+2/BTL))*(ROIN-CROIN+DRisk)/
  #       (1-(1/(1+ROIN-CROIN+DRisk))**BPL)/(1-TxRt)
  # 
  #  Marginal value of device usage
  # 
  #   MVDU=(IBM*ECFP/DEEAPrior+BCCR*BDCCU)/(APCC*PEEAPrior)*
  #      exp(-(BDER/DERPrior)/BMT)
  #   MAW=exp(BMSM0+BVF*LN(MVDU/MVDU0)+BMSMI*(SPC/SPop)/(SPC0/SPop0))
  #   BMSF=MAW/(MVAU+MAW)
  #   BDERA=(DERPrior-BDER)*BMSF
  #   BDERR=BDER/BPL
  #   BDER=BDER+DT*(BDERA-BDERR)
  #   BM=(1-BDER/DERPrior)*BMM
  #   Write Disk(APCC,BCCR,MVDU,MAW,BMSF,BDERR,BDER,BM)
  # Else (ProcSw(Utilize) eq Exogenous) or (ProcSw(Utilize) eq NonExist)
  #  BDER = 0
  #   Write Disk(BM,BDER)
  #   BM=BMM
  #   Write Disk(BM)
  # End Do If ProcSw
  # 

  @. BM = BMM
  WriteDisk(db,"$Outpt/BM",year,BM)


end

function DmFracMaxFromSupplyCurve(data::Data)
  #@debug "DmFracMaxFromSupplyCurve"
end

function TStock(data::Data)
  (; db,year) = data
  (; Ages,Areas,ECs,Enduses,Techs,Vintages) = data
  (; AMSF,DEE,DEEAPrior,DEEAV,DER,DERA,DERAD,DERAP,DERAPC,DERARC,DERAV,DERBefore,DERR) = data
  (; DERRD,DERReduction,DERRP,DERRPC,DERRR,DERRDV,DERRRCV,DERRV,DERRRC) = data
  (; DERRRExo,DERRV,DERV,DERVAllocation,DERVSum,EUPC,EUPCA) = data
  (; EUPCAC,EUPCAdj,EUPCAPC,EUPCPrior,EUPCR,EUPCRC,EUPCRPC,PCEU,PER,PERA) = data
  (; PERAdj,PERADSt,PERAP,PERAPC,PERARC,PERPrior,PERR,PERRDSt,PERReduction) = data
  (; PERRP,PERRPC,PERRR,PERRRC,PERRRExo,RetroSwExo,StockAdjustment) = data

  #@debug "TStock"

  @. EUPCA = EUPCAPC+EUPCAC
  @. EUPCR = EUPCRPC+EUPCRC
  @. EUPC = max(EUPCPrior+DT*(EUPCA-EUPCR),0.00)
    
  for tech in Techs,ec in ECs,area in Areas,enduse in Enduses,age in Ages
  
    EUPCAdj[enduse,tech,age,ec,area] =
      EUPC[enduse,tech,age,ec,area]*StockAdjustment[enduse,tech,ec,area]
  
    EUPC[enduse,tech,age,ec,area] = 
      EUPC[enduse,tech,age,ec,area]+EUPCAdj[enduse,tech,age,ec,area]
      
  end

  @. PERA = PERAPC+PERADSt+PERAP+PERARC
  @. PERR = PERRPC+PERRDSt+PERRP+PERRR+PERRRC
  
  for tech in Techs,ec in ECs,area in Areas,enduse in Enduses
    PER[enduse,tech,ec,area] = PERPrior[enduse,tech,ec,area]+
      DT*(PERA[enduse,tech,ec,area]-PERR[enduse,tech,ec,area])
  end
  @. PERAdj = PER*StockAdjustment
  @. PER = PER+PERAdj

  if RetroSwExo == 1
    # Switch == 1 is Commented out in Promula.
    #   LSeg=SegName
    #   FText2=LSeg+"Output.dba"
    #   FText1=RefName::0+Slash::0+FText2::0
    #   Open Outpt FText1
    #   Read Disk(PERRef)
    #   Open Outpt FText2
    #   PERRRExo=(PER-PERRef*(1-PERReduction))*PERReduction/PERReduction
  elseif RetroSwExo == 2
    @. PERRRExo = PER*PERReduction
  else
    # Read Disk(PERRRExo)
  end
  
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    PER[enduse,tech,ec,area] = max(0,(PER[enduse,tech,ec,area]-PERRRExo[enduse,tech,ec,area]))
  end

  @. DERA = DERAPC+DERAP+DERAD+DERARC
  @. @finite_math DERR = DERRPC+DERRP+DERRD+DERRR+DERRRC+PERRR/DEEAPrior

  #
  # Device Additions are assigned to the Current year Vintage
  #
  firstvintage = 1
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    DERAV[enduse,tech,ec,area,firstvintage] = DERA[enduse,tech,ec,area]
    DEEAV[enduse,tech,ec,area,firstvintage] = (DERV[enduse,tech,ec,area,firstvintage]*DEEAV[enduse,tech,ec,area,firstvintage]+
                                               DERA[enduse,tech,ec,area]*DEE[enduse,tech,ec,area])/
                                              (DERV[enduse,tech,ec,area,firstvintage]+DERA[enduse,tech,ec,area])
  end

  #
  # Device Retirements are generally allocated to Vintages
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, vintage in Vintages
    @finite_math DERRV[enduse,tech,ec,area,vintage] = 
      DERRDV[enduse,tech,ec,area,vintage]+DERRRCV[enduse,tech,ec,area,vintage]+
      (DERRPC[enduse,tech,ec,area]+DERRP[enduse,tech,ec,area]+DERRR[enduse,tech,ec,area]+
       PERRR[enduse,tech,ec,area]/DEEAPrior[enduse,tech,ec,area])*
       DERVAllocation[enduse,tech,ec,area,vintage]
  end
  
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, vintage in Vintages
    DERV[enduse,tech,ec,area,vintage] = DERV[enduse,tech,ec,area,vintage]+DT*
      (DERAV[enduse,tech,ec,area,vintage]-DERRV[enduse,tech,ec,area,vintage])
  end
  
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, vintage in Vintages
    DERV[enduse,tech,ec,area,vintage] =
      DERV[enduse,tech,ec,area,vintage]*(1+StockAdjustment[enduse,tech,ec,area])
  end  
  

  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    DER[enduse,tech,ec,area] = sum(DERV[enduse,tech,ec,area,vintage] for vintage in Vintages)
  end
  
  @. DERBefore = DER
  
  if RetroSwExo == 1
    # Switch == 1 is commented out in Promula
    #   LSeg=SegName
    #   FText2=LSeg+"Output.dba"
    #   FText1=RefName::0+Slash::0+FText2::0
    #   Open Outpt FText1
    #   Read Disk(DERRef)
    #   Open Outpt FText2
    #   DERRRExo=(DER-DERRef*(1-DERReduction))*DERReduction/DERReduction
  elseif RetroSwExo == 2
    @. DERRRExo = DER*DERReduction
  else
  #   Read Disk(DERRRExo)
  end

  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math DER[enduse,tech,ec,area] =
      max(0,(DER[enduse,tech,ec,area]-DERRRExo[enduse,tech,ec,area]-
      PERRRExo[enduse,tech,ec,area]/DEEAPrior[enduse,tech,ec,area]))
  end
  
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas, vintage in Vintages
    @finite_math DERV[enduse,tech,ec,area,vintage] = DERV[enduse,tech,ec,area,vintage]*
      DER[enduse,tech,ec,area]/DERBefore[enduse,tech,ec,area]
  end

  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    @finite_math AMSF[enduse,tech,ec,area] = 
      sum(EUPC[enduse,tech,age,ec,area] for age in Ages)/
      sum(EUPC[enduse,alltechs,age,ec,area] for alltechs in Techs,age in Ages)    
  end

  WriteDisk(db,"$Outpt/AMSF",year,AMSF)
  WriteDisk(db,"$Outpt/DEEAV",year,DEEAV)
  WriteDisk(db,"$Outpt/DER",year,DER)
  WriteDisk(db,"$Outpt/DERA",year,DERA)
  WriteDisk(db,"$Outpt/DERR",year,DERR)
  WriteDisk(db,"$Outpt/DERRV",year,DERRV)
  WriteDisk(db,"$Outpt/DERV",year,DERV)
  WriteDisk(db,"$Outpt/EUPC",year,EUPC)
  WriteDisk(db,"$Outpt/EUPCA",year,EUPCA)
  WriteDisk(db,"$Outpt/EUPCR",year,EUPCR)
  WriteDisk(db,"$Outpt/PER",year,PER)
  WriteDisk(db,"$Outpt/PERA",year,PERA)
  WriteDisk(db,"$Outpt/PERR",year,PERR)
  WriteDisk(db,"$Outpt/PERRRExo",year,PERRRExo)
  
  #
  # Device Allocations for each Vintage
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    DERVSum[enduse,tech,ec,area] = sum(DERV[enduse,tech,ec,area,vintage] for vintage in Vintages)
    for vintage in Vintages
      @finite_math DERVAllocation[enduse,tech,ec,area,vintage] = DERV[enduse,tech,ec,area,vintage] /
                                                    DER[enduse,tech,ec,area]
    end
  end
  WriteDisk(db,"$Outpt/DERVAllocation",year,DERVAllocation)
  WriteDisk(db,"$Outpt/DERVSum",year,DERVSum)
  
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas
    PCEU[enduse,tech,ec,area] = sum(EUPC[enduse,tech,age,ec,area] for age in Ages)
  end

  WriteDisk(db,"$Outpt/PCEU",year,PCEU)

end

function Fungible(data::Data)
  (; db,year) = data
  (; Fuels,Areas,ECs,Techs,Enduses) = data
  (; DmFracMSF,DmFracMarginal,DmFrac,DmFracPrior) = data
  (; DmFracTime,DmFracTotal,DmFrac,DmFracMin,DmFracMax) = data
  (; DmFracMSM0,DmFracVF,ECFPFuel,ECFP0,DmFracTMAW,DmFracMAW,FuelLimit) = data
  (; Inflation,Inflation0) = data

  for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    if ECFPFuel[fuel,ec,area] >= 0 && ECFP0[enduse,tech,ec,area] >= 0
      @finite_math DmFracMAW[enduse,fuel,tech,ec,area] = 
        exp(DmFracMSM0[enduse,fuel,tech,ec,area]+
            DmFracVF[enduse,fuel,tech,ec,area]*
            log((ECFPFuel[fuel,ec,area]/Inflation[area])/
                (ECFP0[enduse,tech,ec,area]/Inflation0[area])))
    else
      DmFracMAW[enduse,fuel,tech,ec,area] = 0.00
    end
  end

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DmFracTMAW[enduse,tech,ec,area] = sum(DmFracMAW[enduse,fuel,tech,ec,area] for fuel in Fuels)
  end

  for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    @finite_math DmFracMSF[enduse,fuel,tech,ec,area] = DmFracMAW[enduse,fuel,tech,ec,area]/DmFracTMAW[enduse,tech,ec,area]
  end

  #
  # Apply Minimums and Maximums
  #
  @. DmFracMarginal = DmFracMSF
  DmFracCount::Int = 1

  while DmFracCount < 10
    @. DmFracMarginal = min(max(DmFracMarginal,DmFracMin),DmFracMax)
    for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
      DmFracMarginal[enduse,fuel,tech,ec,area] = DmFracMarginal[enduse,fuel,tech,ec,area]*FuelLimit[fuel,area]
    end
    for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
      DmFracTotal[enduse,tech,ec,area] = sum(DmFracMarginal[enduse,fuel,tech,ec,area] for fuel in Fuels)
    end
    for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
      @finite_math DmFracMarginal[enduse,fuel,tech,ec,area] =
        DmFracMarginal[enduse,fuel,tech,ec,area]/DmFracTotal[enduse,tech,ec,area]
    end
    DmFracCount += 1
  end

  @. @finite_math DmFrac = DmFracPrior+(DmFracMarginal-DmFracPrior)/DmFracTime

  @. DmFracTotal = 0.0

  for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    DmFracTotal[enduse,tech,ec,area] = DmFrac[enduse,fuel,tech,ec,area]+
      DmFracTotal[enduse,tech,ec,area]
  end

  for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    @finite_math DmFrac[enduse,fuel,tech,ec,area] =
      DmFrac[enduse,fuel,tech,ec,area]/(DmFracTotal[enduse,tech,ec,area])
    if isnan(DmFrac[enduse,fuel,tech,ec,area])
      DmFrac[enduse,fuel,tech,ec,area] = 0.0
    end
  end

  WriteDisk(db,"$Outpt/DmFrac",year,DmFrac)
  WriteDisk(db,"$Outpt/DmFracMarginal",year,DmFracMarginal)
  WriteDisk(db,"$Outpt/DmFracMSF",year,DmFracMSF)
end

function FeedstockFungible(data::Data)
  (; db,year) = data
  (; Fuels,Areas,ECs,Techs,ES) = data
  (; FuelLimit,FsFracMAW,FsFracMSM0,FsFracVF,FsFP,FsFP0) = data
  (; FsFracTMAW,FsFracMSF,FsFracMarginal,FsFracMSF) = data
  (; FsFracMin,FsFracMax) = data
  (; FsFracTotal,FsFracPrior,FsFracTime,FsFrac) = data
  (; Inflation,Inflation0) = data

  #@debug "FeedstockFungible"
  
  es = Select(ES,ESKey)
  for fuel in Fuels,tech in Techs,ec in ECs,area in Areas
    if FsFP[fuel,es,area] >= 0 && FsFP0[fuel,es,area]>= 0    
      @finite_math FsFracMAW[fuel,tech,ec,area] = exp(FsFracMSM0[fuel,tech,ec,area]+
        FsFracVF[fuel,tech,ec,area]*log(FsFP[fuel,es,area]/FsFP0[fuel,es,area]))
    else
      FsFracMAW[fuel,tech,ec,area] = 0.0
    end
  end

  for tech in Techs,ec in ECs,area in Areas
    FsFracTMAW[tech,ec,area] = sum(FsFracMAW[fuel,tech,ec,area] for fuel in Fuels)
  end

  for fuel in Fuels,tech in Techs,ec in ECs,area in Areas
    @finite_math FsFracMSF[fuel,tech,ec,area] = FsFracMAW[fuel,tech,ec,area]/
      FsFracTMAW[tech,ec,area]
  end

  #
  # Apply Minimums and Maximums
  #
  FsFracCount::Int = 1
  @. FsFracMarginal = FsFracMSF

  while FsFracCount < 10
    @. FsFracMarginal = min(max(FsFracMarginal,FsFracMin),FsFracMax)
    for area in Areas,ec in ECs,tech in Techs,fuel in Fuels
      FsFracMarginal[fuel,tech,ec,area] = FsFracMarginal[fuel,tech,ec,area]*FuelLimit[fuel,area]
    end
    for area in Areas,ec in ECs,tech in Techs,fuel in Fuels
      FsFracTotal[tech,ec,area] = sum(FsFracMarginal[fuel,tech,ec,area] for fuel in Fuels)
    end
    for area in Areas,ec in ECs,tech in Techs,fuel in Fuels
      @finite_math FsFracMarginal[fuel,tech,ec,area] = FsFracMarginal[fuel,tech,ec,area]/FsFracTotal[tech,ec,area]
    end
    FsFracCount += 1
  end

  @. @finite_math FsFrac = FsFracPrior+(FsFracMarginal-FsFracPrior)/FsFracTime

  for area in Areas,ec in ECs,tech in Techs
    FsFracTotal[tech,ec,area] = sum(FsFrac[fuel,tech,ec,area] for fuel in Fuels)
  end

  #
  # Set hard ceiling for FsFrac (no weighting) for policies that reduce demands
  # Review and adjust in the future - Ian 10/06/21
  #
  for area in Areas,ec in ECs,tech in Techs,fuel in Fuels
    @finite_math FsFrac[fuel,tech,ec,area] =
      min(FsFrac[fuel,tech,ec,area]/FsFracTotal[tech,ec,area],FsFracMax[fuel,tech,ec,area])
  end

  WriteDisk(db,"$Outpt/FsFrac",year,FsFrac)
  WriteDisk(db,"$Outpt/FsFracMarginal",year,FsFracMarginal)
  WriteDisk(db,"$Outpt/FsFracMSF",year,FsFracMSF)

end

function SequesteringEnergyPenalty(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,ECCs,Enduse,Fuels,FuelEPs,Techs,Poll,Polls) = data
  (; SqPolCCNet,SqPenaltyTech,SqDmd,SqDmdFuelEP) = data
  (; DmFrac,SqDmdFuel,FFPMap) = data
  (; SqPolCCPenaltyEC,SqPolCCPenalty,SqFuelCost,POCX,ZeroFr,ECFP,PCostTech) = data

   #@debug " $ESKey Demand.src, SequesteringEnergyPenalty"

  if SectorName != "Transportation"
  
    CO2 = Select(Poll,"CO2")
    for ecc in ECCs, area in Areas
      SqPolCCNet[ecc,CO2,area] = min(SqPolCCNet[ecc,CO2,area],-0.00001)
    end

    for tech in Techs, ec in ECs, area in Areas
      ecc = Select(ECC,EC[ec])
      SqDmd[tech,ec,area] = sum(0-SqPolCCNet[ecc,poll,area]*
                            SqPenaltyTech[tech,ec,poll,area] for poll in Polls)
    end
    WriteDisk(db,"$Outpt/SqDmd",year,SqDmd)

    Heat = Select(Enduse,"Heat")
    for area in Areas, ec in ECs, fuel in Fuels
      SqDmdFuel[fuel,ec,area] = sum(SqDmd[tech,ec,area]*
                                    DmFrac[Heat,fuel,tech,ec,area] for tech in Techs)
    end
    WriteDisk(db,"$Outpt/SqDmdFuel",year,SqDmdFuel)

    @. SqDmdFuelEP = 0.0
  
    for fuelep in FuelEPs, ec in ECs, area in Areas
      SqDmdFuelEP[fuelep,ec,area] = 
        sum(SqDmdFuel[fuel,ec,area]*FFPMap[fuelep,fuel] for fuel in Fuels)
    end

    for ec in ECs, area in Areas, poll in Polls
      SqPolCCPenaltyEC[ec,poll,area] = 0-sum(SqDmdFuelEP[fuelep,ec,area]*
        POCX[1,fuelep,ec,poll,area]*(1-ZeroFr[fuelep,poll,area]) for fuelep in FuelEPs)
    end
  
    for ec in ECs, poll in Polls, area in Areas
      ecc = Select(ECC,EC[ec])  
      SqPolCCPenalty[ecc,poll,area] = SqPolCCPenaltyEC[ec,poll,area]
    end
  
    WriteDisk(db,"SOutput/SqPolCCPenalty",year,SqPolCCPenalty)

    for ec in ECs, area in Areas
      ecc = Select(ECC,EC[ec])
      @finite_math SqFuelCost[ecc,area] = 
               sum(SqDmd[tech,ec,area]*(ECFP[1,tech,ec,area]-
               PCostTech[tech,ec,area]) for tech in Techs)/
               (0.0-sum(SqPolCCNet[ecc,poll,area] for poll in Polls))*1000000.0
    end

    WriteDisk(db,"SOutput/SqFuelCost",year,SqFuelCost)
  end

end

#
# End-Use Demand Dynamics
#

function DmdEnduse(data::Data)
  (; db,year) = data
  (; Ages,Areas,EC,ECC,ECs,Tech,Techs,Enduse,Enduses,Process,Vintages) = data
  (; PEEA,PEEAPrior,EUPC,PER,PEE,DActV,DEEA,DEEAPrior,DER,DERVAllocation,Dmd,CERSM,CUF) = data
  (; RPEI,DDay,DDayNorm,DDCoefficient,DmdSw,Exogenous) = data
  (; ECFP,Inflation,DSt,NB,AB,ABPrior,UMS,BE,BM,BAT,TSLoad) = data
  (; FsDmd,SPC,FsPEE,WCUF,DSMEU,DmdRq,SqEUTechMap) = data
  (; DEE,AMSF,ECUF,SqDmd,OAPrEOR,EORDmd,H2PipelineMultiplier) = data

  #@debug "DmdEnduse"

  #
  # Utilitzation Multiplier
  #
  for tech in Techs,enduse in Enduses,ec in ECs,area in Areas
    @finite_math NB[enduse,tech,ec,area] = ECFP[enduse,tech,ec,area]/Inflation[area]*
      DSt[enduse,ec,area]/(PEEAPrior[enduse,tech,ec,area]*DEEAPrior[enduse,tech,ec,area])
  end

  @. @finite_math NB = NB+(1-NB/NB)
  @. @finite_math ABPrior = ABPrior+(1-ABPrior/ABPrior)

  #@. @finite_math UMS = (NB/ABPrior)^BE*BM
  #
  # New UMS includes device activity rates
  #
  for area in Areas,ec in ECs,tech in Techs,enduse in Enduses
    UMS[enduse,tech,ec,area] = sum(DActV[enduse,tech,ec,area,vintage]*DERVAllocation[enduse,tech,ec,area,vintage] for vintage in Vintages)
  end 
  WriteDisk(db,"$Outpt/UMS",year,UMS)
  
  @. @finite_math AB = ABPrior+DT*(NB-ABPrior)/BAT

  for area in Areas,ec in ECs,tech in Techs,enduse in Enduses
    @finite_math PEEA[enduse,tech,ec,area] =
      sum(EUPC[enduse,tech,age,ec,area] for age in Ages)*
      DSt[enduse,ec,area]/(PER[enduse,tech,ec,area])
    if PEEA[enduse,tech,ec,area] == 0.0
      PEEA[enduse,tech,ec,area] = PEE[enduse,tech,ec,area]
    end
  end
  # @. @finite_math PEEA = PEEA+PEE*(1.0-PEEA/PEEA)
  
  @. @finite_math DEEA = PER/DER

  #
  # Energy demand for all fuels is based on the device energy 
  # requirements, the budget elasticity multiplier, the lifestyle
  # trend, the capacity utilization factors, the weather impacts,
  # and the energy impact of emission reductions.  Jeff Amlin 1/4/12
  #
  for area in Areas,ec in ECs,tech in Techs,enduse in Enduses
    @finite_math Dmd[enduse,tech,ec,area] = DER[enduse,tech,ec,area]*
      UMS[enduse,tech,ec,area]*CERSM[enduse,ec,area]*
      CUF[enduse,tech,ec,area]*WCUF[ec,area]*RPEI[enduse,tech,ec,area]/1.0e6*
      (TSLoad[enduse,ec,area]*
      (DDay[enduse,area]/DDayNorm[enduse,area])^DDCoefficient[enduse,ec,area]+
      (1.0-TSLoad[enduse,ec,area]))
  end
  WriteDisk(db,"$Outpt/DEEA",year,DEEA)
  WriteDisk(db,"$Outpt/PEEA",year,PEEA)

  #
  # Marginal Energy Requirements (DmdRq)
  #
  for area in Areas,ec in ECs,tech in Techs,enduse in Enduses
    ecc = Select(ECC,EC[ec])
    if PEE[enduse,tech,ec,area] == 0 || DEE[enduse,tech,ec,area] == 0
      DmdRq[enduse,tech,ec,area] = 0
    else
      DmdRq[enduse,tech,ec,area] = DSt[enduse,ec,area]/PEE[enduse,tech,ec,area]/
      DEE[enduse,tech,ec,area]*AMSF[enduse,tech,ec,area]*CERSM[enduse,ec,area]*ECUF[ecc,area]*
      RPEI[enduse,tech,ec,area]/1.0e6
    end
  end
  WriteDisk(db,"$Outpt/DmdRq",year,DmdRq)

  #
  # Sequestering Energy Penalty
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    Dmd[enduse,tech,ec,area] = Dmd[enduse,tech,ec,area]+
                               SqDmd[tech,ec,area]*SqEUTechMap[enduse,tech]
  end

  #
  # Additional motors are require for EOR in Light Oil Mining
  #
  if SectorName == "Industrial"
    ec = Select(EC,"LightOilMining")
    tech = Select(Tech,"Electric")
    enduse = Select(Enduse,"Motors")
    process = Select(Process,"LightOilMining")
    for area in Areas
      Dmd[enduse,tech,ec,area] = Dmd[enduse,tech,ec,area]+
                                 OAPrEOR[process,area]*EORDmd[area]
    end
  end
  
  #
  # Natural Gas Pipeline Energy changes when H2 is in the pipeline
  # 
  if SectorName == "Commercial"
    NGPipeline = Select(EC,"NGPipeline")
    Gas = Select(Tech,"Gas")
    OthSub = Select(Enduse,"OthSub")
    for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
      if (ec == NGPipeline) && (tech == Gas) && (enduse == OthSub)
        Dmd[enduse,tech,ec,area] = Dmd[enduse,tech,ec,area]*H2PipelineMultiplier[area]
      end
    end
  end

  #
  # Feedstock Demands
  #
  for tech in Techs,area in Areas,ec in ECs
    @finite_math FsDmd[tech,ec,area] = SPC[ec,area]/FsPEE[tech,ec,area]*WCUF[ec,area]
  end


  #
  # Remove DSM
  #
  @. Dmd = Dmd-DSMEU
  

  # 
  #   Some of Tech or EC use exogenous demands
  #
  for area in Areas, ec in ECs, tech in Techs
    if DmdSw[tech,ec,area] == Exogenous
      for enduse in Enduses
        Dmd[enduse,tech,ec,area] = xDmd[enduse,tech,ec,area]
      end
      FsDmd[tech,ec,area] = xFsDmd[tech,ec,area]
    end
  end
  
  WriteDisk(db,"$Outpt/Dmd",year,Dmd)
  WriteDisk(db,"$Outpt/FsDmd",year,FsDmd)
 
end

function EECalculation(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,Techs,Enduses,ECC,Fuels) = data
  (; EESw,EE,Dmd,EEImpact,EESat,xEE) = data
  (; EEUCosts,EECosts,DmFrac) = data
  (; EEECC,EECoECC) = data

  #@debug "EECalculation"

  if EESw == 1
    #
    # Energy Efficiency is Endogenous (EESw eq 1)
    #
    # Energy Efficiency (EE) is enduse demand (Dmd) times reduction from EE (EEImpact)
    # times the fraction of load with EE (EESat).
    #
    @. EE = Dmd*EEImpact*EESat
  elseif EESw == 0
    @. EE = xEE
  else
    @. EE = 0
  end

  #
  # Energy Efficiency Costs
  #
  @. EECosts = EE*EEUCosts

  #
  # Energy Efficiency impact on Demand (Dmd)
  #
  @. Dmd = Dmd-EE

  #
  # Energy Efficiency impacts by ECC
  #
  for fuel in Fuels,ec in ECs,area in Areas,
    ecc = Select(ECC,EC[ec])
    EEECC[fuel,ecc,area] = sum(EE[enduse,tech,ec,area]*
      DmFrac[enduse,fuel,tech,ec,area] for enduse in Enduses,tech in Techs)
      
    EECoECC[fuel,ecc,area] = sum(EECosts[enduse,tech,ec,area]*
      DmFrac[enduse,fuel,tech,ec,area] for enduse in Enduses,tech in Techs)
  end

  WriteDisk(db,"$Outpt/Dmd",year,Dmd)
  WriteDisk(db,"$Outpt/EE",year,EE)
  WriteDisk(db,"$Outpt/EECosts",year,EECosts)
  WriteDisk(db,"SOutput/EECoECC",year,EECoECC)
  
end

function CogenerationSector(data::Data)
  (; db,year,CTime) = data
  (; Areas,EC,ECC,ECCs,ECs,Enduse,Enduses) = data
  (; Fuel,FuelEP,FuelEPs,Fuels,Node,Nodes,Plant,Plants,Tech,Techs) = data
  (; CgAT,CgBL,CgCC,CgCCR,CgCR,CgCUFP,CgDC,CgDemandPrior,CgDM,CgDmSw) = data
  (; CgEAW,CgECFP,CgElectricFraction,CgFP,CgFP0,CgGCCI) = data
  (; CgGCCIPlant,CgGCPrior,CgHRtM,CgIGC,CgIVTC,CgMAW) = data
  (; CgMCE,CgMCE0,CgMSF,CgMSM0,CgMSMI,CgMSMM,CgNodeFraction) = data
  (; CgOF,CgPCostPrior,CgPCost1,CgPCost2,CgPCost3,CgPCostExoPrior) = data
  (; CgPCostTech,CgPlantFraction,CgPot,CgPot0,CgPot1) = data
  (; CgPotElec,CgPotMult,CgPotSw,CgR,CgRatio,CgResI) = data
  (; CgRisk,CgSCM,CgTL,CgUMS,CgUMSPrior,CgVC,CgVCSw) = data
  (; CgVF,DER,ECFP,ECFP0,EEConv,ElecMap,Epsilon,FFPMap) = data
  (; FPTech,FTMap,Inflation,InSm,ROIN,SPC,SPC0,TxRt,xCgIGC) = data  

  #@debug "CogenerationSector"

  if SectorName != "Transportation"
  
    #
    # Cogeneration Emission Charges
    #
    for area in Areas, ec in ECs, fuelep in FuelEPs, fuel in Fuels
      if FuelEP[fuelep] == Fuel[fuel]
        ecc = Select(ECC,EC[ec])
        fuel = Select(Fuel,FuelEP[fuelep]) 
        CgPCost1[fuelep,ecc,area] = CgPCostPrior[fuelep,ecc,area]+
                                    CgPCostExoPrior[fuelep,ecc,area]*Inflation[area]
        CgPCost2[fuel,ecc,area] = CgPCost1[fuelep,ecc,area]
        CgPCost3[fuel,ec,area] = CgPCost2[fuel,ecc,area]
      end
    end
    for area in Areas, ec in ECs, tech in Techs
      ecc = Select(ECC,EC[ec])
      fuels = findall(FTMap[:,tech] .== 1)
      if !isempty(fuels)
        if sum(CgDemandPrior[fuel,ecc,area] for fuel in fuels) > 0.0
          CgPCostTech[tech,ec,area] = 
            sum(CgPCost3[fuel,ec,area]*CgDemandPrior[fuel,ecc,area] for fuel in fuels)/
            sum(CgDemandPrior[fuel,ecc,area] for fuel in fuels)       
        end
      end
    end
    WriteDisk(db,"$Outpt/CgPCostTech",year,CgPCostTech)

    #
    # Cogeneration Fuel Price including Emission Charges
    #
    @. CgECFP = FPTech+CgPCostTech
    WriteDisk(db,"$Outpt/CgECFP",year,CgECFP)

    #
    # Renewable Resources and Cost Curves
    #
    for tech in Techs,ec in ECs,area in Areas
      @finite_math CgDM[tech,area] = 1+CgDmSw[tech]*((CgResI[tech,area]-CgGCPrior[tech,ec,area])/CgResI[tech,area])
      CgDM[tech,area] = max(CgDM[tech,area],Epsilon)
      @finite_math CgCC[tech,ec,area] = CgCC[tech,ec,area]*CgDM[tech,area]
    end

    #
    # Cogeneration Capital Charge Rate
    #
    for ec in ECs,area in Areas,tech in Techs
      @finite_math CgCCR[ec,area] = (1-CgIVTC/(1+ROIN[ec,area]+CgRisk[tech]+
        InSm[area])-TxRt[ec,area]*(2/CgTL[tech,ec,area]))*
        (ROIN[ec,area]+CgRisk[tech])/(1-(1/(1+ROIN[ec,area]+CgRisk[tech]))^
        CgBL[tech,ec,area])/(1-TxRt[ec,area])
    end

    #
    # Marginal Cost of Cogeneration
    #
    for ec in ECs,area in Areas,tech in Techs
      @finite_math CgVC[tech,ec,area] = (CgCC[tech,ec,area]*CgOF[tech,ec,area]+
        CgDC[tech,area])*Inflation[area]+CgVCSw[tech]*(CgECFP[tech,ec,area]*
        CgHRtM[tech,ec,area]/EEConv)
      @finite_math CgMCE[tech,ec,area] = CgCCR[ec,area]*CgCC[tech,ec,area]/
        CgCUFP[tech,ec,area]*Inflation[area]+CgVC[tech,ec,area]
    end
    WriteDisk(db,"$Outpt/CgMCE",year,CgMCE)
    WriteDisk(db,"$Outpt/CgVC",year,CgVC)

    #
    # Assign values since Promula Read Disk is not avaialble.
    #
    Electric = Select(Tech,"Electric")
    Heat = Select(Enduse,"Heat")
    for ec in ECs,area in Areas
      CgFP[ec,area] = ECFP[Heat,Electric,ec,area]
      CgFP0[ec,area] = ECFP0[Heat,Electric,ec,area]
    end

    #
    # Allocation Weight and Market Share
    #
    for ec in ECs,area in Areas,tech in Techs
      if CgMCE[tech,ec,area] >= 0 && CgMCE0[tech,ec,area] >= 0    
        @finite_math CgMAW[tech,ec,area] = exp(CgMSM0[tech,ec,area]+
          log(CgMSMM[tech,ec,area])+
          CgMSMI[tech,ec,area]*(SPC[ec,area]/SPC0[ec,area])+
          CgVF[tech,ec,area]*log(CgMCE[tech,ec,area]/CgMCE0[tech,ec,area]))
      else
        CgMAW[tech,ec,area] = 0.0
      end
    
      if CgFP[ec,area] >= 0 && CgFP0[ec,area] >= 0  
        @finite_math CgEAW[tech,ec,area] = 
          exp(CgVF[tech,ec,area]*log(CgFP[ec,area]/CgFP0[ec,area]))
      end
    end

    @. @finite_math CgMSF = CgMAW/(CgMAW+CgEAW)
    WriteDisk(db,"$Outpt/CgMSF",year,CgMSF)

    #
    # Cogeneration Capacity Retirements
    # Since all the Cogeneration are "Units",the retirement rate (if needed,
    # must come from the "Units". - Jeff Amlin 05/21/23
    #
    @. CgR = 0
    WriteDisk(db,"$Outpt/CgR",year,CgR)

    #
    # Cogeneration Capacity Additions
  
    #
    # Cogeneration Potential is maximum cogeneration power that could be
    # generated. The basis for the potential can either be process heat
    # demand (CgPot0) or electricity demand (CgPot1).  The basis cannot
    # be changed without recalibrating the model.  Jeff Amlin 7/22/15
    #
    for tech in Techs,ec in ECs,area in Areas
      @finite_math CgPot0[tech,ec,area] =
        sum(DER[enduse,tech,ec,area] for enduse in Enduses)/CgHRtM[tech,ec,area]/8760*1000
    end
  
    techs = findall(ElecMap .== 1)
    if !isempty(techs)
      for ec in ECs,area in Areas
        CgPotElec[ec,area] = sum(DER[enduse,tech,ec,area]/EEConv/8760*1000
          for enduse in Enduses,tech in techs)
      end
    end
    
    for tech in Techs,ec in ECs,area in Areas
      @finite_math CgPot1[tech,ec,area] = CgPotElec[ec,area]/CgCUFP[tech,ec,area]
    end  
    @. CgPot = (CgPot0*(1-CgPotSw)+CgPot1*CgPotSw)*CgPotMult
    WriteDisk(db,"$Outpt/CgPot",year,CgPot)

    #
    # Cogeneration Construction
    #
    @. CgIGC = max(CgPot*CgMSF,xCgIGC)
    @. @finite_math CgCR = (CgIGC-CgGCPrior)/CgAT+CgR
    @. CgCR = max(CgCR,0)
    WriteDisk(db,"$Outpt/CgCR",year,CgCR)
    WriteDisk(db,"$Outpt/CgIGC",year,CgIGC)

    #
    # Cogeneration Initiated
    #
    @. CgGCCIPlant = 0.0
    for area in Areas, ec in ECs, tech in Techs, plant in Plants
      if (ElecMap[tech] == 1) && (CgElectricFraction[plant,ec,area] > 0.0)
        CgGCCIPlant[plant,ec,area] = CgCR[tech,ec,area]*CgElectricFraction[plant,ec,area]
      elseif (CgPlantFraction[tech,plant] > 0.0)
        CgGCCIPlant[plant,ec,area] = CgGCCIPlant[plant,ec,area]+
                                     CgCR[tech,ec,area]*CgPlantFraction[tech,plant]
      end
    end
    for area in Areas, node in Nodes, ec in ECs, plant in Plants
      ecc = Select(ECC,EC[ec])
      CgGCCI[plant,ecc,node,area] = CgGCCIPlant[plant,ec,area]*CgNodeFraction[ec,node,area]
    end
    WriteDisk(db,"SOutput/CgGCCI",year,CgGCCI)
  
    #
    # Cogeneration Load and Energy
    # (Variable Costs Must Be Less Than Electricity Price)
    #
    for area in Areas, ec in ECs, tech in Techs
      @finite_math CgRatio[tech,ec,area] = CgFP[ec,area]/
        (max(CgVC[tech,ec,area],0.000001)*CgSCM[tech])
      CgRatio[tech,ec,area] = min(1.0,CgRatio[tech,ec,area])
      @finite_math CgUMS[tech,ec,area] = CgUMSPrior[tech,ec,area]+
        DT*(CgRatio[tech,ec,area]-CgUMSPrior[tech,ec,area])/CgAT[tech,ec,area]
    end

    WriteDisk(db,"$Outpt/CgUMS",year,CgUMS)
  end 
end

function CogenerationTotals(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,ECCs,Tech,Techs,FuelEPs,Fuel,Fuels,FFPMap) = data
  (; CgDmd,CgDemand,FTMap,CgEG,CgGen,CgGC,CgCap,CgDem) = data
  (; CgEC) = data

  #@debug "CogenerationTotals Function Call"

  #
  # Cogeneration mapped to Tech
  # Patch until we can review FTMap.  Jeff Amlin 7/14/16
  #
  for ec in ECs,area in Areas,tech in Techs
    ecc = Select(ECC,EC[ec])
    CgDmd[tech,ec,area] = sum(CgDemand[fuel,ecc,area]*FTMap[fuel,ec,tech] for fuel in Fuels)
    CgEG[tech,ec,area] = sum(CgGen[fuel,ecc,area]*FTMap[fuel,ec,tech] for fuel in Fuels)
    CgGC[tech,ec,area] = sum(CgCap[fuel,ecc,area]*FTMap[fuel,ec,tech] for fuel in Fuels)

    if Tech[tech] == "Electric"
      fuels = Select(Fuel,["Hydro","Wind"])
      CgDmd[tech,ec,area] = sum(CgDemand[fuel,ecc,area] for fuel in fuels)
      CgEG[tech,ec,area] = sum(CgGen[fuel,ecc,area] for fuel in fuels)
      CgGC[tech,ec,area] = sum(CgCap[fuel,ecc,area] for fuel in fuels)
    end  
  end

  #
  # Cogeneration Totals
  #
  for ec in ECs,area in Areas,fuelep in FuelEPs
    ecc = Select(ECC,EC[ec])
    CgDem[fuelep,ec,area] = sum(CgDemand[fuel,ecc,area]*FFPMap[fuelep,fuel] for fuel in Fuels)
  end

  for ecc in ECCs,area in Areas
    CgEC[ecc,area] = sum(CgGen[fuel,ecc,area] for fuel in Fuels)
  end

  WriteDisk(db,"$Outpt/CgDem",year,CgDem)
  WriteDisk(db,"$Outpt/CgDmd",year,CgDmd)
  WriteDisk(db,"$Outpt/CgEG",year,CgEG)
  WriteDisk(db,"$Outpt/CgGC",year,CgGC)
  WriteDisk(db,"SOutput/CgEC",year,CgEC)

end

function EnduseDemand(data::Data)
  (; db,year) = data
  (; Area,Areas,EC,ECs,ECC,Enduses) = data
  (; Fuel,Fuels,FuelEPs,Nation,Techs) = data
  (; ANMap,DEEA) = data
  (; DemRq,DemRqAB,Dmd,DmdFEPTech,DmdFuelTech) = data
  (; DmdRq,DmFrac,EuDem,EuDemand,EuDemF) = data
  (; FFPMap,FTMap) = data

  #@debug "EnduseDemand Function Call"

  for area in Areas, ec in ECs, fuel in Fuels, enduse in Enduses
    ecc = Select(ECC,EC[ec])
    EuDemF[enduse,fuel,ecc,area] = sum(Dmd[enduse,tech,ec,area]*
      DmFrac[enduse,fuel,tech,ec,area] for tech in Techs)
  end

  if SectorName != "Transportation"
    fuels = Select(Fuel,["Geothermal","Solar"])
    for area in Areas, ec in ECs, fuel in fuels, enduse in Enduses
      ecc = Select(ECC,EC[ec])
      EuDemF[enduse,fuel,ecc,area] = sum(Dmd[enduse,tech,ec,area]*
        DEEA[enduse,tech,ec,area]*FTMap[fuel,ec,tech] for tech in Techs)
    end
  end

  for area in Areas,ec in ECs, fuelep in FuelEPs, enduse in Enduses
    ecc = Select(ECC,EC[ec])
    EuDem[enduse,fuelep,ec,area] = sum(EuDemF[enduse,fuel,ecc,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels)
  end

  for area in Areas, ec in ECs, fuel in Fuels
    ecc = Select(ECC,EC[ec])
    EuDemand[fuel,ecc,area] = sum(EuDemF[enduse,fuel,ecc,area] for enduse in Enduses)
  end

  WriteDisk(db,"$Outpt/EuDem",year,EuDem)
  WriteDisk(db,"SOutput/EuDemand",year,EuDemand)

  for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    if DmFrac[enduse,fuel,tech,ec,area] > 0
      DmdFuelTech[enduse,fuel,tech,ec,area] = 
        max(Dmd[enduse,tech,ec,area],0.00001)*DmFrac[enduse,fuel,tech,ec,area]
    else
      DmdFuelTech[enduse,fuel,tech,ec,area] = 0
    end
  end
  WriteDisk(db,"$Outpt/DmdFuelTech",year,DmdFuelTech)

  for area in Areas, ec in ECs, tech in Techs, fuelep in FuelEPs
    DmdFEPTech[fuelep,tech,ec,area] = sum(DmdFuelTech[enduse,fuel,tech,ec,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels,enduse in Enduses)
  end
  WriteDisk(db,"$Outpt/DmdFEPTech",year,DmdFEPTech)

  #
  # Marginal Energy Requirements
  #
  for ec in ECs,area in Areas,fuel in Fuels
    ecc = Select(ECC,EC[ec])
    DemRq[fuel,ecc,area] = sum(DmdRq[enduse,tech,ec,area]*
      DmFrac[enduse,fuel,tech,ec,area] for enduse in Enduses,tech in Techs)
  end

  #
  #  US and Mexico are missing demand requirements (DemRq),use AB values
  #
  Alberta = Select(Area,"AB")
  for fuel in Fuels,ec in ECs
    ecc = Select(ECC,EC[ec])     
    DemRqAB[fuel,ecc] = DemRq[fuel,ecc,Alberta]  
  end
  nation = Select(Nation,"US")
  for fuel in Fuels,ec in ECs
    ecc = Select(ECC,EC[ec])     
    for area in Areas
      if ANMap[area,nation] == 1
        DemRq[fuel,ecc,area] = DemRqAB[fuel,ecc]
      end
    end
  end
  *
  nation = Select(Nation,"MX")
  for fuel in Fuels,ec in ECs
    ecc = Select(ECC,EC[ec])     
    for area in Areas
      if ANMap[area,nation] == 1
        DemRq[fuel,ecc,area] = DemRqAB[fuel,ecc]
      end
    end
  end
  WriteDisk(db,"SOutput/DemRq",year,DemRq)

end

function FeedstockDemand(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,Fuels,Techs) = data
  (; FsDem,FsDemand,FsDmd,FsFrac) = data

  #
  # Feedstock Totals
  #
  for area in Areas,ec in ECs,fuel in Fuels, tech in Techs
    FsDem[fuel,tech,ec,area] = FsDmd[tech,ec,area]*FsFrac[fuel,tech,ec,area]
  end

  for area in Areas,ec in ECs,fuel in Fuels
    ecc = Select(ECC,EC[ec])
    FsDemand[fuel,ecc,area] = sum(FsDem[fuel,tech,ec,area] for tech in Techs)
  end
  WriteDisk(db,"$Outpt/FsDem",year,FsDem)
  WriteDisk(db,"SOutput/FsDemand",year,FsDemand)

end

function TotalDemand(data::Data)
  (; db,year,CTime) = data
  (; Area,Areas,EC,ECs,ECC,ECCs,ES,Fuel,Fuels) = data
  (; CgDemand,CgEC,DmdES,EEConv,EuDemand,FsDemand,TotDemand) = data

  #
  # Total Fuel Demands
  #
  for area in Areas, ec in ECs, fuel in Fuels
    ecc = Select(ECC,EC[ec])
    TotDemand[fuel,ecc,area] = 
      EuDemand[fuel,ecc,area]+FsDemand[fuel,ecc,area]+CgDemand[fuel,ecc,area]
  end
  fuel = Select(Fuel,"Electric")
  for area in Areas, ec in ECs
    ecc = Select(ECC,EC[ec])  
    TotDemand[fuel,ecc,area] = TotDemand[fuel,ecc,area]-CgEC[ecc,area]*EEConv/1E6
  end
  WriteDisk(db,"SOutput/TotDemand",year,TotDemand)

  #
  # Energy Demands by Energy Sector
  #
  es = Select(ES,ESKey)
  for fuel in Fuels,area in Areas
    DmdES[es,fuel,area] = sum(TotDemand[fuel,ecc,area] for ecc in ECCs)
  end
  WriteDisk(db,"SOutput/DmdES",year,DmdES)

end

function SteamSalesPurchases(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,Enduse,Enduses,Tech,Techs) = data
  (; Dmd,ESHRt,StHR,StPur,StSold) = data

  if SectorName != "Transportation"
    #
    # Steam Sold to Market
    #
    if "Steam" in Enduse
      steam_enduse = Select(Enduse,"Steam")
      for tech in Techs,area in Areas,ec in ECs
        ESHRt[tech,ec,area] = StHR[area]
      end
      WriteDisk(db,"$Input/ESHRt",year,ESHRt)
      
      for ec in ECs,area in Areas
        ecc = Select(ECC,EC[ec])
        @finite_math StSold[ecc,area] = sum(Dmd[steam_enduse,tech,ec,area]/
                                        ESHRt[tech,ec,area] for tech in Techs)
      end
      WriteDisk(db,"SOutput/StSold",year,StSold)
    end
    
    #
    # Steam Purchased from Market
    #
    if "Steam" in Tech
      steam_tech = Select(Tech,"Steam")
      for ec in ECs,area in Areas
        ecc = Select(ECC,EC[ec])
        StPur[ecc,area] = sum(Dmd[enduse,steam_tech,ec,area] for enduse in Enduses)
      end
      WriteDisk(db,"SOutput/StPur",year,StPur)
    end
  end
end

function PollCoefficients(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,Techs,Enduses,Fuels,Poll,Polls,FuelEPs) = data
  (; POEMPrior,RMPrior) = data
  (; PolSw,POEMA,POEMR,DERA,POCX,POCA,POCAPrior,DERR) = data
  (; POEM,StockAdjustment,RM,DER,BCMultTr,FFPMap) = data
  (; BCarbonSw,FsPOCA,FsPOCX,FsPOCS) = data

  #@debug "PollCoefficients Function Call"

  #
  # Calculation pollution coefficents using embedded values (PolSw=1) or by
  # setting the average equal to marginal (PolSw=2).
  #
  for tech in Techs,ec in ECs,area in Areas,poll in Polls,enduse in Enduses,fuelep in FuelEPs
    if PolSw[tech,ec,poll,area] == 1
      
      #
      # Embedded pollution for new devices (POEMA)
      #
      POEMA[enduse,fuelep,tech,ec,poll,area] = DERA[enduse,tech,ec,area]*
        POCX[enduse,fuelep,tech,ec,poll,area]/1e6
      
      #
      # Embedded pollution for retired devices (POEMR)
      #
      @finite_math POEMR[enduse,fuelep,tech,ec,poll,area] = DERR[enduse,tech,ec,area]*
        POCAPrior[enduse,fuelep,ec,poll,area]/RMPrior[tech,ec,poll,area]/1e6
      
      #
      # Total embedded pollution
      #
      POEM[enduse,fuelep,tech,ec,poll,area] = POEMPrior[enduse,fuelep,tech,ec,poll,area]+
        DT*(POEMA[enduse,fuelep,tech,ec,poll,area]-POEMR[enduse,fuelep,tech,ec,poll,area])
      POEM[enduse,fuelep,tech,ec,poll,area] = POEM[enduse,fuelep,tech,ec,poll,area]*
        (1+StockAdjustment[enduse,tech,ec,area])
      
      #
      # Average Pollution Coefficient
      #
      @finite_math POCA[enduse,fuelep,tech,ec,poll,area] = POEM[enduse,fuelep,tech,ec,poll,area]/
        DER[enduse,tech,ec,area]*1E6*RM[tech,ec,poll,area]
    
    #
    #  Calculate Coefficients assuming Average equals Marginal (PolSw=2)
    #
    elseif PolSw[tech,ec,poll,area] == 2

      #
      # Average Enduse Energy Pollution Coefficient
      #
      POCA[enduse,fuelep,tech,ec,poll,area] = POCX[enduse,fuelep,tech,ec,poll,area]*
        RM[tech,ec,poll,area]
        
      @finite_math POEM[enduse,fuelep,tech,ec,poll,area] = POCA[enduse,fuelep,tech,ec,poll,area]*
        DER[enduse,tech,ec,area]/1e6/RM[tech,ec,poll,area]
      
      POEM[enduse,fuelep,tech,ec,poll,area] = POEM[enduse,fuelep,tech,ec,poll,area]*
        (1+StockAdjustment[enduse,tech,ec,area])
    
    #
    # Calculate Coefficients using Embedded Pollution for Enduse Energy
    # and assuming Average equals Marginal for Cogeneration (PolSw=3)
    #
    elseif PolSw[tech,ec,poll,area] == 3
    
      #
      # Embedded pollution for new devices (POEMA)
      #
      POEMA[enduse,fuelep,tech,ec,poll,area] = DERA[enduse,tech,ec,area]*
        POCX[enduse,fuelep,tech,ec,poll,area]/1e6
      
      #
      # Embedded pollution for retired devices (POEMR)
      #
      @finite_math POEMR[enduse,fuelep,tech,ec,poll,area] = DERR[enduse,tech,ec,area]*
        POCA[enduse,fuelep,tech,ec,poll,area]/RMPrior[tech,ec,poll,area]/1e6
      
      #
      # Total embedded pollution
      #
      POEM[enduse,fuelep,tech,ec,poll,area] = POEMPrior[enduse,fuelep,tech,ec,poll,area]+
        DT*(POEMA[enduse,fuelep,tech,ec,poll,area]-POEMR[enduse,fuelep,tech,ec,poll,area])

      POEM[enduse,fuelep,tech,ec,poll,area] = POEM[enduse,fuelep,tech,ec,poll,area]*
        (1+StockAdjustment[enduse,tech,ec,area])

      #
      # Average Pollution Coefficient
      #
      @finite_math POCA[enduse,fuelep,tech,ec,poll,area] = POEM[enduse,fuelep,tech,ec,poll,area]/
        DER[enduse,tech,ec,area]*1E6*RM[tech,ec,poll,area]
    end
  end

  #
  # Average Non-Energy Pollution
  #
  for fuel in Fuels,tech in Techs,ec in ECs,poll in Polls,area in Areas
    FsPOCA[fuel,tech,ec,poll,area] = min(FsPOCX[fuel,tech,ec,poll,area],FsPOCS[fuel,tech,ec,poll,area])
  end

  if BCarbonSw == 1
    bc = Select(Poll,"BC")
    pm25 = Select(Poll,"PM25")
    #
    # Black Carbon (BC) is a function of PM 2.5 (PM25).
    #
    for ec in ECs
      ecc = Select(ECC,EC[ec])
      if EC[ec] == ECC[ecc]
        for fuelep in FuelEPs, fuel in Fuels
          if FFPMap[fuelep,fuel] == 1.0
            for area in Areas, tech in Techs
              for eu in Enduses
                POCX[eu,fuelep,tech,ec,bc,area] = POCX[eu,fuelep,tech,ec,pm25,area]*BCMultTr[fuel,tech,ec,area]
                POCA[eu,fuelep,tech,ec,bc,area] = POCA[eu,fuelep,tech,ec,pm25,area]*BCMultTr[fuel,tech,ec,area]
              end
              FsPOCX[fuel,tech,ec,bc,area] = FsPOCX[fuel,tech,ec,pm25,area]*BCMultTr[fuel,tech,ec,area]
              FsPOCA[fuel,tech,ec,bc,area] = FsPOCA[fuel,tech,ec,pm25,area]*BCMultTr[fuel,tech,ec,area]
              RM[tech,ec,bc,area] = RM[tech,ec,pm25,area]
            end
          end
        end
      end
    end
    
    WriteDisk(db,"$Input/FsPOCX",year,FsPOCX)
    WriteDisk(db,"$Input/POCX",year,POCX)
    WriteDisk(db,"$Outpt/RM",year,RM)  
  end
  
  WriteDisk(db,"$Outpt/FsPOCA",year,FsPOCA)
  WriteDisk(db,"$Outpt/POCA",year,POCA)
  WriteDisk(db,"$Outpt/POCA",year,POCA)
  WriteDisk(db,"$Outpt/POEM",year,POEM)

end

function SequesteringPotential(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,Enduses,ECC,ECCs,Fuels,Poll,Polls,FuelEPs,Techs) = data
  (; EnSqPot,Polute,SqEnMap,FsSqPot,FsPol,CgSqPot,CgFPolGross) = data
  (; MESqPot,MEPol,SqPolCCPenalty,SqPotential,SqPenaltyFrac) = data

  for ec in ECs,poll in Polls,area in Areas
    ecc = Select(ECC, EC[ec])
    EnSqPot[ecc,poll,area] = sum(Polute[enduse,fuelep,tech,ec,poll,area]*
      SqEnMap[enduse] for enduse in Enduses, fuelep in FuelEPs, tech in Techs)
    FsSqPot[ecc,poll,area] = sum(FsPol[fuel,tech,ec,poll,area] for fuel in Fuels, tech in Techs)
    CgSqPot[ecc,poll,area] = sum(CgFPolGross[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end
  WriteDisk(db,"SOutput/EnSqPot",year,EnSqPot)
  WriteDisk(db,"SOutput/FsSqPot",year,FsSqPot)
  WriteDisk(db,"SOutput/CgSqPot",year,CgSqPot)

  CO2 = Select(Poll,"CO2")
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for area in Areas
      MESqPot[ecc,CO2,area] = MEPol[ecc,CO2,area]
    end
    for area in Areas, poll in Polls
      SqPotential[ecc,poll,area] = (EnSqPot[ecc,poll,area]+FsSqPot[ecc,poll,area]+CgSqPot[ecc,poll,area]+MESqPot[ecc,poll,area]+
                                    SqPolCCPenalty[ecc,poll,area])*(1+SqPenaltyFrac[ecc,poll,area])
    end
  end
  WriteDisk(db,"SOutput/MESqPot",year,MESqPot)
  WriteDisk(db,"SOutput/SqPotential",year,SqPotential)

end

function PRAccounting(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,Enduses,ECC,FuelEPs,Polls,Techs) = data
  (; AGFr,CgPolEC,GRExp,PAdCost,Polute,PRExp) = data
  (; PRExpenditures,RCap,RCapPrior,RCC,RCCEm) = data
  (; RCCEmPrior,RCD,RCI,RCPL,RCR,RCRPrior,RICap) = data
  (; RM,ROCF,RP,RPFull,xRM) = data

  #@debug "PRAccounting Function Call"

  #
  # Pollution Reduction Accounting
  #
  # Indicated Reduction Capacity (RICap) is emissions divided by the reduction
  # multiplier (to give back total embodied emissions) times the pollution
  # reduction (RP) which tells how many Tonnes of pollution can be reduced.
  #

  @. RPFull = 1-(1-RP)*xRM

  for fuelep in FuelEPs, ec in ECs, poll in Polls, area in Areas, tech in Techs
    @finite_math RICap[tech,ec,poll,area] = sum(Polute[enduse,fuelep,tech,ec,poll,area] for enduse in Enduses) +
      CgPolEC[fuelep,ec,poll,area]/RM[tech,ec,poll,area]*RPFull[tech,ec,poll,area]
  end

  #
  # Reduction Capacity Initiation Rate
  #
  for tech in Techs, ec in ECs, poll in Polls, area in Areas
    @finite_math var1 = RICap[tech,ec,poll,area]-RCapPrior[tech,ec,poll,area]-RCRPrior[tech,ec,poll,area]*RCD[ec,poll]+
      RCapPrior[tech,ec,poll,area]/RCPL[ec,poll]
    @finite_math RCI[tech,ec,poll,area] = max(var1, 0.0)/RCD[ec,poll]
    @finite_math RCI[tech,ec,poll,area] = max(RICap[tech,ec,poll,area]-
      RCapPrior[tech,ec,poll,area]-RCRPrior[tech,ec,poll,area]*RCD[ec,poll]+
      RCapPrior[tech,ec,poll,area]/RCPL[ec,poll],0.0)/RCD[ec,poll]
  end

  #
  # Embedded Reduction Capital Costs
  #
  @. RCCEm = RCCEmPrior+DT*RCC*RCRPrior

  #
  # Reduction Capacity
  #
  for tech in Techs, ec in ECs, poll in Polls, area in Areas
    @finite_math RCap[tech,ec,poll,area] = RCapPrior[tech,ec,poll,area]+DT*
      (RCRPrior[tech,ec,poll,area]-RCapPrior[tech,ec,poll,area]/RCPL[ec,poll])
  end

  #
  # Reduction Capacity Completion Rate (has to come last, given equations above)
  #
  for tech in Techs,ec in ECs,poll in Polls,area in Areas
    @finite_math RCR[tech,ec,poll,area] = RCRPrior[tech,ec,poll,area]+DT*
      (RCI[tech,ec,poll,area]-RCRPrior[tech,ec,poll,area])/RCD[ec,poll]
  end

  for area in Areas,ec in ECs,poll in Polls
    ecc = Select(ECC,EC[ec])
    #
    # Private Expenses for Pollution Reductions
    #
    PRExp[ecc,poll,area] = sum(RCR[tech,ec,poll,area]*RCC[tech,ec,poll,area]*(1-AGFr[ecc,poll,area])+
      RCCEm[tech,ec,poll,area]*ROCF[tech,ec,poll,area] for tech in Techs)/1e6
    #
    # Government Expenses for Pollution Reductions
    #
    GRExp[ecc,poll,area] = sum(RCR[tech,ec,poll,area]*RCC[tech,ec,poll,area]*
      (AGFr[ecc,poll,area]) for tech in Techs)/1e6+PAdCost[ecc,poll,area]
  end

  for area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    PRExpenditures[ecc,area] = sum(GRExp[ecc,poll,area]+PRExp[ecc,poll,area] for poll in Polls)
  end

  WriteDisk(db,"SOutput/GRExp",year,GRExp)
  WriteDisk(db,"SOutput/PRExp",year,PRExp)
  WriteDisk(db,"SOutput/PRExpenditures",year,PRExpenditures)
  WriteDisk(db,"$Outpt/RCap",year,RCap)
  WriteDisk(db,"$Outpt/RCCEm",year,RCCEm)
  WriteDisk(db,"$Outpt/RCI",year,RCI)
  WriteDisk(db,"$Outpt/RCR",year,RCR)

end

function PollutionGenerated(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,ECCs,Polls,Enduses,Fuels,FuelEPs,PCov,Sector,Techs) = data
  (; CgFPol,CgPol,CgPolEC,CgPolSq,CgPolSqPenalty,DmdFEPTech,ECoverage) = data
  (; EuFPol,EuPol,FFPMap,FsDem,FsPOCA,FsPol,GrossEnFPol,GrossPol) = data
  (; NcFPol,NcPol,OREnFPol,PCCov,POCA,Polute,RM,SqPolCg) = data
  (; SqPolCgPenalty,TFPol,TotFPol,TSPol,ZeroFr) = data

  #@debug "PollutionGenerated Function Call"

  #
  # Pollution by Enduse and Technology
  #

  for area in Areas,poll in Polls,ec in ECs,fuelep in FuelEPs,tech in Techs,enduse in Enduses
    Polute[enduse,fuelep,tech,ec,poll,area] = DmdFEPTech[fuelep,tech,ec,area]*
      POCA[enduse,fuelep,tech,ec,poll,area]
  end
  WriteDisk(db,"$CalDB/Polute",year,Polute)

  for area in Areas,poll in Polls,ec in ECs,tech in Techs,fuel in Fuels
    FsPol[fuel,tech,ec,poll,area] = FsDem[fuel,tech,ec,area]*FsPOCA[fuel,tech,ec,poll,area]
  end
  WriteDisk(db,"$Outpt/FsPol",year,FsPol)

  #
  # Energy Pollution
  #
  for area in Areas,poll in Polls,ec in ECs,fuelep in FuelEPs
    ecc = Select(ECC,EC[ec])
    EuFPol[fuelep,ecc,poll,area] = sum(Polute[enduse,fuelep,tech,ec,poll,area]*
      (1-ZeroFr[fuelep,poll,area]) for tech in Techs, enduse in Enduses)
  end
  WriteDisk(db,"SOutput/EuFPol",year,EuFPol)

  for area in Areas,poll in Polls,ec in ECs
    ecc = Select(ECC,EC[ec])
    EuPol[ecc,poll,area] = sum(EuFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end
  WriteDisk(db,"SOutput/EuPol",year,EuPol)

  #
  # Off-Road Fuel Emissions
  # 
  if SectorName == "Transportation"
    ecs=Select(EC,["ResidentialOffRoad","CommercialOffRoad"])
    for ec in ecs
      ecc = Select(ECC,EC[ec])
      for fuelep in FuelEPs
        for area in Areas, poll in Polls
          OREnFPol[fuelep,ecc,poll,area] = sum(Polute[enduse,fuelep,tech,ec,poll,area]
                                               for tech in Techs, enduse in Enduses)
        end
      end
    end
    WriteDisk(db,"SOutput/OREnFPol",year,OREnFPol)
  end

  #
  # Non-Combustion Related Pollution
  #
  for area in Areas,poll in Polls,ec in ECs,fuel in Fuels
    ecc = Select(ECC,EC[ec])
    NcFPol[fuel,ecc,poll,area] = sum(FsPol[fuel,tech,ec,poll,area] for tech in Techs)
  end
  WriteDisk(db,"SOutput/NcFPol",year,NcFPol)

  for area in Areas,poll in Polls,ec in ECs
    ecc = Select(ECC,EC[ec])
    NcPol[ecc,poll,area] = sum(NcFPol[fuel,ecc,poll,area] for fuel in Fuels)
  end
  WriteDisk(db,"SOutput/NcPol",year,NcPol)

  #
  # Cogeneration Pollution
  #
  for ecc in ECCs,poll in Polls,area in Areas
    CgPol[ecc,poll,area] = sum(CgFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end

  for ec in ECs,poll in Polls,area in Areas,fuelep in FuelEPs
    ecc = Select(ECC,EC[ec])
    CgPolEC[fuelep,ec,poll,area] = CgFPol[fuelep,ecc,poll,area]
  end

  for ec in ECs,poll in Polls,area in Areas
    ecc = Select(ECC,EC[ec])
    SqPolCg[ecc,poll,area] = 0 - CgPolSq[ecc,poll,area]
    SqPolCgPenalty[ecc,poll,area] = 0 - CgPolSqPenalty[ecc,poll,area]
  end

  WriteDisk(db,"SOutput/CgPol",year,CgPol)
  WriteDisk(db,"$Outpt/CgPolEC",year,CgPolEC)
  WriteDisk(db,"SOutput/SqPolCg",year,SqPolCg)
  WriteDisk(db,"SOutput/SqPolCgPenalty",year,SqPolCgPenalty)

  #
  # Pollution Totals
  #
  for area in Areas,poll in Polls,ecc in ECCs,fuelep in FuelEPs
    TotFPol[fuelep,ecc,poll,area] = EuFPol[fuelep,ecc,poll,area]+
    sum(NcFPol[fuel,ecc,poll,area]*FFPMap[fuelep,fuel] for fuel in Fuels)+
    CgFPol[fuelep,ecc,poll,area]
  end

  sector = Select(Sector,SectorKey)
  for area in Areas,poll in Polls,fuelep in FuelEPs
    TFPol[sector,fuelep,poll,area] = sum(TotFPol[fuelep,ecc,poll,area] for ecc in ECCs)
  end

  for area in Areas,poll in Polls
    TSPol[sector,poll,area] = sum(TFPol[sector,fuelep,poll,area] for fuelep in FuelEPs)
  end

  WriteDisk(db,"SOutput/TFPol",year,TFPol)
  WriteDisk(db,"SOutput/TotFPol",year,TotFPol)
  WriteDisk(db,"SOutput/TSPol",year,TSPol)

  #
  # Gross Pollution (GrossPol) is the covered pollution before the
  # impact of a pollution policy
  #
  
  noncombustion = Select(PCov,"NonCombustion")

  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for area in Areas, poll in Polls
    
      for tech in Techs
        if RM[tech,ec,poll,area] != 0
          GrossEnFPol[tech,ec,poll,area] = sum(Polute[enduse,fuelep,tech,ec,poll,area]/
            RM[tech,ec,poll,area]*PCCov[tech,ec,poll,area]*(1-ZeroFr[fuelep,poll,area])
            for fuelep in FuelEPs, enduse in Enduses)
        else
          GrossEnFPol[tech,ec,poll,area] = 0
        end
      end
      
      GrossPol[ecc,poll,area] = sum(GrossEnFPol[tech,ec,poll,area] for tech in Techs)+
        sum(FsPol[fuel,tech,ec,poll,area]*ECoverage[ec,poll,noncombustion,area] for tech in Techs, fuel in Fuels)
    end
  end

  WriteDisk(db,"SOutput/GrossPol",year,GrossPol)

end

function Investments(data::Data)
  (; db,year,OGRefName,SceName,CTime) = data
  (; Areas,EC,ECs,ECC,ES,Polls,Enduse,Enduses) = data
  (; Fuels,FuelEPs,Tech,Techs,Age,Ages,Process) = data
  (; AGFr,BaseSw,CgCC,CgDC,CgDemand,CgDmd,CgOF,CgOMExp,CgFuelExpenditures,DCC,DCCFullCost) = data
  (; DCCRef,DemCC,DemCCMult,DemCCRef,DInv,DInvTech) = data
  (; DInvTechExo,DInvTechLast,DOCF,DOMExp,Driver,DriverLast,EORDInv,EuDemand,EUPC,EUPCAPC,EUPCRef) = data
  (; EUPCTemp,FPEC,FsDemand,FsFP,FuelExpenditures) = data
  (; Inflation,InflationRef,OAPrEOR,OAPrEORPrior,OMExp,PCC) = data
  (; PCCFC,PCCRef,PCEU,PER,PERA,PERRef,PInv,PInvDevice,PInvDriver,PInvExo) = data
  (; PInvMinFrac,PInvMinimum,PInvTech,POCF,POMExp,RCC,RCCEm) = data
  (; RCR,RDCC,RDMSF,RefSwitch,RInv,ROCF,ROMExp,RPCC,RPMSF) = data

  #@debug "Investments Function Call"

  for ec in ECs
    ecc = Select(ECC,EC[ec])
    
    #
    # Device Investments
    #
    for enduse in Enduses, tech in Techs, area in Areas  
      DInvTech[enduse,tech,ec,area] = (DCCFullCost[enduse,tech,ec,area]*PERA[enduse,tech,ec,area]+
        RDCC[enduse,tech,ec,area]*PER[enduse,tech,ec,area]*RDMSF[enduse,tech,ec,area])/1e6+
        DInvTechExo[enduse,tech,ec,area]*Inflation[area]
    end
    
    #
    # Additional motors are require for EOR in Light Oil Mining
    #
    if SectorName == "Industrial"
      LightOilMining = Select(EC,"LightOilMining")
      Electric = Select(Tech,"Electric")
      Motors = Select(Enduse,"Motors")    
      for enduse in Enduses, tech in Techs, area in Areas  
        if (ec == LightOilMining) && (tech == Electric) && (enduse == Motors)
          process = Select(Process,"LightOilMining")
          
          DInvTech[enduse,tech,ec,area] = DInvTech[enduse,tech,ec,area]+
            (OAPrEOR[process,area]-OAPrEORPrior[process,area])*EORDInv[area]
            
        end
      end
    end
    
    #
    # TODO - revise this section with new methodology - Jeff Amlin 11/7/25
    #
    if CTime > HisTime
      for enduse in Enduses, tech in Techs, area in Areas 
        if DriverLast[ecc,area] > 0.0001
          PInvDevice[enduse,tech,ec,area] = DInvTech[enduse,tech,ec,area]-
            DInvTechLast[enduse,tech,ec,area]*Driver[ecc,area]/DriverLast[ecc,area]
        else
          PInvDevice[enduse,tech,ec,area] = DInvTech[enduse,tech,ec,area]
        end
      end
    end
    
    for area in Areas
      DInv[ecc,area] = sum(DInvTech[enduse,tech,ec,area] for tech in Techs,enduse in Enduses)
    end

    #
    # O&M Expenditures
    #
    # TODOPromula: OMExp's first two lines aren't weighted by Inflation. 
    # Those same calculations are weighted by Inflation in DOMExp. Both of these
    # variables cannot accurately be described as nominal, which they are in their
    # varaible descriptions. PNV 1 July 2025.
    #
    
    for area in Areas
      OMExp[ecc,area] = sum(DCCFullCost[enduse,tech,ec,area]*DOCF[enduse,tech,ec,area]*
             PER[enduse,tech,ec,area]/1000000 for tech in Techs,enduse in Enduses)+
             sum((CgCC[tech,ec,area]*CgOF[tech,ec,area]+CgDC[tech,area])*
             CgDmd[tech,ec,area] for tech in Techs)*Inflation[area] 
    end

    #
    # Device O&M Expenditures
    #
    for area in Areas
      DOMExp[ecc,area] = sum(DCCFullCost[enduse,tech,ec,area]*DOCF[enduse,tech,ec,area]*
        PER[enduse,tech,ec,area]*Inflation[area] for tech in Techs,enduse in Enduses)/1000000
    end

    #
    # Process O&M Expenditures
    #
    for area in Areas
      POMExp[ecc,area] = sum(PCCFC[enduse,tech,ec,area]*POCF[enduse,tech,ec,area]*
        PCEU[enduse,tech,ec,area]*Inflation[area] for tech in Techs,enduse in Enduses)
    end

    #
    # Cogeneration O&M Expenditures
    #
    for area in Areas
      CgOMExp[ecc,area] = sum((CgCC[tech,ec,area]*CgOF[tech,ec,area]+CgDC[tech,area])*
      CgDmd[tech,ec,area] for tech in Techs)*Inflation[area]
    end

    #
    # Fuel Expenditures including Cogeneration
    #
    es = Select(ES,ESKey)
    for area in Areas
      FuelExpenditures[ecc,area] = sum(EuDemand[fuel,ecc,area]*FPEC[fuel,ec,area]+
                                       CgDemand[fuel,ecc,area]*FPEC[fuel,ec,area]+
                                       FsDemand[fuel,ecc,area]*FsFP[fuel,es,area]
                                       for fuel in Fuels)
    end

    #
    # Cogeneration Fuel Expenditures
    #
    for area in Areas
      CgFuelExpenditures[ecc,area] = sum(CgDemand[fuel,ecc,area]*FPEC[fuel,ec,area]
                                         for fuel in Fuels)
    end

    #
    # Process Investments (no process investments in transportation)
    #
    if SectorName != "Transportation"
      New = Select(Age,"New")
      for area in Areas, enduse in Enduses
        if Enduse[enduse] == "Heat"
          for tech in Techs
            PInvTech[enduse,tech,ec,area] = (PCC[enduse,tech,ec,area]*
              EUPCAPC[enduse,tech,New,ec,area]+RPCC[enduse,tech,ec,area]*
              sum(EUPC[enduse,tech,age,ec,area] for age in Ages)*RPMSF[enduse,tech,ec,area])+
              PInvExo[enduse,tech,ec,area]*Inflation[area]
          end
          PInvMinimum[ecc,area] = sum(PCC[enduse,tech,ec,area]*
            EUPC[enduse,tech,age,ec,area] for age in Ages, tech in Techs)*
            PInvMinFrac[ec,area]+
            sum(PInvExo[enduse,tech,ec,area] for tech in Techs)*Inflation[area]+
            sum(DInvTech[enduse,tech,ec,area] for tech in Techs)
          PInvDriver[ecc,area] = sum(PInvTech[enduse,tech,ec,area] for tech in Techs)
        end
        PInv[ecc,area] = max(PInvDriver[ecc,area],PInvMinimum[ecc,area])
        if Driver[ecc,area] <= 0.00001
          PInv[ecc,area] = 0.0
        end        
        for tech in Techs
          PInvTech[enduse,tech,ec,area] = 
            PInvTech[enduse,tech,ec,area]/PInvDriver[ecc,area]*PInv[ecc,area]
        end
      end

      #
      # Emission Reduction Investments
      #
      for area in Areas
        RInv[ecc,area] = sum(RCR[tech,ec,poll,area] *RCC[tech,ec,poll,area]*
          (1-AGFr[ec,poll,area]) for poll in Polls,tech in Techs)/ 1000000
        # 
        # Emission Reduction O&M Costs
        #
        ROMExp[ecc,area] = sum(RCCEm[tech,ec,poll,area]*
          ROCF[tech,ec,poll,area] for poll in Polls, tech in Techs)/1e6
      end
    end
  end
  
  WriteDisk(db,"SOutput/CgFuelExpenditures",year,CgFuelExpenditures)
  WriteDisk(db,"SOutput/CgOMExp",year,CgOMExp)
  WriteDisk(db,"SOutput/DInv",year,DInv)
  WriteDisk(db,"$Outpt/DInvTech",year,DInvTech)
  WriteDisk(db,"SOutput/DOMExp",year,DOMExp)
  WriteDisk(db,"SOutput/FuelExpenditures",year,FuelExpenditures)
  WriteDisk(db,"SOutput/OMExp",year,OMExp)
  WriteDisk(db,"SOutput/PInv",year,PInv)
  WriteDisk(db,"$Outpt/PInvDevice",year,PInvDevice)
  WriteDisk(db,"SOutput/PInvDriver",year,PInvDriver)
  WriteDisk(db,"SOutput/PInvMinimum",year,PInvMinimum)
  WriteDisk(db,"$Outpt/PInvTech",year,PInvTech)
  WriteDisk(db,"SOutput/POMExp",year,POMExp)
  WriteDisk(db,"SOutput/RInv",year,RInv)
  WriteDisk(db,"SOutput/ROMExp",year,ROMExp)

  if SectorName != "Transportation"
    if (OGRefName != SceName) && (BaseSw == 0) && (RefSwitch != 2)
      #
      # In Promula we have to manually read DCCRef, EUPCRef, PCCRef, 
      # PERRef, InflationRef in certain cases to replace default values.
      # Julia reads these by default, so we need to reset to default
      # if we are not in one of these cases.
      #
    else
      @. DCCRef = DCC
      @. EUPCRef = EUPC
      @. PCCRef = PCC
      @. PERRef = PER
      @. InflationRef = Inflation
    end

    #
    # $/Yr DCC($/mmBtu)         PER(mmBtu/Yr)
    # $/Yr PCC($/Driver,$/TBtu) EUPC(Driver/Yr,TBtu/Yr)
    #
    for ec in ECs
      ecc = Select(ECC,EC[ec])
      for area in Areas
        DemCC[ecc,area] = sum(DCC[enduse,tech,ec,area]/Inflation[area]*
          PERRef[enduse,tech,ec,area] for tech in Techs, enduse in Enduses)
      
        #
        # LJD: Attempting to reproduce Promula behavior of selecting all Enduses 
        # if Heat is not an enduse.
        #
        enduses = findall(Enduse[:] .== "Heat")
        if isempty(enduses)
          enduses = Select(Enduse)
        end

        for tech in Techs, enduse in enduses
          EUPCTemp[enduse,tech,ec,area] = sum(EUPCRef[enduse,tech,age,ec,area] for age in Ages)
        end
        DemCC[ecc,area] = DemCC[ecc,area]+
          sum(PCC[enduse,tech,ec,area]/Inflation[area]*
          EUPCTemp[enduse,tech,ec,area] for tech in Techs, enduse in enduses)


        DemCCRef[ecc,area] = sum(DCCRef[enduse,tech,ec,area]/InflationRef[area]*
          PERRef[enduse,tech,ec,area] for tech in Techs, enduse in Enduses)

        DemCCRef[ecc,area] = DemCCRef[ecc,area]+
          sum(PCCRef[enduse,tech,ec,area]/InflationRef[area]*
          EUPCTemp[enduse,tech,ec,area] for tech in Techs, enduse in enduses)

        @finite_math DemCCMult[ecc,area] = DemCC[ecc,area]/DemCCRef[ecc,area]

      end
    end
    WriteDisk(db,"SOutput/DemCC",year,DemCC)
    WriteDisk(db,"SOutput/DemCCMult",year,DemCCMult)

  end

end

function DSMPost(data::Data)
  #@debug "DSMPost Function Call"
end


function Control(data::Data)
  (; db,year) = data
  (; PI) = data
  (; ProcSw,SceName) = data
  
  #
  # Defining these locally for now, not sure if they are global
  # in current version - Ian 1/21/25
  #
  NonExist = -1
  Endogenous = 1
  PreCalc = 2

  PRReductions(data)
  
  # 
  # Avoiding 'pi' in Julia since it is a constant set to 3.14
  # 
  proc = Select(PI,"TPrice")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    TPrice(data)
    SequesteringEnergyPenalty(data)
  end

  SmoothEmissionCosts(data)
  AgeVintages(data)
  CapacityUtilization(data)
  #
  # Marginal Device Characteristics
  #
  proc = Select(PI,"DMarginal")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    DMarginal(data)
    MarginalCostOfFuelUsage(data)
  end
  #
  # Device DSM
  #
  proc = Select(PI,"DDSM")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    DDSM(data)
    MarginalCostOfFuelUsage(data)
  end
  #
  # Marginal Process Characteristics
  #
  proc = Select(PI,"CMarginal")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    CMarginal(data)
  end
  #
  # Process DSM
  #
  proc = Select(PI,"CDSM")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    CDSM(data)
  end
  #
  # # Cross-End-use Impacts
  #
  proc = Select(PI,"CImpact")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    CImpact(data)
  end
  #
  # Marginal Market Share
  #
  proc = Select(PI,"MShare")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    MShare(data)
  end
  #
  # Fuels System Market Share Option
  #
  proc = Select(PI,"FuelSystem")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    FuelSystem(data)
  end
  #
  # Marginal Stock Changes
  #
  proc = Select(PI,"MStock")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    EnduseSaturation(data)
    MarketShareAC(data)
    MStock(data)
  end
  #
  # Conversions and Replacements
  #
  proc = Select(PI,"Conversion")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    Conversion(data)
  end
  #
  # Device Dynamics
  #
  proc = Select(PI,"MStock")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    DeviceDynamics(data)
  end
  #
  # Device Retrofits
  #
  proc = Select(PI,"DRetrofit")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    DRetrofit(data)
  end
  #
  # Secondary Process and Production Capacity Dynamics
  #
  proc = Select(PI,"MStock")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    RCPCDynamics(data)
  end
  #
  # Process and Device Retrofits
  #
  IniRetrofits(data)
  proc = Select(PI,"PRetrofit")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    Retrofit(data)
  end
  #
  # Utilization DSM
  #
  proc = Select(PI,"Utilize")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    Utilize(data)
  end
  #
  # Total Stock Update
  #
  proc = Select(PI,"TStock")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    TStock(data)
  end
  #
  # Fungible Demand Dynamics
  #
  proc = Select(PI,"Fungible")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    DmFracMaxFromSupplyCurve(data)
    Fungible(data)
    FeedstockFungible(data)
  end
  #
  # Enduse Demands
  #
  proc = Select(PI,"DmdEnduse")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    DmdEnduse(data)
    EECalculation(data)
  end
  #
  SequesteringEnergyPenalty(data)
  #
  # DSM Accounting
  #
  proc = Select(PI,"DSMPost")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    DSMPost(data)
  end
  #
  # Enduse and Feedstock Demands
  #
  EnduseDemand(data)
  FeedstockDemand(data)
  #
  # Cogeneration
  #
  proc = Select(PI,"Cogeneration")
  if (ProcSw[proc] != NonExist) && (ProcSw[proc] != PreCalc)
    CogenerationSector(data)
  end

end

function RunAfterCogeneration(data::Data)
  #@debug "RunAfterCogeneration Function Call"
  CogenerationTotals(data)
  TotalDemand(data)
  SteamSalesPurchases(data)
  PollCoefficients(data)
  PollutionGenerated(data)
  SequesteringPotential(data)
  PRAccounting(data)
  Investments(data)

end

function EuPrices(data::Data)
  #@info " $ESKey Demand.jl, EuPrices"
  PRReductions(data)
  TPrice(data)
  SequesteringEnergyPenalty(data)
end



end
