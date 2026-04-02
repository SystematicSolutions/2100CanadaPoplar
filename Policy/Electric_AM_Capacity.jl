#
#  NRCan_Elec_SmallCommunities_2.jl
#

using EnergyModel

module NRCan_Elec_SmallCommunities_2

import ...EnergyModel: ReadDisk,WriteDisk,Select,Zero
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
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (YEARS)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xUnGCCI::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCI") # [Unit,Year] Generating Capacity Initiated (MW)
  xUnGCCR::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCR") # [Unit,Year] Exogenous Generating Capacity Completion Rate (MW)

  # Scratch Variables
  # CapAdd    'Local Variable for Capacity Additions (MW)'
  # LocYear   'Local Variable for Year of Addition (Year)'
  # UCode     'Scratch Variable for UnCode',Type = String(20)
end

function GetUnitSets(data,unit)
  (; Area,GenCo,Node,Plant) = data
  (; UnArea,UnGenCo,UnNode,UnPlant) = data

  plant = Select(Plant,UnPlant[unit])
  node = Select(Node,UnNode[unit])
  genco = Select(GenCo,UnGenCo[unit])
  area = Select(Area,UnArea[unit])

  return plant,node,genco,area
end

function AddCapacity(data,UCode,LocYear,CapAdd)
  (; Year) = data
  (; CD,UnCode,UnOnLine,xUnGCCI,xUnGCCR) = data

  unit = Select(UnCode,UCode)

  #
  # Select GenCo, Area, Node, and Plant Type for this Unit
  #  
  plant,node,genco,area = GetUnitSets(data,unit)

  #
  # Update Online year if needed.
  # 
  UnOnLine[unit] = min(UnOnLine[unit],LocYear)

  #
  # If the plant comes on later in the forecast, then simulate construction
  #  
  if LocYear-CD[plant,Zero] > (HisTime+1)
    Loc1 = LocYear-CD[plant,Zero]-ITime+1
    year = Int(Loc1)
    xUnGCCI[unit,year] = xUnGCCI[unit,year]+CapAdd/1000

  #
  # If the plant comes on-line in the first few years, then there is no time
  # to simulate construction, so just put it on-line.
  #  
  else
    year = Select(Year,string(LocYear))
    xUnGCCR[unit,year] = xUnGCCR[unit,year]+CapAdd/1000
  end
  
  return
end

function ElecPolicy(db)
  data = EControl(; db)
  (; UnOnLine,xUnGCCI,xUnGCCR) = data

  # 
  #                                      Online  xUnGCCI
  #                 Unit Code             Year      kw
  AddCapacity(data,"YT_New_OnshoreWind",  2025,   15000)
  AddCapacity(data,"YT_New_Hydro",        2025,    9000)
  AddCapacity(data,"NT_New_Hydro",        2025,    9000)
  AddCapacity(data,"NU_New_SolarPV",      2025,    7000)
  AddCapacity(data,"NT_New_SolarPV",      2025,    8000)
  AddCapacity(data,"YT_New_SolarPV",      2025,    8000)


  WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
  WriteDisk(db,"EGInput/xUnGCCI",xUnGCCI)
  WriteDisk(db,"EGInput/xUnGCCR",xUnGCCR)
end

function PolicyControl(db)
  @info "NRCan_Elec_SmallCommunities_2.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
