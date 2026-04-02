#
# OBPS_FC_Ind.jl - Process Retrofit
#
# Directly inputs energy reductions for specific sectors in AB,BC, NB, ON, NB, QC, SK
# according to OBPS and fuel charge revenues estimates as provided by MDQR, modified for Ref25A_170
# to remove Canada Growth Fund, $15 billion nominal (see Ref25A_170 Funding Reductions.xlsx)
# Created by Thuo Kossa 10/29/2022
# Modified by Matt Lewis 11/06/2024
# Modified by Matt Lewis 11/26/2025, targetting 1.3 MT of reductions in 2030 across 5 OBPS policy files
# scalar assumption = 0.05

using EnergyModel

module OBPS_FC_Ind

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
  (; Area,EC,Enduse,Tech,Techs,DmdRef,DmdTotal) = data
  (; PERRef,PERRRExo,PInvExo,PolicyCost) = data
  (; DmdFrac,FractionRemovedAnnually) = data
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

  #
  # Energy Requirements Removed due to Program
  #
  for tech in techs, ec in ecs, area in areas, year in years
    PERRRExo[heat,tech,ec,area,year] = PERRRExo[heat,tech,ec,area,year] + 
      PERRef[heat,tech,ec,area,year] * FractionRemovedAnnually[area,year]
  end

  #
  # Split out PolicyCost using reference Dmd values. PInv only uses Process Heat.
  #
  for area in areas, year in years
    DmdTotal[area,year] = sum(DmdRef[heat,tech,ec,area,year] for tech in techs, ec in ecs)
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
  ON = Select(Area,"ON")
  QC = Select(Area,"QC")
  SK = Select(Area,"SK")

  #
  # AB reductions
  #
  #ReductionAdditional[AB,Yr(2024)] = 5.5
  #ReductionAdditional[AB,Yr(2025)] = 7.8
  ReductionAdditional[AB,Yr(2026)] = 9.9
  ReductionAdditional[AB,Yr(2027)] = 11.8
  ReductionAdditional[AB,Yr(2028)] = 12.1
  ReductionAdditional[AB,Yr(2029)] = 12.3
  ReductionAdditional[AB,Yr(2030)] = 12.5

  #
  # ON reductions
  #
  #ReductionAdditional[ON,Yr(2024)] = 3.3
  #ReductionAdditional[ON,Yr(2025)] = 4.6
  ReductionAdditional[ON,Yr(2026)] = 5.8
  ReductionAdditional[ON,Yr(2027)] = 6.8
  ReductionAdditional[ON,Yr(2028)] = 7.0
  ReductionAdditional[ON,Yr(2029)] = 7.1
  ReductionAdditional[ON,Yr(2030)] = 7.1

  #
  # QC reductions
  #
  #ReductionAdditional[QC,Yr(2024)] = 4.4
  #ReductionAdditional[QC,Yr(2025)] = 6.3
  ReductionAdditional[QC,Yr(2026)] = 7.9
  ReductionAdditional[QC,Yr(2027)] = 9.5
  ReductionAdditional[QC,Yr(2028)] = 10.0
  ReductionAdditional[QC,Yr(2029)] = 10.4
  ReductionAdditional[QC,Yr(2030)] = 10.5

  #
  # SK reductions
  #
  #ReductionAdditional[SK,Yr(2024)] = 3.9
  #ReductionAdditional[SK,Yr(2025)] = 5.4
  ReductionAdditional[SK,Yr(2026)] = 6.8
  ReductionAdditional[SK,Yr(2027)] = 7.9
  ReductionAdditional[SK,Yr(2028)] = 8.1
  ReductionAdditional[SK,Yr(2029)] = 8.1
  ReductionAdditional[SK,Yr(2030)] = 8.0

  #
  # Apply annual adjustment to reductions to compensate for 'rebound' from less retirements
  #
  years = collect(Yr(2026):Yr(2030))
  areas = Select(Area,["AB","ON","QC","SK"])
  
  for area in areas, year in years
    AnnualAdjustment[area,year] = AnnualAdjustment[area,year-1] + 0.35
  end

  #
  # Apply adjustment starting from 2025 (including 2024 data)
  #
  years = collect(Yr(2026):Yr(2030))
  for area in areas
    for year in years
      if year >= Yr(2026)
        ReductionAdditional[area,year] = ReductionAdditional[area,year] * 0.05/KJBtu * AnnualAdjustment[area,year]
      else
        ReductionAdditional[area,year] = ReductionAdditional[area,year] * 0.05/KJBtu
      end
    end
    
    # Extend to Final year
    for year in collect(Yr(2031):Final)
      ReductionAdditional[area,year] = ReductionAdditional[area,Yr(2030)]
    end
  end

  #
  # Program Costs $M
  #
  # AB costs
  #
  #PolicyCost[AB,Yr(2024)] = 55.575
  #PolicyCost[AB,Yr(2025)] = 82.35
  PolicyCost[AB,Yr(2026)] = 110.85
  PolicyCost[AB,Yr(2027)] = 138.825
  PolicyCost[AB,Yr(2028)] = 151.725
  PolicyCost[AB,Yr(2029)] = 162.9
  PolicyCost[AB,Yr(2030)] = 171.075

  #
  # ON costs
  #
  #PolicyCost[ON,Yr(2024)] = 161.775
  #PolicyCost[ON,Yr(2025)] = 234.75
  PolicyCost[ON,Yr(2026)] = 310.725
  PolicyCost[ON,Yr(2027)] = 384.075
  PolicyCost[ON,Yr(2028)] = 417.45
  PolicyCost[ON,Yr(2029)] = 445.95
  PolicyCost[ON,Yr(2030)] = 466.125

  #
  # QC costs
  #
  #PolicyCost[QC,Yr(2024)] = 113.7
  #PolicyCost[QC,Yr(2025)] = 163.65
  PolicyCost[QC,Yr(2026)] = 216.075
  PolicyCost[QC,Yr(2027)] = 266.475
  PolicyCost[QC,Yr(2028)] = 289.35
  PolicyCost[QC,Yr(2029)] = 309.0
  PolicyCost[QC,Yr(2030)] = 322.95

  #
  # SK costs
  #
  #PolicyCost[SK,Yr(2024)] = 47.85
  #PolicyCost[SK,Yr(2025)] = 70.35
  PolicyCost[SK,Yr(2026)] = 93.9
  PolicyCost[SK,Yr(2027)] = 116.85
  PolicyCost[SK,Yr(2028)] = 127.425
  PolicyCost[SK,Yr(2029)] = 136.65
  PolicyCost[SK,Yr(2030)] = 143.25

  #
  # Adjust PolicyCost by inflation
  #
  years = collect(Yr(2026):Yr(2030))
  for area in areas, year in years
    if year >= Yr(2026)
      PolicyCost[area,year] = PolicyCost[area,year] * 0.05 / xInflation[area,year]
    end
  end

  #
  # Extend costs to Final year
  #
  for area in areas, year in collect(Yr(2031):Final)
    PolicyCost[area,year] = PolicyCost[area,Yr(2030)]
  end

  #
  # Apply AllocateReduction for different area/EC combinations
  #
  years = collect(Yr(2026):Final)

  #
  # AB industrial ECs
  #
  ecs = Select(EC,["OtherChemicals","Cement","IronSteel"])
  areas = Select(Area,"AB")
  AllocateReduction(data,ecs,areas,years)

  #
  # ON industrial ECs
  #
  ecs = Select(EC,["OtherChemicals","Cement","IronSteel","OtherMetalMining","NonMetalMining"])
  areas = Select(Area,"ON")
  AllocateReduction(data,ecs,areas,years)

  #
  # QC industrial ECs
  #
  ecs = Select(EC,["Cement","IronSteel","OtherNonferrous","IronOreMining","OtherMetalMining","NonMetalMining"])
  areas = Select(Area,"QC")
  AllocateReduction(data,ecs,areas,years)

  #
  # SK industrial ECs
  #
  ecs = Select(EC,["Cement","IronSteel","OtherMetalMining","NonMetalMining"])
  areas = Select(Area,"SK")
  AllocateReduction(data,ecs,areas,years)

  #@info "OBPS_FC_Ind.jl - PolicyControl completed"
end

function PolicyControl(db)
  @info "OBPS_FC_Ind.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end