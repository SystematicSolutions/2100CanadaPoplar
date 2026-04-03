#
# CInitial.jl - Commercial Constants and initial values
#
# Write (" CInitial.jl, Commercial Constants and initial values")
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2013 Systematic Solutions, Inc. All rights reserved.
#

using EnergyModel

module CInitial

import ...EnergyModel: ReadDisk,WriteDisk,Select,Yr
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,DT
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const Input = "CInput"
const Outpt = "COutput"
const CalDB = "CCalDB"
const SectorName::String = "Commercial"
const SectorKey::String = "Com"
const ESKey::String = "Commercial"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  Yr2010 = Yr(2010)
  Yr1997 = Yr(1997)

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESes::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelKey::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPKey::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
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
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  AB::VariableArray{5} = ReadDisk(db,"$Outpt/AB") # [Enduse,Tech,EC,Area,Year] Initial Average Budget ($/$)
  CgUMS::VariableArray{4} = ReadDisk(db,"$Outpt/CgUMS") # [Tech,EC,Area,Year] CgUMS: Cogen. Utilization Mult. (tBtu/tBtu)
  CgVF::VariableArray{3} = ReadDisk(db,"$CalDB/CgVF") # [Tech,EC,Area] Cogeneration Variance Factor ($/$)
  CHR::VariableArray{2} = ReadDisk(db,"$CalDB/CHR") # [EC,Area] Cooling to Heating Ratio
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]
  DCC::VariableArray{5} = ReadDisk(db,"$Outpt/DCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost ($/mmBtu/Yr)
  DCCA0::VariableArray{5} = ReadDisk(db,"$Input/DCCA0") # [Enduse,Tech,EC,Area,Year] Device Capital Cost A0 Coeffcient for Efficiency Program (Btu/Btu)
  DCCB0::VariableArray{5} = ReadDisk(db,"$Input/DCCB0") # [Enduse,Tech,EC,Area,Year] Device Capital Cost B0 Coeffcient for Efficiency Program (Btu/Btu)
  DCCC0::VariableArray{5} = ReadDisk(db,"$Input/DCCC0") # [Enduse,Tech,EC,Area,Year] Device Capital Cost C0 Coeffcient for Efficiency Program (Btu/Btu)
  DCCN::VariableArray{4} = ReadDisk(db,"$Outpt/DCCN") # [Enduse,Tech,EC,Area] Normalized Device Capital Cost ($/mmBtu)
  DCCRN::VariableArray{5} = ReadDisk(db,"$Outpt/DCCR") # [Enduse,Tech,EC,Area,Year] Device Capital Charge Rate ($/Yr/$)
  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # Capital Cost Maximum Multiplier  ($/$) [Enduse,Tech,EC,Area]
  DCTC::VariableArray{5} = ReadDisk(db,"$Outpt/DCTC") # [Enduse,Tech,EC,Area,Year] Device Cap. Trade Off Coefficient (DLESS)
  DCTC0::VariableArray{5} = ReadDisk(db,"$Outpt/DCTC") # [Enduse,Tech,EC,Area,Year] Device Cap. Trade Off Coefficient (DLESS)
  DDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  DDCoefficient::VariableArray{4} = ReadDisk(db,"$Input/DDCoefficient") # [Enduse,EC,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  DEE::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu)
  DEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DEEA0::VariableArray{5} = ReadDisk(db,"$Input/DEEA0") # [Enduse,Tech,EC,Area,Year] Device A0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEB0::VariableArray{5} = ReadDisk(db,"$Input/DEEB0") # [Enduse,Tech,EC,Area,Year] Device B0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEC0::VariableArray{5} = ReadDisk(db,"$Input/DEEC0") # [Enduse,Tech,EC,Area,Year] Device C0 Coeffcient for Efficiency Program (Btu/Btu)
  DEESw::VariableArray{5} = ReadDisk(db,"$Input/DEESw") # [Enduse,Tech,EC,Area,Year] Switch for Device Efficiency (Switch) 
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  DER::VariableArray{5} = ReadDisk(db,"$Outpt/DER") # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  DERV::VariableArray{6} = ReadDisk(db,"$Outpt/DERV") # Energy Requirement by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERVAllocation::VariableArray{6} = ReadDisk(db,"$Outpt/DERVAllocation") # Fraction of DER in each Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  DERVSum::VariableArray{5} = ReadDisk(db,"$Outpt/DERVSum") # Sum of Energy Requirement by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area]
  DEPM::VariableArray{5} = ReadDisk(db,"$Input/DEPM") # [Enduse,Tech,EC,Area,Year] Device Energy Price Multiplier ($/$)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu)
  DEStdP::VariableArray{5} = ReadDisk(db,"$Input/DEStdP") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards Policy (Btu/Btu)
  DFPN::VariableArray{4} = ReadDisk(db,"$Outpt/DFPN") # [Enduse,Tech,EC,Area] Normalized Fuel Price ($/mmBtu)
  DFTC::VariableArray{5} = ReadDisk(db,"$Outpt/DFTC") # [Enduse,Tech,EC,Area,Year] Device Fuel Trade Off Coef. (DLESS)
  DFTC0::VariableArray{5} = ReadDisk(db,"$Outpt/DFTC") # [Enduse,Tech,EC,Area,Year] Device Fuel Trade Off Coef. (DLESS)
  DIVTC::VariableArray{3} = ReadDisk(db,"$Input/DIVTC") # [Tech,Area,Year] Device Investment Tax Credit ($/$)
  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  DOCF::VariableArray{5} = ReadDisk(db,"$Input/DOCF") # [Enduse,Tech,EC,Area,Year] Device Operating Cost Fraction
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  DPLV::VariableArray{6} = ReadDisk(db,"$Input/DPLV") # Scrappage Rate of Equipment by Vintage (1/1) [Enduse,Tech,EC,Area,Vintage]
  DRisk::VariableArray{2} = ReadDisk(db,"$Input/DRisk") # [Enduse,Tech] Device Excess Risk (DLESS)
  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Millions/Yr)
  DSt::VariableArray{4} = ReadDisk(db,"$Outpt/DSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  DTL::VariableArray{5} = ReadDisk(db,"$Outpt/DTL") # [Enduse,Tech,EC,Area,Year] Device Tax Life (Years)
  ECESMap::VariableArray{2} = ReadDisk(db,"$Input/ECESMap") # [EC,ES] Map between EC and ES for Prices (Map)
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  ECFPFuel::VariableArray{4} = ReadDisk(db,"$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  # *ECFPTech::VariableArray{5} = ReadDisk(db,"$Outpt/*ECFPTech") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  ECovECC::VariableArray{5} = ReadDisk(db,"SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage (1=Covered)
  ECoverage::VariableArray{5} = ReadDisk(db,"$Input/ECoverage") # [EC,Poll,PCov,Area,Year] Emissions Coverage (1=Covered)
  ECUF::VariableArray{3} = ReadDisk(db,"MOutput/ECUF") # [ECC,Area,Year] Capital Utilization Fraction
  EUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  ExpCP::VariableArray{4} = ReadDisk(db,"$Outpt/ExpCP") # [FuelEP,EC,Area,Year] Emission Expenditures ($M/Yr)
  FEPCP::VariableArray{4} = ReadDisk(db,"$Outpt/FEPCP") # [FuelEP,EC,Area,Year] Carbon Price by FuelEP ($/mmBtu)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FPCP::VariableArray{4} = ReadDisk(db,"$Outpt/FPCP") # [Fuel,EC,Area,Year] Carbon Price before OBA ($/mmBtu)
  FPCPFrac::VariableArray{4} = ReadDisk(db,"$Input/FPCPFrac") # [Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)
  FPCFSNet::VariableArray{4} = ReadDisk(db,"$Outpt/FPCFSNet") # [Fuel,EC,Area,Year] CFS Price ($/mmBtu)
  FPEC::VariableArray{4} = ReadDisk(db,"$Outpt/FPEC") # [Fuel,EC,Area,Year] Fuel Prices excluding Emission Costs ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  FTMap::VariableArray{2} = ReadDisk(db,"$Input/FTMap") # [Fuel,Tech]   # Map between Fuel and Tech (Map)
  GO::VariableArray{3} = ReadDisk(db,"MOutput/GO") # [ECC,Area,Year] Gross Output
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InitialDemandYear::VariableArray{2} = ReadDisk(db,"$Input/InitialDemandYear") # [EC,Area] First Year of Calibration
  Inflation2010::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr2010) # Inflation Index for 2010 ($/$) [Area]
  Inflation1997::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",Yr1997) # Inflation Index for 1997 ($/$) [Area]
  InSm::VariableArray{2} = ReadDisk(db,"MOutput/InSm") # [Area,Year] Smoothed Inflation Rate (1/Yr)
  MCFU::VariableArray{5} = ReadDisk(db,"$Outpt/MCFU") # [Enduse,Tech,EC,Area,Year] Marginal Cost of Fuel Use ($/mmBtu)
  PC::VariableArray{3} = ReadDisk(db,"MOutput/PC") # [ECC,Area,Year] Production Capacity (M$/Yr)
  PCC::VariableArray{5} = ReadDisk(db,"$Outpt/PCC") # [Enduse,Tech,EC,Area,Year] Process Capital Cost ($/($/Yr))
  PCCA0::VariableArray{5} = ReadDisk(db,"$Input/PCCA0") # [Enduse,Tech,EC,Area,Year] Process Capital Cost A0 Coeffcient for Efficiency Program ($/Btu/($/Btu)) 
  PCCB0::VariableArray{5} = ReadDisk(db,"$Input/PCCB0") # [Enduse,Tech,EC,Area,Year] Process Capital Cost B0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PCCC0::VariableArray{5} = ReadDisk(db,"$Input/PCCC0") # [Enduse,Tech,EC,Area,Year] Process Capital Cost C0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PCCCurve::VariableArray{5} = ReadDisk(db,"$Outpt/PCCCurve") # [Enduse,Tech,EC,Area,Year] Process Capital Cost from Cost Curve ($/($/Yr)
  PCCCurveM::VariableArray{5} = ReadDisk(db,"$Outpt/PCCCurveM") # [Enduse,Tech,EC,Area,Year] Process Capital Cost from Cost Curve Multplier (1/1)
  PCCN::VariableArray{4} = ReadDisk(db,"$Outpt/PCCN") # [Enduse,Tech,EC,Area] Normalized Process Capital Cost ($/mmBtu)
  PCCov::VariableArray{5} = ReadDisk(db,"$Outpt/PCCov") # [FuelEP,EC,Poll,Area,Year] Emissions Coverage by Tech or Fuel (Tonnes/Tonnes)
  PCost::VariableArray{5} = ReadDisk(db,"$Outpt/PCost") # [FuelEP,EC,Poll,Area,Year] Permit Cost ($/Tonne)
  PCostECC::VariableArray{4} = ReadDisk(db,"SOutput/PCost") # [ECC,Poll,Area,Year] Permit Cost ($/Tonne)
  PCostExo::VariableArray{5} = ReadDisk(db,"$Input/PCostExo") # [FuelEP,EC,Poll,Area,Year] Marginal Exogenous Permit Cost (Real $/Tonnes)
  PCostTech::VariableArray{4} = ReadDisk(db,"$Outpt/PCostTech") # [Tech,EC,Area,Year] Permit Cost ($/mmBtu)
  PCovMap::VariableArray{5} = ReadDisk(db,"SInput/PCovMap") # [FuelEP,ECC,PCov,Area,Year] Pollution Coverage Map (1=Mapped)
  PCPL::VariableArray{3} = ReadDisk(db,"MInput/PCPL") # [ECC,Area,Year] Physical Life of Production Capacity (Years)
  PCTC::VariableArray{5} = ReadDisk(db,"$Outpt/PCTC") # [Enduse,Tech,EC,Area,Year] Process Capital Cap. Trade Off Coef. (DLESS)
  PCTC0::VariableArray{5} = ReadDisk(db,"$Outpt/PCTC") # [Enduse,Tech,EC,Area,Year] Process Capital Cap. Trade Off Coef. (DLESS)
  PCCRN::VariableArray{5} = ReadDisk(db,"$Outpt/PCCR") # [Enduse,Tech,EC,Area,Zero] Process Capital Charge Rate
  PCgRFF::VariableArray{3} = ReadDisk(db,"MInput/PCgRF") # [Age,ECC,Area] Fraction of Energy Requirement by Age
  PCERFF::VariableArray{4} = ReadDisk(db,"SInput/PCERF") # [Fuel,Age,ECC,Area] Fraction of Energy Requirement by Age and Fuel
  PCLV::VariableArray{4} = ReadDisk(db,"MOutput/PCLV") # [Age,ECC,Area,Year] Production Capacity (M$/Yr)
  PDif::VariableArray{4} = ReadDisk(db,"$Input/PDif") # [Enduse,Tech,EC,Area] Difference between the Initial Process Efficiency for each Fuel
  PE::VariableArray{3} = ReadDisk(db,"SOutput/PE") # [ECC,Area,Year] Price of Electricity (Mills per kWh)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEEA::VariableArray{5} = ReadDisk(db,"$Outpt/PEEA") # [Enduse,Tech,EC,Area,Year] Average Process Efficiency ($/Btu)
  PEEA0::VariableArray{5} = ReadDisk(db,"$Input/PEEA0") # [Enduse,Tech,EC,Area,Year] Process A0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEEB0::VariableArray{5} = ReadDisk(db,"$Input/PEEB0") # [Enduse,Tech,EC,Area,Year] Process B0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEEC0::VariableArray{5} = ReadDisk(db,"$Input/PEEC0") # [Enduse,Tech,EC,Area,Year] Process C0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEECurve::VariableArray{5} = ReadDisk(db,"$Outpt/PEECurve") #  [Enduse,Tech,EC,Area,Year] Process Efficiency from Cost Curve ($/Btu)
  PEECurveM::VariableArray{5} = ReadDisk(db,"$Outpt/PEECurveM") # [Enduse,Tech,EC,Area,Year] Process Efficiency from Cost Curve Multiplier(1/1) 
  PEESw::VariableArray{5} = ReadDisk(db,"$Input/PEESw") # [Enduse,Tech,EC,Area,Year] Switch for Process Efficiency (Switch) 
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)
  PEMX::VariableArray{4} = ReadDisk(db,"$Input/PEMX") # [Enduse,Tech,EC,Area] Ratio of Maximum to Average Process Efficiency ($/Btu/($/Btu))
  PEPL::VariableArray{5} = ReadDisk(db,"$Outpt/PEPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Process Requirements (Years)
  PER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  PETL::VariableArray{5} = ReadDisk(db,"$Outpt/PETL") # [Enduse,Tech,EC,Area,Year] Tax Life of Process Requirements (Years)
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN") # [Enduse,Tech,EC,Area] Process Normalized Fuel Price ($/mmBtu)
  PFTC::VariableArray{5} = ReadDisk(db,"$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year] Process Fuel Trade Off Coefficient
  PFTC0::VariableArray{5} = ReadDisk(db,"$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year] Process Fuel Trade Off Coefficient
  PIVTC::VariableArray{1} = ReadDisk(db,"$Input/PIVTC") # [Year] Process Investment Tax Credit (DLESS)
  POCA::VariableArray{6} = ReadDisk(db,"$Outpt/POCA") # [Enduse,FuelEP,EC,Poll,Area,Year] Average Pollution Coefficients (Tonnes/TBtu)
  POCF::VariableArray{4} = ReadDisk(db,"$CalDB/POCF") # [Enduse,Tech,EC,Area] Process Operating Cost Fraction
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  PolMarginal::VariableArray{5} = ReadDisk(db,"$Outpt/PolMarginal") # [FuelEP,EC,Poll,Area,Year] Marginal Emissions (Tonnes/Yr)
  RDCTC::VariableArray{5} = ReadDisk(db,"$Outpt/RDCTC") # [Enduse,Tech,EC,Area,Year] Retrofit Device Cap. Trade Off Coefficient (DLESS)
  RDFTC::VariableArray{5} = ReadDisk(db,"$Outpt/RDFTC") # [Enduse,Tech,EC,Area,Year] Retrofit Device Fuel Trade Off Coefficient (DLESS)
  RPCTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPCTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Capital Trade Off Coefficient (DLESS)
  RPFTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPFTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Fuel Trade Off Coefficient
  RM::VariableArray{5} = ReadDisk(db,"$Outpt/RM") # [FuelEP,EC,Poll,Area,Year] Reduction Multiplier (Tonnes/Tonnes)
  ROIN::VariableArray{2} = ReadDisk(db,"$Input/ROIN") # [EC,Area] Return on Investment ($/Yr/$)
  STX::VariableArray{2} = ReadDisk(db,"$Input/STX") # [Area,Year] Sales Tax Rate on Energy Consumer ($/$)
  TaxPct::VariableArray{2} = ReadDisk(db,"$Input/TAXPCT") # [Area,Year] Standard accounting percent of device life that is taxed.
  TSLoad::VariableArray{3} = ReadDisk(db,"$Input/TSLoad") # [Enduse,EC,Area] Temp. Sensitive Fraction of Load
  TxRt::VariableArray{3} = ReadDisk(db,"$Input/TxRt") # [EC,Area,Year] Tax Rate on Energy Consumer (DLESS)
  xCgVF::VariableArray{2} = ReadDisk(db,"$Input/xCgVF") # [Tech,EC] Cogen. Variance Factor ($/$)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year]  Device Capital Cost ($/mmBtu/Yr)
  xDCMM::VariableArray{5} = ReadDisk(db,"$Input/xDCMM") # Maximum Device Capital Cost Mult (Btu/Btu) [Enduse,Tech,EC,Area]
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xDEMM::VariableArray{5} = ReadDisk(db,"$Input/xDEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Effic. Mult. (Btu/Btu)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xDmdPrior::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  # xDmdYr::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xDmFracPrior::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xDPL::VariableArray{5} = ReadDisk(db,"$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Historical Physical Life of Equipment (Years)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  xPCC::VariableArray{5} = ReadDisk(db,"$Input/xPCC") # [Enduse,Tech,EC,Area,Year] Process Capital Cost ($/($/Yr))
  xRM::VariableArray{5} = ReadDisk(db,"$Input/xRM") # Exogenous Average Pollution Coefficient Reduction Multiplier (Tonnes/Tonnes) [FuelEP,EC,Poll,Area]
  YDSt::VariableArray{4} = ReadDisk(db,"$Input/YDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  ZeroFr::VariableArray{4} = ReadDisk(db,"SInput/ZeroFr") # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)

  #
  # Scratch Variables
  #
  # AGENEXT                   'Next Age Category'
  AvPCCN::VariableArray{3} = zeros(Float32,length(Enduse),length(Tech),length(EC)) # [Enduse,Tech,EC] Average Value of PCCN
  AvPCTC::VariableArray{3} = zeros(Float32,length(Enduse),length(Tech),length(EC)) # [Enduse,Tech,EC] Average Value of PCTC
  AvPEM::VariableArray{2} = zeros(Float32,length(Enduse),length(EC)) # [Enduse,EC] Average Value of PEM
  AvPFPN::VariableArray{3} = zeros(Float32,length(Enduse),length(Tech),length(EC)) # [Enduse,Tech,EC] Average Value of PFPN
  AvPOCF::VariableArray{3} = zeros(Float32,length(Enduse),length(Tech),length(EC)) # [Enduse,Tech,EC] Average Value of POCF
  DEEStd::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Device Efficiency with Standard (Btu/Btu)
  DmdFEPTechPrior::VariableArray{4} = zeros(Float32,length(FuelEP),length(Tech),length(EC),length(Area)) # [FuelEP,Tech,EC,Area] Energy Demands (TBtu/Yr)
  DmdFuelTechPrior::VariableArray{5} = zeros(Float32,length(Enduse),length(Fuel),length(Tech),length(EC),length(Area)) # [Enduse,Fuel,Tech,EC,Area] Energy Demands (TBtu/Yr)
  EuDemPrior::VariableArray{4} = zeros(Float32,length(Enduse),length(FuelEP),length(EC),length(Area)) # [Enduse,FuelEP,EC,Area] Enduse Demands (TBtu/Yr)
  FPC::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Actual Production Capacity by Tech ($/Yr)
  FPCI::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Desired Production Capacity by Tech ($/Yr)
  FuelSort::VariableArray{1} = zeros(Float32,length(Fuel)) # [Fuel] Scratch Varable to Sort Fuels
  # InitialYear   'Initial Year for Energy Demands'
  Loc3::VariableArray{3} = zeros(Float32,length(Age),length(EC),length(Area)) # [Age,EC,Area]
  Loc4::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area]

  PCERF::VariableArray{4} = zeros(Float32,length(Tech),length(Age),length(EC),length(Area)) # [Tech,Age,EC,Area] Fraction of Energy Requirement by Age and Fuel
  PCERFI::VariableArray{4} = zeros(Float32,length(Tech),length(Age),length(EC),length(Area)) # [Tech,Age,EC,Area] PCERF before modification
  PCgRF::VariableArray{3} = zeros(Float32,length(Age),length(EC),length(Area)) # [Age,EC,Area] Fraction of Energy Requirement by Age
  PEECurve10::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area));
  PEECurve11::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area));
  TFPC::VariableArray{3} = zeros(Float32,length(Enduse),length(EC),length(Area)) # [Enduse,EC,Area] Total Production Capacity by Tech ($/Yr)
  WCUF::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Capacity Utilization Factor Weighted by Output
end

function Lifetimes(data)
  (;db) = data
  (;Areas,EC,ECC) = data
  (;ECs,Enduse,Enduses) = data
  (;Techs,Years) = data
  (;DCMM,DEMM) = data
  (;DPL) = data
  (;DTL) = data
  (;PCPL) = data
  (;PEPL,PETL) = data
  (;RM,TaxPct,xDCMM,xDEMM,xRM) = data
  (;xDPL,xDSt,xDSt,YDSt) = data

  @info "$SectorName Initial.jl - Lifetimes - Process and Device Lifetimes"
  
  #
  # Device Physical Lifetime
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    ecc = Select(ECC,EC[ec])
    DPL[enduse,tech,ec,area,year] = min(xDPL[enduse,tech,ec,area,year],
                                      PCPL[ecc,area,year])
  end
  WriteDisk(db,"$Outpt/DPL",DPL)

  #
  # Device Tax Lifetime
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DTL[enduse,tech,ec,area,year] = DPL[enduse,tech,ec,area,Zero]*
                                  TaxPct[area,year]
  end
  WriteDisk(db,"$Outpt/DTL",DTL)

  #
  # Process Requirements Lifetime (PEPL) are equal to the device lifetimes
  # (DPL) except for space heating (Heat) and air conditioning (AC) which
  # are equal to the capital stock lifetime (PCPL).
  #
  @. PEPL = DPL

  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    if (Enduse[enduse] == "Heat") || (Enduse[enduse] == "AC") || (Enduse[enduse] == "Carriage")
      ecc = Select(ECC,EC[ec])
      PEPL[enduse,tech,ec,area,year] = sum(PCPL[ecc,area,year])
    end
  end
  WriteDisk(db,"$Outpt/PEPL",PEPL)

  #
  # Process requirements tax lifetime
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    PETL[enduse,tech,ec,area,year] = PEPL[enduse,tech,ec,area,Zero]*
                                   TaxPct[area,year]
  end
  WriteDisk(db,"$Outpt/PETL",PETL)

  years = collect(First:Final)
  for year in years, area in Areas, ec in ECs, enduse in Enduses
    YDSt[enduse,ec,area,year] = xDSt[enduse,ec,area,year]
  end
  WriteDisk(db,"$Input/YDSt",YDSt)

  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DEMM[enduse,tech,ec,area,year] = xDEMM[enduse,tech,ec,area,year]
    DCMM[enduse,tech,ec,area,year] = xDCMM[enduse,tech,ec,area,year]
  end
  WriteDisk(db,"$CalDB/DEMM",DEMM)
  WriteDisk(db,"$Input/DCMM",DCMM)
end

function PRReductions(data)
  (;db) = data
  (;Areas,EC,ECC,Years) = data
  (;ECs) = data
  (;FuelEPs,PCovs,Polls) = data
  (;ECovECC,ECoverage) = data
  (;PCCov,PCost,PCostECC) = data
  (;PCovMap,RM,xRM) = data

  #
  # Pollution Reduction Policy
  #
  @info "$SectorName Initial.jl - PRReductions - Pollution Reductions and Costs"
  
  #
  # Note that Julia code is a bit different than Promula since we have Year in the
  # variable definition to save run time. Code below executes in Year loop whereas
  # Promula code calls procedure inside Do Year loop. - Ian 01/15/25
  #
  # Map input variables from ECC to EC
  #
  for area in Areas, poll in Polls, ec in ECs, year in Years
    ecc = Select(ECC,EC[ec])
    for pcov in PCovs
      ECoverage[ec,poll,pcov,area,year] = ECovECC[ecc,poll,pcov,area,year]
    end
    for fuelep in FuelEPs

      PCCov[fuelep,ec,poll,area,year] = 
        maximum(ECoverage[ec,poll,pcov,area,year]*
        PCovMap[fuelep,ecc,pcov,area,year] for pcov in PCovs)
        
      PCost[fuelep,ec,poll,area,year] =
        PCostECC[ecc,poll,area,year]*PCCov[fuelep,ec,poll,area,year]
        
    end
  end
  WriteDisk(db,"$Input/ECoverage",ECoverage)
  WriteDisk(db,"$Outpt/PCCov",PCCov)
  WriteDisk(db,"$Outpt/PCost",PCost)

  @. RM = xRM
  WriteDisk(db,"$Outpt/RM",RM)

end

function TPrice(data,curtime,ecs,eccs,areas)
  (;db) = data
  (;EC,ECC) = data
  (;ES,ESes,Enduses,Fuel,FuelKey) = data
  (;FuelEPKey,FuelEPs,Fuels,Polls) = data
  (;Techs) = data
  (;DmdFEPTechPrior,DmdFuelTechPrior) = data
  (;ECESMap,ECFP,ECFPFuel) = data
  (;ExpCP,FEPCP,FFPMap,FPCP,FPCPFrac,FPCFSNet,FPEC,FPF,Inflation) = data
  (;PCost,PCostExo) = data
  (;PCostTech) = data
  (;PE) = data
  (;POCX,PolMarginal,RM) = data
  (;xDmdPrior,xDmFracPrior) = data
  (;ZeroFr) = data
  (;EuDemPrior) = data

  @info "$SectorName Initial.jl - TPrice - Technology Prices "
 
  prior = max(curtime-1,1)

  for area in areas, ec in ecs, tech in Techs, fuel in Fuels, enduse in Enduses
    DmdFuelTechPrior[enduse,fuel,tech,ec,area] = 
      max(xDmdPrior[enduse,tech,ec,area,prior],0.00001)*
      xDmFracPrior[enduse,fuel,tech,ec,area,prior]
  end
  
  for area in areas, ec in ecs, tech in Techs, fuelep in FuelEPs
    DmdFEPTechPrior[fuelep,tech,ec,area] = sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels, enduse in Enduses)
  end
  
  for area in areas, ec in ecs, fuelep in FuelEPs, enduse in Enduses
    EuDemPrior[enduse,fuelep,ec,area] = 
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area]*
      FFPMap[fuelep,fuel] for fuel in Fuels, tech in Techs)
  end

  @. RM = 1
  for area in areas, poll in Polls, ec in ecs, fuelep in FuelEPs
    PolMarginal[fuelep,ec,poll,area,curtime] = 
      sum(POCX[enduse,fuelep,ec,poll,area,curtime]*(1-ZeroFr[fuelep,poll,area,curtime])*
      RM[fuelep,ec,poll,area,curtime]*
      max(EuDemPrior[enduse,fuelep,ec,area],1e-12) for enduse in Enduses)
  end
  WriteDisk(db,"$Outpt/PolMarginal",PolMarginal)

  for fuelep in FuelEPs,ec in ecs,area in areas
    @finite_math ExpCP[fuelep,ec,area,curtime] = sum((PolMarginal[fuelep,ec,poll,area,curtime]*
      (PCost[fuelep,ec,poll,area,curtime]+PCostExo[fuelep,ec,poll,area,curtime])*Inflation[area,curtime])/1e6
      for poll in Polls)
  end
  WriteDisk(db,"$Outpt/ExpCP",ExpCP)  
  
  for fuelep in FuelEPs,ec in ecs,area in areas   
    @finite_math FEPCP[fuelep,ec,area,curtime] = ExpCP[fuelep,ec,area,curtime]/
      (sum(DmdFEPTechPrior[fuelep,tech,ec,area] for tech in Techs))
  end
  WriteDisk(db,"$Outpt/FEPCP",FEPCP)

  for tech in Techs,ec in ecs,area in areas
    @finite_math PCostTech[tech,ec,area,curtime] =
      sum(FEPCP[fuelep,ec,area,curtime]*DmdFEPTechPrior[fuelep,tech,ec,area] for fuelep in FuelEPs)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,fuel in Fuels)
  end
  WriteDisk(db,"$Outpt/PCostTech",PCostTech)

  for fuel in Fuels,area in areas,ec in ecs
    if FPCPFrac[fuel,ec,area,curtime] == 0
      for fuelep in FuelEPs 
        if FuelKey[fuel] == FuelEPKey[fuelep]
          FPCP[fuel,ec,area,curtime] = FEPCP[fuelep,ec,area,curtime]
        end
      end
    else
      @finite_math FPCP[fuel,ec,area,curtime] = sum(PCostTech[tech,ec,area,curtime]*
            DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,tech in Techs)/
        sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for enduse in Enduses,tech in Techs)      
    end
  end
  WriteDisk(db,"$Outpt/FPCP",FPCP)

  for area in areas, ec in ecs, fuel in Fuels
    FPCFSNet[fuel,ec,area,curtime] = 0.00
  end
  WriteDisk(db,"$Outpt/FPCFSNet",FPCFSNet)

  #
  # Fuel Prices by Sector (EC)
  #
  for fuel in Fuels,ec in ecs,area in areas
    FPEC[fuel,ec,area,curtime] = sum(FPF[fuel,es,area,curtime]*ECESMap[ec,es] for es in ESes)
  end

  es = Select(ES,ESKey)
  ElectricFuels = Select(Fuel,["Electric","Geothermal","Solar"])
  for fuel in ElectricFuels,area in areas,ec in ecs
    ecc = Select(ECC,EC[ec])
    FPEC[fuel,ec,area,curtime] = PE[ecc,area,curtime]/3412*1000
  end
  WriteDisk(db,"$Outpt/FPEC",FPEC)

  for fuel in Fuels, ec in ecs, area in areas
    ECFPFuel[fuel,ec,area,curtime] = FPEC[fuel,ec,area,curtime]+FPCFSNet[fuel,ec,area,curtime]+FPCP[fuel,ec,area,curtime]
  end
  WriteDisk(db,"$Outpt/ECFPFuel",ECFPFuel)

  for ec in ecs,tech in Techs,area in areas,enduse in Enduses
    @finite_math ECFP[enduse,tech,ec,area,curtime] = 
      sum((FPEC[fuel,ec,area,curtime]+FPCFSNet[fuel,ec,area,curtime])*
          DmdFuelTechPrior[enduse,fuel,tech,ec,area] for fuel in Fuels)/
      sum(DmdFuelTechPrior[enduse,fuel,tech,ec,area] for fuel in Fuels)+
      PCostTech[tech,ec,area,curtime]
  end
  WriteDisk(db,"$Outpt/ECFP",ECFP)

end

function IPrice(data)
  (;db) = data
  (;Areas,ECCs) = data
  (;ECs,Enduses) = data
  (;Techs) = data
  (;CurTime,DCCRN) = data
  (;DIVTC,DPL,DRisk) = data
  (;DTL) = data
  (;InSm) = data
  (;ROIN) = data
  (;TxRt) = data

  @info "$SectorName Initial.jl - IPrice - Initial Prices for Device Efficiency Curves"

  curtime = Int(CurTime)

  PRReductions(data)
  TPrice(data,curtime,ECs,ECCs,Areas)

  #
  # Investment Levelization Rate
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    @finite_math DCCRN[enduse,tech,ec,area,curtime] = 
      (1-DIVTC[tech,area,curtime]/(1+ROIN[ec,area]+DRisk[enduse,tech]+
      InSm[area,curtime])-TxRt[ec,area,curtime]*
      (2/DTL[enduse,tech,ec,area,curtime])/
      (ROIN[ec,area]+DRisk[enduse,tech]+InSm[area,curtime]+
      2/DTL[enduse,tech,ec,area,curtime]))*(ROIN[ec,area]+DRisk[enduse,tech])/
      (1-(1/(1+ROIN[ec,area]+DRisk[enduse,tech]))^
      DPL[enduse,tech,ec,area,curtime])/(1-TxRt[ec,area,curtime])
  end
  WriteDisk(db,"$Outpt/DCCR",DCCRN)
  
end

function DEffCurve(data)
  (;db) = data
  (;Areas) = data
  (;ECs,Enduses) = data
  (;Techs,Years) = data
  (;CurTime,DCCN,DCCRN,DCTC,DCTC) = data
  (;DEM,DEStd) = data
  (;DEStdP,DFPN,DFTC,DFTC,DOCF) = data
  (;ECFP) = data
  (;Inflation) = data
  (;RDCTC,RDFTC) = data
  (;xDCC,xDEE) = data
  (;DEEStd) = data

  #
  # Device Consumer Preference Efficiency and Capital Cost Curves
  #
  @info "$SectorName Initial.jl - DEffCurve - Device Efficiency Curve Coefficients"

  curtime = Int(CurTime)

  #
  # Assume that if standard is in place in CurTime that xDCC
  # value includes the higher efficiency - Ian 02/20/16
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DEEStd[enduse,tech,ec,area] = max(xDEE[enduse,tech,ec,area,curtime],
      DEStd[enduse,tech,ec,area,curtime],DEStdP[enduse,tech,ec,area,curtime])
  end

  #
  # Capital Cost Coefficient
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    @finite_math DCTC[enduse,tech,ec,area,curtime] =
      -1/((ECFP[enduse,tech,ec,area,curtime]/Inflation[area,curtime]/
      xDEE[enduse,tech,ec,area,curtime])/
      ((DCCRN[enduse,tech,ec,area,curtime]+DOCF[enduse,tech,ec,area,curtime])*
      xDCC[enduse,tech,ec,area,curtime])*
      (1-xDEE[enduse,tech,ec,area,curtime]/DEM[enduse,tech,ec,area]))
  end

  #
  # Fuel Cost Coefficient
  #
  @finite_math @. DFTC = DCTC/(1-DCTC)

  #
  # Normal Capital Cost
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    # 
    # Added Do If to trap when DEEStd = 0 since @finite_math was still producing a value - Ian 11/13/24
    #
    if DEEStd[enduse,tech,ec,area] > 0  && xDCC[enduse,tech,ec,area,curtime] != -99.00
      @finite_math DCCN[enduse,tech,ec,area] = xDCC[enduse,tech,ec,area,curtime]/
        (DEM[enduse,tech,ec,area]/DEEStd[enduse,tech,ec,area]-1)^
        (1/DCTC[enduse,tech,ec,area,curtime])
    else
      DCCN[enduse,tech,ec,area] = 0.0
    end
  end

  #
  # Normal Fuel Cost
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    @finite_math DFPN[enduse,tech,ec,area] =
      -(DOCF[enduse,tech,ec,area,curtime]+DCCRN[enduse,tech,ec,area,curtime])*
      DCCN[enduse,tech,ec,area]*DEM[enduse,tech,ec,area]/
      DCTC[enduse,tech,ec,area,curtime]
  end

  WriteDisk(db,"$Outpt/DCCN",DCCN)
  WriteDisk(db,"$Outpt/DCTC",DCTC)
  WriteDisk(db,"$Outpt/DFPN",DFPN)
  WriteDisk(db,"$Outpt/DFTC",DFTC)

  #
  # For Device Coefficients set all year to initialization year (CurTime)
  #
  for year in Years,area in Areas,ec in ECs,tech in Techs,enduse in Enduses
    DCTC[enduse,tech,ec,area,year] = DCTC[enduse,tech,ec,area,curtime]
    DFTC[enduse,tech,ec,area,year] = DFTC[enduse,tech,ec,area,curtime]
    #
    # Device Retrofit Fuel and Capital Cost Coefficients
    #
    RDCTC[enduse,tech,ec,area,year] = DCTC[enduse,tech,ec,area,year]
    RDFTC[enduse,tech,ec,area,year] = DFTC[enduse,tech,ec,area,year]
  end

  WriteDisk(db,"$Outpt/DCTC",DCTC)
  WriteDisk(db,"$Outpt/DFTC",DFTC)
  WriteDisk(db,"$Outpt/RDCTC",RDCTC)
  WriteDisk(db,"$Outpt/RDFTC",RDFTC)

end

function Initial(data,InitialYear,ec,ecc,areas)
  (;db) = data
  (;Age,Ages,Areas) = data
  (;Enduse,Enduses) = data
  (;Fuels) = data
  (;Techs,Vintage,Vintages,Year,Years) = data
  (;AB,CgUMS,CgVF,CHR,CurTime,DCC,DCCA0,DCCB0,DCCC0,DCCN,DCCRN,DCTC) = data
  (;DDay,DDayNorm,DDCoefficient,DEE,DEEB0,DEEC0,DEESw,DEEA,DEM,DEMM,DER,DEPM,DEStd) = data
  (;DERV,DERVAllocation,DERVSum) = data
  (;DEStdP,DFPN,DFTC,DIVTC,Dmd,DPL,DPLV,DRisk) = data
  (;DSt,DTL,ECFP,ECUF,EUPC) = data
  (;FTMap,Inflation,Inflation2010) = data
  (;InSm) = data
  (;PCgRFF,PCERFF,PCLV,PDif) = data
  (;PER,PEE,PEEA) = data
  (;ROIN) = data
  (;STX,TSLoad,TxRt,xCgVF,xDEE,xDmd) = data
  (;xDmFrac,xDSt) = data
  (;FPC) = data
  (;FPCI,FuelSort,Loc3,Loc4,PCERF,PCERFI,PCgRF,TFPC,WCUF) = data

  #
  # Initializations
  #
  @info "$SectorName Initial.jl - Initial - Initialization"

  TPrice(data,InitialYear,ec,ecc,areas)

  #
  # Investment Levelization Rate
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math DCCRN[enduse,tech,ec,area,InitialYear] = 
      (1-DIVTC[tech,area,InitialYear]/(1+ROIN[ec,area]+
      DRisk[enduse,tech]+InSm[area,InitialYear])-TxRt[ec,area,InitialYear]*
      (2/DTL[enduse,tech,ec,area,InitialYear])/
      (ROIN[ec,area]+DRisk[enduse,tech]+InSm[area,InitialYear]+
      2/DTL[enduse,tech,ec,area,InitialYear]))*
      (ROIN[ec,area]+DRisk[enduse,tech])/
      (1-(1/(1+ROIN[ec,area]+DRisk[enduse,tech]))^
      DPL[enduse,tech,ec,area,InitialYear])/(1-TxRt[ec,area,InitialYear])
  end

  WriteDisk(db,"$Outpt/DCCR",DCCRN)

  #
  # Device Efficiency
  #
  for area in areas, tech in Techs, enduse in Enduses
    
    @finite_math DEE[enduse,tech,ec,area,InitialYear] = 
      DEM[enduse,tech,ec,area]*DEMM[enduse,tech,ec,area,InitialYear]*
      (1/(1+(ECFP[enduse,tech,ec,area,InitialYear]/
      Inflation[area,InitialYear]*DEPM[enduse,tech,ec,area,InitialYear]/
      DFPN[enduse,tech,ec,area])^DFTC[enduse,tech,ec,area,InitialYear]))
      
    DEE[enduse,tech,ec,area,InitialYear] = 
      max(DEE[enduse,tech,ec,area,InitialYear],
        DEStd[enduse,tech,ec,area,InitialYear],
        DEStdP[enduse,tech,ec,area,InitialYear])
  end

  #
  # Special equations use DEESw
  #
  year = InitialYear
  for area in Areas, tech in Techs, enduse in Enduses
    if DEESw[enduse,tech,ec,area,year] == 10
  
      @finite_math DEE[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,year]*
        (DEEC0[enduse,tech,ec,area,year]+DEEB0[enduse,tech,ec,area,year]*
        log(ECFP[enduse,tech,ec,area,year]/Inflation[area]*Inflation2010[area]/1.055))
        
      DEE[enduse,tech,ec,area,year] = 
        max(DEE[enduse,tech,ec,area,year],
          DEStd[enduse,tech,ec,area,year],
         DEStdP[enduse,tech,ec,area,year])        
  
    elseif DEESw[enduse,tech,ec,area,year] == 11
        
      @finite_math DEE[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,year]*
        (DEEC0[enduse,tech,ec,area,year]+DEEB0[enduse,tech,ec,area,year]/
        sqrt(ECFP[enduse,tech,ec,area,year]/Inflation[area]*Inflation2010[area]/1.055)) 
        
      DEE[enduse,tech,ec,area,year] = 
        max(DEE[enduse,tech,ec,area,year],
          DEStd[enduse,tech,ec,area,year],
         DEStdP[enduse,tech,ec,area,year])         
          
    elseif DEESw[enduse,tech,ec,area,year] == 12
      
      @finite_math DEE[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,year]*
        (DEEC0[enduse,tech,ec,area,year]+DEEB0[enduse,tech,ec,area,year]/
        (ECFP[enduse,tech,ec,area,year]/Inflation[area]*Inflation2010[area]/1.055)) 
        
      DEE[enduse,tech,ec,area,year] = 
        max(DEE[enduse,tech,ec,area,year],
          DEStd[enduse,tech,ec,area,year],
         DEStdP[enduse,tech,ec,area,year])         
    end
  end

  if CurTime != Zero
    for area in areas, tech in Techs, enduse in Enduses
      if xDEE[enduse,tech,ec,area,InitialYear] != -99.0
        DEE[enduse,tech,ec,area,InitialYear] = 
        max(xDEE[enduse,tech,ec,area,InitialYear],
          DEStd[enduse,tech,ec,area,InitialYear],
          DEStdP[enduse,tech,ec,area,InitialYear])
      end
    end
  end
  WriteDisk(db,"$Outpt/DEE",DEE)

  #
  # Expand Device Efficiency Curve (DEMM) to contain historical Efficiency (DEE)
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math DEMM[enduse,tech,ec,area,InitialYear] = 
      max(DEMM[enduse,tech,ec,area,InitialYear],
      DEE[enduse,tech,ec,area,InitialYear]/(DEM[enduse,tech,ec,area]*0.98))
  end
  WriteDisk(db,"$CalDB/DEMM",DEMM)

  #
  # Capital Cost
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math DCC[enduse,tech,ec,area,InitialYear] = 
      DCCN[enduse,tech,ec,area]*Inflation[area,InitialYear]*
      (1+STX[area,InitialYear])*(DEM[enduse,tech,ec,area]/
      DEE[enduse,tech,ec,area,InitialYear]-1)^
      (1/DCTC[enduse,tech,ec,area,InitialYear])
  end
  #
  # Special equations use DEESw
  #
  Year = InitialYear
  for area in areas, tech in Techs, enduse in Enduses  
    if DEESw[enduse,tech,ec,area,year] == 10
    
      @finite_math DCC[enduse,tech,ec,area,year] = (DCCC0[enduse,tech,ec,area,year]+
        exp((DEE[enduse,tech,ec,area,year]-DCCB0[enduse,tech,ec,area,year])/
        DCCA0[enduse,tech,ec,area,year]))/Inflation2010[area]*Inflation[area]
    
    elseif DEESw[enduse,tech,ec,area,year] == 11
    
      @finite_math DCC[enduse,tech,ec,area,year] = (DCCC0[enduse,tech,ec,area,year]+
        exp((DEE[enduse,tech,ec,area,year]-DCCB0[enduse,tech,ec,area,year])/
        DCCA0[enduse,tech,ec,area,year]))/Inflation2010[area]*Inflation[area]
    
    elseif DEESw[enduse,tech,ec,area,year] == 12
      
      @finite_math DCC[enduse,tech,ec,area,year] = (DCCC0[enduse,tech,ec,area,year]+
        exp((DEE[enduse,tech,ec,area,year]-DCCB0[enduse,tech,ec,area,year])/
        DCCA0[enduse,tech,ec,area,year]))/Inflation2010[area]*Inflation[area]
    end
  end
  WriteDisk(db,"$Outpt/DCC",DCC)

  for area in areas
    WCUF[ec,area] = ECUF[ecc,area,InitialYear]
  end

  #
  # Energy Requirements by Enduse
  #
  for area in areas, tech in Techs, enduse in Enduses
    Dmd[enduse,tech,ec,area,InitialYear] = xDmd[enduse,tech,ec,area,InitialYear]
  end

  #
  # If there are fungible demands, use the fungible demands to initialize the
  # device energy requirements.
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math DER[enduse,tech,ec,area,InitialYear] = 
      Dmd[enduse,tech,ec,area,InitialYear]/WCUF[ec,area]*1e6/
      (TSLoad[enduse,ec,area]*(DDay[enduse,area,InitialYear]/
      DDayNorm[enduse,area])^DDCoefficient[enduse,ec,area,InitialYear]+
      (1-TSLoad[enduse,ec,area]))
  end

  #
  # If there is no initial demand, then set the initial demand
  # to 1/1E12 times the maximum demand (xDmdYr).
  #
  for area in areas, tech in Techs, enduse in Enduses
    DER[enduse,tech,ec,area,InitialYear] = 
      max(DER[enduse,tech,ec,area,InitialYear],
      maximum(xDmd[enduse,tech,ec,area,year] for year in Years)/1e12)
  end
  
  #
  # Initial allocation of device stock (DERVAllocation) is based on scrappage rates (DPLV). 
  # Ian 03/20/24
  #
  for area in areas, tech in Techs, enduse in Enduses
    DERV[enduse,tech,ec,area,1,InitialYear] = DER[enduse,tech,ec,area,InitialYear]
    vintages = collect(2:Int(length(Vintage)))
    for vintage in vintages
      vintageprior = vintage-1
      DERV[enduse,tech,ec,area,vintage,InitialYear] = DERV[enduse,tech,ec,area,vintageprior,InitialYear]*
                                                      (1-DPLV[enduse,tech,ec,area,vintage,InitialYear])
    end
    DERVSum[enduse,tech,ec,area,InitialYear] = sum(DERV[enduse,tech,ec,area,vintage,InitialYear] for vintage in Vintages) 
    for vintage in Vintages
      @finite_math DERVAllocation[enduse,tech,ec,area,vintage,InitialYear] = DERV[enduse,tech,ec,area,vintage,InitialYear]/
                                                                             DERVSum[enduse,tech,ec,area,InitialYear]
      DERV[enduse,tech,ec,area,vintage,InitialYear] = DER[enduse,tech,ec,area,InitialYear]*
                                                      DERVAllocation[enduse,tech,ec,area,vintage,InitialYear]
    end
    DERVSum[enduse,tech,ec,area,InitialYear] = sum(DERV[enduse,tech,ec,area,vintage,InitialYear] for vintage in Vintages) 
  end

  WriteDisk(db,"$Outpt/DERV",DERV)
  WriteDisk(db,"$Outpt/DERVSum",DERVSum)
  
  #
  # The initial average efficiency (DEEA) is equal to the initial
  # marginal efficiency (xDEE).
  #
  for area in areas, tech in Techs, enduse in Enduses
    DEEA[enduse,tech,ec,area,InitialYear] = DEE[enduse,tech,ec,area,InitialYear]
  end

  #
  # Process Energy Requirements of Capital Stock
  #
  for area in areas, tech in Techs, enduse in Enduses
    PER[enduse,tech,ec,area,InitialYear] = 
      DER[enduse,tech,ec,area,InitialYear]*DEEA[enduse,tech,ec,area,InitialYear]
  end

  #
  # Saturation
  #
  for area in areas, enduse in Enduses
    DSt[enduse,ec,area,InitialYear] = xDSt[enduse,ec,area,InitialYear]
  end

  #
  # The "indicated" distribution of capital stock amoung technologies (FPC)
  # is equal to the process energy requirements (PER) divided by the device
  # saturation (DSt) times the difference in process efficiency between
  # technologies (PDif).
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math FPC[enduse,tech,ec,area] = 
      PER[enduse,tech,ec,area,InitialYear]/DSt[enduse,ec,area,InitialYear]*
      PDif[enduse,tech,ec,area]
  end

  #
  # The "indicated" distribution (FPC) is used to allocate the initial
  # capital stock (PCLV) by technology and enduse (FPCI).
  #
  for area in areas, enduse in Enduses
    TFPC[enduse,ec,area] = sum(FPC[enduse,tech,ec,area] for tech in Techs)
  end

  for area in areas, tech in Techs, enduse in Enduses
    @finite_math FPCI[enduse,tech,ec,area] = 
      sum(PCLV[age,ecc,area,InitialYear] for age in Ages)*
      FPC[enduse,tech,ec,area]/TFPC[enduse,ec,area]
  end

  #
  # Calculate Corrected Process Efficiency
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math PEEA[enduse,tech,ec,area,InitialYear] = 
      FPCI[enduse,tech,ec,area]*DSt[enduse,ec,area,InitialYear]/
      PER[enduse,tech,ec,area,InitialYear]
  end

  #
  # The initial marginal process efficiency (PEE) is set equal to the
  # initial average process efficiency (PEEA).
  #
  for area in areas, tech in Techs, enduse in Enduses
    PEE[enduse,tech,ec,area,InitialYear] = PEEA[enduse,tech,ec,area,InitialYear]
  end

  #
  # Use the market share for each age category (PCERF) to split the
  # capital stock (FPCI) into capital stock by age and fuel
  # (EUPCI) for each enduse
  #
  # Renormalize PCERF to be consistent with PCgRF
  # Go from Old to Mid so works with large negative growth
  #
  for enduse in Enduses
    for area in areas, age in Ages, tech in Techs
      fuels = findall(FTMap[Fuels,tech] .== 1)
      #
      #   Sort Descending Fuel using FuelSort
      #
      for fuel in Fuels
        FuelSort[fuel] = xDmFrac[enduse,fuel,tech,ec,area,InitialYear]
      end
      fuels_sorted = fuels[sortperm(FuelSort[fuels],rev = true)]
      HighestFuel = fuels_sorted[1]
      PCERF[tech,age,ec,area] = PCERFF[HighestFuel,age,ecc,area]
    end
    
    for area in areas, age in Ages, tech in Techs
      PCgRF[age,ec,area] = PCgRFF[age,ecc,area]
    end
    ages = Select(Age,["Old","Mid"])
    for age in ages
      for area in areas, tech in Techs
        PCERFI[tech,age,ec,area] = PCERF[tech,age,ec,area]
      end
      AgeNext = Int(age-1)
      
      #
      # Weighted sum of PCERF
      #
      for area in areas, tech in Techs
        @finite_math Loc3[age,ec,area] = sum(PCERF[tech,age,ec,area]*
          FPCI[enduse,tech,ec,area] for tech in Techs)/
          sum(FPCI[enduse,tech,ec,area] for tech in Techs)
      end
      
      #
      # Scale to match PCgRF
      #
      for area in areas, tech in Techs
        @finite_math PCERF[tech,age,ec,area] = PCERF[tech,age,ec,area]*
          PCgRF[age,ec,area]/Loc3[age,ec,area]
      end
      
      #
      # Move residual to next Age group
      #
      for area in areas, tech in Techs
      
        PCERF[tech,AgeNext,ec,area] = PCERF[tech,AgeNext,ec,area]+
          PCERFI[tech,age,ec,area]-PCERF[tech,age,ec,area]
          
        PCERF[tech,AgeNext,ec,area] = max(PCERF[tech,AgeNext,ec,area],0.001)
        
      end
    end
    #
    # Normalize PCERF to sum to 1.0
    #
    for area in areas, age in Ages, tech in Techs
      @finite_math PCERF[tech,age,ec,area] = PCERF[tech,age,ec,area]/
        sum(PCERF[tech,a,ec,area] for a in Ages)
    end
    
    #
    for area in areas, age in Ages, tech in Techs
      EUPC[enduse,tech,age,ec,area,InitialYear] =
        PCERF[tech,age,ec,area]*FPCI[enduse,tech,ec,area]
    end
  end

  #
  # Cooling to Heating Efficiency Ratio
  #
  if (ESKey == "Residential") || (ESKey == "Commercial")
    Heat = Select(Enduse,"Heat")
    AC=Select(Enduse,"AC")
    for area in areas
      @finite_math CHR[ec,area] = (sum(PEE[Heat,tech,ec,area,InitialYear]*
        PER[Heat,tech,ec,area,InitialYear] for tech in Techs)/
        sum(PER[Heat,tech,ec,area,InitialYear] for tech in Techs))/
        (sum(PEE[AC,tech,ec,area,InitialYear]*
        PER[AC,tech,ec,area,InitialYear] for tech in Techs)/
        sum(PER[AC,tech,ec,area,InitialYear] for tech in Techs))
    end
  end

  WriteDisk(db,"$CalDB/CHR",CHR)
  WriteDisk(db,"$Outpt/PEE",PEE)
  WriteDisk(db,"$Outpt/PEEA",PEEA)
  WriteDisk(db,"$Outpt/PER",PER)
  WriteDisk(db,"$Outpt/DEE",DEE)
  WriteDisk(db,"$Outpt/DEEA",DEEA)
  WriteDisk(db,"$Outpt/DER",DER)
  WriteDisk(db,"$Outpt/DSt",DSt)
  WriteDisk(db,"$Outpt/EUPC",EUPC)
  WriteDisk(db,"$Outpt/Dmd",Dmd)

  #
  # Initialize Average Budget
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math AB[enduse,tech,ec,area,InitialYear] = 
      ECFP[enduse,tech,ec,area,InitialYear]/Inflation[area,InitialYear]*
      DSt[enduse,ec,area,InitialYear]/
      (PEEA[enduse,tech,ec,area,InitialYear]*DEEA[enduse,tech,ec,area,InitialYear])
  end
  WriteDisk(db,"$Outpt/AB",AB)

  #
  # Cogeneration
  #
  for area in areas, tech in Techs
    CgVF[tech,ec,area] = xCgVF[tech,ec]
    CgUMS[tech,ec,area,InitialYear] = 1.0
  end
  WriteDisk(db,"$CalDB/CgVF",CgVF)
  WriteDisk(db,"$Outpt/CgUMS",CgUMS)
  
end

function PEffCurve(data,InitialYear,ec,ecc,areas)
  (;db) = data
  (;Enduse,Enduses) = data
  (;Techs) = data
  (;DCC,DCCRN) = data
  (;DEE) = data
  (;DOCF) = data
  (;ECFP) = data
  (;Inflation,Inflation1997,Inflation2010) = data
  (;InSm,MCFU,PCC,PCCA0,PCCB0,PCCC0,PCCCurve,PCCN) = data
  (;PCTC,PCCRN) = data
  (;PEE,PEEB0,PEEC0,PEECurve,PEECurve10,PEECurve11,PEECurveM,PEESw,PEM,PEMX,PEPL,PETL,PEE,PEEA,PFPN,PFTC,PIVTC) = data
  (;POCF,ROIN) = data
  (;TxRt) = data
  (;xPCC) = data

  #
  # Process Consumer Preference Efficiency and Capital Cost Curves
  #
  @info "$SectorName Initial.jl - PEffCurve - Process Efficiency Curve Coefficients"

  #
  # Cost of Using a Device
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math MCFU[enduse,tech,ec,area,InitialYear] =
      (DCCRN[enduse,tech,ec,area,InitialYear]+
        DOCF[enduse,tech,ec,area,InitialYear])*
         DCC[enduse,tech,ec,area,InitialYear]+
        ECFP[enduse,tech,ec,area,InitialYear]/
         DEE[enduse,tech,ec,area,InitialYear]
  end

  WriteDisk(db,"$Outpt/MCFU",MCFU)

  #
  # Capital Charge Rate
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math PCCRN[enduse,tech,ec,area,Zero] =
      (1-PIVTC[InitialYear]/(1+ROIN[ec,area]+0+InSm[area,InitialYear])-
      TxRt[ec,area,InitialYear]*(2/PETL[enduse,tech,ec,area,InitialYear])/
      (ROIN[ec,area]+0+InSm[area,InitialYear]+
      2/PETL[enduse,tech,ec,area,InitialYear]))*(ROIN[ec,area]+0)/
      (1-(1/(1+ROIN[ec,area]+0))^PEPL[enduse,tech,ec,area,InitialYear])/
      (1-TxRt[ec,area,InitialYear])
  end

  WriteDisk(db,"$Outpt/PCCR",PCCRN)

  #
  # Operating Cost Factor
  #
  for area in areas, tech in Techs, enduse in Enduses
    
    @finite_math POCF[enduse,tech,ec,area] = (Inflation[area,InitialYear]-
      MCFU[enduse,tech,ec,area,InitialYear]/1000000/
      PEEA[enduse,tech,ec,area,InitialYear])/
      xPCC[enduse,tech,ec,area,InitialYear]-PCCRN[enduse,tech,ec,area,Zero]
      
    POCF[enduse,tech,ec,area] = max(POCF[enduse,tech,ec,area],0)
  end
  
  #
  # Special equations use PEESw - Convert result from 2010 dollars and 
  # from Driver/GJ to Driver/BTU
  # Moved equation here to use MCFU - Ian 10/13/20
  #
  year = InitialYear
  for enduse in Enduses,tech in Techs,area in areas
      
    if MCFU[enduse,tech,ec,area,year] >= 0
      @finite_math PEECurve10[enduse,tech,ec,area] = (PEEC0[enduse,tech,ec,area,year]+
        PEEB0[enduse,tech,ec,area,year]*
        log(MCFU[enduse,tech,ec,area,year]/Inflation[area]*Inflation2010[area]/1.055))*1.055/1e6
    else
      PEECurve10[enduse,tech,ec,area] = 0.00
    end
      
    @finite_math PEECurve10[enduse,tech,ec,area] = PEECurve10[enduse,tech,ec,area]/
      Inflation2010[area]*Inflation1997[area]
  
    @finite_math PEECurve11[enduse,tech,ec,area] = (PEEC0[enduse,tech,ec,area,year]+
      PEEB0[enduse,tech,ec,area,year]/
      ((MCFU[enduse,tech,ec,area,year]/Inflation[area]*Inflation2010[area]/1.055)^0.5))*1.055/1e6
  
    @finite_math PEECurve11[enduse,tech,ec,area] = PEECurve11[enduse,tech,ec,area]/
      Inflation2010[area]*Inflation1997[area]
  end

  for enduse in Enduses,tech in Techs,area in areas
  
    if PEESw[enduse,tech,ec,area,year] == 10
        @finite_math PEECurveM[enduse,tech,ec,area,year] =
          PEEA[enduse,tech,ec,area,year]/PEECurve10[enduse,tech,ec,area]
        PEECurve[enduse,tech,ec,area,year] = PEEA[enduse,tech,ec,area,year]    
        PEE[enduse,tech,ec,area,year] = PEEA[enduse,tech,ec,area,year] 
       
    elseif PEESw[enduse,tech,ec,area,year] == 11
        @finite_math PEECurveM[enduse,tech,ec,area,year] =
          PEEA[enduse,tech,ec,area,year]/PEECurve11[enduse,tech,ec,area]
        PEECurve[enduse,tech,ec,area,year] = PEEA[enduse,tech,ec,area,year]    
        PEE[enduse,tech,ec,area,year] = PEEA[enduse,tech,ec,area,year]      

    end
  end

  #
  # Maximum Process Efficiency is based on the highest fuel.
  #
  for area in areas, enduse in Enduses
    PEM[enduse,ec,area] = maximum(PEEA[enduse,tech,ec,area,InitialYear]*
      PEMX[enduse,tech,ec,area] for tech in Techs)
  end

  #
  # Process Fuel and Capital Cost Coefficients
  #
  for area in areas, tech in Techs, enduse in Enduses
    if PEMX[enduse,tech,ec,area] != 1.0
      
      PCTC[enduse,tech,ec,area,InitialYear] = 
        -1/((MCFU[enduse,tech,ec,area,InitialYear]/1000000/
        PEEA[enduse,tech,ec,area,InitialYear])/
        ((PCCRN[enduse,tech,ec,area,Zero]+POCF[enduse,tech,ec,area])*
        xPCC[enduse,tech,ec,area,InitialYear])*
        (1-PEEA[enduse,tech,ec,area,InitialYear]/PEM[enduse,ec,area]))
      
      if isnan(PCTC[enduse,tech,ec,area,InitialYear]) == true
        PCTC[enduse,tech,ec,area,InitialYear] = 0
      end       
        
      if (ESKey == "Commercial") || (ESKey == "Transportation")
        PCTC[enduse,tech,ec,area,InitialYear] = 
          min(max(PCTC[enduse,tech,ec,area,InitialYear],-200),-5)
      end
      @finite_math PFTC[enduse,tech,ec,area,InitialYear] = 
        PCTC[enduse,tech,ec,area,InitialYear]/
        (1-PCTC[enduse,tech,ec,area,InitialYear])
    else
      PCTC[enduse,tech,ec,area,InitialYear] = 0
      PFTC[enduse,tech,ec,area,InitialYear] = 0
    end
  end

  #
  # Process Normal Fuel Cost
  #
  for area in areas, tech in Techs, enduse in Enduses
    @finite_math PFPN[enduse,tech,ec,area] = 
      -(PCCRN[enduse,tech,ec,area,Zero]+POCF[enduse,tech,ec,area])*
      xPCC[enduse,tech,ec,area,InitialYear]*PEM[enduse,ec,area]*1000000/
      (PCTC[enduse,tech,ec,area,InitialYear]*(PEM[enduse,ec,area]/
      PEE[enduse,tech,ec,area,InitialYear]-1)^
      (1/PCTC[enduse,tech,ec,area,InitialYear]))
  end

  #
  # Normal Process Capital Cost
  # For Process Heat Only
  #
  for enduse in Enduses
    if (Enduse[enduse] == "Heat") || (Enduse[enduse] == "Ground") || (Enduse[enduse] == "Air/Water") || (Enduse[enduse] == "Carriage")
      for area in areas, tech in Techs
    # 
    # Take the absolute value of result to match Promula when PEE/PCTC are zero. See 11/14/24 e-mail - Ian
    #
      @finite_math PCCN[enduse,tech,ec,area] = 
        abs(xPCC[enduse,tech,ec,area,InitialYear]/(PEM[enduse,ec,area] /
            PEE[enduse,tech,ec,area,InitialYear]-1)^
            (1/PCTC[enduse,tech,ec,area,InitialYear]))     
      end
    else
      for area in areas, tech in Techs
        PCCN[enduse,tech,ec,area] = 0
        PCTC[enduse,tech,ec,area,InitialYear] = 0
        PFTC[enduse,tech,ec,area,InitialYear] = 0
      end
    end
  end

  #
  # Initialize Process Capital Costs
  #
  for area in areas, tech in Techs, enduse in Enduses
    PCC[enduse,tech,ec,area,InitialYear] = xPCC[enduse,tech,ec,area,InitialYear]
  end

  #
  # Special equations use PEESw
  #
  year = InitialYear
  for area in areas, tech in Techs, enduse in Enduses
    if PEESw[enduse,tech,ec,area,year] == 10 
        
      @finite_math PCCCurve[enduse,tech,ec,area,year] = (PCCC0[enduse,tech,ec,area,year]+
        exp(((PEE[enduse,tech,ec,area,year]/
        PEECurveM[enduse,tech,ec,area,year]/1.055*1e6/Inflation1997[area]*Inflation2010[area])-
        PCCB0[enduse,tech,ec,area,year])/
        PCCA0[enduse,tech,ec,area,year]))/Inflation2010[area]*Inflation[area,year]       
        
      PCC[enduse,tech,ec,area,year]=PCCCurve[enduse,tech,ec,area,year]

    elseif PEESw[enduse,tech,ec,area,year] == 11
      @finite_math PCCCurve[enduse,tech,ec,area,year] = 
        exp(((PEE[enduse,tech,ec,area,year]/
        PEECurveM[enduse,tech,ec,area,year]/1.055*1e6/Inflation1997[area]*Inflation2010[area])-
        PCCC0[enduse,tech,ec,area,year])/
        PCCB0[enduse,tech,ec,area,year])/Inflation2010[area]*Inflation[area,year]
        
      PCC[enduse,tech,ec,area,year] = PCCCurve[enduse,tech,ec,area,year]
        
    end  
  end
end

function PEffAdjust(data,InitialYear,ec,ecc)
  (;Area,Areas) = data
  (;Enduses) = data
  (;Techs) = data
  (;Driver) = data
  (;PCCN) = data
  (;PCTC) = data
  (;PEM,PFPN,PFTC) = data
  (;POCF) = data
  (;AvPCCN,AvPCTC,AvPEM,AvPFPN,AvPOCF) = data

  @info "$SectorName Initial.jl - PEffAdjust - Process Efficiency Curve Adjustments"
  
  #
  # If the Economic Output of a sector is too small,
  # the use an average of the other Areas.
  #
  # Average Coefficients
  #
  for enduse in Enduses, tech in Techs
  
    @finite_math AvPEM[enduse,ec] = sum(PEM[enduse,ec,area]*
      Driver[ecc,area,InitialYear] for area in Areas)/
      sum(Driver[ecc,area,InitialYear] for area in Areas)
    
    @finite_math AvPOCF[enduse,tech,ec] = sum(POCF[enduse,tech,ec,area]*
      Driver[ecc,area,InitialYear] for area in Areas)/
      sum(Driver[ecc,area,InitialYear] for area in Areas)
        
    @finite_math AvPCTC[enduse,tech,ec] = 
      sum(PCTC[enduse,tech,ec,area,InitialYear]*
      Driver[ecc,area,InitialYear] for area in Areas)/
      sum(Driver[ecc,area,InitialYear] for area in Areas)
        
    @finite_math AvPFPN[enduse,tech,ec] = sum(PFPN[enduse,tech,ec,area]*
      Driver[ecc,area,InitialYear] for area in Areas)/
      sum(Driver[ecc,area,InitialYear] for area in Areas)
        
    @finite_math AvPCCN[enduse,tech,ec] = sum(PCCN[enduse,tech,ec,area]*
      Driver[ecc,area,InitialYear] for area in Areas)/
      sum(Driver[ecc,area,InitialYear] for area in Areas)
        
  end

  #
  # Frontier Mining is too small in all areas so use Light Oil Mining
  #
  #if EC[ec] == "FrontierOilMining"
  #  FrontierOilMining = ec
  #  LightOilMining = Select(EC,"LightOilMining")
  #  if !isempty(LightOilMining)
  #    for tech in Techs, enduse in Enduses
  #      AvPOCF[enduse,tech,FrontierOilMining] = AvPOCF[enduse,tech,LightOilMining]
  #      AvPCTC[enduse,tech,FrontierOilMining] = AvPCTC[enduse,tech,LightOilMining]
  #      AvPFPN[enduse,tech,FrontierOilMining] = AvPFPN[enduse,tech,LightOilMining]
  #      AvPCCN[enduse,tech,FrontierOilMining] = AvPCCN[enduse,tech,LightOilMining]
  #    end
  #  end
  #end

  #
  # Apply average coefficients to Areas with very small economic output
  #
  areas = Select(Area,!=("MX"))
  for area in areas
    if Driver[ecc,area,InitialYear] < 0.0001
      for enduse in Enduses, tech in Techs
      
        PEM[enduse,ec,area] = AvPEM[enduse,ec]
        POCF[enduse,tech,ec,area] = AvPOCF[enduse,tech,ec]
        PCTC[enduse,tech,ec,area,InitialYear] = AvPCTC[enduse,tech,ec]
          
        @finite_math PFTC[enduse,tech,ec,area,InitialYear] = 
          PCTC[enduse,tech,ec,area,InitialYear]/
          (1-PCTC[enduse,tech,ec,area,InitialYear])
          
        PFPN[enduse,tech,ec,area] = AvPFPN[enduse,tech,ec]
        PCCN[enduse,tech,ec,area] = AvPCCN[enduse,tech,ec]

      end
    end
  end
end

function PEffFuture(data,InitialYear,ec,ecc,areas)
  (;Enduses) = data
  (;Techs,Years) = data
  (;PCTC) = data
  (;PEECurveM,PFTC) = data
  (;RPCTC,RPFTC) = data


  @info "$SectorName Initial.jl - PEffFuture - Process Efficiency Curves for Future"
  
  #
  # Process Coefficients are the same for all years
  #
  for year in Years, area in areas, tech in Techs, enduse in Enduses
  
    PEECurveM[enduse,tech,ec,area,year] = PEECurveM[enduse,tech,ec,area,InitialYear]
    PCTC[enduse,tech,ec,area,year] = PCTC[enduse,tech,ec,area,InitialYear]
    PFTC[enduse,tech,ec,area,year] = PFTC[enduse,tech,ec,area,InitialYear]
    
    #
    # Process Retrofit Fuel and Capital Cost Coefficients
    #
    RPCTC[enduse,tech,ec,area,year] = PCTC[enduse,tech,ec,area,InitialYear]
    RPFTC[enduse,tech,ec,area,year] = PFTC[enduse,tech,ec,area,InitialYear]
  end

end

function PutInitial(data)
  (;db) = data
  (;PCC,PCCN,PCTC) = data
  (;PEECurve,PEECurveM) = data
  (;PEM,PFPN,PFTC,POCF,RPCTC,RPFTC) = data
  
  @info "$SectorName Initial.jl - PutInitial - Write Parameters to Database"
  
  
  WriteDisk(db,"$Outpt/PCC",PCC)
  WriteDisk(db,"$Outpt/PCCN",PCCN)
  WriteDisk(db,"$Outpt/PCTC",PCTC)
  WriteDisk(db,"$Outpt/PEECurve",PEECurve)
  WriteDisk(db,"$Outpt/PEECurveM",PEECurveM)
  WriteDisk(db,"$CalDB/PEM",PEM)
  WriteDisk(db,"$Outpt/PFPN",PFPN)
  WriteDisk(db,"$Outpt/PFTC",PFTC)
  WriteDisk(db,"$CalDB/POCF",POCF)
  WriteDisk(db,"$Outpt/RPCTC",RPCTC)
  WriteDisk(db,"$Outpt/RPFTC",RPFTC)

end


function Pollution(data)
  (;db) = data
  (;Areas) = data
  (;ECs,Enduses) = data
  (;FuelEPs,Polls) = data
  (;POCA,POCX) = data

  # @info "$SectorName Initial.jl - Pollution - Embodied Pollution in Initial"
  
  for area in Areas, poll in Polls, ec in ECs, fuelep in FuelEPs, enduse in Enduses
    POCA[enduse,fuelep,ec,poll,area,Zero] = POCX[enduse,fuelep,ec,poll,area,Zero]
  end
  WriteDisk(db,"$Outpt/POCA",POCA)
end

function Control(db)
  data = Data(; db)
  (;db) = data
  (;Areas,EC,ECC) = data
  (;ECs) = data
  (;InitialDemandYear) = data

  @info "$SectorName Initial.jl - Control - Control Procedure"

  #
  # Demand Constants
  #
  Lifetimes(data)
  IPrice(data)
  DEffCurve(data)

  #
  # We must initialize all sectors to provide values for 1985
  #
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    InitialYear = 1
    Initial(data,InitialYear,ec,ecc,Areas)
    PEffCurve(data,InitialYear,ec,ecc,Areas)
    PEffAdjust(data,InitialYear,ec,ecc)
    PEffFuture(data,InitialYear,ec,ecc,Areas)
  end

  #
  # For those sectors without data in 1985, use the InitialDemandYear
  #
  for area in Areas, ec in ECs
    ecc = Select(ECC,EC[ec])
    InitialYear = Int(InitialDemandYear[ec,area]-ITime+1)
    if InitialYear > 1
      Initial(data,InitialYear,ec,ecc,area)
      PEffCurve(data,InitialYear,ec,ecc,area)
      PEffFuture(data,InitialYear,ec,ecc,area)
    end
  end
  
  PutInitial(data)

  Pollution(data)

end

end
