#
# zCreditsGenerated.jl
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

Base.@kwdef struct zCreditsGeneratedData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zCreditsGenerated::VariableArray{2} = ReadDisk(db, "SOutput/CreditsGenerated") # [Area,Year] CFR Credits Generated (Tonnes/Yr)
  zCreditsGeneratedRef::VariableArray{2} = ReadDisk(RefNameDB, "SOutput/CreditsGenerated") # [Area,Year] CFR Credits Generated (Tonnes/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zCreditsGenerated_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Year) = data
  (; ANMap,BaseSw,Conversion,EndTime,UnitsDS,zCreditsGenerated,zCreditsGeneratedRef,SceName) = data

  if BaseSw != 0
    @. zCreditsGeneratedRef = zCreditsGenerated
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "Tonnes/Yr"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "Tonnes/Yr"
  end

    for area in areas
      for year in years
        ZZZ = zCreditsGenerated[area,year]*Conversion[nation,year]
        CCC = zCreditsGeneratedRef[area,year]*Conversion[nation,year]
        if ZZZ != 0 || CCC != 0
          println(iob,"zCreditsGenerated;",Year[year],";",AreaDS[area],";",UnitsDS[nation],";",
            @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zCreditsGenerated-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zCreditsGenerated_DtaControl(db)
  data = zCreditsGeneratedData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zCreditsGenerated_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zCreditsGenerated_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
 zCreditsGenerated_DtaControl(DB)
end
