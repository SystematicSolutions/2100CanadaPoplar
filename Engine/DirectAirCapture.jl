#
# DirectAirCapture.jl
#

module DirectAirCapture

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
  Yr2016 = 2016-ITime+1
  Yr2020 = 2020-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  DACTech::SetArray = ReadDisk(db,"SInput/DACTechKey")
  DACTechs::Vector{Int} = collect(Select(DACTech))
  Day::SetArray = ReadDisk(db,"MainDB/Day")
  Days::Vector{Int} = collect(Select(Day))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CgCap::VariableArray{3} = ReadDisk(db,"SOutput/CgCap",year) #[Fuel,ECC,Area,Year]  Cogeneration Capacity (MW)
  CgCapPrior::VariableArray{3} = ReadDisk(db,"SOutput/CgCap",prior) #[Fuel,ECC,Area,Prior]  Cogeneration Capacity (MW)
  CgGen::VariableArray{3} = ReadDisk(db,"SOutput/CgGen",year) #[Fuel,ECC,Area,Year]  Cogeneration Generation (GWh/Yr)
  CgInv::VariableArray{2} = ReadDisk(db,"SOutput/CgInv",year) #[ECC,Area,Year]  Cogeneration Investments (M$/Yr)
  
  DACBL::VariableArray{2} = ReadDisk(db,"SpInput/DACBL",year) # [DACTech,Area,Year] DAC Book Lifetime (Years)

  DACBuildFrac::VariableArray{1} = ReadDisk(db,"SpOutput/DACBuildFrac",year) #[Area,Year]  DAC Build Fraction (Tonnes/Tonnes)
  DACBuildFracMax::VariableArray{1} = ReadDisk(db,"SpInput/DACBuildFracMax",year) #[Area,Year]  Maximum DAC Build Fraction (Tonnes/Tonnes)
  DACCap::VariableArray{2} = ReadDisk(db,"SpOutput/DACCap",year) #[DACTech,Area,Year]  DAC Production Capacity (Tonnes/Yr)
  DACCapPrior::VariableArray{2} = ReadDisk(db,"SpOutput/DACCap",prior) #[DACTech,Area,Prior]  DAC Production Capacity (Tonnes/Yr)
  DACCapCR::VariableArray{2} = ReadDisk(db,"SpOutput/DACCapCR",year) #[DACTech,Area,Year]  DAC Production Capacity Completion Rate (Tonnes/Yr)
  DACCapI::VariableArray{2} = ReadDisk(db,"SpOutput/DACCapI",year) #[DACTech,Area,Year]  DAC Indicated Production Capacity (Tonnes/Yr)
  DACCapRR::VariableArray{2} = ReadDisk(db,"SpOutput/DACCapRR",year) #[DACTech,Area,Year]  DAC Production Capacity Retirement Rate (Tonnes/Yr)
  DACCC::VariableArray{2} = ReadDisk(db,"SpOutput/DACCC",year) #[DACTech,Area,Year]  DAC Production Capital Cost ($/Tonne)
  DACCCM::VariableArray{2} = ReadDisk(db,"SpInput/DACCCM",year) #[DACTech,Area,Year]  DAC Production Capital Cost Multiplier ($/$)
  DACCCN::VariableArray{2} = ReadDisk(db,"SpInput/DACCCN",year) #[DACTech,Area,Year]  DAC Production Capital Cost (Real $/Tonne)
  
  DACCCR::VariableArray{2} = ReadDisk(db,"SpOutput/DACCCR",year) #[DACTech,Area,Year]  DAC Production Capital Charge Rate ($/$)
  
  DACCD::Float32 = ReadDisk(db,"SpInput/DACCD",year) #[Year]  DAC Production Construction Delay (Years)
  DACCUF::VariableArray{2} = ReadDisk(db,"SpOutput/DACCUF",year) #[DACTech,Area,Year]  DAC Production Capacity Utilization Factor (Tonnes/Tonnes)
  DACCUFMax::VariableArray{1} = ReadDisk(db,"SpInput/DACCUFMax",year) #[Area,Year]  DAC Production Capacity Utilization Factor Maximum (Tonnes/Tonnes)
  DACCUFP::VariableArray{2} = ReadDisk(db,"SpInput/DACCUFP",year) #[DACTech,Area,Year]  DAC Production Capacity Utilization Factor for Planning (Tonnes/Tonnes)
  DACDem::VariableArray{1} = ReadDisk(db,"SpOutput/DACDem",year) #[Area,Year]  Demand for DAC (Tonnes/Yr)
  DACDemNation::VariableArray{1} = ReadDisk(db,"SpOutput/DACDemNation",year) #[Nation,Year]  Demand for DAC (Tonnes/Yr)
  DACDemand::VariableArray{3} = ReadDisk(db,"SpOutput/DACDemand",year) #[Fuel,DACTech,Area,Year]  DAC Production Energy Usage (Tonne/Yr)
  DACDemGR::VariableArray{1} = ReadDisk(db,"SpOutput/DACDemGR",year) #[Area,Year]  Area Demand for DAC Growth Rate (Tonnes/Tonnes)
  DACDemSm::VariableArray{1} = ReadDisk(db,"SpOutput/DACDemSm",year) #[Area,Year]  Demand for DAC Smoothed (Tonnes/Yr)
  DACDemSmPrior::VariableArray{1} = ReadDisk(db,"SpOutput/DACDemSmPrior",year) #[Area,Year]  Demand for DAC Smoothed for Previous Year (Tonnes/Yr)
  DACDmd::VariableArray{2} = ReadDisk(db,"SpOutput/DACDmd",year) #[DACTech,Area,Year]  DAC Production Energy Usage (TBtu/Yr)
  DACDmFrac::VariableArray{3} = ReadDisk(db,"SpInput/DACDmFrac",year) #[Fuel,DACTech,Area,Year]  DAC Production Energy Usage Fraction (Btu/Btu)
  DACECFP::VariableArray{2} = ReadDisk(db,"SpOutput/DACECFP",year) #[DACTech,Area,Year]  Fuel Prices for DAC Production ($/mmBtu)
  DACEff::VariableArray{2} = ReadDisk(db,"SpInput/DACEff",year) #[DACTech,Area,Year]  DAC Production Energy Efficiency (Tonnes/TBtu)
  DACEI::VariableArray{2} = ReadDisk(db,"SpOutput/DACEI",year) #[DACTech,Area,Year]  DAC Production GHG Emission Intensity (Tonnes/Tonnes)
  DACEIDmd::VariableArray{2} = ReadDisk(db,"SpOutput/DACEIDmd",year) #[DACTech,Area,Year]  DAC Production GHG Combustion Emission Intensity (Tonnes/Tonnes)
  DACEIDmdFuel::VariableArray{3} = ReadDisk(db,"SpOutput/DACEIDmdFuel",year) #[Fuel,DACTech,Area,Year]  DAC Production GHG Combustion Emission Intensity (Tonnes eCO2/TBtu)
  DACEmissionCost::VariableArray{2} = ReadDisk(db,"SpOutput/DACEmissionCost",year) #[DACTech,Area,Year]  DAC Emission Cost ($/Tonne)
  DACENPN::VariableArray{1} = ReadDisk(db,"SpOutput/DACENPN",year) #[Nation,Year]  DAC Wholesale Price ($/Tonne)
  DACENPNNext::VariableArray{1} = ReadDisk(db,"SpOutput/DACENPN",next) #[Nation,Year]  DAC Wholesale Price ($/Tonne)
  DACFOMCost::VariableArray{2} = ReadDisk(db,"SpOutput/DACFOMCost",year) #[DACTech,Area,Year]  DAC Production Fixed O&M Costs ($/Tonne)
  DACFPWholesale::VariableArray{1} = ReadDisk(db,"SpOutput/DACFPWholesale",year) #[Area,Year]  DAC Price ($/Tonne)
  DACFPWholesaleNext::VariableArray{1} = ReadDisk(db,"SpOutput/DACFPWholesale",next) #[Area,Year]  DAC Price ($/Tonne)
  DACFuelCost::VariableArray{2} = ReadDisk(db,"SpOutput/DACFuelCost",year) #[DACTech,Area,Year]  DAC Fuel Cost ($/Tonne)
  DACGridFraction::VariableArray{2} = ReadDisk(db,"SpInput/DACGridFraction",year) #[DACTech,Area,Year]  Fraction of Electric Demands Purchased from Grid (Btu/Btu)
  
  DACIVTC::VariableArray{1} = ReadDisk(db,"SpInput/DACIVTC",year) #[Area,Year]  DAC Investment Tax Credit ($/$)
  
  DACLSF::VariableArray{5} = ReadDisk(db,"SCalDB/DACLSF") #[DACTech,Hour,Day,Month,Area]  DAC Production Load Shape (MW/MW)
  DACMCE::VariableArray{2} = ReadDisk(db,"SpOutput/DACMCE",year) #[DACTech,Area,Year]  DAC Levelized Marginal Cost ($/Tonne)
  DACMCENext::VariableArray{2} = ReadDisk(db,"SpOutput/DACMCE",next) #[DACTech,Area,Year]  DAC Levelized Marginal Cost ($/Tonne)
  DACMCEPrior::VariableArray{2} = ReadDisk(db,"SpOutput/DACMCE",prior) #[DACTech,Area,Year]  DAC Levelized Marginal Cost ($/Tonne)
  DACMCE0::VariableArray{2} = ReadDisk(db,"SpOutput/DACMCE",Yr2020) #[DACTech,Area]  DAC Levelized Marginal Cost ($/Tonne)
  DACMSF::VariableArray{2} = ReadDisk(db,"SpOutput/DACMSF",year) #[DACTech,Area,Year]  DAC Market Share (Tonnes/Tonnes)
  DACMSFSwitch::VariableArray{1} = ReadDisk(db,"SpInput/DACMSFSwitch",year) #[Area,Year]  DAC Market Share Non-Price Factor (Tonnes/Tonnes)
  DACMSM0::VariableArray{2} = ReadDisk(db,"SpInput/DACMSM0",year) #[DACTech,Area,Year]  DAC Market Share Non-Price Factor (Tonnes/Tonnes)
  DACOF::VariableArray{2} = ReadDisk(db,"SpInput/DACOF",year) #[DACTech,Area,Year]  DAC Production O&M Cost Factor (Real $/$/Yr)
  DACPriceDiff::VariableArray{1} = ReadDisk(db,"SpOutput/DACPriceDiff") # [Area,Year]  Percent Difference between DAC Price and Carbon Price (Tonnes/Tonnes)
  DACPriceDiffFrac::VariableArray{1} = ReadDisk(db,"SpInput/DACPriceDiffFrac",year) #[Area,Year]  Fraction of the DAC/CO2 Price Difference Used for Target (Tonnes/Tonnes)
  DACPL::VariableArray{1} = ReadDisk(db,"SpInput/DACPL",year) #[DACTech,Year]  DAC Production Physical Lifetime (Years)
  DACPlantMap::VariableArray{4} = ReadDisk(db,"SpInput/DACPlantMap") #[DACTech,Plant,Power,Area]  DAC Process to Plant Type Map
  DACPOCX::VariableArray{3} = ReadDisk(db,"SpInput/DACPOCX",year) #[FuelEP,Poll,Area,Year]  DAC Pollution Coefficient (Tonnes/TBtu)
  DACPol::VariableArray{4} = ReadDisk(db,"SpOutput/DACPol",year) #[FuelEP,DACTech,Poll,Area,Year]  DAC Production Combustion Emissions (Tonnes/Yr)
  DACPolPrior::VariableArray{4} = ReadDisk(db,"SpOutput/DACPol",prior) #[FuelEP,DACTech,Poll,Area,Prior]  DAC Production Combustion Emissions (Tonnes/Yr)
  DACPolNet::VariableArray{1} = ReadDisk(db,"SpOutput/DACPolNet",year) #[Area,Year]  Net GHG Emissions from DAC Production (eCO2 Tonnes/Yr)
  DACPolNetPrior::VariableArray{1} = ReadDisk(db,"SpOutput/DACPolNet",prior) #[Area,Prior]  Net GHG Emissions from DAC Production (eCO2 Tonnes/Yr)
  DACPolNetPriorNation::VariableArray{1} = zeros(Float32,length(Nation)) # DAC Production (Tonnes/Yr)
  DACProd::VariableArray{2} = ReadDisk(db,"SpOutput/DACProd",year) #[DACTech,Area,Year]  DAC Production (Tonnes/Yr)
  DACProdPrior::VariableArray{2} = ReadDisk(db,"SpOutput/DACProd",prior) #[DACTech,Area,Prior]  DAC Production (Tonnes/Yr)
  DACProdNation::VariableArray{1} = ReadDisk(db,"SpOutput/DACProdNation",year) #[Nation,Year]  DAC Production (Tonnes/Yr)
  DACProdNationPrior::VariableArray{1} = ReadDisk(db,"SpOutput/DACProdNation",prior) #[Nation,Prior]  DAC Production (Tonnes/Yr)
  DACProdTarget::VariableArray{1} = ReadDisk(db,"SpOutput/DACProdTarget",year) #[Area,Year]  DAC Production Target (Tonnes/Yr)
  DACProduction::VariableArray{1} = ReadDisk(db,"SOutput/DACProduction",year) #[Area,Year]  DAC Production (eCO2 Tonnes/Yr)
  DACProductionPrior::VariableArray{1} = ReadDisk(db,"SOutput/DACProduction",prior) #[Area,Prior]  DAC Production (eCO2 Tonnes/Yr)
  
  DACROIN::VariableArray{2} = ReadDisk(db,"SpInput/DACROIN",year) #[DACTech,Area,Year]  DAC Return on Investment ($/$)
  
  DACSaEC::VariableArray{2} = ReadDisk(db,"SpOutput/DACSaEC",year) #[DACTech,Area,Year]  Electric Sales to DAC (GWh/Yr)
  DACSmT::Float32 = ReadDisk(db,"SpInput/DACSmT",year) #[Year]  DAC Production Growth Rate Smoothing Time (Years)
  DACSqFr::VariableArray{3} = ReadDisk(db,"SpInput/DACSqFr",year) #[DACTech,Poll,Area,Year]  DAC Sequestered Pollution Fraction (Tonnes/Tonnes)
  DACSqDemand::VariableArray{3} = ReadDisk(db,"SpOutput/DACSqDemand",year) #[Fuel,DACTech,Area,Year]  DAC Sequestering Energy Usage (TBtu/Yr)
  DACSqEI::VariableArray{2} = ReadDisk(db,"SpOutput/DACSqEI",year) #[DACTech,Area,Year]  DAC Production Sequester GHG Emission Intensity (Tonnes eCO2/Tonne DAC)
  DACSqEIDmd::VariableArray{2} = ReadDisk(db,"SpOutput/DACSqEIDmd",year) #[DACTech,Area,Year]  DAC Production Sequester GHG Combustion Emission Intensity (Tonnes eCO2/Tonne DAC)
  DACSqEIDmdFuel::VariableArray{3} = ReadDisk(db,"SpOutput/DACSqEIDmdFuel",year) #[Fuel,DACTech,Area,Year]  DAC Production Sequester GHG Combustion Emission Intensity (Tonnes eCO2/TBtu)
  DACSqPenalty::VariableArray{3} = ReadDisk(db,"SpInput/DACSqPenalty",year) #[DACTech,Poll,Area,Year]  DAC Sequestering Energy Penalty (TBtu/Tonne)
  DACSqPol::VariableArray{3} = ReadDisk(db,"SpOutput/DACSqPol",year) #[DACTech,Poll,Area,Year]  DAC Sequestering Emissions (Tonnes/Yr)
  DACSqPolPrior::VariableArray{3} = ReadDisk(db,"SpOutput/DACSqPol",prior) #[DACTech,Poll,Area,Prior]  DAC Sequestering Emissions (Tonnes/Yr)
  DACSqPolPenalty::VariableArray{3} = ReadDisk(db,"SpOutput/DACSqPolPenalty",year) #[DACTech,Poll,Area,Year]  DAC Sequestering Emissions Penalty (Tonnes/Yr)
  DACSqTransStorageCost::VariableArray{2} = ReadDisk(db,"SpOutput/DACSqTransStorageCost",year) #[DACTech,Area,Year]  Sequestering Transportation and Storage Costs ($/Tonne)
  DACSubsidy::VariableArray{1} = ReadDisk(db,"SpInput/DACSubsidy",year) #[Area,Year]  DAC Production Subsidy ($/Tonne)
  DACSw::VariableArray{1} = ReadDisk(db,"SpInput/DACSw",year) #[Area,Year]  Switch to Determine DAC Target

  DACTL::VariableArray{2} = ReadDisk(db,"SpInput/DACTL",year) #[DACTech,Area,Year]  DAC Tax Lifetime (Years)
  
  DACTrans::VariableArray{2} = ReadDisk(db,"SpInput/DACTrans",year) #[DACTech,Area,Year]  DAC Incremental Transmission Cost (Real $/Tonne)
  DACTransCost::VariableArray{2} = ReadDisk(db,"SpOutput/DACTransCost",year) #[DACTech,Area,Year]  DAC Transmission Costs ($/Tonne)
  
  DACTxRt::VariableArray{1} = ReadDisk(db,"SpInput/DACTxRt",year) #[Area,Year]  DAC Tax Rate ($/$)
  
  DACUOMC::VariableArray{2} = ReadDisk(db,"SpInput/DACUOMC",year) #[DACTech,Area,Year]  DAC Production Variable O&M Costs (Real $/Tonne)
  DACVC::VariableArray{2} = ReadDisk(db,"SpOutput/DACVC",year) #[DACTech,Area,Year]  DAC Variable Cost ($/Tonne)
  DACVF::VariableArray{2} = ReadDisk(db,"SpInput/DACVF",year) #[DACTech,Area,Year]  DAC Market Share Variance Factor (Tonnes/Tonnes)
  DACVOMCost::VariableArray{2} = ReadDisk(db,"SpOutput/DACVOMCost",year) #[DACTech,Area,Year]  DAC Production Variable O&M Costs ($/Tonne)
  DACWeight::VariableArray{1} = ReadDisk(db,"SpInput/DACWeight",year) #[Area,Year]  Weight of Areas for DACCS Backcasting (unit/unit)
  DACWeightTotal::VariableArray{1} = zeros(Float32,length(Nation)) # Total of DACWeight
  DInv::VariableArray{2} = ReadDisk(db,"SOutput/DInv",year) #[ECC,Area,Year]  Device Investments (M$/Yr)
  DOMExp::VariableArray{2} = ReadDisk(db,"SOutput/DOMExp",year) #[ECC,Area,Year]  Device O&M Expenditures (M$)
  eCO2Price::VariableArray{1} = ReadDisk(db,"SOutput/eCO2Price",year) #[Area,Year]  Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ECoverage::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) #[ECC,Poll,PCov,Area,Year]  Emissions Permit Coverage (Tonnes/Tonnes)
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  EISector::VariableArray{2} = ReadDisk(db,"SOutput/EISector",year) #[ECC,Area,Year]  Sector Emission Intensity (Tonnes/TBtu)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Enduse Energy Pollution with Cogeneration (Tonnes/Yr)
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  EuPol::VariableArray{3} = ReadDisk(db,"SOutput/EuPol",year) #[ECC,Poll,Area,Year]  Enduse Energy Related Pollution (Tonnes/Yr)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Enduse Energy Demands (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") #[Fuel,Plant]  Fuel/Plant Map
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FPBaseF::VariableArray{3} = ReadDisk(db,"SOutput/FPBaseF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price without Taxes ($/mmBtu)
  FPDChgF::VariableArray{3} = ReadDisk(db,"SCalDB/FPDChgF",year) #[Fuel,ES,Area,Year]  Fuel Delivery Charge (Real $/mmBtu)
  FPMarginF::VariableArray{3} = ReadDisk(db,"SInput/FPMarginF",year) #[Fuel,ES,Area,Year]  Refinery/Distributor Margin ($/$)
  FPPolTaxF::VariableArray{3} = ReadDisk(db,"SOutput/FPPolTaxF",year) #[Fuel,ES,Area,Year]  Pollution Tax (Real $/mmBtu)
  FPSMF::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",year) #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPTaxF::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",year) #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  FuelExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/FuelExpenditures",year) #[ECC,Area,Year]  Fuel Expenditures (M$)
  GCCC::VariableArray{2} = ReadDisk(db,"EGOutput/GCCC",year) #[Plant,Area,Year]  Overnight Construction Costs ($/KW)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") #[Area,Year]  Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") #[Nation,Year]  Inflation Index ($/$)
  
  InSm::VariableArray{1} = ReadDisk(db,"MOutput/InSm",year) #[Area,Year] Smoothed Inflation Rate ($/Yr/$) 
  
  LDCECC::VariableArray{5} = ReadDisk(db,"SOutput/LDCECC",year) #[ECC,Hour,Day,Month,Area,Year]  Electric Loads Dispatched (MW)
  LUPol::VariableArray{2} = ReadDisk(db,"MEOutput/LUPol",year) #[Poll,Area,Year]  Land Use Pollution (Tonnes)
  MCE::VariableArray{3} = ReadDisk(db,"EOutput/MCE",year) #[Plant,Power,Area,Year]  Cost of Energy from New Capacity ($/MWh)
  NcFPol::VariableArray{4} = ReadDisk(db,"SOutput/NcFPol",year) #[Fuel,ECC,Poll,Area,Year]  Non Combustion Related Pollution (Tonnes/Yr)
  NcPol::VariableArray{3} = ReadDisk(db,"SOutput/NcPol",year) #[ECC,Poll,Area,Year]  Non Combustion Related Pollution (Tonnes/Yr)
  OMExp::VariableArray{2} = ReadDisk(db,"SOutput/OMExp",year) #[ECC,Area,Year]  O&M Expenditures (M$)
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost (Real $/Tonnes)
  PInv::VariableArray{2} = ReadDisk(db,"SOutput/PInv",year) #[ECC,Area,Year]  Process Investments (M$/Yr)
  PolAfterDAC::VariableArray{1} = ReadDisk(db,"SOutput/PolAfterDAC",year) #[Area,Year]  GHG Emissions After DAC (eCO2 Tonnes/Yr)
  PolBeforeDAC::VariableArray{1} = ReadDisk(db,"SOutput/PolBeforeDAC",year) #[Area,Year]  GHG Emissions Before DAC (eCO2 Tonnes/Yr)
  PolBeforeDACNation::VariableArray{1} = zeros(Float32,length(Nation)) # GHG Emissions Before DAC (eCO2 Tonnes/Yr)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  PolGoal::VariableArray{1} = ReadDisk(db,"SOutput/PolGoal",year) #[Area,Year]  Emissions Goal (eCO2 Tonne/Yr)
  PolGoalNation::VariableArray{1} = ReadDisk(db,"SOutput/PolGoalNation",year) #[Nation,Year]  Emissions Goal (eCO2 Tonne/Yr)
  POMExp::VariableArray{2} = ReadDisk(db,"SOutput/POMExp",year) #[ECC,Area,Year]  Process O&M Expenditures (M$)
  SaEC::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",year) #[ECC,Area,Year]  Electricity Sales (GWh/Yr)
  SqPolCCNet::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCNet",year) #[ECC,Poll,Area,Year]  Sequestering Cost Curve Net Emissions (Tonnes/Yr)
  SqPolPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolPenalty",year) #[ECC,Poll,Area,Year]  Sequestering Emissions Penalty (Tonnes/Yr)

  SqTSCost::VariableArray{1} = ReadDisk(db,"MEOutput/SqTSCost",year) #[Area,Year]  Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e)  
  
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)
  TotDemandPrior::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",prior) #[Fuel,ECC,Area,Prior]  Energy Demands (TBtu/Yr)
 
  TotPolPrior::VariableArray{3} = ReadDisk(db,"SOutput/TotPol",prior) #[ECC,Poll,Area,Year]  Pollution (Tonnes/Yr)
  
  xDACDem::VariableArray{1} = ReadDisk(db,"SpInput/xDACDem",year) #[Area,Year]  Exogenous Demand for DAC (Tonnes/Yr)
  xDACENPN::VariableArray{1} = ReadDisk(db,"SpInput/xDACENPN",year) #[Nation,Year]  Exogenous DAC Wholesale Price (Real $/Tonne)
  xDACENPNNext::VariableArray{1} = ReadDisk(db,"SpInput/xDACENPN",next) #[Nation,Year]  Exogenous DAC Wholesale Price (Real $/Tonne)
  xENPN::VariableArray{2} = ReadDisk(db,"SInput/xENPN",year) #[Fuel,Nation,Year]  Exogenous Price Normal (Real $/mmBtu)
  xDACMSF::VariableArray{2} = ReadDisk(db,"SpInput/xDACMSF",year) #[DACTech,Area,Year]  DAC Exogenous Market Share (Tonnes/Tonnes)
  xPolGoal::VariableArray{1} = ReadDisk(db,"SInput/xPolGoal",year) #[Area,Year]  Exogenous Emissions Goal (eCO2 Tonnes/Yr)
  xPolGoalNation::VariableArray{1} = ReadDisk(db,"SInput/xPolGoalNation",year) #[Nation,Year]  Exogenous Emissions Goal (Tonne/Yr)
  ZeroFr::VariableArray{3} = ReadDisk(db,"SInput/ZeroFr",year) #[FuelEP,Poll,Area,Year]  Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)

  #
  # Scratch Variables
  #
  CgCC::VariableArray{2} = zeros(Float32,length(Fuel),length(Area))  # Cogeneration Capacity (MW)
  DACMAW::VariableArray{2} = zeros(Float32,length(DACTech),length(Area)) # DAC Market Share Allocation Weight (Tonnes/Tonnes)
  DACSqDmd::VariableArray{2} = zeros(Float32,length(DACTech),length(Area))  # DAC Sequestering Energy Usage (TBtu/Yr)
  DACSqDmdFuelEP::VariableArray{3} = zeros(Float32,length(FuelEP),length(DACTech),length(Area))  # DAC Sequestering Energy Usage (TBtu/Yr)'
