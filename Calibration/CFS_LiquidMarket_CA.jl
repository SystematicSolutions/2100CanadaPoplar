#
# CFS_LiquidMarket_CA.jl
#

using EnergyModel

module CFS_LiquidMarket_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation 
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year CFS Limits are Enforced (Year)
  ETABY::VariableArray{1} = ReadDisk(db,"SInput/ETABY") # [Market] Base Year for CFS (Year)
  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Trading Switch (5=GHG Cap and Trade, 6=CFS Market)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate Credits,2=Iterate Emissions,0=Exogenous)
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") # [Market] Gratis Permit Allocation Switch (2=Output, 0=Exogenous, -1=None, 1=Grandfather)
  OverLimit::VariableArray{2} = ReadDisk(db,"SInput/OverLimit") # [Market,Year] Overage Limit as a Fraction (Tonne/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db,"SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  PBnkSw::VariableArray{2} = ReadDisk(db,"SInput/PBnkSw") # [Market,Year] Credit Banking Switch (1=Buy and Sell Out of Inventory)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government (Real US$/Tonne)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits, 2=Domestic Permits)
  xFSell::VariableArray{2} = ReadDisk(db,"SInput/xFSell") # [Market,Year] Exogenous Federal Permits Sold (Tonnes/Yr)
  CoverageCFS::VariableArray{4} = ReadDisk(db,"SInput/CoverageCFS") # [Fuel,ECC,Area,Year] Coverage for CFS (1=Covered)
  CreditsFossilLimit::VariableArray{3} = ReadDisk(db,"SInput/CreditsFossilLimit") # [ECC,Area,Year] Limit Fossil Credits used to meet Obligations (Tonnes/Tonne)
  CreditSwitch::VariableArray{4} = ReadDisk(db,"SInput/CreditSwitch") # [Fuel,ECC,Area,Year] Switch to Indicate Fuels which must Purchase CFS Credits (1=Purchase)
  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # [Year] Maximum Number of Iterations (Number)
  ObligatedCFS::VariableArray{3} = ReadDisk(db,"SInput/ObligatedCFS") # [ECC,Area,Year] Obligated Sectors for CFS Emission Reductions (1=Obligated)
  EIOfficial::VariableArray{3} = ReadDisk(db,"SInput/EIOfficial") # [Fuel,Area,Year] Official Value for Emission Intensity (Tonnes/TBtu)
  DemandCFS::VariableArray{4} = ReadDisk(db,"SOutput/DemandCFS") # [Fuel,ECC,Area,Year] Energy Demands for CFS (TBtu/Yr)
  EIAverage::VariableArray{2} = ReadDisk(db,"SInput/EIAverage") # [Market,Year] Weighted Average EI of Stream (Tonne/TBtu)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  EIReduction::VariableArray{2} = ReadDisk(db,"SInput/EIReduction") # [Market,Year] EI Reduction Requirement (Tonne/TBtu)
  EIStreamCredit::VariableArray{2} = ReadDisk(db,"SInput/EIStreamCredit") # [Market,Year] Stream Credit Reference Emission Intensity (Tonnes/TBtu)
  EIGoalCFS::VariableArray{4} = ReadDisk(db,"SInput/EIGoalCFS") # [Fuel,ES,Area,Year] Emission Intensity Goal for CFS (Tonnes/TBtu)
  CgCredits::VariableArray{2} = ReadDisk(db,"SInput/CgCredits") # [Market,Year] CFS Credits for Cogeneration (Tonnes/GWh)
  DirectCredits::VariableArray{2} = ReadDisk(db,"SInput/DirectCredits") # [Market,Year] Direct Emission Reduction Credits (Tonnes/Tonnes)
  FuCredits::VariableArray{2} = ReadDisk(db,"SInput/FuCredits") # [Market,Year] Fugitive Emission Reduction Credits (Tonnes/Tonnes)
  SqCredits::VariableArray{2} = ReadDisk(db,"SInput/SqCredits") # [Market,Year] Sequestering Credits (Tonnes/Tonnes)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index

  #
  # Scratch Variables
  #
  # BaseYearCFS   'Base year for Emission Reductions and Electricity Demands (Year)' 
  DemandFossil::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Fossil Fuel Demands (TBtu/Yr)
  DemandPassenger::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Renewable Passenger Fuel Demands (TBtu/Yr)
  DemandRenew::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Renewable Fuel Demands (TBtu/Yr)
  EIStreamReference::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Stream Reference Emission Intensity (Tonnes/TBtu)
 # KJBtu    'Kilo Joule per BTU'   
  TransMultiplier::VariableArray{1} = zeros(Float32,length(Fuel)) # [Fuel] Multipler for transportation credits (1/1)
