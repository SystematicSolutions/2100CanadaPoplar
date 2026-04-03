#
# DemandTotals.jl
#
using EnergyModel

module DemandTotals

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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  xFsDmd::VariableArray{4} = ReadDisk(db,"$Input/xFsDmd") # [Tech,EC,Area,Year] Feedstock Energy (TBtu/Yr)

  # Scratch Variables
  EuDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  FsDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Feedstock Demands (TBtu/Yr)
end

function ResPolicy(db)
  data = RControl(; db)
  (;Areas,ECs,Enduses,Fuels,Techs,Years,ECC,EC) = data
  (;xDmFrac,xFsFrac,xDmd,xEuDemand,xFsDemand,xFsDmd) = data
  (;EuDemandEC,FsDemandEC) = data

  #
  # Enduse Energy Demands
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC, EC[ec])
      EuDemandEC[fuel,ec,area,year] = sum(xDmd[eu,tech,ec,area,year] * xDmFrac[eu,fuel,tech,ec,area,year] for eu in Enduses, tech in Techs)
      xEuDemand[fuel,ecc,area,year] = EuDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)

  #
  # Feedstocks
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC, EC[ec])
      FsDemandEC[fuel,ec,area,year] = sum(xFsDmd[tech,ec,area,year] * xFsFrac[fuel,tech,ec,area,year] for tech in Techs)
      xFsDemand[fuel,ecc,area,year] = FsDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xFsDemand",xFsDemand)
end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  xFsDmd::VariableArray{4} = ReadDisk(db,"$Input/xFsDmd") # [Tech,EC,Area,Year] Feedstock Energy (TBtu/Yr)

  # Scratch Variables
  EuDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  FsDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Feedstock Demands (TBtu/Yr)
end

function ComPolicy(db)
  data = CControl(; db)
  (;Areas,ECs,Enduses,Fuels,Techs,Years,ECC,EC) = data
  (;xDmFrac,xFsFrac,xDmd,xEuDemand,xFsDemand,xFsDmd) = data
  (;EuDemandEC,FsDemandEC) = data

  #
  # Enduse Energy Demands
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC, EC[ec])
      EuDemandEC[fuel,ec,area,year] = sum(xDmd[eu,tech,ec,area,year] * xDmFrac[eu,fuel,tech,ec,area,year] for eu in Enduses, tech in Techs)
      xEuDemand[fuel,ecc,area,year] = EuDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)

  #
  # Feedstocks
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC, EC[ec])
      FsDemandEC[fuel,ec,area,year] = sum(xFsDmd[tech,ec,area,year] * xFsFrac[fuel,tech,ec,area,year] for tech in Techs)
      xFsDemand[fuel,ecc,area,year] = FsDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xFsDemand",xFsDemand)
end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  xFsDmd::VariableArray{4} = ReadDisk(db,"$Input/xFsDmd") # [Tech,EC,Area,Year] Feedstock Energy (TBtu/Yr)

  # Scratch Variables
  EuDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  FsDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Feedstock Demands (TBtu/Yr)
end

function IndPolicy(db)
  data = IControl(; db)
  (;Areas,ECs,Enduses,Fuels,Techs,Years,ECC,EC) = data
  (;xDmFrac,xFsFrac,xDmd,xEuDemand,xFsDemand,xFsDmd) = data
  (;EuDemandEC,FsDemandEC) = data

  #
  # Enduse Energy Demands
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC, EC[ec])
      EuDemandEC[fuel,ec,area,year] = sum(xDmd[eu,tech,ec,area,year] * xDmFrac[eu,fuel,tech,ec,area,year] for eu in Enduses, tech in Techs)
      xEuDemand[fuel,ecc,area,year] = EuDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)

  #
  # Feedstocks
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC, EC[ec])
      FsDemandEC[fuel,ec,area,year] = sum(xFsDmd[tech,ec,area,year] * xFsFrac[fuel,tech,ec,area,year] for tech in Techs)
      xFsDemand[fuel,ecc,area,year] = FsDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xFsDemand",xFsDemand)
end

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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ECCMap::VariableArray{2} = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  xFsDmd::VariableArray{4} = ReadDisk(db,"$Input/xFsDmd") # [Tech,EC,Area,Year] Feedstock Energy (TBtu/Yr)

  # Scratch Variables
  EuDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  FsDemandEC::VariableArray{4} = zeros(Float32,length(Fuel),length(EC),length(Area),length(Year)) # [Fuel,EC,Area,Year] Feedstock Demands (TBtu/Yr)
end

function TransPolicy(db)
  data = TControl(; db)
  (;Areas,ECs,Enduses,Fuels,Techs,Years,ECC,EC) = data
  (;xDmFrac,xFsFrac,xDmd,xEuDemand,xFsDemand,xFsDmd) = data
  (;EuDemandEC,FsDemandEC) = data

  #
  # Enduse Energy Demands
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC,EC[ec])
      EuDemandEC[fuel,ec,area,year] = sum(xDmd[eu,tech,ec,area,year] * xDmFrac[eu,fuel,tech,ec,area,year] for eu in Enduses, tech in Techs)
      xEuDemand[fuel,ecc,area,year] = EuDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)

  #
  # Feedstocks
  #
  for year in Years, area in Areas, fuel in Fuels
    for ec in ECs
      ecc = Select(ECC, EC[ec])
      FsDemandEC[fuel,ec,area,year] = sum(xFsDmd[tech,ec,area,year] * xFsFrac[fuel,tech,ec,area,year] for tech in Techs)
      xFsDemand[fuel,ecc,area,year] = FsDemandEC[fuel,ec,area,year]
    end
  end
  WriteDisk(db,"SInput/xFsDemand",xFsDemand)
end

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (TBtu/Yr)
  xCgEC::VariableArray{3} = ReadDisk(db,"SInput/xCgEC") # [ECC,Area,Year] Cogeneration by Economic Category (GWh/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)
end

function MacroPolicy(db)
  data = MControl(; db)
  (;Areas,ECCs,Fuel,Years) = data
  (;EEConv,xCgDemand,xCgEC,xEuDemand,xFsDemand,xTotDemand) = data

  #
  # Total Fuel Demands
  #
  @. xTotDemand = xEuDemand + xCgDemand + xFsDemand
  Electric = Select(Fuel,"Electric")

  for year in Years, area in Areas, ecc in ECCs
    xTotDemand[Electric,ecc,area,year] = xTotDemand[Electric,ecc,area,year] - xCgEC[ecc,area,year]*EEConv/1E6
  end

  WriteDisk(db,"SInput/xTotDemand",xTotDemand)
end

function CalibrationControl(db)
  @info "DemandTotals.jl - CalibrationControl"

  ResPolicy(db)
  ComPolicy(db)
  IndPolicy(db)
  TransPolicy(db)
  MacroPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
