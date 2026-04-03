#
# zLLEffLoss.jl
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

Base.@kwdef struct zLLEffLossData
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
  LLEff::VariableArray{3} = ReadDisk(db,"EGInput/LLEff") #[Node,NodeX,Year]  Transmission Line Efficiency (MW/MW)
  LLEffRef::VariableArray{3} = ReadDisk(RefNameDB,"EGInput/LLEff") #[Node,NodeX,Year]  Transmission Line Efficiency (MW/MW)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  NdArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdArMap") # [Node,Area] Map between Node and Area
  NdArMapRef::VariableArray{2} = ReadDisk(RefNameDB,"EGInput/NdArMap") # [Node,Area] Map between Node and Area  
  SaEC::VariableArray{3} = ReadDisk(db,"SOutput/SaEC") # (ECC,Area,Year),Electricity Sales by ECC (GWh/Yr)
  SaECRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/SaEC") # (ECC,Area,Year),Electricity Sales by ECC (GWh/Yr)
  TDEF::VariableArray{3} = ReadDisk(db, "SInput/TDEF") #[Fuel,Area,Year]  T&D Efficiency (Btu/Btu)
  TDEFRef::VariableArray{3} = ReadDisk(RefNameDB, "SInput/TDEF") #[Fuel,Area,Year]  T&D Efficiency (Btu/Btu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #

  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zLLEffLoss_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations,Year) = data
  (; Months,Node,NodeDS,Nodes,NodeX,NodeXDS,NodeXs,TimePs) = data
  (; ANMap,BaseSw,CCC,EndTime,HDHours,HDHoursRef) = data
  (; HDLLoad,HDLLoadRef,LLEff,LLEffRef,NdArMap,NdArMapRef,SaEC,SaECRef) = data
  (; TDEF,TDEFRef,ZZZ,SceName) = data

  if BaseSw != 0
    @. HDLLoadRef = HDLLoad
    @. HDHoursRef = HDHours
    @. LLEffRef = LLEff
    @. NdArMapRef = NdArMap
    @. SaECRef = SaEC
    @. TDEFRef = TDEF
  end

  years = collect(Yr(1990):Final)
  areas = findall(ANMap[:,nation] .== 1)

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  #
  # Electric Transmission Losses
  #
  for year in years
    ZZZ[year] = sum(HDLLoad[node,nodex,timep,month,year]*(1-LLEff[node,nodex,year])*
                HDHours[timep,month]*NdArMap[node,area] for month in Months,
                timep in TimePs,node in Nodes, nodex in NodeXs, area in areas)/1000
    CCC[year] = sum(HDLLoadRef[node,nodex,timep,month,year]*(1-LLEffRef[node,nodex,year])*
                HDHoursRef[timep,month]*NdArMapRef[node,area] for month in Months,
                timep in TimePs,node in Nodes, nodex in NodeXs, area in areas)/1000
    println(iob,"zLLEffLoss;", Year[year],";",NationDS[nation],";GWh/Yr;",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
  end

  for area in areas
    for year in years
      ZZZ[year] = sum(HDLLoad[node,nodex,timep,month,year]*(1-LLEff[node,nodex,year])*
                  HDHours[timep,month]*NdArMap[node,area] for month in Months,
                  timep in TimePs,node in Nodes, nodex in NodeXs)/1000
      CCC[year] = sum(HDLLoadRef[node,nodex,timep,month,year]*(1-LLEffRef[node,nodex,year])*
                  HDHoursRef[timep,month]*NdArMapRef[node,area] for month in Months,
                  timep in TimePs,node in Nodes, nodex in NodeXs)/1000
      println(iob,"zLLEffLoss;", Year[year],";",AreaDS[area],";GWh/Yr;",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
    end
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zLLEffLoss-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zLLEffLoss_DtaControl(db)
  data = zLLEffLossData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zLLEffLoss_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zLLEffLoss_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zLLEffLoss_DtaControl(DB)
end
