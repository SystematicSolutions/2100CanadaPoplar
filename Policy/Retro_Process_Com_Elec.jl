#
# Retro_Process_Com_Elec.jl - Process Retrofit
# Electricity Conservation Framework, Commercial Buildings Process Improvements
# Input direct energy savings and expenditures provided by Ontario
# see ON_CDM_DSM3.xlsx (RW 09/16/2021)
#
# Last updated by Yang Li on 2025-06-13
#

using EnergyModel

module Retro_Process_Com_Elec

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  CERSM::VariableArray{4} = ReadDisk(db,"$CalDB/CERSM") # [Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)
  DEEARef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DmdRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  ECUF::VariableArray{3} = ReadDisk(db,"MOutput/ECUF") # [ECC,Area,Year] Capital Utilization Fraction
  PER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  PERReduction::VariableArray{5} = ReadDisk(db,"$Input/PERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Process Energy Removed after this Policy is added ((mmBtu/Yr)/(mmBtu/Yr))
  # PERReductionStart::VariableArray{5} = ReadDisk(db,"$Input/PERReductionStart") # [Enduse,Tech,EC,Area,Year] Fraction of Process Energy Removed from Previous Policies ((mmBtu/Yr)/(mmBtu/Yr))
  PERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  PInvExo::VariableArray{5} = ReadDisk(db,"$Input/PInvExo") # [Enduse,Tech,EC,Area,Year] Process Exogenous Investments (M$/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  AnnualAdjustment::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Adjustment for energy savings rebound
  DmdSavings::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions after this Policy is added (TBtu/Yr)
  DmdSavingsAdditional::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions from this Policy (TBtu/Yr)
  DmdSavingsStart::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Demand Reductions from Previous Policies (TBtu/Yr)
  DmdSavingsTotal::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Total Demand Reductions after this Policy is added (TBtu/Yr)
  DmdTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Demand (TBtu/Yr)
  Expenses::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Program Expenses (2015 CN$M)
  FractionRemovedAnnually::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Fraction of Energy Requirements Removed (Btu/Btu)
  Increment::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Annual increment for rebound adjustment
  PERRRExoTotal::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Process Energy Removed (mmBtu/Yr)
  PERReductionAdditional::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Fraction of Process Energy Removed added by this Policy ((mmBtu/Yr)/(mmBtu/Yr))
  PERRemoved::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Policy-specific Process Energy Removed ((mmBtu/Yr)/Yr)
  PERRemovedTotal::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Policy-specific Total Process Energy Removed (mmBtu/Yr)
  PolicyCost::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Cost ($/TBtu)
  Reduction::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
  ReductionAdditional::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data,db,enduses,tech,area,years)
  (; Outpt) = data
  (; EC,ECC,ECCs,ECs) = data
  (; CERSM,PERRemoved,PERRRExo,DEEARef,DmdRef,DmdTotal) = data
  (; ECUF,ReductionAdditional) = data

  #
  # Total Demands
  #
  for year in years
    DmdTotal[year] = sum(DmdRef[eu,tech,ec,area,year] for ec in ECs, eu in enduses)
  end

  #
  # Multiply by DEEA if input values reflect expected Dmd savings
  #
  for year in years, ec in ECs, eu in enduses
    @finite_math PERRemoved[eu,tech,ec,area,year] = 1000000*
      ReductionAdditional[tech,year]*DEEARef[eu,tech,ec,area,year]/
        CERSM[eu,ec,area,year]*DmdRef[eu,tech,ec,area,year]/DmdTotal[year]
  end

  for year in years, ec in ECs, ecc in ECCs, eu in enduses
    if EC[ec] == ECC[ecc]
      @finite_math PERRemoved[eu,tech,ec,area,year] = PERRemoved[eu,tech,ec,area,year]/
        ECUF[ecc,area,year]
    end

  end

  for year in years, ec in ECs, eu in enduses
    PERRRExo[eu,tech,ec,area,year] = PERRRExo[eu,tech,ec,area,year]+
      PERRemoved[eu,tech,ec,area,year]
  end

  WriteDisk(db,"$Outpt/PERRRExo",PERRRExo)
end

