#
# UnitScaleGenerationFuel_US.jl
#
# Done - EGFAMult - off for US for Geothermal,Hydro,Hydrogen,Nuclear,Solar,Waste,Wind
# 24.10.30, LJD: EGFAMult had the wrong variable checked in a Do If, corrected and this
# fixed DmdFA and xUnFlFr.
# Done - DmdFA - off for Waste and Hydrogen for US
# Done - xUnFlFr - off for Unit(1817)
#
# Done - PFFrac - off for US for SmallOGCC,NGCCS,OGSteam,Coal,BiomassCCS
# 24.10.29, LJD: PFFrac does not constitute a problem.
# Julia model had saving temporary values used in calculations
# Saving was for debug purposes only.
#
# Done - xUnEGA - Plant-type check fixed
# Done - xUnHRt - Plant-type check fixed
# - Jeff Amlin 9/30/24
# - Luke Davulis 10/30/24 - significantly fewer units pose problems after EGFAMult fix
#
#
using EnergyModel

module UnitScaleGenerationFuel_US

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  EGFAMult::VariableArray{3} = ReadDisk(db,"EGCalDB/EGFAMult") # [Fuel,Area,Year] Fuel Usage Multiplier (Btu/Btu)
  FFPMap::VariableArray{2} = ReadDisk(db,"SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") # [Fuel,Plant] Fuel/Plant Map
  PFFrac::VariableArray{4} = ReadDisk(db,"EGInput/PFFrac") # [FuelEP,Plant,Area,Year] Fuel Usage Fraction (Btu/Btu)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCode::Array{String} = ReadDisk(db,"EGInput/UnCode") # [Unit] Unit Code
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  xUnFlFr::VariableArray{3} = ReadDisk(db,"EGInput/xUnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnHRt::VariableArray{2} = ReadDisk(db,"EGInput/UnHRt") # [Unit,Year] Heat Rate (BTU/KWh)
  UnNation::Array{String} = ReadDisk(db,"EGInput/UnNation") # [Unit] Nation
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)
  xUnEGA::VariableArray{2} = ReadDisk(db,"EGInput/xUnEGA") # [Unit,Year] Historical Unit Generation (GWh)
  xEUD::VariableArray{3} = ReadDisk(db,"EGInput/xEUD") # [FuelEP,Area,Year] Electric Utility Fuel Demand (TBtu/Yr)
  xEUDmd::VariableArray{3} = ReadDisk(db,"EGInput/xEUDmd") # [Fuel,Area,Year] Electric Utility Fuel Demands (TBtu/Yr)
  xXEUDmd::VariableArray{3} = ReadDisk(db,"EGOutput/DmdFA") # [Fuel,Area,Year] Initial Electric Utility Fuel Demands (TBtu/Yr)

  #
  # Scratch Variables
  #
  # EGACount 'Counter for Iterations to Scale Generation'
  OGMult::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Oil and Gas Unit Adjustment (Btu/Btu)
  PFFracTotal::VariableArray{3} = zeros(Float32,length(Plant),length(Area),length(Year)) # [Plant,Area,Year] Fuel Usage Fraction Total (Btu/Btu)
  xEUDTotal::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Total Fuel Demands (TBtu/Yr)
end

function GetUnitSets(data,unit)
  (; Area,Plant) = data
  (; UnArea,UnPlant) = data
  #
  # This procedure selects the sets for a particular unit
  #
  if (UnPlant[unit] != "Null") && (UnArea[unit] != "Null")
    plant = Select(Plant,UnPlant[unit])
    area = Select(Area,UnArea[unit])
    valid = true
  else
    plant=1
    area=1
    valid = false
  end
  return plant,area,valid
end

