#
# Demand_AllocateSectors_Ind_US.jl
#
#    - Redistributes U.S. regional energy across industries based on
#      AEO national energy intensities times xGOAEO by area and industry. This adjustment
#      is needed because industrial EC splits in Superset do not vary by region.
#      08/11/2020 R.Levesque
#
#    - Splits energy demand from Natural Gas Production industry
#      (which holds all oil and gas industry demands from SEDS)
#      into Light Oil Mining and Natural Gas Production. 05/01/2022 R.Levesque
#
using EnergyModel

module Demand_AllocateSectors_Ind_US

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
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
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Process::SetArray = ReadDisk(db,"MainDB/ProcessKey")
  ProcessDS::SetArray = ReadDisk(db,"MainDB/ProcessDS")
  Processs::Vector{Int} = collect(Select(Process))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xGAProd::VariableArray{3} = ReadDisk(db,"SInput/xGAProd") # [Process,Area,Year] Historical Primary Gas Production (TBtu/Yr)
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (Real M$/Yr)
  xGOAEO::VariableArray{3} = ReadDisk(db,"MInput/xGOAEO") # [ECC,Area,Year] Gross Output from AEO (Real M$/Yr)
  xOAProd::VariableArray{3} = ReadDisk(db,"SInput/xOAProd") # [Process,Area,Year] Oil Production (TBtu/Yr)
  
  #
  # Scratch Variables
  #
  CADmdToProdRatioGas::VariableArray{1} = zeros(Float32,length(Year)) # [Year] California Ratio of Demand to Production for ConventionalGasProduction (TBtu/TBtu)
  CADmdToProdRatioOil::VariableArray{1} = zeros(Float32,length(Year)) # [Year] California Ratio of Demand to Production for LightOilMining (TBtu/TBtu)
  DmdToProdRatioGas::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ratio of Demand to Production for ConventionalGasProduction (TBtu/TBtu)
  DmdToProdRatioOil::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Ratio of Demand to Production for LightOilMining (TBtu/TBtu)
  GasMiningSplit::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Gas Mining Demand as Fraction of Total Oil and Gas Demand (TBtu/TBtu)
  ImpliedDemand::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) # [Enduse,Tech,EC,Area,Year] Energy Demand Calculated from Intensities Times Gross Output (TBtu/Yr)
  ImpliedGasMiningDmd::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Gas Mining Demand Implied by Demand-To-Production Ratios TBtu/Yr)
  ImpliedOGMiningDmd::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Oil plus Gas Mining Demand Implied by Demand-To-Production Ratios TBtu/Yr)
  ImpliedOilMiningDmd::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Oil Mining Demand Implied by Demand-To-Production Ratios TBtu/Yr)
  NationalDmd::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Year)) # [Enduse,Tech,EC,Year] United States Total Energy Demand (TBtu)
  NationalGO::VariableArray{2} = zeros(Float32,length(EC),length(Year)) # [EC,Year] Total National Gross Output by Sector (Real M$/Yr)
  NationalIntensity::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Year)) # [Enduse,Tech,EC,Year] National Energy Intensity (TBtu/2012M$)
  OGDmd::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(Area),length(Year)) # [Enduse,Tech,Area,Year] Total Energy Demand from US Oil and Gas Mining Industry (TBtu)
  OilMiningSplit::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Oil Mining Demand as Fraction of Total Oil and Gas Demand (TBtu/TBtu)
  SEDSTotal::VariableArray{3} = zeros(Float32,length(Tech),length(Area),length(Year)) # [Tech,Area,Year] SEDS Totals by Tech and Area (TBtu)
  ScaleOGFraction::VariableArray{2} = zeros(Float32,length(Enduse),length(Tech)) # [Enduse,Tech] Fraction of Implied OG Demand to AEO OG Demand in Last Historical Year (TBtu/TBtu)
  TotDmdCalc::VariableArray{3} = zeros(Float32,length(Tech),length(Area),length(Year)) # [Tech,Area,Year] Total Calculated Energy Demand by Tech and Area (TBtu)
  TotImpliedDemand::VariableArray{3} = zeros(Float32,length(Tech),length(Area),length(Year)) # [Tech,Area,Year] Total Implied Demand (TBtu)
  TotOGDmd::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(Area),length(Year)) # [Enduse,Tech,Area,Year] Total Energy Demand from US Oil and Gas Mining Industry (TBtu)
  TotOGProd::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Production (TBtu/TBtu)

