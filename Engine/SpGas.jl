#
# SpGas.jl
#

module SpGas

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

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
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodes::Vector{Int} = collect(Select(GNode))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year) #[Area,Market,Year]  Areas included in Market
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") #[Area,CNArea]  Map between Area and Canada Economic Areas (CNArea)
  ENPNNext::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",next) #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  ENPNRef::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year]  Wholesale Price in Reference Case ($/mmBtu)
  ETAPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAPr",year) #[Market,Year]  Cost of Emission Trading Allowances (US$/Tonne)
  ETAvPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAvPr",year) #[Market,Year]  Average Cost of Emission Trading Allowances (US$/Tonne)
  ExchangeRate::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",year) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  Exports::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  ExportsMin::VariableArray{2} = ReadDisk(db,"SpInput/ExportsMin",year) #[FuelEP,Nation,Year]  Exports Minimum (TBtu/Yr)
  ExportsPipeline::VariableArray{1} = ReadDisk(db,"SOutput/ExportsPipeline",year) #[Nation,Year]  Natural Gas Exports by Pipeline (TBtu/Yr)
  ExportsRef::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) #[FuelEP,Nation,Year]  Primary Exports in Reference Case (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FlGProd::VariableArray{1} = ReadDisk(db,"SOutput/FlGProd",year) #[Nation,Year]  Natural Gas Produced from Flaring Reductions (TBtu/Yr)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FPDChgF::VariableArray{3} = ReadDisk(db,"SCalDB/FPDChgF",year) #[Fuel,ES,Area,Year]  Fuel Delivery Charge (Real $/mmBtu)
  FPGNode::VariableArray{2} = ReadDisk(db,"SpOutput/FPGNode",year) #[GNode,Month,Year]  Natural Gas Transmission Node Price ($/mmBtu)
  FPMarginF::VariableArray{3} = ReadDisk(db,"SInput/FPMarginF",year) #[Fuel,ES,Area,Year]  Refinery/Distributor Margin ($/$)
  FPPolTaxF::VariableArray{3} = ReadDisk(db,"SOutput/FPPolTaxF",year) #[Fuel,ES,Area,Year]  Pollution Tax (Real $/mmBtu)
  FPSMF::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",year) #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPTaxF::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",year) #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  FuGProd::VariableArray{1} = ReadDisk(db,"SOutput/FuGProd",year) #[Nation,Year]  Natural Gas Produced from Other Fugitives Reductions (TBtu/Yr)
  GADemand::VariableArray{1} = ReadDisk(db,"SpOutput/GADemand",year) #[Area,Year]  Natural Gas Demand (TBtu/Yr)
  GAProd::VariableArray{2} = ReadDisk(db,"SOutput/GAProd",year) #[Process,Area,Year]  Primary Gas Production (TBtu/Yr)
  GARaw::VariableArray{1} = ReadDisk(db,"SpOutput/GARaw",year) #[Area,Year]  Raw Natural Gas Demand (TBtu/Yr)
  GasProductionMap::VariableArray{1} = ReadDisk(db,"SpInput/GasProductionMap") #[Process]  Gas Production Map (1=include)
  GDemand::VariableArray{1} = ReadDisk(db,"SOutput/GDemand",year) #[Nation,Year]  Natural Gas Demand (TBtu/Yr)
  GDemandPrior::VariableArray{1} = ReadDisk(db,"SOutput/GDemand",prior) #[Nation,Year]  Natural Gas Demand (TBtu/Yr)
  GDemandRef::VariableArray{1} = ReadDisk(db,"SOutput/GDemand",year) #[Nation,Year]  Natural Gas Demand in Reference Case (TBtu/Yr)
  GLosses::VariableArray{1} = ReadDisk(db,"SOutput/GLosses",year) #[Nation,Year]  Natural Gas Losses (TBtu/Yr)
  GMarket::VariableArray{1} = ReadDisk(db,"SOutput/GMarket",year) #[Nation,Year]  Marketable Gas Production (TBtu/Yr)
  GMarketRef::VariableArray{1} = ReadDisk(db,"SOutput/GMarket",year) #[Nation,Year]  Marketable Gas Production in Reference Case (TBtu/Yr)
  GMMult::VariableArray{1} = ReadDisk(db,"SInput/GMMult",year) #[Nation,Year]  Marketable Gas Production Multiplier (TBtu/TBtu)
  GOMult::VariableArray{2} = ReadDisk(db,"SOutput/GOMult",year) #[ECC,Area,Year]  Gross Output Multiplier ($/$)
  GPGDist::VariableArray{2} = ReadDisk(db,"SOutput/GPGDist",year) #[Area,Market,Year]  Gas Distribution Company Gratis Permits (Tonnes)
  GPGPrSw::VariableArray{1} = ReadDisk(db,"SInput/GPGPrSw",year) #[Market,Year]  Gas Production Intensity based Gratis Permits (2=Intensity)
  GPGPrSwNext::VariableArray{1} = ReadDisk(db,"SInput/GPGPrSw",next) #[Market,Year]  Gas Production Intensity based Gratis Permits (2=Intensity)
  GPNGSw::VariableArray{1} = ReadDisk(db,"SInput/GPNGSw",year) #[Market,Year]  Gratis Permit Allocation Switch for Gas Distribution
  GPolDist::VariableArray{2} = ReadDisk(db,"SOutput/GPolDist",year) #[Area,Market,Year]  Pollution from Gas which is Distributed (Tonnes)
  GProd::VariableArray{2} = ReadDisk(db,"SOutput/GProd",year) #[Process,Nation,Year]  Primary Gas Production (TBtu/Yr)
  GPrTax::VariableArray{1} = ReadDisk(db,"SpOutput/GPrTax",year) #[Nation,Year]  Natural Gas Production Tax ($/mmBtu)
  GPrTaxNext::VariableArray{1} = ReadDisk(db,"SpOutput/GPrTax",next) #[Nation,Year]  Natural Gas Production Tax ($/mmBtu)
  GRaw::VariableArray{1} = ReadDisk(db,"SOutput/GRaw",year) #[Nation,Year]  Raw Natural Gas Demand (TBtu/Yr)
  GRqDemand::VariableArray{2} = ReadDisk(db,"SpOutput/GRqDemand",year) #[GNode,Month,Year]  Natural Gas Required to Meet Demands (TBtu/Month)
  GSM::VariableArray{2} = ReadDisk(db,"SpOutput/GSM",year) #[Process,Nation,Year]  Gas Supply Multiplier from Price Changes
  GSMRef::VariableArray{2} = ReadDisk(db,"SpOutput/GSM",year) #[Process,Nation,Year]  Gas Supply Multiplier from Price Changes in Reference Case
  GSPElas::Float32 = ReadDisk(db,"SpInput/GSPElas",year) #[Year]  Gas Supply Elasticity to Change Prices
  GSPM::Float32 = ReadDisk(db,"SpOutput/GSPM",year) #[Year]  Gas Price Multiplier from Supply Changes ($/$)
  GSPMNext::Float32 = ReadDisk(db,"SpOutput/GSPM",next) #[Year]  Gas Price Multiplier from Supply Changes ($/$)
  GSPMPrior::Float32 = ReadDisk(db,"SpOutput/GSPM",prior) #[Year]  Gas Price Multiplier from Supply Changes ($/$)
  GSPMSw::Float32 = ReadDisk(db,"SpInput/GSPMSw",year) #[Year]  Gas Price Multiplier from Supply Changes Switch
  GSPMSwNext::Float32 = ReadDisk(db,"SpInput/GSPMSw",next) #[Year]  Gas Price Multiplier from Supply Changes Switch
  Imports::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)
  ImportsMin::VariableArray{2} = ReadDisk(db,"SpInput/ImportsMin",year) #[FuelEP,Nation,Year]  Imports Minimum (TBtu/Yr)
  ImportsRef::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) #[FuelEP,Nation,Year]  Primary Imports in Reference Case (TBtu/Yr)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) #[Nation,Year]  Inflation Index ($/$)
  InflationNationNext::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",next) #[Nation,Year]  Inflation Index ($/$)
  LNGAProd::VariableArray{1} = ReadDisk(db,"SOutput/LNGAProd",year) #[Area,Year]  Liquid Natural Gas Production (TBtu/Yr)
  LNGProd::VariableArray{1} = ReadDisk(db,"SOutput/LNGProd",year) #[Nation,Year]  LNG Production (TBtu/Yr)
  LNGProdMin::VariableArray{1} = ReadDisk(db,"SOutput/LNGProdMin",year) #[Nation,Year]  Minimum LNG Production (TBtu/Yr)
  OGCode::Vector{String} = ReadDisk(db,"MainDB/OGCode")
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost ($/Tonne)
  PCostNext::VariableArray{3} = ReadDisk(db,"SOutput/PCost",next) #[ECC,Poll,Area,Year]  Permit Cost ($/Tonne)
  Pd::VariableArray{1} = ReadDisk(db,"SpOutput/Pd",year) #[OGUnit,Year]  Production (TBtu/Yr)
  PGratis::VariableArray{4} = ReadDisk(db,"SOutput/PGratis",year) #[ECC,Poll,PCov,Area,Year]  Gratis Permits (Tonnes/Yr)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PolCov::VariableArray{4} = ReadDisk(db,"SOutput/PolCov",year) #[ECC,Poll,PCov,Area,Year]  Total Covered Pollution (Tonnes/Yr)
  PolCovPrior::VariableArray{4} = ReadDisk(db,"SOutput/PolCov",prior) #[ECC,Poll,PCov,Area,Year]  Total Covered Pollution (Tonnes/Yr)
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) #[Poll,Market,Year]  Pollutants included in Market
  RefSwitch::Float32 = ReadDisk(db,"SInput/RefSwitch")[1] #[tv] Reference Case Switch (1=Reference Case) 
  SupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpOutput/SupplyAdjustments",year) #[FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)
  TProd::VariableArray = zeros(Float32,length(Nation))
  VnGProd::VariableArray{1} = ReadDisk(db,"SOutput/VnGProd",year) #[Nation,Year]  Natural Gas Produced from Venting Reductions (TBtu/Yr)
  xENPN::VariableArray{2} = ReadDisk(db,"SInput/xENPN",year) #[Fuel,Nation,Year]  Exogenous Price Normal ($/mmBtu)
  xENPNNext::VariableArray{2} = ReadDisk(db,"SInput/xENPN",next) #[Fuel,Nation,Year]  Exogenous Price Normal ($/mmBtu)
  xExports::VariableArray{2} = ReadDisk(db,"SpInput/xExports",year) #[FuelEP,Nation,Year]  Primary Exports (TBtu/Yr)
  xGAProd::VariableArray{2} = ReadDisk(db,"SInput/xGAProd",year) #[Process,Area,Year]  Natural Gas Production (TBtu/Yr)
  xGProd::VariableArray{2} = ReadDisk(db,"SInput/xGProd",year) #[Process,Nation,Year]  Primary Gas Production (TBtu/Yr)
  xGProdRef::VariableArray{2} = ReadDisk(db,"SInput/xGProd",year) #[Process,Nation,Year]  Primary Gas Production in Reference Case (TBtu/Yr)
  xImports::VariableArray{2} = ReadDisk(db,"SpInput/xImports",year) #[FuelEP,Nation,Year]  Primary Imports (TBtu/Yr)
  xPGratis::VariableArray{4} = ReadDisk(db,"SInput/xPGratis",year) #[ECC,Poll,PCov,Area,Year]  Exogenous Gratis Permits (Tonnes/Yr)
  xSupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpInput/xSupplyAdjustments",year) #[FuelEP,Nation,Year]  Oil and Gas Supply Adjustments (TBtu/Yr)
  ZCarConv::VariableArray{2} = ReadDisk(db,"SInput/ZCarConv") #[FuelEP,Poll]  Convert from ($/Tonnes/($/mmBtu))

  KJBtu::Float32 = 1.054615
