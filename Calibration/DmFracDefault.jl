#
# DmFracDefault.jl  - Assigns default values to xDmFrac when the
# current value is zero or negative. 
#
using EnergyModel

module DmFracDefault

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
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")
  
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracSum::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year))  # [Enduse,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracDefault::VariableArray{2} = zeros(Float32,length(Fuel),length(Tech)) # [Fuel,Tech] Default Energy Demands Fuel/Tech Split (Btu/Btu)
end

function ResCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduse,Enduses,Fuel) = data
  (;Fuels,Tech,Techs) = data
  (;Years,Yrv) = data
  (;xDmFrac) = data
  (;DmFracDefault,DmFracSum) = data
  #  
  # Sets Default Energy Demands Fuel/Tech Split
  #
  for fuel in Fuels,tech in Techs
    DmFracDefault[fuel,tech]=0
  end
  
  BiomassFuel = Select(Fuel, "Biomass")
  BiomassTech = Select(Tech, "Biomass")
  CoalFuel = Select(Fuel, "Coal")
  CoalTech = Select(Tech, "Coal")
  DualHPumpTech = Select(Tech, "DualHPump")
  ElectricFuel = Select(Fuel, "Electric")
  ElectricTech = Select(Tech, "Electric")
  GasTech = Select(Tech, "Gas")
  GeothermalTech = Select(Tech, "Geothermal")
  GasTech = Select(Tech, "Gas")
  LFOFuel = Select(Fuel, "LFO")
  LPGFuel = Select(Fuel, "LPG")
  LPGTech = Select(Tech, "LPG")
  HeatPumpTech = Select(Tech, "HeatPump")
  NaturalGasFuel = Select(Fuel, "NaturalGas")
  OilTech = Select(Tech, "Oil")
  SolarTech = Select(Tech, "Solar")
  SteamFuel = Select(Fuel, "Steam")
  SteamTech = Select(Tech, "Steam")
  
  DmFracDefault[ElectricFuel,ElectricTech]=1
  DmFracDefault[NaturalGasFuel,GasTech]=1
  DmFracDefault[CoalFuel,CoalTech]=1
  DmFracDefault[LFOFuel,OilTech]=1
  DmFracDefault[BiomassFuel,BiomassTech]=1
  DmFracDefault[ElectricFuel,SolarTech]=1
  DmFracDefault[LPGFuel,LPGTech]=1
  DmFracDefault[SteamFuel,SteamTech]=1
  DmFracDefault[ElectricFuel,GeothermalTech]=1
  DmFracDefault[ElectricFuel,HeatPumpTech]=1
  DmFracDefault[ElectricFuel,DualHPumpTech]=0.9
  DmFracDefault[NaturalGasFuel,DualHPumpTech]=0.1
  
  # 
  # Assigns default fractions to Enduse/Area/EC/Year otherwise without value.
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas,year in Years
    
    for fuel in Fuels
      if xDmFrac[enduse,fuel,tech,ec,area,year] < 0.0
        xDmFrac[enduse,fuel,tech,ec,area,year] = 0
      end
    end
    
    if Yrv[year]>2040
      DmFracSum[enduse,tech,ec,area,year] = 
        sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
      for fuel in Fuels
        if DmFracSum[enduse,tech,ec,area,year] < 0.00001
          xDmFrac[enduse,fuel,tech,ec,area,year] = 
            xDmFrac[enduse,fuel,tech,ec,area,Yr(2040)]
        end
      end
    end
 
    DmFracSum[enduse,tech,ec,area,year] = 
      sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
    for fuel in Fuels
      if DmFracSum[enduse,tech,ec,area,year] > 0.00001      
        @finite_math xDmFrac[enduse,fuel,tech,ec,area,year] = 
          xDmFrac[enduse,fuel,tech,ec,area,year]/
          DmFracSum[enduse,tech,ec,area,year]
    
      else
        xDmFrac[enduse,fuel,tech,ec,area,year] = DmFracDefault[fuel,tech]

      end
    end
  end
  
  #
  # Fuel for Geothermal, Heat Pump, and Solar is always Electric - Ian 08/12/20
  #
  techs = Select(Tech,["Geothermal","HeatPump","Solar"])
  
  for enduse in Enduses,fuel in Fuels,tech in techs,ec in ECs,area in Areas,year in Years
    xDmFrac[enduse,fuel,tech,ec,area,year]=0.0
  end
  for enduse in Enduses,tech in techs,ec in ECs,area in Areas,year in Years
    xDmFrac[enduse,ElectricFuel,tech,ec,area,year]=1.0
  end
  
  AC=Select(Enduse,"AC")
  for fuel in Fuels,ec in ECs,area in Areas,year in Years
    xDmFrac[AC,fuel,DualHPumpTech,ec,area,year]=0.0
  end
  for ec in ECs,area in Areas,year in Years
    xDmFrac[AC,ElectricFuel,DualHPumpTech,ec,area,year]=1.0
  end
  
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
  
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
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracSum::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year))  # [Enduse,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracDefault::VariableArray{2} = zeros(Float32,length(Fuel),length(Tech)) # [Fuel,Tech] Default Energy Demands Fuel/Tech Split (Btu/Btu)
end

function ComCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,Fuel,Nation) = data
  (;Fuels,Tech,Techs) = data
  (;ANMap,Years,Yrv) = data
  (;xDmFrac) = data
  (;DmFracDefault,DmFracSum) = data
  
  #  
  # Sets Default Energy Demands Fuel/Tech Split
  #
  for fuel in Fuels,tech in Techs
    DmFracDefault[fuel,tech]=0
  end
  
  BiomassFuel = Select(Fuel, "Biomass")
  BiomassTech = Select(Tech, "Biomass")
  CoalFuel = Select(Fuel, "Coal")
  CoalTech = Select(Tech, "Coal")
  DualHPumpTech = Select(Tech, "DualHPump")
  ElectricFuel = Select(Fuel, "Electric")
  ElectricTech = Select(Tech, "Electric")
  GasTech = Select(Tech, "Gas")
  GeothermalTech = Select(Tech, "Geothermal")
  GasTech = Select(Tech, "Gas")
  LFOFuel = Select(Fuel, "LFO")
  LPGFuel = Select(Fuel, "LPG")
  LPGTech = Select(Tech, "LPG")
  HeatPumpTech = Select(Tech, "HeatPump")
  HydroFuel = Select(Fuel, "Hydro")
  NaturalGasFuel = Select(Fuel, "NaturalGas")
  OilTech = Select(Tech, "Oil")
  SolarTech = Select(Tech, "Solar")
  SteamFuel = Select(Fuel, "Steam")
  SteamTech = Select(Tech, "Steam")
  
  DmFracDefault[ElectricFuel,ElectricTech]=1
  DmFracDefault[NaturalGasFuel,GasTech]=1
  DmFracDefault[CoalFuel,CoalTech]=1
  DmFracDefault[LFOFuel,OilTech]=1
  DmFracDefault[BiomassFuel,BiomassTech]=1
  DmFracDefault[ElectricFuel,SolarTech]=1
  DmFracDefault[LPGFuel,LPGTech]=1
  DmFracDefault[SteamFuel,SteamTech]=1
  DmFracDefault[ElectricFuel,GeothermalTech]=1
  DmFracDefault[ElectricFuel,HeatPumpTech]=1
  DmFracDefault[ElectricFuel,DualHPumpTech]=0.9
  DmFracDefault[NaturalGasFuel,DualHPumpTech]=0.1
 
  # 
  # Assigns default fractions to Enduse/Area/EC/Year otherwise without value.
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas,year in Years
    
    for fuel in Fuels
      if xDmFrac[enduse,fuel,tech,ec,area,year] < 0.0
        xDmFrac[enduse,fuel,tech,ec,area,year] = 0
      end
    end
    
    if Yrv[year]>2040
      DmFracSum[enduse,tech,ec,area,year] = 
        sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
      for fuel in Fuels
        if DmFracSum[enduse,tech,ec,area,year] < 0.00001
          xDmFrac[enduse,fuel,tech,ec,area,year] = 
            xDmFrac[enduse,fuel,tech,ec,area,Yr(2040)]
        end
      end
    end
 
    DmFracSum[enduse,tech,ec,area,year] = 
      sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
    for fuel in Fuels
      if DmFracSum[enduse,tech,ec,area,year] > 0.00001      
        @finite_math xDmFrac[enduse,fuel,tech,ec,area,year] = 
          xDmFrac[enduse,fuel,tech,ec,area,year]/
          DmFracSum[enduse,tech,ec,area,year]
    
      else
        xDmFrac[enduse,fuel,tech,ec,area,year] = DmFracDefault[fuel,tech]

      end
    end
  end
  
  #
  # The US reports Small amounts of commercial hydro demands which are
  # moved into electricity
  # 
  us = Select(Nation, "US")
  us_areas = findall(ANMap[:,us] .== 1.0)
  
  for enduse in Enduses,ec in ECs,area in us_areas,year in Years
    xDmFrac[enduse,ElectricFuel,ElectricTech,ec,area,year]=1.0
  end
  
  for enduse in Enduses,ec in ECs,area in us_areas,year in Years
    xDmFrac[enduse,HydroFuel,ElectricTech,ec,area,year]=0.0
  end
  
  #
  # Fuel for Geothermal, Heat Pump, and Solar is always Electric - Ian 08/12/20
  #
  techs = Select(Tech,["Geothermal","HeatPump","Solar"])
  for enduse in Enduses,fuel in Fuels,tech in techs,ec in ECs,area in Areas,year in Years
    xDmFrac[enduse,fuel,tech,ec,area,year]=0.0
  end
  for enduse in Enduses,tech in techs,ec in ECs,area in Areas,year in Years
    xDmFrac[enduse,ElectricFuel,tech,ec,area,year]=1.0
  end
  
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
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
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracSum::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year))  # [Enduse,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracDefault::VariableArray{2} = zeros(Float32,length(Fuel),length(Tech)) # [Fuel,Tech] Default Energy Demands Fuel/Tech Split (Btu/Btu)
end

function IndCalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduse,Enduses,Fuel) = data
  (;Fuels,Tech,Techs) = data
  (;Years,Yrv) = data
  (;xDmFrac) = data
  (;DmFracDefault,DmFracSum) = data
  
  #  
  # Sets Default Energy Demands Fuel/Tech Split
  #
  for fuel in Fuels,tech in Techs
    DmFracDefault[fuel,tech]=0
  end
  
  
  BiomassFuel = Select(Fuel, "Biomass")
  BiomassTech = Select(Tech, "Biomass")
  CoalFuel = Select(Fuel, "Coal")
  CoalTech = Select(Tech, "Coal")
  DieselFuel = Select(Fuel, "Diesel")
  ElectricFuel = Select(Fuel, "Electric")
  ElectricTech = Select(Tech, "Electric")
  GasTech = Select(Tech, "Gas")
  GasTech = Select(Tech, "Gas")
  LFOFuel = Select(Fuel, "LFO")
  LPGFuel = Select(Fuel, "LPG")
  LPGTech = Select(Tech, "LPG")
  NaturalGasFuel = Select(Fuel, "NaturalGas")
  OilTech = Select(Tech, "Oil")
  SolarTech = Select(Tech, "Solar")
  SteamFuel = Select(Fuel, "Steam")
  SteamTech = Select(Tech, "Steam")
  
  DmFracDefault[ElectricFuel,ElectricTech]=1
  DmFracDefault[NaturalGasFuel,GasTech]=1
  DmFracDefault[CoalFuel,CoalTech]=1
  DmFracDefault[LFOFuel,OilTech]=1
  DmFracDefault[BiomassFuel,BiomassTech]=1
  DmFracDefault[ElectricFuel,SolarTech]=1
  DmFracDefault[LPGFuel,LPGTech]=1
  DmFracDefault[SteamFuel,SteamTech]=1
  
  # 
  # Assigns default fractions to Enduse/Area/EC/Year otherwise without value.
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas,year in Years
    
    for fuel in Fuels
      if xDmFrac[enduse,fuel,tech,ec,area,year] < 0.0
        xDmFrac[enduse,fuel,tech,ec,area,year] = 0
      end
    end
    
    if Yrv[year]>2040
      DmFracSum[enduse,tech,ec,area,year] = 
        sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
      for fuel in Fuels
        if DmFracSum[enduse,tech,ec,area,year] < 0.00001
          xDmFrac[enduse,fuel,tech,ec,area,year] = 
            xDmFrac[enduse,fuel,tech,ec,area,Yr(2040)]
        end
      end
    end
 
    DmFracSum[enduse,tech,ec,area,year] = 
      sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
    for fuel in Fuels
      if DmFracSum[enduse,tech,ec,area,year] > 0.00001      
        @finite_math xDmFrac[enduse,fuel,tech,ec,area,year] = 
          xDmFrac[enduse,fuel,tech,ec,area,year]/
          DmFracSum[enduse,tech,ec,area,year]
        
      elseif Enduse[enduse] == "OffRoad" && Tech[tech] == "Oil"
        xDmFrac[enduse,fuel,tech,ec,area,year] = 0
        xDmFrac[enduse,DieselFuel,tech,ec,area,year] = 1
    
      else
        xDmFrac[enduse,fuel,tech,ec,area,year] = DmFracDefault[fuel,tech]

      end
    end
  end

  #
  # Fuel for Geothermal, Heat Pump, and Solar is always Electric - Ian 08/12/20
  #
  techs = Select(Tech,["Solar","HeatPump"])
  for enduse in Enduses,fuel in Fuels,tech in techs,ec in ECs,area in Areas,year in Years
    xDmFrac[enduse,fuel,tech,ec,area,year]=0.0
  end
  for enduse in Enduses,tech in techs,ec in ECs,area in Areas,year in Years
    xDmFrac[enduse,ElectricFuel,tech,ec,area,year]=1.0
  end
  
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)

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
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracSum::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year))  # [Enduse,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  DmFracDefault::VariableArray{2} = zeros(Float32,length(Fuel),length(Tech)) # [Fuel,Tech] Default Energy Demands Fuel/Tech Split (Btu/Btu)
end

function TransCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Areas,EC,ECs,Enduses,Fuel) = data
  (;Fuels,Tech,Techs) = data
  (;Years,Yrv) = data
  (;xDmFrac) = data
  (;DmFracDefault,DmFracSum) = data
  #  
  # Sets Default Energy Demands Fuel/Tech Split
  #
  for fuel in Fuels,tech in Techs
    DmFracDefault[fuel,tech]=0
    if Fuel[fuel]=="Diesel"
      DmFracDefault[fuel,tech]=1
    end
  end
  # 
  # Assume all electric vehicles use electricity as fuel and hybrids
  # split 40/60 electric/gasoline based on "Light-Duty Vehicle Energy
  # Consumption by Technology Type and Fuel Type, Reference case"
  # in the 2011 AEO
  # 
  Passenger = Select(EC, "Passenger")
  techs = Select(Tech,["LDVElectric","LDTElectric"])
  
  for fuel in Fuels,tech in techs
    DmFracDefault[fuel,tech]=0
     if Fuel[fuel]=="Electric"
      DmFracDefault[fuel,tech]=1
     end
  end
 
  # 
  # Assume hybrids split 40/60 electric/gasoline based on "Light-Duty 
  # Vehicle Energy Consumption by Technology Type and Fuel Type, Reference case"
  # in the 2011 AEO
  # 
  techs = Select(Tech,["LDVHybrid","LDTHybrid"])
  
  for fuel in Fuels,tech in techs
    DmFracDefault[fuel,tech]=0
     if Fuel[fuel]=="Electric"
      DmFracDefault[fuel,tech]=0.40
     end
     if Fuel[fuel]=="Electric"
      DmFracDefault[fuel,tech]=0.40
     end
     if Fuel[fuel]=="Gasoline"
      DmFracDefault[fuel,tech]=0.58
     end
     if Fuel[fuel]=="Ethanol"
      DmFracDefault[fuel,tech]=0.02
     end
  end
  
  # 
  # Assigns default fractions to Enduse/Area/EC/Year otherwise without value.
  #
  for enduse in Enduses,tech in Techs,ec in ECs,area in Areas,year in Years
    
    for fuel in Fuels
      if xDmFrac[enduse,fuel,tech,ec,area,year] < 0.0
        xDmFrac[enduse,fuel,tech,ec,area,year] = 0
      end
    end
    
    if Yrv[year]>2040
      DmFracSum[enduse,tech,ec,area,year] = 
        sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
      for fuel in Fuels
        if DmFracSum[enduse,tech,ec,area,year] < 0.00001
          xDmFrac[enduse,fuel,tech,ec,area,year] = 
            xDmFrac[enduse,fuel,tech,ec,area,Yr(2040)]
        end
      end
    end
 
    DmFracSum[enduse,tech,ec,area,year] = 
      sum(xDmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
    for fuel in Fuels
      if DmFracSum[enduse,tech,ec,area,year] > 0.00001      
        @finite_math xDmFrac[enduse,fuel,tech,ec,area,year] = 
          xDmFrac[enduse,fuel,tech,ec,area,year]/
          DmFracSum[enduse,tech,ec,area,year]
    
      else
        xDmFrac[enduse,fuel,tech,ec,area,year] = DmFracDefault[fuel,tech]

      end
    end
  end
 
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
end



function CalibrationControl(db)
  @info "DmFracDefault.jl - CalibrationControl"
  @info "DmFracDefault.jl - Res"
  ResCalibration(db)
  @info "DmFracDefault.jl - Com"
  ComCalibration(db)
  @info "DmFracDefault.jl - Ind"
  IndCalibration(db)
  @info "DmFracDefault.jl - Trans"
  TransCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
