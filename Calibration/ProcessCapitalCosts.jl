#
# ProcessCapitalCosts.jl
#
using EnergyModel

module ProcessCapitalCosts

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xPCC::VariableArray{5} = ReadDisk(db,"$Input/xPCC") # [Enduse,Tech,EC,Area,Year] Process Capital Cost (Real $/Driver/Yr)

  # Scratch Variables
  PCapCost::VariableArray{2} = zeros(Float32,length(Area),length(EC)) # [EC,Area] Process Capital Cost (Various $/Driver/Yr)
end

function RCalibration(db)
  data = RControl(; db)
  (;Input) = data
  (;Area,Techs,EC,ECs,Enduses,Nation,Years) = data
  (;ANMap,xInflation,xPCC) = data
  (;PCapCost) = data

  #
  # Canada Residential Driver is Floor Space so xPCC is read
  # in as 1985 CN$/Sq Meter and converted to 1985 Local$/Sq Ft
  #
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  ecs = Select(EC,["SingleFamilyDetached","MultiFamily"])
  PCapCost[areas,ecs] .= [
  #/CN      643.32  608.28
  #=ON=#    655.50  644.14
  #=QC=#    614.87  610.97
  #=BC=#    595.81  638.82
  #=AB=#    663.07  420.51
  #=MB=#    638.17  785.92
  #=SK=#    622.09  415.05
  #=NB=#    580.76  617.19
  #=NS=#    565.97  680.71
  #=NL=#    872.63  294.68
  #=PEI=#   496.93  435.38
  #=YT=#    414.00 4878.71
  #=NT=#    414.00 4878.71
  #=NU=#    414.00 4878.71
  ]

  #
  # Territories and NL MultiFamily values look like an outliers so replace
  # with Canada value. Jeff Amlin 11/07/08.
  #
  areas = Select(Area,["YT","NT","NU","NL"])
  MultiFamily = Select(EC,"MultiFamily")
  for area in areas 
    PCapCost[area,MultiFamily] = 608.28
  end

  #
  # Territories SF values look like an outliers so replace with Canada value.
  # Jeff Amlin 11/07/08.
  #
  areas = Select(Area,["YT","NT","NU"])
  SingleFamilyDetached = Select(EC,"SingleFamilyDetached")
  for area in areas 
    PCapCost[area,SingleFamilyDetached] = 643.32
  end

  #
  # Select Areas in Canada
  #
  areas = findall(ANMap[:,CN] .== 1.0)

  #
  # Use 60% of Single Family for Other Family. Jeff Amlin 11/07/08.
  #
  OtherResidential = Select(EC,"OtherResidential")
  SingleFamilyAttached= Select(EC,"SingleFamilyAttached")
  for area in areas   
    PCapCost[area,OtherResidential] = PCapCost[area,SingleFamilyDetached]
    PCapCost[area,SingleFamilyAttached] = PCapCost[area,SingleFamilyDetached]
  end

  #
  # Convert from $/Sq Meter to $/Sq Ft
  #
  for year in Years, area in areas, ec in ECs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = PCapCost[area,ec] / 10.7639 / xInflation[area,Yr(1985)]
  end

  #
  # Average US house sale price in Sept 1985 was 1985 US$102,600 per US Census data 
  # - Ian 07/15/15
  #
  US = Select(Nation,"US")
  areas = findall(ANMap[:,US] .== 1.0)
  for year in Years, area in areas, ec in ECs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = 102600 / 1e6 / xInflation[area,Yr(1985)]
  end

  WriteDisk(db,"$Input/xPCC",xPCC)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
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

  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xPCC::VariableArray{5} = ReadDisk(db,"$Input/xPCC") # [Enduse,Tech,EC,Area,Year] Process Capital Cost ($/Driver/Yr)

  # Scratch Variables
  PCapCost::VariableArray{1} = zeros(Float32,length(EC)) # [EC] Process Capital Cost (Various $/Driver/Yr)
end

