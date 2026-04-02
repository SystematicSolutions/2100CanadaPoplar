#
# CAC_ON_IronSteel.jl
#
# This TXP Models SO2 emission reductions to the Iron&Steel sector in Ontario
# These reductions are associated with the Algoma and Arcelor projects
# Where conversion to DRI-EAF will lead to significant reductions from these 2 plants
#

using EnergyModel

module CAC_ON_IronSteel

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CAC_ON_IronSteelData
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
  years = collect(Yr(2021):Yr(2050))
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
  
  years = collect(Yr(2022):Yr(2050))
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


function CAC_ON_IronSteelDataPolicy(db)
  data = CAC_ON_IronSteelData(; db)
  (; AreaMarket,CapTrade,ECCMarket,ECoverage,MaxIter) = data
  (; PCovMarket,PollMarket,xGoalPol) = data

  # 
  # Data for Emissions Caps
  # 

  # 
  # Ontario
  # 
  #             Market   ECC                Area   Poll                      2022      2023      2024      2025     2026     2027     2028     2029     2030     2031     2032     2033     2034     2035     2036     2037     2038     2039     2040     2041     2042     2043     2044     2045     2046     2047     2048     2049     2050
  CapData(data, 153,     "IronSteel",      "ON",  "SOX")
  xGoalPol[     153,                                       Yr(2022):Yr(2050)] = [12238,    11031,    10426,    9934,    9026,    7993,    7132,    6278,    6290,    6194,    6033,    5863,    5741,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587,    5587]
  
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
  @info "CAC_ON_IronSteel.jl - PolicyControl"
  CAC_ON_IronSteelDataPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
