#
# ElectricGeneration_VB.jl - VBInput Electric Generation
# Jeff Amlin 5/21/2013
#
using EnergyModel

module ElectricGeneration_VB

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vEGFA::VariableArray{3} = ReadDisk(db,"VBInput/vEGFA") # [Fuel,vArea,Year] Electricity Generated (GWH/Yr)
  xEGFA::VariableArray{3} = ReadDisk(db,"EGInput/xEGFA") # [Fuel,Area,Year] Electricity Generated (GWH/Yr)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Nation,Fuels,Years) = data
  (;vAreas,vAreaMap) = data
  (;ANMap,vEGFA,xEGFA) = data

  #*
  #* Generation by Fuel from EnvCa (vEGFA)
  #*
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  
  for area in areas 
    varea = findall(x -> x == 1.0,vAreaMap[area,vAreas])
    if varea != []
      varea = varea[1]
      for fuel in Fuels, year in Years
        xEGFA[fuel,area,year] = vEGFA[fuel,varea,year]
      end
    end
  end

  WriteDisk(db,"EGInput/xEGFA",xEGFA)

end

function CalibrationControl(db)
  @info "ElectricGeneration_VB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
