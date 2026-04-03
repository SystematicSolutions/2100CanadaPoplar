#
# AdjustElectricity_OutageRates.jl
#
# Adjusted almost all year pointers to be Last/Future instead of 2012/2013, 
# with the exception of the US coal unit changes that should be revisited. 
# - Hilary 15.03.04
#
# In the context of the CER modelling we updated UnOR for all plant types.
# NERC Data (collected by ECD) were used for that purpose.
# See: T:\Policy Support Work\Clean_Electricity_Standard\Modelling\For_CG2\Data\Power plant update\UnOR\
#         e2020_nxtgrd_alignment_availability_factor.xlsx
# Some of these UnOR are overwritten during the alignment with historical data,
# therefore they are overwritten again here.
# The values of 'cogen' plants are not modified because it was seen it causes issues (overgeneration from industries)
# The values of 'exogenous' plants are not modified because they are already overwritten in vData (when running the Aligned DB)
# Thomas Dandres March 22, 2024
#
############################################################
#                                                          #
#                       NOTICE                             #
#                                                          #
#  The ENERGY 2100 model is available by contacting        #
#  Systematic Solutions, Inc. (Telephone:937-767-1873).    #
#  The ENERGY 2100 model and all associated software are   #
#  the property of Systematic Solutions, Inc. and cannot   #
#  be distributed to others without the expressed          #
#  permission of Systematic Solutions, Inc. Any modified   #
#  ENERGY 2100-related software must include this notice   #
#  along with a designation stating who made the revision, #
#  the general focus of the revision, and the date of the  #
#  revision.                                               #
#                                                          #
#                                 March 27, 2006           #
#                                                          #
############################################################
#
#    Systematic Solutions, Inc.
#
#        Version: December 2007
#
using EnergyModel

