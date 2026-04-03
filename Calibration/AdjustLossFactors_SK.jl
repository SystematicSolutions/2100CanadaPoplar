#
# AdjustLossFactors_SK.jl
# 
# Copy to 2020Model
# Add to RunModel.jl immediately after "Call PrmFile ElectricLossFactors.jl"
#
using EnergyModel

module AdjustLossFactors_SK

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  TDEF::VariableArray{3} = ReadDisk(db,"SInput/TDEF") # [Fuel,Area,Year] T&D Efficiency (MW/MW)

end

function LossFactors(db)
  data = SControl(; db)
  (;Area,Fuel) = data
  (;TDEF) = data

  area = Select(Area,"SK")
  fuel = Select(Fuel,"Electric")
  years = collect(Yr(2016):Yr(2035))

  TDEF[fuel,area,years] = [
  #/2016  2017  2018  2019  2020  2021  2022  2023  2024  2025  2026  2027  2028  2029  2030  2031  2032  2033  2034  2035
   0.079 0.078 0.078 0.079 0.079 0.080 0.080 0.079 0.078 0.077 0.077 0.078 0.078 0.078 0.077 0.077 0.077 0.077 0.077 0.076
  ]
  
  for year in years
    TDEF[fuel,area,year] = 1 - TDEF[fuel,area,year]
  end
  
  years = collect(Yr(2016):Yr(2019))
  for year in years 
    TDEF[fuel,area,year] = TDEF[fuel,area,year-1] + (TDEF[fuel,area,Yr(2020)] - 
                           TDEF[fuel,area,Yr(2015)]) / (2020-2015)
  end
  
  years = collect(Yr(2036):Yr(2050))
  for year in years 
    TDEF[fuel,area,year] = TDEF[fuel,area,Yr(2035)]
  end

  WriteDisk(db,"SInput/TDEF",TDEF)

end

function Control(db)
  @info "AdjustLossFactors_SK.jl - Control"
  LossFactors(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
