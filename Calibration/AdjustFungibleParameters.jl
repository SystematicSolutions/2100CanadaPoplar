#
# AdjustFungibleParameters.jl
#
using EnergyModel

module AdjustFungibleParameters

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RCalib
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  Last=HisTime-ITime+1

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
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  DmFracMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/DmFracMSM0") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
end

function RCalibration(db)
  data = RCalib(; db)
  (;Input,CalDB,Areas,Fuels,Nation,ECs,Enduses,Tech,Fuel) = data
  (;Techs,Last,Years) = data
  (;ANMap,DmFracMax,DmFracMin,DmFracMSM0,xDmFrac) = data

  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  US = Select(Nation, "US")
  us_areas = findall(ANMap[:,US] .== 1.0)

  Electric = Select(Tech,"Electric")
  Gas = Select(Tech,"Gas")

  RNG = Select(Fuel,"RNG")
  fuels = Select(Fuel,["Biomass","Coal","Coke","PetroCoke","Waste"])

  for year in Years, ec in ECs, eu in Enduses

    for area in us_areas, fuel in Fuels
    
      # 
      # US Hydro and Electricity - constrain since Hydro price is zero. - Jeff Amlin 7/12/2018
      # 
      DmFracMin[eu,fuel,Electric,ec,area,year] = xDmFrac[eu,fuel,Electric,ec,area,year]*0.99
      DmFracMax[eu,fuel,Electric,ec,area,year] = xDmFrac[eu,fuel,Electric,ec,area,year]*1.01
    end

    for area in Areas

      # 
      # Constrain RNG
      # 
      DmFracMin[eu,RNG,Gas,ec,area,year] = xDmFrac[eu,RNG,Gas,ec,area,year]*0.95
      DmFracMax[eu,RNG,Gas,ec,area,year] = xDmFrac[eu,RNG,Gas,ec,area,year]*1.05
    end

    if year > Last

      for area in cn_areas, tech in Techs

        # 
        # Adjust certain fuels to patch issue with calibration forecast - Ian 21/11/25
        # 
        DmFracMSM0[eu,fuels,tech,ec,area,year] = DmFracMSM0[eu,fuels,tech,ec,area,Last]
      end

    end
  end

  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$CalDB/DmFracMSM0",DmFracMSM0)
end

Base.@kwdef struct CCalib
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  Last=HisTime-ITime+1

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
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  DmFracMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/DmFracMSM0") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
end

function CCalibration(db)
  data = CCalib(; db)
  (;Input,CalDB,Areas,Fuels,Nation,ECs,Enduse,Tech,Enduses,Fuel,Techs,Years) = data
  (;ANMap,DmFracMax,DmFracMin,DmFracMSM0,xDmFrac,Last) = data

  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  US = Select(Nation, "US")
  us_areas = findall(ANMap[:,US] .== 1.0)

  Electric = Select(Tech,"Electric")
  Gas = Select(Tech,"Gas")
  Biomass = Select(Tech,"Biomass")

  RNG = Select(Fuel,"RNG")
  bmw = Select(Fuel,["Biomass","Waste"])
  fuels = Select(Fuel,["Biomass","Coal","Coke","PetroCoke","Waste"])

  Heat = Select(Enduse,"Heat")

  for year in Years, ec in ECs, eu in Enduses

    for area in us_areas, fuel in Fuels
    
      # 
      # US Hydro and Electricity - constrain since Hydro price is zero. - Jeff Amlin 7/12/2018
      # 
      DmFracMin[eu,fuel,Electric,ec,area,year] = xDmFrac[eu,fuel,Electric,ec,area,year]*0.99
      DmFracMax[eu,fuel,Electric,ec,area,year] = xDmFrac[eu,fuel,Electric,ec,area,year]*1.01
    end

    for area in Areas

      # 
      # Constrain RNG
      # 
      DmFracMin[eu,RNG,Gas,ec,area,year] = xDmFrac[eu,RNG,Gas,ec,area,year]*0.95
      DmFracMax[eu,RNG,Gas,ec,area,year] = xDmFrac[eu,RNG,Gas,ec,area,year]*1.05
    end

    if year > Last

      for area in Areas
        DmFracMin[Heat,bmw,Biomass,ec,area,year] = xDmFrac[Heat,bmw,Biomass,ec,area,year]*0.99
        DmFracMax[Heat,bmw,Biomass,ec,area,year] = xDmFrac[Heat,bmw,Biomass,ec,area,year]*1.01  
      end

      for area in cn_areas, tech in Techs

        # 
        # Adjust certain fuels to patch issue with calibration forecast - Ian 21/11/25
        # 
        DmFracMSM0[eu,fuels,tech,ec,area,year] = DmFracMSM0[eu,fuels,tech,ec,area,Last]
      end

    end
  end

  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$CalDB/DmFracMSM0",DmFracMSM0)

end

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  Last=HisTime-ITime+1

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
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  DmFracMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/DmFracMSM0") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
end

