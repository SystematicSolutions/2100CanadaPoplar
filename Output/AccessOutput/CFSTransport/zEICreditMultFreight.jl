#
# zEICreditMultFreight.jl
#

Base.@kwdef struct zEICreditMultFreightData
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  zEICreditMult::VariableArray{6} = ReadDisk(db, "$Input/EICreditMult") # [Enduse,Fuel,Tech,EC,Area,Year] Multipler for CFS Credits (Tonne/Tonne)
  zEICreditMultRef::VariableArray{6} = ReadDisk(RefNameDB, "$Input/EICreditMult") # [Enduse,Fuel,Tech,EC,Area,Year] Multipler for CFS Credits (Tonne/Tonne)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

end

function zEICreditMultFreight_DtaRun(data,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,Fuel,FuelDS,Fuels,Nation,NationDS,Nations) = data
  (; Plants,PlantDS,Tech,TechDS,Techs,Year,YearDS) = data
  (; ANMap,BaseSw,Conversion,EndTime,UnitsDS,zEICreditMult,zEICreditMultRef,NationOutputMap) = data

  if BaseSw != 0
    @. zEICreditMultRef = zEICreditMult
  end

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Technology;Fuel;Units;zData;zInitial")

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  # Select EC(Freight) - only process Freight sector
  freight_ec = Select(EC,"Freight")
  if freight_ec == 0
    @warn "Freight EC not found"
    return
  end

  US = Select(Nation,"US")
  CN = Select(Nation,"CN")
  
  for year in years
    Conversion[US,year] = 1.0
    UnitsDS[US] = "Tonne/Tonne"
    Conversion[CN,year] = 1.0
    UnitsDS[CN] = "Tonne/Tonne"
  end

  for enduse in Enduses
    for fuel in Fuels
      for tech in Techs
        for area in areas
          for year in years
            ZZZ = zEICreditMult[enduse,fuel,tech,freight_ec,area,year]*Conversion[nation,year]
            CCC = zEICreditMultRef[enduse,fuel,tech,freight_ec,area,year]*Conversion[nation,year]
            if ZZZ != 0 || CCC != 0
              println(iob,"zEICreditMult;",YearDS[year],";",AreaDS[area],";",ECDS[freight_ec],";",TechDS[tech],";",
                FuelDS[fuel],";",UnitsDS[nation],";",@sprintf("%.6E",ZZZ),";",@sprintf("%.6E",CCC))
            end
          end
        end
      end
    end
  end

  #
  # Create *.dta filename and write output values
  #
  nationkey = Nation[nation]
  filename = "zEICreditMultFreight-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end
 
function zEICreditMultFreight_DtaControl(db,SceName)
  data = zEICreditMultFreightData(; db)
  (; db,Nation,Nations)= data
  (; NationOutputMap)= data

  @info "zEICreditMultFreight_DtaControl"

  for nation in Nations
    if NationOutputMap[nation] == 1
      zEICreditMultFreight_DtaRun(data,nation,SceName)
    end
  end
end