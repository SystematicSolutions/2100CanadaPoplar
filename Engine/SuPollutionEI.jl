#
# SuPollutionEI.jl
#

module SuPollutionEI

import ...EnergyModel: ReadDisk,WriteDisk,Select,MaxTime,HisTime
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))

  Biofuel::SetArray = ReadDisk(db,"MainDB/BiofuelKey")
  Biofuels::Vector{Int} = collect(Select(Biofuel))

  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))

  EIType::SetArray = ReadDisk(db,"MainDB/EITypeKey")
  EITypes::Vector{Int} = collect(Select(EIType))

  Feedstock::SetArray = ReadDisk(db,"MainDB/FeedstockKey")
  Feedstocks::Vector{Int} = collect(Select(Feedstock))

  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))

  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))

  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int} = collect(Select(Nation))

  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))

  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  Polls::Vector{Int} = collect(Select(Poll))

  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))

  Tech::SetArray = ReadDisk(db,"SInput/TechKey")
  Techs::Vector{Int} = collect(Select(Tech))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  BfPol::VariableArray{4} = ReadDisk(db,"SpOutput/BfPol",year) #[FuelEP,Biofuel,Poll,Area,Year]  Biofuel Production Pollution (Tonnes/Yr)
  BfProd::VariableArray{4} = ReadDisk(db,"SpOutput/BfProd",year) #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production (TBtu/Yr)
  CAProd::VariableArray{1} = ReadDisk(db,"SOutput/CAProd",year) #[Area,Year]  Primary Coal Production (TBtu/Yr)
  CgDemand::VariableArray{3} = ReadDisk(db,"SOutput/CgDemand",year) #[Fuel,ECC,Area,Year]  Cogeneration Demands (TBtu/Yr)
  CombustionEmissions::VariableArray{3} = ReadDisk(db,"SOutput/CombustionEmissions",year) #[Fuel,ECC,Area,Year]  Combustion Emissions (Tonnes)
  EAProd::VariableArray{2} = ReadDisk(db,"SOutput/EAProd",year) #[Plant,Area,Year]  Electric Utility Production (GWh/Yr)
  EI::VariableArray{3} = ReadDisk(db,"SOutput/EI",year) #[EIType,Fuel,Area,Year]  Emission Intensity (Tonnes/TBtu)
  EICFS::VariableArray{2} = ReadDisk(db,"SOutput/EICFS",year) #[Fuel,Area,Year]  Emission Intensity (Tonnes/TBtu)
  EICFSPrior::VariableArray{2} = ReadDisk(db,"SOutput/EICFS",prior) #[Fuel,Area,Prior]  Emission Intensity in Previous Year (Tonnes/TBtu)
  EIDomestic::VariableArray{2} = ReadDisk(db,"SOutput/EIDomestic",year) #[Fuel,Area,Year]  Emission Intensity for Domestic Fuels (Tonnes/TBtu)
  EIImports::VariableArray{2} = ReadDisk(db,"SOutput/EIImports",year) #[Fuel,Area,Year]  Emission Intensity for Imported Fuels (Tonnes/TBtu)
  EINation::VariableArray{3} = ReadDisk(db,"SOutput/EINation",year) #[EIType,Fuel,Nation,Year]  Emission Intensity (Tonnes/TBtu)
  EISector::VariableArray{2} = ReadDisk(db,"SOutput/EISector",year) #[ECC,Area,Year]  Sector Emission Intensity (Tonnes/TBtu)
  EISectorN::VariableArray{2} = ReadDisk(db,"SOutput/EISectorN",year) #[ECC,Nation,Year]  Sector Emission Intensity (Tonnes/TBtu)
  EuFPol::VariableArray{4} = ReadDisk(db,"SOutput/EuFPol",year) #[FuelEP,ECC,Poll,Area,Year]  Energy Related Pollution (Tonnes/Yr)
  EuPol::VariableArray{3} = ReadDisk(db,"SOutput/EuPol",year) #[ECC,Poll,Area,Year]  Energy Related Pollution (Tonnes/Yr)
  EuDemand::VariableArray{3} = ReadDisk(db,"SOutput/EuDemand",year) #[Fuel,ECC,Area,Year]  Enduse Energy Demands (TBtu/Yr)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") #[FuelEP,Fuel]  Map between FuelEP and Fuel
  FlPol::VariableArray{3} = ReadDisk(db,"SOutput/FlPol",year) #[ECC,Poll,Area,Year]  Flaring Pollution (Tonnes/Yr)
  FuPol::VariableArray{3} = ReadDisk(db,"SOutput/FuPol",year) #[ECC,Poll,Area,Year]  Other Fugitive Emissions (Tonnes/Yr)
  GAProd::VariableArray{2} = ReadDisk(db,"SOutput/GAProd",year) #[Process,Area,Year]  Primary Gas Production (TBtu/Yr)
  GasProductionMap::VariableArray{1} = ReadDisk(db,"SpInput/GasProductionMap") #[Process]  Gas Production Map (1=include)
  ImportsFraction::VariableArray{2} = ReadDisk(db,"SOutput/ImportsFraction",year) #[Fuel,Area,Year]  Fraction of Energy Imported (Btu/Btu)
  MEPol::VariableArray{3} = ReadDisk(db,"SOutput/MEPol",year) #[ECC,Poll,Area,Year]  Non-Energy Pollution (Tonnes/Yr)
  NcPol::VariableArray{3} = ReadDisk(db,"SOutput/NcPol",year) #[ECC,Poll,Area,Year]  Non-Combustion Pollution (Tonnes/Yr)
  OAProd::VariableArray{2} = ReadDisk(db,"SOutput/OAProd",year) #[Process,Area,Year]  Primary Oil Production (TBtu/Yr)
  ORMEPol::VariableArray{3} = ReadDisk(db,"SOutput/ORMEPol",year) #[ECC,Poll,Area,Year]  Non-Energy Off Road Pollution (Tonnes/year)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") #[Poll]  Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  ProductionEmissions::VariableArray{2} = ReadDisk(db,"SOutput/ProductionEmissions",year) #[ECC,Area,Year]  Fuel Production Emissions (Tonnes/Yr)
  PSoECC::VariableArray{2} = ReadDisk(db,"SOutput/PSoECC",year) #[ECC,Area,Year]  Power Sold to Grid (GWh)
  RPPAProd::VariableArray{1} = ReadDisk(db,"SpOutput/RPPAProd",year) #[Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)
  RPPMap::VariableArray{1} = ReadDisk(db,"SInput/RPPMap") #[Area]  Pointer between RPP Demands and Refineries
  SqPol::VariableArray{3} = ReadDisk(db,"SOutput/SqPol",year) #[ECC,Poll,Area,Year]  Sequestering Emissions (Tonnes/Yr)
  StDemand::VariableArray{1} = ReadDisk(db,"SOutput/StDemand",year) #[Area,Year]  Demand for Steam (TBtu/Yr)
  VnPol::VariableArray{3} = ReadDisk(db,"SOutput/VnPol",year) #[ECC,Poll,Area,Year]  Venting Pollution (Tonnes/Yr)
  xEI::VariableArray{3} = ReadDisk(db,"SInput/xEI",year) #[EIType,Fuel,Area,Year]  Emission Intensity (Tonnes/TBtu)
  xEINation::VariableArray{3} = ReadDisk(db,"SInput/xEINation",year) #[EIType,Fuel,Nation,Year]  Emission Intensity (Tonnes/TBtu)
  xEISector::VariableArray{2} = ReadDisk(db,"SInput/xEISector",year) #[ECC,Area,Year]  Sector Emission Intensity (Tonnes/TBtu)
