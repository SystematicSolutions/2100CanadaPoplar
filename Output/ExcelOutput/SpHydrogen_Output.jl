#
# SpHydrogen_Output.jl
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

Base.@kwdef struct SpHydrogen_OutputData
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
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") # [Fuel,Nation,Year] Primary Fuel Price ($/mmBtu) Type=Real(82)
  FPF::VariableArray{4} = ReadDisk(db, "SOutput/FPF") # [Fuel,ES,Area,Year] Delivered Fuel Price ($/mmBtu)
  FsFP::VariableArray{4} = ReadDisk(db, "SOutput/FsFP") # [Fuel,ES,Area,Year] Feedstock Fuel Price ($/mmBtu)
  FuelExpenditures::VariableArray{3} = ReadDisk(db, "SOutput/FuelExpenditures") #[ECC,Area,Year]  Fuel Expenditures (M$)
  H2Cap::VariableArray{3} = ReadDisk(db, "SpOutput/H2Cap") # [H2Tech,Area,Year] Hydrogen Production Capacity (TBtu/Yr)
  H2CapCR::VariableArray{3} = ReadDisk(db, "SpOutput/H2CapCR") # [H2Tech,Area,Year] Hydrogen Production Capacity Completion Rate (TBtu/Yr)
  H2CapI::VariableArray{3} = ReadDisk(db, "SpOutput/H2CapI") # [H2Tech,Area,Year] Hydrogen Indicated Production Capacity (TBtu/Yr)
  H2CapRR::VariableArray{3} = ReadDisk(db, "SpOutput/H2CapRR") # [H2Tech,Area,Year] Hydrogen Production Capacity Retirement Rate (TBtu/Yr)
  H2CC::VariableArray{3} = ReadDisk(db, "SpOutput/H2CC") # [H2Tech,Area,Year] Hydrogen Production Capital Cost ($/mmBtu)
  H2CCR::VariableArray{3} = ReadDisk(db, "SpInput/H2CCR") # [H2Tech,Area,Year] Hydrogen Production Capital Charge Rate
  H2CUF::VariableArray{3} = ReadDisk(db, "SpOutput/H2CUF") # [H2Tech,Area,Year] Hydrogen Production Capacity Utilization Factor (mmBtu/mmBtu)
  H2CUFP::VariableArray{3} = ReadDisk(db, "SpInput/H2CUFP") # [H2Tech,Area,Year] Hydrogen Production Capacity Utilization Factor for Planning (mmBtu/mmBtu)
  H2Dem::VariableArray{2} = ReadDisk(db, "SpOutput/H2Dem") # [Area,Year] Demand for Hydrogen (TBtu/Yr)
  H2Demand::VariableArray{4} = ReadDisk(db, "SpOutput/H2Demand") # [Fuel,H2Tech,Area,Year] Hydrogen Production Energy Usage (TBtu/Yr)
  H2DemNation::VariableArray{2} = ReadDisk(db, "SpOutput/H2DemNation") # [Nation,Year] National Demand for Hydrogen (TBtu/Yr)
  H2Dmd::VariableArray{3} = ReadDisk(db, "SpOutput/H2Dmd") # [H2Tech,Area,Year] Hydrogen Production Energy Usage (TBtu/Yr)
  H2ECFP::VariableArray{3} = ReadDisk(db, "SpOutput/H2ECFP") # [H2Tech,Area,Year] Fuel Prices for Hydrogen Production ($/mmBtu)
  H2EI::VariableArray{3} = ReadDisk(db, "SpOutput/H2EI") # [H2Tech,Area,Year] Hydrogen Production GHG Emission Intensity (Tonnes eCO2/TBtu H2)
  H2EIDmd::VariableArray{3} = ReadDisk(db, "SpOutput/H2EIDmd") # [H2Tech,Area,Year] Hydrogen Production GHG Combustion Emission Intensity (Tonnes eCO2/TBtu H2)
  H2EIFs::VariableArray{3} = ReadDisk(db, "SpOutput/H2EIFs") # [H2Tech,Area,Year] Hydrogen Production GHG Feedstock Emission Intensity (Tonnes eCO2/TBtu H2)
  H2EmissionCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2EmissionCost") # [H2Tech,Area,Year] Hydrogen Emission Cost ($/mmBtu)
  H2ENPN::VariableArray{2} = ReadDisk(db, "SpOutput/H2ENPN") # [Nation,Year] Hydrogen Wholesale Price ($/mmBtu)
  H2ENPNExports::VariableArray{2} = ReadDisk(db, "SpOutput/H2ENPNExports") # [Nation,Year] Hydrogen Exports Price ($/mmBtu)
  H2ENPNImports::VariableArray{2} = ReadDisk(db, "SpOutput/H2ENPNImports") # [Nation,Year] Hydrogen Imports Price ($/mmBtu)
  H2Exports::VariableArray{2} = ReadDisk(db, "SpOutput/H2Exports") # [Nation,Year] Hydrogen Exports (TBtu/Yr)
  H2ExportsEst::VariableArray{2} = ReadDisk(db, "SpOutput/H2ExportsEst") # [Nation,Year] Estimate of Hydrogen Exports (TBtu/Yr)
  H2ExportsMSF::VariableArray{2} = ReadDisk(db, "SpOutput/H2ExportsMSF") # [Nation,Year] Hydrogen Exports Market Share (TBtu/Yr)
  H2FeedstockCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FeedstockCost") # [H2Tech,Area,Year] Hydrogen Feedstock Cost ($/mmBtu)
  H2FOMCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FOMCost") # [H2Tech,Area,Year] Hydrogen Production O&M Costs ($/mmBtu)
  H2FPWholesale::VariableArray{2} = ReadDisk(db, "SpOutput/H2FPWholesale") # [Area,Year] Hydrogen Price ($/mmBtu)
  H2FsDem::VariableArray{4} = ReadDisk(db, "SpOutput/H2FsDem") # [Fuel,H2Tech,Area,Year] Hydrogen Feedstock Demand (TBtu/Yr)
  H2FsPol::VariableArray{5} = ReadDisk(db, "SpOutput/H2FsPol") # [FuelEP,H2Tech,Poll,Area,Year] Hydrogen Production Feedstock Emissions (Tonnes/Yr)
  H2FsPrice::VariableArray{3} = ReadDisk(db, "SpOutput/H2FsPrice") # [H2Tech,Area,Year] Hydrogen Feedstock Price ($/mmBtu)
  H2FsReq::VariableArray{3} = ReadDisk(db, "SpOutput/H2FsReq") # [H2Tech,Area,Year] Hydrogen Feedstock Required (TBtu/Yr)
  H2FuelCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2FuelCost") # [H2Tech,Area,Year] Hydrogen Fuel Cost ($/mmBtu)
  H2Imports::VariableArray{2} = ReadDisk(db, "SpOutput/H2Imports") # [Nation,Year] Hydrogen Imports (TBtu/Yr)
  H2ImportsEst::VariableArray{2} = ReadDisk(db, "SpOutput/H2ImportsEst") # [Nation,Year] Hydrogen Imports (TBtu/Yr)
  H2ImportsMSF::VariableArray{2} = ReadDisk(db, "SpOutput/H2ImportsMSF") # [Nation,Year] Hydrogen Imports Market Share (TBtu/Yr)
  H2MCE::VariableArray{3} = ReadDisk(db, "SpOutput/H2MCE") # [H2Tech,Area,Year] Hydrogen Levelized Marginal Cost ($/mmBtu)
  H2MSF::VariableArray{3} = ReadDisk(db, "SpOutput/H2MSF") # [H2Tech,Area,Year] Hydrogen Market Share (mmBtu/mmBtu)
  H2Pol::VariableArray{5} = ReadDisk(db, "SpOutput/H2Pol") # [FuelEP,H2Tech,Poll,Area,Year] Hydrogen Production Combustion Emissions (Tonnes/Yr)
  H2Prod::VariableArray{3} = ReadDisk(db, "SpOutput/H2Prod") # [H2Tech,Area,Year] Hydrogen Production (TBtu/Yr)
  H2ProdNation::VariableArray{2} = ReadDisk(db, "SpOutput/H2ProdNation") # [Nation,Year] Hydrogen Production (TBtu/Yr)
  H2ProdTarget::VariableArray{2} = ReadDisk(db, "SpOutput/H2ProdTarget") # [Area,Year] Hydrogen Production Target (TBtu/Yr)
  H2ProdTargetN::VariableArray{2} = ReadDisk(db, "SpOutput/H2ProdTargetN") # [Nation,Year] Hydrogen Production Target (TBtu/Yr)
  H2Production::VariableArray{2} = ReadDisk(db, "SpOutput/H2Production") # [Area,Year] Hydrogen Production (TBtu/Yr)
  H2SaEC::VariableArray{3} = ReadDisk(db,"SpOutput/H2SaEC") # [H2Tech,Area,Year] Electric Sales to Hydrogen (GWh/Yr)
  H2SqPol::VariableArray{4} = ReadDisk(db, "SpOutput/H2SqPol") # [H2Tech,Poll,Area,Year] Hydrogen Sequestering Emissions (Tonnes/Yr)
  H2SqPolPenalty::VariableArray{4} = ReadDisk(db, "SpOutput/H2SqPolPenalty") # [H2Tech,Poll,Area,Year] Hydrogen Sequestering Emissions Penalty (Tonnes/Yr)
  H2Trans::VariableArray{3} = ReadDisk(db, "SpInput/H2Trans") # [H2Tech,Area,Year] Hydrogen Incremental Transmission Cost (Real $/mmBtu)
  H2VC::VariableArray{3} = ReadDisk(db, "SpOutput/H2VC") # [H2Tech,Area,Year] Hydrogen Variable Cost ($/mmBtu)
  H2VOMCost::VariableArray{3} = ReadDisk(db, "SpOutput/H2VOMCost") # [H2Tech,Area,Year] Hydrogen Production O&M Costs ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  MoneyUnitDS::Array{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  NH3H2Yield::Float32 = ReadDisk(db,"SpInput/NH3H2Yield")[1] # [tv] Ammonia Yield from Hydrogen (mmbtu/mmbtu)
  PInv::VariableArray{3} = ReadDisk(db, "SOutput/PInv") # [ECC,Area,Year] Process Investments (M$/Yr)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Greenhouse Gas Coversion (eCO2 Tonnes/Tonnes)
  POMExp::VariableArray{3} = ReadDisk(db, "SOutput/POMExp") # [ECC,Area,Year] Process O&M Expenditures (M$)
  SaEC::VariableArray{3} = ReadDisk(db, "SOutput/SaEC") # [ECC,Area,Year] Electricity Sales (GWh/Yr)
  xENPN::VariableArray{3} = ReadDisk(db, "SInput/xENPN") #[Fuel,Nation,Year]  Exogenous Price Normal (Real $/mmBtu)
  xNH3Exports::VariableArray{2} = ReadDisk(db,"SpInput/xNH3Exports") # [Area,Year] Ammonia Exports (TBtu)

