#
# CFS_EmissionIntensity.jl
#
using EnergyModel

module CFS_EmissionIntensity

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct SControl
  db::String

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EIType::SetArray = ReadDisk(db,"MainDB/EITypeKey")
  EITypeDS::SetArray = ReadDisk(db,"MainDB/EITypeDS")
  EITypes::Vector{Int} = collect(Select(EIType))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  RPPMap::VariableArray{1} = ReadDisk(db,"SInput/RPPMap") # [Area] Pointer between RPP Demands and Refineries
  xEI::VariableArray{4} = ReadDisk(db,"SInput/xEI") # [EIType,Fuel,Area,Year] Emission Intensity (Tonnes/TBtu)
  xEINation::VariableArray{4} = ReadDisk(db,"SInput/xEINation") # [EIType,Fuel,Nation,Year] Emission Intensity (Tonnes/TBtu)
  
end

function Supply(db)
  data = SControl(; db)
  (;Area,Areas,EIType,EITypes,Fuel,Fuels) = data
  (;Nations,Years) = data
  (;RPPMap,xEI,xEINation) = data
  
  #
  # RPP Map - map is only needed if intensity is zero.
  #
  BC = Select(Area,"BC")
  AB = Select(Area,"AB")
  SK = Select(Area,"SK")
  MB = Select(Area,"MB")
  NB = Select(Area,"NB")
  NS = Select(Area,"NS")
  PE = Select(Area,"PE")
  NT = Select(Area,"NT")
  YT = Select(Area,"YT")
  NU = Select(Area,"NU")  
  #
  RPPMap[MB]=SK
  RPPMap[NS]=NB 
  RPPMap[PE]=NB
  RPPMap[YT]=BC 
  RPPMap[NT]=AB
  RPPMap[NU]=SK
  WriteDisk(db,"SInput/RPPMap",RPPMap)
  
  #
  ########################
  #
  
  #
  # KJBtu    'Kilo Joule per BTU'  
  #
  KJBtu=1.054615
  
  Transportation = Select(EIType,"Transportation")
  Production = Select(EIType,"Production") 
  Processing = Select(EIType,"Processing") 
  Other = Select(EIType,"Other")
  
  #
  # RPP Production Intensity is Crude Oil Intensity
  # source: https://www.arb.ca.gov/fuels/lcfs/background/basics.htm
  #
  fuels = Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline",
                       "HFO","JetFuel","Kerosene","LFO","LPG","Lubricants",
                       "Naphtha","NonEnergy","PetroFeed","PetroCoke","StillGas"])
  for year in Years, area in Areas, fuel in fuels
    xEI[Transportation,fuel,area,year]=1+1 *KJBtu*1000
    xEI[Production,fuel,area,year]    =12  *KJBtu*1000
  end
  
  #
  # Ethanol Production Intensity is Feedstock (Agriculture) minus Co-Products
  # source: https://www.arb.ca.gov/fuels/lcfs/background/basics.htm
  #
  fuel = Select(Fuel,"Ethanol")
  for year in Years, area in Areas
    xEI[Transportation,fuel,area,year]=3+3  *KJBtu*1000
    xEI[Production,fuel,area,year]    =33   *KJBtu*1000
    xEI[Other,fuel,area,year]         =0-13 *KJBtu*1000
  end
  
  #
  # Biodiesel Intensity
  # source: https://www.arb.ca.gov/fuels/lcfs/background/basics.htm
  #
  fuel = Select(Fuel,"Biodiesel")
  for year in Years, area in Areas
    xEI[Transportation,fuel,area,year]=2+2  *KJBtu*1000
    xEI[Production,fuel,area,year]    =1    *KJBtu*1000
    xEI[Other,fuel,area,year]         =5    *KJBtu*1000
  end

  #
  # Biogas Intensity
  # source: https://www.arb.ca.gov/fuels/lcfs/background/basics.htm
  #
  fuel = Select(Fuel,"Biogas")
  for year in Years, area in Areas
    xEI[Transportation,fuel,area,year]=5   *KJBtu*1000
    xEI[Production,fuel,area,year]    =1   *KJBtu*1000
    xEI[Other,fuel,area,year]         =-63 *KJBtu*1000
  end

  #
  # Renewable NG Intensity
  # source: https://www.arb.ca.gov/fuels/lcfs/background/basics.htm
  #
  fuel = Select(Fuel,"RNG")
  for year in Years, area in Areas
    xEI[Transportation,fuel,area,year] = 5  *KJBtu*1000
    xEI[Production,fuel,area,year]     =1   *KJBtu*1000
    xEI[Processing,fuel,area,year]     =19  *KJBtu*1000
    xEI[Other,fuel,area,year]          =-63 *KJBtu*1000
  end

  #
  # Biojet
  # source: https://www.energy.gov/sites/prod/files/2016/09/f33/wang_alternative_aviation_fuel_workshop.pdf
  #
  fuel = Select(Fuel,"Biojet")
  for year in Years, area in Areas
    xEI[Transportation,fuel,area,year] =3  *KJBtu*1000
    xEI[Production,fuel,area,year]     =19 *KJBtu*1000
    xEI[Processing,fuel,area,year]     =19 *KJBtu*1000
  end

  #
  # Hydrogen
  # source: GREET Model Tier 1 Defaults
  #
  fuel = Select(Fuel,"Hydrogen")
  for year in Years, area in Areas
    xEI[Transportation,fuel,area,year]=1  *KJBtu*1000
    xEI[Production,fuel,area,year]    =0  *KJBtu*1000
    xEI[Processing,fuel,area,year]    =0  *KJBtu*1000
  end

  area = 1
  for year in Years, nation in Nations, fuel in Fuels, eitype in EITypes
    xEINation[eitype,fuel,nation,year] = xEI[eitype,fuel,area,year]
  end

  WriteDisk(db,"SInput/xEI",xEI)
  WriteDisk(db,"SInput/xEINation",xEINation) 

end

function Control(db)
  @info "CFS_EmissionIntensity.jl - Control"

  Supply(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
