#
# ElectricBalanceArea.jl
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



Base.@kwdef struct ElectricBalanceAreaData
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
  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db, "MainDB/GenCoDS")
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db, "MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db, "MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray = ReadDisk(db, "MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db, "MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db, "MainDB/TimeP")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  ArNdFr::VariableArray{3} = ReadDisk(db, "EGInput/ArNdFr") #[Area,Node,Year]  Fraction of the Area in each Node (Fraction)
  AreaPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/AreaPurchases") # [Area,Year]  Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{2} = ReadDisk(db, "EGOutput/AreaSales") # [Area,Year]  Sales to Areas in the same Country (GWh/Yr)
  CgEC::VariableArray{3} = ReadDisk(db, "SOutput/CgEC") # [ECC,Area,Year]  Cogeneration by Economic Category (GWh/Yr)'
  CgGen::VariableArray{4} = ReadDisk(db, "SOutput/CgGen") # [Fuel,ECC,Area,Year]  Cogeneration Generation (GWh/Yr)
  EGFA::VariableArray{3} = ReadDisk(db, "EGOutput/EGFA") # [Fuel,Area,Year]  Electric Generation Reported Values (GWh/Yr)
  EGFAuu::VariableArray{3} = ReadDisk(db, "EGOutput/EGFAuu") # [Fuel,Area,Year]  Electric Generation Model Values (GWh/Yr)
  EGPA::VariableArray{3} = ReadDisk(db, "EGOutput/EGPA") # [Plant,Area,Year]  Electric Generation Reported Values (GWh/Yr)
  EGPAuu::VariableArray{3} = ReadDisk(db, "EGOutput/EGPAuu") # [Plant,Area,Year]  Electric Generation Model Values (GWh/Yr)
  EmEGA::VariableArray{4} = ReadDisk(db, "EGOutput/EmEGA") # [Node,TimeP,Month,Year]  Emergency Generation (GWh/Yr)
  EuDemand::VariableArray{4} = ReadDisk(db, "SOutput/EuDemand") # [Fuel,ECC,Area,Year]  Enduse Energy Demands (TBtu/Yr)
  ExpPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/ExpPurchases") #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db, "EGOutput/ExpSales") #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)

  HDHours::VariableArray{2} = ReadDisk(db, "EInput/HDHours") #[TimeP,Month] Number of Hours in the Interval (Hours)
  HDLLoad::VariableArray{5} = ReadDisk(db, "EGOutput/HDLLoad") #[Node,NodeX,TimeP,Month,Year]  Flows on Transmission Lines (MW)

  LLEff::VariableArray{3} = ReadDisk(db, "EGInput/LLEff") #[Node,NodeX,Year]  Transmission Line Efficiency (MW/MW)
  NdArMap::VariableArray{2} = ReadDisk(db, "EGInput/NdArMap") #[Node,Area]  Map between Node and Area
  PkLoad::VariableArray{3} = ReadDisk(db, "SOutput/PkLoad") #[Month,Area,Year]  Monthly Peak Load (MW)
  PSoECC::VariableArray{3} = ReadDisk(db, "SOutput/PSoECC") #[ECC,Area,Year]  Power Sold to Grid (GWh/Yr)
  PurECC::VariableArray{3} = ReadDisk(db, "SOutput/PurECC") #[ECC,Area,Year]  Purchases from Electric Grid (GWh/Yr)
  SaEC::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)
  TDEF::VariableArray{3} = ReadDisk(db, "SInput/TDEF") #[Fuel,Area,Year]  T&D Efficiency (Btu/Btu)

  xAreaPurchases::VariableArray{2} = ReadDisk(db, "EGInput/xAreaPurchases") #[Area,Year]  Historical Purchases from Areas in the same Country (GWh/Yr)
  xAreaSales::VariableArray{2} = ReadDisk(db, "EGInput/xAreaSales") #[Area,Year]  Historical Sales to Areas in the same Country (GWh/Yr)
  xCgGen::VariableArray{4} = ReadDisk(db, "SInput/xCgGen") #[Fuel,ECC,Area,Year]  Cogeneration Generation (GWh/Yr)
  xEGFA::VariableArray{3} = ReadDisk(db, "EGInput/xEGFA") #[Fuel,Area,Year]  Electric Generation Historical (GWh/Yr)
  xEGPA::VariableArray{3} = ReadDisk(db, "EGInput/xEGPA") #[Plant,Area,Year]  Electric Generation Historical (GWh/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db, "SInput/xEuDemand") #[Fuel,ECC,Area,Year]  Exogenous Energy Demands (tBtu)
  xExpPurchases::VariableArray{2} = ReadDisk(db, "EGInput/xExpPurchases") #[Area,Year]  Historical Purchases from Areas in a different Country (GWh/Yr)
  xExpSales::VariableArray{2} = ReadDisk(db, "EGInput/xExpSales") #[Area,Year]  Historical Sales to Areas in a different Country (GWh/Yr)
  xPSoECC::VariableArray{3} = ReadDisk(db, "SInput/xPSoECC") #[ECC,Area,Year]  Power Sold to Grid (GWh)
  xSaEC::VariableArray{3} = ReadDisk(db, "SInput/xSaEC") #[ECC,Area,Year]  Historical Electricity Sales (GWh/Yr)

  #
  # Scratch Variables
  #
  ElecAv = zeros(Float32, length(Year))
  ElecRq = zeros(Float32, length(Year))
  PkLoadTemp::VariableArray{2} = zeros(Float32, length(Month), length(Year))
  MMM = zeros(Float32, length(Month), length(Year))
  ZZZ = zeros(Float32, length(Year))
