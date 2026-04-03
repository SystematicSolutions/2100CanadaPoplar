#
# Mreductions.jl
#

module MReductions

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

  Yr2012 = 2012-ITime+1
  Yr2013 = 2013-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))

  Level::SetArray = ReadDisk(db,"MainDB/LevelKey")
  Levels::Vector{Int} = collect(Select(Level))

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  
  Offset::SetArray = ReadDisk(db,"MainDB/OffsetKey")
  Offsets::Vector{Int} = collect(Select(Offset))

  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovs::Vector{Int} = collect(Select(PCov))

  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  eCO2Price::VariableArray{1} = ReadDisk(db,"SOutput/eCO2Price",year) #[Area,Year]  Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  eCO2PriceExo::VariableArray{1} = ReadDisk(db,"SInput/eCO2PriceExo",year) #[Area,Year]  Carbon Tax plus Permit Cost (Real $/eCO2 Tonnes)
  ECoverage::VariableArray{4} = ReadDisk(db,"SInput/ECoverage",year) #[ECC,Poll,PCov,Area,Year]  Emissions Permit Coverage (Tonnes/Tonnes)
  FlInv::VariableArray{2} = ReadDisk(db,"SOutput/FlInv",year) #[ECC,Area,Year]  Flaring Reduction Investments (M$/Yr)
  FlPOCX::VariableArray{3} = ReadDisk(db,"MEInput/FlPOCX",year) #[ECC,Poll,Area,Year]  Flaring Emissions Coefficient (Tonnes/Driver)
  FlReduce::VariableArray{3} = ReadDisk(db,"SOutput/FlReduce",year) #[ECC,Poll,Area,Year]  Flaring Reductions (Tonnes/Yr)
  FPCFSCredit::VariableArray{3} = ReadDisk(db,"SOutput/FPCFSCredit",year) #[Fuel,ES,Area,Year]  CFS Credit Price ($/Tonnes)
  FPCFSObligated::VariableArray{2} = ReadDisk(db,"SOutput/FPCFSObligated",year) #[ECC,Area,Year]  CFS Price for Obligated Sectors ($/Tonnes)
  FuInv::VariableArray{2} = ReadDisk(db,"SOutput/FuInv",year) #[ECC,Area,Year]  Other Fugitives Reduction Investments (M$/Yr)
  FuOMExp::VariableArray{2} = ReadDisk(db,"SOutput/FuOMExp",year) #[ECC,Area,Year]  Other Fugitives Reduction O&M Expenses (M$/Yr)
  FuPOCX::VariableArray{3} = ReadDisk(db,"MEInput/FuPOCX",year) #[ECC,Poll,Area,Year]  Other Fugitive Emissions Coefficient (Tonnes/Driver)
  FuReduce::VariableArray{3} = ReadDisk(db,"SOutput/FuReduce",year) #[ECC,Poll,Area,Year]  Other Fugitives Reductions (Tonnes/Yr)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  InflationYr::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") #[Area,Year]  Inflation Index ($/$)
  InSm::VariableArray{1} = ReadDisk(db,"MOutput/InSm",year) #[Area,Year]  Smoothed Inflation Rate (1/Yr)

  KJBtu = 1.054615

  MEDriver::VariableArray{2} = ReadDisk(db,"MOutput/MEDriver",year) #[ECC,Area,Year]  Driver for Process Emissions (Various Millions/Yr)
  MEInv::VariableArray{2} = ReadDisk(db,"SOutput/MEInv",year) #[ECC,Area,Year]  Non Energy Reduction Investments (M$/Yr)
  MEOMExp::VariableArray{2} = ReadDisk(db,"SOutput/MEOMExp",year) #[ECC,Area,Year]  Non Energy Reduction O&M Expenses(M$/Yr)
  MEPOCX::VariableArray{3} = ReadDisk(db,"MEInput/MEPOCX",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution Coefficient (Tonnes/Economic Driver)
  MEReduce::VariableArray{3} = ReadDisk(db,"SOutput/MEReduce",year) #[ECC,Poll,Area,Year]  Non Energy Reductions (Tonnes/Yr)
  PCost::VariableArray{3} = ReadDisk(db,"SOutput/PCost",year) #[ECC,Poll,Area,Year]  Permit Cost (Real $/Tonnes)
  PCostExo::VariableArray{3} = ReadDisk(db,"SInput/PCostExo",year) #[ECC,Poll,Area,Year]  Exogenous Permit Cost (Real $/Tonnes)
  ReA0::VariableArray{2} = ReadDisk(db,"MEInput/ReA0") #[Offset,Area]  A Term in Reduction Curve ($/Tonne)
  ReB0::VariableArray{2} = ReadDisk(db,"MEInput/ReB0") #[Offset,Area]  B Term in Reduction Curve ($/Tonne)
  ReC0::VariableArray{2} = ReadDisk(db,"MEInput/ReC0",year) #[Offset,Area,Year]  C Term in Reduction Curve (Tonnes/Yr)
  ReC2H6PerCH4::VariableArray{2} = ReadDisk(db,"MEInput/ReC2H6PerCH4",year) #[Offset,Area,Year]  Flaring C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  ReCapacity::VariableArray{2} = ReadDisk(db,"MEOutput/ReCapacity",year) #[Offset,Area,Year]  Reduction Capacity (Tonnes/Yr)
  ReCapacityPrior::VariableArray{2} = ReadDisk(db,"MEOutput/ReCapacity",prior) #[Offset,Area,Prior]  Reduction Capacity (Tonnes/Yr)
  ReCapacityInitiated::VariableArray{2} = ReadDisk(db,"MEOutput/ReCapacityInitiated",year) #[Offset,Area,Year]  Reductions Capacity Initiation Rate (Tonnes/Yr/Yr)
  ReCapacityCompleted::VariableArray{2} = ReadDisk(db,"MEOutput/ReCapacityCompleted",year) #[Offset,Area,Year]  Reduction Capacity Completion Rate (Tonnes/Yr/Yr)
  ReCapacityRetirements::VariableArray{2} = ReadDisk(db,"MEOutput/ReCapacityRetirements",year) #[Offset,Area,Year]  Reduction Capacity Retirements (Tonnes/Yr/Yr)
  ReCapacityUnderConstruction::VariableArray{2} = ReadDisk(db,"MEOutput/ReCapacityUnderConstruction",year) #[Offset,Area,Year]  Reduction Capacity Under Construction (Tonnes/Yr/Yr)
  ReCaptured::VariableArray{3} = ReadDisk(db,"MEOutput/ReCaptured",year) #[Offset,Poll,Area,Year]  Reductions Captured (Tonnes/Yr)
  ReCapturedFraction::VariableArray{3} = ReadDisk(db,"MEInput/ReCapturedFraction",year) #[Offset,Poll,Area,Year]  Reductions Captured Fraction (Tonnes/Yr)
  ReCC::VariableArray{2} = ReadDisk(db,"MEOutput/ReCC",year) #[Offset,Area,Year]  Reduction Capital Cost ($/Tonne)
  ReCCA0::VariableArray{2} = ReadDisk(db,"MEInput/ReCCA0") #[Offset,Area]  A Term in Reduction Capital Cost Curve ($/$)
  ReCCB0::VariableArray{2} = ReadDisk(db,"MEInput/ReCCB0") #[Offset,Area]  B Term in Reduction Capital Cost Curve ($/$)
  ReCCC0::VariableArray{2} = ReadDisk(db,"MEInput/ReCCC0",year) #[Offset,Area,Year]  C Term in Reduction Capital Cost Curve ($/$)
  ReCCEm::VariableArray{2} = ReadDisk(db,"MEOutput/ReCCEm",year) #[Offset,Area,Year]  Reduction Embedded Capital Cost ($/Tonne)
  ReCCEmPrior::VariableArray{2} = ReadDisk(db,"MEOutput/ReCCEm",prior) #[Offset,Area,Prior]  Reduction Embedded Capital Cost ($/Tonne)
  ReCCR::VariableArray{2} = ReadDisk(db,"MEOutput/ReCCR",year) #[Offset,Area,Year]  Reduction Capital Charge Rate ($/$)
  ReCCReplace::VariableArray{2} = ReadDisk(db,"MEInput/ReCCReplace",year) #[Offset,Area,Year]  Reduction Replacement Capital Cost ($/Tonne CH4)
  ReCCSwitch::VariableArray{2} = ReadDisk(db,"MEInput/ReCCSwitch",year) #[Offset,Area,Year]  Reduction Capital Cost Switch (1=Default)
  ReCD::VariableArray{1} = ReadDisk(db,"MEInput/ReCD") #[Offset]  Reduction Construction Time (Years)
  ReCDOrder::VariableArray{1} = ReadDisk(db,"MEInput/ReCDOrder",year) #[Offset,Year]  Number of Levels Reduction Construction Delay (Number)
  ReCDInput::VariableArray{3} = ReadDisk(db,"MEOutput/ReCDInput",year) #[Level,Offset,Area,Year]  Input to Reduction Delay Level (Tonnes/Yr/Yr)
  ReCDLevel::VariableArray{3} = ReadDisk(db,"MEOutput/ReCDLevel",year) #[Level,Offset,Area,Year]  Reduction Delay Level (Tonnes/Yr)
  ReCDLevelPrior::VariableArray{3} = ReadDisk(db,"MEOutput/ReCDLevel",prior) #[Level,Offset,Area,Prior]  Reduction Delay Level (Tonnes/Yr)
  ReCDOutput::VariableArray{3} = ReadDisk(db,"MEOutput/ReCDOutput",year) #[Level,Offset,Area,Year]  Output from Reduction Delay Level (Tonnes/Yr/Yr)
  ReDevelopedFraction::VariableArray{2} = ReadDisk(db,"MEInput/ReDevelopedFraction",year) #[Offset,Area,Year]  Fraction of Captured Gas Developed into Electric Generating Capacity (MW/MW)
  ReECC::Vector{String} = ReadDisk(db,"MEInput/ReECC") #[Offset]  Reduction Economic Sector (Name)
  ReElectricPotentialFactor::VariableArray{2} = ReadDisk(db,"MEInput/ReElectricPotentialFactor",year) #[Offset,Area,Year]  Electric Generating Capacity Potential from Captured Gas Factor (MW/MT)
  ReGAProd::VariableArray{1} = ReadDisk(db,"SOutput/ReGAProd",year) #[Area,Year]  Natural Gas Produced from Reductions (TBtu/Yr)
  ReGProd::VariableArray{1} = ReadDisk(db,"SOutput/ReGProd",year) #[Nation,Year]  Natural Gas Produced from Reductions (TBtu/Yr)
  ReGProdOff::VariableArray{2} = ReadDisk(db,"MEOutput/ReGProdOff",year) #[Offset,Area,Year]  Natural Gas Produced from Reductions (TBtu/Yr)
  ReGC::VariableArray{2} = ReadDisk(db,"MEOutput/ReGC",year) #[Offset,Area,Year]  Electric Generating Capacity (MW/Yr)
  ReGCPrior::VariableArray{2} = ReadDisk(db,"MEOutput/ReGC",prior) #[Offset,Area,Prior]  Electric Generating Capacity (MW/Yr)
  ReGCCM::VariableArray{1} = ReadDisk(db,"SOutput/ReGCCM",year) #[Area,Year]  Incremental Electric Generating Capacity from Reductions (MW)
  ReGCCMOff::VariableArray{2} = ReadDisk(db,"MEOutput/ReGCCMOff",year) #[Offset,Area,Year]  Incremental Electric Generating Capacity from Reductions (MW)
  ReGExp::VariableArray{2} = ReadDisk(db,"MEOutput/ReGExp",year) #[Offset,Area,Year]  Government Expenses (M$/Yr)
  ReGFr::VariableArray{2} = ReadDisk(db,"MEInput/ReGFr",year) #[Offset,Area,Year]  Reduction Grant Fraction ($/$)
  ReInv::VariableArray{2} = ReadDisk(db,"MEOutput/ReInv",year) #[Offset,Area,Year]  Reduction Investments (M$/Yr)
  ReInvSwitch::VariableArray{2} = ReadDisk(db,"MEInput/ReInvSwitch",year) #[Offset,Area,Year]  Reduction Investment Switch (1=Default)
  ReIVTC::VariableArray{2} = ReadDisk(db,"MEInput/ReIVTC",year) #[Offset,Area,Year]  Reduction Investment Tax Credit ($/$)
  ReOCF::VariableArray{2} = ReadDisk(db,"MEInput/ReOCF",year) #[Offset,Area,Year]  Reduction Operating Cost Factor ($/$)
  ReOMExp::VariableArray{2} = ReadDisk(db,"MEOutput/ReOMExp",year) #[Offset,Area,Year]  Reduction O&M Expenses(M$/Yr)
  ReOMExpSwitch::VariableArray{2} = ReadDisk(db,"MEInput/ReOMExpSwitch",year) #[Offset,Area,Year]  Reduction O&M Expenses Switch (1=Default)
  RePExp::VariableArray{2} = ReadDisk(db,"MEOutput/RePExp",year) #[Offset,Area,Year]  Private Expenses (M$/Yr)
  RePL::VariableArray{2} = ReadDisk(db,"MEInput/RePL",year) #[Offset,Area,Year]  Reduction Physical Lifetime (Years)
  RePOCF::VariableArray{3} = ReadDisk(db,"MEInput/RePOCF",year) #[Offset,Poll,Area,Year]  Reduction Factor (Tonnes/Tonnes)
  RePol::VariableArray{2} = ReadDisk(db,"MEOutput/RePol",year) #[Offset,Area,Year]  Pollution (Tonnes/Yr)
  RePollutant::Vector{String} = ReadDisk(db,"MEInput/RePollutant") #[Offset]  Reduction Main Pollutant (Name)
  RePrice::VariableArray{2} = ReadDisk(db,"MEOutput/RePrice",year) #[Offset,Area,Year]  Emission Prices ($/Tonne)
  RePriceSwitch::VariableArray{2} = ReadDisk(db,"MEInput/RePriceSwitch",year) #[Offset,Area,Year]  Reduction Emission Price Switch (1=Default)
  RePriceX::VariableArray{2} = ReadDisk(db,"MEInput/RePriceX",year) #[Offset,Area,Year]  Emission Exogenous Prices ($/Tonne)
  ReReductions::VariableArray{3} = ReadDisk(db,"MEOutput/ReReductions",year) #[Offset,Poll,Area,Year]  Reductions (Tonnes/Yr)
  ReReductionsPrior::VariableArray{3} = ReadDisk(db,"MEOutput/ReReductions",prior) #[Offset,Poll,Area,Prior]  Reductions (Tonnes/Yr)
  ReReductionsIndicated::VariableArray{2} = ReadDisk(db,"MEOutput/ReReductionsIndicated",year) #[Offset,Area,Year]  Reductions Indicated (Tonnes/Yr)
  ReReductionsSwitch::VariableArray{2} = ReadDisk(db,"MEInput/ReReductionsSwitch",year) #[Offset,Area,Year]  Reductions Switch (1=Default)
  ReReductionsX::VariableArray{2} = ReadDisk(db,"MEInput/ReReductionsX",year) #[Offset,Area,Year]  Reductions Exogenous (Tonnes/Yr)
  ReROIN::VariableArray{2} = ReadDisk(db,"MEInput/ReROIN",year) #[Offset,Area,Year]  Reduction Return on Investment ($/$)
  ReRP::VariableArray{2} = ReadDisk(db,"MEOutput/ReRP",year) #[Offset,Area,Year]  Reduction (Tonnes/Tonnes)
  ReTL::VariableArray{2} = ReadDisk(db,"MEInput/ReTL",year) #[Offset,Area,Year]  Reduction Tax Lifetime (Years)
  ReTxRt::VariableArray{2} = ReadDisk(db,"MEInput/ReTxRt",year) #[Offset,Area,Year]  Reduction Tax Rate ($/$)
  ReType::Vector{String} = ReadDisk(db,"MEInput/ReType") #[Offset]  Reduction Type (Name)

  TBtuGasPerTonneCH4 = 55.577*KJBtu/1e6

  VnInv::VariableArray{2} = ReadDisk(db,"SOutput/VnInv",year) #[ECC,Area,Year]  Venting Reduction Investments (M$/Yr)
  VnOMExp::VariableArray{2} = ReadDisk(db,"SOutput/VnOMExp",year) #[ECC,Area,Year]  Venting Reduction O&M Expenses (M$/Yr)
  VnPOCX::VariableArray{3} = ReadDisk(db,"MEInput/VnPOCX",year) #[ECC,Poll,Area,Year]  Fugitive Venting Emissions Coefficient (Tonnes/Driver)
  VnReduce::VariableArray{3} = ReadDisk(db,"SOutput/VnReduce",year) #[ECC,Poll,Area,Year]  Venting Reductions (Tonnes/Yr)

  #
  # Scratch Variables
  #
  RePriceCurve::VariableArray{2} = zeros(Float32,length(Offset),length(Area))
end

function InitializeData(data::Data)
  (; Areas,ECCs,Polls) = data
  (; MEInv,MEOMExp,MEReduce) = data

  for area in Areas, ecc in ECCs
    MEInv[ecc,area] = 0.0
    MEOMExp[ecc,area] = 0.0
    for poll in Polls
      MEReduce[ecc,poll,area] = 0.0
    end
  end

end

function InitializeReductions(data::Data,area,ecc,offset)
  (; Poll) = data
  (; FlPOCX,FuPOCX,MEDriver,MEPOCX,ReECC,RePol,RePollutant,ReType,VnPOCX) = data
 
  poll = Select(Poll,RePollutant[offset])

  if ReType[offset] == "Venting"
    RePol[offset,area] = VnPOCX[ecc,poll,area]*MEDriver[ecc,area]
  elseif ReType[offset] == "Flaring"
    RePol[offset,area] = FlPOCX[ecc,poll,area]*MEDriver[ecc,area]
  elseif ReType[offset] == "Other Fugitives"
    RePol[offset,area] = FuPOCX[ecc,poll,area]*MEDriver[ecc,area]
  elseif ReType[offset] == "Process"
    if (ReECC[offset] == "Forestry") || (ReECC[offset] == "CropProduction") || (ReECC[offset] == "Wastewater") || (ReECC[offset] == "SolidWaste") || (ReECC[offset] == "AnimalProduction")
      RePol[offset,area] = 1.0E12
    else
      RePol[offset,area] = MEPOCX[ecc,poll,area]*MEDriver[ecc,area]
    end
  end

end

function EmissionPrices(data::Data,area,ecc,offset)
  (; ES,Fuel,PCov,Poll) = data
  (; eCO2Price,eCO2PriceExo,ECoverage,FPCFSCredit,FPCFSObligated) = data
  (; Inflation,PCost,PCostExo,RePollutant,RePrice,RePriceX,RePriceSwitch) = data

  poll = Select(Poll,RePollutant[offset])

  industrial = Select(ES,"Industrial")
  naturalgas = Select(Fuel,"NaturalGas")
  pcov = Select(PCov,"Process")

  if RePriceSwitch[offset,area] == 1
      RePrice[offset,area] = (PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area] +
                             PCostExo[ecc,poll,area])*Inflation[area] +
                             FPCFSCredit[naturalgas,industrial,area]*FPCFSObligated[ecc,area]
  elseif RePriceSwitch[offset,area] == 2
      RePrice[offset,area] = eCO2Price[area]+eCO2PriceExo[area]*Inflation[area] +
                             FPCFSCredit[naturalgas,industrial,area]*FPCFSObligated[ecc,area]
  elseif RePriceSwitch[offset,area] == 3
      RePrice[offset,area] = (PCost[ecc,poll,area]*ECoverage[ecc,poll,pcov,area] +
                            PCostExo[ecc,poll,area])*Inflation[area] +
                            FPCFSCredit[naturalgas,industrial,area]*FPCFSObligated[ecc,area]
  elseif RePriceSwitch[offset,area] == 4
      RePrice[offset,area] = eCO2Price[area]+eCO2Price[area]*Inflation[area] +
                             FPCFSCredit[naturalgas,industrial,area]*FPCFSObligated[ecc,area]
  elseif RePriceSwitch[offset,area] == 0

    #
    # Exogenous Venting Emission Prices
    #
    RePrice[offset,area] = RePriceX[offset,area]*Inflation[area]
  end

