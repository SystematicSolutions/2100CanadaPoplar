#
# FlowNationX.jl
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

Base.@kwdef struct FlowNationXData
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
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray = ReadDisk(db, "MainDB/YearKey")

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  xDmdArea::VariableArray{3} = ReadDisk(db,"SpInput/xDmdArea") # [Fuel,Area,Year] Energy Demands (TBtu/Yr)
  xExports::VariableArray{3} = ReadDisk(db,"SpInput/xExports") # [FuelEP,Nation,Year] Primary Exports (TBtu/Yr)
  xExportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xExportsArea") # [Fuel,Area,Year] Exports of Energy (TBtu/Yr)
  xFlowNation::VariableArray{4} = ReadDisk(db,"SpInput/xFlowNation") # [Fuel,Nation,NationX,Year] Historical Energy Flow to Nation from NationX (TBtu/Yr)
  xImports::VariableArray{3} = ReadDisk(db,"SpInput/xImports") # [FuelEP,Nation,Year] Primary Imports (TBtu/Yr)
  xImportsArea::VariableArray{3} = ReadDisk(db,"SpInput/xImportsArea") # [Fuel,Area,Year] Imports of Energy (TBtu/Yr)
  xInflow::VariableArray{4} = ReadDisk(db,"SpInput/xInflow") #[Fuel,Area,Nation,Year]  Historical Energy Inflow (TBtu/Yr)
  xOutflow::VariableArray{4} = ReadDisk(db,"SpInput/xOutflow") #[Fuel,Area,Nation,Year]  Historical Energy Outflow (TBtu/Yr)
  xProdArea::VariableArray{3} = ReadDisk(db,"SpInput/xProdArea") # [Fuel,Area,Year] Energy Production (TBtu/Yr)
  xSupplyAdjustments::VariableArray{3} = ReadDisk(db,"SpInput/xSupplyAdjustments") # [FuelEP,Nation,Year] Oil and Gas Supply Adjustments (TBtu/Yr)

  #
  # Scratch variables
  #
  ZZZ::VariableArray{1} = zeros(Float32, size(Year,1))

end

function FlowNationX_DtaRun(data,FuelName,FuelName2,fuel,fuelep)
  (; SceName,Area,AreaDS,Areas,Fuel,FuelDS,Fuels,FuelEPs,Nations,NationDS) = data
  (; NationXs,NationXDS,Year) = data
  (; ANMap,xDmdArea,xExports,xExportsArea,xFlowNation) = data
  (; xImports,xImportsArea,xInflow,xOutflow,xProdArea,ZZZ) = data
 
  years = collect(Yr(1990):Yr(2050))
  iob = IOBuffer()
  println(iob, " ")
  println(iob, "$FuelName")
  println(iob, "This file was produced by FlowNationX.jl \n \n")
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
    print(iob, "xFlowNation;Total")
    for year in years
      ZZZ[year] = sum(xFlowNation[fuel,nation,nationx,year] for nationx in NationXs)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for nationx in NationXs
      print(iob, "xFlowNation;$(NationXDS[nationx])")
      for year in years
        ZZZ[year] = xFlowNation[fuel,nation,nationx,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nationx in NationXs
    print(iob, "$FuelName Energy Flow From $(NationDS[nationx]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "xFlowNation;Total")
    for year in years
      ZZZ[year] = sum(xFlowNation[fuel,nation,nationx,year] for nation in Nations)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for nation in Nations
      print(iob, "xFlowNation;$(NationDS[nation])")
      for year in years
        ZZZ[year] = xFlowNation[fuel,nation,nationx,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, "$FuelName Energy Flow from $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(0))
    print(iob, "xInflow;Total")   
    for year in years
      ZZZ[year] = sum(xInflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "xInflow;$(AreaDS[area])")    
      for year in years
        ZZZ[year] = xInflow[fuel,area,nation,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, "$FuelName Energy Flow to $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(0))
    print(iob, "xOutflow;Total")    
    for year in years
      ZZZ[year] = sum(xOutflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "xOutflow;$(AreaDS[area])")
      for year in years
        ZZZ[year] = xOutflow[fuel,area,nation,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, "$FuelName Energy Inflow within $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(1))
    print(iob, "xInflow;Total")
    for year in years
      ZZZ[year] = sum(xInflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "xInflow;$(AreaDS[area])")
      for year in years
        ZZZ[year] = xInflow[fuel,area,nation,year]
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  for nation in Nations
    print(iob, "$FuelName Energy Outflow within $(NationDS[nation]) (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    area = Select(ANMap[Areas,nation], ==(1))
    print(iob, "xOutflow;Total")
    for year in years
      ZZZ[year] = sum(xOutflow[fuel,area,nation,year] for area in area)
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
    for area in area
      print(iob, "xOutflow;$(AreaDS[area])")
      for year in years
        ZZZ[year] = xOutflow[fuel,area,nation,year] 
        print(iob,";",@sprintf("%.4f", ZZZ[year]))
      end
      println(iob)
    end
    println(iob, " ")
  end

  if FuelName2 != "Electric"
    print(iob, "$FuelName Imports (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    for nation in Nations
      print(iob, "xImports;$(NationDS[nation])")
      for year in years
        ZZZ[year] = xImports[fuelep,nation,year] 
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
    for nation in Nations
      print(iob, "xExports;$(NationDS[nation])")  
      for year in years
        ZZZ[year] = xExports[fuelep,nation,year]
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
    print(iob, "xDmdArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = xDmdArea[fuel,area,year]
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
    print(iob, "xProdArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = xProdArea[fuel,area,year]
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
    print(iob, "xImportsArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = xImportsArea[fuel,area,year]
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
    print(iob, "xExportsArea;$(AreaDS[area])")  
    for year in years
      ZZZ[year] = xExportsArea[fuel,area,year]
      print(iob,";",@sprintf("%.4f", ZZZ[year]))
    end
    println(iob)
  end
  println(iob, " ")  

  #
  # Create *.dta filename and write output values
  #
  filename = "FlowNationX-$FuelName2-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function FlowNationX_DtaControl(db)
  # @info "FlowNationX_DtaControl"
  data = FlowNationXData(; db)
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
    FlowNationX_DtaRun(data, FuelName, FuelName2, fuel, fuelep)
  end
end
if abspath(PROGRAM_FILE) == @__FILE__
FlowNationX_DtaControl(DB)
end
