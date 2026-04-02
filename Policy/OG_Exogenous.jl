#
# OG_Exogenous.jl
#

using EnergyModel

module OG_Exogenous

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DevSw::VariableArray{2} = ReadDisk(db,"SpInput/DevSw") # [OGUnit,Year] Development Switch
  PdSw::VariableArray{2} = ReadDisk(db,"SpInput/PdSw") # [OGUnit,Year] Production Switch

  # Scratch Variables
end

function SupplyPolicy(db)
  data = SControl(; db)
  (; OGUnits,Years) = data
  (; DevSw,PdSw) = data

  for year in Years, ogunit in OGUnits
    DevSw[ogunit,year] = 0
    PdSw[ogunit,year] = 0
  end
  
  WriteDisk(db,"SpInput/DevSw",DevSw)
  WriteDisk(db,"SpInput/PdSw",PdSw)
end

function PolicyControl(db)
  @info "OG_Exogenous.jl - PolicyControl"
  SupplyPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
