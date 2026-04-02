#
# OG_Venting_IEACurves.jl
#
# This file implements venting reduction curve coefficients and parameters
# for oil and gas operations
#

using EnergyModel

module OG_Venting_IEACurves

import ...EnergyModel: ReadDisk,WriteDisk,Select,HisTime,ITime,MaxTime,First,Future,DB,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct VentingControl
  db::String
  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  
  # Venting Reduction Curve Coefficients
  VnA0::VariableArray{2} = ReadDisk(db,"MEInput/VnA0") # [ECC,Area] A Term in Venting Reduction Curve
  VnB0::VariableArray{2} = ReadDisk(db,"MEInput/VnB0") # [ECC,Area] B Term in Venting Reduction Curve  
  VnC0::VariableArray{3} = ReadDisk(db,"MEInput/VnC0") # [ECC,Area,Year] C Term in Venting Reduction Curve
  
  # Venting Reduction Capital Cost Curve Coefficients
  VnCCA0::VariableArray{2} = ReadDisk(db,"MEInput/VnCCA0") # [ECC,Area] A Term in Venting Reduction Capital Cost Curve ($/$)
  VnCCB0::VariableArray{2} = ReadDisk(db,"MEInput/VnCCB0") # [ECC,Area] B Term in Venting Reduction Capital Cost Curve ($/$)
  VnCCC0::VariableArray{3} = ReadDisk(db,"MEInput/VnCCC0") # [ECC,Area,Year] C Term in Venting Reduction Capital Cost Curve ($/$)
  
  # Other venting parameters
  VnC2H6PerCH4::VariableArray{3} = ReadDisk(db,"MEInput/VnC2H6PerCH4") # [ECC,Area,Year] C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  VnCH4CapturedFraction::VariableArray{3} = ReadDisk(db,"MEInput/VnCH4CapturedFraction") # [ECC,Area,Year] Fraction of CH4 Reduction which is Captured (Tonnes/Tonnes)
  VnCH4FlaredPOCF::VariableArray{4} = ReadDisk(db,"MEInput/VnCH4FlaredPOCF") # [ECC,Poll,Area,Year] Pollution Coefficient for Flared CH4 (Tonnes/Tonnes)
  VnGFr::VariableArray{3} = ReadDisk(db,"MEInput/VnGFr") # [ECC,Area,Year] Venting Reduction Grant Fraction ($/$)
  VnOCF::VariableArray{3} = ReadDisk(db,"MEInput/VnOCF") # [ECC,Area,Year] Venting Reduction Operating Cost Factor ($/$)
  VnPL::VariableArray{3} = ReadDisk(db,"MEInput/VnPL") # [ECC,Area,Year] Venting Reduction Physical Lifetime (Years)
  VnPOCF::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCF") # [ECC,Poll,Area,Year] Venting Reduction Emission Factor (Tonnes/Tonne CH4)
  VnPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/VnPolSwitch") # [ECC,Poll,Area,Year] Venting Pollution Switch (0=Exogenous)
  VnPriceSw::VariableArray{1} = ReadDisk(db,"MEInput/VnPriceSw") # [Year] Venting Reduction Curve Price Switch (1=Endo, 2=Carbon Price, 0=Exo)
  xVnPrice::VariableArray{3} = ReadDisk(db,"MEInput/xVnPrice") # [ECC,Area,Year] Exogenous Price for Venting Reduction Curve ($/Tonne)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
end

