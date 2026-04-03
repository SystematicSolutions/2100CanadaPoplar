#
# EfficiencyPrograms_UOG.jl
#
using EnergyModel

module EfficiencyPrograms_UOG

import ...EnergyModel: ReadDisk, WriteDisk, Select
import ...EnergyModel: HisTime, ITime, MaxTime, First, Future, Final, Yr
import ...EnergyModel: @finite_math, finite_inverse, finite_divide, finite_power, finite_exp, finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  Input::String = "IInput"
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap")
  DEESw::VariableArray{5} = ReadDisk(db, "$Input/DEESw")
  DEEA0::VariableArray{5} = ReadDisk(db, "$Input/DEEA0")
  DEEB0::VariableArray{5} = ReadDisk(db, "$Input/DEEB0")
  DEEC0::VariableArray{5} = ReadDisk(db, "$Input/DEEC0")
  DCCA0::VariableArray{5} = ReadDisk(db, "$Input/DCCA0")
  DCCB0::VariableArray{5} = ReadDisk(db, "$Input/DCCB0")
  DCCC0::VariableArray{5} = ReadDisk(db, "$Input/DCCC0")
  DCDEM::VariableArray{5} = ReadDisk(db, "$Input/DCDEM")
  PEESw::VariableArray{5} = ReadDisk(db, "$Input/PEESw")
  PEEA0::VariableArray{5} = ReadDisk(db, "$Input/PEEA0")
  PEEB0::VariableArray{5} = ReadDisk(db, "$Input/PEEB0")
  PEEC0::VariableArray{5} = ReadDisk(db, "$Input/PEEC0")
  PCCA0::VariableArray{5} = ReadDisk(db, "$Input/PCCA0")
  PCCB0::VariableArray{5} = ReadDisk(db, "$Input/PCCB0")
  PCCC0::VariableArray{5} = ReadDisk(db, "$Input/PCCC0")
  PCPEM::VariableArray{5} = ReadDisk(db, "$Input/PCPEM")

  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))
  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  Techs::Vector{Int} = collect(Select(Tech))
end

