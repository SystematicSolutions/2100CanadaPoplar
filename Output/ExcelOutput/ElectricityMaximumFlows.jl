#
# ElectricityMaximumFlows.jl
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


Base.@kwdef struct ElectricityMaximumFlowsData
  db::String

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXDS::SetArray = ReadDisk(db,"MainDB/NodeXDS")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  TimeP::SetArray = ReadDisk(db,"MainDB/TimeP")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/Year")

  LLMax::VariableArray{5} = ReadDisk(db,"EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)

  # Scratch Variables
  ZZZ = zeros(Float32,length(Year))
end

function ElectricityMaximumFlows_DtaRun(data)
  (; Months,NodeDS,Nodes,NodeXDS,NodeXs,TimePs,Year) = data
  (; LLMax) = data
  (; ZZZ,SceName) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the Electricity Flows Outputs Summary")
  println(iob, " ")

  years = collect(Yr(1990):Final)
  # year = Select(Year)  
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  for nodex in NodeXs
    for node in Nodes
      print(iob, "Max Transmission Load to $(NodeDS[node]) from $(NodeXDS[nodex]) (MW);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for timep in TimePs
        if LLMax[node,nodex,timep,1,Yr(1990)] > 0
          print(iob, "LLMax;       $timep")
          for year in years
            ZZZ[year]=maximum(LLMax[node,nodex,timep,month,year] for month in Months)
            print(iob,";",@sprintf("%.0f",ZZZ[year]))
          end
          println(iob)
        end
      end
      println(iob)
    end
  end

  filename = "ElectricityMaximumFlows-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ElectricityMaximumFlows_DtaControl(db)
  @info "ElectricityMaximumFlows_DtaControl"
  data = ElectricityMaximumFlowsData(; db)

  ElectricityMaximumFlows_DtaRun(data)

end

if abspath(PROGRAM_FILE) == @__FILE__
ElectricityMaximumFlows_DtaControl(DB)
end
