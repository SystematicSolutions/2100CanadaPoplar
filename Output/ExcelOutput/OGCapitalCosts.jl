#
# OGCapitalCosts.jl
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


Base.@kwdef struct OGCapitalCostsData
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}    = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int}     = collect(Select(ECC))
  Enduse::SetArray = ReadDisk(db,"$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db,"$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray   = ReadDisk(db,"MainDB/YearKey")

  CDTime::Int = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  DCC::VariableArray{5} = ReadDisk(db,"$Outpt/DCC") # [Enduse,Tech,EC,Area,Year] Device Capital Cost ($/mmBtu/Yr)
  DEE::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu)
  DEEA::VariableArray{5} = ReadDisk(db,"$Outpt/DEEA") # [Enduse,Tech,EC,Area,Year] Average Device Efficiency (Btu/Btu)
  DEEBeforeStd::VariableArray{5} = ReadDisk(db,"$Outpt/DEEBeforeStd") # [Enduse,Tech,EC,Area,Year] Device Efficiency Before Standard(Btu/Btu)
  DEM::VariableArray{4} = ReadDisk(db,"$Input/DEM") # [Enduse,Tech,EC,Area,Year] Maximum Device Efficiency (Btu/Btu)
  DemCC::VariableArray{3} = ReadDisk(db,"SOutput/DemCC") # Demand Capital Cost ($/mmBtu) [ECC,Area]
  DemCCMult::VariableArray{3} = ReadDisk(db,"SOutput/DemCCMult") # Demand Capital Cost Multiplier ($/$) [ECC,Area]
  DEMM::VariableArray{5} = ReadDisk(db,"$CalDB/DEMM") # Maximum Device Efficiency Multiplier (Btu/Btu) [Enduse,Tech,EC,Area]
  DER::VariableArray{5} = ReadDisk(db,"$Outpt/DER") # Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  DEStd::VariableArray{5} = ReadDisk(db,"$Input/DEStd") # Device Efficiency Standards (Btu/Btu) [Enduse,Tech,EC,Area]
  DEStdP::VariableArray{5} = ReadDisk(db,"$Input/DEStdP") # Device Efficiency Standards Policy (Btu/Btu) [Enduse,Tech,EC,Area]
  DInvTech::VariableArray{5} = ReadDisk(db,"$Outpt/DInvTech") # [Enduse,Tech,EC,Area,Year] Device Investments in Reference Case (M$/Yr)
  Dmd::VariableArray{5} = ReadDisk(db,"$Outpt/Dmd") # [Enduse,Tech,EC,Area,Year] Total Energy Demand (TBtu/Yr)
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  EUPC::VariableArray{6} = ReadDisk(db,"$Outpt/EUPC") # Production Capacity by Enduse (Driver/Yr) [Enduse,Tech,Age,EC,Area]
  FlCC::VariableArray{3} = ReadDisk(db,"MEInput/FlCC") #[ECC,Area,Year]  Flaring Reduction Capital Cost ($/Tonne CH4)
  FlReduce::VariableArray{4} = ReadDisk(db,"SOutput/FlReduce") # [ECC,Poll,Area,Year] Flaring Reductions (Tonnes/Yr)
  FuCap::VariableArray{3} = ReadDisk(db,"MEOutput/FuCap") #[ECC,Area,Year]  Other Fugitives Reduction Capacity (Tonnes/Yr)
  FuCC::VariableArray{3} = ReadDisk(db,"MEOutput/FuCC") #[ECC,Area,Year]  Other Fugitives Reduction Capital Cost ($/Tonne)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  PCC::VariableArray{5} = ReadDisk(db,"$Outpt/PCC") # Process Capital Cost ($/(Driver/Yr)) [Enduse,Tech,EC,Area]
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # [Enduse,Tech,EC,Area,Year] Process Efficiency ($/Btu)
  PEEA::VariableArray{5} = ReadDisk(db,"$Outpt/PEEA") # Average Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEEBeforeStd::VariableArray{5} = ReadDisk(db,"$Outpt/PEEBeforeStd") # [Enduse,Tech,EC,Area,Year] Process Efficiency Before Standard ($/Btu)
  PEECurve::VariableArray{5} = ReadDisk(db,"$Outpt/PEECurve") #'Process Efficiency from Cost Curve ($/Btu) [Enduse,Tech,EC,Area]
  PEEPrice::VariableArray{5} = ReadDisk(db,"$Outpt/PEEPrice") # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PEM::VariableArray{3} = ReadDisk(db,"$CalDB/PEM") # Maximum Process Efficiency ($/Btu)
  PEMM::VariableArray{5} = ReadDisk(db,"$CalDB/PEMM") # [Enduse,Tech,EC,Area,Year] Process Efficiency Max. Mult. ($/Btu/($/Btu)) 
  PER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # [Enduse,Tech,EC,Area,Year] Process Energy Requirement (mmBtu/Yr)
  PEStd::VariableArray{5} = ReadDisk(db,"$Input/PEStd") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard ($/Btu)
  PEStdP::VariableArray{5} = ReadDisk(db,"$Input/PEStdP") # [Enduse,Tech,EC,Area,Year] Process Efficiency Standard Policy ($/Btu)
  VnCap::VariableArray{3} = ReadDisk(db,"MEOutput/VnCap") #[ECC,Area,Year]  Venting Reduction Capacity (Tonnes/Yr)
  VnCC::VariableArray{3} = ReadDisk(db,"MEOutput/VnCC") #[ECC,Area,Year]  Venting Reduction Capital Cost ($/Tonne)

  ZZZ = zeros(Float32, length(Year))
