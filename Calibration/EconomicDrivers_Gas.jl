#
# EconomicDrivers_Gas.jl - Calculates Gas demands into future
#  and assigns it as xDriver for ECCs where DrSwitch=22
#
using EnergyModel

module EconomicDrivers_Gas

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  CalDB::String = "MCalDB"
  Input::String = "MInput"
  Outpt::String = "MOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DrSwitch::VariableArray{3} = ReadDisk(db,"MInput/DrSwitch") # [ECC,Area,Year] Economic Driver Switch
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
  TotDemand::VariableArray{4} = ReadDisk(db,"SOutput/TotDemand") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Economic Driver (Various Units)
  xTotDemand::VariableArray{4} = ReadDisk(db,"SInput/xTotDemand") # [Fuel,ECC,Area,Year] Total Energy Demands (TBtu/Yr)

  # Scratch Variables
  GasDemand::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Gas Demands (TBtu/Yr)
end

function GasDriver(db)
  data = MControl(; db)
  (;Areas,ECCs,Fuel) = data
  (;Years) = data
  (;DrSwitch,SecMap,TotDemand,xDriver,xTotDemand) = data
  (;GasDemand) = data

  #
  # Natural Gas Demands - DrSwitch=22
  # Hydrogen and RNG also flow through the ntural gas pipeline and distribution
  # system so their demands are also included in the Driver - Jeff Amlin 08/17/20
  #
  fuels = Select(Fuel,["Hydrogen","NaturalGas","RNG"])
  years = collect(Zero:Last)
  for year in years, area in Areas, ecc in ECCs, fuel in fuels
    TotDemand[fuel,ecc,area,year]=xTotDemand[fuel,ecc,area,year]
  end
  
  years = collect(Future:Final)
  for year in years, area in Areas, ecc in ECCs, fuel in fuels  
    TotDemand[fuel,ecc,area,year]=TotDemand[fuel,ecc,area,year-1]*1.0175
  end

  WriteDisk(db,"SOutput/TotDemand",TotDemand)

  #
  # Natural Gas Demands excluding Electric Utility NG Demands
  # Select the ECCs in residential (SecMap=1), commercial (SecMap=2),
  # industrial (SecMap=3), and transportation (SecMap=4) sectors.
  # Lag demand one year so we are consistent with model - Jeff Amlin 7/12/13
  #
  eccs1 = findall(SecMap .== 1)
  eccs2 = findall(SecMap .== 2)
  eccs3 = findall(SecMap .== 3)
  eccs4 = findall(SecMap .== 4)
  eccs = union(eccs1,eccs2,eccs3,eccs4)
 
  year = Zero
  for area in Areas
    GasDemand[area,year]=sum(TotDemand[fuel,ecc,area,year] for ecc in eccs, fuel in fuels)
  end
  
  years = collect(First:Final)
  for year in years, area in Areas
    GasDemand[area,year]=sum(TotDemand[fuel,ecc,area,year-1] for ecc in eccs, fuel in fuels)
  end
    
  for year in Years, area in Areas, ecc in ECCs
    if DrSwitch[ecc,area,year] == 22
      xDriver[ecc,area,year]=GasDemand[area,year]
    end
  end

  WriteDisk(db,"MInput/xDriver",xDriver)

end

function Control(db)
  @info "EconomicDrivers_Gas.jl - Control"
  GasDriver(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
