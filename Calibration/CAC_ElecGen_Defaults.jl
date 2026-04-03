#
# CAC_ElecGen_Defaults.jl - Apply default coefficient from vEUPOCX in forecast
# to units with no input inventories - Ian 10/11/22
#
using EnergyModel

module CAC_ElecGen_Defaults

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBTU)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)
end

function GetUnitSets(data,unit)
  (;Area,Plant,UnArea,UnPlant) = data

  #
  # This procedure selects the sets for a particular unit
  #
  plant = findall(Plant .== UnPlant[unit])
  area =  findall(Area .== UnArea[unit])
  return plant,area
end

function ECalibration(db)
  data = EControl(; db)
  (;POCX,FuelEPs,UnCogen,Poll,UnPOCX) = data

  polls = Select(Poll,["PMT","PM10","PM25","SOX","NOX","VOC","COX","NH3","Hg","BC"])

  units = findall(UnCogen .== 0)

  for fuelep in FuelEPs, unit in units
    unit = unit[1]
    plant, area = GetUnitSets(data,unit)
    if plant != [] && area != []
      plant = plant[1]
      area = area[1]
      if sum(POCX[fuelep,plant,poll,area,year] for poll in polls, year in Future:Final) > 0
        if sum(UnPOCX[unit,fuelep,poll,year] for poll in polls, year in Future:Final) == 0
          for year in Future:Final, poll in polls
            UnPOCX[unit,fuelep,poll,year] = POCX[fuelep,plant,poll,area,year]
          end
        end
      end
    end
  end

  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
end

function CalibrationControl(db)
  @info "CAC_ElecGen_Defaults.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
