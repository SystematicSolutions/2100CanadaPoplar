#
# AdjustNLOtherChemicals_TOM.jl
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
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
  MacroSwitch::Vector{String} = ReadDisk(db,"MInput/MacroSwitch") #[Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FlPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FlPOCX") # [ECC,Poll,Area,Year] Fugitive Flaring Emissions Coefficient (Tonnes/Driver)
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") # [ECC,Poll,Area,Year] Other Fugitive Emissions Coefficient (Tonnes/Driver)
  MacroSwitch::Vector{String} = ReadDisk(db,"MInput/MacroSwitch") #[Nation] String Indicator of Macroeconomic Forecast (TOM,Stokes,AEO,CER)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Non-Energy Pollution Coefficient (Tonnes/$B-Output)
  VnPOCX::VariableArray{4} = ReadDisk(db,"MEInput/VnPOCX") # [ECC,Poll,Area,Year] Fugitive Venting Emissions Coefficient (Tonnes/Driver)

  # Scratch Variables
  AdjustFactor::VariableArray{1} = zeros(Float32,length(Year))
end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input,Outpt) = data
  (; Area,EC,Enduse,Enduses) = data
  (; Fuels,Nation,Tech,Techs) = data
  (; AdjustFactor,CERSM,CUF,DCTC,DFTC,DSt,FsFrac) = data
  (; FsPEE,MacroSwitch,MMSM0,PCCN,PCTC) = data
  (; PEE,PEM,PEMM,PEPM,PFTC,PFPN,StockAdjustment,AdjustFactor) = data

  CN = Select(Nation,"CN")
  if MacroSwitch[CN] == "TOM"

    years = collect(Yr(2023):Final)
    NL = Select(Area,"NL")
    QC = Select(Area,"QC")
    ec = Select(EC,"OtherChemicals")

    # 
    # Plant only has Electric and Gas demands
    # 
    techs = Select(Tech,["Electric","Gas"])
    for year in years, enduse in Enduses, tech in techs
      CUF[enduse,tech,ec,NL,year] = CUF[enduse,tech,ec,QC,year]
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
    # Feedstock Demands
    # 
    for year in years, fuel in Fuels, tech in Techs
      FsFrac[fuel,tech,ec,NL,year] = FsFrac[fuel,tech,ec,QC,year]
    end

    #
    # AdjustFactor is not given a value - Jeff Amlin 1/28/26
    #
    for year in years, tech in Techs
      FsPEE[tech,ec,NL,year]=FsPEE[tech,ec,QC,year]
