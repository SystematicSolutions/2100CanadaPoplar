#
# Ind_H2_FeedstocksAP.jl
#

using EnergyModel

module Ind_H2_FeedstocksAP

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FsFracMax::VariableArray{5} = ReadDisk(db,"$Input/FsFracMax") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  FsFracMin::VariableArray{5} = ReadDisk(db,"$Input/FsFracMin") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)

  # Scratch Variables
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Fuel) = data 
  (; Tech,Years) = data
  (; xFsFrac,FsFracMin,FsFracMax) = data
  
  area = Select(Area,"AB") 
  ecs = Select(EC,["Petrochemicals","Petroleum","OilSandsUpgraders"])
  tech = Select(Tech,"Gas") 
     
  xFsFracData =
  #/ Petrochemicals          2024
  # / Petroleum               2024
  # / OilSandsUpgraders       2024
  "Hydrogen                 0.0000 
   NaturalGas               0.0000
   NaturalGasRaw            0.0000
   RNG                      0.0000
   StillGas                 0.0000
   Hydrogen                 0.1993
   NaturalGas               0.7948
   NaturalGasRaw            0.0000
   RNG                      0.0000
   StillGas                 0.0000
   Hydrogen                 0.0111
   NaturalGas               0.9888
   NaturalGasRaw            0.0000
   RNG                      0.0000
   StillGas                 0.0000"
  for row in split(xFsFracData,'\n')
    # Separate the elements in each row
    row_values = strip.(split(row,'\t'))
    row_values = split(row,'\t')
    row_values = [split(value) for value in row_values]
    # Use the elements to select the sets
    f = [string(row_values[1][1])]
    fuel = Select(Fuel,f)
    
    xFsFrac[fuel,tech,ecs,area,Yr(2024)] .= parse.(Float32,row_values[1][2:2])
    years = collect(Yr(2025):Yr(2030))
    for year in years, ec in ecs
      xFsFrac[fuel,tech,ec,area,year] = xFsFrac[fuel,tech,ec,area,Yr(2024)]
    end
    
    years = collect(Yr(2031):Final)
    for year in years, ec in ecs
      xFsFrac[fuel,tech,ec,area,year] .= xFsFrac[fuel,tech,ec,area,year-1]*1.00
    end
    
    FsFracMax[fuel,tech,ecs,area,Years].=xFsFrac[fuel,tech,ecs,area,Years]
    FsFracMin[fuel,tech,ecs,area,Years].=xFsFrac[fuel,tech,ecs,area,Years]
  end
  
  WriteDisk(db,"$Input/FsFracMax",FsFracMax)
  WriteDisk(db,"$Input/FsFracMax",FsFracMax)
  WriteDisk(db,"$Input/xFsFrac",xFsFrac)
end

function PolicyControl(db)
  @info "Ind_H2_FeedstocksAP.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE)==@__FILE__
  PolicyControl(DB)
end

end
