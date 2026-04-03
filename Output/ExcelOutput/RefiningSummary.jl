#
# RefiningSummary.jl
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

Base.@kwdef struct RefiningSummaryData
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
  Inflation::VariableArray{2} = ReadDisk(db,"MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  RfArea::Vector{String} = ReadDisk(db,"SpInput/RfArea") #[RfUnit]  Refinery Area
  RfCap::VariableArray{2} = ReadDisk(db,"SpOutput/RfCap") # [RfUnit,Year] Refining Unit Capacity (TBtu/Yr)
  RfCrude::VariableArray{3} = ReadDisk(db,"SpOutput/RfCrude") # [RfUnit,Crude,Year] Refining Unit Crude Oil Refined (TBtu/Yr)
  RfFP::VariableArray{3} = ReadDisk(db,"SpOutput/RfFP") # [RfUnit,Fuel,Year] RPP Fuel Prices ($/mmBtu)
  RfFPUS::VariableArray{3} = ReadDisk(db,"SpOutput/RfFPUS") # [RfUnit,Fuel,Year] RPP Fuel Prices (US$/mmBtu)
  RfFPCrude::VariableArray{3} = ReadDisk(db,"SpOutput/RfFPCrude") # [RfUnit,Crude,Year] Crude Oil Prices ($/mmBtu)
  RfFPCrudeUS::VariableArray{3} = ReadDisk(db,"SpOutput/RfFPCrudeUS") # [RfUnit,Crude,Year] Crude Oil Prices (US$/mmBtu)
  InflationRfUnit::VariableArray{2} = ReadDisk(db,"MOutput/InflationRfUnit") #[RfUnit,Year]  Inflation Index ($/$)
  RfNation::Array{String} = ReadDisk(db,"SpInput/RfNation") # [RfUnit] Refinery Nation
  RfProd::VariableArray{3} = ReadDisk(db,"SpOutput/RfProd") # [RfUnit,Fuel,Year] Refining Unit Production (TBtu/Yr)
  RPPAreaPurchases::VariableArray{3} = ReadDisk(db,"SpOutput/RPPAreaPurchases") # [Fuel,Area,Year] RPP Purchases from Areas in the same Country (TBtu/Yr)
  RPPAreaSales::VariableArray{3} = ReadDisk(db,"SpOutput/RPPAreaSales") # [Fuel,Area,Year] RPP Sales to Areas in the same Country (TBtu/Yr)
  RPPDem::VariableArray{3} = ReadDisk(db,"SpOutput/RPPDem") # [GNode,Fuel,Year] Nodal Demand for RPP (TBtu/Yr)
  RPPEmgSupply::VariableArray{3} = ReadDisk(db,"SpOutput/RPPEmgSupply") # [GNode,Fuel,Year] RPP Emergency Supply (TBtu/Yr)
  RPPExportsArea::VariableArray{3} = ReadDisk(db,"SpOutput/RPPExportsArea") # [Fuel,Area,Year] RPP Sales to Areas in a different Country (TBtu/Yr)
  RPPImportsArea::VariableArray{3} = ReadDisk(db,"SpOutput/RPPImportsArea") # [Fuel,Area,Year] RPP Imports by Areas (TBtu/Yr)

  ZZZ::VariableArray = zeros(Float32,length(Year))

end

function RefiningSummary_DtaRun(data,areas,TitleName,TitleKey,rfunits)
  (; SceName,Area,AreaDS,Areas,Crude,CrudeDS,Crudes,Fuel,FuelDS,Fuels) = data
  (; GNode,GNodes,Nation,NationDS,Nations,RfName,RfUnit,RfUnits,Year) = data
  (; CDTime,CDYear,ANMap,GNodeAreaMap,Inflation,RfArea,RfCap,RfCrude,RfFP,RfFPUS) = data
  (; RfFPCrude,RfFPCrudeUS,InflationRfUnit,RfNation,RfProd,RPPAreaPurchases) = data
  (; RPPAreaSales,RPPDem,RPPEmgSupply,RPPExportsArea,RPPImportsArea,ZZZ) = data

  years = collect(Yr(1990):Final)
  fuels=Select(Fuel,["Asphalt","AviationGasoline","Diesel","Gasoline","HFO","JetFuel","Kerosene",
      "LFO","LPG","Lubricants","Naphtha","NonEnergy","PetroFeed","PetroCoke","StillGas"])
  iob = IOBuffer()

  println(iob)
  println(iob, "$SceName; is the scenario name.")
  println(iob)
  println(iob, "This file was produced by RefiningSummary.jl")
  println(iob)
  println(iob, "Year;", ";    ", join(Year[years], ";"))
  println(iob)

  #
  # Refining Capacity
  #
  println(iob,"$TitleName Refining Capacity (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RfCap;Total")
  for year in years
    ZZZ[year] = sum(RfCap[rfunit,year] for rfunit in rfunits)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  println(iob)

  #
  # RPP Demands
  #
  println(iob,"$TitleName RPP Demands (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RPPDem;","Total")
  for year in years
    ZZZ[year] = sum(RPPDem[gnode,fuel,year]*GNodeAreaMap[gnode,area] for area in areas, fuel in fuels, gnode in GNodes)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    print(iob,"RPPDem;$(FuelDS[fuel])")
    for year in years
      ZZZ[year] = sum(RPPDem[gnode,fuel,year]*GNodeAreaMap[gnode,area] for area in areas, gnode in GNodes)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Refining Production
  #
  println(iob,"$TitleName RPP Production (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RfProd;Total")
  for year in years
    ZZZ[year] = sum(RfProd[rfunit,fuel,year] for fuel in fuels, rfunit in rfunits)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    print(iob,"RfProd;$(FuelDS[fuel])")
    for year in years
    ZZZ[year] = sum(RfProd[rfunit,fuel,year] for rfunit in rfunits)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,"$TitleName In-Country Purchases (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RPPAreaPurchases;Total")
  for year in years
    ZZZ[year] = sum(RPPAreaPurchases[fuel,area,year] for area in areas, fuel in fuels)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    print(iob,"RPPAreaPurchases;$(FuelDS[fuel])")
    for year in years
    ZZZ[year] = sum(RPPAreaPurchases[fuel,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,"$TitleName In-Country Sales (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RPPAreaSales;Total")
  for year in years
    ZZZ[year] = sum(RPPAreaSales[fuel,area,year] for area in areas, fuel in fuels)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    print(iob,"RPPAreaSales;$(FuelDS[fuel])")
    for year in years
    ZZZ[year] = sum(RPPAreaSales[fuel,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,"$TitleName Imports (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RPPImportsArea;Total")
  for year in years
    ZZZ[year] = sum(RPPImportsArea[fuel,area,year] for area in areas, fuel in fuels)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    print(iob,"RPPImportsArea;$(FuelDS[fuel])")
    for year in years
    ZZZ[year] = sum(RPPImportsArea[fuel,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  println(iob,"$TitleName Exports (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RPPExportsArea;Total")
  for year in years
    ZZZ[year] = sum(RPPExportsArea[fuel,area,year] for area in areas, fuel in fuels)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    print(iob,"RPPExportsArea;$(FuelDS[fuel])")
    for year in years
    ZZZ[year] = sum(RPPExportsArea[fuel,area,year] for area in areas)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # RPP Emergency Supply
  #
  println(iob,"$TitleName RPP Emergency Supply (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RPPEmgSupply;","Total")
  for year in years
    ZZZ[year] = sum(RPPEmgSupply[gnode,fuel,year]*GNodeAreaMap[gnode,area] for area in areas, fuel in fuels, gnode in GNodes)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for fuel in fuels
    print(iob,"RPPEmgSupply;$(FuelDS[fuel])")
    for year in years
      ZZZ[year] = sum(RPPEmgSupply[gnode,fuel,year]*GNodeAreaMap[gnode,area] for area in areas, gnode in GNodes)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Crude Oil Refined by Crude
  #
  println(iob,"$TitleName Crude Oil Refined (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RfCrude;Total")
  for year in years
    ZZZ[year] = sum(RfCrude[rfunit,crude,year] for crude in Crudes, rfunit in rfunits)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for crude in Crudes
    print(iob,"RfCrude;$(CrudeDS[crude])")
    for year in years
      ZZZ[year] = sum(RfCrude[rfunit,crude,year] for rfunit in rfunits)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # RPP Fuel Prices ($/mmBtu)
  #
  println(iob,"$TitleName Average RPP Fuel Price ($CDTime US\$/mmBtu);;    ", join(Year[years], ";"))
  for fuel in fuels
    print(iob,"RfFP;$(FuelDS[fuel])")
    for year in years
      @finite_math ZZZ[year]=sum(RfFPUS[rfunit,fuel,year]/InflationRfUnit[rfunit,year]*InflationRfUnit[rfunit,CDYear]*RfProd[rfunit,fuel,year] for rfunit in rfunits)/
            sum(RfProd[rfunit,fuel,year] for rfunit in rfunits)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)


  #
  # Crude Oil Prices ($/mmBtu)
  #
  println(iob,"$TitleName Average Crude Oil Prices ($CDTime US\$/mmBtu);;    ", join(Year[years], ";"))
  print(iob,"RfFPCrude;Average")
  for year in years
    @finite_math ZZZ[year] = sum(RfFPCrudeUS[rfunit,crude,year]/InflationRfUnit[rfunit,year]*InflationRfUnit[rfunit,CDYear]*RfCap[rfunit,Last] for crude in Crudes, rfunit in rfunits)/
        sum(RfCap[rfunit,Last] for rfunit in rfunits)/length(Crude)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for crude in Crudes
    print(iob,"RfFPCrude;$(CrudeDS[crude])")
    for year in years
      @finite_math ZZZ[year] = sum(RfFPCrudeUS[rfunit,crude,year]/InflationRfUnit[rfunit,year]*InflationRfUnit[rfunit,CDYear]*RfCap[rfunit,Last] for rfunit in rfunits)/
          sum(RfCap[rfunit,Last] for rfunit in rfunits)
      print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  ########################
  #
  # Rows vary based on number of RfUnits in Area
  #
  # Refining Capacity
  #
  println(iob,"$TitleName Refining Capacity (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RfCap;Total")
  for year in years
    ZZZ[year] = sum(RfCap[rfunit,year] for rfunit in rfunits)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for rfunit in rfunits
    print(iob,"RfCap;$(RfName[rfunit])")
    for year in years
      ZZZ[year] = RfCap[rfunit,year]
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # RPP Production
  #
  println(iob,"$TitleName RPP Production (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RfProd;Total")
  for year in years
    ZZZ[year] = sum(RfProd[rfunit,fuel,year] for fuel in fuels, rfunit in rfunits)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for rfunit in rfunits
    print(iob,"RfProd;$(RfName[rfunit])")
    for year in years
      ZZZ[year] = sum(RfProd[rfunit,fuel,year] for fuel in fuels)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Crude Oil Refined by Area
  #
  println(iob,"$TitleName Crude Oil Refined (TBtu/Yr);;    ", join(Year[years], ";"))
  print(iob,"RfCrude;Total")
  for year in years
    ZZZ[year] = sum(RfCrude[rfunit,crude,year] for crude in Crudes, rfunit in rfunits)
    print(iob,";",@sprintf("%14.4f",ZZZ[year]))
  end
  println(iob)
  for rfunit in rfunits
    print(iob,"RfCrude;$(RfName[rfunit])")
    for year in years
      ZZZ[year] = sum(RfCrude[rfunit,crude,year] for crude in Crudes)
        print(iob,";",@sprintf("%14.4f",ZZZ[year]))
    end
    println(iob)
  end
  println(iob)

  #
  # Create *.dta filename and write output values
  #
  filename = "RefiningSummary-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end

end

function RefiningSummary_DtaControl(db)
  @info "RefiningSummary_DtaControl"
  data = RefiningSummaryData(; db)
  (; Area, Areas, AreaDS, Nation, NationDS, Nations, RfUnits) = data
  (; ANMap, RfArea, RfNation) = data

  for nation in Nations
    areas=findall(ANMap[Areas,nation] .== 1)
    TitleName=NationDS[nation]
    TitleKey=Nation[nation]
    rfunits=findall(RfNation[RfUnits] .== Nation[nation])
    if !isempty(rfunits)
      RefiningSummary_DtaRun(data,areas,TitleName,TitleKey,rfunits)
    end
    #
    for area in areas
      TitleName=AreaDS[area]
      TitleKey=Area[area]
      rfunits=findall(RfArea[RfUnits] .== Area[area])
      if !isempty(rfunits)
        RefiningSummary_DtaRun(data,area,TitleName,TitleKey,rfunits)
      end
    end
  end

  TitleName="North America"
  TitleKey="NAm"
  RefiningSummary_DtaRun(data,Areas,TitleName,TitleKey,RfUnits)
end

if abspath(PROGRAM_FILE) == @__FILE__
RefiningSummary_DtaControl(DB)
end
