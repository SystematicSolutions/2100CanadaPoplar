#
# zFPECCCFSCPNet.jl
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

Base.@kwdef struct zFPECCCFSCPNetData
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

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  TotDemand::VariableArray{4} = ReadDisk(db, "SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  TotDemandRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  vECF::VariableArray{3} = ReadDisk(db,"VBInput/vECF") # [Fuel,Area,Year] Energy Converion Factors (TJ/Various)
  zFPECCCFSCPNet::VariableArray{4} = ReadDisk(db,"SOutput/FPECCCFSCPNet") # [Fuel,ECC,Area,Year] Fuel Prices w/CFS and Net Carbon Price ($/mmBtu)
  zFPECCCFSCPNetRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/FPECCCFSCPNet") # [Fuel,ECC,Area,Year] Fuel Prices w/CFS and Net Carbon Price ($/mmBtu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  DmdWeight::VariableArray{4} = zeros(Float32,length(Fuel),length(ECC),length(Area),length(Year)) # [Fuel,ECC,Area,Year] Energy Demand Weight (TBtu/Yr)
  KJBtu = 1.054615 # Kilo Joule per BTU
  National::VariableArray{3} = zeros(Float32,length(Fuel),length(ECC),length(Year)) # [Fuel,ECC,Year] National Average Fuel Prices ($/mmBtu)
  NationalRef::VariableArray{3} = zeros(Float32,length(Fuel),length(ECC),length(Year)) # [Fuel,ECC,Year] National Average Fuel Prices ($/mmBtu)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  vECFUnits::SetArray = fill("",length(Fuel)) # [Fuel] vECF Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zFPECCCFSCPNet_DtaRun(data,iob,nation,CurrencyConversion)
  (; Area,AreaDS,ECC,ECCDS,ECCs,Fuel,Fuels,FuelDS,Nation,NationDS,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,EndTime,ExchangeRateNation) = data
  (; InflationNation,InflationNationRef,TotDemand,TotDemandRef,zFPECCCFSCPNet,zFPECCCFSCPNetRef) = data
  (; CCC,Conversion,DmdWeight,National,NationalRef,KJBtu,UnitsDS,vECF,vECFUnits,ZZZ) = data

  if BaseSw != 0
    zFPECCCFSCPNetRef = zFPECCCFSCPNet
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  CDYear = max(CDYear,1)
  
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  #
  # Use Last values for future
  #
  years = collect(Last:Yr(2050))
  for fuel in Fuels, area in areas, year in years
    vECF[fuel,area,year]=vECF[fuel,area,Last]
  end
  years = collect(1:Yr(EndTime))

  #
  # vECFUnits isn't currently used in Julia version. Manually read in values from .dat file below
  # - Ian 05/30/25
  #
  vECFUnits[:].= "Blank"
  fuels = Select(Fuel,["AviationGasoline","Biodiesel","Diesel","Ethanol","Gasoline","HFO","JetFuel","Kerosene",
                       "LPG","LFO","Lubricants","Naphtha","NonEnergy","PetroFeed","PetroCoke"])
  for fuel in fuels
    vECFUnits[fuel]= "kl"
  end
  fuels = Select(Fuel,["Biomass","Coal","Coke"])
  for fuel in fuels
    vECFUnits[fuel]= "t"
  end
  fuels = Select(Fuel,["CokeOvenGas","NaturalGas","NaturalGasRaw","StillGas"])
  for fuel in fuels
    vECFUnits[fuel]= "Ml"
  end
  fuels = Select(Fuel,["Electric"])
  for fuel in fuels
    vECFUnits[fuel]= "MWh"
  end
  fuels = Select(Fuel,["RNG","Waste"])
  for fuel in fuels
    vECFUnits[fuel]= "GJ"
  end

  if CurrencyConversion == "NominalPolicy"
    UnitsDS[US] = " Nominal Policy US\$/mmBtu"
    UnitsDS[CN] = " Nominal Policy CN\$/"
  
    for year in years
      Conversion[US,year] = 1
      Conversion[CN,year] = 1/KJBtu
    end  
    
  elseif CurrencyConversion == "RealPolicy"
    UnitsDS[US] = "$CDTime Policy US\$/mmBtu"
    UnitsDS[CN] = "$CDTime Policy CN\$/"
  
    for year in years
      Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
      Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]/KJBtu
    end  

  elseif CurrencyConversion == "NominalReference"
    UnitsDS[US] = " Nominal Reference US\$/mmBtu"
    UnitsDS[CN] = " Nominal Reference CN\$/"
  
    for year in years
      Conversion[US,year] = 1
      Conversion[CN,year] = 1/KJBtu
    end  
    
  elseif CurrencyConversion == "RealReference"
    UnitsDS[US] = "$CDTime Reference US\$/mmBtu"
    UnitsDS[CN] = "$CDTime Reference CN\$/"
  
    for year in years
      Conversion[US,year] = 1/InflationNationRef[US,year]*InflationNationRef[US,CDYear]
      Conversion[CN,year] = 1/InflationNationRef[CN,year]*InflationNationRef[CN,CDYear]/KJBtu
    end  
  end  
  
  for ecc in ECCs, fuel in Fuels, year in years
    for area in areas
      DmdWeight[fuel,ecc,area,year] = max(TotDemandRef[fuel,ecc,area,year],0.0)
    end
    @finite_math National[fuel,ecc,year] = sum(zFPECCCFSCPNet[fuel,ecc,area,year]*DmdWeight[fuel,ecc,area,year] for area in areas)/
                                           sum(DmdWeight[fuel,ecc,area,year] for area in areas)
    @finite_math NationalRef[fuel,ecc,year] = sum(zFPECCCFSCPNetRef[fuel,ecc,area,year]*DmdWeight[fuel,ecc,area,year] for area in areas)/
                                           sum(DmdWeight[fuel,ecc,area,year] for area in areas)
  end

  for year in years
    for ecc in ECCs
      for fuel in Fuels
        #
        # vECF doesn't have an area selected in Promula version, use first(area) here to match - Ian 05/30/25
        #
        areafirst = first(areas)
        ZZZ[year] = National[fuel,ecc,year]*Conversion[nation,year]*vECF[fuel,areafirst,year]
        CCC[year] = NationalRef[fuel,ecc,year]*Conversion[nation,year]*vECF[fuel,areafirst,year]
        if (ZZZ[year] > 0.000001) || (CCC[year] > 0.000001)
          println(iob,"zFPECCCFSCPNet;",Year[year],";",NationDS[nation],";",ECCDS[ecc],";",
            FuelDS[fuel],";",UnitsDS[nation],vECFUnits[fuel],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
        end
      end
    end
  end

  for year in years
    for area in areas
      for ecc in ECCs
        for fuel in Fuels
          @finite_math ZZZ[year] = zFPECCCFSCPNet[fuel,ecc,area,year]*Conversion[nation,year]*vECF[fuel,area,year]*
                                   TotDemand[fuel,ecc,area,year]/TotDemand[fuel,ecc,area,year]
          @finite_math CCC[year] = zFPECCCFSCPNetRef[fuel,ecc,area,year]*Conversion[nation,year]*vECF[fuel,area,year]*
                                   TotDemandRef[fuel,ecc,area,year]/TotDemandRef[fuel,ecc,area,year]
          if (ZZZ[year] > 0.000001) || (CCC[year] > 0.000001)
            println(iob,"zFPECCCFSCPNet;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
              FuelDS[fuel],";",UnitsDS[nation],vECFUnits[fuel],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
          end
        end
      end
    end
  end
end

function CreatezFPECCCFSCPNetOutputFile(db,iob,nationkey,SceName)
  filename = "zFPECCCFSCPNet-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end


function zFPECCCFSCPNet_DtaControl(db)
  data = zFPECCCFSCPNetData(; db)
  (; Nation)= data
  (; NationOutputMap,SceName)= data

  @info "zFPECCCFSCPNet_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Fuel;Units;zData;zInitial")
  nations = Select(Nation,["CN","US"])
  
  for nation in nations
    if NationOutputMap[nation] == 1
      CurrencyConversion="NominalPolicy"
      zFPECCCFSCPNet_DtaRun(data,iob,nation,CurrencyConversion)
      CurrencyConversion="RealPolicy"
      zFPECCCFSCPNet_DtaRun(data,iob,nation,CurrencyConversion)
      nationkey = Nation[nation]
      CreatezFPECCCFSCPNetOutputFile(data,iob,nationkey,SceName)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
zFPECCCFSCPNet_DtaControl(DB)
end
