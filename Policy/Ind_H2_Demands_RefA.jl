#
# Ind_H2_Demands_RefA.jl
#
# Adjusted by RST 16Sept2022, keep H2 production from AP facility at 2024 levels for 
# projection period to 2050
#

using EnergyModel

module Ind_H2_Demands_RefA

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

  H2CD::VariableArray{1} = ReadDisk(db,"SpInput/H2CD") # [Year] Hydrogen Production Construction Delay (Years)
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Enduse,Enduses,Fuel,Tech) = data
  (; DmFracMax,DmFracMin,H2CD,xDmFrac) = data

  #
  # Originally AirProducts was scheduled to come online in 2024. It appears that this is no longer the case
  # and that expected timeline for the completion of the project has been pushed back.
  # With this in mind the original year that hydrogen energy demand will be accepted in Alberta is in
  # 2025. This assumption may need to be revisited throughout the Ref24 update cycle.
  #
  AB = Select(Area,"AB")
  ecs = Select(EC,["Petrochemicals","Petroleum","OilSandsUpgraders"])
  fuels = Select(Fuel,["Hydrogen","NaturalGas","NaturalGasRaw","RNG","StillGas"])
  Gas = Select(Tech,"Gas")
  Heat  = Select(Enduse,"Heat")

  Biomass = Select(Fuel,"Biomass")
  Coal = Select(Fuel,"Coal")
  Hydrogen = Select(Fuel,"Hydrogen")
  PetroCoke = Select(Fuel,"PetroCoke")
  NaturalGas = Select(Fuel,"NaturalGas")
  NaturalGasRaw = Select(Fuel,"NaturalGasRaw")
  RNG = Select(Fuel,"RNG")
  StillGas = Select(Fuel,"StillGas")
  Electric = Select(Fuel,"Electric")
  LPG = Select(Fuel,"LPG")
  Waste = Select(Fuel,"Waste")

  Petrochemicals    = Select(EC,"Petrochemicals")
  Petroleum         = Select(EC,"Petroleum")
  OilSandsUpgraders = Select(EC,"OilSandsUpgraders")

  # Petrochemicals          2025
  xDmFrac[Heat,Hydrogen,     Gas,Petrochemicals,   AB,Yr(2025)] = 0.0776
  xDmFrac[Heat,NaturalGas,   Gas,Petrochemicals,   AB,Yr(2025)] = 0.8323
  xDmFrac[Heat,NaturalGasRaw,Gas,Petrochemicals,   AB,Yr(2025)] = 0.0000
  xDmFrac[Heat,RNG,          Gas,Petrochemicals,   AB,Yr(2025)] = 0.0000
  xDmFrac[Heat,StillGas,     Gas,Petrochemicals,   AB,Yr(2025)] = 0.0000

  # OilSandsUpgraders       2025
  xDmFrac[Heat,Hydrogen,     Gas,Petroleum,        AB,Yr(2025)] = 0.1515
  xDmFrac[Heat,NaturalGas,   Gas,Petroleum,        AB,Yr(2025)] = 0.1782
  xDmFrac[Heat,NaturalGasRaw,Gas,Petroleum,        AB,Yr(2025)] = 0.0000
  xDmFrac[Heat,RNG,          Gas,Petroleum,        AB,Yr(2025)] = 0.0000
  xDmFrac[Heat,StillGas,     Gas,Petroleum,        AB,Yr(2025)] = 0.6704

  # OilSandsUpgraders       2025
  xDmFrac[Heat,Hydrogen,Gas,OilSandsUpgraders,AB,Yr(2025)] = 0.0462
  xDmFrac[Heat,NaturalGas,Gas,OilSandsUpgraders,AB,Yr(2025)] = 0.2237
  xDmFrac[Heat,NaturalGasRaw,Gas,OilSandsUpgraders,AB,Yr(2025)] = 0.0000
  xDmFrac[Heat,RNG,Gas,OilSandsUpgraders,AB,Yr(2025)] = 0.0000
  xDmFrac[Heat,StillGas,Gas,OilSandsUpgraders,AB,Yr(2025)] = 0.7001

  for ec in ecs, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,Gas,ec,AB,Yr(2025)] = xDmFrac[Heat,fuel,Gas,ec,AB,Yr(2025)]
  end
  years = collect(Yr(2026):Yr(2030))
  for year in years, ec in ecs, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,Gas,ec,AB,year] = xDmFrac[enduse,fuel,Gas,ec,AB,Yr(2025)]
  end
  years = collect(Yr(2031):Final)
  for year in years, ec in ecs, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,Gas,ec,AB,year] = xDmFrac[enduse,fuel,Gas,ec,AB,year-1]*1.00
  end

  fuels = Select(Fuel,["Hydrogen","NaturalGas","NaturalGasRaw","RNG","StillGas"])
  years = collect(Yr(2025):Final)
  for year in years, ec in ecs, fuel in fuels, enduse in Enduses

    DmFracMax[enduse,fuel,Gas,ec,AB,year] = 
      xDmFrac[enduse,fuel,Gas,ec,AB,year]*1.01
    DmFracMin[enduse,fuel,Gas,ec,AB,year] = 
      xDmFrac[enduse,fuel,Gas,ec,AB,year]*0.99
  end

  #
  ######################
  #
  NL = Select(Area,"NL")
  OtherChemicals = Select(EC,"OtherChemicals")
  fuels = Select(Fuel,["Electric","LPG","NaturalGasRaw","Hydrogen","StillGas"])
  LPGTech = Select(Tech,"LPG")

  Heat = Select(Enduse,"Heat")
  
  # OtherChemicals          2024
  xDmFrac[Heat,Electric,LPGTech,OtherChemicals,NL,Yr(2024)] = 0.4066
  xDmFrac[Heat,LPG,LPGTech,OtherChemicals,NL,Yr(2024)] = 0.5933
  xDmFrac[Heat,NaturalGasRaw,LPGTech,OtherChemicals,NL,Yr(2024)] = 0.0000
  xDmFrac[Heat,Hydrogen,LPGTech,OtherChemicals,NL,Yr(2024)] = 0.0000
  xDmFrac[Heat,StillGas,LPGTech,OtherChemicals,NL,Yr(2024)] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,LPGTech,OtherChemicals,NL,Yr(2024)] = xDmFrac[Heat,fuel,LPGTech,OtherChemicals,NL,Yr(2024)]
  end

  years = collect(Yr(2025):Yr(2030))
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,LPGTech,OtherChemicals,NL,year] = xDmFrac[enduse,fuel,LPGTech,OtherChemicals,NL,Yr(2024)]
  end
  years = collect(Yr(2031):Final)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,LPGTech,OtherChemicals,NL,year] = xDmFrac[enduse,fuel,LPGTech,OtherChemicals,NL,year-1]*0.80
  end
  
  #
  ######################
  #
  fuels = Select(Fuel,["Electric","NaturalGas","NaturalGasRaw","Hydrogen","StillGas"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,LPGTech,OtherChemicals,NL,year] = 
      xDmFrac[enduse,fuel,LPGTech,OtherChemicals,NL,year]*1.01
    DmFracMin[enduse,fuel,LPGTech,OtherChemicals,NL,year] = 
      xDmFrac[enduse,fuel,LPGTech,OtherChemicals,NL,year]*0.99
  end

  #
  #######################
  #
  NL = Select(Area,"NL")
  OtherChemicals = Select(EC,"OtherChemicals")
  fuels = Select(Fuel,["Electric","LPG","NaturalGas","Hydrogen","StillGas"])
  Gas = Select(Tech,"Gas")
  Electric = Select(Fuel,"Electric")

  Heat = Select(Enduse,"Heat")
  xDmFrac[Heat,Electric,Gas,OtherChemicals,NL,Yr(2024)] = 0.6266
  xDmFrac[Heat,LPG,Gas,OtherChemicals,NL,Yr(2024)] = 0.0000
  xDmFrac[Heat,NaturalGas,Gas,OtherChemicals,NL,Yr(2024)] = 0.3733
  xDmFrac[Heat,Hydrogen,Gas,OtherChemicals,NL,Yr(2024)] = 0.0000
  xDmFrac[Heat,StillGas,Gas,OtherChemicals,NL,Yr(2024)] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,Gas,OtherChemicals,NL,Yr(2024)] = xDmFrac[Heat,fuel,Gas,OtherChemicals,NL,Yr(2024)]
  end

  years = collect(Yr(2025):Yr(2030))
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,Gas,OtherChemicals,NL,year] = xDmFrac[enduse,fuel,Gas,OtherChemicals,NL,Yr(2024)]
  end
  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,NaturalGas,Gas,OtherChemicals,NL,year] = xDmFrac[enduse,NaturalGas,Gas,OtherChemicals,NL,year-1]*0.94
  end
  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Electric,Gas,OtherChemicals,NL,year] = xDmFrac[enduse,Electric,Gas,OtherChemicals,NL,year-1]*1.06
  end

  #
  ######################
  #
  fuels = Select(Fuel,["Electric","NaturalGas","NaturalGasRaw","Hydrogen","StillGas"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,Gas,OtherChemicals,NL,year] = 
      xDmFrac[enduse,fuel,Gas,OtherChemicals,NL,year]*1.01
    DmFracMin[enduse,fuel,Gas,OtherChemicals,NL,year] = 
      xDmFrac[enduse,fuel,Gas,OtherChemicals,NL,year]*0.99
  end

  #
  ######################
  #
  AB = Select(Area,"AB")
  Petrochemicals = Select(EC,"Petrochemicals")
  fuels = Select(Fuel,["Hydrogen","NaturalGas","NaturalGasRaw","RNG","StillGas"])
  Gas = Select(Tech,"Gas")

  Heat = Select(Enduse,"Heat")

  # Petrochemicals          2027
  xDmFrac[Heat,Hydrogen,     Gas,Petrochemicals,AB,Yr(2027)] = 0.3776
  xDmFrac[Heat,NaturalGas,   Gas,Petrochemicals,AB,Yr(2027)] = 0.5323
  xDmFrac[Heat,NaturalGasRaw,Gas,Petrochemicals,AB,Yr(2027)] = 0.0000
  xDmFrac[Heat,RNG,          Gas,Petrochemicals,AB,Yr(2027)] = 0.0000
  xDmFrac[Heat,StillGas,     Gas,Petrochemicals,AB,Yr(2027)] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,Gas,Petrochemicals,AB,Yr(2027)] = xDmFrac[Heat,fuel,Gas,Petrochemicals,AB,Yr(2027)]
  end

  years = collect(Yr(2028):Yr(2030))
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,Gas,Petrochemicals,AB,year] = xDmFrac[enduse,fuel,Gas,Petrochemicals,AB,Yr(2027)]
  end
  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,Gas,Petrochemicals,AB,year] = xDmFrac[enduse,Hydrogen,Gas,Petrochemicals,AB,year-1]*0.96
  end
  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,NaturalGas,Gas,Petrochemicals,AB,year] = xDmFrac[enduse,NaturalGas,Gas,Petrochemicals,AB,year-1]*1.04
  end
  
  #
  ######################
  #
  fuels = Select(Fuel,["Hydrogen","NaturalGas","NaturalGasRaw","RNG","StillGas"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,Gas,Petrochemicals,AB,year] = 
      xDmFrac[enduse,fuel,Gas,Petrochemicals,AB,year]*1.01
      
    DmFracMin[enduse,fuel,Gas,Petrochemicals,AB,year] = 
      xDmFrac[enduse,fuel,Gas,Petrochemicals,AB,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"BC")
  ec = Select(EC,"Petroleum")
  fuels = Select(Fuel,["Hydrogen","NaturalGas","PetroCoke","NaturalGasRaw","StillGas"])
  tech = Select(Tech,"Gas")
  year = Yr(2029)

  Heat = Select(Enduse,"Heat")

  # Petroleum          2029
  xDmFrac[Heat,Hydrogen,     tech,ec,area,year] = 0.1315
  xDmFrac[Heat,NaturalGas,   tech,ec,area,year] = 0.0569
  xDmFrac[Heat,PetroCoke,    tech,ec,area,year] = 0.2843
  xDmFrac[Heat,NaturalGasRaw,tech,ec,area,year] = 0.0000
  xDmFrac[Heat,StillGas,     tech,ec,area,year] = 0.5271

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2030)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
    xDmFrac[enduse,StillGas,tech,ec,area,year] = xDmFrac[enduse,StillGas,tech,ec,area,year-1]*1.00
    xDmFrac[enduse,PetroCoke,tech,ec,area,year] = xDmFrac[enduse,PetroCoke,tech,ec,area,year-1]*1.00
  end

  
  #
  ######################
  #
  fuels = Select(Fuel,["Hydrogen","NaturalGas","PetroCoke","NaturalGasRaw","StillGas"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  
  #
  ######################
  #

  area = Select(Area,"BC")
  ec = Select(EC,"SweetGasProcessing")
  fuels = Select(Fuel,["Hydrogen","NaturalGas","PetroCoke","NaturalGasRaw","StillGas"])
  tech = Select(Tech,"Gas")
  year = Yr(2029)

  Heat = Select(Enduse,"Heat")

  # SweetGasProcessing         2029
  xDmFrac[Heat,Hydrogen,     tech,ec,area,year] = 0.0982
  xDmFrac[Heat,NaturalGas,   tech,ec,area,year] = 0.1850
  xDmFrac[Heat,PetroCoke,    tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGasRaw,tech,ec,area,year] = 0.6552
  xDmFrac[Heat,StillGas,     tech,ec,area,year] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2030)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
    xDmFrac[enduse,NaturalGasRaw,tech,ec,area,year] = xDmFrac[enduse,NaturalGasRaw,tech,ec,area,year-1]*1.00
  end

  
  #
  ######################
  #
  fuels = Select(Fuel,["Hydrogen","NaturalGas","PetroCoke","NaturalGasRaw","StillGas"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"BC")
  ec = Select(EC,"Cement")
  fuels = Select(Fuel,["Hydrogen","Biomass","Coal","NaturalGas","Waste"])
  tech = Select(Tech,"Gas")
  year = Yr(2027)

  Heat = Select(Enduse,"Heat")

  # Cement          2027
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.1357
  xDmFrac[Heat,Biomass,   tech,ec,area,year] = 0.1424
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.1761
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.3593
  xDmFrac[Heat,Waste,     tech,ec,area,year] = 0.1843

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2028)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2027)]
  end
  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","Biomass","Coal","NaturalGas","Waste"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"BC")
  ec = Select(EC,"Cement")
  fuels = Select(Fuel,["Hydrogen","Biomass","PetroCoke","NaturalGas","Waste"])
  tech = Select(Tech,"Gas")
  year = Yr(2029)

  Heat = Select(Enduse,"Heat")

  # Cement          2029
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.2421
  xDmFrac[Heat,Biomass,   tech,ec,area,year] = 0.1424
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.2543
  xDmFrac[Heat,Waste,     tech,ec,area,year] = 0.1843

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2030)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
    xDmFrac[enduse,Biomass,tech,ec,area,year] = xDmFrac[enduse,Biomass,tech,ec,area,year-1]*1.00
    xDmFrac[enduse,Waste,tech,ec,area,year] = xDmFrac[enduse,Waste,tech,ec,area,year-1]*1.00
  end

  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","Biomass","PetroCoke","NaturalGas","Waste"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end
  

  #
  ######################
  #

  area = Select(Area,"BC")
  ec = Select(EC,"PulpPaperMills")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","Waste"])
  tech = Select(Tech,"Gas")
  year = Yr(2027)

  Heat = Select(Enduse,"Heat")

  # Cement          2027
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.0442
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.1395
  xDmFrac[Heat,Waste,     tech,ec,area,year] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2028)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2027)]
  end
  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","Waste"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"BC")
  ec = Select(EC,"PulpPaperMills")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","Waste"])
  tech = Select(Tech,"Gas")
  year = Yr(2029)

  Heat = Select(Enduse,"Heat")

  # Cement          2029
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.0442
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.1395
  xDmFrac[Heat,Waste,     tech,ec,area,year] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2030)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
  end

  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","Waste"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"QC")
  ec = Select(EC,"Fertilizer")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  tech = Select(Tech,"Gas")
  year = Yr(2029)

  Heat = Select(Enduse,"Heat")

  # Fertilizer          2029
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.6000
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.2000
  xDmFrac[Heat,RNG,       tech,ec,area,year] = 0.0800

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2030)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
  end

  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"QC")
  ec = Select(EC,"OtherChemicals")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  tech = Select(Tech,"Gas")
  year = Yr(2028)

  Heat = Select(Enduse,"Heat")

  # OtherChemicals          2029
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.2200
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.2200
  xDmFrac[Heat,RNG,       tech,ec,area,year] = 0.0400

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = collect(Yr(2029):Yr(2030))
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2028)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
  end

  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"QC")
  ec = Select(EC,"PulpPaperMills")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  tech = Select(Tech,"Gas")
  year = Yr(2029)

  Heat = Select(Enduse,"Heat")

  # PulpPaperMills          2029
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.0648
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.1870
  xDmFrac[Heat,RNG,       tech,ec,area,year] = 0.0241

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = Yr(2030)
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
  end

  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"ON")
  ec = Select(EC,"Cement")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  tech = Select(Tech,"Gas")
  year = Yr(2026)

  Heat = Select(Enduse,"Heat")

  # Cement          2026
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.0101
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.1179
  xDmFrac[Heat,RNG,       tech,ec,area,year] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = collect(Yr(2027):Yr(2030))
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2026)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
  end

  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"ON")
  ec = Select(EC,"Fertilizer")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  tech = Select(Tech,"Gas")
  year = Yr(2025)

  Heat = Select(Enduse,"Heat")

  # Cement          2026
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.0258
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.9245
  xDmFrac[Heat,RNG,       tech,ec,area,year] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = collect(Yr(2026):Yr(2030))
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2025)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
  end

  
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end
  #
  ######################
  #

  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  years = collect(Yr(2024):Final)
  for year in years, fuel in fuels, enduse in Enduses
    DmFracMax[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*1.01
      
    DmFracMin[enduse,fuel,tech,ec,area,year] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]*0.99
  end

  #
  ######################
  #

  area = Select(Area,"NS")
  ec = Select(EC,"PulpPaperMills")
  fuels = Select(Fuel,["Hydrogen","PetroCoke","Coal","NaturalGas","RNG"])
  tech = Select(Tech,"Gas")
  year = Yr(2025)

  Heat = Select(Enduse,"Heat")

  # PulpPaperMills          2025
  xDmFrac[Heat,Hydrogen,  tech,ec,area,year] = 0.2722
  xDmFrac[Heat,PetroCoke, tech,ec,area,year] = 0.0000
  xDmFrac[Heat,Coal,      tech,ec,area,year] = 0.0000
  xDmFrac[Heat,NaturalGas,tech,ec,area,year] = 0.3625
  xDmFrac[Heat,RNG,       tech,ec,area,year] = 0.0000

  for fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[Heat,fuel,tech,ec,area,year]
  end

  years = collect(Yr(2026):Yr(2030))
  for year in years, fuel in fuels, enduse in Enduses
    xDmFrac[enduse,fuel,tech,ec,area,year]  = xDmFrac[enduse,fuel,tech,ec,area,Yr(2025)]
  end

  years = collect(Yr(2031):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,tech,ec,area,year] = xDmFrac[enduse,Hydrogen,tech,ec,area,year-1]*0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,year-1]*1.01
  end

  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  
  #
  #######################
  #
  # Hydrogen Production Construction Delay
  # Preliminary value - Jeff Amlin 10/22/19
  #
    years = collect(Yr(2022):Yr(2030))
  for year in years
    H2CD[year] = 1
  end
  
  years = collect(Yr(2031):Final)
  for year in years
    H2CD[year] = 2
  end
  
  WriteDisk(db,"SpInput/H2CD",H2CD)
end

function PolicyControl(db)
  @info "Ind_H2_Demands_RefA.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
