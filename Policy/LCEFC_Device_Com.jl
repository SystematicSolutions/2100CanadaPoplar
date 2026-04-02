#
# LCEFC_Device_Com.jl - Low Carbon Economy Challenge Fund - Device Retrofits in commercial buildings 
#
# Details about the underlying assumptions for this policy are available in the following file:
# \\ncr.int.ec.gc.ca\shares\e\ECOMOD\Documentation\Policy - Buildings Policies.docx.
#
# Last updated by Kevin Palmer-Wilson on 2023-06-09
#

using EnergyModel

module LCEFC_Device_Com

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  Dmd::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  DER::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DER") # [Enduse,Tech,EC,Area,Year] Device Energy Requirement (mmBtu/Yr)
  DERReduction::VariableArray{5} = ReadDisk(db,"$Input/DERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Device Energy Removed after this Policy is added ((mmBtu/Yr)/(mmBtu/Yr))
  DERReductionStart::VariableArray{5} = ReadDisk(db,"$Input/DERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Device Energy Removed from Previous Policies ((mmBtu/Yr)/(mmBtu/Yr))
  DERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/DERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  DInvTechExo::VariableArray{5} = ReadDisk(db,"$Input/DInvTechExo") # [Enduse,Tech,EC,Area,Year] Device Exogenous Investments (M$/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  Adjustment::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Feedback Adjustment Variable
  DERRRExoTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Process Energy Removed (mmBtu/Yr)
  DERReductionAdditional::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Fraction of Device Energy Removed added by this Policy ((mmBtu/Yr)/(mmBtu/Yr))
  DERRemoved::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Device Energy Removed ((mmBtu/Yr)/Yr)
  DERRemovedTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Device Energy Removed (mmBtu/Yr)
  DmdSavings::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions after this Policy is added (TBtu/Yr)
  DmdSavingsAdditional::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions from this Policy (TBtu/Yr)
  DmdSavingsStart::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions from Previous Policies (TBtu/Yr)
  DmdSavingsTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Demand Reductions after this Policy is added (TBtu/Yr)
  DmdTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Demand (TBtu/Yr)
  Expenses::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Program Expenses (2015 CN$M)
  FractionRemovedAnnually::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Fraction of Energy Requirements Removed (Btu/Btu)
  PolicyCost::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Cost ($/TBtu)
  ReductionAdditional::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data::CControl,enduses,techs,ecs,areas,year)
  (; DERReduction,DERReductionAdditional) = data
  (; DERReductionStart) = data
  (; Dmd,DmdSavings,DmdSavingsAdditional) = data
  (; DmdSavingsStart,DmdSavingsTotal,DmdTotal) = data
  (; ReductionAdditional) = data
 
  
  KJBtu = 1.054615

  #
  # Total Demands
  #  
  DmdTotal[year] =
    sum(Dmd[enduse,tech,ec,area,year] for enduse in enduses,tech in techs,ec in ecs,area in areas)
  
  #
  # Reductions from Previous Policies
  #  
  for enduse in enduses, tech in techs, ec in ecs, area in areas
    DmdSavingsStart[enduse,tech,ec,area] = Dmd[enduse,tech,ec,area,year]*
      DERReductionStart[enduse,tech,ec,area,year]
  end
    
  #
  # Additional demand reduction is transformed to be a fraction of total demand s
  #  
  for enduse in enduses, tech in techs, ec in ecs, area in areas
    @finite_math  DERReductionAdditional[enduse,tech,ec,area] = 
      ReductionAdditional[year]/DmdTotal[year]
  end
  
  #
  # Demand reductions from this Policy
  #  
  for enduse in enduses, tech in techs, ec in ecs, area in areas
    DmdSavingsAdditional[enduse,tech,ec,area] = Dmd[enduse,tech,ec,area,year]*
      DERReductionAdditional[enduse,tech,ec,area]
  end
  
  #
  # Combine reductions from previous policies with reductions from this policy
  # 
  for enduse in enduses,tech in techs,ec in ecs,area in areas
    DmdSavings[enduse,tech,ec,area] = DmdSavingsStart[enduse,tech,ec,area]+
      DmdSavingsAdditional[enduse,tech,ec,area]
  end
  
  DmdSavingsTotal[year] = 
    sum(DmdSavings[enduse,tech,ec,area] for enduse in enduses,tech in techs,ec in ecs,area in areas)

  #
  # Cumulative reduction fraction (DERReduction)
  #  
  for enduse in enduses, tech in techs, ec in ecs, area in areas
    @finite_math DERReduction[enduse,tech,ec,area,year] = 
      DmdSavings[enduse,tech,ec,area]/DmdTotal[year]
  end  

end

function ComPolicy(db)
  data = CControl(; db)
  (; Input,Outpt) = data
  (; ECs,Enduses,Nation,Techs) = data  
  (; Adjustment,ANMap,DER,DERReduction) = data
  (; DERRRExo,DERRRExoTotal,DInvTechExo,DmdTotal,Expenses) = data
  (; FractionRemovedAnnually,ReductionAdditional) = data
  (; xInflation) = data

  KJBtu = 1.054615

  #
  # Select Canada Areas
  #  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  years = collect(Yr(2022):Yr(2040))
  
  #
  # Policy results is a reduction in demand (PJ) converted to TBtu
  #
 
  ReductionAdditional[years] = [
    # 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035 2036 2037 2038 2039 2040
      3.5  3.9  4.1  4.7  4.7  4.8  4.9  4.9  5.1  5.8  5.9  6.0  6.0  6.0  6.0  6.0  6.0  6.0  6.0]
 
  for year in years 
    ReductionAdditional[year] = ReductionAdditional[year] / KJBtu
  end
  
  #
  # Add adjustment after first year to account for feedback
  #
  
  Adjustment[years] = [
    # 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035 2036 2037 2038 2039 2040
      1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00 2.10 2.23 2.36 2.49 2.62 2.75 2.88 3.01 3.14 3.27 3.40]
  
  for year in years
    ReductionAdditional[year] = ReductionAdditional[year] * Adjustment[year]
  end
  
  for year in years, area in areas, ec in ECs, tech in Techs, enduse in Enduses
    AllocateReduction(data,enduse,tech,ec,area,year)
  end

  #
  # Fraction Removed each Year
  #  
  for year in years
    @finite_math FractionRemovedAnnually[year] = 
      ReductionAdditional[year]/DmdTotal[year]-
        ReductionAdditional[year-1]/DmdTotal[year-1]
  end
  
  years = collect(Yr(2022):Yr(2040))
  
  #
  # Energy Requirements Removed due to Program
  #  
  for enduse in Enduses, tech in Techs, ec in ECs, area in areas, year in years
    DERRRExo[enduse,tech,ec,area,year] = DER[enduse,tech,ec,area,year]*
      FractionRemovedAnnually[year]
  end
  
  WriteDisk(db,"$Input/DERReduction",DERReduction)
  WriteDisk(db,"$Outpt/DERRRExo",DERRRExo)

  # *
  # * Program Costs
  # *   
  
  Expenses[Yr(2022)] = 371

  # *
  # * Allocate Program Costs to each Enduse, Tech, EC, and Area
  # *
  
  DERRRExoTotal[Yr(2022)] = 
    sum(DERRRExo[enduse,tech,ec,area,Yr(2022)] for enduse in Enduses,tech in Techs,ec in ECs,area in areas)
  
  for enduse in Enduses, tech in Techs, ec in ECs, area in areas
    @finite_math  DInvTechExo[enduse,tech,ec,area,Yr(2022)] = 
      DInvTechExo[enduse,tech,ec,area,Yr(2022)]+Expenses[Yr(2022)]/
        xInflation[area,Yr(2018)]*(DERRRExo[enduse,tech,ec,area,Yr(2022)]/
          DERRRExoTotal[Yr(2022)])
  end
  
  WriteDisk(db,"$Input/DInvTechExo",DInvTechExo)
end

function PolicyControl(db)
  @info "LCEFC_Device_Com.jl - PolicyControl"
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
