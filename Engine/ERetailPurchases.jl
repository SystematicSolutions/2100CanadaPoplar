#
# ERetailPurchases.jl
#

module ERetailPurchases

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
  Contracts::SetArray = ReadDisk(db,"MainDB/ContractsKey")
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))  
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node)) 
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant)) 
  PPSet::SetArray = ReadDisk(db,"EInput/PPSetKey")
  PPSets::Vector{Int} = collect(Select(PPSet))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP)) 
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  Capacity::VariableArray{5} = ReadDisk(db,"EOutput/Capacity",year) #[Area,GenCo,Plant,TimeP,Month,Year]  Capacity under Contract (MW)
  CnCap::VariableArray{4} = ReadDisk(db,"EOutput/CnCap") #[Contracts,Area,TimeP,Month]  Contract Capacity (MW)
  CnEG::VariableArray{4} = ReadDisk(db,"EOutput/CnEG") #[Contracts,Area,TimeP,Month]  Contract Generation (GWh)
  CnEnergy::VariableArray{4} = ReadDisk(db,"EOutput/CnEnergy") #[Contracts,Area,TimeP,Month]  Contract Energy (GWh)
  CnGenCo::VariableArray{4} = ReadDisk(db,"EOutput/CnGenCo") #[Contracts,Area,TimeP,Month]  Contract GenCo
  CnMDS::VariableArray{4} = ReadDisk(db,"EOutput/CnMDS") #[Contracts,Area,TimeP,Month]  Contract Maximum Demand Satisfied (MW)
  CnPlant::VariableArray{4} = ReadDisk(db,"EOutput/CnPlant") #[Contracts,Area,TimeP,Month]  Contract Plant Type
  CnUECost::VariableArray{4} = ReadDisk(db,"EOutput/CnUECost") #[Contracts,Area,TimeP,Month]  Contract Energy Cost (US$/MWh)
  EGA::VariableArray{2} = ReadDisk(db,"EOutput/EGA",year) #[Plant,Area,Year]  Electricity Dispatched (GWh/Yr)
  EGBI::VariableArray{3} = ReadDisk(db,"EOutput/EGBI",year) #[Area,GenCo,Plant,Year]  Electricity sold thru Contracts (GWh/Yr)
  EGBIPG::VariableArray{1} = ReadDisk(db,"EOutput/EGBIPG",year) #[Area,Year]  Electricity sold thru Contracts (GWh/Yr)
  EGBITM::VariableArray{5} = ReadDisk(db,"EOutput/EGBITM",year) #[Area,GenCo,Plant,TimeP,Month,Year]  Electricity sold thru Contracts (GWh/Yr)
  Energy::VariableArray{3} = ReadDisk(db,"EOutput/Energy",year) #[Area,GenCo,Plant,Year]  Energy Limit on Contracts (GWh/Yr)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HMADP::VariableArray{4} = ReadDisk(db,"EOutput/HMADP",year) #[Node,Area,TimeP,Month,Year]  Average Load in Interval (MW)
  HMEnergy::VariableArray{4} = ReadDisk(db,"EOutput/HMEnergy",year) #[Node,Area,TimeP,Month,Year]  Energy in Interval (GWh)
  HMPDP::VariableArray{4} = ReadDisk(db,"EOutput/HMPDP",year) #[Node,Area,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
  PPEGA::VariableArray{2} = ReadDisk(db,"EOutput/PPEGA",year) #[PPSet,Area,Year]  Spot Market Purchases (GWh)
  PPEGTM::VariableArray{3} = ReadDisk(db,"EOutput/PPEGTM",year) #[Area,TimeP,Month,Year]  Power Purchases (GWh)
  TPPEGA::VariableArray{1} = ReadDisk(db,"EOutput/TPPEGA",year) #[Area,Year]  Total Purchase Power (GWh)
  UECOST::VariableArray{3} = ReadDisk(db,"EOutput/UECOST",year) #[Area,GenCo,Plant,Year]  Contract Energy Cost (US$/MWh)
  
  HMPDPM::Float32 = 0.0 # Demand To Be Met (MW)

end

function MoveToNextContract(CnNumber)
#
  CnNumber = CnNumber+1
  return CnNumber
#
end

