#
# TOM_GrossOutputDemandCheck.jl
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
Base.@kwdef struct TOM_GrossOutputDemandCheckData
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GY::VariableArray{3} = ReadDisk(db,"KOutput/GY") # [ECCTOM,AreaTOM,Year] Gross Output (2017 $M/Yr)
  GYAdjust::VariableArray{3} = ReadDisk(db,"KOutput/GYAdjust") # [ECCTOM,AreaTOM,Year] Gross Output from TOM, Adjusted (2017 CN$M/Yr)
  GrossDemands::VariableArray{4} = ReadDisk(db,"KOutput/GrossDemands") # [Fuel,ECC,Area,Year]  Gross Energy Demands (TBtu/Yr)
  MapfromECCTOM::VariableArray{2} = ReadDisk(db, "KInput/MapfromECCTOM") # [ECC,ECCTOM] Map between ECCTOM and ECC
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (2017 M$/Yr)

  # Scratch Variables
  DmdTotal = zeros(Float32, length(Year))
  GYTotal = zeros(Float32, length(Year))
  # TotYearsDmd
  # TotYearsGO
  # GOFirst Type=Real(15,8)
  # DmdFirst Type=Real(15,8)

  ZZZ = zeros(Float32, length(Year))
end

function TOM_GrossOutputDemandCheck_DtaRun(data, TitleKey, nation, areas)
  (; SceName,Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs,ECC,ECCDS) = data
  (; ECCs,ECCTOM,ECCTOMDS,ECCTOMs,Fuel,FuelDS,Fuels,Nation) = data
  (; NationDS,Nations,Year,Years) = data
  (; ANMap,GY,GYAdjust,GrossDemands,MapfromECCTOM) = data
  (; DmdTotal,GYTotal,xGO,ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleKey; is the nation being output.")
  println(iob, "TOM Gross Output Compared to Demand.")
  println(iob, " ")

  years = collect(Zero:Final)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  eccs1 = Select(ECC,(from="Wholesale",to="OtherCommercial"))
  eccs2 = Select(ECC,(from="Food",to="NonMetalMining"))
  eccs3 = Select(ECC,(from="CoalMining",to="OnFarmFuelUse"))
  eccs = union(eccs1,eccs2,eccs3)

  for area in areas
    areatom = Select(AreaTOM,Area[area])
    for ecc in eccs
      ecctoms = findall(MapfromECCTOM[ecc,ECCTOMs] .== 1)
      if !isempty(ecctoms)
        if (sum(GrossDemands[fuel,ecc,area,year] for year in years, fuel in Fuels) != 0) &&
           (sum(xGO[ecc,area,year] for year in years) != 0)

          #
          # Write out industries with 1985 gross output = 0, and demand is non-zero
          #
          for year in years
            GYTotal[year] = sum(GY[ecctom,areatom,year] for ecctom in ecctoms)
            DmdTotal[year] = sum(GrossDemands[fuel,ecc,area,year] for fuel in Fuels)
          end
          if (GYTotal[Zero] > 0.0) && (DmdTotal[Zero] > 0.0)
            println(iob, "$(AreaDS[area]), $(ECCDS[ecc]) - No Issues")
          elseif (GYTotal[Zero] == 0.0) && (DmdTotal[Zero] > 0.000001)
            print(iob, "$(AreaDS[area]) $(ECCDS[ecc]);")
            for year in years
              print(iob, ";", Year[year])
            end
            println(iob)
            print(iob, "xGO;2017\$M/Yr")
            for year in years
              @finite_math ZZZ[year] = xGO[ecc,area,year]
              print(iob, ";", @sprintf("%15.8f", ZZZ[year]))
            end
            println(iob)
            print(iob, "GYTotal;$(ECCDS[ecc])")
            for year in years
              @finite_math ZZZ[year] = GYTotal[year]
              print(iob, ";", @sprintf("%15.8f", ZZZ[year]))
            end
            println(iob)
            for ecctom in ecctoms
              print(iob, "GY;$(ECCTOMDS[ecctom])")
              for year in years
                @finite_math ZZZ[year] = GY[ecctom,areatom,year]
                print(iob, ";", @sprintf("%15.8f", ZZZ[year]))
              end
              println(iob)
            end
            print(iob, "GrossDemands;TBtu/Yr")
            for year in years
              @finite_math ZZZ[year] = sum(GrossDemands[fuel,ecc,area,year] for fuel in Fuels)
              print(iob, ";", @sprintf("%15.8f", ZZZ[year]))
            end
            println(iob)
          end
        end
        println(iob)
      end
    end
  end

  filename = "GrossOutputDemandCheck-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TOM_GrossOutputDemandCheck_DtaControl(db)
  @info "TOM_GrossOutputDemandCheck_DtaControl"
  data = TOM_GrossOutputDemandCheckData(; db)
  (; ANMap, Areas, Nation, Nations) = data

  nations=Select(Nation,["CN","US"])
  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    TOM_GrossOutputDemandCheck_DtaRun(data,Nation[nation],nation,areas)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
TOM_GrossOutputDemandCheck_DtaControl(DB)
end

