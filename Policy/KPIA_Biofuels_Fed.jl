#
# KPIA_Biofuels_Fed.jl aka KPIA-Biofuels-Fed.txp - Federal Biofuels Policy
#
# The following is from an email from Nick 12/13/11:
#
# A permanent exemption is being provided for renewable content in diesel
# fuel and heating distillate oil sold in Newfoundland and Labrador to
# address the logistical challenges of blending biodiesel in this region.
# Temporary exemptions for renewable content in diesel fuel and heating
# distillate oil sold in Quebec and all Atlantic Provinces are being
# provided until December 31, 2012. This 18-month period will allow
# eastern refiners time to install biodiesel blending infrastructure
#
# Also from my read, Newfoundland and Labrador, as well as Yukon, NWT and
# Nunavut are exempt from the ethanol requirement.
#
# So the KPIA-Biofuels jl should show
# 1. Delay in bio-diesel standard implementation for Quebec, PEI, Nova
#    Scotia and New Brunswick (i.e., policy starts in 2013)
#
# 2. Exemption from bio-diesel standard for Newfoundland and Labrador, as
#    well as Yukon, NWT and Nunavut
#
# 3. Exemption from ethanol standard for Newfoundland and Labrador, as
#    well as Yukon, NWT and Nunavut
#
# Update by Jeff Amlin 12/13/11
#
# Update by Matt Lewis 03/09/14, added modes to cover Freight vehicles
# that were previously not covered
#
# Update by Matt Lewis June 13, 2022
# Cleaned up the code to remove historical changes
#

using EnergyModel

module KPIA_Biofuels_Fed

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
  BBlend::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Biodiesel Blend %,not equal to DMFRAC
  BDGoal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ethanol Goal (Btu/Btu)
  DPoolDmFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Diesel Pool DmFrac,ie Biod + Diesel
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Enduse) = data
  (; Fuel,Tech) = data
  (; BBlend,BDGoal,DPoolDmFrac,DmFracMin) = data
  (; xDmFrac) = data

  areas = Select(Area,["ON","MB","SK","AB","BC","QC","PE","NS","NB"])
  ecs = Select(EC,(from = "Food",to = "OnFarmFuelUse"))
  OffRoad = Select(Enduse,"OffRoad")
  years = collect(Yr(2022):Yr(2050))
  Oil = Select(Tech,"Oil")

  Diesel = Select(Fuel,"Diesel")
  Biodiesel = Select(Fuel,"Biodiesel")
  for year in years, area in areas, ec in ecs
    DPoolDmFrac[OffRoad,Oil,ec,area,year] = 
      xDmFrac[OffRoad,Diesel,Oil,ec,area,year] + 
        xDmFrac[OffRoad,Biodiesel,Oil,ec,area,year]
    @finite_math BBlend[OffRoad,Oil,ec,area,year] = 
      max(0,xDmFrac[OffRoad,Biodiesel,Oil,ec,area,year] / 
        DPoolDmFrac[OffRoad,Oil,ec,area,year])
  end

  #
  # Biodiesel content set at 2%  by volume (1.86% energy) in 2011
  #  
  for year in years
    BDGoal[year] = 0.0186
  end
  for year in years, area in areas, ec in ecs
    BBlend[OffRoad,Oil,ec,area,year] = max(BBlend[OffRoad,Oil,ec,area,year],BDGoal[year])
    xDmFrac[OffRoad,Biodiesel,Oil,ec,area,year] = BBlend[OffRoad,Oil,ec,area,year] *
      DPoolDmFrac[OffRoad,Oil,ec,area,year]
    xDmFrac[OffRoad,Diesel,Oil,ec,area,year] = (1 - BBlend[OffRoad,Oil,ec,area,year]) * 
      DPoolDmFrac[OffRoad,Oil,ec,area,year]
    DmFracMin[OffRoad,Biodiesel,Oil,ec,area,year] = 
      xDmFrac[OffRoad,Biodiesel,Oil,ec,area,year]
  end
  
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  
  # Scratch Variables
  BBlend::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Biodiesel Blend %,not equal to DMFRAC
  BDGoal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ethanol Goal (Btu/Btu)
  DPoolDmFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Diesel Pool DmFrac,ie Biod + Diesel
