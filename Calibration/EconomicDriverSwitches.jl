#
# EconomicDriverSwitches.jl - Assigns the driver for each ECC and Area
#
using EnergyModel

module EconomicDriverSwitches

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr,Zero
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
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DrSwitch::VariableArray{3} = ReadDisk(db,"MInput/DrSwitch") # [ECC,Area,Year] Economic Driver Switch
  MacroSwitch::SetArray = ReadDisk(db,"MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  NGasFr::VariableArray{3} = ReadDisk(db,"MInput/NGasFr") # [ECC,Area,Year] Fraction of National Natural Gas Driver allocated to each Area (Btu/Btu)

end

function DriverSwitches(db)
  data = MControl(; db)
  (;Area,Areas,ECC,ECCs,Nation,Years) = data
  (;ANMap,DrSwitch,MacroSwitch,NGasFr) = data

  #
  # Default Driver is Gross Output (DrSwitch=21)
  #
  for ecc in ECCs, area in Areas, year in Years
    DrSwitch[ecc,area,year] = 21
  end
  
  #
  # Canada Economic Drivers
  #
  CN = Select(Nation, "CN")
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # Canada Sectors using Floor Space (DrSwitch=1)
  #
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential","Wholesale",
                     "Retail","Warehouse","Information","Offices","Education",
                     "Health","OtherCommercial"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 1
  end
  
  #
  # Canada Sectors using GRP (DrSwitch=2)
  #
  eccs = Select(ECC,["StreetLighting","Freight","AirFreight","ForeignPassenger",
                     "ForeignFreight","Steam","ResidentialOffRoad","CommercialOffRoad"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 2
  end

  #
  # Canada Sectors using Personal Income (DrSwitch=3)
  #
  eccs = Select(ECC,"AirPassenger")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 3
  end
  
  #
  # Canada Sectors using National Oil Production (DrSwitch=4)
  #
  eccs = Select(ECC,"OilPipeline")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 4
  end

  #
  # Canada Sectors using National Gas Production (DrSwitch=5)
  #
  # AB and NT NG Pipelines use national NG production as driver
  # per May 2017 ECCC study. (8/29/17 R.Levesque)
  #
  eccs = Select(ECC,["NGDistribution","NGPipeline"])
  ABandNT = Select(Area,["AB","NT"])
  for year in Years, area in ABandNT, ecc in eccs 
    DrSwitch[ecc,area,year] = 5
  end

  #
  # Canada Sectors using Local Oil Production (DrSwitch=7)
  #
  eccs = Select(ECC,["LightOilMining","HeavyOilMining","FrontierOilMining",
                     "PrimaryOilSands","SAGDOilSands","CSSOilSands",
                     "OilSandsMining","OilSandsUpgraders"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 7
  end

  #
  # Canada Sectors using Local Natural Gas Production (DrSwitch=8)
  #
  eccs = Select(ECC,["SweetGasProcessing","ConventionalGasProduction",
                    "SourGasProcessing","UnconventionalGasProduction"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 8
  end

  #
  # Canada Sectors using Nova Scotia Local Natural Gas Production (DrSwitch=25)
  #
  # NS and NB natural gas pipelines use local NS natural gas production
  # as a driver per May 2017 ECCC study. (8/29/17 R.Levesque)
  #
  eccs = Select(ECC,["NGDistribution","NGPipeline"])
  NSandNB = Select(Area,["NS","NB"])
  for year in Years, area in NSandNB, ecc in eccs
    DrSwitch[ecc,area,year] = 25
  end

  #
  # Canada Sectors using Vehicle Stock (DrSwitch=27)
  #
  eccs = Select(ECC,"Passenger")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 27
  end

  #
  # Canada Sectors using Land Area (DrSwitch=10)
  #
  eccs = Select(ECC,["LandUse","ForestFires","Biogenics"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 10
  end

  #
  # Canada Sectors using Total Housholds (DrSwitch=16) 
  #
  eccs = Select(ECC,["SolidWaste","Wastewater","Incineration"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 16
  end

  #
  # Canada Sectors using Electric Utility Generation (DrSwitch=17)
  #
  eccs = Select(ECC,"UtilityGen")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 17
  end

  #
  # Canada Sectors using RPP Production (DrSwitch=18)
  #
  eccs = Select(ECC,"Petroleum")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 18
  end
  
  #
  # Canada Sectors using Freight Miles (DrSwitch=19)
  #
  eccs = Select(ECC,"RoadDust")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 19
  end

  #
  # Canada Sectors using Farm Gross Output (DrSwitch=20)
  #
  eccs = Select(ECC,"OpenSources")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 20
  end

  #
  # Canada Sectors using Natural Gas Demands (DrSwitch=22)
  #
  eccs = Select(ECC,"NGDistribution")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 22
  end

  #
  # ON,QC,BC,MB,SK,NL,PE,YT,NU pipeline have NG demand as driver
  # per May 2017 ECCC study. 8/29/17 R.Levesque.
  #
  eccs = Select(ECC,"NGPipeline")
  PipelineAreas = Select(Area,["ON","QC","BC","MB","SK","NL","PE","YT","NU"])
  for year in Years, area in PipelineAreas, ecc in eccs
    DrSwitch[ecc,area,year] = 22
  end

  #
  # Canada Sectors using Local Liquid Natural Gas Production (DrSwitch=23)
  #
  eccs = Select(ECC,"LNGProduction")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 23
  end

  #
  # Canada Sectors using Coal Production (DrSwitch=24)
  #
  eccs = Select(ECC,"CoalMining")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 24
  end

  #
  # Canada Sectors using Biofuel Production (DrSwitch=26)
  #
  eccs = Select(ECC,"BiofuelProduction")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 26
  end
  
  #
  # ********************
  #
  # US Economic Drivers
  #
  US = Select(Nation, "US")
  areas = findall(ANMap[:,US] .== 1.0)

  #
  # US Residential Driver is Households (DrSwitch=16)
  #
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 16
  end

  #
  # US Sectors using Floor Space (DrSwitch=1)
  #
  if MacroSwitch[US] == "AEO"
    eccs = Select(ECC,["Wholesale","Retail","Warehouse","Information","Offices",
                      "Education","Health","OtherCommercial"])
    for year in Years, area in areas, ecc in eccs
      DrSwitch[ecc,area,year] = 1
    end
  end

  #
  # US Sectors using GRP (DrSwitch=2)
  #
  eccs = Select(ECC,["Warehouse","StreetLighting","OtherChemicals","Fertilizer",
                     "Cement","IronSteel","Aluminum","Freight","AirFreight","ForeignPassenger",
                     "ForeignFreight","ResidentialOffRoad","CommercialOffRoad","UtilityGen"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 2
  end

  #
  # US Sectors using Personal Income (DrSwitch=3)
  #
  eccs = Select(ECC,"AirPassenger")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 3
  end

  #
  # US Sectors using Local Oil Production (DrSwitch=7)
  #
  eccs = Select(ECC,"LightOilMining")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 7
  end

  #
  # US Sectors using Local Natural Gas Production (DrSwitch=8)
  #
  eccs = Select(ECC,"ConventionalGasProduction")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 8
  end

  #
  # US Sectors using Total Housholds (DrSwitch=16)
  #
  eccs = Select(ECC,["SolidWaste","Wastewater","Incineration"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 16
  end

  #
  # US Sectors using Natural Gas Demands (DrSwitch=22)
  #
  eccs = Select(ECC,["NGDistribution","NGPipeline"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 22
  end

  #
  # US Sectors using Local Liquid Natural Gas Production (DrSwitch=23)
  #
  eccs = Select(ECC,"LNGProduction")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 23
  end

  #
  # US Sectors using Coal Production (DrSwitch=24)
  #
  eccs = Select(ECC,"CoalMining")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 24
  end

  #
  # US Sectors using Biofuel Production (DrSwitch=26)
  #
  eccs = Select(ECC,"BiofuelProduction")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 26
  end

  #
  # US Sectors using using Vehicle Stock (DrSwitch=27)
  #
  eccs = Select(ECC,"Passenger")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 27
  end

  #
  # Mexico Economic Drivers
  #
  MX = Select(Nation, "MX")
  areas = findall(ANMap[:,MX] .== 1.0)

  #
  # Mexico Residential Driver is Population (DrSwitch=9)
  #
  eccs = Select(ECC,["SingleFamilyDetached","SingleFamilyAttached","MultiFamily","OtherResidential"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 9
  end

  #
  # Mexico Sectors using GRP (DrSwitch=2)
  #
  eccs = Select(ECC,["StreetLighting","Freight","AirFreight","ForeignPassenger",
                     "ForeignFreight","ResidentialOffRoad","CommercialOffRoad"])
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 2
  end

  #
  # MX Sectors using Personal Income (DrSwitch=3)
  #
  eccs = Select(ECC,"AirPassenger")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 3
  end

  #
  # MX Sectors using using Vehicle Stock (DrSwitch=27)
  #
  eccs = Select(ECC,"Passenger")
  for year in Years, area in areas, ecc in eccs
    DrSwitch[ecc,area,year] = 27
  end

  WriteDisk(db,"MInput/DrSwitch",DrSwitch)

  #
  # Set NGasFr=1.0 for NGPipeline for all CN areas. 8/31/17 R.Levesque
  #    Previously NGasFr had values to allocate National NG Production to each area
  #    as driver for NGPipeline. Per ECCC May 2017 study, 100% of total national production
  #    is used for areas that drive NGPipeline with national production (AB,NT).
  #

  for year in Years, area in Areas, ecc in ECCs
   NGasFr[ecc,area,year] = 0
  end

  areas = findall(ANMap[:,CN] .== 1.0)
  ecc = Select(ECC,"NGPipeline")
  for year in Years, area in areas
    NGasFr[ecc,area,year] = 1.000
  end

  areas = Select(Area,["ON","QC","BC","AB","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  ecc = Select(ECC,"NGDistribution")
  NGasFr[ecc,areas,Zero] .=[
    #= Ontario =#                  0.291
    #= Quebec =#                   0.041
    #= British Columbia =#         0.099
    #= Alberta =#                  0.240
    #= Manitoba =#                 0.029
    #= Saskatchewan =#             0.300
    #= New Brunswick =#            0.000
    #= Nova Scotia =#              0.000
    #= Newfoundland =#             0.000
    #= PEI =#                      0.000
    #= Yukon =#                    0.000
    #= Northwest Territories =#    0.000
    #= Nunavut =#                  0.000
  ]

  for year in Years, area in areas 
    NGasFr[ecc,area,year] = NGasFr[ecc,area,Zero]
  end

  WriteDisk(db,"MInput/NGasFr",NGasFr)

end

function Control(db)
  @info "EconomicDriverSwitches.jl - Control"
  DriverSwitches(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
