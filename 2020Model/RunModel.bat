rem
rem  RunModel.bat
rem  
rem  %1 - Value of Debug Flag (either "Debug" or "Fast")
rem
     md log
     Echo ENERGY 2100 Model RunModel      > RunModel_Report.log
     Echo Version:     %cd%              >> RunModel_Report.log
     Echo Computer:    %computername%    >> RunModel_Report.log
     Echo %Date% ;%Time%; Start RunModel >> RunModel_Report.log
rem

     Set DebugFlag=Fast
     If [%1] == [] GoTo EndDebug
       Set DebugFlag=%1      
     :EndDebug
     
     Call UnZip DB Process
     
     Call RunJulia StartScenario.jl Process2 Process2 Process2 Process2 Process2 Process2 Process2
          
     cd..\Input\Scripts
       Call RunJulia Maps.jl
     cd..\..\2020Model
     
rem
rem  Process economic variables and calibrate MEconomy to create xDriver
rem  and xExchangeRateNation 1/5/26 R.Levesque and Jeff Amlin 1/9/26
rem
     cd..\Input\Scripts         
       Call RunJulia EconomicDrivers_VB.jl
     cd..\..\2020Model
     
     cd..\Calibration      
       Call RunJulia TransLifetimes.jl     
       Call RunJulia OffsetReductions.jl 
       Call RunJulia Offsets_Forestry.jl
       Call RunJulia Offsets_NERAgriculture.jl
       Call RunJulia Offsets_LandfillGas.jl   
       Call RunJulia Offsets_AerobicComposting.jl
       Call RunJulia Offsets_AnaerobicWWT.jl
       Call RunJulia Offsets_AnaerobicDecomposition.jl
       Call RunJulia Offsets_WoodBiomass.jl    
       Call RunJulia Offsets_History_AB.jl
       Call RunJulia MCalibRun.jl

rem
rem  Build Nonconfidential Version
rem
rem  cd..\2020Model 
rem  Call BreakPoint Confidential
rem  rd /s/q out
rem  md out        
rem  cd..\Calibration       
rem    Call RunJulia DemandNonConfidential_All.jl
rem  cd..\2020Model 
rem  Copy .\out\*.* .\Confidential
rem  Call Zip Results Confidential\Confidential_DTAs .\Confidential\*.dta         

     cd..\Input\Scripts  
       Call RunJulia DeviceSaturation_VB_Res.jl
       Call RunJulia DeviceSaturation_VB_Com.jl
       Call RunJulia DeviceSaturation_VB_Ind.jl
       Call RunJulia DeviceSaturation_VB_Trans.jl
       Call RunJulia EnergyDemand_VB_Res.jl
       Call RunJulia EnergyDemand_VB_Com.jl
       Call RunJulia EnergyDemand_VB_Ind.jl
       Call RunJulia EnergyDemand_VB_Trans.jl
       
       Call RunJulia DmFrac_Calc_Res.jl
       Call RunJulia DmFrac_Calc_Com.jl
       Call RunJulia DmFrac_Calc_Ind.jl
       Call RunJulia DmFrac_Calc_Trans.jl
     
       Call RunJulia NodeExchangeAndInflation.jl
       Call RunJulia DeviceInputs_VB.jl
       Call RunJulia CurTime.jl
     cd..\..\2020Model
     
     cd..\Calibration        
