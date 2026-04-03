#
# This file sets non-energy pollution coefficient for electric HDV vehicles. 
# Audrey - 21.12.07
#
using EnergyModel

module CAC_HDV_Electric

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  TrMEPX::VariableArray{5} = ReadDisk(db,"$Input/TrMEPX") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/Vehicle Miles)

  # Scratch Variables
end

function TransCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;ECs,Nation,Poll) = data
  (;Tech) = data
  (;ANMap,TrMEPX) = data
  
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)  
  years = collect(Future:Final)
  
  HDV2B3Electric = Select(Tech,"HDV2B3Electric")
  HDV2B3Gasoline = Select(Tech,"HDV2B3Gasoline")
  HDV45Electric = Select(Tech,"HDV45Electric")
  HDV45Gasoline = Select(Tech,"HDV45Gasoline")
  HDV67Electric = Select(Tech,"HDV67Electric")
  HDV67Gasoline = Select(Tech,"HDV67Gasoline")
  HDV8Electric = Select(Tech,"HDV8Electric")
  HDV8Gasoline = Select(Tech,"HDV8Gasoline")

  polls = Select(Poll,["PM10","PM25","PMT"])
  
  for ec in ECs, poll in polls, area in areas, year in years
    TrMEPX[HDV2B3Electric,ec,poll,area,year] = TrMEPX[HDV2B3Gasoline,ec,poll,area,year]
    TrMEPX[HDV45Electric,ec,poll,area,year] = TrMEPX[HDV45Gasoline,ec,poll,area,year]
    TrMEPX[HDV67Electric,ec,poll,area,year] = TrMEPX[HDV67Gasoline,ec,poll,area,year]
    TrMEPX[HDV8Electric,ec,poll,area,year] = TrMEPX[HDV8Gasoline,ec,poll,area,year]
  end
  
  WriteDisk(db,"$Input/TrMEPX",TrMEPX)
  
end

function CalibrationControl(db)
  @info "CAC_HDV_Electric.jl - CalibrationControl"

  TransCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
