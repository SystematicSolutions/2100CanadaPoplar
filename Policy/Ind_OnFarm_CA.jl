#
# Ind_OnFarm_CA.jl - On Farm Fuel Use: 25% energy demand
# electrified by 2030 and 75% by 2045
#

using EnergyModel

module Ind_OnFarm_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Enduse) = data
  (; Fuel) = data
  (; Tech) = data
  (; DmFracMin,xDmFrac) = data

  CA = Select(Area,"CA")

  #
  ########################
  #
  # On Farm Fuel Use
  #
  ec = Select(EC,"OnFarmFuelUse")

  enduses = Select(Enduse,["Heat","OthSub"])
  techs = Select(Tech,["Gas","Coal","Oil","Biomass","OffRoad"])

  Electric = Select(Fuel,"Electric")
  for tech in techs, enduse in enduses
    DmFracMin[enduse,Electric,tech,ec,CA,Yr(2030)] = 
      max(DmFracMin[enduse,Electric,tech,ec,CA,Yr(2030)],0.25)
  end

  years = collect(Yr(2045):Final)
  for year in years, tech in techs, enduse in enduses
    DmFracMin[enduse,Electric,tech,ec,CA,year] = 
      max(DmFracMin[enduse,Electric,tech,ec,CA,year],0.75)
  end

  #
  # Interpolate from 2021
  #  
  years = collect(Yr(2022):Yr(2029))
  for year in years, tech in techs, enduse in enduses
    DmFracMin[enduse,Electric,tech,ec,CA,year] = 
      DmFracMin[enduse,Electric,tech,ec,CA,year-1]+
      (DmFracMin[enduse,Electric,tech,ec,CA,Yr(2030)]-
      DmFracMin[enduse,Electric,tech,ec,CA,Yr(2021)])/
      (2030-2021)
  end

  years = collect(Yr(2031):Yr(2044))
  for year in years, tech in techs, enduse in enduses
    DmFracMin[enduse,Electric,tech,ec,CA,year] = 
      DmFracMin[enduse,Electric,tech,ec,CA,year-1]+
      (DmFracMin[enduse,Electric,tech,ec,CA,Yr(2045)]-
      DmFracMin[enduse,Electric,tech,ec,CA,Yr(2030)])/
      (2045-2030)
  end

  years = collect(Yr(2022):Final)
  for year in years, tech in techs, enduse in enduses
    xDmFrac[enduse,Electric,tech,ec,CA,year] = 
      DmFracMin[enduse,Electric,tech,ec,CA,year]
  end

  WriteDisk(db,"$Input/DmFracMin",DmFracMin);
end

function PolicyControl(db)
  @info "Ind_OnFarm_CA.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
