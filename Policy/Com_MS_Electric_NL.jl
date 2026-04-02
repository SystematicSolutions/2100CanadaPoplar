#
# Com_MS_Electric_NL.jl - MS file constructed from ElectricMarketShare_NL.jl
# 
# Ian 08/23/21
#

using EnergyModel

module Com_MS_Electric_NL

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
end

function ComPolicy(db)
  data = CControl(; db)
  (; CalDB) = data
  (; Area,EC,Enduses) = data 
  (; Tech) = data
  (; xMMSF) = data

  NL = Select(Area,"NL")
  years = collect(Future:Final)
  ecs = Select(EC,["Wholesale","Retail","Warehouse","Information","Offices","Education","Health","OtherCommercial"])
  techs = Select(Tech,["Gas","Coal","Oil","Biomass","LPG","Steam"])
  for year in years, ec in ecs, tech in techs, enduse in Enduses
    xMMSF[enduse,tech,ec,NL,year] = 0.0
  end
  
  for year in years, ec in ecs, enduse in Enduses
  Electric = Select(Tech,"Electric")
    xMMSF[enduse,Electric,ec,NL,year] = 1.0
  end

  WriteDisk(db,"$CalDB/xMMSF",xMMSF)
end

function PolicyControl(db)
  @info "Com_MS_Electric_NL - PolicyControl"
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
