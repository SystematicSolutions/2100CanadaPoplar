#
# PlantCharacteristics_SmallOGCC.jl
#
using EnergyModel

module PlantCharacteristics_SmallOGCC

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
  Subsidy::VariableArray{3} = ReadDisk(db,"EGInput/Subsidy") # [Plant,Area,Year] Generating Capacity Subsidy ($/MWh)
  TDInvFr::VariableArray{3} = ReadDisk(db,"EGInput/TDInvFr") # [Plant,Area,Year] Electric Transmission and Distribution Investments Fraction ($/$)
  UnNewNumber::VariableArray{5} = ReadDisk(db,"EGInput/UnNewNumber") # [Plant,Node,GenCo,Area,Year] Unit Number for New Unit
  # UnPointer::VariableArray{5} = ReadDisk(db,"EGInput/UnPointer") # [Plant,Node,GenCo,Area,Year] Unit Pointer

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
  (;Subsidy,TDInvFr,UnNewNumber) = data

  SmallOGCC=Select(Plant,"SmallOGCC")
  OGCC=Select(Plant,"OGCC")
  for year in Years, area in Areas, month in Months, timep in TimePs
    AvFactor[SmallOGCC,timep,month,area,year]=AvFactor[OGCC,timep,month,area,year]
  end
  WriteDisk(db,"EGInput/AvFactor",AvFactor)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    CFStd[fuelep,SmallOGCC,poll,area,year]=CFStd[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/CFStd",CFStd)

  for year in Years, area in Areas, poll in Polls
    CoverNew[SmallOGCC,poll,area,year]=CoverNew[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)

  for year in Years, area in Areas
    DInvFr[SmallOGCC,area,year]=DInvFr[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/DInvFr",DInvFr)

  for year in Years, area in Areas
    DIVTC[SmallOGCC,area,year]=DIVTC[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/DIVTC",DIVTC)

  for year in Years, area in Areas
    DRisk[SmallOGCC,area,year]=DRisk[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/DRisk",DRisk)

  for area in Areas
    EmitNew[SmallOGCC,area]=EmitNew[OGCC,area]
  end
  WriteDisk(db,"EGInput/EmitNew",EmitNew)

  EmitSw[SmallOGCC]=EmitSw[OGCC]
  WriteDisk(db,"EGInput/EmitSw",EmitSw)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUPCostN[fuelep,SmallOGCC,poll,area]=EUPCostN[fuelep,OGCC,poll,area]
  end
  WriteDisk(db,"EGInput/EUPCostN",EUPCostN)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUPVF[fuelep,SmallOGCC,poll,area]=EUPVF[fuelep,OGCC,poll,area]
  end
  WriteDisk(db,"EGInput/EUPVF",EUPVF)

  for year in Years, poll in Polls, fuelep in FuelEPs
    EURCstM[fuelep,SmallOGCC,poll,year]=EURCstM[fuelep,OGCC,poll,year]
  end
  WriteDisk(db,"EGInput/EURCstM",EURCstM)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUROCF[fuelep,SmallOGCC,poll,area]=EUROCF[fuelep,OGCC,poll,area]
  end
  WriteDisk(db,"EGInput/EUROCF",EUROCF)

  for year in Years, area in Areas, poll in Polls
    EURPCSw[SmallOGCC,poll,area,year]=EURPCSw[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/EURPCSw",EURPCSw)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    EUVRP[fuelep,SmallOGCC,poll,area,year]=EUVRP[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/EUVRP",EUVRP)

  for fuelep in FuelEPs
    EUVRRT[fuelep,SmallOGCC]=EUVRRT[fuelep,OGCC]
  end
  WriteDisk(db,"EGInput/EUVRRT",EUVRRT)

  #
  # F1New[SmallOGCC,area]=F1New[OGCC,area]
  # WriteDisk(db,"EGInput/F1New",F1New)
  #

  for year in Years, area in Areas
    FIT[SmallOGCC,area,year]=FIT[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/FIT",FIT)

  for fuel in Fuels
    FlPlnMap[fuel,SmallOGCC]=FlPlnMap[fuel,OGCC]
  end
  WriteDisk(db,"EGInput/FlPlnMap",FlPlnMap)

  for year in Years, area in Areas
    GCCCFlag[SmallOGCC,area,year]=GCCCFlag[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCCCFlag",GCCCFlag)

  for year in Years
    GCDevTime[SmallOGCC,year]=GCDevTime[OGCC,year]
  end
  WriteDisk(db,"EGInput/GCDevTime",GCDevTime)

  for year in Years, area in Areas
    GCExpSw[SmallOGCC,area,year]=GCExpSw[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCExpSw",GCExpSw)

  for year in Years, area in Areas
    GCBL[SmallOGCC,area,year]=GCBL[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCBL",GCBL)

  for year in Years, area in Areas
    GCTL[SmallOGCC,area,year]=GCTL[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/GCTL",GCTL)

  for year in Years, area in Areas, node in Nodes
    GrMSM[SmallOGCC,node,area,year]=GrMSM[OGCC,node,area,year]
  end
  WriteDisk(db,"EGInput/GrMSM",GrMSM)

  for year in Years, timep in TimePs, genco in GenCos
    HDFCFR[SmallOGCC,genco,timep,year]=HDFCFR[OGCC,genco,timep,year]
  end
  WriteDisk(db,"EGInput/HDFCFR",HDFCFR)

  for year in Years, month in Months, timep in TimePs, node in Nodes, genco in GenCos
    HDGCFR[SmallOGCC,genco,node,timep,month,year]=HDGCFR[OGCC,genco,node,timep,month,year]
  end
  WriteDisk(db,"EGInput/HDGCFR",HDGCFR)

  for year in Years, month in Months, timep in TimePs, node in Nodes, genco in GenCos
    HDVCFR[SmallOGCC,genco,node,timep,month,year]=HDVCFR[OGCC,genco,node,timep,month,year]
  end
  WriteDisk(db,"EGInput/HDVCFR",HDVCFR)

  for year in Years, area in Areas, poll in Polls
    MEPOCX[SmallOGCC,poll,area,year]=MEPOCX[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/MEPOCX",MEPOCX)

  for area in Areas
    MRunNew[SmallOGCC,area]=MRunNew[OGCC,area]
  end
  WriteDisk(db,"EGInput/MRunNew",MRunNew)

  for year in Years, area in Areas, poll in Polls
    OffNew[SmallOGCC,poll,area,year]=OffNew[OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/OffNew",OffNew)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    PCostM[fuelep,SmallOGCC,poll,area,year]=PCostM[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/PCostM",PCostM)

  for year in Years, area in Areas, fuelep in FuelEPs
    PFFrac[fuelep,SmallOGCC,area,year]=PFFrac[fuelep,OGCC,area,year]
  end
  WriteDisk(db,"EGInput/PFFrac",PFFrac)

  for area in Areas
    PjMax[SmallOGCC,area]=PjMax[OGCC,area]
  end
  WriteDisk(db,"EGInput/PjMax",PjMax)

  for area in Areas
    PjMnPS[SmallOGCC,area]=PjMnPS[OGCC,area]
  end
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)

  PlantSw[SmallOGCC]=PlantSw[OGCC]
  WriteDisk(db,"EGInput/PlantSw",PlantSw)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    POCX[fuelep,SmallOGCC,poll,area,year]=POCX[fuelep,OGCC,poll,area,year]
  end
  WriteDisk(db,"EGInput/POCX",POCX)

  for year in Years, area in Areas
    PoTRNewExo[SmallOGCC,area,year]=PoTRNewExo[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/PoTRNewExo",PoTRNewExo)

  for year in Years, node in Nodes
    RAvNew[SmallOGCC,node,year]=RAvNew[SmallOGCC,node,year]
  end
  WriteDisk(db,"EGInput/RAvNew",RAvNew)

  for year in Years, area in Areas
    RnBuildFr[SmallOGCC,area,year]=RnBuildFr[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/RnBuildFr",RnBuildFr)

  for year in Years, area in Areas, genco in GenCos, node in Nodes
    RnMSM[SmallOGCC,node,genco,area,year]=RnMSM[OGCC,node,genco,area,year]
  end
  WriteDisk(db,"EGInput/RnMSM",RnMSM)

  for area in Areas
    RnSwitch[SmallOGCC,area]=RnSwitch[OGCC,area]
  end
  WriteDisk(db,"EGInput/RnSwitch",RnSwitch)

  for year in Years, node in Nodes
    RRqNew[SmallOGCC,node,year]=RRqNew[OGCC,node,year]
  end
  WriteDisk(db,"EGInput/RRqNew",RRqNew)

  for year in Years, node in Nodes
    RSwNew[SmallOGCC,node,year]=RSwNew[OGCC,node,year]
  end
  WriteDisk(db,"EGInput/RSwNew",RSwNew)

  for year in Years, area in Areas
    Subsidy[SmallOGCC,area,year]=Subsidy[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/Subsidy",Subsidy)

  for year in Years, area in Areas
    TDInvFr[SmallOGCC,area,year]=TDInvFr[OGCC,area,year]
  end
  WriteDisk(db,"EGInput/TDInvFr",TDInvFr)

  for year in Years, area in Areas, genco in GenCos, node in Nodes
    UnNewNumber[SmallOGCC,node,genco,area,year]=UnNewNumber[OGCC,node,genco,area,year]
  end
  WriteDisk(db,"EGInput/UnNewNumber",UnNewNumber)

end

function CalibrationControl(db)
  @info "PlantCharacteristics_SmallOGCC.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
