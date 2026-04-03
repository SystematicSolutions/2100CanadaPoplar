#
# SpRef.jl - Petroleum Refining
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# � 2013 Systematic Solutions, Inc.  All rights reserved.
#
using EnergyModel

module SpRef

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SEngine
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  last = HisTime-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Crude::SetArray = ReadDisk(db,"MainDB/CrudeKey")
  CrudeDS::SetArray = ReadDisk(db,"MainDB/CrudeDS")
  Crudes::Vector{Int} = collect(Select(Crude))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodeDS::SetArray = ReadDisk(db,"MainDB/GNodeDS")
  GNodeX::SetArray = ReadDisk(db,"MainDB/GNodeXKey")
  GNodeXDS::SetArray = ReadDisk(db,"MainDB/GNodeXDS")
  GNodeXs::Vector{Int} = collect(Select(GNodeX))
  GNodes::Vector{Int} = collect(Select(GNode))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) # [Fuel,Nation,Year] Wholesale Prices ($/mmBtu)
  ExchangeRateGNode::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateGNode",year) # [GNode,Year] Local Currency/US$ Exchange Rate (Local/US$)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  GNodeAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeAreaMap") # [GNode,Area] Natural Gas Node to Area Map
  GNodeNationMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeNationMap") # [GNode,Nation] Natural Gas Node to Nation Map
  GNodeXAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeXAreaMap") # [GNodeX,Area] Natural Gas Node to Area Map
  GNodeXNationMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeXNationMap") # [GNodeX,Nation] Natural Gas Node to Nation Map
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) # [Area,Year] Inflation Index ($/$)
  InflationGNode::VariableArray{1} = ReadDisk(db,"MOutput/InflationGNode",year) # [GNode,Year] Inflation Index ($/$)
  InflationRfUnit::VariableArray{1} = ReadDisk(db,"MOutput/InflationRfUnit",year) # [RfUnit,Year] Inflation Index ($/$)
  RfArea::Array{String} = ReadDisk(db,"SpInput/RfArea") # [RfUnit] Refinery Area
  RfNode::Array{String} = ReadDisk(db,"SpInput/RfNode") # [RfUnit] Refinery GNode
  RfEmgPrice::VariableArray{2} = ReadDisk(db,"SpInput/RfEmgPrice",year) # [GNode,Fuel,Year] RPP Emergency Price (Real US$/mmBtu)
  RfEmgPriceUS::VariableArray{2} = ReadDisk(db,"SpOutput/RfEmgPriceUS",year) # [GNode,Fuel,Year] RPP Emergency Price (US$/mmBtu)
  RfCap::VariableArray{1} = ReadDisk(db,"SpOutput/RfCap",year) # [RfUnit,Year] Refining Unit Capacity (TBtu/Yr)
  RfCrude::VariableArray{2} = ReadDisk(db,"SpOutput/RfCrude",year) # [RfUnit,Crude,Year] Refining Unit Crude Oil Refined (TBtu/Yr)
  RfCrudeLimit::VariableArray{2} = ReadDisk(db,"SpOutput/RfCrudeLimit",year) # [RfUnit,Crude,Year] Refinery Maximum Input of Crude Types (TBtu/Yr)
  ExchangeRateRfUnit::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateRfUnit",year) # [RfUnit,Year] Refinery Exchange Rate($/$)
  RfFP::VariableArray{2} = ReadDisk(db,"SpOutput/RfFP",year) # [RfUnit,Fuel,Year] RPP Fuel Prices ($/mmBtu)
  RfFPCrude::VariableArray{2} = ReadDisk(db,"SpOutput/RfFPCrude",year) # [RfUnit,Crude,Year] Crude Oil Prices ($/mmBtu)
  RfFPCrudeDChg::VariableArray{2} = ReadDisk(db,"SpInput/RfFPCrudeDChg",year) # [RfUnit,Crude,Year] Crude Oil Delivery Charge ($/mmBtu)
  RfFPCrudeUS::VariableArray{2} = ReadDisk(db,"SpOutput/RfFPCrudeUS",year) # [RfUnit,Crude,Year] Crude Oil Prices (US$/mmBtu)
  RfFPUS::VariableArray{2} = ReadDisk(db,"SpOutput/RfFPUS",year) # [RfUnit,Fuel,Year] RPP Fuel Prices (US$/mmBtu)
  RfCapEffective::VariableArray{2} = ReadDisk(db,"SpOutput/RfCapEffective",year) # [RfUnit,Fuel,Year] Maximum Refining Unit Capacity for each RPP (TBtu/Yr)
  RfMaxCrude::VariableArray{2} = ReadDisk(db,"SpInput/RfMaxCrude",year) # [RfUnit,Crude,Year] Refinery Maximum Input of Crude Types (Btu/Btu)
  RfMaxYield::VariableArray{3} = ReadDisk(db,"SpInput/RfMaxYield",year) # [RfUnit,Fuel,Crude,Year] RPP Maximum Yield (Btu/Btu)
  RfMinYield::VariableArray{3} = ReadDisk(db,"SpInput/RfMinYield",year) # [RfUnit,Fuel,Crude,Year] RPP Minimum Yield (Btu/Btu)
  RfNation::Array{String} = ReadDisk(db,"SpInput/RfNation") # [RfUnit] Refinery Nation
  RfOOR::VariableArray{2} = ReadDisk(db,"SCalDB/RfOOR",year) # [RfUnit,Fuel,Year] Refining Unit Operational Outage Rate (Btu/Btu)
  RfPathEff::VariableArray{2} = ReadDisk(db,"SpInput/RfPathEff",year) # [GNode,GNodeX,Year] RPP Transmission Efficiency (Btu/Btu)
  RfPathVC::VariableArray{2} = ReadDisk(db,"SpInput/RfPathVC",year) # [GNode,GNodeX,Year] Variable Cost of Transporting RPP along path (US$/mmBtu)
  RfPathVCUS::VariableArray{2} = ReadDisk(db,"SpOutput/RfPathVCUS",year) # [GNode,GNodeX,Year] Variable Cost of Transporting RPP along path (US$/mmBtu)
  RfProd::VariableArray{2} = ReadDisk(db,"SpOutput/RfProd",year) # [RfUnit,Fuel,Year] Refining Unit Production (TBtu/Yr)
  RfTrMax::VariableArray{2} = ReadDisk(db,"SpInput/RfTrMax",year) # [GNode,GNodeX,Year] RPP Transmission Capacity (TBtu/Year) 
  RfVCProd::VariableArray{3} = ReadDisk(db,"SpInput/RfVCProd",year) # [RfUnit,Fuel,Crude,Year] Variable Cost of Producing a Barrel of Crude ($/mmBtu)
  RfVCProdUS::VariableArray{3} = ReadDisk(db,"SpOutput/RfVCProdUS",year) # [RfUnit,Fuel,Crude,Year] Variable Cost of Producing a Barrel of Crude (US$/mmBtu)
  RPPAreaPurchases::VariableArray{2} = ReadDisk(db,"SpOutput/RPPAreaPurchases",year) # [Fuel,Area,Year] RPP Purchases from Areas in the same Country (TBtu/Yr)
  RPPAreaSales::VariableArray{2} = ReadDisk(db,"SpOutput/RPPAreaSales",year) # [Fuel,Area,Year] RPP Sales to Areas in the same Country (TBtu/Yr)
  RPPCrude::VariableArray{2} = ReadDisk(db,"SpOutput/RPPCrude",year) # [Crude,Area,Year] Crude Oil Processed (TBtu/Yr)
  RPPCrudeAdjust::VariableArray{2} = ReadDisk(db,"SCalDB/RPPCrudeAdjust",year) # [Crude,Area,Year] Crude Oil Processed Adjustment (TBtu/Yr)
  RPPCrudeNation::VariableArray{2} = ReadDisk(db,"SpOutput/RPPCrudeNation",year) # [Crude,Nation,Year] Crude Oil Processed (TBtu/Yr)
  RPPDemandA::VariableArray{2} = ReadDisk(db,"SpOutput/RPPDemandA",year) # [Fuel,Area,Year] Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  RPPDemandN::VariableArray{2} = ReadDisk(db,"SpOutput/RPPDemandN",year) # [Fuel,Nation,Year] Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  RPPDem::VariableArray{2} = ReadDisk(db,"SpOutput/RPPDem",year) # [GNode,Fuel,Year] Nodal Demand for RPP (TBtu/Yr)
  RPPEmgSupply::VariableArray{2} = ReadDisk(db,"SpOutput/RPPEmgSupply",year) # [GNode,Fuel,Year] RPP Emergency Supply (TBtu/Yr)
  RPPExportsArea::VariableArray{2} = ReadDisk(db,"SpOutput/RPPExportsArea",year) # [Fuel,Area,Year] RPP Sales to Areas in a different Country (TBtu/Yr)
  RPPFlows::VariableArray{3} = ReadDisk(db,"SpOutput/RPPFlows",year) # [GNode,GNodeX,Fuel,Year] Refined Petroleum Products Flows (TBtu/Yr)
  RPPImportsArea::VariableArray{2} = ReadDisk(db,"SpOutput/RPPImportsArea",year) # [Fuel,Area,Year] RPP Imports by Areas (TBtu/Yr)
  RPPNodePrice::VariableArray{2} = ReadDisk(db,"SpOutput/RPPNodePrice",year) # [GNode,Fuel,Year] RPP Node Price ($/mmBtu)
  RPPNodePriceUS::VariableArray{2} = ReadDisk(db,"SpOutput/RPPNodePriceUS",year) # [GNode,Fuel,Year] RPP Node Price (US$/mmBtu)
  RPPProdArea::VariableArray{2} = ReadDisk(db,"SpOutput/RPPProdArea",year) # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPProdAdjust::VariableArray{2} = ReadDisk(db,"SCalDB/RPPProdAdjust",year) # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPProdNation::VariableArray{2} = ReadDisk(db,"SpOutput/RPPProdNation",year) # [Fuel,Nation,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  xRfCap::VariableArray{1} = ReadDisk(db,"SpInput/xRfCap",year) # [RfUnit,Year] Refining Unit Capacity (TBtu/Yr)
  xRPPAdjustArea::VariableArray{2} = ReadDisk(db,"SpInput/xRPPAdjustArea",year) # [Fuel,Area,Year] Refined Petroleum Products (RPP) Supply Adjustments (TBtu/Yr)
  xRPPExportsROW::VariableArray{2} = ReadDisk(db,"SpInput/xRPPExportsROW",year) # [Fuel,Area,Year] RPP Exports to ROW (TBtu/Yr)
  xRPPImportsROW::VariableArray{2} = ReadDisk(db,"SpInput/xRPPImportsROW",year) # [Fuel,Area,Year] RPP Imports from (TBtu/Yr)

  # Scratch Variables
  GNodeActive::VariableArray{1} = zeros(Float32,length(GNode)) # [GNode] Is GNode Active (0=No)
