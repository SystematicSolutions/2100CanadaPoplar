rem
rem  E2020_to_TOM.bat - TOM transfer files
rem

 Call RunJulia E2020GrossOutputTransform.jl
 Call RunJulia E2020InvestmentsTransform.jl
 Call RunJulia E2020SplitECCtoTOMInvestments.jl
 Call RunJulia E2020SplitECCtoTOM.jl
 Call RunJulia E2020GrossDemands.jl
 Call RunJulia E2020EnergyDemand.jl
 Call RunJulia E2020EnergyDemandRes.jl

 Call RunJulia E2020EnergyDemandTr.jl
 Call RunJulia E2020VehicleDistanceTraveled.jl
 Call RunJulia E2020EnergyIntensity.jl
 Call RunJulia E2020EnergyIntensityTr.jl 

 Call RunJulia E2020DeliveredPrices.jl
 Call RunJulia E2020DeviceInvestments.jl
 Call RunJulia E2020DeviceInvestmentsTr.jl
 Call RunJulia E2020GovernmentSpending.jl
 Call RunJulia E2020OilGasRevenue.jl
 Call RunJulia E2020PermitExpenditures.jl
 Call RunJulia E2020ProcessInvestments.jl
 Call RunJulia E2020ProductionByArea.jl
 Call RunJulia E2020ReductionInvestments.jl
 Call RunJulia E2020WholesalePrices.jl
 Call RunJulia E2020OMExpenditures.jl
 Call RunJulia E2020TradeFlows.jl
