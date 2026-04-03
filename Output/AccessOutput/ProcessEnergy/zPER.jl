#
# zPER.jl
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
Base.@kwdef struct zPERResData
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
  zPER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  zPERRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)

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

function AssignConversions_zPERRes(data)
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

function zPERRes_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPER,zPERRef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zPERRef .= zPER
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            @finite_math ZZZ[year] = zPER[enduse,tech,ec,area,year]*Conversion[nation,year]
            @finite_math CCC[year] = zPERRef[enduse,tech,ec,area,year]*ConversionRef[nation,year]
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPER;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech in Techs
        end # for ec in ECs
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses

        
end # function zPERRes_DtaRun

#
# Commercial
#
Base.@kwdef struct zPERComData
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
  zPER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  zPERRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)

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

function AssignConversions_zPERCom(data)
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

function zPERCom_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPER,zPERRef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zPERRef .= zPER
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            @finite_math ZZZ[year] = zPER[enduse,tech,ec,area,year]*Conversion[nation,year]
            @finite_math CCC[year] = zPERRef[enduse,tech,ec,area,year]*ConversionRef[nation,year]
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPER;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech in Techs
        end # for ec in ECs
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses

end # function zPERCom_DtaRun

#
# Industrial
#
Base.@kwdef struct zPERIndData
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
  zPER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  zPERRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)

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

function AssignConversions_zPERInd(data)
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

function zPERInd_DtaRun(data,iob,nation)
  (; Ages,Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPER,zPERRef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zPERRef .= zPER
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            @finite_math ZZZ[year] = zPER[enduse,tech,ec,area,year]*Conversion[nation,year]
            @finite_math CCC[year] = zPERRef[enduse,tech,ec,area,year]*ConversionRef[nation,year]
          
            if ZZZ[year] != 0 || CCC[year] != 0
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPER;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech in Techs
        end # for ec in ECs
      end # for area in areas
    end # for year in years
  end # for enduse in Enduses
        
end # function zPERInd_DtaRun

function zPER_Residential(db,iob,nation)
  data = zPERResData(; db)
  AssignConversions_zPERRes(data)
  zPERRes_DtaRun(data,iob,nation)
end

function zPER_Commercial(db,iob,nation)
  data = zPERComData(; db)
  AssignConversions_zPERCom(data)
  zPERCom_DtaRun(data,iob,nation)
end

function zPER_Industrial(db,iob,nation)
  data = zPERIndData(; db)
  AssignConversions_zPERInd(data)
  zPERInd_DtaRun(data,iob,nation)
end

function CreatezPEROutputFile(db,iob,nationkey,SceName)
  filename = "zPER-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zPER_DtaControl(db)
  data = zPERResData(; db)
  (; Nation,Nations,SceName) = data
  (; NationOutputMap) = data

  @info "zPER_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Enduse;Units;zData;zInitial")       

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPER_Residential(db,iob,nation)
      zPER_Commercial(db,iob,nation)
      zPER_Industrial(db,iob,nation)

      CreatezPEROutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zPER_DtaControl(DB)
end
