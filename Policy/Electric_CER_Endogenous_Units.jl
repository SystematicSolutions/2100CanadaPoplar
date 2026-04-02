#
#  Electric_CER_Endogenous_Units.jl 
#

using EnergyModel

module Electric_CER_Endogenous_Units

import ...EnergyModel: ReadDisk,WriteDisk,Select,Zero
import ...EnergyModel: HisTime,ITime,MaxTime,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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

  CD::VariableArray{2} = ReadDisk(db,"EGInput/CD") # [Plant,Year] Construction Delay (YEARS)
  EAF::VariableArray{4} = ReadDisk(db,"EGInput/EAF") # [Plant,Area,Month,Year] Energy Availability Factor (MWh/MWh)
  DesHr::VariableArray{4} = ReadDisk(db,"EGInput/DesHr") # [Plant,Power,Area,Year] Design Hours (Hours)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnEAF::VariableArray{3} = ReadDisk(db,"EGInput/UnEAF") # [Unit,Month,Year] Energy Avaliability Factor (MWh/MWh)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnLimited::VariableArray{2} = ReadDisk(db,"EGInput/UnLimited") #[Unit,Year]  Limited Energy Units Switch (Switch) (1=Limited Energy Unit)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPCFMax::VariableArray{2} = ReadDisk(db,"EGInput/UnPCFMax") #[Unit,Year]  Unit Capacity Factor (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnPSoMaxGridFraction::VariableArray{2} = ReadDisk(db,"EGInput/UnPSoMaxGridFraction") # [Unit,Year] Maxiumum Fraction Sold to Grid
  UnUFOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUFOMC") # [Unit,Year] Fixed O&M Costs ($/Kw/Yr)
  UnUOMC::VariableArray{2} = ReadDisk(db,"EGInput/UnUOMC") # [Unit,Year] Variable O&M Costs (Real $/MWH)
  UnSource::VariableArray{1} = ReadDisk(db,"EGInput/UnSource") # [Unit] Source Flag
  xUnGCCI::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCI") # [Unit,Year] Generating Capacity Initiated (MW) 
  xUnGCCC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/KW)
  xUnGCCR::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCR") # [Unit,Year] Exogenous Generating Capacity Completion Rate (MW)

  # Scratch Variables
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
  (; DesHr,EAF,HoursPerMonth,UnArea,UnCogen,UnEAF,UnLimited,UnNation,UnSource) = data
  (; UnPCFMax,UnPSoMaxGridFraction,UnPlant) = data
  (; AnnualEnergy,MonthEnergy,SummerFraction) = data
  
  # 
  # ***********************
  # 
  # Plant types with capacity factor constraints from Victor - Jeff Amlin 11/30/23
  # 

  years = collect(Yr(2035):Final)
  
  unit0 = findall(UnSource[Units] .== 1)
  unit1 = findall(UnNation[Units] .== "CN")
  unit2 = findall(UnCogen[Units] .== 0)
  unit3 = findall(UnPlant[Units] .== "OGCT")
  unit4 = findall(UnPlant[Units] .== "OGCC")
  unit5 = findall(UnPlant[Units] .== "SmallOGCC")
  unit6 = findall(UnPlant[Units] .== "NGCCS")
  unit7 = findall(UnPlant[Units] .== "OGSteam")
  unit8 = findall(UnPlant[Units] .== "CoalCCS")
  unit9 = findall(UnPlant[Units] .== "OtherGeneration")
  unit10 = findall(UnPlant[Units] .== "Biomass")
  unit11 = findall(UnPlant[Units] .== "BiomassCCS")
  unit12 = findall(UnPlant[Units] .== "Biogas")
  unit13 = findall(UnPlant[Units] .== "Waste")

  units = intersect(union(unit3,unit4,unit5,unit6,unit7,unit8,unit9,unit10,unit11,unit12,unit13),unit1,unit2,unit0)
  for unit in units, year in years
      UnLimited[unit,year] = 1.0
  end
  WriteDisk(db,"EGInput/UnLimited",UnLimited)

  # 
  # ***********************
  #       
  # Source: https://007gc.sharepoint.com/:x:/r/sites/msteams_908fa5/Shared%20Documents/Policy%20Support%20Work/Clean_Electricity_Standard/Modelling/CG2/PCFMax%20(Rob)/CER_PCFMax_Calculations_RST_11July2024.xlsx?d=w00f420d4cb504c199aae63af7e0a23ad&csf=1&web=1&e=o0XxB3
  #         from SouissiM - 18/07/2024
  # Values below assume a performance standard of 65 pre-2050 and 42 in 2050 t/GWh and a CCS capture rate of 95%. Edited by SouissiM on 18/07/2024 for CER CGII modelling work.
  # 
  
  areas = Select(Area,["ON","QC","BC","AB","MB","SK","NB","NS","NL","PE"])

  years = collect(Yr(2035):Yr(2049))
  plant = Select(Plant,"OtherGeneration")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.09
  end
  plant = Select(Plant,"Coal")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.06
  end
  plant = Select(Plant,"CoalCCS")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 1
  end
  plant = Select(Plant,"OGCC")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.17
  end
  plant = Select(Plant,"OGCT")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.11
  end
  plant = Select(Plant,"OGSteam")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.11
  end
  plant = Select(Plant,"NGCCS")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 1
  end  
  plant = Select(Plant,"SmallOGCC")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.17
  end  
  plant = Select(Plant,"Waste")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 1
  end
  
  years = Yr(2050)  
  plant = Select(Plant,"OtherGeneration")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.06
  end
  plant = Select(Plant,"Coal")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.04
  end
  plant = Select(Plant,"CoalCCS")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.76
  end
  plant = Select(Plant,"OGCC")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.11
  end
  plant = Select(Plant,"OGCT")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.07
  end
  plant = Select(Plant,"OGSteam")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.07
  end
  plant = Select(Plant,"NGCCS")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 1
  end  
  plant = Select(Plant,"SmallOGCC")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 0.11
  end  
  plant = Select(Plant,"Waste")
  for year in years, month in Months, area in areas
    EAF[plant,area,month,year] = 1
  end  

  WriteDisk(db,"EGInput/EAF",EAF)
  
  #
  # Apply values to Units
  # 
  for unit in Units, year in Years
    UnPCFMax[unit,year] = 1
  end

  # 
  # Assume GHG-emitting cogeneration (except NGCCS) no longer sells
  # into the grid post-2035 - RST 24May2025
  # 
  unit0 = findall(UnSource[Units] .== 1)
  unit1 = findall(UnCogen[Units] .== 1)
  unit2 = findall(UnArea[Units] .== "AB")
  unit3 = findall(UnArea[Units] .== "BC")
  unit4 = findall(UnArea[Units] .== "MB")
  unit5 = findall(UnArea[Units] .== "NB")
  unit6 = findall(UnArea[Units] .== "NL")
  unit7 = findall(UnArea[Units] .== "NS")
  unit8 = findall(UnArea[Units] .== "ON")
  unit9 = findall(UnArea[Units] .== "PE")
  unit10 = findall(UnArea[Units] .== "QC")
  unit11 = findall(UnArea[Units] .== "SK")

  units = intersect(union(unit2,unit3,unit4,unit5,unit6,unit7,unit8,unit9,unit10,unit11),unit1,unit0)
  years = collect(Yr(2035):Yr(2050))
  for unit in units
    if  (UnPlant[unit] == "OtherGeneration") || (UnPlant[unit] == "Coal") ||
        (UnPlant[unit] == "CoalCCS")         || (UnPlant[unit] == "OGCC") || 
        (UnPlant[unit] == "OGCT")            || (UnPlant[unit] == "OGSteam") || 
        (UnPlant[unit] == "SmallOGCC")
      for year in years
        UnPSoMaxGridFraction[unit,year] = 0
      end
    end
  end
  WriteDisk(db,"EGInput/UnPSoMaxGridFraction",UnPSoMaxGridFraction)

  unit0 = findall(UnSource[Units] .== 1)
  unit1 = findall(UnCogen[Units] .== 0)
  unit2 = findall(UnArea[Units] .== "AB")
  unit3 = findall(UnArea[Units] .== "BC")
  unit4 = findall(UnArea[Units] .== "MB")
  unit5 = findall(UnArea[Units] .== "NB")
  unit6 = findall(UnArea[Units] .== "NL")
  unit7 = findall(UnArea[Units] .== "NS")
  unit8 = findall(UnArea[Units] .== "ON")
  unit9 = findall(UnArea[Units] .== "PE")
  unit10 = findall(UnArea[Units] .== "QC")
  unit11 = findall(UnArea[Units] .== "SK")

  units = intersect(union(unit2,unit3,unit4,unit5,unit6,unit7,unit8,unit9,unit10,unit11),unit1,unit0)
  for unit in units
    if UnPlant[unit] == "OtherGeneration"
      years = collect(Yr(2035):Yr(2049))
      for year in years
        UnPCFMax[unit,year] = 0.09
      end
      years = Yr(2050)
      for year in years
        UnPCFMax[unit,year] = 0.06
      end
    end
    
    if UnPlant[unit] == "Coal"
      years = collect(Yr(2035):Yr(2049))
      for year in years
        UnPCFMax[unit,year] = 0.06
      end
      years = Yr(2050)
      for year in years
        UnPCFMax[unit,year] = 0.04
      end
    end

    if UnPlant[unit] == "CoalCCS"
      years = collect(Yr(2035):Yr(2049))
      for year in years
        UnPCFMax[unit,year] = 0.06
      end
      years = Yr(2050)
      for year in years
        UnPCFMax[unit,year] = 0.04
      end
    end

    if UnPlant[unit] == "OGCC"
      years = collect(Yr(2035):Yr(2049))
      for year in years
        UnPCFMax[unit,year] = 0.17
      end
      years = Yr(2050)
      for year in years
        UnPCFMax[unit,year] = 0.11
      end
    end

    if UnPlant[unit] == "OGCT"
      years = collect(Yr(2035):Yr(2049))
      for year in years
        UnPCFMax[unit,year] = 0.11
      end
      years = Yr(2050)
      for year in years
        UnPCFMax[unit,year] = 0.07
      end
    end

    if UnPlant[unit] == "OGSteam"
      years = collect(Yr(2035):Yr(2049))
      for year in years
        UnPCFMax[unit,year] = 0.11
      end
      years = Yr(2050)
      for year in years
        UnPCFMax[unit,year] = 0.07
      end
    end

    if UnPlant[unit] == "SmallOGCC"
      years = collect(Yr(2035):Yr(2049))
      for year in years
        UnPCFMax[unit,year] = 0.17
      end
      years = Yr(2050)
      for year in years
        UnPCFMax[unit,year] = 0.11
      end
    end
  end

  summer = Select(Month,"Summer")
  winter = Select(Month,"Winter")
  for area in Areas, year in Years
    SummerFraction[area,year] = HoursPerMonth[summer]/sum(HoursPerMonth[month] for month in Months)
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
      MonthEnergy[unit,summer,year] = AnnualEnergy[unit,year]*SummerFraction[area,year]
      MonthEnergy[unit,winter,year] = AnnualEnergy[unit,year]*(1-SummerFraction[area,year])
      for month in Months
        UnEAF[unit,month,year] = MonthEnergy[unit,month,year]/HoursPerMonth[month]
      end
    end
  end
  
  WriteDisk(db,"EGInput/UnEAF",UnEAF)
  WriteDisk(db,"EGInput/UnPCFMax",UnPCFMax)
end

function PolicyControl(db)
  @info "Electric_CER_Endogenous_Units.jl - PolicyControl"

  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
