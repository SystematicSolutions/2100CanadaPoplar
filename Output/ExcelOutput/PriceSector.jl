#
# PriceSector.jl
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

Base.@kwdef struct SControl
  db::String

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Exogenous Price Normal (Real $/mmBtu)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))

end

function TopOfFile(db, iob)
  data = SControl(; db)
  (; Year) = data
  (; SceName) = data
  # @info "TopOfFile"
  #
  years = collect(Yr(1990):Final)

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This is the Price Sector Output summary")
  println(iob)

  println(iob,"Year;;",join(Year[years],";"))
  println(iob)
  return iob
end


function SPriceSector_DtaRun(db,iob)
  data = SControl(; db)
  (;FuelDS,Fuels,Nation,NationDS,Nations,Year) = data
  (;CDTime,CDYear,ExchangeRateNation,InflationNation,xENPN) = data
  (;ZZZ) = data

  CDYear = max(CDYear,1)

  years = collect(Yr(1990):Final)
  US=Select(Nation,"US")
  nations=Select(Nation,["US","CN"])

  #
  # xENPN - Wholesale Primary Fuel Price (US$/mmBtu)
  #
  for nation in nations
    println(iob,"$(NationDS[nation]) Wholesale Fuel Price ($CDTime US\$/mmBtu);;    ", join(Year[years], ";"))
    for fuel in Fuels
      print(iob,"xENPN;",FuelDS[fuel])
      for year in years
        ZZZ[year] = xENPN[fuel,nation,year]*InflationNation[nation,CDYear]/
            ExchangeRateNation[nation,year]/InflationNation[US,year]*InflationNation[US,CDYear]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  return iob
end

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)

  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  ECD::VariableArray{4} = ReadDisk(db,"$Outpt/ECD") # Fuel Demand (TBtu/Yr) [Tech,EC,Area]

  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))

end

function RPriceSector_DtaRun(db,iob)
  data = RControl(; db)
  (;Area,AreaDS,Areas,ECs,Nation,TechDS,Techs,Year) = data
  (;ANMap,CDTime,CDYear,ECD,ECFP,Inflation,MoneyUnitDS) = data
  (;ZZZ) = data

  CDYear = max(CDYear,1)

  years = collect(Yr(1990):Final)
  CN=Select(Nation,"CN")
  US=Select(Nation,"US")

  @. ECD=max(ECD,0.00001)

  areas=findall(ANMap[Areas,CN] .== 1)
  area_single=first(areas)
  enduse=1
 
  for area in areas
    println(iob,"Residential $(AreaDS[area]) Fuel Prices (2010 $(MoneyUnitDS[area])/mmBtu);;    ", join(Year[years], ";"))
    for tech in Techs
      print(iob,"ECFP;",TechDS[tech])
      for year in years
        ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for ec in ECs)/sum(ECD[tech,ec,area,year] for ec in ECs)/Inflation[area,year]*Inflation[area,Yr(2010)]
        print(iob,";",@sprintf("%.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,"Residential $(AreaDS[area_single]) Average Canadian Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  areas=findall(ANMap[Areas,US] .== 1)
  area_single=first(areas)

  println(iob,"Residential $(AreaDS[area_single]) Average United States Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  return iob
end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)

  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  ECD::VariableArray{4} = ReadDisk(db,"$Outpt/ECD") # Fuel Demand (TBtu/Yr) [Tech,EC,Area]

  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))

end

