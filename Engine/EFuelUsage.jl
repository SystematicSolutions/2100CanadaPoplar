#
# EFuelUsage.jl
#

module EFuelUsage

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log, Yr

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  Yr2000 = Yr(2000)

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") #[Area,CNArea]  Map between Area and Canada Economic Areas (CNArea)
  DInv::VariableArray{2} = ReadDisk(db,"SOutput/DInv",year) #[ECC,Area,Year]  Device Investments (M$/Yr)
  DInvEU::VariableArray{2} = ReadDisk(db,"EGOutput/DInvEU",year) #[Fuel,Area,Year]  Device Investments (M$/Yr)
  DInvFr::VariableArray{2} = ReadDisk(db,"EGInput/DInvFr",year) #[Plant,Area,Year]  Device Investments Fraction ($/KW/Yr)
  DmdES::VariableArray{3} = ReadDisk(db,"SOutput/DmdES",year) #[ES,Fuel,Area,Year]  Energy Demand (tBtu/Yr)
  DmdFA::VariableArray{2} = ReadDisk(db,"EGOutput/DmdFA",year) #[Fuel,Area,Year]  Energy Demands (TBtu/Yr)
  DmdFPA::VariableArray{3} = ReadDisk(db,"EGOutput/DmdFPA",year) #[Fuel,Plant,Area,Year]  Energy Demands (TBtu/Yr)
  DmdPA::VariableArray{2} = ReadDisk(db,"EGOutput/DmdPA",year) #[Plant,Area,Year]  Energy Demands (TBtu/Yr)
  Driver::VariableArray{2} = ReadDisk(db,"MOutput/Driver",year) #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  EAProd::VariableArray{2} = ReadDisk(db,"SOutput/EAProd",year) #[Plant,Area,Year]  Electric Utility Production (GWh/Yr)
  ECFPMonth::VariableArray{3} = ReadDisk(db,"EGOutput/ECFPMonth",year) #[FuelEP,Month,Area,Year]  Monthly Fuel Price ($/mmBtu)
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  EGCurtailed::VariableArray{4} = ReadDisk(db,"EGOutput/EGCurtailed",year) #[TimeP,Month,Plant,Area,Year]  Curtailed Electric Generation (GWh/Yr)
  EGFA::VariableArray{2} = ReadDisk(db,"EGOutput/EGFA",year) #[Fuel,Area,Year]  Electricity Generated (GWh/Yr)
  EGFAuu::VariableArray{2} = ReadDisk(db,"EGOutput/EGFAuu",year) #[Fuel,Area,Year]  Electricity Generated (GWh/Yr)
  EGFAGross::VariableArray{2} = ReadDisk(db,"EGOutput/EGFAGross",year) #[Fuel,Area,Year]  Gross Electricity Generated (GWh/Yr)
  EGPA::VariableArray{2} = ReadDisk(db,"EGOutput/EGPA",year) #[Plant,Area,Year]  Electricity Generated (GWh/Yr)
  EGPAuu::VariableArray{2} = ReadDisk(db,"EGOutput/EGPAuu",year) #[Plant,Area,Year]  Electricity Generated (GWh/Yr)
  EGPAGross::VariableArray{2} = ReadDisk(db,"EGOutput/EGPAGross",year) #[Plant,Area,Year]  Gross Electricity Generated (GWh/Yr)
  EGPACurtailed::VariableArray{2} = ReadDisk(db,"EGOutput/EGPACurtailed",year) #[Plant,Area,Year]  Curtailed Electric Generation (GWh/Yr)
  EGTM::VariableArray{4} = ReadDisk(db,"EGOutput/EGTM",year) #[TimeP,Month,Plant,Area,Year]  Electricity Generated (GWh/Yr)
  EUD::VariableArray{2} = ReadDisk(db,"EGOutput/EUD",year) # [FuelEP,Area,Year] Electric Utility Energy Demand (tBtu/Yr)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (tBtu)
  EUDPF::VariableArray{3} = ReadDisk(db,"EGOutput/EUDPF",year) #[FuelEP,Plant,Area,Year]  Electric Utility Fuel Demands (TBtu/Yr)
  EUDPFN::VariableArray{3} = ReadDisk(db,"EGOutput/EUDPFN",year) #[FuelEP,Plant,Node,Year]  Electric Utility Fuel Demands (TBtu/Yr)
  ExchangeRateNation::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateNation",year) #[Nation,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  ExpPurchases::VariableArray{1} = ReadDisk(db,"EGOutput/ExpPurchases",year) #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{1} = ReadDisk(db,"EGOutput/ExpSales",year) #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") # [Fuel,Plant] Fuel/Plant Map
  FuelExp::VariableArray{2} = ReadDisk(db,"EGOutput/FuelExp",year) #[Fuel,Area,Year]  Fuel Expenditures (M$)
  FuelExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/FuelExpenditures",year) #[ECC,Area,Year]  Fuel Expenditures (M$)
  GCFA::VariableArray{2} = ReadDisk(db,"EOutput/GCFA",year) #[Fuel,Area,Year]  Generation Capacity (MW)
  GCFANet::VariableArray{2} = ReadDisk(db,"EOutput/GCFANet",year) #[Fuel,Area,Year]  Net Generation Capacity (MW)
  GCG::VariableArray{2} = ReadDisk(db,"EOutput/GCG",year) #[Plant,GenCo,Year]  Generation Capacity (MW)
  GCPA::VariableArray{2} = ReadDisk(db,"EOutput/GCPA",year) #[Plant,Area,Year]  Generation Capacity (MW)
  GCPANet::VariableArray{2} = ReadDisk(db,"EOutput/GCPANet",year) #[Plant,Area,Year]  Net,Generation Capacity (MW)
  HDEnergy::VariableArray{3} = ReadDisk(db,"EGOutput/HDEnergy",year) # [Node,TimeP,Month] Energy in Interval (GWh)
  HDPrA::VariableArray{3} = ReadDisk(db,"EOutput/HDPrA",year) # (Node,TimeP,Month) Spot Market Marginal Price ($/MWh)
  HMPrA::VariableArray{1} = ReadDisk(db,"EOutput/HMPrA",year) # (Area) Average Spot Market Price ($/MWh)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) #[Nation,Year]  Inflation Index ($/$)
  InflationUnit::VariableArray{1} = ReadDisk(db,"MOutput/InflationUnit",year) #[Unit,Year]  Inflation Index ($/$)
  NdNMap::VariableArray{2} = ReadDisk(db,"EGInput/NdNMap") #[Node,Nation]  Map between Node and Nation
  OMExp::VariableArray{2} = ReadDisk(db,"SOutput/OMExp",year) #[ECC,Area,Year]  O&M Expenditures (M$)
  PInv::VariableArray{2} = ReadDisk(db,"SOutput/PInv",year) #[ECC,Area,Year]  Process Investments (M$/Yr)
  PInvTemp::VariableArray{2} = ReadDisk(db,"EGOutput/PInvTemp",year) #[Fuel,Area,Year]  Process Investments (M$/Yr)
  PSoECC::VariableArray{2} = ReadDisk(db,"SOutput/PSoECC",year) #[ECC,Area,Year]  Power Sold to Grid (GWh)
  RnGen::VariableArray{1} = ReadDisk(db,"EGOutput/RnGen",year) #[Area,Year]  Renewable Current Level of Generation (GWh/Yr)
  RnSwitch::VariableArray{2} = ReadDisk(db,"EGInput/RnSwitch") #[Plant,Area]  Renewable Plant Type Switch (1=Renewable)
  TDInv::VariableArray{1} = ReadDisk(db,"SOutput/TDInv",year) #[Area,Year]  Electric Transmission and Distribution Investments (M$/Yr)
  TDInvFr::VariableArray{2} = ReadDisk(db,"EGInput/TDInvFr",year) #[Plant,Area,Year]  Electric Transmission and Distribution Investments Fraction ($/KW/Yr)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)
  UnArea::Vector{String} = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
  UnCode::Vector{String} = ReadDisk(db,"EGInput/UnCode") #[Unit]  Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::Float32 = ReadDisk(db,"EGInput/UnCounter",year) #[Year]  Number of Units
  UnCW::VariableArray{1} = ReadDisk(db,"EGOutput/UnCW",year) #[Unit,Year]  Construction Costs ($M/Yr)
  UnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UnDmd",year) #[Unit,FuelEP,Year]  Energy Demands (TBtu)
  UnDmdPrior::VariableArray{2} = ReadDisk(db,"EGOutput/UnDmd",prior) #[Unit,FuelEP,Year]  Energy Demands (TBtu)
  UnEG::VariableArray{3} = ReadDisk(db,"EGOutput/UnEG",year) #[Unit,TimeP,Month,Year]  Generation (GWh)
  UnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGA",year) #[Unit,Year]  Generation (GWh)
  UnEGCurtailed::VariableArray{3} = ReadDisk(db,"EGOutput/UnEGCurtailed",year) #[Unit,TimeP,Month,Year]  Generation Curtailed (GWh)
  UnEGGross::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGGross",year) #[Unit,Year]  Gross Generation (GWh/Yr)
  UnFlFr::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFr",year) #[Unit,FuelEP,Year]  Fuel Fraction (Btu/Btu)
  UnFP::VariableArray{2} = ReadDisk(db,"EGOutput/UnFP",year) #[Unit,Month,Year]  Fuel Price ($/mmBtu)
  UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Generating Capacity (MW)
  UnGCNet::VariableArray{1} = ReadDisk(db,"EGOutput/UnGCNet",year) #[Unit,Year]  Net Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{1} = ReadDisk(db,"EGInput/UnHRt",year) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnNode::Vector{String} = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  UnPlant::Vector{String} = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
  UnRetire::VariableArray{1} = ReadDisk(db,"EGInput/UnRetire",year) #[Unit,Year]  Retirement Date (Year)
  UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") #[Unit]  Storage Switch (1=Storage Unit)
  UnUFOMC::VariableArray{1} = ReadDisk(db,"EGInput/UnUFOMC",year) #[Unit,Year]  Fixed O&M Costs (Real $/Kw/Yr)
  UnUOMC::VariableArray{1} = ReadDisk(db,"EGInput/UnUOMC",year) #[Unit,Year]  Variable O&M Costs (Real $/MWH)
  UnXSw::VariableArray{1} = ReadDisk(db,"EGInput/UnXSw",year) #[Unit,Year]  Exogneous Unit Data Switch (0 = Exogenous)
  UUnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UUnDmd",year) #[Unit,FuelEP,Year]  Endogenous Energy Demands (TBtu)
  UUnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGA",year) #[Unit,Year]  Endogenous Generation (GWh)
  xUnDmd::VariableArray{2} = ReadDisk(db,"EGInput/xUnDmd",year) #[Unit,FuelEP,Year]  Historical Unit Energy Demands (TBtu)

  KJBtu = 1.054615

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
  # Select GenCo*,Plant*,Node*,Area*