#     FsPEE[tech,ec,NL,year]=FsPEE[tech,ec,NL,year]*AdjustFactor[year]*0.1
    end 

    #
    # Get rid of historical 2022 electricity values for EUPC, 
    # PER, and DER by setting StockAdjustment=-1. 03/20/24 R.Levesque
    #
    tech=Select(Tech,"Electric")
    enduses=Select(Enduse,["Heat","OthSub"])
    for enduse in enduses
      StockAdjustment[enduse,tech,ec,NL,Yr(2022)]=-1
    end
    
    #
    # Match fuel shares from Ash. 03/18/24 R.Levesque
    #
    for year in years, tech in Techs, enduse in enduses
      MMSM0[enduse,tech,ec,NL,year] = -170.00
      if Tech[tech] == "Electric"
        MMSM0[enduse,tech,ec,NL,year] = -10.00
      elseif Tech[tech] == "Gas"
        MMSM0[enduse,tech,ec,NL,year] = 0.00
      end
    end

    #
    # Adjust energy demands to match Ash
    # 03/18/24 R.Levesque
    #
    for enduse in Enduses
      CERSM[enduse,ec,NL,Yr(2023)] = CERSM[enduse,ec,NL,Yr(2023)]*0.433*3.44
      CERSM[enduse,ec,NL,Yr(2024)] = CERSM[enduse,ec,NL,Yr(2024)]*15.659*1.049
      CERSM[enduse,ec,NL,Yr(2025)] = CERSM[enduse,ec,NL,Yr(2025)]*16.989*1.068
      CERSM[enduse,ec,NL,Yr(2026)] = CERSM[enduse,ec,NL,Yr(2026)]*15.987*1.086
      CERSM[enduse,ec,NL,Yr(2027)] = CERSM[enduse,ec,NL,Yr(2027)]*16.8924
      CERSM[enduse,ec,NL,Yr(2028)] = CERSM[enduse,ec,NL,Yr(2028)]*16.679
      CERSM[enduse,ec,NL,Yr(2029)] = CERSM[enduse,ec,NL,Yr(2029)]*16.5511
      CERSM[enduse,ec,NL,Yr(2030)] = CERSM[enduse,ec,NL,Yr(2030)]*16.0704
      CERSM[enduse,ec,NL,Yr(2031)] = CERSM[enduse,ec,NL,Yr(2031)]*15.4502
      CERSM[enduse,ec,NL,Yr(2032)] = CERSM[enduse,ec,NL,Yr(2032)]*14.7416
      CERSM[enduse,ec,NL,Yr(2033)] = CERSM[enduse,ec,NL,Yr(2033)]*13.9862
      CERSM[enduse,ec,NL,Yr(2034)] = CERSM[enduse,ec,NL,Yr(2034)]*13.2892
      CERSM[enduse,ec,NL,Yr(2035)] = CERSM[enduse,ec,NL,Yr(2035)]*12.5337
      CERSM[enduse,ec,NL,Yr(2036)] = CERSM[enduse,ec,NL,Yr(2036)]*11.788
      CERSM[enduse,ec,NL,Yr(2037)] = CERSM[enduse,ec,NL,Yr(2037)]*10.9515
      CERSM[enduse,ec,NL,Yr(2038)] = CERSM[enduse,ec,NL,Yr(2038)]*10.1919
      CERSM[enduse,ec,NL,Yr(2039)] = CERSM[enduse,ec,NL,Yr(2039)]*9.50
      CERSM[enduse,ec,NL,Yr(2040)] = CERSM[enduse,ec,NL,Yr(2040)]*8.588
      CERSM[enduse,ec,NL,Yr(2041)] = CERSM[enduse,ec,NL,Yr(2041)]*7.7804
      CERSM[enduse,ec,NL,Yr(2042)] = CERSM[enduse,ec,NL,Yr(2042)]*7.0747
      CERSM[enduse,ec,NL,Yr(2043)] = CERSM[enduse,ec,NL,Yr(2043)]*6.454
      CERSM[enduse,ec,NL,Yr(2044)] = CERSM[enduse,ec,NL,Yr(2044)]*5.910
      CERSM[enduse,ec,NL,Yr(2045)] = CERSM[enduse,ec,NL,Yr(2045)]*5.432
      CERSM[enduse,ec,NL,Yr(2046)] = CERSM[enduse,ec,NL,Yr(2046)]*4.998
      CERSM[enduse,ec,NL,Yr(2047)] = CERSM[enduse,ec,NL,Yr(2047)]*4.615
      CERSM[enduse,ec,NL,Yr(2048)] = CERSM[enduse,ec,NL,Yr(2048)]*4.276
      CERSM[enduse,ec,NL,Yr(2049)] = CERSM[enduse,ec,NL,Yr(2049)]*3.977
      CERSM[enduse,ec,NL,Yr(2050)] = CERSM[enduse,ec,NL,Yr(2050)]*3.712
    end
    
    for tech in Techs
      FsPEE[tech,ec,NL,Yr(2023)]=FsPEE[tech,ec,NL,Yr(2023)]*0.0135*0.99
      FsPEE[tech,ec,NL,Yr(2024)]=FsPEE[tech,ec,NL,Yr(2024)]*0.0240*0.99
      FsPEE[tech,ec,NL,Yr(2025)]=FsPEE[tech,ec,NL,Yr(2025)]*0.0296*0.999
      FsPEE[tech,ec,NL,Yr(2026)]=FsPEE[tech,ec,NL,Yr(2026)]*0.0353*0.99
      FsPEE[tech,ec,NL,Yr(2027)]=FsPEE[tech,ec,NL,Yr(2027)]*0.0325*0.733
      FsPEE[tech,ec,NL,Yr(2028)]=FsPEE[tech,ec,NL,Yr(2028)]*0.0342*0.733
      FsPEE[tech,ec,NL,Yr(2029)]=FsPEE[tech,ec,NL,Yr(2029)]*0.0317*0.732
      FsPEE[tech,ec,NL,Yr(2030)]=FsPEE[tech,ec,NL,Yr(2030)]*0.0419*0.731
      FsPEE[tech,ec,NL,Yr(2031)]=FsPEE[tech,ec,NL,Yr(2031)]*0.0499*0.732
      FsPEE[tech,ec,NL,Yr(2032)]=FsPEE[tech,ec,NL,Yr(2032)]*0.0575*0.732
      FsPEE[tech,ec,NL,Yr(2033)]=FsPEE[tech,ec,NL,Yr(2033)]*0.0641*0.732
      FsPEE[tech,ec,NL,Yr(2034)]=FsPEE[tech,ec,NL,Yr(2034)]*0.0617*0.731
      FsPEE[tech,ec,NL,Yr(2035)]=FsPEE[tech,ec,NL,Yr(2035)]*0.0695*0.732
      FsPEE[tech,ec,NL,Yr(2036)]=FsPEE[tech,ec,NL,Yr(2036)]*0.0776*0.732
      FsPEE[tech,ec,NL,Yr(2037)]=FsPEE[tech,ec,NL,Yr(2037)]*0.0809*0.732
      FsPEE[tech,ec,NL,Yr(2038)]=FsPEE[tech,ec,NL,Yr(2038)]*0.0847*0.732
      FsPEE[tech,ec,NL,Yr(2039)]=FsPEE[tech,ec,NL,Yr(2039)]*0.0885*0.732
      FsPEE[tech,ec,NL,Yr(2040)]=FsPEE[tech,ec,NL,Yr(2040)]*0.1719*0.727
      FsPEE[tech,ec,NL,Yr(2041)]=FsPEE[tech,ec,NL,Yr(2041)]*0.1751*0.732
      FsPEE[tech,ec,NL,Yr(2042)]=FsPEE[tech,ec,NL,Yr(2042)]*0.1796*0.732
      FsPEE[tech,ec,NL,Yr(2043)]=FsPEE[tech,ec,NL,Yr(2043)]*0.183*0.732
      FsPEE[tech,ec,NL,Yr(2044)]=FsPEE[tech,ec,NL,Yr(2044)]*0.1868*0.732
      FsPEE[tech,ec,NL,Yr(2045)]=FsPEE[tech,ec,NL,Yr(2045)]*0.1909*0.732
      FsPEE[tech,ec,NL,Yr(2046)]=FsPEE[tech,ec,NL,Yr(2046)]*0.1959*0.732
      FsPEE[tech,ec,NL,Yr(2047)]=FsPEE[tech,ec,NL,Yr(2047)]*0.2001*0.732
      FsPEE[tech,ec,NL,Yr(2048)]=FsPEE[tech,ec,NL,Yr(2048)]*0.2043*0.732
      FsPEE[tech,ec,NL,Yr(2049)]=FsPEE[tech,ec,NL,Yr(2049)]*0.2083*0.732
      FsPEE[tech,ec,NL,Yr(2050)]=FsPEE[tech,ec,NL,Yr(2050)]*0.2121*0.732
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
    WriteDisk(db,"$Outpt/FsFrac",FsFrac)
    WriteDisk(db,"$CalDB/FsPEE",FsPEE)
  end
end

function MacroPolicy(db)
  data = MControl(; db)
  (; Area,ECC,Nation,Polls) = data
  (; FlPOCX,FuPOCX,MacroSwitch,MEPOCX,VnPOCX) = data

  CN = Select(Nation,"CN")
  if MacroSwitch[CN] == "TOM"

    # 
    # Use on Process Emissions for NL Other Chemicals
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
end

function PolicyControl(db)
  @info("AdjustNLOtherChemicals_TOM.jl PolicyControl function called")
  IndPolicy(db)
  MacroPolicy(db)
  @info("Policy executed succecsfully")
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
