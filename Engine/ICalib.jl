#
# ICalib.jl - Industrial Calibration Segment
#
# Write (" ICalib.jl, Industrial Calibration Segment")
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2013 Systematic Solutions, Inc.  All rights reserved.
#

using EnergyModel
using LinearRegression

module ICalib

import ...EnergyModel: ReadDisk,WriteDisk,Select,Yr
import ...EnergyModel: ITime,STime,HisTime,MaxTime,Zero,First,Last,Future,Final,DT
import ...EnergyModel: Infinity
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
import ...LinearRegression: linregress,coef

const Input = "IInput"
const Outpt = "IOutput"
const CalDB = "ICalDB"
const SectorName::String = "Industrial"
const SectorKey::String = "Ind"
const ESKey::String = "Industrial"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}


Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]
  YrDCC = Int(CurTime)
  Yr2010 = Yr(2010)
  Yr1997 = Yr(1997)

  #SceName::String = ReadDisk(DB,"SInput/SceName") #  Scenario Name
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/TechKey")
  CTechs::Vector{Int} = collect(Select(CTech))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESes::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPKey::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelKey::SetArray = ReadDisk(db,"MainDB/FuelKey")  
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  HourDS::SetArray = ReadDisk(db,"MainDB/HourDS")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PIDS::SetArray = ReadDisk(db,"$Input/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Vintage::SetArray = ReadDisk(db,"$Input/VintageKey")
  VintageKey::SetArray = ReadDisk(db,"$Input/VintageKey")  
  Vintages::Vector{Int} = collect(Select(Vintage))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  # BMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/BMSM0") # [Enduse,Tech,EC,Area,Year] Budget market Share Mult. (Btu/Btu)
  # BMSMI::VariableArray{4} = ReadDisk(db,"$CalDB/BMSMI") # [Enduse,Tech,EC,Area] Budget market Share Mult. (Btu/Btu)
  # BMSF::VariableArray{5} = ReadDisk(db,"$Outpt/BMSF") # [Enduse,Tech,EC,Area,Year] Budget Market Share Fraction by Device ($/$)
  # BVF::VariableArray{4} = ReadDisk(db,"$CalDB/BVF") # [Enduse,Tech,EC,Area] Budget Variance Factor ($/$)
  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  CERSM::VariableArray{3} = ReadDisk(db,"$CalDB/CERSM",year) # [Enduse,EC,Area,Year] Lifestyle Multiplier (Btu/Btu)
  CERSMYr::VariableArray{4} = ReadDisk(db,"$CalDB/CERSM") # [Enduse,EC,Area,Year] Lifestyle Multiplier (Btu/Btu)
  CFraction::VariableArray{4} = ReadDisk(db,"$Input/CFraction",year) # [Enduse,Tech,EC,Area,Year] Fraction of Production Capacity open to Conversion ($/$)
  CHR::VariableArray{2} = ReadDisk(db,"$CalDB/CHR") # [EC,Area] Cooling to Heating Ratio (Btu/Btu)
  CHRM::VariableArray{2} = ReadDisk(db,"$Input/CHRM",year) # [EC,Area,Year] Cooling to Heating Ratio Multplier
  CMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/CMSM0",year) # [Enduse,Tech,CTech,EC,Area] Conversion Market Share Multiplier ($/$)
  CMSMI::VariableArray{5} = ReadDisk(db,"$CalDB/CMSMI") # [Enduse,Tech,CTech,EC,Area] Conversion Market Share Multiplier ($/$)
  CoverageCFS::VariableArray{3} = ReadDisk(db,"SInput/CoverageCFS",year) # [Fuel,ECC,Area,Year] Coverage fro CFS (1=Covered)
  CUF::VariableArray{4} = ReadDisk(db,"$CalDB/CUF",year) # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor ($/Yr/$/Yr)
  CVF::VariableArray{5} = ReadDisk(db,"$CalDB/CVF",year) # [Enduse,Tech,CTech,EC,Area] Conversion Market Share Variance Factor (DLESS)
  DCCBeforeStd::VariableArray{4} = ReadDisk(db,"$Outpt/DCCBeforeStd",year) # Device Capital Cost Beore Standard ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCN::VariableArray{4} = ReadDisk(db,"$Outpt/DCCN") # Normalized Device Capital Cost ($/mmBtu) [Enduse,Tech,EC,Area]
  DCMM::VariableArray{4} = ReadDisk(db,"$Input/DCMM",year) # Capital Cost Maximum Multiplier  ($/$) [Enduse,Tech,EC,Area]
  DCMMPrior::VariableArray{4} = ReadDisk(db,"$Input/DCMM",prior) # Capital Cost Maximum Multiplier  ($/$) [Enduse,Tech,EC,Area]
  DCTC::VariableArray{4} = ReadDisk(db,"$Outpt/DCTC",year) # Device Cap. Trade Off Coefficient (DLESS) [Enduse,Tech,EC,Area]
  DDay::VariableArray{2} = ReadDisk(db,"$Input/DDay",year) # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  DDCoefficient::VariableArray{3} = ReadDisk(db,"$Input/DDCoefficient",year) # [Enduse,EC,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  DEE::VariableArray{4} = ReadDisk(db,"$Outpt/DEE",year) # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu)
  DEEAPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DEEA",prior) # [Enduse,Tech,EC,Area,Year] Avg. Device Effic. (Btu/Btu)
  DEEA0::VariableArray{4} = ReadDisk(db,"$Input/DEEA0",year) # Device A0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEB0::VariableArray{4} = ReadDisk(db,"$Input/DEEB0",year) # Device B0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEBeforeStd::VariableArray{4} = ReadDisk(db,"$Outpt/DEEBeforeStd",year) # [Enduse,Tech,EC,Area,Year] Device Efficiency Before Standard(Btu/Btu)
  DEEC0::VariableArray{4} = ReadDisk(db,"$Input/DEEC0",year) # Device C0 Coeffcient for Efficiency Program (Btu/Btu) [Enduse,Tech,EC,Area]
  DEESw::VariableArray{4} = ReadDisk(db,"$Input/DEESw",year) # Switch for Device Efficiency (Switch) [Enduse,Tech,EC,Area]
  DEEThermalMax::VariableArray{4} = ReadDisk(db,"$Input/DEEThermalMax") # [Enduse,Tech,EC,Area] Thermal Maximum Device Efficiency (Btu/Btu)
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEMM::VariableArray{4} = ReadDisk(db,"$CalDB/DEMM",year) # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  DEMMPrior::VariableArray{4} = ReadDisk(db,"$CalDB/DEMM",prior) # [Enduse,Tech,EC,Area,Prior] Maximum Device Effic. Mult. in Previous Year (Btu/Btu)
  DEPM::VariableArray{4} = ReadDisk(db,"$Input/DEPM",year) # [Enduse,Tech,EC,Area,Year] Device Energy Price Multiplier ($/$)
  DER::VariableArray{4} = ReadDisk(db,"$Outpt/DER",year) # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  DERPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DER",prior) # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  DERA::VariableArray{4} = ReadDisk(db,"$Outpt/DERA",year) # [Enduse,Tech,EC,Area,Year] Energy Requirement Addition (mmBtu/Yr)
  DERRR::VariableArray{4} = ReadDisk(db,"$Outpt/DERRR",year) # [Enduse,Tech,EC,Area,Year] Device Energy Retire. Retrofit ((mmBtu/Yr)/Yr)
  DERVPrior::VariableArray{5} = ReadDisk(db,"$Outpt/DERV",prior) # Energy Requirement in Previous Year (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DEStd::VariableArray{4} = ReadDisk(db,"$Input/DEStd",year) # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu)
  DEStdP::VariableArray{4} = ReadDisk(db,"$Input/DEStdP",year) # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards Policy (Btu/Btu)
  DFPN::VariableArray{4} = ReadDisk(db,"$Outpt/DFPN") # [Enduse,Tech,EC,Area] Normalized Fuel Price ($/mmBtu)
  DFTC::VariableArray{4} = ReadDisk(db,"$Outpt/DFTC",year) # [Enduse,Tech,EC,Area,Year] Device Fuel Trade Off Coef. (DLESS)
  # Dmd::VariableArray{4} = ReadDisk(db,"$Outpt/Dmd",year) # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  DmdFEPTechPrior::VariableArray{4} = ReadDisk(db,"$Outpt/DmdFEPTech",prior) # Energy Demands (TBtu/Yr) [FuelEP,Tech,EC,Area]
  DmdFuelTechPrior::VariableArray{5} = ReadDisk(db,"$Outpt/DmdFuelTech",prior) # Energy Demands (TBtu/Yr) [Enduse,Fuel,Tech,EC,Area]
  DmdSw::VariableArray{3} = ReadDisk(db,"$Input/DmdSw",year) # [Tech,EC,Area,Year] DmdEnduse Switch
  DPL::VariableArray{4} = ReadDisk(db,"$Outpt/DPL",year) # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  DPLV::VariableArray{5} = ReadDisk(db,"$Input/DPLV",year) # Scrappage Rate of Equipment by Vintage (1/1) [Enduse,Tech,EC,Area,Vintage]
  DSMEU::VariableArray{4} = ReadDisk(db,"$Input/DSMEU",year) # [Enduse,Tech,EC,Area,Year] Exogenous Enduse DSM Adjustment (GWh/Yr)
  DSt::VariableArray{3} = ReadDisk(db,"$Outpt/DSt",year) # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  DStL::VariableArray{3} = ReadDisk(db,"$Outpt/DSt",prior) # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  DSt0::VariableArray{4} = ReadDisk(db,"$CalDB/DSt0") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  DStI::VariableArray{3} = ReadDisk(db,"$CalDB/DStI") # [Enduse,EC,Area] Device Saturation Income Utility ($/$)
  DStM::VariableArray{3} = ReadDisk(db,"$CalDB/DStM") # [Enduse,EC,Area] Maximum Device Saturation (Btu/Btu)
  DStP::VariableArray{3} = ReadDisk(db,"$CalDB/DStP") # [Enduse,EC,Area] Device Saturation Price Utility ($/$)
  DStPrior::VariableArray{3} = ReadDisk(db,"$Outpt/DSt",prior) # Device Saturation in Prior Year (Btu/Btu) [Enduse,EC,Area]
  ECESMap::VariableArray{2} = ReadDisk(db,"$Input/ECESMap") # [EC,ES] Map between EC and ES for Prices (Map)
  ECFP::VariableArray{4} = ReadDisk(db,"$Outpt/ECFP",year) # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  ECFPFuel::VariableArray{3} = ReadDisk(db,"$Outpt/ECFPFuel",year) # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  ECUF::VariableArray{2} = ReadDisk(db,"MOutput/ECUF",year) # [ECC,Area,Year] Capital Utilization Fraction ($/Yr/$/Yr)
  EuDemPrior::VariableArray{4} = ReadDisk(db,"$Outpt/EuDem",prior) # Enduse Demands (TBtu/Yr) [Enduse,FuelEP,EC,Area]
  EUPCPrior::VariableArray{5} = ReadDisk(db,"$Outpt/EUPC",prior) # [Enduse,Tech,Age,EC,Area,Year] Production Capacity by Enduse (M$/Yr)
  EUPCRC::VariableArray{5} = ReadDisk(db,"$Outpt/EUPCRC",year) # [Enduse,Tech,Age,EC,Area,Year] Production Capacity Retirements from Conversions ((M$/Yr)/Yr)
  ExpCP::VariableArray{3} = ReadDisk(db,"$Outpt/ExpCP",year) # [FuelEP,EC,Area,Year] Emission Expenditures ($M/Yr)
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0
  FEPCP::VariableArray{3} = ReadDisk(db,"$Outpt/FEPCP",year) # [FuelEP,EC,Area,Year] Carbon Price by FuelEP ($/mmBtu)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FPCFS::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFS",year) # [Fuel,EC,Area,Year] CFS Price ($/mmBtu)
  FPCFSFuel::VariableArray{3} = ReadDisk(db,"SOutput/FPCFSFuel",year) # [Fuel,ES,Area,Year] CFS Price ($/mmBtu)
  FPCFSLast::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFS",Last) # [Fuel,EC,Area,Last] CFS Price ($/mmBtu)
  FPCFSNet::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFSNet",year) # [Fuel,EC,Area,Year] CFS Price ($/mmBtu)
  FPCFSObligated::VariableArray{2} = ReadDisk(db,"SOutput/FPCFSObligated",year) # [ECC,Area,Year] CFS Price for Obligated Sectors ($/Tonnes)
  FPCFSTech::VariableArray{3} = ReadDisk(db,"$Outpt/FPCFSTech",year) # [Tech,EC,Area,Year] CFS Price ($/mmBtu)
  FPCP::VariableArray{3} = ReadDisk(db,"$Outpt/FPCP",year) # [Fuel,EC,Area,Year] Carbon Price before OBA ($/mmBtu)
  FPCPFrac::VariableArray{3} = ReadDisk(db,"$Input/FPCPFrac",year) # [Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)
  FPEC::VariableArray{3} = ReadDisk(db,"$Outpt/FPEC",year) # [Fuel,EC,Area,Year] Fuel Prices excluding Emission Costs ($/mmBtu)
  FPECC::VariableArray{3} = ReadDisk(db,"SOutput/FPECC",year) # [Fuel,ECC,Area,Year] Fuel Prices excluding Emission Costs ($/mmBtu)
  FPECCCFS::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFS",year) # [Fuel,ECC,Area,Year] Fuel Prices w/CFS Price ($/mmBtu)
  FPECCCFSCP::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSCP",year) # [Fuel,ECC,Area,Year] Fuel Prices w/CFS and Carbon Price ($/mmBtu)
  FPECCCFSCPNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSCPNet",year) # [Fuel,ECC,Area,Year] Fuel Prices w/CFS and Net Carbon Price ($/mmBtu)
  FPECCCFSNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSNet",year) # [Fuel,ECC,Area,Year] Incremental CFS Price ($/mmBtu)
  FPECCCP::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCP",year) # [Fuel,ECC,Area,Year] Carbon Price before OBA ($/mmBtu)
  FPECCCPNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCPNet",year) # [Fuel,ECC,Area,Year] Net Carbon Price after OBA ($/mmBtu)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) # [Fuel,ES,Area,Year] Fuel Price ($/mmBtu)
  FPTech::VariableArray{3} = ReadDisk(db,"$Outpt/FPTech",year) # [Tech,EC,Area,Year] Fuel Price excluding Emission Costs ($/mmBtu)
  FsPEE::VariableArray{3} = ReadDisk(db,"$CalDB/FsPEE",year) # [Tech,EC,Area,Year] Feedstock Process Efficiency ($/mmBtu)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) # [Area,Year] Inflation Index ($/$)
  Inflation0::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",First) # [Area,Year] Inflation Index ($/$)
  Inflation2010::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr2010) # Inflation Index for 2010 ($/$) [Area]
  Inflation1997::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr1997) # Inflation Index for 1997 ($/$) [Area]
  MCFU::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",year) # [Enduse,Tech,EC,Area,Year] Marginal Cost of Fuel Use ($/mmBtu)
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # [Enduse,Tech,EC,Area,Year] Marginal Cost of Fuel Use ($/mmBtu)
  MMSF::VariableArray{4} = ReadDisk(db,"$Outpt/MMSF",year) # [Enduse,Tech,EC,Area,Year] Market Share Fraction by Device ($/$)
  MMSM0::VariableArray{4} = ReadDisk(db,"$CalDB/MMSM0",year) # [Enduse,Tech,EC,Area,Year] Market Share Mult. Const. ($/$)
  MMSMI::VariableArray{4} = ReadDisk(db,"$CalDB/MMSMI") # [Enduse,Tech,EC,Area] Market Share Mult. from Income ($/$)
  MVF::VariableArray{4} = ReadDisk(db,"$CalDB/MVF",year) # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  OBAFraction::VariableArray{2} = ReadDisk(db,"SInput/OBAFraction",year) # [ECC,Area,Year] Output-Based Allocation Fraction (Tonne/Tonne)
  PC::VariableArray{2} = ReadDisk(db,"MOutput/PC",year) # [ECC,Area,Year] Production Capacity (M$/Yr)
  PC0::VariableArray{2} = ReadDisk(db,"MOutput/PC",First) # [ECC,Area,First] Production Capacity (M$/Yr)
  PCA::VariableArray{3} = ReadDisk(db,"MOutput/PCA",year) # [Age,ECC,Area,Year] Production Capacity Additions (M$/Yr/Yr)
  PCost::VariableArray{4} = ReadDisk(db,"$Outpt/PCost",year) # [FuelEP,EC,Poll,Area,Year] Permit Cost ($/Tonne)
  PCostExo::VariableArray{4} = ReadDisk(db,"$Input/PCostExo",year) # [FuelEP,EC,Poll,Area,Year] Marginal Exogenous Permit Cost (Real $/Tonnes)
  PCostTech::VariableArray{3} = ReadDisk(db,"$Outpt/PCostTech",year) # [Tech,EC,Area,Year] Permit Cost ($/mmBtu)
  PCPL::VariableArray{2} = ReadDisk(db,"MInput/PCPL",year) # [ECC,Area,Year] Physical Life of Production Capacity (Years)
  PE::VariableArray{2} = ReadDisk(db,"SOutput/PE",year) # [ECC,Area,Year] Price of Electricity (Mills per kWh)
  PEE::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",year) # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEEAPrior::VariableArray{4} = ReadDisk(db,"$Outpt/PEEA",prior) # [Enduse,Tech,EC,Area,Year] Average Process Efficiency ($/Btu)
  PEEBeforeStd::VariableArray{4} = ReadDisk(db,"$Outpt/PEEBeforeStd",year) # [Enduse,Tech,EC,Area,Year] Process Efficiency Before Standard ($/Btu)
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)
  PEMM::VariableArray{4} = ReadDisk(db,"$CalDB/PEMM",year) # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu))
  PEMMSw::VariableArray{2} = ReadDisk(db,"$Input/PEMMSw") # [EC,Area] Process Efficiency Update Switch (1=Yes, 0 = No)
  PEMMYr::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu))
  PEPL::VariableArray{4} = ReadDisk(db,"$Outpt/PEPL",year) # [Enduse,Tech,EC,Area,Year] Physical Life of Process Requirements (Years)
  PERPrior::VariableArray{4} = ReadDisk(db,"$Outpt/PER",prior) # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  PERRR::VariableArray{4} = ReadDisk(db,"$Outpt/PERRR",year) # [Enduse,Tech,EC,Area,Year] Process Energy Retire. Process Retrofit ((mmBtu/Yr)/Yr)
  PEStd::VariableArray{4} = ReadDisk(db,"$Input/PEStd",year) # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard ($/Btu)
  PEStdP::VariableArray{4} = ReadDisk(db,"$Input/PEStdP",year) # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard Policy ($/Btu)
  POCX::VariableArray{5} = ReadDisk(db,"$Input/POCX",year) # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  PolMarginal::VariableArray{4} = ReadDisk(db,"$Outpt/PolMarginal",year) # [FuelEP,EC,Poll,Area,Year] Marginal Emissions (Tonnes/Yr)
  Pop::VariableArray{2} = ReadDisk(db,"MOutput/Pop",year) # [ECC,Area,Year] Population (Millions)
  Pop0::VariableArray{2} = ReadDisk(db,"MOutput/Pop",First) # [ECC,Area,First] Population (Millions)
  RM::VariableArray{4} = ReadDisk(db,"$Outpt/RM",year) # [FuelEP,EC,Poll,Area,Year] Reduction Multiplier (Tonnes/Tonnes)
  StockAdjustment::VariableArray{4} = ReadDisk(db,"$Input/StockAdjustment",year) # [Enduse,Tech,EC,Area,Year] Exogenous Capital Stock Adjustment ($/$)
  TSLoad::VariableArray{3} = ReadDisk(db,"$Input/TSLoad") # [Enduse,EC,Area] Temperature Sensitive Fraction of Load (Btu/Btu)
  UMS::VariableArray{4} = ReadDisk(db,"$Outpt/UMS",year) # [Enduse,Tech,EC,Area,Year] Util. Mult. for Short Term Price Response (Btu/Btu)
  xDCC::VariableArray{4} = ReadDisk(db,"$Input/xDCC",year) # Device Capital Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  xDCMM::VariableArray{4} = ReadDisk(db,"$Input/xDCMM",year) # Maximum Device Capital Cost Mult (Btu/Btu) [Enduse,Tech,EC,Area]
  xDCMMPrior::VariableArray{4} = ReadDisk(db,"$Input/xDCMM",prior) # Maximum Device Capital Cost Mult (Btu/Btu) [Enduse,Tech,EC,Area]
  xDEE::VariableArray{4} = ReadDisk(db,"$Input/xDEE",year) # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xDEMM::VariableArray{4} = ReadDisk(db,"$Input/xDEMM",year) # [Enduse,Tech,EC,Area,Year] Maximum Device Effic. Mult. (Btu/Btu)
  xDEMMPrior::VariableArray{4} = ReadDisk(db,"$Input/xDEMM",prior) # [Enduse,Tech,EC,Area,Prior] Maximum Device Effic. Mult. in Previous Year (Btu/Btu)
  xDmd::VariableArray{4} = ReadDisk(db,"$Input/xDmd",year) # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xDmdPrior::VariableArray{4} = ReadDisk(db,"$Input/xDmd",prior) # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xDmdLast::VariableArray{4} = ReadDisk(db,"$Input/xDmd",Last) # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xDmdTrend::VariableArray{4} = ReadDisk(db,"$Input/xDmdTrend",year) # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xDmFracPrior::VariableArray{5} = ReadDisk(db,"$Input/xDmFrac",prior) # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  xFsDmd::VariableArray{3} = ReadDisk(db,"$Input/xFsDmd",year) # [Tech,EC,Area,Year] Historical Feedstock Energy (TBtu/Yr)
  xMMSF::VariableArray{4} = ReadDisk(db,"$CalDB/xMMSF",year) # [Enduse,Tech,EC,Area,Year] Historical Market Share ($/$)
  xMVF::VariableArray{4} = ReadDisk(db,"$Input/xMVF",year) # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  xPEEBeforeStd::VariableArray{4} = ReadDisk(db,"$Input/xPEE",year) # [Enduse,Tech,EC,Area,Year] Historical Process Efficiency Before Standard ($/Btu)
  xPEMM::VariableArray{4} = ReadDisk(db,"$Input/xPEMM",year) # Process Efficiency Max. Mult. ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  xProcSw::VariableArray{1} = ReadDisk(db,"$Input/xProcSw",year) #[PI,Year] "Procedure on/off Switch"
  xXProcSw::VariableArray{1} = ReadDisk(db,"$Input/xXProcSw",year) # [PI,Year] Procedure on/off Switch
  ZeroFr::VariableArray{3} = ReadDisk(db,"SInput/ZeroFr",year) # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)

  #
  # Scratch Variables
  #
  AgingFactor::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Vintage)) # Aging Factor (1/DPL)) [Enduse,Tech,EC,Area,Vintage]
  ALPHA::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Estimation Constant
  BETA::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Estimation Constant
  DEEMax::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Maximum Process Efficiency (Btu/Btu)
  DER1::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Energy Requirement (mmBtu/Yr)
  DERA1::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Energy Requirement Addition (mmBtu/Yr)
  DERAD::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Potential Device Additions from Device Conversions (mmBtu/yr)
  DERAP::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Device Additions from Process Retire. (mmBtu/Yr/Yr)
  DERAPC1::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Device Additions from Production Capacity Additions and Increases in Device Saturation (mmBtu/Yr/Yr)
  DERAdj::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Device Energy Rqmt. Adjustment (mmBtu/Yr/Yr)
  DERAV::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Vintage)) # Energy Requirement Addition (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERR1::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Device Energy Rqmt. Retire. (mmBtu/Yr/Yr)
  DERRD::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Device Retire. from Device Retire. (mmBtu/Yr/Yr)
  DERRP::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Device Retire. from Process Retire. (mmBtu/Yr/Yr)
  DERRDV::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Vintage))  # Device Retire from Device Retire. by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERRPC::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Device Retire. from Production Capacity Retirements and Reductions in Device Saturation (mmBtu/Yr/Yr)
  DERRV::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Vintage))  # Device Retire from Device Retire. by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERV::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Vintage))  # Energy Requirement by Vintage (mmBtu/YR) [Tech,EC,Area,Vintage]
  DERAgedV::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Vintage)); # Energy Requirement Aged to Next Vintage (mmBtu/YR) [Tech,EC,Area,Vintage]
  DERVAllocation::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Vintage))  # Energy Requirement by Vintage (mmBtu/YR) [Tech,EC,Area,Vintage]
  DERVSum::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area))  # Energy Requirement by Vintage (mmBtu/YR) [Tech,EC,Area]
  DeltaA::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Cogeneration Transformation using Average Heat Rate
  DeltaM::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Cogeneration Transformation using MarginalHeat Rate
  EUPCRPC::VariableArray{4} = zeros(Float32,length(Tech),length(Age),length(EC),length(Area)) # [Tech,Age,EC,Area] Production Capacity Retirements from Capacity Retirements (M$/Yr/Yr)
  GAMMA::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Estimation Constant
  HLoc::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Index Holding Variable
  LastVintage::Int = 0 # Last Vintage (Vintage Pointer)
  LI::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Loss Intensity Index (Btu/Btu)
  MAW::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Marginal Alloc. Weight ($/$)
  MMSFAll::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Marginal Market Share for AC of All Technologies (Btu/Btu)
  MMSFGeoHP::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Marginal Market Share for AC Geothermal and Heat Pumps (Btu/Btu)
  MMSFOther::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Marginal Market Share for AC of Other Technologies (Btu/Btu)
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Normalized Market Share
  # NCOL     'Number of Columns in Regression Matrix'
  # NROW     'Number of Active Fuels to Estimate'
  # PEEMax   'Maximum Process Efficiency ($/Btu)'
  PEECalPEMM::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] PEE Scratch Variable
  PEEHeat::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Process Efficiency from Heat ($/Btu)
  PEEWeight::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Intermediate For Process Efficiency from Heat ($/Btu)
  Weights::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Intermediate For Efficiency from Heat ($/Btu)
  PEEMax::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Maximum Process Efficiency ($/Btu)
  PenultimateVintage::Int = 0 # Penultimate (Next to Last) Vintage (Vintage Pointer)
  PERADSt::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Process Additions from Increases in Saturation (mmBtu/Yr/Yr)
  PERAP::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Process Additions from Process Retire. (mmBtu/Yr/Yr)
  PERRDSt::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Process Retire. from Reductions in Saturation (mmBtu/Yr/Yr)
  PERRP::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Process Retire. from Process Retire. (mmBtu/Yr/Yr)
  PERRPC::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Process Retire. from Production Capacity Retire. (mmBtu/Yr/Yr)
  SPC::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Total Production Capacity (M$/Yr)
  SPC0::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Total Production Capacity (M$/Yr)
  SPCA::VariableArray{3} = zeros(Float32,length(Age),length(EC),length(Area)) # [Age,EC,Area] Production Capacity Additions (M$/Yr)
  SPCPL::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Physical Life of Production Capacity (Years)
  SPop::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Population (Millions)
  SPop0::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Population (Millions)
  WCUF::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Capacity Utilization Factor Weighted by Output
  xDmd_temp::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)

