#
# OG_NGLiquidsFraction.jl - Pentane Plus and Condensates are function of NG production
#
using EnergyModel

module OG_NGLiquidsFraction

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
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  NGLiquidsFraction::VariableArray{3} = ReadDisk(db,"SpInput/NGLiquidsFraction") # [Process,Area,Year] NG Liquids Production as a Fraction of NG Production (Btu/Btu)
  xGAProd::VariableArray{3} = ReadDisk(db,"SInput/xGAProd") # [Process,Area,Year] Natural Gas Production (TBtu/Yr)
  xOAProd::VariableArray{3} = ReadDisk(db,"SInput/xOAProd") # [Process,Area,Year] Oil Production (TBtu/Yr)

  # Scratch Variables
  GasProduction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Gas Production (TBtu/Yr)
end

function SCalibration(db)
  data = SControl(; db)
  (;Areas,Process,Years) = data
  (;NGLiquidsFraction,xGAProd,xOAProd,GasProduction) = data

  # 
  # NG Liquids do not come from Associated Gas Production - Jeff Amlin 05/20/21
  # 
  processes = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction"])
  for area in Areas, year in Years
    GasProduction[area,year] = sum(xGAProd[p,area,year] for p in processes)
  end
  
  processes = Select(Process,["PentanesPlus","Condensates"])
  for process in processes, area in Areas, year in Years
    @finite_math NGLiquidsFraction[process,area,year ] =xOAProd[process,area,year]/GasProduction[area,year]
  end

  WriteDisk(db,"SpInput/NGLiquidsFraction",NGLiquidsFraction)

end

function CalibrationControl(db)
  @info "OG_NGLiquidsFraction.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