function ICalibration(db)
  data = ICalib(; db)
  (;Input,CalDB,Area,Areas,EC,ECs,Enduse,Enduses,Fuel) = data
  (;Fuels,Nation,Tech,Techs,Years) = data
  (;ANMap,DmFracMax,DmFracMin,DmFracMSM0,xDmFrac,Last) = data

  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  US = Select(Nation, "US")
  us_areas = findall(ANMap[:,US] .== 1.0)

  QC = Select(Area,"QC")
  ON = Select(Area,"ON")

  Oil = Select(Tech,"Oil")
  Electric = Select(Tech,"Electric")
  Gas = Select(Tech,"Gas")
  Biomass = Select(Tech,"Biomass")
  OffRoad = Select(Tech,"OffRoad")

  Hydrogen = Select(Fuel,"Hydrogen")
  PetroCoke = Select(Fuel,"PetroCoke")
  gas = Select(Fuel,["NaturalGasRaw","StillGas","CokeOvenGas"])
  bmw = Select(Fuel,["Biomass","Waste"])
  fuels = Select(Fuel,["Biomass","Coal","Coke","PetroCoke","Waste"])

  Heat = Select(Enduse,"Heat")
  
  Petroleum = Select(EC,"Petroleum")
  Cement = Select(EC,"Cement")

  for year in Years, ec in ECs, eu in Enduses

    for area in Areas, fuel in Fuels

      # 
      # Raw Natural Gas and Still Gas are constrained - Jeff Amlin 5/9/2018
      # 
      DmFracMin[eu,fuel,Gas,ec,area,year] = xDmFrac[eu,fuel,Gas,ec,area,year]*0.10
      DmFracMin[eu,gas,Gas,ec,area,year] = xDmFrac[eu,gas,Gas,ec,area,year]*0.98
      DmFracMax[eu,gas,Gas,ec,area,year] = xDmFrac[eu,gas,Gas,ec,area,year]*1.02

      # 
      # Off-Road fuel switching is constrained - from Fred Roy-Vigneault, Jeff Amlin 9/28/21 
      # 
      DmFracMin[eu,fuel,OffRoad,ec,area,year] = xDmFrac[eu,fuel,OffRoad,ec,area,year]*0.98
      DmFracMax[eu,fuel,OffRoad,ec,area,year] = xDmFrac[eu,fuel,OffRoad,ec,area,year]*1.02

      # 
      # Add minimum level of Hydrogen Demand to generate a Hydrogen Price 9/2/21
      # 
      DmFracMin[eu,Hydrogen,Gas,Petroleum,area,year] = max(xDmFrac[eu,Hydrogen,Gas,Petroleum,area,year],0.000001)*0.99
      DmFracMax[eu,Hydrogen,Gas,Petroleum,area,year] = max(xDmFrac[eu,Hydrogen,Gas,Petroleum,area,year],0.000001)*1.01
    end

    for area in us_areas, fuel in Fuels

      # 
      # US Petroleum Coke - this is needed at least until we move PetroCoke to
      # the Coal Tech. - Jeff Amlin 5/8/2018
      # 
      DmFracMin[eu,fuel,Oil,ec,area,year] = xDmFrac[eu,fuel,Oil,ec,area,year]*0.10
      DmFracMax[eu,PetroCoke,Oil,ec,area,year] = xDmFrac[eu,PetroCoke,Oil,ec,area,year]*1.02

      # 
      # US Hydro and Electricity - constrain since Hydro price is zero. - Jeff Amlin 7/12/2018
      # 
      DmFracMin[eu,fuel,Electric,ec,area,year] = xDmFrac[eu,fuel,Electric,ec,area,year]*0.99
      DmFracMax[eu,fuel,Electric,ec,area,year] = xDmFrac[eu,fuel,Electric,ec,area,year]*1.01
    end

    if year > Last
      DmFracMin[Heat,bmw,Biomass,Cement,QC,year] = xDmFrac[Heat,bmw,Biomass,Cement,QC,year]*0.99
      DmFracMax[Heat,bmw,Biomass,Cement,QC,year] = xDmFrac[Heat,bmw,Biomass,Cement,QC,year]*1.01

      #
      # Also contrain ON Cement to match historical inputs from Timothy - Ian 09/11/25
      #
      DmFracMin[Heat,bmw,Biomass,Cement,ON,year] = xDmFrac[Heat,bmw,Biomass,Cement,ON,Last]*0.99
      DmFracMax[Heat,bmw,Biomass,Cement,ON,year] = xDmFrac[Heat,bmw,Biomass,Cement,ON,Last]*1.01

      for area in cn_areas, tech in Techs

        # 
        # Adjust certain fuels to patch issue with calibration forecast - Ian 21/11/25
        # 
        DmFracMSM0[eu,fuels,tech,ec,area,year] = DmFracMSM0[eu,fuels,tech,ec,area,Last]
      end

    end

  end

  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$CalDB/DmFracMSM0",DmFracMSM0)
end

Base.@kwdef struct TCalib
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  Last=HisTime-ITime+1

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
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  DmFracMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/DmFracMSM0") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
end

function TCalibration(db)
  data = TCalib(; db)
  (;Input,CalDB,Areas,EC,ECs,Enduses,Fuel) = data
  (;Fuels,Nation,Tech,Techs,Years) = data
  (;ANMap,DmFracMax,DmFracMin,DmFracMSM0,xDmFrac,Last) = data

  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  OffRoad = Select(Tech,"OffRoad")

  fuels = Select(Fuel,["Biomass","Coal","Coke","PetroCoke","Waste"])

  ecs = Select(EC,["ResidentialOffRoad","CommercialOffRoad"])


  for year in Years, eu in Enduses

    for area in Areas, fuel in Fuels
      DmFracMin[eu,fuel,OffRoad,ecs,area,year] = xDmFrac[eu,fuel,OffRoad,ecs,area,year]*0.99
      DmFracMax[eu,fuel,OffRoad,ecs,area,year] = xDmFrac[eu,fuel,OffRoad,ecs,area,year]*1.01
    end

    for area in cn_areas, ec in ECs, tech in Techs
      # 
      # Adjust certain fuels to patch issue with calibration forecast - Ian 21/11/25
      # 
      DmFracMSM0[eu,fuels,tech,ec,area,year] = DmFracMSM0[eu,fuels,tech,ec,area,Last]
    end

  end

  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$CalDB/DmFracMSM0",DmFracMSM0)
end

function CalibrationControl(db)
  @info "AdjustFungibleParameters.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
