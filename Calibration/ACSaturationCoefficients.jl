#
# ACSaturationCoefficients.jl
#
using EnergyModel

module ACSaturationCoefficients

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
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
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DDSatFlag::VariableArray{2} = ReadDisk(db,"$Input/DDSatFlag") # [Enduse,Month] Flag for Degree Days in Saturation Equation (1=include)
  DStA0::VariableArray{4} = ReadDisk(db,"$Input/DStA0") # [Enduse,EC,Area,Year] Device Saturation Degree Day Coefficient (Btu/Btu/DD)
  DStB0::VariableArray{4} = ReadDisk(db,"$Input/DStB0") # [Enduse,EC,Area,Year] Device Saturation Area Adjustment (Btu/Btu)
  DStC0::VariableArray{4} = ReadDisk(db,"$Input/DStC0") # [Enduse,EC,Area,Year] Device Saturation Constant Term (Btu/Btu)
  DStMax::VariableArray{3} = ReadDisk(db,"$Input/DStMax") # [Enduse,EC,Area] Maximum Device Saturation (Btu/Btu)
  DStMin::VariableArray{3} = ReadDisk(db,"$Input/DStMin") # [Enduse,EC,Area] Minimum Device Saturation (Btu/Btu)
  DDSmoothingTime::VariableArray{3} = ReadDisk(db,"$Input/DDSmoothingTime") # [Enduse,Area,Year] Smoothing Time for Annual Degree Days (Years)
  DDayMonthly::VariableArray{4} = ReadDisk(db,"$Input/DDayMonthly") # [Enduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  DDSat::VariableArray{3} = ReadDisk(db,"$Outpt/DDSat") # [Enduse,Area,Year] Degree Days for Saturation Equation (Degree Days)
  DDSmooth::VariableArray{3} = ReadDisk(db,"$Outpt/DDSmooth") # [Enduse,Area,Year] SmoothedDegree Days (Degree Days)

  # Scratch Variables
end

function RCalibration(db)
  data = RControl(; db)
  (;Input,Outpt) = data
  (;Areas,ECs,Enduse,Enduses,Months,Years) = data
  (;DDSatFlag,DStA0,DStB0,DStC0,DStMax,DStMin,DDSmoothingTime,DDayMonthly,DDSat,DDSmooth) = data

  #
  # Air Conditioning Saturation
  #
  enduse = Select(Enduse,"AC")

  #
  # DSt=DStC0+DStB0*exp(DStA0*DDSmooth)   
  #
  
  for year in Years, area in Areas, ec in ECs
   DStA0[enduse,ec,area,year] = -0.00298
  end
  
  for year in Years, area in Areas, ec in ECs
   DStB0[enduse,ec,area,year] = -1.17
  end
  
  for year in Years, area in Areas, ec in ECs
   DStC0[enduse,ec,area,year] =  0.944 
  end
  
  for month in Months
   DDSatFlag[enduse,month] = 1
  end 

  for area in Areas, ec in ECs
   DStMax[enduse,ec,area] = 0.980
  end
  
  for area in Areas, ec in ECs
   DStMin[enduse,ec,area] = 0.022
  end 

  WriteDisk(db, "$Input/DDSatFlag",DDSatFlag)
  WriteDisk(db, "$Input/DStA0",DStA0)
  WriteDisk(db, "$Input/DStB0",DStB0)
  WriteDisk(db, "$Input/DStC0",DStC0)
  WriteDisk(db, "$Input/DStMax",DStMax)
  WriteDisk(db, "$Input/DStMin",DStMin)
  
  #
  #########################
  #
  
  for year in Years, area in Areas, enduse in Enduses
   DDSmoothingTime[enduse,area,year] = 20
  end

  WriteDisk(db, "$Input/DDSmoothingTime",DDSmoothingTime)

  #
  #########################
  #
  for enduse in Enduses, area in Areas, year in Years
    DDSat[enduse,area,year] = sum(DDayMonthly[enduse,month,area,year] * DDSatFlag[enduse,month]
                                  for month in Months)
  end

  for area in Areas, enduse in Enduses
    DDSmooth[enduse,area,Zero] = DDSat[enduse,area,Yr(2013)]
  end

  WriteDisk(db, "$Outpt/DDSmooth",DDSmooth)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DDSatFlag::VariableArray{2} = ReadDisk(db,"$Input/DDSatFlag") # [Enduse,Month] Flag for Degree Days in Saturation Equation (1=include)
  DStA0::VariableArray{4} = ReadDisk(db,"$Input/DStA0") # [Enduse,EC,Area,Year] Device Saturation Degree Day Coefficient (Btu/Btu/DD)
  DStB0::VariableArray{4} = ReadDisk(db,"$Input/DStB0") # [Enduse,EC,Area,Year] Device Saturation Area Adjustment (Btu/Btu)
  DStC0::VariableArray{4} = ReadDisk(db,"$Input/DStC0") # [Enduse,EC,Area,Year] Device Saturation Constant Term (Btu/Btu)
  DStMax::VariableArray{3} = ReadDisk(db,"$Input/DStMax") # [Enduse,EC,Area] Maximum Device Saturation (Btu/Btu)
  DStMin::VariableArray{3} = ReadDisk(db,"$Input/DStMin") # [Enduse,EC,Area] Minimum Device Saturation (Btu/Btu)
  DDSmoothingTime::VariableArray{3} = ReadDisk(db,"$Input/DDSmoothingTime") # [Enduse,Area,Year] Smoothing Time for Annual Degree Days (Years)
  DDayMonthly::VariableArray{4} = ReadDisk(db,"$Input/DDayMonthly") # [Enduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  DDSat::VariableArray{3} = ReadDisk(db,"$Outpt/DDSat") # [Enduse,Area,Year] Degree Days for Saturation Equation (Degree Days)
  DDSmooth::VariableArray{3} = ReadDisk(db,"$Outpt/DDSmooth") # [Enduse,Area,Year] SmoothedDegree Days (Degree Days)

  # Scratch Variables
