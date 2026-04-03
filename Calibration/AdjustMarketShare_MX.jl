#
# AdjustMarketShare_MX.jl  - Adjust the market share parameters
# - Jeff Amlin 3/28/16
#
using EnergyModel

module AdjustMarketShare_MX

import ...EnergyModel: ReadDisk,WriteDisk,Select, Last
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  AMSF::VariableArray{5} = ReadDisk(db,"$Outpt/AMSF") # [Enduse,Tech,EC,Area,Year] Average Market Share
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MCFU::VariableArray{5} = ReadDisk(db,"$Outpt/MCFU") # [Enduse,Tech,EC,Area,Year] Marginal Cost of Technology Use ($/mmBtu)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)  
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]

  #
  # Scratch Variables
  #
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Marginal Allocation Weight
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  Penalty::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [EC,Tech] Penalty for each Tech
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Allocation Weight
end

function CalcMMSM0(data, area, enduse, penalty)
  (;ECs) = data
  (;Techs) = data
  (;AMSF,Inflation,MCFU,MMSM0,MVF,PEE) = data
  (;MAW,MU,TAW, MCFU0, PEE0) = data
  
  #
  # To set future MMSF equal to AMSF(Last) from IFuture.src
  # Else METHOD eq 16
  #
  MCFULast = MCFU[enduse,Techs,ECs,area,Last]
  AMSFLast = AMSF[enduse,Techs,ECs,area,Last]
  PEELast = PEE[enduse,Techs,ECs,area,Last]
  
  years = collect(Future:Final)
  
  for ec in ECs
    AMSFLastSum = sum(AMSFLast[tech,ec] for tech in Techs)
    if AMSFLastSum > 0.95
      for year in years, tech in Techs
        @finite_math MAW[tech,year] = exp(MVF[enduse,tech,ec,area,year]*
        log((MCFULast[tech,ec]/Inflation[area,year]/PEELast[tech,ec])/
        (MCFU0[enduse,tech,ec,area]/Inflation[area,First]/PEE0[enduse,tech,ec,area])))
      end
      
      for year in years
        TAW[year] = sum(MAW[tech,year] for tech in Techs)
      end
      
      for year in years, tech in Techs
        MU[tech] =AMSFLast[tech,ec] * (TAW[year]/MAW[tech,year]) * penalty
        if MU[tech] <= 0.00001
          @finite_math MMSM0[enduse,tech,ec,area,year]  = -171.0
        else
          @finite_math MMSM0[enduse,tech,ec,area,year] = log(MU[tech])
        end
      end
      for year in years
        Loc1 = maximum(MMSM0[enduse,Techs,ec,area,year])
        for tech in Techs
          MMSM0[enduse,tech,ec,area,year] = MMSM0[enduse,tech,ec,area,year]-Loc1
        end
      end
    else
      for year in years, tech in Techs
        MMSM0[enduse,tech,ec,area,year] = MMSM0[enduse,tech,ec,area,Future]
      end
    end
  end
end


function RCalibration(db)
  data = RControl(; db)
  (;CalDB) = data
  (;Area,Enduse) = data
  (;MMSM0,Penalty) = data
  
  MX = Select(Area,"MX")
  enduses = Select(Enduse,["Heat","HW"])
  Penalty=1.0
  for enduse in enduses
    CalcMMSM0(data, MX, enduse, Penalty)
  end
  

  WriteDisk(db,"$CalDB/MMSM0",MMSM0)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
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

  AMSF::VariableArray{5} = ReadDisk(db,"$Outpt/AMSF") # [Enduse,Tech,EC,Area,Year] Average Market Share
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MCFU::VariableArray{5} = ReadDisk(db,"$Outpt/MCFU") # [Enduse,Tech,EC,Area,Year] Marginal Cost of Technology Use ($/mmBtu)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]

  #
  # Scratch Variables
  # 
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Marginal Allocation Weight
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  Penalty::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [EC,Tech] Penalty for each Tech
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Allocation Weight
end

function CCalibration(db)
  data = CControl(; db)
end

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

  AMSF::VariableArray{5} = ReadDisk(db,"$Outpt/AMSF") # [Enduse,Tech,EC,Area,Year] Average Market Share
  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MCFU::VariableArray{5} = ReadDisk(db,"$Outpt/MCFU") # [Enduse,Tech,EC,Area,Year] Marginal Cost of Technology Use ($/mmBtu)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]

  #
  # Scratch Variables
  # 
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Marginal Allocation Weight
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  Penalty::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [EC,Tech] Penalty for each Tech
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Allocation Weight
end


function ICalibration(db)
  data = IControl(; db)
end


# Base.@kwdef struct TControl
#   db::String

#   CalDB::String = "TCalDB"
#   Input::String = "TInput"
#   Outpt::String = "TOutput"

#   Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
#   AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
#   Areas::Vector{Int} = collect(Select(Area))
#   CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
#   CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
#   CTechs::Vector{Int} = collect(Select(CTech))  
#   EC::SetArray = ReadDisk(db,"$Input/ECKey")
#   ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
#   ECs::Vector{Int} = collect(Select(EC))
#   Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
#   EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
#   Enduses::Vector{Int} = collect(Select(Enduse))
#   Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
#   NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
#   Nations::Vector{Int} = collect(Select(Nation))
#   Tech::SetArray = ReadDisk(db,"$Input/TechKey")
#   TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
#   Techs::Vector{Int} = collect(Select(Tech))
#   Year::SetArray = ReadDisk(db,"MainDB/YearKey")
#   YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
#   Years::Vector{Int} = collect(Select(Year))

#   CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
#   MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)

# end


# function TCalibration(db)
#   data = TControl(; db)
#   (;CalDB) = data
#   (;Area,CTechs,EC,Enduse,Tech,Years) = data
#   (;CMSM0,MMSM0) = data
  
#   #
#   # New adjustment just for Julia version - Jeff Amlin 12/21/24
#   #
  
#   area = Select(Area,"MX") 
#   ec = Select(EC,"Passenger")
#   enduse = Select(Enduse,"Carriage")
#   tech = Select(Tech,"TrainElectric")
  
#   years = collect(Future:Final)
#   for year in years
#     MMSM0[enduse,tech,ec,area,year] = -170.3913
#   end
  
#   for year in years, ctech in CTechs
#     CMSM0[enduse,tech,ctech,ec,area,year] = MMSM0[enduse,tech,ec,area,year]
#   end
  
#   WriteDisk(db,"$CalDB/MMSM0",MMSM0)
#   WriteDisk(db,"$CalDB/CMSM0",CMSM0) 
  
  
# end

function Control(db)
  @info "AdjustMarketShare_MX.jl - Control"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  # TCalibration(db)
  
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
