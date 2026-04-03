#
# EGenerationSummary.jl
#

module EGenerationSummary

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
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))

  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")

  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))

  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))

  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))

  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ACE::VariableArray{2} = ReadDisk(db,"EOutput/ACE",year) #[Plant,GenCo,Year]  Average Cost of Energy ($/MWh)
  AFC::VariableArray{2} = ReadDisk(db,"EOutput/AFC",year) #[Plant,GenCo,Year]  Average Fixed Costs ($/KW)
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  AVC::VariableArray{2} = ReadDisk(db,"EOutput/AVC",year) #[Plant,GenCo,Year]  Average Variable Costs ($/MWh)
  CCR::VariableArray{2} = ReadDisk(db,"EGOutput/CCR",year) #[Plant,Area,Year]  Capital Charge Rate (1/Yr)
  EGA::VariableArray{2} = ReadDisk(db,"EGOutput/EGA",year) #[Plant,GenCo,Year]  Electricity Generated (GWh/Yr)
  EGAvailable::VariableArray{4} = ReadDisk(db,"EGOutput/EGAvailable",year) #[TimeP,Month,Plant,Area,Year]  Generation Available after Dispatch (GWh/Yr)
  EGNDA::VariableArray{3} = ReadDisk(db,"EGOutput/EGNDA",year) #[Plant,Node,GenCo,Year]  Electricity Generation (GWh/Yr)
  EGNDAuu::VariableArray{3} = ReadDisk(db,"EGOutput/EGNDAuu",year) #[Plant,Node,GenCo,Year]  Electricity Generation (GWh/Yr)
  FPECC::VariableArray{3} = ReadDisk(db,"SOutput/FPECC",year) #[Fuel,ECC,Area,Year]  Fuel Prices excluding Emission Costs ($/mmBtu)
  FPECCCFSCP::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSCP",year) #[Fuel,ECC,Area,Year]  Fuel Prices w/CFS and Carbon Price ($/mmBtu)
  FPECCCFSCPNet::VariableArray{3} = ReadDisk(db,"SOutput/FPECCCFSCPNet",year) #[Fuel,ECC,Area,Year]  Fuel Prices w/CFS and Net Carbon Price ($/mmBtu)
  FPF::VariableArray{3} = ReadDisk(db,"SOutput/FPF",year) #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  GCG::VariableArray{2} = ReadDisk(db,"EOutput/GCG",year) #[Plant,GenCo,Year]  Generation Capacity (MW)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HDPrA::VariableArray{3} = ReadDisk(db,"EOutput/HDPrA",year) #[Node,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
  PAF::VariableArray{2} = ReadDisk(db,"EOutput/PAF",year) #[Plant,GenCo,Year]  Plant Availability Fractor (MW/MW)
  PCF::VariableArray{2} = ReadDisk(db,"EGOutput/PCF",year) #[Plant,GenCo,Year]  Plant Capacity Factor (MW/MW)
  SICstG::VariableArray{1} = ReadDisk(db,"EOutput/SICstG",year) #[GenCo,Year]  Stranded Investment Cost by GenCo (M$/Yr)
  StorageCosts::VariableArray{1} = ReadDisk(db,"EGOutput/StorageCosts",year) #[Area,Year]  Cost of Generation for Filling Storage (M$/Yr)
  StorageEG::VariableArray{1} = ReadDisk(db,"EGOutput/StorageEG",year) #[Area,Year]  Electricity Generated from Storage Technologies (GWh/Yr)
  StorageEnergy::VariableArray{1} = ReadDisk(db,"EGOutput/StorageEnergy",year) #[Area,Year]  Electricity Required to Recharge Storage Technologies (GWh/Yr)
  StorageNetRevenue::VariableArray{1} = ReadDisk(db,"EGOutput/StorageNetRevenue",year) #[Area,Year]  Net Revenue from Storage Operations (M$/Yr)
  StorageRevenue::VariableArray{1} = ReadDisk(db,"EGOutput/StorageRevenue",year) #[Area,Year]  Revenue from Storage Generation (M$/Yr)
  StorageUnitCosts::VariableArray{1} = ReadDisk(db,"EGOutput/StorageUnitCosts",year) #[Area,Year]  Storage Energy Unit Costs ($/MWh)
  StorCurtailed::VariableArray{3} = ReadDisk(db,"EGOutput/StorCurtailed",year) #[TimeP,Month,Node,Year]  Curtailed Generation which Recharges Storage (GWh/Yr)
  StorEG::VariableArray{3} = ReadDisk(db,"EGOutput/StorEG",year) #[TimeP,Month,Node,Year]  Electricity Generated from Storage (GWh/Yr)
  StorEnergy::VariableArray{3} = ReadDisk(db,"EGOutput/StorEnergy",year) #[TimeP,Month,Node,Year]  Electricity Required to Recharge Storage (GWh/Yr)
  ThermalBatterySwitch::VariableArray{2} = ReadDisk(db,"SInput/ThermalBatterySwitch",year) #[Plant,Area,Year]  Plants which provide Generation for Thermal Batteries (1=Yes)
  ThermalAvailable::VariableArray{1} = ReadDisk(db,"SOutput/ThermalAvailable",year) #[Area,Year]  Generation Available for Thermal Batteries (GWh/Yr)
  UnAFC::VariableArray{1} = ReadDisk(db,"EGOutput/UnAFC",year) #[Unit,Year]  Average Fixed Costs ($/KW)
  UnArea::Vector{String} = ReadDisk(db,"EGInput/UnArea") #[Unit]  Area Pointer
  UnAVC::VariableArray{1} = ReadDisk(db,"EGOutput/UnAVC",year) #[Unit,Year]  Average Variable Costs ($/MWh)
  UnAVCMonth::VariableArray{2} = ReadDisk(db,"EGOutput/UnAVCMonth",year) #[Unit,Month,Year]  Average Monthly Variable Costs ($/MWh)
  UnCode::Vector{String} = ReadDisk(db,"EGInput/UnCode") #[Unit]  Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnCounter::Float32 = ReadDisk(db,"EGInput/UnCounter",year) #[Year]  Number of Units
  UnDmd::VariableArray{2} = ReadDisk(db,"EGOutput/UnDmd",year) #[Unit,FuelEP,Year]  Energy Demands (TBtu)
  UnEffStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnEffStorage") #[Unit]  Storage Efficiency (GWH/GWH)
  UnEG::VariableArray{3} = ReadDisk(db,"EGOutput/UnEG",year) #[Unit,TimeP,Month,Year]  Generation (GWh)
  UnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGA",year) #[Unit,Year]  Net Generation (GWh)
  UnEGAvailable::VariableArray{3} = ReadDisk(db,"EGOutput/UnEGAvailable",year) #[Unit,TimeP,Month,Year]  Generation Available after Dispatch (GWh/Yr)
  UnEGC::VariableArray{3} = ReadDisk(db,"EGOutput/UnEGC",year) #[Unit,TimeP,Month,Year]  Effective Generating Capacity (MW)
  UnEGGross::VariableArray{1} = ReadDisk(db,"EGOutput/UnEGGross",year) #[Unit,Year]  Gross Generation (GWh/Yr)
  UnFlFr::VariableArray{2} = ReadDisk(db,"EGOutput/UnFlFr",year) #[Unit,FuelEP,Year]  Fuel Fraction (Btu/Btu)
  UnFP::VariableArray{2} = ReadDisk(db,"EGOutput/UnFP",year) #[Unit,Month,Year]  Fuel Price ($/mmBtu)
  UnGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnGC",year) #[Unit,Year]  Gross Generating Capacity (MW)
  UnGCNet::VariableArray{1} = ReadDisk(db,"EGOutput/UnGCNet",year) #[Unit,Year]  Net Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db,"EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{1} = ReadDisk(db,"EGInput/UnHRt",year) #[Unit,Year]  Heat Rate (BTU/KWh)
  UnNA::VariableArray{1} = ReadDisk(db,"EGOutput/UnNA",year) #[Unit,Year]  Net Asset Value of Generating Unit (M$)
  UnNode::Vector{String} = ReadDisk(db,"EGInput/UnNode") #[Unit]  Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") #[Unit]  On-Line Date (Year)
  UnOOR::VariableArray{1} = ReadDisk(db,"EGCalDB/UnOOR",year) #[Unit,Year]  Operational Outage Rate (MW/MW)
  UnOUEG::VariableArray{1} = ReadDisk(db,"EGOutput/UnOUEG",year) #[Unit,Year]  Own Use Generation (GWh/Yr)
  UnOUGC::VariableArray{1} = ReadDisk(db,"EGOutput/UnOUGC",year) #[Unit,Year]  Own Use Generating Capacity (MW)
  UnOUREG::VariableArray{1} = ReadDisk(db,"EGInput/UnOUREG",year) #[Unit,Year]  Own Use Rate for Generation (GWh/GWh)
  UnOURGC::VariableArray{1} = ReadDisk(db,"EGInput/UnOURGC",year) #[Unit,Year]  Own Use Rate for Generating Capacity (MW/MW)
  UnPCF::VariableArray{1} = ReadDisk(db,"EGOutput/UnPCF",year) #[Unit,Year]  Maximum Unit Capacity Factor (MW/MW)
  UnPCFMax::VariableArray{1} = ReadDisk(db,"EGInput/UnPCFMax",year) #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPCFuu::VariableArray{1} = ReadDisk(db,"EGOutput/UnPCFuu",year) #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db,"EGInput/UnPlant") #[Unit]  Plant Type
  UnPoTAv::VariableArray{3} = ReadDisk(db,"EGOutput/UnPoTAv",year) #[Unit,FuelEP,Poll,Year]  Average Pollution Tax Rate ($/MWh)
  UnPoTxR::VariableArray{3} = ReadDisk(db,"EGOutput/UnPoTxR",year) #[Unit,FuelEP,Poll,Year]  Marginal Pollution Tax Rate ($/MWh)
  UnRes::VariableArray{1} = ReadDisk(db,"EGOutput/UnRes",year) #[Unit,Year]  Generation while Unit is Forced On to Provide Reserves (GWh)
  UnResFlag::VariableArray{3} = ReadDisk(db,"EGOutput/UnResFlag",year) #[Unit,TimeP,Month,Year]  Flag to Indicate if Unit is Forced On to Provide Reserves (1=Yes)
  UnRetire::VariableArray{1} = ReadDisk(db,"EGInput/UnRetire",year) #[Unit,Year]  Retirement Date (Year)
  UnSector::Vector{String} = ReadDisk(db,"EGInput/UnSector") #[Unit]  Unit Type (Utility or Industry)
  UnSLDPR::VariableArray{1} = ReadDisk(db,"EGOutput/UnSLDPR",year) #[Unit,Year]  Depreciation (M$/Yr)
  UnStorage::VariableArray{1} = ReadDisk(db,"EGInput/UnStorage") #[Unit]  Storage Switch (1=Storage Unit)
  UnStorCurtailed::VariableArray{3} = ReadDisk(db,"EGOutput/UnStorCurtailed",year) #[Unit,TimeP,Month,Year]  Curtailed Generation used to Recharge Storage (GWh/Yr)
  UnXSw::VariableArray{1} = ReadDisk(db,"EGInput/UnXSw",year) #[Unit,Year]  Exogneous Unit Data Switch (0 = Exogenous)
  UUnEGA::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGA",year) #[Unit,Year]  Endogenous Generation (GWh)
  UUnEGAve::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGAve",year) #[Unit,Year]  Average Endogenous Generation (GWh)
  UUnEGAvePrior::VariableArray{1} = ReadDisk(db,"EGOutput/UUnEGAve",prior) #[Unit,Prior]  Average Endogenous Generation for Previous Year (GWh)
  xUnEGA::VariableArray{1} = ReadDisk(db,"EGInput/xUnEGA",year) #[Unit,Year]  Historical Unit Generation

  AFCCum::VariableArray{2} = zeros(Float32,length(Plant),length(GenCo)) # Accumulated Average Fixed Costs ($/KW)
  AVCCum::VariableArray{2} = zeros(Float32,length(Plant),length(GenCo)) # Accumulated Average Variable Costs ($/MWh)
  EGCum::VariableArray{2} = zeros(Float32,length(Plant),length(GenCo)) # Accumulated Electricity Generated (GWh/Yr)
  GCCum::VariableArray{2} = zeros(Float32,length(Plant),length(GenCo)) # Accumulated Generation Capacity (MW)
  PAFCum::VariableArray{2} = zeros(Float32,length(Plant),length(GenCo)) # Accumulated Plant Availablity Factor (MW/MW)

  # 
  # Scratch Variables
  #
  temp_denom::VariableArray{3} = zeros(Float32,length(Fuel),length(ECC),length(Area))
  temp_numer::VariableArray{3} = zeros(Float32,length(Fuel),length(ECC),length(Area))
