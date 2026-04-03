#
# CogenMarketShare.jl - Calculate CgMSM0 based on last historical year
# of the cogeneration capacity.
# 
using EnergyModel

module CogenMarketShare

include("../Core/Core.jl") 
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final
  #  
  Base.@kwdef struct CControl
    db::String
    Last=HisTime-ITime+1
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
    Tech::SetArray = ReadDisk(db,"$Input/TechKey")
    TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
    Techs::Vector{Int} = collect(Select(Tech))
    Year::SetArray = ReadDisk(db,"MainDB/YearKey")
    YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
    Years::Vector{Int} = collect(Select(Year))

    CgCUFP::VariableArray{3} = ReadDisk(db,"$Input/CgCUFP") # [Tech,EC,Area] Normal Cogen. Cap. Utilization Factor (Btu/Btu)
    CgFP::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # Electric Price ($/mmBtu) [EC,Area]
    CgFP0::VariableArray{2} = zeros(Float32,length(EC),length(Area))# Electric Price ($/mmBtu) [EC,Area]
    CgGC::VariableArray{4} = ReadDisk(db,"$Outpt/CgGC") # [Tech,EC,Area,Year] Cogeneration Generating Capacity (MW)
    CgHRtM::VariableArray{3} = ReadDisk(db,"$Input/CgHRtM",Last) # [Tech,EC,Area,Year] Marginal Cogeneration Heat Rate (Btu/KWh) 
    CgMCE::VariableArray{4} = ReadDisk(db,"$Outpt/CgMCE") # [Tech,EC,Area,Year] Cogeneration Marginal Cost of Energy ($/mmBtu)
    CgMCE0::VariableArray{3} = ReadDisk(db,"$Outpt/CgMCE",First) # [Tech,EC,Area,First] Cogeneration Marginal Cost of Energy ($/mmBtu)
    CgMSF::VariableArray{4} = ReadDisk(db,"$Outpt/CgMSF") # [Tech,EC,Area,Year] Cogeneration Market Share ($/$)
    CgMSM0::VariableArray{4} = ReadDisk(db,"$CalDB/CgMSM0") # [Tech,EC,Area,Year] Cogeneration Market Share Non-Price Factor ($/$)
    CgMSMM::VariableArray{4} = ReadDisk(db,"$Input/CgMSMM") # [Tech,EC,Area,Year] Cogeneration Market Share Mult. Policy ($/$)
    CgPot::VariableArray{4} = ReadDisk(db,"$Outpt/CgPot") # [Tech,EC,Area,Year] Cogeneration Potential (MW)
    CgPotMult::VariableArray{4} = ReadDisk(db,"$Input/CgPotMult") # [Tech,EC,Area,Year] Cogeneration Potential Multiplier (Btu/Btu)
    CgVF::VariableArray{3} = ReadDisk(db,"$CalDB/CgVF") # [Tech,EC,Area] Cogeneration Variance Factor ($/$) 
    CgPotSw::VariableArray{3} = ReadDisk(db,"$Input/CgPotSw") # [Tech,EC,Area] Cogeneration Potential Switch (0=Steam, 1=Electric)
    DER::VariableArray{4} = ReadDisk(db,"$Outpt/DER",Last) # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
    xCgMSF::VariableArray{4} = ReadDisk(db,"$CalDB/xCgMSF") # [Tech,EC,Area,Year] Exogenous Cogeneration Market Share (Btu/Btu)
    ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
    ECFP0::VariableArray{4} = ReadDisk(db,"$Outpt/ECFP",First) # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
    EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
    ElecMap::VariableArray{1} = ReadDisk(db,"$Input/ElecMap") # [Tech]
    # Scratch Variables
    CgEAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Electricity Allocation Weight ($/mmBtu)
    CgMAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Market Allocation Weight ($/$)
    CgPot0::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Potential (MW)
    CgPot1::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Potential (MW)
    CgPotElec::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Cogeneration Potential Electricity Demands (MW)
    DERSumEuTech::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] 
    DERSumEu::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) 
    # Future1  'Year after first Future Year (Year)'
  end

  function ComPolicy(db)
    data = CControl(; db)
    (;CalDB,Input) = data
    (;Areas,ECs,Enduse,Enduses,Tech) = data
    (;Techs,Years) = data
    (;CgFP,CgFP0,CgGC,CgMCE,CgMCE0,CgMSF,CgMSM0,CgMSMM,CgPot,CgPotMult) = data
    (;CgVF,CgCUFP,CgHRtM,CgPotSw,DER,xCgMSF) = data
    (;CgEAW,CgMAW,CgPot0,CgPot1,CgPotElec) = data
    (;ECFP,ECFP0,ElecMap,EEConv,Last) = data
    (;CgPotSw,DERSumEuTech,DERSumEu) = data
    
    #
    # Assign values since Promula Read Disk is not avaialble.
    #
    for tech in Techs, ec in ECs,area in Areas
      CgPotSw[tech,ec,area]=0
    end
    Electric = Select(Tech,"Electric")
    Heat = Select(Enduse,"Heat")
    for ec in ECs,area in Areas,year in Years
      CgFP[ec,area,year] = ECFP[Heat,Electric,ec,area,year]
      CgFP0[ec,area] = ECFP0[Heat,Electric,ec,area]
    end
    for ec in ECs,area in Areas
      CgPotSw[Electric,ec,area]=1
    end
    
    WriteDisk(db,"$Input/CgPotSw",CgPotSw)

    for eu in Enduses, tech in Techs, ec in ECs,area in Areas
      DERSumEu[tech,ec,area]=DERSumEu[tech,ec,area]+DER[eu,tech,ec,area]
      if (ElecMap[tech] == 1) 
        DERSumEuTech[ec,area]=DERSumEuTech[ec,area]+DER[eu,tech,ec,area]  
     end
    end
    for tech in Techs, ec in ECs,area in Areas
     @finite_math CgPot0[tech,ec,area]=DERSumEu[tech,ec,area]/CgHRtM[tech,ec,area]/8760*1000
     if (ElecMap[tech] == 1) 
       @finite_math CgPotElec[ec,area]=DERSumEuTech[ec,area]/EEConv/8760*1000 
     end
     @finite_math CgPot1[tech,ec,area]=CgPotElec[ec,area]/CgCUFP[tech,ec,area]  

     @finite_math CgPot[tech,ec,area,Last]=(CgPot0[tech,ec,area]*(1-CgPotSw[tech,ec,area])+CgPot1[tech,ec,area]*CgPotSw[tech,ec,area])  
    end
    # Cogeneration Market Share
    for tech in Techs, ec in ECs,area in Areas,year in Years
      @finite_math xCgMSF[tech,ec,area,year]=CgGC[tech,ec,area,year]/CgPot[tech,ec,area,year]
    end
    WriteDisk(db,"$CalDB/xCgMSF",xCgMSF)
    # Electricity Price for Cogeneration Comparisons
    # Select Year(Last)
    # Cogeneration Non-Price Factor
    for tech in Techs, ec in ECs,area in Areas,year in Years
      CgMSM0[tech,ec,area,year]=-170.39
    end
    for tech in Techs, ec in ECs,area in Areas
      if (xCgMSF[tech,ec,area,Last]) > 0
         # Caluculate CgMSM0 based on xCgMSF    
        @finite_math CgMAW[tech,ec,area]=exp(log(CgMSMM[tech,ec,area,Last])+CgVF[tech,ec,area]*log(CgMCE[tech,ec,area,Last]/CgMCE0[tech,ec,area]))
        #@finite_math CgEAW[tech,ec,area]=exp(CgVF[tech,ec,area]*log(CgFP[tech,ec,area]/CgFP0[ec,area]))
        @finite_math CgEAW[tech,ec,area]=exp(CgVF[tech,ec,area]*log(CgFP[ec,area,Last]/CgFP0[ec,area]))
        @finite_math CgMSM0[tech,ec,area,Last]=log((xCgMSF[tech,ec,area,Last]/CgMAW[tech,ec,area])/
                                               ((1-xCgMSF[tech,ec,area,Last])/CgEAW[tech,ec,area]))
        # Caluculate CgMSF based on CgMSM0
        @finite_math CgMAW[tech,ec,area]=exp(CgMSM0[tech,ec,area,Last]+
                        log(CgMSMM[tech,ec,area,Last])+CgVF[tech,ec,area]*
                        log(CgMCE[tech,ec,area,Last]/CgMCE0[tech,ec,area]))
                        
        @finite_math CgMSF[tech,ec,area,Last]=CgMAW[tech,ec,area]/(CgMAW[tech,ec,area]+CgEAW[tech,ec,area])
        # Adjust CgPotMult based on ratio xCgMSF/CgMSF
        if (CgMSF[tech,ec,area,Last]) > 0
          @finite_math CgPotMult[tech,ec,area,Last]=xCgMSF[tech,ec,area,Last]/CgMSF[tech,ec,area,Last]
        end
      end
    end
    years = collect(Future:Final)
    for tech in Techs, ec in ECs,area in Areas,year in years
      CgMSM0[tech,ec,area,year]=CgMSM0[tech,ec,area,Last]
      CgPotMult[tech,ec,area,year]=CgPotMult[tech,ec,area,Last]
    end
   for tech in Techs, ec in ECs,area in Areas
     CgMSM0[tech,ec,area,Last]=0
     CgPotMult[tech,ec,area,Last]=0
    end
    WriteDisk(db,"$CalDB/CgMSM0",CgMSM0)
    WriteDisk(db,"$Input/CgPotMult",CgPotMult)
  end

  Base.@kwdef struct IControl
    db::String
    Last=HisTime-ITime+1
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

    CgCUFP::VariableArray{3} = ReadDisk(db,"$Input/CgCUFP") # [Tech,EC,Area] Normal Cogen. Cap. Utilization Factor (Btu/Btu)
    
    CgFP::VariableArray{3} = zeros(Float32,length(EC),length(Area),length(Year)) # Electric Price ($/mmBtu) [EC,Area]
    CgFP0::VariableArray{2} = zeros(Float32,length(EC),length(Area))# Electric Price ($/mmBtu) [EC,Area]
    ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
    ECFP0::VariableArray{4} = ReadDisk(db,"$Outpt/ECFP",First) # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
    
    CgGC::VariableArray{4} = ReadDisk(db,"$Outpt/CgGC") # [Tech,EC,Area,Year] Cogeneration Generating Capacity (MW)
    CgHRtM::VariableArray{3} = ReadDisk(db,"$Input/CgHRtM",Last) # [Tech,EC,Area,Year] Marginal Cogeneration Heat Rate (Btu/KWh) 
    CgMCE::VariableArray{4} = ReadDisk(db,"$Outpt/CgMCE") # [Tech,EC,Area,Year] Cogeneration Marginal Cost of Energy ($/mmBtu)
    CgMCE0::VariableArray{3} = ReadDisk(db,"$Outpt/CgMCE",First) # [Tech,EC,Area,First] Cogeneration Marginal Cost of Energy ($/mmBtu)
    CgMSF::VariableArray{4} = ReadDisk(db,"$Outpt/CgMSF") # [Tech,EC,Area,Year] Cogeneration Market Share ($/$)
    CgMSM0::VariableArray{4} = ReadDisk(db,"$CalDB/CgMSM0") # [Tech,EC,Area,Year] Cogeneration Market Share Non-Price Factor ($/$)
    CgMSMM::VariableArray{4} = ReadDisk(db,"$Input/CgMSMM") # [Tech,EC,Area,Year] Cogeneration Market Share Mult. Policy ($/$)
    CgPot::VariableArray{4} = ReadDisk(db,"$Outpt/CgPot") # [Tech,EC,Area,Year] Cogeneration Potential (MW)
    CgPotMult::VariableArray{4} = ReadDisk(db,"$Input/CgPotMult") # [Tech,EC,Area,Year] Cogeneration Potential Multiplier (Btu/Btu)
    CgVF::VariableArray{3} = ReadDisk(db,"$CalDB/CgVF") # [Tech,EC,Area] Cogeneration Variance Factor ($/$) 
    CgPotSw::VariableArray{3} = ReadDisk(db,"$Input/CgPotSw") # [Tech,EC,Area] Cogeneration Potential Switch (0=Steam, 1=Electric)
    DER::VariableArray{4} = ReadDisk(db,"$Outpt/DER",Last) # [Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
    xCgMSF::VariableArray{4} = ReadDisk(db,"$CalDB/xCgMSF") # [Tech,EC,Area,Year] Exogenous Cogeneration Market Share (Btu/Btu)
   
    EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
    ElecMap::VariableArray{1} = ReadDisk(db,"$Input/ElecMap") # [Tech]
    # Scratch Variables
    CgEAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Electricity Allocation Weight ($/mmBtu)
    CgMAW::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Market Allocation Weight ($/$)
    CgPot0::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Potential (MW)
    CgPot1::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) # [Tech,EC,Area] Cogeneration Potential (MW)
    CgPotElec::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] Cogeneration Potential Electricity Demands (MW)
    DERSumEuTech::VariableArray{2} = zeros(Float32,length(EC),length(Area)) # [EC,Area] 
    DERSumEu::VariableArray{3} = zeros(Float32,length(Tech),length(EC),length(Area)) 
  end

  function IndPolicy(db)
    data = IControl(; db)
    (;CalDB,Input) = data
    (;Area,Areas,EC,ECs,Enduse,Enduses,Tech) = data
    (;Techs,Years) = data
    (;CgFP,CgFP0,CgGC,CgMCE,CgMCE0,CgMSF,CgMSM0,CgMSMM,CgPot,CgPotMult) = data
    (;CgVF,CgCUFP,CgHRtM,CgPotSw,DER,xCgMSF) = data
    (;CgEAW,CgMAW,CgPot0,CgPot1,CgPotElec) = data
    (;ECFP,ECFP0,ElecMap,EEConv,Last) = data
    (;CgPotSw,DERSumEuTech,DERSumEu) = data
    
    #
    # Assign values since Promula Read Disk is not avaialble.
    #
    for tech in Techs, ec in ECs,area in Areas
      CgPotSw[tech,ec,area]=0
    end
    Electric = Select(Tech,"Electric")
    Heat = Select(Enduse,"Heat")
    for ec in ECs,area in Areas,year in Years
      CgFP[ec,area,year] = ECFP[Heat,Electric,ec,area,year]
      CgFP0[ec,area] = ECFP0[Heat,Electric,ec,area]
    end
    for ec in ECs,area in Areas
      CgPotSw[Electric,ec,area]=1
    end
    ecs = Select(EC,["Aluminum","NonMetalMining","SAGDOilSands","CSSOilSands","FrontierOilMining"])
    for tech in Techs, ec in ecs,area in Areas
      CgPotSw[tech,ec,area]=1
    end
    WriteDisk(db,"$Input/CgPotSw",CgPotSw)

    for eu in Enduses, tech in Techs, ec in ECs,area in Areas
      DERSumEu[tech,ec,area]=DERSumEu[tech,ec,area]+DER[eu,tech,ec,area]
      if (ElecMap[tech] == 1) 
        DERSumEuTech[ec,area]=DERSumEuTech[ec,area]+DER[eu,tech,ec,area]  
     end
    end
    for tech in Techs, ec in ECs,area in Areas
     @finite_math CgPot0[tech,ec,area]=DERSumEu[tech,ec,area]/CgHRtM[tech,ec,area]/8760*1000
     if (ElecMap[tech] == 1) 
       @finite_math CgPotElec[ec,area]=DERSumEuTech[ec,area]/EEConv/8760*1000 
     end
     @finite_math CgPot1[tech,ec,area]=CgPotElec[ec,area]/CgCUFP[tech,ec,area]  

     @finite_math CgPot[tech,ec,area,Last]=(CgPot0[tech,ec,area]*(1-CgPotSw[tech,ec,area])+CgPot1[tech,ec,area]*CgPotSw[tech,ec,area])  
    end
  # Cogeneration Market Share
    for tech in Techs, ec in ECs,area in Areas,year in Years
      @finite_math xCgMSF[tech,ec,area,year]=CgGC[tech,ec,area,year]/CgPot[tech,ec,area,year]
    end
    WriteDisk(db,"$CalDB/xCgMSF",xCgMSF)
  #   # Electricity Price for Cogeneration Comparisons
  #   # Select Year(Last)
  #  Cogeneration Non-Price Factor
    for tech in Techs, ec in ECs,area in Areas,year in Years
      CgMSM0[tech,ec,area,year]=-170.39
    end
    for tech in Techs, ec in ECs,area in Areas
      if (xCgMSF[tech,ec,area,Last]) > 0
        # Caluculate CgMSM0 based on xCgMSF    
        @finite_math CgMAW[tech,ec,area]=exp(log(CgMSMM[tech,ec,area,Last])+CgVF[tech,ec,area]*log(CgMCE[tech,ec,area,Last]/CgMCE0[tech,ec,area]))
        @finite_math CgEAW[tech,ec,area]=exp(CgVF[tech,ec,area]*log(CgFP[ec,area,Last]/CgFP0[ec,area]))
        @finite_math CgMSM0[tech,ec,area,Last]=log((xCgMSF[tech,ec,area,Last]/CgMAW[tech,ec,area])/
                                               ((1-xCgMSF[tech,ec,area,Last])/CgEAW[tech,ec,area]))
        # Caluculate CgMSF based on CgMSM0
        @finite_math CgMAW[tech,ec,area]=exp(CgMSM0[tech,ec,area,Last]+
                         log(CgMSMM[tech,ec,area,Last])+CgVF[tech,ec,area]*
                         log(CgMCE[tech,ec,area,Last]/CgMCE0[tech,ec,area]))
        @finite_math CgMSF[tech,ec,area,Last]=CgMAW[tech,ec,area]/(CgMAW[tech,ec,area]+CgEAW[tech,ec,area])
        # Adjust CgPotMult based on ratio xCgMSF/CgMSF
        if (CgMSF[tech,ec,area,Last]) > 0
           @finite_math CgPotMult[tech,ec,area,Last]=xCgMSF[tech,ec,area,Last]/CgMSF[tech,ec,area,Last]
         end
      end
    end
    years = collect(Future:Final)
    for tech in Techs, ec in ECs,area in Areas,year in years
      CgMSM0[tech,ec,area,year]=CgMSM0[tech,ec,area,Last]
      CgPotMult[tech,ec,area,year]=CgPotMult[tech,ec,area,Last]
    end
    
    AB = Select(Area,"AB")
    PrimaryOilSands = Select(EC,"PrimaryOilSands")
    for tech in Techs,year in years
      CgPotMult[tech,PrimaryOilSands,AB,year]=CgPotMult[tech,PrimaryOilSands,AB,Last]*1.000
    end
    SAGDOilSands = Select(EC,"SAGDOilSands")
    for tech in Techs,year in years
      CgPotMult[tech,SAGDOilSands,AB,year]=CgPotMult[tech,SAGDOilSands,AB,Last]*0.7277*0.9219
    end
    CSSOilSands = Select(EC,"CSSOilSands")
    for tech in Techs,year in years
      CgPotMult[tech,CSSOilSands,AB,year]=CgPotMult[tech,CSSOilSands,AB,Last]*0.600
    end
    OilSandsMining = Select(EC,"OilSandsMining")
    for tech in Techs,year in years
      CgPotMult[tech,OilSandsMining,AB,year]=CgPotMult[tech,OilSandsMining,AB,Last]*0.630*0.361
    end
    OilSandsUpgraders = Select(EC,"OilSandsUpgraders")
    for tech in Techs,year in years
      CgPotMult[tech,OilSandsUpgraders,AB,year]=CgPotMult[tech,OilSandsUpgraders,AB,Last]*0.630*0.349
    end
    LightOilMining = Select(EC,"LightOilMining")
    for tech in Techs,year in years
      CgPotMult[tech,LightOilMining,AB,year]=CgPotMult[tech,LightOilMining,AB,Last]*1.444
    end
    for tech in Techs, ec in ECs,area in Areas
      CgMSM0[tech,ec,area,Last]=0
      CgPotMult[tech,ec,area,Last]=0
     end
    # Coal and Oil - no endogenous cogeneration
    # source: email from Hilary Paulin, Aug 29, 2016 - Jeff Amlin
    AreasCanada = Select(Area, (from = "ON", to = "NU"))
    techs=Select(Tech,["Coal","Oil","OffRoad"])
    for tech in techs, ec in ECs,area in AreasCanada, year in years
     CgMSM0[tech,ec,area,year]=-170.00
     CgPotMult[tech,ec,area,year]=0
    end
    # Oil Sands Upgrading in Saskatchewan - no endogenous cogeneration
    # source: Hilary Paulin per SaskPower forecasts, March 14, 2017
    SK = Select(Area,"SK")
    OilSandsUpgraders = Select(EC,"OilSandsUpgraders")
    for tech in Techs, year in years
     CgMSM0[tech,OilSandsUpgraders,SK,year]=-170.00
     CgPotMult[tech,OilSandsUpgraders,SK,year]=0
    end
    # Other Nonferrous in BC - historical multiplier is very high,
    # so set to 1.0 in forecast - Jeff Amlin 10/04/18
    BC = Select(Area,"BC")
    OtherNonferrous = Select(EC,"OtherNonferrous")
    for tech in Techs, year in years
      CgPotMult[tech,OtherNonferrous,BC,year]=1.0
    end
    # Heavy Oil Mining in NL - historical multiplier is very high,
    # so set to 1.0 in forecast - Ian 05/04/2020
    NL = Select(Area,"NL")
    HeavyOilMining = Select(EC,"HeavyOilMining")
    for tech in Techs, year in years
      CgPotMult[tech,HeavyOilMining,NL,year]=1.0
    end
    # AB Other Nonferrous - no endogenous cogeneration
    # source: Jeff Amlin  09/17/19
    for tech in Techs, year in years
      CgMSM0[tech,OtherNonferrous,AB,year]=-170.00
      CgPotMult[tech,OtherNonferrous,AB,year]=0.0
    end
    # NL Frontier Oil Mining - no endogenous cogeneration
    # source: from Thomas Dandres - Jeff Amlin  08/28/23
    FrontierOilMining = Select(EC,"FrontierOilMining")
    for tech in Techs, year in years
      CgMSM0[tech,FrontierOilMining,NL,year]=-170.00
      CgPotMult[tech,FrontierOilMining,NL,year]=0.0
    end
    WriteDisk(db,"$CalDB/CgMSM0",CgMSM0)
    WriteDisk(db,"$Input/CgPotMult",CgPotMult)
  end

  function PolicyControl(db)
    @info "CogenMarketShare.jl - PolicyControl"
    ComPolicy(db)
    IndPolicy(db)
 end

 if abspath(PROGRAM_FILE) == @__FILE__
    PolicyControl(DB)
 end

end
