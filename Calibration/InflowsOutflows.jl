#
# InflowsOutflows.jl - Energy Imports and Exports
#
using EnergyModel
using DataFrames
using CSV

module InflowsOutflows

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
import ...DataFrames: DataFrame
import ...CSV: write


const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xDmdArea::VariableArray{3} = ReadDisk(db,"SpInput/xDmdArea") # [Fuel,Area,Year] Energy Demands (TBtu/Yr)
  RPPEff::VariableArray{2} = ReadDisk(db,"SCalDB/RPPEff") # [Nation,Year] RPP Efficiency Factor (Btu/Btu)
  xRPPAProd::VariableArray{2} = ReadDisk(db,"SInput/xRPPAProd") # [Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xRPPProd::VariableArray{2} = ReadDisk(db,"SInput/xRPPProd") # [Nation,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)
  xProdArea::VariableArray{3} = ReadDisk(db,"SpInput/xProdArea") # [Fuel,Area,Year] Energy Production (TBtu/Yr)
  xCAProd::VariableArray{2} = ReadDisk(db,"SpInput/xCAProd") # [Area,Year] Coal Production (TBtu/Yr)
  xEGPA::VariableArray{3} = ReadDisk(db,"EGInput/xEGPA") # [Plant,Area,Year] Historical Electricity Generated (GWh/Yr)
  xGAProd::VariableArray{3} = ReadDisk(db,"SInput/xGAProd") # [Process,Area,Year] Natural Gas Production (TBtu/Yr)
  xGProd::VariableArray{3} = ReadDisk(db,"SInput/xGProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  xOAProd::VariableArray{3} = ReadDisk(db,"SInput/xOAProd") # [Process,Area,Year] Oil Production (TBtu/Yr)
  xOProd::VariableArray{3} = ReadDisk(db,"SInput/xOProd") # [Process,Nation,Year] Primary Oil Production (TBtu/Yr)
  xRPPAdjustments::VariableArray{2} = ReadDisk(db,"SpInput/xRPPAdjustments") # [Nation,Year] RPP Supply Adjustments (TBtu/Yr)
  xSupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpInput/xSupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)
  xExportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xExportsArea") # [Fuel,Area,Year] Exports of Energy (TBtu/Yr)
  xExportsFraction::VariableArray{3} = ReadDisk(db,"SpInput/xExportsFraction") # [Fuel,Area,Year] Exports Fraction (Btu/Btu)
  xExportsFuel::VariableArray{3} = ReadDisk(db,"SpInput/xExportsFuel") # [Fuel,Nation,Year] Primary Exports (TBtu/Yr)
  xFlowNation::VariableArray{4} = ReadDisk(db,"SpInput/xFlowNation") # [Fuel,Nation,NationX,Year] Historical Energy Flow to Nation from NationX (TBtu/Yr)
  xImportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xImportsArea") # [Fuel,Area,Year] Imports of Energy (TBtu/Yr)
  xImportsFraction::VariableArray{3} = ReadDisk(db,"SpInput/xImportsFraction") # [Fuel,Area,Year] Imports Fraction (Btu/Btu)
  xImportsFuel::VariableArray{3} = ReadDisk(db,"SpInput/xImportsFuel") # [Fuel,Nation,Year] Primary Imports (TBtu/Yr)
  xInflow::VariableArray{4} = ReadDisk(db,"SpInput/xInflow") # [Fuel,Area,Nation,Year] Historical Energy Inflow (TBtu/Yr)
  xOutflow::VariableArray{4} = ReadDisk(db,"SpInput/xOutflow") # [Fuel,Area,Nation,Year] Historical Energy Outflow (TBtu/Yr)
  xInflowFraction::VariableArray{3} = ReadDisk(db,"SpInput/xInflowFraction") # [Fuel,Area,Year] Domestic Inflow Fraction (Btu/Btu)
  xOutflowFraction::VariableArray{3} = ReadDisk(db,"SpInput/xOutflowFraction") # [Fuel,Area,Year] Domestic Outflow Fraction (Btu/Btu)
  xSurplusArea::VariableArray{3} = ReadDisk(db,"SpInput/xSurplusArea") # [Fuel,Area,Year] Surplus Supply (TBtu/Yr)
  ImportsAreaFraction::VariableArray{4} = ReadDisk(db,"SpInput/ImportsAreaFraction") # [Fuel,Area,Nation,Year] Fraction to specify Area Flows of Imports (Btu/Btu)
  ExportsAreaFraction::VariableArray{4} = ReadDisk(db,"SpInput/ExportsAreaFraction") # [Fuel,Area,Nation,Year] Fraction to specify Area Flows of Exports (Btu/Btu)
  InflowFraction::VariableArray{3} = ReadDisk(db,"SpInput/InflowFraction") # [Fuel,Area,Year] Domestic Inflow Fraction (Btu/Btu)
  OutflowFraction::VariableArray{3} = ReadDisk(db,"SpInput/OutflowFraction") # [Fuel,Area,Year] Domestic Outflow Fraction (Btu/Btu)

  #
  # Scratch Variables
  #
  ExportsEst::VariableArray{3} = zeros(Float32,length(Fuel),length(Area),length(Year)) # [Fuel,Area,Year] Estimate of Energy Exports (TBtu/Yr)
  ExportsOther::VariableArray{3} = zeros(Float32,length(Fuel),length(Nation),length(Year)) # [Fuel,Nation,Year] 
  ExportsTotal::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] Total Energy Exports for Allocation (TBtu/Yr)
  ExportsTotal1::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] Total Energy Exports for Scaling (TBtu/Yr)
  ImportsEst::VariableArray{3} = zeros(Float32,length(Fuel),length(Area),length(Year)) # [Fuel,Area,Year] Estimate of Energy Imports (TBtu/Yr)
  ImportsOther::VariableArray{3} = zeros(Float32,length(Fuel),length(Nation),length(Year)) # [Fuel,Nation,Year] 
  ImportsTotal::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] Total Energy Imports for Allocation (TBtu/Yr)
  ImportsTotal1::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] Total Energy Imports for Scaling (TBtu/Yr)
  InflowEst::VariableArray{3} = zeros(Float32,length(Fuel),length(Area),length(Year)) # [Fuel,Area,Year] Estimate of Energy Inflow (TBtu/Yr)
  InflowTotal::VariableArray{3} = zeros(Float32,length(Fuel),length(Nation),length(Year)) # [Fuel,Nation,Year] Total Inflow of Energy (TBtu/Yr)
  # KeyNation     'Nation Key', Type=String(4)
  Multiplier::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Multiplier for Supply Adjustment (Btu/Btu)
  # NPointer      'Pointer to Nation'
  # NXPointer     'Pointer to Other Nations'
  # NationNum     'Pointer to Nation'
  # OtherNum      'Pointer to Other Nations'
  OutflowEst::VariableArray{3} = zeros(Float32,length(Fuel),length(Area),length(Year)) # [Fuel,Area,Year] Estimate of Energy Outflow (TBtu/Yr)
  OutflowTotal::VariableArray{3} = zeros(Float32,length(Fuel),length(Nation),length(Year)) # [Fuel,Nation,Year] Total Outflow of Energy (TBtu/Yr)
  xCProd::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Coal Production (TBtu/Yr)
  xRPPADemand::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Refined Petroleum Products (RPP) Demand (TBtu/Yr)
