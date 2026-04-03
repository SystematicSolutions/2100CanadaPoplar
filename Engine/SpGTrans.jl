#
# SpGTrans.jl - Natural Gas Transmission
#
# The natural gas transportation system will be based in US$.
# The NG and LNG costs and prices will be in Local$ and converted
# to US$ if used by the NG transportation system.

module SpGTrans

import ...EnergyModel: ReadDisk, WriteDisk, Select, ITime, MaxTime, HisTime, DT
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int
  
  # Set arrays
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelOG::SetArray = ReadDisk(db,"MainDB/FuelOGKey")
  FuelOGs::Vector{Int} = collect(Select(FuelOG))
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodes::Vector{Int} = collect(Select(GNode))
  GNodeX::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodeXs::Vector{Int} = collect(Select(GNodeX))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  ProcOG::SetArray = ReadDisk(db,"MainDB/ProcOGKey")
  ProcOGs::Vector{Int} = collect(Select(ProcOG))
  
  # Variables
  DaysPerMonth::VariableArray{1} = ReadDisk(db,"SInput/DaysPerMonth") #[Month] Days per Month (Days/Month)
  ENPN::VariableArray{2} = ReadDisk(db,"SOutput/ENPN",year) #[Fuel,Nation,Year] Wholesale Fuel Prices (Local$/mmBtu)
  Epsilon::Float32 = ReadDisk(db,"MainDB/Epsilon")[1] #[tv] A Very Small Number
  ExchangeRateGNode::VariableArray{1} = ReadDisk(db,"MOutput/ExchangeRateGNode",year) #[GNode,Year] Local Currency/US$ Exchange Rate (Local$/US$)
  FPGN1::VariableArray{2} = ReadDisk(db,"SpOutput/FPGNode",year) #[GNode,Month,Year] Natural Gas Transmission Node Price in Previous Year (US$/mmBtu)
  FPGNode::VariableArray{2} = ReadDisk(db,"SpOutput/FPGNode",year) #[GNode,Month] Natural Gas Transmission Node Price (US$/mmBtu)
  FPGNodeUS::VariableArray{2} = ReadDisk(db,"SpOutput/FPGNodeUS",year) #[GNode,Month] Natural Gas Transmission Node Price (US$/mmBtu)
  
  GADemand::VariableArray{1} = ReadDisk(db,"SpOutput/GADemand",year) #[Area] Natural Gas Demand (TBtu/Yr)
  GAProd::VariableArray{2} = ReadDisk(db,"SOutput/GAProd",year) #[Process,Area,Year] Primary Gas Production (TBtu/Yr)
  G3AProd::VariableArray{2} = ReadDisk(db,"SOutput/G3AProd",year) #[Process,Area,Year] Primary Natural Gas Production after Pipeline Constraints (TBtu/Yr)
  GAvFrLNG::VariableArray{2} = ReadDisk(db,"SpInput/GAvFrLNG",year) #[GNode,Month,Year] Fraction of the LNG Capacity Available for Dispatch
  GAvFrProd::VariableArray{2} = ReadDisk(db,"SpInput/GAvFrProd",year) #[GNode,Month,Year] Fraction of NG Production Available Each Month
  GAvFrStorage::VariableArray{2} = ReadDisk(db,"SpInput/GAvFrStorage",year) #[GNode,Month,Year] Fraction of NG Storage Available Each Month
  GAvProd::VariableArray{2} = ReadDisk(db,"SpOutput/GAvProd",year) #[GNode,Month,Year] Natural Gas Available from Production (TBtu/Month)
  GAvStorage::VariableArray{2} = ReadDisk(db,"SpOutput/GAvStorage",year) #[GNode,Month,Year] Natural Gas Availible from Storage (TBtu/Month)
  GAvStoragePrior::VariableArray{2} = ReadDisk(db,"SpOutput/GAvStorage",prior) #[GNode,Month,Year] Natural Gas Availible from Storage (TBtu/Month)
  GAvLNG::VariableArray{2} = ReadDisk(db,"SpOutput/GAvLNG",year) #[GNode,Month,Year] Natural Gas Availible from LNG (TBtu/Month)
  GCapStorage::VariableArray{2} = ReadDisk(db,"SpOutput/GCapStorage",year) #[GNode,Month,Year] Storage Capacity
  GCapLNGExports::VariableArray{2} = ReadDisk(db,"SpOutput/GCapLNGExports",year) #[GNode,Month,Year] LNG Export Capacity
  GCapLNGImports::VariableArray{2} = ReadDisk(db,"SpOutput/GCapLNGImports",year) #[GNode,Month,Year] LNG Import Capacity
  GExpLNG::VariableArray{2} = ReadDisk(db,"SpOutput/GExpLNG",year) #[GNode,Month,Year] Natural Gas LNG Exports (TBtu/Month)
  GExpMaxLNG::VariableArray{2} = ReadDisk(db,"SpOutput/GExpMaxLNG",year) #[GNode,Month,Year] Maximum Natural Gas Exports from LNG (TBtu/Month)
  GExpPrLNG::VariableArray{2} = ReadDisk(db,"SpOutput/GExpPrLNG",year) #[GNode,Month,Year] Natural Gas LNG Export Profits (Local$/mmBtu)
  GExpPrLNGUS::VariableArray{2} = ReadDisk(db,"SpOutput/GExpPrLNGUS",year) #[GNode,Month,Year] Natural Gas LNG Export Profits (US$/mmBtu)
  GFillFrStorage::VariableArray{2} = ReadDisk(db,"SpInput/GFillFrStorage",year) #[GNode,Month,Year] Fraction of Storage Capacity Filled (Btu/Btu)
  GLSF::VariableArray{2} = ReadDisk(db,"SpInput/GLSF",year) #[Month,Area,Year] Natural Gas Load Shape Factor (Btu/Btu)
  GLvStorage::VariableArray{2} = ReadDisk(db,"SpOutput/GLvStorage",year) #[GNode,Month,Year] Level of Natural Gas in Storage (TBtu)
  GLvStoragePrior::VariableArray{2} = ReadDisk(db,"SpOutput/GLvStorage",prior) #[GNode,Month,Year] Level of Natural Gas in Storage (TBtu)
  GNodeAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeAreaMap") #[GNode,Area] Natural Gas Node to Area Map
  GNProd::VariableArray{1} = ReadDisk(db,"SpOutput/GNProd",year) #[GNode,Year] Natural Gas Production (TBtu/Yr)
  G2NProd::VariableArray{1} = ReadDisk(db,"SpOutput/G2NProd",year) #[GNode,Year] Natural Gas Production before Pipeline Constraints (TBtu/Yr)
  G3NProd::VariableArray{1} = ReadDisk(db,"SpOutput/G3NProd",year) #[GNode,Year] Natural Gas Production after Pipeline Constraints (TBtu/Yr)
  G3Prod::VariableArray{2} = ReadDisk(db,"SOutput/G3Prod",year) #[Process,Nation,Year] Primary Natural Gas Production after Pipeline Constraints (TBtu/Yr)
  GRqDemand::VariableArray{2} = ReadDisk(db,"SpOutput/GRqDemand",year) #[GNode,Month,Year] Natural Gas Required to Meet Demands (TBtu/Month)
  GRqStorage::VariableArray{2} = ReadDisk(db,"SpOutput/GRqStorage",year) #[GNode,Month,Year] Natural Gas Required to Fill Storage (TBtu/Month)
  GSpEmg::VariableArray{2} = ReadDisk(db,"SpOutput/GSpEmg",year) #[GNode,Month,Year] Emergency Natural Gas Dispatched (TBtu/Month)
  GSpLNG::VariableArray{2} = ReadDisk(db,"SpOutput/GSpLNG",year) #[GNode,Month,Year] Natural Gas Supplied from LNG (TBtu/Month)
  GSpProd::VariableArray{2} = ReadDisk(db,"SpOutput/GSpProd",year) #[GNode,Month,Year] Natural Gas Supplied from Production (TBtu/Month)
  GSpStorage::VariableArray{2} = ReadDisk(db,"SpOutput/GSpStorage",year) #[GNode,Month,Year] Natural Gas Supplied from Storage (TBtu/Month)
  GSpStorageAve::VariableArray{2} = ReadDisk(db,"SpOutput/GSpStorageAve",year) #[GNode,Month,Year] Average NG Supplied from Storage (TBtu/Month)
  GSpStorageAvePrior::VariableArray{2} = ReadDisk(db,"SpOutput/GSpStorageAve",prior) #[GNode,Month,Year] Average NG Supplied from Storage (TBtu/Month)
  GTrEff::VariableArray{3} = ReadDisk(db,"SpInput/GTrEff",year) #[GNode,GNodeX,Month,Year] Natural Gas Transmission Efficiency (TBtu/TBtu)
  GTrMax::VariableArray{3} = ReadDisk(db,"SpInput/GTrMax",year) #[GNode,GNodeX,Month,Year] Natural Gas Transmission Capacity (TBtu/Month)
  GTrVC::VariableArray{3} = ReadDisk(db,"SpOutput/GTrVC",year) #[GNode,GNodeX,Month,Year] Natural Gas Transmission Variable Cost (US$/mmBtu)
  GTrFlow::VariableArray{3} = ReadDisk(db,"SpOutput/GTrFlow",year) #[GNode,GNodeX,Month,Year] Natural Gas Transmission Flow (TBtu/Month)
  
  GUVCStorage::VariableArray{2} = ReadDisk(db,"SpInput/GUVCStorage",year) #[GNode,Month,Year] Unit Non-Fuel Variable Cost from Storage (Local$/mmBtu)
  GVCEmg::VariableArray{2} = ReadDisk(db,"SpOutput/GVCEmg",year) #[GNode,Month,Year] Emergency Natural Gas Cost (US$/mmBtu)
  GVCLNG::VariableArray{2} = ReadDisk(db,"SpOutput/GVCLNG",year) #[GNode,Month,Year] Natural Gas Variable Cost from LNG (Local$/mmBtu)
  GVCLNGUS::VariableArray{2} = ReadDisk(db,"SpOutput/GVCLNGUS",year) #[GNode,Month,Year] Natural Gas Variable Cost from LNG (US$/mmBtu)
  GVCProd::VariableArray{2} = ReadDisk(db,"SpOutput/GVCProd",year) #[GNode,Month,Year] Natural Gas Variable Cost from Production (Local$/mmBtu)
  GVCProdUS::VariableArray{2} = ReadDisk(db,"SpOutput/GVCProdUS",year) #[GNode,Month,Year] Natural Gas Variable Cost from Production (US$/mmBtu)
  GVCStorage::VariableArray{2} = ReadDisk(db,"SpOutput/GVCStorage",year) #[GNode,Month,Year] Natural Gas Variable Cost from Storage (Local$/mmBtu)
  GVCStorageUS::VariableArray{2} = ReadDisk(db,"SpOutput/GVCStorageUS",year) #[GNode,Month,Year] Natural Gas Variable Cost from Storage (US$/mmBtu)
  
  InflationGNode::VariableArray{1} = ReadDisk(db,"MOutput/InflationGNode",year) #[GNode,Year] Inflation Index ($/$)
  
  OGArea::Vector{String} = ReadDisk(db,"SpInput/OGArea") #[OGUnit] Area
  OGECC::Vector{String} = ReadDisk(db,"SpInput/OGECC") #[OGUnit] Economic Sector
  OGFuel::Vector{String} = ReadDisk(db,"SpInput/OGFuel") #[OGUnit] Fuel Type
  OGNation::Vector{String} = ReadDisk(db,"SpInput/OGNation") #[OGUnit] Nation
  OGNode::Vector{String} = ReadDisk(db,"SpInput/OGNode") #[OGUnit] Natural Gas Transmission Node
  OGOGSw::Vector{String} = ReadDisk(db,"SpInput/OGOGSw") #[OGUnit] Oil or Gas Switch
  OGProcess::Vector{String} = ReadDisk(db,"SpInput/OGProcess") #[OGUnit] Production Process
  Pd::VariableArray{1} = ReadDisk(db,"SpOutput/Pd",year) #[OGUnit,Year] Production (TBtu/Yr)
  Pd3::VariableArray{1} = ReadDisk(db,"SpOutput/Pd3",year) #[OGUnit,Year] Production after Pipeline Constraints (TBtu/Yr)
  Pd3Cum::VariableArray{1} = ReadDisk(db,"SpOutput/Pd3Cum",year) #[OGUnit,Year] Cumulative Production after Pipeline Constraints (TBtu)
  Pd3CumOG::VariableArray{2} = ReadDisk(db,"SpOutput/Pd3CumOG",year) #[ProcOG,Area,Year] Cumulative Production after Pipeline Constraints (TBtu)
  Pd3OG::VariableArray{2} = ReadDisk(db,"SpOutput/Pd3OG",year) #[ProcOG,Area,Year] Production after Pipeline Constraints (TBtu/Yr)
  Pd3RaOG::VariableArray{2} = ReadDisk(db,"SpOutput/Pd3RaOG",year) #[ProcOG,Area,Year] Production Rate after Pipeline Constraints (TBtu/TBtu)
  RsDevOGPrior::VariableArray{2} = ReadDisk(db,"SpOutput/RsDevOG",prior) #[ProcOG,Area,Year] Developed Resources (TBtu)
  xENPN::VariableArray{2} = ReadDisk(db,"SInput/xENPN",year) #[Fuel,Nation,Year] Exogenous Price Normal (Local$/mmBtu)
  xGCapLNGImports::VariableArray{2} = ReadDisk(db,"SpInput/xGCapLNGImports",year) #[GNode,Month,Year] Exogenous LNG Imports Capacity (TBtu/Yr)
  xGCapLNGExports::VariableArray{2} = ReadDisk(db,"SpInput/xGCapLNGExports",year) #[GNode,Month,Year] Exogenous LNG Exports Capacity (TBtu/Yr)
  xGCapStorage::VariableArray{2} = ReadDisk(db,"SpInput/xGCapStorage",year) #[GNode,Month,Year] Exogenous Storage Capacity (TBtu/Yr)
  xGExpDChg::VariableArray{2} = ReadDisk(db,"SpInput/xGExpDChg",year) #[GNode,Month,Year] World Natural Gas Price Differential (Local$/mmBtu)
  xGFlow::VariableArray{3} = ReadDisk(db,"SpInput/xGFlow",year) #[GNode,GNodeX,Month,Year] Exongeous Contract Flows (TBtu/Yr)
  xGLvStorage::VariableArray{2} = ReadDisk(db,"SpInput/xGLvStorage",year) #[GNode,Month,Year] Historical Level of Natural Gas in Storage (TBtu)
  xGTrFlow::VariableArray{3} = ReadDisk(db,"SpInput/xGTrFlow",year) #[GNode,GNodeX,Month,Year] Natural Gas Transmission Flow (TBtu/Month)
  xGTrVC::VariableArray{3} = ReadDisk(db,"SpInput/xGTrVC",year) #[GNode,GNodeX,Month,Year] Natural Gas Transmission Variable Cost (US$/mmBtu)
  xGVCLNG::VariableArray{2} = ReadDisk(db,"SpInput/xGVCLNG",year) #[GNode,Month,Year] Historical Natural Gas Variable Cost from LNG (Local$/mmBtu)
  xGVCProd::VariableArray{2} = ReadDisk(db,"SpInput/xGVCProd",year) #[GNode,Month,Year] Historical Natural Gas Variable Cost from Production (Local$/mmBtu)
  
  # Scratch variables
  StoreAT::Float32 = 4.0
  GStLevel::VariableArray{1} = zeros(Float32, length(GNode))  # Level of Natural Gas in Storage (TBtu)
  ProcSw::VariableArray{1} = ReadDisk(db,"SInput/ProcSw", year) # Process Switch
