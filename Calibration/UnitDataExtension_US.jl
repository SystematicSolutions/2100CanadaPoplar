#
# UnitDataExtension_US.jl - Set values for future years
#
using EnergyModel

module UnitDataExtension_US

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

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
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
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnUFOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUFOMC") # [Unit,Year] Fixed O&M Costs ($/Kw/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable O&M Costs (Real $/MWH)
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)
  xUnGCCC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/KW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;FuelEPs,Months,TimePs) = data
  (;UnEAF,UnHRt,UnNation,UnOnLine,UnOR,UnUFOMC,UnUOMC,xUnDmd,xUnEGA,xUnGC) = data
  (;xUnGCCC) = data

  #
  # Select US Units
  #
  units=findall(UnNation[:] .== "US")
  for unit in units
    #
    # EIA data begins in 2001 - use for prior years
    #
    years=collect(Yr(1985):Yr(2000))
    for year in years
      for month in Months
        UnEAF[unit,month,year]=UnEAF[unit,month,Yr(2001)]
      end
      UnHRt[unit,year]=UnHRt[unit,Yr(2001)]
      for month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=UnOR[unit,timep,month,Yr(2001)]
      end
      UnUFOMC[unit,year]=UnUFOMC[unit,Yr(2001)]
      UnUOMC[unit,year]=UnUOMC[unit,Yr(2001)]
      for fuelep in FuelEPs
        xUnDmd[unit,fuelep,year]=xUnDmd[unit,fuelep,Yr(2001)]
      end
      xUnEGA[unit,year]=xUnEGA[unit,Yr(2001)]
      xUnGC[unit,year]=xUnGC[unit,Yr(2001)]
      xUnGCCC[unit,year]=xUnGCCC[unit,Yr(2001)]
    end
    #
    # EIA data ends in 2020 - extend into future
    #
    years=collect(Yr(2021):Final)
    for year in years
      for month in Months
        UnEAF[unit,month,year]=UnEAF[unit,month,Yr(2020)]
      end
      UnHRt[unit,year]=UnHRt[unit,Yr(2020)]
      for month in Months, timep in TimePs
        UnOR[unit,timep,month,year]=UnOR[unit,timep,month,Yr(2020)]
      end
      UnUFOMC[unit,year]=UnUFOMC[unit,Yr(2020)]
      UnUOMC[unit,year]=UnUOMC[unit,Yr(2020)]
      for fuelep in FuelEPs
        xUnDmd[unit,fuelep,year]=xUnDmd[unit,fuelep,Yr(2020)]
      end
      xUnEGA[unit,year]=xUnEGA[unit,Yr(2020)]
      xUnGC[unit,year]=xUnGC[unit,Yr(2020)]
      xUnGCCC[unit,year]=xUnGCCC[unit,Yr(2020)]
    end
  end

  #
  # Capacity, Generation, and Fuel Demands are set to zero before OnLine date
  #
  for unit in units
    if UnOnLine[unit] > ITime
      Loc1=Int(min(UnOnLine[unit]-1,MaxTime)-ITime+1)
      years=collect(1:Loc1)
      for year in years
        xUnGC[unit,year]=0.0
        xUnEGA[unit,year]=0.0
        for fuelep in FuelEPs
          xUnDmd[unit,fuelep,year]=0.0
        end
      end
    end
  end

  WriteDisk(db,"EGInput/UnEAF",UnEAF)
  WriteDisk(db,"EGInput/UnHRt",UnHRt)
  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGInput/UnUFOMC",UnUFOMC)
  WriteDisk(db,"EGInput/UnUOMC",UnUOMC)
  WriteDisk(db,"EGInput/xUnDmd",xUnDmd)
  WriteDisk(db,"EGInput/xUnEGA",xUnEGA)
  WriteDisk(db,"EGInput/xUnGC",xUnGC)
  WriteDisk(db,"EGInput/xUnGCCC",xUnGCCC)

end

function CalibrationControl(db)
  @info "UnitDataExtension_US.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