end

function  GetUnitSets(data::Data,unit)
  (; Area,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant) = data

  genco = Select(GenCo,UnGenCo[unit])
  plant = Select(Plant,UnPlant[unit])
  node = Select(Node,UnNode[unit])
  area = Select(Area,UnArea[unit])

  return genco,plant,node,area
end

function GetUtilityUnits(data::Data)
  (; CTime) = data
  (; UnCogen,UnCounter,UnOnLine,UnRetire) = data

  units = 1:Int(UnCounter)
  unitsol = Select(UnOnLine,<=(CTime))
  unitsret = Select(UnRetire,>(CTime))
  unitscg0 = Select(UnCogen, ==(0.0))

  UtilityUnits = intersect(units,unitsol,unitsret,unitscg0)

  return UtilityUnits
end

function UnitReserves(data::Data,UtilityUnits)
  (; db,year) = data
  (; Months,TimePs) = data
  (; UnEG,UnRes,UnResFlag) = data
  
  #
  # Generation when Unit was Forced On to Provide Reserves
  #
  for unit in UtilityUnits
    UnRes[unit] = sum(UnEG[unit,timep,month]*UnResFlag[unit,timep,month] for month in Months, timep in TimePs)
  end

  WriteDisk(db,"EGOutput/UnRes",year,UnRes)
