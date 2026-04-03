#
# E2020EnergyDemandRes.jl
#
using EnergyModel

module E2020EnergyDemandRes

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct ControlData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  AreaTOM::SetArray = ReadDisk(db,"KInput/AreaTOMKey")
  AreaTOMs::Vector{Int} = collect(Select(AreaTOM))
  Areas::Vector{Int} = collect(Select(Area))

  ResEC::SetArray = ReadDisk(db,"RInput/ECKey")
  ResECDS::SetArray = ReadDisk(db,"RInput/ECDS")
  ResECs::Vector{Int} = collect(Select(ResEC))
  ResEnduse::SetArray = ReadDisk(db,"RInput/EnduseKey")
  ResEnduseDS::SetArray = ReadDisk(db,"RInput/EnduseDS")
  ResEnduses::Vector{Int} = collect(Select(ResEnduse))
  ResTech::SetArray = ReadDisk(db,"RInput/TechKey")
  ResTechDS::SetArray = ReadDisk(db,"RInput/TechDS")
  ResTechs::Vector{Int} = collect(Select(ResTech))

  ResEnergyTOM::SetArray = ReadDisk(db,"KInput/ResEnergyTOMKey")
  ResEnergyTOMs::Vector{Int} = collect(Select(ResEnergyTOM))

  TransEC::SetArray = ReadDisk(db,"TInput/ECKey")
  TransECDS::SetArray = ReadDisk(db,"TInput/ECDS")
  TransECs::Vector{Int} = collect(Select(TransEC))
  TransEnduse::SetArray = ReadDisk(db,"TInput/EnduseKey")
  TransEnduseDS::SetArray = ReadDisk(db,"TInput/EnduseDS")
  TransEnduses::Vector{Int} = collect(Select(TransEnduse))
  TransTech::SetArray = ReadDisk(db,"TInput/TechKey")
  TransTechDS::SetArray = ReadDisk(db,"TInput/TechDS")
  TransTechs::Vector{Int} = collect(Select(TransTech))

  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  EnRes::VariableArray{3} = ReadDisk(db,"KOutput/EnRes") # [ResEnergyTOM,AreaTOM,Year] Residential Energy from TOM, including Transportation (TBtu)
  EnResE::VariableArray{3} = ReadDisk(db,"KOutput/EnResE") # [ResEnergyTOM,AreaTOM,Year] E2020toTOMResidential Energy Costs including Transportation (2017 $M/Yr)
  HouseholdLDVFraction::VariableArray{2} = ReadDisk(db,"KInput/HouseholdLDVFraction") # [Area,Year] Fraction of LDV/LDT Investments from Households (vs Fleet) (Btu/Btu)
  MapAreaTOM::VariableArray{2} = ReadDisk(db,"KInput/MapAreaTOM") # [Area,AreaTOM] Map between Area and AreaTOM
  ResCgDmd::VariableArray{4} = ReadDisk(db,"ROutput/CgDmd") # [Tech,EC,Area,Year] Cogeneration Energy Demand (TBtu/Yr)
  ResDmd::VariableArray{5} = ReadDisk(db,"ROutput/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  TransDmd::VariableArray{5} = ReadDisk(db,"TOutput/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)

  # Scratch Variables
  HouseholdTransportEnergy::VariableArray{3} = zeros(Float32,length(ResEnergyTOM),length(AreaTOM),length(Year)) # [ResEnergyTOM,AreaTOM,Year] Transportation Portion of Residential Demand (TBtu)
  ResDmdArea::VariableArray{3} = zeros(Float32,length(ResEnergyTOM),length(Area),length(Year))
end

function InitializeEnergy(data)
  (; Area,AreaTOMs,ResEnergyTOMs,Years) = data
  (; EnResE) = data

  for year in Years, areatom in AreaTOMs, resenergytom in ResEnergyTOMs
    EnResE[resenergytom,areatom,year] = 0
  end
end

function ResDemands(data,resenergytom,restechs)
  (; Area,AreaTOM,AreaTOMs,Areas,ResECs,ResEnduses,ResEnergyTOM,ResEnergyTOMs,Years) = data
  (; ResCgDmd,ResDmd,ResDmdArea,EnResE,MapAreaTOM) = data

  for year in Years, area in Areas
    ResDmdArea[resenergytom,area,year] = sum(ResDmd[enduse,tech,ec,area,year]
      for enduse in ResEnduses,tech in restechs, ec in ResECs)+
      sum(ResCgDmd[tech,ec,area,year] for tech in restechs, ec in ResECs)
  end
  for year in Years, areatom in AreaTOMs
    EnResE[resenergytom,areatom,year] = sum(ResDmdArea[resenergytom,area,year]*
        MapAreaTOM[area,areatom] for area in Areas)
    #
    # Trap very small values 6/24/25 R.Levesque
    #
    if EnResE[resenergytom,areatom,year] < 1e-7
      EnResE[resenergytom,areatom,year] = 0.0
    end
  end
end

