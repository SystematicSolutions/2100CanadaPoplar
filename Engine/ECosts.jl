#
# ECosts.jl
#

module ECosts

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime,First
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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  UnGenCo::SetArray = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
  UnArea::SetArray = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
  UnNode::SetArray = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
  UnPlant::SetArray = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CCR::VariableArray{2} = ReadDisk(db,"EGOutput/CCR",year) #[Plant,Area]  Capital Charge Rate (1/Yr)
  CoverageCFS::VariableArray{3} = ReadDisk(db,"SInput/CoverageCFS",year) #[Fuel,ECC,Area,Year]  Coverage fro CFS (1=Covered)
  DPRSL::VariableArray{1} = ReadDisk(db,"EGInput/DPRSL",year) #[Area,Year]  Straight Line Depreciation Rate (1/Yr)
  ECFPAdder::VariableArray{3} = ReadDisk(db,"EGInput/ECFPAdder",year) #[FuelEP,Month,Area,Year]  Monthly Fuel Price Adder ($/mmBtu)
  ECFPFuel::VariableArray{2} = ReadDisk(db,"EGOutput/ECFPFuel",year) #[FuelEP,Area,Year]  Fuel Price ($/mmBtu)
  ECFPMinMult::Float32 = ReadDisk(db,"EGInput/ECFPMinMult",year) #[Year]  Minimum Monthly Fuel Price Multiplier ($/mmBtu)
  ECFPMonth::VariableArray{3} = ReadDisk(db,"EGOutput/ECFPMonth",year) #[FuelEP,Month,Area,Year]  Monthly Fuel Price ($/mmBtu)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FPEU0::VariableArray{2} = ReadDisk(db,"EGOutput/FPEU",First) #[Plant,Area,First]  Electric Utility Fuel Prices ($/mmBtu)
  FPCFSFuel::VariableArray{3} = ReadDisk(db,"SOutput/FPCFSFuel",year) #[Fuel,ES,Area,Year]  CFS Price ($/mmBtu)
  FPEmissions::VariableArray{2} = ReadDisk(db,"EGOutput/FPEmissions",year) #[Fuel,Area,Year]  Emission Price ($/mmBtu)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FuelLimit::VariableArray{2} = ReadDisk(db,"SCalDB/FuelLimit",year) # [Fuel,Area,Year] 'Fuel Limit Multiplier (Btu/Btu)'
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationUnit::VariableArray{1} = ReadDisk(db,"MOutput/InflationUnit",year) #[Unit,Year]  Inflation Index ($/$)
  InflationUS::Float32 = ReadDisk(db,"MOutput/InflationNation",year)[Select(Nation,"US")] #[PointerUS,Year]  Inflation Index ($/$)
  LLPoTxR::VariableArray{3} = ReadDisk(db,"EGOutput/LLPoTxR",year) #[Node,NodeX,Market,Year]  Pollution Costs for Transmission (US$/MWh)
  LLPoTxRExo::VariableArray{2} = ReadDisk(db,"EGInput/LLPoTxRExo",year) #[Node,NodeX,Year]  Exogenous Pollution Costs for Transmission (Real US$/MWH)
  LLVC::VariableArray{2} = ReadDisk(db,"EGOutput/LLVC",year) #[Node,NodeX,Year]  Transmission Rate (US$/MWh)
  NuclearFuelCost::VariableArray{1} = ReadDisk(db,"EGInput/NuclearFuelCost",year) #[Area,Year]  Nuclear Fuel Costs ($/MWh)
  StorageUnitCosts::VariableArray{1} = ReadDisk(db,"EGOutput/StorageUnitCosts",year) #[Area,Year]  Storage Energy Unit Costs ($/MWh)
  UnAFC::VariableArray{1} = ReadDisk(db,"EGOutput/UnAFC",year) #[Unit,Year]  Average Fixed Costs ($/KW)
  UnAVCMonth::VariableArray{2} = ReadDisk(db,"EGOutput/UnAVCMonth",year) #[Unit,Month,Year]  Average Monthly Variable Costs ($/MWh)
  UnCode::Vector{String} = ReadDisk(db,"EGInput/UnCode") #[Unit]  Unit Code
  UnCounter::Float32 = ReadDisk(db,"EGInput/UnCounter",year) #[Year]  Number of Units
  UnCWGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnCWGA",year) #[Unit,Year]  Construction Costs to Gross Assets ($M)
  UnFlFr::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFr",year) #[Unit,FuelEP,Year]  Fuel Fraction (Btu/Btu)
  UnFlFrMarginal::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFrMarginal",year) #[Unit,FuelEP,Year]  Fuel Fraction Marginal Market Share (Btu/Btu)
  UnFlFrMSF::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFrMSF",year) #[Unit,FuelEP,Year]  Fuel Fraction Market Share (Btu/Btu)
  UnFlFrMSM0::VariableArray{2} = ReadDisk(db,"EGCalDB/UnFlFrMSM0",year) #[Unit,FuelEP,Year]  Fuel Fraction Non-Price Factor (Btu/Btu)
  UnFlFrMax::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrMax",year) #[Unit,FuelEP,Year]  Fuel Fraction Maximum (Btu/Btu)
  UnFlFrMin::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrMin",year) #[Unit,FuelEP,Year]  Fuel Fraction Minimum (Btu/Btu)
  UnFlFrPrior::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFr",prior) #[Unit,FuelEP,Prior]  Fuel Fraction in Previous year (Btu/Btu)
  UnFlFrTime::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrTime",year) #[Unit,FuelEP,Year]  Fuel Adjustment Time (Years)
  UnFlFrVF::VariableArray{2} = ReadDisk(db,"EGInput/UnFlFrVF") #[Unit,FuelEP]  Fuel Fraction Variance Factor (Btu/Btu)
  UnFP::VariableArray{2} = ReadDisk(db,"EGOutput/UnFP",year) #[Unit,Month,Year]  Fuel Price ($/mmBtu)
  UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Gross Generating Capacity (MW)
  UnHRt::VariableArray{1} = ReadDisk(db,"EGInput/UnHRt",year) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnNA::VariableArray{1} = ReadDisk(db,"EGOutput/UnNA",year) #[Unit,Year]  Net Asset Value of Generating Unit (M$)
  UnPoTR::VariableArray{1} = ReadDisk(db,"EGOutput/UnPoTR",year) #[Unit,Year]  Pollution Tax Rate ($/MWh)
  UnPoTRExo::VariableArray{1} = ReadDisk(db,"EGInput/UnPoTRExo",year) #[Unit,Year]  Exogenous Pollution Tax Rate (Real $/MWh)
  UnRCGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnRCGA",year) #[Unit,Year]  Emission Reduction Capital Costs (M$/Yr)
  UnRCOM::VariableArray{1} = ReadDisk(db,"EGOutput/UnRCOM",year) #[Unit,Year]  Emission Reduction O&M Costs (M$/Yr)
  UnSLDPR::VariableArray{1} = ReadDisk(db,"EGOutput/UnSLDPR",year) #[Unit,Year]  Depreciation (M$/Yr)
  UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") #[Unit]  Storage Switch (1=Storage Unit)
  UnUFOMC::VariableArray{1} = ReadDisk(db,"EGInput/UnUFOMC",year) #[Unit,Year]  Fixed O&M Costs (Real $/Kw/Yr)
  UnUOMC::VariableArray{1} = ReadDisk(db,"EGInput/UnUOMC",year) #[Unit,Year]  Variable O&M Costs (Real $/MWH)
  xLLVC::VariableArray{2} = ReadDisk(db,"EGInput/xLLVC",year) #[Node,NodeX,Year]  Transmission Rate (Real US$/MWh)
  UnNAPrior::VariableArray{1} = ReadDisk(db,"EGOutput/UnNA",prior) #[Unit,Year]  Net Asset Value of Generating Unit (M$)
  UnRCOMPrior::VariableArray{1} = ReadDisk(db,"EGOutput/UnRCOM",prior) #[Unit,Year]  Emission Reduction O&M Costs (M$/Yr)

  UnFlFrMAW::VariableArray{2} = zeros(Float32,length(Unit),length(FuelEP)) # [Unit,FuelEP] Allocation Weights for Fuel Fraction (DLess)
  UnFlFrTMAW::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit] Total of Allocation Weights for Fuel Fraction (DLess)
  UnFlFrTotal::VariableArray{1} = zeros(Float32,length(Unit)) # [Unit] Total of Fuel Fractions (Btu/Btu)
