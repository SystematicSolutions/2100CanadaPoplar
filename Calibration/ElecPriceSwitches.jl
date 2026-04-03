#
# ElecPriceSwitches.jl for electric price calibration
#
using EnergyModel

module ElecPriceSwitches

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
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GRefSwitch::VariableArray{1} = ReadDisk(db,"EInput/GRefSwitch") # [Year] Gratis Permits Refunded in Retail Prices Switch (1=Yes)
  NPSwitch::VariableArray{1} = ReadDisk(db,"EInput/NPSwitch") # [Year] Non-Power Costs Explicitly in Retail Price Switch (1=Yes)
  NPTime::Float32 = ReadDisk(db,"EInput/NPTime")[1] # [tv] Non-Power Costs Endogenous Time (Year)
  RECSwitch::VariableArray{1} = ReadDisk(db,"EInput/RECSwitch") # [Year] Renewable Energy Credit (REC) in Retail Price Switch (1=Yes)
  SICstFr::VariableArray{3} = ReadDisk(db,"EInput/SICstFr") # [Area,GenCo,Year] Stranded Investment Cost Allocation Fraction ($/$)
end

function ECalibration(db)
  data = EControl(; db)
  (;Area,Areas,GenCo,GenCos,Years) = data
  (;GRefSwitch,NPSwitch,NPTime,RECSwitch,SICstFr) = data

  @. GRefSwitch[Years] = 0
  @. NPSwitch[Years] = 0
  NPTime = 2010
  @. RECSwitch[Years] = 0
  
  # 
  # Stranded Investment Costs in Retail Prices
  # 
  @. SICstFr[Areas,GenCos,Years] = 0
  for genco in GenCos
    area = Select(Area, GenCo[genco])
    @. SICstFr[area,genco,Future:Final] = 1

  end

  WriteDisk(db,"EInput/GRefSwitch", GRefSwitch)
  WriteDisk(db,"EInput/NPSwitch", NPSwitch)
  WriteDisk(db,"EInput/NPTime", NPTime)
  WriteDisk(db,"EInput/RECSwitch", RECSwitch)
  WriteDisk(db,"EInput/SICstFr", SICstFr)
end

function CalibrationControl(db)
  @info "ElecPriceSwitches.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
