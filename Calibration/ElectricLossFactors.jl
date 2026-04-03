#
# ElectricLossFactors.jl
#
using EnergyModel

module ElectricLossFactors

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ElectricLossFactorsCalib
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  TDEF::VariableArray{3} = ReadDisk(db,"SInput/TDEF") # [Fuel,Area,Year] T&D Efficiency (MW/MW)

  # Scratch Variables
  LossFactor::VariableArray{1} = zeros(Float32,length(Area)) # [Area] T&D Loss Fraction (GWh/GWh)
  TDEFCalifornia::VariableArray{1} = zeros(Float32,length(Year)) # [Year] California Electricity T&D Efficiency (MW/MW)
  TDEFMexico::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Mexico Electricity T&D Efficiency (MW/MW)
end

function ECalibration(db)
  data = ElectricLossFactorsCalib(; db)
  (;Area,Fuel,Nation,Years) = data
  (;ANMap,TDEF) = data
  (;LossFactor,TDEFCalifornia,TDEFMexico) = data
  
  #*
  #* Canadian loss factors set by area - Hilary Paulin, August 2017
  #* Estimates based on consultation with PTs & Utility documents
  #* Losses should be roughly aligned with historical vData balancing assumptions
  #* T\2015_Update\Electricity\Source Data\Provincial Line Losses Estimates.xlsx
  #*
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  fuel = Select(Fuel,"Electric")

  #*
  #* Read in losses by area
  #*
  LossFactor[areas] = [
  #=Ontario       =# 0.050
  #=Quebec        =# 0.067
  #=BC            =# 0.060
  #=Alberta       =# 0.037
  #=Manitoba      =# 0.140
  #=Saskatchewan  =# 0.080
  #=New Brunswick =# 0.050
  #=Nova Scotia   =# 0.063
  #=Newfoundland  =# 0.050
  #=PEI           =# 0.070
  #=Yukon         =# 0.088
  #=NWT           =# 0.050
  #=Nunavut       =# 0.050  
  ]

  #*
  #* Calculate new TDEF based on loss factors, keeping constant in all years
  #*
  for year in Years, area in areas
    TDEF[fuel,area,year] = 1.0 - LossFactor[area]
  end

  #*
  #************************
  #*
  #* US loss factor set at 7% - Jeff Amlin "rule of thumb" 10/6/16
  #*
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  for year in Years, area in areas 
    TDEF[fuel,area,year] = 0.93
  end

  #=*
  ************************
  *
  * Revise California loss factor to energy available (generation plus imports)
  * - Jeff Amlin 02/06/16
  * http://energyalmanac.ca.gov/electricity/electricity_generation.html
  * http://www.energy.ca.gov/2013publications/CEC-200-2013-004/CEC-200-2013-004-V1-CMF.pdf
  *=#
  years = collect(Yr(2000):Yr(2013))
  TDEFCalifornia[years] = [
  #/ 2000  2001  2002  2003  2004  2005  2006  2007  2008  2009  2010  2011  2012  2013
    1.032 0.915 0.904 0.907 0.900 0.912 0.909 0.903 0.909 0.911 0.912 0.905 0.903 0.921
  ]

  #*
  #* 2000 efficiency is greater than 1.0, so use 2001 for missing historical years
  #*
  years = collect(Yr(1985):Yr(1999))
  for year in years
    TDEFCalifornia[year] = TDEFCalifornia[Yr(2001)]
  end
  years = collect(Yr(2014):Final)
  for year in years
    TDEFCalifornia[year] = TDEFCalifornia[Yr(2013)]
  end

  CA = Select(Area,"CA")
  for year in Years
    TDEF[fuel,CA,year] = TDEFCalifornia[year]
  end

  #=*
  ************************
  *
  * Loss Factors "SENER_ElectricityBalance_MX_1985-2018.xlsx) - R.Levesque 11/17/2020
  * Source: SENER website  http://sie.energia.gob.mx/bdiController.do?action=cuadro&subAction=applyOptions
  * Note:  Losses include T&D losses, own use, and supply-demand adjustment                                     
  *=#
  years = collect(Yr(1985):Yr(2018))
  TDEFMexico[years] = [
  #/1985  1986  1987  1988  1989  1990  1991  1992  1993  1994  1995  1996  1997  1998  1999  2000  2001  2002  2003  2004  2005  2006  2007  2008  2009  2010  2011  2012  2013  2014  2015  2016  2017  2018
   0.826  0.830 0.824 0.821 0.816 0.818 0.813 0.811 0.809 0.803 0.802 0.800 0.798 0.794 0.799 0.801 0.796 0.793 0.801 0.801 0.798 0.799 0.797 0.799 0.794 0.793 0.797 0.801 0.811 0.818 0.823 0.830 0.816 0.840
  ]

  years = collect(Yr(2019):Final)
  for year in years
    TDEFMexico[year] = TDEFMexico[Yr(2018)]
  end

  MX = Select(Area,"MX")
  for year in Years
    TDEF[fuel,MX,year] = TDEFMexico[year]
  end

  WriteDisk(db,"SInput/TDEF",TDEF)

end

function CalibrationControl(db)
  @info "ElectricLossFactors.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
