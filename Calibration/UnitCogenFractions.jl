#
# UnitCogenFractions.jl - Plant and Node Fractions for Endogenous Cogeneration Units
#
using EnergyModel

module UnitCogenFractions

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CCalib
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgElectricFraction::VariableArray{4} = ReadDisk(db,"$Input/CgElectricFraction") # [Plant,EC,Area,Year] Cogeneration Electric Tech to Plant Fraction (MW/MW)
  CgPlantFraction::VariableArray{3} = ReadDisk(db,"$Input/CgPlantFraction") # [Tech,Plant,Year] Cogeneration Tech to Plant Fraction (MW/MW)
  CgNodeFraction::VariableArray{4} = ReadDisk(db,"$Input/CgNodeFraction") # [EC,Node,Area,Year] Cogeneration EC and Area to Node Fraction (MW/MW)
end

function CCalibration(db)
  data = CCalib(; db)
  (;Area,ECs,Nation,Node) = data
  (;Nodes,Plant,Plants,Tech,Techs,Years,Input) = data
  (;ANMap,CgElectricFraction,CgPlantFraction,CgNodeFraction) = data

  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  # 
  # Initialize Values
  # 
  for plant in Plants, ec in ECs, area in cn_areas, year in Years
    CgElectricFraction[plant,ec,area,year] = 0
  end

  # 
  # Default Values
  # 
  for ec in ECs, area in cn_areas, year in Years
    CgElectricFraction[Select(Plant,"OnshoreWind"),ec,area,year] = 1
    CgElectricFraction[Select(Plant,"BaseHydro"),ec,area,year] = 0
  end

  # 
  # Initialize Values
  # 
  for tech in Techs, plant in Plants, year in Years
    CgPlantFraction[tech,plant,year] = 0
  end

  # 
  # Default Values
  # 
  for ec in ECs, area in cn_areas, year in Years
    CgPlantFraction[Select(Tech,"Gas"),      Select(Plant,"OGCC"),     year] = 1
    CgPlantFraction[Select(Tech,"Coal"),     Select(Plant,"Coal"),     year] = 1
    CgPlantFraction[Select(Tech,"Oil"),      Select(Plant,"OGSteam"),  year] = 1
    CgPlantFraction[Select(Tech,"Biomass"),  Select(Plant,"Biomass"),  year] = 1
    CgPlantFraction[Select(Tech,"Solar"),    Select(Plant,"SolarPV"),  year] = 1
    CgPlantFraction[Select(Tech,"LPG"),      Select(Plant,"OGSteam"),  year] = 1
    CgPlantFraction[Select(Tech,"FuelCell"), Select(Plant,"FuelCell"), year] = 1
  end

  # 
  # Initialize Values
  # 
  for ec in ECs, node in Nodes, area in cn_areas, year in Years
    CgNodeFraction[ec,node,area,year] = 0
  end

  # 
  # Default Values
  # 
  for ec in ECs
    for area in cn_areas
      node = Select(Node,Area[area])
      for year in Years
        CgNodeFraction[ec,node,area,year] = 1
      end
    end
  end

  WriteDisk(db,"$Input/CgElectricFraction",CgElectricFraction)
  WriteDisk(db,"$Input/CgPlantFraction",CgPlantFraction)
  WriteDisk(db,"$Input/CgNodeFraction",CgNodeFraction)

end

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgElectricFraction::VariableArray{4} = ReadDisk(db,"$Input/CgElectricFraction") # [Plant,EC,Area,Year] Cogeneration Electric Tech to Plant Fraction (MW/MW)
  CgPlantFraction::VariableArray{3} = ReadDisk(db,"$Input/CgPlantFraction") # [Tech,Plant,Year] Cogeneration Tech to Plant Fraction (MW/MW)
  CgNodeFraction::VariableArray{4} = ReadDisk(db,"$Input/CgNodeFraction") # [EC,Node,Area,Year] Cogeneration EC and Area to Node Fraction (MW/MW)
end

function ICalibration(db)
  data = ICalib(; db)
  (;Area,EC,ECs,Nation,Node) = data
  (;Nodes,Plant,Plants,Tech,Techs,Years,Input) = data
  (;ANMap,CgElectricFraction,CgPlantFraction,CgNodeFraction) = data

  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  # 
  # Initialize Values
  # 
  for plant in Plants, ec in ECs, area in cn_areas, year in Years
    CgElectricFraction[plant,ec,area,year] = 0
  end

  # 
  # Default Values
  # 
  for ec in ECs, area in cn_areas, year in Years
    CgElectricFraction[Select(Plant,"OnshoreWind"),ec,area,year] = 1
    CgElectricFraction[Select(Plant,"BaseHydro"),ec,area,year] = 0
  end

  # 
  # Exceptions
  # 
  ecs = Select(EC,["PulpPaperMills","IronSteel","Aluminum","OtherNonferrous","OtherMetalMining"])
  for ec in ecs, area in Select(Area,["QC","BC"]), year in Years
    CgElectricFraction[Select(Plant,"OnshoreWind"),ec,area,year] = 0
    CgElectricFraction[Select(Plant,"BaseHydro"),ec,area,year] = 1
  end

  # 
  # Initialize Values
  # 
  for tech in Techs, plant in Plants, year in Years
    CgPlantFraction[tech,plant,year] = 0
  end

  # 
  # Default Values
  # 
  for ec in ECs, area in cn_areas, year in Years
    CgPlantFraction[Select(Tech,"Gas"),      Select(Plant,"OGCC"),     year] = 1
    CgPlantFraction[Select(Tech,"Coal"),     Select(Plant,"Coal"),     year] = 1
    CgPlantFraction[Select(Tech,"Oil"),      Select(Plant,"OGSteam"),  year] = 1
    CgPlantFraction[Select(Tech,"Biomass"),  Select(Plant,"Biomass"),  year] = 1
    CgPlantFraction[Select(Tech,"Solar"),    Select(Plant,"SolarPV"),  year] = 1
    CgPlantFraction[Select(Tech,"LPG"),      Select(Plant,"OGSteam"),  year] = 1
    CgPlantFraction[Select(Tech,"FuelCell"), Select(Plant,"FuelCell"), year] = 1
  end

  # 
  # Initialize Values
  # 
  for ec in ECs, node in Nodes, area in cn_areas, year in Years
    CgNodeFraction[ec,node,area,year] = 0
  end

  # 
  # Default Values
  # 
  for ec in ECs
    for area in cn_areas
      node = Select(Node,Area[area])
      for year in Years
        CgNodeFraction[ec,node,area,year] = 1
      end
    end
  end

  NL = Select(Area,"NL")
  ecs = Select(EC,["OtherMetalMining","OtherNonferrous"])
  LB = Select(Node,"LB")
  for ec in ecs, year in Years
    for node in Nodes
      CgNodeFraction[ec,node,NL,year] = 0
    end
    CgNodeFraction[ec,LB,NL,year] = 1
  end

  WriteDisk(db,"$Input/CgElectricFraction",CgElectricFraction)
  WriteDisk(db,"$Input/CgPlantFraction",CgPlantFraction)
  WriteDisk(db,"$Input/CgNodeFraction",CgNodeFraction)

end

function CalibrationControl(db)
  @info "UnitCogenFractions.jl - CalibrationControl"

  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
