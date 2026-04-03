#
# Adjust_Transportation_VB.jl
#
# Ian 06/20/24
#
using EnergyModel

module Adjust_Transportation_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
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

  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xXDEE::VariableArray{5} = ReadDisk(db,"$Input/xXDEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency w/ Standard (Miles/mmBtu)

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,Tech) = data
  (;TechDS,Techs,Year,YearDS,Years) = data
  (;xDEE,xXDEE) = data

  #
  # Transportation_VB.txt is setting some values to 0.0 when it has a value in
  # vTrDEE. Patch this for now until we figure out cause. Note that code below
  # is looking for 'eq 0', not -99 (which is fine)
  #
  years=collect(First:Last)
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    if (xXDEE[enduse,tech,ec,area,year] == 0)
      xXDEE[enduse,tech,ec,area,year] = xXDEE[enduse,tech,ec,area,year-1]
      xDEE[enduse,tech,ec,area,year] = xXDEE[enduse,tech,ec,area,year]
    end
  end
  
  WriteDisk(db,"$Input/xXDEE",xXDEE)
  WriteDisk(db,"$Input/xDEE",xDEE)

end

function CalibrationControl(db)
  @info "Adjust_Transportation_VB.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
