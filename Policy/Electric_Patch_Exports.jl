#
# Electric_Patch_Exports.jl
#
# this file was added to help fix electricity exports to the US from Canada
# the approach is to adjust variable costs to raise the costs of exports to reduce them
# in years where this did not work the solution was to decrease the max line capacity
# this should be avoided because physical constraints in the model should be kept as constant as possible

using EnergyModel

module Electric_Patch_Exports

import ...EnergyModel: ReadDisk, WriteDisk, Select
import ...EnergyModel: HisTime, ITime, MaxTime, First, Future, Final, Yr
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
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
  xLLVC::VariableArray{3} = ReadDisk(db,"EGInput/xLLVC") # [Node,NodeX,Year] Transmission Rate (Real US$/MWh)
  LLMax::VariableArray{5} = ReadDisk(db,"EGInput/LLMax") # [Node,NodeX,TimeP,Month,Year] Maximum Loading on Transmission Lines (MW)
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Month,Node,NodeX,TimeP,Year) = data
  (; Months,Nodes,NodeXs,TimePs,Years) = data
  (; xLLVC,LLMax) = data
  
  ####################
  #                  #
  # FLOWS BETWEEN PT #
  #                  #
  ####################
 
  # BC --> AB
  AB = Select(Node,"AB")
  BC = Select(NodeX,"BC")
  years = collect(Yr(2026):Yr(2030))
  for year in years
    xLLVC[AB,BC,year]=xLLVC[BC,AB,year]*2
  end
 
  # AB --> BC
  AB = Select(NodeX,"AB")
  BC = Select(Node,"BC")
  # TD (2025-10-20): reducing beccause it cause BC to compensate with NG
  years = collect(Yr(2026):Yr(2030))
  for year in years
    xLLVC[BC,AB,year]=xLLVC[BC,AB,year]*2 #9 #10 #8
  end
  years = collect(Yr(2031):Yr(2034))
  for year in years
    xLLVC[BC,AB,year]=xLLVC[BC,AB,year]*9 #5
  end
  years = collect(Yr(2035):Yr(2039))
  for year in years
    xLLVC[BC,AB,year]=xLLVC[BC,AB,year]*5
  end
  years = collect(Yr(2040):Yr(2050))
  for year in years
    xLLVC[BC,AB,year]=xLLVC[BC,AB,year]*3
  end

  # AB --> SK
  AB = Select(NodeX,"AB")
  SK = Select(Node,"SK")
  years = collect(Yr(2024):Yr(2032))
  for year in years 
    xLLVC[SK,AB,year]=xLLVC[SK,AB,year]*35
  end
  years = collect(Yr(2033):Yr(2050))
  for year in years 
    xLLVC[SK,AB,year]=xLLVC[SK,AB,year]*30
  end

  # SK --> AB
  AB = Select(Node,"AB")
  SK = Select(NodeX,"SK")
  years = collect(Yr(2024):Yr(2024))
  for year in years 
    xLLVC[AB,SK,year]=xLLVC[AB,SK,year]*3 #2
  end
  years = collect(Yr(2025):Yr(2025))
  for year in years 
    xLLVC[AB,SK,year]=xLLVC[AB,SK,year]*2.5 #2
  end
  years = collect(Yr(2026):Yr(2027))
  for year in years 
    xLLVC[AB,SK,year]=xLLVC[AB,SK,year]*3 #2
  end 
  
  # MB --> SK
  MB = Select(NodeX,"MB")
  SK = Select(Node,"SK")
  years = collect(Yr(2024):Yr(2050))
  for year in years 
    xLLVC[SK,MB,year]=xLLVC[SK,MB,year]*35
  end
  # TD 2025 10 13: deactivating LLMax since MB-->SK contract has been reworked to lower export
  #timeperiods = collect(4:6)
  #for year in years, timep in timeperiods
  #  LLMax[SK,MB,timep,Months,year]=LLMax[SK,MB,timep,Months,year]/1.20
  #end

  # MB --> ON
  MB = Select(NodeX,"MB")
  ON = Select(Node,"ON")
  years = collect(Yr(2024):Yr(2024))
  for year in years
    xLLVC[ON,MB,year]=xLLVC[ON,MB,year]*4
  end
  years = collect(Yr(2025):Yr(2025))
  for year in years
    xLLVC[ON,MB,year]=xLLVC[ON,MB,year]*5
  end
  years = collect(Yr(2026):Yr(2029))
  for year in years
    xLLVC[ON,MB,year]=xLLVC[ON,MB,year]*4
  end
  years = collect(Yr(2030):Yr(2040))
  for year in years
    xLLVC[ON,MB,year]=xLLVC[ON,MB,year]*8
  end
  years = collect(Yr(2041):Yr(2044))
  for year in years
    xLLVC[ON,MB,year]=xLLVC[ON,MB,year]*2
  end
  
  # QC --> ON
  QC = Select(NodeX,"QC")
  ON = Select(Node,"ON")
  years = collect(Yr(2024):Yr(2024))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*4
  end
  years = collect(Yr(2025):Yr(2025))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*8 #4
  end
  years = collect(Yr(2026):Yr(2026))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*3.75 #3 #4
  end
  years = collect(Yr(2027):Yr(2027))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*3.5 #3 #4
  end
  years = collect(Yr(2028):Yr(2028))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*3.9 #3 #4
  end
  years = collect(Yr(2029):Yr(2031))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*3.5 #3 #4
  end
  years = collect(Yr(2032):Yr(2041))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*8 #4
  end
  years = collect(Yr(2042):Yr(2050))
  for year in years
    xLLVC[ON,QC,year]=xLLVC[ON,QC,year]*4
  end

  # NS --> NB (for emergency power)
  NS = Select(NodeX,"NS")
  NB = Select(Node,"NB")
  years = collect(Yr(2024):Yr(2025))
  for year in years
    xLLVC[NB,NS,year]=xLLVC[NB,NS,year]*2
  end
  
  ###############################
  #                             #
  # FLOWS BETWEEN CANADA AND US #
  #                             #
  ###############################
  
  # Exemple of code to reduce LLMax on non-peak TimeP
  #timeperiods = collect(4:6)
  #years = collect(Yr(2024):Yr(2026))
  #for year in years, timep in timeperiods
  #  LLMax[NWPP,AB,timep,Months,year]=LLMax[NWPP,AB,timep,Months,year]/5
  #end
  #years = collect(Yr(2027):Yr(2027))
  #for year in years, timep in timeperiods
  #  LLMax[NWPP,AB,timep,Months,year] = LLMax[NWPP,AB,timep,Months,year]/2
  #end
  
  # NWPP (US) --> BC
  NWPP = Select(NodeX,"NWPP")
  BC = Select(Node,"BC")
  # TD (2025-10-20): reducing constraint beccause it causes BC to compensate with NG
  years = collect(Yr(2026):Yr(2030))
  for year in years
    xLLVC[BC,NWPP,year] = xLLVC[BC,NWPP,year]*2 #6
  end
  years = collect(Yr(2031):Yr(2036))
  for year in years
    xLLVC[BC,NWPP,year] = xLLVC[BC,NWPP,year]*5
  end
  
  # AB --> NWPP (US)
  AB = Select(NodeX,"AB")
  NWPP = Select(Node,"NWPP")
  years = collect(Yr(2024):Yr(2030))
  for year in years
    xLLVC[NWPP,AB,year] = xLLVC[NWPP,AB,year]*1.5
  end
  years = collect(Yr(2031):Yr(2034))
  for year in years
    xLLVC[NWPP,AB,year] = xLLVC[NWPP,AB,year]*8
  end
  years = collect(Yr(2035):Yr(2050))
  for year in years
    xLLVC[NWPP,AB,year] = xLLVC[NWPP,AB,year]*3
  end

  # NWPP (US) --> BC
  BC = Select(Node,"BC")
  NWPP = Select(NodeX,"NWPP")
  years = collect(Yr(2026):Yr(2036))
  for year in years
    xLLVC[BC,NWPP,year] = xLLVC[BC,NWPP,year]*2
  end
  
  # SPPN (US) --> SK
  SK = Select(Node,"SK")
  SPPN = Select(NodeX,"SPPN")
  years = collect(Yr(2024):Yr(2027))
  for year in years 
    xLLVC[SK,SPPN,year]=xLLVC[SK,SPPN,year]*22
  end
  years = collect(Yr(2028):Yr(2028))
  for year in years 
    xLLVC[SK,SPPN,year]=xLLVC[SK,SPPN,year]*23
  end
  years = collect(Yr(2029):Yr(2029))
  for year in years 
    xLLVC[SK,SPPN,year]=xLLVC[SK,SPPN,year]*24
  end
  years = collect(Yr(2030):Yr(2034))
  for year in years 
    xLLVC[SK,SPPN,year]=xLLVC[SK,SPPN,year]*25
  end
  years = collect(Yr(2035):Yr(2050))
  for year in years 
    xLLVC[SK,SPPN,year]=xLLVC[SK,SPPN,year]*30
  end 
  
  # MB --> MISW (US)
  MB = Select(NodeX,"MB")
  MISW = Select(Node,"MISW")
  years = collect(Yr(2024):Yr(2027))
  for year in years
    xLLVC[MISW,MB,year] = xLLVC[MISW,MB,year]*4
  end
  years = collect(Yr(2028):Yr(2029))
  for year in years
    xLLVC[MISW,MB,year] = xLLVC[MISW,MB,year]*2
  end

  # MISW (US) --> ON
  MISW = Select(NodeX,"MISW")
  ON = Select(Node,"ON")
  years = collect(Yr(2029):Yr(2029))
  for year in years
    xLLVC[ON,MISW,year] = xLLVC[ON,MISW,year]*3 #2
  end
  years = collect(Yr(2030):Yr(2030))
  for year in years
    xLLVC[ON,MISW,year] = xLLVC[ON,MISW,year]*2
  end
  years = collect(Yr(2031):Yr(2033))
  for year in years
    xLLVC[ON,MISW,year] = xLLVC[ON,MISW,year]*3
  end
  years = collect(Yr(2035):Yr(2039))
  for year in years
    xLLVC[ON,MISW,year] = xLLVC[ON,MISW,year]*4 #3
  end

  # ON --> MISW (US)
  ON = Select(NodeX,"ON")
  MISE = Select(Node,"MISW")
  years = collect(Yr(2044):Yr(2047))
  for year in years
    xLLVC[MISE,ON,year] = xLLVC[MISE,ON,year]*2
  end
  
  # ON --> MISE (US)
  ON = Select(NodeX,"ON")
  MISE = Select(Node,"MISE")
  years = collect(Future:Yr(2043))
  for year in years
    xLLVC[MISE,ON,year] = xLLVC[MISE,ON,year]*5
  end
  years = collect(Yr(2044):Yr(2047))
  for year in years
    xLLVC[MISE,ON,year] = xLLVC[MISE,ON,year]*5.5
  end
  years = collect(Yr(2048):Yr(2050))
  for year in years
    xLLVC[MISE,ON,year] = xLLVC[MISE,ON,year]*5
  end
  
  # ON --> NYUP (US)
  ON = Select(NodeX,"ON")
  NYUP = Select(Node,"NYUP")
  years = collect(Future:Yr(2036))
  for year in years
    xLLVC[NYUP,ON,year] = xLLVC[NYUP,ON,year]*5
  end
  years = collect(Yr(2035):Yr(2038))
  for year in years
    xLLVC[NYUP,ON,year] = xLLVC[NYUP,ON,year]*4
  end
  years = collect(Yr(2039):Yr(2043))
  for year in years
    xLLVC[NYUP,ON,year] = xLLVC[NYUP,ON,year]*5
  end
  years = collect(Yr(2044):Yr(2047))
  for year in years
    xLLVC[NYUP,ON,year] = xLLVC[NYUP,ON,year]*5.5
  end
  years = collect(Yr(2048):Yr(2050))
  for year in years
    xLLVC[NYUP,ON,year] = xLLVC[NYUP,ON,year]*5
  end
  
  # QC --> ISNE (US)
  QC = Select(NodeX,"QC")
  ISNE = Select(Node,"ISNE")
  years = collect(Future:Yr(2034))
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*8.5 #8 #9 #9.5 #10
  end
  years = collect(Yr(2035):Yr(2036))
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*8.4 #8.25 #8.65 #8.48 #8.45 #8.4 #8.5 #8.7 # 8.3 #8 #9.1 #9.25 #9 #9.5 #10
  end
  years = collect(Yr(2037):Yr(2037))
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*8.5# 8.2 #8.15 #8 #8.25 #8.5 #8.75 #9 # 9.5 #8.7# 8.3 #8 #9.1 #9.25 #9 #9.5 #10
  end
  years = collect(Yr(2038):Yr(2039))
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*8.6 #8.25 #9 #9.15 #8.9 #8.75 #9 # 9.5 #8.7# 8.3 #8 #9.1 #9.25 #9 #9.5 #10
  end
  years = collect(Yr(2040):Yr(2042))
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*8.65 #8.5 #8.75 #9.25 #9# 9.5# 8.7 #9.2 #9.1 #9.25 #9 #9.5 #10
  end
  years = collect(Yr(2043):Yr(2043))
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*9.25 #9.3 #9.5 #9.2 #8.7 #9.5 #9.75 #9.25 #9 #9.5 #10
  end
  years = collect(Yr(2044):Yr(2045))
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*9.3 #9.5 #9.2 #8.7 #9.5 #9.75 #9.25 #9 #9.5 #10
  end
  years = collect(Yr(2046):Final)
  for year in years
    xLLVC[ISNE,QC,year]=xLLVC[ISNE,QC,year]*9.5 #9.75 #9.25 #9 #9.5 #10
  end

  # QC --> NYUP (US)
  QC = Select(NodeX,"QC")
  NYUP = Select(Node,"NYUP")
  years = collect(Future:Yr(2028))
  for year in years
    xLLVC[NYUP,QC,year] = xLLVC[NYUP,QC,year]*8
  end
  years = collect(Yr(2029):Yr(2031))
  for year in years
    xLLVC[NYUP,QC,year] = xLLVC[NYUP,QC,year]*6 #7 #8
  end
  years = collect(Yr(2032):Final)
  for year in years
    xLLVC[NYUP,QC,year] = xLLVC[NYUP,QC,year]*8
  end

  # NB --> ISNE (US)
  NB = Select(NodeX,"NB")
  ISNE = Select(Node,"ISNE")
  years = collect(Yr(2024):Yr(2024))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*5
  end
  years = collect(Yr(2025):Yr(2025))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*7
  end
  years = collect(Yr(2026):Yr(2026))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*9 #8 #7 #10
  end
  years = collect(Yr(2027):Yr(2028))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*9 #8 #7 #10
  end
  years = collect(Yr(2029):Yr(2029))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*8 #7 #10
  end
  years = collect(Yr(2030):Yr(2030))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*8.5 #9 #8 #7 #10
  end
  years = collect(Yr(2031):Yr(2031))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*8 #7 #10
  end
  years = collect(Yr(2032):Yr(2033))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*9 #8 #7 #10
  end
  years = collect(Yr(2034):Yr(2035))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*8 #7 #10
  end
  years = collect(Yr(2036):Yr(2041))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*8.5 #8 #7 #10
  end
  years = collect(Yr(2042):Yr(2045))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*9 #8 #7 #10
  end
  years = collect(Yr(2046):Yr(2049))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*8 #7 #10
  end
  years = collect(Yr(2050):Yr(2050))
  for year in years
    xLLVC[ISNE,NB,year] = xLLVC[ISNE,NB,year]*9.5 #8.9 #8.5 #9 #8 #7 #10
  end

  # Write statement
  WriteDisk(db,"EGInput/xLLVC",xLLVC)
  WriteDisk(db,"EGInput/LLMax",LLMax)

end

function PolicyControl(db)
  @info "Electric_Patch_Exports.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
