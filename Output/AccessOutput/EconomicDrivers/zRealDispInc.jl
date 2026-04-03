#
# zRealDispInc.jl
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

Base.@kwdef struct zRealDispIncData
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
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  MacroSwitch::Vector{String} = ReadDisk(db, "MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  zRealDispInc::VariableArray{2} = ReadDisk(db,"MInput/RealDispInc") # [Area,Year] Real Disposable Income (Million Real CN$)
  zRealDispIncRef::VariableArray{2} = ReadDisk(RefNameDB,"MInput/RealDispInc") # [Area,Year] Real Disposable Income (Million Real CN$)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zRealDispInc_DtaRun(data,nation)
  (; AreaDS,Nation,NationDS,Year) = data
  (; ANMap,BaseSw,CCC,CDTime,CDYear,Conversion,ConversionRef,EndTime,MacroSwitch,UnitsDS) = data
  (; MacroSwitch,TOMBaseTime,UnitsDS) = data
  (; InflationNation,InflationNationRef,TOMBaseTime,TOMBaseYear) = data
  (; zRealDispInc,zRealDispIncRef,ZZZ,SceName) = data

  if BaseSw != 0
    zRealDispIncRef = zRealDispInc
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  CN = Select(Nation,"CN")

  if MacroSwitch[CN] == "TOM"
    for year in years
      Conversion[CN,year] = 1.0/InflationNation[CN,TOMBaseYear]*InflationNation[CN,CDYear]
      ConversionRef[CN,year] = 1.0/InflationNationRef[CN,TOMBaseYear]*InflationNationRef[CN,CDYear]
    end
  end
    
  UnitsDS[CN]= "$TOMBaseTime Million Real CN\$"

  for year in years
    ZZZ[year] = sum(zRealDispInc[area,year]*Conversion[nation,year] for area in areas)
    CCC[year] = sum(zRealDispIncRef[area,year]*Conversion[nation,year]  for area in areas)
    if ZZZ[year] != 0 || CCC[year] != 0
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zRealDispInc;",Year[year],";",NationDS[nation],";",
        UnitsDS[nation],";",zData,";",zInitial)
    end
    for area in areas
      ZZZ[year] = zRealDispInc[area,year]*Conversion[nation,year]
      CCC[year] = zRealDispIncRef[area,year]*Conversion[nation,year]
      if ZZZ[year] != 0 || CCC[year] != 0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zRealDispInc;",Year[year],";",AreaDS[area],";",
          UnitsDS[nation],";",zData,";",zInitial)
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zRealDispInc-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zRealDispInc_DtaControl(db)
  data = zRealDispIncData(; db)
  (; Nation)= data

  @info "zRealDispInc_DtaControl"

  nations = Select(Nation,"CN")
  for nation in nations
    zRealDispInc_DtaRun(data,nation)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
  zRealDispInc_DtaControl(DB)
end
