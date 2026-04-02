#
# Electric_BC_Offsets.jl -   Activates OffRq for BC Generation
#

using EnergyModel

module Electric_BC_Offsets

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  OffSw::VariableArray{2} = ReadDisk(db,"EGInput/OffSw") # [Area,Year] GHG Electric Utility Offsets Required Switch (1=Required)

  # Scratch Variables
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area) = data
  (; OffSw) = data

  BC = Select(Area,"BC")
  years = collect(Future:Final)
  for year in years
    OffSw[BC,year] = 1
  end
  
  WriteDisk(db,"EGInput/OffSw",OffSw)
end

function PolicyControl(db)
  @info "Electric_BC_Offsets.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
