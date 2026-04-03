#
# HouseholdLDVFraction.jl - Used for breaking out household transportation for TOM
#
using EnergyModel

module HouseholdLDVFraction

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct HouseholdLDVFractionData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  HouseholdLDVFraction::VariableArray{2} = ReadDisk(db,"KInput/HouseholdLDVFraction") # [Area,Year] Fraction of LDV/LDT Investments from Households (vs Fleet) (Btu/Btu)
end

function AssignValues(db)
  data = HouseholdLDVFractionData(; db)
  (; Area,Areas,Year,Years) = data
  (; HouseholdLDVFraction) = data

  #
  # HouseholdLDVFraction[Area,Year] Fraction of LDV/LDT Investments from Households (vs Fleet) (Btu/Btu)
  # Assume Household Fraction of LDV/LDT Investments is 80% (Rest is Fleet)
  #
  # "Fleet Customers Make up Nearly 20 Percent of Auto Sales":
  # https://www.barsnet.com/fleet-customers-make-up-nearly-20-percent-of-auto-sales/
  # Use this assumption unless Oxford sends updated fractions. 22.03.17 R.Levesque
  #

  @. HouseholdLDVFraction = 0.80
  WriteDisk(db,"KInput/HouseholdLDVFraction",HouseholdLDVFraction)
end

function HouseholdLDVFractionControl(db)
  AssignValues(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  HouseholdLDVFractionControl(DB)
end

end
