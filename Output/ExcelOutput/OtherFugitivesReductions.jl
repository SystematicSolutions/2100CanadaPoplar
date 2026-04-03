#
# OtherFugitivesReductions.jl
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

Base.@kwdef struct OtherFugitivesReductionsData
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  FlPol::VariableArray{4}    = ReadDisk(db,"SOutput/FlPol")   #[ECC,Poll,Area,Year]  Fugitive Flaring Emissions (Tonnes/Yr)
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MEDriver::VariableArray{3} = ReadDisk(db,"MOutput/MEDriver") # [ECC,Area,Year] Driver for Process Emissions (Various Millions/Yr)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  FuA0::VariableArray{2} = ReadDisk(db,"MEInput/FuA0") #[ECC,Area]  A Term in Other Fugitives Reduction Curve (??)
  FuB0::VariableArray{2} = ReadDisk(db,"MEInput/FuB0") #[ECC,Area]  B Term in Other Fugitives Reduction Curve (??)
  FuC0::VariableArray{3} = ReadDisk(db,"MEInput/FuC0") #[ECC,Area,Year]  C Term in Other Fugitives Reduction Curve (??)
  FuCap::VariableArray{3} = ReadDisk(db,"MEOutput/FuCap") #[ECC,Area,Year]  Other Fugitives Reduction Capacity (Tonnes/Yr)
  FuCC::VariableArray{3} = ReadDisk(db,"MEOutput/FuCC") #[ECC,Area,Year]  Other Fugitives Reduction Capital Cost ($/Tonne)
  FuCCA0::VariableArray{2} = ReadDisk(db,"MEInput/FuCCA0") #[ECC,Area]  A Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCB0::VariableArray{2} = ReadDisk(db,"MEInput/FuCCB0") #[ECC,Area]  B Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCC0::VariableArray{3} = ReadDisk(db,"MEInput/FuCCC0") #[ECC,Area,Year]  C Term in Other Fugitives Reduction Capital Cost Curve ($/$)
  FuCCEm::VariableArray{3} = ReadDisk(db,"MEOutput/FuCCEm") #[ECC,Area,Year]  Other Fugitives Reduction Embedded Capital Cost ($/Tonne)
  FuCH4Captured::VariableArray{3} = ReadDisk(db,"MEOutput/FuCH4Captured") #[ECC,Area,Year]  CH4 Captured from Other Fugitives Reductions (Tonnes/Yr)
  FuCH4CapturedFraction::VariableArray{3} = ReadDisk(db,"MEInput/FuCH4CapturedFraction") #[ECC,Area,Year]  Fraction of CH4 Captured from Other Fugitives Reductions (Tonnes/Tonnes)
  FuCH4Flared::VariableArray{3} = ReadDisk(db,"MEOutput/FuCH4Flared") #[ECC,Area,Year]  CH4 Flared from Other Fugitives Reductions (Tonnes/Yr)
  FuCH4FlaredPOCF::VariableArray{4} = ReadDisk(db,"MEInput/FuCH4FlaredPOCF") #[ECC,Poll,Area,Year]  Pollution Coefficient for Flared CH4 (Tonnes/Tonnes)
  FuCH4FlPol::VariableArray{4} = ReadDisk(db,"MEOutput/FuCH4FlPol") #[ECC,Poll,Area,Year]  Emissions from Flaring CH4 (Tonnes/Yr)
  FuCR::VariableArray{3} = ReadDisk(db,"MEOutput/FuCR") #[ECC,Area,Year]  Other Fugitives Reduction Capacity Completion Rate (Tonnes/Yr/Yr)
  FuGAProd::VariableArray{3} = ReadDisk(db,"SOutput/FuGAProd") #[ECC,Area,Year]  Natural Gas Produced from Other Fugitives Reductions (TBtu/Yr)
  FuGExp::VariableArray{3} = ReadDisk(db,"MEOutput/FuGExp") #[ECC,Area,Year]  Other Fugitives Reduction Government Expenses (M$/Yr)
  FuGFr::VariableArray{3} = ReadDisk(db,"MEInput/FuGFr") #[ECC,Area,Year]  Other Fugitives Reduction Grant Fraction ($/$)
  FuGProd::VariableArray{2} = ReadDisk(db,"SOutput/FuGProd") #[Nation,Year]  Natural Gas Produced from Other Fugitives Reductions (TBtu/Yr)
  FuInv::VariableArray{3} = ReadDisk(db,"SOutput/FuInv") #[ECC,Area,Year]  Other Fugitives Reduction Investments (M$/Yr)
  FuOCF::VariableArray{3} = ReadDisk(db,"MEInput/FuOCF") #[ECC,Area,Year]  Other Fugitives Reduction Operating Cost Factor ($/$)
  FuOMExp::VariableArray{3} = ReadDisk(db, "SOutput/FuOMExp") # [ECC,Area,Year] Other Fugitives Reduction O&M Expenses (M$/Yr)
  FuPExp::VariableArray{3} = ReadDisk(db,"SOutput/FuPExp") #[ECC,Area,Year]  Other Fugitives Reduction Private Expenses (M$/Yr)
  FuPL::VariableArray{3} = ReadDisk(db,"MEInput/FuPL") #[ECC,Area,Year]  Other Fugitives Reduction Physical Lifetime (Years)
  FuPOCX::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCX") #[ECC,Poll,Area,Year]  Other Fugitives Emissions Coefficient (Tonnes/Driver)
  FuPOCXMult::VariableArray{4} = ReadDisk(db,"MEInput/FuPOCXMult") #[ECC,Poll,Area,Year]  Other Fugitives Pollution Coefficient Multiplier (Tonnes/Driver)
  FuPol::VariableArray{4}    = ReadDisk(db,"SOutput/FuPol")   #[ECC,Poll,Area,Year]  Other Fugitive Emissions (Tonnes/Yr)
  FuPolSwitch::VariableArray{4} = ReadDisk(db,"SInput/FuPolSwitch") # [ECC,Poll,Area,Year] Fugitive Pollution Switch (0=Exogenous)
  FuPrice::VariableArray{3} = ReadDisk(db,"MEOutput/FuPrice") #[ECC,Area,Year]  Price for Other Fugitives Reduction Curve ($/Tonne)
  FuPriceSw::VariableArray{1} = ReadDisk(db,"MEInput/FuPriceSw") #[Year]  Other Fugitives Reduction Curve Price Switch (1=Endogenous, 0 = Exogenous)
  FuReduce::VariableArray{4} = ReadDisk(db,"SOutput/FuReduce") # [ECC,Poll,Area,Year] Other Fugitives Reductions (Tonnes/Yr)
  FuRP::VariableArray{4} = ReadDisk(db,"MEOutput/FuRP") #[ECC,Poll,Area,Year]  Fraction of Other Fugitives Reduced (Tonnes/Tonnes)
  xFuPol::VariableArray{4} = ReadDisk(db,"SInput/xFuPol") # [ECC,Poll,Area,Year] Fugitive Emissions (Tonnes/Yr)
  xFuPrice::VariableArray{3} = ReadDisk(db,"MEInput/xFuPrice") #[ECC,Area,Year]  Exogenous Price for Other Fugitives Reduction Curve ($/Tonne)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function OtherFugitivesReductions_DtaRun(data,areas,AreaName,AreaKey)
  (; Area,AreaDS,Areas,ECC,ECCDS,ECCs,Poll,PollDS,Polls,Year) = data
  (; SceName,FlPol,Inflation,MEDriver,MoneyUnitDS,FuA0,FuB0,FuC0,FuCap) = data
  (; FuCC,FuCCA0,FuCCB0,FuCCC0,FuCCEm,FuCH4Captured,FuCH4CapturedFraction) = data
  (; FuCH4Flared,FuCH4FlaredPOCF,FuCH4FlPol,FuCR,FuGAProd,FuGExp,FuGFr) = data
  (; FuGProd,FuInv,FuInv,FuOCF,FuOMExp,FuPExp,FuPL,FuPOCX,FuPOCXMult) = data
  (; FuPol,FuPolSwitch,FuPrice,FuPriceSw,FuReduce,FuRP,xFuPol,xFuPrice) = data
  (; ZZZ) = data

  KJBtu = 1.054615
  years = collect(Yr(1990):Yr(2050))
  area_single = first(areas)
  eccs1 = Select(ECC,["NGDistribution","OilPipeline","NGPipeline","Petroleum"])
  eccs2 = Select(ECC,(from="LightOilMining", to="CoalMining"))
  eccs = union(eccs1,eccs2)

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob,"$AreaName; is the area name.")
  println(iob,"Other Fugitives Reductions")
  println(iob)
  println(iob,"Year;",";    ",join(Year[years],";"))
  println(iob)

  polls=Select(Poll,["CH4","CO2"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Other Fugitives Emissions (Kilotonnes/Yr);;    ", join(Year[years], ";"))
    print(iob, "FuPol;Total")  
    for year in years
      ZZZ[year] = sum(FuPol[ecc,poll,area,year] for area in areas, ecc in eccs)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob, "FuPol;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = sum(FuPol[ecc,poll,area,year] for area in areas)/1000
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  polls=Select(Poll,["CH4","CO2"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Flaring Emissions (Kilotonnes/Yr);;    ", join(Year[years], ";"))
    print(iob, "FlPol;Total")  
    for year in years
      ZZZ[year] = sum(FlPol[ecc,poll,area,year] for area in areas, ecc in eccs)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob, "FlPol;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = sum(FlPol[ecc,poll,area,year] for area in areas)/1000
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  polls=Select(Poll,["CH4","CO2"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Other Fugitives Reductions (Kilotonnes/Yr);;    ", join(Year[years], ";"))
    print(iob, "FuReduce;Total")  
    for year in years
      ZZZ[year] = sum(FuReduce[ecc,poll,area,year] for area in areas, ecc in eccs)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob, "FuReduce;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = sum(FuReduce[ecc,poll,area,year] for area in areas)/1000
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  polls=Select(Poll,["CO2"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Emissions from Flaring CH4 (Kilotonnes/Yr);;    ", join(Year[years], ";"))
    print(iob, "FuCH4FlPol;Total")  
    for year in years
      ZZZ[year] = sum(FuCH4FlPol[ecc,poll,area,year] for area in areas, ecc in eccs)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob, "FuCH4FlPol;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = sum(FuCH4FlPol[ecc,poll,area,year] for area in areas)/1000
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  polls=Select(Poll,["CH4"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Other Fugitives Emission Reduction Switch;;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob, "FuPolSwitch;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = FuPolSwitch[ecc,poll,area_single,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  polls=Select(Poll,["CH4"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Fraction of Other Fugitives Reduced (Tonnes/Tonnes);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob, "FuRP;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = FuRP[ecc,poll,area_single,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  polls=Select(Poll,["CH4"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Other Fugitives Emissions Coefficient Multiplier (Tonnes/Tonnes);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob, "FuPOCXMult;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = FuPOCXMult[ecc,poll,area_single,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  # TODO : Should this be sum(Area), and unit Kilotonnes? -LJD, 25.09.02
  polls=Select(Poll,["CH4","CO2"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Exogenous Other Fugitives Emissions (Tonnes/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob, "xFuPol;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = xFuPol[ecc,poll,area_single,year]/1000
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob, "$AreaName CH4 Captured from Other Fugitives Reductions (Kilotonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuCH4Captured;Total")  
  for year in years
    ZZZ[year] = sum(FuCH4Captured[ecc,area,year] for area in areas, ecc in eccs)/1000
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuCH4Captured;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuCH4Captured[ecc,area,year] for area in areas)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName CH4 Flared from Other Fugitives Reductions (Kilotonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuCH4Flared;Total")  
  for year in years
    ZZZ[year] = sum(FuCH4Flared[ecc,area,year] for area in areas, ecc in eccs)/1000
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuCH4Flared;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuCH4Flared[ecc,area,year] for area in areas)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Natural Gas Produced from Other Fugitives Reductions (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuGAProd;Total")  
  for year in years
    ZZZ[year] = sum(FuGAProd[ecc,area,year] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuGAProd;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuGAProd[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Fraction of Captured from Other Fugitives Reductions (Tonnes/Tonnes);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuCH4CapturedFraction;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuCH4CapturedFraction[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  polls=Select(Poll,["CH4"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Other Fugitives Emissions Coefficient (Tonnes/Driver);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob, "FuPOCX;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = FuPOCX[ecc,poll,area_single,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob, "$AreaName Other Fugitives Reduction Capacity (Kilotonnes/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuCap;Total")  
  for year in years
    ZZZ[year] = sum(FuCap[ecc,area,year] for area in areas, ecc in eccs)/1000
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuCap;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuCap[ecc,area,year] for area in areas)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction Capacity Completion Rate (KiloTonnes/Yr/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuCR;Total")  
  for year in years
    ZZZ[year] = sum(FuCR[ecc,area,year] for area in areas, ecc in eccs)/1000
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuCR;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuCR[ecc,area,year] for area in areas)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Price for Other Fugitives Reduction Curve (2020 $(MoneyUnitDS[area_single])/tonne);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuPrice;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuPrice[ecc,area_single,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Exogenous Price for Other Fugitives Reduction Curve (2020 $(MoneyUnitDS[area_single])/tonne);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "xFuPrice;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = xFuPrice[ecc,area_single,year]*Inflation[area_single,Yr(2020)]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction Private Expenses (2020 CN M\$/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuPExp;Total")  
  for year in years
    ZZZ[year] = sum(FuPExp[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr(2020)] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuPExp;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuPExp[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr(2020)] for area in areas)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction Investments (2020 CN M\$/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuInv;Total")  
  for year in years
    ZZZ[year] = sum(FuInv[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr(2020)] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuInv;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuInv[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr(2020)] for area in areas)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction O&M Expenses (2020 CN M\$/Yr);;    ", join(Year[years], ";"))
  print(iob, "FuOMExp;Total")  
  for year in years
    ZZZ[year] = sum(FuOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr(2020)] for area in areas, ecc in eccs)
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  for ecc in eccs
    print(iob, "FuOMExp;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(FuOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr(2020)] for area in areas)/1000
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction Capital Cost (2020 CN \$/Tonne);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuCC;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuCC[ecc,area_single,year]/Inflation[area_single,year]*Inflation[area_single,Yr(2020)]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction Embedded Capital Cost (2020 CN \$/Tonne);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuCCEm;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuCCEm[ecc,area_single,year]/Inflation[area_single,year]*Inflation[area_single,Yr(2020)]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction Operating Cost Factor (\$/\$);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuOCF;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuOCF[ecc,area_single,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Other Fugitives Reduction Physical Lifetime (Years);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuPL;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuPL[ecc,area_single,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "Price Switch for Other Fugitives Reduction Curve (0=exogenous);;    ", join(Year[years], ";"))
  print(iob, "FuPriceSw;Switch")  
  for year in years
    ZZZ[year] = FuPriceSw[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  polls=Select(Poll,["CO2"])
  for poll in polls
    println(iob, "$AreaName $(PollDS[poll]) Pollution Coefficient for Flared CH4 (Tonnes/Tonnes);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob, "FuCH4FlaredPOCF;$(ECCDS[ecc])")  
      for year in years
        ZZZ[year] = FuCH4FlaredPOCF[ecc,poll,area_single,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob, "$AreaName A Term in Other Fugitives Reduction Curve (\$/Tonne);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuA0;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuA0[ecc,area_single]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName B Term in Other Fugitives Reduction Curve (\$/Tonne);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuB0;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuB0[ecc,area_single]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName C Term in Other Fugitives Reduction Curve (\$/Tonne);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuC0;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuC0[ecc,area_single,year]
      print(iob,";",@sprintf("%15.6f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName A Term in Other Fugitives Reduction Capital Cost Curve (\$/\$);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuCCA0;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuCCA0[ecc,area_single]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName B Term in Other Fugitives Reduction Capital Cost Curve (\$/\$);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuCCB0;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuCCB0[ecc,area_single]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName C Term in Other Fugitives Reduction Capital Cost Curve (\$/\$);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "FuCCC0;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = FuCCC0[ecc,area_single,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob, "$AreaName Driver for Process Emissions (Various Millions/Yr);;    ", join(Year[years], ";"))
  for ecc in eccs
    print(iob, "MEDriver;$(ECCDS[ecc])")  
    for year in years
      ZZZ[year] = sum(MEDriver[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "OtherFugitivesReductions-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end

end

function OtherFugitivesReductions_DtaControl(db)
  @info "OtherFugitivesReductions_DtaControl"
  data = OtherFugitivesReductionsData(; db)
  (; Area,Areas,AreaDS) = data

  #
  # Canada
  #
  areas = Select(Area,["AB","ON","QC","BC","SK","MB","NB","NS","PE","NL","YT","NT","NU"])

  AreaName = "Canada"
  AreaKey = "CN"
  OtherFugitivesReductions_DtaRun(data,areas,AreaName,AreaKey)

  #
  # Individual Areas
  #
  for areas in areas
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    OtherFugitivesReductions_DtaRun(data,areas,AreaName,AreaKey)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
OtherFugitivesReductions_DtaControl(DB)
end