end

function SpHydrogen_Output_DtaRun(data, areas, areakey, areaname, nation)
  (; SceName,Year,Area,ECC,ECCDS,ESs,ESDS,FuelDS,FuelEPs,H2Techs,H2TechDS,Nation,NationDS,Nations,Poll,PollDS,InflationNation,Inflation,PolConv,ANMap) = data
  (; FPF,FsFP,H2CC,H2CCR,H2CUFP,H2Dem,H2ECFP,H2ENPN,H2ENPNExports,H2ENPNImports,H2ExportsMSF,H2FsPrice,H2FPWholesale) = data
  (; H2ImportsMSF,H2Prod,H2ProdTarget,H2Production,H2MCE,H2FuelCost,H2FeedstockCost,H2EmissionCost,H2FOMCost) = data
  (; H2VOMCost,H2Pol,H2FsPol,H2SqPol,H2SqPolPenalty,H2Cap,H2CapCR,H2CapI,H2CapRR,H2CUF,H2Demand,H2Dmd,H2FsDem,H2FsReq) = data
  (; H2EI,H2EIDmd,H2EIFs,H2MSF,H2Trans,H2VC,H2DemNation,H2ProdNation,H2ProdTargetN,H2Exports,H2ExportsEst) = data
  (; CDTime,CDYear,H2Imports,H2ImportsEst,ENPN,xENPN,H2SaEC,SaEC,PInv,POMExp,FuelExpenditures,MoneyUnitDS) = data
  (; NH3H2Yield,xNH3Exports) = data  
  
  PPP = zeros(Float32, length(Poll), length(Year))
  WeightProd = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))
  years = collect(Yr(1990):Final)
  area_single=first(areas)

  iob = IOBuffer()

  println(iob)
  println(iob, "$SceName; is the scenario name.")
  println(iob)
  println(iob, "This file was produced by SpHydrogen_output.jl")
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

  WeightProd[years] .= sum(H2Prod[h2tech , area, years] for area in areas, h2tech in H2Techs)

  #
  # Production Target Table
  #
  print(iob,areaname," Hydrogen Production Target (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "H2Dem;Domestic Demand")
  for year in years  
    ZZZ[year] = sum(H2Dem[area,year]-xNH3Exports[area,year]/NH3H2Yield for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end    
  println(iob)
  print(iob, "H2Exports;Exports")
  for year in years  
    ZZZ[year] = sum(xNH3Exports[area,year]/NH3H2Yield for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end   
  println(iob)
  print(iob, "H2Imports;Imports")
  for year in years  
    ZZZ[year] = 0.0
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  print(iob, "H2ProdTarget;Production Target")
  for year in years  
    ZZZ[year] = sum(H2ProdTarget[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end  
  println(iob)
  print(iob, "H2Production;Production")
  for year in years  
    # ZZZ[year] = H2Production[area,year]
    ZZZ[year] = sum(H2Prod[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end  
  println(iob)
  println(iob)

  print(iob, areaname, " Hydrogen Wholesale Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "H2FPWholesale;Total")
  for year in years
    ZZZ[year] = H2FPWholesale[area_single, year] * InflationCDTime[area_single, year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Wholesale National Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "H2ENPN;Total")
  for year in years
    ZZZ[year] = H2ENPN[nation,year] * InflationNationCDTime[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Exports Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "H2ENPNExports;Total")
  for year in years
    ZZZ[year] = H2ENPNExports[nation,year] * InflationNationCDTime[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Imports Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "H2ENPNImports;Total")
  for year in years
    ZZZ[year] = H2ENPNImports[nation,year] * InflationNationCDTime[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, areaname, " Fuel Prices for Hydrogen Production ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2ECFP;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2ECFP[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Feedstock Price for Hydrogen Production ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FsPrice;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2FsPrice[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Delivered Fuel Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for es in ESs
    for fuel in Select(FuelDS, "Hydrogen")
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
  print(iob, areaname," Feedstock Fuel Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  fuel = Select(FuelDS,"Hydrogen")
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
  print(iob,areaname," Electricity Delivered Fuel Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob,)
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
  

  print(iob, areaname, " Hydrogen Production (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob,)
  print(iob, "H2Prod;Total")
  for year in years
    ZZZ[year] = sum(H2Prod[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Prod;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2Prod[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Overnight Capital Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob,)
  for h2tech in H2Techs
    print(iob, "H2CC;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2CC[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Levelized Marginal Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2MCE;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2MCE[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Levelized Capital Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CCLevelized;", H2TechDS[h2tech])
    for year in years
      @finite_math ZZZ[year] = H2CC[h2tech,area_single,year] * InflationCDTime[area_single,year] * H2CCR[h2tech,area_single,year] / H2CUFP[h2tech,area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Fuel Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FuelCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2FuelCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Feedstock Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FeedstockCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2FeedstockCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Emission Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2EmissionCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2EmissionCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Fixed O&M Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FOMCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2FOMCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Variable O&M Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2VOMCost;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2VOMCost[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Net Production GHG Emissions (MT/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  print(iob, "H2Pol,H2FsPol;Total")
  for year in years
    ZZZ[year] = sum((H2Pol[fuelep,h2tech,poll,area,year]+H2FsPol[fuelep,h2tech,poll,area,year])*PolConv[poll]
      for area in areas, h2tech in H2Techs, fuelep in FuelEPs, poll in polls)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "Net GHG;", H2TechDS[h2tech])
    # print(iob, "H2Pol,H2FsPol;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum((H2Pol[fuelep,h2tech,poll,area,year]+H2FsPol[fuelep,h2tech,poll,area,year])*PolConv[poll]
        for area in areas, fuelep in FuelEPs,poll in polls)/1e6
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Gross Combustion GHG Emissions (MT/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  print(iob, "H2Pol;Total")
  for year in years
    ZZZ[year] = sum(H2Pol[fuelep,h2tech,poll,area,year]*PolConv[poll]*PolConv[poll]
      for area in areas, h2tech in H2Techs, fuelep in FuelEPs, poll in polls)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Pol;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2Pol[fuelep,h2tech,poll,area,year]*PolConv[poll]
        for area in areas, fuelep in FuelEPs,poll in polls)/1e6
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Gross Feedstock GHG Emissions (MT/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  print(iob, "H2FsPol;Total")
  for year in years
    ZZZ[year] = sum(H2FsPol[fuelep,h2tech,poll,area,year]*PolConv[poll]
      for area in areas, h2tech in H2Techs, fuelep in FuelEPs, poll in polls)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FsPol;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2FsPol[fuelep,h2tech,poll,area,year]*PolConv[poll]
        for area in areas, fuelep in FuelEPs,poll in polls)/1e6
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Sequestered GHG Emissions (MT/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  print(iob, "H2SqPol;Total")
  for year in years
    ZZZ[year] = sum(H2SqPol[h2tech,poll,area,year]*PolConv[poll]
      for area in areas,  h2tech in H2Techs, poll in polls)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2SqPol;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2SqPol[h2tech,poll,area,year]*PolConv[poll]
        for area in areas,  poll in polls)/1e6
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Sequestered GHG Emissions Penalty (MT/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  polls = Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])
  print(iob, "H2SqPolPenalty;Total")
  for year in years
    ZZZ[year] = sum(H2SqPolPenalty[h2tech,poll,area,year]*PolConv[poll]
      for area in areas,  h2tech in H2Techs, poll in polls)/1e6
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2SqPolPenalty;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2SqPolPenalty[h2tech,poll,area,year]*PolConv[poll]
        for area in areas,  poll in polls)/1e6
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Capacity (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2Cap;Total")
  for year in years
    ZZZ[year] = sum(H2Cap[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Cap;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2Cap[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Capacity Completion Rate (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2CapCR;Total")
  for year in years
    ZZZ[year] = sum(H2CapCR[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CapCR;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2CapCR[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Indicated Production Capacity (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2CapI;Total")
  for year in years
    ZZZ[year] = sum(H2CapI[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CapI;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2CapI[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Capacity Retirement Rate (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2CapRR;Total")
  for year in years
    ZZZ[year] = sum(H2CapRR[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CapRR;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2CapRR[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Capacity Utilization Factor (mmBtu/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2CUF;Total (delete in Promula?)")
  for year in years
    ZZZ[year] = sum(H2CUF[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas, h2tech in H2Techs) / WeightProd[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2CUF;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2CUF[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Energy Usage (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2Demand;Total")
  for year in years
    ZZZ[year] = sum(H2Demand[fuel,h2tech,area,year] for area in areas, h2tech in H2Techs, fuel in Select(FuelDS))
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Demand;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2Demand[fuel,h2tech,area,year] for area in areas, fuel in Select(FuelDS))
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production Energy Usage (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2Dmd;Total")
  for year in years
    ZZZ[year] = sum(H2Dmd[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Dmd;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2Dmd[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, "  Hydrogen Feedstock Demand (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2FsDem;Total")
  for year in years
    ZZZ[year] = sum(H2FsDem[fuel,h2tech,area,year] for area in areas, h2tech in H2Techs, fuel in Select(FuelDS))
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FsDem;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2FsDem[fuel,h2tech,area,year] for area in areas, fuel in Select(FuelDS))
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, "  Hydrogen Feedstock Required (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2FsReq;Total")
  for year in years
    ZZZ[year] = sum(H2FsReq[h2tech,area,year] for area in areas, h2tech in H2Techs)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2FsReq;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2FsReq[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production GHG Emission Intensity (Tonnes eCO2/TBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2EI;Total (delete in Promula?)")
  for year in years
    ZZZ[year] = sum(H2EI[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas, h2tech in H2Techs) ./ WeightProd[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2EI;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2EI[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas) ./ WeightProd[year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Production GHG Combustion Emission Intensity (Tonnes eCO2/TBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2EIDmd;Total (delete in Promula?)")
  for year in years
    ZZZ[year] = sum(H2EIDmd[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas, h2tech in H2Techs) / WeightProd[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2EIDmd;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2EIDmd[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas) / WeightProd[year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob) 

  print(iob, areaname, " Hydrogen Production GHG Feedstock Emission Intensity (Tonnes eCO2/TBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2EIFs;Total (delete in Promula?)")
  for year in years
    ZZZ[year] = sum(H2EIFs[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas, h2tech in H2Techs) / WeightProd[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2EIFs;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2EIFs[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas) / WeightProd[year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Incremental Transmission Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Trans;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2Trans[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Delivered Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2Delivered;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2MCE[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Market Share (mmBtu/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2MSF;Total (delete in Promula?)")
  for year in years
    ZZZ[year] = sum(H2MSF[h2tech,area,year] * H2Prod[h2tech,area,year] for area in areas, h2tech in H2Techs) / WeightProd[year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2MSF;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2MSF[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Hydrogen Variable Cost ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2VC;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = H2VC[h2tech,area_single,year] * InflationCDTime[area_single,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, "$(Nation[nation]) National Demand for Hydrogen (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2DemNation;Total")
  for year in years
    ZZZ[year] = H2DemNation[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Production Target (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2ProdTargetN;Total")
  for year in years
    ZZZ[year] = H2ProdTargetN[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Production (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2ProdNation;Total")
  for year in years
    ZZZ[year] = H2ProdNation[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Exports (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2Exports;Total")
  for year in years
    ZZZ[year] = H2Exports[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Imports (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2Imports;Total")
  for year in years
    ZZZ[year] = H2Imports[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Estimate of Hydrogen Exports (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2ExportsEst;Total")
  for year in years
    ZZZ[year] = H2ExportsEst[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Estimate of Hydrogen Imports (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  print(iob, "H2ImportsEst;Total")
  for year in years
    ZZZ[year] = H2ImportsEst[nation,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Wholesale National Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  fuel=Select(FuelDS,"Hydrogen")
  print(iob, "ENPN;Hydrogen")
  for year in years
    ZZZ[year] = ENPN[fuel,nation,year] * InflationNation[nation,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, "$(Nation[nation]) Hydrogen Exogenous Wholesale National Price ($CDTime ",MoneyUnitDS[area_single],"/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  fuel=Select(FuelDS,"Hydrogen")
  print(iob, "xENPN;Hydrogen")
  for year in years
    ZZZ[year] = xENPN[fuel,nation,year] * InflationNation[nation,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, areaname, " Electric Sales to Hydrogen (GWh/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  for h2tech in H2Techs
    print(iob, "H2SaEC;", H2TechDS[h2tech])
    for year in years
      ZZZ[year] = sum(H2SaEC[h2tech,area,year] for area in areas)
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  print(iob, areaname, " Electric Sales;")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "SaEC;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(SaEC[ecc,area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, areaname, " Process Investments (", CDTime, "M\$/);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "PInv;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(PInv[ecc,area,year] * InflationCDTime[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, areaname, "  Process O&M Expenditures (", CDTime, "M\$/);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "POMExp;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(POMExp[ecc,area,year] * InflationCDTime[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob, areaname, "  Fuel Expenditures (", CDTime, "M\$/);")
  for year in years  
    print(iob,";",Year[year])
  end  
  println(iob)
  ecc = Select(ECCDS, "Hydrogen Production")
  print(iob, "FuelExpenditures;", ECCDS[ecc])
  for year in years
    ZZZ[year] = sum(FuelExpenditures[ecc,area,year] * InflationCDTime[area,year] for area in areas)
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  filename = "SpHydrogen-$areakey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function SpHydrogen_Output_DtaControl(db)

  @info "SpHydrogen_Output_DtaControl"
  data = SpHydrogen_OutputData(; db)
  (; ANMap, Area, AreaDS, Areas, Nation, NationDS) = data

  CN=Select(Nation,"CN")
  areas=Select(Area,["AB","ON","QC","BC","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  for area in areas
    areaname = AreaDS[area]
    areakey = Area[area]
    SpHydrogen_Output_DtaRun(data, area, areakey, areaname, CN)
  end
  areaname=NationDS[CN]
  areakey = Nation[CN]
  SpHydrogen_Output_DtaRun(data, areas, areakey, areaname, CN)

end

if abspath(PROGRAM_FILE) == @__FILE__
SpHydrogen_Output_DtaControl(DB)
end


