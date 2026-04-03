#
# AdjustCAC_OffRoad_NU_TOM.jl
#
using EnergyModel

module AdjustCAC_OffRoad_NU_TOM

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MacroSwitch::Vector{String} = ReadDisk(db,"MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
  POCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)

  # Scratch Variables
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,FuelEP) = data
  (;FuelEPDS,FuelEPs,Nation,NationDS,Nations,Poll,PollDS,Polls,Year,YearDS) = data
  (;Years) = data
  (;MacroSwitch,POCX) = data

  #
  # Other Manufacturing, Nunavut has new industry in 2022.
  # OffRoad CAC coefficients are calculated based on historical data.
  # Need to overwrite POCX for OffRoad in Nunavut. 12/05/2023 R.Levesque
  #
  # Set NU equal to Yukon Territory coefficients
  #
  CN = Select(Nation,"CN")
  if MacroSwitch[CN] == "TOM"
    years=collect(Future:Final)
    NU=Select(Area,"NU")
    YT=Select(Area,"YT")
    enduse=Select(Enduse,"OffRoad")
    polls=Select(Poll,["NOX","SOX","COX","PM25","PM10","PMT","VOC","BC"])
    ec=Select(EC,"OtherManufacturing")
    for year in years, poll in polls, fuelep in FuelEPs
      POCX[enduse,fuelep,ec,poll,NU,year]=POCX[enduse,fuelep,ec,poll,YT,year]
    end
    WriteDisk(db,"$Input/POCX",POCX)
  end
end

function CalibrationControl(db)
  @info "AdjustCAC_OffRoad_NU_TOM.jl - CalibrationControl"

  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
