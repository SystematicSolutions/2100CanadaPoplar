#
# SpCoal.jl
#

module SpCoal

import ...EnergyModel: ReadDisk,WriteDisk, Select, ITime,MaxTime,HisTime
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  last = HisTime-ITime+1

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area)) 
  
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  CNAreas::Vector{Int} = collect(Select(CNArea)) 
  
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
    
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation)) 
    
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap")            # [Area,Nation] # Map between Area and Nation
  CADemand::VariableArray{1} = ReadDisk(db,"SpOutput/CADemand",year) # [Area]# Coal Demand (TBtu/Yr)
  CADemandLast::VariableArray{1} = ReadDisk(db,"SpOutput/CADemand",last) # [Area]# Coal Demand (TBtu/Yr)
  CAProd::VariableArray{1} = ReadDisk(db,"SOutput/CAProd",year) # [Area] # Primary Coal Production (TBtu/Yr)
  CDemand::VariableArray{1} = ReadDisk(db,"SpOutput/CDemand",year) # [Nation] # Coal Demand (TBtu/Yr)
  # CEmiss::VariableArray{1} = ReadDisk(db,"SpOutput/CEmiss",year) #[Nation,Year]  Coal Emissions per Unit of Output (Tonnes/Tonnes)
  CNAMap::VariableArray{2} = ReadDisk(db,"MInput/CNAMap") #[Area,CNArea]  Map between Area and Canada Economic Areas (CNArea)
  CPrTax::VariableArray{1} = ReadDisk(db,"SpOutput/CPrTax",next) # [Nation]   # Coal Production Tax ($/mmBtu)
  CProd::VariableArray{1} = ReadDisk(db,"SpOutput/CProd",year) # [Nation]  # Primary Coal Production (TBtu/Yr)
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",next) # [Fuel,Nation]  # Wholesale Price (Real $/mmBtu)
  Exports::VariableArray{2} = ReadDisk(db,"SpOutput/Exports",year) # [FuelEP,Nation]      # Primary Exports (TBtu/Yr)
  ExportsMin::VariableArray{2} = ReadDisk(db,"SpInput/ExportsMin",year) #[FuelEP,Nation,Year]  Exports Minimum (TBtu/Yr)
  GOMult::VariableArray{2} = ReadDisk(db,"SOutput/GOMult",year) #[ECC,Area,Year]  Gross Output Multiplier ($/$)
  Imports::VariableArray{2} = ReadDisk(db,"SpOutput/Imports",year) # [FuelEP,Nation]       # Primary Imports (TBtu/Yr)
  ImportsMin::VariableArray{2} = ReadDisk(db,"SpInput/ImportsMin",year) #[FuelEP,Nation,Year]  Imports Minimum (TBtu/Yr)
  InflationNation::VariableArray{1} = ReadDisk(db,"MOutput/InflationNation",year) # [Nation]  # Inflation Index ($/$)
  KJBtu = 1.054615
  SupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpOutput/SupplyAdjustments",year) # [FuelEP,Nation]  # Oil and Gas Supply Adjustments (TBtu/Yr)
  TotDemand::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",year) # [Fuel,ECC,Area] # Energy Demands (TBtu/Yr)
  xCAProd::VariableArray{1} = ReadDisk(db,"SpInput/xCAProd",year)   # [Area]  # Coal Production - Reference Case (TBtu/Yr)
  xENPN::VariableArray{2} = ReadDisk(db,"SInput/xENPN",next)      # [Fuel,Nation] # Primary Energy Price (Real $/mmBtu)
  xExports::VariableArray{2} = ReadDisk(db,"SpInput/xExports",year)  # [FuelEP,Nation]  # Primary Exports (TBtu/Yr)
  xImports::VariableArray{2} = ReadDisk(db,"SpInput/xImports",year)  # [FuelEP,Nation] # Primary Imports (TBtu/Yr)
  xSupplyAdjustments::VariableArray{2} = ReadDisk(db,"SpInput/xSupplyAdjustments",year) # [FuelEP,Nation]   # Oil and Gas Supply Adjustments (TBtu/Yr)
