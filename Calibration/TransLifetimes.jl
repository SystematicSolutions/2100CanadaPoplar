#
# TransLifetimes.jl
#
using EnergyModel

module TransLifetimes

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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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

  xDPL::VariableArray{5} = ReadDisk(db,"$Input/xDPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)

end

function TLifetimes(db)
  data = TControl(; db)
  (;Input) = data  
  (;Areas,ECs) = data
  (;Enduses,Tech,Techs,Years) = data
  (;xDPL) = data

  #
  # Default for all Techs/Sectors (for Planes)
  #
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year]=12
  end

  #
  # Values below sent by Matt in xDPL.xlsx - Ian 07/14/20
  #
  techs = Select(Tech,(from = "LDVGasoline",to = "LDVFuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year] = 14.7
  end

  #
  # Light Trucks
  #
  techs = Select(Tech,(from = "LDTGasoline",to = "LDTFuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year]=15.4
  end
  
  #
  # Motorcycles
  #
  techs = Select(Tech,"Motorcycle")
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year] = 13
  end

  #
  # Buses
  #
  techs = Select(Tech,(from = "BusGasoline",to = "BusFuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year] = 17.6
  end
  
  #
  # Freight Trucks
  #
  techs = Select(Tech,(from = "HDV2B3Gasoline",to = "HDV8FuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year] = 17.6
  end

  #
  # Trains
  #
  techs = Select(Tech,(from = "TrainDiesel",to = "TrainFuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year] = 43.9
  end
  
  #
  # Marine
  #
  techs = Select(Tech,(from = "MarineHeavy",to = "MarineFuelCell"))
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xDPL[enduse,tech,ec,area,year] = 40
  end
 
  WriteDisk(db,"$Input/xDPL",xDPL)

end

function Control(db)
  @info "TransLifetimes.jl - Control"
  TLifetimes(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
