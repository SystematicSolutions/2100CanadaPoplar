#
# Trans_OffRoad_Electrify.jl 
#
# This txp electrifies small spark ignition equipment in the Residential off-road sector.
# Detailed 2021 emissions from the NIR are used to estimate a fraction of the
# sectoral emissions attributable to these engines, mostly lawn and garden
# equipment like lawnmowers, leaf blowers etc.
# The electrification assumption uses a Statscan survey to estimate uptake
# of battery and electric equipment.
# Electrification rates are held constant in the projections
# Matt Lewis - June 6 2025
#

using EnergyModel

module Trans_OffRoad_Electrify

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
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
end

function AddElectric(db,enduses,techs,ecs,areas,years,ElectricGoal)
  data = TControl(; db)
  (; Input) = data
  (; Fuel) = data
  (; DmFrac,DmFracMax,DmFracMin,xDmFrac) = data

  electric = Select(Fuel,"Electric")
  non_electric_fuels = Select(Fuel,!=("Electric"))

  for enduse in enduses, ec in ecs, tech in techs, area in areas, year in years
    xDmFrac[enduse,electric,tech,ec,area,year] = max(ElectricGoal,xDmFrac[enduse,electric,tech,ec,area,year])
    DmFracMin[enduse,electric,tech,ec,area,year] = max(xDmFrac[enduse,electric,tech,ec,area,year],DmFracMin[enduse,electric,tech,ec,area,year])
    DmFracMax[enduse,electric,tech,ec,area,year] = max(xDmFrac[enduse,electric,tech,ec,area,year],DmFracMax[enduse,electric,tech,ec,area,year])
    for fuel in non_electric_fuels
      if xDmFrac[enduse,fuel,tech,ec,area,year] > 0
        xDmFrac[enduse,fuel,tech,ec,area,year] = max(0,max((1-ElectricGoal)*DmFrac[enduse,fuel,tech,ec,area,year],(1-ElectricGoal)*xDmFrac[enduse,fuel,tech,ec,area,year]))
        DmFracMin[enduse,fuel,tech,ec,area,year] = max(0,max(xDmFrac[enduse,fuel,tech,ec,area,year],(1-ElectricGoal)*DmFracMin[enduse,fuel,tech,ec,area,year]))
        DmFracMax[enduse,fuel,tech,ec,area,year] = max(0,max(xDmFrac[enduse,fuel,tech,ec,area,year],(1-ElectricGoal)*DmFracMax[enduse,fuel,tech,ec,area,year]))
      end
    end
  end

  WriteDisk(db,"$Input/xDmFrac",xDmFrac)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$Input/DmFracMax",DmFracMax)

end

function TransPolicy(db)
  data = TControl(; db)
  (; EC,Enduses,Nation,Tech) = data
  (; ANMap) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  tech = Select(Tech,"OffRoad")
  ec = Select(EC,"ResidentialOffRoad")
  years = collect(Future:Final)
  
  ElectricGoal = 0.074
  AddElectric(db,Enduses,tech,ec,areas,years,ElectricGoal)

end

function PolicyControl(db)
  @info "Trans_OffRoad_Electrify.jl - PolicyControl"
  TransPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
