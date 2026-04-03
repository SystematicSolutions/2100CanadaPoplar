#
# DeviceThermalMaxEfficiency.jl
#
using EnergyModel

module DeviceThermalMaxEfficiency

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEEThermalMax::VariableArray{4} = ReadDisk(db,"$Input/DEEThermalMax") # [Enduse,Tech,EC,Area] Thermal Maximum Device Efficiency (Btu/Btu)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;ECs,Enduse) = data
  (;Nation,Tech) = data
  (;ANMap,DEEThermalMax) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # Limit max efficiency for Heat/HW for traditional technologies
  #
  enduses = Select(Enduse,["Heat","HW"])
  techs = Select(Tech,["Electric","Gas","Coal","Oil","Biomass","LPG"])

  for enduse in enduses, tech in techs, ec in ECs, area in areas
    DEEThermalMax[enduse,tech,ec,area] = 1.0
  end
  
  WriteDisk(db,"$Input/DEEThermalMax",DEEThermalMax)
  
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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEEThermalMax::VariableArray{4} = ReadDisk(db,"$Input/DEEThermalMax") # [Enduse,Tech,EC,Area] Thermal Maximum Device Efficiency (Btu/Btu)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;ECs,Enduse) = data
  (;Nation,Tech) = data
  (;ANMap,DEEThermalMax) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # Limit max efficiency for Heat/HW for traditional technologies
  #
  enduses = Select(Enduse,["Heat","HW"])
  techs = Select(Tech,["Electric","Gas","Coal","Oil","Biomass","LPG"])

  for enduse in enduses, tech in techs, ec in ECs, area in areas
    DEEThermalMax[enduse,tech,ec,area] = 1.0
  end
  
  WriteDisk(db,"$Input/DEEThermalMax",DEEThermalMax)

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEEThermalMax::VariableArray{4} = ReadDisk(db,"$Input/DEEThermalMax") # [Enduse,Tech,EC,Area] Thermal Maximum Device Efficiency (Btu/Btu)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;ECs,Enduse) = data
  (;Nation,Tech) = data
  (;ANMap,DEEThermalMax) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # Limit max efficiency for Heat/HW for traditional technologies
  #
  enduses = Select(Enduse,"Heat")
  techs = Select(Tech,["Electric","Gas","Coal","Oil","Biomass","LPG"])

  for enduse in enduses, tech in techs, ec in ECs, area in areas
    DEEThermalMax[enduse,tech,ec,area] = 1.0
  end

  WriteDisk(db,"$Input/DEEThermalMax",DEEThermalMax)

end

function CalibrationControl(db)
  @info "DeviceThermalMaxEfficiency.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
