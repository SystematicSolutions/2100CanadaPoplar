#
# UnitBidPrice.jl
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

Base.@kwdef struct UnitBidPriceData
  db::String

  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  TimeP::SetArray = ReadDisk(db, "MainDB/TimeP")
  TimePs::Vector{Int}    = collect(Select(TimeP))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int}    = collect(Select(Year))

  Yr2010 = 2010 - 1985 + 1

  HDFCFR::VariableArray{4} = ReadDisk(db, "EGInput/HDFCFR") #[Plant,GenCo,TimeP,Year]  Fraction of Fixed Costs
  HDHours::VariableArray{2} = ReadDisk(db, "EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HDVCFR::VariableArray{6} = ReadDisk(db, "EGInput/HDVCFR") #[Plant,GenCo,Node,TimeP,Month,Year]  Fraction of Variable Costs
  InflationUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationUnit") #[Unit,Year]  Inflation Index ($/$
  UnAFC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAFC") #[Unit,Year]  Average Fixed Costs ($/KW)
  UnArea::Vector{String} = ReadDisk(db, "EGInput/UnArea") #[Unit] Unit Area
  UnAVC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAVC") #[Unit,Year]  Average Variable Costs ($/MWh)
  UnAVCMonth::VariableArray{3} = ReadDisk(db, "EGOutput/UnAVCMonth") #[Unit,Month,Year]  Average Monthly Variable Costs ($/MWh)
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEG::VariableArray{4} = ReadDisk(db, "EGOutput/UnEG") #[Unit,TimeP,Month,Year]  Generation (GWh)
  UnEGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnEGA") #[Unit,Year]  Generation (GWh)
  UnFP::VariableArray{3} = ReadDisk(db, "EGOutput/UnFP") #[Unit,Month,Year]  Fuel Price ($/mmBtu)
  UnGCCC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCC") #[Unit,Year]  Generating Unit Capital Cost ($/KW)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{2} = ReadDisk(db, "EGInput/UnHRt") #[Unit,Year]  Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db, "EGInput/UnMustRun") #[Unit]  Must Run (1=Must Run)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnPCF::VariableArray{2} = ReadDisk(db, "EGOutput/UnPCF") #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UnPoTR::VariableArray{2} = ReadDisk(db, "EGOutput/UnPoTR") #[Unit,Year]  Pollution Tax Rate ($/MWh)
  UnPoTRExo::VariableArray{2} = ReadDisk(db, "EGInput/UnPoTRExo") #[Unit,Year]  Exogenous Pollution Tax Rate (Real $/MWh)
  UnUFOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUFOMC") #[Unit,Year]  Fixed O&M Costs ($/Kw/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUOMC") #[Unit,Year]  Variable O&M Costs ($/Kw/Yr)
  UnVCost::VariableArray{4} = ReadDisk(db, "EGOutput/UnVCost") #[Unit,TimeP,Month,Year]  Bid Price of Power Offered to Spot Market ($/MWh)

end

