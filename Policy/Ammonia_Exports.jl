#
# Ammonia_Exports.jl - Process Retrofit
# This policy file models ammonia exports from Canada
#

using EnergyModel

module Ammonia_Exports

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  H2Tech::SetArray = ReadDisk(db,"MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db,"MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xNH3Exports::VariableArray{2} = ReadDisk(db,"SpInput/xNH3Exports") # [Area,Year] Variable for ammonia exports
  NH3MSM0::VariableArray{3} = ReadDisk(db,"SpInput/NH3MSM0") # [H2Tech,Area,Year] Variable for ammonia non price factor
end

function AmmoniaPolicy(db)
  data = SControl(; db)
  (; H2Tech,Area,Year) = data
  (; H2Techs,Areas,Years) = data
  (; xNH3Exports,NH3MSM0) = data

  NS = Select(Area,"NS")
  xNH3Exports[NS,Yr(2026)] = 5.12
  xNH3Exports[NS,Yr(2027)] = 5.12
  years = collect(Yr(2028):Yr(2050))
  for year in years
    xNH3Exports[NS,year] = 21.32
  end
  
  Grid = Select(H2Tech,"Grid")
  years = collect(Yr(2026):Yr(2050))
  for year in years 
    NH3MSM0[Grid,NS,year] = 0
  end

  ATRNGCCS = Select(H2Tech,"ATRNGCCS")
  years = collect(Yr(2026):Yr(2050))
  for year in years 
    NH3MSM0[ATRNGCCS,NS,year] = -170
  end

  NGCCS = Select(H2Tech,"NGCCS")
  years = collect(Yr(2026):Yr(2050))
  for year in years 
    NH3MSM0[NGCCS,NS,year] = -170
  end
  
  WriteDisk(db,"SpInput/xNH3Exports",xNH3Exports)
  WriteDisk(db,"SpInput/NH3MSM0",NH3MSM0)

end

function PolicyControl(db)
  @info "Ammonia_Exports.jl - PolicyControl"
  AmmoniaPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
