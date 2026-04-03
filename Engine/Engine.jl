#
# Engine.jl
#

module Engine

using TimerOutputs

const TIMER = TimerOutput()

include("E2020.jl")

#
# Call CompileFile MControl
#
include("MControl.jl")
include("MInitial.jl")

#
# Call CompileFile MCALIB
# Call CompileFile MFUTURE
#
include("MEconomy.jl")
include("MEconomyTOM.jl")

include("SControl.jl")
include("SInitial.jl")
include("SCalib.jl")
include("SFuture.jl")
include("LCDirectControl.jl")

include("Supply.jl")

include("SuPollution.jl")
include("SuPollutionEI.jl")
include("SuPollutionCFS.jl")
include("SuPollutionOGEC.jl")
include("SuPollutionMarket.jl")

include("RInitial.jl")
include("RCalib.jl")
include("RFuture.jl")
include("RDemand.jl")
include("RLoad.jl")
include("RControl.jl")

include("CInitial.jl")
include("CCalib.jl")
include("CFuture.jl")
include("CDemand.jl")
include("CLoad.jl")
include("CControl.jl")

include("IInitial.jl")
include("ICalib.jl")
include("IFuture.jl")
include("IDemand.jl")
include("ILoad.jl")
include("IControl.jl")

include("TInitial.jl")
include("TCalib.jl")
include("TFuture.jl")
include("TDemand.jl")
include("TDemand2.jl")
include("TLoad.jl")
include("TControl.jl")

#
# Call CompileFile EControl
#
include("ELoadCurve.jl")
include("ECapacityExpansion.jl")


include("EFuelUsage.jl")
include("ECosts.jl")
include("EPeakHydro.jl")
include("EDispatch.jl")
include("EDispatchCg.jl")
include("EGenerationSummary.jl")
include("EFlows.jl")
include("EPollution.jl")
include("ERetailPurchases.jl")
include("EContractDevelopment.jl")
include("ERetailPowerCosts.jl")
include("ElectricPrice.jl")

include("EGCalib.jl")

include("SpCoal.jl")
include("SpBiofuel.jl")
include("SpEthanol.jl")
include("SpHydrogen.jl")
include("DirectAirCapture.jl")
include("SpGas.jl")
include("SpGTrans.jl")

#
# Call CompileFile SpGTrLP
#
include("SpImportsExports.jl")
include("SpOGProd.jl")

#
# Call CompileFile SpOGProdCalib
#
include("SpOProd.jl")
include("SpRefinery.jl")
include("SpRef.jl")
include("SpRefCalib.jl")
include("SpRefineryCalib.jl")

include("SpFuelSupplyCurve.jl")
include("MEWaste.jl")
include("MPollution.jl")
include("MReductions.jl")
end