end

function ElectricBalanceArea_DtaRun(data, TitleKey, TitleName, areas)
  (; Area,AreaDS,ECC,ECCDS,ECCs,Fuel,FuelDS,Fuels,FuelEP,FuelEPDS,FuelEPs) = data
  (; GenCo,GenCoDS,Month,MonthDS,Months,Nation,NationDS,Node,NodeDS,Nodes) = data
  (; NodeX,NodeXDS,NodeXs,Plant,PlantDS,Plants,Poll,PollDS,Polls) = data
  (; Power,PowerDS,Powers,TimeP,TimePs,Year,CDTime,CDYear) = data
  (; ArNdFr,AreaPurchases,AreaSales,CgEC,CgGen,EGFA,EGFAuu) = data
  (; EGPA,EGPAuu,EmEGA,EuDemand,ExpPurchases,ExpSales,HDHours) = data
  (; HDLLoad,LLEff,NdArMap,PkLoad,PSoECC,PurECC,SaEC,TDEF,xAreaPurchases) = data
  (; xAreaSales,xCgGen,xEGFA,xEGPA,xEuDemand,xExpPurchases) = data
  (; xExpSales,xPSoECC,xSaEC) = data
  (; ElecAv,ElecRq,PkLoadTemp,MMM,ZZZ,SceName) = data

  iob = IOBuffer()

  area_single = first(areas)
  Electric = Select(Fuel,"Electric")

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file was produced by ElectricBalance.jl")
  println(iob, " ")

  years = collect(Yr(1990):Final)
  # year = Select(Year)
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  print(iob, TitleName, " Electricity Energy Balance - Model Outputs (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    @finite_math ElecRq[year] = sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs) +
      sum(SaEC[ecc,area,year]*(1/TDEF[Electric,area,year]-1) for area in areas, ecc in ECCs) +
      sum(AreaSales[area,year] for area in areas) +
      sum(ExpSales[area,year] for area in areas)
  end
  print(iob, "ElecRq;Energy Requiements")
  for year in years
    ZZZ[year]=ElecRq[year]
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)
  end
  print(iob, "SaEC;  Sales")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "TDEF Losses;  Local T&D Losses")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year]*(1/TDEF[Electric,area,year]-1) for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(AreaSales[area,year] for area in areas)
  end
  print(iob, "AreaSales;  In Country Outflows")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "ExpSales;  Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    @finite_math ElecAv[year] = sum(EGFA[fuel,area,year] for area in areas, fuel in Fuels) +
      sum(AreaPurchases[area,year] for area in areas) +
      sum(ExpPurchases[area,year] for area in areas) +
      sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)+
      sum(EmEGA[node,timep,month,year]*NdArMap[node,area] for area in areas, month in Months, timep in TimePs, node in Nodes)
  end
  print(iob, "ElecAv;Energy Available")
  for year in years
    ZZZ[year]=ElecAv[year]
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(EGFA[fuel,area,year] for area in areas, fuel in Fuels)
  end
  print(iob, "EGFA;  Utility Generation")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
 
  for year in years
    ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)
  end
  print(iob, "PSoECC;  Industrial Generation Sold to Grid")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(AreaPurchases[area,year] for area in areas)
  end
  print(iob, "AreaPurchases;  In Country Inflows")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "ExpPurchases;  Imports")
  for year in years
    ZZZ[year] = sum(ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    @finite_math ZZZ[year] = sum(EmEGA[node,timep,month,year]*NdArMap[node,area] for area in areas, month in Months, timep in TimePs, node in Nodes)
  end
  print(iob, "EmEGA;  Emergency Power")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = ElecRq[year] .- ElecAv[year]
  end
  print(iob, "Deficit;Energy Deficit")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  #############################
  #

  print(iob, TitleName, " Electricity Energy Balance - Model Internal (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    @finite_math ElecRq[year] = sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs) +
      sum(SaEC[ecc,area,year]*(1/TDEF[Electric,area,year]-1) for area in areas, ecc in ECCs) +
      sum(AreaSales[area,year] for area in areas) +
      sum(ExpSales[area,year] for area in areas)
  end
  for year in years
    ZZZ[year]=ElecRq[year]
  end
  print(iob, "ElecRq;Energy Requiements")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "SaEC;  Sales")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year]*(1/TDEF[Electric,area,year]-1) for area in areas, ecc in ECCs)
  end
  print(iob, "TDEF Losses;  Local T&D Losses")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "AreaSales;  In Country Outflows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(ExpSales[area,year] for area in areas)
  end
  print(iob, "ExpSales;  Exports")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    @finite_math ElecAv[year] = sum(EGFAuu[fuel,area,year] for area in areas, fuel in Fuels) +
      sum(AreaPurchases[area,year] for area in areas) +
      sum(ExpPurchases[area,year] for area in areas) +
      sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)+
      sum(EmEGA[node,timep,month,year]*NdArMap[node,area] for area in areas, month in Months, timep in TimePs, node in Nodes)
  end
  print(iob, "ElecAv;Energy Available")
  for year in years
    ZZZ[year]=ElecAv[year]
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(EGFAuu[fuel,area,year] for area in areas, fuel in Fuels)
  end
  print(iob, "EGFAuu;  Utility Generation")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)
  end
  print(iob, "PSoECC;  Industrial Generation Sold to Grid")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(AreaPurchases[area,year] for area in areas)
  end
  print(iob, "AreaPurchases;  In Country Inflows")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(ExpPurchases[area,year] for area in areas)
  end
  print(iob, "ExpPurchases;  Imports")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "EmEGA;  Emergency Power;")
  for year in years
    @finite_math ZZZ[year] = sum(EmEGA[node,timep,month,year]*NdArMap[node,area] for area in areas, month in Months, timep in TimePs, node in Nodes)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "Deficit;Energy Deficit")
  for year in years
    ZZZ[year] = ElecRq[year] .- ElecAv[year]
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  #############################
  #

  print(iob, TitleName, " Electricity Energy Balance - Historical Values (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  for year in years
    @finite_math ElecRq[year] = sum(xSaEC[ecc,area,year] for area in areas, ecc in ECCs) +
      sum(xSaEC[ecc,area,year]*(1/TDEF[Electric,area,year]-1) for area in areas, ecc in ECCs) +
      sum(xAreaSales[area,year] for area in areas) +
      sum(xExpSales[area,year] for area in areas)
  end
  for year in years
    ZZZ[year]=ElecRq[year]
  end
  print(iob, "ElecRq;Energy Requiements")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xSaEC[ecc,area,year] for area in areas, ecc in ECCs)
  end
  print(iob, "xSaEC;  Sales")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xSaEC[ecc,area,year]*(1/TDEF[Electric,area,year]-1) for area in areas, ecc in ECCs)
  end
  print(iob, "TDEF Losses;  Local T&D Losses")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xAreaSales[area,year] for area in areas)
  end
  print(iob, "xAreaSales;  In Country Outflows")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xExpSales[area,year] for area in areas)
  end
  print(iob, "xExpSales;  Exports")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    @finite_math ElecAv[year] = sum(xEGPA[plant,area,year] for area in areas, plant in Plants) +
      sum(xAreaPurchases[area,year] for area in areas) +
      sum(xExpPurchases[area,year] for area in areas) +
      sum(xPSoECC[ecc,area,year] for area in areas, ecc in ECCs)
  end
  for year in years
    ZZZ[year]=ElecAv[year]
  end
  print(iob, "ElecAv;Energy Available")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xEGPA[plant,area,year] for area in areas, plant in Plants)
  end
  print(iob, "xEGPA;  Utility Generation")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xPSoECC[ecc,area,year] for area in areas, ecc in ECCs)
  end
  print(iob, "xPSoECC;  Industrial Generation Sold to Grid")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xAreaPurchases[area,year] for area in areas)
  end
  print(iob, "xAreaPurchases;  In Country Inflows")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xExpPurchases[area,year] for area in areas)
  end
  print(iob, "xExpPurchases;  Imports")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = ElecRq[year] .- ElecAv[year]
  end
  print(iob, "Deficit;Energy Deficit")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  #############################
  #

  print(iob, "Transmission Flows (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "AreaPurchases;Inflows")
  for year in years
    ZZZ[year] = sum(AreaPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xAreaPurchases;Historical Inflows")
  for year in years
    ZZZ[year] = sum(xAreaPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "AreaSales;Outflows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xAreaSales;Historical Outflows")
  for year in years
    ZZZ[year] = sum(xAreaSales[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "ExpPurchases;Imports")
  for year in years
    ZZZ[year] = sum(ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xExpPurchases;Historical Inflows")
  for year in years
    ZZZ[year] = sum(xExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "ExpSales;Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xExpSales;Historical Exports")
  for year in years
    ZZZ[year] = sum(xExpSales[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "NetExp;Net Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] .- ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xNetExp;Historical Net Exports")
  for year in years
    ZZZ[year] = sum(xExpSales[area,year] .- xExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "Net;Net Outflows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] .- AreaPurchases[area,year] .+ ExpSales[area,year] .- ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xNet;Historical Net Outflows")
  for year in years
    ZZZ[year] = sum(xAreaSales[area,year] .- xAreaPurchases[area,year] .+ xExpSales[area,year] .- xExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  println(iob, " ")

  #
  #############################
  #

  print(iob, TitleName, " Other Totals (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(EuDemand[Electric,ecc,area,year]/3412*1e6 for area in areas, ecc in ECCs)
  end
  print(iob, "EuDemand;Gross Electricity Demands")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(xEuDemand[Electric,ecc,area,year]/3412*1e6 for area in areas, ecc in ECCs)
  end
  print(iob, "xEuDemand;Historical Gross Electricity Demands")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  for year in years
    ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels)
  end
  print(iob, "CgGen;Gross Industrial Generation")
  for year in years
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xCgGen;Historical Gross Industrial Generation")
  for year in years
    ZZZ[year] = sum(xCgGen[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "LLEff Losses;Distribution Losses")
  for year in years
    ZZZ[year] = sum(HDLLoad[node,nodex,timep,month,year] .* (1 .- LLEff[node,nodex,year]) .* HDHours[timep,month] / 1000 .*
      NdArMap[node,area] for area in areas, node in Nodes, month in Months, timep in TimePs, nodex in NodeXs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)

  println(iob, " ")

  #
  # Electric Demands
  #
  print(iob, TitleName, " Electric Demands (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EuDemand;Total")
  for year in years
    ZZZ[year] = sum(EuDemand[Electric,ecc,area,year]/3412*1e6 for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "EuDemand;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(EuDemand[Electric,ecc,area,year]/3412*1e6 for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electric Sales
  #
  print(iob, TitleName, " Electric Sales (from Grid) (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "SaEC;Total")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "SaEC;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Self-Generation
  #
  print(iob, TitleName, " Electricity Generated (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "CgGen;Total")
  for year in years
    ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for area in areas, ecc in ECCs, fuel in Fuels)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "CgGen;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Generation Sold to Grid
  #
  print(iob, TitleName, " Generation Sold to Grid (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PSoECC;Total")
  for year in years
    ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PSoECC;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(PSoECC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electricity Purchased from Grid
  #
  print(iob, TitleName, " Generation Purchased from Grid (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PurECC;Total")
  for year in years
    ZZZ[year] = sum(PurECC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PurECC;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(PurECC[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electric Distribution Losses
  #
  print(iob, TitleName, " Electric Distribution Losses (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "TDEF Losses;Total")
  for year in years
    @finite_math ZZZ[year] = sum(SaEC[ecc,area,year] * (1 / TDEF[Electric,area,year] - 1) for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "TDEF Losses;",ECCDS[ecc])
    for year in years
        @finite_math ZZZ[year] = sum(SaEC[ecc,area,year] * (1 / TDEF[Electric,area,year] - 1) for area in areas)
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electric Generation - Model Output
  #
  print(iob, TitleName, " Electric Generation - Model Output (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EGFA;Total")
  for year in years
    ZZZ[year] = sum(EGFA[fuel,area,year] for area in areas, fuel in Fuels)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    print(iob, "EGFA;",FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(EGFA[fuel,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electric Generation (EGFAuu) - Model Internal
  #
  print(iob, TitleName, " Electric Generation - Model Internal (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EGFAuu;Total")
  for year in years
    ZZZ[year] = sum(EGFAuu[fuel,area,year] for area in areas, fuel in Fuels)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    print(iob, "EGFAuu;",FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(EGFAuu[fuel,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electric Generation - Model Output
  #
  print(iob, TitleName, " Electric Generation - Model Output (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EGPA;Total")
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for area in areas, plant in Plants)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "EGPA;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGPA[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electric Generation (EGFAuu) - Model Internal
  #
  print(iob, TitleName, " Electric Generation - Model Internal (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EGPAuu;Total")
  for year in years
    ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas, plant in Plants)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "EGPAuu;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Emergency Power
  #
  TPDS = [
    "High Peak - TimeP(1)",
    "Low Peak - TimeP(2)",
    "High Intermediate - TimeP(3)",
    "Low Intermediate - TimeP(4)",
    "High Baseload - TimeP(5)",
    "Low Baseload - TimeP(6)",
  ]

  print(iob, TitleName, " Emergency Generation (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EmEGA;Total")
  for year in years
    ZZZ[year] = sum(EmEGA[node,timep,month,year] * NdArMap[node,area] for area in areas, month in Months, timep in TimePs, node in Nodes)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for timep in TimePs
    print(iob, "EmEGA;",TPDS[timep])
    for year in years
      ZZZ[year] = sum(EmEGA[node,timep,month,year] * NdArMap[node,area] for area in areas, month in Months, node in Nodes)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Electric Transmission Losses
  #
  print(iob, TitleName, " Electric Transmission Losses (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "LLEff Losses;Total")
  for year in years
    ZZZ[year] = sum(HDLLoad[node,nodex,timep,month,year] .* (1 .- LLEff[node,nodex,year]) .* HDHours[timep,month] / 1000 .*
      NdArMap[node,area] for area in areas, node in Nodes, month in Months, timep in TimePs, nodex in NodeXs)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for nodex in NodeXs
    print(iob, "LLEff Losses;",NodeXDS[nodex])
    for year in years
      ZZZ[year] = sum(HDLLoad[node,nodex,timep,month,year] .* (1 .- LLEff[node,nodex,year]) .* HDHours[timep,month] / 1000 .*
        NdArMap[node,area] for area in areas, node in Nodes, month in Months, timep in TimePs)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Peak Loads
  #
  print(iob, TitleName, " Peak Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for month in Months, year in years
    PkLoadTemp[month,year] = sum(PkLoad[month, area, year] for area in areas)
  end
  print(iob, "PkLoad;Annual")
  for year in years
    ZZZ[year] = maximum(PkLoadTemp[month,year] for month in Months)
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob, "PkLoad;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(PkLoad[month,area,year] for area in areas)
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  filename = "ElectricBalanceArea-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ElectricBalanceArea_DtaControl(db)
  @info "ElectricBalanceArea_DtaControl"
  data = ElectricBalanceAreaData(; db)
  Area = data.Area
  AreaDS = data.AreaDS
  Areas = data.Areas

  for area in Areas
    ElectricBalanceArea_DtaRun(data, Area[area], AreaDS[area], area)
  end

  areas = Select(Area,(from ="ON", to="NU"))
  ElectricBalanceArea_DtaRun(data, "CN", "Canada", areas)

  areas = Select(Area,(from ="CA", to="Pac"))
  ElectricBalanceArea_DtaRun(data, "US", "US", areas)
end

if abspath(PROGRAM_FILE) == @__FILE__
ElectricBalanceArea_DtaControl(DB)
end
