#
# Market_CarbonTaxProv.jl - Emission Market Variables
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

Base.@kwdef struct Market_CarbonTaxProvData
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
  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  DriverRef::VariableArray{3} = ReadDisk(BCNameDB,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  ECCMarket::VariableArray{3} = ReadDisk(db, "SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db, "SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  Enforce::VariableArray{1} = ReadDisk(db, "SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  ETABY::VariableArray{1} = ReadDisk(db, "SInput/ETABY") # [Market] Beginning Year for Emission Trading Allowances (Year)
  ETADAP::VariableArray{2} = ReadDisk(db, "SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government ($/Tonne)
  ETAFAP::VariableArray{2} = ReadDisk(db, "SInput/ETAFAP") # [Market,Year] Cost of Foreign Allowances ($/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db, "SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  ETAPr::VariableArray{2} = ReadDisk(db, "SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances ($/Tonne)
  ETR::VariableArray{3} = ReadDisk(db, "SOutput/ETR") # [Market,Iter,Year] Permit Costs ($/Tonne)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [PointerCN,Year] Local Currency/US$ Exchange Rate (Local/US$)
  FBuy::VariableArray{2} = ReadDisk(db, "SOutput/FBuy") # [Market,Year] Federal (Domestic) Permits Bought (Tonnes/Year)
  FInventory::VariableArray{2} = ReadDisk(db, "SOutput/FInventory") # [Market,Year] Federal (Domestic) Permits Inventory (Tonnes)
  FSell::VariableArray{2} = ReadDisk(db, "SOutput/FSell") # [Market,Year] Indicated Federal Permits Sold (Tonnes/Year)
  GratSw::VariableArray{1} = ReadDisk(db, "SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous)
  GoalPol::VariableArray{2} = ReadDisk(db, "SOutput/GoalPol") # [Market,Year] Pollution Goal (Tonnes/Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [PointerCN,Year] CN Inflation Index ($/$)
  ISell::VariableArray{2} = ReadDisk(db, "SOutput/ISell") # [Market,Year] International Permits Sold (Tonnes/Year)
  MEReduce::VariableArray{4} = ReadDisk(db, "SOutput/MEReduce") # [ECC,Poll,Area,Year] Reductions from Economic Activity Emissions (Tonnes/Yr)
  Over::VariableArray{3} = ReadDisk(db, "SOutput/Over") # [Market,Iter,Year] Market Emissions Overage (Tonnes/Yr)
  PBank::VariableArray{4} = ReadDisk(db, "SOutput/PBank") # [ECC,Poll,Area,Year] Permits Banked (Tonnes/Yr)
  PAuction::VariableArray{2} = ReadDisk(db, "SOutput/PAuction") # [Market,Year] Permits Available for Auction (Tonnes/Year)
  PBuy::VariableArray{4} = ReadDisk(db, "SOutput/PBuy") # [ECC,Poll,Area,Year] Permits Bought (Tonnes/Year)
  PCovMarket::VariableArray{3} = ReadDisk(db, "SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PGratis::VariableArray{5} = ReadDisk(db, "SOutput/PGratis") # [ECC,Poll,PCov,Area,Year] Gratis Permits (Tonnes/Year)
  PInventory::VariableArray{4} = ReadDisk(db, "SOutput/PInventory") # [ECC,Poll,Area,Year] Permit Inventory (Tonnes)
  PNeed::VariableArray{4} = ReadDisk(db, "SOutput/PNeed") # [ECC,Poll,Area,Year] Permits Needed (Tonnes/Year)
  PolCov::VariableArray{5} = ReadDisk(db, "SOutput/PolCov") # [ECC,Poll,PCov,Area,Year] Covered Pollution (Tonnes/Yr)
  PolCovRef::VariableArray{5} = ReadDisk(db, "SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PolImports::VariableArray{3} = ReadDisk(db, "SOutput/PolImports") # [Poll,Area,Year] Imported Electricity Emissions (Tonnes)
  PolTot::VariableArray{5} = ReadDisk(db, "SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Total Pollution (Tonnes/Yr)
  PolTotRef::VariableArray{5} = ReadDisk(BCNameDB, "SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Total Pollution (Tonnes/Yr)
  PollMarket::VariableArray{3} = ReadDisk(db, "SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  PRedeem::VariableArray{4} = ReadDisk(db, "SOutput/PRedeem") # [ECC,Poll,Area,Year] Permits Redeemed from Inventory (Tonnes/Yr)
  PSell::VariableArray{4} = ReadDisk(db, "SOutput/PSell") # [ECC,Poll,Area,Year] Permits Sold (Tonnes/Year)
  TGratis::VariableArray{2} = ReadDisk(db, "SOutput/TGratis") # [Market,Year] Total Gratis Permits (Tonnes/Year)
  UnArea::Array{String} = ReadDisk(db, "EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db, "EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db, "EGInput/UnNode") # [Unit] Transmission Node
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
  Overage::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Overage (Mt)
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


function Market_CarbonTaxProv_DtaRun(data,market,MktName)
  (; db,BCNameDB,Area,AreaDS,Areas,ECC,ECCDS,ECCs,Iter,Iters,Market,Markets) = data
  (; Nation,PCov,PCovDS,PCovs,Poll,PollDS,Polls,Unit,Units) = data
  (; Year,Years,Yrv,CDTime,CDYear) = data
  (; SceName,AreaMarket,CapTrade,Driver,DriverRef,ECCMarket,ECoverage,Enforce,ETABY,ETADAP,
  ETAFAP,ETAIncr,ETAPr,ETR,ExchangeRateNation,FBuy,FInventory,FSell,GratSw,
  GoalPol,InflationNation,ISell,MEReduce,Over,
  PBank, PAuction,PBuy,PCovMarket,PGratis,PInventory,PNeed,PolCov,PolCovRef,PolImports,
  PolTot,PolTotRef, PollMarket,PRedeem,PSell,TGratis,UnArea,
  UnGenCo, UnNode,UnPlant,UnSector,xETAPr,xFSell,xISell,xPolCap) = data
  (; Agric,ECovMarket,EEE,EI,EIRef,Emissions,Forest,GrossRef,IPermits,
  IR, InvChange,NetEmissions,NetRef,OffCogen,OffElectric,OffMT,Overage,
  Reduce,Sequest,SequestEOR,SolidW,TFAvePrice,TIFBuy,TIFSold,Target,
  WaterW,ZZZ) = data
  
  CO2 = Select(Poll,"CO2")
  Energy = Select(PCov,"Energy")  

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; sheet name and scenario")
  println(iob, " ")
  println(iob, "This is the Market $market Summary")
  println(iob, " ")
  
  @. ECovMarket = 0  

  #
  # Select Market and Sets
  #
  if market != 1
    current = Int(Enforce[market])-ITime+1
  else
    current = Yr(2017)
  end
  eccs = findall(ECCMarket[ECCs,market,current] .== 1)
  polls = findall(PollMarket[Polls,market,current] .== 1)
  pcovs = findall(PCovMarket[PCovs,market,current] .== 1)
  areas = findall(AreaMarket[Areas,market,current] .== 1)

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

    years = collect(Yr(2017):Final)

    #
    # Termporaily assign values for output purposes
    #
    for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
      ECovMarket[ecc,poll,pcov,area,year]=ECoverage[ecc,poll,pcov,area,year]
    end

    println(iob, "Year;", ";    ", join(Year[years], ";"))
    println(iob, " ")

    #
    # Show all ECC's
    #
    #
    # Covered Emissions
    #
    PolCov::VariableArray{5} = ReadDisk(db, "SOutput/PolCov") # [ECC,Poll,PCov,Area,Year] Covered Pollution (Tonnes/Yr)  
    for year in years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
      @finite_math PolCov[ecc,poll,pcov,area,year]=PolCov[ecc,poll,pcov,area,year]*
       (ECovMarket[ecc,poll,pcov,area,year]/ECovMarket[ecc,poll,pcov,area,year])
    end
    
    PolCovRef::VariableArray{5} = ReadDisk(db, "SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
    for year in years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
      @finite_math PolCovRef[ecc,poll,pcov,area,year]=PolCovRef[ecc,poll,pcov,area,year]*
       (ECovMarket[ecc,poll,pcov,area,year]/ECovMarket[ecc,poll,pcov,area,year])
    end
    
    PBuy::VariableArray{4} = ReadDisk(db, "SOutput/PBuy") # [ECC,Poll,Area,Year] Permits Bought (Tonnes/Year)
    for year in years, area in areas, poll in polls, ecc in ECCs
      @finite_math PBuy[ecc,poll,area,year]=PBuy[ecc,poll,area,year]*
       (ECovMarket[ecc,poll,Energy,area,year]/ECovMarket[ecc,poll,Energy,area,year])
    end
   
    PSell::VariableArray{4} = ReadDisk(db, "SOutput/PSell") # [ECC,Poll,Area,Year] Permits Sold (Tonnes/Year)
    for year in years, area in areas, poll in polls, ecc in ECCs
      @finite_math PSell[ecc,poll,area,year]=PSell[ecc,poll,area,year]*
       (ECovMarket[ecc,poll,Energy,area,year]/ECovMarket[ecc,poll,Energy,area,year])
    end
    
    PBank::VariableArray{4} = ReadDisk(db, "SOutput/PBank") # [ECC,Poll,Area,Year] Permits Banked (Tonnes/Yr)
    for year in years, area in areas, poll in polls, ecc in ECCs
      @finite_math PBank[ecc,poll,area,year]=PBank[ecc,poll,area,year]*
       (ECovMarket[ecc,poll,Energy,area,year]/ECovMarket[ecc,poll,Energy,area,year])
    end
  
    PRedeem::VariableArray{4} = ReadDisk(db, "SOutput/PRedeem") # [ECC,Poll,Area,Year] Permits Redeemed from Inventory (Tonnes/Yr)
    for year in years, area in areas, poll in polls, ecc in ECCs
      @finite_math PRedeem[ecc,poll,area,year]=PRedeem[ecc,poll,area,year]*
       (ECovMarket[ecc,poll,Energy,area,year]/ECovMarket[ecc,poll,Energy,area,year])
    end
    
    PInventory::VariableArray{4} = ReadDisk(db, "SOutput/PInventory") # [ECC,Poll,Area,Year] Permit Inventory (Tonnes)
    for year in years, area in areas, poll in polls, ecc in ECCs
      @finite_math PInventory[ecc,poll,area,year]=PInventory[ecc,poll,area,year]*
       (ECovMarket[ecc,poll,Energy,area,year]/ECovMarket[ecc,poll,Energy,area,year])
    end
    
    PNeed::VariableArray{4} = ReadDisk(db, "SOutput/PNeed") # [ECC,Poll,Area,Year] Permits Needed (Tonnes/Year)
    for year in years, area in areas, poll in polls, ecc in ECCs
      @finite_math PNeed[ecc,poll,area,year]=PNeed[ecc,poll,area,year]*
       (ECovMarket[ecc,poll,Energy,area,year]/ECovMarket[ecc,poll,Energy,area,year])
    end
    
    PGratis::VariableArray{5} = ReadDisk(db, "SOutput/PGratis") # [ECC,Poll,PCov,Area,Year] Gratis Permits (Tonnes/Year)
    for year in years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
      @finite_math PGratis[ecc,poll,pcov,area,year]=PGratis[ecc,poll,pcov,area,year]*
       (ECovMarket[ecc,poll,pcov,area,year]/ECovMarket[ecc,poll,pcov,area,year])
    end  
    
    Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
    for year in years, area in areas, ecc in ECCs
      @finite_math Driver[ecc,area,year]=Driver[ecc,area,year]*
       (ECovMarket[ecc,CO2,Energy,area,year]/ECovMarket[ecc,CO2,Energy,area,year])
    end     
      
    DriverRef::VariableArray{3} = ReadDisk(BCNameDB,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)  
    for year in years, area in areas, ecc in ECCs
      @finite_math DriverRef[ecc,area,year]=DriverRef[ecc,area,year]*
       (ECovMarket[ecc,CO2,Energy,area,year]/ECovMarket[ecc,CO2,Energy,area,year])
    end  

    xPolCap::VariableArray{5} = ReadDisk(db, "SInput/xPolCap") # [ECC,Poll,PCov,Area,Year] Exogenous Emissions Cap (Tonnes/Year)
    for year in years, area in areas, pcov in pcovs, poll in polls, ecc in ECCs
      @finite_math xPolCap[ecc,poll,pcov,area,year]=xPolCap[ecc,poll,pcov,area,year]*
       (ECovMarket[ecc,poll,pcov,area,year]/ECovMarket[ecc,poll,pcov,area,year])
    end  

    #
    # Emission Intensity (Covered)
    #
    for year in years, ecc in ECCs
      @finite_math EI[ecc,year]   =
        sum(PolCov[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6/
        sum(Driver[ecc,aa,year] for aa in areas)
      @finite_math EIRef[ecc,year] = 
        sum(PolCovRef[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6/
        sum(Driver[ecc,aa,year] for aa in areas)
    end

    #
    # Emissions
    #

    for year in years
      GrossRef[year] = sum(EIRef[ecc,year]*sum(DriverRef[ecc,area,year] for area in areas) for ecc in ECCs)
      NetRef[year]=sum(EIRef[ecc,year]*sum(Driver[ecc,area,year] for area in areas) for ecc in ECCs)
      Emissions[year]=sum(PolCov[ecc,poll,pcov,area,year] for ecc in ECCs, poll in polls,pcov in pcovs, area in areas)/1e6
      #Target[year]=GoalPol[market,year]/1e6
      Target[year]=sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6
      
      FSell[market,year]=(Emissions[year]-Target[year])*1e6
      TIFSold[year]=FSell[market,year]/1e6
      TIFBuy[year]=FBuy[market,year]/1e6
      IPermits[year]=ISell[market,year]/1e6
      NetEmissions[year]=Emissions[year]-Sequest[year]-SequestEOR[year]-
        Agric[year]-Forest[year]-SolidW[year]-WaterW[year]-OffElectric[year]-
        OffMT[year]-OffCogen[year]-TIFSold[year]+TIFBuy[year]-IPermits[year]

      InvChange[year]=sum(PBank[ecc,poll,area,year]-
                      PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
      TGratis[market,year]=TGratis[market,year]/1e6
      PAuction[market,year]=PAuction[market,year]/1e6

      if Yrv[year] >= Enforce[market]
        Overage[year]=NetEmissions[year]+TIFBuy[year]+InvChange[year]-Target[year]
      end

      IR[year]=NetRef[year]-Emissions[year]
      Reduce[year]=IR[year]+Sequest[year]+SequestEOR[year]+Agric[year]+Forest[year]+SolidW[year]+WaterW[year]+
                OffElectric[year]+OffMT[year]+OffCogen[year]+TIFSold[year]-TIFBuy[year]+IPermits[year]
    end

    #
    #########################
    #
    println(iob, MktName, " Emissions Summary (Mt/Year);;    ", join(Year[years], ";"))
    print(iob, " ;Reference Case Emissions")
    for year in years
      ZZZ[year]=GrossRef[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Production Reductions")
    for year in years
      ZZZ[year]=GrossRef[year]-NetRef[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Reference Case Emissions Net of Production Reductions")
    for year in years
      ZZZ[year]=NetRef[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Internal Reductions")
    for year in years
      ZZZ[year]=IR[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Covered Emissions")
    for year in years
      ZZZ[year]=Emissions[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 1 TIF")
    for year in years
      ZZZ[year]=TIFSold[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 1 TIF Removed")
    for year in years
      ZZZ[year]=TIFBuy[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 2 TIF")
    for year in years
      ZZZ[year]=IPermits[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;TIF Total")
    for year in years
      ZZZ[year]=TIFSold[year]-TIFBuy[year]+IPermits[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Reductions")
    for year in years
      ZZZ[year]=Reduce[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Net Emissions")
    for year in years
      ZZZ[year]=NetEmissions[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Emission Target")
    for year in years
      ZZZ[year]=Target[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Gratis Permits")
    for year in years
      # ZZZ[year]=TGratis[market,year]
      ZZZ[year]=sum(PGratis[ecc,poll,pcov,area,year]
        for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Auctioned Permits")
    for year in years
      ZZZ[year]=PAuction[market,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Inventory Change")
    for year in years
      ZZZ[year]=InvChange[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Overage")
    for year in years
      ZZZ[year]=Overage[year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    println(iob, " ")

    #
    println(iob, MktName, " Cost of Permits;;    ", join(Year[years], ";"))
    print(iob, " ;Nominal (CN\$/Tonne)")
    for year in years
      ZZZ[year]=ETAPr[market,year]*ExchangeRateNation[CN,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Real ($CDTime CN\$/Tonne)")
    for year in years
      ZZZ[year]=ETAPr[market,year]*ExchangeRateNation[CN,year]/InflationNation[CN,year]*InflationNation[CN,CDYear]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)    

    print(iob, " ;Tier 1 ($CDTime CN\$/Tonne)")
    for year in years
      ZZZ[year]=ETADAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 2 ($CDTime CN\$/Tonne)")
    for year in years
      ZZZ[year]=ETAFAP[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Price before Iterations ($CDTime CN\$/Tonne)")
    for year in years
      ZZZ[year]=xETAPr[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    println(iob, " ")
    
    #

    println(iob, MktName, " Trading Activity Summary (Mt/Year);;    ", join(Year[years], ";"))
    print(iob, " ;Industry Needed")
    for year in years
      ZZZ[year]=sum(PNeed[ecc,poll,area,year] for ecc in ECCs, poll in polls, area in areas)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Industry Sales")
    for year in years
      ZZZ[year]=sum(PSell[ecc,poll,area,year] for ecc in ECCs, poll in polls, area in areas)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Government Sales")
    for year in years
      ZZZ[year]=(FSell[market,year] + ISell[market,year])/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Industry Purchases")
    for year in years
      ZZZ[year]=sum(PBuy[ecc,poll,area,year] for ecc in ECCs, poll in polls, area in areas)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Banked to Inventory")
    for year in years
      ZZZ[year]=sum(PBank[ecc,poll,area,year] for ecc in ECCs, poll in polls, area in areas)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Sold From Inventory")
    for year in years
      ZZZ[year]=sum(PRedeem[ecc,poll,area,year] for ecc in ECCs, poll in polls, area in areas)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Inventory")
    for year in years
      ZZZ[year]=sum(PInventory[ecc,poll,area,year] for ecc in ECCs, poll in polls, area in areas)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    println(iob, " ")

    #
    println(iob, MktName, " Technology Fund Summary (Tonnes);;    ", join(Year[years], ";"))
    print(iob, " ;Tier 1 Maximum Availiable")
    for year in years
      ZZZ[year]=xFSell[market,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 1 Sold into Market")
    for year in years
      ZZZ[year]=FSell[market,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 2 Maximum Availiable")
    for year in years
      ZZZ[year]=xISell[market,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 2 Sold into Market")
    for year in years
      ZZZ[year]=ISell[market,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Total Sold into Market")
    for year in years
      ZZZ[year]=FSell[market,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 1 Removed from Market")
    for year in years
      ZZZ[year]=FBuy[market,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)

    print(iob, " ;Tier 1 Balance in Reserve")
    for year in years
      ZZZ[year]=FInventory[market,year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    println(iob, " ")

    #
    println(iob, MktName, " Technology Fund Revenue ($CDTime  CN M\$);;    ", join(Year[years], ";"))
    print(iob, " ;Revenue from TF Sold into Market")
    for year in years
      ZZZ[year]=(FSell[market,year]+ISell[market,year])*TFAvePrice[year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    print(iob, " ;Expense of TF Purchased from Market")
    for year in years
      ZZZ[year]=FBuy[market,year]*TFAvePrice[year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    print(iob, " ;Net Revenue from TF Sold into Market")
    for year in years
      ZZZ[year]=(FSell[market,year]+ISell[market,year]-FBuy[market,year])*TFAvePrice[year]/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    println(iob, " ")

    #
    # Reference Case Covered Emissions
    #
    println(iob,MktName," Reference Case Covered Emissions (Mt/Year);;    ", join(Year[years], ";"))
    print(iob, "PolCovRef;Total")    
    for year in years
      ZZZ[year]=sum(PolCovRef[ecc,poll,pcov,area,year]
        for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob,"PolCovRef;",ECCDS[ecc])    
      for year in years
        ZZZ[year]=sum(PolCovRef[ecc,poll,pcov,area,year] 
          for area in areas, pcov in pcovs, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Reference Case Covered Emissions with Production Reductions
    #
    println(iob, MktName, " Reference Case Covered Emissions with Production Reductions (Mt/Year);;    ", join(Year[years], ";"))
    print(iob, "PolCovRefPR;Total")
    for year in years
      ZZZ[year]=sum(EIRef[ecc,year]*
        sum(Driver[ecc,area,year] for area in areas) for ecc in ECCs)
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PolCovRefPR;",ECCDS[ecc])
      for year in years
        ZZZ[year]=EIRef[ecc,year]*sum(Driver[ecc,area,year] for area in areas)
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Policy Covered Emissions
    #
    println(iob, MktName, " Covered Emissions (Mt/Year);;", join(Year[years], ";"))
    print(iob, "PolCov;Total")
    for year in years
      ZZZ[year]=sum(PolCov[ecc,poll,pcov,area,year]
        for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
     print(iob, "PolCov;",ECCDS[ecc])
     for year in years
        ZZZ[year]=sum(PolCov[ecc,poll,pcov,area,year]
          for area in areas, pcov in pcovs, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Reference Case Driver
    #
    println(iob,MktName," Reference Case Driver (Various Units/Year);;    ", join(Year[years], ";"))
    for ecc in ECCs
      print(iob,"DriverRef;",ECCDS[ecc])    
      for year in years
        ZZZ[year]=sum(DriverRef[ecc,area,year] for area in areas)
        print(iob,";",@sprintf("%.7f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Driver
    #
    println(iob,MktName," Driver (Various Units/Year);;    ", join(Year[years], ";"))
    for ecc in ECCs
      print(iob,"Driver;",ECCDS[ecc])    
      for year in years
        ZZZ[year]=sum(Driver[ecc,area,year] for area in areas)
        print(iob,";",@sprintf("%.7f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)    

    #
    # Reference Case Emissions Intensity
    #
    println(iob, MktName, " Reference Case Emissions Intensity (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for ecc in ECCs
      print(iob, "EIRef;",ECCDS[ecc])
      for year in years
        ZZZ[year]=EIRef[ecc,year]*1000
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emissions Intensity
    #
    println(iob, MktName, " Emissions Intensity (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for ecc in ECCs
      print(iob, "EI;",ECCDS[ecc])
      for year in years
        ZZZ[year]=EI[ecc,year]*1000
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emissions Intensity Target
    #
    println(iob, MktName, " Emissions Intensity Target (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for ecc in ECCs
      print(iob, "EI Target;",ECCDS[ecc])
      for year in years
        @finite_math ZZZ[year]=(sum(xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6/
            sum(Driver[ecc,aa,year] for aa in areas))*1000
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emission Intensity adjusted for Credits
    #
    println(iob, MktName, " Emissions Intensity with Credits (Kilotonnes/Various Units);;    ", join(Year[years], ";"))
    for ecc in ECCs
      print(iob, "EI w/Credits;",ECCDS[ecc])
      for year in years
        @finite_math ZZZ[year]=(sum(PolCov[ecc,poll,pcov,area,year]-PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)-
            sum(PBuy[ecc,pp,aa,year] for aa in areas, pp in polls))/1e6/sum(Driver[ecc,aaa,year] for aaa in areas)*1000
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Emissions Cap
    #
    println(iob, MktName, " Emissions Cap (Mt/Year);;    ", join(Year[years], ";"))
    print(iob, "xPolCap;Total")
    for year in years
      ZZZ[year]=sum(xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "xPolCap;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Permits Issued Permits (Gratis Permits)
    #
    println(iob, MktName, " Permits Issued (Mt/Year);;    ", join(Year[years], ";"))
    print(iob, "PGratis;Total")
    for year in years
      ZZZ[year]=sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PGratis;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PGratis[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Required Reductions
    #
    println(iob, MktName, " Required Reductions (Tonnes);;    ", join(Year[years], ";"))
    print(iob, "RR;Total")
    for year in years
      ZZZ[year]=sum(PolCovRef[ecc,poll,pcov,area,year]-xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "RR;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PolCovRef[ecc,poll,pcov,area,year]-xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Required Reduction Fraction
    #
    println(iob, MktName, " Required Reduction Fraction (Tonne/Tonne);;    ", join(Year[years], ";"))
    print(iob, "RR Fraction;Average")
    for year in years
      @finite_math ZZZ[year]=sum(PolCovRef[ecc,poll,pcov,area,year]-xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls, ecc in ECCs)/
            sum(PolCovRef[ee,pp,ppcov,aa,year] for aa in areas, ppcov in pcovs, pp in polls, ee in ECCs)
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "RR Fraction;",ECCDS[ecc])
      for year in years
        @finite_math ZZZ[year]=sum(PolCovRef[ecc,poll,pcov,area,year]-xPolCap[ecc,poll,pcov,area,year] for area in areas, pcov in pcovs, poll in polls)/
          sum(PolCovRef[ecc,pp,ppcov,aa,year] for aa in areas, ppcov in pcovs, pp in polls)
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    # Internal Reductions
    #
    println(iob, MktName, " Internal Reductions (Tonnes);;    ", join(Year[years], ";"))
    print(iob, "IR;Total")
    for year in years
      ZZZ[year]=sum((EIRef[ecc,year]-EI[ecc,year])*
        sum(Driver[ecc,area,year] for area in areas) for ecc in ECCs)
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "IR;",ECCDS[ecc])
      for year in years
        ZZZ[year]=(EIRef[ecc,year]-EI[ecc,year])*sum(Driver[ecc,area,year] for area in areas)
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    println(iob, MktName, " Permits Sold (Mt/Yr);;    ", join(Year[years], ";"))
    print(iob, "PSell;Total")
    for year in years
      ZZZ[year]=sum(PSell[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PSell;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PSell[ecc,poll,area,year] for area in areas, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Permits Bought (Mt/Yr);;    ", join(Year[years], ";"))
    print(iob, "PBuy;Total")
    for year in years
      ZZZ[year]=sum(PBuy[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PBuy;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PBuy[ecc,poll,area,year] for area in areas, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Permits Banked to Inventory (Mt/Yr);;    ", join(Year[years], ";"))
    print(iob, "PBank;Total")
    for year in years
      ZZZ[year]=sum(PBank[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PBank;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PBank[ecc,poll,area,year] for area in areas, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Permits Sold from Inventory (Mt/Yr);;    ", join(Year[years], ";"))
    print(iob, "PRedeem;Total")
    for year in years
      ZZZ[year]=sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PRedeem;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PRedeem[ecc,poll,area,year] for area in areas, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")


    println(iob, MktName, " Inventory Permits (Mt/Yr);;    ", join(Year[years], ";"))
    print(iob, "PInventory;Total")
    for year in years
      ZZZ[year]=sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PInventory;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PInventory[ecc,poll,area,year] for area in areas, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    println(iob, MktName, " Permits Needed (Mt/Yr);;    ", join(Year[years], ";"))
    print(iob, "PNeed;Total")
    for year in years
      ZZZ[year]=sum(PNeed[ecc,poll,area,year] for area in areas, poll in polls, ecc in ECCs)/1e6
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
    for ecc in ECCs
      print(iob, "PNeed;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(PNeed[ecc,poll,area,year] for area in areas, poll in polls)/1e6
        print(iob,";",@sprintf("%15.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
    
    #println(iob, MktName, " ECovMarket (1=Covered);;    ", join(Year[years], ";"))
    #poll = Select(Poll,"CO2")
    #pcov = Select(PCov,"Energy")
    #area = first(areas)
    #for ecc in ECCs
    #   print(iob, "ECovMarket;",ECCDS[ecc])
    #   for year in years
    #     ZZZ[year]=ECovMarket[ecc,poll,pcov,area,year]
    #     print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    #   end
    #   println(iob)
    #end

  filename = "Market_CarbonTaxProv-$market-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
end

function Market_CarbonTaxProv_DtaControl(db)
  @info "Market_CarbonTaxProv_DtaControl"
  data = Market_CarbonTaxProvData(; db)
  BaseSw = data.BaseSw
  CapTrade = data.CapTrade

  #
  # This output file is not meaningful for the Base
  # or the Reference cases.
  #

  markets = [123,128,131,140,141,142,145,146,151,152,155,161]
  for market in markets
    CT = maximum(CapTrade[market,:])
    if (BaseSw == 0) && (CT == 5)
      MktName = "Market GHG $market"
      Market_CarbonTaxProv_DtaRun(data, market, MktName)
    end
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
  Market_CarbonTaxProv_DtaControl(DB)
end
