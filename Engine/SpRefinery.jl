#
# SpRefinery.jl
#

module SpRefinery

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,ITime,HisTime,@finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  Last = HisTime-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")
  
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AreaMarket::VariableArray{2} = ReadDisk(db,"SInput/AreaMarket",year) #[Area,Market,Year]  Areas included in Market
  BaRPPADemand::VariableArray{2} = ReadDisk(BCNameDB,"SpOutput/RPPADemand") #[Area,Year]  Base Case Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  BaRPPDemand::VariableArray{2} = ReadDisk(BCNameDB,"SpOutput/RPPDemand") #[Nation,Year]  Base Case Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  BaRPPAProd::VariableArray{2} = ReadDisk(BCNameDB,"SpOutput/RPPAProd") #[Area,Year]  Base Case Refined Petroleum Products (RPP) Production (TBtu/Yr)
  BaseSw::Float32 = ReadDisk(db,"SInput/BaseSw")[1] #[tv]  Base Case Switch (1=Base Case)
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") #[Area,CNArea]  Map between Area and Canada Economic Areas (CNArea)
  ECCMarket::VariableArray{2} = ReadDisk(db,"SInput/ECCMarket",year) #[ECC,Market,Year]  Economic Categories included in Market
  ECoverage::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) #[ECC,Poll,PCov,Area,Year]  Emissions Permit Coverage (Tonnes/Tonnes)
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year]  Primary Fuel Price ($/mmBtu)
  ETAPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAPr",year) #[Market,Year]  Cost of Emission Trading Allowances (US$/Tonne)
  ETAvPr::VariableArray{1} = ReadDisk(db,"SOutput/ETAvPr",year) #[Market,Year]  Average Cost of Emission Trading Allowances (US$/Tonne)
  ExchangeRate::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRate") #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FPDChgF::VariableArray{3} = ReadDisk(db,"SCalDB/FPDChgF",year) #[Fuel,ES,Area,Year]  Fuel Delivery Charge (Real $/mmBtu)
  FPMarginF::VariableArray{3} = ReadDisk(db,"SInput/FPMarginF",year) #[Fuel,ES,Area,Year]  Refinery/Distributor Margin ($/$)
  FPPolTaxF::VariableArray{3} = ReadDisk(db,"SOutput/FPPolTaxF",year) #[Fuel,ES,Area,Year]  Pollution Tax (Real $/mmBtu)
  FPSMF::VariableArray{3} = ReadDisk(db,"SInput/FPSMF",year) #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPTaxF::VariableArray{3} = ReadDisk(db,"SInput/FPTaxF",year) #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  GO::VariableArray{2} = ReadDisk(db,"MOutput/GO",year) #[ECC,Area,Year]  Gross Output (Real M$/Yr)
  GOMult::VariableArray{2} = ReadDisk(db,"SOutput/GOMult",year) #[ECC,Area,Year]  Gross Output Multiplier ($/$)
  GPFrac::VariableArray{4} = ReadDisk(db,"SOutput/GPFrac",year) #[ECC,Poll,PCov,Area,Year]  Emissions Gratis Fraction (Tonnes/Tonnes)
  GPOilSw::VariableArray{1} = ReadDisk(db,"SInput/GPOilSw",year) #[Market,Year]  Gratis Permit Allocation Switch for Oil Distribution
  GPODist::VariableArray{2} = ReadDisk(db,"SOutput/GPODist",year) #[Area,Market,Year]  Oil Distribution Company Gratis Permits (Tonnes)
  GPOPrSw::VariableArray{1} = ReadDisk(db,"SInput/GPOPrSw",year) #[Market,Year]  Oil Production Intensity based Gratis Permits (2=Intensity)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  OAPDExist::VariableArray{2} = ReadDisk(db,"SpOutput/OAPDExist",year) #[Process,Area,Year]  Drop in Existing Oil Production (TBtu/Yr/Yr)
  OAPDNew::VariableArray{2} = ReadDisk(db,"SpOutput/OAPDNew",year) #[Process,Area,Year]  Drop in New Oil Production (TBtu/Yr/Yr)
  OAPNew::VariableArray{2} = ReadDisk(db,"SpOutput/OAPNew",year) #[Process,Area,Year]  New Oil Production (TBtu/Yr/Yr)
  OPDDSw::VariableArray{1} = ReadDisk(db,"SpInput/OPDDSw",year) #[Nation,Year]  Switch to Adjust Oil Production (1=New & Existing, 2=New Only)
  OPDExist::VariableArray{1} = ReadDisk(db,"SpOutput/OPDExist",year) #[Nation,Year]  Drop in Existing Oil Production (TBtu/Yr/Yr)
  OPDNew::VariableArray{1} = ReadDisk(db,"SpOutput/OPDNew",year) #[Nation,Year]  Drop in New Oil Production (TBtu/Yr/Yr)
  OPNew::VariableArray{1} = ReadDisk(db,"SpOutput/OPNew",year) #[Nation,Year]  New Oil Production (TBtu/Yr/Yr)
  OGGPFr::VariableArray{2} = ReadDisk(db,"SpInput/OGGPFr",year) #[Process,Nation,Year]  Grandfathered Gratis Permit Fraction for Oil Industry (Tonnes/Tonnes)
  OIPElas::Float32 = ReadDisk(db,"SpInput/OIPElas",year) #[Year]  Oil Import Price Elasticity
  OIPSw::Float32 = ReadDisk(db,"SpInput/OIPSw",year) #[Year]  Oil Import Price Switch
  OPolDist::VariableArray{2} = ReadDisk(db,"SOutput/OPolDist",year) #[Area,Market,Year]  Pollution from RPP which are Distributed (Tonnes)
  OProd::VariableArray{2} = ReadDisk(db,"SOutput/OProd",year) #[Process,Nation,Year]  Primary Oil Production (TBtu/Yr)
  OPRODPrior::VariableArray{2} = ReadDisk(db,"SOutput/OProd",prior) #[Process,Nation,Prior]  Primary Oil Production in Prior (TBtu/Yr)
  OPrTax::VariableArray{2} = ReadDisk(db,"SpOutput/OPrTax",year) #[Process,Nation,Year]  Oil Production Tax ($/mmBtu)
  OSElas::VariableArray{2} = ReadDisk(db,"SpInput/OSElas") #[Process,Nation]  Oil Supply Elasticity
  OSM::VariableArray{2} = ReadDisk(db,"SpOutput/OSM",year) #[Process,Nation,Year]  Oil Supply Multiplier (Btu/Btu)
  OSMExist::VariableArray{2} = ReadDisk(db,"SpOutput/OSMExist",year) #[Process,Nation,Year]  Oil Supply Multiplier for Existing Production (Btu/Btu)
  OSMNew::VariableArray{2} = ReadDisk(db,"SpOutput/OSMNew",year) #[Process,Nation,Year]  Oil Supply Multiplier for New Production (Btu/Btu)
  OSUpFr::VariableArray{1} = ReadDisk(db,"SpInput/OSUpFr",year) #[Process,Year]  Oil Sands Upgrader Fraction (Btu/Btu)
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost ($/Tonne)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PolCovPrior::VariableArray{4} = ReadDisk(db,"SOutput/PolCov",prior) #[ECC,Poll,PCov,Area,Year]  Total Covered Pollution (Tonnes/Yr)
  PollMarket::VariableArray{2} = ReadDisk(db,"SInput/PollMarket",year) #[Poll,Market,Year]  Pollutants included in Market
  RPPADD::VariableArray{1} = ReadDisk(db,"SpOutput/RPPADD",year) #[Area,Year]  RPP Demand Drop Relative to Base Case (TBtu/Yr)
  RPPADemand::VariableArray{2} = ReadDisk(db,"SpOutput/RPPADemand") #[Area,Year]  Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  RPPAProd::VariableArray{2} = ReadDisk(db,"SpOutput/RPPAProd") #[Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPAdjustments::VariableArray{1} = ReadDisk(db,"SpOutput/RPPAdjustments",year) #[Nation,Year]  RPP Supply Adjustments (TBtu/Yr)
  RPPDemand::VariableArray{2} = ReadDisk(db,"SpOutput/RPPDemand") #[Nation,Year]  Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  RPPEff::VariableArray{1} = ReadDisk(db,"SCalDB/RPPEff",year) #[Nation,Year]  RPP Efficiency Factor (Btu/Btu)
  RPPExports::VariableArray{2} = ReadDisk(db,"SpOutput/RPPExports") #[Nation,Year]  Refined Petroleum Products (RPP) Exports (TBtu/Yr)
  RPPImports::VariableArray{2} = ReadDisk(db,"SpOutput/RPPImports") #[Nation,Year]  Refined Petroleum Products (RPP) Imports (TBtu/Yr)
  RPPDD::VariableArray{1} = ReadDisk(db,"SpOutput/RPPDD",year) #[Nation,Year]  RPP Demand Drop Relative to Base Case (TBtu/Yr)
  RPPProd::VariableArray{1} = ReadDisk(db,"SpOutput/RPPProd",year) #[Nation,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPASw::VariableArray{1} = ReadDisk(db,"SpInput/RPPASw",year) #[Area,Year]  Refined Petroleum Products (RPP) Area Production Switch
  RPPSw::VariableArray{1} = ReadDisk(db,"SpInput/RPPSw",year) #[Area,Year]  Refined Petroleum Products (RPP) Switch
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) #[Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)
  xPGratis::VariableArray{4} = ReadDisk(db,"SInput/xPGratis",year) #[ECC,Poll,PCov,Area,Year]  Exogenous Gratis Permits (Tonnes/Yr)
  xRPPAdjustments::VariableArray{1} = ReadDisk(db,"SpInput/xRPPAdjustments",year) #[Nation,Year]  RPP Supply Adjustments (TBtu/Yr)
  xRPPAProd::VariableArray{2} = ReadDisk(db,"SInput/xRPPAProd") #[Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xRPPExports::VariableArray{1} = ReadDisk(db,"SpInput/xRPPExports",year) #[Nation,Year]  Refined Petroleum Products (RPP) Exports (TBtu/Yr)
  xRPPImports::VariableArray{1} = ReadDisk(db,"SpInput/xRPPImports",year) #[Nation,Year]  Refined Petroleum Products (RPP) Imports (TBtu/Yr)
  xRPPProd::VariableArray{1} = ReadDisk(db,"SInput/xRPPProd",year) #[Nation,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  ZCarConv::VariableArray{2} = ReadDisk(db,"SInput/ZCarConv") #[FuelEP,Poll]  Convert from $/Tonnes to $/mmBtu
