#
# zGRP.jl
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

Base.@kwdef struct zGRPData
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
  MacroSwitch::Vector{String} = ReadDisk(db, "MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  zGRP::VariableArray{2} = ReadDisk(db,"MOutput/GRP") # [Area,Year] Gross Regional Product (M$/Yr)
  zGRPRef::VariableArray{2} = ReadDisk(RefNameDB,"MOutput/GRP") # [Area,Year] Gross Regional Product (M$/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zGRP_DtaRun(data,nation)
  (; AreaDS) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,MacroSwitch,TOMBaseTime,UnitsDS) = data
  (; zGRP,zGRPRef,ZZZ,SceName) = data

  if BaseSw != 0
    zGRPRef = zGRP
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0/1000
  end
  
  if MacroSwitch[US] == "AEO"
    UnitsDS[US]= "$TOMBaseTime Million US\$/Yr"
  elseif MacroSwitch[US] == "TOM"
    UnitsDS[US]= "$TOMBaseTime Million US\$/Yr"
  end
  if MacroSwitch[CN] == "TOM"
    UnitsDS[CN]= "Billions of $TOMBaseTime CN\$/Yr"
  end

  for area in areas
    for year in years
      ZZZ[year] = zGRP[area,year]*Conversion[nation,year]
      CCC[year] = zGRPRef[area,year]*Conversion[nation,year]
      if ZZZ[year] != 0 || CCC[year] != 0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zGRP;",Year[year],";",AreaDS[area],";",
          UnitsDS[nation],";",zData,";",zInitial)
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zGRP-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zGRP_DtaControl(db)
  data = zGRPData(; db)
  (; Nation)= data
  (; NationOutputMap)= data

  @info "zGRP_DtaControl"

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      zGRP_DtaRun(data,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
zGRP_DtaControl(DB)
end
