#
# SuPollutionOGEC.jl
#

module SuPollutionOGEC

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
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
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") #  Reference Case Name

  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year) #[Area,Market,Year]  Areas included in Market
  CoveredOGEC::VariableArray{2} = ReadDisk(db,"SInput/CoveredOGEC",year) #[ECC,Area,Year]  Covered Sectors for OGEC (1=Obligated)
  DBuyMaxOGEC::VariableArray{2} = ReadDisk(db,"SOutput/DBuyMaxOGEC",year) #[ECC,Area,Year]  Decarb Fund Permits Permitted (Tonnes CO2e)
  DBuyOGEC::VariableArray{2} = ReadDisk(db,"SOutput/DBuyOGEC",year) #[ECC,Area,Year] Decarb Fund Permits Bought for OGEC (Tonnes CO2e)
  ECCMarket::VariableArray{2} = ReadDisk(db,"SInput/ECCMarket",year) #[ECC,Market,Year]  Economic Categories included in Market
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") #[Market]  First Year Market Limits are Enforced (Year)
  ETADAP::VariableArray{1} = ReadDisk(db,"SInput/ETADAP",year) #[Market,Year]  Cost of Domestic Allowances from Government (Real US$/Tonne)
  ETAPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAPr",year) #[Market,Year]  Cost of Emission Trading Allowances (US$/Tonne)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Enduse Energy Demands (TBtu/Yr)
  ExchangeRate::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",year) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  FlPol::VariableArray{3} = ReadDisk(db,"SOutput/FlPol",year) #[ECC,Poll,Area,Year]  Flaring Pollution (Tonnes/Yr)
  FPECCOGEC::VariableArray{3} = ReadDisk(db,"SOutput/FPECCOGEC",year) #[Fuel,ECC,Area,Year]  Incremental OGEC Price ($/mmBtu)
  FuPol::VariableArray{3} = ReadDisk(db,"SOutput/FuPol",year) #[ECC,Poll,Area,Year]  Other Fugitive Emissions (Tonnes/Yr)
  GoalPolOGEC::VariableArray{2} = ReadDisk(db,"SInput/GoalPolOGEC",year) #[ECC,Area,Year]  Emission Intensity Goal for OGEC (Tonnes/TBtu)
  InflationUS::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) # [Nation,Year] Inflation Index ($/$)
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year)   #[ECC,Poll,Area,Year]  Non-Energy Pollution (Tonnes/Yr)
  MktPol::VariableArray{1} = ReadDisk(db,"SOutput/MktPol",year) #[Market,Year]  Pollution Subject to Limits (Tonnes/Yr)
  NcFPol::VariableArray{4} = ReadDisk(db,"SOutput/NcFPol",year) #[Fuel,ECC,Poll,Area,Year]  Non Combustion Related Pollution (Tonnes/Yr)
  ORMEPol::VariableArray{3} = ReadDisk(db,"SOutput/ORMEPol",year) #[ECC,Poll,Area,Year]  Non-Energy Off Road Pollution (Tonnes/year)
  OverBAB::VariableArray{1} = ReadDisk(db,"SOutput/OverBAB",year) #[Market,Year]  Overage Before Adjustment to Bank (Tonnes)
  PBuyMaxOGEC::VariableArray{2} = ReadDisk(db,"SOutput/PBuyMaxOGEC",year) #[ECC,Area,Year]  Total Permits Permitted for OGEC (Tonnes CO2e)
  PBuyOGEC::VariableArray{2} = ReadDisk(db,"SOutput/PBuyOGEC",year) #[ECC,Area,Year]  Market Permits Bought for OGEC (Tonnes CO2e)
  POCXOGEC::VariableArray{3} = ReadDisk(db,"SOutput/POCXOGEC",year) #[Fuel,ECC,Area,Year]  Pollution Coefficients for OGEC (Tonnes/TBtu)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PolOGEC::VariableArray{2} = ReadDisk(db,"SOutput/PolOGEC",year) #[ECC,Area,Year]  OGEC Pollution (Tonnes)
  PolOGEC2026::VariableArray{3} = ReadDisk(db,"SOutput/PolOGEC") #[ECC,Area,Year]  OGEC Pollution (Tonnes)
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) # [Poll,Market,Year] Pollutants included in Market
  PNeedOGEC::VariableArray{2} = ReadDisk(db,"SOutput/PNeedOGEC",year) #[ECC,Area,Year]  OGEC Permits Needed (Tonnes CO2e)
  PSellOGEC::VariableArray{2} = ReadDisk(db,"SOutput/PSellOGEC",year) #[ECC,Area,Year]  OGEC Permits Available in Market (Tonnes CO2e)
  PShortOGEC::VariableArray{2} = ReadDisk(db,"SOutput/PShortOGEC",year) #[ECC,Area,Year]  Excess Emissions Above Permitted Levels for OGEC (Tonnes CO2e)
  SqPol::VariableArray{3} = ReadDisk(db,"SOutput/SqPol",year) #[ECC,Poll,Area,Year]  Sequestering Emissions (Tonnes/Yr)
  TBalance::VariableArray{1} = ReadDisk(db,"SOutput/TBalance",year) #[Market,Year]  Total Permit Bought (Tonnes/Yr)
  TBuy::VariableArray{1} = ReadDisk(db,"SOutput/TBuy",year) #[Market,Year]  Total Permit Bought (Tonnes/Yr)
  TSell::VariableArray{1} = ReadDisk(db,"SOutput/TSell",year) #[Market,Year]  Total Permit Sold (Tonnes/Yr)
  VnPol::VariableArray{3} = ReadDisk(db,"SOutput/VnPol",year) #[ECC,Poll,Area,Year]  Venting Pollution (Tonnes/Yr)
  #
  # Scratch Variables
  #
  DecarbBuyEstimate::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # Estimate of Purchases of Decarb Credits (Tonnes/Yr)
  GoalMkt::VariableArray{1} = zeros(Float32,length(Market)) # Pollution Goal for Market (Tonnes/Yr)
