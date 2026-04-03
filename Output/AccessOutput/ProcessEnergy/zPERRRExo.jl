#
# zPERRRExo.jl - Write Enduse Demands for Access Database
#

#
# Residential
#
Base.@kwdef struct zPERRRExoResData
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  RefNameDB::String = ReadDisk(db, "MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db, "SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db, "SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPERRRExo::VariableArray{5} = ReadDisk(db, "$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  zPERRRExoRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32, length(Nation), length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("", length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32, length(Year))
  ZZZ::VariableArray = zeros(Float32, length(Year))
end

#
# Commercial
#
Base.@kwdef struct zPERRRExoComData
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  RefNameDB::String = ReadDisk(db, "MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db, "SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db, "SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPERRRExo::VariableArray{5} = ReadDisk(db, "$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  zPERRRExoRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32, length(Nation), length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("", length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32, length(Year))
  ZZZ::VariableArray = zeros(Float32, length(Year))
end

#
# Industrial
#
Base.@kwdef struct zPERRRExoIndData
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  RefNameDB::String = ReadDisk(db, "MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db, "SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db, "SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zPERRRExo::VariableArray{5} = ReadDisk(db, "$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  zPERRRExoRef::VariableArray{5} = ReadDisk(RefNameDB, "$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32, length(Nation), length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("", length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32, length(Year))
  ZZZ::VariableArray = zeros(Float32, length(Year))
end

function zPERRRExo_DtaRun(data, iob, nation, SceName)
  (; Area, AreaDS, EC, ECDS, ECs, EnduseDS, Enduses) = data
  (; Nation, Nations, Tech, TechDS, Techs, Year, Years) = data
  (; ANMap, CCC, Conversion) = data
  (; EndTime, UnitsDS, zPERRRExo, zPERRRExoRef, ZZZ) = data

  for year in Years, nation in Nations
    Conversion[nation, year] = 1.0
  end
  for nation in Nations
    UnitsDS[nation] = "mmBtu/Yr/Yr"
  end

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:, nation] .== 1)

  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            ZZZ[year] = zPERRRExo[enduse, tech, ec, area, year] * Conversion[nation, year]
            CCC[year] = zPERRRExoRef[enduse, tech, ec, area, year] * Conversion[nation, year]
            if ZZZ[year] != 0 || CCC[year] != 0
              println(iob, "zPERRRExo;", Year[year], ";", AreaDS[area], ";", ECDS[ec], ";",
                TechDS[tech], ";", EnduseDS[enduse], ";", UnitsDS[nation], ";",
                @sprintf("%.6E", ZZZ[year]), ";", @sprintf("%.6E", CCC[year]))
            end
          end
        end
      end
    end
  end

end #function zPERRRExo_DtaRun

function zPERRRExo_Residential(db, iob, nation, SceName)
  data = zPERRRExoResData(; db)
  zPERRRExo_DtaRun(data, iob, nation, SceName)
end

function zPERRRExo_Commercial(db, iob, nation, SceName)
  data = zPERRRExoComData(; db)
  zPERRRExo_DtaRun(data, iob, nation, SceName)
end

function zPERRRExo_Industrial(db, iob, nation, SceName)
  data = zPERRRExoIndData(; db)
  zPERRRExo_DtaRun(data, iob, nation, SceName)
end

function zPERRRExo_DtaControl(db, SceName)
  data = zPERRRExoResData(; db)
  (; Nation, Nations) = data
  (; NationOutputMap) = data

  @info "zPERRRExo_DtaControl"

  iob = IOBuffer()
  println(iob, "Variable;Year;Area;Sector;Tech;Enduse;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zPERRRExo_Residential(db, iob, nation, SceName)
      zPERRRExo_Commercial(db, iob, nation, SceName)
      zPERRRExo_Industrial(db, iob, nation, SceName)

      nationkey = Nation[nation]
      filename = "zPERRRExo-$nationkey-$SceName.dta"
      open(joinpath(OutputFolder, filename), "w") do filename
        write(filename, String(take!(iob)))
      end
    end
  end

end
