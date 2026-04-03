#
# SpImportsExports.jl
#

module SpImportsExports

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime,@finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))  
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))  
  NationX::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationXs::Vector{Int} = collect(Select(NationX))  
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaPurchases::VariableArray{1} = ReadDisk(db,"EGOutput/AreaPurchases",year) #[Area,Year]  Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{1} = ReadDisk(db,"EGOutput/AreaSales",year) #[Area,Year]  Sales to Areas in the same Country (GWh/Yr)
  CAProd::VariableArray{1} = ReadDisk(db,"SOutput/CAProd",year) #[Area,Year]  Primary Coal Production (TBtu/Yr)
  DmdArea::VariableArray{2} = ReadDisk(db,"SpOutput/DmdArea",year) #[Fuel,Area,Year]  Energy Demands (TBtu/Yr)
  EAProd::VariableArray{2} = ReadDisk(db,"SOutput/EAProd",year) #[Plant,Area,Year]  Electric Utility Production (GWh/Yr)
  Exports::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  ExportsArea::VariableArray{2} = ReadDisk(db,"SpOutput/ExportsArea",year) #[Fuel,Area,Year]  Exports of Energy (TBtu/Yr)
  ExportsAreaFraction::VariableArray{3} = ReadDisk(db,"SpInput/ExportsAreaFraction",year) #[Fuel,Area,Nation,Year]  Fraction to specify Area Flows of Exports (Btu/Btu)
  ExportsFuel::VariableArray{2} = ReadDisk(db,"SpOutput/ExportsFuel",year) #[Fuel,Nation,Year]  Primary Exports (TBtu/Yr)
  ExportsNationFraction::VariableArray{3} = ReadDisk(db,"SpInput/ExportsNationFraction",year) #[Fuel,Nation,NationX,Year]  Fraction to specify flows of Exports (Btu/Btu)
  ExpPurchases::VariableArray{1} = ReadDisk(db,"EGOutput/ExpPurchases",year) #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{1} = ReadDisk(db,"EGOutput/ExpSales",year) #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)
  FlowImports::VariableArray{3} = ReadDisk(db,"SpOutput/FlowImports",year) #[Fuel,Nation,NationX,Year]  Flows Estimated from Imports (TBtu/Yr)
  FlowExports::VariableArray{3} = ReadDisk(db,"SpOutput/FlowExports",year) #[Fuel,Nation,NationX,Year]  Flows Estimated from Exports (TBtu/Yr)
  FlowNation::VariableArray{3} = ReadDisk(db,"SpOutput/FlowNation",year) #[Fuel,Nation,NationX,Year]  Energy Flow to Nation from NationX (TBtu/Yr)
  GAProd::VariableArray{2} = ReadDisk(db,"SOutput/GAProd",year) #[Process,Area,Year]  Primary Gas Production (TBtu/Yr)
  GMarket::VariableArray{1} = ReadDisk(db,"SOutput/GMarket",year) #[Nation,Year]  Marketable Gas Production (TBtu/Yr)
  GProd::VariableArray{2} = ReadDisk(db,"SOutput/GProd",year) #[Process,Nation,Year]  Primary Gas Production (TBtu/Yr)
  Imports::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)
  ImportsArea::VariableArray{2} = ReadDisk(db,"SpOutput/ImportsArea",year) #[Fuel,Area,Year]  Imports of Energy (TBtu/Yr)
  ImportsAreaFraction::VariableArray{3} = ReadDisk(db,"SpInput/ImportsAreaFraction",year) #[Fuel,Area,Nation,Year]  Fraction to specify Area Flows of Imports (Btu/Btu)
  ImportsFuel::VariableArray{2} = ReadDisk(db,"SpOutput/ImportsFuel",year) #[Fuel,Nation,Year]  Primary Imports (TBtu/Yr)
  ImportsNationFraction::VariableArray{3} = ReadDisk(db,"SpInput/ImportsNationFraction",year) #[Fuel,Nation,NationX,Year]  Fraction to specify Flows of Imports (Btu/Btu)
  Inflow::VariableArray{3} = ReadDisk(db,"SpOutput/Inflow",year) #[Fuel,Area,Nation,Year]  Energy Flow to Area from Nation (TBtu/Yr)
  InflowFraction::VariableArray{2} = ReadDisk(db,"SpInput/InflowFraction",year) #[Fuel,Area,Year]  Domestic Inflow Fraction (Btu/Btu)
  OAProd::VariableArray{2} = ReadDisk(db,"SOutput/OAProd",year) #[Process,Area,Year]  Primary Oil Production (TBtu/Yr)
  OProd::VariableArray{2} = ReadDisk(db,"SOutput/OProd",year) #[Process,Nation,Year]  Primary Oil Production (TBtu/Yr)
  Outflow::VariableArray{3} = ReadDisk(db,"SpOutput/Outflow",year) #[Fuel,Area,Nation,Year]  Energy Outflow (TBtu/Yr)
  OutflowFraction::VariableArray{2} = ReadDisk(db,"SpInput/OutflowFraction",year) #[Fuel,Area,Year]  Domestic Outflow Fraction (Btu/Btu)
  ProdArea::VariableArray{2} = ReadDisk(db,"SpOutput/ProdArea",year) #[Fuel,Area,Year]  Energy Productions (TBtu/Yr)
  RPPADemand::VariableArray{1} = ReadDisk(db,"SpOutput/RPPADemand",year) #[Area,Year]  Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  RPPAdjustments::VariableArray{1} = ReadDisk(db,"SpOutput/RPPAdjustments",year) #[Nation,Year]  RPP Supply Adjustments (TBtu/Yr)
  RPPAProd::VariableArray{1} = ReadDisk(db,"SpOutput/RPPAProd",year) #[Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPExports::VariableArray{1} = ReadDisk(db,"SpOutput/RPPExports",year) #[Nation,Year]  Refined Petroleum Products (RPP) Exports (TBtu/Yr)
  RPPImports::VariableArray{1} = ReadDisk(db,"SpOutput/RPPImports",year) #[Nation,Year]  Refined Petroleum Products (RPP) Imports (TBtu/Yr)
  RPPProd::VariableArray{1} = ReadDisk(db,"SpOutput/RPPProd",year) #[Nation,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPProdArea::VariableArray{2} = ReadDisk(db,"SpOutput/RPPProdArea",year) #[Fuel,Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  SaEC::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",year) #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)
  SupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpOutput/SupplyAdjustments",year) #[FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)
  SurplusArea::VariableArray{2} = ReadDisk(db,"SpOutput/SurplusArea",year) #[Fuel,Area,Year]  Surplus Supply (TBtu/Yr)
  TDEF::VariableArray{2} = ReadDisk(db,"SInput/TDEF",year) #[Fuel,Area,Year]  T&D Efficiency (Btu/Btu)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)
  xInflow::VariableArray{3} = ReadDisk(db,"SpInput/xInflow",year) #[Fuel,Area,Nation,Year]  Historical Energy Inflow (TBtu/Yr)
  xOutflow::VariableArray{3} = ReadDisk(db,"SpInput/xOutflow",year) #[Fuel,Area,Nation,Year]  Historical Energy Outflow (TBtu/Yr)

  #
  # Scratch Variables
  #
  InflowEst::VariableArray{2} = zeros(Float32,length(Fuel),length(Area))   
  InflowTotal::VariableArray{2} = zeros(Float32,length(Fuel),length(Nation))
  OutflowEst::VariableArray{2} = zeros(Float32,length(Fuel),length(Area))
  OutflowTotal::VariableArray{2} = zeros(Float32,length(Fuel),length(Nation))
