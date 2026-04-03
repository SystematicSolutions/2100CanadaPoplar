#
# E2020EnergyIntensity.jl
#
using EnergyModel

module E2020EnergyIntensity

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
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMDS::SetArray = ReadDisk(db,"KInput/ECCTOMDS")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db, "KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  EInt::VariableArray{4} = ReadDisk(db,"KOutput/EInt") # [FuelTOM,ECCTOM,AreaTOM,Year] TOM Energy Intensity (mmBtu/2017$M)
  EIntE::VariableArray{4} = ReadDisk(db,"KOutput/EIntE") # [FuelTOM,ECCTOM,AreaTOM,Year] Energy Intensity (mmBtu/2017$M)
  ENe::VariableArray{4} = ReadDisk(db,"KOutput/ENe") # [FuelTOM,ECCTOM,AreaTOM,Year] E2020 to TOM Energy Demands (TBtu/Yr)
  GrossDemands::VariableArray{4} = ReadDisk(db,"KOutput/GrossDemands") # [Fuel,ECC,Area,Year] Gross Energy Demands (TBtu/Yr)
  GYinto::VariableArray{3} = ReadDisk(db,"KOutput/GYinto") # [ECCTOM,AreaTOM,Year] Gross Output for TOM Inputs (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapAreaTOMNation::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOMNation") # [AreaTOM,Nation]  Map between AreaTOM and Nation (Map)
  MapFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (2017 $M/Yr)

  # Scratch Variables
end

