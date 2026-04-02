#
# OGEC_Market.jl
#

using EnergyModel

module OGEC_Market

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name  

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"IInput/ECKey")
  ECDS::SetArray = ReadDisk(db,"IInput/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Enduse::SetArray = ReadDisk(db,"IInput/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"IInput/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))  
  Tech::SetArray = ReadDisk(db,"IInput/TechKey")
  TechDS::SetArray = ReadDisk(db,"IInput/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation 
  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Trading Switch (5=GHG Cap and Trade,6=CFS Market)
  CoveredOGEC::VariableArray{3} = ReadDisk(db,"SInput/CoveredOGEC") #[ECC,Area,Year]  Covered Sectors for OGEC (1=Obligated)
  DBuyMaxOGEC::VariableArray{3} = ReadDisk(db,"SOutput/DBuyMaxOGEC") #[ECC,Area,Year]  Decarb Fund Permits Permitted (Tonnes CO2e)
  DriverRef::VariableArray{3} = ReadDisk(RefNameDB,"MOutput/Driver") # [ECC,Area,Year] Reference Case Economic Driver (Various Millions/Yr)   
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECCProMap::VariableArray{2} = ReadDisk(db,"SInput/ECCProMap") #[ECC,Process]  ECC to Process Map
  EIOGEC::VariableArray{3} = ReadDisk(db,"SInput/EIOGEC") #[ECC,Area,Year]  Emission Intensity (Tonnes/TBtu)
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year CFS Limits are Enforced (Year)
  ETABY::VariableArray{1} = ReadDisk(db,"SInput/ETABY") # [Market] Base Year for CFS (Year)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government (Real US$/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db,"SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate Credits,2=Iterate Emissions,0=Exogenous)
  EuDemandRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/EuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FlPolRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/FlPol") # [ECC,Poll,Area,Year]  Fugitive Flaring Emissions (Tonnes/Yr)
  FuPolRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/FuPol") # [ECC,Poll,Area,Year]  Other Fugitive Emissions (Tonnes/Yr)
  GoalPolOGEC::VariableArray{3} = ReadDisk(db,"SInput/GoalPolOGEC") #[ECC,Area,Year]  Emission Intensity Goal for OGEC (Tonnes/TBtu)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits,2=Domestic Permits)
  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # Maximum Number of Iterations (Number)  
  MEPolRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/MEPol") # [ECC,Poll,Area,Year]  Non-Energy Pollution (Tonnes/Yr)
  NcFPolRef::VariableArray{5} = ReadDisk(RefNameDB,"SOutput/NcFPol") # [Fuel,ECC,Poll,Area,Year] Non Combustion Related Pollution (Tonnes/Yr) 
  OverLimit::VariableArray{2} = ReadDisk(db,"SInput/OverLimit") # [Market,Year] Overage Limit as a Fraction (Tonne/Tonne)
  PBnkSw::VariableArray{2} = ReadDisk(db,"SInput/PBnkSw") # [Market,Year] Credit Banking Switch (1=Buy and Sell Out of Inventory)
  PBuyMaxOGEC::VariableArray{3} = ReadDisk(db,"SOutput/PBuyMaxOGEC") #[ECC,Area,Year]  Total Permits Permitted for OGEC (Tonnes CO2e)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  POCX::VariableArray{6} = ReadDisk(db,"IInput/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
  POCXOGEC::VariableArray{4} = ReadDisk(db,"SOutput/POCXOGEC") #[Fuel,ECC,Area,Year]  Pollution Coefficients for OGEC (Tonnes/TBtu)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market

  PolOGEC::VariableArray{3} = ReadDisk(db,"SOutput/PolOGEC") # [ECC,Area,Year]  OGEC Pollution (Tonnes)
  PolOGECRef::VariableArray{3} = ReadDisk(db,"SInput/PolOGECRef") # [ECC,Area,Year]  OGEC Pollution (Tonnes)

  SqPolRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/SqPol") # [ECC,Poll,Area,Year]  Sequestering Emissions (Tonnes/Yr)
  VnPolRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/VnPol") #[ECC,Poll,Area,Year]  Venting Pollution (Tonnes/Yr)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index
  xGAProd::VariableArray{3} = ReadDisk(db,"SInput/xGAProd") # [Process,Area,Year] Historical Primary Gas Production (TBtu/Yr)
  xOAProd::VariableArray{3} = ReadDisk(db,"SInput/xOAProd") # [Process,Area,Year] Oil Production (TBtu/Yr)

  #
  # Scratch Variables
  #
  POC1::VariableArray{5} = zeros(Float32,length(FuelEP),length(EC),length(Poll),length(Area),length(Year)) # [FuelEP,EC,Poll,Area,Year]
  POC2::VariableArray{5} = zeros(Float32,length(Fuel),length(EC),length(Poll),length(Area),length(Year)) # [Fuel,EC,Poll,Area,Year]
  POC3::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year]
  POC4::VariableArray{4} = zeros(Float32,length(Fuel),length(ECC),length(Area),length(Year)) # [Fuel,ECC,Area,Year]
end

function SupplyPolicy(db)
  data = SControl(; db)
  (; Area,Areas,EC,ECs,ECC,ECCs) = data
  (; Fuel,Fuels,FuelEPs) = data
  (; Nation,Poll,Polls,Processes) = data
  (; Years) = data
  (; ANMap,AreaMarket,CapTrade,CoveredOGEC,DBuyMaxOGEC,DriverRef) = data
  (; ECCMarket,ECCProMap,EIOGEC,Enforce,ETABY,ETADAP,ETAIncr) = data
  (; ETRSw,EuDemandRef,FFPMap,FlPolRef,FuPolRef) = data
  (; GoalPolOGEC,ISaleSw,MaxIter,MEPolRef,NcFPolRef) = data
  (; OverLimit,PBnkSw,PBuyMaxOGEC,PCovMarket,POC1,POC2,POC3,POC4) = data
  (; POCX,POCXOGEC,PolConv,PollMarket) = data
  (; PolOGEC) = data
  (; PolOGECRef) = data
  (; SqPolRef,VnPolRef,xExchangeRateNation,xInflationNation) = data
  (; xGAProd,xOAProd) = data  
  
  #
  # ************************
  #
  market = 5
  
  #
  # ************************
  #
  # Market Timing
  #
  Enforce[market] = 2030
  YrFinal = Int(2050-ITime+1)
  Current = Int(Enforce[market]-ITime+1)
  Prior = Current-1
  ETABY[market] = 2026
  YrETABY = Int(ETABY[market]-ITime+1)
  WriteDisk(db,"SInput/Enforce",Enforce)
  WriteDisk(db,"SInput/ETABY",ETABY)

  #
  # ************************
  #
  # Areas Covered
  #
  for year in Years, area in Areas
    AreaMarket[area,market,year] = 0
  end

  nation=Select(Nation,"CN")
  areas = findall(ANMap[Areas,nation] .== 1)
  for year in Years, area in areas
    AreaMarket[area,market,year] = 1
  end
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)

  #
  # ************************
  #
  # Emissions Covered
  #
  for year in Years,poll in Polls
    PollMarket[poll,market,year] = 0
  end

  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  for year in Years, poll in polls
    PollMarket[poll,market,year] = 1
  end
  WriteDisk(db,"SInput/PollMarket",PollMarket)

  #
  # ************************
  #
  # Type of Emissions Covered
  #
  #for year in Years, pcov in PCovs
  #  PCovMarket[pcov,market,year] = 0
  #end
  #
  #pcovs=Select(PCov,["Energy","Oil","NaturalGas","NonCombustion","Process","Venting","Flaring"])
  #for year in Years, pcov in pcovs
  #  PCovMarket[pcov,market,year] = 1
  #end
  #WriteDisk(db,"SInput/PCovMarket",PCovMarket)

  #
  # ************************
  #
  # Sector Coverages
  #
  for year in Years, ecc in ECCs
    ECCMarket[ecc,market,year] = 0
  end

  eccs=Select(ECC,["LightOilMining","HeavyOilMining","FrontierOilMining","PrimaryOilSands",
      "SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders",
      "ConventionalGasProduction","SweetGasProcessing",
      "UnconventionalGasProduction","SourGasProcessing","LNGProduction"])
  for year in Years, ecc in eccs
    ECCMarket[ecc,market,year] = 1
  end
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)

  #
  # ************************
  #
  # OGEC Coverage - ECC/Area pairs with OG production
  #
  @. CoveredOGEC = 0
  years=collect(Yr(2026):Final)
  for area in areas, ecc in eccs
    loc1=sum((xOAProd[process,area,year]+xGAProd[process,area,year])*
              ECCProMap[ecc,process] for year in years, process in Processes)
    if loc1 > 0.0
      # @info ECC[ecc] "," Area[area] "," loc1
      for year in years
        CoveredOGEC[ecc,area,year] = 1
      end
    end
  end

  years=collect(First:Yr(2025))
  for year in years, area in areas, ecc in eccs
    CoveredOGEC[ecc,area,year]=CoveredOGEC[ecc,area,Yr(2026)]
  end
  WriteDisk(db,"SInput/CoveredOGEC",CoveredOGEC)

  #
  # ************************
  #
  # Emission Trading Switch (5=GHG Cap and Trade, 6=CFS Market)
  #
  for year in Years
    CapTrade[market,year] = 8
  end
  WriteDisk(db,"SInput/CapTrade",CapTrade)

  #
  # ************************
  #
  # Credit Cost Switch
  #
  ETRSw[market] = 0
  WriteDisk(db,"SInput/ETRSw",ETRSw)

  #
  # ************************
  #
  # Maximum Number of Iterations
  #
  MaxIter[1] = max(MaxIter[1],1)
  WriteDisk(db,"SInput/MaxIter",MaxIter)

  #
  # ************************
  #
  # Overage Limit (Fraction)
  #
  for year in Years
    OverLimit[market,year] = 0.001
  end
  WriteDisk(db,"SInput/OverLimit",OverLimit)

  #
  # ************************
  #
  # Price change increment
  #
  for year in Years
    ETAIncr[market,year] = 0.75
  end
  WriteDisk(db,"SInput/ETAIncr",ETAIncr)

  #
  # ************************
  #
  # Credit Banking Switch
  #
  for year in Years
    PBnkSw[market,year] = 0
  end
  WriteDisk(db,"SInput/PBnkSw",PBnkSw)

  #
  # ************************
  #
  # Tech Fund Credits
  #
  # Unlimited Tech Fund Credits (TIF)
  #
  for year in Years
    ISaleSw[market,year] = 0
  end
  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  #
  # Tech Fund Credit Prices (set by policy, but only 10% of remittances permitted)
  #
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  years=collect(Yr(2030):Final)
  for year in years
    ETADAP[market,year] = 50/xExchangeRateNation[CN,year]/
      xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/ETADAP",ETADAP)

  #
  # ************************
  #
  # Emissions Coefficient
  #
  fuels1 = Select(Fuel,!=("Electric"))
  fuels2 = Select(Fuel,!=("Wind"))
  fuels3 = Select(Fuel,!=("Solar"))
  fuels=intersect(fuels1,fuels2,fuels3)

  enduse=1

  #
  # POCXOGEC(Fuel,ECC,A,Y) = sum(FEP,EC,P)(POCX(EU,FEP,EC,P,Area,Y)*
  #                          PolConv[poll]*ECCMap(EC,ECC)*FFPMap(FEP,Fuel))
  #             
  # Expand for clarity
  #
  for year in Years, area in areas, poll in polls, ec in ECs, fuelep in FuelEPs
    POC1[fuelep,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]
  end
  
  for year in Years, area in areas, poll in polls, ec in ECs, fuel in fuels
    POC2[fuel,ec,poll,area,year] = sum(POC1[fuelep,ec,poll,area,year]*
                                   FFPMap[fuelep,fuel] for fuelep in FuelEPs)
  end
  
  for year in Years, area in areas, ec in ECs, fuel in fuels
    POC3[fuel,ec,area,year] = sum(POC2[fuel,ec,poll,area,year]*PolConv[poll]
                                  for poll in polls)
  end
  
  for year in Years, area in areas, ec in ECs, fuel in fuels
    ecc = Select(ECC,EC[ec])
    POC4[fuel,ecc,area,year] = POC3[fuel,ec,area,year]
  end
  
  for year in Years, area in areas, ecc in eccs, fuel in fuels
    POCXOGEC[fuel,ecc,area,year] = POC4[fuel,ecc,area,year]*CoveredOGEC[ecc,area,Yr(2030)]
  end

  #
  # Needs default values for Hydrogen and Thermals
  # Find some stand in for lifecycle pollution from Hydrogen
  #
  fuels=Select(Fuel,["Ammonia","Hydrogen","Biodiesel","Biogas","Biojet","Ethanol"])
  for year in Years, area in areas, ecc in eccs, fuel in fuels
    POCXOGEC[fuel,ecc,area,year] = 3E4*CoveredOGEC[ecc,area,Yr(2030)]
  end
  WriteDisk(db,"SOutput/POCXOGEC",POCXOGEC)

  #
  # ************************
  #
  # Covered Emissions
  #
  years=collect(Yr(2019):Final)
  for year in years, area in areas, ecc in eccs
    PolOGECRef[ecc,area,year] =
      sum(EuDemandRef[fuel,ecc,area,year]*POCXOGEC[fuel,ecc,area,year] for fuel in Fuels)+
      sum(NcFPolRef[fuel,ecc,poll,area,year]*PolConv[poll] for poll in polls, fuel in Fuels)+   
      sum(MEPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls)+     
      sum(VnPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls)+
      sum(FlPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls)+
      sum(FuPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls)+        
      sum(SqPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls)
    PolOGECRef[ecc,area,year]=PolOGECRef[ecc,area,year]*CoveredOGEC[ecc,area,year]
  end
  WriteDisk(db,"SInput/PolOGECRef",PolOGECRef)

  #
  # Emissions Cap
  #
  years=collect(Yr(2030):Yr(2050))
  Yr2026=Yr(2026)
  for year in years, area in areas, ecc in eccs
    GoalPolOGEC[ecc,area,year]=PolOGECRef[ecc,area,Yr2026]*(1-0.27)
  end
  WriteDisk(db,"SInput/GoalPolOGEC",GoalPolOGEC)

  #
  # ************************
  #
  # Emission Intensity by ECC
  #
  for year in Years, area in areas, ecc in eccs
    EIOGEC[ecc,area,year] = GoalPolOGEC[ecc,area,year]/DriverRef[ecc,area,year]
  end
  WriteDisk(db,"SInput/EIOGEC",EIOGEC)

  #
  # ************************
  #
  # Maximum number of permits which can be purchased
  #
  for year in Years, area in areas, ecc in eccs
    PBuyMaxOGEC[ecc,area,year]=GoalPolOGEC[ecc,area,year]*0.20
  end
  WriteDisk(db,"SOutput/PBuyMaxOGEC",PBuyMaxOGEC)

  #
  # Tech Fund/Decarb Credits Available for Purchase
  #
  for year in Years, area in areas, ecc in eccs
    DBuyMaxOGEC[ecc,area,year]=PolOGECRef[ecc,area,year]*0.10
  end
  WriteDisk(db,"SOutput/DBuyMaxOGEC",DBuyMaxOGEC)

end

function PolicyControl(db)
  @info "OGEC_Market.jl - PolicyControl"
  SupplyPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
