#
# TransConversions.jl
#
using EnergyModel

module TransConversions

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PIDS::SetArray = ReadDisk(db,"$Input/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CFraction::VariableArray{5} = ReadDisk(db,"$Input/CFraction") # [Enduse,Tech,EC,Area,Year] Fraction of Production Capacity open to Conversion ($/$)
  xProcSw::VariableArray{2} = ReadDisk(db,"$Input/xProcSw") # [PI,Year] Procedure on/off Switch
  xXProcSw::VariableArray{2} = ReadDisk(db,"$Input/xXProcSw") # [PI,Year] Procedure on/off Switch
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  CnvrtEU::VariableArray{4} = ReadDisk(db,"$Input/CnvrtEU") # Conversion Switch [Enduse,EC,Area, Year]
   
end

function TCalibration(db)
  data = TCalib(; db)
  (;Areas,EC,ECs,Enduses,PI) = data
  (;Tech,Techs,Years) = data
  (;CFraction,xProcSw,xXProcSw) = data
  (;CnvrtEU, Endogenous,Input) = data
  
  Conversion = Select(PI,"Conversion")
  @. xProcSw[Conversion,Years] = Endogenous
  @. xXProcSw[Conversion,Years] = Endogenous
  
  WriteDisk(db,"$Input/xProcSw",xProcSw)
  WriteDisk(db,"$Input/xXProcSw",xXProcSw)
  
  Passenger = Select(EC,"Passenger")
  @. CnvrtEU[Enduses, Passenger,Areas,Years] = Endogenous
  WriteDisk(db,"$Input/CnvrtEU",CnvrtEU)
  
  @. CFraction[Enduses,Techs,ECs,Areas,Years] = 0.0
  
  tech1 = Select(Tech,["Motorcycle","BusElectric","BusNaturalGas","BusPropane",
  "BusFuelCell","TrainDiesel","TrainElectric"])
  tech2 = Select(Tech,(from="TrainFuelCell", to="OffRoad"))
  techs = union(tech1,tech2)
  
  @. CFraction[Enduses,Techs,Passenger,Areas,Years] = 1.0
  
  @. CFraction[Enduses,techs,Passenger,Areas,Years] = 0.0
  
  WriteDisk(db,"$Input/CFraction",CFraction)

end

function CalibrationControl(db)
  @info "TransConversions.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