end

function EmissionsFromCombustion(data::Data,ghg)
  (; Areas,ECCs,Fuel,Fuels,FuelEPs) = data #sets
  (; CombustionEmissions,EuFPol,FFPMap,PolConv,EuDemand,CgDemand,PSoECC,EICFSPrior) = data

  # @info "  SuPollutionEI.jl - EmissionsFromCombustion"

  #
  # Default is only Direct Emissions, not LCA Emissions
  #
  for area in Areas, ecc in ECCs, fuel in Fuels
    CombustionEmissions[fuel,ecc,area] = sum(EuFPol[fuelep,ecc,poll,area]*
                                       FFPMap[fuelep,fuel]*PolConv[poll] for poll in ghg, fuelep in FuelEPs)
  end

  #
  # LCA Emissions for Electricity only for now
  #
    for area in Areas, ecc in ECCs, fuel in Select(Fuel,"Electric")
    CombustionEmissions[fuel,ecc,area] = (EuDemand[fuel,ecc,area]+CgDemand[fuel,ecc,area]-PSoECC[ecc,area]*3412/1e6)*EICFSPrior[fuel,area]
  end

  for area in Areas, ecc in ECCs, fuel in Select(Fuel, "Steam")
    CombustionEmissions[fuel,ecc,area] = (EuDemand[fuel,ecc,area]+CgDemand[fuel,ecc,area])*EICFSPrior[fuel,area]
  end

