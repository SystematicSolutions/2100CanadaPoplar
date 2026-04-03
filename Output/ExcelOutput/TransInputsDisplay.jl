#
# TransInputsDisplay.jl
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

Base.@kwdef struct TransInputsDisplayData
  db::String
  Input = "TInput"
  Outpt = "TOutput"
  CalDB = "TCalDB"

  Area   = ReadDisk(db, "MainDB/AreaKey")
  AreaKey  = ReadDisk(db, "MainDB/AreaKey")
  
  EC     = ReadDisk(db,"$Input/ECKey")
  ECDS   = ReadDisk(db,"$Input/ECDS")  
  ECC    = ReadDisk(db,"MainDB/ECCKey")
  ECCDS  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey = ReadDisk(db,"MainDB/ECCKey")
  
  Enduse = ReadDisk(db,"$Input/EnduseDS")
  Fuel   = ReadDisk(db,"MainDB/FuelDS")
  FuelEP = ReadDisk(db,"MainDB/FuelEPDS")
  PI     = ReadDisk(db,"$Input/PIKey")
  PIDS   = ReadDisk(db,"$Input/PIDS")
  PIs    = collect(Select(PI))
  Poll   = ReadDisk(db,"MainDB/PollDS")
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year   = ReadDisk(db, "MainDB/YearDS")

  CERSM = ReadDisk(db, "$CalDB/CERSM") # [Enduse, EC, Area, Year], Capital Energy Requirement Multiplier (Btu/Btu)
  CUF = ReadDisk(db, "$CalDB/CUF") # [Enduse, Tech, EC, Area, Year], Capacity Utilization Factor (dollars/Yr/dollars/Yr)
  DAct::VariableArray{5} = ReadDisk(db,"$Input/DAct") # [Enduse,Tech,EC,Area,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  DCCN = ReadDisk(db, "$Outpt/DCCN") # [Enduse, Tech, EC, Area], "Normalized Device Capital Cost", "dollars/mmBtu"
  DCCR = ReadDisk(db, "$Outpt/DCCR") # [Enduse, Tech, EC, Area, Year], Device Capital Charge Rate (dollars/Yr/dollars)
  DCTC = ReadDisk(db, "$Outpt/DCTC") # [Enduse,Tech,EC,Area,Year]  'Device Cap. Trade Off Coefficient (DLESS)'
  DDayNorm = ReadDisk(db, "$Input/DDayNorm") # [Enduse, :Area], Normal Annual Degree Days (Degree Days)
  DDCoefficient = ReadDisk(db, "$Input/DDCoefficient") # [:Enduse, :EC, :Area, :Year], Annual Energy Degree Day Coefficient (DD/DD)
  DEEA0 = ReadDisk(db, "$Input/DEEA0") # [Enduse,Tech,EC,Area,Year]  Device A0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEB0 = ReadDisk(db, "$Input/DEEB0") # [Enduse,Tech,EC,Area,Year]  Device B0 Coeffcient for Efficiency Program (Btu/Btu)
  DEEC0 = ReadDisk(db, "$Input/DEEC0") # [Enduse,Tech,EC,Area,Year]  Device C0 Coeffcient for Efficiency Program (Btu/Btu)
  DEM = ReadDisk(db, "$Input/DEM") # [:Enduse, :Tech, :EC, :Area], Maximum Device Efficiency (Btu/Btu)
  DEMM = ReadDisk(db, "$CalDB/DEMM") # [:Enduse, :Tech, :EC, :Area, :Year], Max. Device Eff. Multiplier (Btu/Btu)
  DEPM = ReadDisk(db, "$Input/DEPM") # [Enduse, Tech, EC, Area, Year], Device Energy Price Multiplier (dollars/dollars)
  DEStdP = ReadDisk(db, "$Input/DEStdP") # [:Enduse, Tech, EC, Area, Year], Device Eff. Standards Policy (Btu/Btu)
  DFPN = ReadDisk(db, "$Outpt/DFPN") # [Enduse, Tech, EC, Area), Normalized Fuel Price (dollars/mmBtu)
  DFTC = ReadDisk(db, "$Outpt/DFTC") # [:Enduse, :Tech, :EC, :Area, :Year], Device Fuel Trade Off Coefficient (DLESS)
  DmFracMax = ReadDisk(db, "$Input/DmFracMax") # [:Enduse, :Fuel, :Tech, :EC, :Area, :Year] Demand Fuel/Tech Fraction Maximum (Btu/Btu)
  DOCF = ReadDisk(db, "$Input/DOCF") # [:Enduse, :Tech, :EC, :Area, :Year], "Device Operating Cost Fraction", "dollars/Yr/dollars"
  FsPEE = ReadDisk(db, "$CalDB/FsPEE") # [:Tech, :EC, :Area, :Year], Feedstock Process Efficiency (dollars/mmBtu)
  FsPOCA::VariableArray{6} = ReadDisk(db,"$Outpt/FsPOCA") # [Fuel,Tech,EC,Poll,Area,Year] Feedstock Pollution Coefficients (Tonnes/TBtu) 

  MMSM0 = ReadDisk(db, "$CalDB/MMSM0") # [:Enduse, :Tech, :EC, :Area, :Year], "Non-price Factors.", "dollars/dollars"
  MSMM = ReadDisk(db, "$Input/MSMM") # [:Enduse, :Tech, :EC, :Area, :Year], "Non-Price Market Share Factor Multiplier", "dollars/dollars"
  MVF = ReadDisk(db, "$CalDB/MVF") # [:Enduse, :Tech, :EC, :Area, :Year], "Market Share Variance Factor", "dollars/dollars"
  PCCN = ReadDisk(db, "$Outpt/PCCN") # [:Enduse, :Tech, :EC, :Area], "Normalized Process Capital Cost ", "(dollars/mmBtu)"
  PCTC = ReadDisk(db, "$Outpt/PCTC") # [:Enduse, :Tech, :EC, :Area, :Year], "Process Capital Cap. Trade Off Coef.", "DLESS"
  PEM::VariableArray{4} = ReadDisk(db,"$CalDB/PEM") # [Enduse,Tech,EC,Area] Maximum Process Efficiency ($/Btu) 
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu)) 
  PEPL = ReadDisk(db, "$Outpt/PEPL") # [:Enduse, :Tech, :EC, :Area, :Year], "Physical Life of Process Requirements (Years)"
  PFTC = ReadDisk(db, "$Outpt/PFTC") # [Enduse,Tech,EC,Area,Year], Process Fuel Trade Off Coefficient
  PFPN::VariableArray{4} = ReadDisk(db,"$Outpt/PFPN") # Process Normalized Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]  
  POCA::VariableArray{7} = ReadDisk(db,"$Outpt/POCA") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] Average Pollution Coefficients (Tonnes/TBtu) 
  RPEI = ReadDisk(db, "$Outpt/RPEI") # [:Enduse, :Tech, :EC, :Area, :Year], Energy Impact of Pollution Reduction, (Btu/Btu)
  xDCC::VariableArray{5} = ReadDisk(db,"$Input/xDCC") # [Enduse,Tech,EC,Area,Year]  Device Capital Cost ($/mmBtu/Yr)
  xDCMM::VariableArray{5} = ReadDisk(db,"$Input/xDCMM") # Maximum Device Capital Cost Mult (Btu/Btu) [Enduse,Tech,EC,Area]
  xDEE::VariableArray{5} = ReadDisk(db,"$Input/xDEE") # [Enduse,Tech,EC,Area,Year] Historical Device Efficiency (Btu/Btu)
  xDmd = ReadDisk(db, "$Input/xDmd")   # [Enduse, Tech, EC, Area, Year], Historical Energy Demand (TBtu)
  xDmFrac = ReadDisk(db, "$Input/xDmFrac") # [:Enduse, :Fuel, :Tech, :EC, :Area, :Year], Demand Fuel/Tech Fraction (Btu/Btu)
  xFsFrac = ReadDisk(db, "$Input/xFsFrac") # (:Fuel, :Tech, :EC, :Area, :Year), "Feedstock Demands Fuel/Tech Split", "Fraction")
  xProcSw = ReadDisk(db,"$Input/xProcSw") # [PI,Year] Procedure on/off Switch
  xMMSF = ReadDisk(db, "$CalDB/xMMSF") # (:Enduse, :Tech, :EC, :Area, :Year), "Historical Market Share Fraction by Device", "Fraction")
