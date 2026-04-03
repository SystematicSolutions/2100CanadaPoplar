#
# CData.jl
#
using EnergyModel

module CData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,xITime,HisTime,xHisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
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
  PollX::SetArray = ReadDisk(db,"MainDB/PollXKey")
  PollXDS::SetArray = ReadDisk(db,"MainDB/PollXDS")
  PollXs::Vector{Int} = collect(Select(PollX))
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduses::Vector{Int} = collect(Select(vEnduse))
  vTech::SetArray = ReadDisk(db,"MainDB/vTechKey")
  vTechs::Vector{Int} = collect(Select(vTech))

  CgDmSw::VariableArray{1} = ReadDisk(db,"$Input/CgDmSw") # [Tech] Cogeneration Depletion Multiplier Switch (1=Active)
  CgVCSw::VariableArray{1} = ReadDisk(db,"$Input/CgVCSw") # [Tech] Cogeneration Switch for Incorporating Fuel Costs in Variable Costs (1=Include)
  CnvrtEU::VariableArray{4} = ReadDisk(db,"$Input/CnvrtEU") # [Enduse,EC,Area] Conversion Switch 
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # [tv] Year for capital costs 
  DDHourly::VariableArray{4} = ReadDisk(db,"$Input/DDHourly") # [Enduse,Month,Area,Year] Hourly Degree Days (Degree Days)
  DDHourlyCoefficient::VariableArray{4} = ReadDisk(db,"$Input/DDHourlyCoefficient") # [Enduse,EC,Area,Year] Hourly Demand Degree Day Coefficient (DD/DD)
  DEPM::VariableArray{5} = ReadDisk(db,"$Input/DEPM") # [Enduse,Tech,EC,Area,Year] Device Energy Price Multiplier ($/$)
  DmdSw::VariableArray{4} = ReadDisk(db,"$Input/DmdSw") # [Tech,EC,Area,Year] DmdEnduse Switch
  DEEThermalMax::VariableArray{4} = ReadDisk(db,"$Input/DEEThermalMax") # [Enduse,Tech,EC,Area] Thermal Maximum Device Efficiency (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
  vFlMap::VariableArray{2} = ReadDisk(db,"$Input/vFlMap") # [Fuel,Tech] Maps the Fuels from vData into Techs
  vFsMap::VariableArray{2} = ReadDisk(db,"$Input/vFsMap") # [Fuel,Tech] Feedstock Map between Fuel and Tech
  DUCFSw::VariableArray{1} = ReadDisk(db,"$Input/DUCFSw") # [Enduse] Daily Use Switch for Cogeneration and Feedstock Demand
  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] Map between EC and ECC
  EEImpact::VariableArray{5} = ReadDisk(db,"$Input/EEImpact") # [Enduse,Tech,EC,Area,Year] Energy Efficiency Impact (Btu/Btu)
  EESat::VariableArray{5} = ReadDisk(db,"$Input/EESat") # [Enduse,Tech,EC,Area,Year] Energy Efficiency Saturation (Btu/Btu)
  EESw::VariableArray{1} = ReadDisk(db,"$Input/EESw") # [Year] Energy Efficiency Switch (Endogenous=1, Exogenous=0, Skip=-1)
  EEUCosts::VariableArray{5} = ReadDisk(db,"$Input/EEUCosts") # [Enduse,Tech,EC,Area,Year] Energy Efficiency Unit Costs ($/mmBtu)
  xEE::VariableArray{5} = ReadDisk(db,"$Input/xEE") # [Enduse,Tech,EC,Area,Year] Exogenous Energy Efficiency (TBtu)
  DDSmoothingTime::VariableArray{3} = ReadDisk(db,"$Input/DDSmoothingTime") # [Enduse,Area,Year] Smoothing Time for Annual Degree Days (Years)
  ECESMap::VariableArray{2} = ReadDisk(db,"$Input/ECESMap") # [EC,ES] Map between EC and ES for Prices (Map)
  ElecMap::VariableArray{1} = ReadDisk(db,"$Input/ElecMap") # [Tech] Primary Electricity Technology Map
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] NonExist = -1
  FTMap::VariableArray{2} = ReadDisk(db,"$Input/FTMap") # [Fuel,Tech] Map between Fuel and Tech
  PEPM::VariableArray{5} = ReadDisk(db,"$Input/PEPM") # [Enduse,Tech,EC,Area,Year] Process Energy Price Multiplier ($/$)
  PInvMinFrac::VariableArray{3} = ReadDisk(db,"$Input/PInvMinFrac") # [EC,Area,Year] Minimum Fraction for Process Investments ($/$)
  RetroSw::VariableArray{4} = ReadDisk(db,"$Input/RetroSw") # [Enduse,EC,Area,Year] Retrofit Selection (1=Device,2=Process,3=Both,4=Exogenous)
  RetroSwExo::VariableArray{1} = ReadDisk(db,"$Input/RetroSwExo") # [Year] Switch for Exogneous Retrofit Policy (=Method)
  STFSw::VariableArray{2} = ReadDisk(db,"$Input/STFSw") # [Fuel,Area] Short Term Forecast Switch (1=On, 0=Off)
  xProcSw::VariableArray{2} = ReadDisk(db,"$Input/xProcSw") # [PI,Year] Procedure on/off Switch
  xXProcSw::VariableArray{2} = ReadDisk(db,"$Input/xXProcSw") # [PI,Year] Procedure on/off Switch
  BAT::Float32 = ReadDisk(db,"$Input/BAT")[1] # [tv] Short Term Utilization Adjustment Time (YR)"
  BE::Float32 = ReadDisk(db,"$Input/BE")[1] # [tv]  Budget Elasticity Factor ($/$)
  BMM::VariableArray{5} = ReadDisk(db,"$Input/BMM") # [Enduse,Tech,EC,Area,Year] Budget Multiplier Adjustment (Btu/Btu)
  CgAT::VariableArray{4} = ReadDisk(db,"$Input/CgAT") # [Tech,EC,Area,Year] Cogeneration Implementation Time (Years)
  CgHRtM::VariableArray{4} = ReadDisk(db,"$Input/CgHRtM") # [Tech,EC,Area,Year] Cogeneration Thermal Efficiency (Btu/KWh)
  CgIVTC::VariableArray{1} = ReadDisk(db,"$Input/CgIVTC") # [Year] Cogen. Investment Tax Credit ($/$)
  CgLoad::VariableArray{1} = ReadDisk(db,"$Input/CgLoad") # [Tech] Cogeneration Demand Load to ECD
  CgMSMM::VariableArray{4} = ReadDisk(db,"$Input/CgMSMM") # [Tech,EC,Area,Year] Cogeneration Market Share Mult. Policy ($/$)
  CgRisk::VariableArray{1} = ReadDisk(db,"$Input/CgRisk") # [Tech] Cogeneration Risk Premium (DLESS)
  CgSCM::VariableArray{1} = ReadDisk(db,"$Input/CgSCM") # [Tech] Cogeneration Shared Cost Mult. ($/$)
  CgPL::VariableArray{3} = ReadDisk(db,"$Input/CgPL") # [Tech,EC,Area] Cogeneration Equipment Lifetime (Years)
  CgPotMult::VariableArray{4} = ReadDisk(db,"$Input/CgPotMult") # [Tech,EC,Area,Year] Cogeneration Potential Multiplier (Btu/Btu)
  CgPotSw::VariableArray{3} = ReadDisk(db,"$Input/CgPotSw") # [Tech,EC,Area] Cogeneration Potential Switch (0=Steam, 1=Electric)
  CgResI::VariableArray{2} = ReadDisk(db,"$Input/CgResI") # [Tech,Area] Cogeneration Resource Base (mmBtu)
  CgTL::VariableArray{3} = ReadDisk(db,"$Input/CgTL") # [Tech,EC,Area] Cogeneration Tax Life (Years)
  CgBL::VariableArray{3} = ReadDisk(db,"$Input/CgBL") # [Tech,EC,Area] Cogen. Equip. Book Value Lifetime (Years)
  CgCUFP::VariableArray{3} = ReadDisk(db,"$Input/CgCUFP") # [Tech,EC,Area] Cogeneration Capacity Utilization Factor used for Planning (Btu/Btu)
  CgOF::VariableArray{3} = ReadDisk(db,"$Input/CgOF") # [Tech,EC,Area] Cogeneration Operation Cost Fraction ($/Yr/$)
  xCgVF::VariableArray{2} = ReadDisk(db,"$Input/xCgVF") # [Tech,EC] Cogen. Variance Factor ($/$)
  CHRM::VariableArray{3} = ReadDisk(db,"$Input/CHRM") # [EC,Area,Year] Cooling to Heating Ratio Multplier
  CMSFSwitch::VariableArray{6} = ReadDisk(db,"$Input/CMSFSwitch") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Switch (1=Endogenous, 0=Exogenous)
  CROIN::VariableArray{5} = ReadDisk(db,"$Input/CROIN") # [Enduse,Tech,EC,Area,Year] Conservation Return on Investment ($/Yr/$)
  DActV::VariableArray{5} = ReadDisk(db,"$Input/DActV") # Activity Rate of Equipment by Vintage (1/1) [Enduse,Tech,EC,Area,Vintage]
  DCCLimit::VariableArray{5} = ReadDisk(db,"$Input/DCCLimit") # [Enduse,Tech,EC,Area,Year] Device Capital Cost Limit Multiplier ($/$)
  DEEAM::VariableArray{5} = ReadDisk(db,"$Input/DEEAM") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency Multiplier (Fraction)
  DERReduction::VariableArray{5} = ReadDisk(db,"$Input/DERReduction") # [Enduse,Tech,EC,Area,Year] Device Energy Reduction Fraction ((mmBtu/Yr)/(mmBtu/Yr))
  RDEMM::VariableArray{5} = ReadDisk(db,"$Input/RDEMM") # [Enduse,Tech,EC,Area,Year] Retrofit Max. Device Eff. Multiplier (Btu/Btu)
  xDCMM::VariableArray{5} = ReadDisk(db,"$Input/xDCMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Capital Cost Mult (Btu/Btu)
  xDEMM::VariableArray{5} = ReadDisk(db,"$Input/xDEMM") # [Enduse,Tech,EC,Area,Year] Max. Device Eff. Multiplier (Btu/Btu)
  DIVTC::VariableArray{3} = ReadDisk(db,"$Input/DIVTC") # [Tech,Area,Year] Device Investment Tax Credit ($/$)
  DPIVTC::VariableArray{1} = ReadDisk(db,"$Input/DPIVTC") # [Year] Device Policy Investment Tax Credit ($/$)
  FPCPFrac::VariableArray{4} = ReadDisk(db,"$Input/FPCPFrac") # [Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)
  FsPOCS::VariableArray{5} = ReadDisk(db,"$Input/FsPOCS") # [Fuel,EC,Poll,Area,Year] Feedstock Pollution Standards (Tonnes/TBtu)
  TAXPCT::VariableArray{2} = ReadDisk(db,"$Input/TAXPCT") # [Area,Year] Standard accounting percent of device life that is taxed.
  DRisk::VariableArray{2} = ReadDisk(db,"$Input/DRisk") # [Enduse,Tech] Device Risk Premium ($/$)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  xCgLSF::VariableArray{6} = ReadDisk(db,"$Input/xCgLSF") # [Tech,EC,Hour,Day,Month,Area] Cogeneration Load Shape (MW/MW)
  xCgLSFSold::VariableArray{5} = ReadDisk(db,"$Input/xCgLSFSold") # [EC,Hour,Day,Month,Area] Cogeneration Sold to Grid Load Shape (MW/MW)
  xLSF::VariableArray{6} = ReadDisk(db,"$Input/xLSF") # [Enduse,EC,Hour,Day,Month,Area] Load Shape Factor (MW/MW)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month 
  MMSFSwitch::VariableArray{5} = ReadDisk(db,"$Input/MMSFSwitch") # [Enduse,Tech,EC,Area,Year] Market Share Switch (1=Endogenous, 0=Exogenous)
  MSMM::VariableArray{5} = ReadDisk(db,"$Input/MSMM") # [Enduse,Tech,EC,Area,Year] Non-Price Market Share Factor Multiplier ($/$)
  xMVF::VariableArray{5} = ReadDisk(db,"$Input/xMVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PCCMM::VariableArray{5} = ReadDisk(db,"$Input/PCCMM") # [Enduse,Tech,EC,Area,Year] Process Capital Cost Maximum Mult.  ($/$)
  PCPEM::VariableArray{5} = ReadDisk(db,"$Input/PCPEM") # [Enduse,Tech,EC,Area,Year] Process Cost to Efficiency Multiplier for Efficiency Program ($/$/($/Btu/($/Btu))) 
  PDif::VariableArray{4} = ReadDisk(db,"$Input/PDif") # [Enduse,Tech,EC,Area] Difference between the initial heating process efficiency
  PEMMSw::VariableArray{2} = ReadDisk(db,"$Input/PEMMSw") # [EC,Area] Process Efficiency Update Switch (1=Yes, 0 = No)
  PEMX::VariableArray{4} = ReadDisk(db,"$Input/PEMX") # [Enduse,Tech,EC,Area] Ratio of Maximum to Average Process Efficiency ($/Btu/($/Btu))
  # TODO - PEMMYr is has a matching variable names - Jeff Amlin 3/30/35
  # PEMMYr::Float32 = ReadDisk(db,"$Input/PEMMYr")[1] # [tv] "Process Efficiency Update Year (Year)","Year")
  xPEE::VariableArray{5} = ReadDisk(db,"$Input/xPEE") # [Enduse,Tech,EC,Area,Year] Historical Process Efficiency ($/Btu)
  PERReduction::VariableArray{5} = ReadDisk(db,"$Input/PERReduction") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits Percentage ((mmBtu/Yr)/(mmBtu/Yr))
  PEStd::VariableArray{5} = ReadDisk(db,"$Input/PEStd") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standards ($/Btu)
  PEStdP::VariableArray{5} = ReadDisk(db,"$Input/PEStdP") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standards Policy ($/Btu)
  PIVTC::VariableArray{1} = ReadDisk(db,"$Input/PIVTC") # [Year] Process Investment Tax Credit ($/$)
  POCAM::VariableArray{5} = ReadDisk(db,"$Input/POCAM") # [FuelEP,EC,Poll,Area,Year] Average Pollution Coefficients Multiplier (Fraction)
  PPIVTC::VariableArray{1} = ReadDisk(db,"$Input/PPIVTC") # [Year] Process Policy Investment Tax Credit ($/$)
  PolSw::VariableArray{5} = ReadDisk(db,"$Input/PolSw") # [Tech,EC,Poll,Area,Year] Switch for Pollution Coefficients
  POCS::VariableArray{6} = ReadDisk(db,"$Input/POCS") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Standards (Tonnes/TBtu)
  ROIN::VariableArray{2} = ReadDisk(db,"$Input/ROIN") # [EC,Area] Return on Investment ($/Yr/$)
  RDCCM::VariableArray{5} = ReadDisk(db,"$Input/RDCCM") # [Enduse,Tech,EC,Area,Year] Retrofit Device Capital Cost Multiplier ($/$)
  RDVF::VariableArray{2} = ReadDisk(db,"$Input/RDVF") # [EC,Area] Device Retrofit Market Share Variance Factor (DLESS)
  RPVF::VariableArray{2} = ReadDisk(db,"$Input/RPVF") # [EC,Area] Process Retrofit Market Share Variance Factor (DLESS)
  RHCM::VariableArray{3} = ReadDisk(db,"$Input/RHCM") # [EC,Area,Year] Retrofit Hassle-Cost Multiplier ($/$)
  RPCCM::VariableArray{5} = ReadDisk(db,"$Input/RPCCM") # [Enduse,Tech,EC,Area,Year] Retrofit Process Capital Cost Multiplier ($/$)
  RPEEFr::VariableArray{5} = ReadDisk(db,"$Input/RPEEFr") # [Enduse,Tech,EC,Area,Year] Process Efficiency Fraction for Retrofits ($/Btu/($/Btu))
  RPEMM::VariableArray{5} = ReadDisk(db,"$Input/RPEMM") # Process Efficiency Max. Mult. ($/Btu/($/Btu)) [Enduse,Tech,EC,Area]
  RPMSLimit::VariableArray{3} = ReadDisk(db,"$Input/RPMSLimit") # [EC,Area,Year] Process Retrofit Market Share Limit (1/Yr)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  SqEUTechMap::VariableArray{2} = ReadDisk(db,"$Input/SqEUTechMap") # [Enduse,Tech] Sequestering Enduse Map to Tech (1=include)
  TSLoad::VariableArray{3} = ReadDisk(db,"$Input/TSLoad") # [Enduse,EC,Area] Temperature Sensitive Fraction of Load (Btu/Btu)
  TxRt::VariableArray{3} = ReadDisk(db,"$Input/TxRt") # [EC,Area,Year] Income Tax Rate on Energy Consumer ($/$)
  xRM::VariableArray{5} = ReadDisk(db,"$Input/xRM") # [FuelEP,EC,Poll,Area,Year] Exogenous Average Pollution Coefficient Reduction Multiplier (Tonnes/Tonnes)
  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  YCERSM::VariableArray{4} = ReadDisk(db,"$Input/YCERSM") # [Enduse,EC,Area,Year] CERSM Calibration Control
  YCgCUF::VariableArray{4} = ReadDisk(db,"$Input/YCgCUF") # [Tech,EC,Area,Year] Cogen. Capacity Utilization Factor ($/Yr/$/Yr)
  YCgMSM::VariableArray{4} = ReadDisk(db,"$Input/YCgMSM") # [Tech,EC,Area,Year] Cogeneration Market Share Mult. ($/$)
  YCUF::VariableArray{5} = ReadDisk(db,"$Input/YCUF") # [Enduse,Tech,EC,Area,Year] CUF Calibration Control
  YDCMM::VariableArray{4} = ReadDisk(db,"$Input/YDCMM") # [Enduse,Tech,Area,Year] DCMM Calibration Control
  YDEMM::VariableArray{4} = ReadDisk(db,"$Input/YDEMM") # [Enduse,Tech,Area,Year] DEMM Calibration Control
  YDSt::VariableArray{4} = ReadDisk(db,"$Input/YDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  YEndTime::Float32 = ReadDisk(db,"$Input/YEndTime")[1] # [tv] Last Year of Calibration (Date)
  InitialDemandYear::VariableArray{2} = ReadDisk(db,"$Input/InitialDemandYear") # [EC,Area] First Year of Calibration 
  YFsPEE::VariableArray{4} = ReadDisk(db,"$Input/YFsPEE") # [Tech,EC,Area,Year] Feedstock Process Efficiency Calibration Control
  YMMSM::VariableArray{5} = ReadDisk(db,"$Input/YMMSM") # [Enduse,Tech,EC,Area,Year] MMSM Calibration Control
  HPGeoFraction::VariableArray{3} = ReadDisk(db,"$Input/HPGeoFraction") # [EC,Area,Year] Air Source Heat Pump Fraction of Geothermal Demand (TBtu/TBtu)
  CM::VariableArray{3} = ReadDisk(db,"$Input/CM") # [FuelEP,Poll,PollX] Cross-over Reduction Multiplier (Tonnes/Tonnes)
  RCD::VariableArray{2} = ReadDisk(db,"$Input/RCD") # [EC,Poll] Reduction Capital Construction Delay (Years)
  RCPL::VariableArray{2} = ReadDisk(db,"$Input/RCPL") # [EC,Poll] Reduction Capital Pysical Life (Years)
  RCostM::VariableArray{3} = ReadDisk(db,"$Input/RCostM") # [FuelEP,Poll,Year] Reduction Cost FuelEPnology Multiplier ($/$)
  ROCF::VariableArray{4} = ReadDisk(db,"$Input/ROCF") # [FuelEP,EC,Poll,Area] Polution Reducution O&M ($/Tonne/($/Tonne))
  VRP::VariableArray{5} = ReadDisk(db,"$Input/VRP") # [FuelEP,EC,Poll,Area,Year] Voluntary Reduction Policy (Tonnes/Tonnes)
  VRRT::VariableArray{1} = ReadDisk(db,"$Input/VRRT") # [EC] Voluntary Reduction response time (Years)
  PCostM::VariableArray{5} = ReadDisk(db,"$Input/PCostM") # [FuelEP,EC,Poll,Area,Year] Permit Cost Multiplier ($/Tonne/$/Tonne)
  DEESw::VariableArray{5} = ReadDisk(db,"$Input/DEESw") # [Enduse,Tech,EC,Area,Year] Switch for Device Efficiency (Switch)
  DEEA0::VariableArray{5} = ReadDisk(db,"$Input/DEEA0") # [Enduse,Tech,EC,Area,Year] Device A0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEB0::VariableArray{5} = ReadDisk(db,"$Input/DEEB0") # [Enduse,Tech,EC,Area,Year] Device B0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEC0::VariableArray{5} = ReadDisk(db,"$Input/DEEC0") # [Enduse,Tech,EC,Area,Year] Device C0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEFloorSw::VariableArray{3} = ReadDisk(db,"$Input/DEEFloorSw") # [Area,Year] Switch to Activate Floor for Device Efficiency (1=Activate)
  DCDEM::VariableArray{5} = ReadDisk(db,"$Input/DCDEM") # [Enduse,Tech,EC,Area,Year] Device Cost to Efficiency Multiplier for Efficiency Program ($/$/(Btu/Btu))
  PEESw::VariableArray{5} = ReadDisk(db,"$Input/PEESw") # [Enduse,Tech,EC,Area,Year] Switch for Process Efficiency (Switch)
  PEEA0::VariableArray{5} = ReadDisk(db,"$Input/PEEA0") # [Enduse,Tech,EC,Area,Year] Process A0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEEB0::VariableArray{5} = ReadDisk(db,"$Input/PEEB0") # [Enduse,Tech,EC,Area,Year] Process B0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEEC0::VariableArray{5} = ReadDisk(db,"$Input/PEEC0") # [Enduse,Tech,EC,Area,Year] Process C0 Coeffcient for Efficiency Program ($/Btu/($/Btu))
  PEEFloorSw::VariableArray{3} = ReadDisk(db,"$Input/PEEFloorSw") # [EC,Area,Year] Switch to Activate Floor for Process Efficiency (1=Activate) [EC,Area]
  PrPCostSw::VariableArray{1} = ReadDisk(db,"$Input/PrPCostSw") # [Year] Pollution Cost Switch
  PrPCostAT::VariableArray{2} = ReadDisk(db,"$Input/PrPCostAT") # [EC,Area] Pollution Cost Adjustment Time (Years)
  RPEIX::VariableArray{5} = ReadDisk(db,"$Input/RPEIX") # [Enduse,Tech,EC,Area,Year] Energy Impact of Pollution Reduction Coefficient (Btu/Btu/Tonne/Tonne)
  vTechMap::VariableArray{2} = ReadDisk(db, "$Input/vTechMap") # [vTech,Tech] 'Map between Tech and vTech'
  xDUF::VariableArray{5} = ReadDisk(db, "$Input/xDUF") # [Enduse,EC,Day,Month,Area] Daily Use Factor (Therm/Therm)
  xPEMM::VariableArray{5} = ReadDisk(db,"$Input/xPEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu)) 
  YPEMM::VariableArray{5} = ReadDisk(db,"$Input/YPEMM") # [Enduse,Tech,EC,Area,Year] PEMM Calibration Control (Switch)
  xPolute::VariableArray{6} = ReadDisk(db,"$Input/xPolute") # [Enduse,FuelEP,EC,Poll,Area,Year] Exogenous Pollution Adjustment (Tonnes/Yr) 

  #
  # Scratch Variables
  # 
  SSum::VariableArray{1} = zeros(Float32,length(Enduse))
  
end

function CData_Inputs(db)
  @info "Inside CData_Inputs"
  data = Data(; db)
  (; Areas,Day,Days,EC,ECs,ECC,Enduse,Enduses,ES,Fuel,FuelEP) = data
  (; Hour,Hours,Month,Months,PI,PIs,Poll,Polls,Tech,Techs,vEnduse,vTech,Years) = data
  (; CgDmSw,CgVCSw,CurTime,DActV,DDHourly,DDHourlyCoefficient,DEPM,DmdSw) = data
  (; DEEThermalMax,xDmFrac,xFsFrac,xDCMM,xDEMM) = data
  (; vEUMap,vTechMap,vFlMap,DUCFSw,ECCMap,EEImpact,EESat,EESw,EEUCosts,xEE) = data
  (; DDSmoothingTime,ECESMap,ElecMap,FTMap,PEMMSw,PEPM,PInvMinFrac,RetroSw) = data
  (; RetroSwExo,xProcSw,xXProcSw,CnvrtEU,BAT,BE,BMM,CgAT,CgHRtM,CgIVTC) = data
  (; CgLoad,CgMSMM,CgRisk,CgSCM,CgPL,CgPotMult,CgPotSw,CgResI,CgTL) = data
  (; CgBL,CgCUFP,CgOF,xCgVF,CHRM,CMSFSwitch,CROIN,DCCLimit,DEEAM,DERReduction) = data
  (; RPEMM,RDEMM,DEEAM,DIVTC,FPCPFrac,FsPOCS,TAXPCT,xCgLSF,xCgLSFSold,xDUF,xLSF) = data
  (; xMVF,PCCMM,xPEE,xPEMM,MMSFSwitch,PEMX,PERReduction,POCAM,PolSw,POCS) = data
  (; RDCCM,ROIN,RDVF,RPVF,RHCM,RPCCM,RPEEFr,RPMSLimit,SqEUTechMap,TSLoad,TxRt) = data
  (; xRM,CalibTime,YCERSM,YCgCUF,YCgMSM,YCUF,YDCMM,YDEMM,YDSt,YEndTime) = data
  (; InitialDemandYear,YFsPEE,YMMSM,YPEMM,HPGeoFraction,ROCF,VRP,VRRT) = data
  (; CM,RCostM,RCD,RCPL,PCostM,DEEA0,PEEA0,DEEB0,PEEB0,DEEC0,PEEC0,DCDEM,PCPEM) = data
  (; DEESw,DEEFloorSw,PEEFloorSw,PEESw,PrPCostSw,PrPCostAT,RPEIX,HoursPerMonth) = data
  (; Endogenous,Exogenous,NonExist,vFsMap,SSum,MSMM,PDif) = data
  (; SecMap,xPolute) = data

  CgDmSw .= 0
  WriteDisk(db,"$Input/CgDmSw",CgDmSw)

  # 1. The values of this switch are determined by the scope of the model. 
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  CgVCSw .= 0
  techs = Select(Tech, !=("Electric"))
  for tech in techs
    CgVCSw[tech] = 1
  end
  WriteDisk(db,"$Input/CgVCSw",CgVCSw)

  CurTime = 1993-ITime+1
  WriteDisk(db,"$Input/CurTime",CurTime)

  @. DActV = 1
  WriteDisk(db,"$Input/DActV",DActV)

  @. DDHourly = 1
  @. DDHourlyCoefficient = 0
  WriteDisk(db,"$Input/DDHourly",DDHourly)
  WriteDisk(db,"$Input/DDHourlyCoefficient",DDHourlyCoefficient)

  DEPM .= 1
  WriteDisk(db,"$Input/DEPM",DEPM)

  # 1. The values of this switch are determined by the scope of the model. 
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  DmdSw .= Endogenous
  WriteDisk(db,"$Input/DmdSw",DmdSw)

  # Efficiency can not go above thermal maximum for specified technologies. 
  # and enduses - Ian 09/17/21
  #
  @. DEEThermalMax = 1e6
  WriteDisk(db,"$Input/DEEThermalMax",DEEThermalMax)

  #
  ########################
  #
  # Default Values for Fuel Splits (this is for the US demands) JSA 02/10/05
  #
  #
  fuel = Select(Fuel, "Coal")
  tech = Select(Tech, "Coal")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "NaturalGas")
  tech = Select(Tech, "Gas")
  xDmFrac[:,fuel,tech,:,:,:] .= 1

  fuel = Select(Fuel, "LFO")
  tech = Select(Tech, "Oil")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "Electric")
  tech = Select(Tech, "Electric")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "Biomass")
  tech = Select(Tech, "Biomass")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "LPG")
  tech = Select(Tech, "LPG")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "Solar")
  tech = Select(Tech, "Solar")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "Steam")
  tech = Select(Tech, "Steam")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "Geothermal")
  tech = Select(Tech, "Geothermal")
  xDmFrac[:,fuel,tech,:,:,:] .= 1
  #
  fuel = Select(Fuel, "Hydrogen")
  tech = Select(Tech, "FuelCell")
  xDmFrac[:,fuel,tech,:,:,:] .= 1

  #
  # Use Primary Heat to set values for FsFrac for now - Ian 05/18/2012
  #
  eu = Select(Enduse, "Heat")
  xFsFrac[:,:,:,:,:] .= xDmFrac[eu,:,:,:,:,:]
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
  WriteDisk(db,"$Input/xFsFrac",xFsFrac)

  #
  ########################
  #
  # vEUMap[venduse,enduse] - Map between Enduse and vEnduse
  #
  @. vEUMap = 0.0

  enduse = Select(Enduse, "Heat")
  venduse = 1
  vEUMap[venduse,enduse] = 1.0

  enduse = Select(Enduse, "HW")
  venduse = Select(vEnduse, "HW")
  vEUMap[venduse,enduse] = 1.0

  enduse = Select(Enduse, "OthSub")
  venduse = Select(vEnduse, "OthSub")
  vEUMap[venduse,enduse] = 1.0

  enduse = Select(Enduse, "Refrig")
  venduse = Select(vEnduse, "Refrig")
  vEUMap[venduse,enduse] = 1.0

  enduse = Select(Enduse, "Light")
  venduse = Select(vEnduse, "Light")
  vEUMap[venduse,enduse] = 1.0

  enduse = Select(Enduse, "AC")
  venduse = Select(vEnduse, "AC")
  vEUMap[venduse,enduse] = 1.0

  enduse = Select(Enduse, "OthNSub")
  venduse = Select(vEnduse, "OthNSub")
  vEUMap[venduse,enduse] = 1.0

  WriteDisk(db,"$Input/vEUMap",vEUMap)

  #
  ########################
  #
  # vTechMap[vtech,tech] Map between Tech and vTech
  #
  @. vTechMap = 0.0

  tech = Select(Tech, "Electric")
  vtech = Select(vTech, "Electric")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "Gas")
  vtech = Select(vTech, "Gas")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "Coal")
  vtech = Select(vTech, "Coal")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "Oil")
  vtech = Select(vTech, "Oil")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "Biomass")
  vtech = Select(vTech, "Biomass")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "Solar")
  vtech = Select(vTech, "Solar")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "LPG")
  vtech = Select(vTech, "LPG")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "Steam")
  vtech = Select(vTech, "Steam")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "Geothermal")
  vtech = Select(vTech, "Geothermal")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "HeatPump")
  vtech = Select(vTech, "HeatPump")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "DualHPump")
  vtech = Select(vTech, "DualHPump")
  vTechMap[vtech,tech] = 1.0

  tech = Select(Tech, "FuelCell")
  vtech = Select(vTech, "FuelCell")
  vTechMap[vtech,tech] = 1.0

  # tech = Select(Tech, "OffRoad")
  # vtech = Select(vTech, "OffRoad")
  # vTechMap[vtech,tech] = 1.0

  WriteDisk(db,"$Input/vTechMap",vTechMap)

  #
  ########################
  #
  # vFlMap[fuel,tech] Maps the Fuels from vData into Techs
  #
  @. vFlMap = 0.0

  tech = Select(Tech, "Electric")
  fuels = Select(Fuel, ["Electric","Hydro","Wind"])
  for fuel in fuels
    vFlMap[fuel,tech] = 1.0
  end
  
  tech = Select(Tech, "Gas")
  fuels = Select(Fuel, ["Biogas","CokeOvenGas","NaturalGas","NaturalGasRaw","RNG","StillGas"])
  for fuel in fuels   
    vFlMap[fuel,tech] = 1.0
  end
  
  tech = Select(Tech, "Coal")
  fuels = Select(Fuel, ["Coal","Coke","PetroCoke"])
  for fuel in fuels   
    vFlMap[fuel,tech] = 1.0
  end

  tech = Select(Tech, "Oil")
  fuels = Select(Fuel, ["Asphaltines","AviationGasoline","Biodiesel","Biojet",
      "Diesel","Ethanol","Gasoline","HFO","JetFuel","Kerosene","LFO","Lubricants",
      "Naphtha","NonEnergy","PetroFeed"])
  for fuel in fuels   
    vFlMap[fuel,tech] = 1.0
  end

  tech = Select(Tech, "Biomass")
  fuels = Select(Fuel, ["Biomass","Waste"])
  for fuel in fuels   
    vFlMap[fuel,tech] = 1.0
  end

  tech = Select(Tech, "Solar")
  fuel = Select(Fuel, "Solar")
  vFlMap[fuel,tech] = 1.0

  tech = Select(Tech, "LPG")
  fuels = Select(Fuel, "LPG")
  for fuel in fuels   
    vFlMap[fuel,tech] = 1.0
  end

  tech = Select(Tech, "Steam")
  fuel = Select(Fuel, "Steam")
  vFlMap[fuel,tech] = 1.0

  tech = Select(Tech, "Geothermal")
  fuel = Select(Fuel, "Geothermal")
  vFlMap[fuel,tech] = 1.0

  tech = Select(Tech, "FuelCell")
  fuels = Select(Fuel, ["Ammonia","Hydrogen"])
  for fuel in fuels   
    vFlMap[fuel,tech] = 1.0
  end

  WriteDisk(db,"$Input/vFlMap",vFlMap)

  #
  ########################
  #
  # vFsMap[fuel,tech] Feedstock Map between Fuel and Tech
  #
  @. vFsMap = 0.0

  tech = Select(Tech, "Electric")
  fuel = Select(Fuel, "Electric")
  vFsMap[fuel,tech] = 1.0

  tech = Select(Tech, "Gas")
  fuels = Select(Fuel, ["Biogas","CokeOvenGas","NaturalGas","NaturalGasRaw","RNG","StillGas"])
  for fuel in fuels   
    vFsMap[fuel,tech] = 1.0
  end  

  tech = Select(Tech, "Coal")
  fuels = Select(Fuel, ["Coal","Coke","PetroCoke"])
  for fuel in fuels   
    vFsMap[fuel,tech] = 1.0
  end  

  tech = Select(Tech, "Oil")
  fuels = Select(Fuel, ["Asphaltines","AviationGasoline","Biodiesel","Biojet",
      "Diesel","Ethanol","Gasoline","HFO","JetFuel","Kerosene","LFO","Lubricants",
      "Naphtha","NonEnergy","PetroFeed"])
  for fuel in fuels   
    vFsMap[fuel,tech] = 1.0
  end  

  tech = Select(Tech, "Biomass")
  fuels = Select(Fuel, ["Biomass","Waste"])
  for fuel in fuels   
    vFsMap[fuel,tech] = 1.0
  end  

  tech = Select(Tech, "Solar")
  fuel = Select(Fuel, "Solar")
  vFsMap[fuel,tech] = 1.0

  tech = Select(Tech, "LPG")
  fuels = Select(Fuel, "LPG")
  for fuel in fuels   
    vFsMap[fuel,tech] = 1.0
  end  
  
  tech = Select(Tech, "Steam")
  fuel = Select(Fuel, "Steam")
  vFsMap[fuel,tech] = 1.0

  tech = Select(Tech, "Geothermal")
  fuel = Select(Fuel, "Geothermal")
  vFsMap[fuel,tech] = 1.0

  tech = Select(Tech, "FuelCell")
  fuels = Select(Fuel, ["Ammonia","Hydrogen"])
  for fuel in fuels   
    vFsMap[fuel,tech] = 1.0
  end  

  WriteDisk(db,"$Input/vFsMap",vFsMap)

  #
  ########################
  #
  # DUCFSw[enduse] Daily Use Switch for Cogeneration and Feedstock Demand
  #
  # 1. This switch tells the model where to include cogeneration and feedstock
  #   demands in the gas daily use curve.  We are including them in the
  #   primary heat enduse.  One means the include them, zero to exclude.
  #   Source: Cogeneration and feedstocks are primary heat demands.
  #   This was determined from the data.
  # 2. Heat is set to one, all other enduses are set to zero.
  # 3. P. Cross 10/24/95.
  #
  @. DUCFSw = 0.0
  enduse=Select(Enduse,"Heat")
  DUCFSw[enduse]=1
  WriteDisk(db,"$Input/DUCFSw",DUCFSw)

  #
  ########################
  #
  # ECCMap[EC,ECC] Map between EC and ECC
  #
  # 1. The values of this map are determined by the scope of the model. 
  # 2. The data is read in.
  # 3. P. Cross 10/23/95.
  #
  @. ECCMap = 0
  eccs=Select(ECC, (from = "Wholesale", to = "StreetLighting"))
  for ecc in eccs, ec in ECs
    if ECC[ecc] == EC[ec]
      ECCMap[ec,ecc]=1
    end
  end
  WriteDisk(db,"$Input/ECCMap",ECCMap)

  #
  ########################
  #
  # EEImpact[Enduse,Tech,EC,Area,Year] Energy Efficiency Impact (Btu/Btu)
  #
  @. EEImpact=0.0
  WriteDisk(db,"$Input/EEImpact",EEImpact)

  #
  ########################
  #
  # EESat[Enduse,Tech,EC,Area,Year] Energy Efficiency Saturation (Btu/Btu)
  #
  @. EESat=0.0
  WriteDisk(db,"$Input/EESat",EESat)

  #
  ########################
  #
  # EESw[Year] Energy Efficiency Switch (Endogenous=1, Exogenous=0, Skip=-1)
  #
  @. EESw=0.0
  WriteDisk(db,"$Input/EESw",EESw)

  #
  ########################
  #
  # EEUCosts[Enduse,Tech,EC,Area,Year] Energy Efficiency Unit Costs ($/mmBtu)
  #
  @. EEUCosts=0.0
  WriteDisk(db,"$Input/EEUCosts",EEUCosts)

  #
  ########################
  #
  # xEE[Enduse,Tech,EC,Area,Year] Exogenous Energy Efficiency (TBtu)
  #
  @. xEE=0.0
  WriteDisk(db,"$Input/xEE",xEE)

  #
  ########################
  #
  # DDSmoothingTime[Enduse,Area,Year] Smoothing Time for Annual Degree Days (Years)
  #
  @. DDSmoothingTime=10.0
  WriteDisk(db,"$Input/DDSmoothingTime",DDSmoothingTime)

  #
  ########################
  #
  # ECESMap[EC,ES] Map between EC and ES for Prices (Map)
  #
  @. ECESMap=0.0
  es=Select(ES,"Commercial")
  ECESMap[:,es] .= 1

  ecs = Select(EC,["NGDistribution","OilPipeline","NGPipeline"])
  for ec in ecs
    ECESMap[ec,es] = 0
  end
  es=Select(ES,"Industrial")
  for ec in ecs
    ECESMap[ec,es] = 1
  end
  WriteDisk(db,"$Input/ECESMap",ECESMap)

  #
  ########################
  #
  # ElecMap[tech] Primary Electricity Technology Map
  #
  # ElecMap maps to all the Techs which use electricity Jeff Amlin 5/9/16
  #
  @. ElecMap=0.0
  techs=Select(Tech,["Electric","Geothermal","HeatPump","DualHPump","Solar"])
  ElecMap[techs] .= 1.0
  WriteDisk(db,"$Input/ElecMap",ElecMap)

  #
  ########################
  #
  # FTMap[Fuel,Tech] Map between Fuel and Tech
  #
  # Ethanol assigned to Oil by Jeff Amlin 1/27/11
  # Landfill Gases/Waste assigned to Biomass by Jeff Amlin 1/27/11
  # Still Gas assigned to Gas from Robin White by Jeff Amlin 1/30/17
  #
  tech = Select(Tech,"Electric")
  fuel = Select(Fuel,"Electric")
  FTMap[fuel,tech] = 1.0

  tech = Select(Tech,"Gas")
  fuels = Select(Fuel,["Biogas","CokeOvenGas","NaturalGas","NaturalGasRaw","RNG","StillGas"])
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  tech = Select(Tech,"Coal")
  fuels = Select(Fuel,["Coal","Coke","PetroCoke"])
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  tech = Select(Tech,"Oil")
  fuels = Select(Fuel,["Asphalt","Asphaltines","AviationGasoline","Biodiesel","Biojet",
      "Diesel","Ethanol","Gasoline","HFO","JetFuel","Kerosene","LFO","Lubricants",
      "Naphtha","NonEnergy","PetroFeed"])
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  tech = Select(Tech,"Biomass")
  fuels = Select(Fuel,["Biomass","Waste"])
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  tech = Select(Tech,"Solar")
  fuels = Select(Fuel,["Electric","Solar"])
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  tech = Select(Tech,"LPG")
  fuels = Select(Fuel,"LPG")
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  tech = Select(Tech,"Steam")
  fuel = Select(Fuel,"Steam")
  FTMap[fuel,tech] = 1.0

  tech = Select(Tech,"Geothermal")
  fuels = Select(Fuel,["Electric","Geothermal"])
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  tech = Select(Tech,"HeatPump")
  fuel = Select(Fuel,"Electric")
  FTMap[fuel,tech] = 1.0

  tech = Select(Tech,"DualHPump")
  fuel = Select(Fuel,"Electric")
  FTMap[fuel,tech] = 1.0

  tech = Select(Tech,"FuelCell")
  fuels = Select(Fuel,["Ammonia","Hydrogen"])
  for fuel in fuels
    FTMap[fuel,tech] = 1.0
  end

  WriteDisk(db,"$Input/FTMap",FTMap)

  #
  ########################
  #
  # PEMMSw[EC,Area] Process Efficiency Update Switch (1=Yes, 0=No)
  #
  # Calibrate with a single pass (PEMMSw=0) through the demand sector.
  #
  @. PEMMSw=0.0
  WriteDisk(db,"$Input/PEMMSw",PEMMSw)

  #
  # ********************
  #
  # TODO - PEMMYr is has a matching variable names - Jeff Amlin 3/30/35
  # PEMMYr = xHisTime-Zero+1
  # WriteDisk(db,"$Input/PEMMYr",PEMMYr)

  #
  ########################
  #
  # PEPM[Enduse,Tech,EC,Area,Year] Process Energy Price Multiplier ($/$)
  #
  @. PEPM=1
  WriteDisk(db,"$Input/PEPM",PEPM)

  #
  ########################
  #
  # PInvMinFrac[EC,Area,Year] Minimum Fraction for Process Investments ($/$)
  #
  @. PInvMinFrac=0.002
  WriteDisk(db,"$Input/PInvMinFrac",PInvMinFrac)

  #
  ########################
  #
  # RetroSw[Enduse,EC,Area,Year] Retrofit Selection (1=Device,2=Process,3=Both,4=Exogenous)
  #
  @. RetroSw=-99
  WriteDisk(db,"$Input/RetroSw",RetroSw)

  #
  ########################
  #
  # RetroSwExo[Year] Switch for Exogneous Retrofit Policy (=Method)
  #
  @. RetroSwExo=-99
  WriteDisk(db,"$Input/RetroSwExo",RetroSwExo)

  #
  ########################
  #
  # STFSw[Fuel,Area] Short Term Forecast Switch (1=On, 0=Off)
  #
  # 1. The values of this variable are zero and are commented out to save 
  #    execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # Note - Commented out in Promula
  # @. STFSw=0
  # WriteDisk(db,"$Input/STFSw",STFSw)
  #

  #
  ########################
  #
  # xProcSw[PI,Year] Procedure on/off Switch
  # xXProcSw[PI,Year] Procedure on/off Switch
  #
  # 1. The values of this switch are determined by the scope of the model. 
  # 2. The values are assigned with an equation.  Each procedure is given 
  #    its value directly.
  # 3. J. Amlin 7/15/94
  xProcSw[Select(PI,"TPrice"),Zero]=Endogenous
  xProcSw[Select(PI,"DMarginal"),Zero]=Endogenous
  xProcSw[Select(PI,"DDSM"),Zero]=NonExist
  xProcSw[Select(PI,"CMarginal"),Zero]=Endogenous
  xProcSw[Select(PI,"CDSM"),Zero]=NonExist
  xProcSw[Select(PI,"CImpact"),Zero]=NonExist
  xProcSw[Select(PI,"MShare"),Zero]=Endogenous
  xProcSw[Select(PI,"FuelSystem"),Zero]=NonExist
  xProcSw[Select(PI,"MStock"),Zero]=Endogenous
  xProcSw[Select(PI,"Conversion"),Zero]=NonExist
  xProcSw[Select(PI,"PRetrofit"),Zero]=NonExist
  xProcSw[Select(PI,"DRetrofit"),Zero]=NonExist
  xProcSw[Select(PI,"TStock"),Zero]=Endogenous
  xProcSw[Select(PI,"Utilize"),Zero]=NonExist
  xProcSw[Select(PI,"DmdEnduse"),Zero]=Endogenous
  xProcSw[Select(PI,"Fungible"),Zero]=Endogenous
  xProcSw[Select(PI,"Cogeneration"),Zero]=Endogenous
  xProcSw[Select(PI,"CogFungible"),Zero]=NonExist
  xProcSw[Select(PI,"TotalDemand"),Zero]=Endogenous
  xProcSw[Select(PI,"Pollution"),Zero]=Endogenous
  xProcSw[Select(PI,"DSMPost"),Zero]=Endogenous
  xProcSw[Select(PI,"ETOU"),Zero]=Exogenous
  xProcSw[Select(PI,"LoadMgmt"),Zero]=Exogenous
  xProcSw[Select(PI,"Loadcurve"),Zero]=Endogenous
  xProcSw[Select(PI,"DailyUse"),Zero]=NonExist
  for year in Years, p in PIs
    xProcSw[p,year]=xProcSw[p,Zero]
  end
  @. xXProcSw=xProcSw
  WriteDisk(db,"$Input/xProcSw",xProcSw)
  WriteDisk(db,"$Input/xXProcSw",xXProcSw)

  #
  ########################
  #
  # CnvrtEU[Enduse,EC,Area,Year] Conversion Switch
  #
  for year in Years, area in Areas, ec in ECs, enduse in Enduses
    CnvrtEU[enduse,ec,area,year]=NonExist
  end
  WriteDisk(db,"$Input/CnvrtEU",CnvrtEU)

  #
  ########################
  #
  # DATA VALUES
  #
  ########################
  #
  # BAT[tv] Short Term Utilization Adjustment Time (Yr)
  #
  # 1. Source:  Demand81, regression based on oil price shocks, GAB
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  BAT = 1
  WriteDisk(db,"$Input/BAT",BAT)

  #
  ########################
  #
  # BE[tv] Budget Elasticity Factor ($/$)
  #
  # 1. Source:  Demand81, regression based on oil price shocks, GAB
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # BE = -0.25
  BE = 0
  WriteDisk(db,"$Input/BE",BE)

  #
  ########################
  #
  # BMM[Enduse,Tech,EC,Area,Year] Budget Multiplier Adjustment (Btu/Btu)
  #
  # 1. The value of this variable is determined by the scope of the model.
  # 2. The values are assigned with an equation.  The default value is 1.0.
  # 3. J. Amlin 7/15/94
  #
  @. BMM=1
  WriteDisk(db,"$Input/BMM",BMM)

  #
  ########################
  #
  # CgAT[Tech,EC,Area,Year] Cogeneration Implementation Time (Years)
  #
  # This should generally match the construction time of the unit being built
  # Jeff Amlin 04/28/23
  #
  @. CgAT=2.0
  WriteDisk(db,"$Input/CgAT",CgAT)

  #
  ########################
  #
  # CgHRtM[Tech,EC,Area,Year] Cogeneration Thermal Efficiency (Btu/KWh)
  #
  # This is an engineering value (10,500). 
  #
  @. CgHRtM=10500
  #
  # Biomass Heat Rate
  #
  # "The electricity-to-heat production ratio for a conventional back-pressure
  # steam turbine cogeneration system ranges from 40-60 kWh/GJ (42-63 kWh/MBTU),"
  # which is relatively well-matched to the steam and electricity needs at older
  # kraft mills. With this technology, existing mills may not have an incentive 
  # to reduce steam use because the cogeneration system may not be able to provide
  # the new steam-to-electricity demand ratio and additional electricity purchases
  # may be required. However, rising electricity-to-heat demand ratios (due to
  # increased electricity loads in mills) are motivating interest in alternative
  # cogeneration technologies. Electricity-to-heat ratios from steam turbine systems
  # can be increased to 60-80 kWh/GJ (63-84 kWh/MBtu) by increasing boiler pressures
  # and temperatures."
  # "Energy Efficiency and the Pulp and Paper Industry" by Lars J. Nilsson, 
  # Eric D. Larson, Kenneth Gilbreath, and Ashok Gupta, 100 pp., ACEEE 1996, IE962
  # American Council for an Energy-Efficient Economy (ACEEE) 
  # http://www.aceee.org/pubs/ie962.htm
  #
  # See also http://www.cariboo.bc.ca/news/Past02Feb25/storiesfeb25/biomass2.html
  #
  # Biomass use mid-range quote from ACEEE article of 63 kwh/MBtu
  # 15873=1000000/63
  #
  tech=Select(Tech,"Biomass")
  CgHRtM[tech,:,:,:] .= 15873

  #
  # Solar fuel usage is only the electricity needed to monitor, 
  # control, or back-up the system, therefore we assume a very 
  # low heat rate. Jeff Amlin 5/20/13.
  # Setting Solar Heatrate to 3412 for the KWh to TBtu conversion. Per Jeff, 5/25/21
  #
  tech=Select(Tech,"Solar")
  CgHRtM[tech,:,:,:] .= 3412

  #
  # Cogeneration heat rate for oil and gas (AB) from Rajean and Glasha
  #
  techs=Select(Tech,["Gas","LPG","Oil"])
  CgHRtM[tech,:,:,:] .= 8550

  WriteDisk(db,"$Input/CgHRtM",CgHRtM)

  #
  ########################
  #
  # CgIVTC[Year] Cogen. Investment Tax Credit ($/$)
  #
  # 1. The federal investment tax credit was ended in 1986.  DRI, Table 7.
  # 2. The proper years are selected and CgIVTC is given a value of
  #   seven percent.
  # 3. P. Cross 6/13/94
  #
  # TODOLater This seems like a very outdated variable. LJD, 25/03/05
  #
  @. CgIVTC=0
  CgIVTC[Yr(1985)] = 0.097
  WriteDisk(db,"$Input/CgIVTC",CgIVTC)

  #
  ########################
  #
  # CgLoad[Tech] Cogeneration Demand Load to ECD
  #
  # 1. The value of the variable is determined by the scope of the model.
  # 2. The values are assigned with an equation.
  # 3. P. Cross 10/23/95.
  #
  @. CgLoad=1
  tech=Select(Tech,"Electric")
  CgLoad[tech]=0
  WriteDisk(db,"$Input/CgLoad",CgLoad)

  #
  ########################
  #
  # CgLoad[Tech,EC,Area,Year] Cogeneration Market Share Mult. Policy ($/$)
  #
  # 1. This is a policy variable.  The default value is 1.0.
  # 2. The data is input through an equation.
  # 3. P. Cross 7/18/94
  #
  @. CgMSMM=1
  WriteDisk(db,"$Input/CgMSMM",CgMSMM)

  #
  ########################
  #
  # CgRisk[Tech] Cogeneration Risk Premium (DLESS)
  #
  # 1. This is a policy variable.  The default value is 0.05.
  # 2. The data is input through an equation.
  # 3. P. Cross 7/18/94
  #
  @. CgRisk=0.05
  WriteDisk(db,"$Input/CgRisk",CgRisk)

  #
  ########################
  #
  # CgSCM[Tech] Cogeneration Shared Cost Mult. ($/$)
  #
  @. CgSCM=0.30
  tech=Select(Tech,"Solar")
  CgSCM[tech]=1.00
  WriteDisk(db,"$Input/CgSCM",CgSCM)

  #
  ########################
  #
  # CgPL[Tech,EC,Area] Cogeneration Equipment Lifetime (Years)
  #
  @. CgPL=25.0
  WriteDisk(db,"$Input/CgPL",CgPL)

  #
  ########################
  #
  # CgPotMult[Tech,EC,Area,Year] Cogeneration Potential Multiplier (Btu/Btu)
  #
  @. CgPotMult=1.0
  WriteDisk(db,"$Input/CgPotMult",CgPotMult)

  #
  ########################
  #
  # CgPotSw[Tech,EC,Area] Cogeneration Potential Switch (0=Steam, 1=Electric)
  #
  @. CgPotSw=1.0
  WriteDisk(db,"$Input/CgPotSw",CgPotSw)

  #
  ########################
  #
  # CgResI[Tech,Area] Cogeneration Resource Base (mmBtu)
  #
  @. CgResI=0.0
  WriteDisk(db,"$Input/CgResI",CgResI)

  #
  ########################
  #
  # CgTL[Tech,EC,Area] Cogeneration Tax Life (Years)
  #
  # 1. Standard accounting practice specifies the tax life to be approximately
  #    80 percent of the physical lifetime.
  # 2. The values are assigned with an equation.  The cogeneration tax 
  #    life is equal to .80 (80 percent) times the cogeneration physical 
  #    lifetime (CgPL).
  # 3. D. Boylan, 11/29/94
  #
  @. CgTL=CgPL*0.80
  WriteDisk(db,"$Input/CgTL",CgTL)

  #
  ########################
  #
  # CgBL[Tech,EC,Area] Cogen. Equip. Book Value Lifetime (Years)
  #
  # 1. This is the book value plant life time of cogenerator from George Backus
  #   developed data.
  # 2. The values are assigned with an equation.
  # 3. P. Cross 7/18/94
  #
  @. CgBL=15
  WriteDisk(db,"$Input/CgBL",CgBL)

  #
  ########################
  #
  # CgCUFP[Tech,EC,Area] Cogeneration Capacity Utilization Factor used for Planning (Btu/Btu)
  #
  # Commercial Cogen Capacity Factors from Canada
  #
  @. CgCUFP=0
  
  ecs = Select(EC, !=("Health"))
  for ec in ecs
    CgCUFP[:,ec,:] .= 0.427
  end
  
  ecs = Select(EC, "Health")
  for ec in ecs
    CgCUFP[:,ec,:] .= 0.366
  end
  WriteDisk(db,"$Input/CgCUFP",CgCUFP)

  #
  ########################
  #
  # CgOF[Tech,EC,Area] Cogeneration Capacity Utilization Factor used for Planning (Btu/Btu)
  #
  @. CgOF = 0.05
  WriteDisk(db,"$Input/CgOF",CgOF)

  #
  ########################
  #
  # xCgVF[Tech,EC] Cogen. Variance Factor ($/$)
  #
  # This is the standard variance factor for the industrial sector based
  # on EIA AEO modeling circa ARC 80.  J. Amlin 09/21/09
  #
  @. xCgVF = -2.5
  @. xCgVF = 0
  WriteDisk(db,"$Input/xCgVF",xCgVF)

  #
  ########################
  #
  # CHRM[EC,Area,Year] Cooling to Heating Ratio Multplier
  #
  # 1. This is a policy variable.  The default value is 1.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  @. CHRM = 1.0
  WriteDisk(db,"$Input/CHRM",CHRM)
  #
  ########################
  #
  # CMSFSwitch[Enduse,Tech,CTech,EC,Area,Year]  'Conversion Market Share Switch (1=Endogenous, 0=Exogenous)'
  #
  @. CMSFSwitch=1.0
  WriteDisk(db,"$Input/CMSFSwitch",CMSFSwitch)

  #
  ########################
  #
  # CROIN[Enduse,Tech,EC,Area,Year] Conservation Return on Investment ($/Yr/$)
  #
  # 1. The values of this policy variable are zero until a policy is 
  #    activated and are commented out to save execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  @. CROIN=0
  WriteDisk(db,"$Input/CROIN",CROIN)

  #
  ########################
  #
  # Device Capital Cost Limit as a Multiplier
  #
  # DCCLimit[Enduse,Tech,EC,Area,Year] Device Capital Cost Limit Multiplier ($/$)
  #
  # DCCLimit=2
  @. DCCLimit=10
  # DCCLimit=1000
  WriteDisk(db,"$Input/DCCLimit",DCCLimit)

  #
  ########################
  #
  # DEEAM[Enduse,Tech,EC,Area,Year] Average Device Efficiency Multiplier (Fraction)
  #
  # 1. The default value of this policy variable is 1.
  # 2. The values are assigned with an equation.
  # 3. P. Cross 7/9/99
  #
  @. DEEAM=1
  WriteDisk(db,"$Input/DEEAM",DEEAM)

  #
  ########################
  #
  # DERReduction[Enduse,Tech,EC,Area,Year] Device Energy Reduction Fraction ((mmBtu/Yr)/(mmBtu/Yr))
  #
  # Default value is 0.0 
  #
  @. DERReduction=0.0
  WriteDisk(db,"$Input/DERReduction",DERReduction)

  #
  ########################
  #
  # RPEMM[Enduse,Tech,EC,Area,Year] Retrofit Max. Device Eff. Multiplier (Btu/Btu)
  # RDEMM[Enduse,Tech,EC,Area,Year] Retrofit Max. Device Eff. Multiplier (Btu/Btu)
  # xDEMM[Enduse,Tech,EC,Area,Year] Max. Device Eff. Multiplier (Btu/Btu)
  #
  # The default value of this policy variable is 1.
  #
  @. RPEMM=1
  @. RDEMM=1
  @. xDEMM=1
  @. xDCMM=1
  WriteDisk(db,"$Input/RPEMM",RPEMM)
  WriteDisk(db,"$Input/RDEMM",RDEMM)
  WriteDisk(db,"$Input/xDEMM",xDEMM)
  WriteDisk(db,"$Input/xDCMM",xDCMM)

  #
  ########################
  #
  # DIVTC[Tech,Area,Year] Device Investment Tax Credit ($/$)
  #
  @. DIVTC=0.0
  WriteDisk(db,"$Input/DIVTC",DIVTC)

  #
  ########################
  #
  # DPIVTC[Year] Device Policy Investment Tax Credit ($/$)
  # 
  # 1. The values of this policy variable are zero and are commented out 
  #    to save execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # @. DPIVTC=0.0
  # WriteDisk(db,"$Input/DPIVTC",DPIVTC)

  #
  ########################
  #
  # FPCPFrac[Fuel,EC,Area,Year] Portion of Carbon Price which impacts Fungible Fuel Fraction ($/$)
  # 
  @. FPCPFrac=1.0
  WriteDisk(db,"$Input/FPCPFrac",FPCPFrac)
    
  #
  ########################
  #
  # FsPOCS(Fuel,EC,Poll,Area,Year)    'Feedstock Pollution Standards (Tonnes/TBtu)',
  # Type=Real(9,2), Disk(Input,FsPOCS(Fuel,EC,Poll,Area,Year))
  #
  @. FsPOCS=1E12
  WriteDisk(db,"$Input/FsPOCS",FsPOCS)

  #
  ########################
  #
  # TAXPCT[Area,Year] Standard accounting percent of device life that is taxed.
  #
  # 1. Standard accounting practices.
  # 2. The data is input through an equation. 
  # 3. P. Cross 7/18/94
  #
  @. TAXPCT=0.8
  WriteDisk(db,"$Input/TAXPCT",TAXPCT)

  #
  ########################
  #
  # DRisk[Enduse,Tech] Device Risk Premium ($/$)
  #
  # 1. The values of this policy variable are zero and are commented out 
  #    to save execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # @. DRisk=0.0
  # WriteDisk(db,"$Input/DRisk",DRisk)

  #
  ########################
  #
  # xDSt[Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  #
  # Note - Commented out in Promula
  # @. xDSt=1.0
  # WriteDisk(db,"$Input/xDSt",xDSt)

  #
  ########################
  #
  # xCgLSF[Tech,EC,Hour,Day,Month,Area] Cogeneration Load Shape (MW/MW)
  # xCgLSFSold[EC,Hour,Day,Month,Area] Cogeneration Sold to Grid Load Shape (MW/MW)
  # xLSF[Enduse,EC,Hour,Day,Month,Area] Load Shape Factor (MW/MW)
  # xDUF[Enduse,EC,Day,Month,Area] Natural Gas Daily Use Factor (Therm/Therm)
  #
  # 1. The source is the NEPOOL electric load shapes, NEPOOL July 1995.
  # 2. The data is read in directly. The average is normalized
  #    so that the sum over all seasons is equal to 1.0.  The average load
  #    values (xLSF) are mutiplied times the hours per season (ND) and summed
  #    across all seasons.  This value (SSum) is used to adjust xLSF.
  # 3. J. Amlin 6/13/94
  #
  Summer=Select(Month,"Summer")
  Winter=Select(Month,"Winter")
  
  #                               Peak  Ave   Min
  enduse=Select(Enduse,"Heat")
  xLSF[enduse,1,1,Days,Summer,1]=[1.634 1.020 0.489]
  xLSF[enduse,1,1,Days,Winter,1]=[1.522 0.980 0.502]

  enduse=Select(Enduse,"HW")
  xLSF[enduse,1,1,Days,Summer,1]=[1.634 1.020 0.489]
  xLSF[enduse,1,1,Days,Winter,1]=[1.522 0.980 0.502]

  enduse=Select(Enduse,"OthSub")
  xLSF[enduse,1,1,Days,Summer,1]=[1.634 1.020 0.489]
  xLSF[enduse,1,1,Days,Winter,1]=[1.522 0.980 0.502]

  enduse=Select(Enduse,"Refrig")
  xLSF[enduse,1,1,Days,Summer,1]=[1.634 1.020 0.489]
  xLSF[enduse,1,1,Days,Winter,1]=[1.522 0.980 0.502]

  enduse=Select(Enduse,"Light")
  xLSF[enduse,1,1,Days,Summer,1]=[1.634 1.020 0.489]
  xLSF[enduse,1,1,Days,Winter,1]=[1.522 0.980 0.502]

  enduse=Select(Enduse,"AC")
  xLSF[enduse,1,1,Days,Summer,1]=[1.634 1.020 0.489]
  xLSF[enduse,1,1,Days,Winter,1]=[1.522 0.980 0.502]

  enduse=Select(Enduse,"OthNSub")
  xLSF[enduse,1,1,Days,Summer,1]=[1.634 1.020 0.489]
  xLSF[enduse,1,1,Days,Winter,1]=[1.522 0.980 0.502]

  day=Select(Day,"Average")
  for enduse in Enduses
    SSum[enduse]=sum(xLSF[enduse,1,hour,day,month,1]*HoursPerMonth[month]/8760 for hour in Hours, month in Months)
  end
  for enduse in Enduses, hour in Hours, month in Months
    @finite_math xLSF[enduse,1,hour,day,month,1]=xLSF[enduse,1,hour,day,month,1]/SSum[enduse]
  end
  for area in Areas, month in Months, day in Days, hour in Hours, ec in ECs, enduse in Enduses
    xLSF[enduse,ec,hour,day,month,area]=xLSF[enduse,1,hour,day,month,1]
  end

  #
  # Placeholder values for Cogeneration shapes
  # - Jeff Amlin 10/18/13
  #
  enduse=Select(Enduse,"Refrig")
  for area in Areas, month in Months, day in Days, hour in Hours, ec in ECs, tech in Techs
    xCgLSF[tech,ec,hour,day,month,area]=xLSF[enduse,ec,hour,day,month,area]
  end

  #
  # Gas Daily Use Factors assumed the same as Electric Load Shapes.
  #
  for area in Areas, month in Months, day in Days, ec in ECs, enduse in Enduses
   xDUF[enduse,ec,day,month,area]=sum(xLSF[enduse,ec,hour,day,month,area] for hour in Hours)
  end
  WriteDisk(db,"$Input/xCgLSF",xCgLSF)
  WriteDisk(db,"$Input/xCgLSFSold",xCgLSFSold)
  WriteDisk(db,"$Input/xDUF",xDUF)
  WriteDisk(db,"$Input/xLSF",xLSF)

  #
  ########################
  #
  # MMSFSwitch[Enduse,Tech,EC,Area,Year]   'Market Share Switch (1=Endogenous, 0=Exogenous)',
  #
  @. MMSFSwitch=1.0
  WriteDisk(db,"$Input/MMSFSwitch",MMSFSwitch)

  #
  ########################
  #
  # MSMM[Enduse,Tech,EC,Area,Year] Non-Price Market Share Factor Multiplier ($/$)
  #
  # 1. The default value of this policy variable is 1.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  @. MSMM=1.0
  WriteDisk(db,"$Input/MSMM",MSMM)

  #
  ########################
  #
  # xMVF[Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  #
  # 1. The value is from Demand81.
  # 2. An equation is used to input the data.
  # 3. P. Cross 10/23/95.
  #
  @. xMVF=-2.3
  WriteDisk(db,"$Input/xMVF",xMVF)

  #
  ########################
  #
  # PCCMM[Enduse,Tech,EC,Area,Year] Process Capital Cost Maximum Mult. ($/$)
  #
  # 1. The default value of this policy variable is 1.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  @. PCCMM=1.0
  WriteDisk(db,"$Input/PCCMM",PCCMM)

  #
  ########################
  #
  # PDif[Enduse,Tech,EC,Area] Difference between the initial heating process efficiency
  #
  # 1. The values were developed by M.Jourabchi, MEOER                         
  # 2. The values are read in directly.
  # 3. P. Cross 10/23/95.
  #
  @. PDif=1.0
  WriteDisk(db,"$Input/PDif",PDif)

  #
  ########################
  #
  # xPEE[Enduse,Tech,EC,Area,Year] Historical Process Efficiency ($/Btu)
  #
  # 1. The default value of this variable is -99.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  @. xPEE=-99.0
  WriteDisk(db,"$Input/xPEE",xPEE)

  #
  ########################
  #
  # xPEMM[Enduse,Tech,EC,Area,Year] Pro. Eff. Max. Multi ($/Btu/($/Btu))
  #
  # 1. The default value of this variable is 1.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  @. xPEMM=1.0
  WriteDisk(db,"$Input/xPEMM",xPEMM)

  #
  ########################
  #
  # PEMX[Enduse,Tech,EC,Area] Ratio of Maximum to Average Process Efficiency
  #
  # 1. The values of this variable are from Demand81.
  # 2. The values are assigned with an equation.
  #    All values are initialized to 1.0, then heating and air
  #    conditioning is set to 2.5.
  # 3. J. Amlin 7/15/94
  #
  @. PEMX=1.0
  enduses=Select(Enduse,["AC","Heat"])
  PEMX[enduses,:,:,:] .= 2.5
  WriteDisk(db,"$Input/PEMX",PEMX)

  #
  ########################
  #
  # PERReduction[Enduse,Tech,EC,Area] Process Energy Exogenous Retrofits Percentage ((mmBtu/Yr)/(mmBtu/Yr))
  #
  # Default value for PERReduction is 0.0 
  #
  @. PERReduction=0.0
  WriteDisk(db,"$Input/PERReduction",PERReduction)

  #
  ########################
  #
  # PEStd[Enduse,Tech,EC,Area,Year] Process Efficiency Standards ($/Btu)
  #
  # 1. The values of this policy variable are zero and are commented out 
  #    to save execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # @. PEStd=0.0
  # WriteDisk(db,"$Input/PEStd",PEStd)

  #
  ########################
  #
  # PEStdP[Enduse,Tech,EC,Area,Year] Process Efficiency Standards Policy ($/Btu)
  #
  # 1. The values of this policy variable are zero and are commented out 
  #    to save execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # @. PEStdP=0.0
  # WriteDisk(db,"$Input/PEStdP",PEStdP)

  #
  ########################
  #
  # PIVTC[Enduse,Tech,EC,Area,Year] Process Investment Tax Credit ($/$)
  #
  # 1. The values of this policy variable are zero and are commented out 
  #    to save execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # @. PIVTC=0.0
  # WriteDisk(db,"$Input/PIVTC",PIVTC)

  #
  ########################
  #
  # POCAM[FuelEP,EC,Poll,Area,Year] Average Pollution Coefficients Multiplier (Fraction)
  #
  # 1. The default value of this policy variable is 1.
  # 2. The values are assigned with an equation.
  # 3. P. Cross 7/9/99
  #
  @. POCAM=1.0
  WriteDisk(db,"$Input/POCAM",POCAM)

  #
  ########################
  #
  # PPIVTC[Year] Process Policy Investment Tax Credit ($/$)
  #
  # 1. The values of this policy variable are zero and are commented out 
  #    to save execution time.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  # @. PPIVTC=0.0
  # WriteDisk(db,"$Input/PPIVTC",PPIVTC)

  #
  ########################
  #
  # PolSw[Tech,EC,Poll,Area,Year] Switch for Pollution Coefficients
  #
  # 1. The default value is one.
  # 2. The values are assigned with an equation.
  # 3. P. Cross 8/17/01
  #
  @. PolSw=2.0
  WriteDisk(db,"$Input/PolSw",PolSw)

  #
  ########################
  #
  # POCS[Enduse,FuelEP,EC,Poll,Area,Year] Pollution Standards (Tonnes/TBtu)
  #
  # 1. The default value is one.
  # 2. The values are assigned with an equation.
  # 3. P. Cross 8/17/01
  #
  @. POCS=1e12
  WriteDisk(db,"$Input/POCS",POCS)

  #
  ########################
  #
  # ROIN[EC,Area] Return on Investment ($/Yr/$)
  #
  # 1. The values of this variable are from Demand81.
  # 2. The values are assigned with an equation.
  # 3. J. Amlin 7/15/94
  #
  @. ROIN=0.066
  WriteDisk(db,"$Input/ROIN",ROIN)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # RDCCM(Enduse,Tech,EC,Area,Year) 'Retrofit Device Capital Cost Multiplier ($/$)',
  #  Disk(Input,RDCCM(Enduse,Tech,EC,Area,Year)) 
  # End Define Variable
  # * 
  # * 1. 
  # * 2. The values are assigned with an equation.
  # * 3. P. Cross 12/6/01
  # *
  @. RDCCM=1.5
  WriteDisk(db,"$Input/RDCCM",RDCCM)

  # *
  # ************************
  # *
  # Define Variable
  # RDVF(EC,Area) 'Device Retrofit Market Share Variance Factor (DLESS)',
  #  Disk(Input,RDVF(EC,Area))
  # RPVF(EC,Area) 'Process Retrofit Market Share Variance Factor (DLESS)',
  #  Disk(Input,RPVF(EC,Area)) 
  # End Define Variable
  # *
  # * 1. The value is from Demand81.
  # * 2. An equation is used to input the data.
  # * 3. P. Cross 10/23/95.
  # *
  @. RDVF=-2.3
  @. RPVF=-2.3
  WriteDisk(db,"$Input/RDVF",RDVF)
  WriteDisk(db,"$Input/RPVF",RPVF)

  # *
  # ************************
  # *
  # Define Variable
  # RHCM(EC,Area,Year) 'Retrofit Hassle-Cost Multiplier ($/$)',
  #  Disk(Input,RHCM(EC,Area,Year))
  # End Define Variable
  # *
  @. RHCM = .20
  WriteDisk(db,"$Input/RHCM",RHCM)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # RPCCM(Enduse,Tech,EC,Area,Year) 'Retrofit Process Capital Cost Multiplier ($/$)',
  #  Disk(Input,RPCCM(Enduse,Tech,EC,Area,Year))
  # End Define Variable
  # * 
  # * 1. 
  # * 2. The values are assigned with an equation.
  # * 3. P. Cross 12/6/01
  # *
  @. RPCCM = 1.5
  WriteDisk(db,"$Input/RPCCM",RPCCM)

  # *
  # ************************
  # *
  # Define Variable
  # RPEEFr(Enduse,Tech,EC,Area,Year)  'Process Efficiency Fraction for Retrofits ($/Btu/($/Btu))',
  #  Disk(Input,RPEEFr(Enduse,Tech,EC,Area,Year)) 
  # End Define Variable
  # *
  @. RPEEFr = 0.95
  WriteDisk(db,"$Input/RPEEFr",RPEEFr)

  # *
  # ************************
  # *
  # Define Variable
  # RPMSLimit(EC,Area,Year)   'Process Retrofit Market Share Limit (1/Yr)',
  #  Disk(Input,RPMSLimit(EC,Area,Year))
  # End Define Variable
  # *
  # * Estimated by Jeff Amlin 10/12/21
  # *
  @. RPMSLimit = 0.02
  WriteDisk(db,"$Input/RPMSLimit",RPMSLimit)

  # *
  # ************************
  # *
  # Define Variable
  # SqEUTechMap(Enduse,Tech)   'Sequestering Enduse Map to Tech (1=include)',
  #  Disk(Input,SqEUTechMap(Enduse,Tech))
  # End Define Variable
  # *
  # * Moving assumptions from Engine file to map - Ian 23/08/15
  # *
  @. SqEUTechMap = 0

  enduse = Select(Enduse,"OthSub")
  SqEUTechMap[enduse,:] .= 1
  WriteDisk(db,"$Input/SqEUTechMap",SqEUTechMap)

  # *
  # Select Enduse*
  # Write Disk(SqEUTechMap)
  # *
  # *******************************************************************************
  # *
  # Define Variable
  # TSLoad(Enduse,EC,Area)  'Temperature Sensitive Fraction of Load (Btu/Btu)',
  #  Disk(Input,TSLoad(Enduse,EC,Area))
  # End Define Variable
  # * 
  # * 75% of heating and cooling load is temperature sensitive - Nathalie Trudeau 12/21/07
  # *
  @. TSLoad = 0

  Heat = Select(Enduse,"Heat")
  AC = Select(Enduse,"AC")
  TSLoad[Heat,:,:] .= 1.00 
  TSLoad[AC,:,:] .= 0.30 
  WriteDisk(db,"$Input/TSLoad",TSLoad)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # TxRt(EC,Area,Year) 'Income Tax Rate on Energy Consumer ($/$)',
  #  Disk(Input,TxRt(EC,Area,Year))
  # End Define Variable
  # *
  # * 1. The data is from DRI, Tables 7 & 10
  # * 2. The values are read in for all years and all ECs are set equal to 
  # *    single family.
  # * 3. J. Amlin 7/15/94
  # *
  # Select EC(1),Area(1)
  # Select Year(1985-2031)
  # Read TxRt(EC,Year,Area)

  years = collect(Yr(1985):Yr(1986))
  for year in years
    TxRt[:,:,year] .= .4950
  end
  years = Yr(1987)
  for year in years
    TxRt[:,:,year] .= .38
  end
  years = collect(Yr(1988):Yr(1992))
  for year in years
    TxRt[:,:,year] .= .34
  end
  years = collect(Yr(1993):Final)
  for year in years
    TxRt[:,:,year] .= .35
  end
  WriteDisk(db,"$Input/TxRt",TxRt)
  
  # *
  # ************************
  # *
  # Define Variable
  # xRM(FuelEP,EC,Poll,Area,Year) 'Exogenous Average Pollution Coefficient Reduction Multiplier (Tonnes/Tonnes)',
  #  Disk(Input,xRM(FuelEP,EC,Poll,Area,Year))
  # End Define Variable
  # *
  # * Exogenous Reduction Multiplier is initialized at 1 (No exogenous adjustment)
  # *
  @. xRM = 1.0
  WriteDisk(db,"$Input/xRM",xRM)
   
  # *
  # *******************************************************************************
  # *
  # *  CalibRATION - Flags, Switches, Limits, etc.
  # *
  # *******************************************************************************
  # *
  # * The value in the Zero year slot is the regression method. These methods
  # * are define as follows Y(Zero):
  # *
  # * 1 - Exogenous Values
  # * 2 - Exogenous values scaled to the last historical value.
  # * 3 - The last value
  # * 4 - The mean of the historical values
  # * 5 - Trend the future values toward an exogenous values
  # * 6 - Develop a trend line from the historical values
  # * 7 - Develop an exponential trend line from the historical values
  # * 8 - Estimate a full asymptotic line from the historical values
  # * 9 - Estimate a particle asymptotic line from the historical values
  # * 11    - Maximum likeihood estimate
  # * 16    - Set the future marginal value equal to last historical average value
  # * 17    - Set the future marginal value equal to last historical average value
  # *     using interpolated values.
  # * 18    - Set future marginal values equal to an exogenous values.
  # *
  # ** INTERPOLATION AND BOUNDS
  # * If VALUE IS NEGATIVE, USE LINEAR INTERPOLATION, Else USE EXPONENTIAL
  # * If VALUE HAS FRACTIONAL PART OF 0.1, THERE IS AN UPPER BOUND IN
  # * Y(Future-Final); If FRACTIONAL PART IS 0.2, THERE IS LOWER BOUND.
  # * If THERE IS A -99 IN Y(Future-Final), VALUES WILL BE INTERPOLATED.
  # * 
  # ** OUTLIER METHOD
  # * Y(First-Last): 0=Exclude value, 1=MANUAL SET, 2=HAT CHECK, 3=SD CHECK.
  # *
  # *******************************************************************************
  # *
  # Define Variable
  # CalibTime(EC,Area) 'Last Year of Calibration (Year)',
  #  Disk(Input,CalibTime(EC,Area))
  # End Define Variable
  # *
  @. CalibTime = xHisTime
  WriteDisk(db,"$Input/CalibTime",CalibTime)

  # *
  # ************************
  # *
  # Define Variable
  # YCERSM(Enduse,EC,Area,Year)  'CERSM Calibration Control',
  #  Type=Real(9,6), Disk(Input,YCERSM(Enduse,EC,Area,Year))
  # End Define Variable
  # *
  # * 1. The method for the CERSM calibration (YCERSM) is to use the
  # *    value of the Last calibrated year (YCERSM=3) for all future
  # *    values. Therefore the value in the Zero year equals 3 and the values
  # *    of all other years do not matter.
  # * 2. All values are initialized to 0, then the Zero year is set equal to 3.
  # * 3. J. Amlin 6/13/94
  # *
  @. YCERSM = 0
  YCERSM[:,:,:,Zero] .= 3
  WriteDisk(db,"$Input/YCERSM",YCERSM)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YCgCUF(Tech,EC,Area,Year)    'Cogen. Capacity Utilization Factor ($/Yr/$/Yr)',
  #  Type=Real(9,2), Disk(Input,YCgCUF(Tech,EC,Area,Year))
  # End Define Variable
  # *
  # * Cogeneration capacity utilization factors (CgCUF) are based 
  # * on the Last year's value (YCgCUF=3).
  # *
  @. YCgCUF = 0
  YCgCUF[:,:,:,Zero] .= 3
  WriteDisk(db,"$Input/YCgCUF",YCgCUF)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YCgMSM(Tech,EC,Area,Year)    'Cogeneration Market Share Mult. ($/$)',
  #  Type=Real(9,2), Disk(Input,YCgMSM(Tech,EC,Area,Year))
  # End Define Variable
  # *
  # * Cogeneration non-price factors (CgMSM0) are based on 
  # * the Last year's value (YCgMSM=3)
  # *
  YCgMSM[:,:,:,Zero] .= 3
  WriteDisk(db,"$Input/YCgMSM",YCgMSM)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YCUF(Enduse,Tech,EC,Area,Year)    'CUF Calibration Control',
  #  Type=Real(9,2), Disk(Input,YCUF(Enduse,Tech,EC,Area,Year))
  # Time1    'Local Time Variable',Type=Real(4,0)
  # Time2    'Local Time Variable',Type=Real(4,0)
  # Time3    'Local Time Variable',Type=Real(4,0)
  # End Define Variable
  # *
  # * 1. The method for the capacity utilization factor calibration (YCUF) is
  # *    to linearly interpolate to a final value over five years.
  # * 2. The Zero year for YCUF is set equal to -1 (linear interpolation to an
  # *    exogenous value).  The first 5 years in the forecast period are selected
  # *    and YCUF is given a value of -99.  The remaining years are set equal to
  # *    1.0.  The value of the historical years does not matter.
  # * 3. J. Amlin 6/13/94
  # *
  YCUF[:,:,:,:,Zero] .= 1
  Time1 = Future+5
  years = collect(Future:Time1)
  for year in years
    YCUF[:,:,:,:,year] .= -99
  end

  Time2 = Time1+1
  years = collect(Time2:Final)
  for year in years
    YCUF[:,:,:,:,year] .= 1
  end
  WriteDisk(db,"$Input/YCUF",YCUF)
   
  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YDCMM(Enduse,Tech,Area,Year) 'DCMM Calibration Control',
  #  Type=Real(8,4), Disk(Input,YDCMM(Enduse,Tech,Area,Year))
  # End Define Variable
  # *
  # * 1. The method for the device maximum efficiency multiplier (YDEMM) is
  # *    to use the value of the Last calibrated year (YDEMM=3) for all future
  # *    values.
  # * 2. All values are initialized to 0, then the Zero year is set equal to 3.
  # * 3. J. Amlin 6/13/94
  # *
  @. YDCMM = 0
  YDCMM[:,:,:,Zero] .= 3
  WriteDisk(db,"$Input/YDCMM",YDCMM)
  
  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YDEMM(Enduse,Tech,Area,Year) 'DEMM Calibration Control',
  #  Type=Real(8,4), Disk(Input,YDEMM(Enduse,Tech,Area,Year))
  # End Define Variable
  # *
  # * 1. The method for the device maximum efficiency multiplier (YDEMM) is
  # *    to use the value of the Last calibrated year (YDEMM=3) for all future
  # *    values.
  # * 2. All values are initialized to 0, then the Zero year is set equal to 3.
  # * 3. J. Amlin 6/13/94
  # *
  @. YDEMM = 0
  YDEMM[:,:,:,Zero] .= 3
  WriteDisk(db,"$Input/YDEMM",YDEMM)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YDSt(Enduse,EC,Area,Year)    'Device Saturation (Btu/Btu)',
  #  Type=Real(9,2), Disk(Input,YDSt(Enduse,EC,Area,Year))
  # End Define Variable
  # *
  # * 1. The method for the saturation calibration (YDSt) is to use the full
  # *    asymptotic method (YDSt=8) to interpolate the future years (YDSt=-99).
  # * 2. All values are inititalized to zero. The value in the Zero year is set
  # *    equals to 8.  The values in the historical years do not matter; 
  # *    the value of the future years is the exogenous value (xDSt).
  # * 3. P. Cross 7/13/94 
  # *
  YDSt[:,:,:,Zero] .= 1
  years = collect(Future:Final)
  for year in years
    YDSt[:,:,:,year] .= 1
  end
  WriteDisk(db,"$Input/YDSt",YDSt)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YENDTime(tv) 'Last Year of Calibration (Date)',
  #  Disk(Input,YENDTime(tv))
  # End Define Variable
  # *
  # * 1. This variable is defined by the scope of the model.
  # * 2. The variable is given a value via an equation.
  # * 3. P. Cross 10/23/95.
  # *
  YEndTime = HisTime
  WriteDisk(db,"$Input/YEndTime",YEndTime)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # InitialDemandYear(EC,Area) 'First Year of Calibration', 
  #  Disk(Input,InitialDemandYear(EC,Area))
  # End Define Variable
  # *
  # * Default inital year for calibration is the model start year - Ian 01/08/14
  # *
  @. InitialDemandYear = xITime
  WriteDisk(db,"$Input/InitialDemandYear",InitialDemandYear)

  # *******************************************************************************
  # *
  # Define Variable
  # YFsPEE(Tech,EC,Area,Year)    'Feedstock Process Efficiency Calibration Control',
  #  Disk(Input,YFsPEE(Tech,EC,Area,Year))
  # End Define Variable
  # *
  # * 1. The method for the feedstock process efficiency calibration (YFsPEE) is
  # *    to use the value of the Last calibrated year (YFsPEE=3) for all future
  # *    values.
  # * 2. All values are initialized to 0, then the Zero year is set equal to 3.
  # * 3. J. Amlin 7/15/94
  # *
  @. YFsPEE = 0
  YFsPEE[:,:,:,Zero] .= 3
  WriteDisk(db,"$Input/YFsPEE",YFsPEE)

  # * 
  # *******************************************************************************
  # *
  # Define Variable
  # YMMSM(Enduse,Tech,EC,Area,Year)   'MMSM Calibration Control',
  #  Type=Real(8,4), Disk(Input,YMMSM(Enduse,Tech,EC,Area,Year))
  # End Define Variable
  # *
  # * 1. The method for the market share calibration (YMMSM) is to compute an
  # *    historical average (YMMSM=4) after removing the outliers using the HAT
  # *    method (YMMSM=2). This historical average is used for all future values.
  # * 2. All values are initialized to zero. The value of the Zero year equals 4.
  # *    The value of the historical years equals 2.  The value of the future 
  # *    years does not matter.  A value of 16 tells the model to set the future
  # *   marginal value equal to the last historical value.
  # * 3. J. Amlin 6/13/94
  # *
  @. YMMSM = 0
  YMMSM[:,:,:,:,Zero] .= 4
  years = collect(First:Last)
  for year in years
    YMMSM[:,:,:,:,year] .= 2
  end
  WriteDisk(db,"$Input/YMMSM",YMMSM)

  # *
  # *******************************************************************************
  # *
  # Define Variable
  # YPEMM(Enduse,Tech,EC,Area,Year)   'PEMM Calibration Control',
  #  Type=Real(9,2), Disk(Input,YPEMM(Enduse,Tech,EC,Area,Year))
  # End Define Variable
  # *
  # * 1. The method for the process maximum efficiency multiplier (YPEMM) is
  # *    to use the value of the Last calibrated year (YPEMM=3) for all future
  # *    values.
  # * 2. All values are initialized to 0, then the Zero year is set equal to 3.
  # * 3. P. Cross 6/14/94
  # *
  @. YPEMM = 0
  YPEMM[:,:,:,:,Zero] .= 3
  WriteDisk(db,"$Input/YPEMM",YPEMM)

  # *******************************************************************************
  # *
  # * Heat Pump Fraction of Geothermal Energy Demands
  # *
  # Define Variable
  # HPGeoFraction(EC,Area,Year)  'Air Source Heat Pump Fraction of Geothermal Demand (TBtu/TBtu)',
  #  Disk(Input,HPGeoFraction(EC,Area,Year))
  # End Define Variable
  # *
  @. HPGeoFraction = 0.333
  WriteDisk(db,"$Input/HPGeoFraction",HPGeoFraction)

  # **************************
  # * CAC Pollution Reduction
  # **************************
  # *
  # Define Variable
  # CM(FuelEP,Poll,PollX) 'Cross-over Reduction Multiplier (Tonnes/Tonnes)',
  #  Disk(Input,CM(FuelEP,Poll,PollX))
  # RCD(EC,Poll) 'Reduction Capital Construction Delay (Years)',
  #  Disk(Input,RCD(EC,Poll))
  # RCPL(EC,Poll) 'Reduction Capital Pysical Life (Years)',
  #  Disk(Input,RCPL(EC,Poll))
  # RCostM(FuelEP,Poll,Year) 'Reduction Cost FuelEPnology Multiplier ($/$)',
  #  Disk(Input,RCostM(FuelEP,Poll,Year))
  # ROCF(FuelEP,EC,Poll,Area) 'Polution Reducution O&M ($/Tonne/($/Tonne))',
  #  Disk(Input,ROCF(FuelEP,EC,Poll,Area))
  # VRP(FuelEP,EC,Poll,Area,Year) 'Voluntary Reduction Policy (Tonnes/Tonnes)',
  #  Disk(Input,VRP(FuelEP,EC,Poll,Area,Year))
  # VRRT(EC) 'Voluntary Reduction response time (Years)',
  #  Disk(Input,VRRT(EC))
  # End Define Variable
  # *
  # * Pollution Reduction Operating Cost Factors from Dave Sawyer
  # *
  fueleps = Select(FuelEP,["Diesel","HFO","Kerosene","LFO","LPG"])
  SOX = Select(Poll,"SOX")
  NOX = Select(Poll,"NOX")
  for fuelep in fueleps
    ROCF[fuelep,:,SOX,:] .= 0.35
    ROCF[fuelep,:,NOX,:] .= 0.13
  end

  NaturalGas = Select(FuelEP,"NaturalGas")
  ROCF[NaturalGas,:,SOX,:] .= 0.0
  ROCF[NaturalGas,:,NOX,:] .= 0.13
  polls = Select(Poll,["PM25","PM10","PMT","BC"])
  for poll in polls
    ROCF[NaturalGas,:,poll,:] .= 0.22
  end

  Coal = Select(FuelEP,"Coal")
  ROCF[Coal,:,SOX,:] .= 0.35
  ROCF[Coal,:,NOX,:] .= 0.13
  polls = Select(Poll,["PM25","PM10","PMT","BC"])
  for poll in polls
    ROCF[Coal,:,poll,:] .= 0.22
  end
  WriteDisk(db,"$Input/ROCF",ROCF)

  # *
  # * Voluntary Reductions
  # *
  @. VRP = 0
  @. VRRT = 3
  WriteDisk(db,"$Input/VRP",VRP)
  WriteDisk(db,"$Input/VRRT",VRRT)

  # *
  # * Cross Impact Multiplier (is zero except for the diaganol)
  # *
  @. CM = 0
  for poll in Polls
    CM[:,poll,poll] .= 1.0
  end
  WriteDisk(db,"$Input/CM",CM)
  
  @. RCostM = 1.0
  @. RCD = 1.0
  WriteDisk(db,"$Input/RCostM",RCostM)
  WriteDisk(db,"$Input/RCD",RCD)

  # *
  # * RCPL is set equal to PCPL
  # * 
  @. RCPL = 20
  WriteDisk(db,"$Input/RCPL",RCPL)

  # *
  # ************************
  # *
  # * Permit Cost Effectiveness Multiplier
  # *
  @. PCostM = 1
  WriteDisk(db,"$Input/PCostM",PCostM)

  @. DEEA0 = 88.999
  @. PEEA0 = 88.999
  @. DEEB0 = -5.016
  @. PEEB0 = -5.016
  @. DEEC0 = 0.000
  @. PEEC0 = 0.000
  @. DCDEM = 1.000
  @. PCPEM = 1.000
  @. DEESw = 1
  @. DEEFloorSw = 0
  @. PEEFloorSw = 0
  @. PEESw = 1

  WriteDisk(db,"$Input/DEEA0",DEEA0)
  WriteDisk(db,"$Input/PEEA0",PEEA0)
  WriteDisk(db,"$Input/DEEB0",DEEB0)
  WriteDisk(db,"$Input/PEEB0",PEEB0)
  WriteDisk(db,"$Input/DEEC0",DEEC0)
  WriteDisk(db,"$Input/PEEC0",PEEC0)
  WriteDisk(db,"$Input/DCDEM",DCDEM)
  WriteDisk(db,"$Input/PCPEM",PCPEM)
  WriteDisk(db,"$Input/DEESw",DEESw)
  WriteDisk(db,"$Input/DEEFloorSw",DEEFloorSw)
  WriteDisk(db,"$Input/PEEFloorSw",PEEFloorSw)
  WriteDisk(db,"$Input/PEESw",PEESw)

  # *
  # ************************
  # *
  # * Switches and Coefficients to Smooth PCostTech to get PrPCost for
  # * Energy Efficiency Investments
  # *
  # * Values per Jeff Amlin, 2/27/2013
  # *
  @. PrPCostSw = 1
  @. PrPCostAT = 3
  WriteDisk(db,"$Input/PrPCostSw",PrPCostSw)
  WriteDisk(db,"$Input/PrPCostAT",PrPCostAT)

  @. RPEIX = 0
  WriteDisk(db,"$Input/RPEIX",RPEIX)
  
end # end CData_Inputs

function Control(db)
  @info "CData.jl - Control"
  CData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end
end #end module
