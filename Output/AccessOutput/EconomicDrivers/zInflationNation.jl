#
# zInflationNation.jl
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

Base.@kwdef struct zInflationNationData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zInflationNation::VariableArray{2} = ReadDisk(db, "MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  zInflationNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zInflationNation_DtaRun(data,nation)
  (; Nation,NationDS,Year) = data
  (; BaseSw,CCC,Conversion,EndTime,UnitsDS) = data
  (; zInflationNation,zInflationNationRef,ZZZ,SceName) = data

  if BaseSw != 0
    zInflationNationRef = zInflationNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Nation;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end
  
  UnitsDS[US]= "DLESS"
  UnitsDS[CN]= "Index"

  for year in years
    ZZZ[year] = zInflationNation[nation,year]*Conversion[nation,year]
    CCC[year] = zInflationNationRef[nation,year]*Conversion[nation,year]
    if ZZZ[year] != 0 || CCC[year] != 0
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zInflationNation;",Year[year],";",NationDS[nation],";",
        UnitsDS[nation],";",zData,";",zInitial)
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zInflationNation-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zInflationNation_DtaControl(db)
  data = zInflationNationData(; db)
  (; Nation)= data
  (; NationOutputMap)= data

  @info "zInflationNation_DtaControl"

  nations = Select(Nation,["CN","US"])
  for nation in nations
    # if NationOutputMap[nation] == 1
        zInflationNation_DtaRun(data,nation)
    # end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
zInflationNation_DtaControl(DB)
end
