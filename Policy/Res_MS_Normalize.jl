#
# Res_MS_Normalize.jl 
#

using EnergyModel

module Res_MS_Normalize

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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
  
  #
  # Scratch Variables
  #
  
  xMMSFTotal::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Total Market Share Fraction (Driver/Driver)
end

function ResPolicy(db)
  data = RControl(; db)
  (; CalDB) = data
  (; Areas,ECs,Enduses) = data
  (; Techs) = data
  (; xMMSF,xMMSFTotal) = data

  years = collect(Future:Final)

  for area in Areas, ec in ECs, enduse in Enduses, year in years
    xMMSFTotal[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in Techs)
  end
  
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses, year in years
    @finite_math xMMSF[enduse,tech,ec,area,year] = xMMSF[enduse,tech,ec,area,year]/
      xMMSFTotal[enduse,ec,area,year]
  end
  
  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

function PolicyControl(db)
  @info "Res_MS_Normalize.jl - PolicyControl"
  ResPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end



