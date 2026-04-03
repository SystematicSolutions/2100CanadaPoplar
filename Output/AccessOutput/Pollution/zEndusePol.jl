#
# zEndusePol.jl
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

#
# Residential
#
Base.@kwdef struct ResData
  db::String
  
  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PollType::SetArray = ReadDisk(db,"MainDB/PollType") # [Poll] "Pollution Type - CAC/GHG/Neither(Name)","Name")
  zEndusePol::VariableArray{6} = ReadDisk(db,"$CalDB/Polute") #[Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr) 
  zEndusePolRef::VariableArray{6} = ReadDisk(RefNameDB,"$CalDB/Polute") #[Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr) 

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zEndusePolRes_DtaRun(data,iob,nation,polls)
  (; Area,AreaDS,EC,ECDS,ECs,Enduses,EnduseDS) = data
  (; FuelEP,FuelEPDS,FuelEPs,Nation,Poll,PollDS,Polls,Year) = data
  (; ANMap,CCC,Conversion,EndTime,PolConv) = data
  (; PollType,UnitsDS,zEndusePol,zEndusePolRef,ZZZ) = data


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


  for year in years
    for enduse in Enduses
      for ec in ECs
        for poll in polls
          for area in areas
            ZZZ[year] = sum(zEndusePol[enduse,fuelep,ec,poll,area,year]*Conversion[poll] for fuelep in FuelEPs)
            CCC[year] = sum(zEndusePolRef[enduse,fuelep,ec,poll,area,year]*Conversion[poll] for fuelep in FuelEPs)
            if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zEndusePol;",Year[year],";",AreaDS[area],";",PollDS[poll],";",
                ECDS[ec],";",EnduseDS[enduse],";",UnitsDS[poll],";",zData,";",zInitial)
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
    for year in years
      for enduse in Enduses
        for ec in ECs
          for area in areas
            ZZZ[year] = sum(zEndusePol[enduse,fuelep,ec,poll,area,year]*
              PolConv[poll] for fuelep in FuelEPs, poll in polls)/1000
            CCC[year] = sum(zEndusePolRef[enduse,fuelep,ec,poll,area,year]*
              PolConv[poll] for fuelep in FuelEPs, poll in polls)/1000
              if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
                zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zEndusePol;",Year[year],";",AreaDS[area],";",polltype,";",
                ECDS[ec],";",EnduseDS[enduse],";",pollunit,";",zData,";",zInitial)
            end
          end
        end
      end
    end
  end
end

#
# Commercial
#
Base.@kwdef struct ComData
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") # [Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  # [Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PollType::SetArray = ReadDisk(db,"MainDB/PollType") # [Poll] "Pollution Type - CAC/GHG/Neither(Name)","Name")
  zEndusePol::VariableArray{6} = ReadDisk(db,"$CalDB/Polute") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr) 
  zEndusePolRef::VariableArray{6} = ReadDisk(RefNameDB,"$CalDB/Polute") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr) 

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description
  CCC = zeros(Float32,length(Year))
  ZZZ = zeros(Float32,length(Year))
end

function zEndusePolCom_DtaRun(data,iob,nation,polls)
  (; Area,AreaDS,EC,ECDS,ECs,Enduses,EnduseDS) = data
  (; FuelEP,FuelEPDS,FuelEPs,Nation,Poll,PollDS,Polls,Year) = data
  (; ANMap,CCC,Conversion,EndTime,PolConv) = data
  (; PollType,UnitsDS,zEndusePol,zEndusePolRef,ZZZ) = data

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

  for year in years
    for enduse in Enduses
      for ec in ECs
        for poll in polls
          for area in areas
            ZZZ[year] = sum(zEndusePol[enduse,fuelep,ec,poll,area,year]*Conversion[poll] for fuelep in FuelEPs)
            CCC[year] = sum(zEndusePolRef[enduse,fuelep,ec,poll,area,year]*Conversion[poll] for fuelep in FuelEPs)
            if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zEndusePol;",Year[year],";",AreaDS[area],";",PollDS[poll],";",
                ECDS[ec],";",EnduseDS[enduse],";",UnitsDS[poll],";",zData,";",zInitial)
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
    for year in years
      for enduse in Enduses
        for ec in ECs
          for area in areas
            ZZZ[year] = sum(zEndusePol[enduse,fuelep,ec,poll,area,year]*
              PolConv[poll] for fuelep in FuelEPs, poll in polls)/1000
            CCC[year] = sum(zEndusePolRef[enduse,fuelep,ec,poll,area,year]*
              PolConv[poll] for fuelep in FuelEPs, poll in polls)/1000
            if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zEndusePol;",Year[year],";",AreaDS[area],";",polltype,";",
                  ECDS[ec],";",EnduseDS[enduse],";",pollunit,";",zData,";",zInitial)
            end
          end
        end
      end
    end
  end
