#
# Ind_MS_P30.jl - Policy Targets for FuelShares - Robin White 12/06/20
# 
# Incremental stock electrification of industry by 2030 - Chemicals & Fertilizers (+2%), Cement (+1%), Pulp and Paper (+2%), Mining OffRoad(+4%), Light Manufacturing (+19%)
# Incremental stock electrification of industry by 2050 - Chemicals & Fertilizers (+5%), Cement (+2%), Pulp and Paper (+5%), Mining OffRoad(+10%), Light Manufacturing (+30%)
#

using EnergyModel

module Ind_MS_P30

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String
  
  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput" 
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

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
  CgPotMult::VariableArray{4} = ReadDisk(db,"$Input/CgPotMult") # [Tech,EC,Area,Year] Cogeneration Potential Multiplier (Btu/Btu)
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF") # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  # Scratch Variables
  Change::VariableArray{1} = zeros(Float64,length(EC))
  xMMSFBSSF::VariableArray{4} = zeros(Float64,length(Enduse),length(EC),length(Area),length(Year))
  xMMSFElectric::VariableArray{4} = zeros(Float64,length(Enduse),length(EC),length(Area),length(Year))
  xMMSFFossil::VariableArray{4} = zeros(Float64,length(Enduse),length(EC),length(Area),length(Year))
  xMMSFNonElectric::VariableArray{4} = zeros(Float64,length(Enduse),length(EC),length(Area),length(Year))
  xMMSFNonFossil::VariableArray{4} = zeros(Float64,length(Enduse),length(EC),length(Area),length(Year))

