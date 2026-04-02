#
# LCFS_BC.jl
#
# This policy implements a 20% Low Carbon Fuel Standard for transportation fuels in BC
# for Aviation and Marine in Ref25A - Matt Lewis November 17, 2021
#

using EnergyModel

module LCFS_BC_A

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: DB
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct LCFS_BC_AData
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))
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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelKey::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # Demand Fuel/Tech Fraction Minimum (Btu/Btu) [Enduse,Fuel,Tech,EC,Area,Year]
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year]  'Energy Demands Fuel/Tech Split (Fraction)',

  #
  # Scratch Variables
  #
  BDER::VariableArray{1} = zeros(Float32,length(Year))
  DmFrXBefore::VariableArray{6} = zeros(Float32,length(Enduse),length(Fuel),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Fuel,Tech,EC,Area,Year] xDmFrac from Biofuel Before Policy (Btu/Btu)
  ETTarget::VariableArray{1} = zeros(Float32,length(Year))
  SAFTarget::VariableArray{1} = zeros(Float32,length(Year)) #Policy Sustainable Aviation Fuel Target by volume (Btu/Btu)
end

function TransPolicyLCFSBCA(db)
  data = LCFS_BC_AData(; db)
  (; Input) = data
  (; Area,Areas,EC,ECs,Enduse,Enduses,Fuel,Fuels,Tech,Techs,Year,Years) = data
  (; BDER,DmFracMin,DmFrXBefore,ETTarget,SAFTarget) = data
  (; xDmFrac) = data

  BC = Select(Area,"BC")
  for year in Years, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    DmFrXBefore[enduse,fuel,tech,ec,BC,year] = xDmFrac[enduse,fuel,tech,ec,BC,year]
  end

  #
  # SAFTarget represents the target blending rate of Sustainable Aviation Fuel
  # Use ethanol as a SAF proxy
  # start blending in 2023 ramping to 20% by 2038
  #
  for year in Years
    SAFTarget[year] = 0
  end
  years = collect(Yr(2038):Final)
  for year in years
    SAFTarget[year] = 0.2
  end

  years = collect(Yr(2025):Yr(2037))
  for year in years
    SAFTarget[year] =
      SAFTarget[year-1]+(SAFTarget[Yr(2038)]-SAFTarget[Yr(2024)])/(2038-2024)
  end

  years = collect(Yr(2025):Final)

  ecs = Select(EC,["AirPassenger","AirFreight"])
  enduses = Select(Enduse,"Carriage")
  Ethanol = Select(Fuel,"Ethanol")
  JetFuel = Select(Fuel,"JetFuel")
  techs = Select(Tech,"PlaneJetFuel")

  for year in years, ec in ecs, tech in techs, enduse in enduses
    xDmFrac[enduse,Ethanol,tech,ec,BC,year] =
      max((DmFrXBefore[enduse,Ethanol,tech,ec,BC,year]),
        (((DmFrXBefore[enduse,Ethanol,tech,ec,BC,year] +
           (DmFrXBefore[enduse,JetFuel,tech,ec,BC,year]))*SAFTarget[year])))

    xDmFrac[enduse,JetFuel,tech,ec,BC,year] =
      max(0,((DmFrXBefore[enduse,Ethanol,tech,ec,BC,year] +
      (DmFrXBefore[enduse,JetFuel,tech,ec,BC,year])) -
      xDmFrac[enduse,Ethanol,tech,ec,BC,year]))

    DmFracMin[enduse,Ethanol,tech,ec,BC,year] = xDmFrac[enduse,Ethanol,tech,ec,BC,year]
  end

  Ethanol = Select(Fuel,"Ethanol")
  AviationGasoline = Select(Fuel,"AviationGasoline")
  techs = Select(Tech,"PlaneGasoline")
  for year in years, ec in ecs, tech in techs, enduse in enduses
    xDmFrac[enduse,Ethanol,tech,ec,BC,year] =
      max((DmFrXBefore[enduse,Ethanol,tech,ec,BC,year]),
      (((DmFrXBefore[enduse,Ethanol,tech,ec,BC,year] +
      (DmFrXBefore[enduse,AviationGasoline,tech,ec,BC,year]))*SAFTarget[year])))

    xDmFrac[enduse,AviationGasoline,tech,ec,BC,year] =
      max(0,((DmFrXBefore[enduse,Ethanol,tech,ec,BC,year] +
      (DmFrXBefore[enduse,AviationGasoline,tech,ec,BC,year])) -
      xDmFrac[enduse,Ethanol,tech,ec,BC,year]))

    DmFracMin[enduse,Ethanol,tech,ec,BC,year] = xDmFrac[enduse,Ethanol,tech,ec,BC,year]
  end

  #
  # Biodiesel energy content for a 15% volume of diesel = 13.93% energy
  # based on NIR energy content factors
  #
  for year in years
    BDER[year] = 13.93/15
  end

  ecs = Select(EC,"Freight")
  Biodiesel = Select(Fuel,"Biodiesel")

  HFO = Select(Fuel,"HFO")
  techs = Select(Tech,"MarineHeavy")
  #
  # Biodiesel goal is the maximum of the BC LCFS goal or an existing goal.
  # Use SAFTarget as the schedule for blending biodiesel
  #
  for year in years, ec in ecs, tech in techs, enduse in enduses
    xDmFrac[enduse,Biodiesel,tech,ec,BC,year] =
      max(DmFrXBefore[enduse,Biodiesel,tech,ec,BC,year],
      ((DmFrXBefore[enduse,Biodiesel,tech,ec,BC,year] +
      DmFrXBefore[enduse,HFO,tech,ec,BC,year])*(BDER[year]*SAFTarget[year])))

    xDmFrac[enduse,HFO,tech,ec,BC,year] =
      max(0,((DmFrXBefore[enduse,Biodiesel,tech,ec,BC,year] +
      DmFrXBefore[enduse,HFO,tech,ec,BC,year]) -
      xDmFrac[enduse,Biodiesel,tech,ec,BC,year]))

    DmFracMin[enduse,Biodiesel,tech,ec,BC,year] = xDmFrac[enduse,Biodiesel,tech,ec,BC,year]
  end

  Biodiesel = Select(Fuel,"Biodiesel")
  Diesel = Select(Fuel,"Diesel")
  techs = Select(Tech,"MarineLight")

  #
  # Biodiesel goal is the maximum of the BC LCFS goal or an existing goal.
  # Use SAFTarget as the schedule for blending biodiesel
  #
  for year in years, ec in ecs, tech in techs, enduse in enduses
    xDmFrac[enduse,Biodiesel,tech,ec,BC,year] =
      max(DmFrXBefore[enduse,Biodiesel,tech,ec,BC,year],
      ((DmFrXBefore[enduse,Biodiesel,tech,ec,BC,year] +
      DmFrXBefore[enduse,Diesel,tech,ec,BC,year])*(BDER[year]*SAFTarget[year])))

    xDmFrac[enduse,Diesel,tech,ec,BC,year] =
      max(0,((DmFrXBefore[enduse,Biodiesel,tech,ec,BC,year] +
      DmFrXBefore[enduse,Diesel,tech,ec,BC,year]) -
      xDmFrac[enduse,Biodiesel,tech,ec,BC,year]))

    DmFracMin[enduse,Biodiesel,tech,ec,BC,year] = xDmFrac[enduse,Biodiesel,tech,ec,BC,year]
  end

  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

function PolicyControl(db)
  @info "LCFS_BC_A.jl - PolicyControl"
  TransPolicyLCFSBCA(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
