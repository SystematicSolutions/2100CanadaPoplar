#
# RefiningDeliveryCharge.jl - Data Values for Refining Sector
#
using EnergyModel

module RefiningDeliveryCharge

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Crude::SetArray = ReadDisk(db,"MainDB/CrudeKey")
  CrudeDS::SetArray = ReadDisk(db,"MainDB/CrudeDS")
  Crudes::Vector{Int} = collect(Select(Crude))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  RfFPCrudeDChg::VariableArray{3} = ReadDisk(db,"SpInput/RfFPCrudeDChg") # [RfUnit,Crude,Year] Crude Oil Delivery Charge (1985 US$/mmBtu)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Wholesale Energy Prices (1985 US$/mmBtu)

  #
  # Scratch Variables
  #
  DChgFraction::VariableArray{1} = zeros(Float32,length(Crude)) # [Crude] Delivery Charge as Fraction of World Oil Price ($/$)
end

function DeliveryCharge(db)
  data = SControl(; db)
  (;Crude,Crudes,Fuel,Fuels,Nation,Nations,RfUnit,RfUnits,Year,Years) = data
  (;DChgFraction,RfFPCrudeDChg,xENPN) = data

  for crude in Crudes
    if Crude[crude]      == "LightForeign"
      DChgFraction[crude] =  0.10
    elseif Crude[crude]  == "LightDomestic"
      DChgFraction[crude] =  0.00                  
    elseif Crude[crude]  == "HeavyForeign"     
      DChgFraction[crude] = -0.05                  
    elseif Crude[crude]  == "HeavyDomestic"
      DChgFraction[crude] = -0.10                 
    elseif Crude[crude]  == "SCO"       
      DChgFraction[crude] =  0.00                  
    elseif Crude[crude]  == "Bitumen" 
      DChgFraction[crude] = -0.10                  
    elseif Crude[crude]  == "Condensates"
      DChgFraction[crude] =  0.00   
    elseif Crude[crude]  == "Other"
      DChgFraction[crude] =  0.00
    elseif Crude[crude]  == "Unknown1"
      DChgFraction[crude] =  0.00         
    elseif Crude[crude]  == "Unknown2"
      DChgFraction[crude] =  0.00   
    end
  end
  
  LightCrudeOil = Select(Fuel,"LightCrudeOil")
  US = Select(Nation,"US")
  for year in Years, crude in Crudes, rfunit in RfUnits
    RfFPCrudeDChg[rfunit,crude,year]=xENPN[LightCrudeOil,US,year]*DChgFraction[crude]
  end 

  WriteDisk(db,"SpInput/RfFPCrudeDChg",RfFPCrudeDChg)  
  
end

function Control(db)
  @info "RefiningDeliveryCharge.jl - Control"
  DeliveryCharge(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
