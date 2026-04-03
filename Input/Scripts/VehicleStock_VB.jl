#
# VehicleStock_VB.jl - Read xVehicleStock from VBInput
#
using EnergyModel

module VehicleStock_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  VehiclesPerPerson::VariableArray{2} = ReadDisk(db,"MInput/VehiclesPerPerson") # [Area,Year] Average Vehicle Stock Per Person (Vehicles/Person)
  xVehicleStock::VariableArray{3} = ReadDisk(db,"$Input/xVehicleStock") # [Tech,Area,Year] Stock of Vehicles (Vehicles)
  vVehicleStock::VariableArray{3} = ReadDisk(db,"VBInput/vVehicleStock") # [Tech,Area,Year] Stock of Vehicles (Vehicles)
  vVehiclesPerPerson::VariableArray{2} = ReadDisk(db,"VBInput/vVehiclesPerPerson") # [Area,Year] Average Vehicle Stock Per Person (Vehicles/Person)
end

function TCalibration(db)
  data = TControl(; db)
  (;Input,VehiclesPerPerson,xVehicleStock,vVehicleStock,vVehiclesPerPerson) = data

  VehiclesPerPerson .= vVehiclesPerPerson
  xVehicleStock .= vVehicleStock

  WriteDisk(db,"MInput/VehiclesPerPerson",VehiclesPerPerson)
  WriteDisk(db,"$Input/xVehicleStock",xVehicleStock)

end

function CalibrationControl(db)
  @info "VehicleStock_VB.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