end

function GetElectricSets(data::Data)
  (; ECC,ES) = data

  ElectricUtilitySelected = "False"

  es = Select(ES,"Electric")
  ecc = Select(ECC,"UtilityGen")

  if (ES[es] == "Electric") && (ECC[ecc] == "UtilityGen")
    ElectricUtilitySelected = "True"
  end

  return es,ecc,ElectricUtilitySelected

end

function GetUtilityUnits(data::Data)
  (; CTime) = data
  (; UnCogen,UnCounter,UnOnLine,UnRetire) = data

  Units = 1:Int(UnCounter)
  UnitsOnline = Select(UnOnLine,<=(CTime))
  UnitsNotRetired = Select(UnRetire,>(CTime))
  UnitsNotCogen = Select(UnCogen,==(0.0))

  UtilityUnits = intersect(Units,UnitsOnline,UnitsNotRetired,UnitsNotCogen)

  return UtilityUnits

end

function CheckOnline(data::Data,unit)
  (; CTime) = data
  (; UnOnLine,UnRetire) = data

  UnitIsOnline = "False"

  if (UnOnLine[unit] <= CTime) && (UnRetire[unit] > CTime)
    UnitIsOnline = "True"
  end

  return UnitIsOnline

end

function CheckDoesUnitBurnFuel(data::Data,plant)
  (; FlPlnMap) = data

  UnitDoesNotBurnFuel = "False"

  fuels = findall(FlPlnMap[:,plant] .== 1)
  if !isempty(fuels)
    check = sum(FlPlnMap[fuel,plant] for fuel in fuels)
    if (check > 0.0)
      UnitDoesNotBurnFuel = "True"
    end
  end

  return UnitDoesNotBurnFuel