end

function IndicatedReductions(data::Data,area,ecc,offset)
  (; Yr2013) = data
  (; Inflation,InflationYr,ReA0,ReB0,ReC0,ReECC,RePol,RePrice) = data
  (; ReReductionsIndicated,ReReductionsSwitch,ReReductionsX) = data
  (; RePriceCurve) = data
 
  #
  # 23.08.16, LJD: I don't see where RePriceCurve is used.
  #
    RePriceCurve[offset,area] = RePrice[offset,area]/Inflation[area]*InflationYr[area,Yr2013]

  #
  # Indicated Reductions
  #
  if ReReductionsSwitch[offset,area] == 1
    @finite_math ReReductionsIndicated[offset,area] = ReC0[offset,area]/(1+ReA0[offset,area]*RePrice[offset,area] ^ ReB0[offset,area])*RePrice[offset,area]/RePrice[offset,area]

  #
  # Venting Indicated Reductions
  #
  elseif ReReductionsSwitch[offset,area] == 2
    @finite_math ReRP[offset,area] = ReC0[offset,area]/(1+ReA0[offset,area]*RePrice[offset,area] ^ ReB0[offset,area])*RePrice[offset,area]/RePrice[offset,area]
    ReReductionsIndicated[offset,area] = RePol[offset,area]*ReRP[offset,area]

  #
  # Flaring Other Fugitive Indicated Reductions
  #
  else
    ReReductionsIndicated[offset,area] = ReReductionsX[offset,area]
  end