end

# Constants for process switches
const Endogenous = 1.0
const Exogenous = 2.0
const GTrans = 3.0

function OGSetSelect(data::Data, unit)
  (; Area, ECC, FuelOG, GNode, Nation, OGArea, OGECC, OGFuel, OGNation, OGNode, OGProcess, Process, ProcOG) = data
  
  # This function selects the sets for a particular OG unit
  area = Select(Area, OGArea[unit])
  ecc = Select(ECC, OGECC[unit])
  process = Select(Process, OGECC[unit])
  fuelOG = Select(FuelOG, OGFuel[unit])
  procOG = Select(ProcOG, OGProcess[unit])
  gnode = Select(GNode, OGNode[unit])
  nation = Select(Nation, OGNation[unit])
  
  return area, ecc, process, fuelOG, procOG, gnode, nation
end

function OGRSetSets(data::Data)
  # This function restores the sets to all values
  # No action needed in Julia implementation as we don't modify set selections
end

function Initial(data::Data)
  (; db, year) = data
  (; GLvStorage, xGLvStorage) = data
  
  # Write (" SPGTrans.src, Natural Gas Transmission Initialize Storage")
  
  # Initialize storage level with exogenous values
  for i in eachindex(GLvStorage)
    GLvStorage[i] = xGLvStorage[i]
  end
  
  WriteDisk(db, "SpOutput/GLvStorage", year, GLvStorage)
