#
# Com_CalibrateProcessEfficiency.jl
#
using EnergyModel

module Com_CalibrateProcessEfficiency

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CERSM::VariableArray{4} = ReadDisk(db,"$CalDB/CERSM") # [Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)
  xPEE::VariableArray{5} = ReadDisk(db,"$Input/xPEE") # [Enduse,Tech,EC,Area,Year] Historical Process Efficiency ($/Btu) 

  # Scratch Variables
  # YrBeforeLast  'Year before Last Historical Year (Year)'
end

function CCalibration(db)
  data = CControl(; db)
  (; Input,ECs,Enduse,Enduses,Nation) = data
  (; Techs) = data
  (; ANMap,CERSM,xPEE) = data
  
  #
  # Canada 
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  YrBeforeLast=Last-1

  #
  # Space Heat
  #
  enduses = Select(Enduse,["Heat","AC"])
  
  #
  # Adjust the last value of xPEE by the distance from CERSM to 1.0
  #
  for area in areas, ec in ECs, tech in Techs, enduse in enduses
    if (CERSM[enduse,ec,area,Last] > 0.001) && (CERSM[enduse,ec,area,Last] < 10.0)
      @finite_math xPEE[enduse,tech,ec,area,Last] = xPEE[enduse,tech,ec,area,Last]/
        CERSM[enduse,ec,area,Last]
    end
  end

  #
  # Grow xPEE from First to match the last historical year value
  #
  years = collect(First:YrBeforeLast)
  for area in areas, ec in ECs, tech in Techs, enduse in enduses, year in years
    @finite_math xPEE[enduse,tech,ec,area,year] = xPEE[enduse,tech,ec,area,year-1] +
    ((xPEE[enduse,tech,ec,area,Last]-xPEE[enduse,tech,ec,area,Zero])/(Last-Zero))
  end
  
  WriteDisk(db,"$Input/xPEE",xPEE)

end

function Control(db)
  @info "Com_CalibrateProcessEfficiency.jl - Control"

  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
