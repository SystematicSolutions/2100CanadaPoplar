#
# AdjustNLOtherChemicals.jl
#
# Adds specific amounts to emissions from the Breya Renewable Fuels and OtherChemicals
#
using EnergyModel

module AdjustNLOtherChemicals

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String
  
  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CERSM::VariableArray{4} = ReadDisk(db,"$CalDB/CERSM") # [Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)
  CUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor ($/Yr/$/Yr)
  DCTC::VariableArray{5} = ReadDisk(db,"$Outpt/DCTC") # [Enduse,Tech,EC,Area,Year] Device Cap. Trade Off Coefficient (DLESS)
  DFTC::VariableArray{5} = ReadDisk(db,"$Outpt/DFTC") # [Enduse,Tech,EC,Area,Year] Device Fuel Trade Off Coef. (DLESS)
  DSt::VariableArray{4} = ReadDisk(db,"$Outpt/DSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  FsFrac::VariableArray{5} = ReadDisk(db,"$Outpt/FsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  FsPEE::VariableArray{4} = ReadDisk(db,"$CalDB/FsPEE") # [Tech,EC,Area,Year] Feedstock Process Efficiency ($/mmBtu)
  FsFracMax::VariableArray{5} = ReadDisk(db,"$Input/FsFracMax") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  FsFracMin::VariableArray{5} = ReadDisk(db,"$Input/FsFracMin") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  PCCN::VariableArray{4} = ReadDisk(db,"$Outpt/PCCN") # [Enduse,Tech,EC,Area] Normalized Process Capital Cost ($/mmBtu)
  PCTC::VariableArray{5} = ReadDisk(db,"$Outpt/PCTC") # [Enduse,Tech,EC,Area,Year] Process Capital Trade Off Coefficient (DLESS)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # [Enduse,EC,Area] 'Maximum Process Efficiency ($/mmBtu)'
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year]
  PEPM::VariableArray{5} = ReadDisk(db,"$Input/PEPM") # [Enduse,Tech,EC,Area,Year] Process Energy Price Mult. ($/$)
  PFTC::VariableArray{5} = ReadDisk(db,"$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year] Process Fuel Trade Off Coefficient
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN") # [Enduse,Tech,EC,Area] Process Normalized Fuel Price ($/mmBtu)
  StockAdjustment::VariableArray{5} = ReadDisk(db,"$Input/StockAdjustment") # [Enduse,Tech,EC,Area,Year] Exogenous Capital Stock Adjustment ($/$)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Feedstock Demands Fuel/Tech Split (Fraction)
  
  # Scratch Variables
  AdjustFactor::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Calibration adjustment factor
end

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
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FlPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FlPOCX") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions Coefficient (Tonnes/Driver)
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-Output)
  VnPOCX::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCX") # [ECC,Poll,Area,Year] Fugitive Venting Emissions Coefficient (Tonnes/Driver)

  # Scratch Variables
  AdjustFactor::VariableArray{1} = zeros(Float32,length(Year))
