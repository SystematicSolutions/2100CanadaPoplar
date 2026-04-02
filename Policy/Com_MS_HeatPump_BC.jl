#
# Com_MS_HeatPump_BC.jl - MS based on 'ResCom_HeatPump_BC.jl'
#
# Ian 08/23/21
#
# This policy simulates the the BC heat pump incentive which is part of the CleanBC plan.
# Details about the underlying assumptions for this policy are available in the following file:
# \\ncr.int.ec.gc.ca\shares\e\ECOMOD\Documentation\Policy - Buildings Policies.docx.
# (A. Dumas 2020/06/25).
# Last updated by Yang Li on 2025-06-06
#

using EnergyModel

module Com_MS_HeatPump_BC

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"

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

function ComPolicy()
  data = CControl(db=DB)
  (; CalDB) = data
  (; Area,ECs,Enduse) = data
  (; Tech) = data
  (; xMMSF) = data

  #
  # specify values for desired fuel shares (xMMSF)
  #  
  BC = Select(Area,"BC")  
  years = collect(Yr(2024):Yr(2030)) 
  
  #
  # Roughly 10% of new furnaces will be HeatPump,replacing Gas
  #  
  Heat = Select(Enduse,"Heat")
  HeatPump = Select(Tech,"HeatPump")
  Gas = Select(Tech,"Gas")
  for ec in ECs, year in years
    xMMSF[Heat,HeatPump,ec,BC,year] = 0.1
    xMMSF[Heat,Gas,ec,BC,year] = max(xMMSF[Heat,Gas,ec,BC,year]-0.1,0.0)
  end

  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

function PolicyControl(db)
  @info "Com_MS_HeatPump_BC - PolicyControl"
  ComPolicy()
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
