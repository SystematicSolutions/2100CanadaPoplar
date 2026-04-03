#
# SpHydrogen.jl - Hydrogen Supply Sector
#

module SpHydrogen

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime,DT
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

#
# *********************
#
Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  Yr2016::Int = 2016-ITime+1
  Yr2020::Int = 2020-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaKey::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  Days::Vector{Int} = collect(Select(Day))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCKey::SetArray = ReadDisk(db,"MainDB/ECCKey")  
  ECCs::Vector{Int} = collect(Select(ECC))  
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))  
  H2Tech::SetArray = ReadDisk(db,"MainDB/H2TechKey")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeKey::SetArray = ReadDisk(db,"MainDB/NodeKey")
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantKey::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray  = ReadDisk(db,"MainDB/PowerKey")
  Powers::Vector{Int} = collect(Select(Power))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgCap::VariableArray{3} = ReadDisk(db,"SOutput/CgCap",year) # [Fuel,ECC,Area] Cogeneration Capacity (MW)
  CgCapPrior::VariableArray{3} = ReadDisk(db,"SOutput/CgCap",prior) # [Fuel,ECC,Area] Cogeneration Capacity (MW)
  CgDemand::VariableArray{3} = ReadDisk(db,"SOutput/CgDemand",year) # Cogeneration Demands (TBtu/Yr) [Fuel,ECC,Area]  
  CgGen::VariableArray{3} = ReadDisk(db,"SOutput/CgGen",year) # [Fuel,ECC,Area] Cogeneration Generation (GWh/Yr)
  CgInv::VariableArray{2} = ReadDisk(db,"SOutput/CgInv",year) # [ECC,Area] Cogeneration Investments (M$/Yr)
  CgUnCode::VariableArray{4} = ReadDisk(db,"EGInput/CgUnCode") # [Plant,ECC,Node,Area] Cogeneration Unit Number (Number)
  DOMExp::VariableArray{2} = ReadDisk(db,"SOutput/DOMExp",year) # [ECC,Area] Device O&M Expenditures (M$)
  DInv::VariableArray{2} = ReadDisk(db,"SOutput/DInv",year) # [ECC,Area] Device Investments (M$/Yr)
  eCO2Price::VariableArray{1} = ReadDisk(db,"SOutput/eCO2Price",year) # [Area] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ECoverage::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) # [ECC,Poll,PCov,Area] Emissions Permit Coverage (Tonnes/Tonnes)
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) # [Fuel,Nation]  Wholesale Price ($/mmBtu)
  ENPNNext::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",next) # [Fuel,Nation] Wholesale Price ($/mmBtu)
  ENPNSwNext::VariableArray{2} = ReadDisk(db,"SInput/ENPNSw",next) #[Fuel,Nation] Wholesale Price Switch (1=Endogenous)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) # [FuelEP,ECC,Poll,Area] Energy Pollution with Cogeneration (Tonnes/Yr)
  EuPol::VariableArray{3} = ReadDisk(db,"SOutput/EuPol",year) # [ECC,Poll,Area] Energy Related Pollution (Tonnes/Yr)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) # [Fuel,ECC,Area] Enduse Energy Demands (TBtu/Yr)
  Exports::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) # [FuelEP,Nation] Primary Exports (TBtu/Yr)
  ExportsArea::VariableArray{2} = ReadDisk(db,"SpOutput/ExportsArea",year) #[Fuel,Area,Year]  Exports of Energy (TBtu/Yr)  
  ExportsFuel::VariableArray{2} = ReadDisk(db,"SpOutput/ExportsFuel",year) #[Fuel,Nation,Year]  Primary Exports (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FPBaseFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPBaseF",next) # [Fuel,ES,Area] Delivered Fuel Price without Taxes ($/mmBtu)
  FPDChgFNext::VariableArray{3} = ReadDisk(db,"SCalDB/FPDChgF",next) # [Fuel,ES,Area] Fuel Delivery Charge (Real $/mmBtu)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) # [Fuel,ES,Area] Delivered Fuel Price ($/mmBtu)
  FPFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPF",next) # [Fuel,ES,Area] Delivered Fuel Price ($/mmBtu)
  FPMarginFNext::VariableArray{3} = ReadDisk(db,"SInput/FPMarginF",next) # [Fuel,ES,Area] Refinery/Distributor Margin ($/$)
  FPPolTaxFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPPolTaxF",next) # [Fuel,ES,Area] Pollution Tax (Real $/mmBtu)
  FPSMFNext::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",next) # [Fuel,ES,Area] Energy Sales Tax ($/$)
  FPTaxFNext::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",next) # [Fuel,ES,Area] Fuel Tax (Real $/mmBtu)
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") # [Fuel,Plant] Fuel/Plant Map
  FsDemand::VariableArray{3} = ReadDisk(db,"SOutput/FsDemand",year) # [Fuel,ECC,Area] Feedstock Demands (tBtu)
  FsFP::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",year) # [Fuel,ES,Area] Feedstock Fuel Price ($/mmBtu)
  FsFPNext::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",next) # [Fuel,ES,Area] Feedstock Fuel Price ($/mmBtu)
  FuelExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/FuelExpenditures",year) # [ECC,Area] Fuel Expenditures (M$)
  GCCC::VariableArray{2} = ReadDisk(db,"EGOutput/GCCC",year) # [Plant,Area] Overnight Construction Costs ($/KW)
  H2CC::VariableArray{2} = ReadDisk(db,"SpOutput/H2CC",year) # [H2Tech,Area] Hydrogen Production Capital Cost ($/mmBtu)
  H2CCM::VariableArray{2} = ReadDisk(db,"SpInput/H2CCM",year) # [H2Tech,Area] Hydrogen Production Capital Cost Multiplier ($/$)
  H2CCN::VariableArray{2} = ReadDisk(db,"SpInput/H2CCN",year) # [H2Tech,Area] Hydrogen Production Capital Cost (Real $/mmBtu)
  H2CCR::VariableArray{2} = ReadDisk(db,"SpInput/H2CCR",year) # [H2Tech,Area] Hydrogen Production Capital Charge Rate
  H2CD::Float32 = ReadDisk(db,"SpInput/H2CD",year) # Float32  # Hydrogen Production Construction Delay (Years)
  H2CUF::VariableArray{2} = ReadDisk(db,"SpOutput/H2CUF",year) # [H2Tech,Area] Hydrogen Production Capacity Utilization Factor (mmBtu/mmBtu)
  H2CUFMax::VariableArray{1} = ReadDisk(db,"SpInput/H2CUFMax",year) # [Area] Hydrogen Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  H2CUFP::VariableArray{2} = ReadDisk(db,"SpInput/H2CUFP",year) # [H2Tech,Area] Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  H2Cap::VariableArray{2} = ReadDisk(db,"SpOutput/H2Cap",year) # [H2Tech,Area] Hydrogen Production Capacity (TBtu/Yr)

  H2CapCR::VariableArray{2} = ReadDisk(db,"SpOutput/H2CapCR",year) # [H2Tech,Area] Hydrogen Production Capacity Completion Rate (TBtu/Yr)
  H2CapI::VariableArray{2} = ReadDisk(db,"SpOutput/H2CapI",year) # [H2Tech,Area] Hydrogen Indicated Production Capacity (TBtu/Yr)
  H2CapPrior::VariableArray{2} = ReadDisk(db,"SpOutput/H2Cap",prior) # [H2Tech,Area] Hydrogen Production Capacity (TBtu/Yr)
  H2CapRR::VariableArray{2} = ReadDisk(db,"SpOutput/H2CapRR",year) # [H2Tech,Area] Hydrogen Production Capacity Retirement Rate (TBtu/Yr)
  H2Dem::VariableArray{1} = ReadDisk(db,"SpOutput/H2Dem",year) # [Area] Demand for Hydrogen (TBtu/Yr)
  H2DemGR::VariableArray{1} = ReadDisk(db,"SpInput/H2DemGR",year) # [Nation] National Demand for Hydrogen Growth Rate (Btu/Btu)
  H2DemNation::VariableArray{1} = ReadDisk(db,"SpOutput/H2DemNation",year) # [Nation] National Demand for Hydrogen (TBtu/Yr)
  H2Demand::VariableArray{3} = ReadDisk(db,"SpOutput/H2Demand",year) # [Fuel,H2Tech,Area] Hydrogen Production Energy Usage (TBtu/Yr)
  H2DemandMSM0::VariableArray{1} = ReadDisk(db,"SpInput/H2DemandMSM0",year) # [Nation] Hydrogen Domestic Demand Non-Price Factors ($/$)
  H2DemSm::VariableArray{1} = ReadDisk(db,"SpOutput/H2DemSm",year) # [Nation]
  H2DemSmPrior::VariableArray{1} = ReadDisk(db,"SpOutput/H2DemSm",prior) # [Nation]
  H2DmFrac::VariableArray{3} = ReadDisk(db,"SpInput/H2DmFrac",year) # [Fuel,H2Tech,Area] Hydrogen Production Energy Usage Fraction (Btu/Btu)
  H2Dmd::VariableArray{2} = ReadDisk(db,"SpOutput/H2Dmd",year) # [H2Tech,Area] Hydrogen Production Energy Usage (TBtu/Yr)
  H2DmdEmissionCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2DmdEmissionCost",year) # [H2Tech,Area] Hydrogen Emission Cost ($/mmBtu)
  H2ECFP::VariableArray{2} = ReadDisk(db,"SpOutput/H2ECFP",year) # [H2Tech,Area] Fuel Prices for Hydrogen Production ($/mmBtu)
  H2EI::VariableArray{2} = ReadDisk(db,"SpOutput/H2EI",year) # [H2Tech,Area] Hydrogen Production GHG Emission Intensity (Tonnes eCO2/TBtu H2)
  H2EIDmd::VariableArray{2} = ReadDisk(db,"SpOutput/H2EIDmd",year) # [H2Tech,Area] Hydrogen Production GHG Combustion Emission Intensity (Tonnes eCO2/TBtu H2)
  H2EIDmdFuel::VariableArray{3} = ReadDisk(db,"SpOutput/H2EIDmdFuel",year) # [Fuel,H2Tech,Area] Hydrogen Production GHG Combustion Emission Intensity (Tonnes eCO2/TBtu H2)
  H2EIFs::VariableArray{2} = ReadDisk(db,"SpOutput/H2EIFs",year) # [H2Tech,Area] Hydrogen Production GHG Feedstock Emission Intensity (Tonnes eCO2/TBtu)
  H2EIFsFuel::VariableArray{3} = ReadDisk(db,"SpOutput/H2EIFsFuel",year) # [Fuel,H2Tech,Area] Hydrogen Production GHG Feedstock Emission Intensity (Tonnes eCO2/TBtu)
  H2ENPN::VariableArray{1} = ReadDisk(db,"SpOutput/H2ENPN",year) # [Nation] Hydrogen Wholesale Price ($/mmBtu)
  H2ENPNNext::VariableArray{1} = ReadDisk(db,"SpOutput/H2ENPN",next) # [Nation] Hydrogen Wholesale Price ($/mmBtu)
  H2ENPN0::VariableArray{1} = ReadDisk(db,"SpOutput/H2ENPN",Yr2020) # [Nation] Hydrogen Wholesale Price ($/mmBtu)
  H2ENPNExports::VariableArray{1} = ReadDisk(db,"SpOutput/H2ENPNExports",year) # [Nation] Hydrogen Exports Price ($/mmBtu)
  H2ENPNExports0::VariableArray{1} = ReadDisk(db,"SpOutput/H2ENPNExports",Yr2020) # [Nation] Hydrogen Exports Price ($/mmBtu)
  H2ENPNImports::VariableArray{1} = ReadDisk(db,"SpOutput/H2ENPNImports",year) # [Nation] Hydrogen Imports Price ($/mmBtu)
  H2ENPNImports0::VariableArray{1} = ReadDisk(db,"SpOutput/H2ENPNImports",Yr2020) # [Nation] Hydrogen Imports Price ($/mmBtu)
  H2Eff::VariableArray{2} = ReadDisk(db,"SpInput/H2Eff",year) # [H2Tech,Area] Hydrogen Production Energy Efficiency (Btu/Btu)
  H2EmissionCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2EmissionCost",year) # [H2Tech,Area] Hydrogen Emission Cost ($/mmBtu)
  H2Exports::VariableArray{1} = ReadDisk(db,"SpOutput/H2Exports",year) # [Nation] Hydrogen Exports (TBtu/Yr)
  H2ExportsCharge::VariableArray{1} = ReadDisk(db,"SpInput/H2ExportsCharge",year) # [Nation] Hydrogen Exports Charge ($/mmBtu)
  H2ExportsEst::VariableArray{1} = ReadDisk(db,"SpOutput/H2ExportsEst",year) # [Nation] Estimate of Hydrogen Exports (TBtu/Yr)
  H2ExportsMSF::VariableArray{1} = ReadDisk(db,"SpOutput/H2ExportsMSF",year) # [Nation] Hydrogen Exports Market Share (TBtu/Yr)
  H2ExportsMSM0::VariableArray{1} = ReadDisk(db,"SpInput/H2ExportsMSM0",year) # [Nation] Hydrogen Exports Non-Price Factors ($/$)
  H2ExportsVF::VariableArray{1} = ReadDisk(db,"SpInput/H2ExportsVF",year) # [Nation] Hydrogen Exports Variance Factors ($/$)
  H2FOMCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2FOMCost",year) # [H2Tech,Area] Hydrogen Production Fixed O&M Costs ($/mmBtu)
  H2FPDChgNext::VariableArray{2} = ReadDisk(db,"SpInput/H2FPDChg",next) # [ES,Area] Hydrogen Fuel Delivery Charge (Real $/mmBtu)
  H2FPWholesale::VariableArray{1} = ReadDisk(db,"SpOutput/H2FPWholesale",year) # [Area] Hydrogen Price ($/mmBtu)
  H2FPWholesaleNext::VariableArray{1} = ReadDisk(db,"SpOutput/H2FPWholesale",next) # [Area] Hydrogen Price ($/mmBtu)
  H2FeedstockCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2FeedstockCost",year) # [H2Tech,Area] Hydrogen Feedstock Cost ($/mmBtu)
  H2FsDem::VariableArray{3} = ReadDisk(db,"SpOutput/H2FsDem",year) # [Fuel,H2Tech,Area] Hydrogen Feedstock Demand (mmBtu/Yr)
  H2FsEmissionCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2FsEmissionCost",year) # [H2Tech,Area] Hydrogen Feedstock Emission Cost ($/mmBtu)
  H2FsFrac::VariableArray{3} = ReadDisk(db,"SpInput/H2FsFrac",year) # [Fuel,H2Tech,Area] Hydrogen Feedstock Fuel/H2Tech Split (Btu/Btu)
  H2FsPOCX::VariableArray{3} = ReadDisk(db,"SpInput/H2FsPOCX",year) # [FuelEP,Poll,Area] Hydrogen Feedstock Pollution Coefficients (Tonnes/TBtu)
  H2FsPol::VariableArray{4} = ReadDisk(db,"SpOutput/H2FsPol",year) # [FuelEP,H2Tech,Poll,Area] Hydrogen Production Feedstock Emissions (Tonnes/Yr)
  H2FsPrice::VariableArray{2} = ReadDisk(db,"SpOutput/H2FsPrice",year) # [H2Tech,Area] Hydrogen Feedstock Price ($/mmBtu)
  H2FsReq::VariableArray{2} = ReadDisk(db,"SpOutput/H2FsReq",year) # [H2Tech,Area] Hydrogen Feedstock Required (TBtu/Yr)
  H2FsYield::VariableArray{2} = ReadDisk(db,"SpInput/H2FsYield",year) # [H2Tech,Area] Hydrogen Yield From Feedstock (Btu/Btu)
  H2FuelCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2FuelCost",year) # [H2Tech,Area] Hydrogen Fuel Cost ($/mmBtu)
  H2GridFraction::VariableArray{2} = ReadDisk(db,"SpInput/H2GridFraction",year) # [H2Tech,Area] Fraction of Electric Demands Purchased from Grid (Btu/Btu)
  H2IPMultiplier::VariableArray{2} = ReadDisk(db,"SpInput/H2IPMultiplier",year) # [H2Tech,Area] Interruptible Electricity Price Multiplier ($/$)
  H2Imports::VariableArray{1} = ReadDisk(db,"SpOutput/H2Imports",year) # [Nation] Hydrogen Imports (TBtu/Yr)
  H2ImportsCharge::VariableArray{1} = ReadDisk(db,"SpInput/H2ImportsCharge",year) # [Nation] Hydrogen Imports Charge ($/$)
  H2ImportsEst::VariableArray{1} = ReadDisk(db,"SpOutput/H2ImportsEst",year) # [Nation] Hydrogen Imports (TBtu/Yr)
  H2ImportsMSF::VariableArray{1} = ReadDisk(db,"SpOutput/H2ImportsMSF",year) # [Nation] Hydrogen Imports Market Share (TBtu/Yr)
  H2ImportsMSM0::VariableArray{1} = ReadDisk(db,"SpInput/H2ImportsMSM0",year) # [Nation] Hydrogen Imports Non-Price Factors ($/$)
  H2ImportsVF::VariableArray{1} = ReadDisk(db,"SpInput/H2ImportsVF",year) # [Nation] Hydrogen Imports Variance Factors ($/$)
  H2LSF::VariableArray{5} = ReadDisk(db,"SCalDB/H2LSF") # [H2Tech,Hour,Day,Month,Area] Hydrogen Production Load Shape (MW/MW)
  H2MCE::VariableArray{2} = ReadDisk(db,"SpOutput/H2MCE",year) # [H2Tech,Area] Hydrogen Levelized Marginal Cost ($/mmBtu)
  H2MCE0::VariableArray{2} = ReadDisk(db,"SpOutput/H2MCE",Yr2020) # [H2Tech,Area] Hydrogen Levelized Marginal Cost ($/mmBtu)
  H2MSF::VariableArray{2} = ReadDisk(db,"SpOutput/H2MSF",year) # [H2Tech,Area] Hydrogen Market Share (mmBtu/mmBtu)
  H2MSFSwitch::VariableArray{1} = ReadDisk(db,"SpInput/H2MSFSwitch",year) # [Area] Hydrogen Market Share Non-Price Factor (mmBtu/mmBtu)
  H2MSM0::VariableArray{2} = ReadDisk(db,"SpInput/H2MSM0",year) # [H2Tech,Area] Hydrogen Market Share Non-Price Factor (mmBtu/mmBtu)
  H2OF::VariableArray{2} = ReadDisk(db,"SpInput/H2OF",year) # [H2Tech,Area] Hydrogen Production O&M Cost Factor (Real $/$/Yr)
  H2PL::VariableArray{1} = ReadDisk(db,"SpInput/H2PL",year) # [H2Tech] Hydrogen Production Physical Lifetime (Years)
  H2POCX::VariableArray{3} = ReadDisk(db,"SpInput/H2POCX",year) # [FuelEP,Poll,Area]
  H2PipeA0::VariableArray{1} = ReadDisk(db,"SpInput/H2PipeA0",year) # [Area] Pipeline Efficiency Multiplier A0 Coefficient (Btu/Btu)  # Hydrogen Pollution Coefficient (Tonnes/TBtu)
  H2PipeB0::VariableArray{1} = ReadDisk(db,"SpInput/H2PipeB0",year) # [Area] Pipeline Efficiency Multiplier B0 Coefficient (Btu/Btu)
  H2PipeC0::VariableArray{1} = ReadDisk(db,"SpInput/H2PipeC0",year) # [Area] Pipeline Efficiency Multiplier C0 Coefficient (Btu/Btu)
  H2PipelineFraction::VariableArray{1} = ReadDisk(db,"SpOutput/H2PipelineFraction",year) # [Area] Fraction of H2 in Pipeline (Btu/Btu)
  H2PipelineMultiplier::VariableArray{1} = ReadDisk(db,"SOutput/H2PipelineMultiplier",year) # [Area] Pipeline Efficiency Multiplier from H2 in Pipeline (Btu/Btu)
  H2PlantMap::VariableArray{4} = ReadDisk(db,"SpInput/H2PlantMap") # [H2Tech,Plant,Power,Area] H2 Process to Plant Type Map
  H2Pol::VariableArray{4} = ReadDisk(db,"SpOutput/H2Pol",year) # [FuelEP,H2Tech,Poll,Area] Hydrogen Production Combustion Emissions (Tonnes/Yr)
  H2Prod::VariableArray{2} = ReadDisk(db,"SpOutput/H2Prod",year) # [H2Tech,Area] Hydrogen Production (TBtu/Yr)
  H2ProdNation::VariableArray{1} = ReadDisk(db,"SpOutput/H2ProdNation",year) # [Nation] Hydrogen Production (TBtu/Yr)
  H2ProdNationPrior::VariableArray{1} = ReadDisk(db,"SpOutput/H2ProdNation",prior) # [Nation] Hydrogen Production (TBtu/Yr)
  H2ProdPrior::VariableArray{2} = ReadDisk(db,"SpOutput/H2Prod",prior) # [H2Tech,Area] Hydrogen Production (TBtu/Yr)
  H2ProdTarget::VariableArray{1} = ReadDisk(db,"SpOutput/H2ProdTarget",year) # [Area] Hydrogen Production Target (TBtu/Yr)
  H2ProdTargetN::VariableArray{1} = ReadDisk(db,"SpOutput/H2ProdTargetN",year) # [Nation] Hydrogen Production Target (TBtu/Yr)
  H2Production::VariableArray{1} = ReadDisk(db,"SpOutput/H2Production",year) # [Area] Hydrogen Production (TBtu/Yr)
  H2SaEC::VariableArray{2} = ReadDisk(db,"SpOutput/H2SaEC",year) # [H2Tech,Area] Electric Sales to Hydrogen (GWh/Yr)
  H2SmT::Float32 = ReadDisk(db,"SpInput/H2SmT",year) # [Year]
  H2SqFr::VariableArray{3} = ReadDisk(db,"SpInput/H2SqFr",year) # [H2Tech,Poll,Area] Hydrogen Sequestered Pollution Fraction (Tonnes/Tonnes)
  H2SqDemand::VariableArray{3} = ReadDisk(db,"SpOutput/H2SqDemand",year) # [Fuel,H2Tech,Area]
  H2SqEI::VariableArray{2} = ReadDisk(db,"SpOutput/H2SqEI",year) # [H2Tech,Area]
  H2SqEIDmd::VariableArray{2} = ReadDisk(db,"SpOutput/H2SqEIDmd",year) # [H2Tech,Area]
  H2SqEIDmdFuel::VariableArray{3} = ReadDisk(db,"SpOutput/H2SqEIDmdFuel",year) # [Fuel,H2Tech,Area]
  H2SqEIFs::VariableArray{2} = ReadDisk(db,"SpOutput/H2SqEI",year) # [H2Tech,Area]
  H2SqEIFsFuel::VariableArray{3} = ReadDisk(db,"SpOutput/H2SqEIDmdFuel",year) # [Fuel,H2Tech,Area]
  H2SqPenalty::VariableArray{3} = ReadDisk(db,"SpInput/H2SqPenalty",year) # [H2Tech,Poll,Area]
  H2SqPol::VariableArray{3} = ReadDisk(db,"SpOutput/H2SqPol",year) # [H2Tech,Poll,Area] Hydrogen Sequestering Emissions (Tonnes/Yr)
  H2SqPolPenalty::VariableArray{3} = ReadDisk(db,"SpOutput/H2SqPolPenalty",year) # [H2Tech,Poll,Area] Hydrogen Sequestering Emissions Penalty (Tonnes/Yr)
  H2SqTransStorageCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2SqTransStorageCost",year) # [H2Tech,Area] Hydrogen Sequestering Emissions (Tonnes/Yr)
  H2Subsidy::VariableArray{1} = ReadDisk(db,"SpInput/H2Subsidy",year) # [Area] Hydrogen Production Subsidy ($/mmBtu)
  H2SupplyMSM0::VariableArray{1} = ReadDisk(db,"SpInput/H2SupplyMSM0",year) # [Nation] Hydrogen Domestic Supply Non-Price Factors ($/$)
  H2Trans::VariableArray{2} = ReadDisk(db,"SpInput/H2Trans",year) # [H2Tech,Area] Hydrogen Transmission Costs (Real $/mmBtu)
  H2TransCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2TransCost",year) # [H2Tech,Area] Hydrogen Transmission Costs ($/mmBtu)
  H2UOMC::VariableArray{2} = ReadDisk(db,"SpInput/H2UOMC",year) # [H2Tech,Area] Hydrogen Production Variable O&M Costs (Real $/mmBtu)
  H2VC::VariableArray{2} = ReadDisk(db,"SpOutput/H2VC",year) # [H2Tech,Area] Hydrogen Variable Cost ($/mmBtu)
  H2VF::VariableArray{2} = ReadDisk(db,"SpInput/H2VF",year) # [H2Tech,Area] Hydrogen Market Share Variance Factor (mmBtu/mmBtu)
  H2VOMCost::VariableArray{2} = ReadDisk(db,"SpOutput/H2VOMCost",year) # [H2Tech,Area] Hydrogen Production Variable O&M Costs ($/mmBtu)
  
  Imports::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) # [FuelEP,Nation] Primary Imports (TBtu/Yr)
  ImportsArea::VariableArray{2} = ReadDisk(db,"SpOutput/ImportsArea",year) #[Fuel,Area,Year]  Imports of Energy (TBtu/Yr)
  ImportsFuel::VariableArray{2} = ReadDisk(db,"SpOutput/ImportsFuel",year) #[Fuel,Nation,Year]  Primary Imports (TBtu/Yr)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) # [Area] Inflation Index ($/$)
  Inflation2016::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr2016) # [Area]
  InflationNext::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",next) # [Area] Inflation Index ($/$)
  InflationNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) # [Nation] Inflation Index ($/$)
  InflationNationNext::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",next) # [Nation] Inflation Index ($/$)
  LDCECC::VariableArray{5} = ReadDisk(db,"SOutput/LDCECC",year) # [ECC,Hour,Day,Month,Area] Electric Loads Dispatched (MW)
  MCE::VariableArray{3} = ReadDisk(db,"EOutput/MCE",year) # [Plant,Power,Area] Cost of Energy from New Capacity ($/MWh)
  NcFPol::VariableArray{4} = ReadDisk(db,"SOutput/NcFPol",year) # [Fuel,ECC,Poll,Area] Non Combustion Related Pollution (Tonnes/Yr)
  NcPol::VariableArray{3} = ReadDisk(db,"SOutput/NcPol",year) # [ECC,Poll,Area] Non Combustion Related Pollution (Tonnes/Yr)
  NGDem::VariableArray{1} = ReadDisk(db,"SpOutput/NGDem",year) # [Area] Demand for Hydrogen (TBtu/Yr)
  NGDemNation::VariableArray{1} = ReadDisk(db,"SpOutput/NGDemNation",year) # [Nation] National Demand for Hydrogen (TBtu/Yr)
  
  NH3Cap::VariableArray{2} = ReadDisk(db,"SpOutput/NH3Cap",year) #[H2Tech,Area] Ammonia Production Capacity
  NH3CapPrior::VariableArray{2} = ReadDisk(db,"SpOutput/NH3Cap",prior) #[H2Tech,Area] Ammonia Production Capacity Prior
  NH3CapCR::VariableArray{2} = ReadDisk(db,"SpOutput/NH3CapCR",year) #[H2Tech,Area] Ammonia Capacity Completion Rate
  NH3CapI::VariableArray{2} = ReadDisk(db,"SpOutput/NH3CapI",year) #[H2Tech,Area] Ammonia Indicated Production Capacity
  NH3CapRR::VariableArray{2} = ReadDisk(db,"SpOutput/NH3CapRR",year) #[H2Tech,Area] Ammonia Capacity Retirement Rate
  NH3CC::VariableArray{2} = ReadDisk(db,"SpOutput/NH3CC",year) #[H2Tech,Area] Ammonia Production Capital Cost
  NH3CCM::VariableArray{2} = ReadDisk(db,"SpInput/NH3CCM",year) #[H2Tech,Area] Ammonia Capital Cost Multiplier
  NH3CCN::VariableArray{2} = ReadDisk(db,"SpInput/NH3CCN",year) #[H2Tech,Area] Ammonia Capital Cost Normal
  NH3CUF::VariableArray{2} = ReadDisk(db,"SpOutput/NH3CUF",year) #[H2Tech,Area] Ammonia Capacity Utilization Factor
  NH3CUFMax::VariableArray{1} = ReadDisk(db,"SpInput/NH3CUFMax",year) #[Area] Ammonia Maximum CUF
  NH3CUFP::VariableArray{2} = ReadDisk(db,"SpInput/NH3CUFP",year) #[H2Tech,Area] Ammonia Planning CUF
  NH3Dem::VariableArray{1} = ReadDisk(db,"SpOutput/NH3Dem",year) #[Area] Ammonia Demand
  NH3DemNation::VariableArray{1} = ReadDisk(db,"SpOutput/NH3DemNation",year) #[Nation] National Ammonia Demand
  NH3Eff::VariableArray{2} = ReadDisk(db,"SpInput/NH3Eff",year) # [H2Tech,Area] Ammonia Production Energy Efficiency (Btu/Btu)
  NH3ENPNNext::VariableArray{1} = ReadDisk(db,"SpOutput/NH3ENPN",next) # [Nation,Year] Ammonia Wholesale Price ($/mmBtu)
  NH3Exports::VariableArray{1} = ReadDisk(db,"SpOutput/NH3Exports",year) # [Nation] Ammonia Exports (TBtu/Yr)
  NH3ExportsEst::VariableArray{1} = ReadDisk(db,"SpOutput/NH3ExportsEst",year) # [Nation] NH3 Exports Est (TBtu/Year)
  NH3FOMCost::VariableArray{2} = ReadDisk(db,"SpOutput/NH3FOMCost",year) # [H2Tech,Area] Ammonia Production Fixed O&M Costs ($/mmBtu)
  NH3FPWholesaleNext::VariableArray{1} = ReadDisk(db,"SpOutput/NH3FPWholesale",next) # [Area,Next] Ammonia Price ($/mmBtu)
  NH3FsYield::VariableArray{2} = ReadDisk(db,"SpInput/NH3FsYield",year) # [H2Tech,Area] Ammonia Yield From Feedstock (Btu/Btu)
  NH3FuelCost::VariableArray{2} = ReadDisk(db,"SpOutput/NH3FuelCost",year) # [H2Tech,Area] Ammonia Fuel Cost ($/mmBtu)
  NH3H2Yield::Float32 = ReadDisk(db,"SpInput/NH3H2Yield")[1] # [tv] Ammonia Yield from Hydrogen (mmbtu/mmbtu)
  NH3Imports::VariableArray{1} = ReadDisk(db,"SpOutput/NH3Imports",year) # [Nation] Ammonia Imports (TBtu/Yr)
  NH3MCE::VariableArray{2} = ReadDisk(db,"SpOutput/NH3MCE",year) # [H2Tech,Area] Ammonia Levelized Marginal Cost ($/mmBtu)
  NH3MSF::VariableArray{2} = ReadDisk(db,"SpOutput/NH3MSF",year) # [H2Tech,Area] Ammonia Market Share (mmBtu/mmBtu)
  NH3MSM0::VariableArray{2} = ReadDisk(db,"SpInput/NH3MSM0",year) # [H2Tech,Area] Ammonia Market Share Non-Price Factor (mmBtu/mmBtu)
  NH3OF::VariableArray{2} = ReadDisk(db,"SpInput/NH3OF",year) # [H2Tech,Area] Ammonia Production O&M Cost Factor (Real $/$/Yr)
  NH3Prod::VariableArray{2} = ReadDisk(db,"SpOutput/NH3Prod",year) # [H2Tech,Area] Ammonia Production (TBtu/Yr)
  NH3ProdNation::VariableArray{1} = ReadDisk(db,"SpOutput/NH3ProdNation",year) # [Nation] Ammonia Production (TBtu/Yr)
  NH3ProdPrior::VariableArray{2} = ReadDisk(db,"SpOutput/NH3Prod",prior) # [H2Tech,Area] Ammonia Production (TBtu/Yr)
  NH3ProdTarget::VariableArray{1} = ReadDisk(db,"SpOutput/NH3ProdTarget",year) # [Area] Ammonia Production Target (TBtu/Yr)
  NH3ProdTargetN::VariableArray{1} = ReadDisk(db,"SpOutput/NH3ProdTargetN",year) # [Nation] Ammonia Production Target (TBtu/Yr)
  NH3Production::VariableArray{1} = ReadDisk(db,"SpOutput/NH3Production",year) # [Area] Ammonia Production (TBtu/Yr)
  NH3UOMC::VariableArray{2} = ReadDisk(db,"SpInput/NH3UOMC",year) # [H2Tech,Area] Ammonia Production Variable O&M Costs (Real $/mmBtu)
  NH3VC::VariableArray{2} = ReadDisk(db,"SpOutput/NH3VC",year) # [H2Tech,Area] Ammonia Variable Cost ($/mmBtu)
  NH3VOMCost::VariableArray{2} = ReadDisk(db,"SpOutput/NH3VOMCost",year) # [H2Tech,Area] Ammonia Production Variable O&M Costs ($/mmBtu)
  
  OMExp::VariableArray{2} = ReadDisk(db,"SOutput/OMExp",year) # [ECC,Area] O&M Expenditures (M$)
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) # [ECC,Poll,Area] Permit Cost (Real $/Tonnes)
  PInv::VariableArray{2} = ReadDisk(db,"SOutput/PInv",year) # [ECC,Area] Process Investments (M$/Yr)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  POMExp::VariableArray{2} = ReadDisk(db,"SOutput/POMExp",year) # [ECC,Area] Process O&M Expenditures (M$)
  
  SaEC::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",year) # [ECC,Area] Electricity Sales (GWh/Yr)
  SqPolCCNet::VariableArray{3} = ReadDisk(db,"SOutput/SqPolCCNet",year) # [ECC,Poll,Area] Sequestering Cost Curve Net Emissions (Tonnes/Yr)
  SqPolPenalty::VariableArray{3} = ReadDisk(db,"SOutput/SqPolPenalty",year) # [ECC,Poll,Area] Sequestering Emissions Penalty (Tonnes/Yr)
  SqTransStorageCost::VariableArray{1} = ReadDisk(db,"MEInput/SqTransStorageCost",year) # [Area] Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) # [Fuel,ECC,Area] Energy Demands (TBtu/Yr)
  TotDemandPrior::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",prior) # [Fuel,ECC,Area] Energy Demands (TBtu/Yr)
  UnCode::Vector{String} = ReadDisk(db,"EGInput/UnCode") #[Unit]  Unit Code
  UnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGA",year) #[Unit,Year]  Net Generation (GWh)
  UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Gross Generating Capacity (MW)
  xENPNNext::VariableArray{2} = ReadDisk(db,"SInput/xENPN",next) # [Fuel,Nation] Exogenous Price Normal (Real $/mmBtu)
  xH2MSF::VariableArray{2} = ReadDisk(db,"SpInput/xH2MSF",year) # [H2Tech,Area] Hydrogen Exogenous Market Share (mmBtu/mmBtu)
  xNH3Exports::VariableArray{1} = ReadDisk(db,"SpInput/xNH3Exports",year) # [Area] Ammonia Exports (TBtu)
  ZeroFr::VariableArray{3} = ReadDisk(db,"SInput/ZeroFr",year) # [FuelEP,Poll,Area]
  
  #
  # Scratch Variables
  #
  CgCC::VariableArray{2} = zeros(Float32,length(Fuel),length(Area)) # [Fuel,Area] Cogeneration Capital Costs ($/KW)
  H2CapAvailable::VariableArray{1} = zeros(Float32,length(Area)) # [Area]
  H2CapTotal::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Hydrogen Production Total Capacity (TBtu/Yr)
  H2DemandMAW::VariableArray{1} = zeros(Float32,length(Nation)) # [Nation] Hydrogen Domestic Demand Market Allocation Weight (DLess)
  H2ExportsMAW::VariableArray{1} = zeros(Float32,length(Nation)) # [Nation] Hydrogen Exports Market Allocation Weight (DLess)
  H2ImportsMAW::VariableArray{1} = zeros(Float32,length(Nation)) # [Nation] Hydrogen Imports Market Allocation Weight (DLess)
  H2MAW::VariableArray{2} = zeros(Float32,length(H2Tech),length(Area)) # [H2Tech,Area] Hydrogen Market Share Allocation Weight (mmBtu/mmBtu)
  H2MCEMin::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Minimum Hydrogen Levelized Marginal Cost ($/mmBtu)
  H2SqDmd::VariableArray{2} = zeros(Float32,length(H2Tech),length(Area)) # [H2Tech,Area]
  H2SqDmdFuelEP::VariableArray{3} = zeros(Float32,length(FuelEP),length(H2Tech),length(Area)) # [FuelEP,H2Tech,Area]
  H2SupplyMAW::VariableArray{1} = zeros(Float32,length(Nation)) # [Nation] Hydrogen Domestic Supply Market Allocation Weight (DLess)
  H2TAW::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Hydrogen Market Share Total Allocation Weight (mmBtu/mmBtu)
  NH3CapAvailable::VariableArray{1} = zeros(Float32,length(Area)) #[Area] Ammonia Production Capacity Available
  NH3CapTotal::VariableArray{1} = zeros(Float32,length(Area)) #[Area] Ammonia Production Total Capacity
  NH3MAW::VariableArray{2} = zeros(Float32,length(H2Tech),length(Area)) # [H2Tech,Area] Hydrogen Market Share Allocation Weight (mmBtu/mmBtu)
  NH3TAW::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Hydrogen Market Share Total Allocation Weight (mmBtu/mmBtu)
