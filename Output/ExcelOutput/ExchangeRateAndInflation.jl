#
# ExchangeRateAndInflation.jl
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

Base.@kwdef struct ExchangeRateAndInflationData
  db::String
  
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))

  GNode::SetArray = ReadDisk(db, "MainDB/GNodeKey")
  GNodeDS::SetArray = ReadDisk(db, "MainDB/GNodeDS")
  GNodes::Vector{Int} = collect(Select(GNode))

  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))

  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))

  RfUnit::SetArray = ReadDisk(db, "MainDB/RfUnitKey")
  RfName::SetArray = ReadDisk(db, "MainDB/RfName")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))

  Year::SetArray = ReadDisk(db, "MainDB/Year")

  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") # [Area,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  ExchangeRateGNode::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateGNode") # [GNode,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  ExchangeRateNode::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNode") # [Node,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  ExchangeRateRfUnit::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateRfUnit") # [RfUnit,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  ExchangeRateUnit::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateUnit") # [Unit,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index
  InflationGNode::VariableArray{2} = ReadDisk(db, "MOutput/InflationGNode") # [GNode,Year] Inflation Index
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index
  InflationNode::VariableArray{2} = ReadDisk(db, "MOutput/InflationNode") # [Node,Year] Inflation Index
  InflationRfUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationRfUnit") # [RfUnit,Year] Inflation Index
  InflationUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationUnit") # [Unit,Year] Inflation Index
  InSm::VariableArray{2} = ReadDisk(db, "MOutput/InSm") # [Area,Year] Smoothed Inflation Rate (1/Yr)
  UnArea::Vector{String} = ReadDisk(db, "EGInput/UnArea") # [Unit] Area Pointer Type=String(15)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") # [Unit] Unit Name Type=String(30)
  xExchangeRate::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRate") # [Area,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xExchangeRateGNode::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateGNode") # [GNode,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xExchangeRateNode::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateNode") # [Node,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xExchangeRateRfUnit::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateRfUnit") # [RfUnit,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xExchangeRateUnit::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateUnit") # [Unit,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xInflation::VariableArray{2} = ReadDisk(db, "MInput/xInflation") # [Area,Year] Inflation Index
  xInflationGNode::VariableArray{2} = ReadDisk(db, "MInput/xInflationGNode") # [GNode,Year] Inflation Index
  xInflationNation::VariableArray{2} = ReadDisk(db, "MInput/xInflationNation") # [Nation,Year] Inflation Index
  xInflationNode::VariableArray{2} = ReadDisk(db, "MInput/xInflationNode") # [Node,Year] Inflation Index
  xInflationRfUnit::VariableArray{2} = ReadDisk(db, "MInput/xInflationRfUnit") # [RfUnit,Year] Inflation Index
  xInflationUnit::VariableArray{2} = ReadDisk(db, "MInput/xInflationUnit") # [Unit,Year] Inflation Index
end