end

function CoalSupply(data::Data)
  (; db,year,CTime) = data
  (; Areas,ECCs,Fuel,FuelEP,Nations) = data
  (; ANMap,CADemand,CADemandLast,CAProd,CDemand,CProd) = data
  (; Exports,ExportsMin,Imports,ImportsMin,SupplyAdjustments) = data
  (; TotDemand,xCAProd,xExports,xImports,xSupplyAdjustments) = data

  # @info "  SpCoal.jl - CoalSupply"

  #
  # Coal Demands
  #
  fuel = Select(Fuel,"Coal")
  for area in Areas
    CADemand[area] = sum(TotDemand[fuel,ecc,area] for ecc in ECCs)
  end
  for nation in Nations
    CDemand[nation] = sum(CADemand[area]*ANMap[area,nation] for area in Areas)
  end
  WriteDisk(db,"SpOutput/CADemand",year,CADemand)
  WriteDisk(db,"SpOutput/CDemand",year,CDemand)

  #
  # Coal Production
  #
  CAProd .= xCAProd
  if CTime > HisTime
    @. CAProd = max(CAProd-max(CADemandLast-CADemand,0),0)
  end
  for nation in Nations
    CProd[nation] = sum(CAProd[area]*ANMap[area,nation] for area in Areas)
  end
  WriteDisk(db,"SOutput/CAProd",year,CAProd)
  WriteDisk(db,"SpOutput/CProd",year,CProd)

  #
  # Coal Supply Adjustments
  #
  fuelep = Select(FuelEP,"Coal")
  if CTime <= HisTime
    for nation in Nations
      SupplyAdjustments[fuelep,nation] = CDemand[nation]+xExports[fuelep,nation]-
                                         CProd[nation]-xImports[fuelep,nation]
    end
  else
    for nation in Nations
      SupplyAdjustments[fuelep,nation] = xSupplyAdjustments[fuelep,nation]
    end
  end
  WriteDisk(db,"SpOutput/SupplyAdjustments",year,SupplyAdjustments)

  #
  # Coal Imports
  #
  for nation in Nations
    Imports[fuelep,nation] = ImportsMin[fuelep,nation]+max(CDemand[nation]-
        CProd[nation]-ImportsMin[fuelep,nation]+ExportsMin[fuel,nation]-
        SupplyAdjustments[fuelep,nation],0)
  end
  WriteDisk(db,"SpOutput/Imports",year,Imports)

  #
  # Coal Exports
  #
  for nation in Nations
    Exports[fuelep,nation] = ExportsMin[fuelep,nation]+
        max(CProd[nation]-CDemand[nation]+Imports[fuelep,nation]-
            ExportsMin[fuelep,nation]+SupplyAdjustments[fuelep,nation],0)
  end
  WriteDisk(db,"SpOutput/Exports",year,Exports)

end

#
function CoalPrice(data::Data)
  (; db,next) = data
  (; Fuel,Nation,Nations) = data
  (; CPrTax,ENPN,InflationNation,xENPN) = data

  # @info "  SpCoal.jl - CoalPrice"

  #
  #  Coal Production Tax
  #
  @. CPrTax = 0

  #
  # National Wholesale Coal Prices
  #
  fuel = Select(Fuel,"Coal")
  for nation in Nations
    @finite_math ENPN[fuel,nation] = xENPN[fuel,nation]+CPrTax[nation]/InflationNation[nation]
  end

  #
  # Adjust Coal Related Prices
  #
  fuels = Select(Fuel,["Coke","CokeOvenGas"])
  for nation in Nations, fuel in fuels
    @finite_math ENPN[fuel,nation] = xENPN[fuel,nation]*ENPN[Select(Fuel,"Coal"),nation]/
                                                       xENPN[Select(Fuel,"Coal"),nation]
  end


  WriteDisk(db,"SpOutput/CPrTax",next,CPrTax)
  WriteDisk(db,"SOutput/ENPN",next,ENPN)
end

function Control(data::Data)
  # @info "  SpCoal.jl - Control"

  CoalSupply(data)
end

end # module SpCoal
