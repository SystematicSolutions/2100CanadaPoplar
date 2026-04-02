#
# CapTrade.jl - Endogenous Carbon Tax
#

using EnergyModel

module CapTrade

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

function DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

    areas = findall(AreaMarket[:,market,YrFinal] .== 1)
    eccs =  findall(ECCMarket[:,market,YrFinal] .== 1)    
    pcovs = findall(PCovMarket[:,market,YrFinal] .== 1) 
    polls = findall(PollMarket[:,market,YrFinal] .== 1) 
    years = collect(Current:YrFinal)
    return areas,eccs,pcovs,polls,years
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,Areas,ECC,ECCs,FuelEP,FuelEPs) = data 
  (; Nation,PCov,PCovs) = data
  (; Plant,Plants,Poll,Polls,Units) = data
  (; Years) = data
  (; ANMap,AreaMarket,CapTrade,CBSw,CoverNew,DriverBaseline,DriverRef) = data
  (; ECCMarket,ECoverage,EIBaseline,Enforce) = data
  (; ETABY,ETADAP,ETAFAP,ETAIncr,ETAMax,ETAMin,ETAPr,ETRSw,ExYear,FacSw) = data
  (; FBuyFr,GoalPolSw,GPEUSw,GratSw,ISaleSw,MaxIter,OBAFraction,OffMktFr) = data
  (; OffNew,OverLimit,PBnkSw,PCost,PCovMarket,PInventory) = data
  (; PolConv,PolCovRef,PollMarket,PolTotRef,SqPGMult) = data
  (; UnArea,UnCogen,UnCoverage,UnEGARef) = data
  (; UnF1,UnFlFr,UnOffsets,UnOnLine) = data
  (; UnPGratis,UnPlant,UnPolRef,UnSector,xETAPr) = data
  (; xExchangeRate,xExchangeRateNation,xFSell,xGoalPol,xGPNew) = data
  (; xInflationNation,xISell,xPGratis,xPolCap) = data
  (; xUnGP) = data
  (; EIBase,OBA,OBACogen,OBAElectric) = data
  (; OBANaturalGasNew) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US") 

  # *************************
  #
  # Reference Case Economic Driver
  #
  for year in Years, area in Areas, ecc in ECCs
    DriverBaseline[ecc,area,year] = DriverRef[ecc,area,year]
  end
  WriteDisk(db,"MInput/DriverBaseline",DriverBaseline)

  #
  # ************************
  #
  # Zero out other carbon markets
  #
  markets = union(collect(121:159),200)
  years = collect(Yr(2031):Yr(2050))
  for year in years, market in markets
    xETAPr[market,year] = 0.0
    ETADAP[market,year] = 0.0
    ETAMin[market,year] = 0.0
    ETAMax[market,year] = 0.0
  end
  years = collect(Yr(2020):Yr(2050))
  for year in years, market in markets
    PBnkSw[market,year] = 0.0
  end


  # *************************
  #
  # Federal Carbon Tax with OBA
  #
  market = 161
  
  #
  # *************************
  #
  # Market Timing
  #
  Enforce[market] = 2031
  YrFinal = Yr(2050)
  ETABY[market] = Enforce[market]
  Current = Int(Enforce[market])-ITime+1
  Prior = Current-1

  WriteDisk(db,"SInput/Enforce",Enforce)
  WriteDisk(db,"SInput/ETABY",ETABY)

  years = collect(Current:YrFinal)
  
  #
  # *************************
  #
  # Areas Covered
  #
  for year in years, area in Areas
    AreaMarket[area,market,year] = 0
  end
  areas = findall(ANMap[Areas,CN] .== 1)
  for year in years, area in areas
    AreaMarket[area,market,year] = 1
  end
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)

  #
  # *************************
  #
  # Emissions Covered
  #
  for year in years, poll in Polls
    PollMarket[poll,market,year] = 0
  end
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  for year in years, poll in polls
    PollMarket[poll,market,year] = 1
  end
  WriteDisk(db,"SInput/PollMarket",PollMarket)

  #
  # *************************
  #
  # Type of Emissions Covered
  #
  for year in years, pcov in PCovs
    PCovMarket[pcov,market,year] = 0
  end
  for year in years, pcov in PCovs
    PCovMarket[pcov,market,year] = 1
  end
  WriteDisk(db,"SInput/PCovMarket",PCovMarket)

  #
  # *************************
  #
  # Sector Coverages
  #
  for year in years, ecc in ECCs
    ECCMarket[ecc,market,year] = 1
  end
        
  #
  # Miscellaneous holds government revenues and is not covered
  #
  Miscellaneous = Select(ECC,"Miscellaneous")
  for year in years
    ECCMarket[Miscellaneous,market,year] = 0
  end
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # Sector Coverages
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end
  WriteDisk(db,"SInput/ECoverage",ECoverage)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # GHG Market (CapTrade=5)
  #
  for year in years
    CapTrade[market,year] = 0
  end
  years = collect(Prior:YrFinal)
  for year in years
    CapTrade[market,year] = 5
  end
  years = collect(Current:YrFinal)
  WriteDisk(db,"SInput/CapTrade",CapTrade)

  #
  # Emissions Fee goes to Government Revenues (CBSw=2.0)
  #
  for year in years
    CBSw[market,year] = 2.0
  end
  WriteDisk(db,"SInput/CBSw",CBSw)

  ExYear[market] = 2020
  WriteDisk(db,"SInput/ExYear",ExYear)

  #
  # Facility level intensity target (FacSw=1)
  #
  FacSw[market] = 1
  WriteDisk(db,"SInput/FacSw",FacSw)

  #
  # Electric Utility Gratis Permits are Output Based (GPEUSw=4)
  #
  GPEUSw[market] = 4
  WriteDisk(db,"SInput/GPEUSw",GPEUSw)

  #
  # Emissions goal base on Gratis Permits (GoalPolSw=1)
  #
  GoalPolSw[market] = 1
  WriteDisk(db,"SInput/GoalPolSw",GoalPolSw)

  #
  # Gratis Permits base on OBPS (GratSw=2)
  #
  GratSw[market] = 2
  WriteDisk(db,"SInput/GratSw",GratSw)
  
  #
  # Permit Cost Switch (1=Iterate Credits,2=Iterate Emissions,0=Exogenous)
  #
  ETRSw[market] = 1
  WriteDisk(db,"SInput/ETRSw",ETRSw)  

  #
  # Maximum Number of Iterations
  #
  MaxIter = max(MaxIter,5)
  WriteDisk(db,"SInput/MaxIter",MaxIter)

  #
  # Overage Limit (Fraction)
  #
  for year in years
    OverLimit[market,year] = 0.001
  end
  WriteDisk(db,"SInput/OverLimit",OverLimit)

  #
  # Price change increment
  #
  for year in years
    ETAIncr[market,year] = 0.75
  end
  WriteDisk(db,"SInput/ETAIncr",ETAIncr)

  #
  # Credit Banking Switch (1=Buy and Sell Out of Inventory)
  #
  for year in years
    PBnkSw[market,year] = 1
  end
  WriteDisk(db,"SInput/PBnkSw",PBnkSw)

  #
  # Offsets
  #
  eccs = Select(ECC,["Forestry","CropProduction","AnimalProduction","SolidWaste","Wastewater"])
  for year in years, area in areas, ecc in eccs
    OffMktFr[ecc,area,market,year] = 1.0
  end
  WriteDisk(db,"SInput/OffMktFr",OffMktFr)
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  
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

  #
  years = collect(Prior:YrFinal)
  for year in years, area in areas, poll in polls, ecc in eccs
    PInventory[ecc,poll,area,year] = 0
  end
  WriteDisk(db,"SOutput/PInventory",PInventory)  

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # All Electric Generation Units are Covered including Cogeneration
  #
  for unit in Units
    if (UnPlant[unit] !== "Null") && (UnArea[unit] !== "Null") && (UnSector[unit] !== "Null")
      plant,area,ecc = GetUnitSets(data,unit)
      for year in years
        if (AreaMarket[area,market,year] == 1) && (ECCMarket[ecc,market,year] == 1)
          for poll in polls
            UnCoverage[unit,poll,year] = 1
          end
        end
      end
    end
  end
  WriteDisk(db,"EGInput/UnCoverage",UnCoverage)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  
  #
  # Coverage of new electric generating units
  #
  UtilityGen = Select(ECC,"UtilityGen")
  for year in years, area in areas, poll in polls, plant in Plants
    if ECCMarket[UtilityGen,market,year] == 1
      CoverNew[plant,poll,area,year] = 1 
    end
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # Reference Case Emissions
  # 
  
  #
  # *************************
  #
  # Emissions Intensity from Baseline
  #
  years = collect(Yr(2014):Yr(2016))
  for area in areas, pcov in PCovs, poll in polls, ecc in eccs
    @finite_math EIBase[ecc,poll,pcov,area] = sum(PolTotRef[ecc,poll,pcov,area,year]*
      PolConv[poll]*ECoverage[ecc,poll,pcov,area,YrFinal] for year in years)/
        sum(DriverBaseline[ecc,area,year] for year in years)
  end

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    EIBaseline[ecc,poll,pcov,area,year] = EIBase[ecc,poll,pcov,area]
  end
  WriteDisk(db,"SInput/EIBaseline",EIBaseline)

  #
  # *************************
  #
  # OBA Fraction
  #
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.80
  end

  eccs = Select(ECC,["Petrochemicals","IndustrialGas","OtherChemicals",
                     "Fertilizer","Petroleum","Rubber","OtherNonferrous"])
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.90
  end

  eccs = Select(ECC,["Cement","Glass","LimeGypsum","OtherNonMetallic","IronSteel"])
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.95    
  end

  years = collect(Yr(2024):YrFinal)
  eccs = Select(ECC,["Petrochemicals","Cement","LimeGypsum",
                     "IronSteel","Aluminum","OtherChemicals"])
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = OBAFraction[ecc,area,year-1]-0.01
  end

  eccs =  findall(ECCMarket[:,market,YrFinal] .== 1)
  for ecc in eccs
    if (ECC[ecc] != "Petrochemicals") &&
       (ECC[ecc] != "Cement") &&
       (ECC[ecc] != "LimeGypsum") &&
       (ECC[ecc] != "IronSteel") &&
       (ECC[ecc] != "Aluminum") &&
       (ECC[ecc] != "OtherChemicals")
      for year in years, area in areas
        OBAFraction[ecc,area,year] = OBAFraction[ecc,area,year-1]-0.02
      end
    end
  end
  
  #
  # Reset OBA fractions (100% Gratis Permits)
  #
  for area in areas, ecc in eccs
    OBAFraction[ecc,area,Yr(2031)] = 1.00
  end
  years = collect(Yr(2032):YrFinal)
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = OBAFraction[ecc,area,year-1]-0.100
  end
   
  WriteDisk(db,"SInput/OBAFraction",OBAFraction)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # OBA with generic formula
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    OBA[ecc,poll,pcov,area,year] = EIBase[ecc,poll,pcov,area]*OBAFraction[ecc,area,year]
  end

  #
  # OBA Fraction for Electric Utility Generation
  #
  UtilityGen = Select(ECC,"UtilityGen")
  for year in years, area in areas, pcov in pcovs, poll in polls
    OBA[UtilityGen,poll,pcov,area,year] = 0.0
  end

  CO2 = Select(Poll,"CO2")
  Energy = Select(PCov,"Energy")
  years = collect(Current:YrFinal)

  plants = Select(Plant,["OGCT","OGCC","SmallOGCC","NGCCS","OGSteam"])
  for year in years, fuelep in FuelEPs, plant in plants
    OBAElectric[plant,fuelep,year] = 550.0
  end
  fueleps = Select(FuelEP,"NaturalGas")
  for year in years, fuelep in fueleps, plant in plants
    OBAElectric[plant,fuelep,year] = 370.0
  end
  fueleps = Select(FuelEP,["Biomass","RNG","Waste"])
  for year in years, fuelep in fueleps, plant in plants
    OBAElectric[plant,fuelep,year] = 0.0
  end

  for year in years
    OBACogen[year] = 370
  end

  #
  # New Natural Gas Units
  #
  # plants = Select(Plant,["OGCT","OGCC","SmallOGCC","NGCCS"])
  years = collect(Yr(2019):Yr(2021))
  for year in years 
    OBANaturalGasNew[year] = 370.0
  end
  years = collect(Yr(2030):YrFinal)
  for year in years
    OBANaturalGasNew[year] = 0.0
  end
  years = collect(Yr(2022):Yr(2029))
  for year in years 
    OBANaturalGasNew[year] = OBANaturalGasNew[year-1]+
    (OBANaturalGasNew[Yr(2030)]-OBANaturalGasNew[Yr(2021)])/(2030-2021)
  end
  years = collect(Current:YrFinal)

  #
  # Coal Units
  #
  plants = Select(Plant,["Coal","CoalCCS"])
  for fuelep in FuelEPs, plant in plants
    OBAElectric[plant,fuelep,Yr(2019)] = 800.0
    OBAElectric[plant,fuelep,Yr(2020)] = 650.0
    years = collect(Yr(2030):YrFinal)
    for year in years
      OBAElectric[plant,fuelep,year] = 370.0
    end
    years = collect(Yr(2021):Yr(2029))
    for year in years
      OBAElectric[plant,fuelep,year] = OBAElectric[plant,fuelep,year-1]+
        (OBAElectric[plant,fuelep,Yr(2030)]-OBAElectric[plant,fuelep,Yr(2020)])/(2030-2020)
    end
  end
  years = collect(Current:YrFinal)
  
  #
  # No Gratis Permits for Electric Generation
  #
  years = collect(Yr(2031):Final)
  for year in years, fuelep in FuelEPs, plant in Plants  
    OBAElectric[plant,fuelep,year]=0
  end
  for year in years  
    OBANaturalGasNew[year] = 0
    OBACogen[year] = 0
  end

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  
  #
  # *************************
  #
  # Gratis Permits and Offsets for Electric Generation
  #
  for area in areas
    units = findall(UnArea[:] .== Area[area])
    if !isempty(units)
    
      #
      # Remove any existing Gratis Permits and Offsets 
      #
      for year in years, poll in polls, unit in units
        for fuelep in FuelEPs
          xUnGP[unit,fuelep,poll,year] = 0
        end
        UnOffsets[unit,poll,year] = 0      
      end
      
      #
      # Gratis Permits and Offsets are stored in CO2
      #
      CO2 = Select(Poll,"CO2")

      #
      # For each Covered Electric Generating Unit
      #
      for year in years, unit in units
        if UnCoverage[unit,CO2,year] == 1
          plant,a,ecc = GetUnitSets(data,unit)
          
          #
          # Fossil Units get emissions credits
          #
          if (UnPlant[unit] == "OGCT") || (UnPlant[unit] == "SmallOGCC") ||
              (UnPlant[unit] == "OGCC") || (UnPlant[unit] == "OGSteam")   ||
              (UnPlant[unit] == "Coal") || (UnPlant[unit] == "CoalCCS")   ||
              (UnPlant[unit] == "NGCCS") 
            if UnCogen[unit] == 0
              for fuelep in FuelEPs
                xUnGP[unit,fuelep,CO2,year] = OBAElectric[plant,fuelep,year]
              end
              if UnOnLine[unit] > 2020
                NaturalGas = Select(FuelEP,"NaturalGas")
                xUnGP[unit,NaturalGas,CO2,year] = OBANaturalGasNew[year]  
              end
            else
              for fuelep in FuelEPs
                xUnGP[unit,fuelep,CO2,year] = OBACogen[year]
              end
            end
          end
        end
      end
    end
  end

  WriteDisk(db,"EGInput/UnOffsets",UnOffsets)
  WriteDisk(db,"EGInput/xUnGP",xUnGP)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  
  #
  # *************************
  #
  # Reference Case Generation
  #
  
  #
  # The unit emissions caps (UnPGratis) and the credits for the
  # cogeneration units (UnPGratis) become part of the energy
  # emissions cap for each sector (xPolCap).
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    xPolCap[ecc,poll,pcov,area,year] = 0.0
    PolCovRef[ecc,poll,pcov,area,year] = 0.0
  end

  Energy = Select(PCov,"Energy")

  for unit in Units
    if (UnPlant[unit] !== "Null") && (UnArea[unit] !== "Null") && (UnSector[unit] !== "Null")
      plant,area,ecc = GetUnitSets(data,unit)
      for year in years, poll in polls
        if (UnCoverage[unit,poll,year] == 1) && (AreaMarket[area,market,year] == 1) && (ECCMarket[ecc,market,year] == 1)
          
          UnPGratis[unit,poll,year] = sum(xUnGP[unit,fuelep,poll,year]*UnEGARef[unit,year]*
            UnFlFr[unit,fuelep,year] for fuelep in FuelEPs)
          
          xPolCap[ecc,poll,Energy,area,year] = xPolCap[ecc,poll,Energy,area,year]+
            UnPGratis[unit,poll,year]
          
          PolCovRef[ecc,poll,Energy,area,year] = PolCovRef[ecc,poll,Energy,area,year]+
            sum(UnPolRef[unit,fuelep,poll,year] for fuelep in FuelEPs)*PolConv[poll]
        end
      end
    end
  end

  WriteDisk(db,"EGOutput/UnPGratis",UnPGratis)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # New Units
  #
  #
  # Select Poll(CO2)
  #
  for year in years, area in areas, plant in Plants
    for fuelep in FuelEPs
      xGPNew[fuelep,plant,CO2,area,year] = 0.0
    end
    OffNew[plant,CO2,area,year] = 0
  end

  plants = Select(Plant,["OGCT","OGCC","SmallOGCC","NGCCS","OGSteam","Coal","CoalCCS"])
  for year in years, area in areas, plant in plants, fuelep in FuelEPs
    xGPNew[fuelep,plant,CO2,area,year] = OBAElectric[plant,fuelep,year]
  end

  plants = Select(Plant,["OGCT","OGCC","SmallOGCC","NGCCS","OGSteam"])
  NaturalGas = Select(FuelEP,"NaturalGas")
  for year in years, area in areas, plant in plants
    xGPNew[NaturalGas,plant,CO2,area,year] = OBANaturalGasNew[year]
  end

  WriteDisk(db,"EGInput/OffNew",OffNew)
  WriteDisk(db,"EGInput/xGPNew",xGPNew)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # Exclude electric unit emissions which are computed above
  #
  eccs_UG = Select(ECC,!=("UtilityGen"))
  eccs_subset = intersect(eccs,eccs_UG)

  #
  # Covered Emissions 
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs_subset    
    PolCovRef[ecc,poll,pcov,area,year] = PolTotRef[ecc,poll,pcov,area,year]*
      ECoverage[ecc,poll,pcov,area,year]*PolConv[poll]
  end
    
  #
  # Emission Cap
  #    
  xGoalPol[market,Yr(2031)] = 461e6
  xGoalPol[market,Yr(2034)] = 380e6   
  xGoalPol[market,Yr(2035)] = 310e6  
  xGoalPol[market,Yr(2040)] = 190e6  
  xGoalPol[market,Yr(2041)] = 165e6    
  xGoalPol[market,Yr(2045)] = 125e6  
  xGoalPol[market,Yr(2050)] =  75e6
  
  years = collect(Yr(2032):Yr(2033))
  for year in years
    xGoalPol[market,year] = xGoalPol[market,year-1]+
      (xGoalPol[market,Yr(2034)]-xGoalPol[market,Yr(2031)])/(2034-2031)
  end
  
  years = collect(Yr(2036):Yr(2039))
  for year in years
    xGoalPol[market,year] = xGoalPol[market,year-1]+
      (xGoalPol[market,Yr(2040)]-xGoalPol[market,Yr(2035)])/(2040-2035)                 
  end
  
  years = collect(Yr(2042):Yr(2044))
  for year in years
    xGoalPol[market,year] = xGoalPol[market,year-1]+
      (xGoalPol[market,Yr(2045)]-xGoalPol[market,Yr(2041)])/(2045-2041)
  end
  
  years = collect(Yr(2046):Yr(2049))
  for year in years
    xGoalPol[market,year] = xGoalPol[market,year-1]+
      (xGoalPol[market,Yr(2050)]-xGoalPol[market,Yr(2045)])/(2050-2045)
  end 
  
  #
  # Note - this excludes Electric Utility emissions since we cannot
  # easily esyimate the values - Jeff Amlin 8/14/25
  #
  years = collect(Current:YrFinal)
  PolCovTotal = sum(PolCovRef[ecc,poll,pcov,area,Current]
    for area in areas, pcov in pcovs, poll in polls, ecc in eccs)
  
  for year in Years, area in areas, pcov in pcovs, poll in polls, ecc in eccs      
    xPolCap[ecc,poll,pcov,area,year] =
      PolCovRef[ecc,poll,pcov,area,Current]/PolCovTotal*xGoalPol[market,year]
  end

  WriteDisk(db,"SInput/BaPolCov",PolCovRef)
  WriteDisk(db,"SInput/xPolCap",xPolCap)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # *************************
  #
  # Emission Goal
  #
  for year in years
    xGoalPol[market,year] = sum(xPolCap[ecc,poll,pcov,area,year] for area in areas, 
      pcov in pcovs, poll in polls, ecc in eccs)
  end
  WriteDisk(db,"SInput/xGoalPol",xGoalPol)

  #
  # *************************
  #
  # Emission Credits are energy (xPolCap
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    xPGratis[ecc,poll,pcov,area,year] = xPolCap[ecc,poll,pcov,area,year]
  end
  WriteDisk(db,"SInput/xPGratis",xPGratis)

  #
  # ************************
  #
  # Estimate Initial Prices
  #
  years = collect(Yr(2031):Final)
  for year in years
    xETAPr[market,year] = 170.00/xExchangeRateNation[CN,year]/xInflationNation[US,year]
    ETAPr[market,year] = xETAPr[market,year]*xInflationNation[US,year]
  end
  WriteDisk(db,"SOutput/ETAPr",ETAPr)
  WriteDisk(db,"SInput/xETAPr",xETAPr)

  for year in years, area in areas, poll in polls, ecc in eccs
    PCost[ecc,poll,area,year] = ETAPr[market,year]/PolConv[poll]/
      xInflationNation[US,year]*xExchangeRate[area,year]
  end
  WriteDisk(db,"SOutput/PCost",PCost)

  #
  # Maximum Permit Prices in nominal CN$/tonne
  #
  for year in years
    ETAMax[market,year] = 1500/xExchangeRateNation[CN,year]/xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/ETAMax",ETAMax)

  #
  # Minimum Permit Prices in 2030 CN$/tonne
  #
  ETAMin[market,Yr(2030)] = 170.00/
    xExchangeRateNation[CN,Yr(2030)]/xInflationNation[US,Yr(2030)]
  for year in years
    ETAMin[market,year]=ETAMin[market,year-1]*(1+0.04)
  end
  WriteDisk(db,"SInput/ETAMin",ETAMin)

  #
  # Federal (TIF) Permit Prices
  #
  for year in years
    ETADAP[market,year] = 170.00/xExchangeRateNation[CN,year]/xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/ETADAP",ETADAP)

  #
  # No Federal (TIF) Permits
  #
  for year in years
    ISaleSw[market,year] = 0.0
  end
  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  #
  # First Tier Domestic TIF Permits (xFSell) are unlimited
  #
  for year in years
    xFSell[market,year] = 0.0
  end
  WriteDisk(db,"SInput/xFSell",xFSell)

  #
  # Do not buy back Domestic Permits
  #
  for year in years
    FBuyFr[market,year] = 0.0
  end
  WriteDisk(db,"SInput/FBuyFr",FBuyFr)

  #
  # International Permit Prices
  #
  for year in years
    ETAFAP[market,year] = 0.0
  end
  WriteDisk(db,"SInput/ETAFAP",ETAFAP)

  #
  # No International Permits (xISell)
  #
  for year in years
    xISell[market,year] = 0.0
  end
  WriteDisk(db,"SInput/xISell",xISell)

end

function PolicyControl(db)
  @info "CapTrade.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
