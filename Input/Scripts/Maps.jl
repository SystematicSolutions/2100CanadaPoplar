#
# Maps.jl
#
using EnergyModel

module Maps

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaX::SetArray = ReadDisk(db,"MainDB/AreaXKey")
  AreaXDS::SetArray = ReadDisk(db,"MainDB/AreaXDS")
  AreaXs::Vector{Int} = collect(Select(AreaX))
  Areas::Vector{Int} = collect(Select(Area))
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  CNAreaDS::SetArray = ReadDisk(db,"MainDB/CNAreaDS")
  CNAreas::Vector{Int} = collect(Select(CNArea))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  NationX::SetArray = ReadDisk(db,"MainDB/NationXKey")
  NationXDS::SetArray = ReadDisk(db,"MainDB/NationXDS")
  NationXs::Vector{Int} = collect(Select(NationX))
  Nations::Vector{Int} = collect(Select(Nation))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation (Map)
  AXNXMap::VariableArray{2} = ReadDisk(db,"SInput/AXNXMap") # [AreaX,NationX] Map between AreaX and NationX (Map)
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") # [Area,CNArea] Map between Area and Canada Economic Areas (CNArea)
  GPRAMap::VariableArray{4} = ReadDisk(db,"SpInput/GPRAMap") # [Area,Process,Nation,Year] Provincial Gas Fraction (Btu/Btu)
  OPrAMap::VariableArray{4} = ReadDisk(db,"SpInput/OPrAMap") # [Area,Process,Nation,Year] Provincial Oil Fraction (Btu/Btu)
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,AreaDS,AreaX,AreaXDS,Nation,Processes,Years) = data
  (;ANMap,AXNXMap,CNAMap,GPRAMap,OPrAMap,vAreaMap) = data

  AXNXMap .= ANMap

  AreaXDS .= AreaDS
  AreaX   .= Area

  # 
  # Map between Area and VBInput Areas
  # 
  vAreaMap .= 0
  areas = Select(Area,["AB","BC","MB","ON","QC","SK","NS","NL","NB","PE","YT","NT","NU"])
  vAreaCount=1
  for area in areas
    vAreaMap[area,vAreaCount] = 1
    vAreaCount = vAreaCount+1
  end

  WSC = Select(Area, "WSC")
  US = Select(Nation,"US")
  MX = Select(Area, "MX")
  MX2 = Select(Nation,"MX")
  for process in Processes, year in Years
    
    # 
    # All US oil and gas production is assumed to be in Texas (West South Central)
    # 
    GPRAMap[WSC,process,US,year] = 1
    OPrAMap[WSC,process,US,year] = 1

    #
    # Mexico has only one Area
    #
    GPRAMap[MX,process,MX2,year] = 1
    OPrAMap[MX,process,MX2,year] = 1
  end

  WriteDisk(db, "SInput/AXNXMap", AXNXMap)
  WriteDisk(db, "MainDB/AreaXDS", AreaXDS)
  WriteDisk(db, "MainDB/AreaXKey", AreaX)
  WriteDisk(db, "MainDB/vAreaMap", vAreaMap)
  WriteDisk(db, "SpInput/GPRAMap", GPRAMap)
  WriteDisk(db, "SpInput/OPrAMap", OPrAMap)

