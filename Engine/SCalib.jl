#
# SCalib.jl - Energy Supply Sector Calibration
#
using EnergyModel

module SCalib

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
#  year::Int
#  prior::Int
#  next::Int
#  CTime::Int

  CalDB::String = "SCalDB"
  Input::String = "SInput"
  Outpt::String = "SOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  ClassDS::SetArray = ReadDisk(db,"MainDB/ClassDS")
  Classes::Vector{Int} = collect(Select(Class))
  DACTech::SetArray = ReadDisk(db,"SInput/DACTechKey")
  DACTechDS::SetArray = ReadDisk(db,"SInput/DACTechDS")
  DACTechs::Vector{Int} = collect(Select(DACTech))
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  DayDS::SetArray = ReadDisk(db,"MainDB/DayDS")
  Days::Vector{Int} = collect(Select(Day))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db,"MainDB/ESDS")
  ESes::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  H2Tech::SetArray = ReadDisk(db,"MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db,"MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  HourDS::SetArray = ReadDisk(db,"MainDB/HourDS")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  MonthDS::SetArray = ReadDisk(db,"MainDB/MonthDS")
  Months::Vector{Int} = collect(Select(Month))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SegKey::SetArray = ReadDisk(db,"MainDB/SegKey")
  Seg::SetArray = ReadDisk(db,"MainDB/SegKey")
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  # Year as a Float32,for use in comparison with other Float32
  Yrv::VariableArray{1} = ReadDisk(db,"MainDB/Yrv")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseAdj::VariableArray{4} = ReadDisk(db,"SCalDB/BaseAdj") # [Day,Month,Area,Year] Adjustment Based on All Years (MW/MW)
  CalibLTime::VariableArray{1} = ReadDisk(db,"SInput/CalibLTime") #[Area] Last Year of Load Curve Calibration (Year)
  CDUF::VariableArray{4} = ReadDisk(db,"SCalDB/CDUF") # [Class,Day,Month,Area] Class Use Factor for Gas
  CgLDCECC::VariableArray{6} = ReadDisk(db,"SOutput/CgLDCECC") # [ECC,Hour,Day,Month,Area,Year] Cogeneration Load Curve (MW)
  CgLDCSoldECC::VariableArray{6} = ReadDisk(db,"SOutput/CgLDCSoldECC") # [ECC,Hour,Day,Month,Area,Year] Cogeneration Sold to Grid Load Curve (MW)
  CLSF::VariableArray{5} = ReadDisk(db,"SCalDB/CLSF") # [Class,Hour,Day,Month,Area] Class Load Shape (MW/MW)
  DaysPerMonth::VariableArray{1} = ReadDisk(db,"SInput/DaysPerMonth") #[Month] Days per Month (Days/Month)
  DACLSF::VariableArray{5} = ReadDisk(db,"SCalDB/DACLSF") # [DACTech,Hour,Day,Month,Area] DAC Production Load Shape (MW/MW)
  DPKM::VariableArray{3} = ReadDisk(db,"SCalDB/DPKM") # [Month,Area,Year] Gas Peak Day Multiplier
  ENPN::VariableArray{3} = ReadDisk(db,"SOutput/ENPN") # [Fuel,Nation,Year] Price Normal ($/mmBtu)
  Exogenous::Float32 = ReadDisk(db,"MainDB/Exogenous")[1] # [tv] Exogenous = 0
  FPDChgF::VariableArray{4} = ReadDisk(db,"SCalDB/FPDChgF") # [Fuel,ES,Area,Year] Fuel Delivery Charge (Real $/mmBtu)
  FPMarginF::VariableArray{4} = ReadDisk(db,"SInput/FPMarginF") # [Fuel,ES,Area,Year] Refinery/Distributor Margin ($/$)
  FPSMF::VariableArray{4} = ReadDisk(db,"SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db,"SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  GBaseAdj::VariableArray{3} = ReadDisk(db,"SCalDB/GBaseAdj") # [Day,Month,Area] Gas Adjustment Based on All Years (MTherm/MTherm)
  H2LSF::VariableArray{5} = ReadDisk(db,"SCalDB/H2LSF") # [H2Tech,Hour,Day,Month,Area] Hydrogen Production Load Shape (MW/MW)
  HPKM::VariableArray{3} = ReadDisk(db,"SCalDB/HPKM") # [Month,Area,Year] Peak Day Multiplier (MW/MW)
  HoursPerMonth::VariableArray{1} = ReadDisk(db,"SInput/HoursPerMonth") # [Month] Hours per Month (Hours/Month)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  InflationRate::VariableArray{2} = ReadDisk(db,"MOutput/InflationRate") # [Area,Year] Inflation Rate ($/$)
  InflationRateNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationRateNation") # [Nation,Year] Inflation Rate ($/$)
  InSm::VariableArray{2} = ReadDisk(db,"MOutput/InSm") # [Area,Year] Smoothed Inflation Rate (1/Yr)
  LDCTS::VariableArray{5} = ReadDisk(db,"SOutput/LDCTS") # [ECC,Hour,Month,Area,Year] Temperature Sensitive Load Curve
  MinLd::VariableArray{3} = ReadDisk(db,"SOutput/MinLd") # [Month,Area,Year] Monthly Minimum Load (MW/Month)
  MonOut::VariableArray{3} = ReadDisk(db,"SOutput/MonOut") # [Month,Area,Year] Monthly Output (GWh/Month)
  NonExist::Float32 = ReadDisk(db,"MainDB/NonExist")[1] # [tv] NonExist = -1
  PkHr::VariableArray{3} = ReadDisk(db,"SOutput/PkHr") # [Month,Area,Year] Hour of Monthly Peak Load
  PkLoad::VariableArray{3} = ReadDisk(db,"SOutput/PkLoad") # [Month,Area,Year] Monthly Peak Load (MW/Month)
  SDUC::VariableArray{4} = ReadDisk(db,"SOutput/SDUC") # [Day,Month,Area,Year] System Load Curve (MTherm/Day)
  SegSw::VariableArray{1} = ReadDisk(db,"MainDB/SegSw") #[Seg] Segment Execution Switch
  TDEF::VariableArray{3} = ReadDisk(db,"SInput/TDEF") # [Fuel,Area,Year] T&D Efficiency (Btu/Btu)
  xCDUF::VariableArray{4} = ReadDisk(db,"SInput/xCDUF") # [Class,Day,Month,Area] Class Daily Use Factor for Gas
  xCLSF::VariableArray{5} = ReadDisk(db,"SInput/xCLSF") # [Class,Hour,Day,Month,Area] Class Load Shape (MW/MW)
  xDACLSF::VariableArray{5} = ReadDisk(db,"SpInput/xDACLSF") # [DACTech,Hour,Day,Month,Area] DAC Production Load Shape (MW/MW)
  xENPN::VariableArray{3} = ReadDisk(db,"SInput/xENPN") # [Fuel,Nation,Year] Exogenous Price Normal ($/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db,"SInput/xFPF") # [Fuel,ES,Area,Year] Delivered Fuel Prices (Real $/mmBtu)
  xH2LSF::VariableArray{5} = ReadDisk(db,"SpInput/xH2LSF") # [H2Tech,Hour,Day,Month,Area] Hydrogen Production Load Shape before Calibration (MW/MW)
  xInflation::VariableArray{2} = ReadDisk(db,"MInput/xInflation") # [Area,Year] Inflation Index ($/$)
  xInflationNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationNation") # [Nation,Year] Inflation Index ($/$)
  xInflationRate::VariableArray{2} = ReadDisk(db,"MInput/xInflationRate") # [Area,Year] Inflation Rate (1/Yr)
  xInflationRateNation::VariableArray{2} = ReadDisk(db,"MInput/xInflationRateNation") # [Nation,Year] Inflation Rate (1/Yr)
  xInSm::VariableArray{2} = ReadDisk(db,"MInput/xInSm") # [Area,Year] Smoothed Inflation Rate (1/Yr)
  xMinLd::VariableArray{3} = ReadDisk(db,"SInput/xMinLd") # [Month,Area,Year] Historical Monthly Minimum Load (MW/Month)
  xMonOut::VariableArray{3} = ReadDisk(db,"SInput/xMonOut") # [Month,Area,Year] Historical Monthly Output (GWh/Month)
  xPkLoad::VariableArray{3} = ReadDisk(db,"SInput/xPkLoad") # [Month,Area,Year] Historical Monthly Peak Load (MW/Month)
  xPkSavECC::VariableArray{3} = ReadDisk(db,"SInput/xPkSavECC") # [ECC,Area,Year] Peak Savings from Programs (MW)
  xProcSw::VariableArray{2} = ReadDisk(db,"SInput/xProcSw") #[PI,Year] "Procedure on/off Switch"
  ProcSw::VariableArray{2} = xProcSw
  xSDUC::VariableArray{4} = ReadDisk(db,"SInput/xSDUC") # [Day,Month,Area,Year] System Daily Use Curve (MTherm/Day)
  YHPKM::VariableArray{3} = ReadDisk(db,"SInput/YHPKM") # [Month,Area,Year] Calibration Control Variable for HPKM
  YEndTime::Int = ReadDisk(db,"SInput/YEndTime") # Fixed End-year for Calibration (Date)

  #
  # Scratch Variables
  #
  CDUFN::VariableArray{2} = zeros(Float32,length(Class),length(Area)) # [Class,Area] Class Daily Use Normalization Factor (MW/MW)
  CLSFN::VariableArray{2} = zeros(Float32,length(Class),length(Area)) # [Class,Area] Class Load Shape Normalization Factor (MW/MW)
  CgNetMin::VariableArray{3} = zeros(Float32,length(Month),length(Area),length(Year)) # [Month,Area,Year] Net Cogeneration Reduction to Minimum Load (MW)
  CgNetOut::VariableArray{3} = zeros(Float32,length(Month),length(Area),length(Year)) # [Month,Area,Year] Net Cogeneration Reduction from Monthly Energy (GWh)
  CgNetPk::VariableArray{3} = zeros(Float32,length(Month),length(Area),length(Year)) # [Month,Area,Year] Net Cogeneration Reduction to Peal Load (MW)
end

function Coefficient(data)
  (;db) = data
  (;ESes) = data
  (;Fuels) = data
  (;Nations,Seg,Yrv) = data
  (;ANMap,ENPN,Exogenous,FPDChgF,FPMarginF,FPSMF,FPTaxF) = data
  (;Inflation,InflationNation,InflationRate,InflationRateNation,InSm) = data
  (;NonExist,ProcSw,SegSw) = data
  (;xENPN,xFPF,xInflation,xInflationNation,xInflationRate) = data
  (;xInflationRateNation,xInSm,YEndTime) = data

  @info "SCalib.jl,Coefficient"

  YLast = YEndTime-Yrv[1]+1
  #
  ProcSw[1] = 0
  #
  @. ENPN = xENPN
  WriteDisk(db,"SOutput/ENPN",ENPN)

  #
  # Initialize inflation
  #
  @. Inflation = xInflation
  @. InflationNation = xInflationNation
  @. InflationRate = xInflationRate
  @. InflationRateNation = xInflationRateNation
  @. InSm = xInSm
  WriteDisk(db,"MOutput/Inflation",Inflation)
  WriteDisk(db,"MOutput/InflationNation",InflationNation)
  WriteDisk(db,"MOutput/InflationRate",InflationRate)
  WriteDisk(db,"MOutput/InflationRateNation",InflationRateNation)
  WriteDisk(db,"MOutput/InSm",InSm)

  #
  # Write (" SCalib.src, Calibration ---- Delivery Charge.  Fuel Prices")
  #
  @. FPDChgF = 0
  for nation in Nations
    areas = findall(ANMap[:,nation] .== 1)
    for area in areas
      if ANMap[area,nation] == 1
        for es in ESes, fuel in Fuels
          #
          # Define the historical and future periods, based on the first year
          # when the price (xFPF) is zero.
          #
          years = findall(xFPF[fuel,es,area,:] .!= 0.0)
          if !isempty(years)
            Last1 = maximum(years)
          else
            Last1 = MaxTime-ITime+1
          end
          years = collect(Zero:Last1)
          for year in years
            #
            # Calculate the delivery charge (FPDChgF)
            #
            @finite_math FPDChgF[fuel,es,area,year] = xFPF[fuel,es,area,year]/
              (1+FPSMF[fuel,es,area,year])-xENPN[fuel,nation,year]*
              (1+FPMarginF[fuel,es,area,year])-FPTaxF[fuel,es,area,year]
          end
        end
      end
    end
  end
  WriteDisk(db,"SCalDB/FPDChgF",FPDChgF)

  #
  ########################
  #
  # Set all supply sectors to non exist so price calibration
  # will work without leaving supply sector.  For the supply sectors
  # which actually do exist prices should be exogenous.  This will
  # allow model prices to be equal to historical or exogenous prices.
  #
  segs = Select(Seg,(from = "Gas",to = "Electric"))
  for seg in segs
    SegSw[seg] = NonExist
  end
  #
  Supply = Select(Seg,"Supply")
  SegSw[Supply] = Exogenous
  WriteDisk(db,"MainDB/SegSw",SegSw)
  
  #
  # TODOJulia These variables do not seem to be needed - Jeff Amlin 8/23/24
  #
  # TEST=True
  # CTime=STime
  # Write Disk(CTime)
  # BTime=CTime
  # Write Disk(BTime)
  # EndTime=YEndTime+Yrv(1)-1
  # Write Disk(EndTime)
  # YLast=YEndTime+Yrv(1)-1
  # Clear*


end # function Coefficient

function LEInitial(data)
  (;db) = data
  (;BaseAdj,CLSF,DACLSF) = data
  (;H2LSF,HPKM) = data
  (;PkLoad) = data
  (;xCLSF,xDACLSF,xH2LSF) = data
  (;xPkLoad) = data

  #
  # Initialize Variables for Electric Loadcurve Calibration
  #
  # @info " SCalib.src, Electric Load Curve Initialization - LEInitial"
  #
  @. BaseAdj = 1.0
  @. CLSF = xCLSF
  @. DACLSF = xDACLSF
  @. H2LSF = xH2LSF
  @. PkLoad = xPkLoad
  @. HPKM = 1.0

  WriteDisk(db,"SCalDB/BaseAdj",BaseAdj)
  WriteDisk(db,"SCalDB/DACLSF",DACLSF)
  WriteDisk(db,"SCalDB/CLSF",CLSF)
  WriteDisk(db,"SCalDB/H2LSF",H2LSF)
  WriteDisk(db,"SOutput/PkLoad",PkLoad)
  WriteDisk(db,"SCalDB/HPKM",HPKM)

end

function LECalib(data)
  (;db) = data
  (;Areas,Classes,Day) = data
  (;Days,ECCs,Fuel) = data
  (;Hours,Months) = data
  (;Years,Yrv) = data
  (;BaseAdj,CalibLTime,CgLDCECC,CgLDCSoldECC,CLSF) = data
  (;HoursPerMonth,HPKM) = data
  (;LDCTS,MinLd,MonOut,PkHr,PkLoad,TDEF) = data
  (;xMinLd,xMonOut,xPkLoad,xPkSavECC,YHPKM) = data
  (;CLSFN,CgNetMin,CgNetOut,CgNetPk) = data

  #
  # Electric Load Curve Calibration
  #
  #  @info " SCalib.src, Electric Load Curve Calibration - LECalib"
  
  for area in Areas
    CalLast = Int(min(CalibLTime[area]-Yrv[1]+1,Final))
    CalFuture = Int(min(CalLast+1,Final))
    years = collect(First:CalLast)
    
    #
    # Net Cogeneration is added back before Load Curve calbration
    #
    Average = Select(Day,"Average")
    Peak = Select(Day,"Peak")
    Minimum = Select(Day,"Minimum")
    hour = 1
  
    for year in years, month in Months
    
      CgNetOut[month,area,year] = sum(CgLDCECC[ecc,hour,Average,month,area,year]-
        CgLDCSoldECC[ecc,hour,Average,month,area,year] for ecc in ECCs)*
        HoursPerMonth[month]/1000
        
      CgNetPk[month,area,year] = sum(CgLDCECC[ecc,hour,Peak,month,area,year]-
        CgLDCSoldECC[ecc,hour,Peak,month,area,year] for ecc in ECCs)
        
      CgNetMin[month,area,year] = sum(CgLDCECC[ecc,hour,Minimum,month,area,year]-
        CgLDCSoldECC[ecc,hour,Minimum,month,area,year] for ecc in ECCs)
    end
  
  #
  # Adjust load curve based on the loss factor and cogeneration
  #
    Electric = Select(Fuel,"Electric")
    for year in years, month in Months
      PkLoad[month,area,year] = 
        PkLoad[month,area,year]*TDEF[Electric,area,year]+CgNetPk[month,area,year]
      xPkLoad[month,area,year] =
        xPkLoad[month,area,year]*TDEF[Electric,area,year]+CgNetPk[month,area,year]
      MonOut[month,area,year] =
        MonOut[month,area,year]*TDEF[Electric,area,year]+CgNetOut[month,area,year]
      xMonOut[month,area,year] =
        xMonOut[month,area,year]*TDEF[Electric,area,year]+CgNetOut[month,area,year]
      MinLd[month,area,year] =
        MinLd[month,area,year]*TDEF[Electric,area,year]+CgNetMin[month,area,year]
      xMinLd[month,area,year] =
        xMinLd[month,area,year]*TDEF[Electric,area,year]+CgNetMin[month,area,year]
    end
      
    #
    # Adjust Monthly Energy Values based on the difference between the
    # historical and model produced monthly energy values.
    #
    for year in years, month in Months
      @finite_math BaseAdj[Average,month,area,year] = 
        sum(xMonOut[month,area,yyy] for yyy in years)/
        sum(MonOut[month,area,yy] for yy in years)
    end
    
    for class in Classes, month in Months
      CLSF[class,hour,Average,month,area] = CLSF[class,hour,Average,month,area]*
                                            BaseAdj[Average,month,area,First]
    end
       
    #
    # Re-normalize the average load shapes so that the weighted sum
    # continues to equal 1.0
    #
    for class in Classes
      CLSFN[class,area] = sum(CLSF[class,hour,Average,month,area]*HoursPerMonth[month]
                          for month in Months, hour in Hours)/8760
    end
    
    hour = 1
    for month in Months, class in Classes
      @finite_math CLSF[class,hour,Average,month,area] = 
                   CLSF[class,hour,Average,month,area]/CLSFN[class,area]
    end
    
    #
    # Adjust the minimum day loadshapes based on the difference between the
    # the historical and model produced minimum loads.
    #
    for year in years, month in Months
      @finite_math BaseAdj[Minimum,month,area,year] = xMinLd[month,area,year]/MinLd[month,area,year]
    end
      
    #
    # Adjust the peak day loadshapes based on the difference between the
    # the historical and model produced peak loads.
    #
    for year in years, month in Months
      @finite_math BaseAdj[Peak,month,area,year] = (xPkLoad[month,area,year]+
        sum(xPkSavECC[ecc,area,year] for ecc in ECCs))/
        (PkLoad[month,area,year]+sum(xPkSavECC[ecc,area,year] for ecc in ECCs))
    end
    
    #
    # Apply the average peak load adjustment to the model produced
    # monthly peaks (PkLoad).
    #
    for year in years,month in Months
      PkLoad[month,area,year] = PkLoad[month,area,year]*BaseAdj[Peak,month,area,year]
    end
    
    #
    # Compute the annual adjustments to the peak days
    #
    for year in years,month in Months      
      hour = max(Int(PkHr[month,area,year]),1)
      @finite_math HPKM[month,area,year] = HPKM[month,area,year]*
        (1+(xPkLoad[month,area,year]-PkLoad[month,area,year])/
        sum(LDCTS[ecc,hour,month,area,year]*BaseAdj[Peak,month,area,year] for ecc in ECCs))
    end
    
    #
    # Set future values for the peak day multiplier (HPKM)
    #
    for month in Months
      if YHPKM[month,area,Zero] == 1
        years = collect(CalFuture:Final)
        for year in years
          HPKM[month,area,year] = YHPKM[month,area,year]
          for day in Days
            BaseAdj[day,month,area,year] = BaseAdj[day,month,area,CalLast]
          end
        end
      elseif YHPKM[month,area,Zero] == 1
        Loc1 = Int(min(CalFuture+5,Final))
        Loc2 = Int(min(Loc1+1,Final))
        years = collect(CalFuture:Loc1)
        for year in years, day in Days
          @finite_math BaseAdj[day,month,area,year] = BaseAdj[day,month,area,year-1]+
            (1.0-BaseAdj[day,month,area,CalLast])/length(years)
        end
        for year in years
          @finite_math HPKM[month,area,year] = HPKM[month,area,year-1]+
            (YHPKM[month,area,Loc2]-HPKM[month,area,CalLast])/length(years)
        end
        years = collect(Loc2-Final)
        for year in years, day in Days
          BaseAdj[day,month,area,year] = 1.0
        end
        for year in years
          HPKM[month,area,year] = YHPKM[month,area,year]
        end
      end
    end
  end

  WriteDisk(db,"SCalDB/BaseAdj",BaseAdj)
  WriteDisk(db,"SCalDB/CLSF",CLSF)
  WriteDisk(db,"SCalDB/HPKM",HPKM)

end

function LGINITIAL(data)
  (;db) = data
  (;CDUF,DPKM) = data
  (;GBaseAdj) = data
  (;xCDUF) = data

  #
  # Calibrate the Load Shape Factors to the Seasonal Peaks
  #
  #  @info " SCalib.src, Gas Utility Daily Use Factor Initialization"
  #
  # Set switches for executing the load curve portion of the model.
  #
  @. GBaseAdj = 1.0
  @. CDUF = xCDUF
  @. DPKM = 1.0

  WriteDisk(db,"SCalDB/GBaseAdj",GBaseAdj)
  WriteDisk(db,"SCalDB/CDUF",CDUF)
  WriteDisk(db,"SCalDB/DPKM",DPKM)

end

function LGCalib(data)
  (;db) = data
  (;Areas,Classes,Day) = data
  (;Days,Fuel) = data
  (;Fuels,Months) = data
  (;Years) = data
  (;CDUF,DaysPerMonth,DPKM) = data
  (;GBaseAdj) = data
  (;SDUC,TDEF) = data
  (;xSDUC) = data
  (;CDUFN) = data


  #
  #  @info " SCalib.src, Daily Use Calibration - LGCalib"
  #
  # Set switches for executing the load curve portion of the model.
  #

  #
  # TODOJulia Control sturcture issues
  #
  
  #
  # CTime=STime
  # Write Disk(CTime)
  # EndTime=HisTime
  # Write Disk(EndTime)
  #
  # # @info " SCalib.src, Update Estimate"
  #
  years = collect(First:Last)

  for fuel in Fuels
    if (Fuel[fuel] == "NaturalGas") || (Fuel[fuel] == "UtilityGas")
      for year in years, area in Areas, month in Months, day in Days
        SDUC[day,month,area,year] = SDUC[day,month,area,year]*TDEF[fuel,area,year]
        xSDUC[day,month,area,year] = xSDUC[day,month,area,year]*TDEF[fuel,area,year]
      end
    end
  end

  #
  # Compute the adjustment to ALL load shapes by the average difference
  # between the historical and model produced load curve
  #
  for area in Areas, month in Months, day in Days
    @finite_math GBaseAdj[day,month,area] = sum(xSDUC[day,month,area,y] for y in years)/
      sum(SDUC[day,month,area,yy] for yy in years)
  end

  #
  # Apply the adjustment to the load shapes.
  #
  for area in Areas, month in Months, day in Days, class in Classes
    CDUF[class,day,month,area] = CDUF[class,day,month,area]*GBaseAdj[day,month,area]
  end

  #
  # Re-normalize the average load shapes so that the weighted sum
  # continues to equal 1.0
  #
  Average = Select(Day,"Peak")
  for area in Areas, class in Classes
    CDUFN[class,area] = sum(CDUF[class,Average,month,area]*DaysPerMonth[month] for month in Months)/365
    for month in Months
      @finite_math CDUF[class,Average,month,area] = CDUF[class,Average,month,area]/CDUFN[class,area]
    end
  end

  #
  # Apply the adjustment (GBaseAdj) to the system load (SDUC)
  #
  Peak = Select(Day,"Peak")
  for year in Years, area in Areas, month in Months
    SDUC[Peak,month,area,year] = SDUC[Peak,month,area,year]*GBaseAdj[Peak,month,area]
  end
  #
  # Calculate the adjustment in temperature sensitive load (DPKM)
  # required to match the actual peak load
  #
  # * DPKM(M,Y)=DPKM(M,Y)*(xSDUC(D,M,Y)-(SDUC(D,M,Y)-sum(C)(TSDUC(C,D,M,Y))))/
  # *   sum(C)(TSDUC(C,D,M,Y))

  for year in years, area in Areas, month in Months
    @finite_math DPKM[month,area,year] = xSDUC[Peak,month,area,year]/SDUC[Peak,month,area,year]
  end

  #
  # Set temperature adjustment (DPKM).
  #
  # *DPKM(M,Future)=1.0
  # *Time1=Future+5
  # *Select Year(Future-Time1)
  # *DPKM(M,Y)=DPKM(M,Y-1)+(1.0-DPKM(M,Last))/Year:N
  # *Time1=Time1+1
  # *Select Year(Time1-Final)
  # *DPKM(M,Y)=DPKM(M,Future)
  # *DPKM(M,Y)=1.0

  years = collect(Future:Final)
  for year in years, area in Areas, month in Months
    DPKM[month,area,year] = DPKM[month,area,Future]
  end

  WriteDisk(db,"SCalDB/GBaseAdj",GBaseAdj)
  WriteDisk(db,"SCalDB/CDUF",CDUF)
  WriteDisk(db,"SCalDB/DPKM",DPKM)
end

end
