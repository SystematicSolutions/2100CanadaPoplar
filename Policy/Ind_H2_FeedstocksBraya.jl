#
# Ind_H2_FeedstocksBraya.jl
#

using EnergyModel

module Ind_H2_FeedstocksBraya

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Enduses) = data 
  (; Fuel) = data
  (; Tech) = data
  (; DmFracMin,xDmFrac) = data 
  
  NL = Select(Area,"NL") 
  OtherChemicals = Select(EC,"OtherChemicals")
  Gas = Select(Tech,"Gas") 
  Hydrogen = Select(Fuel,"Hydrogen")
  StillGas = Select(Fuel,"StillGas")
  years = collect(Yr(2024):Yr(2035))

  for year in years, enduse in Enduses
    xDmFrac[enduse,Hydrogen,Gas,OtherChemicals,NL,year] = 0.0755
    DmFracMin[enduse,Hydrogen,Gas,OtherChemicals,NL,year] = 
      xDmFrac[enduse,Hydrogen,Gas,OtherChemicals,NL,year]

    xDmFrac[enduse,StillGas,Gas,OtherChemicals,NL,year] = 0.449
    DmFracMin[enduse,StillGas,Gas,OtherChemicals,NL,year] = 
      xDmFrac[enduse,StillGas,Gas,OtherChemicals,NL,year]
  end

  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
end

function PolicyControl(db)
  @info "Ind_H2_FeedstocksBraya.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
