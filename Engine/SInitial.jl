#
# SInitial.jl - Supply constants and initial values
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2013 Systematic Solutions, Inc. All rights reserved.
#

using EnergyModel

module SInitial

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
#  year::Int
#  prior::Int
#  next::Int
#  CTime::Int
#  SceName::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESes::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SegKey::SetArray = ReadDisk(db,"MainDB/SegKey")
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  ENMSM::VariableArray{3} = ReadDisk(db,"SOutput/ENMSM") # [Fuel,Area,Year]  Energy Supply Constraint Mult.
  ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN")  # [Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db,"SOutput/FPF")    # [Fuel,ES,Area,Year]  Delivered Fuel Price ($/mmBtu)
  FsFP::VariableArray{4} = ReadDisk(db,"SOutput/FsFP")  # [Fuel,ES,Area,Year]  Feedstock Fuel Price ($/mmBtu)
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] NonExist = -1
  PCERF::VariableArray{4} = ReadDisk(db,"SInput/PCERF") # [Fuel,Age,ECC,Area] Fraction of Energy Requirement by Age and Fuel (Fraction)
  PCERG::VariableArray{3} = ReadDisk(db,"SInput/PCERG") # [Fuel,ECC,Area] Energy Requirement Growth Rate (1/Yr)
  PCPL::VariableArray{3} = ReadDisk(db,"MInput/PCPL")   # [ECC,Area,Year] Physical Life of Production Capacity (Years)
  PE::VariableArray{3} = ReadDisk(db,"SOutput/PE")      # [ECC,Area,Year]  Price of Electricity ($/MWh)
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC]  Map between Sector and ECC Sets (1=Res, 2=Com, 3=Ind, etc.)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Exogenous Price Normal ($/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF")   # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xPE::VariableArray{3} = ReadDisk(db,"SInput/xPE")  #[ECC,Area,Year]  Historical Electricity Price (Real $/MWh)
  xSegSw::VariableArray{1} = ReadDisk(db,"MainDB/xSegSw") #[Seg] Segment Execution Switch
end

function Initial(data)
  (;db) = data
  (;Areas,ECCs,ES,ESes,Fuel,Fuels,Nations,Seg,Years) = data
  (;EEConv,ENPN,ENMSM,FPF,FsFP,NonExist,PE,SecMap) = data
  (;xENPN,xFPF,xInflation,xPE,xSegSw) = data

  @info "SInitial.jl,Initialization"

  #
  # Price and Availability
  #
  years = collect(Zero:First)
  for year in years, nation in Nations, fuel in Fuels
    ENPN[fuel,nation,year] = xENPN[fuel,nation,year]
  end

  for year in years, area in Areas, es in ESes, fuel in Fuels
    FPF[fuel,es,area,year] = xFPF[fuel,es,area,year]*xInflation[area,year]
    FsFP[fuel,es,area,year] = FPF[fuel,es,area,year]
    ENMSM[fuel,area,year] = 1.0
  end

  #
  # TODOSimplify - will the electric sector ever not exist? Simplify?
  # Jeff Amlin 8/23/24
  # 
  seg = Select(Seg,"Electric")
  if xSegSw[seg] == NonExist

    fuel = Select(Fuel,"Electric")

    Res = 1
    es = Select(ES,"Residential")
    eccs = findall(SecMap .== Res)
    for year in Years, area in Areas, ecc in eccs
      PE[ecc,area,year] = FPF[fuel,es,area,year]*EEConv/1000
    end

    Com = 2
    es = Select(ES,"Commercial")
    eccs = findall(SecMap .== Com)
    for year in Years, area in Areas, ecc in eccs
      PE[ecc,area,year] = FPF[fuel,es,area,year]*EEConv/1000
    end

    Ind = 3
    es = Select(ES,"Industrial")
    eccs = findall(SecMap .== Ind)
    for year in Years, area in Areas, ecc in eccs
      PE[ecc,area,year] = FPF[fuel,es,area,year]*EEConv/1000
    end

    #
    # TODOSimplify.  The lines below nullify the lines above
    # Do we need the lines above? - Jeff Amlin 8/22/24
    #

    for year in Years, area in Areas, ecc in ECCs
      PE[ecc,area,year] = xPE[ecc,area,year]*xInflation[area,year]
    end

  else
    for year in Years, area in Areas, ecc in ECCs
      PE[ecc,area,year] = xPE[ecc,area,year]*xInflation[area,year]
    end
  end

  WriteDisk(db,"SOutput/ENMSM",ENMSM)
  WriteDisk(db,"SOutput/ENPN",ENPN)
  WriteDisk(db,"SOutput/FPF",FPF)
  WriteDisk(db,"SOutput/FsFP",FsFP)
  WriteDisk(db,"SOutput/PE",PE)

end

function Constant(data)
  (;db) = data
  (;Age,Ages,Areas,ECCs,Fuels) = data
  (;PCERF,PCERG,PCPL) = data

  AgeMax = float(length(Age))
  for area in Areas, ecc in ECCs, age in Ages, fuel in Fuels
    ALoc = float(age)

    @finite_math PCERF[fuel,age,ecc,area] = (exp(-PCERG[fuel,ecc,area]*
      (ALoc-1)*PCPL[ecc,area,Zero]/AgeMax)-
      exp(-PCERG[fuel,ecc,area]*ALoc*PCPL[ecc,area,Zero]/AgeMax))/
      (1-exp(-PCERG[fuel,ecc,area]*PCPL[ecc,area,Zero]))+
      (1-PCERG[fuel,ecc,area]/PCERG[fuel,ecc,area])/3

#  TODOJulia Is this just to have the numbers match? - Jeff Amlin 11/12/24
      if PCERF[fuel,age,ecc,area] < 1/1e36
        PCERF[fuel,age,ecc,area] = 0.0
      end
  end

  WriteDisk(db,"SInput/PCERF",PCERF)

end

function Control(data)

  #
  # Supply Constants
  #
  Initial(data)
  Constant(data)
end

end