#
# Indicated Reductions Constraints - certain Offsets not constrained by
# levels of emissions (RePol).
#
  if ReECC[offset] != "LandUse"
    ReReductionsIndicated[offset,area] = min( max(ReReductionsIndicated[offset,area],ReReductionsX[offset,area]),RePol[offset,area])
  else
    ReReductionsIndicated[offset,area] = max(ReReductionsIndicated[offset,area], ReReductionsX[offset,area])
  end

end

function ReductionConstruction(data::Data,area,ecc,offset)
  (; Levels) = data
  (; ReCapacity,ReCapacityCompleted,ReCapacityInitiated) = data
  (; ReCapacityPrior,ReCapacityRetirements,ReCapacityUnderConstruction) = data
  (; ReCD,ReCDInput,ReCDLevel,ReCDLevelPrior,ReCDOrder,ReCDOutput) = data
  (; ReReductionsIndicated,RePL) = data 

  #
  # Reduction Capacity Retired
  #
  @finite_math ReCapacityRetirements[offset,area] = ReCapacityPrior[offset,area]/RePL[offset,area]

  #
  # Reduction Capaicty Under Construction
  #
  ReCapacityUnderConstruction[offset,area] = sum(ReCDLevelPrior[level,offset,area] for level in Levels)

  #
  # Reduction Capacity Initiated
  #
  ReCapacityInitiated[offset,area] = max(ReReductionsIndicated[offset,area]- (ReCapacityPrior[offset,area] -
                                     ReCapacityRetirements[offset,area]+ReCapacityUnderConstruction[offset,area]),0)

  #
  # Construction Delay
  #
  for level in Levels
    @finite_math ReCDOutput[level,offset,area] = ReCDLevelPrior[level,offset,area]/(ReCD[offset]/ReCDOrder[offset])
  end

  recdorder::Integer = floor(ReCDOrder[offset])
  if recdorder > 1
    for level in 2:recdorder
      ReCDInput[level,offset,area] = ReCDOutput[level-1,offset,area]
    end
  end

  ReCDInput[1,offset,area] = ReCapacityInitiated[offset,area]

  for level in Levels
    ReCDLevel[level,offset,area] = ReCDLevelPrior[level,offset,area]+(ReCDInput[level,offset,area]-ReCDOutput[level,offset,area])
  end

  ReCapacityCompleted[offset,area] = ReCDOutput[recdorder,offset,area]



  #
  # Reduction Capacity
  #
  ReCapacity[offset,area] = ReCapacityPrior[offset,area] +
                            DT*(ReCapacityCompleted[offset,area]-
                            ReCapacityRetirements[offset,area])
