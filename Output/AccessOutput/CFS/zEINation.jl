#
# zEINation.jl
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

  
Base.@kwdef struct zEINationData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EIType::SetArray = ReadDisk(db, "MainDB/EITypeKey")
  EITypeDS::SetArray = ReadDisk(db, "MainDB/EITypeDS")
  EITypes::Vector{Int} = collect(Select(EIType))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  zEINation::VariableArray{4} = ReadDisk(db, "SOutput/EINation") # [EIType,Fuel,Nation,Year] Emission Intensity (Tonnes/TBtu)
  zEINationRef::VariableArray{4} = ReadDisk(RefNameDB, "SOutput/EINation") # [EIType,Fuel,Nation,Year] Emission Intensity (Tonnes/TBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zEINation_DtaRun(data,nation)
  (; Area,AreaDS,Areas,EIType,EITypeDS,EITypes,Fuel,FuelDS,Fuels,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Year) = data
  (; ANMap,BaseSw,Conversion,EndTime,UnitsDS,zEINation,zEINationRef,SceName) = data

  if BaseSw != 0
    @. zEINationRef = zEINation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "Tonnes/TBtu"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "Tonnes/TBtu"
  end

  for fuel in Fuels
    for n in Nations
      if n == nation
        for year in years
          # Sum over EIType dimension
          ZZZ = sum(zEINation[eitype,fuel,n,year] for eitype in EITypes) * Conversion[n,year]
          CCC = sum(zEINationRef[eitype,fuel,n,year] for eitype in EITypes) * Conversion[n,year]
          if ZZZ != 0 || CCC != 0
            println(iob,"zEINation;",Year[year],";",NationDS[n],";",FuelDS[fuel],";",UnitsDS[n],";",
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
  filename = "zEINation-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zEINation_DtaControl(db)
  data = zEINationData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zEINation_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zEINation_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
zEINation_DtaControl(DB)
end
