#
# ZeroEmissionFraction.jl
#
using EnergyModel

module ZeroEmissionFraction

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ZeroFr::VariableArray{4} = ReadDisk(db,"SInput/ZeroFr") # [FuelEP,Poll,Area,Year] Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes) 

  # Scratch Variables
end

function SCalibration(db)
  data = SControl(; db)
  (;FuelEP,Years,Areas,Poll,Polls,FuelEPs) = data
  (;ZeroFr) = data
  
  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
   ZeroFr[fuelep,poll,area,year] = 0.0 
  end  

  fuelep = Select(FuelEP,"Biomass")
  poll = Select(Poll,"CO2")
  for year in Years, area in Areas
   ZeroFr[fuelep,poll,area,year] = 1.00 
  end

  WriteDisk(db,"SInput/ZeroFr",ZeroFr)
  
end

function CalibrationControl(db)
  @info "ZeroEmissionFraction.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
