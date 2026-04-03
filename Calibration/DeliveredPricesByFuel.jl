#
# DeliveredPricesByFuel.jl - Assigns values to price variables by fuel
#
using EnergyModel

module DeliveredPricesByFuel

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DeliveredPricesByFuelCalib
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
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  FPMarginF::VariableArray{4} = ReadDisk(db,"SInput/FPMarginF") # [Fuel,ES,Area,Year] Refinery/Distributor Margin ($/$)
  FPSMF::VariableArray{4} = ReadDisk(db,"SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db,"SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (Real $/mmBtu)
  xFPBaseF::VariableArray{4} = ReadDisk(db,"SInput/xFPBaseF") # [Fuel,ES,Area,Year] Delivered Fuel Price without Taxes (Real $/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function SCalibration(db)
  data = DeliveredPricesByFuelCalib(; db)
  (;Area,Areas,ES,ESs,Fuel,Fuels,Nation,Nations,Years) = data
  (;ANMap,xExchangeRate,FPMarginF,FPSMF,FPTaxF,xENPN,xFPBaseF,xFPF,xInflation) = data
  

  #
  # Insure that delivered oil, gas, coal, LPG, and biomass prices
  # are greater than wholesale prices. Jeff Amlin 4/07/09
  #
  notincluded = Select(Fuel,["NaturalGas","Coal"])
  fuels = setdiff(Fuels,notincluded)
  for nation in Nations, area in Areas
    if ANMap[area,nation] == 1.0
      for year in Years, es in ESs, fuel in fuels
        if xFPF[fuel,es,area,year] > 0
          xFPF[fuel,es,area,year] = max(xFPF[fuel,es,area,year],xENPN[fuel,nation,year])
        end
      end
    end
  end

  #
  ########################
  #
  # Canada Price Adjustments
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # Canada Electric prices are grown into the future since they are calibrated
  # into the future and used for exogenous electric price scenarios.
  #
  years = collect(Future:Final)
  fuel = Select(Fuel,"Electric")
  for area in areas, es in ESs, year in years 
    if xFPF[fuel,es,area,year] == 0
      xFPF[fuel,es,area,year] = xFPF[fuel,es,area,year-1] * 1.020
    end
  end

  #
  # Canada Coal prices are all set to wholesale coal price
  #
  fuel = Select(Fuel,"Coal")
  ess = Select(ES,(from = "Residential", to = "Transport"))
  for year in Years, area in areas, es in ess
    xFPF[fuel,es,area,year] = xENPN[fuel,CN,year]
  end

  #
  #  Canada Steam prices are based on wholesale steam prices plus 50%
  #
  fuel = Select(Fuel,"Steam")
  for year in Years, area in areas, es in ess
    xFPF[fuel,es,area,year] = xENPN[fuel,CN,year] * 1.50
  end
  
  #
  #  Canada LPG prices (except Industrial) are based on light oil prices
  #
  LFO = Select(Fuel,"LFO")
  fuel = Select(Fuel,"LPG")
  ess = Select(ES,["Residential","Commercial"])
  for year in Years, area in areas, es in ess
    xFPF[fuel,es,area,year] = xFPF[LFO,es,area,year]
  end
  Commercial = Select(ES,"Commercial")
  es = Select(ES,"Transport")
  for year in Years, area in areas
    xFPF[fuel,es,area,year] = xFPF[LFO,Commercial,area,year]
  end

  #
  #  Canada Ethanol price is based on gasoline
  #
  fuel = Select(Fuel,"Ethanol")
  Gasoline = Select(Fuel,"Gasoline")
  for year in Years, area in areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[Gasoline,es,area,year]
    FPSMF[fuel,es,area,year] = FPSMF[Gasoline,es,area,year]
    FPTaxF[fuel,es,area,year] = FPTaxF[Gasoline,es,area,year]
  end

  #
  # Canada Aviation Fuel is based on Diesel
  #
  fuel = Select(Fuel,"JetFuel")
  Diesel = Select(Fuel,"Diesel")
  for year in Years, area in areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[Diesel,es,area,year]
  end

  #
  # Canada Transportation NG Price is Commercial NG Price
  # - Jeff Amlin 6/23/13
  #
  fuel = Select(Fuel,"NaturalGas")
  es = Select(ES,"Transport")
  for year in Years, area in areas
    xFPF[fuel,es,area,year] = xFPF[fuel,Commercial,area,year]
  end

  #
  # Canada Own Use Prices
  #
  es = Select(ES,"Misc")
  Industrial = Select(ES,"Industrial")
  fuels = Select(Fuel,["NaturalGas","HFO"])
  for year in Years, area in areas, fuel in fuels
    xFPF[fuel,es,area,year] = xFPF[fuel,Industrial,area,year]
  end

  #
  ########################
  #
  # US Price Adjustments
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)

  #
  # US Electric Generation Prices - Remove disparity between US and Canada 
  # - Jeff Amlin 10/25/11
  #
  es = Select(ES,"Electric")
  fuels = Select(Fuel,["HFO","LFO","NaturalGas"])
  ON=Select(Area,"ON")
  years = 1:(Final-1)
  for year in years, area in areas, fuel in fuels
    xFPF[fuel,es,area,year] = xFPF[fuel,es,ON,year] * xInflation[ON,year] / xExchangeRate[ON,year] *
                              xExchangeRate[area,year] / xInflation[area,year]
  end

  #
  # US Steam Prices are based on wholesale steam prices plus 50%
  #
  fuel = Select(Fuel,"Steam")
  ess = Select(ES,["Residential","Commercial","Industrial"])
  for year in Years, area in areas, es in ess
    xFPF[fuel,es,area,year] = xENPN[fuel,US,year] * 1.50
  end

  #
  ########################
  #
  # Mexico Price Adjustments
  #
  MX = Select(Nation,"MX")
  areas = findall(ANMap[:,MX] .== 1.0)
  
  #
  #  Mexico Ethanol price is based on gasoline
  #
  fuel = Select(Fuel,"Ethanol")
  Gasoline = Select(Fuel,"Gasoline")
  for year in Years, area in areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[Gasoline,es,area,year]
  end

  #
  #  MX Steam Prices are based on wholesale steam prices plus 50%
  #
  fuel = Select(Fuel,"Steam")
  ess = Select(ES,["Residential","Commercial","Industrial"])
  for year in Years, area in areas, es in ess 
    xFPF[fuel,es,area,year] = xENPN[fuel,MX,year] * 1.50
  end

  #
  ########################
  #
  # ROW prices higher than US West South Central (WSC) prices
  #
  ROW = Select(Nation,"ROW")
  areas = findall(ANMap[:,ROW] .== 1.0)
  WSC = Select(Area,"WSC")
  for year in Years, area in areas, es in ESs, fuel in Fuels 
    xFPF[fuel,es,area,year] = xFPF[fuel,es,WSC,year] * 1.25
  end

  ########################
  #
  # Maps to similar fuels
  #
  # Move prices from similar fuels if missing input data based on old
  # PrFlMap - Ian 02/01/22
  #
  # Electric
  #
  ess = Select(ES,(from = "Residential", to = "Industrial"))
  fuels = Select(Fuel,["Geothermal","Solar"])
  Electric = Select(Fuel,"Electric")
  for year in Years, area in Areas, es in ess, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[Electric,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Electric,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Electric,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[Electric,es,area,year]
  end

  es = Select(ES,"Transport")
  fuels = Select(Fuel,["Electric","Geothermal","Solar"])
  Commercial = Select(ES,"Commercial")
  for year in Years, area in Areas, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[Electric,Commercial,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Electric,Commercial,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Electric,Commercial,area,year] 
    xFPF[fuel,es,area,year] = xFPF[Electric,Commercial,area,year]
  end

  #
  # Natural Gas
  #
  fuels = Select(Fuel,["NaturalGasRaw","StillGas","CokeOvenGas"])
  NaturalGas = Select(Fuel,"NaturalGas")
  for year in Years, area in Areas, es in ESs, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[NaturalGas,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[NaturalGas,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[NaturalGas,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[NaturalGas,es,area,year]
  end

  #
  # Coal
  #
  fuels = Select(Fuel,["Coke","PetroCoke"])
  Coal = Select(Fuel,"Coal")
  for year in Years, area in Areas, es in ESs, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[Coal,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Coal,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Coal,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[Coal,es,area,year]
  end
  
  #
  # Oil
  #
  ess = Select(ES,["Residential","Commercial"])
  fuels = Select(Fuel,["Asphalt","Asphaltines","Biodiesel","Diesel","HFO",
                       "Kerosene","Lubricants","NonEnergy","PetroFeed"])
  LFO = Select(Fuel,"LFO")
  for year in Years, area in Areas, es in ess, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[LFO,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[LFO,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[LFO,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[LFO,es,area,year]
  end

  ess = Select(ES,["Industrial","Transport"])
  fuels = Select(Fuel,["Asphalt","Asphaltines","Kerosene","LFO","Lubricants",
                       "NonEnergy","PetroFeed"])
  HFO = Select(Fuel,"HFO")
  for year in Years, area in Areas, es in ess, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[HFO,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[HFO,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[HFO,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[HFO,es,area,year]
  end

  #
  # Transport uses Ind values for feedstocks
  #
  es = Select(ES,"Transport")
  Industrial = Select(ES,"Industrial")
  fuels = Select(Fuel,["Asphalt","Lubricants","NonEnergy","PetroFeed"])
  for year in Years, area in Areas, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[HFO,Industrial,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[HFO,Industrial,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[HFO,Industrial,area,year] 
    xFPF[fuel,es,area,year] = xFPF[HFO,Industrial,area,year]
  end
  
  es = Select(ES,"Electric")
  fuels = Select(Fuel,["Asphaltines","Biodiesel","Biojet","Diesel","JetFuel",
                       "Kerosene","LPG","Lubricants","Naphtha"])
  for year in Years, area in Areas, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[LFO,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[LFO,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[LFO,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[LFO,es,area,year]
  end

  fuel = Select(Fuel,"PetroFeed")
  for year in Years, area in Areas
    FPMarginF[fuel,es,area,year] = FPMarginF[HFO,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[HFO,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[HFO,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[HFO,es,area,year]
  end

  fuel = Select(Fuel,"Asphalt")
  for year in Years, area in Areas
    FPMarginF[fuel,es,area,year] = FPMarginF[HFO,Industrial,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[HFO,Industrial,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[HFO,Industrial,area,year] 
    xFPF[fuel,es,area,year] = xFPF[HFO,Industrial,area,year]
  end

  #
  # Gasoline
  #
  fuel = Select(Fuel,"AviationGasoline")
  Gasoline = Select(Fuel,"Gasoline")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[Gasoline,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Gasoline,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Gasoline,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[Gasoline,es,area,year]
  end

  #
  # Jet Fuel
  #
  fuel = Select(Fuel,"Naphtha")
  JetFuel = Select(Fuel,"JetFuel")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[JetFuel,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[JetFuel,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[JetFuel,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[JetFuel,es,area,year]
  end

  #
  # Diesel
  #
  es = Select(ES,"Industrial")
  fuels = Select(Fuel,["Asphaltines","Biodiesel"])
  Diesel = Select(Fuel,"Diesel")
  for year in Years, area in Areas, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[Diesel,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Diesel,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Diesel,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[Diesel,es,area,year]
  end

  es = Select(ES,"Transport")
  fuels = Select(Fuel,["Asphaltines","Biodiesel","Kerosene","LFO"])
  Diesel = Select(Fuel,"Diesel")
  for year in Years, area in Areas, fuel in fuels
    FPMarginF[fuel,es,area,year] = FPMarginF[Diesel,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Diesel,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Diesel,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[Diesel,es,area,year]
  end

  ########################
  #
  # Price inputs
  #
  # Renewable Natural Gas Wholesale Prices are $15/mmBtu (2015 US$/mmBtu)
  # from "C:\2020CanadaPoplar\2020Model\From ECCC\Frederic\Price by Fuel Input Data Assumptions.xlsm"
  #
  # "The Feasibility of Renewable Natural Gas as a Large-Scale, Low Carbon
  # Substitute" by the STEPS Program, Institute of Transportation Studies,
  # UC Davis under the sponsorship of the California Air Resources Board.
  # Work was completed as of February 29, 2016 and updated as of June 2016.
  # This study shows RNG to be $10 higher than tha Natural gas
  # Update from 2024 by NC. Fortis BC has marked renewable natural gas at 1.56 times the price of natural gas
  # Changing FPF because Fortis numbers are delivered prices and not wholesale prices
  #
  fuel = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[NaturalGas,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[NaturalGas,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[NaturalGas,es,area,year] 
  end

  years = collect(Yr(1985):Final)
  area=Select(Area,"BC")
  for year in years, es in ESs
    xFPF[fuel,es,area,year] = xFPF[NaturalGas,es,area,year]*1.56
  end
  area=Select(Area,"QC")
  for year in years, es in ESs
    xFPF[fuel,es,area,year] = xFPF[NaturalGas,es,area,year]*4.03
  end
  area=Select(Area,"ON")
  for year in years, es in ESs
    xFPF[fuel,es,area,year] = xFPF[NaturalGas,es,area,year]*4.80
  end
  areas=Select(Area,["AB","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  for year in years, area in areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[NaturalGas,es,area,year]*4.42
  end

  #
  # Ethanol Wholesale Prices are 31% higher than gasoline.
  # from "C:\2020CanadaPoplar\2020Model\From ECCC\Frederic\Price by Fuel Input Data Assumptions.xlsm"
  #
  fuel = Select(Fuel,"Ethanol")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[Gasoline,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Gasoline,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Gasoline,es,area,year] 
  end

  #
  # Review to see if we can remove Select Year - Ian 05/07/24
  years = collect(Yr(1985):Yr(2017))
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[Gasoline,es,area,year] + xENPN[Gasoline,US,year] * 
                              0.31 * xExchangeRate[area,year]
  end

  es = Select(ES,"Transport")
  fuel = Select(Fuel,"Biomass")
  Ethanol = Select(Fuel,"Ethanol")
  for year in Years, area in Areas
    xFPF[fuel,es,area,year] = xFPF[Ethanol,es,area,year]
  end

  #
  # Biodiesel Wholesale Prices are 33% higher than Diesel from 1985 to 2017 and 22% higher from 2018-2022
  # first calc from "C:\2020CanadaPoplar\2020Model\From ECCC\Frederic\Price by Fuel Input Data Assumptions.xlsm"
  # second calc from "\\ncr.int.ec.gc.ca\shares\E\ECOMOD\_Annual Updates\2021_Update\Biodiesel Prices\bio_diesel.xlsx#'US_Alt_Fuel_BD"
  #
  fuel = Select(Fuel,"Biodiesel")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[Diesel,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Diesel,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Diesel,es,area,year] 
  end

  years = collect(Yr(1985):Yr(2017))
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[Diesel,es,area,year] + xENPN[Diesel,US,year] * 
                              0.33 * xExchangeRate[area,year]
  end
  years = collect(Yr(2018):Yr(2022))
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[Diesel,es,area,year] + xENPN[Diesel,US,year] * 
                              0.22 * xExchangeRate[area,year]
  end

  #
  # Renewable Natural Gas Wholesale Prices are $15/mmBtu
  # from "C:\2020CanadaPoplar\2020Model\From ECCC\Frederic\Price by Fuel Input Data Assumptions.xlsm"
  #
  fuel = Select(Fuel,"Biogas")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[NaturalGas,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[NaturalGas,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[NaturalGas,es,area,year]
  end

  years = collect(Yr(1985):Yr(2017))
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[NaturalGas,es,area,year] + (15.00 / 
                              xInflation[area,Yr(2015)] - xENPN[NaturalGas,US,year]) *
                              xExchangeRate[area,year]
  end
  years = collect(Yr(2018):Final)
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = max(xFPF[fuel,es,area,year-1] * (1-0.02), xFPF[NaturalGas,es,area,year])
  end

  #
  # Solid Waste is assigned the Coal Price
  #
  fuel = Select(Fuel,"Waste")
  Coal = Select(Fuel,"Coal")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[Coal,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[Coal,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[Coal,es,area,year] 
    xFPF[fuel,es,area,year] = xFPF[Coal,es,area,year]
  end
  
  #
  # Light Crude Oil is assigned Light Fuel Oil Price (for electric utility sector)
  # Jeff Amlin 07/15/18
  #
  fuel = Select(Fuel,"LightCrudeOil")
  LFO = Select(Fuel,"LFO")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[LFO,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[LFO,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[LFO,es,area,year] 
  end

  years = collect(Yr(1985):Yr(2017))
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[LFO,es,area,year]
  end

  #
  # Biojet prices are 4.5 times than JetFuel in 2015
  # from "C:\2020CanadaPoplar\2020Model\From ECCC\Frederic\Price by Fuel Input Data Assumptions.xlsm"
  #
  fuel = Select(Fuel,"Biojet")
  JetFuel = Select(Fuel,"JetFuel")
  for year in Years, area in Areas, es in ESs
    FPMarginF[fuel,es,area,year] = FPMarginF[JetFuel,es,area,year] 
    FPSMF[fuel,es,area,year] = FPSMF[JetFuel,es,area,year] 
    FPTaxF[fuel,es,area,year] = FPTaxF[JetFuel,es,area,year] 
  end

  years = collect(Yr(1985):Yr(2017))
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[JetFuel,es,area,Yr(2015)] * 4.50
  end
  years = collect(Yr(2018):Final)
  for year in years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = max(xFPF[fuel,es,area,year-1] * (1-0.02), xFPF[JetFuel,es,area,Yr(2015)])
  end
  
  #
  ########################
  #
  # Hydrogen set based on Hydrogen Production module - Jeff Amlin 03/09/21
  #
  #Select Fuel(Hydrogen)
  #Do Nation
  #  Select Area*
  #  Select Area If ANMap eq 1
  #  Do If ANMap eq 1
  #    Select Year(1985-2020)
  #    xFPF(Fuel,ES,A,Y)=xmax(90.00/xInflation(A,2017),xENPN(Fuel,N,Y)*1.10)
  #    Select Year(2021-Final)
  #    xFPF(Fuel,ES,A,Y)=xmax(xFPF(Hydrogen,ES,A,Y-1)*(1-0.02),xENPN(Fuel,N,Y)*1.10)
  #    Select Year*
  #  End Do If ANMap
  #End Do Nation
  #Select Fuel*, Area*
  #
  # Hydrogen set based on Hydrogen Production module - Jeff Amlin 03/09/21
  # Hydrogen Prices (recycled from ENERGY 2100) - Jeff Amlin 7/4/22
  # Hydrogen Prices (2017 CN$/mmBtu)
  #
  fuel = Select(Fuel,"Hydrogen")
  AB = Select(Area,"AB")
  years = collect(Yr(1990):Yr(2050))
  xFPF[fuel,Industrial,AB,years] = [
  #/  1990     1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
    7.7047  7.7272  7.5671  7.9836  8.2850  9.1793  9.1078  9.4222  9.7673  10.2125 10.3718 10.8021 12.8960 14.4768 16.7564 15.4907 16.9142 14.5738 12.5214 15.0582 11.3520 9.5323  9.0938  7.7960  9.2458  10.5561 9.1818  7.4272  7.5780  7.3907  7.8556  7.8572  8.8678  9.0591  9.0407  9.0653  9.1371  9.2252  9.4051  9.5226  9.6010  9.7136  9.7729  9.7722  9.8449  9.9074  9.9526  10.0095 10.0579 10.1046 10.1463 10.1893 10.2380 10.3023 10.3857 10.4912 10.5869 10.6902 10.8039 10.9390 11.0925
  ]
  
  for year in years
    xFPF[fuel,Industrial,AB,year] = xFPF[fuel,Industrial,AB,year] / xInflation[AB,Yr(2017)]
  end 

  years = collect(Yr(1985):Yr(1989))
  for year in years 
    xFPF[fuel,Industrial,AB,year] = xFPF[fuel,Industrial,AB,Yr(1990)]
  end
  
  for year in Years, area in Areas, es in ESs
    xFPF[fuel,es,area,year] = xFPF[fuel,Industrial,AB,year]
  end

  WriteDisk(db,"SInput/FPMarginF",FPMarginF)
  WriteDisk(db,"SInput/FPSMF",FPSMF)
  WriteDisk(db,"SInput/FPTaxF",FPTaxF)
  WriteDisk(db,"SInput/xFPF",xFPF)

  #
  ########################
  #
  #  xFPF=(xFPBaseF+FPTaxF)*(1+FPSMF)
  #  xFPF/(1+FPSMF)=(xFPBaseF+FPTaxF)
  #  xFPF/(1+FPSMF)=xFPBaseF+FPTaxF
  #  xFPF/(1+FPSMF)-FPTaxF=xFPBaseF
  #

  for year in Years, area in Areas, es in ESs, fuel in Fuels
    if (xFPF[fuel,es,area,year] > 0) && (xFPBaseF[fuel,es,area,year] == 0)
      xFPBaseF[fuel,es,area,year] = xFPF[fuel,es,area,year] / (1 + FPSMF[fuel,es,area,year]) -
                                    FPTaxF[fuel,es,area,year]
    end
  end

  WriteDisk(db,"SInput/xFPBaseF",xFPBaseF)

end

function CalibrationControl(db)
  @info "DeliveredPricesByFuel.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
