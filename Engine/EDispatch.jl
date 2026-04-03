#
# EDispatch.jl
#

module EDispatch

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime,ITime
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power
import ...EnergyModel: finite_exp,finite_log,E2020Folder

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  AgUnit::SetArray = ReadDisk(db,"MainDB/AgUnitKey")
  AgUnits::Vector{Int} = collect(Select(AgUnit))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeKey::SetArray = ReadDisk(db,"MainDB/NodeKey") 
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXs::Vector{Int} = collect(Select(NodeX))  
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))  
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))   
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  AgEGC::VariableArray{1} = ReadDisk(db,"EGOutput/AgEGC") #[AgUnit]  Aggregate Unit Bid Quantity (MW)
  AgGCD::VariableArray{1} = ReadDisk(db,"EGOutput/AgGCD") #[AgUnit]  Aggregate Unit Generating Capacity Dispatched (MW)
  AgNode::SetArray = AgUnit
  #AgNode::SetArray = ReadDisk(db,"EGOutput/AgNode") # [AgUnit]  Aggregate Unit Node
  AgNum::Int = ReadDisk(db,"EGOutput/AgNum",year) # [Year]  Number of Aggregate Units
  AgPOCGWh::VariableArray{2} = ReadDisk(db,"EGOutput/AgPOCGWh") #[AgUnit,Poll]  Aggregate Unit Pollution Coefficient (Tonnes/GWh)
  AgVCost::VariableArray{1} = ReadDisk(db,"EGOutput/AgVCost") #[AgUnit]  Aggregate Unit Bid Price ($/MWh)
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  ArNdFr::VariableArray{2} = ReadDisk(db,"EGInput/ArNdFr",year) #[Area,Node,Year]  Fraction of the Area in each Node (MW/MW)
  AvFactor::VariableArray{4} = ReadDisk(db,"EGInput/AvFactor",year) #[Plant,TimeP,Month,Area,Year]  Availability Factor (MW/MW)
  BlkSw::VariableArray{1} = ReadDisk(db,"EGInput/BlkSw",year) #[Area,Year]  Block switch
  DmdFraction::VariableArray{3} = ReadDisk(db,"EGOutput/DmdFraction",year) #[Node,TimeP,Month,Year]  Fraction of Annual Electricity Demand in each Time Period (GWh/GWh)
  DmdRemaining::VariableArray{3} = ReadDisk(db,"EGOutput/DmdRemaining",year) #[Node,TimeP,Month,Year]  Fraction of Annual Electricity Demand in Remaining Time Period (GWh/GWh)
  EmEGA::VariableArray{3} = ReadDisk(db,"EGOutput/EmEGA",year) #[Node,TimeP,Month,Year]  Emergency Generation (GWh)
  EmissionGroup::VariableArray{1} = zeros(Int,length(Unit))
  EmissionGroupInterval::Float32 = 50.0 # Size of Emission Group Intervals (Tonnes/GWh)
  Epsilon::Float32 = ReadDisk(db,"MainDB/Epsilon")[1] #[tv] A Very Small Number
  EUEuPol::VariableArray{4} = ReadDisk(db,"EGOutput/EUEuPol",year) #[FuelEP,Plant,Poll,Area,Year]  Electric Utility Pollution (Tonnes/Yr)
  EUEuPolPrior::VariableArray{4} = ReadDisk(db,"EGOutput/EUEuPol",prior) #[FuelEP,Plant,Poll,Area,Year]  Electric Utility Pollution (Tonnes/Yr)
  EUPolGHGPrior::VariableArray{1} = zeros(Float32,length(Area)) # GHG Emissions from Previous Year (Tonnes/Yr)
  ExchangeRate::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",year) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateNode::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateNode",year) #[Node,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateUnit::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateUnit",year) #[Unit,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExpUVCost::VariableArray{1} = ReadDisk(db,"EGInput/ExpUVCost",year) #[Month,Year]  Expected Spot Price for LLH Time Period ($/MWh)
  HDADP::VariableArray{3} = ReadDisk(db,"EGOutput/HDADP",year) #[Node,TimeP,Month,Year]  Average Load in Interval (MW)
  HDADPwithStorage::VariableArray{3} = ReadDisk(db,"EGOutput/HDADPwithStorage",year) #[Node,TimeP,Month,Year]  Average Load in Interval with Generation to Fill Storage (MW)
  HDEmGC::VariableArray{2} = ReadDisk(db,"EGOutput/HDEmGC",year) #[Month,Node,Year]  Emergency Power Available (MW)
  HDEmMDS::VariableArray{3} = ReadDisk(db,"EGOutput/HDEmMDS",year) #[Node,TimeP,Month,Year]  Emergency Power Dispatched (MW)
  HDEmVCost::VariableArray{3} = ReadDisk(db,"EGOutput/HDEmVCost",year) #[Node,TimeP,Month,Year]  Dispatch Price for Emergency Power (US$/MWh)
  HDEmVCostUS::VariableArray{3} = zeros(Float32,length(Node),length(TimeP),length(Month)) # Dispatch Price for Emergency Power (US$/MWh)
  HDFCFR::VariableArray{3} = ReadDisk(db,"EGInput/HDFCFR",year) #[Plant,GenCo,TimeP,Year]  Fraction of Fixed Costs Bid
  HDGCFR::VariableArray{5} = ReadDisk(db,"EGInput/HDGCFR",year) #[Plant,GenCo,Node,TimeP,Month,Year]  Fraction of Available Generating Capacity Bid (MW/MW)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HDLLoad::VariableArray{4} = ReadDisk(db,"EGOutput/HDLLoad",year) #[Node,NodeX,TimeP,Month,Year]  Loading on Transmission Lines (MW)
  HDPDP::VariableArray{3} = ReadDisk(db,"EGOutput/HDPDP",year) #[Node,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
  HDPrA::VariableArray{3} = ReadDisk(db,"EOutput/HDPrA",year) #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
  HDPrAUS::VariableArray{3} = ReadDisk(db,"EOutput/HDPrAUS") # Spot Market Marginal Price (US$/MWh)
  HDVCFr::VariableArray{5} = ReadDisk(db,"EGInput/HDVCFR",year) #[Plant,GenCo,Node,TimeP,Month,Year]  Fraction of Variable Costs Bid
  HDXLoad::VariableArray{4} = ReadDisk(db,"EGInput/HDXLoad",year) #[Node,NodeX,TimeP,Month,Year]  Exogenous Loading on Transmission Lines (MW)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") #[Month]  Hours per Month (Hours/Month)
  LDCMS::VariableArray{4} = ReadDisk(db,"EOutput/LDCMS",year) #[Day,Month,Node,Area,Year]  Marketer System Load Curve (MW)
  LLEff::VariableArray{2} = ReadDisk(db,"EGInput/LLEff",year) #[Node,NodeX,Year]  Transmission Line Efficiency (MW/MW)
  LLGen::VariableArray{4} = ReadDisk(db,"EGOutput/LLGen",year) #[Node,NodeX,TimeP,Month,Year]  Generation through Transmission Lines (GWh)
  LLMax::VariableArray{4} = ReadDisk(db,"EGInput/LLMax",year) #[Node,NodeX,TimeP,Month,Year]  Maximum Loading on Transmission Lines (MW)
  LLPoTxR::VariableArray{3} = ReadDisk(db,"EGOutput/LLPoTxR",year) #[Node,NodeX,Market,Year]  Pollution Costs for Transmission (US$/MWh)
  LLPoTxRExo::VariableArray{2} = ReadDisk(db,"EGInput/LLPoTxRExo",year) #[Node,NodeX,Year]  Exogenous Pollution Costs for Transmission (Real US$/MWH)
  LLVC::VariableArray{2} = ReadDisk(db,"EGOutput/LLVC",year) #[Node,NodeX,Year]  Transmission Rate (US$/MWh)
  MaximumNumberOfEmissionGroups::Float32 = 100.0 # Maximum Number Of Emission Groups
  MCE::VariableArray{3} = ReadDisk(db,"EOutput/MCE",year) #[Plant,Power,Area,Year]  Cost of Energy from New Capacity ($/MWh)
  MEPolPrior::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",prior) #[ECC,Poll,Area,Year]  Process Pollution (Tonnes/Yr)
  MinBid::Float32 = 0.0 # Minimum Dispatch Bid ($/MWh)
  PkHydSw::Float32 = ReadDisk(db,"EGInput/PkHydSw",year) #[Year]  Switch for Allocation Method for Peak Hydro (1=new method)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PollActual::VariableArray{4} = ReadDisk(db,"EGOutput/PollActual",year) #[Poll,TimeP,Month,Node,Year]  Electric Utility Pollution (Tonnes)
  PollAvailable::VariableArray{2} = ReadDisk(db,"EGOutput/PollAvailable",year) #[Poll,Area,Year]  Electric Utility Pollution Limit (Tonnes)
  PollAvailablePrior::VariableArray{2} = ReadDisk(db,"EGOutput/PollAvailable",prior) #[Poll,Area,Prior]  Electric Utility Pollution Limit (Tonnes)
  PollLimit::VariableArray{4} = ReadDisk(db,"EGOutput/PollLimit",year) #[Poll,TimeP,Month,Node,Year]  Electric Utility Pollution Limit (Tonnes)
  PollLimitGHGFlag::VariableArray{1} = ReadDisk(db,"EGInput/PollLimitGHGFlag",year) #[Area,Year]  Pollution Limit GHG Flag (1=GHG Limit)
  PollLimitGHGFlagPrior::VariableArray{1} = ReadDisk(db,"EGInput/PollLimitGHGFlag",prior) #[Area,Prior]  Pollution Limit GHG Flag (1=GHG Limit)
  PollRemaining::VariableArray{2} = zeros(Float32,length(Poll),length(Node)) # Pollution Remaining before Limit (Tonnes)
  PollutionLimit::VariableArray{2} = ReadDisk(db,"EGInput/PollutionLimit",year) #[Poll,Area,Year]  Electric Utility Pollution Limit (Tonnes)
  ResAvail::VariableArray{2} = ReadDisk(db,"EGOutput/ResAvail",year) #[Month,Node,Year]  LLH Reserves Availiable from Baseload Plants (MW)
  ResNeed::VariableArray{2} = ReadDisk(db,"EGOutput/ResNeed",year) #[Month,Node,Year]  LLH Reserves Needed (MW)
  ResReq::VariableArray{2} = ReadDisk(db,"EGOutput/ResReq",year) #[Month,Node,Year]  LLH Reserve Requirements (MW)
  ResSupply::VariableArray{2} = ReadDisk(db,"EGOutput/ResSupply",year) #[Month,Node,Year]  Additonal LLH Reserves Supplied to System (MW)
  StorageUnitCostsPrior::VariableArray{1} = ReadDisk(db,"EGOutput/StorageUnitCosts",prior) #[Area,Year]  Storage Energy Unit Costs ($/MWh)
  StorEnergy::VariableArray{3} = ReadDisk(db,"EGOutput/StorEnergy",year) #[TimeP,Month,Node,Year]  Electricity Required to Recharge Storage (GWh/Yr)
  StorPurchases::VariableArray{2} = ReadDisk(db,"EGOutput/StorPurchases",year) #[Month,Node,Year]  Generation Purchased to Recharge Storage (GWh/Yr)
  UnAFC::VariableArray{1} = ReadDisk(db,"EGOutput/UnAFC",year) #[Unit,Year]  Average Fixed Costs ($/KW)
  UnAgNum::VariableArray{1} = ReadDisk(db,"EGOutput/UnAgNum") #[Unit]  Aggregate Unit Number
  UnArea::Vector{String} = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
  UnAVC::VariableArray{1} = ReadDisk(db,"EGOutput/UnAVC",year) #[Unit,Year]  Average Variable Costs ($/MWh)
  UnAVCMonth::VariableArray{2} = ReadDisk(db,"EGOutput/UnAVCMonth",year) #[Unit,Month,Year]  Average Monthly Variable Costs ($/MWh)
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::Float32 = ReadDisk(db,"EGInput/UnCounter",year) #[Year]  Number of Units
  UnCurtailedSwitch::VariableArray{1} = ReadDisk(db,"EGInput/UnCurtailedSwitch",year) #[Unit, Year]  Unit Curtailment Switch (1=Curtail)
  UnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UnDmd",year) #[Unit,FuelEP,Year]  Energy Demands (TBtu)
  UnEAF::VariableArray{2} = ReadDisk(db,"EGInput/UnEAF",year) #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
  UnEAV::VariableArray{3} = ReadDisk(db,"EGOutput/UnEAV",year) #[Unit,TimeP,Month,Year]  Energy Availability Factor (MWh/MWh)
  UnEffStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnEffStorage") #[Unit]  Storage Efficiency (GWH/GWH)
  UnEG::VariableArray{3} = ReadDisk(db,"EGOutput/UnEG",year) #[Unit,TimeP,Month,Year]  Generation (GWh)
  UnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGA",year) #[Unit,Year]  Net Generation (GWh)
  UnEGC::VariableArray{3} = ReadDisk(db,"EGOutput/UnEGC",year) #[Unit,TimeP,Month,Year]  Effective Generating Capacity (MW)
  UnEGCurtailed::VariableArray{3} = ReadDisk(db,"EGOutput/UnEGCurtailed",year) #[Unit,TimeP,Month,Year]  Generation Curtailed (GWh)
  UnEGGross::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGGross",year) #[Unit,Year]  Gross Generation (GWh/Yr)
  UnFP::VariableArray{2} = ReadDisk(db,"EGOutput/UnFP",year) #[Unit,Month,Year]  Fuel Price ($/mmBtu)
  UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Gross Generating Capacity (MW)
  UnGCD::VariableArray{3} = ReadDisk(db,"EGOutput/UnGCD",year) #[Unit,TimeP,Month,Year]  Generating Capacity Dispatched (MW)
  UnGCNet::VariableArray{1} = ReadDisk(db,"EGOutput/UnGCNet",year) #[Unit,Year]  Net Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
  UnLimited::VariableArray{1} = ReadDisk(db, "EGInput/UnLimited", year) #[Unit,Year]  Limited Energy Units Switch (Switch) (1=Limited Energy Unit)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") #[Unit]  Must Run Switch (1=Must Run)
  UnNA::VariableArray{1} = ReadDisk(db,"EGOutput/UnNA",year) #[Unit,Year]  Net Asset Value of Generating Unit (M$)
  UnNode::Vector{String} = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  UnOOR::VariableArray{1} = ReadDisk(db,"EGCalDB/UnOOR",year) #[Unit,Year]  Operational Outage Rate (MW/MW)
  UnOR::VariableArray{3} = ReadDisk(db,"EGInput/UnOR",year) #[Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  UnOUEG::VariableArray{1} = ReadDisk(db,"EGOutput/UnOUEG",year) #[Unit,Year]  Own Use Generation (GWh/Yr)
  UnOUGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnOUGC",year) #[Unit,Year]  Own Use Generating Capacity (MW)
  UnOUREG::VariableArray{1} = ReadDisk(db,"EGInput/UnOUREG",year) #[Unit,Year]  Own Use Rate for Generation (GWh/GWh)
  UnOURGC::VariableArray{1} = ReadDisk(db,"EGInput/UnOURGC",year) #[Unit,Year]  Own Use Rate for Generating Capacity (MW/MW)
  UnPCF::VariableArray{1} = ReadDisk(db,"EGOutput/UnPCF",year) #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPCFuu::VariableArray{1} = ReadDisk(db,"EGOutput/UnPCFuu",year) #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
  UnPOCGWh::VariableArray{2} = ReadDisk(db,"EGOutput/UnPOCGWh",year) #[Unit,Poll,Year]  Pollution Coefficient (Tonnes/GWh)
  UnPoTR::VariableArray{1} = ReadDisk(db,"EGOutput/UnPoTR",year) #[Unit,Year]  Pollution Tax Rate ($/MWh)
  UnRAv::VariableArray{1} = ReadDisk(db,"EGInput/UnRAv") #[Unit]  Reserves Available (MW/MW)
  UnRes::VariableArray{1} = ReadDisk(db,"EGOutput/UnRes",year) #[Unit,Year]  Generation while Unit is Forced On to Provide Reserves (GWh)
  UnResFlag::VariableArray{3} = ReadDisk(db,"EGOutput/UnResFlag",year) #[Unit,TimeP,Month,Year]  Flag to Indicate if Unit is Forced On to Provide Reserves (1=Yes)
  UnRetire::VariableArray{1} = ReadDisk(db,"EGInput/UnRetire",year) #[Unit,Year]  Retirement Date (Year)
  UnRRq::VariableArray{1} = ReadDisk(db,"EGInput/UnRRq") #[Unit]  Reserve Requirements (MW/MW)
  UnRSwitch::VariableArray{1} = ReadDisk(db,"EGInput/UnRSwitch") #[Unit]  Switch for Units Forced to Supply Reserve Requirements (1=Yes)
  UnRVCost::VariableArray{2} = ReadDisk(db,"EGOutput/UnRVCost") #[Unit,Month]  Effective Cost of Reserves ($/MWh)
  UnSLDPR::VariableArray{1} = ReadDisk(db,"EGOutput/UnSLDPR",year) #[Unit,Year]  Depreciation (M$/Yr)
  UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") #[Unit]  Storage Switch (1=Storage Unit)
  UnStorCurtailed::VariableArray{3} = ReadDisk(db,"EGOutput/UnStorCurtailed",year) #[Unit,TimeP,Month,Year]  Curtailed Generation used to Recharge Storage (GWh/Yr)
  UnVCost::VariableArray{3} = ReadDisk(db,"EGOutput/UnVCost",year) #[Unit,TimeP,Month,Year]  Bid Price of Power Offered to Spot Market ($/MWh)
  UnVCostUS::VariableArray{1} = ReadDisk(db,"EGOutput/UnVCostUS") #[Unit]  US Unit Variable Cost (US$/GWh)
  UUnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UUnDmd",year) #[Unit,FuelEP,Year]  Endogenous Energy Demands (TBtu)
  UUnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGA",year) #[Unit,Year]  Endogenous Generation (GWh)
  xEMGVCost::VariableArray{1} = ReadDisk(db,"EGInput/xEMGVCost",year) #[Node,Year]  Dispatch Price for Emergency Power ($/MWh)
  xUnEGC::VariableArray{3} = ReadDisk(db,"EGInput/xUnEGC",year) #[Unit,TimeP,Month,Year]  Exogenous Effective Generating Capacity (MW)
  xUnVCost::VariableArray{3} = ReadDisk(db,"EGInput/xUnVCost",year) #[Unit,TimeP,Month,Year]  Exogenous Market Price Bid ($/MWh)
