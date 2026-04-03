#
# UnitCounter.jl
#
using EnergyModel

module UnitCounter

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaKey::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") # [Year] Number of Units

end

function CountUnits(db)
  data = EControl(; db)
  (;Area,AreaKey,Areas,Units,Years) = data
  (;UnArea,UnCounter) = data
  
  ActiveUnits = 0
  for unit in Units
    for area in Areas
      if UnArea[unit] == AreaKey[area]
        ActiveUnits = ActiveUnits+1
      end
    end
  end
  
  @info "ActiveUnits = $ActiveUnits "

  for year in Years
    UnCounter[year] = ActiveUnits
  end
  
  WriteDisk(db,"EGInput/UnCounter",UnCounter)

end

function Control(db)
  @info "UnitCounter.jl - Control"
  CountUnits(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
