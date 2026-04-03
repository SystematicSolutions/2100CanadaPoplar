#
# zCPIndex.jl - Consumer Price Index
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

Base.@kwdef struct zCPIndexData
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  CPIndex::VariableArray{2} = ReadDisk(db, "MInput/CPIndex") # [Area,Year] Consumer Price Index (1992=100)
  CPIndexRef::VariableArray{2} = ReadDisk(RefNameDB, "MInput/CPIndex") # [Area,Year] Consumer Price Index (1992=100)
  CPIndexNation::VariableArray{2} = ReadDisk(db, "MInput/CPIndexNation") # [Nation,Year] Consumer Price Index (1992=100)
  CPIndexNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MInput/CPIndexNation") # [Nation,Year] Consumer Price Index (1992=100)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zCPIndex_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations,Year) = data
  (; ANMap,BaseSw,EndTime,RefNameDB) = data
  (; CPIndex,CPIndexRef,CPIndexNation,CPIndexNationRef,NationOutputMap) = data
  (; Conversion,UnitsDS,SceName) = data

  if NationOutputMap[nation] != 1
    return
  end

  if BaseSw != 0
    @. CPIndexRef = CPIndex
    @. CPIndexNationRef = CPIndexNation
  end

  # Set up units
  CN = Select(Nation,"CN")
  UnitsDS[CN] = "2002=100"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  areas = findall(ANMap[:,nation] .== 1)
  years = collect(1:Yr(EndTime))

  for year in years
    # National level output
    ZZZ = CPIndexNation[nation,year]
    CCC = CPIndexNationRef[nation,year]
    if ZZZ != 0 || CCC != 0
      println(iob,"zCPIndexNation;",Year[year],";",NationDS[nation],";",UnitsDS[nation],";",
        @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
    end

    # Area level outputs
    for area in areas
      ZZZ = CPIndex[area,year]
      CCC = CPIndexRef[area,year]
      if ZZZ != 0 || CCC != 0
        println(iob,"zCPIndex;",Year[year],";",AreaDS[area],";",UnitsDS[nation],";",
          @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zCPIndex-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do file
    write(file, String(take!(iob)))
  end
end

function zCPIndex_DtaControl(db)
  @info "zCPIndex_DtaControl"

  data = zCPIndexData(; db)
  
  # Process CN and US
  CN = Select(ReadDisk(db, "MainDB/NationKey"),"CN")
  US = Select(ReadDisk(db, "MainDB/NationKey"),"US")
  
  zCPIndex_DtaRun(data,CN)
  zCPIndex_DtaRun(data,US)
end
  
if abspath(PROGRAM_FILE) == @__FILE__
  zCPIndex_DtaControl(DB)
end
