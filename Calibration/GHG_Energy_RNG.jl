#
# GHG_Energy_RNG.jl - CO2 emissions are assumed to be zero for Biogas and RNG
#
using EnergyModel

module GHG_Energy_RNG

import ...EnergyModel: ReadDisk, WriteDisk, Select
import ...EnergyModel: HisTime, ITime, MaxTime, First, Future, Final, Yr
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String
  
  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CgPOCX::VariableArray{5} = ReadDisk(db, "$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db, "$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
end

function RCalibration(db)
  data = RControl(; db)
  (; Areas, ECs, Enduses, FuelEP, Poll, Polls, Years) = data
  (; CgPOCX, POCX) = data

  biogas_rng = Select(FuelEP, ["Biogas", "RNG"])
  natural_gas = Select(FuelEP, "NaturalGas")
  CO2 = Select(Poll, "CO2")

  for fuelep in biogas_rng
    for year in Years, area in Areas, poll in Polls, ec in ECs
      for enduse in Enduses
        POCX[enduse, fuelep, ec, poll, area, year] = POCX[enduse, natural_gas, ec, poll, area, year]
      end
      CgPOCX[fuelep, ec, poll, area, year] = CgPOCX[natural_gas, ec, poll, area, year]
    end
    
    for year in Years, area in Areas, ec in ECs
      for enduse in Enduses
        POCX[enduse, fuelep, ec, CO2, area, year] = 0
      end
      CgPOCX[fuelep, ec, CO2, area, year] = 0
    end
  end

  WriteDisk(db, "$(data.Input)/POCX", POCX)
  WriteDisk(db, "$(data.Input)/CgPOCX", CgPOCX)

end

Base.@kwdef struct CControl
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgPOCX::VariableArray{5} = ReadDisk(db, "$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db, "$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
end

function CCalibration(db)
  data = CControl(; db)
  (; Areas,ECs,Enduses,FuelEP,Poll,Polls,Years) = data
  (; CgPOCX,POCX) = data

  biogas_rng = Select(FuelEP, ["Biogas", "RNG"])
  natural_gas = Select(FuelEP, "NaturalGas")
  co2 = Select(Poll, "CO2")

  for fuelep in biogas_rng
    for year in Years, area in Areas, poll in Polls, ec in ECs
      for enduse in Enduses
        POCX[enduse, fuelep, ec, poll, area, year] = POCX[enduse, natural_gas, ec, poll, area, year]
      end
      CgPOCX[fuelep, ec, poll, area, year] = CgPOCX[natural_gas, ec, poll, area, year]
    end
    
    for year in Years, area in Areas, ec in ECs
      for enduse in Enduses
        POCX[enduse, fuelep, ec, co2, area, year] = 0
      end
      CgPOCX[fuelep, ec, co2, area, year] = 0
    end
  end

  WriteDisk(db, "$(data.Input)/POCX", POCX)
  WriteDisk(db, "$(data.Input)/CgPOCX", CgPOCX)
end

Base.@kwdef struct IControl
  db::String
  
  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgPOCX::VariableArray{5} = ReadDisk(db, "$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db, "$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
end

function ICalibration(db)
  data = IControl(; db)
  (; Areas,ECs,Enduses,FuelEP,Poll,Polls,Years) = data
  (; CgPOCX,POCX) = data

  biogas_rng = Select(FuelEP, ["Biogas", "RNG"])
  natural_gas = Select(FuelEP, "NaturalGas")
  co2 = Select(Poll, "CO2")

  for fuelep in biogas_rng
    for year in Years, area in Areas, poll in Polls, ec in ECs
      for enduse in Enduses
        POCX[enduse, fuelep, ec, poll, area, year] = POCX[enduse, natural_gas, ec, poll, area, year]
      end
      CgPOCX[fuelep, ec, poll, area, year] = CgPOCX[natural_gas, ec, poll, area, year]
    end
    
    for year in Years, area in Areas, ec in ECs
      for enduse in Enduses
        POCX[enduse, fuelep, ec, co2, area, year] = 0
      end
      CgPOCX[fuelep, ec, co2, area, year] = 0
    end
  end

  WriteDisk(db, "$(data.Input)/POCX", POCX)
  WriteDisk(db, "$(data.Input)/CgPOCX", CgPOCX)
end

Base.@kwdef struct TControl
  db::String
  
  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  POCX::VariableArray{7} = ReadDisk(db, "$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
end

function TCalibration(db)
  data = TControl(; db)
  (; Areas,ECs,Enduses,FuelEP,Techs,Poll,Polls,Years) = data
  (; POCX) = data

  biogas_rng = Select(FuelEP, ["Biogas", "RNG"])
  natural_gas = Select(FuelEP, "NaturalGas")
  CO2 = Select(Poll, "CO2")

  for area in Areas
    for fuelep in biogas_rng
      for year in Years, poll in Polls, ec in ECs, tech in Techs
        for enduse in Enduses
          POCX[enduse, fuelep, tech, ec, poll, area, year] = POCX[enduse, natural_gas, tech, ec, poll, area, year]
        end
      end
      
      for year in Years, ec in ECs, tech in Techs
        for enduse in Enduses
          POCX[enduse, fuelep, tech, ec, CO2, area, year] = 0
        end
      end
    end
  end

  WriteDisk(db, "$(data.Input)/POCX", POCX)
end

Base.@kwdef struct EControl
  db::String
  
  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  POCX::VariableArray{5} = ReadDisk(db, "EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
end

function ECalibration(db)
  data = EControl(; db)
  (; Areas,FuelEP,Plants,Poll,Polls,Years) = data
  (; POCX) = data

  biogas_rng = Select(FuelEP, ["Biogas", "RNG"])
  natural_gas = Select(FuelEP, "NaturalGas")
  co2 = Select(Poll, "CO2")

  for fuelep in biogas_rng
    for year in Years, area in Areas, poll in Polls, plant in Plants
      POCX[fuelep, plant, poll, area, year] = POCX[natural_gas, plant, poll, area, year]
    end
    
    for year in Years, area in Areas, plant in Plants
      POCX[fuelep, plant, co2, area, year] = 0
    end
  end

  WriteDisk(db, "EGInput/POCX", POCX)
end

function CalibrationControl(db)
  @info "GHG_Energy-RNG.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)
  ECalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end # module GHG_Energy_RNG
