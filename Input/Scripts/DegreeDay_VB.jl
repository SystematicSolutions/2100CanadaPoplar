#
# DegreeDay_VB.jl - Apply efficiency trend from VBInput
#
# Ian 09/16/2015
#
using EnergyModel

module DegreeDay_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DDCoefficient::VariableArray{4} = ReadDisk(db,"$Input/DDCoefficient") # [Enduse,EC,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  DDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  DDayMonthly::VariableArray{4} = ReadDisk(db,"$Input/DDayMonthly") # [Enduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  vDDCoefficient::VariableArray{3} = ReadDisk(db,"VBInput/vDDCoefficient") # [vEnduse,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  vDDay::VariableArray{3} = ReadDisk(db,"VBInput/vDDay") # [vEnduse,Area,Year] Degree days(Degree Days)  
  vDDayMonthly::VariableArray{4} = ReadDisk(db,"VBInput/vDDayMonthly") # [vEnduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  vDDayNorm::VariableArray{2} = ReadDisk(db,"VBInput/vDDayNorm") # [vEnduse,Area] Normal Annual Degree days(Degree Days)  
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
end

function RCalibration(db)
  data = RControl(; db)
  (;Input,Areas,ECs,Enduse,Month,Months,Nation,Years,vEnduse,vEnduses) = data
  (;ANMap,DDCoefficient,DDay,DDayMonthly,DDayNorm,vDDCoefficient,vDDay,vDDayMonthly,vDDayNorm,vEUMap) = data

  # 
  # Select All Areas
  # 
  Heat = Select(Enduse,"Heat")
  vHeat = 1
  AC = Select(Enduse,"AC")
  vAC = Select(vEnduse,"AC")

  for ec in ECs, area in Areas, year in Years
    DDCoefficient[Heat,ec,area,year] = vDDCoefficient[vHeat,area,year]
    DDCoefficient[AC,ec,area,year] = vDDCoefficient[vAC,area,year]
  end

  # 
  # Select CN Areas
  # 
  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  # 
  # Heating
  # 
  for area in cn_areas, year in Years
    DDayMonthly[Heat,Select(Month,"Winter"),area,year] = vDDay[vHeat,area,year]
    DDay[Heat,area,year] = vDDay[vHeat,area,year]
    DDayNorm[Heat,area] = vDDayNorm[vHeat,area]
  end

  # 
  # Cooling
  # 
  for area in cn_areas, year in Years
    DDayMonthly[AC,Select(Month,"Summer"),area,year] = vDDay[vAC,area,year]
    DDay[AC,area,year] = vDDay[vAC,area,year]
    DDayNorm[AC,area] = vDDayNorm[vAC,area]
  end

  # 
  # Select US and MX Areas
  # 
  US = Select(Nation,"US")
  MX = Select(Nation,"MX")
  us_areas = findall(ANMap[:,US] .== 1.0)
  mx_areas = findall(ANMap[:,MX] .== 1.0)
  us_mx_areas = union(us_areas,mx_areas)

  # 
  # Heating
  # 
  for month in Months, area in us_mx_areas, year in Years
    DDayMonthly[Heat,month,area,year] = vDDayMonthly[vHeat,month,area,year]
    DDay[Heat,area,year] = vDDay[vHeat,area,year]
    DDayNorm[Heat,area] = vDDayNorm[vHeat,area]
  end

  # 
  # Cooling
  # 
  for month in Months, area in us_mx_areas, year in Years
    DDayMonthly[AC,month,area,year] = vDDayMonthly[vAC,month,area,year]
    DDay[AC,area,year] = vDDay[vAC,area,year]
    DDayNorm[AC,area] = vDDayNorm[vAC,area]
  end

  WriteDisk(db,"$Input/DDCoefficient",DDCoefficient)
  WriteDisk(db,"$Input/DDay",DDay)
  WriteDisk(db,"$Input/DDayNorm",DDayNorm)
  WriteDisk(db,"$Input/DDayMonthly",DDayMonthly)

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DDCoefficient::VariableArray{4} = ReadDisk(db,"$Input/DDCoefficient") # [Enduse,EC,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  DDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  DDayMonthly::VariableArray{4} = ReadDisk(db,"$Input/DDayMonthly") # [Enduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  vDDCoefficient::VariableArray{3} = ReadDisk(db,"VBInput/vDDCoefficient") # [vEnduse,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  vDDay::VariableArray{3} = ReadDisk(db,"VBInput/vDDay") # [vEnduse,Area,Year] Degree days(Degree Days)  
  vDDayMonthly::VariableArray{4} = ReadDisk(db,"VBInput/vDDayMonthly") # [vEnduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  vDDayNorm::VariableArray{2} = ReadDisk(db,"VBInput/vDDayNorm") # [vEnduse,Area] Normal Annual Degree days(Degree Days)  
  vEUMap::VariableArray{2} = ReadDisk(db,"$Input/vEUMap") # [vEnduse,Enduse] Map between Enduse and vEnduse
end

