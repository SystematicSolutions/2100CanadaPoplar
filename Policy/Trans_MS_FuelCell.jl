#
# Trans_MS_FuelCell.txp
#

using EnergyModel

module Trans_MS_FuelCell

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TransMSFuelCellData
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
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)
end

function TransPolicyFuelCell(db)
  data = TransMSFuelCellData(; db)
  (; CalDB) = data
  (; Area,EC,Enduse,Tech,Techs) = data
  (; xMMSF) = data

  enduses = Select(Enduse,"Carriage")
  ecs = Select(EC,"Freight")
  areas = Select(Area,"AB")
  HDV8FuelCell = Select(Tech,"HDV8FuelCell")
  HDV8Diesel = Select(Tech,"HDV8Diesel")

  #
  # Fuel Cell Market Shares
  #
  for area in areas, ec in ecs, enduse in enduses
    xMMSF[enduse,HDV8FuelCell,ec,area,Yr(2025)] = xMMSF[enduse,HDV8Diesel,ec,area,Yr(2025)]*0.0477*0.9550
  end
  years = collect(Yr(2026):Yr(2027))
  for year in years, area in areas, ec in ecs, tech in Techs, enduse in enduses
    xMMSF[enduse,tech,ec,area,year] = xMMSF[enduse,tech,ec,area,year-1]
  end
  for year in years, area in areas, ec in ecs, enduse in enduses
    xMMSF[enduse,HDV8Diesel,ec,area,year] = xMMSF[enduse,HDV8Diesel,ec,area,year]-xMMSF[enduse,HDV8FuelCell,ec,area,year]
  end

  WriteDisk(DB,"$CalDB/xMMSF",xMMSF)
end

function PolicyControl(db)
  @info ("Trans_MS_FuelCell.jl - PolicyControl")
  TransPolicyFuelCell(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
