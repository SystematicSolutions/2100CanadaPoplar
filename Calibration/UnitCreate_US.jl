#
# UnitCreate_US.jl
#
using EnergyModel

module UnitCreate_US

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
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
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

  EAF::VariableArray{4} = ReadDisk(db,"EGInput/EAF") # [Plant,Area,Month,Year] Energy Avaliability Factor (MWh/MWh)
  EmitNew::VariableArray{2} = ReadDisk(db,"EGInput/EmitNew") # [Plant,Area] Do New Plants Emit Pollution? (1=Yes)
  ExchangeRateUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateUnit") # [Unit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  # F1New::VariableArray{2} = ReadDisk(db,"EGInput/F1New") # [Plant,Area] Fuel Type 1
  FlFrNew::VariableArray{4} = ReadDisk(db,"EGInput/FlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
  HRtM::VariableArray{3} = ReadDisk(db,"EGInput/HRtM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  InflationUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationUnit") # [Unit,Year] Inflation Index ($/$)
  MEPOCX::VariableArray{4} = ReadDisk(db,"EGInput/MEPOCX") # [Plant,Poll,Area,Year] Process Emission Coefficients (Tonnes/GWh)
  ORNew::VariableArray{5} = ReadDisk(db,"EGInput/ORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  OUREG::VariableArray{3} = ReadDisk(db,"EGInput/OUREG") # [Plant,Area,Year] Own Use Rate for Generation (GWh/GWh)
  OURGC::VariableArray{3} = ReadDisk(db,"EGInput/OURGC") # [Plant,Area,Year] Own Use Rate for Generating Capacity (MW/MW)
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  SqFr::VariableArray{4} = ReadDisk(db,"EGInput/SqFr") # [Plant,Poll,Area,Year] Sequestered Pollution Fraction (Tonne/Tonne)
  UFOMC::VariableArray{3} = ReadDisk(db,"EGInput/UFOMC") # [Plant,Area,Year] Unit Fixed O&M Costs ($/KW)
  UOMC::VariableArray{3} = ReadDisk(db,"EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs ($/MWh)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") # [Year] Number of Units
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
  UnOUREG::VariableArray{2} = ReadDisk(db,"EGInput/UnOUREG") # [Unit,Year] Own Use Rate for Generation (GWh/GWh)
  UnOURGC::VariableArray{2} = ReadDisk(db,"EGInput/UnOURGC") # [Unit,Year] Own Use Rate for Generating Capacity (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  UnSector::Array{String} = ReadDisk(db,"EGInput/UnSector") # [Unit] Unit Sector
  UnSource::VariableArray{1} = ReadDisk(db,"EGInput/UnSource") # [Unit] Source (1=Endogenous, 0=Exogenous)
  UnSqFr::VariableArray{3} = ReadDisk(db,"EGInput/UnSqFr") # [Unit,Poll,Year] Sequestered Pollution Fraction (Tonnes/Tonnes)
  UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") # [Unit] Storage Switch (1=Storage Unit)
  UnUFOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUFOMC") # [Unit,Year] Fixed O&M Costs (Real $/KW/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable O&M Costs (Real $/MWH)
  UnZeroFr::VariableArray{4} = ReadDisk(db,"EGInput/UnZeroFr") # [Unit,FuelEP,Poll,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
  xExchangeRateUnit::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateUnit") # [Unit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationUnit::VariableArray{2} = ReadDisk(db,"MInput/xInflationUnit") # [Unit,Year] Inflation Index ($/$)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  xUnGCCC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/KW)
  ZeroFr::VariableArray{4} = ReadDisk(db,"SInput/ZeroFr") # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)

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

function CommonCharacteristics(data,unit,plant,genco,node,area,nation)
  (;Area,Fuel,FuelEPs,GenCo,GenCoDS) = data
  (;Months,Nation,Node,Plant,Polls,TimePs,Years) = data
  (;EAF,EmitNew,xExchangeRate,ExchangeRateUnit,xExchangeRateUnit,FlFrNew,GCCCN,HRtM,MEPOCX) = data
  (;ORNew,OUREG,OURGC,POCX,SqFr,UFOMC,UOMC,UnArea) = data
  (;UnCode,UnCogen,UnEAF,UnEffStorage,UnEmit,UnFacility,UnF1,xUnFlFr,UnGenCo) = data
  (;UnHRt,UnitKey,UnMECX,UnMustRun,UnNation,UnNode,UnOnLine,UnOR,UnOwner,UnOUREG) = data
  (;UnOURGC,UnPlant,UnPOCX,UnRetire,UnSector,UnSource,UnSqFr,UnStorage,UnUFOMC,UnUOMC) = data
  (;UnZeroFr,xInflation,InflationUnit,xInflationUnit,xUnGCCC,ZeroFr) = data

  #
  # Assign labels to Unit
  #
  UnitKey[unit]    = UnCode[unit]
  UnOwner[unit]    = GenCoDS[genco]
  UnGenCo[unit]    = GenCo[genco]
  UnPlant[unit]    = Plant[plant]
  UnNode[unit]     = Node[node]
  UnArea[unit]     = Area[area]
  UnNation[unit]   = Nation[nation]
  UnSector[unit]   = "UtilityGen"
  UnFacility[unit] = "Exogenous Build "*Area[area]
  UnSource[unit]   = 1

  for year in Years
    xExchangeRateUnit[unit,year] = xExchangeRate[area,year]
    xInflationUnit[unit,year] = xInflation[area,year]
    ExchangeRateUnit[unit,year] = xExchangeRateUnit[unit,year]
    InflationUnit[unit,year] = xInflationUnit[unit,year]
  end
  
  years=collect(Yr(1986):Final)
  
  #
  # Unit Heat Rate (UnHRt) is the Marginal Plant Heat Rate (HRtM)
  #
  for year in years
    UnHRt[unit,year] = HRtM[plant,area,year]
    UnUOMC[unit,year] = UOMC[plant,area,year]
    UnUFOMC[unit,year] = UFOMC[plant,area,year]
    xUnGCCC[unit,year] = GCCCN[plant,area,year]
  end
  
  for year in years, month in Months
    UnEAF[unit,month,year] = EAF[plant,area,month,year]
  end
  
  #
  # Fuel Type
  #
  # UnF1[unit] = F1New[plant,area] - Julia cannot have two-dimensional strings  
  fuel = GetPrimaryFuel(data,area,plant)
  UnF1[unit]=Fuel[fuel]
  for year in years, fuelep in FuelEPs
      xUnFlFr[unit,fuelep,year] = FlFrNew[fuelep,plant,area,year]
  end
  
  for year in years, month in Months, timep in TimePs
    UnOR[unit,timep,month,year] = ORNew[plant,area,timep,month,year]
  end
  for year in years
    UnOUREG[unit,year] = OUREG[plant,area,year]
    UnOURGC[unit,year] = OURGC[plant,area,year]
  end
  UnCogen[unit] = 0
  
  if UnPlant[unit] == "Battery"
    UnStorage[unit] = 1
    UnEffStorage[unit] = 0.86
  end

  UnMustRun[unit] = 0
  if in(UnPlant[unit], ["Geothermal","Biomass"])
    UnMustRun[unit] = 1
  end

  #
  # Pollution Coefficients
  #
  for year in years, poll in Polls, fuelep in FuelEPs
     UnPOCX[unit,fuelep,poll,year] = POCX[fuelep,plant,poll,area,year]
  end
  for year in years, poll in Polls
    UnMECX[unit,poll,year] = MEPOCX[plant,poll,area,year]
  end
  UnEmit[unit] = EmitNew[plant,area]
  for year in years, poll in Polls
    UnSqFr[unit,poll,year] = SqFr[plant,poll,area,year]
  end
  for year in years, poll in Polls, fuelep in FuelEPs
    UnZeroFr[unit,fuelep,poll,year] = ZeroFr[fuelep,poll,area,year]
  end

  #
  # Unit On-line and Retirement Dates
  #
  UnOnLine[unit] = 2200
  for year in years
    UnRetire[unit,year]=2200
  end

end

function UnitWriteDisk(data)
  (; db) = data
  (;ExchangeRateUnit,xExchangeRateUnit) = data
  (;UnArea,UnCode) = data
  (;UnCogen,UnCounter,UnEAF,UnEffStorage,UnEmit,UnFacility,UnF1,xUnFlFr,UnGenCo) = data
  (;UnHRt,UnitKey,UnMECX,UnMustRun,UnName,UnNation,UnNode,UnOnLine,UnOR,UnOwner,UnOUREG) = data
  (;UnOURGC,UnPlant,UnPOCX,UnRetire,UnSector,UnSource,UnSqFr,UnStorage,UnUFOMC,UnUOMC) = data
  (;UnZeroFr,InflationUnit,xInflationUnit,xUnGCCC) = data

  WriteDisk(db,"MOutput/ExchangeRateUnit",ExchangeRateUnit)
  WriteDisk(db,"MOutput/InflationUnit",InflationUnit)
  WriteDisk(db,"EGInput/UnArea",UnArea)
  WriteDisk(db,"EGInput/UnCode",UnCode)
  WriteDisk(db,"EGInput/UnCogen",UnCogen)
  WriteDisk(db,"EGInput/UnCounter",UnCounter)
  WriteDisk(db,"EGInput/UnEAF",UnEAF)
  WriteDisk(db,"EGInput/UnEffStorage",UnEffStorage)
  WriteDisk(db,"EGInput/UnEmit",UnEmit)
  WriteDisk(db,"EGInput/UnF1",UnF1)
  WriteDisk(db,"EGInput/UnFacility",UnFacility)
  WriteDisk(db,"EGInput/UnGenCo",UnGenCo)
  WriteDisk(db,"EGInput/UnHRt",UnHRt)
  WriteDisk(db,"MainDB/UnitKey",UnitKey)  
  WriteDisk(db,"EGInput/UnMECX",UnMECX)
  WriteDisk(db,"EGInput/UnMustRun",UnMustRun)
  WriteDisk(db,"EGInput/UnName",UnName)
  WriteDisk(db,"EGInput/UnNation",UnNation)
  WriteDisk(db,"EGInput/UnNode",UnNode)
  WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGInput/UnOUREG",UnOUREG)
  WriteDisk(db,"EGInput/UnOURGC",UnOURGC)
  WriteDisk(db,"EGInput/UnOwner",UnOwner)
  WriteDisk(db,"EGInput/UnPlant",UnPlant)
  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
  WriteDisk(db,"EGInput/UnRetire",UnRetire)
  WriteDisk(db,"EGInput/UnSector",UnSector)
  WriteDisk(db,"EGInput/UnSource",UnSource)
  WriteDisk(db,"EGInput/UnSqFr",UnSqFr)
  WriteDisk(db,"EGInput/UnStorage",UnStorage)
  WriteDisk(db,"EGInput/UnUFOMC",UnUFOMC)
  WriteDisk(db,"EGInput/UnUOMC",UnUOMC)
  WriteDisk(db,"EGInput/UnZeroFr",UnZeroFr)
  WriteDisk(db,"MInput/xExchangeRateUnit",xExchangeRateUnit)
  WriteDisk(db,"MInput/xInflationUnit",xInflationUnit)
  WriteDisk(db,"EGInput/xUnFlFr",xUnFlFr)
  WriteDisk(db,"EGInput/xUnGCCC",xUnGCCC)

end

function CreateUnits(db)
  data = EControl(; db)
  (;Area,GenCo) = data
  (;Nation,Node,Plant) = data
  (;UnCode) = data
  (;UnCounter) = data
  (;UnName) = data

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  MX = Select(Nation,"MX")

  OGCT            = Select(Plant,"OGCT")
  OGCC            = Select(Plant,"OGCC")
  SmallOGCC       = Select(Plant,"SmallOGCC")
  NGCCS           = Select(Plant,"NGCCS")
  OGSteam         = Select(Plant,"OGSteam")
  Coal            = Select(Plant,"Coal")
  CoalCCS         = Select(Plant,"CoalCCS")
  OtherGeneration = Select(Plant,"OtherGeneration")
  FuelCell        = Select(Plant,"FuelCell")
  Battery         = Select(Plant,"Battery")
  Nuclear         = Select(Plant,"Nuclear")
  BaseHydro       = Select(Plant,"BaseHydro")
  PeakHydro       = Select(Plant,"PeakHydro")
  PumpedHydro     = Select(Plant,"PumpedHydro")
  SmallHydro      = Select(Plant,"SmallHydro")
  Biomass         = Select(Plant,"Biomass")
  BiomassCCS      = Select(Plant,"BiomassCCS")  
  Biogas          = Select(Plant,"Biogas")
  Waste           = Select(Plant,"Waste")
  OnshoreWind     = Select(Plant,"OnshoreWind")
  OffshoreWind    = Select(Plant,"OffshoreWind")
  SolarPV         = Select(Plant,"SolarPV")
  SolarThermal    = Select(Plant,"SolarThermal")
  Geothermal      = Select(Plant,"Geothermal")
  Wave            = Select(Plant,"Wave")
  Tidal           = Select(Plant,"Tidal")
  # Unknown         = Select(Plant,"Unknown")

  # UnitReadDisk

  #
  # Initialize UnCounter
  #
  uncounter = Int(UnCounter[Yr(1985)])

  #
  ########################
  #
  # SRSG_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"Mtn")
  node=Select(Node,"SRSG")
  area=Select(Area,"Mtn")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SRSG_Waste"
  UnName[uncounter]="SRSG_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # TRE_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"WSC")
  node=Select(Node,"TRE")
  area=Select(Area,"WSC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="TRE_Waste"
  UnName[uncounter]="TRE_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # MISW_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"ENC")
  node=Select(Node,"MISW")
  area=Select(Area,"ENC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="MISW_Waste"
  UnName[uncounter]="MISW_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # MISW_Geothermal
  #
  plant=Select(Plant,"Geothermal")
  genco=Select(GenCo,"ENC")
  node=Select(Node,"MISW")
  area=Select(Area,"ENC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="MISW_Geothermal"
  UnName[uncounter]="MISW_Geothermal"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # SPPN_Geothermal
  #
  plant=Select(Plant,"Geothermal")
  genco=Select(GenCo,"WNC")
  node=Select(Node,"SPPN")
  area=Select(Area,"WNC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SPPN_Geothermal"
  UnName[uncounter]="SPPN_Geothermal"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # NYCW_OnshoreWind
  #
  plant=Select(Plant,"OnshoreWind")
  genco=Select(GenCo,"MAtl")
  node=Select(Node,"NYCW")
  area=Select(Area,"MAtl")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="NYCW_OnshoreWind"
  UnName[uncounter]="NYCW_OnshoreWind"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # NYCW_SolarPV
  #
  plant=Select(Plant,"SolarPV")
  genco=Select(GenCo,"MAtl")
  node=Select(Node,"NYCW")
  area=Select(Area,"MAtl")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="NYCW_SolarPV"
  UnName[uncounter]="NYCW_SolarPV"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # MISE_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"ENC")
  node=Select(Node,"MISE")
  area=Select(Area,"ENC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="MISE_Waste"
  UnName[uncounter]="MISE_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # PJMW_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"ENC")
  node=Select(Node,"PJMW")
  area=Select(Area,"ENC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="PJMW_Waste"
  UnName[uncounter]="PJMW_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # PJMW_OffshoreWind
  #
  plant=Select(Plant,"OffshoreWind")
  genco=Select(GenCo,"ENC")
  node=Select(Node,"PJMW")
  area=Select(Area,"ENC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="PJMW_OffshoreWind"
  UnName[uncounter]="PJMW_OffshoreWind"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # RMRG_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"ENC")
  node=Select(Node,"RMRG")
  area=Select(Area,"ENC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="RMRG_Waste"
  UnName[uncounter]="RMRG_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # SRCE_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"ESC")
  node=Select(Node,"SRCE")
  area=Select(Area,"ESC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SRCE_Waste"
  UnName[uncounter]="SRCE_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # MISS_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"WSC")
  node=Select(Node,"MISS")
  area=Select(Area,"WSC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="MISS_Waste"
  UnName[uncounter]="MISS_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # MISC_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"ENC")
  node=Select(Node,"MISC")
  area=Select(Area,"ENC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="MISC_Waste"
  UnName[uncounter]="MISC_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # SPPS_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"WSC")
  node=Select(Node,"SPPS")
  area=Select(Area,"WSC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SPPS_Waste"
  UnName[uncounter]="SPPS_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # SPPC_Waste
  #
  plant=Select(Plant,"Waste")
  genco=Select(GenCo,"WSC")
  node=Select(Node,"SPPC")
  area=Select(Area,"WSC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SPPC_Waste"
  UnName[uncounter]="SPPC_Waste"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # SRCA_OffshoreWind
  #
  plant=Select(Plant,"OffshoreWind")
  genco=Select(GenCo,"WSC")
  node=Select(Node,"SRCA")
  area=Select(Area,"WSC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SRCA_OffshoreWind"
  UnName[uncounter]="SRCA_OffshoreWind"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # SRSE_FuelCell
  #
  plant=Select(Plant,"FuelCell")
  genco=Select(GenCo,"SAtl")
  node=Select(Node,"SRSE")
  area=Select(Area,"SAtl")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SRSE_FuelCell"
  UnName[uncounter]="SRSE_FuelCell"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # SPPS_Battery
  #
  plant=Select(Plant,"Battery")
  genco=Select(GenCo,"WSC")
  node=Select(Node,"SPPS")
  area=Select(Area,"WSC")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="SPPS_Battery"
  UnName[uncounter]="SPPS_Battery"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # BASN_Battery
  #
  plant=Select(Plant,"Battery")
  genco=Select(GenCo,"Mtn")
  node=Select(Node,"BASN")
  area=Select(Area,"Mtn")
  nation=Select(Nation,"US")
  uncounter = uncounter+1
  UnCode[uncounter]="BASN_Battery"
  UnName[uncounter]="BASN_Battery"
  CommonCharacteristics(data,uncounter,plant,genco,node,area,nation)

  #
  # Move UnCounter
  #
  UnCounter[Yr(1985)] = uncounter
 
  years=collect(Yr(1985):Final)
  for year in years
    UnCounter[year] = UnCounter[Yr(1985)]
  end
 
  UnitWriteDisk(data)

end

function Control(db)
  @info "UnitCreate_US.jl - Control"
  CreateUnits(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
