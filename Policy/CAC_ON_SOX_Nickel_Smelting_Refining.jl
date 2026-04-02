#
# CAC_ON_SOX_Nickel_Smelting_Refining.jl
#
# This TXP models Ontario's SO2 emissions reduction policy for for Sudbury's nickel smelting and refining facilities. 
# Prepared by Howard (Taeyeong) Park on 09/09/2024.
#

using EnergyModel

module CAC_ON_SOX_Nickel_Smelting_Refining

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Last
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CAC_ON_SOX_Nickel_Smelting_RefiningData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PCov::SetArray = ReadDisk(db,"MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db,"MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade,Cap Only=2)
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECoverage::VariableArray{5} = ReadDisk(db,"SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Policy Coverage Switch (1=Covered)
  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # Maximum Number of Iterations (Number)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  RPolicy::VariableArray{4} = ReadDisk(db,"SOutput/RPolicy") # [ECC,Poll,Area,Year] Provincial Reduction (Tonnes/Tonnes)
  xGoalPol::VariableArray{2} = ReadDisk(db,"SInput/xGoalPol") # [Market,Year] Pollution Goal (Tonnes/Yr)
end

function CapData(data,market,ecckey,areakey,pollkey)
  (; Area,ECC,Market) = data 
  (; PCovs,Poll) = data
  (; AreaMarket,CapTrade,ECCMarket,ECoverage,MaxIter) = data
  (; PCovMarket,PollMarket) = data

  eccs = Select(ECC,ecckey)
  areas = Select(Area,areakey)
  poll = Select(Poll,pollkey)

  # 
  #  Set market switches
  #  
  years = collect(Last:Yr(2050))
  for year in years, area in areas
    AreaMarket[area,market,year] = 1
  end
  
  for year in years, ecc in eccs
    ECCMarket[ecc,market,year] = 1
  end
  
  for year in years, pcov in PCovs
    PCovMarket[pcov,market,year] = 1
  end
  
  for year in years
    PollMarket[poll,market,year] = 1
  end
  
  for year in years, area in areas, pcov in PCovs, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1
  end
  
  for year in years
    CapTrade[market,year] = 0
  end
  
  years = collect(Yr(2026):Yr(2050))
  for year in years
    CapTrade[market,year] = 2
  end

  #
  # Maximum Number of Iterations
  #
  for year in years
    MaxIter[year] = max(MaxIter[year],1)
  end

end

function CAC_ON_SOX_Nickel_Smelting_RefiningDataPolicy(db)
  data = CAC_ON_SOX_Nickel_Smelting_RefiningData(; db)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Market,Markets,Nation) = data 
  (; NationDS,Nations,PCov,PCovDS,PCovs,Poll,PollDS,Polls) = data
  (; Year,YearDS,Years) = data
  (; ANMap,AreaMarket,CapTrade,ECCMarket,ECoverage,MaxIter) = data
  (; PCovMarket,PollMarket,RPolicy,xGoalPol) = data

  # 
  # Data for Emissions Caps
  # 

  # 
  # Ontario
  # 
  #             Market   ECC                Area   Poll
  CapData(data, 104,    "OtherNonferrous", "ON",  "SOX")
  #      2026   2027   2028   2029   2030   2031   2032   2033   2034   2035   2036   2037   2038   2039   2040   2041   2042   2043   2044   2045   2046   2047   2048   2049   2050 
  tmp = [32613, 33350, 34121, 35075, 35968, 36619, 37208, 37685, 38006, 38396, 38778, 39211, 39680, 40157, 40677, 41206, 41691, 42264, 42810, 43348, 43876, 44405, 44952, 45489, 46036]
  #     Market Year
  xGoalPol[104,Yr(2026):Yr(2050)] = tmp
  
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)
  WriteDisk(db,"SInput/CapTrade",CapTrade)
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)
  WriteDisk(db,"SInput/ECoverage",ECoverage)
  WriteDisk(db,"SInput/MaxIter",MaxIter)  
  WriteDisk(db,"SInput/PCovMarket",PCovMarket)
  WriteDisk(db,"SInput/PollMarket",PollMarket)
  WriteDisk(db,"SInput/xGoalPol",xGoalPol)
  
end

function PolicyControl(db)
  @info "CAC_ON_SOX_Nickel_Smelting_Refining.jl - PolicyControl"
  CAC_ON_SOX_Nickel_Smelting_RefiningDataPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