end

function AllocateDemands(db)
  data = IControl(; db)
  (;Input) = data
  (;Area,EC,ECC,ECs) = data
  (;Enduses,Process) = data
  (;Techs,Years) = data
  (;xDmd,xGAProd,xGOAEO,xOAProd) = data
  (;DmdToProdRatioGas) = data
  (;DmdToProdRatioOil,ImpliedDemand,ImpliedGasMiningDmd) = data
  (;ImpliedOilMiningDmd,NationalDmd) = data
  (;NationalGO,NationalIntensity,SecMap,SEDSTotal) = data
  (;ScaleOGFraction,TotImpliedDemand,TotOGDmd,TotOGProd) = data

  #
  # Redistributes U.S. regional energy across industries based on
  # national energy intensities times xGOAEO by region and industry.
  #
  # Exclude California from allocating across ECs (have CEC data). 09/22/2023
  # Incude California to allocate ConventionalGasProduction to LightOilMining and ConventionalGasProduction
  #
  areas = Select(Area, (from = "NEng", to = "Pac"))
  Ind = 3
  eccs = findall(SecMap .== Ind)

  #
  # OG Industry Demand to Production Ratios from Alberta 2019. 04/12/2022 R.Levesque
  #
  @. DmdToProdRatioGas = 0.0763
  @. DmdToProdRatioOil = 0.0755
  
  #
  # Calculate National Energy Intensities for Each Industry (AEO demand divided by AEO gross output)
  #
  for year in Years, area in areas, tech in Techs
    SEDSTotal[tech,area,year] = 
      sum(xDmd[enduse,tech,ec,area,year] for ec in ECs, enduse in Enduses)
  end
    
  for year in Years, ec in ECs, tech in Techs, enduse in Enduses  
    NationalDmd[enduse,tech,ec,year] =
      sum(xDmd[enduse,tech,ec,area,year] for area in areas)
  end
  
  for year in Years, ec in ECs, tech in Techs, enduse in Enduses 
    ecc = Select(ECC,EC[ec])
    NationalGO[ec,year] = sum(xGOAEO[ecc,area,year] for area in areas)
  end
    
  for year in Years, ec in ECs, tech in Techs, enduse in Enduses  
    @finite_math NationalIntensity[enduse,tech,ec,year] = 
      NationalDmd[enduse,tech,ec,year]/NationalGO[ec,year]
  end
  
  #
  # Implied Demand is Energy Intensity Times Regional Gross Output
  #
    for year in Years, area in areas, ec in ECs, tech in Techs, enduse in Enduses 
      ecc = Select(ECC,EC[ec])
      ImpliedDemand[enduse,tech,ec,area,year] = 
        NationalIntensity[enduse,tech,ec,year]*xGOAEO[ecc,area,year]
    end

  #
  # OG Industry Implied Demand - Based on Ratios of Demand to Production
  #
  ProcessOil = Select(Process,"LightOilMining") 
  LightOilMining = Select(EC,"LightOilMining") 

  ConventionalGasProduction = Select(EC,"ConventionalGasProduction")
  
  for year in Years, area in areas
    ImpliedOilMiningDmd[area,year] = xOAProd[ProcessOil,area,year]*DmdToProdRatioOil[year]
  end
  
  ec = Select(EC,"LightOilMining")   
  for year in Years, area in areas, tech in Techs, enduse in Enduses 
    @finite_math ImpliedDemand[enduse,tech,ec,area,year] = 
      ImpliedOilMiningDmd[area,year]*(xDmd[enduse,tech,ConventionalGasProduction,area,year]/
      sum(xDmd[eu,te,ConventionalGasProduction,area,year] for eu in Enduses, te in Techs))
  end
  
  ProcessGas = Select(Process,"ConventionalGasProduction") 
  for year in Years, area in areas
    ImpliedGasMiningDmd[area,year] = xGAProd[ProcessGas,area,year]*DmdToProdRatioGas[year]
  end
  
  ec  = Select(EC,"ConventionalGasProduction")   
  for year in Years, area in areas, tech in Techs, enduse in Enduses 
    @finite_math ImpliedDemand[enduse,tech,ec,area,year] =
      ImpliedGasMiningDmd[area,year]*(xDmd[enduse,tech,ec,area,year]/
      sum(xDmd[eu,te,ec,area,year] for eu in Enduses, te in Techs))
  end

  #
  # Scale OG Industry demands to XDmd levels for Conventional Gas Production in Last historical year
  #
  year = Last
  ecs = Select(EC,["LightOilMining","ConventionalGasProduction"])
  for tech in Techs, enduse in Enduses 
    @finite_math ScaleOGFraction[enduse,tech] =
      sum(xDmd[enduse,tech,ConventionalGasProduction,area,year] for area in areas)/
      sum(ImpliedDemand[enduse,tech,ec,area,year] for area in areas, ec in ecs)
  end

  ecs = Select(EC,["LightOilMining","ConventionalGasProduction"])
  for year in Years, area in areas, ec in ecs, tech in Techs, enduse in Enduses 
    ImpliedDemand[enduse,tech,ec,area,year] = ImpliedDemand[enduse,tech,ec,area,year]*
      ScaleOGFraction[enduse,tech]
  end

  #
  # Final Demands - Scale to Match SEDS (Ratio Sums to 1.0 Across Tech and Area)
  #
  for year in Years, area in areas, tech in Techs
    TotImpliedDemand[tech,area,year] = 
      sum(ImpliedDemand[enduse,tech,ec,area,year] for ec in ECs, enduse in Enduses)
  end

  for year in Years, area in areas, ec in ECs, tech in Techs, enduse in Enduses 
    @finite_math xDmd[enduse,tech,ec,area,year] = SEDSTotal[tech,area,year]*
     (ImpliedDemand[enduse,tech,ec,area,year]/TotImpliedDemand[tech,area,year])
  end



  #
  ########################
  #
  # Handle California differently. Split total OG demand into oil and gas industries.
  #
  area = Select(Area,"CA")
  
  ProcessOil = Select(Process,"LightOilMining") 
  ProcessGas = Select(Process,"ConventionalGasProduction")   
  for year in Years
    TotOGProd[year] = xOAProd[ProcessOil,area,year]+xGAProd[ProcessGas,area,year]
  end

  ConventionalGasProduction = Select(EC,"ConventionalGasProduction")
  for year in Years, tech in Techs, enduse in Enduses 
    TotOGDmd[enduse,tech,area,year] = xDmd[enduse,tech,ConventionalGasProduction,area,year]
  end
    
  ec = Select(EC,"LightOilMining") 
  for year in Years, tech in Techs, enduse in Enduses   
    @finite_math xDmd[enduse,tech,ec,area,year] = TotOGDmd[enduse,tech,area,year]*
      (xOAProd[ProcessOil,area,year]/TotOGProd[year])
  end

  ec  = Select(EC,"ConventionalGasProduction")   
  for year in Years, tech in Techs, enduse in Enduses 
    @finite_math xDmd[enduse,tech,ec,area,year] = TotOGDmd[enduse,tech,area,year]*
     (xGAProd[ProcessGas,area,year]/TotOGProd[year])
  end

  WriteDisk(db,"$Input/xDmd",xDmd) 

end

function Control(db)
  @info "Demand_AllocateSectors_Ind_US.jl - Control"
  AllocateDemands(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
