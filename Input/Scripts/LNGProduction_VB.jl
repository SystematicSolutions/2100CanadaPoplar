#
# LNGProduction_VB.jl
#
using EnergyModel

module LNGProduction_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xLNGAProd::VariableArray{2} = ReadDisk(db,"SInput/xLNGAProd") # [Area,Year] Liquid Natural Gas Production (TBtu/Yr) 
  vLNGAProd::VariableArray{2} = ReadDisk(db,"VBInput/vLNGAProd") # [Area,Year] Liquid Natural Gas Production (TBtu/Yr) 
  xGAProd::VariableArray{3} = ReadDisk(db,"SInput/xGAProd") # [Process,Area,Year] Gas Producer Consumption  (Tbtu/Yr)

end

function LNGProduction(db)
  data = SControl(; db)
  (;Areas,Process,Years) = data
  (;xLNGAProd,vLNGAProd,xGAProd) = data
  
  for year in Years, area in Areas
    xLNGAProd[area,year]=vLNGAProd[area,year]
  end
  WriteDisk(db,"SInput/xLNGAProd",xLNGAProd)
  
  process = Select(Process,"LNGProduction")
  for year in Years, area in Areas
    xGAProd[process,area,year]=xLNGAProd[area,year]
  end
  WriteDisk(db,"SInput/xGAProd",xGAProd)
   
end

function Control(db)
  @info "LNGProduction_VB.jl - Control"
  LNGProduction(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