end

#
# Hydrogen Demand, Imports, Exports, and Production Target
#
function Demands(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuel,Nations) = data
  (; ANMap,H2Dem,H2DemNation,NGDem,NGDemNation,NH3Dem) = data
  (; NH3DemNation,NH3H2Yield,TotDemand,TotDemandPrior,xNH3Exports) = data

  #
  # Demands excluding Electruc Utility Demands
  #
  eccs = Select(ECC,!=("UtilityGen"))
  fuel = Select(Fuel,"Hydrogen")  
  for area in Areas
    H2Dem[area] = sum(TotDemand[fuel,ecc,area] for ecc in eccs)
  end  
  fuel = Select(Fuel,"Ammonia")
  for area in Areas
    NH3Dem[area] = sum(TotDemand[fuel,ecc,area] for ecc in eccs)+xNH3Exports[area]
  end
  fuels = Select(Fuel,["NaturalGas","RNG"])
  for area in Areas
    NGDem[area] = sum(TotDemand[fuel,ecc,area] for ecc in eccs, fuel in fuels)
  end

  #
  # Add in Electric Utility Demands from Previous Year
  #
  ecc = Select(ECC,"UtilityGen")
  fuel = Select(Fuel,"Hydrogen")  
  for area in Areas
    H2Dem[area] = H2Dem[area]+TotDemandPrior[fuel,ecc,area]
  end
  fuel = Select(Fuel,"Ammonia") 
  for area in Areas
    NH3Dem[area] = NH3Dem[area]+TotDemandPrior[fuel,ecc,area]
  end
  fuels = Select(Fuel,["NaturalGas","RNG"])
  for area in Areas
    NGDem[area] = NGDem[area]+sum(TotDemandPrior[fuel,ecc,area] for fuel in fuels)
  end
  
  #
  # Increase Hydrogen Demand by the the amount of Hydrogen needed to produce Ammonia
  #
  for area in Areas
    @finite_math H2Dem[area] = H2Dem[area]+NH3Dem[area]/NH3H2Yield
  end 
  
  for nation in Nations
    H2DemNation[nation] = sum(H2Dem[area]*ANMap[area,nation] for area in Areas)
    NH3DemNation[nation] = sum(NH3Dem[area]*ANMap[area,nation] for area in Areas)
    NGDemNation[nation] = sum(H2Dem[area]*ANMap[area,nation] for area in Areas)
  end
  
  WriteDisk(db,"SpOutput/H2Dem",year,H2Dem)
  WriteDisk(db,"SpOutput/NH3Dem",year,NH3Dem)
  WriteDisk(db,"SpOutput/NGDem",year,NGDem)
  WriteDisk(db,"SpOutput/H2DemNation",year,H2DemNation)
  WriteDisk(db,"SpOutput/NH3DemNation",year,NH3DemNation)
  WriteDisk(db,"SpOutput/NGDemNation",year,NGDemNation)
