#
# OG_Resources.jl - Oil and Gas Production and Reserve Data
#
#Select Output OG_Resources.log
#
using EnergyModel

module OG_Resources

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  OGCode::Vector{String} = ReadDisk(db, "MainDB/OGCode")
  OGUnit::SetArray = ReadDisk(db,"MainDB/OGUnitKey")
  OGUnits::Vector{Int} = collect(Select(OGCode))
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
  xPd::VariableArray{2} = ReadDisk(db,"SpInput/xPd") # [OGUnit,Year] Exogenous Production (TBtu/Yr)
  xPdCum::VariableArray{2} = ReadDisk(db,"SpInput/xPdCum") # [OGUnit,Year] Historical Cumulative Production (TBtu)
  xRsUndev::VariableArray{2} = ReadDisk(db,"SpInput/xRsUndev") # [OGUnit,Year] Total Technically Recoverable (TTR) Resources (TBtu)
  xRvUndev::VariableArray{2} = ReadDisk(db,"SpInput/xRvUndev") # [OGUnit,Year] Revisions to Undeveloped Resources (TBtu)
  xPdRate::VariableArray{2} = ReadDisk(db,"SpInput/xPdRate") # [OGUnit,Year] Historical Production Rate (TBtu/Yr/TBtu)
  xRsDev::VariableArray{2} = ReadDisk(db,"SpInput/xRsDev") # [OGUnit,Year] Developed Resources (TBtu)
  xDev::VariableArray{2} = ReadDisk(db,"SpInput/xDev") # [OGUnit,Year] Developed Resources (TBtu/Yr)
  xDevRate::VariableArray{2} = ReadDisk(db,"SpInput/xDevRate") # [OGUnit,Year] Historical Development Rate (TBtu/Yr/TBtu)

  #
  # Scratch Variables
  #
  # ConvMetres    'Conversion from 1000 Cubic Metres to TBtu'
  # FinalMinus1   'Year before Final Year (Year)'
  IAlbHv::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Alberta Heavy Input (1000 Cubic Metres)
  IAlbLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Alberta Light Input (1000 Cubic Metres)
  IArcILt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Arctic Isles Light Input (1000 Cubic Metres)
  IBCLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] British Columbia Light Input (1000 Cubic Metres)
  IEOffLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Eastern Offshore Light Input (1000 Cubic Metres)
  IMTerLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Main. Territory Light Input (1000 Cubic Metres)
  IMacDLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Mac Delta/Beau. Sea Light Input (1000 Cubic Metres)
  IManHv::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Manitoba Heavy Input (1000 Cubic Metres)
  IManLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Manitoba Light Input (1000 Cubic Metres)
  IOECLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Other Eastern Canada Light Input (1000 Cubic Metres)
  IOntLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ontario Light Input (1000 Cubic Metres)
  ISskHv::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Saskatchewan Heavy Input (1000 Cubic Metres)
  ISskLt::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Saskatchewan Light Input (1000 Cubic Metres)
  IUSGasRes::VariableArray{1} = zeros(Float32,length(Year)) # [Year] US Lower 48 Natural Gas Reserves Input (TCF)
  L48PdCum::VariableArray{1} = zeros(Float32,length(Year)) # [Year] US Lower 48 Cumulative Gas Production (TBtu/Yr)
  PdGroup::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Production within a group of OGUnits (TBtu/Yr)
 # YearMax
end

function ProductionRate(data,ogunits)
  (;Year,xPdRate,xRsDev,xPd) = data

  for ogunit in ogunits
    xPdRate[ogunit,1] = 0.00
    for year in 2:length(Year)
      @finite_math xPdRate[ogunit,year] = xPd[ogunit,year]/xRsDev[ogunit,year-1]
    end
  end

end

