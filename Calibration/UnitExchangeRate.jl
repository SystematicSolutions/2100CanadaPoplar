#
# UnitExchangeRate.jl
#
using EnergyModel

module UnitExchangeRate

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ExchangeRateUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateUnit") # [Unit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationUnit") # [Unit,Year] Inflation Index ($/$)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Unit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateUnit::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateUnit") # [Unit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationUnit::VariableArray{2} = ReadDisk(db,"MInput/xInflationUnit") # [Unit,Year] Inflation Index ($/$)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCounter::VariableArray{1} = ReadDisk(db,"EGInput/UnCounter") # [Year] Number of Units

end

function UnitInflationExchangeRate(db)
  data = MControl(; db)
  (;Area,Units,Years) = data
  (;ExchangeRateUnit,InflationUnit,xExchangeRate,xExchangeRateUnit) = data
  (;xInflation,xInflationUnit,UnArea,UnCounter) = data

  ActiveUnits=maximum(Int(UnCounter[year]) for year in Years)
  @info "ActiveUnits = $ActiveUnits "
  units = collect(1:ActiveUnits)
  #units = collect(1:2085)

  for unit in units
    area = Select(Area,UnArea[unit])
    for year in Years
      xExchangeRateUnit[unit,year] = xExchangeRate[area,year]
    end
    for year in Years        
      xInflationUnit[unit,year] = xInflation[area,year]
    end
    for year in Years    
      ExchangeRateUnit[unit,year] = xExchangeRateUnit[unit,year]
    end
    for year in Years        
      InflationUnit[unit,year] = xInflationUnit[unit,year]
    end
  end

  WriteDisk(db,"MOutput/ExchangeRateUnit",ExchangeRateUnit)
  WriteDisk(db,"MOutput/InflationUnit",InflationUnit)
  WriteDisk(db,"MInput/xExchangeRateUnit",xExchangeRateUnit)
  WriteDisk(db,"MInput/xInflationUnit",xInflationUnit)  

end

function Control(db)
  @info "UnitExchangeRate.jl - Control"
  UnitInflationExchangeRate(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
