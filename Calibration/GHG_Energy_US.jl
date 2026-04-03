#
# GHG_Energy_US.jl - Reads in U.S. GHG emission factors
#
using EnergyModel

module GHG_Energy_US

import ...EnergyModel: ReadDisk, WriteDisk, Select
import ...EnergyModel: HisTime, ITime, MaxTime, First, Future, Final, Yr
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

# Common data structures for emissions data
struct EmissionsRecord
  year::String
  fuel::String
  area::String
  sector::String
  co2::Float32
  n2o::Float32
  ch4::Float32
end

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB")

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap")
  CgPOCX::VariableArray{5} = ReadDisk(db, "$Input/CgPOCX")
  POCX::VariableArray{6} = ReadDisk(db, "$Input/POCX")
end

const residential_emissions_data = [
  #                Year   Fuel          Area   Sector   CO2        N2O     CH4
  EmissionsRecord("All", "Biomass",     "All", "All",   0.000,     8.889,  795.155),
  EmissionsRecord("All", "Coal",        "All", "All",   83579.461, 0.742,  1.113),
  EmissionsRecord("All", "Coke",        "All", "All",   0.000,     0.000,  0.000),
  EmissionsRecord("All", "CokeOvenGas", "All", "All",   0.000,     0.000,  0.000),
  EmissionsRecord("All", "CrudeOil",    "All", "All",   0.000,     0.000,  0.000),
  EmissionsRecord("All", "Diesel",      "All", "All",   69530.026, 10.444, 3.480),
  EmissionsRecord("All", "HFO",         "All", "All",   73505.882, 1.506,  1.341),
  EmissionsRecord("All", "Kerosene",    "All", "All",   67250.531, 0.159,  0.690),
  EmissionsRecord("All", "Biogas",      "All", "All",   0.000,     0.000,  0.000),
  EmissionsRecord("All", "LFO",         "All", "All",   70231.959, 0.799,  0.670),
  EmissionsRecord("All", "LPG",         "All", "All",   59660.213, 4.267,  1.067),
  EmissionsRecord("All", "NaturalGas",  "All", "All",   49424.987, 0.915,  0.967),
  EmissionsRecord("All", "PetroCoke",   "All", "All",   82330.097, 0.429,  2.589)
  # EmissionsRecord("All", "StillGas",    "All", "All",   46754.099, 0.001,  0.000)
]

function process_emissions!(data::RControl, records::Vector{EmissionsRecord})
  us = Select(data.Nation, "US")
  areas = findall(a -> data.ANMap[a, us] == 1, data.Areas)

  co2 = Select(data.Poll, "CO2")
  n2o = Select(data.Poll, "N2O")
  ch4 = Select(data.Poll, "CH4")

  for record in records
    # Match year, area, and fuel selections
    years = record.year == "All" ? data.Years : findall(y -> data.Year[y] == record.year, data.Years)
    fuelep = Select(data.FuelEP, record.fuel)

    for year in years, area in areas
      # Set coefficients for each pollutant
      for enduse in data.Enduses, ec in data.ECs
        # Convert from PJ to TBtu using 1.054615 factor
        data.POCX[enduse, fuelep, ec, co2, area, year] = record.co2 * 1.054615
        data.POCX[enduse, fuelep, ec, n2o, area, year] = record.n2o * 1.054615
        data.POCX[enduse, fuelep, ec, ch4, area, year] = record.ch4 * 1.054615

        # Set cogeneration coefficients
        data.CgPOCX[fuelep, ec, co2, area, year] = record.co2 * 1.054615
        data.CgPOCX[fuelep, ec, n2o, area, year] = record.n2o * 1.054615
        data.CgPOCX[fuelep, ec, ch4, area, year] = record.ch4 * 1.054615
      end
    end
  end
end

function RCalibration(db)
  data = RControl(; db)
  process_emissions!(data, residential_emissions_data)

  WriteDisk(db, "$(data.Input)/POCX", data.POCX)
  WriteDisk(db, "$(data.Input)/CgPOCX", data.CgPOCX)
end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB")

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap")
  CgPOCX::VariableArray{5} = ReadDisk(db, "$Input/CgPOCX")
  POCX::VariableArray{6} = ReadDisk(db, "$Input/POCX")
end

const commercial_emissions_data = [
  #                Year   Fuel          Area   Sector         CO2        N2O     CH4
  EmissionsRecord("All", "Biomass",     "All", "All",         0.000,     8.889,  833.333),
  EmissionsRecord("All", "Coal",        "All", "All",         83579.461, 0.742,  1.113),
  EmissionsRecord("All", "Coke",        "All", "All",         0.000,     0.000,  0.000),
  EmissionsRecord("All", "CokeOvenGas", "All", "All",         0.000,     0.000,  0.000),
  EmissionsRecord("All", "CrudeOil",    "All", "All",         0.000,     0.000,  0.000),
  EmissionsRecord("All", "Diesel",      "All", "All",         69530.026, 10.444, 3.480),
  EmissionsRecord("All", "HFO",         "All", "All",         73505.882, 1.506,  1.341),
  EmissionsRecord("All", "Kerosene",    "All", "All",         67250.531, 0.823,  0.690),
  EmissionsRecord("All", "Biogas",      "All", "All",         0.000,     0.000,  0.000),
  EmissionsRecord("All", "LFO",         "All", "All",         70231.959, 0.155,  0.670),
  EmissionsRecord("All", "LPG",         "All", "All",         59660.213, 4.267,  0.948),
  EmissionsRecord("All", "NaturalGas",  "All", "All",         49424.987, 0.915,  0.967),
  EmissionsRecord("All", "PetroCoke",   "All", "All",         82330.097, 0.429,  2.589),
  EmissionsRecord("All", "StillGas",    "All", "All",         46754.099, 0.001,  0.000)
  # EmissionsRecord("All", "NaturalGas",  "All", "Pipelines",   49424.987, 1.307,  49.660)
]

