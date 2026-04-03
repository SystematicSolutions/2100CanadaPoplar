#
# zCUFAll.jl - Write Enduse Demands for Access Database
#

Base.@kwdef struct zCUFAll_RControl
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

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUFAll_AssignConversions_Res(data)
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

function zCUFAllRes_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20
  years = collect(Yr(2010):Yr(2025))
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            # if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            # end
          end
        end
      end
    end 
  end
end

#
# Commercial
#
Base.@kwdef struct zCUFAll_CControl
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

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUFAll_AssignConversions_Com(data)
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

function zCUFAllCom_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20

  years = collect(Yr(2010):Yr(2025))
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            # if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            # end
          end
        end
      end
    end 
  end
end

#
# Industrial except for Oil and Gas
#
Base.@kwdef struct zCUFAll_IControl
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

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUFAll_AssignConversions_Ind(data)
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

function zCUFAllInd_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20

  years = collect(Yr(2010):Yr(2025))
  areas = findall(ANMap[Areas,nation] .== 1)

  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            # if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            # end
          end
        end
      end
    end 
  end
end

#
# Industrial except for Oil and Gas
#
Base.@kwdef struct zCUFAll_TControl
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

  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zCUFAll_AssignConversions_Trans(data)
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

function zCUFAllTrans_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zCUF,zCUFRef,ZZZ) = data

  if BaseSw != 0
    @. zCUFRef = zCUF
  end

  Min=0.80
  Max=1.20

  years = collect(Yr(2010):Yr(2025))
  areas = findall(ANMap[Areas,nation] .== 1)

  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zCUF[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zCUFRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            # if ZZZ[year] < Min || ZZZ[year] > Max
              println(iob,"zCUF;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                TechDS[tech],";",EnduseDS[enduse],";",UnitsDS[nation],";",zData,";",zInitial)
            # end
          end
        end
      end
    end 
  end
end

function zCUFAll_Residential(db,iob,nation,SceName)
  data = zCUFAll_RControl(; db)
  zCUFAll_AssignConversions_Res(data)
  zCUFAllRes_DtaRun(data,iob,nation,SceName)
end

function zCUFAll_Commercial(db,iob,nation,SceName)
  data = zCUFAll_CControl(; db)
  zCUFAll_AssignConversions_Com(data)
  zCUFAllCom_DtaRun(data,iob,nation,SceName)
end

function zCUFAll_Industrial(db,iob,nation,SceName)
  data = zCUFAll_IControl(; db)
  zCUFAll_AssignConversions_Ind(data)
  zCUFAllInd_DtaRun(data,iob,nation,SceName)
end

function zCUFAll_Transportation(db,iob,nation,SceName)
  data = zCUFAll_TControl(; db)
  zCUFAll_AssignConversions_Trans(data)
  zCUFAllTrans_DtaRun(data,iob,nation,SceName)
end

function zCUFAll_CreateOutputFile(db,iob,nationkey,SceName)
  filename = "zCUFAll-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zCUFAll_DtaControl(db,SceName)
  data = zCUFAll_RControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zCUFAll_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Enduse;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zCUFAll_Residential(db,iob,nation,SceName)
      zCUFAll_Commercial(db,iob,nation,SceName)
      zCUFAll_Industrial(db,iob,nation,SceName)
      zCUFAll_Transportation(db,iob,nation,SceName)

      zCUFAll_CreateOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
