#
# E2020OilGasRevenue.jl
#
using EnergyModel

module E2020OilGasRevenue

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
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Primary Fuel Price ($/mmBtu) 
  GAProd::VariableArray{3} = ReadDisk(db,"SOutput/GAProd") # [Process,Area,Year] Primary Gas Production (TBtu/Yr)
  GYEONominalE::VariableArray{2} = ReadDisk(db,"KOutput/GYEONominalE") # [AreaTOM,Year] Oil and Gas Revenue (M$/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  OAProd::VariableArray{3} = ReadDisk(db,"SOutput/OAProd") # [Process,Area,Year] Primary Oil Production (TBtu/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  GasRevenue::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Gas Revenue ($M/Yr)
  OilRevenue::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Oil Revenue ($M/Yr)
end

# function RevenueOil(data)
#   (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
#   (;NationDS,Nations,Process,ProcessDS,Processs,Year,YearDS,Years) = data
#   (;ENPN,GAProd,GYEONominalE,MapAreaTOM,OAProd,xInflation) = data
#   (;GasRevenue,OilRevenue) = data

# end

# function RevenueGas(data)
#   (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
#   (;NationDS,Nations,Process,ProcessDS,Processs,Year,YearDS,Years) = data
#   (;ENPN,GAProd,GYEONominalE,MapAreaTOM,OAProd,xInflation) = data
#   (;GasRevenue,OilRevenue) = data

# end

# function OGRevenue(data)
#   (;Area,AreaDS,AreaTOM,AreaTOMDS,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
#   (;NationDS,Nations,Process,ProcessDS,Processs,Year,YearDS,Years) = data
#   (;ENPN,GAProd,GYEONominalE,MapAreaTOM,OAProd,xInflation) = data
#   (;GasRevenue,OilRevenue) = data

# end

function OGRevenue(db)
  data = MControl(; db)
  (; Area,AreaDS,AreaTOM,AreaTOMs,Areas,Fuel,FuelDS,Fuels,Nation) = data
  (; NationDS,Nations,Process,ProcessDS,Process,Year,YearDS,Years) = data
  (; ANMap,ENPN,GAProd,GYEONominalE,MapAreaTOM,OAProd,xInflation) = data
  (; GasRevenue,OilRevenue) = data

  CN=Select(Nation,"CN")
  US=Select(Nation,"US")
  nations=Select(Nation,["CN","US"])
  areas_cn=findall(ANMap[:,CN] .== 1)
  areas_us=findall(ANMap[:,US] .== 1)
  areas=union(areas_cn,areas_us)

  #
  ########################
  #
  # Oil revenue is total oil production (TBtu) minus upgraders times the wholesale CrudeOil price (1985 $/mmBtu)
  #
  fuel=Select(Fuel,"LightCrudeOil")
  processes=Select(Process,!=("OilSandsUpgraders"))
  for year in Years, area in areas, nation in nations
    if ANMap[area,nation]==1
      OilRevenue[area,year]=sum(OAProd[process,area,year] for process in processes)*ENPN[fuel,nation,year]*xInflation[area,year]
    end
  end

  #
  ########################
  #
  # Gas revenue is total gas production (TBtu) times the wholesale CrudeOil price (1985 $/mmBtu)
  #
  fuel=Select(Fuel,"NaturalGas")
  processes=Select(Process,["ConventionalGasProduction","UnconventionalGasProduction"])
  for year in Years, area in areas, nation in nations
    if ANMap[area,nation]==1
      GasRevenue[area,year]=sum(GAProd[process,area,year] for process in processes)*ENPN[fuel,nation,year]*xInflation[area,year]
    end
  end

  #
  ########################
  #
  # Total revenue for TOM OilGasExtraction sector is OilRevenue + GasRevenue
  #
  for year in Years, areatom in AreaTOMs
    GYEONominalE[areatom,year]=sum((OilRevenue[area,year]+GasRevenue[area,year])*MapAreaTOM[area,areatom] for area in areas)
  end

  WriteDisk(db,"KOutput/GYEONominalE",GYEONominalE)

end

function Control(db)
  @info "E2020OilGasRevenue.jl - Control"

  OGRevenue(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
