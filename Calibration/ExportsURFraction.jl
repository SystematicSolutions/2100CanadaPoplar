#
# ExportsURFraction.jl
#
using EnergyModel

module ExportsURFraction

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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ExportsURFraction::VariableArray{2} = ReadDisk(db,"EInput/ExportsURFraction") # [Area,Year] Electric Exports Unit Revenues Flag (0=exclude)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Years) = data
  (;ExportsURFraction) = data

  @. ExportsURFraction=0.08

  NL=Select(Area,"NL")
  for year in Years
    ExportsURFraction[NL,year]=0
  end
 
  WriteDisk(db,"EInput/ExportsURFraction",ExportsURFraction)
end

function CalibrationControl(db)
  @info "ExportsURFraction.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
