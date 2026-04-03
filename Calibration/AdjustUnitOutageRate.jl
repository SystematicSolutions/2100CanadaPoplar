#
# AdjustUnitOutageRate.jl
#
# Adjusted almost all year pointers to be Last/Future instead of 2012/2013, 
# with the exception of the US coal unit changes that should be revisited. 
# - Hilary 15.03.04
#
using EnergyModel

module AdjustUnitOutageRate

import ...EnergyModel: ReadDisk,WriteDisk,Select
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnCurtailedSwitch::VariableArray{2} = ReadDisk(db,"EGInput/UnCurtailedSwitch") # [Unit,Year] Unit Curtailment Swtich (1=Curtail)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOOR::VariableArray{2} = ReadDisk(db,"EGCalDB/UnOOR") # [Unit,Year] Operational Outage Rate (MW/MW)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
end


function ECalibration(db)
  data = EControl(; db)
  (;UnArea,UnCode,UnCogen,UnCurtailedSwitch,Units,UnNode,UnNation,UnOOR,UnOR) = data
  (;UnPlant) = data

  # 
  # Default Operational Outage Rate is zero.
  #
  @. UnOOR[Units,Future:Final] = 0

  #
  # Canada Units
  #
  # For Peak Hydro use last historical value - Jeff Amlin 1/25/21
  #
  cn_units = findall(UnNation .== "CN")
  unit2 = findall(UnPlant .== "PeakHydro")
  units = intersect(cn_units,unit2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # Base Load Hydro Plants use last historical value
  # 
  unit2 = findall(UnPlant .== "BaseHydro")
  units = intersect(cn_units,unit2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # Centrale hydroélectrique Rivière Magpie (QC06100000050) and
  # Centrale hydroélectrique de la Chute à T (QC06100000090) have
  # no historical generation, but we allow generation in future.
  # 
  units = findall(x -> x == "QC06100000050" || x == "QC06100000090", UnCode)
  @. UnOOR[units,Future:Final] = 0

  # 
  # Curtailed Units
  # 
  unit1 = findall(UnCurtailedSwitch .== 1)
  unit2 =findall(UnArea .== "ON")
  units = intersect(unit1,unit2)
  UnOOR[units,Yr(2019)] = UnOOR[units,Yr(2019)-1]*1.00
  for year in Yr(2020):Final
    UnOOR[units,year] = UnOOR[units,year-1]*0.00
  end

  # 
  # ON Coal Plants
  # 
  unit1 = findall(UnArea .== "ON")
  unit2 = findall(UnPlant .== "Coal")
  units = intersect(unit1,unit2)
  @. UnOOR[units,Future:Final] = 0.85

  # 
  # ON Wind Plants
  # 
  # ON existing wind plants have some reason lowered their capacity factors. Patching to adjust before a long term solution can be found.
  # VKeller 30 Aug 2023
  # 
  unit1 = findall(UnArea .== "ON")
  unit2 = findall(UnPlant .== "OnshoreWind")
  units = intersect(unit1,unit2)
  @. UnOR[units,TimePs,Months,Future:Final] = 0.66
  @. UnOOR[units,Future:Final] = 0.0

  # 
  # NS Coal Plants
  # 
  cn_units = findall(UnArea .== "NS")
  unit2 = findall(UnPlant .== "Coal")
  units = intersect(cn_units,unit2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # SK Coal Plants
  # 
  unit1 = findall(UnArea .== "SK")
  unit2 = findall(UnPlant .== "Coal")
  units = intersect(unit1,unit2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # SK Coal Plant (Shand - SK00015301501)
  # 
  unit = findall(UnCode .== "SK00015301501")
  @. UnOOR[unit,Future:Final] = 0.00

  # 
  # AB Coal Plants
  # 
  unit1 = findall(UnArea .== "AB")
  unit2 = findall(UnPlant .== "Coal")
  units = intersect(unit1,unit2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # Keephills 3 (AB_New_26)
  # 
  unit = findall(UnCode .== "AB_New_26")
  @. UnOOR[unit,Future:Final] = 0.00

  # Enmax Shepard Project (AB06100000120)and Swan Hills CCS (AB0610130_CCS)
  # come online mid-year 2015
  # If needed, this should be to vUnOR before the calibration - Jeff Amlin 09/23/21
  
  # Select Unit*
  # Select Unit If (UnCode eq "AB06100000120") or (UnCode eq "AB0610130_CCS")
  # Do If (UnCode eq "AB06100000120") or (UnCode eq "AB0610130_CCS")
  #  Select Year(2015)
  #  UnOOR=0.50
  #  Select Year(Future-Final)
  # End Do If
  # Select Unit*
  
  # HR Milner Expansion (AB00029600702) comes on-line mid-year 2018
  # If needed, this should be to vUnOR before the calibration - Jeff Amlin 09/23/21
  
  # Select Unit*
  # Select Unit If (UnCode eq "AB00029600702")
  # Do If (UnCode eq "AB00029600702") 
  #  Select Year(2018)
  #  UnOOR=0.50  
  #  Select Year(Future-Final)
  # End Do If
  # Select Unit*

  #
  # Patch - this section is for endogenous units model allignemnt with NextGrid for CER CGII - Victor Keller Jan 11 2024
  # Wind
  unit = findall(UnCode .== "ON_Endo060120")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.66
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "AB_Endo070420")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.56
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "BC_Endo080320")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.65
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "MB_Endo010520")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.62
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NB_Endo050720")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.61
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NL_Endo030920")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.64
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NL_Endo100920")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.64
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NS_Endo090820")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.60
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "PE_Endo111020")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.63
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "QC_Endo040220")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.63
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "SK_Endo020620")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.64
  @. UnOOR[unit,Future:Final] = 0.0

  #
  # Patch - this section is for endogenous units model allignemnt with NextGrid for CER CGII - Victor Keller Jan 11 2024
  # Solar PV
  unit = findall(UnCode .== "ON_Endo060122")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.81
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "AB_Endo070422")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.80
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "BC_Endo080322")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.82
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "MB_Endo010522")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.8
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NB_Endo050722")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.86
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NL_Endo030922")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.84
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NL_Endo100922")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.84
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "NS_Endo090822")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.82
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "PE_Endo111022")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.82
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "QC_Endo040222")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.81
  @. UnOOR[unit,Future:Final] = 0.0

  unit = findall(UnCode .== "SK_Endo020622")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.80
  @. UnOOR[unit,Future:Final] = 0.0

  # 
  # Patch - this should be done in the input file to vUnOR - Jeff Amlin 09/23/21
  # 
  unit1 = findall(UnNode .== "NL")
  unit2 = findall(UnPlant .== "OGCT")
  unit3 = findall(UnCogen .== 0)
  units = intersect(unit1,unit2,unit3)
  if units != []
    @. UnOR[units,TimePs,Months,Future:Final] = 0.05
  end
  # 
  # AB OGCC Plants
  # 
  unit1 = findall(UnArea .== "AB")
  unit2 = findall(UnPlant .== "OGCC")
  units = intersect(unit1,unit2)
  @. UnOOR[units,Future] = -0.10

  #
  # Patch NU_Meliad_LFO to 0.50 from Jeff - Ian 04/14/25
  #
  unit = findall(UnCode .== "NU_Meliad_LFO")
  @. UnOR[unit,TimePs,Months,Future:Final] = 0.50

  #*
  #************************
  #*
  #* Revise Burrard outage rate (moved from ElectricTransmission.txt). R.Levesque 09/11/24
  #*
  #* Burrard
  #*
  units = findall(x -> x == "BC00002504401" || x == "BC00002504402" ||
                       x == "BC00002504403" || x == "BC00002504404" ||
                       x == "BC00002504405" || x == "BC00002504406", UnCode)
  if units != []
    @. UnOR[units,TimePs,Months,Future:Final] = 0.10
  end
  # 
  # US Plants
  # 
  # Last historical value
  # 
  us_units = findall(UnNation .== "US")
  @. UnOOR[us_units,Future:Final] = UnOOR[us_units,Last]
  # 
  unit2 = findall(UnPlant .== "OGCT")
  units = intersect(us_units,unit2)
  @. UnOOR[units,Future:Final] = 0.005
  # 
  unit2 = findall(UnPlant .== "PeakHydro")
  units = intersect(us_units,unit2)
  @. UnOOR[units,Future:Final] = 0.050
  # 
  unit2 = findall(UnPlant .== "Nuclear")
  units = intersect(us_units,unit2)
  for unit in units
    @. UnOOR[unit,Future:Final] = min(UnOOR[unit,Yr(2019)],UnOOR[unit,Yr(2020)])
  end
  # 
  unit2 = findall(UnPlant .== "OGCC")
  units = intersect(us_units,unit2)
  @. UnOOR[units,Future:Final] = 0.005
  @. UnOOR[units,Yr(2021)] = 0.005-0.200
  @. UnOOR[units,Yr(2022)] = 0.005-0.200
  @. UnOOR[units,Yr(2023)] = 0.005-0.200
  @. UnOOR[units,Yr(2024)] = 0.005-0.120

  # 
  # Mexico Plants
  # 
  # Last historical value
  # 
  mx_units = findall(UnNation .== "MX")
  @. UnOOR[mx_units,Future:Final] = UnOOR[mx_units,Last]
  # 
  unit2 = findall(x -> x == "OGCT" || x == "OGCC", UnPlant)
  units = intersect(mx_units,unit2)
  @. UnOOR[units,Future:Final] = 0.005
  # 
  unit2 = findall(UnPlant .== "Coal")
  units = intersect(mx_units,unit2)
  for year in Future:Final
    @. UnOOR[units,year] = UnOOR[units,year-1]*0.80
  end

  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGCalDB/UnOOR",UnOOR)
  
end

function CalibrationControl(db)
  @info "AdjustUnitOutageRate.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