end

include("EDispatchLP.jl")

function GetUnitSets(data::Data,unit)
  (; Area,GenCo,Node,Plant,Unit) = data;
  (; UnArea,UnGenCo,UnNode,UnPlant,Unit) = data;
  #
  # This procedure selects the sets for a particular unit
  #
  gencoindex = Select(GenCo,UnGenCo[unit])
  plantindex = Select(Plant,UnPlant[unit])
  nodeindex = Select(Node,UnNode[unit])
  areaindex = Select(Area,UnArea[unit])

  return gencoindex,plantindex,nodeindex,areaindex

end

function ResetUnitSets(data::Data)

  # Define Procedure ResetUnitSets
  # 
  # Select Area*, GenCo*, Plant*, Node*
  # 
  # End Procedure ResetUnitSets

end

function GetUtilityUnits(data::Data)
  (; CTime) = data
  (; UnCogen,UnCounter,UnOnLine,UnRetire) = data

  UnitsActive = 1:Int(UnCounter)
  UnitsNotCogen = Select(UnCogen,==(0.0))
  UnitsOnline = Select(UnOnLine,<=(CTime))
  UnitsNotRetired = Select(UnRetire,>(CTime))
  UtilityUnits = intersect(UnitsActive,UnitsOnline,UnitsNotRetired,UnitsNotCogen)

  return UtilityUnits

