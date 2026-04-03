#
# CAC_VB_Trans.jl - Moves VBInput data into transportation databases
#
using EnergyModel

module CAC_VB_Trans

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
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
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  
  vTrEnFPol::VariableArray{6} = ReadDisk(db,"VBInput/vTrEnFPol") # [FuelEP,Tech,EC,Poll,vArea,Year] Energy Pollution (Tonnes/Yr)
  vTrMEPol::VariableArray{5} = ReadDisk(db,"VBInput/vTrMEPol") # [Tech,EC,Poll,vArea,Year] Non-Energy Pollution (Tonnes/Yr)
  
  xTrEnFPol::VariableArray{7} = ReadDisk(db,"$Input/xTrEnFPol") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Energy Pollution (Tonnes/Yr)
  xTrMEPol::VariableArray{5} = ReadDisk(db,"$Input/xTrMEPol") # [Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr)

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,ECs,Enduses,FuelEPs,Poll,Techs,Years,vArea) = data
  (;vTrEnFPol,vTrMEPol,xTrEnFPol,xTrMEPol) = data
    
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  CACs = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])
    
  @info "Transfer Transportation TrEnFPol from VBInput"
  for eu in Enduses,fuelep in FuelEPs, tech in Techs,ec in ECs, poll in CACs, area in AreasCanada, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xTrEnFPol[eu,fuelep,tech,ec,poll,area,year]=vTrEnFPol[fuelep,tech,ec,poll,varea,year]
  end
  WriteDisk(db,"$Input/xTrEnFPol",xTrEnFPol)

  @info "Transfer Transportation TrMEPol from VBInput"
  for tech in Techs,ec in ECs, poll in CACs, area in AreasCanada, year in Years
    currentArea=Area[area]
    varea = Select(vArea,["$currentArea"])
    varea=varea[1]
    xTrMEPol[tech,ec,poll,area,year]=vTrMEPol[tech,ec,poll,varea,year]
  end
  WriteDisk(db,"$Input/xTrMEPol",xTrMEPol)
  
end

function CalibrationControl(db)
  @info "CAC_VB_Trans.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