function CCalibration(db)
  data = CControl(; db)
  (;Input) = data
  (;Areas,Techs,Enduses,Years,ECs,EC) = data
  (;xExchangeRate,xInflation,xPCC) = data
  (;PCapCost) = data

  #
  # Values updated with general estimates of cost per sq foot of commercial
  # construction. 1985 US$40 per sqft is used for Offices with
  # other sectors split out proportionally based on differences from
  # original data - Ian 11/17/14
  #
  ecs = Select(EC,(from = "Wholesale",to ="OtherCommercial"))
  PCapCost[ecs] = [
  #=Wholesale=#                  22.451
  #=Retail=#                     19.093
  #=Warehouse=#                  19.065
  #=Information=#                31.425
  #=Offices=#                    20.000
  #=Education=#                  3.298
  #=Health=#                     9.981
  #=OtherCommercial=#            18.258
  ]

  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses 
    xPCC[enduse,tech,ec,area,year] = PCapCost[ec] * xExchangeRate[area,Yr(1985)] / xInflation[area,Yr(1985)]
  end

  WriteDisk(db,"$Input/xPCC",xPCC)

end

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
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

  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xExchangeRateNation::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRateNation") # [Nation,Year] Local Currency/US\$ Exchange Rate (Local/US\$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xPCC::VariableArray{5} = ReadDisk(db,"$Input/xPCC") # [Enduse,Tech,EC,Area,Year] Process Capital Cost ($/Driver/Yr)

  # Scratch Variables
  PCapCost::VariableArray{1} = zeros(Float32,length(EC)) # [EC,Area] Process Capital Cost
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;Areas,EC,ECs,Enduses,Years,Techs,Nation) = data
  (;xExchangeRate,xExchangeRateNation,xInflation,xPCC) = data
  (;PCapCost) = data

  #
  # The process capital cost (xPCC) is the cost of capital (housing, 
  # buildings, factories, facilities) per unit of economic driver.  The
  # economic driver may be in dollars (personal income or gross output)
  # or physcal units (TBtu of oil or gas production).
  #
  # The capital cost per dollar of gross output data are from
  # the US I/O Tables by REMI in 1987 US$ per 1987 US$ of Gross Output
  #
  PCapCost[ECs] = [
  #=Food & Tobacco       =#  0.5446
  #=TextilesApparelLea   =#  0.3193
  #=Lumber               =#  0.3403 
  #=Furniture            =#  0.3313 
  #=Pulp and Paper       =#  0.4328 
  #=Petrochemicals       =#  0.5373 
  #=Industrial Gas       =#  0.5373 
  #=Other Basic Chem     =#  0.5373 
  #=Fertilizers          =#  0.5373 
  #=Petroleum Products   =#  0.6255
  #=Rubber               =#  0.3548 
  #=Cement               =#  0.3756
  #=Glass                =#  0.3756
  #=Lime & Gypsum        =#  0.3756
  #=Other Non-Metallic   =#  0.3756
  #=Iron & Steel         =#  0.2257
  #=Aluminum             =#  0.2257
  #=Other Nonferrous     =#  0.2257
  #=Transport Equipment  =#  0.3209 
  #=Other Manufacturing  =#  0.3534 
  #=Iron Ore Mining      =#  0.6775 
  #=Other Metal Mining   =#  0.6775 
  #=Non-metal Mining     =#  0.6775 
  #=Light Oil Mining     =#  0.6775 
  #=Heavy Oil Mining     =#  0.6775 
  #=Frontier Oil Mining  =#  0.6775 
  #=Primary Oil Sands    =#  0.6775 
  #=SAGD Oil Sands       =#  0.6775 
  #=CSS Oil Sands        =#  0.6775 
  #=Oil Sands Mining     =#  0.6775 
  #=Oil Sands Upgraders  =#  0.6775 
  #=Conv. Gas Production =#  0.6775 
  #=Sweet Gas Processing =#  0.6775 
  #=UnConv Gas Production=#  0.6775 
  #=Sour Gas Processing  =#  0.6775 
  #=LNG Production       =#  0.6775 
  #=Coal Mining          =#  0.6775 
  #=Construction         =#  0.3410
  #=Forestry             =#  0.2108 
  #=On Farm Fuel Use     =#  0.2108 
  #=Crop Production      =#  0.2108 
  #=Animal Production    =#  0.2108   
  ]
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = PCapCost[ec]
  end

  #
  # Oil Sands Capital Costs (2010 CN$/TBtu/Yr) - use SAGD costs from CERI 
  # report for all Oil Sands except Oil Sands Mining.
  # Source: CERI Report, Table 3.1 via "Design Assumptions from CERI
  # Report.xlsx" - Jeff Amlin 11/13/12
  # 
  # Using SAGDOilSands as dummy for LNG Production
  #
  CN = Select(Nation,"CN")
  ecs = Select(EC,["PrimaryOilSands","SAGDOilSands","CSSOilSands","LNGProduction"])
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = 20.13 / xExchangeRateNation[CN,Yr(2010)] * xExchangeRate[area,Yr(2010)] /
                           xInflation[area,Yr(2010)] 
  end

  ecs = Select(EC,"OilSandsMining")
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = 38.71 / xExchangeRateNation[CN,Yr(2010)] * xExchangeRate[area,Yr(2010)] /
                           xInflation[area,Yr(2010)] 
  end

  ecs = Select(EC,"OilSandsUpgraders")
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = 26.54 / xExchangeRateNation[CN,Yr(2010)] * xExchangeRate[area,Yr(2010)] /
                           xInflation[area,Yr(2010)] 
  end

  #
  # Conventional Oil Capital Cost estimate - Jeff Amlin 11/13/12
  #
  ecs = Select(EC,["LightOilMining","HeavyOilMining","FrontierOilMining"])
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = 25.00 / xExchangeRateNation[CN,Yr(2010)] * xExchangeRate[area,Yr(2010)] /
                           xInflation[area,Yr(2010)] 
  end

  #
  # Natural Gas capital costs (2010 CN$/TBtu/Yr) based on Western Canada average 
  # supply costs. Source: Energy Briefing Note (Nov. 2010), Figure 6.
  # - Luke Davulis 11-6-2012
  #
  ecs = Select(EC,["ConventionalGasProduction","UnconventionalGasProduction"])
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = (6.35+1.15) / xExchangeRateNation[CN,Yr(2010)] * xExchangeRate[area,Yr(2010)] /
                           xInflation[area,Yr(2010)] 
  end

  ecs = Select(EC,["SweetGasProcessing","SourGasProcessing"])
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = (6.35+1.15) / xExchangeRateNation[CN,Yr(2010)] * xExchangeRate[area,Yr(2010)] /
                           xInflation[area,Yr(2010)] 
  end

  WriteDisk(db,"$Input/xPCC",xPCC)

