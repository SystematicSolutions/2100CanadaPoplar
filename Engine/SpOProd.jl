#
# SpOProd.jl
#

module SpOProd

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime
import ...EnergyModel: @finite_math,finite_divide

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
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  CNAreas::Vector{Int} = collect(Select(CNArea)) 
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")

  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market)) 

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation)) 
  
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year) #[Area,Market,Year]  Areas included in Market
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") #[Area,CNArea]  Map between Area and Canada Economic Areas (CNArea)
  ECCMarket::VariableArray{2} = ReadDisk(db,"SInput/ECCMarket",year) #[ECC,Market,Year]  Economic Categories included in Market
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year]  Primary Fuel Price ($/mmBtu)
  ENPNNext::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",next) #[Fuel,Nation,Year]  Primary Fuel Price ($/mmBtu)
  Exports::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  ExportsMin::VariableArray{2} = ReadDisk(db,"SpInput/ExportsMin",year) #[FuelEP,Nation,Year]  Exports Minimum (TBtu/Yr)
  GOMult::VariableArray{2} = ReadDisk(db,"SOutput/GOMult",year) #[ECC,Area,Year]  Gross Output Multiplier ($/$)
  GPOPrSw::VariableArray{1} = ReadDisk(db,"SInput/GPOPrSw",year) #[Market,Year]  Oil Production Intensity based Gratis Permits (2=Intensity)
  Imports::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)
  ImportsMin::VariableArray{2} = ReadDisk(db,"SpInput/ImportsMin",year) #[FuelEP,Nation,Year]  Imports Minimum (TBtu/Yr)
  InflationNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) #[Nation,Year]  Inflation Index ($/$)
  OAPrEOR::VariableArray{2} = ReadDisk(db,"SOutput/OAPrEOR",prior) #[Process,Area,Prior]  Oil Production from EOR (TBtu/Yr)
  OAProd::VariableArray{2} = ReadDisk(db,"SOutput/OAProd",year) #[Process,Area,Year]  Primary Oil Production (TBtu/Yr)
  OIPElas::Float32 = ReadDisk(db,"SpInput/OIPElas",year) #[Year]  Oil Import Price Elasticity
  OIPSw::Float32 = ReadDisk(db,"SpInput/OIPSw",year) #[Year]  Oil Import Price Switch
  OProd::VariableArray{2} = ReadDisk(db,"SOutput/OProd",year) #[Process,Nation,Year]  Primary Oil Production (TBtu/Yr)
  OProdPrior::VariableArray{2} = ReadDisk(db,"SOutput/OProd",prior) #[Process,Nation,Prior]  Primary Oil Production in Prior (TBtu/Yr)
  OPrTax::VariableArray{2} = ReadDisk(db,"SpOutput/OPrTax",year) #[Process,Nation,Year]  Oil Production Tax ($/mmBtu)
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost ($/Tonne)
  PGratis::VariableArray{4} = ReadDisk(db,"SOutput/PGratis",year) #[ECC,Poll,PCov,Area,Year]  Gratis Permits (Tonnes/Yr)
  PolCov::VariableArray{4} = ReadDisk(db,"SOutput/PolCov",year) #[ECC,Poll,PCov,Area,Year]  Total Covered Pollution (Tonnes/Yr)
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) #[Poll,Market,Year]  Pollutants included in Market
  RPPProd::VariableArray{1} = ReadDisk(db,"SpOutput/RPPProd",year) #[Nation,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  SqPExp::VariableArray{2} = ReadDisk(db,"SOutput/SqPExp",year) #[ECC,Area,Year]  Sequestering Private Expenses (M$/Yr)
  SupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpOutput/SupplyAdjustments",year) #[FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)
  VnPExp::VariableArray{2} = ReadDisk(db,"SOutput/VnPExp",year) #[ECC,Area,Year]  Venting Reduction Private Expenses (M$/Yr)
  xENPN::VariableArray{2} = ReadDisk(db,"SInput/xENPN",year) #[Fuel,Nation,Year]  Exogenous Primary Fuel Price ($/mmBtu)
  xENPNNext::VariableArray{2} = ReadDisk(db,"SInput/xENPN",next) #[Fuel,Nation,Year]  Exogenous Primary Fuel Price ($/mmBtu)
  xExports::VariableArray{2} = ReadDisk(db,"SpInput/xExports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  xImports::VariableArray{2} = ReadDisk(db,"SpInput/xImports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)
  xOAProd::VariableArray{2} = ReadDisk(db,"SInput/xOAProd",year) #[Process,Area,Year]  Oil Production (TBtu/Yr)
  xSupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpInput/xSupplyAdjustments",year) #[FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)

  KJBtu::Float32 = 1.054615