end

#
# Page 1 - Fuel Usage for each Unit
#
function InitializeFuelUsage(data::Data)
  (; EUDPF,EUDPFN) = data

  @. EUDPFN = 0
  @. EUDPF = 0

end

function UnitFuelUsage(data::Data,unit,plant,node,area)
  (; FuelEPs) = data
  (; EUDPF,EUDPFN,UnDmd,UnEGGross,UnFlFr,UnGC,UnHRt,UUnDmd,UnXSw,xUnDmd) = data

  #
  # Unit fuel usage (UnDmd) is equal to generation (UnEGA) times heat
  # rate (UnHRt) times the fuel fraction (UnFlFr).
  #
  for fuelep in FuelEPs
    UnDmd[unit,fuelep] = max(UnEGGross[unit]*UnHRt[unit]/1e6*UnFlFr[unit,fuelep],0)
  end

  #
  # If UnXSw equals 0.0 then we want fuel usage (UnDmd) to be exact (xUnDmd),
  # but save the model generated value (UUnDmd)
  #
  for fuelep in FuelEPs
    UUnDmd[unit,fuelep] = UnDmd[unit,fuelep]
  end

  if (UnXSw[unit] == 0) && (UnGC[unit] > 0)
    for fuelep in FuelEPs
      UnDmd[unit,fuelep] = xUnDmd[unit,fuelep]
    end
  end

  for fuelep in FuelEPs
    EUDPFN[fuelep,plant,node] = EUDPFN[fuelep,plant,node]+UnDmd[unit,fuelep]
    EUDPF[fuelep,plant,area] = EUDPF[fuelep,plant,area]+UnDmd[unit,fuelep]
  end

