#
# Res_BldgStd.jl - Historical building code standards
# Last updated by Alexandre Dumas on 2020-05-19
#
########################
#
# This policy increases the process efficiency standard (PEStd).
# The policy is aimed to reflect provincial actions aimed at increasing
# the energy efficiency of new residential buildings.
#
# It is important to note that provincial measures are expressed as improvements to 
# energy intensity, while the PEStd variable is expressed in terms of energy 
# efficiency. For this reason, the provincial energy intensity improvement targets 
# need to be converted to energy efficiency targets using the following equation:
# deltaEfficiency = 1/(1-deltaIntensity)-1 
# where deltaIntensity is expressed as a positive number.
#
# For background on how the energy efficiency values were developed, see 
# \\ncr.int.ec.gc.ca\shares\e\ECOMOD\Policy Support Work\Bld Codes Analysis\.
# Detailed factors available in "Bld Codes Stringencyv6.xlsx".
#
########################
#
using EnergyModel

module Res_BldgStd

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RCalib
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  # PEEAvg_BC::VariableArray{5} = ReadDisk(db,"$Outpt/PEEAvg_BC") # [Enduse,Tech,EC,Area,Year] Base Case Process Efficiency ($/Btu)
  PEStd::VariableArray{5} = ReadDisk(db,"$Input/PEStd") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard ($/Btu)
  xPEE::VariableArray{5} = ReadDisk(db,"$Input/xPEE") # [Enduse,Tech,EC,Area,Year] Historical Process Efficiency ($/Btu) 

  # Scratch Variables
  EIImprovement::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Energy Intensity Improvement from Baseline Value ($/Btu)/($/Btu)
  EEImprovement::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Energy Efficiency Improvement from Baseline Value ($/Btu)/($/Btu)
  
end

