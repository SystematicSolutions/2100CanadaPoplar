#
# PlantCharacteristics.jl
#
# Added SqFr for endogenous CoalCCS. JSLandry; July 13, 2020
#
using EnergyModel

module PlantCharacteristics

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
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
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ArNdFr::VariableArray{3} = ReadDisk(db,"EGInput/ArNdFr") # [Area,Node,Year] Fraction of the Area in each Node (Fraction)
  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (Years)
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  UFOMC::VariableArray{3} = ReadDisk(db,"EGInput/UFOMC") # [Plant,Area,Year] Unit Fixed O&M Costs ($/KW)
  UOMC::VariableArray{3} = ReadDisk(db,"EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs ($/MWh)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  EmitNew::VariableArray{2} = ReadDisk(db,"EGInput/EmitNew") # [Plant,Area] Do New Plants Emit Pollution? (1=Yes)
  F1New::VariableArray{2} = ReadDisk(db,"EGInput/F1New") # [Plant,Area] Fuel Type 1
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") # [TimeP,Month] Number of Hours in the Interval (Hours)
  MRunNew::VariableArray{2} = ReadDisk(db,"EGInput/MRunNew") # [Plant,Area] New Plant Must Run Switch (1=Must Run)
  SensitivityNew::VariableArray{3} = ReadDisk(db,"EGInput/SensitivityNew") # [Plant,Area,Year] Outage Rate Sensitivity to Decline in Driver for New Cogeneration Units (Driver/Driver)
  TPRMap::VariableArray{2} = ReadDisk(db,"EGInput/TPRMap") # [TimeP,Power] TimeP to Power Map
  GCExpSw::VariableArray{3} = ReadDisk(db,"EGInput/GCExpSw") # [Plant,Area,Year] Generation Capacity Expansion Switch
  GCCCFlag::VariableArray{3} = ReadDisk(db,"EGInput/GCCCFlag") # [Plant,Area,Year] Plant Capital Cost Flag
  PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") # [Plant,Area] Minimum Project Size (MW)
  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") # [Plant,Area] Maximum Project Size (MW)
  NuclearFuelCost::VariableArray{2} = ReadDisk(db,"EGInput/NuclearFuelCost") # [Area,Year] Nuclear Fuel Costs ($/MWh)
  GCTCB0::VariableArray{3} = ReadDisk(db,"EGInput/GCTCB0") # [Plant,Area,Year] ETC Capital Cost Coefficiency ($/$)
  GCTCMap::VariableArray{3} = ReadDisk(db,"EGInput/GCTCMap") # [Area,Nation,Year] Area to Nation Map for ETC
  DInvFr::VariableArray{3} = ReadDisk(db,"EGInput/DInvFr") # [Plant,Area,Year] Device Investments Fraction ($/$)
  TDInvFr::VariableArray{3} = ReadDisk(db,"EGInput/TDInvFr") # [Plant,Area,Year] Electric Transmission and Distribution Investments Fraction ($/$)

end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Areas,Plant,Years) = data
  (;xExchangeRate,xInflation) = data
  (;EmitNew,F1New,MRunNew,SensitivityNew) = data
  (;GCExpSw,GCCCFlag,PjMnPS,PjMax,NuclearFuelCost,GCTCB0,GCTCMap,DInvFr,TDInvFr) = data

  #
  # Plant Characteristics section
  # All plants, All regions
  #
  @. EmitNew=0
  @. MRunNew=0
  @. SensitivityNew=0

  #
  # OGCC, All regions
  #
  plant=Select(Plant,"OGCC")
  for area in Areas
    EmitNew[plant,area]=1
#    F1New[plant,area]="NaturalGas"
  end

  #
  # OGCT, All regions
  #
  plant=Select(Plant,"OGCT")
  for area in Areas
    EmitNew[plant,area]=1
#    F1New[plant,area]="NaturalGas"
  end
  #
  # Selected Territories and Provinces have no natural gas
  #
  areas=Select(Area,["NL","PE","YT","NU"])
    for area in areas
#    F1New[plant,area]="Diesel"
  end

  #
  # OGSteam, All regions
  #
  plant=Select(Plant,"OGSteam")
  for area in Areas
    EmitNew[plant,area]=1
#    F1New[plant,area]="HFO"
  end

  #
  # Coal and CoalCCS, All regions
  #
  plants=Select(Plant,["Coal","CoalCCS"])
  for area in Areas, plant in plants
    EmitNew[plant,area]=1
#    F1New[plant,area]="Coal"
  end

  #
  # Biomass, All regions
  #
  plant=Select(Plant,"Biomass")
  for area in Areas
    EmitNew[plant,area]=1
#    F1New[plant,area]="Biomass"
  end

  #
  # Biogas, All regions
  #
  plants=Select(Plant,["Biogas","Waste"])
  for area in Areas, plant in plants
    EmitNew[plant,area]=1
