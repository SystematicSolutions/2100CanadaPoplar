#
# SpOil.jl
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


Base.@kwdef struct SpOilData
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
  
  PCov::SetArray = ReadDisk(db, "MainDB/PCovKey")
  PCovs::Vector{Int} = collect(Select(PCov))

  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  
  Process::SetArray = ReadDisk(db, "MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db, "MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  eCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") # [Fuel,Nation,Year] Primary Fuel Price ($/mmBtu)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  Exports::VariableArray{3} = ReadDisk(db, "SpOutput/Exports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  GO::VariableArray{3} = ReadDisk(db, "MOutput/GO") # [ECC,Area,Year] Gross Output (M$/Yr)
  GOMult::VariableArray{3} = ReadDisk(db, "SOutput/GOMult") # [ECC,Area,Year] Gross Output Multiplier ($/$)
  GOMSmooth::VariableArray{3} = ReadDisk(db, "SOutput/GOMSmooth") # [ECC,Area,Year] Smooth of Gross Output Multiplier ($/$)
  Imports::VariableArray{3} = ReadDisk(db, "SpOutput/Imports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") # [Area] Descriptor for Monetary Units Type=String(15)
  OAPrEOR::VariableArray{3} = ReadDisk(db, "SOutput/OAPrEOR") # [Process,Area,Year] Oil Production from EOR (TBtu/Yr)
  OAProd::VariableArray{3} = ReadDisk(db, "SOutput/OAProd") # [Process,Area,Year] Primary Oil Production (TBtu/Yr)
  OIPElas::VariableArray{1} = ReadDisk(db, "SpInput/OIPElas") # [Year] Oil Import Price Elasticity
  OProd::VariableArray{3} = ReadDisk(db, "SOutput/OProd") # [Process,Nation,Year] Primary Oil Production (TBtu/Yr)
  OPrTax::VariableArray{3} = ReadDisk(db, "SpOutput/OPrTax") # [Process,Nation,Year] Oil Production Tax ($/mmBtu)
  OPrAMap::VariableArray{4} = ReadDisk(db, "SpInput/OPrAMap") # [Area,Process,Nation,Year] Provincial Oil Fraction (Btu/Btu)
  OPUC::VariableArray{3} = ReadDisk(db, "SpInput/OPUC") # [Process,Nation,Year] Oil Production Unit Full Cost ($/mmBtu)
  OPUCExist::VariableArray{3} = ReadDisk(db, "SpInput/OPUCExist") # [Process,Nation,Year] Oil Production Unit Full Cost for Existing Production ($/mmBtu)
  OPUCNew::VariableArray{3} = ReadDisk(db, "SpInput/OPUCNew") # [Process,Nation,Year] Oil Production Unit Full Cost for New Production ($/mmBtu)
  OPUCYr::Float32 = ReadDisk(db,"SpInput/OPUCYr")[1] # [tv] Oil Production Year for Existing Plants (Year)
  OSElas::VariableArray{2} = ReadDisk(db, "SpInput/OSElas") # [Process,Nation] Oil Supply Elasticity
  OSM::VariableArray{3} = ReadDisk(db, "SpOutput/OSM") # [Process,Nation,Year] Oil Supply Multiplier
  OSMExist::VariableArray{3} = ReadDisk(db, "SpOutput/OSMExist") # [Process,Nation,Year] Oil Supply Multiplier for Existing Production (Btu/Btu)
  OSMNew::VariableArray{3} = ReadDisk(db, "SpOutput/OSMNew") # [Process,Nation,Year] Oil Supply Multiplier for New Production (Btu/Btu)
  OSMSw::VariableArray{1} = ReadDisk(db, "SpInput/OSMSw") # [Year] Oil Supply Multiplier Switch
  PCost::VariableArray{4} = ReadDisk(db, "SOutput/PCost") # [ECC,Poll,Area,Year] Permit Cost (Real $/Tonnes)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PolCov::VariableArray{5} = ReadDisk(db, "SOutput/PolCov") # [ECC,Poll,PCov,Area,Year] Total Covered Pollution (Tonnes/Yr)
  RPPAdjustments::VariableArray{2} = ReadDisk(db, "SpOutput/RPPAdjustments") # [Nation,Year] RPP Supply Adjustments (TBtu/Yr)
  RPPAProd::VariableArray{2} = ReadDisk(db, "SpOutput/RPPAProd") # [Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPDemand::VariableArray{2} = ReadDisk(db, "SpOutput/RPPDemand") # [Nation,Year] Oil Demand (TBtu/Yr)
  RPPEff::VariableArray{2} = ReadDisk(db, "SCalDB/RPPEff") # [Nation,Year] RPP Efficiency Factor (Btu/Btu)
  RPPExports::VariableArray{2} = ReadDisk(db, "SpOutput/RPPExports") # [Nation,Year] Refined Petroleum Products Exports (TBtu/Yr)
  RPPImports::VariableArray{2} = ReadDisk(db, "SpOutput/RPPImports") # [Nation,Year] Refined Petroleum Products Imports (TBtu/Yr)
  RPPProd::VariableArray{2} = ReadDisk(db, "SpOutput/RPPProd") # [Nation,Year] Refinery Production (TBtu/Yr)
  xENPN::VariableArray{3} = ReadDisk(db, "SInput/xENPN") # [Fuel,Nation,Year] Exogenous Primary Fuel Price (1985 $/mmBtu)
  xExports::VariableArray{3} = ReadDisk(db, "SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xGO::VariableArray{3} = ReadDisk(db, "MInput/xGO") # [ECC,Area,Year] Gross Output (1985 M$/Yr)
  xImports::VariableArray{3} = ReadDisk(db, "SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xOProd::VariableArray{3} = ReadDisk(db, "SInput/xOProd") # [Process,Nation,Year] Primary Oil Production (TBtu/Yr)
  xRPPExports::VariableArray{2} = ReadDisk(db, "SpInput/xRPPExports") # [Nation,Year] Refined Petroleum Products Exports (TBtu/Yr)
  xRPPImports::VariableArray{2} = ReadDisk(db, "SpInput/xRPPImports") # [Nation,Year] Refined Petroleum Products Imports (TBtu/Yr)
  xRPPAdjustments::VariableArray{2} = ReadDisk(db, "SpInput/xRPPAdjustments") # [Nation,Year] RPP Supply Adjustments (TBtu/Yr)
  xRPPAProd::VariableArray{2} = ReadDisk(db, "SInput/xRPPAProd") # [Area,Year] Refinery Production (TBtu/Yr)
 
  #
  # Scratch Variables
  #
  OilConv = zeros(Float32, length(Process)) # Oil Conversion Factor (TJ/1000 Cubic Metres)
  AAA = zeros(Float32, length(Area))
  PPP = zeros(Float32, length(Process))
  ZZZ = zeros(Float32, length(Year))
end

function SpOil_DtaRun(data)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Fuel,FuelDS,Fuels) = data
  (; FuelEP,FuelEPDS,FuelEPs,Nation,NationDS,Nations,PCov,PCovs) = data
  (; Poll,PollDS,Process,ProcessDS,Processes,Year) = data
  (; AAA,ANMap,CDTime,CDYear,eCO2Price,ENPN,ExchangeRate,ExchangeRateNation) = data
  (; Exports,GO,GOMult,GOMSmooth,Imports,Inflation,InflationNation) = data
  (; MoneyUnitDS,OAPrEOR,OAProd,OilConv,OIPElas,OProd,OPrTax,OPrAMap) = data
  (; OPUC,OPUCExist,OPUCNew,OPUCYr,OSElas,OSM,OSMExist,OSMNew) = data
  (; OSMSw,PCost,PolConv,PolCov,PPP,RPPAdjustments,RPPAProd,RPPDemand) = data
  (; RPPEff,RPPExports,RPPImports,RPPProd,SceName,xENPN,xExports,xGO) = data
  (; xImports,xOProd,xRPPExports,xRPPImports,xRPPAdjustments,xRPPAProd,ZZZ) = data

  KJBtu = 1.054615
  BBCM = 6.29258
  years = collect(Yr(1990):Final)
  CDYear = max(CDYear,1)
 
  iob = IOBuffer()
   #
   # Oil Conversion Factor (TJ/1000 Cubic Metres)
   #
  OilConv[Select(Process,"LightOilMining")]              = 38.51
  OilConv[Select(Process,"HeavyOilMining")]              = 40.90
  OilConv[Select(Process,"FrontierOilMining")]           = 38.51
  OilConv[Select(Process,"PrimaryOilSands")]             = 42.79
  OilConv[Select(Process,"SAGDOilSands")]                = 42.79
  OilConv[Select(Process,"CSSOilSands")]                 = 42.79
  OilConv[Select(Process,"OilSandsMining")]              = 42.79
  OilConv[Select(Process,"OilSandsUpgraders")]           = 39.40
  OilConv[Select(Process,"ConventionalGasProduction")]   = 1.00
  OilConv[Select(Process,"SweetGasProcessing")]          = 1.00
  OilConv[Select(Process,"UnconventionalGasProduction")] = 1.00
  OilConv[Select(Process,"SourGasProcessing")]           = 1.00
  OilConv[Select(Process,"PentanesPlus")]                = 41.77
  OilConv[Select(Process,"Condensates")]                 = 41.77
  OilConv[Select(Process,"AssociatedGasProduction")]     = 1.00
  OilConv[Select(Process,"LNGProduction")]               = 1274.00

  CN = Select(Nation,"CN")
  areas_cn = Select(Area,(from ="ON", to="NU"))
  nations = Select(Nation,["US","CN","MX"])
  areas_n = Select(Area,!=("ROW"))
  processes_t = Select(Process,!=("OilSandsUpgraders"))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the SpOil Summary.")
  println(iob, " ")

  print(iob, "Year;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  println(iob, " ")
  println(iob, "*** SpOil Outputs ***")
  println(iob, " ")
 
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  area1 = first(areas)

  print(iob,"Permit Cost plus Carbon Tax ($CDTime Local\$/eCO2 Tonnes);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in CN
    print(iob,"eCO2Price;",NationDS[nation])
    for year in years
      @finite_math ZZZ[year] = eCO2Price[area1,year]/Inflation[area1,year]*Inflation[area1,CDYear]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob,"Permit Cost plus Carbon Tax ($CDTime US\$/eCO2 Tonnes);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in CN
    print(iob,"eCO2Price;", NationDS[nation])
    for year in years
      @finite_math ZZZ[year] = eCO2Price[area1, year]/ExchangeRate[area1,year]/
                    Inflation[area1,year]*Inflation[area1,CDYear]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
  
  print(iob, "Oil Supply Multiplier from Price Changes Switch;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "OSMSw;1=ON 2=OFF")
  for year in years
    ZZZ[year] = OSMSw[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  print(iob, "Oil Demand (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "RPPDemand;", NationDS[nation])
    for year in years
      ZZZ[year] = RPPDemand[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Refined Petroleum Products Exports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "RPPExports;", NationDS[nation])
    for year in years
      ZZZ[year] = RPPExports[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Historical Refined Petroleum Products Exports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "xRPPExports;", NationDS[nation])
    for year in years
      ZZZ[year] = xRPPExports[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Refined Petroleum Products Imports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "RPPImports;", NationDS[nation])
    for year in years
      ZZZ[year] = RPPImports[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Historical Refined Petroleum Products Imports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "xRPPImports;", NationDS[nation])
    for year in years
      ZZZ[year] = xRPPImports[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
 
  print(iob, "Refinery Production (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob,"RPPProd;", NationDS[nation])
    for year in years
      ZZZ[year] = RPPProd[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
 
  print(iob, "Refinery Production (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in areas_n
    print(iob, "RPPAProd;", AreaDS[area])
    for year in years
      ZZZ[year] = RPPAProd[area,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
 
  print(iob, "Historical Refinery Production (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in areas_n
    print(iob, "xRPPAProd;", AreaDS[area])
    for year in years
      ZZZ[year] = xRPPAProd[area,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
 
  print(iob, "Refined Petroleum Products Crude Oil Efficiency (Btu/Btu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "RPPEff;", NationDS[nation])
    for year in years
      ZZZ[year] = RPPEff[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  for nation in nations
    print(iob, NationDS[nation], " Crude Oil Production (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    processes = Select(Process,!=("OilSandsUpgraders")) # Omit Upgraders from total only
    print(iob, "OProd;Total")
    for year in years
      ZZZ[year] = sum(OProd[process,nation,year] for process in processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "OProd;", ProcessDS[process])
      for year in years
        ZZZ[year] = OProd[process,nation,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in nations
    print(iob, NationDS[nation], " Crude Oil Production (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    processes = Select(Process,!=("OilSandsUpgraders")) # Omit Upgraders from total only
    print(iob, "xOProd;Total")
    for year in years
      ZZZ[year] = sum(xOProd[process,nation,year] for process in processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "xOProd;", ProcessDS[process])
      for year in years
        ZZZ[year] = xOProd[process,nation,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  fuelep = Select(FuelEP,"CrudeOil")
  print(iob, "Crude Oil Imports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "Imports;", NationDS[nation])
    for year in years
      ZZZ[year] = Imports[fuelep,nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Exogenous Crude Oil Imports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "xImports;", NationDS[nation])
    for year in years
      ZZZ[year] = xImports[fuelep,nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Crude Oil Exports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "Exports;", NationDS[nation])
    for year in years
      ZZZ[year] = Exports[fuelep,nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Exogenous Crude Oil Exports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in nations
    print(iob, "xExports;", NationDS[nation])
    for year in years
      ZZZ[year] = xExports[fuelep,nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  fuels = Select(Fuel,["LightCrudeOil","HeavyCrudeOil"])
  for nation in nations
    print(iob, NationDS[nation], " Primary Fuel Price ($CDTime Local\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for fuel in fuels
      print(iob, "ENPN;", FuelDS[fuel])
      for year in years
        ZZZ[year] = ENPN[fuel,nation,year] * InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
    print(iob, NationDS[nation], " Primary Fuel Price ($CDTime US\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for fuel in fuels
      print(iob, "ENPN;", FuelDS[fuel])
      for year in years
        @finite_math ZZZ[year] = ENPN[fuel,nation,year]/ExchangeRateNation[nation,year]*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  fuels = Select(Fuel,["LightCrudeOil","HeavyCrudeOil"])
  for nation in nations
    print(iob, NationDS[nation], " Primary Fuel Price ($CDTime Local\$/bbl);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for fuel in fuels
      print(iob, "ENPN;", FuelDS[fuel])
      for year in years
        ZZZ[year] = ENPN[fuel,nation,year]*5.825*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  fuels = Select(Fuel,["LightCrudeOil","HeavyCrudeOil"])
  for nation in nations
    print(iob, NationDS[nation], " Primary Fuel Price ($CDTime US\$/bbl);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for fuel in fuels
      print(iob, "ENPN;", FuelDS[fuel])
      for year in years
        @finite_math ZZZ[year] = ENPN[fuel,nation,year]*5.825/ExchangeRateNation[nation,year]*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
    print(iob, NationDS[nation], " Exogenous Primary Fuel Price ($CDTime US\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for fuel in fuels
      print(iob, "xENPN;", FuelDS[fuel])
      for year in years
        @finite_math ZZZ[year] = xENPN[fuel,nation,year]/ExchangeRateNation[nation,year]*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in CN
    print(iob, NationDS[nation], " Primary Oil Production (PJ/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    processes = Select(Process,!=("OilSandsUpgraders")) # Omit Upgraders from total only
    print(iob, "OProd;Total")
    for year in years
      ZZZ[year] = sum(OProd[process,nation,year]*KJBtu for process in processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "OProd;", ProcessDS[process])
      for year in years
        ZZZ[year] = OProd[process,nation,year]*KJBtu
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in CN
    print(iob, NationDS[nation], " Primary Oil Production (1000 Cubic Meters/Day);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    processes = Select(Process,!=("OilSandsUpgraders")) # Omit Upgraders from total only
    print(iob, "OProd;Total")
    for year in years
      ZZZ[year] = sum(OProd[process,nation,year]*KJBtu/OilConv[process]/365*1000 for process in processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "OProd;", ProcessDS[process])
      for year in years
        ZZZ[year] = OProd[process,nation,year]*KJBtu/OilConv[process]/365*1000
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in CN
    print(iob, NationDS[nation], " Primary Oil Production (1000 bbl/Day);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    processes = Select(Process,!=("OilSandsUpgraders")) # Omit Upgraders from total only
    print(iob, "OProd;Total")
    for year in years
      ZZZ[year] = sum(OProd[process,nation,year]*KJBtu/OilConv[process]/365*BBCM*1000 for process in processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "OProd;", ProcessDS[process])
      for year in years
        ZZZ[year] = OProd[process,nation,year]*KJBtu/OilConv[process]/365*BBCM*1000
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for area in areas
    print(iob, AreaDS[area], " Primary Oil Production (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    processes = Select(Process,!=("OilSandsUpgraders")) # Omit Upgraders from total only
    print(iob, "OAProd;Total")
    for year in years
      ZZZ[year] = sum(OAProd[process,area,year] for process in processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "OAProd;", ProcessDS[process])
      for year in years
        ZZZ[year] = OAProd[process,area,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end  
    println(iob, " ")
  end

  processes = Select(Process,!=("OilSandsUpgraders")) # Omit Upgraders from total only
  for area in areas
    print(iob, AreaDS[area], " Primary Oil Production (PJ/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "OAProd;Total")
    for year in years
      ZZZ[year] = sum(OAProd[process,area,year]*KJBtu for process in processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "OAProd;", ProcessDS[process])
      for year in years
        ZZZ[year] = OAProd[process,area,year]*KJBtu
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    print(iob, "OAProd;Total")
    for year in years
      ZZZ[year] = sum(OAProd[process,area,year]*KJBtu for process in Processes)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)    
    println(iob, " ")
  end

  print(iob, "Map between Area and Nation;")
  for area in areas
    print(iob,";",AreaDS[area])
  end
  println(iob)
  for nation in Nations
    print(iob, "ANMap;", NationDS[nation], ";")
    for area in areas
      AAA[area] = ANMap[area,nation]
      print(iob, @sprintf("%15.0f;", AAA[area]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Oil Supply Elasticity;")
  for process in Processes
    print(iob,";",ProcessDS[process])
  end
  println(iob)
  for nation in Nations
    print(iob, "OSElas;", NationDS[nation])
    for process in Processes
      PPP[process] = OSElas[process,nation]
      print(iob, @sprintf("%.4f;",PPP[process]))
    end
    println(iob)
  end
  println(iob, " ")

  petroleum = Select(ECC,"Petroleum")
  for ecc in petroleum
    print(iob, ECCDS[ecc], " Gross Output (M\$/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for area in Areas
      print(iob, "GO;", AreaDS[area])
      for year in years
        ZZZ[year] = GO[ecc,area,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
    print(iob, ECCDS[ecc], " Gross Output (1985 M\$/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
      for area in Areas
        print(iob, "xGO;", AreaDS[area])
        for year in years
          ZZZ[year] = xGO[ecc,area,year]
          print(iob,";",@sprintf("%15.4f", ZZZ[year]))
        end
        println(iob)
      end
    println(iob, " ")
  end

  eccs = Select(ECC,(from = "LightOilMining", to = "OilSandsMining"))
  for ecc in eccs
    print(iob, ECCDS[ecc], " Gross Output Multiplier (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for area in Areas
      print(iob, "GOMult;", AreaDS[area])
      for year in years
        ZZZ[year] = GOMult[ecc,area,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  print(iob, "Oil Import Price Elasticity;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "OIPElas;Elasticity")
  for year in years
    ZZZ[year] = OIPElas[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  for nation in Nations
    print(iob, NationDS[nation], " Oil Production Full Full Cost ($CDTime Local\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OPUC;", ProcessDS[process])
      for year in years
        ZZZ[year] = OPUC[process,nation,year]*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " Oil Production Full Unit Cost for Existing Production ($CDTime Local\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OPUCExist;", ProcessDS[process])
      for year in years
        ZZZ[year] = OPUCExist[process,nation,year]*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " Oil Production Full Unit Cost for New Production ($CDTime Local\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OPUCNew;", ProcessDS[process])
      for year in years
        ZZZ[year] = OPUCNew[process,nation,year]*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " Oil Production Tax ($CDTime Local\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OPrTax;", ProcessDS[process])
      for year in years
        ZZZ[year] = OPrTax[process,nation,year]/InflationNation[nation,year]*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " Oil Production Profit for Existing Production ($CDTime Local\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "Profit Exist;", ProcessDS[process])
      fuel = Select(Fuel,"HeavyCrudeOil")
      if (Process[process] == "LightOilMining") || (Process[process] == "FrontierOilMining") || (Process[process] == "OilSandsUpgraders")
        fuel = Select(Fuel,"LightCrudeOil")
      end
      for year in years
        @finite_math ZZZ[year] = max(xENPN[fuel,nation,year]-OPUCExist[process,nation,year]-OPrTax[process,nation,year]/InflationNation[nation,year],0)*InflationNation[nation,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end
  
  for nation in Nations
    print(iob, NationDS[nation], " Oil Production Profit for New Production ($CDTime Local\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "Profit New;", ProcessDS[process])
      fuel = Select(Fuel,"HeavyCrudeOil")
      if (Process[process] == "LightOilMining") || (Process[process] == "FrontierOilMining") || (Process[process] == "OilSandsUpgraders")
        fuel = Select(Fuel,"LightCrudeOil")
      end
      for year in years
      @finite_math ZZZ[year] = max(xENPN[fuel,nation,year]-OPUCNew[process,nation,year]-OPrTax[process,nation,year]/InflationNation[nation,year],0)*InflationNation[nation,CDYear]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " Oil Supply Multiplier from Price Changes;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OSM;", ProcessDS[process])
      for year in years
        ZZZ[year] = OSM[process,nation,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " Oil Supply Multiplier from Price Changes for Existing Production;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OSMExist;", ProcessDS[process])
      for year in years
        ZZZ[year] = OSMExist[process,nation,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " Oil Supply Multiplier from Price Changes for New Production;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OSMNew;", ProcessDS[process])
      for year in years
        ZZZ[year] = OSMNew[process,nation,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  ExistYr=Int(max(1,OPUCYr[1]-ITime+1))

  for nation in Nations
    print(iob, NationDS[nation], " Primary Oil Production from Existing Production (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OProdExist;", ProcessDS[process])
      for year in years
        ZZZ[year] = xOProd[process,nation,ExistYr]*OSMExist[process,nation,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
    print(iob, NationDS[nation], " Primary Oil Production from New Production (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for process in Processes
      print(iob, "OProdNew;", ProcessDS[process])
      for year in years
        ZZZ[year] = max(xOProd[process,nation,year]-xOProd[process,nation,ExistYr],0)*OSMNew[process,nation,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  co2 = Select(Poll,"CO2")
  for nation in Nations
    print(iob, NationDS[nation], " ", PollDS[co2], " Pollution Covered (Tonnes/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    areas_map = findall(ANMap[:,nation] .== 1)
    for ecc in eccs
      print(iob, "PolCov;", ECCDS[ecc])
      for year in years
        ZZZ[year] = sum(PolCov[ecc,co2,pcov,area,year]*PolConv[co2] for area in areas_map, pcov in PCovs)
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, NationDS[nation], " ", PollDS[co2], " Permit Costs ($CDTime Local\$/Tonnes);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ecc in eccs
      print(iob, "PCost;", ECCDS[ecc])
      for year in years
        ZZZ[year] = PCost[ecc,co2,area1,year]*Inflation[area1,CDYear]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in CN
    for process in Processes
      print(iob, ProcessDS[process], " ", NationDS[nation], " Provincial Oil Fraction (Btu/Btu);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for area in Areas
        print(iob, "OPrAMap;", AreaDS[area])
        for year in years
          ZZZ[year] = OPrAMap[area,process,nation,year]
          print(iob,";",@sprintf("%15.4f", ZZZ[year]))
        end
        println(iob)
      end
      println(iob, " ")
    end
  end
  
  processes = Select(Process,!=("OilSandsUpgraders"))
  ecc_p = Select(ECC,"Petroleum")
  eccs = union(ecc_p,eccs)
  for ecc in eccs
    print(iob, ECCDS[ecc], " Smooth of Gross Output Multiplier (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for area in areas
      print(iob, "GOMSmooth;", AreaDS[area])
      for year in years
        ZZZ[year] = GOMSmooth[ecc,area,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end
  
  print(iob, "Canada Oil Production from EOR (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "OAPrEOR;Total")
  for year in years
    ZZZ[year] = sum(OAPrEOR[process,area,year] for area in areas, process in processes) # Omit Upgraders from total only
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for process in Processes
    print(iob, "OAPrEOR;", ProcessDS[process])
    for year in years
      ZZZ[year] = sum(OAPrEOR[process,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  for area in areas
    print(iob, AreaDS[area], " Oil Production from EOR (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "OAPrEOR;Total")
    for year in years
      ZZZ[year] = sum(OAPrEOR[process,area,year] for process in processes) # Omit Upgraders from total only
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for process in Processes
      print(iob, "OAPrEOR;", ProcessDS[process])
      for year in years
        ZZZ[year] = OAPrEOR[process,area,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end
  
  print(iob, "Refined Petroleum Products Supply Adjustments (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    print(iob, "RPPAdjustments;", NationDS[nation])
    for year in years
      ZZZ[year] = RPPAdjustments[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Historical Refined Petroleum Products Supply Adjustments (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    print(iob, "xRPPAdjustments;", NationDS[nation])
    for year in years
      ZZZ[year] = xRPPAdjustments[nation,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  filename = "SpOil-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function SpOil_DtaControl(db)
  @info "SpOil_DtaControl"
  data = SpOilData(; db)
  
  SpOil_DtaRun(data)

end

if abspath(PROGRAM_FILE) == @__FILE__
SpOil_DtaControl(DB)
end
