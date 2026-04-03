#
# SupplyBalance.jl
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

Base.@kwdef struct SupplyBalanceData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Biofuel::SetArray = ReadDisk(db,"MainDB/BiofuelKey")
  BiofuelDS::SetArray = ReadDisk(db,"MainDB/BiofuelDS")
  Biofuels::Vector{Int} = collect(Select(Biofuel))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Feedstock::SetArray = ReadDisk(db,"MainDB/FeedstockKey")
  FeedstockDS::SetArray = ReadDisk(db,"MainDB/FeedstockDS")
  Feedstocks::Vector{Int} = collect(Select(Feedstock))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Tech::SetArray = ReadDisk(db,"SInput/TechKey")
  TechDS::SetArray = ReadDisk(db,"SInput/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  AreaPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/AreaPurchases") # [Area,Year]  Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{2} = ReadDisk(db, "EGOutput/AreaSales") # [Area,Year]  Sales to Areas in the same Country (GWh/Yr)
  BfProd::VariableArray{5} = ReadDisk(db,"SpOutput/BfProd") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production (TBtu/Yr)
  CAProd::VariableArray{2} = ReadDisk(db,"SOutput/CAProd") # [Area,Year] Primary Coal Production (TBtu/Yr)
  Exports::VariableArray{3} = ReadDisk(db, "SpOutput/Exports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  ExportsMin::VariableArray{3} = ReadDisk(db, "SpInput/ExportsMin") # [FuelEP,Nation,Year] Exports Minimum (TBtu/Yr)
  GMarket::VariableArray{2} = ReadDisk(db, "SOutput/GMarket") # [Nation,Year] Marketable Gas Production (TBtu/Yr)
  GProd::VariableArray{3} = ReadDisk(db, "SOutput/GProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  GRaw::VariableArray{2} = ReadDisk(db, "SOutput/GRaw") # [Nation,Year] Raw Natural Gas Demand (TBtu/Yr)
  Imports::VariableArray{3} = ReadDisk(db, "SpOutput/Imports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  ImportsMin::VariableArray{3} = ReadDisk(db, "SpInput/ImportsMin") # [FuelEP,Nation,Year] Imports Minimum (TBtu/Yr)
  OProd::VariableArray{3} = ReadDisk(db, "SOutput/OProd") # [Process,Nation,Year] Primary Oil Production (TBtu/Yr)
  RPPAdjustments::VariableArray{2} = ReadDisk(db, "SpOutput/RPPAdjustments") # [Nation,Year] RPP Supply Adjustments (TBtu/Yr)
  RPPExports::VariableArray{2} = ReadDisk(db, "SpOutput/RPPExports") # [Nation,Year] Refined Petroleum Products Exports (TBtu/Yr)
  RPPImports::VariableArray{2} = ReadDisk(db, "SpOutput/RPPImports") # [Nation,Year] Refined Petroleum Products Imports (TBtu/Yr)
  RPPProd::VariableArray{2} = ReadDisk(db, "SpOutput/RPPProd") # [Nation,Year] Refinery Production (TBtu/Yr)
  SupplyAdjustments::VariableArray{3} = ReadDisk(db, "SpOutput/SupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)
  TotDemand::VariableArray{4} = ReadDisk(db,"SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)

  xCAProd::VariableArray{2} = ReadDisk(db,"SpInput/xCAProd") # [Area,Year] Coal Production (TBtu/Yr)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xExports::VariableArray{3} = ReadDisk(db,"SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # Feedstock Energy Demands (TBtu/Yr) [Fuel,ECC,Area,Year]
  xGProd::VariableArray{3} = ReadDisk(db, "SInput/xGProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  xImports::VariableArray{3} = ReadDisk(db,"SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xOProd::VariableArray{3} = ReadDisk(db, "SInput/xOProd") # [Process,Nation,Year] Primary Oil Production (TBtu/Yr)
  xRPPAdjustments::VariableArray{2} = ReadDisk(db,"SpInput/xRPPAdjustments") # [Nation,Year] RPP Supply Adjustments (TBtu/Yr)
  xRPPAProd::VariableArray{2} = ReadDisk(db, "SInput/xRPPAProd") # [Area,Year] Refinery Production (TBtu/Yr)
  xRPPExports::VariableArray{2} = ReadDisk(db, "SpInput/xRPPExports") # [Nation,Year] Refined Petroleum Products Exports (TBtu/Yr)
  xRPPImports::VariableArray{2} = ReadDisk(db, "SpInput/xRPPImports") # [Nation,Year] Refined Petroleum Products Imports (TBtu/Yr)
  xSupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpInput/xSupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)

  EGPA::VariableArray{3} = ReadDisk(db,"EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  # EmEGA::VariableArray{4} = ReadDisk(db,"EGOutput/EmEGA") # (Node,TimeP,Month,Year),Emergency Generation (GWh)

  ExpPurchases::VariableArray{2} = ReadDisk(db,"EGOutput/ExpPurchases") # (Area,Year),Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db,"EGOutput/ExpSales") # (Area,Year),Sales to Areas in a different Country (GWh/Yr)
  PSoECC::VariableArray{3} = ReadDisk(db,"SOutput/PSoECC") # (ECC,Area,Year),Power Sold to Grid (GWh)
  SaEC::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)
  TDEF::VariableArray{3} = ReadDisk(db,"SInput/TDEF") # [Fuel,Area,Year] T&D Efficiency (MW/MW)
  xAreaPurchases::VariableArray{2} = ReadDisk(db, "EGInput/xAreaPurchases") # [Area,Year] Historical Purchases from Areas in the same Country (GWh/Yr)
  xAreaSales::VariableArray{2} = ReadDisk(db, "EGInput/xAreaSales") # [Area,Year] Historical Sales to Areas in the same Country (GWh/Yr)

  xEGPA::VariableArray{3} = ReadDisk(db,"EGInput/xEGPA") # [Plant,Area,Year] Historical Electricity Generated (GWh/Yr)
  xExpPurchases::VariableArray{2} = ReadDisk(db, "EGInput/xExpPurchases") # [Area,Year] Historical Purchases from Areas in a different Country (GWh/Yr)
  xExpSales::VariableArray{2} = ReadDisk(db, "EGInput/xExpSales") # [Area,Year] Historical Sales to Areas in a different Country (GWh/Yr)
  xPSoECC::VariableArray{3} = ReadDisk(db, "SInput/xPSoECC") #[ECC,Area,Year]  Power Sold to Grid (GWh)
  xSaEC::VariableArray{3} = ReadDisk(db, "SInput/xSaEC") #[ECC,Area,Year]  Historical Electricity Sales (GWh/Yr)
  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)

  # Scratch Variables

  # Cubic Meter'
  # CoalConvCons(ES)   'Coal Consumption Conversion (Million Btu per Short Ton), AEO Tbl 73'
  # CoalConvProd(Area) 'Coal Production Conversion (Million Btu per Short Ton), AEO Tbl 75'
  # CoalConvExport     'Coal Exports Conversion (Million Btu per Short Ton), AEO Tbl 73'
  # CrudeConvProd      'Crude Oil Production Conversion (Million Btu per Barrel), AEO Tbl 73'
  # CrudeConvExport    'Crude Oil Exports Conversion (Million Btu per Barrel), AEO Tbl 73'
  # CrudeConvImport    'Crude Oil Imports Conversion (Million Btu per Barrel), AEO Tbl 73'
  # Fraction(Year)     'Fraction of Imports/Exports by Country'
  # GasConv(ES)        'Natural Gas Conversion for Consumption (1000 Btu per Cubit Foot), AEO Tbl 73'
  # GasConvProd        'Natural Gas Conversion for Production (1000 Btu per Cubit Foot), AEO Tbl 73'
  # GasConvExport      'Natural Gas Conversion for Exports (1000 Btu per Cubit Foot), AEO Tbl 73'
  # KJBtu         'Kilo Joule per BTU'
  # mmBtuPerBarrel(Fuel)    'Oil Conversion Factor by Fuel, AEO Tbl 73 (mmBtu per Barrel)'
  # OilConv(Process)   'Oil Conversion Factor by Process (TJ/1000 Cubic Metres)'
  #
  Adjustments::VariableArray{1} = zeros(Float32,length(Year))
  Available::VariableArray{1} = zeros(Float32,length(Year))
  Balance::VariableArray{1} = zeros(Float32,length(Year))
  Demand::VariableArray{1} = zeros(Float32,length(Year))
  Exported::VariableArray{1} = zeros(Float32,length(Year))
  Imported::VariableArray{1} = zeros(Float32,length(Year))
  LossFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year))
  Losses1::VariableArray{1} = zeros(Float32,length(Year))
  Losses2::VariableArray{1} = zeros(Float32,length(Year))
  Losses3::VariableArray{1} = zeros(Float32,length(Year))
  Losses::VariableArray{1} = zeros(Float32,length(Year))
  Production::VariableArray{1} = zeros(Float32,length(Year))
  Requirements::VariableArray{1} = zeros(Float32,length(Year))
  PrintImportsMin::VariableArray{1} = zeros(Float32,length(Year))
  PrintExportsMin::VariableArray{1} = zeros(Float32,length(Year))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  xGRaw::VariableArray{2} = zeros(Float32,length(Nation),length(Year))

  ZZZ::VariableArray{1} = zeros(Float32,length(Year))

end



function ConversionValues(data)
  (; ECCs,Fuel,Nations,Years) = data
  (; ANMap,xGRaw,xTotDemand) = data

  fuel=Select(Fuel,"NaturalGasRaw")
  for nation in Nations
    areas=findall(ANMap[:,nation] .== 1)
    if !isempty(areas)
      for year in Years
        xGRaw[nation,year]=sum(xTotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs)
      end
    end
  end

  #  Conversions are obtained from AEO 2017, Tbl 73, year 2015
  # Some values vary by year in Tbl 73, 2015 value assumed here
  #
  # Crude Oil(million Btu per barrel)
  #    Production                  5.729 
  #    Imports                     6.077
  #    Exports                     5.694
  # Coal (million Btu per short ton)
  #    Production                  19.85
  #      -East of the Mississippi  24.67
  #      -West of the Mississippi  17.15
  #    Consumption                 19.31
  #      -Commercial/Inst.         23.12
  #      -Industrial               20.67
  #      -Coking                   28.69         
  #      -Electric Power           18.85
  #    Imports                     23.68
  #    Exports                     26.64
  #
  # Natural Gas (1000 Btu Per Cubic Foot)
  #    Consumption                 1.033
  #      -Electric Power Sector    1.035
  #      -End-use Sector           1.032
  #    Production                  1.033
  #    Imports                     1.025
  #    Exports                     1.009
  #    Compressed/LNG              0.960
  #
  # CrudeConvProd        = 5.729
  # CrudeConvExport      = 5.694
  # CrudeConvImport      = 6.077
  # CoalConvProd(A)         =19.85
  # CoalConvCons(ES)        =19.31
  # CoalConvCons(Commercial)=23.12
  # CoalConvCons(Industrial)=20.67
  # CoalConvCons(Electric)  =18.85
  # CoalConvExport          =26.64
  #
  # GasConv = 1.033
  # Select ES(Residential-Transport)
  # GasConv = 1.032
  # Select ES(Electric)
  # GasConv = 1.035
  # Select ES*
  #
  # GasConvProd   = 1.033
  # GasConvExport = 1.009
  #
  # Petroleum (million Btu per barrel) 'AEO 2017, Tbl 73'
  #
  # Select Fuel*
  # mmBtuPerBarrel     =5.148
  # Select Fuel(Asphalt,Asphaltines,AviationGasoline,Biodiesel,Diesel,Ethanol,Gasoline,
  #             HeavyCrudeOil,HFO,JetFuel,Kerosene,LightCrudeOil,LFO,LPG,Lubricants,Naphtha,
  #             NonEnergy,PetroFeed,PetroCoke,StillGas)
  # Read mmBtuPerBarrel\20
  # Asphalt             6.636
  # Asphaltines         6.636
  # Aviation Gasoline   5.048
  # Biodiesel           5.359
  # Diesel              5.778
  # Ethanol             3.558
  # Gasoline            5.057
  # Heavy Crude Oil     6.287
  # Residual Fuel Oil   6.287
  # Jet Fuel            5.670
  # Kerosene            5.670
  # Light Crude Oil     5.800
  # Distilite Fuel Oil  5.778
  # LPG and other       3.559
  # Lubricants          6.065
  # Naphtha             5.800
  # NonEnergy           5.800
  # Petrofeedstocks     5.800
  # PetroCoke           6.287
  # StillGas            6.287
  # /Other Petroleum     5.800
  # /Unfinished oils     6.111
  # Select Fuel*
  #
  # Oil Conversions by Process (used for Canada) (Source?, Units?)
  #
  # Read OilConv\20
  # Light Oil           38.51
  # Heavy Oil           40.90
  # Frontier Oil        38.51
  # Oil Sands In-Situ   42.79
  # Oil Sands In-Situ   42.79
  # Oil Sands In-Situ   42.79
  # Oil Sands Mining    42.79
  # Oil Sands Upgraders 39.40
  # Conv Gas Prod        1.00
  # Sweet Gas Process    1.00
  # Unconv Gas Prod      1.00
  # Sour Gas Process     1.00
  # Pentanes Plus       41.77
  # Condensates         41.77
  # AssociatedGas        1.00
  # LNG Production    1274.00
  #
  # KJBtu = 1.054615
  # BBCM  = 6.29258
  #

end

function SupplyBalance_DtaRun(data, FuelName, ProdDS)
  (; Area,AreaDS,Areas,Biofuel, BiofuelDS,Biofuels,ECC,ECCDS,ECCs) = data
  (; Feedstock,FeedstockDS,Feedstocks,Fuel,FuelDS,Fuels,FuelEP) = data
  (; FuelEPDS,FuelEPs,Nation,NationDS,Nations,Plant,PlantDS) = data
  (; Plants,Process,ProcessDS,Processs,Techs,Year,Years) = data
  (; ANMap,AreaPurchases,AreaSales,BfProd,CAProd,Exports,ExportsMin) = data
  (; GMarket,GProd,GRaw,Imports,ImportsMin,OProd,RPPAdjustments) = data
  (; RPPExports,RPPImports,RPPProd,SupplyAdjustments,TotDemand) = data
  (; xCAProd,xCgDemand,xEuDemand,xExports,xFsDemand,xGProd,xImports) = data
  (; xOProd,xRPPAdjustments,xRPPAProd,xRPPExports,xRPPImports) = data
  (; xSupplyAdjustments,EGPA,ExpPurchases,ExpSales,PSoECC,SaEC) = data
  (; TDEF,xAreaPurchases,xAreaSales,xEGPA,xExpPurchases,xExpSales) = data
  (; xPSoECC,xSaEC,xTotDemand) = data
  (; Adjustments,Available,Balance,Demand,Exported,Imported) = data
  (; LossFactor,Losses1,Losses2,Losses3,Losses,SceName) = data
  (; Production,Requirements,PrintImportsMin,PrintExportsMin,xGRaw,ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the Supply Balance for $FuelName.")
  println(iob, " ")

  years = collect(Yr(1990):Final)
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  ########################
  #
  # Supply Balance in TBtu
  #
  for nation in Nations
    areas=findall(ANMap[:,nation] .== 1)
    if !isempty(areas)
      #
      # Endogenous Variables
      #
      if FuelName =="Natural Gas"
        processes=Select(Process,["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction"])
        fuels=Select(Fuel,["NaturalGas","NaturalGasRaw"])
        fueleps=Select(FuelEP,["NaturalGas","NaturalGasRaw"])
        for year in years
          Production[year]=sum(GProd[process,nation,year] for process in processes)
          Demand[year]=sum(TotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=sum(Imports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(Exports[fuelep,nation,year] for fuelep in fueleps)
          # TODOLater Revise to eliminate fuelep sums. LJD, 06.03.25
          fuelep=first(fueleps)
          Adjustments[year]=SupplyAdjustments[fuelep,nation,year]
          Losses[year]=sum(GProd[process,nation,year] for process in processes)-GMarket[nation,year]-GRaw[nation,year]
          PrintImportsMin[year] = sum(ImportsMin[fuelep,nation,year] for fuelep in fueleps)
          PrintExportsMin[year] = sum(ExportsMin[fuelep,nation,year] for fuelep in fueleps)
        end
      elseif FuelName =="Coal"
        fuels=Select(Fuel,["Coal"])
        fueleps=Select(FuelEP,["Coal"])
        for year in years
          Production[year]=sum(CAProd[area,year] for area in areas)
          Demand[year]=sum(TotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=sum(Imports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(Exports[fuelep,nation,year] for fuelep in fueleps)
          # TODO: Should this be a sum? -LJD, 06.02.25
          fuelep=first(fueleps)
          Adjustments[year]=SupplyAdjustments[fuelep,nation,year]
          Losses[year]=0.0
          PrintImportsMin[year] = sum(ImportsMin[fuelep,nation,year] for fuelep in fueleps)
          PrintExportsMin[year] = sum(ExportsMin[fuelep,nation,year] for fuelep in fueleps)
        end
      elseif FuelName =="RPP"
        fuels=Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
                          "Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy",
                          "PetroFeed","PetroCoke","StillGas"])
        fueleps=Select(FuelEP,["Asphaltines","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
                          "Kerosene","LFO","LPG",
                          "PetroCoke","StillGas"])
        for year in years
          Production[year]=RPPProd[nation,year]
          Demand[year]=sum(TotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=RPPImports[nation,year]
          Exported[year]=RPPExports[nation,year]
          Losses[year]=0.0
          Adjustments[year]=xRPPAdjustments[nation,year]
          PrintImportsMin[year] = sum(ImportsMin[fuelep,nation,year] for fuelep in fueleps)
          PrintExportsMin[year] = sum(ExportsMin[fuelep,nation,year] for fuelep in fueleps)
        end
      elseif FuelName =="Crude Oil"
        processes=Select(Process,!=("OilSandsUpgraders"))
        fueleps=Select(FuelEP,["CrudeOil"])
        for year in years
          Production[year]=sum(OProd[process,nation,year] for process in processes)
          Demand[year]=RPPProd[nation,year]
          Imported[year]=sum(Imports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(Exports[fuelep,nation,year] for fuelep in fueleps)
          fuelep=first(fueleps)
          Adjustments[year]=xSupplyAdjustments[fuelep,nation,year]
          Losses[year]=0.0
          PrintImportsMin[year] = sum(ImportsMin[fuelep,nation,year] for fuelep in fueleps)
          PrintExportsMin[year] = sum(ExportsMin[fuelep,nation,year] for fuelep in fueleps)
        end
      elseif FuelName =="Biodiesel"
        biofuels=Select(Biofuel,["Biodiesel"])
        fuels=Select(Fuel,["Biodiesel"])
        fueleps=Select(FuelEP,["Biodiesel"])
        for year in years
          Production[year]=sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks,tech in Techs, biofuel in biofuels)
          Demand[year]=sum(TotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=sum(Imports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(Exports[fuelep,nation,year] for fuelep in fueleps)
          fuelep=first(fueleps)
          # TODO: For Biofuels, historical uses SupplyAdjustments, while endogenous uses xSupplyAdjustments. Revise? LJD, 06.02.25
          Adjustments[year]=xSupplyAdjustments[fuelep,nation,year]
          Losses[year]=0.0
          PrintImportsMin[year] = sum(ImportsMin[fuelep,nation,year] for fuelep in fueleps)
          PrintExportsMin[year] = sum(ExportsMin[fuelep,nation,year] for fuelep in fueleps)
        end
      elseif FuelName =="Ethanol"
        biofuels=Select(Biofuel,["Ethanol"])
        fuels=Select(Fuel,["Ethanol"])
        fueleps=Select(FuelEP,["Ethanol"])
        for year in years
          Production[year]=sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks,tech in Techs, biofuel in biofuels)
          Demand[year]=sum(TotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=sum(Imports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(Exports[fuelep,nation,year] for fuelep in fueleps)
          fuelep=first(fueleps)
          # TODO: For Biofuels, historical uses SupplyAdjustments, while endogenous uses xSupplyAdjustments. Revise? LJD, 06.02.25
          Adjustments[year]=xSupplyAdjustments[fuelep,nation,year]
          Losses[year]=0.0
          PrintImportsMin[year] = sum(ImportsMin[fuelep,nation,year] for fuelep in fueleps)
          PrintExportsMin[year] = sum(ExportsMin[fuelep,nation,year] for fuelep in fueleps)
        end
      elseif FuelName =="Electricity"
        fuels=Select(Fuel,["Electric"])
        for year in years
          # Production[year]=(sum(EGPA[plant,area,year] for area in areas, plant in Plants)+
          #     sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)+
          #     sum(EmEGA[area,year] for area in areas))*3412/1e6         
          #TODO EmEGA is not read-in into the output file in Promula. LJD, 06.02.25
          Production[year]=(sum(EGPA[plant,area,year] for area in areas, plant in Plants)+
              sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs))*3412/1e6         
          Demand[year]=sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)*3412/1e6 
          Imported[year]=sum(ExpPurchases[area,year] for area in areas)*3412/1e6
          Exported[year]=sum(ExpSales[area,year] for area in areas)*3412/1e6
          electric=Select(Fuel,"Electric")
          @finite_math Losses[year]=(sum(SaEC[ecc,area,year]*(1/TDEF[electric,area,year]-1) for area in areas, ecc in ECCs)+
              sum(AreaSales[area,year] for area in areas)-sum(AreaPurchases[area,year] for area in areas))*3412/1e6
          Adjustments[year]=0    
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
      end
      #
      # Balance of Supply
      #
      for year in Years
        Requirements[year]=Demand[year]+Losses[year]+Exported[year]
        Available[year]=Production[year]+Imported[year]+Adjustments[year]
        Balance[year]=Available[year]-Requirements[year]
      end

      # ShowTable
      print(iob, "$(NationDS[nation]) $FuelName Supply Balance (TBtu/Yr);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      print(iob, " Requirements     ;Energy Requirements")
      for year in years
        ZZZ[year] = Requirements[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " TotDemand        ;  Demand")
      for year in years
        ZZZ[year] = Demand[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Losses           ;  Losses")
      for year in years
        ZZZ[year] = Losses[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Exports          ;  Exports")
      for year in years
        ZZZ[year] = Exported[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Available        ;Energy Available")
      for year in years
        ZZZ[year] = Available[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " $ProdDS   ;  Production")
      for year in years
        ZZZ[year] = Production[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Imports          ;  Imports")
      for year in years
        ZZZ[year] = Imported[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " SupplyAdjustments;  Adjustments")
      for year in years
        ZZZ[year] = Adjustments[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Balance          ;Supply Surplus")
      for year in years
        ZZZ[year] = Balance[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Supply Demand Ratio          ;Available/Requirements")
      for year in years
        @finite_math ZZZ[year] = Available[year]/Requirements[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Imports Minimum          ;ImportsMin")
      for year in years
        ZZZ[year] = PrintImportsMin[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, " Exports Minimum          ;ExportsMin")
      for year in years
        ZZZ[year] = PrintExportsMin[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      println(iob)

      #
      # Exogenous Variables
      #
      if FuelName =="Natural Gas"
        processes=Select(Process,["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction"])
        fuels=Select(Fuel,["NaturalGas","NaturalGasRaw"])
        fueleps=Select(FuelEP,["NaturalGas","NaturalGasRaw"])
        for year in years
          Production[year]=sum(xGProd[process,nation,year] for process in processes)
          Demand[year]=sum(xTotDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          fuelep=first(fueleps)
          # Omit NGRaw from Supply Adjustments, Imports, Exports
          Imported[year]=xImports[fuelep,nation,year]
          Exported[year]=xExports[fuelep,nation,year]
          Adjustments[year]=xSupplyAdjustments[fuelep,nation,year]
          Losses[year]=sum(xGProd[process,nation,year] for process in processes)-GMarket[nation,year]-xGRaw[nation,year]
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
      elseif FuelName =="Coal"
        fuels=Select(Fuel,["Coal"])
        fueleps=Select(FuelEP,["Coal"])
        for year in years
          Production[year]=sum(xCAProd[area,year] for area in areas)
          Demand[year]=sum(xEuDemand[fuel,ecc,area,year]+xCgDemand[fuel,ecc,area,year]+xFsDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=sum(xImports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(xExports[fuelep,nation,year] for fuelep in fueleps)
          Adjustments[year]=sum(xSupplyAdjustments[fuelep,nation,year] for fuelep in fueleps)
          Losses[year]=0.0
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
      elseif FuelName =="RPP"
        fuels=Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
                          "Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy",
                          "PetroFeed","PetroCoke","StillGas"])
        fueleps=Select(FuelEP,["Asphaltines","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
                          "Kerosene","LFO","LPG",
                          "PetroCoke","StillGas"])
        for year in years
          Production[year]=sum(xRPPAProd[area,year] for area in areas)
          Demand[year]=sum(xEuDemand[fuel,ecc,area,year]+xCgDemand[fuel,ecc,area,year]+xFsDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=xRPPImports[nation,year]
          Exported[year]=xRPPExports[nation,year]
          Losses[year]=0.0
          # TODO: For RPP, historical uses SupplyAdjustments, while endogenous uses xSupplyAdjustments. Revise? LJD, 06.02.25
          Adjustments[year]=RPPAdjustments[nation,year]
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
      elseif FuelName =="Crude Oil"
        processes=Select(Process,!=("OilSandsUpgraders"))
        fueleps=Select(FuelEP,["CrudeOil"])
        for year in years
          Production[year]=sum(xOProd[process,nation,year] for process in processes)
          Demand[year]=sum(xRPPAProd[area,year] for area in areas)
          Imported[year]=sum(xImports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(xExports[fuelep,nation,year] for fuelep in fueleps)
          Adjustments[year]=sum(xSupplyAdjustments[fuelep,nation,year] for fuelep in fueleps)
          Losses[year]=0.0
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
      elseif FuelName =="Biodiesel"
        biofuels=Select(Biofuel,["Biodiesel"])
        fuels=Select(Fuel,["Biodiesel"])
        fueleps=Select(FuelEP,["Biodiesel"])
        for year in years
          Production[year]=sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks,tech in Techs, biofuel in biofuels)
          Demand[year]=sum(xEuDemand[fuel,ecc,area,year]+xCgDemand[fuel,ecc,area,year]+xFsDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=sum(xImports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(xExports[fuelep,nation,year] for fuelep in fueleps)
          # Adjustments[year]=sum(xSupplyAdjustments[fuelep,nation,year] for fuelep in fueleps)
          fuelep=first(fueleps)
          # TODO: For Biofuels, historical uses SupplyAdjustments, while endogenous uses xSupplyAdjustments. Revise? LJD, 06.02.25
          Adjustments[year]=SupplyAdjustments[fuelep,nation,year]
          Losses[year]=0.0
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
       elseif FuelName =="Ethanol"
        biofuels=Select(Biofuel,["Ethanol"])
        fuels=Select(Fuel,["Ethanol"])
        fueleps=Select(FuelEP,["Ethanol"])
        for year in years
          Production[year]=sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks,tech in Techs, biofuel in biofuels)
          Demand[year]=sum(xEuDemand[fuel,ecc,area,year]+xCgDemand[fuel,ecc,area,year]+xFsDemand[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in fuels)
          Imported[year]=sum(xImports[fuelep,nation,year] for fuelep in fueleps)
          Exported[year]=sum(xExports[fuelep,nation,year] for fuelep in fueleps)
          fuelep=first(fueleps)
          # TODO: For Biofuels, historical uses SupplyAdjustments, while endogenous uses xSupplyAdjustments. Revise? LJD, 06.02.25
          Adjustments[year]=SupplyAdjustments[fuelep,nation,year]
          Losses[year]=0.0
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
      elseif FuelName =="Electricity"
        fuels=Select(Fuel,["Electric"])
        for year in years
          Production[year]=(sum(xEGPA[plant,area,year] for area in areas, plant in Plants)+
              sum(xPSoECC[ecc,area,year] for area in areas, ecc in ECCs))*3412/1e6         
          Demand[year]=sum(xSaEC[ecc,area,year] for area in areas, ecc in ECCs)*3412/1e6 
          Imported[year]=sum(xExpPurchases[area,year] for area in areas)*3412/1e6
          Exported[year]=sum(xExpSales[area,year] for area in areas)*3412/1e6
          electric=Select(Fuel,"Electric")
          @finite_math Losses[year]=(sum(xSaEC[ecc,area,year]*(1/TDEF[electric,area,year]-1) for area in areas, ecc in ECCs)+
              sum(xAreaSales[area,year] for area in areas)-sum(xAreaPurchases[area,year] for area in areas))*3412/1e6
          Adjustments[year]=0    
          PrintImportsMin[year] = -1
          PrintExportsMin[year] = -1
        end
      end
      #
      # Balance of Supply
      #
      for year in Years
        Requirements[year]=Demand[year]+Losses[year]+Exported[year]
        Available[year]=Production[year]+Imported[year]+Adjustments[year]
        Balance[year]=Available[year]-Requirements[year]
      end

      # ShowTable
      print(iob, "$(NationDS[nation]) $FuelName Historical Supply Balance (TBtu/Yr);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      print(iob, "xRequirements     ;Energy Requirements")
      for year in years
        ZZZ[year] = Requirements[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xTotDemand        ;  Demand")
      for year in years
        ZZZ[year] = Demand[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xLosses           ;  Losses")
      for year in years
        ZZZ[year] = Losses[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xExports          ;  Exports")
      for year in years
        ZZZ[year] = Exported[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xAvailable        ;Energy Available")
      for year in years
        ZZZ[year] = Available[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "x$ProdDS   ;  Production")
      for year in years
        ZZZ[year] = Production[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xImports          ;  Imports")
      for year in years
        ZZZ[year] = Imported[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xSupplyAdjustments;  Adjustments")
      for year in years
        ZZZ[year] = Adjustments[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xBalance          ;Supply Surplus")
      for year in years
        ZZZ[year] = Balance[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xSupply Demand Ratio          ;Available/Requirements")
      for year in years
        @finite_math ZZZ[year] = Available[year]/Requirements[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xImports Minimum          ;ImportsMin")
      for year in years
        ZZZ[year] = PrintImportsMin[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      print(iob, "xExports Minimum          ;ExportsMin")
      for year in years
        ZZZ[year] = PrintExportsMin[year]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
      println(iob)
      #
      # End Do Nation  
    end
  end

  filename = "SupplyBalance-$FuelName-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function SupplyBalance_DtaControl(db)
  @info "SupplyBalance_DtaControl"
  data = SupplyBalanceData(; db)

  ConversionValues(data)
  
# Arguments:         data, FuelName,     ProdDS,  SceName 
SupplyBalance_DtaRun(data,"Natural Gas","GProd")
SupplyBalance_DtaRun(data,"Coal",       "CAProd")
SupplyBalance_DtaRun(data,"RPP",        "RPPProd")
SupplyBalance_DtaRun(data,"Crude Oil",  "OProd")
SupplyBalance_DtaRun(data,"Biodiesel",  "BfProd")
SupplyBalance_DtaRun(data,"Ethanol",    "BfProd")
SupplyBalance_DtaRun(data,"Electricity","EAProd")

end


if abspath(PROGRAM_FILE) == @__FILE__
SupplyBalance_DtaControl(DB)
end

