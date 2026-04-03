#
# zConsumptionNation.jl
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

Base.@kwdef struct zConsumptionNationData
  db::String

  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
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
  zCNation::VariableArray{2} = ReadDisk(db, "KOutput/CNation") # [NationTOM,Year] Personal Consumption from TOM (2017 $M/Yr)
  zCNationRef::VariableArray{2} = ReadDisk(RefNameDB, "KOutput/CNation") # [NationTOM,Year] Personal Consumption from TOM (2017 $M/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(NationTOM),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(NationTOM)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zConsumptionNation_DtaRun(data,nation,nationtom)
  (; Nation,NationDS,NationTOM,Year) = data
  (; BaseSw,CCC,Conversion,MacroSwitch,UnitsDS) = data
  (; zCNation,zCNationRef,ZZZ,SceName) = data

  if BaseSw != 0
    zCNationRef = zCNation
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Nation;Units;zData;zInitial")

  years = collect(1:Final)
  US = Select(NationTOM,"US")
  CN = Select(NationTOM,"CN")
  for year in years
    Conversion[US,year] = 1.0/1000
    Conversion[CN,year] = 1.0/1000
  end
  
  UnitsDS[US]= "Billion 2017 US\$/Yr"
  UnitsDS[CN]= "Billion 2017 CN\$/Yr"

  for year in years
    ZZZ[year] = zCNation[nationtom,year]*Conversion[nationtom,year]
    CCC[year] = zCNationRef[nationtom,year]*Conversion[nationtom,year]
    if ZZZ[year] != 0 || CCC[year] != 0
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zCNation;",Year[year],";",NationDS[nation],";",
        UnitsDS[nationtom],";",zData,";",zInitial)
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationtomkey = NationTOM[nationtom]
  filename = "zConsumptionNation-$nationtomkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zConsumptionNation_DtaControl(db)
  data = zConsumptionNationData(; db)
  (; Nation,NationTOM,NationTOMs)= data
  
  @info "zConsumptionNation_DtaControl"

  for nationtom in NationTOMs
    nations = findall(Nation[:] .== NationTOM[nationtom])
    if nations != []
      for nation in nations
        zConsumptionNation_DtaRun(data,nation,nationtom)
      end
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zConsumptionNation_DtaControl(DB)
end
