#
# OffsetReductions.jl - Sets parameters for offset reduction curves and
#                 switches for activating offset curve equations.
#
using EnergyModel

module OffsetReductions

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Offset::SetArray = ReadDisk(db,"MainDB/OffsetKey")
  OffsetDS::SetArray = ReadDisk(db,"MainDB/OffsetDS")
  Offsets::Vector{Int} = collect(Select(Offset))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ReA0::VariableArray{2} = ReadDisk(db,"MEInput/ReA0") # [Offset,Area] A Term in Reduction Curve ($/Tonne)
  ReB0::VariableArray{2} = ReadDisk(db,"MEInput/ReB0") # [Offset,Area] B Term in Reduction Curve ($/Tonne)
  ReC0::VariableArray{3} = ReadDisk(db,"MEInput/ReC0") # [Offset,Area,Year] C Term in Reduction Curve (Tonnes/Yr)
  ReC2H6PerCH4::VariableArray{3} = ReadDisk(db,"MEInput/ReC2H6PerCH4") # [Offset,Area,Year] Flaring C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  ReCapturedFraction::VariableArray{4} = ReadDisk(db,"MEInput/ReCapturedFraction") # [Offset,Poll,Area,Year] Reductions Captured Fraction (Tonnes/Yr)
  ReCCA0::VariableArray{2} = ReadDisk(db,"MEInput/ReCCA0") # [Offset,Area] A Term in Reduction Capital Cost Curve ($/$)
  ReCCB0::VariableArray{2} = ReadDisk(db,"MEInput/ReCCB0") # [Offset,Area] B Term in Reduction Capital Cost Curve ($/$)
  ReCCC0::VariableArray{3} = ReadDisk(db,"MEInput/ReCCC0") # [Offset,Area,Year] C Term in Reduction Capital Cost Curve ($/$)
  ReCCReplace::VariableArray{3} = ReadDisk(db,"MEInput/ReCCReplace") # [Offset,Area,Year] Reduction Replacement Capital Cost ($/Tonne CH4)
  ReCCSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReCCSwitch") # [Offset,Area,Year] Reduction Capital Cost Switch (1=Default)
  ReCD::VariableArray{1} = ReadDisk(db,"MEInput/ReCD") # [Offset] Reduction Construction Time (Years)
  ReCDOrder::VariableArray{2} = ReadDisk(db,"MEInput/ReCDOrder") # [Offset,Year] Number of Levels Reduction Construction Delay (Number)
  ReDevelopedFraction::VariableArray{3} = ReadDisk(db,"MEInput/ReDevelopedFraction") # [Offset,Area,Year] Fraction of Captured Gas Developed into Electric Generating Capacity (MW/MW)
  ReECC::SetArray = ReadDisk(db,"MEInput/ReECC") # [Offset] Reduction Economic Sector (Name)
  ReElectricPotentialFactor::VariableArray{3} = ReadDisk(db,"MEInput/ReElectricPotentialFactor") # [Offset,Area,Year] Electric Generating Capacity Potential from Captured Gas Factor (MW/MT)
  ReGFr::VariableArray{3} = ReadDisk(db,"MEInput/ReGFr") # [Offset,Area,Year] Reduction Grant Fraction ($/$)
  ReInvSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReInvSwitch") # [Offset,Area,Year] Reduction Investment Switch (1=Default)
  ReIVTC::VariableArray{3} = ReadDisk(db,"MEInput/ReIVTC") # [Offset,Area,Year] Reduction Investment Tax Credit ($/$)
  ReOCF::VariableArray{3} = ReadDisk(db,"MEInput/ReOCF") # [Offset,Area,Year] Reduction Operating Cost Factor ($/$)
  ReOMExpSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReOMExpSwitch") # [Offset,Area,Year] Reduction O&M Expenses Switch (1=Default)
  RePL::VariableArray{3} = ReadDisk(db,"MEInput/RePL") # [Offset,Area,Year] Reduction Physical Lifetime (Years)
  RePOCF::VariableArray{4} = ReadDisk(db,"MEInput/RePOCF") # [Offset,Poll,Area,Year] Reduction Factor (Tonnes/Tonnes)
  RePollutant::SetArray = ReadDisk(db,"MEInput/RePollutant") # [Offset] Reduction Main Pollutant (Name)
  RePriceSwitch::VariableArray{3} = ReadDisk(db,"MEInput/RePriceSwitch") # [Offset,Area,Year] Reduction Emission Price Switch (1=Default)
  RePriceX::VariableArray{3} = ReadDisk(db,"MEInput/RePriceX") # [Offset,Area,Year] Emission Exogenous Prices ($/Tonne)
  ReReductionsSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReReductionsSwitch") # [Offset,Area,Year] Reductions Switch (1=Default)
  ReReductionsX::VariableArray{3} = ReadDisk(db,"MEInput/ReReductionsX") # [Offset,Area,Year] Reductions Exogenous (Tonnes/Yr)
  ReROIN::VariableArray{3} = ReadDisk(db,"MEInput/ReROIN") # [Offset,Area,Year] Reduction Return on Investment ($/$)
  ReTL::VariableArray{3} = ReadDisk(db,"MEInput/ReTL") # [Offset,Area,Year] Reduction Tax Lifetime (Years)
  ReTxRt::VariableArray{3} = ReadDisk(db,"MEInput/ReTxRt") # [Offset,Area,Year] Reduction Tax Rate ($/$)
  ReType::SetArray = ReadDisk(db,"MEInput/ReType") # [Offset] Reduction Type (Name)

