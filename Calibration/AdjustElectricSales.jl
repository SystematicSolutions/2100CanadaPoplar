#
# AdjustElectricSales.jl
#
using EnergyModel

module AdjustElectricSales

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct AdjustElectricSalesCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xSAECD::VariableArray{3} = ReadDisk(db,"SInput/xSaEC") # [ECC,Area,Year] Electricity Sales (GWh)

  # Scratch Variables
end

function AdjustElectricSalesCalibration(db)
  data = AdjustElectricSalesCalib(; db)
  (;Area,ECC) = data
  (;xSAECD) = data
  
  # *
  # * New Brunswick and Nova Scotia Streetlighting Sales are set to zero until
  # * we can adjust the electric sales forecasts.
  # * Set to zero in 2005 since this is when we start unit disptatch - J.Amlin 11/7/07
  # *
  
  Miscellaneous = Select(ECC,"Miscellaneous")
  areas = Select(Area, ["NB","NS"])
  years = collect(Yr(2005):Final)
  @. xSAECD[Miscellaneous,areas,years] = 0.0
  
  WriteDisk(db,"SInput/xSaEC",xSAECD)

end

function CalibrationControl(db)
  @info "AdjustElectricSales.jl - CalibrationControl"

  AdjustElectricSalesCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