function ExchangeRateAndInflation_DtaRun(data)
  (; SceName,Area,AreaDS,Areas,GNode,GNodeDS,GNodes,Nation,NationDS,Nations) = data
  (; Node,NodeDS,Nodes,RfName,RfUnits,Units,Year) = data
  (; ExchangeRate,ExchangeRateGNode,ExchangeRateNation) = data
  (; ExchangeRateNode,ExchangeRateRfUnit,ExchangeRateUnit) = data
  (; Inflation,InflationGNode,InflationNation,InflationNode) = data
  (; InflationRfUnit,InflationUnit,InSm,UnArea,UnName) = data
  (; xExchangeRate,xExchangeRateGNode,xExchangeRateNation) = data
  (; xExchangeRateNode,xExchangeRateRfUnit,xExchangeRateUnit) = data
  (; xInflation,xInflationGNode,xInflationNation,xInflationNode) = data
  (; xInflationRfUnit,xInflationUnit) = data

  iob = IOBuffer()

  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the Exchange Rate and Inflation summary output.")
  println(iob, " ")

  years = collect(Yr(1985):Final)
  # year = Select(Year)

  println(iob, "Year;", ";           ", join(Year[years], ";           "))
  println(iob, " ")

  print(iob, "Area Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "ExchangeRate;", AreaDS[area])
    for year in years
      ZZZ[year] = ExchangeRate[area, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "National Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    print(iob, "ExchangeRateNation;", NationDS[nation])
    for year in years
      ZZZ[year] = ExchangeRateNation[nation, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Node Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for node in Nodes
    print(iob, "ExchangeRateNode;", NodeDS[node])
    for year in years
      ZZZ[year] = ExchangeRateNode[node, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "GNode Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for gnode in GNodes
    print(iob, "ExchangeRateGNode;", GNodeDS[gnode])
    for year in years
      ZZZ[year] = ExchangeRateGNode[gnode, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Unit Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    units = findall(UnArea[:] .== Area[area])
    if !isempty(units)
      unit = first(units)
    else
      unit = 1
    end
    print(iob, "ExchangeRateUnit;",AreaDS[area],",", UnName[unit])
    for year in years
      ZZZ[year] = ExchangeRateUnit[unit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "RfUnit Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for rfunit in RfUnits
    print(iob, "ExchangeRateRfUnit;", RfName[rfunit])
    for year in years
      ZZZ[year] = ExchangeRateRfUnit[rfunit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Area Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "Inflation;", AreaDS[area]) 
    for year in years
      ZZZ[year] = Inflation[area, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "National Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    print(iob, "InflationNation;", NationDS[nation])
    for year in years
      ZZZ[year] = InflationNation[nation, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Node Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for node in Nodes
    print(iob, "InflationNode;", NodeDS[node], ";")
    for year in years
      ZZZ[year] = InflationNode[node, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "GNode Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for gnode in GNodes
    print(iob, "InflationGNode;", GNodeDS[gnode])
    for year in years
      ZZZ[year] = InflationGNode[gnode, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Unit Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    units = findall(UnArea[:] .== Area[area])
    if !isempty(units)
      unit = first(units)
    else
      unit = 1
    end
    print(iob, "InflationUnit;",AreaDS[area],",", UnName[unit])
    for year in years
      ZZZ[year] = InflationUnit[unit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "RfUnit Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for rfunit in RfUnits
    print(iob, "InflationRfUnit;", RfName[rfunit])
    for year in years
      ZZZ[year] = InflationRfUnit[rfunit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Smoothed Inflation Rate (1/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    for year in years
      ZZZ[year] = InSm[area, year]
    end
    print(iob, "InSm;", AreaDS[area])
    for year in years
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input Area Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "xExchangeRate;", AreaDS[area])
    for year in years
      ZZZ[year] = xExchangeRate[area, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input National Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    print(iob, "xExchangeRateNation;", NationDS[nation])
    for year in years
      ZZZ[year] = xExchangeRateNation[nation, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input Node Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for node in Nodes
    print(iob, "xExchangeRateNode;", NodeDS[node])
    for year in years
      ZZZ[year] = xExchangeRateNode[node, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input GNode Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for gnode in GNodes
    print(iob, "xExchangeRateGNode;", GNodeDS[gnode])
    for year in years
      ZZZ[year] = xExchangeRateGNode[gnode, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input Unit Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    units = findall(UnArea[:] .== Area[area])
    if !isempty(units)
      unit = first(units)
    else
      unit = 1
    end
    print(iob, "xExchangeRateUnit;",AreaDS[area],",", UnName[unit])
    for year in years
      ZZZ[year] = xExchangeRateUnit[unit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input RfUnit Local Currency/US\$ Exchange Rate (Local/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for rfunit in RfUnits
    print(iob, "xExchangeRateRfUnit;", RfName[rfunit])
    for year in years
      ZZZ[year] = xExchangeRateRfUnit[rfunit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input Area Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "xInflation;", AreaDS[area])
    for year in years
      ZZZ[year] = xInflation[area, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input National Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    print(iob, "xInflationNation;", NationDS[nation])
    for year in years
      ZZZ[year] = xInflationNation[nation, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input Node Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for node in Nodes
    print(iob, "xInflationNode;", NodeDS[node])
    for year in years
      ZZZ[year] = xInflationNode[node, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input GNode Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for gnode in GNodes
    print(iob, "xInflationGNode;", GNodeDS[gnode])
    for year in years
      ZZZ[year] = xInflationGNode[gnode, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  println(iob, "Input Unit Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    units = findall(UnArea[:] .== Area[area])
    if !isempty(units)
      unit = first(units)
    else
      unit = 1
    end
    print(iob, "xInflationUnit;",AreaDS[area],",", UnName[unit])
    for year in years
      ZZZ[year] = xInflationUnit[unit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Input RfUnit Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for rfunit in RfUnits
    print(iob, "xInflationRfUnit;", RfName[rfunit])
    for year in years
      ZZZ[year] = xInflationRfUnit[rfunit, year]
      print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  filename = "ExchangeRateAndInflation-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ExchangeRateAndInflation_DtaControl(db)
  @info "ExchangeRateAndInflation_DtaControl"
  data = ExchangeRateAndInflationData(; db)
  ExchangeRateAndInflation_DtaRun(data)
end
if abspath(PROGRAM_FILE) == @__FILE__
ExchangeRateAndInflation_DtaControl(DB)
end