end

function ElectricUtilityDemandTotals(data::Data)
  (; Areas,FuelEPs,Plants) = data
  (; EUD,EUDPF) = data

  for area in Areas, fuelep in FuelEPs
    EUD[fuelep,area] = sum(EUDPF[fuelep,plant,area] for plant in Plants)
  end

end

function PutFuelUsage(data::Data)
  (; db,year) = data
  (; EUD,EUDPF,EUDPFN,UnDmd,UUnDmd) = data

  WriteDisk(db,"EGOutput/EUD",year,EUD)
  WriteDisk(db,"EGOutput/EUDPF",year,EUDPF)
  WriteDisk(db,"EGOutput/EUDPFN",year,EUDPFN)
  WriteDisk(db,"EGOutput/UnDmd",year,UnDmd)
  WriteDisk(db,"EGOutput/UUnDmd",year,UUnDmd)

end

#
# Page 1 "Headlines"
#
function FuelUsage(data::Data)

  # @info "EFuelUsage - FuelUsage"

  es,ecc,ElectricUtilitySelected = GetElectricSets(data)

  if ElectricUtilitySelected == "True"
    InitializeFuelUsage(data)
    UtilityUnits = GetUtilityUnits(data)

    for unit in UtilityUnits
      plant,node,genco,area = GetUnitSets(data,unit)
      UnitFuelUsage(data,unit,plant,node,area)
    end

    #
    # ResetUnitSets
    #
    ElectricUtilityDemandTotals(data)
    PutFuelUsage(data)

  end

end

#
# Page 2 - Capacity, Generation, and Other Totals across Units
#
function InitializeUnitSummary(data::Data,ecc)
  (; Areas) = data
  (; DInvEU,DmdFA,DmdFPA,DmdPA,EGCurtailed,EGFA) = data
  (; EGFAuu,EGFAGross,EGPA,EGPACurtailed,EGPAGross) = data
  (; EGPAuu,EGTM,EUD,FuelExp,GCFA,GCFANet,GCPA) = data
  (; GCPANet,OMExp,PInvTemp) = data

  @. DInvEU = 0
  @. DmdFA = 0
  @. DmdFPA = 0
  @. DmdPA = 0
  @. EGCurtailed = 0
  @. EGFA = 0
  @. EGFAuu = 0
  @. EGFAGross = 0
  @. EGPA = 0
  @. EGPACurtailed = 0
  @. EGPAGross = 0
  @. EGPAuu = 0
  @. EGTM = 0
  @. EUD = 0
  @. FuelExp = 0
  @. GCFA = 0
  @. GCFANet = 0
  @. GCPA = 0
  @. GCPANet = 0
  @. PInvTemp = 0

  for area in Areas
    OMExp[ecc,area] = 0
  end
