#
# CurTime.jl 
#
using EnergyModel

module CurTime

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String
  Input::String = "RInput"
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]  
end

function RDataValues(db)
  data = RControl(; db)
  (;Input) = data
  (;CurTime) = data

  # 
  # Device curve initialization year is set to 2000 to best match
  # updated data sources 
  #
  CurTime = 2000-ITime+1
  WriteDisk(db,"$Input/CurTime",CurTime)

end

Base.@kwdef struct CControl
  db::String
  Input::String = "CInput"
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]    
end

function CDataValues(db)
  data = CControl(; db)
  (;Input) = data
  (;CurTime) = data

  # 
  # Device curve initialization year is set to 2000 to best match
  # updated data sources 
  #
  CurTime = 2000-ITime+1
  WriteDisk(db,"$Input/CurTime",CurTime)

end

Base.@kwdef struct IControl
  db::String
  Input::String = "IInput"
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # Year for capital costs [tv]    
end

function IDataValues(db)
  data = IControl(; db)
  (;Input) = data
  (;CurTime) = data

  # 
  # Device curve initialization year is set to 1985 to best match
  # data sources 
  #
  CurTime=1985-ITime+1
  WriteDisk(db,"$Input/CurTime",CurTime)

end

function Control(db)
  @info "CurTime.jl - Control"

  RDataValues(db)
  CDataValues(db)
  IDataValues(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