end

function EnergyDemand(data)
  (; db) = data
  (;Area,Areas,ECCs,Fuel,FuelEP,Fuels,Nation,Nations,Plants,Process,Years) = data
  (;ANMap,xDmdArea,xRPPAProd,xRPPProd,xTotDemand,xProdArea,xCAProd,xEGPA,xGAProd) = data
  (;xGProd,xOAProd,xOProd,xRPPAdjustments,xSupplyAdjustments,xInflow,xOutflow,xCProd,xRPPADemand) = data
  (;InflowFraction,OutflowFraction,Multiplier) = data

  for year in Years, area in Areas, fuel in Fuels
    xDmdArea[fuel,area,year] = sum(xTotDemand[fuel,ecc,area,year] for ecc in ECCs)
  end

  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  for year in Years, area in Areas 
    xDmdArea[LightCrudeOil,area,year] = xRPPAProd[area,year]
  end
  
  #
  # RPP Demands are stored in Gasoline
  #
  Gasoline = Select(Fuel,"Gasoline")
  fuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline",
                 "HFO","JetFuel","Kerosene","LFO","LPG","Lubricants",
                 "Naphtha","NonEnergy","PetroFeed","PetroCoke","StillGas"])
  for year in Years, area in Areas 
    xRPPADemand[area,year] = sum(xTotDemand[fuel,ecc,area,year] for fuel in fuels, ecc in ECCs)
    xDmdArea[Gasoline,area,year] = xRPPADemand[area,year]
  end

  #
  # TODO - check a non-zero value is better for other fuels - Jeff Amlin 6/19/25
  #
  ROW = Select(Area,"ROW")
  fuels = Select(Fuel,"Gasoline")
  for year in Years, fuel in fuels
    xDmdArea[fuel,ROW,year] = 101000
  end
  WriteDisk(db, "SpInput/xDmdArea", xDmdArea)

