#
# EfficiencyReference_OG.jl - The OG production sectors use the
# Device and Process efficiency from the Reference Case.
#

using EnergyModel

module EfficiencyReference_OG

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DEESw::VariableArray{5} = ReadDisk(db,"$Input/DEESw") # [Enduse,Tech,EC,Area,Year] Switch for Device Efficiency (Switch)
  PEESw::VariableArray{5} = ReadDisk(db,"$Input/PEESw") # [Enduse,Tech,EC,Area,Year] Switch for Process Efficiency (Switch)

end

function OGPolicy(db)
  data = IControl(; db)
  (; Input) = data
  (; Enduses,Techs,EC,Areas) = data
  (; DEESw,PEESw) = data

  #
  # Set DEESw, PEESw to 6
  #
  years = collect(Future:Final)
  ecs = Select(EC,["LightOilMining","HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders","ConventionalGasProduction","SweetGasProcessing","UnconventionalGasProduction","SourGasProcessing","LNGProduction"])
  for year in years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    DEESw[enduse,tech,ec,area,year] = 6
    PEESw[enduse,tech,ec,area,year] = 6
  end

  WriteDisk(db,"$Input/DEESw",DEESw)
  WriteDisk(db,"$Input/PEESw",PEESw)

end

function PolicyControl(db)
  @info "EfficiencyReference_OG.jl - PolicyControl"
  OGPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
