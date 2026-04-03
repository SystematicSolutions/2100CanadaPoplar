#
# zDInvTechCom.jl - Write Process Investments for Access Database
#

#
# Commercial
#
Base.@kwdef struct zDInvTechComData
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
  zDInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 
  zDInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Process Investments by Technology (M$/Yr) 

  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDInvTechCom(data)
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

function zDInvTechCom_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,EndTime,zDInvTech,zDInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    zDInvTechRef .= zDInvTech
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
                ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
                CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
                  
                if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
                  zData = @sprintf("%.6E",ZZZ[year])
                  zInitial = @sprintf("%.6E",CCC[year])
                  println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                    EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
              end
          end # for tech
        end # for ec
      end # for area
    end #for year
  end # for enduse

end # function zDInvTechCom_DtaRun

function zDInvTech_Commercial(db,iob,nation,SceName)
  data = zDInvTechComData(; db)
  AssignConversions_zDInvTechCom(data)
  zDInvTechCom_DtaRun(data,iob,nation,SceName)
end

function CreateDInvTechComOutputFile(db,iob,nationkey,SceName)
  filename = "zDInvTechCom-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDInvTechCom_DtaControl(db,SceName)
  data = zDInvTechResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap) = data

  @info "zDInvTechCom_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Enduse;Technology;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDInvTech_Commercial(db,iob,nation,SceName)
      CreateDInvTechComOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
