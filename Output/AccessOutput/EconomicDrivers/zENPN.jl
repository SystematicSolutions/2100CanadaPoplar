#
# zENPN.jl
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

Base.@kwdef struct zENPNData
  db::String
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Primary Fuel Price ($/mmBtu)
  zENPNRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/ENPN") # [Fuel,Nation,Year] Primary Fuel Price ($/mmBtu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zENPN_DtaRun(data,nation)
  (; Fuels,FuelDS,Nation,NationDS,Year) = data
  (; BaseSw,CDTime,CDYear,EndTime,ExchangeRateNation) = data
  (; InflationNation,zENPN,zENPNRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ,SceName) = data

  if BaseSw != 0
    zENPNRef = zENPN
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  CDYear = max(CDYear,1)
  
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")

  UnitsDS[US] = " US\$/mmBtu"
  UnitsDS[CN] = " US\$/mmBtu"
  
  for year in years
    Conversion[US,year] = InflationNation[US,CDYear]
    Conversion[CN,year] = InflationNation[CN,year]/ExchangeRateNation[CN,year]/
      InflationNation[US,year]*InflationNation[US,CDYear]
  end  

  for fuel in Fuels
    for year in years
      ZZZ[year] = zENPN[fuel,nation,year]*Conversion[nation,year]
      CCC[year] = zENPNRef[fuel,nation,year]*Conversion[nation,year]
      if (ZZZ[year] != 0) || (CCC[year] != 0)
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zENPN;",Year[year],";",NationDS[nation],";",FuelDS[fuel],";",
          CDTime,UnitsDS[nation],";",zData,";",zInitial)
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zENPN-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zENPN_DtaControl(db)
  data = zENPNData(; db)
  (; Nation)= data
  (; NationOutputMap)= data

  @info "zENPN_DtaControl"

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      zENPN_DtaRun(data,nation)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
zENPN_DtaControl(DB)
end
