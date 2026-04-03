#
# UnitConstruction.jl
# 
using EnergyModel

module UnitConstruction

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ArNdFr::VariableArray{3} = ReadDisk(db,"EGInput/ArNdFr") # [Area,Node,Year] Fraction of the Area in each Node (Fraction)
  PjNSw::VariableArray{4} = ReadDisk(db,"EGInput/PjNSw") # [Node,GenCo,Area,Year] Project Selection Node Switch (1=Build)
  DRM::VariableArray{2} = ReadDisk(db,"EInput/DRM") # [Node,Year] Desired Reserve Margin (MW/MW)
  BuildSw::VariableArray{2} = ReadDisk(db,"EGInput/BuildSw") # [Area,Year] Build switch 
  BuildFr::VariableArray{2} = ReadDisk(db,"EGInput/BuildFr") # [Area,Year] Building fraction
  BFracMax::VariableArray{2} = ReadDisk(db,"EGInput/BFracMax") # [Area,Year] Maximum Fraction of Capacity Built Endogenously (MW/MW)
  CUCLimit::VariableArray{1} = ReadDisk(db,"EGInput/CUCLimit") # [Year] Build Decision Capacity Under Construction Limit (MW/MW)
  PrDiFr::VariableArray{3} = ReadDisk(db,"EGInput/PrDiFr") # [Power,Area,Year] Price Differential Fraction (Fraction)
  RnBuildFr::VariableArray{3} = ReadDisk(db,"EGInput/RnBuildFr") # [Plant,Area,Year] Build Fraction for Renewable Capacity as Fraction of Area (MW/MW)
  RnFr::VariableArray{2} = ReadDisk(db,"EGInput/RnFr") # [Area,Year] Renewable Fraction (GWh/GWh)
  RnMSM::VariableArray{5} = ReadDisk(db,"EGInput/RnMSM") # [Plant,Node,GenCo,Area,Year] Renewable Market Share Non-Price Factors (GWh/GWh)
  RnOption::VariableArray{2} = ReadDisk(db,"EGInput/RnOption") # [Area,Year] Renewable Expansion Option (1=Local RPS, 2=Regional RPS, 3=FIT)
  RnSwitch::VariableArray{2} = ReadDisk(db,"EGInput/RnSwitch") # [Plant,Area] Renewable Plant Type Switch (1=Renewable)
  RnVF::VariableArray{2} = ReadDisk(db,"EGInput/RnVF") # [Area,Year] Renewable Market Share Variance Factor ($/$)
  HDFlowFr::VariableArray{3} = ReadDisk(db,"EGInput/HDFlowFr") # [Node,NodeX,Year] Fraction of Power Contracts in Firm Capacity (MW/MW)
  GrSysFr::VariableArray{3} = ReadDisk(db,"EGInput/GrSysFr") # [Node,Area,Year] Green Power Capacity as Fraction of System (MW/MW)
  GrMSM::VariableArray{4} = ReadDisk(db,"EGInput/GrMSM") # [Plant,Node,Area,Year] Green Power Market Share Non-Price Factors (MW/MW)
  GrVF::VariableArray{1} = ReadDisk(db,"EGInput/GrVF") # [Year] Green Power Market Share Variance Factor (MW/MW)
  CapCredit::VariableArray{3} = ReadDisk(db,"EGInput/CapCredit") # [Plant,Area,Year] Capacity Credit (MW/MW)
end

