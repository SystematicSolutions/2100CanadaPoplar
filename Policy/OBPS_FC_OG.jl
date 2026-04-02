#
# OBPS_FC_OG.jl - Process Retrofit
#
# Directly inputs energy reductions for specific sectors in AB,BC, NB, ON, NB, QC, SK
# according to OBPS and fuel charge revenues estimates as provided by MDQR, modified for Ref25A_170
# to remove Canada Growth Fund, $15 billion nominal (see Ref25A_170 Funding Reductions.xlsx)
# Created by Thuo Kossa 10/29/2022
# Modified by Matt Lewis 11/06/2024
# Modified by Matt Lewis 11/26/2025, targetting 1.3 MT of reductions in 2030 across 5 OBPS policy files
# scalar assumption = 0.05

using EnergyModel

module OBPS_FC_OG

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: DB
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

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
  DEEARef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DmdRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  PERRef::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  PERReduction::VariableArray{5} = ReadDisk(db,"$Input/PERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Process Energy Removed after this Policy is added ((mmBtu/Yr)/(mmBtu/Yr))
  PERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  PInvExo::VariableArray{5} = ReadDisk(db,"$Input/PInvExo") # [Enduse,Tech,EC,Area,Year] Process Exogenous Investments (M$/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  AnnualAdjustment::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Adjustment for energy savings rebound
  DmdFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  DmdTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Demand (TBtu/Yr)
  Expenses::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Program Expenses (2015 CN$M)
  FractionRemovedAnnually::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Fraction of Energy Requirements Removed (Btu/Btu)
  PolicyCost::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Policy Cost ($/TBtu)
  ReductionAdditional::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
  ReductionTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data,ecs,areas,years)
  (; db,Input,Outpt) = data
  (; Area,EC,Enduse,Tech,Techs) = data
  (; DmdRef,DmdTotal,DmdFrac,FractionRemovedAnnually) = data
  (; PERRef,PERRRExo,PInvExo,PolicyCost) = data
  (; ReductionAdditional,ReductionTotal) = data

  KJBtu = 1.054615
  heat = Select(Enduse,"Heat")

  #
  # Filter out Electric, Steam, and Biomass techs
  #
  techs1 = Select(Tech,!=("Electric"))
  techs2 = Select(Tech,!=("Steam"))
  techs3 = Select(Tech,!=("Biomass"))
  techs = intersect(techs1,techs2,techs3)

  #
  # Total Demands
  #
  for area in areas, year in years
    DmdTotal[area,year] = 
      sum(DmdRef[heat,tech,ec,area,year] for tech in techs, ec in ecs)
  end

  #
  # Accumulate ReductionAdditional and apply to reference case demands
  #
  for area in areas, year in years
    ReductionAdditional[area,year] = max((ReductionAdditional[area,year] - 
      ReductionTotal[area,year-1]),0.0)
    ReductionTotal[area,year] = ReductionAdditional[area,year] + 
      ReductionTotal[area,year-1]
  end

  #
  # Fraction Energy Removed each Year
  #
  for area in areas, year in years
    @finite_math FractionRemovedAnnually[area,year] = ReductionAdditional[area,year] / 
      DmdTotal[area,year]
  end
  #println("Area is ", Area[areas])
  #println("EC is ", EC[ecs])
  #println("ReductionAdditional in 2025 is", ReductionAdditional[areas,Yr(2025)])
  #println("DmdTotal in 2025 is", DmdTotal[areas,Yr(2025)])

  #
  # Energy Requirements Removed due to Program
  #
  for tech in techs, ec in ecs, area in areas, year in years
    PERRRExo[heat,tech,ec,area,year] = PERRRExo[heat,tech,ec,area,year] + 
      PERRef[heat,tech,ec,area,year] * FractionRemovedAnnually[area,year]
  end
  #println("FractionRemovedAnnually in 2025 is", FractionRemovedAnnually[areas,Yr(2025)])
  # println("PERRRExo in 2025 is", PERRRExo[heat,areas,Yr(2025)])
  # println("PERRef in 2025 is", PERRef[areas,Yr(2025)])

  #
  # Split out PolicyCost using reference Dmd values. PInv only uses Process Heat.
  #
  for area in areas, year in years
    DmdTotal[area,year] = sum(DmdRef[heat,tech,ec,area,year] 
      for tech in techs, ec in ecs)
  end

  for tech in techs, ec in ecs, area in areas, year in years
    @finite_math DmdFrac[heat,tech,ec,area,year] = DmdRef[heat,tech,ec,area,year] / 
      DmdTotal[area,year]
  end

  for tech in techs, ec in ecs, area in areas, year in years
    PInvExo[heat,tech,ec,area,year] = PInvExo[heat,tech,ec,area,year] + 
      PolicyCost[area,year] * DmdFrac[heat,tech,ec,area,year]
  end

  WriteDisk(db,"$Outpt/PERRRExo",PERRRExo)
  WriteDisk(db,"$Input/PInvExo",PInvExo)