end

function ReductionsGenerated(data::Data,area,ecc,offset)
  (; Poll) = data
  (; ReCapacity,ReECC,ReReductions,ReReductionsSwitch) = data
  (; ReReductionsX,RePOCF,RePol,RePollutant) = data

  poll = Select(Poll,RePollutant[offset])

  #
  # Reductions - certain Offsets not constrained by
  # levels of emissions (RePol).
  #
  if ReReductionsSwitch[offset,area] >= 0
    if ReECC[offset] != "LandUse"
      ReReductions[offset,poll,area] =
        min(max(ReCapacity[offset,area]*RePOCF[offset,poll,area],
                ReReductionsX[offset,area]),
            RePol[offset,area]*RePOCF[offset,poll,area])
    else
      ReReductions[offset,poll,area] = max(ReCapacity[offset,area]*
        RePOCF[offset,poll,area],ReReductionsX[offset,area])
    end
  else
    ReReductions[offset,poll,area] = ReReductionsX[offset,area]*RePOCF[offset,poll,area]
  end

end

function ReductionsCaptured(data::Data,area,ecc,offset)
  (; CTime) = data
  (; Poll) = data
  (; ReC2H6PerCH4,ReCaptured,ReCapturedFraction,ReDevelopedFraction) = data
  (; ReElectricPotentialFactor,ReGC,ReGCPrior,ReGCCMOff,ReGProdOff) = data
  (; RePollutant,ReReductions,TBtuGasPerTonneCH4) = data

  poll = Select(Poll,RePollutant[offset])

  #
  # Emissions Captured
  #
  ReCaptured[offset,poll,area] = ReReductions[offset,poll,area]*ReCapturedFraction[offset,poll,area]

  #
  # Captured Emissions sold as Natural Gas
  #
  ch4 = Select(Poll,"CH4")
  ReGProdOff[offset,area] = ReCaptured[offset,ch4,area]*TBtuGasPerTonneCH4*(1+ReC2H6PerCH4[offset,area])

  #
  # Captured Emissions used for Electric Generation
  #
  ReGC[offset,area] = ReCaptured[offset,ch4,area]*ReDevelopedFraction[offset,area]*ReElectricPotentialFactor[offset,area]/1e6

  #
  # Incremental Electric Capacity from Captured Emissions
  #
  if CTime >= HisTime
    ReGCCMOff[offset,area] = max(ReGC[offset,area]-ReGCPrior[offset,area],0)
  else
    ReGCCMOff[offset,area] = 0
  end

