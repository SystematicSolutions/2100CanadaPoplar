#
# AdjustMarketShare.jl - Adjust the market share parameters
# - Jeff Amlin 6/24/13
#
using EnergyModel

module AdjustMarketShare

import ...EnergyModel: ReadDisk,WriteDisk,Select, Last
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}


function CalcMMSM0(data, area, enduse, penalty, ecs_input=0)
  (;ECs) = data
  (;Techs) = data
  (;AMSF,Inflation,MCFU,MMSM0,MVF,PEE) = data
  (;MAW,MU,TAW,MCFU0,PEE0) = data
  
  #
  # To set future MMSF equal to AMSF(Last) from IFuture.src
  # Else METHOD eq 16
  #
  
  MCFULast = MCFU[enduse,Techs,ECs,area,Last]
  AMSFLast = AMSF[enduse,Techs,ECs,area,Last]
  PEELast = PEE[enduse,Techs,ECs,area,Last]
  
  years = collect(Future:Final)
  
  if ecs_input == 0
    ecs = ECs
  else
    ecs = ecs_input
  end
  
  for ec in ecs
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
        MU[tech] =AMSFLast[tech,ec]*(TAW[year]/MAW[tech,year])*penalty
        if MU[tech] <= 0.000000000000000000000001
          @finite_math MMSM0[enduse,tech,ec,area,year]  = -170.39
        else
          @finite_math MMSM0[enduse,tech,ec,area,year] = log(MU[tech])
        end
      end
      
      for year in years
        Loc1 = maximum(MMSM0[enduse,tech,ec,area,year] for tech in Techs)
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

  # Scratch Variables
 # FutureM  'First Forecast Year'
 # LastM    'Last Historical Year'
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Marginal Allocation Weight
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  Penalty::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [EC,Tech] Penalty for each Tech
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Allocation Weight
end


function RCalibration(db)
  data = RCalib(; db)
  (;Area,ECs,Enduse) = data
  (; Tech, Areas) = data
  (; Penalty, CalDB) = data
  
  areas = Select(Area,["ON","SK","MB","NL","PE","NU"])
  Heat = Select(Enduse,"Heat")
  Penalty=1.0
  for area in areas
    CalcMMSM0(data, area, Heat, Penalty)
  end
  
  
  (; MMSM0) = data
  
  #
  # SK Coal
  #
  Coal = Select(Tech,"Coal")
  SK = Select(Area,"SK")
  years = collect(Future:Final)
  @. MMSM0[Heat,Coal,ECs,SK,years] = -5.0
  
  #
  # NB and NS Oil
  #
  Oil = Select(Tech,"Oil")
  areas = Select(Area,["NB","NS"])
  @. MMSM0[Heat,Oil,ECs,areas,years] = -170.0  
  
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
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]

  # Scratch Variables
 # FutureM  'First Forecast Year'
 # LastM    'Last Historical Year'
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Marginal Allocation Weight
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  Penalty::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [EC,Tech] Penalty for each Tech
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Allocation Weight
end


function CCalibration(db)
  data = CCalib(; db)
  (;Area,Areas,ECs,Enduse,Nation) = data
  (;Tech) = data
  (;ANMap,MMSM0) = data
  (;Penalty,CalDB) = data
  
  
  #
  # Set all future Gas Heat marketshares equal to last historical year average
  #
  
  Penalty=1.0
  Heat = Select(Enduse,"Heat")
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  for area in areas
    CalcMMSM0(data, area, Heat, Penalty)
  end
  
  #
  # Set Coal Market Share to 0 in forecast - Jeff Amlin 07/30/19
  #
  Coal = Select(Tech,"Coal")
  years = collect(Future:Final)
  @. MMSM0[Heat,Coal,ECs,areas,years] = -171.0
  
  #
  # NB and NS Oil
  #
  Oil = Select(Tech, "Oil")
  areas = Select(Area,["NB","NS"])
  @. MMSM0[Heat,Oil,ECs,areas,years] = -170.0  
  
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

  # Scratch Variables
 # FutureM  'First Forecast Year'
 # LastM    'Last Historical Year'
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Marginal Allocation Weight
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  Penalty::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [EC,Tech] Penalty for each Tech
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Allocation Weight
end


function ICalibration(db)
  data = ICalib(; db)
  (; Area,EC,Enduse) = data
  (; Enduses,Tech) = data
  (; MMSM0) = data
  (; Penalty,CalDB) = data
  
  #
  # Industrial Gas
  #
  Penalty=1.0
  Heat = Select(Enduse,"Heat")
  IndustrialGas = Select(EC, ["IndustrialGas"])
  areas = Select(Area, ["ON","AB"])
  for area in areas
    CalcMMSM0(data, area, Heat, Penalty, IndustrialGas)
  end
  
  Oil = Select(Tech, "Oil")
  AB = Select(Area, "AB")
  ON = Select(Area, "ON")
  Gas = Select(Tech, "Gas")
  years = collect(Future:Final)
  @. MMSM0[Heat, Oil, IndustrialGas, AB, years] = -16.4659
  @. MMSM0[Heat, Gas, IndustrialGas, ON, years] = 0.0
  @. MMSM0[Heat, Gas, IndustrialGas, AB, years] = 0.0
  
  
  #
  # NB Pulp and Paper Mills
  #
  PulpPaperMills = Select(EC, ["PulpPaperMills"])
  NB = Select(Area, "NB")
  CalcMMSM0(data, NB, Heat, Penalty, PulpPaperMills)
  
  
  #
  # AB Other Manufacturing
  #
  OtherManufacturing = Select(EC, ["OtherManufacturing"])
  AB = Select(Area, "AB")
  CalcMMSM0(data, AB, Heat, Penalty, OtherManufacturing)
  
  
  #
  # Activate other Techs used historical for forecast
  #
  years = collect(Future:Final)
  Gas = Select(Tech, "Gas")
  Lumber = Select(EC, "Lumber")
  MB = Select(Area, "MB")
  
  #
  # Updated to only select non-electric enduses - Ian 10/20/25
  #
  enduses = Select(Enduse,["Heat","OthSub","OffRoad","Steam"])
  @. MMSM0[enduses,Gas,Lumber,MB,years] = -5.0
  
  Electric = Select(Tech, "Electric")
  @. MMSM0[enduses,Electric,Lumber,MB,years] = -10.0
  
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)