end


function InitializeDispatch(data::Data)
  (; db,year) = data
  (; UnAFC,UnAVC,UnAVCMonth,UnDmd,UnEAV) = data
  (; UnEG,UnEGA,UnEGC,UnEGGross,UnFP,UnGCD) = data
  (; UnGCNet,UnNA,UnOUEG,UnOUGC,UnPCF,UnPCFuu) = data
  (; UnRes,UnResFlag,UnRVCost,UnSLDPR) = data
  (; UnVCost,UUnDmd,UUnEGA) = data


  @. UnAFC = 0
  @. UnAVC = 0
  @. UnAVCMonth = 0
  @. UnDmd = 0
  @. UnEAV = 0
  @. UnEG = 0
  @. UnEGA = 0
  @. UnEGC = 0
  @. UnEGGross = 0
  @. UnFP = 0
  @. UnGCD = 0
  @. UnGCNet = 0
  @. UnNA = 0
  @. UnOUEG = 0
  @. UnOUGC = 0
  @. UnPCF = 0
  @. UnPCFuu = 0
  @. UnRes = 0
  @. UnResFlag = 0
  @. UnRVCost = 0
  @. UnSLDPR = 0
  @. UnVCost = 0
  @. UUnDmd = 0
  @. UUnEGA = 0

  WriteDisk(db,"EGOutput/UnAFC",year,UnAFC)
  WriteDisk(db,"EGOutput/UnAVC",year,UnAVC)
  WriteDisk(db,"EGOutput/UnAVCMonth",year,UnAVCMonth)
  WriteDisk(db,"EGOutput/UnDmd",year,UnDmd)
  WriteDisk(db,"EGOutput/UnEAV",year,UnEAV)
  WriteDisk(db,"EGOutput/UnEG",year,UnEG)
  WriteDisk(db,"EGOutput/UnEGA",year,UnEGA)
  WriteDisk(db,"EGOutput/UnEGC",year,UnEGC)
  WriteDisk(db,"EGOutput/UnEGGross",year,UnEGGross)
  WriteDisk(db,"EGOutput/UnFP",year,UnFP)
  WriteDisk(db,"EGOutput/UnGCD",year,UnGCD)
  WriteDisk(db,"EGOutput/UnGCNet",year,UnGCNet)
  WriteDisk(db,"EGOutput/UnNA",year,UnNA)
  WriteDisk(db,"EGOutput/UnOUEG",year,UnOUEG)
  WriteDisk(db,"EGOutput/UnPCF",year,UnPCF)
  WriteDisk(db,"EGOutput/UnPCFuu",year,UnPCFuu)
  WriteDisk(db,"EGOutput/UnRes",year,UnRes)
  WriteDisk(db,"EGOutput/UnResFlag",year,UnResFlag)
  WriteDisk(db,"EGOutput/UnRVCost",UnRVCost)
  WriteDisk(db,"EGOutput/UnSLDPR",year,UnSLDPR)
  WriteDisk(db,"EGOutput/UnVCost",year,UnVCost)
  WriteDisk(db,"EGOutput/UUnDmd",year,UUnDmd)
  WriteDisk(db,"EGOutput/UUnEGA",year,UUnEGA)

