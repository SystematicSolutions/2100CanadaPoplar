#
# UnitEICoverage.jl
#
using EnergyModel

module UnitEICoverage

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
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

  EICoverage::VariableArray{4} = ReadDisk(db,"EGInput/EICoverage") #  Fuels and Polutants included in Emission Intensity (1=Included)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Areas,FuelEPs,Poll,Years) = data
  (;EICoverage) = data

  ghg=Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  for year in Years, area in Areas, poll in ghg, fuelep in FuelEPs
    EICoverage[fuelep,poll,area,year]=1
  end
  # Select FuelEP(Biomass)
  # Select Poll(CO2)
  # EICoverage=1

  WriteDisk(db,"EGInput/EICoverage",EICoverage)

end

function CalibrationControl(db)
  @info "UnitEICoverage.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
