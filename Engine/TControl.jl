#
# TControl.jl - Transportation energy demand control segment
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# copyright 2013 Systematic Solutions, Inc.  All rights reserved.
#

using EnergyModel

module TControl

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,STime,HisTime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
import ...EnergyModel: Engine.TCalib
import ...EnergyModel: Engine.TFuture
import ...EnergyModel: Engine.TDemand
import ...EnergyModel: Engine.TLoad
import ...EnergyModel: Engine.TDemand2

const SectorName::String = "Transportation"
const SectorKey::String = "Trans"
const ESKey::String = "Transport"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DataTControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  # SceName::String = ReadDisk(DB,"SInput/SceName") #  Scenario Name
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECs::Vector{Int} = collect(Select(EC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")  
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  PI::SetArray = ReadDisk(db,"$Input/PIKey")
  PIDS::SetArray = ReadDisk(db,"$Input/PIDS")
  PIs::Vector{Int} = collect(Select(PI))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  tv::SetArray = ReadDisk(db,"MainDB/tvKey")
  tvs::Vector{Int} = collect(Select(tv))

  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  ElecMap::VariableArray{1} = ReadDisk(db,"$Input/ElecMap") # [Tech] Primary Electricity Technology Map
  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  FTMap::VariableArray{3} = ReadDisk(db,"$Input/FTMap") # [Fuel,EC,Tech]   # Map between Fuel and Tech (Map)
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] NonExist = -1
  PreCalc::Float32 = ReadDisk(db,"MainDB/PreCalc")[1] # [tv] PreCalc = 2

  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] EC to ECC Set Map
  STFSw::VariableArray{2} = ReadDisk(db,"$Input/STFSw") # [Fuel,Area] Short Term Forecast Switch (1=On, 0 = Off)

  xProcSw::VariableArray{2} = ReadDisk(db,"$Input/xProcSw") # [PI,Year] Procedure on/off Switch
  YEndTime::Float32 = ReadDisk(db,"$Input/YEndTime")[1] # [tv] Last Year of Calibration (Date)

  #
  # Scratch Variables
  #
  ProcSw::VariableArray{1} = zeros(Float32,length(PI)) # [PI] Procedure on/off Switch

  # CalibPass     'Pass through Historical Calibration (Counter)' 
  # PEMMAdj  'Process Efficiency Update Switch (True,False)'

end

#
# Control Execution of the Energy Demand
#
# ###########################
# Define Procedure RunControl
# ###########################
# #
# DBOpen
# ProcSw=xProcSw
# #
# Open Segment "TDemand.xeq"
# Read Segment Demand
# DBOpen
# Open Segment "TDemand2.xeq"
# Read Segment Demand2, Do(NumberOfVehicles)  
# #
# DBClose
# End Procedure RunControl
# *
# ************************
# *
# Define Procedure RunTDemand2
# *
# DBOpen
# ProcSw=xProcSw
# *
# Open Segment "TDemand2.xeq"
# Read Segment Demand2, Do(ProcessEmissions)
# *
# Open Segment "TDemand2.xeq"
# Read Segment Demand2, Do(LowCarbonCredits)
# *
# Open Segment "TDemand2.xeq"
# Read Segment Demand2, Do(MacroOutput)
# *
# DBClose
# End Procedure RunTDemand2
#
# # Control Execution of the Load Curves
# #
# ############################
# Define Procedure LoadControl
# ############################
# #
# # Write (" TControl.src, ",SectorDS::0," Load Control")
# #
# DBOpen
# ProcSw=xProcSw
# #
# Open Segment "TLoad.xeq"
# Read Segment LOAD
# #
# DBClose
# End Procedure LoadControl
# #
# ########################
# #
# Define Procedure RunModel
# #
# # Write (SectorDS::0," Control.src, RunModel - run historical period")
# #
# CTime=STime
# Do Until CTime GT HisTime
#   CTime = xmax(CTime,STime)
#   Write Disk(CTime)
#   Current = CTime-Yrv(1)+1
#   DT=Period
#   Prior=Current-1
#   Prior=xmax(1,Prior)
#   Prior2=xmax(1,Prior-1)
#   Next = Current+1
#   Select Year(Current)
# # Write (SectorDS::0," Control.src, simulating the year ",YearDS," ...")
#   Open Segment "TDemand.xeq"
#   Read Segment Demand
#  Open Segment "TDemand2.xeq"
#  Read Segment Demand2, Do(NumberOfVehicles) 
#   Open Segment "TLoad.xeq"
#   Read Segment LOAD
#   CTime = CTime+1
#   Write Disk(CTime)
# End Do Until
# End Procedure RunModel
#

