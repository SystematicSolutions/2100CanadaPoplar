#
# ELoadCurve.jl
#

module ELoadCurve

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime
import ...EnergyModel: finite_inverse,@finite_math,finite_divide,finite_power

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))
  
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  Days::Vector{Int} = collect(Select(Day))
  
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  # HourKs::Vector{Int} = collect(Select(Hour))
  
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  Powers::Vector{Int} = collect(Select(Power))
  
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCos::Vector{Int} = collect(Select(GenCo))
  
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  Classes::Vector{Int} = collect(Select(Class))
  
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))

  ADP::VariableArray{2} = ReadDisk(db,"EOutput/ADP",year) #[Month,Area,Year]  Average Annual Demand (MW)
  ArNdFr::VariableArray{2} = ReadDisk(db,"EGInput/ArNdFr",year) #[Area,Node,Year]  Fraction of the Area in each Node (MW/MW)
  HDADP::VariableArray{3} = ReadDisk(db,"EGOutput/HDADP",year) #[Node,TimeP,Month,Year]  Average Load in Interval (MW)
  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") #[TimeP,Month]  Number of Hours in the Interval (Hours)
  HDHrMn::VariableArray{2} = ReadDisk(db,"EInput/HDHrMn") #[TimeP,Month]  Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db,"EInput/HDHrPk") #[TimeP,Month]  Peak Hour in the Interval (Hour)
  HDPDP::VariableArray{3} = ReadDisk(db,"EGOutput/HDPDP",year) #[Node,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
  HDEnergy::VariableArray{3} = ReadDisk(db,"EGOutput/HDEnergy",year) #[Node,TimeP,Month,Year]  Energy in Interval (GWh)
  HMADP::VariableArray{4} = ReadDisk(db,"EOutput/HMADP",year) #[Node,Area,TimeP,Month,Year]  Average Load in Interval (MW)
  HMEGMn::VariableArray{4} = ReadDisk(db,"EOutput/HMEGMn",year) #[Node,Area,TimeP,Month,Year]  Energy below Lowest Point in Interval (GWh)
  HMEGPk::VariableArray{4} = ReadDisk(db,"EOutput/HMEGPk",year) #[Node,Area,TimeP,Month,Year]  Energy below Highest Load in Interval (GWh)
  HMEnergy::VariableArray{4} = ReadDisk(db,"EOutput/HMEnergy",year) #[Node,Area,TimeP,Month,Year]  Energy in Interval (GWh)
  HMMDP::VariableArray{4} = ReadDisk(db,"EOutput/HMMDP",year) #[Node,Area,TimeP,Month,Year]  Minimum (Lowest) Load in Interval (MW)
  HMPDP::VariableArray{4} = ReadDisk(db,"EOutput/HMPDP",year) #[Node,Area,TimeP,Month,Year]  Peak (Highest) Load in Interval (MW)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") #[Month]  Hours per Month Period (Hours/Month)
  LDCDN::VariableArray{5} = ReadDisk(db,"EOutput/LDCDN",year) #[ECC,Day,Month,Area,Node,Year]  Electric Load Curve (MW)
  LDCECC::VariableArray{5} = ReadDisk(db,"SOutput/LDCECC",year) #[ECC,Hour,Day,Month,Area,Year]  Electric Loads Dispatched (MW)
  LDCMS::VariableArray{4} = ReadDisk(db,"EOutput/LDCMS",year) #[Day,Month,Node,Area,Year]  Marketer System Load Curve (MW)
  LDCNd::VariableArray{5} = ReadDisk(db,"EOutput/LDCNd",year) #[ECC,Day,Month,Node,Area,Year]  Electric Load Curve (MW)
  LDCSA::VariableArray{2} = ReadDisk(db,"EOutput/LDCSA",year) #[Day,Area,Year]  Annual System Load Curve (MW)
  MBD::Float32 = ReadDisk(db,"EInput/MBD",year) #[Year]  Maximum Duration of Baseload Power (Hours)
  MBP::VariableArray{2} = ReadDisk(db,"EOutput/MBP",year) #[Month,Area,Year]  Maximum Baseload Point on Load Duration Curve (MW)
  MDP::VariableArray{2} = ReadDisk(db,"EOutput/MDP",year) #[Month,Area,Year]  Minimum Demand (MW)
  MILD::Float32 = ReadDisk(db,"EInput/MILD",year) #[Year]  Minimum Number of Hours of Operation for a Baseload Plant (Hours/Yr)
  MILP::VariableArray{2} = ReadDisk(db,"EOutput/MILP",year) #[Month,Area,Year]  Maximum Base Load Power (MW)
  PDP::VariableArray{2} = ReadDisk(db,"EOutput/PDP",year) #[Month,Area,Year]  Annual Peak Load
  PwrFrAve::VariableArray{3} = ReadDisk(db,"EGOutput/PwrFrAve",year) #[Power,Month,GenCo,Year]  Average Power Type Fraction (MW/MW)
  PwrFra::VariableArray{2} = ReadDisk(db,"EGOutput/PwrFra",year) #[Power,GenCo,Year]  Annual Power Type Fraction (MW/MW)
  SACL::VariableArray{2} = ReadDisk(db,"EOutput/SACL",year) #[Class,Area,Year]  Electricity Sales (GWh/Yr)
  SAEC::VariableArray{2} = ReadDisk(db,"EOutput/SAEC",year) #[ECC,Area,Year]  Electricity Sales (GWh/Yr)
  SAECN::VariableArray{3} = ReadDisk(db,"EOutput/SAECN",year) #[ECC,Node,Area,Year]  Electricity Sales (GWh/Yr)
  TDEF::VariableArray{2} = ReadDisk(db,"SInput/TDEF",year) #[Fuel,Area,Year]  T&D Efficiency (Btu/Btu)
  TSales::VariableArray{1} = ReadDisk(db,"EOutput/TSales",year) #[Area,Year]  Electricity Sales (GWh/Yr)
  ECCCLMap::VariableArray{2} = ReadDisk(db,"MainDB/ECCCLMap") #
  BugSw::Float32 = ReadDisk(db,"MainDB/BugSw")[1] # BugSw currently a vector of length 1
  PDPR::VariableArray{3} = zeros(Float32,length(Node),length(Area),length(Month))
  ADPR::VariableArray{3} = zeros(Float32,length(Node),length(Area),length(Month))
  MDPR::VariableArray{3} = zeros(Float32,length(Node),length(Area),length(Month))
  Alpha::VariableArray{4} = zeros(Float32,length(Node),length(Area),length(TimeP),length(Month))
  Beta::VariableArray{4} = zeros(Float32,length(Node),length(Area),length(TimeP),length(Month))
  Gamma::VariableArray{4} = zeros(Float32,length(Node),length(Area),length(TimeP),length(Month))
  ADPRFR::VariableArray{3} = zeros(Float32,length(Node),length(Area),length(Month))


