#
# ElectricExpansion.jl
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


Base.@kwdef struct ElectricExpansionData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  Areas::Vector{Int}    = collect(Select(Area))
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Class::SetArray  = ReadDisk(db, "MainDB/Class")
  ClassDS::SetArray  = ReadDisk(db, "MainDB/ClassDS")
  Classes::Vector{Int}    = collect(Select(Class))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCs::Vector{Int}     = collect(Select(ECC))
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db, "MainDB/NodeX")
  NodeXDS::SetArray = ReadDisk(db, "MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Power::SetArray = ReadDisk(db, "MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db, "MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db, "MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation (Map)
  AreaPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/AreaPurchases") # [Area,Year] Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{2} = ReadDisk(db, "EGOutput/AreaSales") # [Area,Year] Sales to Areas in the same Country (GWh/Yr)
  BFracMax::VariableArray{2} = ReadDisk(db, "EGInput/BFracMax") # [Area,Year] Maximum Fraction of Capacity Built Endogenously (MW/MW)
  BsBdFr::VariableArray{3} = ReadDisk(db, "EGInput/BsBdFr") # [Power,Area,Year] Base Build Fraction (Fraction)
  BFraction::VariableArray{4} = ReadDisk(db, "EGOutput/BFraction") # [Power,Node,Area,Year] Endogenous Build Fraction (MW/MW)
  BuildFr::VariableArray{2} = ReadDisk(db, "EGInput/BuildFr") # [Area,Year] Building fraction
  BuildSw::VariableArray{2} = ReadDisk(db, "EGInput/BuildSw") # [Area,Year] Build switch
  CgInv::VariableArray{3} = ReadDisk(db, "SOutput/CgInv") # [ECC,Area,Year] Cogeneration Investments (M$/Yr)
  CapCredit::VariableArray{3} = ReadDisk(db, "EGInput/CapCredit") # [Plant,Area,Year] Capacity Credit (MW/MW)
  CD::VariableArray{2} = ReadDisk(db, "EGInput/CD") # [Plant,Year] Construction Delay (YEARS)
  CUCFr::VariableArray{2} = ReadDisk(db, "EGOutput/CUCFr") # [Node,Year] Capacity Under Construction as Fraction of Capacity (MW/MW)
  CUCLimit::VariableArray{1} = ReadDisk(db, "EGInput/CUCLimit") # [Year] Build Decision Capacity Under Construction Limit (MW/MW)
  CUCMlt::VariableArray{2} = ReadDisk(db, "EGOutput/CUCMlt") # [Node,Year] Build Decision Capacity Under Construction Constraint
  DesHr::VariableArray{4} = ReadDisk(db, "EGInput/DesHr") # [Plant,Power,Area,Year] Design Hours (Hours)
  DInv::VariableArray{3} = ReadDisk(db, "SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  DInvEU::VariableArray{3} = ReadDisk(db, "EGOutput/DInvEU") # [Fuel,Area,Year] Device Investments (M$/Yr)
  DRM::VariableArray{2} = ReadDisk(db, "EInput/DRM") # [Node,Year] Desired Reserve Margin (MW/MW)
  ECCCLMap::VariableArray{2} = ReadDisk(db, "MainDB/ECCCLMap") #[ECC,Class]  Map Between ECC and Class (map)
  EGPA::VariableArray{3} = ReadDisk(db, "EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  EGPACurtailed::VariableArray{3} = ReadDisk(db, "EGOutput/EGPACurtailed") # [Plant,Area,Year] Curtailed Electric Generation (GWh/Yr)
  EmEGA::VariableArray{4} = ReadDisk(db, "EGOutput/EmEGA") # [Node,TimeP,Month,Year] Emergency Generation (GWh)
  EUPOCX::VariableArray{5} = ReadDisk(db, "EGOutput/EUPOCX") # [FuelEP,Plant,Poll,Area,Year] Electric Utility Pollution Coefficient (Tonnes/TBtu)
  Expend::VariableArray{3} = ReadDisk(db, "SOutput/Expend") # [ECC,Area,Year] Expenditures (M$/Yr)
  ExpPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/ExpPurchases") # [Area,Year] Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db, "EGOutput/ExpSales") # [Area,Year] Sales to Areas in a different Country (GWh/Yr)
  FlInv::VariableArray{3} = ReadDisk(db, "SOutput/FlInv") # [ECC,Area,Year] Flaring Reduction Investments (M$/Yr)
  FlPExp::VariableArray{3} = ReadDisk(db, "SOutput/FlPExp") # [ECC,Area,Year] Flaring Reduction Private Expenses (M$/Yr)
  FuelExpenditures::VariableArray{3} = ReadDisk(db, "SOutput/FuelExpenditures") # [ECC,Area,Year] Fuel Expenditures (M$)
  FuInv::VariableArray{3} = ReadDisk(db, "SOutput/FuInv") # [ECC,Area,Year] Other Fugitives Reduction Investments (M$/Yr)
  FuOMExp::VariableArray{3} = ReadDisk(db, "SOutput/FuOMExp") # [ECC,Area,Year] Other Fugitives Reduction O&M Expenses (M$/Yr)
  GCCC::VariableArray{3} = ReadDisk(db, "EGOutput/GCCC") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
  GCCCM::VariableArray{3} = ReadDisk(db, "EGOutput/GCCCM") # [Plant,Area,Year] Capital Cost Multiplier ($/$)
  GCCCN::VariableArray{3} = ReadDisk(db, "EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
  # GCCI::VariableArray{3} = ReadDisk(db, "EGOutput/GCCI") # [Plant,GenCo,Year] Capacity Initiation Rate (MW)
  GCCR::VariableArray{4} = ReadDisk(db, "EGOutput/GCCR") # [Plant,Node,GenCo,Year] Capacity Completion Rate (MW/Yr)
  GCDev::VariableArray{4} = ReadDisk(db, "EGOutput/GCDev") # [Plant,Node,Area,Year] Generation Capacity Developed (MW)
  GCExpSw::VariableArray{3} = ReadDisk(db, "EGInput/GCExpSw") # [Plant,Area,Year] Generation Capacity Expansion Switch
  GCPA::VariableArray{3} = ReadDisk(db, "EOutput/GCPA") # [Plant,Area,Year] Generation Capacity (MW)
  GCPot::VariableArray{4} = ReadDisk(db, "EGOutput/GCPot") # [Plant,Node,Area,Year] Maximum Potential Generation Capacity (MW)
  GrMSF::VariableArray{4} = ReadDisk(db, "EGOutput/GrMSF") # [Plant,Node,Area,Year] Green Power Market Share (MW/MW)
  HDADPwithStorage::VariableArray{4} = ReadDisk(db, "EGOutput/HDADPwithStorage") # [Node,TimeP,Month,Year] Average Load in Interval with Generation to Fill Storage (MW)
  HDEmMDS::VariableArray{4} = ReadDisk(db, "EGOutput/HDEmMDS") # [Node,TimeP,Month,Year] Emergency Power Dispatched (MW)
  HDEnergy::VariableArray{4} = ReadDisk(db, "EGOutput/HDEnergy") # [Node,TimeP,Month,Year] Energy in Interval (GWh)
  HDFlowFr::VariableArray{3} = ReadDisk(db, "EGInput/HDFlowFr") # [Node,NodeX,Year] Fraction of Power Contracts in Firm Capacity (MW/MW)
  HDGCCI::VariableArray{5} = ReadDisk(db, "EGOutput/HDGCCI") # [Plant,Node,GenCo,Area,Year] New Capacity Initiated (MW)
  HDGCCR::VariableArray{2} = ReadDisk(db,"EGOutput/HDGCCR") #[Node,Year]  Firm Generating Capacity being Revised (MW)
  HDHrMn::VariableArray{2} = ReadDisk(db, "EInput/HDHrMn") # [TimeP,Month] Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db, "EInput/HDHrPk") # [TimeP,Month] Peak Hour in the Interval (Hour)
  HDInflow::VariableArray{2} = ReadDisk(db, "EGOutput/HDInflow") # [Node,Year] Firm Capacity from Inflows in Power Contracts (MW)
  HDIPGC::VariableArray{5} = ReadDisk(db, "EGOutput/HDIPGC") # [Power,Node,GenCo,Area,Year] Indicated Planned Generation Capacity (MW)
  HDLLoad::VariableArray{5} = ReadDisk(db, "EGOutput/HDLLoad") # [Node,NodeX,TimeP,Month,Year] Loading on Transmission Lines (MW)
  HDOutflow::VariableArray{2} = ReadDisk(db, "EGOutput/HDOutflow") # [Node,Year] Firm Requirements from Outflows in Power Contracts (MW)
  HDPrDP::VariableArray{3} = ReadDisk(db, "EGOutput/HDPrDP") # [Power,Node,Year] Decision Price for New Construction ($/MWh)
  HDCgGC::VariableArray{2} = ReadDisk(db, "EGOutput/HDCgGC") # [Node,Year] Firm Cogeneration Capacity Sold to Grid (MW)
  HDCUC::VariableArray{2} = ReadDisk(db, "EGOutput/HDCUC") # [Node,Year] Firm Capacity under Construction (MW)
  HDFGC::VariableArray{2} = ReadDisk(db, "EGOutput/HDFGC") # [Node,Year] Forecasted Firm Generation Capacity (MW)
  HDGC::VariableArray{2} = ReadDisk(db, "EGOutput/HDGC") # [Node,Year] Firm Generating Capacity in Previous Year (MW)
  HDGR::VariableArray{2} = ReadDisk(db, "EGOutput/HDGR") # [Node,Year] Forecasted Peak Growth Rate
  HDPDP::VariableArray{4} = ReadDisk(db, "EGOutput/HDPDP") # [Node,TimeP,Month,Year] Peak (Highest) Load in Interval (MW)
  HDPDP1::VariableArray{2} = ReadDisk(db, "EGOutput/HDPDP1") # [Node,Year] Annual Peak Load (MW)
  HDRetire::VariableArray{2} = ReadDisk(db, "EGOutput/HDRetire") # [Node,Year] Firm Generating Capacity being Retired (MW)
  HDRM::VariableArray{2} = ReadDisk(db, "EGOutput/HDRM") # [Node,Year] Reserve Margin (MW/MW)
  HDRQ::VariableArray{2} = ReadDisk(db, "EGOutput/HDRQ") # [Node,Year] Hourly Dispatch Forecasted Generation Requirements
  HDXLoad::VariableArray{5} = ReadDisk(db, "EGInput/HDXLoad") # [Node,NodeX,TimeP,Month,Year] Power Contracts over Transmission Lines (MW)
  HMPr::VariableArray{4} = ReadDisk(db, "EOutput/HMPr") # [Area,TimeP,Month,Year] Spot Market Price ($/MWh)
  HMPrA::VariableArray{2} = ReadDisk(db, "EOutput/HMPrA") # [Area,Year] Average Spot Market Price ($/MWh)
  HRtM::VariableArray{3} = ReadDisk(db, "EGInput/HRtM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  IPGCCI::VariableArray{5} = ReadDisk(db, "EGOutput/IPGCCI") # [Plant,Node,GenCo,Area,Year] Intermittent Power Capacity Initiated (MW)
  IPGCPr::VariableArray{5} = ReadDisk(db, "EGOutput/IPGCPr") # [Power,Node,GenCo,Area,Year] Capacity Built based on Spot Market Prices (MW)
  IPGCRM::VariableArray{5} = ReadDisk(db, "EGOutput/IPGCRM") # [Power,Node,GenCo,Area,Year] Capacity Built based on Reserve Margin (MW)
  LLMax::VariableArray{5} = ReadDisk(db, "EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
  MCE::VariableArray{4} = ReadDisk(db, "EOutput/MCE") # [Plant,Power,Area,Year] Cost of Energy from New Capacity ($/MWh)
  MEInv::VariableArray{3} = ReadDisk(db, "SOutput/MEInv") # [ECC,Area,Year] Non Energy Reduction Investments (M$/Yr)
  MEOMExp::VariableArray{3} = ReadDisk(db, "SOutput/MEOMExp") # [ECC,Area,Year] Non Energy Reduction O&M Expenses(M$/Yr)
  MFC::VariableArray{3} = ReadDisk(db, "EOutput/MFC") # [Plant,Area,Year] Marginal Fixed Costs ($/KW)
  MoneyUnitDS::Array{String} = ReadDisk(db, "MInput/MoneyUnitDS") # [Area] Descriptor for Monetary Units Type=String(15)
  MVC::VariableArray{3} = ReadDisk(db, "EOutput/MVC") # [Plant,Area,Year] Marginal Variable Costs ($/MWh)
  NdArMap::VariableArray{2} = ReadDisk(db, "EGInput/NdArMap") # [Node,Area] Map between Node and Area
  NdNMap::VariableArray{2} = ReadDisk(db, "EGInput/NdNMap") # [Node,Nation] Map between Node and Nation
  NdXArMap::VariableArray{2} = ReadDisk(db, "EGInput/NdXArMap") # [NodeX,Area] Map between NodeX and Area
  NodeSw::VariableArray{1} = ReadDisk(db, "EGInput/NodeSw") # [Node] Switch to indicate if Node is Active (1=Active)
  OMExp::VariableArray{3} = ReadDisk(db, "SOutput/OMExp") # [ECC,Area,Year] O&M Expenditures (M$)
  ORNew::VariableArray{5} = ReadDisk(db, "EGInput/ORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  PE::VariableArray{3} = ReadDisk(db, "SOutput/PE") # [ECC,Area,Year] Endogenous Electricity Price ($/MWh)
  PermitExpenditures::VariableArray{3} = ReadDisk(db, "SOutput/PermitExpenditures") # [ECC,Area,Year] Permits Expenditures (M$/Yr)
  PExp::VariableArray{4} = ReadDisk(db, "SOutput/PExp") # [ECC,Poll,Area,Year] Permits Expenditures (M$/Yr)
  PExpExo::VariableArray{4} = ReadDisk(db, "SInput/PExpExo") # [ECC,Poll,Area,Year] Exogenous Permits Expenditures (M$/Year)
  PRExp::VariableArray{4} = ReadDisk(db, "SOutput/PRExp") # [ECC,Poll,Area,Year] Pollution Reduction Private Expenses (M$/Yr)
  PRExpenditures::VariableArray{3} = ReadDisk(db, "SOutput/PRExpenditures") # [ECC,Area,Year] Pollution Reduction Expenditures (M$/Yr)
  PFFrac::VariableArray{4} = ReadDisk(db, "EGInput/PFFrac") # [Plant,FuelEP,Area,Year] Fuel Usage Fraction (Btu/Btu)
  PInv::VariableArray{3} = ReadDisk(db, "SOutput/PInv") # [ECC,Area,Year] Process Investments (M$/Yr)
  PInvTemp::VariableArray{3} = ReadDisk(db, "EGOutput/PInvTemp") # [Fuel,Area,Year] Process Investments (M$/Yr)
  PjMax::VariableArray{2} = ReadDisk(db, "EGInput/PjMax") # [Plant,Area] Maximum Plant Size (MW)
  PjMnPS::VariableArray{2} = ReadDisk(db, "EGInput/PjMnPS") # [Plant,Area] Minimum Plant Size (MW)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  POMExp::VariableArray{3} = ReadDisk(db, "SOutput/POMExp") # [ECC,Area,Year] Process O&M Expenditures (M$)
  Portfolio::VariableArray{5} = ReadDisk(db, "EGInput/Portfolio") # [Plant,Power,Node,Area,Year] Portfolio Fraction of New Capacity (MW/MW)
  PoTRNew::VariableArray{3} = ReadDisk(db, "EGOutput/PoTRNew") # [Plant,Area,Year] Emission Cost for New Plants ($/MWh)
  PrDiFr::VariableArray{3} = ReadDisk(db, "EGInput/PrDiFr") # [Power,Area,Year] Price Differential Fraction (Fraction)
  PriceDiff::VariableArray{4} = ReadDisk(db, "EGOutput/PriceDiff") # [Power,Node,Area,Year] Difference between Spot Market Price and Price of New Capacity
  RnCosts::VariableArray{2} = ReadDisk(db, "EOutput/RnCosts") # [Area,Year] Renewable RECs Costs ($)
  RnGCCI::VariableArray{5} = ReadDisk(db, "EGOutput/RnGCCI") # [Plant,Node,GenCo,Area,Year] Renewable Capacity Initiated (MW)
  RnGen::VariableArray{2} = ReadDisk(db, "EGOutput/RnGen") # [Area,Year] Renewable Current Level of Generation (GWh/Yr)
  RnGoal::VariableArray{2} = ReadDisk(db, "EGOutput/RnGoal") # [Area,Year] Renewable Generation Goal for Construction (GWh/Yr)
  SaEC::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") # [ECC,Area,Year] Electricity Sales (GWh/Yr)
  SqInv::VariableArray{3} = ReadDisk(db, "SOutput/SqInv") # [ECC,Area,Year] Sequestering Investments (M$/Yr)
  SqOMExp::VariableArray{3} = ReadDisk(db, "SOutput/SqOMExp") # [ECC,Area,Year] Sequestering O&M Expenses (M$/Yr)
  TaxExp::VariableArray{4} = ReadDisk(db, "SOutput/TaxExp") # [Fuel,ECC,Area,Year] Tax Expenditure (M$)
  TDInv::VariableArray{2} = ReadDisk(db, "SOutput/TDInv") # [Area,Year] Electric Transmission and Distribution Investments (M$/Yr)
  TotPol::VariableArray{4} = ReadDisk(db, "SOutput/TotPol") # [ECC,Poll,Area,Year] Pollution (Tonnes/Yr)
  TPRMap::VariableArray{2} = ReadDisk(db, "EGInput/TPRMap") # [TimeP,Power] TimeP to Power Map
  UFOMC::VariableArray{3} = ReadDisk(db, "EGInput/UFOMC") # [Plant,Area,Year] Unit Fixed O&M Costs ($/KW)
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") # [Unit] Industrial Generation Switch (1=Industrial Generation)
  UnEGC::VariableArray{4} = ReadDisk(db, "EGOutput/UnEGC") # [Unit,TimeP,Month,Year] Effective Generating Capacity (MW)
  UnNode::Array{String} = ReadDisk(db, "EGInput/UnNode") # [Unit] Transmission Node Type=String(15)
  UOMC::VariableArray{3} = ReadDisk(db, "EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs ($/MWh)
  VnInv::VariableArray{3} = ReadDisk(db, "SOutput/VnInv") # [ECC,Area,Year] Venting Reduction Investments (M$/Yr)
  VnOMExp::VariableArray{3} = ReadDisk(db, "SOutput/VnOMExp") # [ECC,Area,Year] Venting Reduction O&M Expenses (M$/Yr)
  WCC::VariableArray{2} = ReadDisk(db, "EGInput/WCC") # [Area,Year] Weighted Cost of Capital (1/Yr)
  xGCPot::VariableArray{4} = ReadDisk(db, "EGInput/xGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
  xPRExp::VariableArray{4} = ReadDisk(db, "SInput/xPRExp") # [ECC,Poll,Area,Year] Exogenous Reduction Private Expenses (Million $/Yr)

  # Scratch variables
  FlowPot::VariableArray{1} = zeros(Float32, size(Year,1)) # Transmission Load Potential (MW)
  ZZZ::VariableArray{1} = zeros(Float32, size(Year,1))
  TTT::VariableArray{1} = zeros(Float32, size(Year,1)) # Total
  SSS::VariableArray{1} = zeros(Float32, size(Year,1)) # Subtotal
  years = collect(Yr(1990):Yr(2050))
  MCELowest::VariableArray{2} = zeros(Float32, size(Power,1), size(Year,1)) # Lowest Cost of Energy from New Capacity ($/MWh)
end



function TopOfFile(data, iob, FileKey, TitleName)
  (; Year) = data
  (; years, SceName) = data
  # @info "TopOfFile"
  #
  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "This is the Electricity Capacity Expansion Summary.\n")
  #
  println(iob, "Year;;    ", join(Year[years], ";    "), "\n")
  return iob
end

function ShowData(data, iob, area, TitleName, node)
  (; AreaDS, ECC, ECCs, ECCDS, Fuels, FuelDS, GenCos, Months, Node, NodeDS, Plants, PlantDS,
    PowerDS, Powers, TimePs, Year, Class, Classes, ClassDS, Power, MonthDS, Units, NodeXs,
    Unit, NodeXDS) = data
  (; CDTime, CDYear, Expend, Inflation, MoneyUnitDS, PolConv, Polls, TotPol, years, ZZZ,
    PE, SaEC, HMPrA, EmEGA, HDGCCI, RnGCCI, IPGCCI, HDIPGC, IPGCRM, IPGCPr, HDRM, DRM, BuildSw,
    HDPDP1, HDRQ, HDFGC, HDGC, HDGCCR, HDCUC, HDRetire, HDOutflow, HDInflow, HDCgGC, GCPA, EGPA,
    BuildFr, BFraction, PriceDiff, HDPrDP, GCPot, GCDev, GCExpSw, MCE, MCELowest, BsBdFr, PrDiFr,
    BFracMax, CUCMlt, CUCFr, CUCLimit, HDGR, PInvTemp, FuelExpenditures, OMExp, TDInv, DInvEU, TTT,
    SSS, GCCR, ECCCLMap, AreaPurchases, AreaSales, ExpPurchases, ExpSales, EGPACurtailed, CapCredit,
    Portfolio, HDHrPk, HDHrMn, HDPDP, HDADPwithStorage, UnEGC, UnNode, UnCogen, HMPr, NdXArMap,
    FlowPot, LLMax, HDLLoad, Nodes, HDXLoad,SceName) = data

  #
  # Goals
  #
  ug_ecc = Select(ECC, "UtilityGen")
  print(iob, "$TitleName $(ECCDS[ug_ecc]) Expenditures (Millions $CDTime $(MoneyUnitDS[area])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(Expend[ecc,area,year] for ecc in ug_ecc, area in area)/
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "Expend;$(ECCDS[ug_ecc])")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Total Pollution (eCO2 MT/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(TotPol[ecc,poll,area,year] * PolConv[poll]
      for ecc in ECCs, poll in Polls, area in area)/1e6
  end
  print(iob, "TotPol;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  ug_ecc = Select(ECC, "UtilityGen")
  print(iob, "$TitleName $(ECCDS[ug_ecc]) Pollution (eCO2 MT/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(TotPol[ecc,poll,area,year] * PolConv[poll]
      for ecc in ug_ecc, poll in Polls, area in area)/1e6
  end
  print(iob, "TotPol;$(ECCDS[ug_ecc])")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Average Retail Electricity Price ($CDTime $(MoneyUnitDS[area])/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(PE[ecc,area,year].*SaEC[ecc,area,year] for ecc in ECCs) /
      sum(SaEC[ecc,area,year] for ecc in ECCs) / Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "PE;Average")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Electric Wholesale Price ($CDTime $(MoneyUnitDS[area])/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HMPrA[area,year] / Inflation[area,year] * Inflation[area,CDYear]
  end  
  print(iob, "HMPrA;Average")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Emergency Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(EmEGA[node,timep, month,year] for node in node, timep in TimePs, month in Months)
  end
  print(iob, "EmEGA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Construction
  #
  print(iob, "$TitleName Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(max(HDGCCI[plant,node,genco,area,year],RnGCCI[plant,node,genco,area,year],
      IPGCCI[plant,node,genco,area,year]) for plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "HDGCCI,RnGCCI,IPGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Renewable Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(RnGCCI[plant,node,genco,area,year] for plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "RnGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Intermittent Power Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(IPGCCI[plant,node,genco,area,year] for plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "IPGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Reserve Margin and Price Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(HDGCCI[plant,node,genco,area,year] for plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "HDGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Reserve Margin and Price Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(HDIPGC[power,node,genco,area,year] for power in Powers, node in node, genco in GenCos)
  end
  print(iob, "HDIPGC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Planned Capacity based on Reserve Margin (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(IPGCRM[power,node,genco,area,year] for power in Powers, node in node, genco in GenCos)
  end
  print(iob, "IPGCRM;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Planned Capacity based on Prices (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(IPGCPr[power,node,genco,area,year] for power in Powers, node in node, genco in GenCos)
  end
  print(iob, "IPGCPr;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Reserve Margin (MW/MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDRM[node,year]
  end
  print(iob, "HDRM;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Desired Reserve Margin (MW/MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = DRM[node,year]
  end
  print(iob, "DRM;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Peak Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDPDP1[node,year]
  end
  print(iob, "HDPDP1;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Forecasted Capacity Requirements (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDRQ[node,year]
  end
  print(iob, "HDRQ;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Forecast Firm Generating Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDFGC[node,year]
  end
  print(iob, "HDFGC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Existing Firm Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDGC[node,year]
  end
  print(iob, "HDGC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Firm Capacity under Construction (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDCUC[node,year]
  end
  print(iob, "HDCUC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Firm Capacity Being Retired (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDRetire[node,year]
  end
  print(iob, "HDRetire;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Firm Capacity Being Revised (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDGCCR[node,year]
  end
  print(iob, "HDGCCR;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Firm Contract Outflows (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDOutflow[node,year]
  end
  print(iob, "HDOutflow;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Firm Contract Inflow (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDInflow[node,year]
  end
  print(iob, "HDInflow;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Firm Cogeneration Capacity Sold to Grid (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDCgGC[node,year]
  end
  print(iob, "HDCgGC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  # Summary Variables
  #
  print(iob, "$TitleName Generating Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GCPA[plant,area,year] for plant in Plants, area in area)
  end
  print(iob, "GCPA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for ecc in ECCs, area in area)
  end
  print(iob, "SaEC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Electric Generation (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for plant in Plants, area in area)
  end
  print(iob, "EGPA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Curtailed Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for plant in Plants, area in area)
  end
  print(iob, "EGPACurtailed;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  # Construction Support/Details
  #
  print(iob, "$TitleName Build Switch;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = BuildSw[area,year]
  end
  print(iob, "BuildSw;$TitleName")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Building Fraction;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = BuildFr[area,year]
  end
  print(iob, "BuildFr;$TitleName")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  print(iob, "$TitleName Indicated Planned Generation Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(HDIPGC[power,node,genco,area,year]
      for power in Powers, node in node, genco in GenCos, area in area)
  end
  print(iob, "HDIPGC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = sum(HDIPGC[power,node,genco,area,year]
        for power in Powers, node in node, genco in GenCos, area in area)   
    end
    print(iob, "HDIPGC;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
  
  #
  print(iob, "$TitleName Planned Capacity based on Reserve Margin (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(IPGCRM[power,node,genco,area,year]
      for power in Powers, node in node, genco in GenCos, area in area)
  end     
  print(iob, "IPGCRM;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = sum(IPGCRM[power,node,genco,area,year]
        for power in Powers, node in node, genco in GenCos, area in area)
    end
    print(iob, "IPGCRM;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
  
  #
  print(iob, "$TitleName Planned Capacity based on Prices (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(IPGCPr[power,node,genco,area,year]
      for power in Powers, node in node, genco in GenCos, area in area)
  end
  print(iob, "IPGCPr;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = sum(IPGCPr[power,node,genco,area,year]
        for power in Powers, node in node, genco in GenCos, area in area)
    end
    print(iob, "IPGCPr;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
  
  #
  print(iob, "$TitleName Endogenous Build Fraction (MW/MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for power in Powers
    # ZZZ[years] = BFraction[power,node,area,years]
    print(iob, "BFraction;$(PowerDS[power]);")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
  
  #
  print(iob, "$TitleName Price Differential (\$/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = PriceDiff[power,node,area,year]
    end
    print(iob, "PriceDiff;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
  
  #
  print(iob, "$TitleName Decision Price for New Construction ($CDTime $(MoneyUnitDS[area])/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = HDPrDP[power,node,year] / Inflation[area,year] * Inflation[area,CDYear]
    end
    print(iob, "HDPrDP;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Lowest cost of energy
  #
  for year in years, power in Powers, plant in Plants
    if GCPot[plant,node,area,year] > GCDev[plant,node,area,year] &&
       GCExpSw[plant,area,year] == 1
      MCELowest[power,year] = min(MCE[plant,power,area,year],MCELowest[power,year])
    end
  end
  print(iob, "$TitleName Lowest Cost of Energy for New Capacity ($CDTime $(MoneyUnitDS[area])/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = MCELowest[power,year] / Inflation[area,year] * Inflation[area,CDYear]
    end
    print(iob, "MCELowest;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Baseline Build Fraction (Fraction);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = BsBdFr[power,area,year]
    end
    print(iob, "BsBdFr;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Price Differential Fraction (Fraction);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for power in Powers
    for year in years
      ZZZ[year] = PrDiFr[power,area,year]
    end
    print(iob, "PrDiFr;$(PowerDS[power])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Maximum Build Fraction (Fraction);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = BFracMax[area,year]
  end
  print(iob, "BFracMax;$(AreaDS[area])")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Build Decision Capacity Under Construction Constraint (MW/MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = CUCMlt[node,year]
  end
  print(iob, "CUCMlt;$(NodeDS[node])")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, "$TitleName Capacity Under Construction as a Fraction of Capacity (MW/MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = CUCFr[node,year]
  end
  print(iob, "CUCFr;$(NodeDS[node])")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, "$TitleName Limit on Capacity Under Construction Constraint (MW/MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = CUCLimit[year]
  end
  print(iob, "CUCLimit;$(NodeDS[node])")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, "$TitleName Forecasted Peak Growth Rate;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = HDGR[node,year]
  end
  print(iob, "HDGR;$(NodeDS[node])")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Components of Electric Utility Expenditures
  #
  print(iob, "$TitleName $(ECCDS[ug_ecc]) Expenditures (Millions $CDTime $(MoneyUnitDS[area])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(Expend[ecc,area,year] for ecc in ug_ecc, area in area) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "Expend;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(PInvTemp[fuel,area,year] + DInvEU[fuel,area,year] for fuel in Fuels, area in area) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "PInv+DInvEU;Capacity Investments")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(FuelExpenditures[ecc,area,year] for ecc in ug_ecc, area in area) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "FuelExpenditures;Fuel Expenditures")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(OMExp[ecc,area,year] for ecc in ug_ecc, area in area) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "OMExp;O&M Expenses")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(TDInv[area,year] for area in area) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "TDInv;T&D Investments")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  print(iob, "$TitleName Capacity Investments (Millions $CDTime $(MoneyUnitDS[area])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(PInvTemp[fuel,area,year] .+ DInvEU[fuel,area,year] for fuel in Fuels, area in area) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "PInv+DInvEU;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)

  TTT = ZZZ
  # Select Fuel??

  for year in years
    SSS[year] = sum(PInvTemp[fuel,area,year] + DInvEU[fuel,area,year] for fuel in Fuels, area in area) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  for fuel in Fuels
    print(iob, "PInv+DInvEU;",FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(PInvTemp[fuel,area,year] + DInvEU[fuel,area,year] for fuel in Fuels, area in area) /
        Inflation[area,year] * Inflation[area,CDYear]
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  print(iob, "PInv+DInvEU;Other")
  for year in years
    ZZZ[year] = TTT[year]-SSS[year]
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Detailed Variables
  #
  print(iob, "$TitleName Generating Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GCPA[plant,area,year] for plant in Plants, area in area)
  end
  print(iob, "GCPA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year] for area in area)
    end
    print(iob, "GCPA;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Capacity Completion Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GCCR[plant,node,genco,year] for plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "GCCR;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(GCCR[plant,node,genco,year] for node in node, genco in GenCos)
    end
    print(iob, "GCCR;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(max(HDGCCI[plant,node,genco,area,year],
      RnGCCI[plant,node,genco,area,year],IPGCCI[plant,node,genco,area,year]) for
      plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "HDGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(max(HDGCCI[plant,node,genco,area,year],
        RnGCCI[plant,node,genco,area,year],IPGCCI[plant,node,genco,area,year]) for
        node in node, genco in GenCos)
    end
    print(iob, "HDGCCI;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Reserve Margin and Price Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(HDGCCI[plant,node,genco,area,year] for
      plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "HDGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(HDGCCI[plant,node,genco,area,year] for
        node in node, genco in GenCos)
    end
    print(iob, "HDGCCI;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Renewable Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(RnGCCI[plant,node,genco,area,year] for
      plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "RnGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(RnGCCI[plant,node,genco,area,year] for
        node in node, genco in GenCos)
    end
    print(iob, "RnGCCI;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Intermittent Power Capacity Initiation Rate (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(IPGCCI[plant,node,genco,area,year] for
      plant in Plants, node in node, genco in GenCos)
  end
  print(iob, "IPGCCI;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(IPGCCI[plant,node,genco,area,year] for
        node in node, genco in GenCos)
    end
    print(iob, "IPGCCI;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Electric Generation by Plant Type (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for plant in Plants, area in area)
  end
  print(iob, "EGPA;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(EGPA[plant,area,year] for area in area)
    end
    print(iob, "EGPA;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for ecc in ECCs, area in area)
  end
  print(iob, "SaEC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for class in Classes
    for year in years
      ZZZ[year] = sum(SaEC[ecc,area,year] * ECCCLMap[ecc,class] for ecc in ECCs, area in area)
    end
    print(iob, "SaEC;$(ClassDS[class])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "Transmission Flows (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(AreaPurchases[area,year] for area in area)
  end
  print(iob, "AreaPurchases;In-Flows")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] for area in area)
  end
  print(iob, "AreaSales;Out-Flows")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(ExpPurchases[area,year] for area in area)
  end
  print(iob, "ExpPurchases;Imports")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] for area in area)
  end
  print(iob, "ExpSales;Exports")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] - ExpPurchases[area,year] for area in area)
  end
  print(iob, "NetExp;Net Exports")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] - AreaPurchases[area,year] +
      ExpSales[area,year] - ExpPurchases[area,year] for area in area)
  end
  print(iob, "Net;Net Out-Flows")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob, "$TitleName Average Retail Electricity Price ($CDTime $(MoneyUnitDS[area])/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(PE[ecc,area,year] * SaEC[ecc,area,year] for ecc in ECCs) /
      sum(SaEC[ecc,area,year] for ecc in ECCs) /
      Inflation[area,year] * Inflation[area,CDYear]
  end
  print(iob, "PE;Average")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for class in Select(Class, ["Res", "Com", "Ind", "Transport"])
    for year in years
      ZZZ[year] = sum(PE[ecc,area,year] * SaEC[ecc,area,year] * ECCCLMap[ecc,class] /
        Inflation[area,year] * Inflation[area,CDYear] for ecc in ECCs, area in area) /
        sum(SaEC[ecc,area,year] * ECCCLMap[ecc,class] for ecc in ECCs, area in area)
    end
    print(iob, "PE;$(ClassDS[class]) (\$/MWh)")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Curtailed Generation by Plant Type (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(EGPACurtailed[plant,area,year] for plant in Plants, area in area)
  end
  print(iob, "EGPACurtailed;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in area)
    end
    print(iob, "EGPACurtailed;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Firm Generating Capacity by Plant Type (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(GCPA[plant,area,year] * CapCredit[plant,area,year] for
      plant in Plants, area in area)
  end
  print(iob, "GCPA*CapCredit;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year] * CapCredit[plant,area,year] for area in area)
    end
    print(iob, "GCPA*CapCredit;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  print(iob, "$TitleName Portfolio Fraction of New Capacity (MW/MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  base_power = Select(Power, "Base")
  for year in years
    ZZZ[year] = sum(Portfolio[plant,base_power,node,area,year] for
      plant in Plants, node in node, area in area)
  end
  print(iob, "Portfolio;Total")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    for year in years
      ZZZ[year] = sum(Portfolio[plant,base_power,node,area,year] for
        node in node, area in area)
    end
    print(iob, "Portfolio;$(PlantDS[plant])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  #
  # Cost of Energy from New Capacity
  #
  for power in Powers
    print(iob, "$TitleName $(PowerDS[power]) Cost of Energy from New Capacity by Plant Type ($CDTime $(MoneyUnitDS[area])/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for plant in Plants
      for year in years
        ZZZ[year] = MCE[plant,power,area,year] /
          Inflation[area,year] * Inflation[area,CDYear]
      end
      print(iob, "MCE;$(PlantDS[plant])")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for month in Months
    print(iob, "$TitleName $(MonthDS[month]) Emergency Generation (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        ZZZ[year] = EmEGA[node,timep,month,year]
      end
      print(iob, "EmEGA;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for month in Months
    print(iob, "$TitleName $(MonthDS[month]) Peak (Highest) Load in Interval (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        ZZZ[year] = HDPDP[node,timep,month,year]
      end
      print(iob, "HDPDP;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for month in Months
    print(iob, "$TitleName $(MonthDS[month]) Average Load in Interval with Generation to Fill Storage (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        ZZZ[year] = HDADPwithStorage[node,timep,month,year]
      end
      print(iob, "HDADPwithStorage;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  un1 = UnNode[Units] .== Node[node]
  un2 = UnCogen .== 0
  un = un1 .& un2
  for month in Months
    print(iob, "$TitleName $(MonthDS[month]) Effective Generating Capacity (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        ZZZ[year] = sum(UnEGC[unit,timep,month,year] for unit in Units[un])
      end
      print(iob, "UnEGC;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for month in Months
    print(iob, "$TitleName $(MonthDS[month]) Spot Market Price ($CDTime $(MoneyUnitDS[area])/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        ZZZ[year] = HMPr[area,timep,month,year] /
          Inflation[area,year] * Inflation[area,CDYear]
      end
      print(iob, "HMPr;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  # Transmission Flow Potential From Current Node (Flow Potential = Max Flow - Actual)
  #
  # TODOJulia 1/3/2024 NJC Jeff - need clarity
  # just pick first
  #
  nodexs = Select(NdXArMap[NodeXs,area], ==(1))
  for month in Months
    print(iob, "$(MonthDS[month]) Transmission Load Potential $(NodeXDS[nodexs[1]]) (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        FlowPot[year] = sum(LLMax[node,nodex,timep,month,year] - HDLLoad[node,nodex,timep,month,year]
          for node in node, nodex in nodexs)
        ZZZ[year] = HMPr[area,timep,month,year] /
          Inflation[area,year] * Inflation[area,CDYear]
      end    
      print(iob, "LLMax-HDLLoad;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  # Exogenous Contracts FROM Current Node to other nodes
  #
  nodex = node
  for month in Months
    print(iob, "$(MonthDS[month]) Power Contracts Total Outflows (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        ZZZ[year] = sum(HDXLoad[node,nodex,timep,month,year] for node in Nodes)
      end
      print(iob, "HDXLoad;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    for node in Nodes
      if sum(HDXLoad[node,nodex,timep,month,year] for timep in TimePs, year in years) > 0
        print(iob, "$(MonthDS[month]) Power Contracts to $(NodeDS[node]) (MW);")
        for year in years
          print(iob,";",Year[year])
        end
        println(iob)
        for timep in TimePs
          TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
          for year in years
            ZZZ[year] = HDXLoad[node,nodex,timep,month,year]
          end
          print(iob, "HDXLoad;$TPDS")
          for year in years
            print(iob,";",@sprintf("%.4f", ZZZ[year]))
          end
          println(iob)
        end
        println(iob, " ")
      end
    end
  end

  #
  # Exogenous Contracts TO Current Node FROM other nodes
  #
  for month in Months
    print(iob, "$(MonthDS[month]) Power Contracts Total Inflows (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      for year in years
        ZZZ[year] = sum(HDXLoad[node,nodex,timep,month,year] for nodex in NodeXs)
      end
      print(iob, "HDXLoad;$TPDS")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    for nodex in NodeXs
      if sum(HDXLoad[node,nodex,timep,month,year] for timep in TimePs, year in years) > 0
        print(iob, "$(MonthDS[month]) Power Contracts from $(NodeXDS[nodex]) (MW);")
        for year in years
          print(iob,";",Year[year])
        end
        println(iob)
        for timep in TimePs
          TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
          for year in years
            ZZZ[year] = HDXLoad[node,nodex,timep,month,year]
          end
          print(iob, "HDXLoad;$TPDS")
          for year in years
            print(iob,";",@sprintf("%.4f", ZZZ[year]))
          end
          println(iob)
        end
        println(iob, " ")
      end
    end
  end
  return iob
end

function ElectricExpansion_DtaRun(data)
  (; Area, Areas, AreaDS, GenCo, GenCos, Nation, Nations, Node, Nodes, Year) = data
  (; ANMap, NdArMap, SceName, years,SceName) = data
  #
  iob = IOBuffer()
  #

  CN = Select(Nation,"CN");
  areas = findall(ANMap[:,CN] .== 1);
  for area in areas
    nodes = findall(NdArMap[:,area] .> 0.0)
    if !isempty(nodes)
      genco = area
      TitleName=AreaDS[area]
      FileKey=Area[area]
      #
      if Area[area] != "NL"
        # loop through node
        iob = TopOfFile(data, iob, FileKey, TitleName)
        iob = ShowData(data, iob, area, TitleName, nodes[1])

        #
        # Create *.dta filename and write output values
        #

        OutFil="ElectricExpansion-" * FileKey * "-" * SceName * ".dta"
        open(joinpath(OutputFolder, OutFil), "w") do filename
          write(filename, String(take!(iob)))
        end
      else
        for node in nodes
          TitleName=AreaDS[area] * "For " * Node[node] * " Node"
          FileKey = Node[node]
          iob = TopOfFile(data, iob, FileKey, TitleName)
          iob = ShowData(data, iob, area, TitleName, node)
          #
          # Create *.dta filename and write output values
          #
          OutFil="ElectricExpansion-" * FileKey * "-" * SceName * ".dta"
          open(joinpath(OutputFolder, OutFil), "w") do filename
            write(filename, String(take!(iob)))
          end
        end
      end
    end
  end
end

function ElectricExpansion_DtaControl(db)

  @info "ElectricExpansion_DtaControl"
  data = ElectricExpansionData(; db)
  ElectricExpansion_DtaRun(data)

end

if abspath(PROGRAM_FILE) == @__FILE__
ElectricExpansion_DtaControl(DB)
end