function History(db,YEndTime)
  data = DataTControl(; db)
  (;db) = data
  (;PI) = data  
  (;Endogenous,NonExist,PreCalc,ProcSw,xProcSw) = data
  
  @info "$SectorName Control.jl - History - Historical Demand Calibration"

  #
  # Normalized End-use and Cogeneration Demand Coefficients
  #
  years = collect(1:Final)
  for year in years
    current = year
    CTime = current+ITime-1
    prior = max(1,current-1)
    next = min(current+1,MaxTime-ITime+1)
    @info "$SectorName Control.jl - History - Call Initialization $CTime"
    TCalib.Initial(TCalib.Data(;db,year,prior,next,CTime))
  end
  
  SceName = "Calib"
  CalibPass = 1
  while CalibPass <= 2
    CTime = STime
    while CTime <= YEndTime
      current = CTime-ITime+1
      year = current
      prior = max(1,current-1)
      next = current+1
      
      @. ProcSw = NonExist

      @info "$SectorName Control.jl - History - Call Initialization $CTime"
      
      #
      #   Get device values
      #
      pis = Select(PI,(from = "DMarginal",to = "DDSM"))
      for proc in pis
        ProcSw[proc] = min(Endogenous,xProcSw[proc])
      end
      proc = Select(PI,"Fungible")
      ProcSw[proc] = PreCalc

      @info "$SectorName Control.jl - History - Call Control"
      TDemand.Control(TDemand.Data(;db,year,prior,next,CTime,SceName,ProcSw))

      @info "$SectorName Control.jl - History - Call CalDEMM $CTime"
      TCalib.CalDEMM(TCalib.Data(;db,year,prior,next,CTime))

      #  
      #   Use device values and get process values
      #  
      pis = Select(PI,(from = "DMarginal",to = "CImpact"))
      for proc in pis
        ProcSw[proc] = min(Endogenous,xProcSw[proc])
      end
            
      @info "$SectorName Control.jl - History - Call Control"
      TDemand.Control(TDemand.Data(;db,year,prior,next,CTime,SceName,ProcSw))

      @info "$SectorName Control.jl - History - Call CalPEMM $CTime"
      TCalib.CalPEMM(TCalib.Data(;db,year,prior,next,CTime))

      #
      # Done with devices
      #
      pis = Select(PI,(from = "DMarginal",to = "DDSM"))
      for proc in pis
        ProcSw[proc] = PreCalc
      end      
      
      #  
      # Use process values and get rest-of-sector values
      #
      pis = Select(PI,(from = "CMarginal",to = "Cogeneration"))
      for proc in pis
        ProcSw[proc] = min(Endogenous,xProcSw[proc])
      end

      @info "$SectorName Control.jl - History - Call Control before Coefficients"
      TDemand.Control(TDemand.Data(;db,year,prior,next,CTime,SceName,ProcSw))

      @info "$SectorName Control.jl - History - Call Coefficients $CTime"
      TCalib.Coefficients(TCalib.Data(;db,year,prior,next,CTime),CalibPass)    
    
      #
      # Done with process values
      # 
      pis = Select(PI,(from = "CMarginal",to = "CImpact"))
      for proc in pis
        ProcSw[proc] = PreCalc
      end 

      #
      # Use rest-of-sector values
      #
      pis = Select(PI,(from = "MShare",to = "Pollution"))
      for proc in pis
        ProcSw[proc] = min(Endogenous,xProcSw[proc])
      end  

      @info "$SectorName Control.jl - History - Call Control before CapacityFactorCalibration"
      TDemand.Control(TDemand.Data(;db,year,prior,next,CTime,SceName,ProcSw))

      @info "$SectorName Control.jl - History - Call CapacityFactorCalibration $CTime"
      TCalib.CapacityFactorCalibration(TCalib.Data(;db,year,prior,next,CTime)) 

      @info "$SectorName Control.jl - History - Call Control"
      TDemand.Control(TDemand.Data(;db,year,prior,next,CTime,SceName,ProcSw))

      @info "$SectorName Control.jl - History - Call NumberOfVehicles $CTime"
      TDemand2.NumberOfVehicles(TDemand2.Data(; db,year,prior,next,CTime,SceName))

      CTime = CTime+1
      
    end # while CTime
    
    CalibPass = CalibPass+1
  
  end # while CalibPass