function ComPolicy(db)
  data = CControl(; db)
  (; Input) = data
  (; Area,ECs) = data
  (; Enduse) = data
  (; Tech,Techs,Years) = data
  (; AnnualAdjustment) = data
  (; Expenses,Increment) = data
  (; PERRemoved) = data
  (; PERRemovedTotal,PInvExo) = data
  (; Reduction,ReductionAdditional) = data
  (; xInflation) = data

  for year in Years, tech in Techs
    AnnualAdjustment[tech,year] = 1.0
    Increment[tech,year] = 0
  end

  #
  # Select Sets for Policy
  #
  area = Select(Area,"ON")
  enduses = Select(Enduse,["Heat","AC"])
  tech = Select(Tech,"Electric")
  years = collect(Yr(2024):Yr(2050))

  #
  # PJ Reductions in end-use sectors
  #
  #! format: off
  Reduction[tech, years] = [
    # 2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
      0.39    0.79    1.93    3.88    5.86    7.92    10.0    12.1    14.2    16.4    18.6    20.5    22.4    23.4    23.7    24.0    24.2    24.4    24.6    24.8    25.0    25.2    25.4    25.6    25.8    26.1    26.3
    ]
  #! format: on

  for year in years
    ReductionAdditional[tech,year] = Reduction[tech,year]-Reduction[tech,year-1]
  end

    years = collect(Yr(2024):Yr(2029))
  for year in years
    Increment[tech,year] = 0.00000000000015
  end

   years = collect(Yr(2030):Yr(2031))
  for year in years
    Increment[tech,year] = 0.000000000000015
  end

  years = collect(Yr(2032):Yr(2033))
  for year in years
    Increment[tech,year] = 0.00001
  end

  years = collect(Yr(2034):Yr(2037))
  for year in years
    Increment[tech,year] = 0.0003
  end

  years = collect(Yr(2038):Yr(2038))
  for year in years
    Increment[tech,year] = 0.08
  end

  years = collect(Yr(2038):Yr(2039))
  for year in years
    Increment[tech,year] = 0.90
  end


  years = collect(Yr(2040):Yr(2042))
  for year in years
    Increment[tech,year] = 1.15
  end

 years = collect(Yr(2043):Yr(2044))
  for year in years
    Increment[tech,year] = 1.25
  end

  years = collect(Yr(2046):Final)
  for year in years
    Increment[tech,year] = 1.40
  end

  years = collect(Yr(2024):Yr(2050))
  for year in years
    AnnualAdjustment[tech,year] = AnnualAdjustment[tech,year-1]+Increment[tech,year]
    ReductionAdditional[tech,year] = ReductionAdditional[tech,year]/1.054615*
      AnnualAdjustment[tech,year]
  end

  AllocateReduction(data,db,enduses,tech,area,years)
  #
  # Program Costs
  #
  #! format: off
  Expenses[tech, years] = [
    #2024    2025    2026    2027    2028    2029    2030    2031    2032    2033    2034    2035    2036    2037    2038    2039    2040    2041    2042    2043    2044    2045    2046    2047    2048    2049    2050
    39.8    40.6    41.4    42.3    43.1    44.0    44.9    45.8    46.7    47.6    48.6    49.5    50.5    51.5    52.6    53.6    54.7    55.8    56.9    58.0    59.2    60.4    61.6    62.8    64.1    65.4    66.7
  ]
  for year in years
    Expenses[tech,year] = Expenses[tech,year]/xInflation[area,year]
  end

  #
  # Allocate Program Costs to each Enduse, Tech, EC, and Area
  #
  for year in years
    PERRemovedTotal[tech,year] =
      sum(PERRemoved[enduse,tech,ec,area,year] for ec in ECs, enduse in enduses)
  end

  Heat = Select(Enduse,"Heat")
  for year in years, ec in ECs
    @finite_math PInvExo[Heat,tech,ec,area,year] = PInvExo[Heat,tech,ec,area,year]+
      Expenses[tech,year]*sum(PERRemoved[eu,tech,ec,area,year] for eu in enduses)/
          PERRemovedTotal[tech,year]
  end

  WriteDisk(db,"$Input/PInvExo",PInvExo)
end

function PolicyControl(db)
  @info "Retro_Process_Com_Elec.jl - PolicyControl"
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
     PolicyControl(DB)
end

end
