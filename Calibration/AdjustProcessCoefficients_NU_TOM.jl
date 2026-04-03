#
# AdjustProcessCoefficients_NU_TOM.jl.jl
#
using EnergyModel

module AdjustProcessCoefficients_NU_TOM

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FlPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FlPOCX") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions Coefficient (Tonnes/Driver)
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  MacroSwitch::Vector{String} = ReadDisk(db,"MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-Output)
  VnPOCX::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCX") # [ECC,Poll,Area,Year] Fugitive Venting Emissions Coefficient (Tonnes/Driver)

  # Scratch Variables
end

function MCalibration(db)
  data = MControl(; db)
  (;Area,AreaDS,Areas,ECC,ECCDS,ECCs,Nation,Poll,PollDS,Polls,Year) = data
  (;YearDS,Years) = data
  (;FlPOCX,FuPOCX,MacroSwitch,MEPOCX,VnPOCX) = data

  #
  # Other Manufactring in Nunavut has a lot of zeros historically in TOM then starts up in 2023
  # (after the calibration period).  The process emission coefficients are
  # set equal to the Yukon Terriotry values.  R.Levesque 11/30/23
  #
  # Use YT Process Emissions for NU Other Manufacturing
  #
  CN = Select(Nation,"CN")
  if MacroSwitch[CN] == "TOM"
    NU=Select(Area,"NU")
    YT=Select(Area,"YT")
    ecc=Select(ECC,"OtherManufacturing")
    for year in Years, poll in Polls
      FlPOCX[ecc,poll,NU,year]=FlPOCX[ecc,poll,YT,year]
      FuPOCX[ecc,poll,NU,year]=FuPOCX[ecc,poll,YT,year]
      MEPOCX[ecc,poll,NU,year]=MEPOCX[ecc,poll,YT,year]
      VnPOCX[ecc,poll,NU,year]=VnPOCX[ecc,poll,YT,year]
    end
    
    WriteDisk(db,"MEInput/FlPOCX",FlPOCX)
    WriteDisk(db,"MEInput/FuPOCX",FuPOCX)
    WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
    WriteDisk(db,"MEInput/VnPOCX",VnPOCX)
  end

end

function CalibrationControl(db)
  @info "AdjustProcessCoefficients_NU_TOM.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