end

function GetUnitSets(data::Data,unit)
  (; Area,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant) = data

  genco = Select(GenCo,UnGenCo[unit])
  plant = Select(Plant,UnPlant[unit])
  node = Select(Node,UnNode[unit])
  area = Select(Area,UnArea[unit])

  return genco,plant,node,area

end

function TPrice(data::Data)
  #@debug "TPrice function within ECost.jl is called"
  (; db,year) = data
  (; Areas,ECC,ES,Months) = data
  (; Fuels,FuelEPs) = data
  (; FPEmissions,FPCFSFuel,CoverageCFS) = data
  (; ECFPFuel,FPF,FFPMap,ECFPMonth,ECFPAdder,ECFPMinMult,Inflation) = data

  select_ecc = Select(ECC,"UtilityGen")
  select_es = Select(ES,"Electric")

  for fuel in Fuels,area in Areas
    FPEmissions[fuel,area] = FPCFSFuel[fuel,select_es,area] *
      CoverageCFS[fuel,select_ecc,area]
  end
  WriteDisk(db,"EGOutput/FPEmissions",year,FPEmissions)
  #@debug "FPEmissions calculated"

  for fuelep in FuelEPs,area in Areas
    ECFPFuel[fuelep,area] = sum((FPF[fuel,select_es,area]+
      FPEmissions[fuel,area])*FFPMap[fuelep,fuel] for fuel in Fuels)
    ECFPFuel[fuelep,area] = max(ECFPFuel[fuelep,area],0.001)
  end
  WriteDisk(db,"EGOutput/ECFPFuel",year,ECFPFuel)
  #@debug "ECFPFuel calculated"

  for fuelep in FuelEPs,month in Months,area in Areas
    ECFPMonth[fuelep,month,area] = max(ECFPFuel[fuelep,area]+
      ECFPAdder[fuelep,month,area]*Inflation[area],
      ECFPFuel[fuelep,area]*ECFPMinMult)
  end
  WriteDisk(db,"EGOutput/ECFPMonth",year,ECFPMonth)
  #@debug "ECFPFuel calculated"

