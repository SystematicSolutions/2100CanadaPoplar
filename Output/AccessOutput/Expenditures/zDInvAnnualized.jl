#
# zDInvAnnualized.jl - Write Process Investments for Access Database
#
using EnergyModel
import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB
using   ..EnergyModel: HDF5DataSetNotFoundException,E2020Folder,OutputFolder,rm_dir_contents

using HDF5,DataFrames,CSV,Printf

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct zDInvAnnualizedResData
  db::String
  
  CalDB::String = "RCalDB"
  Input::String = "RInput"
  Outpt::String = "ROutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  DInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  RefDInv::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  RefDPL::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 

  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  #
  # Scratch Variables
  #
  CapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  RefCapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  # DiscountRate  'Discount Rate'
  # Lifespan 'Last year of annualized investment'
  CurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  RefCurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  CumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)
  RefCumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zDInvAnnualizedRes_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,DInvTech,RefDInv,DPL,RefDPL) = data
  (; EndTime,Inflation,NationOutputMap) = data
  (; CapitalRecoveryFactor,RefCapitalRecoveryFactor,CurrentYearAnnualizedInvestments) = data
  (; RefCurrentYearAnnualizedInvestments,CumulativeAnnualizedInvestments) = data
  (; RefCumulativeAnnualizedInvestments,CCC,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    RefDInv .= DInvTech
    RefDPL .= DPL
  end

  DiscountRate::Float32=0.10

  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        for year in years
          for area in areas
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
          end
          CurrentYearAnnualizedInvestments[year]=sum(DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
          RefCurrentYearAnnualizedInvestments[year]=sum(RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
        end

        currentyear::Int=Yr(1990)
        CumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=Int(min(currentyear+DPL[enduse,tech,ec,1,currentyear],Final))
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        currentyear=Yr(1990)
        RefCumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=Int(min(currentyear+RefDPL[enduse,tech,ec,1,currentyear],Final))
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        for year in years
          ZZZ[year]=CumulativeAnnualizedInvestments[year]
          CCC[year]=RefCumulativeAnnualizedInvestments[year]
          if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"DInvAnnualized;",Year[year],";",NationDS[nation],";",ECDS[ec],";",
              EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
          end
        end #for year

        for area in areas
          for year in years
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
            CurrentYearAnnualizedInvestments[year]=DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
            RefCurrentYearAnnualizedInvestments[year]=RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
          end

          currentyear=Yr(1990)
          CumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=Int(min(currentyear+DPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          currentyear=Yr(1990)
        RefCumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=Int(min(currentyear+RefDPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          for year in years
            ZZZ[year]=CumulativeAnnualizedInvestments[year]
            CCC[year]=RefCumulativeAnnualizedInvestments[year]
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"DInvAnnualized;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
            end
          end #for year
        end
      end #for tech
    end #for enduse
  end #for ec

end # function zDInvAnnualizedRes_DtaRun

#
# Commercial
#
Base.@kwdef struct zDInvAnnualizedComData
  db::String
  
  CalDB::String = "CCalDB"
  Input::String = "CInput"
  Outpt::String = "COutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  DInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  RefDInv::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  RefDPL::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 

  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  #
  # Scratch Variables
  #
  CapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  RefCapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  # DiscountRate  'Discount Rate'
  # Lifespan 'Last year of annualized investment'
  CurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  RefCurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  CumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)
  RefCumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)

  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zDInvAnnualizedCom_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,DInvTech,RefDInv,DPL,RefDPL) = data
  (; EndTime,Inflation,NationOutputMap) = data
  (; CapitalRecoveryFactor,RefCapitalRecoveryFactor,CurrentYearAnnualizedInvestments) = data
  (; RefCurrentYearAnnualizedInvestments,CumulativeAnnualizedInvestments) = data
  (; RefCumulativeAnnualizedInvestments,CCC,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    RefDInv .= DInvTech
    RefDPL .= DPL
  end

  DiscountRate::Float32=0.10

  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        for year in years
          for area in areas
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
          end
          CurrentYearAnnualizedInvestments[year]=sum(DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
          RefCurrentYearAnnualizedInvestments[year]=sum(RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
        end

        currentyear::Int=Yr(1990)
        CumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=Int(min(currentyear+DPL[enduse,tech,ec,1,currentyear],Final))
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        currentyear=Yr(1990)
        RefCumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=Int(min(currentyear+RefDPL[enduse,tech,ec,1,currentyear],Final))
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        for year in years
          ZZZ[year]=CumulativeAnnualizedInvestments[year]
          CCC[year]=RefCumulativeAnnualizedInvestments[year]
          if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"DInvAnnualized;",Year[year],";",NationDS[nation],";",ECDS[ec],";",
              EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
          end
        end #for year

        for area in areas
          for year in years
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
            CurrentYearAnnualizedInvestments[year]=DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
            RefCurrentYearAnnualizedInvestments[year]=RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
          end

          currentyear=Yr(1990)
          CumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=Int(min(currentyear+DPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          currentyear=Yr(1990)
          RefCumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=Int(min(currentyear+RefDPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          for year in years
            ZZZ[year]=CumulativeAnnualizedInvestments[year]
            CCC[year]=RefCumulativeAnnualizedInvestments[year]
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"DInvAnnualized;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
            end
          end #for year
        end
      end #for tech
    end #for enduse
  end #for ec

end # function zDInvAnnualizedCom_DtaRun

#
# Industrial
#
Base.@kwdef struct zDInvAnnualizedIndData
  db::String
  
  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  DInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  RefDInv::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  RefDPL::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 

  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  #
  # Scratch Variables
  #
  CapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  RefCapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  # DiscountRate  'Discount Rate'
  # Lifespan 'Last year of annualized investment'
  CurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  RefCurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  CumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)
  RefCumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)

  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zDInvAnnualizedInd_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,DInvTech,RefDInv,DPL,RefDPL) = data
  (; EndTime,Inflation,NationOutputMap) = data
  (; CapitalRecoveryFactor,RefCapitalRecoveryFactor,CurrentYearAnnualizedInvestments) = data
  (; RefCurrentYearAnnualizedInvestments,CumulativeAnnualizedInvestments) = data
  (; RefCumulativeAnnualizedInvestments,CCC,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    RefDInv .= DInvTech
    RefDPL .= DPL
  end

  DiscountRate::Float32=0.10

  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        for year in years
          for area in areas
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
          end
          CurrentYearAnnualizedInvestments[year]=sum(DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
          RefCurrentYearAnnualizedInvestments[year]=sum(RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
        end

        currentyear::Int=Yr(1990)
        CumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=Int(min(currentyear+DPL[enduse,tech,ec,1,currentyear],Final))
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        currentyear=Yr(1990)
        RefCumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=Int(min(currentyear+RefDPL[enduse,tech,ec,1,currentyear],Final))
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        for year in years
          ZZZ[year]=CumulativeAnnualizedInvestments[year]
          CCC[year]=RefCumulativeAnnualizedInvestments[year]
          if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"DInvAnnualized;",Year[year],";",NationDS[nation],";",ECDS[ec],";",
              EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
          end
        end #for year

        for area in areas
          for year in years
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
            CurrentYearAnnualizedInvestments[year]=DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
            RefCurrentYearAnnualizedInvestments[year]=RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
          end

          currentyear=Yr(1990)
          CumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=Int(min(currentyear+DPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          currentyear=Yr(1990)
          RefCumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=Int(min(currentyear+RefDPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          for year in years
            ZZZ[year]=CumulativeAnnualizedInvestments[year]
            CCC[year]=RefCumulativeAnnualizedInvestments[year]
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"DInvAnnualized;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
            end
          end #for year
        end
      end #for tech
    end #for enduse
  end #for ec

end # function zDInvAnnualizedInd_DtaRun

#
# Transportation
#
Base.@kwdef struct zDInvAnnualizedTransData
  db::String
  
  CalDB::String = "TCalDB"
  Input::String = "TInput"
  Outpt::String = "TOutput"
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

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
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  DInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  RefDInv::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments (M$/Yr) 
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 
  RefDPL::VariableArray{5} = ReadDisk(RefNameDB,"$Outpt/DPL") # [Enduse,Tech,EC,Area,Year] Physical Life of Equipment (Years) 

  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  #
  # Scratch Variables
  #
  CapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  RefCapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  # DiscountRate  'Discount Rate'
  # Lifespan 'Last year of annualized investment'
  CurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  RefCurrentYearAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Annualized Investments (M$/Yr)
  CumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)
  RefCumulativeAnnualizedInvestments::VariableArray = zeros(Float32,length(Year)) # Cumulative Annualized Investments (M$/Yr)

  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zDInvAnnualizedTrans_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,EC,ECDS,ECs,EnduseDS,Enduses) = data
  (; Fuel,FuelDS,Fuels,Nation,NationDS,Tech,TechDS,Techs,Year) = data
  (; ANMap,BaseSw,CDTime,CDYear,DInvTech,RefDInv,DPL,RefDPL) = data
  (; EndTime,Inflation,NationOutputMap) = data
  (; CapitalRecoveryFactor,RefCapitalRecoveryFactor,CurrentYearAnnualizedInvestments) = data
  (; RefCurrentYearAnnualizedInvestments,CumulativeAnnualizedInvestments) = data
  (; RefCumulativeAnnualizedInvestments,CCC,ZZZ) = data

  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    RefDInv .= DInvTech
  end


  if BaseSw != 0
    RefDInv .= DInvTech
    RefDPL .= DPL
  end

  DiscountRate::Float32=0.10

  for ec in ECs
    for enduse in Enduses
      for tech in Techs
        for year in years
          for area in areas
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
          end
          CurrentYearAnnualizedInvestments[year]=sum(DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
          RefCurrentYearAnnualizedInvestments[year]=sum(RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)        
        end

        currentyear::Int=Yr(1990)
        CumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=trunc(Int,min(currentyear+DPL[enduse,tech,ec,1,currentyear],Final))
          # TODOLater (line 632): InexactError: Int64(20.5f0) -- LJD, 07.29.25
          # Added 'trunc' to convert Float to Int - Ian 11.26.25
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        currentyear=Yr(1990)
        RefCumulativeAnnualizedInvestments .= 0.0
        while currentyear <= Final
          Lifespan=trunc(Int,min(currentyear+RefDPL[enduse,tech,ec,1,currentyear],Final))
          years_cur=collect(currentyear:Lifespan)
          for year in years_cur
            RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
          end
          currentyear=currentyear+1
        end

        for year in years
          ZZZ[year]=CumulativeAnnualizedInvestments[year]
          CCC[year]=RefCumulativeAnnualizedInvestments[year]
          if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
            zData = @sprintf("%.6E",ZZZ[year])
            zInitial = @sprintf("%.6E",CCC[year])
            println(iob,"DInvAnnualized;",Year[year],";",NationDS[nation],";",ECDS[ec],";",
              EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
          end
        end #for year

        for area in areas
          for year in years
            CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-DPL[enduse,tech,ec,area,year]))
            RefCapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-RefDPL[enduse,tech,ec,area,year]))
            CurrentYearAnnualizedInvestments[year]=DInvTech[enduse,tech,ec,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
            RefCurrentYearAnnualizedInvestments[year]=RefDInv[enduse,tech,ec,area,year]*RefCapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
          end

          currentyear=Yr(1990)
          CumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=trunc(Int,min(currentyear+DPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              CumulativeAnnualizedInvestments[year]=CumulativeAnnualizedInvestments[year]+CurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          currentyear=Yr(1990)
          RefCumulativeAnnualizedInvestments .= 0.0
          while currentyear <= Final
            Lifespan=trunc(Int,min(currentyear+RefDPL[enduse,tech,ec,area,currentyear],Final))
            years_cur=collect(currentyear:Lifespan)
            for year in years_cur
              RefCumulativeAnnualizedInvestments[year]=RefCumulativeAnnualizedInvestments[year]+RefCurrentYearAnnualizedInvestments[currentyear]
            end
            currentyear=currentyear+1
          end

          for year in years
            ZZZ[year]=CumulativeAnnualizedInvestments[year]
            CCC[year]=RefCumulativeAnnualizedInvestments[year]
            if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
              zData = @sprintf("%.6E",ZZZ[year])
              zInitial = @sprintf("%.6E",CCC[year])
              println(iob,"DInvAnnualized;",Year[year],";",AreaDS[area],";",ECDS[ec],";",
                EnduseDS[enduse],";",TechDS[tech],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
            end
          end #for year
        end
      end #for tech
    end #for enduse
  end #for ec

end # function zDInvAnnualizedTrans_DtaRun

#
# Electric Utility
#
Base.@kwdef struct zDInvAnnualizedElecData
  db::String
 
  RefNameDB::String = ReadDisk(db,"MainDB/RefNameDB") # Reference Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")  
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")  
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Unit::SetArray = ReadDisk(db,"MainDB/UnitKey")
  Units::Vector{Int} = collect(Select(Unit))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  Yrv::VariableArray{1} = ReadDisk(db, "MainDB/Yrv")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  BaseSw::Float32 = ReadDisk(db, "SInput/BaseSw")[1]
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)

  DInvFr::VariableArray{3} = ReadDisk(db,"EGInput/DInvFr") # [Plant,Area,Year] Device Investments Fraction ($/KW/Yr)
  FlPlnMap::VariableArray{2} = ReadDisk(db,"EGInput/FlPlnMap") # [Fuel,Plant] Fuel/Plant Map
  GCBL::VariableArray{3} = ReadDisk(db,"EGInput/GCBL") # [Plant,Area,Year] Generation Capacity Book Life (Years)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  UnArea::Array{String} = ReadDisk(db,"EGInput/UnArea") # [Unit] Area Pointer
  UnCW::VariableArray{2} = ReadDisk(db, "EGOutput/UnCW") # [Unit,Year] Construction Costs ($M/Yr)
  RefUnCW::VariableArray{2} = ReadDisk(RefNameDB, "EGOutput/UnCW") # [Unit,Year] Construction Costs ($M/Yr)
  UnCogen::VariableArray{1} = ReadDisk(db,"EGInput/UnCogen") # [Unit] Industrial Self-Generation Flag (1=Self-Generation)
  UnFlFr::VariableArray{3} = ReadDisk(db,"EGOutput/UnFlFr") # [Unit,FuelEP,Year] Fuel Fraction (Btu/Btu)
  UnOnLine::VariableArray{1} = ReadDisk(db,"EGInput/UnOnLine") # [Unit] On-Line Date (Year)
  UnPlant::Array{String} = ReadDisk(db,"EGInput/UnPlant") # [Unit] Plant Type
  UnRetire::VariableArray{2} = ReadDisk(db,"EGInput/UnRetire") # [Unit,Year] Retirement Date (Year)

  EndTime::Float32 = ReadDisk(db,"SInput/EndTime")[1] #[tv]  Ending Year for Simulation (Year)
  NationOutputMap::VariableArray{1} = ReadDisk(db,"SInput/NationOutputMap") #[Nation] Map for Output Control by Nation (0=No Output)(Map)

  #
  # Scratch Variables
  #
  CapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  RefCapitalRecoveryFactor::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # [Area,Year] Capital Recovery Factor
  # DiscountRate  'Discount Rate'
  # Lifespan 'Last year of annualized investment'
  DeviceInv::VariableArray{3} = zeros(Float32,length(Plant),length(Area),length(Year)) # [Plant,Area,Year]     'Utility Device Investments ($M/Yr)'
  RefDeviceInv::VariableArray{3} = zeros(Float32,length(Plant),length(Area),length(Year)) # [Plant,Area,Year]     'Utility Device Investments ($M/Yr)'
  CurrentYearAnnualizedInvestments::VariableArray{2} = zeros(Float32,length(Plant),length(Year)) # Annualized Investments (M$/Yr)
  RefCurrentYearAnnualizedInvestments::VariableArray{2} = zeros(Float32,length(Plant),length(Year)) # Annualized Investments (M$/Yr)
  CumulativeAnnualizedInvestments::VariableArray{2} = zeros(Float32,length(Plant),length(Year)) # Cumulative Annualized Investments (M$/Yr)
  RefCumulativeAnnualizedInvestments::VariableArray{2} = zeros(Float32,length(Plant),length(Year)) # Cumulative Annualized Investments (M$/Yr)

  Conversion::VariableArray{2} = zeros(Float32,length(Nation),length(Year)) # [Nation,Year] Units Conversion Factor
  UnitsDS::SetArray = fill("",length(Nation)) # [Nation] Units Description

  CCC::VariableArray = zeros(Float32,length(Year))
  ZZZ::VariableArray = zeros(Float32,length(Year))
end

function zDInvAnnualizedElec_DtaRun(data,iob,nation,SceName)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs) = data
  (; Fuel,FuelDS,Fuels,FuelEP,FuelEPDS,FuelEPs) = data
  (; Nation,NationDS,Plant,PlantDS,Plants,Units,Year,Yrv) = data
  (; ANMap,BaseSw,CDTime,CDYear,EndTime,DInvFr,FlPlnMap,GCBL) = data
  (; Inflation,UnArea,UnCW,RefUnCW,UnCogen,UnFlFr) = data
  (; UnOnLine,UnPlant,UnRetire) = data
  (; CCC,CapitalRecoveryFactor,RefCapitalRecoveryFactor) = data
  (; DeviceInv,RefDeviceInv,CurrentYearAnnualizedInvestments) = data
  (; RefCurrentYearAnnualizedInvestments,CumulativeAnnualizedInvestments) = data
  (; RefCumulativeAnnualizedInvestments,ZZZ) = data

  ecc=Select(ECC,"UtilityGen")
  years = collect(1:Yr(EndTime))
  areas = findall(ANMap[Areas,nation] .== 1)

  if BaseSw != 0
    RefUnCW .= UnCW
  end
  
  for area in areas
    for plant in Plants
      for year in years
        DeviceInv[plant,area,year]=0.0
        RefDeviceInv[plant,area,year]=0.0
        #
        units_p=findall(UnPlant[Units] .== Plant[plant])
        units_a=findall(UnArea[Units] .== Area[area])
        units_o=findall(UnOnLine[Units] .<= Yrv[year])
        units_r=findall(UnRetire[Units] .> Yrv[year])
        units=intersect(units_p,units_a,units_o,units_r)
        for unit in units
          DeviceInv[plant,area,year]=DeviceInv[plant,area,year]+(UnCW[unit,year]*DInvFr[plant,area,year])
          RefDeviceInv[plant,area,year]=RefDeviceInv[plant,area,year]+(RefUnCW[unit,year]*DInvFr[plant,area,year])
          fuels=findall(FlPlnMap[Fuels,plant] .== 1)
          if !isempty(fuels)
            for fuel in fuels
              fueleps = findall(FuelEP[FuelEPs] .== Fuel[fuel])
              if !isempty(fueleps)
                DeviceInv[plant,area,year]=DeviceInv[plant,area,year]+(UnCW[unit,year]*DInvFr[plant,area,year]*UnFlFr[unit,first(fueleps),year])
                RefDeviceInv[plant,area,year]=RefDeviceInv[plant,area,year]+(RefUnCW[unit,year]*DInvFr[plant,area,year]*UnFlFr[unit,first(fueleps),year])
              end
            end #fuels
          end #units
        end
      end #years
    end #Plants
  end #areas

  DiscountRate::Float32=0.10
  BookLife::Float32=30

  for year in years
    for area in areas
      @finite_math CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-BookLife))
    end
    for plant in Plants
      CurrentYearAnnualizedInvestments[plant,year]=sum(DeviceInv[plant,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      RefCurrentYearAnnualizedInvestments[plant,year]=sum(RefDeviceInv[plant,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
    end
  end

  currentyear::Int=Yr(1990)
  CumulativeAnnualizedInvestments[Plants,Years].=0
  while currentyear <= Final
    Lifespan=Int(min(currentyear+BookLife,Final))
    years_cur=collect(currentyear:Lifespan)
    for year in years_cur, plant in Plants
      CumulativeAnnualizedInvestments[plant,year]=CumulativeAnnualizedInvestments[plant,year]+CurrentYearAnnualizedInvestments[plant,currentyear]
    end
    currentyear=currentyear+1
  end

  currentyear=Yr(1990)
  RefCumulativeAnnualizedInvestments[plant,year]=0
  while currentyear <= Final
    Lifespan=Int(min(currentyear+BookLife,Final))
    years_cur=collect(currentyear:Lifespan)
    for year in years_cur
      RefCumulativeAnnualizedInvestments[plant,year]=RefCumulativeAnnualizedInvestments[plant,year]+RefCurrentYearAnnualizedInvestments[plant,currentyear]
    end
    currentyear=currentyear+1
  end

  for plant in plants
    ZZZ[year]=CumulativeAnnualizedInvestments[plant,year]
    CCC[year]=RefCumulativeAnnualizedInvestments[plant,year]
    if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
      zData = @sprintf("%.6E",ZZZ[year])
      zInitial = @sprintf("%.6E",CCC[year])
      println(iob,"zDInvAnnualized;",Year[year],";",NationDS[nation],";",ECCDS[ecc],";",
        "Electricity Generation",";",PlantDS[plant],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
    end
  end

  for area in areas
    for year in years
      for area in areas
        @finite_math CapitalRecoveryFactor[area,year]=DiscountRate/(1-(1+DiscountRate)^(-BookLife))
      end
      for plant in Plants
        CurrentYearAnnualizedInvestments[plant,year]=DeviceInv[plant,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
        RefCurrentYearAnnualizedInvestments[plant,year]=RefDeviceInv[plant,area,year]*CapitalRecoveryFactor[area,year]/Inflation[area,year]*Inflation[area,CDYear]
      end
    end

    currentyear=Yr(1990)
    CumulativeAnnualizedInvestments[plant,year]=0
    while currentyear <= Final
      Lifespan=Int(min(currentyear+BookLife,Final))
      years_cur=collect(currentyear:Lifespan)
      for year in years_cur, plant in Plants
        CumulativeAnnualizedInvestments[plant,year]=CumulativeAnnualizedInvestments[plant,year]+CurrentYearAnnualizedInvestments[plant,currentyear]
      end
      currentyear=currentyear+1
    end

    currentyear=Yr(1990)
    RefCumulativeAnnualizedInvestments[plant,year]=0
    while currentyear <= Final
      Lifespan=Int(min(currentyear+BookLife,Final))
      years_cur=collect(currentyear:Lifespan)
      for year in years_cur
        RefCumulativeAnnualizedInvestments[plant,year]=RefCumulativeAnnualizedInvestments[plant,year]+RefCurrentYearAnnualizedInvestments[plant,currentyear]
      end
      currentyear=currentyear+1
    end

    for plant in plants
      ZZZ[year]=CumulativeAnnualizedInvestments[plant,year]
      CCC[year]=RefCumulativeAnnualizedInvestments[plant,year]
      if ZZZ[year] > 0.000000001 || ZZZ[year] < -0.000000001 || CCC[year] > 0.000000001 || CCC[year] < -0.000000001
        zData = @sprintf("%.6E",ZZZ[year])
        zInitial = @sprintf("%.6E",CCC[year])
        println(iob,"zDInvAnnualized;",Year[year],";",AreaDS[area],";",ECCDS[ecc],";",
          "Electricity Generation",";",PlantDS[plant],";",CDTime," CN\$/Yr",";",zData,";",zInitial)
      end
    end
  end

end # function zDInvAnnualizedElec_DtaRun

function zDInvAnnualized_Residential(db,iob,nation,SceName)
  data = zDInvAnnualizedResData(; db)
  zDInvAnnualizedRes_DtaRun(data,iob,nation,SceName)
end

function zDInvAnnualized_Commercial(db,iob,nation,SceName)
  data = zDInvAnnualizedComData(; db)
  zDInvAnnualizedCom_DtaRun(data,iob,nation,SceName)
end

function zDInvAnnualized_Industrial(db,iob,nation,SceName)
  data = zDInvAnnualizedIndData(; db)
  zDInvAnnualizedInd_DtaRun(data,iob,nation,SceName)
end

function zDInvAnnualized_Transport(db,iob,nation,SceName)
  data = zDInvAnnualizedTransData(; db)
  zDInvAnnualizedTrans_DtaRun(data,iob,nation,SceName)
end

function zDInvAnnualized_Electric(db,iob,nation,SceName)
  data = zDInvAnnualizedElecData(; db)
  zDInvAnnualizedElec_DtaRun(data,iob,nation,SceName)
end

function CreateDInvAnnualizedOutputFile(db,iob,nationkey,SceName)
  filename = "zDInvAnnualized-$nationkey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function zDInvAnnualized_DtaControl(db)
  data = zDInvAnnualizedResData(; db)
  (; Nation,Nations) = data
  (; NationOutputMap,SceName) = data

  @info "zDInvAnnualized_DtaControl"

  iob = IOBuffer()
  println(iob,"Variable;Year;Area;Sector;Enduse;Technology;Units;zData;zInitial")

  for nation in Nations
    if NationOutputMap[nation] == 1
      zDInvAnnualized_Residential(db,iob,nation,SceName)
      zDInvAnnualized_Commercial(db,iob,nation,SceName)
      zDInvAnnualized_Industrial(db,iob,nation,SceName)
      zDInvAnnualized_Transport(db,iob,nation,SceName)
      zDInvAnnualized_Electric(db,iob,nation,SceName)

      CreateDInvAnnualizedOutputFile(db,iob,Nation[nation],SceName)
    end
  end

end
if abspath(PROGRAM_FILE) == @__FILE__
  zDInvAnnualized_DtaControl(DB)
end
