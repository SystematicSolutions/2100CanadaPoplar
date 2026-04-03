#
# zConsumptionArea.jl
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

Base.@kwdef struct zConsumptionAreaData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
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
  MacroSwitch::Vector{String} = ReadDisk(db, "MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  zC::VariableArray{2} = ReadDisk(db, "KOutput/C") # [AreaTOM,Year] Personal Consumption from TOM (2017 $M/Yr)
  zCRef::VariableArray{2} = ReadDisk(RefNameDB, "KOutput/C") # [AreaTOM,Year] Personal Consumption from TOM (2017 $M/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(NationTOM),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(NationTOM)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zConsumptionArea_DtaRun(data,nation,nationtom)
  (; AreaTOM,AreaTOMs,AreaDS) = data
  (; Nation,NationTOM,Year) = data
  (; BaseSw,CCC,Conversion,MapAreaTOM,MacroSwitch,UnitsDS,SceName) = data
  (; zC,zCRef,ZZZ) = data

  if BaseSw != 0
    zCRef = zC
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  years = collect(1:Final)
  US = Select(NationTOM,"US")
  CN = Select(NationTOM,"CN")
  for year in years
    Conversion[US,year] = 1.0/1000
    Conversion[CN,year] = 1.0/1000
  end
  
  UnitsDS[US]= "Billion 2017 US\$/Yr"
  UnitsDS[CN]= "Billion 2017 CN\$/Yr"

  if NationTOM[nationtom] == "CN"
    areatoms = Select(AreaTOM,(from="AB",to="YT"))
  elseif NationTOM[nationtom] == "US"
    areatoms = Select(AreaTOM,(from="NEng",to="CA"))
  end

  for areatom in areatoms
    area = first(findall(MapAreaTOM[:,areatom] .== 1))
    for year in years
      ZZZ[year] = zC[areatom,year]*Conversion[nationtom,year]
      CCC[year] = zCRef[areatom,year]*Conversion[nationtom,year]
      if ZZZ[year] != 0 || CCC[year] != 0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zC;",Year[year],";",AreaDS[area],";",
          UnitsDS[nationtom],";",zData,";",zInitial)
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationtomkey = NationTOM[nationtom]
  filename = "zConsumptionArea-$nationtomkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zConsumptionArea_DtaControl(db)
  data = zConsumptionAreaData(; db)
  (; Nation,NationTOM,NationTOMs)= data
  
  @info "zConsumptionArea_DtaControl"

  for nationtom in NationTOMs
    nations = findall(Nation[:] .== NationTOM[nationtom])
    if nations != []
      for nation in nations
        zConsumptionArea_DtaRun(data,nation,nationtom)
      end
    end
  end
end
  
if abspath(PROGRAM_FILE) == @__FILE__
  zConsumptionArea_DtaControl(DB)
end