end

function DemandGrowthRate(data::Data)
  (; db,Nation,year) = data
  (; H2DemGR,H2DemNation,H2DemSm,H2DemSmPrior,H2SmT) = data

  ##@. @finite_math H2DemSm = H2DemSmPrior+(H2DemNation-H2DemSmPrior)/H2SmT

  ##WriteDisk(db,"SpOutput/H2DemSm",year,H2DemSm)

  ##@. @finite_math H2DemGR = (H2DemNation/H2DemSm-1)/H2SmT

  ##WriteDisk(db,"SpInput/H2DemGR",year,H2DemGR)
end

function ImportsExportsPrices(data::Data)
  (; db,year) = data
  (; H2ENPN,H2ENPNExports,H2ENPNImports,H2ExportsCharge,H2ImportsCharge,InflationNation) = data

  ##@. H2ENPNImports = max(H2ENPN+H2ImportsCharge*InflationNation,0.05)
  ##@. H2ENPNExports = max(H2ENPN-H2ExportsCharge*InflationNation,0.05)

  ##WriteDisk(db,"SpOutput/H2ENPNImports",year,H2ENPNImports)
  ##WriteDisk(db,"SpOutput/H2ENPNExports",year,H2ENPNExports)
end

function MarketShareImportsExports(data::Data)
  # @info "  SpHydrogen.jl - Market Share Imports Exports"

  (; db,year) = data
  (; H2DemandMAW,H2DemandMSM0,H2ENPN,H2ENPN0,H2ENPNExports,H2ENPNExports0,H2ENPNImports,H2ENPNImports0) = data
  (; H2ExportsMAW,H2ExportsMSF,H2ExportsMSM0,H2ExportsVF,H2ImportsMAW) = data
  (; H2ImportsMSF,H2ImportsMSM0,H2ImportsVF,H2SupplyMAW,H2SupplyMSM0) = data

  ##@. @finite_math H2ImportsMAW = exp(H2ImportsMSM0+H2ImportsVF*log(H2ENPNImports/H2ENPNImports0))
  ##@. @finite_math H2DemandMAW = exp(H2DemandMSM0 +H2ImportsVF*log(H2ENPN/H2ENPN0))
  ##@. @finite_math H2ImportsMSF = H2ImportsMAW/(H2ImportsMAW+H2DemandMAW)

  ##@. @finite_math H2ExportsMAW = exp(H2ExportsMSM0+H2ExportsVF*log(H2ENPNExports/H2ENPNExports0))
  ##@. @finite_math H2SupplyMAW = exp(H2SupplyMSM0+H2ExportsVF*log(H2ENPN/H2ENPN0))
  ##@. @finite_math H2ExportsMSF = H2ExportsMAW/(H2ExportsMAW+H2SupplyMAW)

  ##WriteDisk(db,"SpOutput/H2ImportsMSF",year,H2ImportsMSF)
  ##WriteDisk(db,"SpOutput/H2ExportsMSF",year,H2ExportsMSF)
