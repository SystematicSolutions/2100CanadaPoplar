#
# MCFU_Industrial.jl
#

Base.@kwdef struct MCFU_IndustrialData
  db::String
  Input = "IInput"
  Outpt = "IOutput"
 
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
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  DCC::VariableArray{5} = ReadDisk(db,"$Outpt/DCC") # Device Capital Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCFullCost::VariableArray{5} = ReadDisk(db,"$Outpt/DCCFullCost") # Device Capital Cost Full Cost ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCPoll::VariableArray{5} = ReadDisk(db,"$Outpt/DCCPoll") # Device Capital Cost from Pollution Price ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCPrice::VariableArray{5} = ReadDisk(db,"$Outpt/DCCPrice") # Device Capital Cost from Energy Price ($/mmBtu/Yr) [Enduse,Tech,EC,Area]
  DCCR::VariableArray{5} = ReadDisk(db,"$Outpt/DCCR") # Device Capital Charge Rate ($/Yr/$) [Enduse,Tech,EC,Area]
  DEE::VariableArray{5} = ReadDisk(db,"$Outpt/DEE") # [Enduse,Tech,EC,Area,Year] Device Efficiency (Btu/Btu) 
  DEEPoll::VariableArray{5} = ReadDisk(db,"$Outpt/DEEPoll") # Device Efficiency from Pollution Price (Btu/Btu) [Enduse,Tech,EC,Area]
  DEEPrice::VariableArray{5} = ReadDisk(db,"$Outpt/DEEPrice") # Device Efficiency from Energy Price (Btu/Btu) [Enduse,Tech,EC,Area]
  DEESw::VariableArray{5} = ReadDisk(db,"$Input/DEESw") # Switch for Device Efficiency (Switch) [Enduse,Tech,EC,Area]
  DmFrac::VariableArray{6} = ReadDisk(db,"$Outpt/DmFrac") # Demand Fuel/Tech Fraction Split (Btu/Btu) [Enduse,Fuel,Tech,EC,Area]
  DPL::VariableArray{5} = ReadDisk(db,"$Outpt/DPL") # Physical Life of Equipment (Years) [Enduse,Tech,EC,Area]
  ECFP::VariableArray{5} = ReadDisk(db,"$Outpt/ECFP") # Fuel Price ($/mmBtu) [Enduse,Tech,EC,Area]
  ECFPFuel::VariableArray{5} = ReadDisk(db,"$Outpt/ECFPFuel") # Fuel Price w/CFS Price ($/mmBtu) [Fuel,EC,Area]
  IdrtCost::VariableArray{5} = ReadDisk(db,"$Input/IdrtCost") # Indirect Costs ($/mmBtu) [Enduse,Tech,EC,Area]
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # Inflation Index ($/$) [Area]
  MCFU::VariableArray{5} = ReadDisk(db,"$Outpt/MCFU") # Marginal Cost of Fuel Use ($/mmBtu) [Enduse,Tech,EC,Area]
  PC::VariableArray{3} = ReadDisk(db,"MOutput/PC") # Production Capacity (M$/Yr) [ECC,Area]
  PCC::VariableArray{5} = ReadDisk(db,"$Outpt/PCC") # Process Capital Cost ($/(Driver/Yr)) [Enduse,Tech,EC,Area]
  PCostTech::VariableArray{4} = ReadDisk(db,"$Outpt/PCostTech") # Permit Cost ($/mmBtu) [Tech,EC,Area]
  PEE::VariableArray{5} = ReadDisk(db,"$Outpt/PEE") # Process Efficiency ($/Btu) [Enduse,Tech,EC,Area]
  PER::VariableArray{5} = ReadDisk(db,"$Outpt/PER") # Process Energy Requirement (mmBtu/YR) [Enduse,Tech,EC,Area]
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  DOMC::VariableArray{5} = zeros(Float32,length(Enduse),length(Tech),length(EC),length(Area),length(Year)) #   Device Operating Cost ($/mmBtu)
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))

end

