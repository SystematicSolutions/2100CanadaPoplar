#
# TOM_ProcessInvestmentsReport.jl
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


Base.@kwdef struct TOM_ProcessInvestmentsReportData
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  IFC::VariableArray{3} = ReadDisk(db,"KOutput/IFC") # [ECCTOM,AreaTOM,Year] Investments in Construction (2017 $M/Yr)
  IFCe::VariableArray{3} = ReadDisk(db,"KOutput/IFCe") # [ECCTOM,AreaTOM,Year] E2020 Fixed Investments (2017 $M/Yr)
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map between ECC to ECCTOM
  PInv::VariableArray{3} = ReadDisk(db,"SOutput/PInv") # [ECC,Area,Year] Process Investments in Reference Case (M$/Yr)
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM ($/$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  ZZZ = zeros(Float32, length(Year))
end

function TOM_ProcessInvestmentsReport_DtaRun(data, TitleKey, TitleName, area, areatom)
  (; SceName,Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs,ECC,ECCDS,ECCs) = data
  (; ECCTOM,ECCTOMDS,ECCTOMs) = data
  (; Nation,NationDS,Nations,Year,Years) = data
  (; IFC,IFCe,MapECCtoTOM,PInv,SplitECCtoTOM,xInflation) = data
  (; ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "Process Investments/Fixed Investments in Construction (2017 \$M/Yr).")
  println(iob, " ")

  years = collect(Yr(1985):Final)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  eccs=Select(ECC,(from="Wholesale",to="AnimalProduction"))
  for ecc in eccs
    ecctoms = findall(MapECCtoTOM[ecc,ECCTOMs] .== 1)
    if !isempty(ecctoms)
      print(iob, "$TitleName $(ECCDS[ecc]) Process Investments (2017\$M/Yr);")
      for year in years
        print(iob, ";", Year[year])
      end
      println(iob)
      print(iob, "PInv;$(ECCDS[ecc])")
      for year in years
        @finite_math ZZZ[year] = PInv[ecc,area,year]/xInflation[area,year]*xInflation[area,Yr(2017)]
        print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
      end
      println(iob)
      for ecctom in ecctoms
        print(iob, "SplitECCtoTOM;$(ECCTOMDS[ecctom])")
        for year in years
          @finite_math ZZZ[year] = SplitECCtoTOM[ecc,ecctom,areatom,year]
          print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
        end
        println(iob)
        print(iob, "IFCe;$(ECCTOMDS[ecctom])")
        for year in years
          @finite_math ZZZ[year] = IFCe[ecctom,areatom,year]
          print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
        end
        println(iob)
        print(iob, "IFC;$(ECCTOMDS[ecctom])")
        for year in years
          @finite_math ZZZ[year] = IFC[ecctom,areatom,year]
          print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end
  end

  filename = "TOM_ProcessInvestmentsReport-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TOM_ProcessInvestmentsReport_DtaControl(db)
  @info "TOM_ProcessInvestmentsReport_DtaControl"
  data = TOM_ProcessInvestmentsReportData(; db)
  (; ANMap, Area, AreaDS, Areas, AreaTOM, AreaTOMs, Nation) = data

  CN=Select(Nation,"CN")
  areas=findall(ANMap[Areas,CN] .== 1)
  for area in areas
    areatoms = findall(AreaTOM[AreaTOMs] .== Area[area])
    if !isempty(areatoms)
      areatom = first(areatoms)
      TOM_ProcessInvestmentsReport_DtaRun(data, Area[area], AreaDS[area], area, areatom)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
TOM_ProcessInvestmentsReport_DtaControl(DB)
end