end

function EstimateImportsExports(data::Data)
  (; db,year) = data
  (; Areas,Nations) = data
  (;ANMap,H2ImportsEst,H2DemNation,H2ImportsMSF,H2ExportsEst,H2ProdNationPrior) = data
  (;H2ExportsMSF,NH3H2Yield,xNH3Exports) = data

  ##@. H2ImportsEst = H2DemNation*H2ImportsMSF
  ##@. H2ExportsEst = H2ProdNationPrior*H2ExportsMSF
  ##for nation in Nations
  ##  @finite_math H2ExportsEst[nation] = H2ExportsEst[nation]+
  ##    sum(xNH3Exports[area]*ANMap[area,nation] for area in Areas)/NH3H2Yield
  ##end

  ##WriteDisk(db,"SpOutput/H2ImportsEst",year,H2ImportsEst)
  ##WriteDisk(db,"SpOutput/H2ExportsEst",year,H2ExportsEst)
end

function ProductionTarget(data::Data)
  (; db,year) = data
  (; Areas,Nations) = data
  (; ANMap,H2CD,H2Dem,H2DemGR,H2DemNation,H2ExportsEst,H2ImportsEst,H2ProdTarget,H2ProdTargetN) = data
  (; NH3Dem,NH3DemNation,NH3H2Yield,NH3ProdTarget,NH3ProdTargetN,xNH3Exports) = data
  
  ##@. H2ProdTargetN = (H2DemNation*(1+H2DemGR*max(1.0,H2CD/2))-H2ImportsEst)+H2ExportsEst
  ##@. NH3ProdTargetN = NH3DemNation*(1+H2DemGR*max(1.00,H2CD/2))-H2ImportsEst+H2ExportsEst
  
  #
  # TODO - check units in NH3 - Jeff Amlin 9/19/25
  #
  @. H2ProdTarget = H2Dem
  @. NH3ProdTarget = NH3Dem

  # for area in Areas
  #   @finite_math H2ProdTarget[area] = sum(H2Dem[area]*H2ProdTargetN[nation]/
  #                H2DemNation[nation]*ANMap[area,nation] for nation in Nations)
  #   @finite_math NH3ProdTarget[area] = sum(((NH3Dem[area]+xNH3Exports[area])/NH3H2Yield)*
  #                NH3ProdTargetN[nation]/NH3DemNation[nation]*ANMap[area,nation] 
  #                for nation in Nations)
  # end
  
  ##WriteDisk(db,"SpOutput/H2ProdTargetN",year,H2ProdTargetN)
  ##WriteDisk(db,"SpOutput/NH3ProdTargetN",year,H2ProdTargetN)
  WriteDisk(db,"SpOutput/H2ProdTarget",year,H2ProdTarget)
  WriteDisk(db,"SpOutput/NH3ProdTarget",year,H2ProdTarget)
end

function FuelPrices(data::Data)
  (; db,year) = data
  (; Areas,ES,Fuels,H2Tech,H2Techs,Plants,Powers) = data
  (; FPF,H2DmFrac,H2ECFP,H2FsPrice,H2FsFrac) = data
  (; H2PlantMap,H2IPMultiplier,Inflation,MCE) = data

  es = Select(ES,"Industrial")
  for area in Areas,h2tech in H2Techs
    H2ECFP[h2tech,area] = sum(FPF[fuel,es,area]*H2DmFrac[fuel,h2tech,area] for fuel in Fuels)
    H2ECFP[h2tech,area] = min(H2ECFP[h2tech,area],250.0*Inflation[area])
  end

  Renewables = Select(H2Tech,["OnshoreWind","SolarPV"])
  for area in Areas,h2tech in Renewables
    H2ECFP[h2tech,area] = sum(MCE[plant,power,area]*H2PlantMap[h2tech,plant,power,area]
                          for power in Powers,plant in Plants)
    H2ECFP[h2tech,area] = min(H2ECFP[h2tech,area],50.0*Inflation[area])
  end

  h2tech = Select(H2Tech,"Interruptible")
  for area in Areas
    H2ECFP[h2tech,area] = H2ECFP[h2tech,area]*H2IPMultiplier[h2tech,area]
  end

  es = Select(ES,"Industrial")
  for area in Areas,h2tech in H2Techs
    H2FsPrice[h2tech,area] = sum(FPF[fuel,es,area]*H2FsFrac[fuel,h2tech,area] for fuel in Fuels)
  end

  #
  # CFS - need to increase H2ECFP by EI times CFS credit price
  #

  WriteDisk(db,"SpOutput/H2ECFP",year,H2ECFP)
  WriteDisk(db,"SpOutput/H2FsPrice",year,H2FsPrice)

  #
  # CFS - need to add new variable which is H2FsPrice EI times CFS credit price
  #

