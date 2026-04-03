#
# Adjust_HeatPump_DCMM.jl - Adjustments to Heat Pumps to match NRCan forecast
# expectations. Original data in 'ECCC Inputs - NRCan Advice.xlsx' from Tim 
# on 23/08/23 - Ian
#
using EnergyModel

module Adjust_HeatPump_DCMM

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;ECs,Enduses) = data
  (;Nation,Tech) = data
  (;ANMap,DCMM) = data
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  HeatPump = Select(Tech,"HeatPump")
  years = collect(Future:Final)

  for enduse in Enduses, ec in ECs, area in areas, y in years
    DCMM[enduse,HeatPump,ec,area,y] = max(DCMM[enduse,HeatPump,ec,area,y-1]-0.01,0)
  end

  WriteDisk(db,"$Input/DCMM",DCMM)

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;ECs,Enduses) = data
  (;Nation,Tech) = data
  (;ANMap,DCMM) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  HeatPump = Select(Tech,"HeatPump")
  years = collect(Future:Yr(2030))

  for enduse in Enduses, ec in ECs, area in areas, y in years
    DCMM[enduse,HeatPump,ec,area,y] = max(DCMM[enduse,HeatPump,ec,area,y-1]-0.012,0)
  end

  years = collect(Yr(2031):Final)

  for enduse in Enduses, ec in ECs, area in areas, y in years
    DCMM[enduse,HeatPump,ec,area,y] = max(DCMM[enduse,HeatPump,ec,area,y-1]-0.005,0)
  end

  WriteDisk(db,"$Input/DCMM",DCMM)

end

function CalibrationControl(db)
  @info "Adjust_HeatPump_DCMM.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
