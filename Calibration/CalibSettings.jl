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

Base.@kwdef struct MCalib
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CalibLTime::VariableArray{1} = ReadDisk(db,"SInput/CalibLTime") # [Area] Last Year of Load Curve Calibration (Year)

end

function MCalibSettings(db)
  data = MCalib(; db)
  (;Area,Nation) = data
  (;ANMap,CalibLTime) = data
  
  nation = Select(Nation,"CN")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas 
    CalibLTime[area]=2023
  end
  
  nation = Select(Nation,"US")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas 
    CalibLTime[area]=2015
  end
  
  nation = Select(Nation,"MX")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas 
    CalibLTime[area]=2013
  end
  
  WriteDisk(db,"SInput/CalibLTime",CalibLTime)
end

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
  
  Loc1 = Int(CalibTime[ec,area]-ITime+1)
  years = collect(First:Loc1)
  for year in years, tech in Techs, enduse in Enduses
    YCUF[enduse,tech,ec,area,year]=0
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
    ProcessCalibTime(data,ec,area)
  end
  
  nation = Select(Nation,"US")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2050     
    ProcessCalibTime(data,ec,area)
  end  
  
  nation = Select(Nation,"CN")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2023
    ProcessCalibTime(data,ec,area)
  end
  
  WriteDisk(db,"$Input/CalibTime",CalibTime)
  WriteDisk(db,"$Input/YCUF",YCUF)

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    YMMSM[enduse,tech,ec,area,Zero]=16
  end  
  WriteDisk(db,"$Input/YMMSM",YMMSM)

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
  
  Loc1 = Int(CalibTime[ec,area]-ITime+1)
  years = collect(First:Loc1)
  for year in years, tech in Techs, enduse in Enduses
    YCUF[enduse,tech,ec,area,year]=0
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

function CCalibSettings(db)
  data = CCalib(; db)
  (;Input) = data
  (;Area,Areas,ECs,Enduses,Nation,Techs) = data
  (;ANMap,CalibTime,YCUF,YMMSM) = data

  nation = Select(Nation,"MX")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs   
    CalibTime[ec,area]=2050   
    ProcessCalibTime(data,ec,area)
  end
  
  nation = Select(Nation,"US")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2050   
    ProcessCalibTime(data,ec,area)
  end  
  
  nation = Select(Nation,"CN")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2023
    ProcessCalibTime(data,ec,area)
  end
  
  WriteDisk(db,"$Input/CalibTime",CalibTime)
  WriteDisk(db,"$Input/YCUF",YCUF)

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    YMMSM[enduse,tech,ec,area,Zero]=16
  end  
  WriteDisk(db,"$Input/YMMSM",YMMSM)

end

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"

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
  
  Loc1 = Int(CalibTime[ec,area]-ITime+1)
  years = collect(First:Loc1)
  for year in years, tech in Techs, enduse in Enduses
    YCUF[enduse,tech,ec,area,year]=0
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


function ICalibSettings(db)
  data = ICalib(; db)
  (;Input) = data
  (;Area,Areas,EC,ECs,Enduses,Nation,Techs) = data
  (;ANMap,CalibTime,YCUF,YMMSM) = data

  nation = Select(Nation,"MX")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2050   
    ProcessCalibTime(data,ec,area)
  end
  
  nation = Select(Nation,"US")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2050   
    ProcessCalibTime(data,ec,area)
  end 
  
  nation = Select(Nation,"CN")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2023
    ProcessCalibTime(data,ec,area)
  end  
  
  #
  # Canada Oil and Gas Industries are calibrated into the future
  #
  ecs = Select(EC,["LightOilMining",
                   "HeavyOilMining",
                   "FrontierOilMining",
                   "PrimaryOilSands",
                   "SAGDOilSands",
                   "CSSOilSands",
                   "OilSandsMining",
                   "OilSandsUpgraders",               
                   "ConventionalGasProduction",
                   "SweetGasProcessing",
                   "UnconventionalGasProduction",
                   "SourGasProcessing",
                   "LNGProduction"])
  for area in areas, ec in ecs
    CalibTime[ec,area]=2050
    Loc1 = Int(CalibTime[ec,area]-ITime+1)
    if Loc1 < Final    
      ProcessCalibTime(data,ec,area)
    else
      years = collect(First:Final)
      for year in years, tech in Techs, enduse in Enduses
        YCUF[enduse,tech,ec,area,year]=0
      end   
    end                    
  end                
  
  #
  # Hold OnFarmFuelUse forecast flat into future - Jeff Amlin 08/21/18
  #  
  ecs=Select(EC,"OnFarmFuelUse")
  for area in areas, ec in ecs
    CalibTime[ec,area] = 2050
    Loc1 = Int(CalibTime[ec,area]-ITime+1)
    if Loc1 < Final    
      ProcessCalibTime(data,ec,area)
    else
      years = collect(First:Final)
      for year in years, tech in Techs, enduse in Enduses
        YCUF[enduse,tech,ec,area,year]=0
      end   
    end                    
  end         

  WriteDisk(db,"$Input/CalibTime",CalibTime)
  WriteDisk(db,"$Input/YCUF",YCUF)
 
end

Base.@kwdef struct TCalib
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"

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
  
  Loc1 = Int(CalibTime[ec,area]-ITime+1)
  years = collect(First:Loc1)
  for year in years, tech in Techs, enduse in Enduses
    YCUF[enduse,tech,ec,area,year] = 0.00
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

function TCalibSettings(db)
  data = TCalib(; db)
  (;Input) = data
  (;Area,Areas,ECs,Enduses,Nation,Techs) = data
  (;ANMap,CalibTime,YCUF,YMMSM) = data

  nation = Select(Nation,"MX")
  areas = findall(ANMap[:,nation] .== 1) 
  for area in areas, ec in ECs  
    CalibTime[ec,area]=2050   
    ProcessCalibTime(data,ec,area)
  end
  
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2050   
    ProcessCalibTime(data,ec,area)
  end  
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1) 
  for area in areas, ec in ECs
    CalibTime[ec,area]=2023
    ProcessCalibTime(data,ec,area)
  end
  
  WriteDisk(db,"$Input/CalibTime",CalibTime)
  WriteDisk(db,"$Input/YCUF",YCUF)

  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    YMMSM[enduse,tech,ec,area,Zero]=4
  end  
  WriteDisk(db,"$Input/YMMSM",YMMSM)
end

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ESTime::VariableArray{1} = ReadDisk(db,"EGInput/ESTime") # [Area] Starting Year for Simulation

end

function ECalibSettings(db)
  data = ECalib(; db)
  (;ESTime,Areas) = data
  
  # 
  # Set all calibration start times to no earlier than 1990.
  # Test to see if 1990 will work as a beginning Year.
  # 
  for area in Areas
    ESTime[area]=min(max(ESTime[area],1990),xHisTime)
  end
  
  WriteDisk(db,"EGInput/ESTime",ESTime)
  
end

function Control(db)
  @info "CalibSettings.jl - Control"

  MCalibSettings(db)
  @info "RCalibSettings.jl - Control"
  RCalibSettings(db)
  @info "CCalibSettings.jl - Control"
  CCalibSettings(db)
  @info "ICalibSettings.jl - Control"
  ICalibSettings(db)
  @info "TCalibSettings.jl - Control"
  TCalibSettings(db)
  @info "ECalibSettings.jl - Control"
  ECalibSettings(db)

end


if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
