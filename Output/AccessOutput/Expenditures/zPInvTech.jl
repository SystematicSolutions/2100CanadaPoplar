#
# zPInvTech.jl - Write Process Investments for Access Database
#

Base.@kwdef struct zPInvTechResData
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
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/PInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 
  zPInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zPInvTechRes(data)
  (; Nation,Years,CDYear,Conversion,InflationNation,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
  end

  UnitsDS[US] = " US M\$/Yr"
  UnitsDS[CN] = " CN M\$/Yr"
end

function zPInvTechRes_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPInvTech,zPInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    zPInvTechRef .= zPInvTech
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zPInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zPInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
              
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech
        end # for ec
      end # for area
    end #for year        
  end # for enduse

end # function zPInvTechRes_DtaRun

#
# Commercial
#
Base.@kwdef struct zPInvTechComData
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
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/PInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 
  zPInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zPInvTechCom(data)
  (; Nation,Years,CDYear,Conversion,InflationNation,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
  end

  UnitsDS[US] = " US M\$/Yr"
  UnitsDS[CN] = " CN M\$/Yr"
end

function zPInvTechCom_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPInvTech,zPInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    zPInvTechRef .= zPInvTech
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
              for fuel in Fuels
                ZZZ[year] = zPInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
                CCC[year] = zPInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
                  
                if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
                  zData = @sprintf("%.6E",ZZZ[year])
                  zInitial = @sprintf("%.6E",CCC[year])
                  println(iob,"zPInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                    EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
                end
              end
          end # for tech
        end # for ec
      end # for area
    end #for year
  end # for enduse

end # function zPInvTechCom_DtaRun

#
# Industrial
#
Base.@kwdef struct zPInvTechIndData
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
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/PInvTech") #[Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 
  zPInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PInvTech") #[Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zPInvTechInd(data)
  (; Nation,Years,CDYear,Conversion,InflationNation,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
  end

  UnitsDS[US] = " US M\$/Yr"
  UnitsDS[CN] = " CN M\$/Yr"
end

function zPInvTechInd_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPInvTech,zPInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    zPInvTechRef .= zPInvTech
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zPInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zPInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
              
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech
        end # for ec
      end # for area
    end #for year        
  end # for enduse
end # function zPInvTechInd_DtaRun

#
# Transportation
#
Base.@kwdef struct zPInvTechTransData
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
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/PInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 
  zPInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zPInvTechTrans(data)
  (; Nation,Years,CDYear,Conversion,InflationNation,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1/InflationNation[US,year]*InflationNation[US,CDYear]
    Conversion[CN,year] = 1/InflationNation[CN,year]*InflationNation[CN,CDYear]
  end

  UnitsDS[US] = " US M\$/Yr"
  UnitsDS[CN] = " CN M\$/Yr"
end

function zPInvTechTrans_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zPInvTech,zPInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    zPInvTechRef .= zPInvTech
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zPInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
            CCC[year] = zPInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
            
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"zPInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
            end
          end # for tech
        end # for ec
      end # for area
    end #for year
  end # for enduse
end # function zPInvTechTrans_DtaRun

function zPInvTech_Residential(db,iob,nation,SceName)
  data = zPInvTechResData(; db)
  AssignConversions_zPInvTechRes(data)
  zPInvTechRes_DtaRun(data,iob,nation,SceName)
end

function zPInvTech_Commercial(db,iob,nation,SceName)
  data = zPInvTechComData(; db)
  AssignConversions_zPInvTechCom(data)
  zPInvTechCom_DtaRun(data,iob,nation,SceName)
end

function zPInvTech_Industrial(db,iob,nation,SceName)
  data = zPInvTechIndData(; db)
  AssignConversions_zPInvTechInd(data)
  zPInvTechInd_DtaRun(data,iob,nation,SceName)
end

function zPInvTech_Transport(db,iob,nation,SceName)
  data = zPInvTechTransData(; db)
  AssignConversions_zPInvTechTrans(data)
  zPInvTechTrans_DtaRun(data,iob,nation,SceName)
end

function CreatePInvTechOutputFile(db,iob,nationkey,SceName)
  filename = "zPInvTech-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zPInvTech_DtaControl(db,SceName)
  data = zPInvTechResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zPInvTech_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Enduse;Technology;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPInvTech_Residential(db,iob,nation,SceName)
      zPInvTech_Commercial(db,iob,nation,SceName)
      zPInvTech_Industrial(db,iob,nation,SceName)
      zPInvTech_Transport(db,iob,nation,SceName)

      CreatePInvTechOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
