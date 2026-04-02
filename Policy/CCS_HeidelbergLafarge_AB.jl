#
# CCS_HeidelbergLafarge_AB.jl -  Carbon Sequestration Price Signal
# 
# Exogenous CCS reductions from CCS facility (Lehigh/Heidelberg facility in Edmonton AB)
# Projecting the Exshaw facility from Lafarge to come on line in 2029
#

using EnergyModel

module CCS_HeidelbergLafarge_AB

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

  ecc = Select(ECC,"Cement")
  area = Select(Area,"AB")

  xSqPrice[ecc,area,Yr(2022)] = 120.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2023)] = 123.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2024)] = 124.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2025)] = 124.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2026)] = 125.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2027)] = 125.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2028)] = 126.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2029)] = 126.0/xInflation[area,Yr(2016)]
  xSqPrice[ecc,area,Yr(2030)] = 127.0/xInflation[area,Yr(2016)]

  years = collect(Yr(2031):Final)
  for year in years
    xSqPrice[ecc,area,year] = 127.0/xInflation[area,Yr(2016)]
  end
  WriteDisk(db,"MEInput/xSqPrice",xSqPrice)
  
end

function PolicyControl(db)
  @info "CCS_HeidelbergLafarge_AB.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
