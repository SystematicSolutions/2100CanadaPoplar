#
# SpRefCalib.jl - Refinery Unit Calibration
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# copyright 2013 Systematic Solutions, Inc.  All rights reserved.
#

using EnergyModel

module SpRefCalib

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
# import ...EnergyModel: Engine.SpRef


const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaKey::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))  
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationKey::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfName::SetArray = ReadDisk(db,"MainDB/RfName")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  SegKey::SetArray = ReadDisk(db,"MainDB/SegKey")
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  RfArea::Array{String} = ReadDisk(db,"SpInput/RfArea") # [RfUnit] Refinery Area
  RfCalSw::VariableArray{2} = ReadDisk(db,"SpInput/RfCalSw") # [Nation,Year] Switch for Years to Calibration Production (1-Calibrate)
  RfCapEffective::VariableArray{3} = ReadDisk(db,"SpOutput/RfCapEffective") # [RfUnit,Fuel,Year] Maximum Refining Unit Capacity for each RPP (TBtu/Yr)
  RfNation::Array{String} = ReadDisk(db,"SpInput/RfNation") # [RfUnit] Refinery Nation
  RfOOR::VariableArray{3} = ReadDisk(db,"SCalDB/RfOOR") # [RfUnit,Fuel,Year] Refining Unit Operational Outage Rate (Btu/Btu)
  RfProd::VariableArray{3} = ReadDisk(db,"SpOutput/RfProd") # [RfUnit,Fuel,Year] Refining Unit RPP Production (TBtu/Yr)
  RPPProdArea::VariableArray{3} = ReadDisk(db,"SpOutput/RPPProdArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPProdAdjust::VariableArray{3} = ReadDisk(db,"SCalDB/RPPProdAdjust") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)
  xRfCap::VariableArray{2} = ReadDisk(db,"SpInput/xRfCap") # [RfUnit,Year] Refining Unit Capacity (TBtu/Yr)
  xRfProd::VariableArray{3} = ReadDisk(db,"SpInput/xRfProd") # [RfUnit,Fuel,Year] Historical Refining Unit RPP Production (TBtu/Yr)
  xRPPProdArea::VariableArray{3} = ReadDisk(db,"SpInput/xRPPProdArea") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Production (TBtu/Yr)

  #
  # Scratch Variables
  #  
  CtMax = 10.00    # Maximum Iterations
  ErrLimit = 0.02  # Error Limit aka Error Target (TBtu)
  OORLimit = -0.98 # Limit on Operational Outage Rate (Btu/Btu)
  
  Prod::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Production
  RfErr1::VariableArray{2} = zeros(Float32,length(RfUnit),length(Fuel)) # [RfUnit,Fuel] Error for Current Iteration (TBtu)
  RfErr2::VariableArray{2} = zeros(Float32,length(RfUnit),length(Fuel)) # [RfUnit,Fuel] Error for Previous Iteration (TBtu)
  RfOOR1::VariableArray{2} = zeros(Float32,length(RfUnit),length(Fuel)) # [RfUnit,Fuel] Operational Outage Rate for Current Iteration (Btu/Btu)
  RfOOR2::VariableArray{2} = zeros(Float32,length(RfUnit),length(Fuel)) # [RfUnit,Fuel] Operational Outage Rate for Previous Iteration (Btu/Btu)
  SetYearFlag::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Years for Calibration Flag
  TempErr::VariableArray{2} = zeros(Float32,length(Fuel),length(RfUnit))
  xProd::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Historical Production
end

function SetYears(data)
  (;Nations,Years) = data
  (;RfCalSw,SetYearFlag) = data

  for year in Years
    SetYearFlag[year] = min(maximum(RfCalSw[nation,year] for nation in Nations),1)
  end
  years = findall(SetYearFlag[Years] .== 1)
  return years
end

function SetYearsFuture(data)
  (;Nations,Years) = data
  (;RfCalSw,SetYearFlag) = data
  
  @. SetYearFlag = 1
  years = collect(First:Final)
  for year in Years
    SetYearFlag[year] = maximum(RfCalSw[nation,year] for nation in Nations)
  end
  years = findall(SetYearFlag[Years] .== 0)
  return years
end

function Initialization(data,year)
  (;db) = data
  (;Fuels,RfUnits) = data
  (;RfErr1,RfErr2,RfOOR,RfOOR1,RfOOR2,xRfProd) = data
  
  @. RfOOR1 = 0.005
  @. RfOOR2 = 0.005
  @. RfErr1 = -99
  
  for fuel in Fuels, rfunit in RfUnits
    RfErr2[rfunit,fuel] = xRfProd[rfunit,fuel,year]*0.10
  end
  
  @. RfOOR = 0.005  
  WriteDisk(db,"SCalDB/RfOOR",RfOOR)
end

function CreateDebugLog()
  # 
  # TODOJulia - add this, if needed, will be different in Julia - Jeff Amlin 9/3/24
  #
  # Do If (RfCode eq "WSC")
  # * and (FuelKey eq "Gasoline")
  # * Select Output "Error.log", Printer=ON
  # *  write (" ")      
  # *  write (YearDS," ",RfCode::0," Count = ",Ct," Done = ",DoneOOR)
  # *  write (" RfCapEffective = ",RfCapEffective:12:4, " xRFCap = ",xRfCap:12:4,)
  # *  write (" Prod = ",Prod:12:4,           " xProd = ",xProd:12:4,)
  # *  write (" RfErr1 = ",RfErr1:12:4, " RfErr2 = ",RfErr2:12:4," FracDiff = ",FracDiff:12:4)
  # *  write (" RfOOR = ",RfOOR:12:4,  " RfOOR1 = ",RfOOR1:12:4," RfOOR2 = ",RfOOR2:12:4)
  # *  Write ("File:  SpRefCalib  Procedure: UnitProductionCalibration")
  # * Select Output FText1, Printer=OFF
  # End Do If RfCode
  #
end

function UnitProductionCalibration(data,rfunit,fuel,year,Ct)
  (;Prod) = data
  (;RfErr1,RfErr2,RfOOR,RfOOR1,RfOOR2,xProd) = data
  
  # 
  # @info "SpRefCalib - UnitProductionCalibration"
  #
  
  # 
  # Calculate current Error
  #
  RfErr1[rfunit,fuel] = xProd[year]-Prod[year]
  FracDiff = (xProd[year]-Prod[year])/xProd[year]

  # 
  # Check if Error exceeds limit (ErrLimit)
  # 
  if abs(FracDiff) > 0.005
    if (abs(RfErr1[rfunit,fuel]) > ErrLimit) && 
       ((RfOOR[rfunit,fuel,year] > OORLimit) || (Prod[year] > xProd[year]))

      # 
      # Adjust Operational Outage Rate (RfOOR) with Secant Method
      #

      # 
      # First Iteration perturb RfOOR
      #
      if Ct == 1.0
        RfOOR[rfunit,fuel,year] = RfOOR[rfunit,fuel,year]*1.01

      # 
      # Every twelve iterations perturb oscilations
      # 
      # Else Ct12 eq 10
      #   RfOOR[rfunit,fuel,year] = 
      #    (RfOOR1[rfunit,fuel]+RfOOR2[rfunit,fuel]+RfOOR[rfunit,fuel,year])/3
      #   @info "SpRefCalib - RfOOR = (RfOOR1+RfOOR2+RfOOR)/3"   
      
      else 

        # 
        # Adjust Outage Rate 
        #
        RfOOR[rfunit,fuel,year] = RfOOR1[rfunit,fuel]-
         (RfErr1[rfunit,fuel]*(RfOOR1[rfunit,fuel]-RfOOR2[rfunit,fuel])/
         (RfErr1[rfunit,fuel]-RfErr2[rfunit,fuel]))

        # 
        # If Outage Rate drops to zero, then give it a small value
        # 
        if RfOOR[rfunit,fuel,year] == 0
          RfOOR[rfunit,fuel,year] = RfOOR[rfunit,fuel,year]+0.005
        end

        # 
        # If no change from previous error, then give Outage Rate a push
        # 
        if ((RfErr2[rfunit,fuel] == RfErr1[rfunit,fuel]) &&
           (RfOOR[rfunit,fuel,year] < 0.99))
          RfOOR[rfunit,fuel,year] = RfOOR[rfunit,fuel,year]*1.01
        else 
          RfOOR[rfunit,fuel,year] = RfOOR[rfunit,fuel,year]*0.99    
        end

        # 
        # If production is zero, then set Outage Rate close to 1.00.
        # 
        if xProd == 0
          RfOOR[rfunit,fuel,year] = 0.99
        end
      end # if Ct   
  
      # 
      # Limit change of Outage Rate
      # 
      RfOOR[rfunit,fuel,year] = max(min(RfOOR[rfunit,fuel,year],
                     RfOOR1[rfunit,fuel]+.05),RfOOR1[rfunit,fuel]-0.05)
  
      # 
      # Trap outliers of Outage Rate
      # 
      RfOOR[rfunit,fuel,year] = max(min(RfOOR[rfunit,fuel,year],0.99),OORLimit)  
  
      #
      CreateDebugLog()
   
      # 
      #  Update errors and outage rates
      # 
      RfErr2[rfunit,fuel] = RfErr1[rfunit,fuel]
      RfOOR2[rfunit,fuel] = RfOOR1[rfunit,fuel]
      RfOOR1[rfunit,fuel] = RfOOR[rfunit,fuel,year]

    end # RfErr1
  end # FracDiff
end # UnitProductionCalibration

function FindMaxError(data)
  (;Fuels,RfUnits) = data
  (;TempErr,RfErr1) = data

  for fuel in Fuels, rfunit in RfUnits
    TempErr[rfunit,fuel] = abs(RfErr1[rfunit,fuel])
  end
  ErrMax = maximum(TempErr[rfunit,fuel] for rfunit in RfUnits, fuel in Fuels)
  return ErrMax

end

function CheckIfWeAreDone(data,DoneOOR,Ct,ErrMax)
  (;CtAll,ErrLimit,CtMax) = data

  #
  # If Count if high enough that all plant types have been calibrated
  # and maximum error is less than limit or Count grater than maximum
  # count, then we are done.
  #
  if ((Ct > CtAll) && (ErrMax < ErrLimit)) || (Ct > CtMax)
    DoneOOR = true
  end
  return DoneOOR

end

function CalibrateProduction(data,year,Ct)
  (;Areas,AreaKey,Fuels,NationKey,Nations) = data
  (;RfCalSw,RfArea,RfNation,RfOOR,RfOOR1,RfOOR2,RfProd) = data
  (;RPPProdAdjust,RPPProdArea,xRPPProdArea,xRfProd) = data

  for nation in Nations
    if RfCalSw == 1
      rfunits = findall(RfNation .== NationKey)
      if rfunits !isempty
        for rfunit in rfunits
          Prod[year] = sum(RfProd[rfunit,fuel,year] for fuel in Fuels)
          xProd[year] = sum(xRfProd[rfunit,fuel,year] for fuel in Fuels)
          if Ct == 0
            RfOOR[rfunit,fuel,year] = 1-xProd[year]/xRfCap[rfunit,year]
            RfOOR1[rfunit,fuel] = RfOOR[rfunit,fuel,year]
            RfOOR2[rfunit,fuel] = RfOOR[rfunit,fuel,year]
          else
            UnitProductionCalibration(data,rfunit,fuel,year,Ct)
          end
        end # for rfunits
      end # if rfunits !isempty
    end # if RfCalSw
  end # for Nation
   
  # 
  # RPP Production Adjustment - in order to calibate the historical 
  # Petroleum sector demands (xDmd), production (RPPProdArea) must equal
  # to historical production (xRPPProdArea) during the calibration period.
  # 
  for area in Areas
    rfunits = findall(RfArea .== AreaKey)
    if rfunits !isempty
      for fuel in Fuels
        RPPProdArea[fuel,area,year] = 
                        sum(RfProd[rfunit,fuel,year] for rfunit in rfunits)
      end
    end
  end

  @. RPPProdAdjust = xRPPProdArea-RPPProdArea
  
end

function FutureCalibratedValues(data)
  (;Areas,Fuels,RfUnits) = data
  (;RfOOR,RPPProdAdjust) = data

  years = SetYearsFuture(data)

  for year in years, fuel in Fuels, rfunit in RfUnits
    prior = max(1,year-1)
    RfOOR[rfunit,fuel,year] = RfOOR[rfunit,fuel,prior]
  end
  
  for year in years, area in Areas, fuel in Fuels
    prior = max(1,year-1)
    RPPProdAdjust[fuel,area,year] = RPPProdAdjust[fuel,area,prior]
  end

end

function PutCalibratedValues(data)
  (;db) = data
  (;RfOOR,RPPProdAdjust) = data
    
  WriteDisk(db,"SCalDB/RfOOR",RfOOR)
  WriteDisk(db,"SCalDB/RPPProdAdjust",RPPProdAdjust)
end

function RefiningCalibration(db)
  data = Data(; db)
  
  years = SetYears(data)

  for year in years
    CTime = year+ITime-1
    current = CTime-ITime+1
    prior = max(1,current-1)
    next = current+1
    
    DoneOOR = false  # Switch for Operational Outage Rate
    Ct12 = 0
    Ct = 0

    Initialization(data,year)

    while DoneOOR == false  

      # 
      #  Execute Refining Sector
      #   
      # TODOLater translate SpRef - Jeff 12.28.23
      #
      # @info "SpRefCalib.jl - RefiningCalibration"
      # SpRef.Control(SpRef.Data(; db, year, prior, next, CTime))     

      CalibrateProduction(data,year,Ct)

      #
      # UpdateCounters - was procedure in Promula
      #
      if Ct12 == 12
        Ct12 = 0
      else
        Ct12 = Ct12+1
      end
      Ct = Ct+1
  
      ErrMax = FindMaxError(data)

      DoneOOR = CheckIfWeAreDone(data,DoneOOR,Ct,ErrMax) 
    end # do while
  end # for Years

  FutureCalibratedValues(data)

  PutCalibratedValues(data)

end # RefiningCalibration

end # module SpRefCalib
