#
# EData.jl
#
using EnergyModel

module EData

import ...EnergyModel: ReadDisk,WriteDisk,Select,DT
import ...EnergyModel: ITime,HisTime,MaxTime,Zero,First,Last,Future,Final,Yr
import ...EnergyModel: @finite_math,EnergyModel,finite_inverse,finite_divide,finite_power,finite_exp,finite_log
import ...EnergyModel: DB

const VariableArray{N} = Array{Float32,N} where {N}
const SetArray = Vector{String}

Base.@kwdef struct EControl
  db::String

  Area::SetArray = ReadDisk(db,"MainDB/AreaKey")
  AreaDS::SetArray = ReadDisk(db,"MainDB/AreaDS")
  Areas::Vector{Int} = collect(Select(Area))
  ECC::SetArray = ReadDisk(db,"MainDB/ECCKey")
  ECCDS::SetArray = ReadDisk(db,"MainDB/ECCDS")
  ECCs::Vector{Int} = collect(Select(ECC))
  GenCo::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoKey::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  GenCoDS::SetArray = ReadDisk(db,"MainDB/GenCoKey")
  Node::SetArray = ReadDisk(db,"MainDB/NodeKey")
  Nodes::Vector{Int} = collect(Select(Node))
  Plant::SetArray = ReadDisk(db,"MainDB/PlantKey")
  Plants::Vector{Int} = collect(Select(Plant))
  Power::SetArray = ReadDisk(db,"MainDB/PowerKey")
  Powers::Vector{Int} = collect(Select(Power))
  Year::SetArray = ReadDisk(db,"MainDB/YearKey")
  YearDS::SetArray = ReadDisk(db,"MainDB/YearDS")
  Years::Vector{Int} = collect(Select(Year))

  DRM::VariableArray{2} = ReadDisk(db,"EInput/DRM") # [Node,Year] Desired Reserve Margin (MW/MW)
  ECCPrMap::VariableArray{2} = ReadDisk(db,"EInput/ECCPrMap") # [Node,Year] Map between ECC and Sector for Electric Prices
  SecMap::VariableArray{1} = ReadDisk(db,"SInput/SecMap") # [ECC] ECC Set Map
  AGPVSw::VariableArray{2} = ReadDisk(db,"EInput/AGPVSw") # [GenCo,Year] Is Value of Gratis Permit passed on to Customers (1=Yes)
  MBD::VariableArray{1} = ReadDisk(db,"EInput/MBD") # [Year] Minimum Hours of Operation of Baseload Plants (Hours/Yr)
  MILD::VariableArray{1} = ReadDisk(db,"EInput/MILD") # [Year] Minimum Hours of Operation of Intermediate Plants (Hours/Yr)
  PCFP::VariableArray{2} = ReadDisk(db,"EInput/PCFP") # [Plant,Year] Planning Plant Capacity Factor
  PCFPR::VariableArray{2} = ReadDisk(db,"EInput/PCFPR") # [Power,Year] Planning Plant Capacity Factor
  RofWSw::VariableArray{1} = ReadDisk(db,"EInput/RofWSw") # [Area] Rest-of World Switch (1=Rest-of-World Company)
  xUECost::VariableArray{4} = ReadDisk(db,"EInput/xUECost") # [Area,GenCo,Plant,Year] Energy Cost for Exogenous Contracts (Real US$/MWh)

end

