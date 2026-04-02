#
# Res_MS_HEES_BC_GasProhibition.jl - based on 'EL_Bldg_HPs.txp' - Policy Targets for FuelShares - Jeff Amlin 5/10/16
#
# This policy simulates the prohibition of fossil fuel heating as part of the the Highest Efficiency Equipment Standards 
# for Space and Water Heating (HEES) in BC.
# The prohibition is implemented into software code by setting to zero the Marginal Market Share Fraction MMSF of the
# Space heater technolgie "Gas". 
# Last updated by Yang Li on 2024-10-11
#
using EnergyModel

module Res_MS_HEES_BC_GasProhibition

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
  
  MMSFBase::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/MMSF") # Market Share Fraction from Base Case ($/$) [Enduse,Tech,EC,Area]
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
end

function PolicyControl(db)
  @info "Res_MS_HEES_BC_GasProhibition - PolicyControl"
  data = RControl(; db)
  (; CalDB) = data
  (; Area,ECs,Enduse,Enduses,Tech,Years) = data
  (; xMMSF) = data
  
  #
  # Specify values for desired fuel shares (XMMSF)
  #
  years = collect(Yr(2030):Final)
  BC = Select(Area,"BC")
  enduses = Select(Enduse,["Heat","HW"])

  #
  # Assign emitting fuel shares to heat pumps
  #
  heatpump = Select(Tech,"HeatPump")
  techs = Select(Tech,["HeatPump","Gas"])
  for year in years, ec in ECs, enduse in enduses
    xMMSF[enduse,heatpump,ec,BC,year] = sum(xMMSF[enduse,tech,ec,BC,year] for tech in techs)
  end

  #
  # Assign 0 market share to all emitting Techs
  #
  gas = Select(Tech,"Gas")
  for year in years, ec in ECs, enduse in enduses
    xMMSF[enduse,gas,ec,BC,year] = 0.0
  end

  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

if abspath(PROGRAM_FILE) == @__FILE__
     PolicyControl(DB)
end  
  
end