end

function InitializeGenerationVariables(data::Data)
  (; EGNDA,EGNDAuu,EGAvailable) = data

  @. EGAvailable = 0.0
  @. EGNDA = 0.0
  @. EGNDAuu = 0.0

end

function UnitGeneration(data::Data,unit)
  (; Months,TimePs) = data
  (; UnEG,UnEGA,UnGC,UnStorCurtailed,UnXSw,UUnEGA,xUnEGA) = data

  UUnEGA[unit] = sum(UnEG[unit,timep,month]+UnStorCurtailed[unit,timep,month]
                     for month in Months, timep in TimePs)
  
  #
  # If UnXSw equals 0.0 then we want generation (UnEGA) to exactly
  # equal the historical generation (xUnEGA), but save the model
  # generated value (UUnEGA)
  #
  if (UnXSw[unit] == 0) && (UnGC[unit] > 0)
    UnEGA[unit] = xUnEGA[unit]
  else
    UnEGA[unit] = UUnEGA[unit]
  end
end

function GenerationAvailable(data::Data,unit,plant,area)
  (; Months,TimePs) = data
  (; EGAvailable,HDHours,UnEG,UnEGC,UnGC,UnOOR,UnEGAvailable,UnPCFMax,UnStorage) = data

  for month in Months, timep in TimePs
    @finite_math UnEGAvailable[unit,timep,month] =
      max((UnGC[unit]*UnPCFMax[unit]*HDHours[timep,month] /
      1000-UnEG[unit,timep,month]),0)
  end
  for month in Months, timep in TimePs
    EGAvailable[timep,month,plant,area]+=UnEGAvailable[unit,timep,month]*(1-UnStorage[unit])
  end

