#
# ElectricPricesMove.jl - This file moves the electricity prices
# from xFPF into xPE, xPEDmd, and xPEClass.
#
using EnergyModel

module ElectricPricesMove

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  ClassDS::SetArray = ReadDisk(db,"MainDB/ClassDS")
  Classs::Vector{Int} = collect(Select(Class))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  xPE::VariableArray{3} = ReadDisk(db,"EInput/xPE") # [ECC,Area,Year] Historical Retail Electricity Price ($/MWh)
  xPEClass::VariableArray{3} = ReadDisk(db,"EInput/xPEClass") # [Class,Area,Year] Exogenous Retail Electricity Price (1985 $/MWH)
  xPEDmd::VariableArray{3} = ReadDisk(db, "SInput/xPE") # [ECC, Area,Year]  Historical Price of Electricity ($/MWh)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Input) = data
  (;Class,ECC,ES,Fuel,Areas,Years) = data
  (;EEConv,SecMap,xFPF,xPE,xPEClass,xPEDmd) = data
  
  #
  # Move fuel prices (xFPF) into electric prices (xPEDmd)
  #
  fuel = Select(Fuel,"Electric")
  es = Select(ES,"Residential")
  eccs = findall(x -> x == 1.0, SecMap)
  for year in Years, area in Areas, ecc in eccs
    xPEDmd[ecc,area,year] = xFPF[fuel,es,area,year] * EEConv / 1000
  end

  es = Select(ES,"Commercial")
  eccs = findall(x -> x == 2.0, SecMap)
  for year in Years, area in Areas, ecc in eccs
    xPEDmd[ecc,area,year] = xFPF[fuel,es,area,year] * EEConv / 1000
  end
  
  es = Select(ES,"Industrial")
  eccs = findall(x -> x == 3.0, SecMap)
  for year in Years, area in Areas, ecc in eccs
    xPEDmd[ecc,area,year] = xFPF[fuel,es,area,year] * EEConv / 1000
  end

  es = Select(ES,"Commercial")
  eccs = findall(x -> x == 4.0, SecMap)
  for year in Years, area in Areas, ecc in eccs
    xPEDmd[ecc,area,year] = xFPF[fuel,es,area,year] * EEConv / 1000
  end
  
  es = Select(ES,"Industrial")
  ecc = Select(ECC,"H2Production")
  for year in Years, area in Areas
    xPEDmd[ecc,area,year] = xFPF[fuel,es,area,year] * EEConv / 1000
  end
  
  #
  # Set Retail Company prices (xPE) equal to Area prices (xPEDmd)
  #
  @. xPE = xPEDmd

  #
  # Move sector prices (xPE) into class prices (xPEClass)
  #
  class = Select(Class,"Res")
  eccs = findall(x -> x == 1.0, SecMap)
  # Note - Promula version is using the first selected ECC from SecMap
  ecc = first(eccs)
  for year in Years, area in Areas
    xPEClass[class,area,year] = xPE[ecc,area,year] 
  end  
  
  class = Select(Class,"Com")
  eccs = findall(x -> x == 2.0, SecMap)
  ecc = first(eccs)
  for year in Years, area in Areas
    xPEClass[class,area,year] = xPE[ecc,area,year]
  end
  
  class = Select(Class,"Ind")
  eccs = findall(x -> x == 3.0, SecMap)
  ecc = first(eccs)
  for year in Years, area in Areas
    xPEClass[class,area,year] = xPE[ecc,area,year]
  end
  
  class = Select(Class,"Transport")
  eccs = findall(x -> x == 4.0, SecMap)
  ecc = first(eccs)
  for year in Years, area in Areas
    xPEClass[class,area,year] = xPE[ecc,area,year]
  end
  
  WriteDisk(db,"$Input/xPE",xPE)
  WriteDisk(db,"$Input/xPEClass",xPEClass)
  WriteDisk(db,"SInput/xPE",xPEDmd)

end

function CalibrationControl(db)
  @info "ElectricPricesMove.jl - CalibrationControl"

  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