end

function AreaLoadsToNodeDemands(data::Data)
  (; db,year) = data
  (; Hour) = data
  (; ECCs,Days,Months,Areas,Nodes) = data
  (; LDCDN,LDCECC,ArNdFr) = data

  for ecc in ECCs, day in Days, month in Months, area in Areas, node in Nodes
    LDCDN[ecc,day,month,area,node] = sum(LDCECC[ecc,hour,day,month,area]
                                     for hour in Select(Hour))*ArNdFr[area,node]
  end

  WriteDisk(db,"EOutput/LDCDN",year,LDCDN)
end

function NodeLoadsByMarketShare(data::Data)
  (; db,year) = data
  (; ECCs,Days,Months,Areas,Nodes) = data
  (; LDCNd,LDCDN) = data

  for ecc in ECCs, day in Days, month in Months, area in Areas, node in Nodes
    LDCNd[ecc,day,month,node,area] = LDCDN[ecc,day,month,area,node]
  end

  WriteDisk(db,"EOutput/LDCNd",year,LDCNd)
end


function AreaLoadsByMarketShare(data::Data)
  nothing
end

function LSESystemLoadCurve(data::Data)
  (; db,year) = data;
  (; Day,Fuel) = data;
  (; ECCs,Days,Months,Areas,Nodes) = data
  (; LDCMS,LDCDN,TDEF) = data;

  Electric = Select(Fuel,"Electric")

  for day in Days, month in Months, area in Areas, node in Nodes
    LDCMS[day,month,node,area] = sum(LDCDN[ecc,day,month,area,node] for ecc in ECCs)/
                                 TDEF[Electric,area]
  end

  Minimum = Select(Day,"Minimum")
  Average = Select(Day,"Average")
  for month in Months, area in Areas, node in Nodes
    LDCMS[Minimum,month,node,area] = min(LDCMS[Minimum,month,node,area],
                                     LDCMS[Average,month,node,area]*0.9)
  end

  WriteDisk(db,"EOutput/LDCMS",year,LDCMS)
