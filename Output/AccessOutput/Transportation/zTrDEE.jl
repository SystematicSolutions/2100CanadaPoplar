#
# zTrDEE.jl
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

Base.@kwdef struct zTrDEEData
  db::String
  
  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")  
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  DAct::VariableArray{5} = ReadDisk(db,"$Input/DAct") # [Enduse,Tech,EC,Area,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  DActRef::VariableArray{5} = ReadDisk(RefNameDB,"$Input/DAct") # [Enduse,Tech,EC,Area,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  VDT::VariableArray{5} = ReadDisk(db,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  VDTRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  zTrDEE::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu) 
  zTrDEERef::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu) 

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Convert::VariableArray = zeros(Float32,length(Tech))
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function AssignConversions_zTrDEE(data)
  (; Nation,Tech) = data
  (; Convert,UnitsDS) = data

  techs = Select(Tech,["LDVGasoline","LDVElectric","LDVEthanol","LDVHybrid","LDVFuelCell",
                       "LDTGasoline","LDTElectric","LDTEthanol","LDTHybrid","LDTFuelCell",
                       "Motorcycle","BusGasoline","PlaneGasoline",
                       "HDV2B3Gasoline","HDV45Gasoline","HDV67Gasoline","HDV8Gasoline",
                       "HDV2B3Electric","HDV45Electric","HDV67Electric","HDV8Electric",
                       "HDV2B3FuelCell","HDV45FuelCell","HDV67FuelCell","HDV8FuelCell",
                       "OffRoad"])
  for tech in techs
    Convert[tech] = 125000/1e6
  end

  techs = Select(Tech,["LDVDiesel","LDTDiesel","BusDiesel",
                       "HDV2B3Diesel","HDV45Diesel","HDV67Diesel","HDV8Diesel",
                       "HDV2B3NaturalGas","HDV45NaturalGas","HDV67NaturalGas","HDV8NaturalGas",
                       "TrainDiesel","TrainFuelCell","MarineLight","MarineFuelCell"])
  for tech in techs
    Convert[tech] = 139000/1e6
  end

  techs = Select(Tech,["LDVPropane","LDTPropane","HDV2B3Propane","HDV45Propane","HDV67Propane",
                       "HDV8Propane","BusPropane"])
  for tech in techs
    Convert[tech] = 78965/1e6
  end

  techs = Select(Tech,["LDVNaturalGas","LDTNaturalGas","BusNaturalGas"])
  for tech in techs
    Convert[tech] = 133.39/1e6
  end

  techs = Select(Tech,["PlaneJetFuel","PlaneFuelCell"])
  for tech in techs
    Convert[tech] = 135000/1e6
  end

  techs = Select(Tech,["MarineHeavy"])
  for tech in techs
    Convert[tech] = 152546/1e6
  end

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  UnitsDS[US] = "Btu/Btu"
  UnitsDS[CN] = "Liters/100km"
end