end

function Depreciation(data::Data,unit,area)
  #@debug "Depreciation function within ECost.jl is called"
  (; UnSLDPR,UnNAPrior,DPRSL) = data

  UnSLDPR[unit] = UnNAPrior[unit]*DPRSL[area]

  #@debug "UnSLDPR calculated for unit $unit"

end

function NetAssets(data::Data,unit)
  #@debug "NetAssets function within ECost.jl is called"
  (; UnNA,UnCWGA,UnSLDPR,UnRCGA,UnNAPrior) = data

  UnNA[unit] = UnNAPrior[unit]+UnCWGA[unit]-UnSLDPR[unit]+UnRCGA[unit]
  #@debug "UnNA calculated for unit $unit"
end


function FixedCosts(data::Data,unit,plant,area)
  #@debug "FixedCosts function within ECost.jl is called"
  (; UnNA,UnAFC,UnSLDPR,CCR,UnRCOMPrior,UnGC,UnUFOMC,InflationUnit) = data

  @finite_math UnAFC[unit] = (UnNA[unit]*CCR[plant,area]+UnSLDPR[unit]+UnRCOMPrior[unit])/
      UnGC[unit]*1000+UnUFOMC[unit]*InflationUnit[unit]
      
  #@debug "UnAFC calculated for unit $unit"