end

#
# Industrial
#
Base.@kwdef struct IndData
  db::String
  
  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))  
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  PolConv::VariableArray{1}  = ReadDisk(db,"SInput/PolConv")  #[Poll]  Pollution Conversion Factor (convert GHGs to eCO2)
  PollType::SetArray = ReadDisk(db,"MainDB/PollType") # [Poll] "Pollution Type - CAC/GHG/Neither(Name)","Name")
  zEndusePol::VariableArray{6} = ReadDisk(db,"$CalDB/Polute") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr) 
  zEndusePolRef::VariableArray{6} = ReadDisk(RefNameDB,"$CalDB/Polute") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution (Tonnes/Yr) 

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Poll)) # [Poll] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Poll)) # [Poll] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zEndusePolInd_DtaRun(data,iob,nation,polls)
  (; Area,AreaDS,EC,ECDS,ECs,Enduses,EnduseDS) = data
  (; FuelEP,FuelEPDS,FuelEPs,Nation,Poll,PollDS,Polls,Year) = data
  (; ANMap,CCC,Conversion,EndTime,PolConv) = data
  (; PollType,UnitsDS,zEndusePol,zEndusePolRef,ZZZ) = data

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
  #
  # Suppress Crop Production since all these emissions are process-related.
  #
  ecs1 = Select(EC,(from="Food",to="OnFarmFuelUse"))
  ecs2 = Select(EC,"AnimalProduction")
  ecs = union(ecs1,ecs2)

  for year in years
    for enduse in Enduses
      for ec in ecs
        for poll in polls
          for area in areas
            ZZZ[year] = sum(zEndusePol[enduse,fuelep,ec,poll,area,year]*Conversion[poll] for fuelep in FuelEPs)
            CCC[year] = sum(zEndusePolRef[enduse,fuelep,ec,poll,area,year]*Conversion[poll] for fuelep in FuelEPs)
            if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zEndusePol;",Year[year],";",AreaDS[area],";",PollDS[poll],";",
                ECDS[ec],";",EnduseDS[enduse],";",UnitsDS[poll],";",zData,";",zInitial)
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
    for year in years
      for enduse in Enduses
        for ec in ecs
          for area in areas
            ZZZ[year] = sum(zEndusePol[enduse,fuelep,ec,poll,area,year]*
              PolConv[poll] for fuelep in FuelEPs, poll in polls)/1000
            CCC[year] = sum(zEndusePolRef[enduse,fuelep,ec,poll,area,year]*
              PolConv[poll] for fuelep in FuelEPs, poll in polls)/1000
            if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zEndusePol;",Year[year],";",AreaDS[area],";",polltype,";",
                ECDS[ec],";",EnduseDS[enduse],";",pollunit,";",zData,";",zInitial)
            end
          end
        end
      end
    end
  end
end

function zEndusePol_Residential(db,iob,nation,polls)
  data = ResData(; db)
  zEndusePolRes_DtaRun(data,iob,nation,polls)
end

function zEndusePol_Commercial(db,iob,nation,polls)
  data = ComData(; db)
  zEndusePolCom_DtaRun(data,iob,nation,polls)
end

function zEndusePol_Industrial(db,iob,nation,polls)
  data = IndData(; db)
  zEndusePolInd_DtaRun(data,iob,nation,polls)
end

function CreateOutputFile(db,iob,nationkey,polltype,SceName)
  filename = "zEndusePol-$polltype-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zEndusePol_DtaControl(db)
  data = ResData(; db)
  (; Nation,Nations,Poll,Polls) = data
  (; NationOutputMap,PollType,SceName) = data

  @info "zEndusePol_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1

      #
      # CACs
      #
      iob = IOBuffer()
      println(iob,"Variable;Year;Area;Pollutant;Sector;Enduse;Units;zData;zInitial")

      polls = Select(Poll,["SOX","COX","NOX","PMT","VOC","PM25","PM10","Hg","NH3","BC"])
      zEndusePol_Residential(db,iob,nation,polls)
      zEndusePol_Commercial(db,iob,nation,polls)
      zEndusePol_Industrial(db,iob,nation,polls)
      polltype = "CAC"
      CreateOutputFile(db,iob,Nation[nation],polltype,SceName)

      #
      # GHGs
      #
      iob = IOBuffer()
      println(iob,"Variable;Year;Area;Pollutant;Sector;Enduse;Units;zData;zInitial")
      polls = Select(Poll,["CO2","CH4","N2O"])
      zEndusePol_Residential(db,iob,nation,polls)
      zEndusePol_Commercial(db,iob,nation,polls)
      zEndusePol_Industrial(db,iob,nation,polls)
      polltype = "GHG"
      CreateOutputFile(db,iob,Nation[nation],polltype,SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zEndusePol_DtaControl(DB)
end