end

function EnergyProduction(data)
  (; db) = data
  (;Area,Areas,ECCs,Fuel,FuelEP,Fuels,Nation,Nations,Plants,Process,Years) = data
  (;ANMap,xDmdArea,xRPPAProd,xRPPProd,xTotDemand,xProdArea,xCAProd,xEGPA,xGAProd) = data
  (;xGProd,xOAProd,xOProd,xRPPAdjustments,xSupplyAdjustments,xInflow,xOutflow,xCProd,xRPPADemand) = data
  (;InflowFraction,OutflowFraction,Multiplier) = data
  
  #
  # Production by Area (xProdArea)
  #
  
  #
  # Natural Gas
  #
  NaturalGasFuel = Select(Fuel,"NaturalGas")
  NaturalGasFuelEP = Select(FuelEP,"NaturalGas")
  GasProcesses = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction"])
  for area in Areas, y in Years
    nation = only(Select(ANMap[area, :], .==(1))) 
    
    @finite_math Multiplier[area,y] = 
      (1+xSupplyAdjustments[NaturalGasFuelEP,nation,y]/
      sum(xGProd[process,nation,y] for process in GasProcesses))
                        
    xProdArea[NaturalGasFuel,area,y] = 
      sum(xGAProd[process,area,y] for process in GasProcesses)*Multiplier[area,y]
  end
  
  #
  # Crude Oil stored in "LightCrudeOil"
  #  
  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  CrudeOil = Select(FuelEP,"CrudeOil")
  OilProcesses = Select(Process,["LightOilMining","HeavyOilMining","FrontierOilMining",
                        "PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining",
                        "PentanesPlus","Condensates"])
  for area in Areas, y in Years
    Multiplier[area,y] = @finite_math sum((1+xSupplyAdjustments[CrudeOil,nation,y]/
                         sum(xOProd[process,nation,y] for process in OilProcesses))*ANMap[area,nation]
                         for nation in Nations)
    xProdArea[LightCrudeOil,area,y] = sum(xOAProd[process,area,y] for process in OilProcesses)*
                                      Multiplier[area,y]                                   
  end

  
  #
  # Coal
  #
  CoalFuel = Select(Fuel,"Coal")
  CoalFuelEP = Select(FuelEP,"Coal")
  for nation in Nations, y in Years
    xCProd[nation,y] = sum(xCAProd[area,y]*ANMap[area,nation] for area in Areas)
  end
  for area in Areas, y in Years
    Multiplier[area,y] =  sum((1+ @finite_math xSupplyAdjustments[CoalFuelEP,nation,y]/
                         xCProd[nation,y])*ANMap[area,nation] for nation in Nations)
    xProdArea[CoalFuel,area,y] = xCAProd[area,y]*Multiplier[area,y]
  end

  #
  # RPP stored in Gasoline
  #
  Gasoline = Select(Fuel,"Gasoline")
  for area in Areas, y in Years
    Multiplier[area,y] =  sum((1+ @finite_math xRPPAdjustments[nation,y]/xRPPProd[nation,y])*
                         ANMap[area,nation] for nation in Nations)
    xProdArea[Gasoline,area,y] = xRPPAProd[area,y]*Multiplier[area,y]
  end

  #
  # Electricity
  #
  Electric = Select(Fuel,"Electric")
  for area in Areas, y in Years
    xProdArea[Electric,area,y] = sum(xEGPA[plant,area,y]*3412/1e6 for plant in Plants)
  end
  
  ROW = Select(Area,"ROW") 
  for year in Years, fuel in Fuels
    xProdArea[fuel,ROW,year] = 101000
  end
  WriteDisk(db, "SpInput/xProdArea", xProdArea)

