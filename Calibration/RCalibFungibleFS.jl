#
# RCalibFungibleFS.jl - Fungible Demands Market Share Calibration 
#
using EnergyModel

module RCalibFungibleFS

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr, Zero
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RCalib
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
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
  FsFP0::VariableArray{3} = ReadDisk(db,"SOutput/FsFP",First) # [Fuel,ES,Area,First] Feedstock Fuel Price ($/mmBtu)
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
  (;FsFP,FsFP0,Inflation,Inflation0,xFsFrac) = data
  (;FsFracMAW,FsFracMU) = data
  
  @. FsFracMAW = 0.0
  @. FsFracMU = 0.0
  
  for fuel in Fuels
    if (xFsFrac[fuel,tech,ec,area,year] > 0.0) && (FsFP[fuel,es,area,year] > 0.0)
      @finite_math FsFracMAW[fuel,tech,ec,area] = exp(FsFracVF[fuel,tech,ec,area,year] *
        log((FsFP[fuel,es,area,year]/Inflation[area,year])/(FsFP0[fuel,es,area]/Inflation0[area])))
      @finite_math FsFracMU[fuel,tech,ec,area] = xFsFrac[fuel,tech,ec,area,year] /FsFracMAW[fuel,tech,ec,area]
    end
  end
  
  FsFracMUmax = maximum(FsFracMU[Fuels,tech,ec,area])
  for fuel in Fuels
    if (xFsFrac[fuel,tech,ec,area,year] > 0.0) && (FsFP[fuel,es,area,year] > 0.0)
      @finite_math FsFracMSM0[fuel,tech,ec,area,year] = log(FsFracMU[fuel,tech,ec,area]/FsFracMUmax)
    else
      # FsFracMSM0[fuel,tech,ec,area,year] = FsFracMSM0[fuel,tech,ec,area,year-1]
      FsFracMSM0[fuel,tech,ec,area,year] = -170.3912964
    end
  end

end

function ControlFungibleCalib(data, es)
  (;CalDB,db) = data
  (;Areas,ECs) = data
  (;Fuels,Techs) = data
  (;FsFracMSM0) = data
  
  
  
  @. FsFracMSM0=-170.3912964
  years = collect(First:Final)
  
  for year in years, area in Areas, ec in ECs, tech in Techs
    FungibleCalib(data, tech, ec, es, area, year)
  end
  
  for year in years, area in Areas, ec in ECs, tech in Techs, fuel in Fuels
    if abs(FsFracMSM0[fuel,tech,ec,area,year]) < 0.000001
      FsFracMSM0[fuel,tech,ec,area,year] = 0.0
    end
  end
  
  
  WriteDisk(db,"$CalDB/FsFracMSM0",FsFracMSM0)

end

function Fungible(data, es, year)
  (;Outpt,db) = data
  (;Areas,ECs,Fuel) = data
  (;Fuels,Techs) = data
  (;FsFrac,FsFracMarginal,FsFracMSF,FsFracMSM0,FsFracMax,FsFracMin,FsFracTime,FsFracVF) = data
  (;FsFP,FsFP0,Inflation,Inflation0) = data
  (;FsFracMAW,FsFracTMAW,FsFracTotal) = data
  
  @. FsFracTMAW = 0.0
  @. FsFracMAW = 0.0
  
  for area in Areas, ec in ECs, tech in Techs
    for fuel in Fuels
      if FsFracMSM0[fuel,tech,ec,area,year] > -170.0
        @finite_math FsFracMAW[fuel,tech,ec,area] = exp(FsFracMSM0[fuel,tech,ec,area,year] + 
          (FsFracVF[fuel,tech,ec,area,year] * log((FsFP[fuel,es,area,year]/Inflation[area,year])/
          (FsFP0[fuel,es,area]/Inflation0[area]))))
      end
    end
  end
  
  for area in Areas, ec in ECs, tech in Techs
    FsFracTMAW[tech,ec,area] = sum(FsFracMAW[fuel,tech,ec,area] for fuel in Fuels)
  end
  
  for area in Areas, ec in ECs, tech in Techs
    for fuel in Fuels
      @finite_math FsFracMSF[fuel,tech,ec,area,year] = FsFracMAW[fuel,tech,ec,area] / FsFracTMAW[tech,ec,area]
    end
  end
  
  # *
  # * Apply Minimums and Maximums
  # *
  
  
  @. FsFracMarginal=FsFracMSF
  
  for area in Areas, ec in ECs, tech in Techs
    FsFracCount=1
    while FsFracCount <= 10
      for fuel in Fuels
        FsFracMarginal[fuel,tech,ec,area,year] = min(FsFracMax[fuel,tech,ec,area,year],
        max(FsFracMarginal[fuel,tech,ec,area,year],FsFracMin[fuel,tech,ec,area,year]))
      end
      FsFracTotal[tech,ec,area] = sum(FsFracMarginal[fuel,tech,ec,area,year] for fuel in Fuels)
      for fuel in Fuels
        @finite_math FsFracMarginal[fuel,tech,ec,area,year] = FsFracMarginal[fuel,tech,ec,area,year] / FsFracTotal[tech,ec,area]
      end
      FsFracCount = FsFracCount + 1
    end
    
  end
  
  prior = max(1, year-1)
  FsFracTemp = zeros(Float32,length(Fuel))
  for area in Areas, ec in ECs, tech in Techs
    @. FsFracTemp = 0.0
    for fuel in Fuels
      @finite_math FsFracTemp[fuel] = FsFrac[fuel,tech,ec,area,prior] + 
        ((FsFracMarginal[fuel,tech,ec,area,year] - FsFrac[fuel,tech,ec,area,prior]) / FsFracTime[fuel,tech,ec,area,year])
    end
    FsFracTempTotal = sum(FsFracTemp[fuel] for fuel in Fuels)
    for fuel in Fuels
      @finite_math FsFrac[fuel,tech,ec,area,year] = FsFracTemp[fuel] / FsFracTempTotal
    end
  end
  
  WriteDisk(db,"$Outpt/FsFrac",FsFrac)
  WriteDisk(db,"$Outpt/FsFracMarginal",FsFracMarginal)
  WriteDisk(db,"$Outpt/FsFracMSF",FsFracMSF)

end

function ControlFungible(data, es)
  
  years = collect(First:Final)
  for year in years
    Fungible(data,es,year)
  end

end

function ControlFlow(data, es)
  
  ControlFungibleCalib(data, es)
  ControlFungible(data, es)

end

function RCalibration(db)
  data = RCalib(; db)
  (;Input) = data
  (;Areas,ECs,ES) = data
  (;Fuels,Techs) = data
  (;FsFracMax,FsFracMin,FsFracTime,FsFracVF) = data
  
  es = Select(ES,"Residential")
  
  @. FsFracMax = 1.0
  WriteDisk(db,"$Input/FsFracMax",FsFracMax)
  @. FsFracMin = 0.0
  WriteDisk(db,"$Input/FsFracMin",FsFracMin)
  @. FsFracVF = -10.0
  WriteDisk(db,"$Input/FsFracVF",FsFracVF)
  
  years = collect(Zero:Final)
  @. FsFracTime[Fuels,Techs,ECs,Areas,years] = 1.0
  
  WriteDisk(db,"$Input/FsFracTime",FsFracTime)
  
  ControlFlow(data, es)

end

function CalibrationControl(db)
  @info "RCalibFungibleFS.jl - CalibrationControl"

  RCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
