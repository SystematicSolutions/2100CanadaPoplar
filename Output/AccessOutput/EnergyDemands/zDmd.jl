#
# zDmd.jl - Write Enduse Demands for Access Database
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

Base.@kwdef struct RControl
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
  DEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") #[Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DEEARef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DEEA") #[Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)
  zDmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  zDmdRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  Conversion::VariableArray = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description
  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function AssignConversions_Res(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1*1.054615*1000
  end

  UnitsDS[US] = "TBtu/Yr"
  UnitsDS[CN] = "TJ/Yr"
end

function zDmdRes_DtaRun(data,iob,nation,)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,Techs,Year) = data
  (; ANMap,CCC,Conversion,DEEA,DEEARef,DmFrac,DmFracRef) = data
  (; EndTime,UnitsDS,zDmd,zDmdRef,ZZZ,SceName) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)
  
  techs = Select(Tech,["Geothermal","HeatPump","Solar"])  
  for year in years, area in areas, ec in ECs, tech in techs, fuel in Fuels, enduse in Enduses
    DmFrac[enduse,fuel,tech,ec,area,year] = 0
    DmFracRef[enduse,fuel,tech,ec,area,year] = 0
  end
  fuel = Select(Fuel,"Electric")
  for year in years, area in areas, ec in ECs, tech in techs, enduse in Enduses
    DmFrac[enduse,fuel,tech,ec,area,year] = 1
    DmFracRef[enduse,fuel,tech,ec,area,year] = 1
  end
  
  for enduse in Enduses, year in years, area in areas, ec in ECs
    for fuel in Fuels
      if Fuel[fuel] == "Geothermal" || Fuel[fuel] == "Solar"
        if in(Fuel[fuel],Tech)
          tech = Select(Tech,Fuel[fuel])
          ZZZ[year] = zDmd[enduse,tech,ec,area,year]*
            DEEA[enduse,tech,ec,area,year]*Conversion[nation,year]
          CCC[year] = zDmdRef[enduse,tech,ec,area,year]*
            DEEARef[enduse,tech,ec,area,year]*Conversion[nation,year]
        else 
          ZZZ[year] = 0
          CCC[year] = 0
        end
      else          
        ZZZ[year] = sum(zDmd[enduse,tech,ec,area,year]*
          DmFrac[enduse,fuel,tech,ec,area,year] for tech in Techs)*Conversion[nation,year]
        CCC[year] = sum(zDmdRef[enduse,tech,ec,area,year]*
          DmFracRef[enduse,fuel,tech,ec,area,year] for tech in Techs)*Conversion[nation,year]
      end
      if ZZZ[year] > 0.000001 || ZZZ[year] < -0.000001 ||
           CCC[year] > 0.000001 || CCC[year] < -0.000001
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zDmd;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
          EnduseDS[enduse],";",FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
      end
    end # for fuel

    tech = Select(Tech,"HeatPump")
    ZZZ[year] = zDmd[enduse,tech,ec,area,year]*
      DEEA[enduse,tech,ec,area,year]*Conversion[nation,year]
    CCC[year] = zDmdRef[enduse,tech,ec,area,year]*
      DEEARef[enduse,tech,ec,area,year]*Conversion[nation,year]
    if ZZZ[year] > 0.000001 || CCC[year] > 0.000001
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zDmd;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
        EnduseDS[enduse],";Air Thermal;",UnitsDS[nation],";",zData,";",zInitial)
    end 
  end
end

#
# Commercial
#
Base.@kwdef struct CControl
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
  DEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") #[Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DEEARef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DEEA") #[Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  zDmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  zDmdRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
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

function AssignConversions_Com(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1*1.054615*1000
  end

  UnitsDS[US] = "TBtu/Yr"
  UnitsDS[CN] = "TJ/Yr"
end

function zDmdCom_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,Techs,Year) = data
  (; ANMap,CCC,Conversion,DEEA,DEEARef,DmFrac,DmFracRef) = data
  (; EndTime,UnitsDS,zDmd,zDmdRef,ZZZ,SceName) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  techs = Select(Tech,["Geothermal","HeatPump","Solar"])
  for year in years, area in areas, ec in ECs, tech in techs, fuel in Fuels, enduse in Enduses
    DmFrac[enduse,fuel,tech,ec,area,year] = 0
    DmFracRef[enduse,fuel,tech,ec,area,year] = 0
  end
  Electric = Select(Fuel,"Electric")
  for year in years, area in areas, ec in ECs, enduse in Enduses, tech in techs
    DmFrac[enduse,Electric,tech,ec,area,year] = 1
    DmFracRef[enduse,Electric,tech,ec,area,year] = 1
  end
  
  for enduse in Enduses, year in years, area in areas, ec in ECs
    for fuel in Fuels
      if Fuel[fuel] == "Geothermal" || Fuel[fuel] == "Solar"
        if in(Fuel[fuel],Tech)
          tech = Select(Tech,Fuel[fuel])
          ZZZ[year] = zDmd[enduse,tech,ec,area,year]*
            DEEA[enduse,tech,ec,area,year]*Conversion[nation,year]
          CCC[year] = zDmdRef[enduse,tech,ec,area,year]*
            DEEARef[enduse,tech,ec,area,year]*Conversion[nation,year]
        else 
          ZZZ[year] = 0
          CCC[year] = 0
        end
      else          
        ZZZ[year] = sum(zDmd[enduse,tech,ec,area,year]*
          DmFrac[enduse,fuel,tech,ec,area,year] for tech in Techs)*Conversion[nation,year]
        CCC[year] = sum(zDmdRef[enduse,tech,ec,area,year]*
          DmFracRef[enduse,fuel,tech,ec,area,year] for tech in Techs)*Conversion[nation,year]
      end
      if ZZZ[year] > 0.000001 || ZZZ[year] < -0.000001 || CCC[year] > 0.000001 || CCC[year] < -0.000001
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zDmd;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
          EnduseDS[enduse],";",FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
      end
    end # for fuel

    HeatPump = Select(Tech,"HeatPump")
    ZZZ[year] = zDmd[enduse,HeatPump,ec,area,year]*
      DEEA[enduse,HeatPump,ec,area,year]*Conversion[nation,year]
    CCC[year] = zDmdRef[enduse,HeatPump,ec,area,year]*
      DEEARef[enduse,HeatPump,ec,area,year]*Conversion[nation,year]
    if ZZZ[year] > 0.000001 || CCC[year] > 0.000001
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zDmd;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
        EnduseDS[enduse],";Air Thermal;",UnitsDS[nation],";",zData,";",zInitial)
    end 
  end
