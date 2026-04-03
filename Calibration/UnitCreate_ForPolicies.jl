#
# UnitCreate_ForPolicies.jl - these units are created so they can be
# activated in policy files - Jeff Amlin 01/24/20.
# Updated by Thomas Dandres (add CCS plants for CER simulations)
#
using EnergyModel

module UnitCreate_ForPolicies

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

  #
  # Own Use
  #
  for year in years
    UnOUREG[unit,year] = OUREG[plant,area,year]
    UnOURGC[unit,year] = OURGC[plant,area,year]
  end

  #
  # NGCCS own power use
  #
  if UnPlant[unit]=="NGCCS"
    for year in years
      UnOUREG[unit,year] = 0.171
      UnOURGC[unit,year] = 0.171
    end
  end  

  UnCogen[unit] = 0
  
  if UnPlant[unit] == "Battery"
    UnStorage[unit] = 1
    UnEffStorage[unit] = 0.86
  end

  UnMustRun[unit] = 0
  if in(UnPlant[unit], ["SolarPV","OnshoreWind","OffshoreWind","BaseHydro","SmallHydro","Wave"])
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
  (;Area,FuelEP,GenCo,Months) = data
  (;Nation,Node,Plant,Poll,Polls,TimePs) = data
  (;UnCode) = data
  (;UnCogen,UnCounter,UnMustRun,UnSector,UnSqFr,xUnFlFr) = data
  (;UnName,UnOR) = data

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  MX = Select(Nation,"MX")
  
  CO2 = Select(Poll, "CO2")

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
  # Temporarily modified to remove policy units not needed in order to address the 
  # issue of having too many units (above 3,000) in total. JSLandry; August 22, 2019
  # If a plant type is uncommented, UnOR value must correspond to those in "New Units - for Unit.xlsx"
  #  

  years = collect(Yr(1986):Final)

  #
  # ON New OGCC
  #
  area  = Select(Area,"ON")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "ON_New_OGCC"
  UnName[uncounter] = "ON New OGCC"
  CommonCharacteristics(data,uncounter,OGCC,genco,node,area,CN)
  fuelep = Select(FuelEP,"NaturalGas")
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.12
  end

  #
  # ON New Solar
  #
  area  = Select(Area,"ON")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounterer = uncounter+1
  UnCode[uncounter] = "ON_New_SolarPV"
  UnName[uncounter] = "ON  New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN) 
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.811
  end
  
  #
  # BC New Hydro
  #
  area  = Select(Area,"BC")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "BC_New_Hydro"
  UnName[uncounter] = "BC New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.565721907
  end

  #
  # BC New Solar
  #
  area  = Select(Area,"BC")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "BC_New_SolarPV"
  UnName[uncounter] = "BC New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.815
  end

  #
  # BC New Geothermal
  #
  area  = Select(Area,"BC")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "BC_New_Geo"
  UnName[uncounter] = "BC New Geothermal"
  CommonCharacteristics(data,uncounter,Geothermal,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.3
  end

  #
  # AB New Onshore Wind
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_New_OnshoreWind"
  UnName[uncounter] = "AB New Onshore Wind"
  CommonCharacteristics(data,uncounter,OnshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.563
  end
  
  #
  # AB New Solar
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_New_SolarPV"
  UnName[uncounter] = "AB New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.8
  end  

  #
  # AB New OGCC
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_New_CC"
  UnName[uncounter] = "AB New OGCC"
  CommonCharacteristics(data,uncounter,OGCC,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.12
  end
  fuelep = Select(FuelEP,"NaturalGas")
  for year in years
    xUnFlFr[uncounter,fuelep,year] = 1
  end    
  
  #
  # AB New Geothermal
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_New_Geo"
  UnName[uncounter] = "AB New Geothermal"
  CommonCharacteristics(data,uncounter,Geothermal,genco,node,area,CN)  
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.3
  end

  #
  # SK New Solar
  #
  area  = Select(Area,"SK")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "SK_New_SolarPV"
  UnName[uncounter] = "SK New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.796
  end

  #
  # SK New Geothermal
  #
  area  = Select(Area,"SK")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "SK_New_Geo"
  UnName[uncounter] = "SK New Geothermal"
  CommonCharacteristics(data,uncounter,Geothermal,genco,node,area,CN)  
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.3
  end

  #
  # MB New Hydro
  #
  area  = Select(Area,"MB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "MB_New_Hydro"
  UnName[uncounter] = "MB New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.272
  end

  #
  # MB New Solar
  #
  area  = Select(Area,"MB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "MB_New_SolarPV"
  UnName[uncounter] = "MB New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.804
  end

  #
  # NB New Solar
  #
  area  = Select(Area,"NB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NB_New_SolarPV"
  UnName[uncounter] = "NB New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)  
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.858
  end

  #
  # NB New Offshore Wind
  #
  area  = Select(Area,"NB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NB_New_OnshoreWind"
  UnName[uncounter] = "NB New Onshore Wind"
  CommonCharacteristics(data,uncounter,OnshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.601
  end

  #
  # NS New Offshore Wind
  #
  area  = Select(Area,"NS")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NS_New_OffshoreWind"
  UnName[uncounter] = "NS New Offshore Wind"
  CommonCharacteristics(data,uncounter,OffshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.601
  end

  #
  # NS New Wave
  #
  area  = Select(Area,"NS")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NS_New_Wave"
  UnName[uncounter] = "NS New Wave"
  CommonCharacteristics(data,uncounter,Wave,genco,node,area,CN)  
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.3
  end
  
  #
  # NS New Hydro
  #
  area  = Select(Area,"NS")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NS_New_Hydro"
  UnName[uncounter] = "NS New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.666
  end

  #
  # NS New Solar
  #
  area  = Select(Area,"NS")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NS_New_SolarPV"
  UnName[uncounter] = "NS New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)    
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.836
  end
  
  #
  # NL New Hydro
  #
  area  = Select(Area,"NL")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NL_New_Hydro"
  UnName[uncounter] = "NL New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.357
  end

  #
  # NL New Offshore Wind
  #
  area  = Select(Area,"NL")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NL_New_OffshoreWind"
  UnName[uncounter] = "NL New Offshore Wind"
  CommonCharacteristics(data,uncounter,OffshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.5
  end

  #
  # NL New Solar
  #
  area  = Select(Area,"NL")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NL_New_SolarPV"
  UnName[uncounter] = "NL New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)    
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.836
  end

  #
  # PE New Onshore Wind
  #
  area  = Select(Area,"PE")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "PE_New_OnshoreWind"
  UnName[uncounter] = "PE New Onshore Wind"
  CommonCharacteristics(data,uncounter,OnshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.563
  end

  #
  # QC New Hydro
  #
  area  = Select(Area,"QC")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "QC_New_Hydro"
  UnName[uncounter] = "QC New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.432582489
  end

  #
  # YT New Hydro
  #
  area  = Select(Area,"YT")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "YT_New_Hydro"
  UnName[uncounter] = "YT New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,CN) 
  
  #
  # YT New Onshore Wind
  #
  area  = Select(Area,"YT")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "YT_New_OnshoreWind"
  UnName[uncounter] = "YT New Onshore Wind"
  CommonCharacteristics(data,uncounter,OnshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.6
  end

  #
  # YT New Solar
  #
  area  = Select(Area,"YT")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "YT_New_SolarPV"
  UnName[uncounter] = "YT New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN)    
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.8
  end

  #
  # YT New Geothermal
  #
  area  = Select(Area,"YT")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "YT_New_Geo"
  UnName[uncounter] = "YT New Geothermal"
  CommonCharacteristics(data,uncounter,Geothermal,genco,node,area,CN)  
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.3
  end

  #
  # NT New Hydro
  # 
  area  = Select(Area,"NT")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NT_New_Hydro"
  UnName[uncounter] = "NT New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,CN)

  #
  # NT New Onshore Wind
  #
  area  = Select(Area,"NT")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NT_New_OnshoreWind"
  UnName[uncounter] = "NT New Onshore Wind"
  CommonCharacteristics(data,uncounter,OnshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.6
  end

  #
  # NT New Solar
  #
  area  = Select(Area,"NT")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NT_New_SolarPV"
  UnName[uncounter] = "NT New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN) 
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.8
  end

  #
  # NU New Onshore Wind
  #
  area  = Select(Area,"NU")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NU_New_OnshoreWind"
  UnName[uncounter] = "NU New Onshore Wind"
  CommonCharacteristics(data,uncounter,OnshoreWind,genco,node,area,CN)
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.6
  end
  
  #
  # NU New Solar
  #
  area  = Select(Area,"NU")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "NU_New_SolarPV"
  UnName[uncounter] = "NU New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,CN) 
  for year in years, month in Months, timep in TimePs
    UnOR[uncounter,timep,month,year] = 0.8
  end

  # 
  # Add NG CCS
  # 
  for area in Select(Area,["ON","AB","SK","NB","NS"])
    genco = Select(GenCo,Area[area])
    node = Select(Node,Area[area])
    uncounter = uncounter+1
    UnCode[uncounter] = Area[area]*"_New_NGCCS"
    UnName[uncounter] = Area[area]*" New NG CCS"   
    CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
    for year in years, month in Months, timep in TimePs
      UnOR[uncounter,timep,month,year] = 0.12
    end
    fuelep = Select(FuelEP,"NaturalGas")
    for year in years
      xUnFlFr[uncounter,fuelep,year] = 1
    end
  end

  # 
  # Add Fuel Cells
  # 
  for area in Select(Area,(from = "ON", to = "NU"))
    genco = Select(GenCo,Area[area])
    node = Select(Node,Area[area])
    uncounter = uncounter+1
    UnCode[uncounter] = Area[area]*"_New_FuelCell"
    UnName[uncounter] = Area[area]*" New Fuel Cell"     
    CommonCharacteristics(data,uncounter,FuelCell,genco,node,area,CN)
    fuelep = Select(FuelEP,"Hydrogen")
    for year in years
      xUnFlFr[uncounter,fuelep,year] = 1
    end
  end

  # 
  # Add Biomass CCS
  # 
  for area in Select(Area,(from = "ON", to = "NU"))
    genco = Select(GenCo,Area[area])
    node = Select(Node,Area[area])
    uncounter = uncounter+1
    UnCode[uncounter] = Area[area]*"_New_BiomassCCS"
    UnName[uncounter] = Area[area]*" New Biomass CCS"
    CommonCharacteristics(data,uncounter,BiomassCCS,genco,node,area,CN)
    for year in years, month in Months, timep in TimePs
      UnOR[uncounter,timep,month,year] = 0.12
    end
    fuelep = Select(FuelEP,"Biomass")
    for year in years
      xUnFlFr[uncounter,fuelep,year] = 1
    end
  end   
  
  # 
  # Add Other Storage
  # 
  for area in Select(Area,(from = "ON", to = "NU"))
    genco = Select(GenCo,Area[area])
    node = Select(Node,Area[area])
    nation = Select
    uncounter = uncounter+1
    UnCode[uncounter] = Area[area]*"_New_Battery"
    UnName[uncounter] = Area[area]*" New Battery"     
    CommonCharacteristics(data,uncounter,Battery,genco,node,area,CN)
  end

  # 
  # California Policy Units
  # 
  
  #
  # CA New Geothermal
  #
  area = Select(Area,"CA")
  genco = Select(GenCo,Area[area])
  node = Select(Node,"CANO")
  uncounter = uncounter+1
  UnCode[uncounter] = "CA_New_Geo"
  UnName[uncounter] = "CA New Geothermal" 
  CommonCharacteristics(data,uncounter,Geothermal,genco,node,area,US)
  
  #
  # CA New Hydro
  #
  area = Select(Area,"CA")
  genco = Select(GenCo,Area[area])
  node = Select(Node,"CANO")
  uncounter = uncounter+1
  UnCode[uncounter] = "CA_New_Hydro"
  UnName[uncounter] = "CA New Small Hydro"
  CommonCharacteristics(data,uncounter,SmallHydro,genco,node,area,US)
  
  #
  # CA New Solar
  #
  area = Select(Area,"CA")
  genco = Select(GenCo,Area[area])
  node = Select(Node,"CANO")
  uncounter = uncounter+1
  UnCode[uncounter] = "CA_New_SolarPV"
  UnName[uncounter] = "CA New Solar PV"
  CommonCharacteristics(data,uncounter,SolarPV,genco,node,area,US)
  
  #
  # CA New Onshore Wind
  #
  area = Select(Area,"CA")
  genco = Select(GenCo,Area[area])
  node = Select(Node,"CANO")
  uncounter = uncounter+1
  UnCode[uncounter] = "CA_New_OnshoreWind"
  UnName[uncounter] = "CA New Onshore Wind"
  CommonCharacteristics(data,uncounter,OnshoreWind,genco,node,area,US)
  
  #
  # CA New Biomass
  #
  area = Select(Area,"CA")
  genco = Select(GenCo,Area[area])
  node = Select(Node,"CANO")
  uncounter = uncounter+1
  UnCode[uncounter] = "CA_New_Biomass"
  UnName[uncounter] = "CA New Biomass"
  CommonCharacteristics(data,uncounter,Biomass,genco,node,area,US)

  #
  # Add new CCS units for CER
  #
  
  #
  # AB_OILS0_CCS (AB00002000101)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_OILS0_CCS"
  UnName[uncounter] = "AB00002000101 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "OilSandsUpgraders"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_OILS1_CCS (AB00002000300)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_OILS1_CCS"
  UnName[uncounter] = "AB00002000300 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "OilSandsUpgraders"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SOUR2_CCS (AB00029600201)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SOUR2_CCS"
  UnName[uncounter] = "AB00029600201 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SourGasProcessing"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SWEE3_CCS (AB00034600200)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SWEE3_CCS"
  UnName[uncounter] = "AB00034600200 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SweetGasProcessing"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SOUR4_CCS (AB00034700200)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SOUR4_CCS"
  UnName[uncounter] = "AB00034700200 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SourGasProcessing"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SAGD5_CCS (AB00041700201)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SAGD5_CCS"
  UnName[uncounter] = "AB00041700201 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SAGDOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_PULP6_CCS (AB00041700301)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_PULP6_CCS"
  UnName[uncounter] = "AB00041700301 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "PulpPaperMills"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SAGD7_CCS (AB_CL_NG_2)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SAGD7_CCS"
  UnName[uncounter] = "AB_CL_NG_2 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SAGDOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_CSSO8_CCS (AB_CSS002000)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_CSSO8_CCS"
  UnName[uncounter] = "AB_CSS002000 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "CSSOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_CSSO9_CCS (AB_CSS002003)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_CSSO9_CCS"
  UnName[uncounter] = "AB_CSS002003 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "CSSOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SAGD10_CCS (AB_LongLake_NG)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SAGD10_CCS"
  UnName[uncounter] = "AB_LongLake_NG conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SAGDOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SAGD11_CCS (AB_SAGD042000)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SAGD11_CCS"
  UnName[uncounter] = "AB_SAGD042000 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SAGDOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SAGD12_CCS (AB_SAGD042003)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SAGD12_CCS"
  UnName[uncounter] = "AB_SAGD042003 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SAGDOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_SAGD13_CCS (AB_SAGD042004)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_SAGD13_CCS"
  UnName[uncounter] = "AB_SAGD042004 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "SAGDOilSands"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_PETR14_CCS (AB_Scoria_Cg)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_PETR14_CCS"
  UnName[uncounter] = "AB_Scoria_Cg conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "Petrochemicals"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_INDU15_CCS (AB_Shell_Carol)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_INDU15_CCS"
  UnName[uncounter] = "AB_Shell_Carol conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "IndustrialGas"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_PETR16_CCS (AB_Strath_Co)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_PETR16_CCS"
  UnName[uncounter] = "AB_Strath_Co conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "Petrochemicals"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # SK_NONM17_CCS (SK00015200201)
  #
  area  = Select(Area,"SK")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "SK_NONM17_CCS"
  UnName[uncounter] = "SK00015200201 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "NonMetalMining"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # SK_NONM18_CCS (SK00015200202)
  #
  area  = Select(Area,"SK")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "SK_NONM18_CCS"
  UnName[uncounter] = "SK00015200202 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "NonMetalMining"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # SK_NONM19_CCS (SK00038800100)
  #
  area  = Select(Area,"SK")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "SK_NONM19_CCS"
  UnName[uncounter] = "SK00038800100 conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen[uncounter] = 1
  UnMustRun[uncounter] = 1
  UnSector[uncounter] = "NonMetalMining"
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end
  
  #
  # AB_UTIL20_CCS (AB_Black_Bear)
  #
  area  = Select(Area,"AB")
  genco = Select(GenCo,Area[area])
  node  = Select(Node,Area[area])
  uncounter = uncounter+1
  UnCode[uncounter] = "AB_UTIL20_CCS"
  UnName[uncounter] = "AB_Black_Bear conversion to NGCCS"
  CommonCharacteristics(data,uncounter,NGCCS,genco,node,area,CN)
  UnCogen=0
  for year in years
    UnSqFr[uncounter,CO2,year] = 0.95
  end


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
  @info "UnitCreate_ForPolicies.jl - Control"
  CreateUnits(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