end

function EmissionsBeforeDAC(data::Data)
  (; db,year) = data
  (; Areas,ECC,Poll) = data #sets
  (; LUPol,PolConv,PolBeforeDAC,TotPolPrior) = data

  # @info "  DirectAirCapture.jl - EmissionsBeforeDAC"

  #   Define Procedure EmissionsBeforeDAC
  # 
  ghgpolls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
  daccseccs_1 = Select(ECC, !=("ForeignPassenger"))
  daccseccs_2 = Select(ECC, !=("ForeignFreight"))
  daccseccs_3 = Select(ECC, !=("LandUse"))
  daccseccs = intersect(daccseccs_1,daccseccs_2,daccseccs_3)

  for area in Areas
    PolBeforeDAC[area] = sum(TotPolPrior[ecc,poll,area]*
      PolConv[poll] for poll in ghgpolls, ecc in daccseccs)

    PolBeforeDAC[area] = PolBeforeDAC[area]+sum(LUPol[poll,area]*
      PolConv[poll] for poll in ghgpolls)
  end

  WriteDisk(db,"SOutput/PolBeforeDAC",year,PolBeforeDAC)

end

function NationalGoal(data::Data)
  (; db,year) = data
  (; Nations) = data #sets
  (; ANMap,DACDemNation,DACPolNetPrior,DACPolNetPriorNation) = data
  (; DACSw,DACWeight,DACWeightTotal,PolBeforeDAC) = data
  (; PolBeforeDACNation,PolGoal,PolGoalNation,xPolGoalNation) = data

  # @info "  DirectAirCapture.jl - NationalGoal"
  
  #
  # Note: only used for DACSw = 3, but needs to be calculated outside 
  # of "Do Area" loop.  Get the value from the first area
  #

  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    areafirst = first(areas)
    if DACSw[areafirst] .== 3
    
      PolGoalNation[nation] = xPolGoalNation[nation]
      PolBeforeDACNation[nation] = sum(PolBeforeDAC[area] for area in areas)
      DACPolNetPriorNation[nation] = sum(DACPolNetPrior[area] for area in areas)
      
      DACDemNation[nation] = max(PolBeforeDACNation[nation]+
                             DACPolNetPriorNation[nation]-PolGoalNation[nation],0.0)
                             
      DACWeightTotal[nation] = sum(DACWeight[area] for area in areas)
      
      for area in areas
        PolGoal[area] = PolGoalNation[nation]*DACWeight[area]
      end
      
    end
  end

  WriteDisk(db,"SOutput/PolGoal",year,PolGoal)
  WriteDisk(db,"SOutput/PolGoalNation",year,PolGoalNation)
  WriteDisk(db,"SpOutput/DACDemNation",year,DACDemNation)

