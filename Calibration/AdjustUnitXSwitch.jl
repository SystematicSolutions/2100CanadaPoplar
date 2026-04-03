#
# AdjustUnitXSwitch.jl
#
using EnergyModel

module AdjustUnitXSwitch

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnXSw::VariableArray{2} = ReadDisk(db,"EGInput/UnXSw") # [Unit,Year] Exogneous Unit Data Switch (0=Exogenous)

end

function UnitXSwitchAdjustment(db)
  data = EControl(; db)
  (;Units) = data
  (;UnCogen,UnNation,UnXSw) = data

  #
  # In future all utility units are endogenous
  #
  units = findall(UnCogen[:] .== 0)
  if !isempty(units)
    years = collect(Future:Final)
    for year in years, unit in units
      UnXSw[unit,year] = 1
    end
  end

  #
  # Historically US units are exogenous
  #
  units=findall(UnNation[:] .== "US")
  if !isempty(units)
    years = collect(First:Last)
    for year in years, unit in units
      UnXSw[unit,year] = 0
    end
  end
  #
  # Historically MX units are exogenous
  #
  units=findall(UnNation[:] .== "MX")
  if !isempty(units)
    years = collect(First:Last)
    for year in years, unit in units
      UnXSw[unit,year] = 0
    end
  end

  WriteDisk(db,"EGInput/UnXSw",UnXSw)

end

function Control(db)
  @info "AdjustUnitXSwitch.jl - Control"
  UnitXSwitchAdjustment(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