end

function UnitCapacityAccumulate(data::Data,unit,plant,area)
  (; GCPA,GCPANet,UnGC,UnGCNet) = data

  GCPA[plant,area] = GCPA[plant,area]+UnGC[unit]
  GCPANet[plant,area] = GCPANet[plant,area]+UnGCNet[unit]

end

function UnitGenerationAccumulate(data::Data,unit,plant,area)
  (; Months,TimePs) = data
  (; EGCurtailed,EGPA,EGPACurtailed,EGPAGross) = data
  (; EGPAuu,EGTM,UnEG,UnEGA,UnEGCurtailed) = data
  (; UnEGGross,UnStorage,UUnEGA) = data

  for month in Months, timep in TimePs
    EGCurtailed[timep,month,plant,area] =
      EGCurtailed[timep,month,plant,area]+
      UnEGCurtailed[unit,timep,month]*(1-UnStorage[unit])
  end

  EGPACurtailed[plant,area] = EGPACurtailed[plant,area]+
    sum(UnEGCurtailed[unit,timep,month] for month in Months, timep in TimePs)*(1-UnStorage[unit])

  EGPA[plant,area] = EGPA[plant,area]+UnEGA[unit]*(1-UnStorage[unit])
  EGPAuu[plant,area] = EGPAuu[plant,area]+UUnEGA[unit]*(1-UnStorage[unit])
  EGPAGross[plant,area] = EGPAGross[plant,area]+UnEGGross[unit]*(1-UnStorage[unit])

  for month in Months, timep in TimePs
    EGTM[timep,month,plant,area] = EGTM[timep,month,plant,area]+UnEG[unit,timep,month]
  end

end

function FuelUsageIfDoesNotBurnFuel(data::Data,ecc,unit,plant,area)
  (; Fuels,Months,TimePs) = data
  (; DInvEU,DInvFr,DmdFA,DmdFPA,DmdPA,EGFA,EGFAGross) = data
  (; EGFAuu,FuelExp,FlPlnMap,GCFA,GCFANet,InflationUnit,OMExp,PInvTemp) = data
  (; UnCW,UnEG,UnEGA,UnEGGross,UnFP,UnGC,UnGCNet,UnHRt,UnStorage) = data
  (; UnUFOMC,UnUOMC,UUnEGA) = data

  #
  # This section is for units with fuels not in the FuelEP set
  # (that is,units which do not burn emission producing fuels)
  # so UnDmd has no values - Jeff Amlin 6/23/13
  #
  for fuel in Fuels
    if FlPlnMap[fuel,plant] == 1
      GCFA[fuel,area] = GCFA[fuel,area]+UnGC[unit]
      GCFANet[fuel,area] = GCFANet[fuel,area]+UnGCNet[unit]
      EGFA[fuel,area] = EGFA[fuel,area]+UnEGA[unit]*(1-UnStorage[unit])
      EGFAuu[fuel,area] = EGFAuu[fuel,area]+UUnEGA[unit]*(1-UnStorage[unit])
      EGFAGross[fuel,area] = EGFAGross[fuel,area]+UnEGGross[unit]*(1-UnStorage[unit])
      DmdFA[fuel,area] = DmdFA[fuel,area]+UnEGA[unit]*UnHRt[unit]/1e6
      DmdFPA[fuel,plant,area] = DmdFPA[fuel,plant,area]+UnEGA[unit]*UnHRt[unit]/1e6
      DInvEU[fuel,area] = DInvEU[fuel,area]+UnCW[unit]*DInvFr[plant,area]
      PInvTemp[fuel,area] = PInvTemp[fuel,area]+UnCW[unit]*(1-DInvFr[plant,area])
    end
  end

  DmdPA[plant,area] = DmdPA[plant,area]+UnEGA[unit]*UnHRt[unit]/1e6
  OMExp[ecc,area] = OMExp[ecc,area]+UnUOMC[unit]*InflationUnit[unit]*UnEGA[unit]/1e6 +
              UnUFOMC[unit]*InflationUnit[unit]*UnGC[unit]/1000

  #  FuelExp = FuelExp+UnFP*UnEGA*UnHRt/1e6

  for fuel in Fuels
    if FlPlnMap[fuel,plant] == 1
      FuelExp[fuel,area] = FuelExp[fuel,area]+
        sum(UnFP[unit,month]*UnEG[unit,timep,month] for month in Months, timep in TimePs)*
        UnHRt[unit]/1e6
    end
  end

