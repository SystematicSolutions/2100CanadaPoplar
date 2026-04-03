#
# RefiningImportsExports.jl - Petroleum Refining ImportsExports
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

Base.@kwdef struct RefiningImportsExportsData
  db::String

  Area::SetArray   = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int}    = collect(Select(Area))
  Crude::SetArray = ReadDisk(db,"MainDB/CrudeKey")
  CrudeDS::SetArray = ReadDisk(db,"MainDB/CrudeDS")
  Crudes::Vector{Int} = collect(Select(Crude))
  Fuel::SetArray   = ReadDisk(db,"MainDB/FuelKey")
  FuelDS::SetArray = ReadDisk(db,"MainDB/FuelDS")
  Fuels::Vector{Int}    = collect(Select(Fuel))
  GNode::SetArray = ReadDisk(db,"MainDB/GNodeKey")
  GNodes::Vector{Int} = collect(Select(GNode))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  RfName::SetArray = ReadDisk(db,"MainDB/RfName")
  RfUnit::SetArray = ReadDisk(db,"MainDB/RfUnitKey")
  RfUnits::Vector{Int} = collect(Select(RfUnit))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name
  Year::SetArray   = ReadDisk(db,"MainDB/YearKey")

  CDTime::Int = ReadDisk(db, "SInput/CDTime")[1] # Constant Dollar Year for Model Outputs (Year)
  CDYear::Int = ReadDisk(db, "SInput/CDYear")[1] # Constant Dollar Year for Model Outputs (Year)

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  GNodeAreaMap::VariableArray{2} = ReadDisk(db,"SpInput/GNodeAreaMap") #[GNode,Area]  Natural Gas Node to Area Map
  RPPAreaPurchases::VariableArray{3} = ReadDisk(db,"SpOutput/RPPAreaPurchases") # [Fuel,Area,Year] RPP Purchases from Areas in the same Country (TBtu/Yr)
  RPPAreaSales::VariableArray{3} = ReadDisk(db,"SpOutput/RPPAreaSales") # [Fuel,Area,Year] RPP Sales to Areas in the same Country (TBtu/Yr)
  RPPDem::VariableArray{3} = ReadDisk(db,"SpOutput/RPPDem") # [GNode,Fuel,Year] Nodal Demand for RPP (TBtu/Yr)
  RPPDemandA::VariableArray{3} = ReadDisk(db,"SpOutput/RPPDemandA") # [Fuel,Area,Year] Refined Petroleum Products (RPP) Demand (TBtu/Yr)
  RPPEmgSupply::VariableArray{3} = ReadDisk(db,"SpOutput/RPPEmgSupply") # [GNode,Fuel,Year] RPP Emergency Supply (TBtu/Yr)
  RPPExportsArea::VariableArray{3} = ReadDisk(db,"SpOutput/RPPExportsArea") # [Fuel,Area,Year] RPP Sales to Areas in a different Country (TBtu/Yr)
  RPPImportsArea::VariableArray{3} = ReadDisk(db,"SpOutput/RPPImportsArea") # [Fuel,Area,Year] RPP Imports by Areas (TBtu/Yr)
  RPPProdArea::VariableArray{3} = ReadDisk(db,"SpOutput/RPPProdArea") #[Fuel,Area,Year]  Refined Petroleum Products (RPP) Production (TBtu/Yr)

  ZZZ::VariableArray = zeros(Float32,length(Year))

end

