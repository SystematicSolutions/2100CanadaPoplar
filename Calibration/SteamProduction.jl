#
# SteamProduction.jl - Convert Supply dollar values to apporpiate currency
#
using EnergyModel

module SteamProduction

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  StCC::VariableArray{2} = ReadDisk(db,"SInput/StCC") # [Area,Year] Capital Cost of Steam Capacity (Real $/mmBtu/Yr)
  StCCR::VariableArray{2} = ReadDisk(db,"SInput/StCCR") # [Area,Year] Capital Charge Rate of Steam Capacity ($/($/Yr))
  StHPRatio::VariableArray{2} = ReadDisk(db,"SInput/StHPRatio") # [Area,Year] Steam Capacity Heat-to-Power Ratio (MW/MW)
  StOMC::VariableArray{2} = ReadDisk(db,"SInput/StOMC") # [Area,Year] O&M Cost of Steam Production (Real $/mmBtu)
  StSubsidy::VariableArray{2} = ReadDisk(db,"SInput/StSubsidy") # [Area,Year] Steam Subsidy from Electric Sales or Government (Local/mmBtu)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function SupplyCalibration(db)
  data = SControl(; db)
  (;Input) = data
  (;Areas,Years) = data
  (;StCC,StCCR,StHPRatio,StOMC,StSubsidy,xExchangeRate,xInflation) = data
  # 
  # Capital cost = 2000 US$30/MMbtu/year (this already has the utilization
  # factor (40%) in it).  This is actually based on a Swedish unit 
  # (via a file called dbaFile1544.doc), but makes comparative sense
  # to US utility boiler costs.  Capital costs are assumed to be 10% of full costs. Jeff Amlin 2/24/22
  # 
  for area in Areas, year in Years
    StCC[area,year]=30*0.1*xExchangeRate[area,Yr(2000)]/xInflation[area,Yr(2000)]
  end
  WriteDisk(db,"$Input/StCC",StCC)
  # 
  # O&M costs are 2000 US$2.50/mmbtu (via tech_brief_true_cost.pdf)
  # 
  for area in Areas, year in Years
    StOMC[area,year]=2.50*xExchangeRate[area,Yr(2000)]/xInflation[area,Yr(2000)]
  end
  WriteDisk(db,"$Input/StOMC",StOMC)
  # 
  # Capital Charge Rate
  # 
  for area in Areas, year in Years
    StCCR[area,year]=0.12
  end
  WriteDisk(db,"$Input/StCCR",StCCR)
  # 
  # Heat-to-Power Ratio (Gas CC)
  # 
  for area in Areas, year in Years
    StHPRatio[area,year]=1.0
  end
  WriteDisk(db,"$Input/StHPRatio",StHPRatio)
  #
  for area in Areas, year in Years
    StSubsidy[area,year]=0
  end
  WriteDisk(db,"$Input/StSubsidy",StSubsidy)
  
end

function CalibrationControl(db)
  @info "SteamProduction.jl - CalibrationControl"

  SupplyCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
