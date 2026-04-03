#
# ElectricityPrices.jl
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


Base.@kwdef struct ElectricityPricesData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Class::SetArray = ReadDisk(db, "MainDB/ClassKey")
  Classes::Vector{Int} = collect(Select(Class))
  ClassDS::SetArray = ReadDisk(db, "MainDB/ClassDS")
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db, "MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  PPSet::SetArray = ReadDisk(db, "EInput/PPSetDS")
  TimeP::SetArray = ReadDisk(db, "MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  ACE::VariableArray{3} = ReadDisk(db, "EOutput/ACE") #[Plant,GenCo,Year]  Average Cost of Power ($/MWh)
  AFC::VariableArray{3} = ReadDisk(db, "EOutput/AFC") #[Plant,GenCo,Year]  Average Fixed Costs ($/KW)
  ArNdFr::VariableArray{3} = ReadDisk(db, "EGInput/ArNdFr") #[Area,Node,Year]  Fraction of the Area in each Node (MW/MW)
  AVC::VariableArray{3} = ReadDisk(db, "EOutput/AVC") #[Plant,GenCo,Year]  Average Variable Costs ($/MWh)
  Capacity::VariableArray{6} = ReadDisk(db, "EOutput/Capacity") #[Area,GenCo,Plant,TimeP,Month,Year]  Capacity under Contract (MW)
  DCCost::VariableArray{2} = ReadDisk(db, "EOutput/DCCost") #[Area,Year]  Capacity Cost (M$/Yr)
  DVCost::VariableArray{2} = ReadDisk(db, "EOutput/DVCost") #[Area,Year]  Variable Cost (M$/Yr)
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  EGA::VariableArray{3} = ReadDisk(db, "EGOutput/EGA") #[Plant,GenCo,Year]  Electricity Generated (GWh/Yr)
  EGBI::VariableArray{4} = ReadDisk(db, "EOutput/EGBI") #[Area,GenCo,Plant,Year]  Electricity sold thru Contracts (GWh/Yr)
  EGBIPG::VariableArray{2} = ReadDisk(db, "EOutput/EGBIPG") #[Area,Year]  Electricity sold thru Contracts (GWh/Yr)
  Energy::VariableArray{4} = ReadDisk(db, "EOutput/Energy") #[Area,GenCo,Plant,Year]  Energy Limit on Contracts (Gwh/Yr)
  ExportsPE::VariableArray{2} = ReadDisk(db, "EOutput/ExportsPE") #[Area,Year]  Electric Exports Unit Revenues in Price ($/MWh)
  ExportsRevenues::VariableArray{2} = ReadDisk(db, "SOutput/ExportsRevenues") #[Area,Year]  Electric Exports Revenues (M$/Yr)
  ExportsUR::VariableArray{2} = ReadDisk(db, "EOutput/ExportsUR") #[Area,Year]  Electric Exports Unit Revenues ($/MWh)
  ExportsURFraction::VariableArray{2} = ReadDisk(db, "EInput/ExportsURFraction") #[Area,Year]  Electric Exports Unit Revenues Flag (0=exclude)
  FPSMF::VariableArray{4} = ReadDisk(db, "SInput/FPSMF") #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db, "SInput/FPTaxF") #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  GCG::VariableArray{3} = ReadDisk(db, "EOutput/GCG") #[Plant,GenCo,Year]  Generation Capacity (MW)
  GPURef::VariableArray{2} = ReadDisk(db, "EOutput/GPURef") #[Area,Year]  Gratis Permit Unit Refund ($/MWh)
  HDEnergy::VariableArray{4} = ReadDisk(db, "EGOutput/HDEnergy") #[Node,TimeP,Month,Year]  Energy in Interval (GWh/Yr)
  HDHrMn::VariableArray{2} = ReadDisk(db, "EInput/HDHrMn") #[TimeP,Month]  Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db, "EInput/HDHrPk") #[TimeP,Month]  Peak Hour in the Interval (Hour)
  HDPrA::VariableArray{4} = ReadDisk(db, "EOutput/HDPrA") #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
  HMEnergy::VariableArray{5} = ReadDisk(db, "EOutput/HMEnergy") #[Node,Area,TimeP,Month,Year]  Energy in Interval (GWh/Yr)
  HMPr::VariableArray{4} = ReadDisk(db, "EOutput/HMPr") #[Area,TimeP,Month,Year]  Spot Market Price ($/MWh)
  HMPrA::VariableArray{2} = ReadDisk(db, "EOutput/HMPrA") #[Area,Year]  Average Spot Market Price ($/MWh)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") #[Area,Year]  Inflation Index
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  NdArFr::VariableArray{3} = ReadDisk(db, "EGInput/NdArFr") #[Node,Area,Year]  Fraction of the Node in each Area
  NPAC::VariableArray{3} = ReadDisk(db, "EOutput/NPAC") #[ECC,Area,Year]  Non-Power Average Unit Cost ($/MWh)
  NPAdd::VariableArray{3} = ReadDisk(db, "EOutput/NPAdd") #[ECC,Area,Year]  Non-Power Cost Additions (M$/Yr)
  NPCosts::VariableArray{3} = ReadDisk(db, "EOutput/NPCosts") #[ECC,Area,Year]  Non-Power Costs (M$/Yr)
  NPICosts::VariableArray{3} = ReadDisk(db, "EOutput/NPICosts") #[ECC,Area,Year]  Non-Power Indicated Costs (M$/Yr)
  NPPL::VariableArray{2} = ReadDisk(db, "EInput/NPPL") #[Area,Year]  Non-Power Cost Lifetime (Years)
  NPRetire::VariableArray{3} = ReadDisk(db, "EOutput/NPRetire") #[ECC,Area,Year]  Non-Power Cost Retirements (M$/Yr)
  NPUC::VariableArray{3} = ReadDisk(db, "ECalDB/NPUC") #[ECC,Area,Year]  Non-Power Marginal Unit Cost ($/MWh)
  PE::VariableArray{3} = ReadDisk(db, "EOutput/PE") #[ECC,Area,Year]  Marketer Price of Electricity ($/MWh)
  PECalc::VariableArray{3} = ReadDisk(db, "EOutput/PECalc") #[ECC,Area,Year]  Calculated Price of Electricity ($/MWh)
  PEClass::VariableArray{3} = ReadDisk(db, "EOutput/PEClass") #[Class,Area,Year]  Price of Electricity ($/MWh)
  PEDC::VariableArray{3} = ReadDisk(db, "ECalDB/PEDC") #[ECC,Area,Year]  Electric Delivery Charge ($/MWh)
  PEDmd::VariableArray{3} = ReadDisk(db, "SOutput/PE") #[ECC,Area,Year]  Price of Electricity for Demand Sector ($/MWh)
  PDPT::VariableArray{2} = ReadDisk(db, "EOutput/PDPT") #[Area,Year]  Peak Demand (MW)
  # PPEGA::VariableArray{3} = ReadDisk(db, "EOutput/PPEGA") #[PPSet,Area,Year]  Purchased Power (GWh/Yr)
  PPUC::VariableArray{2} = ReadDisk(db, "EOutput/PPUC") #[Area,Year]  Unit Cost of Purchased Power ($/MWh)
  PUCT::VariableArray{2} = ReadDisk(db, "EOutput/PUCT") #[Area,Year]  Cost of Purchase Power (M$/Yr)
  PUCTBI::VariableArray{2} = ReadDisk(db, "EOutput/PUCTBI") #[Area,Year]  Cost of Purchase Power from Bilateral Contracts (M$/Yr)
  PUCTSM::VariableArray{2} = ReadDisk(db, "EOutput/PUCTSM") #[Area,Year]  Cost of Purchase Power from Spot Market (M$/Yr)
  RnACE::VariableArray{1} = ReadDisk(db, "EOutput/RnACE") #[Year]  Average Unit Cost of Renewable Power ($/MWh)
  RnPE::VariableArray{2} = ReadDisk(db, "EOutput/RnPE") #[Area,Year]  RECs Contribution to Retail Price ($/MWh)
  RnCosts::VariableArray{2} = ReadDisk(db, "EOutput/RnCosts") #[Area,Year]  Renewable RECs Costs (M$/Yr)
  RnRq::VariableArray{2} = ReadDisk(db, "EOutput/RnRq") #[Area,Year]  Renewable Purchases Required (GWh/Yr)
  RnSelf::VariableArray{2} = ReadDisk(db, "EOutput/RnSelf") #[Area,Year]  Renewable Purchases from Bilateral Contracts (GWh/Yr)
  SaECD::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") #[ECC,Area,Year]  Electricity Sales (GWh/Yr)
  SAECN::VariableArray{4} = ReadDisk(db, "EOutput/SAECN") #[ECC,Node,Area,Year]  Electricity Sales (GWh/Yr)
  SACL::VariableArray{3} = ReadDisk(db, "EOutput/SACL") #[Class,Area,Year]  Electricity Sales (GWh/Yr)
  SICstG::VariableArray{2} = ReadDisk(db, "EOutput/SICstG") #[GenCo,Year]  Stranded Investment Cost by GenCo (M$/Yr)
  SICstR::VariableArray{2} = ReadDisk(db, "EOutput/SICstR") #[Area,Year]  Stranded Investment Cost by Area (M$/Yr)
  SICstPE::VariableArray{2} = ReadDisk(db, "EOutput/SICstPE") #[Area,Year]  Stranded Investment Cost in Retail Price ($/MWh)
  TPPEGA::VariableArray{2} = ReadDisk(db, "EOutput/TPPEGA") #[Area,Year]  Total Purchase Power (GWh/Yr)
  TSales::VariableArray{2} = ReadDisk(db, "EOutput/TSales") #[Area,Year]  Electricity Sales (GWh/Yr)
  UCConts::VariableArray{2} = ReadDisk(db, "EOutput/UCConts") #[Area,Year]  Unit Cost of Contracts ($/MWh)
  UCCost::VariableArray{4} = ReadDisk(db, "EOutput/UCCost") #[Area,GenCo,Plant,Year]  Contract Capacity Cost ($/KW)
  UnAFC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAFC") #[Unit,Year]  Average Fixed Costs ($/KW)
  UnAVC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAVC") #[Unit,Year]  Average Variable Costs ($/MWh)
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit]  Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnEGA") #[Unit,Year]  Generation (GWh/Yr)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UPURPP::VariableArray{2} = ReadDisk(db, "EOutput/UPURPP") #[Area,Year]  Unit Cost of Purchases ($/MWh)
  UVCost::VariableArray{4} = ReadDisk(db, "EOutput/UVCost") #[Area,GenCo,Plant,Year]  Contract Variable Cost ($/MWh)

  #
  # Scratch Variables
  #
  PEBuiltUp = zeros(Float32, length(ECC), length(Year))
  SumCap = zeros(Float32, length(Area), length(Year))
  SumEGBI = zeros(Float32, length(Area), length(Year))
  UnACE = zeros(Float32, length(Unit), length(Year))

  DDD = zeros(Float32, length(Year))
  NNN = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))
