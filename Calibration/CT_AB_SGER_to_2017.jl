#
# CT_AB_SGER_to_2017.jl - 2017 Version of Alberta SGER Cap-and-Trade Market
#
using EnergyModel

module CT_AB_SGER_to_2017

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

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
  Offset::SetArray = ReadDisk(db,"MainDB/OffsetKey")
  OffsetDS::SetArray = ReadDisk(db,"MainDB/OffsetDS")
  Offsets::Vector{Int} = collect(Select(Offset))
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
  YrI::SetArray = ReadDisk(db,"MainDB/YrIKey") # 'Facility On-Line Year'
  YrIDS::SetArray = ReadDisk(db,"MainDB/YrIDS")
  YrIs::Vector{Int} = collect(Select(YrI))

  #
  # Scratch Set
  #
  Facility::VariableArray{1} = zeros(Float32,1000) # Electric Generation Facilities
  Facilities::Vector{Int} = collect(Select(Facility))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade, Cap Only=2)
  CBSw::VariableArray{2} = ReadDisk(db,"SInput/CBSw") # [Market,Year] Switch to send Government Revenues to TIM (1=Yes)
  CoverNew::VariableArray{4} = ReadDisk(db,"EGInput/CoverNew") # [Plant,Poll,Area,Year] Fraction of New Plants Covered in Emissions Market (1=100% Covered)
  DriverFac::VariableArray{4} = ReadDisk(db,"SInput/DriverFac") # [ECC,Area,YrI,Year] Driver for Facilities (Driver/Yr)
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db,"SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  EIBase::VariableArray{5} = ReadDisk(db,"SInput/EIBase") # [ECC,Poll,PCov,Area,YrI] Emission Intensity Baseline (Tonnes/Driver)
  EIGoal::VariableArray{6} = ReadDisk(db,"SInput/EIGoal") # [ECC,Poll,PCov,Area,YrI,Year] Emission Intensity Goal (Tonnes/Driver)
  ElecSw::VariableArray{3} = ReadDisk(db,"SInput/ElecSw") # [Poll,Area,Year] Electricity Emission Allocation Switch
  Enforce::VariableArray{1} = ReadDisk(db,"SInput/Enforce") # [Market] First Year Market Limits are Enforced (Year)
  EORCreditMultiplier::VariableArray{3} = ReadDisk(db,"MEInput/EORCreditMultiplier") # [ECC,Area,Year] EOR Credit Multiplier (Tonne/Tonne)
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
  ETARedeem::VariableArray{2} = ReadDisk(db,"SOutput/ETARedeem") # [Market,Year] Minimum Price when Permits are Sold from Inventory ($/Tonne)
  ETRSw::VariableArray{1} = ReadDisk(db,"SInput/ETRSw") # [Market] Permit Cost Switch (1=Iterate, 2=Old Method, 0=Exogenous)
  ExYear::VariableArray{1} = ReadDisk(db,"SInput/ExYear") # [Market] Year to Define Existing Plants (Year)
  FacSw::VariableArray{1} = ReadDisk(db,"SInput/FacSw") # [Market] Facility Level Intensity Target Switch (1=Facility Target)
  FBuyFr::VariableArray{2} = ReadDisk(db,"SInput/FBuyFr") # [Market,Year] Federal (Domestic) Permits Fraction Bought (Tonnes/Tonnes)
  FInvRev::VariableArray{2} = ReadDisk(db,"SOutput/FInvRev") # [Market,Year] Federal (Domestic) Permits Inventory (M$)
  FSeFr1::VariableArray{1} = ReadDisk(db,"SInput/FSeFr1") # [Market] Price 1 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  FSeFr2::VariableArray{1} = ReadDisk(db,"SInput/FSeFr2") # [Market] Price 2 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  FSeFr3::VariableArray{1} = ReadDisk(db,"SInput/FSeFr3") # [Market] Price 3 Fraction of Allowance Reserve Released (Tonnes/Tonnes)
  GoalReduce::VariableArray{4} = ReadDisk(db,"SInput/GoalReduce") # [ECC,Area,YrI,Year] Emission Reduction Goal (Tonne/Tonne)
  GPEUSw::VariableArray{1} = ReadDisk(db,"SInput/GPEUSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous)
  GPGPrSw::VariableArray{2} = ReadDisk(db,"SInput/GPGPrSw") # [Market,Year] Gas Production Intensity based Gratis Permits (2=Intensity)
  GPNGSw::VariableArray{2} = ReadDisk(db,"SInput/GPNGSw") # [Market,Year] Gratis Permit Allocation Switch for Gas Distribution
  GPOilSw::VariableArray{2} = ReadDisk(db,"SInput/GPOilSw") # [Market,Year] Gratis Permit Allocation Switch for Gas Distribution
  GPOPrSw::VariableArray{2} = ReadDisk(db,"SInput/GPOPrSw") # [Market,Year] Oil Production Intensity based Gratis Permits (2=Intensity)
  GracePd::VariableArray{1} = ReadDisk(db,"SInput/GracePd") # [Market] Grace Period for New Facilites (Years)
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather, 2=Output, 0=Exogenous)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits, 2=Domestic Permits)
  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # [Year] Maximum Number of Iterations (Number)
  OffMktFr::VariableArray{4} = ReadDisk(db,"SInput/OffMktFr") # [ECC,Area,Market,Year] Fraction of Offsets allocated to each Market (Tonne/Tonne)
  OffNew::VariableArray{4} = ReadDisk(db,"EGInput/OffNew") # [Plant,Poll,Area,Year] Offset Permits for New Plants (Tonnes/TBtu)
  OverLimit::VariableArray{2} = ReadDisk(db,"SInput/OverLimit") # [Market,Year] Overage Limit as a Fraction (Tonne/Tonne)
  PAucSw::VariableArray{1} = ReadDisk(db,"SInput/PAucSw") # [Market] Switch to Auction Permits (1=Auction)
  PCost::VariableArray{4} = ReadDisk(db,"SOutput/PCost") # [ECC,Poll,Area,Year] Permit Cost (Real $/Tonnes)
  PBnkSw::VariableArray{2} = ReadDisk(db,"SInput/PBnkSw") # [Market,Year] Banking Switch (1=Adjust to Meet Goal)
  PCovMap::VariableArray{5} = ReadDisk(db,"SInput/PCovMap") # [FuelEP,ECC,PCov,Area,Year] Pollution Coverage Map (1=Mapped)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PIAT::VariableArray{2} = ReadDisk(db,"SInput/PIAT") # [ECC,Poll] Pollution Inventory Averaging Time (Years)
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBTU)
  PolCovRef::VariableArray{5} = ReadDisk(db,"SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  PRedFr::VariableArray{4} = ReadDisk(db,"SInput/PRedFr") # [ECC,Poll,Area,Year] Fraction of Permit Inventory Sold (Tonnes/Tonnes)
  ReC0::VariableArray{3} = ReadDisk(db,"MEInput/ReC0") # [Offset,Area,Year] C Term in Reduction Curve (Tonnes/Yr)
  RePollutant::Array{String} = ReadDisk(db,"MEInput/RePollutant") # [Offset] Reduction Main Pollutant (Name)
  ReReductionsX::VariableArray{3} = ReadDisk(db,"MEInput/ReReductionsX") # [Offset,Area,Year] Reductions Exogenous (Tonnes/Yr)
  SqPGMult::VariableArray{4} = ReadDisk(db,"SInput/SqPGMult") # [ECC,Poll,Area,Year] Sequestering Gratis Permit Multiplier (Tonne/Tonne)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") # [Year] Number of Units
  UnCoverage::VariableArray{3} = ReadDisk(db,"EGInput/UnCoverage") # [Unit,Poll,Year] Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnEIBase::VariableArray{3} = ReadDisk(db,"EGInput/UnEIBase") # [Unit,Poll,Year] Baseline Emissions Intensity (Tonnes/GWh)
  UnF1::Array{String} = ReadDisk(db,"EGInput/UnF1") # [Unit] Fuel Source 1
  UnFacility::Array{String} = ReadDisk(db,"EGInput/UnFacility") # [Unit] Facility Name
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOffsets::VariableArray{3} = ReadDisk(db,"EGInput/UnOffsets") # [Unit,Poll,Year] Offsets (Tonnes/GWh) 
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPGratis::VariableArray{3} = ReadDisk(db,"EGOutput/UnPGratis") # [Unit,Poll,Year] Gratis Permits (Tonnes/Yr)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Type (Utility or Industry)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xFSell::VariableArray{2} = ReadDisk(db,"SInput/xFSell") # [Market,Year] Exogenous Federal Permits Sold (Tonnes/Yr)
  xGoalPol::VariableArray{2} = ReadDisk(db,"SInput/xGoalPol") # [Market,Year] Pollution Goal (Tonnes eCO2/Yr)
  xGPNew::VariableArray{5} = ReadDisk(db,"EGInput/xGPNew") # [FuelEP,Plant,Poll,Area,Year] Gratis Permits for New Plants (kg/MWh)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] US Inflation Index ($/$)
  xISell::VariableArray{2} = ReadDisk(db,"SInput/xISell") # [Market,Year] Exogenous International Permits Sold (Tonnes/Yr)
  xPAuction::VariableArray{2} = ReadDisk(db,"SInput/xPAuction") # [Market,Year] Permits Available for Auction (Tonnes/Yr)
  xPGratis::VariableArray{5} = ReadDisk(db,"SInput/xPGratis") # [ECC,Poll,PCov,Area,Year] Exogenous Gratis Permits (Tonnes/Yr)
  xPolCap::VariableArray{5} = ReadDisk(db,"SInput/xPolCap") # [ECC,Poll,PCov,Area,Year] Exogenous Emissions Cap (Tonnes/Yr)
  xPolTot::VariableArray{5} = ReadDisk(db,"SInput/xPolTot") # [ECC,Poll,PCov,Area,Year] Historical Pollution (Tonnes/Yr)
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Generation in Reference Case (GWh) 
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity in Reference Case (GWh) 
  xUnGP::VariableArray{4} = ReadDisk(db,"EGInput/xUnGP") # [Unit,FuelEP,Poll,Year] Unit Intensity Target or Gratis Permits (kg/MWh)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  
  #
  # Scratch Variables
  #
  DriverInc::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(YrI)) # [ECC,Area,YrI] Driver Increment from Previous Year (Driver/Yr)
  DriverMar::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # [ECC,Area] Marginal Driver (Driver/Yr)
  DriverTot::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Driver Total across all new facitilites (Driver/Yr)
  ECCoverage::VariableArray{4} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Year)) # [ECC,Poll,PCov,Year] Emissions Coverage Before Gratis Permits (1=Covered)
  ETarget::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Emissions Target (Tonnes)
  EThreshold::VariableArray{4} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Year)) # [ECC,Poll,PCov,Year] Sectoral Coverage Before Gratis Permits (1=Covered)
  FacName::Vector{String} = fill("", length(Facility)) # [Facility] Electric Generation Facility Name
  FacPolMax::VariableArray{1} = zeros(Float32,length(Facility)) # [Facility] Maximum GHG Emissions (eCO2 Tonnes/Yr)
  GoalECC::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Emission Reduction Goal (Tonne/Tonne)
  OffsetConv::VariableArray{1} = zeros(Float32,length(Offset)) # [Offset] Pollution Conversion Factor (convert GHGs to eCO2)
  PGFrac::VariableArray{5} = zeros(Float32,length(ECC),length(Poll),length(PCov),length(Area),length(Year)) # [ECC,Poll,PCov,Area,Year] Gratis Permit Fraction (Tonnes/Tonnes)
  PolTotMar::VariableArray{2} = zeros(Float32,length(Poll),length(PCov)) # [Poll,PCov] Marginal Emissions (Tonnes/Yr)
  RePotential::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Potential Offsets (Tonne/Yr)
  ReReductionsAB::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Historical Alberta Offsets (Tonnes/Yr)
  UnEIBaseMax::VariableArray{1} = zeros(Float32,length(Poll)) # [Poll] Maximum Unit Emissions Intensity Baseline (Tonnes/GWh)
  UnEIBaseline::VariableArray{2} = zeros(Float32,length(Unit),length(Poll)) # [Unit,Poll] Unit Emissions Intensity Baseline (Tonnes/GWh)
  UnGCOffset::VariableArray{2} = zeros(Float32,length(Unit),length(Year)) # [Unit,Year] Capacity Eligible for Offsets (MW)
  UnGCOnLine::VariableArray{2} = zeros(Float32,length(Unit),length(Year)) # [Unit,Year] Capacity Coming OnLine (MW)
  UnPolMax::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit] Maximum GHG Emissions (eCO2 Tonnes/Yr)
  xUnPol::VariableArray{4} = zeros(Float32,length(Unit),length(FuelEP),length(Poll),length(Year)) # [Unit,FuelEP,Poll,Year] Pollution in Reference Case (Tonnes)
