#
# ElectricSummary.jl
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

Base.@kwdef struct ElectricSummaryData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  ClassDS::SetArray = ReadDisk(db,"MainDB/ClassDS")
  Classes::Vector{Int} = collect(Select(Class))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")

  Yr2010 = 2010 - ITime + 1
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  AreaPurchases::VariableArray{2} = ReadDisk(db,"EGOutput/AreaPurchases") # (Area,Year),Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{2} = ReadDisk(db,"EGOutput/AreaSales") # (Area,Year),Sales to Areas in the same Country (GWh/Yr)
  CapCredit::VariableArray{3} = ReadDisk(db,"EGInput/CapCredit") # (Plant,Area,Year),Capacity Credit (MW/MW)
  CgEC::VariableArray{3} = ReadDisk(db,"SOutput/CgEC") # (ECC,Area,Year),Cogeneration by Economic Category (GWh/Yr)
  CgCap::VariableArray{4} = ReadDisk(db,"SOutput/CgCap") # (Fuel,ECC,Area,Year),CCogeneration Capacity (MW)
  CgDemand::VariableArray{4} = ReadDisk(db,"SOutput/CgDemand") # (Fuel,ECC,Area,Year),Cogeneration Demands (tBtu)
  CgGen::VariableArray{4} = ReadDisk(db,"SOutput/CgGen") # (Fuel,ECC,Area,Year),Cogeneration Generation (GWh/Yr)
  CgFPol::VariableArray{5} = ReadDisk(db,"SOutput/CgFPol") # (FuelEP,ECC,Poll,Area,Year),Cogeneration Related Pollution (Tonnes/Yr)
  DmdFA::VariableArray{3} = ReadDisk(db,"EGOutput/DmdFA") # (Fuel,Area,Year),Energy Demands (TBtu/Yr)
  DmdPA::VariableArray{3} = ReadDisk(db,"EGOutput/DmdPA") # (Plant,Area,Year),Energy Demands (TBtu/Yr)
  ECCCLMap::VariableArray{2} = ReadDisk(db,"MainDB/ECCCLMap") # (ECC,Class),Map Between ECC and Class
  EmEGA::VariableArray{4} = ReadDisk(db,"EGOutput/EmEGA") # (Node,TimeP,Month,Year),Emergency Generation (GWh)
  EGFA::VariableArray{3} = ReadDisk(db,"EGOutput/EGFA") # (Fuel,Area,Year),Electricity Generated (GWh/Yr)
  EGPA::VariableArray{3} = ReadDisk(db,"EGOutput/EGPA") # (Plant,Area,Year),Electricity Generated (GWh/Yr)
  EGPACurtailed::VariableArray{3} = ReadDisk(db,"EGOutput/EGPACurtailed") # (Plant,Area,Year),Curtailed Electric Generation (GWh/Yr)
  EUEuPol::VariableArray{5} = ReadDisk(db,"EGOutput/EUEuPol") # (FuelEP,Plant,Poll,Area,Year),Electric Utility Pollution (Tons/Yr)
  ExpPurchases::VariableArray{2} = ReadDisk(db,"EGOutput/ExpPurchases") # (Area,Year),Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db,"EGOutput/ExpSales") # (Area,Year),Sales to Areas in a different Country (GWh/Yr)
  GCFA::VariableArray{3} = ReadDisk(db,"EOutput/GCFA") # (Fuel,Area,Year),Generation Capacity (MW)
  GCPA::VariableArray{3} = ReadDisk(db,"EOutput/GCPA") # (Plant,Area,Year),Generation Capacity (MW)
  HDEmMDS::VariableArray{4} = ReadDisk(db,"EGOutput/HDEmMDS") # (Node,TimeP,Month,Year),Emergency Power Dispatched (MW)
  HDHrMn::VariableArray{2} = ReadDisk(db,"EInput/HDHrMn") # (TimeP,Month),Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db,"EInput/HDHrPk") # (TimeP,Month),Peak Hour in the Interval (Hour)
  HMPrA::VariableArray{2} = ReadDisk(db,"EOutput/HMPrA") # (Area,Year),Average Spot Market Price ($/MWh)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # (Area,Year),Inflation Index ($/$)
  MEPol::VariableArray{4} = ReadDisk(db,"SOutput/MEPol") # (ECC,Poll,Area,Year),Non-Energy Pollution (Tonnes/Yr)
  MoneyUnitDS::Vector{String} = ReadDisk(db,"MInput/MoneyUnitDS") # (Area),Descriptor for Monetary Units
  NcPol::VariableArray{4} = ReadDisk(db,"SOutput/NcPol") # (ECC,Poll,Area,Year),Non-Combustion Pollution (Tonnes/Yr)
  NdArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdArMap") # (Node,Area),Map between Node and Area
  PE::VariableArray{3} = ReadDisk(db,"SOutput/PE") # (ECC,Area,Year),Price of Electricity ($/MWh)
  PkLoad::VariableArray{3} = ReadDisk(db,"SOutput/PkLoad") # (Month,Area,Year),Monthly Peak Load (MW)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # (Area),Pollution Conversion Factor (convert GHGs to eCO2)
  PSoECC::VariableArray{3} = ReadDisk(db,"SOutput/PSoECC") # (ECC,Area,Year),Power Sold to Grid (GWh)
  SaEC::VariableArray{3} = ReadDisk(db,"SOutput/SaEC") # (ECC,Area,Year),Electricity Sales by ECC (GWh/Yr)
  xPkSavECC::VariableArray{3} = ReadDisk(db,"SInput/xPkSavECC") # [ECC,Area,Year] Peak Savings from Programs (MW)

