#
# AdjustEnergyDemands.jl - Revised Jeff Amlin 08/22/18
#
using EnergyModel

module AdjustEnergyDemands

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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

  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Years,Area,Tech,Techs,EC,Enduse,Enduses) = data
  (;xDmd) = data
   
  heat = Select(Enduse,"Heat")
  rubber = Select(EC,"Rubber")
  YT = Select(Area,"YT")
  for year in Years, tech in Techs
    xDmd[heat,tech,rubber,YT,year] = 0
  end  

  #*
  #* The following are missing historical driver to match small amounts of 
  #* demand. Zero out demand for now until input is fixes - Ian 08/19/16
  #*
  paper = Select(EC,"PulpPaperMills")
  areas = Select(Area,["PE","YT","NT"])
  for year in Years, area in areas, tech in Techs, enduse in Enduses
    xDmd[enduse,tech,paper,area,year] = 0 
  end
  
  #
  # Added NS IronSteel Biomass for now - Ian 07/09/25
  #
  ironsteel = Select(EC,"IronSteel")
  areas = Select(Area,"NS")
  techs = Select(Tech,"Biomass")
  for year in Years, area in areas, tech in techs, enduse in Enduses
    xDmd[enduse,tech,ironsteel,area,year] = 0 
  end
  
  WriteDisk(db,"$Input/xDmd",xDmd)

end

function CalibrationControl(db)
  @info "AdjustEnergyDemands.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
