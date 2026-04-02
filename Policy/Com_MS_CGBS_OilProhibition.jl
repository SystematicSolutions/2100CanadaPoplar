#
# Com_CGBS_FossilFuelHeatingProhibition.jl - based on 'EL_Bldg_HPs.txp' - Policy Targets for FuelShares - Jeff Amlin 5/10/16
#
# This policy simulates the prohibition of fossil fuel heating as part of the Buildings Sector Strategy.
# The prohibition is implemented into software code by setting to zero the Marginal Market Share Fraction MMSF of the
# Space heater technolgies "Coal", "Gas", "LPG", and "Oil" . Only provinces are affects; territories are exempt.
# Last updated by Kevin Palmer-Wilson on 2023-03-22
#
using EnergyModel

module Com_MS_CGBS_OilProhibition

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
  
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
end

function PolicyControl(db)
  @info "Com_MS_CGBS_OilProhibition - PolicyControl"
  data = CControl(; db)
  (; CalDB,Outpt) = data
  (; Area,EC,ECs,Enduse,Tech,Years) = data
  (; DPL,xMMSF) = data
  
  years = collect(Yr(2028):Final)
  areas = Select(Area,["AB","BC","MB","ON","QC","SK","NS","NL","NB","PE"])
  enduses = Select(Enduse,["Heat","HW"])
  ecs = Select(EC,(from="Wholesale",to="OtherCommercial"))

  #
  # Assign emitting fuel shares to heat pumps
  #
  heatpump = Select(Tech,"HeatPump")
  techs = Select(Tech,["HeatPump","Oil"])
  for year in years, area in areas, ec in ecs, enduse in enduses
    xMMSF[enduse,heatpump,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
  end

  #
  # Assign 0 market share to all emitting Techs
  #
  oil = Select(Tech,"Oil")
  for year in years, area in areas, ec in ecs, enduse in enduses
    xMMSF[enduse,oil,ec,area,year] = 0.0
  end

  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
  
  #   
  # From the old ResCom_HEES_BC_Conversions.jl, revising the device 
  # lifetime faciliates the prohibition of replacing fossil fuel heaters
  # at the end of their devince lifetime(conversions) as part of the Canada
  # Green Buildings Strategy.
  #
  # 5 - Use 20+5 for Commerical lifespan
  #
  BC = Select(Area,"BC")  
  enduses=Select(Enduse,["Heat","HW"])
  techs=Select(Tech,["Oil","Gas"])
  years = collect(Yr(2030):Yr(2050))
  for year in years, ec in ECs, enduse in enduses, tech in techs
    DPL[enduse,tech,ec,BC,year] = 25
  end
  WriteDisk(db,"$Outpt/DPL",DPL)  
  
end

if abspath(PROGRAM_FILE) == @__FILE__
     PolicyControl(DB)
end  
  
end



