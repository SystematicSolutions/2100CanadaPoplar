#
# CogenerationSummary_Com.jl
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

Base.@kwdef struct CogenerationSummary_ComData
  db::String

  Input::String = "CInput"
  Outpt::String = "COutput"
  CalDB::String = "CCalDB"

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CgCap::VariableArray{4} = ReadDisk(db,"SOutput/CgCap") # [Fuel,ECC,Area,Year] Cogeneration Capacity (MW)
  CgCC::VariableArray{4} = ReadDisk(db,"$Input/CgCC") # [Tech,EC,Area,Year] Cogeneration Capital Cost ($/mmBtu/Yr)
  CgCR::VariableArray{4} = ReadDisk(db,"$Outpt/CgCR") # [Tech,EC,Area,Year] Cogeneration Capacity Construction Rate (MW/Yr)
  CgDem::VariableArray{4} = ReadDisk(db,"$Outpt/CgDem") # [FuelEP,EC,Area,Year] Cogeneration Demands (TBtu/Yr)
  CgDemand::VariableArray{4} = ReadDisk(db,"SOutput/CgDemand") # [Fuel,ECC,Area,Year] Cogeneration Demands (tBtu)
  CgDmd::VariableArray{4} = ReadDisk(db,"$Outpt/CgDmd") # [Tech,EC,Area,Year] Cogeneration Energy Demand (TBtu/Yr)
  CgEC::VariableArray{3} = ReadDisk(db,"SOutput/CgEC") # [ECC,Area,Year] Cogeneration by Economic Category (GWh/Yr)
  CgECFP::VariableArray{4} = ReadDisk(db,"$Outpt/CgECFP") # [Tech,EC,Area,Year]Cogeneration Fuel Price ($/mmBtu)
  CgEG::VariableArray{4} = ReadDisk(db,"$Outpt/CgEG") # [Tech,EC,Area,Year] Cogeneration Generation (GWh/Yr)
  CgGC::VariableArray{4} = ReadDisk(db,"$Outpt/CgGC") # [Tech,EC,Area,Year] Cogeneration Generating Capacity (MW)
  CgGen::VariableArray{4} = ReadDisk(db,"SOutput/CgGen") # [Fuel,ECC,Area,Year] Cogeneration Generation (GWh/Yr)
  CgHRtA::VariableArray{4} = ReadDisk(db,"$Outpt/CgHRtA") # [Tech,EC,Area,Year] Average Cogeneration Heat Rate (Btu/KWh) 
  CgHRtM::VariableArray{4} = ReadDisk(db,"$Input/CgHRtM") # [Tech,EC,Area,Year] Marginal Cogeneration Heat Rate (Btu/KWh) 
  CgMCE::VariableArray{4} = ReadDisk(db,"$Outpt/CgMCE") # [Tech,EC,Area,Year] Cogeneration Marginal Cost of Energy ($/mmBtu)
  CgMSF::VariableArray{4} = ReadDisk(db,"$Outpt/CgMSF") # [Tech,EC,Area,Year] Cogeneration Market Share ($/$)
  CgPot::VariableArray{4} = ReadDisk(db,"$Outpt/CgPot") # [Tech,EC,Area,Year] Cogeneration Potential (MW)
  CgPotMult::VariableArray{4} = ReadDisk(db,"$Input/CgPotMult") # [Tech,EC,Area,Year] Cogeneration Potential Multiplier (Btu/Btu)
  CgR::VariableArray{4} = ReadDisk(db,"$Outpt/CgR") # [Tech,EC,Area,Year] Cogeneration Cap. Retirements (MW/Yr)
  CgUMS::VariableArray{4} = ReadDisk(db,"$Outpt/CgUMS") # [Tech,EC,Area,Year] Cogeneration Utilization Multiplier (Btu/Btu)
  CgVC::VariableArray{4} = ReadDisk(db,"$Outpt/CgVC") # [Tech,EC,Area,Year]Cogeneration Variable Costs ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index
  xCgIGC::VariableArray{4} = ReadDisk(db,"$Input/xCgIGC") # [Tech,EC,Area,Year]Exogenous Indicated Cogeneration Capacity (MW)
  xCgMSF::VariableArray{4} = ReadDisk(db,"$CalDB/xCgMSF") # [Tech,EC,Area,Year] Exogenous Cogeneration Market Share (Btu/Btu)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function CogenerationSummary_Com_DtaRun(data,areas,eccs,AreaName,AreaKey)
  (; SceName,ECCDS,ECCs,ECs,ECDS,FuelDS,Fuels,FuelEPs,FuelEPDS,Techs,TechDS,Year) = data
  (; CgCap,CgDemand,CgGC,CgGen,CgEG,CgDmd,CgDem,ZZZ) = data
  (; CgCC,CgCR,CgECFP,CgHRtA,CgHRtM,CgMCE) = data
  (; CgMSF,CgPot,CgPotMult,CgR,CgUMS,CgVC,Inflation,xCgIGC,xCgMSF) = data


  KJBtu = 1.054615
  years = collect(Yr(1990):Final)

  iob = IOBuffer()

  println(iob)
  println(iob,"$AreaName")
  println(iob,"This file was produced by CogenerationSummary_Com.txo")
  println(iob)
  println(iob)
  println(iob,"Year;",";",join(Year[years],";"))
  println(iob)

  #
  # Capacity
  #
  print(iob,AreaName," Cogeneration Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CgCap[fuel,ecc,area,year] for fuel in Fuels, ecc in eccs, area in areas)
  end
  print(iob,"CgCap;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"CgCap;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(CgCap[fuel,ecc,area,year] for fuel in Fuels,area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Generation
  #
  print(iob,AreaName," Cogeneration Generation (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for fuel in Fuels, ecc in eccs, area in areas)
  end
  print(iob,"CgGen;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"CgGen;",ECCDS[ecc])
    for year in years
      ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for fuel in Fuels, area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  ###################
  #
  print(iob,AreaName," Cogeneration Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgCap;Total")
  for year in years
    ZZZ[year] = sum(CgCap[fuel,ecc,area,year] for fuel in Fuels, ecc in eccs, area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    print(iob,"CgCap;",FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(CgCap[fuel,ecc,area,year] for ecc in eccs, area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,AreaName," Cogeneration Generation (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgGen;Total")
  for year in years
    ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for fuel in Fuels, ecc in eccs, area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    print(iob,"CgGen;",FuelDS[fuel])
    for year in years
      ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for ecc in eccs,area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # TODOJulia 2/8/2024 Neil - Finite math problem: 0/0=NaN
  print(iob,AreaName," Cogeneration Capacity Factor (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    @finite_math ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for fuel in Fuels, ecc in eccs, area in areas) ./
      sum(CgCap[fuel,ecc,area,year] * 8760/1000 for fuel in Fuels, ecc in eccs, area in areas)
  end
  print(iob,"CgPCF;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    for year in years
      @finite_math ZZZ[year] = sum(CgGen[fuel,ecc,area,year] for ecc in eccs, area in areas) ./
        sum(CgCap[fuel,ecc,area,year] * 8760/1000 for ecc in eccs, area in areas)
    end
    print(iob,"CgPCF;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob,AreaName," Cogeneration Demands (TBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CgDemand[fuel,ecc,area,year] for fuel in Fuels, ecc in eccs, area in areas)
  end
  print(iob,"CgDemand;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in Fuels
    for year in years
      ZZZ[year] = sum(CgDemand[fuel,ecc,area,year] for ecc in eccs, area in areas)
    end
    print(iob,"CgDemand;",FuelDS[fuel])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  ###################
  #
  # Capacity
  #
  print(iob,AreaName," Cogeneration Capacity (MW);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CgGC[tech,ec,area,year] for  tech in Techs, ec in ECs, area in areas)
  end
  print(iob,"CgGC;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for tech in Techs
    for year in years
      ZZZ[year] = sum(CgGC[tech,ec,area,year] for ec in ECs, area in areas)
    end
    print(iob,"CgGC;",TechDS[tech])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Generation
  #
  print(iob,AreaName," Cogeneration Energy Generation (GWh/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CgEG[tech,ec,area,year] for tech in Techs, ec in ECs, area in areas)
  end
  print(iob,"CgEG;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for tech in Techs
    for year in years
      ZZZ[year] = sum(CgEG[tech,ec,area,year] for ec in ECs, area in areas)
    end
    print(iob,"CgEG;",TechDS[tech])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Demand
  #
  print(iob,AreaName," Cogeneration Energy Demand (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CgDmd[tech,ec,area,year] for tech in Techs, ec in ECs, area in areas)
  end
  print(iob,"CgDmd;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for tech in Techs
    for year in years
      ZZZ[year] = sum(CgDmd[tech,ec,area,year] for ec in ECs, area in areas)
    end
    print(iob,"CgDmd;",TechDS[tech])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Demand
  #
  print(iob,AreaName," Cogeneration Energy Demand (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    ZZZ[year] = sum(CgDem[fuelep,ec,area,year] for fuelep in FuelEPs,ec in ECs,area in areas)
  end
  print(iob,"CgDem;Total")
  for year in years
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for fuelep in FuelEPs
    for year in years
      ZZZ[year] = sum(CgDem[fuelep,ec,area,year] for ec in ECs,area in areas)
    end
    print(iob,"CgDem;",FuelEPDS[fuelep])
    for year in years
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  # Tech Loop
  #
  for tech in Techs
  
    #
    # Cogeneration Fuel Price 
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Fuel Price (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgECFP;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgECFP[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 
  
    #
    # Cogeneration Capital Cost ($/mmBtu/Yr)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Capital Cost (\$/mmBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgCC;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgCC[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 
  
    #
    # Marginal Cogeneration Heat Rate (Btu/KWh)
    #
    print(iob,AreaName," ", TechDS[tech]," Marginal Cogeneration Heat Rate (Btu/KWh) (\$/mmBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgHRtM;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgHRtM[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)     

    #
    # Cogeneration Variable Costs ($/mmBtu)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Variable Costs (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgVC;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgVC[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Cogeneration Marginal Cost of Energy ($/mmBtu)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Marginal Cost of Energy (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgMCE;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgMCE[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)    

    #
    # Cogeneration Market Share ($/$)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Market Share (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgMSF;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgMSF[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 
    
    #
    # Historical Cogeneration Market Share ($/$)
    #
    print(iob,AreaName," ", TechDS[tech]," Historical Cogeneration Market Share (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"xCgMSF;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(xCgMSF[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)     
  
    #
    # Cogeneration Cap. Retirements (MW/Yr)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Cap. Retirements (MW/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgR;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgR[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)   
  
    #
    # Cogeneration Potential (MW)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Potential (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgPot;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgPot[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)   
  
    #
    # Cogeneration Potential Multiplier (Btu/Btu)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Potential Multiplier (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgPotMult;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgPotMult[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)   
  
    #
    # Exogenous Indicated Cogeneration Capacity (MW)
    #
    print(iob,AreaName," ", TechDS[tech]," Exogenous Indicated Cogeneration Capacity (MW);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"xCgIGC;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(xCgIGC[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 
    
    #
    # Cogeneration Capacity Construction Rate (MW/Yr)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogeneration Capacity Construction Rate (MW/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgCR;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgCR[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 
    
    #
    # Average Cogeneration Heat Rate (Btu/KWh)
    #
    print(iob,AreaName," ", TechDS[tech]," Average Cogeneration Heat Rate (Btu/KWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgHRtA;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgHRtA[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 
    
    #
    # Cogen. Utilization Mult. (Btu/Btu)
    #
    print(iob,AreaName," ", TechDS[tech]," Cogen. Utilization Mult. (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for ec in ECs
      print(iob,"CgUMS;",ECDS[ec])
      for year in years
        ZZZ[year] = sum(CgUMS[tech,ec,area,year] for area in areas)
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)  
  end
 
  area = first(areas)
  print(iob, "Inflation Index (1985=1);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "Inflation;", AreaName) 
  for year in years
    ZZZ[year] = Inflation[area,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "CogenerationSummary_Com-$(AreaKey)-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end
end

function CogenerationSummary_Com_DtaControl(db)
  @info "CogenerationSummary_Com_DtaControl"
  data = CogenerationSummary_ComData(; db)
  (; Area,Areas,AreaDS,ECC) = data

  eccs = Select(ECC,(from = "Wholesale",to = "StreetLighting"))

  #
  # Canada
  #
  areas = Select(Area,(from = "ON",to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  CogenerationSummary_Com_DtaRun(data,areas,eccs,AreaName,AreaKey)

  #
  # US
  #
  areas = Select(Area,(from = "CA",to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  CogenerationSummary_Com_DtaRun(data,areas,eccs,AreaName,AreaKey)

  #
  # Individual Areas
  #
  areas_CN = Select(Area,(from = "ON",to = "NU"))
  areas_US = Select(Area,(from = "CA",to = "Pac"))
  areas = union(areas_CN,areas_US)
  for area in areas
    AreaName = AreaDS[area]
    AreaKey = Area[area]
    CogenerationSummary_Com_DtaRun(data,area,eccs,AreaName,AreaKey)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
CogenerationSummary_Com_DtaControl(DB)
end