end

function GenerationByNode(data::Data,unit,genco,plant,node)
  (; EGNDA,EGNDAuu,UnEGA,UUnEGA) = data

  EGNDA[plant,node,genco] = EGNDA[plant,node,genco]+UnEGA[unit]
  EGNDAuu[plant,node,genco] = EGNDAuu[plant,node,genco]+UUnEGA[unit]
end

function GenerationByUnit(data::Data,UtilityUnits)
  (; db,year) = data
  (; EGAvailable,EGNDA,EGNDAuu,UnEGA,UUnEGA,UnEGAvailable) = data

  InitializeGenerationVariables(data)

  for unit in UtilityUnits
    genco,plant,node,area = GetUnitSets(data,unit)
    UnitGeneration(data,unit)
    GenerationAvailable(data,unit,plant,area)
    GenerationByNode(data,unit,genco,plant,node)
  end

  WriteDisk(db,"EGOutput/EGAvailable",year,EGAvailable)
  WriteDisk(db,"EGOutput/EGNDA",year,EGNDA)
  WriteDisk(db,"EGOutput/EGNDAuu",year,EGNDAuu)
  WriteDisk(db,"EGOutput/UnEGA",year,UnEGA)
  WriteDisk(db,"EGOutput/UUnEGA",year,UUnEGA)
  WriteDisk(db,"EGOutput/UnEGAvailable",year,UnEGAvailable)
