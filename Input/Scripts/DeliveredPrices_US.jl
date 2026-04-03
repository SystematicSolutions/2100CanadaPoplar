#
# DeliveredPrices_US.jl
#
using EnergyModel

module DeliveredPrices_US

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
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
  FPSMF::VariableArray{4} = ReadDisk(db,"SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db,"SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function TaxesForPrices(db)
  data = SControl(; db)
  (;ES,ESs,Fuel,Fuels,Nation) = data
  (;Years) = data
  (;ANMap,FPSMF,FPTaxF,xInflation) = data
  
  # 
  # US taxes - Estimated at 18.4 federal and 30.0 cents/gal state and local 
  # http://www.gaspricewatch.com/usgastaxes.asp
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)

  Gasoline = Select(Fuel,"Gasoline")
  for es in ESs, area in areas
    FPTaxF[Gasoline,es,area,Yr(2008)] = (18.4+30.0)/125000*1e6/100
  end
  
  Diesel = Select(Fuel,"Diesel")
  for es in ESs, area in areas
    FPTaxF[Diesel,es,area,Yr(2008)] = (18.4+30.0)/139000*1e6/100
  end
  
  fuels = Select(Fuel,["Gasoline","Diesel"])
  for fuel in fuels, es in ESs, area in areas, year in Years
    FPTaxF[fuel,es,area,year] = FPTaxF[fuel,es,area,Yr(2008)]/xInflation[area,year]
  end
  
  WriteDisk(db,"SInput/FPTaxF",FPTaxF)
  
  # 
  # US Sales Tax
  # Estimated at 7.00% by Jeff Amlin 5/31/10 from
  # http://www.thestc.com/STrates.stm
  # 
  for fuel in Fuels, es in ESs, area in areas, year in Years
    FPSMF[fuel,es,area,year] = 0.070
  end
  #
  # Exclude Electric Utility Fuel Prices from US Sales Tax
  #
  Electric = Select(ES,"Electric")
  for fuel in Fuels, area in areas, year in Years
    FPSMF[fuel,Electric,area,year] = 0.070
  end
  WriteDisk(db,"SInput/FPSMF",FPSMF)
end

function Control(db)
  @info "DeliveredPrices_US.jl - Control"
  TaxesForPrices(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
