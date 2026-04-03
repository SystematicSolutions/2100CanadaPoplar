#
# CoalSupply_VB.jl
#
using EnergyModel

module CoalSupply_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
   db::String

  CalDB::String = "SpCalDB"
  Input::String = "SpInput"
  Outpt::String = "SpOutput"
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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vCImports::VariableArray{2} = ReadDisk(db,"VBInput/vCImports") # [vArea,Year] Coal Imports (TBtu/Yr)
  xImports::VariableArray{3} = ReadDisk(db,"SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  vCExports::VariableArray{2} = ReadDisk(db,"VBInput/vCExports") # [vArea,Year] Coal Exports (TBtu/Yr)
  xExports::VariableArray{3} = ReadDisk(db,"SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  CAProd::VariableArray{2} = ReadDisk(db,"SOutput/CAProd") # [Area,Year] Primary Coal Production (TBtu/Yr)
  xCAProd::VariableArray{2} = ReadDisk(db,"SpInput/xCAProd") # [Area,Year] Coal Production - Reference Case (TBtu/Yr)
  xCProd::VariableArray{2} = ReadDisk(db,"SpInput/xCProd") # [Area,Year] 'Coal Production - Reference Case (TBtu/Yr)',
  vCProd::VariableArray{2} = ReadDisk(db,"VBInput/vCProd") # [Area,Year] Coal Production (TBtu/Yr)

  # Scratch Variables
  xCExports::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Coal Exports (TBtu/Yr)
  xCImports::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Coal Imports (TBtu/Yr)
end

function SCalibration(db)
  data = SControl(; db)
  (;Input) = data
  (;Area,Areas,FuelEP,Nation,Nations) = data
  (;Area,FuelEP,Nation,ANMap) = data
  (;Years,vArea) = data
  (;vCImports,xImports,vCExports,xExports,CAProd,xCAProd,xCProd,vCProd) = data
  (;xCExports,xCImports) = data
  
  Coal=Select(FuelEP,"Coal")
  AreasCanada = Select(Area, (from = "ON", to = "NU"))
  CN=Select(Nation,"CN")
  #
  # Imports
  # 
  for area in AreasCanada,year in Years
    varea = Select(vArea,Area[area])
    xCImports[area,year]=vCImports[varea,year]
    xImports[Coal,CN,year]=sum(xCImports[area,year] for area in Areas)
  end
  WriteDisk(db,"$Input/xImports",xImports)
  # 
  # Exports
  # 
  for area in AreasCanada,year in Years
    varea = Select(vArea,Area[area])
    xCExports[area,year]=vCExports[varea,year]
    xExports[Coal,CN,year]=sum(xCExports[area,year] for area in Areas)
  end
  WriteDisk(db,"$Input/xExports",xExports)
  
  # Coal Production
  
  for area in Areas,year in Years
    xCAProd[area,year]=vCProd[area,year]
  end
  # 
  # Fill in zeros
  # 
  years = collect(Future:Final)

  for area in Areas, year in years
    if xCAProd[area,year]==0.0
      if Area[area]!="NS"
        xCAProd[area,year]=xCAProd[area,year-1]
      end
    end
  end
  #
  # National coal production
  #
  for nation in Nations, year in Years
    xCProd[nation,year] = sum(xCAProd[area,year] * ANMap[area,nation] for area in Areas)
  end
  
  for area in Areas, year in Years
    CAProd[area,year]=xCAProd[area,year]
  end
  
  WriteDisk(db,"SOutput/CAProd",CAProd)
  WriteDisk(db,"$Input/xCProd",xCProd)
  WriteDisk(db,"$Input/xCAProd",xCAProd)
end

function CalibrationControl(db)
  @info "CoalSupply_VB.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
