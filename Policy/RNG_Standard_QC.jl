#
# RNG_Standard_QC.jl
#
# This file implements an RNG Standard in QC as per Provincial Input
# 1% by 2020, 2% by 2023, 5% by 2025
# Matt Lewis July 12, 2019
#
# Updated to reflect regulated goal of 10% by 2030
# for the reference case
# www.legisquebec.gouv.qc.ca/en/document/cr/R-6.01, r. 4.3 /
#

using EnergyModel

module RNG_Standard_QC

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
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  
  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,ECs,Enduses) = data 
  (; Fuel) = data
  (; Tech) = data
  (; DmFracMin) = data
  (; Target,xDmFrac) = data
  
  areas = Select(Area,"QC")
  techs = Select(Tech,"Gas")
  RNG = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  
  # 
  # Target for fuel switching
  # 
   Target .= 0
   years = collect(Yr(2030):Yr(2050)) 
   for year in years
    Target[year] = 0.10
   end
   years = collect(Yr(2028):Yr(2029)) 
   for year in years
    Target[year] = 0.07
   end
   years = collect(Yr(2025):Yr(2027)) 
   for year in years
    Target[year] = 0.05
   end
   Target[Future] = 0.02
   
   # 
   # A portion of Natural Gas demands are now RNG
   #   
   years = collect(Future:Yr(2050))     
   for area in areas, tech in techs, ec in ECs, enduse in Enduses, year in years
     
     xDmFrac[enduse,RNG,tech,ec,area,year] = xDmFrac[enduse,RNG,tech,ec,area,year]+
       xDmFrac[enduse,NaturalGas,tech,ec,area,year]*Target[year]
       
     xDmFrac[enduse,NaturalGas,tech,ec,area,year] =
       xDmFrac[enduse,NaturalGas,tech,ec,area,year]*(1-Target[year])
     
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
  (; DmFracMin) = data
  (; Target,xDmFrac) = data

  areas = Select(Area,"QC")
  techs = Select(Tech,"Gas")
  RNG = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  
  # 
  # Target for fuel switching
  # 
   Target .= 0
   years = collect(Yr(2030):Yr(2050)) 
   for year in years
    Target[year] = 0.10
   end
   years = collect(Yr(2028):Yr(2029)) 
   for year in years
    Target[year] = 0.07
   end
   years = collect(Yr(2025):Yr(2027)) 
   for year in years
    Target[year] = 0.05
   end
   Target[Future] = 0.02   
   years = collect(Future:Yr(2050))
   
   # 
   # A portion of Natural Gas demands are now RNG
   # 
   for area in areas, tech in techs, ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,tech,ec,area,year] = xDmFrac[enduse,RNG,tech,ec,area,year]+
      xDmFrac[enduse,NaturalGas,tech,ec,area,year]*Target[year]
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = 
      xDmFrac[enduse,NaturalGas,tech,ec,area,year]*(1-Target[year])
    DmFracMin[enduse,RNG,tech,ec,area,year] = xDmFrac[enduse,RNG,tech,ec,area,year]
   end
   
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
  (; DmFracMin) = data
  (; Target,xDmFrac) = data
  
  areas = Select(Area,"QC")
  techs = Select(Tech,"Gas")
  RNG = Select(Fuel,"RNG")
  NaturalGas = Select(Fuel,"NaturalGas")
  
  # 
  # Target for fuel switching
  #
   Target .= 0
   years = collect(Yr(2030):Yr(2050)) 
   for year in years
    Target[year] = 0.10
   end
   years = collect(Yr(2028):Yr(2029)) 
   for year in years
    Target[year] = 0.07
   end
   years = collect(Yr(2025):Yr(2027)) 
   for year in years
    Target[year] = 0.05
   end
   Target[Future] = 0.02   
   years = collect(Future:Yr(2050))
  
   # 
   # A portion of Natural Gas demands are now RNG
   #    
   for area in areas, tech in techs, ec in ECs, enduse in Enduses, year in years
    xDmFrac[enduse,RNG,tech,ec,area,year] = xDmFrac[enduse,RNG,tech,ec,area,year]+
      xDmFrac[enduse,NaturalGas,tech,ec,area,year]*Target[year]
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year]*
      (1-Target[year])
    DmFracMin[enduse,RNG,tech,ec,area,year] = xDmFrac[enduse,RNG,tech,ec,area,year]
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
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") #[Year]  Number of Units
  UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum (Btu/Btu)
  UnFlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMin") # [Unit,FuelEP,Year] Fuel Fraction Minimum (Btu/Btu)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation

  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Fuel Target (Btu/Btu)
