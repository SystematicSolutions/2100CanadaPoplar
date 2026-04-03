#
# zPERA.jl
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
Base.@kwdef struct zPERAResData
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
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPERA::VariableArray{5} = ReadDisk(db,"$Outpt/PERA") # Process Energy Rqmt. Addition. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  zPERARef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PERA") # Process Energy Rqmt. Addition. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]

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

function AssignConversions_zPERARes(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; UnitsDS) = data
  
  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    ConversionRef[US,year] = 1.0
    Conversion[CN,year] = 1.0
    ConversionRef[CN,year] = 1.0
  end

  UnitsDS[US] = "mmBtu/YR"
  UnitsDS[CN] = "mmBtu/YR"
end

function zPERARes_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPERA,zPERARef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ,SceName) = data

  if BaseSw != 0
    zPERARef .= zPERA
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            @finite_math ZZZ[year] = zPERA[enduse,tech,ec,area,year]*Conversion[nation,year]
            @finite_math CCC[year] = zPERARef[enduse,tech,ec,area,year]*ConversionRef[nation,year]
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPERA;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech in Techs
        end # for ec in ECs
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses

        
end # function zPERARes_DtaRun

#
# Commercial
#
Base.@kwdef struct zPERAComData
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
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPERA::VariableArray{5} = ReadDisk(db,"$Outpt/PERA") # Process Energy Rqmt. Addition. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  zPERARef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PERA") # Process Energy Rqmt. Addition. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
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

function AssignConversions_zPERACom(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; UnitsDS) = data
  
  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    ConversionRef[US,year] = 1.0
    Conversion[CN,year] = 1.0
    ConversionRef[CN,year] = 1.0
  end

  UnitsDS[US] = "mmBtu/YR"
  UnitsDS[CN] = "mmBtu/YR"
end

function zPERACom_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year,SceName) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPERA,zPERARef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zPERARef .= zPERA
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            @finite_math ZZZ[year] = zPERA[enduse,tech,ec,area,year]*Conversion[nation,year]
            @finite_math CCC[year] = zPERARef[enduse,tech,ec,area,year]*ConversionRef[nation,year]
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPERA;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech in Techs
        end # for ec in ECs
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses

end # function zPERACom_DtaRun

#
# Industrial
#
Base.@kwdef struct zPERAIndData
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
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPERA::VariableArray{5} = ReadDisk(db,"$Outpt/PERA") # Process Energy Rqmt. Addition. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
  zPERARef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PERA") # Process Energy Rqmt. Addition. (mmBtu/Yr/Yr) [Enduse,Tech,EC,Area]
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

function AssignConversions_zPERAInd(data)
  (; Nation,Years) = data
  (; CDTime,CDYear,Conversion,ConversionRef) = data
  (; UnitsDS) = data

  KJBtu = 1.054615

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1.0
    ConversionRef[US,year] = 1.0
    Conversion[CN,year] = 1.0
    ConversionRef[CN,year] = 1.0
  end

  UnitsDS[US] = "mmBtu/YR"
  UnitsDS[CN] = "mmBtu/YR"
end

function zPERAInd_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPERA,zPERARef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ,SceName) = data

  if BaseSw != 0
    zPERARef .= zPERA
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            @finite_math ZZZ[year] = zPERA[enduse,tech,ec,area,year]*Conversion[nation,year]
            @finite_math CCC[year] = zPERARef[enduse,tech,ec,area,year]*ConversionRef[nation,year]
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPERA;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech in Techs
        end # for ec in ECs
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses
        
end # function zPERAInd_DtaRun

function zPERA_Residential(db,iob,nation)
  data = zPERAResData(; db)
  AssignConversions_zPERARes(data)
  zPERARes_DtaRun(data,iob,nation)
end

function zPERA_Commercial(db,iob,nation)
  data = zPERAComData(; db)
  AssignConversions_zPERACom(data)
  zPERACom_DtaRun(data,iob,nation)
end

function zPERA_Industrial(db,iob,nation)
  data = zPERAIndData(; db)
  AssignConversions_zPERAInd(data)
  zPERAInd_DtaRun(data,iob,nation)
end

function CreatezPERAOutputFile(db,iob,nationkey,SceName)
  filename = "zPERA-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zPERA_DtaControl(db)
  data = zPERAResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zPERA_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Enduse;Units;zData;zInitial")       

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPERA_Residential(db,iob,nation)
      zPERA_Commercial(db,iob,nation)
      zPERA_Industrial(db,iob,nation)

      CreatezPERAOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
