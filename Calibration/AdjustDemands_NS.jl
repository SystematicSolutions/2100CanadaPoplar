#
# AdjustDemands_NS.jl - Adjust electricity demands for NS
# based on feedback from NSPI via Milica Boskovic
# - Jeff Amlin 2/7/14
#
using EnergyModel

module AdjustDemands_NS

import ...EnergyModel: ReadDisk,WriteDisk,Select, Last
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu)) 

end

function RControl(db)
  data = RCalib(; db)
  (;Area,ECs,Enduse,Enduses,Tech) = data
  (;MMSM0, PEMM) = data
  (;CalDB) = data
  
  NS = Select(Area,"NS")  
  Electric = Select(Tech,"Electric")
  years = collect(Yr(2025):Final)
  
  for year in years, ec in ECs, enduse in Enduses
    PEMM[enduse,Electric,ec,NS,year] = (PEMM[enduse,Electric,ec,NS,year-1]*(1-0.02))
  end
  
  #
  # Increase residential electric market share after 2025
  #
  enduses = Select(Enduse,["Heat","HW"])  
  for year in years, ec in ECs, enduse in enduses  
    MMSM0[enduse,Electric,ec,NS,year] = MMSM0[enduse,Electric,ec,NS,year]*(1-0.03)
  end
  
  WriteDisk(db,"$CalDB/PEMM",PEMM)
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)

end

Base.@kwdef struct CCalib
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
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu)) 
  
  #
  # Scratch Variables
  #
  # FutureM  'First Forecast Year'
  # LastM    'Last Historical Year'
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

function CControl(db)
  data = CCalib(; db)
  (;CalDB) = data
  (;Area,ECs,Enduse,Enduses) = data
  (;Tech) = data
  (;MMSM0,Penalty,PEMM) = data
  
  NS = Select(Area,"NS")  
  Electric = Select(Tech,"Electric")
  years = collect(Yr(2025):Final)
  for year in years, ec in ECs, enduse in Enduses
    PEMM[enduse,Electric,ec,NS,year] = (PEMM[enduse,Electric,ec,NS,year-1]*(1-0.02))
  end
  WriteDisk(db,"$CalDB/PEMM",PEMM)
  
  #
  # No change to Commercial Sectors
  #
  Penalty=1.0
  HW = Select(Enduse,"HW")
  CalcMMSM0(data,NS,HW,Penalty)

  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  

end

Base.@kwdef struct ICalib
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  
end

function ICalibration(db)
  data = ICalib(; db)
  
  # *
  # * OnFarmFuelUse stays constant through 2035 - Ian 08/21/14
  # * Removed 16.06.10 Hilary
  # *
  # * Select EC if ECKey ne "OnFarmFuelUse"
  # * Do If ECKey ne "OnFarmFuelUse"
  # * Select Tech(Electric), Area(NS), Year(2025-Final)
  # *  PEMM(Enduse,Tech,EC,Area,Y)=PEMM(Enduse,Tech,EC,Area,Y-1)*(1-0.02)
  # *  Select Tech*, Area*, Year*
  # * End Do If
  # * Select EC*
  # *
  # * Write Disk(PEMM)
  # *

end

function CalibrationControl(db)
  @info "AdjustDemands_NS.jl - CalibrationControl"

  RControl(db)
  CControl(db)
  ICalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
