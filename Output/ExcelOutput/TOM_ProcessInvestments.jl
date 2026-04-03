#
# TOM_ProcessInvestments.jl
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

Base.@kwdef struct TOM_ProcessInvestmentsData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
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
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  IFC::VariableArray{3} = ReadDisk(db,"KOutput/IFC") # [ECCTOM,AreaTOM,Year] Investments in Construction (2017 $M/Yr)
  IFCe::VariableArray{3} = ReadDisk(db,"KOutput/IFCe") # [ECCTOM,AreaTOM,Year] E2020 Fixed Investments (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  PInv::VariableArray{3} = ReadDisk(db,"SOutput/PInv") # [ECC,Area,Year] Process Investments in Reference Case (M$/Yr)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFC") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM based on Construction Investments, IFC ($/$)
  SplitECCtoTOMIFC::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFC") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM based on Construction Investments, IFC ($/$)
  TOMBaseTime::Int = ReadDisk(db, "KInput/TOMBaseTime")[1] # Base Year for TOM Economic Model (Year)
  TOMBaseYear::Int = ReadDisk(db, "KInput/TOMBaseYear")[1] # Base Year for TOM Economic Model (Index)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function TOM_ProcessInvestments_DtaRun(data,nationkey,areatoms)
  (; Area,AreaTOM,AreaTOMDS,ECC,ECCDS,ECCs,ECCTOMDS,ECCTOMs) = data
  (; ECCTOM,ECCTOMs,SceName,Year) = data
  (; IFC,IFCe,IsActiveToECCTOM,MapAreaTOM,MapECCtoTOM,PInv) = data
  (; SecMap,SplitECCtoTOM,SplitECCtoTOMIFC,TOMBaseTime,TOMBaseYear) = data
  (; xInflation,ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Process Investments/Fixed Investments in Construction ($TOMBaseTime \$M/Yr).")
  println(iob, " ")

  years = collect(Yr(1985):Final)
  println(iob, "Year;", ";", ";", ";", join(Year[years], ";    "))
  println(iob, " ")

  #
  print(iob,"Variable;Area;Sector;Segment")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for areatom in areatoms
    area = Select(Area,AreaTOM[areatom])
    for ecctom in ECCTOMs
      eccs = findall(MapECCtoTOM[ECCs,ecctom] .== 1)
      if !isempty(eccs)
        ecc_single=first(eccs)
        if SecMap[ecc_single] == 2 # Commercial
          print(iob,"PInvMapped;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Commercial")
          for year in years
            ZZZ[year] = sum(PInv[ecc,area,year]*SplitECCtoTOMIFC[ecc,ecctom,areatom,year]/
              xInflation[area,year]*xInflation[area,TOMBaseYear] for ecc in eccs)
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        elseif SecMap[ecc_single] == 3 # Industrial
          print(iob,"PInvMapped;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Industrial")
          for year in years
            ZZZ[year] = sum(PInv[ecc,area,year]*SplitECCtoTOMIFC[ecc,ecctom,areatom,year]/
              xInflation[area,year]*xInflation[area,TOMBaseYear] for ecc in eccs)
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        end
      end
    end
  end

  for areatom in areatoms
    area = Select(Area,AreaTOM[areatom])
    for ecctom in ECCTOMs
      eccs = findall(MapECCtoTOM[ECCs,ecctom] .== 1)
      if !isempty(eccs)
        for year in years
          ZZZ[year] = IFCe[ecctom,areatom,year]
        end
        ecc=first(eccs)
        if SecMap[ecc] == 2 # Commercial
          print(iob,"IFCe;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Commercial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        elseif SecMap[ecc] == 3 # Industrial
          print(iob,"IFCe;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Industrial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        end
        for year in years
          ZZZ[year] = IFC[ecctom,areatom,year]
        end
        ecc = first(eccs)
        if SecMap[ecc] == 2 # Commercial
          print(iob,"IFC;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Commercial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        elseif SecMap[ecc] == 3 # Industrial
          print(iob,"IFC;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Industrial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        end
      end
    end
  end
   
  filename = "TOM_ProcessInvestments-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))  
  end   
end

function TOM_ProcessInvestments_DtaControl(db)
  data = TOM_ProcessInvestmentsData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data

  @info "TOM_ProcessInvestments_DtaControl"

  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  TOM_ProcessInvestments_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  TOM_ProcessInvestments_DtaRun(data,Nation[US],areatoms)
end

if abspath(PROGRAM_FILE) == @__FILE__
  TOM_ProcessInvestments_DtaControl(DB)
end

