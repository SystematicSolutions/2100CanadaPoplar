#
# RefiningDefinitions_VB.jl - Data Values for Refining Sector
#
using EnergyModel

module RefiningDefinitions_VB

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

  Crude::SetArray = ReadDisk(db,"MainDB/CrudeKey")
  CrudeDS::SetArray = ReadDisk(db,"MainDB/CrudeDS")
  Crudes::Vector{Int} = collect(Select(Crude))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodeDS::SetArray = ReadDisk(db,"MainDB/GNodeDS")
  GNodeX::SetArray = ReadDisk(db,"MainDB/GNodeXKey")
  GNodeXDS::SetArray = ReadDisk(db,"MainDB/GNodeXDS")
  GNodeXs::Vector{Int} = collect(Select(GNodeX))
  GNodes::Vector{Int} = collect(Select(GNode))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  RfEmgPrice::VariableArray{3} = ReadDisk(db,"SpInput/RfEmgPrice") # [GNode,Fuel,Year] RPP Emergency Price ($/mmBtu)
  RfMaxCrude::VariableArray{3} = ReadDisk(db,"SpInput/RfMaxCrude") # [RfUnit,Crude,Year] Refinery Maximum Input Fraction of Crude Types (Btu/Btu)
  RfMaxYield::VariableArray{4} = ReadDisk(db,"SpInput/RfMaxYield") # [RfUnit,Fuel,Crude,Year] Maximum Yield (Btu/Btu)
  RfMinYield::VariableArray{4} = ReadDisk(db,"SpInput/RfMinYield") # [RfUnit,Fuel,Crude,Year] Minimum Yield (Btu/Btu)
  RfPathEff::VariableArray{3} = ReadDisk(db,"SpInput/RfPathEff") # [GNode,GNodeX,Year] RPP Transmission Efficiency (Btu/Btu)
  RfPathVC::VariableArray{3} = ReadDisk(db,"SpInput/RfPathVC") # [GNode,GNodeX,Year] Variable Cost of Transporting RPP along path (US$/mmBtu??)
  RfTrMax::VariableArray{3} = ReadDisk(db,"SpInput/RfTrMax") # [GNode,GNodeX,Year] RPP Transmission Capacity (TBtu/Year) 
  RfVCProd::VariableArray{4} = ReadDisk(db,"SpInput/RfVCProd") # [RfUnit,Fuel,Crude,Year] Variable Cost of Producing a Barrel of Crude (Real $/mmBtu)
  vRfEmgPrice::VariableArray{3} = ReadDisk(db,"VBInput/vRfEmgPrice") # [GNode,Fuel,Year] RPP Emergency Price ($/mmBtu)
  vRfMaxCrude::VariableArray{3} = ReadDisk(db,"VBInput/vRfMaxCrude") # [RfUnit,Crude,Year] Refinery Maximum Input of Crude Types (Btu/Btu)
  vRfMaxYield::VariableArray{4} = ReadDisk(db,"VBInput/vRfMaxYield") # [RfUnit,Fuel,Crude,Year] RPP Maximum Yield (Btu/Btu)
  vRfMinYield::VariableArray{4} = ReadDisk(db,"VBInput/vRfMinYield") # [RfUnit,Fuel,Crude,Year] RPP Minimum Yield (Btu/Btu)
  vRfPathEff::VariableArray{3} = ReadDisk(db,"VBInput/vRfPathEff") # [GNode,GNodeX,Year] RPP Transmission Efficiency (Btu/Btu)
  vRfPathVC::VariableArray{3} = ReadDisk(db,"VBInput/vRfPathVC") # [GNode,GNodeX,Year] Variable Cost of Transporting RPP along path (US$/mmBtu??)
  vRfTrMax::VariableArray{3} = ReadDisk(db,"VBInput/vRfTrMax") # [GNode,GNodeX,Year] RPP Transmission Capacity (TBtu/Year) 
  vRfVCProd::VariableArray{4} = ReadDisk(db,"VBInput/vRfVCProd") # [RfUnit,Fuel,Crude,Year] Variable Cost of Producing Crude ($/mmBtu)

end

function SCalibration(db)
   data = SControl(; db)
  (;Crude,CrudeDS,Crudes,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS) = data
  (;GNodeXs,GNodes,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;RfEmgPrice,vRfEmgPrice,RfVCProd,vRfVCProd) = data
  (;RfPathEff,vRfPathEff,RfPathVC,RfTrMax,vRfPathVC,vRfTrMax,RfMaxYield,RfMinYield,vRfMaxYield,vRfMinYield) = data
  (;RfMaxCrude,vRfMaxCrude) = data
  

  RfEmgPrice = vRfEmgPrice
  WriteDisk(db,"SpInput/RfEmgPrice",RfEmgPrice)

  RfVCProd = vRfVCProd
  WriteDisk(db,"SpInput/RfVCProd",RfVCProd)

  RfPathEff = vRfPathEff
  WriteDisk(db,"SpInput/RfPathEff",RfPathEff)

  RfPathVC = vRfPathVC
  RfTrMax = vRfTrMax
  WriteDisk(db,"SpInput/RfPathVC",RfPathVC)
  WriteDisk(db,"SpInput/RfTrMax",RfTrMax)

  RfMaxYield = vRfMaxYield
  RfMinYield = vRfMinYield
  WriteDisk(db,"SpInput/RfMaxYield",RfMaxYield)
  WriteDisk(db,"SpInput/RfMinYield",RfMinYield)

  RfMaxCrude = vRfMaxCrude
  WriteDisk(db,"SpInput/RfMaxCrude",RfMaxCrude)

end

function Control(db)
  @info "RefiningDefinitions_VB.jl - Control"
  SCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