end

function EmissionsFromProduction(data::Data,ghg)
  (; Areas,ECCs,Fuels) = data #sets
  (; ProductionEmissions,CombustionEmissions,NcPol,MEPol,PolConv,VnPol,FlPol,FuPol,ORMEPol,SqPol) = data

  # @info "  SuPollutionEI.jl - EmissionsFromCombustion"

  for area in Areas, ecc in ECCs
    ProductionEmissions[ecc,area] = sum(CombustionEmissions[fuel,ecc,area] for fuel in Fuels)+
                                  sum(NcPol[ecc,poll,area]*PolConv[poll] for poll in ghg)+
                                  sum(MEPol[ecc,poll,area]*PolConv[poll] for poll in ghg)+
                                  sum(VnPol[ecc,poll,area]*PolConv[poll] for poll in ghg)+
                                  sum(FlPol[ecc,poll,area]*PolConv[poll] for poll in ghg)+
                                  sum(FuPol[ecc,poll,area]*PolConv[poll] for poll in ghg)+
                                  sum(ORMEPol[ecc,poll,area]*PolConv[poll] for poll in ghg)+
                                  sum(SqPol[ecc,poll,area]*PolConv[poll] for poll in ghg)
  end

end

function ExogenousEI(data::Data,ghg)
  (; Areas,ECCs,EITypes,Fuels,Nations) = data #sets
  (; EI,EINation,EISector,xEI,xEINation,xEISector) = data

  # @info "  SuPollutionEI.jl - EmissionsFromCombustion"

  for area in Areas, fuel in Fuels, type in EITypes
    EI[type,fuel,area] = xEI[type,fuel,area]
  end

  for nation in Nations, fuel in Fuels, type in EITypes
    EINation[type,fuel,nation] = xEINation[type,fuel,nation]
  end

  for area in Areas, ecc in ECCs
    EISector[ecc,area] = xEISector[ecc,area]
  end

end

function OilProductionEI(data::Data,ghg,nation,areas)
  (; ECC,EIType,Fuel,Process,Processes) = data #sets
  (; EI,EINation,EISector,EISectorN,OAProd,ProductionEmissions) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))
  OProdTotal::VariableArray = zeros(Float32,length(Process))

  # @info "  SuPollutionEI.jl - OilProductionEI"

  oileccs = Select(ECC,["LightOilMining","HeavyOilMining","FrontierOilMining","PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders"])
  production = Select(EIType,"Production")
  oilfuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel","Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy","PetroFeed","PetroCoke","StillGas"])

  for ecc in oileccs, process in Processes
    if Process[process] == ECC[ecc]

      for area in areas
        @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/OAProd[process,area]/1.000
      end

      ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
      OProdTotal[process] = sum(OAProd[process,area] for area in areas)

      @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/
                            OProdTotal[process]/1.000
    end
  end

  #
  # Try using national average for fuel EI - Ian
  #
  oilprocesses = Select(Process,(from = "LightOilMining",to = "OilSandsUpgraders"))

  for nation in nation, fuel in oilfuels, type in production
    PETotal = sum(ProductionEmissions[ecc,area] for area in areas, ecc in oileccs)
    OAPTotal = sum(OAProd[process,area] for area in areas, process in oilprocesses)
    @finite_math EINation[type,fuel,nation] = PETotal/
                                 OAPTotal/1.000
    for area in areas
      EI[type,fuel,area] = EINation[type,fuel,nation]
    end
  end

end

