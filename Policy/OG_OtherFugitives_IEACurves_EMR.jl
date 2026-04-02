#
# OG_OtherFugitives_IEACurves_EMR.jl
#

using EnergyModel
module OG_OtherFugitives_IEACurves_EMR
import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct OGOtherFugitivesEMRData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] # [tv] Ending Year for Simulation (Year)
  
  # Other Fugitives Reduction Curve Coefficients
  FuA0::VariableArray{2} = ReadDisk(db, "MEInput/FuA0") # [ECC,Area] A Term in Other Fugitives Reduction Curve
  FuB0::VariableArray{2} = ReadDisk(db, "MEInput/FuB0") # [ECC,Area] B Term in Other Fugitives Reduction Curve
  FuC0::VariableArray{3} = ReadDisk(db, "MEInput/FuC0") # [ECC,Area,Year] C Term in Other Fugitives Reduction Curve
  
  # Other Fugitives Reduction Capital Cost Curve Coefficients
  FuCCA0::VariableArray{2} = ReadDisk(db, "MEInput/FuCCA0") # [ECC,Area] A Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCB0::VariableArray{2} = ReadDisk(db, "MEInput/FuCCB0") # [ECC,Area] B Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCC0::VariableArray{3} = ReadDisk(db, "MEInput/FuCCC0") # [ECC,Area,Year] C Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  
  # Other variables
  FuC2H6PerCH4::VariableArray{3} = ReadDisk(db, "MEInput/FuC2H6PerCH4") # [ECC,Area,Year] C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  FuCH4CapturedFraction::VariableArray{3} = ReadDisk(db, "MEInput/FuCH4CapturedFraction") # [ECC,Area,Year] Fraction of CH4 Reduction which is Captured (Tonnes/Tonnes)
  FuCH4FlaredPOCF::VariableArray{4} = ReadDisk(db, "MEInput/FuCH4FlaredPOCF") # [ECC,Poll,Area,Year] Pollution Coefficient for Flared CH4 (Tonnes/Tonnes)
  FuGFr::VariableArray{3} = ReadDisk(db, "MEInput/FuGFr") # [ECC,Area,Year] Other Fugitives Reduction Grant Fraction ($/$)
  FuOCF::VariableArray{3} = ReadDisk(db, "MEInput/FuOCF") # [ECC,Area,Year] Other Fugitives Reduction Operating Cost Factor ($/$)
  FuPL::VariableArray{3} = ReadDisk(db, "MEInput/FuPL") # [ECC,Area,Year] Other Fugitives Reduction Physical Lifetime (Years)
  FuPOCF::VariableArray{4} = ReadDisk(db, "MEInput/FuPOCF") # [ECC,Poll,Area,Year] Other Fugitives Reduction Emission Factor (Tonnes/Tonne CH4)
  
  # Policy switches and prices
  FuPolSwitch::VariableArray{4} = ReadDisk(db, "SInput/FuPolSwitch") # [ECC,Poll,Area,Year] Fugitive Pollution Switch (0=Exogenous)
  FuPriceSw::VariableArray{1} = ReadDisk(db, "MEInput/FuPriceSw") # [Year] Other Fugitives Reduction Curve Price Switch (1=Endo, 2=Carbon Price, 0=Exo)
  xFuPrice::VariableArray{3} = ReadDisk(db, "MEInput/xFuPrice") # [ECC,Area,Year] Exogenous Price for Other Fugitives Reduction Curve ($/Tonne)
  xInflation::VariableArray{2} = ReadDisk(db, "MInput/xInflation") # [Area,Year] Inflation Index ($/$)
end

