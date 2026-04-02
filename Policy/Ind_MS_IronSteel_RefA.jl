#
# Ind_MS_IronSteel.jl - Energy for NZA
#
# Net-Zero Accelerator (NZA) Algoma Steel + Arcelor-Mittal reductions are -7.2 Mt
# in 2030 via Natural Gas DRI-EAF (RW 09.24.2021)
# Edited by RST 01Aug2022, re-tuning for Ref22
# Edited by NC 07Sep2023, re-tuning for Ref24
#

using EnergyModel

module Ind_MS_IronSteel_RefA

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
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CFraction::VariableArray{5} = ReadDisk(db,"$Input/CFraction") # [Enduse,Tech,EC,Area,Year] Fraction of Production Capacity open to Conversion ($/$)
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  CnvrtEU::VariableArray{4} = ReadDisk(db,"$Input/CnvrtEU") # Conversion Switch [Enduse,EC,Area]
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  Endogenous::Float64 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  FsFracMax::VariableArray{5} = ReadDisk(db,"$Input/FsFracMax") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  FsFracMin::VariableArray{5} = ReadDisk(db,"$Input/FsFracMin") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  FsPOCX::VariableArray{5} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu))
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)  DInvTechExo::VariableArray{5} = ReadDisk(db,"$Input/DInvTechExo") # [Enduse,Tech,EC,Area,Year] Process Exogenous Investments (M$/Yr)

  end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input) = data
  (; Area,CTech,CTechs,EC) = data
  (; Enduse,Enduses,Fuel,FuelEP) = data
  (; Poll,Tech) = data
  (; CFraction,CMSM0,CnvrtEU,Endogenous) = data
  (; DmFracMax,DmFracMin,FsFracMin,FsFracMax,FsPOCX,PEMM,POCX) = data
  (; xDmFrac,xFsFrac) = data

  area = Select(Area,"ON")
  ec = Select(EC,"IronSteel")

  Electric = Select(Fuel,"Electric")
  CokeOvenGas = Select(Fuel,"CokeOvenGas")
  NaturalGas = Select(Fuel,"NaturalGas")
  LPG = Select(Fuel,"LPG")
  NaturalGasRaw = Select(Fuel,"NaturalGasRaw")

  fuels = Select(Fuel,["Electric","CokeOvenGas","NaturalGas","LPG","NaturalGasRaw"])
  tech = Select(Tech,"Gas")
  enduse = 1

  xDmFrac[enduse,Electric,tech,ec,area,Yr(2025)] = 0.575
  xDmFrac[enduse,CokeOvenGas,tech,ec,area,Yr(2025)] = 0.0012
  xDmFrac[enduse,NaturalGas,tech,ec,area,Yr(2025)] = 0.423
  xDmFrac[enduse,LPG,tech,ec,area,Yr(2025)] = 0.0010
  xDmFrac[enduse,NaturalGasRaw,tech,ec,area,Yr(2025)] = 0.0000

  years = collect(Yr(2026):Yr(2029))
  for year in years, enduse in Enduses, fuel in fuels
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[1,fuel,tech,ec,area,Yr(2025)]
  end

  years = collect(Yr(2025):Yr(2029))
  for year in years, enduse in Enduses, fuel in fuels
    DmFracMax[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year] * 1.01
    DmFracMin[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year] * 0.99
  end

  #

  xDmFrac[enduse,Electric,tech,ec,area,Yr(2030)] = 0.9995
  xDmFrac[enduse,CokeOvenGas,tech,ec,area,Yr(2030)] = 0.0000
  xDmFrac[enduse,NaturalGas,tech,ec,area,Yr(2030)] = 0.0005
  xDmFrac[enduse,LPG,tech,ec,area,Yr(2030)] = 0.0000
  xDmFrac[enduse,NaturalGasRaw,tech,ec,area,Yr(2030)] = 0.0000

  # TODOPromula: Pine version of file unselects Enduse but doesn't apply new xDmFrac to anything besides (1) - Ian
  years = collect(Yr(2030):Final)
  for year in years, enduse in Enduses
    xDmFrac[enduse,Electric,tech,ec,area,year] = xDmFrac[enduse,Electric,tech,ec,area,Yr(2030)] * 0.99
    xDmFrac[enduse,NaturalGas,tech,ec,area,year] = xDmFrac[enduse,NaturalGas,tech,ec,area,Yr(2030)] * 1.03
  end

  # TODOPromula: We aren't setting xDmFrac for other fuels past 2030, not sure what value this equation is using - Ian
  enduse = 1
  for year in years, fuel in fuels
    DmFracMax[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year] * 1.01
    DmFracMin[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year] * 0.99
  end

  for year in years, fuel in fuels
    # TODOPromula: Why is Promula version doing these equations twice? - Ian
    DmFracMax[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year] * 1.01
    DmFracMin[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year] * 0.99
  end

  #TODOPromula: Note we aren't writing xDmFrac in original file - Ian 08/05/25
  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)

  #
  # Hydrogen substitution 0.4 TJ of natural gas replaces 1 TJ of Coke for Iron & Steel
  # Source: Industry_tuning5.xlsx
  # from Robin White
  # Hydrogen substitution - 13% of coke in 2025,increasing to 100% of coke by 2043
  #

  #
  # xFsFrac(Coke,Tech,EC,Area,Year)=x
  # xFsFrac(NaturalGas,Tech,EC,Area,Year)=(1-x)*0.4
  #
  tech = Select(Tech,"Coal")

  Coke = Select(Fuel,"Coke");
  NaturalGas = Select(Fuel,"NaturalGas");
  Hydrogen = Select(Fuel, "Hydrogen");

  xFsFrac[Coke,tech,ec,area,Yr(2025)] = 0.948
  xFsFrac[Coke,tech,ec,area,Yr(2026)] = 0.948
  xFsFrac[Coke,tech,ec,area,Yr(2027)] = 0.948
  xFsFrac[Coke,tech,ec,area,Yr(2028)] = 0.948
  xFsFrac[Coke,tech,ec,area,Yr(2029)] = 0.948
  xFsFrac[Coke,tech,ec,area,Yr(2030)] = 0.085
  xFsFrac[Coke,tech,ec,area,Yr(2031)] = 0.085
  xFsFrac[Coke,tech,ec,area,Yr(2032)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2033)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2034)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2035)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2036)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2037)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2038)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2039)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2040)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2041)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2042)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2043)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2044)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2045)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2046)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2047)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2048)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2049)] = 0.005
  xFsFrac[Coke,tech,ec,area,Yr(2050)] = 0.005

  xFsFrac[NaturalGas,tech,ec,area,Yr(2025)] = 0.052
  xFsFrac[NaturalGas,tech,ec,area,Yr(2026)] = 0.052
  xFsFrac[NaturalGas,tech,ec,area,Yr(2027)] = 0.052
  xFsFrac[NaturalGas,tech,ec,area,Yr(2028)] = 0.052
  xFsFrac[NaturalGas,tech,ec,area,Yr(2029)] = 0.052
  xFsFrac[NaturalGas,tech,ec,area,Yr(2030)] = 0.490
  xFsFrac[NaturalGas,tech,ec,area,Yr(2031)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2032)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2033)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2034)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2035)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2036)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2037)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2038)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2039)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2040)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2041)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2042)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2043)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2044)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2045)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2046)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2047)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2048)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2049)] = 0.595
  xFsFrac[NaturalGas,tech,ec,area,Yr(2050)] = 0.595

  xFsFrac[Hydrogen,tech,ec,area,Yr(2030)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2031)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2032)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2033)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2034)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2035)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2036)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2037)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2038)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2039)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2040)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2041)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2042)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2043)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2044)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2045)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2046)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2047)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2048)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2049)] = 0.405
  xFsFrac[Hydrogen,tech,ec,area,Yr(2050)] = 0.405

  #
  # Constrain FsFrac to match old policy impact (FsFrac < 1.0)
  #
  years = collect(Yr(2025):Yr(2050))
  for year in years
    FsFracMax[NaturalGas,tech,ec,area,year] =
      xFsFrac[NaturalGas,tech,ec,area,year]
    FsFracMin[NaturalGas,tech,ec,area,year] =
      xFsFrac[NaturalGas,tech,ec,area,year]
  end

  CoalFuel = Select(Fuel,"Coal")
  for year in years
    FsFracMax[CoalFuel,tech,ec,area,year] =
      xFsFrac[CoalFuel,tech,ec,area,year]
    FsFracMax[Coke,tech,ec,area,year] =
      xFsFrac[Coke,tech,ec,area,year]
  end

  #
  # Assign emission factors for natural gas since none in history
  #
  years = collect(Yr(2025):Final)
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  Heat = Select(Enduse,"Heat")
  NaturalGasEP = Select(FuelEP,"NaturalGas")

  for year in years, poll in polls
    FsPOCX[NaturalGas,ec,poll,area,year] =
      POCX[Heat,NaturalGasEP,ec,poll,area,year]
  end

  WriteDisk(db,"$Input/xFsFrac",xFsFrac)
  WriteDisk(db,"$Input/FsPOCX",FsPOCX)
  WriteDisk(db,"$Input/FsFracMax",FsFracMax)
  WriteDisk(db,"$Input/FsFracMin",FsFracMin)

  years = collect(Yr(2025):Yr(2030))
  tech = Select(Tech,"Gas")
  enduse = 1

  for year in years
    PEMM[enduse,tech,ec,area,year] =
      PEMM[enduse,tech,ec,area,year] * 2.0
  end

  WriteDisk(db,"$CalDB/PEMM",PEMM)

  for year in years
    CnvrtEU[enduse,ec,area,year] = Endogenous
    CFraction[enduse,tech,ec,area,year] = 1.0
  end

  WriteDisk(db,"$Input/CnvrtEU",CnvrtEU)
  WriteDisk(db,"$Input/CFraction",CFraction)

  for year in years, ctech in CTechs
    CMSM0[enduse,tech,ctech,ec,area,year] = -170
  end
  ctech = Select(CTech,"Coal")
  for year in years
    CMSM0[enduse,tech,ctech,ec,area,year] = -5.00
  end

  WriteDisk(db,"$CalDB/CMSM0",CMSM0)
end

function PolicyControl(db)
  @info "Ind_MS_IronSteel_RefA - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
