#
# EGData.jl
#
using EnergyModel

module EGData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoKey::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Horizon::SetArray = ReadDisk(db,"EGInput/HorizonKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeX")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))  
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  AwardSwitch::VariableArray{2} = ReadDisk(db,"EGInput/AwardSwitch") #[Area,Year]  New Capacity Award Switch (1=Cost,2=Portfolio)
  FIT::VariableArray{3} = ReadDisk(db,"EGInput/FIT") # [Plant,Area,Year] Feed-In Tariff for Renewable Power (nominal $/MWh)
  NodeSw::VariableArray{1} = ReadDisk(db,"EGInput/NodeSw") # [Node] Switch to indicate if Node is Active (1=Active)
  NodeXSw::VariableArray{1} = ReadDisk(db,"EGInput/NodeXSw") # [NodeX] Switch to indicate if NodeX is Active (1=Active)
  PlantSw::VariableArray{1} = ReadDisk(db,"EGInput/PlantSw") # [Plant] Iteration when this Plant Type begins to be calibrated
  EURPCSw::VariableArray{4} = ReadDisk(db,"EGInput/EURPCSw") # [Plant,Poll,Area,Year] Pollution Reduction Curve Switch (1=2009, 2=2004)
  RnBuildFr::VariableArray{3} = ReadDisk(db,"EGInput/RnBuildFr") # [Plant,Area,Year] Build Fraction for Renewable Capacity as Fraction of Area (MW/MW)
  RnOption::VariableArray{2} = ReadDisk(db,"EGInput/RnOption") # [Area,Year] Renewable  (1=Local RPS, 2=Regional RPS, 3=FIT)
  TPRMap::VariableArray{2} = ReadDisk(db,"EGInput/TPRMap") # [TimeP,Power] TimeP to Power Map
  AFCM::VariableArray{2} = ReadDisk(db,"EGInput/AFCM") # [GenCo,Year] Average Fixed Cost Multiplier (Dless)
  AvFactor::VariableArray{5} = ReadDisk(db,"EGInput/AvFactor") # [Plant,TimeP,Month,Area,Year] Availability Factor (MW/MW)
  BFracMax::VariableArray{2} = ReadDisk(db,"EGInput/BFracMax") # [Area,Year] Maximum Fraction of Capacity Built Endogenously (MW/MW)
  BsBdFr::VariableArray{3} = ReadDisk(db, "EGInput/BsBdFr") # [Power,Area,Year] Base Build Fraction (Fraction)
  BuildSw::VariableArray{2} = ReadDisk(db,"EGInput/BuildSw") # [Area,Year] Build switch 
  BuildFr::VariableArray{2} = ReadDisk(db,"EGInput/BuildFr") #[Area,Year]  Building fraction
  CapCredit::VariableArray{3} = ReadDisk(db,"EGInput/CapCredit") # [Plant,Area,Year] Capacity Credit (MW/MW)
  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (Years)
  CUCLimit::VariableArray{1} = ReadDisk(db,"EGInput/CUCLimit") # [Year] Build Decision Capacity Under Construction Limit (MW/MW)
  ECFPAdder::VariableArray{4} = ReadDisk(db,"EGInput/ECFPAdder") #[FuelEP,Month,Area,Year]  Monthly Fuel Price Adder ($/mmBtu)
  ECFPMinMult::VariableArray{1} = ReadDisk(db,"EGInput/ECFPMinMult") #[Year]  Minimum Monthly Fuel Price Multiplier ($/mmBtu)
  EmitNew::VariableArray{2} = ReadDisk(db,"EGInput/EmitNew") # [Plant,Area] Do New Plants Emit Pollution? (1=Yes)
  FlFrTime::VariableArray{4} = ReadDisk(db,"EGInput/FlFrTime") # [FuelEP,Plant,Area,Year] Fuel Adjustment Time (Years)  
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") # [Fuel,Plant] Fuel/Plant Map
  GCCCFlag::VariableArray{3} = ReadDisk(db,"EGInput/GCCCFlag") # [Plant,Area,Year] Plant Capital Cost Flag
  GCDevTime::VariableArray{2} = ReadDisk(db,"EGInput/GCDevTime") # [Plant,Year] Generation Capacity Development Time (Years)
  GCExpSw::VariableArray{3} = ReadDisk(db,"EGInput/GCExpSw") # [Plant,Area,Year] Generation Capacity Expansion Switch
  GCBL::VariableArray{3} = ReadDisk(db,"EGInput/GCBL") # [Plant,Area,Year] Generation Capacity Book Life (Years)
  GCTL::VariableArray{3} = ReadDisk(db,"EGInput/GCTL") # [Plant,Area,Year] Generation Capacity Tax Life (Years)
  # xGCPot::VariableArray{4} = ReadDisk(db,"EGInput/xGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
  GrMSM::VariableArray{4} = ReadDisk(db,"EGInput/GrMSM") # [Plant,Node,Area,Year] Green Power Market Share Non-Price Factors (MW/MW)
  GrVF::VariableArray{1} = ReadDisk(db,"EGInput/GrVF") # [Year] Green Power Market Share Variance Factor (MW/MW)
  HDFCFR::VariableArray{4} = ReadDisk(db,"EGInput/HDFCFR") # [Plant,GenCo,TimeP,Year] Fraction of Fixed Costs Bid ($/$)
  HDGCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDGCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Available Generating Capacity in Block (Fraction)
  HDVCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDVCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Variable Costs Bid ($/$)
  IPExpSw::VariableArray{3} = ReadDisk(db,"EGInput/IPExpSw") #[Plant,Area,Year]  Intermittent Power Capacity Expansion Switch (1=Build)
  IPTPMap::VariableArray{2} = ReadDisk(db,"EGInput/IPTPMap") #[TimeP,Area]  Intermittent Power Price Time Period Map (1=use TimeP)
  LLEff::VariableArray{3} = ReadDisk(db,"EGInput/LLEff") #[Node,NodeX,Year]  Transmission Line Efficiency (MW/MW)
  xLLVC::VariableArray{3} = ReadDisk(db,"EGInput/xLLVC") # [Node,NodeX,Year] Transmission rate (Real US$/MWh)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  MCELimit::VariableArray{2} = ReadDisk(db,"EGInput/MCELimit") #[Area,Year]  Build Decision Cost of Power Limit
  MRunNew::VariableArray{2} = ReadDisk(db,"EGInput/MRunNew") # [Plant,Area] New Plant Must Run Switch (1=Must Run)
  OGCCFraction::VariableArray{2} = ReadDisk(db,"EGInput/OGCCFraction") # [Area,Year] Fraction of new OG capacity which is OGCC (MW/MW)
  OGCCSmallFraction::VariableArray{2} = ReadDisk(db,"EGInput/OGCCSmallFraction") # [Area,Year] Fraction of new OGCC capacity which is Small (MW/MW)
  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") # [Plant,Area] Maximum Project Size (MW)
  PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") # [Plant,Area] Minimum Project Size (MW)
  PjNSw::VariableArray{4} = ReadDisk(db,"EGInput/PjNSw") # [Node,GenCo,Area,Year] Project Selection Node Switch (1=Build)
  PkHydSw::VariableArray{1} = ReadDisk(db,"EGInput/PkHydSw") #[Year]  Switch for Allocation Method for Peak Hydro (1=new method)
  PolSw::VariableArray{2} = ReadDisk(db,"EGInput/PolSw") # [Poll,Area] Switch to Execute Pollution Procedure
  PrDiFr::VariableArray{3} = ReadDisk(db,"EGInput/PrDiFr") # [Power,Area,Year] Price Differential Fraction (Fraction)
  RnFr::VariableArray{2} = ReadDisk(db,"EGInput/RnFr") # [Area,Year] Renewable Fraction (GWh/GWh)
  RnMSM::VariableArray{5} = ReadDisk(db,"EGInput/RnMSM") # [Plant,Node,GenCo,Area,Year] Renewable Market Share Non-Price Factors (GWh/GWh)
  RnSwitch::VariableArray{2} = ReadDisk(db,"EGInput/RnSwitch") # [Plant,Area] Renewable Plant Type Switch (1=Renewable)
  RnVF::VariableArray{2} = ReadDisk(db,"EGInput/RnVF") # [Area,Year] Renewable Market Share Variance Factor ($/$)
  StorageEfficiency::VariableArray{3} = ReadDisk(db,"EGInput/StorageEfficiency") # [Plant,Area,Year] Storage Efficiency (GWh/GWh)
  StorageSwitch::VariableArray{1} = ReadDisk(db,"EGInput/StorageSwitch") #[Plant]  Storage Technology Switch (1=Storage)
  TaxR::VariableArray{2} = ReadDisk(db,"EGInput/TaxR") #[Area,Year]  Income Tax Rate ($/$)
  USMT::VariableArray{1} = ReadDisk(db,"EGInput/USMT") #[Horizon]  Smoothing Time (Year)
  WCC::VariableArray{2} = ReadDisk(db,"EGInput/WCC") #[Area,Year]  Weighted Cost of Capital ($/($/Yr))
  # #  *xOILFR(GenCo,Year)    'Fraction of Oil/Gas which is Oil (FRAC.)', Type=Real(8,2),Disk(EGInput,xOILFR(GenCo,Year))
  BlkSw::VariableArray{2} = ReadDisk(db,"EGInput/BlkSw") #[Area,Year]  Block switch
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") # [Year] Number of Units
  xEMGVCost::VariableArray{2} = ReadDisk(db,"EGInput/xEMGVCost") # [Node,Year] Dispatch Price for Emergency Power ($/MWh)
  xUnEGC::VariableArray{4} = ReadDisk(db,"EGInput/xUnEGC") #[Unit,TimeP,Month,Year]  Exogenous Effective Generating Capacity (MW)
  ESTime::VariableArray{1} = ReadDisk(db,"EGInput/ESTime") # [Area] Starting Year for Simulation
  xEURM::VariableArray{5} = ReadDisk(db,"EGInput/xEURM") # [FuelEP,Plant,Poll,Area,Year] Exogenous Reduction Multiplier by Area (Tonnes/Tonnes)
  EUCCR::VariableArray{2} = ReadDisk(db,"EGInput/EUCCR") #[Area,Year]  Polution Reducution Capital Charge Rate ($/$)
  EUCM::VariableArray{4} = ReadDisk(db,"EGInput/EUCM") #[FuelEP,Plant,Poll,PollX]  Cross-over Reduction Multiplier (Tonnes/Tonnes)
  EURCD::VariableArray{1} = ReadDisk(db,"EGInput/EURCD") #[Poll]  Reduction Capital Construction Delay (Years)
  EURCPL::VariableArray{1} = ReadDisk(db,"EGInput/EURCPL") #[Poll]  Reduction Capital Physical Life (Years)
  EURCstM::VariableArray{4} = ReadDisk(db,"EGInput/EURCstM") # [FuelEP,Plant,Poll,Year] Reduction Cost Technology Multiplier ($/$)
  EUROCF::VariableArray{4} = ReadDisk(db,"EGInput/EUROCF") # [FuelEP,Plant,Poll,Area] Polution Reducution O&M ($/Tonne)
  EUVRP::VariableArray{5} = ReadDisk(db,"EGInput/EUVRP") # [FuelEP,Plant,Poll,Area,Year] Voluntary Reduction Policy (Tonnes/Tonnes)
  EUVRRT::VariableArray{2} = ReadDisk(db,"EGInput/EUVRRT") # [FuelEP,Plant] Voluntary Reduction response time (Years)
  PCostM::VariableArray{5} = ReadDisk(db,"EGInput/PCostM") # [FuelEP,Plant,Poll,Area,Year] Permit Cost Multiplier ($/Tonne/$/Tonne)
  GrSysFr::VariableArray{3} = ReadDisk(db,"EGInput/GrSysFr") # [Node,Area,Year] Green Power Capacity as Fraction of System (MW/MW)
  UnFlFrTime::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrTime") #[Unit,FuelEP,Year]  Fuel Adjustment Time (Years)
  UnPRSw::VariableArray{3} = ReadDisk(db,"EGInput/UnPRSw") # [Unit,Poll,Year] Pollution Reduction Switch (Number)
  UnXSw::VariableArray{2} = ReadDisk(db,"EGInput/UnXSw") # [Unit,Year] Exogneous Unit Data Switch (0=Exogenous)
  xUnVCost::VariableArray{4} = ReadDisk(db,"EGInput/xUnVCost") # [Unit,TimeP,Month,Year] Exogenous Market Price Bid ($/MWh)

