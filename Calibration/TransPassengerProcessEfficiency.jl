#
# TransPassengerProcessEfficiency.jl
#
using EnergyModel

module TransPassengerProcessEfficiency

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

  PEElas::VariableArray{5} = ReadDisk(db,"$Input/PEElas") # [Enduse,Tech,EC,Area,Year] Long Term Price Elasticity for Process Efficiency ($/Btu)
  PEESw::VariableArray{5} = ReadDisk(db,"$Input/PEESw") # [Enduse,Tech,EC,Area,Year] Switch for Process Efficiency (Switch)
  PEMX::VariableArray{4} = ReadDisk(db,"$Input/PEMX") # [Enduse,Tech,EC,Area] Ratio of Maximum to Average Process Efficiency ($/Btu/($/Btu))

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;EC,Areas,ECs,Techs,Enduses,Years) = data
  (;PEElas,PEESw,PEMX) = data

  #*
  #* Source: "Transportation Passenger Process Efficiency (VDT) Equation.xlsx"
  #*
  ecs = Select(EC,["Passenger","AirPassenger"])
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
   PEElas[enduse,tech,ec,area,year] = -0.830
  end
   
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    PEESw[enduse,tech,ec,area,year] = 5
  end
  
  for area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    PEMX[enduse,tech,ec,area] = 2.0
  end

  WriteDisk(db, "$Input/PEElas",PEElas)
  WriteDisk(db, "$Input/PEESw",PEESw)
  WriteDisk(db, "$Input/PEMX",PEMX)

end

function CalibrationControl(db)
  @info "TransPassengerProcessEfficiency.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