function apply_efficiency_programs(db::String)
  data = EControl(; db)
  (; Input) = data
  
  # Start impact in 2013
  start_year = Yr(2013)
  years = findall(y -> y >= start_year, data.Years)
  
  # Apply adjustment to areas in Canada
  canada = Select(data.Nation, "CN")
  areas = findall(a -> data.ANMap[a, canada] == 1, data.Areas)
  
  # Standard Values from "Generic Energy Efficiency Program Curves.xlsm"
  for year in years, area in areas, ec in data.ECs, tech in data.Techs, enduse in data.Enduses
    data.DEEA0[enduse, tech, ec, area, year] = 88.999
    data.PEEA0[enduse, tech, ec, area, year] = 88.999
    data.DEEB0[enduse, tech, ec, area, year] = -5.016
    data.PEEB0[enduse, tech, ec, area, year] = -5.016
    data.DCDEM[enduse, tech, ec, area, year] = 1.000
    data.PCPEM[enduse, tech, ec, area, year] = 1.000
  end
  
  # Upstream Oil and Gas except for SAGD
  uog_ecs = Select(data.EC, ["LightOilMining", "HeavyOilMining", "FrontierOilMining",
                              "PrimaryOilSands", "ConventionalGasProduction", "UnconventionalGasProduction"])
  for year in years, area in areas, ec in uog_ecs, tech in data.Techs, enduse in data.Enduses
    data.DEEC0[enduse, tech, ec, area, year] = 0.160 / 2
    data.PEEC0[enduse, tech, ec, area, year] = 0.160 / 2
    data.DEESw[enduse, tech, ec, area, year] = 2
    data.PEESw[enduse, tech, ec, area, year] = 2
  end
  
  # SAGD and CSS
  sagd_css_ecs = Select(data.EC, ["SAGDOilSands", "CSSOilSands"])
  for year in years, area in areas, ec in sagd_css_ecs, tech in data.Techs, enduse in data.Enduses
    data.DEEA0[enduse, tech, ec, area, year] = 1.45824
    data.DEEB0[enduse, tech, ec, area, year] = -2.70731
    data.DEEC0[enduse, tech, ec, area, year] = 0.32160 / 2
    data.PEEA0[enduse, tech, ec, area, year] = data.DEEA0[enduse, tech, ec, area, year]
    data.PEEB0[enduse, tech, ec, area, year] = data.DEEB0[enduse, tech, ec, area, year]
    data.PEEC0[enduse, tech, ec, area, year] = data.DEEC0[enduse, tech, ec, area, year]
    data.DCCA0[enduse, tech, ec, area, year] = 1.88748
    data.DCCB0[enduse, tech, ec, area, year] = -2.96808
    data.DCCC0[enduse, tech, ec, area, year] = 0.11268
    data.PCCA0[enduse, tech, ec, area, year] = data.DCCA0[enduse, tech, ec, area, year]
    data.PCCB0[enduse, tech, ec, area, year] = data.DCCB0[enduse, tech, ec, area, year]
    data.PCCC0[enduse, tech, ec, area, year] = data.DCCC0[enduse, tech, ec, area, year]
    data.DCDEM[enduse, tech, ec, area, year] = 0.00000
    data.PCPEM[enduse, tech, ec, area, year] = 0.00000
    data.DEESw[enduse, tech, ec, area, year] = 2
    data.PEESw[enduse, tech, ec, area, year] = 2
  end
  
  # Oil Sands Mining
  oil_sands_mining = Select(data.EC, "OilSandsMining")
  for year in years, area in areas, ec in oil_sands_mining, tech in data.Techs, enduse in data.Enduses
    data.DEEA0[enduse, tech, ec, area, year] = 3.49349
    data.DEEB0[enduse, tech, ec, area, year] = -2.92581
    data.DEEC0[enduse, tech, ec, area, year] = 0.35948 / 2
    data.PEEA0[enduse, tech, ec, area, year] = data.DEEA0[enduse, tech, ec, area, year]
    data.PEEB0[enduse, tech, ec, area, year] = data.DEEB0[enduse, tech, ec, area, year]
    data.PEEC0[enduse, tech, ec, area, year] = data.DEEC0[enduse, tech, ec, area, year]
    data.DCCA0[enduse, tech, ec, area, year] = 5.20310
    data.DCCB0[enduse, tech, ec, area, year] = -3.09810
    data.DCCC0[enduse, tech, ec, area, year] = 0.08047
    data.PCCA0[enduse, tech, ec, area, year] = data.DCCA0[enduse, tech, ec, area, year]
    data.PCCB0[enduse, tech, ec, area, year] = data.DCCB0[enduse, tech, ec, area, year]
    data.PCCC0[enduse, tech, ec, area, year] = data.DCCC0[enduse, tech, ec, area, year]
    data.DCDEM[enduse, tech, ec, area, year] = 0.00000
    data.PCPEM[enduse, tech, ec, area, year] = 0.00000
    data.DEESw[enduse, tech, ec, area, year] = 2
    data.PEESw[enduse, tech, ec, area, year] = 2
  end
  
  # Oil Sands Upgraders
  oil_sands_upgraders = Select(data.EC, "OilSandsUpgraders")
  for year in years, area in areas, ec in oil_sands_upgraders, tech in data.Techs, enduse in data.Enduses
    data.DEEA0[enduse, tech, ec, area, year] = 3.25266
    data.DEEB0[enduse, tech, ec, area, year] = -2.71432
    data.DEEC0[enduse, tech, ec, area, year] = 0.17735 / 2
    data.PEEA0[enduse, tech, ec, area, year] = data.DEEA0[enduse, tech, ec, area, year]
    data.PEEB0[enduse, tech, ec, area, year] = data.DEEB0[enduse, tech, ec, area, year]
    data.PEEC0[enduse, tech, ec, area, year] = data.DEEC0[enduse, tech, ec, area, year]
    data.DCCA0[enduse, tech, ec, area, year] = 5.72307
    data.DCCB0[enduse, tech, ec, area, year] = -2.94998
    data.DCCC0[enduse, tech, ec, area, year] = 0.06989
    data.PCCA0[enduse, tech, ec, area, year] = data.DCCA0[enduse, tech, ec, area, year]
    data.PCCB0[enduse, tech, ec, area, year] = data.DCCB0[enduse, tech, ec, area, year]
    data.PCCC0[enduse, tech, ec, area, year] = data.DCCC0[enduse, tech, ec, area, year]
    data.DCDEM[enduse, tech, ec, area, year] = 0.00000
    data.PCPEM[enduse, tech, ec, area, year] = 0.00000
    data.DEESw[enduse, tech, ec, area, year] = 2
    data.PEESw[enduse, tech, ec, area, year] = 2
  end

  # Petroleum Refining
  petroleum = Select(data.EC, "Petroleum")
  for year in years, area in areas, ec in petroleum, tech in data.Techs, enduse in data.Enduses
    data.DEEA0[enduse, tech, ec, area, year] = 3.80953
    data.DEEB0[enduse, tech, ec, area, year] = -1.18422
    data.DEEC0[enduse, tech, ec, area, year] = 0.08703 / 2
    data.PEEA0[enduse, tech, ec, area, year] = data.DEEA0[enduse, tech, ec, area, year]
    data.PEEB0[enduse, tech, ec, area, year] = data.DEEB0[enduse, tech, ec, area, year]
    data.PEEC0[enduse, tech, ec, area, year] = data.DEEC0[enduse, tech, ec, area, year]
    data.DCCA0[enduse, tech, ec, area, year] = 30.04243
    data.DCCB0[enduse, tech, ec, area, year] = -1.60858
    data.DCCC0[enduse, tech, ec, area, year] = 0.25849
    data.PCCA0[enduse, tech, ec, area, year] = data.DCCA0[enduse, tech, ec, area, year]
    data.PCCB0[enduse, tech, ec, area, year] = data.DCCB0[enduse, tech, ec, area, year]
    data.PCCC0[enduse, tech, ec, area, year] = data.DCCC0[enduse, tech, ec, area, year]
    data.DCDEM[enduse, tech, ec, area, year] = 0.00000
    data.PCPEM[enduse, tech, ec, area, year] = 0.00000
    data.DEESw[enduse, tech, ec, area, year] = 2
    data.PEESw[enduse, tech, ec, area, year] = 2
  end

  # Sweet Natural Gas Processing
  sweet_gas_processing = Select(data.EC, "SweetGasProcessing")
  for year in years, area in areas, ec in sweet_gas_processing, tech in data.Techs, enduse in data.Enduses
    data.DEEA0[enduse, tech, ec, area, year] = 12.14619
    data.DEEB0[enduse, tech, ec, area, year] = -3.21261
    data.DEEC0[enduse, tech, ec, area, year] = 0.86143 / 2
    data.PEEA0[enduse, tech, ec, area, year] = data.DEEA0[enduse, tech, ec, area, year]
    data.PEEB0[enduse, tech, ec, area, year] = data.DEEB0[enduse, tech, ec, area, year]
    data.PEEC0[enduse, tech, ec, area, year] = data.DEEC0[enduse, tech, ec, area, year]
    data.DCCA0[enduse, tech, ec, area, year] = 20.42256
    data.DCCB0[enduse, tech, ec, area, year] = -3.42850
    data.DCCC0[enduse, tech, ec, area, year] = 0.20882
    data.PCCA0[enduse, tech, ec, area, year] = data.DCCA0[enduse, tech, ec, area, year]
    data.PCCB0[enduse, tech, ec, area, year] = data.DCCB0[enduse, tech, ec, area, year]
    data.PCCC0[enduse, tech, ec, area, year] = data.DCCC0[enduse, tech, ec, area, year]
    data.DCDEM[enduse, tech, ec, area, year] = 0.00000
    data.PCPEM[enduse, tech, ec, area, year] = 0.00000
    data.DEESw[enduse, tech, ec, area, year] = 2
    data.PEESw[enduse, tech, ec, area, year] = 2
  end

  # Sour Natural Gas Processing
  sour_gas_processing = Select(data.EC, "SourGasProcessing")
  for year in years, area in areas, ec in sour_gas_processing, tech in data.Techs, enduse in data.Enduses
    data.DEEA0[enduse, tech, ec, area, year] = 4.84356
    data.DEEB0[enduse, tech, ec, area, year] = -2.83407
    data.DEEC0[enduse, tech, ec, area, year] = 0.36180 / 2
    data.PEEA0[enduse, tech, ec, area, year] = data.DEEA0[enduse, tech, ec, area, year]
    data.PEEB0[enduse, tech, ec, area, year] = data.DEEB0[enduse, tech, ec, area, year]
    data.PEEC0[enduse, tech, ec, area, year] = data.DEEC0[enduse, tech, ec, area, year]
    data.DCCA0[enduse, tech, ec, area, year] = 7.72441
    data.DCCB0[enduse, tech, ec, area, year] = -3.02903
    data.DCCC0[enduse, tech, ec, area, year] = 0.08770
    data.PCCA0[enduse, tech, ec, area, year] = data.DCCA0[enduse, tech, ec, area, year]
    data.PCCB0[enduse, tech, ec, area, year] = data.DCCB0[enduse, tech, ec, area, year]
    data.PCCC0[enduse, tech, ec, area, year] = data.DCCC0[enduse, tech, ec, area, year]
    data.DCDEM[enduse, tech, ec, area, year] = 0.00000
    data.PCPEM[enduse, tech, ec, area, year] = 0.00000
    data.DEESw[enduse, tech, ec, area, year] = 2
    data.PEESw[enduse, tech, ec, area, year] = 2
  end

  # Write the updated data back to disk
  WriteDisk(db, "$Input/DCCA0", data.DCCA0)
  WriteDisk(db, "$Input/DCCB0", data.DCCB0)
  WriteDisk(db, "$Input/DCCC0", data.DCCC0)
  WriteDisk(db, "$Input/DCDEM", data.DCDEM)
  WriteDisk(db, "$Input/DEESw", data.DEESw)
  WriteDisk(db, "$Input/DEEA0", data.DEEA0)
  WriteDisk(db, "$Input/DEEB0", data.DEEB0)
  WriteDisk(db, "$Input/DEEC0", data.DEEC0)
  WriteDisk(db, "$Input/PCCA0", data.PCCA0)
  WriteDisk(db, "$Input/PCCB0", data.PCCB0)
  WriteDisk(db, "$Input/PCCC0", data.PCCC0)
  WriteDisk(db, "$Input/PCPEM", data.PCPEM)
  WriteDisk(db, "$Input/PEESw", data.PEESw)
  WriteDisk(db, "$Input/PEEA0", data.PEEA0)
  WriteDisk(db, "$Input/PEEB0", data.PEEB0)
  WriteDisk(db, "$Input/PEEC0", data.PEEC0)
end

function run_efficiency_programs(db::String)
  @info "EfficiencyPrograms_UOG.jl - run_efficiency_programs"
  apply_efficiency_programs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  run_efficiency_programs(DB)
end

end # module EfficiencyPrograms_UOG