function RCalibration(db)
  data = RCalib(; db)
  (;Area,ECs,Enduse,Nation) = data
  (;Tech,Techs,Year,Years) = data
  (;ANMap,PEE,PEStd,xPEE) = data
  (;EEImprovement,EIImprovement,Input) = data
  
  
  @. EEImprovement = 0
  
  ON = Select(Area,"ON")
  years = collect(Yr(2007):Yr(2011))
  @. EEImprovement[ON, years] = 0.25
  
  years = collect(Yr(2012):Yr(2016))
  @. EEImprovement[ON, years] = 0.40
  
  years = collect(Yr(2017):Yr(2019))
  @. EEImprovement[ON, years] = 0.49
  
  years = collect(Yr(2020):Final)
  @. EEImprovement[ON, years] = 0.49
  
  QC = Select(Area,"QC")
  years = collect(Yr(2013):Final)
  @. EEImprovement[QC, years] = 0.25
  
  BC = Select(Area,"BC")
  years = collect(Yr(2011):Yr(2015))
  @. EEImprovement[BC, years] = 0.417
  
  years = collect(Yr(2016):Yr(2020))
  @. EEImprovement[BC, years] = 0.498
  
  years = collect(Yr(2021):Final)
  @. EEImprovement[BC, years] = 0.504
  
  YT = Select(Area,"YT")
  years = collect(Yr(2013):Final)
  @. EEImprovement[YT, years] = 0.20
  
  NB = Select(Area,"NB")
  years = collect(Yr(2021):Final)
  @. EEImprovement[NB, years] = 0.20
  
  NL = Select(Area,"NL")
  years = collect(Yr(2012):Final)
  @. EEImprovement[NL, years] = 0.20
  
  NS = Select(Area,"NS")
  years = collect(Yr(2015):Final)
  @. EEImprovement[NS, years] = 0.20
  
  areas = Select(Area,["AB","MB"])
  years = collect(Yr(2016):Final)
  @. EEImprovement[areas, years] = 0.20
  
  NT = Select(Area,"NT")
  years = collect(Yr(2017):Final)
  @. EEImprovement[NT, years] = 0.20
  
  SK = Select(Area,"SK")
  years = collect(Yr(2019):Final)
  @. EEImprovement[SK, years] = 0.20
  
  PE = Select(Area,"PE")
  years = collect(Yr(2020):Final)
  @. EEImprovement[PE, years] = 0.20
  
  one = ones(Float32,length(Area),length(Year))
  @. EIImprovement =  (one/ (one - EEImprovement)) - one
  
  Heat = Select(Enduse,"Heat")
  
  years = collect(Yr(2007):Yr(2019))
  for tech in Techs, year in years, ec in ECs
    max_yr2006 = max(PEE[Heat,tech,ec,ON,Yr(2006)], xPEE[Heat,tech,ec,ON,Yr(2006)]) * (1+EIImprovement[ON,year])
    PEStd[Heat,tech,ec,ON,year] = max(PEStd[Heat,tech,ec,ON,year],max_yr2006)
  end
  
  years = collect(Yr(2020):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr2009 = max(PEE[Heat,tech,ec,ON,Yr(2009)], xPEE[Heat,tech,ec,ON,Yr(2009)]) * (1+EIImprovement[ON,year])
    PEStd[Heat,tech,ec,ON,year] = max(PEStd[Heat,tech,ec,ON,year],max_yr2009)
  end
  
  
  years = collect(Yr(2013):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr2012 = max(PEE[Heat,tech,ec,QC,Yr(2012)], xPEE[Heat,tech,ec,QC,Yr(2012)]) * (1+EIImprovement[QC,year])
    PEStd[Heat,tech,ec,QC,year] = max(PEStd[Heat,tech,ec,QC,year],max_yr2012)
  end
  
  years_sum = collect(Yr(2006):Yr(2010))
  years = collect(Yr(2011):Final)
  for tech in Techs, ec in ECs
    PEESum = sum(PEE[Heat,tech,ec,BC,year_sum] for year_sum in years_sum)/5.0
    xPEESum = sum(xPEE[Heat,tech,ec,BC,year_sum] for year_sum in years_sum)/5.0
    for year in years
      PEEAvg_BC = max(PEESum,xPEESum) * (1+EIImprovement[BC,year])
      PEStd[Heat,tech,ec,BC,year] = max(PEStd[Heat,tech,ec,BC,year],PEEAvg_BC)
    end
  end
  
  years = collect(Yr(2013):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr = max(PEE[Heat,tech,ec,YT,Yr(2009)], xPEE[Heat,tech,ec,YT,Yr(2009)]) * (1+EIImprovement[YT,year])
    PEStd[Heat,tech,ec,YT,year] = max(PEStd[Heat,tech,ec,YT,year],max_yr)
  end
  
  years = collect(Yr(2021):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr = max(PEE[Heat,tech,ec,NB,Yr(2009)], xPEE[Heat,tech,ec,NB,Yr(2009)]) * (1+EIImprovement[NB,year])
    PEStd[Heat,tech,ec,NB,year] = max(PEStd[Heat,tech,ec,NB,year],max_yr)
  end
  
  years = collect(Yr(2012):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr = max(PEE[Heat,tech,ec,NL,Yr(2009)], xPEE[Heat,tech,ec,NL,Yr(2009)]) * (1+EIImprovement[NL,year])
    PEStd[Heat,tech,ec,NL,year] = max(PEStd[Heat,tech,ec,NL,year],max_yr)
  end
  
  years = collect(Yr(2015):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr = max(PEE[Heat,tech,ec,NS,Yr(2009)], xPEE[Heat,tech,ec,NS,Yr(2009)]) * (1+EIImprovement[NS,year])
    PEStd[Heat,tech,ec,NS,year] = max(PEStd[Heat,tech,ec,NS,year],max_yr)
  end
  
  
  areas = Select(Area,["AB","MB"])
  years = collect(Yr(2016):Final)
  for tech in Techs, year in years, ec in ECs, area in areas
    max_yr = max(PEE[Heat,tech,ec,area,Yr(2009)], xPEE[Heat,tech,ec,area,Yr(2009)]) * (1+EIImprovement[area,year])
    PEStd[Heat,tech,ec,area,year] = max(PEStd[Heat,tech,ec,area,year],max_yr)
  end
  
  years = collect(Yr(2017):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr = max(PEE[Heat,tech,ec,NT,Yr(2009)], xPEE[Heat,tech,ec,NT,Yr(2009)]) * (1+EIImprovement[NT,year])
    PEStd[Heat,tech,ec,NT,year] = max(PEStd[Heat,tech,ec,NT,year],max_yr)
  end
  
  years = collect(Yr(2019):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr = max(PEE[Heat,tech,ec,SK,Yr(2009)], xPEE[Heat,tech,ec,SK,Yr(2009)]) * (1+EIImprovement[SK,year])
    PEStd[Heat,tech,ec,SK,year] = max(PEStd[Heat,tech,ec,SK,year],max_yr)
  end
  
  years = collect(Yr(2020):Final)
  for tech in Techs, year in years, ec in ECs
    max_yr = max(PEE[Heat,tech,ec,PE,Yr(2009)], xPEE[Heat,tech,ec,PE,Yr(2009)]) * (1+EIImprovement[PE,year])
    PEStd[Heat,tech,ec,PE,year] = max(PEStd[Heat,tech,ec,PE,year],max_yr)
  end
  
  #
  # Until we get more historical data, set the Geothermal, Heat Pump,
  # and Solar building standards equal to Electric
  #
  
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  techs = Select(Tech,["Geothermal","HeatPump","Solar"])
  Electric = Select(Tech,"Electric")
  for year in Years, tech in techs, ec in ECs, area in areas
    PEStd[Heat,tech,ec,area,year] = PEStd[Heat,Electric,ec,area,year]
  end
  
  WriteDisk(db,"$Input/PEStd", PEStd)

end

function CalibrationControl(db)
  @info "Res_BldgStd.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
