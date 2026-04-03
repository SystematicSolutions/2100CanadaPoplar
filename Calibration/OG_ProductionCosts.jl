#
# OG_ProductionCosts.jl - OG Production Costs
# This is old data which has not been used for years - Jeff Amlin 02/04/22
#
using EnergyModel

module OG_ProductionCosts

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GPUC::VariableArray{3} = ReadDisk(db,"SpInput/GPUC") # [Process,Nation,Year] Gas Production Unit Full Cost (Real $/mmBtu)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  OPUC::VariableArray{3} = ReadDisk(db,"SpInput/OPUC") # [Process,Nation,Year] Oil Production Unit Full Cost (Real $/mmBtu)
  OPUCExist::VariableArray{3} = ReadDisk(db,"SpInput/OPUCExist") # [Process,Nation,Year] Oil Production Unit Full Cost for Existing Production (Real $/mmBtu)
  OPUCNew::VariableArray{3} = ReadDisk(db,"SpInput/OPUCNew") # [Process,Nation,Year] Oil Production Unit Full Cost for New Production (Real $/mmBtu)
  OPUCYr::Float32 = ReadDisk(db,"SpInput/OPUCYr")[1] # [tv] Oil Production Year for Existing Plants (Year)
 
end

function SCalibration(db)
  data = SControl(; db)
  (;Nations,Process,Processes,Years) = data
  (;GPUC,xExchangeRateNation,xInflationNation,OPUC,OPUCExist,OPUCNew,OPUCYr) = data

  # 
  # These are guesses in 2005 US$/Cubic Feet(?). CERI may have some better numbers.
  #
  for process in Processes, nation in Nations, year in Years
    GPUC[process,nation,year] = 2.50/1.030*xExchangeRateNation[nation,Yr(2005)]/xInflationNation[nation,Yr(2005)]
  end

  OPUCYr=2008

  # 
  # Cost for existing plants (1990-2008) from Nick Macaluso email 7/27/10 in US 2010$/bbl
  # 
  OPUCExist[Processes,Nations,Years] .= 1
  for nation in Nations, year in Years
    OPUCExist[Select(Process,"PrimaryOilSands"),nation,year]   = 29.76/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCExist[Select(Process,"SAGDOilSands"),nation,year]      = 32.51/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCExist[Select(Process,"CSSOilSands"),nation,year]       = 26.58/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCExist[Select(Process,"OilSandsMining"),nation,year]    = 29.76/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCExist[Select(Process,"OilSandsUpgraders"),nation,year] = 23.78/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
  end
  OPUC[Processes,Nations,Years] .= OPUCExist

  # 
  # Cost for new production (2009-2050) from Nick Macaluso email 7/27/10 in US 2010$/bbl
  # 
  OPUCNew[Processes,Nations,Years] .= 1
  for nation in Nations, year in Years
    OPUCNew[Select(Process,"PrimaryOilSands"),nation,year]   = 44.98/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCNew[Select(Process,"SAGDOilSands"),nation,year]      = 63.80/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCNew[Select(Process,"CSSOilSands"),nation,year]       = 58.30/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCNew[Select(Process,"OilSandsMining"),nation,year]    = 44.98/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
    OPUCNew[Select(Process,"OilSandsUpgraders"),nation,year] = 34.09/5.825*xExchangeRateNation[nation,Yr(2010)]/xInflationNation[nation,Yr(2010)]
  end

  WriteDisk(db,"SpInput/GPUC",GPUC)
  WriteDisk(db,"SpInput/OPUCYr",OPUCYr)
  WriteDisk(db,"SpInput/OPUCExist",OPUCExist)
  WriteDisk(db,"SpInput/OPUC",OPUC)
  WriteDisk(db,"SpInput/OPUCNew",OPUCNew)
 
end

function CalibrationControl(db)
  @info "OG_ProductionCosts.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