end

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
  GenCos::Vector{Int} = collect(Select(GenCo))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ArGenFr::VariableArray{3} = ReadDisk(db,"EGInput/ArGenFr") # [Area,GenCo,Year] Fraction of the Area going to each GenCo
  ArGenMap::VariableArray{2} = ReadDisk(db,"EGInput/ArGenMap") # [Area,GenCo] Area from which GenCo gets Prices (Map)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,GenCo,Years) = data
  (;ArGenFr,ArGenMap) = data

  ArGenFr .= 0
  for year in Years
    ArGenFr[Select(Area,"ON"),   Select(GenCo,"ON"),   year] = 1
    ArGenFr[Select(Area,"QC"),   Select(GenCo,"QC"),   year] = 1
    ArGenFr[Select(Area,"BC"),   Select(GenCo,"BC"),   year] = 1
    ArGenFr[Select(Area,"AB"),   Select(GenCo,"AB"),   year] = 1
    ArGenFr[Select(Area,"MB"),   Select(GenCo,"MB"),   year] = 1
    ArGenFr[Select(Area,"SK"),   Select(GenCo,"SK"),   year] = 1
    ArGenFr[Select(Area,"NB"),   Select(GenCo,"NB"),   year] = 1
    ArGenFr[Select(Area,"NS"),   Select(GenCo,"NS"),   year] = 1
    ArGenFr[Select(Area,"NL"),   Select(GenCo,"NL"),   year] = 1
    ArGenFr[Select(Area,"PE"),   Select(GenCo,"PE"),   year] = 1
    ArGenFr[Select(Area,"YT"),   Select(GenCo,"YT"),   year] = 1
    ArGenFr[Select(Area,"NT"),   Select(GenCo,"NT"),   year] = 1
    ArGenFr[Select(Area,"NU"),   Select(GenCo,"NU"),   year] = 1
    ArGenFr[Select(Area,"CA"),   Select(GenCo,"CA"),   year] = 1
    ArGenFr[Select(Area,"Pac"),  Select(GenCo,"Pac"),  year] = 1
    ArGenFr[Select(Area,"Mtn"),  Select(GenCo,"Mtn"),  year] = 1
    ArGenFr[Select(Area,"WNC"),  Select(GenCo,"WNC"),  year] = 1
    ArGenFr[Select(Area,"ENC"),  Select(GenCo,"ENC"),  year] = 1
    ArGenFr[Select(Area,"NEng"), Select(GenCo,"NEng"), year] = 1
    ArGenFr[Select(Area,"SAtl"), Select(GenCo,"SAtl"), year] = 1
    ArGenFr[Select(Area,"MAtl"), Select(GenCo,"MAtl"), year] = 1
    ArGenFr[Select(Area,"WSC"),  Select(GenCo,"WSC"),  year] = 1
    ArGenFr[Select(Area,"ESC"),  Select(GenCo,"ESC"),  year] = 1
    ArGenFr[Select(Area,"MX"),   Select(GenCo,"MX"),   year] = 1
  end

  ArGenMap .= 0
  ArGenMap[Select(Area,"ON"),   Select(GenCo,"ON")]   = 1
  ArGenMap[Select(Area,"QC"),   Select(GenCo,"QC")]   = 1
  ArGenMap[Select(Area,"BC"),   Select(GenCo,"BC")]   = 1
  ArGenMap[Select(Area,"AB"),   Select(GenCo,"AB")]   = 1
  ArGenMap[Select(Area,"MB"),   Select(GenCo,"MB")]   = 1
  ArGenMap[Select(Area,"SK"),   Select(GenCo,"SK")]   = 1
  ArGenMap[Select(Area,"NB"),   Select(GenCo,"NB")]   = 1
  ArGenMap[Select(Area,"NS"),   Select(GenCo,"NS")]   = 1
  ArGenMap[Select(Area,"NL"),   Select(GenCo,"NL")]   = 1
  ArGenMap[Select(Area,"PE"),   Select(GenCo,"PE")]   = 1
  ArGenMap[Select(Area,"YT"),   Select(GenCo,"YT")]   = 1
  ArGenMap[Select(Area,"NT"),   Select(GenCo,"NT")]   = 1
  ArGenMap[Select(Area,"NU"),   Select(GenCo,"NU")]   = 1
  ArGenMap[Select(Area,"CA"),   Select(GenCo,"CA")]   = 1
  ArGenMap[Select(Area,"Pac"),  Select(GenCo,"Pac")]  = 1
  ArGenMap[Select(Area,"Mtn"),  Select(GenCo,"Mtn")]  = 1
  ArGenMap[Select(Area,"WNC"),  Select(GenCo,"WNC")]  = 1
  ArGenMap[Select(Area,"ENC"),  Select(GenCo,"ENC")]  = 1
  ArGenMap[Select(Area,"NEng"), Select(GenCo,"NEng")] = 1
  ArGenMap[Select(Area,"SAtl"), Select(GenCo,"SAtl")] = 1
  ArGenMap[Select(Area,"MAtl"), Select(GenCo,"MAtl")] = 1
  ArGenMap[Select(Area,"WSC"),  Select(GenCo,"WSC")]  = 1
  ArGenMap[Select(Area,"ESC"),  Select(GenCo,"ESC")]  = 1
  ArGenMap[Select(Area,"MX"),   Select(GenCo,"MX")]   = 1

  WriteDisk(db, "EGInput/ArGenFr", ArGenFr)
  WriteDisk(db, "EGInput/ArGenMap", ArGenMap)
  
end

function CalibrationControl(db)
  @info "Maps.jl - CalibrationControl"

  SCalibration(db)
  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