end

function GasDemand(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Fuel,Nations) = data #sets
  (; ANMap,GADemand,GDemand,TotDemand) = data

  fuel = Select(Fuel,"NaturalGas")
  
  #
  # Natural Gas Demand for Current Year
  #
  for nation in Nations
    areas = findall(ANMap[Areas,nation] .== 1)
    if !isempty(areas)   
      for area in areas
        GADemand[area] = sum(TotDemand[fuel,ecc,area] for ecc in ECCs)
      end
      GDemand[nation] = sum(GADemand[area] for area in areas)
    end
  end
  
  WriteDisk(db,"SOutput/GDemand",year,GDemand)
  WriteDisk(db,"SpOutput/GADemand",year,GADemand)  

end

function MarketableGas(data::Data)
  (; db,year) = data
  (; ECCs,Fuel,Nations,Processes) = data #sets
  (; ANMap,FlGProd,FuGProd,GARaw,GasProductionMap,GLosses,GMarket) = data
  (; GMMult,GAProd,GProd,GRaw,VnGProd,TotDemand,TProd) = data

  #
  # Gas Production
  #
  for nation in Nations
    TProd[nation] = sum(GProd[process,nation]*GasProductionMap[process] for process in Processes)
  end

  #
  # Marketable Gas Production
  #
  ngrawfuel = Select(Fuel,"NaturalGasRaw")

  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1
        GARaw[area] = sum(TotDemand[fuel,ecc,area] for ecc in ECCs, fuel in ngrawfuel)
        GARaw[area] = min(sum(GAProd[process,area]*GasProductionMap[process] for process in Processes), GARaw[area])
      end
    end
    GRaw[nation] = sum(GARaw[area]*ANMap[area,nation] for area in areas)
    
    GMarket[nation] = (TProd[nation]-GRaw[nation])*GMMult[nation]+
                      (VnGProd[nation]+FuGProd[nation]+FlGProd[nation])
                      
    GLosses[nation] = TProd[nation]-GMarket[nation]-GRaw[nation]
  end

  WriteDisk(db,"SOutput/GMarket",year,GMarket)
  WriteDisk(db,"SOutput/GRaw",year,GRaw)
  WriteDisk(db,"SpOutput/GARaw",year,GARaw)
  WriteDisk(db,"SOutput/GLosses",year,GLosses)

