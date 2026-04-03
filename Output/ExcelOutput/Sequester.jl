#
# Sequester.jl
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

Base.@kwdef struct SequesterData
  db::String

  Input::String = "IInput"
  Outpt::String = "IOutput"
  CalDB::String = "ICalDB"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") #  Base Case Name

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db, "$Input/ECKey")
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  ECDS::SetArray = ReadDisk(db, "$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Level::SetArray = ReadDisk(db, "MainDB/LevelKey")
  Levels::Vector{Int} = collect(Select(Level))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  PCov::SetArray = ReadDisk(db, "MainDB/PCovKey")
  PCovDS::SetArray = ReadDisk(db, "MainDB/PCovDS")
  PCovs::Vector{Int} = collect(Select(PCov))
  Poll::SetArray = ReadDisk(db, "MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db, "MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db, "$Input/TechKey")
  TechDS::SetArray = ReadDisk(db, "$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db, "MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ECoverage::VariableArray{5} = ReadDisk(db, "SInput/ECoverage") # [ECC,Poll,PCov,Area,Year] Emissions Permit Coverage (Tonnes/Tonnes)
  EUPolSq::VariableArray{3} = ReadDisk(db, "SOutput/EUPolSq") # [Poll,Area,Year] Electric Utility Pollution Sequestered (Tonnes/Yr)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index
  MoneyUnitDS::Array{String} = ReadDisk(db, "MInput/MoneyUnitDS") # [Area] Descriptor for Monetary Units
  PCost::VariableArray{4} = ReadDisk(db, "SOutput/PCost") # [ECC,Poll,Area,Year] Permit Cost (Real $/Tonnes)
  PCostExo::VariableArray{4} = ReadDisk(db, "SInput/PCostExo") # [ECC,Poll,Area,Year] Exogenous Permit Cost (Real $/Tonnes)
  CgSqPot::VariableArray{4} = ReadDisk(db, "SOutput/CgSqPot") # [ECC,Poll,Area,Year] Unit Cogeneration Sequestering Potential (Tonnes/Yr)
  EnSqPot::VariableArray{4} = ReadDisk(db, "SOutput/EnSqPot") # [ECC,Poll,Area,Year] Enduse Sequestering Potential (Tonnes/Yr)
  FPCFSObligated::VariableArray{3} = ReadDisk(db, "SOutput/FPCFSObligated") # [ECC,Area,Year] CFS Price for Obligated Sectors ($/Tonnes)
  FPCFSSwitch::VariableArray{3} = ReadDisk(db, "SInput/FPCFSSwitch") # [ECC,Area,Year] CFS Price Switch (1=Full, 2=Partial, 0=None)
  FsSqPot::VariableArray{4} = ReadDisk(db, "SOutput/FsSqPot") # [ECC,Poll,Area,Year] Feedstock Sequestering Potential (Tonnes/Yr)
  MESqPot::VariableArray{4} = ReadDisk(db, "SOutput/MESqPot") # [ECC,Poll,Area,Year] Process Sequestering Potential (Tonnes/Yr)
  SqA0::VariableArray{3} = ReadDisk(db, "MEInput/SqA0") # [ECC,Area,Year] A Term in eCO2 Sequestering Curve (units assume 2016 CN$)
  SqB0::VariableArray{3} = ReadDisk(db, "MEInput/SqB0") # [ECC,Area,Year] B Term in eCO2 Sequestering Curve (Dimensionless)
  SqBL::VariableArray{2} = ReadDisk(db, "MEInput/SqBL") # [Area,Year] Sequestering Book Lifetime (Years)
  SqC0::VariableArray{3} = ReadDisk(db, "MEInput/SqC0") # [ECC,Area,Year] C Term in eCO2 Sequestering Curve (Tonnes/Tonnes)
  SqCap::VariableArray{3} = ReadDisk(db, "MEOutput/SqCap") # [ECC,Area,Year] Sequestering eCO2 Reduction Capacity (Tonnes/Yr)
  SqCapCI::VariableArray{3} = ReadDisk(db, "MEOutput/SqCapCI") # [ECC,Area,Year] Sequestering Capacity Construction Initiation (Tonnes/Yr/Yr)
  SqCapCR::VariableArray{3} = ReadDisk(db, "MEOutput/SqCapCR") # [ECC,Area,Year] Sequestering Capacity Completion Rate (Tonnes/Yr/Yr)
  SqCapRR::VariableArray{3} = ReadDisk(db, "MEOutput/SqCapRR") # [ECC,Area,Year] Sequestering Capacity Retirement Rate (Tonnes/Yr/Yr)
  SqCC::VariableArray{3} = ReadDisk(db, "MEOutput/SqCC") # [ECC,Area,Year] Sequestering eCO2 Reduction Capital Cost ($/Tonne)
  SqCCA0::VariableArray{3} = ReadDisk(db, "MEInput/SqCCA0") # [ECC,Area,Year] A Term in eCO2 Sequestering Capital Cost Curve (2016 Local$)
  SqCCB0::VariableArray{3} = ReadDisk(db, "MEInput/SqCCB0") # [ECC,Area,Year] B Term in eCO2 Sequestering Capital Cost Curve (2016 Local$)
  SqCCC0::VariableArray{3} = ReadDisk(db, "MEInput/SqCCC0") # [ECC,Area,Year] C Term in eCO2 Sequestering Capital Cost Curve (2016 Local$)
  SqCCEm::VariableArray{3} = ReadDisk(db, "MEOutput/SqCCEm") # [ECC,Area,Year] Sequestering eCO2 Reduction Embedded Capital Cost ($/Tonne)
  SqCCLevelized::VariableArray{3} = ReadDisk(db, "MEOutput/SqCCLevelized") # [ECC,Area,Year] Sequestering Levelized Cost for Cost Curve (2016 CN$/tonne CO2e)
  SqCCR::VariableArray{2} = ReadDisk(db, "MEOutput/SqCCR") # [Area,Year] Sequestering eCO2 Reduction Capital Charge Rate ($/$)
  SqCCRMult::VariableArray{2} = ReadDisk(db, "MEOutput/SqCCRMult") # [Area,Year] Sequestering eCO2 Reduction Capital Charge Rate Multiplier ($/$)
  SqCCSw::VariableArray{3} = ReadDisk(db, "MEInput/SqCCSw") # [ECC,Area,Year] Sequestering Capital Cost Switch (1=CC Curve)
  SqCD::VariableArray{3} = ReadDisk(db, "MEInput/SqCD") # [ECC,Area,Year] Sequestering Construction Delay (Years)
  SqCDOrder::VariableArray{2} = ReadDisk(db, "MEInput/SqCDOrder") # [ECC,Year] Number of Levels in the Sequestering Construction Delay (Number)
  SqCDInput::VariableArray{4} = ReadDisk(db, "MEOutput/SqCDInput") # [Level,ECC,Area,Year] Input to Sequestering Delay Level (Tonnes/Yr/Yr)
  SqCDLevel::VariableArray{4} = ReadDisk(db, "MEOutput/SqCDLevel") # [Level,ECC,Area,Year] Sequestering Delay Level (Tonnes/Yr)
  SqCDOutput::VariableArray{4} = ReadDisk(db, "MEOutput/SqCDOutput") # [Level,ECC,Area,Year] Output from Sequestering Delay Level (Tonnes/Yr/Yr)
  SqDmd::VariableArray{4} = ReadDisk(db, "$Outpt/SqDmd") # [Tech,EC,Area,Year] Sequestering Energy Demand (TBtu/Yr)
  SqFuelCost::VariableArray{3} = ReadDisk(db, "SOutput/SqFuelCost") # [ECC,Area,Year] Sequestering Fuel Costs ($/Tonnes)
  SqGExp::VariableArray{3} = ReadDisk(db, "MEOutput/SqGExp") # [ECC,Area,Year] Sequestering Government Expenses (M$/Yr)
  SqGFr::VariableArray{2} = ReadDisk(db, "MEInput/SqGFr") # [Area,Year] Sequestering eCO2 Reduction Grant Fraction ($/$)
  SqIVTC::VariableArray{2} = ReadDisk(db, "MEInput/SqIVTC") # [Area,Year] Sequestering eCO2 Reduction Investment Tax Credit ($/$)
  SqIPol::VariableArray{4} = ReadDisk(db, "MEOutput/SqIPol") # [ECC,Poll,Area,Year] CCS Indicated for Construction (Tonnes/Yr)
  SqIPolCC::VariableArray{4} = ReadDisk(db, "MEOutput/SqIPolCC") # [ECC,Poll,Area,Year] CCS Indicated from Cost Curves (Tonnes/Yr)
  SqOCF::VariableArray{3} = ReadDisk(db, "SInput/SqOCF") # [ECC,Area,Year] Sequestering eCO2 Reduction Operating Cost Factor ($/$)
  SqOMExp::VariableArray{3} = ReadDisk(db, "SOutput/SqOMExp") # [ECC,Area,Year] Sequestering O&M Expenses (M$/Yr)
  SqPenaltyFrac::VariableArray{4} = ReadDisk(db, "MEInput/SqPenaltyFrac") # [ECC,Poll,Area,Year] Sequestering Emission Penalty (Tonne/Tonne)
  SqPenaltyFuel::VariableArray{4} = ReadDisk(db, "$Input/SqPenaltyFuel") # [Fuel,EC,Area,Year] Sequestering Energy Penalty (TBtu/Tonne CO2)
  SqPenaltyTech::VariableArray{5} = ReadDisk(db, "$Input/SqPenaltyTech") # [Tech,EC,Poll,Area,Year] Sequestering Energy Penalty (TBtu/Tonne)
  SqPExp::VariableArray{3} = ReadDisk(db, "SOutput/SqPExp") # [ECC,Area,Year] Sequestering Private Expenses (M$/Yr)
  SqPGMult::VariableArray{4} = ReadDisk(db, "SInput/SqPGMult") # [ECC,Poll,Area,Year] Sequestering Gratis Permit Multiplier (Tonnes/Tonnes)
  SqPL::VariableArray{2} = ReadDisk(db, "MEInput/SqPL") # [Area,Year] Sequestering eCO2 Reduction Physical Lifetime (Years)
  SqPOCF::VariableArray{4} = ReadDisk(db, "MEInput/SqPOCF") # [ECC,Poll,Area,Year] Sequestering Emission Factor (Tonnes/Tonne CO2)
  SqPol::VariableArray{4} = ReadDisk(db, "SOutput/SqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)
  SqPolCC::VariableArray{4} = ReadDisk(db, "SOutput/SqPolCC") # [ECC,Poll,Area,Year] Sequestering Non-Cogeneration Gross Emissions (Tonnes/Yr)
  SqPolCCNet::VariableArray{4} = ReadDisk(db, "SOutput/SqPolCCNet") # [ECC,Poll,Area,Year] Sequestering Non-Cogeneration Net Emissions (Tonnes/Yr)
  SqPolCCPenalty::VariableArray{4} = ReadDisk(db, "SOutput/SqPolCCPenalty") # [ECC,Poll,Area,Year] Sequestering Non-Cogeneration Emissions Penalty (Tonnes/Yr)
  SqPolCg::VariableArray{4} = ReadDisk(db, "SOutput/SqPolCg") # [ECC,Poll,Area,Year] Sequestering Cogeneration Emissions (Tonnes/Yr)
  SqPolCgPenalty::VariableArray{4} = ReadDisk(db, "SOutput/SqPolCgPenalty") # [ECC,Poll,Area,Year] Sequestering Cogeneration Emissions Penalty (Tonnes/Yr)
  SqPolNet::VariableArray{4} = ReadDisk(db, "SOutput/SqPolNet") # [ECC,Poll,Area,Year] Net Sequestering Emissions (Tonnes/Yr)
  SqPolPenalty::VariableArray{4} = ReadDisk(db, "SOutput/SqPolPenalty") # [ECC,Poll,Area,Year] Sequestering Emissions Penalty (Tonnes/Yr)
  SqPotential::VariableArray{4} = ReadDisk(db, "SOutput/SqPotential") # [ECC,Poll,Area,Year] Potential Sequestering Emissions (Tonnes/Yr)
  SqPrice::VariableArray{3} = ReadDisk(db, "MEOutput/SqPrice") # [ECC,Area,Year] Sequestering Cost Curve Price (2016 CN$/tonne CO2e)
  SqReduction::VariableArray{4} = ReadDisk(db, "MEOutput/SqReduction") # [ECC,Poll,Area,Year] Sequestering Fraction Captured Marginal(tonne/tonne)
  SqReductionEm::VariableArray{4} = ReadDisk(db, "MEOutput/SqReductionEm") # [ECC,Poll,Area,Year] Sequestering Fraction Captured Embedded (tonne/tonne)
  SqROIN::VariableArray{2} = ReadDisk(db, "MEInput/SqROIN") # [Area,Year] Sequestering eCO2 Reduction Return on Investment ($/$)
  SqCCThreshold::VariableArray{3} = ReadDisk(db, "MEInput/SqCCThreshold") # [ECC,Area,Year] Levelized Cost Threshold for Sequestering Curve (2016 CN$/Tonne)
  SqTL::VariableArray{2} = ReadDisk(db, "MEInput/SqTL") # [Area,Year] Sequestering eCO2 Reduction Tax Lifetime (Years)
  SqTM::VariableArray{3} = ReadDisk(db, "MEInput/SqTM") # [ECC,Area,Year] Sequestering Technology Multiplier ($/$)
  SqTransStorageCost::VariableArray{2} = ReadDisk(db, "MEInput/SqTransStorageCost") # [Area,Year] Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e)
  SqTSCost::VariableArray{2} = ReadDisk(db,"MEOutput/SqTSCost") #[Area,Year]  Sequestering Transportation and Storage Costs (2016 CN$/tonne CO2e) 
  SqTxRt::VariableArray{2} = ReadDisk(db, "MEInput/SqTxRt") # [Area,Year] Sequestering eCO2 Reduction Tax Rate ($/$)
  xSqDmd::VariableArray{4} = ReadDisk(db, "$Input/xSqDmd") # [Tech,EC,Area,Year] Sequestering Energy Demand (TBtu/Yr)
  xSqPol::VariableArray{4} = ReadDisk(db, "MEInput/xSqPol") # [ECC,Poll,Area,Year] Sequestering Emissions (Tonnes/Yr)
  xSqPolCCNet::VariableArray{4} = ReadDisk(db, "MEInput/xSqPolCCNet") # [ECC,Poll,Area,Year] Sequestering Net Emissions (Tonnes/Yr)
  xSqPrice::VariableArray{3} = ReadDisk(db, "MEInput/xSqPrice") # [ECC,Area,Year] Exogenous Sequestering Cost Curve Price ($/tonne CO2e)

  # Scratch Variables
  # AreaName      Type=String(30)
  # Count
  # LevelDS Type=String(10)
  # ZZZ(Year)     Type=Real(15,4)
end

function Sequester_DtaRun(data, areas, polls, eccs, eccs_ccs, AreaName, AreaKey)
  (; Area, AreaDS, Areas, EC, ECC, ECCDS, ECCs, ECDS, ECs,  
  Fuel,  FuelDS, Fuels, Level, Levels, Nation, NationDS, Nations, PCov, PCovDS,  
  PCovs,  Poll, PollDS, Polls, Tech, TechDS, Techs, Year, YearDS,Years) = data
  (; Input, Outpt, CalDB) = data
  (;ANMap,CgSqPot,ECoverage,EnSqPot,EUPolSq,FPCFSObligated,
  FPCFSSwitch,FsSqPot,Inflation,MESqPot,MoneyUnitDS,PCost,
  PCostExo,SceName,SqA0,SqB0,SqBL,SqC0,SqCap,SqCapCI,SqCapCR,
  SqCapRR,SqCC,SqCCA0,SqCCB0,SqCCC0,SqCCEm,SqCCLevelized,SqCCR,
  SqCCRMult,SqCCSw,SqCD,SqCDInput,SqCDLevel,SqCDOrder,SqCDOutput,
  SqDmd,SqFuelCost,SqGExp,SqGFr,SqIPol,SqIPolCC,SqIVTC,SqOCF,
  SqOMExp,SqPenaltyFrac,SqPenaltyFuel,SqPenaltyTech,SqPExp,SqPGMult,
  SqPL,SqPOCF,SqPol,SqPolCC,SqPolCCNet,SqPolCCPenalty,SqPolCg,
  SqPolCgPenalty,SqPolNet,SqPolPenalty,SqPrice,SqPotential,
  SqReduction,SqReductionEm,SqROIN,SqTL,SqTM,SqTransStorageCost,
  SqTSCost,SqTxRt,SqCCThreshold,xSqDmd,xSqPol,xSqPolCCNet,
  xSqPrice)=data

  ZZZ = zeros(Float32,length(Year))
  
  Yr1990 = 1990-ITime+1
  Yr2016 = 2016-ITime+1
  years = collect(Yr1990:Final)
  levels = collect(1:Int(maximum(SqCDOrder[ecc,year] for year in years, ecc in eccs)))
  area1 = first(areas)

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This is the Sequester Summary.")
  println(iob)

  println(iob,"Year;",";    ",join(Year[years],";"))
  println(iob)

  for poll in polls
    println(iob,AreaName," ",PollDS[poll]," Gross Sequestering Emissions (MT/Yr);;    ",join(Year[years],";"))
    print(iob,"SqPol;Total")
    for year in years
      ZZZ[year]=sum(SqPol[ecc,poll,area,year] for area in areas,ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPol;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPol[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Net Sequestering Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPolNet;Total")
    for year in years
      ZZZ[year]=sum(SqPolNet[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPolNet;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPolNet[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Sequestering Emission Penalty (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPolPenalty;Total")
    for year in years
      ZZZ[year]=sum(SqPolPenalty[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPolPenalty;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPolPenalty[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Gross Sequestering Non-Cogeneration Emissions (MT/Yr);;    ", join(Year[year] for year in years), ";")
    print(iob,"SqPolCC;Total")
    for year in years
      ZZZ[year]=sum(SqPolCC[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPolCC;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPolCC[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Net Sequestering Non-Cogeneration Emissions (MT/Yr);;    ", join(Year[year] for year in years), ";")
    print(iob,"SqPolCCNet;Total")
    for year in years
      ZZZ[year]=sum(SqPolCCNet[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPolCCNet;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPolCCNet[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Sequestering Non-CogenerationEmission Penalty (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPolCCPenalty;Total")
    for year in years
      ZZZ[year]=sum(SqPolCCPenalty[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPolCCPenalty;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPolCCPenalty[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Gross Sequestering Cogeneration Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPolCg;Total")
    for year in years
      ZZZ[year]=sum(SqPolCg[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPolCg;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPolCg[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Sequestering Cogeneration Emissions Penalty (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPolCgPenalty;Total")
    for year in years
      ZZZ[year]=sum(SqPolCgPenalty[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPolCgPenalty;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPolCgPenalty[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,AreaDS[area1], " Sequestering Cost Curve Price (2016 ",MoneyUnitDS[area1],"/Tonne CO2e);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqPrice;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqPrice[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # TODO: there appears to be a difference in how Julia and Promula are interpreting this maximum.
  # This could use Jeff's review to be sure both equations are working the intended way.
  #
  println(iob,AreaDS[area1], " Sequestering Cost (2016 ",MoneyUnitDS[area1],"/Tonne CO2e);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCost;",ECCDS[ecc])
    for year in years
      ZZZ[year]=max(SqCCLevelized[ecc,area1,year],SqCCThreshold[ecc,area1,year])+
        SqFuelCost[ecc,area1,year]/Inflation[area1,year]*Inflation[area1,Yr2016]+
        SqTSCost[area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering Levelized Cost for Cost Curve (2016 ",MoneyUnitDS[area1],"/Tonne CO2e);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCCLevelized;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCCLevelized[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering Fuel Costs (2016 ",MoneyUnitDS[area1],"/Tonne CO2e);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqFuelCost;",ECCDS[ecc])
    for year in years
      ZZZ[year]= SqFuelCost[ecc,area1,year]/Inflation[area1,year]*Inflation[area1,Yr2016]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering Transportation and Storage Costs (2016 ",MoneyUnitDS[area1],"/Tonne CO2e);;    ", join(Year[years], "; "))
  print(iob,"SqTSCost;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqTSCost[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaDS[area1], " Levelized Cost Threshold for Sequestering Curve (2016 CN\$/Tonne CO2e);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCCThreshold;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCCThreshold[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Sequestering Sequestering Fraction Captured (tonne/tonne);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"SqReduction;",ECCDS[ecc])
      for year in years
        ZZZ[year]=SqReduction[ecc,poll,area1,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " CCS Indicated from Cost Curves (MT/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"SqIPolCC;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqIPolCC[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " CCS Indicated for Construction (MT/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"SqIPol;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqIPol[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end


  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Sequestering Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPotential;Total")
    for year in years
      ZZZ[year]=sum(SqPotential[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"SqPotential;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPotential[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Enduse Sequestering Potential (MT/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"EnSqPot;",ECCDS[ecc])
      for year in years
        ZZZ[year]=EnSqPot[ecc,poll,area1,year]/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Feedstock Sequestering Potential (MT/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"FsSqPot;",ECCDS[ecc])
      for year in years
        ZZZ[year]=FsSqPot[ecc,poll,area1,year]/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Cogeneration Sequestering Potential (MT/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"CgSqPot;",ECCDS[ecc])
      for year in years
        ZZZ[year]=CgSqPot[ecc,poll,area1,year]/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Process Sequestering Potential (MT/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"MESqPot;",ECCDS[ecc])
      for year in years
        ZZZ[year]=MESqPot[ecc,poll,area1,year]/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Null Space holder Variable;;    ", join(Year[years], ";"))
    for ecc in eccs
      for year in years
        ZZZ[year]=0.0
      end
      print(iob,"Null;",ECCDS[ecc])
      for year in years
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  techs = Select(Tech,["Electric","Gas"])
  for poll in polls, tech in techs
    println(iob,AreaDS[area1], " ", PollDS[poll], " ", TechDS[tech], " Sequestering Energy Penalty (TBtu/Tonne);;    ", join(Year[years], ";"))
    for ecc in eccs, ec in ECs
      if EC[ec] == ECC[ecc]
        print(iob,"SqPenaltyTech;",ECCDS[ecc])
        for year in years
          ZZZ[year]=SqPenaltyTech[tech,ec,poll,area1,year]
          print(iob,";",@sprintf("%.6e", ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)
  end

  for tech in techs
    println(iob,AreaDS[area1], " ", TechDS[tech], " Sequestering Energy Penalty (TBtu/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs, ec in ECs
      if EC[ec] == ECC[ecc]
        print(iob,"SqDmd;",ECCDS[ecc])
        for year in years
          ZZZ[year]=SqDmd[tech,ec,area1,year]
          print(iob,";",@sprintf("%15.4f", ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)
  end

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Capital Cost (2016 ",MoneyUnitDS[area1],"/Tonnes);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCC;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCC[ecc,area1,year]/Inflation[area1,year]*Inflation[area1,Yr2016]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaName, " Sequestering eCO2 Reduction Capacity (MT/Yr);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCap;",ECCDS[ecc])
    for year in years
      ZZZ[year]=sum(SqCap[ecc,area,year] for area in areas)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaName, " Sequestering Capacity Construction Initiation (MT/Yr/Yr);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCapCI;",ECCDS[ecc])
    for year in years
      ZZZ[year]=sum(SqCapCI[ecc,area,year] for area in areas)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaName, " Sequestering Investments (Millions 2016 ",MoneyUnitDS[area1],"/Yr);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqInv;",ECCDS[ecc])
    for year in years
      ZZZ[year]=sum(SqCapCR[ecc,area,year]*SqCC[ecc,area,year]/1e6/Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaName, " Sequestering O&M Expenses (Millions 2016 ",MoneyUnitDS[area1],"/Yr);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqOMExp;",ECCDS[ecc])
    for year in years
      ZZZ[year]=sum(SqOMExp[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Embedded Capital Cost (2016 ",MoneyUnitDS[area1],"/Tonnes);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCCEm;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCCEm[ecc,area1,year]/Inflation[area1,year]*Inflation[area1,Yr2016]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaName, " Sequestering Capacity Completion Rate (MT/Yr/Yr);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCapCR;",ECCDS[ecc])
    for year in years
      ZZZ[year]=sum(SqCapCR[ecc,area,year] for area in areas)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaName, " Sequestering Capacity Retirement Rate (MT/Yr/Yr);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCapRR;",ECCDS[ecc])
    for year in years
      ZZZ[year]=sum(SqCapRR[ecc,area,year] for area in areas)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering Capital Cost Switch (1=CC Curve);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCCSw;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCCSw[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " A Term in eCO2 Sequestering Curve (units assume 2016 CN\$);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqA0;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqA0[ecc,area1,year]
      print(iob,";",@sprintf("%20.0f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " B Term in eCO2 Sequestering Curve (Dimensionless);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqB0;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqB0[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " C Term in eCO2 Sequestering Curve (Tonnes/Tonnes);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqC0;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqC0[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " A Term in eCO2 Sequestering Capital Cost Curve (2016 ",MoneyUnitDS[area1],");;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCCA0;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCCA0[ecc,area1,year]
      print(iob,";",@sprintf("%20.0f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " B Term in eCO2 Sequestering Capital Cost Curve (2016 ",MoneyUnitDS[area1],");;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCCB0;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCCB0[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob,AreaDS[area1], " C Term in eCO2 Sequestering Capital Cost Curve (2016 ",MoneyUnitDS[area1],");;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCCC0;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCCC0[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering Technology Multiplier (\$/\$);;    ", join(Year[year] for year in years), "; ")
  for ecc in eccs
    print(iob,"SqTM;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqTM[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,"Sequestering eCO2 Reduction Operating Cost Factor (\$/\$);;    ", join(Year[year] for year in years), "; ")
  for ecc in eccs
    print(iob,"SqOCF;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqOCF[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Physical Lifetime (Years);;    ", join(Year[year] for year in years), "; ")
  print(iob,"SqPL;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqPL[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaDS[area1], " Sequestering Book Lifetime (Years);;    ", join(Year[year] for year in years), "; ")
  print(iob,"SqBL;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqBL[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Tax Lifetime (Years);;    ", join(Year[year] for year in years), "; ")
  print(iob,"SqTL;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqTL[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Capital Charge Rate (\$/\$);;    ", join(Year[years], "; "))
  print(iob,"SqCCR;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqCCR[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Return on Investment (\$/\$);;    ", join(Year[years], "; "))
  print(iob,"SqROIN;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqROIN[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Tax Rate (\$/\$);;    ", join(Year[years], "; "))
  print(iob,"SqTxRt;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqTxRt[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Investment Tax Credit (\$/\$);;    ", join(Year[years], "; "))
  print(iob,"SqIVTC;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqIVTC[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  println(iob,AreaName, " Sequestering Private Expenditures (Millions 2016 ",MoneyUnitDS[area1],"/Yr);;    ", join(Year[year] for year in years), "; ")
  for ecc in eccs
    print(iob,"SqPExp;",ECCDS[ecc])    
    for year in years
      ZZZ[year]=sum(SqPExp[ecc,area,year]/Inflation[area,year]*Inflation[area,Yr2016] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaName, " Sequestering Government Expenses (M\$/Yr);;    ", join(Year[year] for year in years), "; ")
  for ecc in eccs
    print(iob,"SqGExp;",ECCDS[ecc])
    for year in years
      ZZZ[year]=sum(SqGExp[ecc,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Grant Fraction (\$/\$);;    ", join(Year[years], "; "))
  print(iob,"SqGFr;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqGFr[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Sequestering Gratis Permit Multiplier (Tonnes/Tonnes);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"SqPGMult;",ECCDS[ecc])
      for year in years
        ZZZ[year]=SqPGMult[ecc,poll,area1,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,AreaDS[area1], " Sequestering Construction Delay (Years);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"SqCD;",ECCDS[ecc])
    for year in years
      ZZZ[year]=SqCD[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Sequestering Macroeconomic Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPolCCNet;Total")
    for year in years
      ZZZ[year]=sum(SqPolCCNet[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
     print(iob,"SqPolCCNet;",ECCDS[ecc])
      for year in years
         ZZZ[year]=sum(SqPolCCNet[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Sequestering Cogeneration Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"SqPolCg;Total")
    for year in years
      ZZZ[year]=sum(SqPolCg[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
     print(iob,"SqPolCg;",ECCDS[ecc])
      for year in years
         ZZZ[year]=sum(SqPolCg[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end
  
  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Permit Cost (2016 ",MoneyUnitDS[area1],"/Tonnes);;    ", join(Year[years], "; "))
    for ecc in eccs
      print(iob,"PCost;",ECCDS[ecc])
      for year in years
        ZZZ[year]=PCost[ecc,poll,area1,year]*Inflation[area1,Yr2016]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end
  
  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Exogenous Permit Cost (2016 ",MoneyUnitDS[area1],"/Tonnes);;    ", join(Year[years], "; "))
    for ecc in eccs
      print(iob,"PCostExo;",ECCDS[ecc])
      for year in years
        ZZZ[year]=PCostExo[ecc,poll,area1,year]*Inflation[area1,Yr2016]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,AreaDS[area1], " CFS Price for Obligated Sectors (2016 ",MoneyUnitDS[area1],"/Tonnes);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"FPCFSObligated;",ECCDS[ecc])
    for year in years
      ZZZ[year]=FPCFSObligated[ecc,area1,year]/Inflation[area1,year]*Inflation[area1,Yr2016]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " CFS Price Switch (1=Full, 2=Partial, 0=None);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"FPCFSSwitch;",ECCDS[ecc])
    for year in years
      ZZZ[year]=FPCFSSwitch[ecc,area1,year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,AreaDS[area1], " Sequestering eCO2 Reduction Capital Charge Rate Multiplier (\$/\$);;    ", join(Year[years], "; "))
  print(iob,"SqCCRMult;",AreaDS[area1])
  for year in years
    ZZZ[year]=SqCCRMult[area1,year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)


  for tech in techs
    println(iob,AreaDS[area1], " ", TechDS[tech], " Historical Sequestering Energy Penalty (TBtu/Yr);;    ", join(Year[years], ";"))
    for ecc in eccs, ec in ECs
      if EC[ec] == ECC[ecc]
        print(iob,"xSqDmd;",ECCDS[ecc])
        for year in years
          ZZZ[year]=xSqDmd[tech,ec,area1,year]
          print(iob,";",@sprintf("%15.4f", ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Net Sequestering Non-Cogeneration Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"xSqPolCCNet;Total")
    for year in years
      ZZZ[year]=sum(xSqPolCCNet[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"xSqPolCCNet;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(xSqPolCCNet[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Sequestering Emissions Penalty Fraction (Tonne/Tonne);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"SqPenaltyFrac;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(SqPenaltyFrac[ecc,poll,area,year] for area in areas)
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaName, " ", PollDS[poll], " Gross Sequestering Non-Cogeneration Emissions (MT/Yr);;    ", join(Year[years], ";"))
    print(iob,"xSqPol;Total")
    for year in years
      ZZZ[year]=sum(xSqPol[ecc,poll,area,year] for area in areas, ecc in eccs)/1e6
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    for ecc in eccs
      print(iob,"xSqPol;",ECCDS[ecc])
      for year in years
        ZZZ[year]=sum(xSqPol[ecc,poll,area,year] for area in areas)/1e6
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for poll in polls
    println(iob,AreaDS[area1], " ", PollDS[poll], " Sequestering Fraction Captured Embedded (tonne/tonne);;    ", join(Year[years], ";"))
    for ecc in eccs
      print(iob,"SqReductionEm;",ECCDS[ecc])
      for year in years
        ZZZ[year]=SqReductionEm[ecc,poll,area1,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  println(iob,AreaDS[area1], " Exogenous Sequestering Cost Curve Price (2016 ",MoneyUnitDS[area1],"/Tonne CO2e);;    ", join(Year[years], "; "))
  for ecc in eccs
    print(iob,"xSqPrice;",ECCDS[ecc])
    for year in years
      ZZZ[year]=xSqPrice[ecc,area1,year]*Inflation[area1,Yr2016]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  CO2 = Select(Poll,"CO2")
  pcov = Select(PCov,"Energy")
  println(iob,AreaDS[area1], " Carbon Price Term in Sequestering Cost Curve Price (2016 ",MoneyUnitDS[area1],"/Tonne CO2e);;    ", join(Year[years], "; "))
  for ecc in eccs
    for year in years
      ZZZ[year]=(PCost[ecc,CO2,area1,year]*SqPGMult[ecc,CO2,area1,year]*ECoverage[ecc,CO2,pcov,area1,year]+
              PCostExo[ecc,CO2,area1,year])*Inflation[area1,Yr2016]
    end
    print(iob,"PCost Term;",ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # CCSLevels
  #
  if AreaName != "Canada"
    
    levels = collect(1:4)

    println(iob,"Number of Levels in the Sequestering Construction Delay (Number);;    ", join(Year[years], "; "))
    for ecc in eccs_ccs
      print(iob,"SqCDOrder;",ECCDS[ecc])
      for year in years
        ZZZ[year]=SqCDOrder[ecc,year]
        print(iob,";",@sprintf("%15.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  
    for ecc in eccs_ccs
      println(iob,AreaName, " ", ECCDS[ecc], " Input to Sequestering Construction Delay (MT/Yr/Yr);;    ", join(Year[years], "; "))
      for level in levels
        print(iob,"SqCDInput;","Level ",level)
        for year in years
          ZZZ[year]=SqCDInput[level,ecc,area1,year]/1e6
          print(iob,";",@sprintf("%15.4f", ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)

    for ecc in eccs_ccs
      println(iob,AreaName, " ", ECCDS[ecc], " Sequestering Construction Delay Level (MT/Yr);;    ", join(Year[years], "; "))
      for level in levels
        for year in years
          ZZZ[year]=SqCDLevel[level,ecc,area1,year]/1e6
        print(iob,"SqCDLevel;","Level ",level)
        end
        for year in years
          print(iob,";",@sprintf("%15.4f", ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)

    for ecc in eccs_ccs
      println(iob,AreaName, " ", ECCDS[ecc], " Output from Sequestering Construction Delay (MT/Yr/Yr);;    ", join(Year[years], "; "))
      for level in levels
        print(iob,"SqCDOutput;","Level ",level)
        for year in years
          ZZZ[year]=SqCDOutput[level,ecc,area1,year]/1e6
          print(iob,";",@sprintf("%15.4f", ZZZ[year]))
        end
        println(iob)
      end
    end
    println(iob)

  end

  filename = "Sequester-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function Sequester_DtaControl(db)


  @info "Sequester_DtaControl"
  data = SequesterData(; db)
  Area = data.Area
  AreaDS = data.AreaDS
  ECC = data.ECC
  Poll = data.Poll

  Area1 = Select(Area,"AB")
  Area2 = Select(Area,(from="ON", to="BC"))
  Area3 = Select(Area,(from="SK", to="NU"))
  areas = union(Area1,Area2,Area3)
  polls = Select(Poll,"CO2")
  eccs = Select(ECC,
   ["PulpPaperMills","Petrochemicals","IndustrialGas","OtherChemicals","Fertilizer",
    "Petroleum","Cement","IronSteel","Aluminum","OtherNonferrous",
    "HeavyOilMining","LightOilMining","SAGDOilSands","CSSOilSands",
    "OilSandsUpgraders","SweetGasProcessing","UnconventionalGasProduction",
    "SourGasProcessing","UtilityGen"]) 
  eccs_ccs = Select(ECC,"OilSandsUpgraders") 


  Sequester_DtaRun(data, areas, polls, eccs, eccs_ccs, "Canada", "CN")
  for area in areas
    Sequester_DtaRun(data, area, polls, eccs, eccs_ccs, AreaDS[area], Area[area])
  end

end


if abspath(PROGRAM_FILE) == @__FILE__
Sequester_DtaControl(DB)
end

