#
# WholesalePrices_CER25_High.jl - Revisions to Wholesale Prices.
#
using EnergyModel

module WholesalePrices_CER25_High

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct WholesalePrices_CER25_HighPolicy
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
  data = WholesalePrices_CER25_HighPolicy(; db)
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
     3.62  2.90  2.26  4.18  6.42  2.53  2.64  4.82  4.84  4.86  4.88  4.90  4.92  4.94  4.96  4.98  5.00  5.02  5.05  5.08  5.11  5.14  5.17  5.20  5.23  5.26  5.29  5.32  5.35  5.38  5.41  5.44  5.47
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
    12.84 11.05  7.50 12.53 16.29 13.33 13.15 14.90 15.92 16.94 17.96 18.98 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00 20.00
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
     7.94  8.57  5.08 10.10 13.42 10.19 10.57 12.64 13.65 14.67 15.68 16.70 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71 17.71
  ]
  for year in years 
    xENPN[fuel,CN,year] = xENPN[fuel,CN,year]/xInflationNation[US,Yr(2022)]*xInflationNation[US,year]*
        xExchangeRateNation[CN,year]/xInflationNation[CN,year]
  end

  WriteDisk(db,"SInput/xENPN",xENPN)

end

function PolicyControl(db)
  @info "WholesalePrices_CER25_High.jl - PolicyControl"

  SPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
