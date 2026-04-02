#
# Electric_Patch.jl
#
# This file is used to fix issues related to a specific scenario.
# Normally, all fixes should be removed when preparing a new scenario.
# The file is organized in several sections:
#
# SECTION 1: increase hydropower with (UnEAF): usually to resolve emergency power
# SECTION 2: increase power plant generation with (UnOR): usually to resolve emergency power or increase thermal power generation
# SECTION 3: manage problematic power plants (UnRetire, UnOnline, UnOR)
# SECTION 4: increase coal power generation (HDVCFR, AvFactor): E2020 tends to under estimate coal power generation in projections
# SECTION 5: reserve margin (DRM): could be used to resolve emergency power
# 
# Other codes (to be cleaned):
#     - Edits for CER CGII (temporary): this section will be moved to the relevant files
#     - Capacity transmission and contracts: this section will be moved to the relevant files
#      (a Section 6 will be created for adjusting LLMax and HDXload to resolve scenario issues) 
#     - Design hours: this section will be moved to the relevant files (could it be used in a new Section 7?)
#

using EnergyModel

module Electric_Patch

import ...EnergyModel: ReadDisk, WriteDisk, Select
import ...EnergyModel: HisTime, ITime, MaxTime, First, Future, Final, Yr
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  #year::Int
  
  # Sets
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey") 
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  NodeX::SetArray = ReadDisk(db,"MainDB/NodeXKey")
  NodeXs::Vector{Int} = collect(Select(NodeX))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  Powers::Vector{Int} = collect(Select(Power))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  # Variables
  AvFactor::VariableArray{5} = ReadDisk(db,"EGInput/AvFactor") # [Plant,TimeP,Month,Area,Year] Availability Factor (MW/MW)
  BuildSw::VariableArray{2} = ReadDisk(db,"EGInput/BuildSw") # [Area,Year] Build switch
  DesHr::VariableArray{4} = ReadDisk(db,"EGInput/DesHr") # [Plant,Power,Area,Year] Design Hours (Hours)
  DRM::VariableArray{2} = ReadDisk(db,"EInput/DRM") # [Node,Year] Desired Reserve Margin (MW/MW)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") # [TimeP,Month] Number of Hours in the Interval (Hours)
  HDVCFR::VariableArray{6} = ReadDisk(db,"EGInput/HDVCFR") # [Plant,GenCo,Node,TimeP,Month,Year] Fraction of Variable Costs Bid ($/$)
  HDXLoad::VariableArray{5} = ReadDisk(db,"EGInput/HDXLoad") # [Node,NodeX,TimeP,Month,Year] Exogenous Loading on Transmission Lines (MW)
  LLMax::VariableArray{5} = ReadDisk(db,"EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
  TPRMap::VariableArray{2} = ReadDisk(db,"EGInput/TPRMap") # [TimeP,Power] TimeP to Power Map
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Availability Factor
  #xUnEGC::VariableArray{3} = ReadDisk(db,"EGInput/xUnEGC",year) #[Unit,TimeP,Month,Year]  Exogenous Effective Generating Capacity (MW)
  UnFlFrMax::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMax") # [Unit,FuelEP,Year] Fuel Fraction Maximum
  UnFlFrMin::VariableArray{3} = ReadDisk(db,"EGInput/UnFlFrMin") # [Unit,FuelEP,Year] Fuel Fraction Minimum
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run Flag
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnOOR::VariableArray{2} = ReadDisk(db,"EGCalDB/UnOOR") # [Unit,Year] Operational Outage Rate (MW/MW)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  UnSource::VariableArray{1} = ReadDisk(db,"EGInput/UnSource") # [Unit] Source Flag
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable Costs Per Unit ($/MWh)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  xUnVCost::VariableArray{4} = ReadDisk(db,"EGInput/xUnVCost") # [Unit,TimeP,Month,Year] Exogenous Market Price Bid ($/MWh)
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,FuelEP,GenCo,Month,Node,NodeX,Plant,Power,TimeP,Unit,Year) = data
  (; Areas,FuelEPs,GenCos,Months,Nodes,NodeXs,Plants,Powers,TimePs,Units,Years) = data
  (; AvFactor,BuildSw,DesHr,DRM,HDHours,HDVCFR,HDXLoad,LLMax) = data
  (; UnArea,UnCode,UnCogen,UnEAF,UnFlFrMax,UnFlFrMin) = data
  (; UnGenCo,UnHRt,UnMustRun,UnNode,UnNation,UnOnLine,UnUOMC) = data
  (; UnOOR,UnOR,UnPlant,UnRetire,UnSource,xUnFlFr,xUnVCost) = data


  #
  # SECTION 0: Temporary (will be moved to vData:vHDxLoad) [TD 2025-10-02]
  #

  #
  # Quebec (QC) to New England (ISNE) (Energy contract ~10 TWh/year)
  #
  node = Select(Node,"ISNE")
  nodex = Select(NodeX,"QC")
  # 2024  
  for timep in TimePs, month in Months
    HDXLoad[node,nodex,timep,month,Yr(2024)] = 0
  end
  # 2025-2034
  Years = collect(Yr(2025):Yr(2034))
  # Summer
  month = Select(Month,"Summer")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 25
    HDXLoad[node,nodex,2,month,year] = 50
    HDXLoad[node,nodex,3,month,year] = 76
    HDXLoad[node,nodex,4,month,year] = 251
    HDXLoad[node,nodex,5,month,year] = 604
    HDXLoad[node,nodex,6,month,year] = 1509
  end
  # Winter
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 25
    HDXLoad[node,nodex,2,month,year] = 51
    HDXLoad[node,nodex,3,month,year] = 75
    HDXLoad[node,nodex,4,month,year] = 251
    HDXLoad[node,nodex,5,month,year] = 604
    HDXLoad[node,nodex,6,month,year] = 1509
  end
  # 2035-2050
  Years = collect(Yr(2035):Final)
  # Summer
  month = Select(Month,"Summer")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 9
    HDXLoad[node,nodex,2,month,year] = 27
    HDXLoad[node,nodex,3,month,year] = 54
    HDXLoad[node,nodex,4,month,year] = 145
    HDXLoad[node,nodex,5,month,year] = 363
    HDXLoad[node,nodex,6,month,year] = 906
  end
  # Winter
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 9
    HDXLoad[node,nodex,2,month,year] = 27
    HDXLoad[node,nodex,3,month,year] = 55
    HDXLoad[node,nodex,4,month,year] = 145
    HDXLoad[node,nodex,5,month,year] = 363
    HDXLoad[node,nodex,6,month,year] = 906
  end

  #
  # Quebec (QC) to New York (NYUP) (Energy contract ~10 TWh/year)
  #
  node = Select(Node,"NYUP")
  nodex = Select(NodeX,"QC")
  # 2024-2025
  for timep in TimePs, month in Months
    HDXLoad[node,nodex,timep,month,Yr(2024)] = 0
    HDXLoad[node,nodex,timep,month,Yr(2025)] = 0
  end
  # 2026-2050
  Years = collect(Yr(2026):Yr(2027))
  # Summer
  month = Select(Month,"Summer")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 10
    HDXLoad[node,nodex,2,month,year] = 30
    HDXLoad[node,nodex,3,month,year] = 60
    HDXLoad[node,nodex,4,month,year] = 160
    HDXLoad[node,nodex,5,month,year] = 399
    HDXLoad[node,nodex,6,month,year] = 998
  end
  # Winter
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 10
    HDXLoad[node,nodex,2,month,year] = 30
    HDXLoad[node,nodex,3,month,year] = 60
    HDXLoad[node,nodex,4,month,year] = 160
    HDXLoad[node,nodex,5,month,year] = 399
    HDXLoad[node,nodex,6,month,year] = 997
  end
  Years = collect(Yr(2028):Yr(2031))
  # Summer
  month = Select(Month,"Summer")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 28
    HDXLoad[node,nodex,2,month,year] = 55
    HDXLoad[node,nodex,3,month,year] = 83
    HDXLoad[node,nodex,4,month,year] = 277
    HDXLoad[node,nodex,5,month,year] = 664
    HDXLoad[node,nodex,6,month,year] = 1661
  end
  # Winter
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 28
    HDXLoad[node,nodex,2,month,year] = 56
    HDXLoad[node,nodex,3,month,year] = 83
    HDXLoad[node,nodex,4,month,year] = 276
    HDXLoad[node,nodex,5,month,year] = 665
    HDXLoad[node,nodex,6,month,year] = 1661
  end
  Years = collect(Yr(2032):Yr(2050))
  # Summer
  month = Select(Month,"Summer")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 10
    HDXLoad[node,nodex,2,month,year] = 30
    HDXLoad[node,nodex,3,month,year] = 60
    HDXLoad[node,nodex,4,month,year] = 160
    HDXLoad[node,nodex,5,month,year] = 399
    HDXLoad[node,nodex,6,month,year] = 998
  end
  # Winter
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 10
    HDXLoad[node,nodex,2,month,year] = 30
    HDXLoad[node,nodex,3,month,year] = 60
    HDXLoad[node,nodex,4,month,year] = 160
    HDXLoad[node,nodex,5,month,year] = 399
    HDXLoad[node,nodex,6,month,year] = 997
  end
  #
  # QC to NB (Capacity contract, 2 TWh/year)
  #
  node = Select(Node,"NB")
  nodex = Select(NodeX,"QC")
  Years = collect(Future:Final)
  for timep in TimePs, month in Months, year in Years
    HDXLoad[node,nodex,timep,month,year] = 137
  end

  #
  # QC to Ontario (ON) (removing contract in 2024 because of emergency power)
  #
  node = Select(Node,"ON")
  nodex = Select(NodeX,"QC")
  for timep in TimePs, month in Months
    HDXLoad[node,nodex,timep,month,Yr(2024)] = 0
  end

  #
  # NL to NS (2 TWh per year, flat capacity contract)
  #
  node = Select(Node,"NS")
  nodex = Select(NodeX,"NL")
  # 2024-2025 Emergency Power: capacity increased
  Years = collect(Yr(2024):Yr(2025))
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 440
    HDXLoad[node,nodex,2,month,year] = 440
    HDXLoad[node,nodex,3,month,year] = 440
    HDXLoad[node,nodex,4,month,year] = 240
    HDXLoad[node,nodex,5,month,year] = 140
    HDXLoad[node,nodex,6,month,year] = 140
  end
  month = Select(Month,"Summer")
  for timep in TimePs, year in Years
    HDXLoad[node,nodex,timep,month,year] = 140
  end
  # 2026-2050 (regular contract)
  Years = collect(Yr(2026):Final)
  for timep in TimePs, month in Months, year in Years
    HDXLoad[node,nodex,timep,month,year] = 140
  end
  
  #
  # NS to NB (1.5 TWh per year, flat capacity contract)
  #
  node = Select(Node,"NB")
  nodex = Select(NodeX,"NS")
  # Winter 2024-2025 (emergency power)
  Years = collect(Yr(2024):Yr(2025))
  month = Select(Month,"Winter")
  for timep in TimePs, year in Years
    HDXLoad[node,nodex,1,month,year] = 0
    HDXLoad[node,nodex,2,month,year] = 0
    HDXLoad[node,nodex,3,month,year] = 0
    HDXLoad[node,nodex,4,month,year] = 0
    HDXLoad[node,nodex,5,month,year] = 100
    HDXLoad[node,nodex,6,month,year] = 100
  end
  # Summer 2024-2025 (contract not modified)
  month = Select(Month,"Summer")
  for timep in TimePs, year in Years
    HDXLoad[node,nodex,timep,month,year] = 100
  end
  # Summer 2026-2050 (contract not modified)
   Years = collect(Yr(2026):Final)
   for timep in TimePs, month in Months, year in Years
     HDXLoad[node,nodex,timep,month,year] = 100
   end

  #
  # NB to PE (0.5 TWh per year, flat capacity contract)
  #
  node = Select(Node,"PE")
  nodex = Select(NodeX,"NB")
  Years = collect(Future:Final)
  for timep in TimePs, month in Months, year in Years
    HDXLoad[node,nodex,timep,month,year] = 34
  end

  #
  # NB to New England (1.4 TWh per year, energy contract)
  #
  node = Select(Node,"ISNE")
  nodex = Select(NodeX,"NB")
  
  # reducing 2024 to resolve emergency power
  for timep in TimePs, month in Months
    HDXLoad[node,nodex,timep,month,Yr(2024)] = 0
  end
  
  Years = collect(Yr(2025):Final)
   # Summer
    month = Select(Month,"Summer")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 1
    HDXLoad[node,nodex,2,month,year] = 4
    HDXLoad[node,nodex,3,month,year] = 8
    HDXLoad[node,nodex,4,month,year] = 21
    HDXLoad[node,nodex,5,month,year] = 54
    HDXLoad[node,nodex,6,month,year] = 134
  end
  # Winter
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 1
    HDXLoad[node,nodex,2,month,year] = 4
    HDXLoad[node,nodex,3,month,year] = 8
    HDXLoad[node,nodex,4,month,year] = 21
    HDXLoad[node,nodex,5,month,year] = 54
    HDXLoad[node,nodex,6,month,year] = 134
  end  

  #
  # MB to SK (energy=2023 data, capacity contract)
  #
  node = Select(Node,"SK")
  nodex = Select(NodeX,"MB")
  
  # Delaying contract because it seems to replace thermal power in SK
  Years = collect(Future:Yr(2029))
  for timep in TimePs, month in Months, year in Years
    HDXLoad[node,nodex,timep,month,year] = 0
  end
  
  Years = collect(Yr(2030):Final)
   # Summer
  month = Select(Month,"Summer")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 315
    HDXLoad[node,nodex,2,month,year] = 315
    HDXLoad[node,nodex,3,month,year] = 315
    HDXLoad[node,nodex,4,month,year] = 132
    HDXLoad[node,nodex,5,month,year] = 132
    HDXLoad[node,nodex,6,month,year] = 128
  end
  # Winter
  month = Select(Month,"Winter")
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 304
    HDXLoad[node,nodex,2,month,year] = 304
    HDXLoad[node,nodex,3,month,year] = 304
    HDXLoad[node,nodex,4,month,year] = 132
    HDXLoad[node,nodex,5,month,year] = 132
    HDXLoad[node,nodex,6,month,year] = 128
  end
  
  #
  # BC to YT
  #
  # TD 2025-10-15: we don't have precise info on this contract but it seems oversized in the early year,
  # causing YT to reduce hydro power generation. I designed it as a capacity contract for peak time,
  # starting progressively over the 5 first years

  node = Select(Node,"YT")
  nodex = Select(NodeX,"BC")
  for month in Months
    HDXLoad[node,nodex,1,month,Yr(2024)] = 1.33
    HDXLoad[node,nodex,2,month,Yr(2024)] = 1.33
    HDXLoad[node,nodex,3,month,Yr(2024)] = 0.67
    HDXLoad[node,nodex,4,month,Yr(2024)] = 0.50
    HDXLoad[node,nodex,5,month,Yr(2024)] = 0.33
    HDXLoad[node,nodex,6,month,Yr(2024)] = 0.17
  end
  for month in Months
    HDXLoad[node,nodex,1,month,Yr(2025)] = 1.6
    HDXLoad[node,nodex,2,month,Yr(2025)] = 1.6
    HDXLoad[node,nodex,3,month,Yr(2025)] = 0.8
    HDXLoad[node,nodex,4,month,Yr(2025)] = 0.6
    HDXLoad[node,nodex,5,month,Yr(2025)] = 0.4
    HDXLoad[node,nodex,6,month,Yr(2025)] = 0.2
  end
  for month in Months
    HDXLoad[node,nodex,1,month,Yr(2026)] = 2
    HDXLoad[node,nodex,2,month,Yr(2026)] = 2
    HDXLoad[node,nodex,3,month,Yr(2026)] = 1
    HDXLoad[node,nodex,4,month,Yr(2026)] = 0.75
    HDXLoad[node,nodex,5,month,Yr(2026)] = 0.5
    HDXLoad[node,nodex,6,month,Yr(2026)] = 0.25
  end
  for month in Months
    HDXLoad[node,nodex,1,month,Yr(2027)] = 2.67
    HDXLoad[node,nodex,2,month,Yr(2027)] = 2.67
    HDXLoad[node,nodex,3,month,Yr(2027)] = 1.33
    HDXLoad[node,nodex,4,month,Yr(2027)] = 1
    HDXLoad[node,nodex,5,month,Yr(2027)] = 0.67
    HDXLoad[node,nodex,6,month,Yr(2027)] = 0.33
  end
    for month in Months
    HDXLoad[node,nodex,1,month,Yr(2028)] = 4
    HDXLoad[node,nodex,2,month,Yr(2028)] = 4
    HDXLoad[node,nodex,3,month,Yr(2028)] = 2
    HDXLoad[node,nodex,4,month,Yr(2028)] = 1.5
    HDXLoad[node,nodex,5,month,Yr(2028)] = 1
    HDXLoad[node,nodex,6,month,Yr(2028)] = 0.5
  end
  Years = collect(Yr(2029):Yr(2050))
  for month in Months, year in Years
    HDXLoad[node,nodex,1,month,year] = 8
    HDXLoad[node,nodex,2,month,year] = 8
    HDXLoad[node,nodex,3,month,year] = 4
    HDXLoad[node,nodex,4,month,year] = 3
    HDXLoad[node,nodex,5,month,year] = 2
    HDXLoad[node,nodex,6,month,year] = 1
  end

  #
  # NWPP (US) to BC
  #
  node = Select(Node,"BC")
  nodex = Select(NodeX,"NWPP")
  # Summer (Winter is 0 in vData)
  month = Select(Month,"Summer")
  Years = collect(Yr(2024):Yr(2029))
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 660
    HDXLoad[node,nodex,2,month,year] = 565
    HDXLoad[node,nodex,3,month,year] = 200
    HDXLoad[node,nodex,4,month,year] = 200
    HDXLoad[node,nodex,5,month,year] = 150
    HDXLoad[node,nodex,6,month,year] = 100
  end
  Years = collect(Yr(2030):Yr(2030))
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 590
    HDXLoad[node,nodex,2,month,year] = 590
    HDXLoad[node,nodex,3,month,year] = 200
    HDXLoad[node,nodex,4,month,year] = 200
    HDXLoad[node,nodex,5,month,year] = 150
    HDXLoad[node,nodex,6,month,year] = 100
  end
  Years = collect(Yr(2031):Yr(2031))
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 573
    HDXLoad[node,nodex,2,month,year] = 573
    HDXLoad[node,nodex,3,month,year] = 213
    HDXLoad[node,nodex,4,month,year] = 200
    HDXLoad[node,nodex,5,month,year] = 150
    HDXLoad[node,nodex,6,month,year] = 100
  end
  Years = collect(Yr(2032):Yr(2032))
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 565
    HDXLoad[node,nodex,2,month,year] = 565
    HDXLoad[node,nodex,3,month,year] = 216
    HDXLoad[node,nodex,4,month,year] = 200
    HDXLoad[node,nodex,5,month,year] = 150
    HDXLoad[node,nodex,6,month,year] = 100
  end
  Years = collect(Yr(2033):Yr(2033))
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 558
    HDXLoad[node,nodex,2,month,year] = 558
    HDXLoad[node,nodex,3,month,year] = 223
    HDXLoad[node,nodex,4,month,year] = 200
    HDXLoad[node,nodex,5,month,year] = 150
    HDXLoad[node,nodex,6,month,year] = 100
  end
  Years = collect(Yr(2034):Yr(2044))
  for year in Years
    HDXLoad[node,nodex,1,month,year] = 550
    HDXLoad[node,nodex,2,month,year] = 550
    HDXLoad[node,nodex,3,month,year] = 225
    HDXLoad[node,nodex,4,month,year] = 200
    HDXLoad[node,nodex,5,month,year] = 150
    HDXLoad[node,nodex,6,month,year] = 100
  end


  WriteDisk(db,"EGInput/HDXLoad",HDXLoad)


  #
  # SECTION 1: Increase/Decrease hydropower with UnEAF and UnOR
  #
  
  # Labrador (LB) - Emergency Power
  unit1 = Select(UnNation, ==("CN"))
  unit3 = Select(UnNode, ==("LB"))
  unit4 = Select(UnCogen, ==(0))
  unit5 = Select(UnPlant, ==("PeakHydro"))
  units = intersect(unit1, unit3, unit4, unit5)
  # Summer
  month = Select(Month,"Summer")
  for unit in units
    UnEAF[unit,month,Yr(2024)] *= 1.198*1.084*1.01
    UnEAF[unit,month,Yr(2025)] *= 1.200*1.085
    UnEAF[unit,month,Yr(2026)] *= 1.199*1.085
    UnEAF[unit,month,Yr(2027)] *= 1.162*1.069*1.046*1.005
    UnEAF[unit,month,Yr(2028)] *= 1.151*1.064*1.042*1.005
    UnEAF[unit,month,Yr(2029)] *= 1.140*1.059*1.040*1.005
    UnEAF[unit,month,Yr(2030)] *= 1.129*1.054*1.037*1.005
    UnEAF[unit,month,Yr(2031)] *= 1.116*1.05*1.034*1.005
    UnEAF[unit,month,Yr(2032)] *= 1.089*1.037*1.034*1.005
    UnEAF[unit,month,Yr(2033)] *= 1.074*1.032*1.029*1.005
  end
  # Winter
  month = Select(Month,"Winter")
  for unit in units
    UnEAF[unit,month,Yr(2024)] *= 1.198*1.001
    UnEAF[unit,month,Yr(2025)] *= 1.200*1.003
    UnEAF[unit,month,Yr(2026)] *= 1.199*1.003
    UnEAF[unit,month,Yr(2027)] *= 1.162
    UnEAF[unit,month,Yr(2028)] *= 1.151
    UnEAF[unit,month,Yr(2029)] *= 1.140
    UnEAF[unit,month,Yr(2030)] *= 1.129
    UnEAF[unit,month,Yr(2031)] *= 1.116
    UnEAF[unit,month,Yr(2032)] *= 1.089
    UnEAF[unit,month,Yr(2033)] *= 1.074
  end