end

function ResPolicy(db)
  data = RControl(; db)
  (; Input) = data
  (; Area,ECs,Enduses) = data
  (; Fuel,Tech,Year) = data
  (; BBlend,BDGoal,DPoolDmFrac,DmFracMin) = data
  (; xDmFrac) = data

  #
  # Newfoundland and Labrador,Yukon,NWT and Nunavut are exempt from federal biodiesel policy.
  # Biodiesel federal policy starts in 2011, NT, NU, YT and NL exempt
  #  
  areas = Select(Area,["ON","MB","SK","AB","BC","QC","PE","NS","NB"])
  years = Select(Year,(from = "2022",to = "2050"))
  Oil = Select(Tech,"Oil")

  Diesel = Select(Fuel,"Diesel")
  Biodiesel = Select(Fuel,"Biodiesel")
  for year in years, area in areas, ec in ECs, enduse in Enduses
    DPoolDmFrac[enduse,Oil,ec,area,year] = 
      xDmFrac[enduse,Diesel,Oil,ec,area,year] + 
        xDmFrac[enduse,Biodiesel,Oil,ec,area,year]
    @finite_math BBlend[enduse,Oil,ec,area,year] = 
      max(0,xDmFrac[enduse,Biodiesel,Oil,ec,area,year] / 
        DPoolDmFrac[enduse,Oil,ec,area,year])
  end

  #
  # Biodiesel content set at 2% by volume (1.86% energy) in 2011
  #  
  for year in years
    BDGoal[year] = 0.0186
  end
  
  for year in years, area in areas, ec in ECs, enduse in Enduses
    BBlend[enduse,Oil,ec,area,year] = max(BBlend[enduse,Oil,ec,area,year],BDGoal[year])
    xDmFrac[enduse,Biodiesel,Oil,ec,area,year] = BBlend[enduse,Oil,ec,area,year] * 
      DPoolDmFrac[enduse,Oil,ec,area,year]
    xDmFrac[enduse,Diesel,Oil,ec,area,year] = (1 - BBlend[enduse,Oil,ec,area,year]) * 
      DPoolDmFrac[enduse,Oil,ec,area,year]
    DmFracMin[enduse,Biodiesel,Oil,ec,area,year] = 
      xDmFrac[enduse,Biodiesel,Oil,ec,area,year]
  end
  
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
  BBlend::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Biodiesel Blend %,not equal to DMFRAC
  BDGoal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ethanol Goal (Btu/Btu)
  DPoolDmFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Diesel Pool DmFrac,ie Biod + Diesel
  EBlend::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Ethanol Blend %,not equal to DMFRAC
  ETGoal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ethanol Goal (Btu/Btu)
  GPoolDmFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Gasoline Pool DmFrac,ie Ethanol + Gasoline
end