end

function TransInputsDisplay_DtaRun(data,area,ec)
  (; SceName,Year,Area,AreaKey,EC,ECDS,ECC,ECCKey,Enduse,Fuel,FuelEP,PIDS,PIs,Poll,Tech,TechDS,Techs) = data
  (; CERSM,CUF,DAct,DCCN,DCCR,DCTC,DDayNorm,DDCoefficient,DEEA0,DEEB0,DEEC0) = data
  (; DEM,DEMM,DEPM,DEStdP,DFPN,DFTC,DmFracMax,DOCF,FsPEE,FsPOCA) = data
  (; MMSM0,MSMM,MVF,PCCN,PCTC,PEM,PEMM,PEPL,PFPN,PFTC,POCA,RPEI) = data
  (; xDCC,xDEE,xDmd,xDmFrac,xFsFrac,xMMSF,xProcSw) = data

  AreaName = Area[area]
  ECName = ECDS[ec]
  ecc = Select(ECC,EC[ec])

  iob = IOBuffer()
  ZZZ = zeros(Float32,length(Year))

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "This file was produced by TransInputsDisplay.jl")
  println(iob, " ")

  # years = Select(Year, (from = "1985", to = "2050"))
  years = Select(Year)
  println(iob, "Year;", ";", join(Year[years], ";"))
  println(iob, " ")

  for enduse in Select(Enduse)

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Capital Energy Requirement Multiplier (Btu/Btu);;", join(Year[years], ";"))
    ZZZ[years] = CERSM[enduse, ec, area, years]
    println(iob, "CERSM;", Enduse[enduse], ";", join(ZZZ[years], ";"))
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Capacity Utilization Factor (dollars/Yr/dollars/Yr);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = CUF[enduse, tech, ec, area, years]
      println(iob, "CUF;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Normalized Device Capital Cost (dollars/mmBtu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] .= DCCN[enduse,tech,ec,area]
      println(iob,"DCCN;",Tech[tech],";",join(ZZZ[years],";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device Capital Charge Rate (dollars/Yr/dollars);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = DCCR[enduse, tech, ec, area, years]
      println(iob, "DCCR;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device Fuel Trade Off Coefficient (DLESS);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = DCTC[enduse, tech, ec, area, years]
      println(iob, "DCTC;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device Fuel Trade Off Coefficient (DLESS);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = DFTC[enduse, tech, ec, area, years]
      println(iob, "DFTC;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device Operating Cost Fraction (dollars/Yr/dollars);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = DOCF[enduse, tech, ec, area, years]
      println(iob, "DOCF;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Maximum Device Efficiency (Btu/Btu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] .= DEM[enduse,tech,ec,area]
      println(iob,"DEM;",Tech[tech],";",join(ZZZ[years],";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Maximum Device Efficiency Multiplier (Btu/Btu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = DEMM[enduse, tech, ec, area, years]
      println(iob, "DEMM;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device Energy Price Multiplier (dollars/dollars);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = DEPM[enduse, tech, ec, area, years]
      println(iob, "DEPM;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    # println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device Eff. Standards Policy (Btu/Btu);;", join(Year[years], ";"))
    # for tech in Techs
    #   ZZZ[years] = DEStdP[enduse, tech, ec, area, years]
    #   println(iob, "DEStdP;", Tech[tech], ";", join(ZZZ[years], ";"))
    # end
    # println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Normalized Fuel Price (dollars/mmBtu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] .= DFPN[enduse,tech,ec,area]
      println(iob,"DFPN;",Tech[tech],";",join(ZZZ[years],";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," Feedstock Process Efficiency (dollars/mmBtu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = FsPEE[tech, ec, area, years]
      println(iob, "FsPEE;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    # FsPOCA = ReadDisk(db, "$Outpt/FsPOCA") # [Fuel,Tech,EC,Poll,Area,Year] "Feedstock Pollution Coefficients", "Tonnes/TBtu"
    #
    tech = 1
    polls = Select(Poll, ["Carbon Dioxide"])
    for poll in polls
      println(iob, AreaName," ",ECName," ",Poll[poll]," Feedstock Pollution Coefficients (Tonnes/TBtu);;", join(Year[years], ";"))
      for fuel in Select(Fuel)
        ZZZ[years] = FsPOCA[fuel,tech,ec,poll,area,years]
        println(iob, "FsPOCA;", Fuel[fuel], ";", join(ZZZ[years], ";"))
      end
      println(iob, " ")
    end


    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Non-price Factors (dollars/dollars);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = MMSM0[enduse, tech, ec, area, years]
      println(iob, "MMSM0;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Market Share Variance Factor (dollars/dollars);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = MVF[enduse, tech, ec, area, years]
      println(iob, "MVF;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Process Fuel Trade Off Coefficient (DLESS);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = PCTC[enduse, tech, ec, area, years]
      println(iob, "PCTC;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Process Fuel Trade Off Coefficient (DLESS);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = PFTC[enduse, tech, ec, area, years]
      println(iob, "PFTC;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")
    
    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Process Normalized Fuel Price (dollars/mmBtu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] .= PFPN[enduse,tech,ec,area]
      println(iob,"PFPN;",Tech[tech],";",join(ZZZ[years],";"))      
    end
    println(iob, " ") 
    
    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Maximum Process Efficiency (Btu/Btu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] .= PEM[enduse,tech,ec,area]
      println(iob,"PEM;",Tech[tech],";",join(ZZZ[years],";"))
    end
    println(iob, " ")    
    
    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Maximum Process Efficiency Multiplier (Btu/Btu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = PEMM[enduse, tech, ec, area, years]
      println(iob, "PEMM;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    #
    # POCA = ReadDisk(db, "$Outpt/POCA") # [Enduse,FuelEP,Tech,EC,Poll,Area,Year] , Average Pollution Coefficients (Tonnes/TBtu)
    #
    tech = 1
    polls = Select(Poll, ["Carbon Dioxide"])
    for poll in polls
      println(iob, AreaName," ",ECName," ",Enduse[enduse]," ",Poll[poll]," Pollution Coefficients (Tonnes/TBtu);;", join(Year[years], ";"))
      for fuelep in Select(FuelEP)
        ZZZ[years] = POCA[enduse, fuelep, tech, ec, poll, area, years]
        println(iob, "POCA;", FuelEP[fuelep], ";", join(ZZZ[years], ";"))
      end
      println(iob, " ")
    end

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Exogenous Market Share (Btu/Btu);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = xMMSF[enduse, tech, ec, area, years]
      println(iob, "xMMSF;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")

    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Historical Energy Demand (TBtu/Yr);;", join(Year[years], ";"))
    for tech in Techs
      ZZZ[years] = xDmd[enduse,tech,ec,area,years]
      println(iob, "xDmd;", Tech[tech], ";", join(ZZZ[years], ";"))
    end
    println(iob, " ")
    

    print(iob, AreaName, " ",ECDS[ec]," Device Efficiency (mmBtu/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob, "xDEE;", TechDS[tech])    
      for year in years
        ZZZ[year] = xDEE[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)    

    print(iob, AreaName, " ",ECDS[ec]," Device Capital Cost (dollars/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob, "xDCC;", TechDS[tech])    
      for year in years
        ZZZ[year] = xDCC[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob) 


#    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device A0 Coeffcient for Efficiency Program (Btu/Btu);;", join(Year[years], ";"))
#    for tech in Techs
#      ZZZ[years] = DEEA0[enduse, tech, ec, area, years]
#      println(iob, "DEEA0;", Tech[tech], ";", join(ZZZ[years], ";"))
#    end
#    println(iob, " ")    
#
#    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device B0 Coeffcient for Efficiency Program (Btu/Btu);;", join(Year[years], ";"))
#    for tech in Techs
#      ZZZ[years] = DEEB0[enduse, tech, ec, area, years]
#      println(iob, "DEEB0;", Tech[tech], ";", join(ZZZ[years], ";"))
#    end
#    println(iob, " ")  
#
#    println(iob, AreaName," ",ECName," ",Enduse[enduse]," Device C0 Coeffcient for Efficiency Program (Btu/Btu);;", join(Year[years], ";"))
#    for tech in Techs
#      ZZZ[years] = DEEC0[enduse, tech, ec, area, years]
#      println(iob, "DEEC0;", Tech[tech], ";", join(ZZZ[years], ";"))
#    end
#    println(iob, " ")  
#
#
#    for tech in Techs
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

#    for tech in Techs
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

    print(iob, AreaName, " ",ECDS[ec]," Device Activity Level (Ton-Miles/Vehicle-Mile));")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in Techs
      print(iob, "DAct;", TechDS[tech])    
      for year in years
        ZZZ[year] = DAct[enduse,tech,ec,area,year]
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)




  end # for enduse
  
  #
  # Procedure Switch (Switch) (xProcSw)
  #
  years = Select(Year)
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

  filename = "TransInputsDisplay-$(AreaKey[area])-$(ECCKey[ecc])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TransInputsDisplay_DtaControl(db)
  @info "TransInputsDisplay_DtaControl"
  data = TransInputsDisplayData(; db)
  Area = data.Area
  EC = data.EC
  #
  areas = Select(Area,["ON","AB","BC"])
  ecs = Select(EC,["Passenger","Freight","AirPassenger","AirFreight","ForeignFreight"])
  for ec in ecs
    for area in areas
      TransInputsDisplay_DtaRun(data, area, ec)
    end
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
TransInputsDisplay_DtaControl(DB)
end

