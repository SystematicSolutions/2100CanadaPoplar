#
# AdjustTransFungible.jl - Fungible Demands Market Share Calibration 
#
using EnergyModel

module AdjustTransFungible

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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

  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,EC,Enduses,Fuels,Tech) = data
  (;xDmFrac) = data
  
  #*
  #************************
  #*
  #* Hybrid Vehicles 
  #*
  #*xDmFrac(Eu,F,LDVHybrid,EC,A,Y)=xDmFrac(Eu,F,LDVGasoline,EC,A,Y)
  #*xDmFrac(Eu,F,LDTHybrid,EC,A,Y)=xDmFrac(Eu,F,LDTGasoline,EC,A,Y)  
  #*
  #************************
  #*
  #* Adjust Commercial Off-Road for Territories between 1985 and 1995
  #*
  ec = Select(EC,"CommercialOffRoad")
  tech = Select(Tech,"OffRoad")
  
  area = Select(Area,"YT")
  years = collect(Yr(1985):Yr(1995))
  for enduse in Enduses, fuel in Fuels, year in years
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,Yr(1996)]
  end
  
  area = Select(Area,"NT")
  for enduse in Enduses, fuel in Fuels, year in years
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,Yr(1996)]
  end

  area = Select(Area,"NU")
  years = collect(Yr(1985):Yr(1999))
  for enduse in Enduses, fuel in Fuels, year in years
    xDmFrac[enduse,fuel,tech,ec,area,year] = xDmFrac[enduse,fuel,tech,ec,area,Yr(2000)]
  end
  
  WriteDisk(db, "$Input/xDmFrac",xDmFrac)

end

function CalibrationControl(db)
  @info "AdjustTransFungible.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
