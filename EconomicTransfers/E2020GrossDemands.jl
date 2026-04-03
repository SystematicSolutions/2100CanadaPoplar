#
# E2020GrossDemands.jl
#

using EnergyModel

module E2020GrossDemands

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EuDemand::VariableArray{4} = ReadDisk(db,"SOutput/EuDemand") # [Fuel,ECC,Area,Year]  Enduse Energy Demands (TBtu/Yr)
  GrossDemands::VariableArray{4} = ReadDisk(db,"KOutput/GrossDemands") # [Fuel,ECC,Area,Year]  Gross Energy Demands (TBtu/Yr)
  TotDemand::VariableArray{4} = ReadDisk(db,"SOutput/TotDemand") # [Fuel,ECC,Area,Year]  Energy Demands (TBtu/Yr)

  #
  # Scratch Variables
  #

end

function CalculateGrossDemand(db)
  data = MControl(; db)
  (; Area,Areas,Fuels,ECCs,Years) = data
  (; EuDemand,GrossDemands) = data

  areas = Select(Area,(from="ON",to="Pac"))

  for year in Years, area in areas, ecc in ECCs, fuel in Fuels
      GrossDemands[fuel,ecc,area,year] = EuDemand[fuel,ecc,area,year]
  end

  #
  # Assign 1985 a value
  #
  for area in areas, ecc in ECCs, fuel in Fuels
    GrossDemands[fuel,ecc,area,Yr(1985)] = GrossDemands[fuel,ecc,area,Yr(1986)]
  end

  #
  # Zero out very small values of energy demand 6/18/25 R.Levesque
  #
  for year in Years, area in Areas, ecc in ECCs, fuel in Fuels
    if GrossDemands[fuel,ecc,area,year] < 1e-8
      GrossDemands[fuel,ecc,area,year] = 0.0f0
    end 
  end

  WriteDisk(db,"KOutput/GrossDemands",GrossDemands)
end

#
########################
#
function Control(db)
  @info "E2020GrossDemands.jl - Control"
  CalculateGrossDemand(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end