function CreateContract(data::Data,CnNumber,area,genco,plant,month,timep)
  (; Capacity,CnCap,CnEnergy,CnGenCo,CnPlant,CnUECost,Energy,HDHours,UECOST) = data
  
  CnGenCo[CnNumber,area,timep,month] = genco
  CnPlant[CnNumber,area,timep,month] = plant
  CnCap[CnNumber,area,timep,month] = Capacity[area,genco,plant,timep,month]
  CnEnergy[CnNumber,area,timep,month] = Energy[area,genco,plant]/8760*HDHours[timep,month]
  CnUECost[CnNumber,area,timep,month] = UECOST[area,genco,plant]
end

function MaxContractNumberExceeded(data::Data,area,genco,plant)
  (; year) = data
  (; Area,GenCo,Plant) = data

  @info "Contract between Area ",Area[area]," and GenCo ",GenCo[genco],
        " for Plant Type ",Plant[plant]," in year ",year,
        " exceeds Maximum Number of Contracts for this Area."
end

function CreateSpotMarket(data::Data,CnNumber,area,month,timep)
  (; Nodes) = data
  (; CnCap,CnEnergy,CnGenCo,CnPlant,CnUECost,HMEnergy,HMPDP) = data
  
  CnGenCo[CnNumber,area,timep,month] = 99
  CnPlant[CnNumber,area,timep,month] = 99
  CnCap[CnNumber,area,timep,month] = sum(HMPDP[node,area,timep,month] for node in Nodes)
  CnEnergy[CnNumber,area,timep,month] = sum(HMEnergy[node,area,timep,month] for node in Nodes)
  CnUECost[CnNumber,area,timep,month] = 9999
end

function SaveContracts(data::Data)
  (; db) = data
  (; CnGenCo,CnPlant,CnCap,CnEnergy,CnUECost) = data

  WriteDisk(db,"EOutput/CnGenCo",CnGenCo)
  WriteDisk(db,"EOutput/CnPlant",CnPlant)
  WriteDisk(db,"EOutput/CnCap",CnCap)
  WriteDisk(db,"EOutput/CnEnergy",CnEnergy)
  WriteDisk(db,"EOutput/CnUECost",CnUECost)
end

function LoadContractVariables(data::Data,CnNumber,area,month,timep)
  (; Contracts,GenCos,Plants) = data
  (; Capacity) = data

  CnNumber = 0
  
  # if Area[area] == "ON"
  #   @info Area[area], Month[month], timep
  #   @info "LoadContractVariables A CnNumber" CnNumber
  # end

  for plant in Plants,genco in GenCos
    if Capacity[area,genco,plant,timep,month] > 0
      CnNumber = MoveToNextContract(CnNumber)
      
      if CnNumber < length(Contracts)
        CreateContract(data,CnNumber,area,genco,plant,month,timep)
      else
        MaxContractNumberExceeded(data,area,genco,plant)
      end
    end
  end
  CnNumber = MoveToNextContract(CnNumber)

  CreateSpotMarket(data,CnNumber,area,month,timep)
  
  return CnNumber
end

function DemandPerInterval(data::Data,HMPDPM,area,month,timep)
  (; Nodes) = data
  (; HMADP) = data

  HMPDPM = sum(HMADP[node,area,timep,month] for node in Nodes)
end

function OrderContractsByCost(data::Data,CnNumber,area,month,timep)
  (; CnUECost) = data

  contracts = 1:CnNumber

  #
  # Sort Ascending Contracts using CnUECost
  #
  # TODOJulia Test Sort 23.12.11, LJD
  #
  # sort!(contracts; by = c -> CnUECost[c,area,timep,month])
  #
  contracts = contracts[sortperm(CnUECost[contracts,area,timep,month])]

  if isempty(contracts)
    contracts = 1:CnNumber
  end

  return contracts
end

function DemandMetByContract(data::Data,HMPDPM,contract,area,month,timep)
  (; db) = data
  (; CnCap,CnEnergy,CnMDS,HDHours) = data

  #
  # The maximum demand satisfied by each contract (CnMDS) is the minimum of the
  # effective contract capacity (CnCap),the peak demand (HMPDPM),and the
  # available energy (CnEnergy) divided by the hours in the period (HDHours).
  #
  CnMDS[contract,area,timep,month] = min(CnCap[contract,area,timep,month],HMPDPM,
                                       CnEnergy[contract,area,timep,month]/HDHours[timep,month]*1000)

  WriteDisk(db,"EOutput/CnMDS",CnMDS)

end

