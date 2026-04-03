#
# DirectAirCapture.jl - Direct Air Carbon Capture and Storage Input Data
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# ? 2016 Systematic Solutions, Inc.  All rights reserved.
#
using EnergyModel

module DirectAirCapture

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
  DACCUFP::VariableArray{3} = ReadDisk(db,"SpInput/DACCUFP") # [DACTech,Area,Year] DAC Production Capacity Utilization Factor for Planning (Tonnes/Tonnes)
  DACCUFMax::VariableArray{2} = ReadDisk(db,"SpInput/DACCUFMax") # [Area,Year] DAC Production Capacity Utilization Factor Maximum (Tonnes/Tonnes)
  DACDmFrac::VariableArray{4} = ReadDisk(db,"SpInput/DACDmFrac") # [Fuel,DACTech,Area,Year] DAC Production Energy Usage Fraction
  DACEff::VariableArray{3} = ReadDisk(db,"SpInput/DACEff") # [DACTech,Area,Year] DAC Production Energy Efficiency (Tonnes/TBtu)
  DACGridFraction::VariableArray{3} = ReadDisk(db,"SpInput/DACGridFraction") # [DACTech,Area,Year] Fraction of Electric Demands Purchased from Grid (Btu/Btu)
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
  DACCCR::VariableArray{3} = ReadDisk(db,"SpInput/DACCCR") # [DACTech,Area,Year] DAC Production Capital Charge Rate ($/$)
  DACCD::VariableArray{1} = ReadDisk(db,"SpInput/DACCD") # [Year] DAC Production Construction Delay (Years)
  DACTrans::VariableArray{3} = ReadDisk(db,"SpInput/DACTrans") # [DACTech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/Tonne)
  DACOF::VariableArray{3} = ReadDisk(db,"SpInput/DACOF") # [DACTech,Area,Year] DAC Production O&M Cost Factor (Real $/$/Yr)
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
  (;Enduse,Fuel,FuelEPs) = data
  (;Hours,Months,Nation) = data
  (;Poll,Polls) = data
  (;Years) = data
  (;xExchangeRate,xExchangeRateNation,xInflation,xInflationNation,DACCUFP,DACCUFMax,DACDmFrac,DACEff) = data
  (;DACGridFraction,DACMSFSwitch,DACMSM0,DACPL,DACPlantMap,DACPOCX,POCX,DACSqFr,DACSqPenalty,DACVF) = data
  (;DACCCM,DACCCN,DACCCR,DACCD,DACTrans,DACOF,DACSmT,DACUOMC,DACSubsidy,DACLSF) = data
  (;xDACLSF,HoursPerMonth,xDACMSF,DACSw,DACBuildFracMax,DACPriceDiffFrac) = data
  (;ElecGJ,HeatGJ,NonEngCost,NormLoad) = data

  #
  ########################
  # NOTE: All values are placeholder values, as of 5/09/2022
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
  # Data From Gabi Diner (CER) by email - Jeff Amlin 3/29/2022
  #
  # Technology    Energy Needs    Costs
  #               (GJ/tCO2)       ($CAD2020/tCO2)
  #               Elect.  Heat    Capital   O&M
  # Liquid DAC    1.32    5.25    1149.61   43.49
  # Solid DAC     2.82    7.2     1095.48   40.53
  #
  #####
  #
  # DAC From EMF (2021-11-12 EMF 37 CMSG-DAC.pptx)
  #
  # 2020             Energy Needs    NonEnergy Costs
  # Tech             (GJ/tCO2)       (US$2015/tCO2)
  #                  Elect.  Heat
  # High Temp Gas    1.8     8.1      300
  # High Temp Elec   6.0     0.0      390
  # Low Temp Elec    3.5     0.0      410
  #
  # 2020             Energy Needs    NonEnergy Costs
  # Tech             (GJ/tCO2)       (US$2015/tCO2)
  #                  Elect.  Heat
  # High Temp Gas    1.3     5.3      180
  # High Temp Elec   5.0     0.0      220
  # Low Temp Elec    2.1     0.0      200
  #
  dactechs=Select(DACTech,["LiquidH2","LiquidNG"])
  fuel=Select(Fuel,"Electric")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=1.31/(1.32+5.25)
  end
  dactechs=Select(DACTech,"LiquidNG")
  fuel=Select(Fuel,"NaturalGas")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=5.25/(1.32+5.25)
  end
  dactechs=Select(DACTech,"LiquidH2")
  fuel=Select(Fuel,"Hydrogen")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=5.25/(1.32+5.25)
  end

  dactechs=Select(DACTech,["SolidH2","SolidNG"])
  fuel=Select(Fuel,"Electric")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=2.82/(2.82+7.2)
  end
  dactechs=Select(DACTech,"SolidNG")
  fuel=Select(Fuel,"NaturalGas")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=7.2/(2.82+7.2)
  end
  dactechs=Select(DACTech,"SolidH2")
  fuel=Select(Fuel,"Hydrogen")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=7.2/(2.82+7.2)
  end

  years=collect(Zero:Yr(2020))
  for year in years
    ElecGJ[year]=1.8
    HeatGJ[year]=8.1
  end
  years=collect(Yr(2050):Final)
  for year in years
    ElecGJ[year]=1.3
    HeatGJ[year]=5.3
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    ElecGJ[year]=ElecGJ[year-1]+(ElecGJ[Yr(2050)]-ElecGJ[Yr(2020)])/(2050-2020)
    HeatGJ[year]=HeatGJ[year-1]+(HeatGJ[Yr(2050)]-HeatGJ[Yr(2020)])/(2050-2020)
  end

  dactechs=Select(DACTech,"HTGas")
  Electric=Select(Fuel,"Electric")
  NaturalGas=Select(Fuel,"NaturalGas")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[Electric,dactech,area,year]=ElecGJ[year]/(ElecGJ[year]+HeatGJ[year])
    DACDmFrac[NaturalGas,dactech,area,year]=HeatGJ[year]/(ElecGJ[year]+HeatGJ[year])
  end

  dactechs=Select(DACTech,["HTElec","LTElec"])
  fuel=Select(Fuel,"Electric")
  for year in Years, area in Areas, dactech in dactechs
    DACDmFrac[fuel,dactech,area,year]=1
  end

  WriteDisk(db,"SpInput/DACDmFrac",DACDmFrac)

  #
  ########################
  #
  # DAC Production Energy Efficiency (Tonnes/TBtu)
  #
  KJBtu=1.054615

  @. DACEff=0
  dactechs=Select(DACTech,["LiquidH2","LiquidNG"])
  for year in Years, area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((1.32+5.25)/(KJBtu*1e6))
  end
  dactechs=Select(DACTech,["SolidH2","SolidNG"])
  for year in Years, area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((2.82+7.2)/(KJBtu*1e6))
  end

  dactechs=Select(DACTech,"HTGas")
  years=collect(Zero:Yr(2020))
  for year in years
    ElecGJ[year]=1.8
    HeatGJ[year]=8.1
  end
  years=collect(Yr(2050):Final)
  for year in years
    ElecGJ[year]=1.3
    HeatGJ[year]=5.3
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    ElecGJ[year]=ElecGJ[year-1]+(ElecGJ[Yr(2050)]-ElecGJ[Yr(2020)])/(2050-2020)
    HeatGJ[year]=HeatGJ[year-1]+(HeatGJ[Yr(2050)]-HeatGJ[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((ElecGJ[year]+HeatGJ[year])/(KJBtu*1e6))
  end

  dactechs=Select(DACTech,"HTElec")
  years=collect(Zero:Yr(2020))
  for year in years
    ElecGJ[year]=6
  end
  years=collect(Yr(2050):Final)
  for year in years
    ElecGJ[year]=5
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    ElecGJ[year]=ElecGJ[year-1]+(ElecGJ[Yr(2050)]-ElecGJ[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((ElecGJ[year])/(KJBtu*1e6))
  end

  dactechs=Select(DACTech,"LTElec")
  years=collect(Zero:Yr(2020))
  for year in years
    ElecGJ[year]=3.5
  end
  years=collect(Yr(2050):Final)
  for year in years
    ElecGJ[year]=2.1
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    ElecGJ[year]=ElecGJ[year-1]+(ElecGJ[Yr(2050)]-ElecGJ[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACEff[dactech,area,year]=1/((ElecGJ[year])/(KJBtu*1e6))
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
  # Options in the Forecast
  #
  years=collect(Future:Final)
  dactechs=Select(DACTech,["LiquidNG","SolidNG"])
  for year in years, area in Areas, dactech in dactechs
    DACMSM0[dactech,area,year]=0.0
  end

  areas=Select(Area,["BC","QC"])
  dactechs=Select(DACTech,["LiquidNG","SolidNG"])
  for year in years, area in areas, dactech in dactechs
    DACMSM0[dactech,area,year]=-10.0
  end
  dactechs=Select(DACTech,["LiquidH2","SolidH2"])
  for year in years, area in areas, dactech in dactechs
    DACMSM0[dactech,area,year]=0.0
  end

  areas=Select(Area,"CA")
  dactechs=Select(DACTech,["LiquidNG","SolidNG"])
  for year in years, area in areas, dactech in dactechs
    DACMSM0[dactech,area,year]=-10.0
  end
  dactechs=Select(DACTech,["LiquidH2","SolidH2"])
  for year in years, area in areas, dactech in dactechs
    DACMSM0[dactech,area,year]=0.0
  end

  WriteDisk(db,"SpInput/DACMSM0",DACMSM0)

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
  # DAC Sequestered Pollution Fraction (Tonnes/Tonnes)'
  #
  @. DACSqFr=0.0
  dactechs=Select(DACTech,["LiquidNG","SolidNG","HTGas"])
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
  # High CO2 concentration
  # – 0.1 MWh/tCO2 of electricity
  #
  poll=Select(Poll,"CO2")
  for year in Years, area in Areas, dactech in DACTechs
    DACSqPenalty[dactech,poll,area,year]= 0.1 *1000*3412/1e12
  end
  WriteDisk(db,"SpInput/DACSqPenalty",DACSqPenalty)

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
  # DAC Production Capital Cost Multiplier ($/$)
  # Preliminary value - Jeff Amlin 10/22/19
  #
  @. DACCCM=1.00
  WriteDisk(db,"SpInput/DACCCM",DACCCM)

  #
  ########################
  #
  # DAC Production Capital Cost (Real $/mmBtu/Yr)
  #
  @. DACCCN=0.0

  dactechs=Select(DACTech,["LiquidH2","LiquidNG"])
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=1149.61
  end
  dactechs=Select(DACTech,["SolidH2","SolidNG"])
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=1095.48
  end

  #
  # Values are converted from 2020 CN$/Tonne to Local Real $/Tonne
  #
  CN=Select(Nation,"CN")
  for year in Years, area in Areas, dactech in DACTechs
    DACCCN[dactech,area,year]=DACCCN[dactech,area,year]/xInflationNation[CN,Yr(2020)]*xInflationNation[CN,year]/
      xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  #
  #####
  #
  # For EMF Technologies, capital cost estimated where 90% of the the non-fuel costs
  # are presumed to be charged capital costs
  #
  dactechs=Select(DACTech,"HTGas")
  years=collect(Zero:Yr(2020))
  for year in years
    NonEngCost[year]=300
  end
  years=collect(Yr(2050):Final)
  for year in years
    NonEngCost[year]=180
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    NonEngCost[year]=NonEngCost[year-1]+(NonEngCost[Yr(2050)]-NonEngCost[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=NonEngCost[year]*0.9/0.08
  end

  dactechs=Select(DACTech,"HTElec")
  years=collect(Zero:Yr(2020))
  for year in years
    NonEngCost[year]=390
  end
  years=collect(Yr(2050):Final)
  for year in years
    NonEngCost[year]=220
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    NonEngCost[year]=NonEngCost[year-1]+(NonEngCost[Yr(2050)]-NonEngCost[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=NonEngCost[year]*0.9/0.08
  end

  dactechs=Select(DACTech,"LTElec")
  years=collect(Zero:Yr(2020))
  for year in years
    NonEngCost[year]=410
  end
  years=collect(Yr(2050):Final)
  for year in years
    NonEngCost[year]=200
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    NonEngCost[year]=NonEngCost[year-1]+(NonEngCost[Yr(2050)]-NonEngCost[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=NonEngCost[year]*0.9/0.08
  end

  dactechs=Select(DACTech,["HTGas","HTElec","LTElec"])
  US=Select(Nation,"US")
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=DACCCN[dactech,area,year]/
      xInflationNation[US,Yr(2015)]*xInflationNation[US,year]*xExchangeRate[area,year]/xInflation[area,year]
  end

  WriteDisk(db,"SpInput/DACCCN",DACCCN)

  #
  ########################
  #
  # DAC Production Capital Charge Rate
  #
  @. DACCCR=0.08
  WriteDisk(db,"SpInput/DACCCR",DACCCR)

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
  # Cost of Transporting Captured Carbon (Real $/Tonne)
  #
  @. DACTrans=0
  #
  # Values are converted from 2020 CN$/mmBtu to Local Real $/mmBtu
  #
  for year in Years, area in Areas, dactech in DACTechs
    DACTrans[dactech,area,year]=DACTrans[dactech,area,year]/xInflationNation[CN,Yr(2020)]*xInflationNation[CN,year]/
      xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end
  WriteDisk(db,"SpInput/DACTrans",DACTrans)

  #
  ########################
  #
  # DAC Fixed O&M Cost Factor ($/$/Yr)
  #
  @. DACOF=0.00
  WriteDisk(db,"SpInput/DACOF",DACOF)

  #
  ########################
  #
  @. DACSmT=2.0
  WriteDisk(db,"SpInput/DACSmT",DACSmT)

  #
  ########################
  #
  # DAC Production Variable O&M Costs (Real $/mmBtu)
  #
  # The units are 2020 CN$/mmBtu
  #
  @. DACUOMC=0.00
  dactechs=Select(DACTech,["LiquidH2","LiquidNG"])
  for year in Years, area in Areas, dactech in dactechs
    DACUOMC[dactech,area,year]=43.49
  end
  dactechs=Select(DACTech,["SolidH2","SolidNG"])
  for year in Years, area in Areas, dactech in dactechs
    DACUOMC[dactech,area,year]=40.53
  end

  #
  # Values are converted from 2020 CN$/Tonne to 1985 Local $/Tonne
  #
  for year in Years, area in Areas, dactech in DACTechs
    DACUOMC[dactech,area,year]=DACUOMC[dactech,area,year]/xInflationNation[CN,Yr(2020)]*xInflationNation[CN,year]/
      xExchangeRateNation[CN,year]*xExchangeRate[area,year]/xInflation[area,year]
  end

  #
  #####
  #
  # For EMF Technologies, 90% of the the non-fuel costs are presumed to be charged capital costs
  #
  dactechs=Select(DACTech,"HTGas")
  years=collect(Zero:Yr(2020))
  for year in years
    NonEngCost[year]=300
  end
  years=collect(Yr(2050):Final)
  for year in years
    NonEngCost[year]=180
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    NonEngCost[year]=NonEngCost[year-1]+(NonEngCost[Yr(2050)]-NonEngCost[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=NonEngCost[year]*0.1
  end

  dactechs=Select(DACTech,"HTElec")
  years=collect(Zero:Yr(2020))
  for year in years
    NonEngCost[year]=390
  end
  years=collect(Yr(2050):Final)
  for year in years
    NonEngCost[year]=220
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    NonEngCost[year]=NonEngCost[year-1]+(NonEngCost[Yr(2050)]-NonEngCost[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=NonEngCost[year]*0.1
  end

  dactechs=Select(DACTech,"LTElec")
  years=collect(Zero:Yr(2020))
  for year in years
    NonEngCost[year]=410
  end
  years=collect(Yr(2050):Final)
  for year in years
    NonEngCost[year]=200
  end
  years=collect(Yr(2021):Yr(2049))
  for year in years
    NonEngCost[year]=NonEngCost[year-1]+(NonEngCost[Yr(2050)]-NonEngCost[Yr(2020)])/(2050-2020)
  end
  for year in Years, area in Areas, dactech in dactechs
    DACCCN[dactech,area,year]=NonEngCost[year]*0.1
  end

  dactechs=Select(DACTech,["HTGas","HTElec","LTElec"])
  for year in Years, area in Areas, dactech in dactechs
    DACUOMC[dactech,area,year]=DACUOMC[dactech,area,year]/
      xInflationNation[US,Yr(2015)]*xInflationNation[US,year]/xExchangeRate[area,year]/xInflation[area,year]
  end

  WriteDisk(db,"SpInput/DACUOMC",DACUOMC)

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
  # DAC Production Load Shape (MW/MW)
  #
  area1=first(Areas)

  # Read xDACLSF\16(Month,Day,DACTech,Hour,Area)
  # /Liquid H2      Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  # /Liquid NG      Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  # /Soild H2       Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  # /Soild NG       Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  # /HT Gas         Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  # /HT Elec        Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  # /LT Elec        Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  # /Other          Peak   Ave   Min
  # Summer          1.00  1.00  1.00
  # Winter          1.00  1.00  1.00
  @. xDACLSF = 1

  for area in Areas, month in Months, day in Days, hour in Hours, dactech in DACTechs
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
  for area in Areas, month in Months, day in Days, hour in Hours, dactech in DACTechs
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
  # Maximum DAC Build Fraction (Tonnes/Tonnes)
  #
  @. DACBuildFracMax=1.0
  WriteDisk(db,"SpInput/DACBuildFracMax",DACBuildFracMax)

  #
  ########################
  #
  # DAC Price Diff Fraction (Tonnes/Tonnes)
  #
  @. DACPriceDiffFrac=0.5
  WriteDisk(db,"SpInput/DACPriceDiffFrac",DACPriceDiffFrac)

end

function CalibrationControl(db)
  @info "DirectAirCapture.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