end

function EnergyLimitedCapacity(data::Data,unit,genco,plant,node,area,timep,month)
  (; HoursPerMonth,PkHydSw,UnEAV,UnGC,UnOOR,UnOUREG,UnPlant,UnStorage,UnLimited) = data
  (; UnEGC,UnOURGC,UnOR,AvFactor,HDHours,HDGCFR,UnEAF,UnEG) = data

  #
  # This procedure computes the effective capacity (UnEGC) for
  # units which are energy limited (UnStorage > 0), but which
  # are not peak hydro units
  #
  if (UnStorage[unit] == 1.0) ||
       ((UnPlant[unit] == "PeakHydro") && (PkHydSw == 0)) ||
       (UnLimited[unit] == 1.0)
    
    #
    # For the peak period (TimeP:S=1) the amount of energy available (UnEAV)
    # is capacity (UnGC) times energy availability (UnEAF) times hours in the
    # season (Hours).
    #
    if timep == 1.0
      UnEAV[unit,timep,month] = UnGC[unit]*(1-UnOUREG[unit])*UnEAF[unit,month]*(1-UnOOR[unit])*HoursPerMonth[month]/1000

      #
      # For non-peak periods (TimeP > 1), the amount of energy available
      # (UnEAV) is energy available in previous period (UnEAV(T-1)) minus
      # energy dispatch in previous period (UnEG(T-1)).
      #
    else
      UnEAV[unit,timep,month] = max(UnEAV[unit,timep-1,month]-UnEG[unit,timep-1,month],0)
    end

    #
    # The capacity available to be bid into the market (UnEGC) is the
    # capacity (UnGC) derated by the unscheduled outage rate (UnOR).
    #
    UnEGC[unit,timep,month] = UnGC[unit]*(1-UnOURGC[unit])*(1-UnOR[unit])*(1-UnOOR[unit])*AvFactor[plant,timep,month,area]

    #
    # The amount actually bid (UnEGC) is a policy which is specified as a
    # fraction (HDGCFR) contrained by the energy available (UnEAV).
    #
    UnEGC[unit,timep,month] = min(UnEGC[unit,timep,month]*HDGCFR[plant,genco,node,timep,month],UnEAV[unit,timep,month]/HDHours[timep,month]*1000)

    #
    # If this is Storage unit, then during Light Load Hours, it is being
    # filled and provides reserves for intermittent resources.  Effective
    # capacity (UnEGC) is the level of reserves which can be provided.
    # This code does not work; generation is excessive in the last period.
    #
    # 23.10.02, LJD: commented out in Promula
    #
    #   Do If (UnStorage == 1) and (TimeP:s == TimeP:m)
    #     UnEGC = UnGC*(1-UnOURGC)*(1-UnOR)*(1-UnOOR)*AvFactor*HDGCFR
    #   End Do If
  end

