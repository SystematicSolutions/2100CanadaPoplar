#
# ElectricPlantCharacteristics_VB.jl - VBInput Electric Generation
# Jeff Amlin 5/21/2013
#
using EnergyModel

module ElectricPlantCharacteristics_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))  
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (Years)
  CgFlFrNew::VariableArray{4} = ReadDisk(db,"EGInput/CgFlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  CgORNew::VariableArray{5} = ReadDisk(db,"EGInput/CgORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  DesHr::VariableArray{4} = ReadDisk(db,"EGInput/DesHr") # [Plant,Power,Area,Year] Design Hours (Hours)
  EAF::VariableArray{4} = ReadDisk(db,"EGInput/EAF") # [Plant,Area,Month,Year] Energy Availability Factor (MWh/MWh)
  FlFrNew::VariableArray{4} = ReadDisk(db,"EGInput/FlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs (Real $/KW)
  HRtM::VariableArray{3} = ReadDisk(db,"EGInput/HRtM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  ORNew::VariableArray{5} = ReadDisk(db,"EGInput/ORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  UFOMC::VariableArray{3} = ReadDisk(db,"EGInput/UFOMC") # [Plant,Area,Year] Unit Fixed O&M Costs (Real $/KW)
  UOMC::VariableArray{3} = ReadDisk(db,"EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs (Real $/MWh)
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vCD::VariableArray{2} = ReadDisk(db,"VBInput/vCD") # [Plant,Year] Construction Delay (Years)
  vCgFlFrNew::VariableArray{4} = ReadDisk(db,"VBInput/vCgFlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  vCgORNew::VariableArray{3} = ReadDisk(db,"VBInput/vCgORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  vDesHr::VariableArray{4} = ReadDisk(db,"VBInput/vDesHr") # [Plant,Power,Area,Year] Design Hours (Hours)
  vEAF::VariableArray{4} = ReadDisk(db,"VBInput/vEAF") # [Plant,Area,Month,Year] Energy Availability Factor (MWh/MWh)
  vFlFrNew::VariableArray{4} = ReadDisk(db,"VBInput/vFlFrNew") # [FuelEP,Plant,Area,Year] Fuel Fraction for New Plants
  vGCCCN::VariableArray{3} = ReadDisk(db,"VBInput/vGCCCN") # [Plant,vArea,Year] Overnight Construction Costs (Real $/Kw)
  vGCPot::VariableArray{4} = ReadDisk(db,"VBInput/vGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
  vHRTM::VariableArray{3} = ReadDisk(db,"VBInput/vHRTM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  vORNew::VariableArray{3} = ReadDisk(db,"VBInput/vORNew") # [Plant,Area,TimeP,Month,Year] Outage Rate for New Plants (MW/MW)
  vUFOMC::VariableArray{3} = ReadDisk(db,"VBInput/vUFOMC") # [Plant,vArea,Year] Unit Fixed O&M Costs (Real $/Kw)
  vUOMC::VariableArray{3} = ReadDisk(db,"VBInput/vUOMC") # [Plant,vArea,Year] Variable O&M Costs (Real $/MWh)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xGCPot::VariableArray{4} = ReadDisk(db,"EGInput/xGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

end

function PlantCharacteristics(db)
  data = EControl(; db)
  (;Area,Areas,FuelEPs,Months,Nation,Nodes,Plants,Powers,TimePs) = data
  (;Years,vArea) = data
  (;ANMap,CD,CgFlFrNew,CgORNew,DesHr,EAF,FlFrNew,GCCCN,HRtM,ORNew,UFOMC,UOMC) = data
  (;vCD,vCgFlFrNew,vCgORNew,vDesHr,vEAF,vFlFrNew,vGCCCN,vGCPot,vHRTM,vORNew,vUFOMC,vUOMC) = data
  (;xExchangeRate,xGCPot,xInflation) = data

  #
  # Electric Utility Plant Characteristics
  #
  for year in Years, plant in Plants
    CD[plant,year] = vCD[plant,year]
  end
  WriteDisk(db,"EGInput/CD",CD)

  for year in Years, area in Areas, plant in Plants, power in Powers
    DesHr[plant,power,area,year] = vDesHr[plant,power,area,year]
  end
  WriteDisk(db,"EGInput/DesHr",DesHr)
  
  for year in Years, area in Areas, plant in Plants, month in Months
    EAF[plant,area,month,year] = vEAF[plant,area,month,year]
  end
  WriteDisk(db,"EGInput/EAF",EAF)

  for year in Years, area in Areas, plant in Plants, node in Nodes
    xGCPot[plant,node,area,year] = vGCPot[plant,node,area,year]
  end
  WriteDisk(db,"EGInput/xGCPot",xGCPot)

  for year in Years, area in Areas, plant in Plants
    HRtM[plant,area,year] = vHRTM[plant,area,year]
  end
  WriteDisk(db,"EGInput/HRtM",HRtM)

  for year in Years, area in Areas, plant in Plants, timep in TimePs, month in Months
    ORNew[plant,area,timep,month,year] = vORNew[plant,area,year]
    CgORNew[plant,area,timep,month,year] = vCgORNew[plant,area,year]
  end
  WriteDisk(db,"EGInput/ORNew",ORNew)
  WriteDisk(db,"EGInput/CgORNew",CgORNew)

  for year in Years, area in Areas, plant in Plants, fuelep in FuelEPs
    FlFrNew[fuelep,plant,area,year] = vFlFrNew[fuelep,plant,area,year]
    CgFlFrNew[fuelep,plant,area,year] = vCgFlFrNew[fuelep,plant,area,year]
  end
  WriteDisk(db,"EGInput/FlFrNew",FlFrNew)
  WriteDisk(db,"EGInput/CgFlFrNew",CgFlFrNew)
  
  #
  # Defined by vArea
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  for year in Years, area in areas, plant in Plants
    varea = Select(vArea,Area[area])
    GCCCN[plant,area,year] = vGCCCN[plant,varea,year]
    UFOMC[plant,area,year] = vUFOMC[plant,varea,year] 
    UOMC[plant,area,year] = vUOMC[plant,varea,year] 
  end
  
  #
  # Other Areas, not xGCPot, use Ontario
  #
  ON = Select(Area,"ON")
  areas = Select(Area,(from = "CA", to = "ROW"))

  for plant in Plants, area in areas, year in Years
    GCCCN[plant,area,year] = GCCCN[plant,ON,year]*xInflation[ON,year]/xExchangeRate[ON,year]*
                                                  xExchangeRate[area,year]/xInflation[area,year]
    UFOMC[plant,area,year] = UFOMC[plant,ON,year]*xInflation[ON,year]/xExchangeRate[ON,year]*
                                                  xExchangeRate[area,year]/xInflation[area,year]
    UOMC[plant,area,year] = UOMC[plant,ON,year] * xInflation[ON,year]/xExchangeRate[ON,year]*
                                                  xExchangeRate[area,year]/xInflation[area,year]
  end

  WriteDisk(db,"EGInput/GCCCN",GCCCN)
  WriteDisk(db,"EGInput/UFOMC",UFOMC)
  WriteDisk(db,"EGInput/UOMC",UOMC) 

end

function Control(db)
  @info "ElectricPlantCharacteristics_VB.jl - Control"
  PlantCharacteristics(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
