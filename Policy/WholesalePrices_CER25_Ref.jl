#
# WholesalePrices_CER25_Ref.jl - Revisions to Wholesale Prices.
#
using EnergyModel

module WholesalePrices_CER25_Ref

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct WholesalePrices_CER25_RefPolicy
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (1985 US$/mmBtu)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)

  # Scratch Variables
  AEOPrices::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] AEO Wholesale Fuel Prices ($/mmBtu)
end

function SPolicy(db)
  data = WholesalePrices_CER25_RefPolicy(; db)
  (;ES,Fuel,Fuels,Nation,Nations,Years) = data
  (;ANMap,xExchangeRateNation,xENPN,xInflationNation) = data
  (;AEOPrices) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  #
  #########################
  #
  # Source: Thuo Kossa August 2024, Preliminary Case
  #
  fuel = Select(Fuel,"NaturalGas")
  years = collect(Yr(2018):Yr(2050))
  xENPN[fuel,CN,years] = [
  #/ 2018  2019  2020  2021  2022  2023  2024  2025  2026  2027  2028  2029  2030  2031  2032  2033  2034  2035  2036  2037  2038  2039  2040  2041  2042  2043  2044  2045  2046  2047  2048  2049  2050  
     3.62  2.90  2.26  4.18  6.42  2.53  2.64  3.50  3.60  3.73  3.81  3.95  4.00  4.02  4.03  4.05  4.06  4.08  4.09  4.11  4.12  4.14  4.15  4.17  4.18  4.20  4.21  4.23  4.24  4.25  4.27  4.28  4.30
  ]
  for year in years 
    xENPN[fuel,CN,year] = xENPN[fuel,CN,year]/xInflationNation[US,Yr(2022)]*xInflationNation[US,year]*
        xExchangeRateNation[CN,year]/xInflationNation[CN,year]
  end

  #
  # Light Crude Oil Price
  #
  fuel = Select(Fuel,"LightCrudeOil")
  years = collect(Yr(2018):Yr(2050))
  xENPN[fuel,CN,years] = [
  #/ 2018  2019  2020  2021  2022  2023  2024  2025  2026  2027  2028  2029  2030  2031  2032  2033  2034  2035  2036  2037  2038  2039  2040  2041  2042  2043  2044  2045  2046  2047  2048  2049  2050  
    12.84 11.05  7.50 12.53 16.29 13.33 13.15 13.89 14.03 14.17 14.32 14.46 14.60 14.59 14.57 14.55 14.53 14.51 14.50 14.48 14.46 14.44 14.43 14.41 14.39 14.37 14.35 14.34 14.32 14.30 14.28 14.26 14.25 
  ]
  for year in years 
    xENPN[fuel,CN,year] = xENPN[fuel,CN,year]/xInflationNation[US,Yr(2022)]*xInflationNation[US,year]*
        xExchangeRateNation[CN,year]/xInflationNation[CN,year]
  end

  #
  # Heavy Crude Oil Price
  #
  fuel = Select(Fuel,"HeavyCrudeOil")
  years = collect(Yr(2018):Yr(2050))
  xENPN[fuel,CN,years] = [
  #/ 2018  2019  2020  2021  2022  2023  2024  2025  2026  2027  2028  2029  2030  2031  2032  2033  2034  2035  2036  2037  2038  2039  2040  2041  2042  2043  2044  2045  2046  2047  2048  2049  2050  
     7.94  8.57  5.08 10.10 13.42 10.19 10.57 11.31 11.46 11.60 11.74 11.89 12.03 11.84 11.65 11.46 11.44 11.42 11.41 11.39 11.37 11.35 11.33 11.32 11.30 11.28 11.26 11.25 11.23 11.21 11.19 11.17 11.16 
  ]
  for year in years 
    xENPN[fuel,CN,year] = xENPN[fuel,CN,year]/xInflationNation[US,Yr(2022)]*xInflationNation[US,year]*
        xExchangeRateNation[CN,year]/xInflationNation[CN,year]
  end

  WriteDisk(db,"SInput/xENPN",xENPN)

end

function PolicyControl(db)
  @info "WholesalePrices_CER25_Ref.jl - PolicyControl"

  SPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