end
function ElectricityPrices_DtaRun(data, AreaName)
  (; Area,AreaDS,Class,ClassDS,Classes,ECC,ECCDS,ES,ESDS,Fuel) = data
  (; FuelDS,GenCo,GenCoDS,GenCos,Month,MonthDS,Months,Node,NodeDS) = data
  (; Plant,PlantDS,Plants,TimeP,TimePs,Unit,Year,CDTime,CDYear,SceName) = data
  (; ACE,AFC,ArNdFr,AVC,Capacity,DCCost,DVCost,EEConv,EGA) = data
  (; EGBI,EGBIPG,Energy,ExportsPE,ExportsRevenues,ExportsUR) = data
  (; ExportsURFraction,FPSMF,FPTaxF,GCG,GPURef,HDEnergy) = data
  (; HDHrMn,HDHrPk,HDPrA,HMEnergy,HMPr,HMPrA,Inflation) = data
  (; MoneyUnitDS,NdArFr,NPAC,NPAdd,NPCosts,NPICosts) = data
  (; NPPL,NPRetire,NPUC,PE,PECalc,PEClass,PEDC,PEDmd) = data
  (; PDPT,PPUC,PUCT,PUCTBI,PUCTSM,RnACE,RnPE,RnCosts) = data
  (; RnRq,RnSelf,SaECD,SAECN,SACL,SICstG,SICstR,SICstPE) = data
  (; TPPEGA,TSales,UCConts,UCCost,UnAFC,UnAVC,UnCode) = data
  (; UnCogen,UnEGA,UnGC,UnGenCo,UnPlant,UPURPP,UVCost) = data
  (; DDD,NNN,PEBuiltUp,SumCap,SumEGBI,UnACE,ZZZ) = data

  area = Select(AreaDS,"$AreaName")
  genco_match = Select(AreaDS,"$AreaName")
  Electric = Select(Fuel,"Electric")
  month1 = 1
  timep1 = 1
  years = collect(Yr(2000):Final)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$AreaName; is the area being output.")
  println(iob, "This file is created by ElectricityPrices.jl.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  print(iob, AreaName, " Retail Price of Electricity ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
  for class in Classes
    print(iob, "PEClass;", ClassDS[class])
    for year in years
      @finite_math ZZZ[year] =
        PEClass[class,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Retail Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "SACL;Total")
  for year in years
    ZZZ[year] = sum(SACL[class,area,year] for class in Classes)
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for class in Classes
    print(iob, "SACL;", ClassDS[class])
    for year in years
      ZZZ[year] = SACL[class,area,year]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Estimated Price of Electricity ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "PECalc;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = PECalc[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  ecc = Select(ECC,"SingleFamilyAttached")
  es = Select(ES,"Residential")
  print(iob, AreaName, " Price of Electricity Built-Up ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    @finite_math PEBuiltUp[ecc,year]=(PPUC[area,year-1]-ExportsPE[area,year-1]+
      NPAC[ecc,area,year]+RnPE[area,year]+SICstPE[area,year-1]-GPURef[area,year-1]+
      PEDC[ecc,area,year]*Inflation[area,year]+
      FPTaxF[Electric,es,area,year]*EEConv/1000*Inflation[area,year])*
      (1+FPSMF[Electric,es,area,year])/Inflation[area,year]*Inflation[area,CDYear]
  end

  ecc = Select(ECC,"Retail")
  es = Select(ES,"Commercial")
  for year in years
    @finite_math PEBuiltUp[ecc,year]=(PPUC[area,year-1]-ExportsPE[area,year-1]+
      NPAC[ecc,area,year]+RnPE[area,year]+SICstPE[area,year-1]-GPURef[area,year-1]+
      PEDC[ecc,area,year]*Inflation[area,year]+
      FPTaxF[Electric,es,area,year]*EEConv/1000*Inflation[area,year])*
      (1+FPSMF[Electric,es,area,year])/Inflation[area,year]*Inflation[area,CDYear]
  end

  ecc = Select(ECC,"Food")
  es = Select(ES,"Industrial")
  for year in years
    @finite_math PEBuiltUp[ecc,year]=(PPUC[area,year-1]-ExportsPE[area,year-1]+
      NPAC[ecc,area,year]+RnPE[area,year]+SICstPE[area,year-1]-GPURef[area,year-1]+
      PEDC[ecc,area,year]*Inflation[area,year]+
      FPTaxF[Electric,es,area,year]*EEConv/1000*Inflation[area,year])*
      (1+FPSMF[Electric,es,area,year])/Inflation[area,year]*Inflation[area,CDYear]
  end

  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  for ecc in eccs
    print(iob, "PEBuiltUp;", ECCDS[ecc])    
    for year in years
      ZZZ[year] = PEBuiltUp[ecc,year]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Price of Electricity Ratio (\$/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "PE Ratio;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = PECalc[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]/PEBuiltUp[ecc,year]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob, AreaName, " Lagged Purchase Power Unit Costs ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PPUC;$AreaName")
  for year in years
    @finite_math ZZZ[year] = PPUC[area,year-1]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Delivery Charge ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "PEDC;", ECCDS[ecc])
    for year in years
      ZZZ[year] = PEDC[ecc,area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Lagged Export Unit Revenue ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "ExportsUR;$AreaName")
  for year in years
    @finite_math ZZZ[year] = ExportsUR[area,year-1]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Lagged Export Unit Revenue in Price ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "ExportsPE;$AreaName")
  for year in years
    @finite_math ZZZ[year] = ExportsPE[area,year-1]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Non-Power Average Unit Cost ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "NPAC;", ECCDS[ecc])  
    for year in years
      ZZZ[year] = NPAC[ecc,area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Lagged Stranded Investments ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "SICstPE;$AreaName")  
  for year in years
    @finite_math ZZZ[year] = SICstPE[area,year-1]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " RECs Contribution to Retail Price ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "RnPE;;")
  for year in years
    @finite_math  ZZZ[year] = RnPE[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Lagged Gratis Permit Refund ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "GPURef;$AreaName")
  for year in years
    @finite_math  ZZZ[year] = GPURef[area,year-1]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  es = Select(ES,["Residential","Commercial","Industrial"])
  print(iob, AreaName, " Fuel Taxes ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for es in es
    print(iob, "FPTaxF;", ESDS[es])
    for year in years
      ZZZ[year] = FPTaxF[Electric,es,area,year]*EEConv/1000*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Sales Tax
  #
  ecc = Select(ECC,"SingleFamilyAttached")
  es = Select(ES,"Residential")
  print(iob, AreaName, " Sales Tax ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "FPSMF Calc;", ESDS[es])
  for year in years
    ZZZ[year]=PEBuiltUp[ecc,year]-
      (PPUC[area,year-1]-ExportsPE[area,year-1]+
      NPAC[ecc,area,year]+RnPE[area,year]+SICstPE[area,year-1]-GPURef[area,year-1]+
      PEDC[ecc,area,year]*Inflation[area,year]+
      FPTaxF[Electric,es,area,year]*EEConv/1000*Inflation[area,year])/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end    
  println(iob)

  ecc = Select(ECC,"Retail")
  es = Select(ES,"Commercial")
  print(iob, "FPSMF Calc;", ESDS[es])
  for year in years
    ZZZ[year]=PEBuiltUp[ecc,year]-
      (PPUC[area,year-1]-ExportsPE[area,year-1]+
      NPAC[ecc,area,year]+RnPE[area,year]+SICstPE[area,year-1]-GPURef[area,year-1]+
      PEDC[ecc,area,year]*Inflation[area,year]+
      FPTaxF[Electric,es,area,year]*EEConv/1000*Inflation[area,year])/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  ecc = Select(ECC,"Food")
  es = Select(ES,"Industrial")
  print(iob, "FPSMF Calc;", ESDS[es])
  for year in years
    ZZZ[year]=PEBuiltUp[ecc,year]-
      (PPUC[area,year-1]-ExportsPE[area,year-1]+
      NPAC[ecc,area,year]+RnPE[area,year]+SICstPE[area,year-1]-GPURef[area,year-1]+
      PEDC[ecc,area,year]*Inflation[area,year]+
      FPTaxF[Electric,es,area,year]*EEConv/1000*Inflation[area,year])/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Purchase Power Unit Costs ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PPUC;$AreaName")
  for year in years
    @finite_math ZZZ[year] = PPUC[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, AreaName, " Bilateral Contract Unit Cost ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "UCConts;$AreaName")
  for year in years
    @finite_math ZZZ[year] = UCConts[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Spot Market Power Unit Cost ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "UPURPP;$AreaName")
  for year in years
    @finite_math ZZZ[year] = UPURPP[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Cost of Purchase Power ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PUCT;$AreaName")
  for year in years
    @finite_math ZZZ[year] = PUCT[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Cost of Purchase Power from Bilateral Contracts ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PUCTBI;$AreaName")
  for year in years
    @finite_math ZZZ[year] = PUCTBI[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Cost of Purchase Power from Spot Market ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PUCTSM;$AreaName")
  for year in years
    @finite_math ZZZ[year] = PUCTSM[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Purchase Power from Bilateral Contracts (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EGBIPG;$AreaName")
  for year in years
    ZZZ[year] = EGBIPG[area,year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Purchase Power from Spot Market (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "TPPEGA;$AreaName")
  for year in years
    ZZZ[year] = TPPEGA[area,year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Export Revenue ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "ExportsRevenues;$AreaName")
  for year in years
    @finite_math ZZZ[year] = ExportsRevenues[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Bilateral Contract Variable Cost ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "DVCost;Total")
  for year in years
    @finite_math ZZZ[year]=DVCost[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "DVCost;", PlantDS[plant])  
    for year in years
      @finite_math ZZZ[year] = sum(EGBI[area,genco,plant,year] .* UVCost[area,genco,plant,year] for genco in GenCos)/1000 ./ Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Bilateral Contract Capacity Cost ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "DCCost;Total")
  for year in years
    @finite_math ZZZ[year] = DCCost[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "DCCost;", PlantDS[plant])
    for year in years
      @finite_math ZZZ[year] = sum(Capacity[area,genco,plant,timep1,month1,year] .*
        UCCost[area,genco,plant,year] for genco in GenCos)/1000 ./
        Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Bilateral Contract Average Unit Cost ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "UACost;Total")
  for year in years
    SumEGBI[area,year] = sum(EGBI[area,genco,plant,year] for plant in Plants, genco in GenCos)
    @finite_math ZZZ[year] = (DVCost[area,year]+DCCost[area,year])/
      SumEGBI[area,year]*1000/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "UACost;", PlantDS[plant])
    for year in years
      SumEGBI[area,year] = sum(EGBI[area,genco,plant,year] for genco in GenCos)
      @finite_math ZZZ[year] = (sum(EGBI[area,genco,plant,year] * UVCost[area,genco,plant,year] + Capacity[area,genco,plant,timep1,month1,year] * UCCost[area,genco,plant,year] for genco in GenCos) /
        SumEGBI[area,year]) / Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Bilateral Contract Variable Unit Cost ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "UVCost;Total")
  for year in years
    SumEGBI[area,year] = sum(EGBI[area,genco,plant,year] for plant in Plants, genco in GenCos)
    @finite_math ZZZ[year]=(DVCost[area,year])/
      SumEGBI[area,year]*1000/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "UVCost;", PlantDS[plant])
    for year in years
      SumEGBI[area,year] = sum(EGBI[area,genco,plant,year] for genco in GenCos)
      @finite_math ZZZ[year] = (sum(EGBI[area,genco,plant,year] * UVCost[area,genco,plant,year] for genco in GenCos) /
        SumEGBI[area,year]) / Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Bilateral Contract Capacity Unit Cost ($CDTime ",MoneyUnitDS[area],"/KW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "UCCost;Total")
  for year in years
    SumCap[area,year] = sum(Capacity[area,genco,plant,timep1,month1,year] for plant in Plants, genco in GenCos)
    @finite_math ZZZ[year] = (DCCost[area,year])/
      SumCap[area,year]*1000/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "UCCost;", PlantDS[plant])
    for year in years
      SumCap[area,year] = sum(Capacity[area,genco,plant,timep1,month1,year] for genco in GenCos)
      @finite_math ZZZ[year] = (sum(Capacity[area,genco,plant,timep1,month1,year] * UCCost[area,genco,plant,year] for genco in GenCos) /
        SumCap[area,year]) / Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Peak Demand (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "PDPT;Peak Demand")
  for year in years
    ZZZ[year] = PDPT[area,year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Bilateral Capacity Purchases (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "Capacity;Total")
  for year in years
    ZZZ[year] = sum(Capacity[area,genco,plant,timep1,month1,year] for plant in Plants, genco in GenCos)
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "Capacity;", PlantDS[plant])
    for year in years
      ZZZ[year] = sum(Capacity[area,genco,plant,timep1,month1,year] for genco in GenCos)
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Electricity Available thru Bilateral Contracts (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "Energy;Total")
  for year in years
    ZZZ[year] = sum(Energy[area,genco,plant,year] for plant in Plants, genco in GenCos)
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "Energy;", PlantDS[plant])
    for year in years
      ZZZ[year] = sum(Energy[area,genco,plant,year] for genco in GenCos)
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Electricity Sold thru Bilateral Contracts (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "EGBI;Total")
  for year in years
    ZZZ[year] = sum(EGBI[area,genco,plant,year] for plant in Plants, genco in GenCos)
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob, "EGBI;", PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGBI[area,genco,plant,year] for genco in GenCos)
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, GenCoDS[genco_match], " Generator Variable Costs ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for plant in Plants
    print(iob, "AVC;", PlantDS[plant])
    for year in years
      @finite_math ZZZ[year] = AVC[plant,genco_match,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, GenCoDS[genco_match], " Generator Fixed Costs ($CDTime ",MoneyUnitDS[area],"/KW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for plant in Plants
    print(iob, "AFC;", PlantDS[plant])
    for year in years
      @finite_math ZZZ[year] = AFC[plant,genco_match,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, GenCoDS[genco_match], " Generator Cost of Power ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for plant in Plants
    print(iob, "ACE;", PlantDS[plant])
    for year in years
      @finite_math ZZZ[year] = ACE[plant,genco_match,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Marketer Price of Electricity ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  for ecc in eccs
    print(iob, "PE;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = PE[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Total Price of Electricity ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "PEDmd;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = PEDmd[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Spot Market Prices
  #
  print(iob, AreaName, " Spot Market Electricity Price ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    nodes = findall(ArNdFr[area,:,year] .> 0.0)
    if !isempty(nodes)
      @finite_math NNN[year] = sum(HMPr[area,timep,month,year]*HMEnergy[node,area,timep,month,year]*NdArFr[node,area,year] for month in Months, timep in TimePs, node in nodes)
      @finite_math DDD[year] = sum(HMEnergy[node,area,timep,month,year]*NdArFr[node,area,year] for month in Months, timep in TimePs, node in nodes)
      @finite_math ZZZ[year] = NNN[year]/DDD[year]/Inflation[area,year]*Inflation[area,CDYear]
    else
      ZZZ[year] = 0.0
    end
  end
  print(iob, "HMPr;$AreaName")
  for year in years
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Prices by Time Period for Selected Nodes
  #
  for month in Months
    print(iob, AreaName, " ", MonthDS[month], " Clearing Price ($CDTime ",MoneyUnitDS[area],"/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      print(iob, "HMPr;",round(Int,HDHrPk[timep,month]),"--",round(Int,HDHrMn[timep,month]))
      for year in years
        @finite_math ZZZ[year]=HMPr[area,timep,month,year]/Inflation[area,year]*Inflation[area,CDYear]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    print(iob, "HMPr;Average")
    for year in years
      nodes = findall(ArNdFr[area,:,year] .> 0.0)
      if !isempty(nodes)
        @finite_math NNN[year] = sum(HMPr[area,timep,month,year]*HMEnergy[node,area,timep,month,year]*NdArFr[node,area,year] for timep in TimePs, node in nodes)
        @finite_math DDD[year] = sum(HMEnergy[node,area,timep,month,year]*NdArFr[node,area,year] for timep in TimePs, node in nodes)
        @finite_math ZZZ[year] = NNN[year]/DDD[year]/Inflation[area,year]*Inflation[area,CDYear]
      else
        ZZZ[year] = 0.0
      end
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
    println(iob, " ")
  end

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Non-Power Average Unit Cost ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "NPAC;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = NPAC[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Non-Power Cost Additions ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  for ecc in eccs
    print(iob, "NPAdd;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = NPAdd[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Non-Power Costs ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "NPCosts;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = NPCosts[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Non-Power Indicated Costs ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "NPICosts;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = NPICosts[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Non-Power Cost Lifetime (Years);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "NPPL;Years")
  for year in years
    ZZZ[year] = NPPL[area,year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Non-Power Cost Retirements ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "NPRetire;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = NPRetire[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  eccs = Select(ECC,["SingleFamilyAttached","Retail","Food"])
  print(iob, AreaName, " Non-Power Marginal Unit Cost ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob, "NPUC;", ECCDS[ecc])
    for year in years
      @finite_math ZZZ[year] = NPUC[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, AreaName, " Stranded Investments Unit Costs ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "SICstPE;$AreaName")
  for year in years
    @finite_math ZZZ[year] = SICstPE[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Stranded Investments Costs ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "SICstR;$AreaName")
  for year in years
    @finite_math ZZZ[year] = SICstR[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, GenCoDS[genco_match], " GenCo Stranded Investments ($CDTime Millions ",MoneyUnitDS[area],"/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "SICstG;",GenCoDS[genco_match])
  for year in years
    @finite_math ZZZ[year] = SICstG[genco_match,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob,"Average Unit Cost of Renewable Power ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "RnACE;")
  for year in years
    @finite_math ZZZ[year] = RnACE[year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  print(iob, AreaName, "RECs Contribution to Retail Price ($CDTime ",MoneyUnitDS[area],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "RnPE;")
  for year in years
    @finite_math ZZZ[year] = RnPE[year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Renewable RECs Costs ($CDTime Millions ",MoneyUnitDS[area],");")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "RnCosts;")
  for year in years
    @finite_math ZZZ[year] = RnCosts[area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Renewable Purchases Required (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "RnRq;")
  for year in years
    ZZZ[year] = RnRq[year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, AreaName, " Renewable Purchases from Bilateral Contracts (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "RnSelf;")
  for year in years
    ZZZ[year] = RnSelf[year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  for plant in Plants
    units = Select(Unit)
    units_cg = Select(UnCogen,==(0.0))
    units_p = findall(UnPlant[:] .== Plant[plant])
    units_g = findall(UnGenCo[:] .== GenCo[genco_match])
    units = intersect(units,units_cg,units_p,units_g)
    if !isempty(units)
      print(iob, GenCoDS[genco_match], " ",PlantDS[plant]," Average Variable Costs ($CDTime ",MoneyUnitDS[area],"/MWh);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for unit in units
        print(iob, "UnAVC;",UnCode[unit])
        for year in years
          @finite_math ZZZ[year] = UnAVC[unit,year]/Inflation[area,year]*Inflation[area,CDYear]
          print(iob,";",@sprintf("%.6f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
      #
      print(iob, GenCoDS[genco_match], " ",PlantDS[plant]," Average Fixed Costs ($CDTime ",MoneyUnitDS[area],"/KW);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for unit in units
        print(iob, "UnAFC;",UnCode[unit])
        for year in years
          @finite_math ZZZ[year] = UnAFC[unit,year]/Inflation[area,year]*Inflation[area,CDYear]
          print(iob,";",@sprintf("%.6f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)

      #
      print(iob, GenCoDS[genco_match], " ",PlantDS[plant]," Average Cost of Power ($CDTime ",MoneyUnitDS[area],"/MWh);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for unit in units
        print(iob, "UnACE;",UnCode[unit])
        for year in years
          @finite_math UnACE[unit,year]=UnAFC[unit,year]*UnGC[unit,year]/UnEGA[unit,year]+UnAVC[unit,year]
          @finite_math ZZZ[year] = UnACE[unit,year]/Inflation[area,year]*Inflation[area,CDYear]
          print(iob,";",@sprintf("%.6f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob, " ")
    end
  end

  filename = "ElectricityPrices-$(Area[area])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ElectricityPrices_DtaControl(db)
  @info "ElectricityPrices_DtaControl"
  data = ElectricityPricesData(; db)
  AreaDS = data.AreaDS
  for area in Select(AreaDS)
    ElectricityPrices_DtaRun(data, AreaDS[area])
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
ElectricityPrices_DtaControl(DB)
end