rem    Call RunJulia Adjust_DeviceInputs.jl
       Call RunJulia Adjust_DeviceInputs_Solar.jl
       Call RunJulia Adjust_DeviceInputs_Ind_HeatPump.jl
       Call RunJulia DeviceThermalMaxEfficiency.jl
       Call RunJulia GeothermalHeatPumpDemands.jl
       Call RunJulia AdjustDeviceCapitalCosts_TOM.jl
       Call RunJulia Adjust_ResPatchAttached.jl
     cd..\2020Model    
       
     cd..\Input\Scripts     
       Call RunJulia GHG_VB_Res.jl     
       Call RunJulia GHG_VB_Com.jl     
       Call RunJulia GHG_VB_Ind.jl     
       Call RunJulia GHG_VB_Trans.jl     
       Call RunJulia GHG_VB_ElecUtility.jl
       Call RunJulia GHG_VB_RCI.jl     
     
       Call RunJulia CAC_VB_RCI.jl          
       Call RunJulia CAC_VB_Trans.jl  
       Call RunJulia CAC_VB_ElecUtility.jl
       Call RunJulia CAC_VB_ReductionCurves.jl
     
       Call RunJulia GasOilSupply_VB.jl
       Call RunJulia CoalSupply_VB.jl
       Call RunJulia LNGProduction_VB.jl
       Call RunJulia NGTransmission_VB.jl
       Call RunJulia FlowFraction_VB.jl
     
       Call RunJulia DeliveredPrices_VB_US.jl
       Call RunJulia DeliveredPricesFuelSet_VB.jl 
      cd..\..\2020Model      
   
      cd..\Calibration          
       Call RunJulia Adjust_DeliveredPricesFuelSet_VB.jl
     cd..\2020Model       
     
     cd..\Input\Scripts         
       Call RunJulia DeliveredPrices_US.jl
       Call RunJulia DeliveredPrices_MX.jl     
       Call RunJulia WholesalePrices_VB.jl   
       Call RunJulia WholesalePrices_AEO.jl  
      cd..\..\2020Model      
   
      cd..\Calibration    
       Call RunJulia WholesalePrices_Revisions.jl
       Call RunJulia AdjustDeliveredPrices.jl  
       Call RunJulia DeliveredPricesByFuel.jl       
       Call RunJulia ElectricPricesMove.jl 
     cd..\2020Model       
     
     cd..\Input\Scripts       
       Call RunJulia Elec_SalesPurch_VB.jl
       Call RunJulia ElectricGeneration_VB.jl
       Call RunJulia ElectricUtilityFuelUse_VB.jl
       Call RunJulia ElectricPlantCharacteristics_VB.jl
       Call RunJulia Electric_Transmission_VB.jl
       Call RunJulia Electric_PeaksMinimumsOutputs_VB.jl
       Call RunJulia Energy_Flows_VB.jl
       Call RunJulia Transportation_VB.jl
       Call RunJulia VehicleStock_VB.jl
     cd..\..\2020Model            
       
     cd..\Calibration        
       Call RunJulia Adjust_Transportation_VB.jl
     cd..\2020Model       

     cd..\Input\Scripts         
       Call RunJulia Steam_VB.jl
       Call RunJulia CogenGeneration_VB.jl  
       Call RunJulia EconomicDrivers_VB.jl
       Call RunJulia Waste_VB.jl
       Call RunJulia Waste_Data.jl
       Call RunJulia ConversionFactors_VB.jl     
       Call RunJulia DegreeDay_VB.jl  
     
       Call RunJulia RefiningDefinitions_VB.jl
       Call RunJulia RfExchangeAndInflation.jl
       Call RunJulia RPP_ProductionImportsExports_VB.jl
       Call RunJulia OG_UnitDefinitions_VB.jl
       Call RunJulia OGExchangeAndInflation.jl
       Call RunJulia OG_UnitFinancialData_VB.jl
     
       Call RunJulia ImportEmissions_VB.jl
      cd..\..\2020Model            
       
     cd..\Calibration        
       Call RunJulia UnitCounter.jl         
       Call RunJulia UnitExchangeRate.jl     
       Call RunJulia UnitXSwitch.jl
     cd..\2020Model  
     
     If %DebugFlag%==Debug Call BreakPoint Process2
