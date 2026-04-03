#
# zKM_VehicleDistance.jl - Comparison of TOM baseline values to E2020 transfers
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

Base.@kwdef struct zKM_VehicleDistanceData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  VehicleTOM::SetArray = ReadDisk(db,"KInput/VehicleTOMKey")
  VehicleTOMDS::SetArray = ReadDisk(db,"KInput/VehicleTOMDS")
  VehicleTOMs::Vector{Int} = collect(Select(VehicleTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  KM::VariableArray{3} = ReadDisk(db,"KOutput/KM") # [VehicleTOM,AreaTOM,Year] Kilometers Traveled by Vehicle Type (Millions KM)  
  KM_e::VariableArray{3} = ReadDisk(db,"KOutput/KM_e") # [VehicleTOM,AreaTOM,Year] Kilometers Traveled by Vehicle Type (Millions KM)  

  #
  # Scratch Variables
  #
  DIF = zeros(Float32,length(Year))
  EEE = zeros(Float32,length(Year))
  PDIF = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
end

function zKM_VehicleDistance_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS,VehicleTOMs,VehicleTOMDS,Year,SceName) = data
  (; BaseSw,EndTime,KM,KM_e) = data
  (; DIF,EEE,PDIF,TTT) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Area;VehicleType;Year;ENERGY2020;TOM;DIF;PercentDIF")

  years = collect(First:Final)

  #
  # Energy Production
  #
  for areatom in areatoms
    for vehicletom in VehicleTOMs
      for year in years
        TTT[year] = KM[vehicletom,areatom,year]
        EEE[year] = KM_e[vehicletom,areatom,year]
        DIF[year] = (TTT[year]-EEE[year])
        @finite_math PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
        println(iob,"KM;Kilometers Traveled by Vehicle Type (Millions KM);",AreaTOMDS[areatom],
          ";",VehicleTOMDS[vehicletom],";",Year[year],";",EEE[year],";",TTT[year],
          ";",DIF[year],";",PDIF[year])
      end
    end
  end


  filename = "zKM_VehicleDistance-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zKM_VehicleDistance_DtaControl(db)
  data = zKM_VehicleDistanceData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zKM_VehicleDistance_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  zKM_VehicleDistance_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  zKM_VehicleDistance_DtaRun(data,Nation[US],areatoms)
end
if abspath(PROGRAM_FILE) == @__FILE__
  zKM_VehicleDistance_DtaControl(DB)
end