end

function GasSupplyAdjustments(data::Data)
  (; db,year,CTime) = data
  (; FuelEP,Nation,Nations) = data #sets
  (; GDemand,GMarket,SupplyAdjustments,xExports,xImports,xSupplyAdjustments) = data

  fuelep = Select(FuelEP,"NaturalGas")

  #
  # Supply Adjustments
  #
  if CTime <= HisTime
    for nation in Nations
      SupplyAdjustments[fuelep,nation] = GDemand[nation]+xExports[fuelep,nation]-
        GMarket[nation]-xImports[fuelep,nation]
    
      #NatDS = Nation[nation]
      #@info " GasSupplyAdjustments for $NatDS $CTime"
      #loc1 = SupplyAdjustments[fuelep,nation]
      #@info " SupplyAdjustments[fuelep,nation] = $loc1 "
      #loc1 = GDemand[nation]
      #@info " GDemand[nation]                  = $loc1 "     
      #loc1 = xExports[fuelep,nation]
      #@info " xExports[fuelep,nation]          = $loc1 " 
      #loc1 = GMarket[nation]
      #@info " GMarket[nation]                  = $loc1 "     
      #loc1 = xImports[fuelep,nation]
      #@info " xImports[fuelep,nation]          = $loc1 "     

    end

    
  else
    for nation in Nations
      SupplyAdjustments[fuelep,nation] = xSupplyAdjustments[fuelep,nation] 
    end
  end  

  WriteDisk(db,"SpOutput/SupplyAdjustments",year,SupplyAdjustments)

