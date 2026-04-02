#
# H2_Prices.jl - Hydrogen Endogenous Price Policy
#

using EnergyModel

module H2_Prices

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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

end

function SupplyPolicy(db)
  data = SControl(; db)
  (; Area,Areas,Fuel,H2Tech,H2Techs,Nation,Years) = data
  (; ENPNSw) = data

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

end

function PolicyControl(db)
  @info "H2_Prices.jl - PolicyControl"
  SupplyPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
