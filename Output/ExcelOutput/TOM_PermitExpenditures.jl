#
# TOM_PermitExpenditures.jl
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
Base.@kwdef struct TOM_PermitExpendituresData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db, "KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db, "KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  NationTOM::SetArray = ReadDisk(db,"KInput/NationTOMKey")
  NationTOMs::Vector{Int} = collect(Select(NationTOM))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EPermit::VariableArray{3} = ReadDisk(db,"KOutput/EPermit") # [ECCTOM,AreaTOM,Year] TOM Cost of Emissions Permits ($M/Yr)
  EPermitE::VariableArray{3} = ReadDisk(db,"KOutput/EPermitE") # [ECCTOM,AreaTOM,Year] Cost of Emissions Permits ($M/Yr)
  EUPExp::VariableArray{2} = ReadDisk(db,"SOutput/EUPExp") #[Area,Year]  Electric Utility Emission Charges (M$/Yr)
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  PExp::VariableArray{4} = ReadDisk(db,"SOutput/PExp") # [ECC,Poll,Area,Year] Permits Expenditures (M$/Yr)
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCtoTOM,AreaTOM,Year] Split ECC into ECCtoTOM ($/$)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32, length(Year))
end

function TOM_PermitExpenditures_DtaRun(data, TitleKey, TitleName, area, areatom)
  (; SceName,Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs,ECC,ECCDS,ECCs) = data
  (; ECCTOM,ECCTOMDS,Nation,NationDS) = data
  (; Nations,NationTOM,NationTOMs,Poll,PollDS,Polls,Year,Years) = data
  (; ANMap,EPermit,EPermitE,EUPExp,MapECCtoTOM,PExp,SplitECCtoTOM) = data
  (; ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "Summary of E2020 Permit Expenditures Mapped to TOM for $TitleName")
  println(iob, " ")

  years = collect(Yr(2020):Final)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  ecctoms = Select(ECCTOM,!=("UtilityGen"))
  for ecctom in ecctoms
    if sum(EPermitE[ecctom,areatom,year] for year in years) != 0
      print(iob, "$TitleName $(ECCTOMDS[ecctom]) Cost of Emissions Permits (\$M/Yr);")
      for year in years
        print(iob, ";", Year[year])
      end
      println(iob)
      eccs = findall(MapECCtoTOM[ECCs,ecctom] .== 1)
      if !isempty(eccs)
        print(iob, "EPermit (TOM Baseline);$(ECCTOMDS[ecctom])")
        for year in years
          ZZZ[year] = EPermit[ecctom,areatom,year]
          print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
        end
        println(iob)
        print(iob, "EPermitE (Sent to TOM);$(ECCTOMDS[ecctom])")
        for year in years
          ZZZ[year] = EPermitE[ecctom,areatom,year]
          print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
        end
        println(iob)
        for ecc in eccs
          if sum(SplitECCtoTOM[ecc,ecctom,areatom,year] for year in years) > 0
            print(iob, "PExp;$(ECCDS[ecc])")
            for year in years
              ZZZ[year] = sum(PExp[ecc,poll,area,year] for poll in Polls)
              print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
            end
            println(iob)
            print(iob, "SplitECCtoTOM;$(ECCDS[ecc])")
            for year in years
              ZZZ[year] = SplitECCtoTOM[ecc,ecctom,areatom,year]
              print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
            end
            println(iob)
          end
        end
      end
      println(iob)
    end
  end

  #
  # Electric Utility permit expenditures are from EUPExp rather than PExp
  #
  ecctom = Select(ECCTOM,"UtilityGen")
  print(iob, "$TitleName $(ECCTOMDS[ecctom]) Cost of Emissions Permits (\$M/Yr);")
  for year in years
    print(iob, ";", Year[year])
  end
  println(iob)
  print(iob, "EPermitE (Sent to TOM);$(ECCTOMDS[ecctom])")
  for year in years
    ZZZ[year] = EPermitE[ecctom,areatom,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  print(iob, "EUPExp;$(ECCTOMDS[ecctom])")
  for year in years
    ZZZ[year] = EUPExp[area,year]
    print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)

  filename = "TOM_PermitExpenditures-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TOM_PermitExpenditures_DtaControl(db)
  @info "TOM_PermitExpenditures_DtaControl"
  data = TOM_PermitExpendituresData(; db)
  (; ANMap, Area, AreaDS, Areas, AreaTOM, AreaTOMs, Nation) = data

  CN=Select(Nation,"CN")
  areas=findall(ANMap[Areas,CN] .== 1)
  for area in areas
    areatoms = findall(AreaTOM[AreaTOMs] .== Area[area])
    if !isempty(areatoms)
      areatom = first(areatoms)
      TOM_PermitExpenditures_DtaRun(data, Area[area], AreaDS[area], area, areatom)
    end
  end

  US=Select(Nation,"US")
  areas=findall(ANMap[Areas,US] .== 1)
  for area in areas
    areatoms = findall(AreaTOM[AreaTOMs] .== Area[area])
    if !isempty(areatoms)
      areatom = first(areatoms)
      TOM_PermitExpenditures_DtaRun(data, Area[area], AreaDS[area], area, areatom)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
TOM_PermitExpenditures_DtaControl(DB)
end