function DemandRemaining(data::Data,HMPDPM,contract,area,month,timep)
  (; CnMDS) = data

  HMPDPM=HMPDPM-CnMDS[contract,area,timep,month]
end

function ContractGeneration(data::Data,CnNumber,area,month,timep)
  (; db) = data
  (; CnEG,CnMDS,HDHours) = data

  for contract in 1:CnNumber
    CnEG[contract,area,timep,month] = CnMDS[contract,area,timep,month]*
                                    HDHours[timep,month]/1000
  end

  WriteDisk(db,"EOutput/CnEG",CnEG)
end

function DispatchContracts(data::Data,CnNumber,area,month,timep)
  (; HMPDPM) = data
  # (; Area,Month,CnUECost) = data

  HMPDPM = 0.00
  HMPDPM = DemandPerInterval(data,HMPDPM,area,month,timep)

  sorted_contracts = OrderContractsByCost(data::Data,CnNumber,area,month,timep)

  for contract in sorted_contracts
    DemandMetByContract(data,HMPDPM,contract,area,month,timep)
    HMPDPM = DemandRemaining(data,HMPDPM,contract,area,month,timep)
  end

  ContractGeneration(data,CnNumber,area,month,timep)

end

function GenerationIsFromContracts(data::Data,contract,area,month,timep)
  (; CnEG,CnGenCo,CnPlant,EGBITM) = data

  genco = Int(CnGenCo[contract,area,timep,month])
  plant = Int(CnPlant[contract,area,timep,month])
  
  EGBITM[area,genco,plant,timep,month] = CnEG[contract,area,timep,month]
end

function GenerationIsFromSpotMarket(data::Data,contract,area,month,timep)
  (; CnEG,PPEGTM) = data

  PPEGTM[area,timep,month] = CnEG[contract,area,timep,month]
end

function UnloadContractVariables(data::Data,CnNumber,area,month,timep)
  (; CnGenCo) = data

  for contract in 1:CnNumber
    if CnGenCo[contract,area,timep,month] != 99
      GenerationIsFromContracts(data,contract,area,month,timep)
    else
      GenerationIsFromSpotMarket(data,contract,area,month,timep)
    end
  end

end

function PurchasesSummation(data::Data)
  (; db,year) = data
  (; Areas,GenCos,Months,Plants,PPSet,PPSets,TimePs) = data #sets
  (; EGA,EGBI,EGBIPG,EGBITM,PPEGA,PPEGTM,TPPEGA) = data

  for plant in Plants,genco in GenCos,area in Areas
    EGBI[area,genco,plant] = sum(EGBITM[area,genco,plant,timep,month] for month in Months,timep in TimePs)
  end

  for plant in Plants,area in Areas
    EGA[plant,area] = sum(EGBI[area,genco,plant] for genco in GenCos)
  end


  for area in Areas
    EGBIPG[area] = sum(EGA[plant,area] for plant in Plants)

    baseppcontracts = Select(PPSet,"BasePP")

    PPEGA[baseppcontracts,area] = sum(PPEGTM[area,timep,month] for month in Months,timep in TimePs)

    TPPEGA[area] = sum(PPEGA[ppset,area] for ppset in PPSets)
  end

  WriteDisk(db,"EOutput/EGBI",year,EGBI)
  WriteDisk(db,"EOutput/EGA",year,EGA)
  WriteDisk(db,"EOutput/EGBIPG",year,EGBIPG)
  WriteDisk(db,"EOutput/PPEGA",year,PPEGA)
  WriteDisk(db,"EOutput/TPPEGA",year,TPPEGA)

end

function RetailPurchases(data::Data)
  (; db,year) = data
  (; Areas,Months,TimePs) = data #sets
  (; EGBITM,PPEGTM) = data

  @debug "Function Call RetailPurchases"

  CnNumber = 0 
  @. EGBITM = 0
  @. PPEGTM = 0
  
  for timep in TimePs,month in Months,area in Areas
    CnNumber = LoadContractVariables(data,CnNumber,area,month,timep)
    DispatchContracts(data,CnNumber,area,month,timep)
    UnloadContractVariables(data,CnNumber,area,month,timep)
  end

  SaveContracts(data)

  WriteDisk(db,"EOutput/EGBITM",year,EGBITM)
  WriteDisk(db,"EOutput/PPEGTM",year,PPEGTM)

  PurchasesSummation(data)
end

end # module ERetailPurchases
