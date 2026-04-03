#
# FlowNation.jl - National Energy Imports and Exports (xFlowNation)
#
using EnergyModel

module FlowNation

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
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
  xExports::VariableArray{3} = ReadDisk(db,"SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xExportsFuel::VariableArray{3} = ReadDisk(db,"SpInput/xExportsFuel") # [Fuel,Nation,Year] Primary Exports (TBtu/Yr)
  xExpPurchases::VariableArray{2} = ReadDisk(db,"EGInput/xExpPurchases") # [Area,Year] Historical Purchases from Areas in a different Country (GWh/Yr)
  xExpSales::VariableArray{2} = ReadDisk(db,"EGInput/xExpSales") # [Area,Year] Historical Sales to Areas in a different Country (GWh/Yr)
  xImports::VariableArray{3} = ReadDisk(db,"SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xImportsFuel::VariableArray{3} = ReadDisk(db,"SpInput/xImportsFuel") # [Fuel,Nation,Year] Primary Imports (TBtu/Yr)
  xRPPExports::VariableArray{2} = ReadDisk(db,"SpInput/xRPPExports") # [Nation,Year] Refined Petroleum Products Exports (TBtu/Yr)
  xRPPImports::VariableArray{2} = ReadDisk(db,"SpInput/xRPPImports") # [Nation,Year] Refined Petroleum Products Imports (TBtu/Yr)
  xFlowNation::VariableArray{4} = ReadDisk(db,"SpInput/xFlowNation") # [Fuel,Nation,NationX,Year] Historical Energy Flow to Nation from NationX (TBtu/Yr)
  ImportsNationFraction::VariableArray{4} = ReadDisk(db,"SpInput/ImportsNationFraction") # [Fuel,Nation,NationX,Year] Fraction to specify flows of Imports (Btu/Btu)
  ExportsNationFraction::VariableArray{4} = ReadDisk(db,"SpInput/ExportsNationFraction") # [Fuel,Nation,NationX,Year] Fraction to specify flows of Exports (Btu/Btu)

  #
  # Scratch Variables
  #
  ExportsNA::VariableArray{3} = zeros(Float32,length(Fuel),length(Nation),length(Year)) # [Fuel,Nation,Year] Exports within North America (TBtu/Yr)
  ImportsNA::VariableArray{3} = zeros(Float32,length(Fuel),length(Nation),length(Year)) # [Fuel,Nation,Year] Imports within North America (TBtu/Yr)
  xRPPFlowNation::VariableArray{3} = zeros(Float32,length(Nation),length(NationX),length(Year)) # [Nation,NationX,Year] Historical RPP Energy Flow to Nation from NationX (TBtu/Yr)
end

function SupplyCalibration(db)
  data = SControl(; db)
  (;Fuel,FuelEP,Fuels,Nation) = data
  (;NationX,NationXs,Nations,Years) = data
  (;ANMap,xExports,xExportsFuel,xExpPurchases,xExpSales,xImports,xImportsFuel,xRPPExports,xRPPImports,xFlowNation) = data
  (;ImportsNationFraction,ExportsNationFraction) = data
  (;ExportsNA,ImportsNA,xRPPFlowNation) = data

  #
  # Move Imports and Exports to Fuel variable
  #

  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  CrudeOil = Select(FuelEP,"CrudeOil")

  for nation in Nations, year in Years
    xImportsFuel[LightCrudeOil,nation,year] = xImports[CrudeOil,nation,year]
    xExportsFuel[LightCrudeOil,nation,year] = xExports[CrudeOil,nation,year]
  end

  NaturalGasFuel = Select(Fuel,"NaturalGas")
  NaturalGasFuelEP = Select(FuelEP,"NaturalGas")

  for nation in Nations, year in Years
    xImportsFuel[NaturalGasFuel,nation,year] = xImports[NaturalGasFuelEP,nation,year]
    xExportsFuel[NaturalGasFuel,nation,year] = xExports[NaturalGasFuelEP,nation,year]
  end

  CoalFuel = Select(Fuel,"Coal")
  CoalFuelEP = Select(FuelEP,"Coal")

  for nation in Nations, year in Years
    xImportsFuel[CoalFuel,nation,year] = xImports[CoalFuelEP,nation,year]
    xExportsFuel[CoalFuel,nation,year] = xExports[CoalFuelEP,nation,year]
  end

  Gasoline = Select(Fuel,"Gasoline")
  GasolineFuelEP = Select(FuelEP,"Gasoline")

  for nation in Nations, year in Years
    xImportsFuel[Gasoline,nation,year] = xRPPImports[nation,year]
    xExportsFuel[Gasoline,nation,year] = xRPPExports[nation,year]
  end

  Electric = Select(Fuel,"Electric")

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  MX = Select(Nation,"MX")

  USx = Select(NationX,"US")
  CNx = Select(NationX,"CN")
  MXx = Select(NationX,"MX")
   
  for nation in Nations, year in Years
    areas = findall(ANMap[:,nation] .== 1)
    xImportsFuel[Electric,nation,year] = sum(xExpPurchases[area,year] for area in areas)*3412/1e6
    xExportsFuel[Electric,nation,year] = sum(xExpSales[area,year] for area in areas)*3412/1e6
  end

  for year in Years
    xImportsFuel[Electric,US,year] = xExportsFuel[Electric,CN,year]+
                                     xExportsFuel[Electric,MX,year]
                                     
    xExportsFuel[Electric,US,year] = xImportsFuel[Electric,CN,year]+
                                     xImportsFuel[Electric,MX,year]
  end
  
  WriteDisk(db, "SpInput/xExportsFuel", xExportsFuel)
  WriteDisk(db, "SpInput/xImportsFuel", xImportsFuel)

  #
  # Nation Flows complete and consistent through 2017
  #
  
  HeavyCrudeOil = Select(Fuel,"HeavyCrudeOil")
  
  for nation in Nations, nationx in NationXs, year in Years
    
    xFlowNation[LightCrudeOil,nation,nationx,year] =
      xFlowNation[LightCrudeOil,nation,nationx,year]+
      xFlowNation[HeavyCrudeOil,nation,nationx,year]
      
    xFlowNation[HeavyCrudeOil,nation,nationx,year] = 0
  end

  #
  # RPP Flows are stored in Gasoline
  #

  RPPs = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel","Kerosene",
                      "LFO","LPG","Lubricants","Naphtha","NonEnergy","PetroFeed","PetroCoke","StillGas"])
  
  for nation in Nations, nationx in NationXs, year in Years
    
    xRPPFlowNation[nation,nationx,year] = 
      sum(xFlowNation[fuel,nation,nationx,year] for fuel in RPPs)
      
    xFlowNation[Gasoline,nation,nationx,year] = xRPPFlowNation[nation,nationx,year]
  end

  #
  # Exclude Coal which is computed in CoalSupplyBalance.txt
  # Include until we fin issue in CoalSupplyBalance.txt
  #

  fuels = Select(Fuel,["NaturalGas","LightCrudeOil","Gasoline","Coal","Electric"])
  nations = Select(Nation,["US","CN","MX"])
  nationxs = Select(NationX,["US","CN","MX"])
  
  for fuel in fuels, nation in nations, year in Years
    ImportsNA[fuel,nation,year] = sum(xFlowNation[fuel,nation,nationx,year] for nationx in nationxs)
  end
  
  for fuel in fuels, year in Years
    ExportsNA[fuel,US,year] = sum(xFlowNation[fuel,nation,USx,year] for nation in nations)
    ExportsNA[fuel,MX,year] = sum(xFlowNation[fuel,nation,MXx,year] for nation in nations)
    ExportsNA[fuel,CN,year] = sum(xFlowNation[fuel,nation,CNx,year] for nation in nations)
  end
 
  #
  # ROW Flows
  #

  ROW = Select(Nation,"ROW")
  ROWx = Select(NationX,"ROW")

  for fuel in fuels, nation in nations, year in Years
    xFlowNation[fuel,nation,ROWx,year] = xImportsFuel[fuel,nation,year]-ImportsNA[fuel,nation,year]
  end

  for fuel in fuels, nation in nations, year in Years
    xFlowNation[fuel,ROW,nation,year] = xExportsFuel[fuel,nation,year]-ExportsNA[fuel,nation,year]
  end
  
  WriteDisk(db, "SpInput/xFlowNation", xFlowNation)
  
  #
  # ROW Imports and Exports
  #
  #
  # Re-arranged equations from Promula version to make it look cleaner due to sum statements - Ian
  #
  for year in Years
    xImports[CrudeOil,ROW,year] =
      sum(xFlowNation[LightCrudeOil,ROW,nationx,year] for nationx in nationxs)
      
    xImports[NaturalGasFuelEP,ROW,year] =
      sum(xFlowNation[NaturalGasFuel,ROW,nationx,year] for nationx in nationxs)
      
    xImports[CoalFuelEP,ROW,year] =
      sum(xFlowNation[CoalFuel,ROW,nationx,year] for nationx in nationxs)
      
    xImports[GasolineFuelEP,ROW,year] =
      sum(xFlowNation[Gasoline,ROW,nationx,year] for nationx in nationxs)
      
    xRPPImports[ROW,year] =
      sum(xFlowNation[Gasoline,ROW,nationx,year] for nationx in nationxs)
  end

  for year in Years
    xExports[CrudeOil,ROW,year] =
      sum(xFlowNation[LightCrudeOil,nation,ROW,year] for nation in nations)
      
    xExports[NaturalGasFuelEP,ROW,year] =
      sum(xFlowNation[NaturalGasFuel,nation,ROW,year] for nation in nations)
      
    xExports[CoalFuelEP,ROW,year] =
      sum(xFlowNation[CoalFuel,nation,ROW,year] for nation in nations)
      
    xExports[GasolineFuelEP,ROW,year] =
      sum(xFlowNation[Gasoline,nation,ROW,year] for nation in nations)
      
    xRPPExports[ROW,year] =
      sum(xFlowNation[Gasoline,nation,ROW,year] for nation in nations)
  end
  
  WriteDisk(db, "SpInput/xImports", xImports)
  WriteDisk(db, "SpInput/xExports", xExports)
  WriteDisk(db, "SpInput/xRPPImports", xRPPImports)
  WriteDisk(db, "SpInput/xRPPExports", xRPPExports)
  
  for fuel in Fuels, nation in Nations, nationx in NationXs, year in Years
    
    @finite_math ImportsNationFraction[fuel,nation,nationx,year] =
      xFlowNation[fuel,nation,nationx,year]/xImportsFuel[fuel,nation,year]
      
    @finite_math ExportsNationFraction[fuel,nation,nationx,year] =
      xFlowNation[fuel,nation,nationx,year]/xExportsFuel[fuel,nationx,year]
  end
  
  years = collect(Yr(2018):Final)
  
  for fuel in Fuels, nation in Nations, nationx in NationXs, year in years
    ImportsNationFraction[fuel,nation,nationx,year] = ImportsNationFraction[fuel,nation,nationx,year-1]
    ExportsNationFraction[fuel,nation,nationx,year] = ExportsNationFraction[fuel,nation,nationx,year-1]
  end

  WriteDisk(db, "SpInput/ImportsNationFraction", ImportsNationFraction)
  WriteDisk(db, "SpInput/ExportsNationFraction", ExportsNationFraction)

end


function CalibrationControl(db)
  @info "FlowNation.jl - CalibrationControl"

  SupplyCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
