#
#  Electric_CER_Exogenous_PCFMax.jl 
#

using EnergyModel

module Electric_CER_Exogenous_PCFMax

import ...EnergyModel: ReadDisk,WriteDisk,Select,Zero
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db,"MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Avaliability Factor (MWh/MWh)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnLimited::VariableArray{2} = ReadDisk(db, "EGInput/UnLimited") #[Unit,Year]  Limited Energy Units Switch (Switch) (1=Limited Energy Unit)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPCFMax::VariableArray{2} = ReadDisk(db,"EGInput/UnPCFMax") #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type

  #
  # Scratch Variables
  #
  AnnualEnergy::VariableArray{2} = zeros(Float32,length(Unit),length(Year)) # [Year] Change in Policy Variable
  MonthEnergy::VariableArray{3} = zeros(Float32,length(Unit),length(Month),length(Year)) # [Year] Change in Policy Variable
  SummerFraction::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Year] Change in Policy Variable
end

function GetUnitSets(data,unit)
  (; Area) = data
  (; UnArea) = data
  if UnArea[unit] != "Null"
    area = Select(Area,UnArea[unit])
  else
    area = 1
  end
  return area
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,Areas,GenCo,Month,Months,Plant,Plants,Power,Powers,Units,Years) = data
  (; HoursPerMonth,UnArea,UnCogen,UnEAF,UnLimited,UnNation,UnPCFMax,UnPlant) = data
  (; AnnualEnergy,MonthEnergy,SummerFraction) = data
  
  #
  # Apply values to Units
  #
  Summer = Select(Month,"Summer")
  Winter = Select(Month,"Winter")
  for area in Areas, year in Years
    SummerFraction[area,year] = HoursPerMonth[Summer]/
      sum(HoursPerMonth[month] for month in Months)
  end
  NS = Select(Area,"NS")
  for year in Years
    SummerFraction[NS,year] = 0.250
  end

  years = collect(Yr(2035):Final)
  for year in years
    units = findall(UnLimited[Units,year] .== 1.0)
    for unit in units
      area = GetUnitSets(data,unit)
      AnnualEnergy[unit,year] = UnPCFMax[unit,year]*8760
      MonthEnergy[unit,Summer,year] = AnnualEnergy[unit,year]*SummerFraction[area,year]
      MonthEnergy[unit,Winter,year] = AnnualEnergy[unit,year]*(1-SummerFraction[area,year])
      for month in Months
        UnEAF[unit,month,year] = MonthEnergy[unit,month,year]/HoursPerMonth[month]
      end
    end
  end
  
  WriteDisk(db,"EGInput/UnEAF",UnEAF)

end

function PolicyControl(db)
  @info "Electric_CER_Exogenous_PCFMax.jl - PolicyControl"

  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
