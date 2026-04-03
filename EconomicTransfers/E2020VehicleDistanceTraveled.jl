#
# E2020VehicleDistanceTraveled.jl
#
using EnergyModel

module E2020VehicleDistanceTraveled

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Input::String = "TInput"
  Outpt::String = "TOutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  IsActiveToFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToFuelTOM") # [FuelTOM,ToTOMVariable] "Flag Indicating Which FuelTOMs go into TOM by Variable")
  KM_e::VariableArray{3} = ReadDisk(db,"KOutput/KM_e") # [VehicleTOM,AreaTOM,Year] Kilometers Traveled by Vehicle Type (Millions KM)  
  KMFuel::VariableArray{4} = ReadDisk(db,"KOutput/KMFuel") # [FuelTOM,VehicleTOM,AreaTOM,Year] Vehicle Distance Traveled by Vehicle Type and Fuel (Millions KM)
  KMShare_e::VariableArray{4} = ReadDisk(db,"KOutput/KMShare_e") # [FuelTOM,VehicleTOM,AreaTOM,Year] Fuel Share of Kilometers Traveled by Vehicle Type (KM/KM)  
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapFuelTechECToVehicleFuelTOM::VariableArray{5} = ReadDisk(db,"KInput/MapFuelTechECToVehicleFuelTOM") # [Fuel,TechTrans,ECTrans,FuelTOM,VehicleTOM] Map between Fuel,Tech and FuelTOM
  VDT::VariableArray{5} = ReadDisk(db,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)

  #
  # Scratch Variables
  #
  KMTotal::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Vehicle Distance Traveled by Vehicle Type (KM/Yr)
end

function VehicleDistanceTraveled(data,areas)
  (; AreaTOMs,ECs,Fuels,FuelTOMs,Techs,ToTOMVariable,VehicleTOMs,Years) = data
  (; DmFrac,KMFuel,IsActiveToFuelTOM,MapAreaTOM,MapFuelTechECToVehicleFuelTOM,VDT) = data

  enduse = 1

  totomvariable = Select(ToTOMVariable,"KMShare_e")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)
  
  for year in Years   
    for areatom in AreaTOMs
      for area in areas
        if MapAreaTOM[area,areatom] == 1
          for vehicletom in VehicleTOMs
            for fueltom in fueltoms
              KMFuel[fueltom,vehicletom,areatom,year] = 
                sum(VDT[enduse,tech,ec,area,year]*DmFrac[enduse,fuel,tech,ec,area,year]*
                MapFuelTechECToVehicleFuelTOM[fuel,tech,ec,fueltom,vehicletom]
                for ec in ECs, tech in Techs, fuel in Fuels)*1.60934
            end
          end
        end
      end
    end
  end

end

function CalculateMiles(data)
  (; AreaTOMs,FuelTOMs,ToTOMVariable,VehicleTOMs,Years) = data
  (; KM_e,KMFuel,IsActiveToFuelTOM,KMShare_e) = data

  totomvariable = Select(ToTOMVariable,"KMShare_e")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)
  
  for year in Years, areatom in AreaTOMs, vehicletom in VehicleTOMs
    KM_e[vehicletom,areatom,year] = sum(KMFuel[fueltom,vehicletom,areatom,year] 
      for fueltom in fueltoms)
  end
  for year in Years, areatom in AreaTOMs, vehicletom in VehicleTOMs, fueltom in fueltoms
    @finite_math KMShare_e[fueltom,vehicletom,areatom,year] = 
      KMFuel[fueltom,vehicletom,areatom,year]/KM_e[vehicletom,areatom,year]
  end

end

function VDTControl(db)
  data = MControl(; db)
  (; Nation) = data
  (; ANMap,KM_e,KMFuel,KMShare_e) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas_cn = findall(ANMap[:,CN] .== 1)
  areas_us = findall(ANMap[:,US] .== 1)
  areas = union(areas_cn,areas_us)

  VehicleDistanceTraveled(data,areas)
  CalculateMiles(data)
  
  WriteDisk(db,"KOutput/KMFuel",KMFuel)
  WriteDisk(db,"KOutput/KM_e",KM_e)
  WriteDisk(db,"KOutput/KMShare_e",KMShare_e)

end

function Control(db)
  @info "E2020VehicleDistanceTraveled.jl - Control"
  VDTControl(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
