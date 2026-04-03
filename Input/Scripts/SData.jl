#
# SData.jl
#
using EnergyModel

module SData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,xHisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Area65::SetArray = ReadDisk(db,"MainDB/Area65Key")
  Area65DS::SetArray = ReadDisk(db,"MainDB/Area65DS")
  Area65s::Vector{Int} = collect(Select(Area65))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  ClassDS::SetArray = ReadDisk(db,"MainDB/ClassDS")
  Classes::Vector{Int} = collect(Select(Class))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelFs::SetArray = ReadDisk(db,"MainDB/FuelFsKey")
  FuelFsDS::SetArray = ReadDisk(db,"MainDB/FuelFsDS")
  FuelFss::Vector{Int} = collect(Select(FuelFs))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  HourDS::SetArray = ReadDisk(db,"MainDB/HourDS")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  PI::SetArray = ReadDisk(db,"SInput/PIKey")
  PIDS::SetArray = ReadDisk(db,"SInput/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))


  AGFr::VariableArray{4} = ReadDisk(db,"SInput/AGFr") # Government Subsidy ($/$) [ECC,Poll,Area,Year]
  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  AreaNatMap::VariableArray{2} = ReadDisk(db,"SInput/AreaNatMap") #[Area65,Nation]  Map between Area65 and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  BCarbonSw::VariableArray{1} = ReadDisk(db,"SInput/BCarbonSw") # [Year] Black Carbon coefficient switch (1=POCX set relative to PM25)
  CalibLTime::VariableArray{1} = ReadDisk(db,"SInput/CalibLTime") # [Area] Last Year of Load Curve Calibration (Year)
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade,Cap Only=2)
  CBSw::VariableArray{2} = ReadDisk(db,"SInput/CBSw") # [Market,Year] Switch to send Government Revenues to Economic Model (1=Yes)
  CDTime::Float32 = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Float32 = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  DaysPerMonth::VariableArray{1} = ReadDisk(db,"SInput/DaysPerMonth") # [Month] Days per Month
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECCProMap::VariableArray{2} = ReadDisk(db,"SInput/ECCProMap") #[ECC,Process]  ECC to Process Map
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  EITarget::VariableArray{5} = ReadDisk(db,"SInput/EITarget") # [ECC,Poll,PCov,Area,Year] Target Emissions Intensity (Tonnes/M$)
  ElecPrSw::VariableArray{2} = ReadDisk(db,"SInput/ElecPrSw") # [Area,Year] Electricity Price Switch (0=Exogenous Prices)
  ENPNSw::VariableArray{3} = ReadDisk(db,"SInput/ENPNSw") # [Fuel,Nation,Year]  Wholesale Price (ENPN) Switch (1=Endogenous)
  ETABY::VariableArray{1} = ReadDisk(db,"SInput/ETABY") # [Market] Beginning Year for Emission Trading Allowances (Year)
  ETAFAP::VariableArray{2} = ReadDisk(db,"SInput/ETAFAP") # [Market,Year] Cost of Foreign Allowances ($/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db,"SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  ETAMin::VariableArray{2} = ReadDisk(db,"SInput/ETAMin") # [Market,Year] Minimum Price for Allowances ($/Tonne)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FFsMap::VariableArray{2} = ReadDisk(db,"SInput/FFsMap") # [FuelFs,Fuel] Map between FuelFs and Fuel
  FlPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/FlPolSwitch") # [ECC,Poll,Area,Year] Flaring Pollution Switch (0=Exogenous)
  FuelLimit::VariableArray{3} = ReadDisk(db,"SCalDB/FuelLimit") # [Fuel,Area,Year] Fuel Limit Multiplier (Btu/Btu) 
  FuPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/FuPolSwitch") # [ECC,Poll,Area,Year] Fugitive Pollution Switch (0=Exogenous)
  GECONV::Float32 = ReadDisk(db,"SInput/GECONV")[1] # Gas Energy Conversion (Therm/mmBtu)
  GMMult::VariableArray{2} = ReadDisk(db,"SInput/GMMult") # [Nation,Year] Marketable Gas Production Multiplier (TBtu/TBtu)
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather,2=Output,0=Exogenous)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Monthly Period (Hours)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits,2=Domestic Permits)
  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # [Year] Maximum Number of Iterations (Number)
  MEPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/MEPolSwitch") # [ECC,Poll,Area,Year] Process Pollution Switch (0=Exogenous)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  OUDmdFr::VariableArray{4} = ReadDisk(db,"SInput/OUDmdFr") # [FuelEP,ECC,Area,Year] Own Use Fraction of Demands (Btu/Btu)
  PAdCost::VariableArray{4} = ReadDisk(db,"SInput/PAdCost") # Policy Administrative Cost (Exogenous) [ECC,Poll,Area,Year]
  PCERG::VariableArray{3} = ReadDisk(db,"SInput/PCERG") # [Fuel,ECC,Area] Energy Requirement Growth Rate (1/Yr)
  PCovMap::VariableArray{5} = ReadDisk(db,"SInput/PCovMap") # [FuelEP,ECC,PCov,Area,Year] Pollution Coverage Map (1=Mapped)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PGrowth::VariableArray{1} = ReadDisk(db,"SInput/PGrowth") # [Market] Growth Factor for Pollution Goals (Tonnes/Yr/(Tonnes/Yr))
  PHYear::VariableArray{1} = ReadDisk(db,"SInput/PHYear") # [Market] Pollution Grandfathering Year (Date)
  PIAT::VariableArray{2} = ReadDisk(db,"SInput/PIAT") # [ECC,Poll] Pollution Inventory Averaging Time (Years)
  POCXMax::VariableArray{3} = ReadDisk(db,"SInput/POCXMax") # [FuelEP,Poll,Year] Pollution Coefficient Maximum (Tonnes/TBtu)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 
  RunExtra::Float32 = ReadDisk(db,"SInput/RunExtra")[1] # [tv] Run Extra Iteration?  
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  SqOCF::VariableArray{3} = ReadDisk(db, "SInput/SqOCF") # [ECC,Area,Year] Sequestering eCO2 Reduction Operating Cost Factor ($/$)
  SqPGMult::VariableArray{4} = ReadDisk(db,"SInput/SqPGMult") # [ECC,Poll,Area,Year] Sequestering Gratis Permit Multiplier (Tonne/Tonne)
  TDEF::VariableArray{3} = ReadDisk(db,"SInput/TDEF") # [Fuel,Area,Year] T&D Efficiency (MW/MW)
  VnPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/VnPolSwitch") # [ECC,Poll,Area,Year] Venting Pollution Switch (0=Exogenous)
  xCDUF::VariableArray{4} = ReadDisk(db,"SInput/xCDUF") # [Class,Day,Month,Area] Class Daily Use Factor for Gas
  xCLSF::VariableArray{5} = ReadDisk(db,"SInput/xCLSF") # [Class,Hour,Day,Month,Area] Class Load Shape (MW/MW)
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xGoalPol::VariableArray{2} = ReadDisk(db,"SInput/xGoalPol") # [Market,Year] Pollution Goal (Tonnes eCO2/Yr)
  xPGratis::VariableArray{5} = ReadDisk(db,"SInput/xPGratis") # [ECC,Poll,PCov,Area,Year] Exogenous Gratis Permits (Tonnes/Yr)
  xPRExp::VariableArray{4} = ReadDisk(db,"SInput/xPRExp") #[ECC,Poll,Area,Year]  Exogenous Reduction Private Expenses (M$/Yr)
  xProcSw::VariableArray{2} = ReadDisk(db,"SInput/xProcSw") #[PI,Year] "Procedure on/off Switch"
  xSalSw::VariableArray{1} = ReadDisk(db,"SInput/xSalSw") #[Class]  Switch for Exogenous Sales (True=Exogenous)
  xTGratis::VariableArray{2} = ReadDisk(db,"SInput/xTGratis") #[Market,Year]  Exogenous Gratis Permits (Tonnes/Yr)
  YEndTime::Float32 = ReadDisk(db,"SInput/YEndTime")[1] # [tv] Last Year of Calibration (Date)
  YFPDChgF::VariableArray{4} = ReadDisk(db,"SInput/YFPDChgF") # [Fuel,ES,Area,Year] Method for deterining future values for FPDChgF
  YHPKM::VariableArray{3} = ReadDisk(db,"SInput/YHPKM") # [Month,Area,Year] Calibration Control Variable for HPKM
  YUFP::Float32 = ReadDisk(db,"SInput/YUFP")[1] # [tv] Upper Error Limit for Fuel Prices (PERCENT)
  YUSales::Float32 = ReadDisk(db,"SInput/YUSales")[1] # [tv] Upper Error Limit for Sales (Percent)
  ZCarConv::VariableArray{2} = ReadDisk(db,"SInput/ZCarConv") #[FuelEP,Poll]  Convert from ($/Tonnes/($/mmBtu))


  #  *LogSw(Year)        'Switch which indicates whether or not to produce log files (Switch)',
  #  * Disk(SInput,LogSw(Year))
  # TEMP
  #  GROW(Sector,Fuel) 'SEDS growth rate'
  ANLENG::VariableArray{1} = zeros(Float32,length(Class))

