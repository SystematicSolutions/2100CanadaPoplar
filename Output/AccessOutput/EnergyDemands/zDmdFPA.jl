#
# zDmdFPA.jl
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

Base.@kwdef struct zDmdFPAData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zDmdFPA::VariableArray{4} = ReadDisk(db,"EGOutput/DmdFPA") #[Fuel,Plant,Area,Year)  Energy Demands (TBtu/Yr)
  zDmdFPARef::VariableArray{4} = ReadDisk(RefNameDB,"EGOutput/DmdFPA") #[Fuel,Plant,Area,Year)  Energy Demands (TBtu/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray{1} = zeros(Float32,length(Year))
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))
end

function zDmdFPA_DtaRun(data,nation)
  (; AreaDS,FuelDS,Fuels) = data
  (; Nation,Plant,PlantDS,Plants,Year) = data
  (; ANMap,CCC,Conversion,EndTime,UnitsDS,SceName) = data
  (; zDmdFPA,zDmdFPARef,ZZZ) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Plant;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "TBtu/Yr"
    Conversion[CN,year] = 1.054615*1000
    UnitsDS[CN] = "TJ/Yr"
  end

  for fuel in Fuels
    for plant in Plants
      for area in areas
        for year in years
          ZZZ[year] = zDmdFPA[fuel,plant,area,year]*Conversion[nation,year]
          CCC[year] = zDmdFPARef[fuel,plant,area,year]*Conversion[nation,year]
          if (ZZZ[year] > 0.000001) || (ZZZ[year] < -0.000001) || (CCC[year] > 0.000001) || (CCC[year] < -0.000001)
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zDmdFPA;",Year[year],";",AreaDS[area],";",PlantDS[plant],";",
              FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zDmdFPA-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDmdFPA_DtaControl(db)
  data = zDmdFPAData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zDmdFPA_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDmdFPA_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zDmdFPA_DtaControl(DB)
end
