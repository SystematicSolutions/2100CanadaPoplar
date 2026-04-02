#
# YDEMM03_All.jl 
#
using EnergyModel

module YDEMM03_All

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  YDEMM::VariableArray{4} = ReadDisk(db,"$Input/YDEMM") # [Enduse,Tech,Area,Year] DEMM Calibration Control
end

function RCalibration(db)
  data = RControl(; db)
  (;Input,Enduses,Techs,Areas) = data
  (;YDEMM) = data
  
  @info "Residential"
  
  for area in Areas, tech in Techs, enduse in Enduses
    YDEMM[enduse,tech,area,Zero] .= 3
  end
  WriteDisk(db,"$Input/YDEMM",YDEMM)
  
end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  YDEMM::VariableArray{4} = ReadDisk(db,"$Input/YDEMM") # [Enduse,Tech,Area,Year] DEMM Calibration Control
end

function CCalibration(db)
  data = CControl(; db)
  (;Input,Enduses,Techs,Areas) = data
  (;YDEMM) = data
  
  @info "Commercial"
  
  for area in Areas, tech in Techs, enduse in Enduses
    YDEMM[enduse,tech,area,Zero] .= 3
  end
  WriteDisk(db,"$Input/YDEMM",YDEMM)
  
end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  YDEMM::VariableArray{4} = ReadDisk(db,"$Input/YDEMM") # [Enduse,Tech,Area,Year] DEMM Calibration Control
end

function ICalibration(db)
  data = IControl(; db)
  (;Input,Enduses,Techs,Areas) = data
  (;YDEMM) = data
  
  @info "Industrial"
  
  for area in Areas, tech in Techs, enduse in Enduses
    YDEMM[enduse,tech,area,Zero] .= 3
  end
  WriteDisk(db,"$Input/YDEMM",YDEMM)
  
end

function CalibrationControl(db)
  @info "YDEMM03_All.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
