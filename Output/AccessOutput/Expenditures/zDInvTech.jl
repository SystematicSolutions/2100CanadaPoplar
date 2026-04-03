#
# zDInvTech.jl - Write Device Investments for Access Database
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

Base.@kwdef struct zDInvResData
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
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zDInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  zDInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDInvRes(data)
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

function zDInvRes_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,DmFrac,DmFracRef,EndTime,zDInvTech,zDInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ,SceName) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zDInvTechRef .= zDInvTech
    DmFracRef .= DmFrac
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            if (Tech[tech] != "Solar") && (Tech[tech] != "Geothermal") && (Tech[tech] != "HeatPump")
                for fuel in Fuels
                  ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*DmFrac[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
                  CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*DmFracRef[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
                  
                  if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
                    zData = @sprintf("%.6E",ZZZ[year])
                    zInitial = @sprintf("%.6E",CCC[year])
                    println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                      EnduseDS[enduse],";",FuelDS[fuel],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)

                  end
                end
            else # Tech is Solar, Geothermal, or HeatPump
              ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
              CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
              if ZZZ[year] > 0.0000001 || ZZZ[year] < -0.0000001 || CCC[year] > 0.0000001 || CCC[year] < -0.0000001
                zData = @sprintf("%.6E",ZZZ[year])
                zInitial = @sprintf("%.6E",CCC[year])
                println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                  EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
              end
            end # if tech
          end # for tech
        end # for ec
      end # for area
    end #for year        
  end # for enduse
end # function zDInvRes_DtaRun

#
# Commercial
#
Base.@kwdef struct zDInvComData
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
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zDInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  zDInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDInvCom(data)
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

function zDInvCom_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses,SceName) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,DmFrac,DmFracRef,EndTime,zDInvTech,zDInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zDInvTechRef .= zDInvTech
    DmFracRef .= DmFrac
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            if (Tech[tech] != "Solar") && (Tech[tech] != "Geothermal") && (Tech[tech] != "HeatPump")
                for fuel in Fuels
                  ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*DmFrac[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
                  CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*DmFracRef[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
                  
                  if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
                    zData = @sprintf("%.6E",ZZZ[year])
                    zInitial = @sprintf("%.6E",CCC[year])
                    println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                      EnduseDS[enduse],";",FuelDS[fuel],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
                  end
                end
            else # Tech is Solar, Geothermal, or HeatPump
              ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*Conversion[nation,year]
              CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*Conversion[nation,year]
              if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
                zData = @sprintf("%.6E",ZZZ[year])
                zInitial = @sprintf("%.6E",CCC[year])
                println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                  EnduseDS[enduse],";",TechDS[tech],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
              end
            end # if tech
          end # for tech
        end # for ec
      end # for area
    end #for year        
  end # for enduse
end # function zDInvCom_DtaRun

#
# Industrial
#
Base.@kwdef struct zDInvIndData
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
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zDInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  zDInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDInvInd(data)
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

function zDInvInd_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,DmFrac,DmFracRef,EndTime,zDInvTech,zDInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ,SceName) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zDInvTechRef .= zDInvTech
    DmFracRef .= DmFrac
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
              for fuel in Fuels
                ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*DmFrac[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
                CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*DmFracRef[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
                  
                if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
                  zData = @sprintf("%.6E",ZZZ[year])
                  zInitial = @sprintf("%.6E",CCC[year])
                  println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                    EnduseDS[enduse],";",FuelDS[fuel],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
                end
              end
          end # for tech
        end # for ec
      end # for area
    end #for year        
  end # for enduse
end # function zDInvInd_DtaRun

#
# Transportation
#
Base.@kwdef struct zDInvTransData
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
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zDInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  zDInvTechRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") #[Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDInvTrans(data)
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

function zDInvTrans_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,DmFrac,DmFracRef,EndTime,zDInvTech,zDInvTechRef) = data
  (; CCC,Conversion,UnitsDS,ZZZ,SceName) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zDInvTechRef .= zDInvTech
    DmFracRef .= DmFrac
  end
  
  for enduse in Enduses
    for year in years
      for area in areas
        for ec in ECs
          for tech in Techs
            for fuel in Fuels
              ZZZ[year] = zDInvTech[enduse,tech,ec,area,year]*DmFrac[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
              CCC[year] = zDInvTechRef[enduse,tech,ec,area,year]*DmFracRef[enduse,fuel,tech,ec,area,year]*Conversion[nation,year]
                  
              if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
                zData = @sprintf("%.6E",ZZZ[year])
                zInitial = @sprintf("%.6E",CCC[year])
                println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                  EnduseDS[enduse],";",FuelDS[fuel],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
              end
            end # for fuel
          end # for tech
        end # for ec
      end # for area
    end #for year        
  end # for enduse
end # function zDInvTrans_DtaRun

#
# Electric Generation
#
Base.@kwdef struct zDInvEGData
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
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zDInvEU::VariableArray{3} = ReadDisk(db,"EGOutput/DInvEU") #[Fuel,Area,Year]  Device Investments (M$/Yr)
  zDInvEURef::VariableArray{3} = ReadDisk(RefNameDB,"EGOutput/DInvEU") #[Fuel,Area,Year]  Device Investments (M$/Yr)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  #
  # Scratch Variables
  #
  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_zDInvEG(data)
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

function zDInvEG_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,DmFrac,DmFracRef,EndTime,zDInvEU,zDInvEURef) = data
  (; CCC,Conversion,UnitsDS,ZZZ,SceName) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  if BaseSw != 0
    zDInvEURef = zDInvEU
    DmFracRef = DmFrac
  end
  
  for fuel in Fuels
    for year in years
      for area in areas
        ZZZ[year] = zDInvEU[fuel,area,year]*Conversion[nation,year]
        CCC[year] = zDInvEURef[fuel,area,year]*Conversion[nation,year]
                  
        if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
          zData = @sprintf("%.6E",ZZZ[year])
          zInitial = @sprintf("%.6E",CCC[year])
          println(iob,"zDInvTech;",Year[year],";",AreaDS[area],";Utility Electric Generation;",
            "Utility Electric Generation;",FuelDS[fuel],";",CDTime,UnitsDS[nation],";",zData,";",zInitial)
        end
      end # for area
    end #for year        
  end # for fuel
end # function zDInvEG_DtaRun

function zDInv_Residential(db,iob,nation)
  data = zDInvResData(; db)
  AssignConversions_zDInvRes(data)
  zDInvRes_DtaRun(data,iob,nation)
end

function zDInv_Commercial(db,iob,nation)
  data = zDInvComData(; db)
  AssignConversions_zDInvCom(data)
  zDInvCom_DtaRun(data,iob,nation)
end

function zDInv_Industrial(db,iob,nation)
  data = zDInvIndData(; db)
  AssignConversions_zDInvInd(data)
  zDInvInd_DtaRun(data,iob,nation)
end

function zDInv_Transport(db,iob,nation)
  data = zDInvTransData(; db)
  AssignConversions_zDInvTrans(data)
  zDInvTrans_DtaRun(data,iob,nation)
end

function zDInv_ElectricGeneration(db,iob,nation)
  data = zDInvEGData(; db)
  AssignConversions_zDInvEG(data)
  zDInvEG_DtaRun(data,iob,nation)
end

function CreateDInvOutputFile(db,iob,nationkey,SceName)
  filename = "zDInvTech-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDInv_DtaControl(db)
  data = zDInvResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zDInv_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Enduse;Technology;Units;zData;zInitial")       

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDInv_Residential(db,iob,nation)
      zDInv_Commercial(db,iob,nation)
      zDInv_Industrial(db,iob,nation)
      zDInv_Transport(db,iob,nation)
      zDInv_ElectricGeneration(db,iob,nation)

      CreateDInvOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zDInv_DtaControl(DB)
end
