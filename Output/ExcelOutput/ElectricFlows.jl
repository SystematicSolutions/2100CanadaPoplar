#
# ElectricFlows.jl
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

  

  
Base.@kwdef struct ElectricFlowsData
  db::String

  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db, "MainDB/NodeX")
  NodeXDS::SetArray = ReadDisk(db, "MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Power::SetArray = ReadDisk(db, "MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db, "MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  TimeP::SetArray = ReadDisk(db, "MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EmEGA::VariableArray{4} = ReadDisk(db, "EGOutput/EmEGA") # [Node,TimeP,Month,Year] Emergency Generation (GWh)
  ExchangeRateNode::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNode") # [Node,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  HDEmMDS::VariableArray{4} = ReadDisk(db, "EGOutput/HDEmMDS") # [Node,TimeP,Month,Year] Emergency Power Dispatched (MW)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month] Number of Hours in the Interval (Hours)
  HDLLoad::VariableArray{5} = ReadDisk(db, "EGOutput/HDLLoad") # [Node,NodeX,TimeP,Month,Year] Loading on Transmission Lines (MW)
  HDPrA::VariableArray{4} = ReadDisk(db,"EOutput/HDPrA") #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
  HDXLoad::VariableArray{5} = ReadDisk(db, "EGInput/HDXLoad") # [Node,NodeX,TimeP,Month,Year] Power Contracts over Transmission Lines (MW)
  InflationNode::VariableArray{2} = ReadDisk(db, "MOutput/InflationNode") # [Node,Year] Inflation Index
  LLMax::VariableArray{5} = ReadDisk(db, "EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
  LLVC::VariableArray{3} = ReadDisk(db,"EGOutput/LLVC") #[Node,NodeX,Year]  Transmission Rate (US$/MWh)
  MoneyUnitDS::Array{String} = ReadDisk(db, "MInput/MoneyUnitDS") # [Area] Descriptor for Monetary Units Type=String(15)

  #
  # Scratch variables
  #
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))

end

function ElectricFlows_DtaRun(data,timep,month,nodexs)
  (; SceName,Months,MonthDS,Node,NodeDS,Nodes,NodeXDS,NodeXs,Year) = data
  (; CDTime,CDYear,EmEGA,ExchangeRateNode,HDEmMDS,HDHours,HDLLoad) = data  
  (; HDPrA,HDXLoad,InflationNode,LLMax,LLVC,MoneyUnitDS,ZZZ) = data
  
  years = collect(Yr(1990):Yr(2050)) 
  TPDS = "TimeP$timep"
   
  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "ElectricFlows")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  print(iob,MonthDS[month]," ",TPDS," Clearing Price ($CDTime US\$/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for node in Nodes
    print(iob,"HDPrA;",NodeDS[node])   
    for year in years
      ZZZ[year] = HDPrA[node,timep,month,year]/ExchangeRateNode[node,year]/
        InflationNode[node,year]*InflationNode[node,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
    
  for nodex in nodexs
  
    print(iob,"From ",NodeXDS[nodex]," ",MonthDS[month]," ",TPDS," Transmission Load (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for node in Nodes
      print(iob,"HDLLoad*HDHours;Sales to ",NodeDS[node])   
      for year in years
        ZZZ[year] = HDLLoad[node,nodex,timep,month,year]*HDHours[timep,month]/1000
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    print(iob,"From ",NodeXDS[nodex]," ",MonthDS[month]," ",TPDS," Transmission Capacity (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for node in Nodes
      print(iob,"LLMax;To ",NodeDS[node])   
      for year in years
        ZZZ[year] = LLMax[node,nodex,timep,month,year]*HDHours[timep,month]/1000
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)    
    
  
    print(iob,"From ",NodeXDS[nodex]," ",MonthDS[month]," ",TPDS," Contract Transmission Load (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for node in Nodes
      print(iob,"HDXLoad*HDHours;Sales to ",NodeDS[node])   
      for year in years
        ZZZ[year] = HDXLoad[node,nodex,timep,month,year]*HDHours[timep,month]/1000
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)  
    
    print(iob,MonthDS[month]," ",TPDS," Transmission Cost ($CDTime US\$/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for node in Nodes
      print(iob,"LLVC;",NodeDS[node])   
      for year in years
        ZZZ[year] = LLVC[node,nodex,year]/InflationNode[node,year]*InflationNode[node,CDYear]
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)    
    
  end # nodexs
    
  print(iob,MonthDS[month]," ",TPDS," Emergency Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for node in Nodes
    print(iob,"EmEGA;",NodeDS[node])   
    for year in years
      ZZZ[year] = EmEGA[node,timep,month,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)     
    
  print(iob,MonthDS[month]," ",TPDS," Emergency Demands (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for node in Nodes
    print(iob,"HDEmMDS;",NodeDS[node])   
    for year in years
      ZZZ[year] = HDEmMDS[node,timep,month,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)        

  #
  # Create *.dta filename and write output values
  #
  filename = "ElectricFlows-$(MonthDS[month])-$TPDS-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ElectricFlows_DtaControl(db)
  @info "ElectricFlows_DtaControl"
  data = ElectricFlowsData(; db)
  (; Month,NodeX) = data  
  
  nodexs = Select(NodeX,["MB","SK","LB","QC","NB","ON","AB",
                         "BC","NS","NL","PE","YT","NT","NU"]) 
  months = Select(Month,["Summer","Winter"])
  timeps = collect(5:6)
  
  for month in months, timep in timeps  
    ElectricFlows_DtaRun(data,timep,month,nodexs)
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
ElectricFlows_DtaControl(DB)
end
