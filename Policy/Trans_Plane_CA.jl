#
# Trans_Plane_CA.jl - 10% of aviation fuel demand is met by
# electricity (batteries) or hydrogen (fuel cells) in 2045. Sustainable
# aviation fuel meets most or rest of aviation fuel demand that has
# not already transitioned to hydrogen or batteries
#

using EnergyModel

module Trans_Plane_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"

  Input::String = "TInput"
  Outpt::String = "TOutput"
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
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
end

function TransPolicy(db)
  data = TControl(; db)
  (; Input) = data
  (; Area,EC) = data
  (; Fuel) = data
  (; Tech) = data
  (; DmFracMin,xDmFrac) = data
  (;) = data

  CA = Select(Area,"CA")

  #
  ########################
  #
  # Air Passenger
  #
  ec = Select(EC,"AirPassenger")

  #
  # Assume small planes use battery and large planes use H2 - Ian
  # Use Biodiesel for small planes instead of Ethanol?
  #  
  tech = Select(Tech,"PlaneGasoline")
  years = collect(Yr(2045):Final)
  Electric = Select(Fuel,"Electric")
  Biodiesel = Select(Fuel,"Biodiesel")
  for year in years
    DmFracMin[1,Electric,tech,ec,CA,year] = 0.1
    xDmFrac[1,Electric,tech,ec,CA,year] = 0.1
    DmFracMin[1,Biodiesel,tech,ec,CA,year] = 0.9
    xDmFrac[1,Biodiesel,tech,ec,CA,year] = 0.9
  end

  #
  # Interpolate from 2021
  #  
  fuels = Select(Fuel,["Electric","Biodiesel"])
  years = collect(Yr(2022):Yr(2044))
  for year in years, fuel in fuels
    DmFracMin[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year-1]+
      (DmFracMin[1,fuel,tech,ec,CA,Yr(2045)]-DmFracMin[1,fuel,tech,ec,CA,Yr(2021)])/
        (2045-2021)
    xDmFrac[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year]
  end

  #
  ########################
  #
  tech = Select(Tech,"PlaneJetFuel")
  years = collect(Yr(2045):Final)
  Hydrogen = Select(Fuel,"Hydrogen")
  Biojet = Select(Fuel,"Biojet")
  for year in years
    DmFracMin[1,Hydrogen,tech,ec,CA,year] = 0.1
    xDmFrac[1,Hydrogen,tech,ec,CA,year] = 0.1
    DmFracMin[1,Biojet,tech,ec,CA,year] = 0.9
    xDmFrac[1,Biojet,tech,ec,CA,year] = 0.9
  end

  #
  # Interpolate from 2021
  #  
  fuels = Select(Fuel,["Hydrogen","Biojet"])
  years = collect(Yr(2022):Yr(2044))
  for year in years, fuel in fuels
    DmFracMin[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year-1]+
      (DmFracMin[1,fuel,tech,ec,CA,Yr(2045)]-DmFracMin[1,fuel,tech,ec,CA,Yr(2021)])/
        (2045-2021)
    xDmFrac[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year]
  end

  #
  ########################
  #
  # Air Freight
  #
  ec = Select(EC,"AirFreight")

  #
  # Assume small planes use battery and large planes use H2 - Ian
  # Use Biodiesel for small planes instead of Ethanol?
  # 
  tech = Select(Tech,"PlaneGasoline")
  years = collect(Yr(2045):Final)
  for year in years
    DmFracMin[1,Electric,tech,ec,CA,year] = 0.1
    xDmFrac[1,Electric,tech,ec,CA,year] = 0.1
    DmFracMin[1,Biodiesel,tech,ec,CA,year] = 0.9
    xDmFrac[1,Biodiesel,tech,ec,CA,year] = 0.9
  end

  #
  # Interpolate from 2021
  # 
  fuels = Select(Fuel,["Electric","Biodiesel"])
  years = collect(Yr(2022):Yr(2044))
  for year in years, fuel in fuels
    DmFracMin[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year-1]+
      (DmFracMin[1,fuel,tech,ec,CA,Yr(2045)]-DmFracMin[1,fuel,tech,ec,CA,Yr(2021)])/
        (2045-2021)
    xDmFrac[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year]
  end

  #
  ########################
  #
  tech = Select(Tech,"PlaneJetFuel")
  years = collect(Yr(2045):Final)
  for year in years
    DmFracMin[1,Hydrogen,tech,ec,CA,year] = 0.1
    xDmFrac[1,Hydrogen,tech,ec,CA,year] = 0.1
    DmFracMin[1,Biojet,tech,ec,CA,year] = 0.9
    xDmFrac[1,Biojet,tech,ec,CA,year] = 0.9
  end

  # 
  # Interpolate from 2021
  #  
  fuels = Select(Fuel,["Hydrogen","Biojet"])
  years = collect(Yr(2022):Yr(2044))
  for year in years, fuel in fuels
    DmFracMin[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year-1]+
      (DmFracMin[1,fuel,tech,ec,CA,Yr(2045)]-DmFracMin[1,fuel,tech,ec,CA,Yr(2021)])/
        (2045-2021)
    xDmFrac[1,fuel,tech,ec,CA,year] = DmFracMin[1,fuel,tech,ec,CA,year]
  end

  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
end

function PolicyControl(db)
  @info "Trans_Plane_CA.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
