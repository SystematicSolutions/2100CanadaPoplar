#
# AdjustSteamHeatRate.jl - VBInput Steam Data
#
####### NOTE:  This file may be able to be deleted. Steam_VB.jl sets
#       the future heat rate equal to Last. 01/03/2019 R.Levesque
#
using EnergyModel

module AdjustSteamHeatRate

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  Last=HisTime-ITime+1
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  StHR::VariableArray{2} = ReadDisk(db,"$Input/StHR") # [Area,Year] Steam Generation Heat Rate (Btu/Btu)

  # Scratch Variables
end

function ElecCalibration(db)
  data = EControl(; db)
  (;Input) = data
  (;Area,Last) = data
  (;StHR) = data
  # Temporary patch to hold StHR constant for Quebec in forecast
  #   *
  Quebec = Select(Area, "QC")
  years = collect(Future:Final)
  
  for year in years
    StHR[Quebec,year]=StHR[Quebec,Last]
  end
  WriteDisk(db,"$Input/StHR",StHR)
end

function CalibrationControl(db)
  @info "AdjustSteamHeatRate.jl - CalibrationControl"
  ElecCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
