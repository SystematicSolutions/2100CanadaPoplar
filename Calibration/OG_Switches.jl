#
# OG_Switches.jl - Set the OG Switches for the Policy Cases
#
using EnergyModel

module OG_Switches

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CCMDemSw::VariableArray{2} = ReadDisk(db,"SpInput/CCMDemSw") # [OGUnit,Year] Switch to Activate the Capital Cost Multiplier (1 = On)
  DevMaxM::VariableArray{2} = ReadDisk(db,"SpInput/DevMaxM") # [OGUnit,Year] Development Rate Maximum Multiplier from ROI (Btu/Btu)
  DevMinM::VariableArray{2} = ReadDisk(db,"SpInput/DevMinM") # [OGUnit,Year] Development Rate Minimum Multiplier from ROI (Btu/Btu)
  DevVar::VariableArray{2} = ReadDisk(db,"SpInput/DevVar") # [OGUnit,Year] Development Rate Variance (Btu/Btu)
  DevVF::VariableArray{2} = ReadDisk(db,"SpInput/DevVF") # [OGUnit,Year] Development Rate Variance Factor for ROI (Btu/Btu)
  DevSw::VariableArray{2} = ReadDisk(db,"SpInput/DevSw") # [OGUnit,Year] Development Switch
  OGPrSw::VariableArray{2} = ReadDisk(db,"SpInput/OGPrSw") # [OGUnit,Year] OG Price Switch (1=from ENPN, 2=Bitumen)
  PdMax::VariableArray{2} = ReadDisk(db,"SpInput/PdMax") # [OGUnit,Year] Maximum Production Rate (TBtu/TBtu)
  PdMaxM::VariableArray{2} = ReadDisk(db,"SpInput/PdMaxM") # [OGUnit,Year] Production Rate Maximum Multiplier from ROI (Btu/Btu)
  PdMinM::VariableArray{2} = ReadDisk(db,"SpInput/PdMinM") # [OGUnit,Year] Production Rate Minimum Multiplier from ROI (Btu/Btu)
  PdVar::VariableArray{2} = ReadDisk(db,"SpInput/PdVar") # [OGUnit,Year] Production Rate Variance (Btu/Btu)
  PdVF::VariableArray{2} = ReadDisk(db,"SpInput/PdVF") # [OGUnit,Year] Production Rate Variance Factor for ROI (Btu/Btu)
  PdSw::VariableArray{2} = ReadDisk(db,"SpInput/PdSw") # [OGUnit,Year] Production Switch
end

function SCalibration(db)
  data = SControl(; db)
  (;CCMDemSw,DevMaxM,DevMinM,DevVar,DevVF,DevSw,OGPrSw,PdMax,PdMaxM,PdMinM,PdVar,PdVF,PdSw) = data

  CCMDemSw  .=    1.0
  DevMaxM   .=    2.00
  DevMinM   .=    0.00
  DevVar    .=    1.00
  DevVF     .=  -10.00
  DevSw     .=    0
  OGPrSw    .=    1
  PdMax     .=    1e12
  PdMaxM    .=    1.00
  PdMinM    .=    0.00
  PdVar     .=    1.00
  PdVF      .=  -10.00
  PdSw      .=    0

  WriteDisk(db,"SpInput/CCMDemSw",CCMDemSw)
  WriteDisk(db,"SpInput/DevMaxM",DevMaxM)
  WriteDisk(db,"SpInput/DevMinM",DevMinM)
  WriteDisk(db,"SpInput/DevVar",DevVar)
  WriteDisk(db,"SpInput/DevVF",DevVF)
  WriteDisk(db,"SpInput/DevSw",DevSw)
  WriteDisk(db,"SpInput/OGPrSw",OGPrSw)
  WriteDisk(db,"SpInput/PdMax",PdMax)
  WriteDisk(db,"SpInput/PdMaxM",PdMaxM)
  WriteDisk(db,"SpInput/PdMinM",PdMinM)
  WriteDisk(db,"SpInput/PdVar",PdVar)
  WriteDisk(db,"SpInput/PdVF",PdVF)
  WriteDisk(db,"SpInput/PdSw",PdSw)
  
end

function CalibrationControl(db)
  @info "OG_Switches.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
