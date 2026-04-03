#
# Hours.jl
#
using EnergyModel

module Hours

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

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))

  HDHours::VariableArray{2} = ReadDisk(db,"EInput/HDHours") # [TimeP,Month] Number of Hours in the Interval (Hours)
  HDHrMn::VariableArray{2} = ReadDisk(db,"EInput/HDHrMn") # [TimeP,Month] Minimum Hour in the Interval (Hour)
  HDHrPk::VariableArray{2} = ReadDisk(db,"EInput/HDHrPk") # [TimeP,Month] Peak Hour in the Interval (Hour)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)


  # Scratch Variables
  HDHrFr::VariableArray{1} = zeros(Float32,length(TimeP)) # [TimeP] Mimunim Hour in each Time Period as a Fraction of the Number of Hours in a Month
end

function ECalibration(db)
  data = EControl(; db)
  (;Input) = data
  (;Months,TimePs) = data
  (;HDHours,HDHrMn,HDHrPk,HoursPerMonth) = data
  (;HDHrFr) = data

  #
  # Mimunim Hour in each Time Period as a Fraction of
  # the Number of Hours in a Month (from TimeP Calculation.xls)
  #
  HDHrFr[TimePs] = [
  #/ TimeP1 TimeP2 TimeP3 TimeP4 TimeP5 TimeP6
      0.01   0.03   0.06   0.16   0.40   1.00
  ]
  
  #
  # Minimum Hour in TimePeriod
  #
  for timep in TimePs, month in Months
    HDHrMn[timep,month] = HoursPerMonth[month] * HDHrFr[timep]
  end

  #
  # Peak Hour in Time Period
  #
  timep = 1
  for month in Months
    HDHrPk[timep,month] = 1
  end
  timeps = collect(2:length(TimePs))
  for timep in timeps, month in Months 
    HDHrPk[timep,month] = HDHrMn[timep-1,month] + 1
  end

  #
  # Hours in the Interval
  #
  for timep in TimePs, month in Months
    HDHours[timep,month] = HDHrMn[timep,month] - HDHrPk[timep,month] + 1
  end

  WriteDisk(db,"$Input/HDHours",HDHours)
  WriteDisk(db,"$Input/HDHrMn",HDHrMn)
  WriteDisk(db,"$Input/HDHrPk",HDHrPk)

end

function CalibrationControl(db)
  @info "Hours.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
