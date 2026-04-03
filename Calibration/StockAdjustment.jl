#
# StockAdjustment.jl
#
using EnergyModel

module StockAdjustment

import ...EnergyModel: ReadDisk,WriteDisk,Select
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
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))  
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

  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  CUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor (($/Yr)/($/Yr))
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  StockAdjustment::VariableArray{5} = ReadDisk(db,"$Input/StockAdjustment") # [Enduse,Tech,EC,Area,Year] Exogenous Capital Stock Adjustment ($/$)

  #
  # Scratch Variables
  #
  AdjustSw::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Sectors Covered By Adjustment (1/1)

end

function RAdjustStock(db)
  data = RControl(; db)
  (;Input,CalDB) = data
  (;Area,Areas,CTechs,EC,ECs,Enduses,Techs,Year) = data
  (;AdjustSw,CalibTime,CMSM0,CUF,MMSM0,StockAdjustment) = data
  
  MinCUF = 0.8
  MaxCUF=1.20
  @. StockAdjustment = 0.0
  @. AdjustSw = 1.0
  
  # 
  # Apply adjustment to all sectors but the following:
  # MB MultiFamily to fix issue with AC Geothermal - Ian 22/08/19
  #
  MultiFamily = Select(EC,"MultiFamily")
  MB = Select(Area,"MB")
  AdjustSw[MultiFamily,MB] = 0.0
  
  for area in Areas, ec in ECs
    if CalibTime[ec,area] < MaxTime && AdjustSw[ec,area] == 1
      for enduse in Enduses, tech in Techs
        
        #
        # Determine last Year for calibration and first Year of forecast
        #
        CalibYr = Int(max((CalibTime[ec,area]) - ITime + 1,1))
        Future = CalibYr + 1
        
        #
        # Adjust capital stock if CUF is too high or too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] > MaxCUF) ||
           (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
         
          StockAdjustment[enduse,tech,ec,area,Future] = CUF[enduse,tech,ec,area,CalibYr]-1
       
          years = collect(Future:Final)
          for year in years
            CUF[enduse,tech,ec,area,year] = 1.0
          end
        end
        
        #
        # Adjust market share non-price factors if CUF is too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
          years = collect(Future:Final)      
          for year in years        
            MMSM0[enduse,tech,ec,area,year] = -170.39
          end
          for year in years, ctech in CTechs        
            CMSM0[enduse,tech,ctech,ec,area,year] = -170.39
          end
        end
      end
    end
  end
  
  WriteDisk(db,"$CalDB/CMSM0",CMSM0)
  WriteDisk(db,"$CalDB/CUF",CUF)
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$Input/StockAdjustment",StockAdjustment)

end

Base.@kwdef struct CControl
  db::String

  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))
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

  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  CUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor (($/Yr)/($/Yr))
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  StockAdjustment::VariableArray{5} = ReadDisk(db,"$Input/StockAdjustment") # [Enduse,Tech,EC,Area,Year] Exogenous Capital Stock Adjustment ($/$)

  #
  # Scratch Variables
  #
  AdjustSw::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Sectors Covered By Adjustment (1/1)

end

function CAdjustStock(db)
  data = CControl(; db)
  (;Input,CalDB) = data
  (;Area,Areas,CTechs,EC,ECs,Enduses,Techs,Year) = data
  (;AdjustSw,CalibTime,CMSM0,CUF,MMSM0,StockAdjustment) = data
  
  MinCUF = 0.80
  MaxCUF = 1.20
  @. StockAdjustment = 0.0
  @. AdjustSw = 1.0
  
  for area in Areas, ec in ECs
    if CalibTime[ec,area] < MaxTime && AdjustSw[ec,area] == 1
      for enduse in Enduses, tech in Techs
      
        #
        # Determine last Year for calibration and first Year of forecast
        #
        CalibYr = Int(max((CalibTime[ec,area]) - ITime + 1,1))
        Future = CalibYr+1
      
        #
        # Adjust capital stock if CUF is too high or too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] > MaxCUF) ||
           (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
         
          StockAdjustment[enduse,tech,ec,area,Future]=CUF[enduse,tech,ec,area,CalibYr]-1
       
          years = collect(Future:Final)
          for year in years
            CUF[enduse,tech,ec,area,year] = 1.0
          end
        end
     
        #
        # Adjust market share non-price factors if CUF is too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
          years = collect(Future:Final)      
          for year in years        
            MMSM0[enduse,tech,ec,area,year] = -170.39
          end
          for year in years, ctech in CTechs        
            CMSM0[enduse,tech,ctech,ec,area,year] = -170.39
          end
        end
      end
    end
  end
  
  WriteDisk(db,"$CalDB/CMSM0",CMSM0)
  WriteDisk(db,"$CalDB/CUF",CUF)
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$Input/StockAdjustment",StockAdjustment)

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
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))
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

  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  CUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor (($/Yr)/($/Yr))
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  StockAdjustment::VariableArray{5} = ReadDisk(db,"$Input/StockAdjustment") # [Enduse,Tech,EC,Area,Year] Exogenous Capital Stock Adjustment ($/$)

  #
  # Scratch Variables
  #
  AdjustSw::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Sectors Covered By Adjustment (1/1)

