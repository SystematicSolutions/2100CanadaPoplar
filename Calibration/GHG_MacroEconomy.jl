#
# GHG_MacroEconomy.jl
#
using EnergyModel

module GHG_MacroEconomy

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  FlPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FlPOCX") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions Coefficient (Tonnes/Driver)
  FlPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/FlPolSwitch") # [ECC,Poll,Area,Year] Flaring Pollution Switch (0=Exogenous)
  FlReduce::VariableArray{4} = ReadDisk(db,"SOutput/FlReduce") # [ECC,Poll,Area,Year] Flaring Reductions (Tonnes/Yr)
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  FuPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/FuPolSwitch") # [ECC,Poll,Area,Year] Fugitive Pollution Switch (0=Exogenous)
  FuReduce::VariableArray{4} = ReadDisk(db,"SOutput/FuReduce") # [ECC,Poll,Area,Year] Other Fugitives Reductions (Tonnes/Yr)
  MEDriver::VariableArray{3} = ReadDisk(db,"MOutput/MEDriver") # [ECC,Area,Year] Driver for Process Emissions (Various Millions/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-Output)
  MEPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/MEPolSwitch") # [ECC,Poll,Area,Year] Process Pollution Switch (0=Exogenous)
  MEReduce::VariableArray{4} = ReadDisk(db,"SOutput/MEReduce") # [ECC,Poll,Area,Year] Non Energy Reductions (Tonnes/Yr)
  VnPOCX::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCX") # [ECC,Poll,Area,Year] Fugitive Venting Emissions Coefficient (Tonnes/Driver)
  VnPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/VnPolSwitch") # [ECC,Poll,Area,Year] Venting Pollution Switch (0=Exogenous)
  VnReduce::VariableArray{4} = ReadDisk(db,"SOutput/VnReduce") # [ECC,Poll,Area,Year] Venting Reductions (Tonnes/Yr)
  xFlPol::VariableArray{4} = ReadDisk(db,"SInput/xFlPol") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions (Tonnes/Yr)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Other Fugitive Emissions (Tonnes/Yr)
  xVnPol::VariableArray{4} = ReadDisk(db,"SInput/xVnPol") # [ECC,Poll,Area,Year] Fugitive Venting Emissions (Tonnes/Yr)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Process Pollution (Tonnes/Yr)

end

