#
# AdjustCAC_SK_Cogen.jl
# 

using EnergyModel

module AdjustCAC_SK_Cogen

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB")

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

  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)end

end

function ElecPolicy(db)
  data = EControl(; db)
  (; FuelEP,Poll) = data
  (; UnCode,UnPOCX) = data

  years = collect(Future:Final)

  #
  # Cory Mines Unit
  #
  poll = Select(Poll,["NOX","VOC"])
  fuelep = Select(FuelEP,"NaturalGas")
  
  units = findall(UnCode .== "SK00038800100")
  if units != []
    for unit in units,year in years
      UnPOCX[unit,fuelep,poll,year] = UnPOCX[unit,fuelep,poll,Yr(2022)]
    end
  end

  #
  # Belle Plain Unit2
  #
  poll = Select(Poll,["NOX","VOC"])
  fuelep = Select(FuelEP,"NaturalGas")
  
  units = findall(UnCode .== "SK00015200202")
  if units != []
    for unit in units, year in years
      UnPOCX[unit,fuelep,poll,year] = UnPOCX[unit,fuelep,poll,Yr(2022)]
    end
  end

  #
  # Belle Plain Unit1
  #
  poll = Select(Poll,["NOX","VOC"])
  fuelep = Select(FuelEP,"NaturalGas")
  
  units = findall(UnCode .== "SK00015200201")
  if units != []
    for unit in units, year in years
      UnPOCX[unit,fuelep,poll,year] = UnPOCX[unit,fuelep,poll,Yr(2022)]
    end
  end

  #
  # Unity Unit
  #
  poll = Select(Poll,["NOX","VOC"])
  fuelep = Select(FuelEP,"NaturalGas")
  
  units = findall(UnCode .== "SK00015000101")
  if units != []
    for unit in units, year in years
      UnPOCX[unit,fuelep,poll,year] = UnPOCX[unit,fuelep,poll,Yr(2022)]
    end
  end

  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
end

function PolicyControl(db)
  @info "AdjustCAC_SK_Cogen.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
