#
# FlowBalance.jl
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

Base.@kwdef struct FlowBalanceData
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

  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  DmdArea::VariableArray{3} = ReadDisk(db,"SpOutput/DmdArea") # [Fuel,Area,Year] Energy Demands (TBtu/Yr)
  Inflow::VariableArray{4} = ReadDisk(db,"SpOutput/Inflow") # [Fuel,Area,Nation,Year] Energy Inflow (TBtu/Yr)
  Outflow::VariableArray{4} = ReadDisk(db,"SpOutput/Outflow") # [Fuel,Area,Nation,Year] Energy Outflow (TBtu/Yr)
  ProdArea::VariableArray{3} = ReadDisk(db,"SpOutput/ProdArea") # [Fuel,Area,Year] Energy Production (TBtu/Yr)
  Surplus::VariableArray{3} = ReadDisk(db,"SpInput/Surplus") # [Fuel,Area,Year] Energy Demand Surplus (TBtu/Yr)

  #
  # Scratch variables
  #
  SSS::VariableArray{1} = zeros(Float32, length(Year))
  ZZZ::VariableArray{1} = zeros(Float32, length(Year))
end

function FlowBalance_DtaRun(data, FuelName,FuelKey,fuels,NationName,NationKey,nation)
  (; Area,AreaDS,Areas,Nation,Nations,NationDS,Year) = data
  (; SceName,ANMap,DmdArea,Inflow,Outflow,ProdArea,Surplus,SSS,ZZZ) = data
  
  years = collect(Yr(1990):Yr(2050))
  iob = IOBuffer()
  println(iob, " ")
  println(iob, "$NationName $FuelName")
  println(iob, "This file was produced by FlowBalance.jl")
  println(iob, " ")
  println(iob, " ")
  println(iob, "Year;;", join(Year[years], ";"))
  println(iob, " ")

  areas=findall(ANMap[Areas,nation] .== 1)
  #
  # Nation Total
  #
  print(iob, "$NationName $FuelName Flow Balance (TBtu/Yr);")
  for year in years
    print(iob,";",Year[year])
  end
  println(iob)
  print(iob, "DmdArea;Demand")
  for year in years
    ZZZ[year] = sum(DmdArea[fuel,area,year] for area in areas, fuel in fuels)
    SSS[year] = 0 + ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  print(iob, "ProdArea;Production")
  for year in years
    ZZZ[year] = sum(ProdArea[fuel,area,year] for area in areas, fuel in fuels)
    SSS[year] = SSS[year] - ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  print(iob, "Inflow;Domestic Inflow")
  for year in years
    ZZZ[year] = sum(Inflow[fuel,area,nation,year] for area in areas, fuel in fuels)
    SSS[year] = SSS[year] - ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  print(iob, "Outflow;Domestic Outflow")
  for year in years
    ZZZ[year] = sum(Outflow[fuel,area,nation,year] for area in areas, fuel in fuels)
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  othernations=Select(Nation,!=(Nation[nation]))
  print(iob, "Inflow;Imports")
  for year in years
    ZZZ[year] = sum(Inflow[fuel,area,othernation,year] for othernation in othernations, area in areas, fuel in fuels)
    SSS[year] = SSS[year] - ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  print(iob, "Outflow;Exports")
  for year in years
    ZZZ[year] = sum(Outflow[fuel,area,othernation,year] for othernation in othernations, area in areas, fuel in fuels)
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  print(iob, "Surplus;Demand Surplus")
  for year in years
    ZZZ[year] = sum(Surplus[fuel,area,year] for area in areas, fuel in fuels)
    SSS[year] = SSS[year] - ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  print(iob, "Check;Supply Surplus")
  for year in years
    print(iob,";",@sprintf("%15.4f", SSS[year]))
  end
  println(iob)
  print(iob, "NetOutflow;Net Outflow")
  for year in years
    ZZZ[year] = sum(Outflow[fuel,area,othernation,year]-
        Inflow[fuel,area,othernation,year] for othernation in othernations, area in areas, fuel in fuels)
    SSS[year] = SSS[year] + ZZZ[year]
    print(iob,";",@sprintf("%15.4f", ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # Individual Areas
  #
  for area in areas
    print(iob, "$(AreaDS[area]) $FuelName Flow Balance (TBtu/Yr);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "DmdArea;Demand")
    for year in years
      ZZZ[year] = sum(DmdArea[fuel,area,year] for fuel in fuels)
      SSS[year] = 0 + ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    print(iob, "ProdArea;Production")
    for year in years
      ZZZ[year] = sum(ProdArea[fuel,area,year] for fuel in fuels)
      SSS[year] = SSS[year] - ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    print(iob, "Inflow;Domestic Inflow")
    for year in years
      ZZZ[year] = sum(Inflow[fuel,area,nation,year] for fuel in fuels)
      SSS[year] = SSS[year] - ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    print(iob, "Outflow;Domestic Outflow")
    for year in years
      ZZZ[year] = sum(Outflow[fuel,area,nation,year] for fuel in fuels)
      SSS[year] = SSS[year] + ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    othernations=Select(Nation,!=(Nation[nation]))
    print(iob, "Inflow;Imports")
    for year in years
      ZZZ[year] = sum(Inflow[fuel,area,othernation,year] for othernation in othernations, fuel in fuels)
      SSS[year] = SSS[year] - ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    print(iob, "Outflow;Exports")
    for year in years
      ZZZ[year] = sum(Outflow[fuel,area,othernation,year] for othernation in othernations, fuel in fuels)
      SSS[year] = SSS[year] + ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    print(iob, "Surplus;Demand Surplus")
    for year in years
      ZZZ[year] = sum(Surplus[fuel,area,year] for fuel in fuels)
      SSS[year] = SSS[year] - ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    print(iob, "Check;Supply Surplus")
    for year in years
      print(iob,";",@sprintf("%15.4f", SSS[year]))
    end
    println(iob)
    print(iob, "NetOutflow;Net Outflow")
    for year in years
      ZZZ[year] = sum(Outflow[fuel,area,othernation,year]-
          Inflow[fuel,area,othernation,year] for othernation in othernations, fuel in fuels)
      SSS[year] = SSS[year] + ZZZ[year]
      print(iob,";",@sprintf("%15.4f", ZZZ[year]))
    end
    println(iob)
    println(iob)
  end

  #
  # Create *.dta filename and write output values
  #
  filename = "FlowBalance-$FuelKey-$NationKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function FlowBalance_DtaControl(db)
  # @info "FlowBalance_DtaControl"
  data = FlowBalanceData(; db)
  (; Fuel, FuelDS, Nation, NationDS) = data
  #
  fuels = Select(Fuel, ["NaturalGas","LightCrudeOil","Electric","Coal"])
  nations=Select(Nation,["CN","US","MX"])
  for fuel in fuels, nation in nations
    FlowBalance_DtaRun(data, FuelDS[fuel], Fuel[fuel], fuel, NationDS[nation], Nation[nation], nation)
  end

  fuels = Select(Fuel, ["Asphalt","Asphaltines","AviationGasoline","Diesel",
                        "Gasoline","HFO","JetFuel","Kerosene","LFO","LPG","Lubricants","Naphtha",
                        "NonEnergy","PetroFeed","PetroCoke","StillGas"])
  for nation in nations
    FlowBalance_DtaRun(data, "RPP", "RPP", fuels, NationDS[nation], Nation[nation], nation)
  end


end

if abspath(PROGRAM_FILE) == @__FILE__
FlowBalance_DtaControl(DB)
end


