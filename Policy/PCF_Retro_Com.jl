#
# PCF_Retro_Com.jl - Process Retrofit
#
# This policy simulates the portion of the NRCan Strategy for Energy Efficient Buildings 
# related to building retrofits in the commercial sector. It reduces energy demand by 
# 78.4 PJ in 2030 in the commercial sector, which is half of the target previously provided to us
# by NRCan. 
# The assumption is that reductions are only half because the implementation period is also cut in half. 
# Reductions are assumed to increase linearly from 2026 to 2030 to reach the target.
# It assumes that costs to achieve these reductions are $100 per GJ in 2016$ (A. Dumas 2021/11/15).
#
# Edited by Kevin Palmer-Wilson on 2022-11-22 to reflect latest energy demand reductions provided by NRCan.
# NRCan suggests that this policy reduces commercial building energy demand by 33.5 PJ in 2030
# versus a scenario without this policy.
#

using EnergyModel

module PCF_Retro_Com

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Dmd::VariableArray{4} = ReadDisk(BCNameDB,"$Outpt/Dmd",Future) # [Enduse,Tech,EC,Area,Future] Demand (TBtu/Yr)
  PER::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  PERReduction::VariableArray{5} = ReadDisk(db,"$Input/PERReduction") # Process Energy Exogenous Retrofits Percentage ((mmBtu/Yr)/(mmBtu/Yr)) [Enduse,Tech,EC,Area]
  PERReductionStart::VariableArray{4} = ReadDisk(db,"$Input/PERReduction",Zero) # [Enduse,Tech,EC,Area,Year] Fraction of Process Energy Removed from Previous Policies ((mmBtu/Yr)/(mmBtu/Yr))
  PERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/PERRRExo") # Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr) [Enduse,Tech,EC,Area]
  PInvExo::VariableArray{5} = ReadDisk(db,"$Input/PInvExo") # Process Exogenous Investments (M$/Yr) [Enduse,Tech,EC,Area]
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") #[Nation,Year]  Inflation Index ($/$)

  #
  Adjustment::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Feedback Adjustment Variable
  DmdSavings::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions after this Policy is added (TBtu/Yr)
  DmdSavingsAdditional::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions from this Policy (TBtu/Yr)
  DmdSavingsStart::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions from Previous Policies (TBtu/Yr)
  DmdSavingsTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Demand Reductions after this Policy is added (TBtu/Yr)
# DmdTotal      'Total Demand (TBtu/Yr)'
  Expenses::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Program Expenses (2015 CN$M)
  FractionRemovedAnnually::VariableArray{2} = zeros(Float32,length(EC),length(Year)) # [EC,Year] Fraction of Energy Requirements Removed (Btu/Btu)
  PERReductionAdditional::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Fraction of Process Energy Removed added by this Policy ((mmBtu/Yr)/(mmBtu/Yr))
  PERRemoved::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Policy-specific Process Energy Removed ((mmBtu/Yr)/Yr)
  PERRemovedTotal::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Policy-specific Total Process Energy Removed (mmBtu/Yr)
  PERRRExoTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Process Energy Removed (mmBtu/Yr)
  PolicyCost::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Cost ($/TBtu)
  ReductionAdditional::VariableArray{2} = zeros(Float32,length(EC),length(Year)) # [EC,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data,DmdTotal,year,enduses,techs,ecs,areas)
  (; Dmd) = data
  (; PERReduction,PERReductionStart) = data
  (; PERReductionAdditional) = data
  (; DmdSavings) = data
  (; DmdSavingsAdditional,DmdSavingsStart) = data
  (; DmdSavingsTotal) = data
  (; ReductionAdditional) = data

  #
  # Reductions from Previous Policies
  # 
  for area in areas, ec in ecs, tech in techs, enduse in enduses
    DmdSavingsStart[enduse,tech,ec,area] = Dmd[enduse,tech,ec,area]*
      PERReductionStart[enduse,tech,ec,area]
  end

  #
  # Additional demand reduction is transformed to be a fraction of total demand 
  #  
  for area in areas, ec in ecs, tech in techs, enduse in enduses
    PERReductionAdditional[enduse,tech,ec,area] = ReductionAdditional[year]/DmdTotal
  end

  #
  # Demand reductions from this Policy
  #  
  for area in areas, ec in ecs, tech in techs, enduse in enduses
    DmdSavingsAdditional[enduse,tech,ec,area] = Dmd[enduse,tech,ec,area]*
      PERReductionAdditional[enduse,tech,ec,area]
  end

  #
  # Combine reductions from previous policies with reductions from this policy
  #  
  for area in areas, ec in ecs, tech in techs, enduse in enduses
    DmdSavings[enduse,tech,ec,area] = DmdSavingsStart[enduse,tech,ec,area]+
      DmdSavingsAdditional[enduse,tech,ec,area]
  end
  
  DmdSavingsTotal[year] = sum(DmdSavings[enduse,tech,ec,area] for area in areas, ec in ecs, tech in techs, enduse in enduses);

  #
  # Cumulative reduction fraction (PERReduction)
  #
  for area in areas, ec in ecs, tech in techs, enduse in enduses
    PERReduction[enduse,tech,ec,area,year] = DmdSavingsTotal[year]/DmdTotal
  end

  return
  
