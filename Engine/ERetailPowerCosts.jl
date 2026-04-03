#
# ERetailPowerCosts.jl
#

module ERetailPowerCosts

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
    GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
    GenCos::Vector{Int} = collect(Select(GenCo))
    Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
    Months::Vector{Int} = collect(Select(Month))
    Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
    Nodes::Vector{Int} = collect(Select(Node))
    Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
    Plants::Vector{Int} = collect(Select(Plant))
    PPSet::SetArray = ReadDisk(db,"EInput/PPSetKey")
    TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
    TimePs::Vector{Int} = collect(Select(TimeP))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")

    AGPV::VariableArray{2} = ReadDisk(db,"EOutput/AGPV",year) #[Plant,GenCo,Year]  Average Gratis Permit Value (US$/Yr)
    AGPVSw::VariableArray{1} = ReadDisk(db,"EInput/AGPVSw",year) #[GenCo,Year]  Is Value of Gratis Permit passed on to Customers (1=Yes)
    AreaPurchases::VariableArray{1} = ReadDisk(db,"EGOutput/AreaPurchases",year) #[Areas,Year]  Purchases from Areas in the same Country (GWh/Yr)
    AreaSales::VariableArray{1} = ReadDisk(db,"EGOutput/AreaSales",year) #[Areas,Year]  Sales to Areas in the same Country (GWh/Yr)
    Capacity::VariableArray{5} = ReadDisk(db,"EOutput/Capacity",year) #[Areas,GenCo,Plant,TimePs,Months,Year]  Capacity under Contract (MW)
    DCCost::VariableArray{1} = ReadDisk(db,"EOutput/DCCost",year) #[Areas,Year]  Capacity Cost (M$/Yr)
    DVCost::VariableArray{1} = ReadDisk(db,"EOutput/DVCost",year) #[Areas,Year]  Variable Cost (M$/Yr)
    EGBI::VariableArray{3} = ReadDisk(db,"EOutput/EGBI",year) #[Areas,GenCo,Plant,Year]  Electricity sold thru Contracts (GWh/Yr)
    ExchangeRate::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRate",year) #[Areas,Year]  Local Currency/US$ Exchange Rate (Local/US$)
    ExportsRevenues::VariableArray{1} = ReadDisk(db,"SOutput/ExportsRevenues",year) #[Areas,Year]  Electric Exports Revenues (M$/Yr)
    ExpPurchases::VariableArray{1} = ReadDisk(db,"EGOutput/ExpPurchases",year) #[Areas,Year]  Purchases from Areas in a different Country (GWh/Yr)
    ExpSales::VariableArray{1} = ReadDisk(db,"EGOutput/ExpSales",year) #[Areas,Year]  Sales to Areas in a different Country (GWh/Yr)
    HDPrA::VariableArray{3} = ReadDisk(db,"EOutput/HDPrA",year) #[Node,TimePs,Months,Year]  Spot Market Marginal Price ($/MWh)
    HMEnergy::VariableArray{4} = ReadDisk(db,"EOutput/HMEnergy",year) #[Node,Areas,TimePs,Months,Year]  Energy in Interval (GWh)
    HMPr::VariableArray{3} = ReadDisk(db,"EOutput/HMPr",year) #[Areas,TimePs,Months,Year]  Spot Market Price ($/MWh)
    HMPrA::VariableArray{1} = ReadDisk(db,"EOutput/HMPrA",year) #[Areas,Year]  Average Spot Market Price ($/MWh)
    HMPrArea::VariableArray{1} = ReadDisk(db,"SOutput/HMPrArea",year) #[Areas,Year]  Electric Wholesale Price ($/MWh)
    ImportsExpenditures::VariableArray{1} = ReadDisk(db,"SOutput/ImportsExpenditures",year) #[Areas,Year]  Electric Imports Expenditures (M$/Yr)
    PPCT::VariableArray{2} = ReadDisk(db,"EOutput/PPCT",year) #[PPSet,Areas,Year]  Cost of Purchase Power (M$/Yr)
    PPEGTM::VariableArray{3} = ReadDisk(db,"EOutput/PPEGTM",year) #[Areas,TimePs,Months,Year]  Power Purchases (GWh)
    PPUC::VariableArray{1} = ReadDisk(db,"EOutput/PPUC",year) #[Areas,Year]  Unit Cost of Purchased Power ($/MWh)
    PUCT::VariableArray{1} = ReadDisk(db,"EOutput/PUCT",year) #[Areas,Year]  Cost of Purchase Power (M$/Yr)
    PUCTBI::VariableArray{1} = ReadDisk(db,"EOutput/PUCTBI",year) #[Areas,Year]  Cost of Purchase Power from Bilateral Contracts (M$/Yr)
    PUCTSM::VariableArray{1} = ReadDisk(db,"EOutput/PUCTSM",year) #[Areas,Year]  Cost of Purchase Power from Spot Market (M$/Yr)
    PPVCost::VariableArray{3} = ReadDisk(db,"EOutput/PPVCost",year) #[PPSet,Months,Areas,Year]  Estimated Spot Market Price ($/MWh)
    TSales::VariableArray{1} = ReadDisk(db,"EOutput/TSales",year) #[Areas,Year]  Electricity Sales (GWh/Yr)
    UCCost::VariableArray{3} = ReadDisk(db,"EOutput/UCCost",year) #[Areas,GenCo,Plant,Year]  Contract Capacity Cost (US$/KW)
    UECOST::VariableArray{3} = ReadDisk(db,"EOutput/UECOST",year) #[Areas,GenCo,Plant,Year]  Contract Energy Cost (US$/MWh)
    UVCost::VariableArray{3} = ReadDisk(db,"EOutput/UVCost",year) #[Areas,GenCo,Plant,Year]  Contract Variable Cost (US$/MWh)
  
    #
    # Scratch Variables
    #
    TempValueAGP::VariableArray{3} = zeros(Float32,length(Areas),length(GenCos),length(Plants))
  end

  function SpotMarketPriceByReCoArea(data::Data)
    (; db,year) = data
    (; Areas,TimePs,Months,Nodes) = data
    (; HDPrA,HMEnergy,HMPr,HMPrA) = data

    for month in Months, timep in TimePs, area in Areas
      @finite_math HMPr[area,timep,month] = sum(HDPrA[node,timep,month] *
            HMEnergy[node,area,timep,month] for node in Nodes) /
        sum(HMEnergy[node,area,timep,month] for node in Nodes)
    end
    WriteDisk(db,"EOutput/HMPr",year,HMPr)

    for area in Areas
      @finite_math HMPrA[area] = sum(HDPrA[node,timep,month] *
            HMEnergy[node,area,timep,month] for month in Months, timep in TimePs, node in Nodes) /
        sum(HMEnergy[node,area,timep,month] for month in Months, timep in TimePs, node in Nodes)
    end
    WriteDisk(db,"EOutput/HMPrA",year,HMPrA)
  end

  function SpotPriceByPowerType(data::Data)
    (; db,year) = data
    (; Areas,Months,PPSet,TimePs) = data
    (; HMPr,PPEGTM,PPVCost) = data

    for area in Areas, month in Months, ppset in Select(PPSet,"BasePP")
      @finite_math PPVCost[ppset,month,area] = sum(HMPr[area,timep,month] *
            PPEGTM[area,timep,month] for timep in TimePs) /
        sum(PPEGTM[area,timep,month] for timep in TimePs)
    end
    WriteDisk(db,"EOutput/PPVCost",year,PPVCost)
  end

  function ContractVariableCost(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Plants) = data
    (; AGPV,AGPVSw,UECOST,UVCost) = data

    #
    # If the benefit of gratis permits are passed to the customers (AGPVSw=1), then
    # remove value of gratis permits (AGPV) from energy costs (UECOST). Note
    # that contracts are dispatched on costs (EUCost) which does not include
    # the benefit of gratis permits. JSA 1/7/10
    #
    for genco in GenCos
      if AGPVSw[genco] == 1
        for plant in Plants, area in Areas
          UVCost[area,genco,plant] = UECOST[area,genco,plant]-AGPV[plant,genco]
        end
      else
        for plant in Plants, area in Areas
          UVCost[area,genco,plant] = UECOST[area,genco,plant]
        end
      end
    end
    WriteDisk(db,"EOutput/UVCost",year,UVCost)
  end

  function ContractCosts(data::Data)
    (; db,year) = data
    (; Areas,GenCos,Months,Plants,TimePs) = data
    (; Capacity,DCCost,DVCost,EGBI,ExchangeRate,UCCost,UVCost) = data
    (; TempValueAGP) = data

    #
    # Direct Access Contracts - Variable Costs
    #
    for area in Areas
      DVCost[area] =
        sum(EGBI[area,genco,plant]*UVCost[area,genco,plant] for plant in Plants, genco in GenCos) /
        1000*ExchangeRate[area]
    end
    WriteDisk(db,"EOutput/DVCost",year,DVCost)

    #
    # Direct Access Contracts - Fixed Costs
    #
    for area in Areas
      for plant in Plants, genco in GenCos
        TempValueAGP[area,genco,plant] =
          maximum(Capacity[area,genco,plant,timep,month] for month in Months, timep in TimePs)
      end
      DCCost[area] = sum(TempValueAGP[area,genco,plant]*UCCost[area,genco,plant] for
        plant in Plants, genco in GenCos)/1000*ExchangeRate[area]
    end
    WriteDisk(db,"EOutput/DCCost",year,DCCost)

  end

  function PowerPurchases(data::Data)
    (; db,year) = data
    (; Areas,Months,PPSet,TimePs) = data
    (; DCCost,DVCost,PPCT,PPEGTM,PPVCost,PUCT,PUCTBI,PUCTSM) = data

    ppset = Select(PPSet,"BasePP")
    for area in Areas
      PPCT[ppset,area] = sum(PPEGTM[area,timep,month]*PPVCost[ppset,month,area] for
        month in Months, timep in TimePs)/1000
    end
    WriteDisk(db,"EOutput/PPCT",year,PPCT)

    #
    # Power Purchases (Spot, Contract, Total)
    #
    for area in Areas
      PUCTSM[area] = PPCT[ppset,area]
      PUCTBI[area] = DVCost[area]+DCCost[area]
      PUCT[area] = PUCTBI[area]+PUCTSM[area]
    end
    WriteDisk(db,"EOutput/PUCTSM",year,PUCTSM)
    WriteDisk(db,"EOutput/PUCTBI",year,PUCTBI)
    WriteDisk(db,"EOutput/PUCT",year,PUCT)
  end

  function UnitCostofPurchasedPower(data::Data)
    (; db,year) = data
    (; Areas) = data
    (; PPUC,PUCT,TSales) = data

    @. @finite_math PPUC[Areas] = PUCT[Areas]/TSales[Areas]*1000
    WriteDisk(db,"EOutput/PPUC",year,PPUC)
  end

  function ImportsExportsFinancials(data::Data)
    (; db,year) = data
    (; AreaPurchases,AreaSales,ExportsRevenues,
      ExpPurchases,ExpSales,HMPrA,ImportsExpenditures) = data

    @. ImportsExpenditures = (AreaPurchases+ExpPurchases)*HMPrA/1000
    WriteDisk(db,"SOutput/ImportsExpenditures",year,ImportsExpenditures)
    #
    @. ExportsRevenues = (AreaSales+ExpSales)*HMPrA/1000
    WriteDisk(db,"SOutput/ExportsRevenues",year,ExportsRevenues)
  end

  function ElectricCosts(data::Data)

    # @info "  ERetailPowerCosts.jl - ElectricCosts"

    SpotMarketPriceByReCoArea(data)
    SpotPriceByPowerType(data)
    ContractVariableCost(data)
    ContractCosts(data)
    PowerPurchases(data)
    UnitCostofPurchasedPower(data)
    ImportsExportsFinancials(data)
  end
end # module ERetailPowerCosts
