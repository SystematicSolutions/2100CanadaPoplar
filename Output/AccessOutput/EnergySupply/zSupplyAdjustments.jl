#
# zSupplyAdjustments.jl
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

Base.@kwdef struct zSupplyAdjustmentsData
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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zSupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpOutput/SupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)
  zSupplyAdjustmentsRef::VariableArray{3} = ReadDisk(RefNameDB,"SpOutput/SupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zSupplyAdjustments_DtaRun(data,nation)
  (; FuelEPDS,FuelEPs) = data
  (; Nation,NationDS,Year,SceName) = data
  (; BaseSw,CCC,Conversion,EndTime) = data
  (; UnitsDS,zSupplyAdjustments,zSupplyAdjustmentsRef,ZZZ) = data

  if BaseSw != 0
    zSupplyAdjustmentsRef .= zSupplyAdjustments
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.054615
  end

  UnitsDS[US] = "TBtu/Yr"
  UnitsDS[CN] = "PJ/Yr"

  for fuelep in FuelEPs
    for year in years
      ZZZ[year] = zSupplyAdjustments[fuelep,nation,year]*Conversion[nation,year]
      CCC[year] = zSupplyAdjustmentsRef[fuelep,nation,year]*Conversion[nation,year]
      if ZZZ[year] != 0 || CCC[year] != 0
        println(iob,"zSupplyAdjustments;",Year[year],";",NationDS[nation],";",
          FuelEPDS[fuelep],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ[year]),";",@sprintf("%.6E",CCC[year]))
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zSupplyAdjustments-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zSupplyAdjustments_DtaControl(db)
  data = zSupplyAdjustmentsData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zSupplyAdjustments_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zSupplyAdjustments_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zSupplyAdjustments_DtaControl(DB)
end