end

function OGCapitalCosts_DtaRun(data,area,ecc)
  (; Age,AgeDS,Ages,Area,AreaDS,Areas,ECC,ECCDS,ECCs,Enduse) = data
  (; EnduseDS,Enduses,Poll,PollDS,Polls,Tech,TechDS,Techs,Year) = data
  (; SceName,CDTime,CDYear,DCC,DEE,DEEA,DEEBeforeStd,DEM,DemCC,DemCCMult,DEMM) = data
  (; DER,DEStd,DEStdP,DInvTech,Dmd,ECFP,EUPC,FlCC,FlReduce,FuCap,FuCC) = data
  (; Inflation,PCC,PEE,PEEA,PEEBeforeStd,PEECurve,PEEPrice,PEM) = data
  (; PEMM,PER,PEStd,PEStdP,VnCap,VnCC,ZZZ) = data

  AreaKey=Area[area]
  AreaName=AreaDS[area]
  ECCKey=ECC[ecc]
  ECCName=ECCDS[ecc]

  # year = Select(Year, (from = "1990", to = "2050"))
  years = collect(Yr(1990):Yr(2050))
  CDYear = max(CDYear,1)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "OGCapitalCosts-$ECCKey-$AreaKey-$SceName.dta; is the file name.")
  println(iob, "; is the model name.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  println(iob, "$AreaName $ECCName Capital Costs Multiplier;;    ", join(Year[years], ";"))
  print(iob, "DemCCMult;$ECCName")  
  for year in years
    ZZZ[year] = DemCCMult[ecc,area,year]
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$AreaName $ECCName Capital Costs Estimate ($CDTime Local M\$/Yr);;    ", join(Year[years], ";"))
  print(iob, "DemCC;Total")  
  for year in years
    ZZZ[year] = DemCC[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  print(iob, "DCC*PER;  Device")  
  for year in years
    ZZZ[year] = sum(DCC[enduse,tech,ecc,area,year]*PER[enduse,tech,ecc,area,year] for tech in Techs, enduse in Enduses)/Inflation[area,year]*Inflation[area,CDYear]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  enduse=Select(Enduse,"Heat")
  print(iob, "PCC*EUPC;  Process")
  for year in years
    ZZZ[year] = sum(PCC[enduse,tech,ecc,area,year]*sum(EUPC[enduse,tech,age,ecc,area,year] for age in Ages) for tech in Techs)/
        Inflation[area,year]*Inflation[area,CDYear]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  print(iob, "VnCC*VnCap;  Venting")
  for year in years
    ZZZ[year] = VnCC[ecc,area,year]*VnCap[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  print(iob, "FuCC*FuCap;  Fugitives")
  for year in years
    ZZZ[year] = FuCC[ecc,area,year]*FuCap[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  poll=Select(Poll,"CO2")
  print(iob, "FlCC*FlReduce;  Flaring")
  for year in years
    ZZZ[year] = FlCC[ecc,area,year]*FlReduce[ecc,poll,area,year]*Inflation[area,CDYear]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  enduse=1
  println(iob, "$AreaName $ECCName $(EnduseDS[enduse]) Device Capital Cost ($CDTime Local \$/mmBtu/Yr);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob, "DCC;$(TechDS[tech])")  
    for year in years
      ZZZ[year] = DCC[enduse,tech,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$AreaName $ECCName Process Energy Requirement (mmBtu/Yr);;    ", join(Year[years], ";"))
  print(iob, "PER;Total")
  for year in years
    ZZZ[year] = sum(PER[enduse,tech,ecc,area,year] for tech in Techs, enduse in Enduses)
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for tech in Techs
    print(iob, "PER;$(TechDS[tech])")  
    for year in years
      ZZZ[year] = sum(PER[enduse,tech,ecc,area,year] for enduse in Enduses)
      print(iob,";",@sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  enduse=Select(Enduse,"Heat")
  println(iob, "$AreaName $ECCName $(EnduseDS[enduse]) Process Capital Cost ($CDTime Local \$/Driver/Yr);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob, "PCC;$(TechDS[tech])")  
    for year in years
      ZZZ[year] = PCC[enduse,tech,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  enduse=Select(Enduse,"Heat")
  println(iob, "$AreaName $ECCName $(EnduseDS[enduse]) Production Capacity (Driver/Yr);;    ", join(Year[years], ";"))
  print(iob, "EUPC;Total")
  for year in years
    ZZZ[year] = sum(EUPC[enduse,tech,age,ecc,area,year] for age in Ages, tech in Techs)
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  for tech in Techs
    print(iob, "EUPC;$(TechDS[tech])")  
    for year in years
      ZZZ[year] = sum(EUPC[enduse,tech,age,ecc,area,year] for age in Ages)
      print(iob,";",@sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  println(iob, "$AreaName $ECCName Venting Reduction Capital Cost ($CDTime Local \$/Tonne);;    ", join(Year[years], ";"))
  print(iob, "VnCC;Venting")  
  for year in years
    ZZZ[year] = VnCC[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName $ECCName Venting Reduction Capacity (MT/Yr);;    ", join(Year[years], ";"))
  print(iob, "VnCap;Venting")
  for year in years
    ZZZ[year] = VnCap[ecc,area,year]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName $ECCName Other Fugitives Reduction Capital Cost ($CDTime Local \$/Tonne);;    ", join(Year[years], ";"))
  print(iob, "FuCC;Fugitives")  
  for year in years
    ZZZ[year] = FuCC[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName $ECCName Other Fugitives Reduction Capacity (MT/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuCap;Fugitives")
  for year in years
    ZZZ[year] = FuCap[ecc,area,year]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName $ECCName Flaring Reduction Capital Cost ($CDTime Local \$/Tonne);;    ", join(Year[years], ";"))
  print(iob, "FlCC;Flaring")  
  for year in years
    ZZZ[year] = FlCC[ecc,area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  println(iob, "$AreaName $ECCName Flaring Reductions (MT/Yr);;    ", join(Year[years], ";"))
  print(iob, "FlReduce;Flaring")
  for year in years
    ZZZ[year] = FlReduce[ecc,poll,area,year]/1e6
    print(iob,";",@sprintf("%15.6f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  enduse=1
  println(iob, "$AreaName $ECCName $(EnduseDS[enduse]) Fuel Price ($CDTime Local \$/mmBtu/Yr);;    ", join(Year[years], ";"))
  for tech in Techs
    print(iob, "ECFP;$(TechDS[tech])")  
    for year in years
      ZZZ[year] = ECFP[enduse,tech,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
      print(iob,";",@sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # *
  # ************************
  # *
  # Define Procedure ShowOther
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Device Investments (M$/Yr);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=Sum(Area)(DInvTech(EU,T,EC,Area,Y))
  #   Write ("DInvTech;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Energy Requirement (mmBtu/Yr);",(Year)(";",Yrv(Year)))
  # ZZZ(Y)=sum(T,Area)(DER(EU,T,EC,Area,Y))
  # Write ("DER;Total",(Year)(";",ZZZ(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(Area)(DER(EU,T,EC,Area,Y))
  #   Write ("DER;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")

  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Maximum Device Efficiency (Btu/Btu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(DEM(EU,T,EC,Area)*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("DEM;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Maximum Device Efficiency Multiplier (Btu/Btu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(DEMM(EU,T,EC,Area,Y)*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("DEMM;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Device Efficiency (Btu/Btu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(DEE(EU,T,EC,Area,Y)*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("DEE;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Device Efficiency Standards (Btu/Btu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(DEStd(EU,T,EC,Area,Y)*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("DEStd;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Device Efficiency Standards Policy(Btu/Btu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(DEStdP(EU,T,EC,Area,Y)*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("DEStdP;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Maximum Process Efficiency ($/mmBtu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEM(EU,EC,Area)*1e6*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEM;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Process Energy Effic. Max. Mult. ($/Btu/($/Btu));",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEMM(EU,T,EC,Area,Y)*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEMM;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Marginal Process Efficiency ($/GJ);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEE(EU,T,EC,Area,Y)*1e6/1.055*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEE;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Process Efficiency Standard ($/mmbtu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEStd(EU,T,EC,Area,Y)*1e6*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEStd;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Process Efficiency Standard Policy ($/mmbtu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEStdP(EU,T,EC,Area,Y)*1e6*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEStdP;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Energy Demands (TBtu/Yr);",(Year)(";",Yrv(Year)))
  # ZZZ(Y)=sum(T,Area)(Dmd(EU,T,EC,Area,Y))
  # Write ("Dmd;Total",(Year)(";",ZZZ(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("Dmd;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Average Device Efficiency (Btu/Btu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=DEEA(EU,T,EC,Area,Y)
  #   Write ("DEEA;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Average Process Efficiency ($/mmbtu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEEA(EU,T,EC,Area,Y)*1e6*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEEA;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Device Efficiency Before Standard (Btu/Btu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(DEEBeforeStd(EU,T,EC,Area,Y)*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("DEEBeforeStd;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Process Efficiency Before Standard ($/mmbtu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEEBeforeStd(EU,T,EC,Area,Y)*1e6*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEEBeforeStd;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Process Efficiency ($/mmBtu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEEPrice(EU,T,EC,Area,Y)*1e6*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEEPrice;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # Write (AreaDS::0," ",ECDS::0," ",EnduseDS::0," Process Efficiency from Cost Curve ($/mmBtu);",(Year)(";",Yrv(Year)))
  # Do Tech
  #   ZZZ(Y)=sum(EU,EC,Area)(PEECurve(EU,T,EC,Area,Y)*1e6*Dmd(EU,T,EC,Area,Y))/
  #          sum(EU,EC,Area)(Dmd(EU,T,EC,Area,Y))
  #   Write ("PEECurve;",TechDS::0,(Year)(";",ZZZ(Year)))
  # End Do Tech
  # Write(" ")
  # *
  # End Define Procedure ShowOther


  #
  # Create *.dta filename and write output values
  #
  filename = "OGCapitalCosts-$ECCKey-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function OGCapitalCosts_DtaControl(db)
  @info "OGCapitalCosts_DtaControl"
  data = OGCapitalCostsData(; db)
  (; Area,ECC) = data

  areas=Select(Area,["AB"])
  eccs=Select(ECC,["LightOilMining"])
  
  for area in areas, ecc in eccs
    OGCapitalCosts_DtaRun(data,area,ecc)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
OGCapitalCosts_DtaControl(DB)
end
