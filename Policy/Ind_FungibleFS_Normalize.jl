#
# Ind_FungibleFS_Normalize.jl - Fungible Demands Market Share Calibration 
#

using EnergyModel

module Ind_FungibleFS_Normalize

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log,HasValues
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
  xFsFracTotal::VariableArray{4} = zeros(Float32,length(Tech),length(EC),length(Area),length(Year)) # [Tech,EC,Area] Total of Feedstock Fuel/Tech Fractions (Btu/Btu)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Techs,ECs,Areas,Fuels) = data
  (; xFsFrac,xFsFracTotal) = data
  
  years = collect(Future:Final)
  for year in years, area in Areas, ec in ECs, tech in Techs
    xFsFracTotal[tech,ec,area,year] = sum(xFsFrac[fuel,tech,ec,area,year] for fuel in Fuels)
    for fuel in Fuels
      xFsFrac[fuel,tech,ec,area,year] = @finite_math xFsFrac[fuel,tech,ec,area,year]/
                                               xFsFracTotal[tech,ec,area,year]
    end
  end

  WriteDisk(db,"$Input/xFsFrac",xFsFrac)

end

function PolicyControl(db)
  @info "Ind_FungibleFS_Normalize.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
