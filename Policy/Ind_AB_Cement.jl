#
# Ind_AB_Cement.jl - Simulates CleanBC investments into decarbonizing the cement sector.
# Typically aligned to the base case, so emissions reductions are assumed to be non-incremental.
# Biomass is substituted for natural gas in the BC cement sector. Aligned to expected emissions reductions from
# British Columbia.
#

using EnergyModel

module Ind_AB_Cement

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
  DInvTechExo::VariableArray{5} = ReadDisk(db,"$Input/DInvTechExo") # [Enduse,Tech,EC,Area,Year] device Exogenous Investments (M$/Yr)
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
  PolicyCost::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Cost ($/TBtu)
end

function IndPolicy(db::String)
  data = IControl(; db)
  (; Input) = data    
  (; Area,EC,Enduse,Fuel,Nation,Tech) = data 
  (; DInvTechExo,DmFracMin,DmFracMax) = data
  (; PolicyCost,xDmFrac,xInflation) = data

  #
  # Substitution of biomass for natural gas occurs through the
  # provision of process heat used in cement
  #
  enduse = Select(Enduse,"Heat")
  ec = Select(EC,"Cement")
  area = Select(Area,"AB")
  tech = Select(Tech,"Gas")

  #
  # Set the demand fraction for biomass in each based on what
  # would be approximately needed to achieve the emissions reductions
  # calculated or expected from the project
  #
  fuel = Select(Fuel,"NaturalGas")
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2024)]=0.7790
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2025)]=0.6819
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2026)]=0.6134
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2027)]=0.7280
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2028)]=0.7533
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]=0.7274
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2030)]=0.6995
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2031)]=0.6747
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2032)]=0.6502
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2033)]=0.6252
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2034)]=0.6242
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2035)]=0.6277
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2036)]=0.6312
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2037)]=0.6343
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2038)]=0.6373
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2039)]=0.6403
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2040)]=0.6445

  fuel = Select(Fuel,"Biomass")
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2024)]=0.2199
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2025)]=0.3170
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2026)]=0.3855
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2027)]=0.3855
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2028)]=0.2461
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2029)]=0.2720
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2030)]=0.2999
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2031)]=0.3246
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2032)]=0.3491
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2033)]=0.3742
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2034)]=0.3751
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2035)]=0.3716
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2036)]=0.3681
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2037)]=0.3650
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2038)]=0.3620
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2039)]=0.3589
  xDmFrac[enduse,fuel,tech,ec,area,Yr(2040)]=0.3548

  # Now ensure that the biomass and natural gas price demand fractions
  # do not fall below what has been previously specified in this txt
  #
  # Assuming policy continues through 2050 - Ian
  #
  years = collect(Yr(2024):Yr(2040))
  for year in years
    DmFracMin[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year]
  end
  years = collect(Yr(2041):Yr(2050))
  for year in years
    DmFracMin[enduse,fuel,tech,ec,area,year] = DmFracMin[enduse,fuel,tech,ec,area,year-1]
  end

  fuel = Select(Fuel,"NaturalGas")
  for year in years
    DmFracMax[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,year]
  end
  years = collect(Yr(2041):Yr(2050))
  for year in years
    #TODOJulia - Right side should probably have 'year-1'. Keeping Promula bug for now
    DmFracMax[enduse,fuel,tech,ec,area,year] = DmFracMax[enduse,fuel,tech,ec,area,year]
  end
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  
  #
  # Program Costs $M  
  #  
  PolicyCost[Yr(2024)] = 74.20
  DInvTechExo[enduse,tech,ec,area,Yr(2024)] = DInvTechExo[enduse,tech,ec,area,Yr(2024)]+
      PolicyCost[Yr(2024)]/xInflation[area,Yr(2024)]/2
  WriteDisk(db,"$Input/DInvTechExo",DInvTechExo)

end

function PolicyControl(db)
  @info "Ind_AB_Cement.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
