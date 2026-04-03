#
# Electric_Transmission_VB.jl - Assign vLLMax to LLMax
#
using EnergyModel

module Electric_Transmission_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  HDXLoad::VariableArray{5} = ReadDisk(db,"EGInput/HDXLoad") # [Node,NodeX,TimeP,Month,Year] Power Contracts over Transmission Lines (MW)
  vHDXLoad::VariableArray{5} = ReadDisk(db,"VBInput/vHDXLoad") # [Node,NodeX,TimeP,Month,Year] Exogenous Loading on Transmission Lines (MW)
  LLMax::VariableArray{5} = ReadDisk(db,"EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
  vLLMax::VariableArray{5} = ReadDisk(db,"VBInput/vLLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
  xLLVC::VariableArray{3} = ReadDisk(db,"EGInput/xLLVC") # [Node,NodeX,Year] Transmission Rate (Real US$/MWh)
  vLLVC::VariableArray{3} = ReadDisk(db,"VBInput/vLLVC") # [Node,NodeX,Year] Transmission rate (Real US$/MWh)
end

function ECalibration(db)
  data = EControl(; db)
  (;Months,NodeXs,Nodes,TimePs,Years) = data
  (;HDXLoad,vHDXLoad,LLMax,vLLMax,xLLVC,vLLVC) = data

  for n in Nodes, nx in NodeXs, t in TimePs, m in Months, y in Years
    HDXLoad[n,nx,t,m,y] = vHDXLoad[n,nx,t,m,y]
    LLMax[n,nx,t,m,y] = vLLMax[n,nx,t,m,y]
  end
  for n in Nodes, nx in NodeXs, y in Years
    xLLVC[n,nx,y] = vLLVC[n,nx,y]
  end

  WriteDisk(db,"EGInput/HDXLoad",HDXLoad)
  WriteDisk(db,"EGInput/LLMax",LLMax)
  WriteDisk(db,"EGInput/xLLVC",xLLVC)
  
end

function CalibrationControl(db)
  @info "Electric_Transmission_VB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
