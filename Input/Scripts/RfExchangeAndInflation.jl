#
# RfExchangeAndInflation.jl - Assigns values to exchange rate and inflation variables
#
########################
#  - Assign values to new variables by RfUnit (xExchangeRate, xExchangeRateNation, xInflationNation)
########################
#
using EnergyModel

module RfExchangeAndInflation

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
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ExchangeRateRfUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateRfUnit") # [RfUnit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationRfUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationRfUnit") # [RfUnit,Year] Inflation Index ($/$)
  RfArea::Array{String} = ReadDisk(db,"SpInput/RfArea") # [RfUnit] Refinery Area
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateRfUnit::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateRfUnit") # [RfUnit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationRfUnit::VariableArray{2} = ReadDisk(db,"MInput/xInflationRfUnit") # [RfUnit,Year] Inflation Index ($/$)

  # Scratch Variables
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,AreaDS,Areas,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ExchangeRateRfUnit,InflationRfUnit,RfArea,xExchangeRate,xExchangeRateRfUnit,xInflation,xInflationRfUnit) = data

  for year in Years, area in Areas, rfunit in RfUnits
    if RfArea[rfunit] == Area[area]
      xExchangeRateRfUnit[rfunit,year]=xExchangeRate[area,year]
      xInflationRfUnit[rfunit,year]=xInflation[area,year]
    end
  end
  @. ExchangeRateRfUnit=xExchangeRateRfUnit
  @. InflationRfUnit=xInflationRfUnit

  WriteDisk(db,"MInput/xExchangeRateRfUnit", xExchangeRateRfUnit)
  WriteDisk(db,"MInput/xInflationRfUnit", xInflationRfUnit)
  WriteDisk(db,"MOutput/ExchangeRateRfUnit", ExchangeRateRfUnit)
  WriteDisk(db,"MOutput/InflationRfUnit", InflationRfUnit)


end

function CalibrationControl(db)
  @info "RfExchangeAndInflation.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