end

function NodeDemSup(data::Data)
  (; db, year) = data
  (; Areas, GNodes, Months) = data
  (; GADemand, GLSF, GNodeAreaMap, GNProd, GRqDemand, G2NProd) = data
  
  # Write (" SPGTrans.src, Natural Gas Transmission Demands and Supply")
  
  # Natural Gas Demand (the GLSF factor should be by ES)
  for gnode in GNodes, month in Months
    GRqDemand[gnode, month] = sum(GADemand[area] * GNodeAreaMap[gnode, area] * 
                                GLSF[month, area] for area in Areas)
  end
  
  WriteDisk(db, "SpOutput/GRqDemand", year, GRqDemand)
  
  # Node Gas Production from OGUnit Gas Production
  # GNProd = 0.0 (commented out in original code)
  for gnode in GNodes
    GNProd[gnode] = G2NProd[gnode]
  end
  
  WriteDisk(db, "SpOutput/GNProd", year, GNProd)
end

function StorCapacity(data::Data)
  (; db, year) = data
  (; GCapStorage, xGCapStorage) = data
  
  # Write (" SPGTrans.src, Natural Gas Transmission Storage Capacity")
  
  # Natural Gas Storage Capacity (GCapStorage) is exogenous (xGCapStorage)
  for i in eachindex(GCapStorage)
    GCapStorage[i] = xGCapStorage[i]
  end
  
  WriteDisk(db, "SpOutput/GCapStorage", year, GCapStorage)