end

#
# ***********************
#
# CFS - add procedure for H2Eff as a function of H2ECFP plus EI times CFS credit price
# CFS - add equations for H2FsYield as a function of H2FsPrice plus EI times CFS credit price
#
# ***********************
#

function CapitalCosts(data::Data)
  (; db, year) = data
  (; Areas, H2Techs) = data
  (; H2CC, H2CCN, H2CCM, Inflation) = data
  (; NH3CC, NH3CCN, NH3CCM) = data
  
  for area in Areas, h2tech in H2Techs
    H2CC[h2tech, area] = H2CCN[h2tech, area] * H2CCM[h2tech, area] * Inflation[area]
    NH3CC[h2tech, area] = NH3CCN[h2tech, area] * NH3CCM[h2tech, area] * Inflation[area]
  end
  
  WriteDisk(db, "SpOutput/H2CC", year, H2CC)
  WriteDisk(db, "SpOutput/NH3CC", year, NH3CC)
end

function GHGEmissionIntensity(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuel,Fuels,FuelEPs,H2Tech,H2Techs,Poll) = data
  (; FFPMap,H2EIDmd,H2EIDmdFuel,H2EIFs,H2EIFsFuel,H2POCX,H2DmFrac,H2SqFr,PolConv,H2FsPOCX,H2FsFrac) = data
  (; H2EI,H2EIDmd,H2Eff,H2EIFs,H2FsYield,H2IPMultiplier,H2SqEI,H2SqEIDmd,H2SqEIDmdFuel,H2SqEIFs,H2SqEIFsFuel,ZeroFr) = data

  CO2 = Select(Poll,"CO2")
  GHG = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  UtilityGen = Select(ECC,"UtilityGen")

  for fuel in Fuels
    if Fuel[fuel] != "Electric"
      for fuelep in FuelEPs
        if FFPMap[fuelep,fuel] == 1
          for area in Areas,h2tech in H2Techs
          
            H2EIDmdFuel[fuel,h2tech,area] = sum(H2POCX[fuelep,poll,area]*
            (1-ZeroFr[fuelep,poll,area]-H2SqFr[h2tech,poll,area])*PolConv[poll] for poll in GHG)
            
            H2EIFsFuel[fuel,h2tech,area] = sum(H2FsPOCX[fuelep,poll,area]*
            (1-ZeroFr[fuelep,poll,area]-H2SqFr[h2tech,poll,area])*PolConv[poll] for poll in GHG)

            H2SqEIDmdFuel[fuel,h2tech,area] = sum(H2POCX[fuelep,poll,area]*
              H2SqFr[h2tech,poll,area]*PolConv[poll] for poll in CO2)
              
            H2SqEIFsFuel[fuel,h2tech,area] = sum(H2FsPOCX[fuelep,poll,area]*
              H2SqFr[h2tech,poll,area]*PolConv[poll] for poll in CO2)
              
          end
        end
      end
    else
      for area in Areas, h2tech in H2Techs
        H2EIDmdFuel[fuel,h2tech,area] = 0.00
        H2EIFsFuel[fuel,h2tech,area] = 0.00
        H2SqEIDmdFuel[fuel,h2tech,area] = 0.00
        H2SqEIFsFuel[fuel,h2tech,area] = 0.00
      end
    end
  end

  WriteDisk(db,"SpOutput/H2EIDmdFuel",year,H2EIDmdFuel)
  WriteDisk(db,"SpOutput/H2EIFsFuel",year,H2EIFsFuel)
  WriteDisk(db,"SpOutput/H2SqEIDmdFuel",year,H2SqEIDmdFuel)
  WriteDisk(db,"SpOutput/H2SqEIFsFuel",year,H2SqEIFsFuel)

  for area in Areas,h2tech in H2Techs
    @finite_math H2EIDmd[h2tech,area] = sum(H2EIDmdFuel[fuel,h2tech,area]*
      H2DmFrac[fuel,h2tech,area] for fuel in Fuels)/H2Eff[h2tech,area]
  end

  WriteDisk(db,"SpOutput/H2EIDmd",year,H2EIDmd)
  for area in Areas,h2tech in H2Techs
    @finite_math H2SqEIDmd[h2tech,area] = sum(H2SqEIDmdFuel[fuel,h2tech,area]*
      H2DmFrac[fuel,h2tech,area] for fuel in Fuels)/H2Eff[h2tech,area]
  end

  WriteDisk(db,"SpOutput/H2SqEIDmd",year,H2SqEIDmd)

  for area in Areas,h2tech in H2Techs
    @finite_math H2EIFs[h2tech,area] = sum(H2EIFsFuel[fuel,h2tech,area]*
      H2FsFrac[fuel,h2tech,area] for fuel in Fuels)/H2FsYield[h2tech,area]
  end

  WriteDisk(db,"SpOutput/H2EIFs",year,H2EIFs)

  for area in Areas,h2tech in H2Techs
    @finite_math H2SqEIFs[h2tech,area] = sum(H2SqEIFsFuel[fuel,h2tech,area]*
      H2FsFrac[fuel,h2tech,area] for fuel in Fuels)/H2FsYield[h2tech,area]
  end

  WriteDisk(db,"SpOutput/H2SqEIDmd",year,H2SqEIDmd)

  #
  #  Emission Intensity
  #
  @. H2EI = H2EIDmd+H2EIFs
  @. H2SqEI = H2SqEIDmd+H2SqEIFs

  WriteDisk(db,"SpOutput/H2EI",year,H2EI)
  WriteDisk(db,"SpOutput/H2SqEI",year,H2SqEI)
end

function EmissionCosts(data::Data)
  (; db,year) = data
  (; Areas,ECC,H2Techs,Poll,PCov) = data
  (; H2EIDmd,H2EIFs,H2EmissionCost,H2FsEmissionCost,PCost,ECoverage,H2DmdEmissionCost) = data

  ecc = Select(ECC,"H2Production")
  poll = Select(Poll,"CO2")
  pcov = Select(PCov,"Energy")
  for area in Areas,h2tech in H2Techs
    H2DmdEmissionCost[h2tech,area] = H2EIDmd[h2tech,area]*
    PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]/1.0e6
  end
  poll = Select(Poll,"CO2")
  pcov = Select(PCov,"NonCombustion")
  for area in Areas,h2tech in H2Techs
    H2FsEmissionCost[h2tech,area] = H2EIFs[h2tech,area]*
    PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area]/1.0e6
  end

  @. H2EmissionCost = H2DmdEmissionCost+H2FsEmissionCost

  WriteDisk(db,"SpOutput/H2DmdEmissionCost",year,H2DmdEmissionCost)
  WriteDisk(db,"SpOutput/H2FsEmissionCost",year,H2FsEmissionCost)
  WriteDisk(db,"SpOutput/H2EmissionCost",year,H2EmissionCost)
end

function MarginalCost(data::Data)
  (; db,year) = data
  (; Areas,H2Techs) = data
  (; H2FuelCost,H2ECFP,H2Eff,H2FeedstockCost,H2FsPrice,H2FsYield,H2VOMCost,H2UOMC,Inflation) = data
  (; H2FOMCost,H2CC,H2OF,H2TransCost,H2Trans,Inflation,Inflation2016) = data
  (; H2VC,H2FuelCost,H2FeedstockCost,H2EmissionCost,H2VOMCost,H2TransCost) = data
  (; H2MCE,H2CCR,H2CC,H2FOMCost,H2CUFP,H2SqEI,H2SqTransStorageCost,H2VC,SqTransStorageCost) = data
  (; NH3Eff,NH3FuelCost,NH3UOMC,NH3VOMCost) = data
  (; NH3CC, NH3OF, NH3FOMCost, NH3CUFP) = data
  (; NH3VC, NH3MCE) = data


  @. H2FuelCost = H2ECFP*finite_inverse(H2Eff)
  @. H2FeedstockCost = H2FsPrice*finite_inverse(H2FsYield)

  for area in Areas, h2tech in H2Techs
    H2VOMCost[h2tech,area] = H2UOMC[h2tech,area]*Inflation[area]
  end

  @. H2FOMCost = H2CC*H2OF

  for area in Areas, h2tech in H2Techs
    H2TransCost[h2tech,area] = H2Trans[h2tech,area]*Inflation[area]
  end

  for area in Areas, h2tech in H2Techs
    @finite_math H2SqTransStorageCost[h2tech,area] = H2SqEI[h2tech,area]*SqTransStorageCost[area]/
      Inflation2016[area]*Inflation[area]/1e6
  end

  @. H2VC = H2FuelCost+H2FeedstockCost+H2EmissionCost+H2VOMCost+H2TransCost+H2SqTransStorageCost
  @. @finite_math H2MCE = (H2CCR*H2CC+H2FOMCost)/H2CUFP+H2VC
  
  # NH3 calculations
  for area in Areas, h2tech in H2Techs
    @finite_math NH3FuelCost[h2tech, area] = H2ECFP[h2tech, area] / NH3Eff[h2tech, area]
    NH3VOMCost[h2tech, area] = NH3UOMC[h2tech, area] * Inflation[area]
    NH3FOMCost[h2tech, area] = NH3CC[h2tech, area] * NH3OF[h2tech, area]
  end

  WriteDisk(db,"SpOutput/H2FuelCost",year,H2FuelCost)
  WriteDisk(db,"SpOutput/H2FeedstockCost",year,H2FeedstockCost)
  WriteDisk(db,"SpOutput/H2VOMCost",year,H2VOMCost)
  WriteDisk(db,"SpOutput/H2FOMCost",year,H2FOMCost)
  WriteDisk(db,"SpOutput/H2TransCost",year,H2TransCost)
  WriteDisk(db,"SpOutput/H2VC",year,H2VC)
  WriteDisk(db,"SpOutput/H2MCE",year,H2MCE)
  
  WriteDisk(db, "SpOutput/NH3FuelCost", year, NH3FuelCost)
  WriteDisk(db, "SpOutput/NH3VOMCost", year, NH3VOMCost)
  WriteDisk(db, "SpOutput/NH3FOMCost", year, NH3FOMCost)
  
  # Emission costs look very small for Ammonia, so ignoring for now PNV 2024.04.17
  # TODO - review incorporating emissions costs since emissions costs may be negative
  # or life-cycle emissions - Jeff Amlin 12/12/24
  
  for area in Areas, h2tech in H2Techs
    NH3VC[h2tech, area] = NH3FuelCost[h2tech, area]+NH3VOMCost[h2tech, area]
    
    @finite_math NH3MCE[h2tech,area] =
      (H2CCR[h2tech,area]*(H2CC[h2tech,area]+NH3CC[h2tech,area])+ 
      H2FOMCost[h2tech,area]+NH3FOMCost[h2tech,area])/ 
      NH3CUFP[h2tech,area]+H2VC[h2tech,area]+NH3VC[h2tech,area]
  end
  
  WriteDisk(db, "SpOutput/H2MCE", year, H2MCE)
  WriteDisk(db, "SpOutput/H2VC", year, H2VC)
  WriteDisk(db, "SpOutput/NH3MCE", year, NH3MCE)
  WriteDisk(db, "SpOutput/NH3VC", year, NH3VC)
  
end

