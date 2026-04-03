#
# zExchangeRateNation.jl
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

Base.@kwdef struct zExchangeRateNationData
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
  zExchangeRateNation::VariableArray{2} = ReadDisk(db, "MInput/xExchangeRateNation") # [Nation,Year] Inflation Index ($/$)
  zExchangeRateNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MInput/xExchangeRateNation") # [Nation,Year] Inflation Index ($/$)
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zExchangeRateNation_DtaRun(data,nation)
  (; Nation,NationDS,Year) = data
  (; BaseSw,CCC,Conversion,EndTime,UnitsDS) = data
  (; zExchangeRateNation,zExchangeRateNationRef,ZZZ,SceName) = data

  if BaseSw != 0
    zExchangeRateNationRef = zExchangeRateNation
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
  
  UnitsDS[US]= "US\$/US\$"
  UnitsDS[CN]= "CN\$/US\$"

  for year in years
    ZZZ[year] = zExchangeRateNation[nation,year]*Conversion[nation,year]
    CCC[year] = zExchangeRateNationRef[nation,year]*Conversion[nation,year]
    if ZZZ[year] != 0 || CCC[year] != 0
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zExchangeRateNation;",Year[year],";",NationDS[nation],";",
        UnitsDS[nation],";",zData,";",zInitial)
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zExchangeRateNation-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zExchangeRateNation_DtaControl(db)
  data = zExchangeRateNationData(; db)
  (; Nation)= data
  (; NationOutputMap)= data

  @info "zExchangeRateNation_DtaControl"

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      zExchangeRateNation_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
zExchangeRateNation_DtaControl(DB)
end