end

function UnitFuelPrices(data::Data,unit,genco,plant,node,area)
  #@debug "UnitFuelPrices function within ECost.jl is called"
  (; Months,FuelEP,FuelEPs,UnCode,UnPlant) = data
  (; UnFP,UnFlFrPrior,ECFPMonth,NuclearFuelCost,InflationUnit,UnHRt) = data

  for month in Months
    UnFP[unit,month] = 0.0
    for fuelep in FuelEPs
      UnFP[unit,month] = UnFP[unit,month]+UnFlFrPrior[unit,fuelep]*ECFPMonth[fuelep,month,area]
    end
  end

  if UnPlant[unit] == "Nuclear" || UnPlant[unit] == "SMNR"
    for month in Months
      @finite_math UnFP[unit,month] = NuclearFuelCost[area]*InflationUnit[unit]/UnHRt[unit]*1000
    end
  end

end

function Fungible(data::Data,unit,area,plant)
  #@debug "Fungible function within ECost.jl is called"
  (; Fuels,FuelEPs) = data;
  (; FFPMap,UnFlFrMAW,UnFlFrMarginal,UnFlFrMSM0,UnFlFrVF,ECFPFuel,FPEU0) = data;
  (; UnFlFrTMAW,UnFlFrMSF,UnFlFrMin,UnFlFrMax,UnFlFrTotal) = data;
  (; UnFlFr,UnFlFrPrior,UnFlFrTime,FuelLimit) = data;

  for fuelep in FuelEPs
    if (ECFPFuel[fuelep,area] > 0 && FPEU0[plant,area] > 0) ||
       UnFlFrMSM0[unit,fuelep] > -100.00
      @finite_math UnFlFrMAW[unit,fuelep] = exp(UnFlFrMSM0[unit,fuelep]+
        UnFlFrVF[unit,fuelep]*log(ECFPFuel[fuelep,area]/FPEU0[plant,area]))
    else
      UnFlFrMAW[unit,fuelep] = 0.0
    end
  end
  
  UnFlFrTMAW[unit] = sum(UnFlFrMAW[unit,fuelep] for fuelep in FuelEPs)
  
  for fuelep in FuelEPs
    @finite_math UnFlFrMSF[unit,fuelep] = UnFlFrMAW[unit,fuelep]/UnFlFrTMAW[unit]
  end

  #
  # Apply Minimums and Maximums
  #  
  for fuelep in FuelEPs
    UnFlFrMarginal[unit,fuelep] = UnFlFrMSF[unit,fuelep]
  end
  
  UnFlFrCount::Int = 1
  while UnFlFrCount < 10
    for fuelep in FuelEPs
      for fuel in Fuels
        if FFPMap[fuelep,fuel] == 1
          UnFlFrMarginal[unit,fuelep] = 
            min(max(UnFlFrMarginal[unit,fuelep],UnFlFrMin[unit,fuelep]),
            UnFlFrMax[unit,fuelep])*FuelLimit[fuel,area]
        end
      end
    end
    
    UnFlFrTotal[unit] = 0.0
    for fuelep in FuelEPs
      UnFlFrTotal[unit] = UnFlFrTotal[unit]+UnFlFrMarginal[unit,fuelep]
    end
    
    #UnFlFrTotal[unit] = sum(UnFlFrMarginal[unit,fuelep] for fuelep in FuelEP)
    
    for fuelep in FuelEPs
      @finite_math UnFlFrMarginal[unit,fuelep] = UnFlFrMarginal[unit,fuelep]/UnFlFrTotal[unit]
    end
    UnFlFrCount = UnFlFrCount+1
  end
  
  for fuelep in FuelEPs
    UnFlFr[unit,fuelep] = UnFlFrPrior[unit,fuelep]+
      (UnFlFrMarginal[unit,fuelep]-UnFlFrPrior[unit,fuelep])/UnFlFrTime[unit,fuelep]
  end
  
  UnFlFrTotal[unit] = 0.0
  for fuelep in FuelEPs
    UnFlFrTotal[unit] = UnFlFrTotal[unit]+UnFlFrMarginal[unit,fuelep]
  end
  
  #UnFlFrTotal[unit] = sum(UnFlFr[unit,fuelep] for fuelep in FuelEP)
  
  for fuelep in FuelEPs  
    @finite_math UnFlFr[unit,fuelep] = UnFlFr[unit,fuelep]/UnFlFrTotal[unit]
  end

