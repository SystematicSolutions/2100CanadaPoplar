#
# AdjustIndustrialGas.jl
#
using EnergyModel

module AdjustIndustrialGas

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PCCN::VariableArray{4} = ReadDisk(db,"$Outpt/PCCN") # [Enduse,Tech,EC,Area] Normalized Process Capital Cost ($/mmBtu)
  PCTC::VariableArray{5} = ReadDisk(db,"$Outpt/PCTC") # [Enduse,Tech,EC,Area,Year] Process Capital Cap. Trade Off Coef. (DLESS)
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM")  # [Enduse,EC,Area] Maximum Process Efficiency ($/Btu)
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN") # [Enduse,Tech,EC,Area] Process Normalized Fuel Price ($/mmBtu)
  PFTC::VariableArray{5} = ReadDisk(db,"$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year] Process Fuel Trade Off Coefficient
  POCF::VariableArray{4} = ReadDisk(db,"$CalDB/POCF") # [Enduse,Tech,EC,Area] Process Operating Cost Fraction
  RPCTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPCTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Capital Trade Off Coefficient (DLESS)
  RPFTC::VariableArray{5} = ReadDisk(db,"$Outpt/RPFTC") # [Enduse,Tech,EC,Area,Year] Retrofit Process Fuel Trade Off Coefficient
end

function SetPCTC(data,ec,areas,areatouse)
  (;Enduses,Techs,Years) = data
  (;PCCN,PCTC,PEM,PFPN,PFTC,POCF,RPCTC,RPFTC) = data

  for area in areas, tech in Techs, eu in Enduses
    PCCN[eu,tech,ec,area] = PCCN[eu,tech,ec,areatouse]
  end

  for year in Years, area in areas, tech in Techs, eu in Enduses
    PCTC[eu,tech,ec,area,year] = PCTC[eu,tech,ec,areatouse,year]
  end

  for area in areas, eu in Enduses
    PEM[eu,ec,area] = PEM[eu,ec,areatouse]
  end

  for year in Years, area in areas, tech in Techs, eu in Enduses
    POCF[eu,tech,ec,area] = POCF[eu,tech,ec,areatouse]
  end

  for year in Years, area in areas, tech in Techs, eu in Enduses
    PFPN[eu,tech,ec,area] = PFPN[eu,tech,ec,areatouse]
  end

  for year in Years, area in areas, tech in Techs, eu in Enduses
    PFTC[eu,tech,ec,area,year] = PFTC[eu,tech,ec,areatouse,year]
  end

  for year in Years, area in areas, tech in Techs, eu in Enduses
    RPCTC[eu,tech,ec,area,year] = RPCTC[eu,tech,ec,areatouse,year]
  end

  for year in Years, area in areas, tech in Techs, eu in Enduses
    RPFTC[eu,tech,ec,area,year] = RPFTC[eu,tech,ec,areatouse,year]
  end
end

function ICalibration(db)
  data = ICalib(; db)
  (;Outpt,CalDB,Area,EC) = data
  (;PCCN,PCTC,PEM,PFPN,PFTC,POCF,RPCTC,RPFTC) = data

  # 
  # PEI, YT and NU use AB
  # 
  ec = Select(EC,"IndustrialGas")
  areatouse = Select(Area,"AB")
  areas = Select(Area,["PE","YT","NU"])
  SetPCTC(data,ec,areas,areatouse)

  WriteDisk(db,"$Outpt/PCCN",PCCN)
  WriteDisk(db,"$Outpt/PCTC",PCTC)
  WriteDisk(db,"$CalDB/PEM",PEM)
  WriteDisk(db,"$Outpt/PFPN",PFPN)
  WriteDisk(db,"$Outpt/PFTC",PFTC)
  WriteDisk(db,"$CalDB/POCF",POCF)
  WriteDisk(db,"$Outpt/RPCTC",RPCTC)
  WriteDisk(db,"$Outpt/RPFTC",RPFTC)
end

function CalibrationControl(db)
  @info "AdjustIndustrialGas.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
