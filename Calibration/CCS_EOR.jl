#
# CCS_EOR.jl
#
using EnergyModel

module CCS_EOR

import ...EnergyModel: ReadDisk,WriteDisk,Select
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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EORCreditMultiplier::VariableArray{3} = ReadDisk(db,"MEInput/EORCreditMultiplier") # [ECC,Area,Year] EOR Credit Multiplier (Tonnes/Tonnes)
  EORFraction::VariableArray{3} = ReadDisk(db,"MEInput/EORFraction") # [ECC,Area,Year] Fraction of Sequestered CO2 used for EOR (Tonnes/Tonnes)
  EORLimit::VariableArray{2} = ReadDisk(db,"MEInput/EORLimit") # [Area,Year] Maximum Amonut of Sequestered CO2 which can be used for EOR (Tonnes)
  EORRate::VariableArray{2} = ReadDisk(db,"MEInput/EORRate") # [Area,Year] EOR Production per unit of Sequestered CO2 (TBtu/Tonne)
  EORDmd::VariableArray{2} = ReadDisk(db,"$Input/EORDmd") # [Area,Year] Demand for Motors for EOR (TBtu/TBtu)
  EORDInv::VariableArray{2} = ReadDisk(db,"$Input/EORDInv") # [Area,Year] Device Investments for EOR (M$/TBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,ECC,ECCs,Years) = data
  (;EORCreditMultiplier,EORFraction,EORLimit,EORRate,EORDmd,EORDInv,xInflation) = data

  @. EORCreditMultiplier = 0

  WriteDisk(db,"MEInput/EORCreditMultiplier",EORCreditMultiplier)

  #
  # Fraction of Sequestered CO2 used for EOR (Tonnes Used/Tonnes Produced)
  #
  @. EORFraction = 0.00

  #
  # In AB, only Fertilizer and Refinery CO2 is used for EOR
  #
  eccs = Select(ECC,["Fertilizer","Petroleum"])
  AB = Select(Area,"AB")

  for year in Years, ecc in eccs
    EORFraction[ecc,AB,year] = 1.0
  end

  #
  # In SK, 40% of Sequestering is for EOR
  #
  SK = Select(Area,"SK")
  for year in Years, ecc in ECCs
    EORFraction[ecc,SK,year] = 0.40
  end

  WriteDisk(db,"MEInput/EORFraction",EORFraction)

  #
  # Maximum Amonut of Sequestered CO2 which can be used for EOR (Tonnes)
  #
  @. EORLimit = 0.00
  areas = Select(Area,["AB","SK"])
  for year in Years, area in areas
    EORLimit[area,year] = 1e12
  end

  WriteDisk(db,"MEInput/EORLimit",EORLimit)

  #
  # EOR Production per unit of Sequestered CO2 (TBtu/Tonne)
  #
  #
  # Increased Oil Production from EOR:
  # From Glasha Obrekht, "I found out that we have used a ratio from the
  # US EPA study
  # (http://www.netl.doe.gov/research/energy-analysis/publications/details?pub=df02ffba-6b4b-4721-a7b4-04a505a19185)
  # of 3 additional barrels of oil for 1 t of CO2 in the cost benefit analysis for
  # boundary dam CCS (http://www.gazette.gc.ca/rp-pr/p2/2012/index-eng.html)
  # Given that the 3 bbl/tCO2 was used in the official RIAS, I think we
  # should be switching to that.
  #
  #     3.00 barrels per tonne of CO2
  #    38.51 TJ/1000 Cubic Metres
  #     6.29 Barrels/Cubic Metre
  # 1.054615 PJ per TBtu
  #
  @. EORRate = 3.00 / 6.29 * 38.51 / 1.054615 / 1000000

  WriteDisk(db,"MEInput/EORRate",EORRate)

  @. EORDmd = 0

  #
  # AB with Pipleine and EOR requires 439 GWh of pumps/motors
  # to produce 29.6 TBtu of oil.
  #
  for year in Years
    EORDmd[AB,year] = (439 * 3412 / 1e6) / 29.6
    EORDmd[SK,year] = 0.015
  end

  WriteDisk(db,"$Input/EORDmd",EORDmd)

  @. EORDInv = 0.00

  #
  # For AB, Pipeline is $1.2B, motors and pumps $53M in 2010 CN$
  # to produce 29.6 TBtu of oil.
  #
  for year in Years
    EORDInv[AB,year] = (1200 + 53) / 29.6 / xInflation[AB,Yr(2010)]
    EORDInv[SK,year] = 53 / 29.6 / xInflation[SK,Yr(2010)]
  end

  WriteDisk(db,"$Input/EORDInv",EORDInv)

end

function CalibrationControl(db)
  @info "CCS_EOR.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
