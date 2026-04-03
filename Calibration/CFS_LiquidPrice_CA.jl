#
# CFS_LiquidPrice_CA.jl
#
using EnergyModel

module CFS_LiquidPrice_CA

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

  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate Credits,2=Iterate Emissions,0=Exogenous)
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous (and Initial) CFS Credit Price (1985 US$/Tonne)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Tech Fund Credits (Real US$/Tonne)
  FSellFraction::VariableArray{2} = ReadDisk(db,"SInput/FSellFraction") # [Market,Year] Fraction of Credit Requirements Sold as Tech Fund Credits (Tonne/Tonne)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits, 2=Domestic Permits)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index

  #
  # Scratch Variables
  #
  CreditPrice::VariableArray{1} = zeros(Float32,length(Year)) # [Year] CFS Credit Price (Nominal Local $/Tonnes)
  # DR       'Discount Rate ($/($/Yr))'
end

function CFS_Prices(db)
  data = SControl(; db)
  (;Nation,Years) = data
  (;CreditPrice,Enforce,ETRSw,ETADAP,FSellFraction,ISaleSw) = data
  (;xETAPr,xInflationNation) = data

  #
  # Need values - Jeff 9/14/23
  # Chart in https://ww2.arb.ca.gov/resources/documents/lcfs-data-dashboard 
  #
  market = 3
  Current = Int(Enforce[market]-ITime+1)
  
  #
  # Exogenous Prices (ETRSw=0)
  #
  ETRSw[market] = 0
  WriteDisk(db,"SInput/ETRSw",ETRSw)

  #
  # Price Growth Rate (Discount Rate) 
  # 
  DR = 0.05

  #
  # Weighted annual prices from California ARB LCFS Data Dashboard
  # https://ww2.arb.ca.gov/resources/documents/lcfs-data-dashboard
  # Jeff Amlin's forecast based on expanded EV and Renewable Diesel
  # - Jeff Amlin - 09/14/23
  #
  CreditPrice[Yr(2013)] =  56 
  CreditPrice[Yr(2014)] =  31 
  CreditPrice[Yr(2015)] =  61 
  CreditPrice[Yr(2016)] = 101 
  CreditPrice[Yr(2017)] =  89 
  CreditPrice[Yr(2018)] = 160 
  CreditPrice[Yr(2019)] = 192 
  CreditPrice[Yr(2020)] = 199 
  CreditPrice[Yr(2021)] = 188 
  CreditPrice[Yr(2022)] = 125 
  CreditPrice[Yr(2023)] =  76 

  years = collect(Yr(2030):Final)
  for year in years
    CreditPrice[year] = 200
  end
  
  years = collect(Yr(2024):Yr(2029))
  for year in years
    CreditPrice[year] = CreditPrice[year-1]+
      (CreditPrice[Yr(2030)]-CreditPrice[Yr(2023)])/(2030-2023)
  end
  
  US = Select(Nation,"US")
  years = collect(Yr(2013):Final)
  for year in years
    xETAPr[market,year] = CreditPrice[year]/xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/xETAPr",xETAPr)  

  #
  ########################
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
    ETADAP[market,year] = 350/xInflationNation[US,Yr(2022)]
  end
  WriteDisk(db,"SInput/ETADAP",ETADAP) 

end

function Control(db)
  @info "CFS_LiquidPrice_CA.jl - Control"

  CFS_Prices(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
