#
# TOM_DeviceInvestments.jl - Emission Permit Ependitures from E2020 to TOM
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

Base.@kwdef struct TOM_DeviceInvestmentsData
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
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation

  DInv::VariableArray{3} = ReadDisk(db,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  IFMEe::VariableArray{3} = ReadDisk(db,"KOutput/IFMEe") # [ECCTOM,AreaTOM,Year] E2020 Investments in Machinery & Equipment (2017 $M/Yr)
  IFMEinto::VariableArray{3} = ReadDisk(db,"KOutput/IFMEinto") # [ECCTOM,AreaTOM,Year]  Investments in Machinery & Equipment  (2017 $M/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapECCtoTOM") # [ECC,ECCTOM] Map between ECC and ECCTOM
  MapUSECCtoTOM::VariableArray{2} = ReadDisk(db,"KInput/MapUSECCtoTOM") # [ECC,ECCTOM] Map between ECCTOM and ECC
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  SplitECCtoTOMIFME::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOMIFME") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM based on M&E Investments, IFME ($/$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  #
  # Scratch Variables
  #
  DeviceInvestReal::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year))
  DeviceInvestRealintoTOM::VariableArray{3} = zeros(Float32,length(ECCTOM),length(Area),length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function TOM_DeviceInvestments_DtaRun(data,nationkey,areatoms)
  (; Area,Areas,AreaTOM,AreaTOMDS,ECC,ECCDS,ECCs,ECCTOMDS,ECCTOMs,Year) = data
  (; SceName,DInv,IFMEe,IFMEinto,MapAreaTOM,MapECCtoTOM) = data
  (; MapUSECCtoTOM,SecMap,SplitECCtoTOMIFME,xInflation) = data
  (; DeviceInvestReal,DeviceInvestRealintoTOM,ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Device Investments/Fixed Investments in Machinery & Equipment (2017 \$M/Yr).")
  println(iob, " ")

  years = collect(Yr(1985):Final)
  println(iob, "Year;", ";", ";", ";", join(Year[years], ";    "))
  println(iob, " ")


  for year in years, area in Areas, ecc in ECCs
    DeviceInvestReal[ecc,area,year] = DInv[ecc,area,year]/xInflation[area,year]*xInflation[area,Yr(2017)]
  end

  print(iob,"Variable;Area;Sector;Segment")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for areatom in areatoms
    area=Select(Area,AreaTOM[areatom])
    for ecctom in ECCTOMs
      eccs = findall(MapECCtoTOM[ECCs,ecctom] .== 1)
      if !isempty(eccs)
        ecc_single = first(eccs)
        if SecMap[ecc_single] == 2 # Commercial
          print(iob,"DInv;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Commercial")
          for year in years
            ZZZ[year]=sum(DeviceInvestReal[ecc,area,year]*SplitECCtoTOMIFME[ecc,ecctom,areatom,year] for ecc in eccs)
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        elseif SecMap[ecc_single] == 3 # Industrial
          print(iob,"DInv;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Industrial")
          for year in years
            ZZZ[year]=sum(DeviceInvestReal[ecc,area,year]*SplitECCtoTOMIFME[ecc,ecctom,areatom,year] for ecc in eccs)
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        end
        #
        for year in years
          ZZZ[year]=IFMEe[ecctom,areatom,year]
        end
        ecc=first(eccs)
        if SecMap[ecc] == 2 # Commercial
          print(iob,"IFMEe;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Commercial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        elseif SecMap[ecc] == 3 # Industrial
          print(iob,"IFMEe;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Industrial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        end
        for year in years
          ZZZ[year]=IFMEinto[ecctom,areatom,year]
        end
        #
        ecc=first(eccs)
        if SecMap[ecc] == 2 # Commercial
          print(iob,"IFME;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Commercial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        elseif SecMap[ecc] == 3 # Industrial
          print(iob,"IFME;$(AreaTOMDS[areatom]);$(ECCTOMDS[ecctom]);Industrial")
          for year in years
            print(iob,";",@sprintf("%15.6f",ZZZ[year]))
          end
          println(iob)
        end
      end
    end
  end

   
  filename = "TOM_DeviceInvestments-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))  
  end   
end

function TOM_DeviceInvestments_DtaControl(db)
  @info "TOM_DeviceInvestments_DtaControl"
  data = TOM_DeviceInvestmentsData(; db)
  (; AreaTOMs,Nation)= data
  (; MapAreaTOMNation) = data


  CN = Select(Nation,"CN")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,CN] .== 1.0)
  TOM_DeviceInvestments_DtaRun(data,Nation[CN],areatoms)

  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1.0)
  TOM_DeviceInvestments_DtaRun(data,Nation[US],areatoms)
end

if abspath(PROGRAM_FILE) == @__FILE__
TOM_DeviceInvestments_DtaControl(DB)
end

