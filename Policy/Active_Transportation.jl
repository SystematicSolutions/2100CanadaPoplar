#
# Active_Transportation.jl - Adjustments to reflect Active Transportation Investments
#
#
# Adjustment represents impact of $500 million dollars into
# bike lanes and other Active Transportation measures
# estimated at 240 KT of reductions in 2030 by Infrastructure
#
# Edited for Ref25, $400 million was the final quantity, so
# must confirm the reductions and target 192 KT
# Matt Lewis June 7, 2024
#

using EnergyModel

module Active_Transportation

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ActiveTransportationData
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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CERSM::VariableArray{4} = ReadDisk(db,"$CalDB/CERSM") # [Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)

  # Scratch Variables
  Adjust::VariableArray{1} = zeros(Float32,length(Year)) # [Year]
end

function TransPolicyActive(db)
  data = ActiveTransportationData(; db)
  (; CalDB) = data
  (; Areas,EC,Enduses,Nation,Years) = data 
  (; Adjust,ANMap,CERSM) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  ecs = Select(EC,"Passenger")
  
  for year in Years
    Adjust[year] = 1.00
  end
  Adjust[Yr(2026)] = 0.9995
  Adjust[Yr(2027)] = 0.999
  Adjust[Yr(2028)] = 0.9985
  Adjust[Yr(2029)] = 0.9975
  years = collect(Yr(2030):Final)
  for year in years
    Adjust[year] = 0.9967
  end

  for enduse in Enduses, ec in ecs, area in areas, year in Years
    CERSM[enduse,ec,area,year] = CERSM[enduse,ec,area,year]*Adjust[year]
  end
  
  WriteDisk(db,"$CalDB/CERSM",CERSM)
end

function PolicyControl(db)
  @info "Active_Transportation.jl - PolicyControl"
  TransPolicyActive(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
