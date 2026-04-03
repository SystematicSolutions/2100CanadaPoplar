#
# OGExchangeAndInflation.jl - Sets parameters for rates of Oil and Gas Calibration
#              
using EnergyModel

module OGExchangeAndInflation

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodes::Vector{Int} = collect(Select(GNode))
  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGCode")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ExchangeRateGNode::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateGNode") # [GNode,Year] Local Currency/US$ Exchange Rate (Local$/US$)
  ExchangeRateOGUnit::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateOGUnit") #[OGUnit,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  GNodeAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeAreaMap") # [GNode,Area] Natural Gas Node to Area Map
  InflationGNode::VariableArray{2} = ReadDisk(db,"MOutput/InflationGNode") # [GNode,Year] Inflation Index ($/$)
  InflationOGUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationOGUnit") #[OGUnit,Year]  Inflation Index ($/$)
  OGArea::Vector{String} = ReadDisk(db, "SpInput/OGArea") #[OGUnit]  OG Unit Area
  xExchangeRate::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRate") # [Area,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xExchangeRateGNode::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateGNode") # [GNode,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xExchangeRateOGUnit::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateOGUnit") # [OGUnit,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db, "MInput/xInflation") # [Area,Year] Inflation Index
  xInflationGNode::VariableArray{2} = ReadDisk(db, "MInput/xInflationGNode") # [GNode,Year] Inflation Index
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") #[Nation,Year]  Inflation Index ($/$)
  xInflationOGUnit::VariableArray{2} = ReadDisk(db,"MInput/xInflationOGUnit") # [OGUnit,Year] Inflation Index ($/$)
  
end

function SupplyCalibration(db)
  data = SControl(; db)
  (;Area,Areas,GNodes,Years) = data
  (;ExchangeRateGNode,ExchangeRateOGUnit,GNodeAreaMap,InflationGNode,InflationOGUnit) = data
  (;OGArea,xExchangeRate,xExchangeRateGNode,xExchangeRateOGUnit,xInflation,xInflationGNode) = data
  (;xInflationOGUnit) = data
  
  for area in Areas 
    ogunits  = findall(OGArea .== Area[area])
    #if ogunits != []
      for ogunit in ogunits, year in Years 
        xExchangeRateOGUnit[ogunit,year] = xExchangeRate[area,year]
        xInflationOGUnit[ogunit,year] = xInflation[area,year]
      end
    #end
  end

  @. ExchangeRateOGUnit = xExchangeRateOGUnit
  @. InflationOGUnit = xInflationOGUnit

  WriteDisk(db,"MOutput/ExchangeRateOGUnit",ExchangeRateOGUnit)
  WriteDisk(db,"MOutput/InflationOGUnit",InflationOGUnit)
  WriteDisk(db,"MInput/xExchangeRateOGUnit",xExchangeRateOGUnit)
  WriteDisk(db,"MInput/xInflationOGUnit",xInflationOGUnit)
  
  for gnode in GNodes
    areas = findall(GNodeAreaMap[gnode,:] .== 1.0)
    if areas != []
      for year in Years
        xExchangeRateGNode[gnode,year] = maximum(xExchangeRate[areas,year])
        xInflationGNode[gnode,year] = maximum(xInflation[areas,year])
      end
    end
  end

  @. ExchangeRateGNode = xExchangeRateGNode
  @. InflationGNode = xInflationGNode
 
  WriteDisk(db,"MOutput/ExchangeRateGNode",ExchangeRateGNode)
  WriteDisk(db,"MOutput/InflationGNode",InflationGNode)
  WriteDisk(db,"MInput/xExchangeRateGNode",xExchangeRateGNode)
  WriteDisk(db,"MInput/xInflationGNode",xInflationGNode)

end

function Control(db)
  @info "OGExchangeAndInflation.jl - Control"

  SupplyCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
