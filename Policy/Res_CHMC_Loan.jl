#
# Res_CHMC_Loan.jl - Process Retrofit
#
# * This policy file simulates the impact of CHMC Interest-Free Loans for Retrofits, part of the Canada Greener Homes program.
# *
# * The 2021 Federal Budget proposed $4.4 billion over 5 years, starting in 2021-2022 
# * to help up to 200,000 homeowners complete deep home retrofits through interest-free loans of up to $40,000.
# *
# * We assume that 22 000 houses per year are retrofited per year, at a cost of $40,000 each ($880 million per year)
# *
# * To calculate policy reduces energy demand from this program, a rule of three is applied with the information on the funding
# * ($880 million per year), and the assumed reduction applied in the Canada Greener Homes Grant (CGHG) policy: see Res_CGHG.txp for more information
# * The CGHG policy reduces energy demand by 16.1 PJ in 2026 in the residential sector with a funding of $583.3 million per year
# * Thus, the assumed reduction from the CHMC Interest-Free Loans for Retrofits: $880/$583.3 * 16.1PJ = 24.3PJ
# *
# * Last modified by F. Roy-Vigneault on 2021/11/02.
#
########################

using EnergyModel

module Res_CHMC_Loan

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  
  DmdSavingsTotal[year] = sum(DmdSavings[enduse,tech,ec,area] for area in areas, ec in ecs, tech in techs, enduse in enduses)

  #
  # Cumulative reduction fraction (PERReduction)
  #
  for area in areas, ec in ecs, tech in techs, enduse in enduses
    PERReduction[enduse,tech,ec,area,year] = DmdSavingsTotal[year]/DmdTotal
  end

  return
  
end

function ResPolicy(db)
  data = RControl(; db)
  (; CalDB,Input,Outpt) = data
  (; Area,Areas,ECs,Enduse,Enduses) = data
  (; Nation,Techs,Years) = data
  (; ANMap,Dmd,PER,PERReduction,PERReductionStart) = data
  (; PERRRExo,PInvExo,xInflationNation) = data
  (; Adjustment,DmdSavings,DmdSavingsAdditional,DmdSavingsStart) = data
  (; DmdSavingsTotal,Expenses,FractionRemovedAnnually,PERReductionAdditional) = data
  (; PERRemoved,PERRemovedTotal,PERRRExoTotal,PolicyCost,ReductionAdditional) = data

  CN=Select(Nation,"CN")
  areas=findall(ANMap[Areas,CN] .== 1)
  enduses=Select(Enduse,["Heat","AC"])
  years=collect(Yr(2024):Yr(2026))

  #
  # Policy results is a reduction in demand (PJ) converted to TBtu
  #
  ReductionAdditional[years] = [
  # /2024   2025   2026
     4.05    8.1   12.15
       ]
  for year in years
    ReductionAdditional[year] = ReductionAdditional[year]/1.054615
  end

  #
  # Add adjustment after first year to account for feedback
  #
  @. Adjustment=1.00
  for year in years
    Adjustment[year] = Adjustment[year-1]+0.03
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
    PERRRExo[enduse,tech,ec,area,year]=PER[enduse,tech,ec,area,year]*FractionRemovedAnnually[year]
    # PERRemoved[enduse,tech,ec,area,year]=PER[enduse,tech,ec,area,year]*FractionRemovedAdditional[year]
  end

  WriteDisk(db,"$Input/PERReduction",PERReduction)
  WriteDisk(db,"$Outpt/PERRRExo",PERRRExo)

  #
  # Program Costs
  #   
  Expenses[years] = [
  # /  2024   2025   2026
       880     880    880
       ]
  for year in years
    Expenses[year] = Expenses[year]/1e6/xInflationNation[CN,year]
  end

  #
  # Allocate Program Costs to each Enduse, Tech, EC, and Area
  #
  for year in years
    PERRemovedTotal[year]=sum(PERRRExo[enduse,tech,ec,area,year] for area in areas, ec in ECs, tech in Techs, enduse in enduses)
  end

  Heat=Select(Enduse,"Heat")
  for year in years, area in areas, ec in ECs, tech in Techs
    PInvExo[Heat,tech,ec,area,year]=PInvExo[Heat,tech,ec,area,year]+Expenses[year]*sum(PERRRExo[enduse,tech,ec,area,year]/PERRemovedTotal[year] for enduse in enduses)
  end
  WriteDisk(db,"$Input/PInvExo",PInvExo)

end

function PolicyControl(db)
  @info "Res_CHMC_Loan.jl - PolicyControl"
  ResPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
