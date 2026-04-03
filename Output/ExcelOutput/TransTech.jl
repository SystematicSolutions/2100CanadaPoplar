#
# TransTech.jl
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
Base.@kwdef struct TransTechData
  db::String
  
  Age::SetArray = ReadDisk(db,"MainDB/AgeKey")
  AgeDS::SetArray = ReadDisk(db,"MainDB/AgeDS")
  Ages::Vector{Int} = collect(Select(Age))
  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  EC::SetArray = ReadDisk(db,"TInput/ECKey")
  ECDS::SetArray = ReadDisk(db,"TInput/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Tech::SetArray = ReadDisk(db,"TInput/TechKey")
  TechDS::SetArray = ReadDisk(db,"TInput/TechDS")
  Year::SetArray = ReadDisk(db,"MainDB/YearDS")  

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  AMSF::VariableArray{5} = ReadDisk(db, "TOutput/AMSF") #[Enduse,Tech,EC,Area,Year] Average Market Share ($/$)
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") #[Area,Nation] Map between Area and Nation
  CMSF::VariableArray{6} = ReadDisk(db, "TOutput/CMSF") #[Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Fraction by Device ($/$)
  CMSM0::VariableArray{6} = ReadDisk(db, "TCalDB/CMSM0") #[Enduse,Tech,CTech,EC,Area,Year] Conversion Market Share Fraction by Device ($/$)
  DAct::VariableArray{5} = ReadDisk(db, "TInput/DAct") #[Enduse,Tech,EC,Area,Year] Device Activity Level (Ton-Miles/Vehicle-Mile)
  DCC::VariableArray{5} = ReadDisk(db, "TOutput/DCC") #[Enduse,Tech,EC,Area,Year] Device Capital Cost ($/Mile/Yr)
  DCCR::VariableArray{5} = ReadDisk(db, "TOutput/DCCR") #[Enduse,Tech,EC,Area,Year] Device Capital Charge Rate (($/Yr)/$)
  DEE::VariableArray{5} = ReadDisk(db, "TOutput/DEE") #[Enduse,Tech,EC,Area,Year] Device Efficiency (Mile/mmBtu)
  DEEA::VariableArray{5} = ReadDisk(db, "TOutput/DEEA") #[Enduse,Tech,EC,Area,Year] Average Device Efficiency (Mile/mmBtu)
  DER::VariableArray{5} = ReadDisk(db, "TOutput/DER") #[Enduse,Tech,EC,Area,Year] Energy Requirement (mmBtu/Yr)
  DERA::VariableArray{5} = ReadDisk(db, "TOutput/DERA") #[Enduse,Tech,EC,Area,Year] Energy Requirement Addition (mmBtu/Yr)
  DERR::VariableArray{5} = ReadDisk(db, "TOutput/DERR") #[Enduse,Tech,EC,Area,Year] Device Energy Rqmt. Retire. (mmBtu/Yr/Yr)
  DEStd::VariableArray{5} = ReadDisk(db, "TInput/DEStd") #[Enduse,Tech,EC,Area,Year] Device Efficiency Standards (Btu/Btu)
  DEStdP::VariableArray{5} = ReadDisk(db, "TInput/DEStdP") #[Enduse,Tech,EC,Area,Year] Device Efficiency Standards Policy (Btu/Btu)
  Dmd::VariableArray{5} = ReadDisk(db, "TOutput/Dmd") #[Enduse,Tech,EC,Area,Year]  Total Energy Demand (TBtu/Yr)
  DmdFEPTech::VariableArray{5} = ReadDisk(db, "TOutput/DmdFEPTech") #[FuelEP,Tech,EC,Area,Year] Enduse Demands (TBtu/Yr)
  DPL::VariableArray{5} = ReadDisk(db, "TOutput/DPL") #[Enduse,Tech,EC,Area,Year]  Physical Life of Equipment (YRS)
  Driver::VariableArray{3} = ReadDisk(db, "MOutput/Driver") #[ECC,Area,Year]  Economic Driver (Various Millions/Yr)
  ECFP::VariableArray{5} = ReadDisk(db, "TOutput/ECFP") #[Enduse,Tech,EC,Area,Year]  Fuel Price ($/mmBtu)
  ECUF::VariableArray{3} = ReadDisk(db, "MOutput/ECUF") #[ECC,Area,Year]  Capital Utilization Fraction (Btu/Btu)
  EuPol::VariableArray{4} = ReadDisk(db, "SOutput/EuPol") #[ECC,Poll,Area,Year]  Energy Related Pollution (Tonnes/Yr)
  EUPC::VariableArray{6} = ReadDisk(db, "TOutput/EUPC") #[Enduse,Tech,Age,EC,Area,Year]  Production Capacity by Enduse (M$/Yr)
  EUPCA::VariableArray{6} = ReadDisk(db, "TOutput/EUPCA") #[Enduse,Tech,Age,EC,Area,Year]  Production Capacity Additions ((M$/Yr)/Yr)
  EUPCR::VariableArray{6} = ReadDisk(db, "TOutput/EUPCR") #[Enduse,Tech,Age,EC,Area,Year]  Production Capacity Retirement ((M$/Yr)/Yr)
  ExchangeRate::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRate") #[Area,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") #[Area,Year]  Inflation Index
  MCFU::VariableArray{5} = ReadDisk(db, "TOutput/MCFU") #[Enduse,Tech,EC,Area,Year]  Marginal Cost of Fuel Use ($/mmBtu)
  MMSF::VariableArray{5} = ReadDisk(db, "TOutput/MMSF") #[Enduse,Tech,EC,Area,Year]  Market Share Fraction by Device ($/$)
  MMSM0::VariableArray{5} = ReadDisk(db, "TCalDB/MMSM0") #[Tech,Area,Enduse,EC,Year] Non-price Factors. ($/$)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  PCC::VariableArray{5} = ReadDisk(db, "TOutput/PCC") #[Enduse,Tech,EC,Area,Year] Process Capital Cost ($/($/Yr))
  PCPL::VariableArray{3} = ReadDisk(db, "MInput/PCPL") #[ECC,Area,Year] Physical Life of Production Capacity (Years)
  PEE::VariableArray{5} = ReadDisk(db, "TOutput/PEE") #[Enduse,Tech,EC,Area,Year] Process Efficiency ($/Mile)
  PEEA::VariableArray{5} = ReadDisk(db, "TOutput/PEEA") #[Enduse,Tech,EC,Area,Year] Average Process Efficiency ($/Mile)
  PEPL::VariableArray{5} = ReadDisk(db, "TOutput/PEPL") #[Enduse,Tech,EC,Area,Year] Physical Life of Process Requirements (Years)
  PER::VariableArray{5} = ReadDisk(db, "TOutput/PER") #[Enduse,Tech,EC,Area,Year] Process Requirement (Miles/Yr)
  PERA::VariableArray{5} = ReadDisk(db, "TOutput/PERA") #[Enduse,Tech,EC,Area,Year] Process Energy Rqmt. Addition (Miles/YR/Yr)
  PERR::VariableArray{5} = ReadDisk(db, "TOutput/PERR") #[Enduse,Tech,EC,Area,Year] Process Energy Rqmt. Retire. (Miles/YR/Yr)
  POCA::VariableArray{7} = ReadDisk(db, "TOutput/POCA") #[Enduse,FuelEP,Tech,EC,Poll,Area,Year] Average Pollution Coefficients (Tonnes/TBtu)
  UMS::VariableArray{5} = ReadDisk(db, "TOutput/UMS") #[Enduse,Tech,EC,Area,Year] Short Term Price Response (Btu/Btu)
  VehicleRetire::VariableArray{5} = ReadDisk(db, "TOutput/VehicleRetire") #[Enduse,Tech,EC,Area,Year] Retirement of Vehicles (Vehicles)
  VehicleSales::VariableArray{5} = ReadDisk(db, "TOutput/VehicleSales") #[Enduse,Tech,EC,Area,Year] Total Sales of Vehicles (Vehicles)
  VehicleStock::VariableArray{5} = ReadDisk(db, "TOutput/VehicleStock") #[Enduse,Tech,EC,Area,Year] Stock of Vehicles (Vehicles)
  VDT::VariableArray{5} = ReadDisk(db, "TOutput/VDT") #[Enduse,Tech,EC,Area,Year] Vehicle Distance Traveled (Million Veh Pass-Miles or Ton-Miles/Yr)
  CERSM::VariableArray{4} = ReadDisk(db, "TCalDB/CERSM") #[Enduse,EC,Area,Year] Capital Energy Requirement (Btu/Btu)
  xDPL::VariableArray{5} = ReadDisk(db, "TInput/xDPL") #[Enduse,Tech,EC,Area,Year]  Physical Life of Equipment (Years)
  xMMSF::VariableArray{5} = ReadDisk(db, "TCalDB/xMMSF") #[Enduse,Tech,EC,Area,Year]  Exogenous Market Share Fraction by Device ($/$)
