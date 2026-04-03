#
# AdjustPEIFood_Res.jl
#
# This txp responds to advice from PEI regarding the recent and expected future
# use of Natural Gas in the Food & Tobacco industry. It also increases the share of electricity
# in the residential space heating sector, at the expense of Light Fuel Oil.
# Mark Radley, August 7, 2013
#
# Changed to Future instead of 2012 - Hilary 15.03.04.
#
#
using EnergyModel

module AdjustPEIFood_Res

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)

  # Scratch Variables
end

function ICalibration(db)
  data = ICalib(; db)
  (;Area,EC,Enduse,Tech) = data
  (;MMSM0, CalDB) = data
  
  years = collect(Future:Final)
  PE = Select(Area,"PE")
  Food = Select(EC,"Food")
  Gas = Select(Tech, "Gas")
  enduses = Select(Enduse,["Heat","OthSub"])
  
  @. MMSM0[enduses,Gas,Food,PE,years] = 0.0
  
  Oil = Select(Tech, "Oil")
  @. MMSM0[enduses,Oil,Food,PE,years] = -170.0
  
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)

end

Base.@kwdef struct RCalib
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)

  # Scratch Variables
end

function RCalibration(db)
  data = RCalib(; db)
  (;Area,EC,Enduse,Tech) = data
  (;MMSM0, CalDB) = data
  
  years = collect(Future:Final)
  PE = Select(Area,"PE")
  ecs = Select(EC,(from="SingleFamilyDetached",to="OtherResidential"))
  Electric = Select(Tech,"Electric")
  Heat = Select(Enduse,"Heat")
  
  @. MMSM0[Heat,Electric,ecs,PE,years] = 0.0
  
  Oil = Select(Tech,"Oil")
  @. MMSM0[Heat,Oil,ecs,PE,years] = -10.0
  
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)

end

function CalibrationControl(db)
  @info "AdjustPEIFood_Res.jl - CalibrationControl"

  ICalibration(db)
  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
