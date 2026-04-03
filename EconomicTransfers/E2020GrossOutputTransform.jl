#
# E2020GrossOutputTransform.jl
#

using EnergyModel

module E2020GrossOutputTransform

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
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMDS::SetArray = ReadDisk(db,"KInput/FuelTOMDS")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GrossDemands::VariableArray{4} = ReadDisk(db,"KOutput/GrossDemands") # [Fuel,ECC,Area,Year] Energy Demands (TBtu/Yr)
  GYAdjust::VariableArray{3} = ReadDisk(db,"KOutput/GYAdjust")  # [ECCTOM,AreaTOM,Year] Gross Output from TOM, Adjusted (2017 $M/Yr)
  GYinto::VariableArray{3} = ReadDisk(db,"KOutput/GYinto") # [ECCTOM,AreaTOM,Year]  Gross Output for TOM Inputs (2017 $M/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM")   # [Area,AreaTOM]  Map between Area and AreaTOM
  MapFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC to TOM ($/$)

  #
  # Scratch Variables
  #
  GYintoTot::VariableArray{2} = zeros(Float32,length(AreaTOM),length(Year)) # [AreaTOM,Year] Total Gross Output for TOM Inputs (2017 $M/Yr)
end

function GrossOutputintoTOM(db)
  data = MControl(; db)
  (; AreaTOM,AreaTOMs,ECCTOM,ECCTOMs,ToTOMVariable,Years) = data
  (; GYAdjust,GYinto,IsActiveToECCTOM) = data

  #
  # GYinto is used to calculate energy intensities for sectors from E2020 into TOM. 
  # We want GYinto to have the gross output associated with the sectors written into TOM.
  #

  totomvariable = Select(ToTOMVariable,"DefaultintoTOM")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    GYinto[ecctom,areatom,year] = GYAdjust[ecctom,areatom,year]
  end

  #
  # Special cases: Several industries, we read in the detail industries' gross output, but write to the top-level sector
  #   These industries are: BasicChemical, NonMetallic, Foundries, Alumimum, and NonferrousMetal
  #
  #   For these industries, we need to total up the detailed industries and put into the top-down
  #   industry for calculating energy intensity for the sectors being sent to TOM, the "into TOM" sectors.
  #
  BasicChemical = Select(ECCTOM,"BasicChemical")
  ecctoms = Select(ECCTOM,["Petrochemicals","IndustrialGas","OtherChemicalsDye","OtherChemicalsInorganic"])
  for year in Years, areatom in AreaTOMs
    GYinto[BasicChemical,areatom,year] = sum(GYAdjust[ecctom,areatom,year] for ecctom in ecctoms)
  end
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    GYinto[ecctom,areatom,year] = 0
  end

  NonMetallic = Select(ECCTOM,"NonMetallic")
  ecctoms = Select(ECCTOM,["Glass","LimeGypsum","OtherNonMetallic","ClayNonMetallic"])
  for year in Years, areatom in AreaTOMs
    GYinto[NonMetallic,areatom,year] = sum(GYAdjust[ecctom,areatom,year] for ecctom in ecctoms)
  end
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    GYinto[ecctom,areatom,year] = 0
  end

  Foundries = Select(ECCTOM,"Foundries")
  ecctoms = Select(ECCTOM,"FerrousFoundries")
  for year in Years, areatom in AreaTOMs
    GYinto[Foundries,areatom,year] = sum(GYAdjust[ecctom,areatom,year] for ecctom in ecctoms)
  end
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    GYinto[ecctom,areatom,year] = 0
  end

  Aluminum = Select(ECCTOM,"Aluminum")
  ecctoms = Select(ECCTOM,["AluminumRolling","AluminumPrimary"])
  for year in Years, areatom in AreaTOMs
    GYinto[Aluminum,areatom,year] = sum(GYAdjust[ecctom,areatom,year] for ecctom in ecctoms)
  end
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    GYinto[ecctom,areatom,year] = 0
  end

  NonferrousMetal = Select(ECCTOM,"NonferrousMetal")
  ecctoms = Select(ECCTOM,["NonferrousFoundries","NonferrousRolling","NonferrousCopper","NonferrousSmelting"])
  for year in Years, areatom in AreaTOMs
    GYinto[NonferrousMetal,areatom,year] = sum(GYAdjust[ecctom,areatom,year] for ecctom in ecctoms)
  end
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms
    GYinto[ecctom,areatom,year] = 0
  end

  WriteDisk(db,"KOutput/GYinto",GYinto)
end #GrossOutputintoTOM

function Control(db)
  @info "GrossOutputTransform.jl - Control"
  GrossOutputintoTOM(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end

