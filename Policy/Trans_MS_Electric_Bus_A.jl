#
# Trans_MS_Electric_Bus_A.jl
#
# 100% electric buses by 2040, Liberal Party Platform
#

using EnergyModel

module Trans_MS_Electric_Bus_A

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
import ..EnergyModel: E2020Folder,OutputFolder,rm_dir_contents

using Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TransMSElectricBusAData
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
  DDD::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Variable for Displaying Outputs
  BusMSOld::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Bus Market Share Old, Before Shift to Electric (Driver/Driver)
  ElectricGoal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Expanding Transit Fractional Goal (Driver/Driver)
  ICEBusMSOld::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] ICE Market Share Old, Before Shift to Electric (Driver/Driver)
  MSFTarget::VariableArray{3} = zeros(Float32,length(Tech),length(Area),length(Year)) # [Tech,Area,Year] Target Market Share for Policy Vehicles (Driver/Driver)
end

function TransPolicyBus(db)
  data = TransMSElectricBusAData(; db)
  (; CalDB) = data
  (; Area,AreaDS,EC,ECDS,Enduse,EnduseDS,Enduses,Nation,Tech,TechDS,Year,Years) = data
  (; ANMap,BusMSOld,ElectricGoal,ICEBusMSOld,MSFTarget,xMMSF) = data
  (; DDD) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  Passenger = Select(EC,"Passenger")
  Carriage = Select(Enduse,"Carriage")

  #
  # Electric Goal is 100% electric buses by 2040
  #
  for year in Years
    ElectricGoal[year] = 0
  end
  years = collect(Yr(2040):Final)
  for year in Years
    ElectricGoal[year] = 1.0
  end
  years = collect(Yr(2023):Yr(2039))
  for year in years
    ElectricGoal[year] = ElectricGoal[year-1]+(ElectricGoal[Yr(2040)]-
      ElectricGoal[Yr(2022)])/(Yr(2040)-Yr(2022))
  end

  years = collect(Yr(2023):Final)
  techs = Select(Tech,(from="BusGasoline",to="BusFuelCell"))
  for area in areas, year in years
    BusMSOld[area,year] = sum(xMMSF[Carriage,tech,Passenger,area,year] for tech in techs)
  end
  for area in areas, tech in techs, year in years
    MSFTarget[tech,area,year] = xMMSF[Carriage,tech,Passenger,area,year]
  end

  techs = Select(Tech,["BusGasoline","BusDiesel","BusPropane","BusNaturalGas"])
  for area in areas, year in years
    ICEBusMSOld[area,year] = sum(xMMSF[Carriage,tech,Passenger,area,year] for tech in techs)
  end
  techs = Select(Tech,(from="BusGasoline",to="BusFuelCell"))
  BusElectric  = Select(Tech,"BusElectric")
  for area in areas, year in years
    if BusMSOld[area,year]*ElectricGoal[year] > xMMSF[Carriage,BusElectric,Passenger,area,year]
      MSFTarget[BusElectric,area,year] = BusMSOld[area,year]*ElectricGoal[year]
    end
  end

  for area in areas, year in years
    if BusMSOld[area,year]*ElectricGoal[year] > xMMSF[Carriage,BusElectric,Passenger,area,year]
      if ICEBusMSOld[area,year] > 0
        techs = Select(Tech,["BusGasoline","BusDiesel","BusPropane","BusNaturalGas"])
        for tech in techs
          MSFTarget[tech,area,year] = (BusMSOld[area,year]-MSFTarget[BusElectric,area,year])*
            (xMMSF[Carriage,tech,Passenger,area,year]/ICEBusMSOld[area,year])
        end
        techs = Select(Tech,(from="BusGasoline",to="BusFuelCell"))
      end
    end
  end
  techs = Select(Tech,(from="BusGasoline",to="BusFuelCell"))
  for area in areas, tech in techs, year in years
    MSFTarget[tech,area,year] = xMMSF[Carriage,tech,Passenger,area,year]
  end
  WriteDisk(db,"$CalDB/xMMSF",xMMSF);

  #
  # CHECK new market shares
  #
  iob = IOBuffer()

  area = Select(Area,"ON")
  years = collect(Yr(2020):Yr(2040))

  print(iob,"Variable;Area;Sector;Technology")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  ec = Select(EC,"Passenger")
  techs = Select(Tech,(from="BusGasoline",to="BusFuelCell"))

  for tech in techs
    for year in years
      DDD[year] = MSFTarget[tech,area,year]
      print(iob,"MSFTarget;", AreaDS[area],";", ECDS[ec],";", TechDS[tech],";",DDD[year])
    end
    print(iob)
  end
  print(iob)

  for tech in techs, Carriage in Enduses
    for year in years
      DDD[year] = xMMSF[Carriage,tech,ec,area,year]
      print(iob,"xMMSF;", AreaDS[area],";", ECDS[ec],";", TechDS[tech],";",DDD[year])
    end
    print(iob)
  end
  print(iob)

  for year in years
    DDD[year] = BusMSOld[area,year]
    print(iob,"BusMSOld;", AreaDS[area],";", ECDS[ec],";",DDD[year])
  end
  print(iob)
  print(iob)

  for year in years
    DDD[year] = ICEBusMSOld[area,year]
    print(iob,"ICEBusMSOld;", AreaDS[area],";", ECDS[ec],";",DDD[year])
  end
  print(iob)
  print(iob)

  for year in years
    DDD[year] = ElectricGoal[year]
    print(iob,"ElectricGoal;", AreaDS[area],";", ECDS[ec],";",DDD[year])
  end
  print(iob)
  print(iob)

  OutFil = "xMMSFYr-BusElectric.dta"
  open(joinpath(OutputFolder, OutFil), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function PolicyControl(db)
  @info ("Trans_MS_Electric_Bus.jl - PolicyControl")
  TransPolicyBus(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
