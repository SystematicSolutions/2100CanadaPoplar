#
# CAC_CCME_AcidRain_A.jl
#
# This file models Province-Wide Cap as part of the CCME Acid Rain Strategy.
# Prepared by Audrey Bernard 07/07/2021.
#

using EnergyModel

module CAC_CCME_AcidRain_A

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CAC_CCME_AcidRainAData
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
  MaxIter::VariableArray{1} = ReadDisk(db,"SInput/MaxIter") # [Year] Maximum Number of Iterations (Number)
  PCovMarket::VariableArray{3} = ReadDisk(db,"SInput/PCovMarket") # [PCov,Market,Year] Types of Pollution included in Market
  PollMarket::VariableArray{3} = ReadDisk(db,"SInput/PollMarket") # [Poll,Market,Year] Pollutants included in Market
  RPolicy::VariableArray{4} = ReadDisk(db,"SOutput/RPolicy") # [ECC,Poll,Area,Year] Provincial Reduction (Tonnes/Tonnes)
  xGoalPol::VariableArray{2} = ReadDisk(db,"SInput/xGoalPol") # [Market,Year] Pollution Goal (Tonnes/Yr)

  # Scratch
  tmp::VariableArray{1} = zeros(Float32,length(Years)) # Create temporary variable with dim years
end

# 
# Emission Caps
# The caps are Emission Cap.xls from Jack Buchanan of Environment Canada.
#

function CapData(data,market,eccs,area,poll)
  (; Area,ECC,Market) = data 
  (; PCovs,Poll,) = data
  (; AreaMarket,CapTrade,ECCMarket,ECoverage) = data
  (; MaxIter,PCovMarket,PollMarket,xGoalPol) = data

  #
  # Zero out early years
  #
  years = collect(1:Last)
  for year in years
    xGoalPol[market,year] = 0
  end
  
  # 
  #  Set market switches
  # 
  years = collect(Last:Yr(2050))
  for year in years
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
  for year in years, pcov in PCovs, ecc in eccs
    ECoverage[ecc,poll,pcov,area,year] = 1
  end
  
  years = collect(Last:Yr(2050))
  for year in years
    CapTrade[market,year] = 0
  end
  years = collect(Future:Yr(2050))
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

function CAC_CCME_AcidRainADataPolicy(data)
  (; db) = data
  (; Area,ECC,Market,Poll) = data 
  (; AreaMarket,CapTrade,ECCMarket,ECoverage) = data
  (; MaxIter,PCovMarket,PollMarket,xGoalPol,tmp) = data

  # 
  # Data for Emissions Caps
  # CCME Acid Rain target for ON is 442.5 kt - see ON Acid Rain 
  # Provincial Cap.xlxs for recalculation (updated by Stephanie August 20, 2012)
  #

  # 
  # Ontario
  # 
  market = 9
  area = Select(Area,"ON")
  eccs1 = Select(ECC,!=("OtherNonferrous"))
  eccs2 = Select(ECC,!=("OtherChemicals"))
  eccs = intersect(eccs1,eccs2)
  poll = Select(Poll,"SOX")
  years = collect(Future:Yr(2050))
  for year in years
    xGoalPol[market,year] = 342500
  end
  CapData(data,market,eccs,area,poll)

  # 
  # Quebec
  # 
  market = 49
  area = Select(Area,"QC")
  eccs1 = Select(ECC,!=("OtherNonferrous"))
  eccs2 = Select(ECC,!=("Aluminum"))
  eccs = intersect(eccs1,eccs2)
  poll = Select(Poll,"SOX")
  years = collect(Future:Yr(2050))
  for year in years
    xGoalPol[market,year] = 227648
  end
  CapData(data,market,eccs,area,poll)
  
  # 
  # New Brunswick
  # 
  market = 70
  area = Select(Area,"NB")
  eccs = Select(ECC,!=("OtherNonferrous"))
  poll = Select(Poll,"SOX")
  years = collect(Future:Yr(2050))  
  for year in years
    xGoalPol[market,year] = 79627
  end
  CapData(data,market,eccs,area,poll)
  
  # 
  # Nova Scotia
  # 
  market = 17
  area = Select(Area,"NS")
  eccs = Select(ECC,!=("UtilityGen"))
  poll = Select(Poll,"SOX")
  years = collect(Future:Yr(2050)) 
  for year in years
    xGoalPol[market,year] = 34750
  end
  CapData(data,market,eccs,area,poll)
  
  # 
  # Newfoundland
  # 
  market = 32
  area = Select(Area,"NL")
  eccs = Select(ECC,!=("IronOreMining"))
  poll = Select(Poll,"SOX")
  years = collect(Future:Yr(2050))   
  for year in years
    xGoalPol[market,year] = 55561
  end
  CapData(data,market,eccs,area,poll)   
   
  WriteDisk(db,"SInput/AreaMarket",AreaMarket)
  WriteDisk(db,"SInput/ECCMarket",ECCMarket)
  WriteDisk(db,"SInput/ECoverage",ECoverage)
  WriteDisk(db,"SInput/CapTrade",CapTrade)
  WriteDisk(db,"SInput/MaxIter",MaxIter)  
  WriteDisk(db,"SInput/PCovMarket",PCovMarket)
  WriteDisk(db,"SInput/PollMarket",PollMarket)
  WriteDisk(db,"SInput/xGoalPol",xGoalPol)
 
end

function PolicyControl(db)
  @info "CAC_CCME_AcidRain_A.jl - PolicyControl"
  data = CAC_CCME_AcidRainAData(; db)
  CAC_CCME_AcidRainADataPolicy(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
