#
# zXMMSF.jl
#

#
# Residential
#
Base.@kwdef struct zXMMSFResData
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  EUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  EUPCRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zxMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
  zxMMSFRef::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
  
  #
  # Scratch Variables
  #
  EUPCRefSum::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Production Capacity (M$/Yr)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zXMMSFRes(data)
  (; Nation,Years) = data
  (; CDTime,UnitsDS) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  UnitsDS[US] = "$CDTime(1/Yr)"
  UnitsDS[CN] = "$CDTime(1/Yr)"
end

function zXMMSFRes_DtaRun(data,iob,nation,SceName)
  (; Age,Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,EUPCRefSum) = data
  (; zxMMSF,zxMMSFRef) = data
  (; CCC,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zxMMSFRef .= zxMMSF
    EUPCRef .= EUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  age = first(Ages)

  for year in years, area in areas, ec in ECs, enduse in Enduses
    EUPCRefSum[enduse,ec,area,year] = sum(EUPCRef[enduse,tech,age,ec,area,year] for tech in Techs)
    EUPCRefSum[enduse,ec,area,year] = max(EUPCRefSum[enduse,ec,area,year],0)
  end

  for year in years
    for ec in ECs
      for tech in Techs
        for enduse in Enduses
          @finite_math ZZZ[year] = sum(zxMMSF[enduse,tech,ec,area,year]*
            EUPCRefSum[enduse,ec,area,year] for area in areas)/
            sum(EUPCRefSum[enduse,ec,area,year] for area in areas)

          @finite_math CCC[year] = sum(zxMMSFRef[enduse,tech,ec,area,year]*
            EUPCRefSum[enduse,ec,area,year] for area in areas)/
            sum(EUPCRefSum[enduse,ec,area,year] for area in areas)

          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.4f",ZZZ[year])
            zInitial = @sprintf("%.4f",CCC[year])
            println(iob,"zxMMSF;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end

          for area in areas
            @finite_math ZZZ[year] = zxMMSF[enduse, tech, ec, area, year]
            @finite_math CCC[year] = zxMMSFRef[enduse, tech, ec, area, year]

            if ZZZ[year] != 0 || CCC[year] != 0
              println(iob,"zxMMSF;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",@sprintf("%.4f",ZZZ[year]),";",@sprintf("%.4f",CCC[year]))
            end
          end # for area in areas
        end # for year in years
      end # for tech in Techs
    end # for enduse in Enduses
  end # for ec in ECs

end # function zXMMSFRes_DtaRun

#
# Commercial
#
Base.@kwdef struct zXMMSFComData
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  EUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  EUPCRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zxMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
  zxMMSFRef::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)

  #
  # Scratch Variables
  #
  EUPCRefSum::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Production Capacity (M$/Yr)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zXMMSFCom(data)
  (; Nation,Years) = data
  (; CDTime,UnitsDS) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  UnitsDS[US] = "$CDTime(1/Yr)"
  UnitsDS[CN] = "$CDTime(1/Yr)"
end

function zXMMSFCom_DtaRun(data,iob,nation,SceName)
  (; Age,Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,EUPCRefSum,zxMMSF,zxMMSFRef) = data
  (; CCC,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zxMMSFRef .= zxMMSF
    EUPCRef .= EUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  age = first(Ages)

  for year in years, area in areas, ec in ECs, enduse in Enduses
    EUPCRefSum[enduse,ec,area,year] = sum(EUPCRef[enduse,tech,age,ec,area,year] for tech in Techs)
    EUPCRefSum[enduse,ec,area,year] = max(EUPCRefSum[enduse,ec,area,year],0)
  end

  for year in years
    for ec in ECs
      for tech in Techs
        for enduse in Enduses
          @finite_math ZZZ[year] = sum(zxMMSF[enduse,tech,ec,area,year]*
            EUPCRefSum[enduse,ec,area,year] for area in areas)/
            sum(EUPCRefSum[enduse,ec,area,year] for area in areas)

          @finite_math CCC[year] = sum(zxMMSFRef[enduse,tech,ec,area,year]*
            EUPCRefSum[enduse,ec,area,year] for area in areas)/
            sum(EUPCRefSum[enduse,ec,area,year] for area in areas)

          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.4f",ZZZ[year])
            zInitial = @sprintf("%.4f",CCC[year])
            println(iob,"zxMMSF;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end

          for area in areas
            @finite_math ZZZ[year] = zxMMSF[enduse, tech, ec, area, year]
            @finite_math CCC[year] = zxMMSFRef[enduse, tech, ec, area, year]

            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.4f",ZZZ[year])
              zInitial = @sprintf("%.4f",CCC[year])
              println(iob,"zxMMSF;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for area in areas
        end # for year in years
      end # for tech in Techs
    end # for enduse in Enduses
  end # for ec in ECs

end # function zXMMSFCom_DtaRun

#
# Industrial
#
Base.@kwdef struct zXMMSFIndData
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
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  EUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  EUPCRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] Production Capacity (M$/Yr)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zxMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
  zxMMSFRef::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)

  #
  # Scratch Variables
  #
  EUPCRefSum::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Production Capacity (M$/Yr)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zXMMSFInd(data)
  (; Nation,Years) = data
  (; CDTime,UnitsDS) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  UnitsDS[US] = "$CDTime(1/Yr)"
  UnitsDS[CN] = "$CDTime(1/Yr)"
end

function zXMMSFInd_DtaRun(data,iob,nation,SceName)
  (; Age,Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,EUPCRefSum,zxMMSF,zxMMSFRef) = data
  (; CCC,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zxMMSFRef .= zxMMSF
    EUPCRef .= EUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  age = first(Ages)

  for year in years, area in areas, ec in ECs, enduse in Enduses
    EUPCRefSum[enduse,ec,area,year] = sum(EUPCRef[enduse,tech,age,ec,area,year] for tech in Techs)
    EUPCRefSum[enduse,ec,area,year] = max(EUPCRefSum[enduse,ec,area,year],0)
  end

  for year in years
    for ec in ECs
      for tech in Techs
        for enduse in Enduses
          @finite_math ZZZ[year] = sum(zxMMSF[enduse,tech,ec,area,year]*
            EUPCRefSum[enduse,ec,area,year] for area in areas)/
            sum(EUPCRefSum[enduse,ec,area,year] for area in areas)

          @finite_math CCC[year] = sum(zxMMSFRef[enduse,tech,ec,area,year]*
            EUPCRefSum[enduse,ec,area,year] for area in areas)/
            sum(EUPCRefSum[enduse,ec,area,year] for area in areas)

          if ZZZ[year] != 0 || CCC[year] != 0
            println(iob,"zxMMSF;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",@sprintf("%.4f",ZZZ[year]),";",@sprintf("%.4f",CCC[year]))
          end

          for area in areas
            @finite_math ZZZ[year] = zxMMSF[enduse, tech, ec, area, year]

            @finite_math CCC[year] = zxMMSFRef[enduse, tech, ec, area, year]
            if ZZZ[year] != 0 || CCC[year] != 0
              println(iob,"zxMMSF;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",@sprintf("%.4f",ZZZ[year]),";",@sprintf("%.4f",CCC[year]))
            end
          end # for area in areas
        end # for year in years
      end # for tech in Techs
    end # for enduse in Enduses
  end # for ec in ECs
        
end # function zXMMSFInd_DtaRun

function zXMMSF_Residential(db,iob,nation,SceName)
  data = zXMMSFResData(; db)
  AssignConversions_zXMMSFRes(data)
  zXMMSFRes_DtaRun(data,iob,nation,SceName)
end

function zXMMSF_Commercial(db,iob,nation,SceName)
  data = zXMMSFComData(; db)
  AssignConversions_zXMMSFCom(data)
  zXMMSFCom_DtaRun(data,iob,nation,SceName)
end

function zXMMSF_Industrial(db,iob,nation,SceName)
  data = zXMMSFIndData(; db)
  AssignConversions_zXMMSFInd(data)
  zXMMSFInd_DtaRun(data,iob,nation,SceName)
end

function CreatezXMMSFOutputFile(db,iob,nationkey,SceName)
  filename = "zxMMSF-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zXMMSF_DtaControl(db,SceName)
  data = zXMMSFResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zXMMSF_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Enduse;Units;zData;zInitial")       

  for nation in Nations
    if NationOutputMap[nation] == 1
      zXMMSF_Residential(db,iob,nation,SceName)
      zXMMSF_Commercial(db,iob,nation,SceName)
      zXMMSF_Industrial(db,iob,nation,SceName)

      CreatezXMMSFOutputFile(db,iob,Nation[nation],SceName)
  
    end
  end

end
