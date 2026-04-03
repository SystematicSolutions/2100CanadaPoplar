#
# Loads.jl
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

Base.@kwdef struct LoadsData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  TimeP::SetArray = ReadDisk(db, "MainDB/TimePKey")
  TimePs::Vector{Int}    = collect(Select(TimeP))
  
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int}    = collect(Select(Month))
  
  Year = ReadDisk(db, "MainDB/YearKey")

  HDADP::VariableArray{4} = ReadDisk(db, "EGOutput/HDADP") #[Node,TimeP,Month,Year]  Average Load in Interval (MW)
  HDADPwithStorage::VariableArray{4} = ReadDisk(db, "EGOutput/HDADPwithStorage") #[Node,TimeP,Month,Year]  Average Load in Interval with Generation to Fill Storage (MW)
  HDEnergy::VariableArray{4} = ReadDisk(db, "EGOutput/HDEnergy") #[Node,TimeP,Month,Year]  Energy in Interval (GWh)
  
  HDHrMn::VariableArray{2} = ReadDisk(db, "EInput/HDHrMn") #[TimeP,Month]  Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db, "EInput/HDHrPk") #[TimeP,Month]  Peak Hour in the Interval (Hour)
  HDPDP::VariableArray{4} = ReadDisk(db, "EGOutput/HDPDP") #[Node,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
  
  StorEG::VariableArray{4} = ReadDisk(db, "EGOutput/StorEG") #[TimeP,Month,Node,Year]  Electricity Generated from Storage (GWh/r)
  StorEnergy::VariableArray{4} = ReadDisk(db, "EGOutput/StorEnergy") #[TimeP,Month,Node,Year]  Electricity Required to Recharge Storage (GWh/Yr)
   
  ZZZ = zeros(Float32,length(Year))
end

function Loads_DtaRun(data::LoadsData)
  (; SceName,Months, Nodes, TimePs)  = data
  (; NodeDS, MonthDS) = data
  (; HDADP, HDADPwithStorage, HDPDP, HDEnergy, StorEG, StorEnergy) = data
  (; HDHrMn, HDHrPk) = data
  (; ZZZ,Year) = data
  iob = IOBuffer()
  
  years = Select(Year, (from = "1990", to = "2050"))
  println(iob, "Variable;Node;Month;TimeP;Hours;Units;", join(Year[years], ";"))
  
  HRS::Float32 = 0.0
  TPDS::SetArray = ["Peak","Near Peak", "High Intermediate", "Low Intermediate", "High Baseload","Low Baseload"]
  
  for node in Nodes, month in Months, timep in TimePs
    HRS=HDHrMn[timep,month]-HDHrPk[timep,month]+1.0
   
    print(iob,"Average Load (MW);",NodeDS[node],";",MonthDS[month],";",TPDS[timep],
    ";",HRS,";","(MW)")
    for year in years
      ZZZ[year] = HDADP[node,timep,month,year]
      print(iob,";",@sprintf("%.1f",ZZZ[year]))
    end 
    println(iob)
    print(iob,"Average Load With Storage (MW);",NodeDS[node],";",MonthDS[month],";",TPDS[timep],
    ";",HRS,";","(MW)")
    for year in years
      ZZZ[year] = HDADPwithStorage[node,timep,month,year]
      print(iob,";",@sprintf("%.1f",ZZZ[year]))
    end 
    println(iob)    
    print(iob,"Peak Load (MW);",NodeDS[node],";",MonthDS[month],";",TPDS[timep],
    ";",HRS,";","(MW)")
    for year in years
      ZZZ[year] = HDPDP[node,timep,month,year]
      print(iob,";",@sprintf("%.1f",ZZZ[year]))
    end 
    println(iob)
    print(iob,"Energy (GWh);",NodeDS[node],";",MonthDS[month],";",TPDS[timep],
    ";",HRS,";","(GWh)")
    for year in years
      ZZZ[year] = HDEnergy[node,timep,month,year]
      print(iob,";",@sprintf("%.1f",ZZZ[year]))
    end 
    println(iob)  
    print(iob,"Electricity Dispatched from Storage Technologies (GWh);",NodeDS[node],";",MonthDS[month],";",TPDS[timep],
    ";",HRS,";","(GWh)")
    for year in years
      ZZZ[year] = StorEG[timep,month,node,year]
      print(iob,";",@sprintf("%.1f",ZZZ[year]))
    end 
    println(iob)   
    print(iob,"Electricity Required to Recharge Storage Technologies (GWh);",NodeDS[node],";",MonthDS[month],";",TPDS[timep],
    ";",HRS,";","(GWh)")
    for year in years
      ZZZ[year] = StorEnergy[timep,month,node,year]
      print(iob,";",@sprintf("%.1f",ZZZ[year]))
    end 
    println(iob)     
    
  end
  
  filename = "Loads-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function Loads_DtaControl(db::String)
  @info "Loads_DtaControl"
  data = LoadsData(; db);
  Loads_DtaRun(data);
  
end

if abspath(PROGRAM_FILE) == @__FILE__
Loads_DtaControl(DB)
end
