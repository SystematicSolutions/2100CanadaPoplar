#
# OGCCFractions.jl
#
using EnergyModel

module OGCCFractions

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  OGCCFraction::VariableArray{2} = ReadDisk(db,"EGInput/OGCCFraction") # [Area,Year] Fraction of new OG capacity which is OGCC (MW/MW)
  OGCCSmallFraction::VariableArray{2} = ReadDisk(db,"EGInput/OGCCSmallFraction") # [Area,Year] Fraction of new OGCC capacity which is Small (MW/MW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Years) = data
  (;OGCCFraction,OGCCSmallFraction) = data

  # @. OGCCFraction=1.0

  #
  # Areas building natural gas units
  #
  areas=Select(Area,["ON","AB","SK","MB","NB","NS","YT","NT","NU"])
  for year in Years, area in areas
    # OGCCFraction[area,year]=0.80
    OGCCFraction[area,year]=0.0
  end
  #
  # Areas not building natural gas units
  #
  areas=Select(Area,["QC","BC","PE","NL"])
  for year in Years, area in areas
    # OGCCFraction[area,year]=1.00
    OGCCFraction[area,year]=0.00
  end

  WriteDisk(db,"EGInput/OGCCFraction",OGCCFraction)

  #
  ########################
  #

  @. OGCCSmallFraction=0.0

  #
  # Areas building large and small OGCC
  #
  areas=Select(Area,["ON","QC","BC","AB","SK","MB","NB"])
  for year in Years, area in areas
    # OGCCSmallFraction[area,year]=0.50
    # Edit V.Keller Apr 24, 2024. For CER CGII work
    OGCCSmallFraction[area,year]=0.00
  end

  #
  # Areas building only small OGCC
  #
  areas=Select(Area,["NS","PE","NL","YT","NT","NU"])
  for year in Years, area in areas
    # OGCCSmallFraction[area,year]=1.00
    OGCCSmallFraction[area,year]=0.00
  end

  WriteDisk(db,"EGInput/OGCCSmallFraction",OGCCSmallFraction)

end

function CalibrationControl(db)
  @info "OGCCFractions.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