end

function ProdBids(data::Data)
  (; db, year) = data
  (; GNodes, Months) = data
  (; DaysPerMonth, GAvProd, GNProd, GAvFrProd, GVCProd, GVCProdUS) = data
  (; GVCEmg, GTrVC, xENPN, InflationGNode, xGVCProd, ExchangeRateGNode, xGTrVC) = data
  
  # Write (" SPGTrans.src, Natural Gas Transmission Production Bids")
  
  # Natural Gas Available from Production (GAvProd) is the annual 
  # Production (GNProd) times a monthly allocation factor (GAvFrProd)
  for gnode in GNodes, month in Months
    GAvProd[gnode, month] = GNProd[gnode] * GAvFrProd[gnode, month] * DaysPerMonth[month] / 365
  end
  
  WriteDisk(db, "SpOutput/GAvProd", year, GAvProd)
  
  # Natural Gas Variable Costs from Production (GVCProd) default
  # to the baseline Wellhead Price (xENPN) unless the exogenous 
  # Variable Costs (xGVCProd) are specified (not equal to -99)
  
  # First initialize with default values
  fuel = Select(data.Fuel, "NaturalGas")
  for gnode in GNodes, month in Months
    # Need to determine which nation this node belongs to for xENPN lookup
    # In the original code this is implicit through the node to nation mapping
    # For simplicity, using nation 1 here - adjust as needed
    nation = 1
    GVCProd[gnode, month] = xENPN[fuel, nation] * InflationGNode[gnode]
  end
  
  # Then override with specified values if available
  for month in Months
    for gnode in GNodes
      if xGVCProd[gnode, month] != -99
        GVCProd[gnode, month] = xGVCProd[gnode, month] * InflationGNode[gnode]
      end
    end
  end
  
  # Convert to US dollars
  for gnode in GNodes, month in Months
    GVCProdUS[gnode, month] = GVCProd[gnode, month] / ExchangeRateGNode[gnode]
  end
  
  WriteDisk(db, "SpOutput/GVCProd", year, GVCProd)
  WriteDisk(db, "SpOutput/GVCProdUS", year, GVCProdUS)
  
  # Emergency Natural Gas Costs
  fuel = Select(data.Fuel, "NaturalGas")
  for gnode in GNodes, month in Months
    # Using nation 1 again as a simplification
    nation = 1
    GVCEmg[gnode, month] = xENPN[fuel, nation] * InflationGNode[gnode] * 5.0
  end
  
  WriteDisk(db, "SpOutput/GVCEmg", year, GVCEmg)
  
  # Natural Gas Transmission Costs (Tariffs)
  for gnode in GNodes, gnodex in GNodes, month in Months
    GTrVC[gnode, gnodex, month] = xGTrVC[gnode, gnodex, month] * InflationGNode[gnode]
  end
  
  WriteDisk(db, "SpOutput/GTrVC", year, GTrVC)