function CPriceSector_DtaRun(db,iob)
  data = CControl(; db)
  (;Area,AreaDS,Areas,ECs,Nation,TechDS,Techs,Year) = data
  (;ANMap,CDTime,CDYear,ECD,ECFP,Inflation,MoneyUnitDS) = data
  (;ZZZ) = data

  CDYear = max(CDYear,1)

  years = collect(Yr(1990):Final)
  CN=Select(Nation,"CN")
  US=Select(Nation,"US")

  @. ECD=max(ECD,0.00001)

  areas=findall(ANMap[Areas,CN] .== 1)
  area_single=first(areas)
  enduse=1
 
  for area in areas
    println(iob,"Commercial $(AreaDS[area]) Fuel Prices (2010 $(MoneyUnitDS[area])/mmBtu);;    ", join(Year[years], ";"))
    for tech in Techs
      print(iob,"ECFP;",TechDS[tech])
      for year in years
        ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for ec in ECs)/sum(ECD[tech,ec,area,year] for ec in ECs)/Inflation[area,year]*Inflation[area,Yr(2010)]
        print(iob,";",@sprintf("%.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,"Commercial $(AreaDS[area_single]) Average Canadian Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  areas=findall(ANMap[Areas,US] .== 1)
  area_single=first(areas)

  println(iob,"Commercial $(AreaDS[area_single]) Average United States Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  return iob
end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)

  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  ECD::VariableArray{4} = ReadDisk(db,"$Outpt/ECD") # Fuel Demand (TBtu/Yr) [Tech,EC,Area]

  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))

end

function IPriceSector_DtaRun(db,iob)
  data = IControl(; db)
  (;Area,AreaDS,Areas,ECs,Nation,TechDS,Techs,Year) = data
  (;ANMap,CDTime,CDYear,ECD,ECFP,Inflation,MoneyUnitDS) = data
  (;ZZZ) = data

  CDYear = max(CDYear,1)

  years = collect(Yr(1990):Final)
  
  # TODO Delete? Repeated only at the start of Ind/Trans/Elec
  println(iob,"Year;;",join(Year[years],";"))
  println(iob)



  CN=Select(Nation,"CN")
  US=Select(Nation,"US")

  @. ECD=max(ECD,0.00001)

  areas=findall(ANMap[Areas,CN] .== 1)
  area_single=first(areas)
  enduse=1
 
  for area in areas
    println(iob,"Industrial $(AreaDS[area]) Fuel Prices (2010 $(MoneyUnitDS[area])/mmBtu);;    ", join(Year[years], ";"))
    for tech in Techs
      print(iob,"ECFP;",TechDS[tech])
      for year in years
        ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for ec in ECs)/sum(ECD[tech,ec,area,year] for ec in ECs)/Inflation[area,year]*Inflation[area,Yr(2010)]
        print(iob,";",@sprintf("%.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,"Industrial $(AreaDS[area_single]) Average Canadian Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  areas=findall(ANMap[Areas,US] .== 1)
  area_single=first(areas)

  println(iob,"Industrial $(AreaDS[area_single]) Average United States Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  return iob
end


Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
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
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)

  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  ECD::VariableArray{4} = ReadDisk(db,"$Outpt/ECD") # Fuel Demand (TBtu/Yr) [Tech,EC,Area]

  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))

end