end

function TPrice(data)
  (;db,year,prior,CTime) = data
  (;Ages,Area,Areas,EC) = data
  (;ECC,ECCs,ECs,ES,ESDS,ESes) = data
  (;Enduses,Fuel,FuelEPs,Fuels,Hours) = data
  (;Poll) = data
  (;Polls,Techs) = data
  (;CoverageCFS) = data
  (;DmdFEPTechPrior,DmdFuelTechPrior) = data
  (;ECESMap,ECFP,ECFPFuel,ECUF,EuDemPrior,ExpCP) = data
  (;FEPCP,FFPMap,FPCFSFuel,FPCFSLast,FPCFS,FPCFSNet,FPCFSObligated,FPCFSTech) = data
  (;FPCP,FPCPFrac,FPEC,FPECC,FPECCCFS,FPECCCFSCP,FPECCCFSCPNet) = data
  (;FPECCCFSNet,FPECCCP,FPECCCPNet,FPF,FPTech,FuelKey,FuelEPKey,Inflation) = data
  (;OBAFraction,PC,PC0,PCA,PCost,PCostExo,PCostTech,PCPL,PE) = data
  (;POCX,PolConv,PolMarginal) = data
  (;Pop,Pop0,RM) = data
  (;xDmdPrior,xDmdLast,xDmFracPrior) = data
  (;ZeroFr) = data
  (;SPC,SPC0,SPCA,SPCPL) = data
  (;SPop,SPop0,WCUF) = data

  #
  # Fuel to Tech Mapping
  #
  # @info "$SectorName Calib.jl - TPrice - Technology Prices " Yrv[year]
  #
  if prior > Last
    @. xDmdPrior = xDmdLast
  end

  for area in Areas, ec in ECs, fuelep in FuelEPs, enduse in Enduses
    EuDemPrior[enduse,fuelep,ec,area] = sum(xDmdPrior[enduse,tech,ec,area]*
      xDmFracPrior[enduse,fuel,tech,ec,area]*
      FFPMap[fuelep,fuel] for tech in Techs, fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/EuDem",prior,EuDemPrior)

  for area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    if xDmFracPrior[enduse,fuel,tech,ec,area] > 0
      DmdFuelTechPrior[enduse,fuel,tech,ec,area] = 
        max(xDmdPrior[enduse,tech,ec,area],0.00001)*
        xDmFracPrior[enduse,fuel,tech,ec,area]
    else
      DmdFuelTechPrior[enduse,fuel,tech,ec,area] = 0
    end
  end
  WriteDisk(db,"$Outpt/DmdFuelTech",prior,DmdFuelTechPrior)

  for area in Areas, ec in ECs, tech in Techs, fuelep in FuelEPs
    DmdFEPTechPrior[fuelep,tech,ec,area] = sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels, enduse in Enduses)
  end
  WriteDisk(db,"$Outpt/DmdFEPTech",prior,DmdFEPTechPrior)

  #
  # PolMarginal
  #
  for area in Areas, poll in Polls, ec in ECs, fuelep in FuelEPs
    PolMarginal[fuelep,ec,poll,area] = 
      sum(POCX[enduse,fuelep,ec,poll,area]*(1-ZeroFr[fuelep,poll,area])*
      RM[fuelep,ec,poll,area]*
      max(EuDemPrior[enduse,fuelep,ec,area],1e-12) for enduse in Enduses)
  end
  WriteDisk(db,"$Outpt/PolMarginal",year,PolMarginal)

  for fuelep in FuelEPs, ec in ECs, area in Areas
    @finite_math ExpCP[fuelep,ec,area] = sum((PolMarginal[fuelep,ec,poll,area]*
      (PCost[fuelep,ec,poll,area]+PCostExo[fuelep,ec,poll,area])*Inflation[area])/1e6
      for poll in Polls)
  end
  WriteDisk(db,"$Outpt/ExpCP",year,ExpCP)  
      
  for fuelep in FuelEPs, ec in ECs, area in Areas  
    @finite_math FEPCP[fuelep,ec,area] = ExpCP[fuelep,ec,area]/
      (sum(DmdFEPTechPrior[fuelep,tech,ec,area] for tech in Techs))
  end
  WriteDisk(db,"$Outpt/FEPCP",year,FEPCP)

  for tech in Techs,ec in ECs,area in Areas
    @finite_math PCostTech[tech,ec,area] =
      sum(FEPCP[fuelep,ec,area]*DmdFEPTechPrior[fuelep,tech,ec,area] for fuelep in FuelEPs)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/PCostTech",year,PCostTech)
  
  for fuel in Fuels,area in Areas,ec in ECs
    if FPCPFrac[fuel,ec,area] == 0
      for fuelep in FuelEPs 
        if FuelKey[fuel] == FuelEPKey[fuelep]
          FPCP[fuel,ec,area] = FEPCP[fuelep,ec,area]
        end
      end
    else
      @finite_math FPCP[fuel,ec,area] = sum(PCostTech[tech,ec,area]*
            DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,tech in Techs)/
        sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,tech in Techs)      
    end
  end
  WriteDisk(db,"$Outpt/FPCP",year,FPCP)

  #
  # FPCFS - CFR Prices
  #
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  es = Select(ES,ESKey)
  for area in Areas, ec in ECs, fuel in Fuels 
    ecc = Select(ECC,EC[ec])
    FPCFS[fuel,ec,area] = FPCFSFuel[fuel,es,area]*CoverageCFS[fuel,ecc,area]
    for fuelep in FuelEPs
      if FuelKey[fuel] == FuelEPKey[fuelep]   
        FPCFS[fuel,ec,area] = FPCFS[fuel,ec,area]+FPCFSObligated[ecc,area]*    
          sum(POCX[1,fuelep,ec,poll,area]*(1-ZeroFr[fuelep,poll,area])*PolConv[poll]
              for poll in polls)/1e6
      end
    end
  end  
  WriteDisk(db,"$Outpt/FPCFS",year,FPCFS)

  #
  # FPCFSNet - Net CFR Prices
  #
  @. FPCFSNet = FPCFS
  areas = Select(Area,"BC")
  for area in areas, ec in ECs, fuel in Fuels
    if CTime < HisTime
      FPCFSNet[fuel,ec,area] = 0.00
    else
      FPCFSNet[fuel,ec,area] = FPCFS[fuel,ec,area]-FPCFSLast[fuel,ec,area]
    end
  end

  WriteDisk(db,"$Outpt/FPCFSNet",year,FPCFSNet)
  
  #
  # FPCFSTech - CFR Prices by Tech
  #
  for tech in Techs,ec in ECs,area in Areas
    @finite_math FPCFSTech[tech,ec,area] = sum(FPCFSNet[fuel,ec,area]*
          DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,fuel in Fuels)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/FPCFSTech",year,FPCFSTech)

  #
  # Fuel Prices by Sector (EC)
  #
  for fuel in Fuels,ec in ECs,area in Areas
    FPEC[fuel,ec,area] = sum(FPF[fuel,es,area]*ECESMap[ec,es] for es in ESes)
  end

  ElectricFuels = Select(Fuel,["Electric","Geothermal","Solar"])
  for fuel in ElectricFuels,area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    FPEC[fuel,ec,area] = PE[ecc,area]/3412*1000
  end
  WriteDisk(db,"$Outpt/FPEC",year,FPEC)

  #
  # Fuel Prices by Tech
  #
  for ec in ECs,tech in Techs,area in Areas
    @finite_math FPTech[tech,ec,area] = 
      sum(FPEC[fuel,ec,area]*DmdFuelTechPrior[1,fuel,tech,ec,area] for fuel in Fuels)/
      sum(                   DmdFuelTechPrior[1,fuel,tech,ec,area] for fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/FPTech",year,FPTech)

  @. ECFPFuel = FPEC+FPCFSNet+FPCP
  WriteDisk(db,"$Outpt/ECFPFuel",year,ECFPFuel)

  for ec in ECs,tech in Techs,area in Areas,enduse in Enduses
    @finite_math ECFP[enduse,tech,ec,area] = 
      sum((FPEC[fuel,ec,area]+FPCFSNet[fuel,ec,area])*
          DmdFuelTechPrior[enduse,fuel,tech,ec,area] for fuel in Fuels)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for fuel in Fuels)+
      PCostTech[tech,ec,area]
  end
  WriteDisk(db,"$Outpt/ECFP",year,ECFP)

  #
  # Price Variables by ECC
  #
  for fuel in Fuels,area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    FPECCCP[fuel,ecc,area] = FPCP[fuel,ec,area]
    FPECCCPNet[fuel,ecc,area] = FPECCCP[fuel,ecc,area]*(1-OBAFraction[ecc,area])
    FPECC[fuel,ecc,area] = FPEC[fuel,ec,area]
  end
  WriteDisk(db,"SOutput/FPECCCP",year,FPECCCP)
  WriteDisk(db,"SOutput/FPECCCPNet",year,FPECCCPNet)
  WriteDisk(db,"SOutput/FPECC",year,FPECC)

  for fuel in Fuels,area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    FPECCCFS[fuel,ecc,area] = FPECC[fuel,ecc,area]+FPCFSNet[fuel,ec,area]
    FPECCCFSNet[fuel,ecc,area] = FPECCCFS[fuel,ecc,area]-FPECC[fuel,ecc,area]
    FPECCCFSCP[fuel,ecc,area] = FPECC[fuel,ecc,area]+FPECCCFSNet[fuel,ecc,area]+FPECCCP[fuel,ecc,area]
    FPECCCFSCPNet[fuel,ecc,area] = FPECC[fuel,ecc,area]+FPECCCFSNet[fuel,ecc,area]+FPECCCPNet[fuel,ecc,area]
  end
  
  WriteDisk(db,"SOutput/FPECCCFS",year,FPECCCFS)
  WriteDisk(db,"SOutput/FPECCCFSNet",year,FPECCCFSNet)
  WriteDisk(db,"SOutput/FPECCCFSCP",year,FPECCCFSCP)
  WriteDisk(db,"SOutput/FPECCCFSCPNet",year,FPECCCFSCPNet)

  #
  # Map production capacity (PC),population (Pop),and capacity utilization
  # factor (ECUF) from the large economic category set (ECC) into production
  # capacity (SPC),population (SPop),and capacity utilization factor (WCUF)
  # with the single sector economic category set (EC).
  #
  for ec in ECs,area in Areas
    ecc = Select(ECC,EC[ec])
    SPC[ec,area] = PC[ecc,area]
    SPC0[ec,area] = PC0[ecc,area]
    SPop[ec,area] = Pop[ecc,area]
    SPop0[ec,area] = Pop0[ecc,area]
    WCUF[ec,area] = ECUF[ecc,area]
  end

  #
  # Map production capacity additions (PCA) from the large economic category
  # set (ECC) into production capacity additions (SPCA) with the single sector
  # economic category set (EC).
  #
  for area in Areas,ec in ECs, age in Ages
    ecc = Select(ECC,EC[ec])
    SPCA[age,ec,area] = (PCA[age,ecc,area])
  end

  #
  # Map production capacity lifetime (PCPL) from the large economic category
  # set (ECC) into production capacity lifetime (SPCPL) with the single sector
  # economic category set (EC).
  #
  for area in Areas, ec in ECs
    ecc = Select(ECC,EC[ec])
    SPCPL[ec,area] = PCPL[ecc,area]
  end
