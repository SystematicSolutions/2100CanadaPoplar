#
#  HydrogenBalance.jl - Hydrogen Fuel Balance
#
#  The ENERGY 2100 model and all associated software are
#  the property of Systematic Solutions, Inc. and cannot
#  be modified or distributed to others without expressed,
#  written permission of Systematic Solutions, Inc.
#  2016 Systematic Solutions, Inc.  All rights reserved.
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct HydrogenBalanceData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int}    = collect(Select(Area))
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Class::SetArray  = ReadDisk(db, "MainDB/Class")
  Classes::Vector{Int}    = collect(Select(Class))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int}     = collect(Select(ECC))
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")
  ES::SetArray     = ReadDisk(db, "MainDB/ES")
  ESs::Vector{Int}    = collect(Select(ES))
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  Fuel::SetArray   = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int}    = collect(Select(Fuel))
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  H2Tech::SetArray = ReadDisk(db, "MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Year::SetArray   = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area, Nation] Map between Area and Nation
  CgDemand::VariableArray{4} = ReadDisk(db, "SOutput/CgDemand") #[Fuel,ECC,Area,Year]  Cogeneration Demands (TBtu/Yr)
  ECCCLMap::VariableArray{2} = ReadDisk(db, "MainDB/ECCCLMap") #[ECC,Class]  Map Between ECC and Class (map)
  EUDemand::VariableArray{4} = ReadDisk(db, "SOutput/CgDemand") #[Fuel,ECC,Area,Year]  Enduse Demands (TBtu/Yr)

  FPF::VariableArray{4} = ReadDisk(db, "SOutput/FPF") # [Fuel, ES, Area, Year] Delivered Fuel Price ($/mmBtu)
  FsDemand::VariableArray{4} = ReadDisk(db, "SOutput/FsDemand") # [Fuel, ECC, Area, Year] Feedstock Demands (tBtu)
  FsFP::VariableArray{4} = ReadDisk(db, "SOutput/FsFP") # [Fuel, ES, Area, Year] Feedstock Fuel Price ($/mmBtu)

  H2Dem::VariableArray{2} = ReadDisk(db, "SpOutput/H2Dem") # [Area,Year] Demand for Hydrogen (TBtu/Yr)
  H2DemNation::VariableArray{2} = ReadDisk(db, "SpOutput/H2DemNation") # [Nation,Year] National Demand for Hydrogen (TBtu/Yr)
  H2Exports::VariableArray{2} = ReadDisk(db, "SpOutput/H2Exports") # [Nation,Year] Hydrogen Exports (TBtu/Yr)
  H2Imports::VariableArray{2} = ReadDisk(db, "SpOutput/H2Imports") # [Nation,Year] Hydrogen Imports (TBtu/Yr)
  H2MCE::VariableArray{3} = ReadDisk(db, "SpOutput/H2MCE") # [H2Tech, Area,Year] Hydrogen Levelized Marginal Cost ($/mmBtu)
  H2Prod::VariableArray{3} = ReadDisk(db, "SpOutput/H2Prod") # [H2Tech, Area,Year] Hydrogen Production (TBtu/Yr)
  H2Production::VariableArray{2} = ReadDisk(db, "SpOutput/H2Production") # [Area,Year] Hydrogen Production (TBtu/Yr)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  # Scratch variables
  KJBtu = 1.054615 # Kilo Joule per BTU
  ZZZ::VariableArray{1} = zeros(Float32, size(Year,1))
  year = collect(Yr(1990):Yr(2050))
  years = collect(Yr(1990):Yr(2050))

end


function HydrogenBalance(data,iob,areas,AreaName,AreaKey)
  (; Class,Classes,ECC,ECCs,ECCDS,Fuel,Fuels,H2Tech,H2Techs,Nation,Year,Years) = data
  (; CgDemand, ECCCLMap, EUDemand, FsDemand, H2DemNation, H2Exports, H2Imports, H2Prod, KJBtu, year, years, ZZZ) = data
  #

  hyd_fuel = Select(Fuel, "Hydrogen")
  #
  print(iob, "$AreaName Hydrogen Balance (PJ/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  #
  RRR = zeros(Float32, length(Year))
  AAA = zeros(Float32, length(Year))
  if AreaKey == "CN" || AreaKey == "US"
    for year in years
      ZZZ[year] = H2DemNation[Select(Nation, AreaKey), year] * KJBtu
    end
    print(iob, "H2DemNation;Hydrogen Demand")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
  else
    print(iob, "H2DemNation;Hydrogen Demand", repeat(";--", size(year,1)))
  end
  println(iob)
  
  #
  for year in years
    ZZZ[year] = sum(EUDemand[hyd_fuel, ecc, area, year] for ecc in ECCs, area in areas) * KJBtu
    RRR[year] = RRR[year] + ZZZ[year]
  end
  print(iob, "EuDemand;Total Enduse Energy Demands")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for class in Classes
    try
      map_ecc = Select(ECCCLMap[ECCs, class], ==(1))
      for year in years
        ZZZ[year] = sum(EUDemand[hyd_fuel, map_ecc, area, year] for map_ecc in ECCs, area in areas) * KJBtu
      end
      print(iob, "  EuDemand; $(Class[class]) Enduse Energy Demands")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    catch
      print(iob, "  EuDemand; $(Class[class]) Enduse Energy Demands")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
  end

  ug_ecc = Select(ECC, "UtilityGen")
  for year in years
    ZZZ[year] = sum(EUDemand[hyd_fuel, ecc, area, year] for ecc in ug_ecc, area in areas) * KJBtu
  end
  print(iob, "  EuDemand; $(ECCDS[ug_ecc]) Enduse Energy Demands")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)

  #
  for year in years
    ZZZ[year] = sum(FsDemand[hyd_fuel, ecc, area, year] for ecc in ECCs, area in areas) * KJBtu
    RRR[year] = RRR[year] + ZZZ[year]
  end
  print(iob, "FsDemand;Feedstock Energy Demands")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)

  #
  for year in years
    ZZZ[year] = sum(CgDemand[hyd_fuel, ecc, area, year] for ecc in ECCs, area in areas) * KJBtu
    RRR[year] = RRR[year] + ZZZ[year]
  end
  print(iob, "CgDemand;Cogeneration Energy Demands")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)

  #
  if AreaKey == "CN" || AreaKey == "US"
    for year in years
      ZZZ[year] = H2Exports[Select(Nation, AreaKey), year] * KJBtu
      RRR[year] = RRR[year] + ZZZ[year]
    end
    print(iob, "H2Exports;Hydrogen Exports")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  else
    print(iob, "H2Exports;Hydrogen Exports", repeat(";--", size(year,1)))
    println(iob)
  end

  #
  for year in years
    ZZZ[year] = RRR[year]
  end  
  print(iob, "Requirements;Total Hydrogen Requirements")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)

  #
  for year in years
    ZZZ[year] = sum(H2Prod[h2tech, area, year] for h2tech in H2Techs, area in areas) * KJBtu
    AAA[year] = AAA[year] + ZZZ[year]
  end
  print(iob, "H2Prod;Total Hydrogen Production")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    for year in years
      ZZZ[year] = sum(H2Prod[h2tech, area, year] for area in areas) * KJBtu
    end
    print(iob, "  H2Prod; $(H2Tech[h2tech]) Production")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  #
  if AreaKey == "CN" || AreaKey == "US"
    for year in years
      ZZZ[year] = H2Imports[Select(Nation, AreaKey), year] * KJBtu
      AAA[year] = AAA[year] + ZZZ[year]
    end
    print(iob, "H2Imports;Hydrogen Imports")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  else
    print(iob, "H2Imports;Hydrogen Imports", repeat(";--", size(year,1)))
    println(iob)
  end

  for year in years
    ZZZ[year] = AAA[year]
  end
  print(iob, "Available;Total Hydrogen Available")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)

  #
  for year in years
    ZZZ[year] = RRR[year] - AAA[year]
  end
  print(iob, "Net Inflows;Net Inflows")
  for year in years
    print(iob,";",@sprintf("%.4f", ZZZ[year]))
  end
  println(iob)
  return iob
