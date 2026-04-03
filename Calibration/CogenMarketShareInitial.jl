#
# CogenMarketShareInitial.jl - Initialize CgMSM0
#
using EnergyModel

module CogenMarketShareInitial

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgMSM0::VariableArray{4} = ReadDisk(db,"$CalDB/CgMSM0") # [Tech,EC,Area,Year] Cogeneration Market Share Non-Price Factor ($/$)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;CalDB) = data
  (;CgMSM0) = data
  #
  # Initialize CgMSM0 especially for the historical period - Jeff Amlin 5/19/23
  #
  @. CgMSM0=-170
  #
  WriteDisk(db,"$CalDB/CgMSM0",CgMSM0)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgMSM0::VariableArray{4} = ReadDisk(db,"$CalDB/CgMSM0") # [Tech,EC,Area,Year] Cogeneration Market Share Non-Price Factor ($/$)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;CalDB) = data
  (;CgMSM0) = data
  #
  # Initialize CgMSM0 especially for the historical period - Jeff Amlin 5/19/23
  #
  @. CgMSM0=-170
  #
  WriteDisk(db,"$CalDB/CgMSM0",CgMSM0)

end

function Control(db)
  @info "CogenMarketShareInitial.jl - CalibrationControl"

  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