end

function GetUnitSets(data,unit)
  (; Area,ECC,Plant) = data
  (; UnArea,UnPlant,UnSector) = data
    
  #
  # This procedure selects the sets for a particular unit
  #
  if UnPlant[unit] !== ""
    # genco = Select(GenCo,UnGenCo[unit])
    plant = Select(Plant,UnPlant[unit])
    # node = Select(Node,UnNode[unit])
    area = Select(Area,UnArea[unit])
    ecc = Select(ECC,UnSector[unit])
    UnitValid = true
  else
    plant = 1
    area = 1
    ecc = 1
    UnitValid = false
  end
    return plant,area,ecc,UnitValid
    # return genco,plant,node,area,ecc
end

function DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

    areas = findall(AreaMarket[:,market,YrFinal] .== 1)
    eccs =  findall(ECCMarket[:,market,YrFinal] .== 1)    
    pcovs = findall(PCovMarket[:,market,YrFinal] .== 1) 
    polls = findall(PollMarket[:,market,YrFinal] .== 1) 
    years = collect(Current:YrFinal)
    return areas,eccs,pcovs,polls,years
end


#  Define Procedure AveEIBaseline
#  EIBase(Poll,PCov,YrI)=sum(Y)(xPolTot(ECC,Poll,PCov,A,Y)*
#                        PolConv(Poll)/xDriver(ECC,A,Y))/Year:n                       
#  End Procedure AveEIBaseline
  