end

function EffectiveCapacity(data::Data,unit,genco,plant,node,area,timep,month)
  (; AvFactor,HDGCFR,UnEGC,UnGC,UnOOR,UnOR,UnOURGC,UnPlant) = data

  #
  # The capacity bid into the market (UnEGC) is the capacity (UnGC)
  # derated by the outage rates (UnOR,UnOOR) and an availability
  # factor (AvFactor) times the fraction bid (HDGCFR).
  #
  if UnPlant[unit] != "PeakHydro"
    UnEGC[unit,timep,month] = UnGC[unit]*
      (1-UnOURGC[unit])*(1-UnOR[unit])*(1-UnOOR[unit])*
      AvFactor[plant,timep,month,area]*HDGCFR[plant,genco,node,timep,month]
  end

end

function ExogEffectiveCapacity(data::Data,unit,timep,month)
  (; db,year) = data
  (; UnEGC,xUnEGC) = data

  #
  # If there is an exogenous input of effective capacity (xUnEGC >= 0),
  # then over write all other calculations and use exogenous value.
  # Jeff Amlin 6/1/09.
  #
  if xUnEGC[unit,timep,month] >= 0
    UnEGC[unit,timep,month] = xUnEGC[unit,timep,month]
  end

end

function InitializeEmergencyPowerCosts(data::Data,timep,month)
  (; Node) = data
  (; HDEmVCost,xEMGVCost) = data

  for node in Select(Node)
    HDEmVCost[node,timep,month] = xEMGVCost[node]
  end

end

function BidPriceCalc(data::Data,unit,genco,plant,node,area,timep,month)
  (; db,year) = data
  (; UnAFC,HDVCFr,UnAVCMonth,UnPoTR,UnVCost,HDFCFR) = data
  # (; RanNum) = data

  #
  # Bid prices (UnVCost) are equal to variables costs (UnAVCMonth) times
  # a fraction (HDVCFR) plus fixed costs (UnAFC) assuming a 75% capacity
  # factor times a fraction (HDFCFR) plus a small random number to break ties.
  # TODO - review why some units are getting NaN value for UnVCost - Jeff Amlin 6/24/25
  #
  @finite_math UnVCost[unit,timep,month] = UnAVCMonth[unit,month]*
    HDVCFr[plant,genco,node,timep,month]+
    UnPoTR[unit]*
    max(1-HDVCFr[plant,genco,node,timep,month],0)+
    (UnAFC[area]/(8760*.75)*1000)*HDFCFR[plant,genco,timep]

  if isnan(UnVCost[unit,timep,month]) == true
    UnVCost[unit,timep,month] = 0.0
  end

  # UnVCost[unit,timep,month] = UnAVCMonth[unit,month]*HDVCFr[plant,genco,node,timep,month]+UnPoTR[unit]*max(1-HDVCFr[plant,genco,node,timep,month],0)+
  #        (UnAFC[area]/(8760*.75)*1000)*HDFCFR[plant,genco,timep]+abs(RanNum)/10000

end

function BidPriceUser(data::Data,unit,timep,month)
  (; db,year) = data
  (; UnVCost,xUnVCost) = data
  # (; RanNum) = data

  UnVCost[unit,timep,month] = xUnVCost[unit,timep,month]
  # UnVCost=xUnVCost+abs(RanNum)/10000

end

function EmergencyPowerCosts(data::Data,unit,node,area,timep,month)
  (; Plant,Power) = data;
  (; HDEmVCost,MCE,UnVCost,xEMGVCost) = data

  ogct = Select(Plant,"OGCT")
  peak = Select(Power,"Peak")
  #
  # Emergency Power is assumed to be available at each node at a cost
  # greater than any of the local bids.
  #
  HDEmVCost[node,timep,month] = min(max(xEMGVCost[node],
                      HDEmVCost[node,timep,month],UnVCost[unit,timep,month]+10.00,MCE[ogct,peak,area]+10.00),
                      MCE[ogct,peak,area]*2)
                      
  if isnan(HDEmVCost[node,timep,month]) == true
    HDEmVCost[node,timep,month] = xEMGVCost[node]
  end

end

function BidPriceToZeroForMustRun(data::Data,unit,timep,month)
  (; UnMustRun,UnVCost) = data

  UnVCost[unit,timep,month] = UnVCost[unit,timep,month]*(1-UnMustRun[unit])

end

function AdjustMustRunBidPrice(data::Data,units,timep,month)
  (; MinBid,UnMustRun,UnVCost) = data
  #
  # Must Run units (UnMustRun=1) are bid in at a little bit less than
  # the minimum bid of all the other units to insure that they are
  # the first dispatched.
  #
  MinBid = minimum(UnVCost[unit,timep,month] for unit in units)
  # @info "Minimum bid is located at: " findmin(UnVCost[:,timep,month])
  # @info "MinBid is: " MinBid
  units_mustrun = findall(UnMustRun .== 1)
  units = intersect(units_mustrun,units)
  for unit in units
    UnVCost[unit,timep,month] = MinBid-0.001
  end

end

function GetUnitsForResReq(data::Data,node)
  (; Node) = data;
  (; UnNode) = data;

  ReserveUnitsSelected = "False"

  UtilUnits = GetUtilityUnits(data)
  unit_node = findall(UnNode .== Node[node])
  units = intersect(UtilUnits,unit_node)

  if length(units) > 0
    ReserveUnitsSelected = "True"
  end

  return units,ReserveUnitsSelected
