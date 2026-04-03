#
# SpThermal.jl - Thermal Supply Sector
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# © 2016 Systematic Solutions, Inc.  All rights reserved.
#
module SpThermal

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
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))

  ThermalDemand::VariableArray{1} = ReadDisk(db,"SOutput/ThermalDemand",year) #[Area,Year] Thermal Demands (TBtu/Yr)
  ThermalLimit::VariableArray{1} = ReadDisk(db,"SOutput/ThermalLimit",year) #[Area,Year] Thermal Limit Multiplier (Btu/Btu)
  ThermalLimitPrior::VariableArray{1} = ReadDisk(db,"SOutput/ThermalLimit",prior) #[Area,Year] Thermal Limit Multiplier (Btu/Btu)
  ThermalParameter::VariableArray{1} = ReadDisk(db,"SInput/LimitParameter",year) #[Area,Year] Thermal Limit Parameter (Btu/Btu)
  ThermalRatio::VariableArray{1} = ReadDisk(db,"SOutput/ThermalRatio",year) #[Area,Year] Thermal Supply (TBtu/Yr)
  ThermalSupply::VariableArray{1} = ReadDisk(db,"SOutput/ThermalSupply",year) #[Area,Year] Thermal Supply (TBtu/Yr)
  TotDemandPrior::VariableArray{3} = ReadDisk(db,"SOutput/TotDemand",prior) #[Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  ThermalAvailablePrior::VariableArray{1} = ReadDisk(db,"SOutput/ThermalAvailable",prior) #[Area,Year] Generation Available for Thermal Batteries (GWh/Yr)
end

function ThermalSupplyLimit(data::Data)
  (; db,year) = data
  (; Areas,ECCs,Fuel) = data
  (; ThermalDemand,ThermalLimit,ThermalLimitPrior,ThermalParameter) = data
  (; ThermalRatio,ThermalSupply,TotDemandPrior,ThermalAvailablePrior) = data

  thermal = Select(Fuel,"Thermal")

  for area in Areas
    ThermalDemand[area] = sum(TotDemandPrior[thermal,ecc,area] for ecc in ECCs)/ThermalLimitPrior[area]
    ThermalSupply[area] = min(ThermalAvailablePrior[area]*3412/1e6, ThermalDemand[area])
    ThermalRatio[area] = ThermalSupply[area]/max(ThermalDemand[area],0.0001)
    
    if ThermalRatio[area] > (1.0+ThermalParameter[area])
      ThermalLimit[area] = 1.0
    elseif ThermalRatio[area] < (1.0-ThermalParameter[area])
      ThermalLimit[area] = ThermalRatio[area]
    else
      ThermalLimit[area] = (1.0-ThermalParameter[area])
    end
  end

  WriteDisk(db,"SOutput/ThermalLimit",year,ThermalLimit)
  WriteDisk(db,"SOutput/ThermalDemand",year,ThermalDemand)
  WriteDisk(db,"SOutput/ThermalRatio",year,ThermalRatio)
  WriteDisk(db,"SOutput/ThermalSupply",year,ThermalSupply)
end

function Control(data::Data)
  ThermalSupplyLimit(data)
end

end # module SpThermal
