#
# E2020EnergyIntensityTr.jl
#
using EnergyModel

module E2020EnergyIntensityTr

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMDS::SetArray = ReadDisk(db,"KInput/FuelTOMDS")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMDS::SetArray = ReadDisk(db,"KInput/VehicleTOMDS")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EIntTr::VariableArray{4} = ReadDisk(db,"KOutput/EIntTr") # [FuelTOM,VehicleTOM,AreaTOM,Year] Transportation Energy Intensity (mmBtu/Thousand KM)
  EIntETr::VariableArray{4} = ReadDisk(db,"KOutput/EIntETr") # [FuelTOM,VehicleTOM,AreaTOM,Year] Transportation Energy Intensity (mmBtu/Thousand KM)
  EnVehicleTOM::VariableArray{4} = ReadDisk(db,"KOutput/EnVehicleTOM") # [FuelTOM,VehicleTOM,AreaTOM,Year] Transportation Energy Demand Mapped to VehicleTOM (TBtu)
  IsActiveToFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToFuelTOM") # [FuelTOM,ToTOMVariable] "Flag Indicating Which FuelTOMs go into TOM by Variable")
  KMFuel::VariableArray{4} = ReadDisk(db,"KOutput/KMFuel") # [FuelTOM,VehicleTOM,AreaTOM,Year] Vehicle Distance Traveled by Vehicle Type and Fuel (Million KM)
  # MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  # VDT::VariableArray{5} = ReadDisk(db,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)

  # Scratch Variables
end

function EIntensityTransport(db)
  data = MControl(; db)
  (; AreaTOM,AreaTOMs,FuelTOM,FuelTOMs,ToTOMVariable,VehicleTOM,VehicleTOMs,Years) = data
  (; EIntTr,EIntETr,EnVehicleTOM,IsActiveToFuelTOM,KMFuel) = data

  totomvariable = Select(ToTOMVariable,"EIntETr")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)

  for vehicletom in VehicleTOMs, fueltom in fueltoms
    for year in Years, areatom in AreaTOMs
      @finite_math EIntETr[fueltom,vehicletom,areatom,year] = 
                   EnVehicleTOM[fueltom,vehicletom,areatom,year]/
                  (KMFuel[fueltom,vehicletom,areatom,year]/1000)
    end
  end
  
  #
  # LPG may be too small to calculate an intensity - Jeff Amlin 6/3/25
  #
  Gasoline = Select(FuelTOM,"Gasoline")
  LPG = Select(FuelTOM,"LPG")
  LDV = Select(VehicleTOM,"LDV")
  for year in Years, areatom in AreaTOMs
    if KMFuel[LPG,LDV,areatom,year] < 0.00001
      EIntETr[LPG,LDV,areatom,year] = EIntETr[Gasoline,LDV,areatom,year]
    end
  end

  #
  # Patch: Overwrite HDV, Biofuel until Tanoak is reviewed - R.Levesque 6/4/25
  #
  Biofuel = Select(FuelTOM,"Biofuel")
  HDV = Select(VehicleTOM,"HDV")
  for year in Years, areatom in AreaTOMs
    EIntETr[Biofuel,HDV,areatom,year] = EIntTr[Biofuel,HDV,areatom,year]
  end

  #
  # Patch: Overwrite Bus, Diesel until Tanoak is reviewed - R.Levesque 6/4/25
  #
  Diesel = Select(FuelTOM,"Diesel")
  Bus = Select(VehicleTOM,"Bus")
  for year in Years, areatom in AreaTOMs
    EIntETr[Diesel,Bus,areatom,year] = EIntTr[Diesel,Bus,areatom,year]
  end

  #
  # Patch: Overwrite Bus, Gasoline in NL until Tanoak is reviewed - R.Levesque 6/4/25
  #
  Gasoline = Select(FuelTOM,"Gasoline")
  Bus = Select(VehicleTOM,"Bus")
  NL = Select(AreaTOM,"NL")
  for year in Years
    EIntETr[Gasoline,Bus,NL,year] = EIntTr[Gasoline,Bus,NL,year]
  end

  WriteDisk(db,"KOutput/EIntETr",EIntETr)

end

function Control(db)
  @info "E2020EnergyIntensityTr.jl - Control"
  EIntensityTransport(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
