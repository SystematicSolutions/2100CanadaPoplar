#
# GHG_Feedstocks_US.jl - Reads in U.S. values for feedstock coefficients
#
using EnergyModel

module GHG_Feedstocks_US

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  FsPOCX::VariableArray{5} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;ECs,Areas,Enduses,Fuel,Fuels,FuelEP,Nation,Poll,Polls,Years) = data
  (;ANMap,FsPOCX,POCX) = data
  
  #
  # Source:  "Feedstock (Non-Energy) Demands GO 07.xls", 'Notes' sheet from Glasha 2-19-09.
  # Feedstock Emission Coefficients are only for CO2. Units (t CO2/PJ)
  # 03/09/09 RBL.
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  for year in Years, area in areas, poll in Polls, ec in ECs, fuel in Fuels
    FsPOCX[fuel,ec,poll,area,year] = 0.0
  end

  #
  # NGL's
  #
  LPG = Select(Fuel,"LPG")
  poll = Select(Poll,"CO2")
  years = collect(Yr(1990):Yr(1997))
  for ec in ECs, area in areas, year in years 
    FsPOCX[LPG,ec,poll,area,year] = 11176
  end
  years = collect(Yr(1998):Final)
  for ec in ECs, area in areas, year in years 
    FsPOCX[LPG,ec,poll,area,year] = 11692
  end
  
  #
  # Lubricants, Naphtha, NaturalGas, NonEnergy, PetroFeed, Coke
  #
  fuel = Select(Fuel,"Lubricants")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 36006
  end
  fuel = Select(Fuel,"Naphtha")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 17771
  end
  fuel = Select(Fuel,"NaturalGas")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 39780
  end
  fuel = Select(Fuel,"NonEnergy")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 36414
  end
  fuel = Select(Fuel,"PetroFeed")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 14217
  end
  fuel = Select(Fuel,"Coke")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 86021.505
  end
  
  #
  # Convert from Tonnes/PJ to Tonnes/TBtu
  #
  for year in Years, area in areas, poll in Polls, ec in ECs, fuel in Fuels
    FsPOCX[fuel,ec,poll,area,year] = FsPOCX[fuel,ec,poll,area,year] * 1.054615
  end

  #
  # Coal and PetroCoke have same values as combustion emissions for CO2.
  #
  fuel = Select(Fuel,"Coal")
  fuelep = Select(FuelEP,"Coal")
  for year in Years, area in areas, ec in ECs, enduse in Enduses
    FsPOCX[fuel,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]
  end
  fuel = Select(Fuel,"PetroCoke")
  fuelep = Select(FuelEP,"PetroCoke")
  for year in Years, area in areas, ec in ECs, enduse in Enduses
      FsPOCX[fuel,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]
  end

  WriteDisk(db,"$Input/FsPOCX",FsPOCX)

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  FsPOCX::VariableArray{5} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;EC,ECs,Enduses,Areas,Fuel,Fuels,FuelEP,Nation,Poll,Polls,Years) = data
  (;ANMap,FsPOCX,POCX) = data
  
  #
  # Source:  "Feedstock (Non-Energy) Demands GO 07.xls", 'Notes' sheet from Glasha 2-19-09.
  # Feedstock Emission Coefficients are only for CO2. Units (t CO2/PJ)
  # 03/09/09 RBL.
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  for year in Years, area in areas, poll in Polls, ec in ECs, fuel in Fuels
    FsPOCX[fuel,ec,poll,area,year] = 0.0
  end

  #
  # NGL's
  #
  LPG = Select(Fuel,"LPG")
  poll = Select(Poll,"CO2")
  years = collect(Yr(1990):Yr(1997))
  for ec in ECs, area in areas, year in years 
    FsPOCX[LPG,ec,poll,area,year] = 11176
  end
  years = collect(Yr(1998):Final)
  for ec in ECs, area in areas, year in years 
    FsPOCX[LPG,ec,poll,area,year] = 11692
  end
  
  #
  # Lubricants, Naphtha, NaturalGas, NonEnergy, PetroFeed, Coke
  #
  fuel = Select(Fuel,"Lubricants")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 36006
  end
  fuel = Select(Fuel,"Naphtha")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 17771
  end
  fuel = Select(Fuel,"NaturalGas")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 39780
  end
  fuel = Select(Fuel,"NonEnergy")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 36414
  end
  fuel = Select(Fuel,"PetroFeed")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 14217
  end
  fuel = Select(Fuel,"Coke")
  for ec in ECs, area in areas, year in Years
    FsPOCX[fuel,ec,poll,area,year] = 86021.505
  end
  
  #
  # Convert from Tonnes/PJ to Tonnes/TBtu
  #
  for year in Years, area in areas, poll in Polls, ec in ECs, fuel in Fuels
    FsPOCX[fuel,ec,poll,area,year] = FsPOCX[fuel,ec,poll,area,year] * 1.054615
  end

  #
  # Coal and PetroCoke have same values as combustion emissions for CO2.
  #
  fuel = Select(Fuel,"Coal")
  fuelep = Select(FuelEP,"Coal")
  for year in Years, area in areas, ec in ECs, enduse in Enduses
      FsPOCX[fuel,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]
  end
  fuel = Select(Fuel,"PetroCoke")
  fuelep = Select(FuelEP,"PetroCoke")
  for year in Years, area in areas, ec in ECs, enduse in Enduses
      FsPOCX[fuel,ec,poll,area,year] = POCX[enduse,fuelep,ec,poll,area,year]
  end

  #
  # Natural Gas Feedstocks in Petroleum Refineries and Oil Sands Upgraders
  # are for producing Hydrogen their emissions are already accounted for
  # in the process emissions (MEPol); therefore the feedstock
  # coefficient is set to zero.  J. Amlin 03/26/09
  #

  ecs = Select(EC,["Petroleum","OilSandsUpgraders"])
  fuel = Select(Fuel,"NaturalGas")
  if ecs != []
    for year in Years, area in areas, poll in Polls, ec in ecs
      FsPOCX[fuel,ec,poll,area,year] = 0
    end
  end

  WriteDisk(db,"$Input/FsPOCX",FsPOCX)

