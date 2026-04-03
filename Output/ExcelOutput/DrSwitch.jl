#
# DrSwitch.jl
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

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  Driver::VariableArray{3} = ReadDisk(db, "MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  DrSwitch::VariableArray{3} = ReadDisk(db,"MInput/DrSwitch") # [ECC,Area,Year] Economic Driver Switch
  ECCProMap::VariableArray{2} = ReadDisk(db,"SInput/ECCProMap") #[ECC,Process]  ECC to Process Map
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Economic Driver (Real M$/Yr)

end

function DrSwitch_DtaRun(data,area)
  (; Area,AreaDS,ECC,ECCDS,ECCs,Process,Processs,Year) = data
  (; Driver,DrSwitch,ECCProMap,xDriver,SceName) = data
  
  ZZZ = zeros(Float32, length(Year))
  PPP = zeros(Int, length(Process))

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file is created by DrSwitch.jl.")
  println(iob, " ")

  AreaName = AreaDS[area]
  years = collect(Yr(2022):Yr(2025))

  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  print(iob, AreaName," Economic Driver Switch;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in ECCs
    print(iob, "DrSwitch;", ECCDS[ecc])
    for year in years
      ZZZ[year] = DrSwitch[ecc,area,year]
      print(iob,";",@sprintf("%15.0f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, AreaName," Economic Driver;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in ECCs
    print(iob, "xDriver;", ECCDS[ecc])
    for year in years
      ZZZ[year] = xDriver[ecc,area,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  print(iob, AreaName," Economic Driver;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in ECCs
    print(iob, "Driver;", ECCDS[ecc])
    for year in years
      ZZZ[year] = Driver[ecc,area,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  
  AreaKey = Area[area]
  filename = "DrSwitch-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function DrSwitch_DtaControl(db)
  @info "DrSwitch_DtaControl"
  data = MControl(; db)
  (; Area,AreaDS,) = data

  #
  # Canada
  #
  areas = Select(Area,(from="AB",to="YT"))
  for area in areas
    DrSwitch_DtaRun(data,area)
  end

  #
  #  US
  #
  areas = Select(Area,(from ="CA",to="Pac"))
  for area in areas
    DrSwitch_DtaRun(data,area)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
DrSwitch_DtaControl(DB)
end