end

# ****************************
# Define Procedure INTERPOLATE
# ****************************
# *
# * Look ahead or behind ICOUNT years to calculate growth rate
# ICOUNT=5
# * First year of series
# MinYr=Year:S(1)
# * Last year of series
# MaxYr=MinYr+Year:N-1
# * Span of years to interpolate
# SPANYr=Year:N
# IMTYPE=MTYPE
# *
# * This process will set TDEP to "NA" if DEP is truly "NA"
# Select Year*
# TDEP=CONDITION
# Select Year(MinYr-MaxYr)
# TDEP=ABS(DEP)+1
# *
# * Check if all data is bad, if so, set to zero and exit.
# Select Year If TDEP NE CONDITION
# Sum1=sum(Y)(TDEP(Y))
# Do If Sum1 eq CONDITION
#   Select Year(MinYr-MaxYr)
#   DEP=0
#   BREAK INTERPOLATE
# End Do If CONDITION
# *
# * Exponential fit only valid if values are positive.
# Min1=min(Y)(DEP(Y))
# Do If Min1 LE 0.0
#   IMTYPE=LINEAR
# End Do If DEP LE 0
# *
# * If needed, transform dependent variable
# Do If IMTYPE eq EXPONENTIAL
#   DEP=LN(DEP)
# End Do If IMTYPE eq "EXPONENTIAL"
# *
# * Interpolate until all years have values
# Do UNTIL Year:N eq SPANYr
# * First year selected
#   Loc1=Year:S(1)
# * If only one data point then set all to that value
#   Do If Year:N eq 1
#     Select Year(MinYr-MaxYr)
#     DEP(Y)=DEP(Loc1)
#     TDEP=1.0
# * Forward values are useable
#   Else TDEP(MaxYr) NE CONDITION
# *   Find second good year
#     Loc2=Year:S(2)
# *   Try ICOUNT years forward to make trend
#     ILoc3=xmin(Loc2+ICOUNT,MaxYr)
#     JLoc1=LN(Smallest)
#     ILoc4=0
# *    Do UNTIL ((TDEP(ILoc3) NE CONDITION) AND (DEP(ILoc3) GE LN(Smallest))) 
# *    Do UNTIL ((TDEP(ILoc3) NE CONDITION) AND (DEP(ILoc3) GE JLoc1)) 
#     Do UNTIL ((TDEP(ILoc3) NE CONDITION) AND (DEP(ILoc3) GT JLoc1)) OR (ILoc4 eq 1)
#       ILoc3=ILoc3-1
#       Do If ILoc3 eq 0
#         ILoc4=1
#         ILoc3=1
#       End Do If
#     End Do UNTIL
# *   Calculate Slope
#     Do If ILoc4 eq 0
#       ISLOPE=(DEP(ILoc3)-DEP(Loc1))/(ILoc3-Loc1)
#     Else
#       ISLOPE=0
#     End Do If
# *   Initial points are undefined; do analysis from initial point
#     Do If Loc1 GT MinYr
#      ILoc3=MinYr
#      Select Year(ILoc3-Loc1)
# *    Fill in missing points
#      DEP(Y)=ISLOPE*(YrNum(Y)-Loc1)+DEP(Loc1)
#      TDEP=1.0
# *    Fill in middle years of an "condition" interval
#     Else
#      Select Year(MinYr-MaxYr)
#      Select Year If TDEP eq CONDITION
# *    Find first good point
#      Loc1=Year:S(1)-1
#      Select Year(Year:S(1)-MaxYr)
#      Select Year If TDEP NE CONDITION
# *    Find second good point
#      Loc2=Year:S(1)
#      ISLOPE=(DEP(Loc1)-DEP(Loc2))/(Loc1-Loc2)
#      Select Year(Loc1-Loc2)
# *    Fill in missing points
#      DEP(Y)=ISLOPE*(YrNum(Y)-Loc1)+DEP(Loc1)
#      TDEP=1.0
#     End Do If Loc1 eq MinYr
# * End points are undefined
#   Else TDEP(MaxYr) eq CONDITION
# *   Reverse sort order
#     Select Year(MaxYr-MinYr)
#     Select Year If TDEP NE CONDITION
# *   Find last and second last value
#     Loc1=Year:S(1)
#     Loc2=Year:S(2)
# *   Try ICOUNT years back to make trend
#     ILoc3=xmax(Loc2-ICOUNT,MinYr)
#     JLoc1=LN(Smallest)
# *    Do UNTIL ((TDEP(ILoc3) NE CONDITION) AND (DEP(ILoc3) GE LN(Smallest))) 
# *    Do UNTIL ((TDEP(ILoc3) NE CONDITION) AND (DEP(ILoc3) GE JLoc1)) 
#     Do UNTIL ((TDEP(ILoc3) NE CONDITION) AND (DEP(ILoc3) GT JLoc1)) OR (ILoc4 eq 1)
#       ILoc3=ILoc3+1
#       Do If ILoc3 eq 0
#         ILoc4=1
#         ILoc3=1
#       End Do If
#     End Do UNTIL
# *   Calculate Slope
#     Do If ILoc4 eq 0
#       ISLOPE=(DEP(ILoc3)-DEP(Loc1))/(ILoc3-Loc1)
#     Else
#       ISLOPE=0
#     End Do If
# *   Calculate Slope
#     ISLOPE=(DEP(Loc1)-DEP(ILoc3))/(Loc1-ILoc3)
#     Select Year(Loc1-MaxYr)
# *   Fill in missing points
#     DEP(Y)=ISLOPE*(YrNum(Y)-Loc1)+DEP(Loc1)
#     TDEP=1.0
#   End Do If Year:N eq 1
#   Select Year(MinYr-MaxYr)
# * Find remaining years with values
#   Select Year If TDEP NE CONDITION
# End Do UNTIL SPANYr
# *
# * Re-transform dependent variable
# Do If IMTYPE eq EXPONENTIAL
#   DEP=EXP(DEP)
# End Do If MTYPE eq EXPONENTIAL
# Select Year(MinYr-MaxYr)
# End Procedure INTERPOLATE

