#
# Electric_ITCs.jl
#
# Ref25 - Removed impacts to the last historical year 2023, removed the Clean Electricity ITC in Current Measures case only - RST 24Apr2025
# Ref24 - Updated with the Ref23AshCER version, removed impacts to the last historical year 2022 - RST 06Aug2024
#

using EnergyModel

module Electric_ITCs

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB")#  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  GCCCN::VariableArray{3} = ReadDisk(db,"EGInput/GCCCN") # [Plant,Area,Year] Overnight Construction Costs ($/KW)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Unit Area
  xUnGCCC::VariableArray{2} = ReadDisk(db,"EGInput/xUnGCCC") # [Unit,Year] Generating Unit Capital Cost (Real $/KW)

  # Scratch Variables
  Reduction::VariableArray{3} = zeros(Float32,length(Plant),length(Area),length(Year)) # [Plant,Area,Year] Reduction fraction
end

function ElecPolicy(db)
  data = EControl(; db)
  (; Area,Areas,Plant,Plants,Units,Years) = data
  (; GCCCN,Reduction,UnPlant,UnArea,xUnGCCC) = data

  #
  # To simulate Investment Tax Credits Impacting Electricity generation, 
  # including ITC's announced in Budget 2023:
  # 1. Atlantic Tax Credit (Existing)
  # 2. CCUS (Budget 2022/23)
  # 3. Clean Electricity (Budget 2023)
  # 4. Clean Technology (FES 2022 / Budget 2023)
  # RST 31May2023
  #
  # v2: Updated after alignment exercise with NextGrid, as well as add in 
  # Biomass (Waste) eligiblity for the CT/CE ITCs from FES 2023 - RST 11Jan2024

  #
  # ********************
  # GCCCN Modification
  # ********************

  @. Reduction = 0

  # CCUS ITC : Target CCS plant types,assume an average of 50% ITC applied on
  # the CCS-portion of the Plant, Full Rate 2022-2030,Half Rate 2031-2040,
  # ITC gone in 2041 onward. Also assume that 50% of the total cost of the
  # CCS Electric Unit is CCS-related equipment.
  # Area coverage: BC/AB/SK (NextGrid Alignment)
  #

  areas = Select(Area,["AB","BC","SK"])
  plants = Select(Plant,["NGCCS","CoalCCS","BiomassCCS"])
  
  years = collect(Yr(2024):Yr(2030))
  for year in years, area in areas, plant in plants
    Reduction[plant,area,year] = Reduction[plant,area,year] + 0.5*0.5
  end
  years = collect(Yr(2031):Yr(2040))
  for year in years, area in areas, plant in plants
    Reduction[plant,area,year] = Reduction[plant,area,year] + 0.25*0.5
  end

  #
  # Clean Technology ITC : Target non-emitting plant types,assume all units are private-owned
  # (so Units can claim the Clean Tech rate (30%) rather than the lower Clean Electricity rate (15%),
  # Full Rate 2023-2033,Half Rate 2034,ITC gone in 2035 onward.
  # Only let PeakHydro be eligible for CE ITC (NextGrid Alignment)
  # Add Biomass (50% of BiomassCCS) and Waste eligible (FES 2023)
  #
  areas = Select(Area, ["AB","BC","MB","ON","QC","SK","NS","NL","NB","PE","YT","NT","NU"])
  plants = Select(Plant,["FuelCell","Battery","Nuclear","SMNR","BaseHydro",
                         "PumpedHydro","SmallHydro","OnshoreWind","OffshoreWind","SolarPV",
                         "SolarThermal","Geothermal","Wave","Tidal","Biomass","Waste"])

  years = collect(Yr(2024):Yr(2033))
  for year in years, area in areas, plant in plants
    Reduction[plant,area,year] = Reduction[plant,area,year] + 0.3
  end

  years = Yr(2034)
  for year in years, area in areas, plant in plants
    Reduction[plant,area,year] = Reduction[plant,area,year] + 0.15
  end

  areas = Select(Area, ["AB","BC","SK"])
  plants = Select(Plant,"BiomassCCS")

  years = collect(Yr(2024):Yr(2033))
  for year in years, area in areas, plant in plants
    Reduction[plant,area,year] = Reduction[plant,area,year] + 0.3*0.5
  end
  
  years = Yr(2034)
  for year in years, area in areas, plant in plants
    Reduction[plant,area,year] = Reduction[plant,area,year] + 0.15*0.5
  end

  #
  # Clean Electricity ITC : Target NGCCS, Full 15% Rate 2024-2034, ITC gone in 2035 onward.
  # Also target PeakHydro (NextGrid Alignment)
  # As 50% of NGCCS plant is CCUS, only allow 50% of plant to be eligible for CE ITC.
  # Since MB is not included in the CCUS ITC, apply 100% of CapEx of NGCCS for the CE ITC
  # Janie and NextGrid Alignment: Finance Canada says AB/BC/SK not eligible for
  # CE-ITC and are only eligible for the CCUS-ITC on capture equipment.
  # MB only eligible if the emissions intensity is 65 t/GWh or less, no NGCCS in
  # MB built in E2020 at moment but assume in future new units meet this limit
  # - RST 11July2024
  #*
  #* Select Area(BC,AB,SK)
  #* Select Plant(NGCCS)
  #*
  #* Select Year(2024-2034)
  #* Do Year
  #* Do Area
  #* Do Plant
  #* Reduction(Plant,Area,Year) = Reduction(Plant,Area,Year) + 0.15*0.5
  #* End Do Plant
  #* End Do Area
  #* End Do Year
  #*
  #* Select Plant*
  #* Select Area*
  #* Select Year*

  #* MB = Select(Area,"MB")
  #* NGCCS = Select(Plant,"NGCCS")
  #* years = collect(Yr(2024):Yr(2034))
  #* for year in years
  #*   Reduction[NGCCS,MB,year] = Reduction[NGCCS,MB,year] + 0.15
  #* end
 
  #* areas = Select(Area, ["AB","BC","MB","ON","QC","SK","NS","NL","NB","PE","YT","NT","NU"])
  #* plants = Select(Plant,"PeakHydro")
  #* years = collect(Yr(2024):Yr(2034))
  #* for year in years, area in areas, plant in plants
  #*   Reduction[plant,area,year] = Reduction[plant,area,year] + 0.15
  #* end
 
  #
  # Atlantic ITCs : Target all units types, 10% Rate,Coverage for Atlantic provinces,
  # Assume all of Quebec not eligible for Credit (Gaspe Region is covered in reality).
  # Remove eligibility of Nuclear and PeakHydro for this ITC, as well as remove CCS
  # as these are not eligible Areas where CCS is built (NextGrid Alignment)
  # Of the emitting technologies, only allow NGCCS and OGCC (NextGrid Alignment)
  #
  # Janie and NextGrid Alignment:  Based on feedback from NRCan, remove this ITC as the scope of its application does not include the type of power generation we are modelling - RST 19July2024
  #
  # areas = Select(Area,["PE","NS","NL","NB"])
  # plants = Select(Plant,["FuelCell","Battery","BaseHydro","PumpedHydro",
  #                        "SmallHydro","OnshoreWind","OffshoreWind","SolarPV",
  #                        "SolarThermal","Geothermal","Wave","Tidal","Biomass",
  #                        "Waste","NGCCS","OGCC"])
  # years = collect(Yr(2024):Final)
  # for year in years, area in areas, plant in Plants
  #   Reduction[plant,area,year] = Reduction[plant,area,year] + 0.1
  # end

  #
  # Apply calculated reductions to existing overnight construction costs
  # to create the new costs minus eligible ITC's by Plant Type / Area / Year.
  #
  for year in Years, area in Areas, plant in Plants
    GCCCN[plant,area,year] = GCCCN[plant,area,year]*(1-Reduction[plant,area,year])
  end

  #
  # ********************
  # xUnGCCC Modification
  # ********************
  #

  areas = Select(Area,["AB","BC","MB","ON","QC","SK","NS","NL","NB","PE","YT","NT","NU"])
  
  for unit in Units, plant in Plants, area in Areas
    if UnArea[unit] == Area[area] && UnPlant[unit] == Plant[plant]
      for year in Years
        xUnGCCC[unit,year] = xUnGCCC[unit,year]*(1-Reduction[plant,area,year])
      end
    end
  end

  WriteDisk(db,"EGInput/GCCCN",GCCCN)
  WriteDisk(db,"EGInput/xUnGCCC",xUnGCCC)
end

function PolicyControl(db)
  @info "Electric_ITCs.jl - PolicyControl"
  ElecPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
