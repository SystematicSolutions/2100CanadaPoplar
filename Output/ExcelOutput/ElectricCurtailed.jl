#
# ElectricCurtailed.jl
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

Base.@kwdef struct ElectricCurtailedData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  ClassDS::SetArray = ReadDisk(db,"MainDB/ClassDS")
  Classes::Vector{Int} = collect(Select(Class))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimeP")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db, "MainDB/Unit")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/Year")

  CDTime::Int = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  AreaPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/AreaPurchases") # [Area,Year] Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{2} = ReadDisk(db, "EGOutput/AreaSales") # [Area,Year] Sales to Areas in the same Country (GWh/Yr)

  CapCredit::VariableArray{3} = ReadDisk(db,"EGInput/CapCredit") #[Plant,Area,Year]  Capacity Credit (MW/MW)
  CgEC::VariableArray{3} = ReadDisk(db,"SOutput/CgEC") # Cogeneration by Economic Category (GWh/YR) [ECC,Area,Year]
  CgCap::VariableArray{4} = ReadDisk(db,"SOutput/CgCap") # (Fuel,ECC,Area,Year),CCogeneration Capacity (MW)

  ECCCLMap::VariableArray{2} = ReadDisk(db,"MainDB/ECCCLMap") #[ECC,Class]  Map Between ECC and Class (map)
  EmEGA::VariableArray{4} = ReadDisk(db,"EGOutput/EmEGA") # (Node,TimeP,Month,Year),Emergency Generation (GWh)
  EGCurtailed::VariableArray{5} = ReadDisk(db,"EGOutput/EGCurtailed") #[TimeP,Month,Plant,Area,Year]  Curtailed Electric Generation (GWh/Yr)
  EGPA::VariableArray{3} = ReadDisk(db, "EGOutput/EGPA") # [Plant,Area,Year]  Electric Generation Reported Values (GWh/Yr)
  EGPAuu::VariableArray{3} = ReadDisk(db, "EGOutput/EGPAuu") # [Plant,Area,Year]  Electric Generation Model Values (GWh/Yr)
  EGPACurtailed::VariableArray{3} = ReadDisk(db,"EGOutput/EGPACurtailed") # (Plant,Area,Year),Curtailed Electric Generation (GWh/Yr)
  EGTM::VariableArray{5} = ReadDisk(db,"EGOutput/EGTM") #[TimeP,Month,Plant,Area,Year]  Electricity Generated (GWh/Yr)


  ExpPurchases::VariableArray{2} = ReadDisk(db,"EGOutput/ExpPurchases") #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db,"EGOutput/ExpSales") #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)
 
  GCPA::VariableArray{3} = ReadDisk(db,"EOutput/GCPA") #[Plant,Area,Year]  Generation Capacity (MW)
  
  HDEmMDS::VariableArray{4} = ReadDisk(db, "EGOutput/HDEmMDS") # [Node,TimeP,Month,Year] Emergency Power Dispatched (MW)
  HDHours::VariableArray{2} = ReadDisk(db, "EInput/HDHours") # [TimeP,Month] Number of Hours in the Interval (Hours)
  HDHrMn::VariableArray{2} = ReadDisk(db,"EInput/HDHrMn") # [TimeP,Month] Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db,"EInput/HDHrPk") # [TimeP,Month] Peak Hour in the Interval (Hour)
  HDPrA::VariableArray{4} = ReadDisk(db, "EOutput/HDPrA") # [Node,TimeP,Month,Year] Spot Market Marginal Price ($/MWh)
  HMPrA::VariableArray{2} = ReadDisk(db, "EOutput/HMPrA") # [Area,Year] Average Spot Market Price ($/MWh)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)

  MinLd::VariableArray{3} = ReadDisk(db,"SOutput/MinLd") # [Month,Area,Year] Monthly Minimum Load (MW/Month)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  NdArMap::VariableArray{2} = ReadDisk(db,"EGInput/NdArMap") # (Node,Area),Map between Node and Area

  PkLoad::VariableArray{3} = ReadDisk(db,"SOutput/PkLoad") # (Month,Area,Year),Monthly Peak Load (MW)
  PSoECC::VariableArray{3} = ReadDisk(db,"SOutput/PSoECC") # (ECC,Area,Year),Power Sold to Grid (GWh)

  SaEC::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") #[ECC,Area,Year]  Electricity Sales by ECC (GWh/Yr)

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnEGC::VariableArray{4} = ReadDisk(db, "EGOutput/UnEGC") #[Unit,TimeP,Month,Year]  Effective Generating Capacity (MW)
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnOOR::VariableArray{2} = ReadDisk(db,"EGCalDB/UnOOR") # [Unit,Year] Operational Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
 
  # Scratch Variables
  EGCNet::VariableArray{3} = zeros(Float32, length(Plant), length(Area), length(Year)) # Effective Generating Capacity (MW)
  EGCPot::VariableArray{3} = zeros(Float32, length(Plant), length(Area), length(Year)) # Potential Effective Generating Capacity (MW)
  RMargin = zeros(Float32,length(Year)) # Reserve Margin (MW/MW) 
  ZZZ = zeros(Float32,length(Year))

