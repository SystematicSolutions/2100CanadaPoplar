#
# TOM_E2020IndustrySplits.jl
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

Base.@kwdef struct TOM_E2020IndustrySplitsData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db, "KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db, "KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db, "KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db, "KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db, "KInput/FuelTOMKey")
  FuelTOMDS::SetArray = ReadDisk(db, "KInput/FuelTOMDS")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db, "KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM ($/$)

  #
  # Scratch Variables
  #
  AAA = zeros(Float32, length(Area))
end

function TOM_E2020IndustrySplits_DtaRun(data)
  (; Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs,ECC,ECCDS,ECCs) = data
  (; Nation,ECCTOM,ECCTOMDS,ECCTOMs,Year,Years) = data
  (; ANMap,SceName,SplitECCtoTOM) = data
  (; AAA) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Summary of Industry Splits Used to Map ENERGY 2100 to TOM.")
  println(iob, " ")
  println(iob, "Year; ; $(Year[Future])")
  println(iob, " ")

  CN=Select(Nation,"CN")
  areas=findall(ANMap[Areas,CN] .== 1)

  println(iob, "Split ECC into ECCTOM (\$/\$) for Year $(Year[Future])")
  print(iob, "Variable;ENERGY 2100 Sector;TOM Sector")
  for area in areas
    print(iob, ";", AreaDS[area])
  end
  println(iob)
  for ecc in ECCs
    for ecctom in ECCTOMs
      if sum(SplitECCtoTOM[ecc,ecctom,areatom,Future] for areatom in AreaTOMs) > 0
        print(iob, "SplitECCtoTOM;$(ECCDS[ecc]);$(ECCTOMDS[ecctom])")
        for area in areas
          areatom = first(Select(AreaTOM,Area[area]))
          AAA[area] = SplitECCtoTOM[ecc,ecctom,areatom,Future]
          print(iob, ";",@sprintf("%.4f",AAA[area]))
        end
        println(iob)
      end
    end
  end

  filename = "TOM_E2020IndustrySplits-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TOM_E2020IndustrySplits_DtaControl(db)
  @info "TOM_E2020IndustrySplits_DtaControl"
  data = TOM_E2020IndustrySplitsData(; db)

  TOM_E2020IndustrySplits_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
TOM_E2020IndustrySplits_DtaControl(DB)
end