end
#

function TechSelect(data,eckey)
  (; EC,Tech) = data

  if eckey == "Passenger"
    techs = Select(Tech,(from="LDVGasoline", to="TrainFuelCell")) 
  elseif eckey == "Freight"
    techs_a =  Select(Tech,(from="TrainDiesel", to="MarineFuelCell"))  
    techs_b = Select(Tech,"OffRoad")
    techs = union(techs_a,techs_b)
  elseif eckey == "AirPassenger"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","OffRoad"])
  elseif eckey == "AirFreight"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","PlaneFuelCell","OffRoad"])
  elseif eckey == "ForeignPassenger"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","PlaneFuelCell","MarineLight","MarineHeavy","MarineFuelCell","OffRoad"])
  elseif eckey == "ForeignFreight"
    techs = Select(Tech,["PlaneJetFuel","PlaneGasoline","PlaneFuelCell","MarineLight","MarineHeavy","MarineFuelCell","OffRoad"])
  elseif eckey == "ResidentialOffRoad"
    techs = Select(Tech,"OffRoad")
  elseif eckey == "CommercialOffRoad"
    techs = Select(Tech,"OffRoad")
  else
    techs = Select(Tech)
  end

  return techs
end

function TransTech_DtaRun(data,areas,AreaName,AreaKey)
  (; Ages,Area,AreaDS,EC,ECDS,ECC,ECCDS,FuelEP,Poll,PollDS,Tech,TechDS,Year) = data
  (; CDTime,CDYear,SceName,AMSF,ANMap,CMSF,CMSM0,DAct,DCC,DCCR,DEE,DEEA,DER) = data
  (; DERA,DERR,DEStd,DEStdP,Dmd,DmdFEPTech,DPL,Driver) = data
  (; ECFP,ECUF,EuPol,EUPC,EUPCA,EUPCR,ExchangeRate) = data
  (; Inflation,MCFU,MMSF,MMSM0,MoneyUnitDS,PCC,PCPL) = data
  (; PEE,PEEA,PEPL,PER,PERA,PERR,POCA,UMS,VehicleRetire) = data
  (; VehicleSales,VehicleStock,VDT,CERSM,xDPL,xMMSF) = data
  
  Biodiesel = zeros(Float32, length(Year))
  Diesel = zeros(Float32, length(Year))
  Ethanol = zeros(Float32, length(Year))
  Gasoline = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))


  enduse = 1
  area_one = first(areas)
  # year = Select(Year, (from = "1990", to = "2050")) 
  years = collect(Yr(1990):Yr(2050))
 
  iob = IOBuffer() 

  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Total; for all geographical areas.")
  println(iob, "This is the Transportation Tech Outputs Summary.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")


  UnitDS::Vector{String} = fill("Invalid EC",length(EC))
  for ec in Select(EC,["Passenger","AirPassenger","ForeignPassenger","ResidentialOffRoad"])
    UnitDS[ec] = "Vehicle-Miles"
  end
  for ec in Select(EC,["Freight","AirFreight","ForeignFreight","CommercialOffRoad"])
    UnitDS[ec] = "Ton-Miles"
  end

  for ec in Select(EC)
    ecc = Select(ECC,EC[ec])
    techs = TechSelect(data,EC[ec])
    tech_one = first(techs)


    print(iob, AreaName, " Economic Driver (Various Units);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(Driver[ecc,area,year] for area in areas)
    end
    print(iob, "Driver;", ECCDS[ecc])
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Total Energy Demand (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas, tech in techs)
    end
    print(iob, "Dmd;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(Dmd[enduse,tech,ec,area,year] for area in areas)
      end
      print(iob, "Dmd;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Energy Requirement (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(DER[enduse,tech,ec,area,year]/1e6 for area in areas, tech in techs)
    end
    print(iob, "DER;Total")
    for year in years
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(DER[enduse,tech,ec,area,year]/1e6 for area in areas)
      end
      print(iob, "DER;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Process Energy Requirements (Million ", UnitDS[ec],"/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(PER[enduse,tech,ec,area,year]/1e6 for area in areas, tech in techs)
    end
    print(iob, "PER;Total")
    for year in years
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(PER[enduse,tech,ec,area,year]/1e6 for area in areas)
      end
      print(iob, "PER;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Production Capacity (M\$/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(EUPC[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in techs)
    end
    print(iob, "EUPC;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(EUPC[enduse,tech,age,ec,area,year] for area in areas, age in Ages)
      end
      print(iob, "EUPC;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Vehicle Stock (000 Vehicles);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(VehicleStock[enduse,tech,ec,area,year]/1000 for area in areas, tech in techs)
    end
    print(iob, "VehicleStock;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VehicleStock[enduse,tech,ec,area,year]/1000 for area in areas)
      end
      print(iob, "VehicleStock;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Energy Requirement Addition (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(DERA[enduse,tech,ec,area,year]/1e6 for area in areas, tech in techs)
    end
    print(iob, "DERA;Total")
    for year in years
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(DERA[enduse,tech,ec,area,year]/1e6 for area in areas)
      end
      print(iob, "DERA;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  
    print(iob, AreaName, " ",ECDS[ec]," Process Energy Rqmt. Addition (Million ", UnitDS[ec],"/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(PERA[enduse,tech,ec,area,year]/1e6 for area in areas, tech in techs)
    end
    print(iob, "PERA;Total")
    for year in years
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(PERA[enduse,tech,ec,area,year]/1e6 for area in areas)
      end
      print(iob, "PERA;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Production Capacity Additions (M\$/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(EUPCA[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in techs)
    end
    print(iob, "EUPCA;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(EUPCA[enduse,tech,age,ec,area,year] for area in areas, age in Ages)
      end
      print(iob, "EUPCA;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Vehicle Sales (000 Vehicles);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(VehicleSales[enduse,tech,ec,area,year]/1000 for area in areas, tech in techs)
    end
    print(iob, "VehicleSales;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VehicleSales[enduse,tech,ec,area,year]/1000 for area in areas)
      end
      print(iob, "VehicleSales;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  
    print(iob, AreaName, " ",ECDS[ec]," Energy Requirement Retirements (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(DERR[enduse,tech,ec,area,year]/1e6 for area in areas, tech in techs)
    end
    print(iob, "DERR;Total")
    for year in years
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(DERR[enduse,tech,ec,area,year]/1e6 for area in areas)
      end
      print(iob, "DERR;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  
    print(iob, AreaName, " ",ECDS[ec]," Process Energy Rqmt. Retirements (Million ", UnitDS[ec],"/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(PERR[enduse,tech,ec,area,year]/1e6 for area in areas, tech in techs)
    end
    print(iob, "PERR;Total")
    for year in years
      print(iob,";",@sprintf("%.f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(PERR[enduse,tech,ec,area,year]/1e6 for area in areas)
      end
      print(iob, "PERR;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%.f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  
    print(iob, AreaName, " ",ECDS[ec]," Production Capacity Retirements (M\$/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(EUPCR[enduse,tech,age,ec,area,year] for area in areas, age in Ages, tech in techs)
    end
    print(iob, "EUPCR;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(EUPCR[enduse,tech,age,ec,area,year] for area in areas, age in Ages)
      end
      print(iob, "EUPCR;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Vehicles Retired (000 Vehicles);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(VehicleRetire[enduse,tech,ec,area,year]/1000 for area in areas, tech in techs)
    end
    print(iob, "VehicleRetire;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VehicleRetire[enduse,tech,ec,area,year]/1000 for area in areas)
      end
      print(iob, "VehicleRetire;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Average Market Share Fraction (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = AMSF[enduse,tech,ec,area_one,year]
      end
      print(iob, "AMSF;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Marginal Market Share Fraction (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = MMSF[enduse,tech,ec,area_one,year]
      end
      print(iob, "MMSF;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.7f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    print(iob, AreaName, " ",ECDS[ec]," Exogenous Marginal Market Share Fraction (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = xMMSF[enduse,tech,ec,area_one,year]
      end
      print(iob, "xMMSF;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.7f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    

    print(iob, AreaName, " ",ECDS[ec]," Conversion Market Share Fraction (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      ctech = tech
      for year in years
        ZZZ[year] = CMSF[enduse,tech,ctech,ec,area_one,year]
      end
      print(iob, "CMSF;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
    
    print(iob, AreaName, " ",ECDS[ec]," Fuel Price ($CDTime ",MoneyUnitDS[area_one],"/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = ECFP[enduse,tech,ec,area_one,year]/Inflation[area_one,year]*Inflation[area_one,CDYear]
      end
      print(iob, "ECFP;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Marginal Cost of Fuel Use ($CDTime ",MoneyUnitDS[area_one],"/",UnitDS[ec],");")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = MCFU[enduse,tech,ec,area_one,year]/Inflation[area_one,year]*Inflation[area_one,CDYear]
      end
      print(iob, "MCFU;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Device Efficiency (",UnitDS[ec],"/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = DEE[enduse,tech_one,ec,area_one,year]
    end
    print(iob, "DEE;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(DEE[enduse,tech,ec,area,year] for area in areas)
      end
      print(iob, "DEE;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    if (EC[ec] == "Freight") || (EC[ec] == "AirFreight") || (EC[ec] == "ForeignFreight")
      print(iob, AreaName, " ",ECDS[ec]," Device Efficiency (Vehicle-Miles/mmBtu);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for year in years
        ZZZ[year] = DEE[enduse,tech_one,ec,area_one,year] ./ DAct[enduse,tech_one,ec,area_one,year]
      end
      print(iob, "DEE;Total")
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      for tech in techs
        for year in years
          ZZZ[year] = DEE[enduse,tech,ec,area_one,year] ./ DAct[enduse,tech,ec,area_one,year]
        end
        print(iob, "DEE;", TechDS[tech])
        for year in years
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end

    print(iob, AreaName, " ",ECDS[ec]," Average Device Efficiency (",UnitDS[ec],"/mmBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = DEEA[enduse,tech_one,ec,area_one,year]
    end
    print(iob, "DEEA;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(DEEA[enduse,tech,ec,area,year] for area in areas)
      end
      print(iob, "DEEA;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    if (EC[ec] == "Freight") || (EC[ec] == "AirFreight") || (EC[ec] == "ForeignFreight")
      print(iob, AreaName, " ",ECDS[ec]," Average Device Efficiency (Vehicle-Miles/mmBtu);")
      for year in years
        print(iob,";",Year[year])
      end
      println(iob)
      for year in years
        ZZZ[year] = DEEA[enduse,tech_one,ec,area_one,year] ./ DAct[enduse,tech_one,ec,area_one,year]
      end
      print(iob, "DEEA;Total")
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
      for tech in techs
        for year in years
          ZZZ[year] = DEEA[enduse,tech,ec,area_one,year] ./ DAct[enduse,tech,ec,area_one,year]
        end
        print(iob, "DEEA;", TechDS[tech])
        for year in years
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end
        println(iob)
      end
      println(iob)
    end

    print(iob, AreaName, " ",ECDS[ec]," Process Efficiency (Driver Units/Thousand ",UnitDS[ec],"/TBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = PEE[enduse,tech_one,ec,area_one,year]*1e9
    end
    print(iob, "PEE;Average")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = PEE[enduse,tech,ec,area_one,year]*1e9
      end
      print(iob, "PEE;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Average Process Efficiency (Driver Units/Thousand ",UnitDS[ec],"/TBtu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = PEEA[enduse,tech_one,ec,area_one,year]*1e9
    end
    print(iob, "PEEA;Average")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = PEEA[enduse,tech,ec,area_one,year]*1e9
      end
      print(iob, "PEEA;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Device Efficiency Standards (Btu/Btu);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = max(DEStd[enduse,tech,ec,area_one,year],DEStd[enduse,tech,ec,area_one,year])
      end
      print(iob, "Max Destd,DestdP;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Distance Traveled (Millions ",UnitDS[ec]," Traveled);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = sum(VDT[enduse,tech,ec,area,year] for area in areas, tech in techs)
    end
    print(iob, "VDT;Total")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = sum(VDT[enduse,tech,ec,area,year] for area in areas)
      end
      print(iob, "VDT;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Capital Costs (Nominal ",MoneyUnitDS[area_one],"/",UnitDS[ec],"/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = DCC[enduse,tech,ec,area_one,year]
      end
      print(iob, "DCC;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Marginal Market Share Non-Price Factors (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = MMSM0[enduse,tech,ec,area_one,year]
      end
      print(iob, "MMSM0;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Conversion Market Share Non-Price Factors (\$/\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      ctech = tech
      for year in years
        ZZZ[year] = CMSM0[enduse,tech,ctech,ec,area_one,year]
      end
      print(iob, "CMSM0;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Device Lifetime (Years);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = xDPL[enduse,tech,ec,area_one,year]
      end
      print(iob, "xDPL;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Device Lifetime (Years);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = DPL[enduse,tech,ec,area_one,year]
      end
      print(iob, "DPL;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Process Lifetime (Years);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = PEPL[enduse,tech,ec,area_one,year]
      end
      print(iob, "PEPL;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECCDS[ecc]," Production Capacity Lifetime (Years);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        ZZZ[year] = PCPL[ecc,area_one,year]
      end
      print(iob, "PCPL;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, AreaName, " ",ECDS[ec]," Vehicle Lifetime (Years);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for tech in techs
      for year in years
        y_prior=max(year-1,1)
        @finite_math ZZZ[year] = VehicleStock[enduse,tech,ec,area_one,y_prior] / VehicleRetire[enduse,tech,ec,area_one,year]
      end
      print(iob, "Lifetime;", TechDS[tech])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)


    print(iob, AreaName, " ",ECCDS[ecc]," Pollution Emitted (Kilotonnes/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for poll in Select(Poll)
      for year in years
        ZZZ[year] = sum(EuPol[ecc,poll,area,year]/1000 for area in areas)
      end
      print(iob, "EuPol;", PollDS[poll])
      for year in years
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)

    print(iob, "Inflation (1985=1);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = Inflation[area_one,year]
    end
    print(iob, "Inflation;Inflation")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)

    print(iob, "Local Currency/US\$ Exchange Rate (Local/US\$);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for year in years
      ZZZ[year] = ExchangeRate[area_one,year]
    end
    print(iob, "ExchangeRate;ExchangeRate")
    for year in years
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob)
  end

  #
  # GroundSummary
  #
  print(iob, AreaName, " Ground Fuel Summary Demand (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  ecs = Select(EC,["Passenger","Freight","ResidentialOffRoad","CommercialOffRoad"])

  #
  # Passenger Ethanol
  #
  ethanol = Select(FuelEP,"Ethanol")
  for year in years
    Ethanol[year] = sum(DmdFEPTech[fuelep,tech,ec,area,year] for area in areas, ec in ecs, tech in Select(Tech), fuelep in ethanol)
    ZZZ[year] = Ethanol[year]
  end
  print(iob, "DmdFEPTech;Ethanol")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Gasoline
  #
  gasoline = Select(FuelEP,"Gasoline")
  for year in years
    Gasoline[year] = sum(DmdFEPTech[fuelep,tech,ec,area,year] for area in areas, ec in ecs, tech in Select(Tech), fuelep in gasoline)
    ZZZ[year] = Gasoline[year]
  end
  print(iob, "DmdFEPTech;Gasoline")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Biodiesel
  #
  biodiesel = Select(FuelEP,"Biodiesel")
  for year in years
    Biodiesel[year] = sum(DmdFEPTech[fuelep,tech,ec,area,year] for area in areas, ec in ecs, tech in Select(Tech), fuelep in biodiesel)
    ZZZ[year] = Biodiesel[year]
  end
  print(iob, "DmdFEPTech;Biodiesel")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)

  #
  # Diesel
  #
  diesel = Select(FuelEP,"Diesel")
  for year in years
    Diesel[year] = sum(DmdFEPTech[fuelep,tech,ec,area,year] for area in areas, ec in ecs, tech in Select(Tech), fuelep in diesel)
    ZZZ[year] = Diesel[year]
  end
  print(iob, "DmdFEPTech;Diesel")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Ethanol and Biodiesel Fractions
  #
  print(iob, AreaName, " Ethanol and Biodiesel Fractions (Btu/Btu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for year in years
    @finite_math ZZZ[year] = Ethanol[year] / (Gasoline[year] + Ethanol[year])
  end
  print(iob, "Fraction;Ethanol")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  for year in years
    @finite_math ZZZ[year] = Biodiesel[year] / (Diesel[year] + Biodiesel[year])
  end
  print(iob, "Fraction;Biodiesel")
  for year in years
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "TransTech-$AreaKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function TransTech_DtaControl(db)
  @info "TransTech_DtaControl"  
  
  data = TransTechData(; db)
  (; db,Area,AreaDS)= data

  #
  # Canada 
  #
  areas = Select(Area, (from = "ON", to = "NU"))
  AreaName = "Canada"
  AreaKey = "CN"
  TransTech_DtaRun(data,areas,AreaName,AreaKey)
  
  #
  #  US
  #
  areas = Select(Area, (from = "CA", to = "Pac"))
  AreaName = "United States"
  AreaKey = "US"
  TransTech_DtaRun(data,areas,AreaName,AreaKey)
  
  #
  # Individual Areas
  #
  for areas in Select(Area)
    AreaName = AreaDS[areas]
    AreaKey = Area[areas]
    TransTech_DtaRun(data,areas,AreaName,AreaKey)
  end
  
  
end

if abspath(PROGRAM_FILE) == @__FILE__
TransTech_DtaControl(DB)
end

