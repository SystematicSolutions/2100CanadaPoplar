#
# CCS_Penalty.jl
#
using EnergyModel

module CCS_Penalty

import ...EnergyModel: ReadDisk,WriteDisk,Select
import ...EnergyModel: HisTime,ITime,MaxTime,First,Future,Final,Yr
import ...EnergyModel: @finite_math,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct IControl
  db::String

  CalDB::String = "ICalDB"
  Input::String = "IInput"
  Outpt::String = "IOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  EC::SetArray = ReadDisk(db,"$Input/ECKey")
  ECDS::SetArray = ReadDisk(db,"$Input/ECDS")
  ECs::Vector{Int} = collect(Select(EC))
  Nation::SetArray = ReadDisk(db,"MainDB/NationKey")
  NationDS::SetArray = ReadDisk(db,"MainDB/NationDS")
  Nations::Vector{Int} = collect(Select(Nation))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Tech::SetArray = ReadDisk(db,"$Input/TechKey")
  TechDS::SetArray = ReadDisk(db,"$Input/TechDS")
  Techs::Vector{Int} = collect(Select(Tech))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  ANMap::VariableArray{2} = ReadDisk(db,"MainDB/ANMap") # [Area,Nation] Map between Area and Nation
  SqPenaltyTech::VariableArray{5} = ReadDisk(db,"$Input/SqPenaltyTech") # [Tech,EC,Poll,Area,Year] Sequestering Energy Penalty (TBtu/Tonne)
  CgOUREG::VariableArray{4} = ReadDisk(db,"$Input/CgOUREG") # [Tech,EC,Area,Year] Cogeneration Own Use Rate for CCS (GWh/GWh)

  # Scratch Variables
  Target::VariableArray{1} = zeros(Float32,length(Year)) # [Year] Policy Target (Btu/Btu)
end

function ICalibration(db)
  data = IControl(; db)
  (;Input) = data
  (;EC,ECs,Nation,Poll) = data
  (;Tech,Techs,Years) = data
  (;ANMap,SqPenaltyTech,CgOUREG) = data

  CN = Select(Nation,"CN")
  # US = Select(Nation,"US")
  # areas = union(findall(ANMap[:,CN] .== 1.0),findall(ANMap[:,US] .== 1.0))
  areas = findall(ANMap[:,CN] .== 1.0)
  poll = Select(Poll,"CO2")

  #
  ########################
  #
  # Low CO2 concentration
  #
  # - 0.16 MWh/tonne of electricity
  # - 2.55 MWh/tonne of gas
  # Source: "CCS Curves Percent Reduction v3.1.xlsx" - Jeff Amlin 10/03/21
  #
  ecs = Select(EC,["PulpPaperMills","Cement","IronSteel","Aluminum","OtherNonferrous",
                   "Petrochemicals","OtherChemicals","SAGDOilSands","CSSOilSands"])
  Electric = Select(Tech,"Electric")
  Gas =  Select(Tech,"Gas")
  for year in Years, area in areas, ec in ecs
    SqPenaltyTech[Electric,ec,poll,area,year]= 0.16 * 1000 * 3412 / 1e12
    SqPenaltyTech[Gas,ec,poll,area,year]= 2.55 * 1000 * 3412 / 1e12
  end

  #
  # Default is Low CO2 concentration - Jeff Amlin 10/31/21
  #
  Cement = Select(EC,"Cement")
  for tech in Techs, ec in ECs, area in areas, year in Years,
    SqPenaltyTech[tech,ec,poll,area,year] = SqPenaltyTech[tech,Cement,poll,area,year]
  end

  #
  ########################
  #
  # High CO2 concentration
  #
  # � 0.1 MWh/tCO2 of electricity
  # Chemical fertilizer, Natural gas processing, Refineries and Upgraders
  # Source: "CCS Curves Percent Reduction v3.1.xlsx" - Jeff Amlin 10/03/21
  #
  ecs = Select(EC,["Fertilizer","Petroleum","OilSandsUpgraders",
                   "SweetGasProcessing","SourGasProcessing"])
  for ec in ecs, area in areas, year in Years
    SqPenaltyTech[Electric,ec,poll,area,year]= 0.10 * 1000 * 3412 / 1e12
    SqPenaltyTech[Gas,ec,poll,area,year]= 1.13 * 1000 * 3412 / 1e12
  end

  WriteDisk(db,"$Input/SqPenaltyTech",SqPenaltyTech)

  @. CgOUREG = 0

  WriteDisk(db,"$Input/CgOUREG",CgOUREG)

end

Base.@kwdef struct EControl
  db::String

  CalDB::String = "ECalDB"
  Input::String = "EInput"
  Outpt::String = "EOutput"
  BCNameDB::String = ReadDisk(db,"MainDB/BCNameDB") # Base Case Name

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  PlantDS::SetArray = ReadDisk(db,"MainDB/PlantDS")
  Plants::Vector{Int} = collect(Select(Plant))
  Poll::SetArray = ReadDisk(db,"MainDB/PollKey")
  PollDS::SetArray = ReadDisk(db,"MainDB/PollDS")
  Polls::Vector{Int} = collect(Select(Poll))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  SqFr::VariableArray{4} = ReadDisk(db,"EGInput/SqFr") # [Plant,Poll,Area,Year] Sequestered Pollution Fraction (Tonne/Tonne)
  OUREG::VariableArray{3} = ReadDisk(db,"EGInput/OUREG") # [Plant,Area,Year] Own Use Rate for Generation (GWh/GWh)
  OURGC::VariableArray{3} = ReadDisk(db,"EGInput/OURGC") # [Plant,Area,Year] Own Use Rate for Generating Capacity (MW/MW)

  # Scratch Variables
end

function ECalibration(db)
  data = EControl(; db)
  (;Areas,Plant,Poll) = data
  (;Years) = data
  (;SqFr,OUREG,OURGC) = data

  @. SqFr = 0

  #
  # Sequestration fraction only has a value for CO2
  #
  poll = Select(Poll,"CO2")

  #
  # For Coal CCS, Gross emissions capturared is 90% while the net
  # emissions captured is 61.8% - Jeff Amlin 05/24/22
  #
  CoalCCS = Select(Plant,"CoalCCS")
  for year in Years, area in Areas
    SqFr[CoalCCS,poll,area,year] = 0.90
  end

  WriteDisk(db,"EGInput/SqFr",SqFr)

  #
  # From Strathcona Cogeneration whose UnCode is AB_Strath_Co
  # - Jeff Amlin 05/24/22
  #
  NGCCS = Select(Plant,"NGCCS")
  for year in Years, area in Areas
    OUREG[NGCCS,area,year] = 0.3421
    OURGC[NGCCS,area,year] = 0.3421
  end

  #
  # From SK Boundary Dam 3 CCS whose UnCode is SK_Boundry3_CCS
  # - Jeff Amlin 05/24/22
  #
  for year in Years, area in Areas
    OUREG[CoalCCS,area,year] = 0.1710
    OURGC[CoalCCS,area,year] = 0.1710
  end

  WriteDisk(db,"EGInput/OUREG",OUREG)
  WriteDisk(db,"EGInput/OURGC",OURGC)

end

function CalibrationControl(db)
  @info "CCS_Penalty.jl - CalibrationControl"

  ICalibration(db)
  ECalibration(db)

end

if abspath(PROGRAM_FILE) == @__FILE__
  CalibrationControl(DB)
end

end
