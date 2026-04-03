#
# AdjustElectricity_AB.jl - Set Outage Rate and Energy Availability Factor
# for AB units.
#
using EnergyModel

module AdjustElectricity_AB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ECalib
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  TimeP::SetArray = ReadDisk(db,"MainDB/TimePKey")
  TimePs::Vector{Int} = collect(Select(TimeP))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnEGA::VariableArray{2} = ReadDisk(db,"EGOutput/UnEGA") # [Unit,Year] Generation (GWh)
  UnMustRun::VariableArray{1} = ReadDisk(db,"EGInput/UnMustRun") # [Unit] Must Run (1=Must Run)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPoTRExo::VariableArray{2} = ReadDisk(db,"EGInput/UnPoTRExo") # [Unit,Year] Exogenous Pollution Tax Rate (Real $/MWh)

  # Scratch Variables
  UnBonnyBrook::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Exogenous Pollution Tax Rate (Real $/MWh)
end

function ECalibration(db)
  data = ECalib(; db)
  (;Months,TimePs,Years) = data
  (;UnArea,UnCode,UnCogen,UnMustRun,UnOR,UnPlant,UnPoTRExo) = data
  (;UnBonnyBrook) = data
  
  unit1 = findall(UnArea .== "AB")
  unit2 = findall(UnPlant .== "Coal")
  unit3 = findall(UnMustRun .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1,unit2, unit3, unit4)
  years = collect(Yr(2010):Final)
  @. UnOR[units,TimePs,Months,years] = 0.25
  
  @. UnOR[units,TimePs,Months,Yr(2014)] = -0.05
  
  years = collect(Yr(2015):Yr(2017))
  @. UnOR[units,TimePs,Months,years] = 0.10
  
  years = collect(Yr(2018):Final)
  @. UnOR[units,TimePs,Months,years] = 0.0
  
  
  # *
  # * Modify UnOR of a few coal units in AB to account for 
  # * within-year retirement (Sundance 2) or mothballing 
  # * (Sundance 3-5). JSLandry; August 23, 2019 
  # *
  # * Sundance 2
  # *
  Selectedunit = findall(UnCode .== "AB00002201602")
  @. UnOR[Selectedunit,TimePs,Months,Yr(2018)] = 0.525
  
  
  # *
  # * Sundance 5
  # *
  Selectedunit = findall(UnCode .== "AB00002201605")
  @. UnOR[Selectedunit,TimePs,Months,Yr(2018)] = 0.0
  years = collect(Yr(2019):Yr(2020))
  @. UnOR[Selectedunit,TimePs,Months,years] = 1.0
  
  @. UnOR[Selectedunit,TimePs,Months,Yr(2021)] = 0.8417
  
  unit1 = findall(UnArea .== "AB")
  unit2 = union(findall(UnPlant .== "OGCC"),findall(UnPlant .== "OGCT"))
  unit3 = findall(UnMustRun .== 0.0)
  unit4 = findall(UnCogen .== 0.0)
  units = intersect(unit1,unit2, unit3, unit4)
  years = (Yr(2010):Final)
  @. UnOR[units,TimePs,Months,years] = 0.0
  
  # *
  # * Enmax Shepard Project (AB06100000120)and Swan Hills CCS (AB0610130_CCS)
  # * come online mid-year 2015
  # * 
  Selectedunit = findall(UnCode .== "AB06100000120")
  @. UnMustRun[Selectedunit] = 1.0
  
  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGInput/UnMustRun",UnMustRun)
  
  Selectedunit = findall(UnCode .== "AB_BonnyBrook")
  if size(Selectedunit, 1) > 0
    @. UnBonnyBrook[Years] = UnPoTRExo[Selectedunit[1], Years]
    Selectedunit = findall(UnCode .== "AB_New_CC")
    @. UnPoTRExo[Selectedunit[1], Years] = UnBonnyBrook[Years]
  end
  
  WriteDisk(db,"EGInput/UnPoTRExo",UnPoTRExo)
  
end

function CalibrationControl(db)
  @info "AdjustElectricity_AB.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
