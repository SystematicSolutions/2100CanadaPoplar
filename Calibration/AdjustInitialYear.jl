#
# AdjustInitialYear.jl - Assign first year of demand calibration
#
using EnergyModel

module AdjustInitialYear

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))

  InitialDemandYear::VariableArray{2} = ReadDisk(db,"$Input/InitialDemandYear") # [EC,Area] First Year of Calibration 

  # Scratch Variables
end

function IndCalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,Areas,EC) = data
  (;InitialDemandYear) = data
  # Selected Industries initialized in 2011
  #
  # Removed OtherMetalMining (vDmd from 1985-2012)
  # *
  # * Switched Fertilizer to 2007 re: Robin (14.08.08) - Hilary Paulin
  # *
  Fertilizer = Select(EC, "Fertilizer")
  for area in Areas
    InitialDemandYear[Fertilizer,area]=2007
  end
  # 
  # Switched SAGDOilSands from 2011 to 2001, which is the first year of vDmd. 
  # (This is in the calibration period so may not be necessary; changes are minimal.)
  # 
  SAGDOilSands = Select(EC, "SAGDOilSands")
  for area in Areas
    InitialDemandYear[SAGDOilSands,area]=2001
  end
  #
  # LNG Production starts in 2019 
  # 
  LNGProduction = Select(EC, "LNGProduction")
  for area in Areas
    InitialDemandYear[LNGProduction,area]=2025
  end
  #
  # Driver is significant for all areas for Frontier Oil Mining in 1999
  # Jeff Amlin 07/12/14
  #
  FrontierOilMining = Select(EC, "FrontierOilMining")
  for area in Areas
    InitialDemandYear[FrontierOilMining,area]=1999
  end
  # 
  # Historical demands irregular for the sectors below in 1985. Choose a better year - Ian 08/07/15
  #
  OtherMetalMining=Select(EC, "OtherMetalMining")
  Alberta=Select(Area, "AB")
  InitialDemandYear[OtherMetalMining,Alberta]=2010
  # 
  OtherManufacturing=Select(EC, "OtherManufacturing")
  NewBrunswick=Select(Area, "NB")
  InitialDemandYear[OtherManufacturing,NewBrunswick]=2006
  NovaScotia=Select(Area, "NS")
  InitialDemandYear[OtherManufacturing,NovaScotia]=2009
  Nunavut=Select(Area, "NU")
  InitialDemandYear[OtherManufacturing,Nunavut]=2009
  Newfoundland=Select(Area, "NL")
  InitialDemandYear[OtherManufacturing,Newfoundland]=2011
  Yukon=Select(Area, "YT")
  InitialDemandYear[OtherManufacturing,Yukon]=2011
  Northwest=Select(Area, "NT")
  InitialDemandYear[OtherManufacturing,Northwest]=2011
  #
  LimeGypsum=Select(EC, "LimeGypsum") 
  InitialDemandYear[LimeGypsum,NewBrunswick]=2010
  # 
  Saskatchewan=Select(Area, "SK")
  Lumber=Select(EC, "Lumber") 
  InitialDemandYear[Lumber,Saskatchewan]=2006
  Manitoba=Select(Area, "MB")
  InitialDemandYear[Lumber,Manitoba]=2006
  #
  HeavyOilMining=Select(EC, "HeavyOilMining") 
  InitialDemandYear[HeavyOilMining,Newfoundland]=2018
  #
  OilSandsUpgraders=Select(EC, "OilSandsUpgraders") 
  InitialDemandYear[OilSandsUpgraders,Saskatchewan]=1993
  #
  # Multiple Glass adjustments from Jeff - Ian 08/04/22
  #
  Glass=Select(EC, "Glass") 
  PrinceEdward=Select(Area, "PE")
  InitialDemandYear[Glass,PrinceEdward]=1999
  InitialDemandYear[Glass,Yukon]=1988
  InitialDemandYear[Glass,Northwest]=1989
  
  #
  # NonMetalMining in NT with TOM drivers - R.Levesque 02/18/24
  #
  NonMetalMining=Select(EC, "NonMetalMining") 
  InitialDemandYear[OtherMetalMining,Northwest]=2003
  InitialDemandYear[NonMetalMining,Northwest]=2003

  #
  # OtherChemicals in NU with TOM drivers - R.Levesque 02/18/24
  #
  OtherChemicals=Select(EC, "OtherChemicals") 
  InitialDemandYear[OtherChemicals,Nunavut]=2010
  
  WriteDisk(db,"$Input/InitialDemandYear",InitialDemandYear)
end

function CalibrationControl(db)
  @info "AdjustInitialYear.jl - CalibrationControl"
  IndCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
