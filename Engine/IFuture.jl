#
# IFuture.jl - Industrial Future values
#
# Write (" IFuture.jl, Industrial Future values")
#
# The ENERGY 2100 model and all associated software are
# the property of Systematic Solutions, Inc. and cannot
# be modified or distributed to others without expressed,
# written permission of Systematic Solutions, Inc.
# (c) 2013 Systematic Solutions, Inc. All rights reserved.
#

using EnergyModel

module IFuture

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,DT,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const Input = "IInput"
const Outpt = "IOutput"
const CalDB = "ICalDB"
const SectorName::String = "Industrial"
const SectorKey::String = "Ind"
const ESKey::String = "Industrial"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))  
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESes::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  AMSF::VariableArray{5} = ReadDisk(db,"$Outpt/AMSF"); # Capital Energy Requirement (Btu/Btu) [Enduse,Tech,EC,Area,Year]
  CalibTime::VariableArray{2} = ReadDisk(db,"$Input/CalibTime") # [EC,Area] Last Year of Calibration (Year)
  CERSM::VariableArray{4} = ReadDisk(db,"$CalDB/CERSM") # [Enduse,EC,Area,Year] Lifestyle Multiplier (Btu/Btu)
  CUF::VariableArray{5} = ReadDisk(db,"$CalDB/CUF")     # [Enduse,Tech,EC,Area,Year] Capacity Utilization Factor ($/Yr/$/Yr)
  DCMM::VariableArray{5} = ReadDisk(db,"$Input/DCMM") # Capital Cost Maximum Multiplier  ($/$) [Enduse,Tech,EC,Area]
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM")   # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency Multiplier (Btu/Btu)
  DSt::VariableArray{4} = ReadDisk(db,"$Outpt/DSt")     # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  FsPEE::VariableArray{4} = ReadDisk(db,"$CalDB/FsPEE") # [Tech,EC,Area,Year] Feedstock Process Efficiency ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # Inflation Index ($/$) [Area,Year]
  Inflation0::VariableArray{1} = ReadDisk(db,"MOutput/Inflation",First) # Inflation Index ($/$) [Area]
  MCFU::VariableArray{5} = ReadDisk(db,"$Outpt/MCFU") # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area,Year]
  MCFU0::VariableArray{4} = ReadDisk(db,"$Outpt/MCFU",First) # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  MMSM0::VariableArray{5} = ReadDisk(db,"$CalDB/MMSM0") # [Enduse,Tech,EC,Area,Year] Market Share Mult. Const. ($/$)
  MMSMI::VariableArray{4} = ReadDisk(db,"$CalDB/MMSMI") # Market Share Mult. from Income ($/$) [Enduse,Tech,EC,Area]
  MVF::VariableArray{5} = ReadDisk(db,"$CalDB/MVF") # Market Share Variance Factor ($/$) [Enduse,Tech,EC,Area,Year]
  PC::VariableArray{3} = ReadDisk(db,"MOutput/PC") # [ECC,Area,Year] Production Capacity (M$/Yr) 
  PC0::VariableArray{2} = ReadDisk(db,"MOutput/PC",First) # [ECC,Area,Year] Production Capacity (M$/Yr)
  PCA::VariableArray{4} = ReadDisk(db,"MOutput/PCA") # [Age,ECC,Area,Year] Production Capacity Additions (M$/Yr/Yr) 
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area,Year]
  PEE0::VariableArray{4} = ReadDisk(db,"$Outpt/PEE",First) # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM")   # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu))
  Pop::VariableArray{3} = ReadDisk(db,"MOutput/Pop") # Population (Millions) [ECC,Area,Year]
  Pop0::VariableArray{2} = ReadDisk(db,"MOutput/Pop",First) # Population (Millions) [ECC,Area]
  xDEMM::VariableArray{5} = ReadDisk(db,"$Input/xDEMM") # [Enduse,Tech,EC,Area,Year] Maximum Device Effic. Mult. (Btu/Btu)
  xDSt::VariableArray{4} = ReadDisk(db,"$Input/xDSt")   # [Enduse,EC,Area,Year] Device Saturation (Btu/Btu)
  xPEMM::VariableArray{5} = ReadDisk(db,"$Input/xPEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu)) 
  YMMSM::VariableArray{5} = ReadDisk(db,"$Input/YMMSM") # [Enduse,Tech,EC,Area,Year] MMSM Calibration Control

  #
  # Scratch Variables
  #
  AbsHAT::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Absolute Value of HAT Variable 
  AbsYVar::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Absolute Value of VarAv minus YVar 
  Dep::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Dependent Variable Value
  FValue::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Control Values for the Function
  HAT::VariableArray{1} = zeros(Float32,length(Year)) # [Year] The HAT Variable 
  MAW::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # Marginal Allocation Weight ($/$) [Enduse,Tech,EC,Area,Year]
  MU::VariableArray{2} = zeros(Float32,length(Tech),length(Year)) # Marginal Allocation Weight ($/$) [Enduse,Tech,EC,Area,Year]
  MUMax::VariableArray{1} = zeros(Float32,length(Year)) # Marginal Allocation Weight ($/$) [Enduse,Tech,EC,Area,Year]
  NewAv::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Average Without Current Year
  PHAT::VariableArray{1} = zeros(Float32,length(Year)) # [Year] The HAT Pick Variable 
  SPC::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # Total Production Capacity (M$/Yr) [EC,Area,Year]
  SPC0::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Total Production Capacity (M$/Yr) [EC,Area]
  SPop::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # Population (Millions) [EC,Area,Year]
  SPop0::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # Population (Millions) [EC,Area]
  TAW::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Marginal Allocation Weight ($/$) 
  Wght::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Weighting for Variable
  WghtFactor::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Weighting Factor for Variable
  YVar::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Transformed Value Value

end


function TrendValue(data)
  (;db) = data
  (;Areas,ECs,Enduses,Techs) = data
  (;CalibTime,CUF) = data

  @info "$SectorName Future.jl - TrendValue - Trend Future Values"
  
  #
  # CUF value is trended to 1.0 over 5 years
  #
  for ec in ECs, area in Areas
    if CalibTime[ec,area] < MaxTime
      CalLast = Int(max(CalibTime[ec,area]-ITime+1,1)) # patch in case CalibTime is zero - Ian
      CalFuture = CalLast + 1
      Future5 = min(CalFuture + 5,Final+1) 
    
      for tech in Techs, enduse in Enduses
    
        CUF[enduse,tech,ec,area,Future5] = 1.0
    
        years = collect(CalFuture:Future5) 
        for year in years
          CUF[enduse,tech,ec,area,year] = CUF[enduse,tech,ec,area,year-1]+
           (CUF[enduse,tech,ec,area,Future5]-CUF[enduse,tech,ec,area,CalLast])/
           (Future5-CalLast)
        end
    
        if Future5 < Final
          years = collect(Future5:Final)
        else
          years = Final
        end
        for year in years
          CUF[enduse,tech,ec,area,year] = 1.0
        end
      end
    end
  end
  WriteDisk(db,"$CalDB/CUF",CUF)    
  
end

function LastValue(data)
  (;db) = data
  (;Areas,ECs,Enduses,Techs) = data
  (;CalibTime,CERSM,DCMM,DEMM,FsPEE,PEMM) = data

  @info "$SectorName Future.jl - LastValue - Future Value is Last Value"

  for ec in ECs, area in Areas
    CalLast = Int(max(CalibTime[ec,area]-ITime+1,1)) # patch in case CalibTime is zero - Ian
    CalFuture = CalLast + 1
    years = collect(CalFuture:Final)

    for year in years, enduse in Enduses
      CERSM[enduse,ec,area,year] = CERSM[enduse,ec,area,CalLast]
    end
    
    for year in years, tech in Techs, enduse in Enduses
      DEMM[enduse,tech,ec,area,year] = DEMM[enduse,tech,ec,area,CalLast]
    end

    for year in years, tech in Techs, enduse in Enduses
      DCMM[enduse,tech,ec,area,year] = DCMM[enduse,tech,ec,area,CalLast]
    end

    for year in years, tech in Techs
      FsPEE[tech,ec,area,year] = FsPEE[tech,ec,area,CalLast]
    end
        
    for year in years, tech in Techs, enduse in Enduses
      PEMM[enduse,tech,ec,area,year] = PEMM[enduse,tech,ec,area,CalLast]
    end
  
  end

  WriteDisk(db,"$CalDB/CERSM",CERSM)
  WriteDisk(db,"$CalDB/DEMM",DEMM) 
  WriteDisk(db,"$Input/DCMM",DCMM) 
  WriteDisk(db,"$CalDB/FsPEE",FsPEE)
  WriteDisk(db,"$CalDB/PEMM",PEMM) 

  
end

function AverageMarketShareValue(data)
  (;db) = data
  (;Areas,EC,ECC,ECs,Enduses,Techs,Years) = data
  (;CalibTime,AMSF,Inflation,Inflation0,MCFU,MCFU0,MMSM0,MMSMI,MVF,PC,PC0,PEE,PEE0,Pop,Pop0,)= data
  (;MAW,MU,MUMax,SPC,SPC0,SPop,SPop0,TAW) = data

  @info "$SectorName Future.jl - AverageMarketShareValue - Future Marginal Market Share is Last Year's Average Market Share"
  
  #
  # Note that Smallest is a global variable in Banyan - Ian 12/09/24
  #
  Smallest = 1e-30
  Infinity = 1e37

  for ec in ECs,area in Areas, year in Years
    ecc = Select(ECC,EC[ec])
    SPC[ec,area,year] = PC[ecc,area,year]
    SPC0[ec,area] = PC0[ecc,area]
    SPop[ec,area,year] = Pop[ecc,area,year]
    SPop0[ec,area] = Pop0[ecc,area]
  end

  for ec in ECs, area in Areas
    CalLast = Int(max(CalibTime[ec,area]-ITime+1,1)) # patch in case CalibTime is zero - Ian
    CalFuture = CalLast + 1
    for enduse in Enduses
      Sum1 = sum(AMSF[enduse,tech,ec,area,CalLast] for tech in Techs)
      if Sum1 > 0.95
        years = collect(CalFuture:Final)
        for tech in Techs
          if MMSMI[enduse,tech,ec,area] == 0
            for year in years
              @finite_math MAW[tech,year] = exp(
              MVF[enduse,tech,ec,area,year]*log((MCFU[enduse,tech,ec,area,CalLast]/Inflation[area,year]/
              PEE[enduse,tech,ec,area,CalLast])/(MCFU0[enduse,tech,ec,area]/Inflation0[area]/PEE0[enduse,tech,ec,area])))
            end
          else
            for year in years
              @finite_math MAW[tech,year] = exp(MMSMI[enduse,tech,ec,area]*
              (SPC[ec,area,year]/SPop[ec,area,year])/(SPC0[ec,area]/SPop0[ec,area])+
              MVF[enduse,tech,ec,area,year]*log((MCFU[enduse,tech,ec,area,CalLast]/Inflation[area,year]/
              PEE[enduse,tech,ec,area,CalLast])/(MCFU0[enduse,tech,ec,area]/Inflation0[area]/PEE0[enduse,tech,ec,area])))
            end
          end
        end
        for year in years
          TAW[year] = sum(MAW[tech,year] for tech in Techs)
          for tech in Techs
            @finite_math MU[tech,year] = AMSF[enduse,tech,ec,area,CalLast] * TAW[year] / MAW[tech,year]
          end
          MUMax[year] = 0
          for tech in Techs
            MUMax[year] = max(MU[tech,year],MUMax[year])
          end
          for tech in Techs
            if MU[tech,year] .< Smallest
              MMSM0[enduse,tech,ec,area,year] = -2*log(Infinity) 
            else
              @finite_math MMSM0[enduse,tech,ec,area,year] = log(MU[tech,year]/MUMax[year])
            #
            # Set units that are very close to zero equal to zero to account for precision differences - Ian 12/03/24
            #
              if MMSM0[enduse,tech,ec,area,year] > -1.0e-14
                MMSM0[enduse,tech,ec,area,year] = 0
              end
            end
          end
        end
      else #if Sum <= 0.95
        years = collect(CalFuture:Final)
        for tech in Techs, year in years
          MMSM0[enduse,tech,ec,area,year] = MMSM0[enduse,tech,ec,area,CalLast]
        end
      end 
    end
  end

  WriteDisk(db,"$CalDB/MMSM0",MMSM0)  
  
end

# 
#  Outlier Removal [FValue(First-Last)]
#  FValue=0 means No Outliers
#  FValue=1 means Manual Outlier
#  FValue=2 means HAT Outlier
#  FValue=3 means Std-Dev Outlier
#
# Input YVar(Year) and output is Wght(Year)
# 
# ***********************
#
function Outlier(data)
  (;db) = data
  (;Areas,EC,ECC,ECs,Enduses,Techs,Years) = data
  (;AbsHAT,AbsYVar,FValue,HAT,NewAv,PHAT,Wght,WghtFactor,YVar)= data
    
  #
  # ***********************
  # 
  #    This procedure adjusts the average of the dependent variable (Dep)
  #    without the zero and the non-zero year outliers.
  #    The adjustment is done by making the weight for the dependent variable 
  #    (Wght) zero for the outlier years.
  #     
  #    Two cases need to be considered. Case 1, all of the transformed values
  #    (YVar) equal zero in the selected range. For this case, we simply set 
  #    the HAT pick variable (PHAT) equal to zero and the weight for the dependent
  #    variable (Wght) equal to zero. Case 2, some of the transformed values
  #    (YVar) equal zero in the selected range. We need to figure out which
  #    year is the outlier year. It is possible the zero year is the outlier year.
  #    We find the outlier for the non-zero variables. Then for the zero years and 
  #    the remaining non-zero years, we check to see if any year is an outlier.
  
  # 
  # Find years with zero value
  # 
  @. PHAT = 0
  years1 = collect(First:Last)
  years2 = findall(FValue[years1] .> 0)
  Sum1 = sum(YVar[year] for year in years2) 
  if Sum1 != 0
    years = findall(YVar[years2] .> 0)
    for year in years
      PHAT[year] = 1
    end
    
    #   
    # Select the non-zero variables.
    # 
    years1 = collect(First:Last)
    years2 = findall(FValue[years1] .> 0)
    years = findall(YVar[years2] .> 0)    
  
    # 
    # Compute the HAT and Std-Dev. The HAT variable is based on the
    # difference in the average with and without each year.
    # 
    TotWght = sum(Wght[year] for year in years)
    VarAv = sum((YVar[year]*Wght[year])/TotWght for year in years)
  
    for year in years
      NewAv[year] =(VarAv*TotWght-YVar[year]*Wght[year])/(TotWght-Wght[year])
      HAT[year] = (NewAv[year]-VarAv)/VarAv
    end 
  
    SDev = sqrt(sum(((VarAv-YVar[year])^2*Wght[year]) for year in years)/
          (length(years)-1))
    # 
    # Remove the non-zero outlier years.
    # If all are outliers, keep all points in the selected range.
    # 
    Max1 = maximum(FValue[year] for year in years)
    if Max1 == 2 
      for year in years
        AbsHAT[year] = abs(HAT[year])
        WghtFactor[year] = 1.0001*Wght[year]/(TotWght-Wght[year])
      end
      years = findall(AbsHAT[years] .< WghtFactor[years])
    elseif Max1 == 3 
      for year in years
        AbsYVar[year] = abs(VarAv-YVar[year])
      end
      years = findall(AbsYVar[years] .<  2*SDev)
    end
    if length(years) == length(Years)
      years1 = collect(First:Last)
      for year in years1
        PHAT[year] = 0
      end
      years = findall(FValue[years1] .> 0)    
    end
    for year in years
      PHAT[year] = 1
    end
  
    # 
    # Remove the non-zero outliers, but include the zero values 
    # 
    years1 = collect(First:Last)
    years2 = findall(FValue[years1] .> 0)
    years = findall(PHAT[years2] .== 1)     
  
    # 
    # Re-compute the HAT variable to check
    # if the zero years are outliers
    # 
    TotWght = sum(Wght[year] for year in years)
    VarAv = sum((YVar[year]*Wght[year])/TotWght for year in years)
  
    for year in years
      NewAv[year] =(VarAv*TotWght-YVar[year]*Wght[year])/(TotWght-Wght[year])
      HAT[year] = (NewAv[year]-VarAv)/VarAv
    end 
  
    SDev = sqrt(sum(((VarAv-YVar[year])^2*Wght[year]) for year in years)/
          (length(years)-1))  
    # 
    # Select the zero years
    # 
    years1 = collect(First:Last)
    years2 = findall(FValue[years1] .> 0)
    years = findall(YVar[years2] .> 0) 
    for year in years
      if YVar[year] == 0
        PHAT[year] = 0
      end
    end
  
    # 
    # Include the zero years if they are not outliers
    # 
    Max1 = maximum(FValue[year] for year in years)
    if Max1 == 2 
      for year in years
        AbsHAT[year] = abs(HAT[year])
        WghtFactor[year] = 1.0001*Wght[year]/(TotWght-Wght[year])        
      end
      years = findall(AbsHAT[years] .< WghtFactor[years])
      for year in years
        if (abs(HAT[year]) .< WghtFactor[year])
          PHAT[year] = 1
        end
      end
         
    elseif Max1 == 3 
      for year in years
        AbsYVar[year] = abs(VarAv-YVar[year])
      end
      years = findall(AbsYVar[years] .<  2*SDev) 
      for year in years
        if (abs(VarAv-YVar[year]) .<  2*SDev)
          PHAT[year] = 1
        end
      end      
  
    # 
    #   If FValue eq 1, no matter if there are outliers in the selected range, we set
    #   PHAT equal 1.
    #      
    elseif Max1 == 1  
      years = collect(First:Last)   
      for year in years
        PHAT[year] = 0
      end
      years1 = collect(First:Last)
      years = findall(FValue[years1] .== 1)
      for year in years
        PHAT[year] = 1
      end  

    else
      years = collect(First:Last)  
      for year in years
        PHAT[year] = 1
      end
    end
  end # if Max1

  # 
  # Re-compute the adjusted average without the zero and the 
  # non-zero year outliers by making Wght zero for outlier years.
  # 
  years = collect(First:Last)   
  for year in years
    Wght[year] = Wght[year]*PHAT[year]   
  end  
end # Outlier

function EstimateMethod4(data)
  (;db) = data
  (;Areas,EC,ECC,ECs,Enduses,Techs,Years) = data
  (;Dep,FValue,Wght,YVar)= data
  
  #
  # @info "Setting Values equal to the Mean"                       ")
  # Calibrated value is Mean value
  #
  
  years = collect(First:Last)    
  for year in years
    YVar[year] = Dep[year]
  end
  
  Outlier(data)
  
  for year in years
    YVar[year] = Dep[year]*Wght[year]
  end
  
  Dep[Future] = sum(YVar[year] for year in years)/
                sum(Wght[year] for year in years)
  years = collect(Future:Final)
  for year in years
    Dep[year] = Dep[Future]
  end
  
end # EstimateMethod4


function AverageMMSM0(data)
  (;db) = data
  (;Age,Areas,EC,ECC,ECs,Enduses,TechDS,Techs,Years) = data
  (;Dep,FValue,MMSM0,PCA,Wght,YMMSM)= data
  
  @info "$SectorName Future.jl - AverageMMSM0 - Average of Historical Values "  

  New = Select(Age,"New")

  # 
  # Parameterize MMSM
  #  
  for area in Areas, ec in ECs, enduse in Enduses
    ecc = Select(ECC,EC[ec])

    # 
    #   Assumption: All of the YMMSM values are less than 10 or great than 11 for
    #   every Tech and Enduse.
    #
    tech = 1
    for year in Years
      FValue[year] = YMMSM[enduse,tech,ec,area,year]
    end
    
    Method = Int(abs(FValue[Zero]))
    years = collect(First:Last) 
    if Method < 10
      for tech in Techs     
        years = collect(Zero:Final)
        for year in years
          FValue[year] = YMMSM[enduse,tech,ec,area,year]
        end
        Method = Int(abs(FValue[Zero]))
        years = collect(First:Last) 
        for year in years
          Dep[year] = exp(MMSM0[enduse,tech,ec,area,year])
        end
        
        for year in years
          Wght[year] = PCA[New,ecc,area,year]
        end
        
        EstimateMethod4(data)
        
        #YBOUNDS  Leave out for now - Jeff Amlin 10/13/25
        #YINTERP  Leave out for now - Jeff Amlin 10/13/25
        
        #
        # Catch LN(0) and set beyond negative Infinity
        #
        years = collect(Future:Final)
        if isnan(log(Dep[Future]))
          for year in years
            MMSM0[enduse,tech,ec,area,year] = -170.39
          end
        else
          for year in years
            MMSM0[enduse,tech,ec,area,year] = log(Dep[Future])
          end
        end
      end # for Techs

      #
      # Normalize MMSM
      #
      loc1 = maximum(MMSM0[enduse,tech,ec,area,Future] for tech in Techs)
      years = collect(Future:Final)
      for year in years, tech in Techs
        MMSM0[enduse,tech,ec,area,year] = MMSM0[enduse,tech,ec,area,year]-loc1
      end
    end
  end
  
  WriteDisk(db,"$CalDB/MMSM0",MMSM0)
  
end # AverageMMSM0

function Control(db)
  data = Data(; db)

  @info "$SectorName Future.jl - Control - Control Procedure"

  #
  # CERSM - YCERSM is Last
  # CgCUF - YCgCUF is not used
  # CgMSM - YCgMSM is not used
  # CUF - YCUF is not checked; Last value trended to 1.0; StockAdjustment.txt sets values
  #       if Last value is too far from 1.0
  # DEMM - YDEMM is Last
  # DCMM - YDCMM is Last
  # DST  - YDST is not used; DSt determined elsewhere; DSt = xDSt
  # FsPEE - YFsPEE is Last
  # PEMM - YPEMM is Last, YPEMM = 2 in Industrial_ETC.txp, but this has no impact
  
  TrendValue(data) # CUF
  LastValue(data)  # CERSM, DEMM, FsPEE, PEMM
  AverageMarketShareValue(data)  # MMSM0
  # AverageMMSM0(data) # MMSM0

end

end