end


function InitializeFlows(fuels,data)
  (; db) = data
  (;Area,Areas,Fuel,Nation,Nations,Years) = data
  (;xInflow,xOutflow) = data

  xInflow[fuels,Areas,Nations,Years] .= 0
  xOutflow[fuels,Areas,Nations,Years]  .= 0

  WriteDisk(db, "SpInput/xInflow", xInflow)
  WriteDisk(db, "SpInput/xOutflow", xOutflow)

end

function MXRowImportsExports(fuels,area,nation,data)
  (; db) = data
  (;Area,Fuel,Nation,Nations,Years) = data
  (;xFlowNation,xInflow,xOutflow) = data

  OtherNum = filter(x -> x != nation, Nations)
  for fuel in fuels, nx in OtherNum, y in Years
    xInflow[fuel,area,nx,y] = xFlowNation[fuel,nation,nx,y]
    xOutflow[fuel,area,nx,y] = xFlowNation[fuel,nx,nation,y]
  end
  
  WriteDisk(db, "SpInput/xInflow", xInflow)
  WriteDisk(db, "SpInput/xOutflow", xOutflow)

end

function CNUSImports(fuels,data)
  (; db) = data
  (;Area,Fuel,Nation,Nations,Years) = data
  (;ANMap,xDmdArea,xProdArea,xImportsFraction,xImportsFuel,xInflow,xFlowNation) = data
  (;ImportsEst,ImportsTotal,ImportsTotal1) = data

  nations = Select(Nation,["US","CN"])

  for nation in nations
    OtherNations = filter(x -> x != nation, Nations) # this is actually NationX, need to find better way to write this
    areas = findall(ANMap[:,nation] .== 1)

    #
    # Estimate Area Imports
    # 
    if (Nation[nation] == "CN")
      for fuel in fuels, area in areas, y in Years
        ImportsEst[fuel,area,y]=max(xDmdArea[fuel,area,y]*xImportsFraction[fuel,area,y],
                                xDmdArea[fuel,area,y]*0.01)
      end
    else
      for fuel in fuels, area in areas, y in Years
        ImportsEst[fuel,area,y]=max(xDmdArea[fuel,area,y]-xProdArea[fuel,area,y],
                                xDmdArea[fuel,area,y]*0.1)
      end
    end

    #
    # Scale Area Imports to National Total (xImportsFuel)
    # 
    for fuel in fuels, y in Years
      ImportsTotal1[fuel,y] = sum(ImportsEst[fuel,area,y] for area in areas)
    end

    for fuel in fuels, area in areas, y in Years
      @finite_math ImportsEst[fuel,area,y] = ImportsEst[fuel,area,y]/
        ImportsTotal1[fuel,y]*xImportsFuel[fuel,nation,y]
    end
    
    #
    # Allocate National Imports to Areas
    # 
    
    for fuel in fuels, y in Years
      ImportsTotal[fuel,y] = sum(ImportsEst[fuel,area,y] for area in areas)
    end

    for fuel in fuels, nationx in OtherNations, area in areas, y in Years
      @finite_math xInflow[fuel,area,nationx,y] = xFlowNation[fuel,nation,nationx,y]*
        ImportsEst[fuel,area,y]/ImportsTotal[fuel,y]
    end
    
  end

  WriteDisk(db, "SpInput/xInflow", xInflow)
  
end