function OGOtherFugitivesEMR_SetCurveCoefficients(data)
  (; ECC, ECCDS, Area, Year, Areas, Years) = data
  (; FuA0, FuB0, FuC0, FuCCA0, FuCCB0, FuCCC0) = data
  
  # Define curve coefficient data (EMR version with different values)
  curve_data = Dict(
    "Petroleum" => (126.906532, -1.81784, 0.89125),
    "LightOilMining" => (0.17128, -0.39014, 0.88125),          # Different C0 value
    "HeavyOilMining" => (0.17128, -0.39014, 0.88125),          # Different C0 value
    "FrontierOilMining" => (0.17128, -0.39014, 0.89125),
    "PrimaryOilSands" => (0.17128, -0.39014, 0.89125),
    "SAGDOilSands" => (0.17128, -0.39014, 0.89125),
    "CSSOilSands" => (0.17128, -0.39014, 0.89125),
    "OilSandsMining" => (0.17128, -0.39014, 0.89125),
    "OilSandsUpgraders" => (126.906532, -1.81784, 0.89125),
    "ConventionalGasProduction" => (0.17128, -0.39014, 0.89125),
    "SweetGasProcessing" => (0.17128, -0.39014, 0.89125),
    "UnconventionalGasProduction" => (0.17128, -0.39014, 0.85112),  # Different C0 value
    "SourGasProcessing" => (0.17128, -0.39014, 0.89125)
  )
  
  # Cost curve coefficient data (same as original)
  cost_curve_data = Dict(
    "Petroleum" => (617.867, -1.97779, 898.71000),
    "LightOilMining" => (17.6561, -1.09068, 350.58000),
    "HeavyOilMining" => (17.6561, -1.09068, 350.58000),
    "FrontierOilMining" => (17.6561, -1.09068, 350.58000),
    "PrimaryOilSands" => (17.6561, -1.09068, 350.58000),
    "SAGDOilSands" => (17.6561, -1.09068, 350.58000),
    "CSSOilSands" => (17.6561, -1.09068, 350.58000),
    "OilSandsMining" => (17.6561, -1.09068, 350.58000),
    "OilSandsUpgraders" => (617.867, -1.97779, 898.71000),
    "ConventionalGasProduction" => (1.91443, -1.07756, 75.841930),
    "SweetGasProcessing" => (617.867, -1.97779, 898.71000),
    "UnconventionalGasProduction" => (17.6561, -1.09068, 350.58000),
    "SourGasProcessing" => (617.867, -1.97779, 898.71000)
  )
  
  # Set curve coefficients for first area and year, then copy to all areas and years
  petroleum_eccs = Select(ECC, ["Petroleum", "LightOilMining", "HeavyOilMining", "FrontierOilMining", 
                                "PrimaryOilSands", "SAGDOilSands", "CSSOilSands", "OilSandsMining",
                                "OilSandsUpgraders", "ConventionalGasProduction", "SweetGasProcessing",
                                "UnconventionalGasProduction", "SourGasProcessing"])
  
  for ecc in petroleum_eccs
    ecc_name = ECC[ecc]
    if haskey(curve_data, ecc_name)
      a0, b0, c0 = curve_data[ecc_name]
      FuA0[ecc, 1] = a0
      FuB0[ecc, 1] = b0
      FuC0[ecc, 1, 1] = c0
    end
    
    if haskey(cost_curve_data, ecc_name)
      cca0, ccb0, ccc0 = cost_curve_data[ecc_name]
      FuCCA0[ecc, 1] = cca0
      FuCCB0[ecc, 1] = ccb0
      FuCCC0[ecc, 1, 1] = ccc0
    end
  end
  
  # Copy to all areas and years for CN nation
  CN = Select(data.Nation, "CN")
  areas_cn = findall(data.ANMap[:, CN] .== 1)
  
  for ecc in petroleum_eccs, area in areas_cn
    FuA0[ecc, area] = FuA0[ecc, 1]
    FuB0[ecc, area] = FuB0[ecc, 1]
    FuCCA0[ecc, area] = FuCCA0[ecc, 1]
    FuCCB0[ecc, area] = FuCCB0[ecc, 1]
    
    for year in Years
      FuC0[ecc, area, year] = FuC0[ecc, 1, 1]
      FuCCC0[ecc, area, year] = FuCCC0[ecc, 1, 1]
    end
  end
end

function OGOtherFugitivesEMR_SetEmissionFactors(data)
  (; ECC, ECCs, Area, Areas, Year, Poll, Polls, Areas, Years) = data
  (; FuC2H6PerCH4, FuCH4CapturedFraction, FuCH4FlaredPOCF, FuPOCF) = data
  
  # Initialize arrays
  for ecc in ECCs, area in Areas, year in Years
    FuC2H6PerCH4[ecc, area, year] = 0.0
    FuCH4CapturedFraction[ecc, area, year] = 0.50
  end
  
  for ecc in ECCs, poll in Polls, area in Areas, year in Years
    FuCH4FlaredPOCF[ecc, poll, area, year] = 0.0
    FuPOCF[ecc, poll, area, year] = 0.0
  end
  
  # Set C2H6 per CH4 factors
  light_oil_mining = Select(ECC, "LightOilMining")
  heavy_oil_primary_sands = Select(ECC, ["HeavyOilMining", "PrimaryOilSands"])
  
  for area in Areas, year in Years
    FuC2H6PerCH4[light_oil_mining, area, year] = 0.1085
    for ecc in heavy_oil_primary_sands
      FuC2H6PerCH4[ecc, area, year] = 0.0069
    end
  end
  
  # Set flared CH4 pollution coefficients
  CO2_idx = Select(Poll, "CO2")
  for area in Areas, year in Years
    FuCH4FlaredPOCF[light_oil_mining, CO2_idx, area, year] = 2.4014
    for ecc in heavy_oil_primary_sands
      FuCH4FlaredPOCF[ecc, CO2_idx, area, year] = 1.5041
    end
  end
  
  # Set pollution coefficients
  CO2_idx = Select(Poll, "CO2")
  VOC_idx = Select(Poll, "VOC")
  
  for area in Areas, year in Years
    FuPOCF[light_oil_mining, CO2_idx, area, year] = 0.1887
    FuPOCF[light_oil_mining, VOC_idx, area, year] = 0.4057
    
    for ecc in heavy_oil_primary_sands
      FuPOCF[ecc, CO2_idx, area, year] = 0.0573
      FuPOCF[ecc, VOC_idx, area, year] = 0.0528
    end
  end
end

