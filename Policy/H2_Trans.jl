#
# H2_Trans.jl - Hydrogen Supply Policy
#

using EnergyModel

module H2_Trans

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Last,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  H2Tech::SetArray = ReadDisk(db,"MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db,"MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))  
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))


  ENPNSw::VariableArray{3} = ReadDisk(db,"SInput/ENPNSw") # [Fuel,Nation,Year] Wholesale Price Switch (1=Endogenous)
  H2Trans::VariableArray{3} = ReadDisk(db,"SpInput/H2Trans") # [H2Tech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/mmBtu)

end

function SupplyPolicy(db)
  data = SControl(; db)
  (; Area,Areas,Fuel,H2Tech,H2Techs,Nation,Years) = data
  (; ENPNSw,H2Trans) = data

  #
  # Price Switch for Hydrogen 
  #
  fuel = Select(Fuel,"Hydrogen")  
  nation = Select(Nation,"CN")
  years = collect(Yr(2020):Yr(2050))
  for year in years  
    ENPNSw[fuel,nation,year] = 1
  end
  WriteDisk(db,"SInput/ENPNSw",ENPNSw)
  
  #
  # Transportation Costs for Hydrogen 
  #
  for year in years, area in Areas, h2tech in H2Techs
    H2Trans[h2tech,area,year] = 10.0
  end
  WriteDisk(db,"SpInput/H2Trans",H2Trans)

end

function PolicyControl(db)
  @info "H2_Trans.jl - PolicyControl"
  SupplyPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
