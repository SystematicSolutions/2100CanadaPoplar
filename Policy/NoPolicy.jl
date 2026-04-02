#
#  NoPolicy.jl
#

using EnergyModel

module NoPolicy

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

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

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (YEARS)
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  xUnGCCI::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCI") # [Unit,Year] Generating Capacity Initiated (MW) 
  xUnGCCR::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCR") # [Unit,Year] Exogenous Generating Capacity Completion Rate (MW) 

  # Scratch Variables
  # LocAdds     'Local Variable for Capacity Additions (MW)'
  # LocYear     'Local Variable for Year of Addition (Year)'
  # UCode    'Scratch Variable for UnCode', Type = String(20)
end

function ElecPolicy(db)
  data = EControl(; db)
  (; ) = data
end

function PolicyControl(db)
  @info "NoPolicy.jl - PolicyControl"
  ElecPolicy(db)
end

#
# Place call in another file
#

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
