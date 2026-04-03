#
# EmpTOM.jl - Employment from TOM (not mapped)
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

Base.@kwdef struct EmpTOMData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db, "KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  EmpTOM::VariableArray{3} = ReadDisk(db,"KOutput/EmpTOM") #[ECCTOM,AreaTOM,Year] Employment (Persons)
  
end

function EmpTOM_DtaRun(data,areatom)
  (; AreaTOM,AreaTOMDS,ECCTOM,ECCTOMDS,ECCTOMs,Year) = data
  (; EmpTOM,SceName) = data
  ZZZ = zeros(Float32, length(Year))

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file is created by EmpTOM.jl.")
  println(iob, " ")

  AreaName = AreaTOMDS[areatom]
  years = collect(Yr(1990):Final)

  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  print(iob, AreaName," Employment (Thousands);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecctom in ECCTOMs
    print(iob, "EmpTOM;", ECCTOMDS[ecctom])
    for year in years
      ZZZ[year] = EmpTOM[ecctom,areatom,year]/1000
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")

  AreaTOMKey = AreaTOM[areatom]
  filename = "EmpTOM-$AreaTOMKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function EmpTOM_DtaControl(db)
  @info "EmpTOM_DtaControl"
  data = EmpTOMData(; db)
  (; AreaTOM,AreaDS,) = data

  #
  # Canada
  #
  areatoms = Select(AreaTOM,(from="AB",to="YT"))
  for areatom in areatoms
    EmpTOM_DtaRun(data,areatom)
  end

  #
  #  US
  #
  areatoms = Select(AreaTOM,(from ="NEng",to="CA"))
  for areatom in areatoms
    EmpTOM_DtaRun(data,areatom)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
EmpTOM_DtaControl(DB)
end
