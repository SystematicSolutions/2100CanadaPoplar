#
# CarbonTaxRemoval.jl - Carbon Tax Removal
#

using EnergyModel

module CarbonTaxRemoval

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade,Cap Only=2)
  CBSw::VariableArray{2} = ReadDisk(db,"SInput/CBSw") # [Market,Year] Switch to send Government Revenues to TIM (1=Yes)
  CoverNew::VariableArray{4} = ReadDisk(db,"EGInput/CoverNew") # [Plant,Poll,Area,Year] Fraction of New Plants Covered in Emissions Market (1=100% Covered)
  DriverBaseline::VariableArray{3} = ReadDisk(db,"MInput/DriverBaseline") # [ECC,Area,Year] Emissions Baseline Economic Driver (Various Units/Yr)
  DriverRef::VariableArray{3} = ReadDisk(BCNameDB,"MOutput/Driver") # [ECC,Area,Year] Emissions Baseline Economic Driver (Various Units/Yr)
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db,"SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  EIBaseline::VariableArray{5} = ReadDisk(db,"SInput/EIBaseline") # [ECC,Poll,PCov,Area,Year] Emission Intensity Baseline (Tonnes/Driver)
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  ETABY::VariableArray{1} = ReadDisk(db,"SInput/ETABY") # [Market] Beginning Year for Emission Trading Allowances (Year)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government (1985 US$/Tonne)
  ETAFAP::VariableArray{2} = ReadDisk(db,"SInput/ETAFAP") # [Market,Year] Cost of Foreign Allowances ($/Tonne)
  ETAIncr::VariableArray{2} = ReadDisk(db,"SInput/ETAIncr") # [Market,Year] Increment in Allowance Price if Goal is not met ($/$)
  ETAMax::VariableArray{2} = ReadDisk(db,"SInput/ETAMax") # [Market,Year] Maximum Price for Allowances ($/Tonne)
  ETAMin::VariableArray{2} = ReadDisk(db,"SInput/ETAMin") # [Market,Year] Minimum Price for Allowances ($/Tonne)
  ETAPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate Credits,2=Iterate Emissions,0=Exogenous)
  ExYear::VariableArray{1} = ReadDisk(db,"SInput/ExYear") # [Market] Year to Define Existing Plants (Year)
  FacSw::VariableArray{1} = ReadDisk(db,"SInput/FacSw") # [Market] Facility Level Intensity Target Switch (1=Facility Target)
  FBuyFr::VariableArray{2} = ReadDisk(db,"SInput/FBuyFr") # [Market,Year] Federal (Domestic) Permits Fraction Bought (Tonnes/Tonnes)
  GoalPolSw::VariableArray{1} = ReadDisk(db,"SInput/GoalPolSw") # [Market] Pollution Goal Switch (1=Gratis Permits,0=Exogenous)
  GPEUSw::VariableArray{1} = ReadDisk(db, "SInput/GPEUSw") # [Market] 'Gratis Permit Switch (1=Grandfather, 2=Output, 4=Output Based, 0=Exogenous)',
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather,2=Output,0=Exogenous)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits,2=Domestic Permits)
  MaxIter::Float32 = ReadDisk(db,"SInput/MaxIter")[1] # [tv] Maximum Number of Iterations  
  OBAFraction::VariableArray{3} = ReadDisk(db,"SInput/OBAFraction") # [ECC,Area,Year] Output-Based Allocation Fraction (Tonne/Tonne)
  OffMktFr::VariableArray{4} = ReadDisk(db,"SInput/OffMktFr") # [ECC,Area,Market,Year] Fraction of Offsets allocated to each Market (Tonne/Tonne)
  OffNew::VariableArray{4} = ReadDisk(db,"EGInput/OffNew") # [Plant,Poll,Area,Year] Offset Permits for New Plants (Tonnes/TBtu)
  OverLimit::VariableArray{2} = ReadDisk(db,"SInput/OverLimit") # [Market,Year] Overage Limit as a Fraction (Tonne/Tonne)
  PBnkSw::VariableArray{2} = ReadDisk(db,"SInput/PBnkSw") # [Market,Year] Credit Banking Switch (1=Buy and Sell Out of Inventory)
  PCost::VariableArray{4} = ReadDisk(db,"SOutput/PCost") # [ECC,Poll,Area,Year] Permit Cost (Real $/Tonnes)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PInventory::VariableArray{4} = ReadDisk(db,"SOutput/PInventory") #[ECC,Poll,Area,Year]  Permit Inventory (Tonnes)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PolCovRef::VariableArray{5} = ReadDisk(db,"SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  PolTotRef::VariableArray{5} = ReadDisk(BCNameDB,"SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Reference Pollution (Tonnes/Yr)
  SqPGMult::VariableArray{4} = ReadDisk(db,"SInput/SqPGMult") # [ECC,Poll,Area,Year] Sequestering Gratis Permit Multiplier (Tonne/Tonne)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCoverage::VariableArray{3} = ReadDisk(db,"EGInput/UnCoverage") # [Unit,Poll,Year] Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnEGARef::VariableArray{2} = ReadDisk(BCNameDB,"EGOutput/UnEGA") # [Unit,Year] Generation in Reference Case (GWh)
  UnF1::Array{String} = ReadDisk(db,"EGInput/UnF1") # [Unit] Fuel Source 1
  UnFlFr::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation  
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOffsets::VariableArray{3} = ReadDisk(db,"EGInput/UnOffsets") # [Unit,Poll,Year] Offsets (Tonnes/GWh) 
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPGratis::VariableArray{3} = ReadDisk(db,"EGOutput/UnPGratis") # [Unit,Poll,Year] Gratis Permits (Tonnes/Yr)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPolRef::VariableArray{4} = ReadDisk(db,"EGOutput/UnPol") # [Unit,FuelEP,Poll,Year] Pollution in Reference Case (Tonnes) 
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (Real US$/Tonne)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xFSell::VariableArray{2} = ReadDisk(db,"SInput/xFSell") # [Market,Year] Exogenous Federal Permits Sold (Tonnes/Yr)
  xGoalPol::VariableArray{2} = ReadDisk(db,"SInput/xGoalPol") # [Market,Year] Pollution Goal (Tonnes eCO2/Yr)
  xGPNew::VariableArray{5} = ReadDisk(db,"EGInput/xGPNew") # [FuelEP,Plant,Poll,Area,Year] Gratis Permits for New Plants (kg/MWh)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index
  xISell::VariableArray{2} = ReadDisk(db,"SInput/xISell") # [Market,Year] Exogenous International Permits Sold (Tonnes/Yr)
  xPGratis::VariableArray{5} = ReadDisk(db,"SInput/xPGratis") # [ECC,Poll,PCov,Area,Year] Exogenous Gratis Permits (Tonnes/Yr)
  xPolCap::VariableArray{5} = ReadDisk(db,"SInput/xPolCap") # [ECC,Poll,PCov,Area,Year] Exogenous Emissions Cap (Tonnes/Yr)
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Generation in Reference Case (GWh) 
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  xUnGP::VariableArray{4} = ReadDisk(db,"EGInput/xUnGP") # [Unit,FuelEP,Poll,Year] Unit Intensity Target or Gratis Permits (kg/MWh)

  # Scratch Variables
  EIBase::VariableArray{4} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Area)) # [ECC,Poll,PCov,Area] Emission Intensity Baseline (Tonnes/Driver)
  EIBaseRawNG::VariableArray{4} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Year)) # [ECC,Poll,PCov,Year] Raw Natural Gas Baseline Emission Intensity (Tonnes/Driver)
  OBA::VariableArray{5} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Area),length(Year)) # [ECC,Poll,PCov,Area,Year] Output-Based Allocations (Tonnes/Driver)
  OBACogen::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Output-Based Allocations for Cogeneration Generation (Tonnes/GWh)
  OBAElectric::VariableArray{3} = zeros(Float32,length(Plant),length(FuelEP),length(Year)) # [Plant,FuelEP,Year] Output-Based Allocations for Electric Generation (Tonnes/GWh)
  OBANaturalGasNew::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Output-Based Allocations for New Natural Gas Generation (Tonnes/GWh)
  OBARawNG::VariableArray{4} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Year)) # [ECC,Poll,PCov,Year] Output-Based Allocations for Raw Natural Gas (Tonnes/Driver)
  OBASpecial::VariableArray{2} = zeros(Float32,length(ECC),length(Year)) # [ECC,Year] Output-Based Allocations for Special Sectors (Tonnes/Driver)
  # YrFinal  'Final Year for GHG Market or Tax (Year)'
