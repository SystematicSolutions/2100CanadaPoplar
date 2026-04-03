#
# Main.jl
#

function PolicyIncorporation()
  @info "PolicyIncorporation - Execute policy files"
  PolicyMarketShare.InitializeMarketShares()
  Policy.IncorporatePolicies()
  PolicyTest.IncorporatePolicyTest()
  PolicyMarketShare.MarketShareCoefficients()
end

function GenerateOutputs(db,SceName,OutputType)
  @info "GenerateOutputs - Generate Outputs for $SceName scenario"
  Outputs.Outputs_Control(db,SceName,OutputType)
end

function Run_E2020(db,BTime,EndTime,SceName; silent = false,write = false)
  @info "Run_E2020 - Executing $SceName scenario"
  Engine.Model(db,BTime,EndTime,SceName; silent = false,write = false)
end

function MCalibRun(db)
  @info "MCalibRun - Executing MEconomy Calibration"
  Engine.MCalibEntire(db)
end

function SCalibRun(db)
  @info "SCalibRun - Executing Price Calibration"
  Engine.SCalibEntire(db)
end

function SCalibPricesRun(db)
  @info "SCalibPricesRun - Executing Price Calibration"
  Engine.SCalibEntirePrices(db)
end

function LCalibRun(db)
  @info "LCalibRun - Executing Loadcurve Calibration"
  Engine.LCDirect(db)
end

function PostSupplyRun(db)
  @info "PostSupplyRun - Executing Post Supply"
  Engine.PostSupply(db)
end

function RInitialRun(db)
  @info "RInitialRun - Executing Residential Initialization"
  Engine.RInitial.Control(db)
end

function RCalibRun(db)
  @info "RCalibRun - Executing Residential Calibration"
  Engine.RControl.Calib(db)
end

function CInitialRun(db)
  @info "CInitialRun - Executing Commercial Initialization"
  Engine.CInitial.Control(db)
end

function CCalibRun(db)
  @info "CCalibRun - Executing Commercial Calibration"
  Engine.CControl.Calib(db)
end

function IInitialRun(db)
  @info "IInitialRun - Executing Industrial Initialization"
  Engine.IInitial.Control(db)
end

function ICalibRun(db)
  @info "ICalibRun - Executing Industrial Calibration"
  Engine.IControl.Calib(db)
end

#
# IFutureRun is currently just for testing - Jeff Amlin 4/16/25
#
function IFutureRun(db)
  @info "IFutureRun - Executing Industrial Future Calibration Values"
  Engine.IFuture.Control(db)
end

function TInitialRun(db)
  @info "TInitialRun - Executing Transportation Initialization"
  Engine.TInitial.Control(db)
end

function TCalibRun(db)
  LoggerInitialize()
  @info "TCalibRun - Executing Transportation Calibration"
  Engine.TControl.Calib(db)
end

#
# TFutureRun is currently just for testing - Jeff Amlin 4/16/25
#
function TFutureRun(db)
  LoggerInitialize()
  @info "TCalibFuture - Executing Transportation Future Calibration Values"
  Engine.TFuture.Control(db)
end


function EGCalibRun(db)
  @info "EGCalibRun - Executing Electric Generation Calibration"
  Engine.EGCalib.OORCalib(db)
end

function SpRefCalibRun(db)
  @info "SpRefCalibRun - Executing Refining Unit Calibration"
  Engine.SpRefCalib.RefiningCalibration(db)
end

function OilGasCoalCalibRun(db)
  @info "OilGasCoalCalibRun - Executing Aggregate Refining Calibration"
  Engine.SpRefineryCalib.Control(db)
end