end

function GasImportsExports(data::Data)
  (; db,year) = data
  (; Area,FuelEP,Nation,Nations,OGUnits,Process) = data #sets
  (; ANMap,Exports,ExportsMin,ExportsPipeline,GAProd,GDemand,GMarket,GProd,Imports) = data
  (; ImportsMin,LNGAProd,LNGProd,LNGProdMin,OGCode,Pd,SupplyAdjustments) = data

  wsc = Select(Area,"WSC")
  ngfuelep = Select(FuelEP,"NaturalGas")
  cn = Select(Nation,"CN")
  us = Select(Nation,"US")
  mx = Select(Nation,"MX")
  lngproduction = Select(Process,"LNGProduction")


  #
  # Gas Imports
  #
  for nation in Nations
    Imports[ngfuelep,nation] = ImportsMin[ngfuelep,nation]+
      max(GDemand[nation]-GMarket[nation]-ImportsMin[ngfuelep,nation]+
      ExportsMin[ngfuelep,nation]+LNGProdMin[nation]-SupplyAdjustments[ngfuelep,nation],0)
  end

  #
  # Gas Exports
  #
  for nation in Nations
    Exports[ngfuelep,nation] = ExportsMin[ngfuelep,nation]+LNGProdMin[nation]+max(GMarket[nation]-GDemand[nation]+Imports[ngfuelep,nation]-ExportsMin[ngfuelep,nation]-LNGProdMin[nation]+SupplyAdjustments[ngfuelep,nation],0)
  end

  ExportsPipeline[us] = min(Imports[ngfuelep,cn]+Imports[ngfuelep,mx],Exports[ngfuelep,us]-LNGProdMin[us])
  ExportsPipeline[cn] = Exports[ngfuelep,cn]-LNGProdMin[cn]
  ExportsPipeline[mx] = Exports[ngfuelep,mx]-LNGProdMin[mx]

  #

  GAProd[lngproduction,wsc] = Exports[ngfuelep,us]-ExportsPipeline[us]-LNGProdMin[us]

  # Select OGUnit If OGCode eq "WSC_LNG_0001"
  for ogunit in OGUnits
    if OGCode[ogunit] == "WSC_LNG_0001"
      Pd[ogunit] = GAProd[lngproduction,wsc]
    end
  end

  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    LNGProd[nation] = sum(LNGAProd[area] for area in areas)
    GProd[lngproduction,nation] = sum(GAProd[lngproduction,area] for area in areas)
  end

  WriteDisk(db,"SpOutput/Exports",year,Exports)
  WriteDisk(db,"SOutput/ExportsPipeline",year,ExportsPipeline)
  WriteDisk(db,"SpOutput/Imports",year,Imports)
  WriteDisk(db,"SOutput/LNGProd",year,LNGProd)
  WriteDisk(db,"SOutput/LNGAProd",year,LNGAProd)
  WriteDisk(db,"SOutput/GAProd",year,GAProd)
  WriteDisk(db,"SOutput/GProd",year,GProd)

