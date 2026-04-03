#
# zGCFA.jl
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

Base.@kwdef struct zGCFAData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")  
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zGCFA::VariableArray{3} = ReadDisk(db, "EOutput/GCFA") # [Fuel,Area,Year] Generation Capacity (MW)
  zGCFARef::VariableArray{3} = ReadDisk(RefNameDB, "EOutput/GCFA") # [Fuel,Area,Year] Generation Capacity (MW)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zGCFA_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations) = data
  (; Fuels,FuelDS,Year) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,UnitsDS,zGCFA,zGCFARef,ZZZ,SceName) = data

  if BaseSw != 0
    @. zGCFARef = zGCFA
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "MW"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "MW"
  end

  for fuel in Fuels
    for area in areas
      for year in years
        ZZZ[year] = zGCFA[fuel,area,year]*Conversion[nation,year]
        CCC[year] = zGCFARef[fuel,area,year]*Conversion[nation,year]
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zGCFA;",Year[year],";",AreaDS[area],";",
            FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zGCFA-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zGCFA_DtaControl(db)
  data = zGCFAData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zGCFA_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zGCFA_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zGCFA_DtaControl(DB)
end