end

function OwnUseGenerationAndCapacity(data::Data,UtilityUnits)
  (; UnEGA,UnEGGross,UnGC,UnGCNet,UnOUEG,UnOUGC,UnOUREG,UnOURGC) = data

  for unit in UtilityUnits
    @finite_math UnEGGross[unit] = UnEGA[unit]/(1-UnOUREG[unit])
    UnOUEG[unit] = UnEGGross[unit]-UnEGA[unit]
    UnGCNet[unit] = UnGC[unit]*(1-UnOURGC[unit])
    UnOUGC[unit] = UnGC[unit]-UnGCNet[unit]
  end
end

function GenerationByPlantAndCompany(data::Data)
  (; db,year) = data
  (; GenCos,Nodes,Plants) = data
  (; EGA,EGNDA) = data

  for genco in GenCos, plant in Plants
    EGA[plant,genco] = sum(EGNDA[plant,node,genco] for node in Nodes)
  end

  WriteDisk(db,"EGOutput/EGA",year,EGA)
end

function UnitCapacityFactor(data::Data,UtilityUnits)
  (; UnEGA,UnGC,UnPCF,UnPCFuu,UUnEGA) = data

  for unit in UtilityUnits
    @finite_math UnPCF[unit] = UnEGA[unit]/(UnGC[unit]*8760/1000)
    @finite_math UnPCFuu[unit] = UUnEGA[unit]/(UnGC[unit]*8760/1000)
  end
end

function PlantCapacityFactor(data::Data)
  (; GenCos,Plants) = data
  (; EGA,GCG,PCF) = data

  for genco in GenCos, plant in Plants
    @finite_math PCF[plant,genco] = EGA[plant,genco]/(GCG[plant,genco]*8760/1000)
  end
end

function FuelAndEmissionPrices(data::Data)
  (; db,year) = data
  (; Area,ES,ECC,Fuel,Fuels,FuelEP,FuelEPs,Months,Poll,TimePs) = data
  (; FPECC,FPECCCFSCP,FPECCCFSCPNet,FPF,UnArea,UnCogen,UnEG,UnFP,UnFlFr,UnHRt,UnPoTAv,UnPoTxR,UnDmd) = data
  (; temp_numer,temp_denom) = data

  ecc = Select(ECC,"UtilityGen")
  es = Select(ES,"Electric")
  poll = Select(Poll,"CO2")

  #
  # 23.10.10, LJD: Needed to exclude "ROW" area, since there are no 
  # units with UnArea = ROW.
  # 
  for area in Select(Area,!=("ROW"))
    unitsa = Select(UnArea, ==(Area[area]))
    unitscg0 = Select(UnCogen, ==(0))
    units = intersect(unitsa,unitscg0)
    for fuel in Fuels, fuelep in FuelEPs
      if Fuel[fuel] == FuelEP[fuelep]
        temp_numer[fuel,ecc,area] = sum(UnFP[unit,month]*UnEG[unit,timep,month]*UnHRt[unit]*UnFlFr[unit,fuelep] for month in Months, timep in TimePs, unit in units)
        temp_denom[fuel,ecc,area] = sum(UnEG[unit,timep,month]*UnHRt[unit]*UnFlFr[unit,fuelep] for month in Months, timep in TimePs, unit in units)
        @finite_math FPECC[fuel,ecc,area] = temp_numer[fuel,ecc,area]/temp_denom[fuel,ecc,area]

        temp_numer[fuel,ecc,area] = sum(UnPoTxR[unit,fuelep,poll]*UnDmd[unit,fuelep] for unit in units)
        temp_denom[fuel,ecc,area] = sum(UnDmd[unit,fuelep] for unit in units)
        @finite_math FPECCCFSCP[fuel,ecc,area] = FPECC[fuel,ecc,area]+temp_numer[fuel,ecc,area]/temp_denom[fuel,ecc,area]

        temp_numer[fuel,ecc,area] = sum(UnPoTAv[unit,fuelep,poll]*UnDmd[unit,fuelep] for unit in units)
        temp_denom[fuel,ecc,area] = sum(UnDmd[unit,fuelep] for unit in units)
        @finite_math FPECCCFSCPNet[fuel,ecc,area] = FPECC[fuel,ecc,area]+temp_numer[fuel,ecc,area]/temp_denom[fuel,ecc,area]
      else
        FPECC[fuel,ecc,area] = FPF[fuel,es,area]
        FPECCCFSCP[fuel,ecc,area] = FPECC[fuel,ecc,area]
        FPECCCFSCPNet[fuel,ecc,area] = FPECC[fuel,ecc,area]
      end

    end
  end

  WriteDisk(db,"SOutput/FPECC",year,FPECC)
  WriteDisk(db,"SOutput/FPECCCFSCP",year,FPECCCFSCP)
  WriteDisk(db,"SOutput/FPECCCFSCPNet",year,FPECCCFSCPNet)