rem  Call CreateDTAs Process2 Process2 Process2 ExcelDTAs NoUnZip
rem  Call UnZip DB Process2 

     cd..\Calibration   
     
       Call RunJulia GasProcessing.jl
       Call RunJulia OG_Switches.jl
       Call RunJulia OG_UnitProduction.jl
       Call RunJulia OG_Resources.jl     
       Call RunJulia OG_NGLiquidsFraction.jl  
       Call RunJulia OG_ProductionCosts.jl    
       Call RunJulia TotalDemands.jl
       Call RunJulia CoalSupplyBalance.jl   
     
       Call RunJulia ScaleMissingGrossOutput_TOM.jl
       Call RunJulia EconomicDriverSwitches.jl
       Call RunJulia EconomicDrivers_ProcessTOM.jl
       Call RunJulia EconomicDrivers_ApplyAEO.jl
     
       Call RunJulia GHG_Energy_US.jl
       Call RunJulia FixPetroCoke_CA.jl  
       Call RunJulia GHG_Transportation_CA.jl
       Call RunJulia GHG_Feedstocks_US.jl
       Call RunJulia GHG_Energy_MX.jl
       Call RunJulia GHG_Feedstocks_MX.jl
       Call RunJulia GHG_Energy_RNG.jl  
     
       Call RunJulia TransLifetimes.jl     
       Call RunJulia OffsetReductions.jl 
       Call RunJulia Offsets_Forestry.jl
       Call RunJulia Offsets_NERAgriculture.jl
       Call RunJulia Offsets_LandfillGas.jl   
       Call RunJulia Offsets_AerobicComposting.jl
       Call RunJulia Offsets_AnaerobicWWT.jl
       Call RunJulia Offsets_AnaerobicDecomposition.jl
       Call RunJulia Offsets_WoodBiomass.jl    
       Call RunJulia Offsets_History_AB.jl

       Call RunJulia Demand_AlignToGO_Com_US.jl
       Call RunJulia Demand_AllocateSectors_Ind_US.jl
       Call RunJulia TotalDemands.jl  
       Call RunJulia EconomicDrivers_Gas.jl

     cd..\2020Model  
     If %DebugFlag%==Debug Call BreakPoint Process3
rem  Call CreateDTAs Process3 Process3 Process3 ExcelDTAs NoUnZip    
rem  Call CompareDatabase Process3
rem  Call UnZip DB Process3 
     Call RunJulia StartScenario.jl Calib Calib Calib Calib Calib Calib Calib
     
     cd..\Calibration       
       Call RunJulia CalibSettings.jl
       Call RunJulia AdjustInitialYear.jl
       Call RunJulia AdjustSteamHeatRate.jl
       Call RunJulia SteamProduction.jl
       Call RunJulia DmFracDefault.jl
       Call RunJulia DmFracMaximum.jl

       Call RunJulia SCalibRun.jl
       Call RunJulia Adjust_FPDChgF.jl
       Call RunJulia SCalibPricesRun.jl

     cd..\2020Model 
     If %DebugFlag%==Debug Call BreakPoint CalibPrice 