function MarketShare(data::Data)
  (; db,year) = data
  (; Areas,H2Tech,H2Techs) = data
  (; H2MAW,H2MSM0,H2VF,H2MCE,H2MCEMin,H2MSF,H2TAW,H2MSFSwitch,xH2MSF) = data
  (; NH3MAW,NH3MSM0,NH3MCE,NH3TAW,NH3MSF) = data

  #
  # Trap so H2MCE is positive
  #
  @. H2MCE = max(H2MCE,1.0)

  h2techs = Select(H2Tech,!=("Other"))
  for area in Areas
    H2MCEMin[area] = minimum(H2MCE[h2tech,area] for h2tech in h2techs)
  end

  for area in Areas,h2tech in H2Techs
    @finite_math H2MAW[h2tech,area] = exp(H2MSM0[h2tech,area]+
                 H2VF[h2tech,area]*log(H2MCE[h2tech,area]/H2MCEMin[area]))
  end

  for area in Areas
    H2TAW[area] = sum(H2MAW[h2tech,area] for h2tech in H2Techs)
  end

  for area in Areas,h2tech in H2Techs
    @finite_math H2MSF[h2tech,area] = H2MAW[h2tech,area]/H2TAW[area]
  end
  #
  # TODO - we can restrict the H2Tech for the NH3 market share using NH3MSM0 - Jeff Amlin 12/12/24
  #
  @. NH3MAW = 0
  h2techs = Select(H2Tech,["Grid","NGCCS","ATRNGCCS","OnshoreWind","SolarPV"])
  for area in Areas,h2tech in h2techs
    @finite_math NH3MAW[h2tech,area] = exp(NH3MSM0[h2tech,area]+
                 H2VF[h2tech,area]*log(NH3MCE[h2tech,area]/H2MCEMin[area]))
  end

  for area in Areas
    NH3TAW[area] = sum(NH3MAW[h2tech,area] for h2tech in H2Techs)
  end

  for area in Areas,h2tech in H2Techs
    @finite_math NH3MSF[h2tech,area] = NH3MAW[h2tech,area]/NH3TAW[area]
  end
  #
  # TODO - should the H2 market share be
  # the market share for H2 production for H2 sold directly plus
  # the market share for NH3 which is H2 produced for NH3? - Jeff Amlin 12/12/24
  #
    for area in Areas,h2tech in H2Techs
    if H2MSFSwitch[area] == 0.0
      H2MSF[h2tech,area] = xH2MSF[h2tech,area]
    end
  end
  WriteDisk(db,"SpOutput/H2MSF",year,H2MSF)
  WriteDisk(db,"SpOutput/NH3MSF",year,NH3MSF)
end

function CapacityRetirementRate(data::Data)
  (; db,year) = data
  (; Areas,H2Techs) = data
  (; H2CapRR,H2CapPrior,H2PL) = data
  (; NH3CapRR,NH3CapPrior) = data
  
  # Write ("CapacityRetirementRate in SpHydrogen.src")
  
  for area in Areas,h2tech in H2Techs
    @finite_math H2CapRR[h2tech,area] = H2CapPrior[h2tech,area]/H2PL[h2tech]
    @finite_math NH3CapRR[h2tech,area] = NH3CapPrior[h2tech,area]/H2PL[h2tech]
  end
  
  WriteDisk(db,"SpOutput/H2CapRR",year,H2CapRR)
  WriteDisk(db,"SpOutput/NH3CapRR",year,NH3CapRR)
end
  
function CapacityIndicated(data::Data)
  (; db,year) = data
  (; Areas,H2Techs) = data
  (; H2CapAvailable,H2CapI,H2CapPrior,H2CapRR,H2ProdTarget,H2MSF,H2CUFP) = data
  (; NH3CapAvailable,NH3CapPrior,NH3CapRR) = data
  (; NH3ProdTarget,NH3MSF,NH3CUFP,NH3CapI) = data
  (; NH3H2Yield) = data


  for area in Areas
    H2CapAvailable[area] = sum(H2CapPrior[h2tech,area]-H2CapRR[h2tech,area] for h2tech in H2Techs)
    NH3CapAvailable[area] = sum(NH3CapPrior[h2tech,area]-NH3CapRR[h2tech,area] for h2tech in H2Techs)
  end

  for area in Areas,h2tech in H2Techs
    
    @finite_math H2CapI[h2tech,area] = max(H2ProdTarget[area]-H2CapAvailable[area],0.0)*
                          H2MSF[h2tech,area]/H2CUFP[h2tech,area]
    
    @finite_math NH3CapI[h2tech,area] = max(NH3ProdTarget[area]-NH3CapAvailable[area],0)* 
                           NH3MSF[h2tech,area]/NH3CUFP[h2tech,area]
   
  end

  #
  # Is this still an issue once we revise the demand calculation? - Jeff Amlin 1/17/25
  # SurifetCapacity = NH3CapI - H2CapI
  # SurifetCapacity > 0 indicated not enough investment in H2. Address this by reallocating H2CapI across H2Techs
  #  
  # for area in Areas,h2tech in H2Techs
  #   H2CapI[h2tech,area] = max(H2CapI[h2tech,area],NH3CapI[h2tech,area]/NH3H2Yield)
  # end

  WriteDisk(db,"SpOutput/H2CapI",year,H2CapI)
  WriteDisk(db,"SpOutput/NH3CapI",year,NH3CapI)
end

function CapacityCompletionRate(data::Data)
  (; db,year) = data
  (; Areas,H2Techs) = data
  (; H2CapCR,H2CapI,H2CD,NH3CapCR,NH3CapI) = data

  for area in Areas,h2tech in H2Techs
    @finite_math H2CapCR[h2tech,area] = H2CapI[h2tech,area]/H2CD
    @finite_math NH3CapCR[h2tech,area] = NH3CapI[h2tech,area]/H2CD
  end
  
  WriteDisk(db,"SpOutput/H2CapCR",year,H2CapCR)
  WriteDisk(db,"SpOutput/NH3CapCR",year,NH3CapCR)
end

function ProductionCapacity(data::Data)
  (; db,year) = data
  (; H2Cap,H2CapPrior,H2CapCR,H2CapRR) = data
  (; NH3Cap,NH3CapPrior,NH3CapCR,NH3CapRR) = data

  @. H2Cap = H2CapPrior+DT*(H2CapCR-H2CapRR)
  @. NH3Cap = NH3CapPrior+DT*(NH3CapCR-NH3CapRR)

  WriteDisk(db,"SpOutput/H2Cap",year,H2Cap)
  WriteDisk(db,"SpOutput/NH3Cap",year,NH3Cap)
end

function Production(data::Data)
  (; db,year) = data
  (; Areas,H2Techs,Nations) = data
  (; H2Dem,H2ProdNation,H2Prod,ANMap,H2CapTotal,H2Cap,H2CUFP,H2ProdTarget) = data
  (; H2CUFMax,H2CUF,H2Production) = data
  (; NH3Dem,NH3ProdNation,NH3Prod,NH3CapTotal,NH3Cap,NH3CUFP,NH3ProdTarget) = data
  (; NH3CUFMax,NH3CUF,NH3Production) = data

  for area in Areas
    H2CapTotal[area] = sum(H2Cap[h2tech,area]*H2CUFP[h2tech,area] for h2tech in H2Techs)
  end

  #
  # Remove constraints on capacity factors so we always exactly
  # meet demand - Jeff Amlin 9/19/25
  #
  for area in Areas, h2tech in H2Techs
    @finite_math H2CUF[h2tech,area] = H2CUFP[h2tech,area]*H2Dem[area]/H2CapTotal[area]
  end
  @. H2Prod = H2Cap*H2CUF

  # for area in Areas, h2tech in H2Techs
  #   @finite_math H2Prod[h2tech,area] = min(
  #     H2Cap[h2tech,area]*H2CUFP[h2tech,area]*H2ProdTarget[area]/H2CapTotal[area],
  #     H2Cap[h2tech,area]*H2CUFMax[area])
  # end
  # @. @finite_math H2CUF = H2Prod/H2Cap

  for area in Areas
    H2Production[area] = sum(H2Prod[h2tech,area] for h2tech in H2Techs)
  end

  for nation in Nations
    H2ProdNation[nation] = sum(H2Prod[h2tech,area]*ANMap[area,nation]
                               for area in Areas,h2tech in H2Techs)
  end
  
  WriteDisk(db,"SpOutput/H2Prod",year,H2Prod)
  WriteDisk(db,"SpOutput/H2CUF",year,H2CUF)
  WriteDisk(db,"SpOutput/H2Production",year,H2Production)
  WriteDisk(db,"SpOutput/H2ProdNation",year,H2ProdNation)

  for area in Areas
    NH3CapTotal[area] = sum(NH3Cap[h2tech,area]*NH3CUFP[h2tech,area] for h2tech in H2Techs)
  end
  
  #
  # Remove constraints on capacity factors so we always exactly
  # meet demand - Jeff Amlin 9/19/25
  #
  for area in Areas, h2tech in H2Techs
    @finite_math NH3CUF[h2tech,area] = NH3CUFP[h2tech,area]*NH3Dem[area]/NH3CapTotal[area]
  end
  @. NH3Prod = NH3Cap*NH3CUF  
  
  # for area in Areas,h2tech in H2Techs
  #   @finite_math NH3Prod[h2tech,area] = min(
  #     NH3Cap[h2tech,area]*NH3CUFP[h2tech,area]*NH3ProdTarget[area]/NH3CapTotal[area],
  #     NH3Cap[h2tech,area]*NH3CUFMax[area])
  #  end
  # @. @finite_math NH3CUF = NH3Prod/NH3Cap

  for area in Areas
    NH3Production[area] = sum(NH3Prod[h2tech,area] for h2tech in H2Techs)
  end

  for nation in Nations
    NH3ProdNation[nation] = sum(NH3Prod[h2tech,area]*ANMap[area,nation]
                               for area in Areas,h2tech in H2Techs)
  end
  
  WriteDisk(db,"SpOutput/NH3Prod",year,NH3Prod)
  WriteDisk(db,"SpOutput/NH3CUF",year,NH3CUF)
  WriteDisk(db,"SpOutput/NH3Production",year,NH3Production)
  WriteDisk(db,"SpOutput/NH3ProdNation",year,NH3ProdNation)
end

function ImportsExports(data::Data)
  (; db,year) = data
  (; Areas,Nations,Fuel,FuelEP) = data
  (; ANMap,Exports,ExportsArea,ExportsFuel) = data
  (; H2Imports,H2DemNation,H2ProdNation,H2ExportsEst,H2Exports) = data
  (; Imports,ImportsArea,ImportsFuel) = data  
  (; NH3Imports,NH3DemNation,NH3ProdNation,NH3Exports,xNH3Exports) = data

  #
  # Hydrogen Imports and Exports
  # Current assumption is for all imported and exports Hydrogen
  # is transported as Ammonia, so Hydrogen Import and Export
  # variables are all zero. - Jeff Amlin 2/23/26
  #
  
  fuel = Select(Fuel,"Hydrogen")
  fuelep = Select(FuelEP,"Hydrogen")  
  #
  # @. H2Imports = max(H2DemNation-H2ProdNation+H2ExportsEst,0.0)
  # @. H2Exports = max(H2ProdNation-H2DemNation+H2Imports,0.0)
  #

  for nation in Nations
    H2Imports[nation] = 0.0
    H2Exports[nation] = 0.0
    Imports[fuelep,nation] = 0.0
    Exports[fuelep,nation] = 0.0   
    ImportsFuel[fuel,nation] = 0.0
    ExportsFuel[fuel,nation] = 0.0       
  end
  
  for area in Areas
    ImportsArea[fuel,area] = 0.0
    ExportsArea[fuel,area] = 0.0
  end
  
  #
  # Ammonia Exports are vehicles to carry Hydrogen and exogenous.
  # Ammonia Imports are assumed to be zero - Jeff Amlin 2/23/26
  #
  fuel = Select(Fuel,"Ammonia")
  fuelep = Select(FuelEP,"Ammonia")   
  
  # @. NH3Imports = max(NH3DemNation-NH3ProdNation+H2ExportsEst,0.0)
  # @. NH3Exports = max(NH3ProdNation-NH3DemNation+NH3Imports,0.0)
  
  for area in Areas
    ImportsArea[fuel,area] = 0.0
    ExportsArea[fuel,area] = xNH3Exports[area]
  end
  
  for nation in Nations
    areas = Select(ANMap[Areas,nation],==(1))   
    NH3Imports[nation] = sum(ImportsArea[fuel,area] for area in areas)
    NH3Exports[nation] = sum(ExportsArea[fuel,area] for area in areas)
    Imports[fuelep,nation] = sum(ImportsArea[fuel,area] for area in areas)
    Exports[fuelep,nation] = sum(ExportsArea[fuel,area] for area in areas) 
    ImportsFuel[fuel,nation] = sum(ImportsArea[fuel,area] for area in areas)
    ExportsFuel[fuel,nation] = sum(ExportsArea[fuel,area] for area in areas)      
  end
  
  WriteDisk(db,"SpOutput/Exports",year,Exports)
  WriteDisk(db,"SpOutput/ExportsArea",year,ExportsArea)  
  WriteDisk(db,"SpOutput/ExportsFuel",year,ExportsFuel)  
  WriteDisk(db,"SpOutput/H2Exports",year,H2Exports)
  WriteDisk(db,"SpOutput/H2Imports",year,H2Imports)
  WriteDisk(db,"SpOutput/Imports",year,Imports)
  WriteDisk(db,"SpOutput/ImportsArea",year,ImportsArea)
  WriteDisk(db,"SpOutput/ImportsFuel",year,ImportsFuel)
  WriteDisk(db,"SpOutput/NH3Exports",year,NH3Exports)
  WriteDisk(db,"SpOutput/NH3Imports",year,NH3Imports)
  