#    F1New[plant,area]="Waste"
  end

  #
  # OnshoreWind, Generic and by Region
  # Wind Capacity Factors based on cost projections from PTs and NRCan learning curves - V.Keller July 2023
  # Updated TD, March 2024 aligment with NextGrid for CER modelling
  #
  plant=Select(Plant,"OnshoreWind")
  for area in Areas
    MRunNew[plant,area]=1
#    F1New[plant,area]="Wind"
  end

  plant=Select(Plant,"OffshoreWind")
  for area in Areas
    MRunNew[plant,area]=1
#    F1New[plant,area]="Wind"
  end

  #
  # SolarPV, generic and by region
  # Solar Factors based on cost projections from PTs and NRCan learning curves - V.Keller July 2023
  # Updated TD, March 2024 aligment with NextGrid for CER modelling
  #
  plants=Select(Plant,["SolarPV","SolarThermal"])
  F1New="Solar"
  for area in Areas, plant in plants
    MRunNew[plant,area]=1
#    F1New[plant,area]="Solar"
  end

  #
  # Hydro, generic and by region
  #
  plants=Select(Plant,["SmallHydro","BaseHydro","PeakHydro"])
  for area in Areas, plant in plants
    MRunNew[plant,area]=1
#    F1New[plant,area]="Hydro"
  end

  #
  # Nuclear, All regions
  #
  plant=Select(Plant,"Nuclear")
  for area in Areas
#    F1New[plant,area]="Nuclear"
  end

  #
  # Other renewable and others, All regions
  #
  plant=Select(Plant,"Geothermal")
  for area in Areas
#    F1New[plant,area]="Geothermal"
  end
  plant=Select(Plant,"Wave")
  for area in Areas
    MRunNew[plant,area]=1
#    F1New[plant,area]="Wave"
  end
  plant=Select(Plant,"Tidal")
  for area in Areas
    MRunNew[plant,area]=1
#    F1New[plant,area]="Wave"
  end
  plant=Select(Plant,"FuelCell")
  for area in Areas
#    F1New[plant,area]="Hydrogen"
  end
  plant=Select(Plant,"OtherGeneration")
  for area in Areas
    EmitNew[plant,area]=1
#    F1New[plant,area]="NaturalGas"
  end

  WriteDisk(db,"EGInput/EmitNew",EmitNew)
