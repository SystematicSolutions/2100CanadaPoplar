#
# zFlows.jl
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct zFlowsData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimeP")
  TimePs::Vector{Int} = collect(Select(TimeP))
  TimePDS::SetArray = ReadDisk(db,"MainDB/TimePDS")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month] Number of Hours in the Interval (Hours)
  HDHoursRef::VariableArray{2} = ReadDisk(RefNameDB,"EInput/HDHours") #[TimeP,Month] Number of Hours in the Interval (Hours)
  HDLLoad::VariableArray{5} = ReadDisk(db,"EGOutput/HDLLoad") #[Node,NodeX,TimeP,Month,Year]  Flows on Transmission Lines (MW)
  HDLLoadRef::VariableArray{5} = ReadDisk(RefNameDB,"EGOutput/HDLLoad") #[Node,NodeX,TimeP,Month,Year]  Flows on Transmission Lines (MW)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  CanNode::VariableArray{1} = zeros(Float32,length(Node)) #'Canadian Nodes'
  CanNodeX::VariableArray{1} = zeros(Float32,length(NodeX)) # 'Canadian From Nodes'
  NodeName::SetArray = fill("",length(Node)) # 'Canadian Nodes', Type=String(20)
  NodeXName::SetArray = fill("",length(NodeX)) # 'Canadian From Nodes', Type=String(20)
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
  # ZZZSum  # 'Variable for Displaying Outputs', Type=Real(15,6)
end

function AssignNodes(data)
  (; Area,AreaDS,Areas,Node,NodeDS,Nodes) = data
  (; NodeX,NodeXDS,NodeXs,Year) = data
  (; CanNode,CanNodeX,NodeName,NodeXName,SceName) = data
  
  for node in Nodes
    CanNode[node] = 0
  end

  for nodex in NodeXs
    CanNodeX[nodex] = 0
  end
  
  nodes = Select(Node,(from="MB",to="NU"))
  nodexs = Select(NodeX,(from="MB",to="NU"))

  for node in nodes
    CanNode[node] = 1
  end

  for nodex in nodexs
    CanNodeX[nodex] = 1
  end

  #
  # Create Node Names for Display
  #
  for node in Nodes
    nodex = findall(NodeX[:] .== Node[node])
    NodeName[node] = Node[node]
    for nodex in NodeXs
      NodeXName[nodex] = NodeX[nodex]
    end
  end
  
  #
  # Assign Area names to Canada Nodes
  #
  for node in nodes
    areas = findall(Area[:] .== Node[node])
    if !isempty(areas)
      for area in areas
        NodeName[node] = string(AreaDS[area])
        nodex = node
        NodeXName[nodex] = NodeName[node]
      end
    end
  end
  
  #
  # Overwrite names for Newfoundland Island and Labrador nodes
  #
  node = Select(Node,"LB")
  nodex = Select(NodeX,"LB")
  NodeName[node] = "Labrador"
  NodeXName[nodex] = "Labrador"

  node = Select(Node,"NL")
  nodex = Select(NodeX,"NL")
  NodeName[node] = "Newfoundland Island"
  NodeXName[nodex] = "Newfoundland Island"

  return NodeName,NodeXName
  
end #function AssignNodes

function zFlows_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations,Year) = data
  (; Months,Node,NodeDS,Nodes,NodeX,NodeXDS,NodeXs,TimePs) = data
  (; ANMap,BaseSw,CanNode,CanNodeX,CCC,EndTime,HDHours,HDHoursRef) = data
  (; HDLLoad,HDLLoadRef,NodeName,NodeXName,ZZZ,SceName) = data

  NodeName,NodeXName = AssignNodes(data)

  years = collect(Yr(1990):Final)
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    @. HDLLoadRef = HDLLoad
    @. HDHoursRef = HDHours
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;From NodeX;To Node;Units;zData;zInitial")

  #
  # Electric Transmission Flows
  #
  for nodex in NodeXs
    for node in Nodes
      ZZZSum = sum(HDLLoad[node,nodex,timep,month,year]*
        HDHours[timep,month] for year in years, month in Months, timep in TimePs)/1000
      if CanNode[node] == 1 || CanNodeX[nodex] == 1
        if ZZZSum > 0.0
          for year in years
            ZZZ[year] = sum(HDLLoad[node,nodex,timep,month,year]*
              HDHours[timep,month] for month in Months, timep in TimePs)/1000
            CCC[year] = sum(HDLLoadRef[node,nodex,timep,month,year]*
              HDHoursRef[timep,month] for month in Months, timep in TimePs)/1000
            zData = @sprintf("%.0f",ZZZ[year])
            zInitial = @sprintf("%.0f",CCC[year])
            println(iob,"zHDLLoad;", Year[year],";",NodeXName[nodex],";",NodeName[node],";GWh/Yr;",zData,";",zInitial)
          end
        end
      end
    end # for node
  end # for nodex
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zFlows-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zFlows_DtaControl(db)
  data = zFlowsData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zFlows_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zFlows_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zFlows_DtaControl(DB)
end
