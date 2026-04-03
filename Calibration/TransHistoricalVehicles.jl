#
# TransHistoricalVehicles.jl
#
using EnergyModel

module TransHistoricalVehicles

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  DER::VariableArray{5} = ReadDisk(db,"$Outpt/DER") # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  THHS::VariableArray{2} = ReadDisk(db,"MOutput/THHS") # [Area,Year] Total Households (Households)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xEnergyPerStock::VariableArray{5} = ReadDisk(db,"$Input/xEnergyPerStock") # [Enduse,Tech,EC,Area,Year] Energy Capital per Vehicle Stock (Btu/Vehicle)
  xVehiclesPerHousehold::VariableArray{2} = ReadDisk(db,"$Input/xVehiclesPerHousehold") # [Area,Year] Vehicles per Household (Vehicle/Household)
  xVehicleStock::VariableArray{3} = ReadDisk(db,"$Input/xVehicleStock") # [Tech,Area,Year] Stock of Vehicles (Vehicles)
end


function TCalibration(db)
  data = TControl(; db)
  (;EC,Enduses,Nation) = data
  (;Tech,Techs,Years) = data
  (;ANMap,DER,THHS,xDEE,xEnergyPerStock,xVehiclesPerHousehold,xVehicleStock) = data

  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)
  passenger = Select(EC,"Passenger")

  for area in cn_areas, year in Years
    xVehiclesPerHousehold[area,year] = sum(xVehicleStock[tech,area,year] for tech in Techs)/THHS[area,year]
  end

  for area in cn_areas, year in Yr(1985):Yr(1989)
    xVehiclesPerHousehold[area,year] = xVehiclesPerHousehold[area,Yr(1990)]
  end

  for area in cn_areas, year in Yr(2018):Final
    xVehiclesPerHousehold[area,year] = xVehiclesPerHousehold[area,Yr(2017)]
  end

  # 
  # Passenger Vehicle Energy Per Vehicle Stock (BTU/Vehicle)
  # 
  techs = Select(Tech,["LDVGasoline","LDVDiesel","LDVNaturalGas","LDVPropane","LDVElectric","LDVHybrid",
            "LDTGasoline","LDTDiesel","LDTNaturalGas","LDTPropane","LDTElectric","LDTHybrid"])
  
  for eu in Enduses, tech in techs, area in cn_areas, year in Years
    @finite_math xEnergyPerStock[eu,tech,passenger,area,year] =
      DER[eu,tech,passenger,area,year]/(xVehicleStock[tech,area,year])
  end

  for eu in Enduses, tech in techs, area in cn_areas, year in Yr(1985):Yr(1989)
    xEnergyPerStock[eu,tech,passenger,area,year] = xEnergyPerStock[eu,tech,passenger,area,Yr(1990)]
  end

  for eu in Enduses, tech in techs, area in cn_areas, year in Yr(2018):Final
    xEnergyPerStock[eu,tech,passenger,area,year] = xEnergyPerStock[eu,tech,passenger,area,Yr(2017)]
  end

  # 
  # Fill missing values for xEnergyPerStock
  # Electric vehicles missing pre-2015 (no energy demands and no DER)
  # 
  ldve = Select(Tech,"LDVElectric")
  ldvg = Select(Tech,"LDVGasoline")
  ldte = Select(Tech,"LDTElectric")
  ldtg = Select(Tech,"LDTGasoline")
  for eu in Enduses, area in cn_areas, year in Yr(1985):Yr(2014)
    @finite_math xEnergyPerStock[eu,ldve,passenger,area,year] = xEnergyPerStock[eu,ldvg,passenger,area,year]*
      xDEE[eu,ldvg,passenger,area,year]/xDEE[eu,ldve,passenger,area,Yr(2015)]
    
      @finite_math xEnergyPerStock[eu,ldte,passenger,area,year] = xEnergyPerStock[eu,ldtg,passenger,area,year]*
        xDEE[eu,ldtg,passenger,area,year]/xDEE[eu,ldte,passenger,area,Yr(2015)]
  end

  WriteDisk(db,"$(data.Input)/xVehiclesPerHousehold",xVehiclesPerHousehold)
  WriteDisk(db,"$(data.Input)/xEnergyPerStock",xEnergyPerStock)
end

function CalibrationControl(db)
  @info "TransHistoricalVehicles.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
