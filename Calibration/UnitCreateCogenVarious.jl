#
# UnitCreateCogenVarious.jl - Create Cogeneration Units - Jeff Amlin 04/13/23
#
using EnergyModel

module UnitCreateCogenVarious

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  Last=HisTime-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  UnitKey::SetArray = ReadDisk(db,"MainDB/UnitKey")  
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (YEARS)
  CgFlFrNew::VariableArray{4} = ReadDisk(db,"EGInput/CgFlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  CgORNew::VariableArray{5} = ReadDisk(db,"EGInput/CgORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  #
  CgUnCode::VariableArray{4} = ReadDisk(db,"EGInput/CgUnCode") # [Plant,ECC,Node,Area] Cogeneration Unit Number (Number)
  EAF::VariableArray{4} = ReadDisk(db,"EGInput/EAF") # [Plant,area,month,Year] Energy Avaliability Factor (MWh/MWh)
  EmitNew::VariableArray{2} = ReadDisk(db,"EGInput/EmitNew") # [Plant,Area] Do New Plants Emit Pollution? (1=Yes)
  ExchangeRateUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateUnit") # [Unit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  # F1New::Array{String} = ReadDisk(db,"EGInput/F1New") # [Plant,Area] Fuel Type 1
  GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
  HRtM::VariableArray{3} = ReadDisk(db,"EGInput/HRtM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  InflationUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationUnit") # [Unit,Year] Inflation Index ($/$)
  MEPOCX::VariableArray{4} = ReadDisk(db,"EGInput/MEPOCX") # [Plant,Poll,Area,Year] Process Emission Coefficients (Tonnes/GWh)
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  SensitivityNew::VariableArray{3} = ReadDisk(db,"EGInput/SensitivityNew") # [Plant,Area,Year] Outage Rate Sensitivity to Decline in Driver for New Cogeneration Units (Driver/Driver)
  SqFr::VariableArray{4} = ReadDisk(db,"EGInput/SqFr") # [Plant,Poll,Area,Year] Sequestered Pollution Fraction (Tonne/Tonne)
  UFOMC::VariableArray{3} = ReadDisk(db,"EGInput/UFOMC") # [Plant,Area,Year] Unit Fixed O&M Costs ($/KW)
  UOMC::VariableArray{3} = ReadDisk(db,"EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs ($/MWh)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  # UnCounter::VariableArray{1} = [ReadDisk(db, "EGInput/UnCounter", year)] #[Year]  Number of Units
  UnCounter::VariableArray{1} = ReadDisk(db, "EGInput/UnCounter") #[Year]  Number of Units
  # UnCntYr::VariableArray{1} = ReadDisk(db,"EGInput/UnCntYr") # [Year] Number of Units
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Avaliability Factor (MWh/MWh)
  UnEffStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnEffStorage") # [Unit] Storage Efficiency (GWH/GWH)
  UnEmit::VariableArray{1} = ReadDisk(db,"EGInput/UnEmit") # [Unit] Does this Unit Emit Pollution (1=Yes)
  UnFacility::Array{String} = ReadDisk(db,"EGInput/UnFacility") # [Unit] Facility Name
  UnF1::Array{String} = ReadDisk(db,"EGInput/UnF1") # [Unit] Fuel Source 1
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnMECX::VariableArray{3} = ReadDisk(db,"EGInput/UnMECX") # [Unit,Poll,Year] Process Pollution Coefficient (Tonnes/GWh)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
  UnName::Array{String} = ReadDisk(db,"EGInput/UnName") # [Unit] Plant Name
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnOwner::Array{String} = ReadDisk(db,"EGInput/UnOwner") # [Unit] Generating Company
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  UnPSoMaxGridFraction::VariableArray{2} = ReadDisk(db,"EGInput/UnPSoMaxGridFraction") # [Unit,Year] Maxiumum Fraction Sold to Grid
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Sector
  UnSensitivity::VariableArray{2} = ReadDisk(db,"EGInput/UnSensitivity") # [Unit,Year] Outage Rate Sensitivity to Decline in Driver (Driver/Driver)
  UnSource::VariableArray{1} = ReadDisk(db,"EGInput/UnSource") # [Unit] Source (1=Endogenous, 0=Exogenous)
  UnSqFr::VariableArray{3} = ReadDisk(db,"EGInput/UnSqFr") # [Unit,Poll,Year] Sequestered Pollution Fraction (Tonnes/Tonnes) 
  UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") # [Unit] Storage Switch (1=Storage Unit)
  UnUFOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUFOMC") # [Unit,Year] Fixed O&M Costs (Real $/KW/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable O&M Costs (Real $/MWH)
  UnZeroFr::VariableArray{4} = ReadDisk(db,"EGInput/UnZeroFr") # [Unit,FuelEP,Poll,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes) 
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateUnit::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateUnit") # [Unit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationUnit::VariableArray{2} = ReadDisk(db,"MInput/xInflationUnit") # [Unit,Year] Inflation Index ($/$)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  xUnGCCC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/KW)
  ZeroFr::VariableArray{4} = ReadDisk(db,"SInput/ZeroFr") # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes) 

  # Scratch Variables
  CogenUnitExist::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # [ECC,Area] Identify all existing cogeneration units not retired (1=Exist)
  PlantKeyShort::VariableArray{1} = zeros(Float32,length(Plant)) # [Plant] Plant Key
end

function GetPrimaryFuel(data,area,plant)
  (; Area,Fuel,Plant) = data
  
  fuel = Select(Fuel,"NaturalGas")

  if (Plant[plant] == "OGCC") || (Plant[plant] == "OGCT") || (Plant[plant] == "SmallOGCC") || (Plant[plant] == "NGCCS")
    if (Area[area] == "NL") || (Area[area] == "NL")
      fuel = Select(Fuel,"Diesel")
    else
      fuel = Select(Fuel,"NaturalGas")
    end
  elseif (Plant[plant] == "OGSteam")
    fuel = Select(Fuel,"HFO")
  elseif (Plant[plant] == "Coal") || (Plant[plant] == "CoalCCS")
    fuel = Select(Fuel,"Coal")
  elseif (Plant[plant] == "OtherGeneration")
    fuel = Select(Fuel,"NaturalGas")
  elseif (Plant[plant] == "FuelCell")
    fuel = Select(Fuel,"Hydrogen")
  elseif (Plant[plant] == "Nuclear")
    fuel = Select(Fuel,"Nuclear")
  elseif (Plant[plant] == "BaseHydro") || (Plant[plant] == "PeakHydro") || (Plant[plant] == "SmallHydro")
    fuel = Select(Fuel,"Hydro")
  elseif (Plant[plant] == "Biomass") || (Plant[plant] == "BiomassCCS")
    fuel = Select(Fuel,"Biomass")
  elseif (Plant[plant] == "Biogas") || (Plant[plant] == "Waste")
    fuel = Select(Fuel,"Waste")
  elseif (Plant[plant] == "OnshoreWind") || (Plant[plant] == "OffshoreWind")
    fuel = Select(Fuel,"Wind")
  elseif (Plant[plant] == "SolarPV") || (Plant[plant] == "SolarThermal")
    fuel = Select(Fuel,"Solar")
  elseif (Plant[plant] == "Geothermal")
    fuel = Select(Fuel,"Geothermal")
  elseif (Plant[plant] == "Wave") || (Plant[plant] == "Tidal")
    fuel = Select(Fuel,"Wave")
  end

  return fuel
end


function CommonCharacteristics(data,area,node,ecc,plant)
  (;Area,ECC,Fuel,FuelEPs,Months,Nation,Nations,Node,Plant,Polls,TimePs,Years) = data
  (;ANMap,CgFlFrNew,CgORNew,EAF,EmitNew,xExchangeRate,ExchangeRateUnit,xExchangeRateUnit) = data
  (;GCCCN,HRtM,MEPOCX,POCX,SensitivityNew,SqFr,UFOMC,UOMC,UnArea) = data
  (;UnCogen,UnEAF,UnEmit,UnFacility,UnF1,xUnFlFr,UnGenCo) = data
  (;UnHRt,UnMECX,UnMustRun,UnNation,UnNode,UnOnLine,UnOR,UnOwner,UnPlant) = data
  (;UnPOCX,UnRetire,UnSector,UnSource,UnSensitivity,UnSqFr,UnUFOMC,UnUOMC) = data
  (;UnZeroFr,xInflation,InflationUnit,xInflationUnit,xUnGCCC,ZeroFr,UnCounter) = data

  #
  # Assign labels to Unit
  # 
  nation = Select(ANMap[area,Nations],==(1))[1]
  UnNation[Int(UnCounter[Yr(1985)])] = Nation[nation]
  UnOwner[Int(UnCounter[Yr(1985)])] = Area[area]*ECC[ecc]
  UnGenCo[Int(UnCounter[Yr(1985)])] = Area[area]
  UnPlant[Int(UnCounter[Yr(1985)])] = Plant[plant]
  UnNode[Int(UnCounter[Yr(1985)])] = Node[node]
  UnArea[Int(UnCounter[Yr(1985)])] = Area[area]
  UnSector[Int(UnCounter[Yr(1985)])] = ECC[ecc]
  UnFacility[Int(UnCounter[Yr(1985)])] = Area[area]*ECC[ecc]
  UnSource[Int(UnCounter[Yr(1985)])] = 1

  # 
  # Inflation and Exchange Rate
  # 
  for year in Years
    xExchangeRateUnit[Int(UnCounter[Yr(1985)]),year] = xExchangeRate[area,year]
    xInflationUnit[Int(UnCounter[Yr(1985)]),year] = xInflation[area,year]
    ExchangeRateUnit[Int(UnCounter[Yr(1985)]),year] = xExchangeRateUnit[Int(UnCounter[Yr(1985)]),year]
    InflationUnit[Int(UnCounter[Yr(1985)]),year] = xInflationUnit[Int(UnCounter[Yr(1985)]),year]
  end

  for year in Yr(1986):Final

    # 
    # Unit Heat Rate (UnHRt) is the Marginal Plant Heat Rate (HRtM)
    # 
    UnHRt[Int(UnCounter[Yr(1985)]),year] = HRtM[plant,area,year]
    UnUOMC[Int(UnCounter[Yr(1985)]),year] = UOMC[plant,area,year]
    UnUFOMC[Int(UnCounter[Yr(1985)]),year] = UFOMC[plant,area,year]
    xUnGCCC[Int(UnCounter[Yr(1985)]),year] = GCCCN[plant,area,year]
    for month in Months
      UnEAF[Int(UnCounter[Yr(1985)]),month,year] = EAF[plant,area,month,year]
    end

    # 
    # Unit Sensitivity to Decline in Driver
    #
    UnSensitivity[Int(UnCounter[Yr(1985)]),year] = SensitivityNew[plant,area,year]
    
    #
    # Fuel Type
    #
    # UnF1[Int(UnCounter[Yr(1985)])] = F1New - Note:F1New broken
    fuel = GetPrimaryFuel(data,area,plant)
    UnF1[Int(UnCounter[Yr(1985)])] = Fuel[fuel]
    for fuelep in FuelEPs
      xUnFlFr[Int(UnCounter[Yr(1985)]),fuelep,year] = CgFlFrNew[fuelep,plant,area,year]
    end
    for month in Months, timep in TimePs
      UnOR[Int(UnCounter[Yr(1985)]),timep,month,year] = CgORNew[plant,area,timep,month,year]
    end
    UnMustRun[Int(UnCounter[Yr(1985)])] = 1
    UnCogen[Int(UnCounter[Yr(1985)])]= 1

    if UnPlant[Int(UnCounter[Yr(1985)])] == "Battery"
      UnStorage[Int(UnCounter[Yr(1985)])]=1
      UnEffStorage[Int(UnCounter[Yr(1985)])]=0.86
    end

    # 
    # Pollution Coefficients
    # 
    for poll in Polls
      for fuelep in FuelEPs
        UnPOCX[Int(UnCounter[Yr(1985)]),fuelep,poll,year] = POCX[fuelep,plant,poll,area,year]
        UnZeroFr[Int(UnCounter[Yr(1985)]),fuelep,poll,year] = ZeroFr[fuelep,poll,area,year]
      end
      UnMECX[Int(UnCounter[Yr(1985)]),poll,year] = MEPOCX[plant,poll,area,year]
      UnSqFr[Int(UnCounter[Yr(1985)]),poll,year] = SqFr[plant,poll,area,year]
    end
    UnEmit[Int(UnCounter[Yr(1985)])] = EmitNew[plant,area]

    # 
    # Unit On-line and Retirement Dates
    # 
    UnOnLine[Int(UnCounter[Yr(1985)])] = HisTime
    UnRetire[Int(UnCounter[Yr(1985)]),year] = 2200
  end
  
end

function CreateUnCode(data,area,node,ecc,plant)
  (;Area,Plant,ECC) = data
  (;CgUnCode) = data
  (;UnCode,UnitKey,UnName,UnCounter) = data

  UnCounter[Yr(1985)] = UnCounter[Yr(1985)]+1
  
  UnCode[Int(UnCounter[Yr(1985)])] = Area[area]*"_Cg_"*ECC[ecc]*"_"*Plant[plant]
  UnName[Int(UnCounter[Yr(1985)])] = Area[area]*" Cg "*first(ECC[ecc],18)*" "*Plant[plant]
  UnitKey[Int(UnCounter[Yr(1985)])] = UnCode[Int(UnCounter[Yr(1985)])]

  CgUnCode[plant,ecc,node,area] = Float32(UnCounter[Yr(1985)])
  
end

function CreateCogenUnit(data,area,node,ecc,plant)

  CreateUnCode(data,area,node,ecc,plant)
  CommonCharacteristics(data,area,node,ecc,plant)

end

function CogenUnitCreate(data)
  (;Area,ECC) = data
  (;Node,Plant) = data

  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"CSSOilSands"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Education"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Education"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Fertilizer"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Food"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Health"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"IndustrialGas"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Lumber"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Lumber"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"NonMetalMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Offices"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Offices"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Offices"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OilSandsMining"),Select(Plant,"Coal"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OilSandsMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OilSandsMining"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OilSandsUpgraders"),Select(Plant,"Coal"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OilSandsUpgraders"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OilSandsUpgraders"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OtherChemicals"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"OtherNonferrous"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Petrochemicals"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Petroleum"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"SAGDOilSands"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"SAGDOilSands"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"SourGasProcessing"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"SweetGasProcessing"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"AB"),Select(Node,"AB"),Select(ECC,"Wastewater"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Aluminum"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Aluminum"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Education"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Food"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Lumber"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Lumber"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Offices"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Offices"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"Offices"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"OtherMetalMining"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"OtherMetalMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"OtherMetalMining"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"OtherNonferrous"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"OtherNonferrous"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"PulpPaperMills"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"PulpPaperMills"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"SourGasProcessing"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"BC"),Select(Node,"BC"),Select(ECC,"SweetGasProcessing"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"Cement"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"Forestry"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"IronSteel"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"OtherChemicals"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"OtherMetalMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"OtherNonferrous"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"MB"),Select(Node,"MB"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"Food"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"Offices"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"Offices"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"Offices"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"Offices"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"Petroleum"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"Petroleum"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"PulpPaperMills"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NB"),Select(Node,"NB"),Select(ECC,"PulpPaperMills"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"LB"),Select(ECC,"OtherMetalMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"LB"),Select(ECC,"OtherMetalMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"LB"),Select(ECC,"OtherNonferrous"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"FrontierOilMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"FrontierOilMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"LB"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"HeavyOilMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"HeavyOilMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"IronOreMining"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"IronOreMining"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"Petroleum"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"PulpPaperMills"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"NL"),Select(ECC,"PulpPaperMills"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NL"),Select(Node,"LB"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))  
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"Lumber"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"Offices"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"PulpPaperMills"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"PulpPaperMills"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NS"),Select(Node,"NS"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"FrontierOilMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"NonMetalMining"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"NonMetalMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"NonMetalMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"NonMetalMining"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"Petroleum"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NT"),Select(Node,"NT"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))  
  CreateCogenUnit(data,Select(Area,"NU"),Select(Node,"NU"),Select(ECC,"OtherMetalMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"NU"),Select(Node,"NU"),Select(ECC,"OtherMetalMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"NU"),Select(Node,"NU"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"NU"),Select(Node,"NU"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))  
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Education"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Education"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Education"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Education"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Fertilizer"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Food"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Food"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Forestry"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Health"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Incineration"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"IndustrialGas"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"IronSteel"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Lumber"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Lumber"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Lumber"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Offices"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Offices"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Offices"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Offices"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OnFarmFuelUse"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherChemicals"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherChemicals"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherCommercial"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherCommercial"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherMetalMining"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherMetalMining"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherNonferrous"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherNonferrous"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherNonferrous"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"OtherNonferrous"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Petrochemicals"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Petroleum"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Petroleum"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"PulpPaperMills"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"PulpPaperMills"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"SolidWaste"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"TransportEquipment"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"ON"),Select(Node,"ON"),Select(ECC,"Wholesale"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"Offices"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"Offices"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"OtherCommercial"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"OtherCommercial"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"OtherCommercial"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"PE"),Select(Node,"PE"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Aluminum"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Aluminum"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"CropProduction"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"IronOreMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"IronOreMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"IronSteel"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"IronSteel"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Lumber"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Lumber"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Offices"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Offices"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Offices"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Offices"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"OtherChemicals"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"OtherCommercial"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"OtherCommercial"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"OtherMetalMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"OtherNonferrous"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"OtherNonferrous"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"PulpPaperMills"),Select(Plant,"BaseHydro"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"PulpPaperMills"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Textiles"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"QC"),Select(Node,"QC"),Select(ECC,"Textiles"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"BiofuelProduction"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"Forestry"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"Health"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"NonMetalMining"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"NonMetalMining"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"Offices"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"OilSandsUpgraders"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"OtherCommercial"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"OtherManufacturing"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"PulpPaperMills"),Select(Plant,"Biomass"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"PulpPaperMills"),Select(Plant,"BiomassCCS"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGCC"))
  CreateCogenUnit(data,Select(Area,"SK"),Select(Node,"SK"),Select(ECC,"PulpPaperMills"),Select(Plant,"OGSteam"))
  CreateCogenUnit(data,Select(Area,"YT"),Select(Node,"YT"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"YT"),Select(Node,"YT"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))
  CreateCogenUnit(data,Select(Area,"MX"),Select(Node,"MX"),Select(ECC,"H2Production"),Select(Plant,"OnshoreWind"))
  CreateCogenUnit(data,Select(Area,"MX"),Select(Node,"MX"),Select(ECC,"H2Production"),Select(Plant,"SolarPV"))

end

function CreateUnits(db)
  data = ECalib(; db)
  (;Units,Years) = data
  (;CgUnCode) = data
  (;ExchangeRateUnit,xExchangeRateUnit,UnArea) = data
  (;UnCode,UnCogen,UnCounter,UnEAF,UnEffStorage,UnEmit,UnFacility,UnF1,xUnFlFr,UnGenCo) = data
  (;UnHRt,UnitKey,UnMECX,UnMustRun,UnName,UnNation,UnNode,UnOnLine,UnOR,UnOwner,UnPlant) = data
  (;UnPOCX,UnRetire,UnPSoMaxGridFraction,UnSector,UnSource,UnSqFr,UnStorage,UnUFOMC,UnUOMC) = data
  (;UnZeroFr,InflationUnit,xInflationUnit,xUnGCCC) = data

  CogenUnitCreate(data)
  for year in Years, unit in Units
    UnPSoMaxGridFraction[unit,year] = 1
  end
  
  for year in Years
    UnCounter[year] = UnCounter[Yr(1985)]
  end

  WriteDisk(db,"EGInput/CgUnCode",CgUnCode)

  WriteDisk(db,"EGInput/UnArea",UnArea)
  WriteDisk(db,"EGInput/UnCode",UnCode)
  WriteDisk(db,"EGInput/UnCogen",UnCogen)
  WriteDisk(db,"EGInput/UnCounter",UnCounter)
  WriteDisk(db,"EGInput/UnEAF",UnEAF)
  WriteDisk(db,"EGInput/UnEmit",UnEmit)
  WriteDisk(db,"EGInput/UnFacility",UnFacility)
  WriteDisk(db,"EGInput/UnF1",UnF1)
  WriteDisk(db,"EGInput/xUnFlFr",xUnFlFr)

  WriteDisk(db,"MOutput/ExchangeRateUnit",ExchangeRateUnit)
  WriteDisk(db,"MInput/xExchangeRateUnit",xExchangeRateUnit)
  WriteDisk(db,"MOutput/InflationUnit",InflationUnit)
  WriteDisk(db,"MInput/xInflationUnit",xInflationUnit)
  
  WriteDisk(db,"EGInput/UnGenCo",UnGenCo)
  WriteDisk(db,"EGInput/UnHRt",UnHRt)
  WriteDisk(db,"MainDB/UnitKey",UnitKey)    
  WriteDisk(db,"EGInput/UnMECX",UnMECX)
  WriteDisk(db,"EGInput/UnMustRun",UnMustRun)
  WriteDisk(db,"EGInput/UnName",UnName)
  WriteDisk(db,"EGInput/UnNation",UnNation)
  WriteDisk(db,"EGInput/UnNode",UnNode)
  WriteDisk(db,"EGInput/xUnGCCC",xUnGCCC)

  WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGInput/UnOwner",UnOwner)
  WriteDisk(db,"EGInput/UnPlant",UnPlant)
  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
  WriteDisk(db,"EGInput/UnPSoMaxGridFraction",UnPSoMaxGridFraction)
  
  WriteDisk(db,"EGInput/UnRetire",UnRetire)
  WriteDisk(db,"EGInput/UnSector",UnSector)
  WriteDisk(db,"EGInput/UnSource",UnSource)
  WriteDisk(db,"EGInput/UnSqFr",UnSqFr)
  WriteDisk(db,"EGInput/UnUFOMC",UnUFOMC)
  WriteDisk(db,"EGInput/UnUOMC",UnUOMC)
  
  WriteDisk(db,"EGInput/UnEffStorage",UnEffStorage)
  WriteDisk(db,"EGInput/UnStorage",UnStorage)
  WriteDisk(db,"EGInput/UnZeroFr",UnZeroFr)

end

function Control(db)
  @info "UnitCreateCogenVarious.jl - Control"
  CreateUnits(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
