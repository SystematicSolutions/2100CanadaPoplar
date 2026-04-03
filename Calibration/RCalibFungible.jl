#
# RCalibFungible.jl - Fungible Demands Market Share Calibration 
#
using EnergyModel

module RCalibFungible

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct RControl
  db::String

  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmFracMarginal::VariableArray{6} = ReadDisk(db,"$Outpt/DmFracMarginal") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Marginal Market Share (Btu/Btu)
  DmFracMSF::VariableArray{6} = ReadDisk(db,"$Outpt/DmFracMSF") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Market Share (Btu/Btu)
  DmFracMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/DmFracMSM0") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Non-Price Factor (Btu/Btu)
  DmFracMax::VariableArray{6} = ReadDisk(db,"$Input/DmFracMax") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DmFracMin::VariableArray{6} = ReadDisk(db,"$Input/DmFracMin") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Minimum (Btu/Btu)
  DmFracTime::VariableArray{6} = ReadDisk(db,"$Input/DmFracTime") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Adjustment Time (Years)
  DmFracVF::VariableArray{5} = ReadDisk(db,"$Input/DmFracVF") # [Enduse,Fuel,Tech,EC,Area] Demand Fuel/Tech Fraction Variance Factor (Btu/Btu)
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  ECFP0::VariableArray{4} = ReadDisk(db,"$Outpt/ECFP",First) # [Enduse,Tech,EC,Area,First] Fuel Price ($/mmBtu)
  ECFPFuel::VariableArray{4} = ReadDisk(db,"$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  Inflation0::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",First) # [Area,Year] Inflation Index ($/$)
  xDmFrac::VariableArray{6} = ReadDisk(db,"$Input/xDmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands Fuel/Tech Split (Btu/Btu)

  #
  # Scratch Variables
  #
  # DmFracCount   'Counter for Demand Fuel/Tech Fraction Market Shares'
  DmFracMAW::VariableArray{5} = zeros(Float32,length(Enduse),length(Fuel),length(Tech),length(EC),length(Area)) # [Enduse,Fuel,Tech,EC,Area] Allocation Weights for Demand Fuel/Tech Fraction (DLess)
  DmFracMU::VariableArray{5} = zeros(Float32,length(Enduse),length(Fuel),length(Tech),length(EC),length(Area)) # [Enduse,Fuel,Tech,EC,Area] Initial Estimate of Fuel/Tech Fraction Non-Price Factor
  DmFracTMAW::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Total of Allocation Weights for Demand Fuel/Tech Fraction (DLess)
  DmFracTotal::VariableArray{4} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area)) # [Enduse,Tech,EC,Area] Total of Demand Fuel/Tech Fractions (Btu/Btu)
end

function InitializeFungible(data)
  (;db,CalDB,Input,Outpt) = data
  (;Areas,ECs,Enduses) = data
  (;Fuels,Techs) = data
  (;DmFracMax,DmFracMin,DmFracTime,DmFracVF) = data

  @. DmFracMax = 1.0
  @. DmFracMin = 0.0
  @. DmFracVF = -10.0
  
  years = collect(Zero:Last)
  for year in years, area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    DmFracTime[enduse,fuel,tech,ec,area,year] = 1.0
  end
  
  years = collect(Future:Final)
  for year in years, area in Areas, ec in ECs, tech in Techs, fuel in Fuels, enduse in Enduses
    DmFracTime[enduse,fuel,tech,ec,area,year] = 1.0
  end
  
  WriteDisk(db,"$Input/DmFracMax",DmFracMax)
  WriteDisk(db,"$Input/DmFracMin",DmFracMin)
  WriteDisk(db,"$Input/DmFracTime",DmFracTime)
  WriteDisk(db,"$Input/DmFracVF",DmFracVF)
  
end

function FungibleCalib(data,enduse,fuels,tech,ec,area,year)
  (;db,CalDB,Input,Outpt) = data
  (;DmFracMAW,DmFracMSM0,DmFracMU,DmFracVF) = data
  (;ECFP0,ECFPFuel,Inflation,Inflation0,xDmFrac) = data
  
  for fuel in fuels
    @finite_math DmFracMAW[enduse,fuel,tech,ec,area] =
      exp(DmFracVF[enduse,fuel,tech,ec,area]*log((ECFPFuel[fuel,ec,area,year]/Inflation[area,year])/
      ECFP0[enduse,tech,ec,area]/Inflation0[area]))
  end
  
  for fuel in fuels
    @finite_math DmFracMU[enduse,fuel,tech,ec,area] = 
      xDmFrac[enduse,fuel,tech,ec,area,year]/DmFracMAW[enduse,fuel,tech,ec,area]
  end
  
  DmFracMUmax = maximum(DmFracMU[enduse,fuels,tech,ec,area])
  
  for fuel in fuels 
    DmFracMSM0[enduse,fuel,tech,ec,area,year] = 
      log(DmFracMU[enduse,fuel,tech,ec,area]/DmFracMUmax)
      
    xxx = DmFracMSM0[enduse,fuel,tech,ec,area,year]
    if isinf(xxx)
      DmFracMSM0[enduse,fuel,tech,ec,area,year] = -170.3912964
    end 
    
    if DmFracMU[enduse,fuel,tech,ec,area] == DmFracMUmax
      DmFracMSM0[enduse,fuel,tech,ec,area,year] = 0.0
    end
    
  end
end

