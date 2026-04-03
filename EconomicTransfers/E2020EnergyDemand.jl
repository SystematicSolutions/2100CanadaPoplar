#
# E2020EnergyDemand.jl
#

using EnergyModel

module E2020EnergyDemand

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct MControl
  db::String

  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMDS::SetArray = ReadDisk(db,"KInput/AreaTOMDS")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECCTOM::SetArray = ReadDisk(db,"KInput/ECCTOMKey")
  ECCTOMs::Vector{Int} = collect(Select(ECCTOM))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelTOM::SetArray = ReadDisk(db,"KInput/FuelTOMKey")
  FuelTOMs::Vector{Int} = collect(Select(FuelTOM))
  ToTOMVariable::SetArray = ReadDisk(db,"KInput/ToTOMVariable")
  ToTOMVariables::Vector{Int} = collect(Select(ToTOMVariable))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation

  ENe::VariableArray{4} = ReadDisk(db,"KOutput/ENe") # [FuelTOM,ECCTOM,AreaTOM,Year]  E2020 to TOM Energy Demands (TBtu/Yr)
  GrossDemands::VariableArray{4} = ReadDisk(db,"KOutput/GrossDemands") # [Fuel,ECC,Area,Year]  Gross Energy Demands (TBtu/Yr)
  IsActiveToECCTOM::VariableArray{2} = ReadDisk(db,"KInput/IsActiveToECCTOM") # [ECCTOM,ToTOMVariable] "Flag Indicating Which ECCTOMs to into TOM by Variable"
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  MapFuelTOM::VariableArray{2} = ReadDisk(db,"KInput/MapFuelTOM") # [Fuel,FuelTOM] Map between Fuel and FuelTOM
  SplitECCtoTOM::VariableArray{4} = ReadDisk(db,"KOutput/SplitECCtoTOM") # [ECC,ECCTOM,AreaTOM,Year] Split ECC to ECCTOM ($/$)

  #
  # Scratch Variables
  #
  ENAreaTOM::VariableArray{4} = zeros(Float32,length(Fuel),length(ECC),length(AreaTOM),length(Year))  # E2020 to TOM Energy Demands Mapped to AreaTOM (TBtu/Yr)
  ENFuelTOM::VariableArray{4} = zeros(Float32,length(FuelTOM),length(ECCTOM),length(AreaTOM),length(Year)) # E2020 to TOM Energy Demands Mapped to FuelTOM (TBtu/Yr)
  ENintoTOM::VariableArray{4} = zeros(Float32,length(Fuel),length(ECCTOM),length(AreaTOM),length(Year))  # E2020 to TOM Energy Demands Mapped to ECCTOM (TBtu/Yr)
end

#
########################
#
function EnergyDemandGeneric(db)
  data = MControl(; db)
  (; Areas,AreaTOMs,ECCs,ECCTOMs,Fuels,FuelTOMs,ToTOMVariable,Years) = data
  (; ENAreaTOM,ENe,ENintoTOM,ENFuelTOM,GrossDemands,IsActiveToECCTOM) = data
  (; MapAreaTOM,MapFuelTOM,SplitECCtoTOM) = data

  totomvariable = Select(ToTOMVariable,"DefaultintoTOM")
  ecctoms = findall(IsActiveToECCTOM[:,totomvariable] .== 1)
  
  for year in Years, areatom in AreaTOMs, ecc in ECCs, fuel in Fuels
    ENAreaTOM[fuel,ecc,areatom,year] = 0
  end

  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fuel in Fuels
    ENintoTOM[fuel,ecctom,areatom,year] = 0
  end
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fueltom in FuelTOMs
    ENFuelTOM[fueltom,ecctom,areatom,year] = 0
  end

  for year in Years, areatom in AreaTOMs, ecc in ECCs, fuel in Fuels
    ENAreaTOM[fuel,ecc,areatom,year] = sum(GrossDemands[fuel,ecc,area,year]*
      MapAreaTOM[area,areatom] for area in Areas)
  end

  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fuel in Fuels
    ENintoTOM[fuel,ecctom,areatom,year] = 
      sum(ENAreaTOM[fuel,ecc,areatom,year]*SplitECCtoTOM[ecc,ecctom,areatom,year] for ecc in ECCs)
    end

  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fueltom in FuelTOMs
    ENFuelTOM[fueltom,ecctom,areatom,year] = sum(ENintoTOM[fuel,ecctom,areatom,year]*
      MapFuelTOM[fuel,fueltom] for fuel in Fuels)
  end

  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fueltom in FuelTOMs
    ENe[fueltom,ecctom,areatom,year] = sum(ENFuelTOM[fueltom,ecctom,areatom,year]*
      MapAreaTOM[area,areatom] for area in Areas)
  end

  #
  # Overwrite very small numbers with 0 to match Promula
  #
  for year in Years, areatom in AreaTOMs, ecctom in ecctoms, fueltom in FuelTOMs
    if ENe[fueltom,ecctom,areatom,year] < 1e-9
      ENe[fueltom,ecctom,areatom,year] = 0.0
    end
  end
    
  WriteDisk(db,"KOutput/ENe",ENe)

end # MapEnergyDemand

#
########################
#
function Control(db)
  @info "E2020EnergyDemand.jl - Control"
  EnergyDemandGeneric(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
