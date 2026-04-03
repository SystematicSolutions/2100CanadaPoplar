#
# CogenFraction.jl - Cogeneration Electric Tech is mapped to fuels 
#
using EnergyModel

module CogenFraction

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
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
  CgFrac::VariableArray{5} = ReadDisk(db,"$Input/CgFrac") # [Fuel,Tech,EC,Area,Year] Cogeneration Demands Fuel/Tech Split (Fraction)
end

function RCalibration(db)
  data = RControl(; db)
  (;Input,ECs,Fuel,Nation,Tech,Years) = data
  (;ANMap,CgFrac) = data

  # 
  # Cogeneration Electric Tech is mapped to fuels
  # 
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  tech = Select(Tech,"Electric")
  Electric = Select(Fuel,"Electric")
  Wind = Select(Fuel,"Wind")
  Hydro = Select(Fuel,"Hydro")

  #
  # Remove Electricity as a Fuel for Cogeneration
  #
  @. CgFrac[Electric,tech,ECs,areas,Years] = 0

  #
  # Specify Wind fraction of Cogeneration Electric Tech
  #
  @. CgFrac[Wind,tech,ECs,areas,Years] = 1

  #
  # Hydro is the non-Wind fraction of Cogeneration Electric Tech
  #
  @. CgFrac[Hydro,tech,ECs,areas,Years] = 1-CgFrac[Wind,tech,ECs,areas,Years]

  WriteDisk(db,"$Input/CgFrac",CgFrac)
  
end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
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
  CgFrac::VariableArray{5} = ReadDisk(db,"$Input/CgFrac") # [Fuel,Tech,EC,Area,Year] Cogeneration Demands Fuel/Tech Split (Fraction)
end

function CCalibration(db)
  data = CControl(; db)
  (;Input,ECs,Tech,Fuel,Nation,Years) = data
  (;ANMap,CgFrac) = data

  # 
  # Cogeneration Electric Tech is mapped to fuels
  # 
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  tech = Select(Tech,"Electric")
  Electric = Select(Fuel,"Electric")
  Wind = Select(Fuel,"Wind")
  Hydro = Select(Fuel,"Hydro")

  #
  # Remove Electricity as a Fuel for Cogeneration
  #
  @. CgFrac[Electric,tech,ECs,areas,Years] = 0

  #
  # Specify Wind fraction of Cogeneration Electric Tech
  #
  @. CgFrac[Wind,tech,ECs,areas,Years] = 1

  #
  # Hydro is the non-Wind fraction of Cogeneration Electric Tech
  #
  @. CgFrac[Hydro,tech,ECs,areas,Years] = 1-CgFrac[Wind,tech,ECs,areas,Years]

  WriteDisk(db,"$Input/CgFrac",CgFrac)

end

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
  CgFrac::VariableArray{5} = ReadDisk(db,"$Input/CgFrac") # [Fuel,Tech,EC,Area,Year] Cogeneration Demands Fuel/Tech Split (Fraction)
end

function ICalibration(db)
  data = IControl(; db)
  (;Input,ECs,Tech,Fuel,Nation,Years) = data
  (;ANMap,CgFrac) = data

  # 
  # Cogeneration Electric Tech is mapped to fuels
  # 
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  tech = Select(Tech,"Electric")
  Electric = Select(Fuel,"Electric")
  Wind = Select(Fuel,"Wind")
  Hydro = Select(Fuel,"Hydro")

  #
  # Remove Electricity as a Fuel for Cogeneration
  #
  @. CgFrac[Electric,tech,ECs,areas,Years] = 0

  #
  # Specify Wind fraction of Cogeneration Electric Tech
  #
  @. CgFrac[Wind,tech,ECs,areas,Years] = 0

  #
  # Hydro is the non-Wind fraction of Cogeneration Electric Tech
  #
  @. CgFrac[Hydro,tech,ECs,areas,Years] = 1-CgFrac[Wind,tech,ECs,areas,Years]

  WriteDisk(db,"$Input/CgFrac",CgFrac)

end

function CalibrationControl(db)
  @info "CogenFraction.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