end

function Demands(data::Data)
  (; db,year) = data
  (; Nations) = data #sets
  (; ANMap,DACBuildFrac,DACBuildFracMax,DACDem,DACDemNation) = data
  (; DACFPWholesale,DACPolNetPrior,DACPriceDiff,DACPriceDiffFrac) = data
  (; DACProductionPrior,DACSw,DACWeight,DACWeightTotal,eCO2Price) = data
  (; PolBeforeDAC,PolGoal,xDACDem,xPolGoal) = data

  # @info "  DirectAirCapture.jl - Demands"

  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas

      if DACSw[area] == 1
        #
        # DAC meets emission Goal
        #
        PolGoal[area] = xPolGoal[area]
        DACDem[area] = max(PolBeforeDAC[area]+DACPolNetPrior[area]-PolGoal[area],0.0)

      elseif DACSw[area] == 2
        #
        # DAC meets emission Goal or produces to exogenous level
        #
        PolGoal[area] = xPolGoal[area]
        DACDem[area] = max(PolBeforeDAC[area]+DACPolNetPrior[area]-PolGoal[area],0.0)
        DACDem[area] = max(DACDem[area],xDACDem[area],0.0)

      #
      # DAC meets national Goal, with production split by exogenous weights
      #
      elseif DACSw[area] == 3
        DACDem[area] = PolGoal[area]
        DACDem[area] = DACDemNation[nation]*DACWeight[area]

      #
      # DAC response to Carbon Price
      #
      elseif DACSw[area] == 4
        @finite_math DACPriceDiff[area] = (DACFPWholesale[area]-eCO2Price[area])/
                           eCO2Price[area]
        DACBuildFrac[area] = min(max(DACPriceDiff[area]*DACPriceDiffFrac[area],0),
                           DACBuildFracMax[area])
        DACDem[area] = min(PolBeforeDAC[area]*DACBuildFrac[area],
                           max(DACProductionPrior[area]*0.10,PolBeforeDAC[area]*0.01))
        PolGoal[area] = DACDem[area]
        
      #
      # Exogenous
      #
      elseif DACSw[area] == 0
        DACDem[area] = xDACDem[area]
        PolGoal[area] = DACDem[area]
      end

    end
  end

  WriteDisk(db,"SOutput/PolGoal",year,PolGoal)
  WriteDisk(db,"SpOutput/DACDem",year,DACDem)
