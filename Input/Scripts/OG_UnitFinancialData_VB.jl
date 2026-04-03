#
# OG_UnitFinancialData_VB.jl - Financial data assumptions for oil and gas production
#
using EnergyModel

module OG_UnitFinancialData_VB

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  OGAbCFr::VariableArray{2} = ReadDisk(db,"SpInput/OGAbCFr") # [OGUnit,Year] OG Abandonment Cost Fraction ($/($/Yr))
  vOGAbCFr::VariableArray{2} = ReadDisk(db,"VBInput/vOGAbCFr") # [OGUnit,Year] OG Abandonment Cost Fraction ($/$)
  DevDpRate::VariableArray{2} = ReadDisk(db,"SpInput/DevDpRate") # [OGUnit,Year] Development Depreciation Rate ($/$)
  SusDpRate::VariableArray{2} = ReadDisk(db,"SpInput/SusDpRate") # [OGUnit,Year] Sustaining Depreciation Rate ($/$)
  vDevDpRate::VariableArray{2} = ReadDisk(db,"VBInput/vDevDpRate") # [OGUnit,Year] Development Depreciation Rate ($/$)
  vSusDpRate::VariableArray{2} = ReadDisk(db,"VBInput/vSusDpRate") # [OGUnit,Year] Sustaining Depreciation Rate ($/$)
  OGITxRate::VariableArray{2} = ReadDisk(db,"SpInput/OGITxRate") # [OGUnit,Year] OG Initial Tax Rate ($/$)
  vOGITxRate::VariableArray{2} = ReadDisk(db,"VBInput/vOGITxRate") # [OGUnit,Year] OG Initial Tax Rate ($/$)
  xOGOMCosts::VariableArray{2} = ReadDisk(db,"SpInput/xOGOMCosts") # [OGUnit,Year] OG O and M Costs ($/mmBtu)
  vOGOMCosts::VariableArray{2} = ReadDisk(db,"VBInput/vOGOMCosts") # [OGUnit,Year] OG O and M Costs ($/mmBtu)
  OGROIN::VariableArray{2} = ReadDisk(db,"SpInput/OGROIN") # [OGUnit,Year] Return on Investment ($/Yr/$)
  vOGROIN::VariableArray{2} = ReadDisk(db,"VBInput/vOGROIN") # [OGUnit,Year] Return on Investment ($/Yr/$)
  DevDMB0::VariableArray{2} = ReadDisk(db,"SpInput/DevDMB0") # [OGUnit,Year] Development Costs Depletion Multiplier Coefficient ($/$)
  DevLCMB0::VariableArray{2} = ReadDisk(db,"SpInput/DevLCMB0") # [OGUnit,Year] Development Costs Learning Curve Multiplier Coefficient ($/$)
  OpDMB0::VariableArray{2} = ReadDisk(db,"SpInput/OpDMB0") # [OGUnit,Year] Operating Costs Depletion Multiplier Coefficient ($/$)
  OpLCMB0::VariableArray{2} = ReadDisk(db,"SpInput/OpLCMB0") # [OGUnit,Year] Operating Costs Learning Curve Multiplier Coefficient ($/$)
  vDevDMB0::VariableArray{2} = ReadDisk(db,"VBInput/vDevDMB0") # [OGUnit,Year] Development Costs Depletion Multiplier Coefficient ($/$)
  vDevLCMB0::VariableArray{2} = ReadDisk(db,"VBInput/vDevLCMB0") # [OGUnit,Year] Development Costs Learning Curve Multiplier Coefficient ($/$)
  vOpDMB0::VariableArray{2} = ReadDisk(db,"VBInput/vOpDMB0") # [OGUnit,Year] Operating Costs Depletion Multiplier Coefficient ($/$)
  vOpLCMB0::VariableArray{2} = ReadDisk(db,"VBInput/vOpLCMB0") # [OGUnit,Year] Operating Costs Learning Curve Multiplier Coefficient ($/$)
  PdC0OG::VariableArray{2} = ReadDisk(db,"SpInput/PdC0OG") # [OGUnit,Year] Learning Curve Initial Cumulative Production (TBtu)
  RsD0OG::VariableArray{2} = ReadDisk(db,"SpOutput/RsD0OG") # [OGUnit,Year] Learning Curve Initial Developed Resources (TBtu)
  vPdC0OG::VariableArray{2} = ReadDisk(db,"VBInput/vPdC0OG") # [OGUnit,Year] Learning Curve Initial Cumulative Production (TBtu)
  vRsD0OG::VariableArray{2} = ReadDisk(db,"VBInput/vRsD0OG") # [OGUnit,Year] Learning Curve Initial Developed Resources (TBtu)
  RyLevFactor::VariableArray{2} = ReadDisk(db,"SpInput/RyLevFactor") # [OGUnit,Year] Royalty Levelization Factor ($/$)
  vRyLevFactor::VariableArray{2} = ReadDisk(db,"VBInput/vRyLevFactor") # [OGUnit,Year] Royalty Levelization Factor ($/$)
  xDevCap::VariableArray{2} = ReadDisk(db,"SpInput/xDevCap") # [OGUnit,Year] Exogenous Development Capital Costs ($/mmBtu)
  xSusCap::VariableArray{2} = ReadDisk(db,"SpInput/xSusCap") # [OGUnit,Year] Exogenous Sustaining Capital Costs ($/mmBtu)
  vDevCap::VariableArray{2} = ReadDisk(db,"VBInput/vDevCap") # [OGUnit,Year] Exogenous Development Capital Costs ($/mmBtu)
  vSusCap::VariableArray{2} = ReadDisk(db,"VBInput/vSusCap") # [OGUnit,Year] Exogenous Sustaining Capital Costs ($/mmBtu)
  GRRMax::VariableArray{2} = ReadDisk(db,"SpInput/GRRMax") # [OGUnit,Year] Maximum Gross Revenue Royalty Rate ($/$)
  GRRMin::VariableArray{2} = ReadDisk(db,"SpInput/GRRMin") # [OGUnit,Year] Minimum Gross Revenue Royalty Rate ($/$)
  GRRPr::VariableArray{2} = ReadDisk(db,"SpInput/GRRPr") # [OGUnit,Year] Gross Revenue Royalty Rate Slope to Price ($/$)
  GRRPr0::VariableArray{2} = ReadDisk(db,"SpInput/GRRPr0") # [OGUnit,Year] Gross Revenue Royalty Rate Intercept ($/$)
  NRRMax::VariableArray{2} = ReadDisk(db,"SpInput/NRRMax") # [OGUnit,Year] Maximum Net Revenue Royalty Rate ($/$)
  NRRMin::VariableArray{2} = ReadDisk(db,"SpInput/NRRMin") # [OGUnit,Year] Minimum Net Revenue Royalty Rate ($/$)
  NRRPr::VariableArray{2} = ReadDisk(db,"SpInput/NRRPr") # [OGUnit,Year] Net Revenue Royalty Rate Slope to Price ($/$)
  NRRPr0::VariableArray{2} = ReadDisk(db,"SpInput/NRRPr0") # [OGUnit,Year] Net Revenue Royalty Rate Intercept ($/$)
  vGRRMax::VariableArray{2} = ReadDisk(db,"VBInput/vGRRMax") # [OGUnit,Year] Maximum Gross Revenue Royalty Rate ($/$)
  vGRRMin::VariableArray{2} = ReadDisk(db,"VBInput/vGRRMin") # [OGUnit,Year] Minimum Gross Revenue Royalty Rate ($/$)
  vGRRPr::VariableArray{2} = ReadDisk(db,"VBInput/vGRRPr") # [OGUnit,Year] Gross Revenue Royalty Rate Slope to Price ($/$)
  vGRRPr0::VariableArray{2} = ReadDisk(db,"VBInput/vGRRPr0") # [OGUnit,Year] Gross Revenue Royalty Rate Intercept ($/$)
  vNRRMax::VariableArray{2} = ReadDisk(db,"VBInput/vNRRMax") # [OGUnit,Year] Maximum Net Revenue Royalty Rate ($/$)
  vNRRMin::VariableArray{2} = ReadDisk(db,"VBInput/vNRRMin") # [OGUnit,Year] Minimum Net Revenue Royalty Rate ($/$)
  vNRRPr::VariableArray{2} = ReadDisk(db,"VBInput/vNRRPr") # [OGUnit,Year] Net Revenue Royalty Rate Slope to Price ($/$)
  vNRRPr0::VariableArray{2} = ReadDisk(db,"VBInput/vNRRPr0") # [OGUnit,Year] Net Revenue Royalty Rate Intercept ($/$)
  ROITarget::VariableArray{2} = ReadDisk(db,"SpInput/ROITarget") # [OGUnit,Year] ROI Target for Supply Cost Search ($/$)
  vROITarget::VariableArray{2} = ReadDisk(db,"VBInput/vROITarget") # [OGUnit,Year] ROI Target for Supply Cost Search ($/$)
  OGFPDChg::VariableArray{2} = ReadDisk(db,"SpInput/OGFPDChg") # [OGUnit,Year] Wholesale Price Transportation Charge ($/mmBtu)
  vOGFPDChg::VariableArray{2} = ReadDisk(db,"VBInput/vOGFPDChg") # [OGUnit,Year] Wholesale Price Transportation Charge ($/mmBtu)
  OGFPAdd::VariableArray{2} = ReadDisk(db,"SpInput/OGFPAdd") # [OGUnit,Year] Price Adder for Supply Cost Search ($/mmBtu)
  OGFPMax::VariableArray{2} = ReadDisk(db,"SpInput/OGFPMax") # [OGUnit,Year] Maximum Price for Supply Cost Search ($/mmBtu)
  OGFPMin::VariableArray{2} = ReadDisk(db,"SpInput/OGFPMin") # [OGUnit,Year] Inital Price for Supply Cost Search ($/mmBtu)
  vOGFPAdd::VariableArray{2} = ReadDisk(db,"VBInput/vOGFPAdd") # [OGUnit,Year] Price Adder for Supply Cost Search ($/mmBtu)
  vOGFPMax::VariableArray{2} = ReadDisk(db,"VBInput/vOGFPMax") # [OGUnit,Year] Maximum Price for Supply Cost Search ($/mmBtu)
  vOGFPMin::VariableArray{2} = ReadDisk(db,"VBInput/vOGFPMin") # [OGUnit,Year] Inital Price for Supply Cost Search ($/mmBtu)
  OWCDays::VariableArray{2} = ReadDisk(db,"SpInput/OWCDays") # [OGUnit,Year] Operating Working Capital Days Payment (Days)
  vOWCDays::VariableArray{2} = ReadDisk(db,"VBInput/vOWCDays") # [OGUnit,Year] Operating Working Capital Days Payment (Days)

