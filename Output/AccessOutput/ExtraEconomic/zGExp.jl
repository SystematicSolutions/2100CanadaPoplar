#
# zGExp.jl
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

Base.@kwdef struct zGExpData
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
  GExp::VariableArray{2} = ReadDisk(db, "KOutput/GExp") # [NationTOM,Year] Government expenditure (Nominal $M)
  GExpRef::VariableArray{2} = ReadDisk(RefNameDB, "KOutput/GExp") # [NationTOM,Year] Government expenditure (Nominal $M)
  PGDP::VariableArray{2} = ReadDisk(db, "KOutput/PGDP") # [NationTOM,Year] Implicit Price Deflator: GDP at market prices (Index)
  PGDPRef::VariableArray{2} = ReadDisk(RefNameDB, "KOutput/PGDP") # [NationTOM,Year] Implicit Price Deflator: GDP at market prices (Index)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(NationTOM),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(NationTOM)) # [Nation] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zGExp_DtaRun(data,nation,nationtom)
  (; Nation,NationDS,NationTOM,Year) = data
  (; BaseSw,CCC,Conversion,UnitsDS) = data
  (; GExp,GExpRef,PGDP,PGDPRef,ZZZ,SceName) = data

  if BaseSw != 0
    GExpRef = GExp
    PGDPRef = PGDP
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Nation;Units;zData;zInitial")

  years = collect(1:Final)
  US = Select(NationTOM,"US")
  CN = Select(NationTOM,"CN")
  for year in years
    Conversion[US,year] = 1
    Conversion[CN,year] = 1.0/(1000*(PGDP[CN,year]/100))
  end
  
  UnitsDS[US]= "2017 \$Billion"
  UnitsDS[CN]= "2017 \$Billion"

  for year in years
    ZZZ[year] = GExp[nationtom,year]/(1000*(PGDP[nationtom,year]/100))
    CCC[year] = GExpRef[nationtom,year]/(1000*(PGDPRef[nationtom,year]/100))
    if ZZZ[year] != 0 || CCC[year] != 0
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"GExp;",Year[year],";",NationDS[nation],";",
        UnitsDS[nationtom],";",zData,";",zInitial)
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationtomkey = NationTOM[nationtom]
  filename = "zGExp-$nationtomkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zGExp_DtaControl(db)
  data = zGExpData(; db)
  (; Nation,NationTOM,NationTOMs)= data
  
  @info "zGExp_DtaControl"

  for nationtom in NationTOMs
    nations = findall(Nation[:] .== NationTOM[nationtom])
    if nations != []
      for nation in nations
        zGExp_DtaRun(data,nation,nationtom)
      end
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zGExp_DtaControl(DB)
end
