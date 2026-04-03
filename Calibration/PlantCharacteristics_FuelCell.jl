#
# PlantCharacteristics_FuelCell.jl
#
using EnergyModel

module PlantCharacteristics_FuelCell

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation (Map)
  PjMax::VariableArray{2} = ReadDisk(db,"EGInput/PjMax") # [Plant,Area] Maximum Project Size (MW)
  PjMnPS::VariableArray{2} = ReadDisk(db,"EGInput/PjMnPS") # [Plant,Area] Minimum Project Size (MW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Plant) = data
  (;PjMax,PjMnPS) = data
  #
  # Source: Capital Cost and Performance Characteristic Estimates for Utility Scale Electric Power Generating Technologies
  # Accessed 02/04/2020: http://www.eia.gov/analysis/studies/powerplants/capitalcost/ Section 10 - 10MW Fuel Cell
  #
  #  Technology                                    E2020 Plant Type               CD       HRtM       xGCC      UFOMC       UOMC
  #  2019 US$
  #  Fuel Cells (2020 Data)                        FuelCell                        2       6469       6700      30.78       0.59
  #

  plants=Select(Plant,"FuelCell")
  areas=Select(Area,["ON","QC","BC","AB","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  for area in areas, plant in plants
    PjMnPS[plant,area]=10
    PjMax[plant,area]=999999
  end

  WriteDisk(db,"EGInput/PjMax",PjMax)
  WriteDisk(db,"EGInput/PjMnPS",PjMnPS)

end

function CalibrationControl(db)
  @info "PlantCharacteristics_FuelCell.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
