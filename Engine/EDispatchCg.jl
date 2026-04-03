#
# EDispatchCg.jl
#

module EDispatchCg

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

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
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CgCap::VariableArray{3} = ReadDisk(db,"SOutput/CgCap",year) #[Fuel,ECC,Area,Year]  Cogeneration Capacity (MW)
  CgCapP::VariableArray{3} = ReadDisk(db,"SOutput/CgCapP",year) #[Plant,ECC,Area,Year]  Generating Capacity from Industrial Units (MW)
  CgCurtailFraction::VariableArray{2} = ReadDisk(db,"SOutput/CgCurtailFraction",year) #[ECC,Area,Year]  Fraction of Cogeneration Curtailed (GWh/GWh)
  CgDemand::VariableArray{3} = ReadDisk(db,"SOutput/CgDemand",year) #[Fuel,ECC,Area,Year]  Cogeneration Demands (TBtu/Yr)
  CgECGrid::VariableArray{2} = ReadDisk(db,"SOutput/CgECGrid",year) #[ECC,Area,Year]  Cogeneration for Grid by Economic Category (GWh/YR)
  CgECNoGrid::VariableArray{2} = ReadDisk(db,"SOutput/CgECNoGrid",year) #[ECC,Area,Year]  Cogeneration not for Grid by Economic Category (GWh/YR)
  CgECShutdown::VariableArray{2} = ReadDisk(db,"SOutput/CgECShutdown",year) #[ECC,Area,Year]  Cogeneration Curtailed by Economic Category (GWh/YR)
  CgFPol::VariableArray{4} = ReadDisk(db,"SOutput/CgFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Pollution in Cogeneration Units (Tonnes/Yr)
  CgFPolGross::VariableArray{4} = ReadDisk(db,"SOutput/CgFPolGross",year) #[FuelEP,ECC,Poll,Area,Year]  Cogeneration Units Gross Pollution (Tonnes/Yr)
  CgGen::VariableArray{3} = ReadDisk(db,"SOutput/CgGen",year) #[Fuel,ECC,Area,Year]  Cogeneration Generation (GWh/Yr)
  CgGenP::VariableArray{3} = ReadDisk(db,"SOutput/CgGenP",year) #[Plant,ECC,Area,Year]  Generation from Industrial Units (GWh/Yr)
  CgPolSq::VariableArray{3} = ReadDisk(db,"SOutput/CgPolSq",year) #[ECC,Poll,Area,Year]  Cogeneration Pollution Sequestered (Tonnes/Yr)
  CgPolSqPenalty::VariableArray{3} = ReadDisk(db,"SOutput/CgPolSqPenalty",year) #[ECC,Poll,Area,Year]  Cogeneration Pollution Sequestered (Tonnes/Yr)
  CoverageCFS::VariableArray{3} = ReadDisk(db,"SInput/CoverageCFS",year) #[Fuel,ECC,Area,Year]  Coverage fro CFS (1=Covered)
  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Enduse Energy Demands (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # Map between FuelEP and Fuel [FuelEP,Fuel]
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") #[Fuel,Plant]  Fuel/Plant Map
  GrElec::VariableArray{2} = ReadDisk(db,"SOutput/GrElec",year) #[ECC,Area,Year]  Gross Electric Usage (GWh)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  MinPurF::VariableArray{2} = ReadDisk(db,"SInput/MinPurF",year) #[ECC,Area,Year]  Minimum Fraction of Electricity which is Purchased (GWh/GWh)
  PSoECC::VariableArray{2} = ReadDisk(db,"SOutput/PSoECC",year) #[ECC,Area,Year]  Power Sold to Grid (GWh)
  PSoECCFraction::VariableArray{2} = ReadDisk(db,"SOutput/PSoECCFraction",year) #[ECC,Area,Year]  Fraction of Power Available for Grid Sales Sold to Grid (GWh/GWh)
  PSoNoGrid::VariableArray{2} = ReadDisk(db,"SOutput/PSoNoGrid",year) #[ECC,Area,Year]  Excess Power that cannot be Sold to Grid (GWh)
  PurECC::VariableArray{2} = ReadDisk(db,"SOutput/PurECC",year) #[ECC,Area,Year]  Purchases from Electric Grid (GWh)
  UnArea::Vector{String} = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
  UnCgCurtailFraction::VariableArray{1} = ReadDisk(db,"EGOutput/UnCgCurtailFraction",year) #[Unit,Year]  Fraction of Unit Power to be Curtailed (GWh/GWh)
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::Float32 = ReadDisk(db,"EGInput/UnCounter",year) #[Year]  Number of Units
  UnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UnDmd",year) #[Unit,FuelEP,Year]  Energy Demands (TBtu)
  UnEG::VariableArray{3} = ReadDisk(db,"EGOutput/UnEG",year) #[Unit,TimeP,Month,Year]  Generation (GWh)
  UnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGA",year) #[Unit,Year]  Net Generation (GWh)
  UnEGAGridSales::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGAGridSales",year) #[Unit,Year]  Generation Sold to Grid (GWh)
  UnEGC::VariableArray{3} = ReadDisk(db,"EGOutput/UnEGC",year) #[Unit,TimeP,Month,Year]  Effective Generating Capacity (MW)
  UnEGGross::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGGross",year) #[Unit,Year]  Gross Generation (GWh/Yr)
  UnFlFr::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFr",year) #[Unit,FuelEP,Year]  Fuel Fraction (Btu/Btu)
  UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Gross Generating Capacity (MW)
  UnGCNet::VariableArray{1} = ReadDisk(db,"EGOutput/UnGCNet",year) #[Unit,Year]  Net Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{1} = ReadDisk(db,"EGInput/UnHRt",year) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnMECX::VariableArray{2} = ReadDisk(db,"EGInput/UnMECX",year) #[Unit,Poll,Year]  Process Pollution Coefficient (Tonnes/GWh)
  UnMEPol::VariableArray{2} = ReadDisk(db,"EGOutput/UnMEPol",year) #[Unit,Poll,Year]  Process Pollution (Tonnes)
  UnNode::Vector{String} = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  UnOOR::VariableArray{1} = ReadDisk(db,"EGCalDB/UnOOR",year) #[Unit,Year]  Operational Outage Rate (MW/MW)
  UnOR::VariableArray{3} = ReadDisk(db,"EGInput/UnOR",year) #[Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  UnORDriver::VariableArray{1} = ReadDisk(db,"EGOutput/UnORDriver",year) #[Unit,Year]  Outage Rate from Decline in Driver (MW/MW)
  UnOUEG::VariableArray{1} = ReadDisk(db,"EGOutput/UnOUEG",year) #[Unit,Year]  Own Use Generation (GWh/Yr)
  UnOUGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnOUGC",year) #[Unit,Year]  Own Use Generating Capacity (MW)
  UnOUREG::VariableArray{1} = ReadDisk(db,"EGInput/UnOUREG",year) #[Unit,Year]  Own Use Rate for Generation (GWh/GWh)
  UnOURGC::VariableArray{1} = ReadDisk(db,"EGInput/UnOURGC",year) #[Unit,Year]  Own Use Rate for Generating Capacity (MW/MW)
  UnPCF::VariableArray{1} = ReadDisk(db,"EGOutput/UnPCF",year) #[Unit,Year]  Unit Capacity Factor (MW/MW)

  UnPCFDriver::VariableArray{1} = ReadDisk(db,"EGOutput/UnPCFDriver",year) #[Unit,Year]  Unit Capacity Factor Limit from Decline in Driver (MW/MW)
  UnPCFuu::VariableArray{1} = ReadDisk(db,"EGOutput/UnPCFuu",year) #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
  UnPOCA::VariableArray{3} = ReadDisk(db,"EGOutput/UnPOCA",year) #[Unit,FuelEP,Poll,Year]  Pollution Coefficient (Tonnes/TBtu)
  UnPOCX::VariableArray{3} = ReadDisk(db,"EGInput/UnPOCX",year) #[Unit,FuelEP,Poll,Year]  Pollution Coefficient (Tonnes/TBtu)
  UnPol::VariableArray{3} = ReadDisk(db,"EGOutput/UnPol",year) #[Unit,FuelEP,Poll,Year]  Pollution (Tonnes)
  UnPolGross::VariableArray{3} = ReadDisk(db,"EGOutput/UnPolGross",year) #[Unit,FuelEP,Poll,Year]  Gross Pollution (Tonnes)
  UnPolSq::VariableArray{3} = ReadDisk(db,"EGOutput/UnPolSq",year) #[Unit,FuelEP,Poll,Year]  Gross Sequestered Pollution (Tonnes/Yr)
  UnPolSqPenalty::VariableArray{3} = ReadDisk(db,"EGOutput/UnPolSqPenalty",year) #[Unit,FuelEP,Poll,Year]  Sequestered Pollution Penalty (Tonnes/Yr)
  UnPSoMaxGridFraction::VariableArray{1} = ReadDisk(db,"EGInput/UnPSoMaxGridFraction",year) #[Unit,Year]  Maximum Fraction Sold to Grid (GWh/GWh)
  UnRetire::VariableArray{1} = ReadDisk(db,"EGInput/UnRetire",year) #[Unit,Year]  Retirement Date (Year)
  UnRM::VariableArray{3} = ReadDisk(db,"EGOutput/UnRM",year) #[Unit,FuelEP,Poll,Year]  Pollution Reduction Multiplier (Tonnes/Tonnes)
  UnSector::Vector{String} = ReadDisk(db,"EGInput/UnSector") #[Unit]  Unit Type (Utility or Industry)
  UnSensitivity::VariableArray{1} = ReadDisk(db,"EGInput/UnSensitivity",year) #[Unit,Year]  Outage Rate Sensitivity to Decline in Driver (Driver/Driver)
  UnSqFr::VariableArray{2} = ReadDisk(db,"EGInput/UnSqFr",year) #[Unit,Poll,Year]  Sequestered Pollution Fraction (Tonnes/Tonnes)
  UnXSw::VariableArray{1} = ReadDisk(db,"EGInput/UnXSw",year) #[Unit,Year]  Exogneous Unit Data Switch (0 = Exogenous)
  UnZeroFr::VariableArray{3} = ReadDisk(db,"EGInput/UnZeroFr",year) #[Unit,FuelEP,Poll,Year]  Fraction of Emissions from Zero Emission Sources (Tonnes/Tonnes)
  UUnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UUnDmd",year) #[Unit,FuelEP,Year]  Endogenous Energy Demands (TBtu)
  UUnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGA",year) #[Unit,Year]  Endogenous Generation (GWh)
  xUnDmd::VariableArray{2} = ReadDisk(db,"EGInput/xUnDmd",year) #[Unit,FuelEP,Year]  Historical Unit Energy Demands (TBtu)
  xUnEGA::VariableArray{1} = ReadDisk(db,"EGInput/xUnEGA",year) #[Unit,Year]  Historical Unit Generation
end

function GetUnitSets(data::Data,unit)
  (; Area, GenCo, Node, Plant,ECC) = data
  (; UnArea,UnGenCo,UnNode,UnPlant,UnSector) = data

  gencoindex = Select(GenCo,UnGenCo[unit])
  plantindex = Select(Plant,UnPlant[unit])
  nodeindex = Select(Node,UnNode[unit])
  areaindex = Select(Area,UnArea[unit])
  eccindex = Select(ECC,UnSector[unit])
  return gencoindex,plantindex,nodeindex,areaindex,eccindex
end

function GetCogenUnits(data::Data)
  (; CTime) = data
  (; UnCogen,UnCounter,UnOnLine,UnRetire,UnSector) = data

  units = 1:Int(UnCounter)
  unitsol = Select(UnOnLine,<=(CTime))
  unitsret = Select(UnRetire,>(CTime))
  unitscg0 = Select(UnCogen,!=(0.0))
  unitsnoh2 = findall(x -> x != "H2Production",UnSector)
  CogenUnits = intersect(units,unitsol,unitsret,unitscg0,unitsnoh2)
  return CogenUnits
end

function InitializeCgData(data::Data)
  (; CgGen,CgGenP,CgCap,CgCapP,CgDemand) = data
  (; CgECGrid,CgECNoGrid,CgFPol,CgFPolGross,CgPolSq,CgPolSqPenalty) = data

  @. CgCap = 0
  @. CgCapP = 0
  @. CgDemand = 0
  @. CgECGrid = 0
  @. CgECNoGrid = 0
  @. CgFPol = 0
  @. CgFPolGross = 0
  @. CgGen = 0
  @. CgGenP = 0
  @. CgPolSq = 0
  @. CgPolSqPenalty = 0
end

function CogenEconomicOutageRate(data::Data,unit,ecc,area)
  (; CTime) = data
  (; Driver,UnOnLine,UnPCFDriver,UnORDriver,UnSensitivity) = data
  
  current = CTime-ITime+1
  if CTime > HisTime
    OnLineYear = Int(min(max(UnOnLine[unit]-ITime+1,HisTime-ITime+1),Final))
    
    @finite_math UnPCFDriver[unit] = min(Driver[ecc,area,current]/
                                         Driver[ecc,area,OnLineYear],1.00)
    
    @finite_math UnORDriver[unit] =
      1-(UnPCFDriver[unit]*UnSensitivity[unit]+(1-UnSensitivity[unit]))
  end
end

function CogenEffectiveCapacity(data::Data,unit)
  (; Months,TimePs) = data
  (; UnEGC,UnGC,UnOOR,UnOR,UnOURGC,UnORDriver) = data
  
  for month in Months, timep in TimePs
    UnEGC[unit,timep,month] = UnGC[unit]*(1-UnOURGC[unit])*
      (1-UnOR[unit,timep,month])*(1-UnOOR[unit])*(1-UnORDriver[unit])
  end
  
end

function CogenerationGeneration(data::Data,unit)
  (; Months,TimePs) = data
  (; HDHours,UnEG,UnEGC,UnCgCurtailFraction) = data

  for timep in TimePs, month in Months
    UnEG[unit,timep,month] = 
      UnEGC[unit,timep,month]*HDHours[timep,month]/1000*(1-UnCgCurtailFraction[unit])
  end
end

function UnitGeneration(data::Data,unit)
  (; Months,TimePs) = data
  (; UnEG,UnEGA,UnGC,UnXSw,UUnEGA,xUnEGA) = data

  UUnEGA[unit] = sum(UnEG[unit,timep,month] for timep in TimePs,month in Months)

  #
  # If UnXSw equals 0.0 then we want generation (UnEGA) to exactly
  # equal the historical generation (xUnEGA),but save the model
  # generated value (UUnEGA)
  #
  if (UnXSw[unit] == 0) && (UnGC[unit] > 0)
    UnEGA[unit] = xUnEGA[unit]
  else
    UnEGA[unit] = UUnEGA[unit]
  end
end

function OwnUseGenerationAndCapacity(data::Data,unit)
  (; UnEGA,UnEGGross,UnGC,UnGCNet,UnOUEG,UnOUGC,UnOUREG,UnOURGC) = data

  @finite_math UnEGGross[unit] = UnEGA[unit] / (1 - UnOUREG[unit])
  UnOUEG[unit] = UnEGGross[unit] - UnEGA[unit]
  UnGCNet[unit] = UnGC[unit] * (1 - UnOURGC[unit])
  UnOUGC[unit] = UnGC[unit] - UnGCNet[unit]
end

function UnitFuelUse(data::Data,unit)
  (; FuelEPs) = data
  (; UnDmd,UnEGGross,UnFlFr,UnGC,UnHRt,UnXSw,UUnDmd,xUnDmd) = data

  for fuelep in FuelEPs

    #
    # Unit fuel usage (UnDmd) is equal to generation (UnEGA) times heat
    # rate (UnHRt) times the fuel fraction (UnFlFr).
    #
    UnDmd[unit,fuelep] = max(UnEGGross[unit] * UnHRt[unit] / 1e6 * UnFlFr[unit,fuelep],0)

    #
    # If UnXSq equals 0.0 then we want fuel usage (UnDmd) to be exact (xUnDmd),
    # but save the model generated value (UUnDmd)
    #
    UUnDmd[unit,fuelep] = UnDmd[unit,fuelep]
    if (UnXSw[unit] == 0) && (UnGC[unit] > 0)
      UnDmd[unit,fuelep] = xUnDmd[unit,fuelep]
    end
  end
end

function GenerationCapacityFuelUse(data::Data,unit,plant,area,ecc)
  (; CTime,Area,ECC,Fuel,Fuels,FuelEP,FuelEPs) = data
  (; FFPMap,FlPlnMap,CgCap,UnGC,CgCapP,CgGen,UnEGA,CgGenP,CgDemand,UnHRt,UnDmd,UnFlFr) = data
  (; CgECGrid,CgECNoGrid,UnSector,UnPSoMaxGridFraction) = data

  if ECC[ecc] == UnSector[unit]
  
     CgCapP[plant,ecc,area] = CgCapP[plant,ecc,area]+UnGC[unit]        
     CgGenP[plant,ecc,area] = CgGenP[plant,ecc,area]+UnEGA[unit]

    for fuel in Fuels
      #
      # For Units which do not use a Fuel in the FuelEP set
      #    
      if FlPlnMap[fuel,plant] == 1
        CgCap[fuel,ecc,area] = CgCap[fuel,ecc,area]+UnGC[unit]
        CgGen[fuel,ecc,area] = CgGen[fuel,ecc,area]+UnEGA[unit]
        CgDemand[fuel,ecc,area] = CgDemand[fuel,ecc,area]+UnEGA[unit]*UnHRt[unit]/1e6
  
      #
      # Else Units which use a Fuel in FuelEP set
      #
      else
        for fuelep in FuelEPs
          if FFPMap[fuelep,fuel] == 1          
            CgCap[fuel,ecc,area] = CgCap[fuel,ecc,area]+UnGC[unit]*UnFlFr[unit,fuelep]
            CgGen[fuel,ecc,area] = CgGen[fuel,ecc,area]+UnEGA[unit]*UnFlFr[unit,fuelep]
            CgDemand[fuel,ecc,area] = CgDemand[fuel,ecc,area]+UnDmd[unit,fuelep]

          end
        end
      end
    end
    
    CgECGrid[ecc,area] = CgECGrid[ecc,area]+UnEGA[unit]*UnPSoMaxGridFraction[unit]
    CgECNoGrid[ecc,area] = CgECNoGrid[ecc,area]+UnEGA[unit]*(1-UnPSoMaxGridFraction[unit])    
  end
end

function UnitPollution(data::Data,unit)
  (; FuelEPs,Polls) = data
  (; UnDmd,UnPOCA,UnPOCX,UnRM,UnPolGross,UnPolSq,UnSqFr) = data
  (; UnPolSqPenalty,UnOUREG,UnPol,UnZeroFr,UnMEPol,UnMECX,UnEGA) = data

  #
  # Pollution Coefficient (UnPOCA) is the normal coefficient (UnPOCX)
  # times the Pollution Reduction Multiplier (UnRM).
  #
  for fuelep in FuelEPs,poll in Polls
    UnPOCA[unit,fuelep,poll] = UnPOCX[unit,fuelep,poll] * UnRM[unit,fuelep,poll]
  end

  for fuelep in FuelEPs,poll in Polls
    UnPolGross[unit,fuelep,poll] = UnDmd[unit,fuelep] * UnPOCA[unit,fuelep,poll]
    UnPolSq[unit,fuelep,poll] = UnPolGross[unit,fuelep,poll] * UnSqFr[unit,poll]
    UnPolSqPenalty[unit,fuelep,poll] = UnPolSq[unit,fuelep,poll] * UnOUREG[unit]
    UnPol[unit,fuelep,poll] = UnPolGross[unit,fuelep,poll] * (1 - UnZeroFr[unit,fuelep,poll]) - UnPolSq[unit,fuelep,poll]
  end

  for poll in Polls
    UnMEPol[unit,poll] = max(UnEGA[unit] * UnMECX[unit,poll],0)
  end

end

function IndustrialGenerationUnitPollution(data::Data,unit,ecc,area)
  (; FuelEPs,Polls) = data
  (; CgFPolGross,UnPolGross,CgFPol,UnZeroFr) = data
  (; CgPolSq,UnPolSq,CgPolSqPenalty,UnPolSqPenalty) = data

  #
  # Update pollution totals for this unit
  #
  for poll in Polls
    for fuelep in FuelEPs
      CgFPolGross[fuelep,ecc,poll,area] = CgFPolGross[fuelep,ecc,poll,area]+
        UnPolGross[unit,fuelep,poll]
        
      CgFPol[fuelep,ecc,poll,area] = CgFPol[fuelep,ecc,poll,area]+
        UnPolGross[unit,fuelep,poll]*(1-UnZeroFr[unit,fuelep,poll])
    end

    CgPolSq[ecc,poll,area] = CgPolSq[ecc,poll,area]+
      sum(UnPolSq[unit,fuelep,poll] for fuelep in FuelEPs)
      
    CgPolSqPenalty[ecc,poll,area] = CgPolSqPenalty[ecc,poll,area]+
      sum(UnPolSqPenalty[unit,fuelep,poll] for fuelep in FuelEPs)
  end

end

function UnitCapacityFactor(data::Data,unit)
  (; UnEGA,UnGC,UnPCF,UnPCFuu,UUnEGA) = data

  @finite_math UnPCF[unit] = UnEGA[unit]/(UnGC[unit]*8760/1000)
  @finite_math UnPCFuu[unit] = UUnEGA[unit]/(UnGC[unit]*8760/1000)
end

function WriteCogenUnitData(data::Data)
  (; db,year) = data
  (; CgCap,CgCapP,CgDemand,CgECGrid,CgECNoGrid) = data
  (; CgFPolGross,CgFPol,CgGen,CgGenP) = data
  (; CgPolSq,CgPolSqPenalty) = data
  (; UnDmd,UnEG,UnEGA,UnEGC,UnEGGross) = data
  (; UnGCNet,UnMEPol,UnOUEG,UnOUGC) = data
  (; UnPCF,UnPCFuu,UnPol,UnPolGross) = data
  (; UnPolSq,UnPolSqPenalty) = data
  (; UUnDmd,UUnEGA) = data

  WriteDisk(db,"SOutput/CgCap",year,CgCap)
  WriteDisk(db,"SOutput/CgCapP",year,CgCapP)
  WriteDisk(db,"SOutput/CgDemand",year,CgDemand)
  WriteDisk(db,"SOutput/CgECGrid",year,CgECGrid)
  WriteDisk(db,"SOutput/CgECNoGrid",year,CgECNoGrid)
  WriteDisk(db,"SOutput/CgFPolGross",year,CgFPolGross)
  WriteDisk(db,"SOutput/CgFPol",year,CgFPol)
  WriteDisk(db,"SOutput/CgGen",year,CgGen)
  WriteDisk(db,"SOutput/CgGenP",year,CgGenP)
  WriteDisk(db,"SOutput/CgPolSq",year,CgPolSq)
  WriteDisk(db,"SOutput/CgPolSqPenalty",year,CgPolSqPenalty)
  WriteDisk(db,"EGOutput/UnDmd",year,UnDmd)
  WriteDisk(db,"EGOutput/UnEG",year,UnEG)
  WriteDisk(db,"EGOutput/UnEGA",year,UnEGA)
  WriteDisk(db,"EGOutput/UnEGC",year,UnEGC)
  WriteDisk(db,"EGOutput/UnEGGross",year,UnEGGross)
  WriteDisk(db,"EGOutput/UnGCNet",year,UnGCNet)
  WriteDisk(db,"EGOutput/UnMEPol",year,UnMEPol)
  WriteDisk(db,"EGOutput/UnOUEG",year,UnOUEG)
  WriteDisk(db,"EGOutput/UnOUGC",year,UnOUGC)
  WriteDisk(db,"EGOutput/UnPCF",year,UnPCF)
  WriteDisk(db,"EGOutput/UnPCFuu",year,UnPCFuu)
  WriteDisk(db,"EGOutput/UnPol",year,UnPol)
  WriteDisk(db,"EGOutput/UnPolGross",year,UnPolGross)
  WriteDisk(db,"EGOutput/UnPolSq",year,UnPolSq)
  WriteDisk(db,"EGOutput/UnPolSqPenalty",year,UnPolSqPenalty)
  WriteDisk(db,"EGOutput/UUnDmd",year,UUnDmd)
  WriteDisk(db,"EGOutput/UUnEGA",year,UUnEGA)
end

function CgProduction(data::Data)
  (; UnCogen) = data
  # @info "EDispatchCg - Industrial Unit Generation CgProduction"

  #
  # New variable named ValidCogenUnit which is 0 or 1?
  #
  InitializeCgData(data) # changed order,since moving unit-loop up in order.

  units = GetCogenUnits(data)
  for unit in units
    if UnCogen[unit] != 0
      genco,plant,node,area,ecc = GetUnitSets(data,unit)      
      CogenEconomicOutageRate(data,unit,ecc,area)
      CogenEffectiveCapacity(data,unit)
      CogenerationGeneration(data,unit)
      UnitGeneration(data,unit)
      OwnUseGenerationAndCapacity(data,unit)
      UnitFuelUse(data,unit)
      GenerationCapacityFuelUse(data,unit,plant,area,ecc)
      UnitPollution(data,unit)
      IndustrialGenerationUnitPollution(data,unit,ecc,area)
      UnitCapacityFactor(data,unit)
    end
  end
  WriteCogenUnitData(data)
end

function CogenSalesAndElectricPurchases(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs,Fuel) = data
  (; EuDemand,GrElec,MinPurF) = data
  (; CgECGrid,CgECNoGrid,PurECC) = data
  (; PSoECC,PSoECCFraction,PSoNoGrid) = data

  #
  # Gross Electric Usage
  #
  electric = Select(Fuel,"Electric")
  for area in Areas, ecc in ECCs 
    GrElec[ecc,area] = EuDemand[electric,ecc,area]/3412*1e6
  end
  WriteDisk(db,"SOutput/GrElec",year,GrElec)

  #
  # Purchase from Electric Grid
  #
  for area in Areas, ecc in ECCs 
    PurECC[ecc,area] = max(
      GrElec[ecc,area]-CgECGrid[ecc,area]-CgECNoGrid[ecc,area],
      GrElec[ecc,area]*MinPurF[ecc,area])
  end
  WriteDisk(db,"SOutput/PurECC",year,PurECC)

  #
  # Power Sold back to Grid
  #
  for area in Areas, ecc in ECCs 
    PSoECC[ecc,area] = max(
      CgECGrid[ecc,area]+PurECC[ecc,area]-(GrElec[ecc,area]-CgECNoGrid[ecc,area]),0)
  end
  WriteDisk(db,"SOutput/PSoECC",year,PSoECC)

  for area in Areas, ecc in ECCs 
    @finite_math PSoECCFraction[ecc,area] = PSoECC[ecc,area]/CgECGrid[ecc,area]
  end
  WriteDisk(db,"SOutput/PSoECCFraction",year,PSoECCFraction)

  #
  # Excess CoGen power that can't be sent to Grid (should be zero)
  #
  for area in Areas, ecc in ECCs 
    PSoNoGrid[ecc,area] = max(
      CgECNoGrid[ecc,area]-(GrElec[ecc,area]-GrElec[ecc,area]*MinPurF[ecc,area]),0)
  end
  WriteDisk(db,"SOutput/PSoNoGrid",year,PSoNoGrid)

end

function CgCurtailments(data::Data)
  (; db,year) = data
  (; Area,Areas,ECC,ECCs) = data
  (; CgECShutdown,CgECNoGrid,GrElec,MinPurF) = data
  (; CgCurtailFraction,UnCgCurtailFraction,UnPSoMaxGridFraction) = data

  #
  # Cogeneration Curtailments
  #
  for area in Areas, ecc in ECCs 
    CgECShutdown[ecc,area] = max(
      CgECNoGrid[ecc,area]-GrElec[ecc,area]+GrElec[ecc,area]*MinPurF[ecc,area],0)
  end
  WriteDisk(db,"SOutput/CgECShutdown",year,CgECShutdown)

  #
  # Fraction of Generation Curtailed
  #
  for area in Areas, ecc in ECCs 
    @finite_math CgCurtailFraction[ecc,area] = CgECShutdown[ecc,area]/CgECNoGrid[ecc,area]
  end
  WriteDisk(db,"SOutput/CgCurtailFraction",year,CgCurtailFraction)

  units = GetCogenUnits(data)
  for unit in units
    if UnPSoMaxGridFraction[unit] == 0  
      genco,plant,node,area,ecc = GetUnitSets(data,unit)
      UnCgCurtailFraction[unit] = CgCurtailFraction[ecc,area]
    end
  end

  WriteDisk(db,"EGOutput/UnCgCurtailFraction",year,UnCgCurtailFraction)
end

function CgUnitGridSales(data::Data)
  (; db,year) = data
  (; UnEGAGridSales,UnEGA,UnPSoMaxGridFraction,PSoECCFraction) = data

  #
  # Initialize grid sales to zero
  #
  @. UnEGAGridSales = 0.0

  units = GetCogenUnits(data)
  for unit in units
    if UnPSoMaxGridFraction[unit] > 0 
      genco,plant,node,area,ecc = GetUnitSets(data,unit)
      UnEGAGridSales[unit] = UnEGA[unit]*UnPSoMaxGridFraction[unit]*PSoECCFraction[ecc,area]
    end
  end

  WriteDisk(db,"EGOutput/UnEGAGridSales",year,UnEGAGridSales)
end

function Control(data::Data)
  (; UnCgCurtailFraction) = data

  #
  # Initialize curtailment fractions to zero
  #  
  @. UnCgCurtailFraction = 0.0

  #
  # First Pass
  #
  Pass = 1
  CgProduction(data)
  CogenSalesAndElectricPurchases(data)
  CgCurtailments(data)

  #
  # Second Pass
  #
  Pass = 2
  CgProduction(data)
  CogenSalesAndElectricPurchases(data)
  CgUnitGridSales(data)
end

end # module EDispatchCg