function CNUSExports(fuels,data)
  (; db) = data
  (;Area,Fuel,Nation,Nations,Years) = data
  (;ANMap,xDmdArea,xProdArea,xExportsFraction,xExportsFuel,xFlowNation,xOutflow) = data
  (;ExportsEst,ExportsTotal,ExportsTotal1) = data

  nations = Select(Nation,["US","CN"])

  for nation in nations
    OtherNations = filter(x -> x != nation, Nations) # this is actually NationX, need to find clearer way to write this - Ian
    areas = findall(ANMap[:,nation] .== 1)

    #
    # Estimate Area Exports
    # 
    if (Nation[nation] == "CN")
      for fuel in fuels, area in areas, y in Years
        ExportsEst[fuel,area,y]=max(xProdArea[fuel,area,y]*xExportsFraction[fuel,area,y],
                                xDmdArea[fuel,area,y]*0.01)
      end
    else
      for fuel in fuels, area in areas, y in Years
        ExportsEst[fuel,area,y]=max(xProdArea[fuel,area,y]-xDmdArea[fuel,area,y],
                                xProdArea[fuel,area,y]*0.1)
      end
    end

    #
    # Scale Area Exports to National Total (xExportsFuel)
    # 
    for fuel in fuels, y in Years
      ExportsTotal1[fuel,y] = sum(ExportsEst[fuel,area,y] for area in areas)
    end
    for fuel in fuels, area in areas, y in Years
      @finite_math ExportsEst[fuel,area,y] = ExportsEst[fuel,area,y]/ExportsTotal1[fuel,y]*xExportsFuel[fuel,nation,y]
    end

    #
    # Allocate National Exports to Areas
    # 
    for fuel in fuels, y in Years
      ExportsTotal[fuel,y] = sum(ExportsEst[fuel,area,y] for area in areas)
    end

    for fuel in fuels, nationx in OtherNations, area in areas, y in Years
      @finite_math xOutflow[fuel,area,nationx,y] = 
        xFlowNation[fuel,nationx,nation,y]*ExportsEst[fuel,area,y]/ExportsTotal[fuel,y]
    end
  
  end

  WriteDisk(db, "SpInput/xOutflow", xOutflow)

end

function AreaImportsExports(fuels,data)
  (; db) = data
  (;Area,Fuel,Nation,Nations,Years) = data
  (;ANMap,xExportsArea,xImportsArea,xInflow,xOutflow) = data

  nations = Select(Nation,["US","CN"])

  for nation in nations
    OtherNations = filter(x -> x != nation, Nations) # this is actually NationX, need to find clearer way to write this - Ian
    areas = findall(ANMap[:,nation] .== 1)

    for fuel in fuels, area in areas, y in Years
      xImportsArea[fuel,area,y] = 0
      xExportsArea[fuel,area,y] = 0
    end
    
    for nationx in OtherNations, fuel in fuels, area in areas, y in Years
      xImportsArea[fuel,area,y] = xImportsArea[fuel,area,y] + xInflow[fuel,area,nationx,y]
      xExportsArea[fuel,area,y] = xExportsArea[fuel,area,y] + xOutflow[fuel,area,nationx,y]
    end

  end

  WriteDisk(db, "SpInput/xImportsArea", xImportsArea)
  WriteDisk(db, "SpInput/xExportsArea", xExportsArea)

end