function CCalibration(db)
  data = CControl(; db)
  (;Input,Areas,ECs,Enduse,Month,Months,Nation,Years,vEnduse,vEnduses) = data
  (;ANMap,DDCoefficient,DDay,DDayMonthly,DDayNorm,vDDCoefficient,vDDay,vDDayMonthly,vDDayNorm,vEUMap) = data

  # 
  # Select All Areas
  # 
  Heat = Select(Enduse,"Heat")
  vHeat = 1
  AC = Select(Enduse,"AC")
  vAC = Select(vEnduse,"AC")

  for ec in ECs, area in Areas, year in Years
    DDCoefficient[Heat,ec,area,year] = vDDCoefficient[vHeat,area,year]
    DDCoefficient[AC,ec,area,year] = vDDCoefficient[vAC,area,year]
  end

  # 
  # Select CN Areas
  # 
  CN = Select(Nation, "CN")
  cn_areas = findall(ANMap[:,CN] .== 1.0)

  # 
  # Heating
  # 
  for area in cn_areas, year in Years
    DDayMonthly[Heat,Select(Month,"Winter"),area,year] = vDDay[vHeat,area,year]
    DDay[Heat,area,year] = vDDay[vHeat,area,year]
    DDayNorm[Heat,area] = vDDayNorm[vHeat,area]
  end

  # 
  # Cooling
  # 
  for area in cn_areas, year in Years
    DDayMonthly[AC,Select(Month,"Summer"),area,year] = vDDay[vAC,area,year]
    DDay[AC,area,year] = vDDay[vAC,area,year]
    DDayNorm[AC,area] = vDDayNorm[vAC,area]
  end

  # 
  # Select US and MX Areas
  # 
  US = Select(Nation,"US")
  MX = Select(Nation,"MX")
  us_areas = findall(ANMap[:,US] .== 1.0)
  mx_areas = findall(ANMap[:,MX] .== 1.0)
  us_mx_areas = union(us_areas,mx_areas)

  # 
  # Heating
  # 
  for month in Months, area in us_mx_areas, year in Years
    DDayMonthly[Heat,month,area,year] = vDDayMonthly[vHeat,month,area,year]
    DDay[Heat,area,year] = vDDay[vHeat,area,year]
    DDayNorm[Heat,area] = vDDayNorm[vHeat,area]
  end

  # 
  # Cooling
  # 
  for month in Months, area in us_mx_areas, year in Years
    DDayMonthly[AC,month,area,year] = vDDayMonthly[vAC,month,area,year]
    DDay[AC,area,year] = vDDay[vAC,area,year]
    DDayNorm[AC,area] = vDDayNorm[vAC,area]
  end

  WriteDisk(db,"$Input/DDCoefficient",DDCoefficient)
  WriteDisk(db,"$Input/DDay",DDay)
  WriteDisk(db,"$Input/DDayNorm",DDayNorm)
  WriteDisk(db,"$Input/DDayMonthly",DDayMonthly)

end

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
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DDCoefficient::VariableArray{4} = ReadDisk(db,"$Input/DDCoefficient") # [Enduse,EC,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  DDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  DDayMonthly::VariableArray{4} = ReadDisk(db,"$Input/DDayMonthly") # [Enduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  vDDCoefficient::VariableArray{3} = ReadDisk(db,"VBInput/vDDCoefficient") # [vEnduse,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  vDDay::VariableArray{3} = ReadDisk(db,"VBInput/vDDay") # [vEnduse,Area,Year] Degree days(Degree Days)  
  vDDayMonthly::VariableArray{4} = ReadDisk(db,"VBInput/vDDayMonthly") # [vEnduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  vDDayNorm::VariableArray{2} = ReadDisk(db,"VBInput/vDDayNorm") # [vEnduse,Area] Normal Annual Degree days(Degree Days)  
end

function ICalibration(db)
  data = IControl(; db)
  (;Input,DDay,DDayMonthly,DDayNorm) = data

  DDayMonthly .= 1
  DDay .= 1
  DDayNorm .= 1

  WriteDisk(db,"$Input/DDay",DDay)
  WriteDisk(db,"$Input/DDayNorm",DDayNorm)
  WriteDisk(db,"$Input/DDayMonthly",DDayMonthly)
  
end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vEnduse::SetArray = ReadDisk(db,"MainDB/vEnduseKey")
  vEnduseDS::SetArray = ReadDisk(db,"MainDB/vEnduseDS")
  vEnduses::Vector{Int} = collect(Select(vEnduse))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DDCoefficient::VariableArray{4} = ReadDisk(db,"$Input/DDCoefficient") # [Enduse,EC,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  DDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  DDayMonthly::VariableArray{4} = ReadDisk(db,"$Input/DDayMonthly") # [Enduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  vDDCoefficient::VariableArray{3} = ReadDisk(db,"VBInput/vDDCoefficient") # [vEnduse,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  vDDay::VariableArray{3} = ReadDisk(db,"VBInput/vDDay") # [vEnduse,Area,Year] Degree days(Degree Days)  
  vDDayMonthly::VariableArray{4} = ReadDisk(db,"VBInput/vDDayMonthly") # [vEnduse,Month,Area,Year] Monthly Degree Days (Degree Days)
  vDDayNorm::VariableArray{2} = ReadDisk(db,"VBInput/vDDayNorm") # [vEnduse,Area] Normal Annual Degree days(Degree Days)  
end

function TCalibration(db)
  data = TControl(; db)
  (;Input,DDay,DDayMonthly,DDayNorm) = data

  DDayMonthly .= 1
  DDay .= 1
  DDayNorm .= 1

  WriteDisk(db,"$Input/DDay",DDay)
  WriteDisk(db,"$Input/DDayNorm",DDayNorm)
  WriteDisk(db,"$Input/DDayMonthly",DDayMonthly)

end

function CalibrationControl(db)
  @info "DegreeDay_VB.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
