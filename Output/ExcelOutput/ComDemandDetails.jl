#
# ComDemandDetails.jl
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

Base.@kwdef struct ComDemandDetailsData
  db::String
  Input = "CInput"
  Outpt = "COutput"
 
  Age    = ReadDisk(db,"MainDB/AgeKey")
  AgeDS  = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS = ReadDisk(db,"MainDB/AreaDS")
  AreaKey     = ReadDisk(db,"MainDB/AreaKey")
  EC     = ReadDisk(db,"$Input/ECKey")
  ECDS   = ReadDisk(db,"$Input/ECDS")  
  ECC    = ReadDisk(db,"MainDB/ECCKey")
  ECCDS  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey = ReadDisk(db,"MainDB/ECCKey")
  Enduse = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS    = ReadDisk(db,"$Input/EnduseDS")  
  Enduses::Vector{Int} = collect(Select(Enduse))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray   = ReadDisk(db,"$Input/TechKey")
  TechDS = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year   = ReadDisk(db,"MainDB/YearDS")

  AMSF::VariableArray{5} = ReadDisk(db,"$Outpt/AMSF") #[Enduse,Tech,EC,Area,Year] Average Market Share ($/$)
  DCC      = ReadDisk(db,"$Outpt/DCC")    # [Enduse,Tech,EC,Area,Year],Device Capital Cost ($/mmBtu/Yr)
  DEE      = ReadDisk(db,"$Outpt/DEE")    # [Enduse,Tech,EC,Area,Year],Device Efficiency (Btu/Btu)
  DEEA     = ReadDisk(db,"$Outpt/DEEA")   # [Enduse,Tech,EC,Area]  # Average Device Efficiency (Btu/Btu)
  DER      = ReadDisk(db,"$Outpt/DER")    # [Enduse,Tech,EC,Area,Year],Energy Requirement (mmBtu/Yr)
  DERA     = ReadDisk(db,"$Outpt/DERA")   # (Enduse,Tech,EC,Area,Year),Energy Requirement Addition (mmBtu/Yr)
  DERAD    = ReadDisk(db,"$Outpt/DERAD")  # (Enduse,Tech,EC,Area,Year),"Device Additions from Device Retirements","(mmBtu/yr)")
  DERAP    = ReadDisk(db,"$Outpt/DERAP")  # (Enduse,Tech,EC,Area,Year),"Device Additions from Process Retire","(mmBtu/Yr/Yr)")
  DERAPC   = ReadDisk(db,"$Outpt/DERAPC") # (Enduse,Tech,EC,Area,Year),"Device Additions from Production Capacity Additions and Increases in Device Saturation","(mmBtu/Yr/Yr)")
  DERR     = ReadDisk(db,"$Outpt/DERR")   # (Enduse,Tech,EC,Area,Year),"Device Energy Rqmt. Retire.","(mmBtu/Yr/Yr)")
  DERRD    = ReadDisk(db,"$Outpt/DERRD")  # (Enduse,Tech,EC,Area,Year),"Device Retire. from Device Retire.","(mmBtu/Yr/Yr)")
  DERRP    = ReadDisk(db,"$Outpt/DERRP")  # (Enduse,Tech,EC,Area,Year),"Device Retire. from Process Retire.","(mmBtu/Yr/Yr)")
  DERRPC   = ReadDisk(db,"$Outpt/DERRPC") # (Enduse,Tech,EC,Area,Year),"Device Retire. from Production Capacity Retirements and  Reductions in Device Saturation","(mmBtu/Yr/Yr)")
  Dmd      = ReadDisk(db,"$Outpt/Dmd")    # [Enduse,Tech,EC,Area,Year] # Total Energy Demand (TBtu/Yr)
  Driver   = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] # Economic Driver (Various Millions/Yr)
  ECFP     = ReadDisk(db,"$Outpt/ECFP")   # [Enduse,Tech,EC,Area,Year] # Fuel Price ($/mmBtu)
  ECCMap   = ReadDisk(db,"$Input/ECCMap") # [EC,ECC] # EC TO ECC Map
  EUPC     = ReadDisk(db,"$Outpt/EUPC") # [Enduse,Tech,Age,EC,Area,Year] # Production Capacity by Enduse (M$/Yr)
  EUPCA    = ReadDisk(db,"$Outpt/EUPCA") # [Enduse,Tech,Age,EC,Area,Year] # Production Capacity Additions ((M$/YR)/YR)
  EUPCAPC  = ReadDisk(db,"$Outpt/EUPCAPC") # [Enduse,Tech,Age,EC,Area,Year],Production Capacity Additions from New Production Capacity (M\$/Yr/Yr)
  EUPCR    = ReadDisk(db,"$Outpt/EUPCR") # [Enduse,Tech,Age,EC,Area,Year] # Production Capacity Retirement ((M$/YR)/YR)
  EUPCRPC  = ReadDisk(db,"$Outpt/EUPCRPC") # [Enduse,Tech,Age,EC,Area,Year] # Production Capacity Retirements from Capacity Retirements (M$/Yr/Yr)
  MCFU     = ReadDisk(db,"$Outpt/MCFU") # (:Enduse,:Tech,:EC,:Area,:Year),"Marginal Cost of Fuel Use ","(\$/mmBtu)")
  MMSF     = ReadDisk(db,"$Outpt/MMSF")   # [Enduse,Tech,EC,Area,Year] # Market Share Fraction by Device ($/$)
  PCostTech= ReadDisk(db,"$Outpt/PCostTech") # [Tech,EC,Area,Year] Permit Cost ($/mmBtu) 
  PEE      = ReadDisk(db,"$Outpt/PEE")    # [Enduse,Tech,EC,Area,Year] # Process Efficiency ($/Btu)
  PEEA     = ReadDisk(db,"$Outpt/PEEA")    # [Enduse,Tech,EC,Area,Year] # Average Process Efficiency ($/Btu)
  PER      = ReadDisk(db,"$Outpt/PER")    # [Enduse,Tech,EC,Area,Year] # Process Energy Requirement (mmBtu/Yr)
  PERA     = ReadDisk(db,"$Outpt/PERA") # [Enduse,Tech,EC,Area,Year]  # Process Energy Rqmt. Addition (mmBtu/Yr/Yr)
  PERAP    = ReadDisk(db,"$Outpt/PERAP") # [Enduse,Tech,EC,Area,Year]  # Process Additions from Process Retire. (mmBtu/Yr/Yr)
  PERAPC   = ReadDisk(db,"$Outpt/PERAPC") # [Enduse,Tech,EC,Area,Year]  # Process Additions from Production Capacity Additions (mmBtu/Yr/Yr)
  PERR     = ReadDisk(db,"$Outpt/PERR") # [Enduse,Tech,EC,Area,Year]  # Process Energy Rqmt. Retire. (mmBtu/Yr/Yr)
  PERRP    = ReadDisk(db,"$Outpt/PERRP") # [Enduse,Tech,EC,Area,Year]  # Process Retire. from Process Retire. (mmBtu/Yr/Yr)
  PERRPC   = ReadDisk(db,"$Outpt/PERRPC") # [Enduse,Tech,EC,Area,Year]  # Process Retire. from Production Capacity Retire. (mmBtu/Yr/Yr)
  PrPCost  = ReadDisk(db,"$Outpt/PrPCost") # [Tech,EC,Area,Year] Pollution Cost ($/mmBtu) 
  xDmd     = ReadDisk(db,"$Input/xDmd")   # [Enduse,Tech,EC,Area,Year] "Historical Energy Demand (TBtu/Yr)