end

function LoadsPeakAverageMinimum(data::Data)
  AreaLoadsToNodeDemands(data)
  LSESystemLoadCurve(data)
end

function ElectricSales(data::Data)
  (; db,year) = data
  (; Day) = data
  (; ECCs,Months,Areas,Nodes,Classes) = data
  (; HoursPerMonth,LDCDN,SAECN,ECCCLMap) = data
  (; SAEC,SACL,TSales) = data

  Average = Select(Day,"Average")
  for ecc in ECCs, area in Areas, node in Nodes
    SAECN[ecc,node,area] = sum(LDCDN[ecc,Average,month,area,node]*
                           HoursPerMonth[month] for month in Months)/1000.0
  end

  for area in Areas, ecc in ECCs
    SAEC[ecc,area] = sum(SAECN[ecc,node,area] for node in Nodes)
  end

  for class in Classes, area in Areas
    SACL[class,area] = sum(SAEC[ecc,area]*ECCCLMap[ecc,class] for ecc in ECCs)
  end

  for area in Areas
    TSales[area] = sum(SACL[class,area] for class in Classes)
  end

  WriteDisk(db,"EOutput/SAECN",year,SAECN)
  WriteDisk(db,"EOutput/SAEC",year,SAEC)
  WriteDisk(db,"EOutput/SACL",year,SACL)
  WriteDisk(db,"EOutput/TSales",year,TSales)
end

function ReCoPeakAverageMinimumLoads(data::Data)
  (; db,year) = data
  (; Day) = data
  (; Months,Areas,Nodes) = data
  (; LDCMS,ADP,MDP,PDP) = data

  Average = Select(Day,"Average")
  Minimum = Select(Day,"Minimum")
  Peak = Select(Day,"Peak")

  for month in Months, area in Areas
    ADP[month,area] = sum(LDCMS[Average,month,node,area] for node in Nodes)
    MDP[month,area] = sum(LDCMS[Minimum,month,node,area] for node in Nodes)
    PDP[month,area] = sum(LDCMS[Peak,month,node,area] for node in Nodes)
  end

  WriteDisk(db,"EOutput/ADP",year,ADP)
  WriteDisk(db,"EOutput/MDP",year,MDP)
  WriteDisk(db,"EOutput/PDP",year,PDP)
end

function ReCoMaximumBaseloadPoint(data::Data)
  (; db,year) = data
  (; Months,Areas) = data
  (; MBP,ADP,MDP,PDP,MBD) = data

  for month in Months, area in Areas
    @finite_math loc1 = max(0,((PDP[month,area]-ADP[month,area])/
                       (ADP[month,area]-MDP[month,area])))
    @finite_math MBP[month,area] = MDP[month,area]+(PDP[month,area]-
                                   MDP[month,area])*(1-MBD/8760)^loc1
  end

  WriteDisk(db,"EOutput/MBP",year,MBP)
end