function OilRefiningEI(data::Data,ghg,nation,areas)
  (; ECC,EIType,Fuel) = data #sets
  (; EI,EINation,EISector,EISectorN,ProductionEmissions,RPPAProd,RPPMap) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))

  # @info "  SuPollutionEI.jl - OilRefiningEI"

  refeccs = Select(ECC,"Petroleum")
  processing = Select(EIType,"Processing")
  oilfuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel","Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy","PetroFeed","PetroCoke","StillGas"])

  for ecc in refeccs
    for area in areas
      @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/RPPAProd[area]/1.000
    end

    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    RPPAProdTotal = sum(RPPAProd[area] for area in areas)

    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/RPPAProdTotal/1.000
  end

  for area in areas, ecc in refeccs
    if (EISector == 0) && (RPPMap > 0)
      rpparea = RPPMap[area]
      EISector[ecc,area] = EISector[ecc,rpparea]
    end
  end

  for ecc in refeccs, fuel in oilfuels, type in processing
    for area in areas
      EI[type,fuel,area] = EISector[ecc,area]
    end

    EINation[type,fuel,nation] = EISectorN[ecc,nation]
  end

end

function OilPipelineEI(data::Data,ghg,nation,areas)
  (; ECC,EIType,Fuel) = data #sets
  (; EI,EINation,EISector,EISectorN,ProductionEmissions,RPPAProd) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))

  # @info "  SuPollutionEI.jl - OilRefiningEI"

  pipeeccs = Select(ECC,"OilPipeline")
  transport = Select(EIType,"Transportation")
  oilfuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel","Kerosene","LFO","LPG","Lubricants","Naphtha","NonEnergy","PetroFeed","PetroCoke","StillGas"])

  for ecc in pipeeccs
    for area in areas
      @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/RPPAProd[area]/1.000
    end

    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    RPPAProdTotal = sum(RPPAProd[area] for area in areas)

    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/RPPAProdTotal/1.000
  end

  for nation in nation, ecc in pipeeccs, area in areas, fuel in oilfuels, type in transport
    EI[type,fuel,area] = EI[type,fuel,area]+EISectorN[ecc,nation]
  end

  for nation in nation, ecc in pipeeccs, fuel in oilfuels, type in transport
    EINation[type,fuel,nation] = EINation[type,fuel,nation]+EISectorN[ecc,nation]
  end

end

function BiofuelProductionEI(data::Data,ghg,nation,areas)
  (; Area,Biofuel,Biofuels,ECC,EIType,Feedstocks,Fuel,FuelEPs,Techs) = data #sets
  (; BfPol,BfProd,EI,EINation,EISector,PolConv) = data
  BfPolATotal::VariableArray = zeros(Float32,length(Area))
  BfProdATotal::VariableArray = zeros(Float32,length(Area))

  # @info "  SuPollutionEI.jl - BiofuelProductionEI"

  bfeccs = Select(ECC,"BiofuelProduction")
  processing = Select(EIType,"Processing")


  for area in areas, ecc in bfeccs
    BfPolATotal[area] = sum(BfPol[fuelep,biofuel,poll,area]*PolConv[poll] for poll in ghg, biofuel in Biofuels, fuelep in FuelEPs)
    BfProdATotal[area] = sum(BfProd[biofuel,tech,feedstock,area] for feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)
    @finite_math EISector[ecc,area] = BfPolATotal[area]/BfProdATotal[area]/1.000
  end

  biofuelbiodiesel = Select(Biofuel,"Biodiesel")
  fuelbiodiesel = Select(Fuel,"Biodiesel")

  for area in areas, fuel in fuelbiodiesel, type in processing
    BfPolATotal[area] = sum(BfPol[fuelep,biofuelbiodiesel,poll,area]*PolConv[poll] for poll in ghg, fuelep in FuelEPs)
    BfProdATotal[area] = sum(BfProd[biofuelbiodiesel,tech,feedstock,area] for feedstock in Feedstocks, tech in Techs)
    @finite_math EI[type,fuel,area] = BfPolATotal[area]/BfProdATotal[area]/1.000
  end

  for nation in nation, fuel in fuelbiodiesel, type in processing
    BfPolTot = sum(BfPol[fuelep,biofuelbiodiesel,poll,area]*PolConv[poll] for area in areas, poll in ghg, fuelep in FuelEPs)
    BfProdTotal = sum(BfProd[biofuelbiodiesel,tech,feedstock,area] for area in areas, feedstock in Feedstocks, tech in Techs)
    @finite_math EINation[type,fuel,nation]=BfPolTot/BfProdTotal/1.000
  end

  #
  # Fill in values for areas with no production
  #
  for area in areas, fuel in fuelbiodiesel, type in processing
    if EI[type,fuel,area] == 0.0
      EI[type,fuel,area] = EINation[type,fuel,nation]
    end
  end

  #####

  biofuelethanol = Select(Biofuel,"Ethanol")
  fuelethanol = Select(Fuel,"Ethanol")

  for area in areas, fuel in fuelethanol, type in processing
    BfPolATotal[area] = sum(BfPol[fuelep,biofuelethanol,poll,area]*PolConv[poll] for poll in ghg, fuelep in FuelEPs)
    BfProdATotal[area] = sum(BfProd[biofuelethanol,tech,feedstock,area] for feedstock in Feedstocks, tech in Techs)
    @finite_math EI[type,fuel,area] = BfPolATotal[area]/BfProdATotal[area]/1.000
  end

  for nation in nation, fuel in fuelethanol, type in processing
    BfPolTot = sum(BfPol[fuelep,biofuelethanol,poll,area]*PolConv[poll] for area in areas, poll in ghg, fuelep in FuelEPs)
    BfProdTotal = sum(BfProd[biofuelethanol,tech,feedstock,area] for area in areas, feedstock in Feedstocks, tech in Techs)
    @finite_math EINation[type,fuel,nation]=BfPolTot/BfProdTotal/1.000
  end

  #
  # Fill in values for areas with no production
  #
  for area in areas, fuel in fuelethanol, type in processing
    if EI[type,fuel,area] == 0.0
      EI[type,fuel,area] = EINation[type,fuel,nation]
    end
  end