end

function GetUnitsForResAvail(data::Data,node,timep,month)
  (; Unit) = data;
  (; ExpUVCost,UnVCost) = data;

  units_res,ReserveUnitsSelected = GetUnitsForResReq(data,node)

  ReserveUnitsSelected = "False"

  units_cost = findall(UnVCost[Select(Unit),timep,month] .<= ExpUVCost[month])
  units = intersect(units_cost,units_res)

  if length(units) > 0
    ReserveUnitsSelected = "True"
  end

  return units,ReserveUnitsSelected
end

function InitializeEnergyForStorage(data::Data)
  (; db,year) = data
  (; StorEnergy,StorPurchases) = data

  @. StorEnergy = 0
  @. StorPurchases = 0

  WriteDisk(db,"EGOutput/StorEnergy",year,StorEnergy)
  WriteDisk(db,"EGOutput/StorPurchases",year,StorPurchases)
end

function RechargingRequirements(data::Data,timep,month)
  (; db,year) = data
  (; TimeP) = data
  (; StorEnergy,UnEffStorage,UnEG,UnStorage) = data

  # Read Disk(StorEnergy)

  if timep < length(TimeP)

    units = GetUtilityUnits(data)
    for unit in units
      genco,plant,node,area = GetUnitSets(data,unit)
      if UnStorage[unit] == 1
        StorEnergy[timep,month,node] = StorEnergy[timep,month,node]+
          UnEG[unit,timep,month]/UnEffStorage[unit]
      end
    end
  end

  WriteDisk(db,"EGOutput/StorEnergy",year,StorEnergy)
end

function CurtailedGeneration(data::Data,timep,month)
  (;UnEGCurtailed, UnEGC,UnOOR,HDHours,UnEG,UnCurtailedSwitch) = data;
  
  units = GetUtilityUnits(data)
  for unit in units
    UnEGCurtailed[unit,timep,month]=max(
      (UnEGC[unit,timep,month]/(1-UnOOR[unit])*HDHours[timep,month]/1000-
        UnEG[unit,timep,month])*UnCurtailedSwitch[unit],0)
  end

end

function RechargeWithCurtailed(data::Data,timep,month)
  (; db,year) = data
  (; TimeP) = data
  (; StorEnergy,UnEGCurtailed,UnStorCurtailed,UnEG) = data

  if timep < length(TimeP)

    units = GetUtilityUnits(data)
    for unit in units
      genco,plant,node,area = GetUnitSets(data,unit)
        
        #
        # Determine amount of Curtailed Generation (UnEGCurtailed) which can
        # meet Recharging Requirements (StorEnergy)
        #
        UnStorCurtailed[unit,timep,month] =
          min(StorEnergy[timep,month,node],UnEGCurtailed[unit,timep,month])
          
        #
        # Reduce Curtailed Generaton (UnEGCurtailed) based on amount used
        # to recharge storage (UnStorCurtailed)
        #
        UnEGCurtailed[unit,timep,month] = 
          max(UnEGCurtailed[unit,timep,month]-UnStorCurtailed[unit,timep,month],0)
          
        UnEG[unit,timep,month]=UnEG[unit,timep,month]+UnStorCurtailed[unit,timep,month]
        #
        # Reduce Recharging Requirements (StorEnergy) based on amount used
        # to recharge storage (UnStorCurtailed)
        #
        StorEnergy[timep,month,node] = max(StorEnergy[timep,month,node]-
          UnStorCurtailed[unit,timep,month],0)
    end
  end

  WriteDisk(db,"EGOutput/UnEG",year,UnEG)
  WriteDisk(db,"EGOutput/UnEGCurtailed",year,UnEGCurtailed)
  WriteDisk(db,"EGOutput/UnStorCurtailed",year,UnStorCurtailed)
  WriteDisk(db,"EGOutput/StorEnergy",year,StorEnergy)
end

function RechargeWithPurchases(data::Data,timep,month)
  (; db,year) = data
  (; Node,TimeP) = data
  (; StorEnergy,StorPurchases) = data

  if timep < length(TimeP)
    for node in Select(Node)
      StorPurchases[month,node] = StorPurchases[month,node]+StorEnergy[timep,month,node]
    end
  end

  WriteDisk(db,"EGOutput/StorPurchases",year,StorPurchases)

end