function TransPolicy(db)
  data = TControl(; db)
  (; Input) = data
  (; Area,ECs,Enduses) = data
  (; Fuel) = data
  (; Tech) = data
  (; BBlend,BDGoal,DmFracMin) = data
  (; DPoolDmFrac,EBlend,ETGoal,GPoolDmFrac) = data
  (; xDmFrac) = data

  #
  # Newfoundland and Labrador, Yukon, NWT and Nunavut are exempt from federal biofuels policy.
  # Ethanol federal policy starts in 2011 for everyone except NF, YT, NT, and NU.
  # Ethanol content in Gasoline is 5.00% volume (3.42% energy) in 2011
  # http://oee.nrcan.gc.ca/transportation/alternative-fuels/fuel-facts/Ethanol/10416
  #  
  areas = Select(Area,["ON","MB","SK","AB","BC","QC","PE","NS","NB"])
  years = collect(Yr(2013):Yr(2050))
  techs = Select(Tech,["LDVGasoline","LDVHybrid","LDVFuelCell","LDTGasoline","LDTHybrid",
                        "LDTFuelCell","Motorcycle","BusGasoline","HDV2B3Gasoline",
                        "HDV45Gasoline","HDV67Gasoline","HDV8Gasoline","OffRoad"])

  Diesel = Select(Fuel,"Diesel")
  Biodiesel = Select(Fuel,"Biodiesel")
  Gasoline = Select(Fuel,"Gasoline")
  Ethanol = Select(Fuel,"Ethanol")
  
  for year in years, area in areas, ec in ECs, tech in techs, enduse in Enduses
    DPoolDmFrac[enduse,tech,ec,area,year] = 
      xDmFrac[enduse,tech,ec,area,year] + 
        xDmFrac[enduse,Biodiesel,tech,ec,area,year]
    GPoolDmFrac[enduse,tech,ec,area,year]= 
      xDmFrac[enduse,Gasoline,tech,ec,area,year] + 
        xDmFrac[enduse,Ethanol,tech,ec,area,year]
    @finite_math EBlend[enduse,tech,ec,area,year] = 
      max(0,xDmFrac[enduse,Ethanol,tech,ec,area,year] / 
        GPoolDmFrac[enduse,tech,ec,area,year])
    @finite_math BBlend[enduse,tech,ec,area,year] = 
      max(0,xDmFrac[enduse,Biodiesel,tech,ec,area,year] / 
        DPoolDmFrac[enduse,tech,ec,area,year])
  end

  #
  # Ethanol goal is the maximum of the Federal goal or an existing (provincial) goal.
  #
  # I've set the fraction to start only in the first forecast year
  # while the goal still exists above in the historical period.
  # - Hilary 15.04.15
  #  
  years = collect(Yr(2022):Yr(2050))
  for year in years
    ETGoal[year] = 0.0342
  end
  
  for year in years, area in areas, ec in ECs, tech in techs, enduse in Enduses
    EBlend[enduse,tech,ec,area,year] = max(EBlend[enduse,tech,ec,area,year],ETGoal[year])
    xDmFrac[enduse,Ethanol,tech,ec,area,year] = EBlend[enduse,tech,ec,area,year] * 
      GPoolDmFrac[enduse,tech,ec,area,year]
    xDmFrac[enduse,Gasoline,tech,ec,area,year] = (1 - EBlend[enduse,tech,ec,area,year]) * 
      GPoolDmFrac[enduse,tech,ec,area,year]
    DmFracMin[enduse,Ethanol,tech,ec,area,year] = xDmFrac[enduse,Ethanol,tech,ec,area,year]
  end
  
  #
  # Biodiesel federal policy starts in 2011
  # Biodiesel content in Diesel is 2.00% volume (1.86% energy) in 2011
  # Biodiesel goal is the maximum of the Federal goal or an existing (provincial) goal.
  #  
  techs = Select(Tech,["LDVDiesel","LDTDiesel","BusDiesel","MarineLight","HDV2B3Diesel",
                        "HDV45Diesel","HDV67Diesel","HDV8Diesel","TrainDiesel","OffRoad"])
  for year in years
    BDGoal[year] = 0.0186
  end
  
  for year in years, area in areas, ec in ECs, tech in techs, eu in Enduses
    BBlend[eu,tech,ec,area,year] = max(BBlend[eu,tech,ec,area,year],BDGoal[year])
    xDmFrac[eu,Biodiesel,tech,ec,area,year] = BBlend[eu,tech,ec,area,year] * 
      DPoolDmFrac[eu,tech,ec,area,year]
    xDmFrac[eu,Diesel,tech,ec,area,year] = (1 - BBlend[eu,tech,ec,area,year]) * 
      DPoolDmFrac[eu,tech,ec,area,year]
    DmFracMin[eu,Biodiesel,tech,ec,area,year] = xDmFrac[eu,Biodiesel,tech,ec,area,year]
  end
  
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

function PolicyControl(db)
  @info "KPIA-Biofuels-Fed.jl - PolicyControl"
  IndPolicy(db)
  ResPolicy(db)
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
