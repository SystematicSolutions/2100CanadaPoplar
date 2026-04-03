#
# EnergyDemand_VB_Trans.jl - Map transportation energy demands from VBInput
#
using EnergyModel

module EnergyDemand_VB_Trans

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
  FuelFs::SetArray = ReadDisk(db,"MainDB/FuelFsKey")
  FuelFsDS::SetArray = ReadDisk(db,"MainDB/FuelFsDS")
  FuelFss::Vector{Int} = collect(Select(FuelFs))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmdFuel::VariableArray{6} = ReadDisk(db,"$Input/DmdFuel") # [Enduse,Fuel,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] 'Map between EC and ECC'
  FFsMap::VariableArray{2} = ReadDisk(db,"SInput/FFsMap") # [FuelFs,Fuel] Map between FuelFs and Fuel
  FsDmdFuel::VariableArray{5} = ReadDisk(db,"$Input/FsDmdFuel") # [Fuel,Tech,EC,Area,Year] Historical Feedstock Demands by Fuel
  vTrDmd::VariableArray{5} = ReadDisk(db,"VBInput/vTrDmd") # [Fuel,Tech,EC,Area,Year] Transportation Enduse Demands (TBtu/Yr)
  vTrFsDmd::VariableArray{5} = ReadDisk(db,"VBInput/vTrFsDmd") # [FuelFs,Tech,EC,Area,Year] Feedstock Demands (TBtu/Yr)
  xCgDemand::VariableArray{4} = ReadDisk(db,"SInput/xCgDemand") # [Fuel,ECC,Area,Year] Exogenous Cogeneration Demands (TBtu/Yr)
  xCgDmd::VariableArray{4} = ReadDisk(db,"$Input/xCgDmd") # [Tech,EC,Area,Year] Historical Cogeneration Demand (TBtu/Yr)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Historical Energy Demand (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Exogenous Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Exogenous Feedstock Demands (TBtu/Yr)
  xFsDmd::VariableArray{4} = ReadDisk(db,"$Input/xFsDmd") # [Tech,EC,Area,Year] Historical Feedstock Demand (TBtu/Yr)
end

function TCalibration(db)
  data = TControl(; db)
  (;Input,Areas,ECCs,ECs,Enduses,FuelFss,Fuels,Techs,Years) = data
  (;ECCMap,DmdFuel,FFsMap,FsDmdFuel,vTrDmd,vTrFsDmd,xCgDemand) = data
  (;xCgDmd,xDmd,xEuDemand,xFsDemand,xFsDmd) = data

  # 
  # Enduse Demands
  #
  for eu in Enduses, fuel in Fuels, tech in Techs, ec in ECs, area in Areas, year in Years
    DmdFuel[eu,fuel,tech,ec,area,year] = vTrDmd[fuel,tech,ec,area,year]
  end

  # 
  # Feedstock Demands
  # 
  for fuel in Fuels, tech in Techs, ec in ECs, area in Areas, year in Years
    FsDmdFuel[fuel,tech,ec,area,year] = sum(vTrFsDmd[fuelfs,tech,ec,area,year]*FFsMap[fuelfs,fuel] for fuelfs in FuelFss)
  end

  # 
  # Aggregate Fuels to Techs; No cogeneration in transportation
  # 
  for tech in Techs, ec in ECs, area in Areas, year in Years
    for eu in Enduses
      xDmd[eu,tech,ec,area,year] = sum(DmdFuel[eu,fuel,tech,ec,area,year] for fuel in Fuels)
    end
    xCgDmd[tech,ec,area,year] = 0
    xFsDmd[tech,ec,area,year] = sum(FsDmdFuel[fuel,tech,ec,area,year] for fuel in Fuels)
  end

  # 
  # Total Demands
  #
  for ec in ECs
    for ecc in findall(ECCMap[ec,ECCs] .== 1.0)
      for fuel in Fuels, area in Areas, year in Years
        xEuDemand[fuel,ecc,area,year] = sum(DmdFuel[eu,fuel,tech,ec,area,year] for eu in Enduses, tech in Techs)
        xCgDemand[fuel,ecc,area,year] = 0
        xFsDemand[fuel,ecc,area,year] = sum(FsDmdFuel[fuel,tech,ec,area,year] for tech in Techs)
      end
    end
  end

  WriteDisk(db,"$Input/DmdFuel",DmdFuel)
  WriteDisk(db,"$Input/FsDmdFuel",FsDmdFuel)
  WriteDisk(db,"$Input/xDmd",xDmd)
  WriteDisk(db,"$Input/xFsDmd",xFsDmd)
  WriteDisk(db,"$Input/xCgDmd",xCgDmd)
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)
  WriteDisk(db,"SInput/xCgDemand",xCgDemand)
  WriteDisk(db,"SInput/xFsDemand",xFsDemand)

end

function CalibrationControl(db)
  @info "EnergyDemand_VB_Trans.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
