#
# EGCalibSwitches.jl
#
using EnergyModel

module EGCalibSwitches

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  PlantSw::VariableArray{1} = ReadDisk(db,"EGInput/PlantSw") # [Plant] Iteration when this Plant Type begins to be calibrated
  EGCalSw::VariableArray{2} = ReadDisk(db,"EGInput/EGCalSw") # [Nation,Year] Switch for Years to Calibrate Generation (1=Calibrate)

end

function Switches(db)
  data = EControl(; db)
  (;Nation,Plant) = data
  (;PlantSw,EGCalSw) = data
  
  @info "EGCalibSwitches.jl - EGCalibSwitches"  
  
  @. PlantSw = 999
  
  plants = Select(Plant,["OtherGeneration","OnshoreWind","OffshoreWind",
                         "SolarPV","SolarThermal","Wave","Geothermal"])
  for plant in plants
    PlantSw[plant] = 1
  end
  
  plants = Select(Plant,["BaseHydro","PeakHydro","SmallHydro"])
  for plant in plants
    PlantSw[plant] = 1
  end
  
  plants = Select(Plant,"Nuclear")
  for plant in plants
    PlantSw[plant] = 2
  end
  
  plants = Select(Plant,["Coal","CoalCCS","Biomass","BiomassCCS",
                         "FuelCell","Biogas"])
  for plant in plants
    PlantSw[plant] = 3
  end
 
  plants = Select(Plant,"OGSteam")
  for plant in plants
    PlantSw[plant] = 3
  end
  
  plants = Select(Plant,["OGCC","OGCT"])
  for plant in plants
    PlantSw[plant] = 999
  end
  
  plants = Select(Plant,["PumpedHydro","Battery"])
  for plant in plants
    PlantSw[plant] = 999
  end

  WriteDisk(db,"EGInput/PlantSw",PlantSw)  
  
  @. EGCalSw = 0
  
  nation = Select(Nation,"US")
  years = collect(Yr(2019):Yr(2020))
  for year in years
    EGCalSw[nation,year] = 1
  end
  
  nation = Select(Nation,"CN")
  years = collect(Yr(2019):Yr(2021))
  for year in years
    EGCalSw[nation,year] = 1
  end  
  
  nation = Select(Nation,"MX")
  years = collect(Yr(2019):Yr(2020))
  for year in years
    EGCalSw[nation,year] = 1
  end

  WriteDisk(db,"EGInput/EGCalSw",EGCalSw)
  
end

function Control(db)
  @info "EGCalibSwitches.jl - Control"
  Switches(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
