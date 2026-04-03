#
# EmpTOMDB.jl - Employment from TOM (not mapped)
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

Base.@kwdef struct EmpTOMDBData
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
  
  ZZZ = zeros(Float32, length(Year))
end

function EmpTOMDB_DtaRun(data)
  (; SceName,AreaTOM,AreaTOMs,AreaTOMDS,ECCTOM,ECCTOMDS,ECCTOMs,Year) = data
  (; EmpTOM,ZZZ,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;AreaTOM;ECCTOMLabel;Units;Data")

  years = collect(Yr(1985):Final)


  for ecctom in ECCTOMs, areatom in AreaTOMs, year in years
        ZZZ[year] = EmpTOM[ecctom,areatom,year]
        println(iob,"EmpTOM;",Year[year],";",AreaTOMDS[areatom],";",ECCTOMDS[ecctom],";",
          "Thousands;",ZZZ[year])
  end

  filename = "EmpTOMDB-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function EmpTOMDB_DtaControl(db)
  @info "EmpTOMDB_DtaControl"
  data = EmpTOMDBData(; db)

    EmpTOMDB_DtaRun(data)

end

if abspath(PROGRAM_FILE) == @__FILE__
EmpTOMDB_DtaControl(DB)
end

