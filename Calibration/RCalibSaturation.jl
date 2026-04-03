#
# RCalibSaturation.jl
#
using EnergyModel

module RCalibSaturation

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr, Last, Zero
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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DDSmooth::VariableArray{3} = ReadDisk(db,"$Outpt/DDSmooth") # [Enduse,Area,Year] SmoothedDegree Days (Degree Days)
  DStA0::VariableArray{4} = ReadDisk(db,"$Input/DStA0") # [Enduse,EC,Area,Year] Device Saturation Degree Day Coefficient (Btu/Btu/DD)
  DStB0::VariableArray{4} = ReadDisk(db,"$Input/DStB0") # [Enduse,EC,Area,Year] Device Saturation Area Adjustment (Btu/Btu)
  DStC0::VariableArray{4} = ReadDisk(db,"$Input/DStC0") # [Enduse,EC,Area,Year] Device Saturation Constant Term (Btu/Btu)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu) 

  # Scratch Variables
  DStSailor::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  DStdiff::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Difference in Device Saturation (Btu/Btu)
  LongSm::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Device Saturation Smoothed over Long Time (Btu/Btu)
  # LongTime 'Long Time for Smoothing (Years)'
  ShortSm::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Device Saturation Smoothed over Short Time (Btu/Btu)
  # ShortTime     'Short Time for Smoothing (Years)'
  Slope::VariableArray{3} = zeros(Float32,length(Enduse),length(EC),length(Area)) # [Enduse,EC,Area] Saturation Slope (1/Yr)
end

function RCalibration(db)
  data = RControl(; db)
  (;Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,Year) = data
  (;Input,Years) = data
  (;DDSmooth,DStA0,DStB0,DStC0,xDSt) = data
  (;DStSailor,DStdiff,LongSm,ShortSm,Slope) = data
  
  LongTime=10.0
  ShortTime=3.0
  #
  # Air Conditioning Saturation Calibration
  #
  AC = Select(Enduse,"AC")
  
  #
  # Assume no change in forecasted degree days
  #
  years = collect(Future:Final)
  for area in Areas, year in years
    DDSmooth[AC,area,year] = DDSmooth[AC,area,Last]
  end
  
  #
  # Sailor and Pavlova (2003): 
  #  S0 = 0.944 - 1.17  exp(-0.00298*CDD)
  # DSt = DStC0 - DStB0*exp(-DStA0  *DDSmooth)
  #
  # Original Sailor equation
  #
  for ec in ECs, area in Areas, year in Years
    DStSailor[AC,ec,area,year]=DStC0[AC,ec,area,year]+
    (DStB0[AC,ec,area,year]*exp(DStA0[AC,ec,area,year]*DDSmooth[AC,area,year]))
  end
  
  #
  # Difference between Sailor and historical saturation
  #
  years = collect(Zero:Last)
  for ec in ECs, area in Areas, year in years
    DStdiff[AC,ec,area,year] = xDSt[AC,ec,area,year]- DStSailor[AC,ec,area,year]
  end  
  
  #
  # Smooth Saturation Differences
  #
  # Select Year(Zero)
  for ec in ECs, area in Areas
    LongSm[AC,ec,area,Zero] = DStdiff[AC,ec,area,Zero]
    ShortSm[AC,ec,area,Zero] = DStdiff[AC,ec,area,Zero]
  end
  
  years = collect(First:Last)
  for ec in ECs, area in Areas, year in years
    LongSm[AC,ec,area,year] = (LongSm[AC,ec,area,year-1]*(1-1/LongTime)) +
    (DStdiff[AC,ec,area,year]*(1/LongTime))
    ShortSm[AC,ec,area,year] = (ShortSm[AC,ec,area,year-1]*(1-1/ShortTime)) +
    (DStdiff[AC,ec,area,year]*(1/ShortTime))
  end
  
  #
  # Slope for Saturation Differences 
  #
  for ec in ECs, area in Areas
    Slope[AC,ec,area] = max(((ShortSm[AC,ec,area,Last]-LongSm[AC,ec,area,Last])/LongTime),0.0)
  end
  
  #
  # Forecast Saturation Differences using Slope
  #
  years = collect(Future:Final)
  for ec in ECs, area in Areas, year in years
    DStdiff[AC,ec,area,year]= min((DStdiff[AC,ec,area,year-1]+ Slope[AC,ec,area]),0.98)
  end
  
  #
  # Adjust Sailor Intercept with Historical and Trended Saturation Differences
  #
  @. DStC0[AC,ECs,Areas,Years] = DStC0[AC,ECs,Areas,Years] + DStdiff[AC,ECs,Areas,Years]
  
  WriteDisk(db,"$Input/DStC0",DStC0)

end

function CalibrationControl(db)
  @info "RCalibSaturation.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
