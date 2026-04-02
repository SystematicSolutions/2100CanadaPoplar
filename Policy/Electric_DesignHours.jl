# Electric_DesignHours.jl
#
# This file is used to adjust Design Hours.
# These changes were introduced in E2020 when developping files for modelling the CER.
# Among motivations:
# 1) improve modelling renewable energy contribution to the different time periods
# 2) improve the alignment between E2020 and NextGrid (used to model CER compliance of the power plants inside E2020)
 
# 
# Notes related to CER Modelling:
# 
# Reduce design hours (DesHr) to reflect capacity factor constraint (EAF) - Jeff Amlin 12/4/23
# Modified to reflect performane standard of 65 pre-2050 and 42 in 2050 t/GWh May 2024. Edited by SouissiM on 18/07/2024 for CER CGII modelling work.
# 
# Note 1 : Despite the CER entering into force in 2035, it is believed that Victor had correctd the DesHr as early as 2025 to reflect that projects built
# beforehand would be impacted by the CER later in their life. This assumption will result in a conservative cost for each technology since it assumed
# the plant will be impact for the full duration of its lifetime, whereas in reality, it will only be impacted post 2035.
#  
# Note 2 : Following the logic explained above, the design hours for the standard in 2050, which is the more restrictive, will be used starting in 2025.
# 
  
using EnergyModel

module Electric_DesignHours

