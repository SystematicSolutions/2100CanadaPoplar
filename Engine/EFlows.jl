#
# EFlows.jl
#

module EFlows

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime,finite_inverse

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/Area")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/Month")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/Nation")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/Node")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeX")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaPurchases::VariableArray{1} = ReadDisk(db,"EGOutput/AreaPurchases",year) #[Area,Year]  Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{1} = ReadDisk(db,"EGOutput/AreaSales",year) #[Area,Year]  Sales to Areas in the same Country (GWh/Yr)
  ExpPurchases::VariableArray{1} = ReadDisk(db,"EGOutput/ExpPurchases",year) #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{1} = ReadDisk(db,"EGOutput/ExpSales",year) #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HDLLoad::VariableArray{4} = ReadDisk(db,"EGOutput/HDLLoad",year) #[Node,NodeX,TimeP,Month,Year]  Loading on Transmission Lines (MW)
  LLEff::VariableArray{2} = ReadDisk(db,"EGInput/LLEff",year) #[Node,NodeX,Year]  Transmission Line Efficiency (MW/MW)
  LLGen::VariableArray{4} = ReadDisk(db,"EGOutput/LLGen",year) #[Node,NodeX,TimeP,Month,Year]  Generation through Transmission Lines (GWh)
  NdArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdArMap") #[Node,Area]  Map between Node and Area
  NdNMap::VariableArray{2} = ReadDisk(db,"EGInput/NdNMap") #[Node,Nation]  Map between Node and Nation
  NdXArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdXArMap") #[NodeX,Area]  Map between NodeX and Area
  NdXNMap::VariableArray{2} = ReadDisk(db,"EGInput/NdXNMap") #[NodeX,Nation]  Map between NodeX and Nation

  TempLoad::VariableArray{2} = zeros(Float32,length(Node),length(NodeX))
end

function GenerationFlows(data::Data)
  (; db,year) = data
  (; Nodes,NodeXs,Months,TimePs) = data
  (; HDHours,HDLLoad,LLGen,TempLoad) = data

  for node in Nodes, nodex in NodeXs, timep in TimePs, month in Months
     LLGen[node,nodex,timep,month] = HDLLoad[node,nodex,timep,month]*
       HDHours[timep,month]/1000
  end

  WriteDisk(db,"EGOutput/LLGen",year,LLGen)

  for node in Nodes, nodex in NodeXs
    TempLoad[node,nodex] = sum(HDLLoad[node,nodex,timep,month]*
      HDHours[timep,month] for timep in TimePs, month in Months)/1000
  end

end

function IntraCountrySales(data::Data,nation,area)
  (; db,year) = data
  (; AreaSales,NdXArMap,NdNMap,NdArMap,TempLoad) = data

  #
  # Sales from this Area to other Areas in the same country
  #
  nodexs = findall(NdXArMap[:,area] .==1)
  nodes = findall(NdNMap[:,nation] .==1)
  if !isempty(nodes) && !isempty(nodexs)
    AreaSales[area] = sum(TempLoad[node,nodex] for node in nodes, nodex in nodexs)
  end

  #
  # Remove sales between two nodes in the same Area
  #
  nodes = findall(NdArMap[:,area] .==1)
  nodexs = findall(NdXArMap[:,area] .==1)
  if !isempty(nodes) && !isempty(nodexs)
    AreaSales[area] = AreaSales[area]-sum(TempLoad[node,nodex] for node in nodes, nodex in nodexs)
  end

  WriteDisk(db,"EGOutput/AreaSales",year,AreaSales)
end

function InterCountrySales(data::Data,nation,area)
  (; db,year) = data
  (; ExpSales,NdXArMap,NdNMap,TempLoad) = data

  #
  # Sales from this Area to other Areas in a different county
  #
  nodexs = findall(NdXArMap[:,area] .==1)
  nodes = findall(NdNMap[:,nation] .==0)
  if !isempty(nodes) && !isempty(nodexs)
    ExpSales[area] = sum(TempLoad[node,nodex] for node in nodes, nodex in nodexs)
  end

  WriteDisk(db,"EGOutput/ExpSales",year,ExpSales)
end

function IntraCountryPurchases(data::Data,nation,area)
  (; db,year) = data
  (; AreaPurchases,LLEff,NdArMap,NdXNMap,NdXArMap,TempLoad) = data

  #
  # Purchases by this Area from other Areas in the same country
  #
  nodexs = findall(NdXNMap[:,nation] .==1)
  nodes = findall(NdArMap[:,area] .==1)
  if !isempty(nodes) && !isempty(nodexs)
    AreaPurchases[area] = sum(TempLoad[node,nodex]*LLEff[node,nodex] for node in nodes, nodex in nodexs)
  end
  
  #
  # Remove purchases between two nodes in the same Area
  #
  nodes = findall(NdArMap[:,area] .==1)
  nodexs = findall(NdXArMap[:,area] .==1)
  if !isempty(nodes) && !isempty(nodexs)
    AreaPurchases[area] = AreaPurchases[area]-sum(TempLoad[node,nodex]*LLEff[node,nodex] for node in nodes, nodex in nodexs)
  end

  WriteDisk(db,"EGOutput/AreaPurchases",year,AreaPurchases)
end

function InterCountryPurchases(data::Data,nation,area)
  (; db,year) = data
  (; ExpPurchases,LLEff,NdArMap,NdXNMap,TempLoad) = data

  #
  # Purchases by this Area from other Areas in a different country
  #
  nodes = findall(NdArMap[:,area] .==1)
  nodexs = findall(NdXNMap[:,nation] .==0)
  if !isempty(nodes) && !isempty(nodexs)
      ExpPurchases[area] = sum(TempLoad[node,nodex]*LLEff[node,nodex] for node in nodes, nodex in nodexs)
  end

  WriteDisk(db,"EGOutput/ExpPurchases",year,ExpPurchases)
end

function Flows(data::Data)
  (; Nation) = data
  (; ANMap) = data

  # @info "  EFlows.jl - Flows"

  GenerationFlows(data)

  for nation in Select(Nation)
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      IntraCountrySales(data,nation,area)
      InterCountrySales(data,nation,area)
      IntraCountryPurchases(data,nation,area)
      InterCountryPurchases(data,nation,area)
    end
  end
end

end # module EFlows
