#
# MInitial.jl - Macroeconomic constants and initial values
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2013 Systematic Solutions, Inc. All rights reserved.
#

using EnergyModel

module MInitial

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

  # CalDB::String = "MCalDB"
  # Input::String = "MInput"
  # Outpt::String = "MOutput"
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Millions/Yr)
  ECUF::VariableArray{3} = ReadDisk(db,"MOutput/ECUF") # [ECC,Area,Year] Capital Utilization Fraction ($/$)
  GO::VariableArray{3} = ReadDisk(db,"MOutput/GO") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  GOMult::VariableArray{3} = ReadDisk(db,"SOutput/GOMult") # [ECC,Area,Year] Gross Output Multiplier ($/$)
  GOMSmooth::VariableArray{3} = ReadDisk(db,"SOutput/GOMSmooth") # [ECC,Area,Year] Smooth of Gross Output Multiplier ($/$)
  GRP::VariableArray{2} = ReadDisk(db,"MOutput/GRP") # [Area,Year] Gross Regional Product (M$/Yr)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationUnit") # [Unit,Year] Inflation Index ($/$)
  InSm::VariableArray{2} = ReadDisk(db,"MOutput/InSm") # [Area,Year] Smoothed Inflation Rate (1/Yr)
  PCgRF::VariableArray{3} = ReadDisk(db,"MInput/PCgRF") # [Age,ECC,Area] Fraction of Energy Requirement by Age
  PCLV::VariableArray{4} = ReadDisk(db,"MOutput/PCLV") # [Age,ECC,Area,Year] Production Capacity (M$/Yr)
  PCLVI::VariableArray{3} = ReadDisk(db,"MInput/PCLVI") # [Age,ECC,Area] Initial Production Capacity (M$/Yr)
  PCPL::VariableArray{3} = ReadDisk(db,"MInput/PCPL") # [ECC,Area,Year] Physical Life of Production Capacity (Years)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Economic Driver (Various Millions/Yr)
  xECUF::VariableArray{3} = ReadDisk(db,"MInput/xECUF") # [ECC,Area,Year] Capital Utilization Fraction ($/$)
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xGRP::VariableArray{2} = ReadDisk(db,"MInput/xGRP") # [Area,Year] Gross Regional Product (Real M$/Yr)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  xInflationUnit::VariableArray{2} = ReadDisk(db,"MInput/xInflationUnit") # [Unit,Year] Inflation Index ($/$)
  xInSm::VariableArray{2} = ReadDisk(db,"MInput/xInSm") # [Area,Year] Smoothed Inflation Rate (1/Yr)
  xPC::VariableArray{3} = ReadDisk(db,"MInput/xPC") # [ECC,Area,Year] Production Capacity (Various Millions/Yr)

  #
  # Scratch Variables
  #
  #  NUMBER   'Number Data of Points'
  PCgR::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # [ECC,Area] Historical Long-Term Production Capacity Growth Rate
  SX::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # [ECC,Area] sum of x
  SXX::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # [ECC,Area] sum of x*X
  SXY::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # [ECC,Area] sum of x*Y
  SY::VariableArray{2} = zeros(Float32,length(ECC),length(Area)) # [ECC,Area] sum of Y
  SmDriver::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Smooth of Economic Driver (Various Millions/Yr)
  # Time1    'Local Time Variable'
  YI::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] Y index for regressions
  xI::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # [ECC,Area,Year] x index for regressions
end

