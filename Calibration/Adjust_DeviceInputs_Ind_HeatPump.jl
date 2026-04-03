#
# Adjust_DeviceInputs_Ind_HeatPump.jl 
#
# Use Electric values as placeholder for new HeatPump tech until data is updated
#
using EnergyModel

module Adjust_DeviceInputs_Ind_HeatPump

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}


Base.@kwdef struct IControl
  db::String

  Input::String = "IInput"

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

  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency (Btu/Btu)
  DOCF::VariableArray{5} = ReadDisk(db,"$Input/DOCF") # [Enduse,Tech,EC,Area,Year] Device Operating Cost Fraction ($/Yr/$)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (1985 Local $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xDPL::VariableArray{5} = ReadDisk(db,"$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)

end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,ECs,Tech,Enduses,Years) = data
  (;DEM,DOCF,xDEE,xDCC,xDPL) = data

  tech=Select(Tech,"HeatPump")
  Electric=Select(Tech,"Electric")

  for area in Areas, ec in ECs, enduse in Enduses
    DEM[enduse,tech,ec,area] = DEM[enduse,Electric,ec,area]
    for year in Years
      DOCF[enduse,tech,ec,area,year] = DOCF[enduse,Electric,ec,area,year]
      xDEE[enduse,tech,ec,area,year] = xDEE[enduse,Electric,ec,area,year]
      xDCC[enduse,tech,ec,area,year] = xDCC[enduse,Electric,ec,area,year]
      xDPL[enduse,tech,ec,area,year] = xDPL[enduse,Electric,ec,area,year]
    end
  end

  WriteDisk(db,"$Input/DEM",DEM)
  WriteDisk(db,"$Input/DOCF",DOCF)
  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xDCC",xDCC)
  WriteDisk(db,"$Input/xDPL",xDPL)

end

function CalibrationControl(db)
  @info "Adjust_DeviceInputs_Ind_HeatPump.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