# Alberta (AB) - Emergency Power
  unit1 = Select(UnNation, ==("CN"))
  unit2 = Select(UnNode, ==("AB"))
  unit3 = Select(UnCogen, ==(0))
  # Hydro Power
  peakhydro = Select(UnPlant, ==("PeakHydro"))
  units = intersect(unit1, unit2, unit3, peakhydro)
  # UnEAF Summer
  month = Select(Month,"Summer")
  for unit in units
    UnEAF[unit,month,Yr(2024)] *= 1.04
    UnEAF[unit,month,Yr(2025)] *= 1.01
  end
  # UnEAF Winter
  month = Select(Month,"Winter")
  for unit in units
    UnEAF[unit,month,Yr(2024)] *= 1.07
    UnEAF[unit,month,Yr(2025)] *= 1.25
    UnEAF[unit,month,Yr(2026)] *= 1.02
  end
  # Thermal power
  # UnOR OGSteam
  ogsteam = Select(UnPlant, ==("OGSteam"))
  units = intersect(unit1, unit2, unit3, ogsteam)
  month = Select(Month,"Summer")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.5
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.5
    UnOR[unit,1,month,Yr(2025)] = UnOR[unit,1,month,Yr(2025)] * 0.5
    UnOR[unit,2,month,Yr(2025)] = UnOR[unit,2,month,Yr(2025)] * 0.5
  end
  month = Select(Month,"Winter")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.5
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.5
    UnOR[unit,1,month,Yr(2025)] = UnOR[unit,1,month,Yr(2025)] * 0.5
    UnOR[unit,2,month,Yr(2025)] = UnOR[unit,2,month,Yr(2025)] * 0.5
    UnOR[unit,1,month,Yr(2026)] = UnOR[unit,1,month,Yr(2026)] * 0.5
    UnOR[unit,2,month,Yr(2026)] = UnOR[unit,2,month,Yr(2026)] * 0.5
  end
  # UnOR OGCT
  ogct = Select(UnPlant, ==("OGCT"))
  units = intersect(unit1, unit2, unit3, ogct)
  month = Select(Month,"Summer")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.5
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.5
    UnOR[unit,1,month,Yr(2025)] = UnOR[unit,1,month,Yr(2025)] * 0.5
    UnOR[unit,2,month,Yr(2025)] = UnOR[unit,2,month,Yr(2025)] * 0.5
  end
  month = Select(Month,"Winter")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.5
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.5
    UnOR[unit,1,month,Yr(2025)] = UnOR[unit,1,month,Yr(2025)] * 0.5
    UnOR[unit,2,month,Yr(2025)] = UnOR[unit,2,month,Yr(2025)] * 0.5
    UnOR[unit,3,month,Yr(2025)] = UnOR[unit,3,month,Yr(2025)] * 0.75
    UnOR[unit,1,month,Yr(2026)] = UnOR[unit,1,month,Yr(2026)] * 0.5
    UnOR[unit,2,month,Yr(2026)] = UnOR[unit,2,month,Yr(2026)] * 0.5
  end
  # UnOR OGCC
  ogcc = Select(UnPlant, ==("OGCC"))
  units = intersect(unit1, unit2, unit3, ogcc)
  month = Select(Month,"Summer")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.5
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.5
    UnOR[unit,1,month,Yr(2025)] = UnOR[unit,1,month,Yr(2025)] * 0.5
    UnOR[unit,2,month,Yr(2025)] = UnOR[unit,2,month,Yr(2025)] * 0.5
  end
  month = Select(Month,"Winter")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.5
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.5
    UnOR[unit,1,month,Yr(2025)] = UnOR[unit,1,month,Yr(2025)] * 0.5
    UnOR[unit,2,month,Yr(2025)] = UnOR[unit,2,month,Yr(2025)] * 0.5
    UnOR[unit,3,month,Yr(2025)] = UnOR[unit,3,month,Yr(2025)] * 0.75
    UnOR[unit,1,month,Yr(2026)] = UnOR[unit,1,month,Yr(2026)] * 0.5
    UnOR[unit,2,month,Yr(2026)] = UnOR[unit,2,month,Yr(2026)] * 0.5
  end
  # UnOR Coal
  coal = Select(UnPlant, ==("Coal"))
  units = intersect(unit1, unit2, unit3, coal)
  month = Select(Month,"Summer")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.95
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.98
  end
  month = Select(Month,"Winter")
  for unit in units
    UnOR[unit,1,month,Yr(2024)] = UnOR[unit,1,month,Yr(2024)] * 0.93
    UnOR[unit,2,month,Yr(2024)] = UnOR[unit,2,month,Yr(2024)] * 0.96
  end
  # Nova Scotia (NS) - Emergency Power (Winter)
  unit1 = Select(UnNation, ==("CN"))
  unit2 = Select(UnNode, ==("NS"))
  unit3 = Select(UnCogen, ==(0))
  month = Select(Month,"Winter")
  # UnEAF
  peakhydro = Select(UnPlant, ==("PeakHydro"))
  units = intersect(unit1, unit2, unit3, peakhydro)
  for unit in units
    UnEAF[unit,month,Yr(2024)] = UnEAF[unit,month,Yr(2024)] * 1.5
    UnEAF[unit,month,Yr(2025)] = UnEAF[unit,month,Yr(2025)] * 1.5
  end
  # UnOR OGSteam
  ogsteam = Select(UnPlant, ==("OGSteam"))
  units = intersect(unit1, unit2, unit3, ogsteam)
  for unit in units, timep in TimePs
    UnOR[unit,timep,month,Yr(2024)] = 0
    UnOR[unit,timep,month,Yr(2025)] = 0
    #xUnEGC[unit,timep,month,Yr(2024)] = UnGC[unit,Yr(2024)]
    #xUnEGC[unit,timep,month,Yr(2025)] = UnGC[unit,Yr(2025)]
  end
  # UnOR OGCT
  ogct = Select(UnPlant, ==("OGCT"))
  units = intersect(unit1, unit2, unit3, ogct)
  for unit in units, timep in TimePs
    UnOR[unit,timep,month,Yr(2024)] = 0
    UnOR[unit,timep,month,Yr(2025)] = 0
    #xUnEGC[unit,timep,month,Yr(2024)] = UnGC[unit,Yr(2024)]
    #xUnEGC[unit,timep,month,Yr(2025)] = UnGC[unit,Yr(2025)]
  end
  # UnOR OGCC
  ogcc = Select(UnPlant, ==("OGCC"))
  units = intersect(unit1, unit2, unit3, ogcc)
  for unit in units, timep in TimePs
    UnOR[unit,timep,month,Yr(2024)] = 0
    UnOR[unit,timep,month,Yr(2025)] = 0
    #xUnEGC[unit,timep,month,Yr(2024)] = UnGC[unit,Yr(2024)]
    #xUnEGC[unit,timep,month,Yr(2025)] = UnGC[unit,Yr(2025)]
  end
  # UnOR Coal
  coal = Select(UnPlant, ==("Coal"))
  units = intersect(unit1, unit2, unit3, coal)
  for unit in units, timep in TimePs
    UnOR[unit,timep,month,Yr(2024)] = 0
    UnOR[unit,timep,month,Yr(2025)] = 0
  end
  # UnOR Biomass
  biomass = Select(UnPlant, ==("Biomass"))
  units = intersect(unit1, unit2, unit3, biomass)
  for unit in units, timep in TimePs
    UnOR[unit,timep,month,Yr(2024)] = 0
    UnOR[unit,timep,month,Yr(2025)] = 0
  end

  # New Brunswick (NB) - Emergency Power
  unit1 = Select(UnNation, ==("CN"))
  unit3 = Select(UnNode, ==("NB"))
  unit4 = Select(UnCogen, ==(0))
  unit5 = Select(UnPlant, ==("PeakHydro"))
  units = intersect(unit1, unit3, unit4, unit5)
  month = Select(Month,"Winter")
  for unit in units
    UnEAF[unit,month,Yr(2024)] *= 0.6
  end

  # Quebec (QC) - Emergency Power
  unit1 = Select(UnNation, ==("CN"))
  unit3 = Select(UnNode, ==("QC"))
  unit4 = Select(UnCogen, ==(0))
  unit5 = Select(UnPlant, ==("PeakHydro"))
  units = intersect(unit1, unit3, unit4, unit5)
  month = Select(Month,"Winter")
  for unit in units
    UnEAF[unit,month,Yr(2024)] *= 0.85
  end

  # British Columbia (BC) - Too much hydro
  
  # 1) Peak Hydro
  unit = findall(UnCode .== "BC_Endo080314")
  Years = collect(Future:Final)
  month = Select(Month,"Winter")
  for year in Years
    UnEAF[unit,month,year] *= 1 #0.85
  end
  month = Select(Month,"Summer")
  for year in Years
    UnEAF[unit,month,year] *= 1 #0.85
  end
  
  # 2) Small Hydro and Base Hydro
  unit1 = findall(UnCode .== "BC_Endo080316")
  unit2 = findall(UnCode .== "BC_Endo080313")
  units = union(unit1, unit2)
  Years = collect(Future:Final)
  
  month = Select(Month,"Winter")
  for unit in units, year in Years
    UnOR[unit,1,month,year] *= 1 #1.15
    UnOR[unit,2,month,year] *= 1 #1.15
    UnOR[unit,3,month,year] *= 1 #1.15
    UnOR[unit,4,month,year] *= 1 #1 #1.15
    UnOR[unit,5,month,year] *= 1 #1.15
    UnOR[unit,6,month,year] *= 1 #1.15
  end
    
  month = Select(Month,"Summer")
  for unit in units, year in Years
    UnOR[unit,1,month,year] *= 1 #1.15
    UnOR[unit,2,month,year] *= 1 #1.15
    UnOR[unit,3,month,year] *= 1 #1.15
    UnOR[unit,4,month,year] *= 1 #1.15
    UnOR[unit,5,month,year] *= 1 #1.15
    UnOR[unit,6,month,year] *= 1 #1.15
  end
  
  
  # Yukon (YT) - Emergency Power
  unit1 = Select(UnNation, ==("CN"))
  unit2 = Select(UnNode, ==("YT"))
  unit3 = Select(UnCogen, ==(0))
  # Hydro Power
  peakhydro = Select(UnPlant, ==("PeakHydro"))
  units = intersect(unit1, unit2, unit3, peakhydro)
  # UnEAF Summer
  month = Select(Month,"Summer")
  for unit in units
    UnEAF[unit,month,Yr(2045)] *= (1-0.007)
    UnEAF[unit,month,Yr(2046)] *= (1-0.011)*(1-0.007)
    UnEAF[unit,month,Yr(2047)] *= (1-0.018)*(1-0.007)
    UnEAF[unit,month,Yr(2048)] *= (1-0.022)*(1-0.013)
    UnEAF[unit,month,Yr(2049)] *= (1-0.024)*(1-0.021)
    UnEAF[unit,month,Yr(2050)] *= (1-0.022)*(1-0.011)
  end
  # UnEAF Winter
  month = Select(Month,"Winter")
  for unit in units
    UnEAF[unit,month,Yr(2045)] *= (1-0.007)
    UnEAF[unit,month,Yr(2046)] *= (1-0.09)*(1-0.005)
    UnEAF[unit,month,Yr(2047)] *= (1-0.018)*(1-0.007)
    UnEAF[unit,month,Yr(2048)] *= (1-0.022)*(1-0.013)
    UnEAF[unit,month,Yr(2049)] *= (1-0.028)*(1-0.019)
    UnEAF[unit,month,Yr(2050)] *= (1-0.083)*(1-0.074)
  end
  

  WriteDisk(db,"EGInput/UnEAF",UnEAF)
  # WriteDisk(db,"EGInput/UnOR",UnOR)

  #
  # SECTION 2
  # 
  # Thermal power generation (UnOR)
  #
  # Ontario (ON)
  # The historical alignment in Access includes reactors being refurbished but in 2024
  # some of these reactors are not available due to refurbishment which causes a drop in nuclear power generation
  # Therefore, UnOR have been recalculated for available reactors to maintain the same level of generation in 2024
  # This UnOR is also applied to subsequent Years to keep the generation as high as possible,
  # but more reactors will be refurbished in the future causing drops in nuclear generation.
  #
  
  units = findall(UnCode .== "ON00011106701")
  Years = collect(Yr(2025):Final)
  # There is not enough natual gas generation,
  # therefore we decrease a bit the nuclear power generation by increase UnOR
  nuke_patch = 2
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units1 =findall(UnCode .== "ON00011106702")
  units2 =findall(UnCode .== "ON00011106703")
  units3 =findall(UnCode .== "ON00037100302")
  units = union(units1,units2,units3)
  Years = collect(Future:Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00011106704")
  Years = collect(Yr(2027):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00011106801")
  Years = collect(Yr(2024):Yr(2025))
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  Years = collect(Yr(2031):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00011106802")
  Years = collect(Yr(2024):Yr(2025))
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  Years = collect(Yr(2033):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00011106803")
  Years = collect(Yr(2024):Yr(2025))
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  Years = collect(Yr(2034):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00011106804")
  Years = collect(Yr(2024):Yr(2025))
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  Years = collect(Yr(2035):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units1 =findall(UnCode .== "ON00011107604")
  units2 =findall(UnCode .== "ON00011107601")
  units = union(units1,units2)
  Years = collect(Yr(2036):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00037100203")
  Years = collect(Yr(2027):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00037100204")
  Years = collect(Yr(2029):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00037100301")
  Years = collect(Yr(2030):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00037100303")
  Years = collect(Yr(2024):Yr(2027))
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  Years = collect(Yr(2032):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  units = findall(UnCode .== "ON00037100304")
  Years = collect(Yr(2024):Yr(2029))
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  Years = collect(Yr(2034):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.104806759 * nuke_patch
  end
  
  # New Brunswick (NB)
  
  # OGCC
  unit1 = Select(UnArea, ==("NB"))
  unit2 = Select(UnPlant, ==("OGCC"))
  unit3 = findall(UnSource .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1, unit2, unit3, unit4)
  # Emergency Power: UnOR is decreased in 2024 to deal with emega
  month = Select(Month,"Winter")
  year = collect(Yr(2024))
  for unit in units
    UnOR[unit,1,month,year] .= 0.1
    UnOR[unit,2,month,year] .= 0.1
    UnOR[unit,3,month,year] .= 0.1
    UnOR[unit,4,month,year] .= 0.1
  end
  # Adjusted to maintain a certain level of natural gas generation (asked by NB in 2024 consultation)
  Years = collect(Yr(2025):Final)
  for year in Years, unit in units, timep in TimePs, month in Months
    UnOR[unit,timep,month,year] = 0.435
  end
  
  # WriteDisk(db,"EGInput/UnOR",UnOR)

  # OGCT plants: Adjusting UnOR 5 years avg
  unit1 = Select(UnArea, ==("NB"))
  unit2 = Select(UnPlant, ==("OGCT"))
  unit3 = findall(UnSource .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1, unit2, unit3, unit4)
  Years = collect(Future:Final)
  for year in Years, unit in units, timep in TimePs, month in Months
    UnOR[unit,timep,month,year] = 0.984
  end

  # OGSteam plants: Adjusting UnOR 5 years avg
  unit1 = Select(UnArea, ==("NB"))
  unit2 = Select(UnPlant, ==("OGSteam"))
  unit3 = findall(UnSource .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1, unit2, unit3, unit4)
  Years = collect(Future:Final)
  for year in Years, unit in units, timep in TimePs, month in Months
    UnOR[unit,timep,month,year] = 0.946
  end

  # Nuclear - Point Lepreau (NB)
  units = Select(UnCode, ==("NB00006601201"))
  # Emergency Power: UnOR is decreased in 2024 to deal with emega
  year = collect(Yr(2024))
  month = Select(Month,"Winter")
  for unit in units
    UnOR[unit,1,month,year] .= 0.16
    UnOR[unit,2,month,year] .= 0.16
    UnOR[unit,3,month,year] .= 0.16
    UnOR[unit,4,month,year] .= 0.16
  end
  # Recalculating UnOR (10 Years average) for Point Lepreau because LHY has a low generation
  Years = collect(Yr(2025):Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.20287407
  end
  
  # Newfoundlant and Labrador (NL)
  #
  # On the long term, emissions should be around 50 kt/year
  # Remote networks are expected to be responsible of these emissions
  # The change has been made in vData but something is overwritting it!!!
  unit1 = Select(UnCode, ==("NL_Group_03"))
  unit2 = Select(UnCode, ==("LB_Group_01"))
  units = union(unit1, unit2)
  Years = collect(Future:Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.85
  end
  
  # British Columbia (BC)
  #
  # Fort Nelson is a remote mustrun thermal power plant
  # By default UnOR is too low (0.05), thus replacing with 5-years average
  units = Select(UnCode, ==("BC_FORTNELSON"))
  Years = collect(Future:Final)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.70
  end
  
  # Yukon (YT)
  unit1 = Select(UnCode, ==("YT_WhiteHorse_N"))
  unit2 = Select(UnCode, ==("YT_WhiteHorse_S"))
  units = union(unit1, unit2)
  # It seems these power plant generate too much in 2027 and 2029, forcing hydro to decrease generation
  # These power plants are kind-of expected to be used mainly in winter, thus setting UnOR=1 for summer.
  month = Select(Month,"Summer")
  years = collect(Future:Final)
  for unit in units, timep in TimePs, year in years
    UnOR[unit,timep,month,year] = 1
  end

  #
  # Heat Rates
  #
  # NT, NU, YT: fixing Future-Final heat rates that are too high causing a jump in emissions
  #             the use of generic heat rates seems causing problem, thus using LHY heat rates
 
  # Northwest territories (NT)
  Years = collect(Future:Final)
  for unit in Units
    if UnCode[unit] =="NT00008200100"
      UnHRt[unit, Years] .= UnHRt[unit, Yr(2023)]
    end
    if UnCode[unit] =="NT00008600100"
      UnHRt[unit, Years] .= UnHRt[unit, Yr(2023)]
    end
    if UnCode[unit] =="NT00008700100"
      UnHRt[unit, Years] .= UnHRt[unit, Yr(2023)]
    end
  end 

  # Nunavut (NU)
  unit1 = Select(UnArea, ==("NU"))
  unit2 = Select(UnPlant, ==("OGCT"))
  unit3 = findall(UnSource .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1, unit2, unit3, unit4)
  Years = collect(Future:Final)
  if !isempty(units)
    for year in Years, unit in units
      UnHRt[unit,year] = 10586.12
    end
  end

  # Yukon (YT)
  unit1 = Select(UnArea, ==("YT"))
  unit2 = Select(UnPlant, ==("OGCT"))
  unit3 = findall(UnSource .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1, unit2, unit3, unit4)
  Years = collect(Future:Final)
  if !isempty(units)
    for year in Years, unit in units
      UnHRt[unit,year] = 8335.207
    end
  end

  WriteDisk(db,"EGInput/UnHRt",UnHRt)

  #
  # SECTION 3: Manage problematic plants
  #
  # Noah does not want these endogenous units to come online
  # TD 2025-04-28 : we need to check if this change is still wanted
  # NL_Cg_ECC34_OGSteam does not seem to exist - Jeff Amlin 8/12/25
  #
  Years = collect(First:Final)
  for unit in Units
    if UnCode[unit] == "NL_Cg_ECC34_OGSteam" ||
       UnCode[unit] == "BC_Cg_PulpPaperMills_OGCC"    
      for year in Years, timep in TimePs, month in Months
        UnOR[unit,timep,month,year] = 1
      end
    end
  end


  # Some remote power plants are not generating in projections as they should
  # These power plants are in remote networks
  unit1 = Select(UnCode, ==("BC_Group_04"))
  unit2 = Select(UnCode, ==("MB00005401300"))
  unit3 = Select(UnCode, ==("MB00005401400"))
  unit4 = Select(UnCode, ==("MB00005401500"))
  unit5 = Select(UnCode, ==("MB00005401600"))
  unit6 = Select(UnCode, ==("ON_Group_17"))
  unit7 = Select(UnCode, ==("QC_Group_11"))
  unit8 = Select(UnCode, ==("QC00013507500"))
  unit9 = Select(UnCode, ==("SK00015301100"))
  
  # Making them MustRun
  units = union(unit1, unit2, unit3, unit4, unit5, unit6, unit7, unit8, unit9)
  for unit in units
    UnMustRun[unit] = 1
  end
  
  # Adjust UnOR for projections (replacing 0.05 value with 5-years historical average)
  Years = collect(Future:Final)
  # BC
  units = unit1
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.86003226
  end
  # MB
  units = union(unit2, unit3, unit4, unit5)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.98419322
  end
  # ON
  units = unit6
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.77457442
  end
  # QC
  units = union(unit7, unit8)
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.86934616
  end
  # SK
  units = unit9
  for unit in units, timep in TimePs, month in Months, year in Years
    UnOR[unit,timep,month,year] = 0.29829528
  end

  # Newfoundland (NL)
  # Holyrood is supposed to be used at least at a minimal level
  unit1 = Select(UnCode, ==("NL00007504001"))
  unit2 = Select(UnCode, ==("NL00007504002"))
  unit3 = Select(UnCode, ==("NL00007504003"))
  unit4 = Select(UnCode, ==("NL00007500302"))
  units = union(unit1, unit2, unit3, unit4)
  for unit in units
    UnMustRun[unit] = 1
  end
  for unit in units, timep in TimePs, month in Months
    UnOR[unit,timep,month,Yr(2024)] = 0.9
    UnOR[unit,timep,month,Yr(2025)] = 0.91
    UnOR[unit,timep,month,Yr(2026)] = 0.92
    UnOR[unit,timep,month,Yr(2027)] = 0.94
    UnOR[unit,timep,month,Yr(2028)] = 0.96
    UnOR[unit,timep,month,Yr(2029)] = 0.98
    UnOR[unit,timep,month,Yr(2030)] = 0.994
  end
  
  WriteDisk(db,"EGInput/UnMustRun", UnMustRun)
  WriteDisk(db,"EGInput/UnOR",UnOR)
  
  #
  # SECTION 4: Fossil power generation adjustments
  #

  # Saskatchewan (SK)
  plant = Select(Plant, ==("Coal"))
  genco = Select(GenCo, ==("SK"))
  node = Select(Node, ==("SK"))
  Years = collect(First:Yr(2030))
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -2
  end

  # Saskatchewan (SK)
  plants = Select(Plant, ["OGCC","OGCT","OGSteam"])
  genco = Select(GenCo, ==("SK"))
  node = Select(Node, ==("SK"))
  Years = collect(First:Yr(2035))
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -1
  end

  # Saskatchewan (SK)
  # Adjusting PeakHydro and Windshore because it's replacing CoalCCS
  genco = Select(GenCo, ==("SK"))
  node = Select(Node, ==("SK"))
  Years = collect(First:Yr(2034))
  # Hydro
  plants = Select(Plant, ["PeakHydro"])
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] = HDVCFR[plant,genco,node,TimePs,Months,year]*2.50
  end
  # Wind
  plants = Select(Plant, ["OnshoreWind"])
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] = HDVCFR[plant,genco,node,TimePs,Months,year]*2.50
  end
  # CoalCCS
  plants = Select(Plant, ["CoalCCS"])
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -4.50
  end
  
  # Saskatchewan (SK)
  # Rebalance UnUOMC (same reason)
  unit1 = Select(UnNation, ==("CN"))
  unit3 = Select(UnNode, ==("SK"))
  unit4 = Select(UnCogen, ==(0))
  Years = collect(First:Yr(2034))
  # Hydro
  unit5 = Select(UnPlant, ==("PeakHydro"))
  units = intersect(unit1, unit3, unit4, unit5)
  for year in Years, unit in units
    UnUOMC[unit,year]  = UnUOMC[unit,year]*2.00
  end
  # Wind
  unit5 = Select(UnPlant, ==("OnshoreWind"))
  units = intersect(unit1, unit3, unit4, unit5)
  for year in Years, unit in units
    UnUOMC[unit,year]  = UnUOMC[unit,year]*2.00
  end
  # CoalCCS
  unit5 = Select(UnPlant, ==("CoalCCS"))
  units = intersect(unit1, unit3, unit4, unit5)
  for year in Years, unit in units
    UnUOMC[unit,year]  = UnUOMC[unit,year]/2.00
  end
  # Coal
  unit5 = Select(UnPlant, ==("Coal"))
  units = intersect(unit1, unit3, unit4, unit5)
  for year in Years, unit in units
    UnUOMC[unit,year]  = UnUOMC[unit,year]/2.00
  end

# Nova Scotia (NS)
  plant = Select(Plant, ==("Coal"))
  genco = Select(GenCo, ==("NS"))
  node = Select(Node, ==("NS"))
  # Dealing with emergency power in 2024-2025 [TD 2025.10.03]
  Years = collect(Yr(2024):Yr(2025))
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -10
  end
  Years = collect(First:Yr(2030))
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -2
  end
  
  # Nova Scotia (NS)
  plants = Select(Plant, ["OGCC","OGCT","OGSteam"])
  genco = Select(GenCo, ==("NS"))
  node = Select(Node, ==("NS"))
  # Dealing with emergency power in 2024-2025 [TD 2025.10.03]
    Years = collect(Yr(2024):Yr(2025))
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -10
  end
  Years = collect(Yr(2026):Yr(2035))
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -2
  end
  
  # New Brunswick (NB)  
  genco = Select(GenCo, ==("NB"))
  node = Select(Node, ==("NB"))
  # Coal plants
  plant = Select(Plant, ==("Coal"))
  HDVCFR[plant,genco,node,TimePs,Months,Yr(2024)] .= -2
  Years = collect(Yr(2025):Yr(2030))
  for year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -1
  end
  # Gas plants <2030 
  Years = collect(Yr(2024):Yr(2029))
  plants = Select(Plant, ["OGCC","OGCT"])
  for plant in plants, year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= 0
  end
  # Oil plants <2030
    plants = Select(Plant, ["OGSteam"])
  for plant in plants, year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -0.5
  end
  # Oil and Gas plants
  Years = collect(Yr(2030):Final)
  plants = Select(Plant, ["OGCC","OGCT","OGSteam"])
  for plant in plants, year in Years
    HDVCFR[plant,genco,node,TimePs,Months,year] .= -0.5
  end
  
  # Ontario (ON)
  genco = Select(GenCo, ==("ON"))
  node = Select(Node, ==("ON"))
  plants = Select(Plant, ["OGCC","OGCT","OGSteam"])
  for plant in plants
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2024)] .= 0.8
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2025)] .= 0.7  #0.75
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2026)] .= 0.5
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2027)] .= 0.45
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2028)] .= 0.3  #0.4 #0.5
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2029)] .= 0.3  #0.35 #0.4
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2030)] .= 0.20 #0.25
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2031)] .= 0.25 #0.30 #0.35
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2032)] .= 0.65
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2033)] .= 0.75
    HDVCFR[plant,genco,node,TimePs,Months,Yr(2034)] .= 0.75
  end

  WriteDisk(db,"EGInput/HDVCFR",HDVCFR)
  WriteDisk(db,"EGInput/UnUOMC",UnUOMC)
  
  #
  # SECTION 5
  #
  node = Select(Node,"PE")
  DRM[node,Years] .= -0.5
  WriteDisk(db,"EInput/DRM",DRM)

  #
  # Step 1: setting default values
  #
  #
  # 
  # March 2024. V.Keller: Updated to reflect current market structures. 
  # Market structure adjustments
  # Market participants
  #
  
  #
  # AB is a market. Should point to 6. But that part of the model is not
  #                 very well developed yet. Until then, leave it at 5.
  # ON is a market. Mostly. But it has some other complicated dynamics. 
  #
  areas = Select(Area,["AB","ON"])
  Years = collect(Future:Final)
  for year in Years, area in areas
    BuildSw[area,year] = 5
  end

  #
  # Rest of the provinces in Canada are all vertically integrated utilities
  #
  areas = Select(Area,["BC","MB","SK","QC","NS","NB","PE","NL","NT","NU","YT"])
  Years = collect(Future:Final)
  for year in Years, area in areas
    BuildSw[area,year] = 6
  end
  
  #
  # Step 2: adjusting values for early projection Years
  #
  areas = Select(Area,(from = "ON", to = "NU"))
  Years = Yr(2024)
  for year in Years, area in areas
    BuildSw[area,year] = 0
  end

  #
  # We have a greater knowledge of future project in AB, 
  # thus not expecting endo addition for a longer period
  #
  areas = Select(Area,"AB")
  Years = collect(Future:Yr(2027))
  for year in Years, area in areas
    BuildSw[area,year] = 0
  end

  #
  # It is decided to not let PE build anythin before 2030 
  # (E2020 is too hasty to install capacity)
  #
  areas = Select(Area,"PE")
  Years = collect(Future:Yr(2029))
  for year in Years, area in areas
    BuildSw[area,year] = 0
  end
  
  WriteDisk(db,"EGInput/BuildSw",BuildSw)
  #WriteDisk(db,"EGInput/xUnEGC",year,xUnEGC)

  # 
  # Patch for Yukon - Jeff Amlin 6/29/24
  # 
  area = Select(Area,"YT")
  years = collect(Future:Final)
  for year in years, power in Powers, plant in Plants
    DesHr[plant,power,area,year] = DesHr[plant,power,area,Yr(2023)]
  end
  WriteDisk(db,"EGInput/DesHr",DesHr)

end

function PolicyControl(db)
  @info "Electric_Patch.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end