end

function EcoGas(data::Data)
  (; db,year) = data
  (; ECC,ECCs,Nation,Process,Processes) = data #sets
  (; ANMap,GAProd,GOMult,xGAProd) = data
  cn = Select(Nation,"CN")
  cnareas = findall(ANMap[:,cn] .== 1)

  # @info "  SpGas.jl - EcoGas - Economic Multipliers for NG Supply"

  for nation in cn, area in cnareas
    if ANMap[area,nation] == 1
      #
      #  Select NG Production sectors
      #
      for process in Processes
        if (Process[process] == "ConventionalGasProduction") || (Process[process] == "UnconventionalGasProduction") ||
           (Process[process] == "SweetGasProcessing") || (Process[process] == "SourGasProcessing") ||
           (Process[process] == "GasMining") || (Process[process] == "LNGProduction")
          if xGAProd[area,process] >= 0.0001
            for ecc in ECCs
              if ECC[ecc] == Process[process]
                GOMult[ecc,area] = GAProd[area,process]/xGAProd[area,process]
              end
            end
          end
        end
      end
    end
  end

  WriteDisk(db,"SOutput/GOMult",year,GOMult)

end

function GasPrice(data::Data)
  (; db,next) = data
  (; ECC,ECCs,Fuel,FuelEP,GNodes,Markets,Months,Nation,Nations,PCovs,Poll,Processes) = data #sets
  (; ANMap,BaseSw,ENPNNext,Exports,ExportsRef,FPGNode) = data
  (; GasProductionMap,GDemand,GDemandRef,GMarket,GMarketRef,GPGPrSwNext) = data
  (; GProd,GPrTaxNext,GRqDemand,GSM,GSMRef,GSPElas,GSPMNext,GSPMPrior) = data
  (; GSPMSwNext,Imports,ImportsRef,InflationNationNext) = data
  (; PCostNext,PGratis,PolCov,RefSwitch,TProd,xENPNNext,xGProd,xGProdRef) = data

  # @info "  SpGas.jl - GasPrice"

    @. GPrTaxNext = 0.0

  #
  # Natural Gas Wellhead Prices
  #
  ngfuel = Select(Fuel,"NaturalGas")
  ngfuelep = Select(FuelEP,"NaturalGas")

  #
  # Reference Case Natural Gas Production
  #
  if (BaseSw == 0) && (RefSwitch == 0)

    #
    # TODOJulia reading reference cases 23.09.05, LJD:
    #

    # FText1=RefName::0+"\SInput.dba"
    # Open SInput FText1
    # FText1=RefName::0+"\SOutput.dba"
    # Open SOutput FText1
    # FText1=RefName::0+"\SpOutput.dba"
    # Open SpOutput FText1
    # Read Disk (GDemandRef,GMarketRef,GSMRef,xGProdRef)
    # Open SInput "SInput.dba"
    # Open SOutput "SOutput.dba"
    # Open SpOutput "SpOutput.dba"

    for nation in Nations
      GDemandRef[nation] = GDemand[nation]
      GMarketRef[nation] = GMarket[nation]
      for process in Processes
        GSMRef[process,nation] = GSM[process,nation]
        xGProdRef[process,nation] = xGProd[process,nation]
      end
    end

  else
    for nation in Nations
      GDemandRef[nation] = GDemand[nation]
      GMarketRef[nation] = GMarket[nation]
      for process in Processes
        GSMRef[process,nation] = GSM[process,nation]
        xGProdRef[process,nation] = xGProd[process,nation]
      end
    end
  end

  #
  # North America Price Impacts
  #
  northamerica = Select(Nation,["US","CN","MX"])

  if GSPMSwNext == 1
    
    #
    # Price Impacts of Excess Gas Demands
    #
    TotalProd = sum(GProd[process,nation]*GasProductionMap[process] for nation in northamerica, process in Processes)
    TotalxProd = sum(xGProd[process,nation]*GasProductionMap[process] for nation in northamerica, process in Processes)

    @finite_math GSPMNext = (TotalProd/TotalxProd)^(-1/GSPElas)

  elseif GSPMSwNext == 2
    
    #
    # Price Impacts of Exogenous Changing of Gas Production (for EMF Scenarios)
    #
    TotalMarket = sum(GMarket[nation] for nation in northamerica)
    TotalRefMarket = sum(GMarketRef[nation] for nation in northamerica)

    @finite_math GSPMNext = (TotalMarket/TotalRefMarket)^(-1/GSPElas)

  elseif GSPMSwNext == 3
    
    #
    # Price Impacts of Supply/Demand Imbalance
    #
    TotalDemand = sum(GDemand[nation] for nation in northamerica)
    TotalRefDemand = sum(GDemandRef[nation] for nation in northamerica)
    TotalMarket = sum(GMarket[nation] for nation in northamerica)
    TotalRefMarket = sum(GMarketRef[nation] for nation in northamerica)

    @finite_math GSPMNext = ((TotalMarket/TotalDemand)/
                      (TotalMarket/TotalRefDemand))^GSPElas
    GSPMNext = GSPMPrior+(GSPMNext-GSPMPrior)/4

  elseif GSPMSwNext == 4
    
    #
    # Price Impacts of Supply/Demand Imbalance
    #

    TotalSupply = sum(xGProd[process,nation]*GasProductionMap[process]*GSM[process,nation] for nation in northamerica, process in Processes)+
                sum(Imports[ngfuelep,nation] for nation in northamerica)
    TotalDemand = sum(GDemand[nation]+Exports[ngfuelep,nation] for nation in northamerica)
    TotalRefSupply = sum(xGProdRef[process,nation]*GasProductionMap[process]*GSMRef[process,nation] for nation in northamerica, process in Processes)+
                   sum(ImportsRef[ngfuelep,nation] for nation in northamerica)
    TotalRefDemand = sum(GDemandRef[nation]+ExportsRef[ngfuelep,nation] for nation in northamerica)

    @finite_math GSPMNext = ((TotalSupply/TotalDemand)/
                      (TotalRefSupply/TotalRefDemand))^GSPElas
    GSPMNext = GSPMPrior+(GSPMNext-GSPMPrior)/4

  elseif GSPMSwNext == 5
    
    #
    # Price Impacts of Supply/Demand Imbalance
    #
    TotalSupply2 = sum(GMarket[nation] for nation in northamerica)+sum(Imports[ngfuelep,nation] for nation in northamerica)
    TotalDemand2 = sum(GDemand[nation]+Exports[ngfuelep,nation] for nation in northamerica)
    TotalRefSupply2 = sum(GMarketRef[nation] for nation in northamerica)+sum(ImportsRef[ngfuelep,nation] for nation in northamerica)
    TotalRefDemand2 = sum(GDemandRef[nation]+ExportsRef[ngfuelep,nation] for nation in northamerica)

    @finite_math GSPMNext = ((TotalSupply2/TotalDemand2)/
                      (TotalRefSupply2/TotalRefDemand2))^GSPElas
    GSPMNext = GSPMPrior+(GSPMNext-GSPMPrior)/4

  elseif GSPMSwNext == 6
    
    #
    # NG Price comes from node price
    #
    GSPMNext = 1

  else
    
    #
    # Natural Gas Price impacts are turned off.
    #
    GSPMNext = 1

  end

  #
  # ***********************
  #
  # Natural Gas Production Taxes
  #
  co2 = Select(Poll,"CO2")

  for ecc in ECCs
    if (ECC[ecc] == "ConventionalGasProduction") || (ECC[ecc] == "UnconventionaGasProduction") ||
       (ECC[ecc] == "SweetGasProcessing")        || (ECC[ecc] == "SourGasProcessing") ||
       (ECC[ecc] == "GasMining")                 || (ECC[ecc] == "LNGProduction") || 
       (ECC[ecc] == "GasProduction")
      for nation in northamerica
        areas = findall(ANMap[:,nation] .== 1)
        TProd[nation] = sum(GProd[process,nation]*GasProductionMap[process] for process in Processes)

        for market in Markets
          
          #
          # Gratis Permits do not depend on production so the full permit cost
          # is included in the marginal production cost and the oil tax.
          #
          if GPGPrSwNext[market] == 1
            #       GPrTax[nation] = sum(Poll,PCov,A)(PolCov[ecc,poll,pcov,area]*
            #                                  PCost[ecc,poll,area])/TProd[nation]/1e6

            #
            # Gratis permits are intenisty based and depend on the level of production so
            # the marginal production costs includes the value of the gratis permits and
            # are included in the oil tax.
            #
          elseif GPGPrSwNext[market] == 2
            # GPrTaxNext[nation] = sum((PolCov[ecc,poll,pcov,area]-PGratis[ecc,poll,pcov,area])*
            # PCostNext[ecc,poll,area] for area in areas, pcov in PCovs, poll in co2)/TProd[nation]/1e6
          end
        end
      end
    end
  end

  #
  # Gas Wellhead Price
  #
  if GSPMSwNext != 6
    for nation in northamerica
      ENPNNext[ngfuel,nation] = (xENPNNext[ngfuel,nation]+GPrTaxNext[nation]/InflationNationNext[nation])*GSPMNext
    end
  else
    for nation in northamerica
      PriceAtGNode = sum(FPGNode[gnode,month]*GRqDemand[gnode,month] for month in Months, gnode in GNodes)
      WeightGNode = sum(GRqDemand[gnode,month] for month in Months, gnode in GNodes)+GPrTaxNext[nation]

      ENPNNext[ngfuel,nation] = (PriceAtGNode/WeightGNode)/InflationNationNext[nation]
      
    end
  end

  #
  # Adjust Natural Gas Related Prices - we need to replace "Select Fuel"
  # statement with flag - Jeff Amlin 8/10/19
  #
  relatedfuels = Select(Fuel,["Hydrogen","NaturalGasRaw","RNG","Steam","CokeOvenGas","StillGas"])
  for nation in northamerica, fuel in relatedfuels
    ENPNNext[fuel,nation] = xENPNNext[fuel,nation]*ENPNNext[ngfuel,nation]/xENPNNext[ngfuel,nation]
  end

  WriteDisk(db,"SOutput/ENPN",next,ENPNNext)
  WriteDisk(db,"SpOutput/GSPM",next,GSPMNext)
  WriteDisk(db,"SpOutput/GPrTax",next,GPrTaxNext)