end

function ComDemandDetails_DtaRun(data,area,ec)
    (; SceName,Year,AgeDS,Ages,Area,AreaDS,AreaKey,EC,ECDS,ECC,ECCDS,ECCKey,EnduseDS,Enduses,TechDS,Techs) = data
    (; AMSF,DCC,DEE,DEEA,DER,DERA,DERAD,DERAP,DERAPC,DERR,DERRD,DERRP,DERRPC) = data
    (; Dmd,Driver,ECFP,ECCMap,EUPC,EUPCA,EUPCAPC,EUPCR,EUPCRPC) = data
    (; MCFU,MMSF,PCostTech,PEE,PEEA,PER,PERA,PERAP,PERAPC,PERR,PERRP,PERRPC,PrPCost,xDmd) = data

  AreaName = AreaDS[area]
  ECName = ECDS[ec]
  ecc = Select(ECC,EC[ec])
  ECCName = ECCDS[ecc]

  iob = IOBuffer()
  ZZZ = zeros(Float32,length(Year))

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This file was produced by ComDemandDetails.jl")
  println(iob)

  years = collect(Yr(1985):Final)

  println(iob,"Year;",";",join(Year[years],";    "))
  println(iob)

  println(iob,AreaName," ",ECCName," Economic Driver (Various Millions/Yr);;    ",join(Year[years],"; "))
  ZZZ[years] = Driver[ecc,area,years]
  print(iob,"Driver;",ECC[ecc],";")
  for zzz in ZZZ[years]
    print(iob,@sprintf("%.4f;",zzz))
  end
  println(iob)
  println(iob)

  for enduse in Enduses
    
    #
    # Production Capacity by Enduse (EUPC) (M\$/Yr)
    #
    for age in Ages
      print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",AgeDS[age]," Production Capacity by Enduse (M\$/Yr);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for tech in Techs
        print(iob,"EUPC;",TechDS[tech])
        for year in years
          ZZZ[year] = EUPC[enduse,tech,age,ec,area,year]
          print(iob,";",@sprintf("%.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end
    
    #
    # Production Capacity Additions (EUPCA) (M\$/Yr)
    #
    for age in Ages
      print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",AgeDS[age]," Production Capacity Additions (M\$/Yr);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for tech in Techs
        print(iob,"EUPCA;",TechDS[tech])
        for year in years
          ZZZ[year] = EUPCA[enduse,tech,age,ec,area,year]
          print(iob,";",@sprintf("%.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end
    
    #
    # Production Capacity Additions from New Production Capacity (EUPCAPC) (M\$/Yr/Yr)
    #
    for age in Ages
      print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",AgeDS[age]," Production Capacity Additions from New Production Capacity (M\$/Yr/Yr);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for tech in Techs
        print(iob,"EUPCAPC;",TechDS[tech])
        for year in years
          ZZZ[year] = EUPCAPC[enduse,tech,age,ec,area,year]
          print(iob,";",@sprintf("%.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end
    
    #
    # Production Capacity Retirement (EUPCR) (M\$/Yr)
    #
    for age in Ages
      print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",AgeDS[age]," Production Capacity Retirement (M\$/Yr);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for tech in Techs
        print(iob,"EUPCR;",TechDS[tech])
        for year in years
          ZZZ[year] = EUPCR[enduse,tech,age,ec,area,year]
          print(iob,";",@sprintf("%.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end

    #
    # Production Capacity Retirements from Capacity Retirements (EUPCRPC) (M\$/Yr)
    #
    for age in Ages
      print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," ",AgeDS[age]," Production Capacity Retirements from Capacity Retirements (M\$/Yr);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for tech in Techs
        print(iob,"EUPCRPC;",TechDS[tech])
        for year in years
          ZZZ[year] = EUPCRPC[enduse,tech,age,ec,area,year]
          print(iob,";",@sprintf("%.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end  
  
    #
    # Process Energy Requirements (PER)
    #
    
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Energy Requirements (mmBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PER;",TechDS[tech])
      for year in years
        ZZZ[year] = PER[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Energy Requirement Addition (PERA)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Energy Requirement Addition (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PERA;",TechDS[tech])
      for year in years
        ZZZ[year] = PERA[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Additions from Process Retirements (PERAP)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Additions from Process Retirements (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PERAP;",TechDS[tech])
      for year in years
        ZZZ[year] = PERAP[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Additions from Production Capacity Additions and Increases in Device Saturation (PERAPC)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Additions from Production Capacity Additions and Increases in Device Saturation (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PERAPC;",TechDS[tech])
      for year in years
        ZZZ[year] = PERAPC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Energy Rqmt. Retire. (PERR)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Energy Rqmt. Retire. (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PERR;",TechDS[tech])
      for year in years
        ZZZ[year] = PERR[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Retire. from Process Retire. (PERRP)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Retire. from Process Retire. (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PERRP;",TechDS[tech])
      for year in years
        ZZZ[year] = PERRP[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Retire. from Production Capacity Retirements and Reductions in Device Saturation (PERRPC)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Retire. from Production Capacity Retirements and Reductions in Device Saturation (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PERRPC;",TechDS[tech])
      for year in years
        ZZZ[year] = PERRPC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    #
    # Device Energy Requirements (DER)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Energy Requirements (mmBtu/Yr;")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DER;",TechDS[tech])
      for year in years
        ZZZ[year] = DER[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.0f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Energy Requirement Addition (DERA)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Energy Requirement Addition (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERA;",TechDS[tech])
      for year in years
        ZZZ[year] = DERA[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Additions from Device Retirements (DERAD)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Additions from Device Retirements (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERAD;",TechDS[tech])
      for year in years
        ZZZ[year] = DERAD[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Additions from Process Retirements (DERAP)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Additions from Process Retirements (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERAP;",TechDS[tech])
      for year in years
        ZZZ[year] = DERAP[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Additions from Production Capacity Additions and Increases in Device Saturation (DERAPC)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Additions from Production Capacity Additions and Increases in Device Saturation (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERAPC;",TechDS[tech])
      for year in years
        ZZZ[year] = DERAPC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Energy Rqmt. Retire. (DERR)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Energy Rqmt. Retire. (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERR;",TechDS[tech])
      for year in years
        ZZZ[year] = DERR[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Retire. from Device Retire. (DERRD)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Retire. from Device Retire. (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERRD;",TechDS[tech])
      for year in years
        ZZZ[year] = DERRD[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Retire. from Process Retire. (DERRP)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Retire. from Process Retire. (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERRP;",TechDS[tech])
      for year in years
        ZZZ[year] = DERRP[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Retire. from Production Capacity Retirements and Reductions in Device Saturation (DERRPC)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Retire. from Production Capacity Retirements and Reductions in Device Saturation (mmBtu/Yr/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DERRPC;",TechDS[tech])
      for year in years
        ZZZ[year] = DERRPC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Efficiency (PEE)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Process Efficiency (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PEE;",TechDS[tech])
      for year in years
        ZZZ[year] = PEE[enduse,tech,ec,area,year]*1000000
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Average Process Efficiency (PEEA)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Average Process Efficiency (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PEEA;",TechDS[tech])
      for year in years
        ZZZ[year] = PEEA[enduse,tech,ec,area,year]*1000000
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  
    #
    # Device Efficiency (DEE)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Efficiency (Btu/Btu);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"DEE;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = DEE[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
    
    #
    # Average Device Efficiency (DEEA)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Efficiency (Btu/Btu);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"DEEA;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = DEEA[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Capital Cost (DCC)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Device Capital Cost (\$/mmBtu);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"DCC;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = DCC[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
    
    #
    # Fuel Price (ECFP)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Fuel Price (dollars/mmBtu);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"ECFP;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = ECFP[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
    
    #
    # Marginal Cost of Fuel Use (MCFU)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Marginal Cost of Fuel Use (dollars/mmBtu);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"MCFU;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = MCFU[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
    
    #
    # Marginal Market Share Fraction (MMSF)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Marginal Market Share Fraction (dollars/dollar);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"MMSF;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = MMSF[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
    
    #
    # Average Market Share Fraction (AMSF)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Average Market Share Fraction (dollars/dollar);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"AMSF;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = AMSF[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.6f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)    
    
    #
    # Energy Demand (Dmd)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Energy Demand (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"Dmd;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = Dmd[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.6f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)
    
    #
    # Historical Energy Demand (xDmd)
    #
    print(iob,AreaName," ",ECName," ",EnduseDS[enduse]," Historical Energy Demand (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end    
    println(iob)    
    for tech in Techs
      print(iob,"xDmd;",TechDS[tech],";")   
      for year in years      
        ZZZ[year] = xDmd[enduse,tech,ec,area,year]
        print(iob,@sprintf("%.4f",ZZZ[year]),";")
      end
      println(iob)
    end
    println(iob)     
  end
  
  #
  # Pollution Cost (PrPCost)
  #
  print(iob,AreaName," ",ECName," Pollution Cost (\$/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end    
  println(iob)    
  for tech in Techs
    print(iob,"PrPCost;",TechDS[tech],";")   
    for year in years      
      ZZZ[year] = PrPCost[tech,ec,area,year]
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)      
    
  #
  # Permit Cost (PCostTech)
  #
  print(iob,AreaName," ",ECName," Permit Cost (\$/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end    
  println(iob)    
  for tech in Techs
    print(iob,"PCostTech;",TechDS[tech],";")   
    for year in years      
      ZZZ[year] = PCostTech[tech,ec,area,year]
      print(iob,@sprintf("%.4f",ZZZ[year]),";")
    end
    println(iob)
  end
  println(iob)

  filename = "ComDemandDetails-$(AreaKey[area])-$(ECCKey[ecc])-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function ComDemandDetails_DtaControl(db)
  @info "ComDemandDetails_DtaControl"
  data = ComDemandDetailsData(; db)
  (; Area, EC, ECC) = data
  areas = Select(Area,["ON","QC","BC","AB","CA"])
  ecs = Select(EC,["Wholesale","Offices","NGPipeline","Health"])
  for ec in ecs
    for area in areas
      ComDemandDetails_DtaRun(data,area,ec)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
ComDemandDetails_DtaControl(DB)
end
