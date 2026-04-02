#
# OG_OtherFugitives_IEACurves.jl
#

using EnergyModel

module OG_OtherFugitives_IEACurves

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct OGOtherFugitivesData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] # [tv] Ending Year for Simulation (Year)
  
  # Other Fugitives Reduction Curve Coefficients
  FuA0::VariableArray{2} = zeros(Float32, length(ECC), length(Area)) # [ECC,Area] A Term in Other Fugitives Reduction Curve
  FuB0::VariableArray{2} = zeros(Float32, length(ECC), length(Area)) # [ECC,Area] B Term in Other Fugitives Reduction Curve
  FuC0::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] C Term in Other Fugitives Reduction Curve
  
  # Other Fugitives Reduction Capital Cost Curve Coefficients
  FuCCA0::VariableArray{2} = zeros(Float32, length(ECC), length(Area)) # [ECC,Area] A Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCB0::VariableArray{2} = zeros(Float32, length(ECC), length(Area)) # [ECC,Area] B Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCC0::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] C Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  
  # Other variables
  FuC2H6PerCH4::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  FuCH4CapturedFraction::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] Fraction of CH4 Reduction which is Captured (Tonnes/Tonnes)
  FuCH4FlaredPOCF::VariableArray{4} = zeros(Float32, length(ECC), length(Poll), length(Area), length(Year)) # [ECC,Poll,Area,Year] Pollution Coefficient for Flared CH4 (Tonnes/Tonnes)
  FuGFr::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] Other Fugitives Reduction Grant Fraction ($/$)
  FuOCF::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] Other Fugitives Reduction Operating Cost Factor ($/$)
  FuPL::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] Other Fugitives Reduction Physical Lifetime (Years)
  FuPOCF::VariableArray{4} = zeros(Float32, length(ECC), length(Poll), length(Area), length(Year)) # [ECC,Poll,Area,Year] Other Fugitives Reduction Emission Factor (Tonnes/Tonne CH4)
  
  # Policy switches and prices
  FuPolSwitch::VariableArray{4} = zeros(Float32, length(ECC), length(Poll), length(Area), length(Year)) # [ECC,Poll,Area,Year] Fugitive Pollution Switch (0=Exogenous)
  FuPriceSw::VariableArray{1} = zeros(Float32, length(Year)) # [Year] Other Fugitives Reduction Curve Price Switch (1=Endo, 2=Carbon Price, 0=Exo)
  xFuPrice::VariableArray{3} = zeros(Float32, length(ECC), length(Area), length(Year)) # [ECC,Area,Year] Exogenous Price for Other Fugitives Reduction Curve ($/Tonne)
  xInflation::VariableArray{2} = ReadDisk(db, "MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  
  LastYear::Int = Yr(EndTime)
end

function OGOtherFugitives_SetCurveCoefficients(data)
  (; ECC, ECCDS, Area, Year, Areas, Years) = data
  (; FuA0, FuB0, FuC0, FuCCA0, FuCCB0, FuCCC0) = data
  
  # Define curve coefficient data
  curve_data = Dict(
    "Petroleum" => (126.906532, -1.81784, 0.89125),
    "LightOilMining" => (0.17128, -0.39014, 0.89125),
    "HeavyOilMining" => (0.17128, -0.39014, 0.89125),
    "FrontierOilMining" => (0.17128, -0.39014, 0.89125),
    "PrimaryOilSands" => (0.17128, -0.39014, 0.89125),
    "SAGDOilSands" => (0.17128, -0.39014, 0.89125),
    "CSSOilSands" => (0.17128, -0.39014, 0.89125),
    "OilSandsMining" => (0.17128, -0.39014, 0.89125),
    "OilSandsUpgraders" => (126.906532, -1.81784, 0.89125),
    "ConventionalGasProduction" => (0.17128, -0.39014, 0.89125),
    "SweetGasProcessing" => (0.17128, -0.39014, 0.89125),
    "UnconventionalGasProduction" => (0.17128, -0.39014, 0.89112),
    "SourGasProcessing" => (0.17128, -0.39014, 0.89125)
  )
  
  # Cost curve coefficient data
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
  for (i, ecc_name) in enumerate(ECCDS)
    if haskey(curve_data, ecc_name)
      a0, b0, c0 = curve_data[ecc_name]
      FuA0[i, 1] = a0
      FuB0[i, 1] = b0
      FuC0[i, 1, 1] = c0
    end
    
    if haskey(cost_curve_data, ecc_name)
      cca0, ccb0, ccc0 = cost_curve_data[ecc_name]
      FuCCA0[i, 1] = cca0
      FuCCB0[i, 1] = ccb0
      FuCCC0[i, 1, 1] = ccc0
    end
  end
  
  # Copy to all areas and years for CN nation
  CN = Select(data.Nation, "CN")
  areas_cn = findall(data.ANMap[:, CN] .== 1)
  
  for area in areas_cn
    for ecc in 1:length(ECC)
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
end

function OGOtherFugitives_SetEmissionFactors(data)
  (; ECC, ECCDS, Area, Year, Poll, PollDS, Areas, Years) = data
  (; FuC2H6PerCH4, FuCH4CapturedFraction, FuCH4FlaredPOCF, FuPOCF) = data
  
  # Initialize arrays
  fill!(FuC2H6PerCH4, 0.0)
  fill!(FuCH4CapturedFraction, 0.50)
  fill!(FuCH4FlaredPOCF, 0.0)
  fill!(FuPOCF, 0.0)
  
  # Set C2H6 per CH4 factors
  for (i, ecc_name) in enumerate(ECCDS)
    if ecc_name == "LightOilMining"
      FuC2H6PerCH4[i, :, :] .= 0.1085
    elseif ecc_name in ["HeavyOilMining", "PrimaryOilSands"]
      FuC2H6PerCH4[i, :, :] .= 0.0069
    end
  end
  
  # Set flared CH4 pollution coefficients
  CO2_idx = Select(Poll, "CO2")
  for (i, ecc_name) in enumerate(ECCDS)
    if ecc_name == "LightOilMining"
      FuCH4FlaredPOCF[i, CO2_idx, :, :] .= 2.4014
    elseif ecc_name in ["HeavyOilMining", "PrimaryOilSands"]
      FuCH4FlaredPOCF[i, CO2_idx, :, :] .= 1.5041
    end
  end
  
  # Set pollution coefficients
  CO2_idx = Select(Poll, "CO2")
  VOC_idx = Select(Poll, "VOC")
  
  for (i, ecc_name) in enumerate(ECCDS)
    if ecc_name == "LightOilMining"
      FuPOCF[i, CO2_idx, :, :] .= 0.1887
      FuPOCF[i, VOC_idx, :, :] .= 0.4057
    elseif ecc_name in ["HeavyOilMining", "PrimaryOilSands"]
      FuPOCF[i, CO2_idx, :, :] .= 0.0573
      FuPOCF[i, VOC_idx, :, :] .= 0.0528
    end
  end
end

function OGOtherFugitives_SetPolicyParameters(data)
  (; ECC, ECCDS, Area, Year, Poll, PollDS, Areas, Years, LastYear) = data
  (; FuGFr, FuOCF, FuPL, FuPolSwitch, FuPriceSw, xFuPrice, xInflation) = data
  
  # Set basic parameters
  fill!(FuGFr, 0.0)
  fill!(FuOCF, 0.21)
  fill!(FuPL, 15.0)
  fill!(FuPriceSw, 0.0)
  fill!(xFuPrice, 0.0)
  
  # Set pollution switches
  fill!(FuPolSwitch, 0.0)
  CH4_idx = Select(Poll, "CH4")
  CO2_idx = Select(Poll, "CO2")
  
  # Set pollution switch for specified ECCs, pollutants, and years (2026-2050)
  petroleum_eccs = ["Petroleum", "LightOilMining", "HeavyOilMining", "FrontierOilMining", 
                   "PrimaryOilSands", "SAGDOilSands", "CSSOilSands", "OilSandsMining",
                   "OilSandsUpgraders", "ConventionalGasProduction", "SweetGasProcessing",
                   "UnconventionalGasProduction", "SourGasProcessing"]
  
  for (i, ecc_name) in enumerate(ECCDS)
    if ecc_name in petroleum_eccs
      for year in Yr(2026):Yr(2050)
        if year <= LastYear
          FuPolSwitch[i, CH4_idx, :, year] .= 1.0
          FuPolSwitch[i, CO2_idx, :, year] .= 1.0
        end
      end
    end
  end
  
  # Set exogenous prices
  base_year = Yr(2020)
  for (i, ecc_name) in enumerate(ECCDS)
    if ecc_name == "LightOilMining"
      if Yr(2026) <= LastYear
        xFuPrice[i, :, Yr(2026)] .= 5.50 ./ xInflation[:, base_year]
      end
      if Yr(2027) <= LastYear
        xFuPrice[i, :, Yr(2027)] .= 4.50 ./ xInflation[:, base_year]
      end
      if Yr(2028) <= LastYear
        xFuPrice[i, :, Yr(2028)] .= 25.50 ./ xInflation[:, base_year]
      end
      if Yr(2029) <= LastYear
        xFuPrice[i, :, Yr(2029)] .= 25.50 ./ xInflation[:, base_year]
      end
      for year in Yr(2030):LastYear
        xFuPrice[i, :, year] .= 195.00 ./ xInflation[:, base_year]
      end
    elseif ecc_name in ["Petroleum", "FrontierOilMining", "SAGDOilSands", "CSSOilSands", 
                       "OilSandsMining", "OilSandsUpgraders", "ConventionalGasProduction",
                       "SweetGasProcessing", "UnconventionalGasProduction", "SourGasProcessing"]
      if Yr(2026) <= LastYear
        xFuPrice[i, :, Yr(2026)] .= 0.23 ./ xInflation[:, base_year]
      end
      if Yr(2027) <= LastYear
        xFuPrice[i, :, Yr(2027)] .= 0.35 ./ xInflation[:, base_year]
      end
      if Yr(2028) <= LastYear
        xFuPrice[i, :, Yr(2028)] .= 2.50 ./ xInflation[:, base_year]
      end
      if Yr(2029) <= LastYear
        xFuPrice[i, :, Yr(2029)] .= 25.50 ./ xInflation[:, base_year]
      end
      for year in Yr(2030):LastYear
        xFuPrice[i, :, year] .= 195.00 ./ xInflation[:, base_year]
      end
    elseif ecc_name in ["HeavyOilMining", "PrimaryOilSands"]
      if Yr(2026) <= LastYear
        xFuPrice[i, :, Yr(2026)] .= 750.0 ./ xInflation[:, base_year]
      end
      if Yr(2027) <= LastYear
        xFuPrice[i, :, Yr(2027)] .= 750.0 ./ xInflation[:, base_year]
      end
      if Yr(2028) <= LastYear
        xFuPrice[i, :, Yr(2028)] .= 750.0 ./ xInflation[:, base_year]
      end
      if Yr(2029) <= LastYear
        xFuPrice[i, :, Yr(2029)] .= 750.50 ./ xInflation[:, base_year]
      end
      for year in Yr(2030):LastYear
        xFuPrice[i, :, year] .= 900.00 ./ xInflation[:, base_year]
      end
    end
  end
end

function OGOtherFugitives_WriteDatabase(data)
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

function OGOtherFugitives_Control(db)
  @info "OGOtherFugitives_Control"
  
  data = OGOtherFugitivesData(; db)
  
  # Set curve coefficients
  OGOtherFugitives_SetCurveCoefficients(data)
  
  # Set emission factors
  OGOtherFugitives_SetEmissionFactors(data)
  
  # Set policy parameters
  OGOtherFugitives_SetPolicyParameters(data)
  
  # Write all data to database
  OGOtherFugitives_WriteDatabase(data)
  
  @info "OG_OtherFugitives_IEACurves.jl has completed successfully"
end

function PolicyControl(db)
  @info "OG_OtherFugitives_IEACurves.jl - PolicyControl"
  OGOtherFugitives_Control(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end # module