function ResFuelMap(data)
  (; ResEnergyTOM,ResEnergyTOMs,ResTech) = data

  resenergytom = Select(ResEnergyTOM,"ResBiofuel")
  techs = Select(ResTech,"Biomass")
  ResDemands(data,resenergytom,techs)

  resenergytom = Select(ResEnergyTOM,"ResCoal")
  techs = Select(ResTech,"Coal")
  ResDemands(data,resenergytom,techs)

  resenergytom = Select(ResEnergyTOM,"ResElectric")
  techs = Select(ResTech,["Electric","Geothermal","HeatPump"])
  ResDemands(data,resenergytom,techs)

  resenergytom = Select(ResEnergyTOM,"ResFuelOil")
  techs = Select(ResTech,"Oil")
  ResDemands(data,resenergytom,techs)

  resenergytom = Select(ResEnergyTOM,"ResLPG")
  techs = Select(ResTech,"LPG")
  ResDemands(data,resenergytom,techs)

  resenergytom = Select(ResEnergyTOM,"ResNaturalGas")
  techs = Select(ResTech,["Gas","FuelCell"])
  ResDemands(data,resenergytom,techs)

  resenergytom = Select(ResEnergyTOM,"ResRenewable")
  techs = Select(ResTech,"Solar")
  ResDemands(data,resenergytom,techs)

  resenergytom = Select(ResEnergyTOM,"ResSteam")
  techs = Select(ResTech,"Steam")
  ResDemands(data,resenergytom,techs)
end

function MapEnergyDemandRes(data)
  (; EnResE) = data

  InitializeEnergy(data)
  ResFuelMap(data)

end

#
# Transportation Demands Assigned to Residential
#
function ResTransportDemands(data,resenergytom,transtechs)
  (; db) = data
  (; Area,Areas,AreaTOM,AreaTOMs,ResEnergyTOM,TransECs,TransEnduses,Years) = data
  (; TransDmd,HouseholdLDVFraction,HouseholdTransportEnergy,MapAreaTOM) = data

  #
  # Residential transportation is HouseholdLDVFraction of LDV and LDT demands; rest is fleet.
  #
  for year in Years, areatom in AreaTOMs
    HouseholdTransportEnergy[resenergytom,areatom,year] = sum(TransDmd[enduse,tech,ec,area,year]*
      HouseholdLDVFraction[area,year]*MapAreaTOM[area,areatom] for enduse in TransEnduses, tech in transtechs, ec in TransECs, area in Areas)
  end

end # ResTransportDemands

#
#######################
#
function MCycleDemands(data,resenergytom,transtechs)
  (; Areas,AreaTOMs,TransECs,TransEnduses,Years) = data
  (; HouseholdTransportEnergy,TransDmd,MapAreaTOM) = data

  #
  # 100% of motorcyle energy demands are included in residential
  #
  for year in Years, areatom in AreaTOMs
    HouseholdTransportEnergy[resenergytom,areatom,year] = HouseholdTransportEnergy[resenergytom,areatom,year]+
      sum(TransDmd[enduse,tech,ec,area,year]*
        MapAreaTOM[area,areatom] for enduse in TransEnduses, tech in transtechs, ec in TransECs, area in Areas)

    if HouseholdTransportEnergy[resenergytom,areatom,year] < 1e-7
      HouseholdTransportEnergy[resenergytom,areatom,year] = 0.0
    end
  end
end

#
########################
#
function MapHHTransportation(data)
  (; Areas,AreaTOMs,TransECs,TransEnduses,ResEnergyTOM,ResEnergyTOMs,TransTech,Years) = data
  (; TransDmd,EnResE,HouseholdLDVFraction,HouseholdTransportEnergy,MapAreaTOM) = data

  resenergytom  = Select(ResEnergyTOM,"TransDiesel")
  techs = Select(TransTech,["LDVDiesel","LDTDiesel"])
  ResTransportDemands(data,resenergytom,techs)

  resenergytom  = Select(ResEnergyTOM,"TransElectric")
  techs = Select(TransTech,["LDVElectric","LDTElectric"])
  ResTransportDemands(data,resenergytom,techs)

  resenergytom  = Select(ResEnergyTOM,"TransGasoline")
  techs = Select(TransTech,["LDVGasoline","LDTGasoline","LDVHybrid","LDTHybrid"])
  ResTransportDemands(data,resenergytom,techs)

  resenergytom  = Select(ResEnergyTOM,"TransLPG")
  techs = Select(TransTech,["LDVPropane","LDTPropane"])
  ResTransportDemands(data,resenergytom,techs)

  resenergytom  = Select(ResEnergyTOM,"TransNaturalGas")
  techs = Select(TransTech,["LDVNaturalGas","LDTNaturalGas"])
  ResTransportDemands(data,resenergytom,techs)

  resenergytom  = Select(ResEnergyTOM,"TransGasoline")
  techs = Select(TransTech,"Motorcycle")
  MCycleDemands(data,resenergytom,techs)

  #
  # Household Transportation Demand Added to Residential Demands
  #
  for year in Years, areatom in AreaTOMs, resenergytom in ResEnergyTOMs
    EnResE[resenergytom,areatom,year] = EnResE[resenergytom,areatom,year] +
      HouseholdTransportEnergy[resenergytom,areatom,year]
  end

end

function PatchValues(data)
  (; AreaTOM,ResEnergyTOM,Years,) = data
  (; EnRes,EnResE) = data

  #
  # Patch California in 2050 to match Spruce. Remove this patch later (in Redwood). 06/24/25 R.Levesque
  #
  CA = Select(AreaTOM,"CA")
  TransElectric = Select(ResEnergyTOM,"TransElectric")
  EnResE[TransElectric,CA,Yr(2050)] = EnRes[TransElectric,CA,Yr(2050)]

end

function Control(db)
  data = ControlData(; db)
  (; EnResE) = data
  @info "E2020EnergyDemandRes.jl - Control"

  MapEnergyDemandRes(data)
  MapHHTransportation(data)
  PatchValues(data)

  WriteDisk(db,"KOutput/EnResE",EnResE)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
