#
# EContractDevelopment.jl
#

module EContractDevelopment

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
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  AFC::VariableArray{2} = ReadDisk(db,"EOutput/AFC",year) #[Plant,GenCo,Year]  Average Fixed Costs ($/KW)
  AFCM::VariableArray{1} = ReadDisk(db,"EGInput/AFCM",year) #[GenCo,Year]  Average Fixed Cost Multiplier ($/$)
  ArGenMap::VariableArray{2} = ReadDisk(db,"EGInput/ArGenMap") #[Area,GenCo]  Area from which GenCo gets Prices (Map)
  AVC::VariableArray{2} = ReadDisk(db,"EOutput/AVC",year) #[Plant,GenCo,Year]  Average Variable Costs ($/MWh)
  Capacity::VariableArray{5} = ReadDisk(db,"EOutput/Capacity",year) #[Area,GenCo,Plant,TimeP,Month,Year]  Capacity under Contract (MW)
  Energy::VariableArray{3} = ReadDisk(db,"EOutput/Energy",year) #[Area,GenCo,Plant,Year]  Energy Limit on Contracts (GWh/Yr)
  GC::VariableArray{3} = ReadDisk(db,"EOutput/GC",year) #[Plant,Node,GenCo,Year]  Generation Capacity (MW)
  GCap::VariableArray{2} = ReadDisk(db,"EOutput/GCap",year) #[Plant,GenCo,Year]  Generating Capacity (MW)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  Inflation::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",year) #[Area,Year]  Inflation Index ($/$)
  LDCSA::VariableArray{2} = ReadDisk(db,"EOutput/LDCSA",year) #[Day,Area,Year]  Annual System Load Curve (MW)
  LLMax::VariableArray{4} = ReadDisk(db,"EGInput/LLMax",year) #[Node,NodeX,TimeP,Month,Year]  Maximum Loading on Transmission Lines (MW)
  PAF::VariableArray{2} = ReadDisk(db,"EOutput/PAF",year) #[Plant,GenCo,Year]  Plant Availability Fractor (MW/MW)
  PCF::VariableArray{2} = ReadDisk(db,"EGOutput/PCF",year) #[Plant,GenCo,Year]  Plant Capacity Factor (MW/MW)
  SelfCap::VariableArray{2} = ReadDisk(db,"EOutput/SelfCap",year) #[Area,GenCo,Year]  Fraction of Capacity Sold through Self Dealing (MW/MW)
  SelfFr::VariableArray{2} = ReadDisk(db,"EOutput/SelfFr",year) #[Area,GenCo,Year]  Self Dealing Fraction as Output (MW/MW)
  SelfG::VariableArray{2} = ReadDisk(db,"EInput/SelfG",year) #[Area,GenCo,Year]  Minimum Fraction of GenCo Total Capacity purchased by Area (MW/MW)
  SelfPlant::VariableArray{3} = ReadDisk(db,"EInput/SelfPlant",year) #[Plant,Area,GenCo,Year]  Minimum Fraction of GenCo Plant Capacity purchased by Area (MW/MW)
  SelfR::VariableArray{2} = ReadDisk(db,"EInput/SelfR",year) #[Area,GenCo,Year]  Minimum Fraction of LSE Load purchased from GenCo (MW/MW)
  UCCost::VariableArray{3} = ReadDisk(db,"EOutput/UCCost",year) #[Area,GenCo,Plant,Year]  Contract Capacity Cost (US$/KW)
  UECOST::VariableArray{3} = ReadDisk(db,"EOutput/UECOST",year) #[Area,GenCo,Plant,Year]  Contract Energy Cost (US$/MWh)
  xCapacity::VariableArray{5} = ReadDisk(db,"EInput/xCapacity",year) #[Area,GenCo,Plant,TimeP,Month,Year]  Capacity for Exogenous Contracts (MW)
  xCapSw::VariableArray{3} = ReadDisk(db,"EInput/xCapSw",year) #[Area,GenCo,Plant,Year]  Switch for Exogenous Contract (1=Contract)
  xEnergy::VariableArray{3} = ReadDisk(db,"EInput/xEnergy",year) #[Area,GenCo,Plant,Year]  Energy Limit on Exogenous Contracts (GWh/Yr)
  xExchangeRate::VariableArray{1} = ReadDisk(db,"MInput/xExchangeRate",year) #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  xInflationNation::VariableArray{1} = ReadDisk(db,"MInput/xInflationNation",year) #[Nation,Year]  Inflation Index ($/$)
  # xInflationUS::VariableArray{1} = ReadDisk(db,"MInput/xInflationUS",year) #[PointerUS,Year]  Inflation Index ($/$)
  xUCCost::VariableArray{3} = ReadDisk(db,"EInput/xUCCost",year) #[Area,GenCo,Plant,Year]  Capacity Cost for Exogenous Contracts (Real US$/KW)
  xUECost::VariableArray{3} = ReadDisk(db,"EInput/xUECost",year) #[Area,GenCo,Plant,Year]  Energy Cost for Exogenous Contracts (Real US$/MWh)

  #
  # Scratch Variables
  #
  LLMaxTemp::VariableArray{2} = zeros(Float32,length(Node),length(NodeX))