end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
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

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xExchangeRate::VariableArray{2} = ReadDisk(db,"MInput/xExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xPCC::VariableArray{5} = ReadDisk(db,"$Input/xPCC") # [Enduse,Tech,EC,Area,Year] Process Capital Cost ($/Driver/Yr)

  #
  # Scratch Variables
  #
  PCapCost::VariableArray{2} = zeros(Float32,length(Tech),length(EC)) # [EC,Area] Process Capital Cost
end

function TCalibration(db)
  data = TControl(; db)
  (;Input) = data
  (;Areas,EC,ECs,Enduses) = data
  (;Techs,Years) = data
  (;PCapCost,xExchangeRate,xInflation,xPCC) = data
  
  #
  # The data was developed from the US I/O Tables by REMI in $1987 from
  # the MassachuSetss Energy Office model.
  #
  # PCAPCost(Res)=1.930
  # PCAPCost(Com)=0.345
  # PCAPCost(Ind)=0.562
  #
  # The historical process capital cost is used to initialize the model.
  # It is defined as the current dollar of capital stock (housing) per 
  # unit of the Driver.
  # P. Cross 7/19/94.
  
  PCapCost[Techs,ECs] = [
  #/                                                                   Res   Com   
  #/                                 Pas   Frt   PasA  PasF ForA  ForF OfR   OfR   
  #=LightGasoline          =#       1.93 0.345     0    0     0    0 0.562 0.562 
  #=LightDiesel            =#       1.93 0.345     0    0     0    0 0.562 0.562 
  #=LightPropane           =#       1.93 0.345     0    0     0    0     0     0 
  #=LightCNG               =#       1.93 0.345     0    0     0    0     0     0 
  #=LightElectric          =#       1.93 0.345     0    0     0    0     0     0 
  #=LightEthanol           =#       1.93 0.345     0    0     0    0     0     0 
  #=LightHybridGasoline    =#       1.93 0.345     0    0     0    0     0     0 
  #=LightFuelCellGasoline  =#       1.93 0.345     0    0     0    0     0     0 
  #=MediumGasoline         =#       1.93 0.562     0    0     0    0 0.562 0.562 
  #=MediumDiesel           =#       1.93 0.562     0    0     0    0 0.562 0.562 
  #=MediumPropane          =#       1.93 0.562     0    0     0    0     0     0 
  #=MediumCNG              =#       1.93 0.562     0    0     0    0     0     0 
  #=MediumEthanol          =#       1.93 0.562     0    0     0    0     0     0 
  #=MediumHybridGasoline   =#       1.93 0.562     0    0     0    0     0     0 
  #=MediumFuelCellGasoline =#       1.93 0.562     0    0     0    0     0     0 
  #=Motorcycle             =#       1.93     0     0    0     0    0     0     0 
  #=BusGasoline            =#      0.345     0     0    0     0    0     0     0 
  #=BusDiesel              =#      0.345     0     0    0     0    0     0     0 
  #=BusPropane             =#      0.345     0     0    0     0    0     0     0 
  #=BusCNG                 =#      0.345     0     0    0     0    0     0     0 
  #=BusElectric            =#       1.93 0.345     0    0     0    0 0.345 0.345 
  #=BusFuelCell            =#      0.345     0     0    0     0    0     0     0 
  #=TrainDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=TrainElectric          =#       1.93 0.345     0    0     0    0 0.345 0.345 
  #=TrainFuelCel           =#       1.93 0.345     0    0     0    0 0.345 0.345 
  #=Plane                  =#      0.345     0 0.345    0 0.345    0     0     0 
  #=Plane                  =#      0.345     0 0.345    0 0.345    0     0     0 
  #=Plane                  =#      0.345     0 0.345    0 0.345    0     0     0 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyGasoline          =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=HeavyDiesel            =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=MarineDiesel           =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=MarineHFO              =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=MarineFuelCell         =#      0.345 0.562     0    0     0    0 0.562 0.562 
  #=Unknown                =#          0     0     0    0     0    0     0     0 
  #=Unknown                =#          0     0     0    0     0    0     0     0 
  ]
  
  for year in Years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = PCapCost[tech,ec]*
      xExchangeRate[area,Yr(1987)]/xInflation[area,Yr(1987)]
  end

  #
  # Only use the Passenger numbers
  #
  ecs = Select(EC,(from = "Freight",to = "CommercialOffRoad"))
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = 0
  end
  
  #
  # TODODevelopment: xPCC is zero for Passenger because the definition
  # of PCapCost doesn't match the Read statement in Banyan/Walnut version
  # Setting it to zero below to match for now - Ian 10/16/24
  # We can only change this after we analysze the impact on the 
  # tranportation demand forecast - Jeff Amlin 10/16/24
  #
  ecs = Select(EC,"Passenger")
  for year in Years, area in Areas, ec in ecs, tech in Techs, enduse in Enduses
    xPCC[enduse,tech,ec,area,year] = 0
  end
  
  WriteDisk(db,"$Input/xPCC",xPCC)
  
end

function CalibrationControl(db)
  @info "ProcessCapitalCosts.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
