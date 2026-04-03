#
# CCS_TaxRate.jl - GHG Carbon Sequestration Tax Rate - Jeff Amlin 3/17/23
#
using EnergyModel

module CCS_TaxRate

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
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
  SqTxRt::VariableArray{2} = ReadDisk(db,"MEInput/SqTxRt") # [Area,Year] Sequestering eCO2 Reduction Tax Rate ($/$)

  # Scratch Variables
  SqTX::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Canada Sequestering eCO2 Reduction Tax Rate ($/$)
end

function MCalibration(db)
  data = MControl(; db)
  (;Nation,Years) = data
  (;ANMap,SqTxRt) = data
  (;SqTX) = data

  #*
  #* 1. US - TxRt from IData.src (these are US values) (The data is from DRI, Tables 7 & 10)
  #* 2. Canada - Source:  NRS.xls (Informetric Corporate Tax Rate, Total All Governments)
  #*
  #* US Areas
  #*
  US = Select(Nation, "US")
  areas = findall(ANMap[:,US] .== 1.0)

  years = collect(Zero:Yr(1986))
  for area in areas, year in years
    SqTxRt[area,year] = 0.4950
  end

  years = Yr(1987)
  for area in areas, year in years
    SqTxRt[area,year] = 0.38
  end

  years = collect(Yr(1988):Yr(1992))
  for area in areas, year in years
    SqTxRt[area,year] = 0.34
  end

  years = collect(Yr(1993):Final)
  for area in areas, year in years
    SqTxRt[area,year] = 0.35
  end

  #*
  #* Canada Areas
  #*
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0) 

  #*
  #* Canada's Total Government Tax Rate (Per Informetrica)
  #*
  years = collect(Zero:Yr(2000))
  SqTX[years] .= [
  31.4
  32.1
  30.0
  27.2
  30.9
  37.6
  43.1
  41.4
  34.7
  30.9
  31.5
  36.0
  37.0
  36.5
  34.4
  35.1
  ]
  for year in years
    SqTX[year] = SqTX[year] / 100
  end

  years = collect(Yr(2001):Final)
  for year in years
    SqTX[year] = SqTX[Yr(2000)]
  end

  for area in areas, year in Years 
    SqTxRt[area,year] = SqTX[year]
  end

  WriteDisk(db,"MEInput/SqTxRt",SqTxRt)

end

function CalibrationControl(db)
  @info "CCS_TaxRate.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
