#
# zGY.jl
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

Base.@kwdef struct zGYData
  db::String
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  GY::VariableArray{3} = ReadDisk(db,"KOutput/GY") # [ECCTOM,AreaTOM,Year] Gross Output from TOM (2017 CN$M/Yr)
  GYRef::VariableArray{3} = ReadDisk(RefNameDB,"KOutput/GY") # [ECCTOM,AreaTOM,Year] Gross Output from TOM (2017 CN$M/Yr)
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zGY_DtaRun(data,nation,areatoms)
  (; AreaTOM,AreaTOMDS,AreaTOMs,ECCTOMDS,ECCTOMs) = data
  (; Nation,NationDS,Year) = data
  (; BaseSw,CCC,UnitsDS) = data
  (; GY,GYRef,ZZZ,SceName) = data

  if BaseSw != 0
    GYRef = GY
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Final)
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")

  UnitsDS[US]= "2017 \$Million"
  UnitsDS[CN]= "2017 \$Million"

  for year in years
    for areatom in areatoms
      for ecctom in ECCTOMs
        ZZZ[year] = GY[ecctom,areatom,year]
        CCC[year] = GYRef[ecctom,areatom,year]
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"GY;",Year[year],";",AreaTOMDS[areatom],";",
            ECCTOMDS[ecctom],";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zGY-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zGY_DtaControl(db)
  data = zGYData(; db)
  (; AreaTOMs,Nation) = data
  (; MapAreaTOMNation) = data
  
  @info "zGY_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  zGY_DtaRun(data,CN,areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  zGY_DtaRun(data,US,areatoms)

end

if abspath(PROGRAM_FILE) == @__FILE__
  zGY_DtaControl(DB)
end