end

function IAdjustStock(db)
  data = IControl(; db)
  (;Input,CalDB) = data
  (;Area,Areas,CTechs,EC,ECs,Enduses,Techs,Year) = data
  (;AdjustSw,CalibTime,CMSM0,CUF,MMSM0,StockAdjustment) = data
  
  MinCUF = 0.8
  MaxCUF = 1.20
  @. StockAdjustment = 0.0
  
  # 
  # Apply adjustment to all sectors but the following:
  # BC Petroleum per e-mail from Jeff - Ian 22/08/19
  #
  @. AdjustSw = 1.0
  Petrochemicals = Select(EC, "Petrochemicals")
  BC = Select(Area,"BC")
  AdjustSw[Petrochemicals,BC] = 0.0
            
  for area in Areas, ec in ECs
    if CalibTime[ec,area] < MaxTime && AdjustSw[ec,area] == 1
      for enduse in Enduses, tech in Techs
      
        #
        # Determine last Year for calibration and first Year of forecast
        #
        CalibYr = Int(max((CalibTime[ec,area]) - ITime + 1,1))
        Future = CalibYr+1
      
        #
        # Adjust capital stock if CUF is too high or too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] > MaxCUF) ||
           (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
         
          StockAdjustment[enduse,tech,ec,area,Future]=CUF[enduse,tech,ec,area,CalibYr]-1
       
          years = collect(Future:Final)
          for year in years
            CUF[enduse,tech,ec,area,year] = 1.0
          end
        end
     
        #
        # Adjust market share non-price factors if CUF is too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
          years = collect(Future:Final)      
          for year in years        
            MMSM0[enduse,tech,ec,area,year] = -170.39
          end
          for year in years, ctech in CTechs        
            CMSM0[enduse,tech,ctech,ec,area,year] = -170.39
          end
        end
      end
    end
  end
  
  WriteDisk(db,"$CalDB/CMSM0",CMSM0)
  WriteDisk(db,"$CalDB/CUF",CUF)
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$Input/StockAdjustment",StockAdjustment)

end

Base.@kwdef struct TControl
  db::String

  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  CTech::SetArray = ReadDisk(db,"$Input/CTechKey")
  CTechDS::SetArray = ReadDisk(db,"$Input/CTechDS")
  CTechs::Vector{Int} = collect(Select(CTech))
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

  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  CUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF") # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor (($/Yr)/($/Yr))
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  StockAdjustment::VariableArray{5} = ReadDisk(db,"$Input/StockAdjustment") # [Enduse,Tech,EC,Area,Year] Exogenous Capital Stock Adjustment ($/$)

  #
  # Scratch Variables
  #
  AdjustSw::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Sectors Covered By Adjustment (1/1)

end

function TAdjustStock(db)
  data = TControl(; db)
  (;Input,CalDB) = data
  (;Area,Areas,CTechs,EC,ECs,Enduses,Techs,Year) = data
  (;AdjustSw,CalibTime,CMSM0,CUF,MMSM0,StockAdjustment) = data
  
  MinCUF = 0.8
  MaxCUF=1.20
  @. StockAdjustment = 0.0
  @. AdjustSw = 1.0 
  
  for area in Areas, ec in ECs
    if CalibTime[ec,area] < MaxTime && AdjustSw[ec,area] == 1
      for enduse in Enduses, tech in Techs
      
        #
        # Determine last Year for calibration and first Year of forecast
        #
        CalibYr = Int(max((CalibTime[ec,area]) - ITime + 1,1))
        Future = CalibYr+1
      
        #
        # Adjust capital stock if CUF is too high or too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] > MaxCUF) ||
           (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
         
          StockAdjustment[enduse,tech,ec,area,Future]=CUF[enduse,tech,ec,area,CalibYr]-1
       
          years = collect(Future:Final)
          for year in years
            CUF[enduse,tech,ec,area,year] = 1.0
          end
        end
     
        #
        # Adjust market share non-price factors if CUF is too low
        #
        if (CUF[enduse,tech,ec,area,CalibYr] < MinCUF)
          years = collect(Future:Final)      
          for year in years        
            MMSM0[enduse,tech,ec,area,year] = -170.39
          end
          for year in years, ctech in CTechs        
            CMSM0[enduse,tech,ctech,ec,area,year] = -170.39
          end
        end
      end
    end
  end
  
  WriteDisk(db,"$CalDB/CMSM0",CMSM0)
  WriteDisk(db,"$CalDB/CUF",CUF)
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$Input/StockAdjustment",StockAdjustment)

end

function Control(db)
  @info "StockAdjustment.jl - Control"

  RAdjustStock(db)
  CAdjustStock(db)
  IAdjustStock(db)
  TAdjustStock(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end

end
