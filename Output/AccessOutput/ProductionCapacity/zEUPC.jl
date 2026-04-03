#
# zEUPC.jl - Write Enduse Demands for Access Database
#

Base.@kwdef struct zEUPC_RControl
  db::String
  
  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zEUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  zEUPCRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zEUPC_AssignConversions_Res(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Units Of Driver"
  UnitsDS[CN] = "Units Of Driver"
end

function zEUPCRes_DtaRun(data,iob,nation,SceName)
  (; Age,AgeDS,Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zEUPC,zEUPCRef,ZZZ) = data

  if BaseSw != 0
    @. zEUPCRef = zEUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            for age in Ages
              ZZZ[year] = zEUPC[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              CCC[year] = zEUPCRef[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              if ZZZ[year] != 0 || ZZZ[year] != 0
                println(iob,"zEUPC;",Year[year],";",AreaDS[area],";",ECDS[ec],";",AgeDS[age],";",
                  TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
              end
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
Base.@kwdef struct zEUPC_CControl
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
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
  zEUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  zEUPCRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zEUPC_AssignConversions_Com(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Units Of Driver"
  UnitsDS[CN] = "Units Of Driver"
end

function zEUPCCom_DtaRun(data,iob,nation,SceName)
  (; Age,AgeDS,Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zEUPC,zEUPCRef,ZZZ) = data

  if BaseSw != 0
    @. zEUPCRef = zEUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            for age in Ages
              ZZZ[year] = zEUPC[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              CCC[year] = zEUPCRef[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              if ZZZ[year] != 0 || ZZZ[year] != 0
                println(iob,"zEUPC;",Year[year],";",AreaDS[area],";",ECDS[ec],";",AgeDS[age],";",
                  TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
              end
            end
          end
        end
      end
    end 
  end
end

#
# Industrial except for Oil and Gas
#
Base.@kwdef struct zEUPC_IControl
  db::String
  
  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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
  zEUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  zEUPCRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zEUPC_AssignConversions_Ind(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Units Of Driver"
  UnitsDS[CN] = "Units Of Driver"
end

function zEUPCInd_DtaRun(data,iob,nation,SceName)
  (; Age,AgeDS,Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zEUPC,zEUPCRef,ZZZ) = data

  if BaseSw != 0
    @. zEUPCRef = zEUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            for age in Ages
              ZZZ[year] = zEUPC[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              CCC[year] = zEUPCRef[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              if ZZZ[year] != 0 || ZZZ[year] != 0
                println(iob,"zEUPC;",Year[year],";",AreaDS[area],";",ECDS[ec],";",AgeDS[age],";",
                  TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
              end
            end
          end
        end
      end
    end 
  end
end

#
# Industrial except for Oil and Gas
#
Base.@kwdef struct zEUPC_TControl
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
  zEUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  zEUPCRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zEUPC_AssignConversions_Trans(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Units Of Driver"
  UnitsDS[CN] = "Units Of Driver"
end

function zEUPCTrans_DtaRun(data,iob,nation,SceName)
  (; Age,AgeDS,Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zEUPC,zEUPCRef,ZZZ) = data

  if BaseSw != 0
    @. zEUPCRef = zEUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            for age in Ages
              ZZZ[year] = zEUPC[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              CCC[year] = zEUPCRef[enduse,tech,age,ec,area,year]*Conversion[nation,year]
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              if ZZZ[year] != 0 || ZZZ[year] != 0
                println(iob,"zEUPC;",Year[year],";",AreaDS[area],";",ECDS[ec],";",AgeDS[age],";",
                  TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
              end
            end
          end
        end
      end
    end 
  end
end

function zEUPC_Residential(db,iob,nation,SceName)
  data = zEUPC_RControl(; db)
  zEUPC_AssignConversions_Res(data)
  zEUPCRes_DtaRun(data,iob,nation,SceName)
end

function zEUPC_Commercial(db,iob,nation,SceName)
  data = zEUPC_CControl(; db)
  zEUPC_AssignConversions_Com(data)
  zEUPCCom_DtaRun(data,iob,nation,SceName)
end

function zEUPC_Industrial(db,iob,nation,SceName)
  data = zEUPC_IControl(; db)
  zEUPC_AssignConversions_Ind(data)
  zEUPCInd_DtaRun(data,iob,nation,SceName)
end

function zEUPC_Transportation(db,iob,nation,SceName)
  data = zEUPC_TControl(; db)
  zEUPC_AssignConversions_Trans(data)
  zEUPCTrans_DtaRun(data,iob,nation,SceName)
end

function zEUPC_CreateOutputFile(db,iob,nationkey,SceName)
  filename = "zEUPC-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zEUPC_DtaControl(db,SceName)
  data = zEUPC_RControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zEUPC_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Age;Tech;Enduse;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zEUPC_Residential(db,iob,nation,SceName)
      zEUPC_Commercial(db,iob,nation,SceName)
      zEUPC_Industrial(db,iob,nation,SceName)
      zEUPC_Transportation(db,iob,nation,SceName)

      zEUPC_CreateOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
