#
# GHG_VB_RCI.jl - VBInput Emission Data
#
using EnergyModel

module GHG_VB_RCI

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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
  vFlPol::VariableArray{4} = ReadDisk(db,"VBInput/vFlPol") # [ECC,Poll,vArea,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  vFuPol::VariableArray{4} = ReadDisk(db,"VBInput/vFuPol") # [ECC,Poll,vArea,Year] Fugitive Emissions (Tonnes/Yr)
  vMEPol::VariableArray{4} = ReadDisk(db,"VBInput/vMEPol") # [ECC,Poll,vArea,Year] Non-Energy Pollution (Tonnes/Yr)
  vVnPol::VariableArray{4} = ReadDisk(db,"VBInput/vVnPol") # [ECC,Poll,vArea,Year] Fugitive Venting Emissions (Tonnes/Yr)
  xFlPol::VariableArray{4} = ReadDisk(db,"SInput/xFlPol") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Fugitive Emissions (Tonnes/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)
  xVnPol::VariableArray{4} = ReadDisk(db,"SInput/xVnPol") # [ECC,Poll,Area,Year] Fugitive Venting Emissions (Tonnes/Yr)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,ECCs) = data
  (;Poll,Years,) = data
  (;vArea) = data
  (;vFlPol,vFuPol,vMEPol,vVnPol) = data
  (;xFlPol,xFuPol,xMEPol,xVnPol) = data
  
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  GHGs = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6","NF3"])
  @info "xMEPol"
  
  for ecc in ECCs, poll in GHGs, area in AreasCanada, year in Years
    varea = Select(vArea,Area[area])
    xMEPol[ecc,poll,area,year]=vMEPol[ecc,poll,varea,year]
  end

  WriteDisk(db,"SInput/xMEPol",xMEPol)
  
  @info "xFlPol"
  
  for ecc in ECCs, poll in GHGs, area in AreasCanada, year in Years
    varea = Select(vArea,Area[area])
    xFlPol[ecc,poll,area,year]=vFlPol[ecc,poll,varea,year]
  end
  WriteDisk(db,"SInput/xFlPol",xFlPol)
  
  
  @info "xFuPol"
  
  for ecc in ECCs, poll in GHGs, area in AreasCanada, year in Years
    varea = Select(vArea,Area[area])
    xFuPol[ecc,poll,area,year]=vFuPol[ecc,poll,varea,year]
  end
  WriteDisk(db,"SInput/xFuPol",xFuPol)
  
    
  @info "xVnPol"
  
  for ecc in ECCs, poll in GHGs, area in AreasCanada, year in Years
    varea = Select(vArea,Area[area])
    xVnPol[ecc,poll,area,year]=vVnPol[ecc,poll,varea,year]
  end
  WriteDisk(db,"SInput/xVnPol",xVnPol)
  
end

function CalibrationControl(db)
  @info "GHG_VB_RCI.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
