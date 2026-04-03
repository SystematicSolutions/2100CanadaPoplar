#
# EnergyDemand_VB_Res.jl - Map residential energy demands from VBInput
#
using EnergyModel

module EnergyDemand_VB_Res

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))

  ECCMap::VariableArray{2} = ReadDisk(db, "$Input/ECCMap") # [EC,ECC] 'Map between EC and ECC'
  DmdFuel::VariableArray{6} = ReadDisk(db,"$Input/DmdFuel") # [Enduse,Fuel,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  FsDmdFuel::VariableArray{5} = ReadDisk(db,"$Input/FsDmdFuel") # [Fuel,Tech,EC,Area,Year] Historical Feedstock Demands by Fuel
  vDmd::VariableArray{5} = ReadDisk(db,"VBInput/vDmd") # [vEnduse,Fuel,ECC,Area,Year] Enduse Energy Demands (TBtu/Yr)
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
  vFlMap::VariableArray{2} = ReadDisk(db,"$Input/vFlMap") # [Fuel,Tech] Maps the Fuels from vData into Techs
  vFsDmd::VariableArray{4} = ReadDisk(db,"VBInput/vFsDmd") # [Fuel,ECC,Area,Year] Feedstock Demands (TBtu/Yr)
  vFsMap::VariableArray{2} = ReadDisk(db,"$Input/vFsMap") # [Fuel,Tech] Feedstock Map between Fuel and Tech
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demand (TBtu/Yr)
  xEuDemand::VariableArray{4} = ReadDisk(db,"SInput/xEuDemand") # [Fuel,ECC,Area,Year] Exogenous Energy Demands (TBtu/Yr)
  xFsDemand::VariableArray{4} = ReadDisk(db,"SInput/xFsDemand") # [Fuel,ECC,Area,Year] Exogenous Feedstock Demands (TBtu/Yr)
  xFsDmd::VariableArray{4} = ReadDisk(db,"$Input/xFsDmd") # [Tech,EC,Area,Year] Historical Feedstock Demand (TBtu/Yr)
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECCs,ECs,Enduses,Fuels,Techs) = data
  (;Years,vEnduses) = data
  (;ECCMap,vDmd,vEUMap,vFlMap,vFsMap,vFsDmd) = data
  (;xDmd,xEuDemand,xFsDemand,xFsDmd,DmdFuel,FsDmdFuel) = data

  # 
  # Enduse Demands
  # 
  for ecc in ECCs
    for ec in findall(ECCMap[ECs,ecc] .== 1.0)
      for eu in Enduses
        for veu in findall(vEUMap[vEnduses,eu] .== 1.0)
          for tech in Techs
            for fuel in findall(vFlMap[Fuels,tech] .== 1.0)
              for area in Areas, year in Years
                DmdFuel[eu,fuel,tech,ec,area,year] = vDmd[veu,fuel,ecc,area,year]
              end
            end
          end
        end
      end
    end
  end

  # 
  # Feedstock Demands
  # 
  for fuel in Fuels, tech in Techs, ec in ECs, area in Areas, year in Years
    FsDmdFuel[fuel,tech,ec,area,year] = sum(vFsDmd[fuel,ecc,area,year]*ECCMap[ec,ecc]*vFsMap[fuel,tech] for ecc in ECCs)
  end

  # 
  # Aggregate Fuels to Techs
  # 
  for tech in Techs, ec in ECs, area in Areas, year in Years
    for eu in Enduses
      xDmd[eu,tech,ec,area,year] = sum(DmdFuel[eu,fuel,tech,ec,area,year] for fuel in Fuels)
    end
    xFsDmd[tech,ec,area,year] = sum(FsDmdFuel[fuel,tech,ec,area,year] for fuel in Fuels)
  end

  # 
  # Total Demands
  #
  for ec in ECs
    for ecc in findall(ECCMap[ec,ECCs] .== 1.0)
      for fuel in Fuels, area in Areas, year in Years
        xEuDemand[fuel,ecc,area,year] = sum(DmdFuel[eu,fuel,tech,ec,area,year] for eu in Enduses, tech in Techs)
        xFsDemand[fuel,ecc,area,year] = sum(FsDmdFuel[fuel,tech,ec,area,year] for tech in Techs)
      end
    end
  end

  WriteDisk(db,"$Input/DmdFuel",DmdFuel)
  WriteDisk(db,"$Input/FsDmdFuel",FsDmdFuel)
  WriteDisk(db,"$Input/xDmd",xDmd)
  WriteDisk(db,"$Input/xFsDmd",xFsDmd)
  WriteDisk(db,"SInput/xEuDemand",xEuDemand)
  WriteDisk(db,"SInput/xFsDemand",xFsDemand)

end

function CalibrationControl(db)
  @info "EnergyDemand_VB_Res.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