rem  Call CreateDTAs CalibPrice CalibPrice CalibPrice ExcelDTAs NoUnZip     
rem  Call UnZip DB CalibPrice
     Call RunJulia StartScenario.jl Calib Calib Calib Calib Calib Calib Calib     
     Echo %Date% ;%Time%; End Price Calibration  %computername% >> RunAll_Report.log
     
     cd..\Calibration       
       Call RunJulia EthanolBiodiesel.jl
       Call RunJulia Hydrogen.jl  
       Call RunJulia H2_CP_ImpactOnFuelFraction.jl
       Call RunJulia BiofuelSwitch.jl
       Call RunJulia CarbonRemoval.jl     
       Call RunJulia ImportsExportsMinimums.jl
       Call RunJulia MCalibRun.jl
 
       Call RunJulia CogenHeatRates.jl
       Call RunJulia CogenerationCapitalCost.jl
       Call RunJulia Hours.jl
       Call RunJulia ProcessCapitalCosts.jl
       Call RunJulia SolarEfficiencyByProvince.jl
       Call RunJulia ElectricLossFactors.jl    
       Call RunJulia AdjustLossFactors_SK.jl
       Call RunJulia AdjustEnergyDemands.jl
       Call RunJulia DeviceMaximumEfficiencyAdjust.jl
       Call RunJulia ZeroEmissionFraction.jl
       Call RunJulia AdjustProcessCapitalCosts_TOM.jl
   
       Call RunJulia EnergyDemands1985to1989.jl 
       Call RunJulia ScaleMissingGrossOutput_TOM.jl      
       Call RunJulia MCalibRun.jl
     cd..\2020Model 
     
     If %DebugFlag%==Debug Call BreakPoint CalibMEconomy
     Echo %Date% ;%Time%; End MEconomy Calibration %computername% >> RunAll_Report.log

     cd..\Calibration
     
       Call RunJulia AdjustTransFungible.jl
       Call RunJulia DemandTotals.jl      
       Call RunJulia IndCogenSoldToGrid.jl   
       Call RunJulia TransPassengerProcessEfficiency.jl  
       Call RunJulia ACSaturation_Res.jl     
       Call RunJulia ACSaturation_Com.jl
       Call RunJulia ACSaturation_Forecast.jl
       Call RunJulia ACSaturationCoefficients.jl
     
       Call RunJulia CCS_TaxRate.jl
       Call RunJulia CCS_CD.jl
       Call RunJulia CCS_EOR.jl
       Call RunJulia CCS_Penalty.jl
       Call RunJulia CCS_GHG.jl
       Call RunJulia DemandTrends.jl
       Call RunJulia HistoricalElectricLoads.jl
       Call RunJulia ElectricPeaksMinimumsAndOutputs_CN.jl  
       Call RunJulia PeakLoads_CA.jl

       Call RunJulia GHG_MacroEconomy_US.jl 
       Call RunJulia GHG_MacroEconomy_CA.jl  
       Call RunJulia GHG_Residential_CA.jl
       Call RunJulia ElectricImports.jl    
       Call RunJulia AdjustElectricImports.jl
       Call RunJulia UnitEmissions.jl
       Call RunJulia CoalRetirements_CA.jl
       Call RunJulia CarbonTaxReferenceEmissions.jl        
 
       Call RunJulia CT_AB_SGER_to_2017.jl
       Call RunJulia CarbonTax_OBA_AB.jl 
       Call RunJulia HFC_ReductionCurves_AB.jl
       Call RunJulia WCI_Market.jl
       Call RunJulia CFS_LiquidMarket_CA.jl    
       Call RunJulia CFS_LiquidPrice_CA.jl  
       Call RunJulia CarbonTax_BC.jl           
       Call RunJulia CarbonTax_NT.jl    
       Call RunJulia CarbonTax_Fed_170.jl  
       Call RunJulia CarbonTax_OBA_ON.jl
       Call RunJulia CarbonTax_OBA_NB.jl
       Call RunJulia CarbonTax_OBA_SK.jl           
       Call RunJulia CarbonTax_OBA_NL.jl     
       Call RunJulia CarbonTax_OBA_BC.jl
       Call RunJulia CarbonTax_OBA_NS.jl
       Call RunJulia CarbonTax_OBA_Fed_170.jl
     
       Call RunJulia EfficiencyPrograms_UOG.jl      
       Call RunJulia Trans_USForecast.jl
       Call RunJulia TransPassengerEffStd.jl
       Call RunJulia PavleyPhaseI_CA.jl  
       Call RunJulia AdjustLightingLoad.jl
       Call RunJulia ACRemoveProcessStandards.jl 
        
       Call RunJulia ResScrappageRates.jl
       Call RunJulia RInitialRun.jl
       Call RunJulia RInitialFungible.jl
       Call RunJulia RInitialFungibleFS.jl
       Call RunJulia RInitial_Adjust.jl   
       Call RunJulia Res_HistoricalProcessEfficiency.jl
       Call RunJulia RCalibRun.jl
       Call RunJulia Res_CalibrateProcessEfficiency.jl
       Call RunJulia RCalibSaturation.jl
       Call RunJulia Res_BldgStd.jl
       Call RunJulia RInitialRun.jl
       Call RunJulia RInitialFungible.jl             
       Call RunJulia RInitial_Adjust.jl
       Call RunJulia RCalibRun.jl   
       Call RunJulia RCalibFungible.jl
       Call RunJulia RCalibFungibleFS.jl

     cd..\2020Model 
     
     If Not %DebugFlag%==Debug GoTo EndCalibRes 
       Call BreakPoint CalibRes
       Call CreateDTAs CalibRes CalibRes CalibRes ExcelDTAs NoUnZip
