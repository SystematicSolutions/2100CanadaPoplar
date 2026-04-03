#
# TOM_EnergyIntensityReport.jl
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

Base.@kwdef struct TOM_EnergyIntensityReportData
  db::String
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

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
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  EInt::VariableArray{4} = ReadDisk(db, "KOutput/EInt") # [FuelTOM,ECCTOM,AreaTOM,Year] TOM Energy Intensity (mmBtu/2017$M)
  EIntE::VariableArray{4} = ReadDisk(db, "KOutput/EIntE") # [FuelTOM,ECCTOM,AreaTOM,Year] Energy Intensity (mmBtu/2017$M)
  ENe::VariableArray{4} = ReadDisk(db, "KOutput/ENe") # [FuelTOM,ECCTOM,AreaTOM,Year]  E2020 to TOM Energy Demands (TBtu/Yr)
  GrossDemands::VariableArray{4} = ReadDisk(db, "KOutput/GrossDemands") # [Fuel,ECC,Area,Year]  Gross Energy Demands (TBtu/Yr)
  GYAdjust::VariableArray{3} = ReadDisk(db, "KOutput/GYAdjust") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Outputs (2017 $M/Yr)
  GYinto::VariableArray{3} = ReadDisk(db, "KOutput/GYinto") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Inputs (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapfromECCTOM::VariableArray{2} = ReadDisk(db, "KInput/MapfromECCTOM") # [ECC,ECCTOM] Map from ECCTOM to ECC
  MapECCtoTOM::VariableArray{2} = ReadDisk(db, "KInput/MapECCtoTOM") # [ECC,ECCtoTOM] Map between ECC and ECCTOM
  MapFuelTOM::VariableArray{2} = ReadDisk(db, "KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db, "KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC into ECCTOM ($/$)
  xGO::VariableArray{3} = ReadDisk(db, "MInput/xGO") # [ECC,Area,Year] Gross Output (2017 M$/Yr)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32, length(Year))
end

function TOM_EnergyIntensityReport_DtaRun(data,TitleKey,TitleName,area,areatom)
  (; SceName,Area,AreaDS,Areas,AreaTOM,AreaTOMDS,AreaTOMs,ECC,ECCDS,ECCs) = data
  (; ECCTOM,ECCTOMDS,ECCTOMs) = data
  (; Fuel,FuelDS,Fuels,FuelTOM,FuelTOMs,FuelTOMDS,ToTOMVariable,Year,Years) = data
  (; EInt,EIntE,ENe,GrossDemands,GYAdjust,GYinto,IsActiveToECCTOM,MapECCtoTOM) = data
  (; MapfromECCTOM,MapFuelTOM,SplitECCtoTOM,xGO) = data
  (; ZZZ) = data

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "Summary of Energy Intensities from E2020 to TOM.")
  println(iob, " ")

  years = collect(Yr(2010):Final)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  totomvariable = Select(ToTOMVariable,"EIntE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

  for ecctom in ecctoms
    if (sum(EIntE[fueltom,ecctom,areatom,year] for year in years, fueltom in FuelTOMs) != 0)
      println(iob, "********** $TitleName - $(ECCTOMDS[ecctom]) **********")
      println(iob, " ")
      eccs = findall(MapECCtoTOM[ECCs,ecctom] .== 1)
      if isempty(eccs)
        # println(iob,"No ECCs match ECCTOM $(ECCTOM[ecctom])")
        # println(iob)
      else
        print(iob, "$TitleName, $(ECCTOMDS[ecctom]) Energy Intensity Mapped to TOM (mmBtu/2017\$M);")
        for year in years
          print(iob, ";", Year[year])
        end
        println(iob)
        for fueltom in FuelTOMs
          print(iob, "EIntE;$(FuelTOMDS[fueltom])")
          for year in years
            ZZZ[year] = EIntE[fueltom,ecctom,areatom,year]
            print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
          end
          println(iob)
        end
        println(iob, " ")

        print(iob, "$(ECCTOMDS[ecctom]) Gross Output (2017\$M);")
        for year in years
          print(iob, ";", Year[year])
        end
        println(iob)
        print(iob, "GYinto;$(ECCTOMDS[ecctom])")
        for year in years
          ZZZ[year] = GYinto[ecctom,areatom,year]
          print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
        end
        println(iob)
        for ecc in eccs
          print(iob, "  xGO;$(ECCDS[ecc])")
          for year in years
            ZZZ[year] = xGO[ecc, area, year]
            print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
          end
          println(iob)
          ecctoms = findall(MapfromECCTOM[ecc,ECCTOMs] .== 1)
          if !isempty(ecctoms)
            for ecctom in ecctoms
              print(iob, "    GYAdjust;$(ECCTOMDS[ecctom])")
              for year in years
                ZZZ[year] = GYAdjust[ecctom, areatom, year]
                print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
              end
              println(iob)
            end
          end
        end
        println(iob, " ")

        print(iob, "$TitleName, $(ECCTOMDS[ecctom]) Energy Demand Mapped to TOM (TBtu);")
        for year in years
          print(iob, ";", Year[year])
        end
        println(iob)
        print(iob, "ENe;Total")
        for year in years
          ZZZ[year] = sum(ENe[fueltom, ecctom, areatom, year] for fueltom in FuelTOMs)
          print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
        end
        println(iob)
        for fueltom in FuelTOMs
          print(iob, "ENe;$(FuelTOMDS[fueltom])")
          for year in years
            ZZZ[year] = ENe[fueltom,ecctom,areatom,year]
            print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
          end
          println(iob)
        end
        println(iob, " ")

        print(iob, "$TitleName, $(ECCTOMDS[ecctom]) Energy Demand by E2020 Category (TBtu);")
        for year in years
          print(iob, ";", Year[year])
        end
        println(iob)
        for ecc in eccs
          println(iob, "From $(ECCDS[ecc]):")
          print(iob, "  SplitECCtoTOM;Fraction of Demand from $(ECCDS[ecc]) to $(ECCTOMDS[ecctom])")
          for year in years
            ZZZ[year] = SplitECCtoTOM[ecc,ecctom,areatom,year]
            print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
          end
          println(iob)
          print(iob, "  GrossDemands;Total")
          for year in years
            ZZZ[year] = sum(GrossDemands[fuel, ecc, area, year] for fuel in Fuels)
            print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
          end
          println(iob)
          for fueltom in FuelTOMs
            fuels = findall(MapFuelTOM[Fuels, fueltom] .== 1)
            if !isempty(fuels)
              if sum(GrossDemands[fuel,ecc,area,year] for year in years, fuel in fuels) > 0
                for fuel in fuels
                  if sum(GrossDemands[fuel,ecc,area,year] for year in years) > 0
                    print(iob, "  GrossDemands;$(FuelDS[fuel])")
                    for year in years
                      ZZZ[year] = GrossDemands[fuel, ecc, area, year]
                      print(iob, ";", @sprintf("%15.6f", ZZZ[year]))
                    end
                    println(iob)
                  end
                end
              end
            end
          end
          println(iob, " ")
        end
      end
    end
  end

  filename = "TOM_EnergyIntensityReport-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TOM_EnergyIntensityReport_DtaControl(db)
  @info "TOM_EnergyIntensityReport_DtaControl"
  data = TOM_EnergyIntensityReportData(; db)
  (; Area, AreaDS, Areas, AreaTOM, AreaTOMs) = data

  for area in Areas
    areatoms = findall(AreaTOM[AreaTOMs] .== Area[area])
    if !isempty(areatoms)
      areatom = first(areatoms)
      TOM_EnergyIntensityReport_DtaRun(data, Area[area], AreaDS[area], area, areatom)
    end
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
TOM_EnergyIntensityReport_DtaControl(DB)
end


