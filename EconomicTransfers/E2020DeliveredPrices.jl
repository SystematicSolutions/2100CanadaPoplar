#
# E2020DeliveredPrices.jl
#
using EnergyModel

module E2020DeliveredPrices

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
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PriceTOM::SetArray = ReadDisk(db,"KInput/PriceTOMKey")
  PriceTOMs::Vector{Int} = collect(Select(PriceTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Price Normal ($/mmBtu) 
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  FPPolTaxF::VariableArray{4} = ReadDisk(db,"SOutput/FPPolTaxF") # [Fuel,ES,Area,Year] Pollution Tax (Real $/mmBtu)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapPriceTOM::VariableArray{3} = ReadDisk(db,"KInput/MapPriceTOM") #[Fuel,ES,PriceTOM] Map from ES and Fuel to PriceTOM
  Pe::VariableArray{3} = ReadDisk(db,"KOutput/Pe") # [PriceTOM,AreaTOM,Year] E2020toTOM Delivered Prices ($/mmBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  ENPNArea::VariableArray{3} = zeros(Float32,length(Fuel),length(Area),length(Year)) # [Fuel,Area,Year] Price Normal by Area and Prices ($/mmBtu)
  FPNoPolTax::VariableArray{4} = zeros(Float32,length(Fuel),length(ES),length(Area),length(Year)) # [Fuel,ES,Area,Year] Fuel Prices ($/mmBtu)
end

function DeliveredPrices(data)
  (; db) = data
  (; ANMap,Areas,AreaTOMs,ESs,Fuels,Nations,PriceTOMs,Years) = data
  (; ENPNArea,ENPN,FPNoPolTax,FPF,FPPolTaxF) = data
  (; MapAreaTOM,MapPriceTOM,xInflation,Pe) = data

  @. FPNoPolTax = FPF-FPPolTaxF
  
  for year in Years, area in Areas, fuel in Fuels
    ENPNArea[fuel,area,year] = sum(ENPN[fuel,nation,year]*ANMap[area,nation] for nation in Nations)
  end
  for year in Years, area in Areas, es in ESs, fuel in Fuels
    FPNoPolTax[fuel,es,area,year] = 
      max(FPNoPolTax[fuel,es,area,year],ENPNArea[fuel,area,year]*xInflation[area,year]*0.25)
  end

  for year in Years, areatom in AreaTOMs, pricetom in PriceTOMs
    Pe[pricetom,areatom,year] = sum(FPNoPolTax[fuel,es,area,year]*MapPriceTOM[fuel,es,pricetom]*
      MapAreaTOM[area,areatom] for area in Areas, es in ESs, fuel in Fuels)
  end  

  WriteDisk(db,"KOutput/Pe",Pe)

end

function Control(db)
  data = MControl(; db)
  @info "E2020DeliveredPrices.jl - Control"

  DeliveredPrices(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
