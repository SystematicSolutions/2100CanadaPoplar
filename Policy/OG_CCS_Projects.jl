#
# OG_CCS_Projects.jl - GHG Carbon Sequestration - Thuo Kossa 10/23/2024
#

using EnergyModel

module OG_CCS_Projects

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
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xSqPol::VariableArray{4} = ReadDisk(db,"MEInput/xSqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)

end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC,Poll) = data
  (; xSqPol) = data

  CO2 = Select(Poll,"CO2")

  #
  # Gross Sequestering
  #

  #
  # Exogenous CCS reductions from Polaris project; 750 kt for total project
  # but only 1/2 for petroleum products and 1/2 for petrochem
  #
  area = Select(Area,"AB")     
  ecc = Select(ECC,"Petroleum")
  years = collect(Yr(2028):Final) 
  for year in years
   xSqPol[ecc,CO2,area,year] = xSqPol[ecc,CO2,area,year]-0.325*1e6
  end 

  #
  # 0.4 MT in Emissions sequestering from Glacier GasProcessing in Alberta.
  # This project has reached FID
  #
  area = Select(Area,"AB")     
  ecc = Select(ECC,"SourGasProcessing")
  years = collect(Yr(2026):Final) 
  for year in years
   xSqPol[ecc,CO2,area,year] = xSqPol[ecc,CO2,area,year]-0.160*1e6
  end  

  #
  # Exogenous CCS reductions from FedCoop CCS plant; 400 kt in Refinery
  #
  area = Select(Area,"SK")     
  ecc = Select(ECC,"Petroleum")
  years = collect(Yr(2028):Final) 
  for year in years
   xSqPol[ecc,CO2,area,year] = xSqPol[ecc,CO2,area,year]-0.400*1e6
  end  

  #
  # Exogenous CCS reductions from Strathcona project; 2 Mt starting in 2028, 
  # 1/2 for AB SAGD and 1/2 for SK Heavy Oil Mining
  # The project description mentions reductions in SK's SAGD operations.
  # But we don't have this sector in E2020.
  #
  area = Select(Area,"AB")     
  ecc = Select(ECC,"SAGDOilSands")
  years = collect(Yr(2028):Final) 
  for year in years
   xSqPol[ecc,CO2,area,year] = xSqPol[ecc,CO2,area,year]-1.00*1e6
  end  
  area = Select(Area,"SK")     
  ecc = Select(ECC,"HeavyOilMining")
  years = collect(Yr(2028):Final) 
  for year in years
   xSqPol[ecc,CO2,area,year] = xSqPol[ecc,CO2,area,year]-1.00*1e6
  end  
  
  WriteDisk(db,"MEInput/xSqPol",xSqPol)
end

function PolicyControl(db)
  @info "OG_CCS_Projects.jl - PolicyControl"
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
