#
# ElectricFuelSplits.jl
#
using EnergyModel

module ElectricFuelSplits

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Last
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PFFrac::VariableArray{4} = ReadDisk(db,"EGInput/PFFrac") # [FuelEP,Plant,Area,Year] Fuel Usage Fraction (Btu/Btu)

  # Scratch Variables
end

function ECalibration(db)
  data = ECalib(; db)
  (;Area,Areas,FuelEP,Plant) = data
  (;Years) = data
  (;PFFrac) = data
  
  # *
  # * Default Values
  # *
  @. PFFrac=0.0
  
  NaturalGas = Select(FuelEP,"NaturalGas")
  HFO = Select(FuelEP,"HFO")
  Coal = Select(FuelEP,"Coal")
  Biogas = Select(FuelEP,"Biogas")
  Waste = Select(FuelEP,"Waste")
  Biomass = Select(FuelEP,"Biomass")
  Hydrogen = Select(FuelEP,"Hydrogen")
  Diesel = Select(FuelEP,"Diesel")
  LFO = Select(FuelEP,"LFO")
  PetroCoke = Select(FuelEP,"PetroCoke")
  
  
  
  OGCT = Select(Plant,"OGCT")
  OGCC = Select(Plant,"OGCC")
  OGSteam = Select(Plant,"OGSteam")
  CoalP = Select(Plant,"Coal")
  CoalCCS = Select(Plant,"CoalCCS")
  BiogasP = Select(Plant,"Biogas")
  WasteP = Select(Plant,"Waste")
  BiomassP = Select(Plant,"Biomass")
  FuelCell = Select(Plant,"FuelCell")
  OtherGeneration = Select(Plant,"OtherGeneration")
  
  @. PFFrac[NaturalGas, OGCT, Areas, Years] = 1.0
  @. PFFrac[NaturalGas, OGCC, Areas, Years] = 1.0
  @. PFFrac[HFO, OGSteam, Areas, Years] = 1.0
  @. PFFrac[Coal, CoalP, Areas, Years] = 1.0
  @. PFFrac[Coal, CoalCCS, Areas, Years] = 1.0
  @. PFFrac[Biogas, BiogasP, Areas, Years] = 1.0
  @. PFFrac[Waste, WasteP, Areas, Years] = 1.0
  @. PFFrac[Biomass, BiomassP, Areas, Years] = 1.0
  @. PFFrac[Hydrogen, FuelCell, Areas, Years] = 1.0
  @. PFFrac[NaturalGas, OtherGeneration, Areas, Years] = 1.0
  
  # *
  # * Smaller Provinces and Territories burn Diesel
  # *
  areas = Select(Area,["NL","PE","YT","NT","NU"])
  
  @. PFFrac[Diesel, OGCT, areas, Years] = 1.0
  @. PFFrac[NaturalGas, OGCT, areas, Years] = 0.0
  @. PFFrac[Diesel, OGCC, areas, Years] = 1.0
  @. PFFrac[NaturalGas, OGCC, areas, Years] = 0.0
  @. PFFrac[HFO, OtherGeneration, areas, Years] = 1.0
  @. PFFrac[NaturalGas, OtherGeneration, areas, Years] = 0.0
  
  # *
  # * Historical 
  # *
  years = collect(First:Last)
  ON = Select(Area,"ON")
  @. PFFrac[HFO, OGSteam, ON, years] = 0.0308
  @. PFFrac[NaturalGas, OGSteam, ON, years] = 0.9692
  plants = Select(Plant,["Coal","CoalCCS"])
  @. PFFrac[Coal, plants, ON, years] = 0.9912
  @. PFFrac[NaturalGas, plants, ON, years] = 0.0088
  @. PFFrac[Diesel, OtherGeneration, ON, years] = 1.0
  @. PFFrac[NaturalGas, OtherGeneration, ON, years] = 0.0
  
  QC = Select(Area,"QC")
  @. PFFrac[Diesel, OGCT, QC, years] = 0.0447
  @. PFFrac[HFO, OGCT, QC, years] = 0.1334
  @. PFFrac[LFO, OGCT, QC, years] = 0.0440
  @. PFFrac[NaturalGas, OGCT, QC, years] = 0.7779
  @. PFFrac[Diesel, OtherGeneration, QC, years] = 1.0
  @. PFFrac[NaturalGas, OtherGeneration, QC, years] = 0.0
  
  BC = Select(Area,"BC")
  @. PFFrac[Diesel, OGCT, BC, years] = 0.0748
  @. PFFrac[NaturalGas, OGCT, BC, years] = 0.9252
  @. PFFrac[NaturalGas, OGSteam, BC, years] = 1.0000
  @. PFFrac[HFO, OGSteam, BC, years] = 0.0
  @. PFFrac[LFO, OtherGeneration, BC, years] = 1.0
  @. PFFrac[NaturalGas, OtherGeneration, BC, years] = 0.0
   
  AB = Select(Area,"AB")
  @. PFFrac[Diesel,OGCT,AB, years] = 0.0178
  @. PFFrac[NaturalGas,OGCT,AB,years] =0.9822
  @. PFFrac[NaturalGas,OGCC,AB,years] = 0.9870
  @. PFFrac[PetroCoke, OGCC,AB,years] = 0.0130
  @. PFFrac[NaturalGas,OGSteam,AB,years] = 0.9357
  @. PFFrac[PetroCoke, OGSteam,AB,years] = 0.0643
  @. PFFrac[Coal,plants,AB,years] = 0.9971
  @. PFFrac[NaturalGas,plants,AB,years] = 0.0029
  
  MB = Select(Area,"MB")
  @. PFFrac[Diesel,    OGCT,MB, years] = 1.0000
  @. PFFrac[NaturalGas,OGCT,MB, years] = 0.0000
  @. PFFrac[Coal,      plants,MB, years] = 0.9645
  @. PFFrac[LFO,       plants,MB, years] = 0.0002
  @. PFFrac[NaturalGas,plants,MB, years] = 0.0353
  
  SK = Select(Area,"SK")
  @. PFFrac[Diesel,    OGCT,SK, years] = 0.1133
  @. PFFrac[NaturalGas,OGCT,SK, years] = 0.8867
  @. PFFrac[NaturalGas,OGSteam,SK, years] = 1.0000
  @. PFFrac[HFO,       OGSteam,SK, years] = 0.0000
  @. PFFrac[Coal,      plants,SK, years] = 0.9977
  @. PFFrac[NaturalGas,plants,SK, years] = 0.0023
  
  NB = Select(Area,"NB")
  @. PFFrac[Diesel,    OGCT,NB, years] = 0.0239
  @. PFFrac[LFO,       OGCT,NB, years] = 0.0029
  @. PFFrac[NaturalGas,OGCT,NB, years] = 0.9731
  
  NS = Select(Area,"NS")
  @. PFFrac[Diesel,    OGCT,NS, years] = 1.0000
  @. PFFrac[NaturalGas,OGCC,NS, years] = 1.0000
  @. PFFrac[HFO,       OGSteam,NS, years] = 0.8713
  @. PFFrac[LFO,       OGSteam,NS, years] = 0.0006
  @. PFFrac[NaturalGas,OGSteam,NS, years] = 0.1281
  @. PFFrac[Coal,      plants,NS, years] = 0.7345
  @. PFFrac[HFO,       plants,NS, years] = 0.0236
  @. PFFrac[LFO,       plants,NS, years] = 0.0016
  @. PFFrac[PetroCoke, plants,NS, years] = 0.2402
  
  PE = Select(Area,"PE")
  @. PFFrac[LFO,       OGCT,PE, years] = 1.0000
  @. PFFrac[Diesel,    OGCT,PE, years] = 0.0000
  @. PFFrac[LFO,       OGCC,PE, years] = 1.0000
  @. PFFrac[Diesel,    OGCC,PE, years] = 0.0000
  
  
  WriteDisk(db,"EGInput/PFFrac",PFFrac)
end

function CalibrationControl(db)
  @info "ElectricFuelSplits.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
