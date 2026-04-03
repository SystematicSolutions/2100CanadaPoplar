#
# FixBiomass.jl
#
using EnergyModel

module FixBiomass

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgPOCX::VariableArray{5} = ReadDisk(db,"$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Enduse Demand Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,FuelEP) = data
  (;Poll) = data
  (;Years) = data
  (;CgPOCX,POCX) = data
  #
  # Adjust Biomass until v*.dat files are revised - Jeff Amlin 04/30/21
  # Source: Email from John St-Laurent O'Connor on Thursday, April 22, 2021 6:22 PM
  #   "You can use 54706.43355 tonnes/TBtu as the biomass CO2 emission coefficient"
  #
  Biomass=Select(FuelEP,"Biomass")
  CO2=Select(Poll,"CO2")
  
  for eu in Enduses,ec in ECs,area in Areas,year in Years
    POCX[eu,Biomass,ec,CO2,area,year]=54706.43
  end
  
  for ec in ECs,area in Areas,year in Years
    CgPOCX[Biomass,ec,CO2,area,year]=54706.43
  end
  
  WriteDisk(db,"$Input/POCX",POCX)
  
  
  # Select FuelEP(Biomass)
  # Select Poll(CO2)
  # POCX=54706.43
  # CgPOCX=54706.43
  # Select FuelEP*, Poll*
#Write Disk(POCX)

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgPOCX::VariableArray{5} = ReadDisk(db,"$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Enduse Demand Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,FuelEP) = data
  (;Poll) = data
  (;Years) = data
  (;CgPOCX,POCX) = data
  #
  # Adjust Biomass until v*.dat files are revised - Jeff Amlin 04/30/21
  # Source: Email from John St-Laurent O'Connor on Thursday, April 22, 2021 6:22 PM
  #   "You can use 54706.43355 tonnes/TBtu as the biomass CO2 emission coefficient"
  #
  Biomass=Select(FuelEP,"Biomass")
  CO2=Select(Poll,"CO2")
  
  for eu in Enduses,ec in ECs,area in Areas,year in Years
    POCX[eu,Biomass,ec,CO2,area,year]=54706.43
  end
  
  for ec in ECs,area in Areas,year in Years
    CgPOCX[Biomass,ec,CO2,area,year]=54706.43
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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgPOCX::VariableArray{5} = ReadDisk(db,"$Input/CgPOCX") # [FuelEP,EC,Poll,Area,Year] Cogeneration Pollution Coefficient (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Enduse Demand Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,FuelEP) = data
  (;Poll) = data
  (;Years) = data
  (;CgPOCX,POCX) = data
  #
  # Adjust Biomass until v*.dat files are revised - Jeff Amlin 04/30/21
  # Source: Email from John St-Laurent O'Connor on Thursday, April 22, 2021 6:22 PM
  #   "You can use 54706.43355 tonnes/TBtu as the biomass CO2 emission coefficient"
  #
  Biomass=Select(FuelEP,"Biomass")
  CO2=Select(Poll,"CO2")
  
  for eu in Enduses,ec in ECs,area in Areas,year in Years
    POCX[eu,Biomass,ec,CO2,area,year]=54706.43
  end
  
  for ec in ECs,area in Areas,year in Years
    CgPOCX[Biomass,ec,CO2,area,year]=54706.43
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
  data = IControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduses,FuelEP) = data
  (;Poll) = data
  (;Years) = data
  (;CgPOCX,POCX) = data
  #
  # Adjust Biomass until v*.dat files are revised - Jeff Amlin 04/30/21
  # Source: Email from John St-Laurent O'Connor on Thursday, April 22, 2021 6:22 PM
  #   "You can use 54706.43355 tonnes/TBtu as the biomass CO2 emission coefficient"
  #
  Biomass=Select(FuelEP,"Biomass")
  CO2=Select(Poll,"CO2")
  
  for eu in Enduses,ec in ECs,area in Areas,year in Years
    POCX[eu,Biomass,ec,CO2,area,year]=54706.43
  end
  
  for ec in ECs,area in Areas,year in Years
    CgPOCX[Biomass,ec,CO2,area,year]=54706.43
  end
  
  WriteDisk(db,"$Input/POCX",POCX)

end

function CalibrationControl(db)
  @info "FixBiomass.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
