#
# Supply.jl
#

module Supply

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime,ModelPath,ITime
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  
  Current::Int = year+ITime-1
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  Classes::Vector{Int} = collect(Select(Class))
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  Days_All::Vector{Int} = collect(Select(Day))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  Hours_All::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  PI::SetArray = ReadDisk(db,"SInput/PIKey")
  PIDS::SetArray = ReadDisk(db,"SInput/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  SegKey::SetArray = ReadDisk(db,"MainDB/SegKey")
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  
  #
  # Pointer "Keys" for PI and Seg
  #
  AccountsKey = Select(PI,"Accounts")
  LoadcurveKey = Select(PI,"Loadcurve")
  DailyUseKey = Select(PI,"DailyUse")
  PriceKey = Select(PI,"Price")   
  SupplyKey = Select(Seg,"Supply")

  ADG::VariableArray{1} = ReadDisk(db,"SOutput/ADG",year) #[Area,Year]  Annual Average Load for Gas
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  BaseAdj::VariableArray{3} = ReadDisk(db,"SCalDB/BaseAdj",year) #[Day,Month,Year]  Adjustment Based on All Years (MW/MW)
  CDUC::VariableArray{4} = ReadDisk(db,"SOutput/CDUC",year) #[Class,Day,Month,Area,Year] Gas Daily Use Curve (MTherm/Day)
  CDUF::VariableArray{4} = ReadDisk(db,"SCalDB/CDUF") #[Class,Day,Month,Area,Year] Factor for Gas (Therm/Therm)
  CgInv::VariableArray{2} = ReadDisk(db,"SOutput/CgInv",year) #[ECC,Area,Year]  Cogeneration Investments (M$/Yr)
  CLSF::VariableArray{5} = ReadDisk(db,"SCalDB/CLSF") #[Class,Hour,Day,Month,Area]  Electric Class Load Shape (MW/MW)
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") #[Area,CNArea]  Map between Area and Canada Economic Areas (CNArea)
  DaysPerMonth::VariableArray{1} = ReadDisk(db,"SInput/DaysPerMonth") # [Month] Days per Month
  DInv::VariableArray{2} = ReadDisk(db,"SOutput/DInv",year) #[ECC,Area,Year]  Device Investments (M$/Yr)
  DmdES::VariableArray{3} = ReadDisk(db,"SOutput/DmdES",year) #[ES,Fuel,Area,Year]  Energy Demand (TBtu/Yr)
  DPKM::VariableArray{2} = ReadDisk(db,"SCalDB/DPKM",year) #[Month,Area,Year]  Gas Peak Day Multiplier
  ECCCLMap::VariableArray{2} = ReadDisk(db,"MainDB/ECCCLMap") #[ECC,Class]  Map Between ECC and Class (map)
  ElecPrSwNext::VariableArray{1} = ReadDisk(db,"SInput/ElecPrSw",next) #[Area,Year]  Electricity Price Switch (0 = Exogenous Prices)
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  ENMSMNext::VariableArray{2} = ReadDisk(db,"SOutput/ENMSM",next) #[Fuel,Area,Year]  Energy Supply Constraint Mult.
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  ENPNNext::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",next) #[Fuel,Nation,Year]  Price Normal ($/mmBtu)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (tBtu)
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0  
  Expend::VariableArray{2} = ReadDisk(db,"SOutput/Expend",year) #[ECC,Area,Year]  Expenditures (M$/Yr)
  Exports::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FlInv::VariableArray{2} = ReadDisk(db,"SOutput/FlInv",year) #[ECC,Area,Year]  Flaring Reduction Investments (M$/Yr)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FPFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPF",next) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FPBaseFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPBaseF",next) #[Fuel,ES,Area,Year]  Delivered Fuel Price without Taxes ($/mmBtu)
  FPDChgFNext::VariableArray{3} = ReadDisk(db,"SCalDB/FPDChgF",next) #[Fuel,ES,Area,Year]  Fuel Delivery Charge (Real $/mmBtu)
  FPMarginFNext::VariableArray{3} = ReadDisk(db,"SInput/FPMarginF",next) #[Fuel,ES,Area,Year]  Refinery/Distributor Margin ($/$)
  FPPolTaxF::VariableArray{3} = ReadDisk(db,"SOutput/FPPolTaxF",year) #[Fuel,ES,Area,Year]  Pollution Tax (Real $/mmBtu)
  FPPolTaxFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPPolTaxF",next) #[Fuel,ES,Area,Year]  Pollution Tax (Real $/mmBtu)
  FPSMF::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",year) #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPSMFNext::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",next) #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPTaxF::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",year) #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  FPTaxFNext::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",next) #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  FPTx::VariableArray{3} = ReadDisk(db,"SOutput/FPTx",year) #[Fuel,ECC,Area,Year]  Energy Tax ($/mmBtu)
  FsFP::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",year) #[Fuel,ES,Area,Year]  Feedstock Fuel Price ($/mmBtu)
  FsFPNext::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",next) #[Fuel,ES,Area,Year]  Feedstock Fuel Price ($/mmBtu)
  FuelExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/FuelExpenditures",year) #[ECC,Area,Year]  Fuel Expenditures (M$)
  FuInv::VariableArray{2} = ReadDisk(db,"SOutput/FuInv",year) #[ECC,Area,Year]  Other Fugitives Reduction Investments (M$/Yr)
  FuOMExp::VariableArray{2} = ReadDisk(db,"SOutput/FuOMExp",year) #[ECC,Area,Year]  Other Fugitives Reduction O&M Expenses (M$/Yr)
  GO::VariableArray{2} = ReadDisk(db,"MOutput/GO",year) #[ECC,Area,Year]  Gross Output (Real M$/Yr)
  GTSales::VariableArray{1} = ReadDisk(db,"SOutput/GTSales",year) #[Area,Year]  Total Annual Usage of Gas (MTherm/Yr)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") #[Month]  Hours per Month (Hours/Month)
  Imports::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationNext::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",next) #[Area,Year]  Inflation Index ($/$)
  InflationNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) #[Nation,Year]  Inflation Index ($/$)
  InflationNationNext::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",next) #[Nation,Year]  Inflation Index ($/$)
  InflationRateNext::VariableArray{1} = ReadDisk(db,"MOutput/InflationRate",next) #[Area,Year]  Inflation Rate (1/Yr)
  InflationRateNationNext::VariableArray{1} = ReadDisk(db,"MOutput/InflationRateNation",next) #[Nation,Year]  Inflation Rate (1/Yr)
  KJBtu::Float32 = 1.054615
  LDCECC::VariableArray{5} = ReadDisk(db,"SOutput/LDCECC",year) #[ECC,Hour,Day,Month,Area,Year]  Electric Loads Dispatched (MW)
  MDG::VariableArray{1} = ReadDisk(db,"SOutput/MDG",year) #[Area,Year]  Annual Minimum Load for Gas
  MEInv::VariableArray{2} = ReadDisk(db,"SOutput/MEInv",year) #[ECC,Area,Year]  Non Energy Reduction Investments (M$/Yr)
  MEOMExp::VariableArray{2} = ReadDisk(db,"SOutput/MEOMExp",year) #[ECC,Area,Year]  Non Energy Reduction O&M Expenses(M$/Yr)
  MinLd::VariableArray{2} = ReadDisk(db,"SOutput/MinLd",year) #[Month,Area,Year]  Monthly Minimum Load (MW/Month)
  MonOut::VariableArray{2} = ReadDisk(db,"SOutput/MonOut",year) #[Month,Area,Year]  Monthly Output (GWh/Month)
  OMExp::VariableArray{2} = ReadDisk(db,"SOutput/OMExp",year) #[ECC,Area,Year]  O&M Expenditures (M$)
  PDG::VariableArray{1} = ReadDisk(db,"SOutput/PDG",year) #[Area,Year]  Annual Peak Load for Gas
  PDP::VariableArray{1} = ReadDisk(db,"SOutput/PDP",year) #[Area,Year]  Annual Peak Load
  PENext::VariableArray{2} = ReadDisk(db,"SOutput/PE",next) #[ECC,Area,Year] Price of Electricity ($/MWh)
  PExp::VariableArray{3} = ReadDisk(db,"SOutput/PExp",year) #[ECC,Poll,Area,Year]  Permits Expenditures (M$/Yr)
  PExpExo::VariableArray{3} = ReadDisk(db,"SInput/PExpExo",year) #[ECC,Poll,Area,Year]  Exogenous Permits Expenditures (M$/Yr)
  PermitExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/PermitExpenditures",year) #[ECC,Area,Year]  Permits Expenditures (M$/Yr)
  PInv::VariableArray{2} = ReadDisk(db,"SOutput/PInv",year) #[ECC,Area,Year]  Process Investments (M$/Yr)
  PkHr::VariableArray{2} = ReadDisk(db,"SOutput/PkHr",year) #[Month,Area,Year]  Hour of Monthly Peak Load
  PkLoad::VariableArray{2} = ReadDisk(db,"SOutput/PkLoad",year) #[Month,Area,Year]  Monthly Peak Load (MW/Month)
  PkMonth::VariableArray{1} = ReadDisk(db,"SOutput/PkMonth",year) #[Area,Year]  Month of the Annual Peak Load
  POMExp::VariableArray{2} = ReadDisk(db,"SOutput/POMExp",year) #[ECC,Area,Year]  Process O&M Expenditures (M$)
  PreCalc::Float32 = ReadDisk(db,"MainDB/PreCalc")[1] # [tv] PreCalc = 2
  PRExp::VariableArray{3} = ReadDisk(db,"SOutput/PRExp",year) #[ECC,Poll,Area,Year]  Pollution Reduction Private Expenses (M$/Yr)
  PRExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/PRExpenditures",year) #[ECC,Area,Year]  Pollution Reduction Expenditures (M$/Yr)
  RPPAProd::VariableArray{1} = ReadDisk(db,"SpOutput/RPPAProd",year) #[Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPExports::VariableArray{1} = ReadDisk(db,"SpOutput/RPPExports",year) #[Nation,Year]  Refined Petroleum Products (RPP) Exports (TBtu/Yr)
  RPPImports::VariableArray{1} = ReadDisk(db,"SpOutput/RPPImports",year) #[Nation,Year]  Refined Petroleum Products (RPP) Imports (TBtu/Yr)
  SaEC::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",year) #[ECC,Area,Year]  Electricity Sales by ECC (GWh/YR)
  Sales::VariableArray{3} = ReadDisk(db,"SOutput/Sales",year) #[Class,Fuel,Area,Year]  Electricity Sales (GWh/YR)
  SDUC::VariableArray{3} = ReadDisk(db,"SOutput/SDUC",year) #[Day,Month,Area,Year]  System Load Curve (MTherm/Day)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map between Sector and ECC Sets (1=Res, 2=Com, 3=Ind, etc.)
  SegSw::VariableArray{1} = ReadDisk(db,"MainDB/SegSw") #[Seg] Segment Execution Switch
  SLDC::VariableArray{4} = ReadDisk(db,"SOutput/SLDC",year) #[Hour,Day,Month,Area,Year]  Electric System Load Curve (MW)
  SqInv::VariableArray{2} = ReadDisk(db,"SOutput/SqInv",year) #[ECC,Area,Year]  Sequestering Investments (M$/Yr)
  SqOMExp::VariableArray{2} = ReadDisk(db,"SOutput/SqOMExp",year) #[ECC,Area,Year]  Sequestering O&M Expenses (M$/Yr)
  StCap::VariableArray{1} = ReadDisk(db,"SOutput/StCap",year) #[Area,Year]  Steam Production Capacity (MW)
  StCapPrior::VariableArray{1} = ReadDisk(db,"SOutput/StCap",prior) #[Area,Prior]  Steam Production Capacity (MW)
  StCCNext::VariableArray{1} = ReadDisk(db,"SInput/StCC",next) #[Area,Year]  Capital Cost of Steam Capacity ($/mmBtu/Yr)
  StCCRNext::VariableArray{1} = ReadDisk(db,"SInput/StCCR",next) #[Area,Year]  Capital Charge Rate of Steam Capacity ($/($/Yr))
  StDemand::VariableArray{1} = ReadDisk(db,"SOutput/StDemand",year) #[Area,Year]  Demand for Steam (TBtu/Yr)
  StDmd::VariableArray{2} = ReadDisk(db,"SOutput/StDmd",year) #[FuelEP,Area,Year]  Steam Generation Fuel Demands (TBtu/Yr)
  StFFrac::VariableArray{2} = ReadDisk(db,"SInput/StFFrac",year) #[FuelEP,Area,Year]  Steam Generation Fuel Fraction (Btu/Btu)
  StFPol::VariableArray{3} = ReadDisk(db,"SOutput/StFPol",year) #[FuelEP,Poll,Area,Year]  Steam Generation Pollution (Tonnes/Yr)
  StGC::VariableArray{1} = ReadDisk(db,"SOutput/StGC",year) #[Area,Year]  Electric Generating Capacity from Steam Production (MW)
  StGCCM::VariableArray{1} = ReadDisk(db,"SOutput/StGCCM",year) #[Area,Year]  Incremental Electric Generating Capacity from Steam Production (MW)
  StGCPrior::VariableArray{1} = ReadDisk(db,"SOutput/StGC",prior) #[Area,Prior]  Electric Generating Capacity from Steam Production (MW)
  StHPRatio::VariableArray{1} = ReadDisk(db,"SInput/StHPRatio",year) #[Area,Year]  Steam Capacity Heat-to-Power Ratio (MW/MW)
  StHR::VariableArray{1} = ReadDisk(db,"SInput/StHR",year) #[Area,Year]  Steam Generation Heat Rate (Btu/Btu)
  StHRNext::VariableArray{1} = ReadDisk(db,"SInput/StHR",next) #[Area,Year]  Steam Generation Heat Rate (Btu/Btu)
  StHrAve::VariableArray{1} = ReadDisk(db,"SOutput/StHrAve",year) #[Area,Year]  Steam Generation Average Heat Rate (Btu/Btu)
  StHRPrior::VariableArray{1} = ReadDisk(db,"SOutput/StHrAve",prior) #[Area,Prior]  Steam Generation Average Heat Rate (Btu/Btu)
  StOMCNext::VariableArray{1} = ReadDisk(db,"SInput/StOMC",next) #[Area,Year]  O&M Cost of Steam Production ($/mmBtu)
  StPOCX::VariableArray{3} = ReadDisk(db,"SInput/StPOCX",year) #[FuelEP,Poll,Area,Year]  Steam Generation Pollution Coefficient (Tonnes/TBtu)
  StPur::VariableArray{2} = ReadDisk(db,"SOutput/StPur",year) #[ECC,Area,Year]  Net Steam Purchases (tBtu/Yr)
  StSold::VariableArray{2} = ReadDisk(db,"SOutput/StSold",year) #[ECC,Area,Year]  Excess Steam Generated (tBtu/Yr)
  StSubsidyNext::VariableArray{1} = ReadDisk(db,"SInput/StSubsidy",next) #[Area,Year]  Steam Subsidy from Electric Sales or Government ($/mmBtu)
  TaxExp::VariableArray{3} = ReadDisk(db,"SOutput/TaxExp",year) #[Fuel,ECC,Area,Year]  Tax Expenditure (M$)
  TDEF::VariableArray{2} = ReadDisk(db,"SInput/TDEF",year) #[Fuel,Area,Year]  Electricity T&D Efficiency (MW/MW)
  TDInv::VariableArray{1} = ReadDisk(db,"SOutput/TDInv",year) #[Area,Year]  Electric Transmission and Distribution Investments (M$/Yr)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)
  VnInv::VariableArray{2} = ReadDisk(db,"SOutput/VnInv",year) #[ECC,Area,Year]  Venting Reduction Investments (M$/Yr)
  VnOMExp::VariableArray{2} = ReadDisk(db,"SOutput/VnOMExp",year) #[ECC,Area,Year]  Venting Reduction O&M Expenses (M$/Yr)
  xENPNNext::VariableArray{2} = ReadDisk(db,"SInput/xENPN",next) #[Fuel,Nation,Year]  Exogenous Price Normal (Real $/mmBtu)
  xFPF::VariableArray{3} = ReadDisk(db,"SInput/xFPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Prices (Real $/mmBtu)
  xFPBaseF::VariableArray{3} = ReadDisk(db,"SInput/xFPBaseF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price without Taxes (Real $/mmBtu)
  xInflationNext::VariableArray{1} = ReadDisk(db,"MInput/xInflation",next) #[Area,Year]  Inflation Index ($/$)
  xInflationNationNext::VariableArray{1} = ReadDisk(db,"MInput/xInflationNation",next) #[Nation,Year]  Inflation Index ($/$)
  xPENext::VariableArray{2} = ReadDisk(db,"SInput/xPE",next) #[ECC,Area,Year]  Exogenous Electricity Price (Real $/MWh)
  xProcSw::VariableArray{1} = ReadDisk(db,"SInput/xProcSw",year) #[PI,Year] "Procedure on/off Switch"
  xSaEC::VariableArray{2} = ReadDisk(db,"SInput/xSaEC",year) #[ECC,Area,Year]  Historical ECC Sales (GWh)
  xSales::VariableArray{3} = ReadDisk(db,"SInput/xSales",year) #[Class,Fuel,Area,Year]  Historical Electricity Sales (GWh/YR)
  xSalSw::VariableArray{1} = ReadDisk(db,"SInput/xSalSw") #[Class]  Switch for Exogenous Sales (True=Exogenous)

  #
  # Scratch Variables
  #
  LoadsTemp::VariableArray{4} = zeros(Float32,length(ECC),length(Hour),length(Day),length(Month))
  LoadsOthManu::VariableArray{3} = zeros(Float32,length(Hour),length(Day),length(Month))
end

function ExoSalesNonElectric(data::Data)
  (; db,year) = data
  (; Areas,Classes,Fuel) = data
  (; Sales,xSales,xSalSw) = data

  # @info "  Supply.jl - ExoSalesNonElectric"

  for class in Classes
    if xSalSw[class] == 1
      for area in Areas, fuel in Select(Fuel, !=("Electric"))
        Sales[class,fuel,area] = xSales[class,fuel,area]
      end
    end
  end

  WriteDisk(db,"SOutput/Sales",year,Sales)

end # function ExoSalesNonElectric

function ExoElectricSalesAndLoadCurve(data::Data)
  (; db,year) = data
  (; Areas,Classes,Day,ECCs,Fuel,Hours_All,Months) = data
  (; BaseAdj,CLSF,ECCCLMap,LDCECC,SaEC,xSaEC,xSalSw) = data

  # @info "  Supply.jl - ExoElectricSalesAndLoadCurve"

  electric = Select(Fuel,"Electric")

  for class in Classes
    if xSalSw[class] == 1
      for area in Areas, ecc in ECCs
        if ECCCLMap[ecc,class] == 1
          SaEC[ecc,area] = xSaEC[ecc,area]
          for month in Months, hour in Hours_All
            average = Select(Day,"Average")
            LDCECC[ecc,hour,average,month,area] = SaEC[ecc,area]*CLSF[class,hour,average,month,area]/8760*1000
            for day in Select(Day,["Peak","Minimum"])
              LDCECC[ecc,hour,day,month,area] = SaEC[ecc,area]*CLSF[class,hour,day,month,area]*BaseAdj[day,month,area]/8760*1000
            end
          end
        end
      end
    end
  end

  WriteDisk(db,"SOutput/SaEC",year,SaEC)
  WriteDisk(db,"SOutput/LDCECC",year,LDCECC)

end # function ExoElectricSalesAndLoadCurve

function RestOfWorldLoadCurve(data::Data)
  (; db,year) = data
  (; Area,Days_All,ECC,ECCs,Hours_All,Months) = data
  (; LDCECC,SaEC,xSaEC,) = data
  (; LoadsTemp,LoadsOthManu) = data
  SalesTemp::VariableArray{1} = zeros(Float32,length(ECC))

  SalesOthManu::Float32 = 0

  # @info "  Supply.jl - RestOfWorldLoadCurve"

  #
  # Rest of world sales area exogenous.
  #
  row = Select(Area,"ROW")
  areas = Select(Area, !=("ROW"))

  for ecc in ECCs
    SaEC[ecc,row] = xSaEC[ecc,row]
  end

  #
  # The load shape of the Rest Of World Area is based on the load shape of the
  # simulated areas.
  #
  for month in Months, day in Days_All, hour in Hours_All, ecc in ECCs
    LoadsTemp[ecc,hour,day,month] = sum(LDCECC[ecc,hour,day,month,area] for area in areas)
    SalesTemp[ecc] = sum(SaEC[ecc,area] for area in areas)
    @finite_math LDCECC[ecc,hour,day,month,row] = LoadsTemp[ecc,hour,day,month]/SalesTemp[ecc]*SaEC[ecc,row]
  end

  #
  # Check if sales and loadcurve both have values.
  #
  # 23.09.01, LJD: I think this is one of the places where ECC Keys 
  #   (Other Manufacturing vs Other Industrial) are used as a trick to 
  #   split ECC and CER versions
  #
  for month in Months, day in Days_All, hour in Hours_All, ecc in Select(ECC,"OtherManufacturing")
    LoadsOthManu[hour,day,month] = sum(LDCECC[ecc,hour,day,month,area] for area in areas)
    SalesOthManu = sum(SaEC[ecc,area] for area in areas)
  end

  for month in Months, day in Days_All, hour in Hours_All, ecc in ECCs
    if (LDCECC[ecc,hour,day,month,row] == 0) && (SaEC[ecc,row] != 0)
      @finite_math LDCECC[ecc,hour,day,month,row] = LoadsOthManu[hour,day,month]/SalesOthManu*SaEC[ecc,row]
    end
  end

  WriteDisk(db,"SOutput/SaEC",year,SaEC)
  WriteDisk(db,"SOutput/LDCECC",year,LDCECC)

end # function RestOfWorldLoadCurve

function LoadCurve(data::Data)
  (; db,year) = data
  (; Areas,Classes,Day,Days_All,ECCs,Fuel,Hours_All,Months) = data
  (; ECCCLMap,HoursPerMonth,LDCECC,MinLd,MonOut,PDP,PkHr,PkLoad,PkMonth,SaEC,Sales,SLDC,TDEF) = data

  peakday = Select(Day,"Peak")
  averageday = Select(Day,"Average")
  minimumday = Select(Day,"Minimum")
  electric = Select(Fuel,"Electric")
  
  #
  # Electric System Load Curves
  #
  # @info "  Supply.jl - LoadCurve"
  
  #
  # Electric System Load Curve
  #
  for area in Areas, month in Months, day in Days_All, hour in Hours_All
    SLDC[hour,day,month,area] = sum(LDCECC[ecc,hour,day,month,area] for ecc in ECCs)/TDEF[electric,area]
  end

  #
  # Class Electric Sales
  #
  for area in Areas, class in Classes
    Sales[class,electric,area] = sum(SaEC[ecc,area]*ECCCLMap[ecc,class] for ecc in ECCs)
  end

  #
  # Monthly Peak Load
  #
  for area in Areas, month in Months
    PkLoad[month,area] = maximum(SLDC[:,peakday,month,area])
  end

  #
  # Annual Peak Load
  #
  for area in Areas
    PDP[area] = maximum(PkLoad[:,area])
  end

  #
  # Hour of Monthly Peak Load
  #
  for area in Areas, month in Months, hour in Hours_All
    if PkLoad[month,area] == SLDC[hour,peakday,month,area]
      PkHr[month,area] = hour
    end
  end

  #
  # Month of the Annual Peak Load
  # Note: If PkLoad is the same for both months, then this Julia code
  # selects the last month while Promula picks the first.  This is ok.
  # - Jeff Amlin 11/18/24
  #
  for area in Areas, month in Months
    if PDP[area] == PkLoad[month,area]
      PkMonth[area] = month
    end
  end

  #
  # Monthly Output
  #
  for area in Areas, month in Months
    MonOut[month,area] = sum(SLDC[hour,averageday,month,area]*HoursPerMonth[month] for hour in Hours_All)/1000
  end

  #
  # Monthly Minimum Load
  #
  for area in Areas, month in Months
     MinLd[month,area] = minimum(SLDC[:,minimumday,month,area])
  end

  WriteDisk(db,"SOutput/MinLd",year,MinLd)
  WriteDisk(db,"SOutput/MonOut",year,MonOut)
  WriteDisk(db,"SOutput/PDP",year,PDP)
  WriteDisk(db,"SOutput/PkHr",year,PkHr)
  WriteDisk(db,"SOutput/PkLoad",year,PkLoad)
  WriteDisk(db,"SOutput/PkMonth",year,PkMonth)
  WriteDisk(db,"SOutput/Sales",year,Sales)
  WriteDisk(db,"SOutput/SLDC",year,SLDC)

end # function LoadCurve

function DailyUse(data::Data)
  (; db,year) = data
  (; Areas,Classes,Day,Days_All,Fuel,Months) = data
  (; ADG,CDUC,CDUF,DaysPerMonth,DPKM,GTSales,MDG,PDG,Sales,SDUC,TDEF) = data

  naturalgas = Select(Fuel,"NaturalGas")
  peakday = Select(Day,"Peak")
  averageday = Select(Day,"Average")
  minimumday = Select(Day,"Minimum")

  #
  # Daily Use Curves
  #
  # @info "  Supply.jl - DailyUse"

  #
  # Gross Daily use curve to net daily use curve
  #
  @. DPKM = 1.0

  #
  # 23.09.01, LJD: I think this is one of the places where FuelKey 
  #   (UtilityGas vs NaturalGas) are used as a trick to split ECC and CER versions
  #
  for area in Areas, month in Months, class in Classes
    for day in Days_All
      @finite_math CDUC[class,day,month,area] = Sales[class,naturalgas,area]/365/CDUF[class,day,month,area]
    end
    @finite_math CDUC[class,peakday,month,area] = Sales[class,naturalgas,area]/365/CDUF[class,peakday,month,area]/DPKM[month,area]
  end

  #
  # Total Sales
  #
  for area in Areas
    GTSales[area] = sum(Sales[class,naturalgas,area] for class in Classes)
  end

  #
  # System Load Curve
  #
  for area in Areas, month in Months, day in Days_All
    @finite_math SDUC[day,month,area] = sum(CDUC[class,day,month,area] for class in Classes)/TDEF[naturalgas,area]
  end

  for area in Areas
    PDG[area] = maximum(SDUC[peakday,:,area])
    ADG[area] = sum(SDUC[averageday,month,area]*DaysPerMonth[month] for month in Months)/365
    MDG[area] = minimum(SDUC[minimumday,:,area])
  end

  WriteDisk(db,"SOutput/CDUC",year,CDUC)
  WriteDisk(db,"SOutput/Sales",year,Sales)
  WriteDisk(db,"SOutput/SDUC",year,SDUC)
  WriteDisk(db,"SOutput/PDG",year,PDG)
  WriteDisk(db,"SOutput/ADG",year,ADG)
  WriteDisk(db,"SOutput/MDG",year,MDG)
  WriteDisk(db,"SOutput/GTSales",year,GTSales)

end # function DailyUse

function SteamSupply(data::Data)
  (; db,year,CTime) = data
  (; Areas,ECC,ECCs,Fuels,FuelEPs,Polls) = data
  (; EuDemand,FFPMap,StCap,StCapPrior,StDemand,StDmd,StFFrac) = data
  (; StFPol,StGC,StGCCM,StGCPrior,StHPRatio,StHR) = data
  (; StHrAve,StHRPrior,StPOCX,StPur,StSold,TotDemand) = data

  steamgeneration = Select(ECC,"Steam")

  # @info "  Supply.jl - SteamSupply"

  #
  #  Net Steam Purchases from the Demand Sectors
  #
  for area in Areas
    StDemand[area] = max(sum(StPur[ecc,area]-StSold[ecc,area] for ecc in ECCs),0)

    #
    #  Steam Capacity is Steam Demands converted to MW
    #  StCap(in MW)=StDemand(in TBtu)/3412(Btu/KWH)/
    #            CapacityFactor(0.60)/8760(Hours/Yr)*1e6(Trillion/Million)
    #
    StCap[area] = StDemand[area]/3412/0.60/8760*1e6

    #
    # Electric Generating Capacity from Steam is the Steam Capacity
    # divided by the Heat-to-Power Ratio
    #
    StGC[area] = StCap[area]/StHPRatio[area]

    #
    # Incremental electric capacity from steam plants (StGCCM) is
    # computed for use in the Electric Sector.
    #
    if CTime > (HisTime+1)
      StGCCM[area] = max(StGC[area]-StGCPrior[area],0)
    else
      StGCCM[area] = 0
    end

    #
    # Average Heat Rate for Steam Production
    #
    if CTime > (HisTime+1)
      @finite_math StHrAve[area] = (StHRPrior[area]*StCapPrior[area]+
        max((StCap[area]-StCapPrior[area]),0)*StHR[area])/StCap[area]
    else
      StHrAve[area] = StHR[area]
    end
  end

  #
  # Demands for fuel in the steam sector (StDmd) are the steam
  # demands (StDemands) times the heat rate (StHR) times the fraction
  # for each type of fuel used to produce steam (StFFrac).
  #
  for area in Areas, fuelep in FuelEPs
    StDmd[fuelep,area] = StDemand[area]*StHrAve[area]*StFFrac[fuelep,area]
  end

  #
  # Pollution from the production of steam (StFPol) is the fuel
  # demands (StDmd) times the pollution coefficient (StPOCX).
  #
  for area in Areas, poll in Polls, fuelep in FuelEPs
    StFPol[fuelep,poll,area] = StDmd[fuelep,area]*StPOCX[fuelep,poll,area]
  end

  #
  # Map fuel demands from FuelEP into Fuel
  # Move steam generation demand into Total Demand.
  # This needs a xDmFrac type of variable to go from FuelEP to Fuel JSA 12/11/08
  #
  for fuel in Fuels, fuelep in FuelEPs, area in Areas
    if FFPMap[fuelep,fuel] == 1
      EuDemand[fuel,steamgeneration,area] = StDmd[fuelep,area]
      TotDemand[fuel,steamgeneration,area] = StDmd[fuelep,area]
    end
  end

  WriteDisk(db,"SOutput/EuDemand",year,EuDemand)
  WriteDisk(db,"SOutput/StCap",year,StCap)
  WriteDisk(db,"SOutput/StDemand",year,StDemand)
  WriteDisk(db,"SOutput/StDmd",year,StDmd)
  WriteDisk(db,"SOutput/StFPol",year,StFPol)
  WriteDisk(db,"SOutput/StGC",year,StGC)
  WriteDisk(db,"SOutput/StGCCM",year,StGCCM)
  WriteDisk(db,"SOutput/StHrAve",year,StHrAve)
  WriteDisk(db,"SOutput/TotDemand",year,TotDemand)

end # function SteamSupply

function Accounts(data::Data)
  (; db,year) = data
  (; Areas,ESes,Fuels) = data
  (; Inflation,FPF,FPPolTaxF,FPSMF,FPTaxF,FPTx,SecMap,TaxExp,TotDemand) = data

  # @info "  Supply.jl - Accounts"

  for es in ESes
    eccs = findall(SecMap .== es)
    for area in Areas, ecc in eccs, fuel in Fuels
        
      #
      # Unit Tax Rate
      #
      FPTx[fuel,ecc,area] = FPF[fuel,es,area]/(1+FPSMF[fuel,es,area])*
                            FPSMF[fuel,es,area]+
                            FPTaxF[fuel,es,area]*Inflation[area]+
                            FPPolTaxF[fuel,es,area]*Inflation[area]
      
      #
      # Tax Expenditures
      #
      TaxExp[fuel,ecc,area] = TotDemand[fuel,ecc,area]*FPTx[fuel,ecc,area]
      
    end
  end

  WriteDisk(db,"SOutput/FPTx",year,FPTx)
  WriteDisk(db,"SOutput/TaxExp",year,TaxExp)

end # function Accounts

function Price(data::Data)
  (; db,CTime,next) = data
  (; Area,Areas,ECCs,ES,ESes,Fuel,Fuels,Nation,Nations,Year) = data
  (; ANMap,ElecPrSwNext,ENPNNext,ENMSMNext,Exogenous,FPBaseFNext) = data
  (; FPDChgFNext,FPFNext,FPMarginFNext,FPSMFNext,FPTaxFNext,FPPolTaxFNext,FsFPNext) = data
  (; Inflation,InflationNext,InflationNation,InflationNationNext,InflationRateNext) = data
  (; InflationRateNationNext,PENext,StCCNext,StCCRNext,StHRNext,StOMCNext,StSubsidyNext) = data
  (; xENPNNext,xInflationNext,xInflationNationNext,xPENext) = data

  # @info "  Supply.jl - Price"

  #
  # Price Calculations for NEXT year
  #

  #
  # During the forecast period, estimate the Inflation Index
  # for the "Next" Year; otherwise use the exogenous value
  #
  if CTime > HisTime
    for area in Areas
      InflationNext[area] = Inflation[area]*(1+InflationRateNext[area])
    end
    for nation in Nations
      InflationNationNext[nation] = InflationNation[nation]*(1+InflationRateNationNext[nation])
    end
  else
    for area in Areas
      InflationNext[area] = xInflationNext[area]
    end
    for nation in Nations
      InflationNationNext[nation] = xInflationNationNext[nation]
    end
  end
  
  WriteDisk(db,"MOutput/Inflation",next,InflationNext)
  WriteDisk(db,"MOutput/InflationNation",next,InflationNationNext)  
  
  #
  # Primary (national) energy prices for fuels without explicit
  # supply sectors ($/mmBtu)
  #
  for nation in Nations, fuel in Select(Fuel,"Biomass")
    ENPNNext[fuel,nation] = xENPNNext[fuel,nation]
  end

  #
  # Delivered Fuel Prices
  #
  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas, es in ESes, fuel in Fuels
      FPBaseFNext[fuel,es,area] = (ENPNNext[fuel,nation]+
                                 FPDChgFNext[fuel,es,area])*InflationNext[area]
      
      FPFNext[fuel,es,area] = (ENPNNext[fuel,nation]*(1+FPMarginFNext[fuel,es,area])+
        FPDChgFNext[fuel,es,area]+FPTaxFNext[fuel,es,area]+
        FPPolTaxFNext[fuel,es,area])*InflationNext[area]*(1+FPSMFNext[fuel,es,area])
        
      FPFNext[fuel,es,area] = max(FPFNext[fuel,es,area],
                                ENPNNext[fuel,nation]*InflationNext[area]*0.25)
                                
      FsFPNext[fuel,es,area] = FPFNext[fuel,es,area]
    end
  end

  #
  # Do if electric prices are exogenous
  #
  for area in Areas, ecc in ECCs
   if ElecPrSwNext[area] == Exogenous
      PENext[ecc,area] = xPENext[ecc,area]*InflationNext[area]
   end
  end
  WriteDisk(db,"SOutput/PE",next,PENext)

  #
  # Price for Electric Utilities and Small Power Producers
  #
  @. ENMSMNext = 1.0

  #
  # Steam Prices
  #
  Industrial = Select(ES,"Industrial")
  NaturalGas = Select(Fuel,"NaturalGas")
  fuel = Select(Fuel,"Steam")
  for area in Areas, es in ESes 
    FPFNext[fuel,es,area] = (StCCNext[area]*StCCRNext[area]+StOMCNext[area]-
      StSubsidyNext[area])*InflationNext[area]+
      FPFNext[NaturalGas,Industrial,area]*StHRNext[area]
  end
  

  WriteDisk(db,"SOutput/ENMSM",next,ENMSMNext)
  WriteDisk(db,"SOutput/ENPN",next,ENPNNext)
  WriteDisk(db,"SOutput/FPBaseF",next,FPBaseFNext)
  WriteDisk(db,"SOutput/FPF",next,FPFNext)
  WriteDisk(db,"SOutput/FsFP",next,FsFPNext)

end # function Price

function Expenditures(data::Data)
  (; db,year) = data
  (; Areas,ECC,ECCs) = data
  (; CgInv,DInv,Expend,FlInv) = data
  (; FuelExpenditures,FuInv,FuOMExp,MEInv,MEOMExp) = data
  (; OMExp,PermitExpenditures,PInv,POMExp,PRExpenditures) = data
  (; SqInv,SqOMExp,TDInv,VnInv,VnOMExp) = data

  # @info "  Supply.jl - Expenditures"

  for area in Areas, ecc in ECCs
    Expend[ecc,area] = CgInv[ecc,area]+DInv[ecc,area]+FlInv[ecc,area]+FuelExpenditures[ecc,area]+FuInv[ecc,area]+FuOMExp[ecc,area]+
                     MEInv[ecc,area]+MEOMExp[ecc,area]+OMExp[ecc,area]+PInv[ecc,area]+POMExp[ecc,area]+SqInv[ecc,area]+SqOMExp[ecc,area]+VnInv[ecc,area]+VnOMExp[ecc,area]+
                     PRExpenditures[ecc,area]+PermitExpenditures[ecc,area]
  end

  for area in Areas, ecc in Select(ECC,"UtilityGen")
    Expend[ecc,area] = Expend[ecc,area]+TDInv[area]
  end

  WriteDisk(db,"SOutput/Expend",year,Expend)

end # function Expenditures

function Control(data::Data,ProcSw)
  (; AccountsKey,DailyUseKey,LoadcurveKey,PriceKey,SupplyKey) = data
  (; Endogenous,PreCalc,SegSw) = data 
   
  # @info "  Supply.jl - Control"   
  
  if SegSw[SupplyKey] != PreCalc  
    ExoSalesNonElectric(data)
    ExoElectricSalesAndLoadCurve(data)
    RestOfWorldLoadCurve(data)
   
    if ProcSw[LoadcurveKey] == Endogenous
      LoadCurve(data)
      SteamSupply(data)
    end
 
    if ProcSw[DailyUseKey] == Endogenous
      DailyUse(data)
    end
   
    if ProcSw[AccountsKey] == Endogenous
      Accounts(data)
    end
  
    if ProcSw[PriceKey] == Endogenous
      Price(data)
    end

  end

end

end # module Supply
