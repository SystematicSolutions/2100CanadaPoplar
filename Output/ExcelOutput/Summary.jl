#
# Summary.jl
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

Base.@kwdef struct SummaryData
  db::String

  Area = ReadDisk(db, "MainDB/AreaDS")
  ECC = ReadDisk(db, "MainDB/ECCDS")
  Fuel = ReadDisk(db, "MainDB/FuelDS")
  FuelEP = ReadDisk(db, "MainDB/FuelEPDS")
  Poll = ReadDisk(db, "MainDB/PollDS")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year = ReadDisk(db, "MainDB/YearKey")

  CAProd = ReadDisk(db, "SOutput/CAProd") # (Area, Year), Primary Coal Production (TBtu/Yr)
  EuPol = ReadDisk(db, "SOutput/EuPol") # (:ECC, :Poll, :Area, :Year), Energy Related Pollution (Tonnes/Yr)
  EuDemand = ReadDisk(db, "SOutput/EuDemand") # (Fuel, ECC, Area, Year), Enduse Energy Demand (TBtu/Yr)
  FsDemand = ReadDisk(db, "SOutput/FsDemand") # (Fuel, ECC, Area, Year), Feedstock Energy Demand (TBtu/Yr)
  H2Production = ReadDisk(db, "SpOutput/H2Production") # (Area, Year), Hydrogen Production (TBtu/Yr)
  TotDemand = ReadDisk(db, "SOutput/TotDemand") # (Fuel, ECC, Area, Year), Total Energy Demand (TBtu/Yr)
  TotFPol = ReadDisk(db, "SOutput/TotFPol") # (FuelEP, ECC, Poll, Area, Year), Pollution (Tonnes/Yr)
  TotPol = ReadDisk(db, "SOutput/TotPol") # (ECC, Poll, Area, Year), Pollution (Tonnes/Yr)
end

function Summary_DtaRun(data)
    (; SceName,Year, Area, ECC, Fuel, FuelEP, Poll) = data
    (; CAProd, EuPol, EuDemand, FsDemand, H2Production, TotDemand, TotFPol) = data

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file was produced by Summary.jl")
  println(iob, " ")

  # year = Select(Year, (from = "1985", to = "2050"))
  years = collect(Yr(1985):Final)

  println(iob, "Year;", ";", join(Year[years], ";    "))
  println(iob, " ")

  # TotFPol
  print(iob, "Total Pollution (Tonnes/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Select(Area)
    print(iob, "TotFPol;", Area[area])
    for year in years
      ZZZ[year] = sum(TotFPol[fuelep,ecc,poll,area,year] for fuelep in Select(FuelEP), ecc in Select(ECC), poll in Select(Poll))
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # EuPol
  print(iob, "Energy-Related Pollution (Tonnes/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Select(Area)
    print(iob, "EuPol;", Area[area])
    for year in years
      ZZZ[year] = sum(EuPol[ecc,poll,area,year] for ecc in Select(ECC), poll in Select(Poll))
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # TotDemand
  print(iob, "Total Energy Demands (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Select(Area)
    print(iob, "TotDemand;", Area[area])
    for year in years
      ZZZ[year] = sum(TotDemand[fuel, ecc, area, year] for ecc in Select(ECC), fuel in Select(Fuel))
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # EuDemand

  print(iob, "Enduse Energy Demands (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Select(Area)
    print(iob, "EuDemand;", Area[area])
    for year in years
      ZZZ[year] = sum(EuDemand[fuel, ecc, area, year] for ecc in Select(ECC), fuel in Select(Fuel))
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # FsDemand

  print(iob, "Feedstock Energy Demands (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Select(Area)
    print(iob, "FsDemand;", Area[area])
    for year in years
      ZZZ[year] = sum(FsDemand[fuel, ecc, area, year] for ecc in Select(ECC), fuel in Select(Fuel))
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # CAProd

  print(iob, "Primary Coal Production (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Select(Area)
    print(iob, "CAProd;", Area[area])
    for year in years
      ZZZ[year] = CAProd[area, year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # H2Production

  print(iob, "Hydrogen Production (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Select(Area)
    print(iob, "H2Production;", Area[area])
    for year in years
      ZZZ[year] = H2Production[area, year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  # Create file

  filename = "Summary-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function Summary_DtaControl(db)
  @info "Summary_DtaControl"
  data = SummaryData(; db)

  Summary_DtaRun(data)
end
if abspath(PROGRAM_FILE) == @__FILE__
Summary_DtaControl(DB)
end
