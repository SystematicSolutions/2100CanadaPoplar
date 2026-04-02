#
# Res_MS_Incentive_Opt1.jl
#

using EnergyModel

module Res_MS_Incentive_Opt1

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
end

function ResPolicy(db)
  data = RControl(; db)
  (; CalDB) = data
  (; Area,ECs,Enduse) = data 
  (; Tech) = data
  (; xMMSF) = data

  #
  # Territories are excluded
  # 
  areas = Select(Area,(from="ON", to="PE"))
  techs = Select(Enduse,["Heat","AC"])
  HeatPump = Select(Tech,"HeatPump")

  #
  # Apply a subsidy of reference forecast value
  #
  years = collect(Yr(2026):Yr(2027))
  for year in years, area in areas, ec in ECs, tech in techs
    xMMSF[tech,HeatPump,ec,area,year] = xMMSF[tech,HeatPump,ec,area,year] + 0.019
  end

  years = collect(Yr(2028):Yr(2029))
  for year in years, area in areas, ec in ECs, tech in techs
    xMMSF[tech,HeatPump,ec,area,year] = xMMSF[tech,HeatPump,ec,area,year] + 0.033
  end

  years = collect(Yr(2030):Final)
  for year in years, area in areas, ec in ECs, tech in techs
    xMMSF[tech,HeatPump,ec,area,year] = xMMSF[tech,HeatPump,ec,area,year] + 0.045
  end

  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

function PolicyControl(db)
  @info "Res_MS_Incentive_Opt1 - PolicyControl"
  ResPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