end

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Input) = data
  (; Area,EC,Enduse,Enduses,Tech) = data 
  (; ANMap,xMMSF) = data
  (; CgPotMult,Change,xMMSFBSSF,xMMSFElectric,xMMSFFossil,xMMSFNonElectric,xMMSFNonFossil) = data

  #
  # Specify values for desired fuel shares (xMMSF)
  #  
  areas = Select(Area,["ON","QC","BC","AB","MB","SK","NB","NS","NL"])
  years = collect(Yr(2025):Yr(2030))

  Change[:].= 0
  ecs = Select(EC,(from = "Petrochemicals", to = "Fertilizer"))
  for ec in ecs
    Change[ec] = 0.18*1.6*1.13
  end

  #
  # P&P needs to account for biomass use, which makes up 50% of energy use
  #  
  ecs = Select(EC,"PulpPaperMills")
  for ec in ecs
    Change[ec] = 0.22*1.6*1.13
  end
  ecs = Select(EC,"Cement")
  for ec in ecs
    Change[ec] = 0.25*1.6*1.13
  end
  ecs1 = Select(EC,(from = "Food", to = "Furniture"))
  ecs2 = Select(EC,["Rubber","Glass","OtherNonMetallic","TransportEquipment","OtherManufacturing"])
  ecs=union(ecs1,ecs2)
  for ec in ecs
    Change[ec] = 0.60*1.6*1.13
  end
  ecs1 = Select(EC,(from = "IronOreMining", to = "NonMetalMining"))
  ecs2 = Select(EC,"CoalMining")
  ecs=union(ecs1,ecs2)
  for ec in ecs
    Change[ec] = 0.22*1.6*1.13
  end

  #
  # Process Heat and Other Substitutables
  #
  enduses = Select(Enduse,["Heat","OthSub"])
  ecs1 = Select(EC,(from = "Petrochemicals", to = "Fertilizer"))
  ecs2 = Select(EC,(from = "Food", to = "Furniture"))
  ecs3 = Select(EC,["PulpPaperMills","Cement","Rubber","Glass","OtherNonMetallic","TransportEquipment","OtherManufacturing"])
  ecs=union(ecs1,ecs2,ecs3)

  techs = Select(Tech,["Biomass","Solar","Steam","FuelCell"])
  for enduse in enduses, ec in ecs, area in areas, year in years
    xMMSFBSSF[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
  end
  techs = Select(Tech,["Electric"])
  for enduse in enduses, ec in ecs, area in areas, year in years, tech in techs
    xMMSF[enduse,tech,ec,area,year] = min(1-xMMSFBSSF[enduse,ec,area,year],xMMSF[enduse,tech,ec,area,year]+Change[ec])
  end

  techs = Select(Tech,["Electric","Biomass","Solar","Steam","FuelCell"])
  for enduse in enduses, ec in ecs, area in areas, year in years
    xMMSFNonFossil[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
  end
  techs = Select(Tech,["Gas","Coal","Oil","LPG","OffRoad"])
  for enduse in enduses, ec in ecs, area in areas, year in years
    xMMSFFossil[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
    for tech in techs
      @finite_math xMMSF[enduse,tech,ec,area,year] = xMMSF[enduse,tech,ec,area,year]/xMMSFFossil[enduse,ec,area,year]*
                                                     (1-(xMMSFNonFossil[enduse,ec,area,year]))
    end
  end
  
  #
  # Off Road
  #
  enduse = Select(Enduse,"OffRoad")
  ecs1 = Select(EC,(from = "Petrochemicals", to = "Fertilizer"))
  ecs2 = Select(EC,(from = "Food", to = "Furniture"))
  ecs3 = Select(EC,(from = "IronOreMining", to = "NonMetalMining"))
  ecs4 = Select(EC,["PulpPaperMills","Cement","Rubber","Glass","OtherNonMetallic","TransportEquipment","OtherManufacturing","CoalMining"])
  ecs=union(ecs1,ecs2,ecs3,ecs4)

  tech = Select(Tech,"Electric")
  for ec in ecs, area in areas, year in years
    xMMSF[enduse,tech,ec,area,year] = Change[ec]
    xMMSFElectric[enduse,ec,area,year] = xMMSF[enduse,tech,ec,area,year]
  end
  techs = Select(Tech,["Gas","Coal","Oil","Biomass","Solar","LPG","OffRoad","Steam","FuelCell"])
  for ec in ecs, area in areas, year in years
    xMMSFNonElectric[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
    for tech in techs
      @finite_math xMMSF[enduse,tech,ec,area,year] = xMMSF[enduse,tech,ec,area,year]/xMMSFNonElectric[enduse,ec,area,year]*
                                                     (1-(xMMSFElectric[enduse,ec,area,year]))
    end
  end

  #
  # Specify values for desired fuel shares (xMMSF)
  #
  years = collect(Yr(2031):Yr(2050))
  Change[:] .= 0

  #
  # Process Heat and Other Substitutables
  #
  enduses = Select(Enduse,["Heat","OthSub"])
  ecs1 = Select(EC,(from = "Petrochemicals", to = "Fertilizer"))
  ecs2 = Select(EC,(from = "Food", to = "Furniture"))
  ecs3 = Select(EC,["PulpPaperMills","Cement","Rubber","Glass","OtherNonMetallic","TransportEquipment","OtherManufacturing"])
  ecs=union(ecs1,ecs2,ecs3)

  techs = Select(Tech,["Biomass","Solar","Steam","FuelCell"])
  for enduse in enduses, ec in ecs, area in areas, year in years
    xMMSFBSSF[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
  end
  techs = Select(Tech,["Electric"])
  for enduse in enduses, ec in ecs, area in areas, year in years, tech in techs
    xMMSF[enduse,tech,ec,area,year] = min(1-xMMSFBSSF[enduse,ec,area,year],xMMSF[enduse,tech,ec,area,year]+Change[ec])
  end

  techs = Select(Tech,["Electric","Biomass","Solar","Steam","FuelCell"])
  for enduse in enduses, ec in ecs, area in areas, year in years
    xMMSFNonFossil[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
  end
  techs = Select(Tech,["Gas","Coal","Oil","LPG","OffRoad"])
  for enduse in enduses, ec in ecs, area in areas, year in years
    xMMSFFossil[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
    for tech in techs
      @finite_math xMMSF[enduse,tech,ec,area,year] = xMMSF[enduse,tech,ec,area,year]/xMMSFFossil[enduse,ec,area,year]*
                                                     (1-(xMMSFNonFossil[enduse,ec,area,year]))
    end
  end
  
  #
  # Off Road
  #
  enduse = Select(Enduse,"OffRoad")
  ecs1 = Select(EC,(from = "Petrochemicals", to = "Fertilizer"))
  ecs2 = Select(EC,(from = "Food", to = "Furniture"))
  ecs3 = Select(EC,(from = "IronOreMining", to = "NonMetalMining"))
  ecs4 = Select(EC,["PulpPaperMills","Cement","Rubber","Glass","OtherNonMetallic","TransportEquipment","OtherManufacturing","CoalMining"])
  ecs=union(ecs1,ecs2,ecs3,ecs4)

  techs = Select(Tech,"Electric")
  for ec in ecs, area in areas, year in years, tech in techs
    xMMSF[enduse,tech,ec,area,year] = Change[ec]
    xMMSFElectric[enduse,ec,area,year] = xMMSF[enduse,tech,ec,area,year]
  end
  techs = Select(Tech,["Gas","Coal","Oil","Biomass","Solar","LPG","OffRoad","Steam","FuelCell"])
  for ec in ecs, area in areas, year in years
    xMMSFNonElectric[enduse,ec,area,year] = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
    for tech in techs
      @finite_math xMMSF[enduse,tech,ec,area,year] = xMMSF[enduse,tech,ec,area,year]/xMMSFNonElectric[enduse,ec,area,year]*
                                                     (1-(xMMSFElectric[enduse,ec,area,year]))
    end
  end

  WriteDisk(db,"$CalDB/xMMSF",xMMSF)

  #

  years = collect(Yr(2025):Final)

  ec = Select(EC,"Petrochemicals")
  area = Select(Area,"AB")
  for tech in techs, year in years
    CgPotMult[tech,ec,area,year]= 1.0
  end
  ec = Select(EC,"NonMetalMining")
  area = Select(Area,"SK")
  for tech in techs, year in years
    CgPotMult[tech,ec,area,year]= 1.0
  end

  WriteDisk(db,"$Input/CgPotMult",CgPotMult)

end

function PolicyControl(db)
  @info "Ind_MS_P30.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