end

function NGProductionEI(data::Data,ghg,nation,areas)
  (; ECC,EIType,Fuel,Process,Processes) = data #sets
  (; EI,EINation,EISector,EISectorN,GAProd,ProductionEmissions) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))
  GProdTotal::VariableArray = zeros(Float32,length(Process))

  # @info "  SuPollutionEI.jl - NGProductionEI"

  gaseccs = Select(ECC,["ConventionalGasProduction","UnconventionalGasProduction"])
  production = Select(EIType,"Production")
  gasfuels = Select(Fuel,["NaturalGas","NaturalGasRaw"])


  for ecc in gaseccs, process in Processes
    if Process[process] == ECC[ecc]

    for area in areas
      @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/GAProd[process,area]/1.000
    end

    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    GProdTotal[process] = sum(GAProd[process,area] for area in areas)

    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/
                                 GProdTotal[process]/1.000
    end
  end

  gasprocesses = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction"])

  for nation in nation, fuel in gasfuels, type in production
    PETotal = sum(ProductionEmissions[ecc,area] for area in areas, ecc in gaseccs)
    GAPTotal = sum(GAProd[process,area] for area in areas, process in gasprocesses)
    @finite_math EINation[type,fuel,nation] = PETotal/
                               GAPTotal/1.000
    for area in areas
      EI[type,fuel,area] = EINation[type,fuel,nation]
    end
  end

end

function NGProcessingEI(data::Data,ghg,nation,areas)
  (; Area,ECC,EIType,Fuel,Process,Processes) = data #sets
  (; EI,EINation,EISector,EISectorN,ProductionEmissions,GAProd) = data
  ProdEmissETotal::VariableArray = zeros(Float32,length(ECC))
  GProdPTotal::VariableArray = zeros(Float32,length(Process))
  ProdEmissATotal::VariableArray = zeros(Float32,length(Area))
  GProdATotal::VariableArray = zeros(Float32,length(Area))

  # @info "  SuPollutionEI.jl - NGProcessingEI"

  ngproceccs = Select(ECC,["SweetGasProcessing","SourGasProcessing"])
  processing = Select(EIType,"Processing")
  gasfuels = Select(Fuel,"NaturalGas")

  for ecc in ngproceccs, process in Processes
    if Process[process] == ECC[ecc]

    for area in areas
      @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/GAProd[process,area]/1.000
    end

    ProdEmissETotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    GProdPTotal[process] = sum(GAProd[process,area] for area in areas)

    @finite_math EISectorN[ecc,nation] = ProdEmissETotal[ecc]/
                                 GProdPTotal[process]/1.000
    end
  end

  # 23.08.28, LJD: Promula appears to not select a subset of Process for EI and EINation

  # gasprocprocesses = Select(Process,["ConventionalGasProduction","UnconventionalGasProduction"])

  for fuel in gasfuels, type in processing
    for area in areas
      ProdEmissATotal[area] = sum(ProductionEmissions[ecc,area] for ecc in ngproceccs)
      GProdATotal[area] = sum(GAProd[process,area] for process in Processes)
      @finite_math EI[type,fuel,area] = ProdEmissATotal[area]/GProdATotal[area]/1.000
    end

    for nation in nation
      PETotal = sum(ProductionEmissions[ecc,area] for area in areas, ecc in ngproceccs)
      GAPTotal = sum(GAProd[process,area] for area in areas, process in Processes)
      GAPTotal = 1.0
      @finite_math EINation[type,fuel,nation] = PETotal/
                                 GAPTotal/1.000
    end

  end

