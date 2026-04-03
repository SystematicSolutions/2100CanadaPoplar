#
# GHG_FixNLGas.jl -
#
using EnergyModel

module AdjustGHG_FixNLGas

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ICalib
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Marginal Pollution Coefficients (Tonnes/TBtu)

  # Scratch Variables
end

function ICalibration(db)
  data = ICalib(; db)
  (; Area,EC,Enduses,FuelEP) = data
  (; Poll,Years) = data
  (; POCX, Input ) = data
  
  # *
  # * Use NaturalGas POCX to fix issue with NL GHG forecast
  # *
  ecs = Select(EC, ["SweetGasProcessing","ConventionalGasProduction",
  "SourGasProcessing","UnconventionalGasProduction"])
  polls = Select(Poll, ["CO2","CH4","N2O","HFC","PFC","SF6"])
  NL = Select(Area, "NL")
  NaturalGasRaw = Select(FuelEP, "NaturalGasRaw")
  NaturalGas = Select(FuelEP, "NaturalGas")
  @. POCX[Enduses,NaturalGasRaw,ecs,polls,NL,Years] = POCX[Enduses,NaturalGas,ecs,polls,NL,Years]
  
  WriteDisk(db, "$Input/POCX", POCX)
  # Select EC(SweetGasProcessing,ConventionalGasProduction,SourGasProcessing,UnconventionalGasProduction)
  # Select Poll(CO2,CH4,N2O,HFC,PFC,SF6)
  # Select Area(NL), FuelEP(NaturalGasRaw)
  # *
  # POCX(EU,F,EC,P,A,Y)=POCX(EU,NaturalGas,EC,P,A,Y)
  # *
  # Select Area*, EC*,Poll*,FuelEP*
  # *
  # Write Disk(POCX)

end

function CalibrationControl(db)
  @info "AdjustGHG_FixNLGas.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
