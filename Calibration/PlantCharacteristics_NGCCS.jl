#
# PlantCharacteristics_NGCCS.jl
#
# Adjusted SqFr so it is for CO2 only and adjusted HRt as per the
# input from ECD/NRCan. JSLandry; July 13, 2020
# Adjusted Costs and heat rate as per latest AB values
# input from VKeller; Aug 28, 2023
#
using EnergyModel

module PlantCharacteristics_NGCCS

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
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
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  AvFactor::VariableArray{5} = ReadDisk(db,"EGInput/AvFactor") # [Plant,TimeP,Month,Area,Year] Availability Factor (MW/MW)
  CFStd::VariableArray{5} = ReadDisk(db,"EGInput/CFStd") # [FuelEP,Plant,Poll,Area,Year] Clean Fuel Standard (kg/MWh)
  CoverNew::VariableArray{4} = ReadDisk(db,"EGInput/CoverNew") # [Plant,Poll,Area,Year] Fraction of New Plants Covered in Emissions Market (1=100% Covered)
  DInvFr::VariableArray{3} = ReadDisk(db,"EGInput/DInvFr") # [Plant,Area,Year] Device Investments Fraction ($/KW/Yr)
  DIVTC::VariableArray{3} = ReadDisk(db,"EGInput/DIVTC") # [Plant,Area,Year] Device Investment Tax Credit ($/$)
  DRisk::VariableArray{3} = ReadDisk(db,"EGInput/DRisk") # [Plant,Area,Year] Device Risk Premium (DLESS)
  EmitNew::VariableArray{2} = ReadDisk(db,"EGInput/EmitNew") # [Plant,Area] Do New Plants Emit Pollution? (1=Yes)
  EmitSw::VariableArray{1} = ReadDisk(db,"EGInput/EmitSw") # [Plant] Does this Plant Type Emit Pollution (1=Yes)
  EUPCostN::VariableArray{4} = ReadDisk(db,"EGInput/EUPCostN") # [FuelEP,Plant,Poll,Area] Pollution Reduction Cost Normal ($/Tonne)
  EUPVF::VariableArray{4} = ReadDisk(db,"EGInput/EUPVF") # [FuelEP,Plant,Poll,Area] Pollution Reduction Variance Factor (($/Tonne)/($/Tonne))
  EURCstM::VariableArray{4} = ReadDisk(db,"EGInput/EURCstM") # [FuelEP,Plant,Poll,Year] Reduction Cost Technology Multiplier ($/$)
  EUROCF::VariableArray{4} = ReadDisk(db,"EGInput/EUROCF") # [FuelEP,Plant,Poll,Area] Polution Reducution O&M ($/Tonne)
  EURPCSw::VariableArray{4} = ReadDisk(db,"EGInput/EURPCSw") # [Plant,Poll,Area,Year] Pollution Reduction Curve Switch (1=2009, 2=2004)
  EUVRP::VariableArray{5} = ReadDisk(db,"EGInput/EUVRP") # [FuelEP,Plant,Poll,Area,Year] Voluntary Reduction Policy (Tonnes/Tonnes)
  EUVRRT::VariableArray{2} = ReadDisk(db,"EGInput/EUVRRT") # [FuelEP,Plant] Voluntary Reduction response time (Years)
  # F1New::VariableArray{2} = ReadDisk(db,"EGInput/F1New") # [Plant,Area] Fuel Type 1
  FIT::VariableArray{3} = ReadDisk(db,"EGInput/FIT") # [Plant,Area,Year] Feed-In Tariff for Renewable Power (nominal $/MWh)
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") # [Fuel,Plant] Fuel/Plant Map
  GCBL::VariableArray{3} = ReadDisk(db,"EGInput/GCBL") # [Plant,Area,Year] Generation Capacity Book Life (Years)
  GCCCFlag::VariableArray{3} = ReadDisk(db,"EGInput/GCCCFlag") # [Plant,Area,Year] Plant Capital Cost Flag
  #GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
  GCDevTime::VariableArray{2} = ReadDisk(db,"EGInput/GCDevTime") # [Plant,Year] Generation Capacity Development Time (Years)
  GCExpSw::VariableArray{3} = ReadDisk(db,"EGInput/GCExpSw") # [Plant,Area,Year] Generation Capacity Expansion Switch
  GCTL::VariableArray{3} = ReadDisk(db,"EGInput/GCTL") # [Plant,Area,Year] Generation Capacity Tax Life (Years)
  GrMSM::VariableArray{4} = ReadDisk(db,"EGInput/GrMSM") # [Plant,Node,Area,Year] Green Power Market Share Non-Price Factors (MW/MW)
  HDFCFR::VariableArray{4} = ReadDisk(db,"EGInput/HDFCFR") # [Plant,GenCo,TimeP,Year] Fraction of Fixed Costs Bid ($/$)
  HDGCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDGCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Available Generating Capacity in Block (Fraction)
  HDVCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDVCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Variable Costs Bid ($/$)
  MEPOCX::VariableArray{4} = ReadDisk(db,"EGInput/MEPOCX") # [Plant,Poll,Area,Year] Process Emission Coefficients (Tonnes/GWh)
  MRunNew::VariableArray{2} = ReadDisk(db,"EGInput/MRunNew") # [Plant,Area] New Plant Must Run Switch (1=Must Run)
  OffNew::VariableArray{4} = ReadDisk(db,"EGInput/OffNew") # [Plant,Poll,Area,Year] Offset Permits for New Plants (Tonnes/TBtu)
  PCostM::VariableArray{5} = ReadDisk(db,"EGInput/PCostM") # [FuelEP,Plant,Poll,Area,Year] Permit Cost Multiplier ($/Tonne/$/Tonne)
  PFFrac::VariableArray{4} = ReadDisk(db,"EGInput/PFFrac") # [FuelEP,Plant,Area,Year] Fuel Usage Fraction (Btu/Btu)
  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") # [Plant,Area] Maximum Project Size (MW)
  PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") # [Plant,Area] Minimum Project Size (MW)
  PlantSw::VariableArray{1} = ReadDisk(db,"EGInput/PlantSw") # [Plant] Iteration when this Plant Type begins to be calibrated
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  PoTRNewExo::VariableArray{3} = ReadDisk(db,"EGInput/PoTRNewExo") # [Plant,Area,Year] Exogenous Emission Cost for New Plants (Real $/MWH)
  RAvNew::VariableArray{3} = ReadDisk(db,"EGInput/RAvNew") # [Plant,Node,Year] Reserve Availability (MW/MW)
  RnBuildFr::VariableArray{3} = ReadDisk(db,"EGInput/RnBuildFr") # [Plant,Area,Year] Build Fraction for Renewable Capacity as Fraction of Area (MW/MW)
  RnMSM::VariableArray{5} = ReadDisk(db,"EGInput/RnMSM") # [Plant,Node,GenCo,Area,Year] Renewable Market Share Non-Price Factors (GWh/GWh)
  RnSwitch::VariableArray{2} = ReadDisk(db,"EGInput/RnSwitch") # [Plant,Area] Renewable Plant Type Switch (1=Renewable)
  RRqNew::VariableArray{3} = ReadDisk(db,"EGInput/RRqNew") # [Plant,Node,Year] Reserve Requirements (MW/MW)
  RSwNew::VariableArray{3} = ReadDisk(db,"EGInput/RSwNew") # [Plant,Node,Year] Reserve Availability Switch (MW/MW)
  SqFr::VariableArray{4} = ReadDisk(db,"EGInput/SqFr") # [Plant,Poll,Area,Year] Sequestered Pollution Fraction (Tonne/Tonne)
  Subsidy::VariableArray{3} = ReadDisk(db,"EGInput/Subsidy") # [Plant,Area,Year] Generating Capacity Subsidy ($/MWh)
  TDInvFr::VariableArray{3} = ReadDisk(db,"EGInput/TDInvFr") # [Plant,Area,Year] Electric Transmission and Distribution Investments Fraction ($/$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Areas,FuelEPs,Fuels) = data
  (;GenCos,Months,Nodes,Plant) = data
  (;Polls,Powers,TimePs) = data
  (;Years) = data
  (;AvFactor,CFStd,CoverNew,DInvFr,DIVTC,DRisk,EmitNew) = data
  (;EmitSw,EUPCostN,EUPVF,EURCstM,EUROCF,EURPCSw,EUVRP,EUVRRT,FIT) = data
  (;FlPlnMap,GCBL,GCCCFlag,GCDevTime,GCExpSw,GCTL,GrMSM,HDFCFR) = data
  (;HDGCFR,HDVCFR,MEPOCX,MRunNew,OffNew,PCostM,PFFrac,PjMax) = data
  (;PjMnPS,PlantSw,POCX,PoTRNewExo,RAvNew,RnBuildFr,RnMSM,RnSwitch,RRqNew,RSwNew) = data
  (;SqFr,Subsidy,TDInvFr,xInflation) = data

  #
  # For Natural Gas with CCS, here are the parameters we want to use:
  #
  #       GCCN (2022 CN $/kW) : 3554.00
  #       UOMC (2022 CN $/kWh) : 8.63
  #       UFOMC (2022 CN $/kWh) : 39.53
  #       CD (Years) : 2
  #       HRt (TBtu/kWh): 7127
  #       OR : 0.1
  #       SqFr : 0.9 (for CO2)
  #
  ########################
  #

  NGCCS=Select(Plant,"NGCCS")
  OGCC=Select(Plant,"OGCC")
  for year in Years, area in Areas, month in Months, timep in TimePs
    AvFactor[NGCCS,timep,month,area,year]=AvFactor[OGCC,timep,month,area,year]
  end
  WriteDisk(db,"EGInput/AvFactor",AvFactor)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    CFStd[fuelep,NGCCS,poll,area,year]=CFStd[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/CFStd",CFStd)

  for year in Years, area in Areas, poll in Polls
    CoverNew[NGCCS,poll,area,year]=CoverNew[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)

  for year in Years, area in Areas
    DInvFr[NGCCS,area,year]=DInvFr[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/DInvFr",DInvFr)

  for year in Years, area in Areas
    DIVTC[NGCCS,area,year]=DIVTC[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/DIVTC",DIVTC)

  for year in Years, area in Areas
    DRisk[NGCCS,area,year]=DRisk[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/DRisk",DRisk)

  for area in Areas
    EmitNew[NGCCS,area]=EmitNew[OGCC,area]
  end
  WriteDisk(db,"EGInput/EmitNew",EmitNew)

  EmitSw[NGCCS]=EmitSw[OGCC]
  WriteDisk(db,"EGInput/EmitSw",EmitSw)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUPCostN[fuelep,NGCCS,poll,area]=EUPCostN[fuelep,OGCC,poll,area]
  end
  WriteDisk(db,"EGInput/EUPCostN",EUPCostN)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUPVF[fuelep,NGCCS,poll,area]=EUPVF[fuelep,OGCC,poll,area]
  end
  WriteDisk(db,"EGInput/EUPVF",EUPVF)

  for year in Years, poll in Polls, fuelep in FuelEPs
    EURCstM[fuelep,NGCCS,poll,year]=EURCstM[fuelep,OGCC,poll,year]
  end
  WriteDisk(db,"EGInput/EURCstM",EURCstM)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUROCF[fuelep,NGCCS,poll,area]=EUROCF[fuelep,OGCC,poll,area]
  end
  WriteDisk(db,"EGInput/EUROCF",EUROCF)

  for year in Years, area in Areas, poll in Polls
    EURPCSw[NGCCS,poll,area,year]=EURPCSw[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/EURPCSw",EURPCSw)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    EUVRP[fuelep,NGCCS,poll,area,year]=EUVRP[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/EUVRP",EUVRP)

  for fuelep in FuelEPs
    EUVRRT[fuelep,NGCCS]=EUVRRT[fuelep,OGCC]
  end
  WriteDisk(db,"EGInput/EUVRRT",EUVRRT)

  #
  # F1New[NGCCS,area]=F1New[OGCC,area]
  # WriteDisk(db,"EGInput/F1New",F1New)
  #

  for year in Years, area in Areas
    FIT[NGCCS,area,year]=FIT[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/FIT",FIT)

  for fuel in Fuels
    FlPlnMap[fuel,NGCCS]=FlPlnMap[fuel,OGCC]
  end
  WriteDisk(db,"EGInput/FlPlnMap",FlPlnMap)

  for year in Years, area in Areas
    GCCCFlag[NGCCS,area,year]=GCCCFlag[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCCCFlag",GCCCFlag)

  # years=collect(Yr(2020):Final)
  # for year in years, area in Areas
  #   GCCCN[NGCCS,area,year]=99999
  # end
  # for area in Areas
  #   GCCCN[NGCCS,area,Yr(2026)]=2817.10/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2027)]=2760.70/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2028)]=2704.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2029)]=2647.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2030)]=2591.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2031)]=2534.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2032)]=2478.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2033)]=2422.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2034)]=2365.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2035)]=2309.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2036)]=2282.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2037)]=2256.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2038)]=2230.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2039)]=2203.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2040)]=2177.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2041)]=2150.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2042)]=2124.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2043)]=2098.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2044)]=2071.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2045)]=2045.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2046)]=2017.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2047)]=1992.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2048)]=1966.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2049)]=1939.50/xInflation[area,Yr(2019)]
  #   GCCCN[NGCCS,area,Yr(2050)]=1913.50/xInflation[area,Yr(2019)]
  # end
  #
  # WriteDisk(db,"EGInput/GCCCN",GCCCN)

  for year in Years
    GCDevTime[NGCCS,year]=GCDevTime[OGCC,year]
  end
  WriteDisk(db,"EGInput/GCDevTime",GCDevTime)

  for year in Years, area in Areas
    GCExpSw[NGCCS,area,year]=GCExpSw[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCExpSw",GCExpSw)

  for year in Years, area in Areas
    GCBL[NGCCS,area,year]=GCBL[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCBL",GCBL)

  for year in Years, area in Areas
    GCTL[NGCCS,area,year]=GCTL[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCTL",GCTL)

  for year in Years, area in Areas, node in Nodes
    GrMSM[NGCCS,node,area,year]=GrMSM[OGCC,node,area,year]
  end
  WriteDisk(db,"EGInput/GrMSM",GrMSM)

  for year in Years, timep in TimePs, genco in GenCos
    HDFCFR[NGCCS,genco,timep,year]=HDFCFR[OGCC,genco,timep,year]
  end
  WriteDisk(db,"EGInput/HDFCFR",HDFCFR)

  for year in Years, month in Months, timep in TimePs, node in Nodes, genco in GenCos
    HDGCFR[NGCCS,genco,node,timep,month,year]=HDGCFR[OGCC,genco,node,timep,month,year]
  end
  WriteDisk(db,"EGInput/HDGCFR",HDGCFR)

  for year in Years, month in Months, timep in TimePs, node in Nodes, genco in GenCos
    HDVCFR[NGCCS,genco,node,timep,month,year]=HDVCFR[OGCC,genco,node,timep,month,year]
  end
  WriteDisk(db,"EGInput/HDVCFR",HDVCFR)

  for year in Years, area in Areas, poll in Polls
    MEPOCX[NGCCS,poll,area,year]=MEPOCX[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/MEPOCX",MEPOCX)

  for area in Areas
    MRunNew[NGCCS,area]=MRunNew[OGCC,area]
  end
  WriteDisk(db,"EGInput/MRunNew",MRunNew)

  for year in Years, area in Areas, poll in Polls
    OffNew[NGCCS,poll,area,year]=OffNew[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/OffNew",OffNew)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    PCostM[fuelep,NGCCS,poll,area,year]=PCostM[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/PCostM",PCostM)

  for year in Years, area in Areas, fuelep in FuelEPs
    PFFrac[fuelep,NGCCS,area,year]=PFFrac[fuelep,OGCC,area,year]
  end
  WriteDisk(db,"EGInput/PFFrac",PFFrac)

  for area in Areas
    PjMax[NGCCS,area]=PjMax[OGCC,area]
  end
  WriteDisk(db,"EGInput/PjMax",PjMax)

  #########JSO Change#########
  for area in Areas
    PjMnPS[NGCCS,area]=1
  end
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)

  PlantSw[NGCCS]=PlantSw[OGCC]
  WriteDisk(db,"EGInput/PlantSw",PlantSw)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    POCX[fuelep,NGCCS,poll,area,year]=POCX[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/POCX",POCX)

  for year in Years, area in Areas
    PoTRNewExo[NGCCS,area,year]=PoTRNewExo[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/PoTRNewExo",PoTRNewExo)

  for year in Years, node in Nodes
    RAvNew[NGCCS,node,year]=RAvNew[NGCCS,node,year]
  end
  WriteDisk(db,"EGInput/RAvNew",RAvNew)

  for year in Years, area in Areas
    RnBuildFr[NGCCS,area,year]=RnBuildFr[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/RnBuildFr",RnBuildFr)

  for year in Years, area in Areas, genco in GenCos, node in Nodes
    RnMSM[NGCCS,node,genco,area,year]=RnMSM[OGCC,node,genco,area,year]
  end
  WriteDisk(db,"EGInput/RnMSM",RnMSM)

  for area in Areas
    RnSwitch[NGCCS,area]=RnSwitch[OGCC,area]
  end
  WriteDisk(db,"EGInput/RnSwitch",RnSwitch)

  for year in Years, node in Nodes
    RRqNew[NGCCS,node,year]=RRqNew[OGCC,node,year]
  end
  WriteDisk(db,"EGInput/RRqNew",RRqNew)

  for year in Years, node in Nodes
    RSwNew[NGCCS,node,year]=RSwNew[OGCC,node,year]
  end
  WriteDisk(db,"EGInput/RSwNew",RSwNew)

  #
  #########JSO Change#########
  # Modified so it applies to CO2 only. JSLandry; July 13, 2020
  # Modified to 95% capture rate. JSO; October 2022
  # *SqFr(NGCCS,CO2,Area,Y)=0.95
  # *SqFr(NGCCS,Poll,Area,Y)=0.90
  #
  #########JSO Change#########
  # Modified so it applies to CO2 only. VKeller; Aug 28, 2023
  # *SqFr(NGCCS,CO2,Area,Y)=0.95
  #
  for year in Years, area in Areas, poll in Polls
    SqFr[NGCCS,poll,area,year]=0.90
  end
  WriteDisk(db,"EGInput/SqFr",SqFr)

  for year in Years, area in Areas
    Subsidy[NGCCS,area,year]=Subsidy[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/Subsidy",Subsidy)

  for year in Years, area in Areas
    TDInvFr[NGCCS,area,year]=TDInvFr[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/TDInvFr",TDInvFr)

end

function CalibrationControl(db)
  @info "PlantCharacteristics_NGCCS.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
