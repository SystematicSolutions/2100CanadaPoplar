#
# MEconomyTOM.jl
#

module MEconomyTOM

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,MaxTime,HisTime,DT
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  current::Int
  prior::Int
  next::Int
  CTime::Int

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  CNArea::SetArray = ReadDisk(db,"MainDB/CNAreaKey")
  CNAreas::Vector{Int} = collect(Select(CNArea))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodes::Vector{Int} = collect(Select(GNode))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CPIndex::VariableArray{1} = ReadDisk(db,"MInput/CPIndex",year) #[Area,Year]  Consumer Price Index (1992=100)
  CPIndexNation::VariableArray{1} = ReadDisk(db,"MInput/CPIndexNation",year) #[Nation,Year]  Consumer Price Index By Area (1992=100)
  Driver::VariableArray{2} = ReadDisk(db,"MOutput/Driver",year) #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  GDPSector::VariableArray{2} = ReadDisk(db,"MInput/GDPSector",year) #[ECC,Area,Year]  GDP By Sector (1997 Million CN$/Yr)
  GDPSectorTOM::VariableArray{2} = ReadDisk(db,"MInput/GDPSectorTOM",year) # [ECC,Area,Year] GDP By Sector (Real Million $/Yr)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
  xCPITOM::VariableArray{1} = ReadDisk(db,"MInput/xCPITOM",year) # [Nation,Year] Consumer Price Index from TOM by Area (2002=100)  
  xCPINationTOM::VariableArray{1} = ReadDisk(db,"MInput/xCPINationTOM",year) # [Nation,Year] Consumer Price Index from TOM by Nation (2002=100)  
  xGO::VariableArray{2} = ReadDisk(db,"MInput/xGO",year) #[ECC,Area,Year]  Gross Output (Real M$/Yr)
  xGOTOM::VariableArray{2} = ReadDisk(db,"MInput/xGOTOM",year) #[ECC,Area,Year]  Gross Output (Real M$/Yr)
  xHHS::VariableArray{2} = ReadDisk(db,"MInput/xHHS",year) #[ECC,Area,Year]  Households (Households)
  xHHSAEO::VariableArray{2} = ReadDisk(db,"MInput/xHHSAEO",year) #[ECC,Area,Year]  Households from AEO (Households)
  xHHSTOM::VariableArray{2} = ReadDisk(db,"MInput/xHHSTOM",year) #[ECC,Area,Year]  Households from TOM (Households)
  xHSize::VariableArray{2} = ReadDisk(db,"MInput/xHSize",year) #[ECC,Area,Year]  Household Size (People/Household)
  xPop::VariableArray{2} = ReadDisk(db,"MInput/xPop",year) #[ECC,Area,Year]  Population (Millions)
  xPopAEO::VariableArray{2} = ReadDisk(db,"MInput/xPopAEO",year) #[ECC,Area,Year]  Population by Household Type from AEO (Millions)
  xPopTOM::VariableArray{2} = ReadDisk(db,"MInput/xPopTOM",year) #[ECC,Area,Year]  Population by Household Type from TOM (Millions)
  xPopT::VariableArray{1} = ReadDisk(db,"MInput/xPopT",year) #[Area,Year]  Population (Millions)
  xPopTAEO::VariableArray{1} = ReadDisk(db,"MInput/xPopTAEO",year) #[Area,Year]  Population (Millions)
  xTHHS::VariableArray{1} = ReadDisk(db,"MInput/xTHHS",year) #[Area,Year]  Total Households (Households)

end

