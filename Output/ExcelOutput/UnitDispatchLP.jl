#
# UnitDispatchLP.jl
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

Base.@kwdef struct UnitDispatchLPData
  db::String

  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  HDPrA::VariableArray{4} = ReadDisk(db, "EOutput/HDPrA") # [Node,TimeP,Month,Year] Spot Market Marginal Price ($/MWh)
  ExchangeRateNode::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNode") # [Node,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  UnAgNum::VariableArray{1} = ReadDisk(db,"EGOutput/UnAgNum") #[Unit]  Aggregate Unit Number
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEGC::VariableArray{4} = ReadDisk(db, "EGOutput/UnEGC") # [Unit,TimeP,Month,Year] Effective Generating Capacity (MW)
  UnEG::VariableArray{4} = ReadDisk(db, "EGOutput/UnEG") # [Unit,TimeP,Month,Year] Generation (GWh) 
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGCD::VariableArray{4} = ReadDisk(db, "EGOutput/UnGCD") #[Unit,TimeP,Month,Year]  Generating Capacity Dispatched (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{2} = ReadDisk(db, "EGInput/UnHRt") #[Unit,Year]  Heat Rate (BTU/KWh)
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UnPOCGWh::VariableArray{3} = ReadDisk(db,"EGOutput/UnPOCGWh") #[Unit,Poll,Year]  Pollution Coefficient (Tonnes/GWh)
  UnVCost::VariableArray{4} = ReadDisk(db, "EGOutput/UnVCost") #[Unit,TimeP,Month,Year]  Bid Price of Power Offered to Spot Market ($/MWh)
  UnVCostUS::VariableArray{1} = ReadDisk(db,"EGOutput/UnVCostUS") #[Unit]  US Unit Variable Cost (US$/GWh)

  #
  HDPrAUS::VariableArray{4} = zeros(Float32, length(Node), length(TimeP), length(Month), length(Year)) # Spot Market Marginal Price (US$/MWh)
end

function UnitDispatchLP_DtaRun(data,nodes,timeps,months,years)
  (; SceName,GenCo,Node,MonthDS,Plant,Poll,Unit,Units,Year) = data
  (; HDPrA,ExchangeRateNode,UnAgNum,UnCode,UnCogen,UnEGC,UnEG) = data
  (; UnGC,UnGCD,UnGenCo,UnHRt,UnNode,UnPlant,UnPOCGWh,UnVCost,UnVCostUS) = data
  (; HDPrAUS) = data

  iob = IOBuffer()
  print(iob, "Node;","Year;","Month;","Time Period;","Unit Code;")
  print(iob,   "Plant Type;")
  print(iob,   "Agg Num;")
  print(iob,   "UnVCost Bid Price (Local\$/MWH);")
  print(iob,   "UnVCostUS Bid Price (US\$/MWH);")
  print(iob,   "HDPrA System Price (Local\$/MWH);")
  print(iob,   "HDPrAUS System Price (US\$/MWH);")
  print(iob,   "UnGCD Dispatched (MW);")
  print(iob,   "UnEGC Available (MW);")
  print(iob,   "Emissions Intensity (Tonnes/GWh);")
  print(iob,   "UnEG Generation (GWh);")
  print(iob,   "UnGC Capacity (MW);")
  println(iob)

  for year in years
    for month in months
      for timep in timeps
        for unit in Units
          if (UnCogen[unit] == 0) && (UnGenCo[unit] != "Null") && (UnPlant[unit] != "Null") && (UnNode[unit] != "Null")
            genco = Select(GenCo,UnGenCo[unit])
            plant = Select(Plant,UnPlant[unit])
            node = Select(Node,UnNode[unit])

            HDPrAUS[node,timep,month,year]=HDPrA[node,timep,month,year]/ExchangeRateNode[node,year]

            print(iob, UnNode[unit])
            print(iob, ";", Year[year])
            print(iob, ";", MonthDS[month])
            print(iob, ";", timep)
            print(iob, ";", UnCode[unit])
            print(iob, ";", UnPlant[unit])
            print(iob, ";", UnAgNum[unit])
            print(iob, ";", @sprintf("%.5f", UnVCost[unit,timep,month,year]))
            print(iob, ";", @sprintf("%.5f", UnVCostUS[unit]))
            print(iob, ";", @sprintf("%.5f", HDPrA[node,timep,month,year]))
            print(iob, ";", @sprintf("%.5f", HDPrAUS[node,timep,month,year]))
            print(iob, ";", @sprintf("%.5f", UnGCD[unit,timep,month,year]))
            print(iob, ";", @sprintf("%.5f", UnEGC[unit,timep,month,year]))
            # TODO Should this select a specific poll? CO2? - Luke 06.05.25
            # poll=1
            print(iob, ";", @sprintf("%.5f", UnPOCGWh[unit,1,year]))
            print(iob, ";", @sprintf("%.5f", UnEG[unit,timep,month,year]))
            print(iob, ";", @sprintf("%.5f", UnGC[unit,year]))
            println(iob)
          end
        end
      end
    end
  end
      
  filename = "UnitDispatchLP-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function UnitDispatchLP_DtaControl(db)
  @info "UnitDispatchLP_DtaControl"
  data = UnitDispatchLPData(; db)
  Month = data.Month
  Months = data.Months
  Node = data.Node
  Nodes = data.Nodes
  TimeP = data.TimeP
  TimePs = data.TimePs

  # NOTE: Node deselected before use in code in Promula
  # nodes=Select(Node,[MB,SK,LB,QC,NB,ON,AB,BC,NS,NL,PE,YT,NT,NU])

  # TimeP and Month selections commented out in Promula
  # timeps=collect(6)
  # months=Seelct(Month,"Winter")

  years=collect(Yr(1986):Yr(1990))
  UnitDispatchLP_DtaRun(data,Nodes,TimePs,Months,years)
end
if abspath(PROGRAM_FILE) == @__FILE__
UnitDispatchLP_DtaControl(DB)
end