end


function GetUnitSets(data,unit)
  (; Area,Plant) = data
  (; UnArea,UnPlant) = data

  #
  # This procedure selects the sets for a particular unit
  #
  if (UnPlant[unit] != "Null") && (UnArea[unit]  != "Null")
    plant = Select(Plant,UnPlant[unit])
    area = Select(Area,UnArea[unit])
    valid = true
  else
    plant=1
    area=1
    valid = false
  end

  return plant,area,valid
end # GetUnitSets


function EffectiveCapacity(data)
  (; Months,TimePs,Units) = data
  (; HDHours,UnCogen,UnEGC,UnOnLine,UnOOR,UnRetire) = data
  (; EGCNet,EGCPot) = data

  @. EGCPot=0
  @. EGCNet=0
  #
  for unit in Units
    if UnCogen[unit] == 0
      plant,area,valid = GetUnitSets(data,unit)
      if valid==true
        y1=Int(max(min(UnOnLine[unit]-ITime+1,Final),2))
        y2=Int(max(min(UnRetire[unit,Yr(2020)]-ITime+1,Final),2))
        years=collect(y1:y2)
        for year in years
          @finite_math EGCPot[plant,area,year]=EGCPot[plant,area,year]+
              sum(UnEGC[unit,timep,month,year]*HDHours[timep,month] for month in Months,timep in TimePs)/8760/(1-UnOOR[unit,year])
          EGCNet[plant,area,year]=EGCNet[plant,area,year]+
              sum(UnEGC[unit,timep,month,year]*HDHours[timep,month] for month in Months,timep in TimePs)/8760
        end
      end
    end
  end

end

# function ShowPlant(data,years,areas,plants,PlantName)
#   (; EGPA,EGPAuu,EGPACurtailed,GCPA) = data
#   (; EGCNet,EGCPot) = data
   
