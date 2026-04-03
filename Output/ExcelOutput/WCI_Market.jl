#
# WCI_Market.jl - Emission Market Variables
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
Base.@kwdef struct WCI_MarketData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Iter::SetArray = ReadDisk(db,"MainDB/IterKey")
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade,Cap Only=2)
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  DriverRef::VariableArray{3} = ReadDisk(RefNameDB,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db,"SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  EORCredits::VariableArray{4} = ReadDisk(db, "SOutput/EORCredits") # [ECC,Poll,Area,Year] Emissions Credits for using CO2 for EOR (Tonnes/Yr)
  ETABY::VariableArray{1} = ReadDisk(db,"SInput/ETABY") # [Market] Beginning Year for Emission Trading Allowances (Year)
  ETADA1P::VariableArray{2} = ReadDisk(db,"SInput/ETADA1P") # [Market,Year] Price Break 1 for Releasing Allowance Reserve ($/Tonne)
  ETADA2P::VariableArray{2} = ReadDisk(db,"SInput/ETADA2P") # [Market,Year] Price Break 2 for Releasing Allowance Reserve ($/Tonne)
  ETADA3P::VariableArray{2} = ReadDisk(db,"SInput/ETADA3P") # [Market,Year] Price Break 3 for Releasing Allowance Reserve ($/Tonne)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government (1985 US$/Tonne)
  ETAFAP::VariableArray{2} = ReadDisk(db,"SInput/ETAFAP") # [Market,Year] Cost of Foreign Allowances ($/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db,"SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  ETAMax::VariableArray{2} = ReadDisk(db,"SInput/ETAMax") # [Market,Year] Maximum Price for Allowances ($/Tonne)
  ETAMin::VariableArray{2} = ReadDisk(db,"SInput/ETAMin") # [Market,Year] Minimum Price for Allowances ($/Tonne)
  ETAPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ETAvPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAvPr") #[Market,Year]  Average Cost of Emission Trading Allowances (US$/Tonne)
  ETR::VariableArray{3} = ReadDisk(db, "SOutput/ETR") # [Market,Iter,Year] Permit Costs ($/Tonne)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate Credits,2=Iterate Emissions,0=Exogenous)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  FBuyFrArea::VariableArray{2} = ReadDisk(db,"SInput/FBuyFrArea") # [Area,Year] Fraction of Allowances Withdrawn or Bought (Tonnes/Tonnes)
  FBuy::VariableArray{2} = ReadDisk(db, "SOutput/FBuy") # [Market,Year] Federal (Domestic) Permits Bought (Tonnes/Year)
  FInventory::VariableArray{2} = ReadDisk(db, "SOutput/FInventory") # [Market,Year] Federal (Domestic) Permits Inventory (Tonnes)
  FInvRev::VariableArray{2} = ReadDisk(db,"SOutput/FInvRev") # [Market,Year] Federal (Domestic) Permits Inventory (M$)
  FSell::VariableArray{2} = ReadDisk(db, "SOutput/FSell") # [Market,Year] Indicated Federal Permits Sold (Tonnes/Year)
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather,2=Output,0=Exogenous)
  GoalPol::VariableArray{2} = ReadDisk(db, "SOutput/GoalPol") # [Market,Year] Pollution Goal (Tonnes/Year)
  GPol::VariableArray{3} = ReadDisk(db, "SOutput/GPol") # [Market,Iter,Year] Market Emissions Goal (Tonnes/Yr)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  ISell::VariableArray{2} = ReadDisk(db, "SOutput/ISell") # [Market,Year] International Permits Sold (Tonnes/Year)

  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # [Year] Maximum Number of Iterations (Number)
  MEReduce::VariableArray{4} = ReadDisk(db,"SOutput/MEReduce") # [ECC,Poll,Area,Year] Non Energy Reductions (Tonnes/Yr)
  MEReduceRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/MEReduce") # [ECC,Poll,Area,Year] Non Energy Reductions (Tonnes/Yr)
  MPol::VariableArray{3} = ReadDisk(db, "SOutput/MPol") # [Market,Iter,Year] Market Covered Emissions (Tonnes/Yr)

  OffGeneric::VariableArray{3} = ReadDisk(db, "SOutput/OffGeneric") # [Market,Poll,Year] Offsets Used (Tonnes)
  OffMktFr::VariableArray{4} = ReadDisk(db,"SInput/OffMktFr") # [ECC,Area,Market,Year] Fraction of Offsets allocated to each Market (Tonne/Tonne)
  # TODO: Sometimes, Offsets is also the collection of the set Offset
  Offsets::VariableArray{4} = ReadDisk(db, "SOutput/Offsets") #[ECC,Poll,Area,Year]  Offsets including Sequestering (Tonnes/Yr)
  OffsetsElec::VariableArray{4} = ReadDisk(db, "SOutput/OffsetsElec") # [ECC,Poll,Area,Year] Offsets from Electric Generation Units (Tonnes/Yr)
  OffTotal::VariableArray{2} = ReadDisk(db,"SOutput/OffTotal") #[Market,Year]  Total Offsets (eCO2 Tonnes)
  Over::VariableArray{3} = ReadDisk(db, "SOutput/Over") # [Market,Iter,Year] Market Emissions Overage (Tonnes/Yr)

  PBank::VariableArray{4} = ReadDisk(db, "SOutput/PBank") # [ECC,Poll,Area,Year] Permits Banked (Tonnes/Yr)
  PBuy::VariableArray{4} = ReadDisk(db, "SOutput/PBuy") # [ECC,Poll,Area,Year] Permits Bought (Tonnes/Year)
  PCovMarket::VariableArray{3} = ReadDisk(db, "SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PGratis::VariableArray{5} = ReadDisk(db, "SOutput/PGratis") # [ECC,Poll,PCov,Area,Year] Gratis Permits (Tonnes/Year)
  PInventory::VariableArray{4} = ReadDisk(db, "SOutput/PInventory") # [ECC,Poll,Area,Year] Permit Inventory (Tonnes)
  PNeed::VariableArray{4} = ReadDisk(db, "SOutput/PNeed") # [ECC,Poll,Area,Year] Permits Needed (Tonnes/Year)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PolCov::VariableArray{5} = ReadDisk(db, "SOutput/PolCov") # [ECC,Poll,PCov,Area,Year] Covered Pollution (Tonnes/Yr)
  PolCovRef::VariableArray{5} = ReadDisk(db,"SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PolImports::VariableArray{3} = ReadDisk(db, "SOutput/PolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  PolImportsRef::VariableArray{3} = ReadDisk(RefNameDB, "SOutput/PolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  PolTot::VariableArray{5} = ReadDisk(db, "SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Total Pollution (Tonnes/Yr)
  PolTotRef::VariableArray{5} = ReadDisk(RefNameDB, "SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Total Pollution (Tonnes/Yr)
  PollMarket::VariableArray{3} = ReadDisk(db, "SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  PRedeem::VariableArray{4} = ReadDisk(db, "SOutput/PRedeem") # [ECC,Poll,Area,Year] Permits Redeemed from Inventory (Tonnes/Yr)
  PSell::VariableArray{4} = ReadDisk(db, "SOutput/PSell") # [ECC,Poll,Area,Year] Permits Sold (Tonnes/Year)

  SqPGMult::VariableArray{4} = ReadDisk(db,"SInput/SqPGMult") # [ECC,Poll,Area,Year] Sequestering Gratis Permit Multiplier (Tonne/Tonne)
  SqPol::VariableArray{4} = ReadDisk(db, "SOutput/SqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)
  SqPolRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/SqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)
  TGratis::VariableArray{2} = ReadDisk(db, "SOutput/TGratis") # [Market,Year] Total Gratis Permits (Tonnes/Year)

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCoverage::VariableArray{3} = ReadDisk(db,"EGInput/UnCoverage") # [Unit,Poll,Year] Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPGratis::VariableArray{3} = ReadDisk(db,"EGOutput/UnPGratis") # [Unit,Poll,Year] Gratis Permits (Tonnes/Yr)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)

  xETAPr::VariableArray{2} = ReadDisk(db, "SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xFSell::VariableArray{2} = ReadDisk(db, "SInput/xFSell") # [Market,Year] Federal (Domestic) Permits Available (Tonnes/Year)
  xISell::VariableArray{2} = ReadDisk(db, "SInput/xISell") # [Market,Year] International Permits Available (Tonnes/Year)
  xPGratis::VariableArray{5} = ReadDisk(db,"SInput/xPGratis") # [ECC,Poll,PCov,Area,Year] Exogenous Gratis Permits (Tonnes/Yr)
  xPolCap::VariableArray{5} = ReadDisk(db,"SInput/xPolCap") # [ECC,Poll,PCov,Area,Year] Exogenous Emissions Cap (Tonnes/Yr)

  # Scratch Variables
  Agric::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Agriculture Offsets (Mt)
  Cap::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Emissions Cap (Mt)
  GrossRef::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reference Case Emissions (Mt)
  NetRef::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reference Case Emissions Net of Production Reductions (Mt)
  ECovMarket::VariableArray{5}=zeros(Float32,length(ECC),length(Poll),length(PCov),length(Area),length(Year)) # [ECC,Poll,PCov,Area,Year] Emissions Coverage for this Market (1=Covered)'
  Emissions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Emissions (Mt)
  EI::VariableArray{3}=zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] [ECC,Area,Year] Emissions Intensity (Tonnes/Driver)
  EIRef::VariableArray{3}=zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Reference Case Emissions Intensity (Tonnes/Driver)
  Forest::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Forestry Offsets (Mt)
  GenericOffsets::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Generic Offsets (Mt)
  IPermits::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] International Permits Bought (Mt)
  IPermitsTotal::VariableArray{1}=zeros(Float32,length(Year)) # [Year] International Permits Bought (Mt)
  InvChange::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Change in Permit Inventory (Mt)
  IR::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Internal Reductions (Mt)
  NetEmissions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Net Emissions (Mt)
  OffCogen::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Recognition of Cogeneration (Mt)
  OffElectric::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Electric Generation Offsets (Mt)
  OffOther::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Other Offsets (Mt)
  OffsetECC::VariableArray{3}=zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Offsets (Mt)
  OverFrac::VariableArray{2}=zeros(Float32,length(Iter),length(Year)) # [Iter,Year] Overage Fraction (Mt/Mt)
  Overage::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Overage (Mt)
  OverageCumulative::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Cumulative Overage (Mt)
  PAuction::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year]Permits Available for Auction (Tonnes/Year)'
  PGratisCogen::VariableArray{3}=zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Gratis Permits for Cogeneration (Tonnes)
  PPBuy::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Permits Purchased (Mt/Yr)
  ProductionReductions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Production Reductions (Mt)
  Reductions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reductions (Mt)
  Sequest::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Sequestering (Mt)
  SequestEOR::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Sequestering EOR Credit (Mt)
  SolidW::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Solid Waste Offsets (Mt)
  TFAvePrice::VariableArray{1}=zeros(Float32,length(Year)) # [Year] TF Average Price ($/Tonne)
  TIFBuy::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reserve Allowances (Mt)
  TIFInventory::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reserve Allowance Inventory (Mt)
  TIFSold::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reserve Allowances Sold (Mt)
  TIFSoldTotal::VariableArray{1}=zeros(Float32,length(Year)) # [Year] Reserve Allowances Sold (Mt)
  TotalOffsets::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Offsets (Mt)
  WaterW::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Wastewater Offsets (Mt)
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function WCIMGetUnitSets(data,unit)
  (; Area,ECC) = data
  (; UnArea,UnSector) = data

  #
  # This procedure selects the sets for a particular unit
  #
  
  if (UnArea[unit] !== "Null") && (UnSector[unit] !== "Null")
    # genco = Select(GenCo,UnGenCo[unit])
    # plant = Select(Plant,UnPlant[unit])
    # node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    return area,ecc
    # return genco,plant,node,area,ecc
  end
end


function WCI_Market_PostProcessing(data,market,areas)
  (; db) = data
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Nation,NationDS,Nations) = data
  (; Market,Markets,PCov,PCovDS,PCovs,Poll,PollDS,Polls,Unit,Units) = data
  (; Year,Years,Yrv) = data
  (; AreaMarket,BaseSw,CapTrade,CDTime,CDYear,Driver,DriverRef,ECCMarket) = data
  (; ECoverage,Enforce,EORCredits,ETABY,ETADA1P,ETADA2P,ETADA3P,ETADAP,ETAFAP,ETAIncr) = data
  (; ETAMax,ETAMin,ETAPr,ETAvPr,ETR,ETRSw,ExchangeRateNation,FBuyFrArea,FBuy) = data
  (; FInventory,FInvRev,FSell,GratSw,GoalPol,GPol,Inflation,InflationNation) = data
  (; ISell,MaxIter,MEReduce,MEReduceRef,MPol,OffGeneric,OffMktFr,Offsets,OffsetsElec) = data
  (; OffTotal,Over,Overage,PBank,PBuy,PCovMarket,PGratis,PInventory,PNeed,PolConv) = data
  (; PolCov,PolCovRef,PolImports,PolImportsRef,PolTot,PolTotRef,PollMarket) = data
  (; PRedeem,PSell,SqPGMult,SqPol,SqPolRef,TGratis,UnArea,UnCode,UnCogen) = data
  (; UnCoverage,UnGenCo,UnNode,UnPGratis,UnPlant,UnSector,xETAPr,xFSell) = data
  (; xISell,xPGratis,xPolCap) = data
  (; Agric,Cap,GrossRef,NetRef,ECovMarket,Emissions,EI,EIRef,Forest) = data
  (; GenericOffsets,IPermits,IPermitsTotal,InvChange,IR,NetEmissions) = data
  (; OffCogen,OffElectric,OffOther,OffsetECC,OverFrac,OverageCumulative) = data
  (; PAuction,PGratisCogen,PPBuy,ProductionReductions,Reductions,Sequest) = data
  (; SequestEOR,SolidW,TFAvePrice,TIFBuy,TIFInventory,TIFSold,TIFSoldTotal) = data
  (; TotalOffsets,WaterW,ZZZ) = data
  
  @info "WCI_Market_PostProcessing"  

  current::Int=Int(Enforce[market]-ITime+1)
  prior::Int=Int(current-1)
  
  #
  # Select Market Sets
  #
  eccs=findall(ECCMarket[ECCs,market,Yr(2020)] .== 1)
  polls=findall(PollMarket[Polls,market,Yr(2020)] .== 1)
  pcovs=findall(PCovMarket[PCovs,market,Yr(2020)] .== 1)
  areas=findall(AreaMarket[Areas,market,Yr(2020)] .== 1)

  #
  # Termporaily assign values for output purposes
  #
  @. ECovMarket=ECoverage
  years=collect(Yr(1990):prior)
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    ECovMarket[ecc,poll,pcov,area,year]=ECoverage[ecc,poll,pcov,area,Yr(2020)]
  end

  if BaseSw != 0
    #
    # Reference Case Covered Emissions
    #
    @. PollTotRef = PolTot
    #
    # Reference Case Economic Driver
    #
    @. DriverRef = Driver
    #
    # Reference Case Offsets, Sequestering, and Imports
    #
    @. MEReduceRef = MEReduce
    @. PolImportsRef = PolImports
    @. SqPolRef = SqPol
    #
    years=collect(Yr(1990):prior)
    for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
      PolCovRef[ecc,poll,pcov,area,year]=PolTotRef[ecc,poll,pcov,area,year]*ECovMarket[ecc,poll,pcov,area,year]*PolConv[poll]
    end
    ecc=Select(ECC,"UtilityGen")
    for year in years, area in areas, pcov in pcovs, poll in polls
      PolCovRef[ecc,poll,pcov,area,year]=(PolTotRef[ecc,poll,pcov,area,year]+PolImportsRef[ecc,poll,pcov,area,year])*ECovMarket[ecc,poll,pcov,area,year]*PolConv[poll]
    end
  end
  #
  # Select ECC* #TODOMaybe - Promula deselects ECC, no longer using ECCs in market, but continues to use Areas, Polls, PCovs from Market. LJD, 25.08.05
  #
  # Covered Emissions
  #
  for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
    # @finite_math PolCov[ecc,poll,pcov,area,year]=PolCov[ecc,poll,pcov,area,year]*(ECovMarket[ecc,poll,pcov,area,year]/ECovMarket[ecc,poll,pcov,area,year])
    # # PolCov=PolCov*(ECovMarket/ECovMarket)
    if ECovMarket[ecc,poll,pcov,area,year] == 0
      PolCov[ecc,poll,pcov,area,year]=0.0
    end
  end
  years=collect(Yr(1990):prior)
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
    # @finite_math PolCov[ecc,poll,pcov,area,year]=PolCovRef[ecc,poll,pcov,area,year]*(ECovMarket[ecc,poll,pcov,area,year]/ECovMarket[ecc,poll,pcov,area,year])
    # # PolCov=PolCovRef*(ECovMarket/ECovMarket)
    if ECovMarket[ecc,poll,pcov,area,year] == 0
      PolCov[ecc,poll,pcov,area,year]=0.0
    else
      PolCov[ecc,poll,pcov,area,year]=PolCovRef[ecc,poll,pcov,area,year]
    end
  end
  # TODOMaybe - Order seems odd to me. Shouldn't we reset PolCovRef to zero based on ECovMarket before using PolCovRef in equations? LJD, 25.08.05
  for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
    # @finite_math PolCovRef[ecc,poll,pcov,area,year]=PolCovRef[ecc,poll,pcov,area,year]*(ECovMarket[ecc,poll,pcov,area,year]/ECovMarket[ecc,poll,pcov,area,year])
    # # PolCovRef=PolCovRef*(ECovMarket/ECovMarket)
    if ECovMarket[ecc,poll,pcov,area,year] == 0
      PolCovRef[ecc,poll,pcov,area,year]=0.0
    end
  end

  #
  # Emission Intensity (Covered)
  #
  for year in Years, area in areas, ecc in ECCs
    @finite_math EI[ecc,area,year]   =sum(PolCov[ecc,poll,pcov,area,year] for pcov in pcovs, poll in polls)/1e6/Driver[ecc,area,year]
    @finite_math EIRef[ecc,area,year]=sum(PolCovRef[ecc,poll,pcov,area,year] for pcov in pcovs, poll in polls)/1e6/DriverRef[ecc,area,year]
  end

  #
  # Emissions
  #
  for year in Years, area in areas
    GrossRef[area,year]=sum(EIRef[ecc,area,year]*DriverRef[ecc,area,year] for ecc in ECCs)
    NetRef[area,year]=sum(EIRef[ecc,area,year]*Driver[ecc,area,year] for ecc in ECCs)
    Emissions[area,year]=sum(EI[ecc,area,year]*Driver[ecc,area,year] for ecc in ECCs)
    Cap[area,year]=sum(xPolCap[ecc,poll,pcov,area,year] for pcov in pcovs, poll in polls, ecc in ECCs)/1e6
  end

  # Offsets for Process Emission Reductions
  #
  for year in Years, area in areas, ecc in ECCs
    OffsetECC[ecc,area,year]=sum(MEReduce[ecc,poll,area,year]*
        PolConv[poll]*OffMktFr[ecc,area,market,year] for poll in polls)/1e6
  end

  area=Select(Area,"CA")
  for year in Years
    GenericOffsets[area,year]=sum(OffGeneric[market,poll,year]*PolConv[poll] for poll in polls)/1e6
  end

  areas=Select(Area,["CA","QC","ON"])
  for year in Years, area in areas
    TotalOffsets[area,year]=sum(Offsets[ecc,poll,area,year]/1e6*OffMktFr[ecc,area,market,year] for poll in polls, ecc in ECCs)+
        GenericOffsets[area,year]
  end

  #
  # Add back emissions used as Offsets
  #
  for year in years, area in areas
    Emissions[area,year]=Emissions[area,year]+sum(OffsetECC[ecc,area,year]*ECCMarket[ecc,market,year] for ecc in ECCs)
  end
  
  #
  # Offset Groupings
  #
  eccs=Select(ECC,["OnFarmFuelUse","CropProduction","AnimalProduction"])
  for year in Years, area in areas
    Agric[area,year]=sum(OffsetECC[ecc,area,year] for ecc in eccs)
  end
  eccs=Select(ECC,["Forestry"])
  for year in Years, area in areas
    Forest[area,year]=sum(OffsetECC[ecc,area,year] for ecc in eccs)
  end
  eccs=Select(ECC,["SolidWaste"])
  for year in Years, area in areas
    SolidW[area,year]=sum(OffsetECC[ecc,area,year] for ecc in eccs)
  end
  eccs=Select(ECC,["Wastewater"])
  for year in Years, area in areas
    WaterW[area,year]=sum(OffsetECC[ecc,area,year] for ecc in eccs)
  end

  ecc=Select(ECC,"UtilityGen")
  for year in Years, area in areas
    OffElectric[area,year]=sum(OffsetsElec[ecc,poll,area,year]*
        OffMktFr[ecc,area,market,year]*PolConv[poll] for poll in polls)/1e6
  end

  eccs=Select(ECC,!=("UtilityGen"))
  for year in Years, area in areas
    OffCogen[area,year]=sum(OffsetsElec[ecc,poll,area,year]*
        OffMktFr[ecc,area,market,year]*PolConv[poll] for poll in polls, ecc in eccs)/1e6
  end

  for year in Years, area in areas
    Sequest[area,year]=sum(0-SqPol[ecc,poll,area,year]*
        SqPGMult[ecc,poll,area,year]*PolConv[poll]*OffMktFr[ecc,area,market,year] for poll in polls, ecc in ECCs)/1e6
    SequestEOR[area,year]=sum(EORCredits[ecc,poll,area,year]*
        PolConv[poll]*OffMktFr[ecc,area,market,year] for poll in polls, ecc in ECCs)/1e6
  end

  @. OffOther=TotalOffsets-Agric-Forest-SolidW-WaterW-OffElectric-GenericOffsets-
                        OffCogen-Sequest-SequestEOR

  #
  # APCR Withdrawn, Sold, and Inventory
  #
  @. TIFInventory=0
  years=collect(First:Final)
  for year in years, area in areas
    TIFBuy[area,year]=sum(xPolCap[ecc,poll,pcov,area,year]*FBuyFrArea[area,year] for pcov in pcovs, poll in polls, ecc in ECCs)/1e6
    @finite_math TIFSold[area,year]=FSell[market,year]/1e6*TIFInventory[area,year-1]/sum(TIFInventory[a,year-1] for a in areas)
    TIFInventory[area,year]=TIFInventory[area,year-1]+TIFBuy[area,year]-TIFSold[area,year]
  end
  for year in years
    TIFSoldTotal[year]=sum(TIFSold[area,year] for area in areas)
  end

  for year in years, area in areas
    IPermits[area,year]=ISell[market,year]/1e6
  end
  for year in years
    IPermitsTotal[year]=sum(IPermits[area,year] for area in areas)
  end

  @. NetEmissions=Emissions-TotalOffsets-TIFSold-IPermits

  for year in Years, area in areas
    # TODOPromula - InvChange calculations possibly incorrect in Promula. LJD 25.08.09
    InvChange[area,year]=sum(PBank[ecc,poll,area,year]-
        PRedeem[ecc,poll,area,year] for poll in polls, ecc in ECCs)/1e6
  end

  @. TGratis=TGratis/1e6

  @. Overage=0
  years=collect(First:Final)
  for year in years, area in areas
    if (Yrv[year] >= Enforce[market]) && (NetEmissions[area,year] > 0.0)
      Overage[area,year]=NetEmissions[area,year]+TIFBuy[area,year]+InvChange[area,year]-Cap[area,year]
      OverageCumulative[area,year]=OverageCumulative[area,year-1]+Overage[area,year]
    end
  end

  @. ProductionReductions=GrossRef-NetRef
  @. IR=NetRef-Emissions
  @. Reductions=ProductionReductions+IR+TotalOffsets+TIFSold+IPermits

  for year in Years, area in areas
    PAuction[area,year]=max(sum(xPolCap[ecc,poll,pcov,area,year] for  pcov in pcovs, poll in polls, ecc in ECCs)-
                          sum(xPGratis[ecc,poll,pcov,area,year] for  pcov in pcovs, poll in polls, ecc in ECCs),0)/1e6
    PPBuy[area,year]=sum(PBuy[ecc,poll,area,year] for poll in polls, ecc in ECCs)/1e6
  end


  #
  # Cogeneration Allocated Allowances
  #
  co2=Select(Poll,"CO2")
  @. PGratisCogen=0
  for unit in Units
    # area,ecc = WCIMGetUnitSets(data,unit)
    if (UnArea[unit] !== "Null") && (UnSector[unit] !== "Null")
      area = Select(Area,UnArea[unit])
      ecc = Select(ECC,UnSector[unit])
      for year in Years
        if (UnCoverage[unit,co2,year] == 1) && (UnCogen[unit] > 0) &&
            (AreaMarket[area,market,year] == 1) && (ECCMarket[ecc,market,year] == 1)
          PGratisCogen[ecc,area,year]=PGratisCogen[ecc,area,year]+sum(UnPGratis[unit,poll,year] for poll in polls)
        end
      end
    end
  end

end

function WCI_Market_DtaRun(data,market,areas,AreaKey,AreaName,MarketName)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Iter,Nation,NationDS,Nations) = data
  (; Market,Markets,PCov,PCovDS,PCovs,Poll,PollDS,Polls,Unit,Units) = data
  (; Year,Years,Yrv,SceName) = data
  (; AreaMarket,BaseSw,CapTrade,CDTime,CDYear,Driver,DriverRef,ECCMarket) = data
  (; ECoverage,Enforce,EORCredits,ETABY,ETADA1P,ETADA2P,ETADA3P,ETADAP,ETAFAP,ETAIncr) = data
  (; ETAMax,ETAMin,ETAPr,ETAvPr,ETR,ETRSw,ExchangeRateNation,FBuyFrArea,FBuy) = data
  (; FInventory,FInvRev,FSell,GratSw,GoalPol,GPol,Inflation,InflationNation) = data
  (; ISell,MaxIter,MEReduce,MEReduceRef,MPol,OffGeneric,OffMktFr,Offsets,OffsetsElec) = data
  (; OffTotal,Over,Overage,PBank,PBuy,PCovMarket,PGratis,PInventory,PNeed,PolConv) = data
  (; PolCov,PolCovRef,PolImports,PolImportsRef,PolTot,PolTotRef,PollMarket) = data
  (; PRedeem,PSell,SqPGMult,SqPol,SqPolRef,TGratis,UnArea,UnCode,UnCogen) = data
  (; UnCoverage,UnGenCo,UnNode,UnPGratis,UnPlant,UnSector,xETAPr,xFSell) = data
  (; xISell,xPGratis,xPolCap) = data
  (; Agric,Cap,GrossRef,NetRef,ECovMarket,Emissions,EI,EIRef,Forest) = data
  (; GenericOffsets,IPermits,IPermitsTotal,InvChange,IR,NetEmissions) = data
  (; OffCogen,OffElectric,OffOther,OffsetECC,OverFrac,OverageCumulative) = data
  (; PAuction,PGratisCogen,PPBuy,ProductionReductions,Reductions,Sequest) = data
  (; SequestEOR,SolidW,TFAvePrice,TIFBuy,TIFInventory,TIFSold,TIFSoldTotal) = data
  (; TotalOffsets,WaterW,ZZZ) = data
  
  @info "WCI_Market_DtaRun"

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the WCI Market Output File.")
  println(iob, " ")

  CN=Select(Nation,"CN")
  US=Select(Nation,"US")

  # eccs=findall(ECCMarket[ECCs,market,Yr(2020)] .== 1)
  polls=findall(PollMarket[Polls,market,Yr(2020)] .== 1)
  pcovs=findall(PCovMarket[PCovs,market,Yr(2020)] .== 1)

  years=union(Yr(1990),Yr(2000),Yr(2005),collect(Yr(2010):Final))

  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  #
  println(iob, "$AreaName Emissions Summary (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, " ;Reference Case Emissions")
  for year in years  
    ZZZ[year] = sum(GrossRef[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Production Reductions")
  for year in years  
    ZZZ[year] = sum(ProductionReductions[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Reference Case Emissions Net of Production Reductions")
  for year in years  
    ZZZ[year] = sum(NetRef[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Internal Reductions")
  for year in years  
    ZZZ[year] = sum(IR[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Covered Emissions")
  for year in years  
    ZZZ[year] = sum(Emissions[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Reference Case Sequestering")
  for year in years  
    ZZZ[year] = sum(0-SqPolRef[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls, ecc in ECCs) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Policy Sequestering")
  for year in years  
    ZZZ[year] = sum(0-SqPol[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls, ecc in ECCs) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Sequestering Credits")
  for year in years  
    ZZZ[year] = sum(Sequest[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Sequestering EOR Credits")
  for year in years  
    ZZZ[year] = sum(SequestEOR[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Agriculture Offsets")
  for year in years  
    ZZZ[year] = sum(Agric[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Forestry Offsets")
  for year in years  
    ZZZ[year] = sum(Forest[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Solid Waste Offsets")
  for year in years  
    ZZZ[year] = sum(SolidW[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Wastewater Offsets")
  for year in years  
    ZZZ[year] = sum(WaterW[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Electric Generation Offsets")
  for year in years  
    ZZZ[year] = sum(OffElectric[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Generic Offsets")
  for year in years  
    ZZZ[year] = sum(GenericOffsets[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Other Offsets")
  for year in years  
    ZZZ[year] = sum(OffOther[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Recognition of Cogeneration")
  for year in years  
    ZZZ[year] = sum(OffCogen[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;International Allowances")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Reductions")
  for year in years  
    ZZZ[year] = sum(Reductions[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Net Emissions")
  for year in years  
    ZZZ[year] = sum(NetEmissions[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Emissions Cap")
  for year in years  
    ZZZ[year] = sum(Cap[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Additions")
  for year in years  
    ZZZ[year] = sum(TIFBuy[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Allocated Allowance")
  for year in years  
    ZZZ[year] = TGratis[market,year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Inventory Change")
  for year in years  
    ZZZ[year] = sum(InvChange[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Overage")
  for year in years  
    ZZZ[year] = sum(Overage[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$MarketName Cost of Trading Allowances ($CDTime CN\$/Tonne);;    ", join(Year[years], ";"))
  print(iob, " ;Marginal")
  for year in years  
    ZZZ[year]=ETAPr[market,year]*ExchangeRateNation[CN,year]/InflationNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Average")
  for year in years  
    # @finite_math TFAvePrice[year]=(ETADAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]*TIFSoldTotal[year]+
    #     ETAFAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]*IPermitsTotal[year]+
    #     ETAPr[market,year]*ExchangeRateNation[CN,year]/InflationNation[CN,year]*InflationNation[CN,CDYear]*
    #     (PPBuy[area,year]-TIFSoldTotal[year]-IPermitsTotal[year]))/PPBuy[area,year]
    # ZZZ[year]=TFAvePrice[year]
    @finite_math ZZZ[year]=(ETADAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]*TIFSoldTotal[year]+
        ETAFAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]*IPermitsTotal[year]+
        ETAPr[market,year]*ExchangeRateNation[CN,year]/InflationNation[CN,year]*InflationNation[CN,CDYear]*
        (sum(PPBuy[area,year] for area in areas)-TIFSoldTotal[year]-IPermitsTotal[year]))/sum(PPBuy[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)

  print(iob, " ;Minimum")
  for year in years  
    ZZZ[year]=ETAMin[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Price before Iterations")
  for year in years  
    ZZZ[year]=xETAPr[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Price Break 1")
  for year in years  
    ZZZ[year]=ETADA1P[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Price Break 2")
  for year in years  
    ZZZ[year]=ETADA2P[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Price Break 3")
  for year in years  
    ZZZ[year]=ETADA3P[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Sales Price")
  for year in years  
    ZZZ[year]=ETADAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;International")
  for year in years  
    ZZZ[year]=ETAFAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$MarketName Cost of Trading Allowances ($CDTime US\$/Tonne);;    ", join(Year[years], ";"))
  print(iob, " ;Marginal")
  for year in years  
    ZZZ[year]=ETAPr[market,year]/InflationNation[US,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Average")
  for year in years  
    @finite_math TFAvePrice[year]=(ETADAP[market,year]*InflationNation[US,CDYear]*TIFSoldTotal[year]+
        ETAFAP[market,year]*InflationNation[US,CDYear]*IPermitsTotal[year]+
        ETAPr[market,year]/InflationNation[US,year]*InflationNation[US,CDYear]*
        (sum(PPBuy[area,year] for area in areas)-TIFSoldTotal[year]-IPermitsTotal[year]))/sum(PPBuy[area,year] for area in areas)
    ZZZ[year]=TFAvePrice[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Minimum")
  for year in years  
    ZZZ[year]=ETAMin[market,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Price before Iterations")
  for year in years  
    ZZZ[year]=xETAPr[market,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Price Break 1")
  for year in years  
    ZZZ[year]=ETADA1P[market,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Price Break 2")
  for year in years  
    ZZZ[year]=ETADA2P[market,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Price Break 3")
  for year in years  
    ZZZ[year]=ETADA3P[market,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Sales Price")
  for year in years  
    ZZZ[year]=ETADAP[market,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;International")
  for year in years  
    ZZZ[year]=ETAFAP[market,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName Allowance Price Containment Reserve (APCR)(MT);;    ", join(Year[years], ";"))
  print(iob, " ;APCR Additions")
  for year in years  
    ZZZ[year] = sum(TIFBuy[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;APCR Balance")
  for year in years  
    ZZZ[year] = sum(TIFInventory[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName Allowance Reserve Revenue ($CDTime CN M\$);;    ", join(Year[years], ";"))
  print(iob, " ;Revenue from Allowances Sold")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year]*ETADAP[market,year]*InflationNation[CN,CDYear] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName Trading Activity Summary (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, " ;Sold")
  for year in years  
    ZZZ[year] = sum(PSell[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Bought")
  for year in years  
    ZZZ[year] = sum(PBuy[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Banked to Inventory")
  for year in years  
    ZZZ[year] = sum(PBank[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Sold From Inventory")
  for year in years  
    ZZZ[year] = sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, " ;Inventory")
  for year in years  
    ZZZ[year] = sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Reference Case Covered Emissions
  #
  println(iob, "$AreaName Reference Case Covered Emissions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PolCovRef;Total")
  for year in years  
    ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PolCovRef;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Reference Case Covered Emissions with Production Reductions
  #
  println(iob, "$AreaName Reference Case Covered Emissions with Production Reductions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PolCovRefPR;Total")
  for year in years  
    ZZZ[year] = sum(EIRef[ecc,area,year]*Driver[ecc,area,year] for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PolCovRefPR;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(EIRef[ecc,area,year]*Driver[ecc,area,year] for area in areas) 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Policy Covered Emissions
  #
  println(iob, "$AreaName Covered Emissions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PolCov;Total")
  for year in years  
    ZZZ[year] = sum(PolCov[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PolCov;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PolCov[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Emissions Cap
  #
  # xPolCap=xPolCap*(ECovMarket/ECovMarket)
  #
  # for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
  #   if ECovMarket[ecc,poll,pcov,area,year] == 0
  #     xPolCap[ecc,poll,pcov,area,year]=0.0
  #   end
  # end
  #
  println(iob, "$AreaName Emissions Cap (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "xPolCap;Total")
  for year in years  
    ZZZ[year] = sum(xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "xPolCap;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Allocated Allowances (Gratis Permits)
  #
  # PGratis=PGratis*(ECovMarket/ECovMarket)
  #
  # for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
  #   if ECovMarket[ecc,poll,pcov,area,year] == 0
  #     PGratis[ecc,poll,pcov,area,year]=0.0
  #   end
  # end
  #
  println(iob, "$AreaName Allocated Allowances (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PGratis;Total")
  for year in years  
    ZZZ[year] = sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PGratis;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Internal Reductions
  #
  println(iob, "$AreaName Internal Reductions (Tonnes);;    ", join(Year[years], ";"))
  print(iob, "IR;Total")
  for year in years  
    ZZZ[year] = sum((EIRef[ecc,area,year]-EI[ecc,area,year])*Driver[ecc,area,year] for area in areas, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "IR;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum((EIRef[ecc,area,year]-EI[ecc,area,year])*Driver[ecc,area,year] for area in areas)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Required Reductions
  #
  println(iob, "$AreaName Required Reductions (Tonnes);;    ", join(Year[years], ";"))
  print(iob, "RR;Total")
  for year in years  
    ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] - xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "RR;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] - xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Required Reduction Fraction
  #
  println(iob, "$AreaName Required Reduction Fraction (Tonne/Tonne);;    ", join(Year[years], ";"))
  print(iob, "RR Fraction;Average")
  for year in years  
    @finite_math ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] - xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/
        sum(PolCovRef[e,p,pc,a,year] for a in areas, pc in PCovs, p in Polls, e in ECCs) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "RR Fraction;$(ECCDS[ecc])")
    for year in years  
      @finite_math ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] - xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/
          sum(PolCovRef[ecc,p,pc,a,year] for a in areas, pc in PCovs, p in Polls) 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Reference Case Driver
  #
  println(iob, "$AreaName Reference Case Driver (Various Units/Year);;    ", join(Year[years], ";"))
  for ecc in ECCs
    print(iob, "DriverRef;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(DriverRef[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Driver
  #
  println(iob, "$AreaName Driver (Various Units/Year);;    ", join(Year[years], ";"))
  for ecc in ECCs
    print(iob, "Driver;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(Driver[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Reference Case Emissions Intensity
  #
  println(iob, "$AreaName Reference Case Emissions Intensity (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
  for ecc in ECCs
    print(iob, "EIRef;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(EIRef[ecc,area,year] for area in areas)*1000
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Emissions Intensity
  #
  println(iob, "$AreaName Emissions Intensity (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
  for ecc in ECCs
    print(iob, "EI;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(EI[ecc,area,year] for area in areas)*1000
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Emission Intensity adjusted for with Permits Purchased
  #
  #  PBuy=PBuy*(ECovMarket/ECovMarket)
  #
  # for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
  #   if ECovMarket[ecc,poll,pcov,area,year] == 0
  #     xPolCap[ecc,poll,pcov,area,year]=0.0
  #   end
  # end
  println(iob, "$AreaName Emissions Intensity with Permits (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
  for ecc in ECCs
    print(iob, "EI w/Permits;$(ECCDS[ecc])")
    for year in years  
    @finite_math ZZZ[year] = sum((PolCov[ecc,poll,pcov,area,year]-
        PBuy[ecc,poll,area,year]) for area in areas, pcov in pcovs, poll in polls)/1e6/
        sum(Driver[ecc,area,year] for area in areas)*1000
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Required Reduction Fraction
  #
  println(iob, "$AreaName Sequestering (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "SqPol;Total")
  for year in years  
    @finite_math ZZZ[year] = sum(0 - SqPol[ecc,poll,area,year]*
        OffMktFr[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "SqPol;$(ECCDS[ecc])")
    for year in years  
      @finite_math ZZZ[year] = sum(0 - SqPol[ecc,poll,area,year]*
          OffMktFr[ecc,poll,area,year] for area in areas, poll in polls)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$AreaName Cogeneration Credits (Mt/Yr);;    ", join(Year[years], ";"))
  print(iob, "UnPGratis;Total")
  for year in years  
    ZZZ[year] = sum(PGratisCogen[ecc,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "UnPGratis;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PGratisCogen[ecc,area,year] for area in areas, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  #  PSell=PSell*(ECovMarket/ECovMarket)
  #
  # for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
  #   if ECovMarket[ecc,poll,pcov,area,year] == 0
  #     PSell[ecc,poll,area,year]=0.0
  #   end
  # end
  println(iob, "$AreaName Permits Sold (Mt/Yr);;    ", join(Year[years], ";"))
  print(iob, "PSell;Total")
  for year in years  
    ZZZ[year] = sum(PSell[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PSell;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PSell[ecc,poll,area,year] for area in areas, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  #  PBuy=PBuy*(ECovMarket/ECovMarket)
  #
  # for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
  #   if ECovMarket[ecc,poll,pcov,area,year] == 0
  #     PBuy[ecc,poll,area,year]=0.0
  #   end
  # end
  println(iob, "$AreaName Permits Bought (Mt/Yr);;    ", join(Year[years], ";"))
  print(iob, "PBuy;Total")
  for year in years  
    ZZZ[year] = sum(PBuy[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PBuy;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PBuy[ecc,poll,area,year] for area in areas, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  #  PBank=PBank*(ECovMarket/ECovMarket)
  #
  # for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
  #   if ECovMarket[ecc,poll,pcov,area,year] == 0
  #     PBank[ecc,poll,area,year]=0.0
  #   end
  # end
  println(iob, "$AreaName Permits Banked to Inventory (Mt/Yr);;    ", join(Year[years], ";"))
  print(iob, "PBank;Total")
  for year in years  
    ZZZ[year] = sum(PBank[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PBank;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PBank[ecc,poll,area,year] for area in areas, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$AreaName Permits Sold from Inventory (Mt/Yr);;    ", join(Year[years], ";"))
  print(iob, "PRedeem;Total")
  for year in years  
    ZZZ[year] = sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PRedeem;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$AreaName Inventory Permits (Mt/Yr);;    ", join(Year[years], ";"))
  print(iob, "PInventory;Total")
  for year in years  
    ZZZ[year] = sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PInventory;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$AreaName Permits Needed (Mt/Yr);;    ", join(Year[years], ";"))
  print(iob, "PNeed;Total")
  for year in years  
    ZZZ[year] = sum(PNeed[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    print(iob, "PNeed;$(ECCDS[ecc])")
    for year in years  
      ZZZ[year] = sum(PNeed[ecc,poll,area,year] for area in areas, poll in polls)/1e6 
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$MarketName Cap Trade Switch;;    ", join(Year[years], ";"))
  print(iob, "CapTrade;$MarketName")
  for year in years  
    ZZZ[year] = CapTrade[market,year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$MarketName External Permit Price (\$/\$);;    ", join(Year[years], ";"))
  print(iob, "ETAIncr;$MarketName")
  for year in years  
    ZZZ[year] = ETAIncr[market,year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$MarketName Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous);$MarketName;")
  println(iob, "GratSw;",@sprintf("%15.0f",GratSw[market]))
  println(iob)

  #
  println(iob, "$MarketName Beginning Year for Emission Trading Allowances (Year);;")
  println(iob, "ETABY;",@sprintf("%15.0f",ETABY[market]))
  println(iob)

  current::Int=Int(Enforce[market]-ITime+1)
  loc1::Int=Int(MaxIter[current])
  iters=collect(1:loc1)

  println(iob, "$MarketName Emission Price ($CDTime CN\$/tonne);;    ", join(Year[years], ";"))
  for iter in iters
    print(iob, "ETR;$iter")
    for year in years  
      ZZZ[year] = ETR[market,iter,year]*ExchangeRateNation[CN,year]/InflationNation[CN,year]*InflationNation[CN,CDYear]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  if ETRSw[market] == 1
    println(iob, "$MarketName Permits Bought (Mt);;    ", join(Year[years], ";"))
  else
    println(iob, "$MarketName Market Emissions (Mt);;    ", join(Year[years], ";"))
  end
  for iter in iters
    if ETRSw[market] == 1
      print(iob, "TBuy;$iter")
    else
      print(iob, "MPol;$iter")
    end
    for year in years  
      ZZZ[year] = MPol[market,iter,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  if ETRSw[market] == 1
    println(iob, "$MarketName Permits Sold (Mt);;    ", join(Year[years], ";"))
  else
    println(iob, "$MarketName Emissions Goal (Mt);;    ", join(Year[years], ";"))
  end
  for iter in iters
    if ETRSw[market] == 1
      print(iob, "TSell;$iter")
    else
      print(iob, "GPol;$iter")
    end
    for year in years  
      ZZZ[year] = GPol[market,iter,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  if ETRSw[market] == 1
    println(iob, "$MarketName Buy over Sell (Mt);;    ", join(Year[years], ";"))
  else
    println(iob, "$MarketName Goal Overage (Mt);;    ", join(Year[years], ";"))
  end
  for iter in iters
    print(iob, "Over;$iter")
    for year in years  
      ZZZ[year] = Over[market,iter,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$MarketName Overage Relative to Emissions Goal (Mt/Mt);;    ", join(Year[years], ";"))
  for iter in iters
    print(iob, "OverFrac;$iter")
    for year in years  
      @finite_math ZZZ[year] = Over[market,iter,year]/GoalPol[market,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "WCI_Market-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function WCI_Market_DtaControl(db)
  @info "WCI_Market_DtaControl"
  data = WCI_MarketData(; db)
  (; Area,AreaDS,Areas,Market,Years) = data
  (; AreaMarket,BaseSw) = data

  #
  # This output file is not meaningful for the Base
  #
  @info "WCI_Market_DtaControl 2"
  market=200
  if BaseSw == 0
    @info "WCI_Market_DtaControl 3"
    areas=findall(AreaMarket[Areas,market,Yr(2030)] .== 1)
    if !isempty(areas)
      @info "WCI_Market_DtaControl 4"
      WCI_Market_PostProcessing(data,market,areas)
      for area in areas
        @info "WCI_Market_DtaControl 5"
        WCI_Market_DtaRun(data,market,area,Area[area],AreaDS[area],"")
      end
      @info "WCI_Market_DtaControl 6"      
      WCI_Market_DtaRun(data,market,areas,"WCI","WCI","WCI")
    else
      @info "WCI_Market Areas are empty"
    end
  else 
    @info "WCI_Market BaseSw = $BaseSw "
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  WCI_Market_DtaControl(DB)
end
