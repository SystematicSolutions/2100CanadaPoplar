#
# zTrVDT.jl
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

Base.@kwdef struct zTrVDTData
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
  UnitsDS::SetArray = fill("",length(EC)) # [EC] Units Description
  #
  # Scratch Variables
  #

end

function zTrVDT_DtaRun(data,iob,areas,nation)
  (; AreaDS,EC,ECs,ECDS,Nation,Tech,TechDS,Techs,Year) = data
  (; BaseSw,EndTime,UnitsDS,VDT,VDTRef) = data

  TonConv=0.9072

  if BaseSw != 0
    VDTRef .= VDT
  end
  years = collect(1:Yr(EndTime))
  enduse = 1

  for ec in ECs
    if Nation[nation] == "CN"
      UnitsDS[ec]="Million Tonne-Kilometers"
    else
      UnitsDS[ec]="Million Tonne-Miles"
    end
    if (EC[ec] == "Passenger") || (EC[ec] == "AirPassenger") || (EC[ec] == "ForeignPassenger")
      if Nation[nation] == "CN"
        UnitsDS[ec]="Million Vehicle Passenger-Kilometers"
      else
        UnitsDS[ec]="Million Vehicle Passenger-Miles"
      end
    end
    for tech in Techs
      for year in years
        for area in areas
          ZZZ = VDT[enduse,tech,ec,area,year]*1.609344
          CCC = VDTRef[enduse,tech,ec,area,year]*1.609344
          if ZZZ != 0 || CCC != 0
            println(iob,"zTrVDT;", Year[year],";",AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
            UnitsDS[ec],";",ZZZ,";",CCC)
          end
        end
      end
    end # area in areas
  end # year in years
  #

end # function zTrVDT_DtaRun

function CreatezTrVDTOutputFile(db,iob,nationkey,SceName)
  filename = "zTrVDT-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrVDT_DtaControl(db)
  data = zTrVDTData(; db)
  (; Nation) = data
  (; ANMap,NationOutputMap,SceName) = data

  @info "zTrVDT_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Units;zData;zInitial")       

  nations = Select(Nation,["CN","US"])
  for nation in nations
    if NationOutputMap[nation] == 1
      areas = findall(ANMap[:,nation] .== 1.0)
      zTrVDT_DtaRun(data,iob,areas,nation)
      CreatezTrVDTOutputFile(db,iob,Nation[nation],SceName)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zTrVDT_DtaControl(DB)
end
