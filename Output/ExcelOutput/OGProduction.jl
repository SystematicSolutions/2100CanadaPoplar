#
# OGProduction.jl
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


Base.@kwdef struct OGProductionData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}    = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray  = ReadDisk(db,"MainDB/ECCDS")
  ECCKey::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCs::Vector{Int}     = collect(Select(ECC))
  Fuel::SetArray   = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int}    = collect(Select(Fuel))
  FuelOG::SetArray = ReadDisk(db, "MainDB/FuelOGKey")
  FuelOGDS::SetArray = ReadDisk(db, "MainDB/FuelOGDS")
  FuelOGs::Vector{Int}    = collect(Select(FuelOG))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  Nations::Vector{Int}     = collect(Select(Nation))
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Process::SetArray = ReadDisk(db, "MainDB/ProcessKey")
  Processes::Vector{Int} = collect(Select(Process))
  ProcessDS::SetArray = ReadDisk(db, "MainDB/ProcessDS")
  Year::SetArray   = ReadDisk(db,"MainDB/YearDS")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") #[Nation,Year]  Inflation Index ($/$)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") #[Fuel,Nation,Year]  Primary Fuel Price ($/mmBtu)
  ExchangeRateNation::VariableArray{2} = ReadDisk(db, "MOutput/ExchangeRateNation") #[Nation,Year]  Local Currency/US$ Exchange Rate (Local/US$)
  GAProd::VariableArray{3} = ReadDisk(db, "SOutput/GAProd") #[Process,Area,Year]  Primary Gas Production (TBtu/Yr)
  OAProd::VariableArray{3} = ReadDisk(db, "SOutput/OAProd") #[Process,Area,Year]  Primary Oil Production (TBtu/Yr)
  OGENPN::VariableArray{3} = ReadDisk(db, "SpOutput/OGENPN") #[FuelOG,Nation,Year]  Wholesale Price used to compute Product Price ($/mmBtu)
  
  #
  # Scratch Variables
  #
  GAProdCum::VariableArray{3} = zeros(Float32,length(Process),length(Area),length(Year)) # [Process,Area,Year] Cumulative Gas Production (TBtu)
  OAProdCum::VariableArray{3} = zeros(Float32,length(Process),length(Area),length(Year)) # [Process,Area,Year] Cumulative Oil Production (TBtu)



end