rem    Call UnZip DB CalibRes
       Call RunJulia StartScenario.jl Calib Calib Calib Calib Calib Calib Calib
     :EndCalibRes       
     Echo %Date% ;%Time%; End Residential Calibration %computername% >> RunAll_Report.log

     cd..\Calibration       
       Call RunJulia ComScrappageRates.jl
       Call RunJulia CInitialRun.jl
       Call RunJulia CInitialFungible.jl
       Call RunJulia CInitialFungibleFS.jl
       Call RunJulia CInitial_Adjust.jl
       Call RunJulia Com_HistoricalProcessEfficiency.jl
       Call RunJulia  CCalibRun.jl
       Call RunJulia Com_CalibrateProcessEfficiency.jl
       Call RunJulia CCalibSaturation.jl
       Call RunJulia Com_BldgStd.jl     
       Call RunJulia CInitialRun.jl
       Call RunJulia CInitialFungible.jl             
       Call RunJulia CInitial_Adjust.jl
       Call RunJulia  CCalibRun.jl  
       Call RunJulia CCalibFungible.jl
       Call RunJulia CCalibFungibleFS.jl
     cd..\2020Model 
     
     If Not %DebugFlag%==Debug GoTo EndCalibCom  
       Call BreakPoint CalibCom 
       Call CreateDTAs CalibCom CalibCom CalibCom ExcelDTAs NoUnZip
rem    Call UnZip DB CalibCom
       Call RunJulia StartScenario.jl Calib Calib Calib Calib Calib Calib Calib     
     :EndCalibCom     
     Echo %Date% ;%Time%; End Commercial Calibration %computername% >> RunAll_Report.log

     cd..\Calibration  
     
       Call RunJulia IronSteel_EfficiencyInputs.jl
       Call RunJulia PulpPaper_EfficiencyInputs.jl
       Call RunJulia IndScrappageRates.jl

       Call RunJulia IInitialRun.jl
       Call RunJulia IInitialFungible.jl    
       Call RunJulia IInitialFungibleFS.jl 
       Call RunJulia IInitial_Adjust.jl
       Call RunJulia AdjustSAGDOilSands.jl
       Call RunJulia ICalibRun.jl 
       Call RunJulia ICalibFungible.jl     
       Call RunJulia ICalibFungibleFS.jl
     cd..\2020Model 
     
     Call BreakPoint CalibInd
     If Not %DebugFlag%==Debug GoTo EndCalibInd  
       Call CreateDTAs CalibInd CalibInd CalibInd ExcelDTAs NoUnZip
rem    Call UnZip DB CalibInd
       Call RunJulia StartScenario.jl Calib Calib Calib Calib Calib Calib Calib
     :EndCalibInd       
     Echo %Date% ;%Time%; End Industrial Calibration %computername% >> RunAll_Report.log

     cd..\Calibration       
       Call RunJulia TransScrappageRates.jl
       Call RunJulia Trans_MassTransit.jl
       Call RunJulia TransConversions.jl     
       Call RunJulia TInitialFungible.jl 
       Call RunJulia TInitialFungibleFS.jl
    
       Call RunJulia TInitialRun.jl     
       Call RunJulia TCalibRun.jl   
       Call RunJulia TFuture.jl     
       Call RunJulia TCalibFungible.jl
       Call RunJulia TCalibFungibleFS.jl
       Call RunJulia TransHistoricalVehicles.jl
     cd..\2020Model 
     
     If Not %DebugFlag%==Debug GoTo EndCalibTrans  
       Call BreakPoint CalibTrans
       Call CreateDTAs CalibTrans CalibTrans CalibTrans ExcelDTAs NoUnZip
rem    Call UnZip DB CalibTrans
       Call RunJulia StartScenario.jl Calib Calib Calib Calib Calib Calib Calib
     :EndCalibTrans    
     Echo %Date% ;%Time%; End Transportation Calibration %computername% >> RunAll_Report.log

     cd..\Calibration       
       Call RunJulia ElecDeprRate.jl
       Call RunJulia ElectricFuelSplits.jl
       Call RunJulia TransStdPostCalib.jl

       Call RunJulia LCalibRun.jl      
       Call RunJulia PostSupplyRun.jl
       Call RunJulia DeviceEfficiencyMultiplierForecast.jl
       Call RunJulia Adjust_HeatPump_DCMM.jl
       Call RunJulia xDCC_Forecast.jl
     cd..\2020Model 
     
     Call BreakPoint Calib 
     If Not %DebugFlag%==Debug GoTo EndCalib  
       Call CreateDTAs Calib Calib Calib ExcelDTAs NoUnZip
     :EndCalib        
