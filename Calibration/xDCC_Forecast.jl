#
# xDCC_Forecast.jl
#
using EnergyModel

module xDCC_Forecast

import ...EnergyModel: ReadDisk,WriteDisk,Select, Last
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

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

  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
end


function RCalibration(db)
  data = RCalib(; db)
  (; Input) = data
  (; Areas,ECs,Enduses,Techs) = data
  (; DCMM,xDCC) = data
  #
  # If there is a forecast value for xDCC then adjust DCMM relative to the value in year
  # Last - Ian 02/28/25
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    #
    # Find most recent xDCC value
    #
    Loc1 = 1
    years=reverse(collect(Zero:Last))
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        Loc1 = year
      end
    end
    #
    # Calculate new DCMM if xDCC has a forecast value
    #
    years=collect(Future:Final)
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        @finite_math DCMM[enduse,tech,ec,area,year] = xDCC[enduse,tech,ec,area,year]/
            xDCC[enduse,tech,ec,area,Loc1]*DCMM[enduse,tech,ec,area,Loc1]
      end
    end
  end

  WriteDisk(db,"$Input/DCMM",DCMM)
end

Base.@kwdef struct CCalib
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
end


function CCalibration(db)
  data = CCalib(; db)
  (; Input) = data
  (; Areas,ECs,Enduses,Techs) = data
  (; DCMM,xDCC) = data
  #
  # If there is a forecast value for xDCC then adjust DCMM relative to the value in year
  # Last - Ian 02/28/25
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    #
    # Find most recent xDCC value
    #
    Loc1 = 1
    years=reverse(collect(Zero:Last))
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        Loc1 = year
      end
    end
    #
    # Calculate new DCMM if xDCC has a forecast value
    #
    years=collect(Future:Final)
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        @finite_math DCMM[enduse,tech,ec,area,year] = xDCC[enduse,tech,ec,area,year]/
            xDCC[enduse,tech,ec,area,Loc1]*DCMM[enduse,tech,ec,area,Loc1]
      end
    end
  end

  WriteDisk(db,"$Input/DCMM",DCMM)
end

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

  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
end


function ICalibration(db)
  data = ICalib(; db)
  (; Input) = data
  (; Areas,ECs,Enduses,Techs) = data
  (; DCMM,xDCC) = data
  #
  # If there is a forecast value for xDCC then adjust DCMM relative to the value in year
  # Last - Ian 02/28/25
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    #
    # Find most recent xDCC value
    #
    Loc1 = 1
    years=reverse(collect(Zero:Last))
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        Loc1 = year
      end
    end
    #
    # Calculate new DCMM if xDCC has a forecast value
    #
    years=collect(Future:Final)
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        @finite_math DCMM[enduse,tech,ec,area,year] = xDCC[enduse,tech,ec,area,year]/
            xDCC[enduse,tech,ec,area,Loc1]*DCMM[enduse,tech,ec,area,Loc1]
      end
    end
  end

  WriteDisk(db,"$Input/DCMM",DCMM)
end

Base.@kwdef struct TCalib
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
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

  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
end

function TCalibration(db)
  data = TCalib(; db)
  (; Input) = data
  (; Areas,ECs,Enduses,Techs) = data
  (; DCMM,xDCC) = data
  #
  # If there is a forecast value for xDCC then adjust DCMM relative to the value in year
  # Last - Ian 02/28/25
  #
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    #
    # Find most recent xDCC value
    #
    Loc1 = 1
    years=reverse(collect(Zero:Last))
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        Loc1 = year
      end
    end
    #
    # Calculate new DCMM if xDCC has a forecast value
    #
    years=collect(Future:Final)
    for year in years
      if xDCC[enduse,tech,ec,area,year] != -99
        @finite_math DCMM[enduse,tech,ec,area,year] = xDCC[enduse,tech,ec,area,year]/
            xDCC[enduse,tech,ec,area,Loc1]*DCMM[enduse,tech,ec,area,Loc1]
      end
    end
  end

  WriteDisk(db,"$Input/DCMM",DCMM)
end

function CalibrationControl(db)
  @info "xDCC_Forecast.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
