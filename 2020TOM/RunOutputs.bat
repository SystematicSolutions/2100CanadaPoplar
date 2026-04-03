  
rem
     Call PrmFile Investments-Education.txo
     Call PrmFile USDemandCheck.txo
     Call PrmFile SummaryTransfers.txo
     Call PrmFile EnergyIntensity(Map).txo
     Call PrmFile EnergyIntensityE2020.txo
     Call PrmFile EnergyIntensityTOM.txo
rem     Call PrmFile DeliveredPrice(Map).txo
     Call PrmFile DeliveredPriceE2020.txo
     Call PrmFile DeliveredPriceTOM.txo
     Call PrmFile EnergyDemand(Map).txo
     Call PrmFile EnergyDemandE2020.txo
     Call PrmFile EnergyDemandTOM.txo
     Call PrmFile VehicleDistanceE2020.txo
     Call PrmFile VehicleDistanceTOM.txo
     Call PrmFile VehicleDistanceShareE2020.txo
     Call PrmFile VehicleDistanceShareTOM.txo
     Call PrmFile ProductionE2020.txo
     Call PrmFile ProductionTOM.txo
     Call PrmFile WholesalePricesE2020.txo
     Call PrmFile WholesalePricesTOM.txo
     Call PrmFile NonproductiveInvestmentsE2020.txo
     Call PrmFile NonproductiveInvestmentsTOM.txo
     Call PrmFile DeviceInvestmentsE2020.txo
     Call PrmFile DeviceInvestmentsTOM.txo
     Call PrmFile DeviceInvestmentsE2020TOM.txo
     Call PrmFile ProcessInvestmentsE2020.txo
     Call PrmFile ProcessInvestmentsTOM.txo
     Call PrmFile ProcessInvestmentsE2020TOM.txo
     Call PrmFile OilGasRevenueE2020.txo
     Call PrmFile OilGasRevenueTOM.txo
     Call PrmFile TradeFlowsE2020.txo
     Call PrmFile TradeFlowsTOM.txo
     Call PrmFile PermitExpendituresE2020.txo
     Call PrmFile PermitExpendituresTOM.txo
     Call PrmFile GovernmentSpendingE2020.txo
     Call PrmFile GovernmentSpendingTOM.txo
rem  
     Call PrmFile E2020TOMMaps.txo
     Call PrmFile E2020toTOM.txo
     Call PrmFile TOMtoE2020_DB.txo

     Call PrmFile TradeFlowsE2020.txo
     Call PrmFile TradeFlowsTOM.txo
     
rem  Call PrmFile E2020toTOM_DB.txo - not finished yet
rem  Call PrmFile TOMtoE2020.txo
rem
     Call PrmFile E2020Outputs.txo
rem
rem  Call PrmFile TOMOutputs.txo    
rem  Call PrmFile E2020TOMOutputs.txo
rem  Call PrmFile Investments.txo    
rem  Call PrmFile xInvestments.txo      
rem  Call PrmFile ProductionDB.txo
rem  Call PrmFile EnergyIntensityCheck.txo
rem  Call PrmFile EnergyIntensity.txo
rem
     Move *.dta %1    
     Call Zip Results %1\%1_ConnectionDTAs %1\*.dta
rem
     Call SetScenarioName %1 %2 %3 %4 %5