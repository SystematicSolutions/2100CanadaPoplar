#
# HistoricalElectricLoads.jl
#
using EnergyModel

module HistoricalElectricLoads

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct HistoricalElectricLoadsCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MinPurF::VariableArray{3} = ReadDisk(db,"SInput/MinPurF") # [ECC,Area,Year] Minimum Fraction of Electricity which is Purchased (GWh/GWh)
  xCgEC::VariableArray{3} = ReadDisk(db,"SInput/xCgEC") # [ECC,Area,Year] Cogeneration by Economic Category (GWh/Yr)
  xCgGen::VariableArray{4} = ReadDisk(db,"SInput/xCgGen") # [Fuel,ECC,Area,Year] Cogeneration Generation (GWh/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Exogenous Energy Demands (tBtu)
  xSaEC::VariableArray{3} = ReadDisk(db,"SInput/xSaEC") # [ECC,Area,Year] Historical Electricity Sales (GWh/Yr)
  xPSoECC::VariableArray{3} = ReadDisk(db,"SInput/xPSoECC") # [ECC,Area,Year] Power Sold to Grid (GWh)

  # Scratch Variables
  xElecDmd::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Electricity Gross Demands (GWh/Yr)
  xPurECC::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Purchases from Electric Grid (GWh)
end

function HCalibration(db)
  data = HistoricalElectricLoadsCalib(; db)
  (;Areas,ECCs,Fuel,Fuels,Years) = data
  (;MinPurF,xCgEC,xCgGen,xEuDemand,xSaEC,xPSoECC) = data
  (;xElecDmd,xPurECC) = data

  #
  # Electricity Demands (before cogeneration)
  #
  fuels = Select(Fuel,["Electric","Solar"])
  for ecc in ECCs, area in Areas, year in Years
    xElecDmd[ecc,area,year] = sum(xEuDemand[fuel,ecc,area,year] for fuel in fuels) /
                              3412 * 1e6
  end

  #Select Fuel*
  #
  # Cogeneration Generation
  #
  for ecc in ECCs, area in Areas, year in Years
    xCgEC[ecc,area,year] = sum(xCgGen[fuel,ecc,area,year] for fuel in Fuels)
  end

  WriteDisk(db,"SInput/xCgEC",xCgEC)

  #
  # Electricity Purchased from Grid
  #
  for ecc in ECCs, area in Areas, year in Years
    xPurECC[ecc,area,year] = max(xElecDmd[ecc,area,year] - xCgEC[ecc,area,year],
                                 xElecDmd[ecc,area,year] * MinPurF[ecc,area,year])
  end

  #
  # Power Sold back to Grid
  #
  for ecc in ECCs, area in Areas, year in Years
    xPSoECC[ecc,area,year] = max(xCgEC[ecc,area,year] + xPurECC[ecc,area,year] -
                                 xElecDmd[ecc,area,year], 0)
  end

  WriteDisk(db,"SInput/xPSoECC",xPSoECC)

  #
  # Electric Sales
  #
  for ecc in ECCs, area in Areas, year in Years
    xSaEC[ecc,area,year] = xElecDmd[ecc,area,year] - xCgEC[ecc,area,year] +
                           xPSoECC[ecc,area,year]
  end

  WriteDisk(db,"SInput/xSaEC",xSaEC)

end

function CalibrationControl(db)
  @info "HistoricalElectricLoads.jl - CalibrationControl"

  HCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
