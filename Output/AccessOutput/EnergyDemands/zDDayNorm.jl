#
# zDDayNorm.jl - Write Enduse Demands for Access Database
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

Base.@kwdef struct zDDayNorm_RControl
  db::String
  
  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  zDDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  zDDayNormRef::VariableArray{2} = ReadDisk(RefNameDB,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDDayNormRes(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Degree Days"
  UnitsDS[CN] = "Degree Days"
end

function zDDayNormRes_DtaRun(data,iob,nation)
  (; Area,AreaDS,Areas,EnduseDS,Enduses) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zDDayNorm,zDDayNormRef,ZZZ,SceName) = data

  if BaseSw != 0
    @. zDDayNormRef = zDDayNorm
  end

  year = Yr(EndTime)
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for area in areas
    for enduse in Enduses
      ZZZ[year] = zDDayNorm[enduse,area]*Conversion[nation,year]
      CCC[year] = zDDayNormRef[enduse,area]*Conversion[nation,year]
      if ZZZ[year] != 0.0 || CCC[year] != 0.0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zDDayNorm;",AreaDS[area],";",
          EnduseDS[enduse],";","Residential",";",UnitsDS[nation],";",zData,";",zInitial)
      end
    end
  end
end

#
# Commercial
#
Base.@kwdef struct zDDayNorm_CControl
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  zDDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  zDDayNormRef::VariableArray{2} = ReadDisk(RefNameDB,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
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

function AssignConversions_zDDayNormCom(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1.0
  end

  UnitsDS[US] = "Degree Days"
  UnitsDS[CN] = "Degree Days"
end

function zDDayNormCom_DtaRun(data,iob,nation)
  (; Area,AreaDS,Areas,EnduseDS,Enduses) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zDDayNorm,zDDayNormRef,ZZZ) = data

  if BaseSw != 0
    @. zDDayNormRef = zDDayNorm
  end

  year = Yr(EndTime)
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for area in areas
    for enduse in Enduses
      ZZZ[year] = zDDayNorm[enduse,area]*Conversion[nation,year]
      CCC[year] = zDDayNormRef[enduse,area]*Conversion[nation,year]
      if ZZZ[year] != 0.0 || CCC[year] != 0.0
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zDDayNorm;",AreaDS[area],";",
          EnduseDS[enduse],";","Commercial",";",UnitsDS[nation],";",zData,";",zInitial)
      end
    end
  end
end

function zDDayNorm_Residential(db,iob,nation)
  data = zDDayNorm_RControl(; db)
  AssignConversions_zDDayNormRes(data)
  zDDayNormRes_DtaRun(data,iob,nation)
end

function zDDayNorm_Commercial(db,iob,nation)
  data = zDDayNorm_CControl(; db)
  AssignConversions_zDDayNormCom(data)
  zDDayNormCom_DtaRun(data,iob,nation)
end

function zDDayNorm_CreateOutputFile(db,iob,nationkey,SceName)
  filename = "zDDayNorm-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDDayNorm_DtaControl(db)
  data = zDDayNorm_RControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zDDayNorm_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Area;Enduse;Sector;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDDayNorm_Residential(db,iob,nation)
      zDDayNorm_Commercial(db,iob,nation)

      zDDayNorm_CreateOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zDDayNorm_DtaControl(DB)
end