end

function Initial(data)
  (;db,year) = data
  (;Areas) = data
  (;ECs) = data
  (;Enduses,Hours) = data
  (;PI) = data
  (;Techs,Years) = data
  (;CERSM) = data
  (;CUF) = data
  (;DSt0) = data
  (;DStI,DStM,DStP,Endogenous) = data
  (;FsPEE,Hours,MMSM0,MMSMI,MVF) = data
  (;PEMM) = data
  (;xDSt,xFsDmd,xMVF) = data
  (;xPEMM,xXProcSw) = data
  (;SPC) = data
  (;WCUF,xProcSw) = data

  #
  # Initialize Market Share and Lifestyle Multipliers
  #
  @info "$SectorName Calib.jl - Initial - Calibration Initialization"
  
  #
  # Estimate Basic Demand Parameters
  #
  # PEMMAdj = FALSE
  @. xProcSw = xXProcSw
  WriteDisk(db,"$Input/xProcSw",year,xProcSw)

  CMarginal = Select(PI,"CMarginal")
  if xProcSw[CMarginal] == Endogenous
    @info "$SectorName Calib.jl - Initializing Process Calibration Variables"
    if year != 1
      @. PEMM = xPEMM
      WriteDisk(db,"$CalDB/PEMM",year,PEMM)
    end
    #
    # 1985 is 0 in Promula, add patch to match - Ian
    #
  end

  MShare = Select(PI,"MShare")
  if xProcSw[MShare] == Endogenous
    @info "$SectorName Calib.jl - Initializing Market Share Calibration Variables"
    @. MMSM0 = 0
    @. MVF = xMVF
    @. MMSMI = 0
    WriteDisk(db,"$CalDB/MMSM0",year,MMSM0)
    WriteDisk(db,"$CalDB/MMSMI",MMSMI)
    WriteDisk(db,"$CalDB/MVF",year,MVF)
  end


  DmdEnduse = Select(PI,"DmdEnduse")
  if xProcSw[DmdEnduse] == Endogenous
    @info "$SectorName Calib.jl - Initializing Utilization Calibration Variables"
    if year != 1
      @. CERSM = 1.0
      @. CUF = 1.0
      WriteDisk(db,"$CalDB/CERSM",year,CERSM)
      WriteDisk(db,"$CalDB/CUF",year,CUF)
    end

    for area in Areas, ec in ECs, enduse in Enduses
      DStM[enduse,ec,area] = 1.2*maximum(xDSt[enduse,ec,area,y] for y in Years)
      @finite_math DSt0[enduse,ec,area,year] =
                   log(DStM[enduse,ec,area]/xDSt[enduse,ec,area,year]-1)
    end
    @. DStI = 0
    @. DStP = 0

    WriteDisk(db,"$CalDB/DSt0",DSt0)
    WriteDisk(db,"$CalDB/DStI",DStI)
    WriteDisk(db,"$CalDB/DStM",DStM)
    WriteDisk(db,"$CalDB/DStP",DStP)
  end

  TPrice(data)

  for area in Areas, ec in ECs, tech in Techs
    @finite_math FsPEE[tech,ec,area] = SPC[ec,area]*WCUF[ec,area]/xFsDmd[tech,ec,area]
  end
  WriteDisk(db,"$CalDB/FsPEE",year,FsPEE)
