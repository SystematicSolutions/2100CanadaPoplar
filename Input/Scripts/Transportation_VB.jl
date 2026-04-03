#
# Transportation_VB.jl - Apply CN Efficiencies from VBInput
#
# Ian 12/15/2016
#
using EnergyModel

module Transportation_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  vArea::SetArray = ReadDisk(db,"MainDB/vAreaKey")
  vAreaDS::SetArray = ReadDisk(db,"MainDB/vAreaDS")
  vAreas::Vector{Int} = collect(Select(vArea))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  # CurTime::VariableArray{1} = ReadDisk(db,"$Input/CurTime") # [tv] Year for initializing Efficiency Capital Costs Curve (Year)
  CurTime::Float32 = ReadDisk(db,"$Input/CurTime")[1] # [tv] Year for initializing Efficiency Capital Costs Curve (Year)
  DAct::VariableArray{5} = ReadDisk(db,"$Input/DAct") # [Enduse,Tech,EC,Area,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$)
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DPConv::VariableArray{5} = ReadDisk(db,"$Input/DPConv") # [Enduse,Tech,EC,Area,Year] Device Process Conversion (Vehicle Mile/Passenger Mile)
  vAreaMap::VariableArray{2} = ReadDisk(db,"MainDB/vAreaMap") # [Area,vArea] Map between Area and and VBInput Areas
  vTrDAct::VariableArray{4} = ReadDisk(db,"VBInput/vTrDAct") # [Tech,EC,vArea,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  vTrDCC::VariableArray{4} = ReadDisk(db,"VBInput/vTrDCC") # [Tech,EC,vArea,Year] Device Capital Cost (Real $/mmBtu/Yr)
  vTrDCMM::VariableArray{4} = ReadDisk(db,"VBInput/vTrDCMM") # [Tech,EC,vArea,Year] Capital Cost Maximum Multiplier  (1=2008)
  vTrDEE::VariableArray{4} = ReadDisk(db,"VBInput/vTrDEE") # [Tech,EC,vArea,Year] Device Efficiency (Btu/Btu)
  vTrDEM::VariableArray{4} = ReadDisk(db,"VBInput/vTrDEM") # [Tech,EC,vArea,Year] Maximum Device Efficiency (miles/mmBtu)
  vTrDPConv::VariableArray{4} = ReadDisk(db,"VBInput/vTrDPConv") # [Tech,EC,vArea,Year] Device Process Conversion (Vehicle Mile/Passenger Mile)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost (Real $/mmBtu/Yr)
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xXDEE::VariableArray{5} = ReadDisk(db,"$Input/xXDEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency w/ Standard (Miles/mmBtu)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
end

function TCalibration(db)
  data = TControl(; db)
  (;Input,Area,Areas,EC,ECs,Enduses,Nation) = data
  (;Tech,Techs,Years,vAreas) = data
  (;ANMap,CurTime,DAct,DCMM,DEM,DPConv,vTrDAct,vTrDCC,vTrDCMM,vTrDEE) = data
  (;vTrDEM,vTrDPConv,xDCC,xDEE,xXDEE,xExchangeRate,xInflation,vAreaMap) = data

  #
  # Device curve initialization year is set to 2008 to best match updated data sources
  #
  CurTime = Yr(2008)
  CN = Select(Nation,"CN")
  cn_areas = Select(ANMap[Areas,CN], ==(1))

  # 
  # Device Capital Cost (xDCC)
  # 
  for eu in Enduses, tech in Techs, ec in ECs, area in cn_areas, year in Years
    xDCC[eu,tech,ec,area,year] = -99
    vareas=findall(vAreaMap[area,:] .==1)
    if !isempty(vareas)
      varea=first(vareas)
      if vTrDCC[tech,ec,varea,year] > 0
        xDCC[eu,tech,ec,area,year] = sum(vTrDCC[tech,ec,v,year]*vAreaMap[area,v] for v in vareas)
      end
    end
  end

  # 
  # xDCMM - Default is 1.0 (TData.src)
  # 
  for eu in Enduses, tech in Techs, ec in ECs, area in cn_areas, year in Years
    vareas=findall(vAreaMap[area,:] .==1)
    if !isempty(vareas)
      varea=first(vareas)
      if vTrDCMM[tech,ec,varea,year] > 0
        DCMM[eu,tech,ec,area,year] = sum(vTrDCMM[tech,ec,v,year]*vAreaMap[area,v] for v in vareas)
      end
    end
  end

  # 
  # DEM - Initialize to 0
  # vTrDEM has same value for all Years
  # 
  for eu in Enduses, tech in Techs, ec in ECs, area in cn_areas
    DEM[eu,tech,ec,area] = 0
    vareas=findall(vAreaMap[area,:] .==1)
    if !isempty(vareas)
      varea=first(vareas)
      year=first(Years)
      if vTrDEM[tech,ec,varea,year] > 0
        DEM[eu,tech,ec,area] = sum(vTrDEM[tech,ec,v,year]*vAreaMap[area,v] for v in vareas)
      end
    end
  end

  # 
  # DAct - Initialize to 1
  # Values constant over time - Use 1985 value for all years
  # 
  for eu in Enduses, tech in Techs, ec in ECs, area in cn_areas, year in Years
    DAct[eu,tech,ec,area,year] = 1.0
    vareas=findall(vAreaMap[area,:] .==1)
    if !isempty(vareas)
      varea=first(vareas)
      if vTrDAct[tech,ec,varea,Yr(1985)] > 0
        DAct[eu,tech,ec,area,year] = sum(vTrDAct[tech,ec,v,Yr(1985)]*vAreaMap[area,v] for v in vareas)
      end
    end
  end

  # 
  # DPConv - Initialize to 1
  # 
  for eu in Enduses, tech in Techs, ec in ECs, area in cn_areas, year in Years
    DPConv[eu,tech,ec,area,year] = 1.0
    vareas=findall(vAreaMap[area,:] .==1)
    if !isempty(vareas)
      varea=first(vareas)
      if vTrDPConv[tech,ec,varea,year] > 0
        DPConv[eu,tech,ec,area,year] = sum(vTrDPConv[tech,ec,v,year]*vAreaMap[area,v] for v in vareas)
      end
    end
  end

  # 
  # Device Efficiency w/o Efficiency Standard
  # Initialize to -99
  # 
  # vTrDEE_Default.dat contains default model values for all technologies. These values
  # are based on EIA data. vTrDEE.dat contains specific values from ECCC for CN Areas.
  # Code below assume input vTrDEE variable is vTrDEE_Default.dat data overwriten 
  # by vTrDEE.dat where applicable.
  # 
  # Input is in vehicle miles per mmbtu. Multiply by DAct to convert freight
  # units to tonne-miles
  # 
  for eu in Enduses, tech in Techs, ec in ECs, area in cn_areas, year in Years
    xDEE[eu,tech,ec,area,year] = -99
    xXDEE[eu,tech,ec,area,year] = -99
    vareas=findall(vAreaMap[area,:] .==1)
    if !isempty(vareas)
      varea=first(vareas)
      if vTrDEE[tech,ec,varea,year] > 0
        xXDEE[eu,tech,ec,area,year] = sum(vTrDEE[tech,ec,v,year]*vAreaMap[area,v] for v in vareas) *
                                      DAct[eu,tech,ec,area,year]
      end
    end
  end

  # 
  # Revise FuelCell Efficiency until values in vTrDEE.dat are input
  # or vTrDEE_Default.dat is revised. - Jeff Amlin 09.24.21
  # 
  # From "Hydrogen is less efficient? Part 3: Energy Cost (arcolaenergy.com)"
  # Fuel cells are more efficient than a diesel engine in converting
  # the chemical energy in a fuel to motion at the wheels. For buses
  # and trucks, an FCEV is roughly 30-40% more efficient than a diesel
  # on an energy basis.
  # Source: https://www.arcolaenergy.com/insights/hydrogen-is-inefficient-part-3-energy-cost
  # Source: Robin White email Thursday, September 23, 2021 11:07 AM
  # 
  for eu in Enduses, ec in ECs, area in cn_areas, year in Years
    xXDEE[eu,Select(Tech,"HDV2B3FuelCell"),ec,area,year] = max(xXDEE[eu,Select(Tech,"HDV2B3Gasoline"),ec,area,year]*1.35,-99)
    xXDEE[eu,Select(Tech,"HDV45FuelCell"), ec,area,year] = max(xXDEE[eu,Select(Tech,"HDV45Diesel"),   ec,area,year]*1.35,-99)
    xXDEE[eu,Select(Tech,"HDV67FuelCell"), ec,area,year] = max(xXDEE[eu,Select(Tech,"HDV67Diesel"),   ec,area,year]*1.35,-99)
    xXDEE[eu,Select(Tech,"HDV8FuelCell"),  ec,area,year] = max(xXDEE[eu,Select(Tech,"HDV8Diesel"),    ec,area,year]*1.35,-99)
  end

  # 
  # Data is read in as xXDEE, which is the actual historical efficiency.
  # In technologies driven by efficiency standards (LDVGasoline, etc) this value
  # is later adjusted downwards by 70% to simulate consumer choice levels
  # 
  Passenger = Select(EC,"Passenger")
  techs = Select(Tech,["LDVGasoline","LDVDiesel","LDTGasoline","LDTDiesel"])
  for eu in Enduses, tech in Techs, ec in ECs, area in cn_areas, year in Years
    if xXDEE[eu,tech,ec,area,year] != -99
      xDEE[eu,tech,ec,area,year] = xXDEE[eu,tech,ec,area,year]*0.70
    else
      xDEE[eu,tech,ec,area,year] = xXDEE[eu,tech,ec,area,year]
    end
  end

  # 
  # For other technologies and sectors assume input efficiency is consumer efficiency without standards
  #
  not_techs = ["LDVGasoline","LDVDiesel","LDTGasoline","LDTDiesel"]
  techs = findall(x -> !(x in not_techs), Tech)

  for eu in Enduses, tech in techs, area in cn_areas, year in Years
    xDEE[eu,tech,Passenger,area,year] = xXDEE[eu,tech,Passenger,area,year]
  end

  ecs = Select(EC, !=("Passenger"))
  for eu in Enduses, tech in Techs, ec in ecs, area in cn_areas, year in Years
    xDEE[eu,tech,ec,area,year] = xXDEE[eu,tech,ec,area,year]
  end

  # 
  # US uses ON values
  # 
  not_cn_areas = Select(ANMap[Areas,CN], ==(0))
  ON = Select(Area,"ON")
  for eu in Enduses, tech in Techs, ec in ECs, area in not_cn_areas, year in Years
    xDCC[eu,tech,ec,area,year] = -99
    if xDCC[eu,tech,ec,ON,year] > 0
      xDCC[eu,tech,ec,area,year] = xDCC[eu,tech,ec,ON,year]*xInflation[ON,year]/xExchangeRate[ON,year]*
                                   xExchangeRate[area,year]/xInflation[area,year]
    end
    DCMM[eu,tech,ec,area,year]   = DCMM[eu,tech,ec,ON,year]
    DEM[eu,tech,ec,area]         = DEM[eu,tech,ec,ON]
    DAct[eu,tech,ec,area,year]   = DAct[eu,tech,ec,ON,year]
    DPConv[eu,tech,ec,area,year] = DPConv[eu,tech,ec,ON,year]
    xDEE[eu,tech,ec,area,year]   = xDEE[eu,tech,ec,ON,year]
    xXDEE[eu,tech,ec,area,year]  = xXDEE[eu,tech,ec,ON,year]
  end

  WriteDisk(db,"$Input/CurTime",CurTime)
  WriteDisk(db,"$Input/xDCC",xDCC)
  WriteDisk(db,"$Input/DEM",DEM)
  WriteDisk(db,"$Input/DAct",DAct)
  WriteDisk(db,"$Input/DPConv",DPConv)
  WriteDisk(db,"$Input/xDEE",xDEE)
  WriteDisk(db,"$Input/xXDEE",xXDEE)
  WriteDisk(db,"$Input/DCMM",DCMM)
 
end

function Control(db)
  @info "Transportation_VB.jl - Control"
  TCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
