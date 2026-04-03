#
# AdjustPetroleum_ON.jl 
#
using EnergyModel

module AdjustPetroleum_ON

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

  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)

  # Scratch Variables
end

function IndCalibration(db)
  data = IControl(; db)
  (;CalDB,Input) = data
  (;Area,EC,Enduse) = data
  (;Fuels,Tech) = data
  (;DmFracMin,MMSM0,xDmFrac) = data
  
  years = collect(Future:Final)
  Petroleum = Select(EC,"Petroleum")
  ON = Select(Area, "ON")
  Heat = Select(Enduse, "Heat")
  Oil = Select(Tech, "Oil")
  
  @. MMSM0[Heat, Oil, Petroleum, ON, years]=-4.5
  
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  
  for year in years
    @. DmFracMin[Heat, Fuels, Oil, Petroleum, ON, year] = xDmFrac[Heat, Fuels, Oil, Petroleum, ON, Yr(2018)]
  end
  
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)

end

function CalibrationControl(db)
  @info "AdjustPetroleum_ON.jl - CalibrationControl"

  IndCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