end

function AreaDemands(data::Data,fuels)
  (; db,year) = data
  (; Area,Areas,ECCs,Fuel,Fuels) = data 
  (; DmdArea,RPPAProd,TotDemand) = data
  (; RPPADemand) = data

  # @info "  SpImportsExports.jl - AreaDemands"

  for area in Areas, fuel in fuels
    DmdArea[fuel,area] = sum(TotDemand[fuel,ecc,area] for ecc in ECCs)
  end

  fuel = Select(Fuel,"LightCrudeOil")
  for area in Areas
    DmdArea[fuel,area] = RPPAProd[area]
  end

  #
  # RPP Demands are stored in Gasoline
  #
  fuel = Select(Fuel, "Gasoline")
  for area in Areas
    DmdArea[fuel,area] = RPPADemand[area]
  end

  WriteDisk(db,"SpOutput/DmdArea",year,DmdArea)

end

function AreaProduction(data::Data)
  (; db,year) = data
  (; Area,Areas,ECCs,Fuel,FuelEP,Nation,Nations,Plants,Process) = data 
  (; ANMap,AreaSales,AreaPurchases,CAProd) = data
  (; EAProd,GAProd,GMarket,GProd,OAProd,OProd) = data
  (; ProdArea,RPPAdjustments,RPPAProd,RPPProd) = data
  (; SaEC,SupplyAdjustments,TDEF) = data
  CProd::VariableArray{1} = zeros(Float32,length(Nation)) # Primary Coal Production (TBtu/Yr)
  Losses::VariableArray{1} = zeros(Float32,length(Area)) # Energy Losses (TBtu/Yr)
  Multiplier::VariableArray{1} = zeros(Float32,length(Area)) # Supply Adjustment Muliplier (Btu/Btu)
  TempSum::VariableArray{1} = zeros(Float32,length(Nation)) # Temporary Sum

  # @info "  SpImportsExports.jl - AreaProduction"

  #
  # Natural Gas
  #
  fuel = Select(Fuel,"NaturalGas")
  fuelep = Select(FuelEP,"NaturalGas")
  processes = Select(Process,["ConventionalGasProduction",
    "UnconventionalGasProduction","AssociatedGasProduction"])
    
  for nation in Nations
    TempSum[nation] = sum(GProd[process,nation] for process in processes)
  end

  for area in Areas
    @finite_math Multiplier[area] = sum((1+
      (GMarket[nation]-TempSum[nation]+SupplyAdjustments[fuelep,nation])/
      TempSum[nation])*ANMap[area,nation] for nation in Nations)

    ProdArea[fuel,area] = sum(GAProd[process,area] for process in processes)*Multiplier[area]
  end

  #
  # Crude Oil stored in "LightCrudeOil"
  #
  fuel = Select(Fuel,"LightCrudeOil")
  fuelep = Select(FuelEP,"CrudeOil")
  processes = Select(Process,["LightOilMining","HeavyOilMining","FrontierOilMining",
                              "PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining",
                              "PentanesPlus","Condensates"])
  for nation in Nations
    TempSum[nation] = sum(OProd[process,nation] for process in processes)
  end

  for area in Areas
    @finite_math Multiplier[area] = sum((1+SupplyAdjustments[fuelep,nation]/
      TempSum[nation])*ANMap[area,nation] for nation in Nations)

    ProdArea[fuel,area] = sum(OAProd[process,area] for process in processes)*Multiplier[area]
  end

  #
  # Coal
  #
  fuel = Select(Fuel,"Coal")
  fuelep = Select(FuelEP,"Coal")
  for nation in Nations
    CProd[nation] = sum(CAProd[area]*ANMap[area,nation] for area in Areas)
  end
  for area in Areas
    @finite_math Multiplier[area] = sum((1+SupplyAdjustments[fuelep,nation]/
                                    CProd[nation])*ANMap[area,nation] for nation in Nations)

    ProdArea[fuel,area] = CAProd[area]*Multiplier[area]
  end

  #
  # RPP Production stored in Gasoline
  #
  fuel = Select(Fuel,"Gasoline")
  for area in Areas
    @finite_math Multiplier[area] = sum((1+RPPAdjustments[nation]/
      RPPProd[nation])*ANMap[area,nation] for nation in Nations)
      
    ProdArea[fuel,area] = RPPAProd[area]*Multiplier[area]
  end

  #
  # Electricity
  #
  fuel = Select(Fuel,"Electric")
  for area in Areas
    Losses[area] = (sum(SaEC[ecc,area]*(1/TDEF[fuel,area]-1) for ecc in ECCs)+
                  AreaSales[area]-AreaPurchases[area])*3412/1e6

    ProdArea[fuel,area] = sum(EAProd[plant,area]*3412/1e6 for plant in Plants)-Losses[area]
  end

  WriteDisk(db,"SpOutput/ProdArea",year,ProdArea)

