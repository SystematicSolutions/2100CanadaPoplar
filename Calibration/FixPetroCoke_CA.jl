#
# FixPetroCoke_CA.jl
#
using EnergyModel

module FixPetroCoke_CA

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Enduse Demand Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Area,Years,ECs,Enduses,FuelEP,Poll) = data
  (;POCX) = data

  #*
  #* Adjust PetroCoke in California - coefficient is higher than Canada.
  #*
  area = Select(Area,"CA")
  fuelep = Select(FuelEP,"PetroCoke")
  poll = Select(Poll,"CO2")
  ON = Select(Area,"ON")
  for year in Years, ec in ECs, enduse in Enduses
    POCX[enduse,fuelep,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,ON,year] 
  end  

  WriteDisk(db,"$Input/POCX",POCX)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Enduse Demand Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Area,Years,ECs,Enduses,FuelEP,Poll) = data
  (;POCX) = data

  #*
  #* Adjust PetroCoke in California - coefficient is higher than Canada.
  #*
  area = Select(Area,"CA")
  fuelep = Select(FuelEP,"PetroCoke")
  poll = Select(Poll,"CO2")
  ON = Select(Area,"ON")
  for year in Years, ec in ECs, enduse in Enduses
      POCX[enduse,fuelep,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,ON,year] 
  end

  WriteDisk(db,"$Input/POCX",POCX)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Enduse Demand Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,FuelEP,Poll,ECs,Enduses,Years) = data
  (;POCX) = data

  #*
  #* Adjust PetroCoke in California - coefficient is higher than Canada.
  #*
  area = Select(Area,"CA")
  fuelep = Select(FuelEP,"PetroCoke")
  poll = Select(Poll,"CO2")
  ON = Select(Area,"ON")
  for year in Years, ec in ECs, enduse in Enduses
    POCX[enduse,fuelep,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,ON,year]
  end
  
  WriteDisk(db,"$Input/POCX",POCX)

end

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{5} = ReadDisk(db,"EGInput/POCX") # [FuelEP,Plant,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Years,Plants,FuelEP,Poll) = data
  (;POCX) = data

  #*
  #* Adjust PetroCoke in California - coefficient is higher than Canada.
  #*
  area = Select(Area,"CA")
  fuelep = Select(FuelEP,"PetroCoke")
  poll = Select(Poll,"CO2")
  ON = Select(Area,"ON")
  for year in Years, plant in Plants
    POCX[fuelep,plant,poll,area,year] = POCX[fuelep,plant,poll,ON,year]
  end
  
  WriteDisk(db,"EGInput/POCX",POCX)

end

function CalibrationControl(db)
  @info "FixPetroCoke_CA.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
