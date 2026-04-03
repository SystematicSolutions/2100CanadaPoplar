#
# GHG_MacroEconomy_CA.jl
#
using EnergyModel

module GHG_MacroEconomy_CA

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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  MEDriver::VariableArray{3} = ReadDisk(db,"MOutput/MEDriver") # [ECC,Area,Year] Driver for Process Emissions (Various Millions/Yr)
  MEPOCX::VariableArray{4} = ReadDisk(db,"MEInput/MEPOCX") # [ECC,Poll,Area,Year] Process Pollution Coefficient (Tonnes/$B-Output)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)
  xMEPol::VariableArray{4} = ReadDisk(db,"SInput/xMEPol") # [ECC,Poll,Area,Year] Process Pollution (Tonnes/Yr)
end

function MCalibration(db)
  data = MControl(; db)
  (;Area,ECC,ECCs,Poll,Polls,Years) = data
  (;MEDriver,MEPOCX,PolConv,xMEPol) = data

  CA = Select(Area,"CA")
  MEPOCX[ECCs,Polls,CA,Years] .= 0
  xMEPol[ECCs,Polls,CA,Years] .= 0

  # 
  # CO2 Process Emissions.  All emissions read in as MT eCO2
  # source: "California Emissions All Fuels v160108.xlsx" - Luke Davulis 1/8/16
  # 
  CO2 = Select(Poll,"CO2")
  eccs = Select(ECC,["Petroleum","Cement","IronSteel","OtherManufacturing","CropProduction"])

  #                   ECC                 Poll                            2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[Select(ECC,"Petroleum"),         CO2,CA,Yr(2000):Yr(2013)] .= [3.6442,  3.6903,  3.7354,  3.6813,  3.6543,  3.6960,  3.9448,  4.0278,  4.0228,  3.6026,  3.7542,  7.0059,  6.8605,  5.9582]
  xMEPol[Select(ECC,"Cement"),            CO2,CA,Yr(2000):Yr(2013)] .= [5.5052,  5.5850,  5.6597,  5.7425,  5.8442,  5.9239,  5.8633,  5.6062,  5.3288,  3.6302,  3.4900,  4.1149,  4.6925,  4.9687]
  xMEPol[Select(ECC,"IronSteel"),         CO2,CA,Yr(2000):Yr(2013)] .= [0.0716,  0.0682,  0.0681,  0.0700,  0.0667,  0.0673,  0.0680,  0.0682,  0.0663,  0.0635,  0.0654,  0.0665,  0.0600,  0.0658]
  xMEPol[Select(ECC,"OtherManufacturing"),CO2,CA,Yr(2000):Yr(2013)] .= [2.7234,  2.4260,  2.3700,  2.3002,  2.2395,  2.2568,  2.3103,  2.3448,  2.2382,  2.0523,  2.1015,  1.9755,  1.8912,  1.8825]
  xMEPol[Select(ECC,"CropProduction"),    CO2,CA,Yr(2000):Yr(2013)] .= [0.2655,  0.1627,  0.2333,  0.2387,  0.2355,  0.2980,  0.4846,  0.2565,  0.1708,  0.1698,  0.1775,  0.1721,  0.2290,  0.1892]
      
  for ecc in eccs
    for year in Yr(2000):Yr(2013)
      # 
      # Convert from MT eCO2 to Tonnes CO2
      # 
      @finite_math xMEPol[ecc,CO2,CA,year] = xMEPol[ecc,CO2,CA,year]*1E6/PolConv[CO2]

      # 
      # Emission Coefficient (Tonnes/Driver)
      # 
      @finite_math MEPOCX[ecc,CO2,CA,year] = xMEPol[ecc,CO2,CA,year]/MEDriver[ecc,CA,year]
    end

    for year in Yr(1985):Yr(1999)
      MEPOCX[ecc,CO2,CA,year] = MEPOCX[ecc,CO2,CA,Yr(2000)]
    end

    for year in Yr(2014):Final
      MEPOCX[ecc,CO2,CA,year] = MEPOCX[ecc,CO2,CA,Yr(2013)]
    end
  end

  # 
  # N2O Process Emissions
  # source: "California Emissions All Fuels.xlsx" - Luke Davulis 1/6/16
  # 
  N2O = Select(Poll,"N2O")
  eccs = Select(ECC,["Petrochemicals","AnimalProduction","CropProduction","LandUse","Wastewater"])

  #                   ECC               Poll                            2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[Select(ECC,"Petrochemicals"),  N2O,CA,Yr(2000):Yr(2013)] .= [0.0485,  0.0485,  0.0485,  0.0485,  0.0485,  0.0485,  0.0485,  0.0485,  0.0485,  0.0485,  0.0485,  0.0481,  0.0489,  0.0503]
  xMEPol[Select(ECC,"AnimalProduction"),N2O,CA,Yr(2000):Yr(2013)] .= [1.3745,  1.4203,  1.4869,  1.5337,  1.4483,  1.5021,  1.5595,  1.5538,  1.5231,  1.4996,  1.4545,  1.4617,  1.5293,  1.5293]
  xMEPol[Select(ECC,"CropProduction"),  N2O,CA,Yr(2000):Yr(2013)] .= [7.0019,  6.9517,  7.0846,  7.1252,  7.0772,  7.0397,  6.9719,  6.9314,  7.0177,  6.7803,  6.7994,  7.0415,  7.0855,  6.8813]
  xMEPol[Select(ECC,"LandUse"),         N2O,CA,Yr(2000):Yr(2013)] .= [0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491,  0.1491]
  xMEPol[Select(ECC,"Wastewater"),      N2O,CA,Yr(2000):Yr(2013)] .= [0.6655,  0.6871,  0.6778,  0.6867,  0.7012,  0.7158,  0.7208,  0.7292,  0.7398,  0.7220,  0.7285,  0.7358,  0.7465,  0.7552]
      
  for ecc in eccs, year in Yr(2000):Yr(2013)
    # 
    # Convert from MT eCO2 to Tonnes N2O
    # 
    @finite_math xMEPol[ecc,N2O,CA,year] = xMEPol[ecc,N2O,CA,year]*1E6/PolConv[N2O]

    # 
    # Emission Coefficient (Tonnes/Driver)
    # 
    @finite_math MEPOCX[ecc,N2O,CA,year] = xMEPol[ecc,N2O,CA,year]/MEDriver[ecc,CA,year]
  end

  # 
  # Residential is aggregate emissions
  # 
  SingleFamilyDetached = Select(ECC,"SingleFamilyDetached")
  years = collect(Yr(2000):Yr(2013))
  #           ECC     Poll               2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[SingleFamilyDetached,N2O,CA,years] = [0.7373,  0.7484,  0.7577,  0.7674,  0.7753,  0.7804,  0.7860,  0.7927,  0.7993,  0.8040,  0.8091,  0.8147,  0.8212,  0.8276]
  
  # 
  # Convert from MT eCO2 to Tonnes N2O
  # 
  for year in years    
    @finite_math xMEPol[SingleFamilyDetached,N2O,CA,year] = xMEPol[SingleFamilyDetached,N2O,CA,year]*1E6/PolConv[N2O]
  end
  
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential"])
  for year in years, ecc in eccs
    @finite_math MEPOCX[ecc,N2O,CA,year] = xMEPol[SingleFamilyDetached,N2O,CA,year]/
                                           sum(MEDriver[e,CA,year] for e in eccs)
  end
  
  for year in years, ecc in eccs  
    xMEPol[ecc,N2O,CA,year] = MEDriver[ecc,CA,year]*MEPOCX[ecc,N2O,CA,year]
  end

  # 
  # Commercial is aggregate emissions
  # 
  Offices = Select(ECC,"Offices")
  years = collect(Yr(2000):Yr(2013))
  
  # ECC - OtherCommercial           2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[Offices,N2O,CA,years] = [0.5004,  0.5079,  0.5142,  0.5208,  0.5262,  0.5296,  0.5334,  0.5379,  0.5424,  0.5456,  0.5491,  0.5529,  0.5573,  0.5616]
      
  eccs = Select(ECC,(from = "Wholesale", to = "OtherCommercial"))
  years = collect(Yr(2000):Yr(2013))

  # 
  # Convert from MT eCO2 to Tonnes N2O
  #   
  for year in years
    @finite_math xMEPol[Offices,N2O,CA,year] = xMEPol[Offices,N2O,CA,year]*1E6/PolConv[N2O]
  end
  
  for year in years, ecc in eccs
    @finite_math MEPOCX[ecc,N2O,CA,year] = xMEPol[Offices,N2O,CA,year]/
                                           sum(MEDriver[e,CA,year] for e in eccs)
  end
  
  for year in years, ecc in eccs
    xMEPol[ecc,N2O,CA,year] = MEDriver[ecc,CA,year]*MEPOCX[ecc,N2O,CA,year]
  end

  years = collect(Yr(1985):Yr(1999))
  for year in years, ecc in ECCs
    MEPOCX[ecc,N2O,CA,year] = MEPOCX[ecc,N2O,CA,Yr(2000)]
  end

  years = collect(Yr(2014):Final)
  for year in years, ecc in ECCs
    MEPOCX[ecc,N2O,CA,year] = MEPOCX[ecc,N2O,CA,Yr(2013)]
  end


  # 
  # CH4 Process Emissions
  # source: "California Emissions All Fuels.xlsx" - Luke Davulis 1/6/16
  # 
  CH4 = Select(Poll,"CH4")
  eccs = Select(ECC,["NGPipeline","Food","PulpPaperMills","Petrochemicals","Petroleum",
                    "Rubber","Cement","IronSteel","OtherManufacturing","ConventionalGasProduction",
                    "Construction","AnimalProduction","CropProduction","SolidWaste","Wastewater"])

  #                   ECC                        Poll                             2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[Select(ECC,"NGPipeline"),               CH4,CA,Yr(2000):Yr(2013)] .= [ 3.6060,  3.6791,  4.2996,  3.7601,  3.8509,  3.8780,  4.1106,  3.9984,  4.1304,  4.2004,  4.0437,  4.0555,  3.8597,  3.8149]
  xMEPol[Select(ECC,"Food"),                     CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0128,  0.0133,  0.0099,  0.0100,  0.0109,  0.0074,  0.0061,  0.0052,  0.0041,  0.0031,  0.0030,  0.0028,  0.0031,  0.0022]
  xMEPol[Select(ECC,"PulpPaperMills"),           CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0035,  0.0036,  0.0041,  0.0042,  0.0039,  0.0043,  0.0046,  0.0038,  0.0039,  0.0040,  0.0035,  0.0037,  0.0042,  0.0043]
  xMEPol[Select(ECC,"Petrochemicals"),           CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0271,  0.0325,  0.0193,  0.0161,  0.0136,  0.0160,  0.0138,  0.0133,  0.0121,  0.0115,  0.0098,  0.0095,  0.0113,  0.0023]
  xMEPol[Select(ECC,"Petroleum"),                CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0257,  0.0263,  0.0265,  0.0270,  0.0263,  0.0272,  0.0278,  0.0275,  0.0272,  0.0252,  0.0246,  0.0514,  0.0353,  0.0195]
  xMEPol[Select(ECC,"Rubber"),                   CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0064,  0.0074,  0.0082,  0.0088,  0.0113,  0.0120,  0.0129,  0.0137,  0.0155,  0.0151,  0.0117,  0.0162,  0.0170,  0.0178]
  xMEPol[Select(ECC,"Cement"),                   CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0609,  0.0242,  0.0238,  0.0241,  0.0257,  0.0252,  0.0246,  0.0233,  0.0205,  0.0192,  0.0138,  0.0162,  0.0148,  0.0163]
  xMEPol[Select(ECC,"IronSteel"),                CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0035,  0.0032,  0.0008,  0.0009,  0.0009,  0.0009,  0.0007,  0.0007,  0.0008,  0.0007,  0.0007,  0.0008,  0.0012,  0.0005]
  xMEPol[Select(ECC,"OtherManufacturing"),       CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0011,  0.0011,  0.0012,  0.0008,  0.0007,  0.0004,  0.0005,  0.0006,  0.0005,  0.0005,  0.0004,  0.0007,  0.0007,  0.0002]
  xMEPol[Select(ECC,"ConventionalGasProduction"),CH4,CA,Yr(2000):Yr(2013)] .= [ 2.2337,  2.3458,  2.3081,  2.2579,  1.7835,  1.7643,  2.3173,  2.3074,  2.3940,  2.4228,  2.4225,  2.4448,  2.4982,  2.5785]
  xMEPol[Select(ECC,"Construction"),             CH4,CA,Yr(2000):Yr(2013)] .= [ 0.0036,  0.0040,  0.0069,  0.0070,  0.0071,  0.0065,  0.0072,  0.0049,  0.0050,  0.0050,  0.0048,  0.0031,  0.0032,  0.0033]
  xMEPol[Select(ECC,"AnimalProduction"),         CH4,CA,Yr(2000):Yr(2013)] .= [18.2812, 19.0215, 19.5691, 20.0976, 19.6081, 20.3083, 20.6603, 22.1757, 22.5694, 22.3831, 21.8924, 21.9161, 22.3943, 22.3943]
  xMEPol[Select(ECC,"CropProduction"),           CH4,CA,Yr(2000):Yr(2013)] .= [ 1.2129,  1.0425,  1.1655,  1.1212,  1.3008,  1.1618,  1.1554,  1.1779,  1.1455,  1.2300,  1.2240,  1.2841,  1.2452,  1.2432]
  xMEPol[Select(ECC,"SolidWaste"),               CH4,CA,Yr(2000):Yr(2013)] .= [ 7.3952,  7.5690,  7.5304,  7.6648,  7.6651,  7.8569,  7.9531,  8.0193,  8.1779,  8.2910,  8.3600,  8.6458,  8.6580,  8.7524]
  xMEPol[Select(ECC,"Wastewater"),               CH4,CA,Yr(2000):Yr(2013)] .= [ 1.8066,  1.7544,  1.7766,  1.7479,  1.7525,  1.7601,  1.7433,  1.7533,  1.7156,  1.6388,  1.6722,  1.6506,  1.6365,  1.6512]
      
  for ecc in eccs
    for year in Yr(2000):Yr(2013)
      # 
      # Convert from MT eCO2 to Tonnes CH4
      # 
      @finite_math xMEPol[ecc,CH4,CA,year] = xMEPol[ecc,CH4,CA,year]*1E6/PolConv[CH4]

      # 
      # Emission Coefficient (Tonnes/Driver)
      # 
      @finite_math MEPOCX[ecc,CH4,CA,year] = xMEPol[ecc,CH4,CA,year]/MEDriver[ecc,CA,year]
    end

    for year in Yr(1985):Yr(1999)
      MEPOCX[ecc,CH4,CA,year] = MEPOCX[ecc,CH4,CA,Yr(2000)]
    end

    for year in Yr(2014):Final
      MEPOCX[ecc,CH4,CA,year] = MEPOCX[ecc,CH4,CA,Yr(2013)]
    end
  end

  # 
  # HFC Process Emissions
  # source: "California Emissions All Fuels.xlsx" - Luke Davulis 1/6/16
  # 
  HFC = Select(Poll,"HFC")
  eccs = Select(ECC,["SingleFamilyDetached","OtherCommercial","OtherManufacturing"])

  #                   ECC                 Poll                            2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[Select(ECC,"SingleFamilyDetached"),HFC,CA,Yr(2000):Yr(2013)] .= [1.6981,  1.6816,  1.6956,  1.7087,  1.7189,  1.6955,  1.6416,  1.6341,  1.6838,  1.8511,  2.2000,  2.5848,  2.9901,  3.3765]
  xMEPol[Select(ECC,"OtherCommercial"),     HFC,CA,Yr(2000):Yr(2013)] .= [1.8876,  2.1345,  2.4034,  2.7652,  3.2317,  3.6597,  4.1100,  4.6061,  5.1440,  5.8335,  6.6777,  7.2550,  7.6932,  8.0305]
  xMEPol[Select(ECC,"OtherManufacturing"),  HFC,CA,Yr(2000):Yr(2013)] .= [0.7297,  0.4563,  1.0302,  1.1816,  1.3702,  1.5435,  1.6810,  1.8275,  2.0566,  2.3764,  2.7115,  2.8596,  3.0004,  3.1077]
      
  for ecc in eccs
    for year in Yr(2000):Yr(2013)
      # 
      # Convert from MT eCO2 to Tonnes HFC
      # 
      @finite_math xMEPol[ecc,HFC,CA,year] = xMEPol[ecc,HFC,CA,year]*1E6/PolConv[HFC]

      # 
      # Emission Coefficient (Tonnes/Driver)
      # 
      @finite_math MEPOCX[ecc,HFC,CA,year] = xMEPol[ecc,HFC,CA,year]/MEDriver[ecc,CA,year]
    end

    for year in Yr(1985):Yr(1999)
      MEPOCX[ecc,HFC,CA,year] = MEPOCX[ecc,HFC,CA,Yr(2000)]
    end

    for year in Yr(2014):Final
      MEPOCX[ecc,HFC,CA,year] = MEPOCX[ecc,HFC,CA,Yr(2013)]
    end
  end

  # 
  # PFC Process Emissions
  # source: "California Emissions All Fuels.xlsx" - Luke Davulis 1/6/16
  # 
  PFC = Select(Poll,"PFC")
  oth_man = Select(ECC,"OtherManufacturing")

  #        ECC   Poll                            2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[oth_man,PFC,CA,Yr(2000):Yr(2013)] .= [0.0022,  0.0015,  0.0017,  0.0012,  0.0018,  0.0017,  0.0022,  0.0028,  0.0021,  0.0021,  0.0022,  0.0022,  0.0025,  0.0022]
      
  for year in Yr(2000):Yr(2013)
    # 
    # Convert from MT eCO2 to Tonnes PFC
    # 
    @finite_math xMEPol[oth_man,PFC,CA,year] = xMEPol[oth_man,PFC,CA,year]*1E6/PolConv[PFC]

    # 
    # Emission Coefficient (Tonnes/Driver)
    # 
    @finite_math MEPOCX[oth_man,PFC,CA,year] = xMEPol[oth_man,PFC,CA,year]/MEDriver[oth_man,CA,year]
  end

  for year in Yr(1985):Yr(1999)
    MEPOCX[oth_man,PFC,CA,year] = MEPOCX[oth_man,PFC,CA,Yr(2000)]
  end

  for year in Yr(2014):Final
    MEPOCX[oth_man,PFC,CA,year] = MEPOCX[oth_man,PFC,CA,Yr(2013)]
  end

  # 
  # HFC Process Emissions
  # source: "California Emissions All Fuels.xlsx" - Luke Davulis 1/6/16
  # 
  SF6 = Select(Poll,"SF6")

  #        ECC   Poll                            2000     2001     2002     2003     2004     2005     2006     2007     2008     2009     2010     2011     2012     2013 
  xMEPol[oth_man,SF6,CA,Yr(2000):Yr(2013)] .= [0.0603,  0.0408,  0.0362,  0.0434,  0.0413,  0.0447,  0.0430,  0.0339,  0.0305,  0.0235,  0.0295,  0.0401,  0.0380,  0.0241]
      
  for year in Yr(2000):Yr(2013)
    # 
    # Convert from MT eCO2 to Tonnes SF6
    # 
    @finite_math xMEPol[oth_man,SF6,CA,year] = xMEPol[oth_man,SF6,CA,year]*1E6/PolConv[SF6]

    # 
    # Emission Coefficient (Tonnes/Driver)
    # 
    @finite_math MEPOCX[oth_man,SF6,CA,year] = xMEPol[oth_man,SF6,CA,year]/MEDriver[oth_man,CA,year]
  end

  for year in Yr(1985):Yr(1999)
    MEPOCX[oth_man,SF6,CA,year] = MEPOCX[oth_man,SF6,CA,Yr(2000)]
  end

  for year in Yr(2014):Final
    MEPOCX[oth_man,SF6,CA,year] = MEPOCX[oth_man,SF6,CA,Yr(2013)]
  end

  for ecc in ECCs, poll in Polls, year in Years
    xMEPol[ecc,poll,CA,year] = MEDriver[ecc,CA,year]*MEPOCX[ecc,poll,CA,year]
  end

  WriteDisk(db,"MEInput/MEPOCX",MEPOCX)
  WriteDisk(db,"SInput/xMEPol",xMEPol)

end

function CalibrationControl(db)
  @info "GHG_MacroEconomy_CA.jl - CalibrationControl"

  MCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
