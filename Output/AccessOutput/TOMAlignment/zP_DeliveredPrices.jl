#
# zP_DeliveredPrices.jl - Comparison of TOM baseline values to E2020 transfers
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

Base.@kwdef struct zP_DeliveredPricesData
  db::String

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PriceTOM::SetArray = ReadDisk(db,"KInput/PriceTOMKey")
  PriceTOMDS::SetArray = ReadDisk(db,"KInput/PriceTOMDS")
  PriceTOMs::Vector{Int} = collect(Select(PriceTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  Pe::VariableArray{3} = ReadDisk(db,"KOutput/Pe") # [PriceTOM,AreaTOM,Year] E2020toTOM Delivered Prices ($/mmBtu)
  P::VariableArray{3} = ReadDisk(db,"KOutput/P") # [PriceTOM,AreaTOM,Year] E2020toTOM Delivered Prices ($/mmBtu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  DIF = zeros(Float32,length(Year))
  EEE = zeros(Float32,length(Year))
  PDIF = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
end

function DeliveredPrices_DtaRun(data,nationkey,areatoms)
  (; AreaTOM,AreaTOMDS,PriceTOM,PriceTOMs,PriceTOMDS,Year) = data
  (; BaseSw,EndTime,P,Pe) = data
  (; DIF,EEE,PDIF,TTT,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Title;Area;PriceTOM;Year;ENERGY2020;TOM;DIF;PercentDIF")

  years = collect(First:Final)
  
  for areatom in areatoms
    for pricetom in PriceTOMs
      for year in years
        TTT[year] = P[pricetom,areatom,year]
        EEE[year] = Pe[pricetom,areatom,year]
        DIF[year] = (TTT[year]-EEE[year])
        PDIF[year] = (TTT[year]-EEE[year])/EEE[year]
        println(iob,"P;Delivered Energy Prices (\$/mmBtu);",AreaTOMDS[areatom],
          ";",PriceTOMDS[pricetom],";",Year[year],";",EEE[year],";",TTT[year],
          ";",DIF[year],";",PDIF[year])
      end
    end
  end

  filename = "zP_DeliveredPrice-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename),"w") do filename
    write(filename, String(take!(iob)))
  end
end

function zP_DeliveredPrices_DtaControl(db)
  data = zP_DeliveredPricesData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "zP_DeliveredPrices_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  DeliveredPrices_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  DeliveredPrices_DtaRun(data,Nation[US],areatoms)
end
if abspath(PROGRAM_FILE) == @__FILE__
  zP_DeliveredPrices_DtaControl(DB)
end