function TPriceSector_DtaRun(db,iob)
  data = TControl(; db)
  (;Area,AreaDS,Areas,ECs,Nation,TechDS,Techs,Year) = data
  (;ANMap,CDTime,CDYear,ECD,ECFP,Inflation,MoneyUnitDS) = data
  (;ZZZ) = data

  CDYear = max(CDYear,1)

  years = collect(Yr(1990):Final)
  # TODO Delete? Repeated only at the start of Ind/Trans/Elec
  println(iob,"Year;;",join(Year[years],";"))
  println(iob)

  CN=Select(Nation,"CN")
  US=Select(Nation,"US")

  @. ECD=max(ECD,0.00001)

  areas=findall(ANMap[Areas,CN] .== 1)
  area_single=first(areas)
  enduse=1
 
  for area in areas
    println(iob,"Transportation $(AreaDS[area]) Fuel Prices (2010 $(MoneyUnitDS[area])/mmBtu);;    ", join(Year[years], ";"))
    for tech in Techs
      print(iob,"ECFP;",TechDS[tech])
      for year in years
        ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for ec in ECs)/sum(ECD[tech,ec,area,year] for ec in ECs)/Inflation[area,year]*Inflation[area,Yr(2010)]
        print(iob,";",@sprintf("%.3f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,"Transportation $(AreaDS[area_single]) Average Canadian Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  areas=findall(ANMap[Areas,US] .== 1)
  area_single=first(areas)

  println(iob,"Transportation $(AreaDS[area_single]) Average United States Fuel Prices (2010 $(MoneyUnitDS[area_single])/mmBtu);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob,"ECFP;",TechDS[tech])
    for year in years
      ZZZ[year] = sum(ECFP[enduse,tech,ec,area,year]*ECD[tech,ec,area,year] for area in areas, ec in ECs)/sum(ECD[tech,ec,area,year] for area in areas, ec in ECs)/Inflation[area_single,year]*Inflation[area_single,Yr(2010)]
      print(iob,";",@sprintf("%.3f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  return iob
end

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  ExchangeRate::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db,"MOutput/ExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Exogenous Price Normal (Real $/mmBtu)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))

end

function EPriceSector_DtaRun(db,iob)
  data = EControl(; db)
  (;Area,AreaDS,Areas,FuelDS,Fuels,Nation,NationDS,Nations,Year) = data
  (;ANMap,CDTime,CDYear,ExchangeRate,ExchangeRateNation,Inflation,InflationNation,xENPN) = data
  (;ZZZ) = data

  CDYear = max(CDYear,1)

  years = collect(Yr(1990):Final)
  # TODO Delete? Repeated only at the start of Ind/Trans/Elec
  println(iob,"Year;;",join(Year[years],";"))
  println(iob)

  CN=Select(Nation,"CN")
  US=Select(Nation,"US")
  nations=Select(Nation,["US","CN"])

  #
  # xENPN - Wholesale Primary Fuel Price (US$/mmBtu)
  #
  for nation in nations
    println(iob,"$(NationDS[nation]) Wholesale Fuel Price (2008 US\$/mmBtu);;    ", join(Year[years], ";"))
    for fuel in Fuels
      print(iob,"xENPN;",FuelDS[fuel])
      for year in years
        ZZZ[year] = xENPN[fuel,nation,year]*InflationNation[nation,Yr(2008)]/
            ExchangeRateNation[nation,Yr(2008)]
        print(iob,";",@sprintf("%12.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,"GDP Deflator (1985=1);;    ", join(Year[years], ";"))
  for area in Areas
    print(iob,"Inflation;",AreaDS[area])
    for year in years
      ZZZ[year] = Inflation[area,year]
      print(iob,";",@sprintf("%12.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  areas=findall(ANMap[Areas,CN] .== 1)
  area_single=first(areas)

  println(iob,"Local Currency/US\$ Exchange Rate (Local/US\$);;    ", join(Year[years], ";"))
  print(iob,"ExchangeRate;ExchangeRate")
  for year in years
    ZZZ[year] = ExchangeRate[area_single,year]
    print(iob,";",@sprintf("%12.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  return iob
end

function CreateOutputFile(db,iob)
  data = SControl(; db)
  (;SceName) = data

  filename = "PriceSector-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function PriceSector_DtaControl(db)
  @info "PriceSector_DtaControl"

  iob = IOBuffer()

  iob = TopOfFile(db,iob)
  iob = SPriceSector_DtaRun(db,iob)
  iob = RPriceSector_DtaRun(db,iob)
  iob = CPriceSector_DtaRun(db,iob)
  iob = IPriceSector_DtaRun(db,iob)
  iob = TPriceSector_DtaRun(db,iob)
  iob = EPriceSector_DtaRun(db,iob)

  CreateOutputFile(db,iob)

end

if abspath(PROGRAM_FILE) == @__FILE__
  PriceSector_DtaControl(DB)
end
