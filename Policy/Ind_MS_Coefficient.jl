#
# Ind_MS_Coefficient.jl
#

using EnergyModel

module Ind_MS_Coefficient

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap")   # [Area,Nation] Map between Area and Nation
  # TODOPromula: Why is Inflation0 defined differently in Ind? - Ian 08/20/25
  Inflation0::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  MCFUBase::VariableArray{5} = ReadDisk(OGRefNameDB,"$Outpt/MCFU")        # [Enduse,Tech,EC,Area,Year] Marginal Cost of Technology Use ($/mmBtu)
  MCFU0Base::VariableArray{4} = ReadDisk(OGRefNameDB,"$Outpt/MCFU",First) # [Enduse,Tech,EC,Area,Year] Marginal Cost of Technology Use ($/mmBtu)
  MMSF::VariableArray{5} = ReadDisk(db,"$Outpt/MMSF")     # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0")   # [Enduse,Tech,EC,Area,Year] Non-price Factors ($/$)
  MSMM::VariableArray{5} = ReadDisk(db,"$Input/MSMM")     # [Enduse,Tech,EC,Area,Year] Non-Price Market Share Factor Mult.($/$)
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF")       # [Enduse,Tech,EC,Area,Year] Market Share Variance Factor ($/$)
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE")       # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEE0Base::VariableArray{4} = ReadDisk(OGRefNameDB,"$Outpt/PEE",First) # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM")       # [Enduse,EC,Area] Process Efficiency ($/Btu)
  PEMBase::VariableArray{3} = ReadDisk(OGRefNameDB,"$CalDB/PEM")        # [Enduse,EC,Area] Process Efficiency ($/Btu)
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM")     # [Enduse,Tech,EC,Area,Year] Maximum Process Efficiency Multiplier ($/mmBtu)
  PEPM::VariableArray{5} = ReadDisk(db,"$Input/PEPM")     # [Enduse,Tech,EC,Area,Year] Process Energy Price Mult. ($/$)
  PEStd::VariableArray{5} = ReadDisk(db,"$Input/PEStd")   # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard ($/Btu)
  PEStdP::VariableArray{5} = ReadDisk(db,"$Input/PEStdP") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard Policy ($/Btu)
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN")     # [Enduse,Tech,EC,Area] Process Normalized Fuel Price ($/mmBtu)
  PFTC::VariableArray{5} = ReadDisk(db,"$Outpt/PFTC")     # [Enduse,Tech,EC,Area,Year] Process Fuel Trade Off Coefficient
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xMMSF::VariableArray{5} = ReadDisk(db,"$CalDB/xMMSF")   # [Enduse,Tech,EC,Area,Year] Market Share Fraction ($/$)

  #
  # Scratch Variables
  #
  # LocT::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Scratch Variable
  PEELocal::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year))      # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  MAW::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Marginal Allocation Weight
  # MAWCheck::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Marginal Allocation Weight for Checking
  # MMSFCheck::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Market Share Fraction for Checking ($/$)
  MMSFx::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Target Market Share Fraction ($/$)
  # MSFPolicy     'Sum of Market Shares under Targets ($/$)'
  # MSFReference  'Sum of Market Shares not under Targets ($/$)'
  MU::VariableArray{1} = zeros(Float32,length(Tech)) # [Tech] Local Calibration Variable
  # TAW      'Total Allocation Weight'
  # TAWCheck 'Total Allocation Weight for Checking'
  # xMMSFMax 'Maximum Value for xMMSF ($/$)'
end

function InputData(data::IControl,enduse,ec,area,years)
  (; Areas,ECs) = data
  (; Enduses) = data
  (; Techs) = data
  (; MCFUBase,PEELocal,PEMBase,PEMM,PEPM,PEStd) = data
  (; PEStdP,PFPN,PFTC,xInflation) = data

  #
  # Policy Case Values
  #  
  for tech in Techs, year in years
    @finite_math PEELocal[enduse,tech,ec,area,year] = max(PEMBase[enduse,ec,area]*
      PEMM[enduse,tech,ec,area,year]*(1/(1+(MCFUBase[enduse,tech,ec,area,year]/
      xInflation[area,year]*PEPM[enduse,tech,ec,area,year]/
      PFPN[enduse,tech,ec,area])^PFTC[enduse,tech,ec,area,year])),
      PEStd[enduse,tech,ec,area,year],PEStdP[enduse,tech,ec,area,year]) 
  end
  
end