end

function ImportsExportsByFuel(data::Data)
  (; db,year) = data
  (; Area,Areas,Fuel,FuelEP,Nations) = data 
  (; ANMap,ExpPurchases,Exports,ExportsFuel,ExpSales,Imports,ImportsFuel,RPPExports,RPPImports) = data

  # @info "  SpImportsExports.jl - ImportsExportsByFuel"

  fuel = Select(Fuel,"LightCrudeOil")
  fuelep = Select(FuelEP,"CrudeOil")
  for nation in Nations
    ImportsFuel[fuel,nation] = Imports[fuelep,nation]
    ExportsFuel[fuel,nation] = Exports[fuelep,nation]
  end

  fuel = Select(Fuel,"NaturalGas")
  fuelep = Select(FuelEP,"NaturalGas")
  for nation in Nations
    ImportsFuel[fuel,nation] = Imports[fuelep,nation]
    ExportsFuel[fuel,nation] = Exports[fuelep,nation]
  end

  fuel = Select(Fuel,"Coal")
  fuelep = Select(FuelEP,"Coal")
  for nation in Nations
    ImportsFuel[fuel,nation] = Imports[fuelep,nation]
    ExportsFuel[fuel,nation] = Exports[fuelep,nation]
  end

  fuel = Select(Fuel,"Gasoline")
  for nation in Nations
    ImportsFuel[fuel,nation] = RPPImports[nation]
    ExportsFuel[fuel,nation] = RPPExports[nation]
  end

  fuel = Select(Fuel,"Electric")
  for nation in Nations
    ImportsFuel[fuel,nation] = sum(ExpPurchases[area]*ANMap[area,nation] for area in Areas)*3412/1e6
    ExportsFuel[fuel,nation] = sum(ExpSales[area]*ANMap[area,nation] for area in Areas)*3412/1e6
  end

  WriteDisk(db,"SpOutput/ExportsFuel",year,ExportsFuel)
  WriteDisk(db,"SpOutput/ImportsFuel",year,ImportsFuel)