function ControlFungibleCalib(data)
  (;db,CalDB,Input,Outpt) = data
  (;Areas,ECs,Enduses) = data
  (;Fuels,Techs) = data
  (;DmFracMSM0,ECFPFuel,xDmFrac) = data
  
  @. DmFracMSM0=-170.3912964
  
  years = collect(First:Final)
  for year in years, area in Areas, ec in ECs, tech in Techs, enduse in Enduses
  
    ExecuteFungibleCalib = false
    for fuel in Fuels
      if xDmFrac[enduse,fuel,tech,ec,area,year] > 0.0 && 
        ECFPFuel[fuel,ec,area,year] > 0.0
      
        ExecuteFungibleCalib = true

      end
    end
    if ExecuteFungibleCalib == true
      
      fuels_1 = findall(xDmFrac[enduse,:,tech,ec,area,year] .> 0.0)
      fuels_2 = findall(ECFPFuel[:,ec,area,year] .> 0.0)
      fuels = intersect(fuels_1,fuels_2)

      FungibleCalib(data, enduse, fuels, tech, ec, area, year)
      
    else
      for fuel in Fuels
        DmFracMSM0[enduse,fuel,tech,ec,area,year] = 
          DmFracMSM0[enduse,fuel,tech,ec,area,year-1]
      end
    end
  end
  
  WriteDisk(db,"$CalDB/DmFracMSM0",DmFracMSM0)
end

function Fungible(data, year)
  (;db,CalDB,Input,Outpt) = data
  (;Areas,ECs,Enduses) = data
  (;Fuels,Techs) = data
  (;DmFrac,DmFracMarginal,DmFracMAW,DmFracMSF,DmFracMSM0) = data
  (;DmFracMax,DmFracMin,DmFracTime,DmFracTMAW,DmFracTotal,DmFracVF) = data
  (;ECFP0,ECFPFuel,Inflation,Inflation0) = data
  
  @. DmFracTMAW = 0.0
  @. DmFracMAW = 0.0
  
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    for fuel in Fuels
      if DmFracMSM0[enduse,fuel,tech,ec,area,year] > -170.0
      
        @finite_math DmFracMAW[enduse,fuel,tech,ec,area] = 
                 exp(DmFracMSM0[enduse,fuel,tech,ec,area,year]+
                    (DmFracVF[enduse,fuel,tech,ec,area]*
          log((ECFPFuel[fuel,ec,area,year]/Inflation[area,year])/
              (ECFP0[enduse,tech,ec,area]/Inflation0[area]))))
          
      end
    end
  end
  
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DmFracTMAW[enduse,tech,ec,area] = 
      sum(DmFracMAW[enduse,fuel,tech,ec,area] for fuel in Fuels)
  end
  
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    for fuel in Fuels
      @finite_math DmFracMSF[enduse,fuel,tech,ec,area,year] =
        DmFracMAW[enduse,fuel,tech,ec,area]/DmFracTMAW[enduse,tech,ec,area]
    end
  end
  
  #
  # Apply Minimums and Maximums
  #
  @. DmFracMarginal=DmFracMSF
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    DmFracCount=1
    while DmFracCount <= 10
      
      for fuel in Fuels
        DmFracMarginal[enduse,fuel,tech,ec,area,year] = min(DmFracMax[enduse,fuel,tech,ec,area,year],
          max(DmFracMarginal[enduse,fuel,tech,ec,area,year],DmFracMin[enduse,fuel,tech,ec,area,year]))
      end
      
      DmFracTotal[enduse,tech,ec,area] = 
        sum(DmFracMarginal[enduse,fuel,tech,ec,area,year] for fuel in Fuels)
        
      for fuel in Fuels
        @finite_math DmFracMarginal[enduse,fuel,tech,ec,area,year] =
          DmFracMarginal[enduse,fuel,tech,ec,area,year]/DmFracTotal[enduse,tech,ec,area]
      end
      
      DmFracCount = DmFracCount+1
    
    end
    
  end
  
  prior = max(year-1,1)
  for area in Areas, ec in ECs, tech in Techs, enduse in Enduses
    
    for fuel in Fuels
     @finite_math DmFrac[enduse,fuel,tech,ec,area,year] = 
                  DmFrac[enduse,fuel,tech,ec,area,prior]+
        ((DmFracMarginal[enduse,fuel,tech,ec,area,year]-
                  DmFrac[enduse,fuel,tech,ec,area,prior])/
              DmFracTime[enduse,fuel,tech,ec,area,year])
    end
    
    DmFracTotal[enduse,tech,ec,area] = 
      sum(DmFrac[enduse,fuel,tech,ec,area,year] for fuel in Fuels)

    for fuel in Fuels
      @finite_math DmFrac[enduse,fuel,tech,ec,area,year] =
        DmFrac[enduse,fuel,tech,ec,area,year]/DmFracTotal[enduse,tech,ec,area]
    end
    
  end
  
  WriteDisk(db,"$Outpt/DmFrac",DmFrac)
  WriteDisk(db,"$Outpt/DmFracMarginal",DmFracMarginal)
  WriteDisk(db,"$Outpt/DmFracMSF",DmFracMSF)

end

function ControlFungible(data)

  years = collect(First:Final)
  for year in years
    Fungible(data,year)
  end

end

function ControlFlow(db)
  data = RControl(;db)
  
  InitializeFungible(data)
  ControlFungibleCalib(data)
  ControlFungible(data)

end

function CalibrationControl(db)
  @info "RCalibFungible.jl - CalibrationControl"
  
  ControlFlow(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
