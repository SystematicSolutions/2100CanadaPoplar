#
# Com_MS_Initialize.jl 
#

using EnergyModel

module Com_MS_Initialize

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
    
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
  MMSFBase::VariableArray{5} = ReadDisk(OGRefNameDB,"$Outpt/MMSF") # Market Share Fraction from Base Case ($/$) [Enduse,Tech,EC,Area]
end

function PolicyControl(db)
  @info "Com_MS_Initialize - PolicyControl"
  data = CControl(; db)
  (; CalDB) = data
  (; Areas,ECs,Enduses,Techs,Years) = data
  (; MMSFBase,xMMSF) = data
  
  Years = collect(Future:Final)
  
  for year in Years, enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    xMMSF[enduse,tech,ec,area,year] = MMSFBase[enduse,tech,ec,area,year]
  end
  
  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end
  
end



