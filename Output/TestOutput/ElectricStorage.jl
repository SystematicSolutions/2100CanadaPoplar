#
# ElectricStorage.jl
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
Base.@kwdef struct ElectricStorageData
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
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  TimeP::SetArray = ReadDisk(db,"MainDB/TimeP")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  CDTime::Int = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  AreaPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/AreaPurchases") # [Area,Year] Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{2} = ReadDisk(db, "EGOutput/AreaSales") # [Area,Year] Sales to Areas in the same Country (GWh/Yr)
  CapCredit::VariableArray{3} = ReadDisk(db, "EGInput/CapCredit") # [Plant,Area,Year] Capacity Credit (MW/MW)
  CgCap::VariableArray{4} = ReadDisk(db, "SOutput/CgCap") # [Fuel,ECC,Area,Year] Cogeneration Capacity (MW)
  CgDemand::VariableArray{4} = ReadDisk(db, "SOutput/CgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (tBtu)
  CgGen::VariableArray{4} = ReadDisk(db, "SOutput/CgGen") # [Fuel,ECC,Area,Year] Cogeneration Generation (GWh/Yr)
  CgFPol::VariableArray{5} = ReadDisk(db, "SOutput/CgFPol") # [FuelEP,ECC,Poll,Area,Year] Cogeneration Related Pollution (Tonnes/Yr)
  DmdFA::VariableArray{3} = ReadDisk(db, "EGOutput/DmdFA") # [Fuel,Area,Year] Energy Demands (TBtu/Yr)
  DmdPA::VariableArray{3} = ReadDisk(db, "EGOutput/DmdPA") # [Plant,Area,Year] Energy Demands (TBtu/Yr)
  ECCCLMap::VariableArray{2} = ReadDisk(db,"MainDB/ECCCLMap") #[ECC,Class]  Map Between ECC and Class (map)
  EmEGA::VariableArray{4} = ReadDisk(db, "EGOutput/EmEGA") # [Node,TimeP,Month,Year] Emergency Generation (GWh)
  EGFA::VariableArray{3} = ReadDisk(db, "EGOutput/EGFA") # [Fuel,Area,Year] Electricity Generated (GWh/Yr)
  EGPA::VariableArray{3} = ReadDisk(db, "EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  EuFPol::VariableArray{5} = ReadDisk(db, "SOutput/EuFPol") # [FuelEP,ECC,Poll,Area,Year] Energy Related Pollution (Tonnes/Yr)
  EUEuPol::VariableArray{5} = ReadDisk(db, "EGOutput/EUEuPol") # [FuelEP,Plant,Poll,Area,Year] Electric Utility Pollution (Tons/Yr)
  ExpPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/ExpPurchases") # [Area,Year] Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db, "EGOutput/ExpSales") # [Area,Year] Sales to Areas in a different Country (GWh/Yr)
  GCFA::VariableArray{3} = ReadDisk(db, "EOutput/GCFA") # [Fuel,Area,Year] Generation Capacity (MW)
  GCPA::VariableArray{3} = ReadDisk(db, "EOutput/GCPA") # [Plant,Area,Year] Generation Capacity (MW)
  HDADP::VariableArray{4} = ReadDisk(db, "EGOutput/HDADP") # [Node,TimeP,Month,Year] Average Load in Interval (MW)
  HDADPwithStorage::VariableArray{4} = ReadDisk(db, "EGOutput/HDADPwithStorage") # [Node,TimeP,Month,Year] Average Load in Interval with Generation to Fill Storage (MW)
  HDEmMDS::VariableArray{4} = ReadDisk(db, "EGOutput/HDEmMDS") # [Node,TimeP,Month,Year] Emergency Power Dispatched (MW)
  HDHours::VariableArray{2} = ReadDisk(db, "EInput/HDHours") # [TimeP,Month] Number of Hours in the Interval (Hours)
  HDHrMn::VariableArray{2} = ReadDisk(db, "EInput/HDHrMn") # [TimeP,Month] Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db, "EInput/HDHrPk") # [TimeP,Month] Peak Hour in the Interval (Hour)
  HDPrA::VariableArray{4} = ReadDisk(db, "EOutput/HDPrA") # [Node,TimeP,Month,Year] Spot Market Marginal Price ($/MWh)
  HMPrA::VariableArray{2} = ReadDisk(db, "EOutput/HMPrA") # [Area,Year] Average Spot Market Price ($/MWh)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MCE::VariableArray{4} = ReadDisk(db, "EOutput/MCE") # [Plant,Power,Area,Year] Cost of Energy from New Capacity ($/MWh)
  MEPol::VariableArray{4} = ReadDisk(db, "SOutput/MEPol") # [ECC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  NcPol::VariableArray{4} = ReadDisk(db, "SOutput/NcPol") # [ECC,Poll,Area,Year] Non-Combustion Pollution (Tonnes/Yr)
  NdArFr::VariableArray{3} = ReadDisk(db, "EGInput/NdArFr") # [Node,Area,Year] Area Node Fraction
  NdArMap::VariableArray{2} = ReadDisk(db, "EGInput/NdArMap") # [Node,Area] Map between Node and Area
  NetImports::VariableArray{2} = ReadDisk(db, "EGOutput/NetImports") # [Area,Year] Net Imports to Area (GWh)
  PE::VariableArray{3} = ReadDisk(db, "SOutput/PE") # [ECC,Area,Year] Price of Electricity ($/MWh)
  PkLoad::VariableArray{3} = ReadDisk(db, "SOutput/PkLoad") # [Month,Area,Year] Monthly Peak Load (MW)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PSoECC::VariableArray{3} = ReadDisk(db, "SOutput/PSoECC") # [ECC,Area,Year] Power Sold to Grid (GWh)
  RnImports::VariableArray{2} = ReadDisk(db, "EGOutput/RnImports") # [Area,Year] Renewable Generation Imports (GWh/Yr)
  RnSwitch::VariableArray{2} = ReadDisk(db, "EGInput/RnSwitch") # [Plant,Area] Renewable Plant Type Switch (1=Renewable)
  SaEC::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)
  StorageCosts::VariableArray{2} = ReadDisk(db, "EGOutput/StorageCosts") # [Area,Year] Cost of Generation for Filling Storage (M$/Yr)
  StorageEG::VariableArray{2} = ReadDisk(db, "EGOutput/StorageEG") # [Area,Year] Electricity Generated from Storage Technologies (GWh/Yr)
  StorageEnergy::VariableArray{2} = ReadDisk(db, "EGOutput/StorageEnergy") # [Area,Year] Electricity Required to Recharge Storage Technologies (GWh/Yr)
  StorageNetRevenue::VariableArray{2} = ReadDisk(db, "EGOutput/StorageNetRevenue") # [Area,Year] Net Revenue from Storage Operations (M$/Yr)
  StorageRevenue::VariableArray{2} = ReadDisk(db, "EGOutput/StorageRevenue") # [Area,Year] Revenue from Storage Generation (M$/Yr)
  StorageUnitCosts::VariableArray{2} = ReadDisk(db, "EGOutput/StorageUnitCosts") # [Area,Year] Storage Energy Unit Costs ($/MWh)
  StorCurtailed::VariableArray{4} = ReadDisk(db, "EGOutput/StorCurtailed") # [TimeP,Month,Node,Year] Curtailed Generation which Recharges Storage (GWh/Yr)
  StorEG::VariableArray{4} = ReadDisk(db, "EGOutput/StorEG") # [TimeP,Month,Node,Year] Electricity Generated from Storage Technologies (GWh/Yr)
  StorEnergy::VariableArray{4} = ReadDisk(db, "EGOutput/StorEnergy") # [TimeP,Month,Node,Year] Electricity Required to Recharge Storage Technologies (GWh/Yr)
  StorPurchases::VariableArray{3} = ReadDisk(db, "EGOutput/StorPurchases") # [Month,Node,Year] Generation Purchased to Recharge Storage (GWh/Yr)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnVCost::VariableArray{4} = ReadDisk(db, "EGOutput/UnVCost") # [Unit,TimeP,Month,Year] Bid Price of Power Offered to Spot Market ($/MWh)
  xAreaPurchases::VariableArray{2} = ReadDisk(db, "EGInput/xAreaPurchases") # [Area,Year] Historical Purchases from Areas in the same Country (GWh/Yr)
  xAreaSales::VariableArray{2} = ReadDisk(db, "EGInput/xAreaSales") # [Area,Year] Historical Sales to Areas in the same Country (GWh/Yr)
  xExpPurchases::VariableArray{2} = ReadDisk(db, "EGInput/xExpPurchases") # [Area,Year] Historical Purchases from Areas in a different Country (GWh/Yr)
  xExpSales::VariableArray{2} = ReadDisk(db, "EGInput/xExpSales") # [Area,Year] Historical Sales to Areas in a different Country (GWh/Yr)

  # Scratch Variables
  PkLoadTemp::VariableArray{2} = zeros(Float32,length(Month),length(Year))
  VCost::VariableArray{2} = zeros(Float32, length(Area), length(Year)) # Bid Price of Power Offered to Spot Market ($/MWh)

  SSS = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))