end

function FuelUsageIfDoesBurnFuel(data::Data,unit,plant,area)
  (; FuelEPs) = data
  (; DmdPA,UnDmd) = data

  #
  # This section if for units with fuels included in the FuelEP set
  # (that is,units which burn emission producing fuels)
  # so use UnDmd for fuel totals.
  #
  DmdPA[plant,area] = DmdPA[plant,area]+sum(UnDmd[unit,fuelep] for fuelep in FuelEPs)

end

function AssignCapacityToLargestFuel(data::Data,unit,area)
  (; Fuel,Fuels,FuelEP,FuelEPs) = data
  (; GCFA,GCFANet,UnFlFr,UnGC,UnGCNet) = data

  fuelep = FuelEPs

  #
  # Capacity is classified by the largest fuel (UnFlFr)
  #
  fuelep = fuelep[sortperm(UnFlFr[unit,fuelep],rev = true)]
  largest = first(fuelep)
  if !isempty(largest)
    for fuel in Fuels
      if Fuel[fuel] == FuelEP[largest]
        GCFA[fuel,area] = GCFA[fuel,area]+UnGC[unit]
        GCFANet[fuel,area] = GCFANet[fuel,area]+UnGCNet[unit]
      end
    end
  end

end

function AllocateCapacityBetweenFuels(data::Data,unit,area)
  # (; Fuels,FuelEPs) = data
  # (; GCFA,GCFANet,UnFlFr,UnGC,UnGCNet) = data
  # (; ModSwitch) = data

  # if ModSwitch == "BPA"
  #   for fuelep in FuelEPs, fuel in Fuels
  #     if FuelEP[fuelep] == Fuel[fuel]
  #       GCFA[fuel,area] = GCFA[fuel,area]+UnGC[unit]*UnFlFr[unit,fuelep]
  #       GCFANet[fuel,area] = GCFANet[fuel,area]+UnGCNet[unit]*UnFlFr[unit,fuelep]
  #     end
  #   end
  # end

end

function SplitGenerationAndFuelUseBetweenFuels(data::Data,unit,plant,area,ecc)
  (; Fuel,Fuels,FuelEP,FuelEPs,Months,TimePs) = data
  (; EGFA,EGFAuu,EGFAGross,UnFlFr,UnEGA,UUnEGA) = data
  (; UnEGGross,DmdFA,UnDmd,DmdFPA,EUD,DInvEU,UnCW) = data
  (; DInvFr,PInvTemp,FuelExp,ECFPMonth,UnEG) = data
  (; OMExp,UnUOMC,InflationUnit,UnUFOMC,UnGC) = data

  #
  # Generation and Fuel Use are split between Fuels (UnFlFr)
  #
  for fuelep in FuelEPs, fuel in Fuels
    if FuelEP[fuelep] == Fuel[fuel]
      EGFA[fuel,area] = EGFA[fuel,area]+UnEGA[unit]*UnFlFr[unit,fuelep]
      EGFAuu[fuel,area] = EGFAuu[fuel,area]+UUnEGA[unit]*UnFlFr[unit,fuelep]
      EGFAGross[fuel,area] = EGFAGross[fuel,area]+UnEGGross[unit]*UnFlFr[unit,fuelep]
      DmdFA[fuel,area] = DmdFA[fuel,area]+UnDmd[unit,fuelep]
      DmdFPA[fuel,plant,area] = DmdFPA[fuel,plant,area]+UnDmd[unit,fuelep]
      EUD[fuelep,area] = EUD[fuelep,area]+UnDmd[unit,fuelep]
      DInvEU[fuel,area] = DInvEU[fuel,area]+UnCW[unit]*DInvFr[plant,area]*UnFlFr[unit,fuelep]
      PInvTemp[fuel,area] = PInvTemp[fuel,area]+UnCW[unit]*(1-DInvFr[plant,area])*UnFlFr[unit,fuelep]

      @finite_math FuelExp[fuel,area] = FuelExp[fuel,area]+
        sum(UnDmd[unit,fuelep]*ECFPMonth[fuelep,month,area]*
        UnEG[unit,timep,month] for month in Months, timep in TimePs)/UnEGA[unit]
    end
  end

  OMExp[ecc,area] += UnUOMC[unit]*InflationUnit[unit]*UnEGA[unit]/1e6+
                     UnUFOMC[unit]*InflationUnit[unit]*UnGC[unit]/1000
