#
# zRPPAProd.jl
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

Base.@kwdef struct zRPPAProdData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
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
  zRPPAProd::VariableArray{2} = ReadDisk(db,"SpOutput/RPPAProd") # [Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  zRPPAProdRef::VariableArray{2} = ReadDisk(RefNameDB,"SpOutput/RPPAProd") # [Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zRPPAProd_DtaRun(data,nation)
  (; AreaDS,Nation,Year,SceName) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime) = data
  (; UnitsDS,zRPPAProd,zRPPAProdRef,ZZZ) = data

  if BaseSw != 0
    zRPPAProdRef .= zRPPAProd
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.054615*1000
  end

  UnitsDS[US] = "TBtu/Yr"
  UnitsDS[CN] = "TJ/Yr"

  for area in areas
    for year in years
      ZZZ[year] = zRPPAProd[area,year]*Conversion[nation,year]
      CCC[year] = zRPPAProdRef[area,year]*Conversion[nation,year]
      if ZZZ[year] != 0 || CCC[year] != 0
        println(iob,"zRPPAProd;",Year[year],";",AreaDS[area],";",
          UnitsDS[nation],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zRPPAProd-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zRPPAProd_DtaControl(db)
  data = zRPPAProdData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zRPPAProd_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zRPPAProd_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zRPPAProd_DtaControl(DB)
end
