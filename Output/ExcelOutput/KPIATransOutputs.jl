#
# KPIATransOutputs.jl
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

Base.@kwdef struct KPIATransData
  db::String
  Input = "RInput"
  Outpt = "ROutput"
  CalDB = "RCalDB"

  Area   = ReadDisk(db, "MainDB/AreaKey")
  AreaKey  = ReadDisk(db, "MainDB/AreaKey")
  
  EC     = ReadDisk(db,"$Input/ECKey")
  ECDS   = ReadDisk(db,"$Input/ECDS")  
  ECC    = ReadDisk(db,"MainDB/ECCKey")
  ECCDS  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey = ReadDisk(db,"MainDB/ECCKey")
  
  Enduse = ReadDisk(db, "$Input/EnduseDS")
  Fuel   = ReadDisk(db, "MainDB/FuelDS")
  FuelEP = ReadDisk(db, "MainDB/FuelEPDS")
  Poll   = ReadDisk(db, "MainDB/PollDS")
  SceName = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech   = ReadDisk(db, "$Input/TechDS")
  Year   = ReadDisk(db, "MainDB/YearDS")

  DmFracMin::VariableArray{6} = ReadDisk(db, "$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db, "$Input/xDmFrac") # [:Enduse, :Fuel, :Tech, :EC, :Area, :Year], Demand Fuel/Tech Fraction (Btu/Btu)
end

function KPIATrans_DtaRun(data, area, ec)
  (; SceName,Year, Area, AreaKey, EC, ECDS, ECC, ECCKey, Enduse, Fuel, FuelEP, Poll, Tech) = data
  (; DmFracMin, xDmFrac) = data

  AreaName = Area[area]
  ECName = ECDS[ec]
  ecc = Select(ECC,EC[ec])
  fuels = Select(Fuel, ["Gasoline", "Ethanol", "Diesel", "Biodiesel"])
  techs = Select(Tech, ["LDVGasoline","LDVHybrid","LDVFuelCell","LDTGasoline","LDTHybrid",
                        "LDTFuelCell","Motorcycle","BusGasoline","HDV2B3Gasoline",
                        "HDV45Gasoline","HDV67Gasoline","HDV8Gasoline","OffRoad",
                        "LDVDiesel","LDTDiesel","BusDiesel","MarineLight","HDV2B3Diesel",
                        "HDV45Diesel","HDV67Diesel","HDV8Diesel","TrainDiesel","OffRoad"])

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file was produced by KPIATrans_DtaRun.jl")
  println(iob, " ")

  # year = Select(Year, (from = "2010", to = "2050"))
  years = collect(Yr(2010):Yr(2050))
  println(iob, "Year;", ";", join(Year[years], ";"))
  println(iob, " ")

  for enduse in Select(Enduse)
    for tech in techs
      print(iob, AreaName," ",ECName," ",Enduse[enduse]," ",Tech[tech]," Demand Fuel/Tech Fraction Minimum (Btu/Btu);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob, ";")
      for fuel in fuels
        for year in years
          ZZZ[year] = DmFracMin[enduse, fuel, tech, ec, area, year]
        end
        print(iob, "DmFracMin;", Fuel[fuel])
        for year in years
          print(iob, @sprintf("%12.4f;", ZZZ[year]))
        end
        println(iob)
      end
      println(iob, " ")
      print(iob, AreaName," ",ECName," ",Enduse[enduse]," ",Tech[tech]," Demand Fuel/Tech Fraction (Btu/Btu);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob, ";")
      for fuel in fuels
        for year in years
          ZZZ[year] = xDmFrac[enduse, fuel, tech, ec, area, year]
        end
        print(iob, "xDmFrac;", Fuel[fuel])
        for year in years
          print(iob, @sprintf("%12.4f;", ZZZ[year]))
        end
        println(iob)
      end
      println(iob, " ")
    end
  end

  filename = "KPIATransOutputs-$(AreaKey[area])-$(ECCKey[ecc])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function KPIATransOutputs_DtaControl(db)
  @info "KPIATransOutputs_DtaControl"
  data = KPIATransData(; db)
  Area = data.Area
  EC = data.EC
  areas = Select(Area, ["ON","MB","SK","AB","BC","QC","PE","NS","NB"])
  for ec in ecs
    for area in areas
      KPIATrans_DtaRun(data, area, ec)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
KPIATransOutputs_DtaControl(DB)
end
