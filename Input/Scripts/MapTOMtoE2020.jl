#
# MapTOMtoE2020.jl - Map TOM Economic Data to Model Variables
#

using EnergyModel

module MapTOMtoE2020

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  CNAreaTOM::SetArray = ReadDisk(db,"KInput/CNAreaTOMKey")
  CNAreaTOMs::Vector{Int} = collect(Select(CNAreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCFloorspaceTOM::SetArray = ReadDisk(db,"KInput/ECCFloorspaceTOMKey")
  ECCFloorspaceTOMs::Vector{Int} = collect(Select(ECCFloorspaceTOM))
  ECCResTOM::SetArray = ReadDisk(db,"KInput/ECCResTOMKey")
  ECCResTOMs::Vector{Int} = collect(Select(ECCResTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  NationTOM::SetArray = ReadDisk(db,"KInput/NationTOMKey")
  NationTOMs::Vector{Int} = collect(Select(NationTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CPI::VariableArray{2} = ReadDisk(db,"KOutput/CPI")  # [AreaTOM,Year] Consumer Price Index by Area (Index 2002=100)
  CPINation::VariableArray{2} = ReadDisk(db,"KOutput/CPINation")     # [NationTOM,Year]  Consumer Price Index by Nation (Index 2002=100)
  CPIndex::VariableArray{2} = ReadDisk(db,"MInput/CPIndex")     # [Nation,Year] Consumer Price Index (1992=100)
  CPIndexNation::VariableArray{2} = ReadDisk(db,"MInput/CPIndexNation")   # [Nation,Year] Consumer Price Index By Area (1992=100)
  EmpTOM::VariableArray{3} = ReadDisk(db,"KOutput/EmpTOM") # [ECCTOM,AreaTOM,Year]  Employment, All Industries, NAICS 1, Persons (People)
  Floorspace::VariableArray{3} = ReadDisk(db,"MOutput/Floorspace")   # [ECC,Area,Year] Floor Space (Million Sq Ft)
  FlrSpc::VariableArray{3} = ReadDisk(db,"KOutput/FlrSpc") # [ECCFloorspaceTOM,CNAreaTOM,Year]  Floorspace (1000 Sq Meters)
  FSFraction::VariableArray{2} = ReadDisk(db,"MInput/FSFraction")    # [ECC,Year] Fraction to Split Informetrica Floor Space into ENERGY 2020 Sectors (Sq Ft/Sq Ft)
  GDP::VariableArray{2} = ReadDisk(db,"KOutput/GDP")  # [AreaTOM,Year] GDP Gross Domestic Product (2017 $M/Yr)
  GDPDeflator::VariableArray{2} = ReadDisk(db,"MOutput/GDPDeflator") # [Nation,Year] GDP Deflator (Index)
  GDPDeflTOM::VariableArray{2} = ReadDisk(db,"MInput/GDPDeflTOM")   # [Nation,Year] Implicit Price Deflator: GDP at Market Prices (Index 2017=100)
  GDPNation::VariableArray{2} = ReadDisk(db,"KOutput/GDPNation")     # [NationTOM,Year]  GDP Gross Domestic Product (2017 $M/Yr)
  GDPSector::VariableArray{3} = ReadDisk(db,"MInput/GDPSector") # [ECC,Area,Year] GDP By Sector (1997 Million CN$/Yr)
  GDPSectorTOM::VariableArray{3} = ReadDisk(db,"MInput/GDPSectorTOM")    # [ECC,Area,Year]  GDP By Sector (2017 Real Million $/Yr)
  GVA_TOM::VariableArray{3} = ReadDisk(db,"KOutput/GVA_TOM")    # [ECCTOM,AreaTOM,Year] Gross Value Added (2017 $M/Yr)
  GY::VariableArray{3} = ReadDisk(db,"KOutput/GY")    # [ECCTOM,AreaTOM,Year] Gross Output (2017 $M/Yr)
  GYAdjust::VariableArray{3} = ReadDisk(db,"KOutput/GYAdjust")  # [ECCTOM,AreaTOM,Year] Gross Output from TOM, Adjusted (2017 $M/Yr)
  HH::VariableArray{3} = ReadDisk(db,"KOutput/HH")    # [ECCResTOM,CNAreaTOM,Year] Households (Households)
  INST::Float32 = ReadDisk(db,"MInput/INST")     # Inflation Rate Smooth Time (Years)
  LaborForce::VariableArray{2} = ReadDisk(db,"MInput/LaborForce") # [Nation,Area]  Total Labor Force, Age 15+ (000s)
  LS::VariableArray{2} = ReadDisk(db,"KOutput/LS")    # [NationTOM,Year]  Labor Force (Persons)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM")   # [Area,AreaTOM]  Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapCNAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapCNAreaTOM")    # [Area,CNAreaTOM]  Map between Area and AreaTOM
  MapECCFloorspaceTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCFloorspaceTOM")     # [ECC,ECCFloorspaceTOM] Map between ECCFloorspaceTOM and ECC
  MapfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapfromECCTOM")  # [ECC,ECCTOM]  Map from ECCTOM to ECC
  MapUSfromECCTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSfromECCTOM")   # [ECC,ECCTOM]  Map between ECCTOM and ECC for the US
  MapECCResTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCResTOM")    # [ECC,ECCResTOM]  Map between ECCResTOM and ECC
  PEDY::VariableArray{2} = ReadDisk(db,"KOutput/PEDY")     # [AreaTOM,Year]  Income, personal disposable, real (2017 $M/Yr)
  PEY::VariableArray{2} = ReadDisk(db,"KOutput/PEY")  # [AreaTOM,Year]  Personal Income, Real, LCU (2017 $M/Yr)
  PGDP::VariableArray{2} = ReadDisk(db,"KOutput/PGDP") # [NationTOM,Year] Implicit Price Deflator: Gross domestic product at market prices (Index 2017=100)
  PopTOM::VariableArray{2} = ReadDisk(db,"KOutput/PopTOM") # [AreaTOM,Year]  Population (People)
  RealDispInc::VariableArray{2} = ReadDisk(db,"MInput/RealDispInc") # [Area,Year]  Real Disposable Income (2017 $M/Yr)
  RXD::VariableArray{2} = ReadDisk(db,"KOutput/RXD")  # [NationTOM,Year]  Exchange Rates (CN$/US$)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  xCPITOM::VariableArray{2} = ReadDisk(db,"MInput/xCPITOM")     # [Nation,Year] Consumer Price Index from TOM by Area (2002=100)
  xCPINationTOM::VariableArray{2} = ReadDisk(db,"MInput/xCPINationTOM")  # [Nation,Year]  Consumer Price Index from TOM by Nation (2002=100)
  xEmp::VariableArray{3} = ReadDisk(db,"MInput/xEmp") # [ECC,Area,Year] Employment (Thousands)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate")   # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xFloorspaceTOM::VariableArray{3} = ReadDisk(db,"MInput/xFloorspaceTOM")     # [ECC,Area,Year]  Commercial Floor Space from TOM (Million Sq Ft)',
  xGDPChained::VariableArray{2} = ReadDisk(db,"MInput/xGDPChained") # [Nation,Year]  Chained National GDP(Chained 2017 Million $/Yr)',
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO")   # [ECC,Area,Year] Gross Output (2017 M$/Yr)
  xGOTOM::VariableArray{3} = ReadDisk(db,"MInput/xGOTOM")  # [ECC,Area,Year] Gross Output (2017 M$/Yr)
  xGRP::VariableArray{2} = ReadDisk(db,"MInput/xGRP") # [Area,Year] Gross Regional Product (2017 M$/Yr)
  xGRPTOM::VariableArray{2} = ReadDisk(db,"MInput/xGRPTOM")     # [Area,Year] Gross Regional Product from TOM (2012 $M/Yr)
  xHHS::VariableArray{3} = ReadDisk(db,"MInput/xHHS") # [ECC,Area,Year] Households (Households)
  xHHSTOM::VariableArray{3} = ReadDisk(db,"MInput/xHHSTOM")     # [ECC,Area,Year] Households from TOM (Households)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation")    # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation")  # [Nation,Year]  Inflation Index ($/$)
  xInflationRate::VariableArray{2} = ReadDisk(db,"MInput/xInflationRate") # [Area,Year] Inflation Rate ($/$)
  xInflationRateNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationRateNation")    # [Nation,Year] Inflation Rate ($/$)
  xInSm::VariableArray{2} = ReadDisk(db,"MInput/xInSm")    # [Area,Year] Smoothed Inflation Rate (1/Yr)
  xPopT::VariableArray{2} = ReadDisk(db,"MInput/xPopT")    # [Area,Year] Population (Millions)
  xPopTTOM::VariableArray{2} = ReadDisk(db,"MInput/xPopTTOM")   # [Area,Year] Population from TOM (Millions)
  xRPI::VariableArray{2} = ReadDisk(db,"MInput/xRPI") # [Area,Year] Total Personal Income (Real M$/Yr)
  xRPITOM::VariableArray{2} = ReadDisk(db,"MInput/xRPITOM")     # [Area,Year] Total Personal Income from TOM (Real M$/Yr)
  xTHHS::VariableArray{2} = ReadDisk(db,"MInput/xTHHS")    # [Area,Year] Total Households (Households)

  #
  # Scratch Variables
  #
  EmpTOMECC::VariableArray{3} = zeros(Float32,length(ECC),length(AreaTOM),length(Year))  # [ECC,AreaTOM,Year] Employment Mapped to ECCs (People)
  FloorspaceCNAreaTOM::VariableArray{3} = zeros(Float32,length(ECC),length(CNAreaTOM),length(Year)) # [ECC,CNAreaTOM,Year]  Floor Space (Million Sq Ft)
  xGOECC::VariableArray{3} = zeros(Float32,length(ECC),length(AreaTOM),length(Year)) # [ECC,AreaTOM,Year]  Gross Output (2017 $M/Yr)
  xHHSCNAreaTOM::VariableArray{3} = zeros(Float32,length(ECC),length(CNAreaTOM),length(Year)) # [ECC,CNAreaTOM,Year]  Households (Households)
  YECC::VariableArray{3} = zeros(Float32,length(ECC),length(AreaTOM),length(Year)) # [ECC,AreaTOM,Year]  GDP by Sector (2017 $M/Yr)
end

function TOMGDPDeflator(db)
  data = MControl(; db)
  (; Areas,Nation,Nations,NationTOM,Years) = data
  (; ANMap,GDPDeflTOM,GDPDeflator,INST) = data
  (; PGDP,xInflation,xInflationNation,xInSm) = data
  (; xInflationRate,xInflationRateNation) = data

  US = Select(NationTOM,"US")
  CN = Select(NationTOM,"CN")

  for year in Years, nation in Nations
    GDPDeflTOM[nation,year] = PGDP[US,year]
  end

  nation = Select(Nation,"CN")
  for year in Years
    GDPDeflTOM[nation,year] = PGDP[CN,year]
  end

  for year in Years, nation in Nations
    GDPDeflator[nation,year] = GDPDeflTOM[nation,year]
  end

  for area in Areas
    xInflation[area,1] = 1.0
  end

  for nation in Nations
    xInflationNation[nation,1] = 1.0
  end

  years = collect(2:Final)

  US = Select(NationTOM,"US")
  CN = Select(NationTOM,"CN")
  nations = Select(Nation,["US","MX","ROW"])

  for year in years, nation in nations
    xInflationNation[nation,year] = PGDP[US,year]/PGDP[US,1]
  end

  nations = Select(Nation,"CN")
  for year in years, nation in nations
    xInflationNation[nation,year] = PGDP[CN,year]/PGDP[CN,1]
  end
  
  US = Select(Nation,"US")
  for year in years, area in Areas
    xInflation[area,year] = xInflationNation[US,year]
  end
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  for year in years, area in areas
    xInflation[area,year] = xInflationNation[CN,year]
  end

  for year in years, area in Areas
    xInflationRate[area,year] = (xInflation[area,year]-xInflation[area,year-1])/xInflation[area,year-1]
  end
  for year in years, nation in Nations
    xInflationRateNation[nation,year] = (xInflationNation[nation,year]-xInflationNation[nation,year-1])/xInflationNation[nation,year-1]
  end

  for area in Areas
      xInSm[area,1] = xInflationRate[area,2]
  end
  for year in years, area in Areas
    xInSm[area,year] = xInSm[area,year-1]+(xInflationRate[area,year]-xInSm[area,year-1])/INST
  end

  WriteDisk(db,"MOutput/GDPDeflator",GDPDeflator)
  WriteDisk(db,"MInput/GDPDeflTOM",GDPDeflTOM)
  WriteDisk(db,"MInput/xInflation",xInflation)
  WriteDisk(db,"MInput/xInflationNation",xInflationNation)
  WriteDisk(db,"MInput/xInflationRate",xInflationRate)
  WriteDisk(db,"MInput/xInflationRateNation",xInflationRateNation)
  WriteDisk(db,"MInput/xInSm",xInSm)
end

#
######################
#
function TOMExchangeRate(db)
  data = MControl(; db)
  (; Areas,Nation,Nations,NationTOM,Years) = data
  (; ANMap,RXD,xExchangeRate,xExchangeRateNation) = data

  for year in Years, area in Areas
    xExchangeRate[area,year] = 1
  end
  for year in Years, nation in Nations
    xExchangeRateNation[nation,year] = 1
  end

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  nationtom = Select(NationTOM,"CN")
  for year in Years, area in areas
    xExchangeRate[area,year] = RXD[nationtom,year]
  end
  for year in Years
    xExchangeRateNation[CN,year] = RXD[nationtom,year]
  end

  WriteDisk(db,"MInput/xExchangeRate",xExchangeRate)
  WriteDisk(db,"MInput/xExchangeRateNation",xExchangeRateNation)
end

#
######################
#
function TOMDisposableIncome(db)
  data = MControl(; db)
  (; Areas,AreaTOMs,Years) = data
  (; MapAreaTOM,PEDY,RealDispInc) = data

  for year in Years, area in Areas
    RealDispInc[area,year] = sum(PEDY[areatom,year]*MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end

  WriteDisk(db,"MInput/RealDispInc",RealDispInc)
end

#
######################
#
function TOMEmployment(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOM,AreaTOMs,ECCs,ECCTOMs) = data
  (; Nation,Years) = data
  (; EmpTOM,EmpTOMECC,MapAreaTOM,MapAreaTOMNation,MapfromECCTOM,MapUSfromECCTOM) = data
  (; xEmp) = data

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
  for year in Years, areatom in areatoms, ecc in ECCs
    EmpTOMECC[ecc,areatom,year] = sum(EmpTOM[ecctom,areatom,year]/1000*
      MapfromECCTOM[ecc,ecctom] for ecctom in ECCTOMs)
  end

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  for year in Years, areatom in areatoms, ecc in ECCs
    EmpTOMECC[ecc,areatom,year] = sum(EmpTOM[ecctom,areatom,year]/1000*
      MapUSfromECCTOM[ecc,ecctom] for ecctom in ECCTOMs)
  end

  for year in Years, area in Areas, ecc in ECCs
    xEmp[ecc,area,year] = sum(EmpTOMECC[ecc,areatom,year]*
      MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end
    WriteDisk(db,"MInput/xEmp",xEmp)
end

#
######################
#
function TOMFloorspace(db)
  data = MControl(; db)
  (; Area,CNAreaTOMs,ECC,ECCs) = data
  (; ECCFloorspaceTOMs,Nation,Years) = data
  (; ANMap) = data
  (; Floorspace,FloorspaceCNAreaTOM,FlrSpc,FSFraction) = data
  (; MapCNAreaTOM,MapECCFloorspaceTOM) = data

  #
  # 1 square foot = 0.0929 square meter
  # 1 square meter = 10.7639 square feet

  #
  # Floorspace only exists for Canada in TOM
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  for year in Years, cnareatom in CNAreaTOMs, ecc in ECCs
    FloorspaceCNAreaTOM[ecc,cnareatom,year] = sum(FlrSpc[eccfloorspacetom,cnareatom,year]*
      10.7639*1000/1000000*MapECCFloorspaceTOM[ecc,eccfloorspacetom] for eccfloorspacetom in ECCFloorspaceTOMs)
  end

  for year in Years, area in areas, ecc in ECCs
    Floorspace[ecc,area,year] = sum(FloorspaceCNAreaTOM[ecc,cnareatom,year]*
      MapCNAreaTOM[area,cnareatom] for cnareatom in CNAreaTOMs)
  end

  #
  # Split Commercial Floor Space between Retail and Wholesale with FSFraction
  #
  for year in Years, area in areas, ecc in ECCs
    Floorspace[ecc,area,year] = Floorspace[ecc,area,year]*FSFraction[ecc,year]
  end


  WriteDisk(db,"MOutput/Floorspace",Floorspace)
end

#
######################
#
function TOMGrossDomesticProduct(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOMs,Nation,NationTOM,Years) = data
  (; ANMap,GDP,GDPNation,MapAreaTOM,xGDPChained,xGRP) = data

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  nationtom_cn = Select(NationTOM,"CN")
  nationtom_us = Select(NationTOM,"US")
  for year in Years
    xGDPChained[CN,year] = GDPNation[nationtom_cn,year]
    xGDPChained[US,year] = GDPNation[nationtom_us,year]
  end

  areas1 = findall(ANMap[:,CN] .== 1.0)
  areas2 = findall(ANMap[:,US] .== 1.0)
  areas = union(areas1,areas2)
  for year in Years, area in areas
    xGRP[area,year] = sum(GDP[areatom,year]*MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end

  #
  # Patch missing values
  #
  areas = findall(ANMap[:,US] .== 1.0)
  years = collect(Yr(1985):Yr(1996))
  for year in years, area in areas
    xGRP[area,year] = xGRP[area,Yr(1997)]
  end

  areas = Select(Area,["NU","NT"])
  years = collect(Yr(1985):Yr(1998))
  for year in years, area in areas
    xGRP[area,year] = xGRP[area,Yr(1999)]
  end

  WriteDisk(db,"MInput/xGRP",xGRP)
  WriteDisk(db,"MInput/xGDPChained",xGDPChained)
end

#
######################
#
function TOMGrossOutput(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOM,AreaTOMs,ECC,ECCs) = data
  (; ECCTOM,ECCTOMs,Nation,NationTOM,Years) = data
  (; ANMap,GY,GYAdjust) = data
  (; MapAreaTOM,MapAreaTOMNation,MapfromECCTOM) = data
  (; MapUSfromECCTOM,PEY,xGO,xGOECC) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
  
  for year in Years, area in areas, ecc in ECCs
    xGO[ecc,area,year] = 0
  end
  for year in Years, areatom in areatoms, ecctom in ECCTOMs
    GYAdjust[ecctom,areatom,year] = 0
  end
  for year in Years, areatom in areatoms, ecctom in ECCTOMs
    GYAdjust[ecctom,areatom,year] = GY[ecctom,areatom,year]
  end
  for year in Years, areatom in areatoms, ecc in ECCs
    xGOECC[ecc,areatom,year] = sum(GYAdjust[ecctom,areatom,year]*
      MapfromECCTOM[ecc,ecctom] for ecctom in ECCTOMs)
  end
  for year in Years, area in areas, ecc in ECCs
    xGO[ecc,area,year]  =sum(xGOECC[ecc,areatom,year]*
      MapAreaTOM[area,areatom] for areatom in areatoms)
  end

  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)  
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)

  for year in Years, area in areas, ecc in ECCs
    xGO[ecc,area,year] = 0
  end
  for year in Years, areatom in areatoms, ecctom in ECCTOMs
    GYAdjust[ecctom,areatom,year] = 0
  end
  for year in Years, areatom in areatoms, ecctom in ECCTOMs
    GYAdjust[ecctom,areatom,year] = GY[ecctom,areatom,year]
  end
  for year in Years, areatom in areatoms, ecc in ECCs
    xGOECC[ecc,areatom,year] = sum(GYAdjust[ecctom,areatom,year]*
      MapUSfromECCTOM[ecc,ecctom] for ecctom in ECCTOMs)
  end
  for year in Years, area in areas, ecc in ECCs
    xGO[ecc,area,year] = sum(xGOECC[ecc,areatom,year]*
      MapAreaTOM[area,areatom] for areatom in areatoms)
  end

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas1 = findall(ANMap[:,CN] .== 1.0)
  areas2 = findall(ANMap[:,US] .== 1.0)  
  areas = union(areas1,areas2)
  
  #
  # Residential - Assign personal income to residential xGO
  #
  eccs = Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
  for year in Years, area in areas, ecc in eccs
    xGO[ecc,area,year] = sum(PEY[areatom,year]*
      MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end

  WriteDisk(db,"KOutput/GYAdjust",GYAdjust)
  WriteDisk(db,"MInput/xGO",xGO)
end

#
######################
#
function AdjustTOMGrossOutput(db)
  data = MControl(; db)
  (; Area,AreaTOM,AreaTOMs,ECC,ECCs,ECCTOM,ECCTOMs,Nation) = data
  (; ANMap,GY,GYAdjust,MapAreaTOMNation,xGO) = data

  #
  # Temporary Patches
  #
  # In Nunavut, 0's before 1999
  #
  areas = Select(Area,"NU")
  areatoms = Select(AreaTOM,"NU")
  years = collect(Yr(1985):Yr(1998))
  for year in years, area in areas, ecc in ECCs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(1999)]
  end
  for year in years, areatom in areatoms, ecctom in ECCTOMs
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(1999)]
  end

  areas = Select(Area,"NU")
  areatoms = Select(AreaTOM,"NU")
  years = collect(Yr(1985):Yr(2009))
  eccs = Select(ECC,["Fertilizer","OtherChemicals"])
  ecctoms = Select(ECCTOM,["Fertilizer","OtherChemicalsOrganic","Pharmaceuticals"])
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(2010)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(2010)]
  end

  #
  # 0's before 2014 in Nunavut IronOreMining, but demand back to 1985
  # Assign non-zero values based on calculated values in Pine (0.088). 8/8/25 R.Levesque
  #
  areas = Select(Area,"NU")
  areatoms = Select(AreaTOM,"NU")
  years = collect(Yr(1985):Yr(2013))
  eccs = Select(ECC,["IronOreMining"])
  ecctoms = Select(ECCTOM,["IronOreMining"])
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = 0.088
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = 0.088
  end
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1)
  eccs = Select(ECC,"Forestry")
  ecctoms = Select(ECCTOM,"Forestry")
  for area in areas, ecc in eccs
    xGO[ecc,area,Yr(1985)] = xGO[ecc,area,Yr(1986)]
  end
  for areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,Yr(1985)] = GYAdjust[ecctom,areatom,Yr(1986)]
  end

  areas = Select(Area,"YT")
  areatoms = Select(AreaTOM,"YT")
  eccs = Select(ECC,"Warehouse")
  ecctoms = Select(ECCTOM,"Warehouse")
  years = collect(Yr(1985):Yr(1986))
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(1987)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(1987)]
  end

  areas = Select(Area,"NT")
  areatoms = Select(AreaTOM,"NT")
  eccs = Select(ECC,["Fertilizer","OtherChemicals"])
  ecctoms = Select(ECCTOM,["Fertilizer","OtherChemicalsOrganic","Pharmaceuticals"])
  years = collect(Yr(1985):Yr(1996))
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(1997)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(1997)]
  end

  areas = Select(Area,"NT")
  areatoms = Select(AreaTOM,"NT")
  eccs = Select(ECC,"NGDistribution")
  ecctoms = Select(ECCTOM,"NGDistribution")
  years = collect(Yr(1985):Yr(2007))
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(2008)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(2008)]
  end

  #
  # OtherNonferrous in U.S. has no demand, so 0's in xGO do not get assigned values
  # However, there are values for xMEPol, so we need xGOs to calc MEPOCX.
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  eccs = Select(ECC,"OtherNonferrous")
  ecctoms = Select(ECCTOM,(from="NonferrousFoundries",to="NonferrousSmelting"))
  years = collect(Yr(1985):Yr(2016))
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(2017)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(2017)]
  end

  #
  # California NGPipelines gross output goes to very small post 2017
  #
  areas = Select(Area,"CA")
  areatoms = Select(AreaTOM,"CA")
  eccs = Select(ECC,"NGPipeline")
  ecctoms = Select(ECCTOM,"NGPipeline")
  years = collect(Yr(2018):Final)
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(2017)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(2017)]
  end

  #
  # California Coal Mining gross output has values in 1998 then in 2009
  #
  areas = Select(Area,"CA")
  areatoms = Select(AreaTOM,"CA")
  eccs = Select(ECC,"CoalMining")
  ecctoms = Select(ECCTOM,"CoalMining")
  years = Yr(1997)
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(1996)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(1996)]
  end
  years = collect(Yr(1999):Yr(2008))
  for year in years, area in areas, ecc in eccs
    xGO[ecc,area,year] = xGO[ecc,area,Yr(2009)]
  end
  for year in years, areatom in areatoms, ecctom in ecctoms
    GYAdjust[ecctom,areatom,year] = GYAdjust[ecctom,areatom,Yr(2009)]
  end

  WriteDisk(db,"MInput/xGO",xGO)
  WriteDisk(db,"KOutput/GYAdjust",GYAdjust)
