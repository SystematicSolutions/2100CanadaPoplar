#
# CalibSettings.jl
#
using EnergyModel

module CalibSettings

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,xHisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RCalib
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"

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
  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  YCUF::VariableArray{5} = ReadDisk(db,"$Input/YCUF") # [Enduse,Tech,EC,Area,Year] CUF Calibration Control
  YMMSM::VariableArray{5} = ReadDisk(db,"$Input/YMMSM") # [Enduse,Tech,EC,Area,Year] MSM Calibration Control

end

function ProcessCalibTime(data,ec,area)
  (;Enduses,Techs) = data
  (;CalibTime,YCUF) = data
  
  @info "Res ProcessCalibTime"
  
  Loc1 = Int(CalibTime[ec,area]-ITime+1)
  years = collect(First:Loc1)
  for year in years, tech in Techs, enduse in Enduses
    YCUF[enduse,tech,ec,area,year] = 0
  end  

  Loc1 = min(Loc1+1,Final+1)
  Loc2 = min(Loc1+4,Final+1)
  years = collect(Loc1:Loc2)
  for year in years, tech in Techs, enduse in Enduses
    YCUF[enduse,tech,ec,area,year] = -99
  end    
  
  Loc1 = min(Loc2+1,Final)
  years = collect(Loc1:Final)  
  for year in years, tech in Techs, enduse in Enduses
    YCUF[enduse,tech,ec,area,year] = 1.00
  end 
  
end

function RCalibSettings(db)
  data = RCalib(; db)
  (;Input) = data
  (;Area,Areas,ECs,Enduses,Nation,Techs) = data
  (;ANMap,CalibTime,YCUF,YMMSM) = data

  nation = Select(Nation,"MX")
  areas = findall(ANMap[:,nation] .== 1) 
  area = Select(Area,"MX")
  for ec in ECs
    CalibTime[ec,area] = 2050  
    @info "ec = $ec area = $area"
    @info typeof(ec)
    @info typeof(area)
    @info typeof(data)
    ProcessCalibTime(data,ec,area)
  end
  
  nation = Select(Nation,"US")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2050   
    @info typeof(ec)
    @info typeof(area)      
    ProcessCalibTime(data,ec,area)
  end  
  
  nation = Select(Nation,"CN")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2021
    ProcessCalibTime(data,ec,area)
  end
  
  WriteDisk(db,"$Input/CalibTime",CalibTime)
  WriteDisk(db,"$Input/YCUF",YCUF)

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    YMMSM[enduse,tech,ec,area,Zero]=16
  end  
  WriteDisk(db,"$Input/YMMSM",YMMSM)

end

function Control(db)
  @info "CalibSettings.jl - Control"

  RCalibSettings(db)

end


if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
