#
# CarbonRemoval.jl - Carbon Removal Input Data
# This txt supplies data for a number of different techs associated with carbon removal.
# A few different types of DAC are modelled as well as a form of enhanced rock weathering.
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2024 Systematic Solutions, Inc.  All rights reserved.
#
using EnergyModel

module CarbonRemoval

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
  DACTech::SetArray = ReadDisk(db,"SInput/DACTechKey")
  DACTechDS::SetArray = ReadDisk(db,"SInput/DACTechDS")
  DACTechs::Vector{Int} = collect(Select(DACTech))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Wholesale Price ($/mmBtu)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (1985 US$/mmBtu)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  
  DACBL::VariableArray{3} = ReadDisk(db,"SpInput/DACBL") # [DACTech,Area,Year] DAC Book Lifetime (Years)

  DACCUFP::VariableArray{3} = ReadDisk(db,"SpInput/DACCUFP") # [DACTech,Area,Year] DAC Production Capacity Utilization Factor for Planning (Tonnes/Tonnes)
  DACCUFMax::VariableArray{2} = ReadDisk(db,"SpInput/DACCUFMax") # [Area,Year] DAC Production Capacity Utilization Factor Maximum (Tonnes/Tonnes)
  DACDmFrac::VariableArray{4} = ReadDisk(db,"SpInput/DACDmFrac") # [Fuel,DACTech,Area,Year] DAC Production Energy Usage Fraction
  DACEff::VariableArray{3} = ReadDisk(db,"SpInput/DACEff") # [DACTech,Area,Year] DAC Production Energy Efficiency (Tonnes/TBtu)
  DACGridFraction::VariableArray{3} = ReadDisk(db,"SpInput/DACGridFraction") # [DACTech,Area,Year] Fraction of Electric Demands Purchased from Grid (Btu/Btu)
  DACIVTC::VariableArray{2} = ReadDisk(db,"SpInput/DACIVTC") #[Area,Year]  DAC Investment Tax Credit ($/$)
  DACMSFSwitch::VariableArray{2} = ReadDisk(db,"SpInput/DACMSFSwitch") # [Area,Year] DAC Market Share Non-Price Factor (Tonnes/Tonnes)
  DACMSM0::VariableArray{3} = ReadDisk(db,"SpInput/DACMSM0") # [DACTech,Area,Year] DAC Market Share Non-Price Factor (Tonnes/Tonnes)
  DACPL::VariableArray{2} = ReadDisk(db,"SpInput/DACPL") # [DACTech,Year] DAC Production Physical Lifetime (Years)
  DACPlantMap::VariableArray{4} = ReadDisk(db,"SpInput/DACPlantMap") # [DACTech,Plant,Power,Area] DAC Process to Plant Type Map
  DACPOCX::VariableArray{4} = ReadDisk(db,"SpInput/DACPOCX") # [FuelEP,Poll,Area,Year] DAC Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
  DACSqFr::VariableArray{4} = ReadDisk(db,"SpInput/DACSqFr") # [DACTech,Poll,Area,Year] DAC Sequestered Pollution Fraction (Tonnes/Tonnes)
  DACSqPenalty::VariableArray{4} = ReadDisk(db,"SpInput/DACSqPenalty") # [DACTech,Poll,Area,Year] DAC Sequestering Energy Penalty (TBtu/Tonne)
  DACVF::VariableArray{3} = ReadDisk(db,"SpInput/DACVF") # [DACTech,Area,Year] DAC Market Share Variance Factor (Tonnes/Tonnes)
  DACCCM::VariableArray{3} = ReadDisk(db,"SpInput/DACCCM") # [DACTech,Area,Year] DAC Production Capital Cost Mulitplier ($/$)
  DACCCN::VariableArray{3} = ReadDisk(db,"SpInput/DACCCN") # [DACTech,Area,Year] DAC Production Capital Cost (Real $/Tonne)
  DACCD::VariableArray{1} = ReadDisk(db,"SpInput/DACCD") # [Year] DAC Production Construction Delay (Years)
  DACTL::VariableArray{3} = ReadDisk(db,"SpInput/DACTL") #[DACTech,Area,Year]  DAC Tax Lifetime (Years)
  DACTrans::VariableArray{3} = ReadDisk(db,"SpInput/DACTrans") # [DACTech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/Tonne)
  DACOF::VariableArray{3} = ReadDisk(db,"SpInput/DACOF") # [DACTech,Area,Year] DAC Production O&M Cost Factor (Real $/$/Yr)
  DACROIN::VariableArray{3} = ReadDisk(db,"SpInput/DACROIN") #[DACTech,Area,Year]  DAC Return on Investment ($/$)
  DACSmT::VariableArray{1} = ReadDisk(db,"SpInput/DACSmT") # [Year] DAC Production Growth Rate Smoothing Time (Years)
  DACUOMC::VariableArray{3} = ReadDisk(db,"SpInput/DACUOMC") # [DACTech,Area,Year] DAC Production Variable O&M Costs (Real $/Tonne)
  DACSubsidy::VariableArray{2} = ReadDisk(db,"SpInput/DACSubsidy") # [Area,Year] DAC Production Subsidy ($/Tonne)
  DACLSF::VariableArray{5} = ReadDisk(db,"SCalDB/DACLSF") # [DACTech,Hour,Day,Month,Area] DAC Production Load Shape (MW/MW)
  xDACLSF::VariableArray{5} = ReadDisk(db,"SpInput/xDACLSF") # [DACTech,Hour,Day,Month,Area] DAC Production Load Shape before Calibration (MW/MW)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  xDACMSF::VariableArray{3} = ReadDisk(db,"SpInput/xDACMSF") # [DACTech,Area,Year] DAC Exogenous Market Share (Tonnes/Tonnes)
  DACSw::VariableArray{2} = ReadDisk(db,"SpInput/DACSw") # [Area,Year] Switch to Determine DAC Target
  DACBuildFracMax::VariableArray{2} = ReadDisk(db,"SpInput/DACBuildFracMax") # [Area,Year] Maximum DAC Build Fraction (Tonnes/Tonnes)
  DACPriceDiffFrac::VariableArray{2} = ReadDisk(db,"SpInput/DACPriceDiffFrac") # [Area,Year] DAC Price Diff Fraction (Tonnes/Tonnes)

  # Scratch Variables
  ElecGJ::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Input vessel for various calculations
  HeatGJ::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Input vessel for various calculations
  NonEngCost::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Input vessel for various calculations
  NormLoad::VariableArray{1} = zeros(Float32,length(DACTech)) # [DACTech] Annual Value used to Normalize Loads (GWh)
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,Areas,DACTech,DACTechs,Day,Days,EC) = data
  (;Enduse,Fuel,Fuels,FuelEPs) = data
  (;Hours,Months,Nation) = data
  (;Poll,Polls) = data
  (;Years) = data
  (;xExchangeRate,xExchangeRateNation,xInflation,xInflationNation) = data
  (;DACBL,DACBuildFracMax,DACCCM,DACCCN,DACCD,DACCUFP,DACCUFMax,DACDmFrac,DACEff) = data
  (;DACGridFraction,DACIVTC,DACMSFSwitch,DACMSM0,DACPL,DACPlantMap,DACPOCX,POCX,DACSqFr,DACSqPenalty,DACVF) = data
  (;DACCCM,DACCCN,DACCD,DACTL,DACTrans,DACOF,DACROIN,DACSmT,DACUOMC,DACSubsidy,DACLSF) = data
  (;xDACLSF,HoursPerMonth,xDACMSF,DACSw,DACBuildFracMax,DACPriceDiffFrac) = data
  (;ElecGJ,HeatGJ,NonEngCost,NormLoad) = data

  #
  ########################
  #
  # Data From Noah Conrad (ECCC) by email - Jeff Amlin 5/06/2024
  # Source: C:\2020 Documents\DAC\Carbon Removal Costs.xlsx
  #
  ########################
  #
  # DAC Book Lifetime (Years)
  #
  @. DACBL=20
  WriteDisk(db,"SpInput/DACBL",DACBL)

  ########################
  #
  # Maximum DAC Build Fraction (Tonnes/Tonnes)
  #
  @. DACBuildFracMax=1.0
  WriteDisk(db,"SpInput/DACBuildFracMax",DACBuildFracMax)

  #
  ########################
  #
  # DAC Production Capital Cost Multiplier ($/$)
  # Preliminary value - Jeff Amlin 10/22/19
  #
  @. DACCCM=1.00
  WriteDisk(db,"SpInput/DACCCM",DACCCM)

  #
  ########################
  #
  # DAC Production Capital Cost (Real $/Tonne)
  #
  @. DACCCN=0.0

  #
  # KOHLoop
  #
  dactech=Select(DACTech,"KOHLoop")
  for area in Areas
    DACCCN[dactech,area,Yr(2025)]=1432.41
    DACCCN[dactech,area,Yr(2050)]=556.1082
  end
  #
  # KOHLBPMED
  #
  dactech=Select(DACTech,"KOHBPMED")
  for area in Areas
    DACCCN[dactech,area,Yr(2025)]=646.26
    DACCCN[dactech,area,Yr(2050)]=166.8002
  end
  #
  # SSorbent
  #
  dactech=Select(DACTech,"SSorbent")
  for area in Areas
    DACCCN[dactech,area,Yr(2025)]=1724.99
    DACCCN[dactech,area,Yr(2050)]=290.1199
  end
  #
  # AmbientW
  #
  dactech=Select(DACTech,"AmbientW")
  for area in Areas
    DACCCN[dactech,area,Yr(2025)]=1683.73
    DACCCN[dactech,area,Yr(2050)]=664.2189
  end

  
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])
  #
  # Interpolate between 2025 and 2050
  #
  years=collect(Yr(2026):Yr(2049))
  for year in years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=DACCCN[dactech,area,year-1]+
        (DACCCN[dactech,area,Yr(2050)]-DACCCN[dactech,area,Yr(2025)])/(2050-2025)
  end
  #
  # Values are converted from 2016 CN$/Tonne to Local Real $/Tonne
  #
  CN=Select(Nation,"CN")
  for year in Years, area in Areas, dactech in DACTechs
    DACCCN[dactech,area,year]=DACCCN[dactech,area,year]/xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]/
        xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  WriteDisk(db,"SpInput/DACCCN",DACCCN)

  #
  ########################
  #
  # DAC Production Construction Delay
  #
  @. DACCD=2
  WriteDisk(db,"SpInput/DACCD",DACCD)

  #
  ########################
  #
  # DAC Production Capacity Utilization Factor for Planning (Tonnes/Tonnes)
  #
  @. DACCUFP=0.90
  WriteDisk(db,"SpInput/DACCUFP",DACCUFP)

  #
  ########################
  #
  # DAC Production Capacity Utilization Factor Maximum (Tonnes/Tonnes)
  #
  dactech1=first(DACTechs)
  for year in Years, area in Areas
    DACCUFMax[area,year]=DACCUFP[dactech1,area,year]*1.10
  end
  WriteDisk(db,"SpInput/DACCUFMax",DACCUFMax)

  #
  ########################
  #
  # DAC Production Energy Usage Fraction
  #
  # KOHLoop
  #
  dactechs=Select(DACTech,"KOHLoop")
  year=Yr(2025)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=1.31/(1.31+5.2)
  end
  fuel=Select(Fuel,"NaturalGas")
  # TODOPromulaExtra - From Jeff: What for Julia values look like? - mismatches in weighted averages?
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=5.2/(1.31+5.22)
  end
  #
  year=Yr(2050)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=1.18/(1.18+4.4)
  end
  fuel=Select(Fuel,"NaturalGas")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=4.4/(1.18+4.4)
  end

  #
  # KOHBPMED
  #
  dactechs=Select(DACTech,"KOHBPMED")
  year=Yr(2025)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=17.86/(17.86+0.00)
  end
  year=Yr(2050)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=14.38/(14.38+0.00)
  end

  #
  # SSorbent
  #
  dactechs=Select(DACTech,"SSorbent")
  year=Yr(2025)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=3.69/(3.69+0.00)
  end
  year=Yr(2050)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=3.325/(3.325+0.00)
  end

  #
  # AmbientW
  #
  dactechs=Select(DACTech,"AmbientW")
  year=Yr(2025)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=0.78/(0.78+6.20)
  end
  fuel=Select(Fuel,"NaturalGas")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=6.20/(0.78+6.20)
  end
  year=Yr(2050)
  fuel=Select(Fuel,"Electric")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=0.73/(0.73+5.24)
  end
  fuel=Select(Fuel,"NaturalGas")
  for area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=5.24/(0.73+5.24)
  end

  #
  # Interpolate between 2025 and 2050
  #
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])
  years=collect(Yr(2026):Yr(2049))
  for year in years, area in Areas, dactech in dactechs, fuel in Fuels
    DACDmFrac[fuel,dactech,area,year]=DACDmFrac[fuel,dactech,area,year-1]+
        (DACDmFrac[fuel,dactech,area,Yr(2050)]-DACDmFrac[fuel,dactech,area,Yr(2025)])/(2050-2025)
  end
  WriteDisk(db,"SpInput/DACDmFrac",DACDmFrac)

  #
  ########################
  #
  # DAC Production Energy Efficiency (Tonnes/TBtu)
  #
  KJBtu=1.054615

  @. DACEff=0

  #
  # KOHLoop
  #
  dactechs=Select(DACTech,"KOHLoop")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((1.31+5.2)/(KJBtu*1e6))
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((1.18+4.4)/(KJBtu*1e6))
  end

  #
  # KOHBPMED
  #
  dactechs=Select(DACTech,"KOHBPMED")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((17.86+0.00)/(KJBtu*1e6))
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((14.38+0.00)/(KJBtu*1e6))
  end

  #
  # SSorbent
  #
  dactechs=Select(DACTech,"SSorbent")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((3.69+0.00)/(KJBtu*1e6))
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((3.325+0.00)/(KJBtu*1e6))
  end

  #
  # AmbientW
  #
  dactechs=Select(DACTech,"AmbientW")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((0.78+6.20)/(KJBtu*1e6))
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((0.73+5.24)/(KJBtu*1e6))
  end

  #
  # Interpolate between 2025 and 2050
  #
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])
  years=collect(Yr(2026):Yr(2049))
  for year in years, area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=DACEff[dactech,area,year-1]+
        (DACEff[dactech,area,Yr(2050)]-DACEff[dactech,area,Yr(2025)])/(2050-2025)
  end
  WriteDisk(db,"SpInput/DACEff",DACEff)

  #
  ########################
  #
  # Fraction of Electric Demands Purchased from Grid (Btu/Btu)'
  #
  @. DACGridFraction=1.0
  WriteDisk(db,"SpInput/DACGridFraction",DACGridFraction)

  #
  ########################
  #
  # DAC Investment Tax Credit ($/$)
  #
  @. DACIVTC=0.0
  WriteDisk(db,"SpInput/DACIVTC",DACIVTC)

  #
  ########################
  #
  # DAC Market Share Non-Price Factor (Tonnes/Tonnes)'
  #
  @. DACMSFSwitch=1
  WriteDisk(db,"SpInput/DACMSFSwitch",DACMSFSwitch)

  #
  ########################
  #
  # DAC Market Share Non-Price Factor (mmBtu/mmBtu)
  # Placeholder data needs to be replaced - Jeff Amlin 10/22/19
  #
  @. DACMSM0=-170

  #
  years=collect(Future:Final)
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])
  for year in years, area in Areas, dactech in dactechs
    DACMSM0[dactech,area,year]=0.0
  end

  WriteDisk(db,"SpInput/DACMSM0",DACMSM0)


  #
  ########################
  #
  # DAC Fixed O&M Cost Factor ($/$/Yr)
  #
  @. DACOF=0.00
  #
  # KOHLoop
  #
  dactechs=Select(DACTech,"KOHLoop")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=82.87
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=49.87
  end

  #
  # KOHBPMED
  #
  dactechs=Select(DACTech,"KOHBPMED")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=50.71
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=27.65
  end

  #
  # SSorbent
  #
  dactechs=Select(DACTech,"SSorbent")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=79.16
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=36.05
  end

  #
  # AmbientW
  #
  dactechs=Select(DACTech,"AmbientW")
  year=Yr(2025)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=94.00
  end
  year=Yr(2050)
  for area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=53.72
  end


  #
  # Interpolate between 2025 and 2050
  #
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])
  years=collect(Yr(2026):Yr(2049))
  for year in years, area in Areas, dactech in dactechs
    DACOF[dactech,area,year]=DACOF[dactech,area,year-1]+
        (DACOF[dactech,area,Yr(2050)]-DACOF[dactech,area,Yr(2025)])/(2050-2025)
  end

  #
  # Convert from 2016 CN$/Tonne to Local Real $/Tonne
  #
  for year in Years, area in Areas, dactech in DACTechs
    DACOF[dactech,area,year]=DACOF[dactech,area,year]/xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]/
        xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end

  #
  # Divide by capital costs to generate fraction
  #
  for year in Years, area in Areas, dactech in DACTechs
    @finite_math DACOF[dactech,area,year]=DACOF[dactech,area,year]/DACCCN[dactech,area,year]
  end
  WriteDisk(db,"SpInput/DACOF",DACOF)

  #
  ########################
  #
  # DAC Production Physical Lifetime (Years)
  #
  @. DACPL=20
  WriteDisk(db,"SpInput/DACPL",DACPL)

  #
  ########################
  #
  # DAC Process to Plant Type Map
  #
  @. DACPlantMap=0
  WriteDisk(db,"SpInput/DACPlantMap",DACPlantMap)

  #
  ########################
  #
  # DAC Pollution Coefficient (Tonnes/TBtu)
  #
  ec=Select(EC,"Fertilizer")
  enduse=Select(Enduse,"Heat")
  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    DACPOCX[fuelep,poll,area,year]=POCX[enduse,fuelep,ec,poll,area,year]
  end
  WriteDisk(db,"SpInput/DACPOCX",DACPOCX)

  #
  ########################
  #
  # DAC Price Diff Fraction (Tonnes/Tonnes)
  #
  @. DACPriceDiffFrac=0.5
  WriteDisk(db,"SpInput/DACPriceDiffFrac",DACPriceDiffFrac)

  #
  ########################
  #
  # DAC Return on Investment ($/$)
  #
  # This can be adjusted to adjust the CCR
  #
  @. DACROIN=0.25
  WriteDisk(db,"SpInput/DACROIN",DACROIN)

  #
  ########################
  #
  # DAC Production Growth Rate Smoothing Time (Years)
  #
  @. DACSmT=2.0
  WriteDisk(db,"SpInput/DACSmT",DACSmT)

  #
  ########################
  #
  # DAC Sequestered Pollution Fraction (Tonnes/Tonnes)'
  #
  @. DACSqFr=0.0
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])
  poll=Select(Poll,"CO2")
  for year in Years, area in Areas, dactech in dactechs
    DACSqFr[dactech,poll,area,year]=0.90
  end
  WriteDisk(db,"SpInput/DACSqFr",DACSqFr)

  #
  ########################
  #
  # DAC Sequestering Energy Penalty (TBtu/Tonne)'
  #
  # MWh/tCO2 of electricity
  # Penalty is expressed in MWh/tonne CO2, but this energy may come from any fuel
  # - Jeff Amlin 4/11/24
  #
  poll=Select(Poll,"CO2")
  dactechs=Select(DACTech,"KOHLoop")
  for year in Years, area in Areas, dactech in dactechs
    DACSqPenalty[dactech,poll,area,year]= 0.1 *1000*3412/1e12
  end
  dactechs=Select(DACTech,"KOHBPMED")
  for year in Years, area in Areas, dactech in dactechs
    DACSqPenalty[dactech,poll,area,year]= 0.1 *1000*3412/1e12
  end
  dactechs=Select(DACTech,"SSorbent")
  for year in Years, area in Areas, dactech in dactechs
    DACSqPenalty[dactech,poll,area,year]= 0.1 *1000*3412/1e12
  end
  dactechs=Select(DACTech,"AmbientW")
  for year in Years, area in Areas, dactech in dactechs
    DACSqPenalty[dactech,poll,area,year]= 0.1 *1000*3412/1e12
  end

  WriteDisk(db,"SpInput/DACSqPenalty",DACSqPenalty)

  #
  ########################
  #
  # DAC Production Subsidy ($/Tonne)
  #
  @. DACSubsidy=0.0
  WriteDisk(db,"SpInput/DACSubsidy",DACSubsidy)

  #
  ########################
  #
  # Switch to Determine DAC Target
  #
  @. DACSw=0
  WriteDisk(db,"SpInput/DACSw",DACSw)

  #
  ########################
  #
  # DAC Tax Lifetime (Years)'
  #
  # The tax life is 80% of the book life.
  #
  @. DACTL= 0.80*DACBL
  WriteDisk(db,"SpInput/DACTL",DACTL)

  #
  ########################
  #
  # Cost of Transporting Captured Carbon (Real $/Tonne)
  #
  @. DACTrans=0
  #
  # Values are converted from 2016 CN$/mmBtu to Local Real $/mmBtu
  #
  for year in Years, area in Areas, dactech in DACTechs
    DACTrans[dactech,area,year]=DACTrans[dactech,area,year]/xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]/
      xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  WriteDisk(db,"SpInput/DACTrans",DACTrans)

  #
  ########################
  #
  # DAC Production Variable O&M Costs (Real $/mmBtu)
  #
  @. DACUOMC=0.00

  #
  # KOHLoop
  #
  dactech=Select(DACTech,"KOHLoop")
  for area in Areas
    DACUOMC[dactech,area,Yr(2025)]=23.32
    DACUOMC[dactech,area,Yr(2050)]=19.82
  end
  #
  # KOHLBPMED
  #
  dactech=Select(DACTech,"KOHBPMED")
  for area in Areas
    DACUOMC[dactech,area,Yr(2025)]=370.55
    DACUOMC[dactech,area,Yr(2050)]=183.684
  end
  #
  # SSorbent
  #
  dactech=Select(DACTech,"SSorbent")
  for area in Areas
    DACUOMC[dactech,area,Yr(2025)]=111.86
    DACUOMC[dactech,area,Yr(2050)]=65.51
  end
  #
  # AmbientW
  #
  dactech=Select(DACTech,"AmbientW")
  for area in Areas
    DACUOMC[dactech,area,Yr(2025)]=20.49
    DACUOMC[dactech,area,Yr(2050)]=17.25
  end

  
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])
  #
  # Interpolate between 2025 and 2050
  #
  years=collect(Yr(2026):Yr(2049))
  for year in years, area in Areas, dactech in dactechs
    DACUOMC[dactech,area,year]=DACUOMC[dactech,area,year-1]+
        (DACUOMC[dactech,area,Yr(2050)]-DACUOMC[dactech,area,Yr(2025)])/(2050-2025)
  end
  #
  # Values are converted from 2016 CN$/Tonne to Local Real $/Tonne
  #
  for year in Years, area in Areas, dactech in DACTechs
    DACUOMC[dactech,area,year]=DACUOMC[dactech,area,year]/xInflationNation[CN,Yr(2016)]*xInflationNation[CN,year]/
        xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  WriteDisk(db,"SpInput/DACUOMC",DACUOMC)

  #
  ########################
  #
  # DAC Market Share Variance Factor (Tonnes/Tonnes)
  # Preliminary value from Industrial XMVF - Jeff Amlin 10/22/19
  #
  @. DACVF=-2.5
  WriteDisk(db,"SpInput/DACVF",DACVF)

  #
  ########################
  #
  # DAC Production Load Shape (MW/MW)
  #
  area1=first(Areas)
  dactechs=Select(DACTech,["KOHLoop","KOHBPMED","SSorbent","AmbientW"])

  # # Read xDACLSF\16(Month,Day,DACTech,Hour,Area)
  # # /KOHLoop        Peak   Ave   Min
  # # Summer          1.00  1.00  1.00
  # # Winter          1.00  1.00  1.00
  # # /KOHBPMED       Peak   Ave   Min
  # # Summer          1.00  1.00  1.00
  # # Winter          1.00  1.00  1.00
  # # /SSorbent       Peak   Ave   Min
  # # Summer          1.00  1.00  1.00
  # # Winter          1.00  1.00  1.00
  # # /AmbientW       Peak   Ave   Min
  # # Summer          1.00  1.00  1.00
  # # Winter          1.00  1.00  1.00
  
  for month in Months, day in Days, hour in Hours, dactech in dactechs
    xDACLSF[dactech,hour,day,month,area1]=1.0
  end

  for area in Areas, month in Months, day in Days, hour in Hours, dactech in dactechs
    xDACLSF[dactech,hour,day,month,area]=xDACLSF[dactech,hour,day,month,area1]
  end

  #
  # Normalize the average day load shape.
  #
  Average=Select(Day,"Average")
  for dactech in DACTechs
    NormLoad[dactech]=sum(xDACLSF[dactech,hour,Average,month,area1]*
      HoursPerMonth[month] for month in Months, hour in Hours)/8760
  end
  for area in Areas, month in Months, day in Days, hour in Hours, dactech in dactechs
    @finite_math xDACLSF[dactech,hour,day,month,area]=xDACLSF[dactech,hour,day,month,area]/
      NormLoad[dactech]
  end

  @. DACLSF=xDACLSF

  WriteDisk(db,"SCalDB/DACLSF",DACLSF)
  WriteDisk(db,"SpInput/xDACLSF",xDACLSF)

  #
  ########################
  #
  # DAC Exogenous Market Share (Tonnes/Tonnes)
  #
  @. xDACMSF=0
  WriteDisk(db,"SpInput/xDACMSF",xDACMSF)

end

function CalibrationControl(db)
  @info "DirectAirCapture.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