end

function InitializeAccumulationVariables(data::Data)
  (; AFCCum,GCCum,AVCCum,EGCum,PAFCum,SICstG) = data

  @. AFCCum = 0
  @. GCCum = 0
  @. AVCCum = 0
  @. EGCum = 0
  @. PAFCum = 0
  @. SICstG = 0

end

function UnitAverageGeneration(data::Data,unit)
  (; db,year) = data
  (; UUnEGA,UUnEGAve,UUnEGAvePrior) = data

  UUnEGAve[unit] = UUnEGAvePrior[unit]+(UUnEGA[unit]-UUnEGAvePrior[unit])/5

  # WriteDisk moved outside of loop
  # WriteDisk(db,"EGOutput/UUnEGAve",year,UUnEGAve)
end

function UnitFixedCostAccumulate(data::Data,unit,genco,plant)
  (; AFCCum,UnAFC,UnGC) = data

  AFCCum[plant,genco] = AFCCum[plant,genco]+UnAFC[unit]*max(UnGC[unit],0.000001)

end

function UnitCapacityAccumulate(data::Data,unit,genco,plant)
  (; GCCum,UnGC) = data

  GCCum[plant,genco] = GCCum[plant,genco]+max(UnGC[unit],0.000001)

end

function UnitVariableCostsAccumulate(data::Data,unit,genco,plant)
  (; AVCCum,UnAVC,UUnEGA,UUnEGAve,UnGC) = data

  if UnGC[unit] > 0.0
    AVCCum[plant,genco] = AVCCum[plant,genco]+
     UnAVC[unit]*max(UUnEGA[unit],UUnEGAve[unit],0.000001)
  end

end

function UnitGenerationAccumulate(data::Data,unit,genco,plant)
  (; EGCum,UUnEGA,UUnEGAve,UnGC) = data

  if UnGC[unit] > 0.0
    EGCum[plant,genco] = EGCum[plant,genco]+
      max(UUnEGA[unit],UUnEGAve[unit],0.000001)
  end
  
end

function UnitPAFAccumulate(data::Data,unit,genco,plant)
  (; Months,TimePs) = data
  (; PAFCum,UnEGC,HDHours) = data
  
  @finite_math PAFCum[plant,genco] = PAFCum[plant,genco]+
    sum(UnEGC[unit,timep,month]*HDHours[timep,month] for month in Months, timep in TimePs)/
    sum(HDHours[timep,month] for month in Months, timep in TimePs)
  
end

function StrandedInvestmentsForRetiredUnits(data::Data,unit,genco,plant,area)
  (; CCR,SICstG,UnNA,UnSLDPR) = data

  SICstG[genco] = SICstG[genco]+(UnNA[unit]*CCR[plant,area]+UnSLDPR[unit])
  
end

function AverageFixedCosts(data::Data)
  (; Plants,GenCos) = data
  (; AFC,AFCCum,GCCum) = data

  #
  # Average Fixed Costs (AFC) are weighted average of Unit Fixed Costs (UnAFC)
  #
  for genco in GenCos, plant in Plants
    @finite_math AFC[plant,genco] = AFCCum[plant,genco]/GCCum[plant,genco]
  end

end

function AverageVariableCosts(data::Data)
  (; Plants,GenCos) = data
  (; AVC,AVCCum,EGCum) = data

  #
  # Average Variable Costs (AVC) are weighted average of Unit Variable Costs (UnAVC)
  #
  for genco in GenCos, plant in Plants
    @finite_math AVC[plant,genco] = AVCCum[plant,genco]/EGCum[plant,genco]
  end

end

