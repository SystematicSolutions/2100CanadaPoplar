#
# zRPCC.jl
#

#
# Residential
#
Base.@kwdef struct zRPCCResData
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
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zRPCC::VariableArray{5} = ReadDisk(db,"$Outpt/RPCC") # Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area,Year]
  zRPCCRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/RPCC") # Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  RPMSF::VariableArray{5} = ReadDisk(db,"$Outpt/RPMSF") # Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  RPMSFRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/RPMSF") # Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  PCRetroRef::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Buildings Retrofit (Units/Year)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zRPCCRes(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; InflationNation,InflationNationRef,UnitsDS) = data
  
  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    ConversionRef[US,year] = 1/InflationNationRef[US,year]*InflationNationRef[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
    ConversionRef[CN,year] = 1/InflationNationRef[CN,year]*InflationNationRef[CN,CDYear]
  end

  UnitsDS[US] = "$CDTime \$/Driver"
  UnitsDS[CN] = "$CDTime \$/Driver"
end

function zRPCCRes_DtaRun(data,iob,nation,SceName)
  (; Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,RPMSF,RPMSFRef,zRPCC,zRPCCRef) = data
  (; CCC,Conversion,ConversionRef,PCRetroRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zRPCCRef .= zRPCC
    EUPCRef .= EUPC
    RPMSFRef .= RPMSF
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)
  enduse = 1

  for year in years, area in areas, ec in ECs, tech in Techs
    PCRetroRef[enduse,tech,ec,area,year]=sum(EUPCRef[enduse,tech,age,ec,area,year]*RPMSFRef[enduse,tech,ec,area,year] for age in Ages)
    PCRetroRef[enduse,tech,ec,area,year]=max(PCRetroRef[enduse,tech,ec,area,year],0)
  end

  for year in years
    for ec in ECs
      for tech in Techs
        @finite_math ZZZ[year] = sum(zRPCC[enduse,tech,ec,area,year]*
          PCRetroRef[enduse,tech,ec,area,year] for area in areas)/
          sum(PCRetroRef[enduse,t,e,a,year] for a in areas, e in ECs, t in Techs)*
          Conversion[nation,year]

        @finite_math CCC[year] = sum(zRPCCRef[enduse,tech,ec,area,year]*
          PCRetroRef[enduse,tech,ec,area,year] for area in areas)/
          sum(PCRetroRef[enduse,t,e,a,year] for a in areas, e in ECs, t in Techs)*
          Conversion[nation,year]

        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zRPCC;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = (zRPCC[enduse,tech,ec,area,year]*
            PCRetroRef[enduse,tech,ec,area,year])/
            sum(PCRetroRef[enduse,t,e,area,year] for e in ECs, t in Techs)*
            Conversion[nation,year]

          @finite_math CCC[year] = (zRPCCRef[enduse,tech,ec,area,year]*
            PCRetroRef[enduse,tech,ec,area,year])/
            sum(PCRetroRef[enduse,t,e,area,year] for e in ECs, t in Techs)*
            Conversion[nation,year]
        
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zRPCC;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for tech in Techs
    end # for ec in ECs
  end # for year in years

        
end # function zRPCCRes_DtaRun

#
# Commercial
#
Base.@kwdef struct zRPCCComData
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
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  RPMSF::VariableArray{5} = ReadDisk(db,"$Outpt/RPMSF") # Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  RPMSFRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/RPMSF") # Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  zRPCC::VariableArray{5} = ReadDisk(db,"$Outpt/RPCC") # Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  zRPCCRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/RPCC") # Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  PCRetroRef::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Buildings Retrofit (Units/Year)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zRPCCCom(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; InflationNation,InflationNationRef,UnitsDS) = data
  
  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    ConversionRef[US,year] = 1/InflationNationRef[US,year]*InflationNationRef[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
    ConversionRef[CN,year] = 1/InflationNationRef[CN,year]*InflationNationRef[CN,CDYear]
  end

  UnitsDS[US] = "$CDTime \$/Driver"
  UnitsDS[CN] = "$CDTime \$/Driver"
end

function zRPCCCom_DtaRun(data,iob,nation,SceName)
  (; Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,RPMSF,RPMSFRef,zRPCC,zRPCCRef) = data
  (; CCC,Conversion,ConversionRef,PCRetroRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zRPCCRef .= zRPCC
    EUPCRef .= EUPC
    RPMSFRef .= RPMSF
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)
  enduse = 1

  for year in years, area in areas, ec in ECs, tech in Techs
    PCRetroRef[enduse,tech,ec,area,year]=sum(EUPCRef[enduse,tech,age,ec,area,year]*RPMSFRef[enduse,tech,ec,area,year] for age in Ages)
    PCRetroRef[enduse,tech,ec,area,year]=max(PCRetroRef[enduse,tech,ec,area,year],0)
  end

  for year in years
    for ec in ECs
      for tech in Techs
        @finite_math ZZZ[year] = sum(zRPCC[enduse,tech,ec,area,year]*
          PCRetroRef[enduse,tech,ec,area,year] for area in areas)/
          sum(PCRetroRef[enduse,t,e,a,year] for a in areas, e in ECs, t in Techs)*
          Conversion[nation,year]

        @finite_math CCC[year] = sum(zRPCCRef[enduse,tech,ec,area,year]*
          PCRetroRef[enduse,tech,ec,area,year] for area in areas)/
          sum(PCRetroRef[enduse,t,e,a,year] for a in areas, e in ECs, t in Techs)*
          Conversion[nation,year]

        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zRPCC;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = (zRPCC[enduse,tech,ec,area,year]*
            PCRetroRef[enduse,tech,ec,area,year])/
            sum(PCRetroRef[enduse,t,e,area,year] for e in ECs, t in Techs)*
            Conversion[nation,year]

          @finite_math CCC[year] = (zRPCCRef[enduse,tech,ec,area,year]*
            PCRetroRef[enduse,tech,ec,area,year])/
            sum(PCRetroRef[enduse,t,e,area,year] for e in ECs, t in Techs)*
            Conversion[nation,year]
        
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zRPCC;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for tech in Techs
    end # for ec in ECs
  end # for year in years

end # function zRPCCCom_DtaRun

#
# Industrial
#
Base.@kwdef struct zRPCCIndData
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
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationNationRef::VariableArray{2} = ReadDisk(RefNameDB, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zRPCC::VariableArray{5} = ReadDisk(db,"$Outpt/RPCC") # Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  zRPCCRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/RPCC") # Process Retrofit Capital Cost ($/($/Yr)) [Enduse,Tech,EC,Area]
  RPMSF::VariableArray{5} = ReadDisk(db,"$Outpt/RPMSF") # Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]
  RPMSFRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/RPMSF") # Process Retrofit Market Share Fraction by Device (1/Yr) [Enduse,Tech,EC,Area]

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  PCRetroRef::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Buildings Retrofit (Units/Year)
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zRPCCInd(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; InflationNation,InflationNationRef,UnitsDS) = data

  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    ConversionRef[US,year] = 1/InflationNationRef[US,year]*InflationNationRef[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
    ConversionRef[CN,year] = 1/InflationNationRef[CN,year]*InflationNationRef[CN,CDYear]
  end

  UnitsDS[US] = "$CDTime \$/Driver"
  UnitsDS[CN] = "$CDTime \$/Driver"
end

function zRPCCInd_DtaRun(data,iob,nation,SceName)
  (; Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,RPMSF,RPMSFRef,zRPCC,zRPCCRef) = data
  (; CCC,Conversion,ConversionRef,PCRetroRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zRPCCRef .= zRPCC
    EUPCRef .= EUPC
    RPMSFRef .= RPMSF
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)
  enduse = 1

  for year in years, area in areas, ec in ECs, tech in Techs
    PCRetroRef[enduse,tech,ec,area,year]=sum(EUPCRef[enduse,tech,age,ec,area,year]*RPMSFRef[enduse,tech,ec,area,year] for age in Ages)
    PCRetroRef[enduse,tech,ec,area,year]=max(PCRetroRef[enduse,tech,ec,area,year],0)
  end

  for year in years
    for ec in ECs
      for tech in Techs
        @finite_math ZZZ[year] = sum(zRPCC[enduse,tech,ec,area,year]*
          PCRetroRef[enduse,tech,ec,area,year] for area in areas)/
          sum(PCRetroRef[enduse,t,e,a,year] for a in areas, e in ECs, t in Techs)*
          Conversion[nation,year]

        @finite_math CCC[year] = sum(zRPCCRef[enduse,tech,ec,area,year]*
          PCRetroRef[enduse,tech,ec,area,year] for area in areas)/
          sum(PCRetroRef[enduse,t,e,a,year] for a in areas, e in ECs, t in Techs)*
          Conversion[nation,year]

        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zRPCC;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = (zRPCC[enduse,tech,ec,area,year]*
            PCRetroRef[enduse,tech,ec,area,year])/
            sum(PCRetroRef[enduse,t,e,area,year] for e in ECs, t in Techs)*
            Conversion[nation,year]

          @finite_math CCC[year] = (zRPCCRef[enduse,tech,ec,area,year]*
            PCRetroRef[enduse,tech,ec,area,year])/
            sum(PCRetroRef[enduse,t,e,area,year] for e in ECs, t in Techs)*
            Conversion[nation,year]
        
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zRPCC;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for tech in Techs
    end # for ec in ECs
  end # for year in years
        
end # function zRPCCInd_DtaRun

function zRPCC_Residential(db,iob,nation,SceName)
  data = zRPCCResData(; db)
  AssignConversions_zRPCCRes(data)
  zRPCCRes_DtaRun(data,iob,nation,SceName)
end

function zRPCC_Commercial(db,iob,nation,SceName)
  data = zRPCCComData(; db)
  AssignConversions_zRPCCCom(data)
  zRPCCCom_DtaRun(data,iob,nation,SceName)
end

function zRPCC_Industrial(db,iob,nation,SceName)
  data = zRPCCIndData(; db)
  AssignConversions_zRPCCInd(data)
  zRPCCInd_DtaRun(data,iob,nation,SceName)
end

function CreatezRPCCOutputFile(db,iob,nationkey,SceName)
  filename = "zRPCC-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zRPCC_DtaControl(db,SceName)
  data = zRPCCResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zRPCC_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Enduse;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zRPCC_Residential(db,iob,nation,SceName)
      zRPCC_Commercial(db,iob,nation,SceName)
      zRPCC_Industrial(db,iob,nation,SceName)

      CreatezRPCCOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
