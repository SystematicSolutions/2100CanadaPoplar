#
# FuelPrices.jl
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

Base.@kwdef struct FuelPricesData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation]  Map between Area and Nation
  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  FPBaseF::VariableArray{4} = ReadDisk(db, "SOutput/FPBaseF") #[Fuel,ES,Area,Year]  Delivered Fuel Price without Taxes ($/mmBtu)
  FPDChgF::VariableArray{4} = ReadDisk(db, "SCalDB/FPDChgF") #[Fuel,ES,Area,Year]  Fuel Delivery Charge (Real $/mmBtu)
  FPCFSFuel::VariableArray{4} = ReadDisk(db, "SOutput/FPCFSFuel") #[Fuel,ES,Area,Year]  CFS Price ($/mmBtu)
  FPECC::VariableArray{4} = ReadDisk(db, "SOutput/FPECC") #[Fuel,ECC,Area,Year]  Fuel Prices excluding Emission Costs ($/mmBtu)
  FPECCCFS::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFS") #[Fuel,ECC,Area,Year]  Fuel Prices w/CFS Price ($/mmBtu)
  FPECCCFSCP::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFSCP") #[Fuel,ECC,Area,Year]  Fuel Prices w/CFS and Carbon Price ($/mmBtu)
  FPECCCFSCPNet::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFSCPNet") #[Fuel,ECC,Area,Year]  Fuel Prices w/CFS and Net Carbon Price ($/mmBtu)
  FPECCCFSNet::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCFSNet") #[Fuel,ECC,Area,Year]  Incremental CFS Charge ($/mmBtu)
  FPECCOGEC::VariableArray{4} = ReadDisk(db,"SOutput/FPECCOGEC") # [Fuel,ECC,Area,Year] Incremental OGEC Price ($/mmBtu)
  FPECCCP::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCP") #[Fuel,ECC,Area,Year]  Carbon Price before OBA ($/mmBtu)
  FPECCCPNet::VariableArray{4} = ReadDisk(db, "SOutput/FPECCCPNet") #[Fuel,ECC,Area,Year]  Net Carbon Price after OBA ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db, "SOutput/FPF") #[Fuel,ES,Area,Year]  Fuel Price ($/mmBtu)
  FPMarginF::VariableArray{4} = ReadDisk(db, "SInput/FPMarginF") #[Fuel,ES,Area,Year]  Refinery/Distributor Margin ($/$)
  FPPolTaxF::VariableArray{4} = ReadDisk(db, "SOutput/FPPolTaxF") #[Fuel,ES,Area,Year]  Pollution Tax (Real $/mmBtu)
  FPSMF::VariableArray{4} = ReadDisk(db, "SInput/FPSMF") #[Fuel,ES,Area,Year]  Energy Sales Tax ($/$)
  FPTaxF::VariableArray{4} = ReadDisk(db, "SInput/FPTaxF") #[Fuel,ES,Area,Year]  Fuel Tax (Real $/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") #[Area,Year]  Inflation Index
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") #[Nation,Year]  Inflation Index
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  SecMap::VariableArray{1} = ReadDisk(db, "SInput/SecMap") #[ECC]  Map Between the Sector and ECC Sets

  #
  # Scratch variables
  #
  FPSMFBtu::VariableArray{1} = zeros(Float32, length(Year))
  years = collect(Yr(1990):Final)
  ZZZ::VariableArray{1} = zeros(Float32, length(Year))
end