function process_commercial_emissions!(data::CControl, records::Vector{EmissionsRecord})
  us = Select(data.Nation, "US")
  areas = findall(a -> data.ANMap[a, us] == 1, data.Areas)

  co2 = Select(data.Poll, "CO2")
  n2o = Select(data.Poll, "N2O")
  ch4 = Select(data.Poll, "CH4")

  for record in records
    years = record.year == "All" ? data.Years : findall(y -> data.Year[y] == record.year, data.Years)
    fuelep = Select(data.FuelEP, record.fuel)

    # Handle special case for pipelines sector
    ecs = if record.sector == "Pipelines"
      Select(data.EC, "NGPipeline")
    else
      data.ECs
    end

    for year in years, area in areas, ec in ecs
      for enduse in data.Enduses
        data.POCX[enduse, fuelep, ec, co2, area, year] = record.co2 * 1.054615
        data.POCX[enduse, fuelep, ec, n2o, area, year] = record.n2o * 1.054615
        data.POCX[enduse, fuelep, ec, ch4, area, year] = record.ch4 * 1.054615
      end

      data.CgPOCX[fuelep, ec, co2, area, year] = record.co2 * 1.054615
      data.CgPOCX[fuelep, ec, n2o, area, year] = record.n2o * 1.054615
      data.CgPOCX[fuelep, ec, ch4, area, year] = record.ch4 * 1.054615
    end
  end
end

function CCalibration(db)
  data = CControl(; db)
  process_commercial_emissions!(data, commercial_emissions_data)

  WriteDisk(db, "$(data.Input)/POCX", data.POCX)
  WriteDisk(db, "$(data.Input)/CgPOCX", data.CgPOCX)
end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB")

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap")
  CgPOCX::VariableArray{5} = ReadDisk(db, "$Input/CgPOCX")
  POCX::VariableArray{6} = ReadDisk(db, "$Input/POCX")
end

# Creating a more specific record type for industrial EC due to special cases
struct IndustrialEmissionsRecord
  year::String
  fuel::String
  area::String
  ec::String
  co2::Float32
  n2o::Float32
  ch4::Float32
  ec_exception::Vector{String}  # For special EC handling
end