function TOMUSProcessing(data::Data)
  (; db,year) = data
  (; Nation,ECC,ECCs) = data #sets
  (; ANMap,CPIndex,CPIndexNation,Driver,GDPSector,GDPSectorTOM,SecMap) = data
  (; xCPITOM,xCPINationTOM,xGO,xGOTOM,xHHS,xHHSAEO,xHHSTOM,xHSize) = data
  (; xPop,xPopAEO,xPopT,xPopTAEO,xPopTOM,xTHHS) = data

  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  Res = 1
  
  eccs = findall(SecMap .== Res)
  for area in areas, ecc in eccs
    xHHS[ecc,area] = xHHSAEO[ecc,area]
    xHHSTOM[ecc,area] = xHHS[ecc,area]
  end
  
  eccs = findall(SecMap .== Res)   
  for area in areas   
    xTHHS[area] = sum(xHHS[ecc,area] for ecc in eccs)
  end
  
  for area in areas, ecc in ECCs     
    xGO[ecc,area] = xGOTOM[ecc,area]
  end
  
  for area in areas, ecc in ECCs     
    GDPSector[ecc,area] = max(GDPSectorTOM[ecc,area],0.00001)
  end
  
  eccs = Select(ECC,["H2Production","BiofuelProduction","SolidWaste",
                     "Wastewater","Incineration","LandUse","RoadDust",
                     "OpenSources","ForestFires","Biogenics"])
  for area in areas, ecc in eccs    
    GDPSector[ecc,area] = Driver[ecc,area]
  end
  
  for area in areas
    CPIndex[area] = xCPITOM[area]
  end
  
  CPIndexNation[US] = xCPINationTOM[US]
  
  eccs = findall(SecMap .== Res)
  for area in areas, ecc in eccs  
    @finite_math xPop[ecc,area] = xPopT[area]*(xPopAEO[ecc,area]/xPopTAEO[area])
    xPopTOM[ecc,area] = xPop[ecc,area]
  end
  
  eccs = findall(SecMap .== Res)
  for area in areas, ecc in eccs  
    @finite_math xHSize[ecc,area] = xPop[ecc,area]/xHHS[ecc,area]
  end
   
  WriteDisk(db,"MInput/CPIndex",year,CPIndex)
  WriteDisk(db,"MInput/CPIndexNation",year,CPIndexNation) 
  WriteDisk(db,"MInput/GDPSector",year,GDPSector)   
  WriteDisk(db,"MInput/xGO",year,xGO)
  WriteDisk(db,"MInput/xHSize",year,xHSize)
  WriteDisk(db,"MInput/xHHS",year,xHHS)
  WriteDisk(db,"MInput/xHHSTOM",year,xHHS)
  WriteDisk(db,"MInput/xPop",year,xPop)
  WriteDisk(db,"MInput/xPopTOM",year,xPopTOM)
  WriteDisk(db,"MInput/xTHHS",year,xTHHS)

end

function TOMCNProcessing(data::Data)
  (; db,year) = data
  (; ECC,ECCs,Nation) = data #sets
  (; ANMap,CPIndex,CPIndexNation,Driver,GDPSector,GDPSectorTOM,SecMap) = data
  (; xCPITOM,xCPINationTOM,xHHS,xPop,xPopT,xPopTOM,xTHHS) = data

  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  Res = 1
    
  #
  # Split Total Population (xPopT) By Housing Type
  #
  eccs = findall(SecMap .== Res)
  for area in areas, ecc in eccs    
    @finite_math xPop[ecc,area] = xPopT[area]*(xHHS[ecc,area]/xTHHS[area])
    xPopTOM[ecc,area] = xPop[ecc,area]
  end
  
  for area in areas, ecc in ECCs     
    GDPSector[ecc,area] = max(GDPSectorTOM[ecc,area],0.00001)
  end
  
  eccs = Select(ECC,["H2Production","BiofuelProduction","SolidWaste",
                     "Wastewater","Incineration","LandUse","RoadDust",
                     "OpenSources","ForestFires","Biogenics"])
  for area in areas, ecc in eccs    
    GDPSector[ecc,area] = Driver[ecc,area]
  end
  
  for area in areas
    CPIndex[area] = xCPITOM[area]
  end
  
  CPIndexNation[CN] = xCPINationTOM[CN]

  WriteDisk(db,"MInput/CPIndex",year,CPIndex)
  WriteDisk(db,"MInput/CPIndexNation",year,CPIndexNation) 
  WriteDisk(db,"MInput/GDPSector",year,GDPSector)   
  WriteDisk(db,"MInput/xPop",year,xPop)
  WriteDisk(db,"MInput/xPopTOM",year,xPopTOM)

end

function Control(data::Data)

  TOMUSProcessing(data)
  TOMCNProcessing(data)
    
end # function Control

end # module MEconomy