end

function CalDEMM(data)
  (;db,year,CTime) = data
  (;Areas) = data
  (;ECs) = data
  (;Enduses,Hours) = data
  (;PI) = data
  (;Techs) = data
  (;DCCBeforeStd,DCCN,DCMM,DCMMPrior,DCTC) = data
  (;DEE,DEEBeforeStd,DEEThermalMax) = data
  (;DEEB0,DEEC0,DEESw,DEM,DEMM,DEMMPrior,DEPM,DEStd,DEStdP,DFPN) = data
  (;DFTC) = data
  (;ECFP,Endogenous) = data
  (;Hours,Inflation,Inflation2010) = data
  (;xDCC,xDCMM,xDEE,xDEMM) = data
  (;xDCMMPrior,xDEMMPrior) = data
  (;DEEMax) = data
  (;xProcSw) = data

  #
  # Calibrate Device Technology
  #
  DMarginal = Select(PI,"DMarginal")
  if xProcSw[DMarginal] == Endogenous
    @info "$SectorName Calib.jl - Device Efficiency Calibration for $CTime"
    
    TPrice(data)

    @finite_math @. DEMM = xDEMM*DEMMPrior/xDEMMPrior
    @finite_math @. DCMM = xDCMM*DCMMPrior/xDCMMPrior

    for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
      @finite_math DEEBeforeStd[enduse,tech,ec,area] = DEM[enduse,tech,ec,area]*
        DEMM[enduse,tech,ec,area]*(1/(1+(ECFP[enduse,tech,ec,area]/Inflation[area]*
        DEPM[enduse,tech,ec,area]/DFPN[enduse,tech,ec,area])^DFTC[enduse,tech,ec,area]))
      #
      # Patch instances where DFPN = 0 to match Promula outputs
      # Ian - 12/02/24
      #
      if DFPN[enduse,tech,ec,area] == 0
        if DEM[enduse,tech,ec,area] > 0 && DEMM[enduse,tech,ec,area] > 0
          DEEBeforeStd[enduse,tech,ec,area] = DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]
        end
      end
      @finite_math DCCBeforeStd[enduse,tech,ec,area] = DCCN[enduse,tech,ec,area]*
        DCMM[enduse,tech,ec,area]*(DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]/
        DEEBeforeStd[enduse,tech,ec,area]-1)^((1/min(DCTC[enduse,tech,ec,area],-0.01)))*Inflation[area]
    end

    for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
      if xDEE[enduse,tech,ec,area] != -99
        DEE[enduse,tech,ec,area] = max(xDEE[enduse,tech,ec,area],
          DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area])
      else
        DEE[enduse,tech,ec,area] = max(DEEBeforeStd[enduse,tech,ec,area],
          DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area])
      end
    
      if DEESw[enduse,tech,ec,area] == 10
        @finite_math DEEBeforeStd[enduse,tech,ec,area] = DEMM[enduse,tech,ec,area]*
          (DEEC0[enduse,tech,ec,area]+DEEB0[enduse,tech,ec,area]*
          log(ECFP[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055)) 
          
        DEE[enduse,tech,ec,area] = max(DEEBeforeStd[enduse,tech,ec,area],
          DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area])

      elseif DEESw[enduse,tech,ec,area] == 11
        @finite_math DEEBeforeStd[enduse,tech,ec,area] = DEMM[enduse,tech,ec,area]*
          (DEEC0[enduse,tech,ec,area]+DEEB0[enduse,tech,ec,area]/
          sqrt(ECFP[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055)) 
          
        DEE[enduse,tech,ec,area] = max(DEEBeforeStd[enduse,tech,ec,area],
          DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area])
        
      elseif DEESw[enduse,tech,ec,area] == 12
        @finite_math DEEBeforeStd[enduse,tech,ec,area] = DEMM[enduse,tech,ec,area]*
          (DEEC0[enduse,tech,ec,area]+DEEB0[enduse,tech,ec,area]/
          (ECFP[enduse,tech,ec,area]/Inflation[area]*Inflation2010[area]/1.055)) 
          
        DEE[enduse,tech,ec,area] = max(DEEBeforeStd[enduse,tech,ec,area],
          DEStd[enduse,tech,ec,area],DEStdP[enduse,tech,ec,area])
      end
          
      DEEBeforeStd[enduse,tech,ec,area] = min(DEEBeforeStd[enduse,tech,ec,area],
        DEEThermalMax[enduse,tech,ec,area])
      DEE[enduse,tech,ec,area] = min(DEE[enduse,tech,ec,area],
        DEEThermalMax[enduse,tech,ec,area])
      @finite_math DEMM[enduse,tech,ec,area] = DEMM[enduse,tech,ec,area]*
        DEE[enduse,tech,ec,area]/DEEBeforeStd[enduse,tech,ec,area]
      DEEMax[enduse,tech,ec,area] = DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area]*0.98
      if DEE[enduse,tech,ec,area] > DEEMax[enduse,tech,ec,area]
        @finite_math DEMM[enduse,tech,ec,area] = max(DEMM[enduse,tech,ec,area],
          DEE[enduse,tech,ec,area]/(DEM[enduse,tech,ec,area]*0.98))
      end
      if xDCC[enduse,tech,ec,area] != -99
        @finite_math DCMM[enduse,tech,ec,area] = DCMM[enduse,tech,ec,area]*xDCC[enduse,tech,ec,area]*
                                                 Inflation[area]/DCCBeforeStd[enduse,tech,ec,area]
      end
    end

    WriteDisk(db,"$Outpt/DEE",year,DEE)
    WriteDisk(db,"$Outpt/DEEBeforeStd",year,DEEBeforeStd)
    WriteDisk(db,"$CalDB/DEMM",year,DEMM)
    WriteDisk(db,"$Input/DCMM",year,DCMM)
  end