#
# Note: Promula Procedure RunLPForDispatch Replaced
# with ElectricDispatchLP in EDispatchLP.jl
#
function ReserveUnits(data::Data,timep,month)
  (; db,year) = data;
  (; Month,Node,TimeP) = data;
  (; ResAvail,ResNeed,ResReq,ResSupply,UnEGC,UnNode,UnResFlag,UnRVCost,UnVCost) = data;
  (; UnRRq,UnRAv,UnRSwitch,UnAVCMonth) = data;
  ResDeficit::VariableArray = zeros(Float32,length(Month),length(Node))

  #
  # This procedure provides reserves to back-up intermittent resources
  # like wind.  A problem still remains with the transmission system.
  # Are the reserves close enough to the wind?
  #
  if timep == length(TimeP)

    for node in Select(Node)
      
      #
      # Reserve Requirement (ResReq) is the generation of intermittent resources
      # times the reserve requirement (UnRRqFr) for each unit.
      #
      ReserveUnits,ReserveUnitsSelected = GetUnitsForResReq(data,node)

      if ReserveUnitsSelected == "True"
        ResReq[month,node] = sum(UnEGC[unit,timep,month]*UnRRq[unit] for unit in ReserveUnits)
      end

      #
      # Reserves Available (ResAvail) are reserves from units which are expected
      # to be dispatched since their costs (UnVCosts) are less than the expected
      # costs (ExpVCosts).  These would be resources from standard baseload units
      # like hydro, nuclear, coal, pumped storage, and other storage.
      #
      ReserveUnits,ReserveUnitsSelected = GetUnitsForResAvail(data,node,timep,month)

      if ReserveUnitsSelected == "True"
        ResAvail[month,node] = sum(UnEGC[unit,timep,month]*UnRAv[unit] for unit in ReserveUnits)
      end

      #
      # Reserves Needed (ResNeed) to be forced on
      #
      ResNeed[month,node] = ResReq[month,node]-ResAvail[month,node]

      #
      # The remaining level of reserves needed (ResNeed) must now be met by
      # forcing plants with reserves (UnRAv) to be run during this time
      # period (probably a light load hour).  The plants are selected based
      # on their ability to provide reserves (UnRAv) and their variable
      # costs (UnAVCMonth).
      #

      ResSupply[month,node] = 0
      unit_util = GetUtilityUnits(data)
      unit_node = findall(UnNode .== Node[node])
      unit_rsw = findall(UnRSwitch .== 1)
      unit_rav = findall(UnRAv .> 0)
      units = intersect(unit_util,unit_node,unit_rsw,unit_rav)
      @. UnRVCost[units,month] = UnAVCMonth[units,month]/UnRAv[units]
      units = units[sortperm(UnRVCost[units,month],rev = true)]
      for unit in units
        
        #
        # Force units to run by dispatching at a zero cost
        #
        if ResNeed[month,node] > ResSupply[month,node]
          UnVCost[unit,timep,month] = 0
          UnResFlag[unit,timep,month] = 1
          ResSupply[month,node] = ResSupply[month,node]+UnEGC[unit,timep,month]*UnRAv[unit]
        end
      end
      
      #
      # If there are insufficient reserves (ResNeed > ResSupply), then
      # back off the units which require reserves (UnRRq).
      #
      unit_util = GetUtilityUnits(data)
      unit_node = findall(UnNode .== Node[node])
      unit_rrq = findall(UnRRq .> 1)
      units = intersect(unit_util,unit_node,unit_rrq)
      if length(units) > 0
        @. @finite_math UnRVCost[units,month] = UnAVCMonth[units,month]/UnRAv[units]
        units = units[sortperm(UnRVCost[units, month], rev = true)]
        ResDeficit[month,node] = ResNeed[month,node]-ResSupply[month,node]
        for unit in units
          if ResDeficit[month,node] > 0
            ResDeficit[month,node] -= UnEGC[unit]*UnRRq[unit]
            UnEGC[unit] = 0
          end
        end # unit
      end # length(units)
    end # node

    WriteDisk(db,"EGOutput/ResAvail",year,ResAvail)
    WriteDisk(db,"EGOutput/ResNeed",year,ResNeed)
    WriteDisk(db,"EGOutput/ResReq",year,ResReq)
    WriteDisk(db,"EGOutput/ResSupply",year,ResSupply)
    WriteDisk(db,"EGOutput/UnEGC",year,UnEGC)
    WriteDisk(db,"EGOutput/UnResFlag",year,UnResFlag)
    WriteDisk(db,"EGOutput/UnRVCost",UnRVCost)
    WriteDisk(db,"EGOutput/UnVCost",year,UnVCost)

  end # End Do If TimeP:s

end

function UnitBids(data::Data,timep,month)
  (; db,year) = data
  (; BlkSw,HDEmVCost,UnVCost,xUnVCost,UnMustRun) = data

  # @info "  EDispatch.jl - UnitBids - Electric Generation Spot Market Bids"

  #
  # This procedure computes the amount and bid price of the blocks
  # of power offered to the spot market.
  #
  # BlkSw = 1 - Prices are based on HDVCFR and HDFCFR
  # BlkSw = 0 - Prices are exogenous (xUnVCost)
  #

  # Read Disk(HDFCFR)
  # Read Disk(HDVCFr)
  # Read Disk(xUnVCost)

  InitializeEmergencyPowerCosts(data,timep,month)

  units = GetUtilityUnits(data)
  for unit in units
    genco,plant,node,area = GetUnitSets(data,unit)
    if xUnVCost[unit,timep,month] == -99
      #
      # If spot bidding switch (BlkSw) equals 1, then spot bids are
      # based on user specified fractions.
      #
      if (BlkSw[area] == 1)
        BidPriceCalc(data,unit,genco,plant,node,area,timep,month)
        #
        # Else if spot bidding switch (BlkSw) equals 0, then spot bids (UnVCost)
        # are user specfied (xUnVCost).
        #
      else (BlkSw[area] == 0)
        BidPriceUser(data,unit,timep,month)
      end

      EmergencyPowerCosts(data,unit,node,area,timep,month)
      BidPriceToZeroForMustRun(data,unit,timep,month)
      #
      # 23.10.02, LJD: Commented out in Promula.
      #
      #  Else xUnVCost < 10
      #   UnVCost=UnAVCMonth*xUnVCost
      #
    else
      UnVCost[unit,timep,month] = xUnVCost[unit,timep,month]
    end
  end

  AdjustMustRunBidPrice(data,units,timep,month)

  WriteDisk(db,"EGOutput/UnVCost",year,UnVCost)
  WriteDisk(db,"EGOutput/HDEmVCost",year,HDEmVCost)

end

function EmergencyPowerAvailibility(data::Data,month,node)
  (; db,year) = data
  (; Area,Day) = data
  (; HDEmGC,LDCMS) = data

  peak = Select(Day,"Peak")

  #
  # Emergency Power is assumed to be available at each node at a cost
  # greater than any of the local bids.
  #
  HDEmGC[node] = sum(LDCMS[peak,month,node,area] for area in Select(Area))

end

function UnitCapacityAvailibility(data::Data,timep,month)
  (; db,year) = data
  (; HDEmGC,UnEAV,UnEGC) = data

  # @info "  EDispatch.jl - UnitCapacityAvailibility"

  units = GetUtilityUnits(data)
  for unit in units
    genco,plant,node,area = GetUnitSets(data,unit)
    EffectiveCapacity(data,unit,genco,plant,node,area,timep,month)
    EnergyLimitedCapacity(data,unit,genco,plant,node,area,timep,month)
    ExogEffectiveCapacity(data,unit,timep,month)
    EmergencyPowerAvailibility(data,month,node)
  end

  WriteDisk(db,"EGOutput/UnEGC",year,UnEGC)
  WriteDisk(db,"EGOutput/UnEAV",year,UnEAV)
  WriteDisk(db,"EGOutput/HDEmGC",year,HDEmGC)

end

