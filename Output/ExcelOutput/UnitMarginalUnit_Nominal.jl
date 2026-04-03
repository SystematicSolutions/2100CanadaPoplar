#
# UnitMarginalUnit_Nominal.jl
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

Base.@kwdef struct UnitMarginalUnit_NominalData
  db::String

  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db, "MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db, "MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  TimeP::SetArray = ReadDisk(db, "MainDB/TimeP")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db, "MainDB/UnitKey")
  Units::Vector{Int}    = collect(Select(Unit))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int}    = collect(Select(Year))

  Yr2010 = 2010 - 1985 + 1

  HDFCFR::VariableArray{4} = ReadDisk(db, "EGInput/HDFCFR") #[Plant,GenCo,TimeP,Year]  Fraction of Fixed Costs
  HDHours::VariableArray{2} = ReadDisk(db, "EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HDPrA::VariableArray{4} = ReadDisk(db, "EOutput/HDPrA") #[Unit,TimeP,Month,Year]  Spot Market Marginal Price ($/MWh)
  HDVCFR::VariableArray{6} = ReadDisk(db, "EGInput/HDVCFR") #[Plant,GenCo,Node,TimeP,Month,Year]  Fraction of Variable Costs
  InflationNode::VariableArray{2} = ReadDisk(db, "MOutput/InflationNode") #[Node,Year]  Inflation Index ($/$
  InflationUnit::VariableArray{2} = ReadDisk(db, "MOutput/InflationUnit") #[Unit,Year]  Inflation Index ($/$
  UnAFC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAFC") #[Unit,Year]  Average Fixed Costs ($/KW)
  UnArea::Vector{String} = ReadDisk(db, "EGInput/UnArea") #[Unit] Unit Area
  UnAVC::VariableArray{2} = ReadDisk(db, "EGOutput/UnAVC") #[Unit,Year]  Average Variable Costs ($/MWh)
  UnCode::Vector{String} = ReadDisk(db, "EGInput/UnCode") #[Unit] IPM Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db, "EGInput/UnCogen") #[Unit]  Industrial Self-Generation Flag (1=Self-Generation)
  UnEG::VariableArray{4} = ReadDisk(db, "EGOutput/UnEG") #[Unit,TimeP,Month,Year]  Generation (GWh)
  UnEGA::VariableArray{2} = ReadDisk(db, "EGOutput/UnEGA") #[Unit,Year]  Generation (GWh)
  UnEGC::VariableArray{4} = ReadDisk(db, "EGOutput/UnEGC") #[Unit,TimeP,Month,Year]  Effective Generating Capacity (MW)
  UnF1::Vector{String} = ReadDisk(db, "EGInput/UnF1") #[Unit] Fuel Source 1
  UnFP::VariableArray{3} = ReadDisk(db, "EGOutput/UnFP") #[Unit,Month,Year]  Fuel Price ($/mmBtu)
  UnGCCC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGCCC") #[Unit,Year]  Generating Unit Capital Cost ($/KW)
  UnGC::VariableArray{2} = ReadDisk(db, "EGOutput/UnGC") #[Unit,Year]  Generating Capacity (MW)
  UnGCD::VariableArray{4} = ReadDisk(db, "EGOutput/UnGCD") #[Unit,TimeP,Month,Year]  Generating Capacity Dispatched (MW)
  UnGenCo::Vector{String} = ReadDisk(db, "EGInput/UnGenCo") #[Unit]  Generating Company
  UnHRt::VariableArray{2} = ReadDisk(db, "EGInput/UnHRt") #[Unit,Year]  Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db, "EGInput/UnMustRun") #[Unit]  Must Run (1=Must Run)
  UnName::Vector{String} = ReadDisk(db, "EGInput/UnName") #[Unit]  Plant Name
  UnNode::Vector{String} = ReadDisk(db, "EGInput/UnNode") #[Unit]  Transmission Node
  UnPCF::VariableArray{2} = ReadDisk(db, "EGOutput/UnPCF") #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Vector{String} = ReadDisk(db, "EGInput/UnPlant") #[Unit]  Plant Type
  UnPoTR::VariableArray{2} = ReadDisk(db, "EGOutput/UnPoTR") #[Unit,Year]  Pollution Tax Rate ($/MWh)
  UnUFOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUFOMC") #[Unit,Year]  Fixed O&M Costs ($/Kw/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db, "EGInput/UnUOMC") #[Unit,Year]  Variable O&M Costs ($/Kw/Yr)
  UnVCost::VariableArray{4} = ReadDisk(db, "EGOutput/UnVCost") #[Unit,TimeP,Month,Year]  Bid Price of Power Offered to Spot Market ($/MWh)
  UnCounter::VariableArray{1} = ReadDisk(db, "EGInput/UnCounter") #[Year]  Number of Units
    

end

function UnitMarginalUnit_Nominal_DtaRun(data, node)
  (; SceName,GenCo,Month,MonthDS,Months,Node,NodeDS,Plant,TimeP,TimePs,Unit,Year,Yr2010) = data
  (; HDFCFR,HDHours,HDPrA,HDVCFR,InflationNode,InflationUnit) = data
  (; UnAFC,UnArea,UnAVC,UnCode,UnCogen,UnEG,UnEGA,UnEGC,UnF1) = data
  (; UnFP,UnGCCC,UnGC,UnGCD,UnGenCo,UnHRt,UnMustRun,UnName) = data
  (; UnNode,UnPCF,UnPlant,UnPoTR,UnUFOMC,UnUOMC,UnVCost, UnCounter) = data

  iob = IOBuffer()

  PCF::VariableArray{4} = zeros(Float32, length(Unit), length(TimeP), length(Month), length(Year))
  UnUFC::VariableArray{1} = zeros(Float32, length(Unit))


  print(iob, "Node;","Year;","Month;","Time Period;","Unit Code;","Plant Name;","Area;")
  print(iob, "Plant Type;")
  print(iob, "Fuel;")
  print(iob, "Bid Price (\$/MWH);")
  print(iob, "System Price (\$/MWH);")
  print(iob, "Dispatched (MW);")
  print(iob, "Available (MW);")
  print(iob, "Variable Costs (\$/MWH);")
  print(iob, "Fixed Costs (\$/KW/Yr);")
  print(iob, "Fuel Costs (\$/MWH);")
  print(iob, "Variable O&M Costs (\$/MWH);")
  print(iob, "Emission Costs (\$/MWH);")
  print(iob, "Fixed O&M Costs (\$/KW/Yr);")
  print(iob, "Heat Rate (Btu/KWH);")          
  print(iob, "Fuel Price (\$/mmBTU);")          
  print(iob, "Fraction of Variable Costs in Bid (\$/\$);")          
  print(iob, "Fraction of Fixed Costs in Bid (\$/\$);")          
  print(iob, "Capital Cost (\$/Kw);")          
  print(iob, "Generation (GWh);")          
  print(iob, "Capacity Factor (KWh/KWh);")          
  print(iob, "Capacity (MW);")          
  print(iob, "Annual Generation (GWh);")          
  print(iob, "Annual Capacity Factor (KWh/KWh);")          
  println(iob)

  #
  # Loops determine order of output results - Jeff Amlin 9/8/25
  #
  years = collect(Future:Final)
  for year in years
    for month in Months
      for timep in TimePs

        UnitsEG = findall(UnEG[:,timep,month,year] .> 0.0)
        UnitsNode = findall(UnNode[:] .== Node[node])
        UnitsCogen = Select(UnCogen,==(0.0))
        UnitsCount = 1:Int(UnCounter[year])   
        SelectedUnits = intersect(UnitsEG,UnitsNode,UnitsCogen,UnitsCount)
    
        if !isempty(SelectedUnits)
          sort!(SelectedUnits; by = u -> UnVCost[u,timep,month,year], rev = true)
        else
          SelectedUnits = 1
        end

        for unit in SelectedUnits
          if UnEG[unit,timep,month,year] > 0.0
            if (UnPlant[unit] !="Null") && (UnGenCo[unit] !="Null")
              genco = Select(GenCo,UnGenCo[unit])
              plant = Select(Plant,UnPlant[unit])
            
              UnUOMC[unit,year]=UnUOMC[unit,year]*InflationUnit[unit,Yr2010]
              UnUFOMC[unit,year]=UnUFOMC[unit,year]*InflationUnit[unit,Yr2010]
  
              #
              print(iob, UnNode[unit])
              print(iob,";",Year[year])
              print(iob,";",MonthDS[month])
              print(iob,";",timep)
              print(iob,";",UnCode[unit])
              print(iob,";",UnName[unit])
              print(iob,";",UnArea[unit])
              print(iob,";",UnPlant[unit])
              print(iob,";",UnF1[unit])
              print(iob,";",@sprintf("%.5f", UnVCost[unit,timep,month,year]))
              print(iob,";",@sprintf("%.5f", HDPrA[node,timep,month,year]))
              print(iob,";",@sprintf("%.5f", UnGCD[unit,timep,month,year]))
              print(iob,";",@sprintf("%.5f", UnEGC[unit,timep,month,year]))
              print(iob,";",@sprintf("%.5f", UnAVC[unit,year]))
              print(iob,";",@sprintf("%.5f", UnAFC[unit,year]))
              print(iob,";",@sprintf("%.5f", UnUFC[unit]))
              print(iob,";",@sprintf("%.5f", UnUOMC[unit,year]))
              print(iob,";",@sprintf("%.5f", UnPoTR[unit,year]))
              print(iob,";",@sprintf("%.5f", UnUFOMC[unit,year]))
              print(iob,";",@sprintf("%.5f", UnHRt[unit,year]))
              print(iob,";",@sprintf("%.5f", UnFP[unit,month,year]))
              print(iob,";",@sprintf("%.5f", HDVCFR[plant,genco,node,timep,month,year]))
              print(iob,";",@sprintf("%.5f", HDFCFR[plant,genco,timep,year]))
              print(iob,";",@sprintf("%.5f", UnGCCC[unit,year]))
              print(iob,";",@sprintf("%.5f", UnEG[unit,timep,month,year]))
              print(iob,";",@sprintf("%.5f", PCF[unit,timep,month,year]))
              print(iob,";",@sprintf("%.5f", UnGC[unit,year]))
              print(iob,";",@sprintf("%.5f", UnEGA[unit,year]))
              print(iob,";",@sprintf("%.5f", UnPCF[unit,year]))
              println(iob)
            else
              nothing
            end
          end
        end
      end # TimeP   
    end # months 
  end # years
 
  filename = "UnitMarginalUnit_Nominal-$(Node[node])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function RunYears(data, node)
  UnitMarginalUnit_Nominal_DtaRun(data, node)
end

function UnitMarginalUnit_Nominal_DtaControl(db)
  @info "UnitMarginalUnit_Nominal_DtaControl"
  data = UnitMarginalUnit_NominalData(; db)
  (; Node) = data
  nodes = Select(Node,["MB","SK","LB","QC","NB","ON","AB","BC","NS","NL","PE","YT","NT","NU"])
  for node in nodes
    RunYears(data, node)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
UnitMarginalUnit_Nominal_DtaControl(DB)
end