end

function CalPEMM(data)
  (;db,year) = data
  (;Areas) = data
  (;ECs,Enduse) = data
  (;Hours) = data
  (;PI) = data
  (;Techs) = data
  (;CHR) = data
  (;CHRM) = data
  (;Endogenous) = data
  (;Hours) = data
  (;PEE) = data
  (;PEEBeforeStd,PEECalPEMM,PEM,PEMM,PERPrior,PEStd,PEStdP) = data
  (;xPEEBeforeStd) = data
  (;PEEHeat,PEEWeight,Weights,PEEMax) = data
  (;xProcSw) = data


  #
  # Calibrate Process Technology
  #
  CMarginal = Select(PI,"CMarginal")
  if xProcSw[CMarginal] == Endogenous
    # @info "$SectorName Calib.jl - Process Efficiency Calibration for " Yrv[year]

    #
    # Compute process efficiency multiplier (PEMM) for all enduses
    # except residential and commercial air conditioning.
    #
    if (SectorName == "Residential") || (SectorName == "Commercial")
      enduses = Select(Enduse,!=("AC"))
    else
      enduses = collect(Select(Enduse))
    end
    for area in Areas, ec in ECs, tech in Techs, enduse in enduses
      if xPEEBeforeStd[enduse,tech,ec,area] > 0.0

        @finite_math PEMM[enduse,tech,ec,area] = PEMM[enduse,tech,ec,area]*
          xPEEBeforeStd[enduse,tech,ec,area]/PEEBeforeStd[enduse,tech,ec,area]

        PEECalPEMM[enduse,tech,ec,area] = 
          PEEBeforeStd[enduse,tech,ec,area]*PEMM[enduse,tech,ec,area]

        PEECalPEMM[enduse,tech,ec,area] = max(PEECalPEMM[enduse,tech,ec,area],
                                          PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area])
        PEEMax[enduse,tech,ec,area] = PEM[enduse,ec,area]*PEMM[enduse,tech,ec,area]*0.98
        if PEECalPEMM[enduse,tech,ec,area] > PEEMax[enduse,tech,ec,area]
          @finite_math PEMM[enduse,tech,ec,area] = max(PEMM[enduse,tech,ec,area],
                                                   PEECalPEMM[enduse,tech,ec,area]/(PEM[enduse,ec,area]*0.98))
        end
      end
    end

    #
    # If space heating (Heat) and air conditioning (AC) both exist, then
    # compute process efficiency multiplier (PEMM) for air conditioning.
    #
    if (SectorName == "Residential") || (SectorName == "Commercial")

      Heat = Select(Enduse,"Heat")
      enduse = Select(Enduse,"AC")
      
      for area in Areas, ec in ECs
        for tech in Techs
          @finite_math PEECalPEMM[enduse,tech,ec,area] =
            sum(PEE[Heat,t,ec,area]*PERPrior[Heat,t,ec,area] for t in Techs)/
            sum(PERPrior[Heat,t,ec,area] for t in Techs)/
            (CHR[ec,area]*CHRM[ec,area])*PEMM[enduse,tech,ec,area]
     
          if xPEEBeforeStd[enduse,tech,ec,area] > 0.0
            @finite_math PEMM[enduse,tech,ec,area] =
              PEMM[enduse,tech,ec,area]*xPEEBeforeStd[enduse,tech,ec,area]/
              PEECalPEMM[enduse,tech,ec,area]
           
            PEECalPEMM[enduse,tech,ec,area] = PEECalPEMM[enduse,tech,ec,area]*
                                              PEMM[enduse,tech,ec,area]
                                             
            PEECalPEMM[enduse,tech,ec,area] = max(PEECalPEMM[enduse,tech,ec,area],
              PEStd[enduse,tech,ec,area],PEStdP[enduse,tech,ec,area])
             
            PEEMax[enduse,tech,ec,area] = PEM[enduse,ec,area]*PEMM[enduse,tech,ec,area]*0.98
           
            if PEECalPEMM[enduse,tech,ec,area] > PEEMax[enduse,tech,ec,area]
              @finite_math PEMM[enduse,tech,ec,area] = max(PEMM[enduse,tech,ec,area],
                PEECalPEMM[enduse,tech,ec,area]/(PEM[enduse,ec,area]*0.98))
            end
          end
        end
      end
    end
    WriteDisk(db,"$CalDB/PEMM",year,PEMM)
  end
