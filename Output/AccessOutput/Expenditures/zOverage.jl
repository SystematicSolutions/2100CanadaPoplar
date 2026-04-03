#
# zOverage.jl - Write Device Investments for Access Database
#

Base.@kwdef struct zOverageData
  db::String
  
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
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
  zOverage::VariableArray{2} = ReadDisk(db,"SOutput/Overage") #[Area,Year] GHG Market Overage (eCO2 Tonnes/Yr)
  zOverageRef::VariableArray{2} = ReadDisk(RefNameDB,"SOutput/Overage") #[Area,Year] GHG Market Overage (eCO2 Tonnes/Yr)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zOverage(data)
  (; Nation,Years,CDYear,Conversion,InflationNation,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")

  for year in Years
    Conversion[US,year] = 1
    Conversion[CN,year] = 1
  end

  UnitsDS[US] = "eCO2 Tonnes/Yr"
  UnitsDS[CN] = "eCO2 Tonnes/Yr"
end

function zOverage_DtaRun(data,nation,nationkey,SceName)
  (; Area,AreaDS,ECC,ECCDS,ECCs) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zOverage,zOverageRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zOverageRef .= zOverage
  end
  
  for area in areas
    for year in years
      ZZZ[year] = zOverage[area,year]*Conversion[nation,year]
      CCC[year] = zOverageRef[area,year]*Conversion[nation,year]
      if ZZZ[year] != 0.0 || CCC[year] != -0.0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zOverage;",Year[year],";",AreaDS[area],";",
          UnitsDS[nation],";",zData,";",zInitial)
      end
    end # for year
  end #for area

  filename = "zOverage-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end


end # function zOverage_DtaRun


function zOverage_DtaControl(db,SceName)
  data = zOverageData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zOverage_DtaControl"
  AssignConversions_zOverage(data)
  for nation in Nations
    if NationOutputMap[nation] == 1
      zOverage_DtaRun(data,nation,Nation[nation],SceName)
    end
  end

end