end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input,Outpt) = data
  (; Area,EC,Enduses) = data
  (; Fuels,Tech,Techs) = data
  (; AdjustFactor,CERSM,CUF,DCTC,DFTC,DSt,FsFrac) = data
  (; FsPEE,MMSM0,PCCN,PCTC) = data
  (; PEE,PEM,PEMM,PEPM,PFTC,PFPN,StockAdjustment,AdjustFactor) = data

  AdjustFactor[Yr(2023)]=0.0695
  AdjustFactor[Yr(2024)]=0.090227
  AdjustFactor[Yr(2025)]=0.135097
  AdjustFactor[Yr(2026)]=0.158487
  AdjustFactor[Yr(2027)]=0.104411
  AdjustFactor[Yr(2028)]=0.109387
  AdjustFactor[Yr(2029)]=0.100705
  AdjustFactor[Yr(2030)]=0.131781
  AdjustFactor[Yr(2031)]=0.15637
  AdjustFactor[Yr(2032)]=0.17926
  AdjustFactor[Yr(2033)]=0.199117
  AdjustFactor[Yr(2034)]=0.190139
  AdjustFactor[Yr(2035)]=0.212027
  AdjustFactor[Yr(2036)]=0.234930
  AdjustFactor[Yr(2037)]=0.242898
  AdjustFactor[Yr(2038)]=0.251931
  AdjustFactor[Yr(2039)]=0.260579
  AdjustFactor[Yr(2040)]=0.4992
  AdjustFactor[Yr(2041)]=0.503795
  AdjustFactor[Yr(2042)]=0.50966
  AdjustFactor[Yr(2043)]=0.510874
  AdjustFactor[Yr(2044)]=0.51287
  AdjustFactor[Yr(2045)]=0.515084
  AdjustFactor[Yr(2046)]=0.516987
  AdjustFactor[Yr(2047)]=0.516078
  AdjustFactor[Yr(2048)]=0.515073
  AdjustFactor[Yr(2049)]=0.513512
  AdjustFactor[Yr(2050)]=0.51093

  years = collect(Yr(2023):Final)
  NL = Select(Area,"NL")
  QC = Select(Area,"QC")
  ec = Select(EC,"OtherChemicals")

  # 
  # Plant only has Electric and Gas demands
  # 
  Electric = Select(Tech,"Electric")
  Gas = Select(Tech,"Gas")
  techs = Select(Tech,["Electric","Gas"])

  for year in years, enduse in Enduses
    CUF[enduse,Electric,ec,NL,year] = 0.0648
    CUF[enduse,Gas,ec,NL,year] = 1.00
  end

  for year in years, enduse in Enduses
    CERSM[enduse,ec,NL,year] = CERSM[enduse,ec,QC,year]
  end
  for year in years, tech in techs, enduse in Enduses
    StockAdjustment[enduse,tech,ec,NL,year]=0.00
  end
  for year in years, tech in techs, enduse in Enduses
    DCTC[enduse,tech,ec,NL,year] = DCTC[enduse,tech,ec,QC,year]
  end
  for year in years, tech in techs, enduse in Enduses
    DFTC[enduse,tech,ec,NL,year] = DFTC[enduse,tech,ec,QC,year]
  end
  for year in years, enduse in Enduses
    DSt[enduse,ec,NL,year] = DSt[enduse,ec,QC,year]
  end
  for year in years, tech in techs, enduse in Enduses
    MMSM0[enduse,tech,ec,NL,year] = MMSM0[enduse,tech,ec,QC,year]
  end
  for tech in techs, enduse in Enduses
    PCCN[enduse,tech,ec,NL] = PCCN[enduse,tech,ec,QC]
  end
  for year in years, tech in techs, enduse in Enduses
    PCTC[enduse,tech,ec,NL,year] = PCTC[enduse,tech,ec,QC,year]
  end
  for enduse in Enduses
    PEM[enduse,ec,NL] = PEM[enduse,ec,QC]
  end
  for year in years, tech in techs, enduse in Enduses
    PEMM[enduse,tech,ec,NL,year] = PEMM[enduse,tech,ec,QC,year]
  end
  for year in years, tech in techs, enduse in Enduses
    PEPM[enduse,tech,ec,NL,year] = PEPM[enduse,tech,ec,QC,year]
  end
  for tech in techs, enduse in Enduses
    PFPN[enduse,tech,ec,NL] = PFPN[enduse,tech,ec,QC]  
  end
  for year in years, tech in techs, enduse in Enduses
    PFTC[enduse,tech,ec,NL,year] = PFTC[enduse,tech,ec,QC,year]
  end
  
  #  
  # Adjust PEMM and MMSM0 to match our goals of 2.2 TBtu electricity
  # and 1.01 TBtu LFO in 2014.
  # Need to adjust fuel demands and process efficiency to increase emissions
  # 
  for year in years, tech in techs, enduse in Enduses
    PEE[enduse,tech,ec,NL,year] = PEE[enduse,tech,ec,NL,year] * AdjustFactor[year] * 0.1   
    PEMM[enduse,tech,ec,NL,year] = PEMM[enduse,tech,ec,NL,year] * AdjustFactor[year]
    MMSM0[enduse,tech,ec,NL,year] = 0.0
  end
  for year in years, enduse in Enduses
    MMSM0[enduse,Electric,ec,NL,year] = 0.0
    MMSM0[enduse,Gas,ec,NL,year] = 0.0
  end
  
  for enduse in Enduses
    PEM[enduse,ec,NL] = PEM[enduse,ec,NL] * AdjustFactor[Yr(2023)]   
  end

  WriteDisk(db,"$CalDB/CERSM",CERSM)
  WriteDisk(db,"$CalDB/CUF",CUF)
  WriteDisk(db,"$Outpt/DCTC",DCTC)
  WriteDisk(db,"$Outpt/DFTC",DFTC)
  WriteDisk(db,"$Outpt/DSt",DSt)
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$Input/StockAdjustment",StockAdjustment)
  WriteDisk(db,"$Outpt/PCCN",PCCN)
  WriteDisk(db,"$Outpt/PCTC",PCTC)
  WriteDisk(db,"$CalDB/PEM",PEM)
  WriteDisk(db,"$CalDB/PEMM",PEMM)
  WriteDisk(db,"$Input/PEPM",PEPM)
  WriteDisk(db,"$Outpt/PFPN",PFPN)
  WriteDisk(db,"$Outpt/PFTC",PFTC)

  # 
  # Feedstock Demands
  # 
  for year in years, fuel in Fuels, tech in Techs
    FsFrac[fuel,tech,ec,NL,year] = FsFrac[fuel,tech,ec,QC,year]
  end

  for year in years, tech in Techs
    FsPEE[tech,ec,NL,year]=FsPEE[tech,ec,QC,year]
    FsPEE[tech,ec,NL,year]=FsPEE[tech,ec,NL,year] * AdjustFactor[year] * .1
  end 

  WriteDisk(db,"$Outpt/FsFrac",FsFrac)
  WriteDisk(db,"$CalDB/FsPEE",FsPEE)
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC,Polls) = data
  (; FlPOCX,FuPOCX,MEPOCX,VnPOCX) = data

  # 
  # * Use on Process Emissions for NL Other Chemicals
  # 
  years = collect(Yr(2023):Final)
  NL = Select(Area,"NL")
  QC = Select(Area,"QC")
  ec = Select(ECC,"OtherChemicals")

  for poll in Polls, year in years
    FlPOCX[ec,poll,NL,year] = FlPOCX[ec,poll,QC,year]
    FuPOCX[ec,poll,NL,year] = FuPOCX[ec,poll,QC,year]
    MEPOCX[ec,poll,NL,year] = MEPOCX[ec,poll,QC,year]
    VnPOCX[ec,poll,NL,year] = VnPOCX[ec,poll,QC,year]
  end

  WriteDisk(db,"MEInput/FlPOCX",FlPOCX)
  WriteDisk(db,"MEInput/FuPOCX",FuPOCX)
  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
  WriteDisk(db,"MEInput/VnPOCX",VnPOCX)
end

function PolicyControl(db)
  @info("AdjustNLOtherChemicals.jl PolicyControl")
  IndPolicy(db)
  MacroPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
