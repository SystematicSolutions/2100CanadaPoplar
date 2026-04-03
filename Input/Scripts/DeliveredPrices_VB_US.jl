#
# DeliveredPrices_VB_US.jl - vData Fuel Price variables vFPBase, vFPTax, and vFPSM.
#
using EnergyModel

module DeliveredPrices_VB_US

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DeliveredPrices_VB_USCalib
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vFPF::VariableArray{4} = ReadDisk(db,"VBInput/vFPF") # [Fuel,ES,Area,Year] Delivered Fuel Price,  including Taxes (Real $/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)

  # Scratch Variables
end

function DCalibration(db)
  data = DeliveredPrices_VB_USCalib(; db)
  (;ESs,Fuels,Nation) = data
  (;Years) = data
  (;ANMap,vFPF,xFPF) = data
  US = Select(Nation,"US")
  us_areas = findall(ANMap[:,US] .== 1.0)
  
  for fuel in Fuels,es in ESs,area in us_areas,year in Years
    xFPF[fuel,es,area,year]=vFPF[fuel,es,area,year]
  end
  WriteDisk(db,"SInput/xFPF",xFPF)
  
end

function CalibrationControl(db)
  @info "DeliveredPrices_VB_US.jl - CalibrationControl"

  DCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
