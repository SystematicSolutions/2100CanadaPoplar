#
# EIP_CCS_2_RefA.jl - Carbon Sequestration Price Signal -
# 0.4 MT in Emissions sequestering from EIP Programs
# Gavin Cook - This policy requires a duplicate for RefA, to target the correct exogenous CCS reductions for the Ref25A scenario.
#

using EnergyModel

module EIP_CCS_2_RefA

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
  ecc = Select(ECC,"HeavyOilMining")
  years = collect(Yr(2023):Final) 
  for year in years
   xSqPrice[ecc,area,year] = 136.3/xInflation[area,Yr(2020)]
  end

  WriteDisk(db,"MEInput/xSqPrice",xSqPrice)
end

function PolicyControl(db)
  @info "EIP_CCS_2_RefA.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
