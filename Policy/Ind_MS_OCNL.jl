#
# Ind_MS_OCNL.jl - Energy for NZA
# Net-Zero Accelerator (NZA) Algoma Steel + Arcelor-Mittal reductions are -7.2 Mt
# in 2030 via Natural Gas DRI-EAF (RW 09.24.2021)
# Edited by RST 01Aug2022, re-tuning for Ref22
# Edited by NC 07Sep2023, re-tuning for Ref24

using EnergyModel

module Ind_MS_OCNL

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PIDS::SetArray = ReadDisk(db,"$Input/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input) = data
  (; Area,EC,Enduse,Enduses,Tech) = data 
  (; xMMSF) = data
  
  #
  # Substitution of biomass for natural gas occurs through the
  # provision of process heat used in cement
  #  
  ec = Select(EC,"OtherChemicals")
  area = Select(Area,"NL")
  Electric = Select(Tech,"Electric")
  LPG = Select(Tech,"LPG")

  #
  # Specify values for desired fuel shares (xMMSF)
  #
  years = years = collect(Yr(2024):Yr(2030))
  for year in years, enduse in Enduses
    xMMSF[enduse,Electric,ec,area,year] = 1.00
    xMMSF[enduse,LPG,ec,area,year] = 0.000
  end
  years = collect(Yr(2031):Yr(2050))
  for year in years, enduse in Enduses
    xMMSF[enduse,Electric,ec,area,year] = 0.107
    xMMSF[enduse,LPG,ec,area,year] = 0.883
  end
  WriteDisk(db,"$CalDB/xMMSF",xMMSF)

end

function PolicyControl(db)
  @info "Ind_MS_OCNL.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