function MarketShareNonPriceFactors(data::IControl)
  (; CalDB,db) = data
  (; Areas,ECs,Enduses,Techs) = data
  (; Inflation0,MAW,MCFUBase,MCFU0Base) = data
  (; MMSF,MMSFx,MMSM0,MSMM,MU,MVF) = data
  (; PEELocal,PEE0Base,xInflation,xMMSF) = data
  #(; MAWCheck,TAWCheck,MMSFCheck) = data

  Smallest = 1e-30
  Infinity = 1e37
  
  for enduse in Enduses, ec in ECs, area in Areas
    years = collect(Future:Final)
    InputData(data,enduse,ec,area,years)

    for year in years
      xMMSFMax = maximum(xMMSF[enduse,:,ec,area,year])
      if xMMSFMax >= 0.0

        #
        # Market Shares which are specified by targets
        #
        techs = findall(xMMSF[enduse,:,ec,area,year] .>= 0)
        if techs != []
          MSFPolicy = sum(xMMSF[enduse,tech,ec,area,year] for tech in techs)
          if MSFPolicy <= 1.0
            for tech in techs
              MMSFx[tech] = xMMSF[enduse,tech,ec,area,year]
            end
          else
            for tech in techs
              @finite_math MMSFx[tech] = xMMSF[enduse,tech,ec,area,year] / MSFPolicy
              MSFPolicy = 1.0
            end
          end
        end

        #
        # Market Shares which are outside of targets
        #     
        techs = findall(xMMSF[enduse,:,ec,area,year] .< 0)
        if techs != []
          MSFReference = sum(MMSF[enduse,tech,ec,area,year] for tech in techs)
          for tech in techs
            @finite_math MMSFx[tech] = MMSF[enduse,tech,ec,area,year]/
              MSFReference*(1-MSFPolicy)
          end
        end

        #
        # Estimate MMSM0
        #      
        for tech in Techs
          @finite_math MAW[tech] = exp(log(MSMM[enduse,tech,ec,area,year])+
            MVF[enduse,tech,ec,area,year]*
            log((MCFUBase[enduse,tech,ec,area,year]/xInflation[area,year]/
            PEELocal[enduse,tech,ec,area,year])/
            (MCFU0Base[enduse,tech,ec,area]/Inflation0[area,year]/
            PEE0Base[enduse,tech,ec,area])))
        end
        
        TAW = sum(MAW[tech] for tech in Techs)
        for tech in Techs
          @finite_math MU[tech] = MMSFx[tech]/MAW[tech]
          MU[tech] = max(MU[tech],0)
          xxx = MU[tech]
          if isinf(xxx)
            MU[tech] = 0
          end     
        end

        MUmax = maximum(MU[:])
        
        for tech in Techs
          MMSM0[enduse,tech,ec,area,year] = log(MU[tech]/MUmax)
          if MU[tech] .< Smallest
            MMSM0[enduse,tech,ec,area,year] = -2*log(Infinity) 
          end
          xxx = MMSM0[enduse,tech,ec,area,year]
          if isinf(xxx)
            MMSM0[enduse,tech,ec,area,year] = -170.39
          end             
        end
        
        #
        # When log(MU[tech]/MUmax) fails, we need to set MMSM0 equal to -170.39.
        # For now, we assume we can set the MMSM0 with MU[tech]/MUmax less than
        # 1e-5 equal to -170.39.  We can trap the log(MU[tech]/MUmax) if there
        # is an issue with this simpler method - Jeff Amlin 7/4/24
        #
        #LogFails = 1e-5
        #for tech in Techs
        #  if MU[tech]/MUmax < LogFails
        #    MMSM0[enduse,tech,ec,area,year] = -170.39
        #  end  
        #end
        
        #
        # Check Market Share Calculation, only needed for debugging
        #
        #if year == Yr(2020) || year == Yr(2030)
        #  for tech in Techs
        #    @finite_math MAWCheck[tech] = exp(
        #      MMSM0[enduse,tech,ec,area,year]+log(MSMM[enduse,tech,ec,area,year])+
        #      MVF[enduse,tech,ec,area,year]*log(
        #        (MCFUBase[enduse,tech,ec,area,year]/xInflation[area,year]/PEE[enduse,tech,ec,area,year])/
        #        (MCFU0Base[enduse,tech,ec,area]/Inflation0[area]/PEE0Base[enduse,tech,ec,area])))
        #  end
        #  TAWCheck = sum(MAWCheck[tech] for tech in Techs)
        #  for tech in Techs
        #    MMSFCheck[tech] = MAWCheck[tech] /  TAWCheck
        #  end
        #end

      else
        for tech in Techs
          MMSM0[enduse,tech,ec,area,year] = MMSM0[enduse,tech,ec,area,year-1]
        end
      end
    end
  end

  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
end

function FuelShares(data)
  MarketShareNonPriceFactors(data)
end
     
function IndPolicy(db)
  data = IControl(; db)

  FuelShares(data)
end

function PolicyControl(db)
  @info "Ind_MS_Coefficient.jl - PolicyControl"
  IndPolicy(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  PolicyControl(DB)
end

end
