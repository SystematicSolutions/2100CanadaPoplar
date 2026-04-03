#
# CoalRetirements_CA.jl
#
using EnergyModel

module CoalRetirements_CA

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
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnFrImports::VariableArray{3} = ReadDisk(db,"EGInput/UnFrImports") # [Unit,Area,Year] Fraction of Unit Imported to Area (GWH/GWH)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Units,Years,UnArea,UnCode,UnFrImports,UnPlant,UnRetire) = data

  CA = Select(Area,"CA")
  # 
  # Boardman - Oregon
  # 
  # Four Corners Units 4 and 5 are sold
  # 
  for unit in Select(UnCode[Units],["Mtn_2442_4","Mtn_2442_5"])
    for year in First:Yr(2012)
      UnFrImports[unit,CA,year] = 0.480
    end
    for year in Yr(2013):Final
      UnFrImports[unit,CA,year] = 0.000
    end
  end

  # 
  # Intermountain
  # 
  for unit in Select(UnCode[Units],["Mtn_6481_1","Mtn_6481_2"])
    for year in First:Yr(2024)
      UnFrImports[unit,CA,year] = 0.789
    end
    for year in Yr(2025):Final
      UnFrImports[unit,CA,year] = 0.0
    end
  end

  # 
  # Navajo
  # 
  for unit in findall(x -> x == "Mtn_4941_NAV1" || x == "Mtn_4941_NAV2" || x == "Mtn_4941_NAV3", UnCode)
    for year in First:Yr(2015)
      UnFrImports[unit,CA,year] = 0.212
    end
    for year in Yr(2016):Final
      UnFrImports[unit,CA,year] = 0.0
    end
  end

  # 
  # San Juan 3
  # 
  for unit in findall(UnCode .== "Mtn_2451_3")
    for year in First:Yr(2017)
      UnFrImports[unit,CA,year] = 0.418
    end
    for year in Yr(2018):Final
      UnFrImports[unit,CA,year] = 0.0
    end
  end

  # 
  # San Juan 4
  # 
  for unit in Select(UnCode[Units],"Mtn_2451_4")
    for year in First:Yr(2018)
      UnFrImports[unit,CA,year] = 0.388
    end
    for year in Yr(2019):Final
      UnFrImports[unit,CA,year] = 0.0
    end
  end

  # 
  # California Coal Units
  # 
  unit1 = findall(UnArea .== "CA")
  unit2 = findall(UnPlant .== "Coal")
  for unit in intersect(unit1,unit2), year in Years
    UnRetire[unit,year] = Int(min(UnRetire[unit,year],2024))
  end

  WriteDisk(db,"EGInput/UnFrImports",UnFrImports)
  WriteDisk(db,"EGInput/UnRetire",UnRetire)

end

function CalibrationControl(db)
  @info "CoalRetirements_CA.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
