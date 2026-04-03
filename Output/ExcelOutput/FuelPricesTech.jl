#
# FuelPricesTech.jl
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

Base.@kwdef struct FuelPricesTechData
  db::String

  Input::String = "IInput"
  Outpt::String = "IOutput"
  CalDB::String = "ICalDB"

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Enduse::SetArray = ReadDisk(db, "$Input/EnduseKey")
  EnduseDS::SetArray = ReadDisk(db, "$Input/EnduseDS")
  Enduses::Vector{Int} = collect(Select(Enduse))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db, "MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  CoverageCFS::VariableArray{4} = ReadDisk(db, "SInput/CoverageCFS") # [Fuel,ECC,Area,Year] Coverage for CFS (1=Covered)
  DmFrac::VariableArray{6} = ReadDisk(db, "$Outpt/DmFrac") # [Enduse,Fuel,Tech,EC,Area,Year] Demand Fuel/Tech Fraction Split (Btu/Btu)
  DmdFEPTech::VariableArray{5} = ReadDisk(db, "$Outpt/DmdFEPTech") # [FuelEP,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  DmdFuelTech::VariableArray{6} = ReadDisk(db, "$Outpt/DmdFuelTech") # [Enduse,Fuel,Tech,EC,Area,Year] Energy Demands (TBtu/Yr)
  ECFP::VariableArray{5} = ReadDisk(db, "$Outpt/ECFP") # [Enduse,Tech,EC,Area,Year] Fuel Price ($/mmBtu)
  ECFPFuel::VariableArray{4} = ReadDisk(db, "$Outpt/ECFPFuel") # [Fuel,EC,Area,Year] Fuel Price w/CFS Price ($/mmBtu)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") # [Fuel,Nation,Year] Wholesale Price ($/mmBtu)
  EuDem::VariableArray{5} = ReadDisk(db, "$Outpt/EuDem") # [Enduse,FuelEP,EC,Area,Year] Enduse Demands (TBtu/Yr)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") # [Area,Year] Local Currency/US$ Exchange Rate (Local/US$)
  ExpCP::VariableArray{4} = ReadDisk(db, "$Outpt/ExpCP") # [FuelEP,EC,Area,Year] Emission Expenditures ($M/Yr)
  FEPCP::VariableArray{4} = ReadDisk(db, "$Outpt/FEPCP") # [FuelEP,EC,Area,Year] Carbon Price by FuelEP ($/mmBtu)
  FFPMap::VariableArray{2} = ReadDisk(db, "SInput/FFPMap") # [FuelEP,Fuel] Map between FuelEP and Fuel
  FPBaseF::VariableArray{4} = ReadDisk(db, "SOutput/FPBaseF") # [Fuel,ES,Area,Year] Delivered Fuel Price without Taxes ($/mmBtu)
  FPCFS::VariableArray{4} = ReadDisk(db, "$Outpt/FPCFS") # [Fuel,EC,Area,Year] CFS Price ($/mmBtu)
  FPCFSFuel::VariableArray{4} = ReadDisk(db, "SOutput/FPCFSFuel") # [Fuel,ES,Area,Year] CFS Price ($/mmBtu)
  FPCFSNet::VariableArray{4} = ReadDisk(db, "$Outpt/FPCFSNet") # [Fuel,EC,Area,Year] CFS Price ($/mmBtu)
  FPCFSObligated::VariableArray{3} = ReadDisk(db, "SOutput/FPCFSObligated") # [ECC,Area,Year] CFS Price for Obligated Sectors ($/Tonnes)
  FPCFSTech::VariableArray{4} = ReadDisk(db, "$Outpt/FPCFSTech") # [Tech,EC,Area,Year] CFS Price ($/mmBtu)
  FPCP::VariableArray{4} = ReadDisk(db, "$Outpt/FPCP") # [Fuel,EC,Area,Year] Carbon Price before OBA ($/mmBtu)
  FPDChgF::VariableArray{4} = ReadDisk(db, "SCalDB/FPDChgF") # [Fuel,ES,Area,Year] Fuel Delivery Charge (Real $/mmBtu)
  FPEC::VariableArray{4} = ReadDisk(db, "$Outpt/FPEC") # [Fuel,EC,Area,Year] Fuel Prices excluding Emission Costs ($/mmBtu)
  FPECC::VariableArray{4} = ReadDisk(db, "SOutput/FPECC") # [Fuel,ECC,Area,Year] Fuel Prices excluding Emission Costs ($/mmBtu)
  FPECCCFS::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFS") # [Fuel,ECC,Area,Year] Fuel Prices w/CFS Price ($/mmBtu)
  FPECCCFSCP::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFSCP") # [Fuel,ECC,Area,Year] Fuel Prices w/CFS and Carbon Price ($/mmBtu)
  FPECCCFSCPNet::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFSCPNet") # [Fuel,ECC,Area,Year] Fuel Prices w/CFS and Net Carbon Price ($/mmBtu)
  FPECCCFSNet::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFSNet") # [Fuel,ECC,Area,Year] Incremental CFS Charge ($/mmBtu)
  FPECCCP::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCP") # [Fuel,ECC,Area,Year] Carbon Price before OBA ($/mmBtu)
  FPECCCPNet::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCPNet") # [Fuel,ECC,Area,Year] Net Carbon Price after OBA ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db, "SOutput/FPF") # [Fuel,ES,Area,Year] Fuel Price ($/mmBtu)
  FPMarginF::VariableArray{4} = ReadDisk(db, "SInput/FPMarginF") # [Fuel,ES,Area,Year] Refinery/Distributor Margin ($/$)
  FPPolTaxF::VariableArray{4} = ReadDisk(db, "SOutput/FPPolTaxF") # [Fuel,ES,Area,Year] Pollution Tax (Real $/mmBtu)
  FPSMF::VariableArray{4} = ReadDisk(db, "SInput/FPSMF") # [Fuel,ES,Area,Year] Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db, "SInput/FPTaxF") # [Fuel,ES,Area,Year] Fuel Tax (Real $/mmBtu)
  FPTech::VariableArray{4} = ReadDisk(db, "$Outpt/FPTech") # [Tech,EC,Area,Year] Fuel Price excluding Emission Costs ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") # [Nation,Year] Inflation Index
  MoneyUnitDS::Array{String} = ReadDisk(db, "MInput/MoneyUnitDS") # [Area] Descriptor for Monetary Units
  PCost::VariableArray{5} = ReadDisk(db, "$Outpt/PCost") # [FuelEP,EC,Poll,Area,Year] Permit Cost ($/Tonne)
  PCostExo::VariableArray{5} = ReadDisk(db, "$Input/PCostExo") # [FuelEP,EC,Poll,Area,Year] Marginal Exogenous Permit Cost (Real $/Tonnes)
  PCostTech::VariableArray{4} = ReadDisk(db, "$Outpt/PCostTech") # [Tech,EC,Area,Year] Permit Cost ($/mmBtu)
  PE::VariableArray{3} = ReadDisk(db, "SOutput/PE") # [ECC,Area,Year] Price of Electricity ($/MWh)
  PolConv::VariableArray{1} = ReadDisk(db, "SInput/PolConv") # [Poll] Greenhouse Gas Conversion (eCO2 Tonnes/Tonnes)
  PolMarginal::VariableArray{5} = ReadDisk(db, "$Outpt/PolMarginal") # [FuelEP,EC,Poll,Area,Year] Marginal Emissions (Tonnes/Yr)

  FuelEPSwitch::VariableArray{1} = zeros(Float32,length(FuelEP))
  ZZZ::VariableArray{1} = zeros(Float32,length(Year))