end

function HydrogenPrices(data,iob,areas,AreaName)
  (; ESs, ESDS, Fuel, FuelDS, Year) = data
  (; CDTime, CDYear, FsFP, FPF, H2Production, Inflation, MoneyUnitDS, year, years, ZZZ) = data

  #
  # CDYear = max(CDYear,1)
  println(iob)
  h_ng_fuel = Select(Fuel, ["Hydrogen", "NaturalGas"])
  for fuel in h_ng_fuel
    print(iob, "$AreaName $(FuelDS[fuel]) Prices ($CDTime $(MoneyUnitDS[areas[1]]) /mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for es in ESs
      for year in years
        ZZZ[year] = sum(FPF[fuel,es,area,year] / Inflation[area,CDYear] *
          H2Production[area,year] for area in areas) / max.(sum(H2Production[area,year] for area in areas),0.00001)
      end
      print(iob, "FPF;$(ESDS[es]) $(FuelDS[fuel])")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  for fuel in h_ng_fuel
    print(iob, "$AreaName $(FuelDS[fuel]) Feedstock Prices ($CDTime $(MoneyUnitDS[areas[1]]) /mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for es in ESs
      for year in years
        ZZZ[year] = sum(FsFP[fuel,es,area,year] / Inflation[area,CDYear] *
          H2Production[area,year] for area in areas) / max.(sum(H2Production[area,year] for area in areas),0.00001)
      end
      print(iob, "FsFP;$(ESDS[es]) $(FuelDS[fuel])")
      for year in years
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end
  return iob
end

function HydrogenCosts(data,iob,areas,AreaName)
  (; H2Tech, H2Techs, Year) = data
  (; CDTime, CDYear, H2MCE, H2Production, Inflation, MoneyUnitDS, year, years, ZZZ) = data

  print(iob, "$AreaName Hydrogen Levelized Marginal Cost ($CDTime $(MoneyUnitDS[areas[1]]) /mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for h2tech in H2Techs
    for year in years
      ZZZ[year] = sum(H2MCE[h2tech,area,year] / Inflation[area,CDYear] *
        H2Production[area,year] for area in areas) / max.(sum(H2Production[area,year] for area in areas),0.00001)
    end
    print(iob, "H2MCE;$(H2Tech[h2tech])")
    for year in years
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  return iob
end

function HydrogenBalance_DtaRun(data,areas,AreaName,AreaKey)
  (; Area, AreaDS, Areas, ECC, ECCDS, ECCs, Fuel, FuelDS, Fuels, Year) = data
  (; SceName,year) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$AreaName")
  println(iob, "This $AreaName Hydrogen Balance file was produced by HydrogenBalance.jl \n \n")
  #
  println(iob, "Year;;", join(Year[year], ";"))
  println(iob, " ")
  #
  iob = HydrogenBalance(data,iob,areas,AreaName,AreaKey)
  iob = HydrogenPrices(data,iob,areas,AreaName)
  iob = HydrogenCosts(data,iob,areas,AreaName)

  #
  # Create *.dta filename and write output values
  #
  filename = "HydrogenBalance-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function HydrogenBalance_DtaControl(db)
  # @info "HydrogenBalance_DtaControl"
  data = HydrogenBalanceData(; db)
  (; Area, Areas, AreaDS) = data

  #
  # Canada
  #
  areas = Select(Area, (from = "ON", to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  HydrogenBalance_DtaRun(data,areas,AreaName,AreaKey)

  #
  #  US
  #
  areas = Select(Area, (from = "CA", to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  HydrogenBalance_DtaRun(data,areas,AreaName,AreaKey)

  #
  # Individual Areas
  #
  for areas in Areas
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    HydrogenBalance_DtaRun(data,areas,AreaName,AreaKey)
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
HydrogenBalance_DtaControl(DB)
end

