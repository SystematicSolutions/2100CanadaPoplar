#
# WCI_Summary.jl - Emission Market Variables
#

import ...EnergyModel: @finite_math,finite_divide,ITime

Base.@kwdef struct WCI_SummaryData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")


  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade,Cap Only=2)
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  DriverRef::VariableArray{3} = ReadDisk(RefNameDB,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db,"SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  EORCredits::VariableArray{4} = ReadDisk(db, "SOutput/EORCredits") # [ECC,Poll,Area,Year] Emissions Credits for using CO2 for EOR (Tonnes/Yr)
  ETAPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)

  FBuyFrArea::VariableArray{2} = ReadDisk(db,"SInput/FBuyFrArea") # [Area,Year] Fraction of Allowances Withdrawn or Bought (Tonnes/Tonnes)
  FInventory::VariableArray{2} = ReadDisk(db, "SOutput/FInventory") # [Market,Year] Federal (Domestic) Permits Inventory (Tonnes)
  FSell::VariableArray{2} = ReadDisk(db, "SOutput/FSell") # [Market,Year] Indicated Federal Permits Sold (Tonnes/Year)

  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)

  MEReduce::VariableArray{4} = ReadDisk(db,"SOutput/MEReduce") # [ECC,Poll,Area,Year] Non Energy Reductions (Tonnes/Yr)
  MEReduceRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/MEReduce") # [ECC,Poll,Area,Year] Non Energy Reductions (Tonnes/Yr)

  OffGeneric::VariableArray{3} = ReadDisk(db, "SOutput/OffGeneric") # [Market,Poll,Year] Offsets Used (Tonnes)
  OffMktFr::VariableArray{4} = ReadDisk(db,"SInput/OffMktFr") # [ECC,Area,Market,Year] Fraction of Offsets allocated to each Market (Tonne/Tonne)
  # TODO: Sometimes, Offsets is also the collection of the set Offset
  Offsets::VariableArray{4} = ReadDisk(db, "SOutput/Offsets") #[ECC,Poll,Area,Year]  Offsets including Sequestering (Tonnes/Yr)
  OffsetsElec::VariableArray{4} = ReadDisk(db, "SOutput/OffsetsElec") # [ECC,Poll,Area,Year] Offsets from Electric Generation Units (Tonnes/Yr)
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
  TotPol::VariableArray{4} = ReadDisk(db,"SOutput/TotPol") #[ECC,Poll,Area,Year]  Pollution (Tonnes/Yr)
  TotPolRef::VariableArray{4} = ReadDisk(RefNameDB,"SOutput/TotPol") #[ECC,Poll,Area,Year]  Pollution in Reference Case (Tonnes/Yr)

  xPGratis::VariableArray{5} = ReadDisk(db,"SInput/xPGratis") # [ECC,Poll,PCov,Area,Year] Exogenous Gratis Permits (Tonnes/Yr)
  xPolCap::VariableArray{5} = ReadDisk(db,"SInput/xPolCap") # [ECC,Poll,PCov,Area,Year] Exogenous Emissions Cap (Tonnes/Yr)

  # Scratch Variables
  Agric::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Agriculture Offsets (Mt)
  GrossRef::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reference Case Emissions (Mt)
  NetRef::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reference Case Emissions Net of Production Reductions (Mt)
  ECovMarket::VariableArray{5}=zeros(Float32,length(ECC),length(Poll),length(PCov),length(Area),length(Year)) # [ECC,Poll,PCov,Area,Year] Emissions Coverage for this Market (1=Covered)'
  Emissions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Emissions (Mt)
  EI::VariableArray{3}=zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] [ECC,Area,Year] Emissions Intensity (Tonnes/Driver)
  EIRef::VariableArray{3}=zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Reference Case Emissions Intensity (Tonnes/Driver)
  Forest::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Forestry Offsets (Mt)
  GenericOffsets::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Generic Offsets (Mt)
  IPermits::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] International Permits Bought (Mt)
  InvChange::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Change in Permit Inventory (Mt)
  IR::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Internal Reductions (Mt)
  NetEmissions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Net Emissions (Mt)
  OffCogen::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Recognition of Cogeneration (Mt)
  OffElectric::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Electric Generation Offsets (Mt)
  OffOther::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Other Offsets (Mt)
  OffsetECC::VariableArray{3}=zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Offsets (Mt)
  Overage::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Overage (Mt)
  OverageCumulative::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Cumulative Overage (Mt)
  PAuction::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year]Permits Available for Auction (Tonnes/Year)'
  PPBuy::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Permits Purchased (Mt/Yr)
  ProductionReductions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Production Reductions (Mt)
  Reductions::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reductions (Mt)
  Sequest::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Sequestering (Mt)
  SequestEOR::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Sequestering EOR Credit (Mt)
  SolidW::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Solid Waste Offsets (Mt)
  Target::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Emissions Target (Mt)
  TIFBuy::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reserve Allowances (Mt)
  TIFInventory::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reserve Allowance Inventory (Mt)
  TIFSold::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Reserve Allowances Sold (Mt)
  TotalOffsets::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Offsets (Mt)
  WaterW::VariableArray{2}=zeros(Float32,length(Area),length(Year)) # [Area,Year] Wastewater Offsets (Mt)
  BBB::VariableArray = zeros(Float32,length(Year))
  SSS::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function WCI_Summary_MarketCalculations(data,market)
  (; db) = data
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Nation,NationDS,Nations) = data
  (; Market,Markets,PCov,PCovDS,PCovs,Poll,PollDS,Polls,Year,Years,Yrv) = data
  (; AreaMarket,BaseSw,CapTrade,CDTime,CDYear,Driver,DriverRef,ECCMarket,ECoverage) = data
  (; Enforce,EORCredits,ETAPr,ExchangeRateNation,FBuyFrArea,FInventory) = data
  (; FSell,InflationNation,MEReduce,MEReduceRef,OffGeneric,OffMktFr,Offsets) = data
  (; OffsetsElec,Overage,PBank,PBuy,PCovMarket,PGratis,PInventory,PNeed) = data
  (; PolConv,PolCov,PolCovRef,PolImports,PolImportsRef,PolTot,PolTotRef) = data
  (; PollMarket,PRedeem,PSell,SqPGMult,SqPol,SqPolRef,TotPol,TotPolRef,xPGratis,xPolCap) = data
  (; Agric,GrossRef,NetRef,ECovMarket,Emissions,EI,EIRef,Forest,GenericOffsets) = data
  (; IPermits,InvChange,IR,NetEmissions,OffCogen,OffElectric,OffOther,OffsetECC) = data
  (; OverageCumulative,PAuction,PPBuy,ProductionReductions,Reductions,Sequest) = data
  (; SequestEOR,SolidW,Target,TIFBuy,TIFInventory,TIFSold,TotalOffsets,WaterW,BBB,SSS,ZZZ) = data

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
    @. PolTotRef = PolTot
    @. TotPolRef = TotPol
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
    Target[area,year]=sum(xPolCap[ecc,poll,pcov,area,year] for pcov in pcovs, poll in polls, ecc in ECCs)/1e6
  end

  #
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
  # Add back emissions used as Offsets (is this needed? JSA 3/15/16)
  #
  # for year in years, area in areas
  #   Emissions[area,year]=Emissions[area,year]+sum(OffsetECC[ecc,area,year]*ECCMarket[ecc,market] for ecc in ECCs)
  # end

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

  @. IPermits=0
  @. NetEmissions=Emissions-TotalOffsets-TIFSold-IPermits

  for year in Years, area in areas
    InvChange[area,year]=sum(PBank[ecc,poll,area,year]-
        PRedeem[ecc,poll,area,year] for poll in polls, ecc in ECCs)/1e6
  end

  @. Overage=0
  for year in Years, area in areas
    if (Yrv[year] >= Enforce[market]) && (NetEmissions[area,year] > 0.0)
      Overage[area,year]=NetEmissions[area,year]+TIFBuy[area,year]+InvChange[area,year]-Target[area,year]
      OverageCumulative[area,year]=OverageCumulative[area,year-1]+Overage[area,year]
    end
  end

  @. ProductionReductions=GrossRef-NetRef
  @. IR=NetRef-Emissions
  @. Reductions=ProductionReductions+IR+TotalOffsets+TIFSold+IPermits

  for year in Years, area in areas
    PPBuy[area,year]=sum(PBuy[ecc,poll,area,year] for poll in polls, ecc in ECCs)/1e6
    PAuction[area,year]=max(sum(xPolCap[ecc,poll,pcov,area,year] for  pcov in pcovs, poll in polls, ecc in ECCs)-
                          sum(xPGratis[ecc,poll,pcov,area,year] for  pcov in pcovs, poll in polls, ecc in ECCs),0)
  end