end

function DemRPP(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Fuel,Nations) = data
  (; ANMap,BaseSw,RPPADemand,TotDemand,RPPEff,RPPDemand,BaRPPADemand,BaRPPDemand,RPPADD,RPPDD) = data

  #
  # Refined Petroleum Product Demands
  #
  fuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
                        "Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy",
                        "PetroFeed","PetroCoke","StillGas"])
  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1.0
        @finite_math RPPADemand[area,year] = 
          sum(TotDemand[fuel,ecc,area] for ecc in ECCs, fuel in fuels)/RPPEff[nation]
      end
    end
    RPPDemand[nation,year] = sum(RPPADemand[area,year] for area in areas)
  end

  #
  #  Base Case RPP Demands
  #
  if BaseSw == 1
    for area in Areas
      BaRPPADemand[area,year] = RPPADemand[area,year]
    end
    for nation in Nations
      BaRPPDemand[nation,year] = RPPDemand[nation,year]
    end
  end

  #
  #  RPP Demand Drop (relative to Base Case)
  #
  for area in Areas
    RPPADD[area] = max(BaRPPADemand[area,year]-RPPADemand[area,year],0)
  end
  for nation in Nations
    RPPDD[nation] = max(BaRPPDemand[nation,year]-RPPDemand[nation,year],0)
  end

  WriteDisk(db,"SpOutput/RPPADD",year,RPPADD)
  WriteDisk(db,"SpOutput/RPPADemand",RPPADemand)
  WriteDisk(db,"SpOutput/RPPDD",year,RPPDD)
  WriteDisk(db,"SpOutput/RPPDemand",RPPDemand)

