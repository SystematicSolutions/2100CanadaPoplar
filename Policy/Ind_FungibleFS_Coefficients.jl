#
# Ind_FungibleFS_Coefficients.jl - Fungible Demands Market Share Calibration 
#

using EnergyModel

module Ind_FungibleFS_Coefficients

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log,HasValues
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name
  OGRefNameDB::String = ReadDisk(db,"MainDB/OGRefNameDB") #  Oil/Gas Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  # Prior::SetArray = ReadDisk(db,"MainDB/PriorKey")
  # PriorDS::SetArray = ReadDisk(db,"MainDB/PriorDS")
  # Priors::Vector{Int} = collect(Select(Prior))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  FsFrac::VariableArray{5} = ReadDisk(db,"$Outpt/FsFrac") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  FsFracMarginal::VariableArray{5} = ReadDisk(db,"$Outpt/FsFracMarginal") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Marginal Market Share (Btu/Btu)
  FsFracMSF::VariableArray{5} = ReadDisk(db,"$Outpt/FsFracMSF") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Market Share (Btu/Btu)
  FsFracMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/FsFracMSM0") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)
  FsFracMax::VariableArray{5} = ReadDisk(db,"$Input/FsFracMax") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  FsFracMin::VariableArray{5} = ReadDisk(db,"$Input/FsFracMin") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  FsFracTime::VariableArray{5} = ReadDisk(db,"$Input/FsFracTime") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Adjustment Time (Years)
  FsFracVF::VariableArray{5} = ReadDisk(db,"$Input/FsFracVF") # [Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Variance Factor (Btu/Btu)
  # DPL::VariableArray{4} = ReadDisk(db,"$Outpt/DPL") # [Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  FsFP::VariableArray{4} = ReadDisk(db,"SOutput/FsFP") # [Fuel,ES,Area,Year] Feedstock Fuel Price ($/mmBtu)
  FsFPRef::VariableArray{4} = ReadDisk(OGRefNameDB,"SOutput/FsFP") # [Fuel,ES,Area,Year] Feedstock Fuel Price ($/mmBtu)
  FsFP0::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",First) # [Fuel,ES,Area,First] Feedstock Fuel Price ($/mmBtu)
  FsFP0Ref::VariableArray{3} = ReadDisk(OGRefNameDB,"SOutput/FsFP",First) # [Fuel,ES,Area,First] Feedstock Fuel Price ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  Inflation0::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",First) # [Area,Year] Inflation Index ($/$)
  xFsFrac::VariableArray{5} = ReadDisk(db,"$Input/xFsFrac") # [Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  # Scratch Variables
 # FsFracCount   'Counter for Demand Fuel/Tech Fraction Market Shares'
  FsFracMAW::VariableArray{4} = zeros(Float32,length(Fuel),length(Tech),length(EC),length(Area)) # [Fuel,Tech,EC,Area] Allocation Weights for Demand Fuel/Tech Fraction (DLess)
  FsFracMU::VariableArray{4} = zeros(Float32,length(Fuel),length(Tech),length(EC),length(Area)) # [Fuel,Tech,EC,Area] Initial Estimate of Fuel/Tech Fraction Non-Price Factor
  FsFracTMAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Total of Allocation Weights for Demand Fuel/Tech Fraction (DLess)
  FsFracTotal::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Total of Demand Fuel/Tech Fractions (Btu/Btu)
end

function FungibleCalib(data, tech, ec, es, area, year)
  (;Fuels) = data
  (;FsFracMSM0,FsFracVF) = data
  (;FsFPRef,FsFP0Ref,Inflation,Inflation0,xFsFrac) = data
  (;FsFracMAW,FsFracMU) = data
  
  for fuel in Fuels
    if (xFsFrac[fuel,tech,ec,area,year] > 0.0) && (FsFPRef[fuel,es,area,year] > 0.0)
      @finite_math FsFracMAW[fuel,tech,ec,area] = exp(FsFracVF[fuel,tech,ec,area,year] *
        log((FsFPRef[fuel,es,area,year]/Inflation[area,year])/(FsFP0Ref[fuel,es,area]/Inflation0[area])))
      @finite_math FsFracMU[fuel,tech,ec,area] = xFsFrac[fuel,tech,ec,area,year] /FsFracMAW[fuel,tech,ec,area]
    end
  end
  
  FsFracMUmax = maximum(FsFracMU[Fuels,tech,ec,area])
  for fuel in Fuels
    if (xFsFrac[fuel,tech,ec,area,year] > 0.0) && (FsFPRef[fuel,es,area,year] > 0.0)
      @finite_math FsFracMSM0[fuel,tech,ec,area,year] = log(FsFracMU[fuel,tech,ec,area]/FsFracMUmax)
    else
      # FsFracMSM0[fuel,tech,ec,area,year] = FsFracMSM0[fuel,tech,ec,area,year-1]
      FsFracMSM0[fuel,tech,ec,area,year] = -170.3912964
    end
  end

end

function ControlFungibleCalib(data,es,techs,ecs,areas,years)
  (;CalDB,db) = data
  (;Fuels) = data
  (;FsFracMSM0) = data
  
  for year in years, area in areas, ec in ecs, tech in techs, fuel in Fuels
    FsFracMSM0[fuel,tech,ec,area,year]=-170.3912964
    FungibleCalib(data, tech, ec, es, area, year)
  end
  
  for year in years, area in areas, ec in ecs, tech in techs, fuel in Fuels
    if abs(FsFracMSM0[fuel,tech,ec,area,year]) < 0.000001
      FsFracMSM0[fuel,tech,ec,area,year] = 0.0
    end
  end
  
end

function ControlFlow(data)
  (; Area,Areas,EC,ECs,ES,Fuels,Tech,Techs) = data

  es = Select(ES,"Industrial")
  areas = Areas
  ecs = ECs
  techs = Techs
  years = collect(Future:Final)
  ControlFungibleCalib(data,es,techs,ecs,areas,years)

end # ControlFlow

function IndPolicy(db)
  data = IControl(; db)
  (; CalDB,Outpt) = data
  (; FsFrac,FsFracMarginal) = data 
  (; FsFracMSF,FsFracMSM0) = data
  
  ControlFlow(data)

  WriteDisk(db,"$CalDB/FsFracMSM0",FsFracMSM0)
  WriteDisk(db,"$Outpt/FsFrac",FsFrac)
  WriteDisk(db,"$Outpt/FsFracMarginal",FsFracMarginal)
  WriteDisk(db,"$Outpt/FsFracMSF",FsFracMSF)
end

function PolicyControl(db)
  @info "Ind_FungibleFS_Coefficients.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
