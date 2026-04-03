#
# zPOCXSimple.jl
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

Base.@kwdef struct zPOCXSimpleData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPOCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") #[FuelEP,Plant,Poll,Area,Year]  Marginal Pollution Coefficients (Tonnes/TBtu)
  zPOCXRef::VariableArray{5} = ReadDisk(RefNameDB,"EGInput/POCX") #[FuelEP,Plant,Poll,Area,Year]  Marginal Pollution Coefficients (Tonnes/TBtu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zPOCXSimple_DtaRun(data,nation)
  (; Area,Areas,AreaDS,FuelEPDS,FuelEPs,Nation,NationDS,Plant,Plants,PlantDS) = data
  (; Poll,PollDS,Year,SceName) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime) = data
  (; UnitsDS,zPOCX,zPOCXRef,ZZZ) = data

  if BaseSw != 0
    zPOCXRef .= zPOCX
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Pollutant;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Tonnes/TBtu"
  UnitsDS[CN] = "Tonnes/TBtu"
  
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
  plant = Select(Plant,"OGCT")
  
  #
  # Value is same across Area so just use Area(1) or ON - Ian 11/07/25
  #
  #area = Select(Area,"ON")
  areas = findall(ANMap[:,CN] .== 1)
  
  for poll in polls
    for fuelep in FuelEPs
      for area in areas
        for year in years
          ZZZ[year] = zPOCX[fuelep,plant,poll,area,year]*Conversion[nation,year]
          CCC[year] = zPOCXRef[fuelep,plant,poll,area,year]*Conversion[nation,year]
          if ZZZ[year] != 0 || CCC[year] != 0
            println(iob,"zPOCXSimple;",Year[year],";",AreaDS[area],";",
            PollDS[poll],";",FuelEPDS[fuelep],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zPOCXSimple-GHG-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zPOCXSimple_DtaControl(db)
  data = zPOCXSimpleData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zPOCXSimple_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPOCXSimple_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zPOCXSimple_DtaControl(DB)
end
