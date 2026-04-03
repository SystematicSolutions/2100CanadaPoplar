#
# zMX_ImportsInternational.jl - Comparison of TOM baseline values to E2020 transfers
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

Base.@kwdef struct zMX_ImportsInternationalData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MX::VariableArray{3} = ReadDisk(db,"KOutput/MX") # [FuelAggTOM,AreaTOM,Year] International Imports (TBtu/Yr)
  MXe::VariableArray{3} = ReadDisk(db,"KOutput/MXe") # [FuelAggTOM,AreaTOM,Year] International Imports (TBtu/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  DIF = zeros(Float32,length(Year))
  EEE = zeros(Float32,length(Year))
  PDIF = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
end

function zImportsInternational_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS,FuelAggTOMs,FuelAggTOMDS,Year,SceName) = data
  (; BaseSw,EndTime,MX,MXe) = data
  (; DIF,EEE,PDIF,TTT) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Area;Fuel;Year;ENERGY2020;TOM;DIF;PercentDIF")

  years = collect(First:Final)

  #
  # Energy Production
  #
  for areatom in areatoms
    for fuelaggtom in FuelAggTOMs
      for year in years
        TTT[year] = MX[fuelaggtom,areatom,year]
        EEE[year] = MXe[fuelaggtom,areatom,year]
        DIF[year] = (TTT[year]-EEE[year])
        @finite_math PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
        println(iob,"MX;International Imports (TBtu/Yr);",AreaTOMDS[areatom],
          ";",FuelAggTOMDS[fuelaggtom],";",Year[year],";",EEE[year],";",TTT[year],
          ";",DIF[year],";",PDIF[year])
      end
    end
  end


  filename = "zMX_ImportsInternational-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zMX_ImportsInternational_DtaControl(db)
  data = zMX_ImportsInternationalData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zMX_ImportsInternational_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  zImportsInternational_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  zImportsInternational_DtaRun(data,Nation[US],areatoms)
end
if abspath(PROGRAM_FILE) == @__FILE__
  zMX_ImportsInternational_DtaControl(DB)
end
