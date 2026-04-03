#
# UnitSensitivity.jl
#
using EnergyModel

module UnitSensitivity

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnSensitivity::VariableArray{2} = ReadDisk(db,"EGInput/UnSensitivity") # [Unit,Year] Outage Rate Sensitivity to Decline in Driver (Driver/Driver)

  # Scratch Variables
end


function ECalibration(db)
  data = EControl(; db)
  (;Units) = data
  (;UnCogen,UnPlant,UnSensitivity) = data

  #
  ########################
  #
  # Renewable and Nuclear Units have no Outage Rate Sensitivity to Declines in Driver
  #
  @. UnSensitivity=0
  #
  # Fossil and Biomass Units have 100% Outage Rate Sensitivity to Declines in Driver
  #
  years=collect(Future:Final)
  for unit in Units
    if UnCogen[unit] > 0
      if (UnPlant[unit] == "OGCT") ||
          (UnPlant[unit] == "OGCC") ||
          (UnPlant[unit] == "SmallOGCC") ||
          (UnPlant[unit] == "NGCCS") ||
          (UnPlant[unit] == "OGSteam") ||
          (UnPlant[unit] == "Coal") ||
          (UnPlant[unit] == "CoalCCS") ||
          (UnPlant[unit] == "Biomass") ||
          (UnPlant[unit] == "BiomassCCS") ||
          (UnPlant[unit] == "Biogas")
        for year in years
          UnSensitivity[unit,year]=1
        end
      end
    end
  end

  WriteDisk(db,"EGInput/UnSensitivity",UnSensitivity)

end

function CalibrationControl(db)
  @info "UnitSensitivity.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
