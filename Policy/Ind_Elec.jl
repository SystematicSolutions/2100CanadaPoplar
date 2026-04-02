#
# Ind_Elec.txp - Process Retrofit to simulate ON electricity conservation frameworks
# Input direct energy savings and expenditures provided by Ontario
# see ON_CDM_DSM_Ref25.xlsx (RW 07/26/2021)
# Edited by RST (05Oct2022), tuning for Ref25 & cost/reduction updates, after Randy's fix for Disk Reading
#

using EnergyModel

module Ind_Elec

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
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
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
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
  ReductionMax::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data,db,enduses,ecs,tech,area,years)
  (; Outpt) = data
  (; EC,ECC,ECCs,ECs) = data
  (; CERSM,PERRemoved,PERRRExo,DEEARef,DmdRef,DmdTotal) = data
  (; ECUF,ReductionAdditional) = data
  
  #
  # Total Demands
  #  
  for year in years
    DmdTotal[year] = sum(DmdRef[eu,tech,ec,area,year] for ec in ecs, eu in enduses)
  end

  #
  # Multiply by DEEA if input values reflect expected Dmd savings
  #  
  for year in years, ec in ecs, eu in enduses
    @finite_math PERRemoved[eu,tech,ec,area,year] = 1000000*
      ReductionAdditional[tech,year]*DEEARef[eu,tech,ec,area,year]/
        CERSM[eu,ec,area,year]*DmdRef[eu,tech,ec,area,year]/DmdTotal[year]
  end

  for year in years, ec in ecs, eu in enduses
    ecc = Select(ECC,EC[ec])
    if ecc != []
      @finite_math PERRemoved[eu,tech,ec,area,year] = PERRemoved[eu,tech,ec,area,year]/
        ECUF[ecc,area,year]
    end
  end

  for year in years, ec in ecs, eu in enduses
    PERRRExo[eu,tech,ec,area,year] = PERRRExo[eu,tech,ec,area,year]+
      PERRemoved[eu,tech,ec,area,year]
  end

  WriteDisk(db,"$Outpt/PERRRExo",PERRRExo)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Area,EC) = data
  (; Enduse,Enduses) = data
  (; Tech,Techs,Years) = data
  (; Expenses,Increment) = data
  (; PERRemoved) = data
  (; PERRemovedTotal,PInvExo) = data
  (; Reduction,ReductionAdditional) = data
  (; xInflation) = data

  #
  # Note that Promula file has inputs for 'Increment' that doesn't actually do anything
  # so I left inputs out for now - Ian 02/07/25
  #
  for year in Years, tech in Techs
    Increment[tech,year] = 1.0
    Increment[tech,year] = 0
  end

  #
  # Electricity
  #
  # Select Sectors Included
  # Select all industrial sectors except pipelines
  #  
  ecs = Select(EC,(from="Food",to="OnFarmFuelUse"))
  area = Select(Area,"ON")
  tech = Select(Tech,"Electric")

  #
  # PJ Reductions in end-use sectors
  #
  Reduction[tech,Yr(2023)] = 0.069
  Reduction[tech,Yr(2024)] = 0.138
  Reduction[tech,Yr(2025)] = 0.276
  Reduction[tech,Yr(2026)] = 0.552
  Reduction[tech,Yr(2027)] = 1.399
  Reduction[tech,Yr(2028)] = 2.268
  Reduction[tech,Yr(2029)] = 3.137
  Reduction[tech,Yr(2030)] = 4.029
  Reduction[tech,Yr(2031)] = 4.929
  Reduction[tech,Yr(2032)] = 5.844
  Reduction[tech,Yr(2033)] = 6.764
  Reduction[tech,Yr(2034)] = 7.634
  Reduction[tech,Yr(2035)] = 8.369
  Reduction[tech,Yr(2036)] = 9.117
  Reduction[tech,Yr(2037)] = 9.480
  Reduction[tech,Yr(2038)] = 9.556
  Reduction[tech,Yr(2039)] = 9.631
  Reduction[tech,Yr(2040)] = 9.715
  Reduction[tech,Yr(2041)] = 9.715
  Reduction[tech,Yr(2042)] = 9.715
  Reduction[tech,Yr(2043)] = 9.715
  Reduction[tech,Yr(2044)] = 9.715
  Reduction[tech,Yr(2045)] = 9.715
  Reduction[tech,Yr(2046)] = 9.715
  Reduction[tech,Yr(2047)] = 9.715
  Reduction[tech,Yr(2048)] = 9.715
  Reduction[tech,Yr(2049)] = 9.715
  Reduction[tech,Yr(2050)] = 9.715

  Increment[tech,Yr(2023)] = 0.900
  Increment[tech,Yr(2024)] = 0.700
  Increment[tech,Yr(2025)] = 0.600
  Increment[tech,Yr(2026)] = 0.650
  Increment[tech,Yr(2027)] = 0.660
  Increment[tech,Yr(2028)] = 0.300
  Increment[tech,Yr(2029)] = 0.375
  Increment[tech,Yr(2030)] = 0.380
  Increment[tech,Yr(2031)] = 0.285
  Increment[tech,Yr(2032)] = 0.180
  Increment[tech,Yr(2033)] = 0.245
  Increment[tech,Yr(2034)] = 0.240
  Increment[tech,Yr(2035)] = 0.155
  Increment[tech,Yr(2036)] = 0.130
  Increment[tech,Yr(2037)] = 0.105
  Increment[tech,Yr(2038)] = 0.090
  Increment[tech,Yr(2039)] = 0.075
  Increment[tech,Yr(2040)] = 0.060
  Increment[tech,Yr(2041)] = 0.161
  Increment[tech,Yr(2042)] = 0.162
  Increment[tech,Yr(2043)] = 0.163
  Increment[tech,Yr(2044)] = 0.164
  Increment[tech,Yr(2045)] = 0.165
  Increment[tech,Yr(2046)] = 0.165
  Increment[tech,Yr(2047)] = 0.166
  Increment[tech,Yr(2048)] = 0.167
  Increment[tech,Yr(2049)] = 0.168
  Increment[tech,Yr(2050)] = 0.169

  years = collect(Yr(2023):Yr(2050))
  for year in years
    ReductionAdditional[tech,year] = Reduction[tech,year]/1.054615*
    Increment[tech,year]
  end
  
  AllocateReduction(data,db,Enduses,ecs,tech,area,years)
  
  #
  # Retrofit Costs
  #
  # Exclude Rubber and Transport Equipment to avoid excessive % investment
  # jumps that cause TIM problems (RW 10/10/18)
  #
  ecs1 = Select(EC,!=("Rubber"))
  ecs2 = Select(EC,!=("TransportEquipment"))
  ecs = intersect(ecs1,ecs2)

  #
  # Program Costs ($M,nominal), Read Expenses(Tech,Year)
  #
  Expenses[tech,Yr(2023)]=105.76
  Expenses[tech,Yr(2024)]=106.505
  Expenses[tech,Yr(2025)]=108.276
  Expenses[tech,Yr(2026)]=110.346
  Expenses[tech,Yr(2027)]=112.618
  Expenses[tech,Yr(2028)]=114.988
  Expenses[tech,Yr(2029)]=117.414
  Expenses[tech,Yr(2030)]=119.927
  Expenses[tech,Yr(2031)]=122.284
  Expenses[tech,Yr(2032)]=124.57
  Expenses[tech,Yr(2033)]=126.918
  Expenses[tech,Yr(2034)]=129.295
  Expenses[tech,Yr(2035)]=131.749
  Expenses[tech,Yr(2036)]=134.295
  Expenses[tech,Yr(2037)]=136.852
  Expenses[tech,Yr(2038)]=139.469
  Expenses[tech,Yr(2039)]=142.175
  Expenses[tech,Yr(2040)]=145.017
  Expenses[tech,Yr(2041)]=147.88
  Expenses[tech,Yr(2042)]=150.731
  Expenses[tech,Yr(2043)]=153.75
  Expenses[tech,Yr(2044)]=156.672
  Expenses[tech,Yr(2045)]=159.822
  Expenses[tech,Yr(2046)]=163.098
  Expenses[tech,Yr(2047)]=166.514
  Expenses[tech,Yr(2048)]=169.877
  Expenses[tech,Yr(2049)]=173.577
  Expenses[tech,Yr(2050)]=177.235

  for year in years
    Expenses[tech,year] = Expenses[tech,year]/xInflation[area,year]
  end

  #
  # Allocate Program Costs to each Enduse, Tech, EC, and Area
  # 
  for year in years, enduse in Enduses, ec in ecs
    #
    # TODOJulia: Statement below in Promula isn't in a loop so it is evaluating
    # the first value
    #
    #PERRemoved[enduse,tech,ec,area,year] = max(PERRemoved[enduse,tech,ec,area,year], 0.00001)
    #PERRemoved[first(enduse),tech,first(ec),area,year] = max(PERRemoved[first(enduse),tech,first(ec),area,year], 0.00001)
  end
  for year in years
    PERRemovedTotal[tech,year] = 
      sum(PERRemoved[enduse,tech,ec,area,year] for ec in ecs, enduse in Enduses)
  end

  Heat = Select(Enduse,"Heat")
  for year in years, ec in ecs
    @finite_math PInvExo[Heat,tech,ec,area,year] = PInvExo[Heat,tech,ec,area,year]+
      Expenses[tech,year]*sum(PERRemoved[eu,tech,ec,area,Yr(2021)] for eu in Enduses)/
          PERRemovedTotal[tech,Yr(2021)]
  end
  WriteDisk(db,"$Input/PInvExo",PInvExo)  
  #
  ######################
  #
  for year in Years, tech in Techs
    Increment[tech,year] = 1.0
    Increment[tech,year] = 0
  end

  #  
  ecs = Select(EC,(from="Food",to="OnFarmFuelUse"))
  area = Select(Area,"BC")
  tech = Select(Tech,"Electric")

  #
  # PJ Reductions in end-use sectors
  #
  Reduction[tech,Yr(2023)] = 0.128
  Reduction[tech,Yr(2024)] = 0.257
  Reduction[tech,Yr(2025)] = 0.430
  Reduction[tech,Yr(2026)] = 0.631
  Reduction[tech,Yr(2027)] = 0.892
  Reduction[tech,Yr(2028)] = 1.033
  Reduction[tech,Yr(2029)] = 1.236
  Reduction[tech,Yr(2030)] = 1.436
  Reduction[tech,Yr(2031)] = 1.650
  Reduction[tech,Yr(2032)] = 1.797
  Reduction[tech,Yr(2033)] = 1.944
  Reduction[tech,Yr(2034)] = 2.067
  Reduction[tech,Yr(2035)] = 2.168
  Reduction[tech,Yr(2036)] = 2.286
  Reduction[tech,Yr(2037)] = 2.356
  Reduction[tech,Yr(2038)] = 2.434
  Reduction[tech,Yr(2039)] = 2.496
  Reduction[tech,Yr(2040)] = 2.522
  Reduction[tech,Yr(2041)] = 2.522
  Reduction[tech,Yr(2042)] = 2.522
  Reduction[tech,Yr(2043)] = 2.522
  Reduction[tech,Yr(2044)] = 2.522
  Reduction[tech,Yr(2045)] = 2.522
  Reduction[tech,Yr(2046)] = 2.522
  Reduction[tech,Yr(2047)] = 2.522
  Reduction[tech,Yr(2048)] = 2.522
  Reduction[tech,Yr(2049)] = 2.522
  Reduction[tech,Yr(2050)] = 2.522

  Increment[tech,Yr(2023)] = 1.000
  Increment[tech,Yr(2024)] = 0.750
  Increment[tech,Yr(2025)] = 0.200
  Increment[tech,Yr(2026)] = 0.370
  Increment[tech,Yr(2027)] = 0.330
  Increment[tech,Yr(2028)] = 0.215
  Increment[tech,Yr(2029)] = 0.200
  Increment[tech,Yr(2030)] = 0.195
  Increment[tech,Yr(2031)] = 0.180
  Increment[tech,Yr(2032)] = 0.145
  Increment[tech,Yr(2033)] = 0.150
  Increment[tech,Yr(2034)] = 0.145
  Increment[tech,Yr(2035)] = 0.140
  Increment[tech,Yr(2036)] = 0.135
  Increment[tech,Yr(2037)] = 0.132
  Increment[tech,Yr(2038)] = 0.130
  Increment[tech,Yr(2039)] = 0.145
  Increment[tech,Yr(2040)] = 0.155
  Increment[tech,Yr(2041)] = 0.176
  Increment[tech,Yr(2042)] = 0.177
  Increment[tech,Yr(2043)] = 0.178
  Increment[tech,Yr(2044)] = 0.179
  Increment[tech,Yr(2045)] = 0.180
  Increment[tech,Yr(2046)] = 0.181
  Increment[tech,Yr(2047)] = 0.182
  Increment[tech,Yr(2048)] = 0.183
  Increment[tech,Yr(2049)] = 0.184
  Increment[tech,Yr(2050)] = 0.185

  years = collect(Yr(2023):Yr(2050))
  for year in years
    ReductionAdditional[tech,year] = Reduction[tech,year]/1.054615*
    Increment[tech,year]
  end
  
  AllocateReduction(data,db,Enduses,ecs,tech,area,years)
  
  #
  # Retrofit Costs
  #
  # Exclude Rubber and Transport Equipment to avoid excessive % investment
  # jumps that cause TIM problems (RW 10/10/18)
  #
  ecs1 = Select(EC,!=("Rubber"))
  ecs2 = Select(EC,!=("TransportEquipment"))
  ecs = intersect(ecs1,ecs2)

  #
  # Program Costs ($M,nominal), Read Expenses(Tech,Year)
  #
  Expenses[tech,Yr(2023)]=19.690
  Expenses[tech,Yr(2024)]=21.142
  Expenses[tech,Yr(2025)]=24.222
  Expenses[tech,Yr(2026)]=24.222
  Expenses[tech,Yr(2027)]=24.222
  Expenses[tech,Yr(2028)]=24.222
  Expenses[tech,Yr(2029)]=24.222
  Expenses[tech,Yr(2030)]=24.222
  Expenses[tech,Yr(2031)]=24.222
  Expenses[tech,Yr(2032)]=24.222 
  Expenses[tech,Yr(2033)]=24.222
  Expenses[tech,Yr(2034)]=24.222
  Expenses[tech,Yr(2035)]=24.222
  Expenses[tech,Yr(2036)]=24.222
  Expenses[tech,Yr(2037)]=24.222
  Expenses[tech,Yr(2038)]=24.222
  Expenses[tech,Yr(2039)]=24.222
  Expenses[tech,Yr(2040)]=24.222
  Expenses[tech,Yr(2041)]=147.88
  Expenses[tech,Yr(2042)]=150.731 
  Expenses[tech,Yr(2043)]=153.75
  Expenses[tech,Yr(2044)]=156.672
  Expenses[tech,Yr(2045)]=159.822
  Expenses[tech,Yr(2046)]=163.098
  Expenses[tech,Yr(2047)]=166.514
  Expenses[tech,Yr(2048)]=169.877
  Expenses[tech,Yr(2049)]=173.577
  Expenses[tech,Yr(2050)]=177.235

  years = collect(Yr(2023):Yr(2050))
  for year in years
    Expenses[tech,year] = Expenses[tech,year]/xInflation[area,year]
  end

  #
  # Allocate Program Costs to each Enduse, Tech, EC, and Area
  # 
  for year in years, enduse in Enduses, ec in ecs
    #
    # TODOJulia: Statement below in Promula isn't in a loop so it is evaluating
    # the first value
    #
    #PERRemoved[enduse,tech,ec,area,year] = max(PERRemoved[enduse,tech,ec,area,year], 0.00001)
    PERRemoved[first(enduse),tech,first(ec),area,year] = max(PERRemoved[first(enduse),tech,first(ec),area,year], 0.00001)
  end
  for year in years
    PERRemovedTotal[tech,year] = 
      sum(PERRemoved[enduse,tech,ec,area,year] for ec in ecs, enduse in Enduses)
  end

  Heat = Select(Enduse,"Heat")
  for year in years, ec in ecs
    @finite_math PInvExo[Heat,tech,ec,area,year] = PInvExo[Heat,tech,ec,area,year]+
      Expenses[tech,year]*sum(PERRemoved[eu,tech,ec,area,Yr(2021)] for eu in Enduses)/
          PERRemovedTotal[tech,Yr(2021)]
  end
  WriteDisk(db,"$Input/PInvExo",PInvExo)  
  
  #
  ######################
  #
  for year in Years, tech in Techs
    Increment[tech,year] = 1.0
    Increment[tech,year] = 0
  end

  #
  # Natural Gas
  #
  # Select Sectors Included
  # Select all industrial sectors except pipelines
  #  
  ecs = Select(EC,(from="Food",to="OnFarmFuelUse"))
  area = Select(Area,"MB")
  tech = Select(Tech,"Gas")

  #
  # PJ Reductions in end-use sectors
  #
  Reduction[tech,Yr(2023)] = 0.467
  Reduction[tech,Yr(2024)] = 0.467
  Reduction[tech,Yr(2025)] = 0.467
  Reduction[tech,Yr(2026)] = 0.467
  Reduction[tech,Yr(2027)] = 0.467
  Reduction[tech,Yr(2028)] = 0.467
  Reduction[tech,Yr(2029)] = 0.467
  Reduction[tech,Yr(2030)] = 0.467
  Reduction[tech,Yr(2031)] = 0.467
  Reduction[tech,Yr(2032)] = 0.467
  Reduction[tech,Yr(2033)] = 0.467
  Reduction[tech,Yr(2034)] = 0.467
  Reduction[tech,Yr(2035)] = 0.467
  Reduction[tech,Yr(2036)] = 0.467
  Reduction[tech,Yr(2037)] = 0.467
  Reduction[tech,Yr(2038)] = 0.467
  Reduction[tech,Yr(2039)] = 0.467
  Reduction[tech,Yr(2040)] = 0.467
  Reduction[tech,Yr(2041)] = 0.467
  Reduction[tech,Yr(2042)] = 0.467
  Reduction[tech,Yr(2043)] = 0.467
  Reduction[tech,Yr(2044)] = 0.467
  Reduction[tech,Yr(2045)] = 0.467
  Reduction[tech,Yr(2046)] = 0.467
  Reduction[tech,Yr(2047)] = 0.467
  Reduction[tech,Yr(2048)] = 0.467
  Reduction[tech,Yr(2049)] = 0.467
  Reduction[tech,Yr(2050)] = 0.467

  Increment[tech,Yr(2023)] = 1.00
  Increment[tech,Yr(2024)] = 0.250
  Increment[tech,Yr(2025)] = 0.150
  Increment[tech,Yr(2026)] = 0.050
  Increment[tech,Yr(2027)] = 0.051
  Increment[tech,Yr(2028)] = 0.052
  Increment[tech,Yr(2029)] = 0.045
  Increment[tech,Yr(2030)] = 0.044
  Increment[tech,Yr(2031)] = 0.043
  Increment[tech,Yr(2032)] = 0.042
  Increment[tech,Yr(2033)] = 0.040
  Increment[tech,Yr(2034)] = 0.040
  Increment[tech,Yr(2035)] = 0.080
  Increment[tech,Yr(2036)] = 0.080
  Increment[tech,Yr(2037)] = 0.080
  Increment[tech,Yr(2038)] = 0.070
  Increment[tech,Yr(2039)] = 0.060
  Increment[tech,Yr(2040)] = 0.059
  Increment[tech,Yr(2041)] = 0.070
  Increment[tech,Yr(2042)] = 0.070
  Increment[tech,Yr(2043)] = 0.070
  Increment[tech,Yr(2044)] = 0.070
  Increment[tech,Yr(2045)] = 0.070
  Increment[tech,Yr(2046)] = 0.070
  Increment[tech,Yr(2047)] = 0.070
  Increment[tech,Yr(2048)] = 0.070
  Increment[tech,Yr(2049)] = 0.070
  Increment[tech,Yr(2050)] = 0.070

  years = collect(Yr(2023):Yr(2050))
  for year in years
    ReductionAdditional[tech,year] = Reduction[tech,year]/1.054615*
    Increment[tech,year]
  end
  
  AllocateReduction(data,db,Enduses,ecs,tech,area,years)
  
  #
  # Retrofit Costs
  #
  # Exclude Rubber and Transport Equipment to avoid excessive % investment
  # jumps that cause TIM problems (RW 10/10/18)
  #
  ecs1 = Select(EC,!=("Rubber"))
  ecs2 = Select(EC,!=("TransportEquipment"))
  ecs = intersect(ecs1,ecs2)

  #
  # Program Costs ($M,nominal), Read Expenses(Tech,Year)
  #
  Expenses[tech,Yr(2023)]=5.736

  years = Yr(2023)
  for year in years
    Expenses[tech,year] = Expenses[tech,year]/xInflation[area,year]
  end

  #
  # Allocate Program Costs to each Enduse, Tech, EC, and Area
  # 
  for year in years, enduse in Enduses, ec in ecs
    #
    # TODOJulia: Statement below in Promula isn't in a loop so it is evaluating
    # the first value
    #
    #PERRemoved[enduse,tech,ec,area,year] = max(PERRemoved[enduse,tech,ec,area,year], 0.00001)
    PERRemoved[first(enduse),tech,first(ec),area,year] = max(PERRemoved[first(enduse),tech,first(ec),area,year], 0.00001)
  end
  for year in years
    PERRemovedTotal[tech,year] = 
      sum(PERRemoved[enduse,tech,ec,area,year] for ec in ecs, enduse in Enduses)
  end

  Heat = Select(Enduse,"Heat")
  for year in years, ec in ecs
    @finite_math PInvExo[Heat,tech,ec,area,year] = PInvExo[Heat,tech,ec,area,year]+
      Expenses[tech,year]*sum(PERRemoved[eu,tech,ec,area,Yr(2021)] for eu in Enduses)/
          PERRemovedTotal[tech,Yr(2021)]
  end
  WriteDisk(db,"$Input/PInvExo",PInvExo) 
end

function PolicyControl(db)
  @info "Ind_Elec.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
     PolicyControl(DB)
end

end
