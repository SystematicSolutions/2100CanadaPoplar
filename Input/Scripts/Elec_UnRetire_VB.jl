#
# Elec_UnRetire_VB.jl - VBInput Unit Retirement Date
#
using EnergyModel

module Elec_UnRetire_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "EGCalDB"
  Input::String = "EGInput"
  Outpt::String = "EGOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vUnRetire::VariableArray{1} = ReadDisk(db,"vData_ElectricUnits/vUnRetire") # [Unit] VBInput Retirement Date (Unit)
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;vUnRetire,UnRetire,Years,Units) = data
  #*
  #* Set x variables equal to v variables
  #*
  for year in Years
    for unit in Units
      UnRetire[unit,year]=vUnRetire[unit]
    end
  end
  WriteDisk(db,"EGInput/UnRetire",UnRetire)
  
end

function CalibrationControl(db)
  @info "Elec_UnRetire_VB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