end

function VCostCalc(data)
  (; Area,Areas,Years) = data
  (; UnArea,UnPlant,UnVCost) = data
  (; VCost) = data

  for area in Areas
    units1=findall(UnPlant[:] .== "Battery")
    units2=findall(UnArea[:] .== Area[area])
    units=intersect(units1,units2)
    if !isempty(units)
      unit=first(units)
      timep=1
      month=2
      for year in Years
        VCost[area,year]=UnVCost[unit,timep,month,year]
      end
      #@info "VCost   $(UnArea[unit]) $(UnPlant[unit]) $(@sprintf("%12.6f",VCost[area,Yr(2050)]))"
      #@info "UnVCost $(UnArea[unit]) $(UnPlant[unit]) $(@sprintf("%12.6f",UnVCost[unit,timep,month,Yr(2050)]))"
    end
  end
end

function ElectricStorage_DtaRun(data, TitleKey, TitleName, areas, nodes)
  (; Area,Area,AreaDS,Areas,Class,ClassDS,Classes,ECC,ECCDS,ECCs,FuelEP) = data
  (; FuelEPDS,FuelEPs,Month,MonthDS,Months,Node,NodeDS,Nodes,Plant,PlantDS) = data
  (; Plants,Poll,PollDS,Power,TimeP,TimePs,Year,CDTime,CDYear,SceName) = data
  (; AreaPurchases,AreaSales,CapCredit,CgCap,CgDemand,CgGen,CgFPol) = data
  (; DmdFA,DmdPA,ECCCLMap,EmEGA,EGFA,EGPA,EuFPol,EUEuPol,ExpPurchases,ExpSales) = data
  (; GCFA,GCPA,HDADP,HDADPwithStorage,HDEmMDS,HDHours,HDHrMn,HDHrPk) = data
  (; HDPrA,HMPrA,Inflation,MCE,MEPol,MoneyUnitDS,NcPol,NdArFr,NdArMap) = data
  (; NetImports,PE,PkLoad,PolConv,PSoECC,RnImports,RnSwitch,SaEC) = data
  (; StorageCosts,StorageEG,StorageEnergy,StorageNetRevenue,StorageRevenue) = data
  (; StorageUnitCosts,StorCurtailed,StorEG,StorEnergy,StorPurchases) = data
  (; UnArea,UnPlant,UnVCost,xAreaPurchases,xAreaSales,xExpPurchases,xExpSales) = data
  (; PkLoadTemp,VCost,SSS,TTT,ZZZ) = data

  iob = IOBuffer()

  area_single = first(areas)


  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "This file was produced by ElectricStorage.jl")
  println(iob, " ")

  years = collect(Yr(1990):Final)
  # year = Select(Year)  
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  #
  print(iob, TitleName, " Storage Summary (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "StorageEG;Generation from Storage")
  for year in years
    ZZZ[year] = sum(StorageEG[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "StorageLosses;Losses in Recharging")
  for year in years
    ZZZ[year] = sum((StorageEnergy[area,year]-StorageEG[area,year]) for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "StorageEnergy;Generation Required to Recharge Storage")
  for year in years
    ZZZ[year] = sum(StorageEnergy[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "StorCurtailed;Recharged from Curtailed Units")
  for year in years
    ZZZ[year] = sum(StorCurtailed[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, month in Months, timep in TimePs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "StorPurchases;Recharged from Power Purchases")
  for year in years
    ZZZ[year] = sum(StorPurchases[month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, month in Months)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, TitleName, " Storage Revenue Summary (Millions $CDTime ",MoneyUnitDS[area_single],");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "StorageNetRevenue;Net Revenue from Storage")
  for year in years
    ZZZ[year] = sum(StorageNetRevenue[area,year] for area in areas)/Inflation[area_single,year]*Inflation[area_single,CDYear]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "StorageRevenue;Gross Revenue from Storage")
  for year in years
    ZZZ[year] = sum(StorageRevenue[area,year] for area in areas)/Inflation[area_single,year]*Inflation[area_single,CDYear]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "StorageCosts;Cost of Generation for Filling Storage")
  for year in years
    ZZZ[year] = sum(StorageCosts[area,year] for area in areas)/Inflation[area_single,year]*Inflation[area_single,CDYear]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, TitleName, " Storage Unit Price Summary ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "StorageUnitRevenue;Unit Revenue")
  for year in years
    @finite_math ZZZ[year] = sum(StorageNetRevenue[area,year] for area in areas)/Inflation[area_single,year]*Inflation[area_single,CDYear]/
        sum(StorageEG[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "StorageUnitCosts;Recharging Unit Costs")
  for year in years
    @finite_math ZZZ[year] = sum(StorageCosts[area,year] for area in areas)/Inflation[area_single,year]*Inflation[area_single,CDYear]/
        sum(StorageEG[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "MCE;Cost of New Storage")
  peak=Select(Power,"Peak")
  for year in years
    @finite_math ZZZ[year] = MCE[1,peak,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "UnVCost;Bid Price of Storage")
  for year in years
    @finite_math ZZZ[year] = (sum(VCost[area,year]*max(StorageEG[area,year],0.0001) for area in areas))/
        (sum(max(StorageEG[area,year],0.0001) for area in areas))/Inflation[area_single,year]*Inflation[area_single,CDYear]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "HMPrA;Wholesale Electric Price")
  for year in years
    @finite_math ZZZ[year] = HMPrA[area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, TitleName, " Generation from Storage (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "StorEG;Annual")
  for year in years
    ZZZ[year] = sum(StorEG[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, month in Months, timep in TimePs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob, "StorEG;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(StorEG[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob, "StorEG;",MonthDS[month]," $TPDS")
      for year in years
        ZZZ[year] = sum(StorEG[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob)

  #
  print(iob, TitleName, " Recharged from Curtailed Units (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "StorCurtailed;Annual")
  for year in years
    ZZZ[year] = sum(StorCurtailed[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, month in Months, timep in TimePs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob, "StorCurtailed;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(StorCurtailed[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob, "StorCurtailed;",MonthDS[month]," $TPDS")
      for year in years
        ZZZ[year] = sum(StorCurtailed[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob)

  #
  print(iob, TitleName, " Recharged from Power Purchases (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "StorPurchases;Total")
  for year in years
    ZZZ[year] = sum(StorPurchases[month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, month in Months)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob, "StorPurchases;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(StorPurchases[month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob, TitleName, " Wholesale Price ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for month in Months
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob, "HDPrA;",MonthDS[month]," $TPDS")
      for year in years
        @finite_math ZZZ[year] = sum(HDPrA[node,timep,month,year]*HDADP[node,timep,month,year]*
            NdArFr[node,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, node in Nodes)/
            sum(HDADP[node,timep,month,year]*NdArFr[node,area,year] for area in areas, node in Nodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob)

  #
  print(iob, TitleName, " Energy needed for Recharge (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "StorEnergy;Annual")
  for year in years
    ZZZ[year] = sum(StorEnergy[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, month in Months, timep in TimePs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob, "StorEnergy;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(StorEnergy[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob, "StorEnergy;",MonthDS[month]," $TPDS")
      for year in years
        ZZZ[year] = sum(StorEnergy[timep,month,node,year]*NdArFr[node,area,year] for area in areas, node in Nodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob)

  #
  print(iob, TitleName, " Average Load before Storage (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "HDADP;Annual")
  for year in years
    ZZZ[year] = sum(HDADP[node,timep,month,year]*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, month in Months, timep in TimePs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob, "HDADP;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(HDADP[node,timep,month,year]*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob, TitleName, " Average Load in Interval with Generation to Fill Storage (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "HDADPwithStorage;Annual")
  for year in years
    ZZZ[year] = sum(HDADPwithStorage[node,timep,month,year]*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, month in Months, timep in TimePs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob, "HDADPwithStorage;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(HDADPwithStorage[node,timep,month,year]*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob, TitleName, " Average Load Change due to Storage (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  # TODO Rename to HDADPChange?
  print(iob, "HDADP;Annual")
  for year in years
    ZZZ[year] = sum((HDADPwithStorage[node,timep,month,year]-HDADP[node,timep,month,year])*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, month in Months, timep in TimePs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    # TODO Rename to HDADPChange?
    print(iob, "HDADP;",MonthDS[month])
    for year in years
      ZZZ[year] = sum((HDADPwithStorage[node,timep,month,year]-HDADP[node,timep,month,year])*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  for month in Months
    print(iob, TitleName," ",MonthDS[month]," Average Load before Storage (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "HDADP;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(HDADP[node,timep,month,year]*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob, "HDADP;",MonthDS[month]," $TPDS")
      for year in years
        ZZZ[year] = sum(HDADP[node,timep,month,year]*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  for month in Months
    print(iob, TitleName," ",MonthDS[month]," Average Load after Storage (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "HDADPwithStorage;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(HDADPwithStorage[node,timep,month,year]*
                      NdArFr[node,area,year]*HDHours[timep,month]/1000 
                      for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob, "HDADPwithStorage;",MonthDS[month]," $TPDS")
      for year in years
        ZZZ[year] = sum(HDADPwithStorage[node,timep,month,year]*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  for month in Months
    print(iob, TitleName," ",MonthDS[month]," Average Load Change due to Storage (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "HDADPChange;",MonthDS[month])
    for year in years
      ZZZ[year] = sum((HDADPwithStorage[node,timep,month,year]-HDADP[node,timep,month,year])*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes, timep in TimePs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob, "HDADPChange;",MonthDS[month]," $TPDS")
      for year in years
        ZZZ[year] = sum((HDADPwithStorage[node,timep,month,year]-HDADP[node,timep,month,year])*NdArFr[node,area,year]*HDHours[timep,month]/1000 for area in areas, node in Nodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  # Generation by Plant Type
  #
  print(iob,TitleName," Generation by Plant Type (GWh);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)  
  print(iob,"EGPA;Total")
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for area in areas, plant in Plants)
    TTT[year] = ZZZ[year]
    SSS[year] = 0.0
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"EGPA;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGPA[plant,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  print(iob,"EGPA;Other Types")
  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Generating Capacity by Plant Type
  #
  print(iob,TitleName," Generating Capacity by Plant Type (MW);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob,"GCPA;Total")
  for year in years
    ZZZ[year] = sum(GCPA[plant,area,year] for area in areas,plant in Plants)
    TTT[year] = ZZZ[year]
    SSS[year] = 0.0
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"GCPA;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year] for area in areas)
      SSS[year] = SSS[year] + ZZZ[year]  
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  print(iob,"GCPA;Other Types")
  for year in years
    ZZZ[year] = TTT[year] - SSS[year]
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,TitleName," Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"SaEC;Total")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas,ecc in ECCs) 
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
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
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
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
  #
  print(iob,"AreaPurchases;In-Flows")
  for year in years
    ZZZ[year] = sum(AreaPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"AreaSales;Out-Flows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"ExpPurchases;Imports")
  for year in years
    ZZZ[year] = sum(ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"ExpSales;Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"NetExp;Net Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] - ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"Net;Net Out-Flows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] - AreaPurchases[area,year] +
      ExpSales[area,year] - ExpPurchases[area,year] for area in areas)  
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  
  #
  # Peak Loads
  #
  print(iob,TitleName," Peak Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
  #
  print(iob,"PkLoad;Annual")
  for year in years
    PkLoadTemp[Months,year] = sum(PkLoad[Months,area,year] for area in areas)
    ZZZ[year] = maximum(PkLoadTemp[month,year] for month in Months)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  #
  for month in Months
    print(iob,"PkLoad;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(PkLoad[month,area,year] for area in areas)    
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Real Retail Prices
  #
  #
  print(iob, TitleName, " Retail Rate (2010 ",MoneyUnitDS[area_single],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PE;Average Retail Rate")
  for year in years
    @finite_math ZZZ[year] = sum(PE[ecc,area,year]*SaEC[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr(2010)] for area in areas, ecc in ECCs)/
        sum(SaEC[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for class in Classes
    print(iob,"PE;",ClassDS[class])  
    for year in years  
      @finite_math ZZZ[year] = sum(PE[ecc,area,year]*SaEC[ecc,area,year]*ECCCLMap[ecc,class]/
          Inflation[area,year]*Inflation[area,Yr(2010)] for area in areas, ecc in ECCs)/
          sum(SaEC[ecc,area,year]*ECCCLMap[ecc,class] for area in areas, ecc in ECCs)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Electric Utility GHG Emissions By Plant Type
  #
  polls=Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  ecc=Select(ECC,"UtilityGen")

  print(iob, TitleName, " Electric Utility GHG Emissions (MT/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "Total;Total")
  for year in years
    ZZZ[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll] for area in areas, poll in polls, plant in Plants, fuelep in FuelEPs)/1e6+
           sum(MEPol[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls)/1e6+
           sum(NcPol[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls)/1e6
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "EUEuPol;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EUEuPol[fuelep,plant,poll,area,year]*PolConv[poll] for area in areas, poll in polls, fuelep in FuelEPs)/1e6
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  print(iob, "MEPol;Non-Energy")
  for year in years
    ZZZ[year] = sum(MEPol[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls)/1e6
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "NcPol;Non-Combustion")
  for year in years
    ZZZ[year] = sum(NcPol[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls)/1e6
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Emergency Generation
  # This variable is last since it has a varying number of rows. JSA 05/13/09
  #
  print(iob,TitleName," Emergency Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EmEGA;Total")
  for year in years
    ZZZ[year] = sum(EmEGA[node,timep,month,year] 
      for month in Months, timep in TimePs, node in nodes)
    print(iob,";",@sprintf("%.0f",ZZZ[year]))
  end
  println(iob)
  for node in nodes
    print(iob,"EmEGA;",NodeDS[node])
    for year in years
      ZZZ[year] = sum(EmEGA[node,timep,month,year] for month in Months,timep in TimePs)
      print(iob,";",@sprintf("%.0f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  node_single=first(nodes)
  print(iob,TitleName," $(NodeDS[node_single]) Emergency Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"HDEmMDS;Total")
  for year in years
    ZZZ[year] = sum(maximum(HDEmMDS[node,timep,month,year] for month in Months,timep in TimePs) for node in nodes)
    print(iob,";",@sprintf("%.0f",ZZZ[year]))
  end
  println(iob)
  for node in nodes
    print(iob,"HDEmMDS;",NodeDS[node])
    for year in years
      ZZZ[year] = maximum(HDEmMDS[node,timep,month,year] for month in Months,timep in TimePs)
      print(iob,";",@sprintf("%.0f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  for node in nodes
    print(iob,TitleName," ",NodeDS[node],"  Emergency Capacity (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"HDEmMDS;Maximum")
    for year in years
      ZZZ[year] = maximum(HDEmMDS[node,timep,month,year] for month in Months,timep in TimePs)
      print(iob,";",@sprintf("%.0f",ZZZ[year]))
    end
    println(iob)
    for month in Months
      print(iob,"HDEmMDS;",MonthDS[month]," Maximum")
      for year in years
        ZZZ[year] = maximum(HDEmMDS[node,timep,month,year] for timep in TimePs)
        print(iob,";",@sprintf("%.0f",ZZZ[year]))
      end
      println(iob)
      for timep in TimePs
        TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
        print(iob,"HDEmMDS;",MonthDS[month]," $TPDS")
        for year in years
          ZZZ[year] = HDEmMDS[node,timep,month,year]
          print(iob,";",@sprintf("%.0f",ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)
  end

  filename = "ElectricStorage-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ElectricStorage_DtaControl(db)
  @info "ElectricStorage_DtaControl"
  data = ElectricStorageData(; db)
  Area = data.Area
  AreaDS = data.AreaDS
  Node = data.Node
  NodeDS = data.NodeDS
  NdArMap = data.NdArMap

  VCostCalc(data)
  
  #
  # Canada
  #
  areas=Select(Area,(from ="ON",to="NU"))
  for area in areas
    nodes = findall(NdArMap[:,area] .> 0)
    if !isempty(nodes)
      ElectricStorage_DtaRun(data,Area[area],AreaDS[area],area,nodes)
    end
  end
  # nodes=Select(Node,(from="MB",to="NU"))
  nodes = findall(sum(NdArMap[:,area] for area in areas) .> 0)
  if !isempty(nodes)
    ElectricStorage_DtaRun(data,"CN","Canada",areas,nodes)
  end

  #
  # US
  #
  areas=Select(Area,(from ="CA",to="Pac"))
  for area in areas
    nodes = findall(NdArMap[:,area] .> 0)
    if !isempty(nodes)
      ElectricStorage_DtaRun(data,Area[area],AreaDS[area],area,nodes)
    end
  end
  nodes = findall(sum(NdArMap[:,area] for area in areas) .> 0)
  if !isempty(nodes)
    ElectricStorage_DtaRun(data,"US","US",areas,nodes)
  end

  #
  # MX
  #
  areas = Select(Area,"MX")
  nodes = Select(Node,"MX")
  if !isempty(nodes)
    ElectricStorage_DtaRun(data,"MX","MX",areas,nodes)
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
ElectricStorage_DtaControl(DB)
end

