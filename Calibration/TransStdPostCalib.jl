#
# TransStdPostCalib.jl - sets an efficiency standard (DEStd) 
# in the forecast equal to the marginal efficiency (DEE) of the last 
# yearor the existing standard (DEStd) whichever is larger.
# - revised Jeff Amlin 3/10/16
#
using EnergyModel

module TransStdPostCalib

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr, Last
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

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
  DEE::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu) 
  DEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu) 

  # Scratch Variables
end

function TCalibration(db)
  data = TCalib(; db)
  (;Areas,EC,ECs,Enduses,Nation) = data
  (;Tech,Techs) = data
  (;ANMap,DEE,DEEA,DEStd, Input) = data
  
  
  # *
  # * Passenger efficiency adjustment from Nathalie Trudeau (5/25/07)
  # *
  Passenger = Select(EC,"Passenger")
  
  # *
  # * Small Car efficiency adjustment
  # *
  techs = Select(Tech,(from="LDVGasoline",to="LDTFuelCell"))
  for enduse in Enduses, tech in techs, area in Areas
    DEStd[enduse,tech,Passenger,area,Last] = max(DEStd[enduse,tech,Passenger,area,Last],DEE[enduse,tech,Passenger,area,Last])
  end
  years = collect(Future:Final)
  for enduse in Enduses, tech in techs, area in Areas, year in years
    DEStd[enduse,tech,Passenger,area,year] = max(DEStd[enduse,tech,Passenger,area,year],DEStd[enduse,tech,Passenger,area,year-1])
  end
  
  # *
  # * Canada transportation marginal efficiencies are at least equal to the 
  # * average efficiency the last historical year. - Jeff Amlin 6/18/13
  # *
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  for enduse in Enduses, tech in Techs, area in areas, year in years, ec in ECs
    DEStd[enduse,tech,ec,area,year] = max(DEStd[enduse,tech,ec,area,year],DEEA[enduse,tech,ec,area,Last])
  end
  
  WriteDisk(db,"$Input/DEStd",DEStd)

end

function CalibrationControl(db)
  @info "TransStdPostCalib.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