end

function PutUnitSummary(data::Data)
  (; db,year) = data
  (; DInvEU,DmdFA,DmdFPA,DmdPA,EGCurtailed,EGFA) = data
  (; EGFAuu,EGFAGross,EGPA,EGPACurtailed) = data
  (; EGPAGross,EGPAuu,EGTM,EUD,FuelExp,GCFA) = data
  (; GCFANet,GCPA,GCPANet,OMExp,PInvTemp) = data

  WriteDisk(db,"EGOutput/DInvEU",year,DInvEU)
  WriteDisk(db,"EGOutput/DmdFA",year,DmdFA)
  WriteDisk(db,"EGOutput/DmdFPA",year,DmdFPA)
  WriteDisk(db,"EGOutput/DmdPA",year,DmdPA)
  WriteDisk(db,"EGOutput/EGCurtailed",year,EGCurtailed)
  WriteDisk(db,"EGOutput/EGFA",year,EGFA)
  WriteDisk(db,"EGOutput/EGFAuu",year,EGFAuu)
  WriteDisk(db,"EGOutput/EGFAGross",year,EGFAGross)
  WriteDisk(db,"EGOutput/EGPA",year,EGPA)
  WriteDisk(db,"EGOutput/EGPACurtailed",year,EGPACurtailed)
  WriteDisk(db,"EGOutput/EGPAGross",year,EGPAGross)
  WriteDisk(db,"EGOutput/EGPAuu",year,EGPAuu)
  WriteDisk(db,"EGOutput/EGTM",year,EGTM)
  WriteDisk(db,"EGOutput/EUD",year,EUD)
  WriteDisk(db,"EGOutput/FuelExp",year,FuelExp)
  WriteDisk(db,"EOutput/GCFA",year,GCFA)
  WriteDisk(db,"EOutput/GCFANet",year,GCFANet)
  WriteDisk(db,"EOutput/GCPA",year,GCPA)
  WriteDisk(db,"EOutput/GCPANet",year,GCPANet)
  WriteDisk(db,"SOutput/OMExp",year,OMExp)
  WriteDisk(db,"EGOutput/PInvTemp",year,PInvTemp)

end

function UnitSummary(data::Data)

  es,ecc,ElectricUtilitySelected = GetElectricSets(data)
  
  InitializeUnitSummary(data,ecc)

  UtilityUnits = GetUtilityUnits(data)

  for unit in UtilityUnits
    plant,node,genco,area = GetUnitSets(data,unit)
    UnitIsOnline = CheckOnline(data,unit)

    if UnitIsOnline == "True"

      UnitCapacityAccumulate(data,unit,plant,area)
      UnitGenerationAccumulate(data,unit,plant,area)

      UnitDoesNotBurnFuel = CheckDoesUnitBurnFuel(data,plant)
      if UnitDoesNotBurnFuel == "True"
        FuelUsageIfDoesNotBurnFuel(data,ecc,unit,plant,area)
      else
        FuelUsageIfDoesBurnFuel(data,unit,plant,area)
        AssignCapacityToLargestFuel(data,unit,area)
        AllocateCapacityBetweenFuels(data,unit,area)
        SplitGenerationAndFuelUseBetweenFuels(data,unit,plant,area,ecc)
      end

    end
  end

  #
  # ResetUnitSets
  # 
  PutUnitSummary(data)

end

# Page 3 - Totals not computed elsewhere

function RenewableGeneration(data::Data)
  (; db,year) = data
  (; Areas) = data
  (; RnGen,RnSwitch,EGPA) = data

  for area in Areas
    plants = findall(RnSwitch[:,area] .> 0)
    RnGen[area] = sum(EGPA[plant,area] for plant in plants)
  end
  WriteDisk(db,"EGOutput/RnGen",year,RnGen)