function SetVentingReductionCurveCoefficients(data)
  (; ECC, Area, Year, Areas, Years) = data
  (; VnA0, VnB0, VnC0) = data
  
  # Define the venting reduction curve coefficients for each ECC type
  venting_coeffs = Dict(
    "Petroleum" => (1.20222, -0.61051, 0.25817),
    "LightOilMining" => (1.00012, -0.39966, 0.75006),
    "HeavyOilMining" => (1.00012, -0.39966, 0.75006),
    "FrontierOilMining" => (1.00012, -0.39966, 0.75006),
    "PrimaryOilSands" => (0.96506, -0.39206, 0.73983),
    "SAGDOilSands" => (0.96506, -0.39206, 0.73983),
    "CSSOilSands" => (0.96506, -0.39206, 0.73983),
    "OilSandsMining" => (0.96506, -0.39206, 0.73983),
    "OilSandsUpgraders" => (1.20222, -0.61051, 0.25817),
    "ConventionalGasProduction" => (0.87861, -0.26958, 0.78986),
    "SweetGasProcessing" => (0.62732, -0.41135, 0.77346),
    "UnconventionalGasProduction" => (0.62732, -0.41135, 0.78952),
    "SourGasProcessing" => (0.62732, -0.41135, 0.77346)
  )
  
  # Set coefficients for relevant ECC types
  for (ecc_name, (a0, b0, c0)) in venting_coeffs
    if ecc_name in ECC
      ecc = Select(ECC, ecc_name)
      for area in Areas, year in Years
        VnA0[ecc, area] = Float32(a0)
        VnB0[ecc, area] = Float32(b0)  
        VnC0[ecc, area, year] = Float32(c0)
      end
    end
  end
end

function SetVentingCapitalCostCurveCoefficients(data)
  (; ECC, Area, Year, Areas, Years) = data
  (; VnCCA0, VnCCB0, VnCCC0) = data
  
  # Define the venting capital cost curve coefficients for each ECC type
  capital_cost_coeffs = Dict(
    "Petroleum" => (1.61e04, -2.68985, 2782.55),
    "LightOilMining" => (45.5995, -1.02371, 1093.73),
    "HeavyOilMining" => (45.5995, -1.02371, 1093.73),
    "FrontierOilMining" => (45.5995, -1.02371, 1093.73),
    "PrimaryOilSands" => (61.5991, -0.95742, 1109.74),
    "SAGDOilSands" => (61.5991, -0.95742, 1109.74),
    "CSSOilSands" => (61.5991, -0.95742, 1109.74),
    "OilSandsMining" => (61.5991, -0.95742, 1109.74),
    "OilSandsUpgraders" => (1.61e04, -2.68985, 2782.55),
    "ConventionalGasProduction" => (175.151, -0.85485, 1647.14),
    "SweetGasProcessing" => (54.9585, -1.09057, 2232.29),
    "UnconventionalGasProduction" => (122.709, -1.12584, 1647.88),
    "SourGasProcessing" => (54.9585, -1.09057, 2232.29)
  )
  
  # Set coefficients for relevant ECC types
  for (ecc_name, (cca0, ccb0, ccc0)) in capital_cost_coeffs
    if ecc_name in ECC
      ecc = Select(ECC, ecc_name)
      for area in Areas, year in Years
        VnCCA0[ecc, area] = Float32(cca0)
        VnCCB0[ecc, area] = Float32(ccb0)
        VnCCC0[ecc, area, year] = Float32(ccc0)
      end
    end
  end
end

function SetC2H6Parameters(data)
  (; ECC, Area, Year, Areas, Years) = data
  (; VnC2H6PerCH4) = data
  
  # Initialize all to zero
  VnC2H6PerCH4 .= 0.0
  
  # Set specific values for different ECC types
  light_oil = Select(ECC, "LightOilMining")
  for area in Areas, year in Years
    VnC2H6PerCH4[light_oil, area, year] = 0.1085
  end
  
  heavy_oil_types = ["HeavyOilMining", "PrimaryOilSands"]
  heavy_eccs = Select(ECC, heavy_oil_types)
  for ecc in heavy_eccs, area in Areas, year in Years
    VnC2H6PerCH4[ecc, area, year] = 0.0069
  end
end

function SetCH4Parameters(data)
  (; ECC, Poll, Area, Year, Areas, Years, Polls) = data
  (; VnCH4CapturedFraction, VnCH4FlaredPOCF) = data
  
  # Set CH4 captured fraction to 0.5 for all
  VnCH4CapturedFraction .= 0.50
  
  # Initialize flared pollution coefficients to zero
  VnCH4FlaredPOCF .= 0.0
  
  # Set CO2 pollution coefficients for flared CH4
  co2 = Select(Poll, "CO2")
  
  light_oil = Select(ECC, "LightOilMining")
  for area in Areas, year in Years
    VnCH4FlaredPOCF[light_oil, co2, area, year] = 2.4014
  end
  
  heavy_oil_types = ["HeavyOilMining", "PrimaryOilSands"]
  heavy_eccs = Select(ECC, heavy_oil_types)
  for ecc in heavy_eccs, area in Areas, year in Years
    VnCH4FlaredPOCF[ecc, co2, area, year] = 1.5041
  end
