#
# zFPECCCFSEMH.jl
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

Base.@kwdef struct zFPECCCFSData
  db::String
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  TotDemand::VariableArray{4} = ReadDisk(db,"SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  TotDemandRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  zFPECCCFS::VariableArray{4} = ReadDisk(db,"SOutput/FPECCCFS") # [Fuel,ECC,Area,Year] Fuel Prices w/CFS Price ($/mmBtu)
  zFPECCCFSRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/FPECCCFS") # [Fuel,ECC,Area,Year] Fuel Prices w/CFS Price ($/mmBtu)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  DmdWeight::VariableArray{4} = zeros(Float32,length(Fuel),length(ECC),length(Area),length(Year)) # [Fuel,ECC,Area,Year] Energy Demand Weight (TBtu/Yr)
  KJBtu = 1.054615 # Kilo Joule per BTU
  National::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] National Average Fuel Prices ($/mmBtu)
  NationalRef::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] National Average Fuel Prices ($/mmBtu)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zFPECCCFS_DtaRun(data,iob,nation,CurrencyConversion)
  (; Area,AreaDS,ECC,ECCDS,ECCs,Fuel,Fuels,FuelDS,Nation,NationDS,Year) = data
  (; ANMap,BaseSw,EndTime,ExchangeRateNation) = data
  (; InflationNation,InflationNationRef,TotDemand,TotDemandRef,zFPECCCFS,zFPECCCFSRef) = data
  (; CCC,Conversion,DmdWeight,National,NationalRef,KJBtu,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zFPECCCFSRef = zFPECCCFS
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  #
  # Explicitly select 2020 per e-mail from Robin - Ian 12/2/25
  #
  CDYear = Yr(2020)
  CDTime = "2020"
  
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")

  years = collect(1:Yr(EndTime))

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

  elseif CurrencyConversion == "NominalReference"
    UnitsDS[US] = " Nominal Reference US\$/mmBtu"
    UnitsDS[CN] = " Nominal Reference CN\$/GJ"
  
    for year in years
      Conversion[US,year] = 1
      Conversion[CN,year] = 1/KJBtu
    end  
    
  elseif CurrencyConversion == "RealReference"
    UnitsDS[US] = "$CDTime Reference US\$/mmBtu"
    UnitsDS[CN] = "$CDTime Reference CN\$/GJ"
  
    for year in years
      Conversion[US,year] = 1/InflationNationRef[US,year]*InflationNationRef[US,CDYear]
      Conversion[CN,year] = 1/InflationNationRef[CN,year]*InflationNationRef[CN,CDYear]/KJBtu
    end  
  end  
  
  for fuel in Fuels, year in years
    for area in areas, ecc in ECCs
      DmdWeight[fuel,ecc,area,year] = max(TotDemandRef[fuel,ecc,area,year],0.0)
    end
    @finite_math National[fuel,year] = sum(zFPECCCFS[fuel,ecc,area,year]*DmdWeight[fuel,ecc,area,year] for area in areas, ecc in ECCs)/
                                           sum(DmdWeight[fuel,ecc,area,year] for area in areas, ecc in ECCs)
    @finite_math NationalRef[fuel,year] = sum(zFPECCCFSRef[fuel,ecc,area,year]*DmdWeight[fuel,ecc,area,year] for area in areas, ecc in ECCs)/
                                           sum(DmdWeight[fuel,ecc,area,year] for area in areas, ecc in ECCs)
  end

  for year in years
    for fuel in Fuels
      ZZZ[year] = National[fuel,year]*Conversion[nation,year]
      CCC[year] = NationalRef[fuel,year]*Conversion[nation,year]
      if (ZZZ[year] > 0.000001) || (CCC[year] > 0.000001)
        println(iob,"zFPECCCFSEMH;",Year[year],";",NationDS[nation],";",
          FuelDS[fuel],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
      end
    end
  end
end

function CreatezFPECCCFSOutputFile(db,iob,nationkey,SceName)
  filename = "zFPECCCFSEMH-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end


function zFPECCCFS_DtaControl(db)
  data = zFPECCCFSData(; db)
  (; Nation)= data
  (; NationOutputMap,SceName)= data

  @info "zFPECCCFS_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Fuel;Units;zData;zInitial")
  nations = Select(Nation,["CN"])
  
  for nation in nations
    if NationOutputMap[nation] == 1
      CurrencyConversion="RealPolicy"
      zFPECCCFS_DtaRun(data,iob,nation,CurrencyConversion)
      nationkey = Nation[nation]
      CreatezFPECCCFSOutputFile(data,iob,nationkey,SceName)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
zFPECCCFS_DtaControl(DB)
end