end

# function GetContractInputs(data::Data)
#   # 23.09.26, LJD: Procedure empty and uncalled in Promula
# end

function GenCoContractCapacity(data::Data)
  (; db,year) = data
  (; GenCos,Nodes,Plants) = data #sets
  (; GC,GCap) = data

  for genco in GenCos, plant in Plants
    GCap[plant,genco] = sum(GC[plant,node,genco] for node in Nodes)
  end
  
  WriteDisk(db,"EOutput/GCap",year,GCap)

end

function GenCoContractCapacityForNL(data::Data,area)
  (; db,year) = data
  (; Area,GenCo,Months,Node,Nodes,NodeX,Plants,TimePs) = data #sets
  (; GC,GCap,LLMax) = data
  (; LLMaxTemp) = data

  #
  # In Newfoundland (NL) the island node (NL) is not connected to Labrador 
  # node (LB), therefore the self dealing contracts are only with the island 
  # node (NL). J. Amlin 3/12/08. However, once the tranmsision line is built, 
  # then NL island (NL) can sign contracts with Labrador (LB) 
  # Jeff Amlin 2/16/11
  #
  if Area[area] == "NL"
    genco = Select(GenCo,"NL")
    nl = Select(Node,"NL")
    lb = Select(NodeX,"LB")
    LLMaxTemp[nl,lb] = minimum(LLMax[nl,lb,timep,month] for month in Months, timep in TimePs)
    if LLMaxTemp[nl,lb] == 0
      for plant in Plants

        #
        # 23.09.26, LJD: revised for ease to prevent passing set selections
        #
        GCap[plant,genco] = sum(GC[plant,nl,genco])
      end
    else
      for plant in Plants
        GCap[plant,genco] = sum(GC[plant,node,genco] for node in Nodes)
      end
    end
  end
  
  WriteDisk(db,"EOutput/GCap",year,GCap)

end

function ContractFractionOfCapacityAndLoad(data::Data,area)
  (; db,year) = data
  (; Area,Day,GenCos,Plants) = data #sets
  (; GCap,LDCSA,SelfCap,SelfFr,SelfG,SelfR) = data

  Peak = Select(Day,"Peak")
  #
  # Contract Fraction (SelFr) is the maximum of the fraction of
  # capacity (SelfG) which the Area is required to purchase times
  # the GenCo capacity (GCap) or the fraction of their load which
  # the Area would like to purchase (SelfR) times the peak demand
  # (LDCSA), but not more than the capacity available (GCap).
  #
  if Area[area] != "NB"
    for genco in GenCos
      SelfCap[area,genco] = max(sum(GCap[plant,genco] for plant in Plants)*SelfG[area,genco],
                            min(LDCSA[Peak,area]*SelfR[area,genco],
                                sum(GCap[plant,genco] for plant in Plants)))
    end
  else
    for genco in GenCos
      SelfCap[area,genco] = sum(GCap[plant,genco] for plant in Plants)*SelfG[area,genco]
    end
  end

  #
  # 23.10.11, LJD: Attempted to add a WriteDisk for SelfCap, which was not in Promula, 
  # but currently does not work. TODOLater Reexamine this?
  #
  for genco in GenCos
    @finite_math SelfFr[area,genco] = SelfCap[area,genco]/
                                      sum(GCap[plant,genco] for plant in Plants)
  end

  WriteDisk(db,"EOutput/SelfCap",year,SelfCap)
  WriteDisk(db,"EOutput/SelfFr",year,SelfFr)  
end

function CapacityUnderContract(data::Data,area)
  (; db,year) = data
  (; GenCos,Months,Plants,TimePs) = data #sets
  (; Capacity,GCap,SelfFr,SelfPlant) = data

  for month in Months, timep in TimePs, plant in Plants, genco in GenCos
    Capacity[area,genco,plant,timep,month] = max(GCap[plant,genco]*SelfFr[area,genco],
                                             GCap[plant,genco]*SelfPlant[plant,area,genco])
  end

  WriteDisk(db,"EOutput/Capacity",year,Capacity)
end

function ContractEnergyLimit(data::Data,area)
  (; db,year) = data
  (; GenCos,Months,Plants,TimePs) = data #sets
  (; Capacity,Energy,HDHours,PCF) = data

  for plant in Plants, genco in GenCos
    Energy[area,genco,plant] = sum(Capacity[area,genco,plant,timep,month]*PCF[plant,genco]*HDHours[timep,month] for month in Months, timep in TimePs)/1000
  end

  WriteDisk(db,"EOutput/Energy",year,Energy)
end

