#
# zUOMC.jl
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

Base.@kwdef struct zUOMCData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") #[Nation,Year]  Inflation Index ($/$)
  zUOMC::VariableArray{3} = ReadDisk(db,"EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs (Real $/MWh)
  zUOMCRef::VariableArray{3} = ReadDisk(RefNameDB,"EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs (Real $/MWh)
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

function zUOMC_DtaRun(data,nation)
  (; Area,AreaDS,Areas,Nation,NationDS,Nations) = data
  (; Plant,PlantDS,Plants,Year,SceName) = data
  (; ANMap,BaseSw,CDTime,CDYear,CCC,Conversion,EndTime,InflationNation,UnitsDS,zUOMC,zUOMCRef,ZZZ) = data

  if BaseSw != 0
    @. zUOMCRef = zUOMC
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = InflationNation[US,CDYear]
    UnitsDS[US] = "$CDTime US\$/MWh"
    Conversion[CN,year] = InflationNation[CN,CDYear]
    UnitsDS[CN] = "$CDTime CN\$/MWh"
  end

  for plant in Plants
    for area in areas
      for year in years
        ZZZ[year] = zUOMC[plant,area,year]*Conversion[nation,year]
        CCC[year] = zUOMCRef[plant,area,year]*Conversion[nation,year]
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zUOMC;",Year[year],";",AreaDS[area],";",
            PlantDS[plant],";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zUOMC-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zUOMC_DtaControl(db)
  data = zUOMCData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zUOMC_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zUOMC_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zUOMC_DtaControl(DB)
end
