#
# DeliveredPrices_MX.jl
#
using EnergyModel

module DeliveredPrices_MX

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DeliveredPrices_MXCalib
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
  FPSMF::VariableArray{4} = ReadDisk(db,"SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db,"SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function DCalibration(db)
  data = DeliveredPrices_MXCalib(; db)
  (;Area,ESs,Fuel,Fuels,Nation) = data
  (;Years) = data
  (;ANMap,FPSMF,FPTaxF,xFPF) = data
  # 
  # Mexico Fuel Prices presumed equal to US/WSC Prices until getting further data.
  # 
  
  MX = Select(Nation,"MX")
  mx_areas = findall(ANMap[:,MX] .== 1.0)
  WSC = Select(Area,"WSC")
  
  for fuel in Fuels,es in ESs,area in mx_areas,year in Years
    xFPF[fuel,es,area,year]=xFPF[fuel,es,WSC,year]
  end
  WriteDisk(db,"SInput/xFPF",xFPF)
  # 
  # Mexico taxes - Gas and Diesel are subsidized, setting taxes to zero
  # prior to additional information.
  # 
  Gasoline = Select(Fuel,"Gasoline")
  for es in ESs,area in mx_areas,year in Years
    FPTaxF[Gasoline,es,area,year]=0.00
  end
   Diesel = Select(Fuel,"Diesel")
  for es in ESs,area in mx_areas,year in Years
    FPTaxF[Diesel,es,area,year]=0.00
  end
  WriteDisk(db,"SInput/FPTaxF",FPTaxF)
  # 
  #  Mexico Sales Tax
  #  Presumed zero due to subsidies.
  # 
  for fuel in Fuels,es in ESs,area in mx_areas,year in Years
    FPSMF[fuel,es,area,year]=0.00
  end
  WriteDisk(db,"SInput/FPSMF",FPSMF)
  # FPSMF=0.00
  # Select Area*, Nation*
  # *
  # Write Disk(FPSMF)
  # *
   end

function CalibrationControl(db)
  @info "DeliveredPrices_MX.jl - CalibrationControl"

  DCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