end # function DemRPP

function SupRPP(data::Data)
  (; db,year,prior,Last) = data
  (; Nation) = data
  (; ANMap,RPPAdjustments,RPPDemand,xRPPExports,xRPPProd,xRPPImports) = data
  (; xRPPAdjustments,RPPSw,RPPProd,RPPAProd,xRPPAProd,RPPImports,RPPExports) = data

  #
  # Refined Petroleum Product (RPP) Supply
  #
  # Note even though RPPSw is by Area, the entire nation must use the same
  # value for the switch since we are summing acrossed Area in the code.
  # Jeff Amlin 6/24/10.
  #
  for nation in Select(Nation)
    areas = findall(ANMap[:,nation] .== 1)
    areaforswitch = first(areas)
    #
    # Supply Adjustments
    #
    if year <= Last
      RPPAdjustments[nation] = RPPDemand[nation,year]+xRPPExports[nation]-
                               xRPPProd[nation]-xRPPImports[nation]
    else
      RPPAdjustments[nation] = xRPPAdjustments[nation]
    end
    #
    #   When RPPSw == 0, RPP production and imports are exogenous.
    #   RPP exports are production less demand plus imports.
    #
    if RPPSw[areaforswitch] == 0
      
      for area in areas
        RPPAProd[area,year] = xRPPAProd[area,year]
      end
      RPPProd[nation] = sum(RPPAProd[area,year] for area in areas)
      
      RPPImports[nation,year] = xRPPImports[nation]+max(RPPDemand[nation,year]-
        RPPProd[nation]-xRPPImports[nation]-RPPAdjustments[nation],0)
      
      RPPExports[nation,year] = max(RPPProd[nation]-RPPDemand[nation,year]+
        RPPImports[nation,year]+RPPAdjustments[nation],0)

    #
    # When RPPSw == 1, the RPP production is exogenous.  RPP imports are a
    # function of RPP demand growth.  RPP exports are production less demand
    # plus imports.
    #
    elseif RPPSw[areaforswitch] == 1
      
      for area in areas
        RPPAProd[area,year] = xRPPAProd[area,year]
      end
      RPPProd[nation] = sum(RPPAProd[area,year] for area in areas)
      
      @finite_math RPPImports[nation,year] =
        RPPImports[nation,prior]*RPPDemand[nation,year]/RPPDemand[nation,prior]
        
      RPPExports[nation,year] = max(RPPProd[nation]-RPPDemand[nation,year]+
        RPPImports[nation,year]+RPPAdjustments[nation],0)
      
      RPPImports[nation,year] = max(RPPDemand[nation,year]-RPPProd[nation]+
        RPPExports[nation,year]-RPPAdjustments[nation],0)
        

    #
    # When RPPSw == 2, RPP imports and exports are a function of RPP demand growth.  RPP
    # production is RPP demand plus exports less imports (shared across the
    # provinces based on pre-2020 production levels).  RPP exports are re-computed
    # to assure that totals match.
    #
    elseif RPPSw[areaforswitch] == 2
    
      @finite_math RPPImports[nation,year] = RPPImports[nation,prior]*
                   RPPDemand[nation,year]/RPPDemand[nation,prior]
    
      @finite_math RPPExports[nation,year] = RPPExports[nation,prior]*
                   RPPDemand[nation,year]/RPPDemand[nation,prior]
    
      for area in areas
        @finite_math RPPAProd[area,year] = RPPAProd[area,prior]*
                    (RPPDemand[nation,year]+RPPExports[nation,year]-RPPImports[nation,year])/
                    (RPPDemand[nation,prior]+RPPExports[nation,prior]-RPPImports[nation,prior])
      end
      
      RPPProd[nation] = sum(RPPAProd[area,year] for area in areas)
      RPPExports[nation,year] = RPPProd[nation]-RPPDemand[nation,year]+RPPImports[nation,year]

    #
    # 23.10.12, LJD: Values for RPPSw >= 3 seem unused in current Model and Policies.
    #
    elseif (RPPSw[areaforswitch] == 3) || (RPPSw[areaforswitch] == 4) ||
      (RPPSw[areaforswitch] == 5) || (RPPSw[areaforswitch] == 6) 
      @info "RPPSw values of 3,4,5,6 not currently implemented."

      # # When RPPSw == 3, the Base Case RPP production is exogenous.  RPP imports are
      # # a function of RPP demand growth.  RPP exports are production less Base Case
      # # demand plus imports.
      # #
      # #     Else RPPSw == 3
      # #       RPPAProd=xRPPAProd
      # #       RPPImports[nation,year] = RPPImports[nation,prior]*RPPDemand[nation,year]/RPPDemand[nation,prior]
      # #       RPPExports[nation,year] = sum(A)(RPPAProd[area,year])-BaRPPDemand[nation,year]+RPPImports[nation,year]
      # # 
      # #      Reduce RPP Production to reflect drop in RPP Demand from Base Case
      # # 
      # #       RPPAProd=xmax(RPPAProd-RPPADD,0)
      # # 
      # #      National RPP Production
      # # 
      # #       RPPProd=RPPDemand+RPPExports-RPPImports
      # # 
      # #      Scale provincial RPP Production to national RPP Production
      # # 
      # #       Loc1=sum(A)(RPPAProd[area,year])
      # #       RPPAProd=RPPAProd*RPPProd/Loc1
      # # 
      # #    RPP Production is a function of Crude Oil Production (OProd)
      # # 
      # #     Else RPPSw == 4
      # #       RPPImports[nation,year] = RPPImports[nation,prior]*RPPDemand[nation,year]/RPPDemand[nation,prior]
      # #       Select Process(LightOilMining-OilSandsMining,PentanesPlus,Condensates)
      # #       RPPAProd[area,year] = RPPAProd(A,Y-1)*sum(Pro)(OProd(Pro,N))/sum(Pro)(OPRODPrior(Pro,N))
      # #       Select Process*
      # #       RPPProd(N)=sum(A)(RPPAProd[area,year])
      # #       RPPExports=RPPProd-RPPDemand+RPPImports
      # # 
      # #    Maximum RPP Production is exogenous, but production will decline if
      # #    RPP Demand declines.
      # # 
      # #     Else RPPSw == 5
      # # 
      # #      Imports and Exports grow with Demands (RPPDemand)
      # # 
      # #       RPPImports[nation,year] = RPPImports[nation,prior]*RPPDemand[nation,year]/RPPDemand[nation,prior]
      # #       RPPExports[nation,year] = RPPExports[nation,prior]*RPPDemand[nation,year]/RPPDemand[nation,prior]
      # # 
      # #      Production increases (decreases) with Demand net of Imports and Exports
      # # 
      # #       RPPAProd[area,year] = RPPAProd(A,Y-1)*
      # #                    (RPPDemand[nation,year]+RPPExports[nation,year]-RPPImports[nation,year])/
      # #                    (RPPDemand[nation,prior]+RPPExports[nation,prior]-RPPImports[nation,prior])
      # # 
      # #      For selected areas (RPPASw == 0) production is exogenous (xRPPAProd)
      # # 
      # #       Do Area
      # #         Do If RPPASw == 0
      # #           RPPAProd=xRPPAProd
      # #         End Do If
      # #       End Do Area
      # #       RPPProd(N)=sum(A)(RPPAProd[area,year])
      # # 
      # #      Adjust Imports to reflect constraints on production
      # # 
      # #       RPPImports=xmax(RPPDemand-RPPProd+RPPExports-RPPAdjustments,0)
      # #       RPPExports=xmax(RPPProd-RPPDemand+RPPImports+RPPAdjustments,0)
      # # 
      # #    Maximum RPP Production is exogenous, but production will decline if
      # #    RPP Demand declines. Remove second RPPImport calculation - Jeff Amlin 7/31/19
      # # 
      # #     Else RPPSw == 6
      # # 
      # #      Imports and Exports grow with Demands (RPPDemand)
      # # 
      # #       RPPImports[nation,year] = RPPImports[nation,prior]*RPPDemand[nation,year]/RPPDemand[nation,prior]
      # #       RPPExports[nation,year] = RPPExports[nation,prior]*RPPDemand[nation,year]/RPPDemand[nation,prior]
      # # 
      # #      Production increases (decreases) with Demand net of Imports and Exports
      # # 
      # #       RPPAProd[area,year] = RPPAProd(A,Y-1)*
      # #                    (RPPDemand[nation,year]+RPPExports[nation,year]-RPPImports[nation,year])/
      # #                    (RPPDemand[nation,prior]+RPPExports[nation,prior]-RPPImports[nation,prior])
      # # 
      # #      For selected areas (RPPASw == 0) production is exogenous (xRPPAProd)
      # # 
      # #       Do Area
      # #         Do If RPPASw == 0
      # #           RPPAProd=xRPPAProd
      # #         End Do If
      # #       End Do Area
      # #       RPPProd(N)=sum(A)(RPPAProd[area,year])
      # # 
      # #      Adjust Imports to reflect constraints on production
      # # 
      # #      RPPImports=xmax(RPPDemand-RPPProd+RPPExports-RPPAdjustments,0) - remove Jeff Amlin 7/31/19
      # #       RPPExports=xmax(RPPProd-RPPDemand+RPPImports+RPPAdjustments,0)
      # # 
    end
  end

  WriteDisk(db,"SpOutput/RPPAdjustments",year,RPPAdjustments)
  WriteDisk(db,"SpOutput/RPPExports",RPPExports)
  WriteDisk(db,"SpOutput/RPPImports",RPPImports)
  WriteDisk(db,"SpOutput/RPPAProd",RPPAProd)
  WriteDisk(db,"SpOutput/RPPProd",year,RPPProd)