function InternalFlows(fuels,data)
  (; db) = data
  (;Area,Fuel,Nation,Years,ANMap) = data
  (;xDmdArea,xProdArea,xExportsArea,xImportsArea,xInflow,xOutflow,xInflowFraction,xSurplusArea) = data
  (;InflowEst,InflowTotal,OutflowEst,OutflowTotal,xOutflowFraction) = data

  nations = Select(Nation,["US","CN"])

  for nation in nations
    areas = findall(ANMap[:,nation] .== 1)

    if (Nation[nation] == "CN")
      for fuel in fuels, area in areas, y in Years
        InflowEst[fuel,area,y] = xDmdArea[fuel,area,y]*xInflowFraction[fuel,area,y]
        OutflowEst[fuel,area,y] = xProdArea[fuel,area,y]*xOutflowFraction[fuel,area,y]  
      end
      
    else
      for fuel in fuels, area in areas, y in Years
 
        InflowEst[fuel,area,y]=max(xDmdArea[fuel,area,y]-xProdArea[fuel,area,y]-
                                xImportsArea[fuel,area,y]+xExportsArea[fuel,area,y],
                                xDmdArea[fuel,area,y]*0.05)
                                
        OutflowEst[fuel,area,y]=xProdArea[fuel,area,y]-xDmdArea[fuel,area,y]+
                                xImportsArea[fuel,area,y]-xExportsArea[fuel,area,y]+
                                InflowEst[fuel,area,y]        
      end

    end
  
    for fuel in fuels, y in Years
      InflowTotal[fuel,nation,y] = sum(InflowEst[fuel,area,y] for area in areas)
      OutflowTotal[fuel,nation,y] = sum(OutflowEst[fuel,area,y] for area in areas)
    end

    for fuel in fuels, area in areas, y in Years
      xInflow[fuel,area,nation,y] = InflowEst[fuel,area,y]
      @finite_math xOutflow[fuel,area,nation,y] = 
        OutflowEst[fuel,area,y]*InflowTotal[fuel,nation,y]/OutflowTotal[fuel,nation,y]
    end
    
    # TODOPromulaExtra - xOutFlow for Gasoline in the US does not make sense - Jeff Amlin 10/2/24
    #if (Nation[nation] == "US")
    #  WSC = Select(Area,"WSC")
    #  Gasoline = Select(Fuel,"Gasoline")
    #  years = collect(Yr(2023):Yr(2025))
    #  for year in years
    #    loc2 = Year[year]
    #    @info ""
    #    loc1 = xOutflow[Gasoline,WSC,nation,year]
    #    @info "xOutFlow         - $loc1  $loc2 "
    #    loc1 = OutflowEst[Gasoline,WSC,year]
    #    @info "OutflowEst       - $loc1  $loc2 " 
    #    loc1 = OutflowTotal[Gasoline,nation,year]
    #    @info "OutflowTotal     - $loc1  $loc2 " 
    #    loc1 = xOutflowFraction[Gasoline,WSC,year]
    #    @info "xOutflowFraction - $loc1  $loc2 "      
    #  
    #    loc1 = xInflow[Gasoline,WSC,nation,year]
    #    @info "xInFlow          - $loc1  $loc2 "      
    #    loc1 = InflowEst[Gasoline,WSC,year]
    #    @info "InflowEst        - $loc1  $loc2 "
    #    loc1 = InflowTotal[Gasoline,nation,year]
    #    @info "InflowTotal      - $loc1  $loc2 "   
    #    loc1 = xInflowFraction[Gasoline,WSC,year]
    #    @info "xInflowFraction  - $loc1  $loc2 "
    #    
    #    loc1 = xProdArea[Gasoline,WSC,year]
    #    @info "xProdArea        - $loc1  $loc2 " 
    #    loc1 = xDmdArea[Gasoline,WSC,year]
    #    @info "xDmdArea         - $loc1  $loc2 " 
    #    loc1 = xImportsArea[Gasoline,WSC,year]
    #    @info "xImportsArea     - $loc1  $loc2 " 
    #    loc1 = xExportsArea[Gasoline,WSC,year]
    #    @info "xExportsArea     - $loc1  $loc2 " 
    #  end    
    #end

    for fuel in fuels, area in areas, y in Years
      xSurplusArea[fuel,area,y] = xProdArea[fuel,area,y]-xDmdArea[fuel,area,y]+xImportsArea[fuel,area,y]-
                                  xExportsArea[fuel,area,y]+xInflow[fuel,area,nation,y]-
                                  xOutflow[fuel,area,nation,y]
    end
    
  end
  
  WriteDisk(db, "SpInput/xSurplusArea", xSurplusArea)
  WriteDisk(db, "SpInput/xInflow", xInflow)
  WriteDisk(db, "SpInput/xOutflow", xOutflow)
  

end

function Control1(fuels,data)
  (;Area,Fuel,Nation) = data
  (;xInflow) = data

  InitializeFlows(fuels,data)

  MXArea = Select(Area,"MX")
  MXNation = Select(Nation,"MX")
  ROWArea = Select(Area,"ROW")
  ROWNation = Select(Nation,"ROW")

  MXRowImportsExports(fuels,MXArea,MXNation,data)
  MXRowImportsExports(fuels,ROWArea,ROWNation,data)

  CNUSImports(fuels,data)
  CNUSExports(fuels,data)
  AreaImportsExports(fuels,data)
  InternalFlows(fuels,data)
  
end