end

function NationalFlow(data::Data,fuels)
  (; db,year) = data
  (; Fuel,Fuels,Nation,Nations,NationX,NationXs) = data 
  (; ExportsFuel,ExportsNationFraction,FlowImports,FlowExports,FlowNation,ImportsFuel,ImportsNationFraction) = data
  
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  MX = Select(Nation,"MX")
  ROW = Select(Nation,"ROW")

  for nationx in NationXs, nation in Nations, fuel in fuels
    
    FlowImports[fuel,nation,nationx] = ImportsFuel[fuel,nation]*
      ImportsNationFraction[fuel,nation,nationx]
      
    FlowExports[fuel,nation,nationx] = ExportsFuel[fuel,nationx]*
      ExportsNationFraction[fuel,nation,nationx]
  
  end

  #
  # Forecast of Nation Flows
  #
  for nationx in NationXs, nation in Nations, fuel in fuels
    FlowNation[fuel,nation,nationx] = min(FlowImports[fuel,nation,nationx],FlowExports[fuel,nation,nationx])
  end

  #
  # Forecast of ROW Flows
  #
  for fuel in fuels
    FlowNation[fuel,US,ROW] = ImportsFuel[fuel,US]-FlowNation[fuel,US,CN]-FlowNation[fuel,US,MX]
    FlowNation[fuel,CN,ROW] = ImportsFuel[fuel,CN]-FlowNation[fuel,CN,US]-FlowNation[fuel,CN,MX]
    FlowNation[fuel,MX,ROW] = ImportsFuel[fuel,MX]-FlowNation[fuel,MX,US]-FlowNation[fuel,MX,CN]

    FlowNation[fuel,ROW,US] = ExportsFuel[fuel,US]-FlowNation[fuel,CN,US]-FlowNation[fuel,MX,US]
    FlowNation[fuel,ROW,CN] = ExportsFuel[fuel,CN]-FlowNation[fuel,US,CN]-FlowNation[fuel,MX,CN]
    FlowNation[fuel,ROW,MX] = ExportsFuel[fuel,MX]-FlowNation[fuel,US,MX]-FlowNation[fuel,CN,MX]
  end

  WriteDisk(db,"SpOutput/FlowExports",year,FlowExports)
  WriteDisk(db,"SpOutput/FlowImports",year,FlowImports)
  WriteDisk(db,"SpOutput/FlowNation",year,FlowNation)