function ReCoMaximumIntermediatePoint(data::Data)
  (; db,year) = data
  (;Months,Areas) = data
  (; ADP,MDP,PDP,MILD,MILP) = data

  for month in Months, area in Areas
    @finite_math loc1 = max(0,((PDP[month,area]-ADP[month,area])/
                       (ADP[month,area]-MDP[month,area])))
    @finite_math MILP[month,area] = MDP[month,area]+(PDP[month,area]-
                                    MDP[month,area])*(1-MILD/8760)^loc1
  end

  WriteDisk(db,"EOutput/MILP",year,MILP)
end

function PowerFractions(data::Data)
  (; db,year) = data
  (; Month,Power) = data
  (; Months,Areas,GenCos,Powers) = data
  (; ADP,MDP,PDP,MBD,MILD,MILP,BugSw,PwrFrAve,PwrFra,MBP) = data

  Base = Select(Power,"Base")
  Interm = Select(Power,"Interm")
  Peak = Select(Power,"Peak")

  if BugSw == 1.0
    PDPPF = Vector{Float32}(undef,length(Month))
    ADPPF = Vector{Float32}(undef,length(Month))
    MDPPF = Vector{Float32}(undef,length(Month))
    MBPPF = Vector{Float32}(undef,length(Month))
    MILPPF = Vector{Float32}(undef,length(Month))
    for month in Months
      PDPPF[month] = sum(PDP[month,area] for area in Areas)
      ADPPF[month] = sum(ADP[month,area] for area in Areas)
      MDPPF[month] = sum(MDP[month,area] for area in Areas)

      Loc1 = max(0,((PDPPF[month]-ADPPF[month])/(ADPPF[month]-MDPPF[month])))
      MBPPF[month] = MDPPF[month]+(PDPPF[month]-MDPPF[month])*(1-MBD/8760)^Loc1
      MILPPF[month] = MDPPF[month]+(PDPPF[month]-MDPPF[month])*(1-MILD/8760)^Loc1
    end

    for month in Months, genco in GenCos
      PwrFrAve[Base,month,genco] = MBPPF[month]/PDPPF[month]
      PwrFrAve[Interm,month,genco] = (MILPPF[month]-MBPPF[month])/PDPPF[month]
      PwrFrAve[Peak,month,genco] = (PDPPF[month]-MILPPF[month])/PDPPF[month]
    end

  else
    for month in Months, genco in GenCos
      PwrFrAve[Base,month,genco] = sum(MBP[month,area] for area in Areas) /
        sum(PDP[month,area] for area in Areas)
    
      PwrFrAve[Interm,month,genco] = sum((MILP[month,area] - MBP[month,area]) for area in Areas)/
        sum(PDP[month,area] for area in Areas)
    
      PwrFrAve[Peak,month,genco] = sum((PDP[month,area] - MILP[month,area]) for area in Areas)/
        sum(PDP[month,area] for area in Areas)
    end
  end # end BugSw

  for power in Powers, genco in GenCos
    @finite_math PwrFra[power,genco] = sum(PwrFrAve[power,month,genco] for month in Months)/
      sum(PwrFrAve[AllPowers,month,genco] for month in Months, AllPowers in Powers)
  end
  
  WriteDisk(db,"EGOutput/PwrFrAve",year,PwrFrAve)
  WriteDisk(db,"EGOutput/PwrFra",year,PwrFra)
end

function SystemAnnualPeakAverageMinimumLoads(data::Data)
  (; db,year) = data
  (; Day) = data
  (; Months,Areas) = data
  (; LDCSA,MDP,PDP,ADP,HoursPerMonth) = data

  Average = Select(Day,"Average")
  Minimum = Select(Day,"Minimum")
  Peak = Select(Day,"Peak")

  for area in Areas
    LDCSA[Minimum,area] = minimum(MDP[:,area])
    LDCSA[Average,area] = sum(ADP[month,area]*HoursPerMonth[month] for month in Months)/
      sum(HoursPerMonth[month] for month in Months)
    LDCSA[Peak,area] = maximum(PDP[:,area])
  end

  WriteDisk(db,"EOutput/LDCSA",year,LDCSA)
end

