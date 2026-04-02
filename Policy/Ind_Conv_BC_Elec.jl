#
# Ind_Conv_BC_Elec.jl
#

using EnergyModel

module Ind_Conv_BC_Elec

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

  CFraction::VariableArray{5} = ReadDisk(db,"$Input/CFraction") # [Enduse,Tech,EC,Area,Year] Fraction of Production Capacity open to Conversion ($/$)
  CnvrtEU::VariableArray{4} = ReadDisk(db,"$Input/CnvrtEU") # Conversion Switch [Enduse,EC,Area]
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Enduse,Enduses,Tech,Techs) = data
  (; CFraction,CnvrtEU) = data
  (; Endogenous) = data

  area = Select(Area,"BC")
  ec = Select(EC,"OtherMetalMining")
  years = collect(Future:Final)
  
  for year in years, enduse in Enduses
    CnvrtEU[enduse,ec,area,year] = Endogenous
  end  
  WriteDisk(db,"$Input/CnvrtEU",CnvrtEU)
  
  techs = Select(Tech,["Gas","Coal","Oil","LPG"])
  for year in years, tech in techs, enduse in Enduses
    CFraction[enduse,tech,ec,area,year] = 1.0
  end
  WriteDisk(db,"$Input/CFraction",CFraction)

end

function PolicyControl(db)
  @info "Ind_Conv_BC_Elec.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