end

function ReductionCapitalCosts(data::Data,area,ecc,offset)
  (; Yr2012) = data
  (; Inflation,InflationYr,InSm,ReCapacity,ReCapacityCompleted,ReCapacityPrior) = data
  (; ReCapacityRetirements,ReCC,ReCCA0,ReCCB0,ReCCC0,ReCCEm,ReCCEmPrior,ReCCR) = data
  (; ReCCSwitch,ReIVTC,ReGFr,ReOCF,RePL,RePrice,ReROIN,ReTL,ReTxRt) = data

  #
  # Capital Charge Rate
  #
  @finite_math ReCCR[offset,area] = (1-ReIVTC[offset,area]/(1+ReROIN[offset,area]+InSm[area]) - ReTxRt[offset,area]*(2/ReTL[offset,area]) /
                                    (ReROIN[offset,area]+InSm[area]+2/ReTL[offset,area] ))*ReROIN[offset,area]/
                                    (1-(1/(1+ReROIN[offset,area])) ^ RePL[offset,area])/(1-ReTxRt[offset,area])

  #
  # Capital Costs
  #
  if ReCCSwitch[offset,area] == 1
    @finite_math ReCC[offset,area] = RePrice[offset,area]/(Inflation[area]*(ReCCR[offset,area]+ReOCF[offset,area])*(1 - ReGFr[offset,area]))
  #
  # Venting and Sequestering Capital Costs
  #
  else
    @finite_math ReCC[offset,area] = ReCCC0[offset,area]/(1+ReCCA0[offset,area]*RePrice[offset,area] ^ ReCCB0[offset,area])*RePrice[offset,area]/RePrice[offset,area]
    @finite_math ReCC[offset,area] = ReCC[offset,area]/InflationYr[area,Yr2012]/Inflation[area]
  end

  #
  # Embedded Capital Costs
  #
  @finite_math ReCCEm[offset,area] = (ReCCEmPrior[offset,area]*(ReCapacityPrior[offset,area] - ReCapacityRetirements[offset,area]) +
                        ReCC[offset,area]*ReCapacityCompleted[offset,area])/ReCapacity[offset,area]