function SCalibration(db)
  data = SControl(; db)
  (;OGUnits,OGCode,Year,Nation,Years) = data
  (;OGNation,OGProcess,xPd,xPdCum,xRsUndev) = data
  (;xRvUndev,xPdRate,xRsDev,xDev,xDevRate) = data
  (;IAlbHv,IAlbLt,IArcILt,IBCLt,IEOffLt,IMTerLt,IMacDLt,IManHv,IManLt,IOECLt) = data
  (;IOntLt,ISskHv,ISskLt,IUSGasRes,L48PdCum,PdGroup) = data
  
  YearMax = length(Year)
  
  # 
  # Production
  # 
  # Cumulative Production
  # 
  xPdCum .= 0
  for ogunit in OGUnits, year in 2:YearMax
    xPdCum[ogunit,year] = xPdCum[ogunit,year-1] + xPd[ogunit,year]
  end

  for year in Years, ogunit in OGUnits 
    # 
    # TTR - Total technically recoverable (TTR) resources are 
    # oil and gas that we can extract using current technologies, whether
    # or not it makes financial sense to do so.
    # 
    # Initialize to 1000 times cumulative production in 2010
    # PNV (22/5/17): is this supposed to read 2050 or is the line below wrong?
    # 
    xRsUndev[ogunit,year] = xPdCum[ogunit,Yr(2050)]*1000

  end

  # 
  # Plays with no production in 2010
  # 
  ogunits = Select(OGCode,["SK_OS_SAGD_0001","Pac_Gas_0001","NL_HeavyOil_0001"])
  for year in Years, ogunit in ogunits 
    xRsUndev[ogunit,year] = xPdCum[ogunit,Yr(2035)]*1000
  end

  # 
  # AB SAGD
  # 
  ogunit = Select(OGCode,"AB_OS_SAGD_0001")
  for year in Years
    xRsUndev[ogunit,year] = xPdCum[ogunit,Yr(2010)]*1000
  end

  # 
  # AB Oil Sands Mining
  # 
  ogunit = Select(OGCode,"AB_OS_Mining_0001")
  for year in Years
    xRsUndev[ogunit,year] = xPdCum[ogunit,Yr(2010)]*1000
  end

  # * 
  # * US Oil Reserves
  # *
  # * Table 1. Technically recoverable U.S. crude oil resources
  # * as of January 1, 2016 (Billion Barrels) – Reference Case
  # * Region      
  # *                               Proved   Unproved   
  # *                              Reserves  Reserves    TRR
  # * Lower 48 Onshore               28.4      165.7    194.1
  # * Lower 48 Offshore               4.7       49.6     54.4
  # * Alaska (Onshore and Offshore)   2.1       34.0     36.1
  # * Total U.S.                     35.2       249.3   284.6
  # *
  # * TRR is Technically Recoverable Resources
  # *
  # * Cumulative Production in 2016 for US regions:
  # *
  # *                    Cum. Prod.     Total TRR by Region
  # * California            8.51        284.6*0.108 =  30.798
  # * East North Central    1.19        284.6*0.015 =   4.323
  # * East South Central    1.28        284.6*0.016 =   4.618
  # * Middle Atlantic       0.11        284.6*0.001 =   0.398
  # * Mountain              7.58        284.6*0.096 =  27.442
  # * Pacific              14.36        284.6*0.183 =  52.004
  # * South Atlantic        0.24        284.6*0.003 =   0.857
  # * West North Central    4.58        284.6*0.058 =  16.596
  # * West South Central   40.76        284.6*0.518 = 147.564
  # * US Total             78.61        284.6*1.000 = 284.600
  # *

  #
  # This math with TRR ends up with depleted resources. 
  # Treating these OG Units in the same manner we deal with 
  # CN OG Units fixes this problem
  # 

  ogunits = Select(OGCode,["CA_Oil_0001",
                           "ENC_Oil_0001",
                           "ESC_Oil_0001",
                           "MAtl_Oil_0001",
                           "Pac_Oil_0001",
                           "SAtl_Oil_0001",
                           "WNC_Oil_0001",
                           "WSC_Oil_0001"])

  for year in Years, ogunit in ogunits 
    xRsUndev[ogunit,year] = xPdCum[ogunit,Yr(2016)]*1000
  end
  
  ogunit = Select(OGCode,"Mtn_Oil_0001")
  for year in Years
    xRsUndev[ogunit,year] = xPdCum[ogunit,Yr(2010)]*1000
  end  
  
  for ogunit in OGUnits
    xRsUndev[ogunit,1] = xRsUndev[ogunit,2]
  end

  # 
  # Revisions to Total technically recoverable (TTR) resources
  # 
  xRvUndev .= 0.0

  # * AEO 2019 shows an increase in production after 2040, so let's assume
  # * it is due to extra resources being discovered - Jeff Amlin 04/29/19
  # * Now with data to 2050 this double counts - Peter Volkmar 10/07/22
  # * Select OGUnit*
  # * Select OGUnit If (OGCode eq "CA_Oil_0001") or (OGCode eq "ENC_Oil_001") or,
  # *                  (OGCode eq "ESC_Oil_0001") or (OGCode eq "MAtl_Oil_001") or,
  # *                  (OGCode eq "Mtn_Oil_0001") or (OGCode eq "Pac_Oil_001") or,
  # *                  (OGCode eq "SAtl_Oil_0001") or (OGCode eq "WNC_Oil_001") or,
  # *                  (OGCode eq "WSC_Oil_0001")
  # * Do If (OGCode eq "CA_Oil_0001") or (OGCode eq "ENC_Oil_001") or,
  # *                  (OGCode eq "ESC_Oil_0001") or (OGCode eq "MAtl_Oil_001") or,
  # *                  (OGCode eq "Mtn_Oil_0001") or (OGCode eq "Pac_Oil_001") or,
  # *                  (OGCode eq "SAtl_Oil_0001") or (OGCode eq "WNC_Oil_001") or,
  # *                  (OGCode eq "WSC_Oil_0001")
  # *   Select Year(2041-2050)
  # *   xRvUndev(OGUnit,Y)=xRsUndev(OGUnit,2040)*0.040
  # *   Select Year*
  # * End Do If OGCode
  # * Select OGUnit*
  
  # 
  # Production Rate and Developed Resources
  # 
  # Units where Developed Resources are Unknown and Production Rate well behaved
  # 
  for year in Years, ogunit in OGUnits 
    xPdRate[ogunit,year] = 0.080
  end

  # 
  # SK Light Oil has steep declines in production - Jeff Amlin 11/04/21
  # 
  ogunits = Select(OGCode,["SK_LightOil_0001","BC_LightOil_0001"])
  for year in Years, ogunit in ogunits 
    xPdRate[ogunit,year] = 0.12
  end

  # 
  # Oil Sands InSitu and Mining have minimal depletion curves - Jeff Amlin 11/04/21
  # 
  ogunits = Select(OGCode,["AB_OS_SAGD_0001","AB_OS_Primary_0001","AB_OS_CSS_0001","AB_OS_Mining_0001"])
  for year in Years, ogunit in ogunits 
    xPdRate[ogunit,year] = 0.02
  end

  ogunits = Select(OGProcess[OGUnits], ==("OilSandsUpgraders"))
  for year in Years, ogunit in ogunits 
    xPdRate[ogunit,year] = 0.012
  end

  # 
  # Processes which do not deplete - Jeff Amlin 04/29/23
  # LNG doesn't have depletion - Peter Volkmar 10/06/22
  # 
  ogunits = Select(OGProcess[OGUnits], ==("LNGProduction"))
  for year in Years, ogunit in ogunits 
    xPdRate[ogunit,year] = 1
  end

  FinalMinus1 = Final-1
  years = collect(Zero:FinalMinus1)
  for year in years, ogunit in OGUnits 
    @finite_math xRsDev[ogunit,year] = xPd[ogunit,year+1]/xPdRate[ogunit,year+1]
  end
  for year in years, ogunit in OGUnits   
    xRsDev[ogunit,Final] = xRsDev[ogunit,FinalMinus1]
  end

  # 
  # Units where Developed Resources are Known
  # 
  # Convert from 1000 Cubic Metres to TBtu
  # using 158.9873 litres/bbl, 5.8e6 Btu/bbl.
  # 
  ConvMetres = 36.4809
  # 
  # 42 gal/bbl
  # 149,793 Btu/gal
  # 6.28981 bbl/Cubic Meter
  # 0.0395711 = 42*149,793*6.28981*1,000/1,000,000,000,000
  ConvMetres = 0.0395711

  # 
  # Read in CAPP Reserve values from "O&G Reserves-CAPP.xls"
  # C:\2020 Documents\Oil and Gas Production\2012\NRCan\O&G Reserves-CAPP.xls
  # 

  yrs = Yr(1985):Yr(2010)
  #               1985      1986      1987      1988      1989      1990      1991      1992      1993      1994      1995      1996      1997      1998      1999      2000      2001      2002      2003      2004      2005      2006      2007      2008      2009      2010
  IMTerLt[yrs] = [35000,    34600,    35030,    35030,    35030,    35030,    37500,    37500,    37500,    37500,    38881,    38628,    38628,    38628,    40987,    42533,    42533,    42533,    42533,    42853,    42853,    43003,    43003,    43003,    43003,    52900]
  IMacDLt[yrs] = [0,        65000,    65000,    65000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000,    54000]
  IArcILt[yrs] = [100,      100,      200,      300,      300,      300,      300,      350,      500,      500,      575,      463,      463,      463,      463,      463,      463,      463,      463,      463,      463,      463,      463,      463,      463,      463]
  IBCLt[yrs]   = [83347,    83195,    83845,    86687,    89257,    90303,    92363,    94662,    96273,    100088,   103957,   105600,   109666,   117289,   119891,   123020,   122575,   122309,   126228,   126882,   127797,   126382,   126533,   127439,   130153,   131840]
  IAlbLt[yrs]  = [1990812,  2021634,  2065908,  2090609,  2105233,  2094906,  2087660,  2090496,  2119501,  2137185,  2162425,  2171818,  2192148,  2215899,  2242056,  2259408,  2260448,  2277425,  2285989,  2307138,  2327449,  2337406,  2354505,  2375260,  2384242,  2450300]
  IAlbHv[yrs]  = [131656,   136696,   147172,   159089,   170068,   181154,   199584,   212484,   220654,   234258,   249643,   281783,   294895,   311009,   319065,   332877,   355479,   367485,   372919,   384986,   392115,   407461,   415994,   417613,   419724,   379400]
  ISskLt[yrs]  = [358146,   354738,   364822,   379441,   385586,   397136,   401544,   413356,   429576,   443333,   463806,   484968,   506663,   519182,   515550,   539245,   555973,   562215,   568908,   581627,   596133,   598614,   618350,   632970,   625207,   623174]
  ISskHv[yrs]  = [83632,    85104,    86263,    92100,    94913,    99048,    100000,   114494,   123441,   130988,   142539,   151890,   170426,   188215,   203036,   215867,   226521,   245407,   262129,   277075,   296686,   300135,   316824,   332344,   326403,   330871]
  IManLt[yrs]  = [34498,    35119,    35830,    34914,    35112,    35837,    36079,    36079,    36087,    36673,    37173,    37295,    37671,    37303,    37595,    38155,    38155,    38155,    40489,    40723,    41560,    45788,    47056,    50502,    51171,    52532]
  IManHv[yrs]  = [0,        261,      275,      295,      355,      357,      357,      357,      367,      367,      319,      324,      338,      362,      389,      592,      592,      592,      447,      0,        0,        0,        0,        0,        0,        0]
  IOntLt[yrs]  = [10257,    10261,    10284,    10998,    11268,    11606,    11742,    11867,    12065,    13200,    13377,    13601,    13683,    14079,    14249,    14602,    14920,    15082,    15162,    15232,    15288,    15490,    15546,    15596,    15656,    15000]
  IOECLt[yrs]  = [129,      129,      129,      133,      133,      133,      133,      133,      133,      133,      133,      133,      128,      128,      128,      128,      128,      128,      128,      128,      128,      128,      128,      128,      128,      128]
  IEOffLt[yrs] = [83000,    83000,    83000,    133000,   138600,   138600,   138600,   138600,   138600,   138600,   139980,   139980,   155250,   155250,   154846,   184866,   184866,   184866,   191197,   226947,   378818,   378818,   409564,   398204,   394013,   336000]


  #
  # Map units for which a CAPP provides reserve values.
  # 
  ogunit = Select(OGCode,"NT_FrontierOil_0001")
  for year in Years
    xRsDev[ogunit,year] = (IMTerLt[year]+IMacDLt[year]+IArcILt[year])*ConvMetres
  end

  years = collect(Yr(2011):YearMax)
  for year in years
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]
  end
  ProductionRate(data,ogunit)

  # 
  # Other East Coast Offshore - where CAPP values are from several of our units.
  # 
  ogunits = Select(OGCode,["NL_FrontierOil_0001","NS_LightOil_0001"])
  for year in Years
    PdGroup[year]= sum(xPdCum[og,Yr(2035)] for og in ogunits)
  end
  for year in Years, ogunit in ogunits
    @finite_math xRsDev[ogunit,year] =
      IEOffLt[year]*xPdCum[ogunit,Yr(2035)]/PdGroup[year]*ConvMetres
  end

  for ogunit in ogunits, year in Yr(2011):YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]
  end
  ProductionRate(data,ogunits)

  # 
  # US Natural Gas Reserves
  # 
  IUSGasRes[Yr(2009):Yr(2040)] = [263.40, 294.02, 324.64, 320.09, 329.08, 332.50, 336.97, 341.77, 344.49, 346.09, 348.56, 352.47, 354.56, 357.99, 362.20, 365.10, 368.52, 372.40, 375.40, 378.44, 380.63, 382.58, 385.16, 387.53, 389.62, 391.86, 393.60, 394.69, 397.47, 399.56, 401.61, 402.59]

  # 
  # Apportion Lower 48 Reserves between units
  # 
  US = Select(Nation,"US")
  ogunits = findall(OGNation[OGUnits] .== "US")
  for year in Years
    L48PdCum[year] = sum(xPdCum[og,year] for og in ogunits)
  end
  for ogunit in ogunits
    for year in Yr(1985):Yr(2010)
      xRsDev[ogunit,year] = xRsDev[ogunit,Yr(2010)]
    end
    for year in Yr(2010):Yr(2040)
      @finite_math xRsDev[ogunit,year] = IUSGasRes[year]*1028*xPdCum[ogunit,year]/L48PdCum[year]
    end
    for year in Yr(2041):YearMax
      xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*1.01     
    end
  end
  ProductionRate(data,ogunits)

  # * Cumulative Production in 2016 is 78.61 
  # *
  # *                  Dev Reserves   Cum.Prod.
  # * California            3.81            8.51 
  # * East North Central    0.53            1.19 
  # * East South Central    0.57            1.28 
  # * Middle Atlantic       0.05            0.11 
  # * Mountain              3.39            7.58
  # * Pacific               6.43           14.36 
  # * South Atlantic        0.11            0.24 
  # * West North Central    2.05            4.58 
  # * West South Central   18.25           40.76 
  # * US Total             35.20           78.61 
  # *
  # *Select OGUnit(US_Oil_0001)
  # *xRsDev(U,Y)=xPdCum(U,Y)*35.2/74.3*1.039
  # *Select Year(Future-YearMax)
  # *xRsDev(U,Y)=xRsDev(U,Y-1)*(1+0.005)
  # *Select Year*
  # *ProductionRate
  # *Select OGUnit*

  ogunit = Select(OGCode,"CA_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*3.81/8.51*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)
  
  ogunit = Select(OGCode,"ENC_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*0.53/1.19*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)
  
  ogunit = Select(OGCode,"ESC_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*0.57/1.28*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)
  
  ogunit = Select(OGCode,"MAtl_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*0.05/0.11*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)
  
  ogunit = Select(OGCode,"Mtn_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*3.39/7.58*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)
  
  ogunit = Select(OGCode,"SAtl_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*0.11/0.24*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)
  
  ogunit = Select(OGCode,"WNC_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*2.05/4.58*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)
  
  ogunit = Select(OGCode,"WSC_Oil_0001")
  for year in Years
    xRsDev[ogunit,year] = xPdCum[ogunit,year]*18.25/40.76*1.039
  end
  for year in Future:YearMax
    xRsDev[ogunit,year] = xRsDev[ogunit,year-1]*(1+0.005)
  end
  ProductionRate(data,ogunit)

  # 
  # Resource Developments
  # 
  for ogunit in OGUnits
    xDev[ogunit,1] = 0.00
  end
  
  years = collect(2:YearMax)
  for year in years,ogunit in OGUnits
      xDev[ogunit,year] = xRsDev[ogunit,year]-xRsDev[ogunit,year-1]+xPd[ogunit,year]
  end
  
  ogunits = findall(OGProcess[OGUnits] .== "LNGProduction")
  for year in years, ogunit in ogunits
    xDev[ogunit,year] = xRsDev[ogunit,year]-xRsDev[ogunit,year-1]
  end

  # 
  # Development Rate
  # 
  for ogunit in OGUnits
    xDevRate[ogunit,1] = 0.00
    for year in 2:YearMax
      @finite_math xDevRate[ogunit,year] = xDev[ogunit,year]/xRsUndev[ogunit,year-1]
      xRsUndev[ogunit,year] = xRsUndev[ogunit,year-1]-xDev[ogunit,year]
    end
  end

  WriteDisk(db,"SpInput/xPdCum",xPdCum)
  WriteDisk(db,"SpInput/xPdRate",xPdRate)
  WriteDisk(db,"SpInput/xRsDev",xRsDev)
  WriteDisk(db,"SpInput/xDev",xDev)
  WriteDisk(db,"SpInput/xDevRate",xDevRate)
  WriteDisk(db,"SpInput/xRsUndev",xRsUndev)

end

function CalibrationControl(db)
  @info "OG_Resources.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
