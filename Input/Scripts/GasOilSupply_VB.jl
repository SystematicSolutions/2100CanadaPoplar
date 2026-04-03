#
# GasOilSupply_VB.jl
#
#Select Output GasOilSupply_VB.log
#
using EnergyModel

module GasOilSupply_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
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
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xExports::VariableArray{3} = ReadDisk(db,"SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xGAProd::VariableArray{3} = ReadDisk(db,"SInput/xGAProd") # [Process,Area,Year] Gas Producer Consumption  (Tbtu/Yr)
  xGProd::VariableArray{3} = ReadDisk(db,"SInput/xGProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  xImports::VariableArray{3} = ReadDisk(db,"SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xOAProd::VariableArray{3} = ReadDisk(db,"SInput/xOAProd") # [Process,Area,Year] Oil Producer Consumption  (Tbtu/Yr)
  xOProd::VariableArray{3} = ReadDisk(db,"SInput/xOProd") # [Process,Nation,Year] Primary Oil Production (TBtu/Yr)
  vExports::VariableArray{3} = ReadDisk(db,"VBInput/vExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  vGAProd::VariableArray{3} = ReadDisk(db,"VBInput/vGAProd") # [Process,Area,Year] Gas Producer Consumption  (Tbtu/Yr)
  vImports::VariableArray{3} = ReadDisk(db,"VBInput/vImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  vOAProd::VariableArray{3} = ReadDisk(db,"VBInput/vOAProd") # [Process,Area,Year] Oil Producer Consumption  (Tbtu/Yr)

  # Scratch Variables
  GrowthRateA::VariableArray{1} = zeros(Float32,length(Area)) # [Area] Growth Rate
  GrowthRateN::VariableArray{1} = zeros(Float32,length(Nation)) # [Nation] Growth Rate
  GrowthRatePA::VariableArray{2} = zeros(Float32,length(Process),length(Area)) # [Process,Area] Growth Rate
  # LastOG::Vector{Int} # Last Year for Exogenous Production Forecast (Year)'
  # NextOG::Vector{Int} # One Year After Last Year for Exogenous Forecast (Year)'
  # RecentOG::Vector{Int} # Recent Year for Calculating Growth Rate (Year)'
end

function SCalibration(db)
  data = SControl(; db)
  (;Input)=data
  (;Area,Areas,FuelEPs,Nation,Nations) = data
  (;Process,Processs,Year,Years) = data
  (;ANMap,xExports,xGAProd,xGProd,xImports,xOAProd,xOProd,vExports,vGAProd,vImports) = data
  (;vOAProd) = data
  #(;GrowthRateA,GrowthRateN,GrowthRatePA,LastOG,NextOG,RecentOG) = data
  (;GrowthRateA,GrowthRateN,GrowthRatePA) = data
  
    
  for year in Years, nation in Nations, fuel in FuelEPs
    xExports[fuel,nation,year]=vExports[fuel,nation,year]
  end
  WriteDisk(db,"SpInput/xExports",xExports)
  
  for year in Years, nation in Nations, fuel in FuelEPs
    xImports[fuel,nation,year]=vImports[fuel,nation,year]
  end
  WriteDisk(db,"SpInput/xImports",xImports)
  
  # 
  # Last Year of Exogenous Forecast
  # 
  ITime=1985
  LastOG=2040-ITime+1
  RecentOG=max(LastOG-1,1)
  NextOG=LastOG+1
  
  # 
  # Oil and Gas Production
  # 
  for year in Years, area in Areas, process in Processs
    xGAProd[process,area,year]=vGAProd[process,area,year]
  end
  WriteDisk(db,"$Input/xGAProd",xGAProd)
  
  # 
  # Growth Rate
  # 
  for process in Processs, area in Areas
    @finite_math GrowthRatePA[process,area] = 
      log((xGAProd[process,area,LastOG]/xGAProd[process,area,RecentOG]))/
      (LastOG-RecentOG)
  end
  
  # 
  # Canada Total Gas Production and Processing
  # 
  for year in Years, nation in Nations, process in Processs
    areas=findall(ANMap[:,nation] .==1)
    if !isempty(areas)
      xGProd[process,nation,year]=sum(xGAProd[process,area,year] for area in areas)
    end
  end
  WriteDisk(db,"$Input/xGProd",xGProd)
  
  #
  # Oil Production
  #
  for year in Years, area in Areas, process in Processs
    xOAProd[process,area,year]=vOAProd[process,area,year]
  end
  WriteDisk(db,"$Input/xOAProd",xOAProd)
  
  for year in Years, nation in Nations, process in Processs
    areas=findall(ANMap[:,nation] .==1)
    if !isempty(areas)
      xOProd[process,nation,year]=sum(xOAProd[process,area,year] for area in areas)
    end
  end
  WriteDisk(db,"$Input/xOProd",xOProd)
end

function Control(db)
  @info "GasOilSupply_VB.jl - Control"
  SCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