function SData_Inputs(db)
  data = SControl(; db)
  (; Areas,Area65,Class,Classes,Day,ECC,ECCs,Fuel,Fuels,FuelEP,FuelEPs,FuelFs,FuelFss) = data
  (; Hours,Month,Months,Nation,PCov,PIs,Poll,Process,Years) = data
  (; AreaNatMap,BaseSw,BCarbonSw,ECCProMap,ElecPrSw,FFPMap,FFsMap,SecMap,CalibLTime) = data
  (; DaysPerMonth,EEConv,ENPNSw,ETABY,GECONV,GMMult,HoursPerMonth,MaxIter,NationOutputMap) = data
  (; OUDmdFr,PCERG,PCovMap,PGrowth,PIAT,PolConv,POCXMax,RefSwitch,RunExtra,SqOCF,SqPGMult,TDEF) = data
  (; xCLSF,xCDUF,xPRExp,FlPolSwitch,FuelLimit,FuPolSwitch,MEPolSwitch,VnPolSwitch,xSalSw) = data
  (; YEndTime,YFPDChgF,YHPKM,YUFP,YUSales,ZCarConv,AGFr,AreaMarket,CapTrade) = data
  (; CBSw,ECCMarket,EITarget,ETAFAP,ETAIncr,ETAMin,xGoalPol,GratSw,ISaleSw) = data
  (; PAdCost,PCovMarket,PHYear,PollMarket,xETAPr,xPGratis,xProcSw,xTGratis) = data
  (; ANLENG) = data

  ########################
  # AreaNatMap[Area65,Nation] Map between Area65 and Nation
  #
  # 1.
  # 2. The data is read in directly.
  # 3. P. Cross 12/4/01
  #
  @. AreaNatMap=0
  US=Select(Nation,"US")
  area65a=Select(Area65,(from="AL",to="WY"))
  area65b=Select(Area65,["US","DC"])
  area65s=union(area65a,area65b)
  AreaNatMap[area65s,US] .= 1
  #
  CN=Select(Nation,"CN")
  area65s=Select(Area65,(from="AB",to="NU"))
  AreaNatMap[area65s,CN] .= 1
  #
  MX=Select(Nation,"MX")
  area65=Select(Area65,"MX")
  AreaNatMap[area65,MX] = 1
  #
  WriteDisk(db,"SInput/AreaNatMap",AreaNatMap)

  ########################
  # BaseSw[tv] Base Case Switch (1=Base Case)
  #
  BaseSw=1
  WriteDisk(db,"SInput/BaseSw",BaseSw)

  ########################
  # BCarbonSw[Year] Black Carbon coefficient switch (1=POCX set relative to PM25)
  #
  # Switch is set to 1 if Black Carbon emissions are to be set at a ratio
  # to PM25 rather than from historical inventories. 
  #
  @. BCarbonSw=0
  WriteDisk(db,"SInput/BCarbonSw",BCarbonSw)

  ########################
  # ECCProMap[ECC,Process] Economic Sectors (ECC) to Oil and Gas Process (Process) Map
  #
  @. ECCProMap=0
  #
  ecc = Select(ECC,"LightOilMining")
  process = Select(Process,"LightOilMining")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"HeavyOilMining")
  process = Select(Process,"HeavyOilMining")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"FrontierOilMining")
  process = Select(Process,"FrontierOilMining")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"PrimaryOilSands")
  process = Select(Process,"PrimaryOilSands")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"SAGDOilSands")
  process = Select(Process,"SAGDOilSands")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"CSSOilSands")
  process = Select(Process,"CSSOilSands")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"OilSandsMining")
  process = Select(Process,"OilSandsMining")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"OilSandsUpgraders")
  process = Select(Process,"OilSandsUpgraders")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"OilPipeline")
  processes = Select(Process,["LightOilMining","HeavyOilMining","PrimaryOilSands",
      "SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders"])
  ECCProMap[ecc,processes] .= 1
  #
  eccs = Select(ECC,["NGDistribution","NGPipeline"])
  processes = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction"])
  ECCProMap[eccs,processes] .= 1
  #
  ecc = Select(ECC,"ConventionalGasProduction")
  process = Select(Process,"ConventionalGasProduction")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"SweetGasProcessing")
  process = Select(Process,"SweetGasProcessing")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"UnconventionalGasProduction")
  process = Select(Process,"UnconventionalGasProduction")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"SourGasProcessing")
  process = Select(Process,"SourGasProcessing")
  ECCProMap[ecc,process] = 1
  #
  ecc = Select(ECC,"LNGProduction")
  process = Select(Process,"LNGProduction")
  ECCProMap[ecc,process] = 1
  #
  WriteDisk(db,"SInput/ECCProMap",ECCProMap)

  ########################
  # ElecPrSw[Area,Year] Electricity Price Switch (0=Exogenous Prices)
  #
  # Electricity Prices are initially exogneous
  #
  for year in Years
    ElecPrSw[:,year] .= 0
  end
  WriteDisk(db,"SInput/ElecPrSw",ElecPrSw)

  ########################
  # FFPMap[FuelEP,Fuel] Map between FuelEP and Fuel
  #
  @. FFPMap=0

  for fuel in Fuels, fuelep in FuelEPs
    if Fuel[fuel] == FuelEP[fuelep]
      FFPMap[fuelep,fuel] = 1
    end
  end
  #
  # Crude Oil assigned price of Light Crude Oil (for electric utility sector)
  # Jeff Amlin 07/15/18
  #
  fuelep=Select(FuelEP,"CrudeOil")
  fuel=Select(Fuel,"LightCrudeOil")
  FFPMap[fuelep,fuel] = 1
  #
  # Non-Energy and Petroleum Feedstock
  # Remove this to facilitate Fuel prices - Jeff Amlin 5/31/2018
  #
  # # fuelep=Select(FuelEP,"LFO")
  # # fuel=Select(Fuel,["Lubricants","Naphtha","NonEnergy","PetroFeed"])
  # # FFPMap[fuelep,fuels] .= 1
  WriteDisk(db,"SInput/FFPMap",FFPMap)

  ########################
  # FFsMap[FuelFs,Fuel] Map between FuelFs and Fuel
  #
  @. FFsMap=0
  for fuel in Fuels, fuelfs in FuelFss
    if Fuel[fuel] == FuelFs[fuelfs]
      FFsMap[fuelfs,fuel] = 1
    end
  end
  WriteDisk(db,"SInput/FFsMap",FFsMap)

  #
  # ************************
  #
  CDTime = 2017
  CDYear = CDTime-ITime+1
  WriteDisk(db,"SInput/CDTime",CDTime)  
  WriteDisk(db,"SInput/CDYear",CDYear)    

  #
  # ********************
  #
  @. NationOutputMap=0
  NationOutputMap[CN] = 1
  WriteDisk(db,"SInput/NationOutputMap",NationOutputMap)

  #
  ########################
  # SecMap[ECC] ECC Set Map
  #
  # 1. The values of this descriptor are determined by the scope of the model. 
  # 2. It is given a value by selecting from the start of the ECC
  #    which corresponds to the sector to the last of the ECC.  It is
  #    then given the value of the place of that sector.
  # 3. J. Amlin 10/24/95
  #
  @. SecMap=0
  eccs=Select(ECC,(from="SingleFamilyDetached",to="OtherResidential"))
  SecMap[eccs] .= 1
  eccs=Select(ECC,(from="Wholesale",to="StreetLighting"))
  SecMap[eccs] .= 2
  eccs=Select(ECC,(from="Food",to="AnimalProduction"))
  SecMap[eccs] .= 3
  eccs=Select(ECC,(from="Passenger",to="CommercialOffRoad"))
  SecMap[eccs] .= 4
  ecc=Select(ECC,"Miscellaneous")
  SecMap[ecc] = 5
  WriteDisk(db,"SInput/SecMap",SecMap)

  ########################
  # xProcSw[PI,Year] Procedure on/off Switch
  #
  # 1. The values of this descriptor are determined by the scope of the model. 
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 10/24/95
  #
  # Endogenous = 1
  for year in Years, p in PIs
    xProcSw[p,year] = 1
  end
  WriteDisk(db,"SInput/xProcSw",xProcSw)

  ########################
  # Data Values
  ########################

  ########################
  # CalibLTime[Area] Last Year of Load Curve Calibration (Year)
  #
  for area in Areas
    CalibLTime[area]=xHisTime
  end
  WriteDisk(db,"SInput/CalibLTime",CalibLTime)

  ########################
  # Days[Month] Days per Month
  #
  # 1. Gregorian calendar values.
  #    (Winter = Jan-Apr, Spring = May-June, Summer = July-August
  #     Fall = Sept-Oct, Latefall = Nov-Dec.)
  # 2. The data is read in directly.
  # 3. P. Cross 9/29/95
  #             
  DaysPerMonth[Select(Month,"Summer")] = 183
  DaysPerMonth[Select(Month,"Winter")] = 182
  WriteDisk(db,"SInput/DaysPerMonth",DaysPerMonth)

  ########################
  # EEConv[-] Electric Energy Conversion (KJ/kWh)
  #
  # 1. This is the engineering value.
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 10/24/95
  #
  EEConv=3412
  WriteDisk(db,"SInput/EEConv",EEConv)

  ########################
  # ENPNSw[Fuel,Nation,Year] Wholesale Price (ENPN) Switch (1=Endogenous)
  #
  @. ENPNSw=0
  WriteDisk(db,"SInput/ENPNSw",ENPNSw)

  #
  # ********************
  #
  # ETABY[Market] Beginning Year for Emission Trading Allowances (Year)
  #
  # 1. The default value is set to a high number.
  # 2. The data is assigned via an equation.
  # 3. P. Cross 6/16/98
  #
  @. ETABY=2200
  WriteDisk(db,"SInput/ETABY",ETABY)
  
  #
  # ********************
  #
  @. FuelLimit = 1.0
  WriteDisk(db,"SCalDB/FuelLimit",FuelLimit)

  #
  # ********************
  #
  # GECONV[-] Gas Energy Conversion (KJ/THERM)
  #
  # 1. This is the engineering value.
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 10/24/95
  #
  GECONV=10
  # WriteDisk(db,"SInput/GECONV",GECONV)

  ########################
  # GMMult[Nation,Year] Marketable Gas Production Multiplier (TBtu/TBtu)
  #
  @. GMMult=1
  WriteDisk(db,"SInput/GMMult",GMMult)

  ########################
  # Hours[Month] Hours per Month
  #
  # 1. Gregorian calendar values.
  # 2. The total hours per month (ND) times 24 hours
  # 3. J. Amlin 10/24/95
  #
  @. HoursPerMonth=DaysPerMonth*24
  WriteDisk(db,"SInput/HoursPerMonth",HoursPerMonth)

  ########################
  # LogSw[Year] Switch which indicates whether or not to produce log files (Switch)
  #
  # Log switch - switch that tells the model to make log files (LogSw=1) or
  # do not make log files (LogSw=0)
  #
  # @. LogSw=0
  # WriteDisk(db,"SInput/LogSw",LogSw)

  #
  # ********************
  #
  for year in Years
    MaxIter[year] = 1.0
  end
  WriteDisk(db,"SInput/MaxIter",MaxIter)

  #
  # ********************
  #
  # OUDmdFr[FuelEP,ECC,Area,Year] Own Use Fraction of Demands (Btu/Btu)
  #
  @. OUDmdFr=0
  #
  # Sectors which have Own Use Oil
  #
  ecc=Select(ECC,"UtilityGen")
  fueleps=Select(FuelEP,["Asphaltines","AviationGasoline","Diesel","HFO","JetFuel",
                "Kerosene","LFO","LPG","CrudeOil","PetroCoke","StillGas"])
  OUDmdFr[fueleps,ecc,:,:] .= 1
  #
  # Sectors which have Own Use Natural Gas
  #
  eccs=Select(ECC,["Petroleum","OilPipeline","LightOilMining","HeavyOilMining","FrontierOilMining",
             "NGDistribution","NGPipeline","ConventionalGasProduction","SweetGasProcessing",
             "UnconventionalGasProduction","SourGasProcessing","UtilityGen","LNGProduction"])
  fuelep=Select(FuelEP,"NaturalGas")
  OUDmdFr[fuelep,eccs,:,:] .= 1
  #
  # All Raw Natural Gas is Own Use
  #
  fuelep=Select(FuelEP,"NaturalGasRaw")
  OUDmdFr[fuelep,:,:,:] .= 1
  WriteDisk(db,"SInput/OUDmdFr",OUDmdFr)

  ########################
  # PCERG[Fuel,ECC,Area] Energy Requirement Growth Rate (1/Yr)
  #
  # 1. Source: SEDS (1960-1975 history)
  # 2. The growth rates are read for residential, commercial, and industrial
  #    sectors and is mapped over to the corresponding economic categories.
  # 3. J. Amlin 10/24/95
  #
  eccs=findall(SecMap[:] .==1)
  PCERG[Select(Fuel,"NaturalGas"),eccs,:] .= 0.0502
  PCERG[Select(Fuel,"LFO"),eccs,:] .= 0.0130
  PCERG[Select(Fuel,"Coal"),eccs,:] .= -0.1088
  PCERG[Select(Fuel,"Biomass"),eccs,:] .= 0.0000
  PCERG[Select(Fuel,"Electric"),eccs,:] .= 0.0768
  #
  eccs=findall(SecMap[:] .==2)
  PCERG[Select(Fuel,"NaturalGas"),eccs,:] .= 0.1540
  PCERG[Select(Fuel,"LFO"),eccs,:] .= 0.0172
  PCERG[Select(Fuel,"Coal"),eccs,:] .= -0.1073
  PCERG[Select(Fuel,"Biomass"),eccs,:] .= 0.0000
  PCERG[Select(Fuel,"Electric"),eccs,:] .= 0.0742
  #
  eccs=findall(SecMap[:] .==3)
  PCERG[Select(Fuel,"NaturalGas"),eccs,:] .= 0.2239
  PCERG[Select(Fuel,"LFO"),eccs,:] .= 0.0342
  PCERG[Select(Fuel,"Coal"),eccs,:] .= -0.2014
  PCERG[Select(Fuel,"Biomass"),eccs,:] .= 0.0000
  PCERG[Select(Fuel,"Electric"),eccs,:] .= 0.1002
  #
  # TODOPromula - Transportation has same values as Industrial. LJD, 25/03/07
  eccs=findall(SecMap[:] .==4)
  PCERG[Select(Fuel,"NaturalGas"),eccs,:] .= 0.2239
  PCERG[Select(Fuel,"LFO"),eccs,:] .= 0.0342
  PCERG[Select(Fuel,"Coal"),eccs,:] .= -0.2014
  PCERG[Select(Fuel,"Biomass"),eccs,:] .= 0.0000
  PCERG[Select(Fuel,"Electric"),eccs,:] .= 0.1002

  WriteDisk(db,"SInput/PCERG",PCERG)

  ########################
  # PCovMap[FuelEP,ECC,PCov,Area,Year] Pollution Coverage Map (1=Mapped)
  #
  @. PCovMap=0
  #
  # PCov(Energy) is default
  #
  pcov=Select(PCov,"Energy")
  PCovMap[:,:,pcov,:,:] .= 1
  #
  # PCov(Oil) covers oil related fuels for all sectors except Utility Generation 
  # using the Own Use fraction (OUDmdFr).
  #
  fueleps=Select(FuelEP,["Asphaltines","AviationGasoline","Diesel","HFO","JetFuel",
                "Kerosene","LFO","LPG","CrudeOil","PetroCoke","StillGas"])
  pcov=Select(PCov,"Oil")
  for year in Years, area in Areas, ecc in ECCs, fuelep in fueleps
    PCovMap[fuelep,ecc,pcov,area,year] = 1*(1-OUDmdFr[fuelep,ecc,area,year])
  end
  pcov=Select(PCov,"Energy")
  for year in Years, area in Areas, ecc in ECCs, fuelep in fueleps
    PCovMap[fuelep,ecc,pcov,area,year] = 1*OUDmdFr[fuelep,ecc,area,year]
  end
  #
  # PCov(NaturalGas) covers natural gas related fuels
  #
  fueleps=Select(FuelEP,["NaturalGas","NaturalGasRaw"])
  pcov=Select(PCov,"NaturalGas")
  for year in Years, area in Areas, ecc in ECCs, fuelep in fueleps
    PCovMap[fuelep,ecc,pcov,area,year] = 1*(1-OUDmdFr[fuelep,ecc,area,year])
  end
  pcov=Select(PCov,"Energy")
  for year in Years, area in Areas, ecc in ECCs, fuelep in fueleps
    PCovMap[fuelep,ecc,pcov,area,year] = 1*OUDmdFr[fuelep,ecc,area,year]
  end
  WriteDisk(db,"SInput/PCovMap",PCovMap)

  ########################
  # PGrowth[Market] Growth Factor for Pollution Goals (Tonnes/Yr/(Tonnes/Yr))
  #
  # 1. Source
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 04/15/04
  #
  @. PGrowth=0.03
  WriteDisk(db,"SInput/PGrowth",PGrowth)

  ########################
  # PIAT[ECC,Poll] Pollution Inventory Averaging Time (Years)
  #
  # 1. Source
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 04/15/04
  #
  @. PGrowth=1.00
  WriteDisk(db,"SInput/PIAT",PIAT)

  ########################
  # PolConv[Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  #
  # 1. Source
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 04/15/04
  # 4. H. Paulin 09/06/15
  #
  @. PolConv=1.00
  PolConv[Select(Poll,"CO2")] = 1 
  PolConv[Select(Poll,"CH4")]=28
  PolConv[Select(Poll,"N2O")]=265
  PolConv[Select(Poll,"SF6")]=23500
  PolConv[Select(Poll,"PFC")]=7390
  PolConv[Select(Poll,"HFC")] = 1430
  PolConv[Select(Poll,"NF3")] = 16100
  WriteDisk(db,"SInput/PolConv",PolConv)

  ########################
  # POCXMax[FuelEP,Poll,Year] Pollution Coefficient Maximum (Tonnes/TBtu)
  #
  # Default coefficient maximum is 1E12
  # R.Levesque 11/6/12
  #
  @. POCXMax=1e12
  WriteDisk(db,"SInput/POCXMax",POCXMax)

  ########################
  # RefSwitch[tv] Reference Case Switch (1=Reference Case)
  #
  RefSwitch=0
  WriteDisk(db,"SInput/RefSwitch",RefSwitch)

  ########################
  # RunExtra[tv] Execute the current year one more time to capture CT impacts (1=Run)
  #
  RunExtra=0
  WriteDisk(db,"SInput/RunExtra",RunExtra)

  ########################
  # SqOCF[ECC,Area,Year] Sequestering eCO2 Reduction Operating Cost Factor ($/$)
  #
  # "Sq Curves.xls" and "O&G_Province.doc" RBL 1/3/02
  # For Gas Processing email from Glasha 1/10/2014
  #
  @. SqOCF=0.08
  eccs=Select(ECC,["SweetGasProcessing","SourGasProcessing"])
  SqOCF[eccs,:,:] .= 0.04
  WriteDisk(db,"SInput/SqOCF",SqOCF)

  ########################
  # SqPGMult[ECC,Poll,Area,Year] Sequestering Gratis Permit Multiplier (Tonnes/Tonnes)
  #
  @. SqPGMult=1.0
  WriteDisk(db,"SInput/SqPGMult",SqPGMult)

  ########################
  # TDEF[Fuel,Area,Year] Sequestering eCO2 Reduction Operating Cost Factor ($/$)
  #
  # "Sq Curves.xls" and "O&G_Province.doc" RBL 1/3/02
  # For Gas Processing email from Glasha 1/10/2014
  #
  @. TDEF=1.0
  fuel=Select(Fuel,"Electric")
  TDEF[fuel,:,:] .= 0.93
  WriteDisk(db,"SInput/TDEF",TDEF)

  ########################
  # xCDUF[Class,Day,Month,Area] Class Daily Use Factor for Gas
  #
  # Developed by J. Amlin from NEGC data (Gas Usage Factors.xls).
  # Minimum loads adjusted to include cooking in summer.
  #
  @. xCDUF=0
  Summer=Select(Month,"Summer")
  Winter=Select(Month,"Winter")
  Peak=Select(Day,"Peak")
  Average=Select(Day,"Average")
  Minimum=Select(Day,"Minimum")
  #
  Res=Select(Class,"Res")
  xCDUF[Res,Peak,Summer,:] .= 2.6240
  xCDUF[Res,Average,Summer,:] .= 0.2247
  xCDUF[Res,Minimum,Summer,:] .= 0.0500
  xCDUF[Res,Peak,Winter,:] .= 5.9110
  xCDUF[Res,Average,Winter,:] .= 1.7795
  xCDUF[Res,Minimum,Winter,:] .= 0.5140
  #
  Com=Select(Class,"Com")
  xCDUF[Com,Peak,Summer,:] .= 1.6590
  xCDUF[Com,Average,Summer,:] .= 0.2400
  xCDUF[Com,Minimum,Summer,:] .= 0.0500
  xCDUF[Com,Peak,Winter,:] .= 3.4800
  xCDUF[Com,Average,Winter,:] .= 1.7642
  xCDUF[Com,Minimum,Winter,:] .= 0.5610
  #
  Ind=Select(Class,"Ind")
  xCDUF[Ind,Peak,Summer,:] .= 1.2310
  xCDUF[Ind,Average,Summer,:] .= 1.0361
  xCDUF[Ind,Minimum,Summer,:] .= 0.6020
  xCDUF[Ind,Peak,Winter,:] .= 1.1580
  xCDUF[Ind,Average,Winter,:] .= 0.9637
  xCDUF[Ind,Minimum,Winter,:] .= 0.5650
  #
  WriteDisk(db,"SInput/xCDUF",xCDUF)

  ########################
  # xCLSF[Class,Hour,Day,Month,Area] Class Daily Use Factor for Gas
  #
  # 1. The data is from NEPOOL
  # 2. The data is read in.
  #    The class load shapes are normalized to the annual energy.
  # 3. x. Dai 4/11/95
  #
  #  Load Shape for Misc. Demand
  #  NEPOOL
  #
  @. xCLSF=0
  #
  Misc=Select(Class,"Misc")
  xCLSF[Misc,:,Peak,:,:] .=2.00
  xCLSF[Misc,:,Average,:,:] .= 1.00
  xCLSF[Misc,:,Minimum,:,:] .= 0.60
  #
  # Normalize the average day load shape.
  # 
  for class in Classes
    ANLENG[class]=sum(xCLSF[class,hour,Average,month,1]*HoursPerMonth[month] for month in Months, hour in Hours)/8760
  end
  for area in Areas, month in Months, hour in Hours, class in Classes
    @finite_math xCLSF[class,hour,Average,month,area]=xCLSF[class,hour,Average,month,area]/ANLENG[class]
  end
  #
  WriteDisk(db,"SInput/xCLSF",xCLSF)

  ########################
  # xPRExp[ECC,Poll,Area,Year] Exogenous Reduction Private Expenses (M$/Yr)
  #
  # Exogenous reductions are initialized at zero (no exogenous reduction)
  # Ian 02/09/2012
  #
  @. xPRExp=0
  WriteDisk(db,"SInput/xPRExp",xPRExp)

  ########################
  # FuPolSwitch[ECC,Poll,Area,Year] Fugitive Pollution Switch (0=Exogenous)
  # MEPolSwitch[ECC,Poll,Area,Year] Process Pollution Switch (0=Exogenous)
  # VnPolSwitch[ECC,Poll,Area,Year] Venting Pollution Switch (0=Exogenous)
  # FlPolSwitch[ECC,Poll,Area,Year] Flaring Pollution Switch (0=Exogenous)
  #
  # Default value for MEPolSwitch is Endogenous
  # Ian 06/14/2013
  #
  @. MEPolSwitch=1
  @. FuPolSwitch=1
  @. VnPolSwitch=1
  @. FlPolSwitch=1
  WriteDisk(db,"SInput/MEPolSwitch",MEPolSwitch)
  WriteDisk(db,"SInput/FuPolSwitch",FuPolSwitch)
  WriteDisk(db,"SInput/VnPolSwitch",VnPolSwitch)
  WriteDisk(db,"SInput/FlPolSwitch",FlPolSwitch)

  ########################
  # xSalSw[Class] Switch for Exogenous Sales (True=Exogenous)
  #
  # 1. This is defined by the structure of the model.
  # 2. The data is input through an equation.
  # 3. J. Amlin 10/24/95
  #
  @. xSalSw=0
  Misc=Select(Class,"Misc")
  xSalSw[Misc] = 1
  WriteDisk(db,"SInput/xSalSw",xSalSw)

  ########################
  #
  # CALIBRATION - Flags, Switches, Limits, etc.
  #
  ########################

  ########################
  # YEndTime[--] Fixed End-year for Calibration (Date)
  #
  # 1. Source: Model Structure.
  # 2. During the price calibration, all available years should be used to 
  #    compute the delivery charges (YEndTime=Year:M-1).
  # 3. J. Amlin 10/24/95
  #
  YEndTime=MaxTime
  WriteDisk(db,"SInput/YEndTime",YEndTime)

  ########################
  # YFPDChgF[Fuel,ES,Area,Year] FPDChgF Calibration Control
  #
  # The future values of the fuel delivery charge (FPDChgF) are equal to
  # the last historical value (YFPDChgF=3). Jeff Amlin 02/11/19
  #
  @. YFPDChgF=3
  WriteDisk(db,"SInput/YFPDChgF",YFPDChgF)

  ########################
  # YHPKM[Month,Area,Year] Calibration Control Variable for HPKM
  #
  # 1. The values are ramped to one.
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 10/24/95
  #
  @. YHPKM=1
  # YHPKM[:,:,Zero] .= 3
  YHPKM[:,:,Zero] .= 1
  WriteDisk(db,"SInput/YHPKM",YHPKM)

  ########################
  # YUFP[--] Upper Error Limit for Fuel Prices (PERCENT)
  #
  # 1. Calibration maximum uncertainty - standard estimation.
  # 2. The data is assigned via an equation.
  # 3. J. Amlin 10/24/95
  #
  YUFP=0.1
  WriteDisk(db,"SInput/YUFP",YUFP)

  ########################
  # YUSales[--] Upper Error Limit for Sales (Percent)
  #
  # 1. Calibration maximum uncertainty - standard estimation.
  # 2. The data is assigned via an equation.
  # 3. P. Cross 3/21/96
  #
  YUSales=0.1
  WriteDisk(db,"SInput/YUSales",YUSales)

  ########################
  # ZCarConv[FuelEP,Poll] Convert from $/Tonnes eCO2 to $/mmBtu
  #
  # The conversion of $/tonne to $/mmBtu is based on the physical properties
  # of each fuel and was developed by Jessica Norup in the spreadsheet
  # "Carbon Tax Conversion Factors Nov 30, 2009.xls"  J. Amlin 11/30/09
  #
  @. ZCarConv=0
  polls=Select(Poll,["CO2","CH4","N2O"])
  ZCarConv[FuelEPs,polls] = [ 0.000000000  0.000000000  0.000000000   #  Ammonia
                              0.071278858  0.000003733  0.000006482   #  Asphaltine
                              0.071278858  0.000003733  0.000006482   #  Aviation Gas
                              0.000000000  0.000000000  0.000000000   #  Biodiesel
                              0.000000000  0.000000000  0.000000000   #  Biogas
                              0.000000000  0.000000000  0.000000000   #  Biojet
                              0.000000000  0.000000000  0.000000000   #  Biomass
                              0.086208768  0.000141886  0.000000709   #  Coal
                              0.086208768  0.000141886  0.000000709   #  Coke
                              0.086208768  0.000141886  0.000000709   #  Coke Oven Gas
                              0.0689316    0.000005521  0.000007208   #  CrudeOil
                              0.073253     0.000001506  0.000005916   #  Diesel
                              0.000000000  0.000000000  0.000000000   #  Ethanol
                              0.0689316    0.000005521  0.000007208   #  Gasoline
                              0.0774752    0.000001414  0.000001587   #  HFO
                              0.000000000  0.000000000  0.000000000   #  Hydrogen
                              0.071278858  0.000003733  0.000006482   #  Jet Fuel
                              0.074024485  0.000000706  0.000000163   #  Kerosene
                              0.074024485  0.000000706  0.000000163   #  LFO
                              0.062881865  0.000001124  0.000004498   #  LPG
                              0.052093936  0.000001019  0.000000964   #  NaturalGas
                              0.052093936  0.000001019  0.000000964   #  NaturalGasRaw
                              0.0774752    0.000001414  0.000001587   #  Petro Coke
                              0.000000000  0.000000000  0.000000000   #  RNG
                              0.062881865  0.000001124  0.000004498   #  Still Gas
                              0.000000000  0.000000000  0.000000000 ] #  Waste
  WriteDisk(db,"SInput/ZCarConv",ZCarConv)

  # ZCarConv[FuelEPs,polls] = [ 0.000000000  0.000000000  0.000000000   #  Ammonia
  #                             0.071278858  0.000003733  0.000006482   #  Asphaltine
  #                             0.071278858  0.000003733  0.000006482   #  Aviation Gas
  #                             0.000000000  0.000000000  0.000000000   #  Biodiesel
  #                             0.000000000  0.000000000  0.000000000   #  Biogas
  #                             0.000000000  0.000000000  0.000000000   #  Biojet
  #                             0.000000000  0.000000000  0.000000000   #  Biomass
  #                             0.086208768  0.000141886  0.000000709   #  Coal
  #                             0.086208768  0.000141886  0.000000709   #  Coke
  #                             0.086208768  0.000141886  0.000000709   #  Coke Oven
  #                             0.0689316    0.000005521  0.000007208   #  CrudeOil
  #                             0.073253     0.000001506  0.000005916   #  Diesel
  #                             0.000000000  0.000000000  0.000000000   #  Ethanol
  #                             0.0689316    0.000005521  0.000007208   #  Gasoline
  #                             0.0774752    0.000001414  0.000001587   #  HFO
  #                             0.000000000  0.000000000  0.000000000   #  Hydrogen
  #                             0.071278858  0.000003733  0.000006482   #  Jet Fuel
  #                             0.074024485  0.000000706  0.000000163   #  Kerosene
  #                             0.074024485  0.000000706  0.000000163   #  LFO
  #                             0.062881865  0.000001124  0.000004498   #  LPG
  #                             0.052093936  0.000001019  0.000000964   #  NaturalGas
  #                             0.052093936  0.000001019  0.000000964   #  NaturalGasRaw
  #                             0.0774752    0.000001414  0.000001587   #  Petro Coke
  #                             0.000000000  0.000000000  0.000000000   #  RNG
  #                             0.062881865  0.000001124  0.000004498   #  Still Gas
  #                             0.000000000  0.000000000  0.000000000 ] #  Waste


  ########################
  # AGFr[ECC,Poll,Area,Year] Government Subsidy ($/$)
  # AreaMarket[Area,Market,Year] Areas included in Market
  # CapTrade[Market,Year] Emission Cap and Trading Switch (1=Trade, Cap Only=2)
  # ECCMarket[ECC,Market,Year] Economic Categories included in Market
  # EITarget[ECC,Poll,PCov,Area,Year] Target Emissions Intensity (Tonnes/M$)
  # ETAFAP[Market,Year] Safety-Valve Maxium Price or Cost of Foreign Allowances ($/Tonne)
  # ETAIncr[Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  # ETAMin[Market,Year] Minimum Price for Allowances ($/Tonne)
  # xGoalPol[Market,Year] Pollution Goal (Tonnes/Yr)
  # GratSw[Market] Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous)
  # ISaleSw[Market,Year] Switich allow International Sales of Permits (1=Yes)
  # PAdCost[ECC,Poll,Area,Year] Policy Administrative Cost (Exogenous)
  # PCovMarket[PCov,Market,Year] Types of Pollution included in Market
  # PHYear[Market] Pollution Grandfathering Year (Date)
  # PollMarket[Poll,Market,Year] Pollutants included in Market
  # xETAPr[Market,Year] Initial Cost of Emission Trading Allowances ($/Tonne)
  # xPGratis[ECC,Poll,PCov,Area,Year] Exogenous Gratis Permits (Tonnes/Yr)
  # xTGratis[ArMarket,Yearr] Exogenous Gratis Permits (Tonnes/Yr)

  @. AGFr=0.0
  WriteDisk(db,"SInput/AGFr",AGFr)

  @. CapTrade=0.0
  WriteDisk(db,"SInput/CapTrade",CapTrade)

  @. PAdCost=0.0
  WriteDisk(db,"SInput/PAdCost",PAdCost)

  @. AreaMarket=0.0
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)

  @. CBSw=0.0
  WriteDisk(db,"SInput/CBSw",CBSw)

  @. ECCMarket=0.0
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)

  @. ETAFAP=0.0
  WriteDisk(db,"SInput/ETAFAP",ETAFAP)

  @. ETAIncr=0.0
  WriteDisk(db,"SInput/ETAIncr",ETAIncr)

  @. ETAMin=0.0
  WriteDisk(db,"SInput/ETAMin",ETAMin)

  @. xGoalPol=0.0
  WriteDisk(db,"SInput/xGoalPol",xGoalPol)

  @. GratSw=0.0
  WriteDisk(db,"SInput/GratSw",GratSw)

  @. ISaleSw=0.0
  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  @. PCovMarket=0.0
  WriteDisk(db,"SInput/PCovMarket",PCovMarket)

  @. PHYear=0.0
  WriteDisk(db,"SInput/PHYear",PHYear)

  @. PollMarket=0.0
  WriteDisk(db,"SInput/PollMarket",PollMarket)

  @. EITarget=0.0
  WriteDisk(db,"SInput/EITarget",EITarget)

  @. xETAPr=0.0
  WriteDisk(db,"SInput/xETAPr",xETAPr)

  @. xPGratis=0.0
  WriteDisk(db,"SInput/xPGratis",xPGratis)

  @. xTGratis=0.0
  WriteDisk(db,"SInput/xTGratis",xTGratis)

end # end SData_Inputs

function Control(db)
  SData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end #end module