end

function DemandGrowthRate(data::Data)
  (; db,year) = data
  (; Areas) = data #sets
  (; DACDemSm,DACDemSmPrior,DACDem) = data
  (; DACDemSmPrior,DACSmT,DACDemGR) = data

  # @info "  DirectAirCapture.jl - DemandGrowthRate"

  for area in Areas
    @finite_math DACDemSm[area] = 
      DACDemSmPrior[area]+(DACDem[area]-DACDemSmPrior[area])/DACSmT
    @finite_math DACDemGR[area] = (DACDem[area]/DACDemSm[area]-1)/DACSmT
  end

  WriteDisk(db,"SpOutput/DACDemSm",year,DACDemSm)
  WriteDisk(db,"SpOutput/DACDemGR",year,DACDemGR)

end

function ProductionTarget(data::Data)
  (; db,year) = data
  (; Areas) = data #sets
  (; DACCD,DACDem,DACDemGR,DACProdTarget) = data

  # @info "  DirectAirCapture.jl - ProductionTarget"

  for area in Areas
    DACProdTarget[area] = DACDem[area]*(1+DACDemGR[area]*max(1.00,DACCD/2))
  end

  WriteDisk(db,"SpOutput/DACProdTarget",year,DACProdTarget)

end

function FuelPrices(data::Data)
  (; db,year,current) = data
  (; Areas,DACTechs,ES,Fuels) = data #sets
  (; DACDmFrac,DACECFP,FPF,Inflation) = data

  # @info "  DirectAirCapture.jl - FuelPrices"

  es = Select(ES,"Industrial")

  for area in Areas, dactech in DACTechs
    DACECFP[dactech,area] = sum(FPF[fuel,es,area]*
      DACDmFrac[fuel,dactech,area] for fuel in Fuels)
    DACECFP[dactech,area] = min(DACECFP[dactech,area],250*Inflation[area,current])
  end

  WriteDisk(db,"SpOutput/DACECFP",year,DACECFP)