end

include("SpRefLP.jl")

function Capacity(data)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # @info " SpRef.src, Petroleum Refining Capacity"
  #
  @. RfCap=xRfCap
  WriteDisk(db, "SpOutput/RfCap", year, RfCap)

  for fuel in Fuels, rfunit in RfUnits
    RfCapEffective[rfunit,fuel]=RfCap[rfunit]*(1-RfOOR[rfunit,fuel])
  end
  WriteDisk(db, "SpOutput/RfCapEffective", year, RfCapEffective)
  
end

function Demand(data)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  # Define Procedure Demand
  # 
  # @info "Refined Petroleum Demand in SpRef.src"
  # 
  fuels=Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
    "Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy",
    "PetroFeed","PetroCoke","StillGas"])

  for fuel in fuels, area in Areas
    RPPDemandA[fuel,area]=sum(TotDemand[fuel,ecc,area] for ecc in ECCs)
  end  
  for fuel in fuels, nation in Nations
    areas=findall(ANMap[:,nation] .== 1)
    RPPDemandN[fuel,nation]=sum(RPPDemandA[fuel,area] for area in areas)
  end

  #
  # Demand for Dispatch (remove ROW Imports, add ROW Exports)
  #
  for fuel in fuels, gnode in GNodes
    RPPDem[gnode,fuel]=sum((sum(TotDemand[fuel,ecc,area] for ecc in ECCs)+
      xRPPExportsROW[fuel,area]-xRPPImportsROW[fuel,area]-
      xRPPAdjustArea[fuel,area])*GNodeAreaMap[gnode,area] for area in Areas)
  end

  WriteDisk(db, "SpOutput/RPPDemandA", year, RPPDemandA)
  WriteDisk(db, "SpOutput/RPPDem", year, RPPDem)
  WriteDisk(db, "SpOutput/RPPDemandN", year, RPPDemandN)

