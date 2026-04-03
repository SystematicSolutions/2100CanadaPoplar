#
# DeviceEfficiencyMultiplierForecast.jl - This file must be run after
# the Demand Calibration - Jeff Amlin 7/26/15
#
using EnergyModel

module DeviceEfficiencyMultiplierForecast

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RCalib
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu) 

  # Scratch Variables
  Mult::VariableArray{3} = zeros(Float32,length(Enduse),length(Tech),length(Year)) # [Enduse,Tech,Year] Multiplier for DEMM (Btu/Btu)
 # Yr2035   'Pointer to Year 2035'
end

function RCalibration(db)
  data = RCalib(; db)
  (;ECs,Enduse,Enduses,Nation) = data
  (;Tech,Techs) = data
  (;ANMap,DEMM,xDEE) = data
  (;Mult,CalDB) = data
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  years = collect(Future:Final)
  for area in areas, ec in ECs, enduse in Enduses, tech in Techs, year in years
    if xDEE[enduse,tech,ec,area,year] != -99
      @finite_math DEMM[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,year-1]/xDEE[enduse,tech,ec,area,year-1]*xDEE[enduse,tech,ec,area,year]
    else
      DEMM[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,year-1]
    end
  end
  # *
  # * Incorporate AEO efficiency increases into Maximum Device
  # * Multiplier (DEMM) in Forecast Period
  # *
  @. Mult = 1.0
  Heat = Select(Enduse,"Heat")
  HW = Select(Enduse,"HW")
  AC = Select(Enduse,"AC")
  
  Electric = Select(Tech,"Electric")
  Gas = Select(Tech,"Gas")
  Oil = Select(Tech,"Oil")
  Solar = Select(Tech,"Solar")
  
  Mult[Heat,Electric,Yr(2035)] = 1.000
  Mult[Heat,Gas,Yr(2035)] = 1.015 
  Mult[Heat,Oil,Yr(2035)] = 1.124
  Mult[Heat,Solar,Yr(2035)] = 1.000
  Mult[HW,Electric,Yr(2035)] = 1.000
  Mult[HW,Gas,Yr(2035)] =  1.000
  Mult[HW,Oil,Yr(2035)] = 1.156 
  Mult[HW,Solar,Yr(2035)] = 1.000
  Mult[AC,Electric,Yr(2035)] = 1.011
  Mult[AC,Gas,Yr(2035)] = 1.000
  Mult[AC,Oil,Yr(2035)] = 1.000
  Mult[AC,Solar,Yr(2035)] = 1.000
  
  years = collect(Future:Yr(2035))
  for year in years, enduse in Enduses, tech in Techs
    Mult[enduse,tech,year] = Mult[enduse,tech,year-1] + 
    ((Mult[enduse,tech,Yr(2035)]-Mult[enduse,tech,Future])/(Yr(2035)-Future))
  end
  
  years = collect(Yr(2035):Final)
  for year in years
    @. Mult[Enduses,Techs,year] = Mult[Enduses,Techs,Yr(2035)]
  end
  
  years = collect(Future:Final)
  for year in years, enduse in Enduses, tech in Techs,ec in ECs, area in areas
    @finite_math DEMM[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,year] * Mult[enduse,tech,year]
  end
  
  WriteDisk(db,"$CalDB/DEMM",DEMM)

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
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)

  # Scratch Variables
  Mult::VariableArray{3} = zeros(Float32,length(Enduse),length(Tech),length(Year)) # [Enduse,Tech,Year] Multiplier for DEMM (Btu/Btu)
 # Yr2035   'Pointer to Year 2035'
end

function CCalibration(db)
  data = CCalib(; db)
  (;ECs,Enduse,Enduses,Nation) = data
  (;Tech,Techs) = data
  (;ANMap,DEMM) = data
  (;Mult, CalDB) = data
  
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  
  @. Mult = 1.0
  
  Heat = Select(Enduse,"Heat")
  HW = Select(Enduse,"HW")
  AC = Select(Enduse,"AC")
  
  Electric = Select(Tech,"Electric")
  Gas = Select(Tech,"Gas")
  Oil = Select(Tech,"Oil")
  
  Mult[Heat,Electric,Yr(2035)] = 1.010
  Mult[Heat,Gas,Yr(2035)] = 1.00
  Mult[Heat,Oil,Yr(2035)] = 1.00
  Mult[HW,Electric,Yr(2035)] = 1.0
  Mult[HW,Gas,Yr(2035)] = 1.061
  Mult[HW,Oil,Yr(2035)] = 1.00
  Mult[AC,Electric,Yr(2035)] = 1.427
  Mult[AC,Gas,Yr(2035)] = 1.00
  Mult[AC,Oil,Yr(2035)] = 1.00
  
  years = collect(Future:Yr(2035))
  for year in years, enduse in Enduses, tech in Techs
    Mult[enduse,tech,year] = Mult[enduse,tech,year-1] + 
    ((Mult[enduse,tech,Yr(2035)]-Mult[enduse,tech,Future])/(Yr(2035)-Future))
  end
  
  years = collect(Yr(2035):Final)
  for year in years
    @. Mult[Enduses,Techs,year] = Mult[Enduses,Techs,Yr(2035)]
  end
  
  years = collect(Future:Final)
  for year in years, enduse in Enduses, tech in Techs,ec in ECs, area in areas
    @finite_math DEMM[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,year] * Mult[enduse,tech,year]
  end
  
  WriteDisk(db,"$CalDB/DEMM",DEMM)

end

function CalibrationControl(db)
  @info "DeviceEfficiencyMultiplierForecast.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
