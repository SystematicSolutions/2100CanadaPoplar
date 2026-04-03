#
# CheckTOMDrivers.txt - Check if GY is missing
#

using EnergyModel

module CheckTOMDrivers

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  NationTOM::SetArray = ReadDisk(db,"KInput/NationTOMKey")
  NationTOMs::Vector{Int} = collect(Select(NationTOM))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GY::VariableArray{3} = ReadDisk(db,"KOutput/GY")    # [ECCTOM,AreaTOM,Year] Gross Output (2017 $M/Yr)

  #
  # Scratch Variables
  #
  # TotalGrossOutput   'Gross Output Totaled Across All Dimensions'
end

function TOMErrorCheck(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOM,AreaTOMs,ECCTOM,ECCTOMs,Years) = data
  (; ANMap,GY) = data

  parent_dir = dirname(pwd())
  file_path = joinpath(parent_dir,"2020Model","ErrorCheckTOMDrivers.log")
  io = open(file_path,"w")
  
  TotalGrossOutput = sum(GY[ecctom,areatom,year] for year in Years, areatom in AreaTOMs, ecctom in ECCTOMs)

  if TotalGrossOutput == 0
    println(io,"ERROR")
  elseif TotalGrossOutput > 0
    println(io,"SUCCESSFUL")
  end

  close(io)   
end

function Control(db)
  @info "CheckTOMDrivers.jl - Control"
  TOMErrorCheck(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
