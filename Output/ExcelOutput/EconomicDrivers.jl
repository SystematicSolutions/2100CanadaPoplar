#
# EconomicDrivers.jl
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


Base.@kwdef struct EconomicDriversData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "TInput/ECKey")
  ECDS::SetArray = ReadDisk(db, "TInput/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray = ReadDisk(db, "TInput/TechKey")
  TechDS::SetArray = ReadDisk(db, "TInput/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CPIndex::VariableArray{2} = ReadDisk(db, "MInput/CPIndex") #[Area,Year]  Consumer Price Index (1992=100)
  Driver::VariableArray{3} = ReadDisk(db, "MOutput/Driver") # [ECC,Area,Year]  Economic Driver (Various Units)
  DrSwitch::VariableArray{2} = ReadDisk(db, "MInput/DrSwitch", Yr(1990)) # [ECC,Area,Year]  Economic Driver (Various Units)
  Emp::VariableArray{3} = ReadDisk(db, "MOutput/Emp") # [ECC,Area,Year]  Employment (Thousands)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") # [Fuel,Nation,Year]  Primary Fuel Price ($/mmBtu)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") # [Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  Floorspace::VariableArray{3} = ReadDisk(db, "MOutput/Floorspace") # [ECC,Area,Year]  Floorspace (Million Sq Ft)
  FSUnit::VariableArray{3} = ReadDisk(db, "MInput/FSUnit") # [ECC,Area,Year]  Floorspace per Unit (Sq Units/Building)
  GDPSector::VariableArray{3} = ReadDisk(db, "MInput/GDPSector") # [ECC,Area,Year]  GDP By Sector (2017 Million CN$/Yr)
  GRP::VariableArray{2} = ReadDisk(db, "MOutput/GRP") # [Area,Year]  Gross Domestic Product (M$/Yr)
  GO::VariableArray{3} = ReadDisk(db, "MOutput/GO") # [ECC,Area,Year]  Gross Output (1985 M$)
  HHS::VariableArray{3} = ReadDisk(db, "MOutput/HHS") # [ECC,Area,Year]  Households (Households)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year]  Inflation Index
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year]  Inflation Index
  InflationRate::VariableArray{2} = ReadDisk(db, "MOutput/InflationRate") # [Area,Year]  Inflation Rate (1/Yr)
  LaborForce::VariableArray{2} = ReadDisk(db, "MInput/LaborForce") # [Nation,Year]  Total Labor Force, Age 15+ (000s)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  PER::VariableArray{5} = ReadDisk(db, "TOutput/PER") # [Enduse,Tech,EC,Area,Year]  Process Energy Requirement (Miles/Yr)
  Pop::VariableArray{3} = ReadDisk(db, "MOutput/Pop") # [ECC,Area,Year]  Population (Millions)
  PopT::VariableArray{2} = ReadDisk(db, "MOutput/PopT") # [Area,Year]  Population (Millions)
  RealDispInc::VariableArray{2} = ReadDisk(db, "MInput/RealDispInc") # [Area,Year]  Real Disposable Income (Million Real CN$)
  RPI::VariableArray{2} = ReadDisk(db, "MOutput/RPI") # [Area,Year]  Personal Income (1985 M$/Yr)
  SecMap::VariableArray{1} = ReadDisk(db, "SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
  xGDPChained::VariableArray{2} = ReadDisk(db, "MInput/xGDPChained") # [Nation,Year]  Chained National GDP(Chained 2017 Million CN$/Yr)
  xGO::VariableArray{3} = ReadDisk(db, "MInput/xGO") # [ECC,Area,Year]  Gross Output (1985 M$/Yr)

end

function DDisplay(data,ecc,area)
  (; Nation,ANMap,DrSwitch) = data

  CN = Select(Nation,"CN")

  if DrSwitch[ecc,area] == 1
    DrDS="Floorspace (Million Sq Ft)"
  elseif DrSwitch[ecc,area] == 2
    if ANMap[area,CN] == 1
      DrDS="GRP (Million 2017 CN\$/Yr)"
    else # using US$ for MX and ROW
      DrDS="GRP (Million 1985 US\$/Yr)"
    end
  elseif DrSwitch[ecc,area] == 3
    if ANMap[area,CN] == 1
      DrDS="Personal Income (Million 2017 CN\$/Yr)"
    else # using US$ for MX and ROW
      DrDS="Personal Income (Million 1985 US\$/Yr)"
    end
  elseif DrSwitch[ecc,area] == 4
    DrDS="National Oil Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 5
    DrDS="National Gas Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 7
    DrDS="Local Oil Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 8
    DrDS="Local Gas Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 9
    DrDS="Population (Millions)"
  elseif DrSwitch[ecc,area] == 10
    DrDS="Land Area (Million Sq Ft)"
  elseif DrSwitch[ecc,area] == 16
    DrDS="Households (Total)"
  elseif DrSwitch[ecc,area] == 17
    DrDS="Utility Generation (GWh/Yr)"
  elseif DrSwitch[ecc,area] == 18
    DrDS="RPP Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 19
    DrDS="Freight Miles Traveled (Millions Ton-Miles/Yr)"
  elseif DrSwitch[ecc,area] == 20
    if ANMap[area,CN] == 1
      DrDS="Farm Gross Output (Million 2017 CN\$/Yr)"
    else # using US$ for MX and ROW
      DrDS="Farm Gross Output (Million 2017 US\$/Yr)"
    end
  elseif DrSwitch[ecc,area] == 21
    if ANMap[area,CN] == 1
      DrDS="Gross Output (Million 2017 CN\$/Yr)"
    else # using US$ for MX and ROW
      DrDS="Gross Output (Million 2017 US\$/Yr)"
    end
  elseif DrSwitch[ecc,area] == 22
    DrDS="Natural Gas Demands (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 23
    DrDS="Liquid Natural Gas Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 24
    DrDS="Electricity Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 25
    DrDS="Local Nova Scotia Natural Gas Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 26
    DrDS="Biofuel Production (TBtu/Yr)"
  elseif DrSwitch[ecc,area] == 27
    DrDS="Number of Vehicles (Millions)"
  elseif DrSwitch[ecc,area] == 0
    DrDS="Exogenous with Unspecified Units"
  end

  return DrDS
end

function EconomicDrivers_DtaRun(data, areas, AreaName, AreaKey, nation)
  (; SceName,Year,Area,AreaDS,EC,ECDS,ECCs,ECCDS,ESDS,Fuel,FuelDS) = data
  (; Nation,NationDS,Tech,TechDS,Techs) = data
  (; ANMap,CPIndex,Driver,DrSwitch,Emp,ENPN,ExchangeRate) = data
  (; Floorspace,FSUnit,GDPSector,GRP,GO,HHS,Inflation) = data
  (; InflationNation,InflationRate,LaborForce,MoneyUnitDS) = data
  (; PER,Pop,PopT,RealDispInc,RPI,SecMap,xGDPChained,xGO) = data

  FFF = zeros(Float32, length(Year))
  PPP = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))
  area_single = first(areas)
  enduse = 1

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file is created by Economic Drivers.jl.")
  println(iob, " ")

  years = collect(Yr(1990):Final)

  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  #
  # Economic Drivers
  #
  print(iob, AreaName, " Economic Drivers (Various Units);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in ECCs
    for year in years
      ZZZ[year] = sum(Driver[ecc, area, year] for area in areas)
    end
    DrDS = DDisplay(data,ecc,area_single)
    print(iob, "Driver;", ECCDS[ecc], " - $DrDS")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # GDP
  #
  print(iob, "Gross Regional Product (Billions of 2017 ",MoneyUnitDS[area_single],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GRP[area,year] for area in areas)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)]/1000
  end
  print(iob, "GRP;$AreaName")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Personal Income
  #
  print(iob, "Personal Income (Billions of 2017 ",MoneyUnitDS[area_single],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(RPI[area,year] for area in areas)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)]/1000
  end
  print(iob, "RPI;$AreaName")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Population
  #
  print(iob, "Population (Millions);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(PopT[area,year] for area in areas)
  end
  print(iob, "PopT;$AreaName")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # World Oil Price
  #
  fuel = Select(Fuel,"LightCrudeOil")
  print(iob, "World Oil Price (2017 ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = ENPN[fuel,nation,year]*Inflation[nation,Yr(2017)]
  end
  print(iob, "ENPN;",FuelDS[fuel])
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Natural Gas Wellhead Price
  #
  fuel = Select(Fuel,"NaturalGas")
  print(iob, "Natural Gas Wellhead Price (2017 ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = ENPN[fuel,nation,year]*Inflation[nation,Yr(2017)]
  end
  print(iob, "ENPN;",FuelDS[fuel])
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Inflation
  #
  print(iob, AreaName," Inflation (2017=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = Inflation[area_single,year]/Inflation[area_single,Yr(2017)]
  end
  print(iob, "Inflation;$AreaName")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName," Inflation Rate (1/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = InflationRate[area_single,year]
  end
  print(iob, "InflationRate;$AreaName")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Gross Output
  #
  print(iob, AreaName," Gross Output for Most Sectors (Billions of 2017 ",MoneyUnitDS[area_single],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GO[ecc, area, year] for area in areas, ecc in ECCs)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)]/1000
  end  
  print(iob, "GO;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    for year in years
      ZZZ[year] = sum(GO[ecc, area, year] for area in areas)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)]/1000
    end
    print(iob, "GO;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob,"US\$/Local Currency Exchange Rate (US\$/Local);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = 1 ./ ExchangeRate[area_single,year]
  end
  print(iob, "ExchangeRate;Exchange Rate")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Residential Households
  #
  res = Select(ESDS,"Residential")
  res_eccs = findall(SecMap .== res)
  #
  print(iob, AreaName," Households (Millions);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(HHS[ecc, area, year] for area in areas, ecc in res_eccs)/1e6
  end
  print(iob, "HHS;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in res_eccs
    for year in years
      ZZZ[year] = sum(HHS[ecc, area, year] for area in areas)/1e6
    end
    print(iob, "HHS;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Personal Income Per Person
  #
  print(iob, AreaName," Personal Income per Person (2017 ",MoneyUnitDS[area_single],"/Person);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    PPP[year] = sum(Pop[ecc, area, year] for area in areas, ecc in res_eccs)
    ZZZ[year] = sum(GO[ecc, area, year] for area in areas, ecc in res_eccs)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)] ./ PPP[year]
  end
  print(iob, "RPI/Pop;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in res_eccs
    for year in years
      PPP[year] = sum(Pop[ecc, area, year] for area in areas)
      ZZZ[year] = sum(GO[ecc, area, year] for area in areas)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)] ./ PPP[year]
    end  
    print(iob, "RPI/Pop;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # People Per Household
  #
  print(iob, AreaName," People per Household (People/Household);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    PPP[year] = sum(Pop[ecc, area, year] for area in areas, ecc in res_eccs)
    ZZZ[year] = PPP[year] ./ sum(HHS[ecc, area, year] for area in areas, ecc in res_eccs)*1e6
  end
  print(iob, "HSize;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in res_eccs
    for year in years
      PPP[year] = sum(Pop[ecc, area, year] for area in areas)
      ZZZ[year] = PPP[year] ./ sum(HHS[ecc, area, year] for area in areas)*1e6
    end
    print(iob, "HSize;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Transportation Distance Traveled
  #
  ec = Select(EC,"Passenger")
  print(iob, AreaName," Distance Traveled (Millions);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(PER[enduse,tech,ec,area,year] for area in areas, tech in Techs)/1000000*1.609344
  end
  print(iob, "PER;Passenger Kilometers")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  ec = Select(EC,"Freight")
  for year in years
    ZZZ[year] = sum(PER[enduse,tech,ec,area,year] for area in areas, tech in Techs)/1000000*1.609344
  end
  print(iob, "PER;Freight Tonne-Kilometers")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  ec = Select(EC,"ResidentialOffRoad")
  for year in years
    ZZZ[year] = sum(PER[enduse,tech,ec,area,year] for area in areas, tech in Techs)/1000000*1.609344
  end
  print(iob, "PER;Residential Off-Road Kilometers")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  ec = Select(EC,"CommercialOffRoad")
  for year in years
    ZZZ[year] = sum(PER[enduse,tech,ec,area,year] for area in areas, tech in Techs)/1000000*1.609344
  end
  print(iob, "PER;Comercial Off-Road Kilometers")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Passenger Traveled per Person
  #
  ec = Select(EC,"Passenger")
  print(iob, AreaName," Distance Traveled (KM/Person);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    PPP[year] = sum(PopT[area, year] for area in areas)
    ZZZ[year] = sum(PER[enduse,tech,ec,area,year] for area in areas, tech in Techs) ./ (PPP[year]*1e6)*1.609344
  end
    print(iob, "PER/PopT;",ECDS[ec])
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Residential Square Feet
  #
  print(iob, AreaName," Residential Floorspace (Million Sq Feet);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(Floorspace[ecc, area, year] for area in areas, ecc in res_eccs)
  end
  print(iob, "Floorspace;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in res_eccs
    for year in years
      ZZZ[year] = sum(Floorspace[ecc, area, year] for area in areas)
    end
    print(iob, "Floorspace;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Commercial Square Feet
  #
  com = Select(ESDS,"Commercial")
  com_eccs = findall(SecMap .== com)
  #
  print(iob, AreaName," Commercial Floorspace (Million Sq Feet);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(Floorspace[ecc, area, year] for area in areas, ecc in com_eccs)
  end
  print(iob, "Floorspace;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in com_eccs
    for year in years
      ZZZ[year] = sum(Floorspace[ecc, area, year] for area in areas)
    end
    print(iob, "Floorspace;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName," Commercial Output Per Floorspace (2017 ", MoneyUnitDS[area_single],"/1000 Sq Feet);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    @finite_math FFF[year] = sum(Floorspace[ecc, area, year] / FSUnit[ecc, area, year]*1000 for area in areas, ecc in com_eccs)
    @finite_math ZZZ[year] = sum(GO[ecc, area, year] for area in areas, ecc in com_eccs)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)] / FFF[year]
  end
  print(iob, "USize;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in com_eccs
    for year in years
      @finite_math FFF[year] = sum(Floorspace[ecc, area, year] / FSUnit[ecc, area, year]*1000 for area in areas)
      @finite_math ZZZ[year] = sum(GO[ecc, area, year] for area in areas)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)] / FFF[year]
    end
    print(iob, "USize;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # 
  #  Chained National GDP
  # 
  print(iob, NationDS[nation]," Chained National GDP (Chained 2017 Million CN\$/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "xGDPChained;",Nation[nation])
  for year in years
    ZZZ[year] = xGDPChained[nation,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")
  # 
  #  National Labor Force
  # 
  #  Write (NatDS::0," Labor Force (Thousands);",(Year)(";",Yrv(Year)))
  #  ZZZ(Y)=Sum(N)(LaborForce(N,Y))
  #  Write ("LaborForce;",NatKey::0,(Year)(";",ZZZ(Year)))
  #  Write (" ")
  # 
  #  TIM CPI
  # 
  #  Write (AreaDS::0," Consumer Price Index (1992=100);",(Year)(";",Yrv(Year)))
  #  ZZZ(Y)=Sum(A)(CPIndex(A,Y))
  #  Write ("CPIndex;",AreaKey::0,(Year)(";",ZZZ(Year)))
  #  Write (" ")

  #
  # Disposable Income
  #
  ec = Select(EC,"Passenger")
  print(iob, AreaName," Real Disposable Income (Million Real CN\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(RealDispInc[area, year] for area in areas)
  end
  print(iob, "RealDispInc;$AreaKey")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  ######### Commented out in Promula #########
  # 
  #  GDP by Sector
  # 
  #  Write (AreaDS::0," GDP By Sector (2017 Million CN$/Yr);",(Year)(";",Yrv(Year)))
  #  ZZZ(Y)=sum(ECC,Area)(GDPSector(ECC,Area,Y)/Inflation(Area,2017)*Inflation(Area,2017))
  #  Write ("GDPSector;Total",(Year)(";",ZZZ(Year)))
  #  Do ECC
  #    ZZZ(Y)=sum(Area)(GDPSector(ECC,Area,Y))/Inflation(Area,2017)*Inflation(Area,2017)
  #    Write ("GDPSector;",ECCDS::0,(Year)(";",ZZZ(Year)))
  #  End Do ECC
  #  Write (" ")
  # 
  #  Employment
  # 
  #  Write (AreaDS::0," Employment (Thousands);",(Year)(";",Yrv(Year)))
  #  ZZZ(Y)=sum(ECC,Area)(Emp(ECC,Area,Y))
  #  Write ("Emp;Total",(Year)(";",ZZZ(Year)))
  #  Do ECC
  #    ZZZ(Y)=sum(Area)(Emp(ECC,Area,Y))
  #    Write ("Emp;",ECCDS::0,(Year)(";",ZZZ(Year)))
  #  End Do ECC
  #  Write (" ")

  print(iob, AreaName," xGross Output for Most Sectors (Billions of 2017 ",MoneyUnitDS[area_single],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(xGO[ecc, area, year] for area in areas, ecc in ECCs)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)]/1000
  end
  print(iob, "xGO;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    for year in years
      ZZZ[year] = sum(xGO[ecc, area, year] for area in areas)/Inflation[area_single,Yr(2017)]*Inflation[area_single,Yr(2017)]/1000
    end
    print(iob, "xGO;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  filename = "EconomicDrivers-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function EconomicDrivers_DtaControl(db)
  @info "EconomicDrivers_DtaControl"
  data = EconomicDriversData(; db)
  (; Area, AreaDS, Nation) = data

  #
  # Canada
  #
  areas = Select(Area, (from = "ON", to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  nation = Select(Nation,"CN")
  EconomicDrivers_DtaRun(data, areas, AreaName, AreaKey, nation)
  for area in areas
    EconomicDrivers_DtaRun(data, area, AreaDS[area], Area[area], nation)
  end

  #
  #  US
  #
  areas = Select(Area, (from = "CA", to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  nation = Select(Nation,"US")
  EconomicDrivers_DtaRun(data, areas, AreaName, AreaKey, nation)
  for area in areas
    EconomicDrivers_DtaRun(data, area, AreaDS[area], Area[area], nation)
  end

  #
  #  Mexico
  #
  area = Select(Area,"MX")
  nation = Select(Nation,"MX")
  EconomicDrivers_DtaRun(data, area, AreaDS[area], Area[area], nation)
end

if abspath(PROGRAM_FILE) == @__FILE__
EconomicDrivers_DtaControl(DB)
end

