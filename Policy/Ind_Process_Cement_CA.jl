#
# Ind_Process_Cement_CA.jl - Stone, Clay, Glass, Cement:  CCS on 40%
# of operations 2035 and on all facilities by 2045 Some process
# emissions reduced through alternative materials
#

using EnergyModel

module Ind_Process_Cement_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Process Pollution Coefficient (Tonnes/$B-Output)
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC) = data
  (; Poll) = data
  (; MEPOCX) = data

  #
  # California
  #  
  CA = Select(Area,"CA")
  eccs = Select(ECC,["Cement","Glass","LimeGypsum","OtherNonMetallic"])
  ghg = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])

  years = collect(Yr(2040):Final)
  for year in years, area in CA, ecc in eccs, poll in ghg
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year]*(1-0.40)
  end

  #
  # Interpolate from 2021
  #  
  years = collect(Yr(2024):Yr(2039))
  for year in years, area in CA, ecc in eccs, poll in ghg
    MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year-1]+
      (MEPOCX[ecc,poll,area,Yr(2040)]-MEPOCX[ecc,poll,area,Yr(2021)])/(2040-2021)
  end

  WriteDisk(db,"MEInput/MEPOCX",MEPOCX);
end

function PolicyControl(db)
  @info "Ind_Process_Cement_CA.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
