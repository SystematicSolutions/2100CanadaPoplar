#
#  UnitAddCap_US.jl - Add Capacity
#
using EnergyModel

module UnitAddCap_US

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

  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnGC::VariableArray{2} = ReadDisk(db,"EGOutput/UnGC") # [Unit,Year] Generating Capacity (MW)
  xUnGC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGC") # [Unit,Year] Generating Capacity (MW)

  # Scratch Variables
  # CapacityAdditions  'Capacity Additions (MW)'
  # UCode    'Scratch Variable for UnCode', Type=String(20)
  # YearCapacityOnLine 'Year Capacity Comes On-Line (Year)'
end

# function GetUnitSets(data)
#   (;CalDB,Input,Outpt) = data
#   (;Unit,Units,Year,YearDS,Years) = data
#   (;UnArea,UnGenCo,UnNode,UnPlant,UnCode,UnOnLine,UnGC,xUnGC) = data

# end

# function ResetUnitSets(data)
#   (;CalDB,Input,Outpt) = data
#   (;Unit,Units,Year,YearDS,Years) = data
#   (;UnArea,UnGenCo,UnNode,UnPlant,UnCode,UnOnLine,UnGC,xUnGC) = data

# end

function AddCapacity(data,UCode,YearCapacityOnLine,CapacityAdditions)
  (;Yrv) = data
  (;UnCode,UnOnLine,xUnGC) = data

  unit=findall(UnCode[:] .== UCode)
  if length(unit) > 1 || isempty(unit)
      @info "Could not match UnCode $UCode"
  else
    #
    # Select GenCo, Area, Node, and Plant Type for this Unit
    #
    # GetUnitSets  # Note: Sets not used.
    #
    #   Update Online year if needed.
    #
    for u in unit
      UnOnLine[u]=min(UnOnLine[u],Yrv[Yr(YearCapacityOnLine)])
    end
    #
    #   If the plant comes on later in the forecast, then simulate construction
    #
    years=collect(Int(YearCapacityOnLine-ITime+1):Final)
    # years=collect(Int(1986-ITime+1):Final)
    for year in years, u in unit
      xUnGC[u,year]=xUnGC[u,year]+CapacityAdditions/1000
      # xUnGC[unit,year]=xUnGC[unit,year]+10.0/1000
    end
  end

end

function ECalibration(db)
  data = EControl(; db)
  (;UnOnLine,xUnGC) = data

  #                UnCode              Year xUnGCCI
  AddCapacity(data,"SRSG_Waste",       1986,10.0)
  AddCapacity(data,"TRE_Waste",        1986,10.0)
  AddCapacity(data,"MISW_Waste",       1986,10.0)
  AddCapacity(data,"MISW_Geothermal",  1986,10.0)
  AddCapacity(data,"SPPN_Geothermal",  1986,10.0)
  AddCapacity(data,"NYCW_OnshoreWind", 1986,10.0)
  AddCapacity(data,"NYCW_SolarPV",     1986,10.0)
  AddCapacity(data,"MISE_Waste",       1986,10.0)
  AddCapacity(data,"PJMW_Waste",       1986,10.0)
  AddCapacity(data,"PJMW_OffshoreWind",1986,10.0)
  AddCapacity(data,"RMRG_Waste",       1986,10.0)
  AddCapacity(data,"MISS_Waste",       1986,10.0)
  AddCapacity(data,"MISC_Waste",       1986,10.0)
  AddCapacity(data,"SRCE_Waste",       1986,10.0)
  AddCapacity(data,"SPPC_Waste",       1986,10.0)
  AddCapacity(data,"SPPS_Waste",       1986,10.0)
  AddCapacity(data,"SRCA_OffshoreWind",1986,10.0)

  WriteDisk(db,"EGInput/UnOnLine",UnOnLine)
  WriteDisk(db,"EGInput/xUnGC",xUnGC)


end

function CalibrationControl(db)
  @info "UnitAddCap_US.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
