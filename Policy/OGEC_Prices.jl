#
# OGEC_Prices.jl
#
using EnergyModel

module OGEC_Prices

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ETAPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Tech Fund Credits (Real US$/Tonne)
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous (and Initial) CFS Credit Price (1985 US$/Tonne)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)

  #
  # Scratch Variables
  #
  CreditPrice::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Credit Price (Nominal Local $/Tonnes)
end

function SetOGEC_Prices(db)
  data = SControl(; db)
  (;Nation,Years) = data
  (;CreditPrice,ETADAP,ETAPr,xETAPr,xInflationNation,xExchangeRateNation) = data

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")

  market = 5

  #
  # ********************
  #
  # Exogenous OGEC prices (adjust to find value which clears market) - Jeff Amlin 1/29/25
  #
  CreditPrice[Yr(2030)] = 50.00
  years = collect(Yr(2031):Yr(2035))
  for year in years
    CreditPrice[year] = 50.00
  end
  years = collect(Yr(2036):Yr(2040))
  for year in years
    CreditPrice[year] = 50.00
  end
  years = collect(Yr(2041):Yr(2050))
  for year in years
    CreditPrice[year] = 50.00
  end
  years = collect(Yr(2030):Yr(2050))
  for year in years
    xETAPr[market,year] = CreditPrice[year]/xExchangeRateNation[CN,year]/xInflationNation[US,year]
    ETAPr[market,year] = xETAPr[market,year]*xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/xETAPr",xETAPr)  
  WriteDisk(db,"SOutput/ETAPr",ETAPr)  
  
  #
  # ********************
  #
  # Code to adjust Sequestering, if needed.  Jeff Amlin 1/29/25
  #
  # Select Year(2026-2029)
  # xSqPriceAdd(ECC,Area,Y)=0.00*CreditPrice(Y)*CoveredOGEC(ECC,Area,2030)/xInflationCN(Y)
  # Write Disk(xSqPriceAdd)
  #  
  
  #
  # ********************
  #
  # Tech Fund Credit Prices (set by policy, but only 10% of remittances permitted)
  #
  years = collect(Yr(2030):Final)
  for year in years
    ETADAP[market,year] = 50/xExchangeRateNation[CN,year]/xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/ETADAP",ETADAP) 

end

function PolicyControl(db)
  @info "OGEC_Prices.jl - PolicyControl"
  SetOGEC_Prices(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
