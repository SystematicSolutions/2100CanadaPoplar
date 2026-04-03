#
# Demand_AlignToGO_Com_US.jl
#    1. Splits U.S. wholesale demands into wholesale & retail based on TOM gross output.
#    2. Splits U.S. gas pipelines into oil and gas pipelines based on TOM gross output. 
#       04/22/2022 R.Levesque
#
using EnergyModel

module Demand_AlignToGO_Com_US

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"

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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  MacroSwitch::Vector{String} = ReadDisk(db, "MInput/MacroSwitch") # [Nation] String Indicator of Macroeconomic Forecast (TIM,TOM,Stokes,AEO,CER)
  xDmd::VariableArray{5} = ReadDisk(db,"$Input/xDmd") # [Enduse,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  xGO::VariableArray{3} = ReadDisk(db,"MInput/xGO") # [ECC,Area,Year] Gross Output (2017 M$/Yr)

  #
  # Scratch Variables
  #
  RatioNGDistribution::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year]
  RatioNGPipeline::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year]  
  RatioOilPipeline::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year]
  RatioRetail::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year]  
  RatioWholesale::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year]
  TotalSectors::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(Area),length(Year)) # [Enduse,Tech,Area,Year]

end

function AlignDemandsToGrossOutput(db)
  data = CControl(; db)
  (;Input) = data
  (;EC,ECC) = data
  (;Enduses,Nation,Techs) = data
  (;Years) = data
  (;ANMap,MacroSwitch,RatioNGDistribution,RatioNGPipeline) = data
  (;RatioOilPipeline,RatioRetail,RatioWholesale,xDmd,xGO,TotalSectors) = data

  US = Select(Nation,"US")

  #
  # Only execute file if TOM is economic model since TOM has these categories split
  #
  if MacroSwitch[US] == "TOM"
    areas = findall(ANMap[:,US] .== 1.0)

    @. RatioWholesale = 1.0
    @. RatioRetail = 1.0
  
    #
    # Split Wholesale xDmd for US areas into Wholesale and Retail
    #
    Wholesale = Select(ECC,"Wholesale")
    Retail = Select(ECC,"Retail")
    eccs = Select(ECC,["Wholesale","Retail"])
    
    for year in Years, area in areas 
      @finite_math RatioWholesale[area,year] = 
        xGO[Wholesale,area,year]/sum(xGO[ecc,area,year] for ecc in eccs)
    end
    
    for year in Years, area in areas    
      @finite_math RatioRetail[area,year] = 
        xGO[Retail,area,year]/sum(xGO[ecc,area,year] for ecc in eccs)
    end
    
    Wholesale = Select(EC,"Wholesale")
    Retail = Select(EC,"Retail")
    ecs = Select(EC,["Wholesale","Retail"])
                                
    for year in Years, area in areas, tech in Techs, enduse in Enduses    
      TotalSectors[enduse,tech,area,year] = 
        sum(xDmd[enduse,tech,ec,area,year] for ec in ecs)
    end
    
    for year in Years, area in areas, tech in Techs, enduse in Enduses        
      xDmd[enduse,tech,Wholesale,area,year] = 
        TotalSectors[enduse,tech,area,year]*RatioWholesale[area,year]
    end
    
    for year in Years, area in areas, tech in Techs, enduse in Enduses        
      xDmd[enduse,tech,Retail,area,year] = 
        TotalSectors[enduse,tech,area,year]*RatioRetail[area,year]
    end

    #
    # Split NGPipleine xDmd for US areas into NGPipeline and OilPipeline and NGDistribution
    # when reading macro data from TOM - TOM has pipeline gross output, but we don't have it from AEO.
    #
    areas = findall(ANMap[:,US] .== 1.0)

    @. RatioNGDistribution=1.0
    @. RatioNGPipeline=1.0
    @. RatioOilPipeline=1.0

    NGDistribution = Select(ECC,"NGDistribution")
    NGPipeline = Select(ECC,"NGPipeline")
    OilPipeline = Select(ECC,"OilPipeline")
    eccs = Select(ECC,["NGDistribution","NGPipeline","OilPipeline"])

    for year in Years, area in areas
      @finite_math RatioNGDistribution[area,year] = 
        xGO[NGDistribution,area,year]/sum(xGO[ecc,area,year] for ecc in eccs)
    end
  
    for year in Years, area in areas
      @finite_math RatioNGPipeline[area,year] = 
        xGO[NGPipeline,area,year]/sum(xGO[ecc,area,year] for ecc in eccs)
    end
  
    for year in Years, area in areas  
      @finite_math RatioOilPipeline[area,year] = 
        xGO[OilPipeline,area,year]/sum(xGO[ecc,area,year] for ecc in eccs)
    end
  
    NGDistribution = Select(EC,"NGDistribution")
    NGPipeline = Select(EC,"NGPipeline")
    OilPipeline = Select(EC,"OilPipeline")
    ecs = Select(EC,["NGDistribution","NGPipeline","OilPipeline"]) 
 
    for year in Years, area in areas, tech in Techs, enduse in Enduses    
      TotalSectors[enduse,tech,area,year] = 
        sum(xDmd[enduse,tech,ec,area,year] for ec in ecs)
    end 
    
    for year in Years, area in areas, tech in Techs, enduse in Enduses  
      xDmd[enduse,tech,NGDistribution,area,year] = 
        TotalSectors[enduse,tech,area,year]*RatioNGDistribution[area,year]
    end
    
    for year in Years, area in areas, tech in Techs, enduse in Enduses  
      xDmd[enduse,tech,NGPipeline,area,year] = 
        TotalSectors[enduse,tech,area,year]*RatioNGPipeline[area,year]
    end
    
    for year in Years, area in areas, tech in Techs, enduse in Enduses  
      xDmd[enduse,tech,OilPipeline,area,year] = 
        TotalSectors[enduse,tech,area,year]*RatioOilPipeline[area,year]
    end
    
    WriteDisk(db,"$Input/xDmd",xDmd)    
  end

end

function Control(db)
  @info "Demand_AlignToGO_Com_US.jl - Control"
  AlignDemandsToGrossOutput(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