function InitializeFuelFractions(data)
  (;FuelEP,FuelEPs,Nation) = data
  (;Plant,Plants,Years) = data
  (;ANMap,PFFrac) = data
  (;xEUD) = data
  (;PFFracTotal,xEUDTotal) = data

  US=Select(Nation,"US")
  areas=findall(ANMap[:,US] .== 1)

  for year in Years, area in areas, plant in Plants, fuelep in FuelEPs
    PFFrac[fuelep,plant,area,year]=0.0
  end

  NaturalGas=Select(FuelEP,"NaturalGas")
  Coal_F=Select(FuelEP,"Coal")
  Biogas_F=Select(FuelEP,"Biogas")
  Waste_F=Select(FuelEP,"Waste")
  Biomass_F=Select(FuelEP,"Biomass")
  Hydrogen=Select(FuelEP,"Hydrogen")
  OGCT=Select(Plant,"OGCT")
  OGCC=Select(Plant,"OGCC")
  CoalCCS=Select(Plant,"CoalCCS")
  Biogas_P=Select(Plant,"Biogas")
  Waste_P=Select(Plant,"Waste")
  Biomass_P=Select(Plant,"Biomass")
  OtherGeneration=Select(Plant,"OtherGeneration")
  FuelCell=Select(Plant,"FuelCell")

  for year in Years, area in areas
    PFFrac[NaturalGas,OGCT,area,year]=1.0000
    PFFrac[NaturalGas,OGCC,area,year]=1.0000
    PFFrac[Coal_F,CoalCCS,area,year]=1.0000
    PFFrac[Biogas_F,Biogas_P,area,year]=1.0000
    PFFrac[Waste_F,Waste_P,area,year]=1.0000
    PFFrac[Biomass_F,Biomass_P,area,year]=1.0000
    PFFrac[NaturalGas,OtherGeneration,area,year]=1.0000
    PFFrac[Hydrogen,FuelCell,area,year]=1.0000
  end

  #
  # Coal contains Petroleum Coke
  #
  plant=Select(Plant,"Coal")
  fueleps=Select(FuelEP,["Coal","PetroCoke"])

  for year in Years, area in areas
    xEUDTotal[area,year]=sum(xEUD[fuelep,area,year] for fuelep in fueleps)
  end

  for year in Years, area in areas, fuelep in fueleps
    @finite_math PFFrac[fuelep,plant,area,year]=xEUD[fuelep,area,year]/
                                                xEUDTotal[area,year]
  end

  #
  # OG Steam contains all the oil and some natural gas
  #
  plant=Select(Plant,"OGSteam")
  #
  # All the oil fuel demands
  #
  fueleps=Select(FuelEP,["Asphaltines","AviationGasoline","Diesel","Gasoline","HFO",
                         "JetFuel","Kerosene","LFO","LPG","StillGas"])
  for year in Years, area in areas
    xEUDTotal[area,year]=sum(xEUD[fuelep,area,year] for fuelep in fueleps)
  end

  for year in Years, area in areas, fuelep in fueleps
    @finite_math PFFrac[fuelep,plant,area,year]=xEUD[fuelep,area,year]/
                                                  xEUDTotal[area,year]
  end
  #
  # Add some natural gas
  #
  for year in Years, area in areas
    PFFrac[NaturalGas,plant,area,year]=0.10
  end

  #
  # Normalize so fraction sums to 1.0
  #
  for year in Years,area in areas
    PFFracTotal[plant,area,year]=sum(PFFrac[fuelep,plant,area,year] for fuelep in FuelEPs)
  end

  for year in Years, area in areas, fuelep in FuelEPs
    @finite_math PFFrac[fuelep,plant,area,year]=PFFrac[fuelep,plant,area,year]/
                                                  PFFracTotal[plant,area,year]
  end

end

