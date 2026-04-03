#
# zCreditsNeeded.jl
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

Base.@kwdef struct zCreditsNeededData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  Fuel::SetArray   = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
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
  zCreditsNeeded::VariableArray{4} = ReadDisk(db, "SOutput/CreditsNeeded") # [Fuel,ECC,Area,Year] Emission Intensity Credits Needed (Tonnes/Yr)
  zCreditsNeededRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/CreditsNeeded") # [Fuel,ECC,Area,Year] Emission Intensity Credits Needed (Tonnes/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name


  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zCreditsNeeded_DtaRun(data,nation)
  (; Area,ECC,ECCDS,ECCs,Fuels,Fuel,FuelDS,AreaDS,Areas,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Year) = data
  (; ANMap,BaseSw,Conversion,EndTime,UnitsDS,zCreditsNeeded,zCreditsNeededRef,SceName) = data

  if BaseSw != 0
    @. zCreditsNeededRef = zCreditsNeeded
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Fuel;Sector;Units;zData;zInitial")

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

  for fuel in Fuels
    for ecc in ECCs
      for area in areas
        for year in years
          ZZZ = zCreditsNeeded[fuel,ecc,area,year]*Conversion[nation,year]
          CCC = zCreditsNeededRef[fuel,ecc,area,year]*Conversion[nation,year]
          if ZZZ != 0 || CCC != 0
            println(iob,"zCreditsNeeded;",Year[year],";",AreaDS[area],";",
              FuelDS[fuel],";",ECCDS[ecc],";",UnitsDS[nation],";",
              @sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zCreditsNeeded-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zCreditsNeeded_DtaControl(db)
  data = zCreditsNeededData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zCreditsNeeded_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zCreditsNeeded_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
zCreditsNeeded_DtaControl(DB)
end
