#
# AdjustMarketShare_BusDiesel.jl
#
using EnergyModel

module AdjustMarketShare_BusDiesel

import ...EnergyModel: ReadDisk,WriteDisk,Select, Last
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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))  
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
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  CFraction::VariableArray{5} = ReadDisk(db,"$Input/CFraction") # [Enduse,Tech,EC,Area,Year] Fraction of Production Capacity open to Conversion ($/$)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
end


function TCalibration(db)
  data = TControl(; db)
  (;CalDB) = data
  (;CTechs,EC,Enduses,Nation,Tech,Years) = data
  (;ANMap,CMSM0,CFraction,MMSM0) = data

  Infinity = 1e37

  CN=Select(Nation,"CN")
  areas=findall(ANMap[:,CN] .== 1)
  years=collect(Future:Final)
  Passenger=Select(EC,"Passenger")
  BusDiesel=Select(Tech,"BusDiesel")
  eu=first(Enduses)
  for year in years, area in areas
    MMSM0[eu,BusDiesel,Passenger,area,year]=-170.00
  end
  #
  # Conversion NonPrice Factors
  #
  for year in years, area in areas
    if CFraction[eu,BusDiesel,Passenger,area,year] != 0
      for ctech in CTechs
        CMSM0[eu,BusDiesel,ctech,Passenger,area,year]=MMSM0[eu,BusDiesel,Passenger,area,year]
      end
    elseif CFraction[eu,BusDiesel,Passenger,area,year] == 0
      for ctech in CTechs
        CMSM0[eu,BusDiesel,ctech,Passenger,area,year]=-2*log(Infinity)
      end
    end
  end

  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$CalDB/CMSM0",CMSM0) 
end

function Control(db)
  @info "AdjustMarketShare_BusDiesel.jl - Control"

  TCalibration(db)
  
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
