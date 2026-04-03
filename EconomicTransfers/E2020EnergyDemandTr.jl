#
# E2020EnergyDemandTr.jl - Transfer E2020 transportation demand to TOM variables
#                       Energy intensity, not energy demand is transferred from E2020 to TOM.
#                       To make calculations easier, this file calculates an energy demand variable
#                       in the same categories as energy intensity (FuelTOM and VehicleTOM)
#
using EnergyModel

module E2020EnergyDemandTr

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
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
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
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EnVehicleTOM::VariableArray{4} = ReadDisk(db,"KOutput/EnVehicleTOM") # [FuelTOM,VehicleTOM,AreaTOM,Year] Support Transportation Energy Demand Mapped to VehicleTOM (TBtu)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapFuelTechECToVehicleFuelTOM::VariableArray{5} = ReadDisk(db,"KInput/MapFuelTechECToVehicleFuelTOM") # [Fuel,TechTrans,ECTrans,FuelTOM,VehicleTOM] Map between Fuel,Tech and FuelTOM

  #
  # Scratch Variables
  #
  EnVehicleTOMArea::VariableArray{4} = zeros(Float32,length(FuelTOM),length(VehicleTOM),length(Area),length(Year)) # [FuelTOM,VehicleTOM,Area,Year] Support Transportation Energy Demand Mapped to VehicleTOM (TBtu)
end

function Initialize(data)
  (; AreaTOMs,Areas,ECs,Enduses,FuelTOMs,VehicleTOMs,Techs,Years) = data
  (; Dmd,EnVehicleTOMArea,EnVehicleTOM) = data

  for year in Years, area in Areas, vehicletom in VehicleTOMs, fueltom in FuelTOMs
    EnVehicleTOMArea[fueltom,vehicletom,area,year] = 0
  end

  for year in Years, areatom in AreaTOMs, vehicletom in VehicleTOMs, fueltom in FuelTOMs
    EnVehicleTOM[fueltom,vehicletom,areatom,year] = 0
  end
  
  #
  # Zero out very small values of energy demand
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, year in Years
    if Dmd[enduse,tech,ec,area,year] < 1e-9
      Dmd[enduse,tech,ec,area,year] = 0.0f0
    end 
  end
end

function AggregateEnergy(data)
  (; Area,Areas,AreaTOM,AreaTOMs,Fuel,Fuels,FuelTOM,FuelTOMs) = data
  (; EC,ECs,Tech,Techs,VehicleTOM,VehicleTOMs,Years) = data
  (; Dmd,DmFrac,EnVehicleTOMArea,EnVehicleTOM,MapAreaTOM,MapFuelTechECToVehicleFuelTOM) = data
  
  enduse = 1

  for year in Years, area in Areas
    for vehicletom in VehicleTOMs
      for fueltom in FuelTOMs
        EnVehicleTOMArea[fueltom,vehicletom,area,year] = 
          EnVehicleTOMArea[fueltom,vehicletom,area,year]+
          sum(Dmd[enduse,tech,ec,area,year]*DmFrac[enduse,fuel,tech,ec,area,year]*
            MapFuelTechECToVehicleFuelTOM[fuel,tech,ec,fueltom,vehicletom]
            for ec in ECs, fuel in Fuels, tech in Techs)
      end
    end
  end
    
  for year in Years    
    for areatom in AreaTOMs, area in Areas
      if MapAreaTOM[area,areatom] == 1
        for vehicletom in VehicleTOMs
          for fueltom in FuelTOMs
            EnVehicleTOM[fueltom,vehicletom,areatom,year] =
              EnVehicleTOMArea[fueltom,vehicletom,area,year]
          end
        end
      end
    end 
  end
end

#
########################
#
function Control(db)
  data = MControl(; db)
  (; EnVehicleTOM) = data

  @info "E2020EnergyDemandTr.jl - Control"

  Initialize(data)
  AggregateEnergy(data)
  
  WriteDisk(db,"KOutput/EnVehicleTOM",EnVehicleTOM)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
