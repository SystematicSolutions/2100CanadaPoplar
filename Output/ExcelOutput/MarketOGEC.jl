#
# MarketOGEC.jl - Oil and Gas Emission Credit Market Output
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

Base.@kwdef struct MarketOGECData
  db::String

  Outpt::String = "IOutput"
  Input::String = "IInput"

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Market::SetArray = ReadDisk(db, "MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  OGUnit::SetArray = ReadDisk(db, "MainDB/OGUnitKey")
  Process::SetArray = ReadDisk(db, "MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  AreaMarket::VariableArray{3} = ReadDisk(db, "SInput/AreaMarket") # [Area,Market,Year] Areas included in Market
  CoveredOGEC::VariableArray{3} = ReadDisk(db, "SInput/CoveredOGEC") # [ECC,Area,Year] Fuel Coverage for OGEC (1=Covered)
  DBuyMaxOGEC::VariableArray{3} = ReadDisk(db, "SOutput/DBuyMaxOGEC") # [ECC,Area,Year] Decarb Fund Permits Permitted (Tonnes CO2e)
  DBuyOGEC::VariableArray{3} = ReadDisk(db, "SOutput/DBuyOGEC") # [ECC,Area,Year] Decarb Fund Permits Bought for OGEC (Tonnes CO2e)
  ECCMarket::VariableArray{3} = ReadDisk(db, "SInput/ECCMarket") # [ECC,Market,Year] Economic Categories included in Market
  ECCProMap::VariableArray{2} = ReadDisk(db, "SInput/ECCProMap") # [ECC,Process] ECC to Process Map
  ECFPFuel::VariableArray{4} = ReadDisk(db, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price w/CFS Price ($/mmBtu)
  EIOGEC::VariableArray{3} = ReadDisk(db, "SInput/EIOGEC") # [ECC,Area,Year] OGEC Emissions Intensity (Tonnes/Driver)
  ETADAP::VariableArray{2} = ReadDisk(db, "SInput/ETADAP") # [Market,Year] Cost of Tech Fund or Part 3 Credits (Real US$/Tonne)
  ETAPr::VariableArray{2} = ReadDisk(db, "SOutput/ETAPr") # [Market,Year] Cost of Emission Trading Allowances (US$/Tonne)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  FPECCOGEC::VariableArray{4} = ReadDisk(db, "SOutput/FPECCOGEC") # [Fuel,ECC,Area,Year] Incremental OGEC Price ($/mmBtu)
  FPOGEC::VariableArray{4} = ReadDisk(db, "$Outpt/FPOGEC") # [Fuel,EC,Area,Year] OGEC Price ($/mmBtu)
  GoalPolOGEC::VariableArray{3} = ReadDisk(db, "SInput/GoalPolOGEC") # [ECC,Area,Year] Emission Intensity Goal for CFS (Tonnes/TBtu)
  OGPolPrice::VariableArray{3} = ReadDisk(db, "SpOutput/OGPolPrice") # [OGUnit,Fuel,Year] Pollution Cost for Fuel Purchased ($/mmBtu)
  OverBAB::VariableArray{2} = ReadDisk(db, "SOutput/OverBAB") # [Market,Year] Overage Before Adjustment to Bank (Tonnes)
  PBuyMaxOGEC::VariableArray{3} = ReadDisk(db, "SOutput/PBuyMaxOGEC") # [ECC,Area,Year] Total Permits Permitted for OGEC (Tonnes CO2e)
  PBuyOGEC::VariableArray{3} = ReadDisk(db, "SOutput/PBuyOGEC") # [ECC,Area,Year] Market Permits Bought for OGEC (Tonnes CO2e)
  PGratisOGEC::VariableArray{3} = ReadDisk(db, "SOutput/PGratisOGEC") # [ECC,Area,Year] Gratis Permits for OGEC (Tonnes CO2e)
  PNeedOGEC::VariableArray{3} = ReadDisk(db, "SOutput/PNeedOGEC") # [ECC,Area,Year] OGEC Permits Needed (Tonnes CO2e)
  PShortOGEC::VariableArray{3} = ReadDisk(db, "SOutput/PShortOGEC") # [ECC,Area,Year] Excess Emissions Above Permitted Levels (Tonnes CO2e)
  PSellOGEC::VariableArray{3} = ReadDisk(db, "SOutput/PSellOGEC") # [ECC,Area,Year] OGEC Permits Available in Market (Tonnes CO2e)
  PolOGEC::VariableArray{3} = ReadDisk(db, "SOutput/PolOGEC") # [ECC,Area,Year] OGEC Pollution (Tonnes)
  PolOGECRef::VariableArray{3} = ReadDisk(db, "SInput/PolOGECRef") # [ECC,Area,Year] OGEC Pollution (Tonnes)
  xETAPr::VariableArray{2} = ReadDisk(db, "SInput/xETAPr") # [Market,Year] Exogenous Cost of Emission Trading Allowances (1985 US$/Tonne)
  xExchangeRate::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateNation") # [Nation,Year] CN Exchange Rate
  xGAProd::VariableArray{3} = ReadDisk(db, "SInput/xGAProd") # [Process,Area,Year] Historical Primary Gas Production (TBtu/Yr)
  xInflation::VariableArray{2} = ReadDisk(db, "MInput/xInflationNation") # [Nation,Year] US Inflation
  xOAProd::VariableArray{3} = ReadDisk(db, "SInput/xOAProd") # [Process,Area,Year] Oil Production (TBtu/Yr)

  # Scratch Variables
  ZZZ::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Display Variable
end

function MarketSummary(data,iob,market,years)
  (; Market,Nation,Yrv,Year) = data
  (; OverBAB, ETAPr, ETADAP, xETAPr, xExchangeRate, xInflation, ZZZ) = data

  print(iob, "OGEC Market Summary;")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob,"OverBAB;Excess Credits (eCO2 MT/Yr)")
  for year in years
    ZZZ[year] = 0-OverBAB[market,year]/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  print(iob, "ETAPr;Cost of Emissions Trading Allowances (CN\$/Tonne)")
  for year in years
    ZZZ[year] = ETAPr[market,year]*xExchangeRate[CN,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "ETADAP;Cost of Decarb Fund Credits (CN\$/Tonne)")
  for year in years
    ZZZ[year] = ETADAP[market,year]*xInflation[US,year]*xExchangeRate[CN,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xETAPr; Exogenous Cost of Emissions Trading Allowances (CN\$/Tonne)")
  for year in years
    ZZZ[year] = xETAPr[market,year]*xInflation[US,year]*xExchangeRate[CN,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "ETAPr;Cost of Emissions Trading Allowances (US\$/Tonne)")
  for year in years
    ZZZ[year] = ETAPr[market,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "xETAPr; Exogenous Cost of Emissions Trading Allowances (1985 US\$/Tonne)")
  for year in years
    ZZZ[year] = xETAPr[market,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "ETADAP;Cost of Decarb Fund Credits (1985 US\$/Tonne)")
  for year in years
    ZZZ[year] = ETADAP[market,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  println(iob, "")
end

function FacilityRun(data, iob, AreaName, ECCName, eccs, areas, years)
  (; Area, ECC, Yrv, Year) = data
  (; PolOGEC, GoalPolOGEC, PolOGECRef, PNeedOGEC, PSellOGEC) = data
  (; PBuyMaxOGEC, DBuyMaxOGEC, PBuyOGEC, DBuyOGEC, PShortOGEC, ZZZ) = data

  print(iob, AreaName, " ", ECCName, " OGEC Total Emissions (CO2e KiloTonnes));")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "PolOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(PolOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "GoalPolOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(GoalPolOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "PolOGECRef; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(PolOGECRef[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "PNeedOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(PNeedOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "PSellOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(PSellOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "PBuyMaxOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(PBuyMaxOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "DBuyMaxOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(DBuyMaxOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "PBuyOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(PBuyOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "DBuyOGEC; ", AreaName, " ", ECCName)
  for year in years
    ZZZ[year] = sum(DBuyOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  print(iob, "PShortOGEC; ", AreaName, " ", ECCName, ";")
  for year in years
    ZZZ[year] = sum(PShortOGEC[ecc,area,year] for ecc in eccs, area in areas)/1e6
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  println(iob, " ")
end

function EmissionIntensity(data, iob, AreaName, ECCName, areas, eccs, years)
  (; Area, AreaDS, ECC, ECCDS, Yrv, Year) = data
  (; EIOGEC, ZZZ) = data

  print(iob, AreaName, " ", ECCName, " OGEC Emissions Intensity (eCO2 Tonnes/TBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  
  for area in areas
    for ecc in eccs
      print(iob, "EIOGEC; ", Area[area], " ", ECC[ecc], ";")
      for year in years
        ZZZ[year] = EIOGEC[ecc,area,year]/1e6
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob, " ")
end

function MarketOGEC_DTARun(data)
  (; Area, ECC, Market, SceName, Year, Yrv) = data
  (; AreaMarket, ECCMarket) = data

  years = collect(Yr(1990):Final)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, SceName, "; is the scenario name.")
  println(iob, " ")
  println(iob, "This file was produced by MarketOGEC.txo")
  println(iob)
  print(iob, "Year;")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob, " ")
  println(iob, " ")
 
  #
  # Select Market 5
  #
  market = 5
  
  #
  # Select areas and ECCs in this market
  #
  year_check = Yr(2020)
  areas = findall(AreaMarket[:,market,year_check] .== 1)
  eccs = findall(ECCMarket[:,market,year_check] .== 1)
  
  # Add diagnostics
  #@info "Market: $market"
  #@info "Number of areas: $(length(areas))"
  #@info "Number of ECCs: $(length(eccs))"
  #@info "Areas: $areas"
  #@info "ECCs: $eccs"

  if !isempty(areas) && !isempty(eccs)
  
    #
    # Market Summary
    #
    MarketSummary(data,iob,market,years)

    #
    # Total Market
    #
    AreaName = "OGEC Market"
    ECCName = "Total"
    FacilityRun(data, iob, AreaName, ECCName, eccs, areas, years)

    #
    # Emission Intensity
    #
    EmissionIntensity(data, iob, AreaName, ECCName, areas, eccs, years)

    #
    # Facility Accounting by Area and ECC
    #
    for area in areas
      for ecc in eccs
        AreaName = Area[area]
        ECCName = ECC[ecc]
        FacilityRun(data, iob, AreaName, ECCName, [ecc], [area], years)
      end
    end
  end

  #
  # Create output file
  #
  filename = "MarketOGEC-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do file
    write(file, String(take!(iob)))
  end
end

function MarketOGEC_DtaControl(db)
  @info "MarketOGEC_DtaControl"
  data = MarketOGECData(; db)
  
  MarketOGEC_DTARun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
  MarketOGEC_DtaControl(DB)
end
