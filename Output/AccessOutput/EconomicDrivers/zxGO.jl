#
# zxGO.jl
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

Base.@kwdef struct zxGOData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  DrSwitch::VariableArray{2} = ReadDisk(db, "MInput/DrSwitch", Yr(2000)) # [ECC,Area,Year]  Economic Driver (Various Units)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  zxGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (2017 $M/Yr)
  zxGORef::VariableArray{3} = ReadDisk(RefNameDB,"MInput/xGO") # [ECC,Area,Year] Gross Output (2017 $M/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zxGO_DtaRun(data,nation)
  (; AreaDS,ECC,ECCDS,ECCs,Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion,EndTime,TOMBaseTime,UnitsDS) = data
  (; zxGO,zxGORef,ZZZ,SceName) = data

  if BaseSw != 0
    zxGORef = zxGO
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  UnitsDS[US]= "M\$/YR"
  UnitsDS[CN]= "Millions of $TOMBaseTime CN\$/Yr"

  for ecc in ECCs
    for area in areas
      for year in years
        ZZZ[year] = zxGO[ecc,area,year]
        CCC[year] = zxGORef[ecc,area,year]
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zxGO;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
            UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zxGO-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zxGO_DtaControl(db)
  data = zxGOData(; db)
  (; Nation)= data

  @info "zxGO_DtaControl"

  nations = Select(Nation,["CN","US"])
  for nation in nations
     zxGO_DtaRun(data,nation)
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zxGO_DtaControl(DB)
end
