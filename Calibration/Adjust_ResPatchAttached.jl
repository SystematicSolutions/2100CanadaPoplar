#
# Adjust_ResPatchAttached.jl 
#
using EnergyModel

module Adjust_ResPatchAttached

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}


Base.@kwdef struct RControl
  db::String

  Input::String = "RInput"

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

  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standard (Btu/Btu)
  DOCF::VariableArray{5} = ReadDisk(db,"$Input/DOCF") # [Enduse,Tech,EC,Area,Year] Device Operating Cost Fraction ($/Yr/$)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xDPL::VariableArray{5} = ReadDisk(db,"$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)

end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,EC,Techs,Enduses,Years) = data
  (;DEM,DEStd,DOCF,xDEE,xDCC,xDPL,xDSt) = data

  ec=Select(EC,"SingleFamilyAttached")
  SingleFamilyDetached=Select(EC,"SingleFamilyDetached")
  
  for area in Areas, tech in Techs, enduse in Enduses
    DEM[enduse,tech,ec,area] = DEM[enduse,tech,SingleFamilyDetached,area]
  end
  for year in Years, area in Areas, tech in Techs, enduse in Enduses
    DEStd[enduse,tech,ec,area,year]=DEStd[enduse,tech,SingleFamilyDetached,area,year]
    DOCF[enduse,tech,ec,area,year] = DOCF[enduse,tech,SingleFamilyDetached,area,year]
    xDEE[enduse,tech,ec,area,year] = xDEE[enduse,tech,SingleFamilyDetached,area,year]
    xDCC[enduse,tech,ec,area,year] = xDCC[enduse,tech,SingleFamilyDetached,area,year]
    xDPL[enduse,tech,ec,area,year] = xDPL[enduse,tech,SingleFamilyDetached,area,year]
  end
  for year in Years, area in Areas, enduse in Enduses
    xDSt[enduse,ec,area,year] = xDSt[enduse,SingleFamilyDetached,area,year]
  end

  WriteDisk(db,"$Input/DEM",DEM)
  WriteDisk(db,"$Input/DEStd",DEStd)
  WriteDisk(db,"$Input/DOCF",DOCF)
  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDCC",xDCC)
  WriteDisk(db,"$Input/xDPL",xDPL)

end

function CalibrationControl(db)
  @info "Adjust_ResPatchAttached.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
