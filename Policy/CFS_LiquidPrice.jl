#
# CFS_LiquidPrice.jl
#

using EnergyModel

module CFS_LiquidPrice

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  # CalDB::String = "SCalDB"
  # Input::String = "SInput"
  # Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db,"MainDB/Yrv")

  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate Credits,2=Iterate Emissions,0=Exogenous)
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous (and Initial) CFS Credit Price (1985 US$/Tonne)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Tech Fund Credits (Real US$/Tonne)
  FSellFraction::VariableArray{2} = ReadDisk(db,"SInput/FSellFraction") # [Market,Year] Fraction of Credit Requirements Sold as Tech Fund Credits (Tonne/Tonne)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits,2=Domestic Permits)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index

  # Scratch Variables
  CreditPrice::VariableArray{1} = zeros(Float32,length(Year)) # [Year] CFS Credit Price (Nominal Local $/Tonnes)
  # DR       'Discount Rate ($/($/Yr))'
end

function SupplyPolicy(db)
  data = SControl(; db)
  (; Nation,Years,Yrv) = data
  (; CreditPrice,Enforce,ETADAP,ETRSw,FSellFraction,ISaleSw) = data
  (; xETAPr,xExchangeRateNation,xInflationNation) = data

  market = 205
  Current = Int(Enforce[market]-ITime+1)

  #
  # Exogenous Prices (ETRSw=0)
  #  
  ETRSw[market] = 0
  WriteDisk(db,"SInput/ETRSw",ETRSw)

  #
  # Price Growth Rate (Discount Rate) 
  #   
  DR = 0.025

  for year in Years
    CreditPrice[year] = 110
  end
  
  years = collect(Future:Yr(2030))
  for year in years
    @finite_math CreditPrice[year] = CreditPrice[Yr(2030)]*(1+DR)^(Yrv[year]-Yrv[Yr(2030)])
  end
  
  years = collect(Yr(2031):Yr(2033))
  for year in years
    CreditPrice[year] = 140
  end

  years = collect(Yr(2034):Yr(2035))
  for year in years
    CreditPrice[year] = 60
  end
  
  years = collect(Yr(2036):Yr(2038))
  for year in years
    CreditPrice[year] = 5
  end
  
  years = collect(Yr(2039):Final)
  for year in years
    CreditPrice[year] = 1
  end

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  years = collect(Future:Final)
  for year in years
    xETAPr[market,year] = CreditPrice[year]/xExchangeRateNation[CN,year]/
      xInflationNation[US,year]
  end
  
  WriteDisk(db,"SInput/xETAPr",xETAPr)

  #########################
  #
  # Tech Fund Credits
  #
  for year in Years
    ISaleSw[market,year] = 0
  end
  
  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  for year in Years
    FSellFraction[market,year] = 0.10
  end
  
  WriteDisk(db,"SInput/FSellFraction",FSellFraction)

  for year in Years
    ETADAP[market,year] = 350/xExchangeRateNation[CN,Yr(2022)]/
      xInflationNation[US,Yr(2022)]
  end
  
  WriteDisk(db,"SInput/ETADAP",ETADAP)
end

function PolicyControl(db)
  @info "CFS_LiquidPrice.jl - PolicyControl"
  SupplyPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end

