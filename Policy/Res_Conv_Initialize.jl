#
# Res_Conv_Initialize.jl
#

using EnergyModel

module Res_Conv_Initialize

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
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PIDS::SetArray = ReadDisk(db,"$Input/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CnvrtEU::VariableArray{4} = ReadDisk(db,"$Input/CnvrtEU") # [Enduse,EC,Area,Year] Conversion Switch
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  xProcSw::VariableArray{2} = ReadDisk(db,"$Input/xProcSw") # [PI,Year] Procedure on/off Switch
  xXProcSw::VariableArray{2} = ReadDisk(db,"$Input/xXProcSw") # [PI,Year] Procedure on/off Switch

end

function ResPolicy(db)
  data = RControl(; db)
  (; Input) = data
  (; ECs,Enduses,Nation,PI,Techs) = data 
  (; ANMap,CnvrtEU,Endogenous,xProcSw,xXProcSw) = data
  
  Conversion = Select(PI,"Conversion")
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  years = collect(Future:Final)
  
  for year in years
    xProcSw[Conversion,year] = Endogenous
    xXProcSw[Conversion,year] = Endogenous
  end
  WriteDisk(db,"$Input/xXProcSw",xXProcSw)
  WriteDisk(db,"$Input/xProcSw",xProcSw)

  for year in years, area in areas, ec in ECs, enduse in Enduses
    CnvrtEU[enduse,ec,area,year] = Endogenous
  end
  WriteDisk(db,"$Input/CnvrtEU",CnvrtEU)
 
end

function PolicyControl(db)
  @info "Res_Conv_Initialize.jl - PolicyControl"
  ResPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
