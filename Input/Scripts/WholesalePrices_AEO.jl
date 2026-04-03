#
# WholesalePrices_AEO.jl - These are the AEO wholesale prices.
#
using EnergyModel

module WholesalePrices_AEO

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct WholesalePrices_AEOCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (1985 US$/mmBtu)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)

  # Scratch Variables
end

function SCalibration(db)
  data = WholesalePrices_AEOCalib(; db)
  (;Fuel,Nation,Years) = data
  (;xENPN,xInflationNation) = data

  #
  #########################
  #
  # US Prices
  #
  nation = Select(Nation,"US")

  #
  # Energy Prices: Units are 2005$/mmBtu.  
  # "Wholesale Fuel Prices 202.xlsx". Luke Davulis
  #
  fuels = Select(Fuel,["LightCrudeOil","NaturalGas","Coal"])
  years = collect(Yr(1985):Yr(2021))
  xENPN[fuels,nation,years] .= [
  #/2005$/mmBtu                1985    1986    1987    1988    1989    1990    1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021
  #=Oil=#                     7.822   4.099   5.090   4.094   4.851   5.834   4.950   4.623   4.046   3.698   3.883   4.573   4.192   2.900   3.834   5.895   4.923   4.876   5.668   7.359   9.724  10.984  11.692  15.760   9.711  12.294  14.370  13.996  14.367  13.459   6.924   6.065   7.003   8.844   7.478   5.059   8.649
  #=NatGas=#                  3.978   3.008   2.521   2.467   2.377   2.316   2.146   2.225   2.550   2.265   1.859   2.555   2.950   2.449   2.622   4.872   4.371   3.667   5.811   6.082   8.690   6.519   6.562   8.160   3.598   3.937   3.529   2.384   3.186   3.677   2.172   2.057   2.401   2.488   1.957   1.528   2.877
  #=Coal=#                    1.870   1.724   1.623   1.509   1.441   1.380   1.325   1.266   1.184   1.135   1.082   1.044   1.006    .964    .909    .897    .924    .944    .925   1.008   1.159   1.200   1.213   1.461   1.589   1.680   1.675   1.638   1.580   1.491   1.345   1.260   1.266   1.280   1.291   1.235   1.227
  ]

  for fuel in fuels, year in years 
    xENPN[fuel,nation,year] = xENPN[fuel,nation,year] / xInflationNation[nation,Yr(2005)]
  end

  #
  # Energy Prices: AEO 2023 Total Energy Supply Disposition and Price
  #                Units are 2022$/mmBtu.  
  # "Wholesale Fuel Prices 2023.xlsx". Luke Davulis
  #
  years = collect(Yr(2022):Yr(2050))
  xENPN[fuels,nation,years] .= [
  #/2022 $/MMBtu                2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
  #=Oil=#                     16.459  14.727  15.650  14.632  14.636  14.684  14.809  14.891  14.968  15.064  15.195  15.268  15.383  15.456  15.592  15.697  15.761  15.853  15.924  16.011  16.089  16.157  16.226  16.284  16.411  16.485  16.604  16.729  16.769
  #=NatGas=#                   6.524   5.266   4.072   3.490   3.066   2.853   2.800   2.825   2.912   3.044   3.208   3.417   3.569   3.682   3.694   3.738   3.867   3.789   3.938   4.022   4.015   3.951   3.914   3.911   3.907   3.871   3.849   3.784   3.771
  #=Coal=#                     1.854   1.836   1.949   1.972   2.075   2.208   2.306   2.358   2.458   2.594   2.478   2.477   2.487   2.489   2.524   2.575   2.636   2.656   2.709   2.709   2.716   2.761   2.805   2.847   2.885   2.905   2.918   2.944   2.976
  ]

  for fuel in fuels, year in years 
    xENPN[fuel,nation,year] = xENPN[fuel,nation,year] / xInflationNation[nation,Yr(2022)]
  end

  #
  # Heavy Oil Price
  #
  fuel = Select(Fuel,"HeavyCrudeOil")
  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  for year in Years 
    xENPN[fuel,nation,year] = max(xENPN[LightCrudeOil,nation,year] - 3.00, xENPN[LightCrudeOil,nation,year] * .60,
                                  0.75 / xInflationNation[nation,Yr(2016)])
  end

  WriteDisk(db,"SInput/xENPN",xENPN)
end

function CalibrationControl(db)
  @info "WholesalePrices_AEO.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