function LoadShapeInputs(data::Data)
  (; Day) = data
  (; Months,Areas,Nodes) = data
  (; LDCMS,PDPR,ADPR,MDPR) = data

  Average = Select(Day,"Average")
  Minimum = Select(Day,"Minimum")
  Peak = Select(Day,"Peak")

  for month in Months, area in Areas, node in Nodes
    PDPR[node,area,month] = LDCMS[Peak,month,node,area]
    ADPR[node,area,month] = LDCMS[Average,month,node,area]
    MDPR[node,area,month] = LDCMS[Minimum,month,node,area]
  end
end

function LoadShapeParameters(data::Data)
  (; Months,Areas,Nodes,TimePs) = data
  (; PDPR,ADPR,MDPR) = data
  (; Alpha,Beta,Gamma) = data

  for month in Months, area in Areas, node in Nodes, timep in TimePs
    @finite_math Alpha[node,area,timep,month] = (PDPR[node,area,month]-ADPR[node,area,month])/
                                                (ADPR[node,area,month]-MDPR[node,area,month])
    @finite_math Beta[node,area,timep,month] = (1+Alpha[node,area,timep,month])/Alpha[node,area,timep,month]
    @finite_math Gamma[node,area,timep,month] = Alpha[node,area,timep,month]/Alpha[node,area,timep,month]*
      (PDPR[node,area,month]-MDPR[node,area,month])^(1/(Alpha[node,area,timep,month]+1))
  end

end

function IntervalPeak(data::Data)
  (; db,year) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; PDPR,MDPR,HDHrPk,HoursPerMonth,HMPDP) = data
  (; Alpha) = data

  for month in Months, area in Areas, node in Nodes, timep in TimePs
  
    @finite_math HMPDP[node,area,timep,month] = MDPR[node,area,month]+
      (PDPR[node,area,month]-MDPR[node,area,month])*
      (1-HDHrPk[timep,month]/HoursPerMonth[month])^Alpha[node,area,timep,month]
  end
  WriteDisk(db,"EOutput/HMPDP",year,HMPDP)
end

function IntervalMinimum(data::Data)
  (; db,year) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; PDPR,MDPR,HoursPerMonth) = data
  (; Alpha) = data
  (;HMMDP,HDHrMn) = data

  for month in Months, area in Areas, node in Nodes, timep in TimePs
    @finite_math HMMDP[node,area,timep,month] = MDPR[node,area,month]+(PDPR[node,area,month]-MDPR[node,area,month])*
      (1-HDHrMn[timep,month]/HoursPerMonth[month])^Alpha[node,area,timep,month]
  end
  WriteDisk(db,"EOutput/HMMDP",year,HMMDP)
end

function EnergyBelowHighestLoad(data::Data)
  (; db,year) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; HMPDP,MDPR,HoursPerMonth,HMEGPk) = data
  (; Beta,Gamma) = data

  for month in Months, area in Areas, node in Nodes, timep in TimePs
    @finite_math HMEGPk[node,area,timep,month] = HoursPerMonth[month]/1000*(HMPDP[node,area,timep,month]-
      (max(0,HMPDP[node,area,timep,month]-MDPR[node,area,month])/Gamma[node,area,timep,month])^
        Beta[node,area,timep,month]/Beta[node,area,timep,month])
  end
  WriteDisk(db,"EOutput/HMEGPk",year,HMEGPk)
end

function EnergyBelowLowestLoad(data::Data)
  (; db,year) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; MDPR,HoursPerMonth) = data
  (; Beta,Gamma) = data
  (;HMMDP,HMEGMn) = data

  for month in Months, area in Areas, node in Nodes, timep in TimePs
    @finite_math HMEGMn[node,area,timep,month] = HoursPerMonth[month]/1000*(HMMDP[node,area,timep,month]-
    (max(0,HMMDP[node,area,timep,month]-MDPR[node,area,month])/Gamma[node,area,timep,month])^
    Beta[node,area,timep,month]/Beta[node,area,timep,month])
  end
  WriteDisk(db,"EOutput/HMEGMn",year,HMEGMn)
end

