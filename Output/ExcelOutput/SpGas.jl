#
# SpGas.jl
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

Base.@kwdef struct SpGasData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))

  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))

  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))

  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))

  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  
  Process::SetArray = ReadDisk(db, "MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db, "MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  eCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") # [Fuel,Nation,Year] Primary Fuel Price ($/mmBtu)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  Exports::VariableArray{3} = ReadDisk(db, "SpOutput/Exports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  ExportsMin::VariableArray{3} = ReadDisk(db, "SpInput/ExportsMin") # [FuelEP,Nation,Year] Exports Minimum (TBtu/Yr)
  FlGProd::VariableArray{2} = ReadDisk(db, "SOutput/FlGProd") # [Nation,Year] Natural Gas Produced from Flaring Reductions (TBtu/Yr)
  FuGProd::VariableArray{2} = ReadDisk(db, "SOutput/FuGProd") # [Nation,Year] Natural Gas Produced from Other Fugitives Reductions (TBtu/Yr)
  GADemand::VariableArray{2} = ReadDisk(db, "SpOutput/GADemand") # [Area,Year] Gas Demand (TBtu/Yr)
  GAProd::VariableArray{3} = ReadDisk(db, "SOutput/GAProd") # [Process,Area,Year] Primary Gas Production (TBtu/Yr)
  GDemand::VariableArray{2} = ReadDisk(db, "SOutput/GDemand") # [Nation,Year] Gas Demand (TBtu/Yr)
  GLosses::VariableArray{2} = ReadDisk(db, "SOutput/GLosses") # [Nation,Year] Natural Gas Losses (TBtu/Yr) 
  GMarket::VariableArray{2} = ReadDisk(db, "SOutput/GMarket") # [Nation,Year] Marketable Gas Production (TBtu/Yr)
  GMMult::VariableArray{2} = ReadDisk(db, "SInput/GMMult") # [Nation,Year] Marketable Gas Production Multiplier (TBtu/TBtu)
  GOMult::VariableArray{3} = ReadDisk(db, "SOutput/GOMult") # [ECC,Area,Year] Gross Output Multiplier ($/$)
  GOMSmooth::VariableArray{3} = ReadDisk(db, "SOutput/GOMSmooth") # [ECC,Area,Year] Smooth of Gross Output Multiplier ($/$)
  GPRAMap::VariableArray{4} = ReadDisk(db, "SpInput/GPRAMap") # [Area,Process,Nation,Year] Provincial Gas Fraction (Btu/Btu)
  GProd::VariableArray{3} = ReadDisk(db, "SOutput/GProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  GPrTax::VariableArray{2} = ReadDisk(db, "SpOutput/GPrTax") # [Nation,Year] Natural Gas Production Tax ($/mmBtu)
  GPUC::VariableArray{3} = ReadDisk(db, "SpInput/GPUC") # [Process,Nation,Year] Gas Production Unit Full Cost ($/mmBtu)
  GRaw::VariableArray{2} = ReadDisk(db, "SOutput/GRaw") # [Nation,Year] Raw Natural Gas Demand (TBtu/Yr)
  GSElas::VariableArray{2} = ReadDisk(db, "SpInput/GSElas") # [Process,Nation] Gas Price Elasticity to Change Supply
  GSM::VariableArray{3} = ReadDisk(db, "SpOutput/GSM") # [Process,Nation,Year] Gas Supply Multiplier from Price Changes
  GSMSw::VariableArray{1} = ReadDisk(db, "SpInput/GSMSw") # [Year] Gas Supply Multiplier from Price Changes Switch
  GSPElas::VariableArray{1} = ReadDisk(db, "SpInput/GSPElas") # [Year] Gas Supply Elasticity to Change Prices
  GSPM::VariableArray{1} = ReadDisk(db, "SpOutput/GSPM") # [Year] Gas Price Multiplier from Supply Changes ($/$)
  GSPMSw::VariableArray{1} = ReadDisk(db, "SpInput/GSPMSw") # [Year] Gas Price Multiplier from Supply Changes Switch
  Imports::VariableArray{3} = ReadDisk(db, "SpOutput/Imports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  ImportsMin::VariableArray{3} = ReadDisk(db, "SpInput/ImportsMin") # [FuelEP,Nation,Year] Imports Minimum (TBtu/Yr)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  LNGProdMin::VariableArray{2} = ReadDisk(db, "SOutput/LNGProdMin") # [Nation,Year] Minimum LNG Production (TBtu/Yr)
  SupplyAdjustments::VariableArray{3} = ReadDisk(db, "SpOutput/SupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)
  TotDemand::VariableArray{4} = ReadDisk(db, "SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  VnGProd::VariableArray{2} = ReadDisk(db, "SOutput/VnGProd") # [Nation] Natural Gas Produced from Venting Reductions (TBtu/Yr)
  xENPN::VariableArray{3} = ReadDisk(db, "SInput/xENPN") # [Fuel,Nation,Year] Exogenous Primary Fuel Price ($/mmBtu)
  xExports::VariableArray{3} = ReadDisk(db, "SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xGProd::VariableArray{3} = ReadDisk(db, "SInput/xGProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  xImports::VariableArray{3} = ReadDisk(db, "SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xSupplyAdjustments::VariableArray{3} = ReadDisk(db, "SpInput/xSupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)
end

function SpGas_DtaRun(data)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Fuel,FuelDS,Fuels) = data
  (; FuelEP,FuelEPDS,FuelEPs,Nation,NationDS,Nations) = data
  (; Process,ProcessDS,Processes,Year,CDTime,CDYear) = data
  (; ANMap,SceName,eCO2Price,ENPN,ExchangeRateNation,Exports) = data
  (; ExportsMin,FlGProd,FuGProd,GADemand,GAProd,GDemand) = data
  (; GLosses,GMarket,GMMult,GOMult,GOMSmooth,GPRAMap) = data
  (; GProd,GPrTax,GPUC,GRaw,GSElas,GSM,GSMSw,GSPElas) = data
  (; GSPM,GSPMSw,Imports,ImportsMin,InflationNation) = data
  (; LNGProdMin,SupplyAdjustments,TotDemand,VnGProd) = data
  (; xENPN,xExports,xGProd,xImports,xSupplyAdjustments) = data

  iob = IOBuffer()

  AAA = zeros(Float32, length(Area))
  DDD = zeros(Float32, length(Year))
  QQQ = zeros(Float32, length(Process))
  SSS = zeros(Float32, length(Year))
  WWW = zeros(Float32, length(Year))
  YYY = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))

  CapturedGas = zeros(Float32, length(Nation), length(Year))
  TProd = zeros(Float32, length(Nation), length(Year))

  CN = Select(Nation,"CN")
  areas_cn = Select(Area,(from ="ON", to="NU"))
  fuels = Select(Fuel,["NaturalGas","NaturalGasRaw"])
  fueleps = Select(FuelEP,["NaturalGas","NaturalGasRaw"])
  nations = Select(Nation,["US","CN","MX"])
  areas_n = Select(Area,!=("ROW"))
  processes_t = Select(Process,!=("OilSandsUpgraders"))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the SpGas Summary.")
  println(iob, " ")

  # year = Select(Year, (from = "1990", to = "2050"))
  years = collect(Yr(1990):Final)
  # year = Select(Year)

  processes = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction"])

  for year in years, nation in Nations
      TProd[nation,year]=sum(GProd[process,nation,year] for process in processes)
      CapturedGas[nation,year] = VnGProd[nation,year]+FuGProd[nation,year]+FlGProd[nation,year]
  end

  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  #
  # Supply Balance
  #
  print(iob, "North America Natural Gas Supply Demand Balance (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  
  #
  # Demand
  #
  for year in years
    DDD[year]=sum(GLosses[nation,year] + GDemand[nation,year] + GRaw[nation,year] for nation in nations) 
    DDD[year]=DDD[year] + sum(Exports[fuelep,nation,year] for nation in nations, fuelep in fueleps)
  end
  print(iob, "Total Demand;Total Demand")
  for year in years
    print(iob,";",@sprintf("%15.4f",DDD[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(GDemand[nation,year] for nation in nations)
  end 
  print(iob, "  GDemand;  TotDemand NG")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(GRaw[nation,year] for nation in nations) 
  end
  print(iob, "  GRaw;  TotDemand NG Raw")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(GLosses[nation,year] for nation in nations) 
  end
  print(iob, "  GLosses;  Direct Emissions")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(Exports[fuelep,nation,year] for nation in nations, fuelep in fueleps)
  end
  print(iob, "  Exports;  Total Exports")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  lngprod = Select(Process,"LNGProduction")
  for year in years
    YYY[year]=sum(GProd[lngprod,nation,year] for nation in nations)
  end
  print(iob, "    GProd(LNG);    LNG Exports")
  for year in years
    print(iob,";",@sprintf("%15.4f",YYY[year]))
  end
  println(iob)

  for year in years
    WWW[year]=ZZZ[year]-YYY[year]
  end
  print(iob, "    Exports-GProd(LNG);    Pipeline Exports")
  for year in years
    print(iob,";",@sprintf("%15.4f",WWW[year]))
  end
  println(iob)

  # 
  # Supply
  #
  for year in years
    SSS[year]=sum(TProd[nation,year] for nation in nations)
    SSS[year]=SSS[year]+sum(Imports[fuelep,nation,year] + SupplyAdjustments[fuelep,nation,year] for nation in nations, fuelep in fueleps) 
  end
  print(iob, "Total Supply;Total Supply")
  for year in years
    print(iob,";",@sprintf("%15.4f",SSS[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(TProd[nation,year] for nation in nations)
  end
  print(iob, "  TProd;  Domestic Production")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(GMarket[nation,year] for nation in nations)
  end
  print(iob, "  GMarket;  Marketable Production")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(CapturedGas[nation,year] for nation in nations)
  end
  print(iob, "      GCaptured;      In GMarket")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(GRaw[nation,year] for nation in nations)
  end
  print(iob, "    GRaw;    Raw NG Demand")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(GLosses[nation,year] for nation in nations)
  end
  print(iob, "    GLosses;    Losses")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(Imports[fuelep,nation,year] for nation in nations, fuelep in fueleps)
  end
  print(iob, "  Imports;  Imports")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=sum(SupplyAdjustments[fuelep,nation,year] for nation in nations, fuelep in fueleps)
  end
  print(iob, "  SupplyAdjustments;  Supply Adjustments")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year]=SSS[year]-DDD[year]
  end
  print(iob, "Supply Balance;Supply minus Demand")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    SSS[year]=sum(GMarket[nation,year] for nation in nations)
    DDD[year]=sum(GDemand[nation,year] for nation in nations)
    DDD[year]=DDD[year]+sum(SupplyAdjustments[fuelep,nation,year] for nation in nations, fuelep in fueleps) 
  end
  for year in years
    @finite_math ZZZ[year]=SSS[year]/DDD[year]
  end
  print(iob, "Supply Ratio;Supply/Demand")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  println(iob)

  for nation in Nations
    print(iob, NationDS[nation], " Natural Gas Supply Demand Balance (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)

    #
    # Demand
    #
    for year in years
      DDD[year]=GLosses[nation,year] + GDemand[nation,year] + GRaw[nation,year]
      DDD[year]=DDD[year] + sum(Exports[fuelep,nation,year] for fuelep in fueleps)
    end
    print(iob, "Total Demand;Total Demand")
    for year in years
      print(iob,";",@sprintf("%15.4f",DDD[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=GDemand[nation,year]
    end
    print(iob, "  GDemand;  TotDemand NG")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=GRaw[nation,year] 
    end
    print(iob, "  GRaw;  TotDemand NG Raw")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=GLosses[nation,year]
    end
    print(iob, "  GLosses;  Direct Emissions")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=sum(Exports[fuelep,nation,year] for fuelep in fueleps)
    end
    print(iob, "  Exports;  Total Exports")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    lngprod = Select(Process,"LNGProduction")
    for year in years
      YYY[year]=GProd[lngprod,nation,year]
    end
    print(iob, "    GProd(LNG);    LNG Exports")
    for year in years
      print(iob,";",@sprintf("%15.4f",YYY[year]))
    end
    println(iob)

    for year in years
      WWW[year]=ZZZ[year]-YYY[year]
    end
    print(iob, "    Exports-GProd(LNG);    Pipeline Exports")
    for year in years
      print(iob,";",@sprintf("%15.4f",WWW[year]))
    end
    println(iob)

    # 
    # Supply
    #
    for year in years
      SSS[year]=TProd[nation,year] + sum(Imports[fuelep,nation,year] +
        SupplyAdjustments[fuelep,nation,year] for fuelep in fueleps) 
    end  
    print(iob, "Total Supply;Total Supply")
    for year in years
      print(iob,";",@sprintf("%15.4f",SSS[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=TProd[nation,year]
    end
    print(iob, "  TProd;  Domestic Production")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=GMarket[nation,year]
    end
    print(iob, "  GMarket;  Marketable Production")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=CapturedGas[nation,year]
    end
    print(iob, "      GCaptured;      In GMarket")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=GRaw[nation,year]
    end
    print(iob, "    GRaw;    Raw NG Demand")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=GLosses[nation,year]
    end
    print(iob, "    GLosses;    Losses")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=sum(Imports[fuelep,nation,year] for fuelep in fueleps)
    end
    print(iob, "  Imports;  Imports")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=sum(SupplyAdjustments[fuelep,nation,year] for fuelep in fueleps)
    end
    print(iob, "  SupplyAdjustments;  Supply Adjustments")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      ZZZ[year]=SSS[year]-DDD[year]
    end
    print(iob, "Supply Balance;Supply minus Demand")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    for year in years
      SSS[year]=GMarket[nation,year]
      DDD[year]=GDemand[nation,year] + sum(SupplyAdjustments[fuelep,nation,year] for fuelep in fueleps) 
    end
    for year in years
      @finite_math ZZZ[year]=SSS[year]/DDD[year]
    end
    print(iob, "Supply Ratio;Supply/Demand")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    println(iob)

  end

  print(iob, "Gas Demand (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GDemand[nation,year] for nation in Nations)
  end
  print(iob, "GDemand;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = GDemand[nation,year]
    end
    print(iob, "GDemand;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  for fuel in fuels
    print(iob, FuelDS[fuel], " Demand (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(TotDemand[fuel,ecc,area,year] for area in Areas, ecc in ECCs)
    end
    print(iob, "TotDemand;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for nation in Nations
      areas = findall(ANMap[:,nation] .== 1)
      for year in years
        ZZZ[year] = sum(TotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs)
      end
      print(iob, "TotDemand;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  print(iob, "Gas Supply (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GMarket[nation,year] for nation in Nations)
  end
  print(iob, "GMarket;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = GMarket[nation,year]
    end
    print(iob, "GMarket;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  for process in processes
    print(iob, ProcessDS[process], " Primary Gas Production (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(GProd[process,nation,year] for nation in Nations)
    end
    print(iob, "GProd;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for nation in Nations
      for year in years
        ZZZ[year] = GProd[process,nation,year]
      end
      print(iob, "GProd;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  print(iob, "Non-Marketable Gas (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = TProd[nation,year]*(1-GMMult[nation,year])
    end
    print(iob, "TProd*(1-GMMult);", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Gas Marketable Multiplier (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = GMMult[nation,year]
    end
    print(iob, "GMMult;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Policy Capture: Venting (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = VnGProd[nation,year]
    end
    print(iob, "VnGProd;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Policy Capture: Fugitive (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = FuGProd[nation,year]
    end
    print(iob, "FuGProd;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Policy Capture: Flaring (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = FlGProd[nation,year]
    end
    print(iob, "FlGProd;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Comment in Promula
  # GMarket=TProd*GMMult+VnGProd+FuGProd+FlGProd
  #

  naturalgas=Select(FuelEP,"NaturalGas")
  for fuelep in naturalgas
    print(iob, FuelEPDS[fuelep], " Primary Imports (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      for year in years
        ZZZ[year] = Imports[fuelep,nation,year]
      end
      print(iob, "Imports;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      for year in years
        ZZZ[year] = ImportsMin[fuelep,nation,year]
      end
      print(iob, "ImportsMin;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  naturalgas=Select(FuelEP,"NaturalGas")
  for fuelep in naturalgas
    print(iob, FuelEPDS[fuelep], " Primary Imports (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      for year in years
        ZZZ[year] = xImports[fuelep,nation,year]
      end
      print(iob, "xImports;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  naturalgas=Select(FuelEP,"NaturalGas")
  for fuelep in naturalgas
    print(iob, FuelEPDS[fuelep], " Primary Exports (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      for year in years
        ZZZ[year] = Exports[fuelep,nation,year]
      end
      print(iob, "Exports;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      for year in years
        ZZZ[year] = ExportsMin[fuelep,nation,year]
      end
      print(iob, "ExportsMin;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      for year in years
        ZZZ[year] = LNGProdMin[nation,year]
      end
      print(iob, "LNGProdMin;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  naturalgas=Select(FuelEP,"NaturalGas")
  for fuelep in naturalgas
    print(iob, FuelEPDS[fuelep], " Primary Exports (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      for year in years
        ZZZ[year] = xExports[fuelep,nation,year]
      end
      print(iob, "xExports;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  naturalgas=Select(Fuel,"NaturalGas")
  for fuel in naturalgas
    print(iob, FuelDS[fuel], " Primary Fuel Price ($CDTime Local/mmBtu);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      for year in years
        ZZZ[year] = ENPN[fuel,nation,year]*InflationNation[nation,CDYear]
      end
      print(iob, "ENPN;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  naturalgas=Select(Fuel,"NaturalGas")
  for fuel in naturalgas
    print(iob, FuelDS[fuel], " Primary Fuel Price ($CDTime US\$/mmBtu);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      for year in years
        @finite_math ZZZ[year] = ENPN[fuel,nation,year]/ExchangeRateNation[nation,year]*InflationNation[nation,CDYear]
      end
      print(iob, "ENPN;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  naturalgas=Select(Fuel,"NaturalGas")
  for fuel in naturalgas
    print(iob, FuelDS[fuel], " Exogenous Primary Fuel Price ($CDTime US\$/mmBtu);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      for year in years
        @finite_math ZZZ[year] = xENPN[fuel,nation,year]/ExchangeRateNation[nation,year]*InflationNation[nation,CDYear]
      end
      print(iob, "xENPN;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    for process in processes
      print(iob, NationDS[nation], " ", ProcessDS[process], " Primary Gas Production (TBtu/Yr);")
      for year in years  
        print(iob,";",Year[year])
      end
      println(iob)
      for year in years
        ZZZ[year] = sum(GAProd[process,area,year] for area in areas)
      end
      print(iob, "GAProd;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      for area in areas
        for year in years
          ZZZ[year] = GAProd[process,area,year]
        end
        print(iob, "GAProd;", AreaDS[area])
        for year in years
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob, " ")
    end
  end

  print(iob, "Gas Supply Multiplier from Price Changes Switch;")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = GSMSw[year]
  end
  print(iob, "GSMSw;1=ON 2=OFF")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "Gas Supply Elasticity to Change Prices;")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = GSPElas[year]
  end
  print(iob, "GSPElas;Elasticity")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "Gas Price Multiplier from Supply Changes (\$/\$);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = GSPM[year]
  end
  print(iob, "GSPM;Multiplier")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "Gas Price Multiplier from Supply Changes Switch;")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = GSPMSw[year]
  end
  print(iob, "GSPMSw;1=ON 2=OFF 3=NEW")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")


  print(iob, "Natural Gas Production Tax ($CDTime Local/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = GPrTax[nation,year]/InflationNation[nation,year]*InflationNation[nation,CDYear]
    end
    print(iob, "GPrTax;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.8f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  for nation in Nations
    print(iob, NationDS[nation], " Gas Supply Multiplier from Price Changes;")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for process in processes
      for year in years
        ZZZ[year] = GSM[process,nation,year]
      end
      print(iob, "GSM;", ProcessDS[process])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  println(iob, "Gas Price Elasticity to Change Supply;", join(ProcessDS[processes]))
  for nation in Nations
    QQQ[processes] = GSElas[processes,nation]
    print(iob, "GSElas;", NationDS[nation])
    for process in processes
      print(iob,";",@sprintf("%15.4f",QQQ[process]))
    end
    println(iob)
  end
  println(iob, " ")


  print(iob, "Gas Supply Potential to Demand Ratio (Btu/Btu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      SSS[year]=sum(xGProd[process,nation,year]*GSM[process,nation,year] for process in processes)
      @finite_math ZZZ[year] = SSS[year]/GDemand[nation,year]
    end
    print(iob, "GSPMRatio;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")


  for process in processes
    print(iob, ProcessDS[process], " Primary Gas Production (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(xGProd[process,nation,year] for nation in Nations)
    end
    print(iob, "xGProd;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for nation in Nations
      for year in years
        ZZZ[year] = xGProd[process,nation,year]
      end
      print(iob, "xGProd;", NationDS[nation])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  filename = "SpGas-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function SpGas_DtaControl(db)
  @info "SpGas_DtaControl"
  data = SpGasData(; db)
  
  SpGas_DtaRun(data)

end

if abspath(PROGRAM_FILE) == @__FILE__
SpGas_DtaControl(DB)
end
