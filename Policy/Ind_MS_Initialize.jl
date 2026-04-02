#
# Ind_MS_Initialize.jl 
#

using EnergyModel

module Ind_MS_Initialize

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
  OGRefNameDB::String = ReadDisk(db,"MainDB/OGRefNameDB") #  Oil/Gas Reference Case Name

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

  MMSFBase::VariableArray{5} = ReadDisk(OGRefNameDB,"$Outpt/MMSF") # Market Share Fraction from Base Case ($/$) [Enduse,Tech,EC,Area]
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)

  # Scratch Variables
end

function IndPolicy(db)
  data = IControl(; db)
end

function PolicyControl(db)
  @info "Ind_MS_Initialize - PolicyControl"
  data = IControl(; db)
  (; CalDB) = data
  (; Areas,ECs,Enduses,MMSFBase,Techs) = data
  (; xMMSF) = data
  
  years = collect(Future:Final);
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xMMSF[enduse,tech,ec,area,year] = MMSFBase[enduse,tech,ec,area,year]
  end
  
  WriteDisk(db,"$CalDB/xMMSF",xMMSF);
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