end

function ReductionExpenditures(data::Data,area,ecc,offset)
  (; Poll) = data
  (; Inflation,ReCapacity,ReCapacityCompleted,ReCC,ReCCEm) = data
  (; ReCCReplace,ReGExp,ReGFr,ReInv,ReInvSwitch,ReOCF,ReOMExp) = data
  (; ReOMExpSwitch,RePExp,RePL,ReReductions,ReReductionsPrior,RePollutant) = data

  poll = Select(Poll,RePollutant[offset])

  #
  # Investments
  #
  if ReInvSwitch[offset,area] == 1
    ReInv[offset,area] = ReCapacityCompleted[offset,area]*ReCC[offset,area]/1e6
  else
    #
    # Other Fugitives Investments
    #
    ch4 = Select(Poll,"CH4")
    @finite_math ReInv[offset,area] = max(ReReductions[offset,ch4,area] - ReReductionsPrior[offset,ch4,area],0)*ReCC[offset,area]*Inflation[area]/1e6 +
                         ReReductionsPrior[offset,ch4,area]/RePL[offset,area]*ReCCReplace[offset,area]*Inflation[area]/1e6
  end

  #
  # O&M Expenses
  #
  if ReOMExpSwitch[offset,area] == 1
    
    #
    # 23.08.17, LJD: I don't know why this is a sum across Poll
    #
    # ReOMExp(Offset,Area)=sum(Poll)(ReCapacity(Offset,Area)*
    #                      ReCCEm(Offset,Area)*ReOCF(Offset,Area)/1e6)
    # ReOMExp[offset,area] = sum(ReCapacity[offset,area]*ReCCEm[offset,area]*ReOCF[offset,area]/1e6 for poll in Polls)

    ReOMExp[offset,area] = ReCapacity[offset,area]*ReCCEm[offset,area]*
                           ReOCF[offset,area]/1e6

  else
    #
    # Other Fugitives O&M Expenses
    #
    # 23.08.17, LJD: this appears has an unsellected Poll in Promula.
    #   
    ReOMExp[offset,area] = ReReductions[offset,poll,area]*ReCC[offset,area]*
                           Inflation[area]*ReOCF[offset,area]/1e6
  end

  #
  #  Private Expenses
  #
  RePExp[offset,area] = ReInv[offset,area]*(1-ReGFr[offset,area])+ReOMExp[offset,area]

  #
  # Government Expenses
  #
  ReGExp[offset,area] = ReInv[offset,area]*ReGFr[offset,area]