end

function NGPipelineEI(data::Data,ghg,nation,areas)
  (; ECC,EIType,Fuel,Processes) = data #sets
  (; EI,EINation,EISector,EISectorN,GAProd,GasProductionMap,ProductionEmissions) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))

  # @info "  SuPollutionEI.jl - OilRefiningEI"

  pipeeccs = Select(ECC,"NGPipeline")
  transport = Select(EIType,"Transportation")
  gasfuels = Select(Fuel,"NaturalGas")

  for ecc in pipeeccs
    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    GAPTotal = sum(GAProd[process,area]*GasProductionMap[process] for area in areas, process in Processes)
    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/GAPTotal/1.000

    for area in areas
      EISector[ecc,area] = EISectorN[ecc,nation]
    end
  end

  for nation in nation, ecc in pipeeccs, area in areas, fuel in gasfuels, type in transport
    EI[type,fuel,area] = EI[type,fuel,area]+EISectorN[ecc,nation]
  end

  for nation in nation, ecc in pipeeccs, fuel in gasfuels, type in transport
    EINation[type,fuel,nation] = EINation[type,fuel,nation]+EISectorN[ecc,nation]
  end

end

function NGDistributionEI(data::Data,ghg,nation,areas)
  (; Area,ECC,EIType,Fuel) = data #sets
  (; CgDemand,EI,EINation,EISector,EISectorN,EuDemand,ProductionEmissions) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))
  NGDemand::VariableArray = zeros(Float32,length(Area))

  # @info "  SuPollutionEI.jl - NGDistributionEI"

  distroeccs = Select(ECC,"NGDistribution")
  transport = Select(EIType,"Transportation")
  gasfuels = Select(Fuel,"NaturalGas")

  nonutility = Select(ECC, !=("Utility Electric Generation"))

  for area in areas
    NGDemand[area] = sum(EuDemand[gasfuels,ecc,area]+CgDemand[gasfuels,ecc,area] for ecc in nonutility)
  end

  for ecc in distroeccs
    for area in areas
      @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/NGDemand[area]/1.000
    end

    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    NGDTotal = sum(NGDemand[area] for area in areas)

    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/NGDTotal/1.000
  end

  for area in areas, fuel in gasfuels, type in transport, ecc in distroeccs
    EI[type,fuel,area] = EI[type,fuel,area]+EISector[ecc,area]
  end

  #
  # 23.08.28, LJD: Possible Promula glitch, with EINation based on EISector rather 
  #   than EISectorN, with multiple areas selected
  #
  # EINation=EINation+EISector
  #

  for nation in nation, fuel in gasfuels, type in transport, ecc in distroeccs
    EINation[type,fuel,nation] = EINation[type,fuel,nation]+EISectorN[ecc,nation]
  end

end

function NGPatchEI(data::Data,ghg,nation,areas)
  (; EITypes,Fuel) = data #sets
  (; EI,EINation) = data

  # @info "  SuPollutionEI.jl - NGPatchEI"

  for area in areas, fuel in Select(Fuel, "NaturalGas"), type in EITypes
    EI[type,fuel,area] = EINation[type,fuel,nation]
  end

end

function CoalMiningEI(data::Data,ghg,nation,areas)
  (; ECC,EIType,Fuel) = data #sets
  (; CAProd,EI,EINation,EISector,EISectorN,ProductionEmissions) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))

  # @info "  SuPollutionEI.jl - CoalMiningEI"

  coaleccs = Select(ECC,"CoalMining")
  production = Select(EIType,"Production")
  coalfuels = Select(Fuel,["Coal","Coke","CokeOvenGas"])

  for area in areas, ecc in coaleccs
    @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/CAProd[area]/1.000
  end

  for nation in nation, ecc in coaleccs
    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    CAPTotal = sum(CAProd[area] for area in areas)
    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/CAPTotal/1.000
  end

  for ecc in coaleccs, area in areas, fuel in coalfuels, type in production
    EI[type,fuel,area] = EISectorN[ecc,nation]
  end

  for ecc in coaleccs, nation in nation, fuel in coalfuels, type in production
    EINation[type,fuel,nation] = EISectorN[ecc,nation]
  end

