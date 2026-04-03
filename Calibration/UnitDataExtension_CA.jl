#
# UnitDataExtension_CA.jl - Set values for future years
#
using EnergyModel

module UnitDataExtension_CA

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  xUnDmd::VariableArray{3} = ReadDisk(db,"EGInput/xUnDmd") # [Unit,FuelEP,Year] Historical Unit Energy Demands (TBtu)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;FuelEPs,Years) = data
  (;UnArea,UnCode,UnHRt,UnOnLine,UnPlant,xUnDmd,xUnEGA,xUnGC) = data

  #
  # Select CA Solar Unit
  #
  units=findall(UnCode[:] .== "CA_CANO13310")
  for unit in units
    if UnCode[unit] == "CA_CANO13310"
      #
      # Data for unit begins in 2008 - use for prior years
      #
      UnOnLine[unit]=1985
      years=collect(Yr(1985):Yr(2007))
      for year in years
        for fuelep in FuelEPs
          xUnDmd[unit,fuelep,year]=xUnDmd[unit,fuelep,Yr(2008)]
        end
        xUnEGA[unit,year]=xUnEGA[unit,Yr(2008)]
        xUnGC[unit,year]=xUnGC[unit,Yr(2008)]
      end
    end
  end

  units_CA=findall(UnArea[:] .== "CA")
  units_GT=findall(UnPlant[:] .== "Geothermal")
  units=intersect(units_CA,units_GT)
  for unit in units
    if (UnArea[unit] == "CA") && (UnPlant[unit] == "Geothermal")
      #
      # Patch for Heat Rate
      #
      for year in Years
        UnHRt[unit,year]=3412
      end
      #
      # Data for Geothermal ends in 2001 - use for prior years
      #
      years=collect(Yr(1985):Yr(2000))
      for year in years
        for fuelep in FuelEPs
          xUnDmd[unit,fuelep,year]=xUnDmd[unit,fuelep,Yr(2001)]
        end
        xUnEGA[unit,year]=xUnEGA[unit,Yr(2001)]
      end
    end
  end

  WriteDisk(db,"EGInput/UnHRt",UnHRt)
  WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
  WriteDisk(db,"EGInput/xUnDmd",xUnDmd)
  WriteDisk(db,"EGInput/xUnEGA",xUnEGA)
  WriteDisk(db,"EGInput/xUnGC",xUnGC)

end

function CalibrationControl(db)
  @info "UnitDataExtension_CA.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