end

function MarketShareAC(data,enduse,ec,area)
  (;db,year) = data
  (;Age,Ages,EC) = data
  (;ECC,Enduse) = data
  (;Hours) = data
  (;Tech,Techs) = data
  (;EUPCPrior) = data
  (;Hours,MMSF) = data
  (;PCA) = data
  (;MMSFAll,MMSFGeoHP,MMSFOther) = data

  if Enduse[enduse] == "AC"
    #
    # Market share for Geothermal and Heat Pumps AC is equal to their
    # market share for Space Heating.
    #
    techs = Select(Tech,["Geothermal","HeatPump","DualHPump"])
    Heat = Select(Enduse,"Heat")
    New = Select(Age,"New")

    for TE in techs
      ecc = Select(ECC,EC[ec])

      @finite_math MMSF[enduse,TE,ec,area] = sum(EUPCPrior[Heat,TE,age,ec,area]-EUPCPrior[enduse,TE,age,ec,area] for age in Ages)/
        (PCA[New,ecc,area])*0.60
      MMSF[enduse,TE,ec,area] = max(MMSF[enduse,TE,ec,area],0)
    end
    MMSFGeoHP[ec,area] = min(sum(MMSF[enduse,TE,ec,area] for TE in techs),1.00)
    
    #
    # Scale other market shares to sum to 1.0 with new Geo/HP values
    #
    techs_1 = Select(Tech,!=("Geothermal"))
    techs_2 = Select(Tech,!=("HeatPump"))
    techs_3 = Select(Tech,!=("DualHPump"))
    techs = intersect(techs_1,techs_2,techs_3)
    MMSFOther[ec,area] = sum(MMSF[enduse,TE,ec,area] for TE in techs)
    for tech in techs
      @finite_math MMSF[enduse,tech,ec,area] = MMSF[enduse,tech,ec,area]/MMSFOther[ec,area]*(1-MMSFGeoHP[ec,area])
    end

    #
    # Normalize marginal market share to equal 1.00
    #
    MMSFAll[ec,area] = sum(MMSF[enduse,tech,ec,area] for tech in Techs)
    for tech in Techs
      @finite_math MMSF[enduse,tech,ec,area] = MMSF[enduse,tech,ec,area]/MMSFAll[ec,area]
    end
    WriteDisk(db,"$Outpt/MMSF",year,MMSF)
  end
end