function OGOtherFugitivesEMR_SetPolicyParameters(data)
  (; ECC, ECCDS, Area, Year, Poll, PollDS, Areas, Years) = data
  (; FuGFr, FuOCF, FuPL, FuPolSwitch, FuPriceSw, xFuPrice, xInflation) = data
  
  # Set basic parameters
  fill!(FuGFr, 0.0)
  fill!(FuOCF, 0.21)
  fill!(FuPL, 15.0)
  fill!(FuPriceSw, 0.0)
  
  # Set pollution switches
  CH4_idx = Select(Poll, "CH4")
  CO2_idx = Select(Poll, "CO2")
  
  # Set pollution switch for specified ECCs, pollutants, and years (2027-2050, different from original)
  petroleum_eccs = Select(ECC,["Petroleum", "LightOilMining", "HeavyOilMining", "FrontierOilMining", 
                   "PrimaryOilSands", "SAGDOilSands", "CSSOilSands", "OilSandsMining",
                   "OilSandsUpgraders", "ConventionalGasProduction", "SweetGasProcessing",
                   "UnconventionalGasProduction", "SourGasProcessing"])
  
  for ecc in petroleum_eccs, area in Areas, year in Yr(2027):Yr(2050)  # EMR starts in 2027, not 2026
    FuPolSwitch[ecc, CH4_idx, area, year] = 1.0
    FuPolSwitch[ecc, CO2_idx, area, year] = 1.0
  end
  
  # Set exogenous prices (EMR version with simplified pricing structure)
  base_year = Yr(2020)
  petroleum_eccs_for_pricing = Select(ECC,["Petroleum", "LightOilMining", "HeavyOilMining", "FrontierOilMining", 
                               "PrimaryOilSands", "SAGDOilSands", "CSSOilSands", "OilSandsMining",
                               "OilSandsUpgraders", "ConventionalGasProduction", "SweetGasProcessing",
                               "UnconventionalGasProduction", "SourGasProcessing"])
  years = Yr(2030):Final
  for ecc in petroleum_eccs_for_pricing, area in Areas
    xFuPrice[ecc, area, Yr(2027)] = 0.35 / xInflation[area, base_year]
    xFuPrice[ecc, area, Yr(2028)] = 2.50 / xInflation[area, base_year]
    xFuPrice[ecc, area, Yr(2029)] = 25.50 / xInflation[area, base_year]
    for year in years
      xFuPrice[ecc, area, year] = 99.00 / xInflation[area, base_year]  # Different final price: 99.00 instead of 195.00
    end
  end
end

function OGOtherFugitivesEMR_WriteDatabase(data)
  (; db) = data
  (; FuA0, FuB0, FuC0, FuCCA0, FuCCB0, FuCCC0) = data
  (; FuC2H6PerCH4, FuCH4CapturedFraction, FuCH4FlaredPOCF, FuGFr, FuOCF, FuPL, FuPOCF) = data
  (; FuPolSwitch, FuPriceSw, xFuPrice) = data
  
  # Write all variables to database
  WriteDisk(db, "MEInput/FuA0", FuA0)
  WriteDisk(db, "MEInput/FuB0", FuB0)
  WriteDisk(db, "MEInput/FuC0", FuC0)
  WriteDisk(db, "MEInput/FuCCA0", FuCCA0)
  WriteDisk(db, "MEInput/FuCCB0", FuCCB0)
  WriteDisk(db, "MEInput/FuCCC0", FuCCC0)
  WriteDisk(db, "MEInput/FuC2H6PerCH4", FuC2H6PerCH4)
  WriteDisk(db, "MEInput/FuCH4CapturedFraction", FuCH4CapturedFraction)
  WriteDisk(db, "MEInput/FuCH4FlaredPOCF", FuCH4FlaredPOCF)
  WriteDisk(db, "MEInput/FuGFr", FuGFr)
  WriteDisk(db, "MEInput/FuOCF", FuOCF)
  WriteDisk(db, "MEInput/FuPL", FuPL)
  WriteDisk(db, "MEInput/FuPOCF", FuPOCF)
  WriteDisk(db, "SInput/FuPolSwitch", FuPolSwitch)
  WriteDisk(db, "MEInput/FuPriceSw", FuPriceSw)
  WriteDisk(db, "MEInput/xFuPrice", xFuPrice)
end

function OGOtherFugitivesEMR_Control(db)
  #@info "OGOtherFugitivesEMR_Control"
  
  data = OGOtherFugitivesEMRData(; db)
  
  # Set curve coefficients
  OGOtherFugitivesEMR_SetCurveCoefficients(data)
  
  # Set emission factors
  OGOtherFugitivesEMR_SetEmissionFactors(data)
  
  # Set policy parameters
  OGOtherFugitivesEMR_SetPolicyParameters(data)
  
  # Write all data to database
  OGOtherFugitivesEMR_WriteDatabase(data)
  
  #@info "OG_OtherFugitives_IEACurves_EMR.jl has completed successfully"
end

function PolicyControl(db)
  @info "OG_OtherFugitives_IEACurves_EMR.jl - PolicyControl"
  OGOtherFugitivesEMR_Control(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