end

function CCalibration(db)
  data = CControl(; db)
  (;Input,Outpt) = data
  (;Areas,ECs,Enduse,Enduses,Months,Years) = data
  (;DDSatFlag,DStA0,DStB0,DStC0,DStMax,DStMin,DDSmoothingTime,DDayMonthly,DDSat,DDSmooth) = data

  #
  # Air Conditioning Saturation
  #
  enduse = Select(Enduse,"AC")

  #
  # DSt=DStC0+DStB0*exp(DStA0*DDSmooth)   
  #
  
  for year in Years, area in Areas, ec in ECs
   DStA0[enduse,ec,area,year] = -0.00298
  end 
  
  for year in Years, area in Areas, ec in ECs
   DStB0[enduse,ec,area,year] = -1.17
  end 
   
  for year in Years, area in Areas, ec in ECs
   DStC0[enduse,ec,area,year] = 0.944 
  end 
  
  for month in Months
   DDSatFlag[enduse,month] = 1
  end
  
  for area in Areas, ec in ECs
   DStMax[enduse,ec,area] = 0.980
  end 
   
  for area in Areas, ec in ECs
   DStMin[enduse,ec,area] = 0.022
  end
  
  WriteDisk(db, "$Input/DDSatFlag",DDSatFlag)
  WriteDisk(db, "$Input/DStA0",DStA0)
  WriteDisk(db, "$Input/DStB0",DStB0)
  WriteDisk(db, "$Input/DStC0",DStC0)
  WriteDisk(db, "$Input/DStMax",DStMax)
  WriteDisk(db, "$Input/DStMin",DStMin)
  
  #
  #########################
  #
  
  for year in Years, area in Areas, enduse in Enduses
   DDSmoothingTime[enduse,area,year] = 20
  end 

  WriteDisk(db, "$Input/DDSmoothingTime",DDSmoothingTime)

  #
  #########################
  #
  for enduse in Enduses, area in Areas, year in Years
    DDSat[enduse,area,year] = sum(DDayMonthly[enduse,month,area,year] * DDSatFlag[enduse,month]
                                  for month in Months)
  end

  for area in Areas, enduse in Enduses
    DDSmooth[enduse,area,Zero] = DDSat[enduse,area,Yr(2013)]
  end
  
  WriteDisk(db, "$Outpt/DDSmooth",DDSmooth)

end

function CalibrationControl(db)
  @info "ACSaturationCoefficients.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