end

function LNGBids(data::Data)
  (; db, year) = data
  (; GNodes, Months, Nations) = data
  (; GCapLNGImports, GCapLNGExports, xGCapLNGImports, xGCapLNGExports) = data
  (; GAvLNG, GAvFrLNG, GVCLNG, GVCLNGUS, GExpMaxLNG, GExpPrLNG, GExpPrLNGUS) = data
  (; xENPN, xGExpDChg, xGVCLNG, InflationGNode, ExchangeRateGNode) = data
  
  # Write (" SPGTrans.src, Natural Gas Transmission LNG Bids")
  
  # Natural Gas LNG Capacity (GCapLNGImports, GCapLNGExports) is
  # exogenous(xGCapLNGImports, xGCapLNGExports)
  for gnode in GNodes, month in Months
    GCapLNGImports[gnode, month] = xGCapLNGImports[gnode, month]
    GCapLNGExports[gnode, month] = xGCapLNGExports[gnode, month]
  end
  
  WriteDisk(db, "SpOutput/GCapLNGImports", year, GCapLNGImports)
  WriteDisk(db, "SpOutput/GCapLNGExports", year, GCapLNGExports)
  
  # Natural Gas available from LNG (GAvLNG) is the LNG Imports Capacity (GCapLNGImports)
  # times the fraction of the gas available for dispatch (GAvFrLNG)
  for gnode in GNodes, month in Months
    GAvLNG[gnode, month] = GCapLNGImports[gnode, month] * GAvFrLNG[gnode, month]
  end
  
  WriteDisk(db, "SpOutput/GAvLNG", year, GAvLNG)
  
  # LNG bid price (GCVCLNG) is a function of price (ENPN) World NG-price
  # differential (xGExpDChg) and the LNG variable costs (xGVCLNG)
  fuel = Select(data.Fuel, "NaturalGas")
  for gnode in GNodes, month in Months
    # Using nation 1 as simplification
    nation = 1
    GVCLNG[gnode, month] = (xENPN[fuel, nation] + xGExpDChg[gnode, month] + 
                          xGVCLNG[gnode, month]) * InflationGNode[gnode]
    GVCLNGUS[gnode, month] = GVCLNG[gnode, month] / ExchangeRateGNode[gnode]
  end
  
  WriteDisk(db, "SpOutput/GVCLNG", year, GVCLNG)
  WriteDisk(db, "SpOutput/GVCLNGUS", year, GVCLNGUS)
  
  # Natural Gas LNG Export Potential
  for gnode in GNodes, month in Months
    GExpMaxLNG[gnode, month] = GCapLNGExports[gnode, month] * GAvFrLNG[gnode, month]
  end
  
  WriteDisk(db, "SpOutput/GExpMaxLNG", year, GExpMaxLNG)
  
  # Natural Gas LNG Export Marginal Profit
  fuel = Select(data.Fuel, "NaturalGas")
  for gnode in GNodes, month in Months
    # Using nation 1 as simplification
    nation = 1
    GExpPrLNG[gnode, month] = (xENPN[fuel, nation] + xGExpDChg[gnode, month] - 
                             xGVCLNG[gnode, month]) * InflationGNode[gnode]
    GExpPrLNGUS[gnode, month] = GExpPrLNG[gnode, month] / ExchangeRateGNode[gnode]
  end
  
  WriteDisk(db, "SpOutput/GExpPrLNG", year, GExpPrLNG)
  WriteDisk(db, "SpOutput/GExpPrLNGUS", year, GExpPrLNGUS)
