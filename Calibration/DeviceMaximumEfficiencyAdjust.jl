#
# DeviceMaximumEfficiencyAdjust.jl
#
using EnergyModel

module DeviceMaximumEfficiencyAdjust

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

  # Scratch Variables
  xDEEMax::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Historical Device Efficiency (Btu/Btu)
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,Techs,Years) = data
  (;DEM,xDEE) = data
  (;xDEEMax) = data

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
   xDEEMax[enduse,tech,ec,area] = -99
  end
  
  #*
  #*******************************************************************************
  #*
  #* DEM must be higher than any value for xDEE
  #*
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    for year in Years
      xDEEMax[enduse,tech,ec,area] = max(xDEEMax[enduse,tech,ec,area], xDEE[enduse,tech,ec,area,year])
    end
    if xDEEMax[enduse,tech,ec,area] > -99 && DEM[enduse,tech,ec,area] > 0
      DEM[enduse,tech,ec,area] = max(DEM[enduse,tech,ec,area], xDEEMax[enduse,tech,ec,area] * 1.02)
    end
  end

  WriteDisk(db,"$Input/DEM",DEM)

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

  # Scratch Variables
  xDEEMax::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Historical Device Efficiency (Btu/Btu)
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,Techs,Years) = data
  (;DEM,xDEE) = data
  (;xDEEMax) = data

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
     xDEEMax[enduse,tech,ec,area] = -99
  end
  
  #*
  #*******************************************************************************
  #*
  #* DEM must be higher than any value for xDEE
  #*
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    for year in Years
      xDEEMax[enduse,tech,ec,area] = max(xDEEMax[enduse,tech,ec,area], xDEE[enduse,tech,ec,area,year])
    end
    if xDEEMax[enduse,tech,ec,area] > -99 && DEM[enduse,tech,ec,area] > 0
      DEM[enduse,tech,ec,area] = max(DEM[enduse,tech,ec,area], xDEEMax[enduse,tech,ec,area] * 1.02)
    end
  end

  WriteDisk(db,"$Input/DEM",DEM)

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

  # Scratch Variables
  xDEEMax::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Historical Device Efficiency (Btu/Btu)
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,Techs,Years) = data
  (;DEM,xDEE) = data
  (;xDEEMax) = data

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
     xDEEMax[enduse,tech,ec,area] = -99
  end
  
  #*
  #*******************************************************************************
  #*
  #* DEM must be higher than any value for xDEE
  #*
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    for year in Years
      xDEEMax[enduse,tech,ec,area] = max(xDEEMax[enduse,tech,ec,area], xDEE[enduse,tech,ec,area,year])
    end
    if xDEEMax[enduse,tech,ec,area] > -99 && DEM[enduse,tech,ec,area] > 0
      DEM[enduse,tech,ec,area] = max(DEM[enduse,tech,ec,area], xDEEMax[enduse,tech,ec,area] * 1.02)
    end
  end

  WriteDisk(db,"$Input/DEM",DEM)

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

  # Scratch Variables
  xDEEMax::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Historical Device Efficiency (Btu/Btu)
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,Techs,Years) = data
  (;DEM,xDEE) = data
  (;xDEEMax) = data

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
     xDEEMax[enduse,tech,ec,area] = -99
  end
  
  #*
  #*******************************************************************************
  #*
  #* DEM must be higher than any value for xDEE
  #*
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    for year in Years
      xDEEMax[enduse,tech,ec,area] = max(xDEEMax[enduse,tech,ec,area], xDEE[enduse,tech,ec,area,year])
    end
    if xDEEMax[enduse,tech,ec,area] > -99 && DEM[enduse,tech,ec,area] > 0
      DEM[enduse,tech,ec,area] = max(DEM[enduse,tech,ec,area], xDEEMax[enduse,tech,ec,area] * 1.02)
    end
  end

  WriteDisk(db,"$Input/DEM",DEM)

end

function CalibrationControl(db)
  @info "DeviceMaximumEfficiencyAdjust.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
