#
# Ind_MS_BC_ElecS.jl
#
# Market share values originally from Ind_BC_ElecS.jl - Ian 08/23/21
# Market shares revised for 100% electricity - Jeff Amlin 02/01/22
#

using EnergyModel

module Ind_MS_BC_ElecS

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

  CgPotMult::VariableArray{4} = ReadDisk(db,"$Input/CgPotMult") # [Tech,EC,Area,Year] Cogeneration Potential Multiplier (Btu/Btu)
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input) = data
  (; Area,EC,Enduses) = data
  (; Tech,Techs) = data
  (; CgPotMult,xMMSF) = data

  #
  # Specify values for desired fuel shares (xMMSF)
  # 
  BC = Select(Area,"BC");
  OtherMetalMining = Select(EC,"OtherMetalMining");
  years = collect(Yr(2024):Final);
  for year in years, enduse in Enduses, tech in Techs
    xMMSF[enduse,tech,OtherMetalMining,BC,year] = 0.0
  end
  
  Electric = Select(Tech,"Electric");
  for year in years, enduse in Enduses
    xMMSF[enduse,Electric,OtherMetalMining,BC,year] = 1.0
  end

  WriteDisk(db,"$CalDB/xMMSF",xMMSF);
  
  for year in years, tech in Techs
    CgPotMult[tech,OtherMetalMining,BC,year] = 1.0
  end
  
  WriteDisk(db,"$Input/CgPotMult",CgPotMult);
end

function PolicyControl(db)
  @info "Ind_MS_BC_ElecS.jl - PolicyControl";
  IndPolicy(db);
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
