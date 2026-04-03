#
# zExpSales.jl
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

Base.@kwdef struct zExpSalesData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  xExpSales::VariableArray{2} = ReadDisk(db,"EGInput/xExpSales") # [Area,Year] Historical Sales to Areas in a different Country (GWh/Yr)
  xExpSalesRef::VariableArray{2} = ReadDisk(RefNameDB,"EGInput/xExpSales") # [Area,Year] Historical Sales to Areas in a different Country (GWh/Yr)
  zExpSales::VariableArray{2} = ReadDisk(db,"EGOutput/ExpSales") #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)
  zExpSalesRef::VariableArray{2} = ReadDisk(RefNameDB,"EGOutput/ExpSales") #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zExpSales_DtaRun(data,nation)
  (; AreaDS,Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime) = data
  (; UnitsDS,zExpSales,zExpSalesRef,xExpSales,xExpSalesRef,ZZZ,SceName) = data

  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw == 0
    years = collect(First:Last)
    for year in years, area in areas
      zExpSalesRef[area,year] = xExpSalesRef[area,year]
    end
  else
    zExpSalesRef .= zExpSales
  end

  years = collect(First:Last)
  for year in years, area in areas
    zExpSales[area,year] = xExpSales[area,year]
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "GWh/Yr"
  UnitsDS[CN] = "GWh"

  for area in areas
    for year in years
      ZZZ[year] = zExpSales[area,year]*Conversion[nation,year]
      CCC[year] = zExpSalesRef[area,year]*Conversion[nation,year]
      if ZZZ[year] != 0 || CCC[year] != 0
        println(iob,"zExpSales;",Year[year],";",AreaDS[area],";",
          UnitsDS[nation],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zExpSales-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zExpSales_DtaControl(db)
  data = zExpSalesData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zExpSales_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zExpSales_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zExpSales_DtaControl(DB)
end