end

function CapitalCosts(data::Data)
  (; db,year,current) = data
  (; Areas,DACTechs) = data #sets
  (; DACCC,DACCCM,DACCCN,Inflation) = data

  # @info "  DirectAirCapture.jl - CapitalCosts"

  for area in Areas, dactech in DACTechs
    DACCC[dactech,area] = DACCCN[dactech,area]DACCCM[dactech,area]*
                          Inflation[area,current]
  end

  WriteDisk(db,"SpOutput/DACCC",year,DACCC)

end


function CapitalChargeRate(data::Data)
  (; db,year,current) = data
  (; Areas,DACTechs) = data
  (; DACBL,DACCCR,DACIVTC,DACROIN,DACTL,DACTxRt,InSm) = data

  for area in Areas, dactech in DACTechs

    @finite_math DACCCR[dactech,area] =
      (1-DACIVTC[area]/(1+DACROIN[dactech,area]+InSm[area])-
       DACTxRt[area]*(2/DACTL[dactech,area])/
      (DACROIN[dactech,area]+InSm[area]+2/DACTL[dactech,area]))*DACROIN[dactech,area]/
      (1-(1/(1+DACROIN[dactech,area]))^DACBL[dactech,area])/(1-DACTxRt[area]) 
   
  end
      
  WriteDisk(db,"SpOutput/DACCCR",year,DACCCR)      

end

function GHGEmissionIntensity(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,ECC,Fuel,Fuels,FuelEPs,Poll) = data #sets
  (; DACEI,DACEIDmd,DACSqEI,DACSqEIDmd,DACEIDmdFuel) = data
  (; DACSqEIDmdFuel,DACDmFrac,DACEff,EISector,PolConv) = data
  (; DACSqFr,DACPOCX,ZeroFr,FFPMap) = data

  # @info "  DirectAirCapture.jl - GHGEmissionIntensity"

  for area in Areas, dactech in DACTechs, fuel in Select(Fuel,!=("Electric")), fuelep in FuelEPs
    if FFPMap[fuelep,fuel] == 1
      ghgpolls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
      DACEIDmdFuel[fuel,dactech,area] = sum(DACPOCX[fuelep,poll,area]*
        (1-ZeroFr[fuelep,poll,area]-DACSqFr[dactech,poll,area])*
        PolConv[poll] for poll in ghgpolls)
      co2poll = Select(Poll,"CO2")
      DACSqEIDmdFuel[fuel,dactech,area] = DACPOCX[dactech,co2poll,area]*
                                        DACSqFr[dactech,co2poll,area]*PolConv[co2poll]
    else
      utilitygen = Select(ECC,"UtilityGen")
      DACEIDmdFuel[fuel,dactech,area] = EISector[utilitygen,area]
      DACSqEIDmdFuel[fuel,dactech,area] = 0.00
    end
  end

  WriteDisk(db,"SpOutput/DACEIDmdFuel",year,DACEIDmdFuel)
  WriteDisk(db,"SpOutput/DACSqEIDmdFuel",year,DACSqEIDmdFuel)


  for area in Areas, dactech in DACTechs
    @finite_math DACEIDmd[dactech,area] = sum(DACEIDmdFuel[fuel,dactech,area]*
      DACDmFrac[fuel,dactech,area] for fuel in Fuels)/DACEff[dactech,area]
  end

  WriteDisk(db,"SpOutput/DACEIDmd",year,DACEIDmd)

  for area in Areas, dactech in DACTechs
    @finite_math DACSqEIDmd[dactech,area] = sum(DACSqEIDmdFuel[fuel,dactech,area]*
                             DACDmFrac[fuel,dactech,area] for fuel in Fuels)/DACEff[dactech,area]
  end

  #
  # Emission Intensity
  #
  for area in Areas, dactech in DACTechs
    DACEI[dactech,area] = DACEIDmd[dactech,area]
  end

  WriteDisk(db,"SpOutput/DACEIDmd",year,DACEIDmd)

  for area in Areas, dactech in DACTechs
    DACSqEI[dactech,area] = DACSqEIDmd[dactech,area]
  end

  WriteDisk(db,"SpOutput/DACSqEI",year,DACSqEI)
end

function EmissionCosts(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,ECC,PCov,Poll) = data #sets
  (; DACEIDmd,DACEmissionCost,ECoverage,PCost) = data

  # @info "  DirectAirCapture.jl - EmissionCosts"

  ecc = Select(ECC,"DirectAirCapture")
  poll = Select(Poll,"CO2")
  pcov = Select(PCov,"Energy")

  for area in Areas, dactech in DACTechs
    DACEmissionCost[dactech,area] = DACEIDmd[dactech,area]*
      PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]/1E6
  end

  WriteDisk(db,"SpOutput/DACEmissionCost",year,DACEmissionCost)
