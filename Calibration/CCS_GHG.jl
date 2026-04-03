#
# CCS_GHG.jl - GHG Carbon Sequestration - Jeff Amlin 10/3/21
#
using EnergyModel

module CCS_GHG

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ECCMap = ReadDisk(db, "$Input/ECCMap") # (EC,ECC) 'Map between EC and ECC'
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Enduse Demand Pollution Coefficients (Tonnes/TBtu)
  SqPenaltyTech::VariableArray{5} = ReadDisk(db,"$Input/SqPenaltyTech") # [Tech,EC,Poll,Area,Year] Sequestering Energy Penalty (TBtu/Tonne)
  SqPenaltyFrac::VariableArray{4} = ReadDisk(db,"MEInput/SqPenaltyFrac") # [ECC,Poll,Area,Year] Sequestering Emission Penalty (Tonne/Tonne)
  SqPolCCNet::VariableArray{4} = ReadDisk(db,"SOutput/SqPolCCNet") # [ECC,Poll,Area,Year] Sequestering Non-Cogeneration Emissions (Tonnes/Yr)
  xSqPol::VariableArray{4} = ReadDisk(db,"MEInput/xSqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)
  xSqPolCCNet::VariableArray{4} = ReadDisk(db,"MEInput/xSqPolCCNet") # [ECC,Poll,Area,Year] Sequestering Net Emissions (Tonnes/Yr)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xSqDmd::VariableArray{4} = ReadDisk(db,"$Input/xSqDmd") # [Tech,EC,Area,Year] Sequestering Energy Demand (TBtu/Yr)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,Areas,Enduse,EC,ECC,FuelEP,Poll,Polls,Tech,Techs,Years) = data
  (;xSqPol,POCX,SqPenaltyTech,SqPenaltyFrac,SqPolCCNet,xSqPolCCNet,xDmd,xSqDmd) = data

  #
  # Gross Sequestering
  #
  # Sequestering for Agrium
  # Source: email from Thuo July 6, 2021 - Jeff Amlin 07/06/21
  #
  poll = Select(Poll,"CO2")
  Fertilizer = Select(ECC,"Fertilizer")
  area = Select(Area,"AB")
  years = collect(Yr(2020):Final)
  for year in years
    xSqPol[Fertilizer,poll,area,year] = xSqPol[Fertilizer,poll,area,year] - 0.1528 * 1e6
  end
  area = Select(Area,"SK")
  years = collect(Yr(1998):Final)
  for year in years
    xSqPol[Fertilizer,poll,area,year] = xSqPol[Fertilizer,poll,area,year] - 0.00254 * 1e6
  end
  years = collect(Yr(1990):Yr(1997))
  for year in years
    xSqPol[Fertilizer,poll,area,year] = xSqPol[Fertilizer,poll,area,year] - 0.00481 * 1e6
  end

  #
  # Sequestering for Refineries
  # Source: from Thuo Sept 11, 2024
  #
  poll = Select(Poll,"CO2")
  Petroleum = Select(ECC,"Petroleum")
  area = Select(Area,"AB")
  xSqPol[Petroleum,poll,area,Yr(2020)]= 0 - 820200
  xSqPol[Petroleum,poll,area,Yr(2021)]= 0 - 1141318
  xSqPol[Petroleum,poll,area,Yr(2022)]= 0 - 926123
  xSqPol[Petroleum,poll,area,Yr(2023)]= 0 - 1289833
    years = collect(Yr(2024):Final)
  for year in years
    xSqPol[Petroleum,poll,area,year] = xSqPol[Petroleum,poll,area,year] - 1.18 * 1e6
  end

  #
  # Scotford Upgrader with Quest CCS is 1MT in 2015
  #
  # Starting in 2026, additional reduction are due to the The Increase Capture Efficiency project funded by the LCEF challenge program.
  # The scope of the Project aims to increase the CO2 capture from the Scotford Upgrader by implementing design improvements to Quest. 
  # These improvements are limited to Quest's CO2 capture and compression infrastructure and all project components will be limited to the existing footprint of the Scotford Upgrader
  #  Given that the reductions vary very little from one year to the next between 2026 and 2045 in the GHG workbook we received, 
  # I used the average reductions expected for this project over that period. This corresponds to 0.289508 MT.
  #  Reduction in 2026 = reduction in 2025 (1.003Mt) + 0.289508 MT
  # 

  OilSandsUpgraders = Select(ECC,"OilSandsUpgraders")
  years = collect(Yr(2012):Yr(2014))
  for year in years
    xSqPol[OilSandsUpgraders,poll,area,year] = 0
  end
  years = collect(Yr(2015):Yr(2026))
  xSqPol[OilSandsUpgraders,poll,area,years] .= [
  -370992
  -1108063
  -1138422
  -1066284
  -1128258
  -940708
  -1055051
  -970737
  -1003108
  -1003108
  -1003108
  -1292616
  ]
  years = collect(Yr(2027):Final)
  for year in years
    xSqPol[OilSandsUpgraders,poll,area,year] = xSqPol[OilSandsUpgraders,poll,area,Yr(2026)]
  end

  WriteDisk(db,"MEInput/xSqPol",xSqPol)

  #
  #########################
  #
  # Net Sequestering
  #
  ecs = Select(EC,["Fertilizer","Petroleum","OilSandsUpgraders"])
  eccs = Select(ECC,["Fertilizer","Petroleum","OilSandsUpgraders"])

  #
  # Emission Penalty is assumed to be all Natural Gas
  #
  Heat = Select(Enduse,"Heat")
  Gas = Select(Tech,"Gas")
  NaturalGas = Select(FuelEP,"NaturalGas")
  for ec in ecs
    ecc= Select(ECC,EC[ec])
    for poll in Polls, year in Years
      SqPenaltyFrac[ecc,poll,area,year] = SqPenaltyTech[Gas,ec,poll,area,year] *
                                          POCX[Heat,NaturalGas,ec,poll,area,year]
    end
  end

  WriteDisk(db,"MEInput/SqPenaltyFrac",SqPenaltyFrac)

  for ecc in eccs, poll in Polls, year in Years
    xSqPolCCNet[ecc,poll,area,year] = xSqPol[ecc,poll,area,year] / (1 + SqPenaltyFrac[ecc,poll,area,year])
  end

  WriteDisk(db,"MEInput/xSqPolCCNet",xSqPolCCNet)

  #
  # Set model value for industrial calibration - Jeff Amlin 07/06/22
  #
  for year in Years, area in Areas, poll in Polls, ecc in eccs
    SqPolCCNet[ecc,poll,area,year] = xSqPolCCNet[ecc,poll,area,year]
  end  

  WriteDisk(db,"SOutput/SqPolCCNet",SqPolCCNet)

  #
  #########################
  #
  # Sequestering Energy Penalty
  #

  ecs = Select(EC,["Fertilizer","Petroleum","OilSandsUpgraders"])
  for ec in ecs
    ecc= Select(ECC,EC[ec])
    for tech in Techs, year in Years
      xSqDmd[tech,ec,area,year] = sum(0 - xSqPolCCNet[ecc,poll,area,year] *
                                      SqPenaltyTech[tech,ec,poll,area,year] for poll in Polls)
    end
  end

  WriteDisk(db,"$Input/xSqDmd",xSqDmd)

  Motors = Select(Enduse,"Motors")
  for tech in Techs, ec in ecs, year in Years
    if Tech[tech] == "Electric"
      xDmd[Motors,tech,ec,area,year] = xDmd[Motors,tech,ec,area,year] - xSqDmd[tech,ec,area,year]
    else
      xDmd[Heat,tech,ec,area,year] = xDmd[Heat,tech,ec,area,year] - xSqDmd[tech,ec,area,year]
    end
  end

  WriteDisk(db,"$Input/xDmd",xDmd)

end

function CalibrationControl(db)
  @info "CCS_GHG.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