function AveEIBaseline(data,ecc,polls,pcovs,area,years,yrIs)
  (;EIBase,PolConv,xPolTot,xDriver) = data
  
  for yrI in yrIs, pcov in pcovs, poll in polls
  
    @finite_math EIBase[ecc,poll,pcov,area,yrI] = 
      sum(xPolTot[ecc,poll,pcov,area,year]*PolConv[poll]/
      xDriver[ecc,area,year] for year in years)/length(years)
  
  end
end
  
#  Define Procedure MarEIBaseline
#  PolTotMar(Poll,PCov)=xmax((xPolTot(ECC,Poll,PCov,Area,Y)-
#                             xPolTot(ECC,Poll,PCov,Area,Y-1))*
#                             PolConv(Poll),0)
#  DriverMar(ECC,Area)=xmax(xDriver(ECC,Area,Y)-xDriver(ECC,Area,Y-1),0)
#  EIBase(Poll,PCov,YrI)=PolTotMar(Poll,PCov)/DriverMar(ECC,Area)
#  End Procedure MarEIBaseline  

function MarEIBaseline(data,ecc,polls,pcovs,area,year,yrI)
  (;DriverMar,EIBase,PolConv,xPolTot,PolTotMar,xDriver) = data
  
  for pcov in pcovs, poll in polls
    PolTotMar[poll,pcov] = 
      max((xPolTot[ecc,poll,pcov,area,year]-
           xPolTot[ecc,poll,pcov,area,year-1])*PolConv[poll],0)
  end
    
  DriverMar[ecc,area] = max(xDriver[ecc,area,year]-xDriver[ecc,area,year-1],0)
  
  for pcov in pcovs, poll in polls
    @finite_math EIBase[ecc,poll,pcov,area,yrI] = PolTotMar[poll,pcov]/DriverMar[ecc,area]
  end