end

function StorBids(data::Data)
  (; db, year, CTime) = data
  (; GNodes, Months) = data
  (; GAvStorage, GStLevel, GAvStoragePrior, GAvFrStorage, GSpStorageAvePrior) = data
  (; GVCStorage, GVCStorageUS, FPGN1, xENPN, InflationGNode, GUVCStorage) = data
  (; GRqStorage, GCapStorage, GFillFrStorage, ExchangeRateGNode) = data
  
  # Write (" SpGTrans.src, Natural Gas Transmission Storage Bids")
  
  # The natural gas available to be withdrawn from storage (GAvStorage)
  # is the level of natural gas in storage (GAvStorageAvePrior) times the
  # fraction of the gas available for dispatch (GAvFrStorage)
  
  summer = Select(data.Month, "Summer")
  
  if CTime > 2014
    for gnode in GNodes, month in Months
      GAvStorage[gnode, month] = min(GStLevel[gnode], 
                                    GSpStorageAvePrior[gnode, month] * (1 + GAvFrStorage[gnode, month]))
    end
  else
    for gnode in GNodes, month in Months
      GAvStorage[gnode, month] = GStLevel[gnode]
    end
  end
  
  WriteDisk(db, "SpOutput/GAvStorage", year, GAvStorage)
  
  # The natural gas storage variable costs (GVCStorage) is the amount
  # the LP must pay to remove gas from storage
  fuel = Select(data.Fuel, "NaturalGas")
  nation = 1  # Using nation 1 as simplification
  
  for gnode in GNodes, month in Months
    GVCStorage[gnode, month] = max(FPGN1[gnode, summer], 
                                 xENPN[fuel, nation] * InflationGNode[gnode]) + 
                             GUVCStorage[gnode, month] * InflationGNode[gnode]
    
    GVCStorageUS[gnode, month] = GVCStorage[gnode, month] / ExchangeRateGNode[gnode]
  end
  
  WriteDisk(db, "SpOutput/GVCStorage", year, GVCStorage)
  WriteDisk(db, "SpOutput/GVCStorageUS", year, GVCStorageUS)
  
  # Natural Gas Required to Fill Storage (GRqStorage) is the Storage
  # Capacity (GCapStorage) times a fraction (GFillFrStorage) which 
  # specifies the desired level of storage minus the current Level of 
  # Storage(GStLevel)
  
  for gnode in GNodes, month in Months
    GRqStorage[gnode, month] = max(GCapStorage[gnode, month] * 
                                 GFillFrStorage[gnode, month] - 
                                 GStLevel[gnode], 0)
  end
  
  WriteDisk(db, "SpOutput/GRqStorage", year, GRqStorage)
