#
# CFS_LiquidEVCredit.jl
#

using EnergyModel

module CFS_LiquidEVCredit

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  # CalDB::String = "SCalDB"
  # Input::String = "SInput"
  # Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation 
  xFPCFSCredit::VariableArray{4} = ReadDisk(db,"SInput/xFPCFSCredit") # [Fuel,ES,Area,Year] CFS Credit Price ($/Tonnes)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  CreditPrice::VariableArray{1} = zeros(Float32,length(Year)) # [Year] CFS Credit Price ($/Tonnes)
end

function SupplyPolicy(db)
  data = SControl(; db)
  (; Areas,ES,Fuel) = data 
  (; xFPCFSCredit) = data

  Transport = Select(ES,"Transport")
  Electric = Select(Fuel,"Electric")
  Gasoline = Select(Fuel,"Gasoline")
  years = collect(Yr(2023):Final)
  for year in years, area in Areas
    xFPCFSCredit[Electric,Transport,area,year] = 
      xFPCFSCredit[Gasoline,Transport,area,year]
  end

  WriteDisk(db,"SInput/xFPCFSCredit",xFPCFSCredit)    
end

function PolicyControl(db)
  @info "CFS_LiquidEVCredit.jl - PolicyControl"
  SupplyPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