end



function EnergyUsage(data::Data)
  (; db,year) = data
  (; Areas,H2Techs,Fuels) = data
  (; H2Dmd,H2Prod,H2Eff,H2Demand,H2DmFrac) = data

  @. @finite_math H2Dmd = H2Prod/H2Eff

  for area in Areas, h2tech in H2Techs, fuel in Fuels
    H2Demand[fuel,h2tech,area] = H2Dmd[h2tech,area]*H2DmFrac[fuel,h2tech,area]
  end

  WriteDisk(db,"SpOutput/H2Dmd",year,H2Dmd)
  WriteDisk(db,"SpOutput/H2Demand",year,H2Demand)
end

function FeedstockRequired(data::Data)
  (; db,year) = data
  (; Areas,Fuels,H2Techs) = data
  (; H2FsReq,H2Prod,H2FsYield,H2FsDem,H2FsFrac) = data

  for area in Areas, h2tech in H2Techs
    @finite_math H2FsReq[h2tech,area] = H2Prod[h2tech,area]/H2FsYield[h2tech,area]
  end

  for area in Areas, h2tech in H2Techs, fuel in Fuels
    H2FsDem[fuel,h2tech,area] = H2FsReq[h2tech,area]*H2FsFrac[fuel,h2tech,area]
  end

  WriteDisk(db,"SpOutput/H2FsReq",year,H2FsReq)
  WriteDisk(db,"SpOutput/H2FsDem",year,H2FsDem)
end

function NGPipelineEfficiency(data::Data)
  (; db,year) = data
  (; Areas,Nations) = data
  (; ANMap,H2DemNation,NGDemNation,H2PipelineFraction,H2PipelineMultiplier,H2PipeC0,H2PipeA0,H2PipeB0) = data

  for nation in Nations,area in Areas
    if ANMap[area,nation] == 1.0
    
      @finite_math H2PipelineFraction[area] = H2DemNation[nation]/
        (H2DemNation[nation]+NGDemNation[nation])
        
      H2PipelineMultiplier[area] = 1.0+H2PipeC0[area]+
        H2PipeA0[area]*H2PipelineFraction[area]+
        (H2PipeB0[area]*H2PipelineFraction[area])^2.0
    end
  end
  WriteDisk(db,"SpOutput/H2PipelineFraction",year,H2PipelineFraction)
  WriteDisk(db,"SOutput/H2PipelineMultiplier",year,H2PipelineMultiplier)
end