end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Areas,ECC,ECCs,FuelEPs) = data
  (;Nation,Offsets,PCov,PCovs) = data
  (;Plant,Plants,Poll,Polls,Units,Year) = data
  (;Years,YrIs,Facility) = data
  (;AreaMarket,CapTrade,CBSw,CoverNew,DriverFac,ECCMarket,ECoverage,EIBase,EIGoal) = data
  (;ElecSw,Enforce,ETABY,ETADA1P,ETADA2P,ETADA3P,ETADAP,ETAFAP,ETAIncr,ETAMax) = data
  (;ETAMin,ETAPr,ETRSw,xExchangeRate,ExYear,FacSw,FBuyFr,FInvRev,FSeFr1,FSeFr2) = data
  (;FSeFr3,GoalReduce,GPEUSw,GPGPrSw,GPNGSw,GPOilSw,GPOPrSw,GracePd,GratSw,ISaleSw) = data
  (;OffsetConv,OffMktFr,OffNew,OverLimit,PAucSw,PCost,PCovMarket,PIAT,POCX,PolConv,xInflationNation) = data
  (;PollMarket,xPolTot,UnCode,UnCogen,UnCounter,UnCoverage,UnEIBase,UnF1,UnFacility) = data
  (;UnOffsets,UnOnLine,UnPlant,UnRetire,xDriver,xETAPr,xFSell,xGoalPol) = data
  (;xGPNew,xISell,xPAuction,xPGratis,xPolCap,xUnDmd,xUnEGA,xUnGC,xUnGP,EORCreditMultiplier) = data
  (;SqPGMult,ReC0,RePollutant,ReReductionsX,ETARedeem,PBnkSw,PRedFr,MaxIter,PolCovRef,xExchangeRateNation) = data
  (;DriverInc,DriverTot,ECCoverage,ETarget,EThreshold,FacName,FacPolMax,GoalECC,PGFrac) = data
  (;RePotential,ReReductionsAB,UnEIBaseMax,UnEIBaseline,UnGCOffset,UnGCOnLine,UnPGratis,xUnPol) = data

  #########################
  #
  # Market 1 is for the Alberta SGER Cap-and-Trade Market
  #
  market = 1

  #########################
  #
  # Remove Existing Market
  #
  AreaMarket .= 0
  PollMarket .= 0
  PCovMarket .= 0
  ECCMarket  .= 0
  ETADAP     .= 0 
  
  #########################
  #
  # Market Timing
  #
  Enforce[market] = 2007
  YrFinal = Yr(2017)
  ETABY[market] = Enforce[market]
  Current = Int(Enforce[market] - ITime + 1)
  Prior = Int(Current-1)
  WriteDisk(db,"SInput/Enforce",Enforce)
  WriteDisk(db,"SInput/ETABY",ETABY)
  years = collect(Current:YrFinal)

  #########################
  # 
  # Areas Covered
  # 
  for year in years,area in Areas
    AreaMarket[area,market,year] = 0
  end
  areas = Select(Area,"AB")
  for year in years,area in areas
    AreaMarket[area,market,year] = 1
  end
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)
    
  #########################
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
  
  #########################
  #
  # Type of Emissions Covered
  #
  for year in years, pcov in PCovs
    PCovMarket[pcov,market,year] = 0
  end
  pcovs = Select(PCov,!=("Process"))
  for year in years, pcov in pcovs
    PCovMarket[pcov,market,year] = 1
  end
  WriteDisk(db,"SInput/PCovMarket",PCovMarket)

  #########################
  # 
  # Sector Coverages
  # 
  for year in years, ecc in ECCs
    ECCMarket[ecc,market,year] = 0
  end
  eccs = Select(ECC,["Cement","LimeGypsum","CoalMining","Petrochemicals","OtherChemicals",
                     "Fertilizer","Petroleum","PulpPaperMills","CSSOilSands","OilSandsMining",
                     "OilSandsUpgraders","SAGDOilSands","SweetGasProcessing","SourGasProcessing",
                     "NGDistribution","NGPipeline","UtilityGen"])
  for year in years, ecc in eccs
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

  #########################
  # 
  # Sector Coverages
  # 
  # Emissions Threshold
  # 
  # source: "AB CT 2004 Coverage.xlsx" from Andy Wong 9/25/13 and
  #         "AB CT 2005 Coverage.xlsx" from Andy Wong 9/26/13
  # - Jeff Amlin 9/26/13

  EThreshold[eccs,polls,pcovs,years] .= 0
  CO2 = Select(Poll,"CO2")
  Energy = Select(PCov,"Energy")

  #                                                                                        2004    2005    2016
  EThreshold[Select(ECC,"Cement"),             CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  1.000,  1.000]
  EThreshold[Select(ECC,"LimeGypsum"),         CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.745,  0.733,  0.649]
  EThreshold[Select(ECC,"CoalMining"),         CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.586,  0.368,  0.392]
  EThreshold[Select(ECC,"Petrochemicals"),     CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.594,  0.577,  0.655]
  EThreshold[Select(ECC,"OtherChemicals"),     CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  1.000,  0.867]
  EThreshold[Select(ECC,"Fertilizer"),         CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.722,  0.717,  0.554]
  EThreshold[Select(ECC,"Petroleum"),          CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  0.902,  1.000]
  EThreshold[Select(ECC,"PulpPaperMills"),     CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.514,  0.663,  0.621]
  EThreshold[Select(ECC,"CSSOilSands"),        CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  1.000,  1.000]
  EThreshold[Select(ECC,"OilSandsMining"),     CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  1.000,  1.000]
  EThreshold[Select(ECC,"OilSandsUpgraders"),  CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  1.000,  1.000]
  EThreshold[Select(ECC,"SAGDOilSands"),       CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  1.000,  1.000]
  EThreshold[Select(ECC,"SweetGasProcessing"), CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.175,  0.164,  0.149]
  EThreshold[Select(ECC,"SourGasProcessing"),  CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.628,  0.635,  0.641]
  EThreshold[Select(ECC,"NGDistribution"),     CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.607,  0.600,  0.600]
  EThreshold[Select(ECC,"NGPipeline"),         CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [0.585,  0.500,  0.495]
  EThreshold[Select(ECC,"UtilityGen"),         CO2,Energy,[Yr(2004),Yr(2005),Yr(2016)]] = [1.000,  1.000,  1.000]
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  # 
  # Set Coverage for other Emissions, Emissions Sources and Years
  # 
  for ecc in eccs, poll in polls, pcov in pcovs, year in Yr(2003):Yr(2004)
    EThreshold[ecc,poll,pcov,year] = EThreshold[ecc,CO2,Energy,Yr(2004)]
  end
  for ecc in eccs, poll in polls, pcov in pcovs, year in Yr(2005):Yr(2015)
    EThreshold[ecc,poll,pcov,year] = EThreshold[ecc,CO2,Energy,Yr(2005)]
  end
  for ecc in eccs, poll in polls, pcov in pcovs, year in Yr(2016):YrFinal
    EThreshold[ecc,poll,pcov,year] = 1.0
  end
  # *EThreshold(ECC,Poll,PCov,Y)=EThreshold(ECC,CO2,Energy,2016)
  
  # 
  # Emissions Coverage (placeholder)
  # 
  years = collect(Yr(2003):YrFinal)
  for ecc in eccs, poll in polls, pcov in pcovs, year in years
    ECCoverage[ecc,poll,pcov,year] = 1.0
  end

  # 
  # Emission Coverage
  # 
  for ecc in eccs, poll in polls, pcov in pcovs, area in areas, year in years
    ECoverage[ecc,poll,pcov,area,year] = ECCoverage[ecc,poll,pcov,year]*EThreshold[ecc,poll,pcov,year]
  end
  WriteDisk(db,"SInput/ECoverage",ECoverage)
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #########################
  # 
  # Type of Market (CapTrade=5 means GHG Market)
  # 
  years = collect(Prior:YrFinal)
  for year in years
    CapTrade[market,year] = 5
  end
  years = collect(Current:YrFinal)
  WriteDisk(db,"SInput/CapTrade",CapTrade)

  # 
  # The market for permits does not generate revenues for the
  # government (CBSw=0.0)
  #
  for year in years
    CBSw[market,year] = 0.0
  end
  WriteDisk(db,"SInput/CBSw",CBSw)
  
  # 
  # Electricity Emissions are not allocated to each Sector (ElecSw=0)
  # 
  for year in years, area in areas ,poll in polls 
    ElecSw[poll,area,year] = 0.0
  end
  WriteDisk(db, "SInput/ElecSw", ElecSw)

  # 
  # Price Breaks for Releasing Allowance Reserves
  # 
  for year in years
    ETADA1P[market,year] = 40*(1+0.05)^(year+ITime-1-Enforce[market])
    ETADA2P[market,year] = 45*(1+0.05)^(year+ITime-1-Enforce[market])
    ETADA3P[market,year] = 50*(1+0.05)^(year+ITime-1-Enforce[market])
  end
  WriteDisk(db, "SInput/ETADA1P", ETADA1P)
  WriteDisk(db, "SInput/ETADA2P", ETADA2P)
  WriteDisk(db, "SInput/ETADA3P", ETADA3P)

  # 
  # Price change increment
  # 
  for year in years
    ETAIncr[market,year] = 0.75
  end
  WriteDisk(db, "SInput/ETAIncr", ETAIncr)

  # 
  # Fix price. Do not iterate to find price (ETRSw=0).
  # 
  ETRSw[market] = 0
  WriteDisk(db, "SInput/ETRSw", ETRSw)

  # 
  # The year used to define "existing" units is set to a high
  # values (ExYear=2200) to shut off this part of code.
  # 
  ExYear[market] = 2200
  WriteDisk(db,"SInput/ExYear",ExYear)

  # 
  # Facility level intensity target (FacSw=1)
  # 
  FacSw[market] = 1
  WriteDisk(db,"SInput/FacSw",FacSw)

  # 
  # Technology Fund Revenues are added to Government 
  # Revenues (FInvRev=-99)
  # 
  for year in Years
    FInvRev[market,year] = -99
  end
  WriteDisk(db, "SOutput/FInvRev", FInvRev)

  # 
  # Fraction of Allowance Reserve Released at each Price Break
  # 
  FSeFr1[market] = 0.333
  FSeFr2[market] = 0.666
  FSeFr3[market] = 1.000
  WriteDisk(db, "SInput/FSeFr1", FSeFr1)
  WriteDisk(db, "SInput/FSeFr2", FSeFr2)
  WriteDisk(db, "SInput/FSeFr3", FSeFr3)

  # 
  # Electric Utility Gratis Permits are exogenous (GPEUSw=3)
  # 
  GPEUSw[market] = 3
  WriteDisk(db, "SInput/GPEUSw", GPEUSw)

  #
  # Gas Production Gratis Permits are Intensity based (2=Intensity)
  #
  for year in years
    GPGPrSw[market,year] = 2
  end
  WriteDisk(db, "SInput/GPGPrSw", GPGPrSw)
  
  #
  # Natural Gas Distributors do not need to purchase allowances for 
  # the Natural Gas which they sell (GPNGSw=0)
  #
  for year in years
    GPNGSw[market,year] = 0
  end
  WriteDisk(db, "SInput/GPNGSw", GPNGSw)
  
  #
  # Refineries do not need to purchase allowances for the RPP(Oil)
  # which they sell (GPOilSw=0)
  #
  for year in Current:YrFinal
    GPOilSw[market,year] = 0
  end
  WriteDisk(db, "SInput/GPOilSw", GPOilSw)
  
  #
  # Oil Production Gratis Permits are Intensity Based (2=Intensity)
  #
  for year in Current:YrFinal
    GPOPrSw[market,year] = 2
  end
  WriteDisk(db, "SInput/GPOPrSw", GPOPrSw)
  
  #
  # Endogenous electric unit grace period is not used (GracePd=0)
  #
  GracePd[market] = 0
  WriteDisk(db, "SInput/GracePd", GracePd)
  
  #
  # Gratis Permits are exogenous (GratSw=0)
  #
  GratSw[market] = 0
  WriteDisk(db,"SInput/GratSw",GratSw)
  
  #
  # Maximum Number of Iterations
  #
  for year in years
    MaxIter[year] = max(MaxIter[year],1)
  end
  WriteDisk(db, "SInput/MaxIter",MaxIter)
  
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
  # Overage Limit (Fraction)
  #
  for year in years
    OverLimit[market,year] = 0.005
  end
  WriteDisk(db, "SInput/OverLimit", OverLimit)

  #
  # Gratis permits are not auctioned (PAucSw=0).
  #
  PAucSw[market] = 0
  WriteDisk(db, "SInput/PAucSw", PAucSw)

  #
  # Permit Inventory Time
  #
  for ecc in eccs, poll in polls
    PIAT[ecc,poll] = 5
  end
  WriteDisk(db, "SInput/PIAT", PIAT)

  ####################################
  # Emission Intensity Reduction Goal
  ####################################

  # 
  # Emissions Intensity Reduction Required
  # 
  years = collect(Current:YrFinal)
  for year in years, area in areas, ecc in eccs
    GoalECC[ecc,area,year] = 0.12
    GoalECC[ecc,area,Yr(2016)] = 0.15
    GoalECC[ecc,area,Yr(2017)] = 0.20
  end

  # 
  # Goals for sectors which are not phased-in.
  # 
  years = collect(Yr(2007):YrFinal)
  yrIs = collect(Yr(2007):YrFinal)
  for year in years, yrI in yrIs, area in areas, ecc in eccs
    GoalReduce[ecc,area,yrI,year] = GoalECC[ecc,area,year]
  end
    
  # 
  # Phase In facilities in selected sectors (Oil Sands)
  # 
  eccs = Select(ECC,["SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders"])
  for year in years, yrI in yrIs, area in areas, ecc in eccs
    GoalReduce[ecc,area,yrI,year] = 0
  end
 
  # 
  # All facilities built by 2007 are "existing"
  #
  years = collect(Yr(2007):YrFinal)
  yrIs = Yr(2007)
  for year in years, yrI in yrIs, area in areas, ecc in eccs
    GoalReduce[ecc,area,yrI,year] = GoalECC[ecc,area,year]
  end

  # 
  # Phase-in new facitilities
  # 
  yrIs = collect(Yr(2008):YrFinal)
  for yrI in yrIs
    YrCount = 4
    YrPhaseIn = 0
    while YrCount <= 9
      YrPhaseIn = min(yrI+(YrCount-1),YrFinal)
      for area in areas, ecc in eccs
        GoalReduce[ecc,area,yrI,YrPhaseIn] = GoalECC[ecc,area,YrPhaseIn]/6*(YrCount-3)
      end
      YrCount = YrCount+1
    end
    YrFuture = YrPhaseIn+1
    
    #
    # If YrFuture is greater than YrFinal, reverse years in "collect" function - Jeff Amlin 9/13/24
    #    
    if YrFuture <= YrFinal
      years = collect(YrFuture:YrFinal)
    else
      years = collect(YrFinal:YrFuture)             
    end

    for year in years, area in areas, ecc in eccs
      GoalReduce[ecc,area,yrI,year] = GoalReduce[ecc,area,yrI,YrPhaseIn]
    end
  end
  WriteDisk(db, "SInput/GoalReduce", GoalReduce)
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  # 
  # Generation Unit Coverage
  # 
  # Generate a list of Facility Names in the covered 
  # Areas (AreaMarket=1) and sectors (ECCMarket=1)
  # 
  FacCounter = 1
  ActiveUnits=maximum(Int(UnCounter[year]) for year in Years)
  units = collect(1:ActiveUnits)

  for unit in units
    plant,area,ecc,UnitValid = GetUnitSets(data,unit)
    if UnitValid

      for  year in years, poll in polls, fuelep in FuelEPs
        xUnPol[unit,fuelep,poll,year] = xUnDmd[unit,fuelep,year]*
                                        POCX[fuelep,plant,poll,area,year]
      end
      
      if (AreaMarket[area,market,Current] == 1) && (ECCMarket[ecc,market,Current] == 1)
      
        #
        # Find the number of unique facilities
        #
        facilities = collect(1:FacCounter)
        
        match = false
        for facility in facilities
          if FacName[facility] == UnFacility[unit]
            match = true
          end
        end

        if match == false
          FacCounter = min(FacCounter+1,length(Facility))
          FacName[FacCounter] = UnFacility[unit]
        end
        
      end # if AreaMarket 
    end # if UnitValid
  end # Unit
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  facilities = collect(1:FacCounter)
  # 
  # Only units which are part of facilities with emissions 
  # over 100000 tonnes are covered.
  # 
  for facility in facilities
  
    ActiveUnits=maximum(Int(UnCounter[year]) for year in Years)
    units_a = collect(1:ActiveUnits)
    units = findall(UnFacility[units_a] .== FacName[facility])

    if !isempty(units)
      # @info "FacName" facility FacName[facility]
      plant,area,ecc,UnitValid = GetUnitSets(data,units[1])
      if UnitValid

        if (AreaMarket[area,market,Current] == 1) && 
          (ECCMarket[ecc,market,Current] == 1)   &&
          (UnFacility[units[1]] == FacName[facility]) &&
          (FacName[facility] != "Unspecified")

          years = collect(Yr(2003):YrFinal)
          #for year in years
          #  FacPolSum[facility,year] = sum(xUnPol[unit,fuelep,poll,year]*PolConv[poll]
          #     for unit in units, fuelep in FuelEPs, poll in polls)
          #end
          #FacPolMax[facility] = maximum(FacPolSum[facility,year] for year in years)      
        
          FacPolMax[facility] = maximum(sum(xUnPol[unit,fuelep,poll,year]*PolConv[poll]
              for unit in units, fuelep in FuelEPs, poll in polls) for year in years)
                                            
          years = collect(Current:YrFinal)                                                   
          if FacPolMax[facility] > 100000
            for year in years, poll in polls, unit in units
              UnCoverage[unit,poll,year] = 1
            end
          end
        
        else FacName[facility] != "Unspecified"
          # loc1 = FacName[facility]
          # @info "Facility $loc1 has no Units."
        end
      end # if UnitValid
    else
      # @info "FacName" facility FacName[facility]
    end
  end # for facilities
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  # 
  # Renewable Units are included as offsets
  # 
  ActiveUnits=maximum(Int(UnCounter[year]) for year in Years)
  units = collect(1:ActiveUnits)

  for unit in units
    plant,area,ecc,UnitValid = GetUnitSets(data,unit)
    if UnitValid
    
      if (AreaMarket[area,market,Current] == 1) && 
         (ECCMarket[ecc,market,Current] == 1)   &&
        ((UnPlant[unit] == "OnshoreWind") || (UnPlant[unit] == "OffshoreWind") ||
         (UnPlant[unit] == "SolarPV") || (UnPlant[unit] == "SolarThermal") ||    
         (UnPlant[unit] == "Biomass") || (UnPlant[unit] == "SmallHydro"))
       
        for year in years, poll in polls
          UnCoverage[unit,poll,year] = 1
        end
        
      end
    end
  end

  for unit in units
    if UnCogen[unit] != 0
      plant,area,ecc,UnitValid = GetUnitSets(data,unit)
      if UnitValid
      
        if AreaMarket[area,market,Current] == 1 && ECCMarket[ecc,market,Current] == 1
          for year in years, poll in polls
            UnCoverage[unit,poll,year] = 1
          end
        end
      end
    end
  end
  WriteDisk(db, "EGInput/UnCoverage", UnCoverage)
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  # 
  # All new units
  # 
  for plant in Plants, poll in polls, year in years, area in areas
    CoverNew[plant,poll,area,year] = 1
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)

  # 
  # Generation Unit Emisssion Intensity
  # 
  UnEIBaseMax[Select(Poll,"CO2")] = 750.000
  UnEIBaseMax[Select(Poll,"CH4")] =   3.500
  UnEIBaseMax[Select(Poll,"N2O")] =   0.040

  CO2 = Select(Poll,"CO2")

  for unit in units 
    plant,area,ecc,UnitValid = GetUnitSets(data,unit)
    if UnitValid

      # 
      # Covered Utility Units in this Market
      # 
      if UnCoverage[unit,CO2,Current] == 1 && UnCogen[unit] == 0 &&
         AreaMarket[area,market,Current] == 1

        # 
        # Unit GHG Baseline Emisssion Intensity
        # 
        years = collect(Yr(2003):Yr(2005))
        for poll in polls
 
          @finite_math UnEIBaseline[unit,poll] =
            sum(xUnPol[unit,fuelep,poll,year] 
                for year in years, fuelep in FuelEPs)*PolConv[poll]/
            sum(xUnEGA[unit,year] for year in years) 
           
        end
        years = collect(Current:YrFinal)  

        if UnF1[unit] == "NaturalGasRaw"
          UnEIBaseline[unit,poll] = min(UnEIBaseline[unit,poll],UnEIBaseMax[poll])
        end

        # 
        # Unit GHG Emisssion Intensity Requirement
        # 
        for year in years, poll in polls
          UnEIBase[unit,poll,year] = UnEIBaseline[unit,poll]
        end
        
        for year in years, poll in polls, fuelep in FuelEPs
          xUnGP[unit,fuelep,poll,year] = UnEIBase[unit,poll,year]*(1-GoalECC[ecc,area,year])
        end

        # 
        # EI Requirements for New Units (built after ??) are
        # phased in over 9 years.
        # 
        if UnOnLine[unit] >= 2005
          YrCount = 3
          YrBase = Int(min(UnOnLine[unit]+(YrCount-1)-ITime+1,length(Year)))
          if UnCode[unit] == "AB00001300203"
            YrBase = Yr(2009)
          end
          for poll in polls
            @finite_math UnEIBaseline[unit,poll] = 
              sum(xUnPol[unit,fuelep,poll,YrBase] for fuelep in FuelEPs)*PolConv[poll]/
              xUnEGA[unit,YrBase]
          end
          
          YrPhaseIn = 0
          while YrCount <= 9
            YrPhaseIn = Int(min(UnOnLine[unit]+(YrCount-1)-ITime+1,length(Year)))
            for poll in polls
              UnEIBase[unit,poll,YrPhaseIn] = UnEIBaseline[unit,poll]
            end
            
            for poll in polls, fuelep in FuelEPs
              xUnGP[unit,fuelep,poll,YrPhaseIn] =
                UnEIBase[unit,poll,YrPhaseIn]*(1-GoalECC[ecc,area,YrPhaseIn]/6*(YrCount-3))
            end
            YrCount = YrCount+1
          end
          YrFuture = min(YrPhaseIn+1,length(Year))
          
          #
          # If YrFuture is greater than YrFinal, reverse years in "collect" function - Jeff Amlin 9/13/24
          #  
          if YrFuture <= YrFinal
             years = collect(YrFuture:YrFinal)
          else
             years = collect(YrFinal:YrFuture)             
          end

          for year in years, poll in polls
            UnEIBase[unit,poll,year] = UnEIBaseline[unit,poll]
          end
          
          for year in years, poll in polls, fuelep in FuelEPs
            xUnGP[unit,fuelep,poll,year] = UnEIBase[unit,poll,year]*(1-GoalECC[ecc,area,year])
          end
          years = collect(Current:YrFinal)
          
        end

        # 
        # Renewable Units get offsets for first 13 years
        # 
        if (UnPlant[unit] == "OnshoreWind") || (UnPlant[unit] == "OffshoreWind") ||
           (UnPlant[unit] == "SolarPV") || (UnPlant[unit] == "SolarThermal") ||    
           (UnPlant[unit] == "Biomass") || (UnPlant[unit] == "SmallHydro")
          
          # 
          # Capacity coming OnLine
          # 
          years = collect(Yr(2002):YrFinal)
          for year in years
            UnGCOnLine[unit,year] = max(xUnGC[unit,year]-xUnGC[unit,year-1],0.0)
          end
            
          # 
          # Capacity receives offset for 12 years
          #
          years = collect(Yr(2002):YrFinal)
          for year in years
            UnGCOffset[unit,year] =      UnGCOnLine[unit,year]    + UnGCOnLine[unit,year-1]  + 
              UnGCOnLine[unit,year-2]  + UnGCOnLine[unit,year-3]  + UnGCOnLine[unit,year-4]  +
              UnGCOnLine[unit,year-5]  + UnGCOnLine[unit,year-6]  + UnGCOnLine[unit,year-7]  +
              UnGCOnLine[unit,year-8]  + UnGCOnLine[unit,year-9]  + UnGCOnLine[unit,year-10] +
              UnGCOnLine[unit,year-11] + UnGCOnLine[unit,year-12]
          end

          # 
          # CO2 Emission Credits (UnOffsets) are weighted by the fraction of
          # capacity which is eligible to receive credits (UnGCOffset/xUnGC).
          # 
          years = collect(Yr(2007):YrFinal)
          for year in years
            @finite_math UnOffsets[unit,CO2,year] = 590*UnGCOffset[unit,year]/xUnGC[unit,year]
          end
          
          areas,eccs,pcovs,polls,years = 
            DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
        
        end

        # 
        # Units which retire due to CASA
        # 
        if UnCode[unit] == "AB00029600601"
          for year in Years
            UnRetire[unit,year] = 2015
            for poll in polls, fuelep in FuelEPs
              xUnGP[unit,fuelep,poll,year] = 0
            end
          end
        elseif UnCode[unit] == "AB00029600701"
          for year in Years
            UnRetire[unit,year] = 2014
            for poll in polls, fuelep in FuelEPs
              xUnGP[unit,fuelep,poll,year] = 0
            end
          end
        end
      end
      years = collect(Current:YrFinal)
        
      # 
      # Cogeneration Units
      # 
      if UnCoverage[unit,CO2,Current] == 1 && UnCogen[unit] != 0 &&
         AreaMarket[area,market,Current] == 1
           
        plant,area,ecc,UnitValid = GetUnitSets(data,unit)
        if UnitValid

          # 
          # Unit GHG Baseline Emisssion Intensity
          #
          for year in years, poll in polls
            @finite_math UnEIBase[unit,poll,year] = 
              sum(xUnPol[unit,fuelep,poll,year] for fuelep in FuelEPs)*PolConv[poll]/
              xUnEGA[unit,year]
          end
          
          if UnF1[unit] == "NaturalGasRaw"
            for year in years, poll in polls
              UnEIBase[unit,poll,year] = min(UnEIBase[unit,poll,year],UnEIBaseMax[poll])
            end
          end

          # 
          # Unit GHG Emisssion Intensity Requirement
          #
          for year in years, poll in polls, fuelep in FuelEPs
            xUnGP[unit,fuelep,poll,year] = UnEIBase[unit,poll,year]*
                                           (1-GoalECC[ecc,area,year])
          end

          # 
          # Cogeneration Units get Offset Credit
          #
          for year in years
            UnOffsets[unit,CO2,year] = 216
          end
          
        end
          
        areas,eccs,pcovs,polls,years = 
          DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

      end
    end
  end
  WriteDisk(db,"EGInput/UnEIBase",UnEIBase)
  WriteDisk(db,"EGInput/UnOffsets",UnOffsets)
  WriteDisk(db,"EGInput/xUnGP",xUnGP)    

  ####################################
  # 
  # The unit emissions caps (UnPGratis) and the credits for the
  # cogeneration units (UnPGratis) become part of the energy
  # emissions cap for each sector (xPolCap).
  # 
  areas,eccs,pcovs,polls,years = 
          DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    xPolCap[ecc,poll,pcov,area,year] = 0.0
    PolCovRef[ecc,poll,pcov,area,year] = 0.0
  end
  
  for unit in units
    plant,area,ecc,UnitValid = GetUnitSets(data,unit)
    if UnitValid
      
      for year in years
        if UnCoverage[unit,CO2,year] == 1 &&
           AreaMarket[area,market,year] == 1 &&
           ECCMarket[ecc,market,year] == 1
          
          for fuelep in FuelEPs, poll in polls
            UnPGratis[unit,poll,year] = xUnGP[unit,fuelep,poll,year]*xUnEGA[unit,year]
          end
          
          if UnCogen[unit] == 0
            pcov = Select(PCov,"Energy")
          else
            pcov = Select(PCov,"Cogeneration")
          end
          
          for poll in polls
            xPolCap[ecc,poll,pcov,area,year] = 
              xPolCap[ecc,poll,pcov,area,year]+UnPGratis[unit,poll,year]
          end
          
          for poll in polls
            PolCovRef[ecc,poll,pcov,area,year] = PolCovRef[ecc,poll,pcov,area,year]+
              sum(xUnPol[unit,fuelep,poll,year] for fuelep in FuelEPs)*PolConv[poll]
          end
        end
      end
    end
  end
  WriteDisk(db,"EGOutput/UnPGratis",UnPGratis)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  ####################################
  # 
  # New Units
  # 
  plants = Select(Plant,["OGCT","OGCC","OGSteam"])
  xGPNew[FuelEPs,plants,CO2,areas,years] .= 420
  
  plants = Select(Plant,["Coal","CoalCCS"])
  xGPNew[FuelEPs,plants,CO2,areas,years] .= 420
  
  plants = Select(Plant,["OnshoreWind","OffshoreWind","SolarPV",
                         "SolarThermal","Biomass","SmallHydro"])
  OffNew[plants,CO2,areas,years] .= 590
  
  WriteDisk(db, "EGInput/OffNew", OffNew)
  WriteDisk(db, "EGInput/xGPNew", xGPNew)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  ####################################
  
  #
  # Incremental Economic Driver
  #
  for ecc in eccs, area in areas
    DriverInc[ecc,area,Yr(2007)] = xDriver[ecc,area,Yr(2007)]
    for year in Yr(2008):YrFinal
      DriverInc[ecc,area,year] = max(xDriver[ecc,area,year]-xDriver[ecc,area,year-1],0)
    end

    # 
    # Nomalize incremental Drivers so totals match Driver
    #
    DriverFac[ecc,area,Yr(2007),Yr(2007)] = DriverInc[ecc,area,Yr(2007)]

    for year in Yr(2008):YrFinal, area in areas
      DriverTot[ecc,area,year] = sum(DriverInc[ecc,area,yr] for yr in Yr(2007):year)
      for yrI in Yr(2007):year
        @finite_math DriverFac[ecc,area,yrI,year] = 
          DriverInc[ecc,area,yrI]*xDriver[ecc,area,year]/DriverTot[ecc,area,year]
      end
    end  
  end
  WriteDisk(db, "SInput/DriverFac", DriverFac)

  ########################
  
  # 
  # Emission Intensity Baseline
  #
  for area in areas
  
    #
    # Initialize all sectors (ECC) to average intensity
    #
    for ecc in eccs
      loc1=ECC[ecc]
      @info "CT_AB_SGER_to_2017.jl - EIBase $loc1" 
      
      years = collect(Yr(2003):Yr(2005))
      yrIs = collect(Yr(2007):YrFinal)
     
      AveEIBaseline(data,ecc,polls,pcovs,area,years,yrIs)
      
      #
      # For new Oil Sands developments use marginal (new facility) emissions intensity.
      #
      if ECC[ecc] == "SAGDOilSands"   || ECC[ecc] == "CSSOilSands" ||
         ECC[ecc] == "OilSandsMining" || ECC[ecc] == "OilSandsUpgraders"

        yrIs = collect(Yr(2014):YrFinal)
        for yrI in yrIs   
          year = yrI
          MarEIBaseline(data,ecc,polls,pcovs,area,year,yrI)
        end
      end # if ECC

      WriteDisk(db, "SInput/EIBase", EIBase)       

      #########################
    
      # 
      # Emission Intensity Goal
      #
      for year in Years, yrI in YrIs, pcov in pcovs, poll in polls 
        EIGoal[ecc,poll,pcov,area,yrI,year] =
          EIBase[ecc,poll,pcov,area,yrI]*(1-GoalReduce[ecc,area,yrI,year])
      end
      WriteDisk(db, "SInput/EIGoal", EIGoal)

      #######################
      
      #
      # Emission Cap
      # 
      if ECC[ecc] == "UtilityGen"
        pcovs = Select(PCov,["Oil","NaturalGas","Cogeneration","NonCombustion",
                             "Process","Venting","Flaring"])
      else
        pcovs = Select(PCov,["Energy","Oil","NaturalGas","NonCombustion",
                             "Process","Venting","Flaring"])   
      end
      
      for year in Years, pcov in pcovs, poll in polls
        xPolCap[ecc,poll,pcov,area,year] = xPolCap[ecc,poll,pcov,area,year] + 
          sum(EIGoal[ecc,poll,pcov,area,yrI,year]*DriverFac[ecc,area,yrI,year]*
          ECoverage[ecc,poll,pcov,area,year] for yrI in YrIs)
      end
    end
  end
  
  WriteDisk(db,"SInput/xPolCap",xPolCap)
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  
  # 
  # Emission Goal
  # 
  for year in years
    xGoalPol[market,year] = sum(xPolCap[ecc,poll,pcov,area,year]
      for area in areas, pcov in pcovs, poll in polls, ecc in eccs)
  end
  WriteDisk(db,"SInput/xGoalPol",xGoalPol)

  #########################
  
  # 
  # Auctioning - Apply Gratis Permit Fraction
  # 
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    
    PGFrac[ecc,poll,pcov,area,year] = 1.00
    
    xPGratis[ecc,poll,pcov,area,year] = 
      xPolCap[ecc,poll,pcov,area,year]*PGFrac[ecc,poll,pcov,area,year]
      
  end
  WriteDisk(db,"SInput/xPGratis",xPGratis)

  #########################
  
  # 
  # Auctioned Permits
  # 
  # Auctioned Permits (xPAuction) is the difference between the Goal (xGoalPol)
  # and the Gratis (Allocated) Permits (xPGratis).
  #
  for year in years
    xPAuction[market,year] = max(xGoalPol[market,year] - 
      sum(xPGratis[ecc,poll,pcov,area,year] for ecc in eccs, poll in polls, pcov in pcovs, area in areas), 0)
  end
  WriteDisk(db, "SInput/xPAuction", xPAuction)

  #########################
  
  #
  # Covered Emissions (exclude unit emissions which are computed above)
  #
  for ecc in eccs
    if (ECC[ecc] == "UtilityGen")
      for year in years, area in areas, pcov in pcovs, poll in polls
        if (PCov[pcov] != "Energy") && (PCov[pcov] != "Cogeneration")
          PolCovRef[ecc,poll,pcov,area,year] =
            xPolTot[ecc,poll,pcov,area,year]*ECoverage[ecc,poll,pcov,area,year]*PolConv[poll]
        end
      end
    else
      for year in years, area in areas, pcov in pcovs, poll in polls
        if (PCov[pcov] != "Cogeneration")
          PolCovRef[ecc,poll,pcov,area,year] =
            xPolTot[ecc,poll,pcov,area,year]*ECoverage[ecc,poll,pcov,area,year]*PolConv[poll]
        end
      end
    end
  end
  WriteDisk(db, "SInput/BaPolCov", PolCovRef)
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  ####################################
  
  #
  # Emissions Reduction Target (ETarget) is covered Reference 
  # emissions (PolCovRef) minus emissions goal (xGoalPol).
  #
  for year in years
    ETarget[year] = sum(PolCovRef[ecc,poll,pcov,area,year]
      for ecc in eccs, poll in polls, pcov in pcovs, area in areas) -
      xGoalPol[market,year]
  end

  ####################################

  #
  # TIF and International Permits
  #
  # Unlimited Federal (TIF) Permits
  # 
  for year in years
    ISaleSw[market,year] = 2
  end

  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  #
  # First Tier Tech Fund Prices - Nominal CN$/tonne
  #
  # Time Series Revised
  # 
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  years = collect(Current:Yr(2016))
  for year in years
    ETADAP[market,year] = 15.00 / xExchangeRateNation[CN,year] / xInflationNation[US,year]
  end
  ETADAP[market,Yr(2016)] = 20.00 / xExchangeRateNation[CN,Yr(2016)] / xInflationNation[US,Yr(2016)]
  ETADAP[market,Yr(2017)] = 30.00 / xExchangeRateNation[CN,Yr(2017)] / xInflationNation[US,Yr(2017)]
  WriteDisk(db,"SInput/ETADAP",ETADAP)

  #
  # Minimum Permit Prices - Nominal CN$/tonne
  #
  years = collect(Current:YrFinal)
  for year in years
    ETAMin[market,year] = 0.25/xExchangeRateNation[CN,year]/xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/ETAMin",ETAMin)
  
  #
  # First Tier Domestic TIF Permits (xFSell) are unlimited
  #
  for year in years
    xFSell[market,year] = 1e12
  end
  WriteDisk(db, "SInput/xFSell", xFSell)

  #
  # Do not buy back Domestic Permits
  #
  for year in years
    FBuyFr[market,year] = 0.0
  end
  WriteDisk(db, "SInput/FBuyFr", FBuyFr)

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

  #
  # Maximum Permit Prices - Nominal CN$/tonne
  #
  # Time Series Revised
  # 
  for year in years
    ETAMax[market,year] = 100.00/xExchangeRateNation[CN,year]/
      xInflationNation[US,year]
  end
  WriteDisk(db,"SInput/ETAMax",ETAMax)

  #
  # Exogenous market price (xETAPr) is set equal to the
  # unlimited TF price (ETADAP)
  #
  for year in Years
    xETAPr[market,year] = ETADAP[market,year]
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
  # For ACTL they do not get double credits under the AB SGER,
  # because CCS for EOR would not get double credits - Glasha 6/12/14
  # No credit for using sequestered CO2 for EOR
  # 
  AB = Select(Area,"AB")
  ecc = Select(ECC,"LightOilMining")
  for year in Yr(2015):YrFinal
    EORCreditMultiplier[ecc,AB,year] = 0
  end
  WriteDisk(db, "MEInput/EORCreditMultiplier", EORCreditMultiplier)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # Double Credits from Scotford Upgrader with Quest CCS,
  # but only for 10 years (until 2024). - Glasha 6/12/14
  # 
  AB = Select(Area,"AB")
  ecc = Select(ECC,"OilSandsUpgraders")
  years = collect(Yr(2015):Yr(2024))
  for year in years
    SqPGMult[ecc,CO2,AB,year] = 2.0
  end
  WriteDisk(db,"SInput/SqPGMult",SqPGMult)
  
  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # Backfill ReC0
  #
  years = collect(Yr(2000):Yr(2006))
  for year in years, offset in Offsets
    ReC0[offset,AB,year] = ReC0[offset,AB,Yr(2007)]
  end

  for offset in Offsets
    OffsetConv[offset] = 1.0
    for poll in polls
      if Poll[poll] == RePollutant[offset]
        OffsetConv[offset] = PolConv[poll]
      end
    end
  end
  
  #
  # Convert reductions to eCO2 Temporarily
  #
  for year in Years, offset in Offsets   
    ReC0[offset,AB,year] = ReC0[offset,AB,year]*OffsetConv[offset]
  end

  #
  # Offset Potential
  #
  for year in Years
    RePotential[year] = sum(ReC0[offset,AB,year] for offset in Offsets)
  end

  #
  # Indicated Offset Construction
  #
  years = collect(Yr(2003):Yr(2013))
  for year in years
    ReReductionsAB[year] = 2.50*1e6
  end
  
  #
  # Scale to all types of Offsets
  #
  years = collect(Yr(2003):Yr(2013))
  for year in years, offset in Offsets
    @finite_math ReReductionsX[offset,AB,year] =
      ReC0[offset,AB,year]/RePotential[year]*ReReductionsAB[year]
  end

  #
  # Convert reductions from eCO2
  #
  years = collect(Yr(2003):Yr(2013))
  for year in years, offset in Offsets
    @finite_math ReReductionsX[offset,AB,year] = ReReductionsX[offset,AB,year]/OffsetConv[offset]
  end
  
  years = collect(Yr(2014):YrFinal)
  for year in years, offset in Offsets
    ReReductionsX[offset,AB,year] = 
      max(ReReductionsX[offset,AB,Yr(2013)],ReReductionsX[offset,AB,year])
  end
  
  WriteDisk(db,"MEInput/ReReductionsX",ReReductionsX)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
 
  #
  # Force buying and banking of permits when goal is exceeded (PBnkSw=2)
  #
  for year in years  
    PBnkSw[market,year] = 2
  end
  WriteDisk(db, "SInput/PBnkSw", PBnkSw)

  # 
  # Force selling of all banked permits into the market, as soon as,
  # they are needed.  Therefore minimum price to redeem (ETARedeem)
  # is half the TF Price (xETAPr) and fraction sold (PRedFr) is 100%.
  # 
  for year in years  
    ETARedeem[market,year] = xETAPr[market,year]/2
  end
  
  for year in years, area in areas, poll in polls, ecc in eccs
    PRedFr[ecc,poll,area,year] = 1.00
  end
 
  WriteDisk(db, "SOutput/ETARedeem", ETARedeem)
  WriteDisk(db, "SInput/PRedFr", PRedFr)

end

function CalibrationControl(db)
  @info "CT_AB_SGER_to_2017.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
