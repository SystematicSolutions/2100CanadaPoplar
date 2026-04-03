#
# zDEEA.jl
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
Base.@kwdef struct zDEEAResData
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
  zDEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  zDEEARef::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDEEARes(data)
  (; Nation,Years) = data
  (; UnitsDS) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  UnitsDS[US] = "Btu/Btu"
  UnitsDS[CN] = "J/J"
end

function zDEEARes_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,zDEEA,zDEEARef) = data
  (; CCC,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zDEEARef .= zDEEA
    EUPCRef .= EUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        for year in years
          @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for area in areas)/
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, area in areas)

            @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for area in areas)/
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, area in areas)

          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zDEEA;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end

          for area in areas
            @finite_math ZZZ[year] = (zDEEA[enduse,tech,ec,area,year]*
              sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages))/
              sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages)

            @finite_math CCC[year] = (zDEEARef[enduse,tech,ec,area,year]*
              sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages))/
              sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages)
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zDEEA;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for area in areas
        end # for year in years
      end # for tech in Techs
    end # for enduse in Enduses
  end # for ec in ECs


  for enduse in Enduses
    for tech in Techs
      for year in years
        @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for area in areas, ec in ECs)/
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, area in areas, ec in ECs)

        @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for area in areas, ec in ECs)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, area in areas, ec in ECs)
    
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zDEEA;", Year[year],";", NationDS[nation],";Residential;",TechDS[tech],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for ec in ECs)/
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, ec in ECs)

        @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for ec in ECs)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, ec in ECs)
    
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zDEEA;", Year[year],";", AreaDS[area],";Residential;",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for year in years
    end # for tech in Techs
  end # for enduse in Enduses
        
end # function zDEEARes_DtaRun

#
# Commercial
#
Base.@kwdef struct zDEEAComData
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
  zDEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  zDEEARef::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDEEACom(data)
  (; Nation,Years) = data
  (; UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  UnitsDS[US] = "Btu/Btu"
  UnitsDS[CN] = "J/J"
end

function zDEEACom_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,zDEEA,zDEEARef) = data
  (; CCC,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zDEEARef .= zDEEA
    EUPCRef .= EUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        for year in years
          @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for area in areas)/
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, area in areas)

            @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for area in areas)/
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, area in areas)

          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zDEEA;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end

          for area in areas
            @finite_math ZZZ[year] = (zDEEA[enduse,tech,ec,area,year]*
              sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages))/
              sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages)

            @finite_math CCC[year] = (zDEEARef[enduse,tech,ec,area,year]*
              sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages))/
              sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages)
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zDEEA;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for area in areas
        end # for year in years
      end # for tech in Techs
    end # for enduse in Enduses
  end # for ec in ECs


  for enduse in Enduses
    for tech in Techs
      for year in years
        @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for area in areas, ec in ECs)/
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, area in areas, ec in ECs)

        @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for area in areas, ec in ECs)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, area in areas, ec in ECs)
    
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zDEEA;", Year[year],";", NationDS[nation],";Commercial;",TechDS[tech],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for ec in ECs)/
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, ec in ECs)

        @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for ec in ECs)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, ec in ECs)
    
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zDEEA;", Year[year],";", AreaDS[area],";Commercial;",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for year in years
    end # for tech in Techs
  end # for enduse in Enduses
        
end # function zDEEACom_DtaRun

#
# Industrial
#
Base.@kwdef struct zDEEAIndData
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
  zDEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  zDEEARef::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDEEAInd(data)
  (; Nation) = data
  (; UnitsDS) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  UnitsDS[US] = "Btu/Btu"
  UnitsDS[CN] = "J/J"
end

function zDEEAInd_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,EUPC,EUPCRef,zDEEA,zDEEARef) = data
  (; CCC,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zDEEARef .= zDEEA
    EUPCRef .= EUPC
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        for year in years
          @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for area in areas)/
            sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, area in areas)

            @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for area in areas)/
            sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, area in areas)

          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zDEEA;", Year[year],";", NationDS[nation],";",ECDS[ec],";",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end

          for area in areas
            @finite_math ZZZ[year] = (zDEEA[enduse,tech,ec,area,year]*
              sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages))/
              sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages)

            @finite_math CCC[year] = (zDEEARef[enduse,tech,ec,area,year]*
              sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages))/
              sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages)
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zDEEA;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for area in areas
        end # for year in years
      end # for tech in Techs
    end # for enduse in Enduses
  end # for ec in ECs


  for enduse in Enduses
    for tech in Techs
      for year in years
        @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for area in areas, ec in ECs)/
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, area in areas, ec in ECs)

        @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for area in areas, ec in ECs)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, area in areas, ec in ECs)
    
        if ZZZ[year] != 0 || CCC[year] != 0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zDEEA;", Year[year],";", NationDS[nation],";Industrial;",TechDS[tech],";",
            EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
        end

        for area in areas
          @finite_math ZZZ[year] = sum(zDEEA[enduse,tech,ec,area,year]*
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages) for ec in ECs)/
          sum(EUPC[enduse,tech,age,ec,area,year] for age in Ages, ec in ECs)

        @finite_math CCC[year] = sum(zDEEARef[enduse,tech,ec,area,year]*
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages) for ec in ECs)/
          sum(EUPCRef[enduse,tech,age,ec,area,year] for age in Ages, ec in ECs)
    
          if ZZZ[year] != 0 || CCC[year] != 0
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"zDEEA;", Year[year],";", AreaDS[area],";Industrial;",TechDS[tech],";",
              EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
          end
        end # for area in areas
      end # for year in years
    end # for tech in Techs
  end # for enduse in Enduses
        
end # function zDEEAInd_DtaRun

function zDEEA_Residential(db,iob,nation)
  data = zDEEAResData(; db)
  AssignConversions_zDEEARes(data)
  zDEEARes_DtaRun(data,iob,nation)
end

function zDEEA_Commercial(db,iob,nation)
  data = zDEEAComData(; db)
  AssignConversions_zDEEACom(data)
  zDEEACom_DtaRun(data,iob,nation)
end

function zDEEA_Industrial(db,iob,nation)
  data = zDEEAIndData(; db)
  AssignConversions_zDEEAInd(data)
  zDEEAInd_DtaRun(data,iob,nation)
end

function CreatezDEEAOutputFile(db,iob,nationkey,SceName)
  filename = "zDEEA-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDEEA_DtaControl(db)
  data = zDEEAResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zDEEA_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Enduse;Units;zData;zInitial")       

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDEEA_Residential(db,iob,nation)
      zDEEA_Commercial(db,iob,nation)
      zDEEA_Industrial(db,iob,nation)

      CreatezDEEAOutputFile(db,iob,Nation[nation],SceName)
  
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
zDEEA_DtaControl(DB)
end