end

function OffsetData(db)
  data = MControl(; db)
  (;Area,Areas,Offset,Offsets) = data
  (;Years) = data
  (;ReA0,ReB0,ReC0,ReC2H6PerCH4,ReCapturedFraction,ReCCA0,ReCCB0,ReCCC0,ReCCReplace) = data
  (;ReCCSwitch,ReCD,ReCDOrder,ReDevelopedFraction,ReECC,ReElectricPotentialFactor,ReGFr,ReInvSwitch,ReIVTC,ReOCF) = data
  (;ReOMExpSwitch,RePL,RePOCF,RePollutant,RePriceSwitch,RePriceX,ReReductionsSwitch,ReReductionsX,ReROIN,ReTL) = data
  (;ReTxRt,ReType) = data

  @. ReA0 = 0
  @. ReB0 = 0
  @. ReC0 = 0
  WriteDisk(db,"MEInput/ReA0",ReA0)
  WriteDisk(db,"MEInput/ReB0",ReB0)
  WriteDisk(db,"MEInput/ReC0",ReC0)

  @. ReC2H6PerCH4 = 0.0
  WriteDisk(db,"MEInput/ReC2H6PerCH4",ReC2H6PerCH4)

  @. ReCapturedFraction = 0.00
  WriteDisk(db,"MEInput/ReCapturedFraction",ReCapturedFraction)

  @. ReCCA0 = 0
  @. ReCCB0 = 0
  @. ReCCC0 = 0
  WriteDisk(db,"MEInput/ReCCA0",ReCCA0)
  WriteDisk(db,"MEInput/ReCCB0",ReCCB0)
  WriteDisk(db,"MEInput/ReCCC0",ReCCC0)

  @. ReCCReplace = 0.0
  WriteDisk(db,"MEInput/ReCCReplace",ReCCReplace)

  @. ReCCSwitch = 1.0
  WriteDisk(db,"MEInput/ReCCSwitch",ReCCSwitch)

  @. ReCD = 5
  WriteDisk(db,"MEInput/ReCD",ReCD)

  @. ReCDOrder = 3
  WriteDisk(db,"MEInput/ReCDOrder",ReCDOrder)
  
  @. ReDevelopedFraction = 0.0
  WriteDisk(db,"MEInput/ReDevelopedFraction",ReDevelopedFraction)

  @. ReECC = "None" 
  offset = Select(Offset,"LFG")
  ReECC[offset] = "SolidWaste"
  offset = Select(Offset,"WWT")  
  ReECC[offset] = "Wastewater"  
  offset = Select(Offset,"AC")  
  ReECC[offset] = "SolidWaste"  
  offset = Select(Offset,"NERA")  
  ReECC[offset] = "CropProduction"    
  offset = Select(Offset,"AD")
  ReECC[offset] = "AnimalProduction"
  offset = Select(Offset,"WB")  
  ReECC[offset] = "CropProduction"   
  offset = Select(Offset,"Forestry")  
  ReECC[offset] = "Forestry"    
  offset = Select(Offset,"CO2Pipe")  
  ReECC[offset] = "LightOilMining"    
  offset = Select(Offset,"Generic")  
  ReECC[offset] = "None" 
  WriteDisk(db,"MEInput/ReECC",ReECC)

  @. RePollutant = "None"
  offset = Select(Offset,"LFG")
  RePollutant[offset] = "CH4"
  offset = Select(Offset,"WWT")  
  RePollutant[offset] = "CH4" 
  offset = Select(Offset,"AC")  
  RePollutant[offset] = "CH4" 
  offset = Select(Offset,"NERA")  
  RePollutant[offset] = "N2O"   
  offset = Select(Offset,"AD")
  RePollutant[offset] = "CH4"
  offset = Select(Offset,"WB")  
  RePollutant[offset] = "CH4" 
  offset = Select(Offset,"Forestry")  
  RePollutant[offset] = "CH4"    
  offset = Select(Offset,"CO2Pipe")  
  RePollutant[offset] = "CH4"  
  offset = Select(Offset,"Generic")  
  RePollutant[offset] = "None"
  WriteDisk(db,"MEInput/RePollutant",RePollutant)

  @. ReElectricPotentialFactor = 0.0
  WriteDisk(db,"MEInput/ReElectricPotentialFactor",ReElectricPotentialFactor)

  @. ReGFr = 0
  WriteDisk(db,"MEInput/ReGFr",ReGFr)

  @. ReInvSwitch = 1.0
  WriteDisk(db,"MEInput/ReInvSwitch",ReInvSwitch)

  @. ReIVTC = 0.00
  WriteDisk(db,"MEInput/ReIVTC",ReIVTC)

  @. ReOCF = 0.08
  WriteDisk(db,"MEInput/ReOCF",ReOCF)

  @. ReOMExpSwitch = 1
  WriteDisk(db,"MEInput/ReOMExpSwitch",ReOMExpSwitch)

  @. RePL = 20
  WriteDisk(db,"MEInput/RePL",RePL)

  @. RePOCF = 0.0
  WriteDisk(db,"MEInput/RePOCF",RePOCF)

  for year in Years, area in Areas, offset in Offsets
    RePriceSwitch[offset,area,year] = 1
  end
  AB = Select(Area,"AB")
  for year in Years, offset in Offsets
    RePriceSwitch[offset,AB,year] = 2
  end
  WriteDisk(db,"MEInput/RePriceSwitch",RePriceSwitch)

  @. RePriceX = 0.0
  WriteDisk(db,"MEInput/RePriceX",RePriceX)
  
  @. ReReductionsSwitch = 1
  WriteDisk(db,"MEInput/ReReductionsSwitch",ReReductionsSwitch)

  @. ReReductionsX = 0.0
  WriteDisk(db,"MEInput/ReReductionsX",ReReductionsX)

  @. ReROIN = 0.15
  WriteDisk(db,"MEInput/ReROIN",ReROIN)

  @. ReTL = RePL*0.80
  WriteDisk(db,"MEInput/ReTL",ReTL)

  @. ReTxRt = 0.35
  WriteDisk(db,"MEInput/ReTxRt",ReTxRt)

  @. ReType = "Process"
  WriteDisk(db,"MEInput/ReType",ReType)

end

function Control(db)
  @info "OffsetReductions.jl - Control"
  OffsetData(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
