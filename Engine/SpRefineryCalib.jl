#
# SpRefineryCalib.jl - Aggregate Refinery Calibration
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# copyright 2013 Systematic Solutions, Inc.  All rights reserved.
#

using EnergyModel

module SpRefineryCalib

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
import ...EnergyModel: Engine

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaKey::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel)) 
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationKey::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  PI::SetArray = ReadDisk(db,"SInput/PIKey")
  PIDS::SetArray = ReadDisk(db,"SInput/PIDS")
  PIs::Vector{Int} = collect(Select(PI))  
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfName::SetArray = ReadDisk(db,"MainDB/RfName")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  SegKey::SetArray = ReadDisk(db,"MainDB/SegKey")
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  #
  # Pointer "Keys" for PI
  #
  AccountsKey = Select(PI,"Accounts")
  LoadcurveKey = Select(PI,"Loadcurve")
  DailyUseKey = Select(PI,"DailyUse")
  PriceKey = Select(PI,"Price")     
  
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] NonExist = -1
  RPPAdjustments::VariableArray{2} = ReadDisk(db,"SpOutput/RPPAdjustments") # [Nation,Year]  RPP Supply Adjustments (TBtu/Yr)
  RPPDemand::VariableArray{2} = ReadDisk(db,"SpOutput/RPPDemand") # [Nation,Year]  Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  RPPEff::VariableArray{2} = ReadDisk(db,"SCalDB/RPPEff") # [Nation,Year] RPP Efficiency Factor (Btu/Btu)  
  SupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpOutput/SupplyAdjustments") # [FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)
  xProcSw::VariableArray{2} = ReadDisk(db,"SInput/xProcSw") # [PI,Year] Procedure on/off Switch
  xRPPAdjustments::VariableArray{2} = ReadDisk(db,"SpInput/xRPPAdjustments") # [Nation,Year]  RPP Supply Adjustments (TBtu/Yr)
  xRPPAProd::VariableArray{2} = ReadDisk(db,"SInput/xRPPAProd") # [Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xRPPExports::VariableArray{2} = ReadDisk(db,"SpInput/xRPPExports") # [Nation,Year]  Refined Petroleum Products (RPP) Exports (TBtu/Yr)
  xRPPImports::VariableArray{2} = ReadDisk(db,"SpInput/xRPPImports") # [Nation,Year]  Refined Petroleum Products (RPP) Imports (TBtu/Yr)
  xSupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpInput/xSupplyAdjustments") # [FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)
  
  #
  # Scratch Variables
  #
  ProcSw::VariableArray{1} = zeros(Float32,length(PI)) # [PI] Procedure on/off Switch
  xRPPDemand::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Refined Petroleum Products (RPP) Demand (TBtu/Yr)
end

# 
# Step 1. Assign value to RPPEff
#
function InitializeRPPEff(data)
  (;db) = data
  (;RPPEff) = data
  
  @. RPPEff = 1.00
  WriteDisk(db,"SCalDB/RPPEff",RPPEff)
end

#
# Step 2. and Step 4. Execute historical period
#
function RunHistory(data)
  (;db) = data

  RunTime = HisTime
  Engine.CallNewRunModel(db,RunTime)
  
end

#
# Step 3. Adjust RPP value
#
function AdjustRPPEff(data)
  (;db) = data
  (;Areas,Nation,Years) = data
  (;ANMap,RPPDemand,RPPEff) = data
  (;xRPPAProd,xRPPDemand,xRPPExports,xRPPImports) = data
  
  RPPDemand = ReadDisk(db,"SpOutput/RPPDemand")

  nation = Select(Nation,"CN")
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for year in Years
    xRPPDemand[nation,year] = sum(xRPPAProd[area,year] for area in areas)+
                              xRPPImports[nation,year]-xRPPExports[nation,year]
  end

  years = collect(First:Last)
  for year in years
    @finite_math RPPEff[nation,year] =
      RPPEff[nation,year]*RPPDemand[nation,year]/xRPPDemand[nation,year]
  end

  years = collect(Future:Final)
  for year in years  
    RPPEff[nation,year] = RPPEff[nation,Last]
  end

  WriteDisk(db,"SCalDB/RPPEff",RPPEff)
end
  
#
# Step 5. Set future values of Supply Adjustments
#
function AdjustSupply(data)
  (;db) = data
  (;FuelEP,FuelEPs,Nation,Nations,Year,Years) = data
  (;RPPAdjustments,SupplyAdjustments) = data
  (;xRPPAdjustments,xSupplyAdjustments) = data
 
  RPPAdjustments = ReadDisk(db,"SpOutput/RPPAdjustments")
  SupplyAdjustments = ReadDisk(db,"SpOutput/SupplyAdjustments")
 
  years = collect(Zero:Last)
  for year in years, nation in Nations
    xRPPAdjustments[nation,year] = RPPAdjustments[nation,year]
  end
  
  for year in years, nation in Nations, fuelep in FuelEPs
    xSupplyAdjustments[fuelep,nation,year] = SupplyAdjustments[fuelep,nation,year]
  end
  
  years = collect(Future:Final)
  for year in years, nation in Nations 
    xRPPAdjustments[nation,year] = xRPPAdjustments[nation,Last]
  end
  
  for year in years, nation in Nations, fuelep in FuelEPs
    xSupplyAdjustments[fuelep,nation,year] = xSupplyAdjustments[fuelep,nation,Last]
  end

  WriteDisk(db,"SpInput/xRPPAdjustments",xRPPAdjustments)
  WriteDisk(db,"SpInput/xSupplyAdjustments",xSupplyAdjustments)
end

function Control(db)
  data = Data(; db)
  
  # 
  # Step 1. Assign value to RPPEff
  #
  InitializeRPPEff(data)
  
  #
  # Step 2. Execute historical period
  #
  RunHistory(data)
  
  #
  # Step 3. Adjust RPP value
  #
  AdjustRPPEff(data)

  #
  # Step 4. Rerun historical period
  #
  RunHistory(data)
  
  #
  # Step 5. Set future values of Supply Adjustments
  #
  AdjustSupply(data)
end

end #  Module SpRefineryCalib