function Initial(data)
  (;db) = data
  (;Age,Ages,Areas,ECC,ECCs,Nation) = data
  (;Nations,Units,Years) = data
  (;ANMap,Driver,ECUF,GO,GOMult,GOMSmooth,GRP,Inflation,InflationNation,InflationUnit,InSm) = data
  (;PCgRF,PCLV,PCLVI,PCPL,xDriver,xECUF,xGO,xGRP,xInflation,xInflationNation) = data
  (;xInflationUnit,xInSm,xPC) = data
  (;PCgR,SX,SXX,SXY,SY,YI,xI) = data

  #
  # Initializations
  #
  # @info "Initialization"
  #
  # Macroeconomy Initialization
  #
  # xECUF is used to smooth out historical changes in the economic driver
  #
  # *SmDriver=xDriver
  # *Select Year(First-Final)
  # *SmDriver(ECC,Area,Y)=SmDriver(ECC,Area,Y-1)+(xDriver(ECC,Area,Y)-SmDriver(ECC,Area,Y-1))/5
  # *xECUF=.80*xDriver/SmDriver
  # *Select Year*
  # *Write Disk(xECUF)
  #
  # Initialize Production Capacity
  #
  for year in Years, area in Areas, ecc in ECCs
    @finite_math xPC[ecc,area,year] = xDriver[ecc,area,year]/xECUF[ecc,area,year]
  end
  
  #
  # Production Capacity Historical Growth Rate
  #
  Time1 = Int(HisTime-ITime+1)
  years = collect(Zero:Time1)
 
  NUMBER = float(length(years))
  for area in Areas, ecc in ECCs
    for year in years
      xI[ecc,area,year] = float(year)-1
      @finite_math YI[ecc,area,year]=log(xPC[ecc,area,year])
    end
    SX[ecc,area] = sum(xI[ecc,area,year] for year in years)
    SY[ecc,area] = sum(YI[ecc,area,year] for year in years)
    SXX[ecc,area] = sum(xI[ecc,area,year]*xI[ecc,area,year] for year in years)
    SXY[ecc,area] = sum(xI[ecc,area,year]*YI[ecc,area,year] for year in years)
    @finite_math PCgR[ecc,area] = (SX[ecc,area]*SY[ecc,area]-NUMBER*SXY[ecc,area])/
            (SX[ecc,area]*SX[ecc,area]-NUMBER*SXX[ecc,area])
  end

  #
  # Capital Vintage Requirements Fraction
  #
  Loc1 = float(length(Age))
  for area in Areas, ecc in ECCs, age in Ages
    if PCgR[ecc,area] != 0.0
      Loc2 = float(age)
      @finite_math PCgRF[age,ecc,area] = (exp(-PCgR[ecc,area]*(Loc2-1)*
         PCPL[ecc,area,Zero]/Loc1)-
         exp(-PCgR[ecc,area]*Loc2*PCPL[ecc,area,Zero]/Loc1))/
         (1-exp(-PCgR[ecc,area]*PCPL[ecc,area,Zero]))
    else
      PCgRF[age,ecc,area] = 1/3
    end
  end

  #
  # Fixing Landuse PCGRF
  #
  CN=Select(Nation,"CN")
  areas=findall(ANMap[:,CN] .== 1)
  eccs=Select(ECC,["LandUse","ForestFires","Biogenics"])
  for area in areas, ecc in eccs, age in Ages
    PCgRF[age,ecc,area] = 1/3
  end

  for area in Areas, ecc in ECCs, age in Ages
    PCLVI[age,ecc,area] = xPC[ecc,area,Zero]*PCgRF[age,ecc,area]
  end

  WriteDisk(db,"MInput/xPC",xPC)
  WriteDisk(db,"MInput/PCgRF",PCgRF)
  WriteDisk(db,"MInput/PCLVI",PCLVI)

  for area in Areas, ecc in ECCs
    ECUF[ecc,area,Zero] = xECUF[ecc,area,Zero]
  end
  for area in Areas, ecc in ECCs, age in Ages
    PCLV[age,ecc,area,Zero] = PCLVI[age,ecc,area]
  end
  for area in Areas
    Inflation[area,Zero] = xInflation[area,Zero]
  end
  for nation in Nations
    InflationNation[nation,Zero] = xInflationNation[nation,Zero]
  end
  for unit in Units
    InflationUnit[unit,Zero] = xInflationUnit[unit,Zero]
  end
  for area in Areas
    InSm[area,Zero] = xInSm[area,Zero]
  end

  WriteDisk(db,"MOutput/ECUF",ECUF)
  WriteDisk(db,"MOutput/PCLV",PCLV)
  WriteDisk(db,"MOutput/Inflation",Inflation)
  WriteDisk(db,"MOutput/InflationNation",InflationNation)
  WriteDisk(db,"MOutput/InflationUnit",InflationUnit)
  WriteDisk(db,"MOutput/InSm",InSm)

  #
  # Economic Drivers and Gross Output
  #
  @.   Driver = xDriver
  @.   GO = xGO
  @.   GRP = xGRP
  WriteDisk(db,"MOutput/Driver",Driver)
  WriteDisk(db,"MOutput/GO",GO)
  WriteDisk(db,"MOutput/GRP",GRP)


  #
  # Gross Output Multiplier
  #
  @. GOMult = 1.0
  @. GOMSmooth = 1.0
  WriteDisk(db,"SOutput/GOMult",GOMult)
  WriteDisk(db,"SOutput/GOMSmooth",GOMSmooth)

end

function Constant(data)
  #
  # Empty Procedure in Promula
  #
end

function Control(data)

  #
  # @info "Macroeconomic Parameters"
  #

  Initial(data)

  #
  #  Constant # Note: Constant is empty and uncalled
  #
end

end