end

#
########################
#
function ImpExpOil(data::Data)
  (; db,year,CTime) = data
  (; FuelEP,Nation,Nations,Process) = data #sets
  (; Exports,ExportsMin,Imports,ImportsMin,OProd,RPPProd,SupplyAdjustments,xExports,xImports,xSupplyAdjustments) = data 
  TProd::VariableArray{1} = zeros(Float32,length(Nation))
  # @info "  SpOProd.jl - Oil Imports and Exports"

  for nation in Nations

    #
    # Crude Oil Imports and Exports
    #
    Crude = Select(FuelEP,"CrudeOil")

    #
    # Total Production excludes Oil Sands Upgraders
    #
    OilProcess = Select(Process,["LightOilMining","HeavyOilMining","FrontierOilMining",
               "PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining",
               "PentanesPlus","Condensates"])
    TProd[nation] = sum(OProd[process,nation] for process in OilProcess)

    #
    # Supply Adjustments
    #
    if CTime <= HisTime
        SupplyAdjustments[Crude,nation] = RPPProd[nation]+xExports[Crude,nation]-
                                        TProd[nation]-xImports[Crude,nation]
    else
      SupplyAdjustments[Crude,nation] = xSupplyAdjustments[Crude,nation]
    end

    #
    # Crude Oil Imports 
    #
    Imports[Crude,nation] = ImportsMin[Crude,nation]+max(RPPProd[nation]-TProd[nation]-
            ImportsMin[Crude,nation]+ExportsMin[Crude,nation]-SupplyAdjustments[Crude,nation],0) 

    # 
    #  Crude Oil Exports
    # 
    Exports[Crude,nation] = ExportsMin[Crude,nation]+max(TProd[nation]-RPPProd[nation]+
            Imports[Crude,nation]-ExportsMin[Crude,nation]+SupplyAdjustments[Crude,nation],0)

  end # do Nation

  WriteDisk(db,"SpOutput/Exports",year,Exports)
  WriteDisk(db,"SpOutput/Imports",year,Imports)
  WriteDisk(db,"SpOutput/SupplyAdjustments",year,SupplyAdjustments)
  
end

#
########################
#
function EcoOil(data::Data)
  (; db,year) = data
  (; ECC,ECCs,Nation,Process) = data #sets
  (; ANMap,GOMult,OAPrEOR,OAProd,xOAProd) = data 
 # @info "  SpOProd.jl - EcoOil - Economic Multipliers for Oil Supply"

  CN = Select(Nation,"CN")
  AreaCN = findall(ANMap[:,CN] .== 1)
  if !isempty(AreaCN)
    for area in AreaCN
      #
      # Loop through all Oil Mining Sectors (Process, ECC)
      #
      OilProcess = Select(Process,(from = "LightOilMining",to = "OilSandsUpgraders"))
      for process in OilProcess, ecc in ECCs
        if Process[process] == ECC[ecc]
          if xOAProd[process,area] > 0.0
    
            GOMult[ecc,area] = (OAProd[process,area]-OAPrEOR[process,area])/xOAProd[process,area]
      
          end
        end
      end
    end
  end

  WriteDisk(db,"SOutput/GOMult",year,GOMult)

