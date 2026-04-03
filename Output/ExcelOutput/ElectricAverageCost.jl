#
# ElectricAverageCost.jl
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

Base.@kwdef struct ElectricAverageCostData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db, "MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db, "MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  ArNdFr::VariableArray{3} = ReadDisk(db, "EGInput/ArNdFr") #[Area,Node,Year]  Fraction of the Area in each Node (MW/MW)
  CCR::VariableArray{3} = ReadDisk(db, "EGOutput/CCR") # [Plant,Area,Year] Capital Charge Rate (1/Yr)

  EGNDA::VariableArray{4} = ReadDisk(db, "EGOutput/EGNDA") # [Plant,Node,GenCo,Year] Electricity Generation (GWh/Yr) 
  EGPA::VariableArray{3} = ReadDisk(db,"EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  ExportsRevenues::VariableArray{2} = ReadDisk(db, "SOutput/ExportsRevenues") #[Area,Year]  Electric Exports Revenues (M$/Yr)
  ExportsUR::VariableArray{2} = ReadDisk(db, "EOutput/ExportsUR") #[Area,Year]  Electric Exports Unit Revenues ($/MWh)

  GCBL::VariableArray{3} = ReadDisk(db, "EGInput/GCBL") # [Plant,Area,Year] Generation Capacity Book Life (Years)

  ImportsExpenditures::VariableArray{2} = ReadDisk(db,"SOutput/ImportsExpenditures") #[Areas,Year]  Electric Imports Expenditures (M$/Yr)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") #[Area,Year]  Inflation Index
  InflationUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationUnit") # [Unit,Year] Inflation Index ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  NdArFr::VariableArray{3} = ReadDisk(db, "EGInput/NdArFr") #[Node,Area,Year]  Fraction of the Node in each Area
  SaECD::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") #[ECC,Area,Year]  Electricity Sales (GWh/Yr)
  Subsidy::VariableArray{3} = ReadDisk(db, "EGInput/Subsidy") # [Plant,Area,Year] Generating Capacity Subsidy ($/MWh)

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnAFC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAFC") #[Unit,Year]  Average Fixed Costs ($/KW)
  UnAVC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAVC") #[Unit,Year]  Average Variable Costs ($/MWh)
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEG::VariableArray{4} = ReadDisk(db, "EGOutput/UnEG") # [Unit,TimeP,Month,Year] Generation (GWh) 
  UnEGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnEGA") #[Unit,Year]  Generation (GWh/Yr)
  UnFP::VariableArray{3} = ReadDisk(db, "EGOutput/UnFP") #[Unit,Month,Year]  Fuel Price ($/mmBtu)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGCCC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCC") #[Unit,Year]  Generating Unit Capital Cost ($/KW)
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnNA::VariableArray{2} = ReadDisk(db, "EGOutput/UnNA") # [Unit,Year] Net Asset Value of Generating Unit (M$) 
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPCF::VariableArray{2} = ReadDisk(db, "EGOutput/UnPCF") # [Unit,Year] Unit Capacity Factor (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPoTR::VariableArray{2} = ReadDisk(db, "EGOutput/UnPoTR") #[Unit,Year]  Pollution Tax Rate ($/MWh)
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  UnSLDPR::VariableArray{2} = ReadDisk(db, "EGOutput/UnSLDPR") # [Unit,Year] Depreciation (M$/Yr)
  UnUFOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUFOMC") # [Unit,Year] Fixed O&M Costs (Real $/KW/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable O&M Costs (Real $/MWH)

  #
  # Scratch Variables
  #
  EGArea::VariableArray{2} = zeros(Float32, length(Area), length(Year)) # Electricity Generated (GWh/Yr)
  EGNGA::VariableArray{4} = zeros(Float32, length(Node), length(GenCo), length(Area), length(Year)) # Electricity Generated (GWh/Yr)
  EGNGATot::VariableArray{1} = zeros(Float32, length(Year)) # Electricity Generated (GWh/Yr)
  ImportsUR::VariableArray{2} = zeros(Float32, length(Area), length(Year)) # Electric Imports Unit Expenditures ($/MWh)
  SystemCost::VariableArray{1} = zeros(Float32, length(Year)) # Total System Cost (B$/Yr)

  ZZZ = zeros(Float32, length(Year))
end


function SetUnGC(data)
  (; Units) = data
  (; UnGC,UnOnLine,UnRetire) = data

  #
  # Set UnGC to zero if before Online date or after Retirement date
  #
  for unit in Units
    if (UnOnLine[unit] > ITime) && (UnOnLine[unit] <= MaxTime)
      Loc1=Int(min(UnOnLine[unit]-ITime+1-1,Final))
      years=collect(Zero:Loc1)
      for year in years
        UnGC[unit,year]=0
      end
    elseif (UnOnLine[unit] > MaxTime)
      years=collect(Zero:Final)
      for year in years
        UnGC[unit,year]=0
      end
    end
    if (UnRetire[unit] < MaxTime) && (UnRetire[unit] > ITime)
      Loc1=Int(max(UnRetire[unit]-ITime-1,1))
      years=collect(Loc1:Final)
      for year in years
        UnGC[unit,year]=0
      end
    end
  end

end

function ElectricAverageCost_DtaRun(data, TitleKey, TitleName, areas)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,GenCo,GenCoDS,GenCos,Month,MonthDS,Months) = data
  (; Node,NodeDS,Nodes,Plant,PlantDS,Plants,TimeP,TimePs,Unit,Units,CDTime,CDYear,Year) = data
  (; ArNdFr,CCR,EGNDA,EGPA,ExportsRevenues,ExportsUR,GCBL,ImportsExpenditures) = data
  (; Inflation,InflationUnit,MoneyUnitDS,NdArFr,SaECD,Subsidy,UnArea,UnAFC,UnAVC) = data
  (; UnCogen,UnEG,UnEGA,UnFP,UnGC,UnGCCC,UnHRt,UnNA,UnNation,UnOnLine,UnPCF) = data
  (; UnPlant,UnPoTR,UnRetire,UnSLDPR,UnUFOMC,UnUOMC) = data
  (; EGArea,EGNGA,EGNGATot,ImportsUR,SystemCost,ZZZ,SceName) = data  # Scratch Variables

  years = collect(Yr(2006):Final)

  iob = IOBuffer()

  area_single = first(areas)

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "This is the Average Cost of Energy Inputs and Outputs Summary.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  #
  # Weighting Factor
  #
  for year in years, area in areas
    EGArea[area,year]=sum(EGPA[plant,area,year] for plant in Plants)
  end
 
  #
  # Imports Unit Expenditures ($/MWh)
  #
  for year in years, area in areas
    ImportsUR[area,year]=ImportsExpenditures[area,year]/sum(SaECD[ecc,area,year] for ecc in ECCs)*1000
  end
  
  if TitleKey == "CN"
    units_nation=findall(UnNation[:] .== "CN")
    units_cogen=findall(UnCogen[:] .== 0)
    units=intersect(units_nation,units_cogen)
  elseif TitleKey == "US"
    units_nation=findall(UnNation[:] .== "US")
    units_cogen=findall(UnCogen[:] .== 0)
    units=intersect(units_nation,units_cogen)
  else
    units_area=findall(UnArea[:] .== TitleKey)
    units_cogen=findall(UnCogen[:] .== 0)
    units=intersect(units_area,units_cogen)
  end

  #
  # System Cost(B$)
  #
  print(iob, "$TitleName Total System Cost ($CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "TSC; Total System Cost ($CDTime $(MoneyUnitDS[area_single]))")
  for year in years
    if !isempty(units)
      SystemCost[year]=(sum((UnAVC[unit,year]*UnEGA[unit,year]+UnAFC[unit,year]*UnGC[unit,year])/
          InflationUnit[unit,year]*InflationUnit[unit,CDYear]*1000 for unit in units)+
          sum((ImportsExpenditures[area,year]-ExportsRevenues[area,year])/
          Inflation[area,year]*Inflation[area,CDYear]*1000000 for area in areas))/1000000000
      ZZZ[year]=SystemCost[year]
    else
      SystemCost[year]=0.0
      ZZZ[year]=SystemCost[year]
    end
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  #
  # Cost of Electricity ($/MWh)
  #
  print(iob, "$TitleName Cost of Electricity ($CDTime $(MoneyUnitDS[area_single])/MWh);")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
  #
  print(iob, "COE; Average Cost of Electricity ($CDTime $(MoneyUnitDS[area_single])/MWh)")
  for year in years
    @finite_math ZZZ[year]=SystemCost[year]*1000000000/sum(SaECD[ecc,area,year]*1000 for area in areas, ecc in ECCs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  # Cost of Generation ($/MWh)
  #
  print(iob, "UnACE; Average Cost of Generation ($CDTime $(MoneyUnitDS[area_single])/MWh)")
  for year in years
    if !isempty(units)
      @finite_math ZZZ[year]=sum((UnAVC[unit,year]*UnEGA[unit,year]+UnAFC[unit,year]*UnGC[unit,year])/
                  InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
                  sum(UnEGA[unit,year] for unit in units)
    else
      ZZZ[year]=0.0
    end
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  # Net Imports/Exports Costs ($/MWh)
  #
  print(iob, "NetImportsUR; Net Imports/Exports Costs ($CDTime $(MoneyUnitDS[area_single])/MWh)")
  for year in years
    if !isempty(units)
      ZZZ[year]=sum(ImportsUR[area,year]-ExportsUR[area,year] for area in areas)/
          Inflation[area_single,year]*Inflation[area_single,CDYear]
    else
      ZZZ[year]=0.0
    end
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Imports Expenditures ($/MWh)
  #
  print(iob, "ImportsUR; Imports Expenditures ($CDTime $(MoneyUnitDS[area_single])/MWh)")
  for year in years
    if !isempty(units)
      ZZZ[year]=sum(ImportsUR[area,year] for area in areas)/Inflation[area_single,year]*Inflation[area_single,CDYear]
    else
      ZZZ[year]=0.0
    end
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Exports Revenues ($/MWh)
  #
  print(iob, "ExportsUR; Exports Revenues ($CDTime $(MoneyUnitDS[area_single])/MWh)")
  for year in years
    if !isempty(units)
      ZZZ[year]=sum(ExportsUR[area,year] for area in areas)/Inflation[area_single,year]*Inflation[area_single,CDYear]
    else
      ZZZ[year]=0.0
    end
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")

  for plant in Plants
    for year in years, area in areas, genco in GenCos, node in Nodes
      EGNGA[node,genco,area,year]=EGNDA[plant,node,genco,year]*ArNdFr[area,node,year]
    end
    for year in years
      EGNGATot[year]=sum(EGNGA[node,genco,area,year] for area in areas, genco in GenCos, node in Nodes)
    end

    if TitleKey == "CN"
      units_nation=findall(UnNation[:] .== "CN")
      units_cogen=findall(UnCogen[:] .== 0)
      units_plant=findall(UnPlant[:] .== Plant[plant])
      units=intersect(units_nation,units_cogen,units_plant)
    elseif TitleKey == "US"
      units_nation=findall(UnNation[:] .== "US")
      units_cogen=findall(UnCogen[:] .== 0)
      units_plant=findall(UnPlant[:] .== Plant[plant])
      units=intersect(units_nation,units_cogen,units_plant)
    else
      units_area=findall(UnArea[:] .== TitleKey)
      units_cogen=findall(UnCogen[:] .== 0)
      units_plant=findall(UnPlant[:] .== Plant[plant])
      units=intersect(units_area,units_cogen,units_plant)
    end

    #
    # Cost of Generation ($/MWh)
    #
    print(iob, "$TitleName $(PlantDS[plant]) Cost of Generation ($CDTime $(MoneyUnitDS[area_single])/MWh);")
    for year in years
      print(iob,";",Year[year])
    end  
    println(iob)
    #
    print(iob, "UnACE; Cost of Generation ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum((UnAVC[unit,year]*UnEGA[unit,year]+UnAFC[unit,year]*UnGC[unit,year])/
            InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
            sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  
    #
    # Variable Cost ($/MWh)
    #
    print(iob, "UnAVC; Variable Cost ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnAVC[unit,year]*UnEGA[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
            sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fixed Cost ($/MWh)
    #
    print(iob, "UnAFC; Fixed Cost ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnAFC[unit,year]*UnGC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
          sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost ($/MWh) - we must divde and multiply by UnGC because of
    # units which have costs (UnNA, UnSLDPR), but have no capacity
    #
    print(iob, "UnCap; Capital Cost ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(((UnNA[unit,year]*CCR[plant,area_single,year]+UnSLDPR[unit,year])/InflationUnit[unit,year]*InflationUnit[unit,CDYear])/
            UnGC[unit,year]*UnGC[unit,year] for unit in units)*1000/sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Capital Cost ($/KW/Yr) - we must divde and multiply by UnGC because of
    # units which have costs (UnNA, UnSLDPR), but have no capacity
    #
    print(iob, "UnCap; Capital Cost ($CDTime $(MoneyUnitDS[area_single])/KW/Yr)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(((UnNA[unit,year]*CCR[plant,area_single,year]+UnSLDPR[unit,year])/InflationUnit[unit,year]*InflationUnit[unit,CDYear])/
            UnGC[unit,year]*UnGC[unit,year] for unit in units)*1000/sum(UnGC[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Overnight Construction Cost ($/KW)
    #
    print(iob, "UnGCCC; Overnight Construction Cost ($CDTime $(MoneyUnitDS[area_single])/KW)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnGCCC[unit,year]*UnGC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
          sum(UnGC[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Fixed O&M Cost ($/MWh)
    #
    print(iob, "UnUFOMC; Unit Fixed O&M Cost ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnUFOMC[unit,year]*UnGC[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
          sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Fixed O&M Cost ($/KW/Yr)
    #
    print(iob, "UnUFOMC; Unit Fixed O&M Cost ($CDTime $(MoneyUnitDS[area_single])/KW/Yr)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnUFOMC[unit,year]*UnGC[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
          sum(UnGC[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Capacity Subsidy ($/MWh)
    #
    print(iob, "Subsidy; Capacity Subsidy ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        ZZZ[year]=Subsidy[plant,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Variable O&M Cost ($/MWh)
    #
    print(iob, "UnUOMC; Unit O&M Cost ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnUOMC[unit,year]*InflationUnit[unit,CDYear]*UnEGA[unit,year] for unit in units)/
          sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Fuel Cost ($/MWh)
    #
    print(iob, "UnFP; Fuel Cost ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnFP[unit,month,year]*UnHRt[unit,year]/1000*UnEG[unit,timep,month,year]/
          InflationUnit[unit,year]*InflationUnit[unit,CDYear] for month in Months, timep in TimePs, unit in units)/
          sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Emission Cost ($/MWh)
    #
    print(iob, "UnPoTR; Emission Cost ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnPoTR[unit,year]*UnEGA[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)/
          sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Fuel Price ($/mmBtu)
    #
    print(iob, "UnFP; Fuel Price ($CDTime $(MoneyUnitDS[area_single])/mmBtu)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnFP[unit,month,year]*UnEG[unit,timep,month,year]/InflationUnit[unit,year]*InflationUnit[unit,CDYear] for month in Months, timep in TimePs, unit in units)/
          sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Heat Rate (Btu/KWh)
    #
    print(iob, "UnHRt; Heat Rate (Btu/KWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnHRt[unit,year]*UnEGA[unit,year] for unit in units)/
            sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Design Hours
    #
    print(iob, "UnPCF*8760; Operating Hours (Hours)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnEGA[unit,year] for unit in units)/sum(UnGC[unit,year]*8760/1000 for unit in units)*8760
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Plant Capacity Factor (MW/MW)
    #
    print(iob, "UnPCF; Plant Capacity Factor (MW/MW)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnEGA[unit,year] for unit in units)/sum(UnGC[unit,year]*8760/1000 for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Generation Capacity Physical Life (Years)
    #
    print(iob, "GCBL; Generation Capacity Book Life (Years)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(GCBL[plant,area,year]*
            EGNGA[node,genco,area,year] for area in areas, genco in GenCos, node in Nodes)/EGNGATot[year]
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Capital Charge Rate (1/Yr)
    #
    print(iob, "CCR; Capital Charge Rate (1/Yr)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(CCR[plant,area,year]*
            EGNGA[node,genco,area,year] for area in areas, genco in GenCos, node in Nodes)/EGNGATot[year]
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Net Asset Value ($/MWh)
    #
    print(iob, "UnNA; Net Asset Value ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnNA[unit,year]/UnGC[unit,year]*UnGC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)*1000/
            sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    # Depreciation ($/MWh)
    #
    print(iob, "UnSLDPR; Depreciation ($CDTime $(MoneyUnitDS[area_single])/MWh)")
    for year in years
      if !isempty(units)
        @finite_math ZZZ[year]=sum(UnSLDPR[unit,year]/UnGC[unit,year]*UnGC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,CDYear] for unit in units)*1000/
            sum(UnEGA[unit,year] for unit in units)
      else
        ZZZ[year]=0.0
      end
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)
  end

  filename = "ElectricAverageCost-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ElectricAverageCost_DtaControl(db)
  @info "ElectricAverageCost_DtaControl"
  data = ElectricAverageCostData(; db)
  Area = data.Area
  AreaDS = data.AreaDS


  SetUnGC(data)

  #
  # Canada
  #
  areas=Select(Area,(from ="ON",to="NU"))
  for area in areas
    ElectricAverageCost_DtaRun(data,Area[area],AreaDS[area],area)
  end
  ElectricAverageCost_DtaRun(data,"CN","Canada",areas)

  #
  # US
  #
  areas=Select(Area,(from ="CA",to="Pac"))
  for area in areas
    ElectricAverageCost_DtaRun(data,Area[area],AreaDS[area],area)
  end
  ElectricAverageCost_DtaRun(data,"US","United States",areas)

  #
  # MX
  #
  area=Select(Area,"MX")
  ElectricAverageCost_DtaRun(data,Area[area],AreaDS[area],area)
end

if abspath(PROGRAM_FILE) == @__FILE__
ElectricAverageCost_DtaControl(DB)
end
