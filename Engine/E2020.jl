#
# E2020.jl
#

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,STime,HisTime,MaxTime,First,Future,Final,DT,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

#
# *************************
#  Single Year
# *************************
# *
function SingleYear(; db,year,prior,next,current,CTime,CIt,NIt,PIt,DoneG,SceName,silent = false,write = false)
  #
  # Write ("2020.src - SingleYear")
  #
  # RandomConstants
  #
  # Message for Promula screen
  #
  @info "SingleYear - Executing for $SceName for $CTime"
  #
  # Write (" Running ",ModelName::0," ",SceName::0," ",CTime::0," Iter ",CIt::0)
  #
  # Write ("2020.src - SingleYear, Initialize Electric Units")
  #
  @info "$CTime - EDispatch - InitializeDispatch"
  EDispatch.InitializeDispatch(EDispatch.Data(; db,year,prior,next,CTime))

  @info "$CTime - EPollution - InitializePollution"
  EPollution.InitializePollution(EPollution.Data(; db,year,prior,next,CTime))

  @info "$CTime - ECapacityExpansion InitializeCapacityExpansion"
  ECapacityExpansion.InitializeCapacityExpansion(ECapacityExpansion.Data(;db,year,current,prior,next,CTime))

  #
  # Write ("2020.src - SingleYear, CFS Prices")
  #
  @info "$CTime - SuPollutionCFS CFSPrices"
  SuPollutionCFS.CFSPrices(SuPollutionCFS.Data(; db,year,prior,next,CTime))

  #
  # Write ("2020.src - SingleYear, OGEC Prices")
  #
  @info "$CTime - SuPollutionOGEC OGECPrices"
  SuPollutionOGEC.OGECPrices(SuPollutionOGEC.Data(; db,year,prior,next,CTime))

  #
  # Write ("2020.src - SingleYear, Electric Prices")
  #
  # Select Seg(Electric)
  # Do If ((SegSw(Electric) NE NonExist) AND (SegSw(Electric) ne PreCalc))
  @info "$CTime - ElectricPrice - ElectricFuelPrices"
  ElectricPrice.ElectricFuelPrices(ElectricPrice.Data(; db,year,prior,next,CTime))
  #End Do If SegSw

  #
  # Write ("2020.src - SingleYear, Oil and Gas Prices")
  #
  @info "$CTime - SpRefinery OilDeliveredPrice"
  SpRefinery.OilDeliveredPrice(SpRefinery.Data(; db,year,prior,next,CTime))
  @info "$CTime - SpGas GasDeliveredPrices"
  SpGas.GasDeliveredPrices(SpGas.Data(; db,year,prior,next,CTime))

  #
  # Write ("2020.src - SingleYear, Macroeconomic Module")
  # The following is for Inflation (needs to be split) - Jeff Amlin 8/6/23
  #
  @info "$CTime - MEconomy Control"
  MEconomy.Control(MEconomy.Data(; db,year,current,prior,next,CTime))

  #
  # Write ("2020.src - SingleYear, Industrial Enduse Prices ",Yrv)
  #
  @info "$CTime - IDemand EuPrices"
  IDemand.EuPrices(IDemand.Data(; db,year,prior,next,CTime,SceName))

  #
  # Write ("2020.src - SingleYear, Oil Refining")
  #
  @info "$CTime - SpRefinery Control"
  SpRefinery.Control(SpRefinery.Data(; db,year,prior,next,CTime))

  #
  # Write ("2020.src - SingleYear, Oil and Gas Production")
  #
  @info "$CTime - SpOGProd Control"
  SpOGProd.Control(SpOGProd.Data(; db,year,prior,next,CTime))

  @info "$CTime - SpOProd Control"
  SpOProd.Control(SpOProd.Data(; db,year,prior,next,CTime))

  @info "$CTime - SpGas Control"
  SpGas.Control(SpGas.Data(; db,year,prior,next,CTime))

  #
  # The following is for the Driver (needs to be split) - Jeff Amlin 8/6/23
  #
  @info "$CTime - MEconomyTOM Control"
  MEconomyTOM.Control(MEconomyTOM.Data(; db,year,current,prior,next,CTime))

  @info "$CTime - MEconomy Control"
  MEconomy.Control(MEconomy.Data(; db,year,current,prior,next,CTime))
  
  #   Read Disk(Logsw)

  #
  # Write ("2020.src - SingleYear, CCS Initiaion")
  #
  # Select Seg(MEconomy)
  #
  @info "$CTime - MPollution CCSInitiation"
  MPollution.CCSInitiation(MPollution.Data(; db,year,prior,next,CTime))

  #
  # Write ("2020.src - SingleYear,Energy Demand")
  #

  #
  # Select Seg(Residential)
  #
  @info "$CTime - Residential - Control"
  RDemand.Control(RDemand.Data(; db,year,prior,next,CTime,SceName))

  #
  # Select Seg(Commercial)
  #
  @info "$CTime - Commercial - Control"
  CDemand.Control(CDemand.Data(; db,year,prior,next,CTime,SceName))

  #
  # Select Seg(Industrial)
  #
  @info "$CTime - Industrial - Control"
  IDemand.Control(IDemand.Data(; db,year,prior,next,CTime,SceName))

  @info "$CTime - Transportation - Control"
  TDemand.Control(TDemand.Data(; db,year,prior,next,CTime,SceName))

  @info "$CTime - TDemand2 - NumberOfVehicles"
  TDemand2.NumberOfVehicles(TDemand2.Data(; db,year,prior,next,CTime,SceName))

  #
  # Write ("2020.src - SingleYear, Industrial Unit Electric Generation")
  #

  @info "$CTime - ECapacityExpansion CgCtrl"
  ECapacityExpansion.CgCtrl(ECapacityExpansion.Data(; db,year,current,prior,next,CTime))

  @info "$CTime - EDispatchCg - CgProduction"
  EDispatchCg.Control(EDispatchCg.Data(; db,year,prior,next,CTime))

  # Write ("2020.src - SingleYear, Total Demands and Pollution")
  # These are run after Electric for cogeneration demands and pollution

  @info "$CTime - Residential - RunAfterCogeneration"
  RDemand.RunAfterCogeneration(RDemand.Data(; db,year,prior,next,CTime,SceName))

  @info "$CTime - Commercial - RunAfterCogeneration"
  CDemand.RunAfterCogeneration(CDemand.Data(; db,year,prior,next,CTime,SceName))

  @info "$CTime - Industrial - RunAfterCogeneration"
  IDemand.RunAfterCogeneration(IDemand.Data(; db,year,prior,next,CTime,SceName))
  
  @info "$CTime - Transport - RunAfterCogeneration"
  TDemand.RunAfterCogeneration(TDemand.Data(; db,year,prior,next,CTime,SceName))

  @info "$CTime - TDemand2 - ProcessEmissions"
  TDemand2.ProcessEmissions(TDemand2.Data(; db,year,prior,next,CTime,SceName))

  @info "$CTime - TDemand2 - LowCarbonCredits"
  TDemand2.LowCarbonCredits(TDemand2.Data(; db,year,prior,next,CTime,SceName))

  #
  # Write ("2020.src - SingleYear, Load Curve and Miscellaneous Demand Sectors")
  #

  @info "$CTime - RLoad - Control"
  RLoad.Control(RLoad.Data(; db,year,prior,next,CTime))

  @info "$CTime - CLoad - Control"
  CLoad.Control(CLoad.Data(; db,year,prior,next,CTime))

  @info "$CTime - ILoad - Control"
  ILoad.Control(ILoad.Data(; db,year,prior,next,CTime))

  @info "$CTime - TLoad - Control"
  TLoad.Control(TLoad.Data(; db,year,prior,next,CTime))

  #
  # Begin ExeSegments SegKey eq "Loadcurve" in SControl, Do(RunControl) 
  #

  @info "$CTime - Hydrogen Supply"
  SpHydrogen.SupplyHydrogen(SpHydrogen.Data(; db,year,prior,next,CTime))

  @info "$CTime - DirectAirCapture SupplyDAC"
  DirectAirCapture.SupplyDAC(DirectAirCapture.Data(; db,year,current,prior,next,CTime))

  @info "$CTime - Supply ExoSalesNonElectric"
  Supply.ExoSalesNonElectric(Supply.Data(; db,year,prior,next,CTime))

  @info "$CTime - Supply ExoElectricSalesAndLoadCurve"
  Supply.ExoElectricSalesAndLoadCurve(Supply.Data(; db,year,prior,next,CTime))

  @info "$CTime - Supply RestOfWorldLoadCurve"
  Supply.RestOfWorldLoadCurve(Supply.Data(; db,year,prior,next,CTime))

  @info "$CTime - Supply LoadCurve"
  Supply.LoadCurve(Supply.Data(; db,year,prior,next,CTime))

  @info "$CTime - Supply SteamSupply"
  Supply.SteamSupply(Supply.Data(; db,year,prior,next,CTime))

  @info "$CTime - Supply DailyUse"
  Supply.DailyUse(Supply.Data(; db,year,prior,next,CTime))

  #
  # End ExeSegments SegKey eq "Loadcurve" in SControl, Do(RunControl) 
  #

  # 
  # Write ("2020.src - SingleYear, Electric Utility Sector")
  # 
  # Begin Segment EControl, Do(RunControl)
  #
  # Electric Loads
  #
  @info "$CTime - ELoadCurve - ElecLoadCurvesAndSales"
  ELoadCurve.ElecLoadCurvesAndSales(ELoadCurve.Data(; db,year,prior,next,CTime));
  #
  # Load,Capacity Expansion, Construction, Pollution Costs
  #
  #
  # Begin RCtrl1 in Segment EControl, Do(RunControl)
  # 
  @info "$CTime - EPollution - Part1"
  EPollution.Part1(EPollution.Data(; db,year,prior,next,CTime))

  @info "$CTime - ECapacityExpansion Ctrl"
  ECapacityExpansion.Ctrl(ECapacityExpansion.Data(; db,year,current,prior,next,CTime))

  # 
  # End RCtrl1 in Segment EControl, Do(RunControl)
  # 

  # 
  # Loads, Generation, Fuel Use, Pollution Emitted
  # 

  #
  # Begin PControl in Segment EControl, Do(RunControl)
  #
  @info "$CTime - ECosts"
  ECosts.Costs(ECosts.Data(; db,year,prior,next,CTime))

  @info "$CTime - EPeakHydro"
  EPeakHydro.HydroControl(EPeakHydro.Data(; db,year,prior,next,CTime))

  @info "$CTime - EDispatch - DispatchElectricity"
  EDispatch.DispatchElectricity(EDispatch.Data(; db,year,prior,next,CTime))

  @info "$CTime - EDispatch - EGenerationSummary"
  EGenerationSummary.GenSummary(EGenerationSummary.Data(; db,year,prior,next,CTime))

  @info "$CTime - EFlows"
  EFlows.Flows(EFlows.Data(; db,year,prior,next,CTime))

  @info "$CTime - EFuelUsage - RunFuelUsage"
  EFuelUsage.RunFuelUsage(EFuelUsage.Data(; db,year,prior,next,CTime))

  @info "$CTime - EPollution - Part2"
  EPollution.Part2(EPollution.Data(; db,year,prior,next,CTime))
  
  #
  # End PControl in Segment EControl, Do(RunControl)
  #

  #
  # Begin ERAControl in Segment EControl, Do(RunControl)
  #
  @info "$CTime - EContractDevelopment - DevelopContracts"
  EContractDevelopment.DevelopContracts(EContractDevelopment.Data(; db,year,prior,next,CTime))

  @info "$CTime - ERetailPurchases - RetailPurchases"
  ERetailPurchases.RetailPurchases(ERetailPurchases.Data(; db,year,prior,next,CTime))
  
  #
  # End ERAControl in Segment EControl, Do(RunControl)
  #

  # 
  # Begin ERRControl in Segment EControl, Do(RunControl)
  #
  if CTime > 1990

    @info "$CTime - ERetailPowerCosts - ElectricCosts"
    ERetailPowerCosts.ElectricCosts(ERetailPowerCosts.Data(; db,year,prior,next,CTime))

    @info "$CTime - ElectricPrice - Finance"
    ElectricPrice.Finance(ElectricPrice.Data(; db,year,prior,next,CTime))

  end
  
  # 
  # End ERRControl in Segment EControl, Do(RunControl)
  #


  #
  # TODOTIM activate TDemand2, MacroOutput - Jeff 12.28.23
  #
  
  # @info "$CTime - TDemand2 - MacroOutput"
  
  #
  # TDemand2.MacroOutput(TDemand2.Data(; db,year,prior,next,CTime,SceName))  
  #

  # 
  # Write ("2020.src - SingleYear, Non-Energy Pollution")
  # 
  # Begin MControl, Do(PollControl)
  # 
  @info "$CTime - MReductions - CtrlReductions"
  MReductions.CtrlReductions(MReductions.Data(; db,year,prior,next,CTime))

  @info "$CTime - MPollution - Reductions"
  MPollution.Reductions(MPollution.Data(; db,year,prior,next,CTime))

  @info "$CTime - MPollution - CtrlPollution"
  MPollution.CtrlPollution(MPollution.Data(; db,year,prior,next,CTime))

  @info "$CTime - MEWaste - Control"
  MEWaste.Control(MEWaste.Data(; db,year,prior,next,CTime))

  @info "$CTime - MPollution - GrossProcessEmissions"
  MPollution.GrossProcessEmissions(MPollution.Data(; db,year,prior,next,CTime))
  
  #
  # End MControl, Do(PollControl)
  #

  # 
  # Write ("2020.src - SingleYear, Supply Sectors and Energy Prices (for next year)")
  #
  # Begin ExeSegments SegKey eq "Supply" in SControl, Do(RunControl) 
  # 
  @info "$CTime - Coal Supply"
  SpCoal.Control(SpCoal.Data(; db,year,prior,next,CTime))

  if CTime <= HisTime

    @info "$CTime - SpRefinery Control"
    SpRefinery.Control(SpRefinery.Data(; db,year,prior,next,CTime))

    @info "$CTime - SpOGProd Control"
    SpOGProd.Control(SpOGProd.Data(; db,year,prior,next,CTime))

    @info "$CTime - SpGas Control"
    SpGas.Control(SpGas.Data(; db,year,prior,next,CTime))

    @info "$CTime - SpOProd Control"
    SpOProd.Control(SpOProd.Data(; db,year,prior,next,CTime))

  end

  #
  # TODOLater translate SpGTrans - Jeff 12.28.23
  #
  
  # @info "$CTime - SpGTrans Control"
  
  #
  # SpGTrans.Control()
  #

  #
  # TODOLater translate SpRef - Jeff 12.28.23
  #
  
  # @info "$CTime - SpRef Control"
  
  #
  # SpRef.Control()
  #

  #
  # TODOLater add BiofuelSwitch - Jeff 12.28.23
  # if BiofuelSwitch eq 1
  #
      @info "$CTime - SpBiofuel SupplyBiofuel"
      SpBiofuel.SupplyBiofuel(SpBiofuel.Data(; db,year,prior,next,CTime))
  
  #
  # else
    # TODOLater translate SpEthanol - Jeff 12.28.23
    # @info "$CTime - SpEthanol EthanolSupply"
    # SpEthanol.EthanolSupply(SpEthanol.Data(; db,year,prior,next,CTime))
  # end

  @info "$CTime - SpImportsExports Control"
  SpImportsExports.Control(SpImportsExports.Data(; db,year,prior,next,CTime))

  @info "$CTime - Supply Accounts"
  Supply.Accounts(Supply.Data(; db,year,prior,next,CTime))

  @info "$CTime - SuPollution PollutionTotals"
  SuPollution.PollutionTotals(SuPollution.Data(; db,year,prior,next,CTime))

  @info "$CTime - SuPollutionEI Control"
  SuPollutionEI.Control(SuPollutionEI.Data(; db,year,prior,next,CTime))

  @info "$CTime - SuPollutionCFS Control"
  SuPollutionCFS.Control(SuPollutionCFS.Data(; db,year,prior,next,CTime))
  
  @info "$CTime - SuPollutionOGEC Control"
  SuPollutionOGEC.Control(SuPollutionOGEC.Data(; db,year,prior,next,CTime))

  @info "$CTime - SuPollutionMarket Control"
  SuPollutionMarket.Control(SuPollutionMarket.Data(;db,year,prior,next,CTime),CIt,NIt,PIt,DoneG)

  @info "$CTime - SuPollutionCFS CFSCredits"
  SuPollutionCFS.CFSCredits(SuPollutionCFS.Data(; db,year,prior,next,CTime))

  @info "$CTime - Coal Price"
  SpCoal.CoalPrice(SpCoal.Data(; db,year,prior,next,CTime))

  @info "$CTime - SpOProd OilPrice"
  SpOProd.OilPrice(SpOProd.Data(; db,year,prior,next,CTime))

  @info "$CTime - SpGas GasPrice"
  SpGas.GasPrice(SpGas.Data(; db,year,prior,next,CTime))

  #
  # TODOLater translate SpFuelSupplyCurve - Jeff 12.28.23
  #
  
  @info "$CTime - SpFuelSupplyCurve Control"
  SpFuelSupplyCurve.Control(SpFuelSupplyCurve.Data(; db,year,prior,next,CTime))

  @info "$CTime - Supply Price"
  Supply.Price(Supply.Data(; db,year,prior,next,CTime))

  #
  # TODOLater add BiofuelSwitch - Jeff 12.28.23
  # if BiofuelSwitch eq 1
  #
    @info "$CTime - SpBiofuel PriceBiofuel"
    SpBiofuel.PriceBiofuel(SpBiofuel.Data(; db,year,prior,next,CTime))
  # else
    # TODOLater translate SpEthanol - Jeff 12.28.23
    # @info "$CTime - SpEthanol PriceEthanol"
    # SpEthanol.PriceEthanol(SpEthanol.Data(; db,year,prior,next,CTime))
  # end

  @info "$CTime - Hydrogen Price"
  SpHydrogen.PriceHydrogen(SpHydrogen.Data(; db,year,prior,next,CTime))

  @info "$CTime - DirectAirCapture PriceDAC"
  DirectAirCapture.PriceDAC(DirectAirCapture.Data(; db,year,current,prior,next,CTime))

  @info "$CTime - Supply Expenditures"
  Supply.Expenditures(Supply.Data(; db,year,prior,next,CTime))

  #
  # End ExeSegments SegKey eq "Supply" in SControl, Do(RunControl)
  #