end

function CFS_Market(db)
  data = SControl(; db)
  (;Area,ECC,ECCs,ES,ESs,Fuel) = data
  (;Fuels,Nation,Poll) = data
  (;Years) = data
  (;Enforce,ETABY,AreaMarket,ECCMarket,PollMarket,CapTrade,ETRSw,GratSw,OverLimit) = data
  (;ETAIncr,PBnkSw,ETADAP,ISaleSw,xFSell,CoverageCFS,CreditsFossilLimit,CreditSwitch,MaxIter,ObligatedCFS,EIOfficial) = data
  (;DemandCFS,EIAverage,xCgDemand,xEuDemand,EIReduction,EIStreamCredit,EIGoalCFS,CgCredits,DirectCredits,FuCredits) = data
  (;SqCredits,xInflationNation) = data
  (;DemandFossil,DemandRenew,EIStreamReference) = data


  market = 3

  #
  ########################
  #
  # First Year CFS Limits are Enforced
  #
  Enforce[market] = 2011
  WriteDisk(db,"SInput/Enforce",Enforce)
  Current = Int(Enforce[market]-ITime+1)
  years = collect(Current:Final)

  #
  ########################
  #
  # Base year for Emission Reductions and Electricity Demands
  #
  ETABY[market] = 2011
  WriteDisk(db,"SInput/ETABY",ETABY)
  BaseYearCFS = Int(ETABY[market]-ITime+1)

  #
  ########################
  #
  # Areas Covered
  #
  areas = Select(Area,"CA")
  for year in years, area in areas
    AreaMarket[area,market,year] = 1
  end
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)

  #
  ########################
  #
  # Sector Coverages
  #
  for year in years, ecc in ECCs
    ECCMarket[ecc,market,year] = 1
  end
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)

  #
  ########################
  #
  # Emissions Covered
  #
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  for year in years, poll in polls
    PollMarket[poll,market,year] = 1
  end
  WriteDisk(db,"SInput/PollMarket",PollMarket)

  #
  ########################
  #
  # Emission Trading Switch (5=GHG Cap and Trade, 6=CFS Market)
  #
  for year in years
    CapTrade[market,year] = 6
  end
  WriteDisk(db,"SInput/CapTrade",CapTrade)

  #
  ########################
  #
  # Credit Cost Switch
  #
  ETRSw[market] = 1
  WriteDisk(db,"SInput/ETRSw",ETRSw)

  #
  ########################
  #
  #
  # No Gratis Permits (GratSw=-1)
  #
  GratSw[market] = -1
  WriteDisk(db,"SInput/GratSw",GratSw)
  
  #
  ########################
  #
  # Maximum Number of Iterations
  #
  for year in years
    MaxIter[year] = max(MaxIter[year],1)
  end
  WriteDisk(db,"SInput/MaxIter",MaxIter)

  #
  ########################
  #
  # Overage Limit (Fraction)
  #
  for year in years
    OverLimit[market,year] = 0.001
  end
  WriteDisk(db,"SInput/OverLimit",OverLimit)

  #
  ########################
  #
  # Price change increment
  #
  for year in years
    ETAIncr[market,year] = 0.75
  end
  WriteDisk(db,"SInput/ETAIncr",ETAIncr)

  #
  ########################
  #
  # Credit Banking Switch
  #
  for year in years
    PBnkSw[market,year] = 1
  end
  WriteDisk(db,"SInput/PBnkSw",PBnkSw)

  #
  ########################
  #
  # Tech Fund Credits
  #
  # Unlimited Tech Fund Credits (TIF)
  #
  for year in years
    ISaleSw[market,year] = 2
  end
  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  #
  # Tech Fund Credit Prices (default is high price)
  #
  US = Select(Nation,"US")
  for year in years
    ETADAP[market,year] = 1000/xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/ETADAP",ETADAP)

  #
  # Unlimited Tech Fund Credits
  #
  for year in years
    xFSell[market,year] = 1e12
  end
  WriteDisk(db,"SInput/xFSell",xFSell)

  #
  ########################
  #
  # Coverage for CFS Liquid Market
  #

  #
  # Liquid Stream
  #
  eccs = Select(ECC,["Wholesale","Retail","Warehouse","Information",
    "Offices","Education","Health","OtherCommercial","NGDistribution",
    "OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer","Petroleum","Rubber",
    "Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining","Construction","OnFarmFuelUse",
    "Passenger","Freight","AirPassenger","AirFreight","ResidentialOffRoad",
    "CommercialOffRoad","UtilityGen"])
    
    fuels = Select(Fuel,["AviationGasoline","Biodiesel","Biojet","Diesel",
                         "Ethanol","Gasoline","JetFuel","Kerosene"])

    for year in years, area in areas, ecc in eccs, fuel in fuels
      CoverageCFS[fuel,ecc,area,year] = 1
    end

  #
  # Transportation
  #
  eccs = Select(ECC,["Passenger","Freight","ResidentialOffRoad","CommercialOffRoad"])
  fuels = Select(Fuel,["Electric","Hydrogen","LPG","NaturalGas","RNG"])
  for year in years, area in areas, ecc in eccs, fuel in fuels
    CoverageCFS[fuel,ecc,area,year] = 1
  end

  #
  # Gaseous Stream
  #
  eccs = Select(ECC,["Wholesale","Retail","Warehouse","Information",
    "Offices","Education","Health","OtherCommercial","NGDistribution",
    "OilPipeline","NGPipeline",
    "Food","Textiles","Lumber","Furniture","PulpPaperMills","Petrochemicals",
    "IndustrialGas","OtherChemicals","Fertilizer","Petroleum","Rubber",
    "Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel","Aluminum",
    "OtherNonferrous","TransportEquipment","OtherManufacturing",
    "IronOreMining","OtherMetalMining","NonMetalMining","LightOilMining",
    "HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands",
    "CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction",
    "SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
    "LNGProduction","CoalMining","Construction","OnFarmFuelUse","UtilityGen"])
    
  fuels = Select(Fuel,["Hydrogen","LPG","NaturalGas","RNG"])
  
  for year in years, area in areas, ecc in eccs, fuel in fuels
    CoverageCFS[fuel,ecc,area,year] = 1
  end

  WriteDisk(db,"SInput/CoverageCFS",CoverageCFS)

  #
  ########################
  #
  for year in years, area in areas, ecc in ECCs
    CreditsFossilLimit[ecc,area,year] = 0.10
  end

  WriteDisk(db,"SInput/CreditsFossilLimit",CreditsFossilLimit)

  #
  ########################
  #
  # Switch to Indicate Fuels which must Purchase CFS Credits
  #
  for year in years, area in areas, ecc in ECCs, fuel in Fuels
    CreditSwitch[fuel,ecc,area,year] = 0.0
  end

  fuels = Select(Fuel,["AviationGasoline","Diesel","Gasoline","JetFuel","Kerosene"])
  for year in years, area in areas, ecc in ECCs,fuel in fuels
    CreditSwitch[fuel,ecc,area,year] = 1.0
  end

  WriteDisk(db,"SInput/CreditSwitch",CreditSwitch)

  #
  ########################
  #
  # Liquid Market Sectors Obligated to meet CFS
  #
  eccs = Select(ECC,["OilPipeline","Petroleum","LightOilMining","HeavyOilMining",
      "PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining",
      "OilSandsUpgraders","BiofuelProduction","H2Production"])
  
  for year in years, area in areas, ecc in eccs
    ObligatedCFS[ecc,area,year] = 1.0
  end
  
  WriteDisk(db,"SInput/ObligatedCFS",ObligatedCFS)

  #
  ########################
  #
  # Official Value (National) for Emission Intensity
  #
  KJBtu = 1.054615

  #
  # Source: "Default CIs for Jeff.xlsx" from Matt Lewis email 6/22/21
  # Source: Aviation Gasoline - CORSIA SUPPORTING DOCUMENT, 
  # CORSIA Eligible Fuels - Life Cycle Assessment Methodology, Version 5 - June 2022
  # https://www.icao.int/environmental-protection/CORSIA/Documents/CORSIA_Eligible_Fuels/CORSIA_Supporting_Document_CORSIA%20Eligible%20Fuels_LCA_Methodology_V5.pdf
  # - Jeff Amlin 9/18/24
  #

  # 
  # EIOfficial
  #
  fuels = Select(Fuel,["Gasoline","Diesel","Kerosene","AviationGasoline",
                       "JetFuel","Ethanol","Biodiesel","Biojet",
                       "NaturalGas","RNG","LPG","Hydrogen"])              
  for area in areas
    # Fuel type      (g CO2e/MJ)
    # Liquid             91.4
    EIOfficial[Select(Fuel,"Gasoline"),area,Current]   = 94.8*KJBtu*1000
    EIOfficial[Select(Fuel,"Diesel"),area,Current]     = 93.2*KJBtu*1000
    # EIOfficial[Select(Fuel,"LFO"),area,Current]      = 93.3*KJBtu*1000
    # EIOfficial[Select(Fuel,"HFO"),area,Current]      = 93.6*KJBtu*1000
    EIOfficial[Select(Fuel,"Kerosene"),area,Current]         = 85.2*KJBtu*1000
    EIOfficial[Select(Fuel,"AviationGasoline"),area,Current] = 95.0*KJBtu*1000
    EIOfficial[Select(Fuel,"JetFuel"),area,Current]          = 88.0*KJBtu*1000
    EIOfficial[Select(Fuel,"Ethanol"),area,Current]          = 49.0*KJBtu*1000
    EIOfficial[Select(Fuel,"Biodiesel"),area,Current]  = 26.0*KJBtu*1000
    # EIOfficial[Select(Fuel,"HDRD"),area,Current]     = 29.0*KJBtu*1000
    # "HDRD in LFO"                                    = 29.0*KJBtu*1000
    EIOfficial[Select(Fuel,"Biojet"),area,Current]     = 30.0*KJBtu*1000
    EIOfficial[Select(Fuel,"NaturalGas"),area,Current] = 78.37*KJBtu*1000
    EIOfficial[Select(Fuel,"RNG"),area,Current]        = 8.09*KJBtu*1000
    EIOfficial[Select(Fuel,"LPG"),area,Current]        = 75.0*KJBtu*1000
    EIOfficial[Select(Fuel,"Hydrogen"),area,Current]   = 3.29*KJBtu*1000
  end
  
  for year in Years, area in areas, fuel in fuels
    EIOfficial[fuel,area,year] = EIOfficial[fuel,area,Current]
  end

  #
  # Electricity
  #
  # Need values - Jeff 9/14/23
  #
  fuel = Select(Fuel,"Electric")
  for year in Years, area in areas
    EIOfficial[fuel,area,year]= 45 *KJBtu*1000
  end

  WriteDisk(db,"SInput/EIOfficial",EIOfficial)

  #
  ########################
  #
  # National Weighted Average EI of Stream
  #

  for year in years, area in areas, ecc in ECCs, fuel in Fuels
    DemandCFS[fuel,ecc,area,year] = 
      (xEuDemand[fuel,ecc,area,year]+xCgDemand[fuel,ecc,area,year])*
      CoverageCFS[fuel,ecc,area,year]
  end

  for year in years
    @finite_math EIAverage[market,year] = sum(EIOfficial[fuel,area,year]*
      DemandCFS[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels)/
      sum(DemandCFS[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels)
  end

  WriteDisk(db,"SInput/EIAverage",EIAverage) 

  #
  ########################
  #
  # Emission Intensity Reduction Requirement
  #
  # https://ww2.arb.ca.gov/resources/documents/lcfs-data-dashboard - Jeff 9/14/23
  #

  for year in Years
    EIReduction[market,year] = 0
  end
  
  EIReduction[market,Yr(2011)] =  0.00
  EIReduction[market,Yr(2012)] =  0.50
  EIReduction[market,Yr(2013)] =  1.00
  EIReduction[market,Yr(2014)] =  1.00
  EIReduction[market,Yr(2015)] =  1.00
  EIReduction[market,Yr(2016)] =  2.00
  EIReduction[market,Yr(2017)] =  3.00
  EIReduction[market,Yr(2018)] =  5.00
  EIReduction[market,Yr(2019)] =  6.00
  EIReduction[market,Yr(2020)] =  8.00
  EIReduction[market,Yr(2021)] =  9.00
  EIReduction[market,Yr(2022)] = 10.00
  years = collect(Yr(2011):Yr(2022))
  for year in years
    EIReduction[market,year] = EIReduction[market,year]*KJBtu*1000
  end
  years = collect(Yr(2023):Final)
  for year in years
    EIReduction[market,year] = 
      min(EIReduction[market,year-1]+1.25*KJBtu*1000,75.00*KJBtu*1000)    
  end
  years = collect(Current:Final)

  WriteDisk(db,"SInput/EIReduction",EIReduction)
  
  #
  ########################
  #
  # Stream Credit Reference Emisssion Intensity
  #
  fuels = Select(Fuel,["AviationGasoline","Diesel","Gasoline","JetFuel","Kerosene","LPG","NaturalGas"])
  for year in Years
    DemandFossil[year] = sum(DemandCFS[fuel,ecc,area,year]*
      CoverageCFS[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
  end

  fuels = Select(Fuel,["Biodiesel","Biojet","Ethanol","Electric","Hydrogen","RNG"])
  for year in Years
    DemandRenew[year] = sum(DemandCFS[fuel,ecc,area,year]*
      CoverageCFS[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
  end

  for year in Years
    @finite_math EIStreamCredit[market,year] = (EIAverage[market,year]-
      EIReduction[market,year])*DemandFossil[year]/(DemandFossil[year]+
        DemandRenew[year])
  end

  #
  # https://ww2.arb.ca.gov/resources/documents/lcfs-data-dashboard - Jeff 9/14/23
  #
  for year in Years
    EIStreamReference[year] = 89.2
  end
  
  years = collect(Current:Final)
  for year in Years
    EIStreamReference[year] = EIStreamReference[year]*KJBtu*1000
  end

  for year in Years
    EIStreamCredit[market,year] = EIStreamReference[year]-EIReduction[market,year]
  end

  WriteDisk(db,"SInput/EIStreamCredit",EIStreamCredit)

  #
  ########################
  #
  # Emission Intensity Goal for CFS 
  #
  for year in Years, area in areas, es in ESs, fuel in Fuels
    EIGoalCFS[fuel,es,area,year] = 0
  end
   
  area = Select(Area,"CA")
  es = Select(ES,"Transport")
  fuel = Select(Fuel,"AviationGasoline")
  year = Yr(2023)
  loc1 = EIGoalCFS[fuel,es,area,year]

  #
  # Fossil Fuels (which are not Low Carbon Fuels)
  #
  fuels = Select(Fuel,["AviationGasoline","Diesel","Gasoline","JetFuel","Kerosene"])
  for year in Years, area in areas, es in ESs, fuel in fuels
    EIGoalCFS[fuel,es,area,year] = EIOfficial[fuel,area,year]-EIReduction[market,year]
  end
   
  area = Select(Area,"CA")
  es = Select(ES,"Transport")
  fuel = Select(Fuel,"AviationGasoline")
  year = Yr(2023)
  loc1 = EIGoalCFS[fuel,es,area,year]
  loc1 = EIReduction[market,year]
  loc1 = EIOfficial[fuel,area,year]

  #
  # Low Carbon Fuels (including Low Carbon Fossil Fuels)
  #
  fuels = Select(Fuel,["Biodiesel","Biojet","Ethanol"])
  for year in Years, area in areas, es in ESs, fuel in fuels
    EIGoalCFS[fuel,es,area,year] = EIStreamCredit[market,year]
  end

  area = Select(Area,"CA")
  es = Select(ES,"Transport")
  fuel = Select(Fuel,"AviationGasoline")
  year = Yr(2023)
  loc1 = EIGoalCFS[fuel,es,area,year]
  loc1 = EIStreamCredit[market,year]



  #
  # Gaseous Stream is based on Natural Gas
  #
  NaturalGas = Select(Fuel,"NaturalGas")
  fuels = Select(Fuel,["Hydrogen","LPG","NaturalGas","RNG"])
  for year in Years, area in areas, es in ESs, fuel in fuels
    EIGoalCFS[fuel,es,area,year] = EIOfficial[NaturalGas,area,year]
  end

  area = Select(Area,"CA")
  es = Select(ES,"Transport")
  fuel = Select(Fuel,"AviationGasoline")
  year = Yr(2023)
  loc1 = EIGoalCFS[fuel,es,area,year]
  loc1 = EIOfficial[fuel,area,year]




  WriteDisk(db,"SInput/EIGoalCFS", EIGoalCFS)

  #
  #########################
  #
  # Cogeneration Credits
  # Source: "Credits are based on the following emissions standards:
  #          boiler emission intensity of 223t CO2/GWh(thermal),
  #          the Alberta electricity grid emission intensity of 670t CO2/GWh(electric)"
  # Source: "Low Carbon Intensity electricity generation (ie solar panels and wind
  #          turbines) are only granted credits when they are directly producing
  #          electricity for a refinery or upgrader. I think this means cogeneration
  #          is out as a way to generate credits."
  #          From: Matthew Lewis Email on Friday, May 28, 2021 10:57 AM
  #          Jeff Amlin 6/22/21
  #
  for year in years
    CgCredits[market,year] = 0
  end
  WriteDisk(db,"SInput/CgCredits",CgCredits)

  #
  ########################
  #
  for year in years
    DirectCredits[market,year] = 1
  end
  DirectCredits[market,Yr(2022)] = 0.5
  WriteDisk(db,"SInput/DirectCredits",DirectCredits)

  for year in years
    FuCredits[market,year] = 1
  end
  FuCredits[market,Yr(2022)] = 0.5
  WriteDisk(db,"SInput/FuCredits",FuCredits)

  for year in years
    SqCredits[market,year] = 1
  end
  SqCredits[market,Yr(2022)] = 0.5
  WriteDisk(db,"SInput/SqCredits",SqCredits)

end


Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
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
  Fuels::Vector{Int} = collect(Select(Fuel))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EICreditMult::VariableArray{6} = ReadDisk(db,"$Input/EICreditMult") # [Enduse,Fuel,Tech,EC,Area,Year] Multipler for CFS Credits (Tonne/Tonne)
  EIGoal::VariableArray{6} = ReadDisk(db,"$Outpt/EIGoal") # [Enduse,Fuel,Tech,EC,Area,Year] Emission Intensity Goal for CFS (Tonnes/TBtu)
  EIGoalCFS::VariableArray{4} = ReadDisk(db,"SInput/EIGoalCFS") # [Fuel,ES,Area,Year] Emission Intensity Goal for CFS (Tonnes/TBtu)
  EIStreamCredit::VariableArray{2} = ReadDisk(db,"SInput/EIStreamCredit") # [Market,Year] Stream Credit Reference Emission Intensity (Tonnes/TBtu)
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year CFS Limits are Enforced (Year)

end

function CFS_Transport(db)
  data = TControl(; db)
  (;Input,Outpt) = data
  (;Area,ECs,ES) = data
  (;Enduses,Fuel,Fuels,Techs) = data
  (;EICreditMult,EIGoal,EIGoalCFS,EIStreamCredit,Enforce) = data

  market = 3
  Current = Int(Enforce[market]-ITime+1)
  years = collect(Current:Final)
  areas = Select(Area,"CA")
  
  for year in years, area in areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    EICreditMult[enduse,fuel,tech,ec,area,year] = 1.0
  end
  WriteDisk(db,"$Input/EICreditMult",EICreditMult)
  
  es = Select(ES,"Transport")
  for year in years, area in areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    EIGoal[enduse,fuel,tech,ec,area,year] = EIGoalCFS[fuel,es,area,year]  
  end
  
  fuels = Select(Fuel,["Electric","Hydrogen","LPG","NaturalGas","RNG"])
  for year in years, area in areas, ec in ECs,tech in Techs, fuel in fuels, enduse in Enduses
    EIGoal[enduse,fuel,tech,ec,area,year] = EIStreamCredit[market,year]  
  end
  
  for year in years, area in areas, fuel in fuels
    EIGoalCFS[fuel,es,area,year] = EIStreamCredit[market,year]  
  end
  WriteDisk(db,"$Outpt/EIGoal",EIGoal)
  WriteDisk(db,"SInput/EIGoalCFS",EIGoalCFS) 

end

function Control(db)

  CFS_Market(db)
  CFS_Transport(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
