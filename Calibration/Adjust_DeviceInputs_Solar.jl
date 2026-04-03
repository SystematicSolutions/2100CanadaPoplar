#
# Adjust_DeviceInputs_Solar.jl 
#
using EnergyModel

module Adjust_DeviceInputs_Solar

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

end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Tech,Enduse) = data
  (;CurTime,xDCC) = data

  #
  # OthSub Solar needs a value for xDCC - Use Heat for now - Ian 03/12/25
  #
  curtime = Int(max(CurTime,1))

  enduse=Select(Enduse,"OthSub")
  tech=Select(Tech,"Solar")
  Heat=Select(Enduse,"Heat")
  for area in Areas, ec in ECs
    xDCC[enduse,tech,ec,area,curtime] = xDCC[Heat,tech,ec,area,curtime]
  end

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

end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Tech,Enduse) = data
  (;CurTime,xDCC) = data

  #
  # OthSub Solar needs a value for xDCC - Use Heat for now - Ian 03/12/25
  #
  curtime = Int(max(CurTime,1))

  enduse=Select(Enduse,"OthSub")
  tech=Select(Tech,"Solar")
  Heat=Select(Enduse,"Heat")
  for area in Areas, ec in ECs
    xDCC[enduse,tech,ec,area,curtime] = xDCC[Heat,tech,ec,area,curtime]
  end

  WriteDisk(db,"$Input/xDCC",xDCC)

end

function CalibrationControl(db)
  @info "Adjust_DeviceInputs_Solar.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