end

function SetOtherVentingParameters(data)
  (; ECC, Area, Year, Areas, Years) = data
  (; VnGFr, VnOCF, VnPL) = data
  
  # Set grant fraction to zero
  VnGFr .= 0.0
  
  # Set operating cost factor to 0.21
  VnOCF .= 0.21
  
  # Set physical lifetime to 15 years
  VnPL .= 15.0
end

function SetPollutionCoefficients(data)
  (; ECC, Poll, Area, Year, Areas, Years) = data
  (; VnPOCF) = data
  
  # Initialize to zero
  VnPOCF .= 0.0
  
  # Set CO2 coefficients
  co2 = Select(Poll, "CO2")
  
  light_oil = Select(ECC, "LightOilMining")
  for area in Areas, year in Years
    VnPOCF[light_oil, co2, area, year] = 0.1887
  end
  
  heavy_oil_types = ["HeavyOilMining", "PrimaryOilSands"]
  heavy_eccs = Select(ECC, heavy_oil_types)
  for ecc in heavy_eccs, area in Areas, year in Years
    VnPOCF[ecc, co2, area, year] = 0.0573
  end
  
  # Set VOC coefficients  
  voc = Select(Poll, "VOC")
  
  light_oil = Select(ECC, "LightOilMining")
  for area in Areas, year in Years
    VnPOCF[light_oil, voc, area, year] = 0.4057
  end
  
  heavy_eccs = Select(ECC, heavy_oil_types)
  for ecc in heavy_eccs, area in Areas, year in Years
    VnPOCF[ecc, voc, area, year] = 0.0528
  end
end

function SetPolicySwitches(data)
  (; ECC, Poll, Area, Year, Areas, Years) = data
  (; VnPolSwitch, VnPriceSw) = data
  
  # Initialize pollution switches to zero
  VnPolSwitch .= 0.0
  
  # Set pollution switches for oil and gas operations for CH4 and CO2 from 2026-2050
  og_ecc_types = ["Petroleum", "LightOilMining", "HeavyOilMining", "FrontierOilMining", 
                  "PrimaryOilSands", "SAGDOilSands", "CSSOilSands", "OilSandsMining",
                  "OilSandsUpgraders", "ConventionalGasProduction", "SweetGasProcessing",
                  "UnconventionalGasProduction", "SourGasProcessing"]
  
  poll_types = ["CH4", "CO2"]
  years = Yr(2026):Yr(2050)
  
  og_eccs = Select(ECC, og_ecc_types)
  polls = Select(Poll, poll_types)
  
  for ecc in og_eccs, poll in polls, area in Areas, year in years
    VnPolSwitch[ecc, poll, area, year] = 1.0
  end
  
  # Set price switches
  VnPriceSw .= 1.0
  future_years = Future:Final
  for year in future_years
    VnPriceSw[year] = 0.0
  end
end