end

function CostsAndPrices(data)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  #  @info " SpRef.src, Petroleum Refining Prices"
  #
  # RPP Prices
  #
  for rfunit in RfUnits
    es=Select(ES,"Industrial")
    area=Select(Area,RfArea[rfunit])
    if RfArea[rfunit]==Area[area]
      for fuel in Fuels
        RfFP[rfunit,fuel]=FPF[fuel,es,area]
      end
    end
    #
    # Crude Oil Prices
    #
    nation=Select(Nation,RfNation[rfunit])
    if RfNation[rfunit]==Nation[nation]
      for crude in Crudes
        LightCrudeOil=Select(Fuel,"LightCrudeOil")
        RfFPCrude[rfunit,crude]=(ENPN[LightCrudeOil,nation]+RfFPCrudeDChg[rfunit,crude])*InflationRfUnit[rfunit]
      end
    end
  end
      
  for fuel in Fuels, rfunit in RfUnits
    RfFPUS[rfunit,fuel]=RfFP[rfunit,fuel]/ExchangeRateRfUnit[rfunit]
  end

  for crude in Crudes, rfunit in RfUnits
    RfFPCrudeUS[rfunit,crude]=RfFPCrude[rfunit,crude]/ExchangeRateRfUnit[rfunit]
  end

  for crude in Crudes, fuel in Fuels, rfunit in RfUnits
    RfVCProdUS[rfunit,fuel,crude]=RfVCProd[rfunit,fuel,crude]*InflationRfUnit[rfunit]/ExchangeRateRfUnit[rfunit]
  end

  for fuel in Fuels, gnode in GNodes
    RfEmgPriceUS[gnode,fuel]=RfEmgPrice[gnode,fuel]*InflationGNode[gnode]
  end

  @. RfPathVCUS=RfPathVC
  
  WriteDisk(db, "SpOutput/RfEmgPriceUS", year, RfEmgPriceUS)
  WriteDisk(db, "SpOutput/RfFPCrude", year, RfFPCrude)
  WriteDisk(db, "SpOutput/RfFPCrudeUS", year, RfFPCrudeUS)
  WriteDisk(db, "SpOutput/RfFP", year, RfFP)
  WriteDisk(db, "SpOutput/RfFPUS", year, RfFPUS)
  WriteDisk(db, "SpOutput/RfPathVCUS", year, RfPathVCUS)
  WriteDisk(db, "SpOutput/RfVCProdUS", year, RfVCProdUS)

