#
# Trans_MassTransit.jl - Input for NEMS default industrial process
# improvements if applied after calibration.
#
using EnergyModel

module Trans_MassTransit

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr, Last
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TCalib
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DPConv::VariableArray{5} = ReadDisk(db,"$Input/DPConv") # [Enduse,Tech,EC,Area,Year] Device Process Conversion (Vehicle Mile/Passenger Mile)
  PDif::VariableArray{4} = ReadDisk(db,"$Input/PDif") # [Enduse,Tech,EC,Area] Difference between the Initial Process Efficiency for each Fuel

  # Scratch Variables
end

function TCalibration(db)
  data = TCalib(; db)
  (;Areas,EC,Enduses) = data
  (;Tech) = data
  (;Input,DPConv,PDif) = data
  
  # *
  # * Revise mass transit process efficiency to be 'vehicle-equivalent' using DPConv
  # *
  
  ecs = Select(EC,["Passenger","AirPassenger","ForeignPassenger"])
  tech1 = Select(Tech,(from="BusGasoline", to="TrainFuelCell"))
  tech2 = Select(Tech,(from="MarineHeavy", to="MarineFuelCell"))
  techs = union(tech1,tech2)
  LDVGasoline = Select(Tech,"LDVGasoline")
  for tech in techs, ec in ecs, area in Areas, enduse in Enduses
    @finite_math PDif[enduse,tech,ec,area] = DPConv[enduse,LDVGasoline,ec,area,Last] / DPConv[enduse,tech,ec,area,Last]
  end
  
  WriteDisk(db,"$Input/PDif",PDif)

end

function CalibrationControl(db)
  @info "Trans_MassTransit.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