end

#
######################
#
function TOMHouseholds(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOMs,CNAreaTOMs,ECCs,ECCResTOMs) = data
  (; Nation,Years) = data
  (; ANMap,HH,MapCNAreaTOM,MapECCResTOM) = data
  (; xHHS,xHHSCNAreaTOM,xTHHS) = data

  #
  # Households originally only existed for Canada in TOM
  # TODO:  Read in US households (stop using AEO's households)
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  for year in Years, cnareatom in CNAreaTOMs, ecc in ECCs
    xHHSCNAreaTOM[ecc,cnareatom,year] = sum(HH[eccrestom,cnareatom,year]*
        MapECCResTOM[ecc,eccrestom] for eccrestom in ECCResTOMs)
  end
  
  for year in Years, area in areas, ecc in ECCs
    xHHS[ecc,area,year] = sum(xHHSCNAreaTOM[ecc,cnareatom,year]*
        MapCNAreaTOM[area,cnareatom] for cnareatom in CNAreaTOMs)
  end

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  for year in Years, area in areas
    xTHHS[area,year] = sum(xHHS[ecc,area,year] for ecc in ECCs)
  end

  WriteDisk(db,"MInput/xHHS",xHHS)
  WriteDisk(db,"MInput/xTHHS",xTHHS)