end

function ElectricityProductionEI(data::Data,ghg,nation,areas)
  (; Area,ECC,EIType,Fuel,Plants) = data #sets
  (; EAProd,EI,EINation,EISector,EISectorN,ProductionEmissions) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))
  EAProdTotal::VariableArray = zeros(Float32,length(Area))

  # @info "  SuPollutionEI.jl - ElectricityProductionEI"

  utilityeccs = Select(ECC,"UtilityGen")
  production = Select(EIType,"Production")
  electricfuels = Select(Fuel,"Electric")

  for area in areas, ecc in utilityeccs
    EAProdTotal[area] = sum(EAProd[plant,area]*3412/1e6 for plant in Plants)
    @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/EAProdTotal[area]/1.000
  end

  for nation in nation, ecc in utilityeccs
    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    EAPTotal = sum(EAProd[plant,area]*3412/1e6 for area in areas, plant in Plants)
    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/EAPTotal/1.000
  end

  for ecc in utilityeccs, area in areas, fuel in electricfuels, type in production
    EI[type,fuel,area] = EISector[ecc,area]
  end

  for ecc in utilityeccs, nation in nation, fuel in electricfuels, type in production
    EINation[type,fuel,nation] = EISectorN[ecc,nation]
  end

end

function SteamProductionEI(data::Data,ghg,nation,areas)
  (; ECC,EIType,Fuel) = data #sets
  (; EI,EINation,EISector,EISectorN,ProductionEmissions,StDemand) = data
  ProdEmissTotal::VariableArray = zeros(Float32,length(ECC))

  # @info "  SuPollutionEI.jl - SteamProductionEI"

  steameccs = Select(ECC,"Steam")
  production = Select(EIType,"Production")
  steamfuels = Select(Fuel,"Steam")

  for area in areas, ecc in steameccs
    @finite_math EISector[ecc,area] = ProductionEmissions[ecc,area]/StDemand[area]/1.000
  end

  for nation in nation, ecc in steameccs
    ProdEmissTotal[ecc] = sum(ProductionEmissions[ecc,area] for area in areas)
    SteamTotal = sum(StDemand[area] for area in areas)
    @finite_math EISectorN[ecc,nation] = ProdEmissTotal[ecc]/SteamTotal/1.000
  end

  for ecc in steameccs, area in areas, fuel in steamfuels, type in production
    EI[type,fuel,area] = EISector[ecc,area]
  end

  for ecc in steameccs, nation in nation, fuel in steamfuels, type in production
    EINation[type,fuel,nation] = EISectorN[ecc,nation]
  end

end

function CombustionEI(data::Data,ghg,nation,areas)
  (; Area,ECCs,EIType,Fuel,Fuels,FuelEPs) = data #sets
  (; CgDemand,EI,EINation,EuFPol,EuDemand,FFPMap,PolConv) = data
  
  CombPolFATotal::VariableArray = zeros(Float32,length(Fuel),length(Area))
  CombDemandFATotal::VariableArray = zeros(Float32,length(Fuel),length(Area))
  CombPolFTotal::VariableArray = zeros(Float32,length(Fuel))
  CombDemandFTotal::VariableArray = zeros(Float32,length(Fuel))

  # @info "  SuPollutionEI.jl - CombustionEI"
  
  eitype = Select(EIType,"Combustion")

  for area in areas, fuel in Fuels
    CombPolFATotal[fuel,area] = sum(EuFPol[fuelep,ecc,poll,area]*FFPMap[fuelep,fuel]*PolConv[poll]
      for poll in ghg, ecc in ECCs, fuelep in FuelEPs)
    CombDemandFATotal[fuel,area] = sum((EuDemand[fuel,ecc,area]+CgDemand[fuel,ecc,area])
      for ecc in ECCs)
    @finite_math EI[eitype,fuel,area] = CombPolFATotal[fuel,area]/CombDemandFATotal[fuel,area]/1.000
  end

  for nation in nation, fuel in Fuels
    CombPolFTotal[fuel] = sum(EuFPol[fuelep,ecc,poll,area]*FFPMap[fuelep,fuel]*PolConv[poll]
      for area in areas, poll in ghg, ecc in ECCs, fuelep in FuelEPs)
    CombDemandFTotal[fuel] = sum((EuDemand[fuel,ecc,area]+CgDemand[fuel,ecc,area])
      for area in areas, ecc in ECCs)
    @finite_math EINation[eitype,fuel,nation] = CombPolFTotal[fuel]/CombDemandFTotal[fuel]/1.000
  end

