#
# zxGDPChained.jl
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

Base.@kwdef struct zxGDPChainedData
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
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  zxGDPChained::VariableArray{2} = ReadDisk(db, "MInput/xGDPChained") # [Nation,Year] Chained National GDP(Chained 2017 Million $/Yr)
  zxGDPChainedRef::VariableArray{2} = ReadDisk(RefNameDB, "MInput/xGDPChained") # [Nation,Year] Chained National GDP(Chained 2017 Million $/Yr)
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zxGDPChained_DtaRun(data,nation)
  (; Nation,NationDS,Year) = data
  (; BaseSw,CCC,Conversion,EndTime,TOMBaseTime,TOMBaseYear,UnitsDS) = data
  (; zxGDPChained,zxGDPChainedRef,ZZZ,SceName) = data

  if BaseSw != 0
    zxGDPChainedRef = zxGDPChained
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Nation;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0/1000
  end
  
  UnitsDS[US]= "Chained $TOMBaseTime Million US\$/Yr"
  UnitsDS[CN]= "Chained $TOMBaseTime Billion CN\$/Yr"

  for year in years
    ZZZ[year] = zxGDPChained[nation,year]*Conversion[nation,year]
    CCC[year] = zxGDPChainedRef[nation,year]*Conversion[nation,year]
    if ZZZ[year] != 0 || CCC[year] != 0
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zxGDPChained;",Year[year],";",NationDS[nation],";",
        UnitsDS[nation],";",zData,";",zInitial)
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zxGDPChained-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zxGDPChained_DtaControl(db)
  data = zxGDPChainedData(; db)
  (; Nation)= data
  (; NationOutputMap)= data

  @info "zxGDPChained_DtaControl"

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      zxGDPChained_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zxGDPChained_DtaControl(DB)
end
