#
# ParasiticLoss.jl - 
#

using EnergyModel

module ParasiticLoss

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  RPEIX::VariableArray{5} = ReadDisk(db,"$Input/RPEIX") # [Enduse,Tech,EC,Area,Year] Energy Impact of Pollution Reduction Coefficient (Btu/Btu/Tonne/Tonne)
end

function IndPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; EC,Enduse) = data 
  (; Nation,Techs,Years) = data
  (; ANMap,RPEIX) = data

  # 
  # Parasitic loss data comes from 'Collateral Impacts Summary.xls' via Seton Steiber at EnviroEconomics
  # Data needs to be read in as % change in energy usage over % reduction in emissions
  # Ian 01/07/2012
  # 
  # Assume all parasitic losses come from Primary Heat
  #   
  Heat = Select(Enduse,"Heat")
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  # 
  Aluminum = Select(EC,"Aluminum")
  for year in Years, area in areas, tech in Techs
    RPEIX[Heat,tech,Aluminum,area,year] = 0.000042
  end
  
  OilSandsUpgraders = Select(EC,"OilSandsUpgraders")
  for year in Years, area in areas, tech in Techs
    RPEIX[Heat,tech,OilSandsUpgraders,area,year] = 0.000172
  end
  
  ecs = Select(EC,["Rubber","OtherChemicals"])
  for year in Years, area in areas, ec in ecs, tech in Techs
    RPEIX[Heat,tech,ec,area,year] = 0.00403
  end
  
  Petroleum = Select(EC,"Petroleum")
  for year in Years, area in areas, tech in Techs
    RPEIX[Heat,tech,Petroleum,area,year] = 0.000032
  end

  WriteDisk(db,"$Input/RPEIX",RPEIX)
end

function PolicyControl(db)
  @info "ParasiticLoss.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
