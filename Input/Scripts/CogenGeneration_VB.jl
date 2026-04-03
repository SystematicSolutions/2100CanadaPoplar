#
# CogenGeneration_VB.jl
#
using EnergyModel

module CogenGeneration_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CogenGeneration_VBCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vCgGen::VariableArray{4} = ReadDisk(db,"VBInput/vCgGen") # [Fuel,ECC,vArea,Year] Cogeneration Generation (GWh/Yr)  
  xCgGen::VariableArray{4} = ReadDisk(db,"SInput/xCgGen") # [Fuel,ECC,Area,Year] Cogeneration Generation (GWh/Yr)  
end

function CCalibration(db)
  data = CogenGeneration_VBCalib(; db)
  (;Areas,ECCs,Fuels,Nation,Years,vAreas) = data
  (;ANMap,vCgGen,xCgGen,vAreaMap) = data

  CN = Select(Nation,"CN")
  cn_areas = Select(ANMap[Areas,CN], ==(1))

  for fuel in Fuels, ecc in ECCs, area in cn_areas, year in Years
    xCgGen[fuel,ecc,area,year] = sum(vCgGen[fuel,ecc,varea,year]*vAreaMap[area,varea] for varea in vAreas) 
  end

  WriteDisk(db,"SInput/xCgGen",xCgGen)

end

function CalibrationControl(db)
  @info "CogenGeneration_VB.jl - CalibrationControl"

  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
