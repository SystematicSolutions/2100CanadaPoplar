#
# PavleyPhaseI_CA.jl - EISA passenger vehicle efficiency (Pavley Phase I) 
# standards for California and all of Canada.  The non-California US states
# do not need this policy since they are calibrated to the AEO 2011 which
# contains this policy.  Jeff Amlin 7/5/11
#
using EnergyModel

module PavleyPhaseI_CA

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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # [Enduse,Tech,EC,Area,Year] Capital Cost Maximum Multiplier  ($/$) 
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu) 
  xDEMM::VariableArray{5} = ReadDisk(db,"$Input/xDEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier  (Btu/Btu)
  xXDEE::VariableArray{5} = ReadDisk(db,"$Input/xXDEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency w/ Standard (Btu/Btu) 

  # Scratch Variables
  CChange::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Adjustment for Vehicle Capital Cost ($/$)
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Area,EC,Enduse,Tech,Techs) = data
  (;DCMM,DEM,DEStd,xDEMM,xXDEE) = data
  (;CChange) = data

  #*
  #* Pavley I - Small and Large Cars
  #* Revised based on EPRI report 3002000298 - Jeff Amlin 2/23/16
  #* Revised again to match 35.5 Fleet Ave Lab Eff - Jeff Amlin 3/12/16
  #*
  area = Select(Area,"CA")
  ec = Select(EC,"Passenger")
  enduse = Select(Enduse,"Carriage")

  #*
  #* Light Duty Vehicles
  #*
  techs = Select(Tech,(from = "LDVGasoline", to = "LDVHybrid"))
  for tech in techs
    DEStd[enduse,tech,ec,area,Yr(2016)] = xXDEE[enduse,tech,ec,area,Yr(2009)] * 1.244 * 1.206
    DEStd[enduse,tech,ec,area,Yr(2009)] = max(DEStd[enduse,tech,ec,area,Yr(2009)], xXDEE[enduse,tech,ec,area,Yr(2009)])
    
    years = collect(Yr(2010):Yr(2015))
    for year in years 
      DEStd[enduse,tech,ec,area,year] = DEStd[enduse,tech,ec,area,year-1] + 
                                        (DEStd[enduse,tech,ec,area,Yr(2016)] - DEStd[enduse,tech,ec,area,Yr(2009)]) /
                                        (2016-2009)
    end
    years = collect(Yr(2017):Final)
    for year in years 
      DEStd[enduse,tech,ec,area,year] = DEStd[enduse,tech,ec,area,Yr(2016)] 
    end
  end

  #*
  #* Light Duty Trucks
  #*
  techs = Select(Tech,(from = "LDTGasoline", to = "LDTHybrid"))
  for tech in techs
    DEStd[enduse,tech,ec,area,Yr(2016)] = xXDEE[enduse,tech,ec,area,Yr(2009)] * 1.365 * 1.206
    DEStd[enduse,tech,ec,area,Yr(2009)] = max(DEStd[enduse,tech,ec,area,Yr(2009)], xXDEE[enduse,tech,ec,area,Yr(2009)])
    
    years = collect(Yr(2010):Yr(2015))
    for year in years 
      DEStd[enduse,tech,ec,area,year] = DEStd[enduse,tech,ec,area,year-1] + 
                                        (DEStd[enduse,tech,ec,area,Yr(2016)] - DEStd[enduse,tech,ec,area,Yr(2009)]) /
                                        (2016-2009)
    end
    years = collect(Yr(2017):Final)
    for year in years 
      DEStd[enduse,tech,ec,area,year] = DEStd[enduse,tech,ec,area,Yr(2016)] 
    end
  end

  #*
  #* Constrain DEStd to be less than maximum efficiency (DEM*DEMM)
  #*
  years = collect(Yr(2010):Final)
  for tech in Techs, year in years 
    DEStd[enduse,tech,ec,area,year] = min(DEStd[enduse,tech,ec,area,year], 
                                          DEM[enduse,tech,ec,area] * xDEMM[enduse,tech,ec,area,year] * 0.98)
  end

  WriteDisk(db,"$Input/DEStd",DEStd)
  
  #*
  #* Adjust Cafe costs down to match estimates.
  #*
  techs = Select(Tech,(from = "LDVGasoline", to = "LDVFuelCell"))
  for tech in techs
    CChange[tech,Yr(2009)]=0.020
    CChange[tech,Yr(2010)]=0.005
    CChange[tech,Yr(2011)]=0.000
    CChange[tech,Yr(2012)]=0.000
    CChange[tech,Yr(2013)]=0.005
    CChange[tech,Yr(2014)]=0.008
    CChange[tech,Yr(2015)]=0.010
    CChange[tech,Yr(2016)]=0.010
    CChange[tech,Yr(2017)]=0.010
    CChange[tech,Yr(2018)]=0.010
    CChange[tech,Yr(2019)]=0.010
    CChange[tech,Yr(2020)]=0.010
  end

  techs = Select(Tech,(from = "LDTGasoline", to = "LDTFuelCell"))
  for tech in techs
    CChange[tech,Yr(2009)]=0.010
    CChange[tech,Yr(2010)]=0.008
    CChange[tech,Yr(2011)]=0.010
    CChange[tech,Yr(2012)]=0.008
    CChange[tech,Yr(2013)]=0.020
    CChange[tech,Yr(2014)]=0.015
    CChange[tech,Yr(2015)]=0.020
    CChange[tech,Yr(2016)]=0.025
    CChange[tech,Yr(2017)]=0.025
    CChange[tech,Yr(2018)]=0.025
    CChange[tech,Yr(2019)]=0.025
    CChange[tech,Yr(2020)]=0.025
  end

  years = collect(Yr(2021):Final)
  for tech in Techs, year in years
    CChange[tech,year] = CChange[tech,Yr(2020)]
  end

  techs = Select(Tech,(from = "LDVGasoline", to = "LDTFuelCell"))
  years = collect(Yr(2009):Final)
  for tech in techs, year in years
    DCMM[enduse,tech,ec,area,year] = DCMM[enduse,tech,ec,area,year] * (1 + CChange[tech,year])
  end
  
  WriteDisk(db,"$Input/DCMM",DCMM)

end

function CalibrationControl(db)
  @info "PavleyPhaseI_CA.jl - CalibrationControl"

  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