end

function MarginalCost(data::Data)
  (; db,year,current,Yr2016) = data
  (; Areas,DACTechs) = data #sets
  (; DACCC,DACCCR,DACCUFP,DACECFP,DACEff,DACEmissionCost) = data
  (; DACFOMCost,DACFuelCost,DACMCE,DACOF,DACSqEI) = data
  (; DACSqTransStorageCost,DACTransCost,DACUOMC) = data
  (; DACVC,DACVOMCost,Inflation,SqTSCost) = data

  # @info "  DirectAirCapture.jl - MarginalCost"

  for area in Areas, dactech in DACTechs
    @finite_math DACFuelCost[dactech,area] = 
      DACECFP[dactech,area]/DACEff[dactech,area]/1e6
    DACVOMCost[dactech,area] = DACUOMC[dactech,area]*Inflation[area,current]
    DACFOMCost[dactech,area] = DACCC[dactech,area]*DACOF[dactech,area]

    #
    #  DACTransCost=DACTrans*Inflation
    #
    @finite_math DACTransCost[dactech,area] = SqTSCost[area]/
      Inflation[area,Yr2016]*Inflation[area,current]
      
    @finite_math DACSqTransStorageCost[dactech,area] = DACSqEI[dactech,area]*
      SqTSCost[area]/Inflation[area,Yr2016]*Inflation[area,current]/1e6
  end

  WriteDisk(db,"SpOutput/DACFOMCost",year,DACFOMCost)
  WriteDisk(db,"SpOutput/DACFuelCost",year,DACFuelCost)
  WriteDisk(db,"SpOutput/DACTransCost",year,DACTransCost)
  WriteDisk(db,"SpOutput/DACSqTransStorageCost",year,DACSqTransStorageCost)
  WriteDisk(db,"SpOutput/DACVOMCost",year,DACVOMCost)

  for area in Areas, dactech in DACTechs
    DACVC[dactech,area] = DACFuelCost[dactech,area]+DACEmissionCost[dactech,area]+
      DACVOMCost[dactech,area]+DACTransCost[dactech,area]+
      DACSqTransStorageCost[dactech,area]
    @finite_math DACMCE[dactech,area] = (DACCCR[dactech,area]*DACCC[dactech,area]+
      DACFOMCost[dactech,area])/DACCUFP[dactech,area]+DACVC[dactech,area]
  end

  WriteDisk(db,"SpOutput/DACMCE",year,DACMCE)
  WriteDisk(db,"SpOutput/DACVC",year,DACVC)

end

function MarketShare(data::Data)
  (; db,year) = data
  (; Area,Areas,DACTech,DACTechs) = data #sets
  (; DACMCE,DACMSF,DACMSFSwitch,DACMSM0,DACVF,xDACMSF) = data
  (; DACMAW) = data
  DACMCEMin::VariableArray{1} = zeros(Float32,length(Area)) # Minimum DAC Levelized Marginal Cost ($/Tonne)
  DACTAW::VariableArray{1} = zeros(Float32,length(Area)) # DAC Market Share Total Allocation Weight (Tonnes/Tonnes)
  # @info "  DirectAirCapture.jl - MarketShare"

  #
  # Trap so DACMCE is positive
  #
  for area in Areas, dactech in DACTechs
    DACMCE[dactech,area] = max(DACMCE[dactech,area],1.00)
  end

  nonothertechs = Select(DACTech, !=("Other"))
  for area in Areas
    DACMCEMin[area] = minimum(DACMCE[dactech,area] for dactech in nonothertechs)
  end

  for area in Areas, dactech in DACTechs
    @finite_math DACMAW[dactech,area] = exp(DACMSM0[dactech,area]+DACVF[dactech,area]*
      log(DACMCE[dactech,area]/DACMCEMin[area]))
  end

  for area in Areas
    DACTAW[area] = sum(DACMAW[dactech,area] for dactech in DACTechs)
  end

  for area in Areas, dactech in DACTechs
    @finite_math DACMSF[dactech,area] = DACMAW[dactech,area]/DACTAW[area]

    if DACMSFSwitch[area] == 0
      DACMSF[dactech,area] = xDACMSF[dactech,area]
    end
  end

  WriteDisk(db,"SpOutput/DACMSF",year,DACMSF)

end

function CapacityIndicated(data::Data)
  (; db,year) = data
  (; Areas,DACTechs) = data #sets
  (; DACCapI,DACCUFP,DACMSF,DACProdTarget) = data

  # @info "  DirectAirCapture.jl - CapacityIndicated"

  for area in Areas, dactech in DACTechs
    @finite_math DACCapI[dactech,area] = DACProdTarget[area]*DACMSF[dactech,area]/
      DACCUFP[dactech,area]
  end

  WriteDisk(db,"SpOutput/DACCapI",year,DACCapI)

end

function CapacityRetirementRate(data::Data)
  (; db,year) = data
  (; Areas,DACTechs) = data #sets
  (; DACCapPrior,DACCapRR,DACPL) = data

  # @info "  DirectAirCapture.jl - CapacityRetirementRate"

  for area in Areas, dactech in DACTechs
    @finite_math DACCapRR[dactech,area] = DACCapPrior[dactech,area]/DACPL[dactech]
  end

  WriteDisk(db,"SpOutput/DACCapRR",year,DACCapRR)
end

function CapacityCompletionRate(data::Data)
  (; db,year) = data
  (; Areas,DACTechs) = data #sets
  (; DACCapCR,DACCapI,DACCapPrior,DACCapRR,DACCD) = data

  # @info "  DirectAirCapture.jl - CapacityCompletionRate"

  for area in Areas, dactech in DACTechs
    @finite_math DACCapCR[dactech,area] = max(0,DACCapI[dactech,area]-
      DACCapPrior[dactech,area]+DACCapRR[dactech,area])/DACCD
  end

  WriteDisk(db,"SpOutput/DACCapCR",year,DACCapCR)


end

function ProductionCapacity(data::Data)
  (; db,year) = data
  (; Areas,DACTechs) = data #sets
  (; DACCap,DACCapCR,DACCapPrior,DACCapRR) = data

  # @info "  DirectAirCapture.jl - ProductionCapacity"

  for area in Areas, dactech in DACTechs
    DACCap[dactech,area] = DACCapPrior[dactech,area]+DT*(DACCapCR[dactech,area]-
                           DACCapRR[dactech,area])
  end

  WriteDisk(db,"SpOutput/DACCap",year,DACCap)
end

function Production(data::Data)
  (; db,year) = data
  (; Area,Areas,DACTechs,Nations) = data #sets
  (; ANMap,DACCap,DACCUF,DACDem,DACProd,DACProdNation,DACProduction) = data
  DACCapTotal::VariableArray{1} = zeros(Float32,length(Area)) # DAC Production Total Capacity (Tonnes/Yr)

  # @info "  DirectAirCapture.jl - Production"

  for area in Areas
    DACCapTotal[area] = sum(DACCap[dactech,area] for dactech in DACTechs)
    # DACCapTotal[area] = sum(DACTech)(DACCap[dactech,area]*DACCUFP[dactech,area])
  end

  for area in Areas, dactech in DACTechs
    @finite_math DACProd[dactech,area] = DACCap[dactech,area]*DACDem[area]/
      DACCapTotal[area]
    #
    # DACProd = min(DACCap*DACCUFP*DACDem/DACCapTotal,DACCap*DACCUFMax)
    #
    @finite_math DACCUF[dactech,area] = DACProd[dactech,area]/DACCap[dactech,area]
  end

  for area in Areas
    DACProduction[area] = sum(DACProd[dactech,area] for dactech in DACTechs)
  end

  for nation in Nations
    DACProdNation[nation] = sum(DACProd[dactech,area]*
      ANMap[area,nation] for area in Areas, dactech in DACTechs)
  end

  WriteDisk(db,"SpOutput/DACCUF",year,DACCUF)
  WriteDisk(db,"SpOutput/DACProd",year,DACProd)
  WriteDisk(db,"SpOutput/DACProdNation",year,DACProdNation)
  WriteDisk(db,"SOutput/DACProduction",year,DACProduction)