end
#
########################
#
function OilPrice(data::Data)

  # @info "  SpOProd.jl - Oil Price Supply"
  (; db,year,next) = data;
  (; Areas,ECC,ECCs,Fuel,FuelEP,Markets,Nation,Nations) = data;
  (; PCovs,Process,Processes) = data; #sets
  (; ANMap,AreaMarket,ECCMarket,ENPNNext,GPOPrSw,OIPSw,OPrTax,PCost,PGratis) = data;
  (; PolCov,PollMarket,OProdPrior,SqPExp,VnPExp,xENPNNext,xImports) = data;
  HeavyCrudeOil = Select(Fuel,"HeavyCrudeOil")
  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  CrudeOil = Select(FuelEP,"CrudeOil")
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  #
  # Oil Production Taxes
  #
  @. OPrTax = 0.0

  for market in Markets
    for nation in Nations
      AreaMkt = findall(AreaMarket[:,market] .== 1)
      PollMkt = findall(PollMarket[:,market] .== 1)
      if (!isempty(AreaMkt)) && (!isempty(PollMkt))
        for process in Processes, ecc in ECCs
          if (Process[process] == ECC[ecc]) && (ECCMarket[ecc,market] == 1)

            #
            # Gratis Permits do not depend on production so the full permit cost
            # is included in the marginal production cost and the oil tax.
            #
            if GPOPrSw[market] == 1.0
              @finite_math OPrTax[process,nation] = OPrTax[process,nation]+
                sum(PolCov[ecc,poll,pcov,area]*
                PCost[ecc,poll,area] for area in AreaMkt, pcov in PCovs, poll in PollMkt)/
                OProdPrior[process,nation]/1e6 

          # 
          # Gratis permits are intensity based and depend on the level of production so
          # the marginal production costs includes the value of the gratis permits and
          # are included in the oil tax.
          # 
            else GPOPrSw[market] == 2.0 
              @finite_math OPrTax[process,nation] = OPrTax[process,nation]+
                sum((PolCov[ecc,poll,pcov,area]-PGratis[ecc,poll,pcov,area])*
                PCost[ecc,poll,area] for area in AreaMkt, pcov in PCovs, poll in PollMkt)/
                OProdPrior[process,nation]/1e6
              
            end # if GPOPrSw  
          end # if Process
        end # for Process
      end # if AreaMkt
    end # for Nation
  end # for Market
  
  # 
  # Add in the cost of sequestering and venting capture as if it was a tax.
  # Jeff Amlin 12/1/13
  #
  for nation in Nations, process in Processes, ecc in ECCs
    if Process[process] == ECC[ecc]
      @finite_math OPrTax[process,nation] = OPrTax[process,nation]+
        sum((SqPExp[ecc,area]+VnPExp[ecc,area])*ANMap[area,nation] for area in Areas)/
        OProdPrior[process,nation]
    end # if Process
  end # for Nation
  WriteDisk(db,"SpOutput/OPrTax",year,OPrTax)

  #
  # Rest of World oil imports are two times US imports
  #
  ROWImport = 2*xImports[CrudeOil,US]
  
  #
  # Primary Oil Prices (ENPN) are OPEC prices and are a function of
  # US (Import) and ROW (ROWImport) oil imports.
  #
  if OIPSw == 1
    for nation in Nations
      xENPNNext[LightCrudeOil,nation] = xENPNNext[LightCrudeOil,nation]*
        ((Imports[Crude,US]+ROWImport)/(xImports[CrudeOil,US]+ROWImport))^OIPElas 
      xENPNNext[HeavyCrudeOil,nation] = xENPNNext[HeavyCrudeOil,nation]
    end
  else   
    for nation in Nations
      xENPNNext[LightCrudeOil,nation] = xENPNNext[LightCrudeOil,nation]
      xENPNNext[HeavyCrudeOil,nation] = xENPNNext[HeavyCrudeOil,nation]  
    end
  end

  #
  # Adjust Oil Related Prices
  #
  LightOils = Select(Fuel,
    ["Asphalt","AviationGasoline","Diesel","Ethanol","Gasoline","JetFuel",
    "Kerosene","LFO","Lubricants","Naphtha","NonEnergy","PetroFeed",
    "PetroCoke","StillGas"])
  
  for nation in Nations, fuel in LightOils
    ENPNNext[fuel,nation] = xENPNNext[fuel,nation]*
                          ENPNNext[LightCrudeOil,nation]/xENPNNext[LightCrudeOil,nation]
  end

  HeavyOils = Select(Fuel,"HFO")
  for nation in Nations, fuel in HeavyOils
    ENPNNext[fuel,nation] = xENPNNext[fuel,nation]*
                          ENPNNext[HeavyCrudeOil,nation]/xENPNNext[HeavyCrudeOil,nation]
  end
  
  WriteDisk(db,"SOutput/ENPN",next,ENPNNext)
  
end # function OilPrice

function Control(data::Data)
  # @info "  SpOProd.jl - Control"

  ImpExpOil(data)
  EcoOil(data)

end # function Control

end # module SpOProd
