#
# Market_GHG.jl - Emission Market Variables
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


Base.@kwdef struct Market_GHGData
  db::String

  # Input::String = "EInput"
  # Outpt::String = "EOutput"
  # CalDB::String = "ECalDB"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  Iter::SetArray = ReadDisk(db, "MainDB/IterKey")
  Iters::Vector{Int} = collect(Select(Iter))
  Market::SetArray = ReadDisk(db, "MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  PCov::SetArray = ReadDisk(db, "MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db, "MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  # Year as a Float32, for use in comparison with other Float32
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  AreaMarket::VariableArray{3} = ReadDisk(db, "SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  CapTrade::VariableArray{2} = ReadDisk(db, "SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade, Cap Only=2)
  Driver::VariableArray{3} = ReadDisk(db, "MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  DriverRef::VariableArray{3} = ReadDisk(BCNameDB, "MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  ECCMarket::VariableArray{3} = ReadDisk(db, "SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db, "SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  Enforce::VariableArray{1} = ReadDisk(db, "SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  EORCredits::VariableArray{4} = ReadDisk(db, "SOutput/EORCredits") # [ECC,Poll,Area,Year] Emissions Credits for using CO2 for EOR (Tonnes/Yr)
  ETABY::VariableArray{1} = ReadDisk(db, "SInput/ETABY") # [Market] Beginning Year for Emission Trading Allowances (Year)
  ETADAP::VariableArray{2} = ReadDisk(db, "SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government ($/Tonne)
  ETAFAP::VariableArray{2} = ReadDisk(db, "SInput/ETAFAP") # [Market,Year] Cost of Foreign Allowances ($/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db, "SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  ETAPr::VariableArray{2} = ReadDisk(db, "SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances ($/Tonne)
  ETR::VariableArray{3} = ReadDisk(db, "SOutput/ETR") # [Market,Iter,Year] Permit Costs ($/Tonne)
  ETRSw::VariableArray{1} = ReadDisk(db, "SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate, 2=Old Method, 0=Exogenous)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [PointerCN,Year] Local Currency/US$ Exchange Rate (Local/US$)
  FBuy::VariableArray{2} = ReadDisk(db, "SOutput/FBuy") # [Market,Year] Federal (Domestic) Permits Bought (Tonnes/Year)
  FInventory::VariableArray{2} = ReadDisk(db, "SOutput/FInventory") # [Market,Year] Federal (Domestic) Permits Inventory (Tonnes)
  FSell::VariableArray{2} = ReadDisk(db, "SOutput/FSell") # [Market,Year] Indicated Federal Permits Sold (Tonnes/Year)
  GratSw::VariableArray{1} = ReadDisk(db, "SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous)
  GoalPol::VariableArray{2} = ReadDisk(db, "SOutput/GoalPol") # [Market,Year] Pollution Goal (Tonnes/Year)
  GPol::VariableArray{3} = ReadDisk(db, "SOutput/GPol") # [Market,Iter,Year] Market Emissions Goal (Tonnes/Yr)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [PointerCN,Year] CN Inflation Index ($/$)
  ISell::VariableArray{2} = ReadDisk(db, "SOutput/ISell") # [Market,Year] International Permits Sold (Tonnes/Year)
  MEReduce::VariableArray{4} = ReadDisk(db, "SOutput/MEReduce") # [ECC,Poll,Area,Year] Reductions from Economic Activity Emissions (Tonnes/Yr)
  MPol::VariableArray{3} = ReadDisk(db, "SOutput/MPol") # [Market,Iter,Year] Market Covered Emissions (Tonnes/Yr)
  OffGeneric::VariableArray{3} = ReadDisk(db, "SOutput/OffGeneric") # [Market,Poll,Year] Offsets Used (Tonnes)
  OffMktFr::VariableArray{4} = ReadDisk(db, "SInput/OffMktFr") # [ECC,Area,Market,Year] Fraction of Offsets allocated to each Market (Tonnes/Tonnes)
  OffsetsElec::VariableArray{4} = ReadDisk(db, "SOutput/OffsetsElec") # [ECC,Poll,Area,Year] Offsets from Electric Generation Units (Tonnes/Yr)
  Over::VariableArray{3} = ReadDisk(db, "SOutput/Over") # [Market,Iter,Year] Market Emissions Overage (Tonnes/Yr)
  PBank::VariableArray{4} = ReadDisk(db, "SOutput/PBank") # [ECC,Poll,Area,Year] Permits Banked (Tonnes/Yr)
  PAuction::VariableArray{2} = ReadDisk(db, "SOutput/PAuction") # [Market,Year] Permits Available for Auction (Tonnes/Year)
  PBuy::VariableArray{4} = ReadDisk(db, "SOutput/PBuy") # [ECC,Poll,Area,Year] Permits Bought (Tonnes/Year)
  PCovMarket::VariableArray{3} = ReadDisk(db, "SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PGratis::VariableArray{5} = ReadDisk(db, "SOutput/PGratis") # [ECC,Poll,PCov,Area,Year] Gratis Permits (Tonnes/Year)
  PInventory::VariableArray{4} = ReadDisk(db, "SOutput/PInventory") # [ECC,Poll,Area,Year] Permit Inventory (Tonnes)
  PNeed::VariableArray{4} = ReadDisk(db, "SOutput/PNeed") # [ECC,Poll,Area,Year] Permits Needed (Tonnes/Year)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PolCov::VariableArray{5} = ReadDisk(db, "SOutput/PolCov") # [ECC,Poll,PCov,Area,Year] Covered Pollution (Tonnes/Yr)
  PolCovRef::VariableArray{5} = ReadDisk(db, "SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PolImports::VariableArray{3} = ReadDisk(db, "SOutput/PolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  PolImportsRef::VariableArray{3} = ReadDisk(BCNameDB, "SOutput/PolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  PolTot::VariableArray{5} = ReadDisk(db, "SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Total Pollution (Tonnes/Yr)
  PolTotRef::VariableArray{5} = ReadDisk(BCNameDB, "SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Total Pollution (Tonnes/Yr)
  PollMarket::VariableArray{3} = ReadDisk(db, "SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  PRedeem::VariableArray{4} = ReadDisk(db, "SOutput/PRedeem") # [ECC,Poll,Area,Year] Permits Redeemed from Inventory (Tonnes/Yr)
  PSell::VariableArray{4} = ReadDisk(db, "SOutput/PSell") # [ECC,Poll,Area,Year] Permits Sold (Tonnes/Year)
  SqPGMult::VariableArray{4} = ReadDisk(db, "SInput/SqPGMult") # [ECC,Poll,Area,Year] Sequestering Gratis Permit Multiplier (Tonnes/Tonnes)
  SqPol::VariableArray{4} = ReadDisk(db, "SOutput/SqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)
  SqPolRef::VariableArray{4} = ReadDisk(BCNameDB, "SOutput/SqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)
  TGratis::VariableArray{2} = ReadDisk(db, "SOutput/TGratis") # [Market,Year] Total Gratis Permits (Tonnes/Year)
  UnArea::Array{String} = ReadDisk(db, "EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::VariableArray{1} = ReadDisk(db, "EGInput/UnCounter") #[Year]  Number of Units
  UnCoverage::VariableArray{3} = ReadDisk(db, "EGInput/UnCoverage") # [Unit,Poll,Year] Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnGenCo::Array{String} = ReadDisk(db, "EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db, "EGInput/UnNode") # [Unit] Transmission Node
  UnPGratis::VariableArray{3} = ReadDisk(db, "EGOutput/UnPGratis") # [Unit,Poll,Year] Gratis Permits (Tonnes/Yr)
  UnPlant::Array{String} = ReadDisk(db, "EGInput/UnPlant") # [Unit] Plant Type
  UnSector::Array{String} = ReadDisk(db, "EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  xETAPr::VariableArray{2} = ReadDisk(db, "SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xFSell::VariableArray{2} = ReadDisk(db, "SInput/xFSell") # [Market,Year] Federal (Domestic) Permits Available (Tonnes/Year)
  xISell::VariableArray{2} = ReadDisk(db, "SInput/xISell") # [Market,Year] International Permits Available (Tonnes/Year)
  xPolCap::VariableArray{5} = ReadDisk(db, "SInput/xPolCap") # [ECC,Poll,PCov,Area,Year] Exogenous Emissions Cap (Tonnes/Year)

  # Scratch Variables
  Agric::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Agriculture Offsets (Mt)
  # AreaName Type=String(30)
  ECovMarket::VariableArray{5} = zeros(Float32, length(ECC), length(Poll), length(PCov), length(Area), length(Year)) # [ECC,Poll,PCov,Area,Year] Emissions Coverage for this Market (1=Covered)
  EEE::VariableArray{2} = zeros(Float32, length(ECC), length(Year)) # [ECC,Year] Sector Subtotal Variable
  EI::VariableArray{2} = zeros(Float32, length(ECC), length(Year)) # [ECC,Year] Emissions Intensity (Tonnes/Driver)
  EIRef::VariableArray{2} = zeros(Float32, length(ECC), length(Year)) # [ECC,Year] Reference Case Emissions Intensity (Tonnes/Driver)
  Emissions::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Emissions (Mt)
  Forest::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Forestry Offsets (Mt)
  GrossRef::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Reference Case Emissions (Mt)
  IPermits::VariableArray{1} = zeros(Float32, length(Year)) # [Year] International Permits Bought (Mt)
  IR::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Internal Reductions (Mt)
  InvChange::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Change in Permit Inventory (Mt)
  # MktName  Type=String(50)
  NetEmissions::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Net Emissions (Mt)
  NetRef::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Reference Case Emissions Net of Production Reductions (Mt)
  OffCogen::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Recognition of Cogeneration (Mt)
  OffElectric::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Electric Generation Offsets (Mt)
  OffMT::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Generic Offsets (Mt)
  OffsetECC::VariableArray{2} = zeros(Float32, length(ECC), length(Year)) # [ECC,Year] Offsets (Mt)
  OverFrac::VariableArray{2} = zeros(Float32, length(Iter), length(Year)) # [Iter,Year] Overage Fraction (Mt/Mt)
  Overage::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Overage (Mt)
  PPBuy::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Permits Purchased (Mt/Yr)
  Reduce::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Reductions (Mt)
  Sequest::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Sequestering (Mt)
  SequestEOR::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Sequestering EOR Credit (Mt)
  SolidW::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Solid Waste Offsets (Mt)
  TFAvePrice::VariableArray{1} = zeros(Float32, length(Year)) # [Year] TF Average Price (CDYear CN$/Tonne)
  TIFBuy::VariableArray{1} = zeros(Float32, length(Year)) # [Year] TIF Permits Bought by Government (Mt)
  TIFSold::VariableArray{1} = zeros(Float32, length(Year)) # [Year] TIF Permits Sold by Government (Mt)
  Target::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Emissions Target (Mt)
  # UnPGratis::VariableArray{3} = zeros(Float32, length(Unit), length(Poll), length(Year)) # [Unit,Poll,Year] Gratis Permits (Tonnes/Yr)
  WaterW::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Wastewater Offsets (Mt)
  ZZZ::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Display Variable
end

function GetUnitSetsMG(data,unit)
  (; Area,ECC,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant,UnSector) = data

  #
  # This procedure selects the sets for a particular unit
  #
  if (UnGenCo[unit]  != "Null") && (UnPlant[unit] != "Null") &&
     (UnNode[unit]   != "Null") && (UnArea[unit]  != "Null") &&
     (UnSector[unit] != "Null")
    genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    valid = true
  else
    genco=1
    plant=1
    node=1
    area=1
    ecc=1
    valid = false
  end

  return genco,plant,node,area,ecc,valid
end # GetUnitSets


function Market_GHG_DtaRun(data,market,MktName)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Iter,Iters,Market,
  Markets,Nation,PCov,PCovDS,PCovs,Poll,PollDS,Polls,Unit,Units,Year,Years,
  Yrv,CDTime,CDYear,SceName) = data
  (; AreaMarket,CapTrade,Driver,DriverRef,ECCMarket,ECoverage,Enforce,EORCredits,ETABY,ETADAP,
  ETAFAP, ETAIncr,ETAPr,ETR,ETRSw,ExchangeRateNation,FBuy,FInventory,FSell,GratSw,
  GoalPol, GPol,InflationNation,ISell,MEReduce,MPol,OffGeneric,OffMktFr,OffsetsElec,Over,
  PBank, PAuction,PBuy,PCovMarket,PGratis,PInventory,PNeed,PolConv,PolCov,PolCovRef,PolImports,PolImportsRef,
  PolTot,PolTotRef, PollMarket,PRedeem,PSell,SqPGMult,SqPol,SqPolRef,TGratis,UnArea,UnCogen,UnCoverage,
  UnGenCo, UnNode,UnPlant,UnSector,xETAPr,xFSell,xISell,xPolCap) = data
  (; Agric,ECovMarket,EEE,EI,EIRef,Emissions,Forest,GrossRef,IPermits,
  IR, InvChange,NetEmissions,NetRef,OffCogen,OffElectric,OffMT,OffsetECC,OverFrac,Overage,
  PPBuy, Reduce,Sequest,SequestEOR,SolidW,TFAvePrice,TIFBuy,TIFSold,Target,UnCounter,UnPGratis,
  WaterW,ZZZ) = data

  Yr2007=2007-ITime+1
  Yr2000=2000-ITime+1
  Yr2020=2020-ITime+1

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; sheet name and scenario")
  println(iob, " ")
  println(iob, "This is the Market $market Summary")
  println(iob, " ")

  #
  # Select Market and Sets
  #
  eccs = findall(ECCMarket[:,market,Yr2020] .== 1)
  polls = findall(PollMarket[:,market,Yr2020] .== 1)
  pcovs = findall(PCovMarket[:,market,Yr2020] .== 1)
  areas = findall(AreaMarket[:,market,Yr2020] .== 1)

  emptysets=false
  if isempty(eccs)
    println(iob, "eccs from Market empty")
    emptysets=true
  end
  if isempty(polls)
    println(iob, "polls from Market empty")
    emptysets=true
  end
  if isempty(pcovs)
    println(iob, "pcovs from Market empty")
    emptysets=true
  end
  if isempty(pcovs)
    println(iob, "pcovs from Market empty")
    emptysets=true
  end
  if emptysets == true
    println(iob, "Stopping File")
  elseif emptysets == false
    CN = Select(Nation,"CN")
    US = Select(Nation,"US")

    #
    # Termporaily assign values for output purposes
    #
    for y in Years, a in areas, pcov in pcovs, p in polls, e in eccs
      ECovMarket[e,p,pcov,a,y]=ECoverage[e,p,pcov,a,y]
    end
    years = Select(Year,(from="1990", to="2006"))
    for y in years, a in areas, pcov in pcovs, p in polls, e in eccs
      ECovMarket[e,p,pcov,a,y]=ECoverage[e,p,pcov,a,Yr2007]
    end

    #
    # Reference Case Covered Emissions
    #
    years = Select(Year,(from="1990", to="2006"))
    for y in years, a in areas, pcov in pcovs, p in polls, e in eccs
      PolCovRef[e,p,pcov,a,y]=PolTotRef[e,p,pcov,a,y]*ECovMarket[e,p,pcov,a,y]*PolConv[p]
    end

    years = union(Select(Year,"1990"),collect(Yr2000:Final))
    println(iob, "Year;", ";    ", join(Year[years], ";"))
    println(iob, " ")

    #
    # Show all ECCs
    #

    #
    # Covered Emissions
    #
    for y in years, a in areas, pcov in pcovs, p in polls, e in ECCs
      @finite_math PolCov[e,p,pcov,a,y]=PolCov[e,p,pcov,a,y]*(ECovMarket[e,p,pcov,a,y]/ECovMarket[e,p,pcov,a,y])
    end
    for y in years, a in areas, pcov in pcovs, p in polls, e in ECCs
      @finite_math PolCovRef[e,p,pcov,a,y]=PolCovRef[e,p,pcov,a,y]*(ECovMarket[e,p,pcov,a,y]/ECovMarket[e,p,pcov,a,y])
    end

    #
    # Emission Intensity (Covered)
    #
    for y in years, e in ECCs
      @finite_math EI[e,y]   =
        sum(PolCov[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6/
        sum(Driver[e,aa,y] for aa in areas)
      @finite_math EIRef[e,y] = 
        sum(PolCovRef[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6/
        sum(Driver[e,aa,y] for aa in areas)
    end

    #
    # Emissions
    #
    UtilityGen = Select(ECC,"UtilityGen")
    Energy = Select(PCov,"Energy")

    for y in years
      GrossRef[y] = sum(EIRef[ecc,y]*sum(DriverRef[ecc,a,y] for a in areas) for ecc in ECCs)+
                    sum(PolImportsRef[p,aa,y]*
                    ECovMarket[UtilityGen,p,Energy,aa,y]*PolConv[p] for aa in areas, p in polls)/1e6

      NetRef[y]=sum(EIRef[ecc,y]*sum(Driver[ecc,a,y] for a in areas) for ecc in ECCs)+
                sum(PolImportsRef[p,aa,y]*
                ECovMarket[UtilityGen,p,Energy,aa,y]*PolConv[p] for aa in areas, p in polls)/1e6

      Emissions[y]=sum(EIRef[ecc,y]*sum(Driver[ecc,a,y] for a in areas) for ecc in ECCs)+
                sum(PolImports[p,aa,y]*
                ECovMarket[UtilityGen,p,Energy,aa,y]*PolConv[p] for aa in areas, p in polls)/1e6

      Target[y]=GoalPol[market,y]/1e6

      #
      # Offsets for Process Emission Reductions
      #
      for e in ECCs
        OffsetECC[e,y]=sum(MEReduce[e,p,a,y]*
                          PolConv[p]*OffMktFr[e,a,market,y] for a in areas, p in polls)/1e6
      end

      #
      # Add back emissions used as offsets
      #
      Emissions[y]=Emissions[y]+sum(OffsetECC[ecc,y]*ECCMarket[ecc,market,y] for ecc in ECCs)

      #
      # Offset Groupings
      #
      farm_eccs = Select(ECC,["OnFarmFuelUse","CropProduction","AnimalProduction"])
      Agric[y]=sum(OffsetECC[ecc,y] for ecc in farm_eccs)

      Forestry = Select(ECC,"Forestry")
      Forest[y]=sum(OffsetECC[ecc,y] for ecc in Forestry)

      SolidWaste = Select(ECC,"SolidWaste")
      SolidW[y]=sum(OffsetECC[ecc,y] for ecc in SolidWaste)

      Wastewater = Select(ECC,"Wastewater")
      WaterW[y]=sum(OffsetECC[ecc,y] for ecc in Wastewater)

      #
      OffElectric[y]=sum(OffsetsElec[e,p,a,y]*
                    OffMktFr[e,a,market,y]*PolConv[p] for a in areas, p in polls, e in UtilityGen)/1e6

      eccs_ne = Select(ECC,!=("UtilityGen"))
      OffCogen[y]=sum(OffsetsElec[e,p,a,y]*
                    OffMktFr[e,a,market,y]*PolConv[p] for a in areas, p in polls, e in eccs_ne)/1e6


      Sequest[y]=sum(0-SqPol[e,p,a,y]*
          SqPGMult[e,p,a,y]*PolConv[p]*OffMktFr[e,a,market,y] for a in areas, p in polls, e in ECCs)/1e6

      SequestEOR[y]=sum(0-EORCredits[e,p,a,y]*
          PolConv[p]*OffMktFr[e,a,market,y] for a in areas, p in polls, e in ECCs)/1e6


      OffMT[y]=sum(OffGeneric[market,p,y]*PolConv[p] for p in polls)/1e6

      TIFSold[y]=FSell[market,y]/1e6
      TIFBuy[y]=FBuy[market,y]/1e6
      IPermits[y]=ISell[market,y]/1e6
      NetEmissions[y]=Emissions[y]-Sequest[y]-SequestEOR[y]-Agric[y]-Forest[y]-SolidW[y]-WaterW[y]-
                  OffElectric[y]-OffMT[y]-OffCogen[y]-TIFSold[y]+TIFBuy[y]-IPermits[y]

      InvChange[y]=sum(PBank[e,p,a,y]-
                      PRedeem[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
      TGratis[market,y]=TGratis[market,y]/1e6
      PAuction[market,y]=PAuction[market,y]/1e6
    end


    for y in years
      if Yrv[y] >= Enforce[market]
        Overage[y]=NetEmissions[y]+TIFBuy[y]+InvChange[y]-Target[y]
      end
      IR[y]=NetRef[y]-Emissions[y]

      Reduce[y]=IR[y]+Sequest[y]+SequestEOR[y]+Agric[y]+Forest[y]+SolidW[y]+WaterW[y]+
                OffElectric[y]+OffMT[y]+OffCogen[y]+TIFSold[y]-TIFBuy[y]+IPermits[y]
    end

    #
    #########################
    #
    println(iob, MktName, " Emissions Summary (Mt/Year);;    ", join(Year[years], ";"))
    print(iob, " ;Reference Case Emissions;")
    
    ZZZ[years]=GrossRef[years]
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    ZZZ[years]=GrossRef[years]-NetRef[years]
    print(iob, " ;Production Reductions;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f", zzz))
    end
    println(iob)

    print(iob, " ;Reference Case Emissions Net of Production Reductions;")
    for zzz in NetRef[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Internal Reductions;")
    for zzz in IR[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Covered Emissions;")
    for zzz in Emissions[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=sum(0-SqPolRef[e,p,a,y]*
        PolConv[p] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, " ;Reference Case Sequestering;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=sum(0-SqPol[e,p,a,y]*
        PolConv[p] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, " ;Policy Sequestering;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Sequestering Credits;")
    for zzz in Sequest[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Sequestering EOR Credits;")
    for zzz in SequestEOR[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Agriculture Offsets;")
    for zzz in Agric[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Forestry Offsets;")
    for zzz in Forest[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Solid Waste Offsets;")
    for zzz in SolidW[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Wastewater Offsets;")
    for zzz in WaterW[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Electric Generation Offsets;")
    for zzz in OffElectric[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Generic Offsets;")
    for zzz in OffMT[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Recognition of Cogeneration;")
    for zzz in OffCogen[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Tier 1 TIF;")
    for zzz in TIFSold[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Tier 1 TIF Removed;")
    for zzz in TIFBuy[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Tier 2 TIF;")
    for zzz in IPermits[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    ZZZ[years]=TIFSold[years].-TIFBuy[years].+IPermits[years]
    print(iob, " ;TIF Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Reductions;")
    for zzz in Reduce[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Net Emissions;")
    for zzz in NetEmissions[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Emission Target;")
    for zzz in Target[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Gratis Permits;")
    for zzz in TGratis[market,years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Auctioned Permits;")
    for zzz in PAuction[market,years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Inventory Change;")
    for zzz in InvChange[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    print(iob, " ;Overage;")
    for zzz in Overage[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    println(iob, MktName, " Cost of Trading Allowances ($CDTime  CN\$/Tonne);;    ", join(Year[years], ";"))

    for y in years
      ZZZ[y]=ETAPr[market,y]*ExchangeRateNation[CN,y]/InflationNation[CN,y]*InflationNation[CN,CDYear]
    end
    print(iob, " ;Marginal;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=ETADAP[market,y]*ExchangeRateNation[CN,y]/InflationNation[CN,y]*InflationNation[CN,CDYear]
    end
    print(iob, " ;Tier 1;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=ETAFAP[market,y]*ExchangeRateNation[CN,y]/InflationNation[CN,y]*InflationNation[CN,CDYear]
    end
    print(iob, " ;Tier 2;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      PPBuy[y]=sum(PBuy[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
      @finite_math TFAvePrice[y]=(ETADAP[market,y]*ExchangeRateNation[CN,y]*InflationNation[CN,CDYear]*TIFSold[y]+
        ETAFAP[market,y]*ExchangeRateNation[CN,y]*InflationNation[CN,CDYear]*IPermits[y]+
        ETAPr[market,y]*ExchangeRateNation[CN,y]/InflationNation[CN,y]*InflationNation[CN,CDYear]*
        (PPBuy[y]-TIFSold[y]-IPermits[y]))/PPBuy[y]
      ZZZ[y]=TFAvePrice[y]
    end
    print(iob, " ;Average;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=xETAPr[market,y]*ExchangeRateNation[CN,y]*InflationNation[CN,CDYear]
    end
    print(iob, " ;Price before Iterations;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    println(iob, MktName, " Technology Fund Summary (Tonnes);;    ", join(Year[years], ";"))

    ZZZ[years]=xFSell[market,years]/1e6
    print(iob, " ;Tier 1 Maximum Availiable;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    ZZZ[years]=FSell[market,years]/1e6
    print(iob, " ;Tier 1 Sold into Market;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    ZZZ[years]=xISell[market,years]/1e6
    print(iob, " ;Tier 2 Maximum Availiable;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    ZZZ[years]=ISell[market,years]/1e6
    print(iob, " ;Tier 2 Sold into Market;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=(FSell[market,y]+ISell[market,y])/1e6
    end
    print(iob, " ;Total Sold into Market;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    ZZZ[years]=FBuy[market,years]/1e6
    print(iob, " ;Tier 1 Removed from Market;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    ZZZ[years]=FInventory[market,years]/1e6
    print(iob, " ;Tier 1 Balance in Reserve;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    println(iob, MktName, " Technology Fund Revenue ($CDTime  CN M\$);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=(FSell[market,y]+ISell[market,y])*TFAvePrice[y]/1e6
    end
      print(iob, " ;Revenue from TF Sold into Market;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=FBuy[market,y]*TFAvePrice[y]/1e6
    end
      print(iob, " ;Expense of TF Purchased from Market;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=(FSell[market,y]+ISell[market,y]-FBuy[market,y])*TFAvePrice[y]/1e6
    end
      print(iob, " ;Net Revenue from TF Sold into Market;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    println(iob, MktName, " Trading Activity Summary (Mt/Year);;    ", join(Year[years], ";"))

    for y in years
      ZZZ[y]=sum(PSell[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, " ;Sold;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=sum(PBuy[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, " ;Bought;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=sum(PBank[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, " ;Banked to Inventory;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=sum(PRedeem[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, " ;Sold From Inventory;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)

    for y in years
      ZZZ[y]=sum(PInventory[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, " ;Inventory;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    # Reference Case Covered Emissions
    #
    println(iob, MktName, " Reference Case Covered Emissions (Mt/Year);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=(sum(PolCovRef[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)+
              sum(PolImportsRef[pp,aa,y]*
              ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls))/1e6
    end
    print(iob, "PolCovRef;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PolCovRef[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6
      end
      print(iob, "PolCovRef;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    for y in years
      ZZZ[y]=sum(PolImportsRef[pp,aa,y]*
            ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls)/1e6
    end
    print(iob, "PolImportsRef;Electric Imports;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    # Reference Case Covered Emissions with Production Reductions
    #
    println(iob, MktName, " Reference Case Covered Emissions with Production Reductions (Mt/Year);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=sum(EIRef[e,y]*sum(Driver[e,a,y] for a in areas) for e in ECCs)+
             sum(PolImportsRef[pp,aa,y]*
             ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls)/1e6
    end
    print(iob, "PolCovRefPR;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=EIRef[e,y]*sum(Driver[e,a,y] for a in areas)
      end
      print(iob, "PolCovRefPR;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    for y in years
      ZZZ[y]=sum(PolImportsRef[pp,aa,y]*
            ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls)/1e6
    end
    print(iob, "PolImportsRefPR;Electric Imports;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    # Policy Covered Emissions
    #
    println(iob, MktName, " Covered Emissions (Mt/Year);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=(sum(PolCov[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)+
              sum(PolImports[pp,aa,y]*
              ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls))/1e6
    end
    print(iob, "PolCov;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PolCov[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6
      end
      print(iob, "PolCov;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    for y in years
      ZZZ[y]=sum(PolImports[pp,aa,y]*
            ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls)/1e6
    end
    print(iob, "PolImports;Electric Imports;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    # Reference Case Driver
    #
    pcov1=first(pcovs)
    poll1=first(polls)
    println(iob, MktName, " Reference Case Driver (Various Units/Year);;    ", join(Year[years], ";"))
    for y in years, a in areas, e in ECCs
      @finite_math DriverRef[e,a,y]=DriverRef[e,a,y]*(ECovMarket[e,poll1,pcov1,a,y]/
                   ECovMarket[e,poll1,pcov1,a,y])
    end
    for e in ECCs
      for y in years
        ZZZ[y]=sum(DriverRef[e,a,y] for a in areas)
      end
      print(iob, "DriverRef;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Driver
    #
    println(iob, MktName, " Driver (Various Units/Year);;    ", join(Year[years], ";"))
    for y in years, a in areas, e in ECCs
      @finite_math Driver[e,a,y]=Driver[e,a,y]*(ECovMarket[e,poll1,pcov1,a,y]/ECovMarket[e,poll1,pcov1,a,y])
    end
    for e in ECCs
      for y in years
        ZZZ[y]=sum(Driver[e,a,y] for a in areas)
      end
      print(iob, "Driver;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Reference Case Emissions Intensity
    #
    println(iob, MktName, " Reference Case Emissions Intensity (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for e in ECCs
      ZZZ[years]=EIRef[e,years]*1000
      print(iob, "EIRef;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emissions Intensity
    #
    println(iob, MktName, " Emissions Intensity (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for e in ECCs
      ZZZ[years]=EI[e,years]*1000
      print(iob, "EI;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emissions Intensity Target
    #
    println(iob, MktName, " Emissions Intensity Target (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for e in ECCs
      for y in years
        @finite_math ZZZ[y]=(sum(xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6/
                             sum(Driver[e,aa,y] for aa in areas))*1000
      end
      print(iob, "EI Target;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emission Intensity adjusted for Credits
    #
    println(iob, MktName, " Emissions Intensity with Credits (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for y in years, a in areas, p in polls, e in ECCs
      @finite_math PBuy[e,p,a,y]=PBuy[e,p,a,y]*(ECovMarket[e,p,pcov1,a,y]/ECovMarket[e,p,pcov1,a,y])
    end
    for e in ECCs
      for y in years
        @finite_math ZZZ[y]=(sum(PolCov[e,p,pcov,a,y]-PGratis[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)-
          sum(PBuy[e,pp,aa,y] for aa in areas, pp in polls))/1e6/sum(Driver[e,aaa,y] for aaa in areas)*1000
      end
      print(iob, "EI w/Credits;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emissions Cap
    #
    println(iob, MktName, " Emissions Cap (Mt/Year);;    ", join(Year[years], ";"))
    for y in years, a in areas, pcov in pcovs, p in polls, e in ECCs
      @finite_math xPolCap[e,p,pcov,a,y]=xPolCap[e,p,pcov,a,y]*(ECovMarket[e,p,pcov,a,y]/ECovMarket[e,p,pcov,a,y])
    end
    for y in years
      ZZZ[y]=sum(xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)/1e6
    end
    print(iob, "xPolCap;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6
      end
      print(iob, "xPolCap;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Permits Issued Permits (Gratis Permits)
    #
    println(iob, MktName, " Permits Issued (Mt/Year);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=sum(PGratis[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)/1e6
    end
    print(iob, "PGratis;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PGratis[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6
      end
      print(iob, "PGratis;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Permits Issued excluding Cogeneration Permits (Gratis Permits)
    #
    println(iob, MktName, " Permits Issued excluding Cogeneration Permits (Mt/Year);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=sum(xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)/1e6
    end
    print(iob, "PGratis xPolCap;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6
      end
      print(iob, "PGratis xPolCap;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Cogeneration Permits (Gratis Permits)
    #
    println(iob, MktName, " Cogeneration Permits (Mt/Year);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=sum(PGratis[e,p,pcov,a,y]-xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)/1e6
    end
    print(iob, "PGratis Cogen;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PGratis[e,p,pcov,a,y]-xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6
      end
      print(iob, "PGratis Cogen;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Required Reductions
    #
    println(iob, MktName, " Required Reductions (Tonnes);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=sum(PolCovRef[e,p,pcov,a,y]-xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)/1e6
    end
    print(iob, "RR;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PolCovRef[e,p,pcov,a,y]-xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/1e6
      end
      print(iob, "RR;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Required Reduction Fraction
    #
    println(iob, MktName, " Required Reduction Fraction (Tonne/Tonne);;    ", join(Year[years], ";"))
    for y in years
      @finite_math ZZZ[y]=sum(PolCovRef[e,p,pcov,a,y]-xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls, e in ECCs)/
            sum(PolCovRef[ee,pp,ppcov,aa,y] for aa in areas, ppcov in pcovs, pp in polls, ee in ECCs)
    end
    print(iob, "RR Fraction;Average;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        @finite_math ZZZ[y]=sum(PolCovRef[e,p,pcov,a,y]-xPolCap[e,p,pcov,a,y] for a in areas, pcov in pcovs, p in polls)/
          sum(PolCovRef[e,pp,ppcov,aa,y] for aa in areas, ppcov in pcovs, pp in polls)
      end
      print(iob, "RR Fraction;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Internal Reductions
    #
    println(iob, MktName, " Internal Reductions (Tonnes);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=sum((EIRef[e,y]-EI[e,y])*sum(Driver[e,a,y] for a in areas) for e in ECCs)+
        sum((PolImportsRef[pp,aa,y]-PolImports[pp,aa,y])*
        ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls)/1e6
    end
    print(iob, "IR;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=(EIRef[e,y]-EI[e,y])*sum(Driver[e,a,y] for a in areas)
      end
      print(iob, "IR;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    for y in years
      ZZZ[y]=sum((PolImportsRef[pp,aa,y]-PolImports[pp,aa,y])*
            ECovMarket[UtilityGen,pp,Energy,aa,y]*PolConv[pp] for aa in areas, pp in polls)/1e6
    end
    print(iob, "IR;Electric Imports;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    #
    # Sequestering
    #
    println(iob, MktName, " Sequestering (Mt/Year);;    ", join(Year[years], ";"))
    for y in years
      ZZZ[y]=sum(0-SqPol[e,p,a,y]*PolConv[p]*OffMktFr[e,a,market,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, "SqPol;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(0-SqPol[e,p,a,y]*PolConv[p]*OffMktFr[e,a,market,y] for a in areas, p in polls)/1e6
      end
      print(iob, "SqPol;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    @. EEE = 0.0
    YrEnforce = Int(Enforce[market])-ITime+1
    poll = first(polls)
    for unit in Units
      genco,plant,node,area,ecc,valid = GetUnitSetsMG(data,unit)
      if valid == true
        if (UnCoverage[unit,poll,YrEnforce] == 1) &&
           (UnCogen[unit] > 0) &&
           (AreaMarket[area,market,YrEnforce] == 1) &&
           (ECCMarket[ecc,market,YrEnforce] == 1)
          for year in years
            EEE[ecc,year] = EEE[ecc,year]+sum(UnPGratis[unit,poll,year] for poll in polls)
          end
        end
      end
    end
    
    println(iob, MktName, " Cogeneration Credits (Mt/Yr);;    ", join(Year[years], ";"))    
    for y in years
      ZZZ[y]=sum(EEE[e,y] for e in ECCs)/1e6
    end
    print(iob, "UnPGratis;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=EEE[e,y]/1e6
      end
      print(iob, "UnPGratis;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Permits Sold (Mt/Yr);;    ", join(Year[years], ";"))
    for y in years, a in areas, p in polls, e in ECCs
      @finite_math PSell[e,p,a,y]=PSell[e,p,a,y]*(ECovMarket[e,p,pcov1,a,y]/ECovMarket[e,p,pcov1,a,y])
    end
    for y in years
      ZZZ[y]=sum(PSell[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, "PSell;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PSell[e,p,a,y] for a in areas, p in polls)/1e6
      end
      print(iob, "PSell;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Permits Bought (Mt/Yr);;    ", join(Year[years], ";"))
    for y in years, a in areas, p in polls, e in ECCs
      @finite_math PBuy[e,p,a,y]=PBuy[e,p,a,y]*(ECovMarket[e,p,pcov1,a,y]/ECovMarket[e,p,pcov1,a,y])
    end
    for y in years
      ZZZ[y]=sum(PBuy[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, "PBuy;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PBuy[e,p,a,y] for a in areas, p in polls)/1e6
      end
      print(iob, "PBuy;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Permits Banked to Inventory (Mt/Yr);;    ", join(Year[years], ";"))
    for y in years, a in areas, p in polls, e in ECCs
      @finite_math PBank[e,p,a,y]=PBank[e,p,a,y]*(ECovMarket[e,p,pcov1,a,y]/ECovMarket[e,p,pcov1,a,y])
    end
    for y in years
      ZZZ[y]=sum(PBank[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, "PBank;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PBank[e,p,a,y] for a in areas, p in polls)/1e6
      end
      print(iob, "PBank;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Permits Sold from Inventory (Mt/Yr);;    ", join(Year[years], ";"))
    for y in years, a in areas, p in polls, e in ECCs
      @finite_math PRedeem[e,p,a,y]=PRedeem[e,p,a,y]*(ECovMarket[e,p,pcov1,a,y]/ECovMarket[e,p,pcov1,a,y])
    end
    for y in years
      ZZZ[y]=sum(PRedeem[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, "PRedeem;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PRedeem[e,p,a,y] for a in areas, p in polls)/1e6
      end
      print(iob, "PRedeem;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Inventory Permits (Mt/Yr);;    ", join(Year[years], ";"))
    for y in years, a in areas, p in polls, e in ECCs
      @finite_math PInventory[e,p,a,y]=PInventory[e,p,a,y]*(ECovMarket[e,p,pcov1,a,y]/ECovMarket[e,p,pcov1,a,y])
    end
    for y in years
      ZZZ[y]=sum(PInventory[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, "PInventory;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PInventory[e,p,a,y] for a in areas, p in polls)/1e6
      end
      print(iob, "PInventory;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    #TODOJulia Jeff, How should I address this? Summing across PCov seems like
    # it could create problems, but I don't know the ideal way to set up this test.

    println(iob, MktName, " Permits Needed (Mt/Yr);;    ", join(Year[years], ";"))
    for y in years, a in areas, p in polls, e in ECCs
      @finite_math PNeed[e,p,a,y]=PNeed[e,p,a,y]*(ECovMarket[e,p,pcov1,a,y]/ECovMarket[e,p,pcov1,a,y])
    end
    for y in years
      ZZZ[y]=sum(PNeed[e,p,a,y] for a in areas, p in polls, e in ECCs)/1e6
    end
    print(iob, "PNeed;Total;")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    for e in ECCs
      for y in years
        ZZZ[y]=sum(PNeed[e,p,a,y] for a in areas, p in polls)/1e6
      end
      print(iob, "PNeed;",ECCDS[e],";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Cap Trade Switch;;    ", join(Year[years], ";"))
    ZZZ[years] = CapTrade[market,years]
    print(iob, "CapTrade;$MktName")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    println(iob, MktName, " External Permit Price (\$/\$);;    ", join(Year[years], ";"))
    ZZZ[years] = ETAIncr[market,years]
    print(iob, "ETAIncr;$MktName")
    for zzz in ZZZ[years]
      print(iob, @sprintf("%15.3f;", zzz))
    end
    println(iob)
    println(iob, " ")

    println(iob, MktName, " Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous);;    ", join(Year[years], ";"))
    println(iob, "GratSw;",Int(GratSw[market]))
    println(iob, " ")

    println(iob, MktName, " Beginning Year for Emission Trading Allowances (Year);;    ", join(Year[years], ";"))
    println(iob, "ETABY;",Int(ETABY[market]))
    println(iob, " ")

    #TODOJulia MaxIter not properly defined
    # iters = collect(1:Int(MaxIter))
    iters = collect(1:1)
    println(iob, MktName, " Emission Price ($CDTime CN\$/tonne);;    ", join(Year[years], ";"))
    for iter in iters
      for y in years
        ZZZ[y]=ETR[market,iter,y]*ExchangeRateNation[CN,y]/InflationNation[CN,y]*InflationNation[CN,CDYear]
      end
      print(iob, "ETR;Iter ",iter,";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")


    if ETRSw[market] == 1
      println(iob, MktName, " Permits Bought (Mt);;    ", join(Year[years], ";"))
    else
      println(iob, MktName, " Market Emissions (Mt);;    ", join(Year[years], ";"))
    end
    for iter in iters
      for y in years
        ZZZ[y]=MPol[market,iter,y]/1e6
      end
      if ETRSw[market] == 1
        print(iob, "TBuy;Iter ",iter,";")
      else
        print(iob, "MPol;Iter ",iter,";")
      end

      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    if ETRSw[market] == 1
      println(iob, MktName, " Permits Sold (Mt);;    ", join(Year[years], ";"))
    else
      println(iob, MktName, " Emissions Goal (Mt);;    ", join(Year[years], ";"))
    end
    for iter in iters
      for y in years
        ZZZ[y]=GPol[market,iter,y]/1e6
      end
      if ETRSw[market] == 1
        print(iob, "TSell;Iter ",iter,";")
      else
        print(iob, "GPol;Iter ",iter,";")
      end

      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    if ETRSw[market] == 1
      println(iob, MktName, " Buy over Sell (Mt);;    ", join(Year[years], ";"))
    else
      println(iob, MktName, " Goal Overage (Mt);;    ", join(Year[years], ";"))
    end
    for iter in iters
      for y in years
        ZZZ[y]=Over[market,iter,y]/1e6
      end
      print(iob, "Over;Iter ",iter,";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%15.3f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")

    println(iob, MktName, " Overage Relative to Emissions Goal (Mt/Mt);;    ", join(Year[years], ";"))
    for iter in iters
      for y in years
        @finite_math ZZZ[y]=Over[market,iter,y]/GoalPol[market,y]
      end
      print(iob, "OverFrac;Iter ",iter,";")
      for zzz in ZZZ[years]
        print(iob, @sprintf("%12.4f;", zzz))
      end
      println(iob)
    end
    println(iob, " ")
  end

  filename = "Market_GHG-$market-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function Market_GHG_DtaControl(db)
  @info "Market_GHG_DtaControl"
  data = Market_GHGData(; db)
  BaseSw = data.BaseSw
  CapTrade = data.CapTrade

  # Market = data.Market

  # markets = [121,122,123,124,126,127,128,129,141,144,145,146,147,148,149,1]
  markets = [140,141,142,145,146,151,152]
  for market in markets
    CT = maximum(CapTrade[market,:])
    if (BaseSw == 0) && (CT == 5)
      MktName = "Market GHG $market"
      Market_GHG_DtaRun(data, market, MktName)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  Market_GHG_DtaControl(DB)
end