end

function EnergyUsage(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,Fuels) = data #sets
  (; DACDemand,DACDmd,DACDmFrac,DACEff,DACProd) = data

  # @info "  DirectAirCapture.jl - EnergyUsage"

  for area in Areas, dactech in DACTechs
    @finite_math DACDmd[dactech,area] = DACProd[dactech,area]/DACEff[dactech,area]

    for fuel in Fuels
      DACDemand[fuel,dactech,area] = DACDmd[dactech,area]*
        DACDmFrac[fuel,dactech,area]
    end
  end

  WriteDisk(db,"SpOutput/DACDemand",year,DACDemand)
  WriteDisk(db,"SpOutput/DACDmd",year,DACDmd)

end

function CombustionEmissions(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,ECC,Fuels,FuelEPs,Polls) = data #sets
  (; DACDemand,DACPOCX,DACPol,EuFPol,EuPol,FFPMap,ZeroFr) = data

  # @info "  DirectAirCapture.jl - CombustionEmissions"

  ecc = Select(ECC,"DirectAirCapture")

  for area in Areas, poll in Polls, dactech in DACTechs, fuelep in FuelEPs
    DACPol[fuelep,dactech,poll,area] = sum(DACDemand[fuel,dactech,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels)*DACPOCX[fuelep,poll,area]
  end

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EuFPol[fuelep,ecc,poll,area] = sum(DACPol[fuelep,dactech,poll,area]*
      (1-ZeroFr[fuelep,poll,area]) for dactech in DACTechs)
  end

  for area in Areas, poll in Polls
    EuPol[ecc,poll,area] = sum(EuFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end

  WriteDisk(db,"SpOutput/DACPol",year,DACPol)
  WriteDisk(db,"SOutput/EuFPol",year,EuFPol)
  WriteDisk(db,"SOutput/EuPol",year,EuPol)
end

function SequesteredEmissions(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,ECC,FuelEPs,Polls) = data #sets
  (; DACPol,DACSqFr,DACSqPol,SqPolCCNet) = data

  # @info "  DirectAirCapture.jl - SequesteredEmissions"

  ecc = Select(ECC,"DirectAirCapture")

  for area in Areas, poll in Polls, dactech in DACTechs
    DACSqPol[dactech,poll,area] = 
      0-sum(DACPol[fuelep,dactech,poll,area] for fuelep in FuelEPs)*
      DACSqFr[dactech,poll,area]
  end

  WriteDisk(db,"SpOutput/DACSqPol",year,DACSqPol)

  for area in Areas, poll in Polls
    SqPolCCNet[ecc,poll,area] = 
      sum(DACSqPol[dactech,poll,area] for dactech in DACTechs)
  end

  WriteDisk(db,"SOutput/SqPolCCNet",year,SqPolCCNet)

end

function NetEmissions(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,FuelEPs,Poll) = data #sets
  (; DACPol,DACPolNet,DACSqPol,PolConv) = data

  # @info "  DirectAirCapture.jl - NetEmissions"

  ghgpolls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])

  for area in Areas
    DACPolNet[area] = sum(DACPol[fuelep,dactech,poll,area]*
      PolConv[poll] for poll in ghgpolls, dactech in DACTechs, fuelep in FuelEPs)+
      sum(DACSqPol[dactech,poll,area]*
      PolConv[poll] for poll in ghgpolls, dactech in DACTechs)
  end

  WriteDisk(db,"SpOutput/DACPolNet",year,DACPolNet)
end

