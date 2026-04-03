#
# Offsets_NERAgriculture.jl - Nitrous Oxide Emissions Reductions
# in Agriculture (NERA) includes implementation of Beneficial
# Nitrogen Management Practices for crop production to reduce
# N2O emissions associated with nitrogen fertilizer application.
#
using EnergyModel

module Offsets_NERAgriculture

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

  # Scratch Variables
end

function OffsetData(db)
  data = MControl(; db)
  (;Area,Nation,Offset,Poll) = data
  (;Years) = data
  (;ANMap,ReA0,ReB0,ReC0,ReC2H6PerCH4,ReCapturedFraction,ReCCA0,ReCCB0,ReCCC0,ReCCReplace) = data
  (;ReCCSwitch,ReCD,ReCDOrder,ReDevelopedFraction,ReECC,ReElectricPotentialFactor,ReGFr,ReInvSwitch,ReIVTC,ReOCF) = data
  (;ReOMExpSwitch,RePL,RePOCF,RePollutant,RePriceSwitch,RePriceX,ReReductionsSwitch,ReReductionsX,ReROIN,ReTL) = data
  (;ReTxRt,ReType) = data

  offset = Select(Offset,"NERA")
  CN = Select(Nation,"CN")

  AB = Select(Area,"AB")
  BC = Select(Area,"BC")
  MB = Select(Area,"MB")
  NB = Select(Area,"NB")
  NL = Select(Area,"NL")
  NS = Select(Area,"NS")
  ON = Select(Area,"ON")
  QC = Select(Area,"QC")
  SK = Select(Area,"SK")
  NT = Select(Area,"NT")
  PE = Select(Area,"PE")
  NU = Select(Area,"NU")
  YT = Select(Area,"YT")

  #
  # Agriculture (Crop Production) Process Emission Reductions
  # Source: "NERA Cost Curve v1.xlsx", Jeff Amlin 4/3/14
  # with data from Glasha 3/27/14
  #
  year = Yr(2007)
  poll = Select(Poll,"N2O")
  areas = Select(Area,["NL","PE","NS","NB","QC","ON","MB","SK","AB","BC","YT","NT","NU"])

  for area in areas
    ReA0[offset,area] = 1067.02
  end
  
  for area in areas
    ReB0[offset,area] = -2.5552
  end

  ReC0[offset,NL,year] = 0.0004 *1000
  ReC0[offset,PE,year] = 0.0146 *1000
  ReC0[offset,NS,year] = 0.0041 *1000
  ReC0[offset,NB,year] = 0.0086 *1000
  ReC0[offset,QC,year] = 0.1944 *1000
  ReC0[offset,ON,year] = 0.3804 *1000
  ReC0[offset,MB,year] = 0.6430 *1000
  ReC0[offset,SK,year] = 1.0307 *1000
  ReC0[offset,AB,year] = 0.8713 *1000
  ReC0[offset,BC,year] = 0.0201 *1000
  ReC0[offset,YT,year] = 0.0000 *1000
  ReC0[offset,NT,year] = 0.0000 *1000
  ReC0[offset,NU,year] = 0.0000 *1000 

  #
  # Set future values
  #
  years = collect(Yr(2008):Final)
  for year in years, area in areas
    ReC0[offset,area,year] = ReC0[offset,area,year-1]
  end
  
  WriteDisk(db,"MEInput/ReA0",ReA0)
  WriteDisk(db,"MEInput/ReB0",ReB0)
  WriteDisk(db,"MEInput/ReC0",ReC0)

  #
  ########################
  #

  for year in Years, area in areas
    ReC2H6PerCH4[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/ReC2H6PerCH4",ReC2H6PerCH4)

  for year in Years, area in areas
    ReCapturedFraction[offset,poll,area,year] = 0.00
  end
  WriteDisk(db,"MEInput/ReCapturedFraction",ReCapturedFraction)

  for year in Years, area in areas
    ReCCA0[offset,area] = 0
  end
  for year in Years, area in areas  
    ReCCB0[offset,area] = 0
  end
  for year in Years, area in areas
    ReCCC0[offset,area,year] = 0
  end
  WriteDisk(db,"MEInput/ReCCA0",ReCCA0)
  WriteDisk(db,"MEInput/ReCCB0",ReCCB0)
  WriteDisk(db,"MEInput/ReCCC0",ReCCC0)

  for year in Years, area in areas
    ReCCReplace[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/ReCCReplace",ReCCReplace)

  for year in Years, area in areas
    ReCCSwitch[offset,area,year] = 1.0
  end
  WriteDisk(db,"MEInput/ReCCSwitch",ReCCSwitch)

  ReCD[offset] = 3
  WriteDisk(db,"MEInput/ReCD",ReCD)

  for year in Years
    ReCDOrder[offset,year] = 2
  end
  WriteDisk(db,"MEInput/ReCDOrder",ReCDOrder)

  for year in Years, area in areas
    ReDevelopedFraction[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/ReDevelopedFraction",ReDevelopedFraction)

  ReECC[offset] = "CropProduction"
  WriteDisk(db,"MEInput/ReECC",ReECC)

  for year in Years, area in areas
    ReElectricPotentialFactor[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/ReElectricPotentialFactor",ReElectricPotentialFactor)

  for year in Years, area in areas
    ReGFr[offset,area,year] = 0
  end
  WriteDisk(db,"MEInput/ReGFr",ReGFr)

  for year in Years, area in areas
    ReInvSwitch[offset,area,year] = 1.0
  end
  WriteDisk(db,"MEInput/ReInvSwitch",ReInvSwitch)

  for year in Years, area in areas
    ReIVTC[offset,area,year] = 0.00
  end
  WriteDisk(db,"MEInput/ReIVTC",ReIVTC)

  for year in Years, area in areas
    ReOCF[offset,area,year] = 0.08
  end
  WriteDisk(db,"MEInput/ReOCF",ReOCF)

  for year in Years, area in areas
    ReOMExpSwitch[offset,area,year] = 1
  end
  WriteDisk(db,"MEInput/ReOMExpSwitch",ReOMExpSwitch)

  for year in Years, area in areas
    RePL[offset,area,year] = 100
  end
  WriteDisk(db,"MEInput/RePL",RePL)

  poll = Select(Poll,"N2O")
  for year in Years, area in areas
    RePOCF[offset,poll,area,year] = 1.0
  end
  WriteDisk(db,"MEInput/RePOCF",RePOCF)

  RePollutant[offset] = "N2O"
  WriteDisk(db,"MEInput/RePollutant",RePollutant)

  for year in Years, area in areas
    RePriceSwitch[offset,area,year] = 1
  end
  for year in Years
    RePriceSwitch[offset,AB,year] = 2
  end
  WriteDisk(db,"MEInput/RePriceSwitch",RePriceSwitch)

  for year in Years, area in areas
    RePriceX[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/RePriceX",RePriceX)
  
  #
  # NERA offsets are calculated endogenously, except for Alberta.
  #
  for year in Years, area in areas
    ReReductionsSwitch[offset,area,year] = 1
  end
  area = Select(Area,"AB")
  for year in Years
    ReReductionsSwitch[offset,area,year] = 0
  end
  areas = findall(ANMap[:,CN] .== 1.0)
  WriteDisk(db,"MEInput/ReReductionsSwitch",ReReductionsSwitch)
  
  #
  # Alberta crop production reductions are exogenous and obtained from running the offsets 
  # endogenously and recycling the values from the reference case 12/09/16 R.Levesque
  #
  for year in Years, area in areas
    ReReductionsX[offset,area,year] = 0.0
  end  
  area = Select(Area,"AB")  
  years = collect(Yr(2015):Yr(2050))
  #                                   2015  2016   2017   2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  ReReductionsX[offset,area,years] = [0.00  94.39 156.37 1732.05 4198.43 5636.99 6291.68 6538.30 6600.27 6584.78 6538.45 6480.47 6418.43 6355.27 6292.09 6229.30 6167.06 6105.40 6044.36 5983.92 5924.08 5864.84 5806.19 5748.13 5690.64 5633.74 5577.40 5521.63 5466.41 5411.75 5357.63 5304.05 5251.01 5286.24 5387.61 5521.34]
  areas = findall(ANMap[:,CN] .== 1.0)  
  WriteDisk(db,"MEInput/ReReductionsX",ReReductionsX)

  for year in Years, area in areas
    ReROIN[offset,area,year] = 0.15
  end
  WriteDisk(db,"MEInput/ReROIN",ReROIN)

  for year in Years, area in areas
    ReTL[offset,area,year] = RePL[offset,area,year]*0.80
  end
  WriteDisk(db,"MEInput/ReTL",ReTL)

  for year in Years, area in areas
    ReTxRt[offset,area,year] = 0.35
  end
  WriteDisk(db,"MEInput/ReTxRt",ReTxRt)

  ReType[offset] = "Process"
  WriteDisk(db,"MEInput/ReType",ReType)

end

function Control(db)
  @info "Offsets_NERAgriculture.jl - Control"
  OffsetData(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