end

function Refine(data)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # @info " SpRef.src - Refine, Petroleum Refining Dispatch"
  #
  fuels=Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
    "Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy",
    "PetroFeed","PetroCoke","StillGas"])

  for gnode in GNodes
    GNodeActive[gnode]=sum(GNodeAreaMap[gnode,area] for area in Areas)
  end

  gnodes=findall(GNodeActive[:] .> 0)

  if GNodeActive[gnode] > 0
    RPPProductionLP(data)
  end

  for fuel in Fuels, gnode in GNodes
    RPPNodePrice[gnode,fuel]=RPPNodePriceUS[gnode,fuel]*ExchangeRateGNode[gnode]
  end
  WriteDisk(db, "SpOutput/RPPNodePrice", year, RPPNodePrice)

end

function Production(data)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # @info " SpRef.src - Production"
  #
  for area in Areas
    rfunits=findall(RfArea[:] .== Area[area])
    if !isempty(rfunits)
      for fuel in Fuels
        RPPProdArea[fuel,area]=sum(RfProd[rfunit,fuel] for rfunit in rfunits)
      end
    end
  end

  @. RPPProdArea=RPPProdArea+RPPProdAdjust

  for nation in Nations, fuel in Fuels
    areas=findall(ANMap[:,nation] .== 1)
    RPPProdNation[fuel,nation]=sum(RPPProdArea[fuel,area] for area in areas)
  end
 
  WriteDisk(db, "SpOutput/RPPProdArea", year, RPPProdArea)
  WriteDisk(db, "SpOutput/RPPProdNation", year, RPPProdNation)

