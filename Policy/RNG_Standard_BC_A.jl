#
# RNG_Standard_BC_A.jl
#
# This file implements an RNG Standard in BC as per Provincial Input
# 5% by 2025, 15% by 2030
# Matt Lewis July 15, 2019
#

using EnergyModel

module RNG_Standard_BC_A

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
  
  area = Select(Area,"BC")
  tech = Select(Tech,"Gas")
  
  #
  # Target for fuel switching
  #   
  Target .= 0
  Target[Future] = 0.02
  Target[Yr(2025)] = 0.035
  years_2030_final = Yr(2030):Final
  for year in years_2030_final
    Target[year] = 0.15
  end
  
  years_2026_2029 = Yr(2026):Yr(2029)
  for year in years_2026_2029
    Target[year] = Target[year-1] + (Target[Yr(2030)] - Target[Yr(2025)]) / (2030 - 2025)
  end
  
  # 
  # A portion of Natural Gas demands are now RNG
  # 
  years = collect(Future:Final)
  bc = Select(Area,"BC")
  gas = Select(Tech,"Gas")
  RNG = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  
  for ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,gas,ec,bc,year] = 
      DmFracRef[enduse,NaturalGas,gas,ec,bc,year]*Target[year]
    DmFracMin[enduse,RNG,gas,ec,bc,year] = 
      xDmFrac[enduse,RNG,gas,ec,bc,year]
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
  
  area = Select(Area,"BC")
  tech = Select(Tech,"Gas")
  
  #
  # Target for fuel switching
  #   
  Target .= 0
  Target[Future] = 0.02
  Target[Yr(2025)] = 0.035
  years_2030_final = Yr(2030):Final
  for year in years_2030_final
    Target[year] = 0.15
  end
  
  years_2026_2029 = Yr(2026):Yr(2029)
  for year in years_2026_2029
    Target[year] = Target[year-1] + (Target[Yr(2030)] - Target[Yr(2025)]) / (2030 - 2025)
  end
  
  # 
  # A portion of Natural Gas demands are now RNG
  #  
  years = collect(Future:Final)
  bc = Select(Area,"BC")
  gas = Select(Tech,"Gas")
  RNG = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  
  for ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,gas,ec,bc,year] = 
      DmFracRef[enduse,NaturalGas,gas,ec,bc,year]*Target[year]
    DmFracMin[enduse,RNG,gas,ec,bc,year] = 
      xDmFrac[enduse,RNG,gas,ec,bc,year]
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

  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input,Outpt) = data
  (; Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses) = data 
  (; Fuel,FuelDS,Fuels,Nation,NationDS,Nations) = data
  (; Tech,TechDS,Techs,Year,YearDS,Years) = data    
  (; ANMap,DmFracRef,DmFracMin,Target,xDmFrac) = data
  
  area = Select(Area,"BC")
  tech = Select(Tech,"Gas")
  
  #
  # Target for fuel switching
  #   
  Target .= 0
  Target[Future] = 0.02
  Target[Yr(2025)] = 0.035
  years_2030_final = Yr(2030):Final
  for year in years_2030_final
    Target[year] = 0.15
  end
  
  years_2026_2029 = Yr(2026):Yr(2029)
  for year in years_2026_2029
    Target[year] = Target[year-1] + (Target[Yr(2030)] - Target[Yr(2025)]) / (2030 - 2025)
  end
  
  # 
  # A portion of Natural Gas demands are now RNG
  #   
  years = collect(Future:Final)
  bc = Select(Area,"BC")
  gas = Select(Tech,"Gas")
  RNG = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  
  for ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,gas,ec,bc,year] = 
      DmFracRef[enduse,NaturalGas,gas,ec,bc,year]*Target[year]
    DmFracMin[enduse,RNG,gas,ec,bc,year] = 
      xDmFrac[enduse,RNG,gas,ec,bc,year]
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
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") #[Year]  Number of Units
  UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum (Btu/Btu)
  UnFlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMin") # [Unit,FuelEP,Year] Fuel Fraction Minimum (Btu/Btu)
  UnFlFrRef::VariableArray{3} = ReadDisk(BCNameDB,"EGOutput/UnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation

  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function GetUtilityUnits(data)
  (; UnArea,UnCogen,UnCounter,UnNation) = data

  #
  # Select Unit If (UnNation eq "CN") and (UnCogen eq 0) and (UnArea eq "BC")
  #

  UnitsNotCogen = Select(UnCogen,==(0.0))
  UnitsInCanada = Select(UnNation,==("CN"))
  UnitsInBC = Select(UnArea,==("BC"))
  UnitsToAdjust = intersect(UnitsNotCogen,UnitsInCanada,UnitsInBC)

  return UnitsToAdjust
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area, FuelEP) = data
  (; Nation,Plants) = data 
  (; ANMap,FlFrNew,FlFrNewRef,Target) = data
  (; UnFlFrMin,UnFlFrRef,xUnFlFr) = data

  #
  # Target for fuel switching
  # 
  Target .= 0
  
  # Set key target years
  Target[Future] = 0.02
  Target[Yr(2025)] = 0.035
  years_2030_final = Yr(2030):Final
  for year in years_2030_final
    Target[year] = 0.15
  end
  
  years_2026_2029 = Yr(2026):Yr(2029)
  for year in years_2026_2029
    Target[year] = Target[year-1] + (Target[Yr(2030)] - Target[Yr(2025)]) / (2030 - 2025)
  end
  
  years = collect(Future:Final)
  RNG = Select(FuelEP,"RNG")
  NaturalGas = Select(FuelEP,"NaturalGas")
  units = GetUtilityUnits(data)
  
  #
  #  A portion of NaturalGas demands are now Natural Gas
  #   
  for year in years, unit in units
    UnFlFrMin[unit,RNG,year] = UnFlFrRef[unit,NaturalGas,year]*Target[year]
    xUnFlFr[unit,RNG,year] = UnFlFrMin[unit,RNG,year]  
  end
  
  WriteDisk(db,"EGInput/UnFlFrMin",UnFlFrMin)
  WriteDisk(db,"EGInput/xUnFlFr",xUnFlFr)
  # 
  #
  #
  area = Select(Area, "BC")
  for plant in Plants, year in years
    FlFrNew[RNG,plant,area,year] = FlFrNewRef[NaturalGas,plant,area,year]*Target[year]
    FlFrNew[NaturalGas,plant,area,year] = FlFrNewRef[NaturalGas,plant,area,year]*
      (1-Target[year])
  end
  
  WriteDisk(db,"EGInput/FlFrNew",FlFrNew) 
end

function PolicyControl(db)
  @info "RNG_Standard_BC_A.jl - PolicyControl"
  ResPolicy(db)
  ComPolicy(db)
  IndPolicy(db)
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
