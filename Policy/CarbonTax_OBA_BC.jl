#
# CarbonTax_OBA_BC.jl - Federal Carbon Tax with OBA for BC
#

using EnergyModel

module CarbonTax_OBA_BC

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
  ETAMax::VariableArray{2} = ReadDisk(db,"SInput/ETAMax") # [Market,Year] Maximum Price for Allowances ($/Tonne)
  ETAMin::VariableArray{2} = ReadDisk(db,"SInput/ETAMin") # [Market,Year] Minimum Price for Allowances ($/Tonne)
  ETAPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ExYear::VariableArray{1} = ReadDisk(db,"SInput/ExYear") # [Market] Year to Define Existing Plants (Year)
  FacSw::VariableArray{1} = ReadDisk(db,"SInput/FacSw") # [Market] Facility Level Intensity Target Switch (1=Facility Target)
  FBuyFr::VariableArray{2} = ReadDisk(db,"SInput/FBuyFr") # [Market,Year] Federal (Domestic) Permits Fraction Bought (Tonnes/Tonnes)
  GoalPolSw::VariableArray{1} = ReadDisk(db,"SInput/GoalPolSw") # [Market] Pollution Goal Switch (1=Gratis Permits,0=Exogenous)
  GratSw::VariableArray{1} = ReadDisk(db,"SInput/GratSw") # [Market] Gratis Permit Allocation Switch (1=Grandfather,2=Output,0=Exogenous)
  ISaleSw::VariableArray{2} = ReadDisk(db,"SInput/ISaleSw") # [Market,Year] Switch for Unlimited Sales (1=International Permits,2=Domestic Permits)
  OBAFraction::VariableArray{3} = ReadDisk(db,"SInput/OBAFraction") # [ECC,Area,Year] Output-Based Allocation Fraction (Tonne/Tonne)
  PBnkSw::VariableArray{2} = ReadDisk(db,"SInput/PBnkSw") # [Market,Year] Credit Banking Switch (1=Buy and Sell Out of Inventory)
  PCost::VariableArray{4} = ReadDisk(db,"SOutput/PCost") # [ECC,Poll,Area,Year] Permit Cost (Real $/Tonnes)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  PolCovRef::VariableArray{5} = ReadDisk(db,"SInput/BaPolCov") #[ECC,Poll,PCov,Area,Year]  Reference Case Covered Pollution (Tonnes/Yr)
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  PolTotRef::VariableArray{5} = ReadDisk(BCNameDB,"SOutput/PolTot") # [ECC,Poll,PCov,Area,Year] Reference Pollution (Tonnes/Yr)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCoverage::VariableArray{3} = ReadDisk(db,"EGInput/UnCoverage") # [Unit,Poll,Year] Fraction of Unit Covered in Emission Market (1=100% Covered)
  UnEGARef::VariableArray{2} = ReadDisk(BCNameDB,"EGOutput/UnEGA") # [Unit,Year] Generation in Reference Case (GWh)
  UnF1::Array{String} = ReadDisk(db,"EGInput/UnF1") # [Unit] Fuel Source 1
  UnFlFr::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
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
  (; Nation) = data
  (; PCov,PCovs,Plant,Plants) = data
  (; Poll,Polls,Units,Years) = data
  (; AreaMarket,CapTrade,CBSw,CoverNew,DriverBaseline,DriverRef) = data
  (; ECCMarket,ECoverage,EIBase,EIBaseline,Enforce) = data
  (; ETABY,ETADAP,ETAFAP,ETAMax,ETAMin,ETAPr) = data
  (; ExYear,FacSw,FBuyFr,GoalPolSw,GratSw,ISaleSw) = data
  (; OBA,OBACogen,OBAElectric,OBAFraction,OBANaturalGasNew) = data
  (; PBnkSw,PCost,PCovMarket,PolConv) = data
  (; PolCovRef,PollMarket,PolTotRef,UnArea,UnCode,UnCogen) = data
  (; UnCoverage,UnEGARef,UnF1,UnFlFr,UnOnLine) = data
  (; UnPGratis,UnPlant,UnPolRef,UnSector,xETAPr) = data
  (; xExchangeRate,xExchangeRateNation,xFSell,xGoalPol,xGPNew) = data
  (; xInflationNation,xISell,xPGratis,xPolCap) = data
  (; xUnEGA,xUnFlFr,xUnGP) = data

  #########################
  #
  # Reference Case Economic Driver
  #
  for year in Years, area in Areas, ecc in ECCs
    DriverBaseline[ecc,area,year] = DriverRef[ecc,area,year]
  end
  WriteDisk(db,"MInput/DriverBaseline",DriverBaseline)

  #########################
  #
  # Federal Carbon Tax with OBA for BC
  #
  market = 155

  #########################
  #
  # Market Timing
  #
  Enforce[market] = 2022
  YrFinal = Yr(2050)
  ETABY[market] = Enforce[market]
  Current = Int(Enforce[market])-ITime+1
  Prior = Current-1

  WriteDisk(db,"SInput/Enforce",Enforce)
  WriteDisk(db,"SInput/ETABY",ETABY)

  years = collect(Current:YrFinal)
  
  #########################
  #
  # Areas Covered
  #
  for year in years, area in Areas
    AreaMarket[area,market,year] = 0
  end

  areas = Select(Area,"BC")
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

  pcovs = PCovs
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

  eccs = Select(ECC,["NGPipeline",
            "Food","Lumber","PulpPaperMills",
            "Petrochemicals","IndustrialGas","OtherChemicals","Fertilizer",
            "Petroleum","Rubber","Cement","Glass","LimeGypsum","OtherNonMetallic",
            "IronSteel","Aluminum","OtherNonferrous",
            "TransportEquipment",
            "IronOreMining","OtherMetalMining","NonMetalMining",
            "LightOilMining","HeavyOilMining","FrontierOilMining","PrimaryOilSands",
            "SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders",
            "ConventionalGasProduction","SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing",
            "LNGProduction","CoalMining"])
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
  # Sector Coverages (exclude Venting and Fugitives (Process) from Oil and Gas)
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1.0
  end

  pcovs = Select(PCov,["Venting","Process"])
  eccs = Select(ECC,["LightOilMining","HeavyOilMining","FrontierOilMining"])
  for year in years, area in areas, pcov in pcovs
    if PCovMarket[pcov,market,year] == 1
      for ecc in eccs
        if ECCMarket[ecc,market,year] == 1
          for poll in polls
            ECoverage[ecc,poll,pcov,area,year] = 0.0
          end
        end
      end
    end
  end
  WriteDisk(db,"SInput/ECoverage",ECoverage)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #########################
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
  # Credit Banking Switch (1=Buy and Sell Out of Inventory)
  #
  for year in years
    PBnkSw[market,year] = 1
  end
  WriteDisk(db,"SInput/PBnkSw",PBnkSw)

  #########################
  #
  # All Electric Generation Units are Covered including Cogeneration
  # Diesel Generation exempt for NL, YT, and NU in Federal OBA - Jacob Rattray
  #
  for unit in Units
    if (UnPlant[unit] !== "Null") && (UnArea[unit] !== "Null") && (UnSector[unit] !== "Null")
      plant,area,ecc = GetUnitSets(data,unit)
      for year in years
        if (AreaMarket[area,market,year] == 1) && (ECCMarket[ecc,market,year] == 1)
          for poll in polls
            UnCoverage[unit,poll,year] = 1
          end
          if ((Area[area] == "NL") || (Area[area] == "YT") || (Area[area] == "NU")) && (UnF1[unit] == "Diesel")
            for poll in polls
              UnCoverage[unit,poll,year] = 0
            end
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
  # Diesel Generation exempt for NL, YT, and NU in Federal OBA - Jacob Rattray
  #
  UtilityGen = Select(ECC,"UtilityGen")
  for year in years, area in areas, poll in polls, plant in Plants
    if ECCMarket[UtilityGen,market,year] == 1
      CoverNew[plant,poll,area,year] = 1 
    end
    if ((Area[area] == "NL") || (Area[area] == "YT") || (Area[area] == "NU")) && Plant[plant] == "OGCT"
      CoverNew[plant,poll,area,year] = 0 
    end
  end
  WriteDisk(db,"EGInput/CoverNew",CoverNew)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #########################
  #
  # Reference Case Emissions
  # 
  
  #########################
  #
  # Emissions Intensity from Baseline
  #
  years = collect(Yr(2019):Yr(2021))
  for area in areas, pcov in PCovs, poll in polls, ecc in eccs
    @finite_math EIBase[ecc,poll,pcov,area] = sum(PolTotRef[ecc,poll,pcov,area,year]*
      PolConv[poll]*ECoverage[ecc,poll,pcov,area,YrFinal] for year in years)/
        sum(DriverBaseline[ecc,area,year] for year in years)
  end

  eccs = Select(ECC,"LNGProduction")
  years = Yr(2025)
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

  #########################
  #
  # OBA Fraction
  #
  years = collect(Yr(2019):Yr(2024))
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.65
  end
  eccs = Select(ECC,"Aluminum")
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.95
  end
  eccs = Select(ECC,["Cement","OtherChemicals","LimeGypsum","OtherNonMetallic"])
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.90
  end
  eccs = Select(ECC,"OtherNonferrous")
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.85
  end
  eccs = Select(ECC,"OtherMetalMining")
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = 0.80
  end
  areas,eccs,pcovs,polls,years = 
  DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)
  years = collect(Yr(2025):Yr(2030))
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = OBAFraction[ecc,area,year-1]-0.01
  end
  
  years = collect(Yr(2031):Final)
  for year in years, area in areas, ecc in eccs
    OBAFraction[ecc,area,year] = OBAFraction[ecc,area,Yr(2030)]
  end

  eccs = Select(ECC,"LNGProduction")
  for area in areas, ecc in eccs
    OBAFraction[ecc,area,Yr(2025)] = 1.00
    OBAFraction[ecc,area,Yr(2026)] = 1.00
    OBAFraction[ecc,area,Yr(2027)] = 1.00
    OBAFraction[ecc,area,Yr(2028)] = 0.68
    OBAFraction[ecc,area,Yr(2029)] = 0.71
    OBAFraction[ecc,area,Yr(2030)] = 0.73
    OBAFraction[ecc,area,Yr(2031)] = 0.68
    OBAFraction[ecc,area,Yr(2032)] = 0.62
    OBAFraction[ecc,area,Yr(2033)] = 0.72
    OBAFraction[ecc,area,Yr(2034)] = 0.77
    OBAFraction[ecc,area,Yr(2035)] = 0.76
    OBAFraction[ecc,area,Yr(2036)] = 0.61
    OBAFraction[ecc,area,Yr(2037)] = 0.60
    OBAFraction[ecc,area,Yr(2038)] = 0.53
    OBAFraction[ecc,area,Yr(2039)] = 0.48
    OBAFraction[ecc,area,Yr(2040)] = 0.47
    OBAFraction[ecc,area,Yr(2041)] = 0.46
    OBAFraction[ecc,area,Yr(2042)] = 0.45
    OBAFraction[ecc,area,Yr(2043)] = 0.45
    OBAFraction[ecc,area,Yr(2044)] = 0.44
    OBAFraction[ecc,area,Yr(2045)] = 0.43
    OBAFraction[ecc,area,Yr(2046)] = 0.42
    OBAFraction[ecc,area,Yr(2047)] = 0.41
    OBAFraction[ecc,area,Yr(2048)] = 0.40
    OBAFraction[ecc,area,Yr(2049)] = 0.40
    OBAFraction[ecc,area,Yr(2050)] = 0.39
  end

  WriteDisk(db,"SInput/OBAFraction",OBAFraction)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)


  #########################
  #
  # OBA with generic formula
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    OBA[ecc,poll,pcov,area,year] = EIBase[ecc,poll,pcov,area]*OBAFraction[ecc,area,year]
  end

  
  #########################
  #
  # Exclude electric unit emissions which are computed above
  #
  eccs_UG = Select(ECC,!=("UtilityGen"))
  eccs_subset = intersect(eccs,eccs_UG)
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs_subset

    #
    # Covered Emissions 
    #
    PolCovRef[ecc,poll,pcov,area,year] = PolTotRef[ecc,poll,pcov,area,year]*
      ECoverage[ecc,poll,pcov,area,year]*PolConv[poll]

    #
    # Emission Cap
    #
    xPolCap[ecc,poll,pcov,area,year] = OBA[ecc,poll,pcov,area,year]*
      DriverBaseline[ecc,area,year]
  end
  
  WriteDisk(db,"SInput/BaPolCov",PolCovRef)
  WriteDisk(db,"SInput/xPolCap",xPolCap)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #########################
  #
  # Emission Goal
  #
  for year in years
    xGoalPol[market,year] = sum(xPolCap[ecc,poll,pcov,area,year] for area in areas, 
      pcov in pcovs, poll in polls, ecc in eccs)
  end

  WriteDisk(db,"SInput/xGoalPol",xGoalPol)

  #########################
  #
  # Emission Credits are energy (xPolCap)
  #
  for year in years, area in areas, pcov in pcovs, poll in polls, ecc in eccs
    xPGratis[ecc,poll,pcov,area,year] = xPolCap[ecc,poll,pcov,area,year]
  end

  WriteDisk(db,"SInput/xPGratis",xPGratis)

  #########################
  #
  # Unlimited Federal (TIF) Permits
  #
  for year in years
    ISaleSw[market,year] = 2
  end

  WriteDisk(db,"SInput/ISaleSw",ISaleSw)

  #########################
  # 
  # Backstop Prices in nominal CN$/tonne
  #
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  # ETADAP[market,Yr(2017)] =  0.00/xExchangeRateNation[CN,Yr(2017)]/xInflationNation[US,Yr(2017)]
  # ETADAP[market,Yr(2018)] =  0.00/xExchangeRateNation[CN,Yr(2018)]/xInflationNation[US,Yr(2018)]
  # ETADAP[market,Yr(2019)] = 20.00/xExchangeRateNation[CN,Yr(2019)]/xInflationNation[US,Yr(2019)]
  # ETADAP[market,Yr(2020)] = 30.00/xExchangeRateNation[CN,Yr(2020)]/xInflationNation[US,Yr(2020)]
  # ETADAP[market,Yr(2021)] = 40.00/xExchangeRateNation[CN,Yr(2021)]/xInflationNation[US,Yr(2021)]
  # ETADAP[market,Yr(2022)] = 50.00/xExchangeRateNation[CN,Yr(2022)]/xInflationNation[US,Yr(2022)]
  # ETADAP[market,Yr(2023)] = 65.00/xExchangeRateNation[CN,Yr(2023)]/xInflationNation[US,Yr(2023)]
  ETADAP[market,Yr(2024)] = 80.00/xExchangeRateNation[CN,Yr(2024)]/xInflationNation[US,Yr(2024)]
  ETADAP[market,Yr(2025)] = 95.00/xExchangeRateNation[CN,Yr(2025)]/xInflationNation[US,Yr(2025)]
  ETADAP[market,Yr(2026)] = 110.00/xExchangeRateNation[CN,Yr(2026)]/xInflationNation[US,Yr(2026)]
  ETADAP[market,Yr(2027)] = 125.00/xExchangeRateNation[CN,Yr(2027)]/xInflationNation[US,Yr(2027)]
  ETADAP[market,Yr(2028)] = 140.00/xExchangeRateNation[CN,Yr(2028)]/xInflationNation[US,Yr(2028)]
  ETADAP[market,Yr(2029)] = 155.00/xExchangeRateNation[CN,Yr(2029)]/xInflationNation[US,Yr(2029)]
  years = collect(Yr(2030):YrFinal)
  for year in years
    ETADAP[market,year] = 170.00/xExchangeRateNation[CN,year]/xInflationNation[US,year]
  end

  WriteDisk(db,"SInput/ETADAP",ETADAP)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  #
  # Minimum Permit Prices in nominal CN$/tonne
  #
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

  #
  # Maximum Permit Prices in nominal CN$/tonne
  #
  for year in years
    ETAMax[market,year] = 170.00/xExchangeRateNation[CN,year]/
      xInflationNation[US,year]
  end

  WriteDisk(db,"SInput/ETAMax",ETAMax)

  #
  # Exogenous market price (xETAPr) is set equal to the
  # unlimited backstop price (ETADAP)
  #
  for year in Years
    xETAPr[market,year] = ETADAP[market,year]
    ETAPr[market,year] = xETAPr[market,year]*xInflationNation[US,year]
  end

  WriteDisk(db,"SOutput/ETAPr",ETAPr)
  WriteDisk(db,"SInput/xETAPr",xETAPr)

  areas,eccs,pcovs,polls,years = 
    DefaultSets(data,AreaMarket,Current,ECCMarket,market,PCovMarket,PollMarket,YrFinal)

  for year in years, area in areas, poll in polls, ecc in eccs
    PCost[ecc,poll,area,year] = ETAPr[market,year]/PolConv[poll]/
      xInflationNation[US,year]*xExchangeRate[area,year]
  end

  WriteDisk(db,"SOutput/PCost",PCost) 
end

function PolicyControl(db)
  @info "CarbonTax_OBA_BC.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
