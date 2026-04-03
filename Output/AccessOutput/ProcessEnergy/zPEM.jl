#
# zPEM.jl
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
Base.@kwdef struct zPEMResData
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
  zPEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)
  zPEMRef::VariableArray{3} = ReadDisk(RefNameDB,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zPEMRes(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; InflationNation,InflationNationRef,UnitsDS) = data
  
  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1
    ConversionRef[US,year] = 1
    Conversion[CN,year] = 1
    ConversionRef[CN,year] = 1
  end

  UnitsDS[US] = "(\$/mmBtu)"
  UnitsDS[CN] = "(\$/mmBtu)"
end

function zPEMRes_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year,SceName) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,zPEM,zPEMRef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zPEMRef .= zPEM
    EUPCRef .= EUPC
  end

  years = [Last]
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for ec in ECs
    for enduse in Enduses
      for year in years
        @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas)/
          sum(EUPC[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in Techs)*
          Conversion[nation,year]

          @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in Techs)*
          ConversionRef[nation,year]

        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zPEM;", NationDS[nation],";",ECDS[ec],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = (zPEM[enduse,ec,area]*
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs))/
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs)*
            Conversion[nation,year]

          @finite_math CCC[year] = (zPEMRef[enduse,ec,area]*
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs))/
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs)*
            ConversionRef[nation,year]
        
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zPEM;", AreaDS[area],";",ECDS[ec],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for year in years
    end # for enduse in Enduses
  end # for ec in ECs


  for enduse in Enduses
    for year in years
      @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas, ec in ECs)/
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, area in areas, ec in ECs)*
        Conversion[nation,year]

      @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas, ec in ECs)/
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, area in areas, ec in ECs)*
        ConversionRef[nation,year]
  
      if ZZZ[year] != 0 || CCC[year] != 0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zPEM;", NationDS[nation],";Residential;",
          EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
      end

      for area in areas
        @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for ec in ECs)/
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, ec in ECs)*
        Conversion[nation,year]

      @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for ec in ECs)/
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, ec in ECs)*
        ConversionRef[nation,year]
  
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zPEM;", AreaDS[area],";Residential;",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses
        
end # function zPEMRes_DtaRun

#
# Commercial
#
Base.@kwdef struct zPEMComData
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
  zPEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)
  zPEMRef::VariableArray{3} = ReadDisk(RefNameDB,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zPEMCom(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; InflationNation,InflationNationRef,UnitsDS) = data
  
  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1
    ConversionRef[US,year] = 1
    Conversion[CN,year] = 1
    ConversionRef[CN,year] = 1
  end

  UnitsDS[US] = "(\$/mmBtu)"
  UnitsDS[CN] = "(\$/mmBtu)"
end

function zPEMCom_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,zPEM,zPEMRef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ,SceName) = data

  if BaseSw != 0
    zPEMRef .= zPEM
    EUPCRef .= EUPC
  end

  years = [Last]
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for ec in ECs
    for enduse in Enduses
      for year in years
        @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas)/
          sum(EUPC[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in Techs)*
          Conversion[nation,year]

          @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in Techs)*
          ConversionRef[nation,year]

        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zPEM;", NationDS[nation],";",ECDS[ec],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = (zPEM[enduse,ec,area]*
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs))/
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs)*
            Conversion[nation,year]

          @finite_math CCC[year] = (zPEMRef[enduse,ec,area]*
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs))/
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs)*
            ConversionRef[nation,year]
        
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zPEM;", AreaDS[area],";",ECDS[ec],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for year in years
    end # for enduse in Enduses
  end # for ec in ECs


  for enduse in Enduses
    for year in years
      @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas, ec in ECs)/
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, area in areas, ec in ECs)*
        Conversion[nation,year]

      @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas, ec in ECs)/
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, area in areas, ec in ECs)*
        ConversionRef[nation,year]
  
      if ZZZ[year] != 0 || CCC[year] != 0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zPEM;", NationDS[nation],";Commercial;",
          EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
      end

      for area in areas
        @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for ec in ECs)/
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, ec in ECs)*
        Conversion[nation,year]

      @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for ec in ECs)/
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, ec in ECs)*
        ConversionRef[nation,year]
  
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zPEM;", AreaDS[area],";Commercial;",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses
        
end # function zPEMCom_DtaRun

#
# Industrial
#
Base.@kwdef struct zPEMIndData
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
  zPEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)
  zPEMRef::VariableArray{3} = ReadDisk(RefNameDB,"$CalDB/PEM") # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zPEMInd(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; InflationNation,InflationNationRef,UnitsDS) = data

  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1
    ConversionRef[US,year] = 1
    Conversion[CN,year] = 1
    ConversionRef[CN,year] = 1
  end

  UnitsDS[US] = "(\$/mmBtu)"
  UnitsDS[CN] = "(\$/mmBtu)"
end

function zPEMInd_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,zPEM,zPEMRef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ,SceName) = data

  if BaseSw != 0
    zPEMRef .= zPEM
    EUPCRef .= EUPC
  end
  years = [Last]
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for ec in ECs
    for enduse in Enduses
      for year in years
        @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas)/
          sum(EUPC[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in Techs)*
          Conversion[nation,year]

          @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in Techs)*
          ConversionRef[nation,year]

        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zPEM;", NationDS[nation],";",ECDS[ec],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = (zPEM[enduse,ec,area]*
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs))/
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs)*
            Conversion[nation,year]

          @finite_math CCC[year] = (zPEMRef[enduse,ec,area]*
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs))/
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs)*
            ConversionRef[nation,year]
        
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zPEM;", AreaDS[area],";",ECDS[ec],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for year in years
    end # for enduse in Enduses
  end # for ec in ECs


  for enduse in Enduses
    for year in years
      @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas, ec in ECs)/
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, area in areas, ec in ECs)*
        Conversion[nation,year]

      @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for area in areas, ec in ECs)/
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, area in areas, ec in ECs)*
        ConversionRef[nation,year]
  
      if ZZZ[year] != 0 || CCC[year] != 0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zPEM;", NationDS[nation],";Industrial;",
          EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
      end

      for area in areas
        @finite_math ZZZ[year] = sum(zPEM[enduse,ec,area]*
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for ec in ECs)/
        sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, ec in ECs)*
        Conversion[nation,year]

      @finite_math CCC[year] = sum(zPEMRef[enduse,ec,area]*
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs) for ec in ECs)/
        sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, tech in Techs, ec in ECs)*
        ConversionRef[nation,year]
  
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zPEM;", AreaDS[area],";Industrial;",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses
        
end # function zPEMInd_DtaRun

function zPEM_Residential(db,iob,nation)
  data = zPEMResData(; db)
  AssignConversions_zPEMRes(data)
  zPEMRes_DtaRun(data,iob,nation)
end

function zPEM_Commercial(db,iob,nation)
  data = zPEMComData(; db)
  AssignConversions_zPEMCom(data)
  zPEMCom_DtaRun(data,iob,nation)
end

function zPEM_Industrial(db,iob,nation)
  data = zPEMIndData(; db)
  AssignConversions_zPEMInd(data)
  zPEMInd_DtaRun(data,iob,nation)
end

function CreatezPEMOutputFile(db,iob,nationkey,SceName)
  filename = "zPEM-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zPEM_DtaControl(db)
  data = zPEMResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zPEM_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Area;Sector;Enduse;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPEM_Residential(db,iob,nation)
      zPEM_Commercial(db,iob,nation)
      zPEM_Industrial(db,iob,nation)

      CreatezPEMOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zPEM_DtaControl(DB)
end
