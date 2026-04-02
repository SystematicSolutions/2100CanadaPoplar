#
# RNG_Standard.jl
#
# This file implements an RNG Standard in multiple provinces
# 2.5% by 2025
# Based on RNG_Standard.txp
#

using EnergyModel

module RNG_Standard

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

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
  DmFracRef::VariableArray{6} = ReadDisk(BCNameDB,"$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)

  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function ResPolicy(db)
  data = RControl(; db)
  (; Input) = data
  (; Area,ECs,Enduses) = data 
  (; Fuel) = data
  (; Tech) = data    
  (; DmFracRef,DmFracMin,Target,xDmFrac) = data
  
  # Target for fuel switching - linear ramp from 0 in 2022 to 2.5% in 2025
  Target .= 0.0
  for year in Yr(2025):Final
    Target[year] = 0.025
  end
  
  #
  # Linear interpolation for 2022-2024
  #
  for year in Yr(2022):Yr(2024)
    Target[year] = Target[year-1] + (Target[Yr(2025)] - Target[Yr(2022)]) / (2025 - 2022)
  end
  
  #
  # A portion of Natural Gas demands are now RNG
  #
  years = Future:Final
  target_areas = ["AB","ON","MB","NB","SK"]
  areas = Select(Area,target_areas)
  techs = Select(Tech,"Gas")
  RNG = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  
  for area in areas, tech in techs, ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,tech,ec,area,year] = DmFracRef[enduse,NaturalGas,tech,ec,area,year]*
       Target[year]
    DmFracMin[enduse,RNG,tech,ec,area,year] = xDmFrac[enduse,RNG,tech,ec,area,year]
  end
  
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

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
  DmFracRef::VariableArray{6} = ReadDisk(BCNameDB,"$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)

  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function ComPolicy(db)
  data = CControl(; db)
  (; Input) = data
  (; Area,ECs,Enduses) = data 
  (; Fuel) = data
  (; Tech) = data    
  (; DmFracRef,DmFracMin,Target,xDmFrac) = data
  
  #
  # Target for fuel switching - linear ramp from 0 in 2022 to 2.5% in 2025
  #
  Target .= 0.0
  for year in Yr(2025):Final
    Target[year] = 0.025
  end
  
  #
  # Linear interpolation for 2022-2024
  #
  for year in Yr(2022):Yr(2024)
    Target[year] = Target[year-1] + (Target[Yr(2025)] - Target[Yr(2022)]) / (2025 - 2022)
  end
  
  #
  # A portion of Natural Gas demands are now RNG
  #
  years = Future:Final
  target_areas = ["AB", "ON", "MB", "NB", "SK"]
  areas = Select(Area, target_areas)
  techs = Select(Tech, "Gas")
  RNG = Select(Fuel, "RNG")
  NaturalGas = Select(Fuel, "NaturalGas")
  
  for area in areas, tech in techs, ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,tech,ec,area,year] = 
      DmFracRef[enduse,NaturalGas,tech,ec,area,year]*Target[year]
    DmFracMin[enduse,RNG,tech,ec,area,year] = 
      xDmFrac[enduse,RNG,tech,ec,area,year]
  end
  
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

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
  DmFracRef::VariableArray{6} = ReadDisk(BCNameDB,"$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)

  #
  # Scratch Variables
  #
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,ECs,Enduses) = data 
  (; Fuel) = data
  (; Tech) = data    
  (; DmFracRef,DmFracMin,Target,xDmFrac) = data
  
  #
  # Target for fuel switching - linear ramp from 0 in 2022 to 2.5% in 2025
  #
  Target .= 0.0
  for year in Yr(2025):Final
    Target[year] = 0.025
  end
  
  #
  # Linear interpolation for 2022-2024
  #  
  for year in Yr(2022):Yr(2024)
    Target[year] = Target[year-1] + (Target[Yr(2025)] - Target[Yr(2022)]) / (2025 - 2022)
  end
  
  #
  # A portion of Natural Gas demands are now RNG
  #
  years = Future:Final
  target_areas = ["AB", "ON", "MB", "NB", "SK"]
  areas = Select(Area, target_areas)
  techs = Select(Tech, "Gas")
  RNG = Select(Fuel, "RNG")
  NaturalGas = Select(Fuel, "NaturalGas")
  
  for area in areas, tech in techs, ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,tech,ec,area,year] = 
      DmFracRef[enduse,NaturalGas,tech,ec,area,year]*Target[year]
    DmFracMin[enduse,RNG,tech,ec,area,year] = 
      xDmFrac[enduse,RNG,tech,ec,area,year]
  end
  
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

