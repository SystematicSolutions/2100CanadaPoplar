#
# FlowFraction_VB.jl - Energy Flow Fractions
#
using EnergyModel

module FlowFraction_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vExportsFraction::VariableArray{3} = ReadDisk(db,"VBInput/vExportsFraction") # [Fuel,vArea,Year] Exports Fraction (Btu/Btu)
  vImportsFraction::VariableArray{3} = ReadDisk(db,"VBInput/vImportsFraction") # [Fuel,vArea,Year] Imports Fraction (Btu/Btu)
  vInflowFraction::VariableArray{3}  = ReadDisk(db,"VBInput/vInflowFraction")  # [Fuel,vArea,Year] Domestic Inflow Fraction (Btu/Btu)
  vOutflowFraction::VariableArray{3} = ReadDisk(db,"VBInput/vOutflowFraction") # [Fuel,vArea,Year] Domestic Outflow Fraction (Btu/Btu)
  xExportsFraction::VariableArray{3} = ReadDisk(db,"SpInput/xExportsFraction") # [Fuel,Area,Year] Exports Fraction (Btu/Btu)
  xImportsFraction::VariableArray{3} = ReadDisk(db,"SpInput/xImportsFraction") # [Fuel,Area,Year] Imports Fraction (Btu/Btu)
  xInflowFraction::VariableArray{3}  = ReadDisk(db,"SpInput/xInflowFraction")  # [Fuel,Area,Year] Domestic Inflow Fraction (Btu/Btu)
  xOutflowFraction::VariableArray{3} = ReadDisk(db,"SpInput/xOutflowFraction") # [Fuel,Area,Year] Domestic Outflow Fraction (Btu/Btu)

end

function FlowFractions(db)
  data = SControl(; db)
  (;Area,Fuels,vArea,vAreas,Years) = data
  (;vInflowFraction,vOutflowFraction,vImportsFraction,vExportsFraction) = data  
  (;xInflowFraction,xOutflowFraction,xImportsFraction,xExportsFraction) = data

  for year in Years, varea in vAreas, fuel in Fuels
    area = Select(Area,vArea[varea])
    xImportsFraction[fuel,area,year] = vImportsFraction[fuel,varea,year]
  end
  WriteDisk(db,"SpInput/xImportsFraction",xImportsFraction)

  for year in Years, varea in vAreas, fuel in Fuels
    area = Select(Area,vArea[varea])
    xExportsFraction[fuel,area,year] = vExportsFraction[fuel,varea,year]
  end
  WriteDisk(db,"SpInput/xExportsFraction",xExportsFraction)

  for year in Years, varea in vAreas, fuel in Fuels
    area = Select(Area,vArea[varea])
    xInflowFraction[fuel,area,year] = vInflowFraction[fuel,varea,year]
  end
  WriteDisk(db,"SpInput/xInflowFraction",xInflowFraction)

  for year in Years, varea in vAreas, fuel in Fuels
    area = Select(Area,vArea[varea])
    xOutflowFraction[fuel,area,year] = vOutflowFraction[fuel,varea,year]
  end
  WriteDisk(db,"SpInput/xOutflowFraction",xOutflowFraction)

end

function Control(db)
  @info "FlowFraction_VB.jl - Control"
  FlowFractions(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
