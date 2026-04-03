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


  ArNdFr = ReadDisk(DataFrame,DB,"EGInput/ArNdFr") #[Area,Node,Year]  Fraction of the Area in each Node (Fraction)
  BFraction = ReadDisk(DataFrame,DB,"EGOutput/BFraction") #[Power,Node,Area,Year]  Endogenous Build Fraction (MW/MW)
  BuildFr = ReadDisk(DataFrame,DB,"EGInput/BuildFr") #[Area,Year]  Building fraction
  BuildSw = ReadDisk(DataFrame,DB,"EGInput/BuildSw") #[Area,Year]  Build switch
  CapCredit = ReadDisk(DataFrame,DB,"EGInput/CapCredit") #[Plant,Area,Year]  Capacity Credit (MW/MW)
  CD = ReadDisk(DataFrame,DB,"EGInput/CD") #[Plant,Year]  Construction Delay (YEARS)
  CUCFr = ReadDisk(DataFrame,DB,"EGOutput/CUCFr") #[Node,Year]  Capacity Under Construction as Fraction of Capacity (MW/MW)
  CUCMlt = ReadDisk(DataFrame,DB,"EGOutput/CUCMlt") #[Node,Year]  Build Decision Capacity Under Construction Constraint (MW/MW)
  CWGA = ReadDisk(DataFrame,DB,"EGOutput/CWGA") #[Plant,Area,Year]  Construction Work into Gross Assets (M$)
  DesHr = ReadDisk(DataFrame,DB,"EGInput/DesHr") #[Plant,Power,Area,Year]  Design Hours (Hours)
  DRM = ReadDisk(DataFrame,DB,"EInput/DRM") #[Node,Year]  Desired Reserve Margin (MW/MW)
  EUPOCX = ReadDisk(DataFrame,DB,"EGOutput/EUPOCX") #[FuelEP,Plant,Poll,Area,Year]  Electric Utility Pollution Coefficient (Tonnes/TBtu)
  ExpPurchases = ReadDisk(DataFrame,DB,"EGOutput/ExpPurchases") #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales = ReadDisk(DataFrame,DB,"EGOutput/ExpSales") #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)
  # F1New = ReadDisk(DataFrame,DB,"EGinput/F1New") #[Plant,Area]  Fuel Type 1
  FlFrNew = ReadDisk(DataFrame,DB,"EGInput/FlFrNew") #[FuelEP,Plant,Area,Year]  Fuel Fraction for New Plants
  FPEU = ReadDisk(DataFrame,DB,"EGOutput/FPEU") #[Plant,Area,Year]  Electric Utility Fuel Prices ($/mmBtu)
  FPF = ReadDisk(DataFrame,DB,"SOutput/FPF") #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  GCCC = ReadDisk(DataFrame,DB,"EGOutput/GCCC") #[Plant,Area,Year]  Overnight Construction Costs ($/KW)
  GCCCM = ReadDisk(DataFrame,DB,"EGOutput/GCCCM") #[Plant,Area,Year]  Capital Cost Multiplier ($/$)
  GCCCN = ReadDisk(DataFrame,DB,"EGInput/GCCCN") #[Plant,Area,Year]  Overnight Construction Costs ($/KW)
  GCCR = ReadDisk(DataFrame,DB,"EGOutput/GCCR") #[Plant,Node,GenCo,Year]  Capacity Completion Rate (MW/Yr)
  GCDev = ReadDisk(DataFrame,DB,"EGOutput/GCDev") #[Plant,Node,Area,Year]  Generation Capacity Developed (MW)
  GCPA = ReadDisk(DataFrame,DB,"EOutput/GCPA") #[Plant,Area,Year]  Generation Capacity (MW)
  GCPot = ReadDisk(DataFrame,DB,"EGOutput/GCPot") #[Plant,Node,Area,Year]  Maximum Potential Generation Capacity (MW)
  GrMSF = ReadDisk(DataFrame,DB,"EGOutput/GrMSF") #[Plant,Node,Area,Year]  Green Power Market Share (MW/MW)
  HDEnergy = ReadDisk(DataFrame,DB,"EGOutput/HDEnergy") #[Node,TimeP,Month,Year]  Energy in Interval (GWh)
  HDGCCI = ReadDisk(DataFrame,DB,"EGOutput/HDGCCI") #[Plant,Node,GenCo,Area,Year]  New Capacity Initiated (MW)
  HDGCCR = ReadDisk(DataFrame,DB,"EGOutput/HDGCCR") #[Node,Year]  Firm Generating Capacity being Revised (MW)
  HDHrMn = ReadDisk(DataFrame,DB,"EInput/HDHrMn") #[TimeP,Month]  Minimum Hour in the Interval (Hour)
  HDHrPk = ReadDisk(DataFrame,DB,"EInput/HDHrPk") #[TimeP,Month]  Peak Hour in the Interval (Hour)
  HDIPGC = ReadDisk(DataFrame,DB,"EGOutput/HDIPGC") #[Power,Node,GenCo,Area,Year]  Indicated Planned Generation Capacity (MW)
  HDPrA = ReadDisk(DataFrame,DB,"EOutput/HDPrA") #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
  HDPrDP = ReadDisk(DataFrame,DB,"EGOutput/HDPrDP") #[Power,Node,Year]  Decision Price for New Construction ($/MWh)
  HDCgGC = ReadDisk(DataFrame,DB,"EGOutput/HDCgGC") #[Node,Year]  Firm Cogeneration Capacity Sold to Grid (MW)
  HDCUC = ReadDisk(DataFrame,DB,"EGOutput/HDCUC") #[Node,Year]  Firm Capacity under Construction (MW)
  HDFGC = ReadDisk(DataFrame,DB,"EGOutput/HDFGC") #[Node,Year]  Forecasted Firm Generation Capacity (MW)
  HDGC = ReadDisk(DataFrame,DB,"EGOutput/HDGC") #[Node,Year]  Firm Generating Capacity in Previous Year (MW)
  HDGR = ReadDisk(DataFrame,DB,"EGOutput/HDGR") #[Node,Year]  Forecasted Peak Growth Rate
  HDPDP = ReadDisk(DataFrame,DB,"EGOutput/HDPDP") #[Node,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
  HDRetire = ReadDisk(DataFrame,DB,"EGOutput/HDRetire") #[Node,Year]  Firm Generating Capacity being Retired (MW)
  HDRM = ReadDisk(DataFrame,DB,"EGOutput/HDRM") #[Node,Year]  Reserve Margin (MW/MW)
  HDRQ = ReadDisk(DataFrame,DB,"EGOutput/HDRQ") #[Node,Year]  Hourly Dispatch Forecasted Generation Requirements
  HRtM = ReadDisk(DataFrame,DB,"EGInput/HRtM") #[Plant,Area,Year]  Marginal Heat Rate (Btu/KWh)
  Inflation = ReadDisk(DataFrame,DB,"MOutput/Inflation") #[Area,Year]  Inflation Index
  IPExpSw = ReadDisk(DataFrame,DB,"EGInput/IPExpSw") #[Plant,Area,Year]  Intermittent Power Capacity Expansion Switch (1=Build)
  IPGCCI = ReadDisk(DataFrame,DB,"EGOutput/IPGCCI") #[Plant,Node,GenCo,Area,Year]  Intermittent Power Capacity Initiated (MW)
  IPGCPr = ReadDisk(DataFrame,DB,"EGOutput/IPGCPr") #[Power,Node,GenCo,Area,Year]  Interruptible Capacity Built based on Spot Market Prices (MW)
  IPGCRM = ReadDisk(DataFrame,DB,"EGOutput/IPGCRM") #[Power,Node,GenCo,Area,Year]  Capacity Built based on Reserve Margin (MW)
  IPPrDP = ReadDisk(DataFrame,DB,"EGOutput/IPPrDP") #[Node,Year]  Decision Price for building Intermittent Power ($/MWh)
  MCE = ReadDisk(DataFrame,DB,"EOutput/MCE") #[Plant,Power,Area,Year]  Cost of Energy from New Capacity ($/MWh)
  MCELimit = ReadDisk(DataFrame,DB,"EGInput/MCELimit") #[Area,Year]  Build Decision Cost of Power Limit
  MFC = ReadDisk(DataFrame,DB,"EOutput/MFC") #[Plant,Area,Year]  Marginal Fixed Costs ($/KW)
  MVC = ReadDisk(DataFrame,DB,"EOutput/MVC") #[Plant,Area,Year]  Marginal Variable Costs ($/MWh)
  NdArMap = ReadDisk(DataFrame,DB,"EGInput/NdArMap") #[Node,Area]  Map between Node and Area
  NdNMap = ReadDisk(DataFrame,DB,"EGInput/NdNMap") #[Node,Nation]  Map between Node and Nation
  OffValue = ReadDisk(DataFrame,DB,"EGOutput/OffValue") #[Plant,Poll,Area,Year]  Value of Offsets ($/MWh)
  ORNew = ReadDisk(DataFrame,DB,"EGInput/ORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  PCF = ReadDisk(DataFrame,DB,"EGOutput/PCF") #[Plant,GenCo,Year]  Plant Capacity Factor (MW/MW)
  PFFrac = ReadDisk(DataFrame,DB,"EGInput/PFFrac") #[FuelEP,Plant,Area,Year]  Fuel Usage Fraction (Btu/Btu)
  PjMax = ReadDisk(DataFrame,DB,"EGInput/PjMax") #[Plant,Area]  Maximum Plant Size (MW)
  PjMnPS = ReadDisk(DataFrame,DB,"EGInput/PjMnPS") #[Plant,Area]  Minimum Plant Size (MW)
  PkLoad = ReadDisk(DataFrame,DB,"SOutput/PkLoad") #[Month,Area,Year]  Monthly Peak Load (MW)
  Portfolio = ReadDisk(DataFrame,DB,"EGInput/Portfolio") #[Plant,Power,Node,Area,Year]  Portfolio Fraction of New Capacity (MW/MW)
  PoTRNew = ReadDisk(DataFrame,DB,"EGOutput/PoTRNew") #[Plant,Area,Year]  Emission Cost for New Plants ($/MWh)
  PriceDiff = ReadDisk(DataFrame,DB,"EGOutput/PriceDiff") #[Power,Node,Area,Year]  Difference between Spot Market Price and Price of New Capacity
  RnGCCI = ReadDisk(DataFrame,DB,"EGOutput/RnGCCI") #[Plant,Node,GenCo,Area,Year]  Renewable Capacity Initiated (MW)
  RnGen = ReadDisk(DataFrame,DB,"EGOutput/RnGen") #[Area,Year]  Renewable Current Level of Generation (GWh/Yr)
  RnGoal = ReadDisk(DataFrame,DB,"EGOutput/RnGoal") #[Area,Year]  Renewable Generation Goal for Construction (GWh/Yr)
  Subsidy = ReadDisk(DataFrame,DB,"EGInput/Subsidy") #[Plant,Area,Year]  Generating Capacity Subsidy ($/MWh)
  TPRMap = ReadDisk(DataFrame,DB,"EGInput/TPRMap") #[TimeP,Power]  TimeP to Power Map
  UFOMC = ReadDisk(DataFrame,DB,"EGInput/UFOMC") #[Plant,Area,Year]  Unit Fixed O&M Costs ($/KW)
  UOMC = ReadDisk(DataFrame,DB,"EGInput/UOMC") #[Plant,Area,Year]  Unit O&M Costs ($/MWh)
  WCC = ReadDisk(DataFrame,DB,"EGInput/WCC") #[Area,Year]  Weighted Cost of Capital (1/Yr)
  xGCPot = ReadDisk(DataFrame,DB,"EGInput/xGCPot") #[Plant,Node,Area,Year]  Exogenous Maximum Potential Generation Capacity (MW)

if abspath(PROGRAM_FILE) == @__FILE__
ElectricConstruction_DtaControl(DB)
end
