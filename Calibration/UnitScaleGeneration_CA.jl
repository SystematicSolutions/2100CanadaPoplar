#
# UnitScaleGeneration_CA.jl
#
using EnergyModel

module UnitScaleGeneration_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation (GWh)

  # Scratch Variables
  EGFAAdjusted::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Generation Adjusted (GWh/Yr)
  EGFAAfter::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Generation After Adjustment (GWh/Yr)
  EGFABefore::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Generation Before Adjustment (GWh/Yr)
  EGFACalifornia::VariableArray{2} = zeros(Float32,length(Fuel),length(Year)) # [Fuel,Year] California Generation (GWH/Yr)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Fuel) = data
  (;UnArea,UnPlant,xUnEGA) = data
  (;EGFAAdjusted,EGFAAfter,EGFABefore,EGFACalifornia) = data

  #
  ########################
  #
  # https://ww2.energy.ca.gov/almanac/electricity_data/
  #
  area=Select(Area,"CA")
  years=collect(Yr(1985):Yr(2008))
  fuels=Select(Fuel,["Hydro","Nuclear","Coal","LFO","NaturalGas","Geothermal","Biomass","Wind","Solar"])
  EGFACalifornia[fuels,years] .= [
    #1985     1986     1987     1988     1989     1990     1991     1992     1993     1994     1995     1996     1997     1998     1999     2000     2001     2002     2003     2004     2005     2006     2007     2008
    33898    44478    27140    26692    32742    26092    23244    22373    41595    25626    51665    47883    41400    48757    41627    42053    24988    31359    36321    34490    40263    48559    27106    24460 # Hydroelectric
    18911    28000    32995    35481    33803    36586    37167    38622    36579    38828    36186    39753    37267    41715    40419    43533    33294    34353    35594    30241    36155    32036    35698    32482 # Nuclear
      865     1033     1163     1791     2479     3692     3050     3629     2549     2655     1136     2870     2276     2701     3602     3183     4041     4275     4269     4086     4283     4190     4217     3977 # In-State Coal
     2790     3126     2143     8158     9275     4449      523      107     2085     1954      489      693      143      123       55      449      379       87      103      127      148      134      103       92 # Oil
    69771    49260    75437    74221    78916    76082    75828    87032    70715    95025    78378    66711    74341    82052    84703   106878   116393    92730    94488   105275    97113   109211   120480   123077 # Natural Gas
    10957    13094    14083    14194    15247    16038    15566    16491    15770    15573    14267    13539    11950    12554    13251    13456    13525    13396    13329    13494    13292    13093    13084    12907 # Geothermal
     1171     2063     2461     4092     5204     6644     7312     7362     5760     7173     5969     5557     5701     5266     5663     6086     5762     6197     6094     6082     6080     5865     5766     5911 # Biomass
      655     1221     1713     1824     2139     2418     2669     2707     2867     3293     3182     3154     2739     2776     3433     3604     3242     3546     3316     4258     4084     4902     5570     5724 # Wind
       33       64      188      315      471      681      719      700      857      798      793      832      810      839      838      860      837      850      759      741      660      616      668      733 # Solar
  ]
  #
  # https://www.energy.ca.gov/data-reports/energy-almanac/california-electricity-data/
  # 09/14/23. R.Levesque
  #
  years=collect(Yr(2009):Yr(2022))
  fuels=Select(Fuel,["Hydro","Nuclear","Coal","LFO","NaturalGas","Geothermal","Biomass","Solar","Wind","Waste"])
  EGFACalifornia[fuels,years] .= [

  #   2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022
  # 207181  205350  200986  199100  199783  199193  196195  198227  206336  194842  200475  190912  194127  203257
     29191   34308   42731   27459   24097   16476   13992   28977   43333   26344   38494   21414   14566   17612 #  Hydro
     31509   32214   36666   18491   17860   17027   18525   18931   17925   18268   16163   16280   16477   17627 #  Nuclear
      3735    3406    3120    1580    1018    1011     538     324     302     294     248     317     303     273 # Coal
        67      52      36      90      38      45      54      37      33      35      36      30      37      65 # Oil
    116726  109752   91233  121716  120863  122005  117490   98831   89564   90691   86136   92298   97431   96457 # Natural Gas
     12907   12740   12685   12733   12485   12186   11994   11582   11745   11528   10943   11345   11116   11110 # Geothermal
      5940    5798    5807    6031    6423    6768    6362    5868    5827    5909    5851    5680    5381    5366 # Biomass
       850     908    1097    1834    4291   10585   15046   19783   24331   27265   28513   29456   33260   40494 # Solar
      6249    6172    7598    9152   12694   13074   12180   13500   12867   14078   13680   13708   15173   13938 # Wind
         7       0      13      14      14      16      14     394     409     430     411     384     382     315 # Waste
  ]

  years=collect(Yr(1985):Yr(2022))

  fuels=Select(Fuel,"Hydro")
  units_ca=findall(UnArea[:] .== "CA")
  units_p1=findall(UnPlant[:] .== "PeakHydro")
  units_p2=findall(UnPlant[:] .== "BaseHydro")
  units_p3=findall(UnPlant[:] .== "SmallHydro")
  units=intersect(units_ca,union(units_p1,units_p2,units_p3))
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Hydro ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,"Nuclear")
  units_ca=findall(UnArea[:] .== "CA")
  units_p=findall(UnPlant[:] .== "Nuclear")
  units=intersect(units_ca,units_p)
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Nuclear ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,"Coal")
  units_ca=findall(UnArea[:] .== "CA")
  units_p1=findall(UnPlant[:] .== "Coal")
  units_p2=findall(UnPlant[:] .== "CoalCCS")
  units=intersect(units_ca,union(units_p1,units_p2))
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Coal ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,["LFO","NaturalGas"])
  units_ca=findall(UnArea[:] .== "CA")
  units_p1=findall(UnPlant[:] .== "OGCT")
  units_p2=findall(UnPlant[:] .== "OGCC")
  units_p3=findall(UnPlant[:] .== "OGSteam")
  units=intersect(units_ca,union(units_p1,units_p2,units_p3))
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("LFO and NG ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,"Geothermal")
  units_ca=findall(UnArea[:] .== "CA")
  units_p=findall(UnPlant[:] .== "Geothermal")
  units=intersect(units_ca,units_p)
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Geothermal ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,"Biomass")
  units_ca=findall(UnArea[:] .== "CA")
  units_p1=findall(UnPlant[:] .== "Biomass")
  units_p2=findall(UnPlant[:] .== "Biogas")
  units_p3=findall(UnPlant[:] .== "Waste")
  units=intersect(units_ca,union(units_p1,units_p2,units_p3))
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Biomass ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,"Wind")
  units_ca=findall(UnArea[:] .== "CA")
  units_p1=findall(UnPlant[:] .== "OnshoreWind")
  units_p2=findall(UnPlant[:] .== "OffshoreWind")
  units=intersect(units_ca,union(units_p1,units_p2))
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Wind ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,"Solar")
  units_ca=findall(UnArea[:] .== "CA")
  units_p1=findall(UnPlant[:] .== "SolarPV")
  units_p2=findall(UnPlant[:] .== "SolarThermal")
  units=intersect(units_ca,union(units_p1,units_p2))
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Solar ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  fuels=Select(Fuel,"Waste")
  units_ca=findall(UnArea[:] .== "CA")
  units_p=findall(UnPlant[:] .== "Waste")
  units=intersect(units_ca,units_p)
  for year in years
    EGFABefore[year]=sum(xUnEGA[unit,year] for unit in units)
    EGFAAfter[year]=sum(EGFACalifornia[fuel,year] for fuel in fuels)
    for unit in units
      @finite_math xUnEGA[unit,year]=xUnEGA[unit,year]/EGFABefore[year]*EGFAAfter[year]
    end
    EGFAAdjusted[year]=sum(xUnEGA[unit,year] for unit in units)

    # Select Year(2020)
    # write ("Waste ",YearDS)
    # write ("EGFA Before   = ",EGFABefore:12:3)
    # write ("EGFA After    = ",EGFAAfter:12:3)
    # write ("EGFA Adjusted = ",EGFAAdjusted:12:3)
    # Select year(1985-2022)
  end

  WriteDisk(db,"EGInput/xUnEGA",xUnEGA)

end

function CalibrationControl(db)
  @info "UnitScaleGeneration_CA.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
