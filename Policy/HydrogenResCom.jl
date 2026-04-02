#
# HydrogenResCom.jl - from HydrogenMandate
#

using EnergyModel

module HydrogenResCom

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  DmFracTime::VariableArray{6} = ReadDisk(db,"$Input/DmFracTime") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Adjustment Time (Years)
end

function ResPolicy(db)
  data = RControl(; db)
  (; Input) = data
  (; Area,Areas,EC,ECs,Enduse,Enduses,Fuel,Fuels,Tech,Techs,Year) = data
  (; DmFracMax,DmFracMin,DmFracTime) = data

  Hydrogen = Select(Fuel,"Hydrogen")
  Gas = Select(Tech,"Gas")

  #
  # Canada Provinces, exclude Territories
  #
  # Renewable Natural Gas
  #
  BC = Select(Area,"BC")
  for ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2026)] = 0.0004
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2029)] = 0.065
  end
  #
  years = collect(Yr(2027):Yr(2028))
  for year in years, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,year] = DmFracMax[enduse,Hydrogen,Gas,ec,BC,year-1]+
      (DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2029)]-DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2026)])/(2029-2026)
  end
  years = collect(Yr(2029):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,year] = DmFracMax[enduse,Hydrogen,Gas,ec,BC,year-1]
  end
  years = collect(Yr(2026):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMin[enduse,Hydrogen,Gas,ec,BC,year] = DmFracMax[enduse,Hydrogen,Gas,ec,BC,year]
    DmFracTime[enduse,Hydrogen,Gas,ec,BC,year] = 1.0
  end

  areas=Select(Area,["NB","NS","ON"])
  for area in areas, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,area,Yr(2026)] = 0.00008
    DmFracMax[enduse,Hydrogen,Gas,ec,area,Yr(2029)] = 0.0008
  end
  years = collect(Yr(2027):Yr(2028))
  for year in years, area in areas, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,area,year] = DmFracMax[enduse,Hydrogen,Gas,ec,area,year-1]+
      (DmFracMax[enduse,Hydrogen,Gas,ec,area,Yr(2029)]-DmFracMax[enduse,Hydrogen,Gas,ec,area,Yr(2026)])/(2029-2026)
  end
  years = collect(Yr(2029):Final)
  for year in years, area in areas, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,area,year] = DmFracMax[enduse,Hydrogen,Gas,ec,area,year-1]
  end
  years = collect(Yr(2026):Final)
  for year in years, area in areas, ec in ECs, enduse in Enduses
    DmFracMin[enduse,Hydrogen,Gas,ec,area,year] = DmFracMax[enduse,Hydrogen,Gas,ec,area,year]
    DmFracTime[enduse,Hydrogen,Gas,ec,area,year] = 1.0
  end

  AB = Select(Area,"AB")
  for ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2026)] = 0.0004
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2028)] = 0.07
  end
  #
  for ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2027)] = DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2026)]+
      (DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2028)]-DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2026)])/(2028-2026)
  end
  years = collect(Yr(2028):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,year] = DmFracMax[enduse,Hydrogen,Gas,ec,AB,year-1]
  end
  #
  years = collect(Yr(2026):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMin[enduse,Hydrogen,Gas,ec,AB,year] = DmFracMax[enduse,Hydrogen,Gas,ec,AB,year]
    DmFracTime[enduse,Hydrogen,Gas,ec,AB,year] = 1.0
  end

  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$Input/DmFracTime",DmFracTime)
end


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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  DmFracTime::VariableArray{6} = ReadDisk(db,"$Input/DmFracTime") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Adjustment Time (Years)
end

function ComPolicy(db)
  data = CControl(; db)
  (; Input) = data
  (; Area,Areas,EC,ECs,Enduse,Enduses,Fuel,Fuels,Tech,Techs,Year) = data
  (; DmFracMax,DmFracMin,DmFracTime) = data

  Hydrogen = Select(Fuel,"Hydrogen")
  Gas = Select(Tech,"Gas")
  #
  # Canada Provinces, exclude Territories
  #
  # Renewable Natural Gas
  #
  BC = Select(Area,"BC")
  for ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2026)] = 0.0004
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2029)] = 0.06
  end
  years = collect(Yr(2027):Yr(2028))
  for year in years, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,year] = DmFracMax[enduse,Hydrogen,Gas,ec,BC,year-1]+
      (DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2029)]-DmFracMax[enduse,Hydrogen,Gas,ec,BC,Yr(2026)])/(2029-2026)
  end
  years = collect(Yr(2029):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,BC,year] = DmFracMax[enduse,Hydrogen,Gas,ec,BC,year-1]
  end
  #
  years = collect(Yr(2026):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMin[enduse,Hydrogen,Gas,ec,BC,year] = DmFracMax[enduse,Hydrogen,Gas,ec,BC,year]
    DmFracTime[enduse,Hydrogen,Gas,ec,BC,year] = 1.0
  end

  AB = Select(Area,"AB")
  for ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2026)] = 0.0004
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2028)] = 0.07
  end
  for ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2027)] = DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2026)]+
      (DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2028)]-DmFracMax[enduse,Hydrogen,Gas,ec,AB,Yr(2026)])/(2028-2026)
  end
  years = collect(Yr(2028):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMax[enduse,Hydrogen,Gas,ec,AB,year] = DmFracMax[enduse,Hydrogen,Gas,ec,AB,year-1]
  end
  #
  years = collect(Yr(2026):Final)
  for year in years, ec in ECs, enduse in Enduses
    DmFracMin[enduse,Hydrogen,Gas,ec,AB,year] = DmFracMax[enduse,Hydrogen,Gas,ec,AB,year]
    DmFracTime[enduse,Hydrogen,Gas,ec,AB,year] = 1.0
  end

  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$Input/DmFracTime",DmFracTime)
end

function PolicyControl(db)
  @info "HydrogenResCom.jl - PolicyControl"
  ResPolicy(db)
  ComPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
