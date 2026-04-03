#
# CoalSupplyBalance.jl
#
using EnergyModel

module CoalSupplyBalance

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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  NationX::SetArray = ReadDisk(db,"MainDB/NationXKey")
  NationXDS::SetArray = ReadDisk(db,"MainDB/NationXDS")
  NationXs::Vector{Int} = collect(Select(NationX))
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xCProd::VariableArray{2} = ReadDisk(db,"SpInput/xCProd") # [Nation,Year] Coal Production - Reference Case (TBtu/Yr)
  xExports::VariableArray{3} = ReadDisk(db,"SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xFlowNation::VariableArray{4} = ReadDisk(db,"SpInput/xFlowNation") # [Fuel,Nation,NationX,Year] Historical Energy Flow to Nation from NationX (TBtu/Yr)
  xImports::VariableArray{3} = ReadDisk(db,"SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)
  xSupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpInput/xSupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)

  # Scratch Variables
  ExportsCN::VariableArray{2} = zeros(Float32,length(FuelEP),length(Year)) # [FuelEP,Year] Temporary Values for Canada Exports (TBtu/Yr)
  ImportsCN::VariableArray{2} = zeros(Float32,length(FuelEP),length(Year)) # [FuelEP,Year] Temporary Values for Canada Imports (TBtu/Yr)
  xCDemand::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Coal Demand (TBtu/Yr)
end

function SCalibration(db)
  data = SControl(; db)
  (;Areas,ECCs,Fuel,FuelEP,Nation,NationX,Nations,Years) = data
  (;ANMap,xCProd,xExports,xFlowNation,xImports,xTotDemand,xSupplyAdjustments) = data
  (;ExportsCN,ImportsCN,xCDemand) = data

  # 
  # Coal Imports and Exports
  # 
  # The initial values for xImports and xExports come from xFlowNation
  # For Canada the values for xFlowNation (ROW) are adjusted to maintain the
  # values of xImports and xExports from xCImports and xCExport from vData
  # 
  coal = Select(Fuel,"Coal")
  for nation in Nations, year in Years
    xCDemand[nation,year] = sum(xTotDemand[coal,ecc,area,year]*ANMap[area,nation] for ecc in ECCs, area in Areas)
  end

  coalep = Select(FuelEP,"Coal")
  US = Select(Nation,"US")
  MX = Select(Nation,"MX")
  CN = Select(Nation,"CN")
  CNX = Select(NationX,"CN")
  ROW = Select(Nation,"ROW")
  ROWX = Select(NationX,"ROW")

  for year in Years
    xImports[coalep,US,year] = sum(xFlowNation[coal,US,n,year] for n in Select(NationX,["CN","MX","ROW"]))
    xExports[coalep,US,year] = sum(xFlowNation[coal,n,US,year] for n in Select(Nation, ["CN","MX","ROW"]))

    xImports[coalep,MX,year] = sum(xFlowNation[coal,MX,n,year] for n in Select(NationX,["US","CN","ROW"]))
    xExports[coalep,MX,year] = sum(xFlowNation[coal,n,MX,year] for n in Select(Nation, ["US","CN","ROW"]))

    ImportsCN[coalep,year]  =  sum(xFlowNation[coal,CN,n,year] for n in Select(NationX,["US","MX","ROW"]))
    ExportsCN[coalep,year]  =  sum(xFlowNation[coal,n,CN,year] for n in Select(Nation, ["US","MX","ROW"]))
  end

  for year in Years
    # 
    # Adjust ROW Imports to Canada
    # 
    xFlowNation[coal,CN,ROWX,year] = xFlowNation[coal,CN,ROWX,year]-ImportsCN[coalep,year]

    # 
    # Adjust ROW Exports from Canada
    # 
    xFlowNation[coal,ROW,CNX,year] = xFlowNation[coal,ROW,CNX,year]-ExportsCN[coalep,year]

    xImports[coalep,ROW,year] = sum(xFlowNation[coal,ROW,n,year] for n in Select(NationX,["US","CN","MX"]))
    xExports[coalep,ROW,year] = sum(xFlowNation[coal,n,ROW,year] for n in Select(Nation, ["US","CN","MX"]))
  end
  
  # 
  # Supply Adjustment to balance Supply, Demand, Imports, and Exports
  # 
  for n in Nations, y in Years
    xSupplyAdjustments[coalep,n,y] = xCDemand[n,y]+xExports[coalep,n,y]-xCProd[n,y]-xImports[coalep,n,y]
  end

  WriteDisk(db,"SpInput/xExports",xExports)
  WriteDisk(db,"SpInput/xImports",xImports)
  WriteDisk(db,"SpInput/xSupplyAdjustments",xSupplyAdjustments)

end

function CalibrationControl(db)
  @info "CoalSupplyBalance.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