rem  Call UnZip DB Calib
     Echo %Date% ;%Time%; End Load Curve and Post Supply %computername% >> RunAll_Report.log

     cd..\Calibration       
       Call RunJulia CogenMarketShareInitial.jl
       Call RunJulia PlantCharacteristics.jl
       Call RunJulia PlantCharacteristics_SMNR.jl     
       Call RunJulia PlantCharacteristics_HydrogenCT.jl     
       Call RunJulia PlantCharacteristics_SmallOGCC.jl
       Call RunJulia PlantCharacteristics_NGCCS.jl  
       Call RunJulia PlantCharacteristics_BiomassCCS.jl
       Call RunJulia PlantCharacteristics_Storage.jl
       Call RunJulia OGCCFractions.jl
       Call RunJulia ConstructionDelay2.jl    
     
       Call RunJulia UnitCreate_US.jl
       Call RunJulia UnitAddCap_US.jl
       Call RunJulia UnitDataExtension_US.jl
       Call RunJulia UnitScaleGenerationFuel_US.jl  
       Call RunJulia UnitDataPatch_US.jl  
       Call RunJulia NodeAreaMap.jl          
       Call RunJulia UnitScaleCapacity_US.jl     
       Call RunJulia UnitDataExtension_CA.jl
       Call RunJulia UnitScaleGeneration_CA.jl  
       Call RunJulia UnitDataPatch_CA.jl      
       Call RunJulia HistoricalGeneration.jl
       Call RunJulia UnitCreate_MX.jl 
       Call RunJulia UnitAddCap_MX.jl 
       Call RunJulia UnitGeneration_MX.jl   
       Call RunJulia UnitOtherVariables_MX.jl      

       Call RunJulia TotalDemands.jl
       Call RunJulia UnitCogenFractions.jl     
       Call RunJulia UnitConstruction.jl  
       Call RunJulia UnitConstruction_US.jl  
       Call RunJulia UnitCreate_ForPolicies.jl 
       Call RunJulia UnitCreateUnits.jl
       Call RunJulia UnitCreateCogenVarious.jl          
       Call RunJulia UnitCapacityInitiate.jl  

       Call RunJulia UnitEmissions.jl
       Call RunJulia UnitEICoverage.jl     
       Call RunJulia UnitSensitivity.jl      
       Call RunJulia AdjustUnitOutageRate_AEO.jl
       Call RunJulia AdjustElectricity_HeatRates.jl
       Call RunJulia HydroTransmissionLineNL.jl      
       Call RunJulia ExportsURFraction.jl  
       Call RunJulia SpotMarketBids.jl
       Call RunJulia AdjustEmgPower.jl
       Call RunJulia AdjustDeliveredPrices_SK.jl
     
       Call RunJulia StockAdjustment.jl
       Call RunJulia AdjustElectricSales.jl
       Call RunJulia ActivateLBNode.jl
       Call RunJulia AdjustGHG_FixNLGas.jl
       Call RunJulia AdjustSelfDealing.jl
       Call RunJulia AdjustMarketShare.jl
       Call RunJulia AdjustMarketShare_MX.jl     
       Call RunJulia AdjustMarketShare_BusDiesel.jl
       Call RunJulia AdjustPetroleum_ON.jl
       Call RunJulia AdjustPEIFood_Res.jl
       Call RunJulia AdjustDemands_NS.jl
       Call RunJulia AdjustCement.jl   
       Call RunJulia AdjustIndustrialGas.jl
       Call RunJulia AdjustFungibleParameters.jl
       Call RunJulia DmFracMaximum.jl

       Call RunJulia AdjustPetrochemicals_TOM.jl
       Call RunJulia AdjustFood_TOM.jl
       Call RunJulia AdjustGlass_TOM.jl
       Call RunJulia AdjustOtherNonMetallic_TOM.jl
       Call RunJulia AdjustAluminum_TOM.jl
       Call RunJulia AdjustOtherNonferrous_TOM.jl
       Call RunJulia AdjustIronOreMining_TOM.jl
       Call RunJulia AdjustOtherManufacturing_TOM.jl
       Call RunJulia AdjustForestry_TOM.jl     

       Call RunJulia EInitialFungible.jl 
       Call RunJulia ECalibFungible.jl 
     cd..\2020Model

     Echo %Date% ;%Time%; Begin Calib2 %computername% >> RunAll_Report.log 
     Call RunJulia StartScenario.jl Calib2 Calib2 Calib2 Calib2 Calib2 Calib2 Calib2
     cd..\Policy
       Copy PolicyEmpty.jl            Policy.jl    
       Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl  
     cd..\2020Model
     If %DebugFlag%==Debug GoTo Calib2Outputs  
       Call RunScenario 1986 2024 Calib2 Calib2 Calib2 Calib2 Calib2 Calib2 None
       GoTo EndCalib2
     :Calib2Outputs
       Call RunScenario 1986 2024 Calib2 Calib2 Calib2 Calib2 Calib2 Calib2 ExcelDTAs 
     :EndCalib2     
     Echo %Date% ;%Time%; End   Calib2 %computername% >> RunAll_Report.log  
     
     cd..\Calibration       
       Call RunJulia LCalibRun.jl 
       Call RunJulia CogenMarketShare.jl         
       Call RunJulia EGCalibSwitches.jl 
       Call RunJulia EGCalibRun.jl      
       Call RunJulia AdjustElectricity_OutageRates.jl 
       Call RunJulia ElecPriceSwitches.jl 
     cd..\2020Model     

     Echo %Date% ;%Time%; Begin Calib3 %computername% >> RunAll_Report.log 
     Call RunJulia StartScenario.jl Calib3 Calib3 Calib3 Calib3 Calib3 Calib3 Calib3
     cd..\Policy
       Copy PolicyEmpty.jl            Policy.jl    
       Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl  
     cd..\2020Model     
     If %DebugFlag%==Debug GoTo Calib3Outputs  
       Call RunScenario 1986 2050 Calib3 Calib3 Calib3 Calib3 Calib3 Calib3 None 
       GoTo EndCalib3
     :Calib3Outputs
       Call RunScenario 1986 2050 Calib3 Calib3 Calib3 Calib3 Calib3 Calib3 ExcelDTAs 
     :EndCalib3          
     Echo %Date% ;%Time%; End   Calib3 %computername% >> RunAll_Report.log     
