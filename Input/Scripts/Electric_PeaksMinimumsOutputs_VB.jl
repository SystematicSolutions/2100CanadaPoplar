#
# Electric_PeaksMinimumsOutputs_VB.jl - Assign vPkLoad, vMinLd, vMonOut for US and MX
#
using EnergyModel

module Electric_PeaksMinimumsOutputs_VB

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  vMinLd::VariableArray{3} = ReadDisk(db,"VBInput/vMinLd") # [Month,Area,Year] Historical Monthly Minimum Load (MW/Month)
  vMonOut::VariableArray{3} = ReadDisk(db,"VBInput/vMonOut") # [Month,Area,Year] Historical Monthly Output (GWh/Month)
  vPkLoad::VariableArray{3} = ReadDisk(db,"VBInput/vPkLoad") # [Month,Area,Year] Historical Monthly Peak Load (MW/Month)
  xMinLd::VariableArray{3} = ReadDisk(db,"SInput/xMinLd") # [Month,Area,Year] Historical Monthly Minimum Load (MW/Month)
  xMonOut::VariableArray{3} = ReadDisk(db,"SInput/xMonOut") # [Month,Area,Year] Historical Monthly Output (GWh/Month)
  xPkLoad::VariableArray{3} = ReadDisk(db,"SInput/xPkLoad") # [Month,Area,Year] Historical Monthly Peak Load (MW/Month)
end

function ECalibration(db)
  data = EControl(; db)
  (;vMinLd,vMonOut,vPkLoad,xMinLd,xMonOut,xPkLoad) = data

  # 
  # Note: v-variables only have values for US and MX. Canada still read in through .txt files. 
  # As of 09/21/24 R.Levesque
  # 
  xMinLd .= vMinLd
  xMonOut .= vMonOut
  xPkLoad .= vPkLoad

  WriteDisk(db,"SInput/xMinLd",xMinLd)
  WriteDisk(db,"SInput/xMonOut",xMonOut)
  WriteDisk(db,"SInput/xPkLoad",xPkLoad)
    
end

function CalibrationControl(db)
  @info "Electric_PeaksMinimumsOutputs_VB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
