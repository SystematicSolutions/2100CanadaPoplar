#
# DeliveredPricesPricesSet_VB.jl - vData Fuel Price variables vFPBase, vFPTax, and vFPSM.
#
using EnergyModel

module DeliveredPricesPricesSet_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Last,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DeliveredPricesPricesSet_VBCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Prices::SetArray = ReadDisk(db,"MainDB/PricesKey")
  PricesDS::SetArray = ReadDisk(db,"MainDB/PricesDS")
  Pricess::Vector{Int} = collect(Select(Prices))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FPSM::VariableArray{3} = ReadDisk(db,"SInput/FPSM") # [Prices,Area,Year] Energy Sales Tax ($/$)
  FPTax::VariableArray{3} = ReadDisk(db,"SInput/FPTax") # [Prices,Area,Year] Fuel Tax (Real $/mmBtu)
  vFPBase::VariableArray{3} = ReadDisk(db,"VBInput/vFPBase") # [Prices,vArea,Year] Delivered Fuel Price without taxes (Real $/mmBtu)
  vFPSM::VariableArray{3} = ReadDisk(db,"VBInput/vFPSM") # [Prices,vArea,Year] Sales Tax for Delivered Prices ($/$)
  vFPTax::VariableArray{3} = ReadDisk(db,"VBInput/vFPTax") # [Prices,vArea,Year] Fuel Tax for Delivered Prices (Real $/mmBtu)
  xFP::VariableArray{3} = ReadDisk(db,"SInput/xFP") # [Prices,Area,Year] Delivered Fuel Price (Real $/mmBtu)
  xFPBase::VariableArray{3} = ReadDisk(db,"SInput/xFPBase") # [Prices,Area,Year] Delivered Fuel Price without taxes (Real $/mmBtu)

  # Scratch Variables
end

function DCalibration(db)
  data = DeliveredPricesPricesSet_VBCalib(; db)
  (;Area,Nation,Pricess) = data
  (;Years,vArea) = data
  (;ANMap,FPSM,FPTax,vFPBase,vFPSM,vFPTax,xFP,xFPBase) = data
  
  CN = Select(Nation,"CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)  
  # 
  # Base Price
  # 
  for price in Pricess,area in cn_areas,year in Years
    varea = Select(vArea,Area[area])
    xFPBase[price,area,year]=vFPBase[price,varea,year]
  end
  # 
  # Sales Tax
  # 
  for price in Pricess,area in cn_areas,year in Years
    varea = Select(vArea,Area[area])
    FPSM[price,area,year]=vFPSM[price,varea,year]
  end
  #
  # Excise Tax
  #
  for price in Pricess,area in cn_areas,year in Years
    varea = Select(vArea,Area[area])
    FPTax[price,area,year]=vFPTax[price,varea,year]
  end
  # 
  # Fill Historical Prices
  # 
  years=reverse(collect(Zero:Last))
  #years=collect(Last:Zero)
  println(years)
  #years=collect(Zero:Last)
  #println(years)
  for price in Pricess,area in cn_areas,year in years
    if xFPBase[price,area,year]==0
      xFPBase[price,area,year]=xFPBase[price,area,year+1]
    end
  end
  #
  # Fill Future Taxes
  #
  years=collect(Future:Final)
  for price in Pricess,area in cn_areas,year in years
    if FPSM[price,area,year]==0
      FPSM[price,area,year]=FPSM[price,area,year-1]
    end
    if FPTax[price,area,year]==0
      FPTax[price,area,year]=FPTax[price,area,year-1]
    end
  end
  # 
  # Delivered Prices
  # 
  for price in Pricess,area in cn_areas,year in Years
    xFP[price,area,year]=0
  end
  
  for price in Pricess,area in cn_areas,year in Years
    if xFPBase[price,area,year] > 0
      xFP[price,area,year]=(xFPBase[price,area,year]+FPTax[price,area,year])*(1+FPSM[price,area,year])
    else
      xFP[price,area,year]=0
    end
  end
  WriteDisk(db,"SInput/FPSM",FPSM)
  WriteDisk(db,"SInput/FPTax",FPTax)
  WriteDisk(db,"SInput/xFP",xFP)
  WriteDisk(db,"SInput/xFPBase",xFPBase)
end

function CalibrationControl(db)
  @info "DeliveredPricesPricesSet_VB.jl - CalibrationControl"

  DCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