function RefiningImportsExports_DtaRun(data)
  (; SceName,Area,AreaDS,Areas,Fuel,FuelDS,Fuels) = data
  (; GNode,GNodes,Nation,NationDS,Nations,Year) = data
  (; CDTime,CDYear,ANMap,GNodeAreaMap,RPPAreaPurchases,RPPAreaSales) = data
  (; RPPDem,RPPDemandA,RPPEmgSupply,RPPExportsArea,RPPImportsArea,RPPProdArea,ZZZ) = data

  years = collect(Yr(1990):Final)
  nations=Select(Nation,["CN","US"])
  iob = IOBuffer()

  println(iob)
  println(iob, "$SceName; is the scenario name.")
  println(iob)
  println(iob, "This file was produced by RefiningImportsExports.jl")
  println(iob)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob)

  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    println(iob,"$(NationDS[nation]) In-Country Sales (TBtu/Yr);;    ", join(Year[years], ";"))
    print(iob,"RPPAreaSales;$(NationDS[nation])")
    for year in years
      ZZZ[year] = sum(RPPAreaSales[fuel,area,year] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for area in areas
      print(iob,"RPPAreaSales;$(AreaDS[area])")
      for year in years
        ZZZ[year] = sum(RPPAreaSales[fuel,area,year] for fuel in Fuels)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    println(iob,"$(NationDS[nation]) In-Country Purchases (TBtu/Yr);;    ", join(Year[years], ";"))
    print(iob,"RPPAreaPurchases;$(NationDS[nation])")
    for year in years
      ZZZ[year] = sum(RPPAreaPurchases[fuel,area,year] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for area in areas
      print(iob,"RPPAreaPurchases;$(AreaDS[area])")
      for year in years
        ZZZ[year] = sum(RPPAreaPurchases[fuel,area,year] for fuel in Fuels)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    println(iob,"$(NationDS[nation]) Exports (TBtu/Yr);;    ", join(Year[years], ";"))
    print(iob,"RPPExportsArea;$(NationDS[nation])")
    for year in years
      ZZZ[year] = sum(RPPExportsArea[fuel,area,year] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for area in areas
      print(iob,"RPPExportsArea;$(AreaDS[area])")
      for year in years
        ZZZ[year] = sum(RPPExportsArea[fuel,area,year] for fuel in Fuels)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    println(iob,"$(NationDS[nation]) Imports (TBtu/Yr);;    ", join(Year[years], ";"))
    print(iob,"RPPImportsArea;$(NationDS[nation])")
    for year in years
      ZZZ[year] = sum(RPPImportsArea[fuel,area,year] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for area in areas
      print(iob,"RPPImportsArea;$(AreaDS[area])")
      for year in years
        ZZZ[year] = sum(RPPImportsArea[fuel,area,year] for fuel in Fuels)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    println(iob,"$(NationDS[nation]) RPP Demands (TBtu/Yr);;    ", join(Year[years], ";"))
    print(iob,"RPPDemandA;$(NationDS[nation])")
    for year in years
      ZZZ[year] = sum(RPPDemandA[fuel,area,year] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for area in areas
      print(iob,"RPPDemandA;$(AreaDS[area])")
      for year in years
        ZZZ[year] = sum(RPPDemandA[fuel,area,year] for fuel in Fuels)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    println(iob,"$(NationDS[nation]) RPP Production (TBtu/Yr);;    ", join(Year[years], ";"))
    print(iob,"RPPProdArea;$(NationDS[nation])")
    for year in years
      ZZZ[year] = sum(RPPProdArea[fuel,area,year] for area in areas, fuel in Fuels)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for area in areas
      print(iob,"RPPProdArea;$(AreaDS[area])")
      for year in years
        ZZZ[year] = sum(RPPProdArea[fuel,area,year] for fuel in Fuels)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  for nation in nations
    areas=findall(ANMap[Areas,nation] .== 1)
    println(iob,"$(NationDS[nation]) RPP Emergency Supply (TBtu/Yr);;    ", join(Year[years], ";"))
    print(iob,"RPPEmgSupply;$(NationDS[nation])")
    for year in years
      ZZZ[year] = sum(RPPEmgSupply[gnode,fuel,year]*GNodeAreaMap[gnode,area] for area in areas, fuel in Fuels, gnode in GNodes)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
    for area in areas
      print(iob,"RPPEmgSupply;$(AreaDS[area])")
      for year in years
        ZZZ[year] = sum(RPPEmgSupply[gnode,fuel,year]*GNodeAreaMap[gnode,area] for fuel in Fuels, gnode in GNodes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
      end
      println(iob)
    end
    println(iob)
  end

  #
  # Create *.dta filename and write output values
  #
  filename = "RefiningImportsExports-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function RefiningImportsExports_DtaControl(db)
  @info "RefiningImportsExports_DtaControl"
  data = RefiningImportsExportsData(; db)
 
  RefiningImportsExports_DtaRun(data)
end

if abspath(PROGRAM_FILE) == @__FILE__
RefiningImportsExports_DtaControl(DB)
end