end

function ElectricSummary_DtaRun(data,areas,nodes,AreaName,AreaKey)

  (; Area,AreaDS,Class,ClassDS,Classes,ECC,ECCDS,ECCs,Fuel,FuelDS,Fuels,FuelEP,FuelEPs,FuelEPDS) = data
  (; Month,MonthDS,Months,Node,NodeDS,Plant,PlantDS,Plants,Poll,PollDS,TimeP,TimePs,Year,Yr2010) = data
  (; AreaPurchases,AreaSales,CapCredit,CgEC) = data
  (; CgCap,CgDemand,CgGen,CgFPol,DmdFA,DmdPA,ECCCLMap) = data
  (; EmEGA,EGFA,EGPA,EGPACurtailed,EUEuPol,ExpPurchases) = data
  (; ExpSales,GCFA,GCPA,HDEmMDS,HDHrMn,HDHrPk,HMPrA) = data
  (; Inflation,MEPol,MoneyUnitDS,NcPol,NdArMap) = data
  (; PE,PkLoad,PolConv,PSoECC,SaEC,xPkSavECC,SceName) = data
  MaxHDEMMDS::VariableArray{2} = zeros(Float32,length(Node),length(Year))
  PkLoadTemp::VariableArray{2} = zeros(Float32,length(Month),length(Year))
  AAA = zeros(Float32,length(Year))
  BBB = zeros(Float32,length(Year))
  LLL = zeros(Float32,length(Year))
  SSS = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
  KJBtu = 1.054615
  WWW = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
  years = collect(Yr(1990):Final)

  fuels=Select(Fuel,!=("Thermal"))

  iob = IOBuffer()

  println(iob)
  println(iob,"$AreaName")
  println(iob,"This file was produced by ElectricSummary.txo")
  println(iob)
  println(iob)
  println(iob,"Year;",";",join(Year[years],";"))
  println(iob)

  #
  # Generation by Plant Type
  #
  print(iob,AreaName," Generation by Plant Type (GWh);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)  
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for area in areas, plant in Plants)
    TTT[year] = ZZZ[year]
    SSS[year] = 0.0
  end
  print(iob,"EGPA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(EGPA[plant,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]
    end
    print(iob,"EGPA;",PlantDS[plant])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  print(iob,"EGPA;Other Types")
  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)
  #
  # Generation by Primary Type

  #
  print(iob,AreaName," Generation by Primary Fuel (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(EGFA[fuel,area,year] for area in areas,fuel in fuels)
    TTT[year] = ZZZ[year]
    SSS[year] = 0.0
  end  
  print(iob,"EGFA;Total")
  for year in years  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end

  for fuel in fuels
    for year in years
      ZZZ[year] = sum(EGFA[fuel,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]
    end
    println(iob)    
    print(iob,"EGFA;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  
  println(iob)
  print(iob,"EGFA;Other Fuels")
  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,AreaName," Industrial Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
    ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for area in areas,ecc in ECCs,fuel in fuels)
  end
  println(iob)

  print(iob,"CgGen;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end

  for fuel in fuels
    for year in years
      ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for area in areas,ecc in ECCs)
    end
    println(iob)
    print(iob,"CgGen;",FuelDS[fuel])
    for year in years  
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
  end  
  println(iob)

  #
  # Generating Capacity by Plant Type
  #
  println(iob)
  print(iob,AreaName," Generating Capacity by Plant Type (MW);")
  for year in years
    print(iob,";",Year[year])
    ZZZ[year] = sum(GCPA[plant,area,year] for area in areas,plant in Plants)
    TTT[year] = ZZZ[year]
    SSS[year] = 0.0
  end  
  println(iob)
  print(iob,"GCPA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end

  for plant in Plants
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]  
    end  
    println(iob)
    print(iob,"GCPA;",PlantDS[plant])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
  end
  println(iob)

  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
  end  
  print(iob,"GCPA;Other Types")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Generating Capacity by Primary Fuel
  #
  println(iob)
  print(iob,AreaName," Generating Capacity by Primary Fuel (MW);")
  for year in years
    print(iob,";",Year[year])
    ZZZ[year] = sum(GCFA[fuel,area,year] for area in areas,fuel in fuels)
    TTT[year] = ZZZ[year]
    SSS[years] .= 0.0
  end  
  println(iob)
  print(iob,"GCFA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  
  for fuel in fuels
    for year in years
      ZZZ[year] = sum(GCFA[fuel,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]
    end  
    println(iob)
    print(iob,"GCFA;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
  end
  println(iob)

  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
  end  
  print(iob,"GCFA;Other fuels")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  #
  println(iob)
  print(iob,AreaName," Industrial Generation Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
    ZZZ[year] = sum(CgCap[fuel,ecc,area,year] for area in areas,ecc in ECCs,fuel in fuels)
  end
  println(iob)

  print(iob,"CgCap;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  for fuel in fuels
    for year in years
      ZZZ[year] = sum(CgCap[fuel,ecc,area,year] for area in areas,ecc in ECCs)
    end  
    print(iob,"CgCap;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Energy Demands by Plant Type
  #
  print(iob,AreaName," Energy Demands by Plant Type (TBtu);")
  for year in years
    print(iob,";",Year[year])
    ZZZ[year] = sum(DmdPA[plant,area,year] for area in areas,plant in Plants)
    TTT[year] = ZZZ[year]
    SSS[year] = 0.0
  end  
  println(iob)
  print(iob,"DmdPA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  for plant in Plants
    for year in years
      ZZZ[year] = sum(DmdPA[plant,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]
    end  
    print(iob,"DmdPA;",PlantDS[plant])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end

  print(iob,"DmdPA;Other Types")
  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Generation by Primary Fuel
  #
  print(iob,AreaName," Energy Demands by Primary Fuel (TBtu);")
  for year in years
    print(iob,";",Year[year])  
    ZZZ[year] = sum(DmdFA[fuel,area,year] for area in areas,fuel in fuels)
    TTT[year] = ZZZ[year]
    SSS[year] = 0.0
  end  
  println(iob)

  print(iob,"DmdFA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  for fuel in fuels
    for year in years
      ZZZ[year] = sum(DmdFA[fuel,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]
    end  
    print(iob,"DmdFA;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end

  print(iob,"DmdFA;Other fuels")
  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Industrial Generation Fuel Use
  #
  print(iob,AreaName," Industrial Generation Energy Demands (TBtu);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"CgDemand;Total")
  for year in years
    ZZZ[year] = sum(CgDemand[fuel,ecc,area,year] for area in areas,ecc in ECCs,fuel in fuels)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    for year in years
      ZZZ[year] = sum(CgDemand[fuel,ecc,area,year] for area in areas,ecc in ECCs)
    end  
    print(iob,"CgDemand;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  GHG = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  UtilityGen = Select(ECC,"UtilityGen")

  #
  # Electric Utility GHG Emissions By Plant Type
  #
  GHG = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  UtilityGen = Select(ECC,"UtilityGen")  
  print(iob,AreaName," Electric Utility GHG Emissions (MT/Yr);")
  for year in years
    print(iob,";",Year[year])
  end   
  println(iob)

  print(iob,"Total;Total")
  for year in years
     ZZZ[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll] for area in areas,poll in GHG,plant in Plants,fuelep in FuelEPs)/1e6+
                sum(MEPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6+
                sum(NcPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"EUEuPol;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll] for area in areas,poll in GHG,fuelep in FuelEPs)/1e6
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end 
  print(iob,"MEPol;Non-Energy")
  for year in years
    ZZZ[year] = sum(MEPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"NcPol;Non-Combustion")
  for year in years
    ZZZ[year] = sum(NcPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # GHG Emissions By Fuel Type
  #
  GHG = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  UtilityGen = Select(ECC,"UtilityGen")
  print(iob,AreaName," Electric Utility GHG Emissions (MT/Yr);")
  for year in years
    print(iob,";",Year[year])
  end 
  println(iob)

  print(iob,"Total;Total")
  for year in years
    ZZZ[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll] for area in areas,poll in GHG,plant in Plants,fuelep in FuelEPs)/1e6+
                sum(MEPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6+
                sum(NcPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuelep in FuelEPs
    print(iob,"EUEuPol;",FuelEPDS[fuelep])
    for year in years
     ZZZ[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll] for area in areas,poll in GHG,plant in Plants)/1e6
     print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  print(iob,"MEPol;Non-Energy")
  for year in years
    ZZZ[year] = sum(MEPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)  
  print(iob,"NcPol;Non-Combustion")
  for year in years
    ZZZ[year] = sum(NcPol[UtilityGen,poll,area,year]*PolConv[poll] for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Electric Utility GHG Emissions Intensity By Plant Type
  #
  GHG = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  UtilityGen = Select(ECC,"UtilityGen")
  print(iob,AreaName," Electric Utility GHG Emission Intensity (tonne/GWh);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"EUEuPol/EGPA;Total")
  for year in years
    TTT[year] = sum(EGPA[plant,area,year] for area in areas,plant in Plants)
    SSS[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll] 
      for area in areas,poll in GHG,plant in Plants,fuelep in FuelEPs)
    @finite_math ZZZ[year] = SSS[year]/TTT[year]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  FossilPlants = Select(Plant,(from = "OGCT",to = "CoalCCS"))
  print(iob,"EUEuPol/EGPA;Fossil Plants")
  for year in years
    TTT[year] = sum(EGPA[plant,area,year] for area in areas,plant in FossilPlants)
    SSS[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll]
      for area in areas,poll in GHG,plant in FossilPlants,fuelep in FuelEPs)
    @finite_math ZZZ[year] = SSS[year]/TTT[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  for plant in Plants  
    print(iob,"EUEuPol/EGPA;",PlantDS[plant])
    for year in years
      TTT[year] = sum(EGPA[plant,area,year] for area in areas)
      SSS[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll]
        for area in areas,poll in GHG,fuelep in FuelEPs)
      @finite_math  ZZZ[year] = SSS[year]/TTT[year]    
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
     
  print(iob,"MEPol;Non-Energy")
  for year in years
    ZZZ[year] = sum(MEPol[UtilityGen,poll,area,year]*PolConv[poll]
      for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"NcPol;Non-Combustion")
  for year in years
    ZZZ[year] = sum(NcPol[UtilityGen,poll,area,year]*PolConv[poll]
      for area in areas,poll in GHG)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Industry Generation GHG Emissions By Fuel Type
  #
  GHG = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  print(iob,AreaName," Industrial Generation  GHG Emissions (MT/Yr);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"Total;Total")
  for year in years
    ZZZ[year] = sum(CgFPol[fuelep,ecc,poll,area,year]*PolConv[poll]
      for area in areas,poll in GHG,ecc in ECCs,fuelep in FuelEPs)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuelep in FuelEPs
    print(iob,"CgFPol;",FuelEPDS[fuelep])
    for year in years
      ZZZ[year] = sum(CgFPol[fuelep,ecc,poll,area,year]*PolConv[poll]
        for area in areas,poll in GHG,ecc in ECCs)/1e6
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end

  print(iob,"MEPol;Non-Energy")
  for year in years
    ZZZ[year] = 0.0
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  
  println(iob)
  print(iob,"NcPol;Non-Combustion")
  for year in years
    ZZZ[year] = 0.0
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Sales
  #
  print(iob,AreaName," Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob,"SaEC;Total")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas,ecc in ECCs) 
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  for class in Classes 
    print(iob,"SaEC;",ClassDS[class])  
    for year in years  
      ZZZ[year] = 0.0
      for ecc in ECCs
        if ECCCLMap[ecc,class] == 1
          ZZZ[year] = ZZZ[year]+sum(SaEC[ecc,area,year] for area in areas)
        end
      end
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)


  #
  # Transmission Flows
  #
  print(iob,"Transmission Flows (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"AreaPurchases;In-Flows")
  for year in years
    ZZZ[year] = sum(AreaPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"AreaSales;Out-Flows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"ExpPurchases;Imports")
  for year in years
    ZZZ[year] = sum(ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"ExpSales;Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"NetExp;Net Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] - ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"Net;Net Out-Flows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] - AreaPurchases[area,year] +
      ExpSales[area,year] - ExpPurchases[area,year] for area in areas)  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Peak Loads
  #
  print(iob,AreaName," Peak Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"PkLoad;Annual")
  for year in years
    PkLoadTemp[Months,year] = sum(PkLoad[Months,area,year] for area in areas)
    ZZZ[year] = maximum(PkLoadTemp[month,year] for month in Months)
    LLL[year] = ZZZ[year] 
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  for month in Months
    print(iob,"PkLoad;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(PkLoad[month,area,year] for area in areas)    
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  # Exogenous Peak Savings
  #
  print(iob,AreaName," Peak Savings (MW);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
 
  print(iob,"xPkSavECC;Annual")
  for year in years
    ZZZ[year] = sum(xPkSavECC[ecc,area,year] for area in areas,ecc in ECCs)    
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Reserve Margin
  #
  print(iob,AreaName," Reserve Margin (%);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob,"RMargin;",AreaName)
  for year in years
    AAA[year]              = sum(GCPA[plant,area,year]*CapCredit[plant,area,year]
                                 for area in areas,plant in Plants)
    @finite_math BBB[year] = sum(CgCap[fuel,ecc,area,year]/
                                 CgEC[ecc,area,year]*PSoECC[ecc,area,year]
                                 for area in areas,ecc in ECCs,fuel in fuels)
    TTT[year]              = AAA[year]+BBB[year]-LLL[year]
    @finite_math ZZZ[year] = (TTT[year]/LLL[year])*100
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Generation Sold to Grid
  #
  print(iob,AreaName," Generation Sold to Grid (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"PSoECC;Total")
  for year in years
    ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas,ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,AreaName," Clearing Price (2010",MoneyUnitDS[areas[1]],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  area = first(areas)
  print(iob,"HMPrA;Average")
  for year in years
    @finite_math ZZZ[year] = HMPrA[area,year]/Inflation[area,year]*Inflation[area,Yr2010]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Real Retail Prices
  #
  print(iob,AreaName," Retail Rate (2010",MoneyUnitDS[areas[1]],"/MWh);")
  for year in years
    print(iob,";",Year[year])

  end
  println(iob)
  
  print(iob,"PE;Average Retail Rate;")
  for year in years
    @finite_math ZZZ[year] = sum(PE[ecc,area,year]*SaEC[ecc,area,year]/
    Inflation[area,year]*Inflation[area,Yr2010] for area in areas, ecc in ECCs)/
    sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for class in Classes
    print(iob,"PE;",ClassDS[class])
    for year in years
      @finite_math ZZZ[year] = sum(PE[ecc,area,year]*SaEC[ecc,area,year]*ECCCLMap[ecc,class]/
        Inflation[area,year]*Inflation[area,Yr2010] for area in areas,ecc in ECCs)/
        sum(SaEC[ecc,area,year]*ECCCLMap[ecc,class] for area in areas,ecc in ECCs)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Nominal Retail Prices
  #
  print(iob,AreaName," Retail Rate (Nominal",MoneyUnitDS[areas[1]],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  
  print(iob,"PE;Average Retail Rate;")
  for year in years
    @finite_math ZZZ[year] =
      sum(PE[ecc,area,year]*SaEC[ecc,area,year] for area in areas,ecc in ECCs)/
      sum(SaEC[ecc,area,year] for area in areas,ecc in ECCs)  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  for class in Classes
    print(iob,"PE;",ClassDS[class])
    for year in years
      @finite_math ZZZ[year] = sum(PE[ecc,area,year]*SaEC[ecc,area,year]*
        ECCCLMap[ecc,class] for area in areas,ecc in ECCs)/
        sum(SaEC[ecc,area,year]*ECCCLMap[ecc,class] for area in areas,ecc in ECCs)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Emergency Generation
  # This variable is last since it has a varying number of rows. JSA 05/13/09
  #
  print(iob,AreaName," Emergency Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  if !isempty(nodes)   
    print(iob,"EmEGA;Total")
    for year in years
      ZZZ[year] = sum(EmEGA[node,timep,month,year]
        for month in Months,timep in TimePs,node in nodes)
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    
    for node in nodes
      print(iob,"EmEGA;",NodeDS[node])
      for year in years
        ZZZ[year] = sum(EmEGA[node,timep,month,year] for month in Months,timep in TimePs)
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob)

  #
  print(iob,AreaName," Curtailed Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"EGPACurtailed;Total")
  for year in years
    ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in Plants)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
 
  for area in areas
    print(iob,"EGPACurtailed;",AreaDS[area])
    for year in years
      ZZZ[year] = sum(EGPACurtailed[plant,area,year] for plant in Plants)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,AreaName," Curtailed Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)

  print(iob,"EGPACurtailed;Total")
  for year in years
    ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in Plants)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"EGPACurtailed;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas) 
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,AreaName," Emergency Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  if !isempty(nodes)
    print(iob,"HDEmMDS;Total")
    for year in years
      for node in nodes
        MaxHDEMMDS[node,year] = maximum(HDEmMDS[node,timep,month,year]
          for month in Months,timep in TimePs)
      end    
      ZZZ[year] = sum(MaxHDEMMDS[node,year] for node in nodes)
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    
    for node in nodes
      print(iob,"HDEmMDS;",NodeDS[node])
      for year in years
         ZZZ[year] = MaxHDEMMDS[node,year]
       print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob)

  #
  if !isempty(nodes)
    for node in nodes

      print(iob,AreaName," Emergency Capacity (MW);")
      for year in years
        print(iob,";",Year[year])
      end  
      println(iob)
      
      print(iob,"HDEmMDS;Maximum")
      for year in years
        ZZZ[year] = maximum(HDEmMDS[node,timep,month,year] for month in Months,timep in TimePs)
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
      
      for month in Months
        print(iob,"HDEmMDS;",MonthDS[month]," Maximum ")
        for year in years
          ZZZ[year] = maximum(HDEmMDS[node,timep,month,year] for timep in TimePs)
          print(iob,";",@sprintf("%.f",ZZZ[year]))
        end
        println(iob)
        
        for timep in TimePs
          print(iob,"HDEmMDS;",MonthDS[month]," ",round(Int,HDHrPk[timep,month]),"--",round(Int,HDHrMn[timep,month]))
          for year in years
            ZZZ[year] = HDEmMDS[node,timep,month,year]
            print(iob,";",@sprintf("%.f",ZZZ[year]))
          end
          println(iob)
        end # TimePs
      end # Months
      println(iob)
    end # nodes
  end # !isempty(nodes)
  
  #
  # Sales
  #
  print(iob,AreaName," Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  
  print(iob,"SaEC;Total")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas,ecc in ECCs) 
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
 
  for ecc in ECCs 
    print(iob,"SaEC;",ECCDS[ecc])  
    for year in years  
      ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas) 
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
 
  #
  # Create *.dta filename and write output values
  #
  filename = "ElectricSummary-$(AreaKey)-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function ElectricSummary_DtaControl(db)
  @info "ElectricSummary_DtaControl"
  data = ElectricSummaryData(; db)
  (; Area,Areas,AreaDS,Node) = data
  (; NdArMap) = data

  #
  # Canada
  #
  areas = Select(Area,(from = "ON",to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  nodes = Select(Node,(from = "MB",to = "NU"))
  ElectricSummary_DtaRun(data,areas,nodes,AreaName,AreaKey)

  #
  # US
  #
  areas = Select(Area,(from = "CA",to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  nodes = Select(Node,(from = "TRE",to = "BASN"))
  ElectricSummary_DtaRun(data,areas,nodes,AreaName,AreaKey)

  #
  # Individual Areas
  #
  areas_CN = Select(Area,(from = "ON",to = "NU"))
  areas_US = Select(Area,(from = "CA",to = "Pac"))
  area_MX = Select(Area,"MX")
  areas = union(areas_CN,areas_US,area_MX)
  for area in areas
    AreaName = AreaDS[area]
    AreaKey = Area[area]
    nodes = findall(NdArMap[:,area] .> 0.0)
    ElectricSummary_DtaRun(data,area,nodes,AreaName,AreaKey)
  end
end


if abspath(PROGRAM_FILE) == @__FILE__
ElectricSummary_DtaControl(DB)
end