function IncreaseLoadsForRecharging(data::Data,timep,month)
  (; db,year) = data
  (; Node,TimeP) = data
  (; HDADP,HDADPwithStorage,HDHours,StorPurchases) = data

  if timep == length(TimeP)
    #
    # In the last time period we need to add the energy required
    # (StorEnergy) to recharge the storage generation technologies (pumped storage,
    # batteries, etc) to the nodal demand (HDADP)
    #
    for node in Select(Node)
      HDADPwithStorage[node,timep,month] = HDADP[node,timep,month]+StorPurchases[month,node]/HDHours[timep,month]*1000
    end
  else
    #
    # In the other time periods we simple use the average demands (HDADP)
    #
    for node in Select(Node)
      HDADPwithStorage[node,timep,month] = HDADP[node,timep,month]
    end
  end

  WriteDisk(db,"EGOutput/HDADPwithStorage",year,HDADPwithStorage)
end

function TimePeriodFractionsOfElectricDemand(data::Data)
  (; db,year) = data
  (; Month,Node,TimeP) = data
  (; DmdFraction,DmdRemaining,HDADP,HDHours) = data
  DmdRunning::VariableArray{1} = zeros(Float32,length(Node)) # Running Fraction of Annual Electricity Demand in Remaining Time Period (GWh/GWh)
  SumNode::VariableArray{1} = zeros(Float32,length(Node))

  for node in Select(Node)
    SumNode[node] = sum(HDADP[node,timep,month]*HDHours[timep,month] for month in Select(Month), timep in Select(TimeP))
  end

  for month in Select(Month), timep in Select(TimeP), node in Select(Node)
    DmdFraction[node,timep,month] = HDADP[node,timep,month]*HDHours[timep,month]/SumNode[node]
  end

  WriteDisk(db,"EGOutput/DmdFraction",year,DmdFraction)

  @. DmdRunning = 1.00
  for month in Select(Month), timep in Select(TimeP), node in Select(Node)
      DmdRemaining[node,timep,month] = DmdRunning[node]
      DmdRunning[node] = DmdRunning[node]-DmdFraction[node,timep,month]
  end

  WriteDisk(db,"EGOutput/DmdRemaining",year,DmdRemaining)

end

function AvaliablePollutionLimits(data::Data)
  (; db,year) = data
  (; Area,ECC,FuelEP,Plant,Poll) = data;
  (; EUPolGHGPrior,EUEuPolPrior,MEPolPrior,PolConv) = data
  (; PollAvailable,PollAvailablePrior,PollLimitGHGFlag) = data
  (; PollLimitGHGFlagPrior,PollutionLimit) = data


  ecc = Select(ECC,"UtilityGen")
  co2 = Select(Poll,["CO2"])
  ghg = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])

  for area in Select(Area)
    EUPolGHGPrior[area] = sum(EUEuPolPrior[fuelep,plant,poll,area]*PolConv[poll] for poll in ghg, plant in Select(Plant), fuelep in Select(FuelEP))+
                        sum(MEPolPrior[ecc,poll,area]*PolConv[poll] for poll in ghg)
  end

  for area in Select(Area)
    #
    # Annual Pollution Limits (PollLimitGHGFlag=1)
    #
    if PollLimitGHGFlag[area] == 1
      for poll in Select(Poll)
        PollAvailable[poll,area] = PollutionLimit[poll,area]
      end

    #
    # Cumulative Pollultion Limits (PollLimitGHGFlag=2)
    #
    elseif (PollLimitGHGFlag == 2) && (PollLimitGHGFlagPrior == 2)
      for poll in co2
        PollAvailable[poll,area] = PollAvailablePrior[poll,area]-EUPolGHGPrior[area]+PollutionLimit[poll,area]
      end
    elseif (PollLimitGHGFlag == 2) && (PollLimitGHGFlagPrior == 0)
      for poll in Select(Poll)
        PollAvailable[poll,area] = PollutionLimit[poll,area]
      end
    end
  end

  WriteDisk(db,"EGOutput/PollAvailable",year,PollAvailable)
end

function InitializePollutionLimits(data::Data)
  (; db,year) = data
  (; Area,Node,Poll) = data
  (; ArNdFr,PollAvailable,PollRemaining) = data

  for poll in Select(Poll), node in Select(Node)
    PollRemaining[poll,node] = sum(PollAvailable[poll,area]*ArNdFr[area,node] for area in Select(Area))
  end
end

function AllocatePollutionLimits(data::Data,timep,month)
  (; db,year) = data
  (; Node,Poll) = data
  (; DmdFraction,DmdRemaining,PollLimit,PollRemaining) = data

  for node in Select(Node), poll in Select(Poll)
    PollLimit[poll,timep,month,node] = max(PollRemaining[poll,node]*DmdFraction[node,timep,month]/DmdRemaining[node,timep,month],0)
  end

  WriteDisk(db,"EGOutput/PollLimit",year,PollLimit)

end

function UpdatePollutionLimits(data::Data,timep,month)
  (; db,year) = data
  (; Node,Poll) = data
  (; PollActual,PollRemaining,UnEG,UnPOCGWh) = data

  for node in Select(Node), poll in Select(Poll)
    PollActual[poll,timep,month,node] = 0
  end

  units = GetUtilityUnits(data)
  for unit in units
    genco,plant,node,area = GetUnitSets(data,unit)
    for poll in Select(Poll)
      PollActual[poll,timep,month,node] = PollActual[poll,timep,month,node]+max(UnEG[unit,timep,month]*UnPOCGWh[unit,poll],0)
    end
  end

  for node in Select(Node), poll in Select(Poll)
    PollRemaining[poll,node] = max(PollRemaining[poll,node]-PollActual[poll,timep,month,node],0)
  end

  WriteDisk(db,"EGOutput/PollActual",year,PollActual)
end

function DispatchElectricity(data::Data)
  (; Month,TimeP) = data

  # @info "  EDispatch.jl - DispatchElectricity"

  TimePeriodFractionsOfElectricDemand(data)
  AvaliablePollutionLimits(data)
  InitializePollutionLimits(data)
  InitializeEnergyForStorage(data)

  for month in Select(Month), timep in Select(TimeP)
    AllocatePollutionLimits(data,timep,month)
    IncreaseLoadsForRecharging(data,timep,month)
    UnitCapacityAvailibility(data,timep,month)
    UnitBids(data,timep,month)
    ReserveUnits(data,timep,month)
    ElectricDispatchLP(data,timep,month) # Note this function is defined in EDispatchLP.jl
    RechargingRequirements(data,timep,month)
    CurtailedGeneration(data,timep,month)
    RechargeWithCurtailed(data,timep,month)
    RechargeWithPurchases(data,timep,month)
    UpdatePollutionLimits(data,timep,month)
  end

end

end # module EDispatch
