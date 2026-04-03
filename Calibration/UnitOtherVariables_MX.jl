#
# UnitOtherVariables_MX.jl
#
using EnergyModel

module UnitOtherVariables_MX

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Avaliability Factor (MWh/MWh)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year]  Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation (GWh)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Months,TimePs,Years) = data
  (;UnEAF,UnMustRun,UnNation,UnOR,UnPlant,xUnGC,xUnEGA) = data

  units_mx=findall(UnNation[:] .== "MX")
  units_P=findall(UnPlant[:] .== "PeakHydro")
  units=intersect(units_mx,units_P)
  for unit in units
    if (UnNation[unit] == "MX") && (UnPlant[unit] == "PeakHydro")
      years=collect(First:Last)
      for year in years, month in Months
        @finite_math UnEAF[unit,month,year]=max(xUnEGA[unit,year]/(xUnGC[unit,year]*8760/1000),0)
      end
      years=collect(Future:Final)
      for year in years, month in Months
        UnEAF[unit,month,year]=UnEAF[unit,month,Last]
      end
    end
  end
  WriteDisk(db,"EGInput/UnEAF",UnEAF)

  #
  ########################
  #
  units_mx=findall(UnNation[:] .== "MX")
  for unit in units_mx
    if (UnNation[unit] == "MX") && ((UnPlant[unit] == "Nuclear")      || (UnPlant[unit] == "OnshoreWind") ||
                                    (UnPlant[unit] == "OffshoreWind") || (UnPlant[unit] == "Geothermal") ||
                                    (UnPlant[unit] == "SolarPV")      || (UnPlant[unit] == "SolarThermal"))
      years=collect(First:Last)
      for year in years, month in Months, timep in TimePs
        @finite_math UnOR[unit,timep,month,year]=1-max(xUnEGA[unit,year]/(xUnGC[unit,year]*8760/1000),0)
      end
      years=collect(Future:Final)
      for year in years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=UnOR[unit,timep,month,Last]
      end
    end
  end

  units_mx=findall(UnNation[:] .== "MX")
  units_P=findall(UnPlant[:] .== "Coal")
  units=intersect(units_mx,units_P)
  for unit in units
    if (UnNation[unit] == "MX") && (UnPlant[unit] == "Coal")
      for year in Years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=0
      end
      for month in Months, timep in TimePs
        UnOR[unit,timep,month,Yr(2025)]=.30
      end
      years=collect(Yr(2018):Yr(2024))
      for year in years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=UnOR[unit,timep,month,year-1]+(UnOR[unit,timep,month,Yr(2025)]-UnOR[unit,timep,month,Yr(2017)])/(2025-2017)
      end
      years=collect(Yr(2040):Final)
      for year in years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=.95
      end
      years=collect(Yr(2024):Yr(2039))
      for year in years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=UnOR[unit,timep,month,year-1]+(UnOR[unit,timep,month,Yr(2040)]-UnOR[unit,timep,month,Yr(2025)])/(2040-2025)
      end
    end
  end

  units_mx=findall(UnNation[:] .== "MX")
  units_P=findall(UnPlant[:] .== "OGSteam")
  units=intersect(units_mx,units_P)
  for unit in units
    if (UnNation[unit] == "MX") && (UnPlant[unit] == "OGSteam")
      for year in Years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=0
      end
      years=collect(Yr(2020):Final)
      for year in years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=.95
      end
      years=collect(Yr(2017):Yr(2019))
      for year in years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=UnOR[unit,timep,month,year-1]+(UnOR[unit,timep,month,Yr(2020)]-UnOR[unit,timep,month,Yr(2016)])/(2020-2016)
      end
    end
  end
  WriteDisk(db,"EGInput/UnOR",UnOR)

  #
  ########################
  #
  units_mx=findall(UnNation[:] .== "MX")
  units_P1=findall(UnPlant[:] .== "Coal")
  units_P2=findall(UnPlant[:] .== "OGSteam")
  units=intersect(units_mx,union(units_P1,units_P2))
  for unit in units
    if (UnNation[unit] == "MX") && ((UnPlant[unit] == "Coal") || (UnPlant[unit] == "OGSteam"))
      UnMustRun[unit]=1
    end
  end
  WriteDisk(db,"EGInput/UnMustRun",UnMustRun)

end

function CalibrationControl(db)
  @info "UnitOtherVariables_MX.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