import ...EnergyModel: ReadDisk, WriteDisk, Select
import ...EnergyModel: HisTime, ITime, MaxTime, First, Future, Final, Yr
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  #year::Int
  
  # Sets
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey") 
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  # Variables
  AvFactor::VariableArray{5} = ReadDisk(db,"EGInput/AvFactor") # [Plant,TimeP,Month,Area,Year] Availability Factor (MW/MW)
  BuildSw::VariableArray{2} = ReadDisk(db,"EGInput/BuildSw") # [Area,Year] Build switch
  DesHr::VariableArray{4} = ReadDisk(db,"EGInput/DesHr") # [Plant,Power,Area,Year] Design Hours (Hours)
  DRM::VariableArray{2} = ReadDisk(db,"EInput/DRM") # [Node,Year] Desired Reserve Margin (MW/MW)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") # [TimeP,Month] Number of Hours in the Interval (Hours)
  HDVCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDVCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Variable Costs Bid ($/$)
  HDXLoad::VariableArray{5} = ReadDisk(db,"EGInput/HDXLoad") # [Node,NodeX,TimeP,Month,Year] Exogenous Loading on Transmission Lines (MW)
  LLMax::VariableArray{5} = ReadDisk(db,"EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
  TPRMap::VariableArray{2} = ReadDisk(db,"EGInput/TPRMap") # [TimeP,Power] TimeP to Power Map
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Availability Factor
  #xUnEGC::VariableArray{3} = ReadDisk(db,"EGInput/xUnEGC",year) #[Unit,TimeP,Month,Year]  Exogenous Effective Generating Capacity (MW)
  UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum
  UnFlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMin") # [Unit,FuelEP,Year] Fuel Fraction Minimum
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run Flag
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnOOR::VariableArray{2} = ReadDisk(db,"EGCalDB/UnOOR") # [Unit,Year] Operational Outage Rate (MW/MW)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  UnSource::VariableArray{1} = ReadDisk(db,"EGInput/UnSource") # [Unit] Source Flag
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable Costs Per Unit ($/MWh)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  xUnVCost::VariableArray{4} = ReadDisk(db,"EGInput/xUnVCost") # [Unit,TimeP,Month,Year] Exogenous Market Price Bid ($/MWh)
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,FuelEP,GenCo,Month,Node,NodeX,Plant,Power,TimeP,Unit,Year) = data
  (; Areas,FuelEPs,GenCos,Months,Nodes,NodeXs,Plants,Powers,TimePs,Units,Years) = data
  (; AvFactor,BuildSw,DesHr,DRM,HDHours,HDVCFR,HDXLoad,LLMax) = data
  (; UnArea,UnCode,UnCogen,UnEAF,UnFlFrMax,UnFlFrMin) = data
  (; UnGenCo,UnHRt,UnMustRun,UnNode,UnNation,UnOnLine,UnUOMC) = data
  (; UnOOR,UnOR,UnPlant,UnRetire,UnSource,xUnFlFr,xUnVCost) = data

  # Peak, Intermediate and Base powers are defined in EGData.jl
  # Peak         = TimeP 1-3 = 525.6
  # Intermediate = TimeP 1-4 = 1401.6
  # Base         = TimeP 1-6 = 8760

  Years = collect(Future:Final)
  
  ##############
  # PEAK POWER #
  ##############
  
  peak = Select(Power, "Peak")
  # Default values
  for plant in Plants, area in Areas, year in Years
    DesHr[plant,peak,area,year] = 525.6
  end
  
  # Thermal
  plants = Select(Plant,["CoalCCS","OGCC","OGCT","OGSteam","NGCCS","SmallOGCC","Waste"])
  for year in Years, area in Areas, plant in plants
    DesHr[plant,peak,area,year] = 525.6
  end   
  
  # Coal
  plants = Select(Plant,"Coal")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,peak,area,year] = 365.7
  end
  
  # Renewables: no contribution
  plants = Select(Plant, ["SolarPV","SolarThermal","OnshoreWind",
                          "OffshoreWind","Wave","Tidal","OtherGeneration"]) 
  for plant in plants, area in Areas, year in Years
    DesHr[plant,peak,area,year] = 0.01
  end


  ######################
  # INTERMEDIATE POWER #
  ######################
  
  interm = Select(Power, "Interm")
  for plant in Plants, area in Areas, year in Years
    DesHr[plant,interm,area,year] = 1401.6
  end

  # Coal
  plants = Select(Plant,"Coal")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,interm,area,year] = 365.7
  end
  # Thermal
  plants = Select(Plant,["CoalCCS","NGCCS","Waste"])
  for year in Years, area in Areas, plant in plants
    # This one won't work unless TimeP5 is in Intermediate power
    DesHr[plant,interm,area,year] = 3504.0
  end
  plants = Select(Plant,["OGCC","SmallOGCC"])
  for year in Years, area in Areas, plant in plants
    DesHr[plant,interm,area,year] = 960.9
  end
  plants = Select(Plant,"OGCT")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,interm,area,year] = 621.2
  end
  plants = Select(Plant,"OGSteam")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,interm,area,year] = 614.2
  end

  # Solar, Wave and others: no contribution
  plants = Select(Plant, ["SolarPV","SolarThermal","Wave","Tidal","OtherGeneration"])
  for plant in plants, area in Areas, year in Years
    DesHr[plant,interm,area,year] = 0.01
  end
  
  # Wind: small contribution
  plants = Select(Plant, ["OnshoreWind","OffshoreWind"])
  for plant in plants, area in Areas, year in Years
    DesHr[plant,interm,area,year] = 1401 * 0.15
  end

  # Battery: small contribution
  plant = Select(Plant, "Battery")
  for area in Areas, year in Years
    DesHr[plant,interm,area,year] = 1401 * 0.25
  end


  ##############
  # BASE POWER #
  ##############
  
  basepower = Select(Power, "Base")
  # Storage: no contribution
  plants = Select(Plant, ["Battery","OtherGeneration","PumpedHydro"])
  for plant in plants, area in Areas, year in Years
    DesHr[plant,basepower,area,year] = 0.01
  end

  # Coal
  plants = Select(Plant,"Coal")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,basepower,area,year] = 365.7
  end
  plants = Select(Plant,"CoalCCS")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,basepower,area,year] = 6677.0
  end
  # Thermal
  plants = Select(Plant,["OGCC","SmallOGCC"])
  for year in Years, area in Areas, plant in plants
    DesHr[plant,basepower,area,year] = 960.9
  end
  plants = Select(Plant,"OGCT")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,basepower,area,year] = 621.2
  end
  plants = Select(Plant,"OGSteam")
  for year in Years, area in Areas, plant in plants
    DesHr[plant,basepower,area,year] = 614.2
  end

  # WRITE DISK
  WriteDisk(db,"EGInput/DesHr",DesHr)
  
end

function PolicyControl(db)
  @info "Electricity_Patch.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end