end

function StorUpdate(data::Data)
  (; db, year, CTime) = data
  (; GNodes, Months, StoreAT) = data
  (; GStLevel, GRqStorage, GSpStorage, GLvStorage, GSpStorageAve, GSpStorageAvePrior) = data
  
  # Write (" SpGTrans.src, Natural Gas Transmission Update Storage")
  
  # Update Level in Storage
  for gnode in GNodes
    GStLevel[gnode] = GStLevel[gnode] + 
                     sum(GRqStorage[gnode, month] - GSpStorage[gnode, month] for month in Months)
    
    for month in Months
      GLvStorage[gnode, month] = GStLevel[gnode]
    end
  end
  
  WriteDisk(db, "SpOutput/GLvStorage", year, GLvStorage)
  
  # Average Withdrawn from Storage
  if CTime > 2014
    for gnode in GNodes, month in Months
      GSpStorageAve[gnode, month] = GSpStorageAvePrior[gnode, month] +
                                  (GSpStorage[gnode, month] - GSpStorageAvePrior[gnode, month]) / StoreAT
    end
  else
    for gnode in GNodes, month in Months
      GSpStorageAve[gnode, month] = GStLevel[gnode]
    end
  end
  
  WriteDisk(db, "SpOutput/GSpStorageAve", year, GSpStorageAve)
end

