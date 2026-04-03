#
# zDDay.jl - Write Enduse Demands for Access Database
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

Base.@kwdef struct zDDay_RControl
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
  zDDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  zDDayRef::VariableArray{3} = ReadDisk(RefNameDB,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
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

function AssignConversions_zDDayRes(data)
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

function zDDayRes_DtaRun(data,iob,nation)
  (; Area,AreaDS,Areas,EnduseDS,Enduses) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zDDay,zDDayRef,ZZZ,SceName) = data

  if BaseSw != 0
    @. zDDayRef = zDDay
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)
  
  for year in years
    for area in areas
      for enduse in Enduses
        ZZZ[year] = zDDay[enduse,area,year]*Conversion[nation,year]
        CCC[year] = zDDayRef[enduse,area,year]*Conversion[nation,year]
        if ZZZ[year] != 0.0 || CCC[year] != 0.0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zDDay;",Year[year],";",AreaDS[area],";",
            EnduseDS[enduse],";","Residential",";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end
end

#
# Commercial
#
Base.@kwdef struct zDDay_CControl
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
  zDDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  zDDayRef::VariableArray{3} = ReadDisk(RefNameDB,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
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

function AssignConversions_zDDayCom(data)
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

function zDDayCom_DtaRun(data,iob,nation)
  (; Area,AreaDS,Areas,EnduseDS,Enduses) = data
  (; Nation,Year) = data
  (; ANMap,BaseSw,CCC,Conversion) = data
  (; EndTime,UnitsDS,zDDay,zDDayRef,ZZZ) = data

  if BaseSw != 0
    @. zDDayRef = zDDay
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  for year in years
    for area in areas
      for enduse in Enduses
        ZZZ[year] = zDDay[enduse,area,year]*Conversion[nation,year]
        CCC[year] = zDDayRef[enduse,area,year]*Conversion[nation,year]
        if ZZZ[year] != 0.0 || CCC[year] != 0.0
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zDDay;",Year[year],";",AreaDS[area],";",
            EnduseDS[enduse],";","Commercial",";",UnitsDS[nation],";",zData,";",zInitial)
        end
      end
    end
  end
end

function zDDay_Residential(db,iob,nation)
  data = zDDay_RControl(; db)
  AssignConversions_zDDayRes(data)
  zDDayRes_DtaRun(data,iob,nation)
end

function zDDay_Commercial(db,iob,nation)
  data = zDDay_CControl(; db)
  AssignConversions_zDDayCom(data)
  zDDayCom_DtaRun(data,iob,nation)
end

function zDDay_CreateOutputFile(db,iob,nationkey,SceName)
  filename = "zDDay-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDDay_DtaControl(db)
  data = zDDay_RControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zDDay_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Enduse;Sector;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDDay_Residential(db,iob,nation)
      zDDay_Commercial(db,iob,nation)

      zDDay_CreateOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zDDay_DtaControl(DB)
end