end

function ROWImportsExports(data::Data,fuels)
  (; db,year) = data
  (; Fuel,FuelEP,Nation) = data 
  (; Exports,ExportsFuel,FlowNation,Imports,ImportsFuel,RPPExports,RPPImports) = data

  CoreNations = Select(Nation,["US","CN","MX"])
  ROW = Select(Nation,"ROW")

  for fuel in fuels
    ImportsFuel[fuel,ROW] = sum(FlowNation[fuel,ROW,nationx] for nationx in CoreNations)
    ExportsFuel[fuel,ROW] = sum(FlowNation[fuel,nation,ROW] for nation in CoreNations)
  end

  fuel = Select(Fuel,"LightCrudeOil")
  fuelep = Select(FuelEP,"CrudeOil")
  Imports[fuelep,ROW] = sum(FlowNation[fuel,ROW,nationx] for nationx in CoreNations)
  Exports[fuelep,ROW] = sum(FlowNation[fuel,nation,ROW] for nation in CoreNations)

  fuel = Select(Fuel,"NaturalGas")
  fuelep = Select(FuelEP,"NaturalGas")
  Imports[fuelep,ROW] = sum(FlowNation[fuel,ROW,nationx] for nationx in CoreNations)
  Exports[fuelep,ROW] = sum(FlowNation[fuel,nation,ROW] for nation in CoreNations)

  fuel = Select(Fuel,"Coal")
  fuelep = Select(FuelEP,"Coal")
  Imports[fuelep,ROW] = sum(FlowNation[fuel,ROW,nationx] for nationx in CoreNations)
  Exports[fuelep,ROW] = sum(FlowNation[fuel,nation,ROW] for nation in CoreNations)

  fuel = Select(Fuel,"Gasoline")
  fuelep = Select(FuelEP,"Gasoline")
  Imports[fuelep,ROW] = sum(FlowNation[fuel,ROW,nationx] for nationx in CoreNations)
  RPPImports[ROW] = sum(FlowNation[fuel,ROW,nationx] for nationx in CoreNations)
  Exports[fuelep,ROW] = sum(FlowNation[fuel,nation,ROW] for nation in CoreNations)
  RPPExports[ROW] = sum(FlowNation[fuel,nation,ROW] for nation in CoreNations)

  WriteDisk(db,"SpOutput/Exports",year,Exports)
  WriteDisk(db,"SpOutput/ExportsFuel",year,ExportsFuel)
  WriteDisk(db,"SpOutput/Imports",year,Imports)
  WriteDisk(db,"SpOutput/ImportsFuel",year,ImportsFuel)
  WriteDisk(db,"SpOutput/RPPImports",year,RPPImports)
  WriteDisk(db,"SpOutput/RPPExports",year,RPPExports)

end

function InternationalAreaFlow(data::Data,fuels)
  (; db,year) = data
  (; Areas,Fuel,Fuels,Nation,Nations,NationX) = data 
  (; ANMap,ExportsAreaFraction,FlowNation,Inflow,ImportsAreaFraction,Outflow) = data

  for nation in Nations
    areas = findall(ANMap[Areas,nation] .== 1)
    NationNum = nation
    OtherNum = 1
    while OtherNum < 5
      if OtherNum != NationNum
        
        for area in areas, fuel in fuels
          Inflow[fuel,area,OtherNum] = FlowNation[fuel,NationNum,OtherNum]*
            ImportsAreaFraction[fuel,area,OtherNum]
        end
        
        
        for area in areas, fuel in fuels       
          Outflow[fuel,area,OtherNum] = FlowNation[fuel,OtherNum,NationNum]*
            ExportsAreaFraction[fuel,area,OtherNum]
        end
      end
      OtherNum = OtherNum+1
    end
  end

  WriteDisk(db,"SpOutput/Inflow",year,Inflow)
  WriteDisk(db,"SpOutput/Outflow",year,Outflow)
