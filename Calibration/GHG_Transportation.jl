#
# GHG_Transportation.jl - this file calculates the GHG coefficients
# for the transportation sector including the enduse (POCX), 
# cogeneration (CgPOCX), non-combustion (FsPOCX), and process (TrMEPX).
# Jeff Amlin 6/9/12
#
using EnergyModel

module GHG_Transportation

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
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  VDT::VariableArray{5} = ReadDisk(db,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  xTrMEPol::VariableArray{5} = ReadDisk(db,"$Input/xTrMEPol") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)

  # Scratch Variables
end

function TransCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;ECs,Enduses,Nation) = data
  (;Poll,Techs) = data
  (;Years) = data
  (;ANMap,TrMEPX,VDT,xTrMEPol) = data
  
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])

  # 
  #  Process Emission Coefficient (TrMEPX) are Process Emissions (TrMEPol)
  #  divided by Vehicle Distance Traveled (VDT).
  # 
  
  @. TrMEPX[Techs,ECs,polls,areas,Years] = 0.0
  for tech in Techs, ec in ECs, poll in polls, area in areas, year in Years
    @finite_math TrMEPX[tech,ec,poll,area,year] = xTrMEPol[tech,ec,poll,area,year] / 
                                                  sum(VDT[enduse,tech,ec,area,year] for enduse in Enduses)
  end
    
  # 
  #  Set coefficient equal to previous year only if it doesn't have a value
  #   
  years = collect(Future:Final)
  for tech in Techs, ec in ECs, poll in polls, area in areas, year in years
    if TrMEPX[tech,ec,poll,area,year] == 0.0
      TrMEPX[tech,ec,poll,area,year] = TrMEPX[tech,ec,poll,area,year-1]
    end
  end
  
  WriteDisk(db,"$Input/TrMEPX",TrMEPX)

end

function CalibrationControl(db)
  @info "GHG_Transportation.jl - CalibrationControl"

  TransCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
