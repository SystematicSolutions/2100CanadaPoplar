#
# GHG_Transportation_CA.jl - California transportaion GHG coefficients
# for enduse (POCX) and process (TrMEPX) emissions - Luke Davulis 1/8/16
#
using EnergyModel

module GHG_Transportation_CA

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

  POCX::VariableArray{7} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,EC,ECs,Enduses,FuelEP,Poll,Polls,Tech,Techs,Years) = data
  (;POCX) = data
  
  #
  #########################
  #
  # Ethanol POCX based in ratio with Gasoline based on Data Sources for
  # California GHG Inventory: www.arb.ca.gov/cc/inventory/doc/doc_index.php
  #
  # Ethanol: 5749 g CO2 Per Gallon; Gasoline 8917 g CO2 Per Gallon
  # Ethanol and Gasoline: Other pollutants are same mass per gallon
  # Ethanol: 84000 btu/gal; Gasoline 125000 btu/gal
  #
  area = Select(Area,"CA")
  Ethanol = Select(FuelEP,"Ethanol")
  Gasoline = Select(FuelEP,"Gasoline")
  for year in Years, poll in Polls, ec in ECs, tech in Techs, enduse in Enduses 
    POCX[enduse,Ethanol,tech,ec,poll,area,year] = POCX[enduse,Gasoline,tech,ec,poll,area,year] * (125 / 84)
  end
  CO2 = Select(Poll,"CO2")
  for year in Years, ec in ECs, tech in Techs, enduse in Enduses
    POCX[enduse,Ethanol,tech,ec,CO2,area,year] = POCX[enduse,Gasoline,tech,ec,CO2,area,year] * (5749 / 8917 * 125 / 84)
  end
  
  LDVEthanol = Select(Tech,"LDVEthanol")
  LDTEthanol = Select(Tech,"LDTEthanol")
  LDVGasoline = Select(Tech,"LDVGasoline")
  LDTGasoline = Select(Tech,"LDTGasoline")
  
  for year in Years, poll in Polls, ec in ECs, enduse in Enduses
    POCX[enduse,Ethanol,LDVEthanol,ec,poll,area,year] = POCX[enduse,Ethanol,LDVGasoline,ec,poll,area,year]
  end  
    
  for year in Years, poll in Polls, ec in ECs, enduse in Enduses  
    POCX[enduse,Ethanol,LDTEthanol,ec,poll,area,year] = POCX[enduse,Ethanol,LDTGasoline,ec,poll,area,year]
  end
  
  #
  # Train Diesel and Marine Light N2O pollution are too high.  POCX seem high for these 
  # fuels and tech, and higher than other similar tech/fuel combinations. GHG Inventories
  # documentation indicate that Marine Distillate and Residual fuel oil have similar
  # coefficients.  www.arb.ca.gov/cc/inventory/doc/doc_index.php
  #
  Diesel = Select(FuelEP,"Diesel")
  HFO = Select(FuelEP,"HFO")
  MarineLight = Select(Tech,"MarineLight")
  MarineHeavy = Select(Tech,"MarineHeavy")
  TrainDiesel = Select(Tech,"TrainDiesel")
  for year in Years, poll in Polls, ec in ECs, enduse in Enduses
    POCX[enduse,Diesel,MarineLight,ec,poll,area,year] = POCX[enduse,HFO,MarineHeavy,ec,poll,area,year]
  end
  
  for year in Years, poll in Polls, ec in ECs, enduse in Enduses  
    POCX[enduse,Diesel,TrainDiesel,ec,poll,area,year] = POCX[enduse,Diesel,MarineLight,ec,poll,area,year]
  end
  
  #
  # Passenger Gasoline Emissions coefficients in the GHG Inventory decrease over time.
  # www.arb.ca.gov/cc/inventory/doc/doc_index.php
  #
  years = collect(Yr(2000):Yr(2013))
  Passenger = Select(EC,"Passenger")
  N2O = Select(Poll,"N2O")

  techs = Select(Tech,["LDVGasoline","LDTGasoline"])
  for enduse in Enduses, tech in techs, year in years
    POCX[enduse,Gasoline,tech,Passenger,N2O,area,year] = 0.9 * POCX[enduse,Gasoline,tech,Passenger,N2O,area,year-1]
  end
  tech = Select(Tech,"BusGasoline")
  for enduse in Enduses, year in years
    POCX[enduse,Gasoline,tech,Passenger,N2O,area,year] = 0.96 * POCX[enduse,Gasoline,tech,Passenger,N2O,area,year-1]
  end
  tech = Select(Tech,"Motorcycle")
  for enduse in Enduses, year in years
    POCX[enduse,Gasoline,tech,Passenger,N2O,area,year] = 0.994 * POCX[enduse,Gasoline,tech,Passenger,N2O,area,year-1]
  end

  years = collect(Yr(2014):Final)
  techs = Select(Tech,["LDVGasoline","LDTGasoline","Motorcycle"])
  for enduse in Enduses, tech in techs, year in years
    POCX[enduse,Gasoline,tech,Passenger,N2O,area,year] = POCX[enduse,Gasoline,tech,Passenger,N2O,area,Yr(2013)]
  end

  WriteDisk(db,"$Input/POCX",POCX)

end

function CalibrationControl(db)
  @info "GHG_Transportation_CA.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
