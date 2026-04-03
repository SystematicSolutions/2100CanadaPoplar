#
# zTrXMMSF.jl
#

Base.@kwdef struct zTrXMMSFData
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
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  VDTRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/VDT") # [Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  zTrxMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)
  zTrxMMSFRef::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction (Driver/Driver)

  #
  # Scratch Variables
  #
  Convert::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray{1} = zeros(Float32,length(Year))
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))
end

function zTrXMMSF_DtaRun(data,nation,SceName)
  (; AreaDS,EC,ECDS,ECs,Enduses,FuelDS,Fuels,TechDS,Techs) = data
  (; Nation,NationDS,Year) = data
  (; ANMap,CCC,EndTime) = data
  (; UnitsDS,VDTRef,zTrxMMSF,zTrxMMSFRef,ZZZ) = data

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  for year in years
    UnitsDS[US] = "Marginal Market Share Fraction (\$/\$)"
    UnitsDS[CN] = "Marginal Market Share Fraction (\$/\$)"
  end
  
  enduse = 1 # One enduse in Transportation

  for tech in Techs, ec in ECs, area in areas, year in years
    VDTRef[enduse,tech,ec,area,year] = max(VDTRef[enduse,tech,ec,area,year],0.0)
  end

  for tech in Techs
    for ec in ECs
      for area in areas
        for year in years
          ZZZ[year] = zTrxMMSF[enduse,tech,ec,area,year]
          CCC[year] = zTrxMMSFRef[enduse,tech,ec,area,year]
          if (ZZZ[year] != 0) || (CCC[year] != 0)
            println(iob,"zTrxMMSF;",Year[year],";",AreaDS[area],";",ECDS[ec],";", TechDS[tech],";",
            UnitsDS[nation],";",@sprintf("%.4f",ZZZ[year]),";",@sprintf("%.4f",CCC[year]))
          end
        end
      end
    end
  end

  for tech in Techs
    for ec in ECs
      for year in years
        ZZZ[year] = sum(zTrxMMSF[enduse,tech,ec,area,year]*VDTRef[enduse,tech,ec,area,year] for area in areas)/
                    sum(VDTRef[enduse,tech,ec,area,year] for area in areas)
        CCC[year] = sum(zTrxMMSFRef[enduse,tech,ec,area,year]*VDTRef[enduse,tech,ec,area,year] for area in areas)/
                    sum(VDTRef[enduse,tech,ec,area,year] for area in areas)
        if (ZZZ[year] != 0) || (CCC[year] != 0)
          println(iob,"zTrxMMSF;",Year[year],";",NationDS[nation],";",ECDS[ec],";", TechDS[tech],";",
          UnitsDS[nation],";",@sprintf("%.4f",ZZZ[year]),";",@sprintf("%.4f",CCC[year]))
        end
       end
    end
  end  
  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zTrXMMSF-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zTrXMMSF_DtaControl(db, SceName)
  data = zTrXMMSFData(; db)
  (; Nations)= data
  (; NationOutputMap)= data

  @info "zTrXMMSF_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zTrXMMSF_DtaRun(data,nation,SceName)
    end
  end
end