end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FsPOCX::VariableArray{6} = ReadDisk(db,"$Input/FsPOCX") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Marginal Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Nation,Poll,Polls,ECs,Fuel,Fuels,Techs,Years) = data
  (;ANMap,FsPOCX) = data
  
  #
  # Source:  "Feedstock (Non-Energy) Demands GO 07.xls", 'Notes' sheet from Glasha 2-19-09.
  # Feedstock Emission Coefficients are only for CO2. Units (t CO2/PJ)
  # 03/09/09 RBL.
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  for year in Years, area in areas, poll in Polls, ec in ECs, tech in Techs, fuel in Fuels
    FsPOCX[fuel,tech,ec,poll,area,year] = 0
  end

  #
  # All Transportation Non-Combustion Emissions are Lubricants
  #
  polls = Select(Poll,"CO2")
  fuel=Select(Fuel,"Lubricants")
  for year in Years, area in areas, poll in polls, ec in ECs, tech in Techs
    FsPOCX[fuel,tech,ec,poll,area,year] = 36006
  end

  #
  # Convert from Tonnes/PJ to Tonnes/TBtu
  #
  for year in Years, area in areas, poll in Polls, ec in ECs, tech in Techs
    FsPOCX[fuel,tech,ec,poll,area,year] = FsPOCX[fuel,tech,ec,poll,area,year] * 1.054615
  end
  
  WriteDisk(db,"$Input/FsPOCX",FsPOCX)

end

function CalibrationControl(db)
  @info "GHG_Feedstocks_US.jl - CalibrationControl"

  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
