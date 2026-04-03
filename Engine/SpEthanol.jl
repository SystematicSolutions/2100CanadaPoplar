#
# SpEthanol.jl
#

module SpEthanol

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime,DT
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaDS")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ES::SetArray = ReadDisk(db,"MainDB/ESDS")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Nation::SetArray = ReadDisk(db,"MainDB/NationDS")
  Poll::SetArray = ReadDisk(db,"MainDB/PollDS")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  DmdES::VariableArray{3} = ReadDisk(db,"SOutput/DmdES",year) #[ES,Fuel,Area,Year]  Energy Demand (TBtu/Yr)
  EuPol::VariableArray{3} = ReadDisk(db,"SOutput/EuPol",year) #[ECC,Poll,Area,Year]  Enduse Energy Related Pollution (Tonnes/Yr)  EtCCN::Float32 = ReadDisk(db,"SpInput/EtCCN",year) #[Year]  Ethanol Production Capital Costs (Real $/mmBtu/Yr)
  EtCCNNext::Float32 = ReadDisk(db,"SpInput/EtCCN",next) #[Year]  Ethanol Production Capital Costs (Real $/mmBtu/Yr)
  EtCR::VariableArray{2} = ReadDisk(db,"SpOutput/EtCR") #[Area,Year]  Ethanol Production Capacity Completion Rate (TBtu/Yr)
  EtCRR::VariableArray{1} = ReadDisk(db,"SpOutput/EtCRR",year) #[Area,Year]  Ethanol Production Capacity Retirement Rate (TBtu/Yr)
  EtCap::VariableArray{1} = ReadDisk(db,"SpOutput/EtCap",year) #[Area,Year]  Ethanol Production Capacity (TBtu/Yr)
  EtCCR::VariableArray{1} = ReadDisk(db,"SpOutput/EtCCR",year) #[Area,Year]  Ethanol Production Capital Charge Rate
  EtDChgNext::VariableArray{1} = ReadDisk(db,"SpInput/EtDChg",next) #[Area,Year]  Ethanol Delivery Charge (Real $/mmBtu)
  EtDemand::VariableArray{1} = ReadDisk(db,"SpOutput/EtDemand",year) #[Area,Year]  Ethanol Demand (TBtu/Yr)
  EtENPNNext::VariableArray{1} = ReadDisk(db,"SpOutput/EtENPN",next) #[Nation,Year]  Ethanol Wholesale Price ($/mmBtu)
  EtGExp::VariableArray{1} = ReadDisk(db,"SpOutput/EtGExp",year) #[Area,Year]  Ethanol Government Expenses (M$/Yr)
  EtPCon::VariableArray{1} = ReadDisk(db,"SpOutput/EtPCon",year) #[Area,Year]  Ethanol Producer Consumption (TBtu/Yr)
  EtPCnFr::VariableArray{1} = ReadDisk(db,"SpInput/EtPCnFr",year) #[Area,Year]  Ethanol Producer Consumption Fraction (Btu/Btu)
  EtPExp::VariableArray{1} = ReadDisk(db,"SpOutput/EtPExp",year) #[Area,Year]  Ethanol Private Expenses (M$/Yr)
  EtPL::Float32 = ReadDisk(db,"SpInput/EtPL",year) #[Year]  Ethanol Production Physical Lifetime (Years)
  EtPOCX::VariableArray{2} = ReadDisk(db,"SpInput/EtPOCX",year) #[Poll,Area,Year]  Ethanol Pollution Coefficient (Tonnes/TBtu)
  EtPol::VariableArray{2} = ReadDisk(db,"SpOutput/EtPol",year) #[Poll,Area,Year]  Ethanol Production Pollution (Tonnes/Yr)
  EtProd::VariableArray{1} = ReadDisk(db,"SpOutput/EtProd",year) #[Area,Year]  Ethanol Production (TBtu/Yr)
  EtSubsidy::VariableArray{1} = ReadDisk(db,"SpInput/EtSubsidy",year) #[Nation,Year]  Ethanol Production Subsidy ($/mmBtu)
  EtSubsidyNext::VariableArray{1} = ReadDisk(db,"SpInput/EtSubsidy",next) #[Nation,Year]  Ethanol Production Subsidy ($/mmBtu)
  EtUOMC::Float32 = ReadDisk(db,"SpInput/EtUOMC",year) #[Year]  Ethanol Production O&M Costs (Real $/mmBtu)
  EtUOMCNext::Float32 = ReadDisk(db,"SpInput/EtUOMC",next) #[Year]  Ethanol Production O&M Costs (Real $/mmBtu)
  FPFNext::VariableArray{3} = ReadDisk(db,"SOutput/FPF",next) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationNext::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",next) #[Area,Year]  Inflation Index ($/$)
