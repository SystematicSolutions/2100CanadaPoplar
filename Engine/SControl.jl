#
# SControl.jl - Energy Supply Control Segment
#
# The ENERGY 2100 model and all associated software are 
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc. 
# copyright 2013 Systematic Solutions, Inc.  All rights reserved.
#

using EnergyModel

#
#
import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct DataSControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  DACTech::SetArray = ReadDisk(db,"SInput/DACTechKey")
  DACTechDS::SetArray = ReadDisk(db,"SInput/DACTechDS")
  DACTechs::Vector{Int} = collect(Select(DACTech))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))  
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))  
  H2Tech::SetArray = ReadDisk(db,"MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db,"MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))  
  OGCode::Vector{String} = ReadDisk(db,"MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGCode")
  OGUnits::Vector{Int} = collect(Select(OGUnit)) 
  PI::SetArray = ReadDisk(db,"SInput/PIKey")
  PIDS::SetArray = ReadDisk(db,"SInput/PIDS")
  PIs::Vector{Int} = collect(Select(PI))
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfName::SetArray = ReadDisk(db,"MainDB/RfName")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  SegKey::SetArray = ReadDisk(db,"MainDB/SegKey")
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")
  Tech::SetArray = ReadDisk(db,"SInput/TechKey")
  TechDS::SetArray = ReadDisk(db,"SInput/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
  #
  # Pointer "Keys" for PI
  #
  AccountsKey = Select(PI,"Accounts")
  LoadcurveKey = Select(PI,"Loadcurve")
  DailyUseKey = Select(PI,"DailyUse")
  PriceKey = Select(PI,"Price")   
  

  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF") #[Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  PE::VariableArray{3} = ReadDisk(db,"SOutput/PE") #[ECC,Area,Year]  Price of Electricity ($/MWh)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map between Sector and ECC Sets (1=Res, 2=Com, 3=Ind, etc.)
  xPE::VariableArray{3} = ReadDisk(db,"SInput/xPE") #[ECC,Area,Year]  Historical Electricity Price (Real $/MWh)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)

  Endogenous::Float32 = ReadDisk(db,"MainDB/Endogenous")[1] # [tv] Endogenous = 1
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] NonExist = -1
  xProcSw::VariableArray{2} = ReadDisk(db,"SInput/xProcSw") # [PI,Year] Procedure on/off Switch

  # Scratch Variables
  # Ct       'Iteration Count for Calibration'
  # Ct12     'Iteration Count to 12 for Calibration'
  # CtMax    'Maximum Iterations'
  # DoneCalib     'Calibration Completion Switch (1=Done)'
  # DoneOOR  'Switch for Operational Outage Rate'
  OGCase::VariableArray{1} = zeros(Float32,length(1)) # [1] Oil and Gas Price Case (High,Low)
  OGDone::VariableArray{1} = zeros(Float32,length(OGUnit)) # [OGUnit] Calibration Completion Switch (1=Done)
  OGErr1::VariableArray{1} = zeros(Float32,length(OGUnit)) # [OGUnit] Error for Current Iteration (TBtu)
  OGErr2::VariableArray{1} = zeros(Float32,length(OGUnit)) # [OGUnit] Error for Previous Iteration (TBtu)
  # OGFinal  'Final Year to Assign Calibrated Values (Year)'
  # OGFirst  'First Year of OG Production Calibration (Year)'
  # OGFuture 'First Future Year to Assign Calibrated Values (Year)'
  # OGLast   'Last Year of OG Production Calibration (Year)'
  ProcSw::VariableArray{1} = zeros(Float32,length(PI)) # [PI] Procedure on/off Switch
  # RunTime       'Final Time for Runing Model'
  VF1::VariableArray{1} = zeros(Float32,length(OGUnit)) # [OGUnit] Variance Factor for Current Iteration (Btu/Btu)
  VF2::VariableArray{1} = zeros(Float32,length(OGUnit)) # [OGUnit] Variance Factor for Previous Iteration (Btu/Btu)
end


