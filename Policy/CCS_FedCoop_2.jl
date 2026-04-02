#
# CCS_FedCoop_2.jl - Carbon Sequestration Price Signal -
# Exogenous CCS reductions from FedCoop CCS plant; 400 kt in Refinery, 75 kt in OtherChem
#

using EnergyModel

module CCS_FedCoop_2

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xSqPrice::VariableArray{3} = ReadDisk(db,"MEInput/xSqPrice") # [ECC,Area,Year] Exogenous Sequestering Cost Curve Price ($/tonne CO2e)

end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC) = data
  (; xInflation,xSqPrice) = data
  
  area = Select(Area,"SK")     
  ecc = Select(ECC,"OtherChemicals")
  year = Yr(2024) 
  xSqPrice[ecc,area,year] = 158.92/xInflation[area,Yr(2020)]  
  years = collect(Yr(2025):Final) 
  for year in years
   xSqPrice[ecc,area,year] = 121.10/xInflation[area,Yr(2020)]
  end

  WriteDisk(db,"MEInput/xSqPrice",xSqPrice)
end

function PolicyControl(db)
  @info "CCS_FedCoop_2.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
