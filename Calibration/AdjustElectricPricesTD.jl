#
# AdjustElectricPricesTD.jl
# This file simulates the growth in the cost of electricity distribution and transmission.
#
using EnergyModel

module AdjustElectricPricesTD

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  Last=HisTime-ITime+1

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  PEDC::VariableArray{3} = ReadDisk(db,"$CalDB/PEDC") # [ECC,Area,Year] Real Elect. Delivery Chg. ($/MWh)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  xPE::VariableArray{3} = ReadDisk(db,"EInput/xPE") # [ECC,Area,Year] Historical Retail Electricity Price (Real $/MWh)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
end

function ElecPolicy(db)
  data = EControl(; db)
  (;CalDB,Last) = data
  (;Area,ECCs,Nation) = data
  (;ANMap,PEDC,xPE,xInflation) = data

  #
  # Electric Delivery Charge (PEDC) grows to reflect increasing
  # Transmission and Distribution Costs in Canada
  #
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  Future5=Last+5
  Future6=Last+6
  years=collect(Future6:Final)
  for year in years, area in areas, ecc in ECCs
    PEDC[ecc,area,year] = PEDC[ecc,area,year-1] + xPE[ecc,area,Future5]*0.018
  end
  #
  # NL has industrial prices lower than the average cost of power resulting
  # in a negative delivery charge.  Set delivery charge to zero in forecast.
  # Jeff Amlin 8/31/16
  #
  NL = Select(Area,"NL")
  years=collect(Future6:Final)
  for year in years, ecc in ECCs
    PEDC[ecc,NL,year] = max(PEDC[ecc,NL,year],0)
  end
  #
  # NU has prices higher than the average cost of power resulting in a
  # negative delivery charge.  Increase the delivery charge in 2021 as
  # hydro unit comes online. Jeff Amlin 8/31/16
  #
  NU = Select(Area,"NU")
  years=collect(Yr(2021):Final)
  for year in years, ecc in ECCs
    PEDC[ecc,NU,year] = PEDC[ecc,NU,year] + 100/xInflation[NU,year]
  end
  WriteDisk(db,"$CalDB/PEDC",PEDC)
end


function CalibrationControl(db)
  @info "AdjustElectricPricesTD.jl - CalibrationControl"

  ElecPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