end

function IndPolicy(db::String)
  data = IControl(; db)
  (; Area,AreaDS,EC,Enduse,Nation,Tech,Year) = data 
  (; Areas,Years,ECs,Enduses,Techs) = data
  (; ANMap,AnnualAdjustment,PolicyCost,ReductionAdditional,xInflation) = data

  KJBtu = 1.054615

  #
  # Initialize AnnualAdjustment
  #
  @. AnnualAdjustment = 1.0

  #
  # Select Sets for Policy
  #
  nation = Select(Nation,"CN")

  #
  # Provincial PJ reductions by fuel share converted to TBtu
  #
  AB = Select(Area,"AB")
  NB = Select(Area,"NB") 
  ON = Select(Area,"ON")
  QC = Select(Area,"QC")
  SK = Select(Area,"SK")

  #
  # AB reductions
  #
  #ReductionAdditional[AB,Yr(2025)] = 44.4
  ReductionAdditional[AB,Yr(2026)] = 75.4
  ReductionAdditional[AB,Yr(2027)] = 106.4
  ReductionAdditional[AB,Yr(2028)] = 135.5
  ReductionAdditional[AB,Yr(2029)] = 167.8
  ReductionAdditional[AB,Yr(2030)] = 178.9

  #
  # NB reductions
  #
  #ReductionAdditional[NB,Yr(2025)] = 3.7
  ReductionAdditional[NB,Yr(2026)] = 4.7
  ReductionAdditional[NB,Yr(2027)] = 5.8
  ReductionAdditional[NB,Yr(2028)] = 6.3
  ReductionAdditional[NB,Yr(2029)] = 6.7
  ReductionAdditional[NB,Yr(2030)] = 7.0

  #
  # ON reductions
  #
  #ReductionAdditional[ON,Yr(2025)] = 4.0
  ReductionAdditional[ON,Yr(2026)] = 5.2
  ReductionAdditional[ON,Yr(2027)] = 6.3
  ReductionAdditional[ON,Yr(2028)] = 6.9
  ReductionAdditional[ON,Yr(2029)] = 7.3
  ReductionAdditional[ON,Yr(2030)] = 7.7

  #
  # QC reductions
  #
  #ReductionAdditional[QC,Yr(2025)] = 2.5
  ReductionAdditional[QC,Yr(2026)] = 3.3
  ReductionAdditional[QC,Yr(2027)] = 4.0
  ReductionAdditional[QC,Yr(2028)] = 4.3
  ReductionAdditional[QC,Yr(2029)] = 4.6
  ReductionAdditional[QC,Yr(2030)] = 4.8

  #
  # SK reductions
  #
  #ReductionAdditional[SK,Yr(2025)] = 1.0
  ReductionAdditional[SK,Yr(2026)] = 1.3
  ReductionAdditional[SK,Yr(2027)] = 1.6
  ReductionAdditional[SK,Yr(2028)] = 1.7
  ReductionAdditional[SK,Yr(2029)] = 1.8
  ReductionAdditional[SK,Yr(2030)] = 1.9

  #
  # Apply annual adjustment to reductions to compensate for 'rebound' from less retirements
  #
  years = collect(Yr(2026):Yr(2030))
  areas = Select(Area,["AB","NB","ON","QC","SK"])
  
  for area in areas, year in years
    AnnualAdjustment[area,year] = AnnualAdjustment[area,year-1] + 0.14
  end

  for area in areas
    for year in years
      ReductionAdditional[area,year] = ReductionAdditional[area,year] * 0.05/KJBtu * AnnualAdjustment[area,year]
    end
    
    #
    # Extend to Final year
    #
    for year in collect(Yr(2031):Final)
      ReductionAdditional[area,year] = ReductionAdditional[area,Yr(2030)]
    end
  end

  #
  # Program Costs $M
  #
  # AB costs
  #
  #PolicyCost[AB,Yr(2025)] = 1166.1
  PolicyCost[AB,Yr(2026)] = 1512.525
  PolicyCost[AB,Yr(2027)] = 1831.65
  PolicyCost[AB,Yr(2028)] = 1970.475
  PolicyCost[AB,Yr(2029)] = 2083.725
  PolicyCost[AB,Yr(2030)] = 2160.9

  #
  # NB costs
  #
  #PolicyCost[NB,Yr(2025)] = 28.05
  PolicyCost[NB,Yr(2026)] = 36.3
  PolicyCost[NB,Yr(2027)] = 43.875
  PolicyCost[NB,Yr(2028)] = 47.175
  PolicyCost[NB,Yr(2029)] = 49.875
  PolicyCost[NB,Yr(2030)] = 51.675

  #
  # ON costs
  #
  #PolicyCost[ON,Yr(2025)] = 8.475
  PolicyCost[ON,Yr(2026)] = 11.025
  PolicyCost[ON,Yr(2027)] = 13.35
  PolicyCost[ON,Yr(2028)] = 14.4
  PolicyCost[ON,Yr(2029)] = 15.225
  PolicyCost[ON,Yr(2030)] = 15.75

  #
  # QC costs
  #
  #PolicyCost[QC,Yr(2025)] = 112.575
  PolicyCost[QC,Yr(2026)] = 144.9
  PolicyCost[QC,Yr(2027)] = 174.675
  PolicyCost[QC,Yr(2028)] = 187.65
  PolicyCost[QC,Yr(2029)] = 198.225
  PolicyCost[QC,Yr(2030)] = 205.275

  #
  # SK costs
  #
  #PolicyCost[SK,Yr(2025)] = 35.7
  PolicyCost[SK,Yr(2026)] = 45.675
  PolicyCost[SK,Yr(2027)] = 54.675
  PolicyCost[SK,Yr(2028)] = 58.575
  PolicyCost[SK,Yr(2029)] = 61.725
  PolicyCost[SK,Yr(2030)] = 63.9

  #
  # Adjust PolicyCost by inflation
  #
  areas = Select(Area,["AB","NB","ON","QC","SK"])
  for area in areas, year in years
    PolicyCost[area,year] = PolicyCost[area,year] * 0.05 / xInflation[area,year]
  end

  #
  # Extend costs to Final year
  #
  years = collect(Yr(2031):Final)
  for area in areas, year in years
    PolicyCost[area,year] = PolicyCost[area,Yr(2030)]
  end

  #
  # Apply AllocateReduction for different area/EC combinations
  #
  years = collect(Yr(2026):Final)

  #
  # AB with multiple ECs
  #
  areas = Select(Area,"AB")
  ecs = Select(EC,["CSSOilSands","LightOilMining","OilSandsMining","OilSandsUpgraders","SAGDOilSands","Petroleum"])
  AllocateReduction(data,ecs,areas,years)

  #
  # Other provinces with Petroleum EC
  #
  ecs = Select(EC,"Petroleum")
  areas = Select(Area,["NB","ON","QC"])
  for area in areas
    AllocateReduction(data,ecs,area,years)
  end

  #
  # SK with OilSandsUpgraders
  #
  ecs = Select(EC,"OilSandsUpgraders")
  areas = Select(Area,"SK")
  AllocateReduction(data,ecs,areas,years)

  #@info "OBPS_FC_OG.jl - PolicyControl completed"
end

function PolicyControl(db)
  @info "OBPS_FC_OG.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