function EData_Inputs(db)
  data = EControl(; db)
  (; Area,ECC,ECCs,Plant,Power,Years) = data
  (; DRM,ECCPrMap,SecMap,AGPVSw,MBD,MILD,PCFP,PCFPR,RofWSw,xUECost) = data

  #
  ########################
  # DRM[Node,Year] Desired Reserve Margin (MW/MW)
  #
  @. DRM=0.25
  WriteDisk(db,"EInput/DRM",DRM)

  #
  ########################
  # ECCPrMap[ECC,Year] Map between ECC and Sector for Electric Prices
  #
  # Default value is SecMap
  #
  for year in Years, ecc in ECCs
    ECCPrMap[ecc,year]=SecMap[ecc]
    #
    # Transportation (SecMap=4) uses Commercial price (ECCPrMap=Com)
    #
    if SecMap[ecc] == 4
      ECCPrMap[ecc,year]=2
    end
    #
    # H2 Production uses Industrial price (ECCPrMap=Ind)
    #
    if ECC[ecc] == "H2Production"
      ECCPrMap[ecc,year]=3
    end
  end
  WriteDisk(db,"EInput/ECCPrMap",ECCPrMap)

  #
  ########################
  # AGPVSw[GenCo,Year] Is Value of Gratis Permit passed on to Customers (1=Yes)
  #
  @. AGPVSw=1.0
  WriteDisk(db,"EInput/AGPVSw",AGPVSw)

  #
  ########################
  # MBD[Year] Minimum Hours of Operation of Baseload Plants (Hours/Yr)
  #
  # 1. Minimum number of hours the base load units can run.
  # 2. The variable is given a value with an equation.
  # 3. P. Cross 3/28/96.
  #
  years=collect(Zero:Last)
  MBD[years] .= 0.0
  years=collect(Future:Final)
  MBD[years] .= 4500.0
  WriteDisk(db,"EInput/MBD",MBD)

  #
  ########################
  # MILD[Year] Minimum Hours of Operation for Intermediate Plants (Hours/Yr)
  #
  years=collect(Zero:Last)
  MILD[years] .= 0.0
  years=collect(Future:Final)
  MILD[years] .= 1000.0
  WriteDisk(db,"EInput/MILD",MILD)

  #
  ########################
  # PCFP[Plant,Year] Planning Plant Capacity Factor
  #
  @. PCFP=0.65
  plant=Select(Plant,"OGCC")
  PCFP[plant,:] .= 0.65
  plant=Select(Plant,"OGCT")
  PCFP[plant,:] .= 0.20
  plant=Select(Plant,"OGSteam")
  PCFP[plant,:] .= 0.65
  plants=Select(Plant,["Coal","CoalCCS"])
  PCFP[plants,:] .= 0.65
  plant=Select(Plant,"Nuclear")
  PCFP[plant,:] .= 0.75
  plant=Select(Plant,"SMNR")
  PCFP[plant,:] .= 0.75
  plant=Select(Plant,"BaseHydro")
  PCFP[plant,:] .= 0.60
  plant=Select(Plant,"PeakHydro")
  PCFP[plant,:] .= 0.60
  plant=Select(Plant,"Biomass")
  PCFP[plant,:] .= 0.60
  WriteDisk(db,"EInput/PCFP",PCFP)

  #
  ########################
  # PCFPR[Power,Year] Planning Plant Capacity Factor
  #
  # 1.
  # 2.
  # 3. T. Harger 7/5/95
  #
  power=Select(Power,"Base")
  PCFPR[power,:] .= 0.70
  power=Select(Power,"Interm")
  PCFPR[power,:] .= 0.50
  power=Select(Power,"Peak")
  PCFPR[power,:] .= 0.25
  WriteDisk(db,"EInput/PCFPR",PCFPR)

  #
  ########################
  # RofWSw[Area] Rest-of World Switch (1=Rest-of-World Company)
  #
  # 1. This variable is defined by the structure of the model.
  # 2. An equation is used to assign a value.
  # 3. J. Amlin 7/29/97
  #
  @. RofWSw=0
  area=Select(Area,"ROW")
  RofWSw[area]=1
  WriteDisk(db,"EInput/RofWSw",RofWSw)

  #
  ########################
  # xUECost[Area,GenCo,Plant,Year] Energy Cost for Exogenous Contracts (Real US$/MWh)
  #
  @. xUECost=0
  WriteDisk(db,"EInput/xUECost",xUECost)
  
end # end EData_Inputs

function Control(db)

  EData_Inputs(db)
end

if abspath(PROGRAM_FILE) == @__FILE__
  Control(DB)
end


end #end module
