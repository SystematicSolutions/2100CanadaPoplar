#
# IndInputsDisplay.jl
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

Base.@kwdef struct IndInputsDisplayData
  db::String
  Input = "IInput"
  Outpt = "IOutput"
  CalDB = "ICalDB"

  Area   = ReadDisk(db, "MainDB/AreaKey")
  AreaKey  = ReadDisk(db, "MainDB/AreaKey")
  
  EC     = ReadDisk(db,"$Input/ECKey")
  ECDS   = ReadDisk(db,"$Input/ECDS")  
  ECC    = ReadDisk(db,"MainDB/ECCKey")
  ECCDS  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey = ReadDisk(db,"MainDB/ECCKey")
  
  Enduse = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel   = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  PI     = ReadDisk(db,"$Input/PIKey")
  PIDS   = ReadDisk(db,"$Input/PIDS")
  PIs    = collect(Select(PI))
  Poll   = ReadDisk(db,"MainDB/PollDS")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech   = ReadDisk(db,"$Input/TechDS")
  TechDS = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year   = ReadDisk(db, "MainDB/YearDS")

  CERSM = ReadDisk(db, "$CalDB/CERSM") # [Enduse, EC, Area, Year], Capital Energy Requirement Multiplier (Btu/Btu)
  CUF = ReadDisk(db, "$CalDB/CUF") # [Enduse, Tech, EC, Area, Year], Capacity Utilization Factor (\$/Yr/\$/Yr)
  DCCN = ReadDisk(db, "$Outpt/DCCN") # [Enduse, Tech, EC, Area], "Normalized Device Capital Cost", "\$/mmBtu"
  DCCR = ReadDisk(db, "$Outpt/DCCR") # [Enduse, Tech, EC, Area, Year], Device Capital Charge Rate (\$/Yr/\$)
  DCTC = ReadDisk(db, "$Outpt/DCTC") # [Enduse,Tech,EC,Area,Year]  'Device Cap. Trade Off Coefficient (DLESS)'
  DDayNorm = ReadDisk(db, "$Input/DDayNorm") # [Enduse, :Area], Normal Annual Degree Days (Degree Days)
  DDCoefficient = ReadDisk(db, "$Input/DDCoefficient") # [:Enduse, :EC, :Area, :Year], Annual Energy Degree Day Coefficient (DD/DD)
  DEEA0 = ReadDisk(db, "$Input/DEEA0") # [Enduse,Tech,EC,Area,Year]  Device A0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEB0 = ReadDisk(db, "$Input/DEEB0") # [Enduse,Tech,EC,Area,Year]  Device B0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEC0 = ReadDisk(db, "$Input/DEEC0") # [Enduse,Tech,EC,Area,Year]  Device C0 Coeffcient for Efficiency Program (Btu/Btu)
  DEM = ReadDisk(db, "$Input/DEM") # [:Enduse, :Tech, :EC, :Area], Maximum Device Efficiency (Btu/Btu)
  DEMM = ReadDisk(db, "$CalDB/DEMM") # [:Enduse, :Tech, :EC, :Area, :Year], Max. Device Eff. Multiplier (Btu/Btu)
  DEPM = ReadDisk(db, "$Input/DEPM") # [Enduse, Tech, EC, Area, Year], Device Energy Price Multiplier (\$/\$)
  DEStdP = ReadDisk(db, "$Input/DEStdP") # [:Enduse, Tech, EC, Area, Year], Device Eff. Standards Policy (Btu/Btu)
  DFPN = ReadDisk(db, "$Outpt/DFPN") # [Enduse, Tech, EC, Area), Normalized Fuel Price (\$/mmBtu)
  DFTC = ReadDisk(db, "$Outpt/DFTC") # [:Enduse, :Tech, :EC, :Area, :Year], Device Fuel Trade Off Coefficient (DLESS)
  DmFracMax = ReadDisk(db, "$Input/DmFracMax") # [:Enduse, :Fuel, :Tech, :EC, :Area, :Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DOCF = ReadDisk(db, "$Input/DOCF") # [:Enduse, :Tech, :EC, :Area, :Year], "Device Operating Cost Fraction", "\$/Yr/\$"
  FsPEE = ReadDisk(db, "$CalDB/FsPEE") # [:Tech, :EC, :Area, :Year], Feedstock Process Efficiency (\$/mmBtu)
  FsPOCA = ReadDisk(db, "$Outpt/FsPOCA") # [:Fuel, :EC, :Poll, :Area, :Year], "Feedstock Pollution Coefficients", "Tonnes/TBtu"
  MMSM0 = ReadDisk(db, "$CalDB/MMSM0") # [:Enduse, :Tech, :EC, :Area, :Year], "Non-price Factors.", "\$/\$"
  MSMM = ReadDisk(db, "$Input/MSMM") # [:Enduse, :Tech, :EC, :Area, :Year], "Non-Price Market Share Factor Multiplier", "\$/\$"
  MVF = ReadDisk(db, "$CalDB/MVF") # [:Enduse, :Tech, :EC, :Area, :Year], "Market Share Variance Factor", "\$/\$"
  PCCN = ReadDisk(db, "$Outpt/PCCN") # [:Enduse, :Tech, :EC, :Area], "Normalized Process Capital Cost ", "(\$/mmBtu)"
  PCTC = ReadDisk(db, "$Outpt/PCTC") # [:Enduse, :Tech, :EC, :Area, :Year], "Process Capital Cap. Trade Off Coef.", "DLESS"
  PEM = ReadDisk(db, "$CalDB/PEM") # [:Enduse, :EC, :Area], "Maximum Process Efficiency", "\$/mmBtu"
  PEMM = ReadDisk(db, "$CalDB/PEMM") # [:Enduse, :Tech, :EC, :Area, :Year], "Process Efficiency Max. Multi", "\$/Btu/(\$/Btu)"
  PEPL = ReadDisk(db, "$Outpt/PEPL") # [:Enduse, :Tech, :EC, :Area, :Year], "Physical Life of Process Requirements (Years)"
  PFTC = ReadDisk(db, "$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year], Process Fuel Trade Off Coefficient
  POCA = ReadDisk(db, "$Outpt/POCA") # [Enduse,FuelEP,EC,Poll,Area,Year], Average Pollution Coefficients (Tonnes/TBtu)
  RPEI = ReadDisk(db, "$Outpt/RPEI") # [:Enduse, :Tech, :EC, :Area, :Year], Energy Impact of Pollution Reduction, (Btu/Btu)
  xDmd = ReadDisk(db, "$Input/xDmd")   # [Enduse, Tech, EC, Area, Year], Historical Energy Demand (TBtu)
  xDmFrac = ReadDisk(db, "$Input/xDmFrac") # [:Enduse, :Fuel, :Tech, :EC, :Area, :Year], Demand Fuel/Tech Fraction (Btu/Btu)
  xFsFrac = ReadDisk(db, "$Input/xFsFrac") # (:Fuel, :Tech, :EC, :Area, :Year), "Feedstock Demands Fuel/Tech Split", "Fraction")
  xProcSw = ReadDisk(db,"$Input/xProcSw") # [PI,Year] Procedure on/off Switch
  xMMSF = ReadDisk(db, "$CalDB/xMMSF") # (:Enduse, :Tech, :EC, :Area, :Year), "Historical Market Share Fraction by Device", "Fraction")
end

function IndInputsDisplay_DtaRun(data, area, ec)
  (; SceName,CERSM, CUF, DCCN, DCCR, DCTC, DDayNorm, DDCoefficient, DEEA0,DEEB0,DEEC0) = data
  (; DEM, DEMM, DEPM, DEStdP, DFPN, DFTC, DmFracMax, DOCF, FsPEE, FsPOCA) = data
  (; MMSM0, MSMM, MVF, PCCN, PCTC, PEM, PEMM, PEPL, PFTC, POCA, RPEI) = data
  (; xDmd,xDmFrac,xFsFrac,xMMSF,xProcSw) = data
  (; Area, AreaKey, ECDS, ECC, ECCKey, EC, Year, Enduse, EnduseDS, Enduses) = data
  (; Techs, TechDS, Poll, Fuel, Fuels, FuelEP, FuelEPs, PIs, PIDS) = data

  AreaName = Area[area]
  ECName = ECDS[ec]
  ecc = Select(ECC,EC[ec])

  iob = IOBuffer()
  ZZZ = zeros(Float32, length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file was produced by IndInputsDisplay.jl")
  println(iob, " ")

  years = collect(Yr(1985):Final)
  # year = Select(Year)
  println(iob,"Year;",";",join(Year[years],";    "))
  println(iob, " ")

  for enduse in Enduses
    
    #
    # Capital Energy Requirement Multiplier (CERSM)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Capital Energy Requirement Multiplier (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
      print(iob,"CERSM;",EnduseDS[enduse])
      for year in years
        ZZZ[year] = CERSM[enduse,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)  
    println(iob)
    
    #
    # Capacity Utilization Factor (CUF)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Capacity Utilization Factor (\$/Yr/\$/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"CUF;",TechDS[tech])
      for year in years
        ZZZ[year] = CUF[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Normalized Device Capital Cost (DCCN)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Normalized Device Capital Cost (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DCCN;",TechDS[tech])
      for year in years
        ZZZ[year] = DCCN[enduse,tech,ec,area]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Capital Charge Rate (DCCR)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device Capital Charge Rate (\$/Yr/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DCCR;",TechDS[tech])
      for year in years
        ZZZ[year] = DCCR[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Fuel Trade Off Coefficient (DLESS) (DCTC)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device Fuel Trade Off Coefficient (DLESS);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DCTC;",TechDS[tech])
      for year in years
        ZZZ[year] = DCTC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Fuel Trade Off Coefficient (DLESS) (DFTC)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device Fuel Trade Off Coefficient (DLESS);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DFTC;",TechDS[tech])
      for year in years
        ZZZ[year] = DFTC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Operating Cost Fraction (DOCF)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device Operating Cost Fraction (\$/Yr/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DOCF;",TechDS[tech])
      for year in years
        ZZZ[year] = DOCF[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Maximum Device Efficiency (DEM)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Maximum Device Efficiency (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DEM;",TechDS[tech])
      for year in years
        ZZZ[year] = DEM[enduse,tech,ec,area]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Maximum Device Efficiency Multiplier (DEMM)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Maximum Device Efficiency Multiplier (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DEMM;",TechDS[tech])
      for year in years
        ZZZ[year] = DEMM[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device Energy Price Multiplier (DEPM)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device Energy Price Multiplier (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DEPM;",TechDS[tech])
      for year in years
        ZZZ[year] = DEPM[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    # println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device Eff. Standards Policy (Btu/Btu);;", join(Year[years], ";"))
    # for tech in Select(Tech)
    #   ZZZ[years] = DEStdP[enduse, tech, ec, area, year]
    #   println(iob, "DEStdP;", Tech[tech], ";", join(ZZZ[years], ";"))
    # end
    # println(iob, " ")
 
    #
    # Normalized Fuel Price (DFPN)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Normalized Fuel Price (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DFPN;",TechDS[tech])
      for year in years
        ZZZ[year] = DFPN[enduse,tech,ec,area]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Feedstock Process Efficiency (FsPEE)
    #
    print(iob,AreaName," ",ECName," Feedstock Process Efficiency (\$/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"FsPEE;",TechDS[tech])
      for year in years
        ZZZ[year] = FsPEE[tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # FsPOCA = ReadDisk(db, "$Outpt/FsPOCA") # [:Fuel, :EC, :Poll, :Area, :Year], "Feedstock Pollution Coefficients", "Tonnes/TBtu"
    #
    # Feedstock Pollution Coefficients (FsPOCA)
    #
    poll = Select(Poll, "Carbon Dioxide")
    print(iob,AreaName," ",ECName," ",Poll[poll]," Feedstock Pollution Coefficients (Tonnes/TBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for fuel in Fuels
      print(iob,"FsPOCA;",Fuel[fuel])
      for year in years
        ZZZ[year] = FsPOCA[fuel,ec,poll,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end  
      println(iob)
    end  
    println(iob)
    
    #
    # Non-price Factors (MMSM0)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Non-price Factors (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"MMSM0;",EnduseDS[enduse])
      for year in years
        ZZZ[year] = MMSM0[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Market Share Variance Factor (MVF)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Market Share Variance Factor (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"MVF;",TechDS[tech])
      for year in years
        ZZZ[year] = MVF[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Process Fuel Trade Off Coefficient (DLESS) (PCTC)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Process Fuel Trade Off Coefficient (DLESS);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PCTC;",TechDS[tech])
      for year in years
        ZZZ[year] = PCTC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Process Fuel Trade Off Coefficient (DLESS) (PFTC)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Process Fuel Trade Off Coefficient (DLESS);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PFTC;",TechDS[tech])
      for year in years
        ZZZ[year] = PFTC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Maximum Process Efficiency Multiplier (PEMM)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Maximum Process Efficiency Multiplier (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"PEMM;",TechDS[tech])
      for year in years
        ZZZ[year] = PEMM[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end  
    println(iob)

    #
    # POCA = ReadDisk(db, "$Outpt/POCA") # [Enduse,FuelEP,EC,Poll,Area,Year], Average Pollution Coefficients (Tonnes/TBtu)
    #
    # Pollution Coefficients (POCA)
    #
    polls = Select(Poll, "Carbon Dioxide")
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," ",Poll[poll]," Pollution Coefficients (Tonnes/TBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for poll in polls, fuelep in FuelEPs
      print(iob,"POCA;",FuelEP[fuelep])
      for year in years
        ZZZ[year] = POCA[enduse,fuelep,ec,poll,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end  
    println(iob)
    
    #
    # Exogenous Market Share (xMMSF)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Exogenous Market Share (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"xMMSF;",TechDS[tech])
      for year in years
        ZZZ[year] = xMMSF[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    #
    # Historical Energy Demand (xDmd)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Historical Energy Demand (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"xDmd;",TechDS[tech])
      for year in years
        ZZZ[year] = xDmd[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    #
    # Device A0 Coeffcient for Efficiency Program (DEEA0)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device A0 Coeffcient for Efficiency Program (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DEEA0;",TechDS[tech])
      for year in years
        ZZZ[year] = DEEA0[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 

    #
    # Device B0 Coeffcient for Efficiency Program (DEEB0)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device B0 Coeffcient for Efficiency Program (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DEEB0;",TechDS[tech])
      for year in years
        ZZZ[year] = DEEB0[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)  

    #
    # Device C0 Coeffcient for Efficiency Program (DEEC0)
    #
    print(iob,AreaName," ",ECName," ",Enduse[enduse]," Device C0 Coeffcient for Efficiency Program (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob,"DEEC0;",TechDS[tech])
      for year in years
        ZZZ[year] = DEEC0[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)   
    
#    for tech in Select(Tech)
#      println(iob, AreaName," ",ECName," ",Tech[tech]," Feedstock Demand Fuel/Tech Fraction (Btu/Btu);;", join(Year[years], ";"))
#      for fuel in Select(Fuel)
#        ZZZ[years] = xFsFrac[fuel, tech, ec, area, years]
#        print(iob, "xFsFrac;", Fuel[fuel], ";")
#        for zzz in ZZZ[years]
#         print(iob, @sprintf("%12.4f;", zzz))
#        end
#        println(iob)
#     end
#      println(iob, " ")
#    end

#    for tech in Select(Tech)
#      println(iob, AreaName," ",ECName," ",Enduse[enduse]," ",Tech[tech]," Energy Demands Fuel/Tech Fraction (Btu/Btu);;", join(Year[years], ";"))
#      for fuel in Select(Fuel)
#        ZZZ[years] = xDmFrac[enduse, fuel, tech, ec, area, years]
#        print(iob, "xDmFrac;", Fuel[fuel], ";")
#        for zzz in ZZZ[years]
#          print(iob, @sprintf("%12.4f;", zzz))
#        end
#        println(iob)
#      end
#      println(iob, " ")
#    end

  end # for enduse
  
  #
  # Procedure Switch (Switch) (xProcSw)
  #
  print(iob,AreaName," Procedure Switch (Switch);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for proc in PIs
    print(iob,"xProcSw;",PIDS[proc])
    for year in years
    ZZZ[year] = xProcSw[proc,year]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end  
  println(iob)   

  filename = "IndInputsDisplay-$(AreaKey[area])-$(ECCKey[ecc])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function IndInputsDisplay_DtaControl(db)
  @info "IndInputsDisplay_DtaControl"
  data = IndInputsDisplayData(; db)
  Area = data.Area
  EC = data.EC
  #
  areas = Select(Area, ["ON","QC","BC","SK","NL","YT","CA","ENC","MX","ROW"])
  ecs = Select(EC,
   ["PulpPaperMills","Petroleum","OtherChemicals","Cement",
    "IronSteel","Aluminum","OtherManufacturing",
    "IronOreMining","OtherMetalMining","FrontierOilMining","OnFarmFuelUse"])
  for ec in ecs
    for area in areas
      IndInputsDisplay_DtaRun(data, area, ec)
    end
  end
  #
  areas = Select(Area,"AB")
  ecs = Select(EC,["PulpPaperMills","SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders",
                   "SweetGasProcessing","SourGasProcessing","OnFarmFuelUse"])
  for ec in ecs
    for area in areas
      IndInputsDisplay_DtaRun(data, area, ec)
    end
  end
  
  areas = Select(Area,"BC")
  ecs = Select(EC,["LNGProduction"])
  for ec in ecs
    for area in areas
      IndInputsDisplay_DtaRun(data, area, ec)
    end
  end  
  
  
end

if abspath(PROGRAM_FILE) == @__FILE__
IndInputsDisplay_DtaControl(DB)
end