module AdjustElectricity_OutageRates

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
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

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
  UnCurtailedSwitch::VariableArray{2} = ReadDisk(db,"EGInput/UnCurtailedSwitch") # [Unit,Year] Unit Curtailment Swtich (1=Curtail)
  UnGenCo::Array{String} = ReadDisk(db,"EGInput/UnGenCo") # [Unit] Generating Company
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnNode::Array{String} = ReadDisk(db,"EGInput/UnNode") # [Unit] Transmission Node
  UnOOR::VariableArray{2} = ReadDisk(db,"EGCalDB/UnOOR") # [Unit,Year] Operational Outage Rate (MW/MW)
  UnOR::VariableArray{4} = ReadDisk(db,"EGInput/UnOR") # [Unit,TimeP,Month,Year] Outage Rate (MW/MW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnSource::VariableArray{1} = ReadDisk(db,"EGInput/UnSource") # [Unit] Source (1=Endogenous, 0=Exogenous)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Months,TimePs) = data
  (;UnArea,UnCode,UnCogen,UnCurtailedSwitch,Units,UnNode,UnNation,UnOOR,UnOR) = data
  (;UnPlant,UnSource) = data

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
  units2 = findall(UnPlant .== "PeakHydro")
  units = intersect(cn_units,units2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # Base Load Hydro Plants use last historical value
  # 
  units2 = findall(UnPlant .== "BaseHydro")
  units = intersect(cn_units,units2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # Curtailed Units
  # 
  units1 = findall(UnCurtailedSwitch .== 1)
  units2 = findall(UnArea .== "ON")
  units = intersect(units1,units2)
  UnOOR[units,Yr(2019)] = UnOOR[units,Yr(2019)-1]*1.00
  for year in Yr(2020):Final
    UnOOR[units,year] = UnOOR[units,year-1]*0.00
  end

  #
  # Apply NERC values for Canadian power plants (TD March 2024)
  #
  units1 = findall(UnNation .== "CN")
  units2 = findall(UnSource .== 1)
  units3 = findall(UnCogen .== 0)
  units = intersect(units1,units2,units3)
  for unit in units
    #
    # Bioamss, Biomass CCS, Coal, Coal CCS, Waste Plants
    #
    years=collect(Future:Final)
    if (UnPlant[unit] == "Biomass") || (UnPlant[unit] == "BiomassCCS") || (UnPlant[unit] == "Coal") || (UnPlant[unit] == "CoalCCS") || (UnPlant[unit] == "Waste")
      @. UnOR[unit,TimePs,Months,years]=0.177
    end
    #
    # NGCCS
    #
    if (UnPlant[unit] == "NGCCS")
      @. UnOR[unit,TimePs,Months,years]=0.12
    end
    #
    # Nuclear
    #
    if (UnPlant[unit] == "Nuclear")
      @. UnOR[unit,TimePs,Months,years]=0.073
    end
    #
    # SMNR
    #
    if (UnPlant[unit] == "SMNR")
      @. UnOR[unit,TimePs,Months,years]=0.073
    end 
    #
    # OffshoreWind
    #
    if (UnPlant[unit] == "OffshoreWind")
      @. UnOR[unit,TimePs,Months,years]=0.5
    end
    #
    # OGCC
    #
    if (UnPlant[unit] == "OGCC")
      @. UnOR[unit,TimePs,Months,years]=0.12
    end
    #
    # SmallOGCC
    # 
    if (UnPlant[unit] == "SmallOGCC")
      @. UnOR[unit,TimePs,Months,years]=0.12
    end
    #
    # OGCT
    #
    if (UnPlant[unit] == "OGCT")
      @. UnOR[unit,TimePs,Months,years]=0.023
    end
    #
    # OGSteam
    #
    if (UnPlant[unit] == "OGSteam")
      @. UnOR[unit,TimePs,Months,years]=0.198
    end
    #
    # Geothermal
    #
    if (UnPlant[unit] == "Geothermal")
      @. UnOR[unit,TimePs,Months,years]=0.3
    end
    #
    # Battery
    #
    if (UnPlant[unit] == "Battery")
      @. UnOR[unit,TimePs,Months,years]=0.2
    end

    #
    # Wind and Solar (area and time dependent)
    #
    years=collect(Future:Yr(2024))
    # Wind multiregions
    if  (UnArea[unit] == "AB") || (UnArea[unit] == "MB") || (UnArea[unit] == "NT") || (UnArea[unit] == "NU") || (UnArea[unit] == "ON") || (UnArea[unit] == "QC") || (UnArea[unit] == "SK") || (UnArea[unit] == "YT")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.67
      end
    end
    # Wind and Solar BC
    if  (UnArea[unit] == "BC")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.65
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.87
      end
    end
    # Wind Maritimes
    if  (UnArea[unit] == "NL") || (UnArea[unit] == "NS") || (UnArea[unit] == "NB") || (UnArea[unit] == "PE")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.64
      end
    end
    # Solar Multiregions
    if  (UnArea[unit] == "NS") || (UnArea[unit] == "MB") || (UnArea[unit] == "NT") || (UnArea[unit] == "NU") || (UnArea[unit] == "ON") || (UnArea[unit] == "QC") || (UnArea[unit] == "SK") || (UnArea[unit] == "YT") || (UnArea[unit] == "PE")
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.83
      end
    end
    # Solar NB
    if  (UnArea[unit] == "NB")
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.858
      end
    end
    # Solar NL
    if  (UnArea[unit] == "NL")
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.836
      end
    end
    # Solar AB
    if  (UnArea[unit] == "AB")
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.8
      end
    end
  
    years=collect(Yr(2024):Final)
    # Wind and solar BC
    if  (UnArea[unit] == "BC")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.65
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.815
      end
    end
    # Wind and solar AB
    if  (UnArea[unit] == "AB")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.563
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.8
      end
    end
    # Wind and solar SK
    if  (UnArea[unit] == "SK")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.635
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.796
      end
    end
    # Wind and solar MB
    if  (UnArea[unit] == "MB")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.622
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.804
      end
    end
    # Wind and solar ON
    if  (UnArea[unit] == "ON")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.63
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.811
      end
    end
    # Wind and solar QC
    if  (UnArea[unit] == "QC")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.63
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.812
      end
    end
    # Wind and solar NB
    if  (UnArea[unit] == "NB")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.601
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.858
      end
    end
    # Wind and solar NS
    if  (UnArea[unit] == "NS")
      if (UnPlant[unit] == "OnshoreWind") 
        @. UnOR[unit,TimePs,Months,years]=0.601
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.824
      end
    end
    # Wind and solar NL
    if  (UnArea[unit] == "NL")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.634
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.836
      end
    end
    # Wind and solar PE
    if  (UnArea[unit] == "PE")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.632
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.818
      end
    end
    # Wind and solar NT
    if  (UnArea[unit] == "NT") || (UnArea[unit] == "NU") || (UnArea[unit] == "YT")
      if (UnPlant[unit] == "OnshoreWind")
        @. UnOR[unit,TimePs,Months,years]=0.632
      end
      if (UnPlant[unit] == "SolarPV")
        @. UnOR[unit,TimePs,Months,years]=0.8
      end
    end
  end

  # 
  # NS Coal Plants
  # 
  units1 = findall(UnArea .== "NS")
  units2 = findall(UnPlant .== "Coal")
  units = intersect(units1,units2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # SK Coal Plants
  # 
  units1 = findall(UnArea .== "SK")
  units2 = findall(UnPlant .== "Coal")
  units = intersect(units1,units2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # SK Coal Plant (Shand - SK00015301501)
  # 
  unit = findall(UnCode .== "SK00015301501")
  @. UnOOR[unit,Future:Final] = 0.00

  # 
  # AB Coal Plants
  # 
  units1 = findall(UnArea .== "AB")
  units2 = findall(UnPlant .== "Coal")
  units = intersect(units1,units2)
  @. UnOOR[units,Future:Final] = UnOOR[units,Last]

  # 
  # Keephills 3 (AB_New_26)
  # 
  unit = findall(UnCode .== "AB_New_26")
  @. UnOOR[unit,Future:Final] = 0.00

  # 
  # US Plants
  # 
  years = collect(Future:Final)  
  
  #
  # Last historical value
  # 
  units = findall(UnNation .== "US")
  for year in years, unit in units
    UnOOR[unit,year] = UnOOR[unit,Last]
  end
  
  # 
  units1 = findall(UnNation .== "US")
  units2 = findall(UnPlant .== "OGCT")
  units = intersect(units1,units2)
  for year in years, unit in units
    UnOOR[unit,year] = 0.005
  end  

  # 
  units1 = findall(UnNation .== "US")
  units2 = findall(UnPlant .== "PeakHydro")
  units = intersect(units1,units2)
  for year in years, unit in units
    UnOOR[unit,year] = 0.050
  end   

  # 
  units1 = findall(UnNation .== "US")
  units2 = findall(UnPlant .== "Nuclear")
  units = intersect(units1,units2)
  for year in years, unit in units
    UnOOR[unit,year] =  min(UnOOR[unit,Yr(2019)],UnOOR[unit,Yr(2020)])
  end     
  
  # 
  units1 = findall(UnNation .== "US")
  units2 = findall(UnPlant .== "OGCC")
  units = intersect(units1,units2)  
  for unit in units
    years = collect(Future:Final)    
    for year in years
      UnOOR[unit,year] = 0.005
    end
    year = Yr(2021)
    UnOOR[unit,year] = 0.005-0.200
    year = Yr(2022)
    UnOOR[unit,year] = 0.005-0.200   
    year = Yr(2023)
    UnOOR[unit,year] = 0.005-0.200    
    year = Yr(2024)
    UnOOR[unit,year] = 0.005-0.120
  end

  # 
  # Mexico Plants
  # 
  years = collect(Future:Final)
  
  # Last historical value
  # 
  mx_units = findall(UnNation .== "MX")
  @. UnOOR[mx_units,Future:Final] = UnOOR[mx_units,Last]
  # 
  units2 = findall(x -> x == "OGCT" || x == "OGCC", UnPlant)
  units = intersect(mx_units,units2)
  @. UnOOR[units,Future:Final] = 0.005
  # 
  units2 = findall(UnPlant .== "Coal")
  units = intersect(mx_units,units2)
  for year in Future:Final
    @. UnOOR[units,year] = UnOOR[units,year-1]*0.80
  end

  WriteDisk(db,"EGInput/UnOR",UnOR)
  WriteDisk(db,"EGCalDB/UnOOR",UnOOR)
  
end

function CalibrationControl(db)
  @info "AdjustElectricity_OutageRates.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