function CombustionEmissions(data::Data)
  (; db,year) = data
  (; Areas,H2Techs,FuelEPs,Polls,Fuels,ECC) = data
  (; EuPol,EuFPol,FFPMap,H2Demand,H2POCX,H2Pol,ZeroFr) = data

  ecc = Select(ECC,"H2Production")

  for area in Areas, poll in Polls, h2tech in H2Techs, fuelep in FuelEPs
    H2Pol[fuelep,h2tech,poll,area] = sum(H2Demand[fuel,h2tech,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels)*H2POCX[fuelep,poll,area]
  end

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EuFPol[fuelep,ecc,poll,area] = sum(H2Pol[fuelep,h2tech,poll,area]
      for h2tech in H2Techs)*(1-ZeroFr[fuelep,poll,area])
  end

  for area in Areas, poll in Polls
    EuPol[ecc,poll,area] = sum(EuFPol[fuelep,ecc,poll,area] for fuelep in FuelEPs)
  end
  
  WriteDisk(db,"SpOutput/H2Pol",year,H2Pol)
  WriteDisk(db,"SOutput/EuFPol",year,EuFPol)
  WriteDisk(db,"SOutput/EuPol",year,EuPol)
end

function FeedstockEmissions(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuels,FuelEPs,H2Techs,Polls) = data
  (; FFPMap,H2FsPol,H2FsDem,H2FsPOCX,NcFPol,NcPol,ZeroFr) = data

  ecc = Select(ECC,"H2Production")

  for area in Areas, poll in Polls, h2tech in H2Techs, fuelep in FuelEPs
    H2FsPol[fuelep,h2tech,poll,area] = sum(H2FsDem[fuel,h2tech,area]*FFPMap[fuelep,fuel]*H2FsPOCX[fuelep,poll,area] for fuel in Fuels)
  end

  for area in Areas, poll in Polls, fuel in Fuels
    NcFPol[fuel,ecc,poll,area] = sum(H2FsPol[fuelep,h2tech,poll,area]*
    (1-ZeroFr[fuelep,poll,area])*FFPMap[fuelep,fuel] for fuelep in FuelEPs,h2tech in H2Techs)
  end

  for area in Areas, poll in Polls
    NcPol[ecc,poll,area] = sum(NcFPol[fuel,ecc,poll,area] for fuel in Fuels)
  end
  
  WriteDisk(db,"SpOutput/H2FsPol",year,H2FsPol)
  WriteDisk(db,"SOutput/NcFPol",year,NcFPol)
  WriteDisk(db,"SOutput/NcPol",year,NcPol)
end

function SequesteredEmissions(data::Data)
  (; db,year) = data
  (; Areas,ECC,FuelEPs,H2Techs,Polls) = data
  (; H2FsPol,H2Pol,H2SqFr,H2SqPol,SqPolCCNet) = data

  ecc = Select(ECC,"H2Production")

  for area in Areas, poll in Polls, h2tech in H2Techs
    H2SqPol[h2tech,poll,area] = (0.0-
      sum((H2Pol[fuelep,h2tech,poll,area]+H2FsPol[fuelep,h2tech,poll,area])
      for fuelep in FuelEPs)*H2SqFr[h2tech,poll,area])
  end

  for area in Areas, poll in Polls
    SqPolCCNet[ecc,poll,area] = sum(H2SqPol[h2tech,poll,area] for h2tech in H2Techs)
  end
  
  WriteDisk(db,"SpOutput/H2SqPol",year,H2SqPol)
  WriteDisk(db,"SOutput/SqPolCCNet",year,SqPolCCNet)
end

function SequesterPenalty(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuels,FuelEPs,H2Techs,Polls) = data
  (; FFPMap,H2DmFrac,H2POCX,H2SqDemand,H2SqDmd,H2SqDmdFuelEP) = data
  (; H2SqPenalty,H2SqPol,H2SqPolPenalty,SqPolPenalty,ZeroFr) = data

  ecc = Select(ECC,"H2Production")

  for area in Areas, h2tech in H2Techs
    H2SqDmd[h2tech,area] = sum(0-H2SqPol[h2tech,poll,area]*H2SqPenalty[h2tech,poll,area] for poll in Polls)
  end

  for area in Areas, h2tech in H2Techs, fuel in Fuels
    H2SqDemand[fuel,h2tech,area] = H2SqDmd[h2tech,area]*H2DmFrac[fuel,h2tech,area]
  end

  WriteDisk(db,"SpOutput/H2SqDemand",year,H2SqDemand)

  for area in Areas, h2tech in H2Techs, fuelep in FuelEPs
     H2SqDmdFuelEP[fuelep,h2tech,area] = sum(H2SqDemand[fuel,h2tech,area]*
       FFPMap[fuelep,fuel] for fuel in Fuels)
  end

  for area in Areas, poll in Polls, h2tech in H2Techs
    H2SqPolPenalty[h2tech,poll,area] = 0-sum(H2SqDmdFuelEP[fuelep,h2tech,area]*
      H2POCX[fuelep,poll,area]*(1-ZeroFr[fuelep,poll,area]) for fuelep in FuelEPs)
  end

  for area in Areas, poll in Polls
    SqPolPenalty[ecc,poll,area] = sum(H2SqPolPenalty[h2tech,poll,area] for h2tech in H2Techs)
  end

  WriteDisk(db,"SOutput/SqPolPenalty",year,SqPolPenalty)

  # Write Disk(SqPolPenalty)

end

function TotalDemands(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuels,H2Techs) = data
  (; CgDemand,EuDemand,FsDemand,H2Demand,H2FsDem,H2SqDemand,TotDemand) = data

  ecc = Select(ECC,"H2Production")

  for area in Areas, fuel in Fuels
    EuDemand[fuel,ecc,area] = sum((H2Demand[fuel,h2tech,area]+H2SqDemand[fuel,h2tech,area]) for h2tech in H2Techs)
  end
  WriteDisk(db,"SOutput/EuDemand",year,EuDemand)

  for area in Areas, fuel in Fuels
    FsDemand[fuel,ecc,area] = sum(H2FsDem[fuel,h2tech,area] for h2tech in H2Techs)
  end
  WriteDisk(db,"SOutput/FsDemand",year,FsDemand)

  for area in Areas, fuel in Fuels
    TotDemand[fuel,ecc,area] = 
      EuDemand[fuel,ecc,area]+FsDemand[fuel,ecc,area]+CgDemand[fuel,ecc,area]
  end
  WriteDisk(db,"SOutput/TotDemand",year,TotDemand)
end

function Investments(data::Data)
  (; db,year) = data
  (; Areas,ECC,ES,Fuels,H2Techs) = data
  (; DOMExp,FuelExpenditures,OMExp,PInv,POMExp,DInv,H2CapCR,H2CC,Inflation) = data
  (; H2VOMCost,H2FOMCost,H2TransCost,H2Prod,H2Dmd,H2ECFP,FsDemand,FsFP) = data

  ecc = Select(ECC,"H2Production")

  #
  # Device Investments
  #
  for area in Areas
    DInv[ecc,area] = 0.0
  end

  #
  # Device O&M Expenditures
  #
  for area in Areas
    DOMExp[ecc,area] = 0.0
  end
  #
  # Process Investments
  #
  for area in Areas
    PInv[ecc,area] = sum(H2CapCR[h2tech,area]*H2CC[h2tech,area]*Inflation[area] for h2tech in H2Techs)
  end

  #
  # Process O&M Expenditures
  #
  for area in Areas
    POMExp[ecc,area] = sum(
      (H2VOMCost[h2tech,area]+H2FOMCost[h2tech,area]+H2TransCost[h2tech,area])*H2Prod[h2tech,area] for
      h2tech in H2Techs)
  end

  #
  # O&M Expenditures
  #
  for area in Areas
    OMExp[ecc,area] = DOMExp[ecc,area]+POMExp[ecc,area]
  end

  #
  # Fuel Expenditures (include Feedstocks which are Natural Gas)
  #
  es = Select(ES,"Industrial")
  for area in Areas
    tmp = sum(FsDemand[fuel,ecc,area]*FsFP[fuel,es,area] for fuel in Fuels)
    FuelExpenditures[ecc,area] = sum(H2Dmd[h2tech,area]*H2ECFP[h2tech,area]+tmp for h2tech in H2Techs)
  end
  
  WriteDisk(db,"SOutput/DInv",year,DInv)
  WriteDisk(db,"SOutput/DOMExp",year,DOMExp)
  WriteDisk(db,"SOutput/PInv",year,PInv)
  WriteDisk(db,"SOutput/POMExp",year,POMExp)
  WriteDisk(db,"SOutput/OMExp",year,OMExp)
  WriteDisk(db,"SOutput/FuelExpenditures",year,FuelExpenditures)
end

function ElectricSalesAndLoads(data::Data)
  (; db,year) = data;
  (; AreaKey,Areas,Days,ECC,ECCKey,Fuel,Fuels,H2Tech,H2Techs,Hours) = data;
  (; Months,Nation,NodeKey,PlantKey,Plants,Power) = data;
  (; ANMap,CgCap,CgCapPrior,CgCC,CgGen,CgInv,CgUnCode,EEConv,GCCC) = data;
  (; H2CUFP,H2Demand,H2DmFrac,H2GridFraction,H2LSF,H2PlantMap,H2SaEC) = data;
  (; LDCECC,SaEC,UnCode,UnEGA,UnGC) = data;

  ecc = Select(ECC,"H2Production")
  fuel = Select(Fuel,"Electric")
  for area in Areas,h2tech in H2Techs
    H2SaEC[h2tech,area] = H2Demand[fuel,h2tech,area]*H2GridFraction[h2tech,area]/EEConv*1.0e6
  end

  for area in Areas
    SaEC[ecc,area] = sum(H2SaEC[h2tech,area] for h2tech in H2Techs)
  end

  for area in Areas,month in Months,day in Days,hour in Hours
    LDCECC[ecc,hour,day,month,area] = 
    (sum(H2SaEC[h2tech,area]*H2LSF[h2tech,hour,day,month,area] for h2tech in H2Techs)/
     8760.0)*1000.0
  end

  Renewables = Select(H2Tech,["OnshoreWind","SolarPV"])
  Base = Select(Power,"Base")

  for area in Areas
    for h2tech in Renewables
      plants = findall(H2PlantMap[h2tech,Plants,Base,area] .== 1)
      fuels = findall(H2DmFrac[Fuels,h2tech,area] .== 1)
      if (!isempty(plants)) && (!isempty(fuels))
        for plant in plants,fuel in fuels
          CgCC[fuel,area] = GCCC[plant,area]
          @finite_math CgGen[fuel,ecc,area] = H2Demand[fuel,h2tech,area]/EEConv*1E6
          @finite_math CgCap[fuel,ecc,area] = CgGen[fuel,ecc,area]/H2CUFP[h2tech,area]/8760*1000
          
          #
          # NodeKey matches AreaKey only for Nodes/Areas in Canada and Mexico.
          # This is the case for the PROMULA model and the second condition enures
          # that happens here too. PNV Dec 11,2023
          #          
          if (CgCap[fuel,ecc,area] >= 0.00) && 
             (sum(ANMap[area,Select(Nation,["CN","MX"])]) == 1)

            node = Select(NodeKey,AreaKey[area])
            if AreaKey[area] == "NL"
              node = Select(NodeKey,"LB")
            end
            if CgUnCode[plant,ecc,node,area] == 0
              line = "Missing CgUnCode ",PlantKey[plant],ECCKey[ecc],AreaKey[area],NodeKey[node]
              @info line
            else
              unit = Int(CgUnCode[plant,ecc,node,area])
              UnEGA[unit] = CgGen[fuel,ecc,area]
              UnGC[unit] = CgCap[fuel,ecc,area]
            end
          end
        end
      end
    end
    CgInv[ecc,area] = sum(max(CgCap[fuel,ecc,area]-CgCapPrior[fuel,ecc,area],0)*
                      CgCC[fuel,area] for fuel in Fuels)/1000
  end

  WriteDisk(db,"SpOutput/H2SaEC",year,H2SaEC)
  WriteDisk(db,"SOutput/SaEC",year,SaEC)
  WriteDisk(db,"SOutput/LDCECC",year,LDCECC)
  WriteDisk(db,"SOutput/CgGen",year,CgGen)
  WriteDisk(db,"SOutput/CgCap",year,CgCap)
  WriteDisk(db,"SOutput/CgInv",year,CgInv)
  WriteDisk(db,"EGOutput/UnEGA",year,UnEGA)
  WriteDisk(db,"EGOutput/UnGC",year,UnGC)
end

#
########################
#
function SupplyHydrogen(data::Data)
  Demands(data)
  DemandGrowthRate(data)
  ImportsExportsPrices(data)
  MarketShareImportsExports(data)
  EstimateImportsExports(data)
  ProductionTarget(data)
  FuelPrices(data)
  CapitalCosts(data)
  GHGEmissionIntensity(data)
  EmissionCosts(data)
  MarginalCost(data)
  MarketShare(data)
  CapacityRetirementRate(data)
  CapacityIndicated(data)
  CapacityCompletionRate(data)
  ProductionCapacity(data)
  Production(data)
  ImportsExports(data)
  EnergyUsage(data)
  FeedstockRequired(data)
  NGPipelineEfficiency(data)
  CombustionEmissions(data)
  FeedstockEmissions(data)
  SequesteredEmissions(data)
  SequesterPenalty(data)
  TotalDemands(data)
  Investments(data)
  ElectricSalesAndLoads(data)
end

#
# *********************
#
function WholesalePrice(data::Data)
  (; db,next) = data
  (; Areas,Fuel,Nations,H2Techs) = data
  (; ANMap,ENPNNext,ENPNSwNext,InflationNationNext) = data
  (; H2ENPNNext,H2FPWholesaleNext,H2MCE,H2Prod,H2ProdNation) = data
  (; NH3ENPNNext,NH3FPWholesaleNext,NH3MCE,NH3Prod,NH3ProdNation) = data  
  (; xENPNNext) = data  
  
  @. H2MCE = max(H2MCE,1.0)

  fuel = Select(Fuel,"Hydrogen")
  for nation in Nations
    areas = findall(ANMap[Areas,nation] .== 1)
    if H2ProdNation[nation] > 0.0
      if !isempty(areas)
      
        @finite_math H2ENPNNext[nation] = 
           sum(H2MCE[h2tech,area]*H2Prod[h2tech,area] for h2tech in H2Techs,area in areas)/
           sum(H2Prod[h2tech,area] for h2tech in H2Techs,area in areas)
           
        for area in areas
          @finite_math H2FPWholesaleNext[area] = 
             sum(H2MCE[h2tech,area]*H2Prod[h2tech,area] for h2tech in H2Techs)/
             sum(H2Prod[h2tech,area] for h2tech in H2Techs)
        end
      end
    end
  end

  for nation in Nations
    if ENPNSwNext[fuel,nation] == 1 && H2ProdNation[nation] > 0
      ENPNNext[fuel,nation] = H2ENPNNext[nation]/InflationNationNext[nation]
    end
  end

  @. NH3MCE = max(NH3MCE,1.0)

  fuel = Select(Fuel,"Ammonia")
  for nation in Nations
    areas = findall(ANMap[Areas,nation] .== 1)
    if NH3ProdNation[nation] > 0.0
      if !isempty(areas)
      
        @finite_math NH3ENPNNext[nation] = 
           sum(NH3MCE[h2tech,area]*NH3Prod[h2tech,area] for h2tech in H2Techs,area in areas)/
           sum(NH3Prod[h2tech,area] for h2tech in H2Techs,area in areas)
           
        for area in areas
          @finite_math NH3FPWholesaleNext[area] = 
             sum(NH3MCE[h2tech,area]*NH3Prod[h2tech,area] for h2tech in H2Techs)/
             sum(NH3Prod[h2tech,area] for h2tech in H2Techs)
        end
      end
    end
  end

  for nation in Nations
    if ENPNSwNext[fuel,nation] == 1 && NH3ProdNation[nation] > 0
      ENPNNext[fuel,nation] = NH3ENPNNext[nation]/InflationNationNext[nation]
    end
  end

  WriteDisk(db,"SpOutput/H2ENPN",next,H2ENPNNext)
  WriteDisk(db,"SpOutput/H2FPWholesale",next,H2FPWholesaleNext)
  WriteDisk(db,"SpOutput/NH3ENPN",next,NH3ENPNNext)
  WriteDisk(db,"SpOutput/NH3FPWholesale",next,NH3FPWholesaleNext)
  WriteDisk(db,"SOutput/ENPN",next,ENPNNext)
end

#
# *********************
#
function RetailPrice(data::Data)
  (; db,next) = data
  (; Areas,ES,Fuel,Nations) = data
  (; ANMap,ENPNSwNext,H2Production) = data
  (; FPDChgFNext,H2FPDChgNext,FPBaseFNext,H2FPWholesaleNext,InflationNext,FPFNext) = data
  (; FPMarginFNext,FPTaxFNext,FPPolTaxFNext,FPSMFNext,FsFPNext) = data
  (; NH3Production, NH3FPWholesaleNext) = data

  Hydrogen = Select(Fuel,"Hydrogen")
  for nation in Nations, area in Areas
    if ANMap[area,nation] == 1 && H2Production[area] > 0 && ENPNSwNext[Hydrogen,nation] == 1

      for es in Select(ES)
        FPDChgFNext[Hydrogen,es,area] = H2FPDChgNext[es,area]
        
        FPBaseFNext[Hydrogen,es,area] = H2FPWholesaleNext[area]+FPDChgFNext[Hydrogen,es,area]*InflationNext[area]
        
        FPFNext[Hydrogen,es,area] = (H2FPWholesaleNext[area]*(1.0+FPMarginFNext[Hydrogen,es,area])+
          ((FPDChgFNext[Hydrogen,es,area]+FPTaxFNext[Hydrogen,es,area])+FPPolTaxFNext[Hydrogen,es,area])*
           InflationNext[area])*(1.0+FPSMFNext[Hydrogen,es,area])
           
        FsFPNext[Hydrogen,es,area] = H2FPWholesaleNext[area]*(1.0+FPMarginFNext[Hydrogen,es,area])+
          (FPTaxFNext[Hydrogen,es,area]+FPPolTaxFNext[Hydrogen,es,area])*InflationNext[area]
      end
    end
    
    Ammonia = Select(Fuel,"Ammonia")
    if ANMap[area,nation] == 1 && NH3Production[area] > 0 && ENPNSwNext[Ammonia,nation] == 1

      for es in Select(ES)
        FPDChgFNext[Ammonia,es,area] = H2FPDChgNext[es,area]
        
        FPBaseFNext[Ammonia,es,area] = NH3FPWholesaleNext[area]+FPDChgFNext[Ammonia,es,area]*InflationNext[area]
        
        FPFNext[Ammonia,es,area] = (NH3FPWholesaleNext[area]*(1.0+FPMarginFNext[Ammonia,es,area])+
          ((FPDChgFNext[Ammonia,es,area]+FPTaxFNext[Ammonia,es,area])+FPPolTaxFNext[Ammonia,es,area])*
           InflationNext[area])*(1.0+FPSMFNext[Ammonia,es,area])
           
        FsFPNext[Ammonia,es,area] = NH3FPWholesaleNext[area]*(1.0+FPMarginFNext[Ammonia,es,area])+
          (FPTaxFNext[Ammonia,es,area]+FPPolTaxFNext[Ammonia,es,area])*InflationNext[area]
      end
    end
  end
  WriteDisk(db,"SCalDB/FPDChgF",next,FPDChgFNext)
  WriteDisk(db,"SOutput/FPBaseF",next,FPBaseFNext)
  WriteDisk(db,"SOutput/FPF",next,FPFNext)
  WriteDisk(db,"SOutput/FsFP",next,FsFPNext)
end

function PriceHydrogen(data::Data)
  WholesalePrice(data)
  RetailPrice(data)
end

end # module SpHydrogen