function GenerationNeededPerInterval(data::Data)
  (; Months,Areas,Nodes,TimePs) = data
  (; HMPDP,HMEGMn,HMEGPk,HDHours) = data
  (; HDHrPk) = data
  (; HMMDP,HMEnergy) = data

  for month in Months, area in Areas, node in Nodes, timep in TimePs
  
    @finite_math HMEnergy[node,area,timep,month] = 
      (HMMDP[node,area,timep,month]*HDHours[timep,month]/1000)+
      max((HMEGPk[node,area,timep,month]-HMEGMn[node,area,timep,month])-
          (HMPDP[node,area,timep,month] -HMMDP[node,area,timep,month])*
           HDHrPk[timep,month]/1000,0)
  end

end

function NormalizeToLoadCurve(data::Data)
  (; db,year) = data
  (; TimeP) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; ADPR,HoursPerMonth,HMEnergy,ADPRFR) = data
  
  for month in Months, area in Areas, node in Nodes, timep in TimePs
  
    @finite_math ADPRFR[node,area,month] = (ADPR[node,area,month]*HoursPerMonth[month]/1000)/
      sum(HMEnergy[node,area,timep2,month] for timep2 in Select(TimeP))
    
    @finite_math HMEnergy[node,area,timep,month] =
      HMEnergy[node,area,timep,month]*ADPRFR[node,area,month]
  end

  WriteDisk(db,"EOutput/HMEnergy",year,HMEnergy)
end

function AverageLoadInInterval(data::Data)
  (; db,year) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; HMADP,HMEnergy,HDHours) = data

  for month in Months, area in Areas, node in Nodes, timep in TimePs
    HMADP[node,area,timep,month] = HMEnergy[node,area,timep,month]/
                                   HDHours[timep,month]*1000
  end

  WriteDisk(db,"EOutput/HMADP",year,HMADP)
end

function LoadsInTimeIntervals(data::Data)
  LoadShapeInputs(data)
  LoadShapeParameters(data)
  IntervalPeak(data)
  IntervalMinimum(data)
  EnergyBelowHighestLoad(data)
  EnergyBelowLowestLoad(data)
  GenerationNeededPerInterval(data)
  NormalizeToLoadCurve(data)
  AverageLoadInInterval(data)
end

function PeakLoadPerHour(data::Data)
  (; db,year) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; HMPDP,HDPDP) = data

  for node in Nodes, timep in TimePs, month in Months
    HDPDP[node,timep,month] = sum(HMPDP[node,area,timep,month] for area in Areas)
  end

  WriteDisk(db,"EGOutput/HDPDP",year,HDPDP)
end

function EnergyPerHour(data::Data)
  (; db,year) = data
  (; Months,Areas,Nodes,TimePs) = data
  (; HDEnergy,HMEnergy) = data

  for node in Nodes, timep in TimePs, month in Months
    HDEnergy[node,timep,month] = sum(HMEnergy[node,area,timep,month] for area in Areas)
  end

  WriteDisk(db,"EGOutput/HDEnergy",year,HDEnergy)
end

function AverageLoadPerHour(data::Data)
  (; db,year) = data
  (; Months,Nodes,TimePs) = data
  (; HDADP,HDEnergy,HDHours) = data

  for node in Nodes, timep in TimePs, month in Months
    HDADP[node,timep,month] = HDEnergy[node,timep,month]/HDHours[timep,month]*1000
  end

  WriteDisk(db,"EGOutput/HDADP",year,HDADP)
end

function HourlyLoads(data::Data)
  PeakLoadPerHour(data)
  EnergyPerHour(data)
  AverageLoadPerHour(data)
end

function ElecLoadCurvesAndSales(data::Data)
  LoadsPeakAverageMinimum(data)
  ElectricSales(data)
  ReCoPeakAverageMinimumLoads(data)
  ReCoMaximumBaseloadPoint(data)
  ReCoMaximumIntermediatePoint(data)
  SystemAnnualPeakAverageMinimumLoads(data)
  PowerFractions(data)

  LoadsInTimeIntervals(data)
  HourlyLoads(data)
end

end # module ELoadCurve
