#
# AdjustLightingLoad.txp - Lighting Program (Incandescent Phase-Out)
# 
using EnergyModel

module AdjustLightingLoad

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  BMM::VariableArray{5} = ReadDisk(db,"$Input/BMM") # [Enduse,Tech,EC,Area,Year] Budget Exogenous Multiplier (Btu/Btu)

  # Scratch Variables
  BMMLighting::VariableArray{2} = zeros(Float32,length(Enduse),length(Year)) # [Enduse,Year] Energy Adjustment from Lighting Policy (Btu/Btu)
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Enduse,Techs,ECs,Years,Nation) = data
  (;ANMap,BMM) = data
  (;BMMLighting) = data
  
  #*
  #* Select Canada Areas
  #*
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #*
  #************************
  #*
  #* Change in non-Lighting Loads
  #* Calculations by Jeff Amlin 4/13/11 in "CFL Lighting EnvCa v5.xlsx"
  #*
  #* Input below using data from Glasha in 8/17/16 e-mail - Ian
  #*
  enduses = Select(Enduse,["AC","Heat"]) 
  years = collect(Yr(2013):Yr(2021))
  BMMLighting[enduses, years] .= [
  #/              2013    2014    2015    2016    2017    2018    2019    2020    2021
  #=Cooling=#   0.9713  0.9570  0.9498  0.9462  0.9444  0.9435  0.9431  0.9428  0.9427
  #=Heating=#   1.0176  1.0264  1.0308  1.0330  1.0341  1.0347  1.0350  1.0351  1.0352
  ]
  for enduse in enduses, tech in Techs, ec in ECs, area in areas, year in years 
    BMM[enduse,tech,ec,area,year] = BMMLighting[enduse,year]
  end
  years = collect(Yr(2022):Final)
  for enduse in enduses, tech in Techs, ec in ECs, area in areas, year in years 
    BMM[enduse,tech,ec,area,year] = BMMLighting[enduse,Yr(2021)]
  end

  WriteDisk(db,"$Input/BMM",BMM)

end

function CalibrationControl(db)
  @info "AdjustLightingLoad.jl - CalibrationControl"

  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