function SetExogenousPrices(data)
  (; ECC, Area, Year, Areas, Years) = data
  (; xVnPrice, xInflation) = data
  
  # Initialize prices to zero
  xVnPrice .= 0.0
  
  # Set prices for LightOilMining
  light_oil = Select(ECC, "LightOilMining")
  for area in Areas
    # 2026
    year = Yr(2026)
    xVnPrice[light_oil, area, year] = 5.50 / xInflation[area, Yr(2020)]
    
    # 2027  
    year = Yr(2027)
    xVnPrice[light_oil, area, year] = 4.50 / xInflation[area, Yr(2020)]
    
    # 2028
    year = Yr(2028) 
    xVnPrice[light_oil, area, year] = 25.00 / xInflation[area, Yr(2020)]
    
    # 2029
    year = Yr(2029)
    xVnPrice[light_oil, area, year] = 25.00 / xInflation[area, Yr(2020)]
    
    # 2030-Final
    years = Yr(2030):Final
    for year in years
      xVnPrice[light_oil, area, year] = 195.00 / xInflation[area, Yr(2020)]
    end
  end
  
  # Set prices for other oil and gas types (excluding HeavyOilMining and PrimaryOilSands)
  other_og_types = ["Petroleum", "FrontierOilMining", "SAGDOilSands", "CSSOilSands", 
                    "OilSandsMining", "OilSandsUpgraders", "ConventionalGasProduction", 
                    "SweetGasProcessing", "UnconventionalGasProduction", "SourGasProcessing"]
  
  eccs = Select(ECC, other_og_types)
  for ecc in eccs, area in Areas
    # 2026
    year = Yr(2026)
    xVnPrice[ecc, area, year] = 0.23 / xInflation[area, Yr(2020)]
    
    # 2027
    year = Yr(2027)
    xVnPrice[ecc, area, year] = 0.35 / xInflation[area, Yr(2020)]
    
    # 2028
    year = Yr(2028)
    xVnPrice[ecc, area, year] = 2.00 / xInflation[area, Yr(2020)]
    
    # 2029
    year = Yr(2029)
    xVnPrice[ecc, area, year] = 25.00 / xInflation[area, Yr(2020)]
    
    # 2030-Final
    years = Yr(2030):Final
    for year in years
      xVnPrice[ecc, area, year] = 195.00 / xInflation[area, Yr(2020)]
    end
  end
  
  # Set prices for HeavyOilMining and PrimaryOilSands
  heavy_types = ["HeavyOilMining", "PrimaryOilSands"]
  
  heavy_eccs = Select(ECC, heavy_types)  
  for ecc in heavy_eccs, area in Areas
    # 2026-2028
    years = Yr(2026):Yr(2028)
    for year in years
      xVnPrice[ecc, area, year] = 750.0 / xInflation[area, Yr(2020)]
    end
    
    # 2029
    year = Yr(2029)
    xVnPrice[ecc, area, year] = 750.50 / xInflation[area, Yr(2020)]
    
    # 2030-Final
    years = Yr(2030):Final
    for year in years
      xVnPrice[ecc, area, year] = 900.00 / xInflation[area, Yr(2020)]
    end
  end
end

function VentingPolicy(db)
  data = VentingControl(; db)
  
  @info "OG_Venting_IEACurves.jl - VentingPolicy"
  
  # Set venting reduction curve coefficients
  SetVentingReductionCurveCoefficients(data)
  WriteDisk(db, "MEInput/VnA0", data.VnA0)
  WriteDisk(db, "MEInput/VnB0", data.VnB0)
  WriteDisk(db, "MEInput/VnC0", data.VnC0)
  
  # Set venting capital cost curve coefficients  
  SetVentingCapitalCostCurveCoefficients(data)
  WriteDisk(db, "MEInput/VnCCA0", data.VnCCA0)
  WriteDisk(db, "MEInput/VnCCB0", data.VnCCB0)
  WriteDisk(db, "MEInput/VnCCC0", data.VnCCC0)
  
  # Set C2H6 parameters
  SetC2H6Parameters(data)
  WriteDisk(db, "MEInput/VnC2H6PerCH4", data.VnC2H6PerCH4)
  
  # Set CH4 parameters
  SetCH4Parameters(data)
  WriteDisk(db, "MEInput/VnCH4CapturedFraction", data.VnCH4CapturedFraction)
  WriteDisk(db, "MEInput/VnCH4FlaredPOCF", data.VnCH4FlaredPOCF)
  
  # Set other venting parameters
  SetOtherVentingParameters(data)
  WriteDisk(db, "MEInput/VnGFr", data.VnGFr)
  WriteDisk(db, "MEInput/VnOCF", data.VnOCF)
  WriteDisk(db, "MEInput/VnPL", data.VnPL)
  
  # Set pollution coefficients
  SetPollutionCoefficients(data)
  WriteDisk(db, "MEInput/VnPOCF", data.VnPOCF)
  
  # Set policy switches
  SetPolicySwitches(data)
  WriteDisk(db, "SInput/VnPolSwitch", data.VnPolSwitch)
  WriteDisk(db, "MEInput/VnPriceSw", data.VnPriceSw)
  
  # Set exogenous prices
  SetExogenousPrices(data)
  WriteDisk(db, "MEInput/xVnPrice", data.xVnPrice)
end

if abspath(PROGRAM_FILE) == @__FILE__
  VentingPolicy(DB)
end

end
