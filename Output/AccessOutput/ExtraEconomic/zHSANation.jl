#
# zHSANation.jl
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

Base.@kwdef struct zHSANationData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCResTOM::SetArray = ReadDisk(db,"KInput/ECCResTOMKey")
  ECCResTOMs::Vector{Int} = collect(Select(ECCResTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  NationTOM::SetArray = ReadDisk(db,"KInput/NationTOMKey")
  NationTOMDS::SetArray = ReadDisk(db, "KInput/NationTOMDS")
  NationTOMs::Vector{Int} = collect(Select(NationTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  HSA::VariableArray{3} = ReadDisk(db, "KOutput/HSA") # [AreaTOM,Year] Housing Stock (Units)
  HSARef::VariableArray{3} = ReadDisk(RefNameDB, "KOutput/HSA") # [AreaTOM,Year] Housing Stock (Units)
  MapECCResTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCResTOM") # [ECC,ECCResTOM] Map between ECCResTOM and ECC

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(NationTOM),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(NationTOM)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zHSANation_DtaRun(data,nation,nationtom)
  (; AreaTOM,AreaTOMs,AreaDS,ECCDS,ECCResTOM,ECCResTOMs) = data
  (; NationDS,NationTOM,Year) = data
  (; BaseSw,CCC,Conversion,MapAreaTOM,MapECCResTOM,UnitsDS) = data
  (; HSA,HSARef,ZZZ,SceName) = data

  if BaseSw != 0
    HSARef = HSA
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Final)
  US = Select(NationTOM,"US")
  CN = Select(NationTOM,"CN")
  for year in years
    Conversion[US,year] = 1.0/1000
    Conversion[CN,year] = 1.0/1000
  end
  
  UnitsDS[US]= "Thousand Units"
  UnitsDS[CN]= "Thousand Units"

  if NationTOM[nationtom] == "CN"
    areatoms = Select(AreaTOM,(from="AB",to="YT"))
  elseif NationTOM[nationtom] == "US"
    areatoms = Select(AreaTOM,(from="NEng",to="CA"))
  end

  for eccrestom in ECCResTOMs
    ecc = first(findall(MapECCResTOM[:,eccrestom] .== 1))
    for year in years
      ZZZ[year] = sum(HSA[eccrestom,areatom,year]*Conversion[nationtom,year] for areatom in areatoms)
      CCC[year] = sum(HSARef[eccrestom,areatom,year]*Conversion[nationtom,year] for areatom in areatoms)
      if ZZZ[year] != 0 || CCC[year] != 0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"HSA;",Year[year],";",NationDS[nation],";",ECCDS[ecc],";",
          UnitsDS[nationtom],";",zData,";",zInitial)
      end
    end
  end

  for year in years
    ZZZ[year] = sum(HSA[eccrestom,areatom,year]*Conversion[nationtom,year] for eccrestom in ECCResTOMs,areatom in areatoms)
    CCC[year] = sum(HSARef[eccrestom,areatom,year]*Conversion[nationtom,year] for eccrestom in ECCResTOMs,areatom in areatoms)
    if ZZZ[year] != 0 || CCC[year] != 0
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"HSA;",Year[year],";",NationDS[nation],";","Total;",
        UnitsDS[nationtom],";",zData,";",zInitial)
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationtomkey = NationTOM[nationtom]
  filename = "zHSANation-$nationtomkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zHSANation_DtaControl(db)
  
  data = zHSANationData(; db)
  
  (; Nation,NationTOM,NationTOMs)= data
  
  @info "zHSANation_DtaControl"

  for nationtom in NationTOMs
    nations = findall(Nation[:] .== NationTOM[nationtom])
    if nations != []
      for nation in nations
        zHSANation_DtaRun(data,nation,nationtom)
      end
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zHSANation_DtaControl(DB)
end