end

function GetUnitSets(data,unit)
  (; Area,ECC,Plant) = data
  (; UnArea,UnPlant,UnSector) = data

  #
  # This procedure selects the sets for a particular unit
  #
  # EmptyString = ""
  if (UnPlant[unit] !== "Null") && (UnArea[unit] !== "Null") && (UnSector[unit] !== "Null")
    # genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    # node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    return plant,area,ecc
    # return genco,plant,node,area,ecc
  end
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,Areas,ECC,ECCs,FuelEP,FuelEPs) = data 
  (; Nation,PCov,PCovs) = data
  (; Plant,Plants,Poll,Polls,Unit,Units) = data
  (; Years) = data
  (; ANMap,AreaMarket,CapTrade,CBSw,CoverNew,DriverBaseline,DriverRef) = data
  (; ECCMarket,ECoverage,EIBaseline,Enforce) = data
  (; ETABY,ETADAP,ETAFAP,ETAIncr,ETAMax,ETAMin,ETAPr,ETRSw,ExYear,FacSw) = data
  (; FBuyFr,GoalPolSw,GPEUSw,GratSw,ISaleSw,MaxIter,OBAFraction,OffMktFr) = data
  (; OffNew,OverLimit,PBnkSw,PCost,PCovMarket,PInventory) = data
  (; PolConv,PolCovRef,PollMarket,PolTotRef,SqPGMult) = data
  (; UnArea,UnCogen,UnCoverage,UnEGARef) = data
  (; UnF1,UnFlFr,UnNation,UnOffsets,UnOnLine) = data
  (; UnPGratis,UnPlant,UnPolRef,UnSector,xETAPr) = data
  (; xExchangeRate,xExchangeRateNation,xFSell,xGoalPol,xGPNew) = data
  (; xInflationNation,xISell,xPGratis,xPolCap) = data
  (; xUnGP) = data
  (; EIBase,OBA,OBACogen,OBAElectric) = data
  (; OBANaturalGasNew) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US") 
  
  #
  # *************************
  #
  # Carbon Tax Markets to be Removed
  #
  markets = union(collect(121:159),200) 

  #
  # *************************
  #
  # Market Removal Timing
  #
  YrFinal = Yr(2050)
  Current = Yr(2025)
  Prior = Current-1
  years = collect(Current:YrFinal)  

  #
  # *************************
  #
  # Areas Covered
  #
  for year in years, market in markets, area in Areas
    AreaMarket[area,market,year] = 0
  end
  areas = findall(ANMap[:,CN] .== 1.0)
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)

  #
  # *************************
  #
  # Emissions Covered
  #
  for year in years, market in markets, poll in Polls
    PollMarket[poll,market,year] = 0
  end
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  for year in years, market in markets, poll in polls
    PollMarket[poll,market,year] = 1
  end
  WriteDisk(db,"SInput/PollMarket",PollMarket)

  #
  # *************************
  #
  # Type of Emissions Covered
  #
  for year in years, market in markets, pcov in PCovs
    PCovMarket[pcov,market,year] = 0
  end
  pcovs = PCovs
  WriteDisk(db,"SInput/PCovMarket",PCovMarket)

  #
  # *************************
  #
  # Sector Coverages
  #
  for year in years, market in markets, ecc in ECCs
    ECCMarket[ecc,market,year] = 0
  end
  eccs = ECCs
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)

  #
  # *************************
  #
  # Sector Coverages
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 0.0
  end
  WriteDisk(db,"SInput/ECoverage",ECoverage)

  #
  # *************************
  #
  # GHG Market (CapTrade=0)
  #
  for year in years, market in markets
    CapTrade[market,year] = 0
  end
  WriteDisk(db,"SInput/CapTrade",CapTrade)

  #
  # Credit Banking Switch (1=Buy and Sell Out of Inventory)
  #
  years = collect(Yr(2020):Yr(2050))
  for year in years, market in markets
    PBnkSw[market,year] = 0.0
  end
  WriteDisk(db,"SInput/PBnkSw",PBnkSw)
  years = collect(Current:YrFinal)

  #
  # Offsets
  #
  eccs = Select(ECC,["Forestry","CropProduction","AnimalProduction","SolidWaste","Wastewater"])
  for year in years, market in markets, area in areas, ecc in eccs
    OffMktFr[ecc,area,market,year] = 0.0
  end
  WriteDisk(db,"SInput/OffMktFr",OffMktFr)
  eccs = ECCs

  #
  # Sequestering Credits (SqPol) are may be increased (SqPGMult) and 
  # are adjusted for extra credit for EOR (or other uses of CO2).
  #
  CO2 = Select(Poll,"CO2")
  AB = Select(Area,"AB")
  for year in years, ecc in eccs
    SqPGMult[ecc,CO2,AB,year] = 1.0
  end
  WriteDisk(db,"SInput/SqPGMult",SqPGMult)

  years = collect(Prior:YrFinal)
  for year in years, area in areas, poll in polls, ecc in eccs
    PInventory[ecc,poll,area,year] = 0
  end
  WriteDisk(db,"SOutput/PInventory",PInventory)  
  years = collect(Current:YrFinal) 

  #
  # *************************
  #
  # All Electric Generation Units are Covered including Cogeneration
  #
  units = Select(UnNation,==("CN"))
  for year in years, poll in polls, unit in units
    UnCoverage[unit,poll,year] = 0
  end
  WriteDisk(db,"EGInput/UnCoverage",UnCoverage)

  #
  # Coverage of new electric generating units
  #
  UtilityGen = Select(ECC,"UtilityGen")
  for year in years, market in markets, area in areas, poll in polls, plant in Plants
    if ECCMarket[UtilityGen,market,year] == 0
      CoverNew[plant,poll,area,year] = 0
    end
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)

  #
  # *************************
  #
  # Remove any existing Gratis Permits and Offsets for Electric Generation
  #
  units = Select(UnNation,==("CN"))
  for year in years, poll in polls, unit in units
    for fuelep in FuelEPs
      xUnGP[unit,fuelep,poll,year] = 0
    end
    UnOffsets[unit,poll,year] = 0      
  end
  WriteDisk(db,"EGInput/UnOffsets",UnOffsets)
  WriteDisk(db,"EGInput/xUnGP",xUnGP)
 
  #
  # The unit emissions caps (UnPGratis) and the credits for the
  # cogeneration units (UnPGratis) become part of the energy
  # emissions cap for each sector (xPolCap).
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    xPolCap[ecc,poll,pcov,area,year] = 0.0
    PolCovRef[ecc,poll,pcov,area,year] = 0.0
  end
  WriteDisk(db,"SInput/BaPolCov",PolCovRef)
  WriteDisk(db,"SInput/xPolCap",xPolCap)

  units = Select(UnNation,==("CN"))
  for year in years, poll in polls, unit in units
    UnPGratis[unit,poll,year] = 0
  end
  WriteDisk(db,"EGOutput/UnPGratis",UnPGratis)

  #
  # *************************
  #
  # New Units
  #
  # Select Poll(CO2)
  #
  for year in years, area in areas, plant in Plants
    for fuelep in FuelEPs
      xGPNew[fuelep,plant,CO2,area,year] = 0.0
    end
    OffNew[plant,CO2,area,year] = 0
  end
  WriteDisk(db,"EGInput/OffNew",OffNew)
  WriteDisk(db,"EGInput/xGPNew",xGPNew)

  #
  # *************************
  #
  # Emission Goal
  #
  for year in years, market in markets
    xGoalPol[market,year] = 0.0
  end
  WriteDisk(db,"SInput/xGoalPol",xGoalPol)

  #
  # *************************
  #
  # Emission Credits are energy (xPolCap
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    xPGratis[ecc,poll,pcov,area,year] = 0.0
  end
  WriteDisk(db,"SInput/xPGratis",xPGratis)

  #
  # ************************
  #
  # Zero out other carbon markets
  #
  for year in years, market in markets
    ETADAP[market,year] = 0.0
    ETAMax[market,year] = 0.0
    ETAMin[market,year] = 0.0
    ETAPr[market,year]  = 0.0
    xETAPr[market,year] = 0.0
  end

  WriteDisk(db,"SInput/ETADAP",ETADAP)
  WriteDisk(db,"SInput/ETAMax",ETAMax)
  WriteDisk(db,"SInput/ETAMin",ETAMin)
  WriteDisk(db,"SOutput/ETAPr",ETAPr)
  WriteDisk(db,"SInput/xETAPr",xETAPr)

  for year in years, area in areas, poll in polls, ecc in eccs
    PCost[ecc,poll,area,year] = 0.0
  end
  WriteDisk(db,"SOutput/PCost",PCost)

  #
  # No Federal (TIF) Permits
  #
  for year in years, market in markets
    ISaleSw[market,year] = 0.0
  end
  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  #
  # First Tier Domestic TIF Permits (xFSell) are unlimited
  #
  for year in years, market in markets
    xFSell[market,year] = 0.0
  end
  WriteDisk(db,"SInput/xFSell",xFSell)

  #
  # Do not buy back Domestic Permits
  #
  for year in years, market in markets
    FBuyFr[market,year] = 0.0
  end
  WriteDisk(db,"SInput/FBuyFr",FBuyFr)

  #
  # International Permit Prices
  #
  for year in years, market in markets
    ETAFAP[market,year] = 0.0
  end
  WriteDisk(db,"SInput/ETAFAP",ETAFAP)

  #
  # No International Permits (xISell)
  #
  for year in years, market in markets
    xISell[market,year] = 0.0
  end
  WriteDisk(db,"SInput/xISell",xISell)

end

function PolicyControl(db)
  @info "CarbonTaxRemoval.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