end

#
# Coversions
#
# Tonnes/TBtu = g/MJ*Tonnes/g*MJ/TBtu
# Tonnes/TBtu = g/MJ*1/1000000*1054615/1
# Tonnes/TBtu = g/MJ*1.054615
# 1 TBtu = 1,054,615 megajoule
# 1 tonne = 1,000,000 gram
#

function ReferenceValues(data::Data,areas,eccs,polls,market)
  (; db,year) = data
  (; Fuels,Polls) = data 
  (; CoveredOGEC,GoalMkt,MktPol,PolConv,PolOGEC,PolOGEC2026) = data
  (; EuDemand,FlPol,FuPol,MEPol,NcFPol,ORMEPol,POCXOGEC) = data
  (; SqPol,VnPol) = data

  @debug "  SuPollutionOGEC.jl - Control - EIGap"
  
  GoalMkt[market] = sum(PolOGEC2026[ecc,area,Yr(2026)]*0.73
                        for ecc in eccs, area in areas)
  
  for ecc in eccs, area in areas
    PolOGEC[ecc,area] = 
      sum(EuDemand[fuel,ecc,area]*POCXOGEC[fuel,ecc,area] for fuel in Fuels) + 
      sum(NcFPol[fuel,ecc,poll,area]*PolConv[poll] for fuel in Fuels, poll in Polls) + 
      sum(MEPol[ecc,poll,area]*PolConv[poll] for poll in polls)+     
      sum(VnPol[ecc,poll,area]*PolConv[poll] for poll in polls)+
      sum(FlPol[ecc,poll,area]*PolConv[poll] for poll in polls)+
      sum(FuPol[ecc,poll,area]*PolConv[poll] for poll in polls)+        
      sum(SqPol[ecc,poll,area]*PolConv[poll] for poll in polls)
    PolOGEC[ecc,area] = PolOGEC[ecc,area]*CoveredOGEC[ecc,area]
  end

  MktPol[market] = sum(PolOGEC[ecc,area] for ecc in eccs, area in areas)

  WriteDisk(db,"SOutput/PolOGEC",year,PolOGEC)
  WriteDisk(db,"SOutput/MktPol",year,MktPol)

end

