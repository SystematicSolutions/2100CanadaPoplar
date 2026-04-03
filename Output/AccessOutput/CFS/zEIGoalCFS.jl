#
# zEIGoalCFS.jl
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

Base.@kwdef struct zEIGoalCFSData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
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
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zEIGoalCFS::VariableArray{4} = ReadDisk(db, "SInput/EIGoalCFS") # [Fuel,ES,Area,Year] Emission Intensity Goal for CFS (Tonnes/TBtu)
  zEIGoalCFSRef::VariableArray{4} = ReadDisk(RefNameDB, "SInput/EIGoalCFS") # [Fuel,ES,Area,Year] Emission Intensity Goal for CFS (Tonnes/TBtu)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  KJBtu::Float32 = 1.054615 # Kilo Joule per BTU
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zEIGoalCFS_DtaRun(data,nation)
  (; Area,AreaDS,Areas,ES,ESDS,ESs,Fuel,FuelDS,Fuels,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Year,YearDS) = data
  (; ANMap,BaseSw,KJBtu,Conversion,EndTime,UnitsDS,zEIGoalCFS,zEIGoalCFSRef,SceName) = data

  if BaseSw != 0
    @. zEIGoalCFSRef = zEIGoalCFS
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  for year in years
    Conversion[US,year] = 1/KJBtu/1000
    UnitsDS[US] = "gCO2e/MJ"
    Conversion[CN,year] = 1/KJBtu/1000
    UnitsDS[CN] = "gCO2e/MJ"
  end

  for fuel in Fuels
    for es in ESs
      for area in areas
        for year in years
          ZZZ = zEIGoalCFS[fuel,es,area,year]*Conversion[nation,year]
          CCC = zEIGoalCFSRef[fuel,es,area,year]*Conversion[nation,year]
          if ZZZ != 0 || CCC != 0
            println(iob,"zEIGoalCFS;",YearDS[year],";",AreaDS[area],";",ESDS[es],";",FuelDS[fuel],";",UnitsDS[nation],";",
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
  filename = "zEIGoalCFS-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zEIGoalCFS_DtaControl(db)
  data = zEIGoalCFSData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zEIGoalCFS_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zEIGoalCFS_DtaRun(data,nation)
    end
  end
end


if abspath(PROGRAM_FILE) == @__FILE__
zEIGoalCFS_DtaControl(DB)
end