function EIntensity(db)
   data = MControl(; db)
  (;Area,AreaTOM,AreaTOMs,Areas,ECC,ECCDS) = data
  (;ECCs,ECCTOM,ECCTOMs,Fuel) = data
  (;FuelTOM,FuelTOMs,Fuels,Nation,ToTOMVariable,Year,Years) = data
  (;Driver,EInt,EIntE,ENe,GrossDemands,GYinto,IsActiveToECCTOM) = data
  (;MapAreaTOM,MapAreaTOMNation,MapFuelTOM,xGO) = data

  totomvariable = Select(ToTOMVariable,"EIntE")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)

  #
  # Commercial and industrial sectors, excluding transport, oil gas extraction, and electric utility
  #
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fueltom in FuelTOMs
    @finite_math EIntE[fueltom,ecctom,areatom,year] = ENe[fueltom,ecctom,areatom,year]/
        GYinto[ecctom,areatom,year]*1000
  end

  for areatom in AreaTOMs
    area = Select(Area,AreaTOM[areatom])

    #
    # Exception: Petroleum industry driven by RPP production, not gross output
    #
    eccs = Select(ECC,"Petroleum")
    ecctoms = Select(ECCTOM,["PetroleumRefinery","PetroleumExRefinery"])
    for year in Years, ecctom in ecctoms, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,ecctom,areatom,year] = 
        sum(sum(GrossDemands[fuel,ecc,area,year]*MapFuelTOM[fuel,fueltom] for fuel in Fuels)/
        Driver[ecc,area,year] for ecc in eccs)
    end

    #
    # Exception: Oil and Gas industry driven by OG production, not gross output
    # Exclude OilSandsUpgraders, GasProcessing, and LNG production
    # Note:  Added back in OilSandsUpgraders (maybe temporarily) 05/01/25 R.Levesque
    #
    OilGasExtraction = Select(ECCTOM,"OilGasExtraction")
    eccs_1 = Select(ECC,(from="LightOilMining",to="OilSandsMining"))
    eccs_2 = Select(ECC,["OilSandsUpgraders","ConventionalGasProduction","UnconventionalGasProduction"])
    eccs = union(eccs_1,eccs_2)
    for year in Years, fueltom in FuelTOMs
      EIntE[fueltom,OilGasExtraction,areatom,year] = 0.0
    end
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,OilGasExtraction,areatom,year] = sum(GrossDemands[fuel,ecc,area,year]*
        MapFuelTOM[fuel,fueltom] for fuel in Fuels, ecc in eccs)/
          sum(Driver[ecc,area,year] for ecc in eccs)
    end

    #
    # Revisit what conventional and non-conventional oil and gas production intensities should be
    #
    OilGasConventional = Select(ECCTOM,"OilGasConventional")
    eccs = Select(ECC,["LightOilMining","HeavyOilMining","FrontierOilMining","ConventionalGasProduction","UnconventionalGasProduction"])
    for year in Years, fueltom in FuelTOMs
      EIntE[fueltom,OilGasConventional,areatom,year] = 0.0
    end
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,OilGasConventional,areatom,year] = sum(GrossDemands[fuel,ecc,area,year]*
        MapFuelTOM[fuel,fueltom] for fuel in Fuels, ecc in eccs)/
          sum(Driver[ecc,area,year] for ecc in eccs)
    end

    OilGasNonConventional = Select(ECCTOM,"OilGasNonConventional")
    eccs = Select(ECC,["PrimaryOilSands","SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders"])
    for year in Years, fueltom in FuelTOMs
      EIntE[fueltom,OilGasNonConventional,areatom,year] = 0.0
    end
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,OilGasNonConventional,areatom,year] = sum(GrossDemands[fuel,ecc,area,year]*
        MapFuelTOM[fuel,fueltom] for fuel in Fuels, ecc in eccs)/
          sum(Driver[ecc,area,year] for ecc in eccs)
    end
        
    #
    # Exception: Coal Mining driven by coal production
    #
    eccs = Select(ECC,"CoalMining")
    CoalMining = Select(ECCTOM,"CoalMining")
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,CoalMining,areatom,year] = sum(sum(GrossDemands[fuel,ecc,area,year]*
        MapFuelTOM[fuel,fueltom] for fuel in Fuels)/Driver[ecc,area,year] for ecc in eccs)
    end

    #
    # Exception: NGDistribution, OilPipeline, NGPipeline are driven by production
    #
    eccs = Select(ECC,"NGDistribution")
    NGDistribution = Select(ECCTOM,"NGDistribution")
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,NGDistribution,areatom,year] = sum(sum(GrossDemands[fuel,ecc,area,year]*
         MapFuelTOM[fuel,fueltom] for fuel in Fuels)/Driver[ecc,area,year] for ecc in eccs)
    end

    eccs = Select(ECC,"OilPipeline")
    OilPipeline = Select(ECCTOM,"OilPipeline")
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,OilPipeline,areatom,year] = sum(sum(GrossDemands[fuel,ecc,area,year]*
        MapFuelTOM[fuel,fueltom] for fuel in Fuels)/Driver[ecc,area,year] for ecc in eccs)
    end

    eccs = Select(ECC,"NGPipeline")
    NGPipeline = Select(ECCTOM,"NGPipeline")
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,NGPipeline,areatom,year] = sum(sum(GrossDemands[fuel,ecc,area,year]*
          MapFuelTOM[fuel,fueltom] for fuel in Fuels)/Driver[ecc,area,year] for ecc in eccs)
    end

    #
    # Exception: Electric utility sector driver is electric generation
    #
    ecc = Select(ECC,"UtilityGen")
    UtilityGen = Select(ECCTOM,"UtilityGen")

    #
    # Convert Driver from GWh to TBtu
    #
    for year in Years
      Driver[ecc,area,year] = Driver[ecc,area,year]*3412/1000000
    end
    for year in Years, fueltom in FuelTOMs
      @finite_math EIntE[fueltom,UtilityGen,areatom,year] = ENe[fueltom,UtilityGen,areatom,year]/
          Driver[ecc,area,year]
    end

    #
    # 1986's driver is 0; assign 1986 intensity equal to 1987
    #
    for fueltom in FuelTOMs
      EIntE[fueltom,UtilityGen,areatom,Yr(1986)] = EIntE[fueltom,UtilityGen,areatom,Yr(1987)]
    end
  end #areatom

  #*********************
  #
  # Patch BC electric (Aluminum MMETA) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,"Aluminum")
  fueltoms = Select(FuelTOM,"Electric")
  areatoms = Select(AreaTOM,"BC")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in fueltoms
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch MB (Aluminum MMETA) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,"Aluminum")
  areatoms = Select(AreaTOM,"MB")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch NB (CopperMining EMMC) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,"CopperMining")
  areatoms = Select(AreaTOM,"NB")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch NB and NS (NGPipeline TPG) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,"NGPipeline")
  areatoms = Select(AreaTOM,["NB","NS"])
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Zero out Newfoundland Petroleum Refinery (per note from Mike)
  #
  areatoms = Select(AreaTOM,"NL")
  ecctoms = Select(ECCTOM,"PetroleumRefinery")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch NS (Coal Mining EMC)
  #
  ecctoms = Select(ECCTOM,"CoalMining")
  areatoms = Select(AreaTOM,"NS")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch NT (Forestry AF)
  #
  ecctoms = Select(ECCTOM,"Forestry")
  areatoms = Select(AreaTOM,"NT")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch NT (Food MF) electricty and natural gas
  #
  ecctoms = Select(ECCTOM,"Food")
  fueltoms = Select(FuelTOM,["Electric","NaturalGas"])
  areatoms = Select(AreaTOM,"NT")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in fueltoms
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch NT (NonMetallic MNMAO)
  #
  ecctoms = Select(ECCTOM,"NonMetallic")
  areatoms = Select(AreaTOM,"NT")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch PE (Rubber MRUBP)
  #
  ecctoms = Select(ECCTOM,"Rubber")
  areatoms = Select(AreaTOM,"PE")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch SK (NGPipeline TPG) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,"NGPipeline")
  areatoms = Select(AreaTOM,"SK")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch YT (Forestry AF) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,"Forestry")
  areatoms = Select(AreaTOM,"YT")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch YT (Lumber MW) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,"Lumber")
  areatoms = Select(AreaTOM,"YT")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch US Areas (Forestry AF) 5/5/25 R.Levesque (per Mike)
  #
  US = Select(Nation,"US")
  areatoms = findall(MapAreaTOMNation[AreaTOMs,US] .== 1)
  ecctoms = Select(ECCTOM,"Forestry")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Patch WNC Areas (IronOreMining EMMI to NonMetalMining EMN) 5/5/25 R.Levesque (per Mike)
  #
  ecctoms = Select(ECCTOM,(from="IronOreMining",to="NonMetalMining"))
  areatoms = Select(AreaTOM,"WNC")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  #
  # Additional patches for Tanoak that were not in Spruce. 6/24/25 R.Levesque
  #
  ecctoms = Select(ECCTOM,["BasicChemical","OtherChemicalsOrganic"])
  areatoms = Select(AreaTOM,"NL")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in FuelTOMs
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end
  
  #
  # Yukon Territory - patch Diesel, Agriculture industries (per Michelle) 6/25/25 R.Levesque
  #
  ecctoms = Select(ECCTOM,["CropEnergy","AnimalEnergy","Fishing","AgForestrySupport"])
  areatoms = Select(AreaTOM,"YT")
  fueltoms = Select(FuelTOM,"Diesel")
  for year in Years, areatom in areatoms, ecctom in ecctoms, fueltom in fueltoms
    EIntE[fueltom,ecctom,areatom,year] = EInt[fueltom,ecctom,areatom,year]
  end

  WriteDisk(db,"KOutput/EIntE",EIntE)

end

function Control(db)
  @info "E2020EnergyIntensity.jl - Control"
  EIntensity(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
