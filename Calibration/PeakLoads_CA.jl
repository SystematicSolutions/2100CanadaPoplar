#
# PeakLoads_CA.jl
# Update 8/11/17 R.Levesque
#
using EnergyModel

module PeakLoads_CA

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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  TDEF::VariableArray{3} = ReadDisk(db,"SInput/TDEF") # [Fuel,Area,Year] T&D Efficiency (Btu/Btu)
  xMonOut::VariableArray{3} = ReadDisk(db,"SInput/xMonOut") # [Month,Area,Year] Historical Monthly Output (GWh/month)
  xSaEC::VariableArray{3} = ReadDisk(db,"SInput/xSaEC") # [ECC,Area,Year] Historical Electricity Sales (GWh/Yr)
  xPkLoad::VariableArray{3} = ReadDisk(db,"SInput/xPkLoad") # [Month,Area,Year] Historical Monthly Peak Load (MW)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  xMinLd::VariableArray{3} = ReadDisk(db,"SInput/xMinLd") # [Month,Area,Year] Historical Monthly Minimum Load (mW/month)

  # Scratch Variables
  AdjPeak::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Adjustment to Peak Load (MW/MW)
  RevPeak::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Revised Peak Load (MW)
  xTEA::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Energy Available from Sales (GWH)
  xXTEA::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Energy Avaliable from Monthly Output (GWH)
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,ECCs,Fuel,Month) = data
  (;Months,Years) = data
  (;TDEF,xMonOut,xSaEC,xPkLoad,HoursPerMonth,xMinLd) = data
  (;AdjPeak,RevPeak,xTEA,xXTEA) = data

  #
  # California T&D Line Efficiency from California Energy Demand Forecast Update, 2020 - 2030 Baseline Forecast - Mid Demand Case,
  # "STATEWIDE Form 1.4-Mid". R.Levesque 9/14/23
  #
  years = collect(Yr(1990):Yr(2030))
  fuel = Select(Fuel,"Electric")
  area = Select(Area,"CA")
  TDEF[fuel,area,years] = [
   #1990    1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030
   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.919   0.920   0.919   0.920   0.919   0.920   0.919   0.920   0.920   0.919   0.919   0.919   0.919   0.920   0.922   0.925   0.926   0.927   0.927   0.927   0.928   0.928   0.929   0.929   0.930   0.930   0.930
  ]

  years = collect(Yr(1985):Yr(1989))
  for year in years
    TDEF[fuel,area,year] = TDEF[fuel,area,Yr(1990)]
  end
  years = collect(Yr(2031):Final)
  for year in years
    TDEF[fuel,area,year] = TDEF[fuel,area,Yr(2030)]
  end

  WriteDisk(db,"SInput/TDEF",TDEF)

  #
  ########################
  #
  # Monthly Output
  #
  for year in Years
    xTEA[area,year] = sum(xSaEC[ecc,area,year] for ecc in ECCs) / TDEF[fuel,area,year]
  end

  #
  # Normalize Monthly Output to Sales and Losses
  #
  for year in Years
    xXTEA[area,year] = sum(xMonOut[month,area,year] for month in Months)
    for month in Months
      xMonOut[month,area,year] = xMonOut[month,area,year] / xXTEA[area,year] * xTEA[area,year]
    end
  end

  #
  # Forecast Monthly Output
  #
  years = collect(Yr(2021):Final)
  for month in Months, year in years
    xMonOut[month,area,year] = xMonOut[month,area,year-1] / xTEA[area,year-1] * xTEA[area,year]
  end

  WriteDisk(db,"SInput/xMonOut",xMonOut)

  #
  ########################
  #
  # Peak Load
  #
  #
  # Peak Load: California Energy Demand Forecast Update, 2020 - 2030 Baseline Forecast - Mid Demand Case
  # Form 1.4:  Net Peak Demand (MW)
  # R.Levesque 9/14/23
  #
  years = collect(Yr(1990):Yr(2030))
  RevPeak[area,years] = [
  #Year               1990    1991    1992    1993    1994    1995    1996    1997    1998    1999    2000    2001    2002    2003    2004    2005    2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016    2017    2018    2019    2020    2021    2022    2023    2024    2025    2026    2027    2028    2029    2030
                     47120   45155   47393   45302   47360   47764   49857   52131   54546   53170   53528   49686   52778   54678   55635   58099   63585   62318   61448   58596   62069   58305   59780   60735   61821   61856   62195   63996   60756   60606   60762   60889   61282   61760   62321   62634   63089   63433   63872   64249   64789
  ]

  years = collect(Yr(1985):Yr(1989))
  for year in years
    RevPeak[area,year] = RevPeak[area,Yr(1990)]
  end

  #
  # Adjust Historical Peak Load for all Months
  #
  Summer = Select(Month,"Summer")
  for year in Years
    AdjPeak[area,year] = RevPeak[area,year] / xPkLoad[Summer,area,year]
    for month in Months
      xPkLoad[month,area,year] = xPkLoad[month,area,year] * AdjPeak[area,year]
    end
  end

  #
  # Forecast California Peak Loads
  #
  years = collect(Yr(2021):Yr(2030))
  for month in Months, year in years
    xPkLoad[month,area,year] = xPkLoad[month,area,year-1] / RevPeak[area,year-1] * RevPeak[area,year]
  end

  #
  # Grow final years same as 2029 to 2030 growth
  #
  years = collect(Yr(2031):Final)
  for month in Months, year in years
    xPkLoad[month,area,year] = xPkLoad[month,area,year-1] * (xPkLoad[month,area,Yr(2030)] / xPkLoad[month,area,Yr(2029)])
  end

  WriteDisk(db,"SInput/xPkLoad",xPkLoad)

  #
  ########################
  #
  # Minimum Loads
  #
  # The Minimum Loads (xMinLd) are set equal to 55 percent of
  # Average Loads (xMonOut/Hours) based on an analysis of
  # Massachusetts loads from 1980 to 1989 (JSA 8/22/97).
  #
  for month in Months, year in Years
    xMinLd[month,area,year] = xMonOut[month,area,year] / HoursPerMonth[month] * 1000 * 0.55
  end

  WriteDisk(db,"SInput/xMinLd",xMinLd)

end

function CalibrationControl(db)
  @info "PeakLoads_CA.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
