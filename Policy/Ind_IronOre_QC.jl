#
# Ind_IronOre_QC.txp - Device Retrofit
# Designed to simulate the introduction of pyrolytic oil into Iron-Ore Mining facilities
# owned by ArcelorMittal in Quebec. Pyrolytic oil (bio-crude) does not exist in E2020 so
# the policy is simulated through a reduction in HFO consumption rather than fuel substitution.
# Funding for the conversions is being negotiated under SIF-NZA.
# This txp should be updated as more information becomes available
# (i.e. no funding agreement is reached) or if pyrolytic oil is introduced into E2020
#

using EnergyModel

module Ind_IronOre_QC

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: DB
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float64,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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
  DEEARef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DmdRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  DERRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DER") # [Enduse,Tech,EC,Area,Year] Device Energy Requirement (mmBtu/Yr)
  DERReduction::VariableArray{5} = ReadDisk(db,"$Input/DERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Device Energy Removed after this Policy is added ((mmBtu/Yr)/(mmBtu/Yr))
  DERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/DERRRExo") # [Enduse,Tech,EC,Area,Year] Device Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  DInvTechExo::VariableArray{5} = ReadDisk(db,"$Input/DInvTechExo") # [Enduse,Tech,EC,Area,Year] Device Exogenous Investments (M$/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  AnnualAdjustment::VariableArray{2} = zeros(Float64,length(EC),length(Year)) # [EC,Year] Adjustment for energy savings rebound
  CCC::VariableArray{2} = zeros(Float64,length(Area),length(Year)) # [Area,Year] Variable for Displaying Outputs
  DDD::VariableArray{2} = zeros(Float64,length(Area),length(Year)) # [Area,Year] Variable for Displaying Outputs
  DmdFrac::VariableArray{5} = zeros(Float64,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  DmdTotal::VariableArray{2} = zeros(Float64,length(EC),length(Year)) # [EC,Year] Total Demand (TBtu/Yr)
  Expenses::VariableArray{1} = zeros(Float64,length(Year)) # [Year] Program Expenses (2015 CN$M)
  FractionRemovedAnnually::VariableArray{2} = zeros(Float64,length(EC),length(Year)) # [EC,Year] Fraction of Energy Requirements Removed (Btu/Btu)
  PolicyCost::VariableArray{2} = zeros(Float64,length(EC),length(Year)) # [EC,Year] Total Policy Cost ($/TBtu)
  PolicyCostYr::VariableArray{2} = zeros(Float64,length(EC),length(Year)) # [EC,Year] Annual Policy Cost ($/TBtu)
  ReductionAdditional::VariableArray{2} = zeros(Float64,length(EC),length(Year)) # [EC,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
  ReductionTotal::VariableArray{2} = zeros(Float64,length(EC),length(Year)) # [EC,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data::IControl,enduses,techs,ecs,areas,years)
  (; db,Outpt) = data
  (; DmdRef,DmdTotal) = data
  (; DERRef,DERRRExo) = data
  (; FractionRemovedAnnually) = data
  (; ReductionAdditional,ReductionTotal) = data

  KJBtu = 1.054615

  #
  # Total Demands
  #  
  for ec in ecs, year in years
    DmdTotal[ec,year] = 
      sum(DmdRef[enduse,tech,ec,area,year] for enduse in enduses,tech in techs,area in areas)
  end

  #
  # Accumulate ReductionAdditional and apply to reference case demands
  #  
  for ec in ecs, year in years
    ReductionAdditional[ec,year] = max((ReductionAdditional[ec,year] - 
      ReductionTotal[ec,year-1]),0.0)
    ReductionTotal[ec,year] = ReductionAdditional[ec,year] + 
      ReductionTotal[ec,year-1]
  end

  #
  #Fraction Removed each Year
  #  
  for ec in ecs, year in years
    @finite_math FractionRemovedAnnually[ec,year] = ReductionAdditional[ec,year] / 
      DmdTotal[ec,year]
  end

  #
  #Energy Requirements Removed due to Program
  #  
  for enduse in enduses, tech in techs, ec in ecs, area in areas, year in years
    DERRRExo[enduse,tech,ec,area,year] = DERRRExo[enduse,tech,ec,area,year] + 
      DERRef[enduse,tech,ec,area,year] * FractionRemovedAnnually[ec,year]
  end

  WriteDisk(db,"$Outpt/DERRRExo",DERRRExo)
end

function IndPolicy(db::String)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Enduses) = data 
  (; Nation,Tech) = data
  (; AnnualAdjustment) = data
  (; DInvTechExo,DmdFrac,DmdRef,DmdTotal) = data
  (; PolicyCost,ReductionAdditional) = data

  KJBtu = 1.054615

  #
  # Select Policy Sets (Enduse,Tech,EC)
  #  
  CN = Select(Nation,"CN")
  years = collect(Yr(2026):Yr(2050))
  areas = Select(Area,"QC")
  ecs = Select(EC,"IronOreMining")
  techs = Select(Tech,"Oil")

  #
  # Reductions in demand read in in TJ and converted to TBtu
  #  
  ReductionAdditional[ecs,Yr(2026)] = 2.8738
  ReductionAdditional[ecs,Yr(2027)] = 4.3093
  ReductionAdditional[ecs,Yr(2028)] = 5.7468
  ReductionAdditional[ecs,Yr(2029)] = 7.1821
  ReductionAdditional[ecs,Yr(2030)] = 8.6185
  ReductionAdditional[ecs,Yr(2031)] = 8.6185
  ReductionAdditional[ecs,Yr(2032)] = 8.6185
  ReductionAdditional[ecs,Yr(2033)] = 8.6185
  ReductionAdditional[ecs,Yr(2034)] = 8.6185
  ReductionAdditional[ecs,Yr(2035)] = 8.6185
  ReductionAdditional[ecs,Yr(2036)] = 8.6185
  ReductionAdditional[ecs,Yr(2037)] = 8.6185
  ReductionAdditional[ecs,Yr(2038)] = 8.6185
  ReductionAdditional[ecs,Yr(2039)] = 8.6185
  ReductionAdditional[ecs,Yr(2040)] = 8.6185
  ReductionAdditional[ecs,Yr(2041)] = 8.6185
  ReductionAdditional[ecs,Yr(2042)] = 8.6185
  ReductionAdditional[ecs,Yr(2043)] = 8.6185
  ReductionAdditional[ecs,Yr(2044)] = 8.6185
  ReductionAdditional[ecs,Yr(2045)] = 8.6185
  ReductionAdditional[ecs,Yr(2046)] = 8.6185
  ReductionAdditional[ecs,Yr(2047)] = 8.6185
  ReductionAdditional[ecs,Yr(2048)] = 8.6185
  ReductionAdditional[ecs,Yr(2049)] = 8.6185
  ReductionAdditional[ecs,Yr(2050)] = 8.6185

  #
  # Apply an annual adjustment to reductions to compensate for 'rebound' from less retirements
  #  
  AnnualAdjustment[ecs,Yr(2026)] = 1.399
  AnnualAdjustment[ecs,Yr(2027)] = 1.440
  AnnualAdjustment[ecs,Yr(2028)] = 1.5
  AnnualAdjustment[ecs,Yr(2029)] = 1.6
  AnnualAdjustment[ecs,Yr(2030)] = 1.7
  AnnualAdjustment[ecs,Yr(2031)] = 1.8
  AnnualAdjustment[ecs,Yr(2032)] = 1.9
  AnnualAdjustment[ecs,Yr(2033)] = 2.0
  AnnualAdjustment[ecs,Yr(2034)] = 2.1
  AnnualAdjustment[ecs,Yr(2035)] = 2.2
  AnnualAdjustment[ecs,Yr(2036)] = 2.265
  AnnualAdjustment[ecs,Yr(2037)] = 2.399
  AnnualAdjustment[ecs,Yr(2038)] = 2.53
  AnnualAdjustment[ecs,Yr(2039)] = 2.664
  AnnualAdjustment[ecs,Yr(2040)] = 2.796
  AnnualAdjustment[ecs,Yr(2041)] = 2.897
  AnnualAdjustment[ecs,Yr(2042)] = 3.05
  AnnualAdjustment[ecs,Yr(2043)] = 3.189
  AnnualAdjustment[ecs,Yr(2044)] = 3.326
  AnnualAdjustment[ecs,Yr(2045)] = 3.463
  AnnualAdjustment[ecs,Yr(2046)] = 3.597
  AnnualAdjustment[ecs,Yr(2047)] = 3.739
  AnnualAdjustment[ecs,Yr(2048)] = 3.884
  AnnualAdjustment[ecs,Yr(2049)] = 4.028
  AnnualAdjustment[ecs,Yr(2050)] = 4.174

  #
  # Convert from TJ to TBtu
  #  
  for ec in ecs, year in years
    ReductionAdditional[ec,year] = ReductionAdditional[ec,year]/KJBtu*AnnualAdjustment[ec,year]
  end

  AllocateReduction(data,Enduses,techs,ecs,areas,years)

  #
  # Program Costs $M
  #
  PolicyCost[ecs,Yr(2026)] = 29.50
  PolicyCost[ecs,Yr(2027)] = 29.50
  PolicyCost[ecs,Yr(2028)] = 29.50
  PolicyCost[ecs,Yr(2029)] = 29.50
  PolicyCost[ecs,Yr(2030)] = 29.50
  #
  # Split out PolicyCost using reference Dmd values. PInv only uses Process Heat.
  #  
  for year in years, area in areas, ec in ecs, tech in techs, eu in Enduses
    @finite_math DmdFrac[eu,tech,ec,area,year] = 
      DmdRef[eu,tech,ec,area,year]/DmdTotal[ec,year]
    DInvTechExo[eu,tech,ec,area,year] = DInvTechExo[eu,tech,ec,area,year]+
      PolicyCost[ec,year]*DmdFrac[eu,tech,ec,area,year]
  end
  
  WriteDisk(db,"$Input/DInvTechExo",DInvTechExo)
end

function PolicyControl(db)
  @info "Ind_IronOre_QC.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
