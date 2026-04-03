#
# DeliveredPricesFuelSet_VB.jl - vData Fuel Price variables vFPBase, vFPTax, and vFPSM.
#
using EnergyModel

module DeliveredPricesFuelSet_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Last,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DeliveredPricesFuelSet_VBCalib
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
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FPSMF::VariableArray{4} = ReadDisk(db,"SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db,"SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  vFPBaseF::VariableArray{4} = ReadDisk(db,"VBInput/vFPBaseF") # [Fuel,ES,vArea,Year] Delivered Fuel Price without Taxes (Real $/mmBtu)
  vFPSMF::VariableArray{4} = ReadDisk(db,"VBInput/vFPSMF") # [Fuel,ES,vArea,Year] Energy Sales Tax ($/$)
  vFPTaxF::VariableArray{4} = ReadDisk(db,"VBInput/vFPTaxF") # [Fuel,ES,vArea,Year] Fuel Tax (Real $/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  xFPBaseF::VariableArray{4} = ReadDisk(db,"SInput/xFPBaseF") # [Fuel,ES,Area,Year] Delivered Fuel Price without Taxes (Real $/mmBtu)

  # Scratch Variables
end

function DCalibration(db)
  data = DeliveredPricesFuelSet_VBCalib(; db)
  (;Area,ESs,Fuels,Nation) = data
  (;Years,vArea) = data
  (;ANMap,FPSMF,FPTaxF,vFPBaseF,vFPSMF,vFPTaxF,xFPF,xFPBaseF) = data
  CN = Select(Nation,"CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)  
  # 
  # Base Price
  # 
  for fuel in Fuels, es in ESs,area in cn_areas,year in Years
    varea = Select(vArea,Area[area])
    xFPBaseF[fuel,es,area,year]=vFPBaseF[fuel,es,varea,year]
  end
  # 
  # Sales Tax
  #
  for fuel in Fuels, es in ESs,area in cn_areas,year in Years
    varea = Select(vArea,Area[area])
    FPSMF[fuel,es,area,year]=vFPSMF[fuel,es,varea,year]
  end
  # 
  # Excise Tax
  #
  for fuel in Fuels, es in ESs,area in cn_areas,year in Years
    varea = Select(vArea,Area[area])
    FPTaxF[fuel,es,area,year]=vFPTaxF[fuel,es,varea,year]
  end
  # 
  # Fill Historical Prices
  # 
  # years=collect(Future:Final)
  # for fuel in Fuels, es in ESs,area in cn_areas,year in years
  #   if xFPBaseF[fuel,es,area,year]==0
  #     xFPBaseF[fuel,es,area,year]=xFPBaseF[fuel,es,area,year+1]
  #   end
  # end
  years=reverse(collect(Zero:Last))
  for fuel in Fuels, es in ESs,area in cn_areas,year in years
    if xFPBaseF[fuel,es,area,year]==0
      xFPBaseF[fuel,es,area,year]=xFPBaseF[fuel,es,area,year+1]
    end
  end
  # 
  # Fill Future Taxes
  # 
  years=collect(Future:Final)
  for fuel in Fuels, es in ESs,area in cn_areas,year in years
    if FPSMF[fuel,es,area,year]==0
      FPSMF[fuel,es,area,year]=FPSMF[fuel,es,area,year-1]
    end
    if FPTaxF[fuel,es,area,year]==0
      FPTaxF[fuel,es,area,year]=FPTaxF[fuel,es,area,year-1]
    end
  end
  # 
  # Delivered Prices
  # 
  for fuel in Fuels, es in ESs,area in cn_areas,year in Years
    xFPF[fuel,es,area,year]=0
  end
  
  for fuel in Fuels, es in ESs,area in cn_areas,year in Years
    if xFPBaseF[fuel,es,area,year] > 0
      xFPF[fuel,es,area,year]=(xFPBaseF[fuel,es,area,year]+FPTaxF[fuel,es,area,year])*(1+FPSMF[fuel,es,area,year])
    else
      xFPF[fuel,es,area,year]=0
    end
  end
  WriteDisk(db,"SInput/FPSMF",FPSMF)
  WriteDisk(db,"SInput/FPTaxF",FPTaxF)
  WriteDisk(db,"SInput/xFPF",xFPF)
  WriteDisk(db,"SInput/xFPBaseF",xFPBaseF)
end

function CalibrationControl(db)
  @info "DeliveredPricesFuelSet_VB.jl - CalibrationControl"

  DCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