#   # print(iob,TitleName," ",PlantName," Summary;")
#   # for year in years
#   #   print(iob,";",Year[year])
#   # end
#   # println(iob)
#   # #
#   # print(iob,"EGPA;Reported Generation (GWh)")
#   # for year in years
#   #   ZZZ[year] = sum(EGPA[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"EGPAuu;Internal Generation (GWh)")
#   # for year in years
#   #   ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"EGPACurtailed;Curtailed Generation (GWh)")
#   # for year in years
#   #   ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"EGPAPot;Internal plus Curtailed Generation (GWh)")
#   # for year in years
#   #   ZZZ[year] = sum(EGPAuu[plant,area,year]+EGPACurtailed[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"EGPAMax;Maximum Generation (GWh)")
#   # for year in years
#   #   ZZZ[year] = sum(GCPA[plant,area,year]*8760/1000 for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"GCPA;Capacity (MW)")
#   # for year in years
#   #   ZZZ[year] = sum(GCPA[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"EGCPot;Internal plus Curtailed Effective Capacity (MW)")
#   # for year in years
#   #   ZZZ[year] = sum(EGCPot[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"EGCNet;Effective Capacity After Curtailments (MW)")
#   # for year in years
#   #   ZZZ[year] = sum(EGCNet[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"PCF;Reported Capacity Factor (GWh/GWh)")
#   # for year in years
#   #   @finite_math ZZZ[year] = sum(EGPA[plant,area,year] for area in areas,plant in plants)/
#   #       (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"PCFuu;Internal Capacity Factor (GWh/GWh)")
#   # for year in years
#   #   @finite_math ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas,plant in plants)/
#   #       (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"PCFPot;Curtailed Capacity Factor (GWh/GWh)")
#   # for year in years
#   #   @finite_math ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in plants)/
#   #       (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"PCFPot;Internal plus Curtailed Capacity Factor (GWh/GWh)")
#   # for year in years
#   #   @finite_math ZZZ[year] = sum(EGPAuu[plant,area,year] + EGPACurtailed[plant,area,year] for area in areas,plant in plants)/
#   #       (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # print(iob,"Fraction Curtailed;Fraction Curtailed (GWh/GWh)")
#   # for year in years
#   #   @finite_math ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in plants)/
#   #       sum(EGPAuu[plant,area,year] + EGPACurtailed[plant,area,year] for area in areas,plant in plants)
#   #   print(iob,";",@sprintf("%15.4f",ZZZ[year]))
#   # end
#   # println(iob)
#   # #
#   # println(iob)

# end

