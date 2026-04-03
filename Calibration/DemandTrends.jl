#
# DemandTrends.jl
#
using EnergyModel

module DemandTrends

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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

  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmdTrend::VariableArray{5} = ReadDisk(db,"$Input/xDmdTrend") # [Enduse,Tech,EC,Area,Year] Trended Energy Demands (TBtu/Yr)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Enduses) = data
  (;xDmd,xDmdTrend) = data

  @. xDmdTrend = xDmd
  LastMinusOne = Last - 1

  years = collect(First:LastMinusOne)
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDmdTrend[enduse,tech,ec,area,year] = xDmdTrend[enduse,tech,ec,area,year-1] +
                               (xDmdTrend[enduse,tech,ec,area,Last] - xDmdTrend[enduse,tech,ec,area,Zero]) / (Last - Zero)
  end

  WriteDisk(db,"$Input/xDmdTrend",xDmdTrend)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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

  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmdTrend::VariableArray{5} = ReadDisk(db,"$Input/xDmdTrend") # [Enduse,Tech,EC,Area,Year] Trended Energy Demands (TBtu/Yr)

  # Scratch Variables
 # LastMinusOne 'Year Before the Last Historical Year'
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Enduses) = data
  (;xDmd,xDmdTrend) = data

  @. xDmdTrend = xDmd
  LastMinusOne = Last - 1

  years = collect(First:LastMinusOne)
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDmdTrend[enduse,tech,ec,area,year] = xDmdTrend[enduse,tech,ec,area,year-1] +
                               (xDmdTrend[enduse,tech,ec,area,Last] - xDmdTrend[enduse,tech,ec,area,Zero]) / (Last - Zero)
  end

  WriteDisk(db,"$Input/xDmdTrend",xDmdTrend)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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

  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmdTrend::VariableArray{5} = ReadDisk(db,"$Input/xDmdTrend") # [Enduse,Tech,EC,Area,Year] Trended Energy Demands (TBtu/Yr)

  # Scratch Variables
 # LastMinusOne 'Year Before the Last Historical Year'
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Enduses) = data
  (;xDmd,xDmdTrend) = data

  @. xDmdTrend = xDmd
  LastMinusOne = Last - 1

  years = collect(First:LastMinusOne)
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDmdTrend[enduse,tech,ec,area,year] = xDmdTrend[enduse,tech,ec,area,year-1] +
                               (xDmdTrend[enduse,tech,ec,area,Last] - xDmdTrend[enduse,tech,ec,area,Zero]) / (Last - Zero)
  end

  WriteDisk(db,"$Input/xDmdTrend",xDmdTrend)

end

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

  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDmdTrend::VariableArray{5} = ReadDisk(db,"$Input/xDmdTrend") # [Enduse,Tech,EC,Area,Year] Trended Energy Demands (TBtu/Yr)

  # Scratch Variables
 # LastMinusOne 'Year Before the Last Historical Year'
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Areas,ECs,Techs,Enduses) = data
  (;xDmd,xDmdTrend) = data

  @. xDmdTrend = xDmd
  LastMinusOne = Last - 1

  years = collect(First:LastMinusOne)
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDmdTrend[enduse,tech,ec,area,year] = xDmdTrend[enduse,tech,ec,area,year-1] +
                               (xDmdTrend[enduse,tech,ec,area,Last] - xDmdTrend[enduse,tech,ec,area,Zero]) / (Last - Zero)
  end

  WriteDisk(db,"$Input/xDmdTrend",xDmdTrend)

end

function CalibrationControl(db)
  @info "DemandTrends.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
