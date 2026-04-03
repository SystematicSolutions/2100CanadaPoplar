#
# zeCO2Price.jl - Carbon Tax plus Permit Cost
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

Base.@kwdef struct zeCO2PriceData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  zeCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  zeCO2PriceRef::VariableArray{2} = ReadDisk(RefNameDB, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index (DLESS)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  CDYear::Int = CDTime - ITime + 1
  Conversion::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Area)) # [Area] Units Description

end

function zeCO2Price_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,EndTime,RefNameDB) = data
  (; zeCO2Price,zeCO2PriceRef,Inflation,NationOutputMap) = data
  (; Conversion,UnitsDS,SceName) = data

  if NationOutputMap[nation] != 1
    return
  end

  if BaseSw != 0
    @. zeCO2PriceRef = zeCO2Price
  end

  # Set up conversion factors using inflation data
  years = collect(1:Yr(EndTime))
  for area in Areas
    for year in years
      Conversion[area,year] = Inflation[area,CDYear]
    end
    UnitsDS[area] = " \$/eCO2 Tonnes"
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;;;Units;zData;zInitial")

  areas = findall(ANMap[:,nation] .== 1)

  for area in areas
    for year in years
      ZZZ = zeCO2Price[area,year] * Conversion[area,year]
      CCC = zeCO2PriceRef[area,year] * Conversion[area,year]
      if ZZZ != 0 || CCC != 0
        println(iob,"zeCO2Price;",Year[year],";",AreaDS[area],";",";",CDTime,UnitsDS[area],";",
          @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  areakey = Area[areas[1]]  # Use first area for filename
  filename = "zeCO2Price-$areakey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do file
    write(file, String(take!(iob)))
  end
end

function zeCO2Price_DtaControl(db)
  @info "zeCO2Price_DtaControl"

  data = zeCO2PriceData(; db)
  
  # Process CN and US
  CN = Select(ReadDisk(db, "MainDB/NationKey"),"CN")
  US = Select(ReadDisk(db, "MainDB/NationKey"),"US")
  
  zeCO2Price_DtaRun(data,CN)
  zeCO2Price_DtaRun(data,US)
end
  
if abspath(PROGRAM_FILE) == @__FILE__
  zeCO2Price_DtaControl(DB)
end
