#
# MarketableGas.jl
#
using EnergyModel

module MarketableGas

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GasProductionMap::VariableArray{1} = ReadDisk(db,"SpInput/GasProductionMap") # [Process] Gas Production Map (1=include)
  GMMult::VariableArray{2} = ReadDisk(db,"SInput/GMMult") # [Nation,Year] Marketable Gas Production Multiplier (TBtu/TBtu)
  xGProd::VariableArray{3} = ReadDisk(db,"SInput/xGProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)

  # Scratch Variables
  # GasConv  'Natural Gas Conversion (1000 Btu per Cubit Foot)'
  xGMarket::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Marketable Gas Production (TBtu/Yr)
end

function SupplyCalibration(db)
  data = SControl(; db)
  (;Input) = data
  (;Areas,ECCs,Fuel,Nation) = data
  (;Processs,Years) = data
  (;ANMap,GasProductionMap,GMMult,xGMarket,xGProd,xTotDemand) = data
  (;GMMult) = data

  GasConv=1.028

  #
  # Marketable Gas from NEB 2017 Forecast
  # https://www.neb-one.gc.ca/nrg/ntgrtd/ftr/2016updt/index-eng.html
  # C:\2020 Documents\Oil and Gas Production\ECCC Development\NEB\2017 Forecast\2017ntrlgsrprt-eng.xlsx
  #

  CN = Select(Nation,"CN")
  years = collect(Yr(2000):Yr(2040))

  xGMarket[CN,years] = [
  # 2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040
  16.7142 17.4683 17.3195 16.7223 17.0105 17.0203 17.1059 16.8935 16.1578 15.1053 14.5900 14.5814 13.9118 14.0455 14.6734 14.9736 15.2268 15.3249 15.1513 14.9830 14.8547 14.7438 14.7124 14.7121 14.7416 14.7924 14.8549 14.9284 15.0118 15.1232 15.2573 15.3919 15.5336 15.7003 15.8849 16.0691 16.2489 16.4243 16.5984 16.7702 16.9386
  ]

  #
  # NEB 2018 Forecast Natural Gas Production
  #
  # Canadian natural gas is produced for use domestically, as well as exported to the U.S.
  # Canadian marketable natural gas production averaged
  # 15.6 billion cubic feet per day (Bcf/d) or 442 million cubic metres per day (106m3/d) in 2017
  # and 16.2 Bcf/d (460 106m3/d) over the first half of 2018.
  #
  # Natural gas production in the Reference Case declines early in the projection period,
  # reaching a low of 15.9 Bcf/d (450 106m3/d) in 2021. After 2021, production begins to
  # increase as gradually higher prices encourage enough drilling to offset production
  # declines from older wells, and development associated with assumed LNG exports support
  # increased capital spending. This leads to more natural gas wells and production
  # in the WCSB. By 2040, production increases to 20.9 Bcf/d (593 106m3/d).
  # https://www.neb-one.gc.ca/nrg/ntgrtd/ftr/2018/chptr3-eng.html
  # Jeff Amlin 4/22/19
  #

  years = [Yr(2017),Yr(2018),Yr(2019),Yr(2020),Yr(2021),Yr(2040)]
  xGMarket[CN,years] = [
  # 2017 2018 2019 2020 2021 2040
  15.6 16.2 16.1 16.0 15.9 20.9
  ]

  years = collect(Yr(2022):Yr(2039))
  for y in years
    xGMarket[CN,y]=xGMarket[CN,y-1]+(xGMarket[CN,Yr(2040)]-xGMarket[CN,Yr(2017)])/(2040-2017)
  end

  years = collect(Yr(2020):Yr(2040))
  for y in years
    xGMarket[CN,y] = xGMarket[CN,y] * GasConv * 365
  end

  #
  # Updated 2022 with data through 2021 from the below url
  # https://www.cer-rec.gc.ca/en/data-analysis/energy-commodities/natural-gas/statistics/marketable-natural-gas-production-in-canada.html
  # Data are provided for every month from 2000-2021.
  # Monthly daily averages are multiplied by number of days in that month.
  # Those figures are summed by year resulting in the below figures.
  #

  years = collect(Yr(2000):Yr(2021))
  xGMarket[CN,years] = [
  #2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
  6117.88 6377.01 6321.35 6104.04 6200.60 6213.02 6243.17 6142.87 5904.95 5509.96 5323.09 5323.16 5092.02 5134.71 5398.15 5538.59 5603.37 5667.72 5898.37 5733.15 5645.75 5882.25
  ]
  for y in years
    xGMarket[CN,y] = xGMarket[CN,y] * GasConv
  end

  #
  # GMMult = xGMarket / (xGProd - xGRaw)
  #

  NaturalGasRaw = Select(Fuel,"NaturalGasRaw")
  for y in Years
    GMMult[CN,y] = sum(xGProd[process,CN,y] * GasProductionMap[process] for process in Processs)
    GMMult[CN,y] = GMMult[CN,y] - sum(xTotDemand[NaturalGasRaw,ecc,area,y] * ANMap[area,CN] for ecc in ECCs, area in Areas)
    @finite_math GMMult[CN,y] = xGMarket[CN,y]/GMMult[CN,y]
  end

  #
  # Use Last historical value for forecast
  #

  years = collect(Yr(1985):Yr(1999))
  for y in years
    GMMult[CN,y] = GMMult[CN,Yr(2000)]
  end
  years = collect(Yr(2022):Final)
  for y in years
    GMMult[CN,y] = GMMult[CN,Yr(2021)]
  end

  #
  # Mexico marketable natural gas
  #
  # Source:  Energy Information System, SENER website, http://sie.energia.gob.mx.
  # Marketable gas = total gas production minus own use.
  # 12/05/2020 R.Levesque
  #

  MX = Select(Nation,"MX")
  years = collect(Yr(1985):Yr(2050))
  xGMarket[MX,years] = [
  #tbtu 1985   1986   1987   1988   1989   1990   1991   1992   1993   1994   1995   1996   1997   1998   1999   2000   2001   2002   2003   2004   2005   2006   2007    2008   2009   2010   2011   2012   2013   2014   2015   2016   2017   2018   2019   2020   2021   2022   2023   2024   2025   2026   2027   2028   2029   2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041     2042   2043    2044    2045    2046    2047    2048    2049    2050
  660.26 585.43 593.61 599.90 571.60 630.71 639.40 581.81 639.35 677.22 668.26 732.91 761.30 763.39 731.21 722.08 705.34 741.35 769.62 763.54 901.61 1014.80 916.63 856.77 980.47 929.14 990.20 943.40 990.69 970.06 906.51 721.36 578.39 274.19 529.19 534.88 556.44 585.90 635.48 696.26 800.26 863.80 951.19 969.96 993.81 1042.46 1034.74 1056.95 1079.64 1102.81 1126.49 1150.67 1175.37 1200.60 1226.37 1252.69 1279.59 1307.05 1335.11 1363.77 1393.04 1422.95 1453.49 1484.69 1516.56 1549.12
  ]

  for y in years
    GMMult[MX,y] = xGMarket[MX,y]/sum(xGProd[process,MX,y]*GasProductionMap[process] for process in Processs)
  end

  WriteDisk(db, "$Input/GMMult", GMMult)

end

function CalibrationControl(db)
  @info "MarketableGas.jl - CalibrationControl"

  SupplyCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
