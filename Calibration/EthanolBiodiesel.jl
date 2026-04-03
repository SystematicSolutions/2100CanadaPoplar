#
# EthanolBiodiesel.jl - Ethanol and Biodiesel Data
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# � 2016 Systematic Solutions, Inc.  All rights reserved.
#
using EnergyModel

module EthanolBiodiesel

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutpt"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Biofuel::SetArray = ReadDisk(db,"MainDB/BiofuelKey")
  BiofuelDS::SetArray = ReadDisk(db,"MainDB/BiofuelDS")
  Biofuels::Vector{Int} = collect(Select(Biofuel))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Feedstock::SetArray = ReadDisk(db,"MainDB/FeedstockKey")
  FeedstockDS::SetArray = ReadDisk(db,"MainDB/FeedstockDS")
  Feedstocks::Vector{Int} = collect(Select(Feedstock))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"SInput/TechKey")
  TechDS::SetArray = ReadDisk(db,"SInput/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BfCC::VariableArray{5} = ReadDisk(db,"SpInput/BfCC") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Production Capital Cost (Real $/mmBtu)
  BfCCR::VariableArray{4} = ReadDisk(db,"SpInput/BfCCR") # [Biofuel,Feedstock,Area,Year] Biofuel Production Capital Charge Rate
  BfCUFMax::VariableArray{3} = ReadDisk(db,"SpInput/BfCUFMax") # [Biofuel,Area,Year] Biofuel Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  BfCUFP::VariableArray{3} = ReadDisk(db,"SpInput/BfCUFP") # [Biofuel,Area,Year] Biofuel Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  BfDChg::VariableArray{3} = ReadDisk(db,"SpInput/BfDChg") # [ES,Area,Year] Biofuel Delivery Charge (Real $/mmBtu)
  BfDmFrac::VariableArray{4} = ReadDisk(db,"SpInput/BfDmFrac") # [Fuel,Tech,Area,Year] Biofuel Production Energy Usage Fraction
  BfEff::VariableArray{5} = ReadDisk(db,"SpInput/BfEff") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Production Energy Efficiency (Btu/Btu)
  BfFsPrice::VariableArray{3} = ReadDisk(db,"SpInput/BfFsPrice") # [Feedstock,Area,Year] Biofuel Feedstock Price ($/Tonne)
  BfFsYield::VariableArray{5} = ReadDisk(db,"SpInput/BfFsYield") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Yield From Feedstock (Btu/Tonne)
  # *BfHRt::VariableArray{5} = ReadDisk(db,"SpInput/*BfHRt") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Production Heat Rate (Btu/Btu)
  BfMSM0::VariableArray{5} = ReadDisk(db,"SpInput/BfMSM0") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Market Share Non-Price Factor (mmBtu/mmBtu)
  BfOF::VariableArray{5} = ReadDisk(db,"SpInput/BfOF") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Production O&M Cost Factor (Real $/$/Yr)
  BfPL::VariableArray{1} = ReadDisk(db,"SpInput/BfPL") # [Year] Biofuel Production Physical Lifetime (Years)
  BfPOCX::VariableArray{4} = ReadDisk(db,"SpInput/BfPOCX") # [FuelEP,Poll,Area,Year] Biofuel Pollution Coefficient (Tonnes/TBtu)
  BfProdFrac::VariableArray{4} = ReadDisk(db,"SpInput/BfProdFrac") # [Biofuel,Area,Nation,Year] Biofuel Production as a Fraction of National Demands (Btu/Btu)
  BfSubsidy::VariableArray{3} = ReadDisk(db,"SpInput/BfSubsidy") # [Biofuel,Nation,Year] Biofuel Production Subsidy ($/mmBtu)
  BfUOMC::VariableArray{5} = ReadDisk(db,"SpInput/BfUOMC") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Production O&M Costs (Real $/mmBtu)
  BfVF::VariableArray{5} = ReadDisk(db,"SpInput/BfVF") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Market Share Variance Factor (mmBtu/mmBtu)
  CgCC::VariableArray{3} = ReadDisk(db,"SpInput/CgCC") # [Tech,Area,Year] Cogeneration Capital Cost ($/mmBtu/Yr)
  CgCUF::VariableArray{2} = ReadDisk(db,"SpInput/CgCUF") # [Tech,Area] Cogeneration Capacity Utilization Factor (Btu/Btu)
  CgMSF::VariableArray{3} = ReadDisk(db,"SpInput/CgMSF") # [Tech,Area,Year] Cogeneration Market Share (Btu/Btu)
  CgOF::VariableArray{2} = ReadDisk(db,"SpInput/CgOF") # [Tech,Area] Cogeneration Operation Cost Fraction ($/Yr/$)
  CgPL::VariableArray{2} = ReadDisk(db,"SpInput/CgPL") # [Tech,Area] Cogeneration Equipment Lifetime (Years)
  ICgCC::VariableArray{4} = ReadDisk(db,"$Input/CgCC") # [Tech,EC,Area,Year] Cogeneration Capital Cost ($/mmBtu/Yr)
  IDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Fraction)
  IPOCX::VariableArray{6} = ReadDisk(db,"$Input/POCX") # [Enduse,FuelEP,EC,Poll,Area,Year] Pollution Coefficient (Tonnes/TBtu)
  IXDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [PointerCN,Year] CN Inflation Index ($/$)
  BfImportFraction::VariableArray{3} = ReadDisk(db,"SpInput/BfImportFraction") # [Biofuel,Nation,Year] Biofuel Import Fraction (Btu/Btu)
  BfExportFraction::VariableArray{3} = ReadDisk(db,"SpInput/BfExportFraction") # [Biofuel,Nation,Year] Biofuel Export Fraction (Btu/Btu)
  BfCD::VariableArray{2} = ReadDisk(db,"SpInput/BfCD") # [Biofuel,Year] Biofuel Production Construction Delay (Years)

  # Scratch Variables
  # PerLitre 'Ethanol Energy Content (Btu/Litre)'
  MSMInput::VariableArray{2} = zeros(Float32,length(Tech),length(Feedstock)) # [Tech,Feedstock] Input for BfMSM0
