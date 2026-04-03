#
# zTrMEPol.jl
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

Base.@kwdef struct zTrMEPolData
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PollType::SetArray = ReadDisk(db,"MainDB/PollType") # [Poll] "Pollution Type - CAC/GHG/Neither(Name)","Name")
  zTrMEPol::VariableArray{5} = ReadDisk(db,"$Outpt/TrMEPol") #[Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr) 
  zTrMEPolRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/TrMEPol") #[Tech,EC,Poll,Area,Year] Non-Energy Pollution (Tonnes/Yr) 

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zTrMEPol_DtaRun(data,polls,nation)
  (; AreaDS,EC,ECDS,ECs) = data
  (; Nation,Poll,PollDS,Polls,TechDS,Techs,Year) = data
  (; ANMap,CCC,Conversion,EndTime,PolConv,PollType) = data
  (; UnitsDS,zTrMEPol,zTrMEPolRef,ZZZ,SceName) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Pollutant;Sector;Technology;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  for poll in Polls
    Conversion[poll] = 0.001
    UnitsDS[poll] = "Kilotonnes"
    if Poll[poll] == "Hg"
      Conversion[poll] = 1000
      UnitsDS[poll] = "Kilograms"
    end
  end

  for tech in Techs
    for ec in ECs
      for poll in polls
        for area in areas
          for year in years
            ZZZ[year] = zTrMEPol[tech,ec,poll,area,year]*Conversion[poll]
            CCC[year] = zTrMEPolRef[tech,ec,poll,area,year]*Conversion[poll]
            if ZZZ[year] != 0.0 || CCC[year] != 0.0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zTrMEPol;",Year[year],";",AreaDS[area],";",PollDS[poll],";",
                ECDS[ec],";",TechDS[tech],";",UnitsDS[poll],";",zData,";",zInitial)
            end
          end
        end
      end
    end
  end
  
  polltype = first(PollType[polls])
  pollunit = first(UnitsDS[polls])

  if polltype == "CO2"
    polltype = "GHG"
  elseif polltype == "SOX"
    polltype = "CAC"
  end 

  if polltype == "GHG"
    for tech in Techs
      for ec in ECs
        for area in areas
          for year in years
            ZZZ[year] = sum(zTrMEPol[tech,ec,poll,area,year]*PolConv[poll]*Conversion[poll] for poll in polls)/1000
            CCC[year] = sum(zTrMEPolRef[tech,ec,poll,area,year]*PolConv[poll]*Conversion[poll] for poll in polls)/1000
            if ZZZ[year] != 0.0 || CCC[year] != 0.0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zTrMEPol;",Year[year],";",AreaDS[area],";",polltype,";",
                ECDS[ec],";",TechDS[tech],";",pollunit,";",zData,";",zInitial)
            end
          end
        end
      end
    end
  end
  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zTrMEPol-$polltype-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrMEPol_DtaControl(db)
  data = zTrMEPolData(; db)
  (; db,Nation,Nations,Poll)= data
  (; ANMap,NationOutputMap)= data

  @info "zTrMEPol_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      polls = Select(Poll,["SOX","COX","NOX","PMT","VOC","PM25","PM10","Hg","NH3","BC"])
      zTrMEPol_DtaRun(data,polls,nation)

      polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
      zTrMEPol_DtaRun(data,polls,nation)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
  zTrMEPol_DtaControl(DB)
end
