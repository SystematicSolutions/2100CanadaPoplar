#
# NH3Summary.jl
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

Base.@kwdef struct NH3SummaryData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))    
  H2Tech::SetArray = ReadDisk(db, "MainDB/H2TechKey")
  H2TechDS::SetArray = ReadDisk(db, "MainDB/H2TechDS")
  H2Techs::Vector{Int} = collect(Select(H2Tech))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  eCO2Price::VariableArray{2} = ReadDisk(db, "SOutput/eCO2Price") # [Area,Year] Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") # [Fuel,Nation,Year] Primary Fuel Price ($/mmBtu)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  FPF::VariableArray{4} = ReadDisk(db, "SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  FsFP::VariableArray{4} = ReadDisk(db, "SOutput/FsFP") # [Fuel,ES,Area,Year] Feedstock Fuel Price ($/mmBtu)
  FuelExpenditures::VariableArray{3} = ReadDisk(db, "SOutput/FuelExpenditures") #[ECC,Area,Year]  Fuel Expenditures (M$)

  H2CC::VariableArray{3} = ReadDisk(db,"SpOutput/H2CC") # [H2Tech,Area] Hydrogen Production Capital Cost ($/mmBtu)
  H2CCR::VariableArray{3} = ReadDisk(db,"SpInput/H2CCR") # [H2Tech,Area,Year] Hydrogen Production Capital Charge Rate
  H2ECFP::VariableArray{3} = ReadDisk(db, "SpOutput/H2ECFP") # [H2Tech,Area,Year] Fuel Prices for Hydrogen Production ($/mmBtu)
  H2EmissionCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2EmissionCost") # [H2Tech,Area,Year] Hydrogen Emission Cost ($/mmBtu)
  H2FeedstockCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FeedstockCost") # [H2Tech,Area,Year] Hydrogen Feedstock Cost ($/mmBtu)
  H2FOMCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FOMCost") # [H2Tech,Area,Year] Hydrogen Production O&M Costs ($/mmBtu)
  H2FsYield::VariableArray{3} = ReadDisk(db, "SpInput/H2FsYield") # [H2Tech,Area,Year] Hydrogen Yield From Feedstock (Btu/Btu)
  H2FuelCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FuelCost") # [H2Tech,Area,Year] Hydrogen Fuel Cost ($/mmBtu)
  H2PL::VariableArray{2} = ReadDisk(db, "SpInput/H2PL") # [h2tech,Year] Ammonia Production Physical Lifetime (Years)
  H2SaEC::VariableArray{3} = ReadDisk(db,"SpOutput/H2SaEC") # [H2Tech,Area,Year] Electric Sales to Hydrogen (GWh/Yr)
  H2SqTransStorageCost::VariableArray{3} = ReadDisk(db,"SpOutput/H2SqTransStorageCost") # [H2Tech,Area] Hydrogen Sequestering Emissions (Tonnes/Yr)
  H2Trans::VariableArray{3} = ReadDisk(db, "SpInput/H2Trans") # [H2Tech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/mmBtu)
  H2TransCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2TransCost") # [H2Tech,Area,Year] Hydrogen Transmission Costs ($/mmBtu)
  H2VC::VariableArray{3} = ReadDisk(db,"SpOutput/H2VC") # [H2Tech,Area] Hydrogen Variable Cost ($/mmBtu)
  H2VOMCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2VOMCost") # [H2Tech,Area,Year] Hydrogen Production O&M Costs ($/mmBtu)

  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  MoneyUnitDS::Array{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  NH3Cap::VariableArray{3} = ReadDisk(db, "SpOutput/NH3Cap") # [H2Tech,Area,Year] Ammonia Production Capacity (TBtu/Yr)
  NH3CapCR::VariableArray{3} = ReadDisk(db, "SpOutput/NH3CapCR") # [H2Tech,Area,Year] Ammonia Production Capacity Completion Rate (TBtu/Yr)
  NH3CapI::VariableArray{3} = ReadDisk(db, "SpOutput/NH3CapI") # [H2Tech,Area,Year] Ammonia Indicated Production Capacity (TBtu/Yr)
  NH3CapRR::VariableArray{3} = ReadDisk(db, "SpOutput/NH3CapRR") # [H2Tech,Area,Year] Ammonia Production Capacity Retirement Rate (TBtu/Yr)
  NH3CC::VariableArray{3} = ReadDisk(db, "SpOutput/NH3CC") # [H2Tech,Area,Year] Ammonia Production Capital Cost ($/mmBtu)
  NH3CCM::VariableArray{3} = ReadDisk(db, "SpInput/NH3CCM") # [H2Tech,Area,Year] Ammonia Production Capital Cost Multiplier ($/$)
  NH3CUF::VariableArray{3} = ReadDisk(db, "SpOutput/NH3CUF") # [H2Tech,Area,Year] Ammonia Production Capacity Utilization Factor (mmBtu/mmBtu)
  NH3CUFP::VariableArray{3} = ReadDisk(db, "SpInput/NH3CUFP") # [H2Tech,Area,Year] Ammonia Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  NH3Dem::VariableArray{2} = ReadDisk(db, "SpOutput/NH3Dem") # [Area,Year] Demand for Ammonia (TBtu/Yr)
  NH3DemNation::VariableArray{2} = ReadDisk(db, "SpOutput/NH3DemNation") # [Nation,Year] National Demand for Ammonia (TBtu/Yr)
  NH3Eff::VariableArray{3} = ReadDisk(db, "SpInput/NH3Eff") # [H2Tech,Area,Year] Ammonia Production Energy Efficiency (Btu/Btu)
  NH3ENPN::VariableArray{2} = ReadDisk(db, "SpOutput/NH3ENPN") # [Nation,Year] Ammonia Wholesale Price ($/mmBtu)
  NH3Exports::VariableArray{2} = ReadDisk(db, "SpOutput/NH3Exports") # [Nation,Year] Ammonia Exports (TBtu/Yr)
  NH3FOMCost::VariableArray{3} = ReadDisk(db, "SpOutput/NH3FOMCost") # [H2Tech,Area,Year] Ammonia Production O&M Costs ($/mmBtu)
  NH3FPWholesale::VariableArray{2} = ReadDisk(db, "SpOutput/NH3FPWholesale") # [Area,Year] Ammonia Price ($/mmBtu)
  NH3FuelCost::VariableArray{3} = ReadDisk(db, "SpOutput/NH3FuelCost") # [H2Tech,Area,Year] Ammonia Fuel Cost ($/mmBtu)
  NH3H2Yield::Float32 = ReadDisk(db,"SpInput/NH3H2Yield")[1] # [tv] Ammonia Yield from Hydrogen (mmbtu/mmbtu)
  NH3Imports::VariableArray{2} = ReadDisk(db, "SpOutput/NH3Imports") # [Nation,Year] Ammonia Imports (TBtu/Yr)
  NH3MCE::VariableArray{3} = ReadDisk(db, "SpOutput/NH3MCE") # [H2Tech,Area,Year] Ammonia Levelized Marginal Cost ($/mmBtu)
  NH3MSF::VariableArray{3} = ReadDisk(db, "SpOutput/NH3MSF") # [H2Tech,Area,Year] Ammonia Market Share (mmBtu/mmBtu)
  NH3OF::VariableArray{3} = ReadDisk(db, "SpInput/NH3OF") # [H2Tech,Area,Year] Ammonia Production O&M Cost Factor (Real $/$/Yr)
  NH3Prod::VariableArray{3} = ReadDisk(db, "SpOutput/NH3Prod") # [H2Tech,Area,Year] Ammonia Production (TBtu/Yr)
  NH3ProdNation::VariableArray{2} = ReadDisk(db, "SpOutput/NH3ProdNation") # [Nation,Year] Ammonia Production (TBtu/Yr)
  NH3ProdTarget::VariableArray{2} = ReadDisk(db, "SpOutput/NH3ProdTarget") # [Area,Year] Ammonia Production Target (TBtu/Yr)
  NH3ProdTargetN::VariableArray{2} = ReadDisk(db, "SpOutput/NH3ProdTargetN") # [Nation,Year] Ammonia Production Target (TBtu/Yr)
  NH3Production::VariableArray{2} = ReadDisk(db, "SpOutput/NH3Production") # [Area,Year] Ammonia Production (TBtu/Yr)
  NH3Subsidy::VariableArray{2} = ReadDisk(db,"SpInput/NH3Subsidy") # [Area,Year] Ammonia Production Subsidy ($/mmBtu)
  NH3VC::VariableArray{3} = ReadDisk(db, "SpOutput/NH3VC") # [H2Tech,Area,Year] Ammonia Variable Cost ($/mmBtu)
  NH3VOMCost::VariableArray{3} = ReadDisk(db,"SpOutput/NH3VOMCost") # [H2Tech,Area] Ammonia Production Variable O&M Costs ($/mmBtu)

  PInv::VariableArray{3} = ReadDisk(db, "SOutput/PInv") # [ECC,Area,Year] Process Investments (M$/Yr)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  POMExp::VariableArray{3} = ReadDisk(db, "SOutput/POMExp") # [ECC,Area,Year] Process O&M Expenditures (M$)
  SaEC::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") # [ECC,Area,Year] Electricity Sales (GWh/Yr)
  xENPN::VariableArray{3} = ReadDisk(db, "SInput/xENPN") #[Fuel,Nation,Year]  Exogenous Price Normal (Real $/mmBtu)
  xNH3Exports::VariableArray{2} = ReadDisk(db,"SpInput/xNH3Exports") # [Area,Year] Ammonia Exports (TBtu)
end

function NH3Summary_DtaRun(data, areas, areakey, areaname, nation)
  (; SceName,Year,Area,ECC,ECCDS,ESs,ESDS,FuelDS,FuelEPs,H2Techs,H2TechDS) = data
  (; Nation,NationDS,Nations,Poll,PollDS) = data
  (; CDTime,CDYear,SceName,ANMap,eCO2Price,ENPN,ExchangeRate,FPF,FsFP) = data
  (; FuelExpenditures,H2CC,H2CCR,H2ECFP,H2EmissionCost,H2FeedstockCost) = data
  (; H2FOMCost,H2FsYield,H2FuelCost,H2PL,H2SaEC,H2SqTransStorageCost) = data
  (; H2Trans,H2TransCost,H2VC,H2VOMCost,Inflation,InflationNation) = data
  (; MoneyUnitDS,NH3Cap,NH3CapCR,NH3CapI,NH3CapRR,NH3CC,NH3CCM) = data
  (; NH3CUF,NH3CUFP,NH3Dem,NH3DemNation,NH3Eff,NH3ENPN,NH3Exports) = data
  (; NH3FOMCost,NH3FPWholesale,NH3FuelCost,NH3H2Yield) = data
  (; NH3Imports,NH3MCE,NH3MSF,NH3OF,NH3Prod,NH3ProdNation) = data
  (; NH3ProdTarget,NH3ProdTargetN,NH3Production,NH3Subsidy,NH3VC,NH3VOMCost) = data
  (; PInv,PolConv,POMExp,SaEC,xENPN,xNH3Exports) = data  
  
  PPP = zeros(Float32, length(Poll), length(Year))
  WeightProd = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))
  years = collect(Yr(1990):Final)
  area_single=first(areas)

  iob = IOBuffer()

  println(iob)
  println(iob, "$SceName; is the scenario name.")
  println(iob)
  println(iob, "This file was produced by NH3Summary.jl")
  println(iob)
  println(iob, "Year;", ";", join(Year[years], ";"))
  println(iob)

  #
  # Inflation code below is short term mess to get file working and needs replaced
  # Goal was to move calculation into single spot instead of each equation
  #
  InflationCDTime = zeros(Float32, length(Area), length(Year))
  InflationNationCDTime = zeros(Float32, length(Nation), length(Year))

  @. InflationNationCDTime[Nations, years] = InflationNation[Nations, CDYear] / InflationNation[Nations, years]

  @. InflationCDTime[areas, years] = Inflation[areas, CDYear] / Inflation[areas, years]

  WeightProd[years] .= sum(NH3Prod[h2tech , area, years] for area in areas, h2tech in H2Techs)

  #
  # Production Target Table
  #
  println(iob,areaname," Ammonia Production Target (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3Dem;Domestic Demand")
  for year in years  
    ZZZ[year] = sum(NH3Dem[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end    
  println(iob)
  print(iob, "NH3Exports;Exports")
  for year in years  
    ZZZ[year] = sum(xNH3Exports[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end   
  println(iob)
  print(iob, "NH3Imports;Imports")
  for year in years  
    ZZZ[year] = 0.0
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "NH3ProdTarget;Production Target")
  for year in years  
    ZZZ[year] = sum(NH3ProdTarget[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end  
  println(iob)
  print(iob, "NH3Production;Production")
  for year in years  
    # ZZZ[year] = NH3Production[area,year]
    ZZZ[year] = sum(NH3Prod[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end  
  println(iob)
  println(iob)

  println(iob, areaname, " Ammonia Wholesale Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  print(iob, "NH3FPWholesale;Total")
  for year in years
    ZZZ[year] = NH3FPWholesale[area_single, year] * InflationCDTime[area_single, year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$(Nation[nation]) Ammonia Wholesale National Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  print(iob, "NH3ENPN;Total")
  for year in years
    ZZZ[year] = NH3ENPN[nation,year] * InflationNationCDTime[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Ammonia Delivered Fuel Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for es in ESs
    for fuel in Select(FuelDS, "Ammonia")
      print(iob, "FPF;", ESDS[es])
      for year in years
        ZZZ[year] = FPF[fuel,es,area_single,year] * InflationCDTime[area_single,year]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
  end
  println(iob)
  
  #
  # Feedstock Fuel Price (FsFP)
  #
  println(iob, areaname," Feedstock Fuel Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  fuel = Select(FuelDS,"Ammonia")
  for es in ESs
    print(iob, "FsFP;",ESDS[es])
    for year in years 
      ZZZ[year] = FsFP[fuel,es,area_single,year]*Inflation[area_single,CDYear]/Inflation[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  # Electricity Price (FPF)
  #  
  println(iob,areaname," Electricity Delivered Fuel Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  fuel = Select(FuelDS,"Electric")  
  for es in ESs
    print(iob,"FPF;",ESDS[es])
    for year in years 
      ZZZ[year] = FPF[fuel,es,area_single,year]*Inflation[area_single,CDYear]/Inflation[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  println(iob, areaname, " Ammonia Production (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3Prod;Total")
  for year in years
    ZZZ[year] = sum(NH3Prod[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "NH3Prod;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(NH3Prod[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Production Overnight Capital Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3CC;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = NH3CC[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Levelized Marginal Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3MCE;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = NH3MCE[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Production Levelized Capital Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3CCLevelized;", H2TechDS[h2tech])
    for year in years
      @finite_math ZZZ[year] = NH3CC[h2tech,area_single,year] * InflationCDTime[area_single,year] * H2CCR[h2tech,area_single,year] / NH3CUFP[h2tech,area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Fuel Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3FuelCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = NH3FuelCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Hydrogen Feedstock Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "H2FeedstockCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2FeedstockCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Fixed O&M Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3FOMCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = NH3FOMCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Variable O&M Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3VOMCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = NH3VOMCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Production Capacity (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3Cap;Total")
  for year in years
    ZZZ[year] = sum(NH3Cap[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "NH3Cap;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(NH3Cap[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Production Capacity Completion Rate (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3CapCR;Total")
  for year in years
    ZZZ[year] = sum(NH3CapCR[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "NH3CapCR;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(NH3CapCR[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Indicated Production Capacity (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3CapI;Total")
  for year in years
    ZZZ[year] = sum(NH3CapI[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "NH3CapI;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(NH3CapI[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Production Capacity Retirement Rate (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3CapRR;Total")
  for year in years
    ZZZ[year] = sum(NH3CapRR[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "NH3CapRR;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(NH3CapRR[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Production Capacity Utilization Factor (mmBtu/mmBtu);;", join(Year[years], ";"))
  print(iob, "NH3CUF;Total (delete in Promula?)")
  for year in years
    ZZZ[year] = sum(NH3CUF[h2tech,area,year] * NH3Prod[h2tech,area,year] for area in areas, h2tech in H2Techs) / WeightProd[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "NH3CUF;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(NH3CUF[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Delivered Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3Delivered;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = NH3MCE[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Market Share (mmBtu/mmBtu);;", join(Year[years], ";"))
  print(iob, "NH3MSF;Total (delete in Promula?)")
  for year in years
    ZZZ[year] = sum(NH3MSF[h2tech,area,year] * NH3Prod[h2tech,area,year] for area in areas, h2tech in H2Techs) / WeightProd[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "NH3MSF;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(NH3MSF[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, areaname, " Ammonia Variable Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  for h2tech in H2Techs
    print(iob, "NH3VC;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = NH3VC[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$(Nation[nation]) National Demand for Ammonia (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3DemNation;Total")
  for year in years
    ZZZ[year] = NH3DemNation[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$(Nation[nation]) Ammonia Production Target (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3ProdTargetN;Total")
  for year in years
    ZZZ[year] = NH3ProdTargetN[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$(Nation[nation]) Ammonia Production (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3ProdNation;Total")
  for year in years
    ZZZ[year] = NH3ProdNation[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$(Nation[nation]) Ammonia Exports (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3Exports;Total")
  for year in years
    ZZZ[year] = NH3Exports[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$(Nation[nation]) Ammonia Imports (TBtu/Yr);;", join(Year[years], ";"))
  print(iob, "NH3Imports;Total")
  for year in years
    ZZZ[year] = NH3Imports[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$(Nation[nation]) Ammonia Wholesale National Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  fuel=Select(FuelDS,"Ammonia")
  print(iob, "ENPN;Ammonia")
  for year in years
    ZZZ[year] = ENPN[fuel,nation,year] * InflationNation[nation,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, "$(Nation[nation]) Ammonia Exogenous Wholesale National Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);;", join(Year[years], ";"))
  fuel=Select(FuelDS,"Ammonia")
  print(iob, "xENPN;Ammonia")
  for year in years
    ZZZ[year] = xENPN[fuel,nation,year] * InflationNation[nation,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Electric Sales;;", join(Year[years], ";"))
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "SaEC;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, areaname, " Process Investments (", CDTime, "M\$/);;", join(Year[years], ";"))
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "PInv;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(PInv[ecc,area,year] * InflationCDTime[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, areaname, "  Process O&M Expenditures (", CDTime, "M\$/);;", join(Year[years], ";"))
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "POMExp;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(POMExp[ecc,area,year] * InflationCDTime[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob, areaname, "  Fuel Expenditures (", CDTime, "M\$/);;", join(Year[years], ";"))
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "FuelExpenditures;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(FuelExpenditures[ecc,area,year] * InflationCDTime[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # NH3Marginal Price
  #
  for h2tech in H2Techs
    println(iob, areaname, " ",H2TechDS[h2tech], " Ammonia Cost Summary (",MoneyUnitDS[area_single],"$CDTime/mmBtu);;", join(Year[years], ";"))
    print(iob, "NH3FP;Delivered Price")
    for year in years
      ZZZ[year] = NH3MCE[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]-NH3Subsidy[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    
    #
    # Delivery Charge ($/mmBtu)
    #
    print(iob, "  ;Delivery Charge")
    for year in years
      ZZZ[year] = 0.0
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Cost of Production ($/mmBtu)
    #  
    print(iob, "NH3MCE;Marginal Cost of Production")
    for year in years
      ZZZ[year] = NH3MCE[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Variable Cost ($/mmBtu)
    #
    print(iob, "NH3VC;Variable Cost")
    for year in years
      ZZZ[year] = NH3VC[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost ($/mmBtu)
    #
    print(iob, "NH3CC*H2CCR/NH3CUFP;Levelized Capital Cost")
    for year in years
      @finite_math ZZZ[year] = NH3CC[h2tech,area_single,year]*H2CCR[h2tech,area_single,year]/NH3CUFP[h2tech,area_single,year]/
          Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost ($/mmBtu/Yr)
    #
    print(iob, "NH3CC*H2CCR;Charged Capital Cost")
    for year in years
      ZZZ[year] = NH3CC[h2tech,area_single,year]*H2CCR[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Overnight Construction Cost ($/mmBtu)
    #
    print(iob, "NH3CC;Overnight Capital Cost")
    for year in years
      ZZZ[year] = NH3CC[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost Multiplier ($/$)'
    #
    print(iob, "NH3CCM;Capital Cost Trend")
    for year in years
      ZZZ[year] = NH3CCM[h2tech,area_single,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Charge Rate (1/Yr)
    #
    print(iob, "H2CCR;Capital Charge Rate (1/Yr)")
    for year in years
      ZZZ[year] = H2CCR[h2tech,area_single,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Ammonia Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
    #
    print(iob, "NH3CUFP;Capacity Utilization Factor (Btu NH3/Btu NH3)")
    for year in years
      ZZZ[year] = NH3CUFP[h2tech,area_single,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fixed O&M Cost ($/mmBtu)
    #
    print(iob, "NH3FOMCost;Levelized Fixed O&M Cost")
    for year in years
      @finite_math ZZZ[year] = NH3FOMCost[h2tech,area_single,year]/NH3CUFP[h2tech,area_single,year]/
          Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Ammonia Production O&M Cost Factor (Real $/$/Yr))
    #
    print(iob, "NH3OF;O&M Cost Fraction of Capital Cost ((\$/Yr)/\$)")
    for year in years
      ZZZ[year] = NH3OF[h2tech,area_single,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Variable O&M Cost ($/mmBtu)
    #
    print(iob, "NH3VOMCost;Variable O&M Cost")
    for year in years
      ZZZ[year] = NH3VOMCost[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fuel Cost ($/mmBtu)
    #
    print(iob, "NH3FuelCost;Fuel Cost")
    for year in years
      ZZZ[year] = NH3FuelCost[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Ammonia Production Energy Efficiency (Btu/Btu)
    #
    print(iob, "NH3Eff;Energy Efficiency (Btu NH3/Btu Tech)")
    for year in years
      ZZZ[year] = NH3Eff[h2tech,area_single,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Feedstock Cost ($/mmBtu)
    #
    print(iob, "H2FeedstockCost;NG Feedstock Cost")
    for year in years
      ZZZ[year] = H2FeedstockCost[h2tech,area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Yield From Feedstock (Btu/Btu)
    #
    print(iob, "H2FsYield;Yield From NG Feedstock (Btu H2/Btu NG)")
    for year in years
      ZZZ[year] = H2FsYield[h2tech,area_single,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Carbon Tax plus Permit Cost ($/eCO2 Tonnes)
    #
    print(iob, "eCO2Price;Carbon Tax plus Permit Cost (", MoneyUnitDS[area_single],"$CDTime/eCO2 Tonnes)")
    for year in years
      ZZZ[year] = eCO2Price[area_single,year]/Inflation[area_single,year]*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Hydrogen Production Physical Lifetime (Years)
    #
    print(iob, "H2PL;Physical Lifetime (Years)")
    for year in years
      ZZZ[year] = H2PL[h2tech,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    println(iob, " ")

  end

  println(iob, areaname, " Additional Variables;;", join(Year[years], ";"))
  print(iob, "ExchangeRate;Local Currency/US\$ Exchange Rate (Local/US\$)")
  for year in years
    ZZZ[year] = ExchangeRate[area_single,year]
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob, " ")


  filename = "NH3Summary-$areakey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function NH3Summary_DtaControl(db)

  @info "NH3Summary_DtaControl"
  data = NH3SummaryData(; db)
  (; ANMap, Area, AreaDS, Areas, Nation, NationDS) = data

  CN=Select(Nation,"CN")
  areas=Select(Area,["AB","ON","QC","BC","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  for area in areas
    areaname = AreaDS[area]
    areakey = Area[area]
    NH3Summary_DtaRun(data, area, areakey, areaname, CN)
  end
  areaname=NationDS[CN]
  areakey = Nation[CN]
  NH3Summary_DtaRun(data, areas, areakey, areaname, CN)

end

if abspath(PROGRAM_FILE) == @__FILE__
NH3Summary_DtaControl(DB)
end


