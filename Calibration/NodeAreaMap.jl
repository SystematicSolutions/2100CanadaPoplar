#
# NodeAreaMap.jl
#
using EnergyModel

module NodeAreaMap

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Nodes::Vector{Int} = collect(Select(Node))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ArNdFr::VariableArray{3} = ReadDisk(db,"EGInput/ArNdFr") # [Area,Node,Year] Fraction of the Area in each Node (MW/MW)
  NdArFr::VariableArray{3} = ReadDisk(db,"EGInput/NdArFr") # [Node,Area,Year] Fraction of the Node in each Area (MW/MW)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)
  NdArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdArMap") # [Node,Area] Map between Node and Area
  NdXArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdXArMap") # [NodeX,Area] Map between NodeX and Area
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  NdNMap::VariableArray{2} = ReadDisk(db,"EGInput/NdNMap") # [Node,Nation] Map between Node and Nation
  NdXNMap::VariableArray{2} = ReadDisk(db,"EGInput/NdXNMap") # [NodeX,Nation] Map between NodeX and Nation

  # Scratch Variables
  GCArea::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Generating Capacity (MW)
  GCNdAr::VariableArray{2} = zeros(Float32,length(Node),length(Area)) # [Node,Area] Generating Capacity (MW)
  GCNode::VariableArray{1} = zeros(Float32,length(Node)) # [Node] Generating Capacity (MW)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Areas,Nations,Node) = data
  (;Nodes,Units,Years) = data
  (;ArNdFr,NdArFr,UnArea,UnNode,xUnGC,NdArMap,NdXArMap,ANMap,NdNMap) = data
  (;NdXNMap) = data
  (;GCArea,GCNdAr,GCNode) = data

  #
  # Sum the Generating Capacity (xUnGC) across Node and Area (GCNdAr).
  # We use the year 2008 because we want to fix the fraction and not
  # have it changing each year.  Jeff Amlin 6/10/11
  #

  @. GCNdAr=0.0
  # for area in Areas,
  #   units=findall(UnArea[:] .== Area[area])
  #   if !isempty(units)
  #     for unit in units
  #       if UnArea[unit] == Area[area]
  #         if UnNode[unit] != "Null"
  #           node=Select(Node,UnNode[unit])
  #           GCNdAr[node,area]=GCNdAr[node,area]+xUnGC[unit,Yr(2008)]
  #         end
  #       end
  #     end
  #   end
  # end

  # TODOJulia Question for Jeff: I don't know if this is the best structure. I'd rather loop across all units,
  # and use more simple selection structure.

  for unit in Units
    if (UnArea[unit] != "Null") && (UnNode[unit] != "Null")
      area=Select(Area,UnArea[unit])
      node=Select(Node,UnNode[unit])
      GCNdAr[node,area]=GCNdAr[node,area]+xUnGC[unit,Yr(2008)]
    end
  end

  #
  # Patch for Mexico
  #
  area=Select(Area,"MX")
  node=Select(Node,"MX")
  GCNdAr[node,area]=1.0

  #
  # Calculate the fraction of Area demands going to each Node (ArNdFr).
  #
  for area in Areas
    GCArea[area]=sum(GCNdAr[node,area] for node in Nodes)
    for year in Years, node in Nodes
      @finite_math ArNdFr[area,node,year]=GCNdAr[node,area]/GCArea[area]
    end
  end
  WriteDisk(db,"EGInput/ArNdFr",ArNdFr)

  #
  # Calculate the fraction of Node demands going to each Area (NdArFr).
  #

  for node in Nodes
    GCNode[node]=sum(GCNdAr[node,area] for area in Areas)
    for year in Years, area in Areas
      @finite_math NdArFr[node,area,year]=GCNdAr[node,area]/GCNode[node]
    end
  end
  WriteDisk(db,"EGInput/NdArFr",NdArFr)

  #
  ########################
  #
  # Newfoundland is a significant exception
  # Fraction of Newfoundland Demand Going to Each Node (GWH/GWH)
  #
  # NL Splits calculated in 'NL Sales and Peak Load Inputs.xlsx' - Ian 09/10/13
  # 2015-2016 data updated by Hilary based on required Labrador sales after Churchill Falls + Exports.
  # Referencing Nalcor's 2017 Annual Report and NL Hydro's 2017 General Rate Application
  #
  area=Select(Area,"NL")
  nodes=Select(Node,["NL","LB"])
  years=collect(Yr(2005):Yr(2016))
  ArNdFr[area,nodes,years] .= [
    # 2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016
    0.7176  0.7086  0.7215  0.706   0.7168  0.6924  0.7176  0.7174  0.718   0.7462  0.7239  0.6222  # NL
    0.2824  0.2914  0.2785  0.294   0.2832  0.3076  0.2824  0.2826  0.282   0.2538  0.2761  0.3778  # LB
  ]

  years=collect(First:Yr(2004))
  for year in years, node in nodes
    ArNdFr[area,node,year]=ArNdFr[area,node,Yr(2005)]
  end

  years=collect(Yr(2017):Final)
  for year in years, node in nodes
    ArNdFr[area,node,year]=ArNdFr[area,node,Yr(2016)]
  end
  WriteDisk(db,"EGInput/ArNdFr",ArNdFr)

  #
  ########################
  #
  # The NdArMap is based on the NdArFr, but each node must be in one
  # and only one Area.  This is not reasonable for some implementations
  # and for those model the results of using this variable are incorrect.
  # J. Amlin 07/22/05
  #
  @. NdArMap=0
  @. NdXArMap=0
  for node in Nodes
    areas=collect(Select(Area))
    areas_sorted=areas[sortperm(NdArFr[node,areas,Future],rev=true)]
    area=first(areas_sorted)
    NdArMap[node,area]=1
    NdXArMap[node,area]=1
  end
  WriteDisk(db,"EGInput/NdArMap",NdArMap)
  WriteDisk(db,"EGInput/NdXArMap",NdXArMap)

  @. NdNMap=0
  @. NdXNMap=0
  for nation in Nations
    areas=findall(ANMap[:,nation] .== 1)
    nodes=findall(sum(NdArMap[:,area] for area in areas) .> 0)
    for node in nodes
      NdNMap[node,nation]=1
    end
    nodexs=findall(sum(NdXArMap[:,area] for area in areas) .> 0)
    for nodex in nodexs
      NdXNMap[nodex,nation]=1
    end
  end

  WriteDisk(db,"EGInput/NdNMap",NdNMap)
  WriteDisk(db,"EGInput/NdXNMap",NdXNMap)

end

function CalibrationControl(db)
  @info "NodeAreaMap.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
