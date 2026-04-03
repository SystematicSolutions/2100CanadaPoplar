#
# zEnergyIntensity.jl
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

Base.@kwdef struct zEnergyIntensityData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray   = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int}    = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  Driver::VariableArray{3} = ReadDisk(db, "MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  DriverRef::VariableArray{3} = ReadDisk(RefNameDB, "MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  EuDemand::VariableArray{4} = ReadDisk(db,"SOutput/EuDemand") # Energy Demands (TBtu/Yr) [Fuel,ECC,Area,Year]
  EuDemandRef::VariableArray{4} = ReadDisk(db,"SOutput/EuDemand") # Energy Demands (TBtu/Yr) [Fuel,ECC,Area,Year]

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  CCC = zeros(Float32,length(Year))
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  ZZZ = zeros(Float32,length(Year))
end

function zEnergyIntensity_DtaRun(data,nation)
  (; AreaDS,ECC,ECCDS,ECCs,Fuels) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,UnitsDS,SceName) = data
  (; Driver,DriverRef,EuDemand,EuDemandRef,ZZZ) = data

  if BaseSw != 0
    EuDemandRef = EuDemand
    DriverRef = Driver
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(Yr(1990):Final)
  areas = findall(ANMap[:,nation] .== 1)
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year]= 1.054615*1000
  end

  UnitsDS[US]= "tBtu/\$"
  UnitsDS[CN]= "TJ/Driver"

  for year in years
    for area in areas
      for ecc in ECCs
        ZZZ[year] = sum(EuDemand[fuel,ecc,area,year] for fuel in Fuels)*Conversion[nation,year]/Driver[ecc,area,year]
        CCC[year] = sum(EuDemandRef[fuel,ecc,area,year] for fuel in Fuels)*Conversion[nation,year]/DriverRef[ecc,area,year]
        if ZZZ[year] > 0.0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zEnergyIntensity;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
            UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zEnergyIntensity-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zEnergyIntensity_DtaControl(db)
  data = zEnergyIntensityData(; db)
  (; Nation)= data
  (; NationOutputMap)= data

  @info "zEnergyIntensity_DtaControl"

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      zEnergyIntensity_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
zEnergyIntensity_DtaControl(DB)
end
