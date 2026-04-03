#
# MEData.jl
#
using EnergyModel

module MEData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  PollX::SetArray = ReadDisk(db,"MainDB/PollKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MEPOCS::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCS") # [ECC,Poll,Area,Year] Non Energy Pollution Standards (Tonnes/TBtu)
  FlPOCXMult::VariableArray{4} = ReadDisk(db,"MEInput/FlPOCXMult") # [ECC,Poll,Area,Year] Flaring Pollution Coefficient (Tonnes/Driver)
  FuPOCXMult::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCXMult") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  MEGFr::VariableArray{3} = ReadDisk(db,"MEInput/MEGFr") # [ECC,Area,Year] Non Energy eCO2 Reduction Grant Fraction ($/$)
  MEOCF::VariableArray{3} = ReadDisk(db,"MEInput/MEOCF") # [ECC,Area,Year] Non Energy eCO2 Reduction Operating Cost Factor ($/$)
  MEPL::VariableArray{3} = ReadDisk(db,"MEInput/MEPL") # [ECC,Area,Year] Non Energy eCO2 Reduction Physical Lifetime (Years)
  MEIVTC::VariableArray{3} = ReadDisk(db,"MEInput/MEIVTC") # [ECC,Area,Year] Non Energy eCO2 Reduction Investment Tax Credit ($/$)
  MEROIN::VariableArray{3} = ReadDisk(db,"MEInput/MEROIN") # [ECC,Area,Year] Non Energy eCO2 Reduction Return on Investment ($/$)
  METL::VariableArray{3} = ReadDisk(db,"MEInput/METL") # [ECC,Area,Year] Non Energy eCO2 Reduction Tax Lifetime (Years)
  METxRt::VariableArray{3} = ReadDisk(db,"MEInput/METxRt") # [ECC,Area,Year] Non Energy eCO2 Reduction Tax Rate ($/$)
  # MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-output)
  # EnPOCX::VariableArray{5} = ReadDisk(db,"MEInput/MEPOCX") # [FuelEP,ECC,Poll,Area,Year] Energy Pollution Coefficien (Tonnes/$B-output)
  SqBL::VariableArray{2} = ReadDisk(db,"MEInput/SqBL") # [Area,Year] Sequestering Book Lifetime (Years)
  SqCCSw::VariableArray{3} = ReadDisk(db,"MEInput/SqCCSw") # [ECC,Area,Year] Sequestering Capital Cost Switch (1=CC Curve, 3=Levelized CC)
  SqCD::VariableArray{3} = ReadDisk(db,"MEInput/SqCD") # [ECC,Area,Year] Sequestering Construction Delay (Years)
  SqCDOrder::VariableArray{2} = ReadDisk(db,"MEInput/SqCDOrder") # [ECC,Year] Number of Levels in the Sequestering Construction Delay (Number)
  SqGFr::VariableArray{2} = ReadDisk(db,"MEInput/SqGFr") # [Area,Year] Sequestering eCO2 Reduction Grant Fraction ($/$)
  SqPL::VariableArray{2} = ReadDisk(db,"MEInput/SqPL") # [Area,Year] Sequestering eCO2 Reduction Physical Lifetime (Years)
  SqIVTC::VariableArray{2} = ReadDisk(db,"MEInput/SqIVTC") # [Area,Year] Sequestering eCO2 Reduction Investment Tax Credit ($/$)
  SqROIN::VariableArray{2} = ReadDisk(db,"MEInput/SqROIN") # [Area,Year] Sequestering eCO2 Reduction Return on Investment ($/$)
  SqTL::VariableArray{2} = ReadDisk(db,"MEInput/SqTL") # [Area,Year] Sequestering eCO2 Reduction Tax Lifetime (Years)
  SqTM::VariableArray{3} = ReadDisk(db,"MEInput/SqTM") # [ECC,Area,Year] Sequestering eCO2 Reduction Tax Lifetime (Years)
  SqTransStorageCost::VariableArray{2} = ReadDisk(db,"MEInput/SqTransStorageCost") # [Area,Year] Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e)
  SqTSCapitalFraction::VariableArray{2} = ReadDisk(db,"MEInput/SqTSCapitalFraction") # [Area,Year] Captial Fraction of Sequestering Transportation and Storage Costs ($/$)
  xMERM::VariableArray{4} = ReadDisk(db,"MEInput/xMERM") # [ECC,Poll,Area,Year] Exogenous Average Pollution Coefficient Reduction Multiplier (Tonnes/Tonnes)
  MECM::VariableArray{2} = ReadDisk(db,"MEInput/MECM") # [Poll,PollX] Cross-over Reduction Multiplier (Tonnes/Tonnes)
  MERCD::VariableArray{2} = ReadDisk(db,"MEInput/MERCD") # [ECC,Poll] Reduction Capital Construction Delay (Years)
  MERCPL::VariableArray{2} = ReadDisk(db,"MEInput/MERCPL") # [ECC,Poll] Reduction Capital Pysical Life (Years)
  MERCstM::VariableArray{3} = ReadDisk(db,"MEInput/MERCstM") # [ECC,Poll,Year] Reduction Cost Technology multiplier ($/$)
  MEROCF::VariableArray{2} = ReadDisk(db,"MEInput/MEROCF") # [ECC,Poll] Polution Reducution O&M ($/Tonne/($/Tonne))
  # MEVRP::VariableArray{4} = ReadDisk(db,"MEInput/MEVRP") # [ECC,Poll,Area,Year] Voluntary Reduction Policy (Tonnes/Tonnes)
  # MEROCF::VariableArray{1} = ReadDisk(db,"MEInput/MEROCF") # [ECC] Voluntary Reduction response time (Years)
  VnPOCXMult::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCXMult") # [ECC,Poll,Area,Year] Venting Pollution Coefficient (Tonnes/Driver)