end

function MonthlyVariableCosts(data::Data,unit,area)
  #@debug "MonthlyVariableCosts function within ECost.jl is called"
  (; Months) = data
  (; UnAVCMonth,UnFP,UnHRt,UnUOMC,InflationUnit) = data
  (; UnPoTR,UnPoTRExo,UnStorage,StorageUnitCosts) = data

  for month in Months
    UnAVCMonth[unit,month] = UnFP[unit,month]*UnHRt[unit]/1000+
      UnUOMC[unit]*InflationUnit[unit]+UnPoTR[unit]+UnPoTRExo[unit]*InflationUnit[unit]
  end

  # The TimeP is not needed anymore.
  # Select TimeP(TimeP:m)

  if UnStorage[unit] == 1
    for month in Months
      UnAVCMonth[unit,month] = StorageUnitCosts[area]+UnUOMC[unit]*
      InflationUnit[unit]+UnPoTR[unit]+UnPoTRExo[unit]*InflationUnit[unit]
    end
  end

  #@debug "UnAVCMonth calculated for unit $unit"

end

function Costs(data::Data)
  #@debug "Costs function within ECost.jl is called"
  (; db,year) = data;
  (; UnCounter,Nodes,Markets) = data;
  (; LLVC,InflationUS,LLPoTxR,LLPoTxRExo,xLLVC,UnAVCMonth) = data;
  (; UnFlFr,UnFlFrMarginal,UnFlFrMSF,UnSLDPR,UnNA,UnAFC,UnFP) = data;

  TPrice(data)
  for unit in 1:Int(UnCounter)
    genco,plant,node,area = GetUnitSets(data,unit)
    if !isempty(plant)
      Depreciation(data,unit,area)
      NetAssets(data,unit)
      FixedCosts(data,unit,plant,area)
      UnitFuelPrices(data,unit,genco,plant,node,area)
      Fungible(data,unit,area,plant)
      MonthlyVariableCosts(data,unit,area)
    end
  end

  for node in Nodes,nodex in setdiff(Nodes,node)
    LLVC[node,nodex] = xLLVC[node,nodex]*InflationUS+
      sum(LLPoTxR[node,nodex,mkt] for mkt in Markets)+
      LLPoTxRExo[node,nodex]*InflationUS
  end

  WriteDisk(db,"EGOutput/LLVC",year,LLVC)
  WriteDisk(db,"EGOutput/UnSLDPR",year,UnSLDPR)
  WriteDisk(db,"EGOutput/UnNA",year,UnNA)
  WriteDisk(db,"EGOutput/UnAFC",year,UnAFC)
  WriteDisk(db,"EGOutput/UnFP",year,UnFP)
  WriteDisk(db,"EGOutput/UnFlFr",year,UnFlFr) 
  WriteDisk(db,"EGOutput/UnFlFrMarginal",year,UnFlFrMarginal)  
  WriteDisk(db,"EGOutput/UnFlFrMSF",year,UnFlFrMSF) 
  WriteDisk(db,"EGOutput/UnAVCMonth",year,UnAVCMonth)

end

end # Module ECosts
