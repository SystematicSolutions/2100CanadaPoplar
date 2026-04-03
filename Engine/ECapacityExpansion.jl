#
# ECapacityExpansion.jl - Electricity Capacity Expansion
#

module ECapacityExpansion

  import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Last,Future
  import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log,@autoinfiltrate

  const VariableArray{N} = Array{Float32,N} where {N}
  const SetArray = Vector{String}

  Base.@kwdef struct Data
    db::String
    year::Int
    current
    prior::Int
    prior2::Int = max(1,current-2)
    prior3::Int = max(1,current-3)
    prior4::Int = max(1,current-4)
    next::Int

    CTime::Int
    Final::Int = MaxTime-ITime+1
    Last::Int = HisTime-ITime+1

    next1::Int = min(next+1,Final)

    Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
    AreaKey::SetArray = ReadDisk(db,"MainDB/AreaKey")
    Areas::Vector{Int} = collect(Select(Area))
    ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
    ECCs::Vector{Int} = collect(Select(ECC))
    ES::SetArray = ReadDisk(db,"MainDB/ESKey")
    Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
    Fuels::Vector{Int} = collect(Select(Fuel))
    FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
    FuelEPs::Vector{Int} = collect(Select(FuelEP))
    GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
    GenCoKey::SetArray = ReadDisk(db,"MainDB/GenCoKey")
    GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoKey")
    GenCos::Vector{Int} = collect(Select(GenCo))
    Horizon::SetArray = ReadDisk(db,"EGInput/HorizonKey")
    Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
    Months::Vector{Int} = collect(Select(Month))
    Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
    NationKey::SetArray = ReadDisk(db,"MainDB/NationKey")
    Nations::Vector{Int} = collect(Select(Nation))
    Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
    NodeKey::SetArray = ReadDisk(db,"MainDB/NodeKey")
    Nodes::Vector{Int} = collect(Select(Node))
    NodeX::SetArray = ReadDisk(db,"MainDB/NodeX")
    NodeXs::Vector{Int} = collect(Select(NodeX))
    Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
    PlantKey::SetArray = ReadDisk(db,"MainDB/PlantKey")
    Plants::Vector{Int} = collect(Select(Plant))
    Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
    Polls::Vector{Int} = collect(Select(Poll))
    Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
    Powers::Vector{Int} = collect(Select(Power))
    TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
    TimePs::Vector{Int} = collect(Select(TimeP))
    Unit::SetArray = ReadDisk(db,"MainDB/Unit")
    Units::Vector{Int} = collect(Select(Unit))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")
    # Year as a Float32, for use in comparison with other Float32
    Yrv::VariableArray{1} = ReadDisk(db,"MainDB/Yrv")

    ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
    ArGenFr::VariableArray{2} = ReadDisk(db,"EGInput/ArGenFr",year) #[Area,GenCo,Year]  Fraction of the Area going to each GenCo
    ArNdFr::VariableArray{2} = ReadDisk(db,"EGInput/ArNdFr",year) #[Area,Node,Year]  Fraction of the Area in each Node (Fraction)
    AwardSwitch::VariableArray{1} = ReadDisk(db,"EGInput/AwardSwitch",year) #[Area,Year]  New Capacity Award Switch (1=Cost,2=Portfolio)
    BFraction::VariableArray{3} = ReadDisk(db,"EGOutput/BFraction",year) #[Power,Node,Area,Year]  Endogenous Build Fraction (MW/MW)
    BFracMax::VariableArray{1} = ReadDisk(db,"EGInput/BFracMax",year) #[Area,Year]  Maximum Fraction of Capacity Built Endogenously (MW/MW)
    BuildFr::VariableArray{1} = ReadDisk(db,"EGInput/BuildFr",year) #[Area,Year]  Building fraction
    BuildSw::VariableArray{1} = ReadDisk(db,"EGInput/BuildSw",year) #[Area,Year]  Build switch
    CapCredit::VariableArray{2} = ReadDisk(db,"EGInput/CapCredit",year) #[Plant,Area,Year]  Capacity Credit (MW/MW)
    CCR::VariableArray{2} = ReadDisk(db,"EGOutput/CCR",year) #[Plant,Area,Year]  Capital Charge Rate (1/Yr)
    CD::VariableArray{1} = ReadDisk(db,"EGInput/CD",year) #[Plant,Year]  Construction Delay (Years)
    # CgEC::VariableArray{2} = ReadDisk(db, "SOutput/CgEC", year) #[ECC,Area,Year]  Cogeneration by Economic Category (GWh/YR)
    CgECPrior::VariableArray{2} = ReadDisk(db,"SOutput/CgEC",prior) #[ECC,Area,Year]  Cogeneration by Economic Category (GWh/YR)
    CgGCCI::VariableArray{4} = ReadDisk(db,"SOutput/CgGCCI",year) #[Plant,ECC,Node,Area,Year]  Cogeneration Unit Capacity Initiated (MW)
    CgInvUnit::VariableArray{2} = ReadDisk(db,"SOutput/CgInvUnit",year) #[ECC,Area,Year]  Cogeneration Investments (M$/Yr)
    CgUnCode::VariableArray{4} = ReadDisk(db,"EGInput/CgUnCode") # [Plant,ECC,Node,Area]  Cogeneration Unit Code (Number)
    CoverNew::VariableArray{3} = ReadDisk(db,"EGInput/CoverNew",year) #[Plant,Poll,Area,Year]  Fraction of New Plants Covered in Emissions Market (1=100% Covered)
    CUCFr::VariableArray{1} = ReadDisk(db,"EGOutput/CUCFr",year) #[Node,Year]  Capacity Under Construction as Fraction of Capacity (MW/MW)
    CUCLimit::Float32 = ReadDisk(db,"EGInput/CUCLimit",year) #[Year]  Build Decision Capacity Under Construction Limit (MW/MW)
    CUCMlt::VariableArray{1} = ReadDisk(db,"EGOutput/CUCMlt",year) #[Node,Year]  Build Decision Capacity Under Construction Constraint (MW/MW)
    CW::VariableArray{2} = ReadDisk(db,"EGOutput/CW",year) #[Plant,Area,Year]  Construction Work in Progress (M$/Yr)
    CWAC::VariableArray{2} = ReadDisk(db,"EGOutput/CWAC",year) #[Plant,Area,Year]  Const. Work in Progress Accum. (M$)
    CWGA::VariableArray{2} = ReadDisk(db,"EGOutput/CWGA",year) #[Plant,Area,Year]  Construction Work into Gross AsSets (M$)
    DesHr::VariableArray{3} = ReadDisk(db,"EGInput/DesHr",year) #[Plant,Power,Area,Year]  Design Hours (Hours)
    DesHrLast::VariableArray{3} = ReadDisk(db,"EGInput/DesHr",Last) #[Plant,Power,Area,Year]  Design Hours (Hours)
    DIVTC::VariableArray{2} = ReadDisk(db,"EGInput/DIVTC",year) #[Plant,Area,Year]  Device Investment Tax Credit ($/$)
    DRisk::VariableArray{2} = ReadDisk(db,"EGInput/DRisk",year) #[Plant,Area,Year]  Device Risk Premium ($/$)
    DRM::VariableArray{1} = ReadDisk(db,"EInput/DRM",year) #[Node,Year]  Desired Reserve Margin (MW/MW)
    EAF::VariableArray{3} = ReadDisk(db,"EGInput/EAF",year) #[Plant,Area,Month,Year]  Energy Avaliability Factor (MWh/MWh)
    # EGPA::VariableArray{2} = ReadDisk(db, "EGOutput/EGPA", year) #[Plant,Area,Year]  Electricity Generated (GWh/Yr)
    EGPAPrior::VariableArray{2} = ReadDisk(db,"EGOutput/EGPA",prior) #[Plant,Area,Year]  Electricity Generated (GWh/Yr)
    EmitNew::VariableArray{2} = ReadDisk(db,"EGInput/EmitNew") #[Plant,Area]  Do New Plants Emit Pollution? (1=Yes)
    ExchangeRate::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",year) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
    ExchangeRateUnit::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateUnit",year) #[Unit,Year]  Local Currency/US$ Exchange Rate (Local/US$)
    FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
    #F1New::SetArray = ReadDisk(db,"EGInput/F1New") #[Plant,Area]  Fuel Type 1 (Name)
    FlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/FlFrMax",year) #[FuelEP,Plant,Area,Year]  Fuel Fraction Maximum (Btu/Btu)
    FlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/FlFrMin",year) #[FuelEP,Plant,Area,Year]  Fuel Fraction Minimum (Btu/Btu)
    FlFrMSM0::VariableArray{3} = ReadDisk(db,"EGInput/FlFrMSM0",year) #[FuelEP,Plant,Area,Year]  Fuel Fraction Non-Price Factor (Btu/Btu)
    FlFrTime::VariableArray{3} = ReadDisk(db,"EGInput/FlFrTime",year) #[FuelEP,Plant,Area,Year]  Fuel Adjustment Time (Years)
    FlFrVF::VariableArray{3} = ReadDisk(db,"EGInput/FlFrVF") #[FuelEP,Plant,Area]  Fuel Fraction Variance Factor (Btu/Btu)
    FIT::VariableArray{2} = ReadDisk(db,"EGInput/FIT",year) #[Plant,Area,Year]  Feed-In Tariff for Renewable Power (nominal $/MWh)
    FlFrNew::VariableArray{3} = ReadDisk(db,"EGInput/FlFrNew",year) #[FuelEP,Plant,Area,Year]  Fuel Fraction for New Plants
    FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
    FPEU::VariableArray{2} = ReadDisk(db,"EGOutput/FPEU",year) #[Plant,Area,Year]  Electric Utility Fuel Prices ($/mmBtu)
    GC::VariableArray{3} = ReadDisk(db,"EOutput/GC",year) #[Plant,Node,GenCo,Year]  Generation Capacity (MW)
    GCPrior::VariableArray{3} = ReadDisk(db,"EOutput/GC",prior) #[Plant,Node,GenCo,Year]  Generation Capacity (MW)
    GCAr::VariableArray{4} = ReadDisk(db,"EOutput/GCAr",year) #[Plant,Node,GenCo,Area,Year]  Generation Capacity (MW)
    GCArPrior::VariableArray{4} = ReadDisk(db,"EOutput/GCAr",prior) #[Plant,Node,GenCo,Area,Year]  Generation Capacity (MW)
    GCCC::VariableArray{2} = ReadDisk(db,"EGOutput/GCCC",year) #[Plant,Area,Year]  Overnight Construction Costs ($/KW)
    GCCCFlag::VariableArray{2} = ReadDisk(db,"EGInput/GCCCFlag",year) #[Plant,Area,Year]  Plant Capital Cost Flag
    GCCCM::VariableArray{2} = ReadDisk(db,"EGOutput/GCCCM",year) #[Plant,Area,Year]  Capital Cost Multiplier ($/$)
    GCCCN::VariableArray{2} = ReadDisk(db,"EGInput/GCCCN",year) #[Plant,Area,Year]  Overnight Construction Costs ($/KW)
    GCCR::VariableArray{3} = ReadDisk(db,"EGOutput/GCCR",year) #[Plant,Node,GenCo,Year]  Capacity Completion Rate (MW/Yr)
    GCDev::VariableArray{3} = ReadDisk(db,"EGOutput/GCDev",year) #[Plant,Node,Area,Year]  Generation Capacity Developed (MW)
    GCDevTime::VariableArray{1} = ReadDisk(db,"EGInput/GCDevTime",year) #[Plant,Year]  Generation Capacity Development Time (Years)
    GCExpSw::VariableArray{2} = ReadDisk(db,"EGInput/GCExpSw", year) #[Plant,Area,Year]  Generation Capacity Expansion Switch
    GCBL::VariableArray{2} = ReadDisk(db,"EGInput/GCBL",year) #[Plant,Area,Year]  Generation Capacity Book Life (Years)
    GCG::VariableArray{2} = ReadDisk(db,"EOutput/GCG",year) #[Plant,GenCo,Year]  Generation Capacity (MW)
    GCPA::VariableArray{2} = ReadDisk(db,"EOutput/GCPA",year) #[Plant,Area,Year]  Generation Capacity (MW)
    GCPAPrior::VariableArray{2} = ReadDisk(db,"EOutput/GCPA",prior) #[Plant,Area,Year]  Generation Capacity (MW)
    GCPot::VariableArray{3} = ReadDisk(db,"EGOutput/GCPot",year) #[Plant,Node,Area,Year]  Maximum Potential Generation Capacity (MW)
    GCTC::VariableArray{2} = ReadDisk(db,"EGOutput/GCTC",year) #[Plant,Nation,Year]  Generating Capacity for ETC Equation (MW)
    GCTCLast::VariableArray{2} = ReadDisk(db,"EGOutput/GCTC",Last) #[Plant,Nation,Last]  Generating Capacity in Last Historical Year for ETC Equation (MW)
    GCTCB0::VariableArray{2} = ReadDisk(db,"EGInput/GCTCB0",year) #[Plant,Area,Year]  ETC Capital Cost Coefficiency ($/$)
    GCTCMap::VariableArray{2} = ReadDisk(db,"EGInput/GCTCMap",year) #[Area,Nation,Year]  Area to Nation Map for ETC
    GCTCM::VariableArray{2} = ReadDisk(db,"EGOutput/GCTCM",year) #[Plant,Area,Year]  Capital Cost Multiplier from ETC ($/$)
    GCTCMPrior::VariableArray{2} = ReadDisk(db,"EGOutput/GCTCM",prior) #[Plant,Area,Year]  Capital Cost Multiplier from ETC ($/$)
    GCTCMLast::VariableArray{2} = ReadDisk(db,"EGOutput/GCTCM",Last) #[Plant,Area,Year]  Capital Cost Multiplier from ETC in Last Historical Year ($/$)
    GCTL::VariableArray{2} = ReadDisk(db,"EGInput/GCTL",year) #[Plant,Area,Year]  Generation Capacity Tax Life (Years)
    GrMSM::VariableArray{3} = ReadDisk(db,"EGInput/GrMSM",year) #[Plant,Node,Area,Year]  Green Power Market Share Non-Price Factors (MW/MW)
    GrSysFr::VariableArray{2} = ReadDisk(db,"EGInput/GrSysFr",year) #[Node,Area,Year]  Green Power Capacity as Fraction of System (MW/MW)
    HDCgGC::VariableArray{1} = ReadDisk(db,"EGOutput/HDCgGC",year) #[Node,Year]  Firm Cogeneration Capacity Sold to Grid (MW)
    HDCUC::VariableArray{1} = ReadDisk(db,"EGOutput/HDCUC",year) #[Node,Year]  Forecasted Firm Capacity under Construction (MW)
    HDFGC::VariableArray{1} = ReadDisk(db,"EGOutput/HDFGC",year) #[Node,Year]  Forecasted Firm Generation Capacity (MW)
    HDFlowFr::VariableArray{2} = ReadDisk(db,"EGInput/HDFlowFr",year) #[Node,NodeX,Year]  Fraction of Power Contracts in Firm Capacity (MW/MW)
    HDGC::VariableArray{1} = ReadDisk(db,"EGOutput/HDGC",year) #[Node,Year]  Firm Generating Capacity (MW)
    HDGCCI::VariableArray{4} = ReadDisk(db,"EGOutput/HDGCCI",year) #[Plant,Node,GenCo,Area,Year]  Capacity Initiated Before Renewable Programs (MW)
    HDGCCR::VariableArray{1} = ReadDisk(db,"EGOutput/HDGCCR",year) #[Node,Year]  Firm Generating Capacity being Revised (MW)
    HDGR::VariableArray{1} = ReadDisk(db,"EGOutput/HDGR",year) #[Node,Year]  Forecasted Peak Growth Rate
    HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
    HDInflow::VariableArray{1} = ReadDisk(db,"EGOutput/HDInflow",year) #[Node,Year]  Firm Capacity from Inflows in Power Contracts (MW)
    HDIPGC::VariableArray{4} = ReadDisk(db,"EGOutput/HDIPGC",year) #[Power,Node,GenCo,Area,Year]  Indicated Planned Generation Capacity (MW)
    HDOutflow::VariableArray{1} = ReadDisk(db,"EGOutput/HDOutflow",year) #[Node,Year]  Firm Requirements from Outflows in Power Contracts (MW)
    HDPDP::VariableArray{3} = ReadDisk(db,"EGOutput/HDPDP",year) #[Node,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
    HDPDP1::VariableArray{1} = ReadDisk(db,"EGOutput/HDPDP1",year) #[Node,Year]  Annual Peak Load (MW)
    HDPDPSM::VariableArray{1} = ReadDisk(db,"EGOutput/HDPDPSM",year) #[Node,Year]  Peak Load Smoothed (MW)
    HDPDPSMPrior::VariableArray{1} = ReadDisk(db,"EGOutput/HDPDPSM",prior) # [Node,Year]  Peak Load Previous Year (MW)
    HDRetire::VariableArray{1} = ReadDisk(db,"EGOutput/HDRetire",year) #[Node,Year]  Firm Generating Capacity being Retired (MW)
    # HDPrA::VariableArray{3} = ReadDisk(db, "EOutput/HDPrA", year) #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
    HDPrAPrior::VariableArray{3} = ReadDisk(db,"EOutput/HDPrA",prior) #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
    HDPrDP::VariableArray{2} = ReadDisk(db,"EGOutput/HDPrDP",year) #[Power,Node,Year]  Decision Price for New Construction ($/MWh)
    HDPrDPPrior::VariableArray{2} = ReadDisk(db,"EGOutput/HDPrDP",prior) #[Power,Node,Prior]  Decision Price for New Construction ($/MWh)
    HDPrDPPrior2::VariableArray{2} = ReadDisk(db,"EGOutput/HDPrDP",prior2) #[Power,Node,Prior2]  Decision Price for New Construction ($/MWh)
    HDPrDPPrior3::VariableArray{2} = ReadDisk(db,"EGOutput/HDPrDP",prior3) #[Power,Node,Prior3]  Decision Price for New Construction ($/MWh)
    HDPrDPPrior4::VariableArray{2} = ReadDisk(db,"EGOutput/HDPrDP",prior4) #[Power,Node,Prior4]  Decision Price for New Construction ($/MWh)
    HDRM::VariableArray{1} = ReadDisk(db,"EGOutput/HDRM",year) #[Node,Year]  Reserve Margin (MW/MW)
    HDRQ::VariableArray{1} = ReadDisk(db,"EGOutput/HDRQ",year) #[Node,Year]  Hourly Dispatch Forecasted Generation Requirements
    HDXLoad::VariableArray{5} = ReadDisk(db,"EGInput/HDXLoad") #[Node,NodeX,TimeP,Month,Year]  Power Contracts over Transmission Lines (MW)
    HDXLoadMax::VariableArray{2} = zeros(Float32,size(Node,1),size(NodeX,1)) # Maximum Power Contracts over Transmission Lines (MW)
    HRtM::VariableArray{2} = ReadDisk(db,"EGInput/HRtM",year) #[Plant,Area,Year]  Marginal Heat Rate (Btu/KWh)
    Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
    InflationUnit::VariableArray{1} = ReadDisk(db,"MOutput/InflationUnit",year) #[Unit,Year]  Inflation Index ($/$)
    InSm::VariableArray{1} = ReadDisk(db,"MOutput/InSm",year) #[Area,Year]  Smoothed Inflation Rate (1/Yr)
    IPExpSw::VariableArray{2} = ReadDisk(db,"EGInput/IPExpSw",year) #[Plant,Area,Year]  Intermittent Power Capacity Expansion Switch (1=Build)
    IPGCCI::VariableArray{4} = ReadDisk(db,"EGOutput/IPGCCI",year) #[Plant,Node,GenCo,Area,Year]  Intermittent Power Capacity Initiated (MW)
    IPGCPr::VariableArray{4} = ReadDisk(db,"EGOutput/IPGCPr",year) #[Power,Node,GenCo,Area,Year]  Capacity Built based on Spot Market Prices (MW)
    IPGCRM::VariableArray{4} = ReadDisk(db,"EGOutput/IPGCRM",year) #[Power,Node,GenCo,Area,Year]  Capacity Built based on Reserve Margin (MW)
    IPPrDP::VariableArray{1} = ReadDisk(db,"EGOutput/IPPrDP",year) #[Node,Year]  Decision Price for building Intermittent Power ($/MWh)
    IPTPMap::VariableArray{2} = ReadDisk(db,"EGInput/IPTPMap") #[TimeP,Area]  Intermittent Power Price Time Period Map (1=use TimeP)
    MEPOCX::VariableArray{3} = ReadDisk(db,"EGInput/MEPOCX",year) #[Plant,Poll,Area,Year]  Process Emission Coefficients (Tonnes/GWh)
    MCE::VariableArray{3} = ReadDisk(db,"EOutput/MCE",year) #[Plant,Power,Area,Year]  Cost of Energy from New Capacity ($/MWh)
    MCELimit::VariableArray{1} = ReadDisk(db,"EGInput/MCELimit",year) #[Area,Year]  Build Decision Cost of Power Limit
    MFC::VariableArray{2} = ReadDisk(db,"EOutput/MFC",year) #[Plant,Area,Year]  Marginal Fixed Costs ($/KW)
    MRunNew::VariableArray{2} = ReadDisk(db,"EGInput/MRunNew") #[Plant,Area]  New Plant Must Run Switch (1=Must Run)
    MVC::VariableArray{2} = ReadDisk(db,"EOutput/MVC",year) #[Plant,Area,Year]  Marginal Variable Costs ($/MWh)
    NdArFr::VariableArray{2} = ReadDisk(db,"EGInput/NdArFr",year) #[Node,Area,Year]  Fraction of the Node in each Area
    NdArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdArMap") #[Node,Area]  Map between Node and Area
    # NuclearFuelCost::VariableArray{1} = ReadDisk(db, "EGInput/NuclearFuelCost", year) #[Area,Year]  Nuclear Fuel Costs ($/MWh)
    OffNew::VariableArray{3} = ReadDisk(db,"EGInput/OffNew",year) #[Plant,Poll,Area,Year]  Offset Permits for New Plants (Tonnes/TBtu)
    OGCapacity::VariableArray{3} = ReadDisk(db,"EGOutput/OGCapacity",year) #[Node,GenCo,Area,Year]  New OG Capacity (MW)
    OGCCFraction::VariableArray{1} = ReadDisk(db,"EGInput/OGCCFraction",year) #[Area,Year]  Fraction of new OG capacity which is OGCC (MW/MW)
    OGCCSmallFraction::VariableArray{1} = ReadDisk(db,"EGInput/OGCCSmallFraction",year) #[Area,Year]  Fraction of new OGCC capacity which is Small (MW/MW)
    ORNew::VariableArray{4} = ReadDisk(db,"EGInput/ORNew",year) #[Plant,Area,TimeP,Month,Year]  Outage Rate for New Plants (MW/MW)
    PCUC::VariableArray{4} = ReadDisk(db,"EGOutput/PCUC",year) #[Plant,Node,GenCo,Area,Year]  Capacity under Construction (MW)
    PCUCPrior::VariableArray{4} = ReadDisk(db,"EGOutput/PCUC",prior) #[Plant,Node,GenCo,Area,Year]  Capacity under Construction (MW)
    Portfolio::VariableArray{4} = ReadDisk(db,"EGInput/Portfolio",year) #[Plant,Power,Node,Area,Year]  Portfolio Fraction of New Capacity (MW/MW)
    PoTRNew::VariableArray{2} = ReadDisk(db,"EGOutput/PoTRNew",year) #[Plant,Area,Year]  Emission Cost for New Plants ($/MWh)
    PoTRNewExo::VariableArray{2} = ReadDisk(db,"EGInput/PoTRNewExo",year) #[Plant,Area,Year]  Exogenous Emission Cost for New Plants (Real $/MWH)
    PrDiFr::VariableArray{2} = ReadDisk(db,"EGInput/PrDiFr",year) #[Power,Area,Year]  Price Differential Fraction (Fraction)
    PriceDiff::VariableArray{3} = ReadDisk(db,"EGOutput/PriceDiff",year) #[Power,Node,Area,Year]  Difference between Spot Market Price and Price of New Capacity ($/$)
    PriceDiffGR::VariableArray{3} = ReadDisk(db,"EGOutput/PriceDiffGR",year) #[Power,Node,Area,Year]  Price Difference Growth Rate (($/$)/Yr)
    PJCIHD::VariableArray{5} = ReadDisk(db,"EGOutput/PJCIHD",year) #[Plant,Node,Power,GenCo,Area,Year]  Capacity of Projects Initiated (MW/Yr)
    PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") #[Plant,Area]  Minimum Project Size (MW)
    PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") #[Plant,Area]  Maximum Project Size (MW)
    PjNSw::VariableArray{3} = ReadDisk(db,"EGInput/PjNSw",year) #[Node,GenCo,Area,Year]  Project Selection Node Switch (1=Build)
    POCX::VariableArray{4} = ReadDisk(db,"EGInput/POCX",year) #[FuelEP,Plant,Poll,Area,Year]  Marginal Pollution Coefficients (Tonnes/TBtu)
    # PSoECC::VariableArray{2} = ReadDisk(db, "SOutput/PSoECC", year) #[ECC,Area,Year]  Power Sold to Grid (GWh)
    PSoECCPrior::VariableArray{2} = ReadDisk(db,"SOutput/PSoECC",prior) #[ECC,Area,Year]  Power Sold to Grid (GWh)
    # PwrFrAve::VariableArray{3} = ReadDisk(db, "EGOutput/PwrFrAve", year) #[Power,Month,GenCo,Year]  Average Power Type Fraction (MW/MW)
    PwrFra::VariableArray{2} = ReadDisk(db,"EGOutput/PwrFra",year) #[Power,GenCo,Year]  Annual Power Type Fraction (MW/MW)
    ReGCCM::VariableArray{1} = ReadDisk(db,"SOutput/ReGCCM",year) #[Area,Year]  Incremental Electric Generating Capacity from Reductions (MW)
    RnBuildFr::VariableArray{2} = ReadDisk(db,"EGInput/RnBuildFr",year) #[Plant,Area,Year]  Build Fraction for Renewable Capacity as Fraction of Area (MW/MW)
    RnEGI::VariableArray{4} = ReadDisk(db,"EGOutput/RnEGI",year) #[Plant,Node,GenCo,Area,Year]  Renewable Generation Initiated (GWh/Yr)
    # RnFr::VariableArray{1} = ReadDisk(db, "EGInput/RnFr", year) #[Area,Year]  Renewable Fraction (GWh/GWh)
    RnGCCI::VariableArray{4} = ReadDisk(db,"EGOutput/RnGCCI",year) #[Plant,Node,GenCo,Area,Year]  Renewable Capacity Initiated (MW)
    # RnGen::VariableArray{1} = ReadDisk(db, "EGOutput/RnGen", year) #[Area,Year]  Renewable Current Level of Generation (GWh/Yr)
    RnGenPrior::VariableArray{1} = ReadDisk(db,"EGOutput/RnGen",prior) #[Area,Year]  Renewable Current Level of Generation (GWh/Yr)
    RnGoal::VariableArray{1} = ReadDisk(db,"EGOutput/RnGoal",year) #[Area,Year]  Renewable Generation Goal (GWh/Yr)
    # RnGoalSwitch::VariableArray{1} = ReadDisk(db, "EGInput/RnGoalSwitch", year) #[Area,Year]  Renewable Generation Goal Switch (0 = Sales, 1=New Capacity)
    RnMSF::VariableArray{4} = ReadDisk(db,"EGOutput/RnMSF",year) #[Plant,Node,GenCo,Area,Year]  Renewable Market Share (GWh/GWh)
    RnMSM::VariableArray{4} = ReadDisk(db,"EGInput/RnMSM",year) #[Plant,Node,GenCo,Area,Year]  Renewable Market Share Non-Price Factors (GWh/GWh)
    RnOption::VariableArray{1} = ReadDisk(db,"EGInput/RnOption",year) #[Area,Year]  Renewable Expansion Option (1=Local RPS,2=Regional RPS,3=FIT)
    RnSwitch::VariableArray{2} = ReadDisk(db,"EGInput/RnSwitch") #[Plant,Area]  Renewable Plant Type Switch (1=Renewable)
    RnVF::VariableArray{1} = ReadDisk(db,"EGInput/RnVF",year) #[Area,Year]  Renewable Market Share Variance Factor ($/$)
    RAvNew::VariableArray{2} = ReadDisk(db,"EGInput/RAvNew",year) #[Plant,Node,Year]  Reserve Availability (MW/MW)
    RRqNew::VariableArray{2} = ReadDisk(db,"EGInput/RRqNew",year) #[Plant,Node,Year]  Reserve Requirements (MW/MW)
    RSwNew::VariableArray{2} = ReadDisk(db,"EGInput/RSwNew",year) #[Plant,Node,Year]  Reserve Availability Switch (MW/MW)
    # SaEC::VariableArray{2} = ReadDisk(db, "SOutput/SaEC", year) #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)
    SaECPrior::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",prior) #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)
    SqFr::VariableArray{3} = ReadDisk(db,"EGInput/SqFr",year) #[Plant,Poll,Area,Year]  Sequestered Pollution Fraction (Tonne/Tonne)
    StGCCM::VariableArray{1} = ReadDisk(db,"SOutput/StGCCM",year) #[Area,Year]  Incremental Electric Generating Capacity from Steam Production (MW)
    StorageEfficiency::VariableArray{2} = ReadDisk(db,"EGInput/StorageEfficiency",year) #[Plant,Area,Year]  Storage Efficiency (GWh/GWh)
    StorageFraction::VariableArray{2} = ReadDisk(db,"EGInput/StorageFraction",year) #[Plant,Area,Year]  Storage as a Fraction of Wind Developed (MW/MW)
    StorageSwitch::VariableArray{1} = ReadDisk(db,"EGInput/StorageSwitch") #[Plant]  Storage Technology Switch (1=Storage)
    # StorageUnitCosts::VariableArray{1} = ReadDisk(db, "EGOutput/StorageUnitCosts", year) #[Area,Year]  Storage Energy Unit Costs ($/MWh)
    StorageUnitCostsPrior::VariableArray{1} = ReadDisk(db,"EGOutput/StorageUnitCosts",prior) #[Area,Year]  Storage Energy Unit Costs ($/MWh)
    Subsidy::VariableArray{2} = ReadDisk(db,"EGInput/Subsidy",year) #[Plant,Area,Year]  Generating Capacity Subsidy ($/MWh)
    TaxR::VariableArray{1} = ReadDisk(db,"EGInput/TaxR",year) #[Area,Year]  Income Tax Rate ($/$)
    TPRMap::VariableArray{2} = ReadDisk(db,"EGInput/TPRMap") #[TimeP,Power]  TimeP to Power Map
    UnArea::SetArray = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
    UnCode::SetArray = ReadDisk(db,"EGInput/UnCode") #[Unit]  Unit Code
    UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
    UnCounter::VariableArray{1} = [ReadDisk(db,"EGInput/UnCounter",year)] #[Year]  Number of Units
    UnCounterPrior::VariableArray{1} = [ReadDisk(db,"EGInput/UnCounter",prior)] #[Year]  Number of Units
    UnCoverage::VariableArray{2} = ReadDisk(db,"EGInput/UnCoverage",year) #[Unit,Poll,Year]  Fraction of Unit Covered in Emission Market (1=100% Covered)
    UnCUC::VariableArray{1} = ReadDisk(db,"EGOutput/UnCUC",year) #[Unit,Year]  Capacity Under Construction (MW)
    UnCUCPrior::VariableArray{1} = ReadDisk(db,"EGOutput/UnCUC",prior) #[Unit,Prior]  Capacity Under Construction in Prior Year (MW)
    UnCW::VariableArray{1} = ReadDisk(db,"EGOutput/UnCW",year) #[Unit,Year]  Construction Costs ($M/Yr)
    UnCWAC::VariableArray{1} = ReadDisk(db,"EGOutput/UnCWAC",year) #[Unit,Year]  Construction Costs Accumulated ($M)
    UnCWGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnCWGA",year) #[Unit,Year]  Construction Costs to Gross AsSets ($M)
    UnEAF::VariableArray{2} = ReadDisk(db,"EGInput/UnEAF",year) #[Unit,Month,Year]  Energy Avaliability Factor (MWh/MWh)
    UnEffStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnEffStorage") #[Unit]  Storage Efficiency (GWH/GWH)
    UnEmit::VariableArray{1} = ReadDisk(db,"EGInput/UnEmit") #[Unit]  Does this Unit Emit Pollution? (1=Yes)
    # UnF1::SetArray = ReadDisk(db,"EGInput/UnF1") #[Unit]  Fuel Source 1
    UnFacility::SetArray = ReadDisk(db,"EGInput/UnFacility") #[Unit]  Facility Name
    UnFlFrMax::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrMax",year) #[Unit,FuelEP,Year]  Fuel Fraction Maximum (Btu/Btu)
    UnFlFrMin::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrMin",year) #[Unit,FuelEP,Year]  Fuel Fraction Minimum (Btu/Btu)
    UnFlFrMSM0::VariableArray{2} = ReadDisk(db,"EGCalDB/UnFlFrMSM0",year) #[Unit,FuelEP,Year]  Fuel Fraction Non-Price Factor (Btu/Btu)
    UnFlFrTime::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrTime",year) #[Unit,FuelEP,Year]  Fuel Adjustment Time (Years)
    UnFlFrVF::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrVF") #[Unit,FuelEP]  Fuel Fraction Variance Factor (Btu/Btu)
    UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Generating Capacity (MW)
    UnGCPrior::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",prior) #[Unit,Prior]  Generating Capacity in Prior Year (MW)
    UnGCCC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGCCC",year) #[Unit,Year]  Generating Unit Capital Cost ($/KW)
    UnGCCI::VariableArray{1} = ReadDisk(db,"EGOutput/UnGCCI",year) #[Unit,Year]  Generating Capacity Initiated (MW)
    UnGCCE::VariableArray{2} = ReadDisk(db,"EGOutput/UnGCCE") #[Unit,Year]  Endogenous Generating Capacity Completed (MW)
    UnGCCR::VariableArray{1} = ReadDisk(db,"EGOutput/UnGCCR",year) #[Unit,Year]  Generating Capacity Completed (MW)
    UnGenCo::SetArray = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
    UnHRt::VariableArray{1} = ReadDisk(db,"EGInput/UnHRt",year) #[Unit,Year]  Heat Rate (BTU/KWh)
    UnMECX::VariableArray{2} = ReadDisk(db,"EGInput/UnMECX",year) #[Unit,Poll,Year]  Process Pollution Coefficient (Tonnes/GWh)
    UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") #[Unit]  Must Run Switch (1=Must Run)
    UnName::SetArray = ReadDisk(db,"EGInput/UnName") #[Unit]  Plant Name
    UnNation::SetArray = ReadDisk(db,"EGInput/UnNation") #[Unit]  Nation
    UnNewNumber::VariableArray{4} = ReadDisk(db,"EGInput/UnNewNumber",year) #[Plant,Node,GenCo,Area,Year]  Unit Number for New Unit
    UnNewNumberPrior::VariableArray{4} = ReadDisk(db,"EGInput/UnNewNumber",prior) #[Plant,Node,GenCo,Area,Year]  Unit Number for New Unit
    UnNode::SetArray = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
    UnOffsets::VariableArray{2} = ReadDisk(db,"EGInput/UnOffsets",year) #[Unit,Poll,Year]  Offsets (Tonnes/GWh)
    UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
    UnOR::VariableArray{3} = ReadDisk(db,"EGInput/UnOR",year) #[Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
    UnOwner::SetArray = ReadDisk(db,"EGInput/UnOwner") #[Unit]  Generating Company
    UnPointer::VariableArray{4} = ReadDisk(db,"EGInput/UnPointer",year) #[Plant,Node,GenCo,Area,Year]  Unit Pointer
    UnPointerPrior::VariableArray{4} = ReadDisk(db,"EGInput/UnPointer",prior) #[Plant,Node,GenCo,Area,Year]  Unit Pointer
    UnPlant::SetArray = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
    UnPOCX::VariableArray{3} = ReadDisk(db,"EGInput/UnPOCX",year) #[Unit,FuelEP,Poll,Year]  Pollution Coefficient (Tonnes/TBtu)
    UnPoTRExo::VariableArray{1} = ReadDisk(db,"EGInput/UnPoTRExo",year) #[Unit,Year]  Exogenous Pollution Tax Rate (Real $/MWh)
    UnRAv::VariableArray{1} = ReadDisk(db,"EGInput/UnRAv") #[Unit]  Reserves Available (MW/MW)
    UnRetire::VariableArray{1} = ReadDisk(db,"EGInput/UnRetire",year) #[Unit,Year]  Retirement Date (Year)
    UnRetireYr::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") #[Unit,Year]  Retirement Date (Year)
    UnRRq::VariableArray{1} = ReadDisk(db,"EGInput/UnRRq") #[Unit]  Reserve Requirements (MW/MW)
    UnRSwitch::VariableArray{1} = ReadDisk(db,"EGInput/UnRSwitch") #[Unit]  Switch for Units Forced to Supply Reserve Requirements (1=Yes)
    UnSector::SetArray = ReadDisk(db,"EGInput/UnSector") #[Unit]  Unit Type (Utility or Industry)
    UnSource::VariableArray{1} = ReadDisk(db,"EGInput/UnSource") #[Unit]  Source (1=Endogenous,0 = Exogenous)
    UnSqFr::VariableArray{2} = ReadDisk(db,"EGInput/UnSqFr",year) #[Unit,Poll,Year]  Sequestered Pollution Fraction (Tonnes/Tonnes)
    UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") #[Unit]  Storage Switch (1=Storage Unit)
    UnUFOMC::VariableArray{1} = ReadDisk(db,"EGInput/UnUFOMC",year) #[Unit,Year]  Fixed O&M Costs ($/Kw/Yr)
    UnUOMC::VariableArray{1} = ReadDisk(db,"EGInput/UnUOMC",year) #[Unit,Year]  Variable O&M Costs ($/MWh)
    UnZeroFr::VariableArray{3} = ReadDisk(db,"EGInput/UnZeroFr",year) #[Unit,FuelEP,Poll,Year]  Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
    UFOMC::VariableArray{2} = ReadDisk(db,"EGInput/UFOMC",year) #[Plant,Area,Year]  Unit Fixed O&M Costs ($/KW)
    UOMC::VariableArray{2} = ReadDisk(db,"EGInput/UOMC",year) #[Plant,Area,Year]  Unit O&M Costs ($/MWh)
    USMT::VariableArray{1} = ReadDisk(db,"EGInput/USMT") #[Horizon]  Smoothing Time (Year)
    WCC::VariableArray{1} = ReadDisk(db,"EGInput/WCC",year) #[Area,Year]  Weighted Cost of Capital ($/($/Yr))
    xGCPot::VariableArray{3} = ReadDisk(db,"EGInput/xGCPot",year) #[Plant,Node,Area,Year]  Exogenous Maximum Potential Generation Capacity (MW)
    xRnImports::VariableArray{1} = ReadDisk(db,"EGInput/xRnImports",year) #[Area,Year]  Exogenous Renewable Generation Imports (GWh/Yr)
    xUnGCCC::VariableArray{1} = ReadDisk(db,"EGInput/xUnGCCC",year) #[Unit,Year]  Generating Unit Capital Cost (Real $/KW)
    xUnGCCI::VariableArray{1} = ReadDisk(db,"EGInput/xUnGCCI",year) #[Unit,Year]  Exogenous Generating Capacity Initiated (MW)
    xUnGCCR::VariableArray{1} = ReadDisk(db,"EGInput/xUnGCCR",year) #[Unit,Year]  Exogenous Generating Capacity Completion Rate (MW)
    xUnGCCRNext::VariableArray{1} = ReadDisk(db,"EGInput/xUnGCCR",next) #[Unit,Year]  Exogenous Generating Capacity Completion Rate (MW)
    xUnGCCRNext1::VariableArray{1} = ReadDisk(db,"EGInput/xUnGCCR",next1) #[Unit,Year]  Exogenous Generating Capacity Completion Rate (MW)
    ZeroFr::VariableArray{3} = ReadDisk(db,"SInput/ZeroFr",year) #[FuelEP,Poll,Area,Year]  Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
    
    #
    # Scratch variables
    #
    AreaCap::VariableArray{1} = zeros(Float32,size(Area,1)) # Area Capacity (MW)
    FITMAW::VariableArray{2} = zeros(Float32,size(Plant,1),size(Area,1)) # Feed-In Tariff Marginal Allocation Weight ($/$)
    FPFEP::VariableArray{2} = zeros(Float32,size(FuelEP,1),size(Area,1)) # [FuelEP,Area]  Delivered Fuel Price ($/mmBtu)
    GCAvail::VariableArray{3} = zeros(Float32,size(Plant,1),size(Node,1),size(Area,1)) # Generating Capacity Available to be Built (MW)
    GCPlanned::VariableArray{3} = zeros(Float32,size(Plant,1),size(Node,1),size(Area,1)) # Generating Capacity Planned to Build (MW)
    GCPotA::VariableArray{2} = zeros(Float32,size(Plant,1),size(Area,1)) # Generating Capacity Potential (MW)
    GCDevA::VariableArray{2} = zeros(Float32,size(Plant,1),size(Area,1)) # Generating Capacity Developed (MW)
    GCTCBase::VariableArray{2} = zeros(Float32,size(Plant,1),size(Nation,1)) # Generating Capacity Baseline for ETC Equation (MW)
    HDIPGCPlant::Float32 = 0.0 # HDIPGC scaled by plant type for a specific GenCo, Area, Node, Power and Plant (MW)
    RnEGUC::VariableArray{1} = zeros(Float32,size(Area,1)) # Renewable Generation Under Construction (GWh)
    RnMAW::VariableArray{4} = zeros(Float32,size(Plant,1),size(Node,1),size(GenCo,1),size(Area,1)) # Renewable Market Share Allocation Weight
    RnTAW::VariableArray{1} = zeros(Float32,size(Area,1)) # Renewable Total Market Share Allocation Weight
    # NewNum::SetArray = fill("",1) # New Unit Number
    NewNum::SetArray = [""] # New Unit Number

    # CgInvUnit::VariableArray{2} = zeros(Float32, size(ECC,1), size(Area,1)) # Area Capacity (MW)

  end

  function GetUnitSets(data::Data,unit)
    (; Area,GenCo,Node,Plant) = data
    (; UnArea,UnGenCo,UnNode,UnPlant) = data

    plant = Select(Plant,UnPlant[unit])
    node = Select(Node,UnNode[unit])
    genco = Select(GenCo,UnGenCo[unit])
    area = Select(Area,UnArea[unit])

    return plant,node,genco,area
  end

  function ResetUnitSets(data::Data)
  end

  function GetUtilityUnits(data::Data)
    (; UnCounter,UnCogen) = data

    #
    # @info "ECapacityExpansion.jl - GetUtilityUnits"
    #
    UtilityUnits = 1:UnCounter[1]
    UtilityUnits = [u for u in UtilityUnits if u in Select(UnCogen, ==(0))]
    return UtilityUnits
  end

  function GetCogenUnits(data::Data)
    (; UnCounter,UnCogen) = data

    #
    # @info "ECapacityExpansion.jl - GetCogenUnits"
    #
    CgUnits = 1:UnCounter[1]
    CgUnits = [u for u in CgUnits if u in Select(UnCogen, !=(0))]
    return CgUnits
  end

  function InitializeCapacityExpansion(data::Data)
    (; db,year) = data
    (; UnCUC,UnCW,UnCWAC,UnCWGA,UnGC,UnGCCI,UnGCCR) = data

    #
    #@info "ECapacityExpansion - InitializeCapacityExpansion"
    #
    @. UnCUC = 0
    @. UnCW = 0
    @. UnCWAC = 0
    @. UnCWGA = 0
    @. UnGC = 0
    @. UnGCCI = 0
    @. UnGCCR = 0

    WriteDisk(db,"EGOutput/UnCUC",year,UnCUC)
    WriteDisk(db,"EGOutput/UnCW",year,UnCW)
    WriteDisk(db,"EGOutput/UnCWAC",year,UnCWAC)
    WriteDisk(db,"EGOutput/UnCWGA",year,UnCWGA)
    WriteDisk(db,"EGOutput/UnGC",year,UnGC)
    WriteDisk(db,"EGOutput/UnGCCI",year,UnGCCI)
    WriteDisk(db,"EGOutput/UnGCCR",year,UnGCCR)
  
  end

  function FirmCapacityFromPowerContracts(data::Data)
    (; db,year,current,Final) = data
    (; Months,Nodes,NodeXs,TimePs) = data
    (; HDInflow,HDFlowFr,HDOutflow,HDXLoad,HDXLoadMax,USMT) = data

    #
    @debug "ECapacityExpansion.jl - FirmCapacityFromPowerContracts"
    
    horizon = 1    
    # horizon = Select(Horizon,"Peak") TODO add in once database is fixed - Jeff Amlin 5/8/25

    HorizonYear = Int(min(current+USMT[horizon],Final))
    for node in Nodes, nodex in NodeXs
      HDXLoadMax[node,nodex] = maximum(HDXLoad[node,nodex,timep,month,HorizonYear]
        for timep in TimePs, month in Months)
    end

    for node in Nodes
      HDInflow[node] = sum(HDXLoadMax[node,from_node]*HDFlowFr[node,from_node]
        for from_node in NodeXs)
    end
    
    for node in Nodes     
      HDOutflow[node] = sum(HDXLoadMax[to_node,node]*HDFlowFr[to_node,node]
        for to_node in Nodes)
    end

    WriteDisk(db,"EGOutput/HDInflow",year,HDInflow)
    WriteDisk(db,"EGOutput/HDOutflow",year,HDOutflow)
  end

  function CapacityRequirementsForecast(data::Data)
    (; db,CTime,year,current) = data
    (; Months,Node,Nodes,TimePs) = data
    (; DRM,HDGR,HDOutflow,HDPDP,HDPDP1) = data
    (; HDPDPSM,HDPDPSMPrior,HDRQ,USMT) = data

    #
    @debug "ECapacityExpansion.jl - CapacityRequirementsForecast"
    #
    
    
    #
    # Forecast based on maximum load across TimeP and Month
    #
    for node in Nodes
      HDPDP1[node] = maximum(HDPDP[node,timep,month] for month in Months, timep in TimePs)
    end
    WriteDisk(db,"EGOutput/HDPDP1",year,HDPDP1)
    
    #
    # Forecast Peak Growth Rate
    #
    if current == Future
      @. HDPDPSMPrior = HDPDP1
    end
    
    horizon = 1    
    # horizon = Select(Horizon,"Peak") TODO add in once database is fixed - Jeff Amlin 5/8/25
    
    for node in Nodes
      HDPDPSM[node] = HDPDPSMPrior[node]+(HDPDP1[node]-HDPDPSMPrior[node])/USMT[horizon]
    end
    WriteDisk(db,"EGOutput/HDPDPSM",year,HDPDPSM)
    
    for node in Nodes
      @finite_math HDGR[node] = (HDPDP1[node]/HDPDPSM[node]-1)/USMT[horizon]
    end
    WriteDisk(db,"EGOutput/HDGR",year,HDGR)    
    
    #
    # Forecast Capacity Requirements
    #
    for node in Nodes
      HDRQ[node] = HDPDP1[node]*(1+DRM[node]+HDGR[node]*USMT[horizon])+
                   HDOutflow[node]*(1+DRM[node])
    end
    WriteDisk(db,"EGOutput/HDRQ",year,HDRQ)
    
  end

  function FirmCapacityFromExistingUnits(data::Data)
    (; db,current,next,next1,year,Yrv) = data
    (; CapCredit,HDGC,HDGCCR,HDCUC,HDRetire,UnCUCPrior,UnGCPrior,UnOnLine,UnRetire) = data
    (; xUnGCCR,xUnGCCRNext,xUnGCCRNext1) = data

    #
    #@debug "ECapacityExpansion.jl - FirmCapacityFromExistingUnits"
    #
    @. HDGC = 0
    @. HDCUC = 0
    @. HDRetire = 0
    @. HDGCCR = 0
    #
    #
    UtilityUnits = round.(Int,GetUtilityUnits(data))
    for unit in UtilityUnits
      plant,node,genco,area = GetUnitSets(data,unit)
      if UnOnLine[unit] <= Yrv[current] && UnRetire[unit] >= Yrv[current]
        HDGC[node] = HDGC[node]+UnGCPrior[unit]*CapCredit[plant,area]
      end
      #

      if UnRetire[unit] == Yrv[current] || UnRetire[unit] == Yrv[next] || UnRetire[unit] == Yrv[next1]
        HDRetire[node] = HDRetire[node]+UnGCPrior[unit]*CapCredit[plant,area]
      end

      #
      # Add negative adjustments to capacity to retirements (check and test - 
      # double counting?)
      #
      HDGCCR[node] = HDGCCR[node]+max(0,0-(xUnGCCR[unit]+
        xUnGCCRNext[unit]+xUnGCCRNext1[unit]))*CapCredit[plant,area]
      
      #
      HDCUC[node] = HDCUC[node]+UnCUCPrior[unit]*CapCredit[plant,area]
    end
    WriteDisk(db,"EGOutput/HDCUC",year,HDCUC)
    WriteDisk(db,"EGOutput/HDGC",year,HDGC)
    WriteDisk(db,"EGOutput/HDGCCR",year,HDGCCR)
    WriteDisk(db,"EGOutput/HDRetire",year,HDRetire)
  end

  function FirmCogenerationCapacitySoldToGrid(data::Data)
    (; db,current,ECC,next,next1,year,Yrv) = data
    (; UnRetire,CapCredit,UnCogen) = data
    (; CgECPrior,HDCgGC,PSoECCPrior,UnCUCPrior,UnGCPrior) = data
    (; UnOnLine,UnSector,xUnGCCR,xUnGCCRNext,xUnGCCRNext1) = data

    #
    #@debug "ECapacityExpansion.jl - FirmCogenerationCapacitySoldToGrid"
    #
    @. HDCgGC = 0
    HDCgCUC = zeros(size(HDCgGC))
    HDCgRetire = zeros(size(HDCgGC))
    #
    CgUnits = round.(Int,GetCogenUnits(data))
    for unit in CgUnits
      if UnCogen[unit] !=0
        plant,node,genco,area = GetUnitSets(data,unit)
        ecc = Select(ECC,UnSector[unit])
        if (UnOnLine[unit] <= Yrv[current]) && (UnRetire[unit] >= Yrv[current])
          @finite_math HDCgGC[node] = HDCgGC[node]+UnGCPrior[unit] *
            CapCredit[plant,area]/CgECPrior[ecc,area]*PSoECCPrior[ecc,area]
        end
        if UnRetire[unit] == Yrv[current] || UnRetire[unit] == Yrv[next] || UnRetire[unit] == Yrv[next1]
          @finite_math HDCgRetire[node] = HDCgRetire[node]+UnGCPrior[unit] *
            CapCredit[plant,area]/CgECPrior[ecc,area]*PSoECCPrior[ecc,area]
        end
        
        HDCgRetire[node] = HDCgRetire[node]+max(0,0-(xUnGCCR[unit]+
          xUnGCCRNext[unit]+xUnGCCRNext1[unit]))*CapCredit[plant,area]
        # @. HDCgRetire=HDCgRetire+UnGCPrior*CapCredit # code from CER project
        #
        HDCgCUC[node] = HDCgCUC[node]+UnCUCPrior[unit]*CapCredit[plant,area]
      end
    end
    @. HDCgGC = HDCgGC-HDCgRetire+HDCgCUC
    # @. HDCgGC=HDCgGC+UnGCPrior*CapCredit # code from CER project
    WriteDisk(db,"EGOutput/HDCgGC",year,HDCgGC)

  end

  function FirmCapacityAvailable(data::Data)
    (; db,year) = data
    (; HDFGC,HDGC,HDGCCR,HDCUC,HDRetire,HDCgGC,HDInflow) = data
    (; HDRM,HDPDP1,HDGR,USMT,HDOutflow) = data

    #
    #@debug "ECapacityExpansion.jl - FirmCapacityAvailable"
    #
    # Forecast Capacity which will exist
    #
    @. HDFGC = HDGC+HDCUC-HDRetire-HDGCCR+HDCgGC+HDInflow
    WriteDisk(db,"EGOutput/HDFGC",year,HDFGC)
    #
    # Reserve Margin
    #
    @. @finite_math HDRM = HDFGC/(HDPDP1*(1+HDGR*USMT[1])+HDOutflow) - 1
    WriteDisk(db,"EGOutput/HDRM",year,HDRM)
  end

  function CapacityAlreadyDeveloped(data::Data)
    (; Plants,Nodes,GenCos,Areas) = data
    (; GCDev,GCArPrior,PCUCPrior) = data

    #
    #@debug "ECapacityExpansion.jl - CapacityAlreadyDeveloped"
    #
    # Capacity Already Developed including Capacity Under Construction (PCUC)
    #
    # Does this equation work?  Please send a note if it does - Jeff Amlin 1/4/24
    #
    # GCDev .= sum(GCArPrior[Plants,Nodes,genco,Areas] +
    #   PCUCPrior[Plants,Nodes,genco,Areas] for genco in GenCos)
    #
    # Looking at results, it seems like it is working, but using old
    # equation style by preference for now. - Luke Davulis, 24.02.08
    #
    for area in Areas, node in Nodes, plant in Plants
      GCDev[plant,node,area] = sum(GCArPrior[plant,node,genco,area] +
        PCUCPrior[plant,node,genco,area] for genco in GenCos)
    end
    
  end

  function CapitalCostMultiplierFromDepletion(data::Data)
    (; db,year) = data
    (; Areas,Nodes,Plant,Plants) = data
    (; GCCCFlag,GCCCM,GCDev,GCDevA,GCPot,GCPotA,xGCPot,StorageFraction) = data

    #
    #@debug "ECapacityExpansion.jl - CapitalCostMultiplierFromDepletion"
    #
    @. GCPot = xGCPot
    #

    OtherStorage = Select(Plant,"Battery")
    OnshoreWind = Select(Plant,"OnshoreWind")
    for area in Areas
      if StorageFraction[OtherStorage,area] > 0.0
        for node in Nodes
          GCPot[OtherStorage,node,area] = GCDev[OnshoreWind,node,area]*StorageFraction[OtherStorage,area]
        end
      else
        for node in Nodes
          GCPot[OtherStorage,node,area] = xGCPot[OtherStorage,node,area]
        end
      end
    end

    #
    for plant in Plants, area in Areas
      GCPotA[plant,area] = sum(GCPot[plant,node,area] for node in Nodes)
      GCDevA[plant,area] = sum(GCDev[plant,node,area] for node in Nodes)
    end
    
    #
    for area in Areas, plant in Plants
      
      #
      # Capital cost increases as potential is depleted
      #
      if GCCCFlag[plant,area] == 1
        @finite_math GCCCM[plant,area] = max(GCPotA[plant,area]/
                           (max(0.0001,GCPotA[plant,area]-GCDevA[plant,area])),1)
        
        #
        # Capital cost does not increase until all is developed.
        #
      elseif GCCCFlag[plant,area] == 2
        if GCPotA[plant,area] > GCDevA[plant,area]
          GCCCM[plant,area] = 1
        else
          GCCCM[plant,area] = 1e12
        end
      else
        
        #
        # Capital cost does not change
        #
        GCCCM[plant,area] = 1
      end
    end
    WriteDisk(db,"EGOutput/GCCCM",year,GCCCM)
    WriteDisk(db,"EGOutput/GCDev",year,GCDev)
    WriteDisk(db,"EGOutput/GCPot",year,GCPot)
  end

  function CapitalCostMultiplierFromETC(data::Data)
    (; db,CTime,year) = data
    (; Areas,Nations,Plant,Plants) = data
    (; ANMap,GCPAPrior,GCTC,GCTCBase,GCTCB0,GCTCLast,GCTCMap,GCTCM,GCTCMLast,PjMnPS) = data



    #
    #@debug "ECapacityExpansion.jl - CapitalCostMultiplierFromETC"
    #
    WindPlants = Select(Plant,["OnshoreWind","OffshoreWind"])
    SolarPlants = Select(Plant,["SolarPV","SolarThermal"])

    for nation in Nations
      
      #
      # Capacity for Endogenous Technological Change
      #
      for plant in Plants
        GCTC[plant,nation] = max(sum(GCPAPrior[plant,area]*GCTCMap[area,nation] for area in Areas),
                                 maximum(PjMnPS[plant,area] for area in Areas))
      end
      
      #
      # Baseline for ETC Multiplier (use of Plant and P is intended)
      #
      @. GCTCBase = GCTCLast
      for plant in WindPlants
        GCTCBase[plant,nation] = sum(GCTCLast[p,nation] for p in WindPlants)
      end
      for plant in SolarPlants
        GCTCBase[plant,nation] = sum(GCTCLast[p,nation] for p in SolarPlants)
      end
      
      #
      # Capital Cost Multiplier from Endogenous Technological Change
      #
      for area in Areas
        if ANMap[area,nation] == 1
          if CTime > HisTime
            for plant in Plants
              @finite_math GCTCM[plant,area] = GCTCMLast[plant,area]*
                min((GCTC[plant,nation]/GCTCBase[plant,nation])^GCTCB0[plant,nation],1.0)
            end
          else
            for plant in Plants
              GCTCM[plant,area] = 1.0
            end
          end
        end
      end
    end
    WriteDisk(db,"EGOutput/GCTC",year,GCTC)
    WriteDisk(db,"EGOutput/GCTCM",year,GCTCM)
  end

  function CapacityCapitalCost(data::Data)
    (; db,year) = data
    (; Areas,Plants) = data
    (; GCCC,GCCCN,GCCCM,GCTCM,Inflation) = data

    #
    #@debug "ECapacityExpansion.jl - CapacityCapitalCost"
    #
    for plant in Plants, area in Areas
      GCCC[plant,area] = GCCCN[plant,area]*GCCCM[plant,area]*GCTCM[plant,area]*Inflation[area]
    end
    WriteDisk(db,"EGOutput/GCCC",year,GCCC)
  end

  function FuelPrices(data::Data)
    (; db,year) = data
    (; Areas,ES,Fuels,FuelEPs,Plants) = data
    (; FPF,FFPMap,FPEU,FPFEP,FlFrNew) = data

    #
    #@debug "ECapacityExpansion.jl - FuelPrices"
    #
    # Map Fuel Prices to Plant Types
    #
    es = Select(ES,"Electric")
    for fuelep in FuelEPs, area in Areas
      FPFEP[fuelep,area] = sum(FPF[fuel,es,area]*FFPMap[fuelep,fuel] for fuel in Select(Fuels))
    end
    #
    for plant in Plants, area in Areas
      FPEU[plant,area] = sum(FPFEP[fuelep,area]*FlFrNew[fuelep,plant,area] for fuelep in Select(FuelEPs))
    end
    WriteDisk(db,"EGOutput/FPEU",year,FPEU)
  end

  function ProjectCosts(data::Data)
    (; db,year) = data
    (; Areas,Plants,Powers) = data
    (; CCR,DIVTC,DRisk,GCBL,GCTL,InSm, StorageUnitCostsPrior,TaxR,WCC) = data
    (; GCCC,Inflation,MCE,MFC,UFOMC) = data
    (; MVC,UOMC,FPEU,HRtM,PoTRNew,PoTRNewExo,StorageSwitch) = data
    (; DesHr,Subsidy) = data

    #   
    # TODOJulia - keep track of PCUCPrior?
    #
    #@debug "ECapacityExpansion.jl - Generation Project Costs"
    #
    for plant in Plants, area in Areas
      #
      # Capital Charge Rate
      #
      @finite_math CCR[plant,area] = (1-DIVTC[plant,area]/(1+WCC[area]+DRisk[plant,area]+InSm[area])-
        TaxR[area]*(2/GCTL[plant,area])/(WCC[area]+DRisk[plant,area]+InSm[area]+2/GCTL[plant,area]))*
        (WCC[area]+DRisk[plant,area])/(1-(1/(1+WCC[area]+DRisk[plant,area])) ^ GCBL[plant,area])/(1-TaxR[area])
      
      #
      # Fixed Costs of New Plants ($/KW)
      #
      MFC[plant,area] = CCR[plant,area]*GCCC[plant,area]+UFOMC[plant,area]*Inflation[area]
      
      #
      # Variable Costs of New Plants ($/MWh)
      #
      MVC[plant,area] = UOMC[plant,area]*Inflation[area]+FPEU[plant,area] *
        HRtM[plant,area]/1000+PoTRNew[plant,area]+PoTRNewExo[plant,area]*Inflation[area]
      #
      if StorageSwitch[plant] == 1
        MVC[plant,area] = StorageUnitCostsPrior[area]+UOMC[plant,area]*Inflation[area] +
          PoTRNew[plant,area]+PoTRNewExo[plant,area]*Inflation[area]
      end
      
      #
      # The average cost per MWh (MCE) is computed by combining the variable costs
      # (MVC) and the fixed costs (MFC) using the design hours of operation (DesHr).
      #
      for power in Powers
        @finite_math MCE[plant,power,area] = MVC[plant,area]+MFC[plant,area]/
          DesHr[plant,power,area]*1000-Subsidy[plant,area]
      end
    end
    WriteDisk(db,"EGOutput/CCR",year,CCR)
    WriteDisk(db,"EOutput/MCE",year,MCE)
    WriteDisk(db,"EOutput/MFC",year,MFC)
    WriteDisk(db,"EOutput/MVC",year,MVC)
  end

  function CapacityUnderConstructionMultiplier(data::Data)
    (; db,year,Nodes) = data
    (; CUCFr,CUCLimit,CUCMlt,HDCUC,HDGC) = data

    #
    #@debug "ECapacityExpansion.jl - CapacityUnderConstructionMultiplier"
    #
    # The build decision is increasingly constrained (by CUCMlt) as the capacity under
    # construction as a fraction of total capacity (CUCFr) approaches a limit (CUCLimit).
    #
    @finite_math @. CUCFr = HDCUC/HDGC
    for node in Nodes
      @finite_math CUCMlt[node] = max(1-min(CUCFr[node],CUCLimit)/CUCLimit,CUCLimit)
    end
    WriteDisk(db,"EGOutput/CUCFr",year,CUCFr)
    WriteDisk(db,"EGOutput/CUCMlt",year,CUCMlt)
  end

  function BuildFractionBasedOnClearingPrice(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Months,Node,Nodes,Plants,Powers,TimePs) = data
    (; BFracMax,GCDev,GCExpSw,GCPot,HDPrAPrior,HDHours,PjNSw) = data
    (; HDPrDP,HDPrDPPrior,HDPrDPPrior2,HDPrDPPrior3,HDPrDPPrior4) = data
    (; BFraction,MCE,PrDiFr,PriceDiff,PriceDiffGR,TPRMap) = data

    #
    #@debug "ECapacityExpansion.jl - BuildFractionBasedOnClearingPrice"
    #
    for power in Powers, area in Areas, genco in GenCos
      
      #
      # Select the Nodes where this GenCo builds
      #
      for node in Nodes
        if PjNSw[node,genco,area] == 1
          
          #
          # Select the time periods for this Power type
          #
          timeps = Select(TPRMap[TimePs,power], ==(1))
         
          #
          # The decision price (HDPrDP) is the price expected for the Power from 
          # the new Plant which is the average spot market price (HDPrA) for the
          # hours in each time period
          #
          TotHrs = sum(HDHours[timep,month] for timep in timeps, month in Months)
          
          @finite_math HDPrDP[power,node] = sum(HDPrAPrior[node,timep,month]*
            HDHours[timep,month] for timep in timeps, month in Months)/TotHrs
         
          #
          # Select the plants available for construction
          #
          plants1 = findall(GCPot[Plants,node,area] .> GCDev[Plants,node,area])
          plants2 = findall(GCExpSw[Plants] .== 1)
          plants = intersect(plants1,plants2)
          if !isempty(plants)

            #
            # Sort Plant type to bring the cheapest Plant type to the first entry
            #
            plants_sorted = plants[sortperm(MCE[plants,power,area])]
            plant = plants_sorted[1]            
            
            #
            # Price differential for new capacity
            #          
            MCE[plant,power,area] = max(MCE[plant,power,area],0.01)            
            PriceDiff[power,node,area] =
                              (HDPrDP[power,node]      -MCE[plant,power,area])/MCE[plant,power,area]
            PriceDiffPrior =  (HDPrDPPrior[power,node] -MCE[plant,power,area])/MCE[plant,power,area]
            PriceDiffPrior2 = (HDPrDPPrior2[power,node]-MCE[plant,power,area])/MCE[plant,power,area]
            PriceDiffPrior3 = (HDPrDPPrior3[power,node]-MCE[plant,power,area])/MCE[plant,power,area]
            PriceDiffPrior4 = (HDPrDPPrior4[power,node]-MCE[plant,power,area])/MCE[plant,power,area]            
            
            #
            # Price differential growth rate
            #
            PriceDiffShort = (PriceDiff[power,node,area]+PriceDiffPrior)/2
            PriceDiffLong = (PriceDiff[power,node,area]+PriceDiffPrior +
              PriceDiffPrior2+PriceDiffPrior3+PriceDiffPrior4)/5
            @finite_math PriceDiffGR[power,node,area] =
              (PriceDiffShort-PriceDiffLong)/abs(PriceDiffLong)
            
            #
            # The fraction of new capacity to be constructed.
            #
            if PriceDiff[power,node,area] >= 0.0
              BFraction[power,node,area] = min(max(PrDiFr[power,area]*PriceDiffGR[power,node,area],0),BFracMax[area])
            else
              BFraction[power,node,area] = 0
            end
            
          end
        end
      end
    end
    WriteDisk(db,"EGOutput/BFraction",year,BFraction)
    WriteDisk(db,"EGOutput/HDPrDP",year,HDPrDP)
    WriteDisk(db,"EGOutput/PriceDiff",year,PriceDiff)
    WriteDisk(db,"EGOutput/PriceDiffGR",year,PriceDiffGR)
  end

  function CapacityNeededBasedOnClearingPrice(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Nodes,Powers) = data
    (; BFraction,HDRQ,BuildFr,CUCMlt,IPGCPr,NdArFr,PjNSw) = data

    #
    #@debug "ECapacityExpansion.jl - CapacityNeededBasedOnClearingPrice"
    #
    for power in Powers, node in Nodes, genco in GenCos, area in Areas
      IPGCPr[power,node,genco,area] = HDRQ[node]*NdArFr[node,area] *
        PjNSw[node,genco,area]*BuildFr[area]*BFraction[power,node,area]*CUCMlt[node]
    end
    WriteDisk(db,"EGOutput/IPGCPr",year,IPGCPr)
  end

  function CapacityNeededForReserveMargin(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Nodes,Powers) = data
    (; HDFGC,HDRQ,BuildFr,IPGCRM,NdArFr,PjNSw,PwrFra) = data

    #
    #@debug "ECapacityExpansion.jl - CapacityNeededForReserveMargin"
    #
    for power in Powers, node in Nodes, genco in GenCos, area in Areas
      IPGCRM[power,node,genco,area] = (HDRQ[node]- HDFGC[node])*NdArFr[node,area] *
        PjNSw[node,genco,area]*BuildFr[area]*PwrFra[power,genco]
    end
    WriteDisk(db,"EGOutput/IPGCRM",year,IPGCRM)
  end

  function BuildNewCapacity(data::Data)
    (; db,year) = data
    (; Area,GenCo,GenCos,Nodes,Powers) = data
    (; BuildSw,HDIPGC,IPGCPr,IPGCRM) = data

    #
    #@debug "ECapacityExpansion.jl - BuildNewCapacity"
    #
    for genco in GenCos, area in Select(Area, ==(GenCo[genco]))
      if BuildSw[area] == 0
        # @. HDIPGC[Powers, Nodes, genco, area] = 0
        for node in Nodes, power in Powers
          HDIPGC[power,node,genco,area] = 0
        end
      elseif BuildSw[area] == 5
        # @. HDIPGC[Powers, Nodes, genco, area] = max(IPGCPr[Powers, Nodes, genco, area], IPGCRM[Powers, Nodes, genco, area])
        for node in Nodes, power in Powers
          HDIPGC[power,node,genco,area] = max(IPGCPr[power,node,genco,area],
            IPGCRM[power,node,genco,area])
        end
      elseif BuildSw[area] == 6
        # @. HDIPGC[Powers, Nodes, genco, area] = IPGCRM[Powers, Nodes, genco, area]
        for node in Nodes, power in Powers
          HDIPGC[power,node,genco,area] = IPGCRM[power,node,genco,area]
        end
      elseif BuildSw[area] == 7
        # @. HDIPGC[Powers, Nodes, genco, area] = IPGCPr[Powers, Nodes, genco, area]
        for node in Nodes, power in Powers
          HDIPGC[power,node,genco,area] = IPGCPr[power,node,genco,area]
        end
      else
        # @. HDIPGC[Powers, Nodes, genco, area] = 0
        for node in Nodes, power in Powers
          HDIPGC[power,node,genco,area] = 0
        end
      end
    end
    WriteDisk(db,"EGOutput/HDIPGC",year,HDIPGC)
  end

  function AwardNewCapacityByCost(data::Data,area,genco,node)
    (; Powers,Power) = data
    (; CapCredit,DesHr,DesHrLast,GCDev,GCDevTime) = data
    (; GCPot,HDIPGC,MCE,PJCIHD,PjMax,PjMnPS,ORNew) = data

    #
    # #@debug "ECapacityExpansion.jl - AwardNewCapacityByCost $area, $genco, $node"
   
    #
    # Sort the capacity needed by type of Power (peaking, intermediate
    # and baseload) to determine where Power is needed to most.
    #
    for power in sortperm(HDIPGC[Powers,node,genco,area])
      if HDIPGC[power,node,genco,area] > 0
      
        #
        # Sort the Plant types based on the busbar costs (MCE)
        #
        plants = findall(GCPot[:,node,area] .> GCDev[:,node,area])
        plants_sorted = plants[sortperm(MCE[plants,power,area])]
        for plant in plants_sorted
          if GCPot[plant,node,area] > GCDev[plant,node,area]
            
            #
            # The amount of capacity awarded to each project (PjCIHD) is 
            # based on the amount of Power needed (HDIPGC) and the maximum 
            # (PjMax) and minimum (PjMnPS) project sizes.
            #
            @finite_math PJCIHD[plant,node,power,genco,area] = 
              max(min(HDIPGC[power,node,genco,area],PjMax[plant,area],
              (GCPot[plant,node,area]-GCDev[plant,node,area])/GCDevTime[plant]),0)
              
            # The following change from the CER analysis needs to be analyzed. 
            # The point is to derate the new capacity before we decide to build
            # new capacity of this plant type.  This needs to be checked for 
            # reasonableness and for double derating. We will also want to
            # add the new variable to the database - Jeff Amlin 9/4/24 
            #       
            # Do If PowerKey eq "Base"
            #   HDIPGCPlant = HDIPGC/(DesHr/DesHrLast*(1-ORNew))
            # Else
            #   HDIPGCPlant = HDIPGC/(CapCredit*DesHr/DesHrLast)
            # End Do If 
            # PjCIHD=xmax(xmin(HDIPGCPlant,PjMax,(GCPot-GCDev)/GCDevTime),0)
              
            #
            # Round the amount of capacity (PjCIHD) into an integer number of projects
            #
            @finite_math PJCIHD[plant,node,power,genco,area] =
              round(PJCIHD[plant,node,power,genco,area]/PjMnPS[plant,area]+0.25)*
              PjMnPS[plant,area]
            
            #
            # Subtract capacity awarded (PJCIHD) from capacity needs (HDIPGC)
            # and add the capacity to capacity developed (GCDev)
            #
            if Power[power] == "Base"
              HDIPGC[power,node,genco,area] = HDIPGC[power,node,genco,area]- 
                PJCIHD[plant,node,power,genco,area]* 
                DesHr[plant,power,area]/DesHrLast[plant,power,area]*(1-ORNew[plant,area,1,1]) # TODOPromula: The values for TimeP and Month should be explicit
            else
              HDIPGC[power,node,genco,area] = HDIPGC[power,node,genco,area]- 
                PJCIHD[plant,node,power,genco,area]*CapCredit[plant,area]* 
                DesHr[plant,power,area]/DesHrLast[plant,power,area]
            end

            GCDev[plant,node,area] = GCDev[plant,node,area]+
                                     PJCIHD[plant,node,power,genco,area]
          end
        end
      end
    end
  end

  function AwardNewCapacityByPortfolio(data::Data,area)
    (; db,year) = data
    (; GenCos,Nodes,Plants,Powers) = data
    (; HDIPGC,PJCIHD,PjMax,PjMnPS,Portfolio) = data

    #
    # #@debug "ECapacityExpansion.src - AwardNewCapacityByPortfolio Area = $area"
    #
    # The portfolio fraction (Portfolio) determines the type of plant
    # constructed amount to meet the power requirements (HDIPGC).
    #
    for plant in Plants, power in Powers, node in Nodes, genco in GenCos
      PJCIHD[plant,node,power,genco,area] = max(HDIPGC[power,node,genco,area]*
                                                Portfolio[plant,power,node,area],0)
    #
    # Constrain the capacity constructed to be less than maximum capacity which can be
    # constucted in a singe year (PjMax).
    #
      PJCIHD[plant,node,power,genco,area] = min(PJCIHD[plant,node,power,genco,area],
                                                PjMax[plant,area])
    #
    # Round the amount of capacity (PJCIHD) into an integer number of projects
    #
      @finite_math PJCIHD[plant,node,power,genco,area] =
        round(PJCIHD[plant,node,power,genco,area]/PjMnPS[plant,area]+0.25)*PjMnPS[plant,area]
    end
    WriteDisk(db,"EGOutput/PJCIHD",year,PJCIHD)
  end

  function NewCapacityInitiated(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Nation,Nodes,Plant,Plants,Powers) = data
    (; ANMap,AwardSwitch,HDGCCI,OGCapacity,OGCCFraction,OGCCSmallFraction,PJCIHD,RnSwitch) = data
    (; GCDev,GCPot,MCE,PjNSw,RnMAW,RnMSF,RnMSM,RnTAW,RnVF) = data

    #
    #@debug " ECapacityExpansion.jl - NewCapacityInitiated"
    
    #
    # Award contracts for new capacity using perfect knowledge theory
    # Initialize to zero
    #
    @. PJCIHD = 0
    areas = findall(AwardSwitch[:] .== 1.0)
    for area in areas, genco in GenCos, node in Nodes
      AwardNewCapacityByCost(data,area,genco,node)
    end

    areas = findall(AwardSwitch[:] .== 2.0)
    for area in areas
      AwardNewCapacityByPortfolio(data,area)
    end
    
    #
    # HDGCCI[Plants,Nodes,GenCos,Areas] .= sum(PJCIHD[Plants,Nodes,power,GenCos,Areas] for power in Powers)
    for area in Areas, genco in GenCos, node in Nodes, plant in Plants
      HDGCCI[plant,node,genco,area] = sum(PJCIHD[plant,node,power,genco,area] for power in Powers)
    end
    
    #
    # Allocate new capacity between OGCC and OGCT (in Canada)
    #
    for area in Areas
      if OGCCFraction[area] < 1.00 && ANMap[area,Select(Nation,"CN")] == 1
        plants = Select(Plant,["OGCT","OGCC"])
        for genco in GenCos, node in Nodes 
          # OGCapacity[Nodes,GenCos,area] .= sum(HDGCCI[plant,Nodes,GenCos,area] for plant in ct_cc_plant)
          OGCapacity[node,genco,area] = sum(HDGCCI[plant,node,genco,area] for plant in plants)
        end

        ogct = Select(Plant,"OGCT")
        for node in Nodes, genco in GenCos
          HDGCCI[ogct,node,genco,area] = OGCapacity[node,genco,area]*(1-OGCCFraction[area])
        end

        ogcc = Select(Plant,"OGCC")
        for node in Nodes, genco in GenCos
          HDGCCI[ogcc,node,genco,area] = OGCapacity[node,genco,area]*OGCCFraction[area]*(1-OGCCSmallFraction[area])
        end

        smallogcc = Select(Plant,"SmallOGCC")
        for node in Nodes, genco in GenCos
          HDGCCI[smallogcc,node,genco,area] = OGCapacity[node,genco,area]*OGCCFraction[area]*OGCCSmallFraction[area]
        end
      end
      
      #
      # Endogenously add renewables to meet load in US
      #
      if ANMap[area,Select(Nation,"US")] == 1
        ogcc = Select(Plant,"OGCC")
        for genco in GenCos, node in Nodes 
          OGCapacity[node,genco,area] = HDGCCI[ogcc,node,genco,area]
        end
        renew_plants = Select(RnSwitch[Plants,area],>(0))
        for node in Nodes, genco in GenCos, plant in Select(renew_plants), power in Powers
          @finite_math RnMAW[plant,node,genco,area] = RnMSM[plant,node,genco,area]*max(MCE[plant,power,area],0.01)^RnVF[area] *
            min(max((GCPot[plant,node,area]*0.98-GCDev[plant,node,area])/GCPot[plant,node,area],0.0),1.0)*PjNSw[node,genco,area]
        end
        RnTAW[area] = sum(RnMAW[plant,node,genco,area] for plant in renew_plants, node in Nodes, genco in GenCos)
        for node in Nodes, genco in GenCos, plant in renew_plants
          @finite_math RnMSF[plant,node,genco,area] = RnMAW[plant,node,genco,area]/RnTAW[area]
          @finite_math HDGCCI[plant,node,genco,area] = OGCapacity[node,genco,area]*OGCCFraction[area]*RnMSF[plant,node,genco,area]
        end
      end
    end
    
    WriteDisk(db,"EGOutput/HDGCCI",year,HDGCCI)
    WriteDisk(db,"EGOutput/OGCapacity",year,OGCapacity)
    WriteDisk(db,"EGOutput/RnMSF",year,RnMSF)
    WriteDisk(db,"EGOutput/PJCIHD",year,PJCIHD)
  end

  function OtherCapacity(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Nodes,Plant) = data
    (; ArGenFr,ArNdFr,HDGCCI,ReGCCM,StGCCM) = data


    #
    #@debug "ECapacityExpansion.jl - Generation Other Capacity"
    
    #
    # Capacity initiated in other parts of the model.
    #
    for area in Areas
      #
      # Select the largest Node and GenCo in the Area
      #
      node_sorted = sortperm(ArNdFr[area,Nodes],rev = true)
      node = node_sorted[1]
      genco_sorted = sortperm(ArGenFr[area,GenCos],rev = true)
      genco = genco_sorted[1]
      
      #
      # The changes to electric generation capacity (StGCCM) from the
      #  steam supply sector are added to "Other" (OtherGeneration) capacity.
      #
      for plant in Select(Plant,"OtherGeneration")
        HDGCCI[plant,node,genco,area] = StGCCM[area]
      end
      
      #
      # The changes to electric generating capacity from Landfill
      # Biogas (ReGCCM) are added to "Biogas" capacity.
      #
      for plant in Select(Plant,["Biogas","Waste"])
        HDGCCI[plant,node,genco,area] = ReGCCM[area]
      end
      
    end
      WriteDisk(db,"EGOutput/HDGCCI",year,HDGCCI)
  end

  function BuildIntermittentPower(data::Data,area,genco,node,plant)
    (; Months,Power,TimePs) = data
    (; GrSysFr,HDHours,HDPrAPrior,HDRQ,IPGCCI,IPPrDP,IPTPMap,MCE,MCELimit,NdArFr) = data
    (; GrMSM,PjMax,GCPot,GCDev,GCDevTime) = data

    #
    #@debug "ECapacityExpansion.jl - BuildIntermittentPower"
    #
    
    #
    # Intermittent Plants are built to displace power, the value of
    # this power is the wholesale price during selected time periods.
    #
    # Select time periods for Intermittent Power Price
    #
    timeps = Select(IPTPMap[TimePs,area], ==(1))
    TotHrs = sum(HDHours[time,month] for time in timeps, month in Months)
    @finite_math IPPrDP[node] = sum(HDPrAPrior[node,time,month]*HDHours[time,month] for
      time in timeps, month in Months)/TotHrs
    
    #
    # If the decision price (IPPrDP) is greater than the long run marginal
    # cost (MCE), then build a Plant.
    #
    base = Select(Power,"Base")
    if IPPrDP[node] > MCE[plant,base,area]
    
      #
      # The Intermittent Power Decision Price (IPPrDP) must be greater than
      # the cost (MCE) by more than a specified amount (MCELimit) and the
      # bigger the difference the more capacity is constructed (MCEMlt).
      #
      MCELimit[area] = max(MCELimit[area],0.0001)
      @finite_math MCEMlt = min(IPPrDP[node]/
                            max(MCE[plant,base,area],0.01)-1,MCELimit[area])+1
      
      #
      # New Capacity (IPGCCI) is constrained by system capacity (HDRQ*GrSysFr),
      # allocated to the geographic area (NdArFr), increased with higher
      # prices (MCEMlt), increased with promotion (GrMSM), and constrained by
      # the capacity available for development ((GCPot-GCDev)/GCDevTime).
      #
      IPGCCI[plant,node,genco,area] = min(HDRQ[node]*GrSysFr[node,area]*
        NdArFr[node,area]*MCEMlt*GrMSM[plant,node,area],PjMax[plant,area])
      @finite_math IPGCCI[plant,node,genco,area] = max(min(IPGCCI[plant,node,genco,area],
        (GCPot[plant,node,area]-GCDev[plant,node,area])/GCDevTime[plant]),0)
    else
      IPGCCI[plant,node,genco,area] = 0.0
    end
  end

  function IntermittentPowerExpansion(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Nodes,Plants) = data
    (; PjNSw,IPExpSw,IPGCCI,IPPrDP) = data


    #
    #@debug "ECapacityExpansion.jl - Intermittent Power Expansion"
    
    #
    # For the Generator who are building capacity (code assumes only one
    # generator builds on each Node).
    #
    for genco in GenCos, area in Areas
      
      #
      # Select Buildable Nodes
      #
      for node in Nodes
        if PjNSw[node,genco,area] == 1
        
          #
          # Select Intermittent Power Plant Types
          #
          for plant in Plants
            if IPExpSw[plant,area] == 1
              BuildIntermittentPower(data,area,genco,node,plant)
            end
          end
        end
      end
    end
    WriteDisk(db,"EGOutput/IPGCCI",year,IPGCCI)
    WriteDisk(db,"EGOutput/IPPrDP",year,IPPrDP)
  end

  function BuildCapacityInsideArea(data::Data,areas)
    (; Area,GenCos,Nodes,Plants,Power) = data
    (; GCDev,GCPot,MCE,ORNew,PCUCPrior,PjNSw,RnGenPrior,
      RnEGI,RnEGUC,RnGoal,RnMAW,RnMSF,RnTAW,RnMSM,RnSwitch,
      RnVF,xRnImports) = data

    #
    #@debug "ECapacityExpansion.jl - BuildCapacityInsideArea"
    #
    for area in areas
      #
      # Select renewable plant types (RnSwitch)
      #
      plants = Select(RnSwitch[Plants,area],>(0))
      #
      # Renewable Generation Under Construction
      #
      # TODO Promula: TimeP and Month values should be explicit in ORNew
      RnEGUC[area] = sum(PCUCPrior[plant,node,genco,area]*(1-ORNew[plant,area,1,1]) for
        plant in plants, node in Nodes, genco in GenCos) *8760/1000
      #
      # Determine Market Share of New Generation
      #
      for power in Select(Power,"Base"), plant in plants, node in Nodes, genco in GenCos
        @finite_math RnMAW[plant,node,genco,area] = RnMSM[plant,node,genco,area]*max(MCE[plant,power,area],0.01)^RnVF[area]*
          min(max((GCPot[plant,node,area]*0.98-GCDev[plant,node,area])/GCPot[plant,node,area],0.0),1.0)*PjNSw[node,genco,area]
      end
      RnTAW[area] = sum(RnMAW[plant,node,genco,area] for plant in plants, node in Nodes, genco in GenCos)
      for power in Select(Power,"Base"), plant in plants, node in Nodes, genco in GenCos
        @finite_math RnMSF[plant,node,genco,area] = RnMAW[plant,node,genco,area]/RnTAW[area]
        #
        # New Renewable Generation to be Built
        #
        if Area[area] != "CA"
          RnEGI[plant,node,genco,area] = max(RnGoal[area]-RnGenPrior[area]-RnEGUC[area]/2-xRnImports[area],0)*RnMSF[plant,node,genco,area]
        else
          RnEGI[plant,node,genco,area] = max(RnGoal[area]-RnGenPrior[area]-RnEGUC[area]-xRnImports[area],0)*RnMSF[plant,node,genco,area]
        end
      end
    end
  end

  function BuildCapacityInAnyArea(data::Data,areas)
    (; Areas, GenCos,Nodes,Plant,Plants,Power) = data
    (; MCE,ORNew,PCUCPrior,PjNSw,RnEGI,RnEGUC,RnGenPrior) = data
    (; RnGoal,RnMAW,RnMSF,RnMSM,RnSwitch,RnVF) = data
    RnTTAW = zeros(Float32, length(Areas))
    #
    #@debug "ECapacityExpansion.jl - BuildCapacityInAnyArea"
    #
    RnSwitchTemp::VariableArray{1} = zeros(Float32,size(Plant,1))
    for plant in Plants
      RnSwitchTemp[plant] = sum(RnSwitch[plant,area] for area in areas)
    end
    plants = Select(RnSwitchTemp[Plants],>(0))
    if !isempty(plants)
      #
      # Renewable Generation Under Construction
      # TODO Promula: TimeP and Month values should be explicit in ORNew
      for area in areas
        RnEGUC[area] = sum(PCUCPrior[plant,node,genco,area]*(1-ORNew[plant,area,1,1]) for
          plant in plants, node in Nodes, genco in GenCos) *8760/1000
      end
      #
      # Determine Market Share of New Generation
      #
      for area in areas, power in Select(Power,"Base"), plant in plants, node in Nodes, genco in GenCos
        #  RnMAW=RnMSM*MCE**RnVF*xmin(xmax((GCPot*0.98-GCDev)/GCPot,0.0),1.0)*PjNSw
        @finite_math RnMAW[plant,node,genco,area] = RnMSM[plant,node,genco,area]*max(MCE[plant,power,area],0.01)^RnVF[area]*
          min(max((RnGoal[area]*0.98-RnGenPrior[area])/RnGoal[area],0.0),1.0)*PjNSw[node,genco,area]
      end
        
      for area in areas
        RnTTAW[area] = sum(RnMAW[plant,node,genco,area]
                           for plant in Plants, node in Nodes, genco in GenCos)
      end

      for area in areas, plant in plants, node in Nodes, genco in GenCos
        @finite_math RnMSF[plant,node,genco,area] = RnMAW[plant,node,genco,area]/RnTTAW[area]
      end
      
      #
      # New Renewable Generation to be Built
      #
      RnTEGI = max(sum(RnGoal[area]-RnGenPrior[area]-RnEGUC[area]/2 for area in areas),0)

      for area in areas, plant in plants, node in Nodes, genco in GenCos
        RnEGI[plant,node,genco,area] = RnTEGI*RnMSF[plant,node,genco,area]
      end
    else
      @info "No Plants where RnSwitch > 0"
    end
  end

  function RnRPS(data::Data)
    (; db,year) = data
    (; Area,Areas,ECC,GenCos,Nodes,Plant,Plants,Power) = data
    (; CD,DesHr,EGPAPrior,Final,GCAvail,GCDev,GCPlanned,GCPot,
      HDGCCI,HDGR,NdArFr,ORNew,PjMax,RnEGI,RnGCCI,RnGoal,RnMSF,RnOption,
      SaECPrior,) = data

    #
    #@debug "ECapacityExpansion.jl - Generation Renewable RPS"
    #
    # Renewable Expansion to meet a Goal (RPS)
    # Assume Onshore Wind dominates so get Onshore Wind construction time
    #
    ow_plant = Select(Plant,"OnshoreWind")
    Loc1 = Int(min(year+CD[ow_plant],Final))
    RnFrLoc1::VariableArray{1} = ReadDisk(db,"EGInput/RnFr",Loc1) #[Area,Year]  Renewable Fraction (GWh/GWh)
    RnGoalSwitchLoc1::VariableArray{1} = ReadDisk(db,"EGInput/RnGoalSwitch",Loc1) #[Area,Year]  Renewable Generation Goal Switch (0 = Sales,1 = New Capacity)
    GR = zeros(Float32,size(Area,1))
    NewGen = zeros(Float32,size(Area,1))
    #
    for area in Areas
      #
      # Renewable Goal (RnGoal) is a fraction (RnFr) of sales (SaEC)
      #
      if RnGoalSwitchLoc1[area] == 1
        RnGoal[area] = sum(SaECPrior[ecc,area] for ecc in Select(ECC))*RnFrLoc1[area]
        #
        # Renewable Goal (RnGoal) is a fraction (RnFr) of generation (EGPA)
        #
      elseif RnGoalSwitchLoc1[area] == 2
        GR[area] = max(sum(HDGR[node]*NdArFr[node,area] for node in Nodes),0)
        @finite_math RnGoal[area] = sum(EGPAPrior[plant,area] for plant in Plants) *
          (1+GR[area])^(CD[ow_plant]+1)*RnFrLoc1[area]
        #
        # Renewable Goal (RnGoal) is fraction of expected generation from new capacity
        #
      else RnGoalSwitchLoc1[area] == 3
        for base_power in Select(Power,"Base")
          NewGen[area] = sum(HDGCCI[plant,node,genco,area]*DesHr[plant,base_power,area] for
            plant in Plants, node in Nodes, genco in GenCos)/1000
        end
        RnGoal[area] = NewGen[area]*RnFrLoc1[area]
      end
    end
    #

    #
    # Option 1: RPS capacity must be built inside the area
    #
    areas = findall(RnOption[:] .== 1)
    if !isempty(areas)
      BuildCapacityInsideArea(data,areas)
    end

    #
    # Option 2: RPS capacity can be built in any area
    #
    areas = findall(RnOption[:] .== 2)
    if !isempty(areas)
      BuildCapacityInAnyArea(data,areas)
    end

    #
    # Option 0: RPS met with Exogenous Building
    #
    areas = findall(RnOption[:] .== 0)
    if !isempty(areas)
      for area in areas, genco in GenCos, node in Nodes, plant in Plants
        RnMSF[plant,node,genco,area] = 0
        RnEGI[plant,node,genco,area] = 0
      end
    end

    #
    # Renewable Capacity Initiated (RnGCCI) is Indicated Generation (RnEGI)
    # divided by one minus the outage rate (ORNew) and converted to MW.
    # TODO Promula: TimeP and Month values should be explicit in ORNew
    for plant in Plants, node in Nodes, genco in GenCos, area in Areas
      @finite_math RnGCCI[plant,node,genco,area] = min(RnEGI[plant,node,genco,area]/8760*1000/(1-ORNew[plant,area,1,1]),PjMax[plant,area])
    end
      
      #
      # Adjust RnGCCI so that we do not exceed GCPot
      #
    for plant in Plants, node in Nodes, area in Areas
      GCPlanned[plant,node,area] = sum(RnGCCI[plant,node,genco,area] for genco in GenCos)
      GCAvail[plant,node,area] = max(GCPot[plant,node,area]*0.98-GCDev[plant,node,area],0)
      for genco in GenCos
        @finite_math RnGCCI[plant,node,genco,area] = RnGCCI[plant,node,genco,area] *
          min(GCPlanned[plant,node,area],GCAvail[plant,node,area])/GCPlanned[plant,node,area]
      end
    end
    WriteDisk(db,"EGOutput/RnEGI",year,RnEGI)
    WriteDisk(db,"EGOutput/RnGCCI",year,RnGCCI)
    WriteDisk(db,"EGOutput/RnGoal",year,RnGoal)
    WriteDisk(db,"EGOutput/RnMSF",year,RnMSF)
  end

  function RnFIT(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Nodes,Plants,Power) = data
    (; AreaCap,FIT,FITMAW,GCAvail,GCDev,GCPAPrior,GCPlanned,
      GCPot,MCE,PjNSw,RnBuildFr,RnGCCI,RnMAW,RnMSF,RnMSM,RnOption,RnVF) = data


    #
    #@debug "ECapacityExpansion.src - Generation Renewable FIT"
    #
    # Select areas where the FIT is active
    #
    for area in Areas
      if RnOption[area] == 3
       
        #
        # Total Capacity in Area
        #
        AreaCap[area] = sum(GCPAPrior[plant,area] for plant in Plants)
        #
        # Select Plant Types with FIT
        #
        plantfit = Select(FIT[Plants,area],>(0))
        
        #
        # Convert FIT contract price (FIT) into a marginal allocation weight (FITMAW)
        #
        @finite_math FITMAW[plantfit,area] = FIT[plantfit,area]^RnVF[area]
        
        #
        # Create a marginal allocation weight (RnMAW) for each type of Renewable Capacity
        # based on the marginal cost (MCE) and the potential capacity (GCPot).
        #
        for base in Select(Power,"Base"), plant in plantfit, node in Nodes, genco in GenCos
          @finite_math RnMAW[plant,node,genco,area] = RnMSM[plant,node,genco,area]*max(MCE[plant,base,area],0.01)^RnVF[area]*
            min(max((GCPot[plant,node,area]*0.98-GCDev[plant,node,area])/GCPot[plant,node,area],0.0),1.0)*PjNSw[node,genco,area]
          
          #
          # Market Share is based on the relationship of each plant type to 
          # its FIT contract price.
          #
          @finite_math RnMSF[plant,node,genco,area] = RnMAW[plant,node,genco,area] /
            (RnMAW[plant,node,genco,area]+FITMAW[plant,area])
          
          #
          # Capacity Initiated (RnGCCI) is a fraction (RnBuildFr) of 
          # the area capacity (GCPA).
          #
          RnGCCI[plant,node,genco,area] = max(RnGCCI[plant,node,genco,area],
            RnMSF[plant,node,genco,area]*AreaCap[area]*RnBuildFr[plant,area])
          
          #
          # Adjust Capacity Initiated (RnGCCI) so that we do not exceed the 
          # Potential Capacity (GCPot).
          #
        end
        for plant in plantfit, node in Nodes
          GCPlanned[plant,node,area] = sum(RnGCCI[plant,node,genco,area] for genco in GenCos)
          GCAvail[plant,node,area] = max(GCPot[plant,node,area]*0.98-GCDev[plant,node,area],0)
          for genco in GenCos
            @finite_math RnGCCI[plant,node,genco,area] = RnGCCI[plant,node,genco,area] *
              min(GCPlanned[plant,node,area],GCAvail[plant,node,area])/GCPlanned[plant,node,area]
          end
        end
      end
    end
    WriteDisk(db,"EGOutput/RnGCCI",year,RnGCCI)
    WriteDisk(db,"EGOutput/RnMSF",year,RnMSF)
  end

  function ReconcileCapacityInitiated(data::Data)
    #
    # Note - all commented out in Promula- Jeff Amlin 1/3/24 
    #
    #  Capacity constrcuted to meet requirements and
    #  to make profits
    # 
    # HDGCCITotal(N,G,A)=sum(P)(HDGCCI(P,N,G,A))
    # 
    #  Renewable capacity initiated from various programs
    # 
    # RnGCCITotal(N,G,A)=sum(P)(RnGCCI(P,N,G,A))
    # 
    #  Reduce capcity to avoid overbuilding from renewables
    # 
    # HDGCCIAllocated=xmax(HDGCCITotal-RnGCCITotal,0)
    # 
    #  Capacity constrcuted to meet requirements and
    #  to make profits after adjustment for renewables
    # 
    # HDGCCIAfterRn=HDGCCI/HDGCCITotal*HDGCCIAllocated
    # 
    #  Write Disk(HDGCCIAfterRn)
    # 
  end

  function Initiation(data::Data)
    (; CTime) = data

    #
    #@debug "ECapacityExpansion.jl - Initiation - Generation Project Initiation"
    #
    # Project Initiation
    #
    # Select the cheapest conventional plant to build
    #
    NewCapacityInitiated(data)
    #
    # Capacity initiated in Other Sectors (Landfill Gas,Steam)
    #
    OtherCapacity(data)
    if CTime > HisTime
      IntermittentPowerExpansion(data)
      #
      # Renewable Policy Options
      #
      RnRPS(data)
      RnFIT(data)
    end
    
    #
    # ReconcileCapacityInitiated
    #
  end

  function TrackingForUnit(data::Data,plant,node,genco,area)
    (; db,year) = data
    (; db,year) = data
    (; NewNum,UnCounter,UnNewNumber,UnPointer) = data

    #
    # If this individual unit is not tracked (UnNewNumber eq 0), then
    # it will be aggregated in with other similar units, so establish
    # a pointer which will be used for the next similar unit.
    #
    #@debug "TrackingForUnit"
    #
    if UnNewNumber[plant,node,genco,area] == 0
      UnPointer[plant,node,genco,area] = UnCounter[1]
      NewNum[1] = "00"
      #
      # Else this individual unit needs to be tracked and so
      # create a unique number for this unit.
      #
    else
      NewNum[1] = string(UnNewNumber[plant,node,genco,area])
      if UnNewNumber[plant,node,genco,area] < 10
        NewNum[1] = "0"*string(UnNewNumber[plant,node,genco,area])
      end
      # Removed uniitary plus due to preferences - LJD 2/13/24
      # UnNewNumber[plant,node,genco,area] += 1
      UnNewNumber[plant,node,genco,area] = UnNewNumber[plant,node,genco,area]+1
    end
  end

  function AssignLabelsToUnit(data::Data,plant,node,genco,area,newunit)
    (; AreaKey,GenCoDS,GenCoKey,NationKey,Nations,NodeKey,PlantKey) = data
    (; ANMap,UnArea,UnGenCo,UnNation,UnNode,UnOwner,UnPlant,UnSector) = data

    #
    #@debug "AssignLabelsToUnit"
    #
    # SetKey specifically used for absolute clarity.
    #
    UnOwner[newunit] = GenCoDS[genco]
    UnGenCo[newunit] = GenCoKey[genco]
    UnPlant[newunit] = PlantKey[plant]
    UnNode[newunit] = NodeKey[node]
    UnArea[newunit] = AreaKey[area]
    for nation in Nations
      if ANMap[area,nation] == 1
        UnNation[newunit] = NationKey[nation]
      end
    end
    UnSector[newunit] = "UtilityGen"
  end

  function CreateUnitAndFacilityName(data::Data,plant,node,genco,area,newunit)
    (; AreaKey,GenCoKey,NodeKey,PlantKey) = data
    (; NewNum,UnFacility,UnName,UnOnLine,UnSource) = data

    #
    #@debug "CreateUnitAndFacilityName"
    #
    # SetKey specifically used for absolute clarity.
    #

    UnName[newunit] = AreaKey[area]*" Endo "*NodeKey[node]*" "*GenCoKey[genco]*" "*PlantKey[plant]*" "*NewNum[1]
    UnFacility[newunit] = "Endogenous Build "*AreaKey[area]
    UnSource[newunit] = 1
    UnOnLine[newunit] = 2200
  end

  function CreateUnitCode(data::Data,plant,node,genco,area,newunit)
    (; Area) = data
    (; NewNum,UnCode) = data

    #
    #@debug "CreateUnitCode"
    #
    GenNum = string(genco[1])
    if genco[1] < 10
      GenNum = "0"*string(genco[1])
    end
    #
    PltNum = string(plant[1])
    if plant[1] < 10
      PltNum = "0"*string(plant[1])
    end
    #
    NodNum = string(node[1])
    if node[1] < 10
      NodNum = "0"*string(node[1])
    end
    UnCode[newunit] = Area[area]*"_Endo"*NodNum*GenNum*PltNum*NewNum[1]
  end

  function UnitOnlineDate(data::Data,plant,unit_OD)
    (; CD,CTime,UnOnLine) = data


    #
    #@debug "ECapacityExpansion.jl - UnitOnlineDate"
    #
    # Unit On-line date is Current time plus construction time (CD)
    #
    UnOnLine[unit_OD] = min(CTime+CD[plant],UnOnLine[unit_OD])
  end

  function ExchangeRates(data::Data,area,newunit)
    (; db,year) = data
    (; ExchangeRateUnit,ExchangeRate) = data

    #
    #@debug "ECapacityExpansion.jl - ExchangeRates"
    #
    ExchangeRateUnit[newunit] = ExchangeRate[area]
  end

  function InflationRates(data::Data,area,newunit)
    (; db,year) = data
    (; Inflation,InflationUnit) = data

    #
    #@debug "ECapacityExpansion.jl - InflationRates"
    #
    InflationUnit[newunit] = Inflation[area]
  end

  function RetirementYear(data::Data,newunit,prior_final)
    (; UnRetireYr) = data

    #
    #@debug "ECapacityExpansion.jl - RetirementYear"
    #
    @. UnRetireYr[newunit,prior_final] = 2200
  end

  function CapitalAndOMCosts(data::Data,plant,area,newunit)
    (; GCCC,GCTCM,Inflation,UFOMC,UnUFOMC,UnUOMC,UOMC,xUnGCCC) = data


    #
    #@debug "ECapacityExpansion.jl - CapitalAndOMCosts"
    #
    @finite_math xUnGCCC[newunit] = GCCC[plant,area]/Inflation[area]/GCTCM[plant,area]
    UnUOMC[newunit] = UOMC[plant,area]
    UnUFOMC[newunit] = UFOMC[plant,area]
  end


  function GetPrimaryFuel(data,area,plant)
    (; Area,Fuel,Plant) = data
    
    fuel = Select(Fuel,"NaturalGas")
  
    if (Plant[plant] == "OGCC") || (Plant[plant] == "OGCT") || (Plant[plant] == "SmallOGCC") || (Plant[plant] == "NGCCS")
      if (Area[area] == "NL") || (Area[area] == "NL")
        fuel = Select(Fuel,"Diesel")
      else
        fuel = Select(Fuel,"NaturalGas")
      end
    elseif (Plant[plant] == "OGSteam")
      fuel = Select(Fuel,"HFO")
    elseif (Plant[plant] == "Coal") || (Plant[plant] == "CoalCCS")
      fuel = Select(Fuel,"Coal")
    elseif (Plant[plant] == "OtherGeneration")
      fuel = Select(Fuel,"NaturalGas")
    elseif (Plant[plant] == "FuelCell")
      fuel = Select(Fuel,"Hydrogen")
    elseif (Plant[plant] == "Nuclear")
      fuel = Select(Fuel,"Nuclear")
    elseif (Plant[plant] == "BaseHydro") || (Plant[plant] == "PeakHydro") || (Plant[plant] == "SmallHydro")
      fuel = Select(Fuel,"Hydro")
    elseif (Plant[plant] == "Biomass") || (Plant[plant] == "BiomassCCS")
      fuel = Select(Fuel,"Biomass")
    elseif (Plant[plant] == "Biogas") || (Plant[plant] == "Waste")
      fuel = Select(Fuel,"Waste")
    elseif (Plant[plant] == "OnshoreWind") || (Plant[plant] == "OffshoreWind")
      fuel = Select(Fuel,"Wind")
    elseif (Plant[plant] == "SolarPV") || (Plant[plant] == "SolarThermal")
      fuel = Select(Fuel,"Solar")
    elseif (Plant[plant] == "Geothermal")
      fuel = Select(Fuel,"Geothermal")
    elseif (Plant[plant] == "Wave") || (Plant[plant] == "Tidal")
      fuel = Select(Fuel,"Wave")
    end
  
    return fuel
  end
  

  function FuelTypeAndHeatRate(data::Data,plant,area,newunit)
    (; Fuel,FuelEPs) = data
    (; FlFrMax,FlFrMin,FlFrMSM0,FlFrTime,FlFrVF,HRtM) = data
    (; UnF1,UnFlFrMax,UnFlFrMin,UnFlFrMSM0,UnFlFrTime,UnFlFrVF,UnHRt) = data

    #@debug "ECapacityExpansion.jl - FuelTypeAndHeatRate"

    # UnF1[newunit] = F1New[plant,area]
  
    fuel = GetPrimaryFuel(data,area,plant)
    #UnF1[newunit] = Fuel[fuel]

    for fuelep in FuelEPs
      UnFlFrMax[newunit,fuelep] = FlFrMax[fuelep,plant,area]
      UnFlFrMin[newunit,fuelep] = FlFrMin[fuelep,plant,area]
      UnFlFrMSM0[newunit,fuelep] = FlFrMSM0[fuelep,plant,area]
      UnFlFrTime[newunit,fuelep] = FlFrTime[fuelep,plant,area]
      UnFlFrVF[newunit,fuelep] = FlFrVF[fuelep,plant,area]
    end
    UnHRt[newunit] = HRtM[plant,area]
  end

  function OutageRates(data::Data,plant,area,newunit)
    (; Months,TimePs) = data
    (; EAF,MRunNew,ORNew) = data
    (; UnEAF,UnMustRun,UnOR) = data


    #
    #@debug "ECapacityExpansion.jl - OutageRates"
    #
    for month in Months
      UnEAF[newunit,month] = EAF[plant,area,month]
      for timep in TimePs
        UnOR[newunit,timep,month] = ORNew[plant,area,timep,month]
      end
    end
    UnMustRun[newunit] = MRunNew[plant,area]
  end

  function StorageParameters(data::Data,plant,area,newunit)
    (; StorageEfficiency,StorageSwitch,UnEffStorage,UnStorage) = data

    #
    #@debug "ECapacityExpansion.jl - StorageParameters"
    #
    UnStorage[newunit] = StorageSwitch[plant]
    UnEffStorage[newunit] = StorageEfficiency[plant,area]
  end

  function ReserveRequirements(data::Data,plant,node,newunit)
    (; RAvNew,RRqNew,RSwNew,UnRAv,UnRRq,UnRSwitch) = data

    #
    #@debug "ECapacityExpansion.jl - ReserveRequirements"
    #
    UnRRq[newunit] = RRqNew[plant,node]
    UnRAv[newunit] = RAvNew[plant,node]
    UnRSwitch[newunit] = RSwNew[plant,node]
  end

  function EmissionParameters(data::Data,plant,area,newunit)
    (; FuelEPs,Polls) = data
    (; CoverNew,EmitNew,MEPOCX,OffNew,POCX,PoTRNewExo,SqFr,ZeroFr) = data
    (; UnCoverage,UnEmit,UnMECX,UnOffsets,UnPOCX,UnPoTRExo,UnSqFr,UnZeroFr) = data

    #
    #@debug "ECapacityExpansion.jl - Emission Parameters"
    #
    #  The following lines take the most time to execute in the model.  I
    #  suspect it is the Write Disk statement causing the delay.  I want to test
    #  adding the Unit dimension to UnPOCX and writing it to disk at
    #  the end of the proceudure.  Jeff Amlin 01/10/10
    #
    for poll in Polls, fuelep in FuelEPs
      UnPOCX[newunit,FuelEPs,poll] = POCX[FuelEPs,plant,poll,area]
    end
    for poll in Polls
      UnMECX[newunit,poll] = MEPOCX[plant,poll,area]
    end

    UnEmit[newunit] = EmitNew[plant,area]

    #
    # UnCoverage[newunit,Polls] = CoverNew[plant,Polls,area]
    #
    for poll in Polls
      UnCoverage[newunit,poll] = CoverNew[plant,poll,area]
    end
    UnPoTRExo[newunit] = PoTRNewExo[plant,area]

    for poll in Polls
      UnOffsets[newunit,poll] = OffNew[plant,poll,area]
      UnSqFr[newunit,poll] = SqFr[plant,poll,area]
      for fuelep in FuelEPs
        UnZeroFr[newunit,fuelep,poll] = ZeroFr[fuelep,poll,area]
      end
    end
  end

  function MaxUnitError(data::Data)
    (; db,year) = data
    (; UnArea,UnCode,UnCoverage,UnEAF,UnEmit,ExchangeRateUnit,InflationUnit,UnFacility) = data
    (; UnFlFrMax,UnFlFrMin,UnFlFrMSM0,UnFlFrTime,UnFlFrVF) = data
    (; UnGCCI,UnGenCo,UnHRt,UnMustRun,UnName,UnNation,UnNode) = data
    (; UnOffsets,UnOnLine,UnOR,UnOwner,UnPlant,UnPoTRExo) = data
    (; UnRAv,UnRetireYr,UnRRq,UnRSwitch,UnSector,UnSource,UnSqFr,UnUOMC,UnUFOMC,xUnGCCC) = data
    (; UnEffStorage,UnStorage,UnZeroFr,xUnGCCI) = data
    (; UnCounter,UnNewNumber,UnPointer,xUnGCCI) = data


    #
    #@debug "ECapacityExpansion.jl -  Procedure:MaxUnitError"
    #
    #   Select Output "ErrorLog.log", Printer=ON
    #@debug  "File:  ECapacityExpansion  Procedure:  UnitInitiation"
    #@debug  "Number of units (UnCounter) has exceeded the maximum."
    #@debug  "UnCounter equals $UnCounter"
    #@debug  "Call Systematic Solutions, Inc."
    #
    WriteDisk(db,"EGInput/UnCounter",year,UnCounter[1])
    WriteDisk(db,"EGInput/UnNewNumber",year,UnNewNumber)
    WriteDisk(db,"EGInput/UnPointer",year,UnPointer)

    WriteDisk(db,"EGInput/UnArea",UnArea)
    WriteDisk(db,"EGInput/UnCode",UnCode)
    WriteDisk(db,"EGInput/UnCoverage",year,UnCoverage)
    WriteDisk(db,"EGInput/UnEAF",year,UnEAF)
    WriteDisk(db,"EGInput/UnEmit",UnEmit)
    WriteDisk(db,"MOutput/ExchangeRateUnit",year,ExchangeRateUnit)
    WriteDisk(db,"MOutput/InflationUnit",year,InflationUnit)
    #WriteDisk(db,"EGInput/UnF1",UnF1)
    WriteDisk(db,"EGInput/UnFacility",UnFacility)

    WriteDisk(db,"EGInput/UnFlFrMax",year,UnFlFrMax)
    WriteDisk(db,"EGInput/UnFlFrMin",year,UnFlFrMin)
    WriteDisk(db,"EGCalDB/UnFlFrMSM0",year,UnFlFrMSM0)
    WriteDisk(db,"EGInput/UnFlFrTime",year,UnFlFrTime)
    WriteDisk(db,"EGInput/UnFlFrVF",UnFlFrVF)

    WriteDisk(db,"EGOutput/UnGCCI",year,UnGCCI)
    WriteDisk(db,"EGInput/UnGenCo",UnGenCo)
    WriteDisk(db,"EGInput/UnHRt",year,UnHRt)
    WriteDisk(db,"EGInput/UnMustRun",UnMustRun)
    WriteDisk(db,"EGInput/UnName",UnName)
    WriteDisk(db,"EGInput/UnNation",UnNation)
    WriteDisk(db,"EGInput/UnNode",UnNode)

    WriteDisk(db,"EGInput/UnOffsets",year,UnOffsets)
    WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
    WriteDisk(db,"EGInput/UnOR",year,UnOR)
    WriteDisk(db,"EGInput/UnOwner",UnOwner)
    WriteDisk(db,"EGInput/UnPlant",UnPlant)
    WriteDisk(db,"EGInput/UnPoTRExo",year,UnPoTRExo)

    WriteDisk(db,"EGInput/UnRAv",UnRAv)
    WriteDisk(db,"EGInput/UnRetire",UnRetireYr)
    WriteDisk(db,"EGInput/UnRRq",UnRRq)
    WriteDisk(db,"EGInput/UnRSwitch",UnRSwitch)
    WriteDisk(db,"EGInput/UnSector",UnSector)
    WriteDisk(db,"EGInput/UnSource",UnSource)
    WriteDisk(db,"EGInput/UnSqFr",year,UnSqFr)
    WriteDisk(db,"EGInput/UnUOMC",year,UnUOMC)
    WriteDisk(db,"EGInput/UnUFOMC",year,UnUFOMC)
    WriteDisk(db,"EGInput/xUnGCCC",year,xUnGCCC)

    WriteDisk(db,"EGInput/UnEffStorage",UnEffStorage)
    WriteDisk(db,"EGInput/UnStorage",UnStorage)
    WriteDisk(db,"EGInput/UnZeroFr",year,UnZeroFr)
    error("Max Unit Error Reached: Number of units has exceeded the maximum $UnCounter")
  end

  function CreateNewUnit(data::Data,plant,node,genco,area)
    (; prior,Final) = data
    (; Unit) = data
    (; UnCounter) = data
    #
    # Increase Unit Counter
    #

    UnCounter[1] = UnCounter[1]+1

    if UnCounter[1] <= size(Unit,1)
      #
      # Select the new unit
      #
      newunit = Int(UnCounter[1])
      #
      TrackingForUnit(data,plant,node,genco,area)
      AssignLabelsToUnit(data,plant,node,genco,area,newunit)
      CreateUnitAndFacilityName(data,plant,node,genco,area,newunit)
      CreateUnitCode(data,plant,node,genco,area,newunit)
      UnitOnlineDate(data,plant,newunit)
      #
      ExchangeRates(data,area,newunit)
      InflationRates(data,area,newunit)
      #
      prior_final = collect(prior:Final)
      RetirementYear(data,newunit,prior_final)
      CapitalAndOMCosts(data,plant,area,newunit)
      FuelTypeAndHeatRate(data,plant,area,newunit)
      OutageRates(data,plant,area,newunit)
      StorageParameters(data,plant,area,newunit)
      ReserveRequirements(data,plant,node,newunit)
      EmissionParameters(data,plant,area,newunit)
    else
      MaxUnitError(data)
    end
    return newunit
  end

  function UnitInitiation(data::Data)
    (; db,year,next) = data
    (; Areas,GenCos,Nodes,Plants) = data
    (; UnArea,UnCode,UnCoverage,UnEAF,UnEmit,ExchangeRateUnit,InflationUnit,UnFacility) = data
    (; UnFlFrMax,UnFlFrMin,UnFlFrMSM0,UnFlFrTime,UnFlFrVF) = data
    (; UnGCCI,UnGenCo,UnHRt,UnMustRun,UnName,UnNation,UnNode) = data
    (; UnOffsets,UnOnLine,UnOR,UnOwner,UnPlant,UnPoTRExo) = data
    (; UnRAv,UnRetireYr,UnRRq,UnRSwitch,UnSector,UnSource,UnSqFr,UnUOMC,UnUFOMC,xUnGCCC) = data
    (; UnEffStorage,UnStorage,UnZeroFr) = data
    (; HDGCCI,IPGCCI,RnGCCI,xUnGCCI,UnMECX,UnPOCX) = data
    (; UnCounter,UnCounterPrior,UnNewNumber,UnNewNumberPrior,UnPointer,UnPointerPrior,xUnGCCI) = data

    #
    #@debug "ECapacityExpansion.jl -  Generation Unit Project Initiation"

    #
    @. UnCounter = UnCounterPrior
    @. UnNewNumber = UnNewNumberPrior
    @. UnPointer = UnPointerPrior
    UtilityUnits = round.(Int,GetUtilityUnits(data))
    for unit in UtilityUnits
      UnGCCI[unit] = xUnGCCI[unit]
    end
    #
    # For each GenCo, Node, and Plant Type initiate a Unit, if needed.
    #
    for genco in GenCos, area in Areas, node in Nodes, plant in Plants
      #
      # Unit Indicated Capacity Initiated (UnIGCCI) is equal the greater
      # of the firm capacity initiated (HDGCCI), the intermittent capacity
      # initiated (IPGCCI), and the renewable capacity initiated (RnGCCI).
      #
      UnIGCCI = max(HDGCCI[plant,node,genco,area],IPGCCI[plant,node,genco,area],RnGCCI[plant,node,genco,area])
      #
      # If Unit Indicated Capacity Initiated (UnIGCCI) is greater
      # than 0.0, then initiate a Unit
      #
      # if UnIGCCI[plant,node,genco,area] > 0.0 && UnPointer[plant,node,genco,area] > 0
      #
      if UnIGCCI > 0.0 && UnPointer[plant,node,genco,area] > 0
        #
        # If this is a new unit (UnPointer eq 0), then increase the number of units,
        # assign the unit a name, and assign the unit operating parameters.
        #
        if  UnPointer[plant,node,genco,area] == 0 || UnNewNumber[plant,node,genco,area] > 0
          newunit = CreateNewUnit(data,plant,node,genco,area)
          #
          # Else there is already an existing unit of this same type, then
          # just Select the unit.
          #
        else
          unitptr = Int(UnPointer[plant,node,genco,area])
          UnitOnlineDate(data,plant,unitptr)
        end
        #
        # Unit Capacity Initiated (UnGCCI)
        #
        # UnGCCI[unitptr] = xUnGCCI[unitptr]+UnIGCCI[plant,node,genco,area]
        UnGCCI[unitptr] = xUnGCCI[unitptr]+UnIGCCI
      end
    end

    #
    # Moved "WriteDisk" outside loop from EmissionParameters - Jeff Amlin 1/4/24
    #
    WriteDisk(db,"EGInput/UnMECX",year,UnMECX)
    WriteDisk(db,"EGInput/UnPOCX",year,UnPOCX)

    WriteDisk(db,"EGInput/UnCounter",year,UnCounter[1])
    WriteDisk(db,"EGInput/UnNewNumber",year,UnNewNumber)
    WriteDisk(db,"EGInput/UnPointer",year,UnPointer)

    WriteDisk(db,"EGInput/UnArea",UnArea)
    WriteDisk(db,"EGInput/UnCode",UnCode)
    WriteDisk(db,"EGInput/UnCoverage",year,UnCoverage)
    WriteDisk(db,"EGInput/UnEAF",year,UnEAF)
    WriteDisk(db,"EGInput/UnEmit",UnEmit)
    WriteDisk(db,"MOutput/ExchangeRateUnit",year,ExchangeRateUnit)
    WriteDisk(db,"MOutput/InflationUnit",year,InflationUnit)
    #WriteDisk(db,"EGInput/UnF1",UnF1)
    WriteDisk(db,"EGInput/UnFacility",UnFacility)

    WriteDisk(db,"EGInput/UnFlFrMax",year,UnFlFrMax)
    WriteDisk(db,"EGInput/UnFlFrMin",year,UnFlFrMin)
    WriteDisk(db,"EGCalDB/UnFlFrMSM0",year,UnFlFrMSM0)
    WriteDisk(db,"EGInput/UnFlFrTime",year,UnFlFrTime)
    WriteDisk(db,"EGInput/UnFlFrVF",UnFlFrVF)

    WriteDisk(db,"EGOutput/UnGCCI",year,UnGCCI)
    WriteDisk(db,"EGInput/UnGenCo",UnGenCo)
    WriteDisk(db,"EGInput/UnHRt",year,UnHRt)
    WriteDisk(db,"EGInput/UnMustRun",UnMustRun)
    WriteDisk(db,"EGInput/UnName",UnName)
    WriteDisk(db,"EGInput/UnNation",UnNation)
    WriteDisk(db,"EGInput/UnNode",UnNode)

    WriteDisk(db,"EGInput/UnOffsets",year,UnOffsets)
    WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
    WriteDisk(db,"EGInput/UnOR",year,UnOR)
    WriteDisk(db,"EGInput/UnOwner",UnOwner)
    WriteDisk(db,"EGInput/UnPlant",UnPlant)
    WriteDisk(db,"EGInput/UnPoTRExo",year,UnPoTRExo)

    WriteDisk(db,"EGInput/UnRAv",UnRAv)
    WriteDisk(db,"EGInput/UnRetire",UnRetireYr)
    WriteDisk(db,"EGInput/UnRRq",UnRRq)
    WriteDisk(db,"EGInput/UnRSwitch",UnRSwitch)
    WriteDisk(db,"EGInput/UnSector",UnSector)
    WriteDisk(db,"EGInput/UnSource",UnSource)
    WriteDisk(db,"EGInput/UnSqFr",year,UnSqFr)
    WriteDisk(db,"EGInput/UnUOMC",year,UnUOMC)
    WriteDisk(db,"EGInput/UnUFOMC",year,UnUFOMC)
    WriteDisk(db,"EGInput/xUnGCCC",year,xUnGCCC)

    WriteDisk(db,"EGInput/UnEffStorage",UnEffStorage)
    WriteDisk(db,"EGInput/UnStorage",UnStorage)
    WriteDisk(db,"EGInput/UnZeroFr",year,UnZeroFr)

    WriteDisk(db,"EGInput/UnCounter",next,UnCounter[1])

  end

  function CgInitiation(data::Data)
    (; db,year) = data
    (; Areas,ECCs,Nodes,Plants,Units) = data
    (; CgGCCI,CgUnCode,NdArMap,UnCode,UnGCCI,xUnGCCI) = data

    # UnGCCI .= ReadDisk(db,"EGOutput/UnGCCI",year)
    CgUnits = round.(Int,GetCogenUnits(data))
    for unit in CgUnits
      UnGCCI[CgUnits] = xUnGCCI[CgUnits]
    end

    for area in Areas, node in Nodes
      if NdArMap[node,area] == 1
        for ecc in ECCs, plant in Plants
          if CgGCCI[plant,ecc,node,area] > 0.0
            for unit in Units
              if CgUnCode[plant,ecc,node,area] == unit
                UnGCCI[unit] = xUnGCCI[unit]+CgGCCI[plant,ecc,node,area]
              else
                #@debug "Missing Cogeneration Unit for $(Plant[plant]) $(ECC[ecc]) $(Node[node]) $(Area[area]) $(Year[year])"
              end
            end
          end
        end
      end
    end
    WriteDisk(db,"EGOutput/UnGCCI",year,UnGCCI)
  end
  
  #
  # *******************
  #
  function CapacityCompletion(data::Data,plant,unit)
    (; year) = data
    (; CD,Final,UnGC,UnGCCE,UnGCCI,UnGCCR,UnGCPrior,xUnGCCR) = data

    #
    ##@debug "ECapacityExpansion.jl - CapacityCompletion - Unit = $unit "
    #
    OnLine = Int(year+CD[plant])
    if OnLine <= Final
      UnGCCE[unit,OnLine] = UnGCCI[unit]    
    end
    
    #
    # Capacity Completion Rate for the Current Year
    #
    UnGCCR[unit] = UnGCCE[unit,year]+xUnGCCR[unit]

    #
    # Update Capacity
    #
    UnGC[unit] = max(UnGCPrior[unit]+UnGCCR[unit],0.0)
  end
  
  #
  # *******************
  #
  function CapacityUnderConstruction(data::Data,unit)
    (; UnCUC,UnCUCPrior,UnGCCI,UnGCCR,xUnGCCR) = data

    #
    # #@debug "ECapacityExpansion.jl - CapacityUnderConstruction Unit = $unit"
    #
    UnCUC[unit] = max(UnCUCPrior[unit]+UnGCCI[unit]-UnGCCR[unit]+xUnGCCR[unit],0)
  end
  
  #
  # *******************
  #
  function ConstructionCosts(data::Data,area,plant,unit)
    
    #
    # #@debug "ECapacityExpansion.jl - ConstructionCosts Unit = $unit"
    #  
    (; CD,GCTCM,InflationUnit,UnCUC,UnCW,UnCWGA,UnGCCC,UnGCCR,xUnGCCC) = data

    UnGCCC[unit] = xUnGCCC[unit]*GCTCM[plant,area]*InflationUnit[unit]

    #
    # Annual Construction Costs
    #
    @finite_math UnCW[unit] = UnCUC[unit]*UnGCCC[unit]/CD[plant]/1000

    # 
    # Construction Costs for Gross Assets (UnCWGA) increase with
    # new construction (UnGCCR > 0)
    # 
    UnCWGA[unit] = max(UnGCCR[unit]*UnGCCC[unit],0)/1000
    
  end
  
  #
  # *******************
  #
  function UnitConstruction(data::Data,units)
    
    #
    #@debug "ECapacityExpansion.jl - UnitConstruction"
    # 
    (; db,year) = data
    (; UnCUC,UnCW,UnCWAC,UnCWGA,UnGC,UnGCCC,UnGCCE,UnGCCR) = data

    for unit in units
      plant,node,genco,area = GetUnitSets(data,unit)
      CapacityCompletion(data,plant,unit)
      CapacityUnderConstruction(data,unit)
      ConstructionCosts(data,area,plant,unit)
    end
    
    WriteDisk(db,"EGOutput/UnCUC",year,UnCUC)
    WriteDisk(db,"EGOutput/UnCW",year,UnCW)
    WriteDisk(db,"EGOutput/UnCWAC",year,UnCWAC)
    WriteDisk(db,"EGOutput/UnCWGA",year,UnCWGA)
    WriteDisk(db,"EGOutput/UnGC",year,UnGC)
    WriteDisk(db,"EGOutput/UnGCCC",year,UnGCCC)
    WriteDisk(db,"EGOutput/UnGCCE",UnGCCE)
    WriteDisk(db,"EGOutput/UnGCCR",year,UnGCCR)
  end
  
  #
  # *******************
  #
  function ErrorCheck(data::Data,unit,genco,plant,node,area)
    (; UnArea,UnCode,UnNode,UnGenCo,UnPlant) = data

    #
    #  Write (" ECapacityExpansion.src,  ErrorCheck")
    # 
    # Do If (Area:n gt 1) or (GenCo:n gt 1) or (Plant:n gt 1) or (Node:n gt 1)
    #   Write ("File:  ECapacityExpansion  Procedure:  UnitConstruction")
    #   Write ("Inside ECapacityExpansion.src - Plant information mis-specified")
    #   Write ("UnCode = ",UnCode::0,", UnPlant = ",UnPlant::0,",UnArea = ",UnArea::0,
    #        ", UnNode = ",UnNode::0,",UnGenCo = ",UnGenCo::0)
    #   Select Output "ErrorLog.log", Printer=ON
    #   Write ("File:  ECapacityExpansion  Procedure:  UnitConstruction")
    #   Write ("Inside ECapacityExpansion.src - Plant information mis-specified")
    #   Write ("UnCode = ",UnCode::0,", UnPlant = ",UnPlant::0,",UnArea = ",UnArea::0,
    #        ", UnNode = ",UnNode::0,",UnGenCo = ",UnGenCo::0)
    #   Select Printer=OFF
    #   Stop Promula
    # End do If

    #
    # #@debug "ECapacityExpansion.jl - ErrorCheck"
    #
    if size(area,1) > 1 || size(genco,1) > 1 || size(plant,1) > 1 || size(node,1) > 1
      error("Plant information mis-specified. UnCode = $(UnCode[unit])")
      error("UnCode = ",UnCode[unit],",UnPlant = ",UnPlant[unit],
            ",UnArea = ",UnArea[unit],",UnNode = ",UnNode[unit],",UnGenCo = ",UnGenCo[unit])
    end
  end
  
  #
  # *******************
  #
  function ConstructionTotals(data::Data)
    (; db,current) = data
    (; year,Yrv) = data
    (; CW,CWAC,CWGA,GC,GCAr,GCG,GCCR,PCUC) = data
    (; UnCW,UnCWAC,UnCWGA,UnGCCR,UnCUC) = data
    (; UnOnLine,UnRetire) = data
    (; UnGC) = data

    #
    #@debug "ECapacityExpansion.jl - ConstructionTotals"
    #
    @. CW = 0
    @. CWAC = 0
    @. CWGA = 0
    @. GC = 0
    @. GCAr =0
    @. GCCR = 0
    @. GCG = 0
    @. PCUC = 0
    #
    UtilityUnits = round.(Int,GetUtilityUnits(data))
    for unit in UtilityUnits
      plant,node,genco,area = GetUnitSets(data,unit)
      CW[plant,area] = CW[plant,area]+UnCW[unit]
      CWAC[plant,area] = CWAC[plant,area]+UnCWAC[unit]
      CWGA[plant,area] = CWGA[plant,area]+UnCWGA[unit]
      GCCR[plant,node,area] = GCCR[plant,node,area]+UnGCCR[unit]
      PCUC[plant,node,genco,area] = PCUC[plant,node,genco,area]+UnCUC[unit]
      if (UnOnLine[unit] <= Yrv[current]) && (UnRetire[unit] > Yrv[current])
        GC[plant,node,genco] = GC[plant,node,genco]+UnGC[unit]
        GCAr[plant,node,genco,area] = GCAr[plant,node,genco,area]+UnGC[unit]
        GCG[plant,genco] = GCG[plant,genco]+UnGC[unit]     
      end
      ErrorCheck(data,unit,genco,plant,node,area)
    end 
    WriteDisk(db,"EGOutput/CW",year,CW)
    WriteDisk(db,"EGOutput/CWAC",year,CWAC)
    WriteDisk(db,"EGOutput/CWGA",year,CWGA)
    WriteDisk(db,"EGOutput/GCCR",year,GCCR)
    WriteDisk(db,"EGOutput/PCUC",year,PCUC)
    WriteDisk(db,"EOutput/GC",year,GC)
    WriteDisk(db,"EOutput/GCAr",year,GCAr)
    WriteDisk(db,"EOutput/GCG",year,GCG)
  end

  function CgConstruction(data::Data)
    (; db,year) = data
    (; ECC) = data
    (; GCTCM,GCTCMPrior,UnCW,UnSector,CgInvUnit) = data

    #
    # @info "ECapacityExpansion.jl - CgConstruction - Cogeneration Construction"
    #
    @. GCTCM = GCTCMPrior
    CgUnits = round.(Int,GetCogenUnits(data))
    UnitConstruction(data,CgUnits)
    #
    @. CgInvUnit = 0
    for unit in CgUnits
      plant,node,genco,area = GetUnitSets(data,unit)
      ecc = Select(ECC,UnSector[unit])
      CgInvUnit[ecc,area] = CgInvUnit[ecc,area]+UnCW[unit]
    end
    WriteDisk(db,"SOutput/CgInvUnit",year,CgInvUnit)
  end

  function CgCtrl(data::Data)

    #
    #@debug "ECapacityExpansion.jl - CgCtrl: Cogeneration Control"
    #
    CgInitiation(data)
    CgConstruction(data)
  end

  function Ctrl(data::Data)
    #@debug "ECapacityExpansion.jl - Ctrl"

    #
    # Capacity Requirements
    #
    FirmCapacityFromPowerContracts(data)
    CapacityRequirementsForecast(data)
    FirmCapacityFromExistingUnits(data)
    FirmCogenerationCapacitySoldToGrid(data)
    FirmCapacityAvailable(data)
    
    #
    # Capacity Costs
    #
    CapacityAlreadyDeveloped(data)
    CapitalCostMultiplierFromDepletion(data)
    CapitalCostMultiplierFromETC(data)
    CapacityCapitalCost(data)
    FuelPrices(data)
    ProjectCosts(data)
    
    #
    # Capacity Initiated
    #
    CapacityUnderConstructionMultiplier(data)
    BuildFractionBasedOnClearingPrice(data)
    CapacityNeededBasedOnClearingPrice(data)
    CapacityNeededForReserveMargin(data)
    BuildNewCapacity(data)
    Initiation(data)
    UnitInitiation(data)
    
    #
    # Capacity Construction
    #
    # TODOJulia - GetUtilityUnits should send back an integer 0 Jeff Amlin 2/28/25
    #
    UtilityUnits = round.(Int,GetUtilityUnits(data))
    UnitConstruction(data,UtilityUnits)
    ConstructionTotals(data)
  end

end # module ECapacityExpansion
