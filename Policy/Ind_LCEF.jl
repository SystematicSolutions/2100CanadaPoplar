#
# Ind_LCEF.jl - Process Retrofit
#
# Directly inputs energy reductions for specific sectors in BC, ON, NB, NL
# according to Leadership and Challenge Low Carbon Economy Fund (LCEF) estimates(see Industry_tuning.xlsx) (RW 01/24/2022)
#

using EnergyModel

module Ind_LCEF

import ...EnergyModel: ReadDisk,WriteDisk,Select,Yr
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DEEARef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DmdRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Demand (TBtu/Yr)
  PERRef::VariableArray{5} = ReadDisk(BCNameDB,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  PERReduction::VariableArray{5} = ReadDisk(db,"$Input/PERReduction") # [Enduse,Tech,EC,Area,Year] Fraction of Process Energy Removed after this Policy is added ((mmBtu/Yr)/(mmBtu/Yr))
  PERRRExo::VariableArray{5} = ReadDisk(db,"$Outpt/PERRRExo") # [Enduse,Tech,EC,Area,Year] Process Energy Exogenous Retrofits ((mmBtu/Yr)/Yr)
  PInvExo::VariableArray{5} = ReadDisk(db,"$Input/PInvExo") # [Enduse,Tech,EC,Area,Year] Process Exogenous Investments (M$/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  AnnualAdjustment::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Adjustment for energy savings rebound
  CCC::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Variable for Displaying Outputs
  DDD::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Variable for Displaying Outputs
  DmdFrac::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  DmdTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Demand (TBtu/Yr)
  Expenses::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Program Expenses (2015 CN$M)
  FractionRemovedAnnually::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Fraction of Energy Requirements Removed (Btu/Btu)
  PolicyCost::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Policy Cost ($/TBtu)
  ReductionAdditional::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
  ReductionTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Demand Reduction from this Policy Cumulative over Years (TBtu/Yr)
end

function AllocateReduction(data::IControl,enduses,techs,ecs,areas,years)
  (; db,Input,Outpt) = data
  (; Enduse) = data
  (; DmdFrac,DmdRef) = data
  (; DmdTotal,FractionRemovedAnnually,PERRef) = data
  (; PERRRExo,PInvExo) = data
  (; PolicyCost,ReductionAdditional,ReductionTotal) = data

  #
  # Total Demands
  #
  for year in years, area in areas
    DmdTotal[area,year] = 
      sum(DmdRef[eu,tech,ec,area,year] for ec in ecs,tech in techs,eu in enduses)
  end

  #
  # Accumulate ReductionAdditional and apply to reference case demands
  #  
  for year in years, area in areas
    ReductionAdditional[area,year] = max((ReductionAdditional[area,year] - 
      ReductionTotal[area,year-1]),0.0)
    ReductionTotal[area,year] = ReductionAdditional[area,year] + 
      ReductionTotal[area,year-1]
  end

  #
  # Fraction Energy Removed each Year
  #  
  for year in years, area in areas
    @finite_math FractionRemovedAnnually[area,year] = 
      ReductionAdditional[area,year] / DmdTotal[area,year]
  end

  #
  # Energy Requirements Removed due to Program
  # 
  for year in years, area in areas, ec in ecs, tech in techs, enduse in enduses
    PERRRExo[enduse,tech,ec,area,year] = PERRRExo[enduse,tech,ec,area,year] +
      PERRef[enduse,tech,ec,area,year] * FractionRemovedAnnually[area,year]
  end

  WriteDisk(db,"$Outpt/PERRRExo",PERRRExo)

  #
  # Split out PolicyCost using reference Dmd values. PInv only uses Process Heat.
  #  
  for year in years, area in areas, ec in ecs, tech in techs
    for eu in enduses
      @finite_math DmdFrac[eu,tech,ec,area,year] = DmdRef[eu,tech,ec,area,year]/
        DmdTotal[area,year]
    end
    
    Heat = Select(Enduse,"Heat")
    PInvExo[Heat,tech,ec,area,year] = PInvExo[Heat,tech,ec,area,year]+
      sum(PolicyCost[area,year]*DmdFrac[eu,tech,ec,area,year] for eu in enduses)
  end

  WriteDisk(db,"$Input/PInvExo",PInvExo)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Area,EC,Enduse) = data
  (; Tech) = data
  (; AnnualAdjustment) = data
  (; PolicyCost,ReductionAdditional,xInflation) = data

  @. AnnualAdjustment=1.0;

  #
  # Policy results is a reduction in demand (PJ) converted to TBtu
  # Provincial PJ reductions by fuel share
  # Read ReductionAdditional(Area,Year)
  #
  BC = Select(Area,"BC");
  ON = Select(Area,"ON");
  NB = Select(Area,"NB");
  NL = Select(Area,"NL");

  years = collect(Yr(2022):Yr(2050));
  for year in years
    if year <= Yr(2030)
      ReductionAdditional[BC,year] = 1.5;
      ReductionAdditional[ON,year] = 0.4;
      ReductionAdditional[NB,year] = 0.4;
      ReductionAdditional[NL,year] = 0.6;
    elseif year <=  Yr(2035)
      ReductionAdditional[BC,year] = 1.5;
      ReductionAdditional[ON,year] = 0.5;
      ReductionAdditional[NB,year] = 0.4;
      ReductionAdditional[NL,year] = 0.6;
    else
      ReductionAdditional[BC,year] = 1.3;
      ReductionAdditional[ON,year] = 0.5;
      ReductionAdditional[NB,year] = 0.4;
      ReductionAdditional[NL,year] = 0.6;
    end
    
  end

  #
  # Apply an annual adjustment to reductions to compensate for 'rebound' from less retirements
  #
  AnnualAdjustment[BC,Yr(2022)] = 3.950
  AnnualAdjustment[BC,Yr(2023)] = 4.063
  AnnualAdjustment[BC,Yr(2024)] = 4.309
  AnnualAdjustment[BC,Yr(2025)] = 4.870
  AnnualAdjustment[BC,Yr(2026)] = 4.920
  AnnualAdjustment[BC,Yr(2027)] = 5.154
  AnnualAdjustment[BC,Yr(2028)] = 5.323
  AnnualAdjustment[BC,Yr(2029)] = 5.537
  AnnualAdjustment[BC,Yr(2030)] = 5.505
  AnnualAdjustment[BC,Yr(2031)] = 5.428
  AnnualAdjustment[BC,Yr(2032)] = 5.516
  AnnualAdjustment[BC,Yr(2033)] = 5.511
  AnnualAdjustment[BC,Yr(2034)] = 5.559
  AnnualAdjustment[BC,Yr(2035)] = 5.548
  AnnualAdjustment[BC,Yr(2036)] = 3.895
  AnnualAdjustment[BC,Yr(2037)] = 3.985
  AnnualAdjustment[BC,Yr(2038)] = 3.949
  AnnualAdjustment[BC,Yr(2039)] = 3.991
  AnnualAdjustment[BC,Yr(2040)] = 3.88
  AnnualAdjustment[BC,Yr(2041)] = 3.944
  AnnualAdjustment[BC,Yr(2042)] = 4.045
  AnnualAdjustment[BC,Yr(2043)] = 4.223
  AnnualAdjustment[BC,Yr(2044)] = 4.233
  AnnualAdjustment[BC,Yr(2045)] = 4.303
  AnnualAdjustment[BC,Yr(2046)] = 4.42
  AnnualAdjustment[BC,Yr(2047)] = 4.404
  AnnualAdjustment[BC,Yr(2048)] = 4.427
  AnnualAdjustment[BC,Yr(2049)] = 4.483
  AnnualAdjustment[BC,Yr(2050)] = 4.602
  *
  AnnualAdjustment[ON,Yr(2022)] = 0.997
  AnnualAdjustment[ON,Yr(2023)] = 1.088
  AnnualAdjustment[ON,Yr(2024)] = 1.195
  AnnualAdjustment[ON,Yr(2025)] = 1.304
  AnnualAdjustment[ON,Yr(2026)] = 1.409
  AnnualAdjustment[ON,Yr(2027)] = 1.513
  AnnualAdjustment[ON,Yr(2028)] = 1.608
  AnnualAdjustment[ON,Yr(2029)] = 1.700
  AnnualAdjustment[ON,Yr(2030)] = 1.791
  AnnualAdjustment[ON,Yr(2031)] = 1.700
  AnnualAdjustment[ON,Yr(2032)] = 1.796
  AnnualAdjustment[ON,Yr(2033)] = 1.883
  AnnualAdjustment[ON,Yr(2034)] = 1.982
  AnnualAdjustment[ON,Yr(2035)] = 2.080
  AnnualAdjustment[ON,Yr(2036)] = 2.203
  AnnualAdjustment[ON,Yr(2037)] = 2.298
  AnnualAdjustment[ON,Yr(2038)] = 2.394
  AnnualAdjustment[ON,Yr(2039)] = 2.489
  AnnualAdjustment[ON,Yr(2040)] = 2.585
  AnnualAdjustment[ON,Yr(2041)] = 2.682
  AnnualAdjustment[ON,Yr(2042)] = 2.776
  AnnualAdjustment[ON,Yr(2043)] = 2.872
  AnnualAdjustment[ON,Yr(2044)] = 2.968
  AnnualAdjustment[ON,Yr(2045)] = 3.066
  AnnualAdjustment[ON,Yr(2046)] = 3.133
  AnnualAdjustment[ON,Yr(2047)] = 3.255
  AnnualAdjustment[ON,Yr(2048)] = 3.355
  AnnualAdjustment[ON,Yr(2049)] = 3.448
  AnnualAdjustment[ON,Yr(2050)] = 3.548
  *
  AnnualAdjustment[NB,Yr(2022)] = 0.989
  AnnualAdjustment[NB,Yr(2023)] = 1.077
  AnnualAdjustment[NB,Yr(2024)] = 1.166
  AnnualAdjustment[NB,Yr(2025)] = 1.253
  AnnualAdjustment[NB,Yr(2026)] = 1.341
  AnnualAdjustment[NB,Yr(2027)] = 1.428
  AnnualAdjustment[NB,Yr(2028)] = 1.514
  AnnualAdjustment[NB,Yr(2029)] = 1.599
  AnnualAdjustment[NB,Yr(2030)] = 1.685
  AnnualAdjustment[NB,Yr(2031)] = 1.77
  AnnualAdjustment[NB,Yr(2032)] = 1.854
  AnnualAdjustment[NB,Yr(2033)] = 1.938
  AnnualAdjustment[NB,Yr(2034)] = 2.022
  AnnualAdjustment[NB,Yr(2035)] = 2.105
  AnnualAdjustment[NB,Yr(2036)] = 2.188
  AnnualAdjustment[NB,Yr(2037)] = 2.27
  AnnualAdjustment[NB,Yr(2038)] = 2.353
  AnnualAdjustment[NB,Yr(2039)] = 2.434
  AnnualAdjustment[NB,Yr(2040)] = 2.515
  AnnualAdjustment[NB,Yr(2041)] = 2.597
  AnnualAdjustment[NB,Yr(2042)] = 2.679
  AnnualAdjustment[NB,Yr(2043)] = 2.76
  AnnualAdjustment[NB,Yr(2044)] = 2.841
  AnnualAdjustment[NB,Yr(2045)] = 2.922
  AnnualAdjustment[NB,Yr(2046)] = 3.004
  AnnualAdjustment[NB,Yr(2047)] = 3.084
  AnnualAdjustment[NB,Yr(2048)] = 3.167
  AnnualAdjustment[NB,Yr(2049)] = 3.247
  AnnualAdjustment[NB,Yr(2050)] = 3.328
  *
  AnnualAdjustment[NL,Yr(2022)] = 0.997
  AnnualAdjustment[NL,Yr(2023)] = 1.088
  AnnualAdjustment[NL,Yr(2024)] = 1.195
  AnnualAdjustment[NL,Yr(2025)] = 1.305
  AnnualAdjustment[NL,Yr(2026)] = 1.304
  AnnualAdjustment[NL,Yr(2027)] = 1.409
  AnnualAdjustment[NL,Yr(2028)] = 1.513
  AnnualAdjustment[NL,Yr(2029)] = 1.608
  AnnualAdjustment[NL,Yr(2030)] = 1.700
  AnnualAdjustment[NL,Yr(2031)] = 1.791
  AnnualAdjustment[NL,Yr(2032)] = 1.700
  AnnualAdjustment[NL,Yr(2033)] = 1.796
  AnnualAdjustment[NL,Yr(2034)] = 1.883
  AnnualAdjustment[NL,Yr(2035)] = 2.080
  AnnualAdjustment[NL,Yr(2036)] = 2.323
  AnnualAdjustment[NL,Yr(2037)] = 2.415
  AnnualAdjustment[NL,Yr(2038)] = 2.507
  AnnualAdjustment[NL,Yr(2039)] = 2.599
  AnnualAdjustment[NL,Yr(2040)] = 2.69
  AnnualAdjustment[NL,Yr(2041)] = 2.783
  AnnualAdjustment[NL,Yr(2042)] = 2.875
  AnnualAdjustment[NL,Yr(2043)] = 2.968
  AnnualAdjustment[NL,Yr(2044)] = 3.06
  AnnualAdjustment[NL,Yr(2045)] = 3.151
  AnnualAdjustment[NL,Yr(2046)] = 3.244
  AnnualAdjustment[NL,Yr(2047)] = 3.338
  AnnualAdjustment[NL,Yr(2048)] = 3.43
  AnnualAdjustment[NL,Yr(2049)] = 3.523
  AnnualAdjustment[NL,Yr(2050)] = 3.619

  areas = Select(Area,["BC","ON","NB","NL"])
  for year in years, area in areas
    ReductionAdditional[area,year] = ReductionAdditional[area,year]/
      1.05461*AnnualAdjustment[area,year]
  end

  PolicyCost[BC,Yr(2022)] = 0;
  PolicyCost[ON,Yr(2022)] = 0;
  PolicyCost[NB,Yr(2022)] = 17.5;
  PolicyCost[NL,Yr(2022)] = 0;

  PolicyCost[NB,Yr(2022)] = PolicyCost[NB,Yr(2022)] / xInflation[NB,Yr(2022)];

  techs = Select(Tech,["Coal","Oil","Gas"])
  enduses = Select(Enduse,"Heat")

  ecs = Select(EC,"LimeGypsum");
  AllocateReduction(data,enduses,techs,ecs,BC,years);

  ecs = Select(EC,"PulpPaperMills");
  AllocateReduction(data,enduses,techs,ecs,ON,years);

  ecs1 = Select(EC,(from="Food",to="Furniture"));
  ecs2 = Select(EC,(from="OtherNonferrous",to="OtherManufacturing"));
  ecs3 = Select(EC,["Rubber","Glass","OtherNonMetallic"]);
  ecs = union(ecs1,ecs2,ecs3);
  AllocateReduction(data,enduses,techs,ecs,NB,years);

  ecs = Select(EC,["IronOreMining","Petroleum"]);
  AllocateReduction(data,enduses,techs,ecs,NL,years);
end

function PolicyControl(db)
  @info "Ind_LCEF.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
