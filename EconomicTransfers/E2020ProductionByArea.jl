#
# E2020ProductionByArea.jl
#
using EnergyModel

module E2020ProductionByArea

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelAggTOM::SetArray = ReadDisk(db,"KInput/FuelAggTOMKey")
  FuelAggTOMDS::SetArray = ReadDisk(db,"KInput/FuelAggTOMDS")
  FuelAggTOMs::Vector{Int} = collect(Select(FuelAggTOM))
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CAProd::VariableArray{2} = ReadDisk(db,"SOutput/CAProd") # [Area,Year] Primary Coal Production (TBtu/Yr)
  EAProd::VariableArray{3} = ReadDisk(db,"SOutput/EAProd") # [Plant,Area,Year] Electric Utility Production (GWh/Yr)
  GAProd::VariableArray{3} = ReadDisk(db,"SOutput/GAProd") # [Process,Area,Year] Primary Gas Production (TBtu/Yr)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapOGProductionTOM::VariableArray{2} = ReadDisk(db,"KInput/MapOGProductionTOM") #[Process,FuelAggTOM] Map of Oil Gas Processes to FuelAggTOM
  OAProd::VariableArray{3} = ReadDisk(db,"SOutput/OAProd") # [Process,Area,Year] Primary Oil Production (TBtu/Yr)
  Q::VariableArray{3} = ReadDisk(db,"KOutput/Q") # [FuelAggTOM,AreaTOM,Year] Energy Production (TBtu/Yr)
  Qe::VariableArray{3} = ReadDisk(db,"KOutput/Qe") # [FuelAggTOM,AreaTOM,Year] Energy Production (TBtu/Yr)
  RPPAProd::VariableArray{2} = ReadDisk(db,"SpOutput/RPPAProd") # [Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPProdArea::VariableArray{3} = ReadDisk(db,"SpOutput/RPPProdArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)

  # Scratch Variables
  QeArea::VariableArray{3} = zeros(Float32,length(FuelAggTOM),length(Area),length(Year)) # Energy Production by Area (TBtu/Yr)

end

function CalcProduction(db)
  data = MControl(; db)
  (;Area,AreaDS,AreaTOM,AreaTOMs,Areas,Fuel,FuelAggTOM,FuelAggTOMs) = data
  (;FuelDS,Fuels,Nation,Plant,PlantDS,Plants,Process,Processes,Year,YearDS) = data
  (;Years) = data
  (;ANMap,CAProd,EAProd,GAProd,MapAreaTOM,OAProd,MapOGProductionTOM) = data
  (; Q,Qe,QeArea,RPPAProd,RPPProdArea) = data

  CN = Select(Nation,"CN")
  US = Select(Nation,"US")
  areas_cn = findall(ANMap[:,CN] .== 1)
  areas_us = findall(ANMap[:,US] .== 1)
  areas = union(areas_cn,areas_us)

  #
  # Oil Production
  #
  fuelaggtoms = Select(FuelAggTOM,["CrudeOil","CrudeConventional","CrudeNonconventional"])
  for year in Years, area in areas, fuelaggtom in fuelaggtoms
      QeArea[fuelaggtom,area,year] = sum(OAProd[process,area,year]*
        MapOGProductionTOM[process,fuelaggtom] for process in Processes)
  end
  for year in Years, areatom in AreaTOMs, fuelaggtom in fuelaggtoms
    Qe[fuelaggtom,areatom,year] = sum(QeArea[fuelaggtom,area,year]*
       MapAreaTOM[area,areatom] for area in areas)
  end
  
  #
  # Gas Production
  #
  fuelaggtoms = Select(FuelAggTOM,"NaturalGas")
  for year in Years, areatom in AreaTOMs, fuelaggtom in fuelaggtoms
    Qe[fuelaggtom,areatom,year] = sum(GAProd[process,area,year]*
      MapOGProductionTOM[process,fuelaggtom]*
      MapAreaTOM[area,areatom] for area in areas, process in Processes)
  end
  
  #
  # Coal Production
  #
  fuelaggtom = Select(FuelAggTOM,"Coal")
  for year in Years, areatom in AreaTOMs
    Qe[fuelaggtom,areatom,year] = sum(CAProd[area,year]*
      MapAreaTOM[area,areatom] for area in areas)
  end

  #
  # Temporary Patch - Turn off ENC - coal production in 2050 gets too high in iterations
  #
  ENC = Select(AreaTOM,"ENC")
  for year in Years
    Qe[fuelaggtom,ENC,year] = Q[fuelaggtom,ENC,year]
  end
  
  #
  # RPP Production
  #
  fuelaggtom = Select(FuelAggTOM,"RPP")
  for year in Years, areatom in AreaTOMs
    # Qe[fuelaggtom,areatom,year] = sum(RPPProdArea[fuel,area,year]*
    #   MapAreaTOM[area,areatom] for area in areas, fuel in Fuels)
    Qe[fuelaggtom,areatom,year] = sum(RPPAProd[area,year]*
      MapAreaTOM[area,areatom] for area in areas)      
  end

  #
  # Electric Production
  #
  fuelaggtom = Select(FuelAggTOM,"Electric")
  for year in Years, areatom in AreaTOMs
    Qe[fuelaggtom,areatom,year] = sum(EAProd[plant,area,year]*
      MapAreaTOM[area,areatom] for area in areas, plant in Plants)
  end

  #
  # Convert from GWh to TBtu
  #
  for year in Years, areatom in AreaTOMs
    Qe[fuelaggtom,areatom,year] = Qe[fuelaggtom,areatom,year]*3412/1000000
  end
  
  #
  # Constrain Qe to be positive
  #
  for year in Years, areatom in AreaTOMs, fuelaggtom in FuelAggTOMs
    Qe[fuelaggtom,areatom,year] = max(Qe[fuelaggtom,areatom,year],0)
  end

  WriteDisk(db,"KOutput/Qe",Qe)

end

function Control(db)
  @info "E2020ProductionByArea.jl - Control"
  CalcProduction(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