end

function EGData_Inputs(db)
  data = EControl(; db)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Fuel,Fuels,FuelEP,FuelEPs) = data
  (; GenCo,GenCoKey,GenCoDS,Horizon,Nation,Nations,Node,Nodes,NodeX,NodeXs) = data
  (; Plant,Plants,Poll,Polls,Power,Powers,TimeP,TimePs,Units,Year,YearDS,Years) = data
  (; AFCM,AvFactor,AwardSwitch,BFracMax,BlkSw,BsBdFr,BuildFr,BuildSw) = data
  (; CapCredit,CD,CUCLimit,ECFPAdder,ECFPMinMult,EmitNew,ESTime,EUCCR) = data
  (; EUCM,EURCD,EURCPL,EURCstM,EUROCF,EURPCSw,EUVRP,EUVRRT,FIT,FlFrTime,FlPlnMap) = data
  (; GCBL,GCCCFlag,GCDevTime,GCExpSw,GCTL,GrMSM,GrSysFr,GrVF,HDFCFR) = data
  (; HDGCFR,HDVCFR,IPExpSw,IPTPMap,LLEff,MCELimit,MRunNew,NodeSw,NodeXSw) = data
  (; OGCCFraction,OGCCSmallFraction,PCostM,PjMax,PjMnPS,PjNSw,PkHydSw) = data
  (; PlantSw,PolSw,PrDiFr,RnBuildFr,RnFr,RnMSM,RnOption,RnSwitch,RnVF) = data
  (; StorageEfficiency,StorageSwitch,TaxR,TPRMap,UnCounter,UnFlFrTime,UnPRSw,UnXSw) = data
  (; USMT,WCC,xEMGVCost,xEURM,xExchangeRateNation,xInflationNation,xLLVC,xUnEGC,xUnVCost) = data

  ########################
  #  Maps, Descriptors, Switches, and such.
  ########################  

  ########################
  # AwardSwitch[Area,Year] New Capacity Award Switch (1=Cost, 2=Portfolio)
  #
  @. AwardSwitch=1.0
  WriteDisk(db,"EGInput/AwardSwitch",AwardSwitch)

  ########################
  # FIT[Plant,Area] Feed-In Tariff for Renewable Power (nominal $/MWh)
  #
  # TODO In Promula, this appears to only set values for one year.
  FIT[:,:,Zero] .= 0
  WriteDisk(db,"EGInput/FIT",FIT)

  ########################
  # NodeSw[Node] Switch to indicate if Node is Active (1=Active)
  # NodeXSw[NodeX] Switch to indicate if NodeX is Active (1=Active)
  #
  @. NodeSw=1.0
  @. NodeXSw=1.0
  WriteDisk(db,"EGInput/NodeSw",NodeSw)
  WriteDisk(db,"EGInput/NodeXSw",NodeXSw)

  ########################
  # PlantSw[Plant] Iteration when this Plant Type begins to be calibrated
  #
  @. PlantSw=5
  plants=Select(Plant,["OtherGeneration","OnshoreWind","OffshoreWind","SolarPV","SolarThermal","Wave","Geothermal"])
  PlantSw[plants] .= 1
  plants=Select(Plant,["BaseHydro","PeakHydro","SmallHydro"])
  PlantSw[plants] .= 1
  plants=Select(Plant,["Nuclear","SMNR"])
  PlantSw[plants] .= 2
  plants=Select(Plant,["OGSteam","Coal","Biomass","Biogas"])
  PlantSw[plants] .= 3
  plants=Select(Plant,["OGCT","OGCC"])
  PlantSw[plants] .= 5
  plants=Select(Plant,["FuelCell","PumpedHydro","Battery"])
  PlantSw[plants] .= 5
  WriteDisk(db,"EGInput/PlantSw",PlantSw)

  ########################
  # EURPCSw[Plant,Poll,Area,Year] Pollution Reduction Curve Switch (1=2009, 2=2004)
  #
  @. EURPCSw=2.0
  WriteDisk(db,"EGInput/EURPCSw",EURPCSw)

  ########################
  # RnBuildFr[Plant,Area] Build Fraction for Renewable Capacity as Fraction of Area (MW/MW)
  #
  @. RnBuildFr=0.0
  WriteDisk(db,"EGInput/RnBuildFr",RnBuildFr)

  ########################
  # RnOption[Area,Year] Renewable Expansion Option (1=Local RPS, 2=Regional RPS, 3=FIT)
  #
  @. RnOption=0.0
  WriteDisk(db,"EGInput/RnOption",RnOption)

  ########################
  # TPRMap[TimeP,Power] TimeP to Power Map
  #
  # The CER analysi changed the TimeP 5 to intermediate, but this needs more analysis - Jeff Amlin 9/4/24
  #
  #                         Peak  Inter  Base
  TPRMap[TimePs,Powers] =  [1      1     1
                            1      1     1
                            1      1     1
                            0      1     1
                            0      0     1
                            0      0     1]
  WriteDisk(db,"EGInput/TPRMap",TPRMap)

  ########################
  #
  #   Below are the calibration control variables.  The value in the zero
  #   year slot tells the model how to parameterize the future values of the
  #   calibrated variable.  If exogenous values are used for the future values
  #   those values will be placed in the future year slots of the control
  #   variable.  The values in the historical years are used to select the
  #   years to average.
  #   Settings for the calibration control variables which are used are:
  #   1 - Exogenous values  -  Sets future values of calibrated variable to
  #       values in future years of the control variable.
  #   3 - Last  -  Sets future values of the calibrated variable to the last
  #       historical year.
  #   4 - Average  -  Sets future values of the calibrated variable to the
  #       average of the historical years.
  #
  ########################
  #  Data
  ########################

  ########################
  # AFCM[Area,Year] Average Fixed Cost Multiplier (Dless)
  #
  # 1. The default value is one.
  # 2. The variable is given a value with an equation.
  # 3. P. Cross 9/10/96
  #
  @. AFCM=1.0
  WriteDisk(db,"EGInput/AFCM",AFCM)

  ########################
  # AvFactor[Plant,TimeP,Month,Area,Year] Availability Factor (MW/MW)
  #
  #
  @. AvFactor=1.0
  plants=Select(Plant,["Battery","PumpedHydro"])
  timep=last(TimePs)
  AvFactor[plants,timep,:,:,:] .= 0
  WriteDisk(db,"EGInput/AvFactor",AvFactor)

  ########################
  # BFracMax[Area,Year] Maximum Fraction of Capacity Built Endogenously (MW/MW)
  #
  # Source: Analysis by Jeff Amlin and Randy Levesque - 04/23/21
  #
  @. BFracMax=0.02
  WriteDisk(db,"EGInput/BFracMax",BFracMax)

  ########################
  # BsBdFr[Power,Area,Year] Base Build Fraction (Fraction)
  #
  @. BsBdFr=0.02
  WriteDisk(db,"EGInput/BsBdFr",BsBdFr)

  ########################
  # BuildSw[Area,Year] Build switch
  #
  # 1. The default building decision is exogenous.
  # 2. The variable is given a value with an equation.
  # 3. P. Cross 9/10/96
  #
  years=collect(Zero:Last)
  BuildSw[:,years] .= 0
  years=collect(Future:Final)
  BuildSw[:,years] .= 5
  WriteDisk(db,"EGInput/BuildSw",BuildSw)


  ########################
  # BuildFr[Area,Year] Building fraction
  #
  # 1. The default building decision is exogenous.
  # 2. The variable is given a value with an equation.
  # 3. P. Cross 9/10/96
  #
  @. BuildFr=0.0
  WriteDisk(db,"EGInput/BuildFr",BuildFr)

  ########################
  # CapCredit[Plant,Area,Year] Capacity Credit (MW/MW)
  #
  @. CapCredit=1.00
  plants=Select(Plant,["OnshoreWind","OffshoreWind","SolarPV","SolarThermal"])
  CapCredit[plants,:,:] .= 0.15
  WriteDisk(db,"EGInput/CapCredit",CapCredit)

  ########################
  # CD[Plant,Year] Construction Delay (Years)
  #
  # 1. Union Electric's "Generation Technologies for Integrated Resource
  #    Planning", Janauary, 1995.  spreadsheet Plant.xls
  # 2. The variable is given a value with an equation.
  # 3. J. Amlin 2/19/98.
  #
  @. CD=2
  CD[Select(Plant,"OGCT"),:] .= 1
  CD[Select(Plant,"OGCC"),:] .= 2
  CD[Select(Plant,"OGSteam"),:] .= 2
  CD[Select(Plant,"Coal"),:] .= 4
  CD[Select(Plant,"Nuclear"),:] .= 12
  CD[Select(Plant,"SMNR"),:] .= 12
  CD[Select(Plant,"BaseHydro"),:] .= 5
  CD[Select(Plant,"PeakHydro"),:] .= 5
  WriteDisk(db,"EGInput/CD",CD)

  ########################
  # CUCLimit[Year] Build Decision Capacity Under Construction Limit (MW/MW)
  #
  # Source: Analysis by Jeff Amlin and Randy Levesque - 04/23/21
  #
  @. CUCLimit=0.10
  WriteDisk(db,"EGInput/CUCLimit",CUCLimit)

  ########################
  # ECFPAdder[FuelEP,Month,Area,Year] Monthly Fuel Price Adder ($/mmBtu)
  #
  @. ECFPAdder=0
  WriteDisk(db,"EGInput/ECFPAdder",ECFPAdder)

  ########################
  # ECFPMinMult[Year] Minimum Monthly Fuel Price Multiplier ($/mmBtu)
  #
  @. ECFPMinMult=1.0
  WriteDisk(db,"EGInput/ECFPMinMult",ECFPMinMult)

  ########################
  # EmitNew[Plant,Area] Do New Plants Emit Pollution? (1=Yes)
  #
  # Set flag to 1 for emitting plant types
  #
  @. EmitNew=0
  plants=Select(Plant,["OGCT","OGCC","OGSteam","Coal","OtherGeneration","Biomass",
                      "Biogas","FuelCell","CoalCCS","Waste","SmallOGCC"])
  EmitNew[plants,:] .= 1
  WriteDisk(db,"EGInput/EmitNew",EmitNew)

  @. FlFrTime = 1.0
  WriteDisk(db,"EGInput/FlFrTime",FlFrTime)

  ########################
  # FlPlnMap[Fuel,Plant] Fuel/Plant Map
  #
  # Plant types which burn fuel which are part of FuelEP are not specified here
  #
  @. FlPlnMap=0

  fuel=Select(Fuel,"Nuclear")
  plants=Select(Plant,["Nuclear","SMNR"])
  FlPlnMap[fuel,plants] .= 1

  fuel=Select(Fuel,"Hydro")
  plants=Select(Plant,["BaseHydro","PeakHydro","PumpedHydro","SmallHydro"])
  FlPlnMap[fuel,plants] .= 1

  fuel=Select(Fuel,"Wind")
  plants=Select(Plant,["OnshoreWind","OffshoreWind"])
  FlPlnMap[fuel,plants] .= 1

  fuel=Select(Fuel,"Solar")
  plants=Select(Plant,["SolarPV","SolarThermal"])
  FlPlnMap[fuel,plants] .= 1

  fuel=Select(Fuel,"Wave")
  plant=Select(Plant,"Wave")
  FlPlnMap[fuel,plant] = 1

  fuel=Select(Fuel,"Geothermal")
  plant=Select(Plant,"Geothermal")
  FlPlnMap[fuel,plant] = 1

  fuel=Select(Fuel,"Electric")
  plant=Select(Plant,"Battery")
  FlPlnMap[fuel,plant] = 1

  WriteDisk(db,"EGInput/FlPlnMap",FlPlnMap)

  ########################
  # GCCCFlag[Plant,Area,Year] Plant Capital Cost Flag
  #
  # Initialize all plants to an infinite potential capacity
  #
  @. GCCCFlag=0.0
  #
  # Plants whose potential is limited with costs increasing as sites are developed.
  #
  plants=Select(Plant,["Biomass","SmallHydro","OnshoreWind","OffshoreWind","SolarPV","SolarThermal","PumpedHydro"])
  GCCCFlag[plants,:,:] .= 1
  #
  # Plants whose potential is limited, but costs are fixed.
  #
  plants=Select(Plant,["FuelCell","Geothermal","Battery"])
  GCCCFlag[plants,:,:] .= 2
  #
  # Plants whose potential is limited by GRP - Biogas
  #
  plant=Select(Plant,"Biogas")
  GCCCFlag[plant,:,:] .= 3
  WriteDisk(db,"EGInput/GCCCFlag",GCCCFlag)

  ########################
  # GCDevTime[Plant,Year] Generation Capacity Development Time (Years)
  #
  @. GCDevTime=1
  plants=Select(Plant,(from="Battery",to="Biomass"))
  GCDevTime[plants,:] .= 10
  WriteDisk(db,"EGInput/GCDevTime",GCDevTime)

  ########################
  # GCExpSw[Plant,Area,Year] Generation Capacity Expansion Switch
  #
  # Conventional Plants (GCExpSw=1)
  #
  @. GCExpSw=1.0
  #
  # Renewable Plants (GCExpSw=2)
  #
  plants=Select(Plant,["Biomass","Geothermal","SmallHydro","SolarPV",
               "SolarThermal","Waste","Wave","OnshoreWind","OffshoreWind"])
  GCExpSw[plants,:,:] .= 2
  #
  # Landfill Gas and Other Generation come from other parts of the model (GCExpSw=3)
  #
  plants=Select(Plant,["Biogas","OtherGeneration"])
  GCExpSw[plants,:,:] .= 3
  WriteDisk(db,"EGInput/GCExpSw",GCExpSw)

  ########################
  # GCBL[Plant,Area,Year] Generation Capacity Book Life (Years)
  #
  # Generating capacity financial lifetimes are estimated at 30 years - J. Amlin
  #
  @. GCBL=30
  WriteDisk(db,"EGInput/GCBL",GCBL)


  ########################
  # GCTL[Plant,Area,Year] Generation Capacity Tax Life (Years)
  #
  # Generating capacity tax lifetimes are estimated at 80% of Book Life - J. Amlin
  #
  @. GCTL=GCBL*0.80
  WriteDisk(db,"EGInput/GCTL",GCTL)


  ########################
  # xGCPot[Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
  #
  # Values in PlantCharacteristics.txt
  ########################

  ########################
  # GrMSM[Plant,Node,Area,Year] Green Power Market Share Non-Price Factors (MW/MW)
  # GrVF[Year] Green Power Market Share Variance Factor (MW/MW)
  #
  @. GrMSM=1.0
  @. GrVF=0-5.0
  WriteDisk(db,"EGInput/GrMSM",GrMSM)
  WriteDisk(db,"EGInput/GrVF",GrVF)

  ########################
  # HDFCFR[Plant,GenCo,TimeP,Year] Fraction of Fixed Costs in Block
  #
  @. HDFCFR=0.0
  plant=Select(Plant,"OGCT")
  HDFCFR[plant,:,:,:] .= 1.0
  WriteDisk(db,"EGInput/HDFCFR",HDFCFR)


  ########################
  # HDGCFR[Plant,GenCo,Node,TimeP,Month,Year] Fraction of Available Generating Capacity in Block (MW/MW)
  #
  @. HDGCFR=1.0
  WriteDisk(db,"EGInput/HDGCFR",HDGCFR)


  ########################
  # HDFCFR[Plant,GenCo,Node,TimeP,Month,Year] Fraction of Variable Costs in Block
  #
  @. HDVCFR=1.0
  plant=Select(Plant,"Nuclear")
  HDFCFR[plant,:,:,:] .= 0.25
  plant=Select(Plant,"SMNR")
  HDFCFR[plant,:,:,:] .= 0.25
  WriteDisk(db,"EGInput/HDFCFR",HDFCFR)

  ########################
  # IPExpSw[Plant,Area,Year] Intermittent Power Capacity Expansion Switch (1=Build)
  #
  @. IPExpSw=0.0
  plants=Select(Plant,["Biomass","FuelCell","Geothermal","SmallHydro","SolarPV",
               "SolarThermal","Waste","Wave","OnshoreWind","OffshoreWind"])
  IPExpSw[plants,:,:] .= 1.0
  WriteDisk(db,"EGInput/IPExpSw",IPExpSw)

  ########################
  # IPTPMap[TimeP,Area] Intermittent Power Price Time Period Map (1=use TimeP)
  #
  @. IPTPMap=0.0
  timeps=collect(3:6)
  IPTPMap[timeps,:] .= 1.0
  WriteDisk(db,"EGInput/IPTPMap",IPTPMap)

  ########################
  # LLEff[Node,NodeX,Year] Transmission Line Efficiency (MW/MW)
  #
  # Line Losses at 2.5% - Ottie Nabors phone call 4/30/08
  #
  @. LLEff=(1-0.025)
  WriteDisk(db,"EGInput/LLEff",LLEff)

  ########################
  # xLLVC[Node,NodeX,Year] Transmission Line Efficiency (MW/MW)
  #
  # Overwrite the LLVC to represent a value of 5.74 2022CAD/MWh.
  # From CER CGII allignment work with NextGrid Feb 2024 V.Keller
  #
  CN=Select(Nation,"CN")
  US=Select(Nation,"US")
  for y in Years, nx in NodeXs, n in Nodes
    xLLVC[n,nx,y]= 5.74/xExchangeRateNation[CN,Yr(2022)]/xInflationNation[US,Yr(2022)]
  end
  WriteDisk(db,"EGInput/xLLVC",xLLVC)

  ########################
  # MCELimit[Area,Year] Build Decision Cost of Power Limit
  #
  @. MCELimit=0.10
  WriteDisk(db,"EGInput/MCELimit",MCELimit)

  ########################
  # MRunNew[Plant,Area] New Plant Must Run Switch (1=Must Run)
  #
  @. MRunNew=0.0
  MRunNew[Select(Plant,"PeakHydro"),:] .= 1.0
  WriteDisk(db,"EGInput/MRunNew",MRunNew)

  ########################
  # OGCCFraction[Area,Year] Fraction of new OG capacity which is OGCC (MW/MW)
  #
  @. OGCCFraction=1.0
  WriteDisk(db,"EGInput/OGCCFraction",OGCCFraction)

  ########################
  # OGCCSmallFraction[Area,Year] Fraction of new OGCC capacity which is Small (MW/MW)
  #
  @. OGCCSmallFraction=0.0
  WriteDisk(db,"EGInput/OGCCSmallFraction",OGCCSmallFraction)

  ########################
  # PjMax[Plant,Area] Maximum Project Size (MW)
  #
  # 1. Source.  
  # 2. The values are assigned with an equation.
  # 3. P. Cross 2/21/96.
  #
  @. PjMax=0.0
  PjMax[Select(Plant,"OGCT"),:] .= 99999
  PjMax[Select(Plant,"OGCC"),:] .= 99999
  WriteDisk(db,"EGInput/PjMax",PjMax)

  ########################
  # PjMnPS[Plant,Area] Minimum Project Size (MW)
  #
  @. PjMax=1.0
  PjMnPS[Select(Plant,"OGCT"),:] .= 50
  PjMnPS[Select(Plant,"OGCC"),:] .= 50
  PjMnPS[Select(Plant,"OGSteam"),:] .= 100
  PjMnPS[Select(Plant,"Coal"),:] .= 400
  PjMnPS[Select(Plant,"CoalCCS"),:] .= 400
  PjMnPS[Select(Plant,"Nuclear"),:] .= 750
  PjMnPS[Select(Plant,"SMNR"),:] .= 750
  PjMnPS[Select(Plant,"BaseHydro"),:] .= 50
  PjMnPS[Select(Plant,"PeakHydro"),:] .= 50
  PjMnPS[Select(Plant,"Biomass"),:] .= 25
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)

  ########################
  # PjNSw[Node,GenCo,Area,Year] Project Selection Node Switch (1=Build)
  #
  @. PjNSw=1.0
  WriteDisk(db,"EGInput/PjNSw",PjNSw)

  ########################
  # PkHydSw[Year] Switch for Allocation Method for Peak Hydro (1=new method)
  #
  @. PkHydSw=0
  years=collect(Yr(2005):Final)
  PkHydSw[years] .= 1
  WriteDisk(db,"EGInput/PkHydSw",PkHydSw)

  ########################
  # PolSw[Poll,Year] Switch to Execute Pollution Procedure
  #
  @. PolSw=2.0
  WriteDisk(db,"EGInput/PolSw",PolSw)
  #TODO PolSw seems unused in Electric sector; only used in R/C/I/T sectors, defined on appropriate databases. -LJD, 25/03/07

  ########################
  # PrDiFr[Power,Area,Year] Price Differential Fraction (Fraction)
  #
  # Source: Analysis by Jeff Amlin and Randy Levesque - 04/23/21
  #
  @. PrDiFr=0.15
  WriteDisk(db,"EGInput/PrDiFr",PrDiFr)

  ########################
  # RnFr[Area] Renewable Fraction (GWh/GWh)
  # RnMSM[Plant,Node,GenCo,Area,Year] Renewable Market Share Non-Price Factors (GWh/GWh)
  # RnSwitch[Plant,Area] Renewable Plant Type Switch (1=Renewable)
  # RnVF[Area,Year] Renewable Market Share Variance Factor ($/$)
  #
  @. RnFr=0.0
  @. RnVF=0-10.0
  #
  @. RnMSM=0.0
  @. RnSwitch=0
  plants=Select(Plant,["Biomass","Biogas","OnshoreWind","OffshoreWind","SolarPV","SolarThermal","SmallHydro","Wave","Geothermal","Waste"])
  RnMSM[plants,:,:,:,:] .= 1.0
  RnSwitch[plants,:] .= 0
  WriteDisk(db,"EGInput/RnFr",RnFr)
  WriteDisk(db,"EGInput/RnMSM",RnMSM)
  WriteDisk(db,"EGInput/RnSwitch",RnSwitch)
  WriteDisk(db,"EGInput/RnVF",RnVF)

  ########################
  # StorageEfficiency[Power,Area,Year] Storage Efficiency (GWh/GWh)
  #
  @. StorageEfficiency=0.85
  WriteDisk(db,"EGInput/StorageEfficiency",StorageEfficiency)

  ########################
  # StorageSwitch[Plant] Storage Technology Switch (1=Storage)
  #
  @. StorageSwitch=0
  plants=Select(Plant,["PumpedHydro","Battery"])
  StorageSwitch[plants] .= 1
  WriteDisk(db,"EGInput/StorageSwitch",StorageSwitch)

  ########################
  # TaxR[Area,Year] Income Tax Rate (DLESS)
  # 
  # 1. The values are from the Federal and State tax codes.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  years=collect(Yr(1988):Final)
  TaxR[:,years] .= 0.34
  WriteDisk(db,"EGInput/TaxR",TaxR)

  ########################
  # USMT[Horizon] Smoothing Time (Year)
  #
  @. USMT=4
  WriteDisk(db,"EGInput/USMT",USMT)

  ########################
  # WCC[Area,Year] Weighted Cost of Capital (1/Yr)
  #
  @. WCC=0.095
  #
  # Adjustment for PCF policies.
  #
  years=collect(Yr(2020):Final)
  # WCC[:,years] .= 0.035
  # Edit for CER CGII allignment work with NextGrid. Feb 2024 V.Keller
  WCC[:,years] .= 0.0374
  years=collect(Yr(2011):Yr(2019))
  for year in years, area in Areas
    WCC[area,year]=WCC[area,year-1]+(WCC[area,Yr(2020)]-WCC[area,Yr(2010)])/(2020-2010)
  end
  WriteDisk(db,"EGInput/WCC",WCC)

  # *******************************************************************************
  # *
  # *Define Variable
  # *xOILFR(GenCo,Year)    'Fraction of Oil/Gas which is Oil (FRAC.)',
  # * Type=Real(8,2),Disk(EGInput,xOILFR(GenCo,Year))
  # *End Define Variable
  # ** 
  # ** 1. The default value is one.
  # ** 2. The values are read in directly.
  # ** 3. P. Cross 9/12/96.
  # **
  # *xOILFR=1
  # *Write Disk(xOILFR)

  ########################
  # Calculated Values.
  ########################

  ########################
  # BlkSw[Area,Year] Block switch
  #
  @. BlkSw=1.0
  WriteDisk(db,"EGInput/BlkSw",BlkSw)

  ########################
  # UnCounter[Year] Number of Units
  #
  @. UnCounter=1
  WriteDisk(db,"EGInput/UnCounter",UnCounter)

  ########################
  # xEMGVCost[Node,Year] Dispatch Price for Emergency Power ($/MWh)
  #
  # Default value is $250/MWH except for Labrador which higher
  # so that emergency power is not exported from Labrador to
  # Quebec.  Jeff Amlin 9/02/2013
  #
  @. xEMGVCost=250
  #
  # Node 3 is Labrador
  #
  node=Select(Node,"LB")
  xEMGVCost[node,:] .= 300
  #
  years=collect(Future:Final)
  for year in years, node in Nodes
    xEMGVCost[node,year]=xEMGVCost[node,year-1]*(1+0.01)
  end
  WriteDisk(db,"EGInput/xEMGVCost",xEMGVCost)

  ########################
  # xUnEGC[Unit,TimeP,Month,Year] Exogenous Effective Generating Capacity (MW)
  #
  @. xUnEGC=-99
  WriteDisk(db,"EGInput/xUnEGC",xUnEGC)

  ########################
  # ESTime[Area] Starting Year for Simulation
  #
  @. ESTime=1989
  WriteDisk(db,"EGInput/ESTime",ESTime)

  ########################
  # xEURM[FuelEP,Plant,Poll,Area,Year] Exogenous Reduction Multiplier by Area (Tonnes/Tonnes)
  #
  # Exogenous Reduction Multiplier is initialized at 1 (No exogenous adjustment)
  #
  @. xEURM=1
  WriteDisk(db,"EGInput/xEURM",xEURM)

  ########################
  # CAC Curve Variables
  ########################
  # EUCCR[Area,Year] Polution Reducution Capital Charge Rate ($/$)
  # EUCM[FuelEP,Plant,Poll,PollX] Cross-over Reduction Multiplier (Tonnes/Tonnes)
  # EURCD[Poll] Reduction Capital Construction Delay (Years)
  # EURCPL[Poll] Reduction Capital Pysical Life (Years)
  # EURCstM[FuelEP,Plant,Poll,Year] Reduction Cost Technology Multiplier ($/$)
  # EUROCF[FuelEP,Plant,Poll,Area] Polution Reducution O&M ($/Tonne)
  # EUVRP[FuelEP,Plant,Poll,Area,Year] Voluntary Reduction Policy (Tonnes/Tonnes)
  # EUVRRT[FuelEP,Plant] Voluntary Reduction response time (Years)
  #
  # Electric Utility Capital Charge Rate for Reductions
  #
  @. EUCCR=0.12
  WriteDisk(db,"EGInput/EUCCR",EUCCR)

  #
  # Cross Impact Multiplier (is zero except for the diaganol)
  #
  @. EUCM=0
  for poll in Polls
    pollx=poll
    EUCM[:,:,poll,pollx] .= 1.0
  end
  WriteDisk(db,"EGInput/EUCM",EUCM)

  #
  # Reduction Cost Multiplier
  #
  @. EURCstM=1.0
  WriteDisk(db,"EGInput/EURCstM",EURCstM)

  #
  # Reduction Construction Time
  #
  # @. EURCD=3.0
  @. EURCD=1.0
  WriteDisk(db,"EGInput/EURCD",EURCD)

  #
  # Reduction Capital Lifetime
  #
  @. EURCPL=30
  WriteDisk(db,"EGInput/EURCPL",EURCPL)

  #
  # Reduction Operating Cost Factor ($/$) from Dave Sawyer
  #
  SOX=Select(Poll,"SOX")
  NOX=Select(Poll,"NOX")
  fueleps=Select(FuelEP,["Diesel","HFO","LFO"])
  EUROCF[fueleps,:,SOX,:] .= 0.35
  EUROCF[fueleps,:,NOX,:] .= 0.13
  polls=Select(Poll,["PM25","PM10","PMT","BC"])
  EUROCF[fueleps,:,polls,:] .= 0.22
  #
  fuelep=Select(FuelEP,"NaturalGas")
  EUROCF[fueleps,:,SOX,:] .= 0.0
  EUROCF[fueleps,:,NOX,:] .= 0.13
  polls=Select(Poll,["PM25","PM10","PMT","BC"])
  EUROCF[fueleps,:,polls,:] .= 0.22
  #
  fuelep=Select(FuelEP,"Coal")
  EUROCF[fueleps,:,SOX,:] .= 0.35
  EUROCF[fueleps,:,NOX,:] .= 0.0
  polls=Select(Poll,["PM25","PM10","PMT","BC"])
  EUROCF[fueleps,:,polls,:] .= 0.22
  #
  WriteDisk(db,"EGInput/EUROCF",EUROCF)

  #
  # Voluntary Reductions
  #
  @. EUVRP=0
  @. EUVRRT=1
  WriteDisk(db,"EGInput/EUVRP",EUVRP)
  WriteDisk(db,"EGInput/EUVRRT",EUVRRT)

  ########################
  # PCostM[FuelEP,Plant,Poll,Area,Year] Permit Cost Multiplier ($/Tonne/$/Tonne)
  #
  @. PCostM=1
  WriteDisk(db,"EGInput/PCostM",PCostM)

  ########################
  # GrSysFr[Node,Area,Year] Green Power Capacity as Fraction of System (MW/MW)
  #
  @. GrSysFr=0.0
  WriteDisk(db,"EGInput/GrSysFr",GrSysFr)

  @. UnFlFrTime = 1.0
  WriteDisk(db,"EGInput/UnFlFrTime",UnFlFrTime)

  ########################
  # UnPRSw[Unit,Poll,Year] Pollution Reduction Switch (Number)
  #
  @. UnPRSw=2
  WriteDisk(db,"EGInput/UnPRSw",UnPRSw)

  #
  # UnXSw[Unit,Year] Exogneous Unit Data Switch (0=Exogenous)
  #
  for year in Years, unit in Units
    if year <= Last
      UnXSw[unit,year] = 0
    else
      UnXSw[unit,year] = 1
    end
  end
  WriteDisk(db,"EGInput/UnXSw",UnXSw)

  ########################
  # xUnVCost[Unit,TimeP,Month,Year] Exogenous Market Price Bid ($/MWh)
  #
  @. xUnVCost=-99
  WriteDisk(db,"EGInput/xUnVCost",xUnVCost)

end # end EGData_Inputs

function Control(db)
  EGData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end


end #end module