function zTrDEE_DtaRun(data,iob,areas,nation,AreaName)
  (; EC,ECDS,ECs,Tech,TechDS,Techs,Year) = data
  (; BaseSw,DAct,DActRef,Dmd,EndTime,VDT,VDTRef,zTrDEE,zTrDEERef) = data
  (; Convert,UnitsDS) = data

  if BaseSw != 0
    zTrDEERef .= zTrDEE
    VDTRef .= VDT
  end
  
  literconvert = 235.214583

  years = collect(1:Yr(EndTime))
  enduse = 1

  for tech in Techs
    for ec in ECs
      for year in years
        if sum(Dmd[enduse,tech,ec,area,year] for area in areas) > 0
          @finite_math ZZZ = literconvert/(sum(zTrDEE[enduse,tech,ec,area,year]*
          Convert[tech]/DAct[enduse,tech,ec,area,year]*VDT[enduse,tech,ec,area,year] for area in areas)/
          sum(VDT[enduse,tech,ec,area,year] for area in areas))

          @finite_math CCC = literconvert/(sum(zTrDEERef[enduse,tech,ec,area,year]*
          Convert[tech]/DActRef[enduse,tech,ec,area,year]*VDTRef[enduse,tech,ec,area,year] for area in areas)/
          sum(VDTRef[enduse,tech,ec,area,year] for area in areas))

          if ZZZ != 0 || CCC != 0
            println(iob,"zTrDEE;", Year[year],";",AreaName,";",ECDS[ec],";",TechDS[tech],";",
            UnitsDS[nation],";",ZZZ,";",CCC)
          end
        end # if Dmd
      end # year in years
    end # for ec in ECs
  end # tech in Techs

  ec = Select(EC,"Passenger")
  techs = Select(Tech,(from="LDVGasoline", to="LDTDiesel"))
  for year in years
    if sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs) > 0
      @finite_math ZZZ = literconvert/(sum(zTrDEE[enduse,tech,ec,area,year]*
      Convert[tech]/DAct[enduse,tech,ec,area,year]*VDT[enduse,tech,ec,area,year] for area in areas, tech in techs)/
      sum(VDT[enduse,tech,ec,area,year] for area in areas, tech in techs))

      @finite_math CCC = literconvert/(sum(zTrDEERef[enduse,tech,ec,area,year]*
      Convert[tech]/DActRef[enduse,tech,ec,area,year]*VDTRef[enduse,tech,ec,area,year] for area in areas, tech in techs)/
      sum(VDTRef[enduse,tech,ec,area,year] for area in areas, tech in techs))

      if ZZZ != 0 || CCC != 0
        println(iob,"zTrDEE;", Year[year],";",AreaName,";",ECDS[ec],";","Personal Vehicle Average;",
        UnitsDS[nation],";",ZZZ,";",CCC)
      end
    end # if Dmd
  end # year in years

  ec = Select(EC,"Freight")
  techs = Select(Tech,(from="HDV2B3Gasoline", to="HDV8FuelCell"))
  for year in years
    if sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs) > 0
      @finite_math ZZZ = literconvert/(sum(zTrDEE[enduse,tech,ec,area,year]*
      Convert[tech]/DAct[enduse,tech,ec,area,year]*VDT[enduse,tech,ec,area,year] for area in areas, tech in techs)/
      sum(VDT[enduse,tech,ec,area,year] for area in areas, tech in techs))

      @finite_math CCC = literconvert/(sum(zTrDEERef[enduse,tech,ec,area,year]*
      Convert[tech]/DActRef[enduse,tech,ec,area,year]*VDTRef[enduse,tech,ec,area,year] for area in areas, tech in techs)/
      sum(VDTRef[enduse,tech,ec,area,year] for area in areas, tech in techs))

      if ZZZ != 0 || CCC != 0
        println(iob,"zTrDEE;", Year[year],";",AreaName,";",ECDS[ec],";","Road Freight Average;",
        UnitsDS[nation],";",ZZZ,";",CCC)
      end
    end # if Dmd
  end # year in years        
end # function zTrDEE_DtaRun

function CreatezTrDEEOutputFile(db,iob,nationkey,SceName)
  filename = "zTrDEE-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrDEE_DtaControl(db)
  data = zTrDEEData(; db)
  (; AreaDS,Nation) = data
  (; ANMap,NationOutputMap,SceName) = data

  @info "zTrDEE_DtaControl"
  AssignConversions_zTrDEE(data)

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Units;zData;zInitial")       

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      areas = findall(ANMap[:,nation] .== 1.0)
      if Nation[nation] == "CN"
        AreaName = "Canada"
      else
        AreaName = "United States"
      end
      zTrDEE_DtaRun(data,iob,areas,nation,AreaName)
      for area in areas
        AreaName = AreaDS[area]
        zTrDEE_DtaRun(data,iob,areas,nation,AreaName)
      end
      CreatezTrDEEOutputFile(db,iob,Nation[nation],SceName)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zTrDEE_DtaControl(DB)
end
