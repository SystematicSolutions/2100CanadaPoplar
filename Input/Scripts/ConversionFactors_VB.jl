#
# ConversionFactors_VB.jl - Assigns future values of vECF equal to last historical year
#
##### NOTE - vECF goes through 2050 in vData.accdb. Delete this file?? R.Levesque 01/03/2019 ####
#
using EnergyModel

module ConversionFactors_VB

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
  Last = HisTime-ITime+1


  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vECF::VariableArray{3} = ReadDisk(db,"VBInput/vECF") # [Fuel,Area,Year] Energy Converion Factors (TJ/Various)
end

function SCalibration(db)
  data = SControl(; db)
  (;Fuels,Nation,Last,ANMap,vECF) = data


  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  for fuel in Fuels, area in cn_areas, year in Future:Final
    vECF[fuel,area,year] = vECF[fuel,area,Last]
  end

  WriteDisk(db,"VBInput/vECF",vECF)

end

function CalibrationControl(db)
  @info "ConversionFactors_VB.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
