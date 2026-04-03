#
# ElectricUtilityFuelUse_VB.jl - VBInput Electric Generation
# Jeff Amlin 5/21/2013
#
using EnergyModel

module ElectricUtilityFuelUse_VB

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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  vEUDmd::VariableArray{3} = ReadDisk(db,"VBInput/vEUDmd") # [Fuel,Area,Year] Electric Utility Fuel Demands (TBtu/Yr)
  xEUD::VariableArray{3} = ReadDisk(db,"EGInput/xEUD") # [FuelEP,Area,Year] Electric Utility Fuel Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Exogenous Energy Demands (tBtu)
  xEUDmd::VariableArray{3} = ReadDisk(db,"EGInput/xEUDmd") # [Fuel,Area,Year] Electric Utility Fuel Demands (TBtu/Yr)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Areas,ECC) = data
  (;FuelEPs,Fuels,Years) = data
  (;FFPMap,vEUDmd,xEUD,xEuDemand,xEUDmd) = data

  #*
  #* Canada Electric Utility Fuel Usage from ECCC (vEUDmd)
  #* US Electric Utility Fuel Usage extracted from EIA/AEO (vEUDmd)
  #*
  UtilityGen=Select(ECC,"UtilityGen")

  @. xEUDmd = vEUDmd
  for fuelep in FuelEPs, area in Areas, year in Years
    xEUD[fuelep,area,year] = sum(xEUDmd[fuel,area,year] * FFPMap[fuelep,fuel] for fuel in Fuels)
  end
  for year in Years, area in Areas, fuel in Fuels
    xEuDemand[fuel,UtilityGen,area,year] = xEUDmd[fuel,area,year]
  end

  WriteDisk(db,"EGInput/xEUD",xEUD)
  WriteDisk(db,"EGInput/xEUDmd",xEUDmd)
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)

end

function CalibrationControl(db)
  @info "ElectricUtilityFuelUse_VB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