end # History


function TLoadCalib(db,RunTime,CalSw)
  data = DataTControl(; db)
  (;db) = data
  (;PI) = data  
  (;Endogenous,NonExist,ProcSw,xProcSw) = data
  
  @info "TControl - TLoadCalib - Loadcurve Calibration"
  
  False = 0
  
  @. ProcSw = NonExist
  pis = Select(PI,["ETOU","LoadMgmt","Loadcurve"])
  for proc in pis
    ProcSw[proc] = min(Endogenous,xProcSw[proc])
  end
  
  Loadcurve = Select(PI,"Loadcurve")
  
  if xProcSw[Loadcurve] != NonExist
  
    if CalSw == False
      @info "TControl.jl - TLoadCalib - LoadShape"
      #TCalib.LoadShape(TCalib.DataLoadShape(db))
      TCalib.LoadShape(db)      
    else
      @info "TControl.jl - TLoadCalib - Normalize"   
      #
      # TCalib.Normalize(TCalib.DataLoadShape(db))
      #
      TCalib.Normalize(db)
    end
    
    CTime = STime
    while CTime <= RunTime

      current = CTime-ITime+1
      year = current
      prior = max(1,current-1)
      prior2 = max(1,prior-1)      
      next = current+1
      
      @info "TControl.jl - TLoadCalib - TLoad - Control - $CTime"
      TLoad.Control(TLoad.Data(; db,year,prior,next,CTime))
      
      CTime = CTime+1
    end
  end

end

function Calib(db)
  data = DataTControl(; db)
  (;db) = data
  (;Areas,ECs) = data  
  (;CalibTime) = data
  
  @info "TControl - Calib - Demand Calibration"

  YEndTime = maximum(CalibTime[ec,area] for area in Areas, ec in ECs)
  CalLast = YEndTime-ITime+1
  CalFuture = CalLast+1

  #
  # Initial is split off so we can adjust the parameters
  # before starting the rest of the calibration.
  # 
  # Remove Initial 
  # Open Segment "TInitial.xeq"
  # Read Segment Initial
  
  History(db,YEndTime)
  
  
  TFuture.Control(db)

  #
  #  Calibrate Short Term Future Values of Calibration Variables.
  # 
  # 
  # Do Area
  #   Sum1=sum(F)(STFSw(F,Area))
  #   Do if Sum1 ne 0
  #     ProcSw=xProcSw
  #     STime = xHisTime
  #     HisTime=SFTime
  #    RunModel
  #     Open Segment "TFuture.xeq"
  #     Read Segment Future, Do(SFCalib)
  #    DBOpen
  #     ProcSw=xProcSw
  #     STime = xHisTime
  #     HisTime=SFTime
  #     RunModel
  #   End Do If
  # End Do Area
  # STime = xITime+1
  # HisTime = xHisTime

end # Calib



# 
# ##########################
# Define Procedure ShortTerm
# ##########################
# 
# Last=YEndTime-Yrv(1)+1
# Future=Last+1
# 
# ProcSw=xProcSw
# STime = xHisTime
# HisTime=SFTime
# RunModel
# Open Segment "TFuture.xeq"
# Read Segment Future, Do(SFCalib)
# DBOpen
# ProcSw=xProcSw
# STime = xHisTime
# HisTime=SFTime
# RunModel
# STime = xITime+1
# HisTime = xHisTime
# #
# DBClose
# Select Sector#
# Last=xHisTime-Yrv(1)+1
# Future=Last+1
# End Procedure ShortTerm

end
