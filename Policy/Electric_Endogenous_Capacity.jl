# 
# Electric_Endogenous_Capacity.jl
#
# TD July 22, 2025:
# - changed GCPot for MB because there is too much OGCT in projections (PjMax is not respected)
# - reduced nuclear and smnr PjMax because it's developping too fast 
#
# TD July 4, 2025: this file is temporary
# Normaly the GCPot values are in vGCPot, but there is a problem in the simulation since the GCPot outputs are wrong.
# The file is used to implement the right data until the problem is solved (by SSI)
# The file has been tested but it will be updated since some values are irealistic
#
# This file contains the maximum capacities that can be installed in each PT by yearly
# GCPot refers to the absolute maximum while PjMax is the maximum that can be installed by year.
# The values correspond to those decided for the CER (alignment with NextGrid)
# Consequently, Electric_Endogenous_Capacity_CER.txp won't be needed anymore
#            

using EnergyModel

module Electric_Endogenous_Capacity

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  NodeDS::SetArray = ReadDisk(db,"MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GCPA::VariableArray{3} = ReadDisk(db,"EOutput/GCPA") # [Plant,Area,Year] Generation Capacity (MW)
  GCPot::VariableArray{4} = ReadDisk(db,"EGOutput/GCPot") # [Plant,Node,Area,Year] Maximum Potential Generation Capacity (MW)
  NdArFr::VariableArray{3} = ReadDisk(db,"EGInput/NdArFr") # [Node,Area,Year] Fraction of the Node in each Area (MW/MW)
  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") # [Plant,Area] Maximum Project Size (MW)
  xGCPot::VariableArray{4} = ReadDisk(db,"EGInput/xGCPot") # [Plant,Node,Area,Year] Exogenous Maximum Potential Generation Capacity (MW)
end 

function NodeAreaIndex(data,Ind)
  (; Area,Node) = data 
  if Area[Ind] == "NL"
    return Select(Node,["NL","LB"])
  else 
    return Select(Node,Area[Ind])
  end
end
  
function ElecPolicy(db)
  data = EControl(; db)
  (; Area,Areas,Node,Nodes,Plant,Plants,Year,Years) = data
  (; GCPA,PjMax,xGCPot) = data

  #
  # Reset GCPot for Canada
  #
  areas = Select(Area,["ON","QC","BC","NB","NS","NL","PE","AB","MB","SK","NT","NU","YT"])
  
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for year in Years, node in nodes, plant in Plants
      xGCPot[plant,node,area,year] = 0
    end
  end
  
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # No development for the following plant types:
  # Biogas, Biomass, Waste, Coal, CoalCCS, Geothermal, FuelCell, OGSteam
  # OtherGeneration, PumpedHydro, SolarThermal, Tidal, Unknown
  #
  #plants = Select(Plant,["Biogas","Biomass","Waste","Coal","CoalCCS","Geothermal","FuelCell","OGSteam","OtherGeneration","PumpedHydro","SolarThermal","Tidal"])
  #years = collect(Future:Final)
  #for area in areas
  #  nodes = NodeAreaIndex(data,area)
  #  for plant in plants, node in nodes, year in years
  #    xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
  #  end
  #end
  
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  # 
  # OGCC (NGCC in NxtGrid)
  #
  plants = Select(Plant,"OGCC")
  years = collect(Future:Final)
  areas = Select(Area,["BC","MB","ON","QC","NL","PE","NT","NU","YT","AB","SK","NB","NS"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end
  
  #
  # No limit after 2029
  # 
  years = collect(Yr(2030):Final)
  areas = Select(Area,["AB","SK","NB","NS"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end
  
  #
  # SmallOGCC
  #
  plants = Select(Plant,"SmallOGCC")
  years = collect(Future:Final)
  areas = Select(Area,["ON","QC","BC","MB","NL","PE","NT","NU","YT","AB","SK","NB","NS"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end
  
  #
  # No limit after 2029
  #
  years = collect(Yr(2030):Final)
  areas = Select(Area,["AB","SK","NB","NS"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end
  
  #
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # OGCT (several types in NextGrid, matching uncrtain)
  #
  plants = Select(Plant,"OGCT")
  years = collect(Future:Final)
  
  #
  # No development
  #
  areas = Select(Area,["QC","BC","NL","PE"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end  
  
  #
  # Some limit (Future:Final)
  #
  area_limits = [
    ("NT",134.6),
    ("NU",111.72),
    ("YT",99.805)
  ]
  for (area_name,increment) in area_limits
    area = Select(Area,area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end
  
  #
  # Some limit (ON)
  # Six-period development
  #
  dev_schedule = [("ON",
                 [(Future,  Yr(2029),    0),
                  (Yr(2030),Yr(2034), 2143),
                  (Yr(2035),Yr(2039), 5714),
                  (Yr(2040),Yr(2044), 9286),
                  (Yr(2045),Yr(2049),12857),
                  (Yr(2050),Yr(2050),15000)])
                 ]
  for (area_name, periods) in dev_schedule
    area = Select(Area,area_name)
    nodes = NodeAreaIndex(data,area)
    for (start_year,end_year,increment) in periods
      years = collect(start_year:end_year)
      for plant in plants, node in nodes, year in years
        xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
      end
    end
  end
  
  #
  # NB limits
  #
  years=collect(Future:Yr(2029))
  areas = Select(Area,"NB")
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 600
    end
  end
  years=collect(Yr(2030):Final)
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end
  
  # Some limit (MB)
  # Six-period development
  dev_schedule = [("MB",
                 [(Future,  Yr(2029), 200),
                  (Yr(2030),Yr(2034), 400),
                  (Yr(2035),Yr(2039), 600),
                  (Yr(2040),Yr(2044), 800),
                  (Yr(2045),Yr(2050),1000)])
                 ]
  for (area_name,periods) in dev_schedule
    area = Select(Area,area_name)
    nodes = NodeAreaIndex(data,area)
    for (start_year,end_year,increment) in periods
      years = collect(start_year:end_year)
      for plant in plants, node in nodes, year in years
        xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
      end
    end
  end
  
  #
  # No Limit
  #
  years = collect(Future:Final)
  areas = Select(Area,["AB","SK","NS"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end

  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # NGCCS
  #
  plants = Select(Plant,"NGCCS")
  years = collect(Future:Final)
  
  #
  # No development
  #
  areas = Select(Area,["BC","ON","QC","NB","NS","NL","PE","NT","NU","YT","AB","MB","SK"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end
  
  #
  # No Limit after 2029
  #
  years = collect(Yr(2030):Final)
  areas = Select(Area,["AB","MB","SK"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end
  
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # BiomassCCS
  #
  plants = Select(Plant,"BiomassCCS")
  years = collect(Future:Final)
  
  #
  # No development
  #
  areas = Select(Area,["BC","ON","QC","NB","NS","NL","PE","NT","NU","YT","AB","MB","SK"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end
  
  #
  # No Limit after 2029
  #
  years = collect(Yr(2030):Final)
  areas = Select(Area,["AB","MB","SK"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end
 
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # BaseHydro (Because the potential is defined for all Hydro, it is split using 2023 installed capacity ratio by plant type)
  #
  plants = Select(Plant,"BaseHydro")
  years = collect(Future:Final)
  
  #
  # No development
  #
  areas = Select(Area,["PE","NS","NL","NU","NT","YT","ON","AB","MB","SK","QC","BC","NB"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end

  #
  # Limited development after 2029
  #
  years = collect(Yr(2030):Final)
  area_limits = [("ON",4519),
                 ("QC",  62),
                 ("BC", 733),
                 ("AB",1000),
                 ("MB",8407),
                 ("SK", 485),
                 ("NB",   3)]
  for (area_name,increment) in area_limits
    area = Select(Area,area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end

  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # SmallHydro (Because the potential is defined for all Hydro, it is split using 2023 installed capacity ratio by plant type)
  #
  plants = Select(Plant,"SmallHydro")
  years = collect(Future:Final)

  #
  # No development
  #
  areas = Select(Area,["SK","ON","MB","NB","AB","PE","NS","NL","NU","NT","YT","QC","BC"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end
  
  #
  # Limited development
  #
  years = collect(Yr(2030):Final)
  area_limits = [("QC",  59),
                 ("BC",1993),]
  for (area_name,increment) in area_limits
    area = Select(Area,area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end
  
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # PeakHydro (Because the potential is defined for all Hydro, it is split using 2023 installed capacity ratio by plant type)
  #
  plants = Select(Plant,"PeakHydro")
  years = collect(Future:Final)

  #
  # No development
  #
  areas = Select(Area,["ON","AB","PE","YT","NS","NU","BC","SK","NB","NL","QC","NT", "MB"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end

  #
  # QC Some development before 2030 (Patch Sept 2025)
  # Rational: QC plans increasing hydro power capacity in existing power plants by 2130
  # However, not all details are known (742 MW are not documented in current QC projects)
  # It is expected the increase will start occuring before 2030: ~ +80MW/year (742 MW over 2027-2035)
  #
  years = collect(Yr(2027):Yr(2029))
  areas = Select(Area,"QC")
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]+240
    end
  end

  #
  # Some development
  #
  years = collect(Yr(2030):Final)
  area_limits = [("SK", 3458),
                 ("NB", 577),
                 ("NL", 4277),
                 ("QC", 40122)]
  for (area_name, increment) in area_limits
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end

  #
  # BC (delayed to 2035 because of consultation feedback)(TD 2025-09-26)
  #

  years = collect(Yr(2035):Final)
  area_limits = [("BC", 27566)]
  for (area_name, increment) in area_limits
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end

  #
  # MB Some development (Patch July 2025)
  #
  years = collect(Yr(2030):Final)
  areas = Select(Area,"MB")
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]*1.1
    end
  end

  #  
  # NT and NU are based on a 2006 study (used in the 2008 study below), thus using GPCA(2006):
  # https://waterpowercanada.ca/wp-content/uploads/2019/06/2008-hydropower-past-present-future-en.pdf
  #
  years = collect(Yr(2030):Final)
  area_limits = [("NT", 11524),
                 ("YT", 17664),]
  for (area_name, increment) in area_limits
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2006)] + increment
    end
  end
  
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # OnshoreWind
  #
  plants = Select(Plant, "OnshoreWind")

  #
  # Limited development before 2030
  #
  years = collect(Future:Yr(2029))
  area_limits = [
    ("BC", 6725),
    ("AB", 6745),
    ("SK", 1628),
    ("MB", 5000),
    ("ON", 5000),
    ("QC", 7500),
    ("NB", 1200),
    ("NL", 1000),
    ("NS",  325),
    ("PE", 1000),
    ("NT",   50), 
    ("NU",   50), 
    ("YT",   50)]
  for (area_name, increment) in area_limits
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end
  
  #
  # More development after 2030
  #
  years = collect(Yr(2030):Final)
  area_limits = [
    ("BC",15000),
    ("AB",25000),
    ("SK",10000),
    ("MB", 5000),
    ("ON",20000),
    ("QC",20000),
    ("NB", 5000),
    ("NL", 1000),
    ("NS", 5000),
    ("PE", 1000),
    ("NT",  500), 
    ("NU",  500), 
    ("YT",  500)]
  for (area_name, increment) in area_limits
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end
  
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # OffshoreWind
  #
  plants = Select(Plant, "OffshoreWind")
  
  #
  # No development
  #
  years = collect(Future:Final)  
  areas = Select(Area, ["AB","MB","SK","ON","QC","NB","PE","NT","NU","YT"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end
  
  #
  # Limited development BC
  #
  area = Select(Area,"BC")
  nodes = NodeAreaIndex(data,area)
  years = collect(Future:Yr(2034))
  for plant in plants, node in nodes, year in years
    xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
  end
  years = collect(Yr(2035):Final)
  for plant in plants, node in nodes, year in years
    xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 1000
  end  
  
  #
  # Limited development NS
  #
  area = Select(Area,"NS")
  nodes = NodeAreaIndex(data,area)
  years = collect(Future:Yr(2034))
  for plant in plants, node in nodes, year in years
    xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
  end
  years = collect(Yr(2035):Final)
  for plant in plants, node in nodes, year in years
    xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 500
  end   

  #
  # Limited development NL
  #
  area = Select(Area,"NL")
  nodes = NodeAreaIndex(data,area)
  years = collect(Future:Yr(2029))
  for plant in plants, node in nodes, year in years
    xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
  end
  years = collect(Yr(2030):Final)
  for plant in plants, node in nodes, year in years
    xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 500
  end    

  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # SolarPV
  #
  plants = Select(Plant, "SolarPV")
  years = collect(Future:Yr(2029))

  #
  # Some development up to 2030
  #
  area_limits = [
    ("BC", 7500),
    ("AB", 5350),
    ("SK", 5000),
    ("MB", 1000),
    ("ON", 7500),
    ("QC", 5000),
    ("NB", 1000),
    ("NS", 300),
    ("NL", 150),
    ("PE", 1000),
    ("NT", 15),
    ("NU", 15),
    ("YT", 15)]
  for (area_name, increment) in area_limits
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end
  
  #
  # More development after 2030
  #
  years = collect(Yr(2030):Final)
  area_limits = [
    ("BC", 7500),
    ("AB", 7500),
    ("SK", 5000),
    ("MB", 1000),
    ("ON", 7500),
    ("QC", 5000),
    ("NB", 1000),
    ("NS", 1000),
    ("NL", 1000),
    ("PE", 1000),
    ("NT", 100),
    ("NU", 100),
    ("YT", 100)]
  for (area_name, increment) in area_limits
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end
 
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # Wave
  #
  plants = Select(Plant, "Wave")
  years = collect(Future:Final)

  #
  # No development
  #
  areas = Select(Area, ["ON","QC","BC","NB","NL","PE","AB","MB","SK","NT","NU","YT"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end

  #
  # Two-period development for NS
  #
  area = Select(Area, "NS")
  nodes = NodeAreaIndex(data,area)
  dev_schedule = [(Future,   Yr(2029), 10),
                  (Yr(2030), Final,    19.65)]
  for (start_year, end_year, increment) in dev_schedule
    years = collect(start_year:end_year)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
    end
  end

  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # Battery (Energy Storage)
  #
  plants = Select(Plant, "Battery")
  years = collect(Future:Final)

  #
  # No limit for all areas
  #
  areas = Select(Area, ["ON","QC","BC","NB","NS","NL","PE","AB","MB","SK","NT","NU","YT"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end
  
  #°º¤ø,¸¸,ø¤º°`°º¤ø,¸,ø¤°º¤ø,¸¸,ø¤º°`°º¤ø,¸
  #
  # Nuclear
  #
  plants = Select(Plant, "Nuclear")
  
  #
  # No development
  #
  years = collect(Future:Final)
  areas = Select(Area, ["BC","MB","NL","PE","NT","NU","YT"])
  for area in areas 
    nodes = NodeAreaIndex(data, area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end

  #
  # No limit after 2030 (ON)
  #
  areas = Select(Area, ["ON"])
  for area in areas  
    nodes = NodeAreaIndex(data,area)  
    years = collect(Future:Yr(2029))
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end    
    years = collect(Yr(2030):Final)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end

  #
  # No limit after 2035 (SK, QC, NB, NS)
  #
  areas = Select(Area, ["SK","QC","NB","NS"])
  for area in areas
    nodes = NodeAreaIndex(data,area) 
    years = collect(Future:Yr(2034))
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end   
   
    #
    # Patch July 2025 (some limit after 2035)
    #
    years = collect(Yr(2035):Yr(2039))
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 300
    end
    years = collect(Yr(2040):Yr(2045))
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 900
    end
    years = collect(Yr(2045):Yr(2050))
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 1500
    end
  end

  #
  # There is a new project in AB: Peace River (4.8 GW)
  # It's too uncertain to be modeled exogenously
  # Increasing GCPot to make it possible endogenously
  #
  areas = Select(Area, ["AB"])
  for area in areas
    nodes = NodeAreaIndex(data,area) 
    years = collect(Future:Yr(2034))
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end   
    years = collect(Yr(2035):Yr(2050))
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + 5000
    end
  end

  #
  # SMNR
  #
  plants = Select(Plant,"SMNR")
  years = collect(Future:Final)
  #
  # No development
  #
  areas = Select(Area, ["BC","MB","NL","PE","NT","NU","YT","ON","AB","SK","QC","NB","NS"])
  for area in areas 
    nodes = NodeAreaIndex(data, area)
    for plant in plants, node in nodes, year in Years
      xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)]
    end
  end
  
  #
  # Limited development after 2030 (NB)
  #
  dev_schedule = [
    ("NB", [(Future,   Yr(2029),   0),
            (Yr(2030), Yr(2039), 840),
            (Yr(2040), Final,    840)])]
  for (area_name, periods) in dev_schedule
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for (start_year, end_year, increment) in periods
      years = collect(start_year:end_year)
      for plant in plants, node in nodes, year in years
        xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
      end
    end
  end

  # Limited development after 2035 (SK, QC, NS)
  dev_schedule = [
    ("SK", [(Future,   Yr(2034),    0),
            (Yr(2035), Yr(2039), 1690),
            (Yr(2040), Final,    3220)]),               
    ("QC", [(Future,   Yr(2034),     0),
            (Yr(2035), Yr(2039), 10000),
            (Yr(2040), Final,    10000)]),              
    ("NS", [(Future,   Yr(2034),   0),
            (Yr(2035), Yr(2039), 840),
            (Yr(2040), Final,    840)])]
  for (area_name, periods) in dev_schedule
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for (start_year, end_year, increment) in periods
      years = collect(start_year:end_year)
      for plant in plants, node in nodes, year in years
        xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
      end
    end
  end

  #
  # patch July 2025 (AB, ON)
  #
  dev_schedule = [
    ("AB", [(Future, Yr(2034), 0), (Yr(2035), Yr(2039), 300), (Yr(2040), Yr(2044), 900),(Yr(2045), Yr(2050), 1500)]),
    ("ON", [(Future, Yr(2034), 0), (Yr(2035), Yr(2039), 300), (Yr(2040), Yr(2044), 900),(Yr(2045), Yr(2050), 1500)])]
  for (area_name, periods) in dev_schedule
    area = Select(Area, area_name)
    nodes = NodeAreaIndex(data,area)
    for (start_year, end_year, increment) in periods
      years = collect(start_year:end_year)
      for plant in plants, node in nodes, year in years
        xGCPot[plant,node,area,year] = GCPA[plant,area,Yr(2023)] + increment
      end
    end
  end

  #
  # No limit after 2035
  #
  years = collect(Yr(2035):Final)
  areas = Select(Area, ["NT","NU","YT"])
  for area in areas
    nodes = NodeAreaIndex(data,area)
    for plant in plants, node in nodes, year in years
      xGCPot[plant,node,area,year] = 1000000
    end
  end

  WriteDisk(db,"EGInput/xGCPot",xGCPot)

  #
  # PjMax Section
  #
  
  #
  # OGCC
  #
  PeakHydro = Select(Plant,"OGCC")
  area_limits = [
    ("AB", 500),
    ("SK", 500),
    ("NB", 500),
    ("NS", 500)]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[PeakHydro,area] = limit
  end

  #
  # SmallOGCC
  #
  PeakHydro = Select(Plant,"SmallOGCC")
  area_limits = [
    ("AB", 100),
    ("SK", 100),
    ("NB", 100),
    ("NS", 100)]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[PeakHydro,area] = limit
  end

  #
  # OGCT
  #
  PeakHydro = Select(Plant,"OGCT")
  area_limits = [
    ("AB", 200),
    ("SK", 200),
    ("NB", 200),
    ("NS", 200),
    ("MB", 200),
    ("ON", 200)]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[PeakHydro,area] = limit
  end

  #
  # NGCCS
  #
  PeakHydro = Select(Plant,"NGCCS")
  area_limits = [
    ("AB", 600),
    ("SK", 600),
    ("MB", 600)
  ]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[PeakHydro,area] = limit
  end

  #
  # Peakhydro
  #
  PeakHydro = Select(Plant,"PeakHydro")
  area_limits = [
    ("BC", 300),
    ("SK", 200),
    ("MB", 100), # Patch July 2025
    ("QC", 500), # Patch July 2025
    ("NB", 100),
    ("NL", 300),
    ("NT", 50),
    ("YT", 50)
  ]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[PeakHydro,area] = limit
  end

  #
  # Small Hydro
  #
  SmallHydro = Select(Plant,"SmallHydro")
  areas = Select(Area, ["QC","BC"])
  for area in areas
    PjMax[SmallHydro,area] = 50
  end

  #
  # Base Hydro
  #
  BaseHydro = Select(Plant,"BaseHydro")
  area_limits = [
    ("BC", 100),
    ("AB", 100),
    ("SK", 100),
    ("MB", 100),
    ("ON", 100),
    ("QC", 50),
    ("NB", 50)]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[BaseHydro,area] = limit
  end

  #
  # Battery (numbers = numbers from original TXP)
  #
  Battery = Select(Plant,"Battery")
  
  #
  # Areas ON-AB
  #
  areas = Select(Area,(from="ON",to="AB"))
  for area in areas
    PjMax[Battery,area] = 40
  end
  
  #
  # Areas MB-NL
  #
  areas = Select(Area,(from="MB",to="NL"))
  for area in areas
    PjMax[Battery,area] = 15
  end
  
  #
  # Areas PE-NU
  #
  areas = Select(Area,(from="PE",to="NU"))
  for area in areas
    PjMax[Battery,area] = 1
  end

  #
  # Biomass
  #
  Biomass = Select(Plant,"Biomass")
  
  #
  # Areas ON-NL
  #
  areas = Select(Area,(from="ON",to="NL"))
  for area in areas
    PjMax[Biomass,area] = 30
  end
  
  #
  # Areas PE-NU
  #
  areas = Select(Area,(from="PE",to="NU"))
  for area in areas
    PjMax[Biomass,area] = 1
  end

  #
  # Onshore Wind : numbers = 0.75 x Max(annual new capacity, 1985-2025)
  #
  OnshoreWind = Select(Plant,"OnshoreWind")
  
  area_limits = [
    ("ON", 750),
    ("QC", 750),
    ("SK", 130), # July Patch from 260 to 130
    ("AB", 350),
    ("NS", 190),
    ("BC", 300), # (patch July 2025)
    ("MB", 150), # (patch July 2025)
    ("NB", 75),
    ("PE", 75),
    ("NL", 20),
    ("NT", 20),
    ("NU", 10),
    ("YT", 1)]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[OnshoreWind,area] = limit
  end

  #
  # Offshore Wind : GCPot=500 MW, it does not seem necessary to cap the annual addition
  #

  #
  # Solar PV (too few data to use onshore wind method, numbers = 0.5 x onshore wind numbers, min=1)
  #
  SolarPV = Select(Plant,"SolarPV")
  
  area_limits = [
    ("ON", 325),
    ("QC", 325),
    ("SK", 130),
    ("AB", 175),
    ("NS", 95),
    ("BC", 75),
    ("MB", 17.5),
    ("NB", 17.5),
    ("PE", 17.5),
    ("NL", 10),
    ("NT", 10),
    ("NU", 5),
    ("YT", 1)
  ]
  for (area_name, limit) in area_limits
    area = Select(Area,area_name)
    PjMax[SolarPV,area] = limit
  end

  #
  # SMNR (the default size seems to be 300 MW)
  #
  SMNR = Select(Plant,"SMNR")
  areas = Select(Area,["ON","AB","SK","QC","NB","NS","NT","YT","NU"])
  for area in areas
    PjMax[SMNR,area] = 300
  end

  #
  # Nuclear (a reactor is about 1000 MW)
  #
  Nuclear = Select(Plant,"Nuclear")
  areas = Select(Area,["ON","AB","SK","QC","NB","NS"])
  for area in areas
    PjMax[Nuclear,area] = 300
  end

  WriteDisk(db,"EGInput/PjMax",PjMax)
end

function PolicyControl(db)
  @info "Electric_Endogenous_Capacity.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