rem  Call UnZip DB Calib3
     
     cd..\Calibration  
       Call RunJulia ElecPriceCalib.jl
       Call RunJulia ECalibFungible.jl  
       Call RunJulia Electric_Coal_FuelFractions.jl     
       Call RunJulia ElecPriceEndo.jl   
       Call RunJulia AdjustElectricPricesTD.jl      
       Call RunJulia WholesalePrices_Select.jl
     
       Call RunJulia DemandTotals.jl 
       Call RunJulia TotalDemands.jl 
       Call RunJulia MarketableGas.jl
       Call RunJulia OilGasCoalCalibRun.jl  

       Call RunJulia RefiningDeliveryCharge.jl
       Call RunJulia RefiningAdjustments.jl   
       Call RunJulia FlowNation.jl
       Call RunJulia InflowsOutflows.jl   

       Call RunJulia SpRefCalibRun.jl
  
       Call RunJulia GHG_MacroEconomy.jl
       Call RunJulia GHG_ElectricGeneration.jl
       Call RunJulia GHG_Transportation.jl
       Call RunJulia GHG_Transportation_MX.jl
       Call RunJulia GHG_ElectricGeneration_CA.jl
       Call RunJulia GHG_TransportationMacro_CA.jl
       Call RunJulia AdjustGHG_Coefficients.jl    
     
       Call RunJulia CAC_ElectricGeneration.jl 
       Call RunJulia CAC_MacroEconomy.jl
       Call RunJulia CAC_Residential.jl
       Call RunJulia CAC_Commercial.jl  
       Call RunJulia CAC_Transportation.jl      
       Call RunJulia CAC_Industrial.jl 
       Call RunJulia AdjustCAC_ABElecGen_Alt.jl
       Call RunJulia CAC_ElecGen_Defaults.jl
       Call RunJulia CAC_MacroEconomySpecial.jl   
       Call RunJulia AdjustCAC_PetroCoefficients.jl
       
       Call RunJulia CAC_BlackCarbon.jl
       Call RunJulia CAC_TransBiofuels.jl
       Call RunJulia CAC_HDV8NG.jl
       Call RunJulia CAC_H2Coefficients.jl
       Call RunJulia CAC_LNGProduction_POCX.jl
       Call RunJulia CAC_HDV_Electric.jl
       Call RunJulia CAC_OffRoadBiofuels.jl
       Call RunJulia AdjustProcessCoefficients_NU_TOM.jl
       Call RunJulia AdjustCAC_OffRoad_NU_TOM.jl
     cd..\2020Model

     Echo %Date% ;%Time%; Begin Calib4 %computername% >> RunAll_Report.log 
     Call RunJulia StartScenario.jl Calib4 Calib4 Calib4 Calib4 Calib4 Calib4 Calib4
     cd..\Policy
       Copy PolicyEmpty.jl            Policy.jl    
       Copy PolicyMarketShareEmpty.jl PolicyMarketShare.jl
       Copy PolicyTestEmpty.jl        PolicyTest.jl  
     cd..\2020Model 
     If %DebugFlag%==Debug GoTo Calib4Outputs  
       Call RunScenario 1986 2050 Calib4 Calib4 Calib4 Calib4 Calib4 Calib4 None 
       GoTo EndCalib4
     :Calib4Outputs
       Call RunScenario 1986 2050 Calib4 Calib4 Calib4 Calib4 Calib4 Calib4 ExcelDTAs 
     :EndCalib4
