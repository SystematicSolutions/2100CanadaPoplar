#
# AdjustTransEff.jl - Passenger Transportation Efficiency Adjustment
#
using EnergyModel

module AdjustTransEff

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)

  # Scratch Variables
  # Eff      'Change in Efficiency (Btu/Btu)'
end

function TransCalibration(db)
  data = TControl(; db)
  (;CalDB,Input) = data
  (;EC,Nation) = data
  (;Tech) = data
  (;ANMap,DEMM,DCMM) = data
  
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  
  #
  # Select enduses impacted by this policy and implement change in
  # efficiency and capital costs.
  #
  Passenger = Select(EC,"Passenger")

  #
  # Light Duty Vehicle (auotomobile) efficiency adjustment
  #
  techs = Select(Tech,["LDVGasoline","LDVDiesel","LDVElectric","LDVHybrid",
                       "LDVPropane","LDVNaturalGas","LDVEthanol"])
  years = collect(Future:Final)
  for year in years, area in areas, tech in techs
    DEMM[1,tech,Passenger,area,year] = DEMM[1,tech,Passenger,area,year-1] * 1.006
    DCMM[1,tech,Passenger,area,year] = DCMM[1,tech,Passenger,area,year-1] * 1.001
  end
  
  #
  # Light Duty Truck (and SUV) efficiency adjustment
  #
  techs = Select(Tech,["LDTGasoline","LDTDiesel","LDTElectric","LDTHybrid",
                       "LDTPropane","LDTNaturalGas","LDTEthanol"])
  for year in years, area in areas, tech in techs
    DEMM[1,tech,Passenger,area,year] = DEMM[1,tech,Passenger,area,year-1] * 1.006
    DCMM[1,tech,Passenger,area,year] = DCMM[1,tech,Passenger,area,year-1] * 1.001
  end
  
  WriteDisk(db,"$Input/DCMM",DCMM)
  WriteDisk(db,"$CalDB/DEMM",DEMM)

end

function CalibrationControl(db)
  @info "AdjustTransEff.jl - CalibrationControl"

  TransCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