#  WriteDisk(db,"EGInput/F1New",F1New)
  WriteDisk(db,"EGInput/MRunNew",MRunNew)
  WriteDisk(db,"EGInput/SensitivityNew",SensitivityNew)

  #
  ###################################
  #
  # Conventional Plants (GCExpSw=1)
  #
  @. GCExpSw=1

  #
  # Renewable Plants (GCExpSw=2)
  #
  plants=Select(Plant,["Biomass","Geothermal","SmallHydro","SolarPV","SolarThermal",
                      "Waste","BiomassCCS","Wave","Tidal","OnshoreWind","OffshoreWind"])
  for year in Years, area in Areas, plant in plants
    GCExpSw[plant,area,year]=2
  end

  #
  # Landfill Gas and Other Generation come from other parts of the model (GCExpSw=3)
  #
  plants=Select(Plant,["Biogas","OtherGeneration"])
  for year in Years, area in Areas, plant in plants
    GCExpSw[plant,area,year]=3
  end
  WriteDisk(db,"EGInput/GCExpSw",GCExpSw)

  #
  ########################
  #
  # Generation Cost Flag
  #
  # Initialize all plants to an infinite potential capacity
  #
  @. GCCCFlag=0

  #
  # Plants whose potential is limited with costs increasing as sites are developed.
  #
  plants=Select(Plant,["SmallHydro","PumpedHydro"])
  for year in Years, area in Areas, plant in plants
    GCCCFlag[plant,area,year]=1
  end

  #
  # Plants whose potential is limited, but costs are fixed.
  #
  plants=Select(Plant,["Biomass","OnshoreWind","OffshoreWind","SolarPV","SolarThermal",
                      "FuelCell","Wave","Tidal","Geothermal"])
  for year in Years, area in Areas, plant in plants
    GCCCFlag[plant,area,year]=2
  end
  WriteDisk(db,"EGInput/GCCCFlag",GCCCFlag)

  #
  ########################
  #
  # Minimum Plant Size
  #
  #########JSO Change##########
  @. PjMnPS=1
  # PjMnPS(OGCT,A)=50
  # PjMnPS(OGCC,A)=50
  # PjMnPS(OGSteam,A)=100
  # PjMnPS(Coal,A)=400
  # PjMnPS(CoalCCS,A)=400
  # PjMnPS(Nuclear,A)=750
  # PjMnPS(BaseHydro,A)=50
  # PjMnPS(PeakHydro,A)=50
  # PjMnPS(Biomass,A)=25
  #
  # Select Area(NL)
  # PjMnPS(OGCT,A)=25
  # Select Area*
  #
  # Select Area(PE,YT,NT,NU)
  # PjMnPS(OGCT,A)=10
  # PjMnPS(OGCC,A)=30
  # PjMnPS(PeakHydro,A)=5
  # Select Area*
  #
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)

  #
  ########################
  #
  # The default value is for the capacity built in a single year
  # to be uncontrained.
  #
  @. PjMax=99999
  #
  # NFLD, Yukon, and Nunavut has no natural gas capacity
  #
  years=collect(Future:Final)
  areas=Select(Area,["NL","YT","NU"])
  plant=Select(Plant,"OGCC")
  #########JSO Change##########
  for area in areas
    PjMax[plant,area]=99999
  end
  #########JSO Change##########
  plant=Select(Plant,"OGSteam")
  for area in areas
    PjMax[plant,area]=99999
  end

  #
  # Advanced Coal must be IGCC
  #
  # *Select Plant(CoalAdvanced)
  # *PjMax=0
  # *Select Area(AB,SK)
  # *PjMax=99999
  # *Select Plant*, Area*
  #
  # Quebec builds hydro instead of natural gas and oil
  #
  # *Select Area(QC), Plant(PeakHydro)
  # *PjMax=2000
  #########JSO Change##########
  # *Select Plant(OGCC,OGCT)
  # *PjMax=0
  #########JSO Change##########
  #
  # Manitoba builds hydro instead of natural gas and oil
  #
  area=Select(Area,"MB")
  plant=Select(Plant,"PeakHydro")
  PjMax[plant,area]=200
  plants=Select(Plant,["OGCC","OGCT"])
  for plant in plants
    PjMax[plant,area]=0
  end

  #
  # Yukon builds small hydro - Jeff Amlin 11/07/16
  #
  area=Select(Area,"YT")
  plant=Select(Plant,"PeakHydro")
  PjMax[plant,area]=15

  #
  ########################
  #
  # John St-Laurent O'Connor 2021.10.15 Changes to cap yearly growth
  # of some plant types in some areas
  #
  areas=Select(Area,(from="ON", to="NU"))
  plant=Select(Plant,"Battery")
  for area in areas
    PjMax[plant,area]=15
  end

  plant=Select(Plant,"SmallHydro")
  areas=Select(Area,(from="ON", to="MB"))
  for area in areas
    PjMax[plant,area]=50
  end
  areas=Select(Area,(from="SK", to="NU"))
  for area in areas
    PjMax[plant,area]=10
  end

  plant=Select(Plant,"OnshoreWind")
  areas=Select(Area,["ON","QC","BC","AB","SK","NL"])
  for area in areas
    PjMax[plant,area]=1000
  end
  areas=Select(Area,["MB","NB","NS"])
  for area in areas
    PjMax[plant,area]=500
  end
  areas=Select(Area,(from="PE", to="NU"))
  for area in areas
    PjMax[plant,area]=100
  end

  plant=Select(Plant,"SolarPV")
  areas=Select(Area,["ON","QC","BC","AB","SK"])
  for area in areas
    PjMax[plant,area]=300
  end
  areas=Select(Area,["MB","NB","NS","NL"])
  for area in areas
    PjMax[plant,area]=100
  end
  areas=Select(Area,(from="PE", to="NU"))
  for area in areas
    PjMax[plant,area]=50
  end

  WriteDisk(db,"EGInput/PjMax",PjMax)

  #
  ########################
  #
  # Convert from 2013 Ontario$/MWh to 1985 local$/MWh.
  #
  ON=Select(Area,"ON")
  for year in Years, area in Areas
    NuclearFuelCost[area,year]=109/44.4/xExchangeRate[ON,Yr(2013)]*xExchangeRate[area,Yr(2013)]/
      xInflation[area,Yr(2013)]
  end

  #
  # Source: Ontario Power Generation Annual Report 2013,
  # overview page and page 86. Jeff Amlin 3/5/15.
  #
  # Nuclear Fuel Cost (Millions 2013 CN$) 109.00
  # Nuclear Generation (TWh)               44.70
  # Nuclear Fuel Cost (2013 CN$/MWh)        2.44
  #
  WriteDisk(db,"EGInput/NuclearFuelCost",NuclearFuelCost)


  #
  ########################
  #
  @. GCTCB0=0
  WriteDisk(db,"EGInput/GCTCB0",GCTCB0)

  #
  ########################
  #
  @. GCTCMap=1
  WriteDisk(db,"EGInput/GCTCMap",GCTCMap)

  #
  ########################
  #
  @. DInvFr=0.10
  WriteDisk(db,"EGInput/DInvFr",DInvFr)

  #
  ########################
  #
  @. TDInvFr=0.0
  WriteDisk(db,"EGInput/TDInvFr",TDInvFr)

end

function CalibrationControl(db)
  @info "PlantCharacteristics.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
