#
# DmFracMaximum.jl
#
using EnergyModel

module DmFracMaximum

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String
  Last=HisTime-ITime+1

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  #LastDS::SetArray = ReadDisk(db,"MainDB/LastDS")
  #Lasts::Vector{Int} = collect(Select(Last))
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
  xDmFrac::VariableArray{5} = ReadDisk(db,"$Input/xDmFrac",Last) # [Enduse,Fuel,Tech,EC,Area,Last] Energy Demands Fuel/Tech Split (Fraction)

end

function TrendDmFracMax(data,fuel,tech,db)
  (;AreasCanada,ECs,Enduses) = data
  (;DmFracMax) = data
    years=collect(Yr(2024):Yr(2028))
    for eu in Enduses,ec in ECs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]+
                                                (DmFracMax[eu,fuel,tech,ec,area,Yr(2029)]-DmFracMax[eu,fuel,tech,ec,area,Yr(2023)])/(2029-2023)
    end
    years=collect(Yr(2030):Final)
    for eu in Enduses,ec in ECs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]
    end
end

function ResCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;AreasCanada,ECs,Enduses,Fuel) = data
  (;Tech) = data
  (;DmFracMax,xDmFrac) = data
    BiodieselMax=0.35
    Oil = Select(Tech, "Oil")
    Biodiesel = Select(Fuel, "Biodiesel")
    for eu in Enduses,ec in ECs,area in AreasCanada
      DmFracMax[eu,Biodiesel,Oil,ec,area,Yr(2023)]=xDmFrac[eu,Biodiesel,Oil,ec,area]*1.02  
      DmFracMax[eu,Biodiesel,Oil,ec,area,Yr(2029)]=BiodieselMax
    end
    TrendDmFracMax(data,Biodiesel,Oil,db)
    
    Ethanol = Select(Fuel, "Ethanol")
    EthanolMax=0.102
    for eu in Enduses,ec in ECs,area in AreasCanada
      DmFracMax[eu,Ethanol,Oil,ec,area,Yr(2023)]=xDmFrac[eu,Ethanol,Oil,ec,area]*1.02
      DmFracMax[eu,Ethanol,Oil,ec,area,Yr(2029)]=EthanolMax
    end
    TrendDmFracMax(data,Ethanol,Oil,db)
    WriteDisk(db,"$Input/DmFracMax",DmFracMax)
end


Base.@kwdef struct CControl
  db::String
  Last=HisTime-ITime+1

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  #LastDS::SetArray = ReadDisk(db,"MainDB/LastDS")
  #Lasts::Vector{Int} = collect(Select(Last))
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
  xDmFrac::VariableArray{5} = ReadDisk(db,"$Input/xDmFrac",Last) # [Enduse,Fuel,Tech,EC,Area,Last] Energy Demands Fuel/Tech Split (Fraction)

end

function TrendDmFracMax(data,fuel,tech,db)
  (;AreasCanada,ECs,Enduses) = data
  (;DmFracMax) = data
    years=collect(Yr(2024):Yr(2028))
    for eu in Enduses,ec in ECs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]+
                                                (DmFracMax[eu,fuel,tech,ec,area,Yr(2029)]-DmFracMax[eu,fuel,tech,ec,area,Yr(2023)])/(2029-2023)
    end
    years=collect(Yr(2030):Final)
    for eu in Enduses,ec in ECs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]
    end
end

function ComCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;AreasCanada,ECs,Enduses,Fuel) = data
  (;Tech) = data
  (;DmFracMax,xDmFrac) = data
    BiodieselMax=0.35
    Oil = Select(Tech, "Oil")
    Biodiesel = Select(Fuel, "Biodiesel")
    for eu in Enduses,ec in ECs,area in AreasCanada
      DmFracMax[eu,Biodiesel,Oil,ec,area,Yr(2023)]=xDmFrac[eu,Biodiesel,Oil,ec,area]*1.02  
      DmFracMax[eu,Biodiesel,Oil,ec,area,Yr(2029)]=BiodieselMax
    end
    TrendDmFracMax(data,Biodiesel,Oil,db)
    
    Ethanol = Select(Fuel, "Ethanol")
    EthanolMax=0.102
    for eu in Enduses,ec in ECs,area in AreasCanada
      DmFracMax[eu,Ethanol,Oil,ec,area,Yr(2023)]=xDmFrac[eu,Ethanol,Oil,ec,area]*1.02
      DmFracMax[eu,Ethanol,Oil,ec,area,Yr(2029)]=EthanolMax
    end
    TrendDmFracMax(data,Ethanol,Oil,db)
    WriteDisk(db,"$Input/DmFracMax",DmFracMax)
