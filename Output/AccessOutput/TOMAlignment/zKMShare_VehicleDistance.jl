#
# zKMShare_VehicleDistance.jl - Comparison of TOM baseline values to E2020 transfers
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct zKMShare_VehicleDistanceData
  db::String
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMDS::SetArray = ReadDisk(db,"KInput/FuelTOMDS")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMDS::SetArray = ReadDisk(db,"KInput/VehicleTOMDS")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  IsActiveToFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToFuelTOM") # [FuelTOM,ToTOMVariable] "Flag Indicating Which FuelTOMs go into TOM by Variable")
  KMShare::VariableArray{4} = ReadDisk(db,"KOutput/KMShare") # [FuelTOM,VehicleTOM,AreaTOM,Year] Fuel Share of Kilometers Traveled by Vehicle Type (KM/KM)  
  KMShare_e::VariableArray{4} = ReadDisk(db,"KOutput/KMShare_e") # [FuelTOM,VehicleTOM,AreaTOM,Year] Fuel Share of Kilometers Traveled by Vehicle Type (KM/KM)  

  #
  # Scratch Variables
  #
  DIF = zeros(Float32,length(Year))
  EEE = zeros(Float32,length(Year))
  PDIF = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
end

function zKMShare_VehicleDistance_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS,FuelTOM,FuelTOMs,FuelTOMDS,ToTOMVariable) = data
  (; VehicleTOM,VehicleTOMs,VehicleTOMDS,Year) = data
  (; BaseSw,EndTime,IsActiveToFuelTOM,KMShare,KMShare_e) = data
  (; DIF,EEE,PDIF,TTT,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Area;VehicleType;Fuel;Year;ENERGY2020;TOM;DIF;PercentDIF")

  years = collect(First:Final)

  totomvariable = Select(ToTOMVariable,"KMShare_e")
  fueltoms = findall(IsActiveToFuelTOM[:,totomvariable] .== 1)
  
  #
  # Energy Production
  #
  for areatom in areatoms
    @info("areatom = ",AreaTOM[areatom])    
    for vehicletom in VehicleTOMs
      @info("vehicletom = ",VehicleTOM[vehicletom])
      for fueltom in fueltoms
          @info("fueltom = ",FuelTOM[fueltom])
        for year in years
          #
          # TODO: Uncomment out KMShare one Ben fixes issues reading KMShare from TOM. First index is only size 1. 
          #       11/14/25 R.Levesque
          #
          #TTT[year] = KMShare[fueltom,vehicletom,areatom,year]
          EEE[year] = KMShare_e[fueltom,vehicletom,areatom,year]
          DIF[year] = (TTT[year]-EEE[year])
          @finite_math PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
          println(iob,"KMShare,Fuel Share of Kilometers Traveled by Vehicle Type (KM/KM);",AreaTOMDS[areatom],
            ";",VehicleTOMDS[vehicletom],";",FuelTOMDS[fueltom],";",Year[year],";",EEE[year],";",TTT[year],
            ";",DIF[year],";",PDIF[year])
        end
      end
    end
  end


  filename = "zKMShare_VehicleDistance-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zKMShare_VehicleDistance_DtaControl(db)
  data = zKMShare_VehicleDistanceData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zKMShare_VehicleDistance_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  zKMShare_VehicleDistance_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  zKMShare_VehicleDistance_DtaRun(data,Nation[US],areatoms)
end
if abspath(PROGRAM_FILE) == @__FILE__
  zKMShare_VehicleDistance_DtaControl(DB)
end
