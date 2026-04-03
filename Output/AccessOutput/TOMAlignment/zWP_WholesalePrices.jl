#
# zWP_WholesalePrices.jl - Comparison of TOM baseline values to E2020 transfers
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

Base.@kwdef struct zWP_WholesalePricesData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  WorldTOM::SetArray = ReadDisk(db,"KInput/WorldTOMKey")
  WorldTOMDS::SetArray = ReadDisk(db,"KInput/WorldTOMDS")
  WorldTOMs::Vector{Int} = collect(Select(WorldTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  WPCL::VariableArray{2} = ReadDisk(db,"KOutput/WPCL") # [WorldTOM,Year] Coal Price from TOM (Index of $/Ton (2005=100))
  WPCLe::VariableArray{2} = ReadDisk(db,"KOutput/WPCLe") # [WorldTOM,Year] Coal Price from ENERGY 2020 (Index of $/Ton (2005=100))
  WPGasHH::VariableArray{2} = ReadDisk(db,"KOutput/WPGasHHe") # [WorldTOM,Year] Gas World Price from TOM ($US/mmBtu)
  WPGasHHe::VariableArray{2} = ReadDisk(db,"KOutput/WPGasHHe") # [WorldTOM,Year] Gas World Price from ENERGY 2020 ($US/mmBtu)
  WPO_WCS::VariableArray{2} = ReadDisk(db,"KOutput/WPO_WCSe") # [WorldTOM,Year] Wholesale/global price of oil - WTI from TOM (US$/bbl)
  WPO_WCSe::VariableArray{2} = ReadDisk(db,"KOutput/WPO_WCSe") # [WorldTOM,Year] Wholesale/global price of oil - WTI from E2020 (US$/bbl)
  WPO_WTI::VariableArray{2} = ReadDisk(db,"KOutput/WPO_WTIe") # [WorldTOM,Year] Wholesale/global price of oil - WPO from TOM (US$/bbl)
  WPO_WTIe::VariableArray{2} = ReadDisk(db,"KOutput/WPO_WTIe") # [WorldTOM,Year] Wholesale/global price of oil - WPO from E2020 (US$/bbl)

  #
  # Scratch Variables
  #
  DIF = zeros(Float32,length(Year))
  EEE = zeros(Float32,length(Year))
  PDIF = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
end

function zWP_WholesalePrices_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS,WorldTOMs,Year) = data
  (; BaseSw,EndTime,WPCL,WPCLe,WPGasHH,WPGasHHe) = data
  (; WPO_WCS,WPO_WCSe,WPO_WTI,WPO_WTIe) = data
  (; DIF,EEE,PDIF,TTT,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Fuel;Year;ENERGY2020;TOM;DIF;PercentDIF")

  years = collect(First:Final)

  for worldtom in WorldTOMs
    for year in years
      TTT[year] = WPCL[worldtom,year]
      EEE[year] = WPCLe[worldtom,year]
      DIF[year] = (TTT[year]-EEE[year])
      @finite_math PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
      println(iob,"WPCL;Wholesale Price (Index of \$/Ton 2005=100);Coal",
        ";",Year[year],";",EEE[year],";",TTT[year],
        ";",DIF[year],";",PDIF[year])
    end
  end

  for worldtom in WorldTOMs
    for year in years
      TTT[year] = WPGasHH[worldtom,year]
      EEE[year] = WPGasHHe[worldtom,year]
      DIF[year] = (TTT[year]-EEE[year])
      @finite_math PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
      println(iob,"WPGasHH;Wholesale Price (\$US/mmBtu);Gas",
        ";",Year[year],";",EEE[year],";",TTT[year],
        ";",DIF[year],";",PDIF[year])
    end
  end

  for worldtom in WorldTOMs
    for year in years
      TTT[year] = WPO_WCS[worldtom,year]
      EEE[year] = WPO_WCSe[worldtom,year]
      DIF[year] = (TTT[year]-EEE[year])
      @finite_math PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
      println(iob,"WPO_WCS;Wholesale Price (\$US/bbl);Oil-WCS",
        ";",Year[year],";",EEE[year],";",TTT[year],
        ";",DIF[year],";",PDIF[year])
    end
  end

  for worldtom in WorldTOMs
    for year in years
      TTT[year] = WPO_WTI[worldtom,year]
      EEE[year] = WPO_WTIe[worldtom,year]
      DIF[year] = (TTT[year]-EEE[year])
      @finite_math PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
      println(iob,"WPO_WTI;Wholesale Price (\$US/bbl);Oil-WTI",
        ";",Year[year],";",EEE[year],";",TTT[year],
        ";",DIF[year],";",PDIF[year])
    end
  end


  filename = "zWP_WholesalePrices-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zWP_WholesalePrices_DtaControl(db)
  data = zWP_WholesalePricesData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zWP_WholesalePrices_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  zWP_WholesalePrices_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  zWP_WholesalePrices_DtaRun(data,Nation[US],areatoms)
end
if abspath(PROGRAM_FILE) == @__FILE__
  zWP_WholesalePrices_DtaControl(DB)
end
