#
# ACSaturation_Forecast.jl - Read in historical AC saturation rates
#
using EnergyModel

module ACSaturation_Forecast

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)

  # Scratch Variables
  GrowthRate::VariableArray{3} = zeros(Float32,length(Enduse),length(EC),length(Area)) # [Enduse,EC,Area] Saturation Growth Rate (1/Yr)
  xDStLongSm::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Device Saturation Smoothed over Long Time (Btu/Btu)
  xDStMax::VariableArray{3} = zeros(Float32,length(Enduse),length(EC),length(Area)) # [Enduse,EC,Area] Maximum Saturation without Climate Change (Btu/Btu)
  xDStShortSm::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Device Saturation Smoothed over Short Time (Btu/Btu)
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduse) = data
  (;xDSt) = data
  (;GrowthRate,xDStLongSm,xDStMax,xDStShortSm) = data

  #*
  #* Last Year for AC Saturation Data
  #*
  YrLast = 2012-ITime+1
  YrFuture = YrLast+1

  enduse = Select(Enduse,"AC")
  LongTime = 10
  ShortTime = 3

  #*
  #* Smooth Saturation
  #*
  for area in Areas, ec in ECs
    xDStLongSm[enduse,ec,area,Zero] = xDSt[enduse,ec,area,Zero]  
  end
  for area in Areas, ec in ECs
    xDStShortSm[enduse,ec,area,Zero] = xDSt[enduse,ec,area,Zero]
  end  
  years = collect(First:YrLast)
  for ec in ECs, area in Areas, year in years
    xDStLongSm[enduse,ec,area,year] = xDStLongSm[enduse,ec,area,year-1] * (1-1/LongTime) +
                                      xDSt[enduse,ec,area,year] * (1/LongTime)
    xDStShortSm[enduse,ec,area,year] = xDStShortSm[enduse,ec,area,year-1] * (1-1/ShortTime) +
                                       xDSt[enduse,ec,area,year] * (1/ShortTime)
  end

  #*
  #* Saturation Growth Rate
  #*
  for ec in ECs, area in Areas
    GrowthRate[enduse,ec,area] = (xDStShortSm[enduse,ec,area,YrLast] / 
                                  xDStLongSm[enduse,ec,area,YrLast] - 1) / LongTime
  end

  #*
  #* Maximum Saturation without Climate Change
  #*
  for ec in ECs, area in Areas
    xDStMax[enduse,ec,area] = max(min(xDSt[enduse,ec,area,YrLast] + (1 - xDSt[enduse,ec,area,YrLast]) *
                                      0.50, 0.98), xDSt[enduse,ec,area,YrLast])
  end

  #*
  #* Forecast Saturation
  #*
  years = collect(YrFuture:Final)
  for ec in ECs, area in Areas, year in years
    xDSt[enduse,ec,area,year] = min(xDSt[enduse,ec,area,year-1] * (1 + GrowthRate[enduse,ec,area]),
                                    xDStMax[enduse,ec,area])
  end

  WriteDisk(db, "$Input/xDSt",xDSt)

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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)

  # Scratch Variables
  GrowthRate::VariableArray{3} = zeros(Float32,length(Enduse),length(EC),length(Area)) # [Enduse,EC,Area] Saturation Growth Rate (1/Yr)
  xDStLongSm::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Device Saturation Smoothed over Long Time (Btu/Btu)
  xDStMax::VariableArray{3} = zeros(Float32,length(Enduse),length(EC),length(Area)) # [Enduse,EC,Area] Maximum Saturation without Climate Change (Btu/Btu)
  xDStShortSm::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Device Saturation Smoothed over Short Time (Btu/Btu)
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,ECs,Enduse) = data
  (;xDSt) = data
  (;GrowthRate,xDStLongSm,xDStMax,xDStShortSm) = data

  #*
  #* Last Year for AC Saturation Data
  #*
  YrLast = 2012-ITime+1
  YrFuture = YrLast+1

  enduse = Select(Enduse,"AC")
  LongTime = 10
  ShortTime = 3

  #*
  #* Smooth Saturation
  #*
  for area in Areas, ec in ECs
    xDStLongSm[enduse,ec,area,Zero] = xDSt[enduse,ec,area,Zero]
  end  
  for area in Areas, ec in ECs  
    xDStShortSm[enduse,ec,area,Zero] = xDSt[enduse,ec,area,Zero]
  end
  years = collect(First:YrLast)
  for ec in ECs, area in Areas, year in years
    xDStLongSm[enduse,ec,area,year] = xDStLongSm[enduse,ec,area,year-1] * (1-1/LongTime) +
                                      xDSt[enduse,ec,area,year] * (1/LongTime)
    xDStShortSm[enduse,ec,area,year] = xDStShortSm[enduse,ec,area,year-1] * (1-1/ShortTime) +
                                       xDSt[enduse,ec,area,year] * (1/ShortTime)
  end

  #*
  #* Saturation Growth Rate
  #*
  for ec in ECs, area in Areas
    GrowthRate[enduse,ec,area] = (xDStShortSm[enduse,ec,area,YrLast] / 
                                  xDStLongSm[enduse,ec,area,YrLast] - 1) / LongTime
  end

  #*
  #* Maximum Saturation without Climate Change
  #*
  for ec in ECs, area in Areas
    xDStMax[enduse,ec,area] = max(min(xDSt[enduse,ec,area,YrLast] + (1 -xDSt[enduse,ec,area,YrLast]) *
                                      0.50, 0.98), xDSt[enduse,ec,area,YrLast])
  end

  #*
  #* Forecast Saturation
  #*
  years = collect(YrFuture:Final)
  for ec in ECs, area in Areas, year in years
    xDSt[enduse,ec,area,year] = min(xDSt[enduse,ec,area,year-1] * (1 + GrowthRate[enduse,ec,area]),
                                    xDStMax[enduse,ec,area])
  end

  WriteDisk(db, "$Input/xDSt",xDSt)

end

function CalibrationControl(db)
  @info "ACSaturation_Forecast.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