function ECalibration(db)
  data = ECalib(; db)
  (;Area,Areas,GenCo,GenCos,Nation,Node) = data
  (;NodeXs,Nodes,Plant,Plants) = data
  (;Years) = data
  (;ANMap,ArNdFr,PjNSw,DRM,BuildSw,BuildFr,BFracMax,CUCLimit,PrDiFr,RnBuildFr) = data
  (;RnFr,RnMSM,RnOption,RnSwitch,RnVF,HDFlowFr,GrSysFr,GrMSM,GrVF,CapCredit) = data

  # 
  # Initialize construction
  # 
  PjNSw .= 0.0

  # 
  # All GenCos builds in only one Area and Node.
  # 
  # For Canada, Node, GenCo, and Area match
  # 
  for area in Areas, year in Years
    genco = Select(GenCo,Area[area])
    node = findall(Node.== Area[area])
    if node != []
      for n in node
        PjNSw[n,genco,area,year] = 1.0
      end
    end
  end

  PjNSw[Select(Node,"LB"),Select(GenCo,"NL"),Select(Area,"NL"),Years] .= 1.0

  # 
  # For US, construction location based on ArNdFr
  # 
  US = Select(Nation, "US")
  us_areas = findall(ANMap[:,US] .== 1.0)
  for area in us_areas, year in Years
    genco = Select(GenCo,Area[area])
    node = findall(ArNdFr[area,Nodes,year] .> 0.001)
    if node != []
      for n in node
        PjNSw[n,genco,area,year] = 1.0
      end
    end
  end

  PjNSw[Nodes,Select(GenCo,"ROW"),Areas,Years] .= 0.0

  # 
  # Default Reserve Margin
  # 
  DRM .= 0.20

  #
  # Desired Reserve Margins have been updated during the Clean electricity regulations modelling.
  # Values have been discussed with ECD which has been in contact with provincial utilities.
  # TD, Aug 2024
  #

  node=Select(Node,"BC")
  for year in Years
    # DRM[node,year] = 0.137 (updated to 12% due to Ref24 consultation)
    DRM[node,year] = 0.12
  end

  node=Select(Node,"AB")
  for year in Years
    DRM[node,year] = 0.27
  end

  node=Select(Node,"SK")
  for year in Years
    DRM[node,year] = 0.15
  end

  node=Select(Node,"MB")
  for year in Years
    DRM[node,year] = 0.12
  end

  node=Select(Node,"ON")
  for year in Years
    # DRM[node,year] = 0.142  (updated due to new numbers in 2024 Annual Planning Outlook IESO)
    DRM[node,year] = 0.134
  end

  node=Select(Node,"QC")
  for year in Years
    DRM[node,year] = 0.095
  end

  node=Select(Node,"NB")
  for year in Years
    DRM[node,year] = 0.2
  end

  node=Select(Node,"NL")
  for year in Years
    DRM[node,year] = 0.2
  end

  node=Select(Node,"NS")
  for year in Years
    DRM[node,year] = 0.20
  end

  node=Select(Node,"PE")
  for year in Years
    # DRM[node,year] = 0.2 (updated to 15% due to Ref24 consultation)
    DRM[node,year] = 0.15
  end

  # 
  # Yukon is higher since it is an isolated system - Jeff Amlin 11/07/16
  # 
  node=Select(Node,"YT")
  for year in Years
    DRM[node,year] = 0.40
  end

  # 
  # Adjust reserve margin for CASO due to capacity jump in 2018. Possibly
  # due to Arizona units claimed by California. 04/08/2019 R.Levesque
  # 
  node=Select(Node,"CASO")
  DRM[node,Yr(2017)] = 0.0
  years=collect(Yr(2018):Final)
  for year in years
    DRM[node,year] = DRM[node,year-1] + 0.005
  end

  node=Select(Node,"MX")
  years=collect(Future:Final)
  for year in years
    DRM[node,year] = 0.45
  end

  #
  # Building Strategies
  #
  years=collect(Future:Final)  

  # 
  # Build to meet reserve margin or if prices are high (BuildSw=5)
  #
  for year in years, area in Areas   
    BuildSw[area,year] = 5
  end

  # 
  # British Columbia, Nova Scotia, New Brunswick and Yukon only build to meet peak (BuildSw=6)
  #
  areas = Select(Area,["BC","NS","NB","YT","PE"])
  for year in years, area in areas
    BuildSw[area,year] = 6
  end

  # 
  # ROW does not build endogenously
  #
  areas = Select(Area,"ROW")
  for year in years, area in areas
    BuildSw[area,year] = 0
  end

  # 
  # US utilities build to meet reserve margin or price
  # 
  areas = Select(Area,(from = "CA", to = "Pac"))
  for year in years, area in areas
    BuildSw[area,year] = 5
  end
 
  # 
  # California is building due to high prices (which are probably due to 
  # an generation imbalance, possibly due to our lack of cogeneration).  
  # Sorting this out will take time, so in the short term, we change the 
  # BuildSw to 6 for California, WSC (Texas) and Mtn (AZ).
  # per Jeff Amlin 4/9/2019 R.Levesque
  # 
  # Overwrite CA,WSC, and Mtn builds to meet peak demand (BuildSw=6)
  # 
  areas = Select(Area,["CA","WSC","Mtn"])
  for year in years, area in areas
    BuildSw[area,year] = 6
  end

  # 
  # Mexico builds to meet peak (BuildSw=6) - Jeff Amlin 08/10/18
  # 
  areas = Select(Area,"MX")
  for year in years, area in areas  
    BuildSw[area,year] = 6
  end
  
  #
  # Build Fraction
  #
  for year in Future:Final
    for area in Areas
      BuildFr[area,year] = 1.00
    end

    BuildFr[Select(Area,"ROW"),year] = 0.00

    for area in Select(Area,(from = "CA", to = "MX"))
      BuildFr[area,year] = 0.50
    end
  end

  for area in Areas, year in 1:Yr(2020)
    # 
    # Do not build in first forecast years since this will cause 
    # problems with the UnCounter.
    # 
    BuildFr[area,year] = 0.0
  end

  # 
  # Endogenous Building Parameters
  # 
  BFracMax .= 0.02
  CUCLimit .= 0.10
  PrDiFr .= 0.15

  # 
  # Renewable Capacity Parameters
  # 
  RnOption .= 0
  RnBuildFr .= 0.02
  RnFr .= 0.0
  RnVF .= 0-10.0
  RnMSM .= 0.0
  RnSwitch .= 0

  plants = Select(Plant,["Biomass","Biogas","OnshoreWind","OffshoreWind","SolarPV",
                          "SolarThermal","SmallHydro","Wave","Geothermal","Waste"])
  RnMSM[plants,Nodes,GenCos,Areas,Years] .= 1.0
  RnSwitch[plants,Areas] .= 1.0

  # 
  # Nova Scotia includes all hydro
  # 
  plants = Select(Plant,["PeakHydro","BaseHydro","Biomass","Biogas","OnshoreWind","OffshoreWind",
                         "SolarPV","SolarThermal","SmallHydro","Wave","Geothermal","Waste"])
  RnSwitch[plants,Select(Area,"NS")] .= 1.0

  # 
  # Ontario has only exogenous renewable construction
  # 
  RnBuildFr[Plants,Select(Area,"ON"),Years] .= 0.0
  RnOption[Select(Area,"ON"),Years] .= 0.0

  # 
  # Build to meet Contract Flows
  # 
  HDFlowFr[Nodes,NodeXs,Future:Final] .= 1.0

  # 
  # These limit the amount of renewable capacity which can be constructed
  # each year (not the total).  The system fraction (GrSysFr) is the amount
  # of Green Power which can be built in a single year as a fraction of the
  # system capacity.
  # 
  GrSysFr[Nodes,Areas,Yr(2020):Final] .= 0.050

  # 
  # A renewewable resource cannot be constructed without a non-zero
  # non-price factors (GrMSM).  The non-price factors are also used
  # to encourage one resource over another regardless of price.
  # 
  # Select the nodes in Canada and the relevant years
  # 
  areas = Select(Area,(from="ON",to="NU"))
  years = Yr(2010):Final

  # 
  # Renewable Plants Types which may be developed.
  # 
  GrMSM[Select(Plant,"OnshoreWind"),  Nodes,areas,years] .= 1.00
  GrMSM[Select(Plant,"OffshoreWind"), Nodes,areas,years] .= 1.00
  GrMSM[Select(Plant,"Biomass"),      Nodes,areas,years] .= 0.05
  GrMSM[Select(Plant,"SmallHydro"),   Nodes,areas,years] .= 1.00
  GrMSM[Select(Plant,"SolarPV"),      Nodes,areas,years] .= 1.00
  GrMSM[Select(Plant,"SolarThermal"), Nodes,areas,years] .= 0.10
  GrMSM[Select(Plant,"Biogas"),       Nodes,areas,years] .= 0.50

  # 
  # Renewable Plant Types considered not ready for development
  # 
  GrMSM[Select(Plant,"Geothermal"), Nodes,areas,years] .= 0.00
  GrMSM[Select(Plant,"Wave"),       Nodes,areas,years] .= 0.00
  GrMSM[Select(Plant,"FuelCell"),   Nodes,areas,years] .= 0.00

  # 
  # Lowered GrMSM for NB and QC due to overbuilding wind for export oct 9, 2020. John St-Laurent O'Connor
  # 
  areas = Select(Area,["NB","QC"])
  nodes = Select(Node,["NB","QC"])
  GrMSM[Select(Plant,"OnshoreWind"),  nodes,areas,years] .= 0.50
  GrMSM[Select(Plant,"OffshoreWind"), nodes,areas,years] .= 0.50
  GrMSM[Select(Plant,"Biomass"),      nodes,areas,years] .= 0.05
  GrMSM[Select(Plant,"SmallHydro"),   nodes,areas,years] .= 0.50
  GrMSM[Select(Plant,"SolarPV"),      nodes,areas,years] .= 0.50
  GrMSM[Select(Plant,"SolarThermal"), nodes,areas,years] .= 0.10
  GrMSM[Select(Plant,"Biogas"),       nodes,areas,years] .= 0.50

  GrVF .= 0-5.0

  CapCredit .= 1.00
  CapCredit[Select(Plant,["OnshoreWind","OffshoreWind"]), Areas,             Years]        .= 0.15
  CapCredit[Select(Plant,["SolarPV","SolarThermal"]),     Areas,             Years]        .= 0.0
  CapCredit[Select(Plant,["OnshoreWind","OffshoreWind"]), Select(Area,"QC"), Years]        .= 0.40
  CapCredit[Select(Plant,"PeakHydro"),                    Select(Area,"BC"), Future:Final] .= 0.60
  CapCredit[Select(Plant,"OnshoreWind"),                  Select(Area,"MB"), Future:Final] .= 0.40
  CapCredit[Select(Plant,"Battery"),                      Areas,             Future:Final] .= 0.25

  #
  # Updates for CER CGII allignment with NextGrid. V.Keller Jan 2024 **********************************************************************************************
  #
  years=collect(First:Final)
  for year in years, area in Areas
    CapCredit[Select(Plant,"Biomass"),area,year]=0.84
    CapCredit[Select(Plant,"FuelCell"),area,year]=0.88
    CapCredit[Select(Plant,"Coal"),area,year]=0.84
    CapCredit[Select(Plant,"CoalCCS"),area,year]=0.74
    CapCredit[Select(Plant,"Geothermal"),area,year]=0.85
    CapCredit[Select(Plant,"NGCCS"),area,year]=0.80
    CapCredit[Select(Plant,"Nuclear"),area,year]=0.90
    CapCredit[Select(Plant,"OGCC"),area,year]=0.88
    CapCredit[Select(Plant,"OGCT"),area,year]=0.89
    CapCredit[Select(Plant,"OGSteam"),area,year]=0.82
    CapCredit[Select(Plant,"Waste"),area,year]=0.84
    CapCredit[Select(Plant,"Wave"),area,year]=0.80
    CapCredit[Select(Plant,"SolarPV"),area,year]=0.0

    CapCredit[Select(Plant,"PeakHydro"),area,year]=0.90
    if Area[area] == "BC"
      CapCredit[Select(Plant,"PeakHydro"),area,year]=0.70
    end

    CapCredit[Select(Plant,"SmallHydro"),area,year]=0.90
    if Area[area] == "BC"
      CapCredit[Select(Plant,"SmallHydro"),area,year]=0.70
    end

    CapCredit[Select(Plant,"BaseHydro"),area,year]=0.80
    if Area[area] == "BC"
      CapCredit[Select(Plant,"BaseHydro"),area,year]=0.60
    end
  end

  plant=Select(Plant,"OnshoreWind")
  for year in years
    CapCredit[plant,Select(Area,"AB"),year]=0.17
    CapCredit[plant,Select(Area,"BC"),year]=0.23
    CapCredit[plant,Select(Area,"SK"),year]=0.11
    CapCredit[plant,Select(Area,"MB"),year]=0.32
    CapCredit[plant,Select(Area,"ON"),year]=0.21
    CapCredit[plant,Select(Area,"QC"),year]=0.34
    CapCredit[plant,Select(Area,"NB"),year]=0.27
    CapCredit[plant,Select(Area,"NS"),year]=0.10
    CapCredit[plant,Select(Area,"NL"),year]=0.24
    CapCredit[plant,Select(Area,"PE"),year]=0.25
  end

  plant=Select(Plant,"OffshoreWind")
  for year in years
    CapCredit[plant,Select(Area,"NB"),year]=0.27
  end


  #
  # CapCredit of Battery increased from 25% to 95% for attempting to better allign results 
  #
  plant=Select(Plant,"Battery")
  years=collect(Future:Final)
  for year in years, area in Areas
    CapCredit[plant,area,year]=0.95
  end

  #
  # CapCredit of PeakHydro changed to 78% for allignemnt with NextGrid -- A.Robertson July 11
  # Base on ON APO, for winter peaking
  #
  years=collect(Future:Final)
  area=Select(Area,"ON")
  plant=Select(Plant,"PeakHydro")
  for year in years
    CapCredit[plant,area,year]=0.78
  end

  WriteDisk(db,"EGInput/PjNSw",PjNSw)
  WriteDisk(db,"EInput/DRM",DRM)
  WriteDisk(db,"EGInput/BuildSw",BuildSw)
  WriteDisk(db,"EGInput/BuildFr",BuildFr)
  WriteDisk(db,"EGInput/BFracMax",BFracMax)
  WriteDisk(db,"EGInput/CUCLimit",CUCLimit)
  WriteDisk(db,"EGInput/PrDiFr",PrDiFr)
  WriteDisk(db,"EGInput/RnBuildFr",RnBuildFr)
  WriteDisk(db,"EGInput/RnFr",RnFr)
  WriteDisk(db,"EGInput/RnMSM",RnMSM)
  WriteDisk(db,"EGInput/RnOption",RnOption)
  WriteDisk(db,"EGInput/RnSwitch",RnSwitch)
  WriteDisk(db,"EGInput/RnVF",RnVF)
  WriteDisk(db,"EGInput/HDFlowFr",HDFlowFr)
  WriteDisk(db,"EGInput/GrSysFr",GrSysFr)
  WriteDisk(db,"EGInput/GrMSM",GrMSM)
  WriteDisk(db,"EGInput/GrVF",GrVF)
  WriteDisk(db,"EGInput/CapCredit",CapCredit)
  
end

function CalibrationControl(db)
  @info "UnitConstruction.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