end

function EthanolSupply(data::Data)
  (; db,year) = data
  (; Area,ECC,ES,Fuel,Nation,Poll) = data
  (; ANMap,DmdES,EuPol,EtCap,EtCCN,EtCR,EtCRR) = data
  (; EtDemand,EtGExp,EtPCnFr,EtPCon,EtPExp) = data
  (; EtPL,EtPOCX,EtPol,EtProd,EtSubsidy,EtUOMC,Inflation) = data

  #
  # Ethanol Supply
  #
  # Ethanol Demands are all from the transportation sector and
  # stored in the Biomass fuel.
  #

  biomass = Select(Fuel,"Biomass")
  es_trans = Select(ES,"Transportation")

  for area in Select(Area)
    EtDemand[area] = sum(DmdES[es,fuel,area] for fuel in biomass, es in es_trans)
  end

  #
  # Ethanol Production Capacity Retirement Rate
  #
  EtRYear::Int = max(1,year-EtPL)
  for area in Select(Area)
    EtCRR[area] = EtCR[area,EtRYear]
  end

  #
  # Ethanol Production Capacity Completion Rate
  #
  for area in Select(Area)
    EtCR[area,year] = max(0,EtDemand[area]-EtCap[area]+EtCRR[area])
  end

  #
  # Ethanol Production Capacity
  #
  for area in Select(Area)
    EtCap[area] = EtCap[area]+DT*(EtCR[area,year]-EtCRR[area])
  end

  #
  # Ethanol Production
  #
  for area in Select(Area)
    EtProd[area] = min(EtDemand[area],EtCap[area])
  end

  #
  # Ethanol Producer Consumption
  #
  for area in Select(Area)
    EtPCon[area] = EtProd[area]*EtPCnFr[area]
  end

  WriteDisk(db,"SpOutput/EtDemand",year,EtDemand)
  WriteDisk(db,"SpOutput/EtCap",year,EtCap)
  WriteDisk(db,"SpOutput/EtCR",EtCR)
  WriteDisk(db,"SpOutput/EtCRR",year,EtCRR)
  WriteDisk(db,"SpOutput/EtPCon",year,EtPCon)
  WriteDisk(db,"SpOutput/EtProd",year,EtProd)

  ##########################

  #
  # Ethanol Private Expenses
  #
  for area in Select(Area)
    EtPExp[area] = (EtCR[area,year]*EtCCN+EtProd[area]*EtUOMC)*Inflation[area]
  end

  #
  # Ethanol Government Expenses
  #
  for nation in Select(Nation)
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1.0
        EtGExp[area] = EtProd[area]*EtSubsidy[nation]
      end
    end
  end

  WriteDisk(db,"SpOutput/EtGExp",year,EtGExp)
  WriteDisk(db,"SpOutput/EtPExp",year,EtPExp)

  ##########################

  #
  # Ethanol Producer Emissions
  #
  for area in Select(Area), poll in Select(Poll)
    EtPol[poll,area] = EtPCon[area]*EtPOCX[poll,area]
  end

  WriteDisk(db,"SpOutput/EtPol",year,EtPol)

  ecc = Select(ECC,"Biofuel Production")
  for area in Select(Area), poll in Select(Poll)
    EuPol[ecc,poll,area] = EtPol[poll,area]
  end

  WriteDisk(db,"SOutput/EuPol",year,EuPol)

end

function PriceEthanol(data::Data)
  (; db,next) = data
  (; ES,Fuel,Nation) = data
  (; ANMap,EtENPNNext,EtCCR,EtCCNNext) = data
  (; EtDChgNext,EtSubsidyNext,EtUOMCNext) = data
  (; FPFNext,InflationNext) = data

  #
  # Ethanol Price
  #
  # 23.10.05, ljd: Added loops
  for nation in Select(Nation)
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1.0
        EtENPNNext[nation] = (EtCCR[area]*EtCCNNext+EtUOMCNext)*InflationNext[area]-EtSubsidyNext[nation]
      end
    end
  end

  WriteDisk(db,"SpOutput/EtENPN",next,EtENPNNext)

  ethanol = Select(Fuel,"Ethanol")

  for nation in Select(Nation)
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1.0
        for es in Select(ES)
          FPFNext[ethanol,es,area] = EtENPNNext[nation]+EtDChgNext[area]*InflationNext[area]
        end
      end
    end
  end

  WriteDisk(db,"SOutput/FPF",next,FPFNext)
end

end # module SpEthanol
