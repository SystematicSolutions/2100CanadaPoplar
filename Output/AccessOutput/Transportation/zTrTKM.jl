#
# zTrTKM.jl
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

Base.@kwdef struct zTrTKMData
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  VDT::VariableArray{5} = ReadDisk(db,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  VDTRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #

end

function zTrTKM_DtaRun(data,iob,areas,nation)
  (; AreaDS,EC,ECDS,ECs,Tech,TechDS,Techs,Year) = data
  (; BaseSw,EndTime,VDT,VDTRef) = data

  TonConv=0.9072

  if BaseSw != 0
    VDTRef .= VDT
  end
  years = collect(1:Yr(EndTime))
  enduse = 1

  ecs = Select(EC,["Freight","AirFreight"])
  # 
  for year in years
    for area in areas
      ZZZ = sum(VDT[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs, tech in Techs)
      CCC = sum(VDTRef[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs, tech in Techs)
      if ZZZ != 0 || CCC != 0
        println(iob,"zTrTKM;", Year[year],";",AreaDS[area],";","Domestic Freight",";","Total",";",
        "Millions Tonne-Kilometers",";",ZZZ,";",CCC)
      end
    end # area in areas
  end # year in years
  #
  techs1 = Select(Tech,(from="HDV2B3Gasoline", to="HDV8FuelCell"))
  techs2 = Select(Tech,["TrainDiesel","TrainFuelCell","MarineHeavy","MarineLight","MarineFuelCell"])
  techs = union(techs1,techs2)
  # 
  for year in years
    for area in areas
      for tech in techs
        ZZZ = sum(VDT[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs)
        CCC = sum(VDTRef[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs)
        if ZZZ != 0 || CCC != 0
          println(iob,"zTrTKM;", Year[year],";",AreaDS[area],";","Domestic Freight",";",TechDS[tech],";",
          "Millions Tonne-Kilometers",";",ZZZ,";",CCC)
        end
      end # tech in techs
    end # area in areas
  end # year in years

  ecs = Select(EC,["AirFreight"])
  techs = Select(Tech,["PlaneJetFuel","PlaneGasoline"])
  # 
  for year in years
    for area in areas
      for tech in techs
        ZZZ = sum(VDT[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs)
        CCC = sum(VDTRef[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs)
        if ZZZ != 0 || CCC != 0
          println(iob,"zTrTKM;", Year[year],";",AreaDS[area],";","Domestic Freight",";",TechDS[tech],";",
          "Millions Tonne-Kilometers",";",ZZZ,";",CCC)
        end
      end # tech in techs
    end # area in areas
  end # year in years

  ecs = Select(EC,["ForeignFreight"])
  techs = Select(Tech,["MarineLight","MarineHeavy","PlaneJetFuel","PlaneGasoline"])
  # 
  for year in years
    for area in areas
      for tech in techs
        ZZZ = sum(VDT[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs)
        CCC = sum(VDTRef[enduse,tech,ec,area,year]*1.609344*TonConv for ec in ecs)
        if ZZZ != 0 || CCC != 0
          println(iob,"zTrTKM;", Year[year],";",AreaDS[area],";","Foreign Freight",";",TechDS[tech],";",
          "Millions Tonne-Kilometers",";",ZZZ,";",CCC)
        end
      end # tech in techs
    end # area in areas
  end # year in years

end # function zTrTKM_DtaRun

function CreatezTrTKMOutputFile(db,iob,nationkey,SceName)
  filename = "zTrTKM-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrTKM_DtaControl(db)
  data = zTrTKMData(; db)
  (; Nation) = data
  (; ANMap,NationOutputMap,SceName) = data

  @info "zTrTKM_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Units;zData;zInitial")       

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      areas = findall(ANMap[:,nation] .== 1.0)
      zTrTKM_DtaRun(data,iob,areas,nation)
      CreatezTrTKMOutputFile(db,iob,Nation[nation],SceName)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zTrTKM_DtaControl(DB)
end