function Coefficients(data,CalibPass)
  (;db,year,CTime) = data
  (;Age,Ages,Area,Areas,CTechs,EC,ECC,ECs,Enduse,Enduses) = data
  (;Hours,Tech,Techs,Vintage,Vintages,Years) = data
  (;AgingFactor,CalibTime,CERSM,CERSMYr,CFraction) = data
  (;CUF,DDay,DDayNorm,DDCoefficient,DEE,DEEAPrior) = data
  (;DERAgedV,DERAV,DERPrior,DERRDV,DERRR,DERRV,DERV,DERVAllocation,DERVPrior,DERVSum) = data
  (;DmdSw,DPL,DPLV,DSMEU,DSt,DStPrior) = data
  (;EUPCPrior,Exogenous) = data
  (;Hours,Inflation,Inflation0,MCFU,MCFU0,MMSF,MMSM0,MMSMI,MVF) = data
  (;PCA,PEE,PEE0) = data
  (;PEEAPrior,PEMMSw,PEMMYr,PEPL,PERPrior,PERRR) = data
  (;StockAdjustment,TSLoad,UMS) = data
  (;xDmd,xDmdTrend,xFsDmd,xMMSF) = data
  (;ALPHA,BETA,CMSM0,CMSMI,CVF,DER1,DERA1,DERAD) = data
  (;DERAP,DERAPC1,DERR1,DERRD,DERRP,DERRPC,EUPCRC) = data
  (;EUPCRPC,GAMMA,HLoc,LastVintage,MAW) = data
  (;MU,PERADSt,PERAP,PenultimateVintage,PERRDSt,PERRP,PERRPC,SPC,SPC0,SPCA,SPCPL) = data
  (;SPop,SPop0,WCUF) = data

  #
  # Calculate Calibration Parameters
  #
  # @info "$SectorName Calib.jl - Market Share, CERSM, and CUF Calib. for " Yrv[year]

  # Select Tech*,EC*,Enduse*,CTech*,Year(Current)
  #
  # Calculate CERSM and MSM by recognizing that prior values can
  # be treated as constants so that xDmd can be written as:
  #     xDmd=CERSM*CUF*(ALPHA+BETA*MSF)
  # with MSF a function of MSM. CUF, CERSM and MSM can be
  # solved directly or by using least-squares.
  # Hold CUF at 1.0 for analysis and use as error term when done.
  # Solve for xMSF first by noting that CERSM can be cancelled out:
  #     xDmd(I)/xDmd(J)=(ALPHA(I)+BETA(I)+xMSF(I))/(ALPHA(J)+BETA(J)+xMSF(J))
  # and noting that sum(F)(xMSF(F))=1.0 and xMSF GT 0.
  # Then do regression to solve CERSM:
  #      xDmd(I)=CERSM*GAMMA(I)
  # where GAMMA=ALPHA+BETA*xMSF
  #
  # Get Old Coefficients in Case of No Fuel Use
  #

  # Select Year(Prior)
  # Read Disk(CUFPrior,CERSMPrior,PERPrior,DERPrior,DStL,PEEAPrior,DEEAPrior,EUPCPrior)
  # Select Year(Current)
  # Read Disk(DERRR,PERRR)

  #
  # Add in historical DSM savings
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDmdTrend[enduse,tech,ec,area] = xDmdTrend[enduse,tech,ec,area]+DSMEU[enduse,tech,ec,area]
  end

  #
  # If the demands are exogenous (DmdSw=Exogenous), then they are not calibrated.
  #
  for area in Areas, ec in ECs, tech in Techs
    if DmdSw[tech,ec,area] == Exogenous
      for enduse in Enduses
        xDmdTrend[enduse,tech,ec,area] = 0
        xFsDmd[tech,ec,area] = 0
      end
    end
  end

  TPrice(data)

  New = Select(Age,"New")
  Old = Select(Age,"Old")
  for area in Areas, ec in ECs, enduse in Enduses
    
    #
    # Write GOTOXY(2,10), CENTER(EnduseDS,ECDS)
    #
    for tech in Techs
      MMSM0[enduse,tech,ec,area] = -2*log(Infinity)
      xMMSF[enduse,tech,ec,area] = 0
    end

    for age in Ages, tech in Techs
      @finite_math EUPCRPC[tech,age,ec,area] = EUPCPrior[enduse,tech,age,ec,area]/(SPCPL[ec,area]/3)
    end
    for tech in Techs
      @finite_math PERADSt[tech,ec,area] = (sum(EUPCPrior[enduse,tech,age,ec,area] for age in Ages)-
        EUPCRPC[tech,Old,ec,area])*
        max(0,(DSt[enduse,ec,area]-DStPrior[enduse,ec,area]))/PEEAPrior[enduse,tech,ec,area]
    end
    for tech in Techs
      @finite_math DERAPC1[tech,ec,area] = PERADSt[tech,ec,area]/DEE[enduse,tech,ec,area]
    end
    for tech in Techs
      @finite_math PERRDSt[tech,ec,area] = (sum(EUPCPrior[enduse,tech,age,ec,area] for age in Ages)-
        EUPCRPC[tech,Old,ec,area])*
        max(0,(DStPrior[enduse,ec,area]-DSt[enduse,ec,area]))/PEEAPrior[enduse,tech,ec,area]
    end
    for tech in Techs
      @finite_math PERRPC[tech,ec,area] = EUPCRPC[tech,Old,ec,area]*DStPrior[enduse,ec,area]/
        PEEAPrior[enduse,tech,ec,area]
    end
    for tech in Techs
      @finite_math PERRP[tech,ec,area] = (PERPrior[enduse,tech,ec,area]-
        PERRPC[tech,ec,area]-PERRDSt[tech,ec,area])/PEPL[enduse,tech,ec,area]
    end
    for tech in Techs
      @finite_math PERAP[tech,ec,area] = PERRP[tech,ec,area]*PEEAPrior[enduse,tech,ec,area]/PEE[enduse,tech,ec,area]
    end
    for tech in Techs
      @finite_math DERAP[tech,ec,area] = max(0,(PERAP[tech,ec,area]-PERRP[tech,ec,area]))/DEE[enduse,tech,ec,area]
    end

    #
    # Age Vintages
    #
    # AgingFactor is a local variable for now defined as number of vintages over DPL
    #
    for tech in Techs, vintage in Vintages
      @finite_math AgingFactor[tech,ec,area,vintage] = min(Int(length(Vintage))/DPL[enduse,tech,ec,area], 1.0)
      DERAgedV[tech,ec,area,vintage] = DERVPrior[enduse,tech,ec,area,vintage]*AgingFactor[tech,ec,area,vintage]
    end
    
    FirstVintage = 1
    for tech in Techs
      DERV[tech,ec,area,FirstVintage] = DERVPrior[enduse,tech,ec,area,FirstVintage]-
                                        DERAgedV[tech,ec,area,FirstVintage]
    end
  
    LastVintage=Int(length(Vintage))
    PenultimateVintage = LastVintage-1
    vintages = collect(2:PenultimateVintage)  
    for tech in Techs, vintage in vintages
      vintageprior = vintage-1
      DERV[tech,ec,area,vintage] = DERVPrior[enduse,tech,ec,area,vintage]-
        DERAgedV[tech,ec,area,vintage]+DERAgedV[tech,ec,area,vintageprior]
    end
  
    LastVintage = Int(length(Vintage))
    vintageprior = LastVintage-1
    for tech in Techs
      DERV[tech,ec,area,LastVintage] = DERVPrior[enduse,tech,ec,area,LastVintage]+DERAgedV[tech,ec,area,vintageprior]
    end

    for tech in Techs
      DERVSum[tech,ec,area] = sum(DERV[tech,ec,area,vintage] for vintage in Vintages)
      for vintage in Vintages
        @finite_math DERVAllocation[tech,ec,area,vintage] = DERV[tech,ec,area,vintage] /
                                                            DERVSum[tech,ec,area]
      end
    end

    for tech in Techs
      @finite_math DERRPC[tech,ec,area] = (PERRPC[tech,ec,area]+PERRDSt[tech,ec,area])/DEEAPrior[enduse,tech,ec,area]
    end

    for tech in Techs
      @finite_math DERRP[tech,ec,area] = max(0,(PERRP[tech,ec,area]-PERAP[tech,ec,area]))/DEEAPrior[enduse,tech,ec,area]
    end
    
    for tech in Techs, vintage in Vintages
      @finite_math DERRDV[tech,ec,area,vintage] = (DERVSum[tech,ec,area]-
      DERRPC[tech,ec,area]-DERRP[tech,ec,area])*DERVAllocation[tech,ec,area,vintage]*
      DPLV[enduse,tech,ec,area,vintage]
    end
    for tech in Techs
      @finite_math DERRD[tech,ec,area] = sum(DERRDV[tech,ec,area,vintage] for vintage in Vintages)   
    end
  
    for tech in Techs
      @finite_math DERAD[tech,ec,area] = DERRD[tech,ec,area]*DEEAPrior[enduse,tech,ec,area]/DEE[enduse,tech,ec,area]
    end

    for tech in Techs
      DERA1[tech,ec,area] = DERAPC1[tech,ec,area]+DERAP[tech,ec,area]+DERAD[tech,ec,area]
    end

    vintage = 1
    for tech in Techs
      DERAV[tech,ec,area,vintage] = DERA1[tech,ec,area]
    end

    for tech in Techs, vintage in Vintages
      @finite_math DERRV[tech,ec,area,vintage] = DERRDV[tech,ec,area,vintage]+
      (DERRPC[tech,ec,area]+DERRP[tech,ec,area]+DERRR[enduse,tech,ec,area]+PERRR[enduse,tech,ec,area]/
      DEEAPrior[enduse,tech,ec,area])*DERVAllocation[tech,ec,area,vintage]
    end
    
    for tech in Techs, vintage in Vintages    
      DERV[tech,ec,area,vintage] = DERV[tech,ec,area,vintage]+
        DT*(DERAV[tech,ec,area,vintage]-DERRV[tech,ec,area,vintage])
    end 

    for tech in Techs
      DER1[tech,ec,area] = sum(DERV[tech,ec,area,vintage] for vintage in Vintages)
    end

    for tech in Techs
      ALPHA[tech,ec,area] = DER1[tech,ec,area]
    end
    for tech in Techs
      @finite_math BETA[tech,ec,area] = (SPCA[New,ec,area]+
        sum(EUPCRC[enduse,fromTech,age,ec,area]*
        CFraction[enduse,fromTech,ec,area] for age in Ages, fromTech in Techs))*
        DSt[enduse,ec,area]/(PEE[enduse,tech,ec,area]*DEE[enduse,tech,ec,area])
    end

    #
    # Exogenous Stock Adjustment
    #
    for tech in Techs
      ALPHA[tech,ec,area] = ALPHA[tech,ec,area]*
        (1+StockAdjustment[enduse,tech,ec,area])
      BETA[tech,ec,area] = BETA[tech,ec,area]*
        (1+StockAdjustment[enduse,tech,ec,area])
    end

    techs_der = findall(DERPrior[enduse,:,ec,area] .> 0)
    techs_trend = findall(xDmdTrend[enduse,:,ec,area] .> 0)
    techs = intersect(techs_der,techs_trend)

    if !isempty(techs)
      #
      # Check for no fuel use in Enduse  (But DER may be positive)
      #
      tech = first(techs)
      ecc = Select(ECC,EC[ec])
      if (DERPrior[enduse,tech,ec,area] > 0) && (xDmdTrend[enduse,tech,ec,area] > 0)
        Sum1 = (PCA[New,ecc,area])
        if Sum1 > 0
          Test = false
          while Test == false
            if length(techs) > 1
              #
              # Make Table to Translate Fuel to Array Entries
              #
              Loc1 = Int(0)
              for tech in techs
                Loc1 = Loc1+1
                HLoc[Loc1] = tech
              end

              #
              # Fill "AA" Array
              #
              NROW = Int(length(techs))
              NCOL = Int(NROW+1)
              erows = collect(1:NROW)
              ecols = collect(1:NROW) 

              #
              # Note: Recreating AA and x, rather than defined above, 
              #  so that the size of AA is appropriate
              #
              AA::VariableArray{2} = zeros(Float32,length(erows),length(ecols))
              x::VariableArray{1} = zeros(Float32,length(erows))
            
              #
              # xMMSF as a function of ALPHA, BETA and xDmdTrend
              #
              hloc1 = Int(HLoc[1])
              for e in erows
                hloc = Int(HLoc[e])
                AA[e,e] = (-1)*BETA[hloc,ec,area]*xDmdTrend[enduse,hloc1,ec,area]
              end
              for erow in erows
                hloc = Int(HLoc[erow])
                AA[erow,1] = BETA[hloc1,ec,area]*xDmdTrend[enduse,hloc,ec,area]
              end
              for erow in erows
                hloc = Int(HLoc[erow])
                x[erow] = ALPHA[hloc,ec,area]*xDmdTrend[enduse,hloc1,ec,area]-
                  ALPHA[hloc1,ec,area]*xDmdTrend[enduse,hloc,ec,area]
              end

              for tech in techs
                if isnan(ALPHA[tech,ec,area])
                  @info "ALPHA ", Enduse[enduse], Tech[tech], EC[ec], Area[area]
                  readline(stdin)
                elseif isnan(BETA[tech,ec,area])
                    @info "BETA ", Enduse[enduse], Tech[tech], EC[ec], Area[area]
                    readline(stdin)
                end
              end

              for ecol in ecols
                AA[1,ecol] = 1.0
              end
              x[1] = 1.0

              #
              # Solve system of linear equations
              #
              # xSolution=AA\x  This had NANs - Jeff Amlin 8/27/24
              # erows=collect(1:NROW) # note: selections appear unused
              # ecols=collect(1:NCOL)
              # xrows=collect(1:NROW)
              xS = linregress(AA[:,:],x[:]; intercept=false)
              xSCoef = coef(xS)
              #
              # Move Solution Vector to Model Variable Names
              #
              for erow in erows
                hloc = Int(HLoc[erow])
                xMMSF[enduse,hloc,ec,area] = xSCoef[erow]
              end

              #
              # No MSF can be negative so must be 0.0 at worst.
              #
              for tech in techs
                xMMSF[enduse,tech,ec,area] = max(0.0,xMMSF[enduse,tech,ec,area])
              end
              Test = true
              for tech in techs
                if xMMSF[enduse,tech,ec,area] == 0.0
                  Test = false
                end
              end
              techs = findall(xMMSF[enduse,:,ec,area] .> 0)
              #
              # Select Tech If xMMSF GT 0
              #
            elseif length(techs) == 1
              for tech in techs
                xMMSF[enduse,tech,ec,area] = 1.0
                Test = true
              end
            end # if tech
          end # while

          #
          # Back Solve for MMSM0 and normalize one fuel to Zero
          #
          for tech in techs
            @finite_math MAW[enduse,tech,ec,area] = exp(MMSMI[enduse,tech,ec,area]*
              (SPC[ec,area]/SPop[ec,area])/(SPC0[ec,area]/SPop0[ec,area])+
              MVF[enduse,tech,ec,area]*log((MCFU[enduse,tech,ec,area]/Inflation[area]/
              PEE[enduse,tech,ec,area])/(MCFU0[enduse,tech,ec,area]/Inflation0[area]/PEE0[enduse,tech,ec,area])))
          end

          for tech in techs
            @finite_math MU[tech] = xMMSF[enduse,tech,ec,area]/MAW[enduse,tech,ec,area]
          end
          MuMax = 0
          for tech in techs
            MuMax = max(MU[tech],MuMax)
          end
          for tech in techs
            MMSM0[enduse,tech,ec,area] = log(MU[tech]/MuMax)
            xxx = MMSM0[enduse,tech,ec,area]
            if isinf(xxx)
              MMSM0[enduse,tech,ec,area] = -170.39
            end            
            #
            # Set units that are very close to zero equal to zero to account for precision differences - Ian 12/03/24
            #
          end
        end # sum PCA

        if Enduse[enduse] == "AC"
          for tech in Techs
            MMSM0[enduse,tech,ec,area] = -2*log(Infinity)
            if Tech[tech] == "Electric"
              MMSM0[enduse,tech,ec,area] = 0
            end
          end
          MarketShareAC(data,enduse,ec,area)
          for tech in Techs
            xMMSF[enduse,tech,ec,area] = MMSF[enduse,tech,ec,area]
          end
        end

        #
        # Get back ALL fuels involved (xDmdTrend GT 0)
        #

        techs_der = findall(DERPrior[enduse,:,ec,area] .> 0)
        techs_trend = findall(xDmdTrend[enduse,:,ec,area] .> 0)
        techs = intersect(techs_der,techs_trend)
        
        #
        # Solve Least-Square Value of CERSM
        #
        for tech in techs
          @finite_math GAMMA[tech,ec,area] = (ALPHA[tech,ec,area]+BETA[tech,ec,area]*
            xMMSF[enduse,tech,ec,area])*UMS[enduse,tech,ec,area]*WCUF[ec,area]/1e6*
            (TSLoad[enduse,ec,area]*(DDay[enduse,area]/DDayNorm[enduse,area])^
            DDCoefficient[enduse,ec,area]+(1-TSLoad[enduse,ec,area]))
        end

        @finite_math CERSM[enduse,ec,area] = 
          sum(xDmdTrend[enduse,tech,ec,area]*GAMMA[tech,ec,area] for tech in techs)/
          sum(GAMMA[wtech,ec,area]*GAMMA[wtech,ec,area] for wtech in techs)
      end #if DERPrior and xDmdTrend
    end #if isempty

    #
    # Solve for CUFs.
    #
    for tech in Techs
      @finite_math CUF[enduse,tech,ec,area] = xDmd[enduse,tech,ec,area]/
        (CERSM[enduse,ec,area]*GAMMA[tech,ec,area])+
        (1-DERPrior[enduse,tech,ec,area]/DERPrior[enduse,tech,ec,area])

      #
      # Set units that are very close to zero equal to zero to account for precision differences - Ian 12/03/24
      #
      if CUF[enduse,tech,ec,area] < 1.0e-14
        CUF[enduse,tech,ec,area] = 0
      end
    end
  end # for area, etc

  WriteDisk(db,"$CalDB/CUF",year,CUF)
  WriteDisk(db,"$CalDB/CERSM",year,CERSM)
  WriteDisk(db,"$CalDB/MMSM0",year,MMSM0)
  WriteDisk(db,"$CalDB/xMMSF",year,xMMSF)

  #
  ########################
  #
  # Conversion Parameters
  #
  for area in Areas, ec in ECs, ctech in CTechs, tech in Techs, enduse in Enduses
    if CFraction[enduse,tech,ec,area] == 0
      CMSM0[enduse,tech,ctech,ec,area] = -2*log(Infinity)
    else
      CMSM0[enduse,tech,ctech,ec,area] = MMSM0[enduse,tech,ec,area]
    end
    CMSMI[enduse,tech,ctech,ec,area] = MMSMI[enduse,tech,ec,area]
    CVF[enduse,tech,ctech,ec,area] = MVF[enduse,tech,ec,area]
  end

  WriteDisk(db,"$CalDB/CMSM0",year,CMSM0)
  WriteDisk(db,"$CalDB/CMSMI",CMSMI)
  WriteDisk(db,"$CalDB/CVF",year,CVF)

  #
  ########################
  #
  # Do if this is the end of the first pass
  #
  # @info "$SectorName Calib.jl - Process Efficiency Adjustment for " Yrv[year]
  if CalibPass == 1
    for area in Areas, ec in ECs
      CalLast = CalibTime[ec,area]-ITime+1
      if (PEMMSw[ec,area] == 1) && (CTime == CalibTime[ec,area])
        for enduse in Enduses
          if CERSMYr[enduse,ec,area,CalLast] > 0
            for y in Years, tech in Techs
              PEMMYr[enduse,tech,ec,area,y] = PEMMr[enduse,tech,ec,area,y]/
                CERSMYr[enduse,ec,area,CalLast]
            end
            WriteDisk(db,"$CalDB/PEMM",PEMMYr)
          end
        end
      end
    end
  end

