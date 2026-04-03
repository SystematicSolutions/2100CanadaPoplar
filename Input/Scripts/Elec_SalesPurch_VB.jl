#
# Elec_SalesPurch_VB.jl - VBInput Electric Sales and Purchases
#
using EnergyModel

module Elec_SalesPurch_VB

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
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vAreaPurchases::VariableArray{2} = ReadDisk(db,"VBInput/vAreaPurchases") # [vArea,Year] VBInput Historical Purchases from Areas in the same Country (GWh/Yr)
  vAreaSales::VariableArray{2} = ReadDisk(db,"VBInput/vAreaSales") # [vArea,Year] VBInput Historical Sales to Areas in the same Country (GWh/Yr)
  vExpPurchases::VariableArray{2} = ReadDisk(db,"VBInput/vExpPurchases") # [vArea,Year] VBInput Historical Purchases from Areas in a different Country (GWh/Yr)
  vExpSales::VariableArray{2} = ReadDisk(db,"VBInput/vExpSales") # [vArea,Year] VBInput Historical Sales to Areas in a different Country (GWh/Yr)
  xAreaPurchases::VariableArray{2} = ReadDisk(db,"EGInput/xAreaPurchases") # [Area,Year] Historical Purchases from Areas in the same Country (GWh/Yr)
  xAreaSales::VariableArray{2} = ReadDisk(db,"EGInput/xAreaSales") # [Area,Year] Historical Sales to Areas in the same Country (GWh/Yr)
  xExpPurchases::VariableArray{2} = ReadDisk(db,"EGInput/xExpPurchases") # [Area,Year] Historical Purchases from Areas in a different Country (GWh/Yr)
  xExpSales::VariableArray{2} = ReadDisk(db,"EGInput/xExpSales") # [Area,Year] Historical Sales to Areas in a different Country (GWh/Yr)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;vAreaPurchases,vAreaSales,vExpPurchases,vExpSales,xAreaPurchases,xAreaSales,xExpPurchases,xExpSales) = data

  #*
  #* Set x variables equal to v variables
  #*
  @. xAreaPurchases = vAreaPurchases
  @. xAreaSales = vAreaSales
  @. xExpPurchases = vExpPurchases
  @. xExpSales = vExpSales

  WriteDisk(db,"EGInput/xAreaPurchases",xAreaPurchases)
  WriteDisk(db,"EGInput/xAreaSales",xAreaSales)
  WriteDisk(db,"EGInput/xExpPurchases",xExpPurchases)
  WriteDisk(db,"EGInput/xExpSales",xExpSales)
  
end

function CalibrationControl(db)
  @info "Elec_SalesPurch_VB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