function MacroCalibration(db)
  data = MControl(; db)
  (;Area,Areas,ECC,ECCs,Nation,Poll) = data
  (;Polls,Years) = data
  (;ANMap,FlPOCX,FlPolSwitch,FlReduce,FuPOCX,FuPolSwitch,FuReduce,MEDriver,MEPOCX,MEPolSwitch) = data
  (;MEReduce,VnPOCX,VnPolSwitch,VnReduce,xFlPol,xFuPol,xVnPol,xMEPol) = data
  
  CN = Select(Nation,"CN")
  areas =  findall(x -> x == 1, ANMap[:,CN])
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
  
  # 
  #  Add back emission reductions (MEReduce) to historical emissions (xMEPol)
  # 
  for year in Years, area in areas, poll in polls, ecc in ECCs
    if xMEPol[ecc,poll,area,year] > 0.0
      xMEPol[ecc,poll,area,year] = xMEPol[ecc,poll,area,year] + MEReduce[ecc,poll,area,year]
    end
  end
  WriteDisk(db,"SInput/xMEPol",xMEPol)
  
  # 
  #  HFC emissions for passenger, Freight, and Air Passenger are exogenous
  #  until the reference case (Ref24) creates a VDT
  # 
  HFC = Select(Poll,"HFC")
  eccs = Select(ECC,["Passenger","Freight","AirPassenger"])
  @. MEPolSwitch[eccs,HFC,areas,Years] = 0.0
  
  # 
  #  Animal Production N2O and CH4 is exogenous, hold emissions at 2030 level
  #  Jeff Amlin 08/03/15
  # 
  polls = Select(Poll,["CO2","N2O","CH4"])
  AnimalProduction = Select(ECC,"AnimalProduction")
  @. MEPolSwitch[AnimalProduction,polls,areas,Years] = 0.0
  
  # 
  #  Crop Production N2O is exogenous, hold emissions at 2030 level
  #  Jeff Amlin 08/03/15
  # 
  CropProduction = Select(ECC,"CropProduction")
  @. MEPolSwitch[CropProduction,polls,areas,Years] = 0.0
  
  WriteDisk(db,"SInput/MEPolSwitch",MEPolSwitch)
 
  # 
  #  Process emission coefficient (MEPOCX) is historical emissions (xMEPol) 
  #  divided by process emission driver (MEDriver).
  # 
  #  Seperated MEPOCX to its own section since we have xMEPol out to 2050
  #  - Ian 05/24/13
  # 
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
  @. MEPOCX[ECCs,polls,areas,Years] = 0.0
  
  for year in Years, area in areas, poll in polls, ecc in ECCs
    @finite_math MEPOCX[ecc,poll,area,year] = xMEPol[ecc,poll,area,year] / MEDriver[ecc,area,year]
    
  end
  
  years = collect(Future:Final)
  for year in years, area in areas, poll in polls, ecc in ECCs
    if (MEDriver[ecc,area,year] <= 1.0) | (xMEPol[ecc,poll,area,year] == 0.0)
      MEPOCX[ecc,poll,area,year] = MEPOCX[ecc,poll,area,year-1]
    end
  end
  
  years = collect(Yr(1990):Last)
  for year in years, area in areas, poll in polls, ecc in ECCs
    @finite_math FuPOCX[ecc,poll,area,year] = (xFuPol[ecc,poll,area,year]+FuReduce[ecc,poll,area,year])/MEDriver[ecc,area,year]
    @finite_math FlPOCX[ecc,poll,area,year] = (xFlPol[ecc,poll,area,year]+FlReduce[ecc,poll,area,year])/MEDriver[ecc,area,year]
    @finite_math VnPOCX[ecc,poll,area,year] = (xVnPol[ecc,poll,area,year]+VnReduce[ecc,poll,area,year])/MEDriver[ecc,area,year]
  end
  
  # 
  #  The coefficients from the last historical year are used for the forecast years.
  # 
  years = collect(Future:Final)
  for year in years, area in areas, poll in polls, ecc in ECCs
    FuPOCX[ecc,poll,area,year] = FuPOCX[ecc,poll,area,Yr(2019)]
    FlPOCX[ecc,poll,area,year] = FlPOCX[ecc,poll,area,Yr(2019)]
    VnPOCX[ecc,poll,area,year] = VnPOCX[ecc,poll,area,Yr(2019)]
  end
  
  # 
  #  LNG Production in BC
  # 
  BC = Select(Area,"BC")
  ecc = Select(ECC,"LNGProduction")
  years = collect(Yr(2019):Final)
  for year in years, poll in polls
    @finite_math MEPOCX[ecc,poll,BC,year] = xMEPol[ecc,poll,BC,year]/MEDriver[ecc,BC,year]
    @finite_math FuPOCX[ecc,poll,BC,year] = xFuPol[ecc,poll,BC,year]/MEDriver[ecc,BC,year]
    @finite_math FlPOCX[ecc,poll,BC,year] = xFlPol[ecc,poll,BC,year]/MEDriver[ecc,BC,year]
    @finite_math VnPOCX[ecc,poll,BC,year] = xVnPol[ecc,poll,BC,year]/MEDriver[ecc,BC,year]
  end
  years = collect(Zero:Yr(2018))
  for year in years, poll in polls
    @finite_math MEPOCX[ecc,poll,BC,year] = MEPOCX[ecc,poll,BC,Yr(2019)]
    @finite_math FuPOCX[ecc,poll,BC,year] = FuPOCX[ecc,poll,BC,Yr(2019)]
    @finite_math FlPOCX[ecc,poll,BC,year] = FlPOCX[ecc,poll,BC,Yr(2019)]
    @finite_math VnPOCX[ecc,poll,BC,year] = VnPOCX[ecc,poll,BC,Yr(2019)]
  end
  
  # 
  #  Sweet & Sour Gas Processing in BC - Exogenous venting forecast from Rob
  #  - Ian 08/25/16, Rob 08/29/16
  # 
  eccs = Select(ECC,["SweetGasProcessing","SourGasProcessing"])
  polls = Select(Poll,["CO2","CH4"])
  years = collect(Future:Yr(2040))
  for year in years, poll in polls, ecc in eccs
    @finite_math VnPOCX[ecc,poll,BC,year] = xVnPol[ecc,poll,BC,year]/MEDriver[ecc,BC,year]
  end
  years = collect(Yr(2041):Final)
  for year in years, poll in polls, ecc in eccs
    VnPOCX[ecc,poll,BC,year] =VnPOCX[ecc,poll,BC,Yr(2040)]
  end
  
  # 
  #  SF6 are in Electric Utilities and Other Nonferrous and have 
  #  a slow decline to offset economic growth
  # 
  SF6 = Select(Poll,"SF6")
  eccs = Select(ECC,["UtilityGen","OtherNonferrous"])
  years = collect(Future:Final)
  for year in years, area in areas, ecc in eccs
    MEPOCX[ecc,SF6,area,year] = MEPOCX[ecc,SF6,area,year-1] * (1-0.022)
  end
  
  # 
  #  Northwest Territories Natural Gas Pipeline does not begin until 2017
  # 
  NT = Select(Area,"NT")
  NGPipeline = Select(ECC,"NGPipeline")
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
  for year in years, poll in polls
    xFuPol[NGPipeline,poll,NT,year] = xFuPol[NGPipeline,poll,NT,Last]
    @finite_math FuPOCX[NGPipeline,poll,NT,year] = xFuPol[NGPipeline,poll,NT,year] / MEDriver[NGPipeline,NT,year]
  end
  
  # 
  #  Flaring Forecast for Newfoundland Frontier Oil Mining
  # 
  NL = Select(Area,"NL")
  eccs = Select(ECC,["FrontierOilMining","HeavyOilMining"])
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  for year in years, poll in polls, ecc in eccs
    @finite_math FlPOCX[ecc,poll,NL,year] = xFlPol[ecc,poll,NL,year] / MEDriver[ecc,NL,year]
  end
  
  for ecc in ECCs, year in Years, area in Areas, poll in Polls
    FuPolSwitch[ecc,poll,area,year] = 2.0
    VnPolSwitch[ecc,poll,area,year] = 2.0
    FlPolSwitch[ecc,poll,area,year] = 1.0
  end
  
  # 
  #  NS Coal Mining has input emissions in forecast - Ian 11/10/21
  # 
  
  NS = Select(Area,"NS")
  CoalMining = Select(ECC,"CoalMining")
  years = collect(Future:Final)
  @. FuPolSwitch[CoalMining,Polls,NS,years] = 0
  
  # Select ECC*, Area*, Year*
  # 
  #  Gavin's additions. This is to have more accurate reductions from methane policy.
  #  Temporary change that will be cease to exist after we have updated methane 
  #  reductions from RAVD.
  # 
  
  areas = Select(Area,["AB","BC","SK"])
  polls = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC","NF3"])
  eccs = Select(ECC,["LightOilMining","HeavyOilMining",
  "ConventionalGasProduction","UnconventionalGasProduction",
  "SourGasProcessing","SweetGasProcessing"])
  years = collect(Future:Final)
  
  for ecc in eccs, year in years, area in areas, poll in polls
    println(ecc,poll,area,year)
    FuPolSwitch[ecc,poll,area,year] = 0.0
    VnPolSwitch[ecc,poll,area,year] = 0.0
    FlPolSwitch[ecc,poll,area,year] = 0.0
  end
  
  WriteDisk(db,"MEInput/FlPOCX",FlPOCX)
  WriteDisk(db,"MEInput/FuPOCX",FuPOCX)
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
  WriteDisk(db,"MEInput/VnPOCX",VnPOCX)
  WriteDisk(db,"SInput/FuPolSwitch",FuPolSwitch)
  WriteDisk(db,"SInput/VnPolSwitch",VnPolSwitch)
  WriteDisk(db,"SInput/FlPolSwitch",FlPolSwitch)

end

function CalibrationControl(db)
  @info "GHG_MacroEconomy.jl - CalibrationControl"

  MacroCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
