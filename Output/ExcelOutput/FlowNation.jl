#
# FlowNation.jl
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

#rm_dir_contents(OutputFolder)
#create_folder() = isdir(dirname(OutputFolder)) || mkpath(dirname(OutputFolder))

Base.@kwdef struct FlowNationData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  Areas::Vector{Int}    = collect(Select(Area))
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Fuel::SetArray = ReadDisk(db, "MainDB/FuelKey")
  Fuels::Vector{Int}    = collect(Select(Fuel))
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  FuelEP::SetArray = ReadDisk(db, "MainDB/FuelEPKey")
  FuelEPs::Vector{Int}    = collect(Select(FuelEP))
  Nation::SetArray = ReadDisk(db, "MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int}    = collect(Select(Nation))
  NationX::SetArray = ReadDisk(db, "MainDB/NationXKey")
  NationXDS::SetArray = ReadDisk(db, "MainDB/NationXDS")
  NationXs::Vector{Int}    = collect(Select(NationX))
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DmdArea::VariableArray{3} = ReadDisk(db,"SpOutput/DmdArea") # [Fuel,Area,Year] Energy Demands (TBtu/Yr)
  Exports::VariableArray{3} = ReadDisk(db,"SpOutput/Exports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  ExportsArea::VariableArray{3} = ReadDisk(db,"SpOutput/ExportsArea") # [Fuel,Area,Year] Exports of Energy (TBtu/Yr)
  FlowNation::VariableArray{4} = ReadDisk(db,"SpOutput/FlowNation") # [Fuel,Nation,NationX,Year] Energy Flow to Nation from NationX (TBtu/Yr)
  Imports::VariableArray{3} = ReadDisk(db,"SpOutput/Imports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  ImportsArea::VariableArray{3} = ReadDisk(db,"SpOutput/ImportsArea") # [Fuel,Area,Year] Imports of Energy (TBtu/Yr)
  Inflow::VariableArray{4} = ReadDisk(db,"SpOutput/Inflow") # [Fuel,Area,Nation,Year] Energy Inflow (TBtu/Yr)
  Outflow::VariableArray{4} = ReadDisk(db,"SpOutput/Outflow") # [Fuel,Area,Nation,Year] Energy Outflow (TBtu/Yr)
  ProdArea::VariableArray{3} = ReadDisk(db,"SpOutput/ProdArea") # [Fuel,Area,Year] Energy Production (TBtu/Yr)
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  SupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpOutput/SupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)

  #
  # Scratch variables
  #
  ZZZ::VariableArray{1} = zeros(Float32, size(Year,1))
end

function FlowNation_DtaRun(data, FuelName, FuelName2,fuel,fuelep)
  (; Area,AreaDS,Areas,Fuel,FuelDS,Fuels,FuelEPs,Nations,NationDS) = data
  (; NationXs, NationXDS,Year) = data
  (; ANMap,DmdArea,Exports,ExportsArea,FlowNation) = data
  (; Imports,ImportsArea,Inflow,Outflow,ProdArea,SceName,ZZZ) = data
  
  years = collect(Yr(1990):Yr(2050))
  iob = IOBuffer()
  println(iob, " ")
  println(iob, "$FuelName")
  println(iob, "This file was produced by FlowNation.jl \n \n")
  println(iob, "Year;;", join(Year[years], ";"))
  println(iob, " ")

  #
  # ********************
  #
  for nation in Nations
    print(iob, "$FuelName Energy Flow to $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "FlowNation;Total")
    for year in years
      ZZZ[year] = sum(FlowNation[fuel,nation,nationx,year] for nationx in NationXs)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for nationx in NationXs
      print(iob, "FlowNation;$(NationXDS[nationx])")
      for year in years
        ZZZ[year] = FlowNation[fuel,nation,nationx,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for nationx in NationXs
    print(iob, "$FuelName Energy Flow From $(NationDS[nationx]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "FlowNation;Total")
    for year in years
      ZZZ[year] = sum(FlowNation[fuel,nation,nationx,year] for nation in Nations)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for nation in Nations
      print(iob, "FlowNation;$(NationDS[nation])")
      for year in years
        ZZZ[year] = FlowNation[fuel,nation,nationx,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for nation in Nations
    print(iob, "$FuelName Energy Flow from $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(0))
    print(iob, "Inflow;Total")   
    for year in years
      ZZZ[year] = sum(Inflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "Inflow;$(AreaDS[area])")    
      for year in years
        ZZZ[year] = Inflow[fuel,area,nation,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for nation in Nations
    print(iob, "$FuelName Energy Flow to $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(0))
    print(iob, "Outflow;Total")    
    for year in years
      ZZZ[year] = sum(Outflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "Outflow;$(AreaDS[area])")
      for year in years
        ZZZ[year] = Outflow[fuel,area,nation,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for nation in Nations
    print(iob, "$FuelName Energy Inflow within $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(1))
    print(iob, "Inflow;Total")
    for year in years
      ZZZ[year] = sum(Inflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "Inflow;$(AreaDS[area])")
      for year in years
        ZZZ[year] = Inflow[fuel,area,nation,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  for nation in Nations
    print(iob, "$FuelName Energy Outflow within $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(1))
    print(iob, "Outflow;Total")
    for year in years
      ZZZ[year] = sum(Outflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "Outflow;$(AreaDS[area])")
      for year in years
        ZZZ[year] = Outflow[fuel,area,nation,year] 
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  #
  if FuelName2 != "Electric"
    print(iob, "$FuelName Imports (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      print(iob, "Imports;$(NationDS[nation])")
      for year in years
        ZZZ[year] = Imports[fuelep,nation,year] 
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")

    #
    print(iob, "$FuelName Exports (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      print(iob, "Exports;$(NationDS[nation])")  
      for year in years
        ZZZ[year] = Exports[fuelep,nation,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end


  print(iob, "$FuelName Demand (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "DmdArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = DmdArea[fuel,area,year]
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")  
  
  print(iob, "$FuelName Production (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "ProdArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = ProdArea[fuel,area,year]
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")  
   
  print(iob, "$FuelName Imports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "ImportsArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = ImportsArea[fuel,area,year]
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")
    
  print(iob, "$FuelName Exports (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  for area in Areas
    print(iob, "ExportsArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = ExportsArea[fuel,area,year]
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")  

  #
  # Create *.dta filename and write output values
  #
  filename = "FlowNation-$FuelName2-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function FlowNation_DtaControl(db)
   @info "FlowNation_DtaControl"

  data = FlowNationData(; db)
  (; Fuel, FuelDS, FuelEP) = data
  #
  fuels = Select(Fuel, ["NaturalGas","LightCrudeOil","Coal","Electric","Gasoline"])
  for fuel in fuels
    FuelName = FuelDS[fuel]
    FuelName2 = Fuel[fuel]
    if Fuel[fuel] == "LightCrudeOil"
      fuel = Select(Fuel,"LightCrudeOil")
      fuelep = Select(FuelEP,"CrudeOil")
    elseif Fuel[fuel] == "NaturalGas"
      fuel = Select(Fuel,"NaturalGas")
      fuelep = Select(FuelEP,"NaturalGas")
    elseif Fuel[fuel] == "Coal"
      fuel = Select(Fuel,"Coal")
      fuelep = Select(FuelEP,"Coal")
    elseif Fuel[fuel] == "Electric"
      fuel = Select(Fuel,"Electric")
      fuelep = 1
    elseif Fuel[fuel] == "Gasoline"
      FuelName = "RPP"
      FuelName2 = "RPP"   
      fuel = Select(Fuel,"Gasoline")
      fuelep = Select(FuelEP,"Gasoline")    
    end
    FlowNation_DtaRun(data, FuelName, FuelName2, fuel, fuelep)
  end
end

if abspath(PROGRAM_FILE) == @__FILE__
FlowNation_DtaControl(DB)
end