end

function MapReductions(data::Data,area,ecc,offset)
  (; Poll,Polls) = data
  (; FlInv,FlReduce,FuInv,FuOMExp,FuReduce,MEInv) = data
  (; MEOMExp,MEReduce,ReInv,ReOMExp,RePOCF,RePollutant) = data
  (; ReReductions,ReType,VnInv,VnOMExp,VnReduce) = data
  
  poll = Select(Poll,RePollutant[offset])

  if ReType[offset] == "Venting"
    VnReduce[ecc,poll,area] = VnReduce[offset,poll,area]+ReReductions[offset,poll,area]
    VnInv[ecc,area] = VnInv[ecc,area]+ReInv[offset,area]
    VnOMExp[ecc,area] = VnOMExp[ecc,area]+ReOMExp[offset,area]
  elseif ReType[offset] == "Flaring"
    FlReduce[ecc,poll,area] = FlReduce[offset,poll,area]+ReReductions[offset,poll,area]
    FlInv[ecc,area] = FlInv[ecc,area]+ReInv[offset,area]
  elseif ReType[offset] == "OtherFugitives"
    FuReduce[ecc,poll,area] = FuReduce[offset,poll,area]+ReReductions[offset,poll,area]
    FuInv[ecc,area] = FuInv[ecc,area]+ReInv[offset,area]
    FuOMExp[ecc,area] = FuOMExp[ecc,area]+ReOMExp[offset,area]
  elseif ReType[offset] == "Process"
    #
    # MEReduce needs a Poll selection
    #
    for poll in Polls
      if RePOCF[offset,poll,area] > 0
        MEReduce[ecc,poll,area] = MEReduce[ecc,poll,area]+ReReductions[offset,poll,area]
      end
    end
    #
    MEInv[ecc,area] = MEInv[ecc,area]+ReInv[offset,area]
    MEOMExp[ecc,area] = MEOMExp[ecc,area]+ReOMExp[offset,area]
  end

end

function TotalReductions(data::Data)
  (; Areas,Nations, Offsets) = data
  (; ANMap,ReGAProd,ReGCCM,ReGCCMOff,ReGProd,ReGProdOff) = data

  #
  # Electric Generation
  #
  for area in Areas
    ReGCCM[area] = sum(ReGCCMOff[offset,area] for offset in Offsets)
  end
  
  #
  # Natural Gas Production
  #
  for area in Areas
    ReGAProd[area] = sum(ReGProdOff[offset,area] for offset in Offsets)
  end
  for nation in Nations
    ReGProd[nation] = sum(ReGAProd[area]*ANMap[area,nation] for area in Areas)
  end