end

function ElectricUtilityFuelUsage(data::Data)
  (; db,year) = data
  (; Areas,ECC,ES,Fuels) = data
  (; DmdFA,DmdES,EuDemand,TotDemand) = data

  ecc = Select(ECC,"UtilityGen")
  es = Select(ES,"Electric")

  for area in Areas, fuel in Fuels
    DmdES[es,fuel,area] = DmdFA[fuel,area]
    EuDemand[fuel,ecc,area] = DmdFA[fuel,area]
    TotDemand[fuel,ecc,area] = DmdFA[fuel,area]
  end

  WriteDisk(db,"SOutput/EuDemand",year,EuDemand)
  WriteDisk(db,"SOutput/DmdES",year,DmdES)
  WriteDisk(db,"SOutput/TotDemand",year,TotDemand)

end

function InvestmentInDevices(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuels) = data
  (; DInv,DInvEU,PInv,PInvTemp) = data

  ecc = Select(ECC,"UtilityGen")
  for area in Areas
    DInv[ecc,area] = sum(DInvEU[fuel,area] for fuel in Fuels)
    PInv[ecc,area] = sum(PInvTemp[fuel,area] for fuel in Fuels)
  end
  WriteDisk(db,"SOutput/DInv",year,DInv)
  WriteDisk(db,"SOutput/PInv",year,PInv)

end

function TransmissionAndDistributionInvestments(data::Data)
  (; db,year) = data
  (; Areas,Plants) = data
  (; GCPA,Inflation,TDInv,TDInvFr) = data

  for area in Areas
    TDInv[area] = sum(GCPA[plant,area]*TDInvFr[plant,area] for plant in Plants)*
      Inflation[area]*1000/1000000
  end
  WriteDisk(db,"SOutput/TDInv",year,TDInv)

end

function ExpendituresForFuel(data::Data)
  (; db,year) = data
  (; Areas,ECC,Fuels) = data
  (; FuelExp,FuelExpenditures) = data

  ecc = Select(ECC,"UtilityGen")
  for area in Areas
    FuelExpenditures[ecc,area] = sum(FuelExp[fuel,area] for fuel in Fuels)
  end
  WriteDisk(db,"SOutput/FuelExpenditures",year,FuelExpenditures)

end

#
# Page 4 - Interface between Electric Utility and Economy
#
function ProductionByArea(data::Data)
  (; db,year) = data
  (; Areas,Plants) = data
  (; EAProd,EGPA) = data

  #
  # Production (Generation) by Area
  #
  for area in Areas, plant in Plants
    EAProd[plant,area] = EGPA[plant,area]
  end
  WriteDisk(db,"SOutput/EAProd",year,EAProd)

end

function ElectricUtilityDriverIsGeneration(data::Data)
  (; db,year) = data
  (; Areas,ECC,Plants) = data
  (; Driver,EGPA) = data

  ecc = Select(ECC,"UtilityGen")
  for area in Areas
    Driver[ecc,area] = sum(EGPA[plant,area] for plant in Plants)
  end
  WriteDisk(db,"MOutput/Driver",year,Driver)

end

function EUEconomyInterface(data::Data)
  #
  # Electric Utility interface with Economy Sector
  #

  # @info "EFuelUsage - EUEconomyInterface"

  ProductionByArea(data)
  ElectricUtilityDriverIsGeneration(data)

end

#
# Page 5 - TIM Model Variables
#
function ProvincialEnergyProduction(data::Data)

  #
  # TODOTIM After October
  #

  # GetCanadaAreas() # function not called and removed from Julia code
  # 
  # GetSmallAreas() # function not called and removed from Julia code
  # 

end

#
# Front Page "Headlines"
#
function RunFuelUsage(data::Data)

  # @info "EFuelUsage - RunFuelUsage"

  FuelUsage(data)

  UnitSummary(data)

  RenewableGeneration(data)
  ElectricUtilityFuelUsage(data)
  InvestmentInDevices(data)
  TransmissionAndDistributionInvestments(data)
  ExpendituresForFuel(data)

  EUEconomyInterface(data)

  # @info "EFuelUsage - End of RunFuelUsage"

end

end # module EFuelUsage
