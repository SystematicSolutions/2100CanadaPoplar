#
# Hydrogen.jl - Hydrogen Input Data
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2016 Systematic Solutions, Inc.  All rights reserved.
#
using EnergyModel

module Hydrogen

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  H2Tech::SetArray = ReadDisk(db,"MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db,"MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  HourDS::SetArray = ReadDisk(db,"MainDB/HourDS")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  H2CUFP::VariableArray{3} = ReadDisk(db,"SpInput/H2CUFP") # [H2Tech,Area,Year] Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  NH3CUFP::VariableArray{3} = ReadDisk(db,"SpInput/NH3CUFP") # [H2Tech,Area,Year] Ammonia Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  H2CUFMax::VariableArray{2} = ReadDisk(db,"SpInput/H2CUFMax") # [Area,Year] Hydrogen Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  NH3CUFMax::VariableArray{2} = ReadDisk(db,"SpInput/NH3CUFMax") # [Area,Year] Ammonia Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  H2DmFrac::VariableArray{4} = ReadDisk(db,"SpInput/H2DmFrac") # [Fuel,H2Tech,Area,Year] Hydrogen Production Energy Usage Fraction
  NH3DmFrac::VariableArray{4} = ReadDisk(db,"SpInput/NH3DmFrac") # [Fuel,H2Tech,Area,Year] Ammonia Production Energy Usage Fraction
  H2Eff::VariableArray{3} = ReadDisk(db,"SpInput/H2Eff") # [H2Tech,Area,Year] Hydrogen Production Energy Efficiency (Btu/Btu)
  NH3Eff::VariableArray{3} = ReadDisk(db,"SpInput/NH3Eff") # [H2Tech,Area,Year] Ammonia Production Energy Efficiency (Btu/Btu)
  H2FsFrac::VariableArray{4} = ReadDisk(db,"SpInput/H2FsFrac") # [Fuel,H2Tech,Area,Year] Hydrogen Feedstock Fuel/H2Tech Split (Btu/Btu)
  NH3FsFrac::VariableArray{4} = ReadDisk(db,"SpInput/NH3FsFrac") # [Fuel,H2Tech,Area,Year] Ammonia Feedstock Fuel/H2Tech Split (Btu/Btu)
  H2FsPOCX::VariableArray{4} = ReadDisk(db,"SpInput/H2FsPOCX") # [FuelEP,Poll,Area,Year] Hydrogen Feedstock Pollution Coefficients (Tonnes/TBtu)
  H2GridFraction::VariableArray{3} = ReadDisk(db,"SpInput/H2GridFraction") # [H2Tech,Area,Year] Fraction of Electric Demands Purchased from Grid (Btu/Btu)
  H2MSFSwitch::VariableArray{2} = ReadDisk(db,"SpInput/H2MSFSwitch") # [Area,Year] Hydrogen Market Share Non-Price Factor (mmBtu/mmBtu)
  NH3MSFSwitch::VariableArray{2} = ReadDisk(db,"SpInput/NH3MSFSwitch") # [Area,Year] Ammonia Market Share Non-Price Factor (mmBtu/mmBtu)
  H2MSM0::VariableArray{3} = ReadDisk(db,"SpInput/H2MSM0") # [H2Tech,Area,Year] Hydrogen Market Share Non-Price Factor (mmBtu/mmBtu)
  NH3MSM0::VariableArray{3} = ReadDisk(db,"SpInput/NH3MSM0") # [H2Tech,Area,Year] Ammonia Market Share Non-Price Factor (mmBtu/mmBtu)
  H2PL::VariableArray{2} = ReadDisk(db,"SpInput/H2PL") # [H2Tech,Year] Hydrogen Production Physical Lifetime (Years)
  NH3PL::VariableArray{2} = ReadDisk(db,"SpInput/NH3PL") # [H2Tech,Year] Ammonia Production Physical Lifetime (Years)
  H2PlantMap::VariableArray{4} = ReadDisk(db,"SpInput/H2PlantMap") # [H2Tech,Plant,Power,Area] H2 Process to Plant Type Map
  H2POCX::VariableArray{4} = ReadDisk(db,"SpInput/H2POCX") # [FuelEP,Poll,Area,Year] Hydrogen Pollution Coefficient (Tonnes/TBtu)
  NH3POCX::VariableArray{4} = ReadDisk(db,"SpInput/NH3POCX") # [FuelEP,Poll,Area,Year] Ammonia Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
  H2SqFr::VariableArray{4} = ReadDisk(db,"SpInput/H2SqFr") # [H2Tech,Poll,Area,Year] Hydrogen Sequestered Pollution Fraction (Tonnes/Tonnes)
  H2SqPenalty::VariableArray{4} = ReadDisk(db,"SpInput/H2SqPenalty") # [H2Tech,Poll,Area,Year] Hydrogen Sequestering Energy Penalty (TBtu/Tonne)
  H2VF::VariableArray{3} = ReadDisk(db,"SpInput/H2VF") # [H2Tech,Area,Year] Hydrogen Market Share Variance Factor (mmBtu/mmBtu)
  NH3VF::VariableArray{3} = ReadDisk(db,"SpInput/NH3VF") # [H2Tech,Area,Year] Ammonia Market Share Variance Factor (mmBtu/mmBtu)
  H2FsYield::VariableArray{3} = ReadDisk(db,"SpInput/H2FsYield") # [H2Tech,Area,Year] Hydrogen Yield From Feedstock (Btu/Btu)
  NH3FsYield::VariableArray{3} = ReadDisk(db,"SpInput/NH3FsYield") # [H2Tech,Area,Year] Ammonia Yield From Feedstock (Btu/Btu)
  NH3H2Yield::Float32 = ReadDisk(db,"SpInput/NH3H2Yield")[1] # [H2Tech,Area,Year] Ammonia Yield From Hydrogen (Btu/Btu)
  H2CCM::VariableArray{3} = ReadDisk(db,"SpInput/H2CCM") # [H2Tech,Area,Year] Hydrogen Production Capital Cost Multiplier ($/$)
  H2CCN::VariableArray{3} = ReadDisk(db,"SpInput/H2CCN") # [H2Tech,Area,Year] Hydrogen Production Capital Cost (Real $/mmBtu)
  NH3CCM::VariableArray{3} = ReadDisk(db,"SpInput/NH3CCM") # [H2Tech,Area,Year] Ammonia Production Capital Cost Multiplier ($/$)
  NH3CCN::VariableArray{3} = ReadDisk(db,"SpInput/NH3CCN") # [H2Tech,Area,Year] Ammonia Production Capital Cost (Real $/mmBtu)
  H2CCR::VariableArray{3} = ReadDisk(db,"SpInput/H2CCR") # [H2Tech,Area,Year] Hydrogen Production Capital Charge Rate ($/$)
  H2CD::VariableArray{1} = ReadDisk(db,"SpInput/H2CD") # [Year] Hydrogen Production Construction Delay (Years)
  H2FPDChg::VariableArray{3} = ReadDisk(db,"SpInput/H2FPDChg") # [ES,Area,Year] Hydrogen Fuel Delivery Charge (Real $/mmBtu)
  H2Trans::VariableArray{3} = ReadDisk(db,"SpInput/H2Trans") # [H2Tech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/mmBtu)
  H2IPMultiplier::VariableArray{3} = ReadDisk(db,"SpInput/H2IPMultiplier") # [H2Tech,Area,Year] Interruptible Electricity Price Multiplier ($/$)
  H2OF::VariableArray{3} = ReadDisk(db,"SpInput/H2OF") # [H2Tech,Area,Year] Hydrogen Production O&M Cost Factor (Real $/$/Yr)
  NH3OF::VariableArray{3} = ReadDisk(db,"SpInput/NH3OF") # [H2Tech,Area,Year] Ammonia Production O&M Cost Factor (Real $/$/Yr)
  H2SmT::VariableArray{1} = ReadDisk(db,"SpInput/H2SmT") # [Year] Hydrogen Production Growth Rate Smoothing Time (Years)
  H2UOMC::VariableArray{3} = ReadDisk(db,"SpInput/H2UOMC") # [H2Tech,Area,Year] Hydrogen Production Variable O&M Costs (Real $/mmBtu)
  NH3UOMC::VariableArray{3} = ReadDisk(db,"SpInput/NH3UOMC") # [H2Tech,Area,Year] Ammonia Production Variable O&M Costs (Real $/mmBtu)
  H2Subsidy::VariableArray{2} = ReadDisk(db,"SpInput/H2Subsidy") # [Area,Year] Hydrogen Production Subsidy ($/mmBtu)
  NH3Subsidy::VariableArray{2} = ReadDisk(db,"SpInput/NH3Subsidy") # [Area,Year] Ammonia Production Subsidy ($/mmBtu)
  H2ExportsCharge::VariableArray{2} = ReadDisk(db,"SpInput/H2ExportsCharge") # [Nation,Year] Hydrogen Exports Charge ($/mmBtu)
  H2ImportsCharge::VariableArray{2} = ReadDisk(db,"SpInput/H2ImportsCharge") # [Nation,Year] Hydrogen Imports Charge ($/mmBtu)
  H2ExportsMSM0::VariableArray{2} = ReadDisk(db,"SpInput/H2ExportsMSM0") # [Nation,Year] Hydrogen Exports Non-Price Factors ($/$)
  H2ImportsMSM0::VariableArray{2} = ReadDisk(db,"SpInput/H2ImportsMSM0") # [Nation,Year] Hydrogen Imports Non-Price Factors ($/$)
  H2ExportsVF::VariableArray{2} = ReadDisk(db,"SpInput/H2ExportsVF") # [Nation,Year] Hydrogen Exports Variance Factors ($/$)
  H2ImportsVF::VariableArray{2} = ReadDisk(db,"SpInput/H2ImportsVF") # [Nation,Year] Hydrogen Imports Variance Factors ($/$)
  H2LSF::VariableArray{5} = ReadDisk(db,"SCalDB/H2LSF") # [H2Tech,Hour,Day,Month,Area] Hydrogen Production Load Shape (MW/MW)
  xH2LSF::VariableArray{5} = ReadDisk(db,"SpInput/xH2LSF") # [H2Tech,Hour,Day,Month,Area] Hydrogen Production Load Shape before Calibration (MW/MW)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  xH2MSF::VariableArray{3} = ReadDisk(db,"SpInput/xH2MSF") # [H2Tech,Area,Year] Hydrogen Exogenous Market Share (mmBtu/mmBtu)
  xNH3Exports::VariableArray{2} =ReadDisk(db,"SpInput/xNH3Exports") # [Area,Year] Ammonia Exogenous Exports (TBtu/Year)
  H2PipeA0::VariableArray{2} = ReadDisk(db,"SpInput/H2PipeA0") # [Area,Year] Pipeline Efficiency Multiplier A0 Coefficient (Btu/Btu)
  H2PipeB0::VariableArray{2} = ReadDisk(db,"SpInput/H2PipeB0") # [Area,Year] Pipeline Efficiency Multiplier B0 Coefficient (Btu/Btu)
  H2PipeC0::VariableArray{2} = ReadDisk(db,"SpInput/H2PipeC0") # [Area,Year] Pipeline Efficiency Multiplier C0 Coefficient (Btu/Btu)

  # Scratch Variables
  CapCostATRNGCCS::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Capital Cost of Hydrogen with Central ATR NG with CCS (Real $/mmBtu)
  CapCostBiomass::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Capital Cost of Hydrogen with Central Biomass (Real $/mmBtu)
  CapCostBiomassCCS::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Capital Cost of Hydrogen with Central Biomass with CCS (Real $/mmBtu)
  CapCostDelivery::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Capital Cost of Hydrogen Delivery from Central to Distributed (Real $/mmBtu)
  CapCostNG::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Capital Cost of Hydrogen with Distributed NG without CCS (Real $/mmBtu)
  CapCostNGCCS::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Capital Cost of Hydrogen with Central SMR NG with CCS (Real $/mmBtu)
  CapCostPEM::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Capital Cost of Hydrogen with Distributed PEM Capital Cost (Real $/mmBtu)
  LSFLoad::VariableArray{2} = zeros(Float32,length(Months),length(Days)) # [Months,Days] Variable to Read Loads
  NormLoad::VariableArray{1} = zeros(Float32,length(H2Tech)) # [H2Tech] Annual Value used to Normalize Loads (GWh)
  Shipping::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Shipping costs via Ammonia
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,Areas,Day,Days,EC,ES) = data
  (;Enduse,Fuel,FuelEP,FuelEPs) = data
  (;Fuels,H2Tech,H2Techs,Hour,Hours,Month,Months) = data
  (;Nation,Nations,Plant,Poll,Polls,Power) = data
  (;Years) = data
  (;ANMap,xExchangeRate,xExchangeRateNation,xInflation,xInflationNation,H2CUFP,NH3CUFP,H2CUFMax,NH3CUFMax,H2DmFrac,NH3DmFrac,H2Eff,NH3Eff) = data
  (;H2FsFrac,NH3FsFrac,H2FsPOCX,H2GridFraction,H2MSFSwitch,NH3MSFSwitch,H2MSM0,NH3MSM0,H2PL,NH3PL,H2PlantMap,H2POCX,NH3POCX,POCX,H2SqFr) = data
  (;H2SqPenalty,H2VF,NH3VF,H2FsYield,NH3FsYield,NH3H2Yield,H2CCM,NH3CCM,H2CCN,NH3CCN,H2CCR,H2CD,H2FPDChg,H2Trans,H2IPMultiplier) = data
  (;H2OF,NH3OF,H2SmT,H2UOMC,NH3UOMC,H2Subsidy,NH3Subsidy,H2ExportsCharge,H2ImportsCharge,H2ExportsMSM0,H2ImportsMSM0,H2ExportsVF,H2ImportsVF) = data
  (;H2LSF,xH2LSF,HoursPerMonth,xH2MSF,xNH3Exports,H2PipeA0,H2PipeB0,H2PipeC0) = data
  (;CapCostATRNGCCS,CapCostBiomass,CapCostBiomassCCS,CapCostDelivery,CapCostNG,CapCostNGCCS,CapCostPEM,LSFLoad,NormLoad,Shipping) = data

  #
  ########################
  #
  # Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  #
  # NREL spreadsheets - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary v10_update.xlsx
  # Adjustments for renewables and Interruptible need to be researched - Jeff Amlin 02/08/20
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  #

  @. H2CUFP = 0.90
  @. NH3CUFP = 0.90

  #
  h2tech=Select(H2Tech,"Grid")
  for year in Years, area in Areas
        H2CUFP[h2tech,area,year] = 0.90  # Changed from 0.86
        NH3CUFP[h2tech,area,year] = 0.90
  end
  #
  h2tech=Select(H2Tech,"OnshoreWind")
  areas=Select(Area,["AB","ON","SK","YT","NT","MB"])
  for year in Years, area in areas
        H2CUFP[h2tech,area,year] = 0.33
        NH3CUFP[h2tech,area,year] = 0.33
  end
  areas=Select(Area,["BC","NU"])
  for year in Years, area in areas
        H2CUFP[h2tech,area,year] = 0.35
        NH3CUFP[h2tech,area,year] = 0.35
  end
  areas=Select(Area,["NB","NS"])
  for year in Years, area in areas
        H2CUFP[h2tech,area,year] = 0.36
  end
  areas=Select(Area,["NL","PE"])
  for year in Years, area in areas
        H2CUFP[h2tech,area,year] = 0.40
  end
  area=Select(Area,"QC")
  years=collect(Yr(2025):Final)
  for year in years
        H2CUFP[h2tech,area,year] = 0.37
  end
    H2CUFP[h2tech,area,Yr(2024)] = 0.20
    H2CUFP[h2tech,area,Yr(2023)] = 0.17
  #
  h2tech=Select(H2Tech,"SolarPV")
  for year in Years, area in Areas
        H2CUFP[h2tech,area,year] = 0.20  # Changed from 0.86*0.30
  end
  #
  h2tech=Select(H2Tech,"SMNR")
  for year in Years, area in Areas
        H2CUFP[h2tech,area,year] = 0.95
  end
  #
  h2tech=Select(H2Tech,"Interruptible")
  for year in Years, area in Areas
        H2CUFP[h2tech,area,year] = 0.86 * 0.20
  end
  #
  h2tech=Select(H2Tech,"NG")
  for year in Years, area in Areas
        H2CUFP[h2tech,area,year] = 0.90
  end
  h2techs=Select(H2Tech,["NGCCS","ATRNGCCS"])
  for year in Years, area in Areas, h2tech in h2techs
        H2CUFP[h2tech,area,year] = 0.90
        NH3CUFP[h2tech,area,year] = 0.90
  end
  h2techs=Select(H2Tech,["Biomass","BiomassCCS"])
  for year in Years, area in Areas, h2tech in h2techs
        H2CUFP[h2tech,area,year] = 0.90
  end
  WriteDisk(db,"SpInput/H2CUFP",H2CUFP)
  WriteDisk(db,"SpInput/NH3CUFP",NH3CUFP)

  #
  ########################
  #
  # Hydrogen Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  # Use "normal" value - Jeff Amlin 5/26/16
  # Placeholder data needs to be reviewed - Jeff Amlin 10/22/19
  #
  for year in Years, area in Areas
    h2tech=first(H2Techs)
    H2CUFMax[area,year] = H2CUFP[h2tech,area,year]*1.10
  end
  for year in Years, area in Areas
    h2techs=Select(H2Tech,["Grid","NGCCS","ATRNGCCS"])
    h2tech=first(h2techs)
    NH3CUFMax[area,year] = NH3CUFP[h2tech,area,year]*1.10
  end

  WriteDisk(db,"SpInput/H2CUFMax",H2CUFMax)
  WriteDisk(db,"SpInput/NH3CUFMax",NH3CUFMax)

  #
  ########################
  #
  # Hydrogen Production Energy Usage Fraction
  #
    @. H2DmFrac = 0.0
    @. NH3DmFrac = 0.0

  h2techs=Select(H2Tech,["Grid","Interruptible"])
  fuels=Select(Fuel,"Electric")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    H2DmFrac[fuel,h2tech,area,year] = 1.0
    NH3DmFrac[fuel,h2tech,area,year] = 1.0
  end

  h2techs=Select(H2Tech,"OnshoreWind")
  fuels=Select(Fuel,"Wind")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    H2DmFrac[fuel,h2tech,area,year] = 1.0
  end

  h2techs=Select(H2Tech,"SolarPV")
  fuels=Select(Fuel,"Solar")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    H2DmFrac[fuel,h2tech,area,year] = 1.0
  end

  h2techs=Select(H2Tech,"SMNR")
  fuels=Select(Fuel,"Nuclear")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    H2DmFrac[fuel,h2tech,area,year] = 1.0
  end

  h2techs=Select(H2Tech,["NG","NGCCS","ATRNGCCS"])
  fuels=Select(Fuel,"NaturalGas")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    H2DmFrac[fuel,h2tech,area,year] = 1.0
  end

  h2techs=Select(H2Tech,["NGCCS","ATRNGCCS"])
  fuels=Select(Fuel,"Electric")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    NH3DmFrac[fuel,h2tech,area,year] = 1.0
  end

  #
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  #
  h2techs=Select(H2Tech,["Biomass","BiomassCCS"])
  NaturalGas=Select(Fuel,"NaturalGas")
  Electric=Select(Fuel,"Electric")
  for area in Areas, h2tech in h2techs
    years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
    for year in years
      H2DmFrac[NaturalGas,h2tech,area,year] = 0.2073
      H2DmFrac[Electric,h2tech,area,year] = 0.7927
    end
    years=collect(Yr(2040):Final)
    for year in years
      H2DmFrac[NaturalGas,h2tech,area,year] = 0.1904
      H2DmFrac[Electric,h2tech,area,year] = 0.8096
    end
    years=collect(Yr(2024):Yr(2039))
    for year in years,fuel in Fuels
      H2DmFrac[fuel,h2tech,area,year] = H2DmFrac[fuel,h2tech,area,year-1]+
        (H2DmFrac[fuel,h2tech,area,Yr(2040)]-H2DmFrac[fuel,h2tech,area,Yr(2023)])/(2040-2023)
    end
  end

  WriteDisk(db,"SpInput/H2DmFrac",H2DmFrac)
  WriteDisk(db,"SpInput/NH3DmFrac",NH3DmFrac)

    #
  ########################
  #
  # Hydrogen Production Energy Efficiency (Btu/Btu)
  #
  # NREL spreadsheets - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary v10_update.xlsx
  #
  # keep efficiency the same as NREL values
  #

  @. H2Eff=0

  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","Interruptible","SMNR"])
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 0.7105
  end
  for area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,Yr(2030)] = 0.7357
  end
  years=collect(Yr(2024):Yr(2029))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = H2Eff[h2tech,area,year-1]+
      (H2Eff[h2tech,area,Yr(2030)]-H2Eff[h2tech,area,Yr(2023)])/(2030-2023)
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 0.7672
  end
  years=collect(Yr(2031):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = H2Eff[h2tech,area,year-1]+
      (H2Eff[h2tech,area,Yr(2040)]-H2Eff[h2tech,area,Yr(2030)])/(2040-2030)
  end
  #
  h2techs=Select(H2Tech,"NG")
  years=collect(Zero:Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 300.6305
  end
  #
  h2techs=Select(H2Tech,"NGCCS")
  years=collect(Zero:Yr(2050))
  for year in Years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 26.2442
  end

  #
  # From Thuo email on June 13, 2022.
  # Source: "IHS-HydrogenModel_NoLink v2.xlsx"
  #
  h2techs=Select(H2Tech,"ATRNGCCS")
  years=collect(Zero:Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 11.5212  # Changed from 11.2835
  end

  #
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  #
  h2techs=Select(H2Tech,"Biomass")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 13.03224
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 18.6378
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = H2Eff[h2tech,area,year-1]+
      (H2Eff[h2tech,area,Yr(2040)]-H2Eff[h2tech,area,Yr(2023)])/(2040-2023)
  end

  h2techs=Select(H2Tech,"BiomassCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 13.7252
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = 20.0908
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2Eff[h2tech,area,year] = H2Eff[h2tech,area,year-1]+
      (H2Eff[h2tech,area,Yr(2040)]-H2Eff[h2tech,area,Yr(2023)])/(2040-2023)
  end

  h2techs=Select(H2Tech,"Grid")
  for year in Years, area in Areas, h2tech in h2techs
        NH3Eff[h2tech,area,year] = 5.747
  end
  h2techs=Select(H2Tech,["NGCCS","ATRNGCCS"])
  for year in Years, area in Areas, h2tech in h2techs
        NH3Eff[h2tech,area,year] = 10.764
  end

  WriteDisk(db,"SpInput/H2Eff",H2Eff)
  WriteDisk(db,"SpInput/NH3Eff",NH3Eff)

  #
  ########################
  #
  # Hydrogen Feedstock Usage Fraction
  #
  h2techs=Select(H2Tech,["NG","NGCCS","ATRNGCCS"])
  fuels=Select(Fuel,"NaturalGas")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    H2FsFrac[fuel,h2tech,area,year] = 1.0
  end

  fuels=Select(Fuel,"Hydrogen")
  for year in Years, area in Areas, h2tech in H2Techs, fuel in fuels
    NH3FsFrac[fuel,h2tech,area,year] = 1.0
  end
  h2techs=Select(H2Tech,"Grid")
  for year in Years, area in Areas, h2tech in h2techs, fuel in Fuels
    NH3FsFrac[fuel,h2tech,area,year] = 1.0
  end

  h2techs=Select(H2Tech,["Biomass","BiomassCCS"])
  fuels=Select(Fuel,"Biomass")
  for year in Years, area in Areas, h2tech in h2techs, fuel in fuels
    H2FsFrac[fuel,h2tech,area,year] = 1.0
  end
  WriteDisk(db,"SpInput/H2FsFrac",H2FsFrac)
  WriteDisk(db,"SpInput/NH3FsFrac",NH3FsFrac)

  #
  ########################
  #
  # Source:  "Feedstock (Non-Energy) Demands GO 07.xls", 'Notes' sheet from Glasha 2-19-09.
  # Feedstock Emission Coefficients are only for CO2. Units (t CO2/PJ)
  # 03/09/09 RBL.
  #

  NaturalGas=Select(FuelEP,"NaturalGas")
  CO2=Select(Poll,"CO2")
  for year in Years, area in Areas
    H2FsPOCX[NaturalGas,CO2,area,year] = 39780.0
    #
    # Convert from Tonnes/PJ to Tonnes/TBtu
    #
    H2FsPOCX[NaturalGas,CO2,area,year] = H2FsPOCX[NaturalGas,CO2,area,year]*1.054615
  end

  WriteDisk(db,"SpInput/H2FsPOCX",H2FsPOCX)

  #
  ########################
  #
  @. H2GridFraction=1.0
  h2techs=Select(H2Tech,["OnshoreWind","SolarPV"])
  for year in Years, area in Areas, h2tech in h2techs
    H2GridFraction[h2tech,area,year] = 0.0
  end
  WriteDisk(db,"SpInput/H2GridFraction",H2GridFraction)

  #
  ########################
  #
  @. H2MSFSwitch=1.0
  @. NH3MSFSwitch=1.0
  WriteDisk(db,"SpInput/H2MSFSwitch",H2MSFSwitch)
  WriteDisk(db,"SpInput/NH3MSFSwitch",NH3MSFSwitch)

  #
  ########################
  #
  # Hydrogen Market Share Non-Price Factor (mmBtu/mmBtu)
  # Placeholder data needs to be replaced - Jeff Amlin 10/22/19
  #
  @.  H2MSM0=-170

  #
  # Establish historical Hydrogen production (from Natural Gas)
  #
  years=collect(Zero:Last)
  h2techs=Select(H2Tech,"NG")
  for year in years, area in Areas, h2tech in h2techs
    H2MSM0[h2tech,area,year] = 0.0
  end

  #
  # Options in the Forecast
  #
  years=collect(Future:Final)
  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","NG","SMNR"])
  for year in years, area in Areas, h2tech in h2techs
    H2MSM0[h2tech,area,year] = 0.0
  end

  #
  # Only Ontario has significant need for Interruptible power
  #
  areas=Select(Area,"ON")
  h2techs=Select(H2Tech,"Interruptible")
  for year in years, area in areas, h2tech in h2techs
    H2MSM0[h2tech,area,year] = -1.0
  end

  #
  # NG CCS units only expected in AB and SK
  #
  areas=Select(Area,["AB","SK"])
  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","NG"])
  for year in years, area in areas, h2tech in h2techs
    H2MSM0[h2tech,area,year] = -10.0
  end
  h2techs=Select(H2Tech,["NGCCS","ATRNGCCS"])
  for year in years, area in areas, h2tech in h2techs
    H2MSM0[h2tech,area,year] = 0.00
  end

  #
  # Biomass Gasification only in BC and QC
  #
  areas=Select(Area,["BC","QC"])
  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","NG"])
  for year in years, area in areas, h2tech in h2techs
    H2MSM0[h2tech,area,year] = -10.0
  end
  h2techs=Select(H2Tech,["Biomass","BiomassCCS"])
  for year in years, area in areas, h2tech in h2techs
    H2MSM0[h2tech,area,year] = 0.00
  end

  @. NH3MSM0=H2MSM0

  WriteDisk(db,"SpInput/H2MSM0",H2MSM0)
  WriteDisk(db,"SpInput/NH3MSM0",NH3MSM0)

  #
  ########################
  #
  # Hydrogen Production Physical Lifetime (Years)
  # source: "Hydrogen Input Parameters from Thuo.xlsx" 8/28/16 by Jeff Amlin 10/22/19
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  #
  # *
  # *Select H2Tech(Grid,OnshoreWind,SolarPV,Interruptible,Biomass,BiomassCCS)
  # *H2PL=40
  # *Select H2Tech(NG,NGCCS,ATRNGCCS)
  # *H2PL=20
  # *Select H2Tech*
  #
  # Since all these are new facilities, remove all the retirements by having
  # a lifetime of 0 - Jeff Amlin 08/11/22
  #
  @. H2PL=0
  @. NH3PL=40
  WriteDisk(db,"SpInput/H2PL",H2PL)
  WriteDisk(db,"SpInput/NH3PL",NH3PL)

  #
  ########################
  #
  @.  H2PlantMap=0

  h2tech=Select(H2Tech,"OnshoreWind")
  plant=Select(Plant,"OnshoreWind")
  power=Select(Power,"Base")
  for area in Areas
    H2PlantMap[h2tech,plant,power,area] = 1
  end

  h2tech=Select(H2Tech,"SolarPV")
  plant=Select(Plant,"SolarPV")
  power=Select(Power,"Base")
  for area in Areas
    H2PlantMap[h2tech,plant,power,area] = 1
  end

  WriteDisk(db,"SpInput/H2PlantMap",H2PlantMap)

  #
  ########################
  #
  # Hydrogen Pollution Coefficient (Tonnes/TBtu)
  # "Most of the energy needed for the [Ammonia conversion from Hydrogen]
  # process is generated by the reaction itself, although a small amount of electricity
  # is required to power motors, heat exchangers and other equipment to control the
  # pressure and temperature."
  #
  # However, the air seperation units are run by natural gas combustion for NGCCS and ATRNGCCS
  #

  ec=Select(EC,"Fertilizer")
  enduse=Select(Enduse,"Heat")
  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    H2POCX[fuelep,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]
  end
  poll=Select(Poll,"CO2")
  for year in Years, area in Areas, fuelep in FuelEPs
    NH3POCX[fuelep,poll,area,year] = 0.0
  end

  WriteDisk(db,"SpInput/H2POCX",H2POCX)
  WriteDisk(db,"SpInput/NH3POCX",NH3POCX)

  #
  ########################
  #
  # 90% - C:\2020 Documents\Hydrogen\NREL H2A Model\current-central-natural-gas-with-co2-sequestration-v3-2018.xlsm
  # 90% - C:\2020 Documents\Hydrogen\NREL H2A Model\future-central-natural-gas-with-co2-sequestration-v3-2018.xlsm
  # Harris Berton, NRCan, 11/30/2020 recommendations to increase sequestration fraction to that amenable to
  # autothermal reforming (ATR) of natural gas (ie 95%).
  #
  @. H2SqFr=0.0
  CO2=Select(Poll,"CO2")
  #
  # From Thuo email on June 13, 2022: Align with the average sequestration
  # rate reported by the Shell Quest project (78.8%).
  #
  h2tech=Select(H2Tech,"NGCCS")
  for year in Years, area in Areas
    H2SqFr[h2tech,CO2,area,year] = 0.78
  end

  #
  # From Thuo email on June 13, 2022.
  # Source: "IHS-HydrogenModel_NoLink v2.xlsx"
  #
  h2tech=Select(H2Tech,"ATRNGCCS")
  for year in Years, area in Areas
    H2SqFr[h2tech,CO2,area,year] = 0.95
  end

  #
  # "Adding CCS with a high capture rate (i.e. specfic pre-combustion capture
  # unit CO2 recovery of 98%)",
  # DOI: 10.1039/D0SE01637C (Paper) Sustainable Energy Fuels, 2021, 5, 2602-2621
  #
  h2tech=Select(H2Tech,"BiomassCCS")
  for year in Years, area in Areas
    H2SqFr[h2tech,CO2,area,year] = 0.980
  end

  WriteDisk(db,"SpInput/H2SqFr",H2SqFr)

  #
  ########################
  #
  # Hydrogen Sequestering Energy Penalty (TBtu/Tonne)
  #
  # High CO2 concentration
  # – 0.1 MWh/tCO2 of electricity
  #
  CO2=Select(Poll,"CO2")
  for year in Years, area in Areas, h2tech in H2Techs
    H2SqPenalty[h2tech,CO2,area,year] = 0.1 *1000*3412/1e12
  end
  WriteDisk(db,"SpInput/H2SqPenalty",H2SqPenalty)

  #
  ########################
  #
  # Hydrogen Market Share Variance Factor (mmBtu/mmBtu)
  # Preliminary value from Industrial XMVF - Jeff Amlin 10/22/19
  #
  @. H2VF=-2.5
  @. NH3VF=-2.5
  WriteDisk(db,"SpInput/H2VF",H2VF)
  WriteDisk(db,"SpInput/NH3VF",NH3VF)

  #
  ########################
  #
  # Hydrogen Yield From Feedstock (Btu/Btu)
  #
  # NREL spreadsheets - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary v10_update.xlsx
  #
  NH3H2Yield=0.8677
  @. H2FsYield=0
  @. NH3FsYield=0

  h2techs=Select(H2Tech,["Grid","NGCCS","ATRNGCCS"])
  for year in Years, area in Areas, h2tech in h2techs
    NH3FsYield[h2tech,area,year] = 0.8677
  end

  h2techs=Select(H2Tech,"NG")
  for year in Years, area in Areas, h2tech in h2techs
    H2FsYield[h2tech,area,year] = 0.8530
  end

  h2techs=Select(H2Tech,"NGCCS")
  for year in Years, area in Areas, h2tech in h2techs
    H2FsYield[h2tech,area,year] = 0.8020
  end

  #
  # From Thuo email on June 13, 2022.
  # Source: "IHS-HydrogenModel_NoLink v2.xlsx"
  #
  h2techs=Select(H2Tech,"ATRNGCCS")
  for year in Years, area in Areas, h2tech in h2techs
    H2FsYield[h2tech,area,year] = 0.811  # Changed from 0.8534
  end

  #
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  #
  h2techs=Select(H2Tech,["Biomass","BiomassCCS"])
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2FsYield[h2tech,area,year] = 0.5383
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2FsYield[h2tech,area,year] = 0.5573
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2FsYield[h2tech,area,year] = H2FsYield[h2tech,area,year-1]+
      (H2FsYield[h2tech,area,Yr(2040)]-H2FsYield[h2tech,area,Yr(2023)])/(2040-2023)
  end

  WriteDisk(db,"SpInput/H2FsYield",H2FsYield)
  WriteDisk(db,"SpInput/NH3H2Yield",NH3H2Yield)
  WriteDisk(db,"SpInput/NH3FsYield",NH3FsYield)

  #
  ########################
  #
  # Hydrogen Production Capital Cost Multiplier ($/$)
  # Preliminary value - Jeff Amlin 10/22/19
  #
  @. H2CCM=1.00
  @. NH3CCM=1.00
  WriteDisk(db,"SpInput/H2CCM",H2CCM)
  WriteDisk(db,"SpInput/NH3CCM",NH3CCM)

  #
  ########################
  #
  # Hydrogen Production Capital Cost (Real $/mmBtu/Yr)
  # source: "Hydrogen Input Parameters from Thuo.xlsx" 8/28/16 by Jeff Amlin 10/22/19
  # temporary source: The Hydrogen Economy: Opportunities, Costs, Barriers, and R&D Needs (2004)
  # Jeff Amlin 10/28/19
  #
  # C:\2020 Documents\Hydrogen\NREL H2A Model\current-distributed-pem-electrolysis-v3-2018.xlsm
  # C:\2020 Documents\Hydrogen\NREL H2A Model\future-distributed-pem-electrolysis-v3-2018.xlsm
  # The units are 2016 US$/mmBtu
  # - Jeff Amlin 11/22/19
  #
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years
    CapCostPEM[year] = 132.65  # Changed from 117.432
  end
  CapCostPEM[Yr(2030)] = 98.120  # Changed from 76.547
  years=collect(Yr(2024):Yr(2029))
  for year in years
    CapCostPEM[year] = CapCostPEM[year-1]+
      (CapCostPEM[Yr(2030)]-CapCostPEM[Yr(2023)])/(2030-2023)
  end
  years=collect(Yr(2040):Final)
  for year in years
    CapCostPEM[year] =  84.185  # Changed from 39.631
  end
  years=collect(Yr(2031):Yr(2039))
  for year in years
    CapCostPEM[year] = CapCostPEM[year-1]+
      (CapCostPEM[Yr(2040)]-CapCostPEM[Yr(2030)])/(2040-2030)
  end

  #
  # C:\2020 Documents\Hydrogen\NREL H2A Model\current-distributed-natural-gas-v3-2018.xlsm
  # C:\2020 Documents\Hydrogen\NREL H2A Model\future-distributed-natural-gas-v3-2018.xlsm
  # The units are 2016 US$/mmBtu
  # - Jeff Amlin 11/22/19
  #
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years
    CapCostNG[year] =   9.103
  end
  years=collect(Yr(2040):Final)
  for year in years
    CapCostNG[year] =   9.103
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years
    CapCostNG[year] = CapCostNG[year-1]+
      (CapCostNG[Yr(2040)]-CapCostNG[Yr(2023)])/(2040-2023)
  end

  #
  # C:\2020 Documents\Hydrogen\NREL H2A Model\current-central-natural-gas-with-co2-sequestration-v3-2018.xlsm
  # C:\2020 Documents\Hydrogen\NREL H2A Model\future-central-natural-gas-with-co2-sequestration-v3-2018.xlsm
  # The units are 2016 US$/mmBtu
  # - Jeff Amlin 11/22/19
  #
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years
    CapCostNGCCS[year] =  23.487
  end
  years=collect(Yr(2040):Final)
  for year in years
    CapCostNGCCS[year] =  17.653
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years
    CapCostNGCCS[year] = CapCostNGCCS[year-1]+
      (CapCostNGCCS[Yr(2040)]-CapCostNGCCS[Yr(2023)])/(2040-2023)
  end

  #
  # From Thuo email on June 13, 2022.
  # Source: "IHS-HydrogenModel_NoLink v2.xlsx"
  # The units are input in 2020 US$/mmBtu and converted to 2016 US$/mmBtu
  # - Jeff Amlin 11/22/19
  #
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years
    CapCostATRNGCCS[year] =  102.994  # Changed from 21.569
  end
  CapCostATRNGCCS[Yr(2030)] =  97.878  # Changed from 19.838
  years=collect(Yr(2024):Yr(2029))
  for year in years
    CapCostATRNGCCS[year] = CapCostATRNGCCS[year-1]+
      (CapCostATRNGCCS[Yr(2030)]-CapCostATRNGCCS[Yr(2023)])/(2030-2023)
  end
  years=collect(Yr(2040):Final)
  for year in years
    CapCostATRNGCCS[year] =  84.108  # Changed from 16.055
  end
  years=collect(Yr(2031):Yr(2039))
  for year in years
    CapCostATRNGCCS[year] = CapCostATRNGCCS[year-1]+
      (CapCostATRNGCCS[Yr(2040)]-CapCostATRNGCCS[Yr(2030)])/(2040-2030)
  end

  #
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  # The units are 2016 US$/mmBtu
  # - Jeff Amlin 11/22/19
  #
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years
        CapCostBiomass[year] = 27.989
  end
  years=collect(Yr(2040):Final)
  for year in years
        CapCostBiomass[year] = 26.344
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years
    CapCostBiomass[year] = CapCostBiomass[year-1]+
      (CapCostBiomass[Yr(2040)]-CapCostBiomass[Yr(2023)])/(2040-2023)
  end

  #
  # Incorporate Biomass CCS values when available - Jeff Amlin 04/08/22
  #
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years
        CapCostBiomassCCS[year] = 55.538
  end
  years=collect(Yr(2040):Final)
  for year in years
        CapCostBiomassCCS[year] = 53.823
  end
  years=collect(Yr(2024):Yr(2039))
    for year in years
    CapCostBiomassCCS[year] = CapCostBiomassCCS[year-1]+
      (CapCostBiomassCCS[Yr(2040)]-CapCostBiomassCCS[Yr(2023)])/(2040-2023)
  end

  #
  # The capital costs for the construction of a pipeline which would bring the H2 to
  # an equivalent location (relative to transportation costs) as a distributed unit.
  # "NREL HDSAM Model\19.12.04 Delivery Cost Jeff Amlin from HDSAM v3.1.xlsm"
  # 7.739($/mmBtu)=50.024(M$ Initial Investment)/56.700(M kg/Yr)/0.1140(mmBtu/Kg)
  #
  @. CapCostDelivery=0
  #
  # Now this is incorporate in the H2Trans cost
  #
  # @. CapCostDelivery=7.739
  #
  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","Interruptible","SMNR"])
  for year in Years, area in Areas, h2tech in h2techs
    H2CCN[h2tech,area,year] = CapCostPEM[year]
  end

  h2techs=Select(H2Tech,"Grid")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
        NH3CCN[h2tech,area,year] = 44.0675
  end
  years=collect(Yr(2040):Final)
  for year in years, area in Areas, h2tech in h2techs
        NH3CCN[h2tech,area,year] = 44.0675
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    NH3CCN[h2tech,area,year] = NH3CCN[h2tech,area,year-1]+
      (NH3CCN[h2tech,area,Yr(2040)]-NH3CCN[h2tech,area,Yr(2023)])/(2040-2023)
  end

  #
  h2techs=Select(H2Tech,"NG")
  for year in Years, area in Areas, h2tech in h2techs
    H2CCN[h2tech,area,year] = CapCostNG[year]
  end

  #
  h2techs=Select(H2Tech,"NGCCS")
  for year in Years, area in Areas, h2tech in h2techs
    H2CCN[h2tech,area,year] = CapCostNGCCS[year]+CapCostDelivery[year]
  end

  #
  h2techs=Select(H2Tech,"NGCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
        NH3CCN[h2tech,area,year] = 56.3332
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
        NH3CCN[h2tech,area,year] = 56.3332
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    NH3CCN[h2tech,area,year] = NH3CCN[h2tech,area,year-1]+
      (NH3CCN[h2tech,area,Yr(2040)]-NH3CCN[h2tech,area,Yr(2023)])/(2040-2023)
  end

  h2techs=Select(H2Tech,"ATRNGCCS")
  for year in Years, area in Areas, h2tech in h2techs
    H2CCN[h2tech,area,year] = CapCostATRNGCCS[year]+CapCostDelivery[year]
  end

  h2techs=Select(H2Tech,"ATRNGCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
        NH3CCN[h2tech,area,year] = 56.3332
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
        NH3CCN[h2tech,area,year] = 56.3332
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    NH3CCN[h2tech,area,year] = NH3CCN[h2tech,area,year-1]+
      (NH3CCN[h2tech,area,Yr(2040)]-NH3CCN[h2tech,area,Yr(2023)])/(2040-2023)
  end

  h2techs=Select(H2Tech,"Biomass")
  for year in Years, area in Areas, h2tech in h2techs
    H2CCN[h2tech,area,year] = CapCostBiomass[year]+CapCostDelivery[year]
  end
  h2techs=Select(H2Tech,"BiomassCCS")
  for year in Years, area in Areas, h2tech in h2techs
    H2CCN[h2tech,area,year] = CapCostBiomassCCS[year]+CapCostDelivery[year]
  end

  #
  # Values are converted from 2016 US$/mmBtu to Local Real $/mmBtu
  #
    # these techs have their capital costs listed in Canadian dollars
    h2techs = Select(H2Tech, ["Grid","OnshoreWind","SolarPV","Interruptible","SMNR","ATRNGCCS"])
    CN = Select(Nation, "CN")
    for year in Years, area in Areas, h2tech in H2Techs
        H2CCN[h2tech,area,year] = H2CCN[h2tech,area,year]/
                                  xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]
    end
    # these techs have their capital costs listed in American dollars
    h2techs = Select(H2Tech, ["BiomassCCS","Biomass","NG","NGCCS"])
  US=Select(Nation,"US")
  for year in Years, area in Areas, h2tech in H2Techs
    H2CCN[h2tech,area,year] = H2CCN[h2tech,area,year]/
      xInflationNation[US,Yr(2016)]*xInflationNation[US,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  WriteDisk(db,"SpInput/H2CCN",H2CCN)
  WriteDisk(db,"SpInput/NH3CCN",NH3CCN)

  #
  ########################
  #
  # Hydrogen Production Capital Charge Rate
  #
  # NREL spreadsheets - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary v10_update.xlsx
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  # NH3 will just take Hydrogen values
  #
  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","Interruptible","SMNR"])
  for year in Years, area in Areas, h2tech in h2techs
        H2CCR[h2tech,area,year] = 0.014
  end
  h2techs=Select(H2Tech,["NG","NGCCS","ATRNGCCS","Biomass","BiomassCCS"])
  for year in Years, area in Areas, h2tech in h2techs
        H2CCR[h2tech,area,year] = 0.05
  end
  WriteDisk(db,"SpInput/H2CCR",H2CCR)

  #
  ########################
  #
  # Hydrogen Production Construction Delay
  # Preliminary value - Jeff Amlin 10/22/19
  #
  @. H2CD=2
  # @. NH3CD=2
  WriteDisk(db,"SpInput/H2CD",H2CD)
  # WriteDisk(db,"SpInput/NH3CD",NH3CD)

  #
  ########################
  #
  # Hydrogen Delivery Charge (Real $/mmBtu)
  #
  mmBtukgH2=0.134551

  #
  # Ratio of ammonia to hydrogen's energy per weight is from:
  # https://www.nh3fuel.com/index.php/faqs/16-ammonia/35-is-ammonia-the-ideal-energy-currency
  #
  mmBtukgNH3=0.134551*7987/51500
  #
  # Ammonia Fuel Delivery Charge based on diesel - PNV 2024.04.05
  #
  # Select Fuel(Diesel)
  # Read(FPDChgF)
  # NH3FPDChg(ES,Area,Year) = FPDChgF(Fuel,ES,Area,Year)

  #
  # Table 8: Estimated hydrogen pipeline network tariffs
  # Source: BNEF 2020 and AMD calculations. 2019USD
  # TranspH2__costs_700km v3.xlsx - Thuo and Jeff Amlin 08/17/20
  #
  @. H2FPDChg=0
  years=collect(Zero:Final)
  es=Select(ES,"Transport")
  for year in years, area in Areas
    H2FPDChg[es,area,year] = 21.28  # New values
  end
  ess=Select(ES,["Commercial","Residential","Industrial"])
  for year in years, area in Areas, es in ess
    H2FPDChg[es,area,year] = 10.06  # New values - different from old calculation
  end

  #
  # Values are converted from 2019 US$/mmBtu to 1985 Local $/mmBtu
  #

  #
  # Industrial Hydrogen produced on site.
  #
  es=Select(ES,"Industrial")
  for year in Years, area in Areas
    H2FPDChg[es,area,year] = 0
  end

  ess = Select(ES, ["Commercial", "Residential", "Industrial", "Transport"])
  for year in Years, area in Areas, es in ess
      H2FPDChg[es, area, year] = H2FPDChg[es, area, year]/xInflationNation[CN, Yr(2016)] * xInflationNation[CN, year]
  end

  WriteDisk(db,"SpInput/H2FPDChg",H2FPDChg)

  #
  # Transmission Costs (H2Trans) are any incremental costs above the
  # standard delivery costs.  In this case, they apply only to NG CCS
  # which must be transported from a central location to the market.
  # Source: BNEF 2020 and AMD calculations. 2019 US$
  # TranspH2__costs_700km v3.xlsx - Thuo and Jeff Amlin 08/17/20
  #
  @. H2Trans=0

  h2techs=Select(H2Tech,["NGCCS","ATRNGCCS","Biomass","BiomassCCS"])
  for year in Years, area in Areas, h2tech in h2techs
    H2Trans[h2tech,area,year] = (10.01-8.63)*0.0
  end

  years=collect(Yr(2040):Final)
  for year in years, area in Areas, h2tech in h2techs
    H2Trans[h2tech,area,year] = (4.96-4.28)*0.0
  end
  years=collect(Yr(2021):Yr(2039))
  for year in years, area in Areas, h2tech in H2Techs
    H2Trans[h2tech,area,year] = H2Trans[h2tech,area,year-1]+
      (H2Trans[h2tech,area,Yr(2040)]-H2Trans[h2tech,area,Yr(2020)])/(2040-2020)
  end

  #
  # Values are converted from 2019 US$/mmBtu to 1985 Local $/mmBtu
  #
  for year in Years, area in Areas, h2tech in H2Techs
    H2Trans[h2tech,area,year] = H2Trans[h2tech,area,year]/
      xInflationNation[US,Yr(2019)]*xInflationNation[US,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  WriteDisk(db,"SpInput/H2Trans",H2Trans)

  #
  ########################
  #
  # Interruptible Electricity Price Multiplier ($/$)
  #
  # Ammonia will use values from Hydrogen
  #
@. H2IPMultiplier=1.0
  h2tech=Select(H2Tech,"Interruptible")
  for year in Years, area in Areas
    H2IPMultiplier[h2tech,area,year] = 0.10
  end
  WriteDisk(db,"SpInput/H2IPMultiplier",H2IPMultiplier)

  #
  ########################
  #
  # Hydrogen Fixed O&M Cost Factor ($/$/Yr)
  #
  # NREL spreadsheets - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary v10_update.xlsx
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  #
  @. H2OF=0.00
  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","Interruptible","SMNR"])
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0100  # Changed from 0.0550
  end
  for area in Areas, h2tech in h2techs
    H2OF[h2tech,area,Yr(2030)] = 0.0135  # Changed from 0.0578
  end
  years=collect(Yr(2024):Yr(2029))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = H2OF[h2tech,area,year-1]+
      (H2OF[h2tech,area,Yr(2030)]-H2OF[h2tech,area,Yr(2023)])/(2030-2023)
  end
  years=collect(Yr(2040):Final)
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0157  # Changed from 0.0652
  end
  years=collect(Yr(2031):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = H2OF[h2tech,area,year-1]+
      (H2OF[h2tech,area,Yr(2040)]-H2OF[h2tech,area,Yr(2030)])/(2040-2030)
  end

  h2techs=Select(H2Tech,"NG")
  for year in Years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.1004
  end

  h2techs=Select(H2Tech,"NGCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0925
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.1119
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = H2OF[h2tech,area,year-1]+
      (H2OF[h2tech,area,Yr(2040)]-H2OF[h2tech,area,Yr(2023)])/(2040-2023)
  end

  #
  # From Thuo email on June 13, 2022.
  # Source: "IHS-HydrogenModel_NoLink v2.xlsx"
  #
  # round up to two decimals
  h2techs=Select(H2Tech,"ATRNGCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.010  # Changed from 0.07229
  end
  for area in Areas, h2tech in h2techs
    H2OF[h2tech,area,Yr(2030)] = 0.010  # Changed from 0.0770
  end
  years=collect(Yr(2024):Yr(2029))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = H2OF[h2tech,area,year-1]+
      (H2OF[h2tech,area,Yr(2030)]-H2OF[h2tech,area,Yr(2023)])/(2030-2023)
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0100  # Changed from 0.0852
  end
  years=collect(Yr(2031):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = H2OF[h2tech,area,year-1]+
      (H2OF[h2tech,area,Yr(2040)]-H2OF[h2tech,area,Yr(2030)])/(2040-2030)
  end

  h2techs=Select(H2Tech,"Biomass")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0888
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0774
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = H2OF[h2tech,area,year-1]+
      (H2OF[h2tech,area,Yr(2040)]-H2OF[h2tech,area,Yr(2023)])/(2040-2023)
  end

  #
  # Incorporate Biomass CCS values when available - Jeff Amlin 04/08/22
  #
  h2techs=Select(H2Tech,"BiomassCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0888
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = 0.0774
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2OF[h2tech,area,year] = H2OF[h2tech,area,year-1]+
      (H2OF[h2tech,area,Yr(2040)]-H2OF[h2tech,area,Yr(2023)])/(2040-2023)
  end

  WriteDisk(db,"SpInput/H2OF",H2OF)

  # Email - From: Kossa, Khodeu Thuo Zhagnin Sent: Monday, July 27, 2020 5:17 PM
  #         To: Jeff Amlin; Robin White; Luke Davulis
  #         Subject: RE: ECCC - Hydrogen Tasks from July 21 Meeting
  # Source: HDV_Fuel Cell_capital costs_O&M v2.xlsx
  # Table 5: Capex and technical assumptions for large-scale hydrogen fuel cell power stations
  # Source: BloombergNEF, 2020
  # In discussions, we decided to use 0.5% - Jeff Amlin 08/04/20
  #
  # Old value, commented out.
  # @. H2OF=0.005
  # WriteDisk(db,"SpInput/H2OF",H2OF)

  h2techs=Select(H2Tech,["NGCCS","ATRNGCCS"])
  for area in Areas, h2tech in h2techs
    NH3OF[h2tech,area,Yr(2023)] = 2.73
  end
  years=collect(Yr(2040):Final)
  for year in years, area in Areas, h2tech in h2techs
    NH3OF[h2tech,area,year] = 2.66
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    NH3OF[h2tech,area,year] = NH3OF[h2tech,area,year-1]+
      (NH3OF[h2tech,area,Yr(2040)]-NH3OF[h2tech,area,Yr(2023)])/(2040-2023)
  end

  h2techs=Select(H2Tech,"Grid")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    NH3OF[h2tech,area,year] = 2.80
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    NH3OF[h2tech,area,year] = 2.71
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    NH3OF[h2tech,area,year] = NH3OF[h2tech,area,year-1]+
      (NH3OF[h2tech,area,Yr(2040)]-NH3OF[h2tech,area,Yr(2023)])/(2040-2023)
  end

  WriteDisk(db,"SpInput/NH3OF",NH3OF)

  #
  ########################
  #
  @. H2SmT=2.0
  WriteDisk(db,"SpInput/H2SmT",H2SmT)

  #
  ########################
  #
  # Hydrogen Production Variable O&M Cost Factor (Real $/mmBtu)
  #
  # NREL spreadsheets - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary v10_update.xlsx
  # Biomass spreadsheet from Khodeu Thuo Zhagnin Kossa email - Jeff Amlin 03/07/22
  # C:\2020 Documents\Hydrogen\NREL H2A Model\NREL H2A Summary_Biomass Gasification.xlsx
  # The units are 2016 US$/mmBtu
  #
  # in the LCA model all variable costs are equal to fuel costs
  @. H2UOMC=0.00
  @. NH3UOMC=0.00

  h2techs=Select(H2Tech,["Grid","OnshoreWind","SolarPV","Interruptible","SMNR"])
  for year in Years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 0.00  # Changed from 3.85
  end

  h2techs=Select(H2Tech,["Grid","NGCCS","ATRNGCCS"])
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    NH3UOMC[h2tech,area,year] = 0.592
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    NH3UOMC[h2tech,area,year] = 0.592
  end
  years=collect(Yr(2024):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    NH3UOMC[h2tech,area,year] = NH3UOMC[h2tech,area,year-1]+
      (NH3UOMC[h2tech,area,Yr(2040)]-NH3UOMC[h2tech,area,Yr(2023)])/(2040-2023)
  end

  h2techs=Select(H2Tech,"NG")
  for year in Years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 0.1026
  end

  h2techs=Select(H2Tech,"NGCCS")
  for year in Years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 2.4378
  end

  #
  # From Thuo email on June 13, 2022.
  # Source: "IHS-HydrogenModel_NoLink v2.xlsx"
  #
  # variable operating costs are the costs related to sequestration
  h2techs=Select(H2Tech,"ATRNGCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 1.56  # Changed from 2.0464
  end
  for area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,Yr(2030)] = 1.56  # Changed from 2.0285
  end
  years=collect(Yr(2024):Yr(2029))
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = H2UOMC[h2tech,area,year-1]+
      (H2UOMC[h2tech,area,Yr(2030)]-H2UOMC[h2tech,area,Yr(2023)])/(2030-2023)
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 1.56  # Changed from 1.9052
  end
  years=collect(Yr(2031):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = H2UOMC[h2tech,area,year-1]+
      (H2UOMC[h2tech,area,Yr(2040)]-H2UOMC[h2tech,area,Yr(2030)])/(2040-2030)
  end

  h2techs=Select(H2Tech,"Biomass")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 1.59
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 0.9554
  end
  years=collect(Yr(2026):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = H2UOMC[h2tech,area,year-1]+
      (H2UOMC[h2tech,area,Yr(2040)]-H2UOMC[h2tech,area,Yr(2023)])/(2040-2023)
  end

  #
  # Incorporate Biomass CCS values when available - Jeff Amlin 04/08/22
  #
  h2techs=Select(H2Tech,"BiomassCCS")
  years=collect(Zero:Yr(2025))  # Changed from Yr(2023)
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 2.6703
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = 2.7850
  end
  years=collect(Yr(2026):Yr(2039))
  for year in years, area in Areas, h2tech in h2techs
    H2UOMC[h2tech,area,year] = H2UOMC[h2tech,area,year-1]+
      (H2UOMC[h2tech,area,Yr(2040)]-H2UOMC[h2tech,area,Yr(2023)])/(2040-2023)
  end

  #
  # Values are converted from 2016 CN$/mmBtu to 1985 Local $/mmBtu
  #
  CN=Select(Nation,"CN")
  for year in Years, area in Areas, h2tech in H2Techs
    H2UOMC[h2tech,area,year] = H2UOMC[h2tech,area,year]/
      xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]/xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  for year in Years, area in Areas, h2tech in H2Techs
    NH3UOMC[h2tech,area,year] = NH3UOMC[h2tech,area,year]/
      xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]/xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
    #set for pem and atr
    CN = Select(Nation, "CN")
    h2techs = Select(H2Tech, ["OnshoreWind","SolarPV","Interruptible","SMNR","ATRNGCCS"])
    for year in Years, area in Areas, h2tech in H2Techs
        H2UOMC[h2tech,area,year] = H2UOMC[h2tech,area,year]/
                                   xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]
    end
  WriteDisk(db,"SpInput/H2UOMC",H2UOMC)
  WriteDisk(db,"SpInput/NH3UOMC",NH3UOMC)

  #
  ########################
  #
  # Hydrogen Production Subsidy ($/mmBtu)
  #
  @. H2Subsidy = 0.0
  @. NH3Subsidy = 0.0
  WriteDisk(db,"SpInput/H2Subsidy",H2Subsidy)
  WriteDisk(db,"SpInput/NH3Subsidy",NH3Subsidy)

  #
  ########################
  #
  years=collect(Zero:Yr(2020))
  for year in years
    Shipping[year] = 23.41
  end
  years=collect(Yr(2040):Yr(2050))
  for year in years
    Shipping[year] = 15.76
  end
  years=collect(Future:Yr(2039))
  for year in years
    Shipping[year] = Shipping[year-1]+
      (Shipping[Yr(2040)]-Shipping[Yr(2020)])/(2040-2020)
  end

  for year in Years, nation in Nations
    H2ExportsCharge[nation,year] = Shipping[year]/xInflationNation[US,Yr(2019)]*xInflationNation[US,year]*
      xExchangeRateNation[nation,year]/xInflationNation[nation,year]
    H2ImportsCharge[nation,year] = Shipping[year]/xInflationNation[US,Yr(2019)]*xInflationNation[US,year]*
      xExchangeRateNation[nation,year]/xInflationNation[nation,year]
  end

  WriteDisk(db,"SpInput/H2ExportsCharge",H2ExportsCharge)
  WriteDisk(db,"SpInput/H2ImportsCharge",H2ImportsCharge)

  #
  ########################
  #
  @. H2ExportsMSM0 = -170.00
  @. H2ImportsMSM0 = -170.00
  WriteDisk(db,"SpInput/H2ExportsMSM0",H2ExportsMSM0)
  WriteDisk(db,"SpInput/H2ImportsMSM0",H2ImportsMSM0)

  #
  ########################
  #
  @. H2ExportsVF = -10.00
  @. H2ImportsVF = -10.00
  WriteDisk(db,"SpInput/H2ExportsVF",H2ExportsVF)
  WriteDisk(db,"SpInput/H2ImportsVF",H2ImportsVF)

  #
  ########################
  #
  # Hydrogen Production Load Shape (MW/MW)
  #
  # Ammonia will use Hydrogen figures
  #
  area1=first(Areas)
  hour=first(Hours)
  h2tech=Select(H2Tech,"Grid")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /Grid
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"OnshoreWind")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /OnshoreWind
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"SolarPV")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /SolarPV
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"Interruptible")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /Interruptible
    0.00  1.00  1.00 # Summer
    0.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"NG")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /SMR NG
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"NGCCS")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /SMR NG w CCS
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"ATRNGCCS")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /ATR NG w CCS
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"Biomass")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /SMR Biomass
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"BiomassCCS")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /Biomass w CCS
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"SMNR")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /SMNR
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"MP")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /MP
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  h2tech=Select(H2Tech,"Other")
  LSFLoad[Months,Days] = [
  # Peak   Ave   Min /Other
    1.00  1.00  1.00 # Summer
    1.00  1.00  1.00 # Winter
  ]
  for day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area1] = LSFLoad[month,day]
  end

  for area in Areas, hour in Hours, h2tech in H2Techs, day in Days, month in Months
    xH2LSF[h2tech,hour,day,month,area] = xH2LSF[h2tech,hour,day,month,area1]
  end

  #
  # Normalize the average day load shape.
  #
  Average=Select(Day,"Average")
  for h2tech in H2Techs
    NormLoad[h2tech] = sum(xH2LSF[h2tech,hour,Average,month,area1]*
      HoursPerMonth[month] for hour in Hours, month in Months)/8760
  end
  for area in Areas, month in Months, hour in Hours, h2tech in H2Techs
    @finite_math xH2LSF[h2tech,hour,Average,month,area] = xH2LSF[h2tech,hour,Average,month,area]/
      NormLoad[h2tech]
  end

  @. H2LSF=xH2LSF

  WriteDisk(db,"SCalDB/H2LSF",H2LSF)
  WriteDisk(db,"SpInput/xH2LSF",xH2LSF)

  #
  ########################
  #
  # Hydrogen Exogenous Market Share (mmBtu/mmBtu)
  #
  @. xH2MSF=0
  WriteDisk(db,"SpInput/xH2MSF",xH2MSF)

  #
  ########################
  #
  # Ammonia Exogenous Exports (TBtu/Year)
  #
  @. xNH3Exports=0
  WriteDisk(db,"SpInput/xNH3Exports",xNH3Exports)

  #
  ########################
  #
  # Pipeline Efficiency Multipliers
  #
  @. H2PipeA0=0
  @. H2PipeB0=0
  @. H2PipeC0=0
  areas=findall(ANMap[:,CN] .== 1)
  years=collect(Future:Final)
  #
  # Placeholder for future values
  #
  for year in years, area in areas
    H2PipeA0[area,year] = 0
    H2PipeB0[area,year] = 0
    H2PipeC0[area,year] = 0
  end
  WriteDisk(db,"SpInput/H2PipeA0",H2PipeA0)
  WriteDisk(db,"SpInput/H2PipeB0",H2PipeB0)
  WriteDisk(db,"SpInput/H2PipeC0",H2PipeC0)

end

function CalibrationControl(db)
  @info "Hydrogen.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
