#
# eCO2Prices.jl - Carbon Prices
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct eCO2PricesData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}     = collect(Select(Area))
  Iter::SetArray = ReadDisk(db,"MainDB/IterKey")
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray   = ReadDisk(db,"MainDB/YearDS")

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  AreaMarket::VariableArray{3} = ReadDisk(db,"SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  CapTrade::VariableArray{2} = ReadDisk(db,"SInput/CapTrade") # [Market,Year] Emission Cap and Trading Switch (1=Trade,Cap Only=2)
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  ECCMarket::VariableArray{3} = ReadDisk(db,"SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  eCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ETADAP::VariableArray{2} = ReadDisk(db,"SInput/ETADAP") # [Market,Year] Cost of Domestic Allowances from Government (1985 US$/Tonne)
  ETAFAP::VariableArray{2} = ReadDisk(db,"SInput/ETAFAP") # [Market,Year] Cost of Foreign Allowances ($/Tonne)
  ETAPr::VariableArray{2} = ReadDisk(db,"SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ETR::VariableArray{3} = ReadDisk(db, "SOutput/ETR") # [Market,Iter,Year] Permit Costs ($/Tonne)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  xETAPr::VariableArray{2} = ReadDisk(db,"SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)

  ZZZ::VariableArray{1} = zeros(Float32,length(Year))
end

function eCO2Prices_DtaRun(data,market)
  (; Area,AreaDS,Areas,Nation,Year) = data
  (; SceName,CDTime,CDYear,eCO2Price,ETAPr,xETAPr,ExchangeRateNation,InflationNation,MoneyUnitDS,ZZZ) = data
  
  years = collect(Yr(1990):Final)
  CN=Select(Nation,"CN")

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the Cap-and-Trade Prices.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  MktName="Market $market"

  println(iob, "$MktName Cost of Trading Allowances ($CDTime CN\$/Tonne);;    ", join(Year[years], ";"))
  print(iob,"ETAPr ;Marginal")  
  for year in years  
    ZZZ[year]=ETAPr[market,year]*ExchangeRateNation[CN,year]/InflationNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob,"xETAPr ;Exogenous")  
  for year in years  
    ZZZ[year]=xETAPr[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,CDYear]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$MktName Cost of Trading Allowances (Nominal CN\$/Tonne);;    ", join(Year[years], ";"))
  print(iob,"ETAPr ;Marginal")  
  for year in years  
    ZZZ[year]=ETAPr[market,year]*ExchangeRateNation[CN,year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  print(iob,"xETAPr ;Exogenous")  
  for year in years  
    ZZZ[year]=xETAPr[market,year]*ExchangeRateNation[CN,year]*InflationNation[CN,year]
    print(iob,";",@sprintf("%15.3f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  area_single=first(Areas)
  println(iob, "Carbon Tax plus Permit Cost ($CDTime $(MoneyUnitDS[area_single])/Tonne);;    ", join(Year[years], ";"))
  for area in Areas
    print(iob,"eCO2Price;$(AreaDS[area])")  
    for year in years  
      ZZZ[year]=eCO2Price[area,year]/InflationNation[CN,year]*InflationNation[CN,CDYear]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Carbon Tax plus Permit Cost (Nominal $(MoneyUnitDS[area_single])/Tonne);;    ", join(Year[years], ";"))
  for area in Areas
    print(iob,"eCO2Price;$(AreaDS[area])")  
    for year in years  
      ZZZ[year]=eCO2Price[area,year]
      print(iob,";",@sprintf("%15.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)


  #
  # Create *.dta filename and write output values
  #
  filename = "eCO2Prices$market-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function eCO2Prices_DtaControl(db)
  @info "eCO2Prices_DtaControl"
  data = eCO2PricesData(; db)
  (; db)= data

  markets = [161,151,131]

  for market in markets
    eCO2Prices_DtaRun(data,market)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
eCO2Prices_DtaControl(DB)
end