function PeakingEnergyLimit(data::Data,area)
  (; db,year) = data
  (; GenCos,Months,Plant,Plants,TimePs) = data #sets
  (; Capacity,Energy,HDHours,PAF) = data

  #
  # For peaking units (whose capacity factor is very low) the estimate
  # of the amount of power avialiable for sale is the availaibly of the
  # unit (PAF) instead of the capacity factor (PCF).
  #
  for plant in Plants
    if Plant[plant] == "OGCT"
      for genco in GenCos
        Energy[area,genco,plant] = sum(Capacity[area,genco,plant,timep,month]*PAF[plant,genco]*HDHours[timep,month] for month in Months, timep in TimePs)/1000
      end
    end
  end

  WriteDisk(db,"EOutput/Energy",year,Energy)
end

function CapacityAndEnergyCosts(data::Data,area)
  (; GenCos,Plants) = data #sets
  (; AFC,AFCM,AVC,UCCost,UECOST,xExchangeRate) = data

  for plant in Plants, genco in GenCos
    @finite_math UCCost[area,genco,plant] = AFC[plant,genco]*AFCM[genco]/xExchangeRate[area]
    @finite_math UECOST[area,genco,plant] = AVC[plant,genco]/xExchangeRate[area]
  end
end

function UseEndogenousCostsForExogenousContracts(data::Data,area,genco,plant)
  (; Nation) = data #sets
  (; AFC,AFCM,AVC,xUCCost,xExchangeRate,xInflationNation,xUECost) = data

  US = Select(Nation,"US")

  @finite_math xUCCost[area,genco,plant] = AFC[plant,genco]*AFCM[genco]/xExchangeRate[area]/xInflationNation[US]
  @finite_math xUECost[area,genco,plant] = AVC[plant,genco]/xExchangeRate[area]/xInflationNation[US]
end

function AverageContractFixedCost(data::Data,area,genco,plant)
  (; Months,Nation,TimePs) = data #sets
  (; Capacity,UCCost,xUCCost,xCapacity,xInflationNation) = data

  US = Select(Nation,"US")

  TempCost = sum(UCCost[area,genco,plant]*Capacity[area,genco,plant,timep,month]+
           xUCCost[area,genco,plant]*xInflationNation[US]*xCapacity[area,genco,plant,timep,month] for month in Months, timep in TimePs)
  TempWeight = sum(Capacity[area,genco,plant,timep,month]+xCapacity[area,genco,plant,timep,month] for month in Months, timep in TimePs)

  @finite_math UCCost[area,genco,plant] = TempCost/TempWeight
end

function AverageContractVariableCost(data::Data,area,genco,plant)
  (; Nation) = data #sets
  (; Energy,UECOST,xEnergy,xInflationNation,xUECost) = data

  US = Select(Nation,"US")

  @finite_math UECOST[area,genco,plant] = (UECOST[area,genco,plant]*Energy[area,genco,plant]+xUECost[area,genco,plant]*xInflationNation[US]*xEnergy[area,genco,plant])/(Energy[area,genco,plant]+xEnergy[area,genco,plant])
end

function AddExogenousCapacity(data::Data,area,genco,plant)
  (; Months,TimePs) = data #sets
  (; Capacity,xCapacity) = data

  for month in Months, timep in TimePs
    Capacity[area,genco,plant,timep,month] = Capacity[area,genco,plant,timep,month]+xCapacity[area,genco,plant,timep,month]
  end
end

function AddExogenousEnergy(data::Data,area,genco,plant)
  (; Energy,xEnergy) = data

  Energy[area,genco,plant] = Energy[area,genco,plant]+xEnergy[area,genco,plant]
end

function SaveContracts(data::Data)
  (; db,year) = data
  # (; Area,GenCo,Month,Plant,TimeP) = data #sets
  (; Capacity,Energy,UCCost,UECOST) = data

  WriteDisk(db,"EOutput/Capacity",year,Capacity)
  WriteDisk(db,"EOutput/Energy",year,Energy)
  WriteDisk(db,"EOutput/UCCost",year,UCCost)
  WriteDisk(db,"EOutput/UECOST",year,UECOST)
end

function DevelopContracts(data::Data)
  (; Areas,GenCos,Plants) = data #sets
  (; xCapSw) = data

  # @info "  EContractDevelopment.jl - DevelopContracts"

  # 
  # GetContractInputs # Uncalled in Promula
  #

  #
  # Endogenous Contracts
  #
  for area in Areas
    GenCoContractCapacity(data)
    GenCoContractCapacityForNL(data,area)
    ContractFractionOfCapacityAndLoad(data,area)
    CapacityUnderContract(data,area)
    ContractEnergyLimit(data,area)
    PeakingEnergyLimit(data,area)
    CapacityAndEnergyCosts(data,area)
  end
  #
  # Exogenous Contracts
  #
  for plant in Plants, genco in GenCos, area in Areas
    if xCapSw[area,genco,plant] > 0
      if xCapSw[area,genco,plant] == 2
        UseEndogenousCostsForExogenousContracts(data,area,genco,plant)
      end
      AverageContractFixedCost(data,area,genco,plant)
      AverageContractVariableCost(data,area,genco,plant)
      AddExogenousCapacity(data,area,genco,plant)
      AddExogenousEnergy(data,area,genco,plant)

    end
  end

  SaveContracts(data)

end

end # module EContractDevelopment
