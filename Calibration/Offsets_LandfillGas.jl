#
# Offsets_LandfillGas.jl
#
using EnergyModel

module Offsets_LandfillGas

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Offset::SetArray = ReadDisk(db,"MainDB/OffsetKey")
  OffsetDS::SetArray = ReadDisk(db,"MainDB/OffsetDS")
  Offsets::Vector{Int} = collect(Select(Offset))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  ReA0::VariableArray{2} = ReadDisk(db,"MEInput/ReA0") # [Offset,Area] A Term in Reduction Curve ($/Tonne)
  ReB0::VariableArray{2} = ReadDisk(db,"MEInput/ReB0") # [Offset,Area] B Term in Reduction Curve ($/Tonne)
  ReC0::VariableArray{3} = ReadDisk(db,"MEInput/ReC0") # [Offset,Area,Year] C Term in Reduction Curve (Tonnes/Yr)
  ReC2H6PerCH4::VariableArray{3} = ReadDisk(db,"MEInput/ReC2H6PerCH4") # [Offset,Area,Year] Flaring C2H6 Captured per CH4 Captured (Tonnes/Tonne CH4)
  ReCapturedFraction::VariableArray{4} = ReadDisk(db,"MEInput/ReCapturedFraction") # [Offset,Poll,Area,Year] Reductions Captured Fraction (Tonnes/Yr)
  ReCCA0::VariableArray{2} = ReadDisk(db,"MEInput/ReCCA0") # [Offset,Area] A Term in Reduction Capital Cost Curve ($/$)
  ReCCB0::VariableArray{2} = ReadDisk(db,"MEInput/ReCCB0") # [Offset,Area] B Term in Reduction Capital Cost Curve ($/$)
  ReCCC0::VariableArray{3} = ReadDisk(db,"MEInput/ReCCC0") # [Offset,Area,Year] C Term in Reduction Capital Cost Curve ($/$)
  ReCCReplace::VariableArray{3} = ReadDisk(db,"MEInput/ReCCReplace") # [Offset,Area,Year] Reduction Replacement Capital Cost ($/Tonne CH4)
  ReCCSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReCCSwitch") # [Offset,Area,Year] Reduction Capital Cost Switch (1=Default)
  ReCD::VariableArray{1} = ReadDisk(db,"MEInput/ReCD") # [Offset] Reduction Construction Time (Years)
  ReCDOrder::VariableArray{2} = ReadDisk(db,"MEInput/ReCDOrder") # [Offset,Year] Number of Levels Reduction Construction Delay (Number)
  ReDevelopedFraction::VariableArray{3} = ReadDisk(db,"MEInput/ReDevelopedFraction") # [Offset,Area,Year] Fraction of Captured Gas Developed into Electric Generating Capacity (MW/MW)
  ReECC::SetArray = ReadDisk(db,"MEInput/ReECC") # [Offset] Reduction Economic Sector (Name)
  ReElectricPotentialFactor::VariableArray{3} = ReadDisk(db,"MEInput/ReElectricPotentialFactor") # [Offset,Area,Year] Electric Generating Capacity Potential from Captured Gas Factor (MW/MT)
  ReGFr::VariableArray{3} = ReadDisk(db,"MEInput/ReGFr") # [Offset,Area,Year] Reduction Grant Fraction ($/$)
  ReInvSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReInvSwitch") # [Offset,Area,Year] Reduction Investment Switch (1=Default)
  ReIVTC::VariableArray{3} = ReadDisk(db,"MEInput/ReIVTC") # [Offset,Area,Year] Reduction Investment Tax Credit ($/$)
  ReOCF::VariableArray{3} = ReadDisk(db,"MEInput/ReOCF") # [Offset,Area,Year] Reduction Operating Cost Factor ($/$)
  ReOMExpSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReOMExpSwitch") # [Offset,Area,Year] Reduction O&M Expenses Switch (1=Default)
  RePL::VariableArray{3} = ReadDisk(db,"MEInput/RePL") # [Offset,Area,Year] Reduction Physical Lifetime (Years)
  RePOCF::VariableArray{4} = ReadDisk(db,"MEInput/RePOCF") # [Offset,Poll,Area,Year] Reduction Factor (Tonnes/Tonnes)
  RePollutant::SetArray = ReadDisk(db,"MEInput/RePollutant") # [Offset] Reduction Main Pollutant (Name)
  RePriceSwitch::VariableArray{3} = ReadDisk(db,"MEInput/RePriceSwitch") # [Offset,Area,Year] Reduction Emission Price Switch (1=Default)
  RePriceX::VariableArray{3} = ReadDisk(db,"MEInput/RePriceX") # [Offset,Area,Year] Emission Exogenous Prices ($/Tonne)
  ReReductionsSwitch::VariableArray{3} = ReadDisk(db,"MEInput/ReReductionsSwitch") # [Offset,Area,Year] Reductions Switch (1=Default)
  ReReductionsX::VariableArray{3} = ReadDisk(db,"MEInput/ReReductionsX") # [Offset,Area,Year] Reductions Exogenous (Tonnes/Yr)
  ReROIN::VariableArray{3} = ReadDisk(db,"MEInput/ReROIN") # [Offset,Area,Year] Reduction Return on Investment ($/$)
  ReTL::VariableArray{3} = ReadDisk(db,"MEInput/ReTL") # [Offset,Area,Year] Reduction Tax Lifetime (Years)
  ReTxRt::VariableArray{3} = ReadDisk(db,"MEInput/ReTxRt") # [Offset,Area,Year] Reduction Tax Rate ($/$)
  ReType::SetArray = ReadDisk(db,"MEInput/ReType") # [Offset] Reduction Type (Name)

  # Scratch Variables
