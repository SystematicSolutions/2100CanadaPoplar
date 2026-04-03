#
# zFPF.jl
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

Base.@kwdef struct zFPFData
  db::String
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zFPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  zFPFRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  KJBtu = 1.054615 # Kilo Joule per BTU
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zFPF_DtaRun(data,iob,nation,CurrencyConversion)
  (; Area,AreaDS,ES,ESDS,ESs,Fuels,FuelDS,Nation,NationDS,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,EndTime,ExchangeRateNation) = data
  (; InflationNation,zFPF,zFPFRef) = data
  (; CCC,Conversion,KJBtu,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zFPFRef = zFPF
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  CDYear = max(CDYear,1)
  
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")

  if CurrencyConversion == "NominalPolicy"
    UnitsDS[US] = " Nominal Policy US\$/mmBtu"
    UnitsDS[CN] = " Nominal Policy CN\$/GJ"
  
    for year in years
      Conversion[US,year] = 1
      Conversion[CN,year] = 1/KJBtu
    end  
    
  elseif CurrencyConversion == "RealPolicy"
    UnitsDS[US] = "$CDTime Policy US\$/mmBtu"
    UnitsDS[CN] = "$CDTime Policy CN\$/GJ"
  
    for year in years
      Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
      Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]/KJBtu
    end  
  end

  for area in areas
    for es in ESs
      for fuel in Fuels
        for year in years
          ZZZ[year] = zFPF[fuel,es,area,year]*Conversion[nation,year]
          CCC[year] = zFPFRef[fuel,es,area,year]*Conversion[nation,year]
          if (ZZZ[year] > 0.000001) || (CCC[year] > 0.000001)
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zFPF;",Year[year],";",AreaDS[area],";",ESDS[es],";",
              FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end
      end
    end
  end
end

function CreatezFPFOutputFile(db,iob,nationkey,SceName)
  filename = "zFPF-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end


function zFPF_DtaControl(db)
  data = zFPFData(; db)
  (; Nation)= data
  (; NationOutputMap,SceName)= data

  @info "zFPF_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Fuel;Units;zData;zInitial")
  nations = Select(Nation,["CN","US"])
  
  for nation in nations
    if NationOutputMap[nation] == 1
      CurrencyConversion="NominalPolicy"
      zFPF_DtaRun(data,iob,nation,CurrencyConversion)
      CurrencyConversion="RealPolicy"
      zFPF_DtaRun(data,iob,nation,CurrencyConversion)
      nationkey = Nation[nation]
      CreatezFPFOutputFile(data,iob,nationkey,SceName)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
 zFPF_DtaControl(DB)
end
