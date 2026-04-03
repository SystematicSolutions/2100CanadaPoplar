#
# zFsDmd.jl
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

Base.@kwdef struct zFsDmdData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zFsDmd::VariableArray{4} = ReadDisk(db, "SOutput/FsDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (tBtu)
  zFsDmdRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/FsDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (tBtu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zFsDmd_DtaRun(data,nation)
  (; AreaDS,ECC,ECCDS,ECCs,FuelDS,Fuels) = data
  (; Nation,Year) = data
  (; ANMap,CCC,Conversion,EndTime) = data
  (; UnitsDS,zFsDmd,zFsDmdRef,ZZZ,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "TBtu/Yr"
    Conversion[CN,year] = 1.054615*1000
    UnitsDS[CN] = "TJ/Yr"
  end

  for fuel in Fuels
    for ecc in ECCs
      for area in areas
        for year in years
          ZZZ[year] = zFsDmd[fuel,ecc,area,year]*Conversion[nation,year]
          CCC[year] = zFsDmdRef[fuel,ecc,area,year]*Conversion[nation,year]
          if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zFsDmd;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
              FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zFsDmd-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zFsDmd_DtaControl(db)
  data = zFsDmdData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zFsDmd_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zFsDmd_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zFsDmd_DtaControl(DB)
end
