#
# EconomicDriver.jl
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

Base.@kwdef struct EconomicDriverData
  db::String

  Area     = ReadDisk(db, "MainDB/AreaDS")
  ECC      = ReadDisk(db, "MainDB/ECCDS")
  Year     = ReadDisk(db, "MainDB/YearDS")
  Driver   = ReadDisk(db, "MOutput/Driver")
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

end

function EconomicDriver_DtaRun(data)
  (; Year, Area, ECC, Driver,SceName) = data

  iob = IOBuffer()

  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Economic Driver")
  println(iob, " ")

  years = collect(Yr(1985):Final)
  year = Select(Year)

  print(iob, "Year;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  
  println(iob, " ")

  for area in Select(Area)
    print(iob, Area[area], " Economic Driver (Various Millions/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ecc in Select(ECC)
      for year in years
        ZZZ[year] = Driver[ecc, area, year]
      end
      print(iob, "Driver;", ECC[ecc])
      for year in years
        print(iob,";",@sprintf("%15.4f;",ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  filename = "EconomicDriver-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function EconomicDriver_DtaControl(db)
  @info "EconomicDriver_DtaControl"
  data = EconomicDriverData(; db)
  EconomicDriver_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
EconomicDriver_DtaControl(DB)
end