end

function SCalibration(db)
  data = SControl(; db)
  (;OGUnit,OGUnits,Year,YearDS,Years) = data
  (;OGAbCFr,vOGAbCFr,DevDpRate,SusDpRate,vDevDpRate,vSusDpRate,OGITxRate,vOGITxRate,xOGOMCosts,vOGOMCosts) = data
  (;OGROIN,vOGROIN,DevDMB0,DevLCMB0,OpDMB0,OpLCMB0,vDevDMB0,vDevLCMB0,vOpDMB0,vOpLCMB0) = data
  (;PdC0OG,RsD0OG,vPdC0OG,vRsD0OG,RyLevFactor,vRyLevFactor,xDevCap,xSusCap,vDevCap,vSusCap) = data
  (;GRRMax,GRRMin,GRRPr,GRRPr0,NRRMax,NRRMin,NRRPr,NRRPr0,vGRRMax,vGRRMin) = data
  (;vGRRPr,vGRRPr0,vNRRMax,vNRRMin,vNRRPr,vNRRPr0,ROITarget,vROITarget,OGFPDChg,vOGFPDChg) = data
  (;OGFPAdd,OGFPMax,OGFPMin,vOGFPAdd,vOGFPMax,vOGFPMin,OWCDays,vOWCDays) = data

  OGAbCFr = vOGAbCFr
  WriteDisk(db,"SpInput/OGAbCFr",OGAbCFr)

  DevDpRate = vDevDpRate
  SusDpRate = vSusDpRate
  WriteDisk(db,"SpInput/DevDpRate",DevDpRate)
  WriteDisk(db,"SpInput/SusDpRate",SusDpRate)

  OGITxRate = vOGITxRate
  WriteDisk(db,"SpInput/OGITxRate",OGITxRate)

  xOGOMCosts = vOGOMCosts
  WriteDisk(db,"SpInput/xOGOMCosts",xOGOMCosts)

  OGROIN = vOGROIN
  WriteDisk(db,"SpInput/OGROIN",OGROIN)

  DevDMB0 = vDevDMB0
  DevLCMB0 = vDevLCMB0
  OpDMB0 = vOpDMB0
  OpLCMB0 = vOpLCMB0
  PdC0OG = vPdC0OG
  RsD0OG = vRsD0OG
  WriteDisk(db,"SpInput/DevDMB0",DevDMB0)
  WriteDisk(db,"SpInput/DevLCMB0",DevLCMB0)
  WriteDisk(db,"SpInput/OpDMB0",OpDMB0)
  WriteDisk(db,"SpInput/OpLCMB0",OpLCMB0)
  WriteDisk(db,"SpInput/PdC0OG",PdC0OG)
  WriteDisk(db,"SpOutput/RsD0OG",RsD0OG)

  RyLevFactor = vRyLevFactor
  WriteDisk(db,"SpInput/RyLevFactor",RyLevFactor)

  xDevCap = vDevCap
  xSusCap = vSusCap
  WriteDisk(db,"SpInput/xDevCap",xDevCap)
  WriteDisk(db,"SpInput/xSusCap",xSusCap)

  GRRMax = vGRRMax
  GRRMin = vGRRMin
  GRRPr = vGRRPr
  GRRPr0 = vGRRPr0
  NRRMax = vNRRMax
  NRRMin = vNRRMin
  NRRPr = vNRRPr
  NRRPr0 = vNRRPr0
  WriteDisk(db,"SpInput/GRRMax",GRRMax)
  WriteDisk(db,"SpInput/GRRMin",GRRMin)
  WriteDisk(db,"SpInput/GRRPr",GRRPr)
  WriteDisk(db,"SpInput/GRRPr0",GRRPr0)
  WriteDisk(db,"SpInput/NRRMax",NRRMax)
  WriteDisk(db,"SpInput/NRRMin",NRRMin)
  WriteDisk(db,"SpInput/NRRPr",NRRPr)
  WriteDisk(db,"SpInput/NRRPr0",NRRPr0)

  ROITarget = vROITarget
  WriteDisk(db,"SpInput/ROITarget",ROITarget)

  OGFPDChg = vOGFPDChg
  WriteDisk(db,"SpInput/OGFPDChg",OGFPDChg)

  OGFPAdd = vOGFPAdd
  OGFPMax = vOGFPMax
  OGFPMin = vOGFPMin
  WriteDisk(db,"SpInput/OGFPAdd",OGFPAdd)
  WriteDisk(db,"SpInput/OGFPMax",OGFPMax)
  WriteDisk(db,"SpInput/OGFPMin",OGFPMin)

  OWCDays = vOWCDays
  WriteDisk(db,"SpInput/OWCDays",OWCDays)

end

function Control(db)
  @info "OG_UnitFinancialData_VB.jl - Control"
  SCalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