end

Base.@kwdef struct TCalib
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
  CFraction::VariableArray{5} = ReadDisk(db,"$Input/CFraction") # [Enduse,Tech,EC,Area,Year] Fraction of Production Capacity open to Conversion ($/$)
  CMSM0::VariableArray{6} = ReadDisk(db,"$CalDB/CMSM0") # [Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Multiplier ($/$)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MCFU::VariableArray{5} = ReadDisk(db,"$Outpt/MCFU") # [Enduse,Tech,EC,Area,Year] Marginal Cost of Technology Use ($/mmBtu)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Non-price Factors. ($/$)
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]

  # Scratch Variables
 # FutureM  'First Forecast Year'
 # LastM    'Last Historical Year'
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # [Tech,Year] Marginal Allocation Weight
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  Penalty::VariableArray{2} = zeros(Float32,length(EC),length(Tech)) # [EC,Tech] Penalty for each Tech
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Total Allocation Weight
end

function MarginalSetToAverage(data, area, enduse, penalty, ecs_input=0)
  (; ECs) = data
  (;Techs) = data
  (;AMSF,Inflation,MCFU,MMSM0,MVF,PEE) = data
  (;MAW,MU,TAW,MCFU0,PEE0) = data
  
  #
  # Method 16 - Non-Price Factors (MMSM0) are set so the forecast Marginal 
  # Market Share (MMSF) is equal to the Average Market Share (AMSF) in
  # the Last historical year. - Jeff Amlin 02/20/20
  #
  
  MCFULast = MCFU[enduse,Techs,ECs,area,Last]
  AMSFLast = AMSF[enduse,Techs,ECs,area,Last]
  PEELast = PEE[enduse,Techs,ECs,area,Last]
  
  years = collect(Future:Final)
  
  if ecs_input == 0
    ecs = ECs
  else
    ecs = ecs_input
  end
  
  for ec in ecs
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
        MU[tech] =AMSFLast[tech,ec]*(TAW[year]/MAW[tech,year])*penalty
        if MU[tech] <= 0.00000000000000001
          @finite_math MMSM0[enduse,tech,ec,area,year]  = -170.39
        else
          @finite_math MMSM0[enduse,tech,ec,area,year] = log(MU[tech])
        end
      end
      
      for year in years
        Loc1 = maximum(MMSM0[enduse,tech,ec,area,year] for tech in Techs)
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

function ConversionNonPriceFactors(data, ec, area)
  (;CTechs) = data
  (;Enduses,Techs) = data
  (;CFraction,CMSM0,MMSM0) = data
  
  years = collect(Future:Final)
  for enduse in Enduses, tech in Techs, ctech in CTechs, year in years
    # if CFraction[enduse,tech,ec,area,year] == 0.0
    #   @. CMSM0[enduse,tech,ctech,ec,area,year] = MMSM0[enduse,tech,ec,area,year]
    # else
    #   @. CMSM0[enduse,tech,ctech,ec,area,year] = -170.39
    # end
    @finite_math CFractionRatio = CFraction[enduse,tech,ec[1],area,year]/CFraction[enduse,tech,ec[1],area,year]
    @. CMSM0[enduse,tech,ctech,ec,area,year] = (MMSM0[enduse,tech,ec,area,year]*CFractionRatio)+(-170.39*(1-CFractionRatio))
  end
  
end

function TCalibration(db)
  data = TCalib(; db)
  (;Area,EC) = data
  (;Enduses,Nation,Tech,Techs) = data
  (;ANMap,CMSM0,MMSM0) = data
  (;Penalty,CalDB) = data
  
  Freight = Select(EC, ["Freight"])
  CN = Select(Nation,"CN")
  areas = findall(ANMap[:,CN] .== 1.0)
  Penalty=1.0
  for area in areas, enduse in Enduses
    MarginalSetToAverage(data, area, enduse, Penalty, Freight)
  end
  
  for area in areas
    ConversionNonPriceFactors(data, Freight, area)
  end
  
  Passenger = Select(EC, ["Passenger"])
  years = collect(Future:Final)
  techs=Select(Tech,!=("BusDiesel"))
  for year in years
    @. MMSM0[Enduses,techs,Passenger,areas,year] = MMSM0[Enduses,techs,Passenger,areas,Last] 
  end
  for area in areas
    ConversionNonPriceFactors(data, Passenger, area)
  end
  
  # *
  # * ON Bus Diesel uses 2019 value to fix irregular data
  # *
  # *Select Area(ON), Tech(BusDiesel)
  # *MMSM0(Enduse,Tech,EC,Area,Y)=MMSM0(Enduse,Tech,EC,Area,2019)
  # *ConversionNonPriceFactors
  
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  WriteDisk(db,"$CalDB/CMSM0",CMSM0)
  

end

function CalibrationControl(db)
  @info "AdjustMarketShare.jl - CalibrationControl"

  RCalibration(db)
  CCalibration(db)
  ICalibration(db)
  TCalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
