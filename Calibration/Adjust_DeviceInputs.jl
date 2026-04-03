#
# Adjust_DeviceInputs.jl 
#
using EnergyModel

module Adjust_DeviceInputs

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  Input::String = "RInput"

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

  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1]  
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Enduses) = data
  (;CurTime,xDEE,xDCC) = data

  #
  # Set missing values in CurTime to 0.0 to match prior versions
  #
  curtime = Int(CurTime)

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDEE[enduse,tech,ec,area,curtime] = max(xDEE[enduse,tech,ec,area,curtime], 0.0)
    xDCC[enduse,tech,ec,area,curtime] = max(xDCC[enduse,tech,ec,area,curtime], 0.0)
  end

  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDCC",xDCC)

end

Base.@kwdef struct CControl
  db::String

  Input::String = "CInput"

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

  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1]  
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Enduses) = data
  (;CurTime,xDEE,xDCC) = data

  #
  # Set missing values in CurTime to 0.0 to match prior versions
  #
  curtime = Int(CurTime)

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDEE[enduse,tech,ec,area,curtime] = max(xDEE[enduse,tech,ec,area,curtime], 0.0)
    xDCC[enduse,tech,ec,area,curtime] = max(xDCC[enduse,tech,ec,area,curtime], 0.0)
  end

  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDCC",xDCC)

end

Base.@kwdef struct IControl
  db::String

  Input::String = "IInput"

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

  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1]  
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Enduses) = data
  (;CurTime,xDEE,xDCC) = data

  #
  # Set missing values in CurTime to 0.0 to match prior versions
  #
  curtime = Int(CurTime)

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDEE[enduse,tech,ec,area,curtime] = max(xDEE[enduse,tech,ec,area,curtime], 0.0)
    xDCC[enduse,tech,ec,area,curtime] = max(xDCC[enduse,tech,ec,area,curtime], 0.0)
  end

  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDCC",xDCC)

end

function CalibrationControl(db)
  @info "Adjust_DeviceInputs.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
