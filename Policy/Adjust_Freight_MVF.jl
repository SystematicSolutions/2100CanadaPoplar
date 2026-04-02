#
# Adjust_Freight_MVF.jl
# Reduce MVF (market variance factor) heterogenously across
# PTs to acheive reasonable freight market shares over time
# Reducing MVF will dampen the price response in the freight sector
# and reduce uptake of rail and marine
#

using EnergyModel

module Adjust_Freight_MVF

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
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)

end

function TransPolicy(db)
  data = TControl(; db)
  (; CalDB) = data
  (; Area,EC,Enduses,Techs) = data 
  (; MVF) = data

  Freight = Select(EC,"Freight")
  years = collect(Future:Final)
  
  areas = Select(Area,["AB","SK","QC"])
  for enduse in Enduses, tech in Techs, area in areas, year in years
    MVF[enduse,tech,Freight,area,year] = -1.0
  end
  
  areas = Select(Area,"ON")
  for enduse in Enduses, tech in Techs, area in areas, year in years
    MVF[enduse,tech,Freight,area,year] = -0.5
  end
  
  areas = Select(Area,"NB")
  for enduse in Enduses, tech in Techs, area in areas, year in years 
    MVF[enduse,tech,Freight,area,year] = -1.5
  end
  
  areas = Select(Area,["MB","PE"])
  for enduse in Enduses, tech in Techs, area in areas, year in years
    MVF[enduse,tech,Freight,area,year] = -0.75
  end
  
  areas = Select(Area,["NS","YT"])
  for enduse in Enduses, tech in Techs, area in areas, year in years
    MVF[enduse,tech,Freight,area,year] = -1.75
  end
  
  areas = Select(Area,["NL","NU"])
  for enduse in Enduses, tech in Techs, area in areas, year in years
    MVF[enduse,tech,Freight,area,year] = -2.0
  end
  
  areas = Select(Area,["NT","BC"])
  for enduse in Enduses, tech in Techs, area in areas, year in years
    MVF[enduse,tech,Freight,area,year] = -1.25
  end
  
  WriteDisk(db,"$CalDB/MVF",MVF)
end

function PolicyControl(db)
  @info "Adjust_Freight_MVF.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
