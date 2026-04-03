#
# CAC_TransBiofuels_3.jl - this file calculates the CAC coefficients
# for biofuels in the the transportation sector including the enduse (POCX)
# and non-combustion (FsPOCX).
# Luke Davulis 6/7/17
#
using EnergyModel

module CAC_TransBiofuels

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
  POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Pollution coefficient (Tonnes/TBtu)

  # Scratch Variables
end

function TransPolicy(db)
  data = TControl(; db)
  (;Input) = data
  (;EC,FuelEP) = data
  (;Nation,Poll,Tech) = data
  (;ANMap,POCX) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1)
  years = collect(Future:Final)

  # *
  # ***Ethanol Coefficients***
  # *
  # ***Passenger***
  # *
  Passenger = Select(EC,"Passenger")
  Ethanol = Select(FuelEP,"Ethanol")
  Gasoline = Select(FuelEP,"Gasoline")
  techs = Select(Tech,["LDVHybrid","LDTHybrid","LDVGasoline","LDTGasoline","Motorcycle","BusGasoline"])

  polls = Select(Poll,["PMT","PM10","PM25"])
  @. POCX[1,Ethanol,techs,Passenger,polls,areas,years] = POCX[1,Gasoline,techs,Passenger,polls,areas,years] * (1.0-0.0)

  NOX = Select(Poll,"NOX")
  @. POCX[1,Ethanol,techs,Passenger,NOX,areas,years] = POCX[1,Gasoline,techs,Passenger,NOX,areas,years] * (1.0+0.13)

  COX = Select(Poll,"COX")
  @. POCX[1,Ethanol,techs,Passenger,COX,areas,years] = POCX[1,Gasoline,techs,Passenger,COX,areas,years] * (1.0-0.22)

  VOC = Select(Poll,"VOC")
  @. POCX[1,Ethanol,techs,Passenger,VOC,areas,years] = POCX[1,Gasoline,techs,Passenger,VOC,areas,years] * (1.0+0.12)

  polls = Select(Poll,["NH3","BC","Hg"])
  @. POCX[1,Ethanol,techs,Passenger,polls,areas,years] = POCX[1,Gasoline,techs,Passenger,polls,areas,years]

  # *
  # ***Commercial/Residential OffRoad***
  # *

  ecs = Select(EC,["ResidentialOffRoad","CommercialOffRoad"])
  OffRoad = Select(Tech,"OffRoad")

  polls = Select(Poll,["PMT","PM10","PM25"])
  @. POCX[1,Ethanol,OffRoad,ecs,polls,areas,years] = POCX[1,Gasoline,OffRoad,ecs,polls,areas,years] * (1.0-0.0)

  NOX = Select(Poll,"NOX")
  @. POCX[1,Ethanol,OffRoad,ecs,NOX,areas,years] = POCX[1,Gasoline,OffRoad,ecs,NOX,areas,years] * (1.0+0.13)

  COX = Select(Poll,"COX")
  @. POCX[1,Ethanol,OffRoad,ecs,COX,areas,years] = POCX[1,Gasoline,OffRoad,ecs,COX,areas,years] * (1.0-0.22)

  VOC = Select(Poll,"VOC")
  @. POCX[1,Ethanol,OffRoad,ecs,VOC,areas,years] = POCX[1,Gasoline,OffRoad,ecs,VOC,areas,years] * (1.0+0.12)

  polls = Select(Poll,["SOX","NH3","BC","Hg"])
  @. POCX[1,Ethanol,OffRoad,ecs,polls,areas,years] = POCX[1,Gasoline,OffRoad,ecs,polls,areas,years]


  # *
  # ***Biodiesel Coefficients***
  # *
  # ***Passenger***
  # *

  techs = Select(Tech,["BusDiesel","LDVDiesel","LDTDiesel"])
  Biodiesel = Select(FuelEP,"Biodiesel")
  Diesel = Select(FuelEP,"Diesel")


  # polls = Select(Poll,["PMT","PM10","PM25"])
  # @. POCX[1,Biodiesel,techs,Passenger,polls,areas,years] = POCX[1,Diesel,techs,Passenger,polls,areas,years] * (1.0-0.68)

  # NOX = Select(Poll,"NOX")
  # @. POCX[1,Biodiesel,techs,Passenger,NOX,areas,years] = POCX[1,Diesel,techs,Passenger,NOX,areas,years] * (1.0+0.89)

  # COX = Select(Poll,"COX")
  # @. POCX[1,Biodiesel,techs,Passenger,COX,areas,years] = POCX[1,Diesel,techs,Passenger,COX,areas,years] * (1.0-0.46)

  # VOC = Select(Poll,"VOC")
  # @. POCX[1,Biodiesel,techs,Passenger,VOC,areas,years] = POCX[1,Diesel,techs,Passenger,VOC,areas,years] * (1.0+0.12)

  # polls = Select(Poll,["NH3","BC","Hg","VOC"])
  # @. POCX[1,Biodiesel,techs,Passenger,polls,areas,years] = POCX[1,Diesel,techs,Passenger,polls,areas,years]

  # SOX = Select(Poll,"SOX")
  # @. POCX[1,Biodiesel,techs,Passenger,SOX,areas,years] = POCX[1,Diesel,techs,Passenger,SOX,areas,years] * (1.0-1.0)

  polls = Select(Poll,["NOX","SOX","COX","PM25","PM10","PMT","VOC","BC","NH3","Hg"])
  @. POCX[1,Biodiesel,techs,Passenger,polls,areas,years] = POCX[1,Diesel,techs,Passenger,polls,areas,years]

  # *
  # ***Passenger Train***
  # *
  TrainDiesel = Select(Tech,"TrainDiesel")

  polls = Select(Poll,["PMT","PM10","PM25"])
  @. POCX[1,Biodiesel,TrainDiesel,Passenger,polls,areas,years] = POCX[1,Diesel,TrainDiesel,Passenger,polls,areas,years] * (1.0-0.481)

  NOX = Select(Poll,"NOX")
  @. POCX[1,Biodiesel,TrainDiesel,Passenger,NOX,areas,years] = POCX[1,Diesel,TrainDiesel,Passenger,NOX,areas,years] * (1.0+0.1)

  COX = Select(Poll,"COX")
  @. POCX[1,Biodiesel,TrainDiesel,Passenger,COX,areas,years] = POCX[1,Diesel,TrainDiesel,Passenger,COX,areas,years] * (1.0-0.49)

  polls = Select(Poll,["NH3","BC","Hg","VOC"])
  @. POCX[1,Biodiesel,TrainDiesel,Passenger,polls,areas,years] = POCX[1,Diesel,TrainDiesel,Passenger,polls,areas,years]

  SOX = Select(Poll,"SOX")
  @. POCX[1,Biodiesel,TrainDiesel,Passenger,SOX,areas,years] = POCX[1,Diesel,TrainDiesel,Passenger,SOX,areas,years] * (1.0-1.0)




  # *
  # ***Freight***
  # *
  Freight = Select(EC,"Freight")
  techs = Select(Tech,["TrainDiesel","HDV2B3Diesel","HDV45Diesel",
  "HDV67Diesel","HDV8Diesel","MarineLight","MarineHeavy"])

  # polls = Select(Poll,["PMT","PM10","PM25"])
  # @. POCX[1,Biodiesel,techs,Freight,polls,areas,years] = POCX[1,Diesel,techs,Freight,polls,areas,years] * (1.0-0.481)

  # NOX = Select(Poll,"NOX")
  # @. POCX[1,Biodiesel,techs,Freight,NOX,areas,years] = POCX[1,Diesel,techs,Freight,NOX,areas,years] * (1.0+0.1)

  # COX = Select(Poll,"COX")
  # @. POCX[1,Biodiesel,techs,Freight,COX,areas,years] = POCX[1,Diesel,techs,Freight,COX,areas,years] * (1.0-0.49)

  # polls = Select(Poll,["NH3","BC","Hg","VOC"])
  # @. POCX[1,Biodiesel,techs,Freight,polls,areas,years] = POCX[1,Diesel,techs,Freight,polls,areas,years]

  # SOX = Select(Poll,"SOX")
  # @. POCX[1,Biodiesel,techs,Freight,SOX,areas,years] = POCX[1,Diesel,techs,Freight,SOX,areas,years] * (1.0-1.0)

  Diesel = Select(FuelEP,"Diesel")
  polls = Select(Poll,["NOX","SOX","COX","PM25","PM10","PMT","VOC","BC","NH3","Hg"])
  @. POCX[1,Biodiesel,techs,Freight,polls,areas,years] = POCX[1,Diesel,techs,Freight,polls,areas,years]

  # *
  # ***Freight Train/Marine***
  # *
  techs = Select(Tech,["TrainDiesel","MarineLight","MarineHeavy"])

  polls = Select(Poll,["PMT","PM10","PM25"])
  @. POCX[1,Biodiesel,techs,Freight,polls,areas,years] = POCX[1,Diesel,techs,Freight,polls,areas,years] * (1.0-0.481)

  NOX = Select(Poll,"NOX")
  @. POCX[1,Biodiesel,techs,Freight,NOX,areas,years] = POCX[1,Diesel,techs,Freight,NOX,areas,years] * (1.0+0.1)

  COX = Select(Poll,"COX")
  @. POCX[1,Biodiesel,techs,Freight,COX,areas,years] = POCX[1,Diesel,techs,Freight,COX,areas,years] * (1.0-0.49)

  polls = Select(Poll,["NH3","BC","Hg","VOC"])
  @. POCX[1,Biodiesel,techs,Freight,polls,areas,years] = POCX[1,Diesel,techs,Freight,polls,areas,years]

  SOX = Select(Poll,"SOX")
  @. POCX[1,Biodiesel,techs,Freight,SOX,areas,years] = POCX[1,Diesel,techs,Freight,SOX,areas,years] * (1.0-1.0)


  # *
  # ***Foreign Freight***
  # *
  ForeignFreight = Select(EC,"ForeignFreight")
  MarineLight = Select(Tech,"MarineLight")

  polls = Select(Poll,["PMT","PM10","PM25"])
  @. POCX[1,Biodiesel,MarineLight,ForeignFreight,polls,areas,years] = POCX[1,Diesel,MarineLight,ForeignFreight,polls,areas,years] * (1.0-0.481)

  NOX = Select(Poll,"NOX")
  @. POCX[1,Biodiesel,MarineLight,ForeignFreight,NOX,areas,years] = POCX[1,Diesel,MarineLight,ForeignFreight,NOX,areas,years] * (1.0+0.1)

  COX = Select(Poll,"COX")
  @. POCX[1,Biodiesel,MarineLight,ForeignFreight,COX,areas,years] = POCX[1,Diesel,MarineLight,ForeignFreight,COX,areas,years] * (1.0-0.49)

  polls = Select(Poll,["NH3","BC","Hg","VOC"])
  @. POCX[1,Biodiesel,MarineLight,ForeignFreight,polls,areas,years] = POCX[1,Diesel,MarineLight,ForeignFreight,polls,areas,years]

  SOX = Select(Poll,"SOX")
  @. POCX[1,Biodiesel,MarineLight,ForeignFreight,SOX,areas,years] = POCX[1,Diesel,MarineLight,ForeignFreight,SOX,areas,years] * (1.0-1.0)


  # *
  # ***Commercial/Residential OffRoad***
  # *

  ecs = Select(EC,["ResidentialOffRoad","CommercialOffRoad"])

  polls = Select(Poll,["PMT","PM10","PM25"])
  @. POCX[1,Biodiesel,OffRoad,ecs,polls,areas,years] = POCX[1,Diesel,OffRoad,ecs,polls,areas,years] * (1.0-0.481)

  NOX = Select(Poll,"NOX")
  @. POCX[1,Biodiesel,OffRoad,ecs,NOX,areas,years] = POCX[1,Diesel,OffRoad,ecs,NOX,areas,years] * (1.0+0.1)

  COX = Select(Poll,"COX")
  @. POCX[1,Biodiesel,OffRoad,ecs,COX,areas,years] = POCX[1,Diesel,OffRoad,ecs,COX,areas,years] * (1.0-0.49)

  polls = Select(Poll,["NH3","BC","Hg","VOC"])
  @. POCX[1,Biodiesel,OffRoad,ecs,polls,areas,years] = POCX[1,Diesel,OffRoad,ecs,polls,areas,years]

  SOX = Select(Poll,"SOX")
  @. POCX[1,Biodiesel,OffRoad,ecs,SOX,areas,years] = POCX[1,Diesel,OffRoad,ecs,SOX,areas,years] * (1.0-1.0)

  WriteDisk(db, "$Input/POCX", POCX)

end

function CalibrationControl(db)
  @info "CAC_TransBiofuels.jl - CalibrationControl"

  TransPolicy(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