function ExeSegments(data,seg,year,prior,next,CTime,current,CIt,NIt,PIt,DoneG)
  (;db) = data
  (;DACTechDS,FuelEP,H2TechDS,Nation,Nations,SegKey) = data
  (;DACTechDS,H2TechDS)= data

  #
  # Write ("SControl.src - ExeSegments")
  #

  #
  # "Loadcurve" is run before the Electric sector
  #
  if SegKey[seg] == "Loadcurve"

    @info "ExeSegments - Hydrogen Supply"
    SpHydrogen.SupplyHydrogen(SpHydrogen.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - DirectAirCapture SupplyDAC"
    DirectAirCapture.SupplyDAC(DirectAirCapture.Data(; db,year,current,prior,next,CTime))

    @info "ExeSegments - Supply ExoSalesNonElectric"
    Supply.ExoSalesNonElectric(Supply.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - Supply ExoElectricSalesAndLoadCurve"
    Supply.ExoElectricSalesAndLoadCurve(Supply.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - Supply RestOfWorldLoadCurve"
    Supply.RestOfWorldLoadCurve(Supply.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - Supply LoadCurve"
    Supply.LoadCurve(Supply.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - Supply SteamSupply"
    Supply.SteamSupply(Supply.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - Supply DailyUse"
    Supply.DailyUse(Supply.Data(; db,year,prior,next,CTime))

  #
  # "Supply" is run after the Electric Sector
  #
  elseif SegKey[seg] == "Supply"

    @info "ExeSegments - Coal Supply"
    SpCoal.Control(SpCoal.Data(; db,year,prior,next,CTime))
    
    #  
    # The gas and oil production sectors are run here for calibration (historical),
    # but must be run earlier in the future to enable production elasticity 
    # calculations.  Jeff Amlin April 19, 2007.
    # Gas production (SpGas) must come before oil Production (SpOProd) because gas
    # production is used to compute Pentanes and Condensates - Jeff Amlin 11/24/19
    # 
    if CTime <= HisTime

      @info "ExeSegments - SpRefinery Control"
      SpRefinery.Control(SpRefinery.Data(; db,year,prior,next,CTime))

      @info "ExeSegments - SpOGProd Control"
      SpOGProd.Control(SpOGProd.Data(; db,year,prior,next,CTime))

      @info "ExeSegments - SpGas Control"
      SpGas.Control(SpGas.Data(; db,year,prior,next,CTime))
  
      @info "ExeSegments - SpOProd Control"
      SpOProd.Control(SpOProd.Data(; db,year,prior,next,CTime))
  
    end

    #
    # TODOLater translate SpGTrans - Jeff 12.28.23
    # @info "ExeSegments - SpGTrans Control"
    # SpGTrans.Control()
    #
    
    # 
    # TODOLater translate SpRef - Jeff 12.28.23
    # @info "ExeSegments - SpRef Control"
    # SpRef.Control()
    #
    
    #
    # TODOLater add BiofuelSwitch - Jeff 12.28.23
    # if BiofuelSwitch eq 1
    #    
        @info "ExeSegments - SpBiofuel SupplyBiofuel"
        SpBiofuel.SupplyBiofuel(SpBiofuel.Data(; db,year,prior,next,CTime))
    #
    # else
      # TODOLater translate SpEthanol - Jeff 12.28.23
      # @info "ExeSegments - SpEthanol EthanolSupply"
    # SpEthanol.EthanolSupply(SpEthanol.Data(; db, year, prior, next, CTime))
    # end
    #  
    @info "ExeSegments - SpImportsExports Control"
    SpImportsExports.Control(SpImportsExports.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - Supply Accounts"
    Supply.Accounts(Supply.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - SuPollution PollutionTotals"
    SuPollution.PollutionTotals(SuPollution.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - SuPollutionEI Control"
    SuPollutionEI.Control(SuPollutionEI.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - SuPollutionCFS Control"
    SuPollutionCFS.Control(SuPollutionCFS.Data(; db,year,prior,next,CTime))
  
    ### @info "ExeSegments - SuPollutionOGEC Control"
    ### SuPollutionOGEC.Control(SuPollutionOGEC.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - SuPollutionMarket Control"
    SuPollutionMarket.Control(SuPollutionMarket.Data(;db,year,prior,next,CTime),CIt,NIt,PIt,DoneG)
  
    @info "ExeSegments - SuPollutionCFS CFSCredits"
    SuPollutionCFS.CFSCredits(SuPollutionCFS.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - Coal Price"
    SpCoal.CoalPrice(SpCoal.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - SpOProd OilPrice"
    SpOProd.OilPrice(SpOProd.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - SpGas GasPrice"
    SpGas.GasPrice(SpGas.Data(; db,year,prior,next,CTime))

    @info "ExeSegments - SpFuelSupplyCurve Control"
    SpFuelSupplyCurve.Control(SpFuelSupplyCurve.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - Supply Price"
    Supply.Price(Supply.Data(; db,year,prior,next,CTime))
  
    #
    # TODOLater add BiofuelSwitch - Jeff 12.28.23
    #
    # if BiofuelSwitch eq 1
    @info "ExeSegments - SpBiofuel PriceBiofuel"
    SpBiofuel.PriceBiofuel(SpBiofuel.Data(; db,year,prior,next,CTime))
    # else
      # TODOLater translate SpEthanol - Jeff 12.28.23
      # @info "ExeSegments - SpEthanol PriceEthanol"
      # SpEthanol.PriceEthanol(SpEthanol.Data(; db, year, prior, next, CTime))
    # end
  
    @info "ExeSegments - Hydrogen Price"
    SpHydrogen.PriceHydrogen(SpHydrogen.Data(; db,year,prior,next,CTime))
  
    @info "ExeSegments - DirectAirCapture PriceDAC"
    DirectAirCapture.PriceDAC(DirectAirCapture.Data(; db,year,current,prior,next,CTime))
  
    @info "ExeSegments - Supply Expenditures"
    Supply.Expenditures(Supply.Data(; db,year,prior,next,CTime))
  end 
   
end

function RunControl(data)

end

function RunModel(data,ProcSw,RunTime)
  (;db) = data 
  (;ProcSw) = data
  
  CTime = max(ITime,STime)
  while CTime <= RunTime
    current = CTime-ITime+1
    year = current
    prior = max(1,current-1)
    next = current+1
    @info "RunModel - Executing for $CTime"
  
    @info "RunModel - Supply Control"
    Supply.Control(Supply.Data(; db,year,prior,next,CTime),ProcSw)  
    
    @info "RunModel - SuPollution PollutionTotals"
    SuPollution.PollutionTotals(SuPollution.Data(; db,year,prior,next,CTime))

    CTime = CTime+1
  end

end  

function NewRunModel(data,seg,RunTime)
  (;DACTechDS,FuelEP,H2TechDS,Nation,Nations,TechDS,Year) = data
  
  DoneG = 1
  CIt = 1
  PIt = max(CIt-1,1)
  NIt = CIt+1
  
  #
  # This procedure runs the supply model after calibration to fill
  # in the historical data for the oil, gas, coal, and other supply
  # sectors.  We may be able to replace RunModel with this procedure
  # after we check if it runs the calibraton properly. J. Amlin 5/14/02
  #
  CTime = ITime
  STime = ITime+1
  while CTime <= RunTime
    CTime = max(CTime,STime)   
    current = CTime-ITime+1
    year = current
    prior = max(1,current-1)
    next = current+1
    
    @info "NewRunModel - Executing for $CTime"
    
    ExeSegments(data,seg,year,prior,next,CTime,current,CIt,NIt,PIt,DoneG)
    
    CTime = CTime+1
  end
  
end

function SCalibEntire(db)
  data = DataSControl(; db)
  (;PIs) = data
  (;AccountsKey,LoadcurveKey,DailyUseKey) = data
  (;Endogenous,NonExist,ProcSw,xProcSw) = data

  @info "SCalibEntire - Executing Price Calibration"
  
  RunTime = MaxTime
  
  SInitial.Control(SInitial.Data(;db))

  SCalib.Coefficient(SCalib.Data(;db))

  SFuture.FutCal(SFuture.Data(;db))
  
  for p in PIs
    ProcSw[p] = xProcSw[p,1]
  end
  ProcSw[AccountsKey] = Endogenous
  ProcSw[LoadcurveKey] = NonExist
  ProcSw[DailyUseKey] = NonExist

  RunModel(data,ProcSw,RunTime)
end

function SCalibEntirePrices(db)
  data = DataSControl(; db)
  (;PIs) = data
  (;AccountsKey,LoadcurveKey,DailyUseKey) = data
  (;Endogenous,NonExist,ProcSw,xProcSw) = data

  @info "SCalibEntire - Executing Price Calibration"
  
  RunTime = MaxTime
  
  for p in PIs
    ProcSw[p] = xProcSw[p,1]
  end
  ProcSw[AccountsKey] = NonExist
  ProcSw[LoadcurveKey] = NonExist
  ProcSw[DailyUseKey] = NonExist

  RunModel(data,ProcSw,RunTime)
end



function SLoadCalib(db,RunTime,CalSw,OPSw)
  data = DataSControl(; db)
  (;db) = data
  (;PIs) = data
  (;AccountsKey,Endogenous,LoadcurveKey,ProcSw,xProcSw) = data
  
  @info "SControl.jl - SLoadCalib Loadcurve Calibration CalSw=$CalSw OPSw=$OPSw"
  
  True = 1
  False = 0

  if (CalSw == False) && (OPSw == False)
    SCalib.LEInitial(SCalib.Data(;db))
        
  elseif (CalSw >= True) && (OPSw == False)  
    SCalib.LECalib(SCalib.Data(;db))  

  else (CalSw >= True) && (OPSw == True)
    @. ProcSw = 0
    ProcSw[AccountsKey] = Endogenous
    ProcSw[LoadcurveKey] = Endogenous
    RunTime = HisTime
    RunModel(data,ProcSw,RunTime)
    for p in PIs
      ProcSw[p] = xProcSw[p,1]
    end
    RunTime = MaxTime
  end

end

function DailyCalib(data)

end

function OilGasCalibration(data)
  (;DACTechDS,H2TechDS) = data
  (;TechDS) = data
  (;DACTechDS,H2TechDS,TechDS) = data

end

function CallNewRunModel(db,RunTime)
   data = DataSControl(; db)
  (;db) = data
  (;DACTechDS,FuelEP,FuelEPs,H2TechDS,Nation,Nations,TechDS,Year,Years) = data   
  (;PIs,Seg) = data
  (;AccountsKey,LoadcurveKey,DailyUseKey,PriceKey) = data
  (;Endogenous,NonExist,ProcSw,xProcSw) = data

  seg = Select(Seg,"Supply") 

  for p in PIs
    ProcSw[p] = xProcSw[p,1]
  end

  ProcSw[AccountsKey] = Endogenous
  ProcSw[LoadcurveKey] = NonExist
  ProcSw[DailyUseKey] = NonExist
  ProcSw[PriceKey] = NonExist   

  NewRunModel(data,seg,RunTime)
  
end

function PostSupply(db)

  RunTime = MaxTime
  CallNewRunModel(db,RunTime)
end

function SCalibPrices(db)
  
  @info "SCalibPrices - Executing Price Calibration"
  
   data = DataSControl(; db)
  (;db) = data
  (;Areas,ECCs,ES,Fuel,Years) = data
  (;EEConv,FPF,PE,SecMap,xPE,xInflation) = data
  
  #
  # GetScenarioName
  #
  # SCalibEntire
  # 
  # Exogenous electric prices for future
  # to calibrate oil and gas sector for Canada
  # 
  for year in Years, area in Areas, ecc in ECCs
    PE[ecc,area,year] = xPE[ecc,area,year]*xInflation[area,year]
  end
  
  fuel = Select(Fuel,"Electric")
  
  Res = 1
  es = Select(ES,"Residential")
  eccs = findall(SecMap .== Res)
  ecc = first(eccs)
  for year in Years, area in Areas
    FPF[fuel,es,area,year] = PE[ecc,area,year]/EEConv*1000
  end  
  
  Com = 2
  es = Select(ES,"Commercial")
  eccs = findall(SecMap .== Com)
  ecc = first(eccs)
  for year in Years, area in Areas
    FPF[fuel,es,area,year] = PE[ecc,area,year]/EEConv*1000
  end    

  Ind = 3
  es = Select(ES,"Industrial")
  eccs = findall(SecMap .== Ind)
  ecc = first(eccs)
  for year in Years, area in Areas
    FPF[fuel,es,area,year] = PE[ecc,area,year]/EEConv*1000
  end  

  WriteDisk(db,"SOutput/FPF",FPF)
  WriteDisk(db,"SOutput/PE",PE)
  
end
