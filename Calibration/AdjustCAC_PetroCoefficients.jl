#
# AdjustCAC_PetroCoefficients.jl
#
using EnergyModel

module AdjustCAC_PetroCoefficients

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,FuelEP) = data
  (;FuelEPDS,FuelEPs,Poll,PollDS,Polls,Year,YearDS) = data
  (;Years) = data
  (;POCX) = data

  #
  # For Ref25, adjust the coefficient for HFO in Petroleum Product Sector to the 2022 emission intensities
  #
  area = Select(Area,"ON")
  polls=Select(Poll,["COX","NOX"])
  ec=Select(EC,"Petroleum")
  fuelep = Select(FuelEP,"HFO")
  years = collect(Future:Final)
  for year in years, poll in polls, enduse in Enduses
    POCX[enduse,fuelep,ec,poll,area,year]=POCX[enduse,fuelep,ec,poll,area,Yr(2022)]
  end

  WriteDisk(db,"$Input/POCX",POCX)

end

function CalibrationControl(db)
  @info "AdjustCAC_PetroCoefficients.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