end

function GetUtilityUnits(data,year)
  (; UnArea,UnCogen,UnNation) = data

  #
  # Select Unit If (UnNation eq "CN") and (UnCogen eq 0) and (UnArea eq "BC")
  #  
  UnitsNotCogen = Select(UnCogen,==(0.0))
  UnitsInCanada = Select(UnNation,==("CN"))
  UnitsInQC     = Select(UnArea,==("QC"))
  UnitsToAdjust = intersect(UnitsNotCogen,UnitsInCanada,UnitsInQC)

  return UnitsToAdjust
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,FuelEP,FuelEPs) = data
  (; Nation,Plants) = data
  (; ANMap,FlFrNew,Target,UnFlFrMax,UnFlFrMin) = data
  (; xUnFlFr) = data

  # 
  # Target for fuel switching
  #  
  Target .= 0
  years = collect(Yr(2030):Yr(2050)) 
  for year in years
    Target[year] = 0.10
  end
  years = collect(Yr(2028):Yr(2029)) 
  for year in years
    Target[year] = 0.07
  end
  years = collect(Yr(2025):Yr(2027)) 
  for year in years
    Target[year] = 0.05
  end
  Target[Future] = 0.02   
  years = collect(Future:Yr(2050))

  units = GetUtilityUnits(data,Yr(2025))
  RNG = Select(FuelEP,"RNG")
  NaturalGas = Select(FuelEP,"NaturalGas")
  
  #
  #  A portion of NaturalGas demands are now RNG
  #     
  years = collect(Future:Yr(2050)) 
  for year in years, unit in units
  
    #if (unit == 1256) && (year == Yr(2050))
    #  loc1 = xUnFlFr[unit,RNG,year]
    #  @info " Before xUnFlFr[$unit,RNG,$year] = $loc1"
    #  loc1 = xUnFlFr[unit,NaturalGas,year]
    #  @info " Before xUnFlFr[$unit,NaturalGas,$year] = $loc1"
    #  loc1 = Target[year]
    #  @info " Before Target[$year] = $loc1"
    #end
      
    xUnFlFr[unit,RNG,year] = xUnFlFr[unit,RNG,year]+
                           xUnFlFr[unit,NaturalGas,year]*Target[year]
                           
    xUnFlFr[unit,NaturalGas,year] = xUnFlFr[unit,NaturalGas,year]*(1-Target[year])
      
    #if (unit == 1256) && (year == Yr(2050))
    # loc1 = xUnFlFr[unit,RNG,year]
    #  @info " After xUnFlFr[$unit,RNG,$year] = $loc1"
    #  loc1 = xUnFlFr[unit,NaturalGas,year]
    #  @info " After xUnFlFr[$unit,NaturalGas,$year] = $loc1"
    #end     
    
  end
  
  for year in years, unit in units, fuel in FuelEPs
    UnFlFrMax[unit,fuel,year] = xUnFlFr[unit,fuel,year]
    UnFlFrMin[unit,fuel,year] = xUnFlFr[unit,fuel,year]
  end
  
  WriteDisk(db,"EGInput/UnFlFrMax",UnFlFrMax)
  WriteDisk(db,"EGInput/UnFlFrMin",UnFlFrMin)
  WriteDisk(db,"EGInput/xUnFlFr",xUnFlFr)
  # 
  #
  #
  area = Select(Area, "QC")
  for plant in Plants, year in years
    FlFrNew[RNG,plant,area,year] = FlFrNew[RNG,plant,area,year]+
      FlFrNew[NaturalGas,plant,area,year]*Target[year]
    FlFrNew[NaturalGas,plant,area,year] = FlFrNew[NaturalGas,plant,area,year]*
      (1-Target[year])
  end
  
  WriteDisk(db,"EGInput/FlFrNew",FlFrNew)
end

function PolicyControl(db)
  @info "RNG_Standard_QC.jl - PolicyControl"
  IndPolicy(db)
  ComPolicy(db)
  ResPolicy(db)
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
