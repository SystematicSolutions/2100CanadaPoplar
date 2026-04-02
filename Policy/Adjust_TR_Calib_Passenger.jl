#
# Adjust_TR_Calib_Passenger.jl
#
# This file sets calibration variables equal to 2019 instead of 2020
# in order to avoid calibrating on data impacted by COVID
# for Passenger only. This should be moved to calibration instead of being called
# in REF22.bat, but this is a hot fix for the consultation case.
# Matt Lewis July 19, 2022
#

using EnergyModel

module Adjust_TR_Calib_Passenger

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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CERSM::VariableArray{4} = ReadDisk(db,"$CalDB/CERSM") # [Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)
  CUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor ($/Yr/$/Yr)
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu))
end

function TransPolicy(db)
  data = TControl(; db)
  (; CalDB) = data
  (; Areas,EC,Enduses,Nation,Techs) = data 
  (; ANMap,CERSM,CUF,DEMM,MMSM0,PEMM) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)

  Passenger = Select(EC,"Passenger")
  years = collect(Future:Final)
  for year in years, area in areas, enduse in Enduses
    CERSM[enduse,Passenger,area,year] = 
      CERSM[enduse,Passenger,area,Yr(2019)]
  end
  
  for year in years, area in areas, tech in Techs, enduse in Enduses
    DEMM[enduse,tech,Passenger,area,year] = 
      DEMM[enduse,tech,Passenger,area,Yr(2019)]
  end
  
  for year in years, area in areas, tech in Techs, enduse in Enduses
    MMSM0[enduse,tech,Passenger,area,year] = 
      MMSM0[enduse,tech,Passenger,area,Yr(2019)]
  end
  
  for year in years, area in areas, tech in Techs, enduse in Enduses
    PEMM[enduse,tech,Passenger,area,year] = 
      PEMM[enduse,tech,Passenger,area,Yr(2019)]
  end

  years = collect(Future:Final)
  for eu in Enduses, tech in Techs, area in areas, year in years
    if CUF[eu,tech,Passenger,area,Yr(2019)] != 0
      CUF[eu,tech,Passenger,area,year] = 
        CUF[eu,tech,Passenger,area,Yr(2019)]
    end
    
  end

  WriteDisk(db,"$CalDB/CERSM",CERSM)
  WriteDisk(db,"$CalDB/CUF",CUF)
  WriteDisk(db,"$CalDB/DEMM",DEMM)
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$CalDB/PEMM",PEMM)
end

function PolicyControl(db)
  @info "Adjust_TR_Calib_Passenger.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
