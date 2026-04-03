#
# Prices.jl
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

Base.@kwdef struct PricesData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db, "MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db, "MainDB/ECCDS")
  ES::SetArray = ReadDisk(db, "MainDB/ESKey")
  ESDS::SetArray = ReadDisk(db, "MainDB/ESDS")
  ESs::Vector{Int} = collect(Select(ES))
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db, "MainDB/FuelDS")
  Fuels::Vector{Int} = collect(Select(Fuel))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")
  Years::Vector{Int} = collect(Select(Year))

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)
  ENPN::VariableArray{3} = ReadDisk(db, "SOutput/ENPN") #[Fuel,Nation,Year]  Wholesale Price ($/mmBtu)
  FPF::VariableArray{4} = ReadDisk(db, "SOutput/FPF") #[Fuel,ES,Area,Year]  Fuel Price ($/mmBtu)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") #[Area,Year]  Inflation Index
  InflationNation::VariableArray{2} = ReadDisk(db, "MOutput/InflationNation") #[Nation,Year]  Inflation Index
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  xENPN::VariableArray{3} = ReadDisk(db, "SInput/xENPN") # [Fuel,Nation,Year] Exogenous Primary Fuel Price ($/mmBtu)
  xFPF::VariableArray{4} = ReadDisk(db, "SInput/xFPF") #[Fuel,ES,Area,Year]  Fuel Price ($/mmBtu)

  #
  # Scratch Variables
  #
  ZZZ = zeros(Float32,length(Year))
end

function Prices_DtaRun(data,fuel)
  (; SceName,Area,AreaDS,Areas,ECC,ES,ESDS,ESs,Fuel,FuelDS,Nation,NationDS,Nations,Year) = data
  (; CDTime,CDYear,ENPN,FPF,Inflation,InflationNation) = data
  (; MoneyUnitDS,xENPN,xFPF,ZZZ) = data

  CDYear = max(CDYear,1)
  FuelName = FuelDS[fuel]
  years = collect(Yr(1985):Final)

  iob = IOBuffer()

  println(iob)
  println(iob,"$SceName; is the scenario name.")
  println(iob)
  println(iob,"This is the Prices Summary for ",FuelName)
  println(iob)

  println(iob,"Year;;",join(Year[years],";"))
  println(iob)

  #print(iob,FuelName," Primary Fuel Price ($CDTime ",MoneyUnitDS[area],"/mmBtu));")
  print(iob,FuelName," Primary Fuel Price ($CDTime CN\$/mmBtu);")
  for year in years 
    print(iob,";",Year[year]) 
  end
  println(iob)
  for nation in Nations
    print(iob,"ENPN;",NationDS[nation])
    for year in years
      ZZZ[year] = ENPN[fuel,nation,year]*InflationNation[nation,CDYear]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #print(iob,FuelName," Exogenous Primary Fuel Price ($CDTime ",MoneyUnitDS[area],"/mmBtu));")
  print(iob,FuelName," Exogenous Primary Fuel Price ($CDTime CN\$/mmBtu);")
  for year in years 
    print(iob,";",Year[year]) 
  end
  println(iob)
  for nation in Nations
    print(iob,"xENPN;",NationDS[nation])
    for year in years
      ZZZ[year] = xENPN[fuel,nation,year]*InflationNation[nation,CDYear]
      print(iob,";",@sprintf("%.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  for es in ESs
    #print(iob,FuelName," ",ESDS[es]," Delivered Fuel Price ($CDTime ",MoneyUnitDS[area],"/mmBtu));")
    print(iob,FuelName," ",ESDS[es]," Delivered Fuel Price ($CDTime CN\$/mmBtu);")
    for year in years 
      print(iob,";",Year[year]) 
    end
    println(iob)
    for area in Areas
      print(iob,"FPF;",AreaDS[area])
      for year in years
        ZZZ[year] = FPF[fuel,es,area,year]*Inflation[area,CDYear]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for es in ESs
    #print(iob,FuelName," ",ESDS[es]," Exogenous Delivered Fuel Price ($CDTime ",MoneyUnitDS[area],"/mmBtu));")
    print(iob,FuelName," ",ESDS[es]," Exogenous Delivered Fuel Price ($CDTime CN\$/mmBtu);")
    for year in years 
      print(iob,";",Year[year]) 
    end
    println(iob)
    for area in Areas
      print(iob,"xFPF;",AreaDS[area])
      for year in years
        ZZZ[year] = xFPF[fuel,es,area,year]*Inflation[area,CDYear]
        print(iob,";",@sprintf("%.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  filename = "Prices-$(Fuel[fuel])-$SceName.dta"
  open(joinpath(OutputFolder,filename),"w") do filename
    write(filename,String(take!(iob)))
  end
end

function Prices_DtaControl(db)
  @info "Prices_DtaControl"
  data = PricesData(; db)
  (; Fuels) = data
  
  for fuel in Fuels
    Prices_DtaRun(data,fuel)
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
Prices_DtaControl(DB)
end
