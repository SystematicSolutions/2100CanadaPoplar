#
# Trans_MS_OGV_CA.jl - 25% of OGVs utilize hydrogen fuel cell
# electric technology by 2045
#

using EnergyModel

module Trans_MS_OGV_CA

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
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
  MSFPVBase::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Sum of Personal Vehicle Market Shares in Base
end

function TransPolicy(db)
  data = TControl(; db)
  (; CalDB) = data
  (; Area,EC) = data
  (; Tech) = data
  (; xMMSF) = data
  (; MSFPVBase) = data

  CA = Select(Area,"CA")

  #
  ########################
  #
  # Foreign Freight
  #
  ec = Select(EC,"ForeignFreight")

  years = collect(Yr(2030):Final)
  
  techs = Select(Tech,["MarineHeavy","MarineLight","MarineFuelCell"])
  for year in years
    MSFPVBase[CA,year] = sum(xMMSF[1,tech,ec,CA,year] for tech in techs)
  end

  tech = Select(Tech,"MarineFuelCell")
  for year in years
    xMMSF[1,tech,ec,CA,year] = MSFPVBase[CA,year]*0.25
  end

  techs = Select(Tech,["MarineHeavy","MarineLight"])
  for year in years, tech in techs
    xMMSF[1,tech,ec,CA,year] = MSFPVBase[CA,year]*(1-0.25)
  end

  #
  # Interpolate from 2021
  # 
  techs = Select(Tech,["MarineHeavy","MarineLight","MarineFuelCell"])
  years = collect(Yr(2022):Yr(2029))

  for year in years, ec in ecs, tech in techs
    xMMSF[1,tech,ec,CA,year] = xMMSF[1,tech,ec,CA,year-1]+
      (xMMSF[1,tech,ec,CA,Yr(2030)]-xMMSF[1,tech,ec,CA,Yr(2021)])/(2030-2021)
  end

  WriteDisk(db,"$CalDB/xMMSF",xMMSF);
end

function PolicyControl(db)
  @info "Trans_MS_OGV_CA.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
