#
# ErrorCheckTOM.txt - Check if GY is missing
#

using EnergyModel

module ErrorCheckTOM

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
  TotalGrossOutput::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Gross Output (2017 $M/Yr)
  # Done
  # TOMEndYear
  # EndYearIndex
  # TotalGrossOutput   'Gross Output Totaled Across All Dimensions'
  # YrFound
  # YrPointer    'Pointer to Year value'
end

function CheckGrossOutput(db)
  data = MControl(; db)
  (; Area,Areas,AreaTOM,AreaTOMs,ECCTOM,ECCTOMs,Years) = data
  (; ANMap,GY,TotalGrossOutput) = data

  #
  # Read TOMEndYear from TOMEndYear.log
  #
  YearString = ""
  TOMEndYear = 0
  parent_dir = dirname(pwd())
  file_path = joinpath(parent_dir,"2020Model","TOMEndYear.log")
  file = open(file_path, "r")
  YearString = readline(file)
  close(file)
  TOMEndYear = parse(Int,YearString)
  @info "TOMEndYear = $TOMEndYear"
  
  #
  # Create log file to indicate if GY is zero or has *****'s
  #
  file_path = joinpath(parent_dir,"2020Model","ErrorCheckTOMDrivers.log")
  io = open(file_path,"w")

  #
  # Assign year index to TOMEndYear
  #
  EndYearIndex = TOMEndYear-ITime+1
  years = collect(Future:EndYearIndex)
  
  #
  # Check one area's gross output
  #
  ON = Select(AreaTOM,"ON")
  for year in years
    TotalGrossOutput[year] = sum(GY[ecctom,ON,year] for ecctom in ECCTOMs)
  end

  Done = 0
  if sum(TotalGrossOutput[year] for year in years) == 0
    println(io, "ERROR")
    println(io,"Gross Output = 0")
    Done = 1
  end
  
  Done = 0
  for year in years
    if TotalGrossOutput[year] > 1E24
      println(io, "ERROR")
      println(io,"Gross Output = *******")
      Done = 1
    elseif TotalGrossOutput[year] == 0
      println(io,"ERROR")
      println(io,"Gross Output = 0")
      Done = 1
    end
  end

  if Done == 1
    YrPointer = Future
    YrFound = 0
    while YrFound == 0
      if TotalGrossOutput[YrPointer] > 1E21
        YrFound = YrPointer+1985-1
        println(io,"Year = $YrFound")
      elseif TotalGrossOutput[YrPointer] == 0
        YrFound = YrPointer+1985-1
        println(io,"Year = $YrFound")
      end
      YrPointer = YrPointer+1
    end
  end
  
  if Done == 0
    println(io, "SUCCESSFUL")
    Done = 1
  end

  close(io)
end

function Control(db)
  @info "ErrorCheckTOM.jl - Control"
  CheckGrossOutput(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end
end
