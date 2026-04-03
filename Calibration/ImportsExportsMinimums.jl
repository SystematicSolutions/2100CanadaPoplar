#
# ImportsExportsMinimums.jl - Assigns the minimum imports and exports
#        to be equal the exogenous inputs (xImports and xExports).
#
using EnergyModel

module ImportsExportsMinimums

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
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

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ImportsMin::VariableArray{3} = ReadDisk(db,"SpInput/ImportsMin") # [FuelEP,Nation,Year] Imports Minimum (TBtu/Yr)
  ExportsMin::VariableArray{3} = ReadDisk(db,"SpInput/ExportsMin") # [FuelEP,Nation,Year] Exports Minimum (TBtu/Yr)
  xCProd::VariableArray{2} = ReadDisk(db,"SpInput/xCProd") # [Nation,Year] Coal Production - Reference Case (TBtu/Yr)
  xImports::VariableArray{3} = ReadDisk(db,"SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xExports::VariableArray{3} = ReadDisk(db,"SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xSupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpInput/xSupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)

  # Scratch Variables
end

function SCalibration(db)
  data = SControl(; db)
  (;FuelEP,FuelEPs,Nation,Nations) = data
  (;ImportsMin,ExportsMin,xCProd,xImports,xExports) = data

  @. ImportsMin = xImports
  @. ExportsMin = xExports

  #*
  #* Default projection values for FuelEPs - Peter Volkmar 2022.10.07
  #*
  years = collect(Future:Final)
  for fuelep in FuelEPs, nation in Nations, year in years 
    ExportsMin[fuelep,nation,year] = max(ExportsMin[fuelep,nation,year-1] * (1 - 0.05),
                                         xExports[fuelep,nation,year] * 0.95)
    ImportsMin[fuelep,nation,year] = max(ImportsMin[fuelep,nation,year-1] * (1 - 0.05),
                                         xImports[fuelep,nation,year] * 0.95)
  end

  #*
  #* Natural Gas
  #* ImportsMin(NG,CN,Y) dropoff by 0.5% instead of 5% - Peter Volkmar 2022.10.07
  #*
  fuelep = Select(FuelEP,"NaturalGas")
  nation = Select(Nation,"CN")
  for year in years 
    ExportsMin[fuelep,nation,year] = max(ExportsMin[fuelep,nation,year-1] * (1 - 0.05),
                                         xExports[fuelep,nation,Last] * 0.25)
    ImportsMin[fuelep,nation,year] = ImportsMin[fuelep,nation,year-1] * (1 + .01)
  end
  years = collect(Yr(2030):Final)
  for year in years 
    ImportsMin[fuelep,nation,year] = ImportsMin[fuelep,nation,year-1]
  end
  
  years = collect(Future:Final)
  nation = Select(Nation,"US")
  for year in years 
    ExportsMin[fuelep,nation,year] = max(ExportsMin[fuelep,nation,year-1] * (1 - 0.05),
                                         xExports[fuelep,nation,Last] * 0.25)
  end

  nation = Select(Nation,"MX")
  for year in years 
    ImportsMin[fuelep,nation,year] = xImports[fuelep,nation,Last] * 0.25
  end

  #*
  #* Coal
  #*
  fuelep = Select(FuelEP,"Coal")
  nation = Select(Nation,"CN")
  for year in years 
    ExportsMin[fuelep,nation,year] = max(ExportsMin[fuelep,nation,year-1] * (1 - 0.25),
                                         xCProd[nation,year] * 0.10)
    ImportsMin[fuelep,nation,year] = max(ImportsMin[fuelep,nation,year-1] * (1 - 0.25),
                                         xCProd[nation,year] * 0.01)  
  end

  WriteDisk(db,"SpInput/ExportsMin",ExportsMin)
  WriteDisk(db,"SpInput/ImportsMin",ImportsMin)

end

function CalibrationControl(db)
  @info "ImportsExportsMinimums.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