end

Base.@kwdef struct DataLoadShape
  db::String
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))  

  
  BaseAdj::VariableArray{4} = ReadDisk(db,"SCalDB/BaseAdj") # [Day,Month,Area,Year] Adjustment Based on All Years (MW/MW)
  CalibLTime::VariableArray{1} = ReadDisk(db,"SInput/CalibLTime") #[Area] Last Year of Load Curve Calibration (Year)
  CgLSF::VariableArray{6} = ReadDisk(db,"$CalDB/CgLSF") # [Tech,EC,Hour,Day,Month,Area] Cogeneration Load Shape (MW/MW)
  CgLSFSold::VariableArray{5} = ReadDisk(db,"$CalDB/CgLSFSold") # [EC,Hour,Day,Month,Area] Cogeneration Sold to Grid Load Shape (MW/MW)
  DUF::VariableArray{5} = ReadDisk(db,"$CalDB/DUF") # [Enduse,EC,Day,Month,Area] Daily Use Factor (Therm/Therm)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") #[Month]  Hours per Monthly Period (HoursPerMonth)
  LSF::VariableArray{6} = ReadDisk(db,"$CalDB/LSF") # [Enduse,EC,Hour,Day,Month,Area] Load Shape Factor (DLESS)
  xCgLSF::VariableArray{6} = ReadDisk(db,"$Input/xCgLSF") # [Tech,EC,Hour,Day,Month,Area] Cogeneration Load Shape (MW/MW)
  xCgLSFSold::VariableArray{5} = ReadDisk(db,"$Input/xCgLSFSold") # [EC,Hour,Day,Month,Area] Cogeneration Sold to Grid Load Shape (MW/MW)
  xLSF::VariableArray{6} = ReadDisk(db,"$Input/xLSF") # [Enduse,EC,Hour,Day,Month,Area] Load Shape Factor (MW/MW)

  CgLSFM::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Cogeneration Load Shape Normalization Factor (MW/MW)
  LSFM::VariableArray{1} = zeros(Float32,length(Enduse)) # [Enduse] Load Shape Normalization Factor (DLESS)

end

function LoadShape(db)
  data = DataLoadShape(; db)
  (;db) = data
  (;Areas,Days,ECs) = data
  (;Enduses,Hours) = data
  (;Months,Techs) = data
  (;CgLSF,CgLSFSold,LSF) = data
  (;xCgLSF,xCgLSFSold,xLSF) = data

  @info "Calib.jl $SectorName LoadShape - Load Shape Factor Initialization"

  for area in Areas, month in Months, day in Days, hour in Hours, ec in ECs
    for enduse in Enduses
      LSF[enduse,ec,hour,day,month,area] = xLSF[enduse,ec,hour,day,month,area]
    end
    for tech in Techs
      CgLSF[tech,ec,hour,day,month,area] = xCgLSF[tech,ec,hour,day,month,area]
    end
    CgLSFSold[ec,hour,day,month,area] = xCgLSFSold[ec,hour,day,month,area]
  end

  WriteDisk(db,"$CalDB/LSF",LSF)
  WriteDisk(db,"$CalDB/CgLSF",CgLSF)
  WriteDisk(db,"$CalDB/CgLSFSold",CgLSFSold)
end

function Normalize(db)
  data = DataLoadShape(; db)
  (;db,CalibLTime) = data
  (;Areas,Day,Days,ECs) = data
  (;Enduses,Hours) = data
  (;Months) = data
  (;BaseAdj,DUF,HoursPerMonth,LSF,LSFM) = data

  @info "Calib.jl $SectorName Normalize - Load Shape Factor Normalization"

  for area in Areas, ec in ECs
    CalLast = Int(CalibLTime[area]-ITime+1)
    Average = Select(Day,"Average")
    for enduse in Enduses
      for month in Months, hour in Hours
        LSF[enduse,ec,hour,Average,month,area] = 
          LSF[enduse,ec,hour,Average,month,area]*BaseAdj[Average,month,area,CalLast]
      end
      LSFM[enduse] = sum(LSF[enduse,ec,hour,Average,month,area]*
                       HoursPerMonth[month] for hour in Hours, month in Months)/8760
                       
      for month in Months, hour in Hours
        @finite_math LSF[enduse,ec,hour,Average,month,area] = 
                     LSF[enduse,ec,hour,Average,month,area]/LSFM[enduse]
      end
    end

    for month in Months, day in Days, enduse in Enduses
      DUF[enduse,ec,day,month,area] = sum(LSF[enduse,ec,hour,day,month,area] for hour in Hours)
    end

    #
    # Note: CgLSF and CgLSFSold commented out in Promula
    # for tech in Techs
    #   for month in Months, hour in Hours
    #     CgLSF[tech,ec,hour,Average,month,area] = CgLSF[tech,ec,hour,Average,month,area]*BaseAdj[Average,month,area]
    #   end
    #   CgLSFM[tech] = sum(CgLSF[enduse,ec,hour,Average,month,area]*
    #                    HoursPerMonth[month]/8760 for hour in Hours, month in Months)
    #   for month in Months, hour in Hours
    #       @finite_math CgLSF[tech,ec,hour,Average,month,area] = 
    #                    CgLSF[tech,ec,hour,Average,month,area]/CgLSFM[enduse]
    #   end
    # end
    #
    # for month in Months, hour in Hours
    #   CgLSFSold[ec,hour,Average,month,area] = CgLSFSold[ec,hour,Average,month,area]*BaseAdj[Average,month,area]
    # end
    # CgLSFSoldM[tech] = sum(CgLSFSold[enduse,ec,hour,Average,month,area]*HoursPerMonth[month]/8760 for hour in Hours, month in Months)
    # for month in Months, hour in Hours
    #   @finite_math CgLSFSold[ec,hour,Average,month,area] = CgLSFSold[tech,ec,hour,Average,month,area]/CgLSFM[enduse]
    # end
    
  end

  WriteDisk(db,"$CalDB/LSF",LSF)
  WriteDisk(db,"$CalDB/DUF",DUF)
  # WriteDisk(db,"$CalDB/CgLSF",CgLSF)
  # WriteDisk(db,"$CalDB/CgLSFSold",CgLSFSold)
end

end

