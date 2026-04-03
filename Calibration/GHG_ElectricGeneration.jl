#
# GHG_ElectricGeneration.jl - this file calculates the GHG process
# coefficients for the electric generation sector (MEPOCX, UnMECX)
# - Jeff Amlin 10/27/10
#
using EnergyModel

module GHG_ElectricGeneration

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  GenCo::SetArray = ReadDisk(db, "MainDB/GenCoKey")
  
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db, "MainDB/NodeKey")
  
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EGPA::VariableArray{3} = ReadDisk(db,"EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"EGInput/MEPOCX") # [Plant,Poll,Area,Year] Process Emission Coefficients (Tonnes/GWh)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnMECX::VariableArray{3} = ReadDisk(db,"EGInput/UnMECX") # [Unit,Poll,Year] Process Pollution Coefficient (Tonnes/GWh)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)

  # Scratch Variables
  EGTot::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Generation which is subject to Process Emissions (GWh)
end

function GetUnitSets(data::EControl, unit)
  (; Area,GenCo,Node,Plant,Unit) = data;
  (; UnArea,UnGenCo,UnNode,UnPlant,Unit) = data;
  #
  # This procedure selects the sets for a particular unit
  #
  gencoindex = Select(GenCo, UnGenCo[unit])
  plantindex = Select(Plant, UnPlant[unit])
  nodeindex = Select(Node, UnNode[unit])
  areaindex = Select(Area, UnArea[unit])

  return gencoindex, plantindex, nodeindex, areaindex

end


function MECXCalc(data::EControl)
  (; db) = data
  (;ECC,Nation,Plant) = data
  (;Plants,Poll,Units,Years) = data
  (;ANMap,EGPA,MEPOCX,UnMECX,UnNation,xMEPol) = data
  (;EGTot) = data
  
  #
  # Select Canada areas
  #  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1) 
  
  #
  # Select Electric Utility Generation sector
  #
  UtilityGen = Select(ECC,"UtilityGen")
  
  #
  # Select GHG Pollutants and Years for actual data
  #
  years = collect(Yr(1990):Yr(2008))
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  
  #
  # Total generation subject to process emissions
  #
  plants = Select(Plant,["OGCT","OGCC","OGSteam","Coal","CoalCCS","Nuclear","Biogas","Biomass"])
  for area in areas, year in years
    EGTot[area,year] = sum(EGPA[plant,area,year] for plant in plants)
  end
  
  #
  # Process Coefficients by plant type
  #
  for plant in plants, poll in polls, area in areas, year in years
    @finite_math MEPOCX[plant,poll,area,year] = xMEPol[UtilityGen,poll,area,year]/EGTot[area,year]
  end
  
  # 
  #  Forecast and Historical Values of Coefficients
  #
  years = collect(Yr(2009):Final)
  for year in years, plant in Plants, poll in polls, area in areas
    MEPOCX[plant,poll,area,year]=MEPOCX[plant,poll,area,Yr(2008)]
  end
  
  years = collect(Yr(1985):Yr(1989))
  for year in years, plant in Plants, poll in polls, area in areas
    MEPOCX[plant,poll,area,year]=MEPOCX[plant,poll,area,Yr(1990)]
  end

  # 
  #  SF6 in Electric Utilities are reduced through 2015, then held
  #  constant via a slow decline to offset generation growth.
  # 

  SF6 = Select(Poll,"SF6")
  years = collect(Yr(2009):Yr(2015))
  for plant in Plants, area in areas, year in years
    MEPOCX[plant,SF6,area,year] = MEPOCX[plant,SF6,area,year-1]*(1-0.091)
  end
  years = collect(Yr(2016):Final)
  for plant in Plants, area in areas, year in years
    MEPOCX[plant,SF6,area,year] = MEPOCX[plant,SF6,area,year-1]*(1-0.022)
  end
  
  # 
  #  Assign Process Coefficients to Units.
  # 
  for unit in Units
    if UnNation[unit] == "CN"
      UnitData = GetUnitSets(data,unit)
      @. UnMECX[unit,polls,Years] = MEPOCX[UnitData[2],polls,UnitData[4],Years]
    end
  end
  
  # 
  #  Forecast and Historical Values of Coefficients
  # 
  years = collect(Yr(2009):Final)
  for year in years
    @. UnMECX[Units,polls,year] = UnMECX[Units,polls,Yr(2008)]
  end
  years = collect(Yr(1985):Yr(1989))
  for year in years
    @. UnMECX[Units,polls,year] = UnMECX[Units,polls,Yr(1990)]
  end
  
  WriteDisk(db,"EGInput/MEPOCX",MEPOCX)
  WriteDisk(db,"EGInput/UnMECX",UnMECX)

end

function ElecCalibration(db)
  data = EControl(; db)
  
  MECXCalc(data)

end

function CalibrationControl(db)
  @info "GHG_ElectricGeneration.jl - CalibrationControl"

  ElecCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