function ElectricCurtailed_DtaRun(data,TitleKey,TitleName,areas,nodes)
  (; AreaDS,ClassDS,Classes,ECCs,Fuels,Month,MonthDS,Months) = data
  (; NodeDS,Plant,PlantDS,Plants,TimePs,Year) = data
  (; CDTime,CDYear,SceName,AreaPurchases,AreaSales,CapCredit,CgEC,CgCap,ECCCLMap) = data
  (; EmEGA,EGCurtailed,EGPA,EGPAuu,EGPACurtailed,EGTM,ExpPurchases) = data
  (; ExpSales,GCPA,HDEmMDS,HDHrMn,HDHrPk,HDPrA,HMPrA) = data
  (; Inflation,MinLd,MoneyUnitDS,NdArMap,PkLoad,PSoECC) = data
  (; SaEC,UnArea,UnCogen,UnEGC,UnOnLine,UnOOR,UnPlant,UnRetire) = data
  (; EGCNet,EGCPot,RMargin,ZZZ) = data
  
  if !isempty(nodes)
  
  CDYear = max(CDYear,1)

  iob = IOBuffer()
  
  area_single = first(areas)

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob,"$TitleName; is the area being output.")
  println(iob,"This is the Electric Curtailments Summary.")
  println(iob)

  years = collect(Yr(1990):Final)
  println(iob,"Year;",";    ",join(Year[years],";"))
  println(iob)

  plants=Select(Plant,["OnshoreWind","OffshoreWind","SolarPV","SolarThermal"])
  print(iob,TitleName," Wind and Solar Summary;")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  #
  print(iob,"EGPA;Reported Generation (GWh)")
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"EGPAuu;Internal Generation (GWh)")
  for year in years
    ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"EGPACurtailed;Curtailed Generation (GWh)")
  for year in years
    ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"EGPAPot;Internal plus Curtailed Generation (GWh)")
  for year in years
    ZZZ[year] = sum(EGPAuu[plant,area,year]+EGPACurtailed[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"EGPAMax;Maximum Generation (GWh)")
  for year in years
    ZZZ[year] = sum(GCPA[plant,area,year]*8760/1000 for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"GCPA;Capacity (MW)")
  for year in years
    ZZZ[year] = sum(GCPA[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"EGCPot;Internal plus Curtailed Effective Capacity (MW)")
  for year in years
    ZZZ[year] = sum(EGCPot[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"EGCNet;Effective Capacity After Curtailments (MW)")
  for year in years
    ZZZ[year] = sum(EGCNet[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"PCF;Reported Capacity Factor (GWh/GWh)")
  for year in years
    @finite_math ZZZ[year] = sum(EGPA[plant,area,year] for area in areas,plant in plants)/
        (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"PCFuu;Internal Capacity Factor (GWh/GWh)")
  for year in years
    @finite_math ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas,plant in plants)/
        (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"PCFPot;Curtailed Capacity Factor (GWh/GWh)")
  for year in years
    @finite_math ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in plants)/
        (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"PCFPot;Internal plus Curtailed Capacity Factor (GWh/GWh)")
  for year in years
    @finite_math ZZZ[year] = sum(EGPAuu[plant,area,year] + EGPACurtailed[plant,area,year] for area in areas,plant in plants)/
        (sum(GCPA[plant,area,year] for area in areas,plant in plants)*8760/1000)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"Fraction Curtailed;Fraction Curtailed (GWh/GWh)")
  for year in years
    @finite_math ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in plants)/
        sum(EGPAuu[plant,area,year] + EGPACurtailed[plant,area,year] for area in areas,plant in plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  println(iob)

  # ShowPlant(data,years,areas,plants,"Wind and Solar")
  #
  for plant in Plants
    print(iob,TitleName," ",PlantDS[plant]," Summary;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    #
    print(iob,"EGPA;Reported Generation (GWh)")
    for year in years
      ZZZ[year] = sum(EGPA[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"EGPAuu;Internal Generation (GWh)")
    for year in years
      ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"EGPACurtailed;Curtailed Generation (GWh)")
    for year in years
      ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"EGPAPot;Internal plus Curtailed Generation (GWh)")
    for year in years
      ZZZ[year] = sum(EGPAuu[plant,area,year]+EGPACurtailed[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"EGPAMax;Maximum Generation (GWh)")
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year]*8760/1000 for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"GCPA;Capacity (MW)")
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"EGCPot;Internal plus Curtailed Effective Capacity (MW)")
    for year in years
      ZZZ[year] = sum(EGCPot[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"EGCNet;Effective Capacity After Curtailments (MW)")
    for year in years
      ZZZ[year] = sum(EGCNet[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PCF;Reported Capacity Factor (GWh/GWh)")
    for year in years
      @finite_math ZZZ[year] = sum(EGPA[plant,area,year] for area in areas)/
          (sum(GCPA[plant,area,year] for area in areas)*8760/1000)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PCFuu;Internal Capacity Factor (GWh/GWh)")
    for year in years
      @finite_math ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas)/
          (sum(GCPA[plant,area,year] for area in areas)*8760/1000)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PCFPot;Curtailed Capacity Factor (GWh/GWh)")
    for year in years
      @finite_math ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas)/
          (sum(GCPA[plant,area,year] for area in areas)*8760/1000)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PCFPot;Internal plus Curtailed Capacity Factor (GWh/GWh)")
    for year in years
      @finite_math ZZZ[year] = sum(EGPAuu[plant,area,year] + EGPACurtailed[plant,area,year] for area in areas)/
          (sum(GCPA[plant,area,year] for area in areas)*8760/1000)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"Fraction Curtailed;Fraction Curtailed (GWh/GWh)")
    for year in years
      @finite_math ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas)/
          sum(EGPAuu[plant,area,year] + EGPACurtailed[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    println(iob)
  end

  #
  print(iob,TitleName," Internal Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EGPAuu;Total")
  for year in years
    ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas,plant in Plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"EGPAuu;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGPAuu[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,TitleName," Curtailed Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EGPACurtailed;Total")
  for year in years
    ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in Plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"EGPACurtailed;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGPACurtailed[plant,area,year] for area in areas,plant in Plants)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,TitleName," Effective Generating Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EGCNet;Total")
  for year in years
    ZZZ[year] = sum(EGCNet[plant,area,year] for area in areas,plant in Plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"EGCNet;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGCNet[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,TitleName," Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EGPA;Total")
  for year in years
    ZZZ[year] = sum(EGPA[plant,area,year] for area in areas,plant in Plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"EGPA;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(EGPA[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,TitleName," Generating Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"GCPA;Total")
  for year in years
    ZZZ[year] = sum(GCPA[plant,area,year] for area in areas,plant in Plants)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for plant in Plants
    print(iob,"GCPA;",PlantDS[plant])
    for year in years
      ZZZ[year] = sum(GCPA[plant,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  for month in Months
    print(iob,TitleName," ",MonthDS[month],"Curtailed Generation (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"EGCurtailed;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(EGCurtailed[timep,month,plant,area,year] for area in areas,plant in Plants,timep in TimePs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob,"EGCurtailed;$TPDS")
      for year in years
        ZZZ[year] = sum(EGCurtailed[timep,month,plant,area,year] for area in areas,plant in Plants)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  print(iob,TitleName," Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EGTM;Annual")
  for year in years
    ZZZ[year] = sum(EGTM[timep,month,plant,area,year] for area in areas,plant in Plants,month in Months,timep in TimePs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob,"EGTM;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(EGTM[timep,month,plant,area,year] for area in areas,plant in Plants,timep in TimePs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  for plant in Plants
    print(iob,TitleName," ",PlantDS[plant]," Generation (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"EGTM;Annual")
    for year in years
      ZZZ[year] = sum(EGTM[timep,month,plant,area,year] for area in areas,month in Months,timep in TimePs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for month in Months
      print(iob,"EGTM;",MonthDS[month])
      for year in years
        ZZZ[year] = sum(EGTM[timep,month,plant,area,year] for area in areas,timep in TimePs)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end  

  #
  for month in Months
    print(iob,TitleName," ",MonthDS[month]," Generation (GWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob,"EGTM;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(EGTM[timep,month,plant,area,year] for area in areas,plant in Plants,timep in TimePs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for timep in TimePs
      TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
      print(iob,"EGTM;$TPDS")
      for year in years
        ZZZ[year] = sum(EGTM[timep,month,plant,area,year] for area in areas,plant in Plants)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end  

  #
  print(iob,TitleName," Electricity Sales (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"SaEC;Total")
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas,ecc in ECCs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for class in Classes
    print(iob,"SaEC;",ClassDS[class])
    for year in years
      ZZZ[year] = sum(SaEC[ecc,area,year]*ECCCLMap[ecc,class] for area in areas,ecc in ECCs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Transmission Flows
  #
  print(iob,"Transmission Flows (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"AreaPurchases;In-Flows")
  for year in years
    ZZZ[year] = sum(AreaPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"AreaSales;Out-Flows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"ExpPurchases;Imports")
  for year in years
    ZZZ[year] = sum(ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"ExpSales;Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"NetExp;Net Exports")
  for year in years
    ZZZ[year] = sum(ExpSales[area,year]-ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  print(iob,"Net;Net Out-Flows")
  for year in years
    ZZZ[year] = sum(AreaSales[area,year]-AreaPurchases[area,year]+ExpSales[area,year]-ExpPurchases[area,year] for area in areas)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  print(iob,TitleName," Peak Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PkLoad;Annual")
  for year in years
    ZZZ[year] = maximum(sum(PkLoad[month,area,year] for area in areas) for month in Months)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob,"PkLoad;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(PkLoad[month,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,TitleName," Minimum Loads (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"MinLd;Annual")
  for year in years
    ZZZ[year] = minimum(sum(MinLd[month,area,year] for area in areas) for month in Months)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for month in Months
    print(iob,"MinLd;",MonthDS[month])
    for year in years
      ZZZ[year] = sum(MinLd[month,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Reserve Margin
  #
  for year in years
    @finite_math RMargin[year]=(sum(GCPA[plant,area,year]*CapCredit[plant,area,year] for area in areas,plant in Plants)+
        sum(sum(CgCap[fuel,ecc,area,year]/CgEC[ecc,area,year]*PSoECC[ecc,area,year] for fuel in Fuels) for area in areas,ecc in ECCs)-
        maximum(sum(PkLoad[month,area,year] for area in areas) for month in Months))/
        maximum(sum(PkLoad[month,area,year] for area in areas) for month in Months)
  end
  print(iob,TitleName," Reserve Margin (%);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"RMargin;",TitleName)
  for year in years
    ZZZ[year] = RMargin[year]*100
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,AreaDS[area_single]," Clearing Price ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"HMPrA;Average")
  for year in years
    ZZZ[year] = HMPrA[area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  for node in nodes
    for month in Months
      print(iob,TitleName," ",NodeDS[node]," ",MonthDS[month]," Clearing Price ($CDTime ",MoneyUnitDS[area_single],"/MWh);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for timep in TimePs
        TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
        print(iob,"HDPrA;$TPDS")
        for year in years
          ZZZ[year] = HDPrA[node,timep,month,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end
  end
    
  #
  # Emergency Generation
  # This variable is last since it has a varying number of rows. JSA 05/13/09
  #
  print(iob,TitleName," Emergency Generation (GWh);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EmEGA;Total")
  for year in years
    ZZZ[year] = sum(EmEGA[node,timep,month,year] for month in Months,timep in TimePs, node in nodes)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for node in nodes
    print(iob,"EmEGA;",NodeDS[node])
    for year in years
      ZZZ[year] = sum(EmEGA[node,timep,month,year] for month in Months,timep in TimePs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  #
  for node in nodes
    for month in Months
      print(iob,TitleName," ",NodeDS[node]," ",MonthDS[month]," Emergency Generation (GWh);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for timep in TimePs
        TPDS = "$(@sprintf("%.0f",HDHrPk[timep,month])) -- $(@sprintf("%.0f",HDHrMn[timep,month]))"
        print(iob,"HDEmMDS;$TPDS")
        for year in years
          ZZZ[year] = HDEmMDS[node,timep,month,year]
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end
  end

  filename = "ElectricCurtailed-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end
  
  end # if !isempty(nodes)
end

function ElectricCurtailed_DtaControl(db)
  @info "ElectricCurtailed_DtaControl"
  data = ElectricCurtailedData(; db)
  Area = data.Area
  AreaDS = data.AreaDS
  Node = data.Node
  NodeDS = data.NodeDS
  NdArMap = data.NdArMap

  EffectiveCapacity(data)
  
  #
  # Canada
  #
  areas=Select(Area,(from ="ON",to="NU"))
  for area in areas
    nodes = findall(NdArMap[:,area] .> 0)
    ElectricCurtailed_DtaRun(data,Area[area],AreaDS[area],area,nodes)
  end
  # nodes=Select(Node,(from="MB",to="NU"))
  nodes = findall(sum(NdArMap[:,area] for area in areas) .> 0)
  ElectricCurtailed_DtaRun(data,"CN","Canada",areas,nodes)

  #
  # US
  #
  areas=Select(Area,(from ="CA",to="Pac"))
  for area in areas
    nodes = findall(NdArMap[:,area] .> 0)
    ElectricCurtailed_DtaRun(data,Area[area],AreaDS[area],area,nodes)
  end
  nodes = findall(sum(NdArMap[:,area] for area in areas) .> 0)
  ElectricCurtailed_DtaRun(data,"US","US",areas,nodes)

  #
  # MX
  #
  area=Select(Area,"MX")
  node=Select(Node,"MX")
  ElectricCurtailed_DtaRun(data,Area[area],AreaDS[area],area,node)
end

if abspath(PROGRAM_FILE) == @__FILE__
ElectricCurtailed_DtaControl(DB)
end