function AverageCostOfEnergy(data::Data)
  (; Plants,GenCos) = data
  (; ACE,AFCCum,AVCCum,EGCum) = data

  #
  # Average Cost of Energy (ACE) is weighted average of fixed and variable unit costs.
  #
  for genco in GenCos, plant in Plants
    @finite_math ACE[plant,genco] = (AFCCum[plant,genco]+AVCCum[plant,genco])/EGCum[plant,genco]
  end

end

function AveragePAF(data::Data)
  (; Plants,GenCos) = data
  (; PAF,PAFCum,GCCum) = data

  for genco in GenCos, plant in Plants
    @finite_math PAF[plant,genco] = PAFCum[plant,genco]/GCCum[plant,genco]
  end

end

function CheckOnline(data::Data,unit)
  (; CTime) = data
  (; UnCogen,UnOnLine,UnRetire) = data

  UnitIsOnline = "False"
  if (UnOnLine[unit] <= CTime) && (UnRetire[unit] > CTime) && (UnCogen[unit] == 0)
    UnitIsOnline = "True"
  end

  return UnitIsOnline
end

function CheckRetire(data::Data,unit)
  (; CTime) = data
  (; UnCogen,UnOnLine,UnRetire) = data

  UnitIsRetired = "False"
  if (UnOnLine[unit] <= CTime) && (UnRetire[unit] <= CTime) && (UnCogen[unit] == 0)
    UnitIsRetired = "True"
  end

  return UnitIsRetired
end

function AccumulateUnitCosts(data::Data,unit,genco,plant)

  UnitAverageGeneration(data,unit)
  UnitFixedCostAccumulate(data,unit,genco,plant)
  UnitCapacityAccumulate(data,unit,genco,plant)
  UnitVariableCostsAccumulate(data,unit,genco,plant)
  UnitGenerationAccumulate(data,unit,genco,plant)
  UnitPAFAccumulate(data,unit,genco,plant)

end

function FindAndSaveAverageCosts(data::Data)
  (; db,year) = data
  (; ACE,AFC,AVC,PAF,SICstG) = data

  #
  # ResetUnitSets
  #
  AverageFixedCosts(data)
  AverageVariableCosts(data)
  AverageCostOfEnergy(data)
  AveragePAF(data)

  WriteDisk(db,"EOutput/ACE",year,ACE)
  WriteDisk(db,"EOutput/AFC",year,AFC)
  WriteDisk(db,"EOutput/AVC",year,AVC)
  WriteDisk(db,"EOutput/PAF",year,PAF)
  WriteDisk(db,"EOutput/SICstG",year,SICstG)
end

function GenTotals(data::Data)
  (; db,year) = data
  (; PCF,UnEGGross,UnGCNet,UnOUEG,UnOUGC,UnPCF,UnPCFuu) = data

  # @info "EGenerationSummary - GenTotals"

  UtilityUnits = GetUtilityUnits(data)

  UnitReserves(data,UtilityUnits)
  GenerationByUnit(data,UtilityUnits)
  OwnUseGenerationAndCapacity(data,UtilityUnits)

  WriteDisk(db,"EGOutput/UnEGGross",year,UnEGGross)
  WriteDisk(db,"EGOutput/UnGCNet",year,UnGCNet)
  WriteDisk(db,"EGOutput/UnOUEG",year,UnOUEG)
  WriteDisk(db,"EGOutput/UnOUGC",year,UnOUGC)

  GenerationByPlantAndCompany(data)
  UnitCapacityFactor(data,UtilityUnits)
  PlantCapacityFactor(data)

  WriteDisk(db,"EGOutput/PCF",year,PCF)
  WriteDisk(db,"EGOutput/UnPCF",year,UnPCF)
  WriteDisk(db,"EGOutput/UnPCFuu",year,UnPCFuu)

  FuelAndEmissionPrices(data)

end

function VariableCosts(data::Data)
  (; db,year) = data
  (; Months,TimePs,Units) = data
  (; UnAVC,UnAVCMonth,UnEG) = data

  for unit in Units
    @finite_math UnAVC[unit] =
      sum(UnAVCMonth[unit,month]*max(UnEG[unit,timep,month],0.000001)
          for month in Months, timep in TimePs)/
      sum(max(UnEG[unit,timep,month],0.000001)
          for month in Months, timep in TimePs)
  end

  WriteDisk(db,"EGOutput/UnAVC",year,UnAVC)
