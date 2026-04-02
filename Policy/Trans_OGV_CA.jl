#
# Trans_OGV_CA.jl - 25% of OGVs utilize hydrogen fuel cell
# electric technology by 2045
#

using EnergyModel

module Trans_OGV_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
end

function TransPolicy(db)
  data = TControl(; db)
  (; Input) = data
  (; Area,EC) = data
  (; Fuel) = data
  (; Tech) = data
  (; DmFracMin,xDmFrac) = data

  CA = Select(Area,"CA")

  #
  ########################
  #
  # Foreign Freight
  #
  ecs = Select(EC,"ForeignFreight")
  techs = Select(Tech,(from = "MarineHeavy",to = "MarineLight"))
  years = collect(Yr(2045):Final)
  fuel = Select(Fuel,"Hydrogen")
  for year in years, ec in ecs, tech in techs
    DmFracMin[1,fuel,tech,ec,CA,year] = 0.25
  end
  
  #
  # Add some Electric demand (5%?) to simulate shore power reg
  # 
  fuel = Select(Fuel,"Electric")
  for year in years, ec in ecs, tech in techs
    DmFracMin[1,fuel,tech,ec,CA,year] = 0.05
  end

  #
  # Interpolate from 2021
  #  
  fuels = Select(Fuel,["Hydrogen","Electric"])
  years = collect(Yr(2022):Yr(2044))
  for year in years, ec in ecs, tech in techs, fuel in fuels
    DmFracMin[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year-1]+
    (DmFracMin[1,fuel,tech,ec,CA,Yr(2045)]-DmFracMin[1,fuel,tech,ec,CA,Yr(2021)])/
      (2045-2021)
  end
  
  years = collect(Yr(2022):Final)
  for year in years, ec in ecs, tech in techs, fuel in fuels
    xDmFrac[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year]
  end

  WriteDisk(db,"$Input/DmFracMin",DmFracMin);
end

function PolicyControl(db)
  @info "Trans_OGV_CA.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