Base.@kwdef struct EControl
  db::String
  
  CalDB::String = "EGCalDB"
  Input::String = "EGInput"
  Outpt::String = "EGOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FlFrNew::VariableArray{4} = ReadDisk(db,"EGInput/FlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  FlFrNewRef::VariableArray{4} = ReadDisk(BCNameDB,"EGInput/FlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum (Btu/Btu)
  UnFlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMin") # [Unit,FuelEP,Year] Fuel Fraction Minimum (Btu/Btu)
  UnFlFrRef::VariableArray{3} = ReadDisk(BCNameDB,"EGOutput/UnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation

  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function GetUtilityUnits(data, target_areas)
  (; UnArea,UnCogen,UnNation) = data

  # Select units that are:
  # - In Canada (UnNation == "CN") 
  # - Not cogeneration (UnCogen == 0)
  # - In target areas
  
  UnitsNotCogen = Select(UnCogen,==(0.0))
  UnitsInTargetAreas = Select(UnArea, in(target_areas))
  UnitsToAdjust = intersect(UnitsNotCogen,UnitsInTargetAreas)

  return UnitsToAdjust
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,FuelEP) = data
  (; Nation,Plants) = data 
  (; ANMap,FlFrNew,FlFrNewRef,Target) = data
  (; UnFlFrMin,UnFlFrRef,xUnFlFr) = data

  #
  # Target for fuel switching - linear ramp from 0 in 2022 to 2.5% in 2025
  #  
  Target .= 0.0
  for year in Yr(2025):Final
    Target[year] = 0.025
  end
  
  #
  # Linear interpolation for 2022-2024
  #
  for year in Yr(2022):Yr(2024)
    Target[year] = Target[year-1] + (Target[Yr(2025)] - Target[Yr(2022)]) / (2025 - 2022)
  end
  
  years = Future:Final
  RNG = Select(FuelEP,"RNG")
  NaturalGas = Select(FuelEP,"NaturalGas")
  target_areas = ["AB", "ON", "MB", "NB", "SK"]
  units = GetUtilityUnits(data, target_areas)
  
  #
  # A portion of NaturalGas demands are now RNG for utility units
  #
  for year in years, unit in units
    UnFlFrMin[unit,RNG,year] = UnFlFrRef[unit,NaturalGas,year]*Target[year]
    xUnFlFr[unit,RNG,year] = UnFlFrMin[unit,RNG,year]  
  end
  
  WriteDisk(db,"EGInput/UnFlFrMin",UnFlFrMin)
  WriteDisk(db,"EGInput/xUnFlFr",xUnFlFr)
  
  #
  # For new plants in Canadian areas
  #
  areas = Select(Area, target_areas)
  for area in areas, plant in Plants, year in years
    FlFrNew[RNG,plant,area,year] = FlFrNewRef[NaturalGas,plant,area,year]*Target[year]
    FlFrNew[NaturalGas,plant,area,year] = FlFrNewRef[NaturalGas,plant,area,year]*
      (1-Target[year])
  end
  
  WriteDisk(db,"EGInput/FlFrNew",FlFrNew) 
end

function PolicyControl(db)
  @info "RNG_Standard.jl - PolicyControl"
  ResPolicy(db)
  ComPolicy(db)
  IndPolicy(db)
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
