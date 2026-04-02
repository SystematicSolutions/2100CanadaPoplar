#
# OG_SAGD_Solvent.jl
#
# Gavin Cook - This policy increases SAGD production as a result of utilizing solvent technology. 
# We expect a 40% increase in production from facilities utilizing tech, which is roughly 350 PJ more production in 2030.
#

using EnergyModel

module OG_SAGD_Solvent

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SAGDSolventControl
  db::String

  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  OGCode::Array{String} = ReadDisk(db,"MainDB/OGCode") # [OGUnit] Oil and Gas Unit Code
  xDevCap::VariableArray{2} = ReadDisk(db,"SpInput/xDevCap") # [OGUnit,Year] Exogenous Development Capital Costs ($/mmBtu)
  xSusCap::VariableArray{2} = ReadDisk(db,"SpInput/xSusCap") # [OGUnit,Year] Exogenous Sustaining Capital Costs ($/mmBtu)
end

function PolicyControl(db)
  data = SAGDSolventControl(; db)
  (; OGUnit, OGUnits, Years) = data
  (; OGCode, xDevCap, xSusCap) = data
  
  @info "OG_SAGD_Solvent.jl - SAGDSolventPolicy"
  
  # Apply policy for years 2024-2030
  years = Yr(2026):Yr(2030)
  
  # Select SAGD units with specific code
  sagd_unit = Select(OGCode, ==("AB_OS_SAGD_0001"))
  
  for unit in sagd_unit, year in years
    xDevCap[unit, year] = 5.5
    xSusCap[unit, year] = 0.26
  end
  
  WriteDisk(db, "SpInput/xDevCap", xDevCap)
  WriteDisk(db, "SpInput/xSusCap", xSusCap)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
