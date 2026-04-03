#
# CLoad.src
#

module CLoad

import ...EnergyModel: ReadDisk,WriteDisk,Select,ITime,First,finite_inverse,finite_power,finite_exp,finite_log

const Input = "CInput"
const Outpt = "COutput"
const CalDB = "CCalDB"

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct Data
  db::String
  year::Int
  prior::Int
  next::Int
  CTime::Int

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  Areas::Vector{Int} = collect(Select(Area))
  Class::SetArray = ReadDisk(db,"MainDB/ClassKey")
  Day::SetArray = ReadDisk(db,"MainDB/DayKey")
  Days::Vector{Int} = collect(Select(Day))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int} = collect(Select(ECC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  Enduses::Vector{Int} = collect(Select(Enduse))
  ES::SetArray = ReadDisk(db,"MainDB/ESKey")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Hour::SetArray = ReadDisk(db,"MainDB/HourKey")
  Hours::Vector{Int} = collect(Select(Hour))
  Month::SetArray = ReadDisk(db,"MainDB/MonthKey")
  Months::Vector{Int} = collect(Select(Month))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  Techs::Vector{Int} = collect(Select(Tech))

  BaseAdj::VariableArray{3} = ReadDisk(db,"SCalDB/BaseAdj",year) # [Day,Month,Area] # Adjustment Based on All Years (MW/MW)
  CDUC::VariableArray{4} = ReadDisk(db,"SOutput/CDUC",year) # [Class,Day,Month,Area]# Gas Gross Load Curve (MTherm/Day)
  CgDmd::VariableArray{3} = ReadDisk(db,"$Outpt/CgDmd",year) # Cogeneration Energy Demand (TBtu/Yr) [Tech,EC,Area]
  CgEC::VariableArray{2} = ReadDisk(db,"SOutput/CgEC",year) # [ECC,Area]# Cogeneration by Economic Category (GWh/YR)
  CgEG::VariableArray{3} = ReadDisk(db,"$Outpt/CgEG",year) # [Tech,EC,Area]# Electricity from Cogeneration (GWh/YR)
  CgGen::VariableArray{3} = ReadDisk(db,"SOutput/CgGen",year) # [Fuel,ECC,Area]# Cogeneration Demands (TBtu/Yr)
  CgLDC::VariableArray{6} = ReadDisk(db,"$Outpt/CgLDC",year) # [Tech,EC,Hour,Day,Month,Area]# Cogeneration Load Curve (MW)
  CgLDCECC::VariableArray{5} = ReadDisk(db,"SOutput/CgLDCECC",year) # [ECC,Hour,Day,Month,Area]# Cogeneration Load Curve (MW)
  CgLDCSold::VariableArray{5} = ReadDisk(db,"$Outpt/CgLDCSold",year) # [EC,Hour,Day,Month,Area]# Cogeneration Sold to Grid Load Curve (MW)
  CgLDCSoldECC::VariableArray{5} = ReadDisk(db,"SOutput/CgLDCSoldECC",year) # [ECC,Hour,Day,Month,Area]# Cogeneration Sold to Grid Load Curve (MW)
  CgLSF::VariableArray{6} = ReadDisk(db,"$CalDB/CgLSF") # [Tech,EC,Hour,Day,Month,Area]# Cogeneration Load Shape (MW/MW)
  CgLSFSold::VariableArray{5} = ReadDisk(db,"$CalDB/CgLSFSold") # [EC,Hour,Day,Month,Area]# Cogeneration Sold to Grid Load Shape (MW/MW)
  Dmd::VariableArray{4} = ReadDisk(db,"$Outpt/Dmd",year) # [Enduse,Tech,EC,Area] # Energy Demand (TBtu/Yr)
  DmFrac::VariableArray{5} = ReadDisk(db,"$Outpt/DmFrac",year) # [Enduse,Fuel,Tech,EC,Area]# Demand Fuel/Tech Fraction Split (Btu/Btu)
  DPKM::VariableArray{2} = ReadDisk(db,"SCalDB/DPKM",year) # [Month,Area]  # Gas Peak Day Multiplier (Therm/Day/Therm/Day)
  DSMEU::VariableArray{4} = ReadDisk(db,"$Input/DSMEU",year) # [Enduse,Tech,EC,Area] # Exogenous Enduse DSM Adjustment (GWh/Yr)
  DUCFSw::VariableArray{1} = ReadDisk(db,"$Input/DUCFSw") # [Enduse] # Switch for Cogeneration and Feedstock Demand
  DUF::VariableArray{5} = ReadDisk(db,"$CalDB/DUF") # [Enduse,EC,Day,Month,Area] # Daily Use Factor (Therm/Therm)
  ECDUC::VariableArray{5} = zeros(Float32,length(Enduse),length(Day),length(Month),length(EC),length(Area))
  EEConv::Float32 = ReadDisk(db,"SInput/EEConv")[1] # Electric Energy Conversion (Btu/KWh)
  ESales::VariableArray{3} = ReadDisk(db,"$Outpt/ESales",year) # [Enduse,EC,Area] # Electricity Gross Demands (GWh/Yr)
  ElecDmd::VariableArray{2} = ReadDisk(db,"SOutput/ElecDmd",year) # [ECC,Area]   # Electricity Gross Demands (GWh/Yr)
  FsDmd::VariableArray{3} = ReadDisk(db,"$Outpt/FsDmd",year) # [Tech,EC,Area]   # Feedstock Energy Demand (TBtu/Yr)
  FsFrac::VariableArray{4} = ReadDisk(db,"$Outpt/FsFrac",year) # [Fuel,Tech,EC,Area]   # Feedstock Demands Fuel/Tech Split (Fraction)
  FTMap::VariableArray{2} = ReadDisk(db,"$Input/FTMap") # [Fuel,Tech]   # Map between Fuel and Tech (Map)
  GECONV::Float32 = ReadDisk(db,"SInput/GECONV")[1] # Gas Energy Conversion (Therm/mmBtu)
  GSales::VariableArray{3} = ReadDisk(db,"$Outpt/GSales",year) # [Enduse,EC,Area] # Gas Sales (MTherm/Yr)
  HPKM::VariableArray{2} = ReadDisk(db,"SCalDB/HPKM",year) # [Month,Area] # Peak Day Multiplier (MW/MW)
  LDCECC::VariableArray{5} = ReadDisk(db,"SOutput/LDCECC",year) # [ECC,Hour,Day,Month,Area] # Electric Loads Dispatched (MW)
  LDCECCGrid::VariableArray{5} = ReadDisk(db,"SOutput/LDCECCGrid",year) # [ECC,Hour,Day,Month,Area] # Electric Loads from Grid (MW)
  LDCEU::VariableArray{6} = ReadDisk(db,"$Outpt/LDCEU",year) # [Enduse,EC,Hour,Day,Month,Area] # Electric Load Curve (MW)
  LDCEUECC::VariableArray{5} = ReadDisk(db,"SOutput/LDCEUECC",year) # [ECC,Hour,Day,Month,Area] # Electric Load Curve (MW)
  LDCTS::VariableArray{4} = ReadDisk(db,"SOutput/LDCTS",year) # [ECC,Hour,Month,Area] # Temperature Sensitive Electric Peak Load (MW)
  LSF::VariableArray{6} = ReadDisk(db,"$CalDB/LSF") # [Enduse,EC,SHour,Day,Month,Area] # Temperature Sensitive Electric Peak Load (MW)
  PSoECC::VariableArray{2} = ReadDisk(db,"SOutput/PSoECC",year) # [ECC,Area] # Power Sold to Grid (GWh/Yr)
  SaEC::VariableArray{2} = ReadDisk(db,"SOutput/SaEC",year) # [ECC,Area] # Electricity Sales (GWh/Yr)
  Sales::VariableArray{3} = ReadDisk(db,"SOutput/Sales",year) # [Class,Fuel,Area] # Gas Sales (MTherm/Yr)
  TSDUC::VariableArray{4} = ReadDisk(db,"SOutput/TSDUC",year) # [Day,Month,Class,Area] # Temperature Sensitive Load Curve
  TSLoad::VariableArray{3} = ReadDisk(db,"$Input/TSLoad") # [Enduse,EC,Area] # Temperature Sensitive Fraction of Load (Btu/Btu)
  xPkSav::VariableArray{3} = ReadDisk(db,"$Input/xPkSav",year) # [Enduse,EC,Area] # Exogenous Peak Savings (MW)
end

function CogenGeneration(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,ECCs,ECs,Tech,Techs,Fuel,Fuels) = data
  (; CgEC,CgEG,CgGen,FTMap) = data

  for ecc in ECCs,area in Areas
    CgEC[ecc,area] = sum(CgGen[fuel,ecc,area] for fuel in Fuels)
  end

  for area in Areas,ec in ECs
    ecc = Select(ECC,EC[ec])
    for tech in Techs
      CgEG[tech,ec,area] = sum(CgGen[fuel,ecc,area]*FTMap[fuel,tech] for fuel in Fuels)
      if Tech[tech] == "Electric"
        fuels = Select(Fuel,["Hydro","Wind"])
        CgEG[tech,ec,area] = sum(CgGen[fuel,ecc,area] for fuel in fuels)
      end 
    end
  end
  WriteDisk(db,"SOutput/CgEC",year,CgEC)
  WriteDisk(db,"$Outpt/CgEG",year,CgEG)
end

#
function ElectricitySales(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,Techs,Fuel,ECC,Enduses) = data
  (; ESales,Dmd,DmFrac,EEConv,ElecDmd,SaEC,CgEC,PSoECC) = data

  fuel = Select(Fuel,"Electric")
  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for area in Areas,enduse in Enduses
      ESales[enduse,ec,area] = sum(Dmd[enduse,tech,ec,area]*
        DmFrac[enduse,fuel,tech,ec,area] for tech in Techs)/EEConv*1e6
    end

    for area in Areas
      ElecDmd[ecc,area] = sum(ESales[enduse,ec,area] for enduse in Enduses)
      SaEC[ecc,area] = ElecDmd[ecc,area]-CgEC[ecc,area]+PSoECC[ecc,area]
    end
  end

  WriteDisk(db,"SOutput/ElecDmd",year,ElecDmd)
  WriteDisk(db,"$Outpt/ESales",year,ESales)
  WriteDisk(db,"SOutput/SaEC",year,SaEC)
end

function LoadCurve(data::Data)
  (; db,year) = data
  (; Areas,EC,ECs,ECC,Enduses,Hours,Day,Days,Months,Techs) = data
  (; LDCEU,ESales,LSF,BaseAdj,HPKM,TSLoad,xPkSav,LDCEUECC) = data
  (; CgLDC,CgEG,CgLSF,CgLDCECC,CgLDCSold,CgLSFSold,CgLDCSoldECC,PSoECC) = data
  (; LDCECCGrid,LDCECC,LDCTS) = data

  for ec in ECs
    ecc = Select(ECC,EC[ec])
    for enduse in Enduses,hour in Hours,month in Months,area in Areas
      
      day = Select(Day,"Average")
      LDCEU[enduse,ec,hour,day,month,area] = ESales[enduse,ec,area]*
        LSF[enduse,ec,hour,day,month,area]/8760*1e3
      
      day = Select(Day,"Minimum")
      LDCEU[enduse,ec,hour,day,month,area] = ESales[enduse,ec,area]*
        LSF[enduse,ec,hour,day,month,area]*BaseAdj[day,month,area]/8760*1e3
        
      day = Select(Day,"Peak")
      LDCEU[enduse,ec,hour,day,month,area] = ESales[enduse,ec,area]*
        LSF[enduse,ec,hour,day,month,area]*BaseAdj[day,month,area]/8760*1e3*
        (HPKM[month,area]*TSLoad[enduse,ec,area]+(1-TSLoad[enduse,ec,area]))-
        xPkSav[enduse,ec,area]
    end

    for day in Days,hour in Hours,month in Months,area in Areas
     LDCEUECC[ecc,hour,day,month,area] = sum(LDCEU[enduse,ec,hour,day,month,area]
       for enduse in Enduses)
    end

    for tech in Techs,hour in Hours,day in Days,month in Months,area in Areas
      CgLDC[tech,ec,hour,day,month,area] = CgEG[tech,ec,area]*
        CgLSF[tech,ec,hour,day,month,area]/8760*1E3
    end

    for hour in Hours,day in Days,month in Months,area in Areas
      CgLDCECC[ecc,hour,day,month,area] = sum(CgLDC[tech,ec,hour,day,month,area]
        for tech in Techs)
    end

    for hour in Hours,day in Days,month in Months,area in Areas
      CgLDCSold[ec,hour,day,month,area] = PSoECC[ecc,area]*
        CgLSFSold[ec,hour,day,month,area]/8760*1E3
        
      CgLDCSoldECC[ecc,hour,day,month,area] = CgLDCSold[ec,hour,day,month,area]
    end

    for day in Days,hour in Hours,month in Months,area in Areas
      LDCECCGrid[ecc,hour,day,month,area] = LDCEUECC[ecc,hour,day,month,area]-
        CgLDCECC[ecc,hour,day,month,area]+CgLDCSoldECC[ecc,hour,day,month,area]
     end

    for day in Days,hour in Hours,month in Months,area in Areas       
      LDCECC[ecc,hour,day,month,area] = LDCEUECC[ecc,hour,day,month,area]-
        CgLDCECC[ecc,hour,day,month,area]
    end

    for hour in Hours,month in Months,area in Areas
      day = Select(Day,"Peak")
      LDCTS[ecc,hour,month,area] = sum(LDCEU[enduse,ec,hour,day,month,area]*
        TSLoad[enduse,ec,area] for enduse in Enduses)
    end

  end

  WriteDisk(db,"$Outpt/CgLDC",year,CgLDC)
  WriteDisk(db,"SOutput/CgLDCECC",year,CgLDCECC)
  WriteDisk(db,"$Outpt/CgLDCSold",year,CgLDCSold)
  WriteDisk(db,"SOutput/CgLDCSoldECC",year,CgLDCSoldECC)
  WriteDisk(db,"SOutput/LDCECC",year,LDCECC)
  WriteDisk(db,"SOutput/LDCECCGrid",year,LDCECCGrid)
  WriteDisk(db,"$Outpt/LDCEU",year,LDCEU)  
  WriteDisk(db,"SOutput/LDCEUECC",year,LDCEUECC)
  WriteDisk(db,"SOutput/LDCTS",year,LDCTS)
end

function GasSales(data::Data)
  (; db,year) = data
  (; Areas,ECs,Techs,Fuel,Enduses,Class) = data
  (; GSales,Dmd,DmFrac,CgDmd,DUCFSw,FsDmd,FsFrac,GECONV,Sales) = data

  fuel = Select(Fuel,"NaturalGas")
  for enduse in Enduses, ec in ECs, area in Areas
    GSales[enduse,ec,area] = 
     (sum(Dmd[enduse,tech,ec,area]*DmFrac[enduse,fuel,tech,ec,area] for tech in Techs)+
      sum(FsDmd[tech,ec,area]*FsFrac[fuel,tech,ec,area]*DUCFSw[enduse] for tech in Techs))*
      GECONV
  end

  fuel = Select(Fuel,"NaturalGas")
  class = Select(Class,"Com")
  for area in Areas
    Sales[class,fuel,area] = sum(GSales[enduse,ec,area] for enduse in Enduses, ec in ECs)
  end

  WriteDisk(db,"$Outpt/GSales",year,GSales)
  WriteDisk(db,"SOutput/Sales",year,Sales)
end

function DailyUseGas(data::Data)
  (; db,year) = data
  (; Areas,ECs,Day,Days,Months,Enduses,Class) = data
  (; ECDUC,GSales,DUF,DPKM,TSLoad,CDUC,TSDUC) = data

  for enduse in Enduses,day in Days,month in Months,ec in ECs,area in Areas
    ECDUC[enduse,day,month,ec,area] = GSales[enduse,ec,area]*DUF[enduse,ec,day,month,area]/365
  end

  for enduse in Enduses, month in Months,ec in ECs,area in Areas
    day = Select(Day,"Peak")
    ECDUC[enduse,day,month,ec,area] = GSales[enduse,ec,area]*(DPKM[month,area]*TSLoad[enduse,ec,area]+(1-TSLoad[enduse,ec,area]))
  end

  class = Select(Class,"Com")
  for day in Days, month in Months,area in Areas
    CDUC[class,day,month,area] = sum(ECDUC[enduse,day,month,ec,area] for enduse in Enduses,ec in ECs)
  end

  for day in Days, month in Months,area in Areas
    TSDUC[day,month,class,area] = sum(ECDUC[enduse,day,month,ec,area]*TSLoad[enduse,ec,area] for enduse in Enduses,ec in ECs)
  end

  WriteDisk(db,"SOutput/CDUC",year,CDUC)
  # WriteDisk(db,"$Outpt/ECDUC",year,ECDUC)
  WriteDisk(db,"SOutput/TSDUC",year,TSDUC)

end

function Control(data::Data)
  CogenGeneration(data)
  ElectricitySales(data)
  LoadCurve(data)
  GasSales(data)
  DailyUseGas(data)
end

end