end

function WriteReductionsToDatabase(data::Data)
  (; db,year) = data
  (; ) = data
  (; FlInv,FlReduce,FuInv,FuOMExp,FuReduce,MEInv,MEOMExp,MEReduce,ReCC) = data
  (; ReCCEm,ReCCR,ReCDInput,ReCDLevel,ReCDOutput,ReCapacity,ReCapacityCompleted) = data
  (; ReCapacityInitiated,ReCapacityRetirements,ReCapacityUnderConstruction) = data
  (; ReCaptured,ReGAProd,ReGC,ReGCCM,ReGCCMOff,ReGExp,ReGProd,ReGProdOff) = data
  (; ReInv,ReOMExp,RePExp,RePol,RePrice,ReReductions,ReReductionsIndicated) = data
  (; VnInv,VnOMExp,VnReduce) = data

  WriteDisk(db,"SOutput/FlInv",year,FlInv)
  WriteDisk(db,"SOutput/FlReduce",year,FlReduce)
  WriteDisk(db,"SOutput/FuInv",year,FuInv)
  WriteDisk(db,"SOutput/FuOMExp",year,FuOMExp)
  WriteDisk(db,"SOutput/FuReduce",year,FuReduce)
  WriteDisk(db,"SOutput/MEInv",year,MEInv)
  WriteDisk(db,"SOutput/MEOMExp",year,MEOMExp)
  WriteDisk(db,"SOutput/MEReduce",year,MEReduce)
  WriteDisk(db,"MEOutput/ReCC",year,ReCC)
  WriteDisk(db,"MEOutput/ReCCEm",year,ReCCEm)
  WriteDisk(db,"MEOutput/ReCCR",year,ReCCR)
  WriteDisk(db,"MEOutput/ReCDInput",year,ReCDInput)
  WriteDisk(db,"MEOutput/ReCDLevel",year,ReCDLevel)
  WriteDisk(db,"MEOutput/ReCDOutput",year,ReCDOutput)
  WriteDisk(db,"MEOutput/ReCapacity",year,ReCapacity)
  WriteDisk(db,"MEOutput/ReCapacityCompleted",year,ReCapacityCompleted)
  WriteDisk(db,"MEOutput/ReCapacityInitiated",year,ReCapacityInitiated)
  WriteDisk(db,"MEOutput/ReCapacityRetirements",year,ReCapacityRetirements)
  WriteDisk(db,"MEOutput/ReCapacityUnderConstruction",year,ReCapacityUnderConstruction)
  WriteDisk(db,"MEOutput/ReCaptured",year,ReCaptured)
  WriteDisk(db,"SOutput/ReGAProd",year,ReGAProd)
  WriteDisk(db,"MEOutput/ReGC",year,ReGC)
  WriteDisk(db,"SOutput/ReGCCM",year,ReGCCM)
  WriteDisk(db,"MEOutput/ReGCCMOff",year,ReGCCMOff)
  WriteDisk(db,"MEOutput/ReGExp",year,ReGExp)
  WriteDisk(db,"SOutput/ReGProd",year,ReGProd)
  WriteDisk(db,"MEOutput/ReGProdOff",year,ReGProdOff)
  WriteDisk(db,"MEOutput/ReInv",year,ReInv)
  WriteDisk(db,"MEOutput/ReOMExp",year,ReOMExp)
  WriteDisk(db,"MEOutput/RePExp",year,RePExp)
  WriteDisk(db,"MEOutput/RePol",year,RePol)
  WriteDisk(db,"MEOutput/RePrice",year,RePrice)
  WriteDisk(db,"MEOutput/ReReductions",year,ReReductions)
  WriteDisk(db,"MEOutput/ReReductionsIndicated",year,ReReductionsIndicated)
  WriteDisk(db,"SOutput/VnInv",year,VnInv)
  WriteDisk(db,"SOutput/VnOMExp",year,VnOMExp)
  WriteDisk(db,"SOutput/VnReduce",year,VnReduce)
end

function CtrlReductions(data::Data)
  (; Areas,ECC,ECCs,Offsets ) = data
  (; ReECC) = data

  # @info "  MReductions.jl - CtrlReductions"

  InitializeData(data)

  for offset in Offsets
    for ecc in ECCs
      if ReECC[offset] == ECC[ecc]
        for area in Areas

          InitializeReductions(data,area,ecc,offset)
          EmissionPrices(data,area,ecc,offset)
          IndicatedReductions(data,area,ecc,offset)
          ReductionConstruction(data,area,ecc,offset)
          ReductionsGenerated(data,area,ecc,offset)
          ReductionsCaptured(data,area,ecc,offset)
          ReductionCapitalCosts(data,area,ecc,offset)
          ReductionExpenditures(data,area,ecc,offset)
          MapReductions(data,area,ecc,offset)

        end
      end
    end
  end

  TotalReductions(data)
  WriteReductionsToDatabase(data)

end

end
