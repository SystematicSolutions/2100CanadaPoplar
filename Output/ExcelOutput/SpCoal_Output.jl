#
# SpCoal_Output.jl
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

Base.@kwdef struct SpCoal_OutputData
  db::String

  Area     = ReadDisk(db, "MainDB/AreaKey")
  AreaDS     = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Day      = ReadDisk(db, "MainDB/DayDS")
  ECC      = ReadDisk(db, "MainDB/ECCKey")
  ECCDS      = ReadDisk(db, "MainDB/ECCDS")
  ES       = ReadDisk(db, "MainDB/ESDS")
  Fuel     = ReadDisk(db, "MainDB/FuelDS")
  FuelEP   = ReadDisk(db, "MainDB/FuelEPDS")
  Hour     = ReadDisk(db, "MainDB/HourDS")
  Month    = ReadDisk(db, "MainDB/MonthDS")
  Nation   = ReadDisk(db, "MainDB/NationKey")
  NationDS   = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll     = ReadDisk(db, "MainDB/PollKey")
  PollDS     = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year     = ReadDisk(db, "MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CAProd   = ReadDisk(db, "SOutput/CAProd")
  CADemand = ReadDisk(db, "SpOutput/CADemand")
  CDemand  = ReadDisk(db, "SpOutput/CDemand")
  CProd    = ReadDisk(db, "SpOutput/CProd")
  CPrTax   = ReadDisk(db, "SpOutput/CPrTax")
  eCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") #[Area,Year]  Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ENPN     = ReadDisk(db, "SOutput/ENPN")
  Exports  = ReadDisk(db, "SpOutput/Exports")
  GOMSmooth::VariableArray{3} = ReadDisk(db, "SOutput/GOMSmooth") #[ECC,Area,Year]  Smooth of Gross Output Multiplier ($/$)
  GOMult::VariableArray{3} = ReadDisk(db, "SOutput/GOMult") #[ECC,Area,Year]  Gross Output Multiplier ($/$)
  Imports  = ReadDisk(db, "SpOutput/Imports")
  InflationNation = ReadDisk(db, "MOutput/InflationNation")
  SupplyAdjustments  = ReadDisk(db, "SpOutput/SupplyAdjustments")
  xCAProd  = ReadDisk(db, "SpInput/xCAProd")
  xENPN    = ReadDisk(db, "SInput/xENPN")
  xExports = ReadDisk(db, "SpInput/xExports")
  xImports = ReadDisk(db, "SpInput/xImports")
  xSupplyAdjustments = ReadDisk(db, "SpInput/xSupplyAdjustments")
end

function SpCoal_Output_DtaRun(data)
  (; SceName,Year, Areas, AreaDS, ECC, ECCDS, Nations, NationDS, Polls, PollDS, Fuel, FuelEP, ANMap, InflationNation) = data
  (; eCO2Price, CProd, CDemand, Imports, Exports, SupplyAdjustments, CAProd, CADemand, CPrTax, xCAProd, ENPN) = data
  (; xENPN, xImports, xExports, xSupplyAdjustments, GOMSmooth, GOMult) = data
  fuel = Select(Fuel, "Coal")
  fuelep = Select(FuelEP, "Coal")
  infla_year = Select(Year, "2010")
  ZZZ = zeros(Float32, length(Year))
  # year = Select(Year, (from = "1990", to = "2050"))
  years = collect(Yr(1990):Final)
  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This is the SpCoal Summary.")
  println(iob, " ")
  println(iob, "Year;;", join(Year[years], ";"))
  println(iob, " ")

  println(iob, "*** SpCoal Outputs ***")
  println(iob, " ")

  print(iob, "Carbon Tax plus Permit Cost (\$/eCO2 Tonnes);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    area = first(areas)
    for year in years
      ZZZ[year] = eCO2Price[area,year]
    end
    print(iob, "eCO2Price;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Production (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = CProd[nation, year]
    end
    print(iob, "CProd;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Demand (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = CDemand[nation, year]
    end
    print(iob, "CDemand;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Imports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = Imports[fuelep, nation, year]
    end
    print(iob, "Imports;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Exports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = Exports[fuelep, nation, year]
    end
    print(iob, "Exports;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Supply Adjustments (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = SupplyAdjustments[fuelep, nation, year]
    end
    print(iob, "SupplyAdjustments;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Production (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CAProd[area, year] for area in Areas)
  end
  print(iob, "CAProd;", "Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for area in Areas
    for year in years
      ZZZ[year] = CAProd[area, year]
    end
    print(iob, "CAProd;", AreaDS[area])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Demand (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CADemand[area, year] for area in Areas)
  end  
  print(iob, "CADemand;", "Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for area in Areas
    for year in years
      ZZZ[year] = CADemand[area, year]
    end
    print(iob, "CADemand;", AreaDS[area])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Production Tax (\$/Tonne);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = CPrTax[nation, year]
    end
    print(iob, "CPrTax;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Production - Reference Case (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    for year in years
      ZZZ[year] = xCAProd[area, year]
    end
    print(iob, "xCAProd;", AreaDS[area])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  ecc = Select(ECC,"CoalMining")
  print(iob, ECCDS[ecc]," Gross Output Multiplier (\$/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    for year in years
      ZZZ[year] = GOMult[ecc,area,year]
    end
    print(iob, "GOMult;", AreaDS[area])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Primary Fuel Price (2010 CN\$/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = ENPN[fuel, nation, year] * InflationNation[nation, infla_year]
    end
    print(iob, "ENPN;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, "Coal Exogenous Primary Fuel Price (2010 CN\$/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for nation in Nations
    for year in years
      ZZZ[year] = xENPN[fuel, nation, year] * InflationNation[nation, infla_year]
    end
    print(iob, "xENPN;", NationDS[nation])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, ECCDS[ecc]," Smooth of Gross Output Multiplier (\$/\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    for year in years
      ZZZ[year] = GOMSmooth[ecc,area,year]
    end
    print(iob, "GOMSmooth;", AreaDS[area])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  filename = "SpCoal-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function SpCoal_Output_DtaControl(db)
  @info "SpCoal_Output_DtaControl"
  data = SpCoal_OutputData(; db)
  SpCoal_Output_DtaRun(data)
end
if abspath(PROGRAM_FILE) == @__FILE__
SpCoal_Output_DtaControl(DB)
end