end

function WCI_Summary_DtaRun(data,market,SceName)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Nation,NationDS,Nations) = data
  (; Market,Markets,PCov,PCovDS,PCovs,Poll,PollDS,Polls,Year,Years,Yrv) = data
  (; AreaMarket,BaseSw,CapTrade,CDTime,CDYear,Driver,DriverRef,ECCMarket,ECoverage) = data
  (; Enforce,EORCredits,ETAPr,ExchangeRateNation,FBuyFrArea,FInventory) = data
  (; FSell,InflationNation,MEReduce,MEReduceRef,OffGeneric,OffMktFr,Offsets) = data
  (; OffsetsElec,Overage,PBank,PBuy,PCovMarket,PGratis,PInventory,PNeed) = data
  (; PolConv,PolCov,PolCovRef,PolImports,PolImportsRef,PolTot,PolTotRef) = data
  (; PollMarket,PRedeem,PSell,SqPGMult,SqPol,SqPolRef,TotPol,TotPolRef,xPGratis,xPolCap) = data
  (; Agric,GrossRef,NetRef,ECovMarket,Emissions,EI,EIRef,Forest,GenericOffsets) = data
  (; IPermits,InvChange,IR,NetEmissions,OffCogen,OffElectric,OffOther,OffsetECC) = data
  (; OverageCumulative,PAuction,PPBuy,ProductionReductions,Reductions,Sequest) = data
  (; SequestEOR,SolidW,Target,TIFBuy,TIFInventory,TIFSold,TotalOffsets,WaterW,BBB,SSS,ZZZ) = data

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the WCI Cap-and-Trade Market Summary.")
  println(iob, " ")

  areas=Select(Area,["CA","QC","ON"])
  polls=findall(PollMarket[Polls,market,Yr(2020)] .== 1)
  pcovs=findall(PCovMarket[PCovs,market,Yr(2020)] .== 1)

  years=union(Yr(1990),Yr(2000),Yr(2005),collect(Yr(2010):Final))
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  # MktName="WCI Summary"

  println(iob, "Market Cumulative Overage (MT);;    ", join(Year[years], ";"))
  print(iob, "OverageCumulative;Total")
  for year in years  
    ZZZ[year] = sum(OverageCumulative[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "OverageCumulative;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = OverageCumulative[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Market Overage (MT);;    ", join(Year[years], ";"))
  print(iob, "Overage;Total")
  for year in years  
    ZZZ[year] = sum(Overage[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "Overage;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = Overage[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  CN=Select(Nation,"CN")
  US=Select(Nation,"US")
  println(iob, "Marginal Cost of Trading Allowances;;    ", join(Year[years], ";"))
  print(iob, "ETAPr;Nominal US\$/Tonne")
  for year in years  
    ZZZ[year] = ETAPr[market,year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  # TODOPromula - ETAPR lines in Promula have extra ";" delimiter. LJD,25.08.06
  println(iob)
  print(iob, "ETAPr;$CDTime CN\$/Tonne")
  for year in years  
    ZZZ[year] = ETAPr[market,year]*ExchangeRateNation[CN,CDYear]/InflationNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "ETAPr;$CDTime US\$/Tonne")
  for year in years  
    ZZZ[year] = ETAPr[market,year]/InflationNation[US,year]*InflationNation[US,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "Reference Covered Emissions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "GrossRef;Total")
  for year in years  
    ZZZ[year] = sum(GrossRef[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "GrossRef;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = GrossRef[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # println(iob, "Reference Driver (Units);;    ", join(Year[years], ";"))
  # print(iob, "DriverRef;Total")
  # for year in years  
  #   ZZZ[year] = sum(DriverRef[ecc,area,year] for area in areas, ecc in ECCs) 
  #   print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  # end
  # println(iob)
  # for area in areas
  #   print(iob, "DriverRef;$(AreaDS[area])")
  #   for year in years  
  #     ZZZ[year] = sum(DriverRef[ecc,area,year] for ecc in ECCs) 
  #     print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)

  # println(iob, "PolCov  (Units);;    ", join(Year[years], ";"))
  # print(iob, "PolCov;Total")
  # for year in years  
  #   ZZZ[year] = sum(PolCov[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs) 
  #   print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  # end
  # println(iob)
  # for area in areas
  #   print(iob, "PolCov;$(AreaDS[area])")
  #   for year in years  
  #     ZZZ[year] = sum(PolCov[ecc,poll,pcov,area,year] for pcov in pcovs, poll in polls, ecc in ECCs) 
  #     print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)

  # println(iob, "PolCovRef  (Units);;    ", join(Year[years], ";"))
  # print(iob, "PolCovRef;Total")
  # for year in years  
  #   ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs) 
  #   print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  # end
  # println(iob)
  # for area in areas
  #   print(iob, "PolCovRef;$(AreaDS[area])")
  #   for year in years  
  #     ZZZ[year] = sum(PolCovRef[ecc,poll,pcov,area,year] for pcov in pcovs, poll in polls, ecc in ECCs) 
  #     print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)

  # println(iob, "Reference EI (Units);;    ", join(Year[years], ";"))
  # print(iob, "EIRef;Total")
  # for year in years  
  #   ZZZ[year] = sum(EIRef[ecc,area,year] for area in areas, ecc in ECCs) 
  #   print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  # end
  # println(iob)
  # for area in areas
  #   print(iob, "EIRef;$(AreaDS[area])")
  #   for year in years  
  #     ZZZ[year] = sum(EIRef[ecc,area,year] for ecc in ECCs) 
  #     print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)

  # println(iob, " EI (Units);;    ", join(Year[years], ";"))
  # print(iob, "EI;Total")
  # for year in years  
  #   ZZZ[year] = sum(EI[ecc,area,year] for area in areas, ecc in ECCs) 
  #   print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  # end
  # println(iob)
  # for area in areas
  #   print(iob, "EI;$(AreaDS[area])")
  #   for year in years  
  #     ZZZ[year] = sum(EI[ecc,area,year] for ecc in ECCs) 
  #     print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  #   end
  #   println(iob)
  # end
  # println(iob)


  println(iob, "Internal Reductions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "IR;Total")
  for year in years  
    ZZZ[year] = sum(IR[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "IR;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = IR[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Covered Emissions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "Emissions;Total")
  for year in years  
    ZZZ[year] = sum(Emissions[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "Emissions;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = Emissions[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Reductions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "Reductions;Total")
  for year in years  
    ZZZ[year] = sum(Reductions[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "Reductions;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = Reductions[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Net Emissions (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "NetEmissions;Total")
  for year in years  
    ZZZ[year] = sum(NetEmissions[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "NetEmissions;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = NetEmissions[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Emissions Target (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "Target;Total")
  for year in years  
    ZZZ[year] = sum(Target[area,year] for area in areas) 
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "Target;$(AreaDS[area])")
    for year in years  
      ZZZ[year] = Target[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # GHG Emissions with Imports
  #
  eccsfp=Select(ECC,!=("ForeignPassenger"))
  eccsff=Select(ECC,!=("ForeignFreight"))
  eccs=intersect(eccsfp,eccsff)
  println(iob, "Reference GHG Emissions with Imports (Mt eCO2);;    ", join(Year[years], ";"))
  print(iob, "GHG with Imports;Total")
  for year in years  
    ZZZ[year] = (sum(TotPolRef[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls, ecc in eccs) +
        sum(PolImportsRef[poll,area,year]*PolConv[poll] for area in areas, poll in polls))/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "GHG with Imports;$(AreaDS[area])")
    for year in years  
    ZZZ[year] = (sum(TotPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls, ecc in eccs) +
        sum(PolImportsRef[poll,area,year]*PolConv[poll] for poll in polls))/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Domestic Emissions
  #
  eccsfp=Select(ECC,!=("ForeignPassenger"))
  eccsff=Select(ECC,!=("ForeignFreight"))
  eccs=intersect(eccsfp,eccsff)
  println(iob, "Reference GHG Domestic Emissions (Mt eCO2);;    ", join(Year[years], ";"))
  print(iob, "TotPol;Total")
  for year in years  
    ZZZ[year] = sum(TotPolRef[ecc,poll,area,year]*PolConv[poll] for area in areas, poll in polls, ecc in eccs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  for area in areas
    print(iob, "TotPol;$(AreaDS[area])")
    for year in years  
    ZZZ[year] = sum(TotPolRef[ecc,poll,area,year]*PolConv[poll] for poll in polls, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Allowances
  #
  areas=Select(Area,["CA","QC","ON"])
  AreaName="WCI"
  # ShowAllowances
  println(iob, "$AreaName Allowances (Mt/Year);;    ", join(Year[years], ";"))
  @. SSS = 0.0
  print(iob, "PGratis;Allocated Allowances")
  for year in years  
    ZZZ[year] = sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in eccs)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "Available;Total Available")
  for year in years  
    print(iob,";",@sprintf("%15.3f",SSS[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["CA"])
  AreaName=AreaDS[first(areas)]
  # ShowAllowances
  println(iob, "$AreaName Allowances (Mt/Year);;    ", join(Year[years], ";"))
  @. SSS = 0.0
  print(iob, "PGratis;Allocated Allowances")
  for year in years  
    ZZZ[year] = sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in eccs)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "Available;Total Available")
  for year in years  
    print(iob,";",@sprintf("%15.3f",SSS[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["QC"])
  AreaName=AreaDS[first(areas)]
  # ShowAllowances
  println(iob, "$AreaName Allowances (Mt/Year);;    ", join(Year[years], ";"))
  @. SSS = 0.0
  print(iob, "PGratis;Allocated Allowances")
  for year in years  
    ZZZ[year] = sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in eccs)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "Available;Total Available")
  for year in years  
    print(iob,";",@sprintf("%15.3f",SSS[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["ON"])
  AreaName=AreaDS[first(areas)]
  # ShowAllowances
  println(iob, "$AreaName Allowances (Mt/Year);;    ", join(Year[years], ";"))
  @. SSS = 0.0
  print(iob, "PGratis;Allocated Allowances")
  for year in years  
    ZZZ[year] = sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in eccs)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)/1e6
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "Available;Total Available")
  for year in years  
    print(iob,";",@sprintf("%15.3f",SSS[year]))
  end
  println(iob)
  println(iob)


  #
  # Flows
  #
  areas=Select(Area,["CA","QC","ON"])
  AreaName="WCI"
  # ShowFlows
  println(iob, "$AreaName Allowance Flows (Mt/Year);;    ", join(Year[years], ";"))
  @. BBB = 0.0
  print(iob, "PBuy;Allowances Needed")
  for year in years  
    ZZZ[year] = sum(max(PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PBank;Allowances Banked")
  for year in years  
    ZZZ[year] = sum(max(PBank[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PSell;Allowances Sold")
  for year in years  
    ZZZ[year] = sum(max(0-PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Allowances Redeemed from Bank")
  for year in years  
    ZZZ[year] = sum(max(PRedeem[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "NetFlow;Net Inflow")
  for year in years  
    print(iob,";",@sprintf("%15.3f",BBB[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["CA"])
  AreaName=AreaDS[first(areas)]
  # ShowFlows
  println(iob, "$AreaName Allowance Flows (Mt/Year);;    ", join(Year[years], ";"))
  @. BBB = 0.0
  print(iob, "PBuy;Allowances Needed")
  for year in years  
    ZZZ[year] = sum(max(PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PBank;Allowances Banked")
  for year in years  
    ZZZ[year] = sum(max(PBank[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PSell;Allowances Sold")
  for year in years  
    ZZZ[year] = sum(max(0-PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Allowances Redeemed from Bank")
  for year in years  
    ZZZ[year] = sum(max(PRedeem[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "NetFlow;Net Inflow")
  for year in years  
    print(iob,";",@sprintf("%15.3f",BBB[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["QC"])
  AreaName=AreaDS[first(areas)]
  # ShowFlows
  println(iob, "$AreaName Allowance Flows (Mt/Year);;    ", join(Year[years], ";"))
  @. BBB = 0.0
  print(iob, "PBuy;Allowances Needed")
  for year in years  
    ZZZ[year] = sum(max(PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PBank;Allowances Banked")
  for year in years  
    ZZZ[year] = sum(max(PBank[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PSell;Allowances Sold")
  for year in years  
    ZZZ[year] = sum(max(0-PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Allowances Redeemed from Bank")
  for year in years  
    ZZZ[year] = sum(max(PRedeem[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "NetFlow;Net Inflow")
  for year in years  
    print(iob,";",@sprintf("%15.3f",BBB[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["ON"])
  AreaName=AreaDS[first(areas)]
  # ShowFlows
  println(iob, "$AreaName Allowance Flows (Mt/Year);;    ", join(Year[years], ";"))
  @. BBB = 0.0
  print(iob, "PBuy;Allowances Needed")
  for year in years  
    ZZZ[year] = sum(max(PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PBank;Allowances Banked")
  for year in years  
    ZZZ[year] = sum(max(PBank[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PAuction;Auctioned Allowances")
  for year in years  
    ZZZ[year] = sum(PAuction[area,year] for area in areas)/1e6 - sum(TIFBuy[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PSell;Allowances Sold")
  for year in years  
    ZZZ[year] = sum(max(0-PNeed[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Allowances Redeemed from Bank")
  for year in years  
    ZZZ[year] = sum(max(PRedeem[ecc,poll,area,year],0) for area in areas, poll in polls, ecc in ECCs)/1e6
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TotalOffsets;Offsets")
  for year in years  
    ZZZ[year] = sum(TotalOffsets[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "IPermits;International Sales")
  for year in years  
    ZZZ[year] = sum(IPermits[area,year] for area in areas)
    BBB[year] = BBB[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "NetFlow;Net Inflow")
  for year in years  
    print(iob,";",@sprintf("%15.3f",BBB[year]))
  end
  println(iob)
  println(iob)


  #
  # Inventory
  #
  areas=Select(Area,["CA","QC","ON"])
  AreaName="WCI"
  # ShowInventory
  println(iob, "$AreaName Allowance Inventory (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PBank;Banked to Inventory")
  for year in years  
    ZZZ[year] = sum(PBank[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Sold From Inventory")
  for year in years  
    ZZZ[year] = sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PInventory;Inventory")
  for year in years  
    ZZZ[year] = sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["CA"])
  AreaName=AreaDS[first(areas)]
  # ShowInventory
  println(iob, "$AreaName Allowance Inventory (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PBank;Banked to Inventory")
  for year in years  
    ZZZ[year] = sum(PBank[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Sold From Inventory")
  for year in years  
    ZZZ[year] = sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PInventory;Inventory")
  for year in years  
    ZZZ[year] = sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["QC"])
  AreaName=AreaDS[first(areas)]
  # ShowInventory
  println(iob, "$AreaName Allowance Inventory (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PBank;Banked to Inventory")
  for year in years  
    ZZZ[year] = sum(PBank[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Sold From Inventory")
  for year in years  
    ZZZ[year] = sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PInventory;Inventory")
  for year in years  
    ZZZ[year] = sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["ON"])
  AreaName=AreaDS[first(areas)]
  # ShowInventory
  println(iob, "$AreaName Allowance Inventory (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "PBank;Banked to Inventory")
  for year in years  
    ZZZ[year] = sum(PBank[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PRedeem;Sold From Inventory")
  for year in years  
    ZZZ[year] = sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "PInventory;Inventory")
  for year in years  
    ZZZ[year] = sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)


  #
  # APCR
  #
  areas=Select(Area,["CA","QC","ON"])
  AreaName="WCI"
  # ShowAPCR
  println(iob, "$AreaName APCR Activity (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "TIFBuy;APCR Withdrawn")
  for year in years  
    ZZZ[year] = sum(TIFBuy[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFInventory;APCR Balance")
  for year in years  
    ZZZ[year] = sum(TIFInventory[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["CA"])
  AreaName=AreaDS[first(areas)]
  # ShowAPCR
  println(iob, "$AreaName APCR Activity (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "TIFBuy;APCR Withdrawn")
  for year in years  
    ZZZ[year] = sum(TIFBuy[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFInventory;APCR Balance")
  for year in years  
    ZZZ[year] = sum(TIFInventory[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["QC"])
  AreaName=AreaDS[first(areas)]
  # ShowAPCR
  println(iob, "$AreaName APCR Activity (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "TIFBuy;APCR Withdrawn")
  for year in years  
    ZZZ[year] = sum(TIFBuy[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFInventory;APCR Balance")
  for year in years  
    ZZZ[year] = sum(TIFInventory[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  areas=Select(Area,["ON"])
  AreaName=AreaDS[first(areas)]
  # ShowAPCR
  println(iob, "$AreaName APCR Activity (Mt/Year);;    ", join(Year[years], ";"))
  print(iob, "TIFBuy;APCR Withdrawn")
  for year in years  
    ZZZ[year] = sum(TIFBuy[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFSold;APCR Sales")
  for year in years  
    ZZZ[year] = sum(TIFSold[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob, "TIFInventory;APCR Balance")
  for year in years  
    ZZZ[year] = sum(TIFInventory[area,year] for area in areas)
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  # Create *.dta filename and write output values
  #
  filename = "WCI_Summary-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function WCI_Summary_DtaControl(db,SceName)
  @info "WCI_Summary_DtaControl"
  data = WCI_SummaryData(; db)
  (; Market,Years) = data
  (; BaseSw,CapTrade) = data

  #
  # This output file is not meaningful for the Base
  #
  market=200
  if BaseSw == 0
    if maximum(CapTrade[market,year] for year in Years) == 5
      WCI_Summary_MarketCalculations(data,market)
    end
    WCI_Summary_DtaRun(data,market,SceName)
  end
end