end # Procedure SingleYear

# 
# *****************************
#
function ModelIterate(; db,year,prior,next,current,CTime,SceName,silent = false,write = false)
  @info " "
  @info "ModelIterate - Executing $SceName for $CTime"
 
  # 
  # Write ("2020.src - ModelIterate")
  # 
  Market::SetArray = ReadDisk(db,"MainDB/MarketKey")
  Markets::Vector{Int} = collect(Select(Market))
  MaxIter::Float32 = ReadDisk(db,"SInput/MaxIter")[1] # [tv] Maximum Number of Iterations  
  RunExtra::Float32 = ReadDisk(db,"SInput/RunExtra")[1] # [tv] Run Extra Iteration?  
  DoneM::VariableArray{1} = ReadDisk(db,"SOutput/DoneM") #[Market]  Market Done Switch (0 = Done)

  #
  # Initalize Loop
  #
  DoneG = 1  # DoneG - All Markets have converged when DoneG equals 0
  CIt = 1    # CIt - Current iteration
  NIt = 2    # NIt - Next Iteration
  PIt = 1    # PIt - Privious Iteration
  MaxIter = max(MaxIter,1)
    
  #
  # Write ("2020.src - Initialize Permit Market Prices")
  #
  @info "$CTime - ModelIterate - SuPollutionMarket - InitializeMarkets"
  SuPollutionMarket.InitializeMarkets(SuPollutionMarket.Data(; db,year,prior,next,CTime))
  @info "$CTime - ModelIterate - ImpactOnFuelPrices"
  SuPollutionMarket.ImpactOnFuelPrices(SuPollutionMarket.Data(; db,year,prior,next,CTime))
  @info "$CTime - ModelIterate - CapControl"
  SuPollutionMarket.CapControl(SuPollutionMarket.Data(; db,year,prior,next,CTime),CIt,NIt,PIt)
  
  #
  # Loop until prices converge in all markets
  #
  while (DoneG > 0) && (CIt <= MaxIter)
  
    #
    # Previous Iteration
    #
    PIt = max(CIt-1,1)
    
    #
    # Next Iteration
    #
    NIt = CIt+1
    
    SingleYear(; db,year,prior,next,current,CTime,CIt,NIt,PIt,DoneG,SceName,silent,write)
  
    CIt = CIt+1
  
    DoneG = sum(DoneM[market] for market in Markets)
  end

  #
  # We need to execute the model twice for a variety of reasons
  # including fixed emission caps, final emission prices, and
  # EOR from sequestering.  J. Amlin 5/30/14
  #
  if RunExtra == 1
    SingleYear(; db,year,prior,next,current,CTime,CIt,NIt,PIt,DoneG,SceName,silent,write)
  end
  
  #
  # Write ("2020.src - Final Market Calculations")
  #
  @info "$CTime - ModelIterate - FinalizeMarkets"
  SuPollutionMarket.FinalizeMarkets(SuPollutionMarket.Data(; db,year,prior,next,CTime))
  
end # Procedure ModelIterate


function Model(db,BTime,EndTime,SceName; silent = false,write = false)
  #
  # Model Simulation Routine
  #
  
  #
  # Increment Iteration (use LogSw as test)
  #
  @info "Model - Executing $BTime to $EndTime for $SceName"

  #
  # Starting Year
  #
  CTime = BTime

  #
  # Ending Year
  #
  EndTime = min(EndTime,MaxTime)
  Ending = EndTime
  EndYear = EndTime-ITime+1

  while CTime <= Ending

    #
    # Time variables for year being simulated
    #
    current = CTime-ITime+1
    year = current
    prior = max(1,current-1)
    next = current+1

    #
    # Run a single year of the model
    #
    ModelIterate(; db,year,prior,next,current,CTime,SceName,silent,write)

    CTime = CTime+1

  end # while CTime <= Ending
end # Procedure Model
