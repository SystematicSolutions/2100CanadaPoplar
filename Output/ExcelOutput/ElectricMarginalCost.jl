#
# ElectricMarginalCost.jl
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

Base.@kwdef struct ElectricMarginalCostData
  db::String

  Area::SetArray = ReadDisk(db, "MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db, "MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))

  GenCo::SetArray = ReadDisk(db, "MainDB/GenCo")
  GenCoDS::SetArray = ReadDisk(db, "MainDB/GenCoDS")
  GenCos::Vector{Int} = collect(Select(GenCo))

  Nation::SetArray = ReadDisk(db, "MainDB/Nation")
  NationDS::SetArray = ReadDisk(db, "MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))

  Node::SetArray = ReadDisk(db, "MainDB/Node")
  NodeDS::SetArray = ReadDisk(db, "MainDB/NodeDS")
  Nodes::Vector{Int} = collect(Select(Node))

  Plant::SetArray = ReadDisk(db, "MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db, "MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))

  Power::SetArray = ReadDisk(db, "MainDB/PowerKey")
  PowerDS::SetArray = ReadDisk(db, "MainDB/PowerDS")
  Powers::Vector{Int} = collect(Select(Power))
  SceName::String = ReadDisk(db,"SInput/SceName") #  Scenario Name

  Year::SetArray = ReadDisk(db, "MainDB/Year")
  Yr2018 = 2018 - 1985 + 1
  Yr2020 = 2020 - 1985 + 1

  ANMap::VariableArray{2} = ReadDisk(db, "MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  ArGenFr::VariableArray{3} = ReadDisk(db, "EGInput/ArGenFr") # [Area,GenCo,Year] Fraction of the Area going to each GenCo
  ArNdFr::VariableArray{3} = ReadDisk(db, "EGInput/ArNdFr") # [Area,Node,Year] Fraction of the Area in each Node (MW/MW)
  CCR::VariableArray{3} = ReadDisk(db, "EGOutput/CCR") # [Plant,Area,Year] Capital Charge Rate (1/Yr)
  DesHr::VariableArray{4} = ReadDisk(db, "EGInput/DesHr") # [Plant,Power,Area,Year] Design Hours (Hours)
  EGNDA::VariableArray{4} = ReadDisk(db, "EGOutput/EGNDA") # [Plant,Node,GenCo,Year] Electricity Generation (GWh/Yr) 
  EGPA::VariableArray{3} = ReadDisk(db, "EGOutput/EGPA") # [Plant,Area,Year] Electricity Generated (GWh/Yr)
  FPEU::VariableArray{3} = ReadDisk(db, "EGOutput/FPEU") # [Plant,Area,Year] Electric Utility Fuel Prices ($/mmBtu)
  GCBL::VariableArray{3} = ReadDisk(db, "EGInput/GCBL") # [Plant,Area,Year] Generation Capacity Book Life (Years)
  GCCC::VariableArray{3} = ReadDisk(db, "EGOutput/GCCC") # [Plant,Area,Year] Generation Capac. Capital Costs ($/KW)
  HRtM::VariableArray{3} = ReadDisk(db, "EGInput/HRtM") # [Plant,Area,Year] Marginal Heat Rate (Btu/KWh)
  Inflation::VariableArray{2} = ReadDisk(db, "MOutput/Inflation") # [Area,Year] Inflation Index ($/$)
  MCE::VariableArray{4} = ReadDisk(db, "EOutput/MCE") # [Plant,Power,Area,Year] Cost of Energy from New Capacity ($/MWh)
  MFC::VariableArray{3} = ReadDisk(db, "EOutput/MFC") # [Plant,Area,Year] Marginal Fixed Costs ($/KW)
  MoneyUnitDS::Vector{String} = ReadDisk(db, "MInput/MoneyUnitDS") #[Area]  Descriptor for Monetary Units
  MVC::VariableArray{3} = ReadDisk(db, "EOutput/MVC") # [Plant,Area,Year] Marginal Variable Costs ($/MWh)
  NdArFr::VariableArray{3} = ReadDisk(db, "EGInput/NdArFr") # [Node,Area,Year] Fraction of the Node in each Area
  PoTRNew::VariableArray{3} = ReadDisk(db, "EGOutput/PoTRNew") # [Plant,Area,Year] Emission Cost for New Plants ($/MWh)
  Subsidy::VariableArray{3} = ReadDisk(db, "EGInput/Subsidy") # [Plant,Area,Year] Generating Capacity Subsidy ($/MWh)
  UFOMC::VariableArray{3} = ReadDisk(db, "EGInput/UFOMC") # [Plant,Area,Year] Unit Fixed O&M Costs ($/KW)
  UOMC::VariableArray{3} = ReadDisk(db, "EGInput/UOMC") # [Plant,Area,Year] Unit O&M Costs ($/MWh)
end


function ElectricMarginalCost_DtaRun(data,area)
  (; SceName,Area,AreaDS,GenCo,GenCoDS,GenCos,Nation,NationDS,Nations) = data
  (; Node,NodeDS,Nodes,Plant,PlantDS,Plants,Power,PowerDS,Powers) = data
  (; Year,Yr2018,Yr2020) = data
  (; ANMap,ArGenFr,ArNdFr,CCR,DesHr,EGNDA,EGPA,FPEU,GCBL,GCCC) = data
  (; HRtM,Inflation,MCE,MFC,MoneyUnitDS,MVC,NdArFr,PoTRNew) = data
  (; Subsidy,UFOMC,UOMC) = data

  iob = IOBuffer()

  ArNdSum = zeros(Float32, length(Node))
  EGNGA = zeros(Float32, length(Node), length(GenCo), length(Area), length(Year))
  EGNGATot = zeros(Float32, length(Year))
  ZZZ = zeros(Float32, length(Year))

  areas = area
  areaname = AreaDS[area]
  areakey = Area[area]
  TitleKey = areakey
  TitleName = areaname
  
  power = Select(Power,"Base")

  println(iob, " ")
  println(iob, "$SceName; is the scenario name.")
  println(iob, "$TitleName; is the area being output.")
  println(iob, "This is the Marginal Cost of Energy Inputs and Outputs Summary.")
  println(iob, " ")

  years = collect(Yr(1990):Final)
  # year = Select(Year)  
  println(iob, "Year;", ";    ", join(Year[years], ";    "))
  println(iob, " ")

  #
  # Cost of Energy from New Capacity
  #
  println(iob, "*** ", TitleName, " ",PowerDS[power], " Load Cost of Energy from New Capacity (",MoneyUnitDS[area],"2018/MWh) ***")
  println(iob)

  for node in Nodes
    ArNdSum[node]=sum(ArNdFr[area,node,Yr2020] for area in areas)
  end
  
  nodes = findall(ArNdSum[:] .> 0.0)
  if !isempty(nodes)

  for plant in Plants
    #
    # Weighting Factor
    #
    for year in years, area in areas, node in nodes, genco in GenCos
      EGNGA[node,genco,area,year]=max(EGNDA[plant,genco,area,year]*ArNdFr[area,node,year],1e-12)
    end
    for year in years
      EGNGATot[year]=sum(EGNGA[node,genco,area,year] for area in areas, node in nodes, genco in GenCos)
    end
    #
    # Filter out extremely high values
    #
    for year in years, area in areas
      GCCC[plant,area,year]=min(GCCC[plant,area,year],100000)
      MCE[plant,power,area,year]=min(MCE[plant,power,area,year],1000)
      MFC[plant,area,year]=min(MFC[plant,area,year],1000)
    end

    #
    # Cost of Energy ($/MWh)
    #
    print(iob, TitleName, " ",PlantDS[plant], " ",PowerDS[power], " Cost of Energy of New Capacity (\$/MWh);")
    for year in years
      print(iob,";",Year[year])
    end
    println(iob)
    print(iob, "MCE; Marginal Cost of Energy (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = MCE[plant,power,area,year]/Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    
    #
    # Variable Cost ($/MWh)
    #
    print(iob, "MVC; Variable Cost (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = MVC[plant,area,year]/Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fixed Cost ($/MWh)
    #
    print(iob, "MFC; Fixed Cost (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = MFC[plant,area,year]/DesHr[plant,power,area,year]*1000/
        Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Generation Capacity Capital Cost ($/MWh)
    #
    print(iob, "GCCC; Capital Cost (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = CCR[plant,area,year]*GCCC[plant,area,year]/
        DesHr[plant,power,area,year]*1000/Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Cost ($/KW/Yr)
    #
    print(iob, "GCCC; Capital Cost (",MoneyUnitDS[area],"2018/KW/Yr)")
    for year in years
      ZZZ[year] = CCR[plant,area,year]*GCCC[plant,area,year]/
        Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Overnight Construction Cost ($/KW)
    #
    print(iob, "GCCC; Overnight Construction Cost (",MoneyUnitDS[area],"2018/KW)")
    for year in years
      ZZZ[year] = GCCC[plant,area,year]/
        Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fixed O&M Cost ($/MWh)
    #
    print(iob, "UFOMC; Unit Fixed O&M Cost (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = UFOMC[plant,area,year]/DesHr[plant,power,area,year]*1000*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fixed O&M Cost ($/KW/Yr)
    #
    print(iob, "UFOMC; Unit Fixed O&M Cost (",MoneyUnitDS[area],"2018/KW/Yr)")
    for year in years
      ZZZ[year] = UFOMC[plant,area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capacity Subsidy ($/MWh)
    #
    print(iob, "Subsidy; Capacity Subsidy (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = Subsidy[plant,area,year]/
        Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Variable O&M Cost ($/MWh)
    #
    print(iob, "UOMC; Unit O&M Cost (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = UOMC[plant,area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fuel Cost ($/MWh)
    #
    print(iob, "UFC; Fuel Cost (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = FPEU[plant,area,year]*HRtM[plant,area,year]/1000/
        Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Emission Cost ($/MWh)
    #
    print(iob, "PoTRNew; Emission Cost (",MoneyUnitDS[area],"2018/MWh)")
    for year in years
      ZZZ[year] = PoTRNew[plant,area,year]/
        Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Fuel Price ($/mmBtu)
    #
    print(iob, "FPEU; Fuel Price (",MoneyUnitDS[area],"2018/mmBtu)")
    for year in years
      ZZZ[year] = FPEU[plant,area,year]/
        Inflation[area,year]*Inflation[area,Yr2018]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Heat Rate (Btu/KWh)
    #
    print(iob, "HRtM; Heat Rate (Btu/KWh)")
    for year in years
      ZZZ[year] = HRtM[plant,area,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Design Hours
    #
    print(iob, "DesHr; Design Hours (Hours)")
    for year in years
      ZZZ[year] = DesHr[plant,power,area,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Plant Capacity Factor (MW/MW)
    #
    print(iob,"DesHr/8760; Plant Capacity Factor (MW/MW)")
    for year in years
      ZZZ[year] = DesHr[plant,power,area,year]/8760
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Generation Capacity Book Life (Years)
    #
    print(iob, "GCBL; Generation Capacity Book Life (Years)")
    for year in years
      ZZZ[year] = GCBL[plant,area,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)

    #
    # Capital Charge Rate (1/Yr)
    #
    print(iob, "CCR; Capital Charge Rate (1/Yr)")
    for year in years
      ZZZ[year] = CCR[plant,area,year]
      print(iob,";",@sprintf("%15.4f",ZZZ[year]))
    end
    println(iob)
    println(iob, " ")

  end
  end

  filename = "ElectricMarginalCost-$TitleKey-$SceName.dta"
  open(joinpath(OutputFolder, filename), "w") do filename
    write(filename, String(take!(iob)))
  end
end

function ElectricMarginalCost_DtaControl(db)
  @info "ElectricMarginalCost_DtaControl"
  data = ElectricMarginalCostData(; db)
  Area = data.Area
  AreaDS = data.AreaDS

  for area in Select(Area,(from ="ON", to="MX"))
    ElectricMarginalCost_DtaRun(data,area)
  end
  
  #areas = Select(Area,(from ="ON", to="NU"))
  #ElectricMarginalCost_DtaRun(data, "CN", "Canada", areas, SceName)
  
  #areas = Select(Area,(from ="CA", to="Pac"))
  #ElectricMarginalCost_DtaRun(data, "US", "US", areas, SceName)

end
if abspath(PROGRAM_FILE) == @__FILE__
ElectricMarginalCost_DtaControl(DB)
end