function FuelDemands(data)
  (;db) = data
  (;Fuel,FuelEP,FuelEPs,Fuels,Nation) = data
  (;Years,Yrv) = data
  (;ANMap,FlPlnMap,PFFrac,UnCogen,xUnFlFr,UnHRt) = data
  (;UnNation,UnOnLine,UnRetire,xUnEGA,xXEUDmd) = data


  US=Select(Nation,"US")
  areas=findall(ANMap[:,US] .== 1)

  units_us=findall(UnNation[:] .== "US")
  units_cg=findall(UnCogen[:] .== 0.0)
  units=intersect(units_us,units_cg)

  for year in Years, area in areas, fuel in Fuels
    xXEUDmd[fuel,area,year]=0
  end

  for unit in units
    years=collect(Zero:Final)
    for year in years
      if (UnOnLine[unit] <= Yrv[year]) && (UnRetire[unit,year] > Yrv[year])
        plant,area,valid = GetUnitSets(data,unit)
        if valid == true
          #
          # Plants not in FuelEP set
          #
          fuels_a=findall(FlPlnMap[:,plant] .== 1)
          if !isempty(fuels_a)
            for fuel in fuels_a
              xXEUDmd[fuel,area,year]=xXEUDmd[fuel,area,year]+
                                      xUnEGA[unit,year]*UnHRt[unit,year]/1e6
            end
          end
          # fuels_b=findall(FlPlnMap[:,plant] .!= 1)
          # if !isempty(fuels_b)

            #
            #     Else Plant in FuelEP set split between Fuels (xUnFlFr)
            #
            for fuelep in FuelEPs, fuel in Fuels
              if FuelEP[fuelep] == Fuel[fuel]
                xUnFlFr[unit,fuelep,year]=PFFrac[fuelep,plant,area,year]
                xXEUDmd[fuel,area,year]=xXEUDmd[fuel,area,year]+
                      xUnEGA[unit,year]*UnHRt[unit,year]/1e6*xUnFlFr[unit,fuelep,year]
              end
            end
          # end
        end
      end
    end
    years=collect(Future:Final)
    for year in years, fuelep in FuelEPs
      xUnFlFr[unit,fuelep,year]=xUnFlFr[unit,fuelep,Last]
    end
  end

  WriteDisk(db,"EGInput/xUnFlFr",xUnFlFr)
  WriteDisk(db,"EGOutput/DmdFA",xXEUDmd)

end

function FuelAdjustment(data,EGACount)
  (;db) = data
  (;Fuel,Fuels,Nation) = data
  (;Years) = data
  (;ANMap,EGFAMult) = data
  (;xEUDmd,xXEUDmd) = data
  (;OGMult) = data

  US=Select(Nation,"US")
  areas=findall(ANMap[:,US] .== 1)

  for year in Years, area in areas, fuel in Fuels
    if xEUDmd[fuel,area,year] > 0.0
      @finite_math EGFAMult[fuel,area,year]=xEUDmd[fuel,area,year]/xXEUDmd[fuel,area,year]
    else
      EGFAMult[fuel,area,year]=1.00
    end
  end

  #
  # Total Oil and Gas Fuel Demands
  #
  areas=findall(ANMap[:,US] .== 1)
  fuels=Select(Fuel,["Asphaltines","AviationGasoline","Diesel","Gasoline","HFO",
                    "JetFuel","Kerosene","LFO","LPG","StillGas",
                    "NaturalGas"])
  for year in Years, area in areas
    @finite_math OGMult[area,year]=sum(xEUDmd[fuel,area,year] for fuel in fuels)/
                                   sum(xXEUDmd[f,area,year] for f in fuels)
  end

  if EGACount == 1
    WriteDisk(db,"EGCalDB/EGFAMult",EGFAMult)
  end

end

function AdjustOGSteamFuelFraction(data)
  (;Fuel,FuelEP,FuelEPs,Fuels,Nation) = data
  (;Plant) = data
  (;ANMap,EGFAMult,PFFrac) = data
  (;PFFracTotal) = data

  US=Select(Nation,"US")
  areas=findall(ANMap[:,US] .== 1)

  OGSteam=Select(Plant,"OGSteam")
  years=collect(Zero:Last)
  fueleps=Select(FuelEP,["Asphaltines","AviationGasoline","Diesel","Gasoline","HFO",
                         "JetFuel","Kerosene","LFO","LPG","StillGas"])
  for fuelep in fueleps, fuel in Fuels
    if FuelEP[fuelep] == Fuel[fuel]
      for year in years, area in areas
        PFFrac[fuelep,OGSteam,area,year]=PFFrac[fuelep,OGSteam,area,year]*EGFAMult[fuel,area,year]
      end
    end
  end

  #
  # Normalize so fraction sums to 1.0
  #
  for year in years, area in areas
    PFFracTotal[OGSteam,area,year]=sum(PFFrac[fuelep,OGSteam,area,year] for fuelep in FuelEPs)
    for fuelep in FuelEPs
      @finite_math PFFrac[fuelep,OGSteam,area,year]=PFFrac[fuelep,OGSteam,area,year]/
        PFFracTotal[OGSteam,area,year]
    end
  end

  years=collect(Future:Final)
  for year in years, area in areas, fuelep in FuelEPs
    PFFrac[fuelep,OGSteam,area,year]=PFFrac[fuelep,OGSteam,area,Last]
  end

  # WriteDisk(db,"EGInput/PFFrac",PFFrac)

