#
# zCUF.jl - Write Enduse Demands for Access Database
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

Base.@kwdef struct zCUF_RControl
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
  zCUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  zCUFRef::VariableArray{5} = ReadDisk(RefNameDB,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUF_AssignConversions_Res(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "\$/Yr/\$/Yr"
  UnitsDS[CN] = "\$/Yr/\$/Yr"
end

function zCUFRes_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20
  years = [Last]
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
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
Base.@kwdef struct zCUF_CControl
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
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
  zCUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  zCUFRef::VariableArray{5} = ReadDisk(RefNameDB,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUF_AssignConversions_Com(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "\$/Yr/\$/Yr"
  UnitsDS[CN] = "\$/Yr/\$/Yr"
end

function zCUFCom_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20

  years = [Last]
  areas = findall(ANMap[:,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
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
Base.@kwdef struct zCUF_IControl
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
  zCUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  zCUFRef::VariableArray{5} = ReadDisk(RefNameDB,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUF_AssignConversions_Ind(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "\$/Yr/\$/Yr"
  UnitsDS[CN] = "\$/Yr/\$/Yr"
end

function zCUFInd_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20

  years = [Last]
  areas = findall(ANMap[:,nation] .== 1)

  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
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
Base.@kwdef struct zCUF_TControl
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
  zCUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  zCUFRef::VariableArray{5} = ReadDisk(RefNameDB,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUF_AssignConversions_Trans(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "\$/Yr/\$/Yr"
  UnitsDS[CN] = "\$/Yr/\$/Yr"
end

function zCUFTrans_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20

  years = [Last]
  areas = findall(ANMap[:,nation] .== 1)

  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            end
          end
        end
      end
    end 
  end
end

function zCUF_Residential(db,iob,nation)
  data = zCUF_RControl(; db)
  zCUF_AssignConversions_Res(data)
  zCUFRes_DtaRun(data,iob,nation)
end

function zCUF_Commercial(db,iob,nation)
  data = zCUF_CControl(; db)
  zCUF_AssignConversions_Com(data)
  zCUFCom_DtaRun(data,iob,nation)
end

function zCUF_Industrial(db,iob,nation)
  data = zCUF_IControl(; db)
  zCUF_AssignConversions_Ind(data)
  zCUFInd_DtaRun(data,iob,nation)
end

function zCUF_Transportation(db,iob,nation)
  data = zCUF_TControl(; db)
  zCUF_AssignConversions_Trans(data)
  zCUFTrans_DtaRun(data,iob,nation)
end

function zCUF_CreateOutputFile(db,iob,nationkey,SceName)
  filename = "zCUF-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zCUF_DtaControl(db)
  data = zCUF_RControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zCUF_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Enduse;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zCUF_Residential(db,iob,nation)
      zCUF_Commercial(db,iob,nation)
      zCUF_Industrial(db,iob,nation)
      zCUF_Transportation(db,iob,nation)

      zCUF_CreateOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zCUF_DtaControl(DB)
end
