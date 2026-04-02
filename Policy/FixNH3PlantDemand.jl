#
# FixNH3PlantDemand.jl
#

using EnergyModel

module FixNH3PlantDemand

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: DB
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum (Btu/Btu)
end

function ElecPolicy(db::String)
  data = EControl(; db)
  (; FuelEP,Unit,Year) = data 
  (; Units,FuelEPs,Years) = data
  (; UnFlFrMax) = data

  #
  # Set ammonia fuel fraction maximum to zero for all units and years
  #
  ammonia = Select(FuelEP,"Ammonia")
  
  for unit in Units, year in Years
    UnFlFrMax[unit,ammonia,year] = 0.0
  end

  WriteDisk(db,"EGInput/UnFlFrMax",UnFlFrMax)

  #@info "FixNH3PlantDemand.jl - PolicyControl completed"
end

function PolicyControl(db)
  @info "FixNH3PlantDemand.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
