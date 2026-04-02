#
# Hg_Com.jl - Mercury regs in commercial buildings 
# Details about the underlying assumptions for this policy are available in the following file:
# \\ncr.int.ec.gc.ca\shares\e\ECOMOD\Documentation\Policy - Buildings Policies.docx.
#
# Last updated by Yang Li on 2025-08-12
#

using EnergyModel

module Hg_Com

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: DB
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

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
  DERReduction::VariableArray{5} = ReadDisk(db,"$Input/DERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Device Energy Removed after this Policy is added ((mmBtu/Yr)/(mmBtu/Yr))
  DERRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DER") # [Enduse,Tech,EC,Area,Year] Device Energy Requirement (mmBtu/Yr)
  DERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/DERRRExo") # [Enduse,Tech,EC,Area,Year] Device Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  DInvTechExo::VariableArray{5} = ReadDisk(db,"$Input/DInvTechExo") # [Enduse,Tech,EC,Area,Year] Device Exogenous Investments (M$/Yr)
  DmdRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  AnnualAdjustment::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Adjustment for energy savings rebound
  CCC::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Variable for Displaying Outputs
  DDD::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Variable for Displaying Outputs
  DmdFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Device Energy Requirement (mmBtu/Yr)
  DmdTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Demand (TBtu/Yr)
  Expenses::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Program Expenses (2015 CN$M)
  FractionRemovedAnnually::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Fraction of Energy Requirements Removed (Btu/Btu)
  PolicyCost::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Policy Cost ($/TBtu)
  ReductionAdditional::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
  ReductionTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data::CControl,enduses,techs,ecs,areas,years)
  (; Outpt) = data
  (; db) = data
  (; ANMap,DERRef) = data
  (; DERRRExo,DmdRef) = data
  (; DmdTotal,FractionRemovedAnnually) = data
  (; ReductionAdditional,ReductionTotal) = data

  KJBtu = 1.054615

  #
  # Total Demands
  #  
  for year in years
    DmdTotal[year] = sum(DmdRef[enduse,tech,ec,area,year] 
      for area in areas, enduse in enduses, tech in techs, ec in ecs)
  end

  #
  # Accumulate ReductionAdditional and apply to base case demands
  #  
  for year in years
    ReductionAdditional[year] = max((ReductionAdditional[year] - 
        ReductionTotal[year-1]),0.0)
    ReductionTotal[year] = ReductionAdditional[year] + 
        ReductionTotal[year-1]
  end

  #
  # Fraction Removed each Year
  #  
  for year in years
    @finite_math FractionRemovedAnnually[year] = ReductionAdditional[year] / 
        DmdTotal[year]
  end
   
  #
  # Energy Requirements Removed due to Program
  #  
  for year in years, area in areas, ec in ecs, tech in techs, enduse in enduses
    DERRRExo[enduse,tech,ec,area,year] = DERRRExo[enduse,tech,ec,area,year] + 
      DERRef[enduse,tech,ec,area,year] * FractionRemovedAnnually[year]
  end

  WriteDisk(db,"$Outpt/DERRRExo",DERRRExo)
end

function ComPolicyHg(db::String)
  data = CControl(; db)
  (; Input) = data
  (; Area,ECs,Enduse,Tech) = data
  (; Nation,Tech) = data
  (; ANMap,AnnualAdjustment) = data
  (; DInvTechExo,DmdFrac,DmdRef,DmdTotal) = data
  (; PolicyCost,ReductionAdditional,xInflation) = data

  KJBtu = 1.054615

  #
  # Select Policy Sets (Enduse,Tech,EC)
  #  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  enduses = Select(Enduse,"Light")
  techs = Select(Tech,"Electric")
  #
  # Reductions in demand read in PJ and converted to TBtu
  #
  years = collect(Yr(2026):Yr(2050))

  #
  # PJ Reductions in end-use sectors
  #
  ReductionAdditional[years] = [
  # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
    2.1     4.1     6.7     9.1    11.2    13.2    15.0    14.5    14.0    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5    12.5
  ]
    
  #
  # Apply an annual adjustment to reductions to compensate for 'rebound' from less retirements
  #
  AnnualAdjustment[years] = [
  # 2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
    1.0     1.1     1.1     1.2     1.3     1.4     1.5     1.7     1.9     2.2     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0     1.0        
  ]
  
  #
  # Convert from PJ to TBtu
  #  
  for year in years
    ReductionAdditional[year] = ReductionAdditional[year]/
      KJBtu*AnnualAdjustment[year]
  end
  
  AllocateReduction(data,enduses,techs,ECs,areas,years)

end  #function ComPolicyHg

function PolicyControl(db)
  @info "Hg_Com.jl - PolicyControl"
  ComPolicyHg(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