end

#
# Industrial except for Oil and Gas
#
Base.@kwdef struct IControl
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
  DEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") #[Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DEEARef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DEEA") #[Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  zDmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  zDmdRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracRef::VariableArray{6} = ReadDisk(RefNameDB,"$Outpt/DmFrac") #[Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
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

function AssignConversions_Ind(data)
  (; Nation,Years,Conversion,UnitsDS) = data
  
  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  for year in Years 
    Conversion[US,year] = 1.0
    Conversion[CN,year] = 1*1.054615*1000
  end

  UnitsDS[US] = "TBtu/Yr"
  UnitsDS[CN] = "TJ/Yr"
end

function zDmdInd_DtaRun(data,iob,nation)
  (; Area,AreaDS,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,Tech,Techs,Year) = data
  (; ANMap,CCC,Conversion,DEEA,DEEARef,DmFrac,DmFracRef) = data
  (; EndTime,UnitsDS,zDmd,zDmdRef,ZZZ,SceName) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[:,nation] .== 1)

  techs = Select(Tech,["Solar"])
  for year in years, area in areas, ec in ECs, tech in techs, fuel in Fuels, enduse in Enduses
    DmFrac[enduse,fuel,tech,ec,area,year] = 0
    DmFracRef[enduse,fuel,tech,ec,area,year] = 0
  end
  Electric = Select(Fuel,"Electric")
  for year in years, area in areas, ec in ECs, tech in techs, enduse in Enduses
    DmFrac[enduse,Electric,tech,ec,area,year] = 1
    DmFracRef[enduse,Electric,tech,ec,area,year] = 1
  end
  
  for enduse in Enduses, year in years, area in areas, ec in ECs
    for fuel in Fuels
      if Fuel[fuel] == "Geothermal" || Fuel[fuel] == "Solar"
        if in(Fuel[fuel],Tech)
          tech = Select(Tech,Fuel[fuel])
          ZZZ[year] = zDmd[enduse,tech,ec,area,year]*
            DEEA[enduse,tech,ec,area,year]*Conversion[nation,year]
          CCC[year] = zDmdRef[enduse,tech,ec,area,year]*
            DEEARef[enduse,tech,ec,area,year]*Conversion[nation,year]
        else 
          ZZZ[year] = 0
          CCC[year] = 0
        end
      else          
        ZZZ[year] = sum(zDmd[enduse,tech,ec,area,year]*
          DmFrac[enduse,fuel,tech,ec,area,year] for tech in Techs)*Conversion[nation,year]
        CCC[year] = sum(zDmdRef[enduse,tech,ec,area,year]*
          DmFracRef[enduse,fuel,tech,ec,area,year] for tech in Techs)*Conversion[nation,year]
      end
      if ZZZ[year] > 0.000001 || ZZZ[year] < -0.000001 || CCC[year] > 0.000001 || CCC[year] < -0.000001
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zDmd;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
          EnduseDS[enduse],";",FuelDS[fuel],";",UnitsDS[nation],";",zData,";",zInitial)
      end
    end # for fuel
  end
end

function zDmd_Residential(db,iob,nation)
  data = RControl(; db)
    (; SceName,) = data
  AssignConversions_Res(data)
  zDmdRes_DtaRun(data,iob,nation)
end

function zDmd_Commercial(db,iob,nation)
  data = CControl(; db)
   (; SceName,) = data
  AssignConversions_Com(data)
  zDmdCom_DtaRun(data,iob,nation)
end

function zDmd_Industrial(db,iob,nation)
  data = IControl(; db)
   (; SceName,) = data
  AssignConversions_Ind(data)
  zDmdInd_DtaRun(data,iob,nation)
end

function CreateOutputFile(db,iob,nationkey,SceName)
  filename = "zDmd-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDmd_DtaControl(db)
  data = RControl(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zDmd_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Enduse;Fuel;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDmd_Residential(db,iob,nation)
      zDmd_Commercial(db,iob,nation)
      zDmd_Industrial(db,iob,nation)

      CreateOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end

if abspath(PROGRAM_FILE) == @__FILE__
  zDmd_DtaControl(DB)
end