function EmissionsPermits(data::Data,areas,eccs,market)
  (; db,year) = data
  (; Nation) = data  
  (; ETAPr,ETADAP,DBuyMaxOGEC,DBuyOGEC,DecarbBuyEstimate,GoalMkt,GoalPolOGEC) = data
  (; InflationUS,OverBAB,PBuyMaxOGEC,PBuyOGEC,PNeedOGEC,PSellOGEC,PShortOGEC,PolOGEC) = data
  (; TBalance,TBuy,TSell) = data

  @debug "  SuPollutionOGEC.jl - Control - EmissionsPermits"

  #
  # Allocate Emissions Goal based on Goal estimated in *.txp (GoalPolOGEC)
  #
  GoalMktEst = sum(GoalPolOGEC[ecc,area] for ecc in eccs, area in areas)
  for ecc in eccs, area in areas
    GoalPolOGEC[ecc,area] = GoalPolOGEC[ecc,area]/GoalMktEst*GoalMkt[market]
  end

  #
  # Total Permits
  #
  for ecc in eccs, area in areas
    PBuyMaxOGEC[ecc,area] = PolOGEC[ecc,area]
  end
  
  #
  # Tech Fund/Decarb Credits Available
  #
  for ecc in eccs, area in areas
    DBuyMaxOGEC[ecc,area] = PolOGEC[ecc,area]*0.10
  end
  WriteDisk(db,"SInput/GoalPolOGEC",year,GoalPolOGEC)
  WriteDisk(db,"SOutput/PBuyMaxOGEC",year,PBuyMaxOGEC)
  WriteDisk(db,"SOutput/DBuyMaxOGEC",year,DBuyMaxOGEC)

  #
  # Permits Sold into the Market
  #
  # Assuming Decarb Fund permits cannot be resold, if they
  # can be resold, we need to revise the code
  #
  for ecc in eccs, area in areas
    PSellOGEC[ecc,area] = max(GoalPolOGEC[ecc,area]-PolOGEC[ecc,area],0)
  end
  WriteDisk(db,"SOutput/PSellOGEC",year,PSellOGEC)

  #
  # Permits Needed
  #
  for ecc in eccs, area in areas
    PNeedOGEC[ecc,area] = max(PolOGEC[ecc,area]-GoalPolOGEC[ecc,area],0)
  end
  WriteDisk(db,"SOutput/PNeedOGEC",year,PNeedOGEC)

  #
  # Balance without Decarb Fund
  #
  ShortageNoDecarb = sum(PNeedOGEC[ecc,area]-PSellOGEC[ecc,area]
                         for ecc in eccs, area in areas)
  #
  DecarbLimit = sum(DBuyMaxOGEC[ecc,area] for ecc in eccs, area in areas)
  for ecc in eccs, area in areas
    DecarbBuyEstimate[ecc,area] = min(PNeedOGEC[ecc,area],DBuyMaxOGEC[ecc,area])
  end

  #
  # Permits Purchased from the Decarb Fund 
  #
  nation = Select(Nation,"US")
  if ETAPr[market] >= (ETADAP[market]*InflationUS[nation])
    for ecc in eccs, area in areas
      DBuyOGEC[ecc,area] = DecarbBuyEstimate[ecc,area]
    end
  else
    if ShortageNoDecarb > 0
      DecarbBuy = min(ShortageNoDecarb,DecarbLimit)
      for ecc in eccs, area in areas
        DBuyOGEC[ecc,area] = DecarbBuyEstimate[ecc,area]*DecarbBuy/DecarbLimit
      end
      ETAPr[market] = ETADAP[market]*InflationUS[nation]
    else
      for ecc in eccs, area in areas
        DBuyOGEC[ecc,area] = 0
      end
    end
  end
  WriteDisk(db,"SOutput/DBuyOGEC",year,DBuyOGEC)
  WriteDisk(db,"SOutput/ETAPr",year,ETAPr)

  #
  # Permits Purchased from the Market 
  #
  for ecc in eccs, area in areas
    PBuyOGEC[ecc,area] = min(PNeedOGEC[ecc,area]-DBuyOGEC[ecc,area],
                             PBuyMaxOGEC[ecc,area]-DBuyMaxOGEC[ecc,area])
  end
  WriteDisk(db,"SOutput/PBuyOGEC",year,PBuyOGEC)

  #
  # Overage before adjustment to Banking
  #
  OverBAB[market] = sum(PNeedOGEC[ecc,area]-PSellOGEC[ecc,area]-DBuyOGEC[ecc,area]
                        for ecc in eccs, area in areas)
  WriteDisk(db,"SOutput/OverBAB",year,OverBAB)

  #
  # Shortages - Sector neet their Goal when this is 0.0
  #
  for ecc in eccs, area in areas
    PShortOGEC[ecc,area] = max(PNeedOGEC[ecc,area]-PBuyOGEC[ecc,area]-DBuyOGEC[ecc,area],0)
  end
  WriteDisk(db,"SOutput/PShortOGEC",year,PShortOGEC)

  #
  # Permits traded in market (Decarb Fund permits not traded)
  #
  TBuy[market] = sum(PBuyOGEC[ecc,area] for ecc in eccs, area in areas)
  TSell[market] = sum(PSellOGEC[ecc,area] for ecc in eccs, area in areas)
  WriteDisk(db,"SOutput/TBuy",year,TBuy)
  WriteDisk(db,"SOutput/TSell",year,TSell)

  #
  # Permit Balance - Market is cleared when this is 0.0
  #
  TBalance[market] = TBuy[market]-TSell[market]
  WriteDisk(db,"SOutput/TBalance",year,TBalance)

end #EmissionsPermits

function Control(data::Data)
  (; db,CTime) = data
  (; AreaMarket,ECCMarket,Enforce,PollMarket) = data

  @debug "  SuPollutionOGEC.jl - Control"

  # Prior=Current-1
  # Prior=xmax(1,Prior)
  # Prior2=xmax(1,Prior-1)
  # 
  market = 5
  areas = findall(AreaMarket[:,market] .== 1)
  eccs = findall(ECCMarket[:,market] .== 1)
  polls = findall(PollMarket[:,market] .== 1) 
  if !isempty(areas) && !isempty(eccs) && !isempty(polls)
  
    ReferenceValues(data,areas,eccs,polls,market)
    
    if CTime >= Enforce[market]
      EmissionsPermits(data,areas,eccs,market)
    end
    
  end

end # function Control

function OGECPrices(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Fuels) = data #sets
  (; CoveredOGEC,ETAPr,ExchangeRate,FPECCOGEC,POCXOGEC) = data
  
  #@debug "  SuPollutionOGEC.jl - OGECPrices"

  market = 5
  for fuel in Fuels, ecc in ECCs, area in Areas
    FPECCOGEC[fuel,ecc,area] =
      CoveredOGEC[ecc,area]*ETAPr[market]*ExchangeRate[area]*POCXOGEC[fuel,ecc,area]/1e6
  end
  WriteDisk(db,"SOutput/FPECCOGEC",year,FPECCOGEC)

end # function OGECPrices

end # module SuPollutionOGEC