end


Base.@kwdef struct IControl
  db::String
  Last=HisTime-ITime+1

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  #LastDS::SetArray = ReadDisk(db,"MainDB/LastDS")
  #Lasts::Vector{Int} = collect(Select(Last))
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
  xDmFrac::VariableArray{5} = ReadDisk(db,"$Input/xDmFrac",Last) # [Enduse,Fuel,Tech,EC,Area,Last] Energy Demands Fuel/Tech Split (Fraction)

end

function TrendDmFracMax(data,fuel,techs,db)
  (;AreasCanada,ECs,Enduses) = data
  (;DmFracMax) = data
    years=collect(Yr(2024):Yr(2028))
    for eu in Enduses,tech in techs,ec in ECs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]+
                                                (DmFracMax[eu,fuel,tech,ec,area,Yr(2029)]-DmFracMax[eu,fuel,tech,ec,area,Yr(2023)])/(2029-2023)
    end
    years=collect(Yr(2030):Final)
    for eu in Enduses,tech in techs,ec in ECs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]
    end
end

function IndCalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;AreasCanada,ECs,Enduses,Fuel) = data
  (;Tech) = data
  (;DmFracMax,xDmFrac) = data
    BiodieselMax=0.35
    techs = Select(Tech,["Oil","OffRoad"])
    Biodiesel = Select(Fuel, "Biodiesel")
    for eu in Enduses,tech in techs,ec in ECs,area in AreasCanada
      DmFracMax[eu,Biodiesel,tech,ec,area,Yr(2023)]=xDmFrac[eu,Biodiesel,tech,ec,area]*1.02  
      DmFracMax[eu,Biodiesel,tech,ec,area,Yr(2029)]=BiodieselMax
    end
    TrendDmFracMax(data,Biodiesel,techs,db)
    
    Ethanol = Select(Fuel, "Ethanol")
    EthanolMax=0.102
    for eu in Enduses,tech in techs,ec in ECs,area in AreasCanada
      DmFracMax[eu,Ethanol,tech,ec,area,Yr(2023)]=xDmFrac[eu,Ethanol,tech,ec,area]*1.02
      DmFracMax[eu,Ethanol,tech,ec,area,Yr(2029)]=EthanolMax
    end
    TrendDmFracMax(data,Ethanol,techs,db)
    WriteDisk(db,"$Input/DmFracMax",DmFracMax)
end


Base.@kwdef struct TControl
  db::String
  Last=HisTime-ITime+1

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  #LastDS::SetArray = ReadDisk(db,"MainDB/LastDS")
  #Lasts::Vector{Int} = collect(Select(Last))
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
  xDmFrac::VariableArray{5} = ReadDisk(db,"$Input/xDmFrac",Last) # [Enduse,Fuel,Tech,EC,Area,Last] Energy Demands Fuel/Tech Split (Fraction)

end

function TrendDmFracMax(data,fuel,techs,ecs,db)
  (;AreasCanada,Enduses) = data
  (;DmFracMax) = data
    years=collect(Yr(2024):Yr(2028))
    for eu in Enduses,tech in techs,ec in ecs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]+
                                                (DmFracMax[eu,fuel,tech,ec,area,Yr(2029)]-DmFracMax[eu,fuel,tech,ec,area,Yr(2023)])/(2029-2023)
    end
    years=collect(Yr(2030):Final)
    for eu in Enduses,tech in techs,ec in ecs,area in AreasCanada,year in years
      DmFracMax[eu,fuel,tech,ec,area,year]=DmFracMax[eu,fuel,tech,ec,area,year-1]
    end
end

function TransCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;AreasCanada,EC,Enduses,Fuel) = data
  (;Tech) = data
  (;DmFracMax,xDmFrac) = data
    BiodieselMax=0.35
    techs = Select(Tech,["LDVDiesel","LDTDiesel","BusDiesel","TrainDiesel"])
    Biodiesel = Select(Fuel, "Biodiesel")
    Passenger = Select(EC, "Passenger")
    for eu in Enduses,tech in techs,area in AreasCanada
      DmFracMax[eu,Biodiesel,tech,Passenger,area,Yr(2023)]=xDmFrac[eu,Biodiesel,tech,Passenger,area]*1.02  
      DmFracMax[eu,Biodiesel,tech,Passenger,area,Yr(2029)]=BiodieselMax
    end
    TrendDmFracMax(data,Biodiesel,techs,Passenger,db)
    
    techs = Select(Tech,["TrainDiesel","HDV2B3Diesel","HDV45Diesel","HDV67Diesel","HDV8Diesel","MarineLight","MarineHeavy"])
    Biodiesel = Select(Fuel, "Biodiesel")
    Freight = Select(EC, "Freight")
    for eu in Enduses,tech in techs,area in AreasCanada
      DmFracMax[eu,Biodiesel,tech,Freight,area,Yr(2023)]=xDmFrac[eu,Biodiesel,tech,Freight,area]*1.02  
      DmFracMax[eu,Biodiesel,tech,Freight,area,Yr(2029)]=BiodieselMax
    end
    TrendDmFracMax(data,Biodiesel,techs,Freight,db)
    
    Biodiesel = Select(Fuel, "Biodiesel")
    ecs = Select(EC, ["ResidentialOffRoad","CommercialOffRoad","AirPassenger"])
    OffRoad = Select(Tech,"OffRoad")
    for eu in Enduses,ec in ecs, area in AreasCanada
      DmFracMax[eu,Biodiesel,OffRoad,ec,area,Yr(2023)]=xDmFrac[eu,Biodiesel,OffRoad,ec,area]*1.02  
      DmFracMax[eu,Biodiesel,OffRoad,ec,area,Yr(2029)]=BiodieselMax
    end
    TrendDmFracMax(data,Biodiesel,OffRoad,ecs,db)

    EthanolMax=0.102
    techs = Select(Tech,["LDVHybrid","LDTHybrid","LDVGasoline","LDTGasoline","Motorcycle","BusGasoline"])
    Ethanol = Select(Fuel, "Ethanol")
    Passenger = Select(EC, "Passenger")
    for eu in Enduses,tech in techs,area in AreasCanada
      DmFracMax[eu,Ethanol,tech,Passenger,area,Yr(2023)]=xDmFrac[eu,Ethanol,tech,Passenger,area]*1.02  
      DmFracMax[eu,Ethanol,tech,Passenger,area,Yr(2029)]=EthanolMax
    end
    TrendDmFracMax(data,Ethanol,techs,Passenger,db)
    
    techs = Select(Tech,["HDV2B3Gasoline","HDV45Gasoline","HDV67Gasoline","HDV8Gasoline"])
    Freight = Select(EC, "Freight")
    for eu in Enduses,tech in techs,area in AreasCanada
      DmFracMax[eu,Ethanol,tech,Freight,area,Yr(2023)]=xDmFrac[eu,Ethanol,tech,Freight,area]*1.02  
      DmFracMax[eu,Ethanol,tech,Freight,area,Yr(2029)]=EthanolMax
    end
    TrendDmFracMax(data,Ethanol,techs,Freight,db)

    Ethanol = Select(Fuel, "Ethanol")
    ecs = Select(EC, ["ResidentialOffRoad","CommercialOffRoad","AirPassenger"])
    OffRoad = Select(Tech,"OffRoad")
    for eu in Enduses,ec in ecs, area in AreasCanada
      DmFracMax[eu,Ethanol,OffRoad,ec,area,Yr(2023)]=xDmFrac[eu,Ethanol,OffRoad,ec,area]*1.02  
      DmFracMax[eu,Ethanol,OffRoad,ec,area,Yr(2029)]=EthanolMax
    end
    TrendDmFracMax(data,Ethanol,OffRoad,ecs,db)


    Biojet = Select(Fuel, "Biojet")
    BiojetMax=0.10
    ecs = Select(EC,["AirPassenger","AirFreight"])
    techs = Select(Tech,"PlaneJetFuel")
    for eu in Enduses,tech in techs,ec in ecs,area in AreasCanada
      DmFracMax[eu,Biojet,tech,ec,area,Yr(2023)]=0 
      DmFracMax[eu,Biojet,tech,ec,area,Yr(2029)]=BiojetMax
    end
    TrendDmFracMax(data,Biojet,techs,ecs,db)
    
    WriteDisk(db,"$Input/DmFracMax",DmFracMax)
end


function CalibrationControl(db)
  @info "DmFracMaximum.jl - CalibrationControl"

  ResCalibration(db)
  ComCalibration(db)
  IndCalibration(db)
  TransCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