end

function SCalibration(db)
  data = SControl(; db)
  (;Area,Areas,Biofuel,Biofuels,EC) = data
  (;Enduse,Feedstock,Feedstocks,Fuel) = data
  (;FuelEPs,Fuels,Nation,Polls) = data
  (;Tech,Techs,Years) = data
  (;ANMap,BfCC,BfCCR,BfCUFMax,BfCUFP,BfDChg,BfDmFrac,BfEff,BfFsPrice,BfFsYield) = data
  (;BfMSM0,BfOF,BfPL,BfPOCX,BfProdFrac,BfSubsidy,BfUOMC,BfVF,CgCC) = data
  (;CgCUF,CgMSF,CgOF,CgPL,ICgCC,IDmFrac,IPOCX) = data
  (;xExchangeRate,xInflation,xInflationNation,BfImportFraction,BfExportFraction,BfCD) = data
  (;MSMInput) = data

  #
  #################################################
  #
  # Btu per Litre of Ethanol:
  # Source: https://en.wikipedia.org/wiki/Gasoline_gallon_equivalent
  #
  PerLitre=76100/3.7854
  #
  ##### General Biofuels Data
  #
  ########################
  #
  # Biofuel Production Capacity Utilization Factor Maximum (mmBtu/mmBtu)
  # Use "normal" value - Jeff Amlin 5/26/16
  #
  years=collect(Zero:Last)
  for year in years, area in Areas, biofuel in Biofuels
    BfCUFMax[biofuel,area,year]=1.00
  end
  years=collect(Future:Final)
  for year in years, area in Areas, biofuel in Biofuels
    BfCUFMax[biofuel,area,year]=0.90
  end
  WriteDisk(db,"SpInput/BfCUFMax",BfCUFMax)

  #
  ########################
  #
  # Biofuel Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  # Use "normal" value - Jeff Amlin 5/26/16
  #
  for year in Years, area in Areas, biofuel in Biofuels
    BfCUFP[biofuel,area,year]=0.80
  end
  WriteDisk(db,"SpInput/BfCUFP",BfCUFP)

  #
  ########################
  #
  # Biofuel Production Energy Usage Fraction
  #
  enduse=Select(Enduse,"Heat")
  ec=Select(EC,"OtherChemicals")
  for year in Years, area in Areas, tech in Techs, fuel in Fuels
    BfDmFrac[fuel,tech,area,year]=IDmFrac[enduse,fuel,tech,ec,area,year]
  end

  #
  # Add in non-substitutible demands (in lieu of an enduse) - Jeff Amlin 2/28/17
  # Source: 2015 Energy Balance for the Corn-Ethanol Industry,USDA, Office of the Chief Economist,
  # Office of Energy Policy and New Uses, February 2016
  # Authors: Paul W. Gallagher, Ph.D., Associate Professor, Department of Economics, Iowa State University
  # Winnie C. Yee, Chemical Engineer, USDA, Agricultural Research Service, Crop Conversion Science and Engineering Research Unit
  # Harry S. Baumes, Ph.D., Director, USDA, Office of the Chief Economist, Office of Energy Policy and New Uses
  # C:\2020 Data\Biofuel\US\Elecricity in Biofuel Production.xlsx - Jeff Amlin 2/28/17
  #*
  fuel=Select(Fuel,"Electric")
  for area in Areas, tech in Techs
    BfDmFrac[fuel,tech,area,Yr(2009)]=BfDmFrac[fuel,tech,area,Yr(2009)]+0.1111
    BfDmFrac[fuel,tech,area,Yr(2010)]=BfDmFrac[fuel,tech,area,Yr(2010)]+0.0989
    BfDmFrac[fuel,tech,area,Yr(2011)]=BfDmFrac[fuel,tech,area,Yr(2011)]+0.0870
    BfDmFrac[fuel,tech,area,Yr(2012)]=BfDmFrac[fuel,tech,area,Yr(2012)]+0.0753
    BfDmFrac[fuel,tech,area,Yr(2013)]=BfDmFrac[fuel,tech,area,Yr(2013)]+0.0638
  end
  years=collect(Zero:Yr(2008))
  for year in years, area in Areas, tech in Techs
    BfDmFrac[fuel,tech,area,year]=BfDmFrac[fuel,tech,area,Yr(2009)]
  end
  years=collect(Yr(2014):Final)
  for year in years, area in Areas, tech in Techs
    BfDmFrac[fuel,tech,area,year]=BfDmFrac[fuel,tech,area,Yr(2013)]
  end
  WriteDisk(db,"SpInput/BfDmFrac",BfDmFrac)

  #
  ########################
  #
  #  Biofuel Production Energy Efficiency (Btu/Btu)
  #
  # Source: "Biofuel_Module_Parameters_Rob_05Jan2015.xlsx"
  # NOTE: NEEDS CONVERSION - Energy Requirements in MJ/Litre Ethanol
  #

  for area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfEff[biofuel,tech,feedstock,area,Yr(2009)]=PerLitre/(10.65*948.4514)
    BfEff[biofuel,tech,feedstock,area,Yr(2010)]=PerLitre/(10.66*948.4514)
    BfEff[biofuel,tech,feedstock,area,Yr(2011)]=PerLitre/(10.44*948.4514)
    BfEff[biofuel,tech,feedstock,area,Yr(2012)]=PerLitre/(10.24*948.4514)
    BfEff[biofuel,tech,feedstock,area,Yr(2013)]=PerLitre/(10.09*948.4514)
  end
  years=collect(First:Yr(2008))
  for year in years, area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfEff[biofuel,tech,feedstock,area,year]=BfEff[biofuel,tech,feedstock,area,Yr(2009)]
  end
  years=collect(Yr(2014):Final)
  for year in years, area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfEff[biofuel,tech,feedstock,area,year]=BfEff[biofuel,tech,feedstock,area,Yr(2013)]
  end
  #
  # Biodiesel is less energy intensive than ethanol from IEA - Jeff Amlin 5/22/2018
  #
  Biodiesel=Select(Biofuel,"Biodiesel")
  Ethanol=Select(Biofuel,"Ethanol")
  for year in Years, area in Areas, feedstock in Feedstocks, tech in Techs
    BfEff[Biodiesel,tech,feedstock,area,year]=BfEff[Ethanol,tech,feedstock,area,year]*3
  end
  #
  # Adjust Biofuel efficiency to to reduce demands relative to the
  # historical demands for Other Chemicals - Jeff Amlin 6/7/17
  #
  # *BfEff=BfEff*10
  #
  # *Select Area(SK)
  # *BfEff=BfEff*10
  # *Select Area*
  #
  WriteDisk(db,"SpInput/BfEff",BfEff)

  #
  ########################
  #
  # Biofuel Production Heat Rate (Btu/Btu)
  # Preliminary value from Industrial CgHRt for Biomass
  #
  # *BfHRt(Biofuel,Tech,Feedstock,Area,Year)=15873
  # *Write Disk(BfHRt)
  #
  ########################
  #
  # Biofuel Market Share Non-Price Factor (mmBtu/mmBtu)
  #
  # Source: Roughly based on "Biofuel_Module_Parameters_Rob_05Jan2015.xlsx"
  # Note: Oil substituted for Steam (remove Oil - Jeff Amlin 9/27/16)
  #
  # Source: 2015 Energy Balance for the Corn-Ethanol Industry,USDA, Office of the Chief Economist,
  # Office of Energy Policy and New Uses, February 2016
  # Authors: Paul W. Gallagher, Ph.D., Associate Professor, Department of Economics, Iowa State University
  # Winnie C. Yee, Chemical Engineer, USDA, Agricultural Research Service, Crop Conversion Science and Engineering Research Unit
  # Harry S. Baumes, Ph.D., Director, USDA, Office of the Chief Economist, Office of Energy Policy and New Uses
  # Jeff Amlin 2/28/17
  #
  @. BfMSM0=-170
  biofuel=Select(Biofuel,"Ethanol")
  feedstocks=Select(Feedstock,["Corn","Wheat","Cellulosic"])
  techs=Select(Tech,["Electric","Gas","Steam"])
  # area1=first(Areas)
  # year1=first(Years)
  MSMInput[techs,feedstocks] .= [
    #Corn  Wheat Cellulosic
    -6.0  -6.5  -27.00 # Electric
     0.0  -0.5  -10.00 # Gas
    -2.0  -2.5  -20.00 # Steam
  ]
  for year in Years, area in Areas, feedstock in feedstocks, tech in techs
    BfMSM0[biofuel,tech,feedstock,area,year]=MSMInput[tech,feedstock]
  end

  biofuel=Select(Biofuel,"Biodiesel")
  feedstocks=Select(Feedstock,["Rapeseed","Other"])
  techs=Select(Tech,["Electric","Gas","Steam"])
  # area1=first(Areas)
  # year1=first(Years)
  MSMInput[techs,feedstocks] .= [
    #Rapeseed  Other
    -6.0      -25.00 # Electric
     0.0      -10.00 # Gas
    -2.0      -20.00 # Steam
  ]
  for year in Years, area in Areas, feedstock in feedstocks, tech in techs
    BfMSM0[biofuel,tech,feedstock,area,year]=MSMInput[tech,feedstock]
  end

  WriteDisk(db,"SpInput/BfMSM0",BfMSM0)

  #
  ########################
  #
  # Biofuel Production Physical Lifetime (Years)
  # Preliminary Value from Industrial Heat Lifetime
  #
  @. BfPL=10
  WriteDisk(db,"SpInput/BfPL",BfPL)

  #
  ########################
  #
  # Biofuel Pollution Coefficient (Tonnes/TBtu)
  # Preliminary Values from Industrial POCX, EC Chemicals, Enduse Heat
  #

  enduse=Select(Enduse,"Heat")
  ec=Select(EC,"OtherChemicals")
  for year in Years, area in Areas, poll in Polls, fuelep in FuelEPs
    BfPOCX[fuelep,poll,area,year]=IPOCX[enduse,fuelep,ec,poll,area,year]
  end
  WriteDisk(db,"SpInput/BfPOCX",BfPOCX)

  #
  ########################
  #
  # Ethanol (and Biodiesel) Production by Area
  #
  # Canada Fractions
  # Ethanol prod import export 20-Oct-16.xlsm from Robin White - Jeff Amlin 1/17/17
  #
  CN=Select(Nation,"CN")
  areas=findall(ANMap[:,CN] .== 1)
  for year in years, area in areas, biofuel in Biofuels
    BfProdFrac[biofuel,area,CN,year]=0.0
  end

  areas=Select(Area,["AB","BC","MB","NB","NS","ON","QC","SK"])
  biofuel1=first(Biofuels)
  years=collect(Yr(2013):Yr(2015))
  BfProdFrac[biofuel1,areas,CN,years] .= [
    # 2013    2014    2015
    0.0328  0.0397  0.0229 # Alberta
    0.0000  0.0000  0.0000 # BC
    0.0904  0.0882  0.0902 # Manitoba
    0.0000  0.0000  0.0000 # New Brunswick
    0.0000  0.0000  0.0000 # Nova Scotia
    0.6055  0.5967  0.6103 # Ontario
    0.1012  0.1006  0.1040 # Quebec
    0.1702  0.1747  0.1726 # Saskatchewan
  ]
  for year in years, area in areas, biofuel in Biofuels
    BfProdFrac[biofuel,area,CN,year]=BfProdFrac[biofuel1,area,CN,year]
  end
  years=collect(Zero:Yr(2012))
  for year in years, area in areas, biofuel in Biofuels
    BfProdFrac[biofuel,area,CN,year]=BfProdFrac[biofuel,area,CN,Yr(2013)]
  end
  years=collect(Yr(2016):Final)
  for year in years, area in areas, biofuel in Biofuels
    BfProdFrac[biofuel,area,CN,year]=BfProdFrac[biofuel,area,CN,Yr(2015)]
  end

  #
  # US Fractions
  # Source: http://www.neo.ne.gov/statshtml/121.htm
  # C:\2020 Data\Biofuel\US\US Ethanol Production Capacity and Production by State 2016 v2.xlsx.xls
  # Jeff Amlin 2/27/17
  #
  US=Select(Nation,"US")
  areas=Select(Area,["CA","NEng","MAtl","ENC","WNC","SAtl","ESC","WSC","Mtn","Pac"])
  BfProdFrac[biofuel1,areas,US,Yr(2016)] .= [
    0.0144 # CA
    0.0000 # NEng
    0.0184 # MAtl
    0.2699 # ENC
    0.6206 # WNC
    0.0119 # SAtl
    0.0207 # ESC
    0.0257 # WSC
    0.0156 # Mtn
    0.0030 # Pac
  ]

  for area in areas, biofuel in Biofuels
    BfProdFrac[biofuel,area,US,Yr(2016)]=BfProdFrac[biofuel1,area,US,Yr(2016)]
  end
  years=collect(Zero:Yr(2015))
  for year in years, area in areas, biofuel in Biofuels
    BfProdFrac[biofuel,area,US,year]=BfProdFrac[biofuel,area,US,Yr(2016)]
  end
  years=collect(Yr(2017):Final)
  for year in years, area in areas, biofuel in Biofuels
    BfProdFrac[biofuel,area,US,year]=BfProdFrac[biofuel,area,US,Yr(2016)]
  end

  WriteDisk(db,"SpInput/BfProdFrac",BfProdFrac)


  #
  ########################
  #
  for biofuel in Biofuels
    BfImportFraction[biofuel,CN,Yr(2013)]=0.4100
    BfImportFraction[biofuel,CN,Yr(2014)]=0.4327
    BfImportFraction[biofuel,CN,Yr(2015)]=0.4399
  end
  years=collect(Zero:Yr(2012))
  for year in years, biofuel in Biofuels
    BfImportFraction[biofuel,CN,year]=BfImportFraction[biofuel,CN,Yr(2013)]
  end
  years=collect(Yr(2016):Final)
  for year in years, biofuel in Biofuels
    BfImportFraction[biofuel,CN,year]=BfImportFraction[biofuel,CN,Yr(2015)]
  end
  WriteDisk(db,"SpInput/BfImportFraction",BfImportFraction)

  #
  ########################
  #
  for biofuel in Biofuels
    BfExportFraction[biofuel,CN,Yr(2013)]=0.0198
    BfExportFraction[biofuel,CN,Yr(2014)]=0.0158
    BfExportFraction[biofuel,CN,Yr(2015)]=0.0000
  end
  years=collect(Zero:Yr(2012))
  for year in years, biofuel in Biofuels
    BfExportFraction[biofuel,CN,year]=BfExportFraction[biofuel,CN,Yr(2013)]
  end
  years=collect(Yr(2016):Final)
  for year in years, biofuel in Biofuels
    BfExportFraction[biofuel,CN,year]=BfExportFraction[biofuel,CN,Yr(2015)]
  end
  WriteDisk(db,"SpInput/BfExportFraction",BfExportFraction)

  #
  ########################
  #
  # Biofuel Market Share Variance Factor (mmBtu/mmBtu)
  # Preliminary value from Industrial xMVF
  #
  @. BfVF=-2.5
  WriteDisk(db,"SpInput/BfVF",BfVF)

  #
  ########################
  #
  ##### Biofuels Feedstock Variables
  #
  # Biofuel Feedstock Price (2013 US$/Tonne)
  #
  for area in Areas, feedstock in Feedstocks
    BfFsPrice[feedstock,area,Yr(2011)]=259.02
    BfFsPrice[feedstock,area,Yr(2012)]=274.60
    BfFsPrice[feedstock,area,Yr(2013)]=250.57
  end

  # Time Series Revised
  for year in Years,area in Areas, feedstock in Feedstocks
    BfFsPrice[feedstock,area,year]=BfFsPrice[feedstock,area,year]/xInflationNation[US,Yr(2013)]*xInflationNation[US,year]*
      xExchangeRate[area,year]/xInflation[area,year]
  end

  years=collect(First:Yr(2010))
  for year in years,area in Areas, feedstock in Feedstocks
    BfFsPrice[feedstock,area,year]=BfFsPrice[feedstock,area,Yr(2011)]
  end
  years=collect(Yr(2014):Final)
  for year in years,area in Areas, feedstock in Feedstocks
    BfFsPrice[feedstock,area,year]=BfFsPrice[feedstock,area,Yr(2013)]
  end
  WriteDisk(db,"SpInput/BfFsPrice",BfFsPrice)

  #
  ########################
  #
  # Biofuel Yield From Feedstock (Btu/Tonne)
  #
  # Source: "http://www.ethanolproducer.com/articles/9658/survey-cellulosic-ethanol-will-be-cost-competitive-by-2015"
  # File: Biofuel_module_Parameters_v2.1.xlsx
  #
  years=collect(First:Yr(2010))
  for year in years, area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfFsYield[biofuel,tech,feedstock,area,year]=4978847
  end
  years=collect(Yr(2011):Final)
  for year in years, area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfFsYield[biofuel,tech,feedstock,area,year]=5665584
  end
  WriteDisk(db,"SpInput/BfFsYield",BfFsYield)

  #
  ########################
  #
  ##### Biofuels Financials
  #
  # Biofuel Production Capital Cost (Real $/mmBtu)
  #
  # Source: "Biofuel_Module_Parameters_Rob_05Jan2015.xlsx"
  # Capital cost in 2013 CN$/Litre Ethanol
  #
  for area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfCC[biofuel,tech,feedstock,area,Yr(2011)]=0.9401/PerLitre
    BfCC[biofuel,tech,feedstock,area,Yr(2012)]=0.9229/PerLitre
    BfCC[biofuel,tech,feedstock,area,Yr(2013)]=0.9661/PerLitre
  end

  # Time Series Revised
  for year in Years,area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfCC[biofuel,tech,feedstock,area,year]=BfCC[biofuel,tech,feedstock,area,year]/xInflationNation[US,Yr(2013)]*xInflationNation[US,year]*
      xExchangeRate[area,year]/xInflation[area,year]
  end

  #
  # Increaseing because BfCC seems small. Luke Davulis, 6-9-2016
  #
  for year in Years,area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfCC[biofuel,tech,feedstock,area,year]=BfCC[biofuel,tech,feedstock,area,year]*50
  end

  years=collect(First:Yr(2010))
  for year in years,area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfCC[biofuel,tech,feedstock,area,year]=BfCC[biofuel,tech,feedstock,area,Yr(2011)]
  end
  years=collect(Yr(2014):Final)
  for year in years,area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfCC[biofuel,tech,feedstock,area,year]=BfCC[biofuel,tech,feedstock,area,Yr(2013)]
  end
  WriteDisk(db,"SpInput/BfCC",BfCC)

  #
  ########################
  #
  # Biofuel Production Capital Charge Rate
  # Reduce due to low interest rates Jeff Amlin 5/26/16
  #
  @. BfCCR=0.08
  WriteDisk(db,"SpInput/BfCCR",BfCCR)

  #
  ########################
  #
  @. BfCD=2
  WriteDisk(db,"SpInput/BfCD",BfCD)

  #
  ########################
  #
  # Biofuel Delivery Charge (Real $/mmBtu)
  #
  @. BfDChg=0.0
  WriteDisk(db,"SpInput/BfDChg",BfDChg)

  #
  ########################
  #
  # Biofuel Production O&M Cost Factor (Real $/$/Yr)
  #
  @. BfOF=0.05
  WriteDisk(db,"SpInput/BfOF",BfOF)

  #
  ########################
  #
  # Biofuel Production Subsidy ($/mmBtu)
  #
  @. BfSubsidy=0.0
  WriteDisk(db,"SpInput/BfSubsidy",BfSubsidy)

  #
  ########################
  #
  # Biofuel Production O&M Costs (Real $/mmBtu)
  #
  # Source: "Biofuel_Module_Parameters_Rob_05Jan2015.xlsx"
  # Original Source O&M cost in 2013 CN$/Litre Ethanol
  #
  for area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfUOMC[biofuel,tech,feedstock,area,Yr(2010)]=0.2980/PerLitre
    BfUOMC[biofuel,tech,feedstock,area,Yr(2011)]=0.2367/PerLitre
    BfUOMC[biofuel,tech,feedstock,area,Yr(2012)]=0.1521/PerLitre
    BfUOMC[biofuel,tech,feedstock,area,Yr(2013)]=0.1300/PerLitre
  end

  # Time Series Revised
  for year in Years,area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfUOMC[biofuel,tech,feedstock,area,year]=BfUOMC[biofuel,tech,feedstock,area,year]/xInflationNation[US,Yr(2013)]*xInflationNation[US,year]*
      xExchangeRate[area,year]/xInflation[area,year]
  end

  years=collect(First:Yr(2009))
  for year in years,area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfUOMC[biofuel,tech,feedstock,area,year]=BfUOMC[biofuel,tech,feedstock,area,Yr(2010)]
  end
  years=collect(Yr(2014):Final)
  for year in years,area in Areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels
    BfUOMC[biofuel,tech,feedstock,area,year]=BfUOMC[biofuel,tech,feedstock,area,Yr(2013)]
  end
  WriteDisk(db,"SpInput/BfUOMC",BfUOMC)

  #
  ########################
  #
  ##### Biofuels Cogeneration
  #
  # Cogeneration Capital Cost ($/mmBtu/Yr)
  #
  ec=Select(EC,"OtherChemicals")
  for year in Years, area in Areas, tech in Techs
    CgCC[tech,area,year]=ICgCC[tech,ec,area,year]
  end
  WriteDisk(db,"SpInput/CgCC",CgCC)

  #
  # Cogeneration Capacity Utilization Factor (Btu/Btu)
  # Preliminary Value from Industrial Chemicals CgCUF
  #
  @. CgCUF=0.894
  WriteDisk(db,"SpInput/CgCUF",CgCUF)

  #
  # Cogeneration Market Share (Btu/Btu)
  #
  @. CgMSF=0.0
  WriteDisk(db,"SpInput/CgMSF",CgMSF)

  #
  # Cogeneration Operation Cost Fraction ($/Yr/$)
  #
  @. CgOF=0.05
  WriteDisk(db,"SpInput/CgOF",CgOF)

  #
  # Cogeneration Equipment Lifetime (Years)
  # Preliminary value from Industrial CgPL
  #
  @. CgPL=25.0
  WriteDisk(db,"SpInput/CgPL",CgPL)


end

function CalibrationControl(db)
  @info "EthanolBiodiesel.jl - CalibrationControl"

  SCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
