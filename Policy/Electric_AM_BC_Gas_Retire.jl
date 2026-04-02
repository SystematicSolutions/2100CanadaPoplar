#
# Electric_AM_BC_Gas_Retire.jl
#
#
# In its clean electricity policy, in 2030, BC wants to stop using natural gas
# to generate electricity in utility power plants ("cogen" still allowed)
# Author: Thomas Dandres
# Date: Nov 2021
#
# Based on a new conversation with BC, it appears the existing plant would be allowed
# to continue to generate. Only new plants would not be allowed to be added to the grid
# This TXP should be deactivated in Ref25.
# Thomas Dandres, January 2024
#

using EnergyModel

module Electric_AM_BC_Gas_Retire

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)

  # Scratch Variables
  # UCode     'Unit Code of Unit with New Retirement Date',Type = String(20)
  # UName     'Unit Name',Type = String(20)
  # URetire   'New Retirement Date (Year)'
  # URetireOld     'Old Retirement Date (Year)'
end

function GetUnitData(data,UCode,UName,URetire)
  (; UnCode,UnRetire,Years) = data
  unit = Select(UnCode,UCode)
  if unit == []
    @debug("Could not match UnCode $UCode")
  else
    URetireOld = UnRetire[unit,Future]
    if URetire < URetireOld
      for year in Years
        UnRetire[unit,year] = URetire
      end
    end
  end
  return
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Years) = data
  (; UnCode,UnRetire) = data

  #
  #                  UnCode           UnitName           UnRetire
  GetUnitData(data,"BC_Group_03"  ,"Duke_Eng_Taylor",      2030)
  GetUnitData(data,"BC00002500201","Prince Rupert",        2030)
  GetUnitData(data,"BC00002500202","Prince Rupert",        2030)
  GetUnitData(data,"BC_Endo080308","Endo OtherGeneration", 2030)

  # WriteDisk(db,"EGInput/UnRetire",UnRetire)
end

function PolicyControl(db)
  @info "Electric_AM_BC_Gas_Retire.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
