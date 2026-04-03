#
# TOMBaseYear.jl
#
using EnergyModel

module TOMBaseYear

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TOMBaseYearData
  db::String

  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
end

function ReadTOMBaseYear(db)
  data = TOMBaseYearData(; db)
  (; TOMBaseTime,TOMBaseYear) = data

  TOMBaseTime = 2017
  TOMBaseYear = TOMBaseTime-ITime+1
  WriteDisk(db,"KInput/TOMBaseTime",TOMBaseTime)
  WriteDisk(db,"KInput/TOMBaseYear",TOMBaseYear)

end

if abspath(PROGRAM_FILE) == @__FILE__
  ReadTOMBaseYear(DB)
end

end
