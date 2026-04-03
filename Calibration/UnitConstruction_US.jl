#
# UnitConstruction_US.jl
#
using EnergyModel

module UnitConstruction_US

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
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ArGenFr::VariableArray{3} = ReadDisk(db,"EGInput/ArGenFr") # [Area,GenCo,Year] Fraction of the Area going to each GenCo
  ArNdFr::VariableArray{3} = ReadDisk(db,"EGInput/ArNdFr") # [Area,Node,Year] Fraction of the Area in each Node (Fraction)
  GrMSM::VariableArray{4} = ReadDisk(db,"EGInput/GrMSM") # [Plant,Node,Area,Year] Green Power Market Share Non-Price Factors (MW/MW)
  GrSysFr::VariableArray{3} = ReadDisk(db,"EGInput/GrSysFr") # [Node,Area,Year] Green Power Capacity as Fraction of System (MW/MW)
  HRtM::VariableArray{3} = ReadDisk(db,"EGInput/HRtM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  OGCCFraction::VariableArray{2} = ReadDisk(db,"EGInput/OGCCFraction") # [Area,Year] Fraction of new OG capacity which is OGCC (MW/MW)
  RnFr::VariableArray{2} = ReadDisk(db,"EGInput/RnFr") # [Area,Year] Renewable Fraction (GWh/GWh)
  RnGoalSwitch::VariableArray{2} = ReadDisk(db,"EGInput/RnGoalSwitch") # [Area,Year] Renewable Generation Goal Switch (0=Sales, 1=New Capacity)
  RnOption::VariableArray{2} = ReadDisk(db,"EGInput/RnOption") # [Area,Year] Renewable  (1=Local RPS, 2=Regional RPS, 3=FIT)
  RnMSM::VariableArray{5} = ReadDisk(db,"EGInput/RnMSM") # [Plant,Node,GenCo,Area,Year] Renewable Market Share Non-Price Factors (GWh/GWh)
  RnVF::VariableArray{2} = ReadDisk(db,"EGInput/RnVF") # [Area,Year] Renewable Market Share Variance Factor ($/$)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xGCPot::VariableArray{4} = ReadDisk(db,"EGInput/xGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
  xUnGCCI::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCI") # [Unit,Year] Generating Capacity Initiated (MW)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Areas,GenCo,GenCos,Nation) = data
  (;Nodes,Plant,Plants,Years) = data
  (;ANMap,ArNdFr,HRtM,xGCPot,xUnGCCI,UnNation,UnPlant,OGCCFraction,RnFr,RnGoalSwitch) = data
  (;RnOption,ArGenFr,RnMSM,RnVF,GrSysFr,GrMSM) = data

  # 
  # https://www.eia.gov/outlooks/aeo/assumptions/pdf/table_8.2.pdf
  # 
  OGCT = Select(Plant, "OGCT")
  for area in Areas, year in Future:Final
    HRtM[OGCT,area,year] = 9800
  end

  # 
  # Potential Capacities
  # 

  # 
  # Remove default future exogenous capacity expansion
  # 
  us_units = findall(UnNation .== "US")
  not_units = ["Nuclear","OGSteam","OnshoreWind","Battery","PeakHydro","Geothermal","OffshoreWind"]
  unit2 = findall(s -> !(s in not_units), UnPlant)
  units = intersect(us_units, unit2)
  for unit in units, year in Yr(2021):Final
    xUnGCCI[unit,year] = 0
  end

  US = Select(Nation,"US")
  us_areas = findall(ANMap[:,US] .== 1.0)
  for area in us_areas

    for year in Yr(2017):Yr(2033)
      OGCCFraction[area,year] = 0.40
    end

    for year in Yr(2034):Yr(2039)
      OGCCFraction[area,year] = 3.50
    end

    for year in Yr(2040):Yr(2050)
      OGCCFraction[area,year] = 2.00
    end
  end

  # 
  # Existing RPS programs from EPA GHG documentation. Weighted into regions
  # in 'Default US RPS.xlsx' - Ian 06/10/14
  # CA added as duplicate of Pac - R.Levesque 06/28/2015
  #                                               2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030 
  RnFr[Select(Area,"CA"),   Yr(2012):Yr(2030)] = [0.0280, 0.0560, 0.0840, 0.1120, 0.1400, 0.1680, 0.1960, 0.2239, 0.2519, 0.2538, 0.2557, 0.2576, 0.2594, 0.2613, 0.2617, 0.2621, 0.2625, 0.2629, 0.2633]
  RnFr[Select(Area,"NEng"), Yr(2012):Yr(2030)] = [0.0314, 0.0628, 0.0942, 0.1256, 0.1570, 0.1884, 0.2105, 0.2325, 0.2546, 0.2607, 0.2668, 0.2729, 0.2790, 0.2851, 0.2893, 0.2935, 0.2976, 0.3018, 0.3060]
  RnFr[Select(Area,"MAtl"), Yr(2012):Yr(2030)] = [0.0325, 0.0650, 0.0976, 0.1301, 0.1382, 0.1464, 0.1545, 0.1627, 0.1708, 0.1737, 0.1737, 0.1737, 0.1737, 0.1737, 0.1737, 0.1737, 0.1737, 0.1737, 0.1737]
  RnFr[Select(Area,"ENC"),  Yr(2012):Yr(2030)] = [0.0148, 0.0296, 0.0445, 0.0593, 0.0670, 0.0748, 0.0825, 0.0902, 0.0980, 0.1058, 0.1136, 0.1214, 0.1292, 0.1348, 0.1348, 0.1348, 0.1348, 0.1348, 0.1348]
  RnFr[Select(Area,"WNC"),  Yr(2012):Yr(2030)] = [0.0119, 0.0238, 0.0357, 0.0476, 0.0595, 0.0714, 0.0833, 0.0952, 0.1071, 0.1200, 0.1200, 0.1200, 0.1200, 0.1200, 0.1200, 0.1200, 0.1200, 0.1200, 0.1200]
  RnFr[Select(Area,"SAtl"), Yr(2012):Yr(2030)] = [0.0030, 0.0060, 0.0091, 0.0121, 0.0151, 0.0181, 0.0211, 0.0242, 0.0272, 0.0326, 0.0332, 0.0333, 0.0333, 0.0334, 0.0334, 0.0335, 0.0335, 0.0335, 0.0335]
  RnFr[Select(Area,"ESC"),  Yr(2012):Yr(2030)] = [0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000]
  RnFr[Select(Area,"WSC"),  Yr(2012):Yr(2030)] = [0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000]
  RnFr[Select(Area,"Mtn"),  Yr(2012):Yr(2030)] = [0.0159, 0.0317, 0.0476, 0.0634, 0.0761, 0.0889, 0.1016, 0.1143, 0.1270, 0.1307, 0.1344, 0.1381, 0.1418, 0.1455, 0.1455, 0.1455, 0.1455, 0.1455, 0.1455]
  RnFr[Select(Area,"Pac"),  Yr(2012):Yr(2030)] = [0.0280, 0.0560, 0.0840, 0.1120, 0.1400, 0.1680, 0.1960, 0.2239, 0.2519, 0.2538, 0.2557, 0.2576, 0.2594, 0.2613, 0.2617, 0.2621, 0.2625, 0.2629, 0.2633]

  us_gencos = Select(GenCo,(from = "CA", to = "Pac"))
  rn_plants = Select(Plant,["Biomass","Biogas","OnshoreWind","OffshoreWind","SolarThermal","SmallHydro","Wave"])
  
  for area in us_areas

    for year in Yr(2031):Final
      RnFr[area,year] = RnFr[area,Yr(2030)]
    end

    # 
    # Interpolate Renewable Goal to match AEO 2019
    # 
    RnFr[area,Yr(2017)] = 0
    RnFr[area,Yr(2050)] = 0

    for year in Yr(2018):Final
      RnFr[area,year] = RnFr[area,year-1] + (RnFr[area,Yr(2050)]-RnFr[area,Yr(2017)]) / (2050 - 2017)
    end

    # 
    # Renewable generation goal calculated as fraction of sales
    # 
    for year in Years
      RnGoalSwitch[area,year] = 1
    end

    # 
    # Renewables must be built inside the area (RnOption=1) 
    # 
    for year in Yr(2021):Final
      RnOption[area,year] = 1

      # 
      # Initialize RnMSM to zero for US Areas and Nodes
      # 
      for plant in Plants, node in Nodes, genco in us_gencos
        if sum(ArNdFr[a,node,year] for a in us_areas) > 0
          RnMSM[plant,node,genco,area,year] = 0.00
        end
      end

      # 
      # Non-Price Factors for Renewable Plant Types
      # 
      for node in Nodes, genco in GenCos
        if ArGenFr[area,genco,year] > 0 && ArNdFr[area,node,year] > 0
          RnMSM[Select(Plant,"SolarPV"),node,genco,area,year] = 1.00
          for plant in rn_plants
            RnMSM[plant,node,genco,area,year] = 0.0005
          end
        end
      end

      # 
      # Renewable Variance Factor (sensitivity to prices)
      # 
      RnVF[area,year] = 0-5.0
    end

    # 
    # These limit the amount of renewable capacity which can be constructed
    # each year (not the total). The system fraction (GrSysFr) is the amount
    # of Green Power which can be built in a single year as a fraction of the
    # system capacity.
    # 
    for node in Nodes

      if sum(ArNdFr[a,node,Yr(2050)] for a in us_areas) > 0
        GrSysFr[node,area,Yr(2050)] = 0.050
      end

      for year in Yr(2021):Final

        if sum(ArNdFr[a,node,year] for a in us_areas) > 0
          GrSysFr[node,area,year] = GrSysFr[node,area,year-1] +
                                    (GrSysFr[node,area,Yr(2050)]-GrSysFr[node,area,Yr(2020)]) / (2050-2020)

          #
          #  Most new renewables in AEO 2019 are Solar PV - Jeff Amlin 04/29/19
          # 
          GrMSM[Select(Plant,"SolarPV"),node,area,year] = 1.00
          for plant in rn_plants
            GrMSM[plant,node,area,year] = 0.0005
          end
        end
      end
    end
  end

  WriteDisk(db,"EGInput/GrMSM",GrMSM)
  WriteDisk(db,"EGInput/GrSysFr",GrSysFr)
  WriteDisk(db,"EGInput/HRtM",HRtM)
  WriteDisk(db,"EGInput/OGCCFraction",OGCCFraction)
  WriteDisk(db,"EGInput/RnFr",RnFr)
  WriteDisk(db,"EGInput/RnGoalSwitch",RnGoalSwitch)
  WriteDisk(db,"EGInput/RnOption",RnOption)
  WriteDisk(db,"EGInput/RnMSM",RnMSM)
  WriteDisk(db,"EGInput/RnVF",RnVF)
  WriteDisk(db,"EGInput/xGCPot",xGCPot)
  WriteDisk(db,"EGInput/xUnGCCI",xUnGCCI)

end

function CalibrationControl(db)
  @info "UnitConstruction_US.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
