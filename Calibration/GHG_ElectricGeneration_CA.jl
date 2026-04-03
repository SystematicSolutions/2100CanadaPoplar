#
# GHG_ElectricGeneration_CA.jl - Updated CA data from California Energy Commission
# 1/18/16
#
using EnergyModel

module GHG_ElectricGeneration_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
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

  EGPA::VariableArray{3} = ReadDisk(db,"EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"EGInput/MEPOCX") # [Plant,Poll,Area,Year] Process Emission Coefficients (Tonnes/GWh)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnMECX::VariableArray{3} = ReadDisk(db,"EGInput/UnMECX") # [Unit,Poll,Year] Process Pollution Coefficient (Tonnes/GWh)
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Actual Process Pollution (Tonnes/Yr)

  # Scratch Variables
  CAPoll::VariableArray{2} = zeros(Float32,length(Poll),length(Year)) # [Poll,Year] California Transportation Pollution
  EGTot::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Generation which is subject to Process Emissions (GWh)
end

function GetUnitSets(data::ECalib, unit)
  (; Area,Plant, Unit) = data;
  (; UnArea,UnPlant,Unit) = data;
  #
  # This procedure selects the sets for a particular unit
  #
  #gencoindex = Select(GenCo, UnGenCo[unit])
  plantindex = Select(Plant, UnPlant[unit])
  #nodeindex = Select(Node, UnNode[unit])
  areaindex = Select(Area, UnArea[unit])

  return plantindex, areaindex

end


function ECalibration(db)
  data = ECalib(; db)
  (;Area,ECC,Plant,Plants,Poll) = data
  (;Years) = data
  (;EGPA,MEPOCX,PolConv,UnArea,UnMECX,xMEPol) = data
  (;CAPoll,EGTot) = data
  
  
  #
  # Read current emission coefficients
  #
  
  #
  # Select California areas
  #
  CA = Select(Area, "CA")
  #
  # Select Electric Utility Generation sector
  #
  UtilityGen = Select(ECC, "UtilityGen")
  #
  # Select GHG Pollutants and Years for actual data
  #
  years = collect(Yr(2000):Yr(2013))
  polls = Select(Poll, ["CO2","SF6"])
  #
  # Process Emissions from California GHG Inventory.
  # Sources: "California Emissions - Industrial Demand & Process Estimation v160122.xlsx"
  # Sources: "California GHG Inventory 2013 - Coded v160122.xlsx"
  # Luke Davulis, January 22, 2016
  #
  # Select ECC(UtilityGen), Poll(CO2,SF6), Year(2000-2013)
  # Read CAPoll\27(Poll,Year)
  CAPoll[polls,years] = [
  # /EC                Poll      2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  # UtilityGen         CO2     
  0.1121   0.1101   0.1111   0.1084   0.1089   0.1116   0.1128   0.1100   0.1025   0.0977   0.0556   0.0543   0.0179   0.0051 
  # UtilityGen         SF6     
  0.2410   0.2263   0.1948   0.1945   0.1924   0.1944   0.1959   0.1743   0.1737   0.1733   0.1650   0.1616   0.1555   0.1233 
  ]
  @. xMEPol[UtilityGen,polls,CA,years] = CAPoll[polls,years]
  for poll in polls
    @. xMEPol[UtilityGen,poll,CA,years] = xMEPol[UtilityGen,poll,CA,years]*1000000/PolConv[poll]
  end
  
  #
  # Total generation subject to process emissions
  #
  plants = Select(Plant, ["OGCT","OGCC","OGSteam","Coal","CoalCCS","Nuclear","Biogas","Biomass"])
  for year in years
    EGTot[CA, year] = sum(EGPA[plant,CA,year] for plant in plants)
  end
    
  #
  # Process Coefficients by plant type
  #
  for poll in polls, year in years, plant in plants
    @finite_math MEPOCX[plant,poll,CA,year] = xMEPol[UtilityGen,poll,CA,year] / EGTot[CA, year]
  end
  
  
  # Select Plant*
  #
  # Forecast and Historical Values of Coefficients
  #
  years = collect(Yr(2014):Final)
  for year in years
    @. MEPOCX[Plants,polls,CA,year] = MEPOCX[Plants,polls,CA,Yr(2013)]
  end
  
  years = collect(Yr(1985):Yr(1999))
  for year in years
    @. MEPOCX[Plants,polls,CA,year] = MEPOCX[Plants,polls,CA,Yr(2000)]
  end
  
  
  #
  # Assign Process Coefficients to Units.
  #
  
  unareas = findall(x -> x == "CA", UnArea)
  for unit in unareas
    plantindex, areaindex = GetUnitSets(data, unit)
    if areaindex == CA
      @. UnMECX[unit,polls,Years] = MEPOCX[plantindex,polls,CA,Years]
    end
  end
  
  
  WriteDisk(db,"EGInput/MEPOCX",MEPOCX)
  WriteDisk(db,"EGInput/UnMECX",UnMECX)

end

function CalibrationControl(db)
  @info "GHG_ElectricGeneration_CA.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
