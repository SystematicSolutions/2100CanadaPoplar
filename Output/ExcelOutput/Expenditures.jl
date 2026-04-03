#
# Expenditures.jl
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


Base.@kwdef struct ExpendituresData
  db::String

  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/Year")
  Years::Vector{Int} = collect(Select(Year))

  CDTime::Int = ReadDisk(db,"SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db,"SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  AreaPurchases::VariableArray{2} = ReadDisk(db, "EGOutput/AreaPurchases") # [Area,Year] Purchases from Areas in the same Country (GWh/Yr)
  AreaSales::VariableArray{2} = ReadDisk(db, "EGOutput/AreaSales") # [Area,Year] Sales to Areas in the same Country (GWh/Yr)
  CgFuelExpenditures::VariableArray{3} = ReadDisk(db,"SOutput/CgFuelExpenditures") # Cogeneration Fuel Expenditures (M$) [ECC,Area]
  CgInv::VariableArray{3} = ReadDisk(db,"SOutput/CgInv") #[ECC,Area,Year]  Cogeneration Investments (M$/Yr)
  CgPExp::VariableArray{3} = ReadDisk(db,"SOutput/CgPExp") #[ECC,Area,Year]  Cogeneration Emission Charges (M$/Yr)
  DemandCFS::VariableArray{4} = ReadDisk(db,"SOutput/DemandCFS") # [Fuel,ECC,Area,Year] Energy Demands for CFS (TBtu/Yr)
  DInv::VariableArray{3} = ReadDisk(db,"SOutput/DInv") # [ECC,Area,Year] Device Investments (M$/Yr)
  Driver::VariableArray{3} = ReadDisk(db,"MOutput/Driver") # [ECC,Area,Year] Economic Driver (Various Units)
  EUPExp::VariableArray{2} = ReadDisk(db,"SOutput/EUPExp") #[Area,Year]  Electric Utility Emission Charges (M$/Yr)
  ExpPurchases::VariableArray{2} = ReadDisk(db,"EGOutput/ExpPurchases") #[Area,Year]  Purchases from Areas in a different Country (GWh/Yr)
  ExpSales::VariableArray{2} = ReadDisk(db,"EGOutput/ExpSales") #[Area,Year]  Sales to Areas in a different Country (GWh/Yr)

  FlInv::VariableArray{3} = ReadDisk(db, "SOutput/FlInv") # [ECC,Area,Year] Flaring Reduction Investments (M$/Yr)
  FuelExpenditures::VariableArray{3} = ReadDisk(db, "SOutput/FuelExpenditures") # [ECC,Area,Year] Fuel Expenditures (M$)
  FPECCCFSNet::VariableArray{4} = ReadDisk(db,"SOutput/FPECCCFSNet") # [Fuel,ECC,Area,Year] Incremental CFS Price ($/mmBtu)
  FuInv::VariableArray{3} = ReadDisk(db, "SOutput/FuInv") # [ECC,Area,Year] Other Fugitives Reduction Investments (M$/Yr)
  FuOMExp::VariableArray{3} = ReadDisk(db, "SOutput/FuOMExp") # [ECC,Area,Year] Other Fugitives Reduction O&M Expenses (M$/Yr)

  HMPrA::VariableArray{2} = ReadDisk(db, "EOutput/HMPrA") # [Area,Year] Average Spot Market Price ($/MWh)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)

  MEInv::VariableArray{3} = ReadDisk(db, "SOutput/MEInv") # [ECC,Area,Year] Non Energy Reduction Investments (M$/Yr)
  MEOMExp::VariableArray{3} = ReadDisk(db, "SOutput/MEOMExp") # [ECC,Area,Year] Non Energy Reduction O&M Expenses(M$/Yr)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units

  OMExp::VariableArray{3} = ReadDisk(db, "SOutput/OMExp") # [ECC,Area,Year] O&M Expenditures (M$)
  PCA::VariableArray{4} = ReadDisk(db, "MOutput/PCA") # [Age,ECC,Area,Year] Production Capacity Additions (M$/Yr/Yr)
  PInv::VariableArray{3} = ReadDisk(db, "SOutput/PInv") # [ECC,Area,Year] Process Investments (M$/Yr)
  PExp::VariableArray{4} = ReadDisk(db,"SOutput/PExp") # [ECC,Poll,Area,Year] Permits Expenditures (M$/Yr)
  PExpExo::VariableArray{4} = ReadDisk(db, "SInput/PExpExo") # [ECC,Poll,Area,Year] Exogenous Permits Expenditures (M$/Year)
  PRExp::VariableArray{4} = ReadDisk(db, "SOutput/PRExp") # [ECC,Poll,Area,Year] Pollution Reduction Private Expenses (M$/Yr)
  RnCosts::VariableArray{2} = ReadDisk(db, "EOutput/RnCosts") #[Area,Year]  Renewable RECs Costs (M$/Yr)

  SqInv::VariableArray{3} = ReadDisk(db, "SOutput/SqInv") # [ECC,Area,Year] Sequestering Investments (M$/Yr)
  SqOMExp::VariableArray{3} = ReadDisk(db, "SOutput/SqOMExp") # [ECC,Area,Year] Sequestering O&M Expenses (M$/Yr)
  TaxExp::VariableArray{4} = ReadDisk(db, "SOutput/TaxExp") # [Fuel,ECC,Area,Year] Tax Expenditure (M$)
  TDInv::VariableArray{2} = ReadDisk(db, "SOutput/TDInv") # [Area,Year] Electric Transmission and Distribution Investments (M$/Yr)
  VnInv::VariableArray{3} = ReadDisk(db, "SOutput/VnInv") # [ECC,Area,Year] Venting Reduction Investments (M$/Yr)
  VnOMExp::VariableArray{3} = ReadDisk(db, "SOutput/VnOMExp") # [ECC,Area,Year] Venting Reduction O&M Expenses (M$/Yr)

  # Scratch Variables
  CFRExp::VariableArray{4} = zeros(Float32,length(Fuel),length(ECC),length(Area),length(Year)) # Expenditures Related to CFR ($M/Yr)
  Expend::VariableArray{3} = zeros(Float32,length(ECC),length(Area),length(Year)) # Expenditures (M$/Yr)
  ExportsRevenue::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # Revenues from Exports (M$/Yr)
  ImportsExp::VariableArray{2} = zeros(Float32,length(Area),length(Year)) # Expenditures for Imports (M$/Yr)
  ZZZ = zeros(Float32,length(Year))
end

function CalcExpenditures(data,areas)
  (; ECC,ECCs,Fuels,Polls,Years) = data
  (; AreaPurchases,AreaSales,CgInv,DemandCFS,DInv,ExpPurchases,ExpSales) = data
  (; FlInv,FuelExpenditures,FPECCCFSNet,FuInv,FuOMExp,HMPrA,MEInv,MEOMExp,OMExp,PExp) = data
  (; PExpExo,PInv,PRExp,RnCosts,SqInv,SqOMExp,TaxExp,TDInv,VnInv,VnOMExp) = data
  (; CFRExp,Expend,ExportsRevenue,ImportsExp) = data

  for year in Years, area in areas, ecc in ECCs
    Expend[ecc,area,year]=PInv[ecc,area,year]+
        DInv[ecc,area,year]+
        CgInv[ecc,area,year]+
        SqInv[ecc,area,year]+
        VnInv[ecc,area,year]+
        FlInv[ecc,area,year]+
        FuInv[ecc,area,year]+
        MEInv[ecc,area,year]+
        sum(PRExp[ecc,poll,area,year] for poll in Polls)+
        FuelExpenditures[ecc,area,year]+
        OMExp[ecc,area,year]+
        SqOMExp[ecc,area,year]+
        VnOMExp[ecc,area,year]+
        FuOMExp[ecc,area,year]+
        MEOMExp[ecc,area,year]+
        sum(PExp[ecc,poll,area,year]+PExpExo[ecc,poll,area,year] for poll in Polls)+
        sum(TaxExp[fuel,ecc,area,year] for fuel in Fuels)
  end
  ecc=Select(ECC,"UtilityGen")
  for year in Years, area in areas
    ImportsExp[area,year]=(AreaPurchases[area,year]+ExpPurchases[area,year])*
        HMPrA[area,year]/1000
    ExportsRevenue[area,year]=(AreaSales[area,year]+ExpSales[area,year])*
        HMPrA[area,year]/1000
    Expend[ecc,area,year]=Expend[ecc,area,year]+TDInv[area,year]+
        ImportsExp[area,year]-ExportsRevenue[area,year]+
        RnCosts[area,year]
  end

  for year in Years, area in areas, ecc in ECCs, fuel in Fuels
    CFRExp[fuel,ecc,area,year]=FPECCCFSNet[fuel,ecc,area,year]*DemandCFS[fuel,ecc,area,year]
  end

  for year in Years, area in areas, ecc in ECCs
    Expend[ecc,area,year]=Expend[ecc,area,year]+sum(CFRExp[fuel,ecc,area,year] for fuel in Fuels)
  end
 
end

function Expenditures_DtaRun(data,TitleKey,TitleName,areas)
  (; Age,Area,AreaDS,ECC,ECCDS,ECCs,Fuel,FuelDS,Fuels,Poll,PollDS,Polls,Year) = data
  (; CDTime,CDYear,SceName,AreaPurchases,AreaSales,CgFuelExpenditures) = data
  (; CgInv,CgPExp,DemandCFS,DInv,Driver,EUPExp) = data
  (; ExpPurchases,ExpSales,FlInv,FuelExpenditures,FPECCCFSNet) = data
  (; FuInv,FuOMExp,HMPrA,Inflation,MEInv,MEOMExp,MoneyUnitDS) = data
  (; OMExp,PCA,PInv,PExp,PExpExo,PRExp,RnCosts,SqInv,SqOMExp) = data
  (; TaxExp,TDInv,VnInv,VnOMExp) = data
  (; CFRExp,Expend,ExportsRevenue,ImportsExp,ZZZ) = data

  iob = IOBuffer()
  
  area_single = first(areas)

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob,"$TitleName; is the area being output.")
  println(iob,"This is the Expenditures Summary.")
  println(iob)

  CalcExpenditures(data,areas)

  years = collect(Yr(1990):Final)
  println(iob,"Year;",";    ",join(Year[years],";"))
  println(iob)

  eccs1=Select(ECC,(from="SingleFamilyDetached",to="CommercialOffRoad"))
  eccs2=Select(ECC,!=("ForeignPassenger"))
  eccs3=Select(ECC,!=("ForeignFreight"))
  eccs=intersect(eccs1,eccs2,eccs3)

  #
  # Secondary Energy Expenditures
  #
  # Show Summary
  #
  print(iob,"$TitleName Secondary Energy Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  #
  print(iob,"Expend;Expenditures")
  for year in years
    ZZZ[year] = sum(Expend[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"PInv;Process Investments")
  for year in years
    ZZZ[year] = sum(PInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"DInv;Device Investments")
  for year in years
    ZZZ[year] = sum(DInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"CgInv;Cogeneration Investments")
  for year in years
    ZZZ[year] = sum(CgInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"SqInv;Sequestering Investments")
  for year in years
    ZZZ[year] = sum(SqInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"VnInv;Venting Reduction Investments")
  for year in years
    ZZZ[year] = sum(VnInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"FlInv;Flaring Reduction Investments")
  for year in years
    ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"FuInv;Other Fugitives Reduction Investments")
  for year in years
    ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"MEInv;Non Energy Reduction Investments")
  for year in years
    ZZZ[year] = sum(MEInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"PRExp;Pollution Reduction Expenditures")
  for year in years
    ZZZ[year] = sum(PRExp[ecc,poll,area,year]/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, poll in Polls, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"FuelExpenditures;Fuel Expenses")
  for year in years
    ZZZ[year] = sum(FuelExpenditures[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"OMExp;O&M Expenses")
  for year in years
    ZZZ[year] = sum(OMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"SqOMExp;Sequestering O&M Expenses")
  for year in years
    ZZZ[year] = sum(SqOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"VnOMExp;Venting Reduction O&M Expenses")
  for year in years
    ZZZ[year] = sum(VnOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"FuOMExp;Other Fugitives Reduction O&M Expenses")
  for year in years
    ZZZ[year] = sum(FuOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"MEOMExp;Non Energy Reduction O&M Expenses")
  for year in years
    ZZZ[year] = sum(MEOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"PExp;Emission Permit Expenses")
  for year in years
    ZZZ[year] = sum((PExp[ecc,poll,area,year]+PExpExo[ecc,poll,area,year])/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, poll in Polls, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"TaxExp;Energy Tax Expenses")
  for year in years
    ZZZ[year] = sum(TaxExp[fuel,ecc,area,year]/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, ecc in eccs, fuel in Fuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  #
  print(iob,"CFRExp;Clean Fuel Regulation Expenses")
  for year in years
    ZZZ[year] = sum(CFRExp[fuel,ecc,area,year]/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, ecc in eccs, fuel in Fuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  # ShowExpenditures
  print(iob,"$TitleName Secondary Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"Expend;Total")
  for year in years
    ZZZ[year] = sum(Expend[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"Expend;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(Expend[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowPInv
  print(iob,"$TitleName Process Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PInv;Total")
  for year in years
    ZZZ[year] = sum(PInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"PInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(PInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowDInv
  print(iob,"$TitleName Device Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"DInv;Total")
  for year in years
    ZZZ[year] = sum(DInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"DInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(DInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowCgInv
  print(iob,"$TitleName Self Generation Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
    print(iob,"CgInv;Total")
  for year in years
    ZZZ[year] = sum(CgInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"CgInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(CgInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowSqInv
  print(iob,"$TitleName Sequestering Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"SqInv;Total")
  for year in years
    ZZZ[year] = sum(SqInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"SqInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(SqInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowVnInv
  print(iob,"$TitleName Venting Reduction Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"VnInv;Total")
  for year in years
    ZZZ[year] = sum(VnInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"VnInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(VnInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowFlInv
  print(iob,"$TitleName Flaring Reduction Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"FlInv,Total")
  for year in years
    ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"FlInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowFuInv
  print(iob,"$TitleName Other Fugitives Reduction Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"FuInv;Total")
  for year in years
    ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"FuInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(FuInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowMEInv
  print(iob,"$TitleName Non Energy Reduction Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"MEInv;Total")
  for year in years
    ZZZ[year] = sum(MEInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"MEInv;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(MEInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowPRExp
  print(iob,"$TitleName Pollution Reduction Investments (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PRExp;Total")
  for year in years
    ZZZ[year] = sum(PRExp[ecc,poll,area,year]/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, poll in Polls, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"PRExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(PRExp[ecc,poll,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, poll in Polls)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowFuel
  print(iob,"$TitleName Fuel Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"FuelExpenditures;Total")
  for year in years
    ZZZ[year] = sum(FuelExpenditures[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"FuelExpenditures;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(FuelExpenditures[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowOM
  print(iob,"$TitleName O&M Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"OMExp;Total")
  for year in years
    ZZZ[year] = sum(OMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"OMExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(OMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowSqOM
  print(iob,"$TitleName Sequestering O&M Expenses (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"SqOMExp;Total")
  for year in years
    ZZZ[year] = sum(SqOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"SqOMExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(SqOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowVnOM
  print(iob,"$TitleName Venting Reduction O&M Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"VnOMExp;Total")
  for year in years
    ZZZ[year] = sum(VnOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"VnOMExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(VnOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowMEOM
  print(iob,"$TitleName Non Energy Reduction O&M Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"MEOMExp;Total")
  for year in years
    ZZZ[year] = sum(MEOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"MEOMExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(MEOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowFuOM - Not Shown

  #
  # ShowPExp
  #
  print(iob,"$TitleName Permits Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"PExp;Total")
  for year in years
    ZZZ[year] = sum((PExp[ecc,poll,area,year]+PExpExo[ecc,poll,area,year])/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, poll in Polls, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"PExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum((PExp[ecc,poll,area,year]+PExpExo[ecc,poll,area,year])/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, poll in Polls)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowEUPExp
  print(iob,"$TitleName Electric Utility Permit Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"EUPExp;ElectricUtility")
  for year in years
    ZZZ[year] = sum(EUPExp[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  # ShowTaxExp
  print(iob,"$TitleName Tax Expenditure (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"TaxExp;Total")
  for year in years
    ZZZ[year] = sum(TaxExp[fuel,ecc,area,year]/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, ecc in eccs, fuel in Fuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"TaxExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(TaxExp[fuel,ecc,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, fuel in Fuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowCFRExp
  print(iob,"$TitleName Clean Fuel Regulation Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CFRExp;Total")
  for year in years
    ZZZ[year] = sum(CFRExp[fuel,ecc,area,year]/Inflation[area,year]*
        Inflation[area,CDYear] for area in areas, ecc in eccs, fuel in Fuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"CFRExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(CFRExp[fuel,ecc,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, fuel in Fuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowCgFuel
  print(iob,"$TitleName Cogeneration Fuel Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgFuelExpenditures;Total")
  for year in years
    ZZZ[year] = sum(CgFuelExpenditures[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"CgFuelExpenditures;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(CgFuelExpenditures[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  # ShowCgPExp
  print(iob,"$TitleName Cogeneration Permit Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob,"CgPExp;Total")
  for year in years
    ZZZ[year] = sum(CgPExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob,"CgPExp;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(CgPExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  # ShowDriver
  #
  # Economic Driver
  #
  print(iob,"$TitleName Economic Driver (Various Units/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob,"Driver;$(ECCDS[ecc])")
    for year in years
      ZZZ[year] = sum(Driver[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  #
  # Production Capacity Additions
  #
  print(iob,"$TitleName Production Capacity Additions (Various Units/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for ecc in eccs
    print(iob,"PCA;$(ECCDS[ecc])")
    new=Select(Age,"New")
    for year in years
      ZZZ[year] = sum(PCA[new,ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Supply Sectors
  #
  eccs=Select(ECC,["UtilityGen","H2Production"])
  for ecc in eccs
    #
    # Show Summary
    #
    print(iob,"$TitleName $(ECCDS[ecc]) Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    #
    print(iob,"Expend;Expenditures")
    for year in years
      ZZZ[year] = sum(Expend[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PInv;Process Investments")
    for year in years
      ZZZ[year] = sum(PInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"DInv;Device Investments")
    for year in years
      ZZZ[year] = sum(DInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"CgInv;Cogeneration Investments")
    for year in years
      ZZZ[year] = sum(CgInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"SqInv;Sequestering Investments")
    for year in years
      ZZZ[year] = sum(SqInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"VnInv;Venting Reduction Investments")
    for year in years
      ZZZ[year] = sum(VnInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FlInv;Flaring Reduction Investments")
    for year in years
      ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FuInv;Other Fugitives Reduction Investments")
    for year in years
      ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"MEInv;Non Energy Reduction Investments")
    for year in years
      ZZZ[year] = sum(MEInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PRExp;Pollution Reduction Investments")
    for year in years
      ZZZ[year] = sum(PRExp[ecc,poll,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, poll in Polls)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FuelExpenditures;Fuel Expenses")
    for year in years
      ZZZ[year] = sum(FuelExpenditures[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"OMExp;O&M Expenses")
    for year in years
      ZZZ[year] = sum(OMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"SqOMExp;Sequestering O&M Expenses")
    for year in years
      ZZZ[year] = sum(SqOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"VnOMExp;Venting Reduction O&M Expenses")
    for year in years
      ZZZ[year] = sum(VnOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FuOMExp;Other Fugitives Reduction O&M Expenses")
    for year in years
      ZZZ[year] = sum(FuOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"MEOMExp;Non Energy Reduction O&M Expenses")
    for year in years
      ZZZ[year] = sum(MEOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PExp;Emission Permit Expenses")
    for year in years
      ZZZ[year] = sum((PExp[ecc,poll,area,year]+PExpExo[ecc,poll,area,year])/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, poll in Polls)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"TaxExp;Energy Tax Expenses")
    for year in years
      ZZZ[year] = sum(TaxExp[fuel,ecc,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"CFRExp;Clean Fuel Regulation Expenses")
    for year in years
      ZZZ[year] = sum(CFRExp[fuel,ecc,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    if (ECC[ecc] == "UtilityGen")
      print(iob,"TDInv;Transmission and Distribution Investments)")
      for year in years
        ZZZ[year] = sum(TDInv[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      print(iob,"ImportsExp;Import Expenses")
      for year in years
        ZZZ[year] = sum(ImportsExp[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      print(iob,"ExportsRevenue;Export Revenue")
      for year in years
        ZZZ[year] = sum(ExportsRevenue[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      print(iob,"RnCosts;Renewable REC Costs")
      for year in years
        ZZZ[year] = sum(RnCosts[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  # All Sectors
  #
  for ecc in ECCs
    #
    # Show Summary
    #
    print(iob,"$TitleName $(ECCDS[ecc]) Expenditures (Millions $CDTime $(MoneyUnitDS[area_single])/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    #
    print(iob,"Expend;Expenditures")
    for year in years
      ZZZ[year] = sum(Expend[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PInv;Process Investments")
    for year in years
      ZZZ[year] = sum(PInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"DInv;Device Investments")
    for year in years
      ZZZ[year] = sum(DInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"CgInv;Cogeneration Investments")
    for year in years
      ZZZ[year] = sum(CgInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"SqInv;Sequestering Investments")
    for year in years
      ZZZ[year] = sum(SqInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"VnInv;Venting Reduction Investments")
    for year in years
      ZZZ[year] = sum(VnInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FlInv;Flaring Reduction Investments")
    for year in years
      ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FuInv;Other Fugitives Reduction Investments")
    for year in years
      ZZZ[year] = sum(FlInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"MEInv;Non Energy Reduction Investments")
    for year in years
      ZZZ[year] = sum(MEInv[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PRExp;Pollution Reduction Investments")
    for year in years
      ZZZ[year] = sum(PRExp[ecc,poll,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, poll in Polls)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FuelExpenditures;Fuel Expenses")
    for year in years
      ZZZ[year] = sum(FuelExpenditures[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"OMExp;O&M Expenses")
    for year in years
      ZZZ[year] = sum(OMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"SqOMExp;Sequestering O&M Expenses")
    for year in years
      ZZZ[year] = sum(SqOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"VnOMExp;Venting Reduction O&M Expenses")
    for year in years
      ZZZ[year] = sum(VnOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"FuOMExp;Other Fugitives Reduction O&M Expenses")
    for year in years
      ZZZ[year] = sum(FuOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"MEOMExp;Non Energy Reduction O&M Expenses")
    for year in years
      ZZZ[year] = sum(MEOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"PExp;Emission Permit Expenses")
    for year in years
      ZZZ[year] = sum((PExp[ecc,poll,area,year]+PExpExo[ecc,poll,area,year])/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, poll in Polls)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"TaxExp;Energy Tax Expenses")
    for year in years
      ZZZ[year] = sum(TaxExp[fuel,ecc,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    print(iob,"CFRExp;Clean Fuel Regulation Expenses")
    for year in years
      ZZZ[year] = sum(CFRExp[fuel,ecc,area,year]/Inflation[area,year]*
          Inflation[area,CDYear] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    #
    if (ECC[ecc] == "UtilityGen")
      print(iob,"TDInv;Transmission and Distribution Investments)")
      for year in years
        ZZZ[year] = sum(TDInv[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      print(iob,"ImportsExp;Import Expenses")
      for year in years
        ZZZ[year] = sum(ImportsExp[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      print(iob,"ExportsRevenue;Export Revenue")
      for year in years
        ZZZ[year] = sum(ExportsRevenue[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      print(iob,"RnCosts;Renewable REC Costs")
      for year in years
        ZZZ[year] = sum(RnCosts[area,year]/Inflation[area,year]*Inflation[area,CDYear] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    #
    if (ECC[ecc] != "UtilityGen") && (ECC[ecc] != "H2Production")
      print(iob,"Driver ;Economic Driver (Various Units)")
      for year in years
        ZZZ[year] = sum(Driver[ecc,area,year] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      #
      print(iob,"PCA ;Production Capacity Additions (Various Units)")
      new=Select(Age,"New")
      for year in years
        ZZZ[year] = sum(PCA[new,ecc,area,year] for area in areas)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end
  
  filename = "Expenditures-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end
end

function Expenditures_DtaControl(db)
  @info "Expenditures_DtaControl"

  data = ExpendituresData(; db)
  (; Area,AreaDS,ECC,Years) = data
  (; PInv) = data

  # TODO Add description of why this correction is here.
  ecc=Select(ECC,"IronSteel")
  area=Select(Area,"NS")
  for year in Years
    PInv[ecc,area,year]=1
  end

  #
  # Canada
  #
  areas=Select(Area,(from ="ON",to="NU"))
  for area in areas
    Expenditures_DtaRun(data,Area[area],AreaDS[area],area)
  end
  Expenditures_DtaRun(data,"CN","Canada",areas)

  #
  # US
  #
  areas=Select(Area,(from ="CA",to="Pac"))
  for area in areas
    Expenditures_DtaRun(data,Area[area],AreaDS[area],area)
  end
  Expenditures_DtaRun(data,"US","US",areas)

  #
  # MX
  #
  area=Select(Area,"MX")
  Expenditures_DtaRun(data,Area[area],AreaDS[area],area)

end
if abspath(PROGRAM_FILE) == @__FILE__
Expenditures_DtaControl(DB)
end
