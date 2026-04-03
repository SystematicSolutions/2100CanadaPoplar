#
# E2020WholesalePrices.jl
#
using EnergyModel

module E2020WholesalePrices

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  WorldTOM::SetArray = ReadDisk(db,"KInput/WorldTOMKey")
  WorldTOMDS::SetArray = ReadDisk(db,"KInput/WorldTOMDS")
  WorldTOMs::Vector{Int} = collect(Select(WorldTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Wholesale Price (1985 Local$/mmBtu)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  WPCLe::VariableArray{2} = ReadDisk(db,"KOutput/WPCLe") # [WorldTOM,Year] Coal Price from ENERGY 2020 (Index of $/Ton (2005=100))
  WPGasHHe::VariableArray{2} = ReadDisk(db,"KOutput/WPGasHHe") # [WorldTOM,Year] Gas World Price from ENERGY 2020 ($US/mmBtu)
  WPO_WCSe::VariableArray{2} = ReadDisk(db,"KOutput/WPO_WCSe") # [WorldTOM,Year] Wholesale/global price of oil - WTI from E2020 (US$/bbl)
  WPO_WTIe::VariableArray{2} = ReadDisk(db,"KOutput/WPO_WTIe") # [WorldTOM,Year] Wholesale/global price of oil - WPO from E2020 (US$/bbl)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)

  # Scratch Variables
end

# function OilWholesalePrices(data)
#   (;CalDB,Input,Outpt) = data
#   (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
#   (;NationDS,Nations,WorldTOM,WorldTOMDS,WorldTOMs,Year,YearDS,Years) = data
#   (;ENPN,MapAreaTOM,WPCLe,WPGasHHe,WPO_WCSe,WPO_WTIe,xExchangeRateNation,xInflationNation) = data

# end

# function GasWholesalePrices(data)
#   (;CalDB,Input,Outpt) = data
#   (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
#   (;NationDS,Nations,WorldTOM,WorldTOMDS,WorldTOMs,Year,YearDS,Years) = data
#   (;ENPN,MapAreaTOM,WPCLe,WPGasHHe,WPO_WCSe,WPO_WTIe,xExchangeRateNation,xInflationNation) = data

# end

# function CoalWholesalePrices(data)
#   (;CalDB,Input,Outpt) = data
#   (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
#   (;NationDS,Nations,WorldTOM,WorldTOMDS,WorldTOMs,Year,YearDS,Years) = data
#   (;ENPN,MapAreaTOM,WPCLe,WPGasHHe,WPO_WCSe,WPO_WTIe,xExchangeRateNation,xInflationNation) = data

# end

function MapWholesalePrices(db)
  data = MControl(; db)
  (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
  (;NationDS,Nations,WorldTOM,WorldTOMDS,WorldTOMs,Year,YearDS,Years) = data
  (;ENPN,MapAreaTOM,WPCLe,WPGasHHe,WPO_WCSe,WPO_WTIe,xExchangeRateNation,xInflationNation) = data

  #
  # Oil Wholesale Prices
  #
  # Convert from 1985$ local (CN) dollars per mmBtu to nominal US dollars per barrel
  #
  fuel=Select(Fuel,"HeavyCrudeOil")
  nation=first(Nations)
  for year in Years, worldtom in WorldTOMs
    WPO_WCSe[worldtom,year]=ENPN[fuel,nation,year]*xInflationNation[nation,year]/xExchangeRateNation[nation,year]*5.825
  end

  fuel=Select(Fuel,"LightCrudeOil")
  for year in Years, worldtom in WorldTOMs
    WPO_WTIe[worldtom,year]=ENPN[fuel,nation,year]*xInflationNation[nation,year]/xExchangeRateNation[nation,year]*5.825
  end

  WriteDisk(db,"KOutput/WPO_WCSe",WPO_WCSe)
  WriteDisk(db,"KOutput/WPO_WTIe",WPO_WTIe)

  #
  # Gas Wholesale Prices
  #
  fuel=Select(Fuel,"NaturalGas")
  nation=first(Nations)
  for year in Years, worldtom in WorldTOMs
    WPGasHHe[worldtom,year]=ENPN[fuel,nation,year]*xInflationNation[nation,year]/xExchangeRateNation[nation,year]
  end
  WriteDisk(db,"KOutput/WPGasHHe",WPGasHHe)

  #
  # Coal Wholesale Prices
  #
  # Coal converted to an index with 2005 = 100
  #
  fuel=Select(Fuel,"Coal")
  for year in Years, worldtom in WorldTOMs
    WPCLe[worldtom,year] = ((ENPN[fuel,nation,year]*xInflationNation[nation,year]/xExchangeRateNation[nation,year])/
      (ENPN[fuel,nation,Yr(2005)]*xInflationNation[nation,year]/xExchangeRateNation[nation,year]))*100
  end
  #
  # TODORandy - should the inflation/Exchange for the 2005 price also be 2005 inflation/exchange? - Luke, 25.02.25
  #
  WriteDisk(db,"KOutput/WPCLe",WPCLe)
end

function Control(db)
  @info "E2020WholesalePrices.jl - Control"
  MapWholesalePrices(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