end # function GasPrice

function GasDeliveredPrices(data::Data)
  (; db,year) = data
  (; Areas,ECC,ESes,Fuel,FuelEP,Markets,Nations,PCov,Poll) = data #sets
  (; ANMap,AreaMarket,ENPN,ETAPr,ETAvPr,ExchangeRate,FFPMap,FPDChgF,FPF) = data
  (; FPMarginF,FPPolTaxF,FPSMF,FPTaxF,GPGDist,GPNGSw,GPolDist) = data
  (; Inflation,PolConv,PolCovPrior,PollMarket,xPGratis,ZCarConv) = data

  # @info "  SpGas.jl - GasDeliveredPrices"

  #
  # Natural Gas Distribution Taxes
  #

  ngfuel = Select(Fuel,"NaturalGas")
  ngfuelep = Select(FuelEP,"NaturalGas")

  for area in Areas, es in ESes, fuel in ngfuel
    FPPolTaxF[fuel,es,area] = 0
  end

  for market in Markets
    areasmkt = findall(AreaMarket[:,market] .== 1)
    pollsmkt = findall(PollMarket[:,market] .== 1)
    if  GPNGSw != 0
      if !isempty(areasmkt) && !isempty(pollsmkt)
        for area in areasmkt
          if AreaMarket[area,market] == 1
            #
            # Pollution from Natural Gas which is distributed
            #
            for ecc in Select(ECC,"NGDistribution")

              GPolDist[area,market] = sum(PolCovPrior[ecc,poll,pcov,area] for pcov in Select(PCov,"NaturalGas"), poll in pollsmkt)

              #
              # Gratis Permits for Distribution Company
              #
              GPGDist[area,market] = sum(xPGratis[ecc,poll,pcov,area] for pcov in Select(PCov,"NaturalGas"), poll in pollsmkt)

            end

            #
            # Customers must pay full marginal cost of permits (GPNGSw eq 1)
            #
            if GPNGSw == 1
              ghg = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
              for es in ESes
                @finite_math FPPolTaxF[ngfuel,es,area] = FPPolTaxF[ngfuel,es,area]+ETAPr[market]*
                                                    sum(ZCarConv[ngfuelep,poll]*PolConv[poll] for poll in ghg)/
                                                    Inflation[area]*ExchangeRate[area]
              end

            #
            # Distributors must pass on value of all gratis permits to customers
            # and use the average cost of permits (GPNGSw eq 2)
            #
            elseif GPNGSw == 2
              ghg = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
              for es in ESes
                @finite_math FPPolTaxF[ngfuel,es,area] = FPPolTaxF[ngfuel,es,area]+
                                                    (GPolDist[area,market]-GPGDist[area,market])/GPolDist[area,market]*ETAvPr[market]*
                                                    sum(ZCarConv[ngfuelep,poll]*PolConv[poll] for poll in ghg)/
                                                    Inflation[area]*ExchangeRate[area]
              end
            end
          end
        end
      end
    end
  end

  #
  # Adjust Delivered Natural Gas Prices
  #
  GPNGSwitch = sum(GPNGSw[market] for market in Markets)
  if GPNGSwitch != 0
    for nation in Nations
      for area in Areas
        if ANMap[area,nation] == 1
          for es in ESes
            FPF[ngfuel,es,area] = (ENPN[ngfuel,nation]*(1+FPMarginF[ngfuel,es,area])+FPDChgF[ngfuel,es,area]+FPTaxF[ngfuel,es,area]+FPPolTaxF[ngfuel,es,area])*Inflation[area]*(1+FPSMF[ngfuel,es,area])
          end
        end
      end
    end
  end

  WriteDisk(db,"SOutput/FPF",year,FPF)
  WriteDisk(db,"SOutput/FPPolTaxF",year,FPPolTaxF)
  WriteDisk(db,"SOutput/GPGDist",year,GPGDist)
  WriteDisk(db,"SOutput/GPolDist",year,GPolDist)

end # function GasDeliveredPrices

function Control(data::Data)
  # @info "  SpGas.jl - Control"

  GasDemand(data)
  MarketableGas(data)
  GasSupplyAdjustments(data)
  GasImportsExports(data)
  EcoGas(data)
end # function Control


end # module SpGas