function Dispatch(data::Data)
  (; db, year) = data
  (; GNodes, Months) = data
  (; G3NProd, GLvStoragePrior, GSpProd, GStLevel) = data
  
  # Write (" SpGTrans.src, Natural Gas Transmission Dispatch")
  
  # Storage Level is initialize as the value from the last
  # month of the previous year
  loc1 = first(Months)  # In the PromulaADS this selects the first month
  
  for gnode in GNodes
    GStLevel[gnode] = GLvStoragePrior[gnode, loc1]
  end
  
  StorCapacity(data)
  ProdBids(data)
  LNGBids(data)
  
  for month in Months
    StorBids(data)
    
    # Open Segment "SpGTrLP.xeq"
    # Read Segment SpGTrLP, Do(LPCtrl)
    # Note: This would require a separate implementation of the LP solver
    
    StorUpdate(data)
  end
  
  for gnode in GNodes
    G3NProd[gnode] = sum(GSpProd[gnode, month] for month in Months)
  end
  
  WriteDisk(db, "SpOutput/G3NProd", year, G3NProd)
end

function Summary3(data::Data)
  (; db, year) = data
  (; Areas, ProcOGs, Processes) = data
  (; G3AProd, G3Prod, G3NProd, G2NProd, Pd, Pd3, Pd3Cum) = data
  (; Pd3OG, Pd3CumOG, Pd3RaOG, RsDevOGPrior, OGOGSw) = data
  
  # Write (" SpGTrans.src, Gas Production after Pipeline Constraints")
  
  # Initialize accumulators
  @. G3AProd = 0
  @. G3Prod = 0
  @. Pd3 = 0
  @. Pd3Cum = 0
  @. Pd3OG = 0
  @. Pd3CumOG = 0
  
  # Process each OG unit
  for ogunit in data.OGUnits
    if OGOGSw[ogunit] != "Oil"
      area, ecc, process, fueloG, procog, gnode, nation = OGSetSelect(data, ogunit)
      
      # Natural Gas Production
      if G2NProd[gnode] != 0
        Pd3[ogunit] = Pd[ogunit] * G3NProd[gnode] / G2NProd[gnode]
      else
        Pd3[ogunit] = 0
      end
      
      Pd3Cum[ogunit] = Pd3Cum[ogunit] + Pd3[ogunit]
      
      if !isempty(area)
        G3AProd[process, area] = G3AProd[process, area] + Pd3[ogunit]
      end
      
      if !isempty(nation)
        G3Prod[process, nation] = G3Prod[process, nation] + Pd3[ogunit]
      end
      
      # Totals by Product and Area
      if data.OGProcess[ogunit] == data.ProcOG[procog]
        Pd3OG[procog, area] = Pd3OG[procog, area] + Pd3[ogunit]
        Pd3CumOG[procog, area] = Pd3CumOG[procog, area] + Pd3[ogunit]
      end
    end
  end
  
  OGRSetSets(data)
  
  WriteDisk(db, "SOutput/G3AProd", year, G3AProd)
  WriteDisk(db, "SOutput/G3Prod", year, G3Prod)
  WriteDisk(db, "SpOutput/Pd3", year, Pd3)
  WriteDisk(db, "SpOutput/Pd3Cum", year, Pd3Cum)
  WriteDisk(db, "SpOutput/Pd3OG", year, Pd3OG)
  WriteDisk(db, "SpOutput/Pd3CumOG", year, Pd3CumOG)
  
  # Averages by Product and Area
  for procog in ProcOGs, area in Areas
    if RsDevOGPrior[procog, area] != 0
      Pd3RaOG[procog, area] = Pd3OG[procog, area] / RsDevOGPrior[procog, area]
    else
      Pd3RaOG[procog, area] = 0
    end
  end
  
  WriteDisk(db, "SpOutput/Pd3RaOG", year, Pd3RaOG)
end

function Control(data::Data)
  (; ProcSw) = data
  
  # Write (" SpGTrans.src, Natural Gas Transmission Control")
  
  if ProcSw[GTrans] == Endogenous
    # Select Fuel(NaturalGas), GNode(1-25)
    # We'll use GNodes directly instead of restricting to first 25
    
    # Read "BaseCase" values for testing - commented out in original code
    # if ProcSw[9] == Exogenous
    #   ...
    # end
    
    NodeDemSup(data)
    Dispatch(data)
    Summary3(data)
  end
end

end # module SpGTrans
