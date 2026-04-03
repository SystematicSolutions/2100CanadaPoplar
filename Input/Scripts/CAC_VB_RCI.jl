#
# CAC_VB_RCI.jl - VBInput Emission Data
#
using EnergyModel

module CAC_VB_RCI

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vCogFPol::VariableArray{5} = ReadDisk(db,"VBInput/vCogFPol") # [FuelEP,ECC,Poll,vArea,Year] Cogeneration Related Pollution (Tonnes/Yr)
  vEnFPol::VariableArray{5} = ReadDisk(db,"VBInput/vEnFPol") # [FuelEP,ECC,Poll,vArea,Year] Actual Energy Related Pollution (Tonnes/Yr)
  vFlPol::VariableArray{4} = ReadDisk(db,"VBInput/vFlPol") # [ECC,Poll,vArea,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  vFuPol::VariableArray{4} = ReadDisk(db,"VBInput/vFuPol") # [ECC,Poll,vArea,Year] Fugitive Emissions (Tonnes/Yr)
  vMEPol::VariableArray{4} = ReadDisk(db,"VBInput/vMEPol") # [ECC,Poll,vArea,Year] Non-Energy Pollution (Tonnes/Yr)
  vOREnFPol::VariableArray{5} = ReadDisk(db,"VBInput/vOREnFPol") # [FuelEP,ECC,Poll,vArea,Year] Off Road Actual Energy Related Pollution (Tonnes/Yr)
  vVnPol::VariableArray{4} = ReadDisk(db,"VBInput/vVnPol") # [ECC,Poll,vArea,Year] Fugitive Venting Emissions (Tonnes/Yr)
    
  xCgFPol::VariableArray{5} = ReadDisk(db,"SInput/xCgFPol") # [FuelEP,ECC,Poll,Area,Year] Cogeneration Related Pollution (Tonnes/Yr)
  xEnFPol::VariableArray{5} = ReadDisk(db,"SInput/xEnFPol") # [FuelEP,ECC,Poll,Area,Year] Actual Energy Related Pollution (Tonnes/Yr)
  xFlPol::VariableArray{4} = ReadDisk(db,"SInput/xFlPol") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Fugitive Emissions (Tonnes/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)
  xOREnFPol::VariableArray{5} = ReadDisk(db,"SInput/xOREnFPol") # [FuelEP,ECC,Poll,Area,Year] Off Road Actual Energy Related Pollution (Tonnes/Yr)
  xORMEPol::VariableArray{4} = ReadDisk(db,"SInput/xORMEPol") # [ECC,Poll,Area,Year] Non-Energy Off Road Pollution (Tonnes/Yr)
  xVnPol::VariableArray{4} = ReadDisk(db,"SInput/xVnPol") # [ECC,Poll,Area,Year] Fugitive Venting Emissions (Tonnes/Yr)

  # Scratch Variables
end

function ReadVBInput(db)
  data = ECalib(; db)
  (;Area,ECCs,FuelEPs,Poll,Years) = data
  (;vArea) = data
  (;vCogFPol,vEnFPol,vFlPol,vFuPol,vMEPol,vOREnFPol,vVnPol,xCgFPol) = data
  (;xEnFPol,xFlPol,xFuPol,xMEPol,xOREnFPol,xVnPol) = data
  
  areas = Select(Area, (from = "ON", to = "NU"))
  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])
  
  @info "xMEPol"
  
  for ecc in ECCs, poll in polls, area in areas, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xMEPol[ecc,poll,area,year] = vMEPol[ecc,poll,varea,year]
  end

  years = collect(Yr(1985):Yr(1989))
  for ecc in ECCs, poll in polls, area in areas, year in years
      xMEPol[ecc,poll,area,year] = xMEPol[ecc,poll,area,Yr(1990)]
  end
  WriteDisk(db,"SInput/xMEPol",xMEPol)
  
  @info "xOREnFPol"
  
  for fuelep in FuelEPs, ecc in ECCs, poll in polls, area in areas, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xOREnFPol[fuelep,ecc,poll,area,year] = vOREnFPol[fuelep,ecc,poll,varea,year]
  end

  WriteDisk(db,"SInput/xOREnFPol",xOREnFPol)
  
  @info "xEnFPol"
  
  for fuelep in FuelEPs, ecc in ECCs, poll in polls, area in areas, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xEnFPol[fuelep,ecc,poll,area,year] = vEnFPol[fuelep,ecc,poll,varea,year]
  end

  WriteDisk(db,"SInput/xEnFPol",xEnFPol)
  
  @info "xCgFPol"
  
  for fuelep in FuelEPs, ecc in ECCs, poll in polls, area in areas, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xCgFPol[fuelep,ecc,poll,area,year] = vCogFPol[fuelep,ecc,poll,varea,year]
  end
  WriteDisk(db,"SInput/xCgFPol",xCgFPol)

  @info "xFlPol"
  
  for ecc in ECCs, poll in polls, area in areas, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xFlPol[ecc,poll,area,year] = vFlPol[ecc,poll,varea,year]
  end
  WriteDisk(db,"SInput/xFlPol",xFlPol)
  
  
  @info "xFuPol"
  
  for ecc in ECCs, poll in polls, area in areas, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xFuPol[ecc,poll,area,year] = vFuPol[ecc,poll,varea,year]
  end
  WriteDisk(db,"SInput/xFuPol",xFuPol)
  
    
  @info "xVnPol"
  
  for ecc in ECCs, poll in polls, area in areas, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xVnPol[ecc,poll,area,year] = vVnPol[ecc,poll,varea,year]
  end
  WriteDisk(db,"SInput/xVnPol",xVnPol)
  
end

function CalibrationControl(db)
  @info "CAC_VB_RCI.jl - CalibrationControl"
  ReadVBInput(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
