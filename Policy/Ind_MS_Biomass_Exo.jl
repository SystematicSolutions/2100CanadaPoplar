#
# Ind_MS_Biomass_Exo.jl
#
using EnergyModel

module Ind_MS_Biomass_Exo

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String
  
  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput" 
  
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
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PIDS::SetArray = ReadDisk(db,"$Input/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  AMSF::VariableArray{5} = ReadDisk(db,"$Outpt/AMSF") # [Enduse,Tech,EC,Area,Year] Average Market Share
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  MMSFExogenous::VariableArray{5} = ReadDisk(db,"$Input/MMSFExogenous") # [Enduse,Tech,EC,Area,Year] Exogenous Market Share Fraction ($/$)
  MMSFSwitch::VariableArray{5} = ReadDisk(db,"$Input/MMSFSwitch") # [Enduse,Tech,EC,Area,Year] Market Share Switch (1=Endogenous, 0=Exogenous)
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)
  xProcSw::VariableArray{2} = ReadDisk(db,"$Input/xProcSw") #[PI,Year] "Procedure on/off Switch"
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0

end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input) = data
  (; ECs,Enduse,Enduses,Areas,Nation,PI,Tech,Techs) = data
  (; AMSF,ANMap,Exogenous,MMSFExogenous,MMSFSwitch,xMMSF,xProcSw) = data

  #
  # Allow for exogneous market shares
  #
  years = collect(Future:Final)
  MShare = Select(PI,"MShare")
  for year in years
    xProcSw[MShare,year] = Exogenous
  end
  WriteDisk(db,"$Input/xProcSw",xProcSw)

  #
  # Biomass in Canada is exogenous
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  Heat = Select(Enduse,"Heat")
  Biomass = Select(Tech,"Biomass")
  for year in years, area in areas, ec in ECs
    MMSFExogenous[Heat,Biomass,ec,area,year] = AMSF[Heat,Biomass,ec,area,Last]
  end
  for year in years, area in areas, ec in ECs
    MMSFSwitch[Heat,Biomass,ec,area,year] = 0.0
  end  
  WriteDisk(db,"$Input/MMSFSwitch",MMSFSwitch)
  WriteDisk(db,"$Input/MMSFExogenous",MMSFExogenous)

end

function PolicyControl(db)
  @info("Ind_MS_Biomass_Exo.jl PolicyControl function called")
  IndPolicy(db)
  @info("Policy executed succecsfully")
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