end

function CrudeOilProcessed(data)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # @info " SpRef.src - CrudeOilProcessed"
  #
  for area in Areas
    rfunits=findall(RfArea[:] .== Area[area])
    if !isempty(rfunits)
      for crude in Crudes
        RPPCrude[crude,area]=sum(RfCrude[rfunit,crude] for rfunit in rfunits)
      end
    end
  end

  @. RPPCrude=RPPCrude+RPPCrudeAdjust

  for nation in Nations, crude in Crudes
    areas=findall(ANMap[:,nation] .== 1)
    RPPCrudeNation[crude,nation]=sum(RPPCrude[crude,area] for area in areas)
  end
 
  WriteDisk(db, "SpOutput/RPPCrude", year, RPPCrude)
  WriteDisk(db, "SpOutput/RPPCrudeNation", year, RPPCrudeNation)

end

function IntraCountrySales(data,nation,area)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # Sales from this Area to other Areas in the same country
  #
  gnodexs = findall(GNodeXAreaMap[:,area] .== 1)
  gnodes = findall(GNodeNationMap[:,nation] .== 1)
  if !isempty(gnodexs) && !isempty(gnodes)
    for fuel in Fuels
      RPPAreaSales[fuel,area]=sum(RPPFlows[gnode,gnodex,fuel] for gnodex in gnodexs, gnode in gnodes)
    end
  end

  #
  # Remove sales between two GNodes in the same Area
  #
  gnodexs = findall(GNodeXAreaMap[:,area] .== 1)
  gnodes = findall(GNodeAreaMap[:,area] .== 1)
  if !isempty(gnodexs) && !isempty(gnodes)
    for fuel in Fuels
      RPPAreaSales[fuel,area]=RPPAreaSales[fuel,area]-sum(RPPFlows[gnode,gnodex,fuel] for gnodex in gnodexs, gnode in gnodes)
    end
  end

  # Moved out of loop
  # WriteDisk(db, "SpOutput/RPPAreaSales", year, RPPAreaSales)

end

function InterCountrySales(data,nation,area)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # Sales from this Area to other Areas in a different county
  #
  gnodexs = findall(GNodeXAreaMap[:,area] .== 1)
  gnodes = findall(GNodeNationMap[:,nation] .== 0)
  if !isempty(gnodexs) && !isempty(gnodes)
    for fuel in Fuels
      RPPExportsArea[fuel,area]=sum(RPPFlows[gnode,gnodex,fuel] for gnodex in gnodexs, gnode in gnodes)
    end
  end

  #
  # Add in ROW Exports
  #
  @. RPPExportsArea=RPPExportsArea+xRPPExportsROW

  # Moved out of loop
  # WriteDisk(db, "SpOutput/RPPExportsArea", year, RPPExportsArea)

end

function IntraCountryPurchases(data,nation,area)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data
  
  #
  # Purchases by this Area from other Areas in the same country
  #
  gnodexs = findall(GNodeXNationMap[:,nation] .== 1)
  gnodes = findall(GNodeAreaMap[:,area] .== 1)
  if !isempty(gnodexs) && !isempty(gnodes)
    for fuel in Fuels
      RPPAreaPurchases[fuel,area]=sum(RPPFlows[gnode,gnodex,fuel]*RfPathEff[gnode,gnodex] for gnodex in gnodexs, gnode in gnodes)
    end
  end

  #
  # Remove purchases between two GNodes in the same Area
  #
  gnodes = findall(GNodeAreaMap[:,area] .== 1)
  gnodexs = findall(GNodeXAreaMap[:,area] .== 1)
  if !isempty(gnodexs) && !isempty(gnodes)
    for fuel in Fuels
      RPPAreaPurchases[fuel,area]=RPPAreaPurchases[fuel,area]-sum(RPPFlows[gnode,gnodex,fuel]*RfPathEff[gnode,gnodex] for gnodex in gnodexs, gnode in gnodes)
    end
  end

  # Moved out of loop
  # WriteDisk(db, "SpOutput/RPPAreaPurchases", year, RPPAreaPurchases)