end

function ComPolicy(db)
  data = CControl(; db)
  (; CalDB,Input,Outpt) = data
  (; Area,Areas,ECs,Enduse,Enduses) = data
  (; Nation,Techs,Years) = data
  (; ANMap,Dmd,PER,PERReduction,PERReductionStart) = data
  (; PERRRExo,PInvExo,xInflationNation) = data
  (; Adjustment,DmdSavings,DmdSavingsAdditional,DmdSavingsStart) = data
  (; DmdSavingsTotal,Expenses,FractionRemovedAnnually,PERReductionAdditional) = data
  (; PERRemoved,PERRemovedTotal,PERRRExoTotal,PolicyCost,ReductionAdditional) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[Areas,CN] .== 1)
  enduses = Select(Enduse,["Heat","AC"])
  years = collect(Yr(2026):Yr(2030))

  #
  # Policy results is a reduction in demand (PJ) converted to TBtu
  #
  ReductionAdditional[years] = [
  # /  2026   2027   2028   2029   2030
        6.7   13.4   20.1   26.8   33.5 
        ]
  # New vlaues added by KPW on 2022-11-22 above
  # Previous values provided by NRCan:
  #    15.7   31.3   47.0   62.7   78.4
  for year in years
    ReductionAdditional[year] = ReductionAdditional[year]/1.054615
  end

  #
  # Add adjustment after first year to account for feedback
  #
  @. Adjustment = 1.00
  years_b = collect(Yr(2027):Yr(2030))
  # Adjustment modified from 0.35 to 0.39 by KPW on 29.11.2022 to tune TXP to match energy demand reduction values provided by NRCan
  for year in years_b
    Adjustment[year] = Adjustment[year-1]+0.039
  end

  for year in years
    ReductionAdditional[year] = ReductionAdditional[year]*Adjustment[year]
  end

  DmdTotal = sum(Dmd[enduse,tech,ec,area] for area in areas, ec in ECs, tech in Techs, enduse in enduses)

  for year in years
    AllocateReduction(data,DmdTotal,year,enduses,Techs,ECs,areas)
  end

  #
  # Fraction Removed each Year
  #
  for year in years
    FractionRemovedAnnually[year] = ReductionAdditional[year]/DmdTotal-
        ReductionAdditional[year-1]/DmdTotal    
  end

  #
  # Energy Requirements Removed due to Program
  #
  for year in years, area in areas, ec in ECs, tech in Techs, enduse in enduses
    PERRRExo[enduse,tech,ec,area,year] = PER[enduse,tech,ec,area,year]*FractionRemovedAnnually[year]
    # PERRemoved[enduse,tech,ec,area,year]=PER[enduse,tech,ec,area,year]*FractionRemovedAdditional[year]
  end

  WriteDisk(db,"$Input/PERReduction",PERReduction)
  WriteDisk(db,"$Outpt/PERRRExo",PERRRExo)

  #
  # Program Costs
  #   
  Expenses[years] = [
  # / 2026   2027   2028   2029   2030
      1567.2 1567.2 1567.2 1567.2 1567.2
      ]
  for year in years
    Expenses[year] = Expenses[year]/1e6/xInflationNation[CN,year]
  end

  #
  # Allocate Program Costs to each Enduse, Tech, EC, and Area
  #
  for year in years
    PERRemovedTotal[year] = sum(PERRRExo[enduse,tech,ec,area,year] for area in areas, ec in ECs, tech in Techs, enduse in enduses)
  end

  Heat = Select(Enduse,"Heat")
  for year in years, area in areas, ec in ECs, tech in Techs
    PInvExo[Heat,tech,ec,area,year] = PInvExo[Heat,tech,ec,area,year]+Expenses[year]*sum(PERRRExo[enduse,tech,ec,area,year]/PERRemovedTotal[year] for enduse in enduses)
  end
  WriteDisk(db,"$Input/PInvExo",PInvExo)

end

function PolicyControl(db)
  @info "PCF_Retro_Com.jl - PolicyControl"
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
