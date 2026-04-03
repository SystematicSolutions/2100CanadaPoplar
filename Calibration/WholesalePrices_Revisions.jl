#
# WholesalePrices_Revisions.jl - Revisions to Wholesale Prices.
#
using EnergyModel

module WholesalePrices_Revisions

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Wholesale Price ($/mmBtu)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (1985 US$/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)

  #
  # Scratch Variables
  #
  AEOPrices::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] AEO Wholesale Fuel Prices ($/mmBtu)
end

function WholesalePrices(db)
  data = SControl(; db)
  (;ES,Fuel,Fuels,Nation,Nations,Years) = data
  (;ANMap,ENPN,xExchangeRateNation,xENPN,xFPF,xInflationNation) = data
  (;AEOPrices) = data
  
  #
  #########################
  #
  # Fuel prices which are driven by world Light Crude Oil price.
  #
  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  fuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline",
                       "JetFuel","Kerosene","LFO","Lubricants","Naphtha",
                       "NonEnergy","PetroFeed"])
                       
  for year in Years, nation in Nations, fuel in fuels
    xENPN[fuel,nation,year] = xENPN[LightCrudeOil,nation,year]
  end
  
  #
  #########################
  #
  # Heavy Fuel Oil prices are set by Heavy Crude Oil
  #
  HeavyCrudeOil = Select(Fuel,"HeavyCrudeOil")
  fuel = Select(Fuel,"HFO")
  for year in Years, nation in Nations, fuel in fuel
    xENPN[fuel,nation,year] = xENPN[HeavyCrudeOil,nation,year]
  end  

  #
  #########################
  #
  # Ethanol and Biodiesel wholesale prices equal to world oil price. J. Amlin 9/26/09
  #
  fuels = Select(Fuel,["Ethanol","Biodiesel"])
  for year in Years, nation in Nations, fuel in fuels
    xENPN[fuel,nation,year] = xENPN[LightCrudeOil,nation,year]
  end

  #
  #########################
  #
  # Fuel prices are driven by coal price
  #
  Coal = Select(Fuel,"Coal")
  fuels = Select(Fuel,["Coke","Waste"])
  for year in Years, nation in Nations, fuel in fuels
    xENPN[fuel,nation,year] = xENPN[Coal,nation,year]
  end

  #
  #########################
  #
  # Fuel prices are driven by natural gas price.
  #
  NaturalGas = Select(Fuel,"NaturalGas")
  fuels = Select(Fuel,["Hydrogen","NaturalGasRaw","RNG","Steam",
                       "CokeOvenGas","StillGas"])
  for year in Years, nation in Nations, fuel in fuels
    xENPN[fuel,nation,year] = xENPN[NaturalGas,nation,year]
  end

  #
  #########################
  #
  # Hydrogen set based on Hydrogen Production module - Jeff Amlin 03/09/21
  # Hydrogen Prices (recycled from ENERGY 2100) - Jeff Amlin 7/4/22
  # Hydrogen Prices (2017 CN$/mmBtu)
  #
  fuel = Select(Fuel,"Hydrogen")
  CN = Select(Nation,"CN")
  years = collect(Yr(1990):Yr(2050))
  xENPN[fuel,CN,years] = [
  #/  1990     1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
    9.7663  10.4681 10.2868 10.6049 10.9407 11.7025 10.9561 11.0375 11.6057 12.3784 12.5924 14.2814 16.8931 17.3273 18.4675 17.8339 18.6595 18.3818 14.8147 17.3612 14.3701 12.5704 11.5004 10.3494 11.1239 12.3267 11.8678 11.1577 11.2207 10.6998 10.1182 9.6295  10.0112 11.4263 11.6230 11.7363 11.8595 11.9977 12.1314 12.2062 12.2645 12.3085 12.3875 12.3974 12.4661 12.5324 12.6071 12.6655 12.7432 12.8039 12.8788 12.9439 13.0155 13.0701 13.1787 13.3057 13.4147 13.5367 13.6570 13.8099 13.9833
  ]
  for year in years 
    xENPN[fuel,CN,year] = xENPN[fuel,CN,year] / xInflationNation[CN,Yr(2017)]
  end
  years = collect(Yr(1985):Yr(1989))
  for year in years 
    xENPN[fuel,CN,year] = xENPN[fuel,CN,Yr(1990)] 
  end
  for year in Years, nation in Nations 
    xENPN[fuel,nation,year] = xENPN[fuel,CN,year]
  end

  #
  # Ammonia prices based on amount of Hydrogen required
  # 1 mmbtu of Hydrogen produces 0.8677 mmbtu of Ammonia
  # -pnv 8/23/2024
  #
  fuel=Select(Fuel,"Ammonia")
  Hydrogen=Select(Fuel,"Hydrogen")
  for year in Years, nation in Nations 
    xENPN[fuel,nation,year] = xENPN[Hydrogen,nation,year]/0.8677
  end

  #
  #########################
  #
  # In US LPG Prices are driven by Oil Prices
  #
  US = Select(Nation,"US")
  fuel = Select(Fuel,"LPG")
  for year in Years
    xENPN[fuel,US,year] = xENPN[LightCrudeOil,US,year]
  end

  #
  # In Canada LPG wholesale prices are based on lowest LPG
  # delivered price for the historical period, then oil prices in forecast.
  # Jeff Amlin 12/2/13
  #
  areas = findall(ANMap[:,CN] .== 1.0)
  es = Select(ES,"Industrial")
  for year in Years
    Loc1 = minimum(xFPF[fuel,es,area,year] for area in areas)
    if (Loc1 > 0.0) || (year == 1)
      xENPN[fuel,CN,year] = Loc1
    else
      xENPN[fuel,CN,year] = xENPN[fuel,CN,year-1] * xENPN[LightCrudeOil,CN,year] /
                            xENPN[LightCrudeOil,CN,year-1]
    end
  end
  
  #
  #########################
  #
  # Biomass Prices - Fill Historical Prices
  #
  fuel = Select(Fuel,"Biomass")
  years = reverse(collect(Zero:Last))
  for nation in Nations, year in years 
    if xENPN[fuel,nation,year] == 0
      xENPN[fuel,nation,year] = xENPN[fuel,nation,year+1]
    end
  end

  #
  #########################
  #
  # Store AEO Prices
  #
  for year in Years, fuel in Fuels
    AEOPrices[fuel,year] = xENPN[fuel,US,year]
  end

  #
  #########################
  #
  # For US calibration, use the historical Canada prices
  #
  years = collect(Zero:Last)
  # Time Series Revised
  for fuel in Fuels, year in years
    xENPN[fuel,US,year] = xENPN[fuel,CN,year] * xInflationNation[CN,year] / 
                          xExchangeRateNation[CN,year] / xInflationNation[US,year]
  end
  
  #
  # For US forecast use AEO growth rates
  #
  years = collect(Future:Final)
  for fuel in Fuels, year in years 
    @finite_math xENPN[fuel,US,year] = xENPN[fuel,US,year-1] * AEOPrices[fuel,year] / AEOPrices[fuel,year-1]
  end

  #
  #########################
  #
  # Hold missing prices constant at 2040 value - Jeff Amlin 10/3/19
  #
  years = collect(Yr(2041):Yr(2050))
  for fuel in Fuels, year in years
    if xENPN[fuel,CN,year] == 0
      xENPN[fuel,CN,year] = xENPN[fuel,CN,year-1]
    end
  end

  #
  #########################
  # 
  # Mexico and ROW Prices equal to US
  #
  nations = Select(Nation,["MX","ROW"])
  # Time Series Revised
  for fuel in Fuels, nation in nations, year in Years
    @finite_math xENPN[fuel,nation,year] = xENPN[fuel,US,year] * xInflationNation[US,year] / 
                              xExchangeRateNation[nation,year] / xInflationNation[nation,year]
  end

  @. ENPN = xENPN

  WriteDisk(db,"SInput/xENPN",xENPN)
  WriteDisk(db,"SOutput/ENPN",ENPN)

end

function Control(db)
  @info "WholesalePrices_Revisions.jl - Control"
  WholesalePrices(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
