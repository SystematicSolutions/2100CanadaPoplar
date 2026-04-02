#
# Res_MS_NewElectric_CA.jl
#
# New residential and commercial buildings: All electric appliances
# beginning 2026 (residential) and 2029 (commercial)
#

using EnergyModel

module Res_MS_NewElectric_CA

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
  MSFPVBase::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Sum of Personal Vehicle Market Shares in Base
end

function ResPolicy(db)
  data = RControl(; db)
  (; CalDB) = data
  (; Area,ECs,Enduse) = data 
  (; Tech,Techs) = data
  (; xMMSF) = data

  CA = Select(Area,"CA")

  #
  # Space Heat - Assume switch to Heat Pump
  # 
  Heat = Select(Enduse,"Heat")
  
  years = collect(Yr(2026):Final)
  HeatPump = Select(Tech,"HeatPump")
  for year in years, ec in ECs
    xMMSF[Heat,HeatPump,ec,CA,year] = 1.0
  end

  techs = Select(Tech,!=("HeatPump"))
  for year in years, ec in ECs, tech in techs
    xMMSF[Heat,tech,ec,CA,year] = 0.0
  end

  #
  # Interpolate from 2021
  #  
  years = collect(Yr(2022):Yr(2025))

  for tech in Techs, ec in ECs, year in years
    @finite_math xMMSF[Heat,tech,ec,CA,year] = xMMSF[Heat,tech,ec,CA,year-1] +
    ((xMMSF[Heat,tech,ec,CA,Yr(2026)] - xMMSF[Heat,tech,ec,CA,Yr(2021)]) / (2026-2021))
  end

  #
  # Water Heat and OthSub switch to Electric
  #  
  enduses = Select(Enduse,["HW","OthSub"])
  years = collect(Yr(2026):Final)
  Electric = Select(Tech,"Electric")
  for year in years, ec in ECs, enduse in enduses
    xMMSF[enduse,Electric,ec,CA,year] = 1.0
  end

  techs = Select(Tech,!=("Electric"))
  for year in years, ec in ECs, enduse in enduses, tech in techs
    xMMSF[enduse,tech,ec,CA,year] = 0.0
  end

  #
  # Interpolate from 2021
  #  
  years = collect(Yr(2022):Yr(2025))

  for tech in Techs, ec in ECs, year in years, enduse in enduses
    @finite_math xMMSF[enduse,tech,ec,CA,year] = xMMSF[enduse,tech,ec,CA,year-1] +
      ((xMMSF[enduse,tech,ec,CA,Yr(2026)] - 
        xMMSF[enduse,tech,ec,CA,Yr(2021)]) / (2026-2021))
  end

  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

function PolicyControl(db)
  @info "Res_MS_NewElectric_CA - PolicyControl"
  ResPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
