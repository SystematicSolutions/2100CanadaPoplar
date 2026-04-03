#
# CAC_OffRoadBiofuels.jl - sets emission coefficients (POCX) for off-road
# biodiesel use for all industrial sectors. The coefficients are set equal
# to the diesel coefficients. 
#
using EnergyModel

module CAC_OffRoadBiofuels

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
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)

end

function Ind_CAC_OffRoadBiofuels(db)
  data = IControl(; db)
  (;Input) = data
  (;EC,Enduse,FuelEP) = data
  (;Nation,Poll) = data
  (;ANMap,POCX) = data

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  polls = Select(Poll,["NOX","SOX","COX","PM25","PM10","PMT","VOC","BC"])
  ecs = Select(EC,(from = "Food",to = "AnimalProduction"))
  Biodiesel = Select(FuelEP,"Biodiesel")
  Diesel = Select(FuelEP,"Diesel")
  OffRoad = Select(Enduse, "OffRoad")
  years = collect(Future:Final)
  
  for ec in ecs, poll in polls, area in areas, year in years
    POCX[OffRoad,Biodiesel,ec,poll,area,year]=POCX[OffRoad,Diesel,ec,poll,area,year]
  end
  
  WriteDisk(db,"$Input/POCX",POCX)
  
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)

end

function Trans_CAC_OffRoadBiofuels(db)
  data = TControl(; db)
  (;Input) = data
  (;EC,Enduses,FuelEP) = data
  (;Nation,Poll) = data
  (;Enduses,Techs) = data
  (;ANMap,POCX) = data

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  polls = Select(Poll,["NOX","SOX","COX","PM25","PM10","PMT","VOC","BC"])
  ecs = Select(EC,["ResidentialOffRoad","CommercialOffRoad"])
  Biodiesel = Select(FuelEP,"Biodiesel")
  Diesel = Select(FuelEP,"Diesel")
  years = collect(Future:Final) 
  
  for enduse in Enduses, tech in Techs, ec in ecs, poll in polls, area in areas, year in years
    POCX[enduse,Biodiesel,tech,ec,poll,area,year] = POCX[enduse,Diesel,tech,ec,poll,area,year]
  end

  WriteDisk(db,"$Input/POCX",POCX)
  
end

function Control(db)
  @info "CAC_OffRoadBiofuels.jl - Control"
  Ind_CAC_OffRoadBiofuels(db)
  Trans_CAC_OffRoadBiofuels(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