function AreaFractions(fuels,data)
  (; db) = data
  (;Areas,Fuel,Fuels,Nation,Nations,Years) = data
  (;ANMap,xInflow,xOutflow,ImportsAreaFraction,ExportsAreaFraction) = data
  (;ImportsOther,ExportsOther) = data

  for nation in Nations
    areas = findall(ANMap[Areas,nation] .== 1)
    NationNum = nation
    OtherNum = 1
    while OtherNum < 5
      if OtherNum != NationNum
      
        for year in Years, fuel in fuels
          ImportsOther[fuel,OtherNum,year] = 
            sum(xInflow[fuel,area,OtherNum,year] for area in areas)  
        end
      
        for year in Years, area in areas, fuel in fuels
          @finite_math ImportsAreaFraction[fuel,area,OtherNum,year] = 
            xInflow[fuel,area,OtherNum,year]/ImportsOther[fuel,OtherNum,year]
        end
        
        for year in Years, fuel in fuels
          ExportsOther[fuel,OtherNum,year] = 
            sum(xOutflow[fuel,area,OtherNum,year] for area in areas)  
        end
      
        for year in Years, area in areas, fuel in fuels
          @finite_math ExportsAreaFraction[fuel,area,OtherNum,year] = 
            xOutflow[fuel,area,OtherNum,year]/ExportsOther[fuel,OtherNum,year]
        end        
    
      end # if
      OtherNum = OtherNum+1
    end # while
  end # for nation
    
  # Canada has no historical crude oil exports to ROW, 
  # so use the fractions for Canada exports to US.  - Jeff Amlin 04/12/19 
    
  CN = Select(Nation,"CN")
  areas = findall(ANMap[Areas,CN] .== 1)
  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  ROW = Select(Nation,"ROW")
  US = Select(Nation,"US")
  for year in Years, area in areas
    ExportsAreaFraction[LightCrudeOil,area,ROW,year] =
      ExportsAreaFraction[LightCrudeOil,area,US,year]
  end
    
  years = collect(Yr(2018):Final)
  for year in years, nation in Nations, area in Areas, fuel in Fuels
    ImportsAreaFraction[fuel,area,nation,year] = 
      ImportsAreaFraction[fuel,area,nation,year-1]
    ExportsAreaFraction[fuel,area,nation,year] = 
      ExportsAreaFraction[fuel,area,nation,year-1]
  end

  WriteDisk(db,"SpInput/ExportsAreaFraction",ExportsAreaFraction)
  WriteDisk(db,"SpInput/ImportsAreaFraction",ImportsAreaFraction)

end

function AreaFlows(data)
  (; db) = data
  (;Areas,Fuel,Fuels,Nation,Nations,Years) = data
  (;ANMap,InflowFraction,OutflowFraction,xInflow,xOutflow,ImportsAreaFraction,ExportsAreaFraction) = data
  (;ImportsOther,ExportsOther,xDmdArea,xProdArea) = data
  
  nations = Select(Nation,["MX","ROW"])
  for nation in nations
    areas = findall(ANMap[:,nation] .== 1)
    for fuel in Fuels, area in areas, y in Years
      InflowFraction[fuel,area,y] = 0
      OutflowFraction[fuel,area,y] = 0
    end
  end

  nations = Select(Nation,["US","CN"])
  for nation in nations
    areas = findall(ANMap[Areas,nation] .== 1)
    for fuel in Fuels, area in areas
      for year in Years
        @finite_math InflowFraction[fuel,area,year] =
          xInflow[fuel,area,nation,year]/xDmdArea[fuel,area,year]
      end    
    end
    
    for fuel in Fuels, area in areas, year in Years  
      @finite_math OutflowFraction[fuel,area,year] = 
        xOutflow[fuel,area,nation,year]/xProdArea[fuel,area,year]
    end      
  end

  years = collect(Yr(2018):Final)
  for fuel in Fuels, area in Areas, y in years
    InflowFraction[fuel,area,y] = InflowFraction[fuel,area,y-1]
    OutflowFraction[fuel,area,y] = OutflowFraction[fuel,area,y-1]
  end

  WriteDisk(db, "SpInput/InflowFraction", InflowFraction)
  WriteDisk(db, "SpInput/OutflowFraction", OutflowFraction)  

end

function Control(db)
  @info "InflowsOutflows.jl - Control"
  data = SControl(; db)
  (;Areas,Fuel,Fuels,Nation,Nations,Years) = data
  (;ANMap,xInflow,xOutflow,ImportsAreaFraction,ExportsAreaFraction) = data
  (;ImportsOther,ExportsOther) = data
   
  EnergyDemand(data)  
  EnergyProduction(data)  
  #
  # Imports and Exports
  #
  fuels = Select(Fuel,["NaturalGas","LightCrudeOil","Gasoline","Coal","Electric"])
  Control1(fuels,data)

  #  WriteDisk(db, "SpInput/xInflow", xInflow)
  #  WriteDisk(db, "SpInput/xOutflow", xOutflow)
  
  AreaFractions(fuels,data)
  AreaFlows(data)  

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