function OGProduction_DtaRun(data,nations,areas,NationName,NationKey)
  (; AreaDS, Nation, Fuel, FuelOGDS, FuelOGs, Process, Processes,ProcessDS, Year) = data
  (; ENPN, GAProd,GAProdCum,OAProd,OAProdCum,OGENPN) = data
  (; InflationNation, ExchangeRateNation, CDTime, CDYear,SceName) = data
  KJBtu = 1.054615
  ZZZ = zeros(Float32, length(Year))
  years = collect(Yr(1990):Final)

  iob = IOBuffer()

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, " ")
  println(iob, "Oil and Gas Production in NEB Categories.")
  println(iob, " ")
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob, " ")

  print(iob, NationName, " Oil Wholesale Prices ($CDTime Local \$/mmBtu);")
  fuel = Select(Fuel, "LightCrudeOil")
  for year in years
    ZZZ[year] = ENPN[fuel,nations,year] /InflationNation[nations,year] * InflationNation[nations,CDYear]
    print(iob,";",Year[year])  
  end
  println(iob)
  print(iob, "ENPN;LightCrudeOil")
  for year in years
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  fuel = Select(Fuel, "HeavyCrudeOil")
  for year in years
    ZZZ[year] = ENPN[fuel,nations,year] /InflationNation[nations,year] * InflationNation[nations,CDYear]
  end
  print(iob, "ENPN;HeavyCrudeOil")
  for year in years
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  
  #
  # Natural Gas Wholesale Price (ENPN) ($CDTime Local \$/mmBtu)
  #
  println(iob)
  fuel = Select(Fuel, "NaturalGas")
  print(iob,NationName," Natural Gas Wholesale Price ($CDTime Local \$/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)  
    print(iob,"ENPN;NaturalGas")
    for year in years
      ZZZ[year] = ENPN[fuel,nations,year]/
                  InflationNation[nations,year]*InflationNation[nations,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
  println(iob)

  #
  # println(iob, "Oil Production (OAProd) (PJ/Yr);")
  #
  println(iob)
  OilExceptUpgraders = Select(Process,!=("OilSandsUpgraders"))
  print(iob,"Oil Production (PJ/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)  
  
  print(iob, "OAProd;", NationName)
  for year in years  
    ZZZ[year] = sum(OAProd[process,area,year]
                    for process in OilExceptUpgraders, area in areas)*KJBtu
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end  
  println(iob)
  
  for area in areas
    print(iob,"OAProd;",AreaDS[area])
    for year in years
      ZZZ[year] = sum(OAProd[process,area,year] for process in OilExceptUpgraders)*KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
  println(iob)
  end
  
  #
  # Oil Sands InSitu Production (OAProd) (PJ/Yr) template for shorter blocks
  #
  println(iob)
  OilSands = Select(Process, ["PrimaryOilSands","SAGDOilSands","CSSOilSands"])
  print(iob, "Oil Sands InSitu Production (PJ/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)  

  print(iob, "OAProd;", NationName)
  for year in years
    ZZZ[year] = sum(OAProd[process,area,year] for process in OilSands, area in areas) * KJBtu
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  for area in areas
    print(iob, "OAProd;", AreaDS[area])
    for year in years
      ZZZ[year] = sum(OAProd[process,area,year] for process in OilSands) * KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  
  #
  # Production (OAPROD) (PJ/Yr) template for longer blocks
  #
  println(iob)
  Oil = Select(Process, ["LightOilMining","HeavyOilMining","FrontierOilMining","PrimaryOilSands",
              "SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders","PentanesPlus","Condensates"])
  for process in Oil
    print(iob, ProcessDS[process], "Production (PJ/Yr);") 
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)

    print(iob, "OAProd;", NationName)
    for year in years  
      ZZZ[year] = sum(OAProd[process,area,year] for area in areas) * KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)

    for area in areas
      print(iob, "OAProd;", AreaDS[area])
      for year in years
        ZZZ[year] = OAProd[process,area,year] * KJBtu
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
    println(iob)
    end
  println(iob)
  end
  
  #
  # Natural Gas Production (GAProd) (PJ/Yr)
  #
  Gas = Select(Process, ["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction"])
  print(iob, "Natural Gas Production (PJ/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)  

  print(iob, "GAProd;", NationName)
  for year in years
    ZZZ[year] = sum(GAProd[process,area,year] for area in areas, process in Gas) * KJBtu
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  
  for area in areas
    print(iob, "GAProd;", AreaDS[area])
    for year in years
      ZZZ[year] = sum(GAProd[process,area,year] for process in Gas)* KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end

  #
  # (Production) (GAPod) (PJ/Yr)
  #
  println(iob)
  Gas = Select(Process, ["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction",
              "SweetGasProcessing","SourGasProcessing","LNGProduction"])
  for process in Gas
    print(iob, ProcessDS[process], " (PJ/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)  
    
    print(iob, "GAProd;", NationName)
    for year in years
      ZZZ[year] = sum(GAProd[process,area,year] for area in areas) * KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)

    for area in areas
      print(iob, "GAProd;", AreaDS[area])
      for year in years
        ZZZ[year] = GAProd[process,area,year] * KJBtu
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
    println(iob)
    end
  println(iob)
  end

  #
  # Cumulative Production (since 1990)
  #
  year = Yr(1990)
  for area in areas, process in Processes
    OAProdCum[process,area,year] = OAProd[process,area,year]
    GAProdCum[process,area,year] = GAProd[process,area,year]
  end
  year = collect(Yr(1990):Final)
  for year in years,area in areas, process in Processes
    OAProdCum[process,area,year] = OAProdCum[process,area,year-1]+OAProd[process,area,year]
    GAProdCum[process,area,year] = GAProdCum[process,area,year-1]+GAProd[process,area,year] 
  end
 
  #
  # Cumulative Oil Production (OAProdCum) (PJ/Yr)
  #
  OilExceptUpgraders = Select(Process, !=("OilSandsUpgraders"))
  print(iob,"Cumulative Oil Production (PJ/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "OAProdCum;", NationName)
  for year in years
    ZZZ[year] = sum(OAProdCum[process,area,year] for process in OilExceptUpgraders, area in areas)*KJBtu
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  for area in areas
    print(iob, "OAProdCum;", AreaDS[area])
    for year in years
      ZZZ[year] = sum(OAProdCum[process,area,year] for process in OilExceptUpgraders)*KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  
  #
  # Cumulative Oil Sands InSitu Production (OAProdcum) (PJ/Yr)
  #
  println(iob)
  print(iob,"Cumulative Oil Sands InSitu Production (PJ/Yr);")
  OilSands = Select(Process, ["PrimaryOilSands","SAGDOilSands","CSSOilSands"])
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
    
  print(iob, "OAProdCum;", NationName)
  for year in years
    ZZZ[year] = sum(OAProdCum[process, area, year] for process in OilSands, area in areas)*KJBtu
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  for area in areas
    print(iob, "OAProdCum;", AreaDS[area])
    for year in years
      ZZZ[year] = sum(OAProdCum[process,area,year] for process in OilSands)*KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end

  #
  # Cumulative Production (OAProdCum) (PJ/Yr)
  #
  println(iob)
  Oil = Select(Process, ["LightOilMining","HeavyOilMining","FrontierOilMining","PrimaryOilSands",
              "SAGDOilSands","CSSOilSands","OilSandsMining","OilSandsUpgraders","PentanesPlus","Condensates"])
  for process in Oil
    print(iob, ProcessDS[process], " Cumulative Production (PJ/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    
    print(iob, "OAProdCum;", NationName)
    for year in years
      ZZZ[year] = sum(OAProdCum[process,area,year] for area in areas)*KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)

    for area in areas
      print(iob, "OAProdCum;", AreaDS[area])
      for year in years
        ZZZ[year] = (OAProdCum[process,area,year]*KJBtu)
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end
  
  #
  # Cumulative Natural Gas Production (GAProdCum) (PJ/Yr)
  #
  Gas = Select(Process, ["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction"])
  print(iob, "Cumulative Natural Gas Production (PJ/Yr);")
  for year in years  
    print(iob,";",Year[year])
  end
  println(iob)

  print(iob, "GAProdCum;", NationName)
  for year in years
    ZZZ[year] = sum(GAProdCum[process,area,year] for area in areas, process in Gas)*KJBtu
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  for area in areas
    print(iob, "GAProdCum;", AreaDS[area])
    for year in years
      ZZZ[year] = sum(GAProdCum[process,area,year] for process in Gas)*KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end

  #
  # Cumulative (GAProdCum) (PJ/Yr)
  #
  println(iob)
  Gas = Select(Process, ["ConventionalGasProduction","UnconventionalGasProduction","AssociatedGasProduction",
              "SweetGasProcessing","SourGasProcessing","LNGProduction"])
  for process in Gas
    print(iob,"Cumulative ", ProcessDS[process], " (PJ/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    
    print(iob, "GAProdCum;", NationName)
    for year in years
      ZZZ[years] = sum(GAProdCum[process, area, years] for area in areas)*KJBtu
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)

    for area in areas
      print(iob, "GAProdCum;", AreaDS[area])
      for year in years
        ZZZ[year] = GAProdCum[process,area,year]*KJBtu
        print(iob,";",@sprintf("%.6f",ZZZ[year]))
      end
    println(iob)
    end
  println(iob)
  end
  
  #
  print(iob, NationName, " Wholesale Prices ($CDTime Local \$/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuelOG in FuelOGs
    print(iob, "OGENPN;",FuelOGDS[fuelOG])
    for year in years
      ZZZ[year] = OGENPN[fuelOG,nations,year] /InflationNation[nations,year] * InflationNation[nations,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  US = Select(Nation,"US")
  print(iob, NationName, "Wholesale Prices ($CDTime US\$/mmBtu);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuelOG in FuelOGs  
    print(iob, "OGENPN;",FuelOGDS[fuelOG])
    for year in years
      ZZZ[year] = OGENPN[fuelOG,nations,year] /ExchangeRateNation[nations,year] /InflationNation[US,year] * InflationNation[US,CDYear]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  print(iob, NationName, " Wholesale Prices (Nominal Local \$/mmBtu);")
  US = Select(Nation,"US")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for fuelOG in FuelOGs
    print(iob, "OGENPN;",FuelOGDS[fuelOG])
    for  year in years
      ZZZ[year] = OGENPN[fuelOG,nations,year]
      print(iob,";",@sprintf("%.6f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)
  
  #
  print(iob, NationName, " Oil Wholesale Prices ($CDTime US\$/mmBtu);")
  US = Select(Nation,"US")
  fuel = Select(Fuel, "LightCrudeOil")
  for year in years
    ZZZ[year] = ENPN[fuel,nations,year]*InflationNation[nations,year]/ExchangeRateNation[nations,year]/InflationNation[US,year]*InflationNation[US,CDYear]
    print(iob,";",Year[year])  
  end
  println(iob)
  print(iob, "ENPN;LightCrudeOil")
  for year in years
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  fuel = Select(Fuel, "HeavyCrudeOil")
  for year in years
    ZZZ[year] = ENPN[fuel,nations,year]*InflationNation[nations,year]/ExchangeRateNation[nations,year]/InflationNation[US,year]*InflationNation[US,CDYear]
  end
  println(iob)
  print(iob, "ENPN;HeavyCrudeOil")
  for year in years
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  
  #
  println(iob)
  print(iob, NationName, " Natural Gas Wholesale Price ($CDTime US\$/mmBtu);")
  US = Select(Nation,"US")
  fuel = Select(Fuel, "NaturalGas")
  for year in years
    print(iob,";",Year[year])
  end  
  println(iob)
  for year in years
    ZZZ[year] = ENPN[fuel,nations,year]*InflationNation[nations,year]/ExchangeRateNation[nations,year]/InflationNation[US,year]*InflationNation[US,CDYear]
  end
  print(iob, "ENPN;NaturalGas")
  for year in years
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  #
  println(iob)
  print(iob, "US Inflation (\$/Real \$);")
  US = Select(Nation,"US")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "InflationUS;Inflation")
  for year in years  
    ZZZ[year] = InflationNation[US,year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)
  
  #
  println(iob)
  print(iob, NationName, " Inflation (\$/Real \$);")  
  for year in years 
    print(iob,";",Year[year])
  end
  println(iob) 
  print(iob, "InflationNation;Inflation") 
  for year in years
    ZZZ[year] = InflationNation[nations,year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  #
  println(iob)
  print(iob, NationName, " Exchange Rate (Local\$/US\$);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob) 
  print(iob, "ExchangeRateNation;Exchange Rate")
  for year in years 
    ZZZ[year] = ExchangeRateNation[nations,year]
    print(iob,";",@sprintf("%.6f",ZZZ[year]))
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "OGProduction-$NationKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function OGProduction_DtaControl(db)
  @info "OGProduction_DtaControl"
  data = OGProductionData(; db)
  (; Nation, Area) = data
  #
  # Canada
  #
  nations = Select(Nation, "CN")
  areas = Select(Area, (from = "ON", to = "NU"))
  NationName = "Canada"
  NationKey= "CN"
  OGProduction_DtaRun(data,nations,areas,NationName,NationKey)

  #
  #  US
  #
  nations = Select(Nation, "US")
  areas = Select(Area, (from = "CA", to = "Pac"))
  NationName = "United States"
  NationKey= "US"
  OGProduction_DtaRun(data,nations,areas,NationName,NationKey)

  #
  #  MX
  #
  nations = Select(Nation, "MX")
  areas = Select(Area, "MX")
  NationName = "Mexico"
  NationKey= "MX"
  OGProduction_DtaRun(data,nations,areas,NationName,NationKey)

end

if abspath(PROGRAM_FILE) == @__FILE__
OGProduction_DtaControl(DB)
end