end

function OffsetData(db)
  data = MControl(; db)
  (;Area,Nation,Offset,Poll) = data
  (;Years) = data
  (;ANMap,PolConv,ReA0,ReB0,ReC0,ReC2H6PerCH4,ReCapturedFraction,ReCCA0,ReCCB0,ReCCC0) = data
  (;ReCCReplace,ReCCSwitch,ReCD,ReCDOrder,ReDevelopedFraction,ReECC,ReElectricPotentialFactor,ReGFr,ReInvSwitch,ReIVTC) = data
  (;ReOCF,ReOMExpSwitch,RePL,RePOCF,RePollutant,RePriceSwitch,RePriceX,ReReductionsSwitch,ReReductionsX,ReROIN) = data
  (;ReTL,ReTxRt,ReType) = data


  offset = Select(Offset,"LFG")
  CO2 = Select(Poll,"CO2")
  CH4 = Select(Poll,"CH4")  

  AB = Select(Area,"AB")
  BC = Select(Area,"BC")
  MB = Select(Area,"MB")
  NB = Select(Area,"NB")
  NL = Select(Area,"NL")
  NS = Select(Area,"NS")
  ON = Select(Area,"ON")
  QC = Select(Area,"QC")
  SK = Select(Area,"SK")
  NT = Select(Area,"NT")
  PE = Select(Area,"PE")
  NU = Select(Area,"NU")
  YT = Select(Area,"YT")
  
  #
  # "Landfill Gas Cost Curve v1_Export.xlsx" R. Levesque 4/21/14
  #
  # Analysis on LFG offsets in the context of the WCI indicate that 
  # there is about 100 kt in CO2 eq of potential in QC. See the study 
  # "Etude d impact economique du projet de reglement modifiant le reglement
  # concernant le systeme de plafonnement et d echange de droits d emission 
  # de gaz a effet de serre" by Quebec and the presentation "Quebec Offset
  # System" for more information. (Maxime C., 2016-01-26)
  #
  year = Yr(2014)
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  poll = Select(Poll,"CH4")
  
  for area in areas
    ReA0[offset,area] = 39.1159
  end
  
  for area in areas
    ReB0[offset,area] = -2.0209
  end

  areas = Select(Area,["NL","PE","NS","NB","QC","ON","MB","SK","AB","BC","YT","NT","NU"])
  ReC0[offset,NL,year] = 7.1367 *1000
  ReC0[offset,PE,year] = 0.0000 *1000
  ReC0[offset,NS,year] = 0.6595 *1000
  ReC0[offset,NB,year] = 20.476 *1000
  ReC0[offset,QC,year] = 4.0000 *1000
  ReC0[offset,ON,year] = 0.0000 *1000
  ReC0[offset,MB,year] = 22.070 *1000
  ReC0[offset,SK,year] = 18.050 *1000
  ReC0[offset,AB,year] = 47.091 *1000
  ReC0[offset,BC,year] = 0.0000 *1000
  ReC0[offset,YT,year] = 0.0000 *1000
  ReC0[offset,NT,year] = 0.0000 *1000
  ReC0[offset,NU,year] = 0.0000 *1000 

  #
  # Set future values
  #
  years = collect(Yr(2015):Final)
  for year in years, area in areas
    ReC0[offset,area,year] = ReC0[offset,area,year-1]
  end
  
  WriteDisk(db,"MEInput/ReA0",ReA0)
  WriteDisk(db,"MEInput/ReB0",ReB0)
  WriteDisk(db,"MEInput/ReC0",ReC0)

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  
  #
  ########################
  #

  for year in Years, area in areas
    ReC2H6PerCH4[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/ReC2H6PerCH4",ReC2H6PerCH4)

  for year in Years, area in areas
    ReCapturedFraction[offset,poll,area,year] = 1.00
  end
  WriteDisk(db,"MEInput/ReCapturedFraction",ReCapturedFraction)

  for year in Years, area in areas
    ReCCA0[offset,area] = 0
  end
  for year in Years, area in areas  
    ReCCB0[offset,area] = 0
  end
  for year in Years, area in areas
    ReCCC0[offset,area,year] = 0
  end
  WriteDisk(db,"MEInput/ReCCA0",ReCCA0)
  WriteDisk(db,"MEInput/ReCCB0",ReCCB0)
  WriteDisk(db,"MEInput/ReCCC0",ReCCC0)

  for year in Years, area in areas
    ReCCReplace[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/ReCCReplace",ReCCReplace)

  for year in Years, area in areas
    ReCCSwitch[offset,area,year] = 1.0
  end
  WriteDisk(db,"MEInput/ReCCSwitch",ReCCSwitch)

  ReCD[offset] = 3
  WriteDisk(db,"MEInput/ReCD",ReCD)

  for year in Years
    ReCDOrder[offset,year] = 2
  end
  WriteDisk(db,"MEInput/ReCDOrder",ReCDOrder)

  #
  # From "Site Fact Sheet JSA.xls"
  #
  years = collect(Yr(2012):Final)
  for year in years, area in areas
    ReDevelopedFraction[offset,area,year] = 0.54
  end
  
  #
  # Set endogenous building of LFG to 0.0 prior to 2012
  # to avoid double-counting on top of exogenous reductions
  #
  years = collect(Yr(2007):Yr(2011))
  for year in years, area in areas
    ReDevelopedFraction[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/ReDevelopedFraction",ReDevelopedFraction)

  ReECC[offset] = "SolidWaste"
  WriteDisk(db,"MEInput/ReECC",ReECC)
  
  #
  # Source: Strategic Assessment Of The Additional Potential For
  # Landfill Gas Recovery And Utilization In Canada, Prepared For:
  # Environment Canada, 37408, Ref. no. 19799 (1), by Conestoga Rovers
  # & Associates (CRA), see "Landfill Gas Generation.xls" - 1231 MW/tonne
  # Revised based on "Site Fact Sheet JSA.xls" with an average
  # of 24.16 MW/tonne
  #
  for year in Years, area in areas
    ReElectricPotentialFactor[offset,area,year] = 24.16
  end
  WriteDisk(db,"MEInput/ReElectricPotentialFactor",ReElectricPotentialFactor)

  for year in Years, area in areas
    ReGFr[offset,area,year] = 0
  end
  WriteDisk(db,"MEInput/ReGFr",ReGFr)

  for year in Years, area in areas
    ReInvSwitch[offset,area,year] = 1.0
  end
  WriteDisk(db,"MEInput/ReInvSwitch",ReInvSwitch)

  for year in Years, area in areas
    ReIVTC[offset,area,year] = 0.00
  end
  WriteDisk(db,"MEInput/ReIVTC",ReIVTC)
  
  #
  # Source: LFG_Province.doc - RBL 01/04/02
  #
  for year in Years, area in areas
    ReOCF[offset,area,year] = 0.06
  end
  WriteDisk(db,"MEInput/ReOCF",ReOCF)

  for year in Years, area in areas
    ReOMExpSwitch[offset,area,year] = 1
  end
  WriteDisk(db,"MEInput/ReOMExpSwitch",ReOMExpSwitch)

  #
  # Set to 100 years to minimize retirements - Jeff Amlin 11/14/13
  #
  for year in Years, area in areas
    RePL[offset,area,year] = 100
  end
  WriteDisk(db,"MEInput/RePL",RePL)
  
  #
  # From G. Backus "Jay Barclay has checked on the accounting for the
  # production of CO2 from the burning of CH4 in the landfills. He finds
  # the rules say that it does not have to be counted.  This means you
  # need to now set RePOCF(CO2)=0 and RePOCF(CH4)=-1 (to have us
  # reduce the real MT of CH4 for every CO2e MT reduced but add no new
  # real CO2)" 1/31/2002
  #
  for year in Years, area in areas
    RePOCF[offset,CH4,area,year] = 1.0
    RePOCF[offset,CO2,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/RePOCF",RePOCF)

  RePollutant[offset] = "CH4"
  WriteDisk(db,"MEInput/RePollutant",RePollutant)

  for year in Years, area in areas
    RePriceSwitch[offset,area,year] = 1
  end
  for year in Years
    RePriceSwitch[offset,AB,year] = 2
  end
  WriteDisk(db,"MEInput/RePriceSwitch",RePriceSwitch)

  for year in Years, area in areas
    RePriceX[offset,area,year] = 0.0
  end
  WriteDisk(db,"MEInput/RePriceX",RePriceX)

  for year in Years, area in areas
    ReReductionsSwitch[offset,area,year] = 1
  end
  WriteDisk(db,"MEInput/ReReductionsSwitch",ReReductionsSwitch)
  
  #
  # Ontario - Milica email 6/19/12 - "Landfill Provincial Policies.xlsx"
  # - see also "LFG Policy - June 19 2012.xlsx"
  #
  # Adjusted ReReductionsX numerators by a factor of 1.2 to account for the 
  # updated GWP for methane. (John S.O., 2016-08-23)
  #
  area = Select(Area,"ON") 
  ReReductionsX[offset,area,Yr(2014)] =  2.04 * 1e6/PolConv[CH4]
  ReReductionsX[offset,area,Yr(2020)] =  2.52 * 1e6/PolConv[CH4]
  years = collect(Yr(2015):Yr(2019))
  for year in years
    ReReductionsX[offset,area,year] = ReReductionsX[offset,area,year-1]+
    (ReReductionsX[offset,area,Yr(2020)]-ReReductionsX[offset,area,Yr(2014)])/(2020-2014)
  end
  years = collect(Yr(2021):Final)  
  for year in years
    ReReductionsX[offset,area,year] = ReReductionsX[offset,area,Yr(2020)]
  end

  #
  # Quebec - Milica email 6/19/12 - "Landfill Provincial Policies.xlsx"
  # - see also "LFG Policy - June 19 2012.xlsx"
  # Reductions based on www.mddep.gouv.qc.ca/changements/plan_action/2006-2012_en.pdf 
  # The document notes that landfill measures 13 and 14 will reduce GHG emissions 
  # by 500 kt and 3 700 kt (CO2e). We assume that these reductions will continue 
  # over time and divide them over the six years of the plan.
  #
  area = Select(Area,"QC")
  years = collect(Yr(2012):Final)
  for year in years
    ReReductionsX[offset,area,year] =  0.84 * 1e6/PolConv[CH4]
  end
  #
  # BC - Milica email 6/19/12 - "Landfill Provincial Policies.xlsx"
  # - see also "LFG Policy - June 19 2012.xlsx"
  #
  area = Select(Area,"BC")
  ReReductionsX[offset,area,Yr(2015)] =  2.04 * 1e6/PolConv[CH4]
  ReReductionsX[offset,area,Yr(2020)] =  2.52 * 1e6/PolConv[CH4]
  years = collect(Yr(2016):Yr(2019))
  for year in years
    ReReductionsX[offset,area,year] = ReReductionsX[offset,area,year-1]+
      (ReReductionsX[offset,area,Yr(2020)]-ReReductionsX[offset,area,Yr(2015)])/(2020-2015)
  end
  years = collect(Yr(2021):Final)
  for year in years  
    ReReductionsX[offset,area,year] = ReReductionsX[offset,area,Yr(2020)]
  end

  #
  # NL - Robin email 08/07/13 - "NL Landfill Provincial Policies.xlsx"
  # NL - changed to 2013 start year, 14.08.08 - Hilary Paulin
  # - see also "LFG Policy - June 19 2012.xlsx"
  # Removed per Glasha email - Jeff Amlin 9/17/15
  #
  #Select Area(NL)
  #Select Year(2013-Final)
  #ReReductionsX[offset,area,year] =  0.072   # 1e6/PolConv[CH4]
  #Select Area*, Year*
  
  #
  # Alberta - Email from Glasha, source Kerri Henry 4/29/14.
  # Clover Bar Landfill (2005):  http://www.csaregistries.ca/files/projects/prj_6807_771.pdf
  # Sheperd Landfill (2006):  http://www.csaregistries.ca/files/projects/prj_1334_1090.pdf
  #
  area = Select(Area,"AB")
  ReReductionsX[offset,area,Yr(2005)] =  69600/PolConv[CH4]
  ReReductionsX[offset,area,Yr(2006)] =  1.2 * (58000+101000)/PolConv[CH4]
  years = collect(Yr(2007):Final)
  for year in years 
    ReReductionsX[offset,area,year] = ReReductionsX[offset,area,Yr(2006)]
  end
  WriteDisk(db,"MEInput/ReReductionsX",ReReductionsX)

  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  for year in Years, area in areas
    ReROIN[offset,area,year] = 0.15
  end
  WriteDisk(db,"MEInput/ReROIN",ReROIN)

  for year in Years, area in areas
    ReTL[offset,area,year] = RePL[offset,area,year]*0.80
  end
  WriteDisk(db,"MEInput/ReTL",ReTL)

  for year in Years, area in areas
    ReTxRt[offset,area,year] = 0.35
  end
  WriteDisk(db,"MEInput/ReTxRt",ReTxRt)

  ReType[offset] = "Process"
  WriteDisk(db,"MEInput/ReType",ReType)

end

function Control(db)
  @info "Offsets_LandfillGas.jl - Control"
  OffsetData(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
