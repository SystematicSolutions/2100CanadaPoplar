#
# AdjustCAC_ABElecGen_Alt.jl
# Forecasted CAC coefficients for selected AB units - Ian 20/10/20
#
############################################################
#                                                          #
#                       NOTICE                             #
#                                                          #
#  The ENERGY 2100 model is available by contacting        #
#  Systematic Solutions, Inc. (Telephone:937-767-1873).    #
#  The ENERGY 2100 model and all associated software are   #
#  the property of Systematic Solutions, Inc. and cannot   #
#  be distributed to others without the expressed          #
#  permission of Systematic Solutions, Inc. Any modified   #
#  ENERGY 2100-related software must include this notice   #
#  along with a designation stating who made the revision, #
#  the general focus of the revision, and the date of the  #
#  revision.                                               #
#                                                          #
#                                 March 27, 2006           #
#                                                          #
############################################################
#
#    Systematic Solutions, Inc.
#
#        Version: September 2010
#
using EnergyModel

module AdjustCAC_ABElecGen_Alt

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct AdjustCAC_ABElecGen_AltData
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

  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPOCX::VariableArray{4} = ReadDisk(db,"EGInput/UnPOCX") # [Unit,FuelEP,Poll,Year] Pollution Coefficient (Tonnes/TBtu)

end

function AdjustCAC_ABElecGen_AltDataCalibration(db)
  data = AdjustCAC_ABElecGen_AltData(; db)
  (;Area,FuelEP,Plant,Poll) = data
  (;Years) = data
  (;POCX,UnArea,UnPlant,UnPOCX) = data

  # 
  # Apply AB specific coefficient from CAC_VB_ElecUtility.txt to units with no
  # existing values for covered pollutants in forecast- Ian 21/10/13
  # 
  fuelep = Select(FuelEP,"NaturalGas")
  area = Select(Area,"AB")
  polls = Select(Poll,["NH3","BC","COX","Hg","NOX","PM10","PM25","PMT","SOX","VOC"])

  unit1 = findall(x -> x == "AB", UnArea)
  unit2 = findall(x -> x == "OGCC", UnPlant)
  unit3 = findall(x -> x == "OGCT", UnPlant)
  unit4 = findall(x -> x == "SmallOGCC", UnPlant)
  unit5 = findall(x -> x == "OGSteam", UnPlant)
  units = intersect(unit1,union(unit2,unit3,unit4,unit5))

  for year in Years, poll in polls, unit in units
    if UnPOCX[unit,fuelep,poll,year] == 0
      plant = Select(Plant,UnPlant[unit])
      UnPOCX[unit,fuelep,poll,year] = POCX[fuelep,plant,poll,area,year]
    end
  end

  WriteDisk(db,"EGInput/UnPOCX",UnPOCX)
end

function CalibrationControl(db)
  @info "AdjustCAC_ABElecGen_Alt.jl - CalibrationControl"

  AdjustCAC_ABElecGen_AltDataCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
