#
# WholesalePrices_VB.jl
# This file reads in vENPN developed by Environment Canada
#
using EnergyModel

module WholesalePrices_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (Real $/mmBtu)
  vENPN::VariableArray{3} = ReadDisk(db,"VBInput/vENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (Real $/mmBtu)

end

function WholesalePrices(db)
  data = SControl(; db)
  (;Fuels,Nation,Years) = data
  (;xENPN,vENPN) = data

  CN = Select(Nation,"CN")
  for fuel in Fuels, year in Years 
    xENPN[fuel,CN,year] = vENPN[fuel,CN,year]
  end
  WriteDisk(db,"SInput/xENPN",xENPN)
end

function Control(db)
  @info "WholesalePrices_VB.jl - Control"
  WholesalePrices(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