function ShowPrices(data::FuelPricesData,area,ecc,es,fuel,iob)
  (;AreaDS, ECCDS, FuelDS, Year) = data;
  (;CDTime, MoneyUnitDS, ZZZ, years, CDYear, InflationNation, ANMap) = data;
  (;ENPN, FPDChgF, FPBaseF, Inflation, FPMarginF, FPTaxF, FPPolTaxF, ) = data;
  (;FPECC,FPECCCFSNet,FPSMF,FPSMFBtu,FPF,FPECCOGEC) = data;
  (;FPECCCFS, FPECCCP, FPECCCPNet, FPECCCFSCP, FPECCCFSCPNet) = data;

  nation = only(Select(ANMap[area, :], .==(1)))

  print(iob,AreaDS[area]," ",ECCDS[ecc]," ", FuelDS[fuel]," Prices (",string(CDTime)," ",MoneyUnitDS[area],"/mmBtu);")
  for year in years 
    print(iob,";",Year[year]) 
  end
  println(iob)
  
  print(iob,"ENPN;Wholesale Fuel Price")
  for year in years
    ZZZ[year] = ENPN[fuel,nation,year]*InflationNation[nation,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"FPDChgF;Fuel Differential Charge")
  for year in years
    ZZZ[year] = FPDChgF[fuel,es,area,year]*InflationNation[nation,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"FPBaseF;Delivered Fuel Price w/o Taxes")
  for year in years
    ZZZ[year] = FPBaseF[fuel,es,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"FPMarginF;Refinery/Distributor Margin")
  for year in years
    ZZZ[year] = ENPN[fuel,nation,year]*FPMarginF[fuel,es,area,year]*
    InflationNation[nation,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"FPTaxF;Excise Tax")
  for year in years
    ZZZ[year]=FPTaxF[fuel,es,area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  
  print(iob,"FPPolTaxF;Pollution Tax")
  for year in years
    ZZZ[year]=FPPolTaxF[fuel,es,area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Calculate FPSMF output in $/mmBtu
  #
  for year in years
    FPSMFBtu[year]=(ENPN[fuel,nation,year]*(1+FPMarginF[fuel,es,area,year])+
      FPDChgF[fuel,es,area,year]+FPTaxF[fuel,es,area,year]+FPPolTaxF[fuel,es,area,year])*
      InflationNation[nation,year]*FPSMF[fuel,es,area,year]
  end

  print(iob,"FPSMF;Sales Tax")
  for year in years
    ZZZ[year]=FPSMFBtu[year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPF;Fuel Price w/o Emission Charges")
  for year in years
    ZZZ[year]=FPF[fuel,es,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECC;Fuel Price w/o Emission Charges")
  for year in years
    ZZZ[year]=FPECC[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECCCFSNet;CFS Incremental Charges")
  for year in years
    ZZZ[year]=FPECCCFSNet[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECCCFS;Fuel Price w/CFS")
  for year in years
    ZZZ[year]=FPECCCFS[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECCOGEC;OGEC Fuel Price")
  for year in years
    ZZZ[year]=FPECCOGEC[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECCCP;Carbon Price")
  for year in years
    ZZZ[year]=FPECCCP[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECCCPNet;Net Carbon Price")
  for year in years
    ZZZ[year]=FPECCCPNet[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECCCFSCP;Fuel Price w/CFS and Carbon Price")
  for year in years
    ZZZ[year]=FPECCCFSCP[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]  
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)

  print(iob,"FPECCCFSCPNet;Fuel Price w/CFS and Net Carbon Price")
  for year in years
    ZZZ[year]=FPECCCFSCPNet[fuel,ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  return(iob)
end

function ShowRelatedVariables(data::FuelPricesData, area,iob)
  (; AreaDS, Year, Fuel, FuelDS, Nation, years) = data;
  (; Inflation, ExchangeRate, ENPN, InflationNation, ANMap, ZZZ) = data;
  (; FPECCCFSCPNet,CDYear) = data;
  
  nation = only(Select(ANMap[area, :], .==(1)))

  print(iob,AreaDS[area]," Inflation (Dollars/Real Dollar);")
  for year in years
    print(iob,";",Year[year]) 
  end
  println(iob)

  print(iob,"Inflation;",AreaDS[area])
  for year in years  
    ZZZ[year]=Inflation[area,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  print(iob,AreaDS[area]," Exchange Rate (Local Dollars/US Dollar);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  
  print(iob,"ExchangeRate;Exchange Rate")
  for year in years
    ZZZ[year]=ExchangeRate[area,year]
    print(iob,";",@sprintf("%.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)
  
  #
  fuels = Select(Fuel, ["NaturalGas","LightCrudeOil","HeavyCrudeOil","Coal","PetroCoke"])
  print(iob,AreaDS[area]," Wholesale Fuel Prices (Real Dollars/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuel in fuels
    print(iob,"ENPN;",FuelDS[fuel])
    for year in years
      ZZZ[year]=ENPN[fuel,nation,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end # do fuel
  println(iob)

  print(iob, AreaDS[area]," Wholesale Fuel Prices (Nominal Dollars/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuel in fuels
    print(iob,"ENPN;",FuelDS[fuel])
    for year in years
      ZZZ[year]=ENPN[fuel,nation,year]*Inflation[area,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))  
    end
    println(iob)
  end # do fuel
  println(iob)
  
  print(iob,AreaDS[area]," Wholesale Fuel Prices (Nominal US Dollars/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuel in fuels
    print(iob,"ENPN;",FuelDS[fuel])
    for year in years
      ZZZ[year]=ENPN[fuel,nation,year]*Inflation[area,year]/ExchangeRate[area,year]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end # do fuel
  println(iob)
  
  us = Select(Nation, "US")
  yr2019 = Select(Year, "2019")
  
  print(iob,AreaDS[area]," Wholesale Fuel Prices (2019 US Dollars/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuel in fuels
    print(iob,"ENPN;",FuelDS[fuel])
    for year in years
      ZZZ[year]=ENPN[fuel,nation,year]*Inflation[area,year]/ExchangeRate[area,year]/
      Inflation[area,year]*InflationNation[us, yr2019]
      print(iob,";",@sprintf("%.4f",ZZZ[year])) 
    end  
    println(iob)
  end # do fuel
  println(iob)
  return iob
end

function DtaRun(data::FuelPricesData, area, nation, es, ecc)
  (;db) = data;
  (;Area, Year, ECC, ES, Fuel, years, SecMap,SceName) = data;
  
  OUTFIL="FuelPrices-"*ES[es]*"-"*Area[area]*"-"*SceName*".dta"
  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; sheet name and scenario")
  println(iob, " ")
  println(iob, "This is the Price Output summary")
  println(iob, " ")  
  
  println(iob,"Year;",";",join(Year[years],";    "))
  println(iob)
  
  #
  # Top of output loops through single ECC for all Fuels
  #
  for fuel in Select(Fuel)
    iob = ShowPrices(data, area, ecc, es, fuel, iob)
  end
  if ES[es] == "Industrial"
    fuels = Select(Fuel, ["Electric", "NaturalGas", "Coal"])
  elseif ES[es] == "Transport"
    fuels = Select(Fuel, ["Electric","Gasoline","Diesel"])
  elseif ES[es] == "Biofuel" # Note, Biofuel is not an ES
    fuels = Select(Fuel, ["Electric","NaturalGas"])
  elseif ES[es] == "H2Prod" # Note, H2Prod is not an ES
    fuels = Select(Fuel, ["Electric","NaturalGas"])
  else
    fuels = Select(Fuel, ["Electric", "NaturalGas", "LPG"])
  end
  #
  # Bottom of file loops through all sectors for a couple fuels
  #
  eccs = Select(SecMap, .==(es))
  if length(ecc) > 0
    for ecc in eccs, fuel in fuels
      iob = ShowPrices(data, area, ecc, es, fuel,iob)
    end # do ecc
  end # do if
  #
  iob = ShowRelatedVariables(data, area,iob)
  #
  eccs = Select(ECC)
  fuels = Select(Fuel)

  open(joinpath(OutputFolder, OUTFIL), "w") do OUTFIL
    write(OUTFIL, String(take!(iob)))
  end
end

function DtaRunSupply(data, area, es, SceName)
  (;db) = data;
  (;Area, Year, ECC, ES, Fuel, years) = data;
  #
  OUTFIL="FuelPrices-Supply-"*Area[area]*"-"*SceName*".dta"
  
  iob = IOBuffer()
  
  println(iob, " ")
  println(iob, "$SceName; sheet name and scenario")
  println(iob, " ")
  println(iob, "This is the Price Output summary")
  println(iob, " ")  
  
  println(iob,"Year;",";",join(Year[years],";    "))
  println(iob)

  
  ecc = Select(ECC, "UtilityGen")
  # es = Select(ES, "Electric")
  
  for fuel in Select(Fuel)
    iob = ShowPrices(data, area, ecc, es, fuel,iob)
  end
  
  eccs = Select(ECC, ["H2Production", "BiofuelProduction"])
  fuels = Select(Fuel, ["Electric", "NaturalGas", "LPG"])
  
  for ecc in eccs, fuel in fuels
    # es = ECC[ecc] == "H2Production" ? Select(ES, "Gas") : Select(ES, "Misc") 
    iob = ShowPrices(data, area, ecc, es, fuel,iob)
  end
  
  open(joinpath(OutputFolder, OUTFIL), "w") do OUTFIL
    write(OUTFIL, String(take!(iob)))
  end

end

function FuelPrices_DtaControl(db)
  @info "FuelPrices_DtaControl"
  data = FuelPricesData(; db)
  (; db) = data;
  (; Area, ES, ECC, Nation) = data;
  (; ANMap) = data;
  
  nation = Select(Nation, "CN")
  areas = Select(Area)
  area_cn = Select(ANMap[areas, nation], .==(1))
  area_other = Select(Area, ["CA", "MX"])
  areas = union(area_cn, area_other)
  for a in areas
    n = only(Select(ANMap[a, :], .==(1)))
    DtaRun(data, a, n, Select(ES, "Residential"), Select(ECC, "SingleFamilyAttached"))
    DtaRun(data, a, n, Select(ES, "Commercial"), Select(ECC, "Offices"))
    DtaRun(data, a, n, Select(ES, "Industrial"), Select(ECC, "Food"))
    DtaRun(data, a, n, Select(ES, "Transport"), Select(ECC, "Passenger"))
    #
    # DtaRunSupply(data, a, Select(ES,"Transport"), SceName)
  end
end


if abspath(PROGRAM_FILE) == @__FILE__
FuelPrices_DtaControl(DB)
end

