#
# GasProcessing.jl - Assigns gas processing switches, map and sweet fraction
#
using EnergyModel

module GasProcessing

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GasProcessingSwitch::VariableArray{2} = ReadDisk(db,"SpInput/GasProcessingSwitch") # [Area,Year] Gas Processing Switch (1=Endogenous, 0=Exogenous)
  GasProductionMap::VariableArray{1} = ReadDisk(db,"SpInput/GasProductionMap") # [Process] Gas Production Map (1=include)
  GasSweetFraction::VariableArray{2} = ReadDisk(db,"SpInput/GasSweetFraction") # [Area,Year] Gas Processing Sweet Fraction (Btu/Btu)
  GasProcessingFraction::VariableArray{3} = ReadDisk(db,"SpInput/GasProcessingFraction") # [Process,Area,Year] Gas Processing Fraction (Btu/Btu)
end

function SCalibration(db)
  data = SControl(; db)
  (;AreaDS,Areas,Nation,Process,Years) = data
  (;ANMap,GasProcessingSwitch,GasProductionMap,GasSweetFraction,GasProcessingFraction) = data

  GasProcessingSwitch .= 0
  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)
  for area in cn_areas, year in Years
    GasProcessingSwitch[area,year] = 1
  end

  GasProductionMap .= 0
  processes = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction"])
  for process in processes
    GasProductionMap[process] = 1
  end

  GasSweetFraction[Select(AreaDS,"Ontario"),Years]              .= 1.00
  GasSweetFraction[Select(AreaDS,"Quebec"),Years]               .= 1.00
  GasSweetFraction[Select(AreaDS,"British Columbia"),Years]     .= 0.30
  GasSweetFraction[Select(AreaDS,"Alberta"),Years]              .= 0.50 
  GasSweetFraction[Select(AreaDS,"Manitoba"),Years]             .= 1.00 
  GasSweetFraction[Select(AreaDS,"Saskatchewan"),Years]         .= 0.50
  GasSweetFraction[Select(AreaDS,"New Brunswick"),Years]        .= 1.00
  GasSweetFraction[Select(AreaDS,"Nova Scotia"),Years]          .= 1.00
  GasSweetFraction[Select(AreaDS,"Newfoundland"),Years]         .= 1.00
  GasSweetFraction[Select(AreaDS,"Prince Edward Island"),Years] .= 1.00
  GasSweetFraction[Select(AreaDS,"Yukon Territory"),Years]      .= 1.00
  GasSweetFraction[Select(AreaDS,"Northwest Territory"),Years]  .= 1.00
  GasSweetFraction[Select(AreaDS,"Nunavut"),Years]              .= 1.00

  GasProcessingFraction .= 0
  for area in Areas, year in Years
    GasProcessingFraction[Select(Process,"SweetGasProcessing"),area,year] = GasSweetFraction[area,year]
    GasProcessingFraction[Select(Process,"SourGasProcessing"),area,year] = 1-GasSweetFraction[area,year]
  end

  WriteDisk(db,"SpInput/GasProcessingSwitch",GasProcessingSwitch)
  WriteDisk(db,"SpInput/GasProductionMap",GasProductionMap)
  WriteDisk(db,"SpInput/GasSweetFraction",GasSweetFraction)
  WriteDisk(db,"SpInput/GasProcessingFraction",GasProcessingFraction)

    
end

function CalibrationControl(db)
  @info "GasProcessing.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