function UnitBidPrice_DtaRun(data, year, month, timep)
  (; SceName,GenCo,Months,MonthDS,Node,Plant,TimeP,Unit,Year,Yr2010) = data
  (; Plants, Units, Years, TimePs) = data
  (; HDFCFR,HDHours,HDVCFR,InflationUnit,UnAFC,UnArea,UnAVC) = data
  (; UnAVCMonth,UnCode,UnCogen,UnEG,UnEGA,UnFP,UnGCCC,UnGC) = data
  (; UnGenCo,UnHRt,UnMustRun,UnName,UnNode,UnPCF,UnPlant) = data
  (; UnPoTR,UnPoTRExo,UnUFOMC,UnUOMC,UnVCost) = data

  iob = IOBuffer()

  UnVCostCalc = zeros(Float32, length(Unit))
  UnAVCMonthCalc = zeros(Float32, length(Unit))
  UnPoTRCalc = zeros(Float32, length(Unit))
  UnAFCCalc = zeros(Float32, length(Unit))

  print(iob, "Year;","Time Period;","Month;","Unit Code;","Plant Name;","Area;","Node;")
  print(iob, "Plant Type;","Cogen;","Must Run;")
  print(iob, "UnAVC Variable Costs (2010 \$/MWH);")
  print(iob, "UnVCost Bid Price (2010 \$/MWH);")
  print(iob, "Bid Price Calc (2010 \$/MWH);")
  print(iob, "UnAVCMonth Average Monthly Variable Costs (2010 \$/MWh);")
  print(iob, "Average Monthly Variable Costs Calc (2010 \$/MWh);")
  print(iob, "Pollution Tax Rate (2010 \$/MWh);")
  print(iob, "Pollution Tax Rate Calc (2010 \$/MWh);")
  print(iob, "Fixed Costs (2010 \$/KW/Yr);")
  print(iob, "Fixed Costs Calc (2010 \$/KW/Yr);")
  print(iob, "Fraction of Variable Costs in Bid (\$/\$);")
  print(iob, "Fraction of Fixed Costs in Bid (\$/\$);")
  print(iob, "Fuel Price (2010 \$/mmBTU);")
  print(iob, "Heat Rate (Btu/KWH);")          
  print(iob, "Variable O&M Costs (2010 \$/MWH);")
  print(iob, "Exogenous Pollution Tax Rate (2010 \$/MWh);")
  print(iob, "Fixed O&M Costs (2010 \$/KW/Yr);")
  println(iob)

  for unit in Units
    if UnPlant[unit] != "Null"
      plant = Select(Plant,UnPlant[unit])
    else
      plant = ""
    end

    if UnGenCo[unit] != "Null"
      genco = Select(GenCo,UnGenCo[unit])
    else
      genco = ""
    end

    if UnNode[unit] != "Null"
      node = Select(Node,UnNode[unit])
    else
      node = ""
    end
  
    if !isempty(plant) && !isempty(genco) && !isempty(node)
      
      # 
      # Convert to 2010 $
      #
      UnVCost[unit,timep,month,year]=UnVCost[unit,timep,month,year]/
        InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
      UnAVCMonth[unit,month,year]=UnAVCMonth[unit,month,year]/
        InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
      UnPoTR[unit,year]=UnPoTR[unit,year]/InflationUnit[unit,year]*
        InflationUnit[unit,Yr2010]
      UnPoTRExo[unit,year]=UnPoTRExo[unit,year]*InflationUnit[unit,Yr2010]
      UnUOMC[unit,year]=UnUOMC[unit,year]/InflationUnit[unit,year]*
        InflationUnit[unit,Yr2010]
      UnUFOMC[unit,year]=UnUFOMC[unit,year]/InflationUnit[unit,year]*
        InflationUnit[unit,Yr2010]
      UnAFC[unit,year]=UnAFC[unit,year]/InflationUnit[unit,year]*
        InflationUnit[unit,Yr2010]
      UnAVC[unit,year]=UnAVC[unit,year]/InflationUnit[unit,year]*InflationUnit[unit,Yr2010]
      UnFP[unit,month,year]=UnFP[unit,month,year]/InflationUnit[unit,year]*
        InflationUnit[unit,Yr2010]
      
      #
      UnVCostCalc[unit]=UnAVCMonth[unit,month,year]*
        HDVCFR[plant,genco,node,timep,month,year]+UnPoTR[unit,year]*
          max(1-HDVCFR[plant,genco,node,timep,month,year],0)+
            (UnAFC[unit,year]/(8760*.75)*1000)*HDFCFR[plant,genco,timep,year]
      UnAVCMonthCalc[unit]=UnAVCMonth[unit,month,year]*
        HDVCFR[plant,genco,node,timep,month,year]
      UnPoTRCalc[unit]=UnPoTR[unit,year]*
        max(1-HDVCFR[plant,genco,node,timep,month,year],0)
      UnAFCCalc[unit]=(UnAFC[unit,year]/(8760*.75)*1000)*
        HDFCFR[plant,genco,timep,year]


      print(iob,Year[year])
      print(iob,";",timep)
      print(iob,";",MonthDS[month])
      print(iob,";",UnCode[unit])
      print(iob,";",UnName[unit])
      print(iob,";",UnArea[unit])
      print(iob,";",UnNode[unit])
      print(iob,";",UnPlant[unit])
      print(iob,";",UnCogen[unit])
      print(iob,";",UnMustRun[unit])
      print(iob,";",@sprintf("%.5f",UnAVC[unit,year]))
      print(iob,";",@sprintf("%.5f",UnVCost[unit,timep,month,year]))
      print(iob,";",@sprintf("%.5f",UnVCostCalc[unit]))
      print(iob,";",@sprintf("%.5f",UnAVCMonth[unit,month,year]))
      print(iob,";",@sprintf("%.5f",UnAVCMonthCalc[unit]))
      print(iob,";",@sprintf("%.5f",UnPoTR[unit,year]))
      print(iob,";",@sprintf("%.5f",UnPoTRCalc[unit]))
      print(iob,";",@sprintf("%.5f",UnAFC[unit,year]))
      print(iob,";",@sprintf("%.5f",UnAFCCalc[unit]))
      print(iob,";",@sprintf("%.5f",HDVCFR[plant,genco,node,timep,month,year]))
      print(iob,";",@sprintf("%.5f",HDFCFR[plant,genco,timep,year]))
      print(iob,";",@sprintf("%.5f",UnFP[unit,month,year]))
      print(iob,";",@sprintf("%.5f",UnHRt[unit,year]))
      print(iob,";",@sprintf("%.5f",UnUOMC[unit,year]))
      print(iob,";",@sprintf("%.5f",UnPoTRExo[unit,year]))
      print(iob,";",@sprintf("%.5f",UnUFOMC[unit,year]))
      println(iob)
    end
  end
 
  filename = "UnitBidPrice-$(MonthDS[month])-Period$timep-$(Year[year])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function RunYears(data::UnitBidPriceData, years, months, timeps)
  for year in years, month in months, timep in timeps
    UnitBidPrice_DtaRun(data, year, month, timep)
  end
end

function UnitBidPrice_DtaControl(db)
  @info "UnitBidPrice_DtaControl"
  data = UnitBidPriceData(; db)
  (; Months, TimePs, Year) = data

  Years = [Yr(2025),Yr(2035),Final]
  SelectedTimePs = [1,4,6]
  RunYears(data, Years, Months, SelectedTimePs)
end

if abspath(PROGRAM_FILE) == @__FILE__
UnitBidPrice_DtaControl(DB)
end

