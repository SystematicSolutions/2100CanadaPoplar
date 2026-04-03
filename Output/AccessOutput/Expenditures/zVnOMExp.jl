#
# zVnOMExp.jl - Write Device Investments for Access Database
#

Base.@kwdef struct zVnOMExpData
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
  zVnOMExp::VariableArray{3} = ReadDisk(db,"SOutput/VnOMExp") #[ECC,Area,Year] Venting Reduction O&M Expenses (M$/Yr)
  zVnOMExpRef::VariableArray{3} = ReadDisk(RefNameDB,"SOutput/VnOMExp") #[ECC,Area,Year] Venting Reduction O&M Expenses (M$/Yr)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zVnOMExp(data)
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

function zVnOMExp_DtaRun(data,nation,nationkey,SceName)
  (; Area,AreaDS,ECC,ECCDS,ECCs) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zVnOMExp,zVnOMExpRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zVnOMExpRef .= zVnOMExp
  end
  
  for ecc in ECCs
    for area in areas
      for year in years
        ZZZ[year] = zVnOMExp[ecc,area,year]*Conversion[nation,year]
        CCC[year] = zVnOMExpRef[ecc,area,year]*Conversion[nation,year]
        if ZZZ[year] != 0.0 || CCC[year] != -0.0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zVnOMExp;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
            CDTime,UnitsDS[nation],";",zData,";",zInitial)
        end
      end # for year
    end #for area
  end # for ecc

  filename = "zVnOMExp-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end


end # function zVnOMExp_DtaRun


function zVnOMExp_DtaControl(db,SceName)
  data = zVnOMExpData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zVnOMExp_DtaControl"
  AssignConversions_zVnOMExp(data)
  for nation in Nations
    if NationOutputMap[nation] == 1
      zVnOMExp_DtaRun(data,nation,Nation[nation],SceName)
    end
  end

end
