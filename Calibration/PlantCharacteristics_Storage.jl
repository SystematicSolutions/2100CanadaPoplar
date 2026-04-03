#
# PlantCharacteristics_Storage.jl
#
using EnergyModel

module PlantCharacteristics_Storage

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
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GCExpSw::VariableArray{3} = ReadDisk(db,"EGInput/GCExpSw") # [Plant,Area,Year] Generation Capacity Expansion Switch
  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") # [Plant,Area] Maximum Project Size (MW)
  PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") # [Plant,Area] Minimum Project Size (MW)
  StorageEfficiency::VariableArray{3} = ReadDisk(db,"EGInput/StorageEfficiency") # [Plant,Area,Year] Storage Efficiency (GWh/GWh)
  StorageFraction::VariableArray{3} = ReadDisk(db,"EGInput/StorageFraction") # [Plant,Area,Year] Storage as a Fraction of Wind Developed (MW/MW)
  TPRMap::VariableArray{2} = ReadDisk(db,"EGInput/TPRMap") # [TimeP,Power] TimeP to Power Map
  # xGCPot::VariableArray{4} = ReadDisk(db,"EGInput/xGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Months,Node,Plant) = data
  (;Power,Powers,TimePs) = data
  (;GCExpSw,PjMax,PjMnPS,StorageEfficiency,StorageFraction,TPRMap) = data
  # (;xGCPot) = data


  plant=Select(Plant,"Battery")

  areas=Select(Area,["ON","QC","BC","AB","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  years=collect(Yr(2023):Final)

  #
  # Control Variables
  #
  # for year in years, area in areas, node in nodes
  #   xGCPot[plant,node,area,year]=1E6
  # end
  for year in years, area in areas
    StorageFraction[plant,area,year]=0.0
  end
  WriteDisk(db,"EGInput/StorageFraction",StorageFraction)
  # WriteDisk(db,"EGInput/xGCPot",xGCPot)

  #
  # Parametere for text files
  #
  for year in years, area in areas
    GCExpSw[plant,area,year]=4
  end
  for year in years, area in areas
    StorageEfficiency[plant,area,year]=0.85
  end
  for area in areas
    PjMax[plant,area]=10000
    PjMnPS[plant,area]=1
  end
  
  WriteDisk(db,"EGInput/GCExpSw",GCExpSw)
  WriteDisk(db,"EGInput/PjMax",PjMax)
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)
  WriteDisk(db,"EGInput/StorageEfficiency",StorageEfficiency)

end

function CalibrationControl(db)
  @info "PlantCharacteristics_Storage.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
