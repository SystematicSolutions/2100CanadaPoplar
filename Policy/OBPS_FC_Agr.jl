#
# OBPS_FC_Agr.jl - Process Retrofit
#
# Directly inputs energy reductions for specific sectors in AB,BC, NB, ON, NB, QC, SK
# according to OBPS and fuel charge revenues estimates as provided by MDQR, modified for Ref25A_170
# to remove Canada Growth Fund, $15 billion nominal (see Ref25A_170 Funding Reductions.xlsx)
# Created by Thuo Kossa 10/29/2022
# Modified by Matt Lewis 11/06/2024
# Modified by Matt Lewis 11/26/2025, targetting 1.3 MT of reductions in 2030 across 5 OBPS policy files
# scalar assumption = 0.05

using EnergyModel

module OBPS_FC_Agr

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
  BC = Select(Area,"BC")
  MB = Select(Area,"MB")
  ON = Select(Area,"ON")
  QC = Select(Area,"QC")
  SK = Select(Area,"SK")

  #
  # AB reductions
  #
  #ReductionAdditional[AB,Yr(2024)] = 3.6
  #ReductionAdditional[AB,Yr(2025)] = 5.1
  ReductionAdditional[AB,Yr(2026)] = 6.5
  ReductionAdditional[AB,Yr(2027)] = 7.8
  ReductionAdditional[AB,Yr(2028)] = 8.2
  ReductionAdditional[AB,Yr(2029)] = 8.5
  ReductionAdditional[AB,Yr(2030)] = 8.5

  #
  # BC reductions
  #
  #ReductionAdditional[BC,Yr(2024)] = 1.0
  #ReductionAdditional[BC,Yr(2025)] = 1.3
  ReductionAdditional[BC,Yr(2026)] = 1.5
  ReductionAdditional[BC,Yr(2027)] = 1.6
  ReductionAdditional[BC,Yr(2028)] = 1.6
  ReductionAdditional[BC,Yr(2029)] = 1.5
  ReductionAdditional[BC,Yr(2030)] = 1.4

  #
  # MB reductions
  #
  #ReductionAdditional[MB,Yr(2024)] = 1.2
  #ReductionAdditional[MB,Yr(2025)] = 1.7
  ReductionAdditional[MB,Yr(2026)] = 2.2
  ReductionAdditional[MB,Yr(2027)] = 2.6
  ReductionAdditional[MB,Yr(2028)] = 2.8
  ReductionAdditional[MB,Yr(2029)] = 3.0
  ReductionAdditional[MB,Yr(2030)] = 3.1

  #
  # ON reductions
  #
  #ReductionAdditional[ON,Yr(2024)] = 3.4
  #ReductionAdditional[ON,Yr(2025)] = 4.5
  ReductionAdditional[ON,Yr(2026)] = 5.6
  ReductionAdditional[ON,Yr(2027)] = 6.5
  ReductionAdditional[ON,Yr(2028)] = 6.6
  ReductionAdditional[ON,Yr(2029)] = 6.6
  ReductionAdditional[ON,Yr(2030)] = 6.5

  #
  # QC reductions
  #
  #ReductionAdditional[QC,Yr(2024)] = 0.3
  #ReductionAdditional[QC,Yr(2025)] = 0.4
  ReductionAdditional[QC,Yr(2026)] = 0.5
  ReductionAdditional[QC,Yr(2027)] = 0.6
  ReductionAdditional[QC,Yr(2028)] = 0.6
  ReductionAdditional[QC,Yr(2029)] = 0.6
  ReductionAdditional[QC,Yr(2030)] = 0.6

  #
  # SK reductions
  #
  #ReductionAdditional[SK,Yr(2024)] = 4.9
  #ReductionAdditional[SK,Yr(2025)] = 6.9
  ReductionAdditional[SK,Yr(2026)] = 8.9
  ReductionAdditional[SK,Yr(2027)] = 10.7
  ReductionAdditional[SK,Yr(2028)] = 11.2
  ReductionAdditional[SK,Yr(2029)] = 11.7
  ReductionAdditional[SK,Yr(2030)] = 11.9

  #
  # Apply annual adjustment to reductions to compensate for 'rebound' from less retirements
  #
  years = collect(Yr(2026):Yr(2030))
  areas = Select(Area,["AB","BC","MB","ON","QC","SK"])
  
  for area in areas, year in years
    AnnualAdjustment[area,year] = AnnualAdjustment[area,year-1] + 0.35
  end

  #
  # Apply adjustment starting from 2026
  #
  for area in areas
    years = collect(Yr(2026):Yr(2030))
    for year in years
      if year >= Yr(2026)
        ReductionAdditional[area,year] = ReductionAdditional[area,year] * 0.05/KJBtu * AnnualAdjustment[area,year]
      else
        ReductionAdditional[area,year] = ReductionAdditional[area,year] * 0.05/KJBtu
      end
    end
    
    #
    # Extend to Final year
    #
    years = collect(Yr(2031):Final)
    for year in years
      ReductionAdditional[area,year] = ReductionAdditional[area,Yr(2030)]
    end
  end
   years = collect(Yr(2024):Yr(2030))

  #
  # Program Costs $M
  #
  # AB costs
  #
  #PolicyCost[AB,Yr(2025)] = 87.975
  PolicyCost[AB,Yr(2026)] = 118.575
  PolicyCost[AB,Yr(2027)] = 148.95
  PolicyCost[AB,Yr(2028)] = 162.75
  PolicyCost[AB,Yr(2029)] = 174.9
  PolicyCost[AB,Yr(2030)] = 183.75

  #
  # BC costs
  #
  #PolicyCost[BC,Yr(2025)] = 57.6
  PolicyCost[BC,Yr(2026)] = 76.5
  PolicyCost[BC,Yr(2027)] = 94.875
  PolicyCost[BC,Yr(2028)] = 103.05
  PolicyCost[BC,Yr(2029)] = 110.175
  PolicyCost[BC,Yr(2030)] = 115.2

  #
  # MB costs
  #
  #PolicyCost[MB,Yr(2025)] = 47.4
  PolicyCost[MB,Yr(2026)] = 62.925
  PolicyCost[MB,Yr(2027)] = 78.0
  PolicyCost[MB,Yr(2028)] = 84.675
  PolicyCost[MB,Yr(2029)] = 90.45
  PolicyCost[MB,Yr(2030)] = 94.5

  #
  # ON costs
  #
 # PolicyCost[ON,Yr(2025)] = 122.7
  PolicyCost[ON,Yr(2026)] = 162.6
  PolicyCost[ON,Yr(2027)] = 201.3
  PolicyCost[ON,Yr(2028)] = 218.625
  PolicyCost[ON,Yr(2029)] = 233.55
  PolicyCost[ON,Yr(2030)] = 244.2

  #
  # QC costs
  #
  #PolicyCost[QC,Yr(2025)] = 85.8
  PolicyCost[QC,Yr(2026)] = 113.4
  PolicyCost[QC,Yr(2027)] = 139.95
  PolicyCost[QC,Yr(2028)] = 151.875
  PolicyCost[QC,Yr(2029)] = 162.075
  PolicyCost[QC,Yr(2030)] = 169.35

  #
  # SK costs
  #
  #PolicyCost[SK,Yr(2025)] = 71.325
  PolicyCost[SK,Yr(2026)] = 95.7
  PolicyCost[SK,Yr(2027)] = 119.925
  PolicyCost[SK,Yr(2028)] = 131.025
  PolicyCost[SK,Yr(2029)] = 140.775
  PolicyCost[SK,Yr(2030)] = 147.825

  #
  # Adjust PolicyCost by inflation
  #
  areas = Select(Area,["AB","BC","MB","ON","QC","SK"])
  years = collect(Yr(2026):Yr(2030))
  for area in areas, year in years
    PolicyCost[area,year] = PolicyCost[area,year] * 0.05/ xInflation[area,year]
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
  # Agricultural ECs - most provinces use OnFarmFuelUse
  #
  ecs = Select(EC,"OnFarmFuelUse")
  areas = Select(Area,["AB","BC","MB","ON","SK"])
  for area in areas
    AllocateReduction(data,ecs,area,years)
  end

  #
  # QC has additional CropProduction EC
  #
  ecs = Select(EC,["OnFarmFuelUse","CropProduction"])
  areas = Select(Area,"QC")
  AllocateReduction(data,ecs,areas,years)

  #@info "OBPS_FC_Agr.jl - PolicyControl completed"
end

function PolicyControl(db)
  @info "OBPS_FC_Agr.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end