end

function ApplyNationalToMissingValues(data::Data,ghg,nation,areas)
  (; EITypes,Fuel) = data #sets
  (; EI,EINation) = data

  # @info "  SuPollutionEI.jl - ApplyNationalToMissingValues"

  #
  # If EIType is zero for a combination of Area/Fuel/EIType then
  # set it equal to the national average.
  #
  for area in areas, fuel in Select(Fuel,"NaturalGas"), type in EITypes
    if EI[type,fuel,area] == 0.0
      EI[type,fuel,area] = EINation[type,fuel,nation]
    end
  end

end

function ImportsEI(data::Data,ghg,nation,areas)
  (; EITypes,Fuels) = data #sets
  (; EIImports,EINation) = data

  # @info "  SuPollutionEI.jl - ImportsEI"

  #
  # Assume imports have the same EI as nation value until data is available
  #
  for area in areas, fuel in Fuels,
    EIImports[fuel,area] = sum(EINation[type,fuel,nation] for type in EITypes)
  end

end

function TotalEI(data::Data,ghg,nation,areas)
  (; EITypes,Fuels) = data #sets
  (; EI,EICFS,EIDomestic,EIImports,ImportsFraction) = data

  # @info "  SuPollutionEI.jl - TotalEI"

  for area in areas, fuel in Fuels,
    EIDomestic[fuel,area] = sum(EI[type,fuel,area] for type in EITypes)

    EICFS[fuel,area] = EIDomestic[fuel,area]*(1-ImportsFraction[fuel,area])+EIImports[fuel,area]*ImportsFraction[fuel,area]
  end

end

function WriteOutputs(data::Data,ghg)
  (; db,year) = data
  (; CombustionEmissions,EI,EICFS,EIDomestic,EIImports,EINation,EISector,EISectorN,ProductionEmissions) = data

  # @info "  SuPollutionEI.jl - WriteOutputs"

  WriteDisk(db,"SOutput/CombustionEmissions",year,CombustionEmissions)
  WriteDisk(db,"SOutput/EI",year,EI)
  WriteDisk(db,"SOutput/EICFS",year,EICFS)
  WriteDisk(db,"SOutput/EIDomestic",year,EIDomestic)
  WriteDisk(db,"SOutput/EIImports",year,EIImports)
  WriteDisk(db,"SOutput/EINation",year,EINation)
  WriteDisk(db,"SOutput/EISector",year,EISector)
  WriteDisk(db,"SOutput/EISectorN",year,EISectorN)
  WriteDisk(db,"SOutput/ProductionEmissions",year,ProductionEmissions)

end

function Control(data::Data)
  (; Nations,Poll) = data #sets
  (; ANMap) = data

  # @info "  SuPollutionEI.jl - Control"

  ghg = Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])

  EmissionsFromCombustion(data,ghg)
  EmissionsFromProduction(data,ghg)
  ExogenousEI(data,ghg)


  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)

    OilProductionEI(data,ghg,nation,areas)
    OilRefiningEI(data,ghg,nation,areas)
    OilPipelineEI(data,ghg,nation,areas)
    BiofuelProductionEI(data,ghg,nation,areas)
    NGProductionEI(data,ghg,nation,areas)
    NGProcessingEI(data,ghg,nation,areas)
    NGPipelineEI(data,ghg,nation,areas)
    NGDistributionEI(data,ghg,nation,areas)
    NGPatchEI(data,ghg,nation,areas)
    CoalMiningEI(data,ghg,nation,areas)
    ElectricityProductionEI(data,ghg,nation,areas)
    SteamProductionEI(data,ghg,nation,areas)
    CombustionEI(data,ghg,nation,areas)
    ApplyNationalToMissingValues(data,ghg,nation,areas)
    ImportsEI(data,ghg,nation,areas)
    TotalEI(data,ghg,nation,areas)
  end

  WriteOutputs(data,ghg)
    
end # function Control

end # module SuPollutionEI
