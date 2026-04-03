#
# PlantCharacteristics_BiomassCCS.jl
#
# All values equal to Biomass except:
#  POCX - emission factor supplied for CO2 so we have something to capture
#  SqFr - sequestering fraction set at 90%
# These should be reviewed - Jeff Amlin March 29, 2021
#
using EnergyModel

module PlantCharacteristics_BiomassCCS

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
  GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
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
  (;Poll,Polls,Powers,TimePs) = data
  (;Years) = data
  (;AvFactor,CFStd,CoverNew,DInvFr,DIVTC,DRisk,EmitNew) = data
  (;EmitSw,EUPCostN,EUPVF,EURCstM,EUROCF,EURPCSw,EUVRP,EUVRRT,FIT) = data
  (;FlPlnMap,GCBL,GCCCFlag,GCCCN,GCDevTime,GCExpSw,GCTL,GrMSM,HDFCFR) = data
  (;HDGCFR,HDVCFR,MEPOCX,MRunNew,OffNew,PCostM,PFFrac,PjMax) = data
  (;PjMnPS,PlantSw,POCX,PoTRNewExo,RAvNew,RnBuildFr,RnMSM,RnSwitch,RRqNew,RSwNew) = data
  (;SqFr,Subsidy,TDInvFr,xInflation) = data


  BiomassCCS=Select(Plant,"BiomassCCS")
  Biomass=Select(Plant,"Biomass")
  for year in Years, area in Areas, month in Months, timep in TimePs
    AvFactor[BiomassCCS,timep,month,area,year]=AvFactor[Biomass,timep,month,area,year]
  end
  WriteDisk(db,"EGInput/AvFactor",AvFactor)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    CFStd[fuelep,BiomassCCS,poll,area,year]=CFStd[fuelep,Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/CFStd",CFStd)

  for year in Years, area in Areas, poll in Polls
    CoverNew[BiomassCCS,poll,area,year]=CoverNew[Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)

  for year in Years, area in Areas
    DInvFr[BiomassCCS,area,year]=DInvFr[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/DInvFr",DInvFr)

  for year in Years, area in Areas
    DIVTC[BiomassCCS,area,year]=DIVTC[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/DIVTC",DIVTC)

  for year in Years, area in Areas
    DRisk[BiomassCCS,area,year]=DRisk[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/DRisk",DRisk)

  for area in Areas
    EmitNew[BiomassCCS,area]=EmitNew[Biomass,area]
  end
  WriteDisk(db,"EGInput/EmitNew",EmitNew)

  EmitSw[BiomassCCS]=EmitSw[Biomass]
  WriteDisk(db,"EGInput/EmitSw",EmitSw)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUPCostN[fuelep,BiomassCCS,poll,area]=EUPCostN[fuelep,Biomass,poll,area]
  end
  WriteDisk(db,"EGInput/EUPCostN",EUPCostN)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUPVF[fuelep,BiomassCCS,poll,area]=EUPVF[fuelep,Biomass,poll,area]
  end
  WriteDisk(db,"EGInput/EUPVF",EUPVF)

  for year in Years, poll in Polls, fuelep in FuelEPs
    EURCstM[fuelep,BiomassCCS,poll,year]=EURCstM[fuelep,Biomass,poll,year]
  end
  WriteDisk(db,"EGInput/EURCstM",EURCstM)

  for area in Areas, poll in Polls, fuelep in FuelEPs
    EUROCF[fuelep,BiomassCCS,poll,area]=EUROCF[fuelep,Biomass,poll,area]
  end
  WriteDisk(db,"EGInput/EUROCF",EUROCF)

  for year in Years, area in Areas, poll in Polls
    EURPCSw[BiomassCCS,poll,area,year]=EURPCSw[Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/EURPCSw",EURPCSw)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    EUVRP[fuelep,BiomassCCS,poll,area,year]=EUVRP[fuelep,Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/EUVRP",EUVRP)

  for fuelep in FuelEPs
    EUVRRT[fuelep,BiomassCCS]=EUVRRT[fuelep,Biomass]
  end
  WriteDisk(db,"EGInput/EUVRRT",EUVRRT)

  #
  # F1New[BiomassCCS,area]=F1New[Biomass,area]
  # WriteDisk(db,"EGInput/F1New",F1New)
  #

  for year in Years, area in Areas
    FIT[BiomassCCS,area,year]=FIT[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/FIT",FIT)

  for fuel in Fuels
    FlPlnMap[fuel,BiomassCCS]=FlPlnMap[fuel,Biomass]
  end
  WriteDisk(db,"EGInput/FlPlnMap",FlPlnMap)

  for year in Years, area in Areas
    GCCCFlag[BiomassCCS,area,year]=GCCCFlag[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/GCCCFlag",GCCCFlag)

  #
  # Source: Email "ECCC - Emission Intensity for Biomass CCS"
  # From: John St-LaurentOConnor, Tuesday, May 4, 2021 5:15 PM
  # Overnight Capital Costs - ($2020/MW)    9,385,453
  #
  # for year in Years, area in Areas
  #   GCCCN[BiomassCCS,area,year]=9385453/1000/xInflation[area,Yr(2020)]
  # end
  # WriteDisk(db,"EGInput/GCCCN",GCCCN)

  for year in Years
    GCDevTime[BiomassCCS,year]=GCDevTime[Biomass,year]
  end
  WriteDisk(db,"EGInput/GCDevTime",GCDevTime)

  for year in Years, area in Areas
    GCExpSw[BiomassCCS,area,year]=GCExpSw[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/GCExpSw",GCExpSw)

  for year in Years, area in Areas
    GCBL[BiomassCCS,area,year]=GCBL[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/GCBL",GCBL)

  for year in Years, area in Areas
    GCTL[BiomassCCS,area,year]=GCTL[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/GCTL",GCTL)

  for year in Years, area in Areas, node in Nodes
    GrMSM[BiomassCCS,node,area,year]=GrMSM[Biomass,node,area,year]
  end
  WriteDisk(db,"EGInput/GrMSM",GrMSM)

  for year in Years, timep in TimePs, genco in GenCos
    HDFCFR[BiomassCCS,genco,timep,year]=HDFCFR[Biomass,genco,timep,year]
  end
  WriteDisk(db,"EGInput/HDFCFR",HDFCFR)

  for year in Years, month in Months, timep in TimePs, node in Nodes, genco in GenCos
    HDGCFR[BiomassCCS,genco,node,timep,month,year]=HDGCFR[Biomass,genco,node,timep,month,year]
  end
  WriteDisk(db,"EGInput/HDGCFR",HDGCFR)

  for year in Years, month in Months, timep in TimePs, node in Nodes, genco in GenCos
    HDVCFR[BiomassCCS,genco,node,timep,month,year]=HDVCFR[Biomass,genco,node,timep,month,year]
  end
  WriteDisk(db,"EGInput/HDVCFR",HDVCFR)

  for year in Years, area in Areas, poll in Polls
    MEPOCX[BiomassCCS,poll,area,year]=MEPOCX[Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/MEPOCX",MEPOCX)

  for area in Areas
    MRunNew[BiomassCCS,area]=MRunNew[Biomass,area]
  end
  WriteDisk(db,"EGInput/MRunNew",MRunNew)

  for year in Years, area in Areas, poll in Polls
    OffNew[BiomassCCS,poll,area,year]=OffNew[Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/OffNew",OffNew)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    PCostM[fuelep,BiomassCCS,poll,area,year]=PCostM[fuelep,Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/PCostM",PCostM)

  for year in Years, area in Areas, fuelep in FuelEPs
    PFFrac[fuelep,BiomassCCS,area,year]=PFFrac[fuelep,Biomass,area,year]
  end
  WriteDisk(db,"EGInput/PFFrac",PFFrac)

  for area in Areas
    PjMax[BiomassCCS,area]=PjMax[Biomass,area]
  end
  WriteDisk(db,"EGInput/PjMax",PjMax)

  for area in Areas
    PjMnPS[BiomassCCS,area]=PjMnPS[Biomass,area]
  end
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)

  PlantSw[BiomassCCS]=PlantSw[Biomass]
  WriteDisk(db,"EGInput/PlantSw",PlantSw)

  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    POCX[fuelep,BiomassCCS,poll,area,year]=POCX[fuelep,Biomass,poll,area,year]
  end
  WriteDisk(db,"EGInput/POCX",POCX)

  for year in Years, area in Areas
    PoTRNewExo[BiomassCCS,area,year]=PoTRNewExo[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/PoTRNewExo",PoTRNewExo)

  for year in Years, node in Nodes
    RAvNew[BiomassCCS,node,year]=RAvNew[BiomassCCS,node,year]
  end
  WriteDisk(db,"EGInput/RAvNew",RAvNew)

  for year in Years, area in Areas
    RnBuildFr[BiomassCCS,area,year]=RnBuildFr[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/RnBuildFr",RnBuildFr)

  for year in Years, area in Areas, genco in GenCos, node in Nodes
    RnMSM[BiomassCCS,node,genco,area,year]=RnMSM[Biomass,node,genco,area,year]
  end
  WriteDisk(db,"EGInput/RnMSM",RnMSM)

  for area in Areas
    RnSwitch[BiomassCCS,area]=RnSwitch[Biomass,area]
  end
  WriteDisk(db,"EGInput/RnSwitch",RnSwitch)

  for year in Years, node in Nodes
    RRqNew[BiomassCCS,node,year]=RRqNew[Biomass,node,year]
  end
  WriteDisk(db,"EGInput/RRqNew",RRqNew)

  for year in Years, node in Nodes
    RSwNew[BiomassCCS,node,year]=RSwNew[Biomass,node,year]
  end
  WriteDisk(db,"EGInput/RSwNew",RSwNew)

  #
  # Source: Email "ECCC - Emission Intensity for Biomass CCS"
  # From: John St-LaurentOConnor, Tuesday, May 4, 2021 5:15 PM
  # Sequestration Fraction for CO2        0.90
  #
  CO2=Select(Poll,"CO2")
  for year in Years, area in Areas
    SqFr[BiomassCCS,CO2,area,year]=0.90
  end
  WriteDisk(db,"EGInput/SqFr",SqFr)

  for year in Years, area in Areas
    Subsidy[BiomassCCS,area,year]=Subsidy[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/Subsidy",Subsidy)

  for year in Years, area in Areas
    TDInvFr[BiomassCCS,area,year]=TDInvFr[Biomass,area,year]
  end
  WriteDisk(db,"EGInput/TDInvFr",TDInvFr)

end

function CalibrationControl(db)
  @info "PlantCharacteristics_BiomassCCS.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