const industrial_emissions_data = [
  #                         Year     Fuel                Area   EC                   CO2          N2O      CH4    Exception
  IndustrialEmissionsRecord("All",  "Biomass",          "All",  "All",                   0.000,   1.270,   3.214, [""]),
  IndustrialEmissionsRecord("All",  "Biomass",          "All",  "PulpPaperMills",        0.000,   2.344,   3.146, [""]),
  IndustrialEmissionsRecord("All",  "Coal",             "All",  "All",               83579.461,   0.742,   1.113, [""]),
  IndustrialEmissionsRecord("All",  "Coke",             "All",  "All",               86021.505,   1.214,   1.283, [""]),
  IndustrialEmissionsRecord("All",  "CokeOvenGas",      "All",  "All",               45919.540,   1.045,   1.567, [""]),
  IndustrialEmissionsRecord("All",  "CrudeOil",         "All",  "All",                   0.000,   0.000,   0.000, [""]),
  IndustrialEmissionsRecord("All",  "Diesel",           "All",  "All",               69530.026,  28.721,   3.916, [""]),
  IndustrialEmissionsRecord("All",  "HFO",              "All",  "All",               73505.882,   1.506,   2.824, [""]),
  IndustrialEmissionsRecord("All",  "Kerosene",         "All",  "All",               67250.531,   0.823,   0.159, [""]),
  IndustrialEmissionsRecord("All",  "Biogas",           "All",  "All",               80719.000,   0.000,   0.000, [""]),
  IndustrialEmissionsRecord("All",  "LFO",              "All",  "All",               70231.959,   0.799,   0.155, [""]),
  IndustrialEmissionsRecord("All",  "LPG",              "All",  "All",               59660.213,   4.267,   0.948, [""]),
  IndustrialEmissionsRecord("All",  "NaturalGas",       "All",  "All",               49424.987,   0.915,   0.967, [""]),
  IndustrialEmissionsRecord("All",  "NaturalGasRaw",    "All",  "All",               62205.959,   1.568, 169.890, [""]),
  IndustrialEmissionsRecord("All",  "PetroCoke",        "All",  "All",               82939.394,   0.428,   2.630, [""]),
  IndustrialEmissionsRecord("All",  "StillGas",         "All",  "All",               46754.099,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("All",  "Asphaltines",      "All",  "All",               82939.394,   0.428,   2.630, [""]),
  IndustrialEmissionsRecord("All",  "Gasoline",         "All",  "All",               65400.000,   1.429,  77.143, [""]),
  IndustrialEmissionsRecord("All",  "AviationGasoline", "All",  "All",               69868.735,   6.862,  65.632, [""]),
  IndustrialEmissionsRecord("All",  "JetFuel",          "All",  "All",               67754.011,   1.898,   0.749, [""]),
  IndustrialEmissionsRecord("All",  "Biodiesel",        "All",  "All",                3681.608,  28.721,   3.916, [""]),
  IndustrialEmissionsRecord("All",  "Ethanol",          "All",  "All",                   0.000,   1.429,  77.143, [""]),
  IndustrialEmissionsRecord("All",  "Coke",             "All",  "All",               86021.51 ,   1.214,   1.283, ["IronSteel"]),
  IndustrialEmissionsRecord("All",  "Coke",             "All",  "IronSteel",             0.00 ,   1.214,   1.283, [""]),
  IndustrialEmissionsRecord("All",  "HFO",              "All",  "All",               73505.882,   1.506,   2.824, ["Petroleum"]),
  IndustrialEmissionsRecord("All",  "HFO",              "All",  "Petroleum",         74305.882,   1.506,   2.824, [""]),
  IndustrialEmissionsRecord("All",  "PetroCoke",        "All",  "OilSandsUpgraders", 87744.172,   0.537,   2.990, [""]),
  IndustrialEmissionsRecord("All",  "StillGas",         "All",  "OilSandsUpgraders", 50803.651,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("All",  "Diesel",           "All",  "All",               69530.026,  28.721,   3.916, ["Petroleum"]),
  IndustrialEmissionsRecord("All",  "Diesel",           "All",  "Petroleum",         69530.026,  10.444,   3.473, [""]),
  IndustrialEmissionsRecord("All",  "Diesel",           "All",  "All",               69530.026,  28.721,   3.916, ["OilSandsMining"]),
  IndustrialEmissionsRecord("All",  "Diesel",           "All",  "OilSandsMining",    69530.026,  10.444,   3.473, [""]),
    
  IndustrialEmissionsRecord("1990", "PetroCoke",        "All",  "OilSandsUpgraders", 89707.366,   0.507,   3.027, [""]),
  IndustrialEmissionsRecord("1991", "PetroCoke",        "All",  "OilSandsUpgraders", 89707.366,   0.512,   3.027, [""]),
  IndustrialEmissionsRecord("1992", "PetroCoke",        "All",  "OilSandsUpgraders", 89707.366,   0.520,   3.027, [""]),
  IndustrialEmissionsRecord("1993", "PetroCoke",        "All",  "OilSandsUpgraders", 89707.366,   0.525,   3.027, [""]),
  IndustrialEmissionsRecord("1994", "PetroCoke",        "All",  "OilSandsUpgraders", 89656.912,   0.532,   3.027, [""]),
  IndustrialEmissionsRecord("1995", "PetroCoke",        "All",  "OilSandsUpgraders", 89581.231,   0.525,   3.027, [""]),
  IndustrialEmissionsRecord("1996", "PetroCoke",        "All",  "OilSandsUpgraders", 90438.951,   0.525,   3.027, [""]),
  IndustrialEmissionsRecord("1997", "PetroCoke",        "All",  "OilSandsUpgraders", 89253.280,   0.532,   3.027, [""]),
  IndustrialEmissionsRecord("1998", "PetroCoke",        "All",  "OilSandsUpgraders", 87218.789,   0.536,   2.967, [""]),
  IndustrialEmissionsRecord("1999", "PetroCoke",        "All",  "OilSandsUpgraders", 86699.629,   0.539,   2.967, [""]),
  IndustrialEmissionsRecord("2000", "PetroCoke",        "All",  "OilSandsUpgraders", 86056.860,   0.551,   2.967, [""]),
  IndustrialEmissionsRecord("2001", "PetroCoke",        "All",  "OilSandsUpgraders", 86378.245,   0.549,   2.967, [""]),
  IndustrialEmissionsRecord("2002", "PetroCoke",        "All",  "OilSandsUpgraders", 86378.245,   0.549,   2.967, [""]),
  IndustrialEmissionsRecord("2003", "PetroCoke",        "All",  "OilSandsUpgraders", 86378.245,   0.549,   2.967, [""]),
  IndustrialEmissionsRecord("2004", "PetroCoke",        "All",  "OilSandsUpgraders", 86378.245,   0.549,   2.967, [""]),
  IndustrialEmissionsRecord("2005", "PetroCoke",        "All",  "OilSandsUpgraders", 86378.245,   0.549,   2.967, [""]),
  IndustrialEmissionsRecord("2006", "PetroCoke",        "All",  "OilSandsUpgraders", 86378.245,   0.549,   2.967, [""]),
  IndustrialEmissionsRecord("2007", "PetroCoke",        "All",  "OilSandsUpgraders", 86378.245,   0.549,   2.967, [""]),
  IndustrialEmissionsRecord("2008", "PetroCoke",        "All",  "OilSandsUpgraders", 86250.309,   0.548,   2.962, [""]),
  IndustrialEmissionsRecord("2009", "PetroCoke",        "All",  "OilSandsUpgraders", 86250.309,   0.548,   2.962, [""]),

  IndustrialEmissionsRecord("1990",  "PetroCoke",       "All",  "All",               84667.266,   0.416,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1991",  "PetroCoke",       "All",  "All",               84667.266,   0.420,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1992",  "PetroCoke",       "All",  "All",               84667.266,   0.427,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1993",  "PetroCoke",       "All",  "All",               84667.266,   0.432,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1994",  "PetroCoke",       "All",  "All",               85319.245,   0.436,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1995",  "PetroCoke",       "All",  "All",               85139.388,   0.432,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1996",  "PetroCoke",       "All",  "All",               84127.698,   0.432,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1997",  "PetroCoke",       "All",  "All",               84442.446,   0.436,   2.698, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1998",  "PetroCoke",       "All",  "All",               80964.686,   0.420,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("1999",  "PetroCoke",       "All",  "All",               81330.749,   0.422,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2000",  "PetroCoke",       "All",  "All",               79909.561,   0.431,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2001",  "PetroCoke",       "All",  "All",               81029.285,   0.429,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2002",  "PetroCoke",       "All",  "All",               82084.410,   0.429,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2003",  "PetroCoke",       "All",  "All",               82558.140,   0.429,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2004",  "PetroCoke",       "All",  "All",               81955.211,   0.429,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2005",  "PetroCoke",       "All",  "All",               82127.476,   0.429,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2006",  "PetroCoke",       "All",  "All",               82192.076,   0.429,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2007",  "PetroCoke",       "All",  "All",               82256.675,   0.429,   2.584, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2008",  "PetroCoke",       "All",  "All",               82351.672,   0.429,   2.589, ["OilSandsUpgraders"]),
  IndustrialEmissionsRecord("2009",  "PetroCoke",       "All",  "All",               82330.097,   0.429,   2.589, ["OilSandsUpgraders"]),

  IndustrialEmissionsRecord("1990", "StillGas",         "All",  "OilSandsUpgraders", 53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1991", "StillGas",         "All",  "OilSandsUpgraders", 53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1992", "StillGas",         "All",  "OilSandsUpgraders", 53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1993", "StillGas",         "All",  "OilSandsUpgraders", 53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1994", "StillGas",         "All",  "OilSandsUpgraders", 52863.436,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1995", "StillGas",         "All",  "OilSandsUpgraders", 48458.150,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1996", "StillGas",         "All",  "OilSandsUpgraders", 51240.436,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1997", "StillGas",         "All",  "OilSandsUpgraders", 53790.865,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1998", "StillGas",         "All",  "OilSandsUpgraders", 52237.111,   0.000,   0.000, [""]),
  IndustrialEmissionsRecord("1999", "StillGas",         "All",  "OilSandsUpgraders", 48797.410,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2000", "StillGas",         "All",  "OilSandsUpgraders", 49028.677,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2001", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2002", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2003", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2004", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2005", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2006", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2007", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2008", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2009", "StillGas",         "All",  "OilSandsUpgraders", 49491.212,   0.001,   0.000, [""]),
  
  IndustrialEmissionsRecord("1990", "StillGas",         "All",  "OilSandsMining",    53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1991", "StillGas",         "All",  "OilSandsMining",    53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1992", "StillGas",         "All",  "OilSandsMining",    53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1993", "StillGas",         "All",  "OilSandsMining",    53559.008,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1994", "StillGas",         "All",  "OilSandsMining",    52863.436,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1995", "StillGas",         "All",  "OilSandsMining",    48458.150,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1996", "StillGas",         "All",  "OilSandsMining",    51240.436,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1997", "StillGas",         "All",  "OilSandsMining",    53790.865,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("1998", "StillGas",         "All",  "OilSandsMining",    52237.111,   0.000,   0.000, [""]),
  IndustrialEmissionsRecord("1999", "StillGas",         "All",  "OilSandsMining",    48797.410,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2000", "StillGas",         "All",  "OilSandsMining",    49028.677,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2001", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2002", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2003", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2004", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2005", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2006", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2007", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2008", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  IndustrialEmissionsRecord("2009", "StillGas",         "All",  "OilSandsMining",    49491.212,   0.001,   0.000, [""]),
  
  IndustrialEmissionsRecord("1990", "StillGas",         "All",  "All",               45010.730,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1991", "StillGas",         "All",  "All",               45010.730,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1992", "StillGas",         "All",  "All",               45010.730,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1993", "StillGas",         "All",  "All",               45010.730,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1994", "StillGas",         "All",  "All",               44688.841,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1995", "StillGas",         "All",  "All",               46888.412,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1996", "StillGas",         "All",  "All",               48310.086,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1997", "StillGas",         "All",  "All",               47719.957,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1998", "StillGas",         "All",  "All",               49762.611,   0.000,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("1999", "StillGas",         "All",  "All",               49861.419,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2000", "StillGas",         "All",  "All",               46646.341,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2001", "StillGas",         "All",  "All",               45787.140,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2002", "StillGas",         "All",  "All",               46202.882,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2003", "StillGas",         "All",  "All",               47117.517,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2004", "StillGas",         "All",  "All",               47311.530,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2005", "StillGas",         "All",  "All",               47644.124,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2006", "StillGas",         "All",  "All",               48586.475,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2007", "StillGas",         "All",  "All",               48780.488,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2008", "StillGas",         "All",  "All",               47256.098,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"]),
  IndustrialEmissionsRecord("2009", "StillGas",         "All",  "All",               47754.989,   0.001,   0.000, ["OilSandsUpgraders", "OilSandsMining"])
  # IndustrialEmissionsRecord("Diesel",               All                   Oil Sands Mining                    69530.026       10.444        3.473
]

function process_industrial_emissions!(data::IControl, records::Vector{IndustrialEmissionsRecord})
  us = Select(data.Nation, "US")
  areas = findall(a -> data.ANMap[a, us] == 1, data.Areas)

  co2 = Select(data.Poll, "CO2")
  n2o = Select(data.Poll, "N2O")
  ch4 = Select(data.Poll, "CH4")

  for record in records
    years = record.year == "All" ? data.Years : findall(y -> data.Year[y] == record.year, data.Years)
    fuelep = Select(data.FuelEP, record.fuel)

    if record.ec == "All"
      ecs = data.ECs
    else 
      ecs = Select(data.EC,record.ec)
    end

    # EC exception handling
    if record.ec_exception != [""]
      ecs = Select(data.EC, setdiff(data.EC[ecs], record.ec_exception))
    end

    for year in years, area in areas, ec in ecs
      for enduse in data.Enduses
        data.POCX[enduse, fuelep, ec, co2, area, year] = record.co2 * 1.054615
        data.POCX[enduse, fuelep, ec, n2o, area, year] = record.n2o * 1.054615
        data.POCX[enduse, fuelep, ec, ch4, area, year] = record.ch4 * 1.054615
      end

      data.CgPOCX[fuelep, ec, co2, area, year] = record.co2 * 1.054615
      data.CgPOCX[fuelep, ec, n2o, area, year] = record.n2o * 1.054615
      data.CgPOCX[fuelep, ec, ch4, area, year] = record.ch4 * 1.054615
    end
  end
end

function ICalibration(db)
  data = IControl(; db)
  process_industrial_emissions!(data, industrial_emissions_data)

  WriteDisk(db, "$(data.Input)/POCX", data.POCX)
  WriteDisk(db, "$(data.Input)/CgPOCX", data.CgPOCX)
end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB")

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap")
  POCX::VariableArray{7} = ReadDisk(db, "$Input/POCX")  # Note the 7 dimensions for transportation
end

struct TransportEmissionsRecord
  year::String
  ec::String
  fuel::String
  tech::String
  area::String
  co2::Float32
  n2o::Float32
  ch4::Float32
end

const transportation_emissions_data = [
  #                         Years  EC                    FuelEP              Tech              Area   CO2            N2O      CH4             Tran Tech
  TransportEmissionsRecord("All", "Passenger",          "NaturalGas",       "LDVNaturalGas",  "All",  49398.850,     1.568,   235.233),     # NATURAL GAS
  TransportEmissionsRecord("All", "Passenger",          "All",              "LDVElectric",    "All",      0.000,     0.000,     0.000),     # PRIMARY ELECTRICITY, HYDRO AND NUCLEAR
  TransportEmissionsRecord("All", "Passenger",          "LPG",              "LDVPropane",     "All",  59660.213,     1.106,    25.286),     # GAS PLANT NATURAL GAS LIQUIDS (NGL'S)
  TransportEmissionsRecord("All", "Passenger",          "Diesel",           "LDVDiesel",      "All",  69530.026,     5.654,     1.380),     # DIESEL FUEL OIL
  TransportEmissionsRecord("All", "Passenger",          "Gasoline",         "LDVGasoline",    "All",  65400.000,     7.272,     6.011),     # MOTOR GASOLINE
  TransportEmissionsRecord("All", "Passenger",          "Ethanol",          "LDVGasoline",    "All",      0.000,    10.952,     8.574),     # ETHANOL
  TransportEmissionsRecord("All", "Passenger",          "Biodiesel",        "LDVDiesel",      "All",   3681.608,     6.513,     1.585),     # BIODIESEL
  TransportEmissionsRecord("All", "Passenger",          "NaturalGas",       "LDTNaturalGas",  "All",  49398.850,     1.568,   235.233),     # NATURAL GAS
  TransportEmissionsRecord("All", "Passenger",          "All",              "LDTElectric",    "All",      0.000,     0.000,     0.000),     # PRIMARY ELECTRICITY, HYDRO AND NUCLEAR
  TransportEmissionsRecord("All", "Passenger",          "LPG",              "LDTPropane",     "All",  59660.213,     1.106,    25.286),     # GAS PLANT NATURAL GAS LIQUIDS (NGL'S)
  TransportEmissionsRecord("All", "Passenger",          "Diesel",           "LDTDiesel",      "All",  69530.026,     5.646,     1.775),     # DIESEL FUEL OIL
  TransportEmissionsRecord("All", "Passenger",          "Gasoline",         "LDTGasoline",    "All",  65400.000,     7.498,     6.044),     # MOTOR GASOLINE
  TransportEmissionsRecord("All", "Passenger",          "Ethanol",          "LDTGasoline",    "All",      0.000,    11.108,     8.500),     # ETHANOL
  TransportEmissionsRecord("All", "Passenger",          "Biodiesel",        "LDTDiesel",      "All",   3681.608,     6.503,     2.044),     # BIODIESEL
  TransportEmissionsRecord("All", "Passenger",          "Gasoline",         "Motorcycle",     "All",  65400.000,     1.189,    25.774),     # MOTOR GASOLINE
  TransportEmissionsRecord("All", "Passenger",          "Ethanol",          "Motorcycle",     "All",      0.000,     1.798,    42.990),     # ETHANOL
  TransportEmissionsRecord("All", "Passenger",          "NaturalGas",       "BusNaturalGas",  "All",  49398.850,     1.568,   235.233),     # NATURAL GAS
  TransportEmissionsRecord("All", "Passenger",          "All",              "BusElectric",    "All",      0.000,     0.000,     0.000),     # PRIMARY ELECTRICITY, HYDRO AND NUCLEAR
  TransportEmissionsRecord("All", "Passenger",          "LPG",              "BusPropane",     "All",  59660.213,     1.106,    25.286),     # GAS PLANT NATURAL GAS LIQUIDS (NGL'S)
  TransportEmissionsRecord("All", "Passenger",          "Diesel",           "BusDiesel",      "All",  69530.026,     3.570,     3.013),     # DIESEL FUEL OIL
  TransportEmissionsRecord("All", "Passenger",          "Gasoline",         "BusGasoline",    "All",  65400.000,     5.261,     2.518),     # MOTOR GASOLINE
  TransportEmissionsRecord("All", "Passenger",          "Ethanol",          "BusGasoline",    "All",      0.000,     8.003,     3.572),     # ETHANOL
  TransportEmissionsRecord("All", "Passenger",          "Biodiesel",        "BusDiesel",      "All",   3681.608,     4.093,     3.475),     # BIODIESEL
  TransportEmissionsRecord("All", "Passenger",          "Diesel",           "TrainDiesel",    "All",  69530.026,    28.721,     3.916),     # DIESEL FUEL OIL
  TransportEmissionsRecord("All", "Passenger",          "Biodiesel",        "TrainDiesel",    "All",   3681.608,    28.721,     3.916),     # BIODIESEL
  TransportEmissionsRecord("All", "Freight",            "Diesel",           "HDV2B3Diesel",   "All",  69530.026,     3.833,     2.913),     # DIESEL FUEL OIL 
  TransportEmissionsRecord("All", "Freight",            "Gasoline",         "HDV2B3Gasoline", "All",  65400.000,     5.249,     2.535),     # MOTOR GASOLINE  
  TransportEmissionsRecord("All", "Freight",            "Ethanol",          "HDV2B3Gasoline", "All",      0.000,     8.000,     3.575),     # ETHANOL         
  TransportEmissionsRecord("All", "Freight",            "Biodiesel",        "HDV2B3Diesel",   "All",   3681.608,     4.396,     3.361),     # BIODIESEL       
  TransportEmissionsRecord("All", "Freight",            "Diesel",           "HDV45Diesel",    "All",  69530.026,     3.803,     2.925),     # DIESEL FUEL OIL 
  TransportEmissionsRecord("All", "Freight",            "Gasoline",         "HDV45Gasoline",  "All",  65400.000,     5.155,     2.672),     # MOTOR GASOLINE  
  TransportEmissionsRecord("All", "Freight",            "Ethanol",          "HDV45Gasoline",  "All",      0.000,     7.421,     4.416),     # ETHANOL         
  TransportEmissionsRecord("All", "Freight",            "Biodiesel",        "HDV45Diesel",    "All",   3681.608,     4.410,     3.356),     # BIODIESEL       
  TransportEmissionsRecord("All", "Freight",            "Diesel",           "HDV67Diesel",    "All",  69530.026,     3.686,     2.969),     # DIESEL FUEL OIL 
  TransportEmissionsRecord("All", "Freight",            "Gasoline",         "HDV67Gasoline",  "All",  65400.000,     3.517,     5.050),     # MOTOR GASOLINE  
  TransportEmissionsRecord("All", "Freight",            "Ethanol",          "HDV67Gasoline",  "All",      0.000,     4.818,     8.195),     # ETHANOL         
  TransportEmissionsRecord("All", "Freight",            "Biodiesel",        "HDV67Diesel",    "All",   3681.608,     4.147,     3.455),     # BIODIESEL       
  TransportEmissionsRecord("All", "Freight",            "Diesel",           "HDV8Diesel",     "All",  69530.026,     3.802,     2.925),     # DIESEL FUEL OIL 
  TransportEmissionsRecord("All", "Freight",            "Gasoline",         "HDV8Gasoline",   "All",  65400.000,     5.179,     2.637),     # MOTOR GASOLINE  
  TransportEmissionsRecord("All", "Freight",            "Ethanol",          "HDV8Gasoline",   "All",      0.000,     7.687,     4.030),     # ETHANOL         
  TransportEmissionsRecord("All", "Freight",            "Biodiesel",        "HDV8Diesel",     "All",   3681.608,     4.392,     3.363),     # BIODIESEL       
  TransportEmissionsRecord("All", "Freight",            "Diesel",           "TrainDiesel",    "All",  69530.026,    28.721,     3.916),     # DIESEL FUEL OIL 
  TransportEmissionsRecord("All", "Freight",            "Biodiesel",        "TrainDiesel",    "All",   3681.608,    28.721,     3.916),     # BIODIESEL       
  TransportEmissionsRecord("All", "Freight",            "HFO",              "MarineHeavy",    "All",  73505.882,     1.859,     6.588),     # HEAVY FUEL OIL  
  TransportEmissionsRecord("All", "Freight",            "Diesel",           "MarineLight",    "All",  69530.026,    28.721,     3.916),     # DIESEL FUEL OIL 
  TransportEmissionsRecord("All", "Freight",            "Biodiesel",        "MarineLight",    "All",   3681.608,    28.721,     3.916),      # BIODIESEL       
  TransportEmissionsRecord("All", "AirPassenger",       "AviationGasoline", "PlaneGasoline",  "All",  69868.735,     6.862,    65.632),     # AVIATION GASOLINE
  TransportEmissionsRecord("All", "AirPassenger",       "JetFuel",          "PlaneJetFuel",   "All",  67754.011,     1.898,     0.749),     # JET FUEL         
  TransportEmissionsRecord("All", "AirFreight",         "AviationGasoline", "PlaneGasoline",  "All",  69868.735,     6.862,    65.632),     # AVIATION GASOLINE
  TransportEmissionsRecord("All", "AirFreight",         "JetFuel",          "PlaneJetFuel",   "All",  67754.011,     1.898,     0.749),     # JET FUEL         
  TransportEmissionsRecord("All", "ForeignPassenger",   "AviationGasoline", "PlaneGasoline",  "All",  69868.735,     6.862,    65.632),     # AVIATION GASOLINE
  TransportEmissionsRecord("All", "ForeignPassenger",   "JetFuel",          "PlaneJetFuel",   "All",  67754.011,     1.898,     0.749),     # JET FUEL         
  TransportEmissionsRecord("All", "ForeignFreight",     "AviationGasoline", "PlaneGasoline",  "All",  69868.735,     6.862,    65.632),     # AVIATION GASOLINE
  TransportEmissionsRecord("All", "ForeignFreight",     "JetFuel",          "PlaneJetFuel",   "All",  67754.011,     1.898,     0.749),     # JET FUEL         
  TransportEmissionsRecord("All", "ForeignFreight",     "HFO",              "MarineHeavy",    "All",  73505.882,     1.859,     6.588),     # HEAVY FUEL OIL   
  TransportEmissionsRecord("All", "ForeignFreight",     "Diesel",           "MarineLight",    "All",  69530.026,    28.721,     3.916),     # DIESEL FUEL OIL  
  TransportEmissionsRecord("All", "ForeignFreight",     "Biodiesel",        "MarineLight",    "All",   3681.608,    28.721,     3.916),     # BIODIESEL        
  TransportEmissionsRecord("All", "ResidentialOffRoad", "Diesel",           "OffRoad",        "All",  69530.026,    28.721,     3.916),     # DIESEL FUEL OIL  
  TransportEmissionsRecord("All", "ResidentialOffRoad", "Gasoline",         "OffRoad",        "All",  65400.000,     1.429,    77.143),     # MOTOR GASOLINE   
  TransportEmissionsRecord("All", "ResidentialOffRoad", "Ethanol",          "OffRoad",        "All",      0.000,     1.429,    77.143),     # ETHANOL          
  TransportEmissionsRecord("All", "ResidentialOffRoad", "Biodiesel",        "OffRoad",        "All",   3681.608,    28.721,     3.916),     # BIODIESEL        
  TransportEmissionsRecord("All", "CommercialOffRoad",  "Diesel",           "OffRoad",        "All",  69530.026,    28.721,     3.916),     # DIESEL FUEL OIL  
  TransportEmissionsRecord("All", "CommercialOffRoad",  "Gasoline",         "OffRoad",        "All",  65400.000,     1.429,    77.143),     # MOTOR GASOLINE   
  TransportEmissionsRecord("All", "CommercialOffRoad",  "Ethanol",          "OffRoad",        "All",      0.000,     1.429,    77.143),     # ETHANOL          
  TransportEmissionsRecord("All", "CommercialOffRoad",  "Biodiesel",        "OffRoad",        "All",   3681.608,    28.721,     3.916)      # BIODIESEL        
  # EOD       Commercial Off-Road   BIODIESEL                                     Biodiesel                                   Off-Road                          All          3681.608       28.721        3.916
]

function process_transport_emissions!(data::TControl, records::Vector{TransportEmissionsRecord})
  us = Select(data.Nation, "US")
  areas = findall(a -> data.ANMap[a, us] == 1, data.Areas)

  co2 = Select(data.Poll, "CO2")
  n2o = Select(data.Poll, "N2O")
  ch4 = Select(data.Poll, "CH4")

  for record in records
    years = record.year == "All" ? data.Years : findall(y -> data.Year[y] == record.year, data.Years)

    # Handle ec, fuel, and tech selections
    ecs = Select(data.EC, record.ec)
    fueleps = record.fuel == "All" ? data.FuelEPs : Select(data.FuelEP, record.fuel)
    techs = Select(data.Tech, record.tech)

    for year in years, area in areas, ec in ecs, fuelep in fueleps, tech in techs
      for enduse in data.Enduses

        # Set coefficients with conversion factor
        data.POCX[enduse, fuelep, tech, ec, co2, area, year] = record.co2 * 1.054615
        data.POCX[enduse, fuelep, tech, ec, n2o, area, year] = record.n2o * 1.054615
        data.POCX[enduse, fuelep, tech, ec, ch4, area, year] = record.ch4 * 1.054615

      end
    end
  end
end

function TCalibration(db)
  data = TControl(; db)
  process_transport_emissions!(data, transportation_emissions_data)
  WriteDisk(data.db, "$(data.Input)/POCX", data.POCX)
end

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db, "MainDB/BCNameDB")

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap")
  POCX::VariableArray{5} = ReadDisk(db, "EGInput/POCX")
end

const electric_emissions_data = [
  #                Year    FuelEP         Area   EC     CO2          N2O    CH4
  EmissionsRecord("All",  "Biomass",     "All", "All",      0.000,   1.270, 3.214),
  EmissionsRecord("All",  "Coal",        "All", "All",  88964.200,   1.573, 1.081),
  EmissionsRecord("All",  "Coke",        "All", "All",  86021.505,   1.214, 1.283),
  EmissionsRecord("All",  "CokeOvenGas", "All", "All",  30485.605,   0.694, 1.041),
  EmissionsRecord("All",  "CrudeOil",    "All", "All",  59660.213,   4.267, 0.948),
  EmissionsRecord("All",  "Diesel",      "All", "All",  69530.026,  10.444, 3.480),
  EmissionsRecord("All",  "HFO",         "All", "All",  73505.882,   1.506, 0.800),
  EmissionsRecord("All",  "Kerosene",    "All", "All",  67250.531,   0.823, 0.159),
  EmissionsRecord("All",  "Biogas",      "All", "All",      0.000,   0.100, 1.000),
  EmissionsRecord("All",  "LFO",         "All", "All",  70231.959,   0.799, 4.639),
  EmissionsRecord("All",  "LPG",         "All", "All",  59660.213,   4.267, 0.948),
  EmissionsRecord("All",  "NaturalGas",  "All", "All",  49424.987,   0.863, 0.967),
  EmissionsRecord("All",  "PetroCoke",   "All", "All",  82330.097,   0.429, 2.589),
  EmissionsRecord("All",  "StillGas",    "All", "All",  47018.000,   0.001, 0.000),
  EmissionsRecord("1990", "PetroCoke",   "All", "All",  84667.266,   0.416, 2.698),
  EmissionsRecord("1991", "PetroCoke",   "All", "All",  84667.266,   0.420, 2.698),
  EmissionsRecord("1992", "PetroCoke",   "All", "All",  84667.266,   0.427, 2.698),
  EmissionsRecord("1993", "PetroCoke",   "All", "All",  84667.266,   0.432, 2.698),
  EmissionsRecord("1994", "PetroCoke",   "All", "All",  85319.245,   0.436, 2.698),
  EmissionsRecord("1995", "PetroCoke",   "All", "All",  85139.388,   0.432, 2.698),
  EmissionsRecord("1996", "PetroCoke",   "All", "All",  84127.698,   0.432, 2.698),
  EmissionsRecord("1997", "PetroCoke",   "All", "All",  84442.446,   0.436, 2.698),
  EmissionsRecord("1998", "PetroCoke",   "All", "All",  80964.686,   0.420, 2.584),
  EmissionsRecord("1999", "PetroCoke",   "All", "All",  81330.749,   0.422, 2.584),
  EmissionsRecord("2000", "PetroCoke",   "All", "All",  79909.561,   0.431, 2.584),
  EmissionsRecord("2001", "PetroCoke",   "All", "All",  81029.285,   0.429, 2.584),
  EmissionsRecord("2002", "PetroCoke",   "All", "All",  82084.410,   0.429, 2.584),
  EmissionsRecord("2003", "PetroCoke",   "All", "All",  82558.140,   0.429, 2.584),
  EmissionsRecord("2004", "PetroCoke",   "All", "All",  81955.211,   0.429, 2.584),
  EmissionsRecord("2005", "PetroCoke",   "All", "All",  82127.476,   0.429, 2.584),
  EmissionsRecord("2006", "PetroCoke",   "All", "All",  82192.076,   0.429, 2.584),
  EmissionsRecord("2007", "PetroCoke",   "All", "All",  82256.675,   0.429, 2.584),
  EmissionsRecord("2008", "PetroCoke",   "All", "All",  82351.672,   0.429, 2.589),
  EmissionsRecord("2009", "PetroCoke",   "All", "All",  82330.097,   0.429, 2.589)
  # EOD       Still Gas            All                   All                                47018.000        0.001        0.000
]

function process_electric_emissions!(data::EControl, records::Vector{EmissionsRecord})
  us = Select(data.Nation, "US")
  areas = findall(a -> data.ANMap[a, us] == 1, data.Areas)

  co2 = Select(data.Poll, "CO2")
  n2o = Select(data.Poll, "N2O")
  ch4 = Select(data.Poll, "CH4")

  for record in records
    years = record.year == "All" ? data.Years : findall(y -> data.Year[y] == record.year, data.Years)
    fuelep = Select(data.FuelEP, record.fuel)

    for year in years, area in areas, plant in data.Plants
      data.POCX[fuelep, plant, co2, area, year] = record.co2 * 1.054615
      data.POCX[fuelep, plant, n2o, area, year] = record.n2o * 1.054615
      data.POCX[fuelep, plant, ch4, area, year] = record.ch4 * 1.054615
    end
  end
end

function ECalibration(db)
  data = EControl(; db)
  process_electric_emissions!(data, electric_emissions_data)
  WriteDisk(db, "EGInput/POCX", data.POCX)
end

# Update the main CalibrationControl function to include all sectors
function CalibrationControl(db)
  @info "GHG_Energy-US.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)
  ECalibration(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end # module GHG_Energy_US