end

function FuelPricesTech_DtaRun(data, tech, ec, ecc, area, nation, es)
  (; Area, AreaDS, Areas, CDTime, CDYear, Nation, NationDS, Nations,
    Fuel, FuelDS, Fuels,  ECC, ECCDS, ECCs, Year, YearDS, Years,
    FuelEP, FuelEPDS, FuelEPs,  Tech, TechDS, Techs, EC, ECDS, ECs,
    Enduse, EnduseDS, Enduses,  ES, ESDS, ESs, Poll, PollDS, Polls) = data
  (; ANMap, CoverageCFS, DmdFEPTech, DmdFuelTech, DmFrac, ECFP, ECFPFuel, ENPN, EuDem,
    ExchangeRate,  ExpCP, FEPCP, FFPMap, FPBaseF, FPCFS, FPCFSFuel, FPCFSNet, FPCFSObligated, FPCFSTech,
    FPCP,  FPDChgF, FPEC, FPECC, FPECCCFS, FPECCCFSCP, FPECCCFSCPNet, FPECCCFSNet, FPECCCP, FPECCCPNet,
    FPF,  FPMarginF, FPPolTaxF, FPSMF, FPTaxF, FPTech, FuelEPSwitch, Inflation, InflationNation, MoneyUnitDS,
    PE,  PCost, PCostExo, PCostTech, PolConv,PolMarginal,ZZZ,SceName) = data

  year = collect(Yr(1990):Yr(2050))
  years = collect(Yr(1990):Yr(2050)) 

  iob = IOBuffer()
  println(iob, " ")
  println(iob, "$SceName; is the scenario name. \n")
  println(iob, "This is the Price Output summary \n")
  println(iob, "Year;;    ", join(Year[year], ";    "))
  println(iob, " ")
  
  #
  # Top of output loops through single EC for all Fuels
  #
  polls=Select(Poll,["CO2","CH4","N2O","HFC","PFC","SF6"])

  enduse1=1
  
  fuels = findall(DmFrac[enduse1,:,tech,ec,area,Yr(2030)] .> 0)
  fuelfail=false
  if isempty(fuels)
    fuels=collect(Select(Fuel))
    fuelfail=true
  end
  fuels_order = fuels[sortperm(DmFrac[enduse1,fuels,tech,ec,area,Yr(2030)], rev = true)]


  @. FuelEPSwitch = 0.0
  FuelCount=1.0
  fuelepfail=false
  for fuel in fuels_order
    fueleps=findall(FFPMap[:,fuel] .== 1)
    if !isempty(fueleps)
      fuelep=first(fueleps)
    else
      fuelep=1
      fuelepfail=true
    end
    FuelEPSwitch[fuelep] = FuelCount
    FuelCount=FuelCount+1
  end

  fueleps = findall(FuelEPSwitch[:] .> 0)
  fueleps_order = fueleps[sortperm(FuelEPSwitch[fueleps])]

  

  if (fuelfail == false) && (fuelepfail == false)
    println(iob,"*** ",TechDS[tech]," Tech Fuels ***\n")
  elseif (fuelfail == true) && (fuelepfail == false)
    println(iob, "*** ",TechDS[tech]," Tech Fuels *** - Fuel Selection failed \n")
  elseif (fuelfail == false) && (fuelepfail == true)
    println(iob, "*** ",TechDS[tech]," Tech Fuels *** - FuelEP Selection failed \n")
  else
    println(iob, "*** ",TechDS[tech]," Tech Fuels *** - Fuel and FuelEP Selection failed \n")
  end



  # # ShowPrices

  print(iob,AreaDS[area]," ",ECDS[ec]," ",TechDS[tech]," Energy Demands (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuel in fuels_order
    print(iob,"DmdFuelTech;",FuelDS[fuel])
    for year in years
      ZZZ[year]=sum(DmdFuelTech[enduse,fuel,tech,ec,area,year] for enduse in Enduses)
      print(iob,";",@sprintf("%12.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," Energy Demands (TBtu/Yr);;    ", join(Year[year], ";    "))
  for fuelep in fueleps_order
    ZZZ[year]=sum(EuDem[enduse,fuelep,ec,area,year] for enduse in Enduses)
    println(iob,"EuDem;",FuelEPDS[fuelep],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
    end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," ",TechDS[tech]," Energy Demands (TBtu/Yr);;    ", join(Year[year], ";    "))
  for fuelep in fueleps_order
    ZZZ[year]=DmdFEPTech[fuelep,tech,ec,area,year]
    println(iob,"DmdFEPTech;",FuelEPDS[fuelep],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," eCO2 Marginal Emissions (Tonnes/Yr);;    ", join(Year[year], ";    "))
  for fuelep in fueleps_order
    ZZZ[year]=sum(PolMarginal[fuelep,ec,poll,area,year]*PolConv[poll] for poll in polls)
    println(iob,"PolMarginal;",FuelEPDS[fuelep],";",
      join([@sprintf("%.0f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," ",TechDS[tech]," Emission Expenditures (\$M/Yr);;    ", join(Year[year], ";    "))
  for year in years
    ZZZ[year]=ExpCP[tech,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
  end
  println(iob,"ExpCP;",TechDS[tech],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))

  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," eCO2 Permit Cost($CDTime ",MoneyUnitDS[area],"/Tonne);;    ", join(Year[year], ";    "))
  for fuelep in fueleps_order
    for year in years
      @finite_math ZZZ[year]=sum(PCost[fuelep,ec,poll,area,year]*PolMarginal[fuelep,ec,poll,area,year]*PolConv[poll] for poll in polls)/
        sum(PolMarginal[fuelep,ec,poll,area,year]*PolConv[poll] for poll in polls)/
        Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"PCost;",FuelEPDS[fuelep],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," Exogenous eCO2 Permit Cost($CDTime ",MoneyUnitDS[area],"/Tonne);;    ", join(Year[year], ";    "))
  for fuelep in fueleps_order
    for year in years
      @finite_math ZZZ[year]=sum(PCostExo[fuelep,ec,poll,area,year]*PolMarginal[fuelep,ec,poll,area,year]*PolConv[poll] for poll in polls)/
           sum(PolMarginal[fuelep,ec,poll,area,year]*PolConv[poll] for poll in polls)
    end
    println(iob, "PCostExo;",FuelEPDS[fuelep],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," Exogenous eCO2 Permit Cost($CDTime ",MoneyUnitDS[area],"/Tonne);;    ", join(Year[year], ";    "))
  for fuelep in fueleps_order
    for year in years
      ZZZ[year]=FEPCP[fuelep,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"FEPCP;",FuelEPDS[fuelep],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," ",TechDS[tech]," Permit Cost($CDTime ",MoneyUnitDS[area],"/Tonne);;    ", join(Year[year], ";    "))
  for year in years
    ZZZ[year]=PCostTech[tech,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
  end
  println(iob,"PCostTech;",TechDS[tech],";",
    join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," Carbon Price before OBA ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=FPCP[fuel,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"FPCP;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," CFS Price ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=FPCFS[fuel,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"FPCFS;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ESDS[es]," CFS Price ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=FPCFSFuel[fuel,es,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"FPCFSFuel;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," Coverage for CFS (1=Covered);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=CoverageCFS[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"CoverageCFS;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," CFS Price for Obligated Sectors ($CDTime ",MoneyUnitDS[area],"/Tonne);;    ", join(Year[year], ";    "))
  for year in years
    ZZZ[year]=FPCFSObligated[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
  end
  println(iob,"FPCFSObligated;",ECCDS[ecc],";",
     join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  println(iob)
  println(iob,AreaDS[area]," ",ECDS[ec]," Net CFS Price ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=FPCFSNet[fuel,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"FPCFSNet;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," ",TechDS[tech]," CFS Price ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for year in years
    ZZZ[year]=FPCFSTech[tech,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
  end
  println(iob,"FPCFSTech;",TechDS[tech],";",
    join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," Fuel Prices excluding Emission Costs ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=FPEC[fuel,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"FPEC;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," ",TechDS[tech]," Fuel Price w/o Emission Charges ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for year in years
    ZZZ[year]=FPTech[tech,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
  end
  println(iob,"FPTech;",TechDS[tech],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  println(iob)

  println(iob,AreaDS[area]," ",ESDS[es]," Fuel Price w/o Emission Charges ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=FPF[fuel,es,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"FPF;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," Fuel Price w/CFS Price ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    for year in years
      ZZZ[year]=ECFPFuel[fuel,ec,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    end
    println(iob,"ECFPFuel;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  println(iob,AreaDS[area]," ",ECDS[ec]," ",TechDS[tech]," Weighed Average Fuel Price w/CFS Price ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  #TODOJulia Jeff, What should the fuel selection be?
  fuel=first(fuels_order)
  for year in years
    @finite_math ZZZ[year]=sum(ECFP[enduse,tech,ec,area,year]*DmdFuelTech[enduse,fuel,tech,ec,area,year] for enduse in Enduses)/
      sum(DmdFuelTech[enduse,fuel,tech,ec,area,year] for enduse in Enduses)/
      Inflation[area,year]*Inflation[area,CDYear]
  end
  println(iob,"ECFP;",TechDS[tech],";",
    join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  println(iob)

  println(iob,AreaDS[area]," Wholesale Fuel Prices ($CDTime ",MoneyUnitDS[area],"/mmBtu);;    ", join(Year[year], ";    "))
  for fuel in fuels_order
    ZZZ[year]=ENPN[fuel,nation,year]*Inflation[area,CDYear]
    println(iob,"ENPN;",FuelDS[fuel],";",
      join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))
  end
  println(iob)

  # ShowRelatedVariables

  println(iob,AreaDS[area]," Inflation (\$/Real \$);;    ", join(Year[year], ";    "))
  ZZZ[year]=Inflation[area,year]
  println(iob,"Inflation;",AreaDS[area],";",
    join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))

  println(iob)
  *
  println(iob,AreaDS[area]," Exchange Rate (Local\$/US\$);;    ", join(Year[year], ";    "))
  ZZZ[year]=ExchangeRate[area,year]
  println(iob,"ExchangeRate;Exchange Rate",";",
    join([@sprintf("%12.4f", x) for x in ZZZ[year]], ";"))

  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "FuelPricesTech-$(EC[ec])-$(Area[area])-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function FuelPricesTech_DtaControl(db)
  @info "FuelPricesTech_DtaControl"
  data = FuelPricesTechData(; db)
  (; ANMap, AreaDS, EC, ECC, ECCs, ECDS, ES, Nation, Tech) = data

  es=Select(ES,"Industrial")
  ecs=Select(EC,["PulpPaperMills","Petroleum","Petrochemicals","IronSteel","SAGDOilSands"])
  tech=Select(Tech,"Gas")
  CN=Select(Nation,"CN")
  areas=findall(ANMap[:,CN] .== 1)
  for area in areas,ec in ecs
    ecc=Select(ECC,EC[ec])
    FuelPricesTech_DtaRun(data, tech, ec, ecc, area, CN, es)
  end

end


if abspath(PROGRAM_FILE) == @__FILE__
FuelPricesTech_DtaControl(DB)
end