end # function SupRPP

function EcoRPP(data::Data)
  (; db,year) = data
  (; ECC,Nation) = data
  (; ANMap,GOMult,RPPAProd,xRPPAProd) = data

  y = year

  #
  # Multiplier for Petroleum Refining Gross Output from Oil Refining
  #
  ecc = Select(ECC,"Petroleum")

  #
  # Section Not needed in Julia, part of Data Inputs
  # Read Disk(GOMult)
  # Do If BaseSw == 0
  #   FText1=BCName::0+"\SOutput.dba"
  #   Open SOutput FText1
  #   Read Disk(BaRPAProd)
  #   Open SOutput "SOutput.dba"
  # End Do If BaseSw

  for nation in Select(Nation)
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1.0
        if xRPPAProd[area,year] < 0.0
          #  GOMult=RPPAProd/BaRPAProd # Commented out in Promula
          GOMult[ecc,area] = RPPAProd[area,year]/xRPPAProd[area,year]
        end
      end
    end
  end

  WriteDisk(db,"SOutput/GOMult",year,GOMult)

end # function EcoRPP

function OilDeliveredPrice(data::Data)
  (; ECC,ES,Fuel,Market,Nation,PCov,Poll) = data
  (; AreaMarket,ENPN,ETAPr,ETAvPr,ExchangeRate,FFPMap) = data
  (; FPDChgF,FPF,FPMarginF,FPPolTaxF,FPSMF,FPTaxF) = data
  (; GPODist,GPOilSw,Inflation,OPolDist,PolConv) = data
  (; PolCovPrior,PollMarket,xPGratis,ZCarConv) = data

  # @info "  SpRefinery.jl - OilDeliveredPrice"

  #
  # Oil Distribution Taxes
  #
  fuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel",
                        "Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy",
                        "PetroFeed","PetroCoke","StillGas"])
  ghg = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  @. FPPolTaxF = 0

  for market in Select(Market)
    #
    # Select Prices, Pollutants and Areas covered in Market
    #
    areas_m = findall(AreaMarket[:,market] .== 1)
    polls_m = findall(PollMarket[:,market] .== 1)
    if !isempty(areas_m) && !isempty(polls_m) && (GPOilSw[market] != 0)
      #
      # Pollution from RPP(Oil) which are distributed
      #

      ecc = Select(ECC,"Petroleum")
      pcov = Select(PCov,"Oil")
      for area in areas_m
        OPolDist[area,market] = sum(PolCovPrior[ecc,poll,pcov,area] for poll in polls_m)

        #
        # Gratis Permits for Distribution Company
        #
        GPODist[area,market] = sum(xPGratis[ecc,poll,pcov,area] for poll in polls_m)

        #
        # Customers must pay full marginal cost of permits (GPOilSw == 1)
        #
        if GPOilSw[market] == 1
          for area in areas_m, es in Select(ES), fuel in fuels
            FPPolTaxF[fuel,es,area] = FPPolTaxF[fuel,es,area]+ETAPr[market]*
              sum(ZCarConv[fuelep,poll]*FFPMap[fuel,fuelep]*PolConv[poll] for poll in ghg, fuelep in Select(FuelEP))/
              Inflation[area]*ExchangeRate[area]
          end

        #
        # Distributors must pass on value of all gratis permits to customers
        # and use the average cost of permits (GPOilSw == 2)
        #
        else GPOilSw[market] == 2
          for area in areas_m, es in Select(ES), fuel in fuels
            @finite_math FPPolTaxF[fuel,es,area] = FPPolTaxF[fuel,es,area]+
              (OPolDist[area,market]-GPODist[area,market])/OPolDist[area,market]*ETAvPr[market]*
              sum(ZCarConv[fuelep,poll]*FFPMap[fuel,fuelep]*PolConv[poll] for poll in ghg, fuelep in Select(FuelEP))/
              Inflation[area]*ExchangeRate[area]
          end
        end
      end
    end
  end

  #
  # Adjust Delivered Oil Prices
  #

  GPOilSwitch = sum(GPOilSw[market] for market in Select(Market))
  if GPOilSwitch != 0
    for nation in Select(Nation)
      areas = findall(ANMap[:,nation] .== 1)
      for area in areas
        if ANMap[area,nation] == 1.0
          for es in Select(ES), fuel in fuels
            FPF[fuel,es,area] = (ENPN[fuel,nation]*(1+FPMarginF[fuel,es,area])+FPDChgF[fuel,es,area]+FPTaxF[fuel,es,area]+FPPolTaxF[fuel,es,area])*Inflation[area]*(1+FPSMF[fuel,es,area])
          end
        end
      end
    end
  end


  # Write Disk(FPF,FPPolTaxF,GPODist,OPolDist)

end # function OilDeliveredPrice

function Control(data::Data)
  # @info "  SpRefinery.jl - Control"
  DemRPP(data)
  SupRPP(data)
  EcoRPP(data)
end # function Control


end # module SpRefinery