function SequesterPenalty(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,ECC,Fuels,FuelEPs,Polls) = data #sets
  (; DACDmFrac,DACPOCX,DACSqDemand) = data
  (; DACSqPenalty,DACSqPol) = data
  (; DACSqPolPenalty,FFPMap,SqPolPenalty,ZeroFr) = data
  (; DACSqDmd,DACSqDmdFuelEP) = data
  
  # @info "  DirectAirCapture.jl - SequesterPenalty"

  ecc = Select(ECC,"DirectAirCapture")

  for area in Areas, dactech in DACTechs
    DACSqDmd[dactech,area] = sum(0-DACSqPol[dactech,poll,area]*
      DACSqPenalty[dactech,poll,area] for poll in Polls)
    for fuel in Fuels
      DACSqDemand[fuel,dactech,area] = DACSqDmd[dactech,area]*
        DACDmFrac[fuel,dactech,area]
    end
  end

  WriteDisk(db,"SpOutput/DACSqDemand",year,DACSqDemand)

  for area in Areas, dactech in DACTechs, fuelep in FuelEPs
    DACSqDmdFuelEP[fuelep,dactech,area] = sum(DACSqDemand[fuel,dactech,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels)
  end

  for area in Areas, dactech in DACTechs, poll in Polls
    DACSqPolPenalty[dactech,poll,area] = 0-sum(DACSqDmdFuelEP[fuelep,dactech,area]*
                                       DACPOCX[fuelep,poll,area]*(1-ZeroFr[fuelep,poll,area]) for fuelep in FuelEPs)
  end

  WriteDisk(db,"SpOutput/DACSqPolPenalty",year,DACSqPolPenalty)

  for area in Areas, poll in Polls
    SqPolPenalty[ecc,poll,area] = 
      sum(DACSqPolPenalty[dactech,poll,area] for dactech in DACTechs)
  end

  WriteDisk(db,"SOutput/SqPolPenalty",year,SqPolPenalty)

end

function TotalDemands(data::Data)
  (; db,year) = data
  (; Areas,DACTechs,ECC,Fuels) = data #sets
  (; DACDemand,DACSqDemand,EuDemand,TotDemand) = data

  # @info "  DirectAirCapture.jl - TotalDemands"

  ecc = Select(ECC,"DirectAirCapture")

  for area in Areas, fuel in Fuels
    EuDemand[fuel,ecc,area] = sum(DACDemand[fuel,dactech,area]+
      DACSqDemand[fuel,dactech,area] for dactech in DACTechs)
    TotDemand[fuel,ecc,area] = EuDemand[fuel,ecc,area]
  end

  WriteDisk(db,"SOutput/EuDemand",year,EuDemand)
  WriteDisk(db,"SOutput/TotDemand",year,TotDemand)

end

function Investments(data::Data)
  (; db,year,current) = data
  (; Areas,DACTechs,ECC) = data #sets
  (; DACCapCR,DACCC,DACDmd,DACECFP,DACFOMCost,DACProd) = data
  (; DACTransCost,DACVOMCost,DInv,DOMExp) = data
  (; FuelExpenditures,Inflation,OMExp,PInv,POMExp) = data

  # @info "  DirectAirCapture.jl - Investments"

  ecc = Select(ECC,"DirectAirCapture")

  for area in Areas

    #
    # Device Investments
    #
    DInv[ecc,area] = 0.0

    #
    # Device O&M Expenditures
    #
    DOMExp[ecc,area] = 0.0

    #
    # Process Investments
    #
    PInv[ecc,area] = sum(DACCapCR[dactech,area]*DACCC[dactech,area]*
      Inflation[area,current] for dactech in DACTechs)/1e6

    #
    # Process O&M Expenditures
    #
    POMExp[ecc,area] = sum((DACVOMCost[dactech,area]+DACFOMCost[dactech,area]+
      DACTransCost[dactech,area])*DACProd[dactech,area] for dactech in DACTechs)/1e6

    #
    # O&M Expenditures
    #
    OMExp[ecc,area] = DOMExp[ecc,area]+POMExp[ecc,area]

    #
    # Fuel Expenditures (include Feedstocks which are Natural Gas)
    #
    FuelExpenditures[ecc,area] = sum((DACDmd[dactech,area]*
      DACECFP[dactech,area]*1e6) for dactech in DACTechs)/1e6
  end

  WriteDisk(db,"SOutput/DInv",year,DInv)
  WriteDisk(db,"SOutput/DOMExp",year,DOMExp)
  WriteDisk(db,"SOutput/FuelExpenditures",year,FuelExpenditures)
  WriteDisk(db,"SOutput/OMExp",year,OMExp)
  WriteDisk(db,"SOutput/PInv",year,PInv)
  WriteDisk(db,"SOutput/POMExp",year,POMExp)


end

function ElectricSalesAndLoads(data::Data)
  (; db,year) = data
  (; Areas,DACTech,DACTechs,Days,ECC,Fuel,Fuels,Hours,Months,Plant) = data #sets
  (; CgCap,CgCapPrior,CgGen,CgInv,DACCUFP) = data
  (; DACDemand,DACGridFraction,DACLSF,DACSaEC) = data
  (; DACSqDemand,EEConv,GCCC,LDCECC,SaEC) = data
  (; CgCC) = data
  
  # @info "  DirectAirCapture.jl - ElectricSalesAndLoads"

  electric = Select(Fuel,"Electric")
  ecc = Select(ECC,"DirectAirCapture")

  for area in Areas
    for dactech in DACTechs
      DACSaEC[dactech,area] = (DACDemand[electric,dactech,area]+
        DACSqDemand[electric,dactech,area])*DACGridFraction[dactech,area]/EEConv*1E6
    end

    SaEC[ecc,area] = sum(DACSaEC[dactech,area] for dactech in DACTechs)

    for month in Months, day in Days, hour in Hours
      LDCECC[ecc,hour,day,month,area] = sum(DACSaEC[dactech,area]*
        DACLSF[dactech,hour,day,month,area] for dactech in DACTechs)/8760*1E3
    end
  end

  WriteDisk(db,"SpOutput/DACSaEC",year,DACSaEC)
  WriteDisk(db,"SOutput/LDCECC",year,LDCECC)
  WriteDisk(db,"SOutput/SaEC",year,SaEC)

  solar = Select(Fuel,"Solar")
  wind = Select(Fuel,"Wind")
  solarpv = Select(Plant,"SolarPV")
  onshorewind = Select(Plant,"OnshoreWind")

  for area in Areas, dactech in DACTechs
    if DACTech[dactech] == "SolidWaste"
      for fuel in Fuels

        @finite_math CgGen[fuel,ecc,area] = DACDemand[fuel,dactech,area]/
          EEConv*1E6
        @finite_math CgCap[fuel,ecc,area] = CgGen[fuel,ecc,area]/
          DACCUFP[dactech,area]/8760*1000
      end

      CgCC[wind,area] = GCCC[onshorewind,area]
      CgCC[solar,area] = GCCC[solarpv,area]
      CgInv[ecc,area] = sum(max(CgCap[fuel,ecc,area]-CgCapPrior[fuel,ecc,area],0)*
                        CgCC[fuel,area] for fuel in Fuels)/1000
    end
  end


  WriteDisk(db,"SOutput/CgCap",year,CgCap)
  WriteDisk(db,"SOutput/CgGen",year,CgGen)
  WriteDisk(db,"SOutput/CgInv",year,CgInv)

end

function EmissionsAfterDAC(data::Data)
  (; db,year) = data
  (; Areas) = data #sets
  (; PolAfterDAC,PolBeforeDAC,DACPolNet,DACProduction) = data

  # @info "  DirectAirCapture.jl - EmissionsAfterDAC"

  for area in Areas
    PolAfterDAC[area] = PolBeforeDAC[area]-DACProduction[area]+DACPolNet[area]
  end

  WriteDisk(db,"SOutput/PolAfterDAC",year,PolAfterDAC)

end

function SupplyDAC(data::Data)
  # @info "  DirectAirCapture.jl - SupplyDAC"

  EmissionsBeforeDAC(data)
  NationalGoal(data)
  Demands(data)

  # Select ECC(DirectAirCapture)

  DemandGrowthRate(data)
  ProductionTarget(data)
  FuelPrices(data)
  CapitalCosts(data)
  CapitalChargeRate(data)
  GHGEmissionIntensity(data)
  EmissionCosts(data)
  MarginalCost(data)
  MarketShare(data)
  CapacityIndicated(data)
  CapacityRetirementRate(data)
  CapacityCompletionRate(data)
  ProductionCapacity(data)
  Production(data)
  EnergyUsage(data)
  CombustionEmissions(data)
  SequesteredEmissions(data)
  NetEmissions(data)
  SequesterPenalty(data)
  TotalDemands(data)
  Investments(data)

  # Select ECC*

  ElectricSalesAndLoads(data)
  EmissionsAfterDAC(data)

end # function SupplyDAC

########################
#
# DAC Prices
#
########################


function WholesalePrice(data::Data)
  (; db,next) = data
  (; Areas,DACTechs,Nations) = data #sets
  (; ANMap,DACENPNNext,DACFPWholesaleNext,DACMCE,DACMCENext,DACProd,DACProdNation,InflationNation,xDACENPNNext) = data

  # @info "  DirectAirCapture.jl - WholesalePrice"

  #
  # Trap so DACMCE is positive
  #
  for area in Areas, dactech in DACTechs
    DACMCENext[dactech,area] = max(DACMCE[dactech,area],1.00)
  end

  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    if DACProdNation[nation] > 0

      MCEWeight = sum(DACMCE[dactech,area]*DACProd[dactech,area]*
        ANMap[area,nation] for area in Areas, dactech in DACTechs)
      TotalWeight = sum(DACProd[dactech,area]*
        ANMap[area,nation] for area in Areas, dactech in DACTechs)
      @finite_math DACENPNNext[nation] = MCEWeight/TotalWeight

      for area in areas
        if ANMap[area,nation] == 1

          MCEWeight = sum(DACMCE[dactech,area]*
            DACProd[dactech,area] for dactech in DACTechs)
          TotalWeight = sum(DACProd[dactech,area] for dactech in DACTechs)
          @finite_math DACFPWholesaleNext[area] = MCEWeight/TotalWeight

        end
      end
    else

      DACENPNNext[nation] = xDACENPNNext[nation]*InflationNation[nation,next]
      for area in areas
        if ANMap[area,nation] == 1
          @finite_math DACFPWholesaleNext[area] = xDACENPNNext[nation]*
            InflationNation[nation,next]
        end
      end
    end
  end

  WriteDisk(db,"SpOutput/DACENPN",next,DACENPNNext)
  WriteDisk(db,"SpOutput/DACFPWholesale",next,DACFPWholesaleNext)
end

function RetailPrice(data::Data)

  # @info "  DirectAirCapture.jl - RetailPrice"

  #
  # Empty procedure in Promula
  #
end

function PriceDAC(data::Data)
  # @info "  DirectAirCapture.jl - PriceDAC"

  WholesalePrice(data)

  #
  # RetailPrice(data)
  #

end # function PriceDAC

end # module DirectAirCapture
