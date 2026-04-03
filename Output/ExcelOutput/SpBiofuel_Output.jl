#
# SpBiofuel_Output.jl
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

Base.@kwdef struct SpBiofuel_OutputData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Biofuel::SetArray = ReadDisk(db,"MainDB/BiofuelKey")
  BiofuelDS::SetArray = ReadDisk(db,"MainDB/BiofuelDS")
  Biofuels::Vector{Int} = collect(Select(Biofuel))
  Feedstock::SetArray = ReadDisk(db,"MainDB/FeedstockKey")
  FeedstockDS::SetArray = ReadDisk(db,"MainDB/FeedstockDS")
  Feedstocks::Vector{Int} = collect(Select(Feedstock))
  Fuel::SetArray = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  FuelEP::SetArray = ReadDisk(db,"MainDB/FuelEPKey")
  FuelEPDS::SetArray = ReadDisk(db,"MainDB/FuelEPDS")
  FuelEPs::Vector{Int} = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"SInput/TechKey")
  TechDS::SetArray = ReadDisk(db,"SInput/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db, "MainDB/YearDS")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  
  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation

  BfCap::VariableArray{5} = ReadDisk(db,"SpOutput/BfCap") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capacity (TBtu/Yr)
  BfCapCR::VariableArray{5} = ReadDisk(db,"SpOutput/BfCapCR") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capacity Completion Rate (TBtu/Yr)
  BfCapI::VariableArray{5} = ReadDisk(db,"SpOutput/BfCapI") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Indicated Production Capacity (TBtu/Yr)
  BfCapRR::VariableArray{5} = ReadDisk(db,"SpOutput/BfCapRR") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Capacity Retirement Rate (TBtu/Yr)
 
  BfDem::VariableArray{3} = ReadDisk(db,"SpOutput/BfDem") #[Biofuel,Area,Year]  Demand for Biofuel (TBtu/Yr)
  BfDemand::VariableArray{5} = ReadDisk(db,"SpOutput/BfDemand") #[Fuel,Biofuel,Feedstock,Area,Year]  Biofuel Production Energy Usage (TBtu/Yr)
  BfEff::VariableArray{5} = ReadDisk(db,"SpInput/BfEff") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production Energy Efficiency (Btu/Btu)
  BfENPN::VariableArray{3} = ReadDisk(db,"SpOutput/BfENPN") #[Biofuel,Nation,Year]  Biofuel Wholesale Price ($/mmBtu)

  BfFsReq::VariableArray{5} = ReadDisk(db,"SpOutput/BfFsReq") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Feedstock Required (Tonnes/Year)
  BfFsPrice::VariableArray{3} = ReadDisk(db,"SpInput/BfFsPrice") #[Feedstock,Area,Year]  Biofuel Feedstock Price ($/Tonne)
  BfFsYield::VariableArray{5} = ReadDisk(db,"SpInput/BfFsYield") # [Biofuel,Tech,Feedstock,Area,Year] Biofuel Yield From Feedstock (Btu/Tonne)

  BfPol::VariableArray{5} = ReadDisk(db,"SpOutput/BfPol") #[FuelEP,Biofuel,Poll,Area,Year]  Biofuel Production Pollution (Tonnes/Yr)
  BfProd::VariableArray{5} = ReadDisk(db,"SpOutput/BfProd") #[Biofuel,Tech,Feedstock,Area,Year]  Biofuel Production (TBtu/Yr)
  BfProdNation::VariableArray{3} = ReadDisk(db,"SpOutput/BfProdNation") #[Biofuel,Nation,Year]  Biofuel Production (TBtu/Yr)

  Exports::VariableArray{3} = ReadDisk(db,"SpOutput/Exports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  Imports::VariableArray{3} = ReadDisk(db,"SpOutput/Imports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
 
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  InflationNation::VariableArray{2} = ReadDisk(db,"MOutput/InflationNation") # [Nation,Year] Inflation Index ($/$)
  PolConv::VariableArray{1} = ReadDisk(db,"SInput/PolConv") # [Poll] Pollution Conversion Factor (convert GHGs to eCO2)



end

function SpBiofuel_Output_DtaRun(data, areas, areakey, areaname, nation)
  (; SceName,Area,AreaDS,Areas,Biofuel,BiofuelDS,Biofuels,Feedstock) = data
  (; FeedstockDS,Feedstocks,Fuel,FuelDS,Fuels,FuelEP,FuelEPDS,FuelEPs) = data
  (; Nation,NationDS,Nations,Poll,PollDS,Polls,Tech,TechDS,Techs,Year) = data
  (; CDTime,CDYear,ANMap,BfCap,BfCapCR,BfCapI,BfCapRR,BfDem,BfDemand,BfEff) = data
  (; BfENPN,BfFsReq,BfFsPrice,BfFsYield,BfPol,BfProd,BfProdNation,Exports) = data
  (; Imports,Inflation,InflationNation,PolConv) = data  
  
  SSS = zeros(Float32, length(Year))
  TTT = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))

  years = collect(Yr(1990):Final)
  area_single=first(areas)
  
  iob = IOBuffer()

  println(iob)
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$areaname; is the Area name.")
  println(iob, "This file was produced by SpBiofuel_Output.jl")
  println(iob)
  println(iob, "Year;", ";", join(Year[years], ";"))
  println(iob)

  #
  # BfENPN(Biofuel,Nation,Year)     'Biofuel Wholesale Price ($/mmBtu)'
  #
  print(iob,"$(NationDS[nation]) Biofuel Wholesale Price ($CDTime Local \$/mmBtu);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfENPN;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = BfENPN[biofuel,nation,year]*InflationNation[nation,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  # BfDem(Biofuel,Area,Year)     'Biofuel Demand (TBtu/Yr)'
  #
  print(iob,areaname," Biofuel Demand (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfDem;Total")
  for year in years  
    ZZZ[year] = sum(BfDem[biofuel,area,year] for area in areas, biofuel in Biofuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfDem;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = sum(BfDem[biofuel,area,year] for area in areas)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  # BfProd(Biofuel,Tech,Feedstock,Area,Year)  'Biofuel Production (TBtu/Yr)
  #
  print(iob,areaname," Biofuel Production (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfProd;Total")
  for year in years  
    ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfProd;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  fueleps=Select(FuelEP,["Ethanol","Biodiesel"])
  print(iob,"$(NationDS[nation]) Biofuel Imports (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for fuelep in fueleps
    print(iob, "Imports;$(FuelEPDS[fuelep])")
    for year in years  
      ZZZ[year] = Imports[fuelep,nation,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  fueleps=Select(FuelEP,["Ethanol","Biodiesel"])
  print(iob,"$(NationDS[nation]) Biofuel Exports (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for fuelep in fueleps
    print(iob, "Exports;$(FuelEPDS[fuelep])")
    for year in years  
      ZZZ[year] = Exports[fuelep,nation,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  # BfDemand(Fuel,Biofuel,Feedstock,Area,Year)   'Biofuel Production Energy Usage (TBtu/Yr)'
  #
  for biofuel in Biofuels
    print(iob,areaname," $(BiofuelDS[biofuel]) Production Energy Usage (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "BfDemand;Total")
    for year in years  
      ZZZ[year] = sum(BfDemand[fuel,biofuel,feedstock,area,year] for area in areas, feedstock in Feedstocks, fuel in Fuels)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      TTT[year] = ZZZ[year]
      SSS[year] = 0
    end    
    println(iob)
    fuels=Select(Fuel,["Electric","NaturalGas","Steam"])
    for fuel in fuels
      print(iob, "BfDemand;Total")
      for year in years  
        ZZZ[year] = sum(BfDemand[fuel,biofuel,feedstock,area,year] for area in areas, feedstock in Feedstocks)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        SSS[year] = SSS[year] + ZZZ[year]
      end    
      println(iob)
    end
    print(iob, "BfDemand;Other")
    for year in years 
      ZZZ[year] = TTT[year] - SSS[year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
    println(iob)
  end
  
  #
  # BfPol(FuelEP,Biofuel,Poll,Area,Year)    'Biofuel Production Pollution (Tonnes/Yr)'
  #
  polls=Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  print(iob,areaname," Biofuel GHG Production Pollution (Kilotonnes eCO2);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfPol;Total")
  for year in years  
    ZZZ[year] = sum(BfPol[fuelep,biofuel,poll,area,year] for area in areas, poll in polls, biofuel in Biofuels, fuelep in FuelEPs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfPol;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = sum(BfPol[fuelep,biofuel,poll,area,year] for area in areas, poll in polls, fuelep in FuelEPs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  # BfFsPrice(Feedstock,Area,Year)    'Biofuel Feedstock Price ($/Tonne)'
  #
  print(iob,areaname," Biofuel Feedstock Price ($CDTime Local \$/Tonne);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  for feedstock in Feedstocks
    print(iob, "BfFsPrice;$(FeedstockDS[feedstock])")
    for year in years  
      @finite_math ZZZ[year]=sum(BfFsPrice[feedstock,area,year]*BfFsReq[biofuel,tech,feedstock,area,year] for area in areas, tech in Techs, biofuel in Biofuels)/
          sum(BfFsReq[biofuel,tech,feedstock,area,year] for area in areas, tech in Techs, biofuel in Biofuels)*Inflation[area_single,CDYear]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  # 
  print(iob,areaname," Biofuel Production Capacity (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfCap;Total")
  for year in years  
    ZZZ[year] = sum(BfCap[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfCap;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = sum(BfCap[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  print(iob,areaname," Biofuel Production Capacity (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfCUF;Total")
  for year in years  
    @finite_math ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)/
        sum(BfCap[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfCUF;$(BiofuelDS[biofuel])")
    for year in years  
      @finite_math ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)/
          sum(BfCap[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  print(iob,areaname," Biofuel Production Indicated Capacity (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfCapI;Total")
  for year in years  
    ZZZ[year] = sum(BfCapI[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfCapI;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = sum(BfCapI[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  print(iob,areaname," Biofuel Production Capacity Completed (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfCapCR;Total")
  for year in years  
    ZZZ[year] = sum(BfCapCR[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfCapCR;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = sum(BfCapCR[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  print(iob,areaname," Biofuel Production Capacity Retired (TBtu/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfCapRR;Total")
  for year in years  
    ZZZ[year] = sum(BfCapRR[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs, biofuel in Biofuels)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for biofuel in Biofuels
    print(iob, "BfCapRR;$(BiofuelDS[biofuel])")
    for year in years  
      ZZZ[year] = sum(BfCapRR[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)
  
  #
  # BfProd(Biofuel,Tech,Feedstock,Area,Year)  'Biofuel Production (TBtu/Yr)
  #
  for biofuel in Biofuels
    print(iob,areaname," $(BiofuelDS[biofuel]) Production (TBtu/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "BfProd;Total")
    for year in years  
      ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
    for feedstock in Feedstocks
      print(iob, "BfProd;$(FeedstockDS[feedstock])")
      for year in years  
        ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, tech in Techs)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end    
      println(iob)
    end
    println(iob)
  end

  #
  # BfProd(Biofuel,Tech,Feedstock,Area,Year)  'Biofuel Production (TBtu/Yr)
  #
  for biofuel in Biofuels
    for feedstock in Feedstocks
      print(iob,areaname," $(BiofuelDS[biofuel]) Production from $(FeedstockDS[feedstock]) (TBtu/Yr);")
      for year in years  
        print(iob,";",Year[year])
      end
      println(iob)
      print(iob, "BfProd;Total")
      for year in years  
        ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas, tech in Techs)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end    
      println(iob)
      for tech in Techs
        print(iob, "BfProd;$(TechDS[tech])")
        for year in years  
          ZZZ[year] = sum(BfProd[biofuel,tech,feedstock,area,year] for area in areas)
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end    
        println(iob)
      end
      println(iob)
    end
  end

  #
  # BfDemand 'Biofuel Production Energy Usage (TBtu/Yr)'
  #
  for biofuel in Biofuels
    for feedstock in Feedstocks
      print(iob,areaname," $(BiofuelDS[biofuel]) $(FeedstockDS[feedstock]) Production Energy Usage (TBtu/Yr);")
      for year in years  
        print(iob,";",Year[year])
      end
      println(iob)
      print(iob, "BfDemand;Total")
      for year in years  
        ZZZ[year] = sum(BfDemand[fuel,biofuel,feedstock,area,year] for area in areas, fuel in Fuels)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        TTT[year] = ZZZ[year]
        SSS[year] = 0
      end    
      println(iob)
      fuels=Select(Fuel,["Electric","NaturalGas","Steam"])
      for fuel in fuels
        print(iob, "BfDemand;Total")
        for year in years  
          ZZZ[year] = sum(BfDemand[fuel,biofuel,feedstock,area,year] for area in areas)
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
          SSS[year] = SSS[year] + ZZZ[year]
        end    
        println(iob)
      end
      print(iob, "BfDemand;Other")
      for year in years 
        ZZZ[year] = TTT[year] - SSS[year]
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end    
      println(iob)
      println(iob)
    end
  end

  #
  # BfPol(FuelEP,Biofuel,Poll,Area,Year)    'Biofuel Production Pollution (Tonnes/Yr)'
  #
  # Select Poll(CO2,CH4,N2O,SF6,PFC,HFC)
  polls=Select(Poll,["CO2","CH4","N2O","SF6","PFC","HFC"])
  print(iob,areaname," Biofuel GHG Production Pollution (Kilotonnes eCO2);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "BfPol;Total")
  for year in years  
    ZZZ[year] = sum(BfPol[fuelep,biofuel,poll,area,year] for area in areas, poll in polls, biofuel in Biofuels, fuelep in FuelEPs)
    print(iob,";",@sprintf("%15.4f",ZZZ[year]))
  end    
  println(iob)
  for fuelep in FuelEPs
    print(iob, "BfPol;$(FuelEPDS[fuelep])")
    for year in years  
      ZZZ[year] = sum(BfPol[fuelep,biofuel,poll,area,year] for area in areas, poll in polls, biofuel in Biofuels)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
  end
  println(iob)

  #
  # BfFsReq(Biofuel,Tech,Feedstock,Area,Year)   'Biofuel Feedstock Required (Tonnes/Year)'
  #
  for biofuel in Biofuels
    print(iob,areaname," $(BiofuelDS[biofuel]) Feedstock Required (Tonnes/Yr);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "BfFsReq;Total")
    for year in years  
      ZZZ[year] = sum(BfFsReq[biofuel,tech,feedstock,area,year] for area in areas, feedstock in Feedstocks, tech in Techs)
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end    
    println(iob)
    for feedstock in Feedstocks
      print(iob, "BfFsReq;$(FeedstockDS[feedstock])")
      for year in years  
        ZZZ[year] = sum(BfFsReq[biofuel,tech,feedstock,area,year] for area in areas, tech in Techs)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end    
      println(iob)
    end
    println(iob)
  end

  #
  # BfFsReq(Biofuel,Tech,Feedstock,Area,Year)   'Biofuel Feedstock Required (Tonnes/Year)'
  #
  for biofuel in Biofuels
    for feedstock in Feedstocks
      print(iob,areaname," $(FeedstockDS[feedstock]) Feedstock Required for $(BiofuelDS[biofuel]) Production (Tonnes/Yr);")
      for year in years  
        print(iob,";",Year[year])
      end
      println(iob)
      print(iob, "BfFsReq;Total")
      for year in years  
        ZZZ[year] = sum(BfFsReq[biofuel,tech,feedstock,area,year] for area in areas, tech in Techs)
        print(iob,";",@sprintf("%15.4f",ZZZ[year]))
      end    
      println(iob)
      for tech in Techs
        print(iob, "BfFsReq;$(TechDS[tech])")
        for year in years  
          ZZZ[year] = sum(BfFsReq[biofuel,tech,feedstock,area,year] for area in areas)
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end    
        println(iob)
      end
      println(iob)
    end
  end

  #
  # BfFsYield(Biofuel,Tech,Feedstock,Area,Year) 'Biofuel Yield From Feedstock (Btu/Tonne)'
  #
  for biofuel in Biofuels
    print(iob,areaname," $(BiofuelDS[biofuel]) Feedstock Yield (Btu/Tonne);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for feedstock in Feedstocks
      for tech in Techs
        print(iob, "BfFsYield;$(FeedstockDS[feedstock]) $(TechDS[tech])")
        for year in years  
          ZZZ[year] = sum(BfFsYield[biofuel,tech,feedstock,area,year] for area in areas)
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end    
        println(iob)
      end
    end
    println(iob)
  end

  #
  # BfEff(Biofuel,Tech,Feedstock,Area,Year)     'Biofuel Production Energy Efficiency (Btu/Btu)',
  #
  for biofuel in Biofuels
    print(iob,areaname," $(BiofuelDS[biofuel]) Production Energy Efficiency (Btu/Btu);")
    for year in years  
      print(iob,";",Year[year])
    end
    println(iob)
    for feedstock in Feedstocks
      for tech in Techs
        print(iob, "BfEff;$(FeedstockDS[feedstock]) $(TechDS[tech])")
        for year in years  
          ZZZ[year] = sum(BfEff[biofuel,tech,feedstock,area,year] for area in areas)
          print(iob,";",@sprintf("%15.4f",ZZZ[year]))
        end    
        println(iob)
      end
    end
    println(iob)
  end

  filename = "SpBiofuel-$areakey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function SpBiofuel_Output_DtaControl(db)

  @info "SpBiofuel_Output_DtaControl"
  data = SpBiofuel_OutputData(; db)
  (; ANMap, Area, AreaDS, Areas, Nation, NationDS) = data

  CN=Select(Nation,"CN")
  areas=Select(Area,["AB","ON","QC","BC","MB","SK","NB","NS","NL","PE","YT","NT","NU"])
  for area in areas
    areaname = AreaDS[area]
    areakey = Area[area]
    SpBiofuel_Output_DtaRun(data, area, areakey, areaname, CN)
  end
  areaname=NationDS[CN]
  areakey = Nation[CN]
  SpBiofuel_Output_DtaRun(data, areas, areakey, areaname, CN)

  #
  US=Select(Nation,"US")
  areas=findall(ANMap[Areas,US] .== 1)
  for area in areas
    areaname = AreaDS[area]
    areakey = Area[area]
    SpBiofuel_Output_DtaRun(data, area, areakey, areaname, US)
  end
  areaname=NationDS[US]
  areakey = Nation[US]
  SpBiofuel_Output_DtaRun(data, areas, areakey, areaname, US)

end

if abspath(PROGRAM_FILE) == @__FILE__
SpBiofuel_Output_DtaControl(DB)
end