end

function AverageCosts(data::Data)
  (; db,year) = data
  (; UnCounter,UUnEGAve) = data

  # @info "EGenerationSummary - AverageCosts"

  InitializeAccumulationVariables(data)

  for unit in 1:Int(UnCounter)
    genco,plant,node,area = GetUnitSets(data,unit)

    UnitIsOnline = CheckOnline(data,unit)
    if UnitIsOnline == "True"
      AccumulateUnitCosts(data,unit,genco,plant)
    end

    UnitIsRetired = CheckRetire(data,unit)
    if UnitIsRetired == "True"
      StrandedInvestmentsForRetiredUnits(data,unit,genco,plant,area)
    end
  end

  FindAndSaveAverageCosts(data)
  WriteDisk(db,"EGOutput/UUnEGAve",year,UUnEGAve)
end

function StorageSummary(data::Data)
  (; db,year) = data
  (; Areas,Months,TimePs,) = data
  (; HDPrA,StorageCosts,StorageEG,StorageEnergy,StorageNetRevenue,
    StorageRevenue,StorageUnitCosts,StorCurtailed,StorEG,StorEnergy,
    UnEffStorage,UnEG,UnStorage,UnStorCurtailed) = data


  TimePMax=length(TimePs)
  @. StorageCosts = 0
  @. StorageEG = 0
  @. StorageEnergy = 0
  @. StorageRevenue = 0
  @. StorCurtailed = 0
  @. StorEG = 0
  @. StorEnergy = 0

  UtilityUnits = GetUtilityUnits(data)
  for unit in UtilityUnits
    genco,plant,node,area = GetUnitSets(data,unit)

    for month in Months, timep in TimePs
      StorCurtailed[timep,month,node] = StorCurtailed[timep,month,node]+
        UnStorCurtailed[unit,timep,month]
    end

    if UnStorage[unit] == 1
    
      for month in Months, timep in TimePs
        
        StorEG[timep,month,node] = StorEG[timep,month,node]+UnEG[unit,timep,month]
        
        @finite_math StorEnergy[timep,month,node] = StorEnergy[timep,month,node]+
          UnEG[unit,timep,month]/UnEffStorage[unit]
      
      end
      
      StorageEG[area] = StorageEG[area]+
        sum(UnEG[unit,timep,month] for month in Months, timep in TimePs)
    
      @finite_math StorageEnergy[area] = StorageEnergy[area]+
        sum(max(UnEG[unit,timep,month],0.001) for month in Months, 
        timep in TimePs)/UnEffStorage[unit]
        
      StorageRevenue[area] = StorageRevenue[area]+
        sum(max(UnEG[unit,timep,month],0.001)*
        HDPrA[node,timep,month] for month in Months, timep in TimePs)
      
      @finite_math StorageCosts[area] = StorageCosts[area]+
            sum((max(UnEG[unit,timep,month],0.001)/UnEffStorage[unit]-
            UnStorCurtailed[unit,timep,month])*
            HDPrA[node,TimePMax,month] for month in Months, timep in TimePs)
    end
  end

  for area in Areas
    StorageNetRevenue[area] = StorageRevenue[area]-StorageCosts[area]

    @finite_math StorageUnitCosts[area] = StorageCosts[area]/StorageEnergy[area]
  end

  WriteDisk(db,"EGOutput/StorageCosts",year,StorageCosts)
  WriteDisk(db,"EGOutput/StorageEG",year,StorageEG)
  WriteDisk(db,"EGOutput/StorageEnergy",year,StorageEnergy)
  WriteDisk(db,"EGOutput/StorageNetRevenue",year,StorageNetRevenue)
  WriteDisk(db,"EGOutput/StorageRevenue",year,StorageRevenue)
  WriteDisk(db,"EGOutput/StorageUnitCosts",year,StorageUnitCosts)
  WriteDisk(db,"EGOutput/StorCurtailed",year,StorCurtailed)
  WriteDisk(db,"EGOutput/StorEG",year,StorEG)
  WriteDisk(db,"EGOutput/StorEnergy",year,StorEnergy)
end

function GenSummary(data::Data)

  GenTotals(data)
  VariableCosts(data)
  AverageCosts(data)
  StorageSummary(data)
end
end # module EGenerationSummary
