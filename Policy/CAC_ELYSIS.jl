#
# CAC_ELYSIS.txt
#
# This policy file models the adoption of ELYSIS technology in aluminium facilities across Canada.
#

using EnergyModel

module CAC_ELYSIS

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Last,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CAC_ELYSISData
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

end

# 
# Emission Caps
# The caps are estimated in "CAC_ELYSIS_2024AM_analysis.xlsx" file. 
#

function CapData(data,market,eccs,area,poll)
  (; Area,ECC,Market) = data 
  (; PCovs,Poll,) = data
  (; AreaMarket,CapTrade,ECCMarket,ECoverage) = data
  (; MaxIter,PCovMarket,PollMarket,xGoalPol) = data

  #
  # Read Emissions Cap
  #
  # Zero out early years
  #
  years = collect(1:Yr(2025))
  for year in years
    xGoalPol[market,year] = 0
  end
  # 
  #  Set market switches
  # 
  years = collect(Yr(2025):Yr(2050))
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
  years = collect(Yr(2025):Yr(2050))
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

function CAC_ELYSISDataPolicy(data)
  (; db) = data
  (; Area,ECC,Market,Poll) = data 
  (; AreaMarket,CapTrade,ECCMarket,ECoverage) = data
  (; MaxIter,PCovMarket,PollMarket,xGoalPol) = data

  # 
  # Data for Emissions Caps
  #

  # 
  # Quebec
  # 
  market = 18
  area = Select(Area,"QC")
  eccs = Select(ECC,"Aluminum")
  poll = Select(Poll,"SOX")
  years = collect(Yr(2026):Yr(2050))
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [49836   50070   50266   50608   48811   49000   49169   49325   49457   44335   44496   44646   44763   44907   43023   43182   43295   43437   43571   41322   41391   41474   41557   41647   40715]
  CapData(data,market,eccs,area,poll)

  market = 19
  poll = Select(Poll,"COX")
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [334575  336102  337378  339649  332266  333535  334674  335718  336604  289279  290315  291282  292026  292950  279116  280145  280873  281785  282643  266861  267297  267831  268355  268935  259965]
  CapData(data,market,eccs,area,poll)

  market = 20
  poll = Select(Poll,"PMT")
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [4829    4859    4884    4920    4432    4451    4469    4485    4499    4036    4052    4068    4082    4097    4098    4114    4125    4140    4154    4153    4161    4171    4180    4190    4410]
  CapData(data,market,eccs,area,poll)

  market = 21
  poll = Select(Poll,"PM10")
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [3583    3604    3622    3649    3230    3244    3257    3268    3278    3013    3025    3037    3047    3057    3053    3065    3074    3084    3095    3086    3092    3099    3106    3113    3288]
  CapData(data,market,eccs,area,poll)

  market = 22
  poll = Select(Poll,"PM25")
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [2870    2886    2899    2919    2583    2594    2604    2612    2620    2408    2417    2426    2433    2442    2438    2447    2454    2462    2470    2463    2468    2473    2478    2484    2623]
  CapData(data,market,eccs,area,poll)

  #
  # BC
  #
  market = 23
  area = Select(Area,"BC")
  eccs = Select(ECC,"Aluminum")
  poll = Select(Poll,"SOX")
  years = collect(Yr(2026):Yr(2050))
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [12124   12289   12458   12629   12272   12364   12458   12553   12648   11397   11453   11509   11565   11623   11154   11286   11419   11549   11678   11165   11268   11373   11479   11585   11410]
  CapData(data,market,eccs,area,poll)   

  market = 24
  poll = Select(Poll,"COX")
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [43906   44499   45111   45726   45072   45410   45754   46102   46452   40129   40325   40521   40719   40923   39057   39518   39984   40438   40889   38919   39279   39642   40010   40382   39324]
  CapData(data,market,eccs,area,poll)   

  # 
  # Ontario
  # 
  market = 25
  area = Select(Area,"ON")
  eccs = Select(ECC,"Aluminum")
  poll = Select(Poll,"COX")
  years = collect(Yr(2026):Yr(2050))
  #                         2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050 
  xGoalPol[market,years] = [23      23      24      24      23      23      23      24      24      20      21      21      21      21      20      20      21      21      21      20      20      20      20      20      20]
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
  @info "CAC_ELYSIS.jl - PolicyControl"
  data = CAC_ELYSISData(; db)
  CAC_ELYSISDataPolicy(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