end

#
######################
#
function TOMPersonalIncome(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOMs,ECCs) = data
  (; Nation,Years) = data
  (; ANMap,MapAreaTOM,PEY,xRPI) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas1 = findall(ANMap[:,CN] .== 1.0)
  areas2 = findall(ANMap[:,US] .== 1.0)
  areas = union(areas1,areas2)
  
  for year in Years, area in areas
    xRPI[area,year] = sum(PEY[areatom,year]*MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end

  #
  # Patch for missing values in TOM
  #
  areas = Select(Area,["NT","NU"])
  years = collect(Yr(1985):Yr(1998))
  for year in years, area in areas
    xRPI[area,year] = xRPI[area,Yr(1999)]
  end

  WriteDisk(db,"MInput/xRPI",xRPI)
end

#
######################
#
function TOMPopulation(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOMs,Nation,Years) = data
  (; ANMap,MapAreaTOM,PopTOM,xPopT) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas1 = findall(ANMap[:,CN] .== 1.0)
  areas2 = findall(ANMap[:,US] .== 1.0)
  areas = union(areas1,areas2)
  
  for year in Years, area in areas
    xPopT[area,year] = sum(PopTOM[areatom,year]*MapAreaTOM[area,areatom] for areatom in AreaTOMs)/1e6
  end

  #
  # Patch for missing values
  #
  years = collect(Yr(1985):Yr(1990))
  areas = Select(Area,["NT","NU"])
  for year in years, area in areas
    xPopT[area,year] = xPopT[area,Yr(1991)]
  end

  WriteDisk(db,"MInput/xPopT",xPopT)
end

#
######################
#
function TOMLaborForce(db)
  data = MControl(; db)
  (; Nation,Nations,NationTOM,Years) = data
  (; LaborForce,LS) = data

  for year in Years, nation in Nations
    LaborForce[nation,year] = 0
  end

  nations = Select(Nation,"CN")
  CN = Select(NationTOM,"CN")
  for year in Years, nation in nations
    LaborForce[nation,year] = LS[CN,year]/1000
  end

  nations = Select(Nation,"US")
  US = Select(NationTOM,"US")
  for year in Years, nation in nations
    LaborForce[nation,year] = LS[US,year]/1000
  end

  WriteDisk(db,"MInput/LaborForce",LaborForce)
end

#
######################
#
function TOMGDPSector(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOM,AreaTOMs,ECC) = data
  (; ECCTOM,ECCTOMs,Nation,Years) = data
  (; ANMap,GDPSector,GVA_TOM,MapAreaTOM,MapAreaTOMNation) = data
  (; MapfromECCTOM,MapUSfromECCTOM,PEY,YECC) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas1 = findall(ANMap[:,CN] .== 1.0)
  areas2 = findall(ANMap[:,US] .== 1.0)
  areas = union(areas1,areas2)

  #
  # Residential - Save personal income to residential
  #
  eccs = Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
  for year in Years, area in areas, ecc in eccs
    GDPSector[ecc,area,year] = sum(PEY[areatom,year]*
      MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end

  #
  # Commercial and Industrial
  #
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  eccs1 = Select(ECC,(from="Wholesale",to="AnimalProduction"))
  eccs2 = Select(ECC,(from="Passenger",to="CommercialOffRoad"))
  eccs3 = Select(ECC,["UtilityGen","Steam"])
  eccs = union(eccs1,eccs2,eccs3)
  for year in Years, areatom in areatoms, ecc in eccs
    YECC[ecc,areatom,year] = sum(GVA_TOM[ecctom,areatom,year]*
      MapfromECCTOM[ecc,ecctom] for ecctom in ECCTOMs)
  end

  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  for year in Years, areatom in areatoms, ecc in eccs
    YECC[ecc,areatom,year] = sum(GVA_TOM[ecctom,areatom,year]*
      MapUSfromECCTOM[ecc,ecctom] for ecctom in ECCTOMs)
  end

  for year in Years, area in areas, ecc in eccs
    GDPSector[ecc,area,year] = sum(YECC[ecc,areatom,year]*
      MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end

  #
  # Placeholder for Miscellaneous sectors
  #
  eccs1 = Select(ECC,["H2Production","BiofuelProduction"])
  eccs2 = Select(ECC,(from="SolidWaste",to="Biogenics"))
  eccs = union(eccs1,eccs2)
  for year in Years, area in areas, ecc in eccs
    GDPSector[ecc,area,year] = 1.0
  end

  WriteDisk(db,"MInput/GDPSector",GDPSector)
end

#
######################
#
function TOMConsumerPriceIndex(db)
  data = MControl(; db)
  (; Areas,AreaTOMs) = data
  (; Nation,NationTOM,Years) = data
  (; CPI,CPIndex,CPINation,CPIndexNation,MapAreaTOM,xCPITOM,xCPINationTOM) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years, area in Areas
    xCPITOM[area,year] = sum(CPI[areatom,year]*MapAreaTOM[area,areatom] for areatom in AreaTOMs)
  end
  nationtom = Select(NationTOM,"CN")
  for year in Years
    xCPINationTOM[CN,year] = CPINation[nationtom,year]
  end

  nationtom = Select(NationTOM,"US")
  for year in Years
    xCPINationTOM[US,year] = CPINation[nationtom,year]
  end
  
  nations = Select(Nation,["CN","US"])
  for year in Years, nation in nations
    CPIndex[nation,year] = xCPITOM[nation,year]
    CPIndexNation[nation,year] = xCPINationTOM[nation,year]
  end

  WriteDisk(db,"MInput/xCPITOM",xCPITOM)
  WriteDisk(db,"MInput/xCPINationTOM",xCPINationTOM)
  WriteDisk(db,"MInput/CPIndex",CPIndex)
  WriteDisk(db,"MInput/CPIndexNation",CPIndexNation)
end

function StoreTOMValues(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOMs,ECCs) = data
  (; Nation,Years) = data
  (; ANMap,Floorspace,GDPSector,GDPSectorTOM,xFloorspaceTOM) = data
  (; xGO,xGOTOM,xGRP,xGRPTOM,xHHS,xHHSTOM,xRPI,xRPITOM,xPopT,xPopTTOM) = data

  #
  # Households and Floorspace for Canada only
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  for year in Years, area in areas, ecc in ECCs
    xHHSTOM[ecc,area,year] = xHHS[ecc,area,year]
    xFloorspaceTOM[ecc,area,year] = Floorspace[ecc,area,year]
  end

  US = Select(Nation,"US")
  areas1 = findall(ANMap[:,CN] .== 1.0)
  areas2 = findall(ANMap[:,US] .== 1.0)
  areas = union(areas1,areas2)
  
  for year in Years, area in areas
    xRPITOM[area,year] = xRPI[area,year]
    xPopTTOM[area,year] = xPopT[area,year]
    xGRPTOM[area,year] = xGRP[area,year]
  end

  for year in Years, area in areas, ecc in ECCs
    xGOTOM[ecc,area,year] = xGO[ecc,area,year]
    GDPSectorTOM[ecc,area,year] = GDPSector[ecc,area,year]
  end

  WriteDisk(db,"MInput/GDPSectorTOM",GDPSectorTOM)
  WriteDisk(db,"MInput/xFloorspaceTOM",xFloorspaceTOM)
  WriteDisk(db,"MInput/xGRPTOM",xGRPTOM)
  WriteDisk(db,"MInput/xGOTOM",xGOTOM)
  WriteDisk(db,"MInput/xRPITOM",xRPITOM)
  WriteDisk(db,"MInput/xPopTTOM",xPopTTOM)
end

#
######################
#
function ReadTOMValues(db)
  data = MControl(; db)
 
  @info "TOMGDPDeflator"
  TOMGDPDeflator(db)
  @info"TOMExchangeRate"
  TOMExchangeRate(db)
  @info "TOMDisposableIncome"
  TOMDisposableIncome(db)
  @info "TOMEmployment"
  TOMEmployment(db)
  @info "TOMFloorspace"
  TOMFloorspace(db)
  @info "TOMGrossDomesticProduct"
  TOMGrossDomesticProduct(db)
  @info "TOMGrossOutput"
  TOMGrossOutput(db)
  @info "AdjustTOMGrossOutput"
  AdjustTOMGrossOutput(db)
  @info "TOMHouseholds"
  TOMHouseholds(db)
  @info "TOMPersonalIncome"
  TOMPersonalIncome(db)
  @info "TOMPopulation"
  TOMPopulation(db)
  @info "TOMLaborForce"
  TOMLaborForce(db)
  @info "TOMGDPSector"
  TOMGDPSector(db)
  @info "TOMConsumerPriceIndex"
  TOMConsumerPriceIndex(db)
  @info "StoreTOMValues"
  StoreTOMValues(db)
end

function Control(db)
  @info "MapTOMtoE2020.jl - Control"
  ReadTOMValues(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
