#
# zTrDERV.jl
#

#
# Transportation
#
Base.@kwdef struct zTrDERVTransData
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
  Vintage::SetArray = ReadDisk(db,"$Input/VintageKey")
  VintageDS::SetArray = ReadDisk(db,"$Input/VintageDS")
  Vintages::Vector{Int} = collect(Select(Vintage))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zTrDERV::VariableArray{6} = ReadDisk(db,"$Outpt/DERV") # Energy Requirement by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]
  zTrDERVRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DERV") # Energy Requirement by Vintage (mmBtu/YR) [Enduse,Tech,EC,Area,Vintage]

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  ConversionRef::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zTrDERVTrans(data)
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

function zTrDERVTrans_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Nation,NationDS,Tech,TechDS,Techs,Vintage,Vintages,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zTrDERV,zTrDERVRef) = data
  (; CCC,Conversion,ConversionRef,UnitsDS,ZZZ) = data

  if BaseSw != 0
    zTrDERVRef .= zTrDERV
  end

  selected_years = [2020, 2030, 2040, 2050]
  years = [Yr(year) for year in selected_years if Yr(year) <= length(Year)]

  area = Select(Area,"ON")
  ecs = Select(EC,["Passenger","Freight"])
  
  for enduse in Enduses
    for year in years
      # for area in areas
        for ec in ecs
          for tech in Techs
            for vintage in Vintages
              @finite_math ZZZ[year] = zTrDERV[enduse,tech,ec,area,vintage,year]*Conversion[nation,year]
              @finite_math CCC[year] = zTrDERVRef[enduse,tech,ec,area,vintage,year]*ConversionRef[nation,year]
            
              if ZZZ[year] != 0 || CCC[year] != 0
                zData = @sprintf("%.6E",ZZZ[year])
                zInitial = @sprintf("%.6E",CCC[year])
                println(iob,"zTrDERV;", Year[year],";", AreaDS[area],";",ECDS[ec],";",TechDS[tech],";",
                  EnduseDS[enduse],";",Vintage[vintage],";",UnitsDS[nation],";",zData,";",zInitial)
              end
            end # for vintage in Vintages
          end # for tech in Techs
        end # for ec in ECs
      # end # for area in areas
    end # for year in years
  end # for enduse in Enduses

end # function zTrDERVTrans_DtaRun


function zTrDERV_Transportation(db,iob,nation,SceName)
  data = zTrDERVTransData(; db)
  AssignConversions_zTrDERVTrans(data)
  zTrDERVTrans_DtaRun(data,iob,nation,SceName)
end

function CreatezTrDERVOutputFile(db,iob,nationkey,SceName)
  filename = "zTrDERV-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrDERV_DtaControl(db,SceName)
  data = zTrDERVTransData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zTrDERV_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Tech;Enduse;Vintage;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zTrDERV_Transportation(db,iob,nation,SceName)

      CreatezTrDERVOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
