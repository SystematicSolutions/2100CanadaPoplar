#
# Com_HistoricalProcessEfficiency.jl
#
using EnergyModel

module Com_HistoricalProcessEfficiency

import ...EnergyModel: ReadDisk,WriteDisk,Select, Yr
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final, Zero, Last
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CCalib
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DDay::VariableArray{3} = ReadDisk(db,"$Input/DDay") # [Enduse,Area,Year] Annual Degree Days (Degree Days)
  DDayNorm::VariableArray{2} = ReadDisk(db,"$Input/DDayNorm") # [Enduse,Area] Normal Annual Degree Days (Degree Days)
  DDCoefficient::VariableArray{4} = ReadDisk(db,"$Input/DDCoefficient") # [Enduse,EC,Area,Year] Annual Energy Degree Day Coefficient (DD/DD)
  DEE::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu)
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area] Maximum Device Efficiency (Btu/Btu)
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu)
  DEStdP::VariableArray{5} = ReadDisk(db,"$Input/DEStdP") # [Enduse,Tech,EC,Area,Year] Device Efficiency Standards Policy (Btu/Btu)
  DFPN::VariableArray{4} = ReadDisk(db,"$Outpt/DFPN") # [Enduse,Tech,EC,Area] Normalized Fuel Price ($/mmBtu)
  DFTC::VariableArray{5} = ReadDisk(db,"$Outpt/DFTC") # [Enduse,Tech,EC,Area,Year] Device Fuel Trade Off Coef. (DLESS)
  DSt::VariableArray{4} = ReadDisk(db,"$Outpt/DSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years)
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  ECUF::VariableArray{3} = ReadDisk(db,"MOutput/ECUF") # [ECC,Area,Year] Capital Utilization Fraction
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  PDif::VariableArray{4} = ReadDisk(db,"$Input/PDif") # [Enduse,Tech,EC,Area] Difference between the Initial Process Efficiency for each Fuel
  PER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  TSLoad::VariableArray{3} = ReadDisk(db,"$Input/TSLoad") # [Enduse,EC,Area] Temp. Sensitive Fraction of Load
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xDEEA::VariableArray{5} = ReadDisk(db,"$Input/xDEEA") # [Enduse,Tech,EC,Area,Year] Historical Average Device Efficiency (Btu/Btu)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xDriver::VariableArray{3} = ReadDisk(db,"MInput/xDriver") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt") # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  xECUF::VariableArray{3} = ReadDisk(db,"MInput/xECUF") # [ECC,Area,Year] Capital Utilization Fraction ($/$)
  xPEEA::VariableArray{5} = ReadDisk(db,"$Input/xPEEA") # [Enduse,Tech,EC,Area,Year] Historical Average Process Efficiency ($/Btu)
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xPEE::VariableArray{5} = ReadDisk(db,"$Input/xPEE") # [Enduse,Tech,EC,Area,Year] Historical Process Efficiency ($/Btu)

  # Scratch Variables
  DEEEst::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Estimated Device Efficiency (Btu/Btu)
  FPCIXDriver::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Driver
  # Factor   'Multiplier between Average and Marginal Process Efficiency (BTu/Btu)'
  Scale::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Scale for Estimated Device Efficiency (Btu/Btu)
  TXPER::VariableArray{4} = zeros(Float32,length(Enduse),length(EC),length(Area),length(Year)) # [Enduse,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  # YrBeforeLast  'Year before Last Historical Year (Year)'
  xDER::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  xFPC::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  xPER::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  xWCUF::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # [EC,Area,Year] Capacity Utilization Factor Weighted by Output
end

function CCalibration(db)
  data = CCalib(; db)
  (;Areas,EC,ECC,ECs,Enduse) = data
  (;Input,Enduses,Nation,Tech,Techs) = data
  (;Years) = data
  (;DDay,DDayNorm,DDCoefficient,DEM,DEStd,DEStdP,DFPN,DFTC) = data
  (;DPL,ECFP,ECUF,Inflation,PDif,TSLoad,xDEE,xDEEA,xDmd) = data
  (;xDriver,xDSt,xECUF,xPEEA,ANMap,xPEE) = data
  (;DEEEst,FPCIXDriver,Scale,TXPER,xDER,xFPC,xPER,xWCUF) = data

  years = collect(Zero:Last)
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, year in years
    @finite_math DEEEst[enduse,tech,ec,area,year] = DEM[enduse,tech,ec,area]/
        (1.0+((ECFP[enduse,tech,ec,area,year]/Inflation[area,year]/
        DFPN[enduse,tech,ec,area])^DFTC[enduse,tech,ec,area,year]))  
  end

  #
  # Scale DEEEst by Input xDEE in initial year (2000)
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    @finite_math Scale[enduse,tech,ec,area] = xDEE[enduse,tech,ec,area,Yr(2000)]/
      DEEEst[enduse,tech,ec,area,Yr(2000)]
  end

  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, year in years
    DEEEst[enduse,tech,ec,area,year] = DEEEst[enduse,tech,ec,area,year]*Scale[enduse,tech,ec,area]
  end

  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas, year in years
    if xDEE[enduse,tech,ec,area,year] == -99
      xDEE[enduse,tech,ec,area,year] = max(DEEEst[enduse,tech,ec,area,year],
        DEStd[enduse,tech,ec,area,year],DEStdP[enduse,tech,ec,area,year] )
    end
  end

  #
  # Average efficiency is smoothed xDEE
  #
  for enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    xDEEA[enduse,tech,ec,area,Zero] = xDEE[enduse,tech,ec,area,Zero]
  end
  years = collect(First:Last)
  for year in years, enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    @finite_math xDEEA[enduse,tech,ec,area,year] = 
      (xDEEA[enduse,tech,ec,area,year-1]*(1-(1/DPL[enduse,tech,ec,area,year])))+
      (xDEE[enduse,tech,ec,area,year]*(1/DPL[enduse,tech,ec,area,year]))
  end

  WriteDisk(db,"$Input/xDEEA",xDEEA)

  for year in Years, ec in ECs, area in Areas
    ecc = Select(ECC,EC[ec])
    @finite_math xWCUF[ec,area,year] = 
      xDriver[ecc,area,year]*ECUF[ecc,area,year]/xDriver[ecc,area,year]
  end

  for year in Years, enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    @finite_math xDER[enduse,tech,ec,area,year] =
      xDmd[enduse,tech,ec,area,year]/xWCUF[ec,area,year]/(TSLoad[enduse,ec,area]*
      ((DDay[enduse,area,year]/DDayNorm[enduse,area])^DDCoefficient[enduse,ec,area,year])+
      (1-TSLoad[enduse,ec,area]))*1000000
  end

  for year in Years, enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    @finite_math xPER[enduse,tech,ec,area,year] = xDER[enduse,tech,ec,area,year]*
                                                  xDEEA[enduse,tech,ec,area,year]
  end

  for year in Years, enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    @finite_math xFPC[enduse,tech,ec,area,year]= xPER[enduse,tech,ec,area,year]/
      xDSt[enduse,ec,area,year]*PDif[enduse,tech,ec,area]
  end

  for year in Years, enduse in Enduses, ec in ECs, area in Areas
    TXPER[enduse,ec,area,year] = sum(xFPC[enduse,tech,ec,area,year] for tech in Techs)
  end

  for year in Years, enduse in Enduses, tech in Techs, ec in ECs, area in Areas
    ecc = Select(ECC,EC[ec])
    @finite_math FPCIXDriver[enduse,tech,ec,area,year] = xDriver[ecc,area,year] / xECUF[ecc,area,year] *
      xFPC[enduse,tech,ec,area,year] / TXPER[enduse,ec,area,year]
    @finite_math xPEEA[enduse,tech,ec,area,year] = FPCIXDriver[enduse,tech,ec,area,year] * xDSt[enduse,ec,area,year] / xPER[enduse,tech,ec,area,year]
  end

  #
  # Use Electric process efficiency for Solar, Heat Pumps and Geothermal
  #
  techs = Select(Tech,["Solar","HeatPump","Geothermal"])
  Electric = Select(Tech, "Electric")
  for year in Years, area in Areas, ec in ECs, tech in techs, enduse in Enduses
    xPEEA[enduse,tech,ec,area,year] = xPEEA[enduse,Electric,ec,area,year]
  end

  WriteDisk(db,"$Input/xPEEA",xPEEA)

  #
  # Canada
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  enduses = Select(Enduse,["Heat","AC"])
  YrBeforeLast=Last-1
  Factor=1.05

  for area in Areas, ec in ECs, tech in Techs, enduse in enduses
    xPEE[enduse,tech,ec,area,Zero] = xPEEA[enduse,tech,ec,area,Zero]*Factor
    xPEE[enduse,tech,ec,area,Last] = xPEEA[enduse,tech,ec,area,Last]*Factor
  end
  
  years = collect(First:YrBeforeLast)
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in enduses
    xPEE[enduse,tech,ec,area,year] = xPEE[enduse,tech,ec,area,year-1]+
    ((xPEE[enduse,tech,ec,area,Last]-xPEE[enduse,tech,ec,area,Zero])/(Last-Zero))
  end
  WriteDisk(db,"$Input/xPEE",xPEE)
end

function CalibrationControl(db)
  @info "Com_HistoricalProcessEfficiency.jl - CalibrationControl"

  CCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