function MCFU_Industrial_DtaRun(data,area,ec,enduse,SceName)
    (; Area,AreaDS,Areas,EC,ECDS,ECs,Enduse,EnduseDS,Enduses,Fuel,FuelDS,Fuels) = data
    (; Tech,TechDS,Techs,Year) = data
    (; DCC,DCCFullCost,DCCPoll,DCCPrice,DCCR,DEE,DEEPoll,DEEPrice,DEESw,DmFrac) = data
    (; DPL,ECFP,ECFPFuel,IdrtCost,Inflation,MCFU,PC,PCC,PCostTech,PEE,PER) = data
    (; MoneyUnitDS,DOMC,ZZZ) = data

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob,"$(Area[area]); $(ECDS[ec]); $(EnduseDS[enduse]); is the area being output.")
  println(iob,"This is the Hydrogen Marginal Cost of Energy Inputs and Outputs Summary.jl")
  println(iob)

  years = collect(Yr(1990):Final)

  println(iob,"Year;",";",join(Year[years],";    "))
  println(iob)

  #
  # ShowFuelCostComponents
  #
  for tech in Techs
    println(iob, "$(AreaDS[area]) $(ECDS[ec]) $(EnduseDS[enduse]) $(TechDS[tech]) MCFU Summary ($(MoneyUnitDS[area]) 2016/mmBtu);;    ", join(Year[years], ";"))
    #
    # MCFU; MCFU=DCCR*DCC+DOMC+ECFP/DEE+IdrtCost*Inflation
    #
    print(iob,"MCFU;Marginal Cost of Fuel Use")  
    for year in years  
    ZZZ[year]=MCFU(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # Levelized DCC
    # 
    print(iob,"DCCR*DCC;Levelized Device Capital Costs")  
    for year in years  
      ZZZ[year]=DCCR(EU,T,EC,Area,Y)*DCC(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # DOMC; DOMC=DOCF*DCCFullCost
    # 
    print(iob,"DOMC;Device Operating Cost")  
    for year in years
      DOMC=DOCF*DCCFullCost
      ZZZ[year]=DCCR(EU,T,EC,Area,Y)*DCC(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # ECFP/DEE; from ECFPFuel and PCostTech
    # 
    print(iob,"ECFP/DEE;Fuel Cost")  
    for year in years
      ZZZ[year]=ECFP(EU,T,EC,Area,Y)/DEE(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # IdrtCost(Enduse,Tech,EC,Area,Year) 'Indirect Costs ($/mmBtu)'
    # 
    print(iob,"IdrtCost;Indirect Costs")  
    for year in years
      ZZZ[year]=IdrtCost(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # ECFP; from ECFPFuel and PCostTech
    # 
    print(iob,"ECFP;Fuel Price")  
    for year in years
      ZZZ[year]=ECFP(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # DEE; from DEEPrice, DEEPoll
    # 
    print(iob,"DEE;Device Efficiency (Btu/Btu)")  
    for year in years
      ZZZ[year]=DEE(EU,T,EC,Area,Y)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # DCCR; DCCR=(1-(DIVTC+DPIVTC)/(1+ROIN-CROIN+DRisk+InSm)-TxRt*(2/DTL)/
    #      (ROIN-CROIN+DRisk+InSm+2/DTL))*(ROIN-CROIN+DRisk)/
    #      (1-(1/(1+ROIN-CROIN+DRisk))**DPLN)/(1-TxRt)
    # 
    print(iob,"DCCR;Device Capital Charge Rate ((\$/Yr)/\$)")  
    for year in years
      ZZZ[year]=DCCR(EU,T,EC,Area,Y)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    #
    # DCC; from DCCPrice, DCCPoll
    #
    print(iob,"DCC;Device Capital Costs (\$/mmBtu/Yr)")  
    for year in years
      ZZZ[year]=DCC(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # DOCF
    # 
    print(iob,"DOCF;Device Operating Cost Fraction (\$/Yr/\$)")  
    for year in years
      ZZZ[year]=DOCF(EU,T,EC,Area,Y)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # DCCFullCost
    # 
    print(iob,"DCCFullCost;Device Capital Cost Full Cost (\$/mmBtu/Yr)")  
    for year in years
      ZZZ[year]=DCCFullCost(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # DEESw
    # 
    print(iob,"DEESw;Switch for Device Efficiency (Switch)")  
    for year in years
      ZZZ[year]=DEESw(EU,T,EC,Area,Y)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # PCostTech
    # 
    print(iob,"PCostTech;Permit Cost")  
    for year in years
      ZZZ[year]=PCostTech(Tech,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # 
    # ECFPFuel(Fuel,EC,Area,Year)  'Fuel Price ($/mmBtu)'
    # 
    # FCheck=0.0
    # FCheck(Fuel)=sum(EU,T,EC,A,Y)(DmFrac(EU,Fuel,T,EC,A,Y))
    # Select Fuel if FCheck gt 0.0
    for fuel in fuels
      print(iob,"  ECFPFuel;$(FuelDS[fuel]) Fuel Price")  
      for year in years
        ZZZ[year]=PCostTech(Tech,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
        print(iob,";",@sprintf("%15.6f",ZZZ[year]))
      end
      println(iob)
    end


    # 
    # PEE
    #
    print(iob,"PEE;Process Efficiency (Btu/Btu)")  
    for year in years
      ZZZ[year]=PEE(EU,T,EC,Area,Y)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)

    # Write ("PEE;Process Efficiency (Btu/Btu)",(Year)(";",ZZZ(Year))) 
    #
    # PCC
    #
    print(iob,"PCC;Process Capital Costs (\$/mmBtu/Yr)")  
    for year in years
      ZZZ[year]=PCC(EU,T,EC,Area,Y)/Inflation(Area,Y)*Inflation(Area,2016)
      print(iob,";",@sprintf("%15.6f",ZZZ[year]))
    end
    println(iob)
    println(iob)

  end

  #
  # ShowInflation
  #
  print(iob,"Inflation;$(AreaDS[area])")  
  for year in years  
    ZZZ[year]=Inflation[area,year]   
    print(iob,";",@sprintf("%15.6f",ZZZ[year]))
  end
  println(iob)
  println(iob)


  filename = "MCFU_Industrial-$(Area[area])-$(ECC[ecc])-$(Enduse[enduse])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function MCFU_Industrial_DtaControl(db, SceName)
  @info "MCFU_Industrial_DtaControl"
  data = MCFU_IndustrialData(; db)
  (; Area, EC, Enduse) = data
  areas = Select(Area, ["ON","AB"])
  ecs = Select(EC, ["IronSteel","SAGDOilSands"])
  enduses = Select(Enduse, ["Heat"])
  for area in areas, ec in ecs, enduse in enduses
    MCFU_Industrial_DtaRun(data,area,ec,enduse,SceName)
  end
 
end
