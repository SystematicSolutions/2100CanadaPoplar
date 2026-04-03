#
# GHG_Residential_CA.jl - Updated CA data from California Energy Commission
# 11/24/15
#
using EnergyModel

module GHG_Residential_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
end

function RCalibration(db)
  data = RControl(; db)
  (;Area,Input,ECs,Enduses,FuelEP,Poll,Years,POCX) = data

  # 
  # Adjust Wood POCX based on CA GHG Inventories Documentation
  # Source: www.arb.ca.gov/cc/inventory/doc/docs1/1a4b_householduse_fuelcombustion_wood(wet)_ch4_2013.htm
  # Source: "CH4 Coefficient Examinations.xlsx" 1-22-2016, Luke Davulis
  # 
  biomass = Select(FuelEP,"Biomass")
  CH4 = Select(Poll,"CH4")
  CA = Select(Area,"CA")

  for eu in Enduses, ec in ECs, year in Years
    POCX[eu,biomass,ec,CH4,CA,year] = 32*POCX[eu,biomass,ec,CH4,CA,year]/POCX[eu,biomass,ec,CH4,CA,Yr(2013)]
  end

  WriteDisk(db,"$Input/POCX",POCX)
  
end

function CalibrationControl(db)
  @info "GHG_Residential_CA.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
