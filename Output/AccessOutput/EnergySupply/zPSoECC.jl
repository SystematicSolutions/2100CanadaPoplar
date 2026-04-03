#
# zPSoECC.jl
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

Base.@kwdef struct zPSoECCData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zPSoECC::VariableArray{3} = ReadDisk(db,"SOutput/PSoECC") # [ECC,Area,Year] # Power Sold to Grid (GWh/Yr)
  zPSoECCRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/PSoECC") # [ECC,Area,Year] # Power Sold to Grid (GWh/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zPSoECC_DtaRun(data,nation)
  (; Area,AreaDS,Areas,ECCDS,ECCs,Nation,NationDS,Nations,Year,SceName) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,UnitsDS,zPSoECC,zPSoECCRef,ZZZ) = data

  if BaseSw != 0
    @. zPSoECCRef = zPSoECC
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "GWh"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "GWh"
  end

  for ecc in ECCs
    for area in areas
      for year in years
        ZZZ[year] = zPSoECC[ecc,area,year]*Conversion[nation,year]
        CCC[year] = zPSoECCRef[ecc,area,year]*Conversion[nation,year]
        if ZZZ[year] != 0 || CCC[year] != 0
          println(iob,"zPSoECC;",Year[year],";",AreaDS[area],";",
            ECCDS[ecc],";",UnitsDS[nation],";",ZZZ[year],";",CCC[year])
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zPSoECC-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zPSoECC_DtaControl(db)
  data = zPSoECCData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zPSoECC_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPSoECC_DtaRun(data,nation,)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zPSoECC_DtaControl(DB)
end
