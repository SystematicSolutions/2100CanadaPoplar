#
# GHG_VB_ElecUtility.jl - VBInput Electric Utility Pollution
#
using EnergyModel

module GHG_VB_ElecUtility

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "EGCalDB"
  Input::String = "EGInput"
  Outpt::String = "EGOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
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
  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vEUPOCX::VariableArray{5} = ReadDisk(db,"VBInput/vEUPOCX") # [FuelEP,Plant,Poll,vArea,Year] Electric Pollution Coefficient (Tonnes/TBtu)

  # Scratch Variables
end


function ECalibration(db)
  data = EControl(; db)
  (;Input) = data
  (;Area,Areas) = data
  (;FuelEPs) = data
  (;Plants,Poll,Years,vArea,vAreas) = data
  (;vEUPOCX,POCX,vAreaMap) = data
  
  
  println("Reading Electric GHG POCX")  
  
  GHGs = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
    
  for fuel in FuelEPs,plant in Plants,poll in GHGs, area in AreasCanada,year in Years
    POCX[fuel,plant,poll,area,year]=0
  end

  for fuel in FuelEPs,plant in Plants,poll in GHGs,area in AreasCanada,year in Years
    vareas = findall(vAreaMap[area,:] .==1)
    POCX[fuel,plant,poll,area,year]=sum(vEUPOCX[fuel,plant,poll,varea,year] for varea in vareas)
  end
  
  years = collect(Future:Final)
  
  for fuel in FuelEPs,plant in Plants,poll in GHGs,area in AreasCanada,year in years
    POCX[fuel,plant,poll,area,year]=POCX[fuel,plant,poll,area,year-1]
  end
  WriteDisk(db,"$Input/POCX",POCX)
end

function CalibrationControl(db)
  @info "GHG_VB_ElecUtility.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
