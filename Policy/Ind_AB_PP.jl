#
# Ind_AB_PP.jl - Simulates CleanBC investments into decarbonizing SweetGasProcessing.
# Reductions are assumed to non-incremental, tuned to the base case. Reductions come from energy efficiency.
# Aligned to numbers that have been received from the BC government or pulled from the BC government website.
#

using EnergyModel

module Ind_AB_PP

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # Map between Area and Nation [Area,Nation]
  DInvTechExo::VariableArray{5} = ReadDisk(db,"$Input/DInvTechExo") # [Enduse,Tech,EC,Area,Year] device Exogenous Investments (M$/Yr)
  DmdRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  DERRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DER") # [Enduse,Tech,EC,Area,Year] Device Energy Requirement (mmBtu/Yr)
  DERReduction::VariableArray{5} = ReadDisk(db,"$Input/DERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Device Energy Removed after this Policy is added ((mmBtu/Yr)/(mmBtu/Yr))
  DERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/DERRRExo") # [Enduse,Tech,EC,Area,Year] Device Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)

  # Scratch Variables
  AnnualAdjustment::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # [EC,Area,Year] Adjustment for energy savings rebound
  DmdFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  DmdTotal::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # [EC,Area,Year] Total Demand (TBtu/Yr)
  FractionRemovedAnnually::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # [EC,Area,Year] Fraction of Energy Requirements Removed (Btu/Btu)
  ReductionAdditional::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # [EC,Area,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
  ReductionTotal::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # [EC,Area,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
  PolicyCost::VariableArray{2} = zeros(Float32,length(EC),length(Year)) # [Year] Policy Cost ($/TBtu)
end

function AllocateReduction(data::IControl,enduses,tech,ec,area,years)
  (; db,Outpt) = data
  (; Tech) = data
  (; DmdRef,DmdTotal) = data
  (; DERRef,DERRRExo) = data
  (; FractionRemovedAnnually) = data
  (; ReductionAdditional,ReductionTotal) = data

  #
  # Total Demands
  #  
  # Statement below from Promula code shouldn't work since we enter procudure after Select Tech(Gas) - Ian 02/04/25
  # techs = Select(Tech,["Coal","Oil","Gas"])
  for year in years
    DmdTotal[ec,area,year] = sum(DmdRef[enduse,tech,ec,area,year] for enduse in enduses)
  end

  #
  # Accumulate ReductionAdditional and apply to reference case demands
  #  
  for year in years
    ReductionAdditional[ec,area,year] = max((ReductionAdditional[ec,area,year] - 
      ReductionTotal[ec,area,year-1]),0.0)
    ReductionTotal[ec,area,year] = ReductionAdditional[ec,area,year] + 
      ReductionTotal[ec,area,year-1]
  end

  #
  #Fraction Removed each Year
  #  
  for year in years
    @finite_math FractionRemovedAnnually[ec,area,year] = ReductionAdditional[ec,area,year] / 
      DmdTotal[ec,area,year]
  end

  #
  #Energy Requirements Removed due to Program
  #  
  for enduse in enduses, year in years
    DERRRExo[enduse,tech,ec,area,year] = DERRRExo[enduse,tech,ec,area,year]+ 
                                         (DERRef[enduse,tech,ec,area,year]*FractionRemovedAnnually[ec,area,year])
  end

  WriteDisk(db,"$Outpt/DERRRExo",DERRRExo)
end

function IndPolicy(db::String)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC,Enduse,Enduses,Nation,Tech) = data 
  (; AnnualAdjustment,DInvTechExo,DmdFrac,DmdRef,DmdTotal,ReductionAdditional,PolicyCost) = data

  #
  # Select Sets for Policy
  #  
  nation = Select(Nation,"CN")
  area = Select(Area,"AB")
  ec = Select(EC,"PulpPaperMills")
  #
  # Policy results is a reduction in demand (PJ) converted to TBtu
  #
  years = collect(Yr(2024):Yr(2050))

  ReductionAdditional[ec,area,Yr(2024)] = 0.515
  ReductionAdditional[ec,area,Yr(2025)] = 0.515
  ReductionAdditional[ec,area,Yr(2026)] = 0.515
  ReductionAdditional[ec,area,Yr(2027)] = 0.515
  ReductionAdditional[ec,area,Yr(2028)] = 1.154
  ReductionAdditional[ec,area,Yr(2029)] = 1.154
  ReductionAdditional[ec,area,Yr(2030)] = 1.154
  ReductionAdditional[ec,area,Yr(2031)] = 1.154
  ReductionAdditional[ec,area,Yr(2032)] = 1.154
  ReductionAdditional[ec,area,Yr(2033)] = 1.154
  ReductionAdditional[ec,area,Yr(2034)] = 1.154
  ReductionAdditional[ec,area,Yr(2035)] = 1.154
  ReductionAdditional[ec,area,Yr(2036)] = 1.154
  #ReductionAdditional[ec,area,Yr(2037)] = 1.154 TODOJulia: missing in Promula file
  ReductionAdditional[ec,area,Yr(2038)] = 1.154
  ReductionAdditional[ec,area,Yr(2039)] = 1.154
  ReductionAdditional[ec,area,Yr(2040)] = 1.154
  ReductionAdditional[ec,area,Yr(2041)] = 1.154
  ReductionAdditional[ec,area,Yr(2042)] = 1.154
  ReductionAdditional[ec,area,Yr(2043)] = 1.154
  ReductionAdditional[ec,area,Yr(2044)] = 1.154
  ReductionAdditional[ec,area,Yr(2045)] = 1.154
  ReductionAdditional[ec,area,Yr(2046)] = 1.154
  ReductionAdditional[ec,area,Yr(2047)] = 1.154
  ReductionAdditional[ec,area,Yr(2048)] = 1.154
  ReductionAdditional[ec,area,Yr(2049)] = 0.686
  ReductionAdditional[ec,area,Yr(2050)] = 0.686

  #
  # Apply an annual adjustment to reductions to compensate for 'rebound' from less retirements
  #  
  AnnualAdjustment[ec,area,Yr(2024)] = 1.04
  AnnualAdjustment[ec,area,Yr(2025)] = 1.09
  AnnualAdjustment[ec,area,Yr(2026)] = 1.16
  AnnualAdjustment[ec,area,Yr(2027)] = 1.28
  AnnualAdjustment[ec,area,Yr(2028)] = 1.38
  AnnualAdjustment[ec,area,Yr(2029)] = 1.52
  AnnualAdjustment[ec,area,Yr(2030)] = 1.70
  AnnualAdjustment[ec,area,Yr(2031)] = 1.81
  AnnualAdjustment[ec,area,Yr(2032)] = 1.83
  AnnualAdjustment[ec,area,Yr(2033)] = 2.145
  AnnualAdjustment[ec,area,Yr(2034)] = 2.155
  AnnualAdjustment[ec,area,Yr(2035)] = 2.295
  AnnualAdjustment[ec,area,Yr(2036)] = 2.445
  AnnualAdjustment[ec,area,Yr(2037)] = 2.485
  AnnualAdjustment[ec,area,Yr(2038)] = 2.575
  AnnualAdjustment[ec,area,Yr(2039)] = 2.745
  AnnualAdjustment[ec,area,Yr(2040)] = 2.829
  AnnualAdjustment[ec,area,Yr(2041)] = 2.839
  AnnualAdjustment[ec,area,Yr(2042)] = 2.849
  AnnualAdjustment[ec,area,Yr(2043)] = 2.859
  AnnualAdjustment[ec,area,Yr(2044)] = 2.869
  AnnualAdjustment[ec,area,Yr(2045)] = 2.879
  AnnualAdjustment[ec,area,Yr(2046)] = 2.889
  AnnualAdjustment[ec,area,Yr(2047)] = 2.899
  AnnualAdjustment[ec,area,Yr(2048)] = 2.909
  AnnualAdjustment[ec,area,Yr(2049)] = 2.919
  AnnualAdjustment[ec,area,Yr(2050)] = 2.929

  #
  # Convert from TJ to TBtu
  #  
  tech = Select(Tech,"Gas")
  for year in years
    ReductionAdditional[ec,area,year] = ReductionAdditional[ec,area,year]/1.05461*AnnualAdjustment[ec,area,year]
  end

  AllocateReduction(data,Enduses,tech,ec,area,years)
  
  #
  # Program Costs, Read PolicyCost 
  # 
  PolicyCost[ec,Yr(2024)] = 88.6

  # Investment costs have been updated due to the year 2023 being removed. Check for accuracy later.
  # NC 06/20/2024
  # Split out PolicyCost using reference Dmd values. PInv only uses Process Heat.
  #
  for enduse in Enduses,year in years
    DmdFrac[enduse,tech,ec,area,year] = DmdRef[enduse,tech,ec,area,year]/DmdTotal[ec,area,year]
    DInvTechExo[enduse,tech,ec,area,year] = DInvTechExo[enduse,tech,ec,area,year]+PolicyCost[ec,year]*DmdFrac[enduse,tech,ec,area,year]
  end
  WriteDisk(db,"$Input/DInvTechExo",DInvTechExo)
end

function PolicyControl(db)
  @info "Ind_AB_PP.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
