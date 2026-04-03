#
# IndCogenSoldToGrid.jl
#
using EnergyModel

module IndCogenSoldToGrid

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

  MinPurF::VariableArray{3} = ReadDisk(db,"SInput/MinPurF") # [ECC,Area,Year] Minimum Fraction of Electricity which is Purchased (GWh/GWh)

  # Scratch Variables
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,ECCs) = data
  (;MinPurF) = data

  area = Select(Area,("AB"))
  years = collect(Yr(2010):Final)
  
  for year in years, ecc in ECCs
    MinPurF[ecc,area,year] = 0.05
  end

  WriteDisk(db, "SInput/MinPurF",MinPurF)

end

function CalibrationControl(db)
  @info "IndCogenSoldToGrid.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
