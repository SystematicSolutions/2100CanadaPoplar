#
# xGOTable.jl
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

Base.@kwdef struct xGOTableData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  xGO::VariableArray{3} = ReadDisk(db, "MInput/xGO") # [ECC,Area,Year]  Gross Output (1985 M$/Yr)

end

function xGOTable_DtaRun(data, areas, AreaName, AreaKey, nation)
  (; SceName,Year,Area,AreaDS,ECCs,ECCDS) = data
  (; Nation,NationDS) = data
  (; ANMap) = data
  (; TOMBaseTime,TOMBaseYear,xGO) = data

  FFF = zeros(Float32, length(Year))
  PPP = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file is created by Economic Drivers.jl.")
  println(iob, " ")

  years = collect(Yr(1985):Final)

  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  print(iob, AreaName," xGross Output for Most Sectors (Billions of $TOMBaseTime \$/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(xGO[ecc, area, year] for area in areas, ecc in ECCs)
  end
  print(iob, "xGO;Total")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in ECCs
    for year in years
      ZZZ[year] = sum(xGO[ecc, area, year] for area in areas)
    end
    print(iob, "xGO;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  filename = "xGOTable-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function xGOTable_DtaControl(db)
  @info "xGOTable_DtaControl"
  data = xGOTableData(; db)
  (; Area, AreaDS, Nation) = data

  #
  # Canada
  #
  areas = Select(Area, (from = "ON", to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  nation = Select(Nation,"CN")
  xGOTable_DtaRun(data, areas, AreaName, AreaKey, nation)
  for area in areas
    xGOTable_DtaRun(data, area, AreaDS[area], Area[area], nation)
  end

  #
  #  US
  #
  areas = Select(Area, (from = "CA", to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  nation = Select(Nation,"US")
  xGOTable_DtaRun(data, areas, AreaName, AreaKey, nation)
  for area in areas
    xGOTable_DtaRun(data, area, AreaDS[area], Area[area], nation)
  end

  #
  #  Mexico
  #
  area = Select(Area,"MX")
  nation = Select(Nation,"MX")
  xGOTable_DtaRun(data, area, AreaDS[area], Area[area], nation)
end

if abspath(PROGRAM_FILE) == @__FILE__
xGOTable_DtaControl(DB)
end