end

function AreaImportsExports(data::Data,fuels)
  (; db,year) = data
  (; Areas,Fuels,Nations) = data
  (; ANMap,ExportsArea,Inflow,ImportsArea,Outflow) = data

  for area in Areas
    nations = findall(ANMap[area,Nations] .== 0)

    for nation in nations, fuel in fuels 
      ImportsArea[fuel,area] = sum(Inflow[fuel,area,nation] for nation in nations)
    end
    
    for nation in nations, fuel in fuels    
      ExportsArea[fuel,area] = sum(Outflow[fuel,area,nation] for nation in nations)
    end
  
  end
  
  # areas = Select(Area,["ON","NEng","MX"])
  # for area in areas, fuel in fuels
  #   othernations = findall(ANMap[area,:] .== 0)
  #   ImportsArea[fuel,area] = sum(Inflow[fuel,area,nation] for nation in othernations)
  #   ExportsArea[fuel,area] = sum(Outflow[fuel,area,nation] for nation in othernations)
  # end

  WriteDisk(db,"SpOutput/ImportsArea",year,ImportsArea)
  WriteDisk(db,"SpOutput/ExportsArea",year,ExportsArea)
end

function InternalFlows(data::Data,fuels)
  (; db,year) = data
  (; Areas,Fuel,Nation,Nations) = data 
  (; ANMap,DmdArea,ExportsArea,Inflow,InflowFraction,ImportsArea,Outflow,OutflowFraction,ProdArea,SurplusArea) = data
  (; InflowEst,OutflowEst,InflowTotal,OutflowTotal) = data


  for nation in Nations, fuel in fuels
    areas = findall(ANMap[Areas,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1
      
        if Nation[nation] == "CN"
          InflowEst[fuel,area] = DmdArea[fuel,area]*InflowFraction[fuel,area]
          OutflowEst[fuel,area] = ProdArea[fuel,area]*OutflowFraction[fuel,area]
        else
          InflowEst[fuel,area] = max(DmdArea[fuel,area]-ProdArea[fuel,area]-
            ImportsArea[fuel,area]+ExportsArea[fuel,area],
            DmdArea[fuel,area]*InflowFraction[fuel,area])
            
          OutflowEst[fuel,area] = ProdArea[fuel,area]-DmdArea[fuel,area]+
            ImportsArea[fuel,area]-ExportsArea[fuel,area]+InflowEst[fuel,area]
        end
      end
    end
    
    InflowTotal[fuel,nation] = sum(InflowEst[fuel,area] for area in areas)
    OutflowTotal[fuel,nation] = sum(OutflowEst[fuel,area] for area in areas)
    
    for area in areas
      if ANMap[area,nation] == 1
        Inflow[fuel,area,nation] = InflowEst[fuel,area]
        
        @finite_math Outflow[fuel,area,nation] = 
          OutflowEst[fuel,area]*InflowTotal[fuel,nation]/OutflowTotal[fuel,nation]
          
        SurplusArea[fuel,area] = ProdArea[fuel,area]-DmdArea[fuel,area]+
          ImportsArea[fuel,area]-ExportsArea[fuel,area]+
          Inflow[fuel,area,nation]-Outflow[fuel,area,nation]
          
      end
    end
  end

  WriteDisk(db,"SpOutput/Inflow",year,Inflow)
  WriteDisk(db,"SpOutput/Outflow",year,Outflow)
  WriteDisk(db,"SpOutput/SurplusArea",year,SurplusArea)
end

function Control(data::Data)
  (; Fuel) = data 
  
  # @info "  SpImportsExports.jl - Control"
  
  fuels = Select(Fuel,["NaturalGas","Coal","Gasoline","LightCrudeOil","Electric"])

  AreaDemands(data,fuels)
  AreaProduction(data)
  ImportsExportsByFuel(data)
  NationalFlow(data,fuels)
  ROWImportsExports(data,fuels)
  InternationalAreaFlow(data,fuels)
  AreaImportsExports(data,fuels)
  InternalFlows(data,fuels)

end # function Control

end # module SpImportsExports
