#
# OG_UnitProduction.jl - Oil and Gas Production Data
#
using EnergyModel

module OG_UnitProduction

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

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  FuelOG::SetArray = ReadDisk(db, "MainDB/FuelOGKey")
  GNode::SetArray = ReadDisk(db, "MainDB/GNodeKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGUnit))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processes::Vector{Int} = collect(Select(Process))
  ProcOG::SetArray = ReadDisk(db, "MainDB/ProcOGKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  OGArea::Array{String} = ReadDisk(db,"SpInput/OGArea") # [OGUnit] Area
  OGECC::Array{String} = ReadDisk(db,"SpInput/OGECC") # [OGUnit] Economic Sector
  OGFuel::Array{String} = ReadDisk(db,"SpInput/OGFuel") # [OGUnit] Fuel Type
  OGNation::Array{String} = ReadDisk(db,"SpInput/OGNation") # [OGUnit] Nation
  OGNode::Array{String} = ReadDisk(db,"SpInput/OGNode") # [OGUnit] Natural Gas Transmission Node
  OGOGSw::Array{String} = ReadDisk(db,"SpInput/OGOGSw") # [OGUnit] Oil or Gas Switch
  OGProcess::Array{String} = ReadDisk(db,"SpInput/OGProcess") # [OGUnit] Production Process
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation (Map)
  GPRAMap::VariableArray{4} = ReadDisk(db,"SpInput/GPRAMap") # [Area,Process,Nation,Year] Area Gas Production Fraction (Btu/Btu)
  OPrAMap::VariableArray{4} = ReadDisk(db,"SpInput/OPrAMap") # [Area,Process,Nation,Year] Area Oil Production Fraction (Btu/Btu)
  xPd::VariableArray{2} = ReadDisk(db,"SpInput/xPd") # [OGUnit,Year] Exogenous Production (TBtu/Yr)
  xGAProd::VariableArray{3} = ReadDisk(db,"SInput/xGAProd") # [Process,Area,Year] Natural Gas Production (TBtu/Yr)
  xGProd::VariableArray{3} = ReadDisk(db,"SInput/xGProd") # [Process,Nation,Year] Primary Gas Production (TBtu/Yr)
  xOAProd::VariableArray{3} = ReadDisk(db,"SInput/xOAProd") # [Process,Area,Year] Oil Production (TBtu/Yr)
  xOProd::VariableArray{3} = ReadDisk(db,"SInput/xOProd") # [Process,Nation,Year] Primary Oil Production (TBtu/Yr)

  # Scratch Variables
  AEOGProd::VariableArray{1} = zeros(Float32,length(Year)) # [Year] AEO Total Dry Gas Production (TBtu/Yr)
  GAdjust::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Natural Gas Adjustment (Btu/Btu)
  GR::VariableArray{2} = zeros(Float32,length(Process),length(Area)) # [Process,Area] Growth Rate after 2040 (1/Yr)
end

function OGSetSelect(data,ogunit)
  (;Area,ECC,FuelOG,ProcOG,GNode,Process) = data
  (;OGArea,OGECC,OGFuel,OGNode,OGProcess) = data

  area    = Select(Area,OGArea[ogunit])
  ecc     = Select(ECC,OGECC[ogunit])
  process = Select(Process,OGECC[ogunit])
  fuelog  = Select(FuelOG,OGFuel[ogunit])
  procog  = Select(ProcOG,OGProcess[ogunit])
  gnode   = Select(GNode,OGNode[ogunit])

  return area,ecc,process,fuelog,procog,gnode
end

function SCalibration(db)
  data = SControl(; db)
  (;Areas,Nation,Nations,OGUnits,Process,Processes,Years) = data
  (;OGCode,OGNation,OGOGSw,ANMap,GPRAMap,OPrAMap) = data
  (;xPd,xGAProd,xGProd,xOAProd,xOProd) = data

  # 
  # US Natural Gas Data
  # 

  # 
  # Production
  # 
  for process in Processes, nation in Nations, year in Years
    areas = findall(ANMap[Areas,nation] .== 1)
    xOProd[process,nation,year] = sum(xOAProd[process,a,year] for a in areas)
    xGProd[process,nation,year] = sum(xGAProd[process,a,year] for a in areas)
  end

  xPd .= 0

  #
  # OGUnits where data is read directly from EnvCa
  # 
  ogunits = Select(OGCode,["AB_LightOil_0001",
                           "AB_HeavyOil_0001",
                           "AB_OS_Primary_0001",
                           "AB_OS_SAGD_0001",
                           "AB_OS_CSS_0001",
                           "AB_OS_Mining_0001",
                           "AB_OS_Upgrader_0001",
                           "AB_ConvGas_0001",
                           "AB_UnconvGas_0001",
                           "BC_LightOil_0001",
                           "BC_ConvGas_0001",
                           "BC_UnconvGas_0001",
                           "MB_LightOil_0001",
                           "MB_HeavyOil_0001",
                           "NB_Gas_0001",
                           "NL_FrontierOil_0001",
                           "NL_Gas_0001",
                           "NL_HeavyOil_0001",
                           "NS_Gas_0001",
                           "NS_LightOil_0001",
                           "NT_FrontierOil_0001",
                           "NT_Gas_0001",
                           "ON_LightOil_0001",
                           "ON_Gas_0001",
                           "SK_LightOil_0001",
                           "SK_HeavyOil_0001",
                           "SK_OS_SAGD_0001",
                           "SK_OS_Upgrader_0001",
                           "SK_ConvGas_0001",
                           "SK_UnconvGas_0001",
                           "YT_Gas_0001",
                           "BC_LNG_0001",
                           "NS_LNG_0001",
                           "QC_LNG_0001"])

  for ogunit in ogunits
    area,ecc,process,fuelog,procog,gnode = OGSetSelect(data,ogunit)
    for year in Years
      if OGOGSw[ogunit] == "Oil"
        xPd[ogunit,year] = xOAProd[process,area,year]
      elseif OGOGSw[ogunit] == "Gas"
        xPd[ogunit,year] = xGAProd[process,area,year]
      end
    end
  end

  # 
  # US Oil and Gas Production
  # 
  US = Select(Nation,"US")
  for ogunit in findall(OGNation[OGUnits] .== "US")
    area,ecc,process,fuelog,procog,gnode = OGSetSelect(data,ogunit)
    for year in Years
      if OGOGSw[ogunit] == "Oil"
        xPd[ogunit,year] = xOAProd[process,area,year]
      elseif OGOGSw[ogunit] == "Gas"
        xPd[ogunit,year] = xGAProd[process,area,year]
      end
    end
  end

  # 
  # Mexico Oil and Gas Production
  # 
  # Mexico Oil
  # 
  process = Select(Process,"LightOilMining")
  ogunit = Select(OGCode,"MX_Oil_0001")
  MX = Select(Nation,"MX")
  for year in Years
    xPd[ogunit,year] = xOProd[process,MX,year]
  end

  # 
  # Mexico Natural Gas
  # 
  process = Select(Process,"ConventionalGasProduction")
  ogunit = Select(OGCode,"MX_NaturalGas_0001")
  for year in Years
    xPd[ogunit,year] = xGProd[process,MX,year]
  end

  for nation in Nations
    for area in findall(ANMap[Areas,nation] .== 1)
      for process in Processes, year in Years
        @finite_math GPRAMap[area,process,nation,year] = xGAProd[process,area,year]/xGProd[process,nation,year]
        @finite_math OPrAMap[area,process,nation,year] = xOAProd[process,area,year]/xOProd[process,nation,year]
      end
    end
  end

  WriteDisk(db,"SInput/xGAProd",xGAProd)
  WriteDisk(db,"SInput/xGProd",xGProd)
  WriteDisk(db,"SInput/xOAProd",xOAProd)
  WriteDisk(db,"SInput/xOProd",xOProd)
  WriteDisk(db,"SpInput/xPd",xPd)
  WriteDisk(db,"SpInput/GPRAMap",GPRAMap)
  WriteDisk(db,"SpInput/OPrAMap",OPrAMap)

end

function CalibrationControl(db)
  @info "OG_UnitProduction.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