end

function InterCountryPurchases(data,nation,area)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data
  
  #
  # Purchases by this Area from other Areas in a different country
  #
  gnodes = findall(GNodeAreaMap[:,area] .== 1)
  gnodexs = findall(GNodeXNationMap[:,nation] .== 0)
  if !isempty(gnodexs) && !isempty(gnodes)
    for fuel in Fuels
      RPPImportsArea[fuel,area]=sum(RPPFlows[gnode,gnodex,fuel]*RfPathEff[gnode,gnodex] for gnodex in gnodexs, gnode in gnodes)
    end
  end

  #
  # Add in ROW Imports
  #
  @. RPPImportsArea=RPPImportsArea+xRPPImportsROW

  # Moved out of loop
  # WriteDisk(db, "SpOutput/RPPImportsArea", year, RPPImportsArea)

end

function Flows(data)
  (; db,year) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # @info " SpRef.src,  Flows"
  #
  # Transmission Flows between Areas and Nations (Imports and Exports)
  #
  for nation in Nations
    areas=findall(ANMap[:,nation] .== 1)
    if !isempty(areas)
      for area in areas
        IntraCountrySales(data,nation,area)
        InterCountrySales(data,nation,area)
        IntraCountryPurchases(data,nation,area)
        InterCountryPurchases(data,nation,area)
      end
    end
  end

  #
  # Note: Write Disk statements moved out of loop
  #
  WriteDisk(db, "SpOutput/RPPAreaSales", year, RPPAreaSales)
  WriteDisk(db, "SpOutput/RPPExportsArea", year, RPPExportsArea)
  WriteDisk(db, "SpOutput/RPPAreaPurchases", year, RPPAreaPurchases)
  WriteDisk(db, "SpOutput/RPPImportsArea", year, RPPImportsArea)

end

function Control(data)
  (; db,year) = data
  (;Area,AreaDS,Areas,Crude,CrudeDS,Crudes,ECC,ECCDS,ECCs,ES) = data
  (;ESDS,ESs,Fuel,FuelDS,Fuels,GNode,GNodeDS,GNodeX,GNodeXDS,GNodeXs) = data
  (;GNodes,Nation,NationDS,Nations,RfUnit,RfUnits,Year,YearDS,Years) = data
  (;ANMap,ENPN,ExchangeRateGNode,FPF,GNodeAreaMap,GNodeNationMap,GNodeXAreaMap,GNodeXNationMap,Inflation,InflationGNode) = data
  (;InflationRfUnit,RfArea,RfNode,RfEmgPrice,RfEmgPriceUS,RfCap,RfCrude,RfCrudeLimit,ExchangeRateRfUnit,RfFP) = data
  (;RfFPCrude,RfFPCrudeDChg,RfFPCrudeUS,RfFPUS,RfCapEffective,RfMaxCrude,RfMaxYield,RfMinYield,RfNation,RfOOR) = data
  (;RfPathEff,RfPathVC,RfPathVCUS,RfProd,RfTrMax,RfVCProd,RfVCProdUS,RPPAreaPurchases,RPPAreaSales,RPPCrude) = data
  (;RPPCrudeAdjust,RPPCrudeNation,RPPDemandA,RPPDemandN,RPPDem,RPPEmgSupply,RPPExportsArea,RPPFlows,RPPImportsArea,RPPNodePrice) = data
  (;RPPNodePriceUS,RPPProdArea,RPPProdAdjust,RPPProdNation,TotDemand,xRfCap,xRPPAdjustArea,xRPPExportsROW,xRPPImportsROW) = data
  (;GNodeActive) = data

  #
  # @info " SpRef.src - Control, Petroleum Refining Control"
  #
  Capacity(data)
  Demand(data)
  CostsAndPrices(data)
  Refine(data)
  Production(data)
  CrudeOilProcessed(data)
  Flows(data)
  
end

end

