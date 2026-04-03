#
# UnitDataPatch_CA.jl - Set values for future years
#
using EnergyModel

module UnitDataPatch_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Avaliability Factor (MWh/MWh)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Months,TimePs,Years) = data
  (;UnArea,UnCode,UnEAF,UnMustRun,UnOR,UnPlant,UnRetire,xUnEGA) = data
  (;xUnGC) = data

  #
  ########################
  #
  # Patch for Must Run status of California units
  #
  units=findall(UnCode[:] .== "CA_CANO1050")
  for unit in units
    if UnCode[unit] == "CA_CANO1050"
      UnMustRun[unit]=1
    end
  end

  WriteDisk(db,"EGInput/UnMustRun",UnMustRun)

  #
  ########################
  #
  # Outage Rate for Units in California
  #
  units=findall(UnArea[:] .== "CA")
  for unit in units
    if UnArea[unit] == "CA"
      #
      # Outage Rate for Must Run Units in California
      #
      if UnMustRun[unit] == 1.0
        years=collect(First:Yr(2016))
        for year in years, month in Months, timep in TimePs
          @finite_math UnOR[unit,timep,month,year]=1-xUnEGA[unit,year]/(xUnGC[unit,year]*8760/1000)
        end
        years=collect(Yr(2017):Final)
        for year in years, month in Months, timep in TimePs
          UnOR[unit,timep,month,year]=UnOR[unit,timep,month,Yr(2016)]
        end
      end

      #
      # Outage Rate for Pumped Hydro Units in California
      #
      if UnPlant[unit] == "PumpedHydro"
        years=collect(First:Yr(2016))
        for year in years, month in Months, timep in TimePs
          @finite_math UnOR[unit,timep,month,year]=1-xUnEGA[unit,year]/(xUnGC[unit,year]*8760/1000)
        end
        years=collect(Yr(2017):Final)
        for year in years, month in Months, timep in TimePs
          UnOR[unit,timep,month,year]=UnOR[unit,timep,month,Yr(2016)]
        end
      end
    end
  end
  WriteDisk(db,"EGInput/UnOR",UnOR)

  #
  ########################
  #
  # Energy Availability for California Peak Hydro Units
  #
  units_CA=findall(UnArea[:] .== "CA")
  units_P=findall(UnPlant[:] .== "PeakHydro")
  units=intersect(units_CA,units_P)
  for unit in units
    if (UnArea[unit] == "CA") && (UnPlant[unit] == "PeakHydro")
      years=collect(Yr(2017):Final)
      for year in years, month in Months
        UnEAF[unit,month,year]=UnEAF[unit,month,Yr(2016)]
      end
    end
  end
  WriteDisk(db,"EGInput/UnEAF",UnEAF)

  #
  ########################
  #
  # California Nuclear Units
  #
  # Nuclear in California (Diablo Canyon) is planned to be retired
  # by 2026 (As of 2019). However, there have been policies to keep it in place.
  # To set the policy, we need non-zero capacity, so the retirement date is
  # used as the policy variable. 04/26/19. R.Levesque
  #
  units_CA=findall(UnArea[:] .== "CA")
  units_P=findall(UnPlant[:] .== "Nuclear")
  units=intersect(units_CA,units_P)
  for unit in units
    if (UnArea[unit] == "CA") && (UnPlant[unit] == "Nuclear")
      for year in Years, month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=0
      end
      years=collect(Yr(2017):Final)
      for year in years
        xUnGC[unit,year]=xUnGC[unit,Yr(2016)]
      end
    end
  end

  #
  # Diablo Canyon 1
  #
  units=findall(UnCode[:] .== "CA_6099_1")
  for unit in units
    if UnCode[unit] == "CA_6099_1"
      for year in Years
        UnRetire[unit,year]=2024
      end
      years=collect(Yr(2017):Yr(2023))
      for year in years
        xUnEGA[unit,year]=xUnEGA[unit,Yr(2016)]
      end
    end
  end

  #
  # Diablo Canyon 2
  #
  units=findall(UnCode[:] .== "CA_6099_2")
  for unit in units
    if UnCode[unit] == "CA_6099_2"
      for year in Years
        UnRetire[unit,year]=2025
      end
      years=collect(Yr(2017):Yr(2024))
      for year in years
        xUnEGA[unit,year]=xUnEGA[unit,Yr(2016)]
      end
    end
  end

  #
  # San Onofre 2 and 3 (Decommissioned unit)
  #
  units1=findall(UnCode[:] .== "CA_360_2")
  units2=findall(UnCode[:] .== "CA_360_3")
  units=intersect(units1,units2)
  for unit in units
    if (UnCode[unit] == "CA_360_2") || (UnCode[unit] == "CA_360_3")
      for year in Years
        UnRetire[unit,year]=2012
      end
    end
  end

  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGInput/UnRetire",UnRetire)
  WriteDisk(db,"EGInput/xUnGC",xUnGC)
  WriteDisk(db,"EGInput/xUnEGA",xUnEGA)

end

function CalibrationControl(db)
  @info "UnitDataPatch_CA.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
