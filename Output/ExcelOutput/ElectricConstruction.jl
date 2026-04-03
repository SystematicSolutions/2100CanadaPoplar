#
# ElectricConstruction.jl
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


Base.@kwdef struct ElectricConstructionData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimeP")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/Year")

  CDTime::Int = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  ArNdFr::VariableArray{3} = ReadDisk(db,"EGInput/ArNdFr") #[Area,Node,Year]  Fraction of the Area in each Node (Fraction)
  BFraction::VariableArray{4} = ReadDisk(db,"EGOutput/BFraction") #[Power,Node,Area,Year]  Endogenous Build Fraction (MW/MW)
  BuildFr::VariableArray{2} = ReadDisk(db,"EGInput/BuildFr") #[Area,Year]  Building fraction
  BuildSw::VariableArray{2} = ReadDisk(db,"EGInput/BuildSw") #[Area,Year]  Build switch
  CapCredit::VariableArray{3} = ReadDisk(db,"EGInput/CapCredit") #[Plant,Area,Year]  Capacity Credit (MW/MW)
  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") #[Plant,Year]  Construction Delay (YEARS)
  CUCFr::VariableArray{2} = ReadDisk(db,"EGOutput/CUCFr") #[Node,Year]  Capacity Under Construction as Fraction of Capacity (MW/MW)
  CUCLimit::VariableArray{1} = ReadDisk(db,"EGInput/CUCLimit") #[Year]  Build Decision Capacity Under Construction Limit (MW/MW)
  CUCMlt::VariableArray{2} = ReadDisk(db,"EGOutput/CUCMlt") #[Node,Year]  Build Decision Capacity Under Construction Constraint (MW/MW)
  CWGA::VariableArray{3} = ReadDisk(db,"EGOutput/CWGA") #[Plant,Area,Year]  Construction Work into Gross Assets (M$)
  DesHr::VariableArray{4} = ReadDisk(db,"EGInput/DesHr") #[Plant,Power,Area,Year]  Design Hours (Hours)
  DRM::VariableArray{2} = ReadDisk(db,"EInput/DRM") #[Node,Year]  Desired Reserve Margin (MW/MW)
  EUPOCX::VariableArray{5} = ReadDisk(db,"EGOutput/EUPOCX") #[FuelEP,Plant,Poll,Area,Year]  Electric Utility Pollution Coefficient (Tonnes/TBtu)
  ExpPurchases::VariableArray{2} = ReadDisk(db,"EGOutput/ExpPurchases") #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db,"EGOutput/ExpSales") #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)
  # F1New::VariableArray{2} = ReadDisk(db,"EGinput/F1New") #[Plant,Area]  Fuel Type 1
  FlFrNew::VariableArray{4} = ReadDisk(db,"EGInput/FlFrNew") #[FuelEP,Plant,Area,Year]  Fuel Fraction for New Plants
  FPEU::VariableArray{3} = ReadDisk(db,"EGOutput/FPEU") #[Plant,Area,Year]  Electric Utility Fuel Prices ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF") #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  GCCC::VariableArray{3} = ReadDisk(db,"EGOutput/GCCC") #[Plant,Area,Year]  Overnight Construction Costs ($/KW)
  GCCCM::VariableArray{3} = ReadDisk(db,"EGOutput/GCCCM") #[Plant,Area,Year]  Capital Cost Multiplier ($/$)
  GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") #[Plant,Area,Year]  Overnight Construction Costs ($/KW)
  GCCR::VariableArray{4} = ReadDisk(db,"EGOutput/GCCR") #[Plant,Node,GenCo,Year]  Capacity Completion Rate (MW/Yr)
  GCDev::VariableArray{4} = ReadDisk(db,"EGOutput/GCDev") #[Plant,Node,Area,Year]  Generation Capacity Developed (MW)
  GCPA::VariableArray{3} = ReadDisk(db,"EOutput/GCPA") #[Plant,Area,Year]  Generation Capacity (MW)
  GCPot::VariableArray{4} = ReadDisk(db,"EGOutput/GCPot") #[Plant,Node,Area,Year]  Maximum Potential Generation Capacity (MW)
  GrMSF::VariableArray{4} = ReadDisk(db,"EGOutput/GrMSF") #[Plant,Node,Area,Year]  Green Power Market Share (MW/MW)
  HDEnergy::VariableArray{4} = ReadDisk(db,"EGOutput/HDEnergy") #[Node,TimeP,Month,Year]  Energy in Interval (GWh)
  HDGCCI::VariableArray{5} = ReadDisk(db,"EGOutput/HDGCCI") #[Plant,Node,GenCo,Area,Year]  New Capacity Initiated (MW)
  HDGCCR::VariableArray{2} = ReadDisk(db,"EGOutput/HDGCCR") #[Node,Year]  Firm Generating Capacity being Revised (MW)
  HDHrMn::VariableArray{2} = ReadDisk(db,"EInput/HDHrMn") #[TimeP,Month]  Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db,"EInput/HDHrPk") #[TimeP,Month]  Peak Hour in the Interval (Hour)
  HDIPGC::VariableArray{5} = ReadDisk(db,"EGOutput/HDIPGC") #[Power,Node,GenCo,Area,Year]  Indicated Planned Generation Capacity (MW)
  HDPrA::VariableArray{4} = ReadDisk(db,"EOutput/HDPrA") #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
  HDPrDP::VariableArray{3} = ReadDisk(db,"EGOutput/HDPrDP") #[Power,Node,Year]  Decision Price for New Construction ($/MWh)
  HDCgGC::VariableArray{2} = ReadDisk(db,"EGOutput/HDCgGC") #[Node,Year]  Firm Cogeneration Capacity Sold to Grid (MW)
  HDCUC::VariableArray{2} = ReadDisk(db,"EGOutput/HDCUC") #[Node,Year]  Firm Capacity under Construction (MW)
  HDFGC::VariableArray{2} = ReadDisk(db,"EGOutput/HDFGC") #[Node,Year]  Forecasted Firm Generation Capacity (MW)
  HDGC::VariableArray{2} = ReadDisk(db,"EGOutput/HDGC") #[Node,Year]  Firm Generating Capacity in Previous Year (MW)
  HDGR::VariableArray{2} = ReadDisk(db,"EGOutput/HDGR") #[Node,Year]  Forecasted Peak Growth Rate
  HDPDP::VariableArray{4} = ReadDisk(db,"EGOutput/HDPDP") #[Node,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
  HDRetire::VariableArray{2} = ReadDisk(db,"EGOutput/HDRetire") #[Node,Year]  Firm Generating Capacity being Retired (MW)
  HDRM::VariableArray{2} = ReadDisk(db,"EGOutput/HDRM") #[Node,Year]  Reserve Margin (MW/MW)
  HDRQ::VariableArray{2} = ReadDisk(db,"EGOutput/HDRQ") #[Node,Year]  Hourly Dispatch Forecasted Generation Requirements
  HRtM::VariableArray{3} = ReadDisk(db,"EGInput/HRtM") #[Plant,Area,Year]  Marginal Heat Rate (Btu/KWh)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") #[Area,Year]  Inflation Index
  IPExpSw::VariableArray{3} = ReadDisk(db,"EGInput/IPExpSw") #[Plant,Area,Year]  Intermittent Power Capacity Expansion Switch (1=Build)
  IPGCCI::VariableArray{5} = ReadDisk(db,"EGOutput/IPGCCI") #[Plant,Node,GenCo,Area,Year]  Intermittent Power Capacity Initiated (MW)
  IPGCPr::VariableArray{5} = ReadDisk(db,"EGOutput/IPGCPr") #[Power,Node,GenCo,Area,Year]  Interruptible Capacity Built based on Spot Market Prices (MW)
  IPGCRM::VariableArray{5} = ReadDisk(db,"EGOutput/IPGCRM") #[Power,Node,GenCo,Area,Year]  Capacity Built based on Reserve Margin (MW)
  IPPrDP::VariableArray{2} = ReadDisk(db,"EGOutput/IPPrDP") #[Node,Year]  Decision Price for building Intermittent Power ($/MWh)
  MCE::VariableArray{4} = ReadDisk(db,"EOutput/MCE") #[Plant,Power,Area,Year]  Cost of Energy from New Capacity ($/MWh)
  MCELimit::VariableArray{2} = ReadDisk(db,"EGInput/MCELimit") #[Area,Year]  Build Decision Cost of Power Limit
  MFC::VariableArray{3} = ReadDisk(db,"EOutput/MFC") #[Plant,Area,Year]  Marginal Fixed Costs ($/KW)
  MoneyUnitDS::Vector{String} = ReadDisk(db,"MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  MVC::VariableArray{3} = ReadDisk(db,"EOutput/MVC") #[Plant,Area,Year]  Marginal Variable Costs ($/MWh)
  NdArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdArMap") #[Node,Area]  Map between Node and Area
  NdNMap::VariableArray{2} = ReadDisk(db,"EGInput/NdNMap") #[Node,Nation]  Map between Node and Nation
  NodeSw::VariableArray{1} = ReadDisk(db,"EGInput/NodeSw") #[Node]  Switch to indicate if Node is Active (1=Active)
  OffValue::VariableArray{4} = ReadDisk(db,"EGOutput/OffValue") #[Plant,Poll,Area,Year]  Value of Offsets ($/MWh)
  ORNew::VariableArray{5} = ReadDisk(db,"EGInput/ORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  PCF::VariableArray{3} = ReadDisk(db,"EGOutput/PCF") #[Plant,GenCo,Year]  Plant Capacity Factor (MW/MW)
  PFFrac::VariableArray{4} = ReadDisk(db,"EGInput/PFFrac") #[FuelEP,Plant,Area,Year]  Fuel Usage Fraction (Btu/Btu)
  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") #[Plant,Area]  Maximum Plant Size (MW)
  PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") #[Plant,Area]  Minimum Plant Size (MW)
  PkLoad::VariableArray{3} = ReadDisk(db,"SOutput/PkLoad") #[Month,Area,Year]  Monthly Peak Load (MW)
  Portfolio::VariableArray{5} = ReadDisk(db,"EGInput/Portfolio") #[Plant,Power,Node,Area,Year]  Portfolio Fraction of New Capacity (MW/MW)
  PoTRNew::VariableArray{3} = ReadDisk(db,"EGOutput/PoTRNew") #[Plant,Area,Year]  Emission Cost for New Plants ($/MWh)
  PriceDiff::VariableArray{4} = ReadDisk(db,"EGOutput/PriceDiff") #[Power,Node,Area,Year]  Difference between Spot Market Price and Price of New Capacity
  RnGCCI::VariableArray{5} = ReadDisk(db,"EGOutput/RnGCCI") #[Plant,Node,GenCo,Area,Year]  Renewable Capacity Initiated (MW)
  RnGen::VariableArray{2} = ReadDisk(db,"EGOutput/RnGen") #[Area,Year]  Renewable Current Level of Generation (GWh/Yr)
  RnGoal::VariableArray{2} = ReadDisk(db,"EGOutput/RnGoal") #[Area,Year]  Renewable Generation Goal for Construction (GWh/Yr)
  Subsidy::VariableArray{3} = ReadDisk(db,"EGInput/Subsidy") #[Plant,Area,Year]  Generating Capacity Subsidy ($/MWh)
  TPRMap::VariableArray{2} = ReadDisk(db,"EGInput/TPRMap") #[TimeP,Power]  TimeP to Power Map
  UFOMC::VariableArray{3} = ReadDisk(db,"EGInput/UFOMC") #[Plant,Area,Year]  Unit Fixed O&M Costs ($/KW)
  UOMC::VariableArray{3} = ReadDisk(db,"EGInput/UOMC") #[Plant,Area,Year]  Unit O&M Costs ($/MWh)
  WCC::VariableArray{2} = ReadDisk(db,"EGInput/WCC") #[Area,Year]  Weighted Cost of Capital (1/Yr)
  xGCPot::VariableArray{4} = ReadDisk(db,"EGInput/xGCPot") #[Plant,Node,Area,Year]  Exogenous Maximum Potential Generation Capacity (MW)
end

function GetPrimaryFuel(data,area,plant)
  (; Area,Fuel,Plant) = data
   
  fuel = Select(Fuel)

  if (Plant[plant] == "OGCC") || (Plant[plant] == "OGCT") || (Plant[plant] == "SmallOGCC") || (Plant[plant] == "NGCCS")
    if (Area[area] == "NL") || (Area[area] == "NL")
      fuel = Select(Fuel,"Diesel")
    else
      fuel = Select(Fuel,"NaturalGas")
    end
  elseif (Plant[plant] == "OGSteam")
    fuel = Select(Fuel,"HFO")
  elseif (Plant[plant] == "Coal") || (Plant[plant] == "CoalCCS")
    fuel = Select(Fuel,"Coal")
  elseif (Plant[plant] == "OtherGeneration")
    fuel = Select(Fuel,"NaturalGas")
  elseif (Plant[plant] == "FuelCell")
    fuel = Select(Fuel,"Hydrogen")
  elseif (Plant[plant] == "Nuclear")
    fuel = Select(Fuel,"Nuclear")
  elseif (Plant[plant] == "BaseHydro") || (Plant[plant] == "PeakHydro") || (Plant[plant] == "SmallHydro")
    fuel = Select(Fuel,"Hydro")
  elseif (Plant[plant] == "Biomass") || (Plant[plant] == "BiomassCCS")
    fuel = Select(Fuel,"Biomass")
  elseif (Plant[plant] == "Biogas") || (Plant[plant] == "Waste")
    fuel = Select(Fuel,"Waste")
  elseif (Plant[plant] == "OnshoreWind") || (Plant[plant] == "OffshoreWind")
    fuel = Select(Fuel,"Wind")
  elseif (Plant[plant] == "SolarPV") || (Plant[plant] == "SolarThermal")
    fuel = Select(Fuel,"Solar")
  elseif (Plant[plant] == "Geothermal")
    fuel = Select(Fuel,"Geothermal")
  elseif (Plant[plant] == "Wave") || (Plant[plant] == "Tidal")
    fuel = Select(Fuel,"Wave")
  end

  return fuel
end


function ElectricConstruction_DtaRun(data,TitleKey,TitleName,areas,gencos,nodes)
  (; Area,AreaDS,ES,ESDS,Fuel,FuelDS,Fuels,FuelEP,FuelEPDS,FuelEPs) = data
  (; GenCo,GenCoDS,Month,MonthDS,Months,Nation,NationDS) = data
  (; Node,NodeDS,Plant,PlantDS,Plants,Poll,PollDS,Polls) = data
  (; Power,PowerDS,Powers,TimeP,TimePs,Year,CDTime,CDYear,SceName) = data
  (; ArNdFr,BFraction,BuildFr,BuildSw,CapCredit,CD,CUCFr,CUCLimit) = data
  (; CUCMlt,CWGA,DesHr,DRM,EUPOCX,ExpPurchases,ExpSales,FlFrNew,FPEU) = data
  (; FPF,GCCC,GCCCM,GCCCN,GCCR,GCDev,GCPA,GCPot,GrMSF,HDEnergy,HDGCCI) = data
  (; HDGCCR,HDHrMn,HDHrPk,HDIPGC,HDPrA,HDPrDP,HDCgGC,HDCUC,HDFGC,HDGC,HDGR) = data
  (; HDPDP,HDRetire,HDRM,HDRQ,HRtM,Inflation,IPExpSw,IPGCCI,IPGCPr) = data
  (; IPGCRM,IPPrDP,MCE,MCELimit,MFC,MoneyUnitDS,MVC,NdArMap,NdNMap,NodeSw) = data
  (; OffValue,ORNew,PCF,PFFrac,PjMax,PjMnPS,PkLoad,Portfolio,PoTRNew) = data
  (; PriceDiff,RnGCCI,RnGen,RnGoal,Subsidy,TPRMap,UFOMC,UOMC,WCC,xGCPot) = data
  
  CDYear = max(CDYear,1)

  iob = IOBuffer()
  
  PkLoadTemp::VariableArray{2} = zeros(Float32,length(Month),length(Year))

  AAA = zeros(Float32,length(Area))
  LLL = zeros(Float32,length(Year))
  SSS = zeros(Float32,length(Year))
  TTT = zeros(Float32,length(Year))
  WWW = zeros(Float32,length(TimeP))
  ZZZ = zeros(Float32,length(Year))

  area_single = first(areas)
  genco_single = first(gencos)
  node_single = first(nodes)

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob,"$TitleName; is the area being output.")
  println(iob,"This is the Electric Construction Inputs and Outputs Summary.")
  println(iob)

  years = collect(Yr(2010):Final)
  println(iob,"Year;",";    ",join(Year[years],";"))
  println(iob)

  if TitleKey == "Summary"

    #
    print(iob,TitleName," Generating Capacity Completion Rate (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(GCCR[plant,node,genco,year] for genco in gencos,node in nodes,plant in Plants)
    end
    print(iob,"GCCR;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(GCCR[plant,node,genco,year] for genco in gencos,node in nodes)
      end
      print(iob,"GCCR;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Generating Capacity Completion Rate (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(GCCR[plant,node,genco,year] for genco in gencos,node in nodes,plant in Plants)
    end
    print(iob,"GCCR;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for node in nodes
      for year in years
        ZZZ[year] = sum(GCCR[plant,node,genco,year] for genco in gencos,plant in Plants)
      end
      print(iob,"GCCR;",NodeDS[node])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Generating Capacity Completion Rate (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(GCCR[plant,node,genco,year] for genco in gencos,node in nodes,plant in Plants)
    end
    print(iob,"GCCR;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for genco in gencos
      for year in years
        ZZZ[year] = sum(GCCR[plant,node,genco,year] for node in nodes,plant in Plants)
      end
      print(iob,"GCCR;",GenCoDS[genco])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

  else

    #
    # Generating Capacity by Plant Type
    #
    print(iob,TitleName," Generating Capacity by Plant Type (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year] for area in areas,plant in Plants)
    end
    print(iob,"GCPA;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(GCPA[plant,area,year] for area in areas)
      end
      print(iob,"GCPA;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Generating Capacity Completion Rate (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(GCCR[plant,node,genco,year] for genco in gencos,node in nodes,plant in Plants)
    end
    print(iob,"GCCR;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(GCCR[plant,node,genco,year] for genco in gencos,node in nodes)
      end
      print(iob,"GCCR;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob,TitleName," Capacity Initiation Rate (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDGCCI[plant,node,genco,area_single,year] for genco in gencos,node in nodes,plant in Plants)
    end
    print(iob,"HDGCCI;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(HDGCCI[plant,node,genco,area_single,year] for genco in gencos,node in nodes)
      end
      print(iob,"HDGCCI;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob,TitleName," Renewable Capacity Initiation Rate (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(RnGCCI[plant,node,genco,area_single,year] for genco in gencos,node in nodes,plant in Plants)
    end
    print(iob,"RnGCCI;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(RnGCCI[plant,node,genco,area_single,year] for genco in gencos,node in nodes)
      end
      print(iob,"RnGCCI;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob,TitleName," Intermittent Power Capacity Initiation Rate (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(IPGCCI[plant,node,genco,area_single,year] for genco in gencos,node in nodes,plant in Plants)
    end
    print(iob,"IPGCCI;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(IPGCCI[plant,node,genco,area_single,year] for genco in gencos,node in nodes)
      end
      print(iob,"IPGCCI;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Indicated Planned Generation Capacity (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for y in years
      ZZZ[y] = sum(HDIPGC[power,node,genco,area,y] for area in areas,genco in gencos,node in nodes,power in Powers)
    end
    print(iob,"HDIPGC;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for power in Powers
      for year in years
        ZZZ[year] = sum(HDIPGC[power,node,genco,area_single,year] for genco in gencos,node in nodes)
      end
      print(iob,"HDIPGC;",PowerDS[power])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Planned Capacity based on Reserve Margin (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(IPGCRM[power,node,genco,area,year] for area in areas,genco in gencos,node in nodes,power in Powers)
    end  
    print(iob,"IPGCRM;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for power in Powers
      for year in years
        ZZZ[year] = sum(IPGCRM[power,node,genco,area_single,year] for genco in gencos,node in nodes)
      end  
      print(iob,"IPGCRM;",PowerDS[power])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Planned Capacity based on Prices (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(IPGCPr[power,node,genco,area,year] for area in areas,genco in gencos,node in nodes,power in Powers)
    end  
    print(iob,"IPGCPr;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for power in Powers
      for year in years
        ZZZ[year] = sum(IPGCPr[power,node,genco,area_single,year] for genco in gencos,node in nodes)
      end
      print(iob,"IPGCPr;",PowerDS[power])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Endogenous Build Fraction (MW/MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for power in Powers
      for year in years
        ZZZ[year] = BFraction[power,node_single,area_single,year]
      end
      print(iob,"BFraction;",PowerDS[power])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Price Differential (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for power in Powers
      for year in years
       ZZZ[year] = PriceDiff[power,node_single,area_single,year]
      end
      print(iob,"PriceDiff",PowerDS[power])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)



    HDPrAV = zeros(Float32,length(Month),length(Node),length(Year))
    PointsMNY = zeros(Float32,length(Month),length(Node),length(Year))
    WeightsMNY = zeros(Float32,length(Month),length(Node),length(Year))

    #
    # HDPrAV(M,N,Y)=sum(TP)(HDPrA(N,TP,M,Y)*HDEnergy(N,TP,M,Y)/sum(TimeP)(HDEnergy(N,TimeP,M,Y)))
    #
    for y in years,month in Months
      PointsMNY[month,node_single,y] = sum(HDPrA[node_single,timep,month,y]*HDEnergy[node_single,timep,month,y] for timep in TimePs)
      WeightsMNY[month,node_single,y] = sum(HDEnergy[node_single,timep,month,y] for timep in TimePs)
      @finite_math HDPrAV[month,node_single,y] = PointsMNY[month,node_single,y] / WeightsMNY[month,node_single,y]
    end

    for month in Months
      print(iob,TitleName," ",MonthDS[month]," Spot Market Marginal Price ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for year in years
        @finite_math ZZZ[year] = HDPrAV[month,node_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"HDPrA;Average")
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      for timep in TimePs
        for year in years
          @finite_math ZZZ[year] = HDPrA[node_single,timep,month,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
        end
        print(iob,"HDPrA;",round(Int,HDHrPk[timep,month]),"--",round(Int,HDHrMn[timep,month]))
        for year in years
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end

    #
    print(iob,TitleName," Decision Price for New Construction ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for power in Powers
      for year in years
        @finite_math ZZZ[year] = HDPrDP[power,node_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"HDPrDP;",PowerDS[power])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Peak Loads
    #
    print(iob,TitleName," Peak Loads (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for month in Months,year in years
      PkLoadTemp[month,year] = sum(PkLoad[month,area,year] for area in areas)
    end
    for y in years
      ZZZ[y] = maximum(PkLoadTemp[month,y] for month in Months)
    end
    LLL[years] = ZZZ[years]
    print(iob,"PkLoad;Annual")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for month in Months
      for year in years
        ZZZ[year] = sum(PkLoad[month,area,year] for area in areas)
      end
      print(iob,"PkLoad;",MonthDS[month])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Reserve Margin
    #
    print(iob,TitleName," Reserve Margin (%);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      SSS[year] = sum(GCPA[plant,area,year] .* CapCredit[plant,area,year] for area in areas,plant in Plants)
      TTT[year] = SSS[year] - LLL[year]
      ZZZ[year] = (TTT[year] / LLL[year])*100
    end
    print(iob,"RMargin;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Build Switch;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = BuildSw[area_single,year]
    end
    print(iob,"BuildSw;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    print(iob,TitleName," Building Fraction;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = BuildFr[area_single,year]
    end
    print(iob,"BuildFr;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Desired Reserve Margin (MW/MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = DRM[node_single,year]
    end
    print(iob,"DRM;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Reserve Margin (MW/MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = HDRM[node_single,year]
    end
    print(iob,"HDRM;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Forecast Firm Generating Capacity (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDFGC[node,year] for node in nodes)
    end
    print(iob,"HDFGC;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Firm Capacity Before New Construction (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDGC[node,year] for node in nodes)
    end
    print(iob,"HDGC;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Firm Capacity under Construction (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDCUC[node,year] for node in nodes)
    end
    print(iob,"HDCUC;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Firm Capacity Being Retired (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDRetire[node,year] for node in nodes)
    end
    print(iob,"HDRetire;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

   #
    print(iob,TitleName," Firm Capacity Being Revised (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"HDGCCR;",TitleName)
    for year in years
      ZZZ[year] = sum(HDGCCR[node,year] for node in nodes)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Firm Cogeneration Capacity Sold to Grid (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDCgGC[node,year] for node in nodes)
    end
    print(iob,"HDCgGC;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Hourly Dispatch Forecasted Generation Requirements;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDRQ[node,year] for node in nodes)
    end
    print(iob,"HDRQ;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Forecasted Peak Growth Rate;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(HDGR[node,year] for node in nodes)
    end
    print(iob,"HDGR;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Capacity Under Construction as Fraction of Capacity (MW/MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(CUCFr[node,year] for node in nodes)
    end
    print(iob,"CUCFr;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Build Decision Capacity Under Construction Limit;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = CUCLimit[year]
    end
    print(iob,"CUCLimit;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Build Decision Capacity Under Construction Constraint;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(CUCMlt[node,year] for node in nodes)
    end
    print(iob,"CUCMlt;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Decision Price for Building Intermittent Power ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = IPPrDP[node_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
    end
    print(iob,"IPPrDP;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Peak (Highest) Load in Interval (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      for y in years
        ZZZ[y] = sum(maximum(HDPDP[node,timep,month,y] for month in Months) for node in nodes)
      end
      print(iob,"HDPDP;",round(Int,HDHrPk[timep,1]),"--",round(Int,HDHrMn[timep,1]))
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    power = Select(Power,"Base")
    print(iob,TitleName," Portfolio Fraction of New Capacity (MW/MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(Portfolio[plant,power,node,area,year] for area in areas,node in nodes,plant in Plants)
    end
    print(iob,"Portfolio;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(Portfolio[plant,power,node,area,year] for area in areas,node in nodes)
      end  
      print(iob,"Portfolio;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Renewable Market Share (MW/MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(GrMSF[plant,node,area_single,year] for node in nodes)
      end
      print(iob,"GrMSf;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Construction Work into Gross Assets ($CDTime ",MoneyUnitDS[area_single],"M);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(CWGA[plant,area_single,year] for plant in Plants) ./ Inflation[area_single,year] * Inflation[area_single,CDYear]
    end
    print(iob,"CWGA;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = CWGA[plant,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"CWGA;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob,TitleName," TimeP to Power Map;")
    for timep in TimePs
      print(iob,";",round(Int,HDHrPk[timep,1]),"--",round(Int,HDHrMn[timep,1]))
    end
    println(iob)
    for power in Powers
      print(iob,"TPRMap;",PowerDS[power])
      for timep in TimePs
        WWW[timep] = TPRMap[timep,power]
        print(iob,";",@sprintf("%15.4f",WWW[timep]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Cost of Energy from New Capacity
    #
    for power in Powers
      print(iob,TitleName," ",PowerDS[power]," Cost of Energy from New Capacity ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for plant in Plants
        for year in years
          ZZZ[year] = MCE[plant,power,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
        end  
        print(iob,"MCE;",PlantDS[plant])
        for year in years
          print(iob,";",@sprintf("%.f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end

    #
    print(iob,TitleName," Marginal Fixed Costs ($CDTime ",MoneyUnitDS[area_single],"/KW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = MFC[plant,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"MFC;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Generation Capacity Capital Costs ($CDTime ",MoneyUnitDS[area_single],"/KW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = GCCC[plant,genco_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end  
      print(iob,"GCCC;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%.1f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Weighted Cost of Capital (1/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = WCC[area_single,year]
    end
    print(iob,"WCC;",TitleName)
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    #
    print(iob,TitleName," Marginal Variable Costs ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = MVC[plant,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"MVC;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Unit Fixed O&M Costs ($CDTime ",MoneyUnitDS[area_single],"/KW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = UFOMC[plant,area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"UFOMC;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Unit Variable O&M Costs ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = UOMC[plant,area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"UOMC;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Fuel Price for Electric Utility ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = FPEU[plant,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"FPEU;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    es = Select(ES,"Electric")
    print(iob,TitleName," Delivered Fuel Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for fuel in Fuels
      for year in years
        ZZZ[year] = FPF[fuel,es,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"FPF;",FuelDS[fuel])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Marginal Heat Rate (Btu/KWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = HRtM[plant,area_single,year]
      end
      print(iob,"HRtM;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    for power in Powers
      print(iob,TitleName," ",PowerDS[power],"Design Hours (Hours);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for plant in Plants
        for year in years
          ZZZ[year]=DesHr[plant,power,area_single,year]
        end
        print(iob,"DesHr;",PlantDS[plant])
        for year in years
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end

    #
    print(iob,TitleName," Plant Capacity Factor;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = PCF[plant,genco_single,year]
      end
      print(iob,"PCF;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Maximum Potential Generation Capacity (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(GCPot[plant,node,area_single,year] for node in nodes)
      end
      print(iob,"GCPot;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Exogenous Maximum Potential Generation Capacity (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(xGCPot[plant,node,area_single,year] for node in nodes)
      end
      print(iob,"xGCPot;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Generation Capacity Developed (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(GCDev[plant,node,area_single,year] for node in nodes)
      end
      print(iob,"GCDev;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Generation Capacity Availiable (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(GCPot[plant,node,area_single,year] - GCDev[plant,node,area_single,year] for node in nodes)
      end
      print(iob,"GCAvail;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Capital Cost Multiplier (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = GCCCM[plant,area_single,year]
      end
      print(iob,"GCCCM;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%.2f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Overnight Construction Costs ($CDTime ",MoneyUnitDS[area_single],"/KW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = GCCCN[plant,area_single,year]*Inflation[area_single,CDYear]
      end
      if sum(ZZZ[y] for y in years) > 0.0
        print(iob,"GCCCN;",PlantDS[plant])
        for year in years
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)

    #
    print(iob,TitleName," Construction Delay (YEARS);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = CD[plant,year]
      end
      print(iob,"CD;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    for plant in Plants
      fuel = GetPrimaryFuel(data,area_single,plant)
      if length(fuel) != length(FuelEPs)
        for fuelep in FuelEPs
          if Fuel[fuel] == FuelEP[fuelep]
            print(iob,TitleName," ",PlantDS[plant]," ",FuelEPDS[fuelep]," Fuel Fraction for New Plants;")
            for year in years
              print(iob,";",Year[year])
            end
            println(iob)
            for year in years
              ZZZ[year] = FlFrNew[fuelep,plant,area_single,year]
            end
            print(iob,"FlFrNew;",PlantDS[plant])
            for year in years
              print(iob,";",@sprintf("%.2f",ZZZ[year]))
            end
            println(iob)
            println(iob)
          end

        end
      end
    end

    for plant in Plants
      fuel = GetPrimaryFuel(data,area_single,plant)
      if length(fuel) != length(FuelEPs)
        for fuelep in FuelEPs
          if Fuel[fuel] == FuelEP[fuelep]
            print(iob,TitleName," ",PlantDS[plant]," ",FuelEPDS[fuelep]," Fuel Usage Fraction (Btu/Btu);")
            for year in years
              print(iob,";",Year[year])
            end
            println(iob)
            for year in years
              ZZZ[year] = PFFrac[fuelep,plant,area_single,year]
            end
            if sum(ZZZ[y] for y in years) > 0.0
              print(iob,"PFFrac;",PlantDS[plant])
              for year in years
                print(iob,";",@sprintf("%.2f",ZZZ[year]))
              end
              println(iob)
            end
            println(iob)
          end
        end
      end
    end

    #
    for plant in Plants
      fuel = GetPrimaryFuel(data,area_single,plant)
      if length(fuel) != length(FuelEPs)
        for fuelep in FuelEPs
          if Fuel[fuel] == FuelEP[fuelep]
            print(iob,TitleName," ",PlantDS[plant]," ",FuelEPDS[fuelep]," Marginal Pollution Coefficients (Tonne/TBtu);")
            for year in years
              print(iob,";",Year[year])
            end
            println(iob)
            for poll in Polls
              for year in years
                ZZZ[year] = EUPOCX[fuelep,plant,poll,area_single,year]
              end
              print(iob,"EUPOCX;",PollDS[poll])
              for year in years
                print(iob,";",@sprintf("%.2f",ZZZ[year]))
              end
              println(iob)
            end
            println(iob)

          end
        end
      end
    end

    #
    print(iob,TitleName," Pollution Tax Rate ($CDTime ",MoneyUnitDS[area_single],"/MWH);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = PoTRNew[plant,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      end
      print(iob,"PoTRNew;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    print(iob,TitleName," Value of Offsets ($CDTime ",MoneyUnitDS[area_single],"/MWH);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = sum(OffValue[plant,poll,area_single,year] for poll in Polls) ./ Inflation[area_single,year] * Inflation[area_single,CDYear]
      end
      print(iob,"OffValue;",PlantDS[plant])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Select Intermittent Power Plant Types
    #
    power = Select(Power,"Base")
    intermittent_Plants = findall(IPExpSw[:,area_single,CDYear] .== 1.0)
    if !isempty(intermittent_Plants)
      print(iob,TitleName," Build Decision Cost of Power Constraint;")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for plant in intermittent_Plants
        for year in years
          ZZZ[year] = min(IPPrDP[node_single,year]/max(MCE[plant,power,area_single,year],0.01)-1,MCELimit[area_single,year])+1
        end
        print(iob,"MCEMlt;",PlantDS[plant])
        for year in years
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end

    #
    println(iob,TitleName," Minimum Plant Size (MW)")
    for plant in Plants
      AAA[areas] = PjMnPS[plant,areas]
      print(iob,"PjMnPS;",PlantDS[plant])
      for aaa in AAA[areas]
        print(iob,";",@sprintf("%20.2f",aaa))
      end
      println(iob)
    end
    println(iob)

    #
    println(iob,TitleName," Maximum Plant Size (MW)    ")
    for plant in Plants
      AAA[areas] = PjMax[plant,areas]
      print(iob,"PjMax;",PlantDS[plant])
      for aaa in AAA[areas]
        print(iob,";",@sprintf("%20.2f",aaa))
      end
      println(iob)
    end
    println(iob)

    #
    println(iob,TitleName," Fuel Type 1")
    for plant in Plants
      fuel = GetPrimaryFuel(data,area_single,plant)
      Temp=" "
      if length(fuel) == 1
        Temp = Fuel[fuel]
      end
      println(iob,"F1New;",PlantDS[plant],";$Temp")
    end
    println(iob)

    #
    println(iob,TitleName," Outage Rate for New Plants (MW/MW)")
    for plant in Plants
      # TODO: Using default TimeP and Month of 1
      AAA[areas] = ORNew[plant,areas,1,1,CDYear]
      print(iob,"ORNew;",PlantDS[plant])
      for aaa in AAA[areas]
        print(iob,";",@sprintf("%15.4f",aaa))
      end
      println(iob)
    end
    println(iob)
  end

  filename = "ElectricConstruction-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end
end

function ElectricConstruction_DtaControl(db)
  @info "ElectricConstruction_DtaControl"
     
  data = ElectricConstructionData(; db)
  Area = data.Area
  AreaDS = data.AreaDS
  Node = data.Node
  NodeDS = data.NodeDS
  NdArMap = data.NdArMap

  # Summary
  areas = Select(AreaDS)
  gencos = areas
  nodes = Select(NodeDS)
  ElectricConstruction_DtaRun(data,"Summary","Summary",areas,gencos,nodes)

  for area in Select(AreaDS,(from ="Ontario",to="Nunavut"))
    areas = area
    gencos = area
    nodes = findall(NdArMap[:,area] .== 1)
    if !isempty(nodes)
      ElectricConstruction_DtaRun(data,Area[area],AreaDS[area],areas,gencos,nodes)
    end
  end

  for node in Select(Node,(from ="TRE",to="BASN"))
    areas = findall(NdArMap[node,:] .> 0)
    gencos = areas
    nodes = node
    if !isempty(areas)
      ElectricConstruction_DtaRun(data,Node[node],NodeDS[node],areas,gencos,nodes)
    end
  end

  for node in Select(Node,"MX")
    areas = Select(Area,"MX")
    gencos = areas
    nodes = node
    ElectricConstruction_DtaRun(data,Node[node],NodeDS[node],areas,gencos,nodes)
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
ElectricConstruction_DtaControl(DB)
end
