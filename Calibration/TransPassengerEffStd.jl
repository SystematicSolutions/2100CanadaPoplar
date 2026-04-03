#
# TransPassengerEffStd.jl - sets an efficiency 
# standard (DEStd) equal to the historical efficiency (xXDEE) which
# includes a standard.  
#
using EnergyModel

module TransPassengerEffStd

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Future,Final,Yr
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

  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu) 
  xXDEE::VariableArray{5} = ReadDisk(db,"$Input/xXDEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency w/ Standard (Btu/Btu) 

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Areas,Years,EC,ECs,Enduses,Techs) = data
  (;DEStd,xXDEE) = data
  
  #*
  #* Historical transportation efficiencies are assumed to be driven
  #* primarily by standards enacted rather than consumer choice.
  #*
  ec = Select(EC,"Passenger")
  years = collect(First:Final)
  for enduse in Enduses, tech in Techs, area in Areas, year in years
    if xXDEE[enduse,tech,ec,area,year] > 0
      DEStd[enduse,tech,ec,area,year] = xXDEE[enduse,tech,ec,area,year]
    else
      DEStd[enduse,tech,ec,area,year] = xXDEE[enduse,tech,ec,area,year-1]
    end
  end
 
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses  
    DEStd[enduse,tech,ec,area,Zero] = DEStd[enduse,tech,ec,area,First]
  end  

  WriteDisk(db,"$Input/DEStd",DEStd)

end

function CalibrationControl(db)
  @info "TransPassengerEffStd.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