rem  Call UnZip DB Calib4   
     Echo %Date% ;%Time%; End   Calib4 %computername% >> RunAll_Report.log     

     cd..\Calibration   
       Call RunJulia Ind_MS_Biomass_Exo.jl
       Call RunJulia SetAsPolicyCase.jl
       Call RunJulia AdjustTransEff.jl
       Call RunJulia CFS_EmissionIntensity.jl
       Call RunJulia AdjustNLOtherChemicals_TOM.jl
       Call RunJulia EconomicDrivers_RestoreTOMValues.jl
       Call RunJulia MCalibRun.jl   
     cd..\2020Model

rem
     Echo %Date% ;%Time%; Begin StartBase %computername% >> RunAll_Report.log
     RD /s/q StartBase
     MD StartBase
     Call Zip Results StartBase\database database.hdf5 
     If Not %DebugFlag%==Debug GoTo EndStartBase  
       Call CreateDTAs StartBase StartBase StartBase ExcelDTAs NoUnZip
     :EndStartBase   
     RD /s/q StartBaseClean
     MD StartBaseClean
     Copy .\StartBase\*.* .\StartBaseClean\*.*     
     Echo %Date% ;%Time%; End   StartBase %computername% >> RunAll_Report.log    
rem
rem  ========================
rem
rem  Copy .\StartBaseClean\*.* .\StartBase\*.*  
     Echo %Date% ;%Time%; Begin Base %computername% >> RunAll_Report.log
     Call RunE2100 Base Base TestEmpty 2020 2050 Base Base Base All     
     Echo %Date% ;%Time%; End   Base %computername% >> RunAll_Report.log
rem
     Echo %Date% ;%Time%; Begin OGRef %computername% >> RunAll_Report.log
     Call RunE2100 OGRef OGRef TestEmpty 2020 2050 Base Base Base All
     Echo %Date% ;%Time%; End   OGRef %computername% >> RunAll_Report.log
rem
     Call RunOGCalibrationShort
     Echo %Date% ;%Time%; End   RunOGCalibrationShort %computername% >> RunAll_Report.log
rem
     Echo %Date% ;%Time%; Begin Ref25 %computername% >> RunAll_Report.log
     Call RunE2100 Ref25 Ref25 TestEmpty 2020 2050 Base Base Base All
     Echo %Date% ;%Time%; End   Ref25 %computername% >> RunAll_Report.log  
rem
     Echo %Date% ;%Time%; Begin Ref25A %computername% >> RunAll_Report.log
     Call RunE2100 Ref25A Ref25A TestEmpty 2020 2050 Ref25 Ref25 Ref25A All     
     Echo %Date% ;%Time%; End   Ref25A %computername% >> RunAll_Report.log  
rem
     Echo %Date% ;%Time%; Begin TOM Runs %computername% >> RunAll_Report.log 
     Call RunTOMRuns
     Echo %Date% ;%Time%; End   TOM Runs %computername% >> RunAll_Report.log 
rem
     Echo %Date% ;%Time%; Begin Access Databases %computername% >> RunAll_Report.log 
     Call CreateAccessOutputDatabases
     Echo %Date% ;%Time%; End   Access Databases %computername% >> RunAll_Report.log 
rem
     Echo %Date% ;%Time%; End   RunModel %computername% >> RunAll_Report.log
