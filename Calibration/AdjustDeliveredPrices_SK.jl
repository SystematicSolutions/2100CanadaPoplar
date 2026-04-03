#
# AdjustDeliveredPrices_SK.jl
#
# Adjust Delivered Fuel Prices for Saskatchewan Utility Natural Gas
# 
# 2015-2022 Natural Gas fuel prices for EU are too low in Saskatchewan given hedges
# made in 2014. Adjust EU NG price for SK using hedge prices and estimated hedge
# fractions. Source: SaskPower's 2014-2016 Rate Application - Final Independent Report.
# - Hilary Paulin 17.03.01
#
using EnergyModel

module AdjustDeliveredPrices_SK

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct AdjustDeliveredPrices_SKCalib
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

  FPDChgF::VariableArray{4} = ReadDisk(db,"SCalDB/FPDChgF") # [Fuel,ES,Area,Year] Fuel Delivery Charge ($/mmBtu)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (1985 US$/mmBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  HedgeFraction::VariableArray{1} = zeros(Float32,length(Year)) # [Year] SaskPower Natural Gas Fraction of Volume Hedged (MJ/MJ)
  HedgePrice::VariableArray{1} = zeros(Float32,length(Year)) # [Year] SaskPower Natural Gas Hedge Price (Real 2014CN$/GJ)
  NewFP::VariableArray{2} = zeros(Float32,length(ES),length(Year)) # [ES,Year] Adjusted delivered fuel price (1985 US$/GJ)
  OldFP::VariableArray{2} = zeros(Float32,length(ES),length(Year)) # [ES,Year] Current delivered fuel price (1985 US$/GJ)
end

function ACalibration(db)
  data = AdjustDeliveredPrices_SKCalib(; db)
  (;Area,AreaDS,Areas,ES,ESDS,ESs,Fuel,FuelDS,Fuels,Nation) = data
  (;NationDS,Nations,Year,YearDS,Years) = data
  (;FPDChgF,xENPN,xInflation) = data
  (;HedgeFraction,HedgePrice,NewFP,OldFP) = data

  SK=Select(Area,"SK")
  CN=Select(Nation,"CN")
  es=Select(ES,"Electric")
  fuel=Select(Fuel,"NaturalGas")
  years=collect(Yr(2015):Yr(2022))
  #
  # Hedge prices in 2014 $CN/GJ, then converted to 1985 CN$/mmBtu
  #
  HedgePrice[Yr(2015)]=4.31
  HedgePrice[Yr(2016)]=4.26
  HedgePrice[Yr(2017)]=4.37
  HedgePrice[Yr(2018)]=4.72
  HedgePrice[Yr(2019)]=5.03
  HedgePrice[Yr(2020)]=5.32
  HedgePrice[Yr(2021)]=5.43
  HedgePrice[Yr(2022)]=5.56

  #
  # Convert price to 1985 CN$/mmBtu
  #
  for year in years
    HedgePrice[year] = HedgePrice[year]*1.055/xInflation[SK,Yr(2014)]
  end

  HedgeFraction[Yr(2015)]=0.45
  HedgeFraction[Yr(2016)]=0.40
  HedgeFraction[Yr(2017)]=0.35
  HedgeFraction[Yr(2018)]=0.30
  HedgeFraction[Yr(2019)]=0.25
  HedgeFraction[Yr(2020)]=0.20
  HedgeFraction[Yr(2021)]=0.15
  HedgeFraction[Yr(2022)]=0.10

  #
  # Calculate Current Fuel Price
  #
  for year in years
    OldFP[es,year]=xENPN[fuel,CN,year]+FPDChgF[fuel,es,SK,year]
  end

  #
  # Calculate new fuel price
  #
  for year in years
    NewFP[es,year]=OldFP[es,year]*(1-HedgeFraction[year])+HedgePrice[year]*HedgeFraction[year]
  end
  
  #
  # Adjust FPDChgF to account for new difference
  #
  for year in years
    FPDChgF[fuel,es,SK,year]=FPDChgF[fuel,es,SK,year]+NewFP[es,year]-OldFP[es,year]
  end
  WriteDisk(db,"SCalDB/FPDChgF",FPDChgF)

end

function CalibrationControl(db)
  @info "AdjustDeliveredPrices_SK.jl - CalibrationControl"

  ACalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