end

function AdjustUnits(data,year,unit,area,fuel)
  (;Yrv) = data
  (;EGFAMult,UnHRt) = data
  (;xUnEGA) = data


  #
  # After 2000 adjust heat rates
  #
  if Yrv[year] > 2000

    # loc1 = UnHRt[unit,year]
    # @info " UnHRt[$unit,$year] = $loc1 "
    # loc1 = EGFAMult[fuel,area,year]
    # @info " EGFAMult[$fuel,$area,$year] = $loc1 "

    UnHRt[unit,year]=UnHRt[unit,year]*EGFAMult[fuel,area,year]
  #
  # Before 2000 adjust generation (and use 2001 heat rate)
  #
  else
    xUnEGA[unit,year]=xUnEGA[unit,year]*EGFAMult[fuel,area,year]
    UnHRt[unit,year]=UnHRt[unit,Yr(2001)]
  end
end

function ApplyFuelAdjustment(data)
  (;db) = data
  (;Fuel,FuelEP,FuelEPs) = data
  (;Yrv) = data
  (;EGFAMult,FFPMap,FlPlnMap,UnCogen,xUnFlFr,UnHRt) = data
  (;UnNation,UnOnLine,UnPlant,UnRetire,xUnEGA) = data
  (;OGMult) = data

  units_us=findall(UnNation[:] .== "US")
  units_cg=findall(UnCogen[:] .== 0.0)
  units=intersect(units_us,units_cg)

  for unit in units
    years=reverse(collect(Zero:Last))
    for year in years

      if (UnOnLine[unit] <= Yrv[year]) && (UnRetire[unit,year] > Yrv[year])
        plant,area,valid = GetUnitSets(data,unit)
        if valid == true

          #
          # Plants not in FuelEP
          #
          fuels = findall(FlPlnMap[:,plant] .== 1)
          if !isempty(fuels)
            fuel = first(fuels)

            AdjustUnits(data,year,unit,area,fuel)

          #
          # Plants in FuelEP set except for OG units
          #
          else

            #
            # Sort Descending FuelEP using xUnFlFr
            #
            fueleps = FuelEPs[sortperm(xUnFlFr[unit,FuelEPs,year],rev=true)]
            fuelep = first(fueleps)
            fuel = Select(Fuel,FuelEP[fuelep])

            if FFPMap[fuelep,fuel] == 1 && (UnPlant[unit] != "OGCT") &&
              (UnPlant[unit] != "OGCC") && (UnPlant[unit] != "OGSteam")

              AdjustUnits(data,year,unit,area,fuel)

            else
              EGFAMult[fuel,area,year]=OGMult[area,year]
              AdjustUnits(data,year,unit,area,fuel)
            end

          end
        end
      end
    end

    years=collect(Future:Final)
    for year in years
      UnHRt[unit,year]=UnHRt[unit,Last]
    end

  end

  WriteDisk(db,"EGInput/UnHRt",UnHRt)
  WriteDisk(db,"EGInput/xUnEGA",xUnEGA)

end

function ScaleGenerationFuel(data,EGACount)

  FuelDemands(data)
  FuelAdjustment(data,EGACount)
  AdjustOGSteamFuelFraction(data)
  ApplyFuelAdjustment(data)

end

function ControlScaling(db)
  data = EControl(; db)

  InitializeFuelFractions(data)
  EGACount=1
  ScaleGenerationFuel(data,EGACount)
  EGACount=2
  ScaleGenerationFuel(data,EGACount)
  EGACount=3
  ScaleGenerationFuel(data,EGACount)

end

function Control(db)
  @info "UnitScaleGenerationFuel_US.jl - Control"
  ControlScaling(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
