#
# AdjustDeliveredPrices.jl
#
using EnergyModel

module AdjustDeliveredPrices

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct AdjustDeliveredPricesCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [[Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)

  # Scratch Variables
end

function SCalibration(db)
  data = AdjustDeliveredPricesCalib(; db)
  (;Area,ES,Fuel) = data
  (;xFPF) = data

  #
  # Fix early Ontario and BC electric generation prices
  # - Jeff Amlin 6/23/13
  #
  es = Select(ES,"Electric")
  fuel = Select(Fuel,"HFO")
  years = collect(Yr(1985):Yr(1990))
  area = Select(Area,"ON")
  QC = Select(Area,"QC")
  for year in years
    xFPF[fuel,es,area,year] = xFPF[fuel,es,QC,year]
  end

  area = Select(Area,"BC")
  AB = Select(Area,"AB")
  for year in years
    xFPF[fuel,es,area,year] = xFPF[fuel,es,AB,year]
  end

  fuel = Select(Fuel,"NaturalGas")
  years = collect(Yr(1985):Yr(1991))
  area = Select(Area,"ON")
  QC = Select(Area,"QC")
  for year in years
    xFPF[fuel,es,area,year] = xFPF[fuel,es,QC,year]
  end

  WriteDisk(db,"SInput/xFPF",xFPF)

end

function CalibrationControl(db)
  @info "AdjustDeliveredPrices.jl - CalibrationControl"

  # TODOPromulaExtra - Omitting to Match Promula

  # SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