end

function MEData_Inputs(db)
  data = MControl(; db)
  (; Area,Areas,ECC,ECCs,Nation,Nations,Poll,Polls,PollX,Years) = data
  (; MEPOCS,FlPOCXMult,FuPOCXMult,MEGFr,MEOCF,MEPL,MEIVTC,MEROIN,METL) = data
  (; METxRt,SqBL,SqCCSw,SqCD,SqCDOrder,SqGFr,SqPL,SqIVTC,SqROIN,SqTL) = data
  (; SqTM,SqTransStorageCost,SqTSCapitalFraction,xMERM,MECM,MERCD) = data
  (; MERCPL,MERCstM,MEROCF, VnPOCXMult) = data

  #
  ########################
  #
  # MEPOCS[ECC,Poll,Area,Year] Non Energy Pollution Standards (Tonnes/TBtu)
  #
  @. MEPOCS=1e12
  WriteDisk(db,"MEInput/MEPOCS",MEPOCS)

  #
  ########################
  #
  # FlPOCXMult[ECC,Poll,Area,Year] Flaring Pollution Coefficient (Tonnes/Driver)
  #
  @. FlPOCXMult=1
  WriteDisk(db,"MEInput/FlPOCXMult",FlPOCXMult)

  #
  ########################
  #
  # FuPOCXMult[ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  #
  @. FuPOCXMult=1
  WriteDisk(db,"MEInput/FuPOCXMult",FuPOCXMult)

  #
  ########################
  #
  # MEGFr[ECC,Area,Year] Non Energy eCO2 Reduction Grant Fraction ($/$)
  #
  # This is a policy variable
  #
  @. MEGFr=0.0
  WriteDisk(db,"MEInput/MEGFr",MEGFr)

  #
  ########################
  #
  # MEOCF[ECC,Area,Year] Non Energy eCO2 Reduction Operating Cost Factor ($/$)
  #
  # 1. Source:  "ME Curves.xls" and "O&G_Province.doc"
  # 2. RBL 1/3/02
  #
  @. MEOCF=0.08
  WriteDisk(db,"MEInput/MEOCF",MEOCF)

  #
  ########################
  #
  # MEOCF[ECC,Area,Year] Non Energy eCO2 Reduction Operating Cost Factor ($/$)
  #
  # 1. Source:  "ME Curves.xls" and "O&G_Province.doc"
  # 2. RBL 1/3/02
  #
  @. MEOCF=0.08
  WriteDisk(db,"MEInput/MEOCF",MEOCF)

  #
  ########################
  #
  # MEPL[ECC,Area,Year] Non Energy eCO2 Reduction Physical Lifetime (Years)
  #
  # 1. Source:  "ME Curves.xls"
  # 2. RBL 1/3/02
  #
  @. MEPL=20
  WriteDisk(db,"MEInput/MEPL",MEPL)

  #
  ########################
  #
  # MEIVTC[ECC,Area,Year] Non Energy eCO2 Reduction Investment Tax Credit ($/$)
  #
  # This is a policy variable
  #
  @. MEIVTC=0.0
  WriteDisk(db,"MEInput/MEIVTC",MEIVTC)

  #
  ########################
  #
  # MEROIN(ECC,Area,Year] Non Energy eCO2 Reduction Return on Investment ($/$)
  #
  # 1. Set equal to .25 for all processes per J.Amlin
  # 2. RBL 01/04/02
  #
  @. MEROIN=0.25
  WriteDisk(db,"MEInput/MEROIN",MEROIN)

  #
  ########################
  #
  # METL[ECC,Area,Year] Non Energy eCO2 Reduction Tax Lifetime (Years)
  #
  # The tax life is 80% of the book life.
  #
  @. METL=0.80*MEPL
  WriteDisk(db,"MEInput/METL",METL)

  #
  ########################
  #
  # METxRt[ECC,Area,Year] Non Energy eCO2 Reduction Tax Rate ($/$)
  #
  # 1. US - TxRt from IData.src (these are US values) (The data is from DRI, Tables 7 & 10)
  # 2. Canada - Source:  NRS.xls (Informetrica Corporate Tax Rate, Total All Governments)
  #
  Years=collect(Yr(1985):Yr(1986))
  METxRt[:,:,Years] .= 0.4950
  METxRt[:,:,Yr(1987)] .= 0.38
  Years=collect(Yr(1988):Yr(1992))
  METxRt[:,:,Years] .= 0.34
  Years=collect(Yr(1993):Final)
  METxRt[:,:,Years] .= 0.35
  WriteDisk(db,"MEInput/METxRt",METxRt)

  #
  ########################
  #
  # MEPOCX[ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-output)
  #
  # 1. Comes from Superset per J.Amlin
  # 2. RBL 01/04/02
  #
  # WriteDisk(db,"MEInput/MEPOCX",MEPOCX)

  #
  ########################
  #
  # EnPOCX[FuelEP,ECC,Poll,Area,Year] Energy Pollution Coefficient (Tonnes/$B-output)
  #
  # 1. Comes from Superset per J.Amlin
  # 2. RBL 01/04/02
  #
  # WriteDisk(db,"MEInput/EnPOCX",EnPOCX)

  #
  ########################
  #
  # SqBL[Area,Year] Sequestering Book Lifetime (Years)
  #
  # 1. Source:  "Sq Curves.xls"
  # 2. RBL 1/3/02
  #
  @. SqBL=20.0
  WriteDisk(db,"MEInput/SqBL",SqBL)

  #
  ########################
  #
  # SqCCSw[ECC,Area,Year] Sequestering Capital Cost Switch (1=CC Curve, 3=Levelized CC)
  #
  @. SqCCSw=3
  WriteDisk(db,"MEInput/SqCCSw",SqCCSw)

  #
  ########################
  #
  # SqCD[ECC,Area,Year] Sequestering Construction Delay (Years)
  #
  # Default Value
  #
  @. SqCD=2
  #
  # Oil Sands
  #
  eccs=Select(ECC,["PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsUpgraders"])
  SqCD[eccs,:,:] .= 6
  
  WriteDisk(db,"MEInput/SqCD",SqCD)

  #
  ########################
  #
  # SqCDOrder[ECC,Area,Year] Number of Levels in the Sequestering Construction Delay (Number)
  #
  # Default Value
  #
  @. SqCDOrder=2
  #
  # Oil Sands
  #
  eccs=Select(ECC,["PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsUpgraders"])
  SqCDOrder[eccs,:] .= 2
  
  WriteDisk(db,"MEInput/SqCDOrder",SqCDOrder)


  #
  ########################
  #
  # SqGFr[Area,Year] Sequestering eCO2 Reduction Grant Fraction ($/$)
  #
  # This is a policy variable
  #
  @. SqGFr=0.0
  WriteDisk(db,"MEInput/SqGFr",SqGFr)

  #
  ########################
  #
  # SqPL[Area,Year] Sequestering eCO2 Reduction Physical Lifetime (Years)
  #
  # Source:  "Sq Curves.xls" - RBL 1/3/02
  # Set to zero to remove retirements from simulation 
  # - Jeff Amlin 1/25/13
  #
  @. SqPL=0.0
  WriteDisk(db,"MEInput/SqPL",SqPL)

  #
  ########################
  #
  # SqIVTC[Area,Year] Sequestering eCO2 Reduction Investment Tax Credit ($/$)
  #
  # This is a policy variable
  #
  @. SqIVTC = 0.0
  WriteDisk(db,"MEInput/SqIVTC",SqIVTC)

  #
  ########################
  #
  # SqROIN[Area,Year] Sequestering eCO2 Reduction Return on Investment ($/$)
  #
  # 1. Set equal to .25 for all processes per J.Amlin
  # 2. RBL 01/04/02
  #
  @. SqROIN = 0.25
  WriteDisk(db,"MEInput/SqROIN",SqROIN)

  #
  ########################
  #
  # SqTL[Area,Year] Sequestering eCO2 Reduction Tax Lifetime (Years)
  #
  # The tax life is 80% of the book life.
  #
  @. SqTL = 0.80*SqBL
  WriteDisk(db,"MEInput/SqTL",SqTL)

  #
  ########################
  #
  # SqTM[Area,Year] Sequestering eCO2 Reduction Tax Lifetime (Years)
  #
  @. SqTM = 1.0
  WriteDisk(db,"MEInput/SqTM",SqTM)

  #
  ########################
  #
  # SqTransStorageCost[Area,Year] Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e)
  #
  @. SqTransStorageCost = 0.0
  WriteDisk(db,"MEInput/SqTransStorageCost",SqTransStorageCost)

  #
  ########################
  #
  # SqTSCapitalFraction[Area,Year] Captial Fraction of Sequestering Transportation and Storage Costs ($/$)
  #
  # Source: Email from: Noah Conrad of ECCC, Sent: Wednesday, July 3, 2024 12:10 PM
  # - Jeff Amlin 7/15/24
  #
  @. SqTSCapitalFraction = 0.90
  WriteDisk(db,"MEInput/SqTSCapitalFraction",SqTSCapitalFraction)

  #
  ########################
  #
  # xMERM[ECC,Poll,Area,Year] Exogenous Average Pollution Coefficient Reduction Multiplier (Tonnes/Tonnes)
  #
  # Exogenous Reduction Multiplier is initialized at 1 (No exogenous adjustment)
  #
  @. xMERM = 1.0
  WriteDisk(db,"MEInput/xMERM",xMERM)

  #########################
  # CAC Pollution Reduction
  #########################
  #
  # MECM[Poll,PollX] Cross-over Reduction Multiplier (Tonnes/Tonnes)
  # MERCD[ECC,Poll] Reduction Capital Construction Delay (Years)
  # MERCPL[ECC,Poll] Reduction Capital Pysical Life (Years)
  # MERCstM[ECC,Poll,Year] Reduction Cost Technology multiplier ($/$)
  # MEROCF[ECC,Poll] Polution Reducution O&M ($/Tonne/($/Tonne))
  # MEVRP[ECC,Poll,Area,Year] Voluntary Reduction Policy (Tonnes/Tonnes)
  # MEVRRT[ECC] Voluntary Reduction response time (Years)
  #
  # Pollution Reduction Operating Cost Factors from Dave Sawyer
  #
  ecc=Select(ECC,"IronSteel")
  poll=Select(Poll,"SOX")
  MEROCF[ecc,poll]=1.0

  ecc=Select(ECC,"Wastewater")
  poll=Select(Poll,"SOX")
  MEROCF[ecc,poll]=2.0

  ecc=Select(ECC,"Incineration")
  poll=Select(Poll,"SOX")
  MEROCF[ecc,poll]=0.10

  ecc=Select(ECC,"Wastewater")
  poll=Select(Poll,"PMT")
  MEROCF[ecc,poll]=0.0

  ecc=Select(ECC,"Incineration")
  poll=Select(Poll,"PMT")
  MEROCF[ecc,poll]=0.0

  WriteDisk(db,"MEInput/MEROCF",MEROCF)

  #
  # Voluntary Reductions
  #
  # @. MEVRRT=3
  # @. MEVRP=0
  # Note : Variables not saved to disk in Promula. LJD, 25/03/05

  #
  # Cross Impact Multiplier (is zero except for the diaganol)
  #
  @. MECM=0
  for poll in Polls
    pollx=Select(PollX,Poll[poll])
    MECM[poll,pollx]=1.0
  end
  WriteDisk(db,"MEInput/MECM",MECM)

  @. MERCstM=1.0
  # @. MERCD=3.0
  @. MERCD=1.0
  WriteDisk(db,"MEInput/MERCstM",MERCstM)
  WriteDisk(db,"MEInput/MERCD",MERCD)

  #
  # MERCPL is set equal to PCPL
  #
  @. MERCPL=20
  eccs=Select(ECC,(from="Cement",to="OtherManufacturing"))
  MERCPL[eccs,:] .= 33
  WriteDisk(db,"MEInput/MERCPL",MERCPL)

  #
  ########################
  #
  # VnPOCXMult[ECC,Poll,Area,Year] Venting Pollution Coefficient (Tonnes/Driver)
  #
  # Exogenous Reduction Multiplier is initialized at 1 (No exogenous adjustment)
  #
  @. VnPOCXMult=1.0
  WriteDisk(db,"MEInput/VnPOCXMult",VnPOCXMult)

end # end MEData_Inputs

function Control(db)
  MEData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end